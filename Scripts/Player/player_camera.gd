class_name PlayerCamera extends Camera2D

@onready var camera: Camera2D = $"."
var cinematic_mode: bool = false

@export var default_zoom: Vector2 = Vector2(6, 6)  # ADD THIS
var _zoom_tween: Tween                              # ADD THIS

func _ready() -> void:
	LevelManager.tilemap_bounds_changed.connect(update_limits)
	update_limits(LevelManager.current_tilemap_bounds)
	add_to_group("player_camera")  # ADD THIS so the Area2D can find it

func _process(delta: float) -> void:
	look_up()

func look_up():
	if cinematic_mode:
		return
	if not PlayerManager.player.can_look_up:
		return
	if Input.is_action_pressed("up"):
		camera.position = Vector2(0, -50)
	else:
		camera.position = Vector2(0, -17)

func update_limits(bounds: Array[Vector2]):
	if bounds == []:
		return
	limit_left   = int(bounds[0].x)
	limit_top    = int(bounds[0].y)
	limit_right  = int(bounds[1].x)
	limit_bottom = int(bounds[1].y)

# ADD THIS FUNCTION
func tween_zoom(target: Vector2, duration: float) -> void:
	if _zoom_tween:
		_zoom_tween.kill()
	_zoom_tween = create_tween()
	_zoom_tween.set_ease(Tween.EASE_IN_OUT)
	_zoom_tween.set_trans(Tween.TRANS_SINE)
	_zoom_tween.tween_property(self, "zoom", target, duration)
