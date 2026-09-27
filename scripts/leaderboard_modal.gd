class_name LeaderboardModal
extends ColorRect

signal closed

@onready var card: Panel = $Card
@onready var btn_close: Button = $Card/BtnClose
@onready var btn_tab_all: Button = $Card/TabBox/BtnTabAll
@onready var btn_tab_weekly: Button = $Card/TabBox/BtnTabWeekly
@onready var list_container: VBoxContainer = $Card/ScrollContainer/ListContainer
@onready var loading_label: Label = $Card/LoadingLabel

# Bottom Player Bar
@onready var my_rank_label: Label = $Card/BottomBox/MyRankLabel
@onready var btn_edit_name: Button = $Card/BottomBox/BtnEditName

# Nickname Edit Popup
@onready var nick_modal: ColorRect = $NickModal
@onready var nick_edit: LineEdit = $NickModal/Card/NickEdit
@onready var btn_nick_confirm: Button = $NickModal/Card/HBox/BtnConfirm
@onready var btn_nick_cancel: Button = $NickModal/Card/HBox/BtnCancel
@onready var nick_status_label: Label = $NickModal/Card/StatusLabel

var current_tab: String = "all" # "all" or "weekly"
var is_fetching: bool = false

# Colors & Styles
var font_res: Font = preload("res://assets/fonts/font.ttf")

func _ready() -> void:
	visible = false
	nick_modal.visible = false
	
	btn_close.pressed.connect(close)
	btn_tab_all.pressed.connect(func(): _switch_tab("all"))
	btn_tab_weekly.pressed.connect(func(): _switch_tab("weekly"))
	
	btn_edit_name.pressed.connect(_open_nick_modal)
	btn_nick_confirm.pressed.connect(_submit_new_nick)
	btn_nick_cancel.pressed.connect(func(): nick_modal.visible = false)
	
	nick_edit.text_submitted.connect(func(_text): _submit_new_nick())

func open() -> void:
	SoundManager.play_click()
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
	var active_color = Color(0.14, 0.48, 0.95)
	var inactive_color = Color(0.12, 0.16, 0.24)
	
	var style_all = btn_tab_all.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	style_all.bg_color = active_color if current_tab == "all" else inactive_color
	btn_tab_all.add_theme_stylebox_override("normal", style_all)
	btn_tab_all.modulate = Color(1, 1, 1, 1) if current_tab == "all" else Color(0.7, 0.7, 0.7, 1)
	
	var style_weekly = btn_tab_weekly.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	style_weekly.bg_color = active_color if current_tab == "weekly" else inactive_color
	btn_tab_weekly.add_theme_stylebox_override("normal", style_weekly)
	btn_tab_weekly.modulate = Color(1, 1, 1, 1) if current_tab == "weekly" else Color(0.7, 0.7, 0.7, 1)

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
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	
	if is_me:
		style.bg_color = Color(0.12, 0.28, 0.45, 0.95)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.22, 0.74, 0.97, 0.9)
	elif rank == 1:
		style.bg_color = Color(0.22, 0.18, 0.08, 0.85)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.99, 0.82, 0.25, 0.6)
	elif rank % 2 == 0:
		style.bg_color = Color(0.08, 0.11, 0.18, 0.7)
	else:
		style.bg_color = Color(0.06, 0.08, 0.14, 0.7)
		
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(0, 52)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.custom_minimum_size = Vector2(0, 52)
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
		tex_rect.custom_minimum_size = Vector2(36, 36)
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
	lbl_score.text = _format_number(score_val) + "점 "
	
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
		my_rank_label.text = "내 정보: %s  |  최고 점수: %s점 (전체 %d위)" % [my_nick, _format_number(s), r]
	elif LeaderboardManager.last_known_rank > 0:
		my_rank_label.text = "내 정보: %s  |  최고 점수: %s점 (최근 %d위)" % [
			my_nick, 
			_format_number(LeaderboardManager.last_best_score), 
			LeaderboardManager.last_known_rank
		]
	else:
		my_rank_label.text = "내 정보: %s  |  게임을 플레이하여 순위를 등록하세요!" % my_nick

func _open_nick_modal() -> void:
	SoundManager.play_click()
	nick_edit.text = LeaderboardManager.nickname
	nick_status_label.text = ""
	nick_modal.visible = true
	nick_edit.grab_focus()

func _submit_new_nick() -> void:
	var new_name = nick_edit.text.strip_edges()
	if new_name.is_empty():
		nick_status_label.text = "닉네임을 한 글자 이상 입력해 주세요."
		return
	if new_name.length() > 12:
		new_name = new_name.substr(0, 12)
		
	nick_status_label.text = "저장 중..."
	SoundManager.play_click()
	
	LeaderboardManager.update_nickname(new_name, func(ok: bool):
		if ok:
			nick_modal.visible = false
			_update_bottom_info(null)
			_load_leaderboard()
		else:
			nick_status_label.text = "변경 실패. 잠시 후 다시 시도해 주세요."
	)

func _format_number(n: int) -> String:
	var s = str(n)
	var res = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = "," + res
	return res
