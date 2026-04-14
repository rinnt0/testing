extends CanvasLayer

@export_multiline var cutscene_lines: Array[String] = [
	"First line of the story...",
	"Second line...",
	"Third line..."
]
@export_file("*.tscn") var next_scene: String = ""

var current_line = 0
var is_typing = false

@onready var label: Label = $Label
@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	# Setup
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	
	# Create black background
	color_rect.color = Color.BLACK
	color_rect.size = get_viewport().get_visible_rect().size
	
	# Setup label
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = get_viewport().get_visible_rect().size
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", Color.WHITE)
	
	# Start first line
	display_line(cutscene_lines[current_line])

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact") and not is_typing:
		# Advance to next line or end
		if current_line + 1 < cutscene_lines.size():
			current_line += 1
			display_line(cutscene_lines[current_line])
		else:
			# Cutscene done, go to next scene
			end_cutscene()

func display_line(text: String):
	is_typing = true
	label.text = text
	label.visible_characters = 0
	
	var typing_speed = 10
	var typing_time = 0.0
	
	while label.visible_characters < label.get_total_character_count():
		typing_time += get_process_delta_time()
		label.visible_characters = typing_speed * typing_time as int
		await get_tree().process_frame
	
	is_typing = false

func end_cutscene():
	# Fade out the text first
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	await tween.finished
	
	# Create a NEW black overlay on the root that will persist
	var new_canvas = CanvasLayer.new()
	new_canvas.layer = 100
	get_tree().root.add_child(new_canvas)
	
	var new_black = ColorRect.new()
	new_black.color = Color.BLACK
	new_black.color.a = 1.0
	new_black.size = get_viewport().size * 4
	new_canvas.add_child(new_black)
	
	# Now transition - this new black screen will stay
	get_tree().change_scene_to_file(next_scene)
