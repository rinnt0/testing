extends AnimationPlayer
var player_in_range = false
@onready var animation_player: AnimationPlayer = $"."
@onready var texture_rect: TextureRect = $TextureRect
@onready var level_transition_x: LevelTransition = $".."


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	level_transition_x.body_entered.connect(player_entered)
	level_transition_x.body_exited.connect(player_exited)

func player_entered():
	player_in_range = true
	
func player_exited():
	player_in_range = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player_in_range:
		texture_rect.visible = true

		
		pass
