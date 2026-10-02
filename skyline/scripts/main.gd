extends Control
## Game screen: title, map with camera and tools, top info bar, bottom build bar, popups.
## The rules live in City; this script turns input into City edits and City signals into feedback.

const W := 720
const H := 1280
const TOP_H := 150
const BOTTOM_Y := 994
const VIEW := Rect2(0, TOP_H, W, BOTTOM_Y - TOP_H)
const SAVE_PATH := "user://save.json"
const META_PATH := "user://meta.json"
const MIN_ZOOM := 1.0
const MAX_ZOOM := 6.0
const MAX_RECT := 16
const FAC_PAGE := 6

enum Tool { HAND, ROAD, R, C, I, FAC, BULLDOZE }
const TOOL_INFO := {
	Tool.HAND: ["보기", "ui_hand"],
	Tool.ROAD: ["도로", "ui_road"],
	Tool.R: ["주거", "ui_res"],
	Tool.C: ["상업", "ui_com"],
	Tool.I: ["공업", "ui_ind"],
	Tool.FAC: ["시설", "ui_fac"],
	Tool.BULLDOZE: ["철거", "ui_bulldoze"],
}

var city: City
var world: Node2D
var map: MapView
var walkers: Walkers
var fx: FxLayer

var zoom := 3.0
var cam := Vector2.ZERO
var tool := Tool.HAND
var fac_id := 2
var fac_page := 0
var speed_idx := 1
var week_timer := 0.0
var meta := {"dex": {}, "best": 0, "best_daily": {}, "muted": false}
var year_start := {}
var year_net := 0

# pointer state
var stroke_active := false
var stroke_start := -1
var stroke_last := -1
var stroke_moved := false
var stroke_press := Vector2.ZERO
var stroke_changes := {}
var stroke_spent := 0
var stroke_failed := false
var undo_op := {}
var panning := false
var pan_last := Vector2.ZERO
var touches := {}
var multi_touch := false
var pinch_dist := 1.0
var pinch_zoom := 3.0
var pinch_anchor := Vector2.ZERO

# UI
var money_label: Label
var delta_label: Label
var date_label: Label
var pop_label: Label
var rank_label: Label
var goals_label: Label
var demand_bars: Array = []
var speed_buttons: Array = []
var tool_buttons := {}
var undo_button: Button
var context_box: Control
var hint_label: Label
var fac_row: HBoxContainer
var fac_buttons := {}
var toast_panel: PanelContainer
var toast_label: Label
var toast_queue: Array = []
var toast_time := 0.0
var modal_layer: Control
var title_screen: Control
var continue_button: Button
var best_label: Label


func _ready() -> void:
	Atlas.load_once()
	_load_meta()
	SoundManager.muted = meta.get("muted", false)
	world = Node2D.new()
	add_child(world)
	map = MapView.new()
	world.add_child(map)
	walkers = Walkers.new()
	world.add_child(walkers)
	walkers.shop_visit.connect(_on_shop_visit)
	fx = FxLayer.new()
	fx.world = world
	add_child(fx)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_top_bar()
	_build_bottom_bar()
	_build_toast()
	modal_layer = Control.new()
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(modal_layer)
	_build_title()
	_show_title()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if city != null and not city.finished:
			_save_game()


