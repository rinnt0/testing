class_name LevelTilemap extends TileMapLayer

const PLAYER = preload("res://Scenes/Player/player.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame
	LevelManager.change_tilemap_bounds( get_combined_bounds() )

func get_combined_bounds() -> Array[Vector2]:
	var all_tilemaps = get_tree().get_nodes_in_group("tilemaps")
	
	var min_pos = get_tilemap_bounds()[0]
	var max_pos = get_tilemap_bounds()[1]
	
	for tilemap in all_tilemaps:
		if tilemap == self:
			continue
		var bounds = tilemap.get_tilemap_bounds()
		min_pos.x = min(min_pos.x, bounds[0].x)
		min_pos.y = min(min_pos.y, bounds[0].y)
		max_pos.x = max(max_pos.x, bounds[1].x)
		max_pos.y = max(max_pos.y, bounds[1].y)
	
	return [min_pos, max_pos]

func get_tilemap_bounds() -> Array[Vector2]:
	var bounds: Array[Vector2] = []
	bounds.append(Vector2(get_used_rect().position * tile_set.tile_size * 0.99))
	bounds.append(Vector2(get_used_rect().end * tile_set.tile_size * 0.99))
	return bounds
