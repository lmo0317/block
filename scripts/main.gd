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
var sound_on_tex: Texture2D = preload("res://assets/sprites/sound_on.png")
var sound_off_tex: Texture2D = preload("res://assets/sprites/sound_off.png")

var score: int = 0
var best_score: int = 0
var combo_count: int = 0
const MAX_COMBO_GRACE: int = 3
# Perfect clear bonus before the combo multiplier (see GAME_DESIGN.md ch.9)
const PERFECT_CLEAR_BASE: int = 300
var combo_grace_moves: int = 0
var is_game_over: bool = false
var new_best_achieved: bool = false
var has_revived_this_game: bool = false

# Game mode: "classic" (adaptive endless), "daily" (same seeded sequence for everyone)
# or "adventure" (stage with a start board, goal and move limit)
var game_mode: String = "classic"
var challenge_day: String = ""
var challenge_rng: RandomNumberGenerator = null
var daily_best: int = 0
var stage: Dictionary = {}
var stage_progress: int = 0
var adventure_select: AdventureSelect
# Classic game-over texts, restored after the modal is reused for stage results
var go_default_texts: Dictionary = {}

# Per-game stats for analytics
var game_id: String = ""
var game_start_msec: int = 0
var last_game_over_msec: int = -1
var move_count: int = 0
var max_combo: int = 0

# Screen Shake
var shake_intensity: float = 0.0
var shake_duration: float = 0.0

# Current 3 tray pieces (null if placed)
var tray_pieces: Array = [null, null, null]
var dragging_piece: BlockPiece = null
var drag_touch_id: int = -1

# Node references
@onready var camera: Camera2D = $Camera2D
@onready var combo_aura: Panel = $ComboAura
@onready var board: Board = $Board
@onready var score_label: Label = $UI/Header/ScoreBox/ScoreValue
@onready var best_label: Label = $UI/Header/BestBox/BestValue
@onready var combo_banner: PanelContainer = $UI/ComboBanner
@onready var combo_label: Label = $UI/ComboBanner/ComboLabel
@onready var btn_home: TextureButton = $UI/Header/BtnHome
@onready var btn_settings: TextureButton = $UI/Header/BtnSettings
@onready var btn_leaderboard: TextureButton = $UI/Header/BtnLeaderboard
@onready var btn_sound: TextureButton = $UI/Header/BtnSound

# Game Over Dialog
@onready var game_over_panel: ColorRect = $UI/GameOverModal
@onready var go_final_score: Label = $UI/GameOverModal/Card/FinalScore
@onready var go_best_score: Label = $UI/GameOverModal/Card/BestScore
@onready var go_new_badge: Label = $UI/GameOverModal/Card/NewBestBadge
@onready var go_rank_status: Label = $UI/GameOverModal/Card/RankStatus
@onready var go_btn_view_rank: Button = $UI/GameOverModal/Card/BtnViewRank
@onready var go_btn_retry: Button = $UI/GameOverModal/Card/BtnRetry
@onready var go_btn_home: Button = $UI/GameOverModal/Card/BtnGoHome

# Revive Modal
@onready var revive_modal: ReviveModal = $UI/ReviveModal

# Leaderboard Modal
@onready var leaderboard_modal: LeaderboardModal = $UI/LeaderboardModal
var was_in_start_screen: bool = false

# Settings & Setup Modals
@onready var settings_modal: SettingsModal = $UI/SettingsModal
@onready var profile_setup_modal: ProfileSetupModal = $UI/ProfileSetupModal

