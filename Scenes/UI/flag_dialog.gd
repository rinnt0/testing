class_name FlagDialogue extends Resource

# This script doesn't 'do' anything on its own—it's a container.
# It's like a specialized envelope that holds a specific conversation.

# The 'Key' that unlocks this conversation (e.g., "met_mysterious_man")
@export var flag_name: String = ""

# The actual lines for this specific situation
@export_multiline var dialogue_lines: Array[String] = []

# Which face to show for each line (0=Neutral, 1=Angry, etc.)
@export var portrait_indices: Array[int] = []

# Who is talking for each line (NPC vs Player)
@export var is_player_speaking: Array[bool] = []
