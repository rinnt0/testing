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
