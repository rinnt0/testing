class_name PlayerCamera extends Camera2D

@onready var camera: Camera2D = $"."

var cinematic_mode: bool = false


func _ready() -> void:
	LevelManager.tilemap_bounds_changed.connect( update_limits )
	update_limits( LevelManager.current_tilemap_bounds )
	pass


func _process(delta: float) -> void:
	look_up()
	pass
		
		
func look_up():
	if cinematic_mode:
		return
	if not PlayerManager.player.can_look_up:
		return
	if Input.is_action_pressed("up"):
		camera.position = Vector2(0, -50)
	else:
		camera.position = Vector2(0, -17)

func update_limits( bounds : Array[ Vector2 ] ):
	if bounds == []:
		return
	limit_left = int( bounds[0].x )
	limit_top = int( bounds[0].y )
	limit_right = int( bounds[1].x )
	limit_bottom = int( bounds[1].y )
	pass
