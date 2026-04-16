class_name DialogContent extends Node
@export_multiline var lines: Array[String] = []
@export var portraits: Array[Texture2D] = []
@export var voice_profiles: Array[VoiceProfile] = []
@export var camera_targets: Array[String] = []  # ← one per line, empty = no move
@export var camera_zoom: Array[float] = []    # default zoom is 6, lower to zoom out, higher to zoom in.
@export var player_targets: Array[String] = []  # ← one per line, empty = stay in place
 
