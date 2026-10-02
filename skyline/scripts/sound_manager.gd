extends Node
## Plays the short synthesized sounds in assets/sfx (tools/generate_sfx.py). Every file peaks at
## -6 dBFS so overlapping sounds do not clip; no pitch shifting at runtime.

const POOL_SIZE := 10
const KEYS := ["click", "place", "build", "coin", "bulldoze", "invalid", "rankup", "notice", "yearend"]
# quiet, frequent sounds are throttled so a busy city does not turn into noise
const MIN_GAP := {"build": 0.12, "coin": 0.09, "place": 0.04}
const VOLUME := {"coin": -9.0, "build": -6.0, "place": -4.0}

var muted := false
var sounds := {}
var players: Array[AudioStreamPlayer] = []
var last_played := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	for k in KEYS:
		var path := "res://assets/sfx/%s.wav" % k
		if ResourceLoader.exists(path):
			sounds[k] = load(path)


func play(key: String) -> void:
	if muted or not sounds.has(key):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if MIN_GAP.has(key) and now - float(last_played.get(key, -10.0)) < MIN_GAP[key]:
		return
	last_played[key] = now
	for p in players:
		if not p.playing:
			p.stream = sounds[key]
			p.volume_db = VOLUME.get(key, 0.0)
			p.play()
			return
