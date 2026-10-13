extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
@onready var transition_label: Label = $Label

signal transition_finished

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func do_transition(content: TransitionContent, already_black: bool = false):
	visible = true
	transition_label.modulate.a = 0.0
	transition_label.text = ""
	
	# ADD SAFETY CHECK: The player might not exist on the title screen
	if PlayerManager.player:
		PlayerManager.lock_player()

	if not already_black:
		color_rect.color.a = 0.0
		var tween = create_tween()
		tween.tween_property(color_rect, "color:a", 1.0, 1.0)
		await tween.finished
	else:
		color_rect.color.a = 1.0

	# Loop through each transition text line
	for i in content.transition_texts.size():
		var text = content.transition_texts[i]
		if text == "":
			continue

		var profile = null
		if content.voice_profiles.size() > i:
			profile = content.voice_profiles[i]

		transition_label.modulate.a = 1.0
		await _typewrite(transition_label, text, profile)
		await _wait_for_interact()

		var tween = create_tween()
		tween.tween_property(transition_label, "modulate:a", 0.0, 0.5)
		await tween.finished

	# 1. Trigger the level load
	LevelManager.load_new_level(content.next_scene_path, content.transition_target, Vector2.ZERO)
	
	# 2. WAIT for the engine to actually swap the scenes
	await get_tree().process_frame
	
	# 3. Play the intro fade-in BEFORE hiding the TransitionBox
	# This ensures there is no gap where the Title Screen is visible.
	await FullArtBox.play_fade_in()

	if PlayerManager.player:
		PlayerManager.player.visible = true
		var camera = PlayerManager.player.get_node_or_null("Camera2D")
		if camera:
			camera.enabled = true
			camera.top_level = false
			camera.cinematic_mode = false
			camera.position = Vector2(0, -17)
			camera.reset_smoothing()
	visible = false
	PlayerManager.unlock_player()
	transition_finished.emit()

func _typewrite(label_node: Label, text: String, profile: VoiceProfile = null):
	label_node.text = text
	label_node.visible_characters = 0
	var typing_speed = 10
	var typing_time = 0.0
	var last_visible = 0
	var blip_counter = 0

	while label_node.visible_characters < label_node.get_total_character_count():
		typing_time += get_process_delta_time()
		label_node.visible_characters = int(typing_speed * typing_time)

		if label_node.visible_characters > last_visible:
			for i in range(last_visible, label_node.visible_characters):
				var c = text[i]
				if not AudioManager.is_silent_char(c):
					blip_counter += 1
					var every_n = profile.blip_every_n_chars if profile else 1
					if blip_counter >= every_n:
						blip_counter = 0
						AudioManager.play_voice_blip(profile.blip_sound if profile else null, profile)
			last_visible = label_node.visible_characters

		await get_tree().process_frame

func _wait_for_interact():
	while true:
		if Input.is_action_just_pressed("interact"):
			break
		await get_tree().process_frame

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		print("!!! ALERT: TransitionBox is being deleted!")
		# This will print to the console the moment it's freed
		# Look at the Stack Trace in the debugger to see what called it.
