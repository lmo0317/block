extends Node
# Headless test for the drag magnet: a held piece snaps to the nearest free spot within
# Board.SNAP_RADIUS cells, the sprite slides onto it, and a drop lands there.
# Run: Godot_console.exe --headless --path . res://tests/test_magnet.tscn

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const USER_FILES: Array[String] = [
	"user://game_settings.json",
	"user://block_blast_save.cfg",
	"user://achievements.json",
]

var backups: Dictionary = {}
var failures: Array[String] = []
var main: MainGame
var board: Board

func _ready() -> void:
	Analytics.enabled = false
	for p in USER_FILES:
		if FileAccess.file_exists(p):
			backups[p] = FileAccess.get_file_as_bytes(p)
	_run.call_deferred()

func _run() -> void:
	main = MainScene.instantiate()
	add_child(main)
	await get_tree().process_frame
	main.profile_setup_modal.visible = false
	main._on_start_play_pressed()
	for i in range(60):
		if main.tray_pieces[0] != null and is_instance_valid(main.tray_pieces[0]):
			break
		await get_tree().create_timer(0.05).timeout
	board = main.board

	var dot: Dictionary = BlockData.SHAPES[0]
	_expect(dot["cells"].size() == 1, "SHAPES[0] is the single block")
	var bar: Dictionary = {}
	for s in BlockData.SHAPES:
		if s["cells"].size() == 3 and BlockData.get_bounds(s["cells"]).size == Vector2i(3, 1):
			bar = s
	_expect(not bar.is_empty(), "found a 1x3 bar")

	# Pure search: occupied (3,3); holding the dot 0.3 cells right of it snaps to (4,3)
	_clear_board([Vector2i(3, 3)])
	_expect_origin(dot, _center(dot, Vector2(3.3, 3)), Vector2i(4, 3), "0.3 off an occupied cell snaps to the free neighbor")
	_expect_origin(dot, _center(dot, Vector2(3, 3)), Vector2i(-1, -1), "neighbors 1 cell away are outside the magnet")
	_expect_origin(dot, _center(dot, Vector2(5, 5)), Vector2i(5, 5), "an exact free spot is kept")
	_expect_origin(dot, _center(dot, Vector2(5.4, 4.6)), Vector2i(5, 5), "nearest grid spot wins")
	_expect_origin(dot, _center(dot, Vector2(-0.5, 2)), Vector2i(0, 2), "half a cell off the left edge snaps in")
	_expect_origin(dot, _center(dot, Vector2(2, -3)), Vector2i(-1, -1), "far above the board does not snap")
	_expect_origin(bar, _center(bar, Vector2(5.6, 0)), Vector2i(5, 0), "a bar hanging off the right edge snaps in")

	# Through the real drag: the sprite slides onto the spot, and the drop lands there
	_clear_board([Vector2i(3, 3)])
	var piece := _fresh_piece(dot)
	var anchor := _center(dot, Vector2(3.3, 3))
	var screen := anchor - Vector2(0, BlockPiece.DRAG_OFFSET_Y)
	main.dragging_piece = piece
	piece.start_drag(screen)
	main._on_pointer_move(screen)
	_expect(piece.snapping, "piece is snapping while held near a free spot")
	await get_tree().create_timer(0.4).timeout
	var target := _center(dot, Vector2(4, 3))
	_expect(piece.global_position.distance_to(target) < 1.0, "sprite settled on the snapped spot: %s vs %s" % [piece.global_position, target])
	_expect(piece.placement_point() == anchor, "placement still follows the finger")
	main._on_pointer_up(screen, -1)
	await get_tree().process_frame
	_expect(board.grid_state[4][3] != null, "drop landed on the snapped spot")
	_expect(main.play_log.back() == ["p", dot["id"], 4, 3], "replay log records the snapped origin: %s" % str(main.play_log.back()))

	# Away from any spot the piece just follows the finger and goes back on release
	_clear_board([])
	piece = _fresh_piece(dot)
	screen = _center(dot, Vector2(2, -3)) - Vector2(0, BlockPiece.DRAG_OFFSET_Y)
	main.dragging_piece = piece
	piece.start_drag(screen)
	main._on_pointer_move(screen)
	await get_tree().process_frame
	_expect(not piece.snapping, "no snap far from the board")
	_expect(piece.global_position == piece.drag_anchor, "piece follows the finger when not snapping")
	main._on_pointer_up(screen, -1)
	await get_tree().process_frame
	_expect(board.get_occupied_count() == 0, "nothing placed when dropped off the board")

	# Leaving the magnet lets the piece go again
	_clear_board([])
	piece = _fresh_piece(dot)
	screen = _center(dot, Vector2(1, 1)) - Vector2(0, BlockPiece.DRAG_OFFSET_Y)
	main.dragging_piece = piece
	piece.start_drag(screen)
	main._on_pointer_move(screen)
	_expect(piece.snapping, "snaps on the board")
	screen = _center(dot, Vector2(1, -4)) - Vector2(0, BlockPiece.DRAG_OFFSET_Y)
	main._on_pointer_move(screen)
	_expect(not piece.snapping, "lets go when dragged away")
	await get_tree().create_timer(0.4).timeout
	_expect(piece.global_position.distance_to(piece.drag_anchor) < 1.0, "slid back under the finger")
	main._on_pointer_up(screen, -1)

	_finish()

func _clear_board(occupied: Array) -> void:
	board.reset_board()
	for c in occupied:
		board.grid_state[c.x][c.y] = "blue"

func _fresh_piece(shape: Dictionary) -> BlockPiece:
	var piece: BlockPiece = null
	for p in main.tray_pieces:
		if p != null and is_instance_valid(p):
			piece = p
			break
	if piece == null:
		main._spawn_new_tray()
		piece = main.tray_pieces[0]
	piece.setup(shape, piece.slot_index, piece.tray_position)
	return piece

# Global position of the shape's center when its top-left cell is at grid (fractional) pos
func _center(shape: Dictionary, pos: Vector2) -> Vector2:
	var b: Rect2i = BlockData.get_bounds(shape["cells"])
	var half := Vector2((b.size.x * Board.CELL_SPACING - Board.CELL_GAP) * 0.5, (b.size.y * Board.CELL_SPACING - Board.CELL_GAP) * 0.5)
	return board.to_global(pos * Board.CELL_SPACING + half)

func _expect_origin(shape: Dictionary, center: Vector2, origin: Vector2i, what: String) -> void:
	var p: Dictionary = board.find_placement(shape, center)
	var got := Vector2i(-1, -1)
	if p["valid"]:
		got = p["origin"]
	_expect(got == origin, "%s (got %s, expected %s)" % [what, got, origin])

func _expect(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)

func _finish() -> void:
	for p in USER_FILES:
		if backups.has(p):
			var f := FileAccess.open(p, FileAccess.WRITE)
			f.store_buffer(backups[p])
			f.close()
		elif FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	if failures.is_empty():
		print("MAGNET OK")
	else:
		for f in failures:
			printerr("FAIL: " + f)
	get_tree().quit(0 if failures.is_empty() else 1)
