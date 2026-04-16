class_name Player extends CharacterBody2D

var current_direction = Vector2.DOWN
var direction = Vector2.ZERO
var can_look_up = true

# ─────────────────────────────────────────────
#  Footsteps
# ─────────────────────────────────────────────
@export var footstep_sounds: Array[AudioStream] = []   # drag in 2–4 step sounds

@onready var state_walk_to_interact: StateWalkToInteract = $StateMachine/WalkToInteract
@onready var sprite: Sprite2D = $Sprite2D
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

signal looking_up

func _ready() -> void:
	add_to_group("player")
	state_machine.initialize(self)
	current_direction = Vector2.LEFT
	sprite.scale.x = -1

func _process(delta: float) -> void:
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	is_looking_up()


func _physics_process(delta: float) -> void:
	velocity.y = 10
	move_and_slide()

# ─────────────────────────────────────────────
#  Existing methods (unchanged)
# ─────────────────────────────────────────────
func update_animation(state: String) -> void:
	animation_player.play(state)

func set_direction() -> bool:
	var new_direction = current_direction
	if direction == Vector2.ZERO:
		return false
	if direction.y == 0:
		new_direction = Vector2.LEFT if direction.x < 0 else Vector2.RIGHT
	elif direction.x == 0:
		new_direction = Vector2.UP if direction.y < 0 else Vector2.DOWN
	if new_direction == current_direction:
		return false
	current_direction = new_direction
	sprite.scale.x = -1 if current_direction == Vector2.LEFT else 1
	return true

func is_looking_up() -> void:
	if not can_look_up:
		return
	if Input.is_action_pressed("up"):
		collision_shape.scale.y = 1.5
		collision_shape.position = Vector2(0.0, -26.3)
	else:
		collision_shape.scale.y = 1
		collision_shape.position = Vector2(0.0, -17.5)

func walk_to_interact(prompt: InteractPrompt) -> void:
	state_walk_to_interact.set_target(prompt)
	state_machine.change_state(state_walk_to_interact)
