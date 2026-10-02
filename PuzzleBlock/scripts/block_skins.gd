class_name BlockSkins
extends RefCounted
# Block texture lookup for the selected skin (SettingsManager.block_skin), with a per-skin cache.
# "classic" uses assets/sprites/block_<color>.png; others live in assets/sprites/skins/<skin>/.

const SKINS: Array[Dictionary] = [
	{"id": "classic", "name": "클래식"},
	{"id": "candy", "name": "캔디"},
	{"id": "neon", "name": "네온"},
	{"id": "jewel", "name": "보석"},
]
const COLORS: Array[String] = ["blue", "orange", "green", "purple", "yellow", "red", "cyan", "pink"]

static var _cache: Dictionary = {}

static func texture(color_name: String, skin: String = "") -> Texture2D:
	if skin.is_empty():
		skin = SettingsManager.block_skin
	var key := skin + "/" + color_name
	if _cache.has(key):
		return _cache[key]
	var path := _path(skin, color_name)
	if not ResourceLoader.exists(path):
		path = _path("classic", color_name)
	var tex: Texture2D = load(path)
	_cache[key] = tex
	return tex

static func preload_skin(skin: String) -> void:
	for c in COLORS:
		texture(c, skin)

static func is_valid(skin: String) -> bool:
	for s in SKINS:
		if s["id"] == skin:
			return true
	return false

static func _path(skin: String, color_name: String) -> String:
	if skin == "classic":
		return "res://assets/sprites/block_%s.png" % color_name
	return "res://assets/sprites/skins/%s/block_%s.png" % [skin, color_name]
