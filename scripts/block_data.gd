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

static func get_adaptive_trio(board, combo_count: int = 0, score: int = 0, combo_grace_moves: int = 3) -> Array[Dictionary]:
	if board == null:
		return get_balanced_trio()
		
	var fill: float = board.get_fill_ratio()
	
	# Categorize shapes into the 3 Canonical Block Blast Roles
	var solvers: Array[Dictionary] = []
	var triggers: Array[Dictionary] = []
	var hazards: Array[Dictionary] = []
	var normal_shapes: Array[Dictionary] = []
	
	for s in SHAPES:
		if s["id"] == "dot_1x1":
			continue
		normal_shapes.append(s)
		var id: String = s["id"]
		var cells_count: int = s["cells"].size()
		
		# Role 1: Solver (1x2 dominoes, 2x2 square, small 3-cell corners)
		if cells_count <= 2 or id.begins_with("corner_2x2") or id == "square_2x2":
			solvers.append(s)
			
		# Role 2: Line Trigger (straight lines 3, 4, 5, T-shapes, L/J, S/Z)
		if id.begins_with("line_") or id.begins_with("t_") or id.begins_with("l_4") or id.begins_with("z_") or id.begins_with("s_"):
			triggers.append(s)
			
		# Role 3: Hazard / Large (3x3 big square, big 3x3 L-corners, 1x5 straight line)
		if id == "square_3x3" or id.begins_with("big_l") or id == "line_5_h" or id == "line_5_v":
			hazards.append(s)

	# Query Board for currently fitting and line-clearing shapes
	var all_fitting: Array[Dictionary] = board.get_fitting_shapes(normal_shapes)
	
	# Emergency fallback: If absolutely NO normal shape fits, check 1x1 dot
	if all_fitting.is_empty():
		var dot_shape = SHAPES[0] # dot_1x1
		if board.can_fit_shape(dot_shape):
			return [dot_shape, dot_shape, dot_shape]
		return [solvers[0], solvers[1], solvers[0]]
		
	var solvers_fitting: Array[Dictionary] = board.get_fitting_shapes(solvers)
	var triggers_fitting: Array[Dictionary] = board.get_fitting_shapes(triggers)
	var hazards_fitting: Array[Dictionary] = board.get_fitting_shapes(hazards)
	var clearing_shapes: Array[Dictionary] = board.find_clearing_shapes(all_fitting)
	
	var is_crisis: bool = (fill >= 0.70 or all_fitting.size() <= 4)
	var is_comfortable: bool = (fill <= 0.45)
	
	var trio: Array[Dictionary] = []
	
	# =========================================================
	# SLOT A: The Solver (해결사 / 소형)
	# =========================================================
	var piece_a: Dictionary = {}
	if not solvers_fitting.is_empty():
		if is_crisis:
			var very_small: Array[Dictionary] = []
			for s in solvers_fitting:
				if s["cells"].size() <= 3:
					very_small.append(s)
			if not very_small.is_empty():
				piece_a = very_small[randi() % very_small.size()]
			else:
				piece_a = solvers_fitting[randi() % solvers_fitting.size()]
		else:
			piece_a = solvers_fitting[randi() % solvers_fitting.size()]
	else:
		piece_a = all_fitting[randi() % all_fitting.size()]
	trio.append(piece_a)
	
	# =========================================================
	# SLOT B: The Line Trigger / Clutch Savior (라인 트리거 / 구원 블록)
	# =========================================================
	var piece_b: Dictionary = {}
	var must_give_clutch = is_crisis and not clearing_shapes.is_empty()
	var assist_chance = 0.95 if combo_grace_moves <= 1 else 0.82
	var assist_combo = (combo_count > 0) and not clearing_shapes.is_empty() and (randf() < assist_chance)
	
	if must_give_clutch or assist_combo or (not clearing_shapes.is_empty() and randf() < 0.60):
		# Prioritize shapes that trigger an immediate line clear!
		var non_hazard_clearing: Array[Dictionary] = []
		for s in clearing_shapes:
			if s["id"] != "square_3x3" and not s["id"].begins_with("big_l"):
				non_hazard_clearing.append(s)
		if not non_hazard_clearing.is_empty():
			piece_b = non_hazard_clearing[randi() % non_hazard_clearing.size()]
		else:
			piece_b = clearing_shapes[randi() % clearing_shapes.size()]
	elif not triggers_fitting.is_empty():
		piece_b = triggers_fitting[randi() % triggers_fitting.size()]
	elif not solvers_fitting.is_empty():
		piece_b = solvers_fitting[randi() % solvers_fitting.size()]
	else:
		piece_b = all_fitting[randi() % all_fitting.size()]
	trio.append(piece_b)
	
	# =========================================================
	# SLOT C: Hazard / Cognitive Dilemma (위험 요소 / 대형 인지적 압박)
	# =========================================================
	var piece_c: Dictionary = {}
	
	if is_crisis:
		# (DDA Rule: In crisis, large hazard probability is 0% to prevent unfair loss!)
		if not solvers_fitting.is_empty():
			piece_c = solvers_fitting[randi() % solvers_fitting.size()]
		elif not triggers_fitting.is_empty():
			piece_c = triggers_fitting[randi() % triggers_fitting.size()]
		else:
			piece_c = all_fitting[randi() % all_fitting.size()]
	elif is_comfortable and (score >= 400 or combo_count >= 2) and not hazards_fitting.is_empty() and randf() < 0.65:
		# (DDA Rule: Intentional Kill Timing - Inject 3x3 or Big L when board is spacious to test space management!)
		piece_c = hazards_fitting[randi() % hazards_fitting.size()]
	else:
		# Standard distribution: 25% hazard, 45% trigger, 30% solver
		var roll = randf()
		if roll < 0.25 and not hazards_fitting.is_empty() and fill < 0.60:
			piece_c = hazards_fitting[randi() % hazards_fitting.size()]
		elif roll < 0.70 and not triggers_fitting.is_empty():
			piece_c = triggers_fitting[randi() % triggers_fitting.size()]
		elif not solvers_fitting.is_empty():
			piece_c = solvers_fitting[randi() % solvers_fitting.size()]
		else:
			piece_c = all_fitting[randi() % all_fitting.size()]
	trio.append(piece_c)
	
	# =========================================================
	# Solvability Check (죽음 방지 검증 루프)
	# =========================================================
	# Guarantee that at least ONE piece among the 3 can be placed on the current board
	var has_valid_move = false
	for p in trio:
		if board.can_fit_shape(p):
			has_valid_move = true
			break
			
	if not has_valid_move:
		if not solvers_fitting.is_empty():
			trio[0] = solvers_fitting[randi() % solvers_fitting.size()]
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
