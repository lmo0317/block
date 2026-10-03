class_name LeaderboardModal
extends ColorRect

signal closed

@onready var card: Panel = $Card
@onready var btn_close: Button = $Card/BtnClose
@onready var btn_tab_all: Button = $Card/TabBox/BtnTabAll
@onready var btn_tab_weekly: Button = $Card/TabBox/BtnTabWeekly
@onready var btn_tab_daily: Button = $Card/TabBox/BtnTabDaily
@onready var list_container: VBoxContainer = $Card/ScrollContainer/ListContainer
@onready var loading_label: Label = $Card/LoadingLabel

# Bottom Player Bar
@onready var my_rank_label: Label = $Card/BottomBox/MyRankLabel

# Nickname Edit Popup

var current_tab: String = "all" # "all", "weekly" or "daily"
var is_fetching: bool = false

# Colors & Styles
var font_res: Font = preload("res://assets/fonts/font.ttf")

func _ready() -> void:
	visible = false
	UIKit.style_modal_backdrop(self)
	UIKit.style_modal(card, $Card/Title, $Card/SubTitle)
	UIKit.style_close_button(btn_close)
	$Card/BottomBox.add_theme_stylebox_override("panel", UIKit.section(14))
	DragScroll.attach($Card/ScrollContainer)
	
	btn_close.pressed.connect(close)
	btn_tab_all.pressed.connect(func(): _switch_tab("all"))
	btn_tab_weekly.pressed.connect(func(): _switch_tab("weekly"))
	btn_tab_daily.pressed.connect(func(): _switch_tab("daily"))
	
	

func open(initial_tab: String = "") -> void:
	SoundManager.play_click()
	if not initial_tab.is_empty():
		current_tab = initial_tab
	visible = true
	modulate.a = 0.0
	
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.2)
	
	_update_tab_buttons()
	_update_bottom_info(null)
	_load_leaderboard()

func close() -> void:
	SoundManager.play_click()
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func():
		visible = false
		closed.emit()
	)

func _switch_tab(tab: String) -> void:
	if current_tab == tab:
		return
	SoundManager.play_click()
	current_tab = tab
	_update_tab_buttons()
	_load_leaderboard()

func _update_tab_buttons() -> void:
	var tabs = {"all": btn_tab_all, "weekly": btn_tab_weekly, "daily": btn_tab_daily}
	for key in tabs:
		var btn: Button = tabs[key]
		UIKit.style_button(btn, "primary" if current_tab == key else "ghost", UIKit.TYPE_BODY, 14)

func _load_leaderboard() -> void:
	if is_fetching:
		return
	is_fetching = true
	
	# Clear previous entries
	for child in list_container.get_children():
		child.queue_free()
		
	loading_label.visible = true
	loading_label.text = "랭킹 데이터를 불러오는 중..."
	
	LeaderboardManager.fetch_leaderboard(current_tab, 50, _on_leaderboard_loaded)

func _on_leaderboard_loaded(data: Dictionary) -> void:
	is_fetching = false
	loading_label.visible = false
	
	if not data.get("success", false):
		loading_label.visible = true
		loading_label.text = "네트워크 연결을 확인할 수 없습니다."
		return
		
	var list: Array = data.get("leaderboard", [])
	if list.is_empty():
		loading_label.visible = true
		loading_label.text = "아직 등록된 랭킹 기록이 없습니다.\n지금 첫 번째 랭커가 되어보세요!"
		return
		
	_populate_rows(list)
	
	var my_rank = data.get("my_rank", null)
	_update_bottom_info(my_rank)

func _populate_rows(list: Array) -> void:
	for child in list_container.get_children():
		child.queue_free()
		
	for item in list:
		var row = _create_row_entry(item)
		list_container.add_child(row)

