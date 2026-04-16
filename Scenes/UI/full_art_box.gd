extends CanvasLayer

@onready var sprite: TextureRect             = $TextureRect
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var color_rect: ColorRect           = $ColorRect
@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal art_finished

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_art(content: FullArtContent, leave_black: bool = false):
	visible = true

	# --- configure the correct display node, hide the other ---
	_setup_display(content)

	PlayerManager.player.state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	PlayerManager.player.can_look_up = false

	animation_player.play("FA_1")
	await animation_player.animation_finished

	# show whichever node is active
	if content.is_animated():
		animated_sprite.visible = true
		animated_sprite.play(content.animation_name)
	else:
		sprite.visible = true

	animation_player.play("FA_2")
	await animation_player.animation_finished

	# if animated + play-once, wait for it to finish before dialog/interact
	if content.is_animated() and not content.loop:
		await animated_sprite.animation_finished

	if content.lines.size() > 0:
		DialogBox.show_lines(content.lines, content.portraits, content.voice_profiles)
		await DialogBox.dialog_finished
	else:
		await wait_for_interact()

	# stop animation before fade-out to avoid a visible pop
	if content.is_animated():
		animated_sprite.stop()

	animation_player.play("FA_1")
	await animation_player.animation_finished

	sprite.visible        = false
	animated_sprite.visible = false

	if not leave_black:
		animation_player.play("FA_2")
		await animation_player.animation_finished
		visible = false
		PlayerManager.player.state_machine.process_mode = Node.PROCESS_MODE_INHERIT
		PlayerManager.player.can_look_up = true

	art_finished.emit()

# ── helpers ──────────────────────────────────────────────────────────────────

func _setup_display(content: FullArtContent) -> void:
	if content.is_animated():
		animated_sprite.sprite_frames = content.animated_frames
		animated_sprite.sprite_frames.set_animation_loop(content.animation_name, content.loop)

		# Match the AnimatedSprite2D to the TextureRect's position and size
		var rect: Rect2 = sprite.get_rect()
		var frame_tex: Texture2D = animated_sprite.sprite_frames.get_frame_texture(content.animation_name, 0)
		if frame_tex:
			var frame_size: Vector2 = frame_tex.get_size()
			animated_sprite.centered = true
			animated_sprite.position = rect.get_center()
			animated_sprite.scale = rect.size / frame_size

		animated_sprite.visible = false
		sprite.visible = false
	else:
		sprite.texture = content.texture
		sprite.visible = false
		animated_sprite.visible = false

func play_fade_in():
	visible = true
	animation_player.play("FA_2")
	await animation_player.animation_finished
	visible = false

func wait_for_interact():
	while true:
		if Input.is_action_just_pressed("interact"):
			break
		await get_tree().process_frame
