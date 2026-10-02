class_name BoardThemes
extends RefCounted
# Game screen themes that change on every perfect clear, as in Block Blast. Purely visual:
# the backdrop (assets/art, painted with Gemini), the board's fill and rim, and a tint on the
# empty cells ("slots", multiplied onto the dark slot sprite). Block skins stay
# whatever the player picked in settings.

const THEMES: Array = [
	{"name": "미드나잇", "bg": "res://assets/art/game_bg.jpg", "board": Color(0.07, 0.094, 0.153, 0.95), "rim": Color(0.18, 0.24, 0.36, 0.8), "slots": Color(1, 1, 1)},
	{"name": "오로라", "bg": "res://assets/art/theme_aurora.jpg", "board": Color(0.09, 0.07, 0.18, 0.95), "rim": Color(0.45, 0.32, 0.8, 0.85), "slots": Color(1.15, 0.95, 1.45)},
	{"name": "오션", "bg": "res://assets/art/theme_ocean.jpg", "board": Color(0.035, 0.12, 0.14, 0.95), "rim": Color(0.16, 0.55, 0.6, 0.85), "slots": Color(0.8, 1.3, 1.3)},
	{"name": "선셋", "bg": "res://assets/art/theme_sunset.jpg", "board": Color(0.13, 0.055, 0.11, 0.95), "rim": Color(0.85, 0.42, 0.36, 0.85), "slots": Color(1.45, 0.92, 1.05)},
	{"name": "포레스트", "bg": "res://assets/art/theme_forest.jpg", "board": Color(0.035, 0.11, 0.065, 0.95), "rim": Color(0.3, 0.65, 0.42, 0.85), "slots": Color(0.85, 1.35, 0.95)},
	{"name": "코스모스", "bg": "res://assets/art/theme_cosmos.jpg", "board": Color(0.035, 0.04, 0.085, 0.95), "rim": Color(0.42, 0.44, 0.88, 0.85), "slots": Color(1.0, 1.0, 1.4)},
	{"name": "엠버", "bg": "res://assets/art/theme_ember.jpg", "board": Color(0.1, 0.075, 0.04, 0.95), "rim": Color(0.88, 0.62, 0.26, 0.85), "slots": Color(1.45, 1.15, 0.78)},
]

static func count() -> int:
	return THEMES.size()

static func get_theme(index: int) -> Dictionary:
	return THEMES[posmod(index, THEMES.size())]

static func backdrop(index: int) -> Texture2D:
	return load(get_theme(index)["bg"])
