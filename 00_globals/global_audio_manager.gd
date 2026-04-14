extends Node

var music_audio_player_count: int = 2
var current_music_player : int = 0
var music_players : array[ AudioStreamPlayer ] = []
var music_bus : String = "Music"

var music_fade_Duration
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in music_audio_player_count:
		var player = AudioStreamPlayer.new()
		add_child(player)
		player.bus = music_bus
		music_players.append( player )
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
