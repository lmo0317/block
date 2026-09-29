extends Node
# Exports the game rules the server needs for replay validation to tools/block_rules.json:
# shapes, spawn weights, scoring constants, and reference daily sequences / string hashes so the
# server's port of Godot's RNG and hash() can be checked against the engine itself.
# Run after changing shapes or scoring:
#   Godot_console.exe --headless --path . res://tools/export_rules.tscn

const OUT_PATH: String = "res://tools/block_rules.json"
const SAMPLE_DAYS: Array[String] = ["2026-09-29", "2000-01-01", "2031-12-31"]
const SAMPLE_TRIOS: int = 40

func _ready() -> void:
	var shapes: Array = []
	for s in BlockData.SHAPES:
		shapes.append({
			"id": s["id"],
			"category": s["category"],
			"cells": s["cells"].map(func(c): return [c.x, c.y])
		})

	var samples := {}
	var hashes := {}
	for day in SAMPLE_DAYS:
		var seed_text: String = "block-daily-" + day
		hashes[seed_text] = hash(seed_text)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(seed_text)
		var trios: Array = []
		for i in range(SAMPLE_TRIOS):
			trios.append(BlockData.get_seeded_trio(rng).map(func(s): return s["id"]))
		samples[day] = trios

	# Raw RNG outputs for a fixed seed, to pin down randi/randf/randi_range behaviour
	var probe := RandomNumberGenerator.new()
	probe.seed = 12345
	var rng_probe := {"seed": 12345, "randi": [], "randf": [], "randi_range_0_7": []}
	for i in range(5):
		rng_probe["randi"].append(probe.randi())
	for i in range(5):
		rng_probe["randf"].append(probe.randf())
	for i in range(5):
		rng_probe["randi_range_0_7"].append(probe.randi_range(0, 7))

	var rules := {
		"version": 1,
		"grid_size": BlockData.GRID_N,
		"shapes": shapes,
		"base_weights": BlockData.SHAPE_BASE_WEIGHTS,
		"scoring": {
			"line_base": MainGame.LINE_SCORE_BASE,
			"combo_alpha": MainGame.COMBO_ALPHA,
			"combo_bonus_linear": MainGame.COMBO_BONUS_LINEAR,
			"combo_bonus_quadratic": MainGame.COMBO_BONUS_QUADRATIC,
			"combo_grace": MainGame.MAX_COMBO_GRACE,
			"perfect_base": MainGame.PERFECT_CLEAR_BASE,
			"fever_combo": MainGame.FEVER_COMBO,
			"fever_multiplier": MainGame.FEVER_MULTIPLIER
		},
		"revive_max_cells": Board.REVIVE_MAX_CELLS,
		"daily_seed_prefix": "block-daily-",
		"daily_samples": samples,
		"hash_samples": hashes,
		"rng_probe": rng_probe
	}
	var f := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(rules, "  "))
	f.close()
	print("exported rules to " + ProjectSettings.globalize_path(OUT_PATH))
	get_tree().quit()
