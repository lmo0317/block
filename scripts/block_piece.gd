class_name BlockPiece
extends Node2D

const CELL_SIZE: float = 76.0
const CELL_GAP: float = 2.0
const CELL_SPACING: float = 78.0 # CELL_SIZE + CELL_GAP
const TRAY_SCALE: float = 0.62
const DRAG_OFFSET_Y: float = -110.0

var shape_data: Dictionary = {}
var slot_index: int = -1
var tray_position: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var is_dimmed: bool = false

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
	is_dragging = false
	
	_build_visuals()

func _build_visuals() -> void:
	for c in cell_sprites:
		c.queue_free()
	cell_sprites.clear()
	
	var cells: Array = shape_data["cells"]
	var color_name: String = shape_data["color"]
	var tex_path: String = "res://assets/sprites/block_%s.png" % color_name
	var tex: Texture2D = load(tex_path)
	
	var bounds: Rect2i = BlockData.get_bounds(cells)
	var half_w = (bounds.size.x * CELL_SPACING - CELL_GAP) * 0.5
	var half_h = (bounds.size.y * CELL_SPACING - CELL_GAP) * 0.5
	
	for c in cells:
		var sp = Sprite2D.new()
		sp.texture = tex
		var lx = (c.x - bounds.position.x) * CELL_SPACING + 38.0 - half_w
		var ly = (c.y - bounds.position.y) * CELL_SPACING + 38.0 - half_h
		sp.position = Vector2(lx, ly)
		cells_container.add_child(sp)
		cell_sprites.append(sp)
	
	local_bounds = Rect2(-half_w, -half_h, half_w * 2.0, half_h * 2.0)

func is_point_inside(global_pt: Vector2) -> bool:
	if global_position.distance_to(global_pt) <= 95.0:
		return true
	var local_pt = to_local(global_pt)
	var hit_rect = local_bounds.grow(40.0)
	return hit_rect.has_point(local_pt)

func start_drag(screen_pos: Vector2) -> void:
	is_dragging = true
	z_index = 100
	SoundManager.play_pickup()
	
	global_position = screen_pos + Vector2(0, DRAG_OFFSET_Y)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.1)

func update_drag(screen_pos: Vector2) -> void:
	global_position = screen_pos + Vector2(0, DRAG_OFFSET_Y)

func return_to_tray() -> void:
	is_dragging = false
	z_index = 10
	SoundManager.play_invalid()
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "position", tray_position, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE * TRAY_SCALE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var target_alpha = 0.42 if is_dimmed else 1.0
	tw.tween_property(self, "modulate:a", target_alpha, 0.2)

func snap_to_board() -> void:
	is_dragging = false
	queue_free()

func set_dimmed(dimmed: bool) -> void:
	is_dimmed = dimmed
	if not is_dragging:
		var target_alpha = 0.42 if dimmed else 1.0
		var tw = create_tween()
		tw.tween_property(self, "modulate:a", target_alpha, 0.25)
