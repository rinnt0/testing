extends Label

@onready var labelz: Label = $"."
@onready var timer: Timer = $Timer
@export var type = ""
@export var timer_time = 0.1
# At the top with your other vars
var current_voice_profile: VoiceProfile = null
var _blip_char_counter: int = 0
var current_index = 0

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)
	timer.start(0.1)
	
	
func _on_timer_timeout():
	if current_index < type.length():
		labelz.text += type[current_index]
		DialogBox._on_char_revealed(type[current_index])  # ← add this line
		current_index += 1
	else:
		timer.stop()
		DialogBox.on_typing_finished()

# At the bottom
func _on_char_revealed(c: String) -> void:
	if AudioManager.is_silent_char(c):
		return
	_blip_char_counter += 1
	var every_n: int = current_voice_profile.blip_every_n_chars if current_voice_profile else 1
	if _blip_char_counter >= every_n:
		_blip_char_counter = 0
		var sound = current_voice_profile.blip_sound if current_voice_profile else null
		AudioManager.play_voice_blip(sound, current_voice_profile)
