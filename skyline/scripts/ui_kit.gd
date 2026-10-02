class_name UIKit
extends RefCounted
## UI palette and builders (copied from PuzzleBlock and recolored): retro game windows with a light
## border and raised buttons with a dark lip.

const BG := Color(0.12, 0.16, 0.24)
const WINDOW := Color(0.14, 0.2, 0.38)
const WINDOW_HI := Color(0.2, 0.28, 0.5)
const BORDER := Color(0.93, 0.95, 1.0)
const TEXT := Color(0.98, 0.98, 1.0)
const MUTED := Color(0.72, 0.78, 0.9)
const GOLD := Color(1.0, 0.84, 0.3)
const GREEN := Color(0.45, 0.9, 0.45)
const RED := Color(1.0, 0.45, 0.42)
const ACCENT := Color(0.98, 0.6, 0.2)

const FONT: Font = preload("res://assets/fonts/font.ttf")
const BUTTON_DEPTH := 5


static func box(bg: Color, border: Color = Color.TRANSPARENT, radius: int = 10, border_w: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	if border_w > 0:
		sb.border_color = border
		sb.set_border_width_all(border_w)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


static func window(radius: int = 12) -> StyleBoxFlat:
	## The game's menu window: deep blue with a white rim, like a retro RPG window.
	var sb := box(WINDOW, BORDER, radius, 3)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	return sb


static func raised(fill: Color, line: Color, lip: Color, radius: int, pressed: bool = false) -> StyleBoxFlat:
	var sb := box(fill, line, radius, 2)
	sb.shadow_color = lip
	sb.shadow_size = 1
	var sink: int = BUTTON_DEPTH - 2 if pressed else 0
	sb.shadow_offset = Vector2(0, BUTTON_DEPTH - sink)
	sb.expand_margin_top = -sink
	sb.expand_margin_bottom = sink
	sb.content_margin_top += sink
	sb.content_margin_bottom = maxf(0.0, sb.content_margin_bottom - sink)
	return sb


static func style_raised(btn: Button, fill: Color, line: Color, lip: Color, radius: int) -> void:
	btn.add_theme_stylebox_override("normal", raised(fill, line, lip, radius))
	btn.add_theme_stylebox_override("hover", raised(fill.lightened(0.07), line.lightened(0.15), lip, radius))
	btn.add_theme_stylebox_override("pressed", raised(fill.darkened(0.08), line, lip, radius, true))
	btn.add_theme_stylebox_override("hover_pressed", raised(fill.darkened(0.08), line, lip, radius, true))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("disabled", raised(fill.darkened(0.45), line.darkened(0.5), lip, radius))


## kind: primary (orange), secondary (blue), selected (gold), ghost (text only), danger
static func style_button(btn: Button, kind: String = "secondary", font_size: int = 22, radius: int = 10) -> void:
	var font_col := TEXT
	match kind:
		"primary":
			style_raised(btn, Color(0.96, 0.55, 0.18), Color(1.0, 0.8, 0.5), Color(0.5, 0.22, 0.05), radius)
		"selected":
			style_raised(btn, Color(1.0, 0.82, 0.3), Color(1.0, 0.97, 0.8), Color(0.55, 0.38, 0.05), radius)
			font_col = Color(0.25, 0.16, 0.05)
		"danger":
			style_raised(btn, Color(0.75, 0.22, 0.22), Color(1.0, 0.55, 0.5), Color(0.35, 0.06, 0.06), radius)
		"ghost":
			for st in ["normal", "hover", "pressed", "hover_pressed"]:
				btn.add_theme_stylebox_override(st, box(Color(1, 1, 1, 0.0 if st == "normal" else 0.08)))
			btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
			font_col = MUTED
		_:
			style_raised(btn, Color(0.25, 0.37, 0.66), Color(0.62, 0.74, 1.0), Color(0.07, 0.1, 0.22), radius)
	btn.add_theme_font_override("font", FONT)
	btn.add_theme_font_size_override("font_size", font_size)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		btn.add_theme_color_override(key, font_col)
	btn.add_theme_color_override("font_disabled_color", Color(MUTED, 0.45))


static func label(text: String, size: int, color: Color = TEXT, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.12))
	l.add_theme_constant_override("outline_size", 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func outlined(l: Label, size: int = 6) -> Label:
	l.add_theme_constant_override("outline_size", size)
	return l


static func format_number(n: int) -> String:
	var s := str(absi(n))
	var res := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = "," + res
	return ("-" if n < 0 else "") + res


static func money(n: int) -> String:
	return ("-$" if n < 0 else "$") + format_number(absi(n))