func _create_row_entry(item: Dictionary) -> PanelContainer:
	var rank = int(item.get("rank", 999))
	var nickname = str(item.get("nickname", "플레이어"))
	var score_val = int(item.get("score", 0))
	var is_me = bool(item.get("is_me", false))
	
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.list_row("selected" if is_me else ("gold" if rank == 1 else "normal")))
	panel.custom_minimum_size = Vector2(0, 58)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.custom_minimum_size = Vector2(0, 58)
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)
	
	# 1. Rank Label
	var lbl_rank = Label.new()
	lbl_rank.custom_minimum_size = Vector2(70, 0)
	lbl_rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_rank.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_rank.add_theme_font_override("font", font_res)
	lbl_rank.add_theme_font_size_override("font_size", 22)
	
	if rank == 1:
		lbl_rank.text = "1위"
		lbl_rank.add_theme_color_override("font_color", Color(0.99, 0.82, 0.25))
	elif rank == 2:
		lbl_rank.text = "2위"
		lbl_rank.add_theme_color_override("font_color", Color(0.85, 0.90, 0.98))
	elif rank == 3:
		lbl_rank.text = "3위"
		lbl_rank.add_theme_color_override("font_color", Color(0.96, 0.62, 0.35))
	else:
		lbl_rank.text = "%d위" % rank
		lbl_rank.add_theme_color_override("font_color", Color(0.65, 0.72, 0.82))
	hbox.add_child(lbl_rank)
	
	# 2. Avatar Icon
	var av_id = int(item.get("avatar_id", 1))
	var av_tex = LeaderboardManager.get_avatar_texture(av_id)
	if av_tex:
		var tex_rect = TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(38, 38)
		tex_rect.texture = av_tex
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(tex_rect)
	
	# 3. Nickname Label
	var lbl_name = Label.new()
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_name.add_theme_font_override("font", font_res)
	lbl_name.add_theme_font_size_override("font_size", 20)
	lbl_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	
	if is_me:
		lbl_name.text = nickname + " (나)"
		lbl_name.add_theme_color_override("font_color", Color(0.30, 0.85, 1.0))
	else:
		lbl_name.text = nickname
		lbl_name.add_theme_color_override("font_color", Color(0.92, 0.95, 0.98))

	hbox.add_child(lbl_name)
	
	# 3. Score Label
	var lbl_score = Label.new()
	lbl_score.custom_minimum_size = Vector2(140, 0)
	lbl_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_score.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_score.add_theme_font_override("font", font_res)
	lbl_score.add_theme_font_size_override("font_size", 22)
	lbl_score.text = UIKit.format_number(score_val) + "점 "
	
	if rank == 1 or is_me:
		lbl_score.add_theme_color_override("font_color", Color(0.99, 0.82, 0.25))
	else:
		lbl_score.add_theme_color_override("font_color", Color(0.22, 0.74, 0.97))
	hbox.add_child(lbl_score)
	
	return panel

func _update_bottom_info(my_rank_data) -> void:
	var my_nick = LeaderboardManager.nickname
	if my_rank_data is Dictionary and my_rank_data.has("rank"):
		var r = int(my_rank_data["rank"])
		var s = int(my_rank_data.get("score", 0))
		var scope = {"all": "전체", "weekly": "주간", "daily": "오늘"}.get(current_tab, "전체")
		my_rank_label.text = "내 정보 · %s\n최고 %s점 · %s %d위" % [my_nick, UIKit.format_number(s), scope, r]
	elif current_tab == "daily":
		my_rank_label.text = "내 정보 · %s\n오늘의 챌린지에 도전해 순위를 등록하세요!" % my_nick
	elif LeaderboardManager.last_known_rank > 0:
		my_rank_label.text = "내 정보 · %s\n최고 %s점 · 최근 %d위" % [
			my_nick, 
			UIKit.format_number(LeaderboardManager.last_best_score),
			LeaderboardManager.last_known_rank
		]
	else:
		my_rank_label.text = "내 정보 · %s\n게임을 플레이해 순위를 등록하세요!" % my_nick
