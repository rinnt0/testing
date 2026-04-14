extends CanvasLayer

signal option_confirmed(action: String)

@onready var vbox: VBoxContainer = $Control/VBoxContainer

var options: Array = []
var current_index: int = 0

const VISIBLE_SLOTS = 5  # keep this odd so there's a true center
const HALF = VISIBLE_SLOTS / 2  # = 2

const SLOT_SELECTED = preload("res://Scenes/UI/ChoiceSystem/ChoiceSlotSelected.tscn")
const SLOT_UNSELECTED = preload("res://Scenes/UI/ChoiceSystem/ChoiceSlotUnselected.tscn")
signal option_index_confirmed(index: int)
func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_options(new_options: Array):
	options = new_options
	current_index = 0
	visible = true
	rebuild()
	PlayerManager.player.can_look_up = false
	
	if PlayerManager.player.has_node("AnimationPlayer"):
		PlayerManager.player.get_node("AnimationPlayer").play("idle")
	
	PlayerManager.player.state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	PlayerManager.player.velocity = Vector2.ZERO

func hide_menu():
	print("hide_menu called")
	visible = false
	options = []
	PlayerManager.player.can_look_up = true
	
func rebuild():
	for child in vbox.get_children():
		child.queue_free()

	for offset in range(-HALF, HALF + 1):
		var i = current_index + offset
		var slot = SLOT_SELECTED.instantiate() if offset == 0 else SLOT_UNSELECTED.instantiate()
		vbox.add_child(slot)
		if i < 0 or i >= options.size():
			slot.modulate.a = 0.0  # invisible but identical size to a real slot
		else:
			slot.setup(options[i].label, options[i].icon)
		
func _input(event: InputEvent):
	if not visible:
		return
		
	# Check the 'event' rather than the global 'Input' state
	if event.is_action_pressed("ui_up"):
		get_viewport().set_input_as_handled()
		current_index = (current_index - 1 + options.size()) % options.size()
		rebuild()
		
	elif event.is_action_pressed("ui_down"):
		get_viewport().set_input_as_handled()
		current_index = (current_index + 1) % options.size()
		rebuild()
		
	elif event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		option_confirmed.emit(options[current_index].label)
		option_index_confirmed.emit(current_index)
		hide_menu()