# Start Screen (Home Screen / Lobby)
@onready var start_screen: ColorRect = $UI/StartScreen
@onready var start_btn_home_sound: TextureButton = $UI/StartScreen/Card/BtnHomeSound
@onready var start_btn_home_settings: TextureButton = $UI/StartScreen/Card/BtnHomeSettings
@onready var start_player_avatar: TextureRect = $UI/StartScreen/Card/ProfileBox/PlayerAvatar
@onready var start_profile_title: Label = $UI/StartScreen/Card/ProfileBox/StatusLabel
@onready var start_profile_sub: Label = $UI/StartScreen/Card/ProfileBox/SubLabel
@onready var start_btn_edit_profile: Button = $UI/StartScreen/Card/ProfileBox/BtnEditProfile
@onready var start_btn_play: Button = $UI/StartScreen/Card/BtnPlay
@onready var start_btn_daily: Button = $UI/StartScreen/Card/BtnDaily
@onready var start_btn_adventure: Button = $UI/StartScreen/Card/BtnAdventure
@onready var best_sub: Label = $UI/Header/BestBox/BestHeader/BestSub
@onready var go_title: Label = $UI/GameOverModal/Card/Title
@onready var header_title: Label = $UI/Header/Title
@onready var start_btn_ranking: Button = $UI/StartScreen/Card/BtnRanking
@onready var start_btn_settings: Button = $UI/StartScreen/Card/BtnSettings

func _ready() -> void:
	randomize()
	_load_best_score()
	_update_ui()
	SettingsManager.init_settings()
	AuthManager.init_auth()
	
	# Header connections
	btn_home.pressed.connect(_open_home_screen)
	btn_settings.pressed.connect(_open_settings)
	btn_sound.pressed.connect(_on_sound_toggled)
	btn_leaderboard.pressed.connect(_open_leaderboard)
	
	# Revive connections
	revive_modal.revive_accepted.connect(_on_revive_accepted)
	revive_modal.revive_declined.connect(_on_revive_declined)
	
	# Modals signal connections
	leaderboard_modal.closed.connect(_on_leaderboard_closed)
	settings_modal.closed.connect(_on_settings_closed)
	settings_modal.request_profile_setup.connect(func(): profile_setup_modal.open())
	profile_setup_modal.setup_completed.connect(_on_profile_setup_completed)
	LeaderboardManager.profile_updated.connect(func(_n, _a): _update_home_profile_ui())
	
	# Home Screen connections
	start_btn_play.pressed.connect(_on_start_play_pressed)
	start_btn_daily.pressed.connect(_on_start_daily_pressed)
	start_btn_adventure.pressed.connect(_open_adventure_select)

	adventure_select = AdventureSelect.new()
	$UI.add_child(adventure_select)
	adventure_select.stage_selected.connect(_start_adventure_stage)
	adventure_select.closed.connect(_open_home_screen)
	start_btn_ranking.pressed.connect(_open_leaderboard)
	start_btn_settings.pressed.connect(_open_settings)
	start_btn_home_settings.pressed.connect(_open_settings)
	start_btn_home_sound.pressed.connect(_on_sound_toggled)
	start_btn_edit_profile.pressed.connect(_open_settings)
	
	# Game Over connections
	go_btn_retry.pressed.connect(start_new_game.bind(true))
	go_btn_view_rank.pressed.connect(_on_go_primary_pressed)
	go_btn_home.pressed.connect(_on_go_secondary_pressed)
	go_default_texts = {
		"title": go_title.text,
		"primary": go_btn_view_rank.text,
		"retry": go_btn_retry.text,
		"secondary": go_btn_home.text,
		"badge": go_new_badge.text
	}
	
	combo_banner.visible = false
	combo_aura.visible = false
	revive_modal.visible = false
	game_over_panel.visible = false
	leaderboard_modal.visible = false
	settings_modal.visible = false
	profile_setup_modal.visible = false
	
	# Show Start Screen initially
	start_screen.visible = true
	_update_home_profile_ui()
	
	# First-time user profile setup popup check
	if not LeaderboardManager.is_profile_setup_done:
		profile_setup_modal.open()

func _process(delta: float) -> void:
	if shake_duration > 0.0:
		shake_duration -= delta
		var ox = randf_range(-shake_intensity, shake_intensity)
		var oy = randf_range(-shake_intensity, shake_intensity)
		camera.offset = Vector2(ox, oy)
		if shake_duration <= 0.0:
			camera.offset = Vector2.ZERO
			shake_intensity = 0.0

