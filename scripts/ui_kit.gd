class_name UIKit
extends RefCounted
# Shared UI palette and builders so every screen uses the same colors, buttons and type.
# Rule of thumb: menus and buttons in Korean only; scoreboard terms (SCORE, BEST, COMBO) stay English.

const BG := Color(0.043, 0.059, 0.098)
const SURFACE := Color(0.075, 0.1, 0.165)
const SURFACE_HI := Color(0.11, 0.145, 0.23)
const BORDER := Color(0.2, 0.27, 0.4)
const TEXT := Color(0.93, 0.95, 0.99)
const MUTED := Color(0.6, 0.67, 0.78)
const ACCENT := Color(0.18, 0.48, 0.96)
const ACCENT_HI := Color(0.3, 0.58, 1.0)
const GOLD := Color(0.99, 0.82, 0.3)
const PURPLE := Color(0.75, 0.52, 0.99)
const CYAN := Color(0.13, 0.83, 0.93)
const DANGER := Color(0.93, 0.36, 0.36)

const FONT: Font = preload("res://assets/fonts/font.ttf")

static func box(bg: Color, border: Color = Color.TRANSPARENT, radius: int = 16, border_w: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	if border_w > 0:
		sb.border_color = border
		sb.set_border_width_all(border_w)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

# kind: "primary" (solid accent), "secondary" (surface + border), "ghost" (text only), "danger"
static func style_button(btn: Button, kind: String = "secondary", font_size: int = 20, radius: int = 16) -> void:
	var normal: StyleBoxFlat
	var hover: StyleBoxFlat
	var pressed: StyleBoxFlat
	var font_col := TEXT
	match kind:
		"primary":
			normal = box(ACCENT, ACCENT_HI, radius, 0)
			normal.shadow_color = Color(ACCENT, 0.35)
			normal.shadow_size = 10
			normal.shadow_offset = Vector2(0, 4)
			hover = box(ACCENT_HI, ACCENT_HI, radius, 0)
			pressed = box(ACCENT.darkened(0.15), ACCENT, radius, 0)
		"danger":
			normal = box(Color(DANGER, 0.12), Color(DANGER, 0.6), radius, 2)
			hover = box(Color(DANGER, 0.2), DANGER, radius, 2)
			pressed = box(Color(DANGER, 0.28), DANGER, radius, 2)
			font_col = Color(1.0, 0.72, 0.72)
		"ghost":
			normal = box(Color.TRANSPARENT, Color.TRANSPARENT, radius, 0)
			hover = box(Color(1, 1, 1, 0.06), Color.TRANSPARENT, radius, 0)
			pressed = box(Color(1, 1, 1, 0.1), Color.TRANSPARENT, radius, 0)
			font_col = MUTED
		_:
			normal = box(SURFACE_HI, BORDER, radius, 2)
			hover = box(SURFACE_HI.lightened(0.06), ACCENT_HI, radius, 2)
			pressed = box(SURFACE, ACCENT, radius, 2)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("hover_pressed", pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("disabled", box(SURFACE, Color(BORDER, 0.5), radius, 2))
	btn.add_theme_font_override("font", FONT)
	btn.add_theme_font_size_override("font_size", font_size)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		btn.add_theme_color_override(key, font_col)
	btn.add_theme_color_override("font_disabled_color", Color(MUTED, 0.5))

static func label(text: String, size: int, color: Color = TEXT, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func style_close_button(btn: Button) -> void:
	# Round "X" in the top-right corner of every modal card
	# The game font (Malgun Gothic Bold) has "×" but not "✕"
	style_button(btn, "ghost", 30, 22)
	btn.text = "×"
	btn.add_theme_color_override("font_color", MUTED)
	btn.add_theme_color_override("font_hover_color", TEXT)

static func style_modal(card: Control, title: Label = null, subtitle: Label = null) -> void:
	# Same card surface and title treatment for every popup
	if card is Panel:
		var sb := box(SURFACE, BORDER, 28, 2)
		sb.shadow_color = Color(0, 0, 0, 0.45)
		sb.shadow_size = 24
		card.add_theme_stylebox_override("panel", sb)
	if title:
		title.label_settings = null
		title.add_theme_font_override("font", FONT)
		title.add_theme_font_size_override("font_size", 34)
		title.add_theme_color_override("font_color", TEXT)
	if subtitle:
		subtitle.label_settings = null
		subtitle.add_theme_font_override("font", FONT)
		subtitle.add_theme_font_size_override("font_size", 17)
		subtitle.add_theme_color_override("font_color", MUTED)

static func format_number(n: int) -> String:
	var s := str(n)
	var res := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = "," + res
	return res
