class_name State extends Node

static var player : Player


func _ready() -> void:
	pass 



func enter_state():
	pass
	
func exit_state():
	pass

func process( _delta : float ) -> State:
	return null

func physics( _delta : float ) -> State:
	return null
	
func handle_input( _event : InputEvent ) -> State:
	return null
