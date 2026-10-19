extends CanvasLayer

signal option_confirmed(action: String)
signal option_index_confirmed(index: int)
signal menu_hidden

@onready var vbox: VBoxContainer = $Control/VBoxContainer
@onready var container_mask: Control = $Control # The parent with "Clip Content" on
var bar_target_x: float
var decor_target_x: float
var options: Array = []
var current_index: int = 0
var slot_nodes: Array = []
var is_closing: bool = false 
var decor_base_x: float = 0.0 # Caches the decoration's intended position

const SLOT_SCENE = preload("res://Scenes/UI/ChoiceSystem/ChoiceSlotSelected.tscn")
const SCROLL_SPEED = 0.2 

func _ready():
	visible = false
	$Control/SelectionBar.top_level = true
	$Control/Decorations.top_level = true
	
	# Cache the original X position of the decorations to ensure reliable sliding targets
	decor_base_x = $Control/Decorations.global_position.x
	bar_target_x = $Control/SelectionBar.global_position.x
	decor_target_x = $Control/Decorations.global_position.x
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_options(new_options: Array):
	options = new_options
	current_index = 0
	is_closing = false
	$Control.modulate.a = 1.0 # Ensure it's visible for the next use
	visible = true
	AudioManager.play_ui_open()
	
	setup_slots()
	update_selection(false)
	play_intro_animation()
	
	PlayerManager.lock_player()
	
	setup_slots()
	update_selection(false) # Snap to start without animation

func setup_slots():
	# Clear old nodes
	for child in vbox.get_children():
		child.queue_free()
	slot_nodes.clear()
	
	# Instantiate all options at once
	for i in range(options.size()):
		var slot = SLOT_SCENE.instantiate()
		vbox.add_child(slot)
		slot.setup(options[i].label, options[i].icon)
		slot_nodes.append(slot)

func update_selection(animate: bool = true):
	# CRITICAL: Wait one frame so the VBox updates its internal size/positions
	if not is_node_ready(): await ready 
	await get_tree().process_frame 

	if slot_nodes.is_empty(): return

	# 1. Get exact dimensions
	var separation = vbox.get_theme_constant("separation")
	var slot_height = slot_nodes[0].size.y # Use .size.y instead of custom_min
	var full_slot_step = slot_height + separation
	
	# 2. Calculate the "Center" of your visible window
	# We want the middle of the 'container_mask' to align with the middle of the slot
	var mask_center = container_mask.size.y / 2.0
	var slot_center_offset = slot_height / 2.0
	
	# The target position for the VBox
	var target_y = mask_center - slot_center_offset - (current_index * full_slot_step)

	# 3. Animate
	var tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	if animate:
		tween.tween_property(vbox, "position:y", target_y, SCROLL_SPEED)
	else:
		vbox.position.y = target_y

	# 4. Highlight Logic
	for i in range(slot_nodes.size()):
		var is_selected = (i == current_index)
		# Optional: Dim the ones that aren't selected for a "focus" effect
		var target_alpha = 1.0 if is_selected else 0.3
		var target_scale = Vector2(1.05, 1.05) if is_selected else Vector2(1.0, 1.0)
		
		var s_tween = create_tween().set_parallel(true)
		s_tween.tween_property(slot_nodes[i], "modulate:a", target_alpha, 0.1)
		s_tween.tween_property(slot_nodes[i], "scale", target_scale, 0.1)

func _input(event: InputEvent):
	if not visible or options.size() == 0 or is_closing:
		return
		
	if event.is_action_pressed("ui_up"):
		get_viewport().set_input_as_handled()
		current_index = (current_index - 1 + options.size()) % options.size()
		update_selection()
		AudioManager.play_sfx(AudioManager.ui_click_sound)
		
	elif event.is_action_pressed("ui_down"):
		get_viewport().set_input_as_handled()
		current_index = (current_index + 1) % options.size()
		update_selection()
		AudioManager.play_sfx(AudioManager.ui_click_sound)
		
	elif event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		var selected_label: String = options[current_index].label
		var selected_index: int = current_index
		hide_menu()
		option_confirmed.emit(selected_label)
		option_index_confirmed.emit(selected_index)

func hide_menu():
	if is_closing: return
	is_closing = true
	AudioManager.play_ui_close()
	
	var bar = $Control/SelectionBar
	var decor = $Control/Decorations
	
	var exit_tween = create_tween().set_parallel(true)
	
	exit_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	# Main fade
	exit_tween.tween_property($Control, "modulate:a", 0.0, 0.25)
	
	# 🔹 SelectionBar → RIGHT (fast)
	exit_tween.tween_property(bar, "global_position:x", bar_target_x + 150, 0.25)
	exit_tween.tween_property(bar, "modulate:a", 0.0, 0.12)
	
	# 🔹 Decorations → LEFT (slower + slight delay feel via duration)
	exit_tween.tween_property(decor, "global_position:x", decor_target_x - 150, 0.45)
	exit_tween.tween_property(decor, "modulate:a", 0.0, 0.18)
	
	exit_tween.finished.connect(func():
		visible = false
		is_closing = false
		options = []
		
		# Reset everything cleanly
		bar.global_position.x = bar_target_x
		decor.global_position.x = decor_target_x
		bar.modulate.a = 1.0
		decor.modulate.a = 1.0
		
		PlayerManager.unlock_player()
		menu_hidden.emit()
	)

func play_intro_animation():
	var main_control = $Control
	var bar = $Control/SelectionBar
	var decor = $Control/Decorations
	
	# Reset positions every time
	bar.global_position.x = bar_target_x + 150
	decor.global_position.x = decor_target_x - 150
	
	# Reset alpha
	main_control.modulate.a = 0.0
	bar.modulate.a = 0.0
	decor.modulate.a = 0.0
	
	var intro = create_tween().set_parallel(true)
	
	# Main fade
	intro.tween_property(main_control, "modulate:a", 1.0, 0.4)
	
	intro.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# 🔹 SelectionBar (fast + immediate)
	intro.tween_property(bar, "global_position:x", bar_target_x, 0.3)
	intro.tween_property(bar, "modulate:a", 1.0, 0.15)
	
	# 🔹 Decorations (slower + slight delay)
	intro.tween_property(decor, "global_position:x", decor_target_x, 0.55).set_delay(0.05)
	intro.tween_property(decor, "modulate:a", 1.0, 0.2).set_delay(0.05)

func animate_bg_elements():
	var delay = 0.0
	# Loop through all children in your decoration container
	for sprite in $Control/Decorations.get_children():
		if sprite is Sprite2D:
			sprite.modulate.a = 0
			sprite.scale = Vector2.ZERO
			
			var tw = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			# Start each sprite slightly after the previous one
			tw.set_parallel(true)
			tw.tween_property(sprite, "modulate:a", 1.0, 0.5).set_delay(delay)
			tw.tween_property(sprite, "scale", Vector2(1, 1), 0.6).set_delay(delay)
			
			delay += 0.1 # Increase delay for the next sprite
