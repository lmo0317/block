extends Node
# Headless test for T-09: achievement unlocks, persistence, settings list and title picker.
# Needs a local server because choosing a title syncs the profile:
#   BLOCK_API_HOST=http://127.0.0.1:3000 Godot_console.exe --headless --path . res://tests/test_achievements.tscn

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
	if OS.get_environment("BLOCK_API_HOST").is_empty():
		push_error("Set BLOCK_API_HOST to a local server before running this test")
		get_tree().quit(2)
		return
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
	_expect(Achievements.unlocked_titles() == ["첫 폭발", "콤보 입문", "콤보 장인"], "titles in definition order: %s" % str(Achievements.unlocked_titles()))

	# Settings screen lists every achievement and offers unlocked titles
	var settings: SettingsModal = SettingsScene.instantiate()
	add_child(settings)
	await get_tree().process_frame
	settings.open()
	await get_tree().process_frame
	var rows := settings.achievement_list.get_children().filter(func(c): return not c.is_queued_for_deletion())
	_expect(rows.size() == Achievements.DEFS.size(), "settings lists %d achievements" % rows.size())
	_expect(settings.achievement_summary.text == "달성 3 / %d" % Achievements.DEFS.size(), "summary text: " + settings.achievement_summary.text)
	_expect(settings.title_option.item_count == 4, "title picker has none + 3 titles")
	settings.title_option.select(3)
	settings._on_title_selected(3)
	_expect(LeaderboardManager.title == "콤보 장인", "picking a title sets it on the profile")

	# Wait for the profile sync to reach the local server, then check the ranking returns the title
	await get_tree().create_timer(1.0).timeout
	LeaderboardManager.submit_score(1234, Callable())
	await get_tree().create_timer(1.0).timeout
	var got: Array = [null]
	LeaderboardManager.fetch_leaderboard("all", 100, func(res): got[0] = res)
	for i in range(30):
		if got[0] != null:
			break
		await get_tree().create_timer(0.1).timeout
	var mine: Array = []
	if got[0] is Dictionary:
		mine = got[0].get("leaderboard", []).filter(func(r): return r.get("is_me", false))
	_expect(mine.size() == 1 and mine[0].get("title", "") == "콤보 장인", "ranking row carries the title")

	LeaderboardManager.title = ""
	_restore_user_files()
	Achievements.load_data()
	if failures.is_empty():
		print("ACHIEVEMENTS OK")
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
