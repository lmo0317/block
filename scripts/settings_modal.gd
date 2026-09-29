class_name SettingsModal
extends ColorRect

signal closed
signal request_profile_setup

@onready var card: Panel = $Card
@onready var btn_close: Button = $Card/BtnClose
@onready var preview_avatar: TextureRect = $Card/ScrollContainer/Content/ProfileBox/Margin/VBox/PreviewBox/PreviewAvatar
@onready var avatar_grid: GridContainer = $Card/ScrollContainer/Content/ProfileBox/Margin/VBox/AvatarGrid
@onready var input_nick: LineEdit = $Card/ScrollContainer/Content/ProfileBox/Margin/VBox/NickEdit
@onready var btn_save_nick: Button = $Card/ScrollContainer/Content/ProfileBox/Margin/VBox/BtnSaveProfile
@onready var nick_status: Label = $Card/ScrollContainer/Content/ProfileBox/Margin/VBox/StatusLabel

# Game Settings Toggles
@onready var btn_sound: Button = $Card/ScrollContainer/Content/OptionsBox/Margin/VBox/BtnSound
@onready var btn_shake: Button = $Card/ScrollContainer/Content/OptionsBox/Margin/VBox/BtnShake
@onready var btn_ghost: Button = $Card/ScrollContainer/Content/OptionsBox/Margin/VBox/BtnGhost
@onready var btn_vibration: Button = $Card/ScrollContainer/Content/OptionsBox/Margin/VBox/BtnVibration

# Account & Close
@onready var btn_reset_profile: Button = $Card/ScrollContainer/Content/AccountBox/Margin/VBox/BtnResetProfile
@onready var btn_close_bottom: Button = $Card/BtnCloseBottom
@onready var content_box: VBoxContainer = $Card/ScrollContainer/Content
@onready var account_box: PanelContainer = $Card/ScrollContainer/Content/AccountBox
@onready var account_sec_title: Label = $Card/ScrollContainer/Content/AccountBox/Margin/VBox/SecTitle

var font_res: Font = preload("res://assets/fonts/font.ttf")
var achievement_summary: Label
var achievement_list: VBoxContainer
var title_option: OptionButton
var skin_buttons: Dictionary = {} # skin id -> Button

var selected_avatar_id: int = 1
var avatar_buttons: Array[Button] = []

func _ready() -> void:
	visible = false
	input_nick.max_length = LeaderboardManager.MAX_NICKNAME_LENGTH
	_setup_avatar_grid()
	
	btn_close.pressed.connect(close)
	btn_close_bottom.pressed.connect(close)
	btn_save_nick.pressed.connect(_on_save_profile_pressed)
	input_nick.text_submitted.connect(func(_t): _on_save_profile_pressed())
	
	btn_sound.pressed.connect(_on_sound_toggled)
	btn_shake.pressed.connect(_on_shake_toggled)
	btn_ghost.pressed.connect(_on_ghost_toggled)
	btn_vibration.pressed.connect(_on_vibration_toggled)
	
	btn_reset_profile.pressed.connect(_on_reset_profile_pressed)
	_build_achievement_box()
	_build_skin_picker()
	UIKit.style_modal(card, $Card/Title, $Card/Subtitle)
	UIKit.style_close_button(btn_close)
	UIKit.style_button(btn_close_bottom, "secondary", 20, 16)
	UIKit.style_button(btn_save_nick, "primary", 18, 14)
	UIKit.style_button(btn_reset_profile, "danger", 16, 14)

func _setup_avatar_grid() -> void:
	for child in avatar_grid.get_children():
		child.queue_free()
	avatar_buttons.clear()
	
	for i in range(1, 9):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(52, 52)
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.expand_icon = true
		
		var tex = LeaderboardManager.get_avatar_texture(i)
		if tex:
			btn.icon = tex
			
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.16, 0.25, 0.9)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.25, 0.35, 0.5, 0.8)
		btn.add_theme_stylebox_override("normal", style)
		
		var avatar_index = i
		btn.pressed.connect(func(): _select_avatar(avatar_index))
		
		avatar_grid.add_child(btn)
		avatar_buttons.append(btn)

