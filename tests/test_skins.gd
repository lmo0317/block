extends Node
# Headless test for T-10: every skin has all block textures, the choice persists,
# and switching skins re-textures the board and tray.
# Run: Godot_console.exe --headless --path . res://tests/test_skins.tscn

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const USER_FILES: Array[String] = [
	"user://game_settings.json",
	"user://block_blast_save.cfg",
	"user://achievements.json",
]

var backups: Dictionary = {}
var failures: Array[String] = []

func _ready() -> void:
	Analytics.enabled = false
	_backup_user_files()
	_run.call_deferred()

func _run() -> void:
	for s in BlockSkins.SKINS:
		for c in BlockSkins.COLORS:
			var path: String = BlockSkins._path(s["id"], c)
			_expect(ResourceLoader.exists(path), "missing texture " + path)
			_expect(BlockSkins.texture(c, s["id"]) != null, "texture failed to load: %s/%s" % [s["id"], c])

	SettingsManager.set_skin("neon")
	SettingsManager.block_skin = "classic"
	SettingsManager.load_settings()
	_expect(SettingsManager.block_skin == "neon", "skin choice not saved")
	SettingsManager.set_skin("no_such_skin")
	_expect(SettingsManager.block_skin == "neon", "invalid skin was accepted")
	SettingsManager.set_skin("classic")

	var main: MainGame = MainScene.instantiate()
	add_child(main)
	await get_tree().process_frame
	main.profile_setup_modal.visible = false
	main._on_start_play_pressed()
	await get_tree().process_frame

	# Classic deals the first set after the start pattern drops in
	for i in range(60):
		if main.tray_pieces[0] != null and is_instance_valid(main.tray_pieces[0]):
			break
		await get_tree().create_timer(0.05).timeout
	# Place the first tray piece on a free spot (the start pattern already fills some cells)
	var piece: BlockPiece = main.tray_pieces[0]
	var bounds: Rect2i = BlockData.get_bounds(piece.shape_data["cells"])
	var offsets: Array[Vector2i] = BlockData.get_offsets(piece.shape_data)
	var grid: PackedByteArray = main.board.get_occupancy_snapshot()
	var spot := Vector2i(-1, -1)
	for y in range(8 - bounds.size.y + 1):
		for x in range(8 - bounds.size.x + 1):
			if spot.x < 0 and offsets.all(func(o): return grid[(x + o.x) + (y + o.y) * 8] == 0):
				spot = Vector2i(x, y)
	var half := Vector2((bounds.size.x * Board.CELL_SPACING - Board.CELL_GAP) * 0.5, (bounds.size.y * Board.CELL_SPACING - Board.CELL_GAP) * 0.5)
	piece.global_position = main.board.to_global(Vector2(spot) * Board.CELL_SPACING + half)
	main.dragging_piece = piece
	main._on_pointer_up(Vector2.ZERO, -1)
	await get_tree().process_frame

	main.settings_modal.open()
	await get_tree().process_frame
	_expect(main.settings_modal.skin_buttons.size() == BlockSkins.SKINS.size(), "skin picker buttons")
	main.settings_modal._on_skin_pressed("candy")
	main._on_settings_closed()

	var placed := 0
	var wrong := 0
	for x in range(8):
		for y in range(8):
			var sp = main.board.placed_sprites[x][y]
			if sp != null:
				placed += 1
				if sp.texture != BlockSkins.texture(main.board.grid_state[x][y], "candy"):
					wrong += 1
	_expect(placed > 0 and wrong == 0, "board blocks re-skinned (%d placed, %d wrong)" % [placed, wrong])
	var tray_ok := true
	for p in main.tray_pieces:
		if p != null and is_instance_valid(p):
			for c in p.cell_sprites:
				if c.texture != BlockSkins.texture(p.shape_data["color"], "candy"):
					tray_ok = false
	_expect(tray_ok, "tray pieces re-skinned")

	_restore_user_files()
	SettingsManager.load_settings()
	if failures.is_empty():
		print("SKINS OK")
	else:
		for f in failures:
			printerr("FAIL: " + f)
	get_tree().quit(0 if failures.is_empty() else 1)

func _expect(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)

func _backup_user_files() -> void:
	for p in USER_FILES:
		if FileAccess.file_exists(p):
			backups[p] = FileAccess.get_file_as_bytes(p)

func _restore_user_files() -> void:
	for p in USER_FILES:
		if backups.has(p):
			var f := FileAccess.open(p, FileAccess.WRITE)
			f.store_buffer(backups[p])
			f.close()
		elif FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
