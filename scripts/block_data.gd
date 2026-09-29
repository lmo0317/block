class_name BlockData
extends RefCounted

# Color list matching generated sprites:
# "blue", "orange", "green", "purple", "yellow", "red", "cyan", "pink"

const SHAPES: Array[Dictionary] = [
	# 1. Single Dot (1 cell)
	{
		"id": "dot_1x1",
		"category": "small",
		"color": "yellow",
		"cells": [Vector2i(0, 0)]
	},
	# 2. Dominoes (2 cells)
	{
		"id": "line_2_h",
		"category": "small",
		"color": "cyan",
		"cells": [Vector2i(0, 0), Vector2i(1, 0)]
	},
	{
		"id": "line_2_v",
		"category": "small",
		"color": "cyan",
		"cells": [Vector2i(0, 0), Vector2i(0, 1)]
	},
	# 3. Triominoes (3 cells)
	{
		"id": "line_3_h",
		"category": "medium",
		"color": "blue",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	},
	{
		"id": "line_3_v",
		"category": "medium",
		"color": "blue",
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)]
	},
	# 4. Small Corners (3 cells)
	{
		"id": "corner_2x2_1",
		"category": "medium",
		"color": "orange",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]
	},
	{
		"id": "corner_2x2_2",
		"category": "medium",
		"color": "orange",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)]
	},
	{
		"id": "corner_2x2_3",
		"category": "medium",
		"color": "orange",
		"cells": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 0)]
	},
	{
		"id": "corner_2x2_4",
		"category": "medium",
		"color": "orange",
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]
	},
	# 5. 2x2 Square (4 cells)
	{
		"id": "square_2x2",
		"category": "medium",
		"color": "green",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
	},
	# 6. Straight Tetrominoes (4 cells)
	{
		"id": "line_4_h",
		"category": "medium",
		"color": "pink",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	},
	{
		"id": "line_4_v",
		"category": "medium",
		"color": "pink",
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)]
	},
	# 7. Classic L & J shapes (4 cells)
	{
		"id": "l_4_1",
		"category": "medium",
		"color": "orange",
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)]
	},
	{
		"id": "l_4_2",
		"category": "medium",
		"color": "orange",
		"cells": [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(0, 2)]
	},
	{
		"id": "l_4_3",
		"category": "medium",
		"color": "orange",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1)]
	},
	{
		"id": "l_4_4",
		"category": "medium",
		"color": "orange",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)]
	},
	# 8. T-Shapes (4 cells)
	{
		"id": "t_1",
		"category": "medium",
		"color": "purple",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)]
	},
	{
		"id": "t_2",
		"category": "medium",
		"color": "purple",
		"cells": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
	},
	{
		"id": "t_3",
		"category": "medium",
		"color": "purple",
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 1)]
	},
	{
		"id": "t_4",
		"category": "medium",
		"color": "purple",
		"cells": [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(0, 1)]
	},
	# 9. Z & S Shapes (4 cells)
	{
		"id": "z_h",
		"category": "medium",
		"color": "green",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)]
	},
	{
		"id": "z_v",
		"category": "medium",
		"color": "green",
		"cells": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)]
	},
	{
		"id": "s_h",
		"category": "medium",
		"color": "green",
		"cells": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)]
	},
	{
		"id": "s_v",
		"category": "medium",
		"color": "green",
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)]
	},
	# 10. Large Straight (5 cells)
	{
		"id": "line_5_h",
		"category": "large",
		"color": "red",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)]
	},
	{
		"id": "line_5_v",
		"category": "large",
		"color": "red",
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4)]
	},
	# 11. Large L-shapes (5 cells - 3x3 corner)
	{
		"id": "big_l_1",
		"category": "large",
		"color": "purple",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(0, 2)]
	},
	{
		"id": "big_l_2",
		"category": "large",
		"color": "purple",
		"cells": [Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(0, 0), Vector2i(1, 0)]
	},
	{
		"id": "big_l_3",
		"category": "large",
		"color": "purple",
		"cells": [Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(2, 0), Vector2i(2, 1)]
	},
	{
		"id": "big_l_4",
		"category": "large",
		"color": "purple",
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)]
	},
	# 12. 3x3 Big Square (9 cells)
	{
		"id": "square_3x3",
		"category": "large",
		"color": "red",
		"cells": [
			Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
			Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
			Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)
		]
	}
]

