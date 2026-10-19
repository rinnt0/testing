extends Control

@export var music : AudioStream
@export var ambient : AudioStream

@onready var transition_content: TransitionContent = $TransitionContent

const UI_FONT := preload("res://Assets/UI/LowresPixel-Regular.otf")
const DIALOG_TEXTURE := preload("res://Assets/UI/textbox.png")
var load_menu_overlay: ColorRect
var load_menu_slots: VBoxContainer
var load_menu_status: Label

func _ready() -> void:
	AudioManager.play_music( music )
	AudioManager.play_ambient( ambient )
	if PlayerManager.player:
		PlayerManager.player.visible = false
		var camera = PlayerManager.player.get_node_or_null("Camera2D")
		if camera:
			camera.enabled = false
	_build_load_menu()


func _build_load_menu() -> void:
	load_menu_overlay = ColorRect.new()
	load_menu_overlay.name = "LoadMenuOverlay"
	load_menu_overlay.color = Color(0.0, 0.0, 0.0, 0.78)
	load_menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	load_menu_overlay.z_index = 500
	load_menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(load_menu_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	load_menu_overlay.add_child(center)

	var panel := NinePatchRect.new()
	panel.texture = DIALOG_TEXTURE
	panel.region_rect = Rect2(7, 6, 34, 35)
	panel.patch_margin_left = 12
	panel.patch_margin_top = 12
	panel.patch_margin_right = 12
	panel.patch_margin_bottom = 12
	panel.self_modulate = Color(1, 1, 1, 0.78)
	panel.custom_minimum_size = Vector2(1120, 760)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 68)
	margin.add_theme_constant_override("margin_right", 68)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_bottom", 48)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	margin.add_child(content)

	var heading := Label.new()
	heading.text = "SELECT A RECORD"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", UI_FONT)
	heading.add_theme_font_size_override("font_size", 54)
	heading.add_theme_color_override("font_color", Color("#f0e8d9"))
	content.add_child(heading)

	var divider := HSeparator.new()
	content.add_child(divider)

	load_menu_slots = VBoxContainer.new()
	load_menu_slots.add_theme_constant_override("separation", 12)
	content.add_child(load_menu_slots)

	load_menu_status = Label.new()
	load_menu_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	load_menu_status.add_theme_font_override("font", UI_FONT)
	load_menu_status.add_theme_font_size_override("font_size", 26)
	load_menu_status.add_theme_color_override("font_color", Color("#e0aa55"))
	content.add_child(load_menu_status)

	_populate_load_menu()
	load_menu_overlay.visible = false


func _populate_load_menu() -> void:
	for child in load_menu_slots.get_children():
		load_menu_slots.remove_child(child)
		child.queue_free()
	for slot in range(0, PersistentData.MAX_SLOT + 1):
		_add_load_button(
			PersistentData.get_save_display_name(slot),
			_on_load_slot_pressed.bind(slot),
			PersistentData.has_save(slot)
		)
	_add_load_button("BACK", _hide_load_menu)


func _add_load_button(text: String, action: Callable, enabled: bool = true) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(900, 76)
	button.disabled = not enabled
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", UI_FONT)
	button.add_theme_font_size_override("font_size", 34)
	button.add_theme_color_override("font_color", Color("#f0e8d9"))
	button.add_theme_color_override("font_hover_color", Color("#f0e8d9"))
	button.add_theme_color_override("font_disabled_color", Color("#99958c"))
	button.add_theme_stylebox_override("normal", _dialog_button_style(Color(1, 1, 1, 0.78)))
	button.add_theme_stylebox_override("hover", _dialog_button_style(Color(1, 0.78, 0.48, 0.9)))
	button.add_theme_stylebox_override("pressed", _dialog_button_style(Color(0.9, 0.48, 0.32, 0.92)))
	button.add_theme_stylebox_override("disabled", _dialog_button_style(Color(0.55, 0.55, 0.55, 0.48)))
	button.pressed.connect(action)
	load_menu_slots.add_child(button)


func _dialog_button_style(tint: Color) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = DIALOG_TEXTURE
	style.region_rect = Rect2(7, 6, 34, 35)
	style.texture_margin_left = 12
	style.texture_margin_top = 12
	style.texture_margin_right = 12
	style.texture_margin_bottom = 12
	style.modulate_color = tint
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _on_new_game_pressed() -> void:
	PersistentData.reset_to_defaults()
	if transition_content:
		TransitionBox.do_transition(transition_content)


func _on_load_game_pressed() -> void:
	load_menu_status.text = ""
	_populate_load_menu()
	load_menu_overlay.visible = true
	AudioManager.play_ui_open()
	for child in load_menu_slots.get_children():
		var button := child as Button
		if button and not button.disabled:
			button.grab_focus()
			return


func _hide_load_menu() -> void:
	if load_menu_overlay.visible:
		AudioManager.play_ui_close()
	load_menu_overlay.visible = false


func _on_load_slot_pressed(slot: int) -> void:
	var save_dict := PersistentData.get_save(slot)
	if save_dict.is_empty():
		load_menu_status.text = "NO VALID RECORD IN THAT SLOT"
		return
	var scene_path: String = save_dict.get("scene_path", "")
	if not ResourceLoader.exists(scene_path):
		load_menu_status.text = "THE SAVED SCENE IS MISSING"
		return
	var saved_position: Array = save_dict["player_position"]
	PersistentData.load_game(save_dict)
	_hide_load_menu()
	await TransitionBox.do_scene_fade(
		scene_path,
		"",
		true,
		Vector2(float(saved_position[0]), float(saved_position[1]))
	)


func _on_quit_pressed() -> void:
	get_tree().quit()
