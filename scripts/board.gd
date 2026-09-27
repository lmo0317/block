class_name Board
extends Node2D

signal lines_cleared(line_count: int, cell_count: int, combo_bonus_pos: Vector2)

const GRID_SIZE: int = 8
const CELL_SIZE: float = 76.0
const CELL_GAP: float = 2.0
const CELL_SPACING: float = 78.0 # CELL_SIZE + CELL_GAP

const BOARD_WIDTH: float = GRID_SIZE * CELL_SPACING - CELL_GAP # 622.0
const BOARD_HEIGHT: float = BOARD_WIDTH

var cell_blast_scene: PackedScene = preload("res://scenes/cell_blast.tscn")
var slot_texture: Texture2D = preload("res://assets/sprites/cell_slot.png")
var ghost_texture: Texture2D = preload("res://assets/sprites/cell_ghost.png")

# 8x8 Grid state: stores String color name or null
var grid_state: Array = []
# 8x8 Sprite references: stores Sprite2D or null
var placed_sprites: Array = []
# 8x8 Ghost preview sprites
var ghost_sprites: Array = []

@onready var slots_container: Node2D = $Slots
@onready var ghosts_container: Node2D = $Ghosts
@onready var pieces_container: Node2D = $Pieces
@onready var effects_container: Node2D = $Effects

func _ready() -> void:
	_init_grid()

func _init_grid() -> void:
	grid_state.clear()
	placed_sprites.clear()
	ghost_sprites.clear()
	
	for x in range(GRID_SIZE):
		var col_state = []
		var col_placed = []
		var col_ghost = []
		for y in range(GRID_SIZE):
			col_state.append(null)
			col_placed.append(null)
			
			var cell_pos = get_cell_position(x, y)
			
			# 1. Slot background sprite
			var slot_sp = Sprite2D.new()
			slot_sp.texture = slot_texture
			slot_sp.position = cell_pos
			slots_container.add_child(slot_sp)
			
			# 2. Ghost preview sprite
			var ghost_sp = Sprite2D.new()
			ghost_sp.texture = ghost_texture
			ghost_sp.position = cell_pos
			ghost_sp.visible = false
			ghosts_container.add_child(ghost_sp)
			col_ghost.append(ghost_sp)
			
		grid_state.append(col_state)
		placed_sprites.append(col_placed)
		ghost_sprites.append(col_ghost)

func get_cell_position(grid_x: int, grid_y: int) -> Vector2:
	return Vector2(
		grid_x * CELL_SPACING + 38.0,
		grid_y * CELL_SPACING + 38.0
	)

func get_target_placement(shape_data: Dictionary, piece: BlockPiece) -> Dictionary:
	var cells: Array = shape_data["cells"]
	var bounds: Rect2i = BlockData.get_bounds(cells)
	
	var half_w = (bounds.size.x * CELL_SPACING - CELL_GAP) * 0.5
	var half_h = (bounds.size.y * CELL_SPACING - CELL_GAP) * 0.5
	
	var piece_local_pos = to_local(piece.global_position)
	var piece_top_left_x = piece_local_pos.x - half_w
	var piece_top_left_y = piece_local_pos.y - half_h
	
	var base_gx = int(round(piece_top_left_x / CELL_SPACING))
	var base_gy = int(round(piece_top_left_y / CELL_SPACING))
	
	var target_coords: Array[Vector2i] = []
	
	for c in cells:
		var gx = base_gx + (c.x - bounds.position.x)
		var gy = base_gy + (c.y - bounds.position.y)
		
		# Out of board bounds
		if gx < 0 or gx >= GRID_SIZE or gy < 0 or gy >= GRID_SIZE:
			return {"valid": false}
			
		# Already occupied
		if grid_state[gx][gy] != null:
			return {"valid": false}
			
		target_coords.append(Vector2i(gx, gy))
		
	return {"valid": true, "coords": target_coords}

func update_ghost_preview(shape_data: Dictionary, piece: BlockPiece) -> bool:
	hide_ghost_preview()
	if not SettingsManager.ghost_piece_enabled:
		return false
	
	var placement = get_target_placement(shape_data, piece)
	if placement["valid"]:
		var coords: Array[Vector2i] = placement["coords"]
		var col_name: String = shape_data["color"]
		var tint = _get_color_tint(col_name)
		tint.a = 0.85
		for coord in coords:
			var sp: Sprite2D = ghost_sprites[coord.x][coord.y]
			sp.visible = true
			sp.modulate = tint
		return true
	return false

func hide_ghost_preview() -> void:
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			ghost_sprites[x][y].visible = false