const GRID_N: int = 8
# Max search nodes for the sequential placement check (keeps the worst case cheap on Web)
const SOLVE_NODE_BUDGET: int = 6000
# Role-based rerolls before falling back to rescue pieces
const MAX_TRIO_ATTEMPTS: int = 8

static var _offset_cache: Dictionary = {}
static var _default_rng: RandomNumberGenerator = null
# How the last trio was produced: "roll_N", "rescue", "dots", "dead" (for logging and tests)
static var last_generation_note: String = ""

const SHAPE_BASE_WEIGHTS: Dictionary = {
	"dot_1x1": 0.0,
	# Dominoes (high demand, universal gap pluggers)
	"line_2_h": 4.5, "line_2_v": 4.5,
	# Triominoes (very friendly builders and bridges)
	"line_3_h": 3.8, "line_3_v": 3.8,
	"square_2x2": 3.5,
	"corner_2x2_1": 2.4, "corner_2x2_2": 2.4, "corner_2x2_3": 2.4, "corner_2x2_4": 2.4,
	# Tetrominoes
	"line_4_h": 2.8, "line_4_v": 2.8,
	"t_1": 1.4, "t_2": 1.4, "t_3": 1.4, "t_4": 1.4,
	"l_4_1": 1.5, "l_4_2": 1.5, "l_4_3": 1.5, "l_4_4": 1.5,
	# S and Z (low base weight so they don't spam the board)
	"z_h": 0.7, "z_v": 0.7, "s_h": 0.7, "s_v": 0.7,
	# Pentominoes & Giants (high commitment)
	"line_5_h": 1.2, "line_5_v": 1.2,
	"big_l_1": 0.8, "big_l_2": 0.8, "big_l_3": 0.8, "big_l_4": 0.8,
	"square_3x3": 0.9
}

static func get_default_rng() -> RandomNumberGenerator:
	# Shared randomized RNG for normal play; seeded modes pass their own instance
	if _default_rng == null:
		_default_rng = RandomNumberGenerator.new()
		_default_rng.randomize()
	return _default_rng

