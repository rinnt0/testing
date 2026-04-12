@tool
class_name LevelTransition extends Area2D

enum SIDE { TOP, DOWN, LEFT, RIGHT }

@export_file("*.tscn") var level
@export var target_transition_area : String = "level_transition_x"
@export_category("Collision Area Settings")
@export_range( 1, 12, 1, "or_greater") var size = 2 :
	set( value ):
		size = value
		_update_area()
@export var side : SIDE = SIDE.DOWN:
	set( value ):
		side = value
		_update_area()
@export var snap_to_grid = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D




func _ready() -> void:
	if collision_shape == null:
		collision_shape = get_node("CollisionShape2D")
	_update_area()
	if Engine.is_editor_hint():
		return
		
	monitoring = false
	place_player()
	
	await LevelManager.level_loaded
	monitoring = true
	body_entered.connect( player_entered )
	pass

func player_entered( _p : Node2D ):
	# Create persistent black overlay before transition
	var fade_canvas = CanvasLayer.new()
	fade_canvas.layer = 100
	get_tree().root.add_child(fade_canvas)
	
	var fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.color.a = 0
	fade_rect.size = get_viewport().get_visible_rect().size
	fade_canvas.add_child(fade_rect)
	
	# Fade to black
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.5)
	await tween.finished
	
	# Now transition (black stays)
	LevelManager.load_new_level( level, target_transition_area, get_offset() )

func place_player():
	if name != LevelManager.target_transition:
		return
	PlayerManager.set_player_position( global_position + LevelManager.position_offset )

func get_offset():
	var offset = Vector2.ZERO
	var player_pos = PlayerManager.player.global_position
	
	if side == SIDE.LEFT or side == SIDE.RIGHT:
		offset.y = player_pos.y - global_position.y
		offset.x = 16
		if side == SIDE.LEFT:
			offset.x *= -1
	
	return offset
	
func _update_area():
	var new_rect : Vector2 = Vector2(16, 16)
	var new_position : Vector2 = Vector2.ZERO
	
	if side == SIDE.TOP:
		new_rect.x *= size
		new_position.y -= 16
	elif side == SIDE.DOWN:
		new_rect.x *= size
		new_position.y += 16
	elif side == SIDE.LEFT:
		new_rect.y *= size
		new_position.x -= 16
	elif side == SIDE.RIGHT:
		new_rect.y *= size
		new_position.x += 16
	if collision_shape == null:
		if has_node("CollisionShape2D"):
			collision_shape = get_node("CollisionShape2D")
		else:
			return
			
	if collision_shape.shape:
		collision_shape.shape.size = new_rect
		collision_shape.position = new_position
