class_name AutoTrigger extends Area2D

var _triggered = false
@export var free_on_complete: bool = true  # Uncheck to keep the Area2D alive after triggering

func _ready() -> void:
	for maker in get_children().filter(func(c): return c is ChoiceMaker):
		var flag = maker.get_node_or_null("DialogFlag")
		if flag and flag.set_flag_on_complete and flag.flag_name != "":
			if PersistentData.get_flag(flag.flag_name):
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

	var dialog     = maker.get_node_or_null("DialogContent")     if maker else null
	var full_art   = maker.get_node_or_null("FullArtContent")    if maker else null
	var flag       = maker.get_node_or_null("DialogFlag")        if maker else null

	# TransitionContent can live on the ChoiceMaker child OR directly on AutoTrigger
	var transition = null
	if maker:
		transition = maker.get_node_or_null("TransitionContent")
	if not transition:
		transition = get_node_or_null("TransitionContent")

	# 1. Play visuals / dialog
	if full_art:
		await FullArtBox.show_art(full_art, transition != null)
	elif dialog:
		DialogBox.show_lines(dialog.lines, dialog.portraits, dialog.voice_profiles, dialog)
		await DialogBox.dialog_finished
		body.state_machine.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		PlayerManager.player.state_machine.process_mode = Node.PROCESS_MODE_INHERIT
		PlayerManager.player.can_look_up = true

	# 2. Handle flags
	if flag and flag.set_flag_on_complete and flag.flag_name != "":
		PersistentData.set_flag(flag.flag_name, true)

	# 3. Handle transitions (last)
	if transition:
		TransitionBox.do_transition(transition, full_art != null)
		await TransitionBox.transition_finished

	if free_on_complete:
		queue_free()
	else:
		# Re-arm so the trigger can fire again if desired
		_triggered = false
