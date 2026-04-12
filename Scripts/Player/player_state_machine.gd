class_name PlayerStateMachine extends Node

var states : Array[ State ]
var prev_state : State
var current_state : State





func _ready() -> void:
	# keep the brain turned off uuntil initialize() is called
	process_mode = Node.PROCESS_MODE_DISABLED
	pass


func _process(delta: float) -> void:
	# constantly ask the current state if it wants to switch to a new one
	change_state( current_state.process( delta ) )
	pass

func _physics_process(delta: float) -> void:
	# constantly run the physics (movement) of the current state
	change_state( current_state.physics( delta ) )
	pass

func _unhandled_input(event: InputEvent) -> void:
	# make sure button presses get passed through (interact, move, look up)
	change_state( current_state.handle_input( event ) )



func initialize( _player : Player ):
	# Clear the list to prepare for fresh states
	states = []
	
	# Look at all children nodes; if they are "States", add them to the list
	for c in get_children():
		if c is State:
			states.append(c)
	
	if states.size() > 0:
		# if the amount of states is more than 0
		states[0].player = _player 
		change_state( states[0] ) # change the state to index 0 (idle state)
		process_mode  = Node.PROCESS_MODE_INHERIT # turn the brain on

func change_state( new_state : State ):
	if new_state == null || new_state == current_state:
		return #if the state is invalid, or the same, skip
	
	if current_state:
		current_state.exit_state() # tell the current state to make way for the next one.
	
	prev_state = current_state
	current_state = new_state
	current_state.enter_state() # enter the new state
