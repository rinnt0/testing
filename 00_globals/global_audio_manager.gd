extends Node

# ─────────────────────────────────────────────
#  Music
# ─────────────────────────────────────────────
var music_audio_player_count: int = 2
var current_music_player: int = 0
var music_players: Array[AudioStreamPlayer] = []
var music_bus: String = "Music"
var music_fade_Duration: float = 1

# ─────────────────────────────────────────────
#  Voice Blips
# ─────────────────────────────────────────────
var blip_bus: String = "SFX"
var blip_pool_size: int = 4          # lets fast text overlap slightly
var blip_players: Array[AudioStreamPlayer] = []
var blip_pool_index: int = 0


var ambient_bus: String = "Ambient"
var ambient_players: Array[AudioStreamPlayer] = []
var current_ambient_player: int = 0
var ui_click_sound: AudioStream = preload("res://Assets/Music/mixkit-modern-technology-select-3124.wav")


# Characters that should NOT trigger a blip
const SILENT_CHARS := [" ", "\n", ".", ",", "!", "?", "-", "…", "\"", "'", ":"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# In _ready(), add:
	for i in music_audio_player_count:
		var player = AudioStreamPlayer.new()
		add_child(player)
		player.bus = ambient_bus
		player.volume_db = -40
		ambient_players.append(player)

		
	
	# Music players
	for i in music_audio_player_count:
		var player = AudioStreamPlayer.new()
		add_child(player)
		player.bus = music_bus
		player.volume_db = -40
		music_players.append(player)

	# Blip pool
	for i in blip_pool_size:
		var player = AudioStreamPlayer.new()
		add_child(player)
		player.bus = blip_bus
		blip_players.append(player)


# Call this from your typewriter loop once per revealed character.
# Pass in a VoiceProfile to get per-character personality.
func play_voice_blip(sound: AudioStream, profile: VoiceProfile = null) -> void:
	print("play_voice_blip, sound: ", sound, " bus: ", blip_players[blip_pool_index].bus)
	if sound == null:
		return

	# Grab the next player in the pool (round-robin)
	var player: AudioStreamPlayer = blip_players[blip_pool_index]
	blip_pool_index = (blip_pool_index + 1) % blip_pool_size

	player.stream = sound
	player.stop()

	if profile:
		# Pitch: base + small random wobble
		var wobble: float = randf_range(-profile.pitch_variance, profile.pitch_variance)
		player.pitch_scale = clamp(profile.base_pitch + wobble, 0.5, 3.0)

		# Slight volume nudge for texture
		var vol_nudge: float = randf_range(-profile.volume_variance_db, profile.volume_variance_db)
		player.volume_db = profile.base_volume_db + vol_nudge
	else:
		player.pitch_scale = randf_range(0.9, 1.1)
		player.volume_db = 0.0

	player.play()


# Helper — call this at the start of each dialog line
# to silence any still-playing blips from the last line
func stop_all_blips() -> void:
	for p in blip_players:
		p.stop()


# ─────────────────────────────────────────────
#  Utility used by your DialogBox typewriter
# ─────────────────────────────────────────────
static func is_silent_char(c: String) -> bool:
	return c in SILENT_CHARS


# ─────────────────────────────────────────────
#  Music (unchanged)
# ─────────────────────────────────────────────
func play_music(_audio: AudioStream) -> void:
	if _audio == music_players[current_music_player].stream:
		return
	current_music_player = (current_music_player + 1) % 2
	var current_player: AudioStreamPlayer = music_players[current_music_player]
	current_player.stream = _audio
	play_and_fade_in(current_player)
	var old_player = music_players[1 - current_music_player]
	fade_out_and_stop(old_player)

func play_ambient(audio: AudioStream) -> void:
	if audio == ambient_players[current_ambient_player].stream:
		return
	current_ambient_player = (current_ambient_player + 1) % 2
	var current_player = ambient_players[current_ambient_player]
	current_player.stream = audio
	play_and_fade_in(current_player)
	var old_player = ambient_players[1 - current_ambient_player]
	fade_out_and_stop(old_player)


func play_and_fade_in(player: AudioStreamPlayer) -> void:
	player.play(0)
	var tween: Tween = create_tween()
	tween.tween_property(player, "volume_db", 0, music_fade_Duration)

func fade_out_and_stop(player: AudioStreamPlayer) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(player, "volume_db", -40, music_fade_Duration)
	await tween.finished
	player.stop()


func play_sfx(sound: AudioStream) -> void:
	if sound == null:
		return
	var player: AudioStreamPlayer = blip_players[blip_pool_index]
	blip_pool_index = (blip_pool_index + 1) % blip_pool_size
	player.stream = sound
	player.pitch_scale = 1.0
	player.volume_db = 0.0
	player.stop()
	player.play()
