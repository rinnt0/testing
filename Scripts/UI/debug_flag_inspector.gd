extends CanvasLayer

const UI_FONT := preload("res://Assets/UI/LowresPixel-Regular.otf")
const DIALOG_TEXTURE := preload("res://Assets/UI/textbox.png")

@export var inspector_enabled: bool = true:
	set(value):
		inspector_enabled = value
		_apply_visibility()

@onready var panel: PanelContainer = $PanelContainer
@onready var flag_list: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/FlagScroll/FlagList
@onready var flag_name_input: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/AddFlagRow/FlagNameInput
@onready var add_flag_button: Button = $PanelContainer/MarginContainer/VBoxContainer/AddFlagRow/AddFlagButton

var _flag_toggles: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.is_debug_build():
		queue_free()
		return
	flag_name_input.add_theme_font_override("font", UI_FONT)
	flag_name_input.add_theme_font_size_override("font_size", 18)
	flag_name_input.add_theme_stylebox_override("normal", _dialog_style(Color(1, 1, 1, 0.7)))
	flag_name_input.add_theme_stylebox_override("focus", _dialog_style(Color(1, 0.82, 0.56, 0.9)))
	add_flag_button.add_theme_font_override("font", UI_FONT)
	add_flag_button.add_theme_font_size_override("font_size", 18)
	add_flag_button.add_theme_color_override("font_color", Color("#f0e8d9"))
	add_flag_button.add_theme_color_override("font_hover_color", Color("#fff4df"))
	add_flag_button.add_theme_stylebox_override("normal", _dialog_style(Color(1, 1, 1, 0.76)))
	add_flag_button.add_theme_stylebox_override("hover", _dialog_style(Color(1, 0.78, 0.48, 0.9)))
	add_flag_button.add_theme_stylebox_override("pressed", _dialog_style(Color(0.9, 0.48, 0.32, 0.92)))
	PersistentData.flag_changed.connect(_on_flag_changed)
	PersistentData.flags_reloaded.connect(_refresh_flags)
	_refresh_flags()
	_apply_visibility()


func _apply_visibility() -> void:
	if is_instance_valid(panel):
		panel.visible = inspector_enabled and OS.is_debug_build()


func _refresh_flags() -> void:
	for child in flag_list.get_children():
		flag_list.remove_child(child)
		child.queue_free()
	_flag_toggles.clear()

	var flag_names: Array = PersistentData.flags.keys()
	flag_names.sort()
	if flag_names.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No flags registered"
		flag_list.add_child(empty_label)
		return

	for flag_name in flag_names:
		_add_flag_row(String(flag_name))


func _add_flag_row(flag_name: String) -> void:
	var row_panel := PanelContainer.new()
	row_panel.add_theme_stylebox_override("panel", _dialog_style(Color(1, 1, 1, 0.2)))
	flag_list.add_child(row_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row_panel.add_child(row)

	var name_label := Label.new()
	name_label.text = flag_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_override("font", UI_FONT)
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color("#f0e8d9"))
	row.add_child(name_label)

	var flag_toggle := CheckButton.new()
	flag_toggle.button_pressed = PersistentData.get_flag(flag_name)
	flag_toggle.text = "TRUE" if flag_toggle.button_pressed else "FALSE"
	flag_toggle.add_theme_font_override("font", UI_FONT)
	flag_toggle.add_theme_font_size_override("font_size", 18)
	flag_toggle.add_theme_color_override("font_color", Color("#e0aa55"))
	flag_toggle.toggled.connect(_on_flag_toggled.bind(flag_name))
	row.add_child(flag_toggle)
	_flag_toggles[flag_name] = flag_toggle


func _on_flag_toggled(value: bool, flag_name: String) -> void:
	(_flag_toggles[flag_name] as CheckButton).text = "TRUE" if value else "FALSE"
	PersistentData.set_flag(flag_name, value)


func _on_flag_changed(flag_name: String, value: bool) -> void:
	if _flag_toggles.has(flag_name):
		var flag_toggle := _flag_toggles[flag_name] as CheckButton
		flag_toggle.set_pressed_no_signal(value)
		flag_toggle.text = "TRUE" if value else "FALSE"
	else:
		_refresh_flags()


func _on_add_flag_pressed() -> void:
	var flag_name := flag_name_input.text.strip_edges()
	if flag_name.is_empty():
		return
	if not PersistentData.flags.has(flag_name):
		PersistentData.set_flag(flag_name, false)
	flag_name_input.clear()
	_refresh_flags()


func _on_flag_name_submitted(_text: String) -> void:
	_on_add_flag_pressed()


func _dialog_style(tint: Color) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = DIALOG_TEXTURE
	style.region_rect = Rect2(7, 6, 34, 35)
	style.texture_margin_left = 12
	style.texture_margin_top = 12
	style.texture_margin_right = 12
	style.texture_margin_bottom = 12
	style.modulate_color = tint
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
