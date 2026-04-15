class_name StateIdle extends State

@onready var walk: StateWalk = $"../Walk"

func enter_state():
	player.update_animation("idle")
	pass
	
func exit_state():
	pass

func process( _delta : float ) -> State:
	if player.direction != Vector2.ZERO: # if the player velocity does not equal 0, return the walk state
		return walk
	
	player.velocity = Vector2.ZERO
	return null

func physics( _delta : float ) -> State:
	return null
	
func handle_input( _event : InputEvent ) -> State:
	return null
