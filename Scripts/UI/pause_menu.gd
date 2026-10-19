extends Control

@onready var canvas_layer: CanvasLayer = $CanvasLayer

const TITLE_SCENE := "res://Scenes/UI/title_screen.tscn"
const UI_FONT := preload("res://Assets/UI/LowresPixel-Regular.otf")
const DIALOG_TEXTURE := preload("res://Assets/UI/textbox.png")
var menu_view_container: VBoxContainer
var menu_footer_container: VBoxContainer
var status_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false
	canvas_layer.visible = false


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if visible:
			_close_pause()
		elif get_tree().current_scene and get_tree().current_scene.is_in_group("level"):
			_open_pause()


func _build_ui() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.015, 0.023, 0.031, 0.62)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(980, 850)
	var panel_style := StyleBoxTexture.new()
	panel_style.texture = DIALOG_TEXTURE
	panel_style.region_rect = Rect2(7, 6, 34, 35)
	panel_style.texture_margin_left = 12
	panel_style.texture_margin_top = 12
	panel_style.texture_margin_right = 12
	panel_style.texture_margin_bottom = 12
	panel_style.modulate_color = Color(1, 1, 1, 0.82)
	panel_style.content_margin_left = 58
	panel_style.content_margin_right = 58
	panel_style.content_margin_top = 42
	panel_style.content_margin_bottom = 42
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	panel.add_child(content)

	var eyebrow := Label.new()
	eyebrow.text = "FIELD RECORD  /  PAUSED"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_override("font", UI_FONT)
	eyebrow.add_theme_color_override("font_color", Color("#e0aa55"))
	eyebrow.add_theme_font_size_override("font_size", 26)
	content.add_child(eyebrow)

	var title := Label.new()
	title.text = "THE STORY SO FAR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UI_FONT)
	title.add_theme_color_override("font_color", Color("#f0e8d9"))
	title.add_theme_font_size_override("font_size", 48)
	content.add_child(title)

	var divider := HSeparator.new()
	content.add_child(divider)

	var view_container := VBoxContainer.new()
	view_container.name = "ViewContainer"
	view_container.add_theme_constant_override("separation", 14)
	content.add_child(view_container)
	menu_view_container = view_container

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)

	menu_footer_container = VBoxContainer.new()
	menu_footer_container.add_theme_constant_override("separation", 10)
	content.add_child(menu_footer_container)

	var status := Label.new()
	status.name = "Status"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_override("font", UI_FONT)
	status.add_theme_color_override("font_color", Color("#e0aa55"))
	status.add_theme_font_size_override("font_size", 22)
	menu_footer_container.add_child(status)
	status_label = status

	_add_action_button("RETURN TO MAIN MENU", _return_to_title, true, menu_footer_container)
	_show_main_screen()


func _open_pause() -> void:
	visible = true
	canvas_layer.visible = true
	get_tree().paused = true
	AudioManager.play_ui_open()
	_show_main_screen()


func _close_pause() -> void:
	var was_open := canvas_layer.visible
	visible = false
	canvas_layer.visible = false
	get_tree().paused = false
	if was_open:
		AudioManager.play_ui_close()


func _show_main_screen() -> void:
	_clear_screen()
	_add_action_button("RESUME", _close_pause)
	_add_action_button("SAVE GAME", _show_save_screen)
	_add_action_button("LOAD GAME", _show_load_screen)
	_focus_first_button()


func _show_save_screen() -> void:
	_clear_screen()
	for slot in range(1, PersistentData.MAX_SLOT + 1):
		_add_action_button(
			"SAVE TO  %02d     //     %s" % [slot, PersistentData.get_save_display_name(slot).split("//", true, 1)[1].strip_edges()],
			_on_save_slot_pressed.bind(slot)
		)
	_add_action_button("BACK", _show_main_screen)
	_focus_first_button()


func _show_load_screen() -> void:
	_clear_screen()
	_add_action_button(
		PersistentData.get_save_display_name(0),
		_on_load_slot_pressed.bind(0),
		PersistentData.has_save(0)
	)
	for slot in range(1, PersistentData.MAX_SLOT + 1):
		_add_action_button(
			PersistentData.get_save_display_name(slot),
			_on_load_slot_pressed.bind(slot),
			PersistentData.has_save(slot)
		)
	_add_action_button("BACK", _show_main_screen)
	_focus_first_button()


func _clear_screen() -> void:
	for child in menu_view_container.get_children():
		menu_view_container.remove_child(child)
		child.queue_free()


func _add_action_button(
	text: String,
	action: Callable,
	enabled: bool = true,
	parent: VBoxContainer = null
) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(760, 72)
	button.disabled = not enabled
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", UI_FONT)
	button.add_theme_font_size_override("font_size", 30)
	button.add_theme_color_override("font_color", Color("#f0e8d9"))
	button.add_theme_color_override("font_hover_color", Color("#fff4df"))
	button.add_theme_color_override("font_pressed_color", Color("#fff4df"))
	button.add_theme_color_override("font_disabled_color", Color("#72808a"))
	button.add_theme_stylebox_override("normal", _button_style(Color(1, 1, 1, 0.76)))
	button.add_theme_stylebox_override("hover", _button_style(Color(1, 0.78, 0.48, 0.9)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.9, 0.48, 0.32, 0.92)))
	button.add_theme_stylebox_override("focus", _button_style(Color(1, 0.9, 0.7, 0.9)))
	button.add_theme_stylebox_override("disabled", _button_style(Color(0.55, 0.55, 0.55, 0.48)))
	button.pressed.connect(action)
	var button_parent := parent if parent else menu_view_container
	button_parent.add_child(button)
	return button


func _button_style(tint: Color) -> StyleBoxTexture:
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


func _focus_first_button() -> void:
	for child in menu_view_container.get_children():
		var button := child as Button
		if button and not button.disabled:
			button.grab_focus()
			return


func _on_save_slot_pressed(slot: int) -> void:
	if PersistentData.save_game(slot):
		_set_status("SAVED TO SLOT %02d" % slot)
		_show_save_screen()
		_set_status("SAVED TO SLOT %02d" % slot)
	else:
		_set_status("SAVE FAILED  //  PREVIOUS SAVE KEPT")


func _on_load_slot_pressed(slot: int) -> void:
	var save_dict := PersistentData.get_save(slot)
	if save_dict.is_empty():
		_set_status("NO VALID SAVE IN THAT SLOT")
		return
	var scene_path: String = save_dict.get("scene_path", "")
	if not ResourceLoader.exists(scene_path):
		_set_status("THE SAVED SCENE IS MISSING")
		return
	var saved_position: Array = save_dict["player_position"]
	PersistentData.load_game(save_dict)
	_close_pause()
	await TransitionBox.do_scene_fade(
		scene_path,
		"",
		true,
		Vector2(float(saved_position[0]), float(saved_position[1]))
	)


func _return_to_title() -> void:
	_close_pause()
	if get_tree().current_scene and get_tree().current_scene.is_in_group("level"):
		PlayerManager.unparent_player(get_tree().current_scene)
	await TransitionBox.do_scene_fade(TITLE_SCENE)


func _set_status(message: String) -> void:
	status_label.text = message
