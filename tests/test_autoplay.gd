extends Node
# Headless integration test: plays real games through main.tscn with a greedy bot.
# Exercises placement, scoring, combos, revive (accept and decline), game over and analytics.
# Run against a local server so nothing reaches the 112 server:
#   BLOCK_API_HOST=http://127.0.0.1:3000 Godot_console.exe --headless --path . res://tests/test_autoplay.tscn
# Local save files (best score, profile, settings) are backed up and restored.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const GAMES: int = 4
const USER_FILES: Array[String] = [
	"user://block_blast_save.cfg",
	"user://player_profile.json",
	"user://game_settings.json",
]

var main: MainGame
var backups: Dictionary = {}
var failures: Array[String] = []

func _ready() -> void:
	if OS.get_environment("BLOCK_API_HOST").is_empty():
		push_error("Set BLOCK_API_HOST to a local server before running this test")
		get_tree().quit(2)
		return
	seed(424242)
	_backup_user_files()
	main = MainScene.instantiate()
	add_child(main)
	_run.call_deferred()

func _run() -> void:
	await get_tree().process_frame
	main.profile_setup_modal.visible = false

	for g in range(GAMES):
		if g == 0:
			main._on_start_play_pressed()
		else:
			main.start_new_game(true)
		await get_tree().process_frame

		var guard := 0
		while not main.is_game_over and guard < 600:
			guard += 1
			if main.revive_modal.is_active:
				# Accept on even games, decline on odd games
				if g % 2 == 0:
					main.revive_modal._on_revive_pressed()
				else:
					main.revive_modal._on_skip_pressed()
				await get_tree().process_frame
				continue
			var move: Dictionary = _pick_move()
			if move.is_empty():
				await get_tree().process_frame
				continue
			var piece: BlockPiece = move["piece"]
			piece.global_position = move["target"]
			main.dragging_piece = piece
			main._on_pointer_up(Vector2.ZERO, -1)
			await get_tree().process_frame

		await get_tree().create_timer(0.8).timeout
		print("game %d: score=%d moves=%d max_combo=%d revived=%s" % [
			g, main.score, main.move_count, main.max_combo, str(main.has_revived_this_game)])
		if not main.is_game_over:
			failures.append("game %d did not reach game over" % g)
		if main.move_count <= 0:
			failures.append("game %d made no moves" % g)

	await _check_perfect_clear()
	_check_vibration_setting()

	# Let the last analytics batch reach the server
	for i in range(30):
		if not Analytics.is_flushing:
			break
		await get_tree().create_timer(0.1).timeout
	Analytics.flush()
	await get_tree().create_timer(1.5).timeout

	_restore_user_files()
	if failures.is_empty():
		print("AUTOPLAY OK")
	else:
		for f in failures:
			printerr("FAIL: " + f)
	get_tree().quit(0 if failures.is_empty() else 1)

func _check_perfect_clear() -> void:
	# Scripted board: bottom row filled except the last cell, then drop a 1x1 into the gap
	main.start_new_game()
	await get_tree().process_frame
	var board: Board = main.board
	board.reset_board()
	for x in range(7):
		board.grid_state[x][7] = "blue"
	var piece: BlockPiece = main.tray_pieces[0]
	piece.setup(BlockData.SHAPES[0], 0, piece.tray_position)
	var score_before: int = main.score
	piece.global_position = board.to_global(board.get_cell_position(7, 7))
	main.dragging_piece = piece
	main._on_pointer_up(Vector2.ZERO, -1)
	await get_tree().process_frame

	# 1 (placement) + 34 (1 line, combo 1) + 435 (perfect: 300 x 1.45)
	var gained: int = main.score - score_before
	print("perfect clear: gained=%d occupied=%d" % [gained, board.get_occupied_count()])
	if gained != 470:
		failures.append("perfect clear gave %d points, expected 470" % gained)
	if board.get_occupied_count() != 0:
		failures.append("board not empty after perfect clear")

func _check_vibration_setting() -> void:
	# Toggle through the settings screen and confirm the value survives a reload
	var original: bool = SettingsManager.vibration_enabled
	main.settings_modal._on_vibration_toggled()
	SettingsManager.vibration_enabled = original
	SettingsManager.load_settings()
	if SettingsManager.vibration_enabled == original:
		failures.append("vibration setting was not saved")
	if not main.settings_modal.btn_vibration.text.begins_with("진동 효과: "):
		failures.append("vibration toggle label not updated")
	print("vibration setting: %s -> %s" % [str(original), str(SettingsManager.vibration_enabled)])
	SettingsManager.set_vibration(original)

func _pick_move() -> Dictionary:
	# Greedy bot: prefer placements that clear the most cells, random tie-break
	var board: Board = main.board
	var grid: PackedByteArray = board.get_occupancy_snapshot()
	var before := _count(grid)
	var best: Dictionary = {}
	var best_score := -1.0
	for piece in main.tray_pieces:
		if piece == null or not is_instance_valid(piece):
			continue
		var shape: Dictionary = piece.shape_data
		var offsets: Array[Vector2i] = BlockData.get_offsets(shape)
		var bounds: Rect2i = BlockData.get_bounds(shape["cells"])
		for by in range(8 - bounds.size.y + 1):
			for bx in range(8 - bounds.size.x + 1):
				var ok := true
				for o in offsets:
					if grid[(bx + o.x) + (by + o.y) * 8] != 0:
						ok = false
						break
				if not ok:
					continue
				var after := _count(BlockData.place_and_clear(grid, offsets, bx, by))
				var cleared := before + offsets.size() - after
				var s := cleared * 10.0 + randf()
				if s > best_score:
					best_score = s
					var half := Vector2((bounds.size.x * Board.CELL_SPACING - Board.CELL_GAP) * 0.5,
						(bounds.size.y * Board.CELL_SPACING - Board.CELL_GAP) * 0.5)
					var local := Vector2(bx * Board.CELL_SPACING, by * Board.CELL_SPACING) + half
					best = {"piece": piece, "target": board.to_global(local)}
	return best

func _count(grid: PackedByteArray) -> int:
	var n := 0
	for v in grid:
		n += v
	return n

func _backup_user_files() -> void:
	for p in USER_FILES:
		if FileAccess.file_exists(p):
			backups[p] = FileAccess.get_file_as_bytes(p)

func _restore_user_files() -> void:
	for p in USER_FILES:
		if backups.has(p):
			var f := FileAccess.open(p, FileAccess.WRITE)
			f.store_buffer(backups[p])
			f.close()
		elif FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
