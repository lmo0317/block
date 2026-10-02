class_name Atlas
extends RefCounted
## Sprite atlas made by tools/generate_sprites.py: one texture plus name -> region.

static var texture: Texture2D
static var regions := {}


static func load_once() -> void:
	if texture != null:
		return
	texture = load("res://assets/sprites/atlas.png")
	var f := FileAccess.open("res://assets/sprites/atlas.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	for k in data:
		var r: Array = data[k]
		regions[k] = Rect2(r[0], r[1], r[2], r[3])


static func region(name: String) -> Rect2:
	return regions.get(name, Rect2())


static func icon(name: String) -> AtlasTexture:
	load_once()
	var t := AtlasTexture.new()
	t.atlas = texture
	t.region = region(name)
	return t