func open() -> void:
	SoundManager.play_click()
	visible = true
	modulate.a = 0.0
	
	selected_avatar_id = LeaderboardManager.avatar_id
	input_nick.text = LeaderboardManager.nickname
	nick_status.text = ""
	
	_select_avatar(selected_avatar_id)
	_update_toggle_buttons()
	_refresh_achievements()
	
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.2)

func close() -> void:
	SoundManager.play_click()
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func():
		visible = false
		closed.emit()
	)

func _select_avatar(id: int) -> void:
	selected_avatar_id = id
	preview_avatar.texture = LeaderboardManager.get_avatar_texture(selected_avatar_id)
	
	for i in range(avatar_buttons.size()):
		var btn = avatar_buttons[i]
		var idx = i + 1
		var style = btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		if idx == selected_avatar_id:
			style.border_color = Color(0.22, 0.85, 1.0, 1.0)
			style.border_width_left = 3
			style.border_width_top = 3
			style.border_width_right = 3
			style.border_width_bottom = 3
			style.bg_color = Color(0.18, 0.28, 0.45, 0.95)
		else:
			style.border_color = Color(0.25, 0.35, 0.5, 0.6)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			style.bg_color = Color(0.12, 0.16, 0.25, 0.9)
		btn.add_theme_stylebox_override("normal", style)

func _on_save_profile_pressed() -> void:
	var nick = input_nick.text.strip_edges()
	if nick.is_empty():
		nick_status.text = "닉네임을 한 글자 이상 입력해 주세요."
		return
	if nick.length() > LeaderboardManager.MAX_NICKNAME_LENGTH:
		nick = nick.substr(0, LeaderboardManager.MAX_NICKNAME_LENGTH)
		
	nick_status.text = "저장 중..."
	SoundManager.play_click()
	
	LeaderboardManager.update_profile(nick, selected_avatar_id, func(ok: bool):
		if ok:
			nick_status.text = "프로필이 성공적으로 저장되었습니다."
		else:
			nick_status.text = "저장 완료 (로컬 저장됨)"
	)

func _update_toggle_buttons() -> void:
	_style_toggle_btn(btn_sound, "효과음", SettingsManager.sound_enabled)
	_style_toggle_btn(btn_shake, "화면 흔들림", SettingsManager.screen_shake_enabled)
	_style_toggle_btn(btn_ghost, "놓을 자리 미리보기", SettingsManager.ghost_piece_enabled)
	_style_toggle_btn(btn_vibration, "진동 (모바일)", SettingsManager.vibration_enabled)
	_update_skin_buttons()

func _style_toggle_btn(btn: Button, title: String, enabled: bool) -> void:
	# Setting row: name on the left, on/off pill on the right
	btn.text = title
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	UIKit.style_button(btn, "secondary", 18, 14)
	var state: Label = btn.get_node_or_null("State")
	if state == null:
		state = UIKit.label("", 16, UIKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		state.name = "State"
		state.anchor_left = 1.0
		state.anchor_right = 1.0
		state.anchor_bottom = 1.0
		state.offset_left = -92
		state.offset_right = -12
		state.offset_top = 9
		state.offset_bottom = -9
		btn.add_child(state)
	state.text = "켜짐" if enabled else "꺼짐"
	state.add_theme_color_override("font_color", UIKit.TEXT if enabled else UIKit.MUTED)
	state.add_theme_stylebox_override("normal", UIKit.box(UIKit.ACCENT if enabled else UIKit.SURFACE, UIKit.BORDER, 12, 0 if enabled else 2))

func _on_sound_toggled() -> void:
	SettingsManager.set_sound(not SettingsManager.sound_enabled)
	SoundManager.play_click()
	_update_toggle_buttons()

func _on_shake_toggled() -> void:
	SettingsManager.set_shake(not SettingsManager.screen_shake_enabled)
	SoundManager.play_click()
	_update_toggle_buttons()

func _on_ghost_toggled() -> void:
	SettingsManager.set_ghost(not SettingsManager.ghost_piece_enabled)
	SoundManager.play_click()
	_update_toggle_buttons()

func _on_vibration_toggled() -> void:
	SettingsManager.set_vibration(not SettingsManager.vibration_enabled)
	SoundManager.play_click()
	SettingsManager.vibrate(30)
	_update_toggle_buttons()

func _build_skin_picker() -> void:
	# Row of skin buttons (preview block + name) under the option toggles
	var options_vbox: VBoxContainer = btn_vibration.get_parent()
	options_vbox.add_child(_small_label("블록 스킨", 16, Color(0.92, 0.95, 0.98)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for s in BlockSkins.SKINS:
		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 92)
		btn.icon = BlockSkins.texture("blue", s["id"])
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		btn.text = s["name"]
		btn.add_theme_font_override("font", font_res)
		btn.add_theme_font_size_override("font_size", 15)
		btn.add_theme_constant_override("icon_max_width", 44)
		var skin_id: String = s["id"]
		btn.pressed.connect(func(): _on_skin_pressed(skin_id))
		row.add_child(btn)
		skin_buttons[skin_id] = btn
	options_vbox.add_child(row)

func _update_skin_buttons() -> void:
	for skin_id in skin_buttons:
		var btn: Button = skin_buttons[skin_id]
		var selected: bool = skin_id == SettingsManager.block_skin
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.14, 0.24, 0.42, 0.95) if selected else Color(0.12, 0.16, 0.25, 0.9)
		sb.border_color = Color(0.22, 0.85, 1.0, 1.0) if selected else Color(0.25, 0.35, 0.5, 0.6)
		sb.set_border_width_all(3 if selected else 2)
		sb.set_corner_radius_all(12)
		sb.content_margin_top = 8
		sb.content_margin_bottom = 6
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)

