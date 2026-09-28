extends Node
# Headless test for T-01: every dealt trio must be placeable in sequence whenever any solvable set exists.
# Run: Godot_console.exe --headless --path . res://tests/test_solvability.tscn

const BoardScene: PackedScene = preload("res://scenes/board.tscn")
const UNLIMITED: int = 1 << 40

var board: Board
var violations: int = 0
var checks: int = 0
var notes: Dictionary = {}
var times_all: Array[int] = []
var times_crisis: Array[int] = []

func _ready() -> void:
	board = BoardScene.instantiate()
	add_child(board)
	_run.call_deferred()

func _run() -> void:
	seed(20260929)

	# 1) Boards reached through simulated play (random agent)
	for game in range(40):
		var grid := PackedByteArray()
		grid.resize(64)
		var combo := 0
		for deal in range(60):
			var trio := _deal_and_check(grid, combo)
			var next = _random_play(grid, trio)
			if next == null:
				break
			combo = combo + 1 if randf() < 0.3 else 0
			grid = next

	# 2) Random boards across fill densities
	for i in range(700):
		var d := 0.25 + 0.65 * (float(i) / 700.0)
		_deal_and_check(_random_board(d), randi() % 3)

	print("checks=%d violations=%d" % [checks, violations])
	print("generation notes: %s" % str(notes))
	print("trio time us: avg=%d max=%d | crisis(fill>=70%%) avg=%d max=%d n=%d" % [
		_avg(times_all), _max(times_all), _avg(times_crisis), _max(times_crisis), times_crisis.size()])
	get_tree().quit(1 if violations > 0 else 0)

func _deal_and_check(grid: PackedByteArray, combo: int) -> Array[Dictionary]:
	_sync(grid)
	var fill := board.get_fill_ratio()
	var t0 := Time.get_ticks_usec()
	var trio: Array[Dictionary] = BlockData.get_adaptive_trio(board, combo, 500, 3)
	var dt := Time.get_ticks_usec() - t0
	times_all.append(dt)
	if fill >= 0.70:
		times_crisis.append(dt)

	var note := BlockData.last_generation_note
	notes[note] = notes.get(note, 0) + 1

	checks += 1
	var dot: Dictionary = BlockData.SHAPES[0]
	var any_solvable := BlockData.can_place_all(grid, [dot, dot, dot], UNLIMITED)
	var trio_solvable := BlockData.can_place_all(grid, trio, UNLIMITED)
	if any_solvable and not trio_solvable:
		violations += 1
		printerr("VIOLATION fill=%.2f trio=%s note=%s" % [fill, str(trio.map(func(s): return s["id"])), note])
	return trio

func _random_play(grid: PackedByteArray, trio: Array[Dictionary]):
	var order := trio.duplicate()
	order.shuffle()
	var g := grid
	for shape in order:
		var offsets: Array[Vector2i] = BlockData.get_offsets(shape)
		var bounds: Rect2i = BlockData.get_bounds(shape["cells"])
		var spots: Array[Vector2i] = []
		for by in range(8 - bounds.size.y + 1):
			for bx in range(8 - bounds.size.x + 1):
				var ok := true
				for o in offsets:
					if g[(bx + o.x) + (by + o.y) * 8] != 0:
						ok = false
						break
				if ok:
					spots.append(Vector2i(bx, by))
		if spots.is_empty():
			return null
		var p: Vector2i = spots[randi() % spots.size()]
		g = BlockData.place_and_clear(g, offsets, p.x, p.y)
	return g

func _random_board(density: float) -> PackedByteArray:
	var g := PackedByteArray()
	g.resize(64)
	for i in range(64):
		if randf() < density:
			g[i] = 1
	# A live board never contains full lines
	for y in range(8):
		var full := true
		for x in range(8):
			if g[x + y * 8] == 0:
				full = false
				break
		if full:
			g[randi() % 8 + y * 8] = 0
	for x in range(8):
		var full := true
		for y in range(8):
			if g[x + y * 8] == 0:
				full = false
				break
		if full:
			g[x + (randi() % 8) * 8] = 0
	return g

func _sync(grid: PackedByteArray) -> void:
	for x in range(8):
		for y in range(8):
			board.grid_state[x][y] = "blue" if grid[x + y * 8] != 0 else null

func _avg(a: Array[int]) -> int:
	if a.is_empty():
		return 0
	var s := 0
	for v in a:
		s += v
	return s / a.size()

func _max(a: Array[int]) -> int:
	var m := 0
	for v in a:
		m = max(m, v)
	return m
