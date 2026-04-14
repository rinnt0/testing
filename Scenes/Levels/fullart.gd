extends Sprite2D

@export var full_art_texture: Texture2D
@export var trigger_transition = false
@export var transition_text = ""
@export var transition_target = ""
@export_file("*.tscn") var next_scene_path = ""
@export_multiline var dialogue_lines: Array[String] = [
	"Default full art dialogue 1.",
	"Default full art dialogue 2."
]
@export var lamp_light_path: NodePath
@export var warn_text = ""

# New requirement settings

@export var requires_condition: bool = false
#####
# add flags here to add them to the dropdown!!
####
@export var required_flag: String = "pills_taken"

@onready var collision_shape_2d: CollisionShape2D = $"../CollisionShape2D"
@onready var plant: InteractPrompt = $".."
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var dialog_ui: CanvasLayer = $"../DialogUI"
@onready var label: Label = $"../DialogUI/Label"
@onready var sprite_2d: Sprite2D = $"."

var point_light: PointLight2D
var smile = 1
var player_in_range = false
var anim_done = true
var current_line = 0
var is_transitioning = false
var show_warning = false

func _ready() -> void:
	sprite_2d.visible = false
	sprite_2d.texture = full_art_texture
	animation_player.play("FA_1")
	animation_player.stop()
	dialog_ui.visible = false
	
	if lamp_light_path:
		point_light = get_node(lamp_light_path)
	
	animation_player.animation_finished.connect(_finished_anim)
	plant.body_entered.connect(_on_player_entered)
	plant.body_exited.connect(_on_player_exited)

func _finished_anim():
	anim_done = true

func _on_player_entered():
	player_in_range = true
	
func _on_player_exited():
	player_in_range = false

func check_requirement() -> bool:
	if not requires_condition:
		return true
	
	return PersistentData.get_flag(required_flag)
	
	# Check persistent flags first, fall back to scene variables
	#match required_flag:
	#	"pills_taken":
	#		return PersistentData.get_flag("pills_taken")
	#	"other_flag":
	#		return PersistentData.get_flag("other_flag")
	#	_:
	#		return true

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact") and player_in_range and not is_transitioning:
		if not check_requirement():
			if not show_warning:
				dialog_ui.visible = true
				get_tree().paused = true
				label.display_text(warn_text)
				show_warning = true
			else:
				dialog_ui.visible = false
				get_tree().paused = false
				show_warning = false
			return
		
		if smile == 1:
			if anim_done == true:
				anim_done = false
				get_tree().paused = true
				dialog_ui.visible = false
				animation_player.play("FA_1")
				await animation_player.animation_finished
				animation_player.play("FA_2")
				
				if smile == 1:
					var viewport = get_viewport().get_camera_2d()
					sprite_2d.global_position = viewport.get_screen_center_position()
					sprite_2d.visible = true
					
					if point_light:
						point_light.visible = false
					
					# Check if there are dialogue lines
					if dialogue_lines.size() > 0:
						dialog_ui.visible = true
						current_line = 0
						label.display_text(dialogue_lines[current_line])
						smile = 2
					else:
						# No dialogue, just show the art
						smile = 2
					
		elif smile == 2:
			if dialogue_lines.size() > 0 and current_line + 1 < dialogue_lines.size():
				current_line += 1
				label.display_text(dialogue_lines[current_line])
			else:
				dialog_ui.visible = false
				is_transitioning = true
				
				animation_player.play("FA_1")
				await animation_player.animation_finished
				
				sprite_2d.visible = false
				
				if point_light:
					point_light.visible = true
				
				if trigger_transition and next_scene_path != "":
					await do_scene_transition()
				else:
					animation_player.play("FA_2")
					
					get_tree().paused = false
					current_line = 0
					anim_done = true
					smile = 1
					is_transitioning = false

func do_scene_transition():
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(canvas_layer)
	
	var color_rect = ColorRect.new()
	color_rect.color = Color.BLACK
	color_rect.color.a = 0
	color_rect.size = get_viewport_rect().size
	canvas_layer.add_child(color_rect)
	
	var transition_label = Label.new()
	transition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transition_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	transition_label.position = Vector2.ZERO
	transition_label.size = get_viewport_rect().size
	transition_label.modulate.a = 0
	transition_label.add_theme_font_size_override("font_size", 32)
	canvas_layer.add_child(transition_label)
	
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, 1.0)
	await tween.finished
	
	sprite_2d.visible = false
	
	transition_label.modulate.a = 1.0
	await typewrite_text(transition_label, transition_text)
	
	await wait_for_interact()
	
	tween = create_tween()
	tween.tween_property(transition_label, "modulate:a", 0.0, 0.5)
	await tween.finished
	transition_label.queue_free()

	var new_canvas = CanvasLayer.new()
	new_canvas.layer = 100
	get_tree().root.add_child(new_canvas)

	var new_black = ColorRect.new()
	new_black.color = Color.BLACK
	new_black.color.a = 1.0
	new_black.size = get_viewport().size * 4
	new_canvas.add_child(new_black)

	canvas_layer.queue_free()
	
	LevelManager.load_new_level(next_scene_path, transition_target, Vector2.ZERO)

func typewrite_text(label_node: Label, text: String):
	label_node.text = text
	label_node.visible_characters = 0
	var typing_speed = 10
	var typing_time = 0.0
	
	while label_node.visible_characters < label_node.get_total_character_count():
		typing_time += get_process_delta_time()
		label_node.visible_characters = typing_speed * typing_time as int
		await get_tree().process_frame

func wait_for_interact():
	while true:
		if Input.is_action_just_pressed("interact"):
			break
		await get_tree().process_frame