func apply_screen_shake(intensity: float, duration: float) -> void:
	if not SettingsManager.screen_shake_enabled:
		return
	shake_intensity = max(shake_intensity, intensity)
	shake_duration = max(shake_duration, duration)

func start_new_game(from_retry: bool = false, mode: String = "") -> void:
	SoundManager.play_click()
	
	# Retry keeps the current mode; the home screen buttons choose one explicitly
	if not mode.is_empty():
		game_mode = mode
	if game_mode == "daily":
		challenge_day = LeaderboardManager.get_kst_day_key()
		challenge_rng = RandomNumberGenerator.new()
		challenge_rng.seed = hash("block-daily-" + challenge_day)
		daily_best = _load_daily_best(challenge_day)
		header_title.text = "오늘의 챌린지"
	elif game_mode == "adventure":
		header_title.text = "STAGE %d" % stage["id"]
		stage_progress = 0
	else:
		header_title.text = "BLOCK BLAST!"

	score = 0
	combo_count = 0
	combo_grace_moves = 0
	is_game_over = false
	new_best_achieved = false
	has_revived_this_game = false
	dragging_piece = null
	drag_touch_id = -1

	move_count = 0
	max_combo = 0
	game_start_msec = Time.get_ticks_msec()
	game_id = "g_%d_%d" % [Time.get_unix_time_from_system(), randi() % 100000]
	var since_last_over: float = -1.0
	if last_game_over_msec >= 0:
		since_last_over = (game_start_msec - last_game_over_msec) / 1000.0
	Analytics.log_event("game_start", {
		"game_id": game_id,
		"from_retry": from_retry,
		"mode": game_mode,
		"day_key": challenge_day if game_mode == "daily" else "",
		"stage_id": stage.get("id", 0) if game_mode == "adventure" else 0,
		"secs_since_game_over": since_last_over
	})
	
	revive_modal.close()
	game_over_panel.visible = false
	combo_banner.visible = false
	_update_combo_aura()
	
	board.reset_board()
	if game_mode == "adventure":
		board.load_layout(stage["layout"])
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
	var shapes: Array[Dictionary] = []
	if game_mode == "daily":
		shapes = BlockData.get_seeded_trio(challenge_rng)
	else:
		shapes = BlockData.get_adaptive_trio(board, combo_count, score, combo_grace_moves)
	Analytics.log_event("tray_dealt", {
		"game_id": game_id,
		"shapes": shapes.map(func(s): return s["id"]),
		"fill": snappedf(board.get_fill_ratio(), 0.001),
		"note": BlockData.last_generation_note
	})

	for i in range(3):
		var piece: BlockPiece = block_piece_scene.instantiate()
		add_child(piece)
		piece.setup(shapes[i], i, TRAY_SLOTS[i])
		tray_pieces[i] = piece
		
		# Pop in animation
		piece.scale = Vector2.ZERO
		var tw = create_tween()
		tw.tween_interval(i * 0.08)
		tw.tween_property(piece, "scale", Vector2.ONE * piece.tray_scale, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	_check_piece_usability_and_game_over()

func _input(event: InputEvent) -> void:
	if is_game_over or start_screen.visible or leaderboard_modal.visible or settings_modal.visible or profile_setup_modal.visible or adventure_select.visible:
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
		SettingsManager.vibrate(8)
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
		
		SettingsManager.vibrate(12)
		
		# (1) Placement Score: N points (1 per placed tile)
		var cell_count = piece.shape_data["cells"].size()
		_add_score(cell_count)
		
		piece.snap_to_board()
		
		# Check lines
		var clear_info = board.check_and_clear_lines()
		var lines = clear_info["lines"]
		var perfect: bool = clear_info["perfect"]
		
		if lines > 0:
			combo_count += 1
			combo_grace_moves = MAX_COMBO_GRACE
			_process_line_clears(lines, clear_info["cells"], clear_info["center"])
			if perfect:
				_process_perfect_clear()
		else:
			if combo_count > 0:
				combo_grace_moves -= 1
				if combo_grace_moves <= 0:
					combo_count = 0
					_hide_combo_banner()
					_update_combo_aura()
				else:
					# Grace move consumed, combo streak preserved!
					_show_combo_banner(combo_count, combo_grace_moves)

		move_count += 1
		max_combo = max(max_combo, combo_count)
		Analytics.log_event("place", {
			"game_id": game_id,
			"shape": piece.shape_data["id"],
			"cells": cell_count,
			"lines": lines,
			"perfect": perfect,
			"combo": combo_count,
			"grace": combo_grace_moves,
			"fill_after": snappedf(board.get_fill_ratio(), 0.001)
		})

		if game_mode == "adventure" and _update_stage_after_move(lines, clear_info["gems"]):
			return

		if _is_tray_empty():
			_spawn_new_tray()
		else:
			_check_piece_usability_and_game_over()
	else:
		piece.return_to_tray()

func _process_line_clears(lines: int, _cells: int, center_pos: Vector2) -> void:
	SoundManager.play_lines_clear(lines, combo_count)
	
	# Juicy dynamic camera shake based on cleared lines and streak combo
	var base_shake: float = 3.5
	match lines:
		1: base_shake = 4.0
		2: base_shake = 8.0
		3: base_shake = 13.0
		_: base_shake = 19.0
	if combo_count >= 3:
		base_shake += min(combo_count * 2.0, 12.0)
	apply_screen_shake(base_shake, 0.12 + lines * 0.04)
	SettingsManager.vibrate(mini(25 + 15 * lines + 3 * combo_count, 90))
	
	_update_combo_aura()
	
	# (2) Line Clear Base Score: 10 * L^2
	var base_line_score: int = 10 * lines * lines
	
	# (3) Combo Multiplier & Escalating Bonus:
	# Score_total = Score_clear * (1 + alpha * C) + Bonus(C)
	# Quadratic bonus triggers explosive growth when C >= 5..10+
	var combo_mult: float = 1.0 + 0.45 * combo_count
	var combo_bonus: int = 0
	if combo_count > 0:
		combo_bonus = int(15 * combo_count + 5 * combo_count * combo_count)
		
	var total_gain: int = int(base_line_score * combo_mult) + combo_bonus
	_add_score(total_gain)
	
	# Dopamine feedback praise tiers matching original Block Blast
	var praise_text = ""
	var praise_color = Color.WHITE
	
	if combo_count >= 15:
		praise_text = "GODLIKE! x%d\n+%d" % [combo_count, total_gain]
		praise_color = Color(0.96, 0.45, 0.85)
	elif combo_count >= 10:
		praise_text = "LEGENDARY! x%d\n+%d" % [combo_count, total_gain]
		praise_color = Color(1.0, 0.65, 0.1)
	elif combo_count >= 7:
		praise_text = "MASTER! x%d\n+%d" % [combo_count, total_gain]
		praise_color = Color(0.98, 0.45, 0.2)
	elif combo_count >= 5:
		praise_text = "UNBELIEVABLE! x%d\n+%d" % [combo_count, total_gain]
		praise_color = Color(0.97, 0.35, 0.35)
	elif combo_count >= 3:
		praise_text = "AMAZING! x%d\n+%d" % [combo_count, total_gain]
		praise_color = Color(0.99, 0.88, 0.28)
	elif combo_count >= 2:
		praise_text = "GREAT! x%d\n+%d" % [combo_count, total_gain]
		praise_color = Color(0.20, 0.83, 0.60)
	elif lines >= 3:
		praise_text = "TRIPLE! +%d" % total_gain
		praise_color = Color(0.99, 0.85, 0.25)
	elif lines == 2:
		praise_text = "DOUBLE! +%d" % total_gain
		praise_color = Color(0.22, 0.74, 0.97)
	else:
		praise_text = "COOL! +%d" % total_gain
		praise_color = Color(0.22, 0.74, 0.97)
		
	if combo_count >= 1:
		_show_combo_banner(combo_count, combo_grace_moves)
	
	var text_scale = 1.0
	if combo_count >= 10 or lines >= 4:
		text_scale = 1.55
	elif combo_count >= 5 or lines >= 3:
		text_scale = 1.35
	elif combo_count >= 2 or lines >= 2:
		text_scale = 1.15
	_spawn_floating_text(praise_text, center_pos, praise_color, text_scale)

func _process_perfect_clear() -> void:
	var gain: int = roundi(PERFECT_CLEAR_BASE * (1.0 + 0.45 * combo_count))
	_add_score(gain)
	
	SoundManager.play_perfect_clear()
	SettingsManager.vibrate(160)
	apply_screen_shake(24.0, 0.45)
	
	# Whole-board flash
	board.modulate = Color(1.9, 1.8, 1.4)
	var tw = create_tween()
	tw.tween_property(board, "modulate", Color.WHITE, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	var board_center: Vector2 = board.to_global(Vector2(Board.BOARD_WIDTH, Board.BOARD_HEIGHT) * 0.5)
	_spawn_floating_text("PERFECT!
+%d" % gain, board_center - Vector2(0, 90), Color(1.0, 0.84, 0.3), 1.75)

func _show_combo_banner(c: int, grace: int = 3) -> void:
	if c <= 0:
		_hide_combo_banner()
		return
		
	combo_banner.visible = true
	var pips = ""
	match grace:
		3: pips = "● ● ●"
		2: pips = "● ● ○"
		1: pips = "● ○ ○"
		_: pips = "● ● ●"
		
	combo_label.text = "COMBO x%d  %s" % [c, pips]
	
	if grace == 1:
		# Urgent warning pulse when 1 move left!
		combo_banner.modulate = Color(1.2, 0.5, 0.3)
		var tw = create_tween()
		tw.tween_property(combo_banner, "scale", Vector2.ONE * 1.15, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(combo_banner, "scale", Vector2.ONE, 0.1)
	else:
		combo_banner.modulate = Color.WHITE
		combo_banner.scale = Vector2.ONE * 0.75
		var tw = create_tween()
		tw.tween_property(combo_banner, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _hide_combo_banner() -> void:
	if combo_banner.visible:
		var tw = create_tween()
		tw.tween_property(combo_banner, "scale", Vector2.ZERO, 0.15)
		tw.tween_callback(func(): combo_banner.visible = false)

func _update_combo_aura() -> void:
	if combo_count < 3:
		if combo_aura.visible:
			var tw = create_tween()
			tw.tween_property(combo_aura, "modulate:a", 0.0, 0.2)
			tw.tween_callback(func(): combo_aura.visible = false)
	elif combo_count < 5:
		combo_aura.visible = true
		combo_aura.modulate = Color(0.2, 0.85, 1.0, 0.85) # Electric cyan neon
		var tw = create_tween()
		tw.tween_property(combo_aura, "scale", Vector2(1.015, 1.015), 0.1)
		tw.tween_property(combo_aura, "scale", Vector2.ONE, 0.1)
	else:
		combo_aura.visible = true
		combo_aura.modulate = Color(1.0, 0.6, 0.15, 1.0) # Fiery gold flame
		var tw = create_tween()
		tw.tween_property(combo_aura, "scale", Vector2(1.03, 1.03), 0.12)
		tw.tween_property(combo_aura, "scale", Vector2.ONE, 0.12)

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
		if game_mode == "adventure":
			_finish_stage(false, "stuck")
		elif not has_revived_this_game:
			_trigger_revive_chance()
		else:
			_trigger_game_over()

func _trigger_revive_chance() -> void:
	Analytics.log_event("revive_offer", {
		"game_id": game_id,
		"score": score,
		"fill": snappedf(board.get_fill_ratio(), 0.001)
	})
	apply_screen_shake(6.0, 0.25)
	SoundManager.play("invalid", 1.0, 2.0)
	revive_modal.open()

func _on_revive_accepted() -> void:
	has_revived_this_game = true
	SoundManager.play_revive_bomb()
	SettingsManager.vibrate(100)
	apply_screen_shake(18.0, 0.35)
	
	var cleared = board.execute_revive_bomb()
	Analytics.log_event("revive_result", {"game_id": game_id, "accepted": true, "cleared": cleared})
	_spawn_floating_text("SECOND CHANCE!\n+%d CLEARED" % cleared, Vector2(360, 580), Color(0.99, 0.82, 0.25), 1.4)
	_clear_tray()
	_spawn_new_tray()

func _on_revive_declined() -> void:
	Analytics.log_event("revive_result", {"game_id": game_id, "accepted": false, "cleared": 0})
	_trigger_game_over()

func _open_leaderboard() -> void:
	was_in_start_screen = start_screen.visible
	if was_in_start_screen:
		start_screen.visible = false
	# From a daily game (game over or header), jump straight to today's ranking
	var tab = "daily" if (game_mode == "daily" and not was_in_start_screen) else ""
	leaderboard_modal.open(tab)

func _on_leaderboard_closed() -> void:
	if was_in_start_screen:
		start_screen.visible = true

func _open_settings() -> void:
	was_in_start_screen = start_screen.visible
	if was_in_start_screen:
		start_screen.visible = false
	settings_modal.open()

func _on_settings_closed() -> void:
	if was_in_start_screen:
		start_screen.visible = true
	_update_home_profile_ui()

func _on_profile_setup_completed() -> void:
	_update_home_profile_ui()
	start_screen.visible = true

func _open_home_screen() -> void:
	SoundManager.play_click()
	if not start_screen.visible and not is_game_over and not game_id.is_empty():
		# Player left a game in progress
		Analytics.log_event("game_quit", {
			"game_id": game_id,
			"score": score,
			"moves": move_count,
			"duration_s": snappedf((Time.get_ticks_msec() - game_start_msec) / 1000.0, 0.1)
		})
		Analytics.flush()
	_update_home_profile_ui()
	start_screen.visible = true
	game_over_panel.visible = false
	if leaderboard_modal.visible:
		leaderboard_modal.close()
	if settings_modal.visible:
		settings_modal.close()
	if profile_setup_modal.visible:
		profile_setup_modal.close()
	adventure_select.visible = false

func _on_start_play_pressed() -> void:
	start_screen.visible = false
	start_new_game(false, "classic")

func _on_start_daily_pressed() -> void:
	start_screen.visible = false
	start_new_game(false, "daily")

func _update_home_profile_ui() -> void:
	start_player_avatar.texture = LeaderboardManager.get_avatar_texture()
	start_profile_title.text = LeaderboardManager.nickname
	
	var rank_text = ""
	if LeaderboardManager.last_known_rank > 0:
		rank_text = "전체 %d위" % LeaderboardManager.last_known_rank
	else:
		rank_text = "랭킹 도전 가능"
	start_profile_sub.text = "최고 점수: %s점  |  %s" % [_format_number(best_score), rank_text]
	
	var is_muted = SoundManager.is_muted
	btn_sound.texture_normal = sound_off_tex if is_muted else sound_on_tex
	start_btn_home_sound.texture_normal = sound_off_tex if is_muted else sound_on_tex

func _trigger_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	last_game_over_msec = Time.get_ticks_msec()
	
	var remaining_shapes: Array = []
	for p in tray_pieces:
		if p != null and is_instance_valid(p):
			remaining_shapes.append(p.shape_data["id"])
	Analytics.log_event("game_over", {
		"game_id": game_id,
		"score": score,
		"best_score": best_score,
		"new_best": new_best_achieved,
		"duration_s": snappedf((last_game_over_msec - game_start_msec) / 1000.0, 0.1),
		"moves": move_count,
		"max_combo": max_combo,
		"remaining_shapes": remaining_shapes,
		"fill": snappedf(board.get_fill_ratio(), 0.001),
		"revived": has_revived_this_game
	})
	Analytics.flush()
	
	SoundManager.play_gameover()
	SettingsManager.vibrate(120)
	_restore_game_over_texts()

	# Submit score to leaderboard API
	go_rank_status.text = "실시간 랭킹 등록 중..."
	if score > 0:
		LeaderboardManager.submit_score(score, _on_leaderboard_score_submitted, game_mode, challenge_day)
	else:
		go_rank_status.text = "0점은 랭킹에 등록되지 않습니다."
	
	await get_tree().create_timer(0.65).timeout
	
	go_final_score.text = "%s" % _format_number(score)
	if game_mode == "daily":
		go_best_score.text = "오늘 BEST: %s" % _format_number(daily_best)
	else:
		go_best_score.text = "BEST: %s" % _format_number(best_score)
	go_new_badge.visible = new_best_achieved
	
	if new_best_achieved:
		SoundManager.play_record()
	
	game_over_panel.visible = true
	game_over_panel.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(game_over_panel, "modulate:a", 1.0, 0.25)

func _restore_game_over_texts() -> void:
	go_title.text = go_default_texts["title"]
	go_btn_view_rank.text = go_default_texts["primary"]
	go_btn_retry.text = go_default_texts["retry"]
	go_btn_home.text = go_default_texts["secondary"]
	go_new_badge.text = go_default_texts["badge"]
	go_btn_view_rank.visible = true

func _on_go_primary_pressed() -> void:
	if game_mode == "adventure":
		_start_adventure_stage(int(stage["id"]) + 1)
	else:
		_open_leaderboard()

func _on_go_secondary_pressed() -> void:
	if game_mode == "adventure":
		_open_adventure_select()
	else:
		_open_home_screen()

# =========================================================
# Adventure mode
# =========================================================

func _open_adventure_select() -> void:
	start_screen.visible = false
	game_over_panel.visible = false
	adventure_select.open()

func _start_adventure_stage(stage_id: int) -> void:
	var next: Dictionary = AdventureData.get_stage(stage_id)
	if next.is_empty():
		_open_adventure_select()
		return
	stage = next
	adventure_select.visible = false
	start_screen.visible = false
	game_over_panel.visible = false
	start_new_game(false, "adventure")

func _update_stage_after_move(lines: int, gems: int) -> bool:
	# Returns true when the stage ended (cleared or out of moves)
	match stage["goal"]["type"]:
		"lines":
			stage_progress += lines
		"gems":
			stage_progress += gems
		"score":
			stage_progress = score
	_update_ui()
	if stage_progress >= int(stage["goal"]["target"]):
		_finish_stage(true, "goal")
		return true
	if int(stage["moves"]) > 0 and move_count >= int(stage["moves"]):
		_finish_stage(false, "moves")
		return true
	return false

func _finish_stage(cleared: bool, reason: String) -> void:
	if is_game_over:
		return
	is_game_over = true
	last_game_over_msec = Time.get_ticks_msec()

	var stars: int = AdventureData.stars_for(stage, move_count) if cleared else 0
	var improved: bool = cleared and AdventureData.record_result(int(stage["id"]), stars)
	Analytics.log_event("stage_result", {
		"game_id": game_id,
		"stage_id": stage["id"],
		"cleared": cleared,
		"stars": stars,
		"moves_used": move_count,
		"score": score,
		"progress": stage_progress,
		"reason": reason
	})
	Analytics.flush()

	if cleared:
		SoundManager.play_record()
		SettingsManager.vibrate(160)
	else:
		SoundManager.play_gameover()
		SettingsManager.vibrate(120)

	await get_tree().create_timer(0.65).timeout

	var goal: Dictionary = stage["goal"]
	var progress: int = score if goal["type"] == "score" else stage_progress
	go_title.text = "STAGE CLEAR!" if cleared else "STAGE FAILED"
	go_final_score.text = _format_number(score)
	go_best_score.text = AdventureData.star_text(stars) if cleared else AdventureData.goal_text(goal, progress)
	go_new_badge.text = "NEW RECORD"
	go_new_badge.visible = improved
	match reason:
		"goal":
			go_rank_status.text = "%s 달성! (%d수)" % [AdventureData.goal_text(goal), move_count]
		"moves":
			go_rank_status.text = "이동 횟수를 모두 사용했습니다."
		_:
			go_rank_status.text = "더 이상 놓을 곳이 없습니다."
	var has_next: bool = not AdventureData.get_stage(int(stage["id"]) + 1).is_empty()
	go_btn_view_rank.text = "다음 스테이지"
	go_btn_view_rank.visible = cleared and has_next
	go_btn_retry.text = "다시 도전"
	go_btn_home.text = "스테이지 선택"

	game_over_panel.visible = true
	game_over_panel.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(game_over_panel, "modulate:a", 1.0, 0.25)

func _on_leaderboard_score_submitted(res: Dictionary) -> void:
	if not is_instance_valid(go_rank_status):
		return
	if res.get("success", false):
		var r = int(res.get("rank", -1))
		var is_new = bool(res.get("is_new_best", false))
		var scope = "오늘의 챌린지" if res.get("mode", "") == "daily" else "전체"
		if is_new:
			go_rank_status.text = "★ 최고 기록 경신! %s %d위 달성! ★" % [scope, r]
		else:
			go_rank_status.text = "내 최고 순위: %s %d위" % [scope, r]
	else:
		go_rank_status.text = "실시간 랭킹 확인 가능"

func _add_score(amount: int) -> void:
	score += amount
	if game_mode == "adventure":
		pass # Stage scores never touch classic/daily records
	elif game_mode == "daily":
		if score > daily_best:
			daily_best = score
			new_best_achieved = true
			_save_daily_best()
	elif score > best_score:
		best_score = score
		new_best_achieved = true
		_save_best_score()
	_update_ui()
	
	score_label.scale = Vector2.ONE * 1.25
	var tw = create_tween()
	tw.tween_property(score_label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _update_ui() -> void:
	score_label.text = _format_number(score)
	if game_mode == "adventure" and not stage.is_empty():
		var progress: int = score if stage["goal"]["type"] == "score" else stage_progress
		best_label.text = AdventureData.goal_text(stage["goal"], progress)
		if int(stage["moves"]) > 0:
			best_sub.text = "목표 · 남은 이동 %d" % maxi(0, int(stage["moves"]) - move_count)
		else:
			best_sub.text = "목표"
	else:
		best_sub.text = "BEST"
		best_label.text = _format_number(daily_best if game_mode == "daily" else best_score)

func _on_sound_toggled() -> void:
	SoundManager.play_click()
	var muted = SoundManager.toggle_mute()
	SettingsManager.set_sound(not muted)
	btn_sound.texture_normal = sound_off_tex if muted else sound_on_tex
	start_btn_home_sound.texture_normal = sound_off_tex if muted else sound_on_tex

func _load_best_score() -> void:
	var cfg = ConfigFile.new()
	var err = cfg.load(SAVE_PATH)
	if err == OK:
		best_score = cfg.get_value("game", "best_score", 0)

func _save_best_score() -> void:
	var cfg = ConfigFile.new()
	cfg.load(SAVE_PATH) # keep other sections (daily bests)
	cfg.set_value("game", "best_score", best_score)
	cfg.save(SAVE_PATH)

func _load_daily_best(day_key: String) -> int:
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return 0
	return int(cfg.get_value("daily", day_key, 0))

func _save_daily_best() -> void:
	var cfg = ConfigFile.new()
	cfg.load(SAVE_PATH)
	# Only today's entry matters; drop older days
	if cfg.has_section("daily"):
		for key in cfg.get_section_keys("daily"):
			if key != challenge_day:
				cfg.erase_section_key("daily", key)
	cfg.set_value("daily", challenge_day, daily_best)
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
