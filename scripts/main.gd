class_name MainGame
extends Control

const SAVE_PATH: String = "user://block_blast_save.cfg"

# Tray slot positions in 720x1280 screen
const TRAY_SLOTS: Array[Vector2] = [
	Vector2(140, 1060),
	Vector2(360, 1060),
	Vector2(580, 1060)
]

var block_piece_scene: PackedScene = preload("res://scenes/block_piece.tscn")
var floating_text_scene: PackedScene = preload("res://scenes/floating_text.tscn")

var score: int = 0
var best_score: int = 0
var combo_count: int = 0
var is_game_over: bool = false
var new_best_achieved: bool = false

# Current 3 tray pieces (null if placed)
var tray_pieces: Array = [null, null, null]
var dragging_piece: BlockPiece = null
var drag_touch_id: int = -1

# Node references
@onready var board: Board = $Board
@onready var score_label: Label = $UI/Header/ScoreBox/ScoreValue
@onready var best_label: Label = $UI/Header/BestBox/BestValue
@onready var combo_banner: PanelContainer = $UI/ComboBanner
@onready var combo_label: Label = $UI/ComboBanner/ComboLabel
@onready var btn_sound: Button = $UI/Header/ButtonsBox/BtnSound
@onready var btn_restart: Button = $UI/Header/ButtonsBox/BtnRestart
@onready var btn_header_ranking: Button = $UI/Header/ButtonsBox/BtnRanking

# Game Over Dialog
@onready var game_over_panel: ColorRect = $UI/GameOverModal
@onready var go_final_score: Label = $UI/GameOverModal/Card/FinalScore
@onready var go_best_score: Label = $UI/GameOverModal/Card/BestScore
@onready var go_new_badge: Label = $UI/GameOverModal/Card/NewBestBadge
@onready var go_btn_retry: Button = $UI/GameOverModal/Card/BtnRetry
@onready var go_btn_ranking: Button = $UI/GameOverModal/Card/BtnGoRanking

# Start Screen
@onready var start_screen: ColorRect = $UI/StartScreen
@onready var start_btn_play: Button = $UI/StartScreen/Card/BtnPlay
@onready var start_btn_insta: Button = $UI/StartScreen/Card/ProfileBox/BtnInstaLogin
@onready var start_btn_logout: Button = $UI/StartScreen/Card/ProfileBox/BtnLogout
@onready var start_btn_ranking: Button = $UI/StartScreen/Card/BtnRanking
@onready var start_profile_title: Label = $UI/StartScreen/Card/ProfileBox/StatusLabel
@onready var start_profile_sub: Label = $UI/StartScreen/Card/ProfileBox/SubLabel

# Instagram Login Modal
@onready var insta_modal: ColorRect = $UI/InstaLoginModal
@onready var insta_input: LineEdit = $UI/InstaLoginModal/Card/InputHandle
@onready var insta_btn_confirm: Button = $UI/InstaLoginModal/Card/BtnConfirm
@onready var insta_btn_cancel: Button = $UI/InstaLoginModal/Card/BtnCancel
@onready var chip_1: Button = $UI/InstaLoginModal/Card/ChipsBox/Chip1
@onready var chip_2: Button = $UI/InstaLoginModal/Card/ChipsBox/Chip2
@onready var chip_3: Button = $UI/InstaLoginModal/Card/ChipsBox/Chip3

# Friends Ranking Modal
@onready var ranking_modal: ColorRect = $UI/RankingModal
@onready var ranking_list: VBoxContainer = $UI/RankingModal/Card/ScrollContainer/RankingList
@onready var ranking_input_friend: LineEdit = $UI/RankingModal/Card/AddFriendBox/InputFriend
@onready var ranking_btn_add: Button = $UI/RankingModal/Card/AddFriendBox/BtnAdd
@onready var ranking_btn_close: Button = $UI/RankingModal/Card/BtnClose

