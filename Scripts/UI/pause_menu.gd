extends Control

@onready var texture_rect: TextureRect = $TextureRect
@onready var pause_menu: Control = $"."
@onready var canvas_layer: CanvasLayer = $CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pause_menu.visible = false
	canvas_layer.visible = false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		pause_menu.visible = true
		get_tree().paused = true
		canvas_layer.visible = true
	pass


func _on_continue_button_pressed() -> void:
	pause_menu.visible = false
	get_tree().paused = false
	canvas_layer.visible = false
	pass # Replace with function body.
