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

static func _pick_weighted_shape(candidate_pool: Array, weights: Dictionary) -> Dictionary:
	if candidate_pool.is_empty():
		return {}
	var total_w: float = 0.0
	for s in candidate_pool:
		total_w += weights.get(s["id"], 1.0)
	if total_w <= 0.0:
		return candidate_pool[randi() % candidate_pool.size()]
	var roll: float = randf() * total_w
	var accum: float = 0.0
	for s in candidate_pool:
		accum += weights.get(s["id"], 1.0)
		if roll <= accum:
			return s
	return candidate_pool[-1]

static func get_adaptive_trio(board, combo_count: int = 0, score: int = 0, combo_grace_moves: int = 3) -> Array[Dictionary]:
	if board == null:
		return get_balanced_trio()
		
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
		var dyn_w: float = base_w * (1.0 + aff * 0.18)
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
	var is_comfortable: bool = (fill <= 0.45)
	
	var trio: Array[Dictionary] = []
	
	# =========================================================
	# SLOT A: The Solver (해결사 / 틈새 메우기)
	# =========================================================
	var piece_a: Dictionary = {}
	if not solvers.is_empty():
		piece_a = _pick_weighted_shape(solvers, shape_weights)
	else:
		piece_a = _pick_weighted_shape(all_fitting, shape_weights)
	trio.append(piece_a)
	
	# =========================================================
	# SLOT B: The Line Finisher / Clutch Savior (라인 완성기 / 구원 블록)
	# =========================================================
	var piece_b: Dictionary = {}
	var need_clutch = is_crisis and not clearing_shapes.is_empty()
	var assist_chance = 0.95 if combo_grace_moves <= 1 else 0.85
	var should_clear = (combo_count > 0 or fill >= 0.40) and not clearing_shapes.is_empty() and (randf() < assist_chance)
	
	if need_clutch or should_clear:
		piece_b = _pick_weighted_shape(clearing_shapes, shape_weights)
	elif not near_line_shapes.is_empty() and randf() < 0.75:
		# Give a piece that plugs a 6/8 or 7/8 near-complete line!
		piece_b = _pick_weighted_shape(near_line_shapes, shape_weights)
	elif not triggers.is_empty():
		piece_b = _pick_weighted_shape(triggers, shape_weights)
	else:
		piece_b = _pick_weighted_shape(all_fitting, shape_weights)
	trio.append(piece_b)
	
	# =========================================================
	# SLOT C: Hazard / Cognitive Dilemma (전략적 압박 / 밸런서)
	# =========================================================
	var piece_c: Dictionary = {}
	if is_crisis:
		# In crisis, large hazards are completely banned! Give another helper
		var safe_pool = []
		for s in all_fitting:
			if s["cells"].size() <= 4 and s["id"] != "square_3x3" and not s["id"].begins_with("big_l"):
				safe_pool.append(s)
		if not safe_pool.is_empty():
			piece_c = _pick_weighted_shape(safe_pool, shape_weights)
		else:
			piece_c = _pick_weighted_shape(all_fitting, shape_weights)
	elif is_comfortable and (score >= 400 or combo_count >= 2) and not hazards.is_empty() and randf() < 0.50:
		# Challenge the player when they have open space
		piece_c = _pick_weighted_shape(hazards, shape_weights)
	else:
		# General pool with affinity weighting (favors shapes that fit current gaps)
		piece_c = _pick_weighted_shape(all_fitting, shape_weights)
	trio.append(piece_c)
	
	# =========================================================
	# Solvability Check (죽음 방지 검증 루프)
	# =========================================================
	var has_valid_move = false
	for p in trio:
		if board.can_fit_shape(p):
			has_valid_move = true
			break
			
	if not has_valid_move:
		if not solvers.is_empty():
			trio[0] = _pick_weighted_shape(solvers, shape_weights)
		elif not all_fitting.is_empty():
			trio[0] = all_fitting[0]
		else:
			var dot_shape = SHAPES[0]
			if board.can_fit_shape(dot_shape):
				trio[0] = dot_shape
				
	# Shuffle order so the user cannot guess which slot corresponds to which role
	trio.shuffle()
	return trio

static func get_balanced_trio() -> Array[Dictionary]:
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
	if randf() < 0.4:
		result.append(smalls[randi() % smalls.size()])
	else:
		result.append(mediums[randi() % mediums.size()])
	
	# Slot 2: medium or large (35% large)
	if randf() < 0.35:
		result.append(larges[randi() % larges.size()])
	else:
		result.append(mediums[randi() % mediums.size()])
	
	# Slot 3: small or medium
	if randf() < 0.5:
		result.append(smalls[randi() % smalls.size()])
	else:
		result.append(mediums[randi() % mediums.size()])
	
	# Shuffle order so slots feel natural
	result.shuffle()
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
