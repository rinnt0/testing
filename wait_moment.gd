extends Node
class_name WaitMoment

@export_group("Thoughts")
@export var thoughts: Array[String] = []
@export var thought_delays: Array[float] = []
@export var portraits: Array[Texture2D] = []
@export var voice_profiles: Array[VoiceProfile] = [] # <--- Make sure this is "voice_profiles"
@export var deep_indices: Array[int] = []

@export_group("Camera")
@export var camera_targets: Array[String] = []
@export var camera_zoom: Array[float] = []
