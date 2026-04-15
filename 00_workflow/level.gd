class_name Level extends Node2D

@onready var door_spawn: Marker2D = $Marker2D
@export var music : AudioStream
@export var ambient: AudioStream 

var pills_taken = false
var camera = PlayerManager.player.get_node("Camera2D")
func _ready() -> void:
	PlayerManager.set_as_parent(self)
	AudioManager.play_music( music )
	AudioManager.play_ambient( ambient )  # ← add this
	
	PlayerManager.player.visible = true
	if camera:
		camera.enabled = true
	
	# Re-enable player movement (in case it was disabled)
	if PlayerManager.player and is_instance_valid(PlayerManager.player):
		PlayerManager.player.set_physics_process(true)
		PlayerManager.player.set_process(true)
	
	# Check for specific spawn point first (from elevator or level transition)
	if LevelManager.target_transition != "":
		var spawn_point = get_node_or_null(LevelManager.target_transition)
		if spawn_point and PlayerManager.player and is_instance_valid(PlayerManager.player):
			PlayerManager.set_player_position(spawn_point.global_position)
		else:
			print("WARNING: Spawn point not found:", LevelManager.target_transition)
			# Fall back to door_spawn
			if door_spawn and PlayerManager.player and is_instance_valid(PlayerManager.player):
				PlayerManager.set_player_position(door_spawn.global_position)
	else:
		# No transition set, use default spawn
		if door_spawn and PlayerManager.player and is_instance_valid(PlayerManager.player):
			PlayerManager.set_player_position(door_spawn.global_position)
			if not PlayerManager.player_spawned:
				PlayerManager.player.scale.x = -1
	
	# Force camera to snap instantly
	if PlayerManager.player and is_instance_valid(PlayerManager.player):
		if camera:
			camera.reset_smoothing()
	
	await get_tree().process_frame
	
	# Find existing black overlay from previous scene
	var canvas_layer = null
	var color_rect = null
	
	for child in get_tree().root.get_children():
		if child is CanvasLayer:
			for subchild in child.get_children():
				if subchild is ColorRect and subchild.color == Color.BLACK:
					canvas_layer = child
					color_rect = subchild
					break
	
	# If we found it, fade it out. Otherwise create new one
	if color_rect:
		var tween = create_tween()
		tween.tween_property(color_rect, "color:a", 0.0, 1.0)
		await tween.finished
	else:
		# No existing overlay, create and fade in
		canvas_layer = CanvasLayer.new()
		canvas_layer.layer = 100
		get_tree().root.add_child(canvas_layer)
		
		color_rect = ColorRect.new()
		color_rect.color = Color.BLACK
		color_rect.color.a = 1.0
		color_rect.size = get_viewport_rect().size
		canvas_layer.add_child(color_rect)
		
		var tween = create_tween()
		tween.tween_property(color_rect, "color:a", 0.0, 1.0)
		await tween.finished
		canvas_layer.queue_free()
	
	LevelManager.level_load_started.connect(_free_level)

func _free_level():
	PlayerManager.unparent_player(self)
	queue_free()
