extends RichTextLabel

@onready var timer: Timer = $Timer
@export var type = ""
@export var timer_time = 0.1
var current_voice_profile: VoiceProfile = null
var _blip_char_counter: int = 0
var current_index = 0
var _parsed := ""

func _ready() -> void:
	bbcode_enabled = true
	scroll_active = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer.timeout.connect(_on_timer_timeout)


func play(full_text: String, speed: float = -1.0) -> void:
	type = full_text
	visible_characters = 0
	text = full_text
	_parsed = get_parsed_text()
	current_index = 0
	_blip_char_counter = 0
	var s: float = speed if speed > 0.0 else timer_time
	timer.start(s)


func reveal_all() -> void:
	timer.stop()
	visible_characters = -1
	current_index = _parsed.length()


func clear_text() -> void:
	timer.stop()
	text = ""
	_parsed = ""
	current_index = 0
	visible_characters = 0


func _on_timer_timeout():
	if current_index < _parsed.length():
		var c := _parsed[current_index]
		current_index += 1
		visible_characters = current_index
		DialogBox._on_char_revealed(c)
	else:
		timer.stop()
		DialogBox.on_typing_finished()
