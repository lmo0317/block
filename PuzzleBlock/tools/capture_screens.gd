extends Node
# Saves a PNG of every main screen so the UI can be reviewed without clicking through the game.
# Needs a real window (the headless renderer draws nothing):
#   Godot_console.exe --path . --resolution 720x1280 res://tools/capture_screens.tscn
# Output folder: CAPTURE_DIR environment variable, default user://captures.
# Local save files are backed up first and restored at the end.

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const USER_FILES: Array[String] = [
	"user://block_blast_save.cfg",
	"user://game_settings.json",
	"user://player_profile.json",
	"user://adventure_progress.json",
	"user://achievements.json",
]

var backups: Dictionary = {}
var out_dir: String = ""
var main: MainGame

func _ready() -> void:
	Analytics.enabled = false
	out_dir = OS.get_environment("CAPTURE_DIR")
	if out_dir.is_empty():
		out_dir = ProjectSettings.globalize_path("user://captures")
	DirAccess.make_dir_recursive_absolute(out_dir)
	for p in USER_FILES:
		if FileAccess.file_exists(p):
			backups[p] = FileAccess.get_file_as_bytes(p)
	_run.call_deferred()

func _run() -> void:
	main = MainScene.instantiate()
	add_child(main)
	SoundManager.is_muted = true
	main.profile_setup_modal.visible = false
	await _shot("01_home")

	main.profile_setup_modal.open()
	await _shot("02_profile_setup")
	main.profile_setup_modal.visible = false

	main._open_adventure_select()
	await _shot("03_adventure_select")
	main._open_home_screen()

	main._open_settings()
	await _shot("04_settings_game")
	main.settings_modal._show_tab("profile")
	await _shot("05_settings_profile")
	main.settings_modal._show_tab("achievements")
	await _shot("06_settings_achievements")
	main.settings_modal.close()
	await _wait(0.3)

	if main.btn_leaderboard.visible:
		main._open_leaderboard()
		await _shot("07_leaderboard", 2.0)
		main.leaderboard_modal.close()
		await _wait(0.3)

	main._on_start_play_pressed()
	await _shot("08_game_classic", 1.5)
	main._show_combo_banner(4)
	main._spawn_combo_popup(2, 240, main.board.to_global(Vector2(Board.BOARD_WIDTH / 2.0, Board.BOARD_HEIGHT / 2.0)))
	await _shot("09_game_combo", 0.35)
	main._hide_combo_banner()

	main.revive_modal.open()
	await _shot("10_revive")
	main.revive_modal.is_active = false
	main.revive_modal.visible = false

	main.go_final_score.text = "12,480"
	main.go_best_score.text = main._best_line("BEST", 15200)
	main.go_new_badge.visible = false
	main.game_over_panel.visible = true
	main.game_over_panel.modulate.a = 1.0
	await _shot("11_game_over")
	main.game_over_panel.visible = false

	main.start_screen.visible = false
	main.start_new_game(false, "daily")
	await _shot("12_game_daily", 1.5)

	_finish()

func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

func _shot(name: String, delay: float = 0.6) -> void:
	await _wait(delay)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("captured ", name)

func _finish() -> void:
	for p in USER_FILES:
		if backups.has(p):
			var f := FileAccess.open(p, FileAccess.WRITE)
			f.store_buffer(backups[p])
			f.close()
		elif FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	get_tree().quit()
