extends CanvasLayer
@onready var label: Label = $NinePatchRect/Label
@onready var portrait: TextureRect = $TextureRect
@onready var diamond: AnimatedSprite2D = $AnimatedSprite2D
# At the top with your other vars
var current_voice_profile: VoiceProfile = null
var _blip_char_counter: int = 0
var voice_profiles: Array[VoiceProfile] = []
var portraits: Array = []
var lines: Array[String] = []
var current_line = 0
var is_typing = false

signal dialog_finished

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_lines(new_lines: Array[String], new_portraits: Array = [], new_profiles: Array[VoiceProfile] = []):
	lines = new_lines
	portraits = new_portraits
	voice_profiles = new_profiles  # ← add this
	current_line = 0
	visible = true
	diamond.visible = false
	display_current_line()
	PlayerManager.player.can_look_up = false
	PlayerManager.player.state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	

func _input(event: InputEvent):
	if not visible:
		return
	if event.is_action_pressed("interact") and not event.is_echo():
		get_viewport().set_input_as_handled()
		if is_typing:
			# Show all text instantly
			label.timer.stop()
			label.text = lines[current_line]
			is_typing = false
			on_typing_finished()
		elif current_line + 1 < lines.size():
			current_line += 1
			display_current_line()
		else:
			visible = false
			PlayerManager.player.state_machine.process_mode = Node.PROCESS_MODE_INHERIT
			PlayerManager.player.can_look_up = true
			dialog_finished.emit()

func on_typing_finished():
	print("typing finished")
	is_typing = false
	diamond.visible = true

func display_current_line():
	is_typing = true
	diamond.visible = false
	_blip_char_counter = 0

	if voice_profiles.size() > current_line and voice_profiles[current_line] != null:
		current_voice_profile = voice_profiles[current_line]
	else:
		current_voice_profile = null

	label.type = lines[current_line]
	label.text = ""
	label.current_index = 0

	# Use the profile's speed if available, otherwise fall back to the label's default
	var speed = current_voice_profile.char_speed if current_voice_profile else label.timer_time
	label.timer.start(speed)  # ← changed from label.timer.start(label.timer_time)

	if portraits.size() > current_line and portraits[current_line] != null:
		portrait.texture = portraits[current_line]
		
		
func _on_char_revealed(c: String) -> void:
	print("profile: ", current_voice_profile)  # ← add this
	if AudioManager.is_silent_char(c):
		return
	_blip_char_counter += 1
	var every_n: int = current_voice_profile.blip_every_n_chars if current_voice_profile else 1
	if _blip_char_counter >= every_n:
		_blip_char_counter = 0
		var sound = current_voice_profile.blip_sound if current_voice_profile else null
		AudioManager.play_voice_blip(sound, current_voice_profile)
