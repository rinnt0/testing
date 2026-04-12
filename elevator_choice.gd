extends CanvasLayer

signal choice_made(direction: String)

@onready var button_up: Button = $CenterContainer/VBoxContainer/UpOption/ButtonUp
@onready var button_down: Button = $CenterContainer/VBoxContainer/DownOption/ButtonDown
@onready var button_cancel: Button = $CenterContainer/VBoxContainer/CancelOption/ButtonCancel

@onready var up_option: HBoxContainer = $CenterContainer/VBoxContainer/UpOption
@onready var down_option: HBoxContainer = $CenterContainer/VBoxContainer/DownOption

@onready var triangle_up: Label = $CenterContainer/VBoxContainer/UpOption/Triangle
@onready var triangle_down: Label = $CenterContainer/VBoxContainer/DownOption/Triangle
@onready var triangle_cancel: Label = $CenterContainer/VBoxContainer/CancelOption/Triangle

var current_triangle: Label
var bob_time: float = 0.0
var original_y: float = 0.0
var current_index: int = 0
var buttons: Array[Button] = []

func setup_options(has_up: bool, up_text: String, has_down: bool, down_text: String):
	# Set custom text
	button_up.text = up_text
	button_down.text = down_text
	
	# Disable mouse on all buttons
	button_up.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button_down.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button_cancel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Hide options that aren't available
	up_option.visible = has_up
	down_option.visible = has_down
	
	# Rebuild button array
	buttons.clear()
	if has_up:
		buttons.append(button_up)
	if has_down:
		buttons.append(button_down)
	buttons.append(button_cancel)
	
	# Focus first button
	current_index = 0
	if buttons.size() > 0:
		await get_tree().process_frame
		buttons[0].grab_focus()
		
		if buttons[0] == button_up:
			_on_up_focused()
		elif buttons[0] == button_down:
			_on_down_focused()
		else:
			_on_cancel_focused()

func _ready():
	button_up.pressed.connect(_on_up_pressed)
	button_down.pressed.connect(_on_down_pressed)
	button_cancel.pressed.connect(_on_cancel_pressed)
	
	button_up.focus_entered.connect(_on_up_focused)
	button_down.focus_entered.connect(_on_down_focused)
	button_cancel.focus_entered.connect(_on_cancel_focused)

func _input(event):
	if event.is_action_pressed("move_down"):
		current_index = (current_index + 1) % buttons.size()
		buttons[current_index].grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_up") or event.is_action_pressed("up"):
		current_index = (current_index - 1 + buttons.size()) % buttons.size()
		buttons[current_index].grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		if buttons[current_index] == button_up:
			choice_made.emit("Up")
		elif buttons[current_index] == button_down:
			choice_made.emit("Down")
		elif buttons[current_index] == button_cancel:
			choice_made.emit("Cancel")
		queue_free()
		get_viewport().set_input_as_handled()

func _process(delta):
	if current_triangle:
		bob_time += delta * 5.0
		var offset = sin(bob_time) * 3.0
		current_triangle.position.y = original_y + offset

func _on_up_focused():
	hide_all_triangles()
	triangle_up.visible = true
	current_triangle = triangle_up
	original_y = triangle_up.position.y
	current_index = buttons.find(button_up)
	bob_time = 0.0

func _on_down_focused():
	hide_all_triangles()
	triangle_down.visible = true
	current_triangle = triangle_down
	original_y = triangle_down.position.y
	current_index = buttons.find(button_down)
	bob_time = 0.0

func _on_cancel_focused():
	hide_all_triangles()
	triangle_cancel.visible = true
	current_triangle = triangle_cancel
	original_y = triangle_cancel.position.y
	current_index = buttons.find(button_cancel)
	bob_time = 0.0

func hide_all_triangles():
	triangle_up.visible = false
	triangle_down.visible = false
	triangle_cancel.visible = false

func _on_up_pressed():
	choice_made.emit("Up")
	queue_free()

func _on_down_pressed():
	choice_made.emit("Down")
	queue_free()

func _on_cancel_pressed():
	choice_made.emit("Cancel")
	queue_free()
