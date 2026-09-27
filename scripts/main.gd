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

# Game Over Dialog
@onready var game_over_panel: ColorRect = $UI/GameOverModal
@onready var go_final_score: Label = $UI/GameOverModal/Card/FinalScore
@onready var go_best_score: Label = $UI/GameOverModal/Card/BestScore
@onready var go_new_badge: Label = $UI/GameOverModal/Card/NewBestBadge
@onready var go_btn_retry: Button = $UI/GameOverModal/Card/BtnRetry

func _ready() -> void:
	randomize()
	_load_best_score()
	_update_ui()
	
	# Header & Game Over connections
	btn_sound.pressed.connect(_on_sound_toggled)
	btn_restart.pressed.connect(start_new_game)
	go_btn_retry.pressed.connect(start_new_game)
	board.lines_cleared.connect(_on_board_lines_cleared)
	
	combo_banner.visible = false
	game_over_panel.visible = false
	
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
	if is_game_over:
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
	_update_ui()
	
	score_label.scale = Vector2.ONE * 1.25
	var tw = create_tween()
	tw.tween_property(score_label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _update_ui() -> void:
	score_label.text = _format_number(score)
	best_label.text = _format_number(best_score)

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
