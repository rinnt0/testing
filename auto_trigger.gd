class_name AutoTrigger extends Area2D

var _triggered = false

func _ready() -> void:
	# Respect persistent flags the same way ChoiceBridge does
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

	# Force the SM into idle using its own method, then freeze it
	body.state_machine.change_state(body.state_machine.states[0])  # states[0] is always Idle per initialize()
	await get_tree().process_frame

	body.state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	


	# Grab the first ChoiceMaker child (AutoTrigger expects exactly one)
	var maker = get_children().filter(func(c): return c is ChoiceMaker).front()
	if not maker:
		queue_free()
		return

	var dialog     = maker.get_node_or_null("DialogContent")
	var full_art   = maker.get_node_or_null("FullArtContent")
	var transition = maker.get_node_or_null("TransitionContent")
	var flag       = maker.get_node_or_null("DialogFlag")

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
	if flag:
		if flag.set_flag_on_complete and flag.flag_name != "":
			PersistentData.set_flag(flag.flag_name, true)

	# 3. Handle transitions (last)
	if transition:
		TransitionBox.do_transition(transition, full_art != null)
		await TransitionBox.transition_finished

	queue_free()
