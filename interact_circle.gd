class_name InteractCircle extends Node2D
@export var lerp_speed: float = 10.0
@export var activate_distance: float = 200.0
@export var vertical_offset: float = -20.0
@export var arrival_threshold: float = 2.0  # how close = "done moving"
@export var button_visible_distance: float = 80.0  # player distance to show button
@onready var circle: Sprite2D = $interact_prompt_circle
@onready var circle_animation_player: AnimationPlayer = $interact_prompt_circle/CircleAnimationPlayer
@onready var button: Sprite2D = $interact_prompt_button
var player: Player
var _current_target: InteractPrompt = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	circle.visible = false
	button.visible = false

func _process(delta: float) -> void:
	if not player:
		return
	var nearest := _get_nearest_prompt()
	if nearest == null:
		circle.visible = false
		button.visible = false
		_current_target = null
		return
	if _current_target == null:
		global_position = player.global_position + Vector2(0, vertical_offset)
		circle_animation_player.play("active")
		button.visible = false
	_current_target = nearest
	circle.visible = true
	global_position = global_position.lerp(nearest.global_position, lerp_speed * delta)
	# Fade button alpha based on player's proximity to the target
	var player_dist_to_target := player.global_position.distance_to(nearest.global_position)
	var alpha := 1.0 - clampf(player_dist_to_target / button_visible_distance, 0.0, 1.0)
	button.visible = alpha > 0.0
	button.modulate.a = alpha

func _get_nearest_prompt() -> InteractPrompt:
	var nearest: InteractPrompt = null
	var nearest_dist: float = activate_distance
	for p: InteractPrompt in get_tree().get_nodes_in_group("interact_prompts"):
		var d := player.global_position.distance_to(p.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = p
	return nearest
