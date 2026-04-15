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
var _active_dialog_content: DialogContent = null
var _camera: PlayerCamera = null
var _original_zoom: Vector2 = Vector2.ONE  # ← store zoom before dialog starts
signal dialog_finished

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_lines(new_lines: Array[String], new_portraits: Array = [], new_profiles: Array[VoiceProfile] = [], content: DialogContent = null):
	lines = new_lines
	portraits = new_portraits
	voice_profiles = new_profiles
	_active_dialog_content = content
	current_line = 0
	visible = true
	diamond.visible = false
	# Capture original zoom before any dialog changes it
	var cam = PlayerManager.player.get_node_or_null("Camera2D")
	if cam:
		_original_zoom = cam.zoom
	display_current_line()
	PlayerManager.player.can_look_up = false
	PlayerManager.player.state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	

func _input(event: InputEvent):
	if not visible:
		return
	if event.is_action_pressed("interact") and not event.is_echo():
		get_viewport().set_input_as_handled()
		AudioManager.play_sfx(AudioManager.ui_click_sound)  # ← scroll
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
			_restore_camera()
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

	# Camera target for this line
	var target_pos: Variant = null
	if _active_dialog_content and _active_dialog_content.camera_targets.size() > current_line:
		var target_name = _active_dialog_content.camera_targets[current_line]
		if target_name != "":
			var marker = _active_dialog_content.get_node_or_null(target_name)
			if marker:
				target_pos = marker.global_position
		else:
			_restore_camera()

	# Camera zoom for this line
	var target_zoom: float = -1.0  # -1 means "no change"
	if _active_dialog_content and _active_dialog_content.camera_zoom.size() > current_line:
		target_zoom = _active_dialog_content.camera_zoom[current_line]

	if target_pos != null or target_zoom > 0.0:
		_move_camera_to(target_pos, target_zoom)

	label.type = lines[current_line]
	label.text = ""
	label.current_index = 0
	var speed = current_voice_profile.char_speed if current_voice_profile else label.timer_time
	label.timer.start(speed)

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

func _move_camera_to(target_pos: Variant, target_zoom: float = -1.0) -> void:
	if not _camera:
		_camera = PlayerManager.player.get_node_or_null("Camera2D")
	if not _camera:
		return

	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_parallel(true)

	# Only move if a position was given
	if target_pos != null:
		# Capture the exact visual center to prevent the initial snap
		var current_visual_pos = _camera.get_screen_center_position()

		# Detach from player movement
		_camera.cinematic_mode = true
		_camera.top_level = true
		_camera.position_smoothing_enabled = false

		# Teleport the 'actual' position to the 'visual' position immediately
		_camera.global_position = current_visual_pos

		tween.tween_property(_camera, "global_position", target_pos, 0.4)

	# Only zoom if a valid zoom was given
	if target_zoom > 0.0:
		tween.tween_property(_camera, "zoom", Vector2(target_zoom, target_zoom), 0.4)

func _restore_camera() -> void:
	if not _camera:
		return
		
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_parallel(true)
	
	# Calculate exactly where the camera sits relative to the player
	var target_return_pos = PlayerManager.player.global_position + Vector2(0, -17)
	
	tween.tween_property(_camera, "global_position", target_return_pos, 0.4)
	tween.tween_property(_camera, "zoom", _original_zoom, 0.4)  # ← restore zoom
	await tween.finished
	
	# Re-attach to player
	_camera.top_level = false
	_camera.cinematic_mode = false
	_camera.position = Vector2(0, -17)
	
	# Force the camera to 'forget' the transition and stick to the player
	_camera.reset_smoothing()
	_camera.position_smoothing_enabled = true
	
	_camera = null
