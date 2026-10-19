extends Node

signal level_load_started
signal level_loaded

var current_tilemap_bounds : Array[Vector2]
var target_transition : String
var position_offset : Vector2
var has_restore_position: bool = false
var restore_position: Vector2

signal tilemap_bounds_changed( bounds : Array[Vector2] )


func _ready() -> void:
	await get_tree().process_frame
	level_loaded.emit()

func change_tilemap_bounds( bounds : Array[Vector2] ):
	current_tilemap_bounds = bounds
	tilemap_bounds_changed.emit( bounds )


func load_new_level(
	level_path : String,
	_target_transition : String,
	_position_offset : Vector2
	
):
	
	get_tree().paused = true
	target_transition = _target_transition
	position_offset = _position_offset
	
	level_load_started.emit()
	
	await get_tree().process_frame
	
	var change_error := get_tree().change_scene_to_file(level_path)
	if change_error != OK:
		get_tree().paused = false
		level_loaded.emit()
		push_error("Could not load scene '%s': %s" % [level_path, error_string(change_error)])
		return
	
	await get_tree().process_frame
	if has_restore_position and PlayerManager.player and is_instance_valid(PlayerManager.player):
		PlayerManager.set_player_position(restore_position)
		has_restore_position = false

	if get_tree().current_scene and get_tree().current_scene.is_in_group("level"):
		if not PersistentData.save_game(0):
			push_warning("Could not write the automatic save for this level")
	
	get_tree().paused = false
	
	await get_tree().process_frame
	
	level_loaded.emit()
	
	pass


func load_saved_game(level_path: String, player_position: Vector2) -> void:
	has_restore_position = true
	restore_position = player_position
	await load_new_level(level_path, "", Vector2.ZERO)
