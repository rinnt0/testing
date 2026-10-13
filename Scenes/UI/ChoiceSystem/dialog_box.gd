extends CanvasLayer
@onready var label: RichTextLabel = $NinePatchRect/Label
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
var _is_walking: bool = false
var _is_wait_thought: bool = false  # ← true while WaitMoment is displaying; blocks input
var _wait_thought_gen: int = 0      # ← ADD THIS: tracks the active wait thought to prevent premature hiding
signal dialog_finished
var is_closing: bool = false
var _fade_tween: Tween
func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_lines(new_lines: Array[String], new_portraits: Array = [], new_profiles: Array[VoiceProfile] = [], content: DialogContent = null):
	
	lines = new_lines
	portraits = new_portraits
	voice_profiles = new_profiles
	_active_dialog_content = content
	current_line = 0
	fade_in()
	diamond.visible = false
	# Capture original zoom before any dialog changes it
	var cam = PlayerManager.player.get_node_or_null("Camera2D")
	if cam:
		_original_zoom = cam.zoom
	display_current_line()
	PlayerManager.player.can_look_up = false
	PlayerManager.player.state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	PlayerManager.player.movement_locked = true

# ─────────────────────────────────────────────
#  WaitMoment thoughts — no player state management, no input, no diamond.
#  WaitBox calls this; it calls hide_wait_thought() when the wait ends.
# ─────────────────────────────────────────────
func show_wait_thought(text: String, portrait_tex: Texture2D = null, voice_profile: VoiceProfile = null) -> void:
	_wait_thought_gen += 1  # ← Invalidate any previous hide timers
	_is_wait_thought = true
	current_voice_profile = voice_profile
	fade_in()
	diamond.visible = false
	portrait.texture = portrait_tex
	var speed = voice_profile.char_speed if voice_profile else label.timer_time
	label.play(text, speed)
	PlayerManager.player.movement_locked = true
	is_typing = true

func hide_wait_thought() -> void:
	_wait_thought_gen += 1  # ← Prevent any lingering 5-second timers from firing
	_is_wait_thought = false
	await fade_out()
	PlayerManager.player.movement_locked = false
	label.clear_text()

func _input(event: InputEvent):
	if is_closing:
		return
	if _is_wait_thought:
		# Consume interact so it can't bleed into _unhandled_input handlers.
		# ui_cancel is intentionally left unconsumed so WaitBox can catch it.
		if event.is_action_pressed("interact") and not event.is_echo():
			get_viewport().set_input_as_handled()
		return
	if _is_walking:
		get_viewport().set_input_as_handled()
		return
	if not visible:
		return
	if lines.is_empty():
		return
	if event.is_action_pressed("interact") and not event.is_echo():
		get_viewport().set_input_as_handled()
		AudioManager.play_sfx(AudioManager.ui_click_sound)  # ← scroll
		if is_typing:
			label.reveal_all()
			is_typing = false
			on_typing_finished()
		elif current_line + 1 < lines.size():
			current_line += 1
			display_current_line()
		else:
			
			restore_camera()
			PlayerManager.player.state_machine.process_mode = Node.PROCESS_MODE_INHERIT
			PlayerManager.player.can_look_up = true
			PlayerManager.player.movement_locked = false
			await fade_out()
			dialog_finished.emit()

func on_typing_finished():
	print("typing finished")
	is_typing = false
	if not _is_wait_thought:
		diamond.visible = true
	else:
		# ← ADD THIS BLOCK: Auto-hide wait thoughts 5 seconds after they finish typing
		var current_gen = _wait_thought_gen
		await get_tree().create_timer(5.0).timeout
		
		# Only hide if we are still on the exact same thought and haven't been canceled
		if _is_wait_thought and _wait_thought_gen == current_gen:
			hide_wait_thought()

