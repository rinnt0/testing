extends Node

signal wait_finished

var _wait_gen: int = 0
var _waiting: bool = false
var _skip_player_lock: bool = false
var _original_zoom: Vector2 = Vector2.ONE

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if _waiting and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_cancel()

func do_wait(content: WaitMoment, skip_player_lock: bool = false) -> void:
	_skip_player_lock = skip_player_lock
	_waiting = true
	_wait_gen += 1 
	var current_gen := _wait_gen

	# Capture original zoom so we can go back later
	var cam = PlayerManager.player.get_node_or_null("Camera2D")
	if cam:
		_original_zoom = cam.zoom

	if not skip_player_lock:
		_lock_player()

	for i in content.thought_delays.size():
		_show_thought_after(content, i, current_gen)

	await wait_finished

# Inside WaitBox.gd

func _cancel() -> void:
	if not _waiting:
		return
		
	_waiting = false
	_wait_gen += 1
	
	DialogBox.hide_wait_thought()
	
	# PASS THE ZOOM HERE:
	DialogBox.restore_camera(_original_zoom) 
	
	if not _skip_player_lock:
		_unlock_player()
	
	wait_finished.emit()

# ── helpers ──────────────────────────────────────────────────────────────────

func _lock_player() -> void:
	var sm = PlayerManager.player.state_machine
	var wait_state = sm.get_node_or_null("Wait")
	if wait_state:
		sm.change_state(wait_state)
	else:
		sm.process_mode = Node.PROCESS_MODE_DISABLED

func _unlock_player() -> void:
	var sm = PlayerManager.player.state_machine
	sm.process_mode = Node.PROCESS_MODE_INHERIT
	
	var idle_state = sm.get_node_or_null("Idle")
	if idle_state:
		sm.change_state(idle_state)
		
	PlayerManager.player.can_look_up = true

func _show_thought_after(content: WaitMoment, index: int, gen: int) -> void:
	await get_tree().create_timer(content.thought_delays[index]).timeout
	
	if _wait_gen != gen or not _waiting:
		return

	# 1. CAMERA LOGIC
	var target_pos: Variant = null
	if content.camera_targets.size() > index:
		var t_name = content.camera_targets[index]
		if t_name != "":
			var marker = content.get_node_or_null(t_name)
			if marker: 
				target_pos = marker.global_position
	
	var target_zoom: float = -1.0
	if content.camera_zoom.size() > index:
		target_zoom = content.camera_zoom[index]

	if target_pos != null or target_zoom > 0.0:
		DialogBox.move_camera_to(target_pos, target_zoom)

	# 2. TEXT LOGIC
	if index >= content.thoughts.size():
		return
		
	var text := content.thoughts[index]
	if content.deep_indices.has(index):
		text = "[color=red]" + text + "[/color]"
		
	var portrait = content.portraits[index] if index < content.portraits.size() else null
	
	# Fix: Use "voice_profiles" to match the WaitMoment script
	var voice_profile = content.voice_profiles[index] if index < content.voice_profiles.size() else null
	
	DialogBox.show_wait_thought(text, portrait, voice_profile)
