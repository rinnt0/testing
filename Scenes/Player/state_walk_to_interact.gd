class_name StateWalkToInteract extends State

@export var move_speed: float = 40.0
@export var arrive_distance: float = 8.0  # how close before interacting

@onready var idle: State = $"../Idle"

var _target: InteractPrompt = null

func set_target(prompt: InteractPrompt) -> void:
	_target = prompt

func enter_state() -> void:
	player.update_animation("walk")

func exit_state() -> void:
	_target = null

# StateWalkToInteract — arrival auto-fires, no second press needed
func process(_delta: float) -> State:
	if _target == null or not is_instance_valid(_target):
		return idle
	var dist_x: float = absf(player.global_position.x - _target.global_position.x)
	if dist_x <= arrive_distance:
		_target.interact(player)  # fires signal directly — no E required
		return idle
	var dir_x := signf(_target.global_position.x - player.global_position.x)
	player.direction.x = dir_x
	player.velocity = Vector2(dir_x, 0) * move_speed
	if player.set_direction():
		player.update_animation("walk")
	return null

func physics(_delta: float) -> State:
	return null

func handle_input(event: InputEvent) -> State:
	# Let player cancel by moving manually
	if event.is_action_pressed("left") or event.is_action_pressed("right"):
		return idle
	return null
