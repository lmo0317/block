class_name AdventureSelect
extends ColorRect
# Adventure stage select screen: 4x5 grid of stages with stars and lock state.

signal stage_selected(stage_id: int)
signal closed

const COLUMNS: int = 4
const BUTTON_SIZE: Vector2 = Vector2(122, 124)
const LOCK_ICON: Texture2D = preload("res://assets/sprites/lock_icon.png")

var grid: GridContainer
var summary_label: Label

func _ready() -> void:
	visible = false
	z_index = 150
	color = Color(UIKit.BG, 0.99)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var card := Panel.new()
	UIKit.style_modal(card)
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -310
	card.offset_right = 310
	card.offset_top = -500
	card.offset_bottom = 500
	add_child(card)

	var title := UIKit.label("어드벤처", UIKit.TYPE_MODAL_TITLE, UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 28
	title.offset_bottom = 80
	card.add_child(title)

	summary_label = UIKit.label("", UIKit.TYPE_BODY, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
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
	back.text = "홈으로"
	UIKit.style_button(back, "secondary", 22, 18)
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
		btn.name = "Stage%d" % sid
		if locked:
			btn.text = ""
			btn.disabled = true
			UIKit.style_button(btn, "secondary", 22, 18)
			btn.add_theme_stylebox_override("disabled", UIKit.raised(UIKit.SURFACE_HI, Color(UIKit.BORDER, 0.72), Color(0.02, 0.03, 0.06), 18))
			_add_locked_content(btn, sid)
		else:
			btn.text = "%d\n%s" % [sid, AdventureData.star_text(stars)]
			var border := Color(0.99, 0.82, 0.25, 0.9) if stars > 0 else Color(0.22, 0.74, 0.97, 0.9)
			UIKit.style_raised(btn, UIKit.SURFACE_HI, border, Color(0.02, 0.03, 0.06), 18)
			btn.add_theme_font_override("font", UIKit.FONT)
			btn.add_theme_font_size_override("font_size", 22)
			btn.add_theme_color_override("font_color", UIKit.TEXT)
			btn.add_theme_color_override("font_hover_color", UIKit.TEXT)
			btn.add_theme_color_override("font_pressed_color", UIKit.TEXT)
			btn.tooltip_text = "%s · %s" % [s["name"], AdventureData.goal_text(s["goal"])]
			btn.pressed.connect(func(): stage_selected.emit(sid))
		grid.add_child(btn)

	summary_label.text = "모은 별 %d / %d" % [total_stars, AdventureData.stage_count() * 3]

func _add_locked_content(btn: Button, stage_id: int) -> void:
	# Keep the lock as a centered state marker instead of a tiny inline button icon.
	var stack := VBoxContainer.new()
	btn.add_child(stack)
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 1)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var number := UIKit.label(str(stage_id), 22, Color(UIKit.MUTED, 0.92), HORIZONTAL_ALIGNMENT_CENTER)
	number.custom_minimum_size = Vector2(0, 26)
	number.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_child(number)

	var icon_center := CenterContainer.new()
	icon_center.custom_minimum_size = Vector2(0, 32)
	icon_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lock := TextureRect.new()
	lock.texture = LOCK_ICON
	lock.custom_minimum_size = Vector2(30, 30)
	lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_center.add_child(lock)
	stack.add_child(icon_center)

	var state := UIKit.label("잠김", UIKit.TYPE_BODY, Color(UIKit.MUTED, 0.92), HORIZONTAL_ALIGNMENT_CENTER)
	state.custom_minimum_size = Vector2(0, 27)
	state.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_child(state)
