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
		"id": "s_h",
		"category": "medium",
		"color": "green",
		"cells": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)]
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
	},
	# 13. Plus / Cross (5 cells)
	{
		"id": "plus_5",
		"category": "large",
		"color": "blue",
		"cells": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]
	},
	# 14. 2x3 Rectangles (6 cells)
	{
		"id": "rect_2x3_h",
		"category": "large",
		"color": "cyan",
		"cells": [
			Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
			Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)
		]
	},
	{
		"id": "rect_2x3_v",
		"category": "large",
		"color": "cyan",
		"cells": [
			Vector2i(0, 0), Vector2i(1, 0),
			Vector2i(0, 1), Vector2i(1, 1),
			Vector2i(0, 2), Vector2i(1, 2)
		]
	}
]

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
