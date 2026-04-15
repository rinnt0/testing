extends Control

# You can remove start_scene since TransitionContent handles the next scene path!
@export var music : AudioStream

# Grab a reference to the new node
@onready var transition_content: TransitionContent = $TransitionContent 

func _ready() -> void:
	AudioManager.play_music( music )
	if PlayerManager.player:
		PlayerManager.player.visible = false
		var camera = PlayerManager.player.get_node_or_null("Camera2D")
		if camera:
			camera.enabled = false

func _on_start_pressed():
	# Instead of fading and loading manually, let TransitionBox handle it
	if transition_content:
		TransitionBox.do_transition(transition_content)

# You can completely delete the old fade_out() function, 
# as TransitionBox.do_transition() already fades a ColorRect in!

func _on_quit_pressed():
	get_tree().quit()
