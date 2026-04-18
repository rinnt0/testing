# choice_bridge.gd
extends Node2D

@onready var interact_prompt: InteractPrompt = $InteractPrompt
var player_in_range = false
var is_open = false
var _menu_open = false          # ← ADD: true only while ChoiceMenu is on screen

func _ready():
	for maker in get_children().filter(func(c): return c is ChoiceMaker):
		var flag = maker.get_node_or_null("DialogFlag")
		if flag and flag.set_flag_on_complete and flag.flag_name != "":
			if PersistentData.get_flag(flag.flag_name):
				queue_free()
				return
	interact_prompt.body_entered.connect(_on_entered)
	interact_prompt.body_exited.connect(_on_exited)

func _on_entered():
	player_in_range = true

func _on_exited():
	player_in_range = false

func _unhandled_input(event: InputEvent):
	# ← was: is_open. Now only fires while the MENU itself is showing.
	if _menu_open and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		ChoiceMenu.hide_menu()
		PlayerManager.player.state_machine.process_mode = Node.PROCESS_MODE_INHERIT
		PlayerManager.player.can_look_up = true
		_menu_open = false      # ← ADD
		is_open = false
		return

	if player_in_range and not is_open and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()

		is_open = true
		_menu_open = true       # ← ADD: menu is now showing

		var active_flagged_labels = {}
		for c in get_children():
			if c is ChoiceMaker and c.requires_flag:
				if PersistentData.get_flag(c.flag_name) == c.flag_value:
					active_flagged_labels[c.label] = true

		var choices = []
		for c in get_children():
			if not c is ChoiceMaker:
				continue
			if c.requires_flag:
				if PersistentData.get_flag(c.flag_name) == c.flag_value:
					choices.append(c)
			else:
				if not active_flagged_labels.has(c.label):
					choices.append(c)

		ChoiceMenu.show_options(choices)
		var choice = await ChoiceMenu.option_confirmed
		_menu_open = false      # ← ADD: menu confirmed, no longer showing

		var chosen_maker = choices.filter(func(c): return c.label == choice)
		if chosen_maker.size() > 0:
			var dialog     = chosen_maker[0].get_node_or_null("DialogContent")
			var full_art   = chosen_maker[0].get_node_or_null("FullArtContent")
			var wait       = chosen_maker[0].get_node_or_null("WaitMoment")
			var transition = chosen_maker[0].get_node_or_null("TransitionContent")
			var flag       = chosen_maker[0].get_node_or_null("DialogFlag")

			if wait and full_art:
				var _art_done := false
				var _wait_done := false
				FullArtBox.art_finished.connect(func(): _art_done = true, CONNECT_ONE_SHOT)
				WaitBox.wait_finished.connect(func(): _wait_done = true, CONNECT_ONE_SHOT)
				# ↓ was: WaitBox.do_wait(wait, true)
				_do_wait_with_audio(wait)  # don't await — runs parallel with art
				FullArtBox.show_art(full_art, transition != null)
				while not (_art_done and _wait_done):
					await get_tree().process_frame
			elif wait:
				# ↓ was: await WaitBox.do_wait(wait)
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
					PersistentData.set_flag(flag.flag_name, true)
				if flag.delete_after_interaction:
					queue_free()

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

			is_open = false

# ── add this helper ──────────────────────────────────────────────
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
# ────────────────────────────────────────────────────────────────
