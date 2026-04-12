extends Node2D

@export_file("*.tscn") var target_scene: String = ""
@export var target_spawn_name: String = ""  # Add spawn point name

@onready var interact_prompt: InteractPrompt = $InteractPrompt

var player_in_range = false

func _ready() -> void:
	interact_prompt.body_entered.connect(_on_player_entered)
	interact_prompt.body_exited.connect(_on_player_exited)

func _on_player_entered():
	player_in_range = true
	
func _on_player_exited():
	player_in_range = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact") and player_in_range:
		await fade_out()
		LevelManager.load_new_level(target_scene, target_spawn_name, Vector2.ZERO)  # Pass spawn name

func fade_out():
	# Create black overlay
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	get_tree().root.add_child(canvas_layer)
	
	var color_rect = ColorRect.new()
	color_rect.color = Color.BLACK
	color_rect.color.a = 0
	color_rect.size = get_viewport_rect().size
	canvas_layer.add_child(color_rect)
	
	# Fade to black
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, 1.0)
	await tween.finished
