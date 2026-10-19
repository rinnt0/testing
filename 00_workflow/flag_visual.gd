extends Sprite2D
class_name FlagVisual

@export var flag_name: String = ""
@export var flag_value: bool = true

@export_group("Texture")
@export var change_texture: bool = false
@export var texture_when_set: Texture2D
@export var texture_when_unset: Texture2D

@export_group("Position")
@export var change_position: bool = false
@export var position_when_set: Vector2
@export var position_when_unset: Vector2

@export_group("Visibility")
@export var change_visibility: bool = false
@export var visible_when_set: bool = true
@export var visible_when_unset: bool = true

@export_group("Modulate")
@export var change_modulate: bool = false
@export var modulate_when_set: Color = Color.WHITE
@export var modulate_when_unset: Color = Color.WHITE

@export_group("Animation")
@export var animation_player_path: NodePath
@export var animation_when_set: StringName = &""
@export var animation_when_unset: StringName = &""

var _animation_player: AnimationPlayer
var _has_applied_state: bool = false
var _last_flag_state: bool = false


func _ready() -> void:
	if not animation_player_path.is_empty():
		_animation_player = get_node_or_null(animation_player_path) as AnimationPlayer
	PersistentData.flag_changed.connect(_on_flag_changed)
	PersistentData.flags_reloaded.connect(_on_flags_reloaded)
	_apply_flag_state(true)


func _on_flag_changed(changed_flag: String, _value: bool) -> void:
	if changed_flag == flag_name:
		_apply_flag_state()


func _on_flags_reloaded() -> void:
	_apply_flag_state()


func _apply_flag_state(force_animation: bool = false) -> void:
	if flag_name.is_empty():
		return

	var is_set := PersistentData.get_flag(flag_name) == flag_value
	var state_changed := not _has_applied_state or is_set != _last_flag_state
	if change_texture:
		texture = texture_when_set if is_set else texture_when_unset
	if change_position:
		position = position_when_set if is_set else position_when_unset
	if change_visibility:
		visible = visible_when_set if is_set else visible_when_unset
	if change_modulate:
		modulate = modulate_when_set if is_set else modulate_when_unset

	if _animation_player and (force_animation or state_changed):
		var animation_name := animation_when_set if is_set else animation_when_unset
		if not animation_name.is_empty() and _animation_player.has_animation(animation_name):
			_animation_player.play(animation_name)

	_last_flag_state = is_set
	_has_applied_state = true