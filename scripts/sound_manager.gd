extends Node

var is_muted: bool = false
var sounds: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 12

func _ready() -> void:
	# Create pool of AudioStreamPlayers
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		players.append(p)
	
	# Load sound assets
	_load_sound("pickup", "res://assets/sfx/pickup.wav")
	_load_sound("place", "res://assets/sfx/place.wav")
	_load_sound("invalid", "res://assets/sfx/invalid.wav")
	_load_sound("clear", "res://assets/sfx/clear.wav")
	_load_sound("gameover", "res://assets/sfx/gameover.wav")
	_load_sound("record", "res://assets/sfx/record.wav")
	_load_sound("click", "res://assets/sfx/click.wav")
	_load_sound("deal", "res://assets/sfx/deal.wav")
	
	for i in range(1, 8):
		_load_sound("combo_%d" % i, "res://assets/sfx/combo_%d.wav" % i)

func _load_sound(key: String, path: String) -> void:
	if ResourceLoader.exists(path):
		var stream = load(path)
		sounds[key] = stream

func play(key: String, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if is_muted:
		return
	if not sounds.has(key):
		return
	
	var player = _get_available_player()
	if player:
		player.stream = sounds[key]
		player.pitch_scale = pitch_scale
		player.volume_db = volume_db
		player.play()

func _get_available_player() -> AudioStreamPlayer:
	for p in players:
		if not p.playing:
			return p
	return players[0]

func play_pickup() -> void:
	play("pickup", 1.0, -2.0)

func play_place() -> void:
	play("place", 1.0, 0.0)

func play_invalid() -> void:
	play("invalid", 1.0, -2.0)

func play_clear() -> void:
	play("clear", 1.0, 1.0)

func play_combo(combo_level: int) -> void:
	var idx = clamp(combo_level, 1, 7)
	play("combo_%d" % idx, 1.0, 2.0)

func play_gameover() -> void:
	play("gameover", 1.0, 2.0)

func play_record() -> void:
	play("record", 1.0, 3.0)

func play_click() -> void:
	play("click", 1.0, -4.0)

func play_deal() -> void:
	play("deal", 1.0, -2.0)

func toggle_mute() -> bool:
	is_muted = not is_muted
	return is_muted
