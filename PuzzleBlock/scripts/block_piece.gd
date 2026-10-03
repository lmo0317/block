class_name BlockPiece
extends Node2D

const CELL_SIZE: float = 76.0
const CELL_GAP: float = 2.0
const CELL_SPACING: float = 78.0 # CELL_SIZE + CELL_GAP
const DEFAULT_TRAY_SCALE: float = 0.58
const DRAG_OFFSET_Y: float = -110.0
const SNAP_SETTLE: float = 32.0 # how fast the piece slides onto a magnet spot (per second, exponential)

var shape_data: Dictionary = {}
var slot_index: int = -1
var tray_position: Vector2 = Vector2.ZERO
var tray_scale: float = 0.58
var is_dragging: bool = false
var is_dimmed: bool = false

# While dragging the piece follows drag_anchor (under the finger), or sits on snap_center when the
# board's magnet has a spot for it. visual_offset makes the jump between the two a quick slide.
var drag_anchor: Vector2 = Vector2.ZERO
var snapping: bool = false
var snap_center: Vector2 = Vector2.ZERO
var visual_offset: Vector2 = Vector2.ZERO
var move_tween: Tween = null

var cell_sprites: Array[Sprite2D] = []
var local_bounds: Rect2 = Rect2()

@onready var cells_container: Node2D = $Cells

func setup(data: Dictionary, slot_idx: int, slot_pos: Vector2) -> void:
	shape_data = data
	slot_index = slot_idx
	tray_position = slot_pos
	position = slot_pos
	
	_build_visuals()
	
	# Calculate dynamic fit scale so piece never overflows the slot box
	var bounds: Rect2i = BlockData.get_bounds(shape_data["cells"])
	var raw_w: float = float(bounds.size.x * CELL_SPACING - CELL_GAP)
	var raw_h: float = float(bounds.size.y * CELL_SPACING - CELL_GAP)
	var max_dim: float = max(raw_w, raw_h)
	
	var base_scale: float = DEFAULT_TRAY_SCALE
	# Slot plate width is 200px; cap piece visual size at 164px for generous padding
	if max_dim * base_scale > 164.0:
		tray_scale = 164.0 / max_dim
	else:
		tray_scale = base_scale
		
	scale = Vector2.ONE * tray_scale
	modulate.a = 1.0
	is_dragging = false

func _build_visuals() -> void:
	for c in cell_sprites:
		c.queue_free()
	cell_sprites.clear()
	
	var cells: Array = shape_data["cells"]
	var color_name: String = shape_data["color"]
	var tex: Texture2D = BlockSkins.texture(color_name)
	
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

func refresh_skin() -> void:
	var tex: Texture2D = BlockSkins.texture(shape_data["color"])
	for sp in cell_sprites:
		sp.texture = tex

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
	# Grabbed again while still flying back to the tray: stop that tween so it can't pull the piece away
	if move_tween != null and move_tween.is_valid():
		move_tween.kill()
	
	drag_anchor = screen_pos + Vector2(0, DRAG_OFFSET_Y)
	snapping = false
	visual_offset = Vector2.ZERO
	global_position = drag_anchor
	
	var tw = create_tween().set_parallel(true)
	move_tween = tw
	tw.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.1)

func update_drag(screen_pos: Vector2) -> void:
	drag_anchor = screen_pos + Vector2(0, DRAG_OFFSET_Y)
	global_position = _drag_target() + visual_offset

func placement_point() -> Vector2:
	# Placement follows the finger, not the snapped sprite, so the magnet can let go again
	return drag_anchor if is_dragging else global_position

# Called after every drag move with the board's placement for this piece. Returns true when the
# piece just locked onto a new spot.
func set_snap(placement: Dictionary) -> bool:
	var on: bool = placement.get("valid", false)
	var center: Vector2 = placement["center"] if on else Vector2.ZERO
	if on == snapping and center == snap_center:
		return false
	# Keep the sprite where it is and let the offset slide it to the new target
	var before: Vector2 = global_position
	snapping = on
	snap_center = center
	visual_offset = before - _drag_target()
	global_position = before
	if on:
		var tw = create_tween()
		cells_container.scale = Vector2.ONE * 1.06
		tw.tween_property(cells_container, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return on

func _drag_target() -> Vector2:
	return snap_center if snapping else drag_anchor

func _process(delta: float) -> void:
	if not is_dragging or visual_offset == Vector2.ZERO:
		return
	visual_offset *= exp(-SNAP_SETTLE * delta)
	if visual_offset.length() < 0.5:
		visual_offset = Vector2.ZERO
	global_position = _drag_target() + visual_offset

func return_to_tray() -> void:
	is_dragging = false
	snapping = false
	visual_offset = Vector2.ZERO
	cells_container.scale = Vector2.ONE
	z_index = 10
	SoundManager.play_invalid()
	
	var tw = create_tween().set_parallel(true)
	move_tween = tw
	tw.tween_property(self, "position", tray_position, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE * tray_scale, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
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
