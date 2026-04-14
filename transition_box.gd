extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
@onready var transition_label: Label = $Label

signal transition_finished

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func do_transition(content: TransitionContent, already_black: bool = false):
	visible = true
	transition_label.modulate.a = 0.0
	transition_label.text = ""
	PlayerManager.player.state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	PlayerManager.player.can_look_up = false

	# Fade to black (skip if already black from full art)
	if not already_black:
		color_rect.color.a = 0.0
		var tween = create_tween()
		tween.tween_property(color_rect, "color:a", 1.0, 1.0)
		await tween.finished
	else:
		color_rect.color.a = 1.0

	# Typewrite the transition text
	if content.transition_text != "":
		transition_label.modulate.a = 1.0
		await _typewrite(transition_label, content.transition_text)
		await _wait_for_interact()
		var tween = create_tween()
		tween.tween_property(transition_label, "modulate:a", 0.0, 0.5)
		await tween.finished

	# Load the next level
	LevelManager.load_new_level(content.next_scene_path, content.transition_target, Vector2.ZERO)

	visible = false
	await FullArtBox.play_fade_in()

	PlayerManager.player.state_machine.process_mode = Node.PROCESS_MODE_INHERIT
	PlayerManager.player.can_look_up = true
	transition_finished.emit()

func _typewrite(label_node: Label, text: String):
	label_node.text = text
	label_node.visible_characters = 0
	var typing_speed = 10
	var typing_time = 0.0
	while label_node.visible_characters < label_node.get_total_character_count():
		typing_time += get_process_delta_time()
		label_node.visible_characters = int(typing_speed * typing_time)
		await get_tree().process_frame

func _wait_for_interact():
	while true:
		if Input.is_action_just_pressed("interact"):
			break
		await get_tree().process_frame

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		print("!!! ALERT: TransitionBox is being deleted!")
		# This will print to the console the moment it's freed
		# Look at the Stack Trace in the debugger to see what called it.
