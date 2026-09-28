extends Node
# Headless test for T-08: validates stage data, the stage select screen, and plays every
# stage with a gem-aware greedy bot to confirm each one can be cleared.
# Run: Godot_console.exe --headless --path . res://tests/test_adventure.tscn
# Local save files are backed up and restored; analytics are disabled.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const ATTEMPTS: int = 8
const USER_FILES: Array[String] = [
	"user://block_blast_save.cfg",
	"user://player_profile.json",
	"user://game_settings.json",
	"user://achievements.json",
	"user://adventure_progress.json",
]

var main: MainGame
# The bot's own RNG: the global one is also drawn by particles, which depends on frame timing
var bot_rng := RandomNumberGenerator.new()
var backups: Dictionary = {}
var failures: Array[String] = []

func _ready() -> void:
	Analytics.enabled = false
	seed(8080)
	_backup_user_files()
	if FileAccess.file_exists(AdventureData.PROGRESS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(AdventureData.PROGRESS_PATH))
	main = MainScene.instantiate()
	add_child(main)
	_run.call_deferred()

func _run() -> void:
	await get_tree().process_frame
	main.profile_setup_modal.visible = false
	# Seed the piece generator and the bot so runs are reproducible
	BlockData.get_default_rng().seed = 8080
	bot_rng.seed = 8080
	
	_validate_stage_data()
	_check_select_screen(1)

	print("stage | goal        | moves | wins | moves used (wins)")
	for s in AdventureData.STAGES:
		var wins := 0
		var used: Array[int] = []
		for attempt in range(ATTEMPTS):
			main._start_adventure_stage(s["id"])
			await get_tree().process_frame
			if attempt == 0:
				_check_stage_start(s)
			var cleared: bool = await _play_stage()
			if cleared:
				wins += 1
				used.append(main.move_count)
		used.sort()
		print("%5d | %-11s | %5d | %d/%d | %s" % [s["id"], AdventureData.goal_text(s["goal"]), s["moves"], wins, ATTEMPTS, str(used)])
		if wins == 0:
			failures.append("stage %d was never cleared by the bot" % s["id"])

	var progress := AdventureData.load_progress()
	if int(progress["unlocked"]) != AdventureData.stage_count():
		failures.append("expected all stages unlocked, got %d" % progress["unlocked"])
	_check_select_screen(AdventureData.stage_count())

	_restore_user_files()
	if failures.is_empty():
		print("ADVENTURE OK")
	else:
		for f in failures:
			printerr("FAIL: " + f)
	get_tree().quit(0 if failures.is_empty() else 1)

func _validate_stage_data() -> void:
	var ids := {}
	for s in AdventureData.STAGES:
		var sid: int = s["id"]
		if ids.has(sid):
			failures.append("duplicate stage id %d" % sid)
		ids[sid] = true
		if not s["goal"]["type"] in ["score", "lines", "gems"]:
			failures.append("stage %d: bad goal type" % sid)
		var th: Array = s["stars"]
		if th.size() != 2 or th[0] > th[1] or (int(s["moves"]) > 0 and th[1] > int(s["moves"])):
			failures.append("stage %d: bad star thresholds %s" % [sid, str(th)])
		var layout: Array = s["layout"]
		if layout.size() != 8:
			failures.append("stage %d: layout needs 8 rows" % sid)
			continue
		var grid: Array = []
		var gems := 0
		for row in layout:
			if row.length() != 8:
				failures.append("stage %d: row '%s' is not 8 wide" % [sid, row])
			for ch in row:
				if ch != "." and not AdventureData.COLOR_CODES.has(ch.to_lower()):
					failures.append("stage %d: unknown cell '%s'" % [sid, ch])
				if ch != "." and ch != ch.to_lower():
					gems += 1
			grid.append(row)
		for i in range(8):
			if not grid[i].contains("."):
				failures.append("stage %d: row %d starts full" % [sid, i])
			var col_full := true
			for r in grid:
				if r[i] == ".":
					col_full = false
			if col_full:
				failures.append("stage %d: column %d starts full" % [sid, i])
		if s["goal"]["type"] == "gems" and gems < int(s["goal"]["target"]):
			failures.append("stage %d: only %d gems for target %d" % [sid, gems, s["goal"]["target"]])

func _check_stage_start(s: Dictionary) -> void:
	var expected := 0
	var gems := 0
	for row in s["layout"]:
		for ch in row:
			if ch != ".":
				expected += 1
				if ch != ch.to_lower():
					gems += 1
	if main.game_mode != "adventure" or main.board.get_occupied_count() != expected or main.board.get_gem_count() != gems:
		failures.append("stage %d did not load its layout" % s["id"])
	if main.header_title.text != "STAGE %d" % s["id"]:
		failures.append("stage %d header title wrong: %s" % [s["id"], main.header_title.text])

func _check_select_screen(expected_unlocked: int) -> void:
	main._open_adventure_select()
	var buttons: Array = main.adventure_select.grid.get_children().filter(func(b): return not b.is_queued_for_deletion())
	var unlocked: int = buttons.filter(func(b): return not b.disabled).size()
	if buttons.size() != AdventureData.stage_count():
		failures.append("select screen shows %d stages" % buttons.size())
	if unlocked != expected_unlocked:
		failures.append("select screen unlocked %d, expected %d" % [unlocked, expected_unlocked])
	main.adventure_select.visible = false

func _play_stage() -> bool:
	var guard := 0
	while not main.is_game_over and guard < 200:
		guard += 1
		var move: Dictionary = _pick_move()
		if move.is_empty():
			await get_tree().process_frame
			continue
		var piece: BlockPiece = move["piece"]
		piece.global_position = move["target"]
		main.dragging_piece = piece
		main._on_pointer_up(Vector2.ZERO, -1)
		await get_tree().process_frame
	await get_tree().create_timer(0.75).timeout
	return main.go_title.text == "STAGE CLEAR!"

func _pick_move() -> Dictionary:
	# Greedy: gems first, then cleared cells, random tie-break
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
				var after_grid := BlockData.place_and_clear(grid, offsets, bx, by)
				var cleared := before + offsets.size() - _count(after_grid)
				var gems := 0
				for g in board.gem_cells:
					if after_grid[g.x + g.y * 8] == 0:
						gems += 1
				var s := gems * 100.0 + cleared * 10.0 + bot_rng.randf()
				if s > best_score:
					best_score = s
					var half := Vector2((bounds.size.x * Board.CELL_SPACING - Board.CELL_GAP) * 0.5,
						(bounds.size.y * Board.CELL_SPACING - Board.CELL_GAP) * 0.5)
					best = {"piece": piece, "target": board.to_global(Vector2(bx * Board.CELL_SPACING, by * Board.CELL_SPACING) + half)}
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
