# choice_bridge.gd
extends Node2D

@onready var interact_prompt: InteractPrompt = $InteractPrompt
var player_in_range = false
var is_open = false
var _menu_open = false          # true only while ChoiceMenu is on screen

func _ready():
	for maker in _live_makers():
		var flag = maker.get_node_or_null("DialogFlag")
		if flag and flag.set_flag_on_complete and flag.flag_name != "" \
				and flag.delete_after_interaction != DialogFlag.DeleteMode.NO:
			if PersistentData.get_flag(flag.flag_name) == flag.flag_value:
				match flag.delete_after_interaction:
					DialogFlag.DeleteMode.CHOICE_MAKER:
						maker.queue_free()
					DialogFlag.DeleteMode.CHOICE_BRIDGE:
						queue_free()
						return
	interact_prompt.body_entered.connect(_on_entered)
	interact_prompt.body_exited.connect(_on_exited)
	_update_prompt_state()

func _on_entered():
	player_in_range = true

func _on_exited():
	player_in_range = false

# Makers that exist and aren't about to be deleted
func _live_makers() -> Array:
	return get_children().filter(func(c): return c is ChoiceMaker and not c.is_queued_for_deletion())

# If every maker is gone, switch the prompt off. The bridge itself stays,
# so sprites etc. underneath it are untouched.
func _update_prompt_state() -> void:
	if _live_makers().is_empty():
		interact_prompt.visible = false
		interact_prompt.set_deferred("monitoring", false)
		interact_prompt.remove_from_group("interact_prompts")
		player_in_range = false

func _unhandled_input(event: InputEvent):
	if _menu_open and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		ChoiceMenu.hide_menu()
		PlayerManager.player.state_machine.process_mode = Node.PROCESS_MODE_INHERIT
		PlayerManager.player.can_look_up = true
		_menu_open = false
		is_open = false
		return

	if player_in_range and not is_open and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()

		var active_flagged_labels = {}
		for c in _live_makers():
			if c.requires_flag:
				if PersistentData.get_flag(c.flag_name) == c.flag_value:
					active_flagged_labels[c.label] = true

		var choices = []
		for c in _live_makers():
			if c.requires_flag:
				if PersistentData.get_flag(c.flag_name) == c.flag_value:
					choices.append(c)
			else:
				if not active_flagged_labels.has(c.label):
					choices.append(c)

		# Nothing to show -> don't open an empty menu (it would lock the player)
		if choices.is_empty():
			_update_prompt_state()
			return

		is_open = true
		_menu_open = true

		ChoiceMenu.show_options(choices)
		var choice = await ChoiceMenu.option_confirmed
		_menu_open = false

		var chosen_maker = choices.filter(func(c): return c.label == choice)
		if chosen_maker.size() > 0:
			var maker      = chosen_maker[0]
			var dialog     = maker.get_node_or_null("DialogContent")
			var full_art   = maker.get_node_or_null("FullArtContent")
			var wait       = maker.get_node_or_null("WaitMoment")
			var transition = maker.get_node_or_null("TransitionContent")
			var flag       = maker.get_node_or_null("DialogFlag")
			var toast      = _find_toast(maker)

			if toast and toast.timing == ToastContent.Timing.START:
				ToastBox.show_toast(toast)

			if wait and full_art:
				var _art_done := false
				var _wait_done := false
				FullArtBox.art_finished.connect(func(): _art_done = true, CONNECT_ONE_SHOT)
				WaitBox.wait_finished.connect(func(): _wait_done = true, CONNECT_ONE_SHOT)
				_do_wait_with_audio(wait)  # don't await, runs parallel with art
				FullArtBox.show_art(full_art, transition != null)
				while not (_art_done and _wait_done):
					await get_tree().process_frame
			elif wait:
				await _do_wait_with_audio(wait)
			elif full_art:
				await FullArtBox.show_art(full_art, transition != null)
			elif dialog:
				DialogBox.show_lines(dialog.lines, dialog.portraits, dialog.voice_profiles, dialog)
				await DialogBox.dialog_finished
			else:
				PlayerManager.player.state_machine.process_mode = Node.PROCESS_MODE_INHERIT
				PlayerManager.player.can_look_up = true

			if flag:
				if flag.set_flag_on_complete and flag.flag_name != "":
					PersistentData.set_flag(flag.flag_name, flag.flag_value)

			if toast and toast.timing == ToastContent.Timing.END:
				if transition:
					await ToastBox.show_toast(toast)   # let it finish before the fade
				else:
					ToastBox.show_toast(toast)   

			if transition:
				ChoiceMenu.hide_menu()
				match transition.facing_direction:
					TransitionContent.FacingDirection.LEFT:
						PlayerManager.player.current_direction = Vector2.LEFT
						PlayerManager.player.sprite.scale.x = -1
					TransitionContent.FacingDirection.RIGHT:
						PlayerManager.player.current_direction = Vector2.RIGHT
						PlayerManager.player.sprite.scale.x = 1
				TransitionBox.do_transition(transition, full_art != null)
				await TransitionBox.transition_finished

			# Delete ONLY the maker that was used, not the whole bridge
			if flag:
				match flag.delete_after_interaction:
					DialogFlag.DeleteMode.CHOICE_MAKER:
						maker.queue_free()
						_update_prompt_state()
					DialogFlag.DeleteMode.CHOICE_BRIDGE:
						queue_free()

		is_open = false

func _find_toast(maker: Node) -> ToastContent:
	var named = maker.get_node_or_null("ToastContent")
	if named is ToastContent:
		return named
	for child in maker.get_children():
		if child is ToastContent:
			return child
	return null

func _do_wait_with_audio(wait: WaitMoment) -> void:
	# Snapshot current level audio
	var level = get_tree().get_first_node_in_group("level")
	var prev_music:   AudioStream = level.music   if level else null
	var prev_ambient: AudioStream = level.ambient if level else null

	# Override if set
	if wait.override_music:
		AudioManager.play_music(wait.override_music)
	if wait.override_ambient:
		AudioManager.play_ambient(wait.override_ambient)

	await WaitBox.do_wait(wait)

	# Restore
	if wait.override_music and prev_music:
		AudioManager.play_music(prev_music)
	if wait.override_ambient and prev_ambient:
		AudioManager.play_ambient(prev_ambient)
