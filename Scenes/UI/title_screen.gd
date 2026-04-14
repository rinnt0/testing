extends Control

@export_file("*.tscn") var start_scene: String = ""
@export var music : AudioStream

func _ready() -> void:
	AudioManager.play_music( music )
	if PlayerManager.player:
		PlayerManager.player.visible = false
		var camera = PlayerManager.player.get_node_or_null("Camera2D")
		if camera:
			camera.enabled = false

func _on_start_pressed():
	if start_scene != "":
		await fade_out()
		LevelManager.load_new_level(start_scene, "", Vector2.ZERO)

func fade_out():
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	get_tree().root.add_child(canvas_layer)
	
	var color_rect = ColorRect.new()
	color_rect.color = Color.BLACK
	color_rect.color.a = 0
	color_rect.size = get_viewport_rect().size
	canvas_layer.add_child(color_rect)
	
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, 1.0)
	await tween.finished

func _on_quit_pressed():
	get_tree().quit()
