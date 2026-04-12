extends Node2D

# Dialogue sets
@export_group("Initial Dialogue")
@export_multiline var initial_dialogue: Array[String] = ["Hello.", "How are you?"]
@export var initial_portraits: Array[int] = [0, 0]  # Which portrait for each line
@export var initial_speakers: Array[bool] = [false, false]  # false = NPC, true = Player

@export_group("Exhausted Dialogue")
@export_multiline var exhausted_dialogue: Array[String] = []
@export var exhausted_portraits: Array[int] = []
@export var exhausted_speakers: Array[bool] = []

@export_group("Flag-Based Dialogue")
@export var flag_dialogues: Array[FlagDialogue] = []

@export_group("NPC Portraits")
@export var npc_portraits: Array[Texture2D] = []  # 0 = neutral, 1 = happy, etc.

@export_group("Player Portraits")
@export var player_portraits: Array[Texture2D] = []  # 0 = neutral, 1 = sad, etc.

@onready var interact_prompt: InteractPrompt = $InteractPrompt
@onready var dialog_ui: CanvasLayer = $DialogUI
@onready var label: Label = $DialogUI/Label
@onready var portrait_sprite: Sprite2D = $DialogUI/Portrait

var player_in_range = false
var is_showing = false
var current_dialogue_set: Array[String] = []
var current_portrait_set: Array[int] = []
var current_speaker_set: Array[bool] = []
var current_line = 0
var dialogue_exhausted = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	dialog_ui.visible = false
	
	interact_prompt.body_entered.connect(_on_player_entered)
	interact_prompt.body_exited.connect(_on_player_exited)
	
	# Start with initial dialogue
	current_dialogue_set = initial_dialogue.duplicate()
	current_portrait_set = initial_portraits.duplicate()
	current_speaker_set = initial_speakers.duplicate()

func _on_player_entered():
	player_in_range = true
	
func _on_player_exited():
	player_in_range = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact") and player_in_range:
		if not is_showing:
			# Check for flag-based dialogue first
			update_dialogue_based_on_flags()
			
			dialog_ui.visible = true
			get_tree().paused = true
			current_line = 0
			
			if current_dialogue_set.size() > 0:
				label.display_text(current_dialogue_set[current_line])
				update_portrait(current_line)
			
			is_showing = true
		else:
			advance_dialogue()

func update_dialogue_based_on_flags():
	# Check flag-based dialogues in order
	for flag_dialogue in flag_dialogues:
		if check_flag(flag_dialogue.flag_name):
			current_dialogue_set = flag_dialogue.dialogue_lines.duplicate()
			current_portrait_set = flag_dialogue.portrait_indices.duplicate()
			current_speaker_set = flag_dialogue.is_player_speaking.duplicate()
			dialogue_exhausted = false
			return
	
	# If no flags match, use initial or exhausted
	if dialogue_exhausted:
		if exhausted_dialogue.size() > 0:
			current_dialogue_set = exhausted_dialogue.duplicate()
			current_portrait_set = exhausted_portraits.duplicate()
			current_speaker_set = exhausted_speakers.duplicate()
		else:
			# Repeat last line of initial dialogue
			if initial_dialogue.size() > 0:
				current_dialogue_set = [initial_dialogue[initial_dialogue.size() - 1]]
				if initial_portraits.size() > 0:
					current_portrait_set = [initial_portraits[initial_portraits.size() - 1]]
				if initial_speakers.size() > 0:
					current_speaker_set = [initial_speakers[initial_speakers.size() - 1]]
	else:
		current_dialogue_set = initial_dialogue.duplicate()
		current_portrait_set = initial_portraits.duplicate()
		current_speaker_set = initial_speakers.duplicate()

func check_flag(flag_name: String) -> bool:
	# Check persistent flags
	if has_node("/root/PersistentData"):
		return PersistentData.get_flag(flag_name)
	
	# Check scene variables
	if flag_name in get_tree().current_scene:
		return get_tree().current_scene.get(flag_name)
	
	return false

func advance_dialogue():
	if current_line + 1 < current_dialogue_set.size():
		current_line += 1
		label.display_text(current_dialogue_set[current_line])
		update_portrait(current_line)
	else:
		# Dialogue finished
		dialog_ui.visible = false
		get_tree().paused = false
		current_line = 0
		is_showing = false
		
		# Mark as exhausted if this was initial dialogue
		if current_dialogue_set == initial_dialogue:
			dialogue_exhausted = true

func update_portrait(line_index: int):
	# Determine if player or NPC is speaking
	var is_player = false
	if current_speaker_set.size() > line_index:
		is_player = current_speaker_set[line_index]
	
	# Get correct portrait
	if current_portrait_set.size() > line_index:
		var portrait_index = current_portrait_set[line_index]
		var portrait_array = player_portraits if is_player else npc_portraits
		
		if portrait_array.size() > portrait_index:
			portrait_sprite.texture = portrait_array[portrait_index]
			portrait_sprite.visible = true
		else:
			portrait_sprite.visible = false
	else:
		portrait_sprite.visible = false