# ================================================================ title
func _build_title() -> void:
	title_screen = Control.new()
	title_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(title_screen)
	var bg := ColorRect.new()
	bg.color = UIKit.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_screen.add_child(bg)
	var frame := Panel.new()
	frame.add_theme_stylebox_override("panel", UIKit.window(16))
	frame.position = Vector2(40, 70)
	frame.size = Vector2(640, 520)
	title_screen.add_child(frame)
	var art := TextureRect.new()
	art.texture = load("res://assets/art/title.jpg")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.position = Vector2(6, 6)
	art.size = Vector2(628, 508)
	art.clip_contents = true
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	frame.add_child(art)
	var title := UIKit.outlined(UIKit.label("도트 미니 시티", 64, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER), 12)
	title.position = Vector2(0, 610)
	title.size = Vector2(W, 80)
	title_screen.add_child(title)
	var sub := UIKit.label("구역을 칠하면 도시가 스스로 자라요", 24, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	sub.position = Vector2(0, 690)
	sub.size = Vector2(W, 36)
	title_screen.add_child(sub)
	var col := VBoxContainer.new()
	col.position = Vector2(160, 760)
	col.size = Vector2(400, 380)
	col.add_theme_constant_override("separation", 18)
	title_screen.add_child(col)
	continue_button = _menu_button(col, "이어하기", "primary", _continue_game)
	_menu_button(col, "새 도시 만들기", "primary", func(): _start_game("normal"))
	_menu_button(col, "오늘의 도시", "secondary", func(): _start_game("daily"))
	_menu_button(col, "콤보 도감", "secondary", _show_dex)
	best_label = UIKit.label("", 22, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	best_label.position = Vector2(0, 1180)
	best_label.size = Vector2(W, 34)
	title_screen.add_child(best_label)
	var tag := UIKit.label("가칭 · 첫 플레이 버전", 18, Color(UIKit.MUTED, 0.6), HORIZONTAL_ALIGNMENT_CENTER)
	tag.position = Vector2(0, 1222)
	tag.size = Vector2(W, 30)
	title_screen.add_child(tag)


func _menu_button(parent: Control, text: String, kind: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(400, 74)
	UIKit.style_button(b, kind, 28, 14)
	b.pressed.connect(func():
		SoundManager.play("click")
		cb.call())
	parent.add_child(b)
	return b


func _show_title() -> void:
	_close_modal()
	title_screen.visible = true
	continue_button.visible = FileAccess.file_exists(SAVE_PATH)
	var today := _today()
	var daily: int = int(meta["best_daily"].get(today, 0))
	var text := "최고 점수 %s" % UIKit.format_number(int(meta["best"]))
	if daily > 0:
		text += "  ·  오늘의 도시 %s" % UIKit.format_number(daily)
	best_label.text = text
	walkers.clear()


func _today() -> String:
	return Time.get_date_string_from_system()


# ================================================================ game start / save
func _start_game(mode: String) -> void:
	city = City.new()
	var seed_in := randi()
	if mode == "daily":
		seed_in = _today().replace("-", "").to_int()
	city.new_game(seed_in, mode)
	_attach_city()
	_save_game()
	_toast("고속도로(왼쪽)에 도로를 이어 깔고, 발전소와 급수탑을 지어요", "info")


func _continue_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	city = City.new()
	if typeof(d) != TYPE_DICTIONARY or not city.from_dict(d):
		_toast("저장된 도시를 불러오지 못했어요", "bad")
		return
	_attach_city()


func _attach_city() -> void:
	city.notice.connect(_toast)
	city.built.connect(_on_built)
	city.burned.connect(_on_burned)
	city.combo_found.connect(_on_combo_found)
	city.rank_up.connect(_on_rank_up)
	city.month_passed.connect(_on_month_passed)
	city.year_end.connect(_on_year_end)
	city.finished_run.connect(_on_finished)
	map.city = city
	walkers.city = city
	walkers.clear()
	# combos already standing in a loaded city count for the dex too
	for k in city.seen_combos:
		meta["dex"][k] = true
	title_screen.visible = false
	undo_op = {}
	week_timer = 0.0
	year_start = {"pop": city.pop, "money": city.money}
	year_net = 0
	_set_tool(Tool.HAND)
	_set_speed(1)
	var a := city.active_rect()
	cam = Vector2(a.get_center()) * MapView.CELL
	zoom = 3.0
	_apply_camera()
	_after_edit()


func _save_game() -> void:
	if city == null:
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(city.to_dict()))


func _delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


func _load_meta() -> void:
	var f := FileAccess.open(META_PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) == TYPE_DICTIONARY:
		for k in d:
			meta[k] = d[k]


func _save_meta() -> void:
	var f := FileAccess.open(META_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(meta))


# ================================================================ top bar
func _build_top_bar() -> void:
	var bar := Panel.new()
	var sb := UIKit.window(0)
	sb.set_border_width_all(0)
	sb.border_width_bottom = 3
	bar.add_theme_stylebox_override("panel", sb)
	bar.position = Vector2(0, 0)
	bar.size = Vector2(W, TOP_H)
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bar)
	money_label = UIKit.outlined(UIKit.label("$0", 34, UIKit.GOLD), 6)
	money_label.position = Vector2(18, 6)
	money_label.size = Vector2(230, 44)
	bar.add_child(money_label)
	delta_label = UIKit.label("", 19, UIKit.GREEN)
	delta_label.position = Vector2(20, 48)
	delta_label.size = Vector2(230, 28)
	bar.add_child(delta_label)
	date_label = UIKit.outlined(UIKit.label("", 26), 4)
	date_label.position = Vector2(250, 8)
	date_label.size = Vector2(300, 40)
	bar.add_child(date_label)
	pop_label = UIKit.label("", 20, UIKit.TEXT)
	pop_label.position = Vector2(252, 48)
	pop_label.size = Vector2(320, 28)
	bar.add_child(pop_label)
	var chip := PanelContainer.new()
	var csb := UIKit.box(UIKit.ACCENT, Color(1, 0.9, 0.7), 8, 2)
	csb.content_margin_top = 2
	csb.content_margin_bottom = 2
	chip.add_theme_stylebox_override("panel", csb)
	chip.position = Vector2(14, 88)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(chip)
	rank_label = UIKit.outlined(UIKit.label("마을", 22), 4)
	chip.add_child(rank_label)
	goals_label = UIKit.label("", 19, UIKit.TEXT)
	goals_label.position = Vector2(130, 86)
	goals_label.size = Vector2(450, 52)
	goals_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goals_label.add_theme_constant_override("line_spacing", -4)
	bar.add_child(goals_label)
	# demand bars R C I (bottom-right; the top-right corner stays free for platform buttons)
	var names := ["주", "상", "공"]
	for k in 3:
		var x := 600 + k * 38
		var back := ColorRect.new()
		back.color = Color(0, 0, 0, 0.35)
		back.position = Vector2(x, 84)
		back.size = Vector2(26, 44)
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.add_child(back)
		var fill := ColorRect.new()
		fill.color = Defs.ZONE_COLORS[k + 1]
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		back.add_child(fill)
		demand_bars.append(fill)
		var l := UIKit.label(names[k], 15, UIKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		l.position = Vector2(x - 6, 126)
		l.size = Vector2(38, 20)
		bar.add_child(l)


func _update_hud() -> void:
	if city == null:
		return
	money_label.text = UIKit.money(city.money)
	money_label.add_theme_color_override("font_color", UIKit.GOLD if city.money >= 0 else UIKit.RED)
	var net := city.last_income - city.last_expense
	delta_label.text = "월 %s%s" % ["+" if net >= 0 else "", UIKit.money(net)] if city.month > 0 else "월 수입 —"
	delta_label.add_theme_color_override("font_color", UIKit.GREEN if net >= 0 else UIKit.RED)
	var date := "%d년차 %d월" % [mini(city.year(), Defs.YEARS), city.month_of_year()] if not city.finished else "%d년 완료" % Defs.YEARS
	if city.event_key != "":
		for e in Defs.EVENTS:
			if e["key"] == city.event_key:
				date += "  · %s" % e["name"]
	date_label.text = date
	pop_label.text = "인구 %s  ·  행복 %d" % [UIKit.format_number(city.pop), city.happiness]
	rank_label.text = Defs.RANKS[city.rank]["name"]
	if city.rank + 1 < Defs.RANKS.size():
		var parts: Array = []
		for g in city.rank_goals(city.rank + 1):
			parts.append("%s %s/%s" % [g[0], UIKit.format_number(g[1]), UIKit.format_number(g[2])])
		goals_label.text = "다음 '%s': %s" % [Defs.RANKS[city.rank + 1]["name"], "  ".join(parts)]
	else:
		goals_label.text = "최고 랭크예요! 점수를 더 올려 봐요"
	for k in 3:
		var d: float = city.demand[k + 1]
		var bar: ColorRect = demand_bars[k]
		var h := absf(d) * 22.0
		bar.position = Vector2(0, 22.0 - h if d >= 0 else 22.0)
		bar.size = Vector2(26, maxf(h, 2.0))
		bar.color = Defs.ZONE_COLORS[k + 1] if d >= 0 else Color(0.9, 0.3, 0.3)


# ================================================================ bottom bar
func _build_bottom_bar() -> void:
	var bar := Panel.new()
	var sb := UIKit.window(0)
	sb.set_border_width_all(0)
	sb.border_width_top = 3
	bar.add_theme_stylebox_override("panel", sb)
	bar.position = Vector2(0, BOTTOM_Y)
	bar.size = Vector2(W, H - BOTTOM_Y)
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bar)
	# row A: speed, undo, dex, menu
	var icons := ["ui_pause", "ui_play1", "ui_play2", "ui_play3"]
	for k in 4:
		var b := _icon_button(icons[k], Vector2(64, 50))
		b.position = Vector2(12 + k * 72, 10)
		b.pressed.connect(func(): _set_speed(k))
		bar.add_child(b)
		speed_buttons.append(b)
	undo_button = _icon_button("ui_undo", Vector2(64, 50))
	undo_button.position = Vector2(470, 10)
	undo_button.pressed.connect(_undo)
	bar.add_child(undo_button)
	var dex := _icon_button("ui_book", Vector2(64, 50))
	dex.position = Vector2(554, 10)
	dex.pressed.connect(_show_dex)
	bar.add_child(dex)
	var menu := _icon_button("ui_menu", Vector2(64, 50))
	menu.position = Vector2(638, 10)
	menu.pressed.connect(_show_menu)
	bar.add_child(menu)
	# row B: tools
	var order := [Tool.HAND, Tool.ROAD, Tool.R, Tool.C, Tool.I, Tool.FAC, Tool.BULLDOZE]
	for k in order.size():
		var t: int = order[k]
		var b := Button.new()
		b.text = TOOL_INFO[t][0]
		b.icon = Atlas.icon(TOOL_INFO[t][1])
		b.expand_icon = true
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_theme_constant_override("icon_max_width", 44)
		b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		b.custom_minimum_size = Vector2(94, 98)
		b.size = Vector2(94, 98)
		b.position = Vector2(10 + k * 101, 72)
		UIKit.style_button(b, "secondary", 19, 10)
		b.pressed.connect(func():
			SoundManager.play("click")
			_set_tool(t))
		bar.add_child(b)
		tool_buttons[t] = b
	# row C: hint text or facility palette
	context_box = Control.new()
	context_box.position = Vector2(10, 182)
	context_box.size = Vector2(700, 98)
	bar.add_child(context_box)
	hint_label = UIKit.label("", 19, UIKit.TEXT)
	hint_label.position = Vector2(6, 0)
	hint_label.size = Vector2(688, 96)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_constant_override("line_spacing", -2)
	context_box.add_child(hint_label)
	fac_row = HBoxContainer.new()
	fac_row.position = Vector2(0, 2)
	fac_row.size = Vector2(700, 92)
	fac_row.add_theme_constant_override("separation", 6)
	context_box.add_child(fac_row)
	var prev := _small_button("◀", func(): _fac_page_step(-1))
	fac_row.add_child(prev)
	for id in Defs.FAC_ORDER:
		var b := Button.new()
		b.icon = Atlas.icon(Defs.fac(id)["key"])
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_constant_override("icon_max_width", 28)
		b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		b.custom_minimum_size = Vector2(98, 88)
		b.clip_text = false
		UIKit.style_button(b, "secondary", 15, 8)
		b.pressed.connect(func():
			SoundManager.play("click")
			_select_facility(id))
		fac_row.add_child(b)
		fac_buttons[id] = b
	var next := _small_button("▶", func(): _fac_page_step(1))
	fac_row.add_child(next)


func _icon_button(icon: String, size: Vector2) -> Button:
	var b := Button.new()
	b.icon = Atlas.icon(icon)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.custom_minimum_size = size
	b.size = size
	UIKit.style_button(b, "secondary", 18, 10)
	b.add_theme_constant_override("icon_max_width", 32)
	return b


func _small_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(44, 88)
	UIKit.style_button(b, "secondary", 20, 8)
	b.pressed.connect(func():
		SoundManager.play("click")
		cb.call())
	return b


func _set_speed(k: int) -> void:
	speed_idx = k
	for i in speed_buttons.size():
		UIKit.style_button(speed_buttons[i], "selected" if i == k else "secondary", 18, 10)


func _set_tool(t: int) -> void:
	tool = t
	for k in tool_buttons:
		UIKit.style_button(tool_buttons[k], "selected" if k == t else "secondary", 19, 10)
	map.selected = -1
	map.preview = {}
	map.ghost_cell = -1
	map.overlay = _overlay_for_tool()
	_update_context()
	map.queue_redraw()


func _select_facility(id: int) -> void:
	if city == null:
		return
	if not city.unlocked(id):
		var need: int = Defs.fac(id)["rank"]
		_toast("'%s' 랭크가 되면 지을 수 있어요" % Defs.RANKS[need]["name"], "info")
		return
	fac_id = id
	map.overlay = _overlay_for_tool()
	_update_context()
	map.queue_redraw()


func _overlay_for_tool() -> String:
	if tool != Tool.FAC:
		return ""
	match fac_id:
		2:
			return "power"
		3:
			return "water"
		7, 8, 9, 10:
			return "svc:%d" % Defs.SERVICE_BIT[fac_id]
	return "land"


func _fac_page_step(d: int) -> void:
	var pages := ceili(Defs.FAC_ORDER.size() / float(FAC_PAGE))
	fac_page = posmod(fac_page + d, pages)
	_update_context()


func _update_context() -> void:
	if city == null:
		return
	fac_row.visible = tool == Tool.FAC
	hint_label.visible = tool != Tool.FAC
	undo_button.disabled = undo_op.is_empty() or undo_op.get("month", -1) != city.month
	if tool == Tool.FAC:
		for k in Defs.FAC_ORDER.size():
			var id: int = Defs.FAC_ORDER[k]
			var b: Button = fac_buttons[id]
			b.visible = k / FAC_PAGE == fac_page
			var f := Defs.fac(id)
			var lock := not city.unlocked(id)
			var done := Defs.is_landmark(id) and city.has_landmark(id)
			b.text = "%s\n%s" % [f["name"], "잠김" if lock else ("완성" if done else UIKit.money(f["cost"]))]
			b.modulate = Color(1, 1, 1, 0.45) if lock or done else Color.WHITE
			UIKit.style_button(b, "selected" if id == fac_id else "secondary", 15, 8)
		return
	hint_label.text = _hint_text()


func _hint_text() -> String:
	match tool:
		Tool.ROAD:
			return "도로 %s/칸 (물 위 다리 %s)\n손가락으로 끌어서 길게 깔아요. 고속도로와 이어져야 해요" % [UIKit.money(Defs.ROAD_COST), UIKit.money(Defs.BRIDGE_COST)]
		Tool.R, Tool.C, Tool.I:
			var z: int = [0, 0, Defs.Z.R, Defs.Z.C, Defs.Z.I][tool]
			return "%s 구역 %s/칸 · 끌어서 네모로 칠해요\n도로 2칸 안에 전기·물이 있으면 건물이 저절로 지어져요" % [Defs.ZONE_NAMES[z], UIKit.money(Defs.ZONE_COST)]
		Tool.BULLDOZE:
			return "끌어서 네모로 철거해요 (숲은 %s)\n돈은 돌려받지 못해요" % UIKit.money(Defs.CLEAR_COST)
	if map.selected >= 0:
		return _cell_info(map.selected)
	return _advice()


func _advice() -> String:
	## What to do next, for the first minutes of a run.
	var has := {}
	for i in City.CELLS:
		if city.obj[i] >= 2:
			has[city.obj[i]] = true
	var zones := 0
	for i in City.CELLS:
		if city.zone[i] != Defs.Z.NONE:
			zones += 1
	if city.road_count < 14:
		return "도움말: '도로'를 골라 왼쪽 고속도로 끝에서 이어 깔아요\n두 손가락(또는 마우스 휠)으로 확대, 끌어서 이동"
	if zones < 6:
		return "도움말: 도로 옆에 '주거' 구역을 칠해요\n집이 생기면 '상업'·'공업'도 칠해요"
	if not has.has(2) or not has.has(3):
		return "도움말: '시설'에서 발전소와 급수탑을 지어요\n전기와 물이 닿아야 건물이 자라요"
	var no_power := 0
	var no_water := 0
	var no_road := 0
	for i in City.CELLS:
		if city.zone[i] != Defs.Z.NONE:
			if city.access_road[i] < 0:
				no_road += 1
			elif city.power[i] == 0:
				no_power += 1
			elif city.water[i] == 0:
				no_water += 1
	if no_power >= 3:
		return "전기가 안 닿는 구역이 %d칸 있어요 (번개 표시)\n발전소를 하나 더 지어요" % no_power
	if no_water >= 3:
		return "물이 안 닿는 구역이 %d칸 있어요 (물방울 표시)\n급수탑을 하나 더 지어요" % no_water
	if no_road >= 3:
		return "이어진 도로가 2칸 안에 없는 구역이 %d칸 있어요\n고속도로와 이어지게 도로를 깔아요" % no_road
	var top := 1
	for z in [2, 3]:
		if city.demand[z] > city.demand[top]:
			top = z
	if city.demand[top] > 0.3:
		return "%s 수요가 높아요! %s 구역을 더 칠해 봐요\n칸을 누르면 건물 정보를 볼 수 있어요" % [Defs.ZONE_NAMES[top], Defs.ZONE_NAMES[top]]
	return "칸을 누르면 정보를 봐요. 공원·나무로 지가를 올리면 건물이 커져요\n건물 3개를 3칸 안에 모으면 콤보! (도감 참고)"


func _cell_info(i: int) -> String:
	var k := city.kind_of(i)
	var head := ""
	if k != "":
		head = Defs.kind_name(k)
		if city.zone[i] != Defs.Z.NONE:
			head += " (%s %d단계)" % [Defs.ZONE_NAMES[city.zone[i]], city.level[i]]
	elif city.zone[i] != Defs.Z.NONE:
		head = "%s 구역 %s" % [Defs.ZONE_NAMES[city.zone[i]], "(공사 중)" if city.build[i] > 0 else "(빈 땅)"]
	elif city.obj[i] == Defs.ROAD:
		head = "도로" + ("" if city.connected[i] else " (고속도로와 안 이어짐)")
	else:
		head = ["풀밭", "물", "숲"][city.terrain[i]]
	var line2 := "지가 %d" % city.land[i]
	if city.zone[i] != Defs.Z.NONE:
		line2 += "  ·  도로 %s 전기 %s 물 %s" % ["○" if city.access_road[i] >= 0 else "×", "○" if city.power[i] else "×", "○" if city.water[i] else "×"]
		if city.level[i] > 0 and city.level[i] < 3:
			var need: int = Defs.LV_NEED[city.level[i] + 1]
			line2 += "  ·  다음 단계 지가 %d" % need
	var names: Array = []
	for ci in Defs.COMBOS.size():
		if city.in_combo[i] & (1 << ci):
			names.append(Defs.COMBOS[ci]["name"])
	if not names.is_empty():
		line2 += "\n콤보: " + ", ".join(names)
	return head + "\n" + line2


# ================================================================ toast and popups
func _build_toast() -> void:
	toast_panel = PanelContainer.new()
	toast_panel.add_theme_stylebox_override("panel", UIKit.window(12))
	toast_panel.position = Vector2(30, TOP_H + 12)
	toast_panel.custom_minimum_size = Vector2(660, 0)
	toast_panel.size = Vector2(660, 0)
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.visible = false
	add_child(toast_panel)
	toast_label = UIKit.label("", 22, UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.custom_minimum_size = Vector2(630, 0)
	toast_panel.add_child(toast_label)


func _toast(text: String, kind: String = "info") -> void:
	if kind in ["event", "bad"]:
		SoundManager.play("notice")
	toast_queue.append([text, kind])
	if toast_queue.size() > 4:
		toast_queue.pop_front()
	if not toast_panel.visible:
		_next_toast()


func _next_toast() -> void:
	if toast_queue.is_empty():
		toast_panel.visible = false
		return
	var t: Array = toast_queue.pop_front()
	var col: Color = {"good": UIKit.GREEN, "bad": UIKit.RED, "event": UIKit.GOLD}.get(t[1], UIKit.TEXT)
	toast_label.text = t[0]
	toast_label.add_theme_color_override("font_color", col)
	toast_panel.size = Vector2(660, 0)
	toast_panel.visible = true
	toast_panel.modulate.a = 1.0
	toast_time = 3.2


func _modal_open() -> bool:
	return modal_layer.get_child_count() > 0


func _close_modal() -> void:
	for c in modal_layer.get_children():
		c.queue_free()
		modal_layer.remove_child(c)


func _show_modal(title: String, body: String, buttons: Array, extra: Control = null) -> void:
	## buttons: [[text, kind, callable], ...]; every button closes the popup first.
	_close_modal()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_layer.add_child(dim)
	var card := PanelContainer.new()
	var sb := UIKit.window(16)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 24
	sb.content_margin_bottom = 26
	card.add_theme_stylebox_override("panel", sb)
	card.custom_minimum_size = Vector2(640, 0)
	dim.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	card.add_child(col)
	var t := UIKit.outlined(UIKit.label(title, 34, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER), 6)
	col.add_child(t)
	if body != "":
		var b := UIKit.label(body, 22, UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(580, 0)
		col.add_child(b)
	if extra != null:
		col.add_child(extra)
	if not buttons.is_empty():
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 14)
		col.add_child(row)
		for spec in buttons:
			var btn := Button.new()
			btn.text = spec[0]
			btn.custom_minimum_size = Vector2(180 if buttons.size() > 2 else 230, 68)
			UIKit.style_button(btn, spec[1], 24, 12)
			var cb: Callable = spec[2]
			btn.pressed.connect(func():
				SoundManager.play("click")
				_close_modal()
				cb.call())
			row.add_child(btn)
	# center once the card knows its size
	card.position = Vector2((W - 640) / 2.0, 300)
	await get_tree().process_frame
	if is_instance_valid(card):
		card.position = Vector2((W - card.size.x) / 2.0, maxf(60.0, (H - card.size.y) / 2.0))


func _show_menu() -> void:
	if city == null:
		return
	SoundManager.play("click")
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	var tax_btn := Button.new()
	tax_btn.custom_minimum_size = Vector2(560, 64)
	UIKit.style_button(tax_btn, "secondary", 22, 12)
	var tax_text := func(): return "세금: %s  (낮음 = 수요↑ 수입↓, 높음 = 반대)" % Defs.TAX_NAMES[city.tax]
	tax_btn.text = tax_text.call()
	tax_btn.pressed.connect(func():
		SoundManager.play("click")
		city.tax = (city.tax + 1) % 3
		city.refresh()
		tax_btn.text = tax_text.call()
		_after_edit())
	box.add_child(tax_btn)
	var land_btn := Button.new()
	land_btn.custom_minimum_size = Vector2(560, 64)
	UIKit.style_button(land_btn, "secondary", 22, 12)
	land_btn.text = "지가 지도 보기" if map.overlay != "land" else "지가 지도 끄기"
	land_btn.pressed.connect(func():
		_set_tool(Tool.HAND)
		map.overlay = "land" if land_btn.text == "지가 지도 보기" else ""
		map.queue_redraw()
		_close_modal())
	box.add_child(land_btn)
	var snd := Button.new()
	snd.custom_minimum_size = Vector2(560, 64)
	UIKit.style_button(snd, "secondary", 22, 12)
	snd.text = "소리 켜기" if SoundManager.muted else "소리 끄기"
	snd.pressed.connect(func():
		SoundManager.muted = not SoundManager.muted
		meta["muted"] = SoundManager.muted
		_save_meta()
		snd.text = "소리 켜기" if SoundManager.muted else "소리 끄기")
	box.add_child(snd)
	_show_modal("메뉴", "", [["타이틀로", "secondary", _to_title], ["계속하기", "primary", func(): pass]], box)


func _to_title() -> void:
	if city != null and not city.finished:
		_save_game()
	city = null
	_show_title()


func _show_dex() -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	var found := 0
	for c in Defs.COMBOS:
		var known: bool = meta["dex"].has(c["key"])
		if known:
			found += 1
		var cell := PanelContainer.new()
		var here: bool = city != null and city.seen_combos.has(c["key"])
		cell.add_theme_stylebox_override("panel", UIKit.box(UIKit.WINDOW_HI if known else Color(0, 0, 0, 0.25), UIKit.GOLD if here else Color(1, 1, 1, 0.25), 8, 2))
		cell.custom_minimum_size = Vector2(284, 0)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		cell.add_child(v)
		v.add_child(UIKit.label(c["name"] if known else "???", 21, UIKit.GOLD if known else UIKit.MUTED))
		var parts: Array = []
		for k in c["parts"].size():
			parts.append(Defs.kind_name(c["parts"][k]) if known or k == 0 else "?")
		v.add_child(UIKit.label(" + ".join(parts), 17, UIKit.TEXT if known else UIKit.MUTED))
		grid.add_child(cell)
	_show_modal("콤보 도감 %d/%d" % [found, Defs.COMBOS.size()], "세 건물을 서로 3칸 안에 모으면 콤보! 지가와 수입이 올라요", [["닫기", "primary", func(): pass]], grid)


# ================================================================ city signals
func _on_built(cell: int) -> void:
	SoundManager.play("build")
	fx.burst(map.cell_center(cell), Color(1, 1, 1), 0.5)


func _on_burned(cell: int) -> void:
	map.fires[cell] = 2.5
	SoundManager.play("bulldoze")


func _on_shop_visit(cell: int) -> void:
	if VIEW.has_point(world.get_transform() * map.cell_center(cell)):
		fx.pop_text(map.cell_center(cell), "", UIKit.GOLD, true)
		SoundManager.play("coin")


func _on_combo_found(index: int, cells: Array) -> void:
	var c: Dictionary = Defs.COMBOS[index]
	var first: bool = not meta["dex"].has(c["key"])
	meta["dex"][c["key"]] = true
	_save_meta()
	SoundManager.play("combo")
	for cell in cells:
		fx.burst(map.cell_center(cell), UIKit.GOLD, 1.2)
	fx.pop_text(map.cell_center(cells[0]), "콤보! %s" % c["name"], UIKit.GOLD)
	_toast("콤보 '%s'!%s 지가·수입이 올라요" % [c["name"], " 도감에 새로 올렸어요." if first else ""], "good")


func _on_rank_up(r: int) -> void:
	SoundManager.play("rankup")
	var unlocks: Array = []
	for id in Defs.FAC_ORDER:
		if int(Defs.fac(id)["rank"]) == r:
			unlocks.append(Defs.fac(id)["name"])
	var size := Defs.rank_size(r)
	var body := "땅이 %d×%d로 넓어졌어요" % [size, size]
	if not unlocks.is_empty():
		body += "\n새 시설: " + ", ".join(unlocks)
	_show_modal("'%s'(으)로 성장했어요!" % Defs.RANKS[r]["name"], body, [["좋아요", "primary", func(): pass]])
	_after_edit()


func _on_month_passed(income: int, expense: int) -> void:
	var net := income - expense
	year_net += net
	fx.pop_text(world.get_transform().affine_inverse() * Vector2(150, TOP_H + 20), "%s%s" % ["+" if net >= 0 else "", UIKit.money(net)], UIKit.GREEN if net >= 0 else UIKit.RED)
	_save_game()


func _on_year_end(y: int) -> void:
	SoundManager.play("yearend")
	var pop_gain := city.pop - int(year_start.get("pop", 0))
	var net := year_net
	year_net = 0
	year_start = {"pop": city.pop, "money": city.money}
	var headline := "조용하지만 차분한 한 해였어요"
	if pop_gain >= 300:
		headline = "인구 %s명 증가! 도시가 쑥쑥 자라요" % UIKit.format_number(pop_gain)
	elif net >= 3000:
		headline = "흑자 %s! 살림이 넉넉해요" % UIKit.money(net)
	elif net < 0:
		headline = "올해 살림은 적자였어요. 세금이나 유지비를 살펴봐요"
	elif pop_gain > 0:
		headline = "새 주민 %s명이 이사 왔어요" % UIKit.format_number(pop_gain)
	var body := "「%s」\n인구 %s (%s%s)  ·  1년 수지 %s%s\n콤보 %d개  ·  행복 %d\n\n내년 정책을 하나 골라요" % [
		headline, UIKit.format_number(city.pop), "+" if pop_gain >= 0 else "", UIKit.format_number(pop_gain),
		"+" if net >= 0 else "", UIKit.money(net), city.combos.size(), city.happiness]
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	for p in city.policy_choices():
		var b := Button.new()
		b.custom_minimum_size = Vector2(186, 200)
		UIKit.style_button(b, "secondary", 19, 12)
		var v := VBoxContainer.new()
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_theme_constant_override("separation", 12)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(v)
		v.add_child(UIKit.outlined(UIKit.label(p["name"], 24, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER), 4))
		var desc := UIKit.label(p["text"], 18, UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(desc)
		var key: String = p["key"]
		b.pressed.connect(func():
			SoundManager.play("click")
			city.choose_policy(key)
			_close_modal()
			_toast("정책 '%s'을(를) 골랐어요" % p["name"], "good")
			_save_game()
			_after_edit())
		row.add_child(b)
	_show_modal("%d년차 결산" % y, body, [], row)


func _on_finished(score: int) -> void:
	SoundManager.play("rankup")
	var is_best := false
	if city.mode == "daily":
		var today := _today()
		if score > int(meta["best_daily"].get(today, 0)):
			meta["best_daily"][today] = score
			is_best = true
	if score > int(meta["best"]):
		meta["best"] = score
		is_best = true
	_save_meta()
	_delete_save()
	var lines: Array = []
	for p in city.score_parts():
		lines.append("%s %s → %s점" % [p[0], UIKit.format_number(p[1]), UIKit.format_number(p[2])])
	var body := "\n".join(lines) + "\n\n도시 점수 %s%s" % [UIKit.format_number(score), "  (최고 기록!)" if is_best else ""]
	var mode := city.mode
	_show_modal("%d년 완료!" % Defs.YEARS, body, [
		["구경하기", "secondary", func(): pass],
		["새 도시", "primary", func(): _start_game(mode)],
		["타이틀", "secondary", _to_title],
	])


# ================================================================ frame loop
func _process(delta: float) -> void:
	if toast_panel.visible:
		toast_time -= delta
		if toast_time < 0.4:
			toast_panel.modulate.a = maxf(0.0, toast_time / 0.4)
		if toast_time <= 0.0:
			_next_toast()
	if city == null or title_screen.visible:
		walkers.speed = 0.0
		return
	var running := not _modal_open() and not city.finished
	var spd: float = Defs.SPEEDS[speed_idx] if running else 0.0
	walkers.speed = spd if not city.finished else 1.0
	if spd <= 0.0:
		return
	week_timer += delta * spd
	var step := Defs.MONTH_SECONDS / Defs.WEEKS
	if week_timer >= step:
		week_timer -= step
		city.step_week()
		_after_edit()


func _after_edit() -> void:
	map.queue_redraw()
	walkers.city_changed()
	_update_hud()
	_update_context()


# ================================================================ camera
func _apply_camera() -> void:
	if city == null:
		return
	var a := city.active_rect()
	var lo := Vector2(a.position) * MapView.CELL
	var hi := Vector2(a.end) * MapView.CELL
	cam = cam.clamp(lo, hi)
	world.scale = Vector2(zoom, zoom)
	world.position = (VIEW.get_center() - cam * zoom).round()
	fx.queue_redraw()


func _screen_to_map(p: Vector2) -> Vector2:
	return (p - world.position) / zoom


func _screen_to_cell(p: Vector2) -> int:
	var m := _screen_to_map(p)
	var c := Vector2i(floori(m.x / MapView.CELL), floori(m.y / MapView.CELL))
	if not City.inside(c.x, c.y):
		return -1
	return City.idx(c.x, c.y)


func _zoom_at(screen: Vector2, new_zoom: float) -> void:
	var anchor := _screen_to_map(screen)
	zoom = clampf(new_zoom, MIN_ZOOM, MAX_ZOOM)
	cam = anchor - (screen - VIEW.get_center()) / zoom
	_apply_camera()


# ================================================================ input
func _unhandled_input(event: InputEvent) -> void:
	if city == null or title_screen.visible or _modal_open():
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed and VIEW.has_point(st.position):
			touches[st.index] = st.position
		elif not st.pressed:
			touches.erase(st.index)
		if touches.size() >= 2 and not multi_touch:
			_begin_pinch()
		elif touches.is_empty() and multi_touch:
			multi_touch = false
			_zoom_at(VIEW.get_center(), roundf(zoom))
		return
	if event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if touches.has(sd.index):
			touches[sd.index] = sd.position
			if multi_touch:
				_update_pinch()
		return
	if multi_touch:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			if VIEW.has_point(mb.position):
				_zoom_at(mb.position, roundf(zoom) + (1.0 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0))
		elif mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			panning = mb.pressed and VIEW.has_point(mb.position)
			pan_last = mb.position
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and VIEW.has_point(mb.position):
				_begin_stroke(mb.position)
			elif not mb.pressed and stroke_active:
				_end_stroke(mb.position)
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if panning:
			cam -= (mm.position - pan_last) / zoom
			pan_last = mm.position
			_apply_camera()
		elif stroke_active:
			_move_stroke(mm.position)
		elif tool == Tool.FAC and VIEW.has_point(mm.position):
			_set_ghost(_screen_to_cell(mm.position))


func _begin_pinch() -> void:
	_cancel_stroke()
	multi_touch = true
	var pts: Array = touches.values()
	pinch_dist = maxf(1.0, (pts[0] as Vector2).distance_to(pts[1]))
	pinch_zoom = zoom
	pinch_anchor = _screen_to_map(((pts[0] as Vector2) + pts[1]) * 0.5)


func _update_pinch() -> void:
	var pts: Array = touches.values()
	if pts.size() < 2:
		return
	var mid: Vector2 = ((pts[0] as Vector2) + pts[1]) * 0.5
	var d := maxf(1.0, (pts[0] as Vector2).distance_to(pts[1]))
	zoom = clampf(pinch_zoom * d / pinch_dist, MIN_ZOOM, MAX_ZOOM)
	cam = pinch_anchor - (mid - VIEW.get_center()) / zoom
	_apply_camera()


func _record(i: int) -> void:
	if not stroke_changes.has(i):
		stroke_changes[i] = city.cell_state(i)


func _begin_stroke(p: Vector2) -> void:
	stroke_active = true
	stroke_moved = false
	stroke_press = p
	stroke_changes = {}
	stroke_spent = 0
	stroke_failed = false
	pan_last = p
	var cell := _screen_to_cell(p)
	stroke_start = cell
	stroke_last = cell
	match tool:
		Tool.ROAD:
			_road_at(cell)
			map.queue_redraw()
		Tool.R, Tool.C, Tool.I, Tool.BULLDOZE:
			_rect_preview(cell)
		Tool.FAC:
			_set_ghost(cell)


func _move_stroke(p: Vector2) -> void:
	if p.distance_to(stroke_press) > 14.0:
		stroke_moved = true
	var cell := _screen_to_cell(p)
	match tool:
		Tool.HAND:
			cam -= (p - pan_last) / zoom
			pan_last = p
			_apply_camera()
		Tool.ROAD:
			if cell >= 0 and stroke_last >= 0 and cell != stroke_last:
				var a := City.pos(stroke_last)
				var b := City.pos(cell)
				while a != b:
					var d := b - a
					if absi(d.x) >= absi(d.y):
						a.x += signi(d.x)
					else:
						a.y += signi(d.y)
					_road_at(City.idx(a.x, a.y))
				stroke_last = cell
				map.queue_redraw()
				_update_hud()
		Tool.R, Tool.C, Tool.I, Tool.BULLDOZE:
			_rect_preview(cell)
		Tool.FAC:
			_set_ghost(cell)


func _end_stroke(p: Vector2) -> void:
	stroke_active = false
	match tool:
		Tool.HAND:
			if not stroke_moved:
				var cell := _screen_to_cell(p)
				map.selected = cell if cell >= 0 and map.selected != cell else -1
				SoundManager.play("click")
				_update_context()
				map.queue_redraw()
			return
		Tool.R, Tool.C, Tool.I, Tool.BULLDOZE:
			var z: int = [0, 0, Defs.Z.R, Defs.Z.C, Defs.Z.I, 0, 0][tool]
			for c in _rect_cells(stroke_start, stroke_last):
				if tool == Tool.BULLDOZE:
					if city.can_bulldoze(c):
						_record(c)
						var cost := city.bulldoze(c)
						if cost < 0:
							stroke_changes.erase(c)
							stroke_failed = true
						else:
							stroke_spent += cost
				elif city.zone_cost(c, z) >= 0:
					_record(c)
					var cost := city.place_zone(c, z)
					if cost < 0:
						stroke_changes.erase(c)
						stroke_failed = true
					else:
						stroke_spent += cost
			map.preview = {}
		Tool.FAC:
			var cell := map.ghost_cell
			if cell >= 0 and VIEW.has_point(p):
				if city.facility_cost(cell, fac_id) < 0:
					stroke_failed = true
				else:
					_record(cell)
					var cost := city.place_facility(cell, fac_id)
					if cost < 0:
						stroke_changes.erase(cell)
						stroke_failed = true
					else:
						stroke_spent += cost
	_finish_stroke()


func _finish_stroke() -> void:
	if not stroke_changes.is_empty():
		undo_op = {"changes": stroke_changes, "spent": stroke_spent, "month": city.month}
		city.refresh()
		SoundManager.play("bulldoze" if tool == Tool.BULLDOZE else "place")
		if stroke_spent > 0:
			fx.pop_text(_screen_to_map(stroke_press), "-" + UIKit.money(stroke_spent), UIKit.RED)
	elif stroke_failed or tool == Tool.FAC:
		SoundManager.play("invalid")
	if stroke_failed and city.money < 50:
		_toast("돈이 부족해요. 시간이 지나면 세금이 들어와요", "bad")
	stroke_changes = {}
	_after_edit()


func _cancel_stroke() -> void:
	if not stroke_active:
		return
	stroke_active = false
	for c in stroke_changes:
		city.set_cell_state(c, stroke_changes[c])
	city.money += stroke_spent
	stroke_changes = {}
	stroke_spent = 0
	map.preview = {}
	map.ghost_cell = -1
	city.refresh()
	_after_edit()


func _undo() -> void:
	if undo_op.is_empty() or undo_op["month"] != city.month:
		return
	SoundManager.play("click")
	var changes: Dictionary = undo_op["changes"]
	for c in changes:
		city.set_cell_state(c, changes[c])
	city.money += int(undo_op["spent"])
	undo_op = {}
	city.refresh()
	_after_edit()


func _road_at(cell: int) -> void:
	if cell < 0:
		return
	if city.road_cost(cell) < 0:
		if city.obj[cell] != Defs.ROAD:
			stroke_failed = true
		return
	_record(cell)
	var cost := city.place_road(cell)
	if cost < 0:
		stroke_changes.erase(cell)
		stroke_failed = true
	else:
		stroke_spent += cost


func _rect_cells(a: int, b: int) -> Array:
	if a < 0 or b < 0:
		return []
	var pa := City.pos(a)
	var pb := City.pos(b)
	pb.x = clampi(pb.x, pa.x - MAX_RECT + 1, pa.x + MAX_RECT - 1)
	pb.y = clampi(pb.y, pa.y - MAX_RECT + 1, pa.y + MAX_RECT - 1)
	var out: Array = []
	for y in range(mini(pa.y, pb.y), maxi(pa.y, pb.y) + 1):
		for x in range(mini(pa.x, pb.x), maxi(pa.x, pb.x) + 1):
			out.append(City.idx(x, y))
	return out


func _rect_preview(cell: int) -> void:
	if cell < 0:
		return
	stroke_last = cell
	var z: int = [0, 0, Defs.Z.R, Defs.Z.C, Defs.Z.I, 0, 0][tool]
	var pv := {}
	var total := 0
	for c in _rect_cells(stroke_start, cell):
		var ok := city.can_bulldoze(c) if tool == Tool.BULLDOZE else city.zone_cost(c, z) >= 0
		if tool != Tool.BULLDOZE and not ok and city.zone[c] == z:
			continue
		pv[c] = ok
		if ok and tool != Tool.BULLDOZE:
			total += city.zone_cost(c, z)
	map.preview = pv
	if tool != Tool.BULLDOZE:
		hint_label.text = "%d칸 · %s" % [pv.size(), UIKit.money(total)]
	map.queue_redraw()


func _set_ghost(cell: int) -> void:
	if cell < 0:
		return
	map.ghost_cell = cell
	map.ghost = Defs.fac(fac_id)["key"]
	map.ghost_radius = int(Defs.fac(fac_id)["radius"]) if fac_id in [2, 3, 7, 8, 9, 10] else 0
	map.preview = {cell: city.facility_cost(cell, fac_id) >= 0 and city.money >= city.facility_cost(cell, fac_id)}
	map.queue_redraw()
