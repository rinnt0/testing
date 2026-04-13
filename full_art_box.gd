extends CanvasLayer

@onready var sprite: TextureRect = $TextureRect
@onready var color_rect: ColorRect = $ColorRect
@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal art_finished

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_art(content: FullArtContent):
	visible = true
	sprite.texture = content.texture
	sprite.visible = false
	PlayerManager.player.state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	PlayerManager.player.can_look_up = false
	
	animation_player.play("FA_1")
	await animation_player.animation_finished
	
	sprite.visible = true
	
	animation_player.play("FA_2")
	await animation_player.animation_finished
	
	if content.lines.size() > 0:
		DialogBox.show_lines(content.lines, content.portraits)
		await DialogBox.dialog_finished
	else:
		await wait_for_interact()
	
	animation_player.play("FA_1")
	await animation_player.animation_finished
	
	sprite.visible = false
	
	animation_player.play("FA_2")
	await animation_player.animation_finished
	
	visible = false
	PlayerManager.player.state_machine.process_mode = Node.PROCESS_MODE_INHERIT
	PlayerManager.player.can_look_up = true
	art_finished.emit()

func wait_for_interact():
	while true:
		if Input.is_action_just_pressed("interact"):
			break
		await get_tree().process_frame
