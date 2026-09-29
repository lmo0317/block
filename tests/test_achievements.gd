extends Node
# Headless test for T-09: achievement unlocks and persistence, settings tabs, drag-to-scroll.
# Run: Godot_console.exe --headless --path . res://tests/test_achievements.tscn

const SettingsScene: PackedScene = preload("res://scenes/settings_modal.tscn")
const USER_FILES: Array[String] = [
	"user://achievements.json",
	"user://player_profile.json",
	"user://game_settings.json",
]

var backups: Dictionary = {}
var failures: Array[String] = []
var unlocked_events: Array[String] = []

func _ready() -> void:
	Analytics.enabled = false
	_backup_user_files()
	_run.call_deferred()

func _run() -> void:
	if FileAccess.file_exists(Achievements.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Achievements.SAVE_PATH))
	Achievements.load_data()
	Achievements.achievement_unlocked.connect(func(d): unlocked_events.append(d["id"]))

	Achievements.add_stat("total_lines", 1)
	_expect(unlocked_events == ["first_clear"], "first line clear unlocks first_clear only: %s" % str(unlocked_events))

	unlocked_events.clear()
	Achievements.max_stat("max_combo", 12)
	Achievements.max_stat("max_combo", 8) # lower value must not reduce the stat
	_expect(unlocked_events == ["combo_5", "combo_10"], "combo 12 unlocks combo_5 and combo_10: %s" % str(unlocked_events))
	_expect(Achievements.get_stat("max_combo") == 12, "max_stat keeps the maximum")
	_expect(not Achievements.is_unlocked("combo_20"), "combo_20 stays locked")

	Achievements.record_daily_day("2026-09-29")
	Achievements.record_daily_day("2026-09-29")
	_expect(Achievements.get_stat("daily_days") == 1, "same day counts once")

	Achievements.load_data()
	_expect(Achievements.is_unlocked("combo_10") and Achievements.get_stat("total_lines") == 1, "progress survives reload")
	_expect(Achievements.DEFS.all(func(d): return d.has("name") and not d.has("title")), "achievements use name (titles removed)")
	
	# Settings: tabs show one page at a time
	var settings: SettingsModal = SettingsScene.instantiate()
	add_child(settings)
	await get_tree().process_frame
	settings.open()
	await get_tree().process_frame
	_expect(settings.options_box.visible and not settings.achievement_box.visible and not settings.profile_box.visible, "game tab shows only options")
	settings._show_tab("achievements")
	await get_tree().process_frame
	_expect(settings.achievement_box.visible and not settings.options_box.visible, "achievements tab shows only achievements")
	var rows := settings.achievement_list.get_children().filter(func(c): return not c.is_queued_for_deletion())
	_expect(rows.size() == Achievements.DEFS.size(), "settings lists %d achievements" % rows.size())
	_expect(settings.achievement_summary.text == "달성 3 / %d" % Achievements.DEFS.size(), "summary text: " + settings.achievement_summary.text)
	
	# Drag anywhere on the list scrolls it. Headless Godot does not route mouse input to the GUI,
	# so events go straight to DragScroll here; tap-vs-drag on buttons is checked in the Web build.
	await get_tree().create_timer(0.3).timeout
	var ds: DragScroll = null
	for c in settings.scroll.get_children():
		if c is DragScroll:
			ds = c
	_expect(ds != null, "settings scroll has DragScroll attached")
	if ds:
		var rect: Rect2 = settings.scroll.get_global_rect()
		var from := rect.get_center() + Vector2(0, 150)
		_feed_drag(ds, from, from - Vector2(0, 300))
		_expect(settings.scroll.scroll_vertical > 100, "drag scrolled the achievements list (scroll=%d)" % settings.scroll.scroll_vertical)
		settings.scroll.scroll_vertical = 0
		_feed_drag(ds, from, from - Vector2(0, 6))
		_expect(settings.scroll.scroll_vertical == 0 and not ds.dragging, "a short move under the threshold is not a drag")
	
	_restore_user_files()
	Achievements.load_data()
	if failures.is_empty():
		print("ACHIEVEMENTS OK")
	else:
		for f in failures:
			printerr("FAIL: " + f)
	get_tree().quit(0 if failures.is_empty() else 1)

func _feed_drag(ds: DragScroll, from: Vector2, to: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = from
	ds._input(down)
	for i in range(1, 7):
		var m := InputEventMouseMotion.new()
		m.position = from.lerp(to, i / 6.0)
		ds._input(m)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = to
	ds._input(up)

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
