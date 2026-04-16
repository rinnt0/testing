class_name InteractPrompt extends Area2D

var player: Player
@onready var star: Sprite2D = $interact_prompt_star
@onready var button: Sprite2D = $interact_prompt_button
@onready var star_animation_player: AnimationPlayer = $interact_prompt_star/StarAnimationPlayer

@export var fade_start_distance: float = 200.0
@export var fade_end_distance: float = 20.0
signal interacted(player: Player)

func interact(p: Player) -> void:
	emit_signal("interacted", p)
func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	add_to_group("interact_prompts")  # lets the tracker find all prompts

func _process(_delta: float) -> void:
	if not player or not is_instance_valid(player):
		return
	var distance = global_position.distance_to(player.global_position)
	var alpha = inverse_lerp(fade_start_distance, fade_end_distance, distance)
	star.self_modulate = Color(1, 1, 1, clamp(alpha, 0.0, 1.0))

func _on_body_entered(body: Player) -> void:
	player = body
	star_animation_player.play("active")
	emit_signal("body_entered")

func _on_body_exited(body: Player) -> void:
	star_animation_player.play("idle")
	emit_signal("body_exited")
