extends Label

@onready var label: Label = $"."

var _typing_speed = 10 # characters revealed per second
var _typing_time : float

# Emitted when the entire string of text is fully visible on screen
signal typing_finished

func _ready() -> void:
	# Keep the typewriter completely hidden until it's called
	label.text = "" # when the game starts make sure the text is empty.
	label.visible = false # and hide it so you dont get jumpscared with random text
	pass



func display_text(new_text : String):
	label.visible = true
	label.text = new_text
	label.visible_characters = 0 # reset all character on fresh dialog
	_typing_time = 0 # reset the stopwatch
	
	# Keep looping as long as there are still hidden characters
	while label.visible_characters < label.get_total_character_count():
		# Add the time that passed during this specific frame to the stopwatch
		_typing_time += get_process_delta_time()
		
		# Calculate how many characters should be visible based on speed and time
		label.visible_characters = _typing_speed * _typing_time as int
		
		# VERY IMPORTANT: Pause this loop until the next frame so the game doesn't freeze
		await get_tree().process_frame
		
	# Yell out to the rest of the game that the text is done typing
	emit_signal("typing_finished")
