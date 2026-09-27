class_name BlockPiece
extends Node2D

signal drag_started(piece: BlockPiece)
signal drag_moved(piece: BlockPiece, global_pos: Vector2)
signal drag_ended(piece: BlockPiece, global_pos: Vector2)

const CELL_SIZE: float = 74.0
const TRAY_SCALE: float = 0.62
const DRAG_OFFSET_Y: float = -110.0

var shape_data: Dictionary = {}
var slot_index: int = -1
var tray_position: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var is_dimmed: bool = false
var touch_index: int = -1

var cell_sprites: Array[Sprite2D] = []
var local_bounds: Rect2 = Rect2()

@onready var cells_container: Node2D = $Cells

func setup(data: Dictionary, slot_idx: int, slot_pos: Vector2) -> void:
	shape_data = data
	slot_index = slot_idx
	tray_position = slot_pos
	position = slot_pos
	scale = Vector2.ONE * TRAY_SCALE
	modulate.a = 1.0
	
	_build_visuals()

func _build_visuals() -> void:
	for c in cell_sprites:
		c.queue_free()
	cell_sprites.clear()
	
	var cells: Array = shape_data["cells"]
	var color_name: String = shape_data["color"]
	var tex_path: String = "res://assets/sprites/block_%s.png" % color_name
	var tex: Texture2D = load(tex_path)
	
	# Calculate bounding box
	var bounds: Rect2i = BlockData.get_bounds(cells)
	var center_offset: Vector2 = Vector2(
		-bounds.size.x * CELL_SIZE * 0.5,
		-bounds.size.y * CELL_SIZE * 0.5
	)
	
	for c in cells:
		var sp = Sprite2D.new()
		sp.texture = tex
		# Center cells within this piece
		var local_x = (c.x - bounds.position.x) * CELL_SIZE + CELL_SIZE * 0.5 + center_offset.x
		var local_y = (c.y - bounds.position.y) * CELL_SIZE + CELL_SIZE * 0.5 + center_offset.y
		sp.position = Vector2(local_x, local_y)
		cells_container.add_child(sp)
		cell_sprites.append(sp)
	
	local_bounds = Rect2(
		center_offset.x,
		center_offset.y,
		bounds.size.x * CELL_SIZE,
		bounds.size.y * CELL_SIZE
	)

func is_point_inside(global_pt: Vector2) -> bool:
	var local_pt = to_local(global_pt)
	# Expand touch hit area for better touch UX on mobile
	var hit_rect = local_bounds.grow(35.0)
	return hit_rect.has_point(local_pt)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if not is_dragging and is_point_inside(event.position):
				touch_index = event.index
				_start_drag(event.position)
				get_viewport().set_input_as_handled()
		else:
			if is_dragging and (event.index == touch_index or touch_index == -1):
				_end_drag(event.position)
				get_viewport().set_input_as_handled()
				
	elif event is InputEventScreenDrag:
		if is_dragging and (event.index == touch_index or touch_index == -1):
			_move_drag(event.position)
			get_viewport().set_input_as_handled()
			
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if not is_dragging and is_point_inside(event.position):
					touch_index = -1
					_start_drag(event.position)
					get_viewport().set_input_as_handled()
			else:
				if is_dragging:
					_end_drag(event.position)
					get_viewport().set_input_as_handled()
					
	elif event is InputEventMouseMotion:
		if is_dragging and touch_index == -1:
			_move_drag(event.position)
			get_viewport().set_input_as_handled()

func _start_drag(touch_pos: Vector2) -> void:
	is_dragging = true
	z_index = 100 # Put on top of everything
	
	SoundManager.play_pickup()
	
	# Instantly align position to touch with offset
	position = touch_pos + Vector2(0, DRAG_OFFSET_Y)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.1)
	
	drag_started.emit(self)

func _move_drag(touch_pos: Vector2) -> void:
	position = touch_pos + Vector2(0, DRAG_OFFSET_Y)
	drag_moved.emit(self, global_position)

func _end_drag(touch_pos: Vector2) -> void:
	is_dragging = false
	drag_ended.emit(self, global_position)

func return_to_tray() -> void:
	z_index = 10
	SoundManager.play_invalid()
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "position", tray_position, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE * TRAY_SCALE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var target_alpha = 0.45 if is_dimmed else 1.0
	tw.tween_property(self, "modulate:a", target_alpha, 0.2)

func snap_to_board() -> void:
	# Placed on board, clean up
	queue_free()

func set_dimmed(dimmed: bool) -> void:
	is_dimmed = dimmed
	if not is_dragging:
		var target_alpha = 0.42 if dimmed else 1.0
		var tw = create_tween()
		tw.tween_property(self, "modulate:a", target_alpha, 0.25)
