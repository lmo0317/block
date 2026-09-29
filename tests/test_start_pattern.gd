extends Node
# Headless test for the classic start pattern: every generated board meets the rules, the first set
# can clear a line right away, and the generator is deterministic for a seed.
# Run: Godot_console.exe --headless --path . res://tests/test_start_pattern.tscn

const BoardScene: PackedScene = preload("res://scenes/board.tscn")
const RUNS: int = 1000

var board: Board
var failures: Array[String] = []

func _ready() -> void:
	board = BoardScene.instantiate()
	add_child(board)
	_run.call_deferred()

func _run() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var empty := 0
	var cells_hist := {}
	var pieces_hist := {}
	var first_clear_ok := 0
	var doubles := 0
	var hole_piece_dealt := 0
	var total_us := 0
	for i in range(RUNS):
		var t0 := Time.get_ticks_usec()
		var placements: Array[Dictionary] = BlockData.generate_start_pattern(rng)
		total_us += Time.get_ticks_usec() - t0
		if placements.is_empty():
			empty += 1
			continue
		var grid := PackedByteArray()
		grid.resize(64)
		for p in placements:
			for o in BlockData.get_offsets(p["shape"]):
				var idx: int = (p["x"] + o.x) + (p["y"] + o.y) * 8
				if grid[idx] != 0:
					failures.append("run %d: pieces overlap" % i)
				grid[idx] = 1
		if not BlockData._start_pattern_ok(grid):
			failures.append("run %d: pattern breaks the rules" % i)
		var cells := 0
		for v in grid:
			cells += v
		cells_hist[cells] = cells_hist.get(cells, 0) + 1
		var hole_pieces := BlockData._multi_clear_shapes(grid)
		if not hole_pieces.is_empty():
			doubles += 1
		pieces_hist[placements.size()] = pieces_hist.get(placements.size(), 0) + 1
		
		# The first set must contain a piece that clears a line immediately
		for x in range(8):
			for y in range(8):
				board.grid_state[x][y] = "blue" if grid[x + y * 8] != 0 else null
		var trio: Array[Dictionary] = BlockData.get_fun_trio(board, 0, 0, 3, rng, true)
		if trio.any(func(s): return hole_pieces.has(s)):
			hole_piece_dealt += 1
		var clears := false
		for s in trio:
			if not board.find_clearing_shapes([s]).is_empty():
				clears = true
		if clears:
			first_clear_ok += 1
		if not BlockData.can_place_all(grid, trio, 1 << 40):
			failures.append("run %d: first set cannot be placed in sequence" % i)
	
	var generated := RUNS - empty
	print("patterns generated %d/%d  avg %.2f ms" % [generated, RUNS, total_us / 1000.0 / RUNS])
	print("pieces: %s" % str(pieces_hist))
	var keys := cells_hist.keys()
	keys.sort()
	print("cells: min %d max %d" % [keys[0], keys[-1]])
	print("first set clears a line: %d/%d" % [first_clear_ok, generated])
	print("boards with a double-clear hole: %d/%d, first set has the piece that fits it: %d" % [doubles, generated, hole_piece_dealt])
	if empty > RUNS * 0.02:
		failures.append("too many empty fallbacks: %d" % empty)
	if hole_piece_dealt < doubles * 0.8:
		failures.append("hole piece dealt too rarely: %d/%d" % [hole_piece_dealt, doubles])
	if first_clear_ok < generated:
		failures.append("first set without a clearing piece: %d" % (generated - first_clear_ok))
	
	# Same seed, same boards
	var a := RandomNumberGenerator.new()
	a.seed = 42
	var b := RandomNumberGenerator.new()
	b.seed = 42
	var pa := BlockData.generate_start_pattern(a).map(func(p): return [p["shape"]["id"], p["x"], p["y"]])
	var pb := BlockData.generate_start_pattern(b).map(func(p): return [p["shape"]["id"], p["x"], p["y"]])
	if pa != pb:
		failures.append("same seed produced different patterns")
	
	if failures.is_empty():
		print("START PATTERN OK")
	else:
		for f in failures.slice(0, 10):
			printerr("FAIL: " + f)
	get_tree().quit(0 if failures.is_empty() else 1)
