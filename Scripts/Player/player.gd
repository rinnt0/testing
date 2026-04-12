class_name Player extends CharacterBody2D

var current_direction = Vector2.DOWN
var direction = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

signal looking_up

func _ready() -> void:
	state_machine.initialize(self) # initialize the state machine on self (the player)
	current_direction = Vector2.LEFT # start the game looking left.
	sprite.scale.x = -1 # scale the sprite to look left
	pass
	
	
func _process(delta: float) -> void:
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	# simple movement with 3 directions: -1, 0, 1
	# hold right = 1 | hold left = -1 | hold both or press nothing = 0.
	# this value gets multiplied by the walk speed to make the character move.
	is_looking_up()
	pass
	

func _physics_process(delta: float) -> void:
	velocity.y = 10 # this is the gravity, ensuring the player stays on the ground and doesnt start floating for no reason.
	
	move_and_slide()

func update_animation( state : String ):
	animation_player.play( state ) # play the current state

func set_direction():
	var new_direction = current_direction
	if direction == Vector2.ZERO: # when you are not moving, nothing happens
		return false
	
	if direction.y == 0:
		new_direction = Vector2.LEFT if direction.x < 0 else Vector2.RIGHT
	elif direction.x == 0:
		new_direction = Vector2.UP if direction.y < 0 else Vector2.DOWN
	
	if new_direction == current_direction:
		return false
	
	current_direction = new_direction
	sprite.scale.x = -1 if current_direction == Vector2.LEFT else 1 # flip the sprite when moving left
	return true

func is_looking_up(): # smooth looking up mechanic for hidden stuff
	if Input.is_action_pressed("up"):
		collision_shape.scale.y = 1.5
		collision_shape.position = Vector2( 0.0, -26.3 )
	else:
		collision_shape.scale.y = 1
		collision_shape.position = Vector2( 0.0, -17.5 )
