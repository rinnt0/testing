class_name Level extends Node2D

@onready var door_spawn: Marker2D = $Marker2D
@export var music : AudioStream
@export var ambient: AudioStream 

var pills_taken = false

# 1. Declare the variable, but don't assign it yet
var camera: Camera2D 

func _ready() -> void:
	add_to_group("level")  
	PlayerManager.set_as_parent(self) # This likely creates/assigns the player
	
	AudioManager.play_music(music)
	AudioManager.play_ambient(ambient)  
	
	# 2. Assign the camera ONLY if the player exists now
	if PlayerManager.player and is_instance_valid(PlayerManager.player):
		camera = PlayerManager.player.get_node_or_null("Camera2D")
		PlayerManager.player.visible = true
		
		if camera:
			camera.enabled = true
	
		# Re-enable player movement (in case it was disabled)
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
		# No transition set (Happens when using F6)
		# First try to find a PlayerSpawn node
		var default_spawn = get_node_or_null("PlayerSpawn")
		
		if default_spawn and PlayerManager.player and is_instance_valid(PlayerManager.player):
			PlayerManager.set_player_position(default_spawn.global_position)
			if not PlayerManager.player_spawned:
				PlayerManager.player.scale.x = 1 # Adjust facing direction if needed
				
		# Fall back to door_spawn if PlayerSpawn doesn't exist in this level
		elif door_spawn and PlayerManager.player and is_instance_valid(PlayerManager.player):
			PlayerManager.set_player_position(door_spawn.global_position)
			if not PlayerManager.player_spawned:
				PlayerManager.player.scale.x = -1
	
	# Force camera to snap instantly
	if PlayerManager.player and is_instance_valid(PlayerManager.player):
		if camera:
			camera.reset_smoothing()
	
	# Connect right away. If another load starts while we are still fading in,
	# this level must still be able to free itself.
	LevelManager.level_load_started.connect(_free_level)

	await get_tree().process_frame

	# When TransitionBox triggered this load it fades itself in (transition_box.gd).
	# Running a second fade on top of it was what made the end of the fade pop.
	if not TransitionBox.visible:
		await _fade_in_from_black()

func _fade_in_from_black() -> void:
	# LevelTransition leaves a black rect in the "scene_fade" group - reuse it.
	var color_rect := get_tree().get_first_node_in_group("scene_fade") as ColorRect
	var canvas_layer: CanvasLayer = null
	if color_rect:
		canvas_layer = color_rect.get_parent() as CanvasLayer
	else:
		# Nothing to continue from (e.g. running the level with F6): start black.
		canvas_layer = CanvasLayer.new()
		canvas_layer.layer = 100
		get_tree().root.add_child(canvas_layer)
		color_rect = ColorRect.new()
		color_rect.color = Color.BLACK
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas_layer.add_child(color_rect)
		color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Tween lives on the overlay, not on this Level, so it still finishes (and the
	# overlay still gets freed) even if this level is freed mid-fade.
	canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var tween := canvas_layer.create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, 1.0)
	tween.finished.connect(canvas_layer.queue_free)
	await tween.finished

func _free_level():
	PlayerManager.unparent_player(self)
	queue_free()
