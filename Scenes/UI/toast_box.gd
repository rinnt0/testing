extends CanvasLayer

signal toast_finished

const HOLD_SECONDS := 2.2
const REST_LEFT := 40.0
const REST_RIGHT := 560.0
const REST_TOP := -220.0
const REST_BOTTOM := -40.0

@onready var panel: Control = $Panel
@onready var header_label: RichTextLabel = $Panel/Margin/VBox/Header
@onready var icon_rect: TextureRect = $Panel/Margin/VBox/Body/Icon
@onready var item_label: RichTextLabel = $Panel/Margin/VBox/Body/NameColumn/ItemName

var _gen: int = 0
var _tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	panel.modulate.a = 0.0

func show_toast(content: ToastContent) -> void:
	_gen += 1
	var gen := _gen
	if _tween:
		_tween.kill()

	header_label.text = content.header_text
	item_label.text = content.item_name
	icon_rect.texture = content.icon

	visible = true
	panel.modulate.a = 0.0
	var height := REST_BOTTOM - REST_TOP
	panel.offset_left = REST_LEFT
	panel.offset_right = REST_RIGHT
	panel.offset_top = REST_TOP + height
	panel.offset_bottom = REST_BOTTOM + height

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	_tween.tween_property(panel, "offset_top", REST_TOP, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(panel, "offset_bottom", REST_BOTTOM, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await _tween.finished
	if gen != _gen:
		return

	await get_tree().create_timer(HOLD_SECONDS).timeout
	if gen != _gen:
		return

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(panel, "modulate:a", 0.0, 0.22)
	_tween.tween_property(panel, "offset_top", REST_TOP + height, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(panel, "offset_bottom", REST_BOTTOM + height, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await _tween.finished
	if gen != _gen:
		return

	visible = false
	toast_finished.emit()
