extends Node2D

@export var falling_cutscene: Node2D
@export_file("*.tscn") var next_scene: String = ""

@onready var interact_prompt: InteractPrompt = $"../../InteractPrompt"

var player_in_range = false
var can_interact = false  # Start false
var is_playing = false  # Prevent spam

func _ready() -> void:
	if falling_cutscene:
		falling_cutscene.visible = false
	
	# Start with interaction disabled, wait for prompt to become visible
	can_interact = false
	
	interact_prompt.body_entered.connect(_on_player_entered)
	interact_prompt.body_exited.connect(_on_player_exited)
	interact_prompt.visibility_changed.connect(_on_prompt_visible)

func _on_prompt_visible():
	if interact_prompt.visible:
		can_interact = true

func _on_player_entered():
	player_in_range = true

func _on_player_exited():
	player_in_range = false

# Called by reflection script when fade completes
func enable_interaction():
	can_interact = true

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact") and player_in_range and can_interact and not is_playing:
		is_playing = true
		await play_falling_cutscene()

func play_falling_cutscene():
	# Disable player movement
	if PlayerManager.player and is_instance_valid(PlayerManager.player):
		PlayerManager.player.set_physics_process(false)
		PlayerManager.player.set_process(false)
	
	# Hide interact prompt
	interact_prompt.visible = false
	
	# Create black fade overlay
	var fade_canvas = CanvasLayer.new()
	fade_canvas.layer = 99
	get_tree().root.add_child(fade_canvas)
	
	var fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.color.a = 0
	fade_rect.size = get_viewport_rect().size
	fade_canvas.add_child(fade_rect)
	
	# Fade to black
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 1.0)
	await tween.finished
	
	# Center and show cutscene
	var viewport_size = get_viewport_rect().size
	falling_cutscene.position = viewport_size / 2
	falling_cutscene.visible = true
	
	# Fade out black to reveal cutscene
	tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 1.0)
	await tween.finished
	fade_canvas.queue_free()
	
	# Play cutscene animation
	var anim_player = falling_cutscene.get_node("AnimationPlayer")
	if anim_player:
		anim_player.play("falling_cutscene")
		await anim_player.animation_finished
	
	# Create persistent black overlay before scene change
	var persistent_canvas = CanvasLayer.new()
	persistent_canvas.layer = 100
	get_tree().root.add_child(persistent_canvas)
	
	var persistent_black = ColorRect.new()
	persistent_black.color = Color.BLACK
	persistent_black.color.a = 1.0
	persistent_black.size = get_viewport().size * 4
	persistent_canvas.add_child(persistent_black)
	
	# Transition to next scene
	LevelManager.load_new_level(next_scene, "", Vector2.ZERO)