static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	# Fisher-Yates driven by the given RNG (Array.shuffle() always uses the global RNG)
	for i in range(arr.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

static func _pick_weighted_shape(candidate_pool: Array, weights: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	if candidate_pool.is_empty():
		return {}
	var total_w: float = 0.0
	for s in candidate_pool:
		total_w += weights.get(s["id"], 1.0)
	if total_w <= 0.0:
		return candidate_pool[rng.randi() % candidate_pool.size()]
	var roll: float = rng.randf() * total_w
	var accum: float = 0.0
	for s in candidate_pool:
		accum += weights.get(s["id"], 1.0)
		if roll <= accum:
			return s
	return candidate_pool[-1]

# Classic difficulty curve: no change below PRESSURE_START points, full pressure at PRESSURE_FULL.
# Pressure trims the generator's help (line-clearing picks, gap fillers) and lets big pieces in sooner.
const PRESSURE_START: int = 2000
const PRESSURE_FULL: int = 12000

static func pressure_for_score(score: int) -> float:
	return clampf(float(score - PRESSURE_START) / float(PRESSURE_FULL - PRESSURE_START), 0.0, 1.0)

static func get_adaptive_trio(board, combo_count: int = 0, score: int = 0, combo_grace_moves: int = 3, rng: RandomNumberGenerator = null, pressure: float = 0.0) -> Array[Dictionary]:
	if rng == null:
		rng = get_default_rng()
	if board == null:
		return get_balanced_trio(rng)
		
	var fill: float = board.get_fill_ratio()
	
	# Calculate affinity and dynamic weight for every shape on this specific board
	var shape_weights: Dictionary = {}
	var shape_affinities: Dictionary = {}
	var all_fitting: Array[Dictionary] = []
	var clearing_shapes: Array[Dictionary] = []
	var near_line_shapes: Array[Dictionary] = []
	
	var solvers: Array[Dictionary] = []
	var triggers: Array[Dictionary] = []
	var hazards: Array[Dictionary] = []
	
	for s in SHAPES:
		if s["id"] == "dot_1x1":
			continue
		var id: String = s["id"]
		var cells_count: int = s["cells"].size()
		var aff: float = board.get_shape_affinity(s)
		shape_affinities[id] = aff
		
		if aff < 0.0:
			continue # Cannot fit anywhere on the board!
			
		all_fitting.append(s)
		
		var base_w: float = SHAPE_BASE_WEIGHTS.get(id, 1.0)
		# Multiplier exponentially boosts shapes that clear lines or advance near-complete lines
		var dyn_w: float = base_w * (1.0 + aff * 0.18 * (1.0 - 0.6 * pressure))
		shape_weights[id] = dyn_w
		
		if aff >= 100.0:
			clearing_shapes.append(s)
		elif aff >= 20.0:
			near_line_shapes.append(s)
			
		# Role 1: Solver (dominoes, 2x2 square, 3-cell corners)
		if cells_count <= 2 or id.begins_with("corner_2x2") or id == "square_2x2":
			solvers.append(s)
		# Role 2: Line Trigger (straight lines 3, 4, 5, T, L, Z, S)
		if id.begins_with("line_") or id.begins_with("t_") or id.begins_with("l_4") or id.begins_with("z_") or id.begins_with("s_"):
			triggers.append(s)
		# Role 3: Hazard / Large (3x3 big square, big 3x3 L, 5-lines)
		if id == "square_3x3" or id.begins_with("big_l") or id == "line_5_h" or id == "line_5_v":
			hazards.append(s)
			
	# Emergency fallback: If absolutely NO normal shape fits, check 1x1 dot
	if all_fitting.is_empty():
		var dot_shape = SHAPES[0] # dot_1x1
		if board.can_fit_shape(dot_shape):
			return [dot_shape, dot_shape, dot_shape]
		return [SHAPES[1], SHAPES[2], SHAPES[1]]
		
	var is_crisis: bool = (fill >= 0.70 or all_fitting.size() <= 4)
	var is_comfortable: bool = (fill <= 0.45 + 0.15 * pressure)
	var assist_chance = (0.95 - 0.3 * pressure) if combo_grace_moves <= 1 else (0.85 - 0.4 * pressure)
	var near_line_chance: float = 0.75 - 0.35 * pressure
	var hazard_chance: float = 0.5 + 0.3 * pressure

	# In crisis, large hazards are completely banned from slot C
	var safe_pool: Array[Dictionary] = []
	for s in all_fitting:
		if s["cells"].size() <= 4 and s["id"] != "square_3x3" and not s["id"].begins_with("big_l"):
			safe_pool.append(s)

	var grid: PackedByteArray = board.get_occupancy_snapshot()
	var trio: Array[Dictionary] = []

	for attempt in range(MAX_TRIO_ATTEMPTS):
		trio = []

		# =========================================================
		# SLOT A: The Solver (해결사 / 틈새 메우기)
		# =========================================================
		var piece_a: Dictionary = {}
		# Under pressure the "gap filler" slot sometimes becomes an ordinary pick
		if not solvers.is_empty() and rng.randf() >= 0.5 * pressure:
			piece_a = _pick_weighted_shape(solvers, shape_weights, rng)
		else:
			piece_a = _pick_weighted_shape(all_fitting, shape_weights, rng)
		trio.append(piece_a)

		# =========================================================
		# SLOT B: The Line Finisher / Clutch Savior (라인 완성기 / 구원 블록)
		# =========================================================
		var piece_b: Dictionary = {}
		var need_clutch = is_crisis and not clearing_shapes.is_empty()
		var should_clear = (combo_count > 0 or fill >= 0.40) and not clearing_shapes.is_empty() and (rng.randf() < assist_chance)

		if need_clutch or should_clear:
			piece_b = _pick_weighted_shape(clearing_shapes, shape_weights, rng)
		elif not near_line_shapes.is_empty() and rng.randf() < near_line_chance:
			# Give a piece that plugs a 6/8 or 7/8 near-complete line!
			piece_b = _pick_weighted_shape(near_line_shapes, shape_weights, rng)
		elif not triggers.is_empty():
			piece_b = _pick_weighted_shape(triggers, shape_weights, rng)
		else:
			piece_b = _pick_weighted_shape(all_fitting, shape_weights, rng)
		trio.append(piece_b)

		# =========================================================
		# SLOT C: Hazard / Cognitive Dilemma (전략적 압박 / 밸런서)
		# =========================================================
		var piece_c: Dictionary = {}
		if is_crisis:
			if not safe_pool.is_empty():
				piece_c = _pick_weighted_shape(safe_pool, shape_weights, rng)
			else:
				piece_c = _pick_weighted_shape(all_fitting, shape_weights, rng)
		elif is_comfortable and (score >= 400 or combo_count >= 2) and not hazards.is_empty() and rng.randf() < hazard_chance:
			# Challenge the player when they have open space
			piece_c = _pick_weighted_shape(hazards, shape_weights, rng)
		else:
			# General pool with affinity weighting (favors shapes that fit current gaps)
			piece_c = _pick_weighted_shape(all_fitting, shape_weights, rng)
		trio.append(piece_c)

		# =========================================================
		# Solvability Check (죽음 방지 검증): all 3 must be placeable in some order
		# =========================================================
		if can_place_all(grid, trio):
			last_generation_note = "roll_%d" % attempt
			# Shuffle order so the user cannot guess which slot corresponds to which role
			_shuffle(trio, rng)
			return trio

	# Rescue: swap slots (hazard slot first) for the smallest solvers until the set is solvable
	var rescue_pool: Array[Dictionary] = solvers.duplicate() if not solvers.is_empty() else all_fitting.duplicate()
	rescue_pool.sort_custom(func(a, b): return a["cells"].size() < b["cells"].size())
	for slot in [2, 1, 0]:
		for candidate in rescue_pool:
			var attempt_trio: Array[Dictionary] = trio.duplicate()
			attempt_trio[slot] = candidate
			if can_place_all(grid, attempt_trio):
				last_generation_note = "rescue"
				_shuffle(attempt_trio, rng)
				return attempt_trio
		trio[slot] = rescue_pool[0]

	var dot_shape: Dictionary = SHAPES[0]
	var dots: Array[Dictionary] = [dot_shape, dot_shape, dot_shape]
	if can_place_all(grid, dots):
		last_generation_note = "dots"
		return dots

	# Truly dead board: nothing can save it, so hand out the rescue set and let game over happen
	last_generation_note = "dead"
	_shuffle(trio, rng)
	return trio

# =========================================================
# Sequential placement solver on an 8x8 occupancy grid (index = x + y * 8)
# =========================================================

static func can_place_all(grid: PackedByteArray, shapes: Array, node_budget: int = SOLVE_NODE_BUDGET) -> bool:
	# True if every shape can be placed one after another in some order,
	# applying line clears between placements. Exceeding the budget counts as unsolvable.
	var budget: Array[int] = [node_budget]
	return _search_placements(grid, shapes, budget)

static func _search_placements(grid: PackedByteArray, remaining: Array, budget: Array[int]) -> bool:
	if remaining.is_empty():
		return true
	if budget[0] <= 0:
		return false

	var tried_ids: Dictionary = {}
	for i in range(remaining.size()):
		var shape: Dictionary = remaining[i]
		if tried_ids.has(shape["id"]):
			continue
		tried_ids[shape["id"]] = true

		var rest: Array = remaining.duplicate()
		rest.remove_at(i)
		var offsets: Array[Vector2i] = get_offsets(shape)
		var bounds: Rect2i = get_bounds(shape["cells"])

		for by in range(GRID_N - bounds.size.y + 1):
			for bx in range(GRID_N - bounds.size.x + 1):
				if not _fits_at(grid, offsets, bx, by):
					continue
				if rest.is_empty():
					return true
				budget[0] -= 1
				if budget[0] <= 0:
					return false
				if _search_placements(place_and_clear(grid, offsets, bx, by), rest, budget):
					return true
	return false

static func get_offsets(shape: Dictionary) -> Array[Vector2i]:
	var id: String = shape["id"]
	if _offset_cache.has(id):
		return _offset_cache[id]
	var bounds: Rect2i = get_bounds(shape["cells"])
	var offsets: Array[Vector2i] = []
	for c in shape["cells"]:
		offsets.append(Vector2i(c.x - bounds.position.x, c.y - bounds.position.y))
	_offset_cache[id] = offsets
	return offsets

static func _fits_at(grid: PackedByteArray, offsets: Array[Vector2i], bx: int, by: int) -> bool:
	for o in offsets:
		if grid[(bx + o.x) + (by + o.y) * GRID_N] != 0:
			return false
	return true

static func place_and_clear(grid: PackedByteArray, offsets: Array[Vector2i], bx: int, by: int) -> PackedByteArray:
	var g: PackedByteArray = grid.duplicate()
	var rows: Dictionary = {}
	var cols: Dictionary = {}
	for o in offsets:
		var x = bx + o.x
		var y = by + o.y
		g[x + y * GRID_N] = 1
		rows[y] = true
		cols[x] = true

	# Only rows/columns touched by the piece can have become full
	var full_rows: Array[int] = []
	var full_cols: Array[int] = []
	for y in rows:
		var full = true
		for x in range(GRID_N):
			if g[x + y * GRID_N] == 0:
				full = false
				break
		if full:
			full_rows.append(y)
	for x in cols:
		var full = true
		for y in range(GRID_N):
			if g[x + y * GRID_N] == 0:
				full = false
				break
		if full:
			full_cols.append(x)

	for y in full_rows:
		for x in range(GRID_N):
			g[x + y * GRID_N] = 0
	for x in full_cols:
		for y in range(GRID_N):
			g[x + y * GRID_N] = 0
	return g

static func get_seeded_trio(rng: RandomNumberGenerator) -> Array[Dictionary]:
	# Board-independent trio for the daily challenge: the same seed yields the same
	# sequence for every player. Weighted by base weights, at most one large piece per trio.
	var pool: Array[Dictionary] = []
	var small_pool: Array[Dictionary] = []
	for s in SHAPES:
		if s["id"] == "dot_1x1":
			continue
		pool.append(s)
		if s["category"] != "large":
			small_pool.append(s)
	
	var trio: Array[Dictionary] = []
	var has_large := false
	for i in range(3):
		var piece: Dictionary = _pick_weighted_shape(small_pool if has_large else pool, SHAPE_BASE_WEIGHTS, rng)
		if piece["category"] == "large":
			has_large = true
		trio.append(piece)
	_shuffle(trio, rng)
	last_generation_note = "seeded"
	return trio

static func get_balanced_trio(rng: RandomNumberGenerator = null) -> Array[Dictionary]:
	if rng == null:
		rng = get_default_rng()
	# Returns 3 balanced pieces (at least 1 small/medium, at most 1 large)
	var smalls: Array[Dictionary] = []
	var mediums: Array[Dictionary] = []
	var larges: Array[Dictionary] = []
	
	for s in SHAPES:
		match s["category"]:
			"small": smalls.append(s)
			"medium": mediums.append(s)
			"large": larges.append(s)
	
	var result: Array[Dictionary] = []
	
	# Slot 1: small or medium
	if rng.randf() < 0.4:
		result.append(smalls[rng.randi() % smalls.size()])
	else:
		result.append(mediums[rng.randi() % mediums.size()])
	
	# Slot 2: medium or large (35% large)
	if rng.randf() < 0.35:
		result.append(larges[rng.randi() % larges.size()])
	else:
		result.append(mediums[rng.randi() % mediums.size()])
	
	# Slot 3: small or medium
	if rng.randf() < 0.5:
		result.append(smalls[rng.randi() % smalls.size()])
	else:
		result.append(mediums[rng.randi() % mediums.size()])
	
	# Shuffle order so slots feel natural
	_shuffle(result, rng)
	return result

static func get_bounds(cells: Array) -> Rect2i:
	if cells.is_empty():
		return Rect2i(0, 0, 0, 0)
	var min_x = cells[0].x
	var max_x = cells[0].x
	var min_y = cells[0].y
	var max_y = cells[0].y
	for c in cells:
		min_x = mini(min_x, c.x)
		max_x = maxi(max_x, c.x)
		min_y = mini(min_y, c.y)
		max_y = maxi(max_y, c.y)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
