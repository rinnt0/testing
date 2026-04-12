extends AnimationPlayer
@onready var plant: InteractPrompt = $".."
var player_in_range = false
@onready var animation_player: AnimationPlayer = $"."
@onready var texture_rect: TextureRect = $TextureRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	plant.body_entered.connect(_on_player_entered)
	plant.body_exited.connect(_on_player_exited)

func _on_player_entered():
	player_in_range = true
	
func _on_player_exited():
	player_in_range = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact") and player_in_range:
		texture_rect.visible = true

		
		pass
