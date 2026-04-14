# res://Resources/VoiceProfile/voice_profile.gd
class_name VoiceProfile
extends Resource

## The blip sound for this character
@export var blip_sound: AudioStream

## 1.0 = normal. Higher = squeaky (child/creature), lower = deep (giant/old)
@export_range(0.5, 3.0) var base_pitch: float = 1.0

## How much the pitch randomly wobbles each blip. 0.1 feels natural.
@export_range(0.0, 0.5) var pitch_variance: float = 0.1

## Base volume in dB (0 = full, -6 = quieter)
@export_range(-20.0, 6.0) var base_volume_db: float = 0.0

## Random ± volume nudge per blip, adds texture
@export_range(0.0, 6.0) var volume_variance_db: float = 1.5

## Only fire a blip every N characters — higher = slower/deeper feel
@export_range(1, 6) var blip_every_n_chars: int = 1

## Time between each character appearing. Lower = faster.
@export_range(0.01, 0.2) var char_speed: float = 0.05
