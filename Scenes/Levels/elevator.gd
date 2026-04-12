extends Node2D

@export_file("*.tscn") var target_scene_up: String = ""
@export var target_spawn_up: String = ""
@export var option_up_text: String = "Up"  # Customizable text

@export_file("*.tscn") var target_scene_down: String = ""
@export var target_spawn_down: String = ""
@export var option_down_text: String = "Down"  # Customizable text

@export var travel_distance: float = 100.0

const CHOICE_UI = preload("res://ElevatorChoice.tscn")

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var interact_prompt: InteractPrompt = $InteractPrompt

var player_in_range = false
var is_active = false

func _ready():
	interact_prompt.body_entered.connect(_on_player_entered)
	interact_prompt.body_exited.connect(_on_player_exited)

func _on_player_entered(body):
	player_in_range = true

func _on_player_exited(body):
	player_in_range = false

func _process(delta):
	if Input.is_action_just_pressed("interact") and player_in_range and not is_active:
		show_choice_menu()

func show_choice_menu():
	is_active = true
	
	# Disable player input
	if PlayerManager.player:
		PlayerManager.player.set_process_input(false)
		PlayerManager.player.set_process_unhandled_input(false)
	
	# Pause the game
	get_tree().paused = true
	
	# Create choice UI
	var choice_ui = CHOICE_UI.instantiate()
	choice_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(choice_ui)
	
	# Configure options with custom text
	choice_ui.setup_options(
		target_scene_up != "", option_up_text,
		target_scene_down != "", option_down_text
	)
	
	# Wait for choice
	var choice = await choice_ui.choice_made
	
	# Check for cancel
	if choice == "Cancel":
		get_tree().paused = false
		if PlayerManager.player:
			PlayerManager.player.set_process_input(true)
			PlayerManager.player.set_process_unhandled_input(true)
		
		while Input.is_action_pressed("interact"):
			await get_tree().process_frame
		
		is_active = false
		return
	
	# Unpause
	get_tree().paused = false
	if PlayerManager.player:
		PlayerManager.player.set_process_input(true)
		PlayerManager.player.set_process_unhandled_input(true)
	
	# Activate with chosen direction
	await activate_elevator(choice)

func activate_elevator(direction: String):
	# ... rest stays the same
	if PlayerManager.player:
		PlayerManager.player.set_physics_process(false)
		PlayerManager.player.set_process(false)
		
		var camera = PlayerManager.player.get_node_or_null("Camera2D")
		if camera:
			camera.enabled = false
	
	var player_global_pos = PlayerManager.player.global_position
	
	var old_parent = PlayerManager.player.get_parent()
	old_parent.remove_child(PlayerManager.player)
	add_child(PlayerManager.player)
	PlayerManager.player.global_position = player_global_pos
	
	if PlayerManager.player:
		var camera = PlayerManager.player.get_node_or_null("Camera2D")
		if camera:
			camera.reset_smoothing()
			camera.enabled = true
	
	interact_prompt.visible = false
	
	animation_player.play("gear_moving")
	
	var target_y = position.y - travel_distance if direction == "Up" else position.y + travel_distance
	
	var tween = create_tween()
	tween.tween_property(self, "position:y", target_y, 1.5)
	
	await animation_player.animation_finished
	
	var fade_canvas = CanvasLayer.new()
	fade_canvas.layer = 100
	get_tree().root.add_child(fade_canvas)
	
	var fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.color.a = 0
	fade_rect.size = get_viewport_rect().size
	fade_canvas.add_child(fade_rect)
	
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_rect, "color:a", 1.0, 0.5)
	await fade_tween.finished
	
	var persistent_canvas = CanvasLayer.new()
	persistent_canvas.layer = 100
	get_tree().root.add_child(persistent_canvas)
	
	var persistent_black = ColorRect.new()
	persistent_black.color = Color.BLACK
	persistent_black.color.a = 1.0
	persistent_black.size = get_viewport().size * 4
	persistent_canvas.add_child(persistent_black)
	
	fade_canvas.queue_free()
	
	var target_scene = target_scene_up if direction == "Up" else target_scene_down
	var target_spawn = target_spawn_up if direction == "Up" else target_spawn_down
	
	LevelManager.load_new_level(target_scene, target_spawn, Vector2.ZERO)
