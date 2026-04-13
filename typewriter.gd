extends Label

@onready var labelz: Label = $"."
@onready var timer: Timer = $Timer
@export var type = ""
@export var timer_time = 0.1

var current_index = 0

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)
	timer.start(0.1)
	
	
func _on_timer_timeout():
	if current_index < type.length():
		labelz.text += type[current_index]
		current_index += 1
	else:
		timer.stop()
		DialogBox.on_typing_finished()
