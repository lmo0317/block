class_name ProfileSetupModal
extends ColorRect

signal setup_completed

@onready var card: Panel = $Card
@onready var preview_avatar: TextureRect = $Card/AvatarSection/PreviewBox/PreviewAvatar
@onready var avatar_grid: GridContainer = $Card/AvatarSection/AvatarGrid
@onready var input_nick: LineEdit = $Card/NickSection/NickEdit
@onready var chip_1: Button = $Card/NickSection/Chips/Chip1
@onready var chip_2: Button = $Card/NickSection/Chips/Chip2
@onready var chip_3: Button = $Card/NickSection/Chips/Chip3
@onready var btn_random: Button = $Card/NickSection/Chips/BtnRandom
@onready var btn_confirm: Button = $Card/BtnConfirm
@onready var status_label: Label = $Card/StatusLabel

var selected_avatar_id: int = 1
var avatar_buttons: Array[Button] = []

func _ready() -> void:
	visible = false
	UIKit.style_modal(card, $Card/Title, $Card/Subtitle)
	UIKit.style_avatar_frame($Card/AvatarSection/PreviewBox/PreviewFrame)
	UIKit.style_button(btn_confirm, "primary", 26, 18)
	for chip in [chip_1, chip_2, chip_3, btn_random]:
		UIKit.style_button(chip, "secondary", 15, 12)
	input_nick.max_length = LeaderboardManager.MAX_NICKNAME_LENGTH
	_setup_avatar_grid()
	
	chip_1.pressed.connect(func(): input_nick.text = "블록마스터")
	chip_2.pressed.connect(func(): input_nick.text = "퍼즐킹")
	chip_3.pressed.connect(func(): input_nick.text = "럭키블록")
	btn_random.pressed.connect(_pick_random_nick)
	
	btn_confirm.pressed.connect(_on_confirm_pressed)
	input_nick.text_submitted.connect(func(_t): _on_confirm_pressed())

func _setup_avatar_grid() -> void:
	# Clear existing children if any
	for child in avatar_grid.get_children():
		child.queue_free()
	avatar_buttons.clear()
	
	for i in range(1, 9):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(56, 56)
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.expand_icon = true
		
		var tex = LeaderboardManager.get_avatar_texture(i)
		if tex:
			btn.icon = tex
			
		UIKit.style_avatar_button(btn, false)
		
		var avatar_index = i
		btn.pressed.connect(func(): _select_avatar(avatar_index))
		
		avatar_grid.add_child(btn)
		avatar_buttons.append(btn)

func open() -> void:
	SoundManager.play_click()
	visible = true
	modulate.a = 0.0
	
	selected_avatar_id = LeaderboardManager.avatar_id
	if selected_avatar_id < 1 or selected_avatar_id > 8:
		selected_avatar_id = randi_range(1, 8)
		
	var cur_name = LeaderboardManager.nickname
	if cur_name.is_empty() or cur_name.begins_with("usr_"):
		cur_name = "블록마스터"
	input_nick.text = cur_name
	status_label.text = ""
	
	_select_avatar(selected_avatar_id)
	
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.2)
	input_nick.grab_focus()

func close() -> void:
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func():
		visible = false
		setup_completed.emit()
	)

func _select_avatar(id: int) -> void:
	selected_avatar_id = id
	SoundManager.play_click()
	
	# Update preview
	preview_avatar.texture = LeaderboardManager.get_avatar_texture(selected_avatar_id)
	
	# Update button visual borders
	for i in range(avatar_buttons.size()):
		var btn = avatar_buttons[i]
		var idx = i + 1
		UIKit.style_avatar_button(btn, idx == selected_avatar_id)

func _pick_random_nick() -> void:
	SoundManager.play_click()
	var words1 = ["빛나는", "럭키", "스피드", "슈퍼", "황금", "천재", "매직"]
	var words2 = ["블록커", "퍼즐러", "마스터", "플레이어", "챔피언", "빌더"]
	input_nick.text = words1[randi() % words1.size()] + words2[randi() % words2.size()]

func _on_confirm_pressed() -> void:
	var nick = input_nick.text.strip_edges()
	if nick.is_empty():
		status_label.text = "닉네임을 한 글자 이상 입력해 주세요."
		return
	if nick.length() > LeaderboardManager.MAX_NICKNAME_LENGTH:
		nick = nick.substr(0, LeaderboardManager.MAX_NICKNAME_LENGTH)
		
	status_label.text = "프로필 저장 중..."
	SoundManager.play_record()
	
	LeaderboardManager.update_profile(nick, selected_avatar_id, func(_ok: bool):
		close()
	)
