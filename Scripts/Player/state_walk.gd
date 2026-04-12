class_name StateWalk extends State

@export var move_speed : float = 40.0 # this is the speed the player should move anyways, its weighty, but not too slow, perfect for building tention and atmosphere


@onready var idle: State = $"../Idle"



func enter_state():
	player.update_animation("walk") # change state to "walk"
	pass
	
func exit_state():
	pass

func process( _delta : float ) -> State:
	if player.direction == Vector2.ZERO: #if the player is not moving, return the idle state
		return idle
	
	player.velocity = player.direction * move_speed # the way you moved is the side you are holding the stick, or what key you are pressing and then applying the set speed to the direction
	
	if player.set_direction(): #if the player is holding a direction...
		player.update_animation("walk") # update the state to walk
	return null

func physics( _delta : float ) -> State:
	return null
	
func handle_input( _event : InputEvent ) -> State:
	return null
