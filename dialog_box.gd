extends CanvasLayer
@onready var label: Label = $NinePatchRect/Label
@onready var portrait: TextureRect = $TextureRect
@onready var diamond: TextureRect = $TextureRect2

var portraits: Array = []
var lines: Array[String] = []
var current_line = 0
var is_typing = false

signal dialog_finished

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_lines(new_lines: Array[String], new_portraits: Array = []):
	print("show_lines called with: ", new_lines)
	lines = new_lines
	portraits = new_portraits
	current_line = 0
	visible = true
	diamond.visible = false
	display_current_line()
	PlayerManager.player.can_look_up = false
	PlayerManager.player.state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	

func _input(event: InputEvent):
	if not visible:
		return
	if event.is_action_pressed("interact") and not event.is_echo():
		get_viewport().set_input_as_handled()
		if is_typing:
			# Show all text instantly
			label.timer.stop()
			label.text = lines[current_line]
			is_typing = false
			on_typing_finished()
		elif current_line + 1 < lines.size():
			current_line += 1
			display_current_line()
		else:
			visible = false
			PlayerManager.player.state_machine.process_mode = Node.PROCESS_MODE_INHERIT
			PlayerManager.player.can_look_up = true
			dialog_finished.emit()

func on_typing_finished():
	print("typing finished")
	is_typing = false
	diamond.visible = true

func display_current_line():
	is_typing = true
	diamond.visible = false
	
	label.type = lines[current_line]
	label.text = ""
	label.current_index = 0
	label.timer.start(label.timer_time)
	
	if portraits.size() > current_line and portraits[current_line] != null:
		portrait.texture = portraits[current_line]
