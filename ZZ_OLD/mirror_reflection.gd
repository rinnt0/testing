extends Sprite2D
@export var mirror_center_x: float = 0.0
@export var y_offset: float = -50.0
@export var x_offset: float = 25.0
@export var transparency: float = 0.6
@export var final_mirror_x: float = 0.0
@export var freeze_at_player_x: float = 0.0
@export var mirror_interact: InteractPrompt  # Reference to the interact prompt
var is_frozen = false
var is_fading = false
var frozen_position: Vector2
var frozen_frame: int
var frozen_texture: Texture2D
var frozen_scale_x: float
func _ready() -> void:
	# Hide the interact prompt initially
	if mirror_interact:
		mirror_interact.visible = false
func _process(delta: float) -> void:
	if PlayerManager.player:
		var player_sprite = PlayerManager.player.get_node("Sprite2D")

		# Check if player has passed the freeze point
		if not is_frozen and PlayerManager.player.global_position.x >= freeze_at_player_x:
			# Freeze the reflection
			is_frozen = true
			frozen_position = global_position
			frozen_frame = 0
			frozen_texture = player_sprite.texture
			frozen_scale_x = player_sprite.scale.x

			# Start fade out
			if not is_fading:
				is_fading = true
				var tween = create_tween()
				tween.tween_property(self, "modulate:a", 0.0, 2.0)
				await tween.finished

				# Show interact prompt after fade completes
				if mirror_interact:
					mirror_interact.visible = true

		if is_frozen:
			# Display frozen reflection
			global_position = frozen_position
			texture = frozen_texture
			frame = frozen_frame
			scale.x = frozen_scale_x
		else:
			# Normal reflection behavior
			global_position.y = PlayerManager.player.global_position.y + y_offset
			var distance_from_mirror = PlayerManager.player.global_position.x - mirror_center_x
			global_position.x = mirror_center_x + distance_from_mirror + x_offset

			texture = player_sprite.texture
			frame = player_sprite.frame
			scale.x = player_sprite.scale.x
			modulate.a = transparency
