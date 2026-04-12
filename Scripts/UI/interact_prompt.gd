class_name InteractPrompt extends Area2D

var player : Player

@onready var star: Sprite2D = $interact_prompt_star
@onready var circle: Sprite2D = $interact_prompt_circle
@onready var button: Sprite2D = $interact_prompt_button

@onready var star_animation_player: AnimationPlayer = $interact_prompt_star/StarAnimationPlayer

func _on_body_entered(body: Player) -> void:
		print("lool")
		star_animation_player.play("active")
		circle.visible = true
		button.visible = true
		emit_signal("body_entered")
		pass# Replace with function body.



func _on_body_exited(body: Player) -> void:
		
		star_animation_player.play("idle")
		circle.visible = false
		button.visible = false
		emit_signal("body_exited")
		pass # Replace with function body.
