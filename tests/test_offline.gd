extends Node
# Headless test for store (offline) builds: ranking UI is hidden, a finished game sends nothing,
# and the Android back button leaves a game for home.
# Run: BLOCK_OFFLINE=1 Godot_console.exe --headless --path . res://tests/test_offline.tscn

const MainScene: PackedScene = preload("res://scenes/main.tscn")

var failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	_expect(not LeaderboardManager.is_online(), "run with BLOCK_OFFLINE=1")
	var main: MainGame = MainScene.instantiate()
	add_child(main)
	await get_tree().process_frame
	main.profile_setup_modal.visible = false

	_expect(not main.btn_leaderboard.visible, "header ranking button hidden")
	_expect(not main.start_screen.ranking_button.visible, "home ranking button hidden")
	_expect(not main.start_screen.rank_value.visible, "home rank label hidden")

	main._on_start_play_pressed()
	await get_tree().create_timer(1.5).timeout
	_expect(not main.start_screen.visible, "game started")
	var before := LeaderboardManager.get_child_count()
	main._trigger_game_over()
	await get_tree().create_timer(1.0).timeout
	_expect(LeaderboardManager.get_child_count() == before, "no score request sent")
	_expect(not main.go_btn_view_rank.visible, "game over ranking button hidden")
	_expect(Analytics.buffer.is_empty(), "no analytics buffered")

	main.start_new_game(true)
	await get_tree().create_timer(1.5).timeout
	main._notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	_expect(main.start_screen.visible, "back button returns to home")
	main.settings_modal.open()
	await get_tree().create_timer(0.3).timeout
	main._notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	await get_tree().create_timer(0.3).timeout
	_expect(not main.settings_modal.visible, "back button closes settings")

	if failures.is_empty():
		print("OFFLINE OK")
	else:
		for f in failures:
			printerr("FAIL: " + f)
	get_tree().quit(0 if failures.is_empty() else 1)

func _expect(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)
