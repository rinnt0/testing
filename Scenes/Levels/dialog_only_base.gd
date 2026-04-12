extends Node2D

@export_multiline var dialogue_lines: Array[String] = [
	"Default dialogue line 1.",
	"Default dialogue line 2."
]
@export var set_flag_on_complete: bool = false
@export var flag_name: String = "pills_taken"
@export var delete_after_interaction: bool = true

@onready var interact_prompt: InteractPrompt = $InteractPrompt
@onready var dialog_ui: CanvasLayer = $InteractPrompt/DialogUI
@onready var label: Label = $InteractPrompt/DialogUI/Label

var player_in_range = false
var is_showing = false
var current_line = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	dialog_ui.visible = false
	
	# Check if already collected - if so, delete immediately
	if set_flag_on_complete and has_node("/root/PersistentData"):
		if PersistentData.get_flag(flag_name):
			queue_free()
			return
	
	interact_prompt.body_entered.connect(_on_player_entered)
	interact_prompt.body_exited.connect(_on_player_exited)

func _on_player_entered():
	player_in_range = true
	
func _on_player_exited():
	player_in_range = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact") and player_in_range:
		if not is_showing:
			dialog_ui.visible = true
			get_tree().paused = true
			current_line = 0
			label.display_text(dialogue_lines[current_line])
			is_showing = true
		else:
			if current_line + 1 < dialogue_lines.size():
				current_line += 1
				label.display_text(dialogue_lines[current_line])
			else:
				# Dialogue finished
				dialog_ui.visible = false
				get_tree().paused = false
				current_line = 0
				is_showing = false
				
				# Set flag if enabled
				if set_flag_on_complete:
					# Set persistent flag
					if has_node("/root/PersistentData"):
						PersistentData.set_flag(flag_name, true)
					
					# Also set scene variable for backward compatibility
					if flag_name in get_tree().current_scene:
						get_tree().current_scene.set(flag_name, true)
				
				# Remove object if enabled
				if delete_after_interaction:
					queue_free()
