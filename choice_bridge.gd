extends Node2D

@onready var interact_prompt: InteractPrompt = $InteractPrompt
var player_in_range = false
var is_open = false

func _ready():
	for maker in get_children().filter(func(c): return c is ChoiceMaker):
		var flag = maker.get_node_or_null("DialogFlag")
		if flag and flag.set_flag_on_complete and flag.flag_name != "":
			if PersistentData.get_flag(flag.flag_name):
				queue_free()
				return
	interact_prompt.body_entered.connect(_on_entered)
	interact_prompt.body_exited.connect(_on_exited)

func _on_entered():
	player_in_range = true

func _on_exited():
	player_in_range = false

# Removed _process. Using _unhandled_input instead!
func _unhandled_input(event: InputEvent):
	if player_in_range and not is_open and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled() 
		
		is_open = true
		
		# 1. Figure out which labels have an active, met flag condition
		var active_flagged_labels = {}
		for c in get_children():
			if c is ChoiceMaker and c.requires_flag:
				if PersistentData.get_flag(c.flag_name) == c.flag_value:
					active_flagged_labels[c.label] = true

		# 2. Build the choices array
		var choices = []
		for c in get_children():
			if not c is ChoiceMaker:
				continue
				
			if c.requires_flag:
				# Add flagged choices ONLY if their condition is met
				if PersistentData.get_flag(c.flag_name) == c.flag_value:
					choices.append(c)
			else:
				# Add default/non-flagged choices ONLY if a flagged version isn't overriding it
				if not active_flagged_labels.has(c.label):
					choices.append(c)
		
		ChoiceMenu.show_options(choices)
		var choice = await ChoiceMenu.option_confirmed
		is_open = false

		var chosen_maker = choices.filter(func(c): return c.label == choice)
		if chosen_maker.size() > 0:
			var dialog = chosen_maker[0].get_node_or_null("DialogContent")
			var full_art = chosen_maker[0].get_node_or_null("FullArtContent")
			var flag = chosen_maker[0].get_node_or_null("DialogFlag")
			
			if full_art:
				await FullArtBox.show_art(full_art)
			elif dialog:
				DialogBox.show_lines(dialog.lines, dialog.portraits)
				await DialogBox.dialog_finished
			else:
				PlayerManager.player.state_machine.process_mode = Node.PROCESS_MODE_INHERIT
				PlayerManager.player.can_look_up = true
			
			if flag:
				if flag.set_flag_on_complete and flag.flag_name != "":
					PersistentData.set_flag(flag.flag_name, true)
				if flag.delete_after_interaction:
					queue_free()
