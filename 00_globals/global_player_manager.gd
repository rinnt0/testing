extends Node

var player : Player
var player_spawned = false
const PLAYER = preload("res://Scenes/Player/player.tscn")

func _ready() -> void:
	add_player_instance()
	await get_tree().create_timer(0.2).timeout
	player_spawned = true

func add_player_instance():
	player = PLAYER.instantiate()
	add_child(player)

func set_player_position(_new_pos : Vector2):
	if player and is_instance_valid(player):
		player.global_position = _new_pos

func set_as_parent(_p : Node2D):
	if player and is_instance_valid(player):
		var current_parent = player.get_parent()
		if current_parent:
			current_parent.remove_child(player)
		_p.add_child(player)
	else:
		# Player is invalid, recreate it
		add_player_instance()
		if player:
			_p.add_child(player)

func unparent_player(_p : Node2D):
	if player and is_instance_valid(player) and is_instance_valid(_p):
		if player.get_parent() == _p:
			_p.remove_child(player)
			add_child(player)

func is_busy() -> bool:
	if ChoiceMenu.visible:
		return true
	if DialogBox.visible:
		return true
	if FullArtBox.visible:
		return true
	if TransitionBox.is_blocking():
		return true
	if WaitBox.is_active():
		return true
	return false

func lock_player() -> void:
	if not player or not is_instance_valid(player):
		return
	player.movement_locked = true
	player.velocity = Vector2.ZERO
	player.direction = Vector2.ZERO
	player.can_look_up = false
	if player.state_machine:
		player.state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	if player.has_node("AnimationPlayer"):
		player.get_node("AnimationPlayer").play("idle")

func unlock_player() -> void:
	if not player or not is_instance_valid(player):
		return
	if is_busy():
		return
	if not player.movement_locked:
		return  # already unlocked - don't yank a walking player back to idle
	player.movement_locked = false
	player.can_look_up = true
	if player.state_machine:
		player.state_machine.process_mode = Node.PROCESS_MODE_INHERIT
		var idle_state = player.state_machine.get_node_or_null("Idle")
		if idle_state:
			player.state_machine.change_state(idle_state)
