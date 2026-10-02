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

# Raised game button: fill, a light outline, and a dark lip underneath (a shadow with no blur,
# offset down). Pressed, the button sinks onto its lip.
const BUTTON_DEPTH: int = 6

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

# Info panels (scores, records) sit sunk into the background so they never read as buttons
static func inset(radius: int = 20) -> StyleBoxFlat:
	return box(Color(0.03, 0.045, 0.08), Color(0.15, 0.2, 0.31), radius, 2)

static func style_raised(btn: Button, fill: Color, line: Color, lip: Color, radius: int) -> void:
	btn.add_theme_stylebox_override("normal", raised(fill, line, lip, radius))
	btn.add_theme_stylebox_override("hover", raised(fill.lightened(0.07), line.lightened(0.15), lip, radius))
	btn.add_theme_stylebox_override("pressed", raised(fill.darkened(0.08), line, lip, radius, true))
	btn.add_theme_stylebox_override("hover_pressed", raised(fill.darkened(0.08), line, lip, radius, true))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

# kind: "primary" (solid accent), "secondary" (surface + outline), "ghost" (text only), "danger"
static func style_button(btn: Button, kind: String = "secondary", font_size: int = 20, radius: int = 16) -> void:
	var font_col := TEXT
	match kind:
		"primary":
			style_raised(btn, Color(0.2, 0.52, 1.0), Color(0.5, 0.74, 1.0), Color(0.06, 0.2, 0.5), radius)
		"danger":
			style_raised(btn, Color(0.55, 0.16, 0.2), Color(0.95, 0.45, 0.45), Color(0.25, 0.05, 0.08), radius)
			font_col = Color(1.0, 0.85, 0.85)
		"ghost":
			btn.add_theme_stylebox_override("normal", box(Color.TRANSPARENT, Color.TRANSPARENT, radius, 0))
			btn.add_theme_stylebox_override("hover", box(Color(1, 1, 1, 0.06), Color.TRANSPARENT, radius, 0))
			btn.add_theme_stylebox_override("pressed", box(Color(1, 1, 1, 0.1), Color.TRANSPARENT, radius, 0))
			btn.add_theme_stylebox_override("hover_pressed", box(Color(1, 1, 1, 0.1), Color.TRANSPARENT, radius, 0))
			btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
			font_col = MUTED
		_:
			style_raised(btn, Color(0.13, 0.17, 0.28), Color(0.33, 0.43, 0.62), Color(0.02, 0.03, 0.06), radius)
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

static func style_avatar_frame(frame: Panel) -> void:
	# Avatars are rounded blocks, so their highlight frame is a rounded square too
	var sb := box(Color(ACCENT, 0.12), ACCENT_HI, 24, 3)
	sb.shadow_color = Color(ACCENT, 0.45)
	sb.shadow_size = 14
	frame.add_theme_stylebox_override("panel", sb)

static func style_avatar_button(btn: Button, selected: bool) -> void:
	# Same look in every state so the selection stays visible under the pointer
	var sb: StyleBoxFlat
	if selected:
		sb = box(Color(ACCENT, 0.22), CYAN, 14, 3)
	else:
		sb = box(Color.TRANSPARENT, Color.TRANSPARENT, 14, 0)
	sb.content_margin_left = 5
	sb.content_margin_right = 5
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		btn.add_theme_stylebox_override(state, sb)

static func backdrop(tex: Texture2D) -> TextureRect:
	# Full-rect background image that never takes input
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return r

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
