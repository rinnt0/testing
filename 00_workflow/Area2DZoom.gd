class_name CameraZoomArea extends Area2D

@export var target_zoom: Vector2 = Vector2(6, 6)
@export var zoom_duration: float = 0.5
@export var area_music: AudioStream  # Leave empty to keep level music as-is

var _camera: PlayerCamera
var _level_music: AudioStream  # stores the level's original track

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	await get_tree().process_frame
	_camera = get_tree().get_first_node_in_group("player_camera")
	
	# Grab the level's music so we can restore it on exit
	var level = get_tree().get_first_node_in_group("level")
	if level:
		_level_music = level.music

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if _camera:
		_camera.tween_zoom(target_zoom, zoom_duration)
	if area_music:
		AudioManager.play_music(area_music)

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if _camera:
		_camera.tween_zoom(_camera.default_zoom, zoom_duration)
