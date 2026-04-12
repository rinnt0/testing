extends Node2D

@export_multiline var dialogue_lines: Array[String] = [
	"Default dialogue line 1.",
	"Default dialogue line 2."
]

@onready var interact_prompt: InteractPrompt = $InteractPrompt
@onready var dialog_ui: CanvasLayer = $InteractPrompt/DialogUI
@onready var label: Label = $InteractPrompt/DialogUI/Label

var player_in_range = false
var is_showing = false
var current_line = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	dialog_ui.visible = false
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
				dialog_ui.visible = false
				get_tree().paused = false
				current_line = 0
				is_showing = false
