extends Node

# Dictionary to store all persistent flags
var flags: Dictionary = {}

# Dictionary to store persistent data (positions, stats, etc.)
var data: Dictionary = {}

func _ready():
	# Initialize with default values
	reset_to_defaults()

func reset_to_defaults():
	flags = {
		"pills_taken": false,
		"talked_to_npc_1": false,
		# Add more flags as needed
	}
	
	data = {
		# Add persistent data like player stats, inventory, etc.
	}

# Flag management
func set_flag(flag_name: String, value: bool):
	flags[flag_name] = value
	print("Flag set:", flag_name, "=", value)

func get_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)

# Data management
func set_data(key: String, value):
	data[key] = value

func get_data(key: String, default_value = null):
	return data.get(key, default_value)

# Save/Load (implement later when needed)
func save_game():
	var save_dict = {
		"flags": flags,
		"data": data
	}
	# TODO: Save to file
	return save_dict

func load_game(save_dict: Dictionary):
	flags = save_dict.get("flags", {})
	data = save_dict.get("data", {})