func _ready() -> void:
	randomize()
	AuthManager.init_auth()
	_load_best_score()
	_update_ui()
	_update_auth_ui()
	
	# Header & Game Over connections
	btn_sound.pressed.connect(_on_sound_toggled)
	btn_restart.pressed.connect(start_new_game)
	btn_header_ranking.pressed.connect(_open_ranking_modal)
	go_btn_retry.pressed.connect(start_new_game)
	go_btn_ranking.pressed.connect(_open_ranking_modal)
	board.lines_cleared.connect(_on_board_lines_cleared)
	
	# Start Screen connections
	start_btn_play.pressed.connect(_on_start_game_pressed)
	start_btn_insta.pressed.connect(_open_insta_login_modal)
	start_btn_logout.pressed.connect(_on_logout_pressed)
	start_btn_ranking.pressed.connect(_open_ranking_modal)
	
	# Instagram Login Modal connections
	insta_btn_confirm.pressed.connect(_on_insta_confirm)
	insta_btn_cancel.pressed.connect(func(): insta_modal.visible = false)
	chip_1.pressed.connect(func(): insta_input.text = "minoh_lee")
	chip_2.pressed.connect(func(): insta_input.text = "puzzle_king")
	chip_3.pressed.connect(func(): insta_input.text = "block_star_kr")
	
	# Ranking Modal connections
	ranking_btn_add.pressed.connect(_on_add_friend_pressed)
	ranking_btn_close.pressed.connect(func(): ranking_modal.visible = false)
	
	combo_banner.visible = false
	game_over_panel.visible = false
	insta_modal.visible = false
	ranking_modal.visible = false
	
	# Initial Start Screen is visible
	start_screen.visible = true

func _on_start_game_pressed() -> void:
	SoundManager.play_click()
	start_screen.visible = false
	start_new_game()

func start_new_game() -> void:
	SoundManager.play_click()
	
	score = 0
	combo_count = 0
	is_game_over = false
	new_best_achieved = false
	dragging_piece = null
	drag_touch_id = -1
	
	game_over_panel.visible = false
	combo_banner.visible = false
	start_screen.visible = false
	
	board.reset_board()
	_clear_tray()
	_update_ui()
	_spawn_new_tray()

func _clear_tray() -> void:
	for i in range(3):
		if tray_pieces[i] != null and is_instance_valid(tray_pieces[i]):
			tray_pieces[i].queue_free()
		tray_pieces[i] = null
	dragging_piece = null