func place_piece(shape_data: Dictionary, piece: BlockPiece) -> bool:
	var placement = get_target_placement(shape_data, piece)
	if not placement["valid"]:
		return false
	
	hide_ghost_preview()
	
	var coords: Array[Vector2i] = placement["coords"]
	var col_name: String = shape_data["color"]
	var tex_path: String = "res://assets/sprites/block_%s.png" % col_name
	var tex: Texture2D = load(tex_path)
	
	for coord in coords:
		var x = coord.x
		var y = coord.y
		grid_state[x][y] = col_name
		
		var sp = Sprite2D.new()
		sp.texture = tex
		sp.position = get_cell_position(x, y)
		pieces_container.add_child(sp)
		placed_sprites[x][y] = sp
		
		# Pop animation on place
		sp.scale = Vector2.ONE * 0.65
		var tw = create_tween()
		tw.tween_property(sp, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	SoundManager.play_place()
	return true

func check_and_clear_lines() -> Dictionary:
	var full_rows: Array[int] = []
	var full_cols: Array[int] = []
	
	# Check rows
	for y in range(GRID_SIZE):
		var row_full = true
		for x in range(GRID_SIZE):
			if grid_state[x][y] == null:
				row_full = false
				break
		if row_full:
			full_rows.append(y)
			
	# Check columns
	for x in range(GRID_SIZE):
		var col_full = true
		for y in range(GRID_SIZE):
			if grid_state[x][y] == null:
				col_full = false
				break
		if col_full:
			full_cols.append(x)
	
	var total_lines = full_rows.size() + full_cols.size()
	if total_lines == 0:
		return {"lines": 0, "cells": 0, "center": Vector2.ZERO}
	
	# Collect unique cells to clear
	var cells_to_clear: Dictionary = {}
	for y in full_rows:
		for x in range(GRID_SIZE):
			cells_to_clear[Vector2i(x, y)] = true
	for x in full_cols:
		for y in range(GRID_SIZE):
			cells_to_clear[Vector2i(x, y)] = true
			
	var avg_pos = Vector2.ZERO
	for coord in cells_to_clear.keys():
		var x = coord.x
		var y = coord.y
		var cell_world_pos = to_global(get_cell_position(x, y))
		avg_pos += cell_world_pos
		
		var col_name = grid_state[x][y]
		var tex_path = "res://assets/sprites/block_%s.png" % (col_name if col_name else "blue")
		var block_tex: Texture2D = load(tex_path)
		
		# Free placed sprite
		if placed_sprites[x][y] != null:
			placed_sprites[x][y].queue_free()
			placed_sprites[x][y] = null
			
		grid_state[x][y] = null
		
		# Spawn cell blast particle effect
		var blast: CellBlast = cell_blast_scene.instantiate()
		blast.position = get_cell_position(x, y)
		effects_container.add_child(blast)
		blast.start_blast(block_tex)
		
	avg_pos /= max(1, cells_to_clear.size())
	
	lines_cleared.emit(total_lines, cells_to_clear.size(), avg_pos)
	return {
		"lines": total_lines,
		"cells": cells_to_clear.size(),
		"center": avg_pos
	}

func can_fit_shape(shape_data: Dictionary) -> bool:
	var cells: Array = shape_data["cells"]
	var bounds: Rect2i = BlockData.get_bounds(cells)
	
	var max_base_x = GRID_SIZE - bounds.size.x
	var max_base_y = GRID_SIZE - bounds.size.y
	
	for base_x in range(max_base_x + 1):
		for base_y in range(max_base_y + 1):
			var fits = true
			for c in cells:
				var gx = base_x + (c.x - bounds.position.x)
				var gy = base_y + (c.y - bounds.position.y)
				if grid_state[gx][gy] != null:
					fits = false
					break
			if fits:
				return true
				
	return false
	
func get_fill_ratio() -> float:
	var occupied: int = 0
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if grid_state[x][y] != null:
				occupied += 1
	return float(occupied) / float(GRID_SIZE * GRID_SIZE)

func get_occupied_count() -> int:
	var occupied: int = 0
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if grid_state[x][y] != null:
				occupied += 1
	return occupied

func get_fitting_shapes(candidate_shapes: Array) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for shape in candidate_shapes:
		if can_fit_shape(shape):
			results.append(shape)
	return results

func find_clearing_shapes(candidate_shapes: Array) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var row_counts: Array[int] = []
	var col_counts: Array[int] = []
	row_counts.resize(GRID_SIZE)
	col_counts.resize(GRID_SIZE)
	for i in range(GRID_SIZE):
		row_counts[i] = 0
		col_counts[i] = 0
		
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if grid_state[x][y] != null:
				col_counts[x] += 1
				row_counts[y] += 1
				
	for shape in candidate_shapes:
		var cells: Array = shape["cells"]
		var bounds: Rect2i = BlockData.get_bounds(cells)
		var max_base_x = GRID_SIZE - bounds.size.x
		var max_base_y = GRID_SIZE - bounds.size.y
		var can_clear = false
		
		for base_x in range(max_base_x + 1):
			if can_clear:
				break
			for base_y in range(max_base_y + 1):
				var fits = true
				for c in cells:
					var gx = base_x + (c.x - bounds.position.x)
					var gy = base_y + (c.y - bounds.position.y)
					if grid_state[gx][gy] != null:
						fits = false
						break
				if fits:
					var added_rows = {}
					var added_cols = {}
					for c in cells:
						var gx = base_x + (c.x - bounds.position.x)
						var gy = base_y + (c.y - bounds.position.y)
						added_rows[gy] = added_rows.get(gy, 0) + 1
						added_cols[gx] = added_cols.get(gx, 0) + 1
						
					for gy in added_rows:
						if row_counts[gy] + added_rows[gy] == GRID_SIZE:
							can_clear = true
							break
					if not can_clear:
						for gx in added_cols:
							if col_counts[gx] + added_cols[gx] == GRID_SIZE:
								can_clear = true
								break
				if can_clear:
					break
					
		if can_clear:
			results.append(shape)
			
	return results

func reset_board() -> void:
	hide_ghost_preview()
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			grid_state[x][y] = null
			if placed_sprites[x][y] != null:
				placed_sprites[x][y].queue_free()
				placed_sprites[x][y] = null

func _get_color_tint(color_name: String) -> Color:
	match color_name:
		"blue": return Color(0.22, 0.74, 0.97)
		"orange": return Color(0.98, 0.57, 0.24)
		"green": return Color(0.20, 0.83, 0.60)
		"purple": return Color(0.75, 0.52, 0.99)
		"yellow": return Color(0.99, 0.88, 0.28)
		"red": return Color(0.97, 0.44, 0.44)
		"cyan": return Color(0.13, 0.83, 0.93)
		"pink": return Color(0.96, 0.45, 0.71)
		_: return Color.WHITE
