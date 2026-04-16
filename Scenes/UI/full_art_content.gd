class_name FullArtContent extends Node

@export var texture: Texture2D                        # static art
@export var animated_frames: SpriteFrames = null      # set this for animated art
@export var animation_name: StringName = &"default"   # which animation to play
@export var loop: bool = true                         # loop or play once then hold

@export_multiline var lines: Array[String] = []
@export var portraits: Array[Texture2D] = []
@export var voice_profiles: Array[VoiceProfile] = []

# Convenience read-only: true when this content is animated
func is_animated() -> bool:
	return animated_frames != null
