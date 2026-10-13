class_name AutoTrigger extends Area2D
var _triggered = false
@export var free_on_complete: bool = true  # Uncheck to keep the Area2D alive after triggering

func _ready() -> void:
	for maker in get_children().filter(func(c): return c is ChoiceMaker):
		var flag = maker.get_node_or_null("DialogFlag")
		if flag and flag.set_flag_on_complete and flag.flag_name != "" and flag.delete_after_interaction:
			if PersistentData.get_flag(flag.flag_name) == flag.flag_value:
				queue_free()
				return
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _triggered or not body is Player:
		return
	_triggered = true
	body.velocity = Vector2.ZERO
	body.direction = Vector2.ZERO
	body.state_machine.change_state(body.state_machine.states[0])
	await get_tree().process_frame
	body.state_machine.process_mode = Node.PROCESS_MODE_DISABLED

	var maker = get_children().filter(func(c): return c is ChoiceMaker).front()
	var flag = maker.get_node_or_null("DialogFlag") if maker else null
	var toast: ToastContent = null
	if maker:
		var named = maker.get_node_or_null("ToastContent")
		if named is ToastContent:
			toast = named
		else:
			for child in maker.get_children():
				if child is ToastContent:
					toast = child
					break

	if toast and toast.timing == ToastContent.Timing.START:
		ToastBox.show_toast(toast)

	# TransitionContent can live on the ChoiceMaker child OR directly on AutoTrigger
	var transition = null
	if maker:
		transition = maker.get_node_or_null("TransitionContent")
	if not transition:
		transition = get_node_or_null("TransitionContent")

	# Build an ordered sequence of content nodes.
	# Supports any order/count of DialogContent and FullArtContent children,
	# e.g. DialogContent1, FullArtContent1, DialogContent2, ...
	# Sort by child index so scene tree order = playback order.
	var sequence: Array = []
	if maker:
		for child in maker.get_children():
			if child is DialogContent or child is FullArtContent:
				sequence.append(child)

	var played_any := false
	for i in sequence.size():
		var content = sequence[i]
		var is_last_visual := (i == sequence.size() - 1)
		played_any = true
		if content is DialogContent:
			DialogBox.show_lines(content.lines, content.portraits, content.voice_profiles, content)
			await DialogBox.dialog_finished
			if is_last_visual and not transition:
				body.state_machine.process_mode = Node.PROCESS_MODE_INHERIT
		elif content is FullArtContent:
			await FullArtBox.show_art(content, transition != null and is_last_visual)

	if not played_any:
		PlayerManager.player.state_machine.process_mode = Node.PROCESS_MODE_INHERIT
		PlayerManager.player.can_look_up = true

	# Handle flags
	if flag and flag.set_flag_on_complete and flag.flag_name != "":
		PersistentData.set_flag(flag.flag_name, flag.flag_value)

	if toast and toast.timing == ToastContent.Timing.END:
		await ToastBox.show_toast(toast)

	# Handle transitions (last)
	if transition:
		TransitionBox.do_transition(transition, played_any)
		await TransitionBox.transition_finished

	if free_on_complete:
		queue_free()
	else:
		_triggered = false