func display_current_line():
	if lines.is_empty():
		visible = false
		dialog_finished.emit.call_deferred()  # deferred so await can catch it
		return
	is_typing = true
	diamond.visible = false
	_blip_char_counter = 0

	# 1. SET VOICE PROFILE
	if voice_profiles.size() > current_line and voice_profiles[current_line] != null:
		current_voice_profile = voice_profiles[current_line]
	else:
		current_voice_profile = null

	# 2. PLAYER WALKING (DO THIS FIRST)
	if _active_dialog_content and _active_dialog_content.player_targets.size() > current_line:
		var player_target_name = _active_dialog_content.player_targets[current_line]
		if player_target_name != "":
			var player_marker = _active_dialog_content.get_node_or_null(player_target_name)
			if player_marker:
				_is_walking = true       # ← lock
				await fade_out()         # ← cinematic fade out
				await _walk_player_to(player_marker.global_position)
				_is_walking = false      # ← unlock
				fade_in()                # ← cinematic fade in

	# 3. CAMERA LOGIC (WAITING IS DONE)
	# Because of the 'await' above, this code won't run until the walk finishes.
	var target_pos: Variant = null
	if _active_dialog_content and _active_dialog_content.camera_targets.size() > current_line:
		var target_name = _active_dialog_content.camera_targets[current_line]
		if target_name != "":
			var marker = _active_dialog_content.get_node_or_null(target_name)
			if marker:
				target_pos = marker.global_position
		else:
			restore_camera()

	var target_zoom: float = -1.0
	if _active_dialog_content and _active_dialog_content.camera_zoom.size() > current_line:
		target_zoom = _active_dialog_content.camera_zoom[current_line]

	if target_pos != null or target_zoom > 0.0:
		move_camera_to(target_pos, target_zoom)

	# 4. START TEXT TYPING
	var speed = current_voice_profile.char_speed if current_voice_profile else label.timer_time
	label.play(lines[current_line], speed)

	if portraits.size() > current_line and portraits[current_line] != null:
		portrait.texture = portraits[current_line]


func _walk_player_to(target_pos: Vector2) -> void:
	var player = PlayerManager.player
	var walk_duration = abs(player.global_position.x - target_pos.x) / 100.0
	walk_duration = clamp(walk_duration, 0.1, 2.0)

	# 1. Determine the new direction based on movement
	var new_dir = Vector2.LEFT if target_pos.x < player.global_position.x else Vector2.RIGHT
	
	# 2. Update the Player's internal state so the scripts stay in sync
	player.current_direction = new_dir
	
	# 3. Update the visual scale
	player.sprite.scale.x = -1 if new_dir == Vector2.LEFT else 1

	player.update_animation("walk")

	var tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(player, "global_position", Vector2(target_pos.x, player.global_position.y), walk_duration)
	await tween.finished

	player.update_animation("idle")
		
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

func move_camera_to(target_pos: Variant, target_zoom: float = -1.0) -> void:
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

# Inside DialogBox.gd

func restore_camera(preferred_zoom: Variant = null) -> void:
	if not _camera:
		_camera = PlayerManager.player.get_node_or_null("Camera2D")
	if not _camera:
		return
		
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_parallel(true)
	
	# Determine which zoom to return to: 
	# 1. The one passed in (WaitBox's)
	# 2. The one stored here (DialogBox's)
	# 3. Default to (1,1) if all else fails
	var final_zoom = _original_zoom
	if preferred_zoom is Vector2:
		final_zoom = preferred_zoom
	
	var target_return_pos = PlayerManager.player.global_position + Vector2(0, -17)
	
	tween.tween_property(_camera, "global_position", target_return_pos, 0.4)
	tween.tween_property(_camera, "zoom", final_zoom, 0.4)
	
	await tween.finished
	
	# Re-attach logic
	_camera.top_level = false
	_camera.cinematic_mode = false
	_camera.position = Vector2(0, -17)
	_camera.reset_smoothing()
	_camera.position_smoothing_enabled = true
	_camera = null


func fade_in():
	is_closing = false
	visible = true
	
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
		
	_fade_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Start transparent
	$NinePatchRect.modulate.a = 0.0
	portrait.modulate.a = 0.0
	
	_fade_tween.tween_property($NinePatchRect, "modulate:a", 1.0, 0.2)
	_fade_tween.tween_property(portrait, "modulate:a", 1.0, 0.2)

func fade_out():
	if is_closing: return
	is_closing = true
	
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
		
	_fade_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	_fade_tween.tween_property($NinePatchRect, "modulate:a", 0.0, 0.2)
	_fade_tween.tween_property(portrait, "modulate:a", 0.0, 0.2)
	
	await _fade_tween.finished
	
	visible = false
	is_closing = false
