extends Area2D

@onready var label: Label = $"../player/text_ui/Label"
@onready var text_ui: Control = $"../player/text_ui"
@onready var test_npc: Area2D = $"."

var inside = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if inside == 1 and Input.is_action_just_pressed("interact"):
		label.text = "yo dude"
		text_ui.visible = true
	pass


func _on_body_entered(body: Node2D) -> void:
	inside = 1
	pass # Replace with function body.


func _on_body_exited(body: Node2D) -> void:
	inside = 0
	pass # Replace with function body.
