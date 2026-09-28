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

# Account & Close
@onready var btn_reset_profile: Button = $Card/ScrollContainer/Content/AccountBox/Margin/VBox/BtnResetProfile
@onready var btn_close_bottom: Button = $Card/BtnCloseBottom

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
	
	btn_reset_profile.pressed.connect(_on_reset_profile_pressed)

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
	_style_toggle_btn(btn_sound, "사운드 효과", SettingsManager.sound_enabled)
	_style_toggle_btn(btn_shake, "화면 진동 효과", SettingsManager.screen_shake_enabled)
	_style_toggle_btn(btn_ghost, "블록 가이드라인", SettingsManager.ghost_piece_enabled)

func _style_toggle_btn(btn: Button, title: String, enabled: bool) -> void:
	btn.text = "%s: %s" % [title, "ON" if enabled else "OFF"]
	var style = btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	if enabled:
		style.bg_color = Color(0.14, 0.48, 0.95, 0.9)
		style.border_color = Color(0.4, 0.75, 1.0, 0.9)
	else:
		style.bg_color = Color(0.14, 0.18, 0.26, 0.9)
		style.border_color = Color(0.3, 0.38, 0.5, 0.6)
	btn.add_theme_stylebox_override("normal", style)

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

func _on_reset_profile_pressed() -> void:
	SoundManager.play_click()
	LeaderboardManager.reset_profile()
	close()
	request_profile_setup.emit()
