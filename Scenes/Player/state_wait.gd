class_name StateWait extends State

const WAIT_ANIMATION = "idle"

@onready var idle: StateIdle = $"../Idle"  # match the exact node name in your scene tree

func enter_state() -> void:
	player.update_animation(WAIT_ANIMATION)
	player.can_look_up = false

func exit_state() -> void:
	player.can_look_up = true

func process(_delta: float) -> State:
	player.velocity = Vector2.ZERO
	return null

func physics(_delta: float) -> State:
	return null

func handle_input(event: InputEvent) -> State:
	if event.is_action_pressed("ui_cancel"):
		return idle
	return null
