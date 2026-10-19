extends Node

signal flag_changed(flag_name: String, value: bool)
signal flags_reloaded

const SAVE_DIRECTORY := "user://saves"
const MAX_SLOT := 3
const DEFAULT_FLAGS := {
	"pills_taken": false,
	"talked_to_npc_1": false,
	"talked_to_npc": false,
	"visited_hub": false
}

var flags: Dictionary = {}
var data: Dictionary = {}
var _save_counter: int = 0

func _ready():
	# Initialize with default values
	reset_to_defaults()

func reset_to_defaults():
	reset_flags_to_defaults()
	data = {}


func reset_flags_to_defaults() -> void:
	flags = DEFAULT_FLAGS.duplicate(true)
	flags_reloaded.emit()


func replace_flags(new_flags: Dictionary) -> void:
	flags = new_flags.duplicate(true)
	flags_reloaded.emit()

# Flag management
func set_flag(flag_name: String, value: bool):
	if flags.has(flag_name) and flags[flag_name] == value:
		return
	flags[flag_name] = value
	flag_changed.emit(flag_name, value)
	print("Flag set:", flag_name, "=", value)

func get_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)

# Data management
func set_data(key: String, value):
	data[key] = value

func get_data(key: String, default_value = null):
	return data.get(key, default_value)


func save_game(slot: int = 0) -> bool:
	if slot < 0 or slot > MAX_SLOT:
		return false
	if not get_tree().current_scene or not get_tree().current_scene.is_in_group("level"):
		return false
	if not PlayerManager.player or not is_instance_valid(PlayerManager.player):
		return false

	var save_id := _next_save_id()
	var prefix := _slot_prefix(slot)
	var final_path := "%s/%s%s.json" % [SAVE_DIRECTORY, prefix, save_id]
	var temp_path := final_path + ".tmp"
	var absolute_directory := ProjectSettings.globalize_path(SAVE_DIRECTORY)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_directory)
	if directory_error != OK:
		push_error("Could not create save directory: %s" % error_string(directory_error))
		return false

	var save_dict = {
		"version": 1,
		"scene_path": get_tree().current_scene.scene_file_path,
		"player_position": [PlayerManager.player.global_position.x, PlayerManager.player.global_position.y],
		"persistent_flags": flags,
		"global_flags": flags,
		"data": data,
		"saved_at": int(Time.get_unix_time_from_system())
	}

	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open temporary save file: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(save_dict))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		push_error("Could not write save file: %s" % error_string(write_error))
		return false

	if not _is_valid_save(_read_save_file(temp_path)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		push_error("Temporary save file did not validate")
		return false

	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temp_path),
		ProjectSettings.globalize_path(final_path)
	)
	if rename_error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		push_error("Could not commit save file: %s" % error_string(rename_error))
		return false

	_prune_old_saves(slot)
	return true


func load_game(save_dict: Dictionary) -> void:
	var loaded_flags: Dictionary = {}
	var legacy_global_flags: Variant = save_dict.get("global_flags", {})
	if legacy_global_flags is Dictionary:
		loaded_flags.merge(legacy_global_flags, true)
	var persistent_flags: Variant = save_dict.get("persistent_flags", save_dict.get("flags", {}))
	if persistent_flags is Dictionary:
		loaded_flags.merge(persistent_flags, true)
	replace_flags(loaded_flags)
	data = save_dict.get("data", {})


func get_save(slot: int) -> Dictionary:
	if slot < 0 or slot > MAX_SLOT:
		return {}
	var files := _get_save_files(slot)
	for filename in files:
		var save_dict := _read_save_file("%s/%s" % [SAVE_DIRECTORY, filename])
		if not save_dict.is_empty():
			return save_dict
	return {}


func has_save(slot: int) -> bool:
	return not get_save(slot).is_empty()


func get_save_display_name(slot: int) -> String:
	var save := get_save(slot)
	var prefix := "AUTO SAVE" if slot == 0 else "SLOT %d" % slot
	if save.is_empty():
		return "%s  //  EMPTY" % prefix
	var scene_name: String = String(save.get("scene_path", "Unknown scene")).get_file().get_basename()
	return "%s  //  %s" % [prefix, scene_name.to_upper()]


func _next_save_id() -> String:
	_save_counter += 1
	var timestamp := int(Time.get_unix_time_from_system() * 1000000.0) + _save_counter
	return "%020d" % timestamp


func _slot_prefix(slot: int) -> String:
	return "autosave_" if slot == 0 else "slot_%d_" % slot


func _get_save_files(slot: int) -> Array[String]:
	var matches: Array[String] = []
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(SAVE_DIRECTORY)):
		return matches
	for filename in DirAccess.get_files_at(SAVE_DIRECTORY):
		if filename.begins_with(_slot_prefix(slot)) and filename.ends_with(".json"):
			matches.append(filename)
	matches.sort()
	matches.reverse()
	return matches


func _read_save_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	if not parser.data is Dictionary:
		return {}
	var save_dict: Dictionary = parser.data
	return save_dict if _is_valid_save(save_dict) else {}


func _is_valid_save(save_dict: Dictionary) -> bool:
	if int(save_dict.get("version", 0)) != 1:
		return false
	if not save_dict.get("scene_path", "") is String:
		return false
	var player_position: Variant = save_dict.get("player_position", null)
	if not player_position is Array or player_position.size() != 2:
		return false
	if not save_dict.get("persistent_flags", save_dict.get("flags", {})) is Dictionary:
		return false
	if not save_dict.get("global_flags", {}) is Dictionary:
		return false
	return save_dict.get("data", {}) is Dictionary


func _prune_old_saves(slot: int) -> void:
	var files := _get_save_files(slot)
	for index in range(2, files.size()):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("%s/%s" % [SAVE_DIRECTORY, files[index]]))
