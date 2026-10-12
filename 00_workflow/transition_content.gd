class_name TransitionContent extends Node

enum FacingDirection { UNCHANGED, LEFT, RIGHT }

@export_multiline var transition_texts: Array[String] = []
@export var transition_target: String = ""
@export_file("*.tscn") var next_scene_path: String = ""
@export var voice_profiles: Array[VoiceProfile] = []
@export var facing_direction: FacingDirection = FacingDirection.UNCHANGED
