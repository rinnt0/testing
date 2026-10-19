extends Node

var flags: Dictionary:
	get:
		return PersistentData.flags
	set(value):
		PersistentData.replace_flags(value)


func reset_to_defaults() -> void:
	PersistentData.reset_flags_to_defaults()


func set_flag(flag_name: String, value: bool) -> void:
	PersistentData.set_flag(flag_name, value)


func get_flag(flag_name: String) -> bool:
	return PersistentData.get_flag(flag_name)