func _spawn_new_tray() -> void:
	SoundManager.play_deal()
	var shapes: Array[Dictionary] = BlockData.get_balanced_trio()
	
	for i in range(3):
		var piece: BlockPiece = block_piece_scene.instantiate()
		add_child(piece)
		piece.setup(shapes[i], i, TRAY_SLOTS[i])
		tray_pieces[i] = piece
		
		# Pop in animation
		piece.scale = Vector2.ZERO
		var tw = create_tween()
		tw.tween_interval(i * 0.08)
		tw.tween_property(piece, "scale", Vector2.ONE * BlockPiece.TRAY_SCALE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	_check_piece_usability_and_game_over()

func _input(event: InputEvent) -> void:
	# If any modal is open, ignore board dragging
	if is_game_over or start_screen.visible or insta_modal.visible or ranking_modal.visible:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_pointer_down(event.position, -1)
			else:
				_on_pointer_up(event.position, -1)
				
	elif event is InputEventMouseMotion:
		if dragging_piece != null and drag_touch_id == -1:
			_on_pointer_move(event.position)
			
	elif event is InputEventScreenTouch:
		if event.pressed:
			_on_pointer_down(event.position, event.index)
		else:
			if event.index == drag_touch_id or drag_touch_id == -1:
				_on_pointer_up(event.position, event.index)
				
	elif event is InputEventScreenDrag:
		if dragging_piece != null and (event.index == drag_touch_id or drag_touch_id == -1):
			_on_pointer_move(event.position)

func _on_pointer_down(screen_pos: Vector2, touch_id: int) -> void:
	if dragging_piece != null:
		return
		
	var best_piece: BlockPiece = null
	var best_dist: float = 99999.0
	
	for piece in tray_pieces:
		if piece != null and is_instance_valid(piece):
			if piece.is_point_inside(screen_pos):
				var d = screen_pos.distance_to(piece.global_position)
				if d < best_dist:
					best_dist = d
					best_piece = piece
					
	if best_piece != null:
		dragging_piece = best_piece
		drag_touch_id = touch_id
		dragging_piece.start_drag(screen_pos)
		board.update_ghost_preview(dragging_piece.shape_data, dragging_piece)

func _on_pointer_move(screen_pos: Vector2) -> void:
	if dragging_piece == null or not is_instance_valid(dragging_piece):
		return
	dragging_piece.update_drag(screen_pos)
	board.update_ghost_preview(dragging_piece.shape_data, dragging_piece)

func _on_pointer_up(_screen_pos: Vector2, touch_id: int) -> void:
	if dragging_piece == null or not is_instance_valid(dragging_piece):
		return
	if touch_id != -1 and drag_touch_id != -1 and touch_id != drag_touch_id:
		return
		
	var piece = dragging_piece
	dragging_piece = null
	drag_touch_id = -1
	
	board.hide_ghost_preview()
	
	# Attempt placing on the board
	var success = board.place_piece(piece.shape_data, piece)
	if success:
		var slot_idx = piece.slot_index
		tray_pieces[slot_idx] = null
		
		var cell_count = piece.shape_data["cells"].size()
		_add_score(cell_count * 10)
		
		piece.snap_to_board()
		
		# Check lines
		var clear_info = board.check_and_clear_lines()
		var lines = clear_info["lines"]
		
		if lines > 0:
			combo_count += 1
			_process_line_clears(lines, clear_info["cells"], clear_info["center"])
		else:
			if combo_count > 0:
				combo_count = 0
				_hide_combo_banner()
		
		if _is_tray_empty():
			_spawn_new_tray()
		else:
			_check_piece_usability_and_game_over()
	else:
		piece.return_to_tray()

func _process_line_clears(lines: int, _cells: int, center_pos: Vector2) -> void:
	SoundManager.play_clear()
	SoundManager.play_combo(combo_count)
	
	var line_pts = 0
	match lines:
		1: line_pts = 100
		2: line_pts = 300
		3: line_pts = 600
		4: line_pts = 1000
		_: line_pts = 1500 + (lines - 4) * 500
		
	var combo_bonus = combo_count * 100
	var total_gain = line_pts + combo_bonus
	_add_score(total_gain)
	
	var praise_text = ""
	var praise_color = Color.WHITE
	
	if lines == 1:
		praise_text = "COOL! +%d" % total_gain
		praise_color = Color(0.22, 0.74, 0.97)
	elif lines == 2:
		praise_text = "GREAT!! +%d" % total_gain
		praise_color = Color(0.20, 0.83, 0.60)
	elif lines == 3:
		praise_text = "AMAZING!!! +%d" % total_gain
		praise_color = Color(0.99, 0.88, 0.28)
	else:
		praise_text = "UNBELIEVABLE!!!! +%d" % total_gain
		praise_color = Color(0.97, 0.44, 0.44)
		
	if combo_count > 1:
		praise_text = "COMBO x%d! 🔥\n+%d" % [combo_count, total_gain]
		praise_color = Color(0.98, 0.57, 0.24)
		_show_combo_banner(combo_count)
	
	_spawn_floating_text(praise_text, center_pos, praise_color, 1.2 if lines > 1 else 1.0)

func _show_combo_banner(c: int) -> void:
	combo_banner.visible = true
	combo_label.text = "COMBO x%d 🔥" % c
	combo_banner.scale = Vector2.ONE * 0.7
	var tw = create_tween()
	tw.tween_property(combo_banner, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _hide_combo_banner() -> void:
	if combo_banner.visible:
		var tw = create_tween()
		tw.tween_property(combo_banner, "scale", Vector2.ZERO, 0.15)
		tw.tween_callback(func(): combo_banner.visible = false)

func _spawn_floating_text(text: String, spawn_pos: Vector2, col: Color, scale_mult: float = 1.0) -> void:
	var ft: FloatingText = floating_text_scene.instantiate()
	ft.position = spawn_pos
	add_child(ft)
	ft.setup(text, col, scale_mult)

func _is_tray_empty() -> bool:
	for p in tray_pieces:
		if p != null and is_instance_valid(p):
			return false
	return true

func _check_piece_usability_and_game_over() -> void:
	var any_can_fit = false
	var remaining_pieces: int = 0
	
	for p in tray_pieces:
		if p != null and is_instance_valid(p):
			remaining_pieces += 1
			var fits = board.can_fit_shape(p.shape_data)
			p.set_dimmed(not fits)
			if fits:
				any_can_fit = true
				
	if remaining_pieces > 0 and not any_can_fit:
		_trigger_game_over()

func _trigger_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	
	SoundManager.play_gameover()
	AuthManager.update_my_score(best_score)
	
	await get_tree().create_timer(0.65).timeout
	
	go_final_score.text = "%s" % _format_number(score)
	go_best_score.text = "BEST: %s" % _format_number(best_score)
	go_new_badge.visible = new_best_achieved
	
	if new_best_achieved:
		SoundManager.play_record()
	
	game_over_panel.visible = true
	game_over_panel.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(game_over_panel, "modulate:a", 1.0, 0.25)

func _add_score(amount: int) -> void:
	score += amount
	if score > best_score:
		best_score = score
		new_best_achieved = true
		_save_best_score()
		AuthManager.update_my_score(best_score)
	_update_ui()
	
	score_label.scale = Vector2.ONE * 1.25
	var tw = create_tween()
	tw.tween_property(score_label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _update_ui() -> void:
	score_label.text = _format_number(score)
	best_label.text = _format_number(best_score)

func _update_auth_ui() -> void:
	if AuthManager.is_logged_in:
		start_profile_title.text = "🟢 인스타 연동됨: @%s" % AuthManager.username
		start_profile_sub.text = "친구 랭킹에 내 점수가 실시간 반영됩니다."
		start_btn_insta.text = "계정 변경 (Change)"
		start_btn_logout.visible = true
	else:
		start_profile_title.text = "📷 Instagram 계정 연동"
		start_profile_sub.text = "로그인하면 친구들과 점수를 겨룰 수 있습니다."
		start_btn_insta.text = "📷 인스타그램으로 로그인"
		start_btn_logout.visible = false

# ----------------- Instagram Login Modal -----------------
func _open_insta_login_modal() -> void:
	SoundManager.play_click()
	insta_modal.visible = true
	insta_input.text = AuthManager.username if AuthManager.is_logged_in else "minoh_lee"
	insta_input.grab_focus()

func _on_insta_confirm() -> void:
	SoundManager.play_record()
	var handle = insta_input.text.strip_edges()
	if handle.is_empty():
		handle = "instagram_user"
	AuthManager.login_with_instagram(handle)
	AuthManager.update_my_score(best_score)
	_update_auth_ui()
	insta_modal.visible = false

func _on_logout_pressed() -> void:
	SoundManager.play_click()
	AuthManager.logout()
	_update_auth_ui()

# ----------------- Friends Ranking Modal -----------------
func _open_ranking_modal() -> void:
	SoundManager.play_click()
	ranking_modal.visible = true
	_refresh_ranking_list()

func _on_add_friend_pressed() -> void:
	var handle = ranking_input_friend.text.strip_edges()
	if handle.is_empty():
		return
	SoundManager.play_place()
	AuthManager.add_friend(handle)
	ranking_input_friend.text = ""
	_refresh_ranking_list()

func _refresh_ranking_list() -> void:
	for child in ranking_list.get_children():
		ranking_list.remove_child(child)
		child.queue_free()
		
	var leaderboard = AuthManager.get_sorted_leaderboard(best_score)
	var font_res = load("res://assets/fonts/font.ttf")
	
	for i in range(leaderboard.size()):
		var entry = leaderboard[i]
		var rank = i + 1
		var is_me = entry.get("is_me", false)
		
		var row = PanelContainer.new()
		row.custom_minimum_size = Vector2(540, 54)
		
		# Styling for row
		var row_style = StyleBoxFlat.new()
		row_style.corner_radius_top_left = 10
		row_style.corner_radius_top_right = 10
		row_style.corner_radius_bottom_right = 10
		row_style.corner_radius_bottom_left = 10
		
		if is_me:
			row_style.bg_color = Color(0.12, 0.22, 0.38, 0.95)
			row_style.border_width_left = 2
			row_style.border_width_top = 2
			row_style.border_width_right = 2
			row_style.border_width_bottom = 2
			row_style.border_color = Color(0.22, 0.74, 0.97, 1.0)
		else:
			row_style.bg_color = Color(0.08, 0.11, 0.18, 0.85)
			row_style.border_width_bottom = 1
			row_style.border_color = Color(0.15, 0.20, 0.30, 0.7)
			
		row.add_theme_stylebox_override("panel", row_style)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)
		
		# 1. Rank medal or number
		var rank_lbl = Label.new()
		rank_lbl.custom_minimum_size = Vector2(48, 48)
		rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		rank_lbl.add_theme_font_override("font", font_res)
		rank_lbl.add_theme_font_size_override("font_size", 22)
		
		match rank:
			1:
				rank_lbl.text = "🥇"
				rank_lbl.add_theme_color_override("font_color", Color(1, 0.84, 0))
			2:
				rank_lbl.text = "🥈"
				rank_lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92))
			3:
				rank_lbl.text = "🥉"
				rank_lbl.add_theme_color_override("font_color", Color(0.85, 0.55, 0.35))
			_:
				rank_lbl.text = "#%d" % rank
				rank_lbl.add_theme_color_override("font_color", Color(0.55, 0.62, 0.75))
		hbox.add_child(rank_lbl)
		
		# 2. Instagram camera icon / avatar dot
		var insta_icon = TextureRect.new()
		insta_icon.texture = load("res://assets/sprites/instagram_icon.png")
		insta_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		insta_icon.custom_minimum_size = Vector2(34, 34)
		insta_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(insta_icon)
		
		# 3. User display info
		var info_box = VBoxContainer.new()
		info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_box.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var name_lbl = Label.new()
		var dname = entry.get("display_name", "")
		if is_me and not dname.ends_with("(나)"):
			dname += " (나)"
		name_lbl.text = dname
		name_lbl.add_theme_font_override("font", font_res)
		name_lbl.add_theme_font_size_override("font_size", 18)
		if is_me:
			name_lbl.add_theme_color_override("font_color", Color(0.38, 0.85, 1.0))
		else:
			name_lbl.add_theme_color_override("font_color", Color(0.92, 0.95, 0.98))
		info_box.add_child(name_lbl)
		
		var handle_lbl = Label.new()
		handle_lbl.text = "@" + entry.get("username", "")
		handle_lbl.add_theme_font_override("font", font_res)
		handle_lbl.add_theme_font_size_override("font_size", 13)
		handle_lbl.add_theme_color_override("font_color", Color(0.5, 0.58, 0.7))
		info_box.add_child(handle_lbl)
		
		hbox.add_child(info_box)
		
		# 4. Score
		var score_val = Label.new()
		score_val.text = "%s점" % _format_number(entry.get("score", 0))
		score_val.add_theme_font_override("font", font_res)
		score_val.add_theme_font_size_override("font_size", 22)
		score_val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if rank == 1:
			score_val.add_theme_color_override("font_color", Color(1, 0.82, 0.25))
		elif is_me:
			score_val.add_theme_color_override("font_color", Color(0.22, 0.74, 0.97))
		else:
			score_val.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
		hbox.add_child(score_val)
		
		row.add_child(hbox)
		ranking_list.add_child(row)

func _on_sound_toggled() -> void:
	SoundManager.play_click()
	var muted = SoundManager.toggle_mute()
	btn_sound.text = "🔇" if muted else "🔊"

func _on_board_lines_cleared(_lines: int, _cells: int, _center: Vector2) -> void:
	pass

func _load_best_score() -> void:
	var cfg = ConfigFile.new()
	var err = cfg.load(SAVE_PATH)
	if err == OK:
		best_score = cfg.get_value("game", "best_score", 0)

func _save_best_score() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("game", "best_score", best_score)
	cfg.save(SAVE_PATH)

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