func _on_skin_pressed(skin_id: String) -> void:
	SoundManager.play_click()
	SettingsManager.set_skin(skin_id)
	_update_skin_buttons()

func _build_achievement_box() -> void:
	# Achievements list and representative title picker, placed above the account section
	var box := PanelContainer.new()
	box.name = "AchievementBox"
	box.add_theme_stylebox_override("panel", account_box.get_theme_stylebox("panel"))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	box.add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	margin.add_child(v)

	var sec := Label.new()
	sec.text = "업적 및 칭호"
	sec.label_settings = account_sec_title.label_settings
	v.add_child(sec)

	achievement_summary = _small_label("", 15, Color(0.65, 0.72, 0.82))
	v.add_child(achievement_summary)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(_small_label("대표 칭호", 16, Color(0.92, 0.95, 0.98)))
	title_option = OptionButton.new()
	title_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_option.custom_minimum_size = Vector2(0, 40)
	title_option.add_theme_font_override("font", font_res)
	title_option.add_theme_font_size_override("font_size", 16)
	title_option.item_selected.connect(_on_title_selected)
	row.add_child(title_option)
	v.add_child(row)

	achievement_list = VBoxContainer.new()
	achievement_list.add_theme_constant_override("separation", 4)
	v.add_child(achievement_list)

	content_box.add_child(box)
	content_box.move_child(box, account_box.get_index())

func _refresh_achievements() -> void:
	var defs: Array[Dictionary] = Achievements.DEFS
	var done := 0
	for child in achievement_list.get_children():
		child.queue_free()
	for d in defs:
		var got: bool = Achievements.is_unlocked(d["id"])
		if got:
			done += 1
		var text := "%s · %s" % [d["title"], d["desc"]]
		if not got:
			text += "  (%d/%d)" % [mini(Achievements.get_stat(d["stat"]), int(d["target"])), int(d["target"])]
		var col := Color(0.99, 0.82, 0.35) if got else Color(0.5, 0.56, 0.66)
		var l := _small_label(text, 14, col)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		achievement_list.add_child(l)
	achievement_summary.text = "달성 %d / %d" % [done, defs.size()]

	title_option.clear()
	title_option.add_item("칭호 없음")
	var selected := 0
	for t in Achievements.unlocked_titles():
		title_option.add_item(t)
		if t == LeaderboardManager.title:
			selected = title_option.item_count - 1
	title_option.select(selected)

func _on_title_selected(index: int) -> void:
	SoundManager.play_click()
	LeaderboardManager.set_title("" if index == 0 else title_option.get_item_text(index))

func _small_label(text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font_res)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func _on_reset_profile_pressed() -> void:
	SoundManager.play_click()
	LeaderboardManager.reset_profile()
	close()
	request_profile_setup.emit()
