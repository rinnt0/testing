extends Node

var flags: Dictionary = {
	"pills_taken": false,
	"talked_to_npc": false,
	"visited_hub": false,
	# Add any flags here, puzzle solved, character spoken to? , is this light on or off? anything really
}

# Use this to mark progress (e.g., taking the pills)
func set_flag(flag_name: String, value: bool):
	flags[flag_name] = value

# Use this to check if a player is allowed to do something.
func get_flag(flag_name: String) -> bool:
	# if the flag name doesn't exist yet, it just returns 'false'
	# instead of crashing the game.
	return flags.get(flag_name, false)
