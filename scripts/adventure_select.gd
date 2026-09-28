class_name AdventureSelect
extends ColorRect
# Adventure stage select screen: 4x5 grid of stages with stars and lock state.

signal stage_selected(stage_id: int)
signal closed

const COLUMNS: int = 4
const BUTTON_SIZE: Vector2 = Vector2(122, 124)

var font_res: Font = preload("res://assets/fonts/font.ttf")
var grid: GridContainer
var summary_label: Label

func _ready() -> void:
	visible = false
	z_index = 150
	color = Color(0.0431373, 0.0588235, 0.0980392, 0.98)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var card := Panel.new()
	card.add_theme_stylebox_override("panel", _box(Color(0.07, 0.1, 0.17, 0.98), Color(0.22, 0.4, 0.7, 0.8), 24, 2))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -310
	card.offset_right = 310
	card.offset_top = -500
	card.offset_bottom = 500
	add_child(card)

	var title := _label("어드벤처", 40, Color(0.99, 0.88, 0.28))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 28
	title.offset_bottom = 80
	card.add_child(title)

	summary_label = _label("", 18, Color(0.65, 0.72, 0.82))
	summary_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	summary_label.offset_top = 82
	summary_label.offset_bottom = 110
	card.add_child(summary_label)

	grid = GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	grid.position = Vector2((620 - (BUTTON_SIZE.x * COLUMNS + 16 * (COLUMNS - 1))) * 0.5, 130)
	card.add_child(grid)

	var back := Button.new()
	back.text = "홈으로 (HOME)"
	back.add_theme_font_override("font", font_res)
	back.add_theme_font_size_override("font_size", 20)
	back.add_theme_stylebox_override("normal", _box(Color(0.12, 0.16, 0.25, 0.95), Color(0.3, 0.38, 0.5, 0.7), 16, 2))
	back.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	back.offset_left = -260
	back.offset_right = 260
	back.offset_top = -90
	back.offset_bottom = -30
	back.pressed.connect(close)
	card.add_child(back)

func open() -> void:
	SoundManager.play_click()
	refresh()
	visible = true
	modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.2)

func close() -> void:
	SoundManager.play_click()
	visible = false
	closed.emit()

func refresh() -> void:
	for child in grid.get_children():
		child.queue_free()

	var progress: Dictionary = AdventureData.load_progress()
	var total_stars := 0
	for s in AdventureData.STAGES:
		var sid: int = s["id"]
		var stars: int = int(progress["stars"].get(str(sid), 0))
		total_stars += stars
		var locked: bool = sid > int(progress["unlocked"])

		var btn := Button.new()
		btn.custom_minimum_size = BUTTON_SIZE
		btn.add_theme_font_override("font", font_res)
		btn.add_theme_font_size_override("font_size", 22)
		btn.name = "Stage%d" % sid
		if locked:
			btn.text = "%d\n잠김" % sid
			btn.disabled = true
			btn.add_theme_stylebox_override("disabled", _box(Color(0.08, 0.1, 0.15, 0.9), Color(0.18, 0.22, 0.3, 0.6), 16, 2))
			btn.add_theme_color_override("font_disabled_color", Color(0.35, 0.4, 0.5))
		else:
			btn.text = "%d\n%s" % [sid, AdventureData.star_text(stars)]
			var border := Color(0.99, 0.82, 0.25, 0.9) if stars > 0 else Color(0.22, 0.74, 0.97, 0.9)
			btn.add_theme_stylebox_override("normal", _box(Color(0.12, 0.17, 0.28, 0.95), border, 16, 2))
			btn.add_theme_stylebox_override("hover", _box(Color(0.16, 0.23, 0.38, 0.95), border, 16, 3))
			btn.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
			btn.tooltip_text = "%s · %s" % [s["name"], AdventureData.goal_text(s["goal"])]
			btn.pressed.connect(func(): stage_selected.emit(sid))
		grid.add_child(btn)

	summary_label.text = "모은 별 %d / %d" % [total_stars, AdventureData.stage_count() * 3]

func _label(text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font_res)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func _box(bg: Color, border: Color, radius: int, border_w: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	return sb
