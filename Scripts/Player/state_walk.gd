class_name StateWalk extends State

@export var move_speed: float = 40.0
@export var footstep_interval: float = 0.35

var _footstep_timer: float = 0.0

@onready var idle: State = $"../Idle"

func enter_state() -> void:
	player.update_animation("walk")
	_footstep_timer = footstep_interval  # play first step immediately on enter

func exit_state() -> void:
	_footstep_timer = footstep_interval  # reset so next entry starts fresh

func process(delta: float) -> State:
	if player.direction == Vector2.ZERO:
		return idle

	player.velocity = player.direction * move_speed

	if player.set_direction():
		player.update_animation("walk")

	_tick_footsteps(delta)
	return null

func _tick_footsteps(delta: float) -> void:
	_footstep_timer -= delta
	if _footstep_timer <= 0.0:
		_footstep_timer = footstep_interval
		_play_footstep()

func _play_footstep() -> void:
	if player.footstep_sounds.is_empty():
		return
	var sound: AudioStream = player.footstep_sounds[randi() % player.footstep_sounds.size()]
	AudioManager.play_sfx(sound)

func physics(_delta: float) -> State:
	return null

func handle_input(_event: InputEvent) -> State:
	return null
