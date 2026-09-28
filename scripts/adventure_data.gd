class_name AdventureData
extends RefCounted
# Adventure stage definitions and local progress (see docs/ADVENTURE_MODE.md).
# Layout chars: "." empty, lowercase color = block, uppercase color = block with a gem.
# Colors: r red, b blue, y yellow, p purple, o orange, g green, c cyan, k pink.

const PROGRESS_PATH: String = "user://adventure_progress.json"

const COLOR_CODES: Dictionary = {
	"r": "red", "b": "blue", "y": "yellow", "p": "purple",
	"o": "orange", "g": "green", "c": "cyan", "k": "pink"
}

const EMPTY: Array[String] = ["........", "........", "........", "........", "........", "........", "........", "........"]

const STAGES: Array[Dictionary] = [
	{"id": 1, "name": "첫 걸음", "goal": {"type": "score", "target": 300}, "moves": 0, "stars": [12, 20], "layout": EMPTY},
	{"id": 2, "name": "줄 맞추기", "goal": {"type": "lines", "target": 3}, "moves": 18, "stars": [10, 14], "layout": EMPTY},
	{"id": 3, "name": "콤보 연습", "goal": {"type": "score", "target": 800}, "moves": 0, "stars": [22, 32], "layout": EMPTY},
	{"id": 4, "name": "빈틈 채우기", "goal": {"type": "lines", "target": 4}, "moves": 12, "stars": [5, 8], "layout": [
		"........",
		"........",
		"........",
		"........",
		"........",
		"bbbb.bbb",
		"oo.ooooo",
		"ggggg.gg",
	]},
	{"id": 5, "name": "첫 보석", "goal": {"type": "gems", "target": 2}, "moves": 15, "stars": [4, 8], "layout": [
		"........",
		"........",
		"........",
		"........",
		"........",
		"........",
		"rrRr.rrr",
		"ccc.cCcc",
	]},
	{"id": 6, "name": "양쪽 벽", "goal": {"type": "lines", "target": 6}, "moves": 22, "stars": [14, 18], "layout": [
		"........",
		"........",
		"p......p",
		"pp....pp",
		"ppp..ppp",
		"........",
		"........",
		"........",
	]},
	{"id": 7, "name": "보석 세 개", "goal": {"type": "gems", "target": 3}, "moves": 24, "stars": [14, 19], "layout": [
		"........",
		"........",
		"...Y....",
		"..yyy...",
		"........",
		"........",
		"kk.kkKkk",
		"bBbb.bbb",
	]},
	{"id": 8, "name": "흩어진 돌", "goal": {"type": "score", "target": 1400}, "moves": 32, "stars": [22, 27], "layout": [
		"........",
		".o....o.",
		"........",
		"........",
		"........",
		"........",
		".o....o.",
		"........",
	]},
	{"id": 9, "name": "네 모서리", "goal": {"type": "gems", "target": 4}, "moves": 20, "stars": [8, 14], "layout": [
		"G......G",
		"g......g",
		"........",
		"........",
		"........",
		"........",
		"g......g",
		"G......G",
	]},
	{"id": 10, "name": "징검다리", "goal": {"type": "lines", "target": 8}, "moves": 28, "stars": [18, 23], "layout": [
		"r.r.r.r.",
		"........",
		".b.b.b.b",
		"........",
		"y.y.y.y.",
		"........",
		".c.c.c.c",
		"........",
	]},
	{"id": 11, "name": "빈 상자", "goal": {"type": "score", "target": 1700}, "moves": 34, "stars": [24, 29], "layout": [
		"........",
		"........",
		"..pppp..",
		"..p..p..",
		"..p..p..",
		"..pppp..",
		"........",
		"........",
	]},
	{"id": 12, "name": "쌍둥이 보석", "goal": {"type": "gems", "target": 4}, "moves": 24, "stars": [14, 19], "layout": [
		"........",
		"...OO...",
		"...oo...",
		"........",
		"........",
		"...oo...",
		"...OO...",
		"........",
	]},
	{"id": 13, "name": "무거운 바닥", "goal": {"type": "lines", "target": 10}, "moves": 28, "stars": [20, 24], "layout": [
		"........",
		"........",
		"........",
		"........",
		"gg.gg.gg",
		"g.gg.gg.",
		".gg.gg.g",
		"gg.gg.gg",
	]},
	{"id": 14, "name": "기둥 사이", "goal": {"type": "score", "target": 2500}, "moves": 40, "stars": [28, 34], "layout": [
		"c......c",
		"c......c",
		"c......c",
		"........",
		"........",
		"c......c",
		"c......c",
		"c......c",
	]},
	{"id": 15, "name": "다섯 방향", "goal": {"type": "gems", "target": 5}, "moves": 32, "stars": [18, 25], "layout": [
		"....Y...",
		"....y...",
		"..P.....",
		"R......B",
		"r......b",
		"........",
		"...k....",
		"...K....",
	]},
	{"id": 16, "name": "촘촘한 격자", "goal": {"type": "lines", "target": 12}, "moves": 32, "stars": [22, 27], "layout": [
		"bb.bb.bb",
		"........",
		".oo.oo.o",
		"........",
		"bb.bb.bb",
		"........",
		".oo.oo.o",
		"........",
	]},
	{"id": 17, "name": "왕관", "goal": {"type": "gems", "target": 6}, "moves": 32, "stars": [18, 25], "layout": [
		"Rr....rR",
		"r......r",
		"........",
		"...GG...",
		"........",
		"........",
		"r......r",
		"Rr....rR",
	]},
	{"id": 18, "name": "십자로", "goal": {"type": "score", "target": 3200}, "moves": 42, "stars": [30, 36], "layout": [
		"...pp...",
		"...pp...",
		"...pp...",
		"ppp..ppp",
		"ppp..ppp",
		"...pp...",
		"...pp...",
		"...pp...",
	]},
	{"id": 19, "name": "황금 사다리", "goal": {"type": "gems", "target": 6}, "moves": 30, "stars": [14, 22], "layout": [
		"yy.yy.yy",
		"Y......Y",
		"........",
		"..yYYy..",
		"........",
		"........",
		"Y......Y",
		"yy.yy.yy",
	]},
	{"id": 20, "name": "최종 시험", "goal": {"type": "gems", "target": 6}, "moves": 40, "stars": [26, 33], "layout": [
		"G.b..b.G",
		"........",
		"b.B..B.b",
		"........",
		"........",
		"b.B..B.b",
		"........",
		"G.b..b.G",
	]},
]

static func get_stage(stage_id: int) -> Dictionary:
	for s in STAGES:
		if s["id"] == stage_id:
			return s
	return {}

static func stage_count() -> int:
	return STAGES.size()

static func goal_text(goal: Dictionary, progress: int = -1) -> String:
	var label: String = {"score": "점수", "lines": "줄", "gems": "보석"}.get(goal["type"], "목표")
	if progress < 0:
		return "%s %d" % [label, goal["target"]]
	return "%s %d/%d" % [label, mini(progress, goal["target"]), goal["target"]]

static func stars_for(stage: Dictionary, moves_used: int) -> int:
	var th: Array = stage["stars"]
	if moves_used <= th[0]:
		return 3
	if moves_used <= th[1]:
		return 2
	return 1

static func star_text(stars: int) -> String:
	return "★".repeat(stars) + "☆".repeat(3 - stars)

# =========================================================
# Local progress: {"unlocked": int, "stars": {"<id>": int}}
# =========================================================

static func load_progress() -> Dictionary:
	var progress := {"unlocked": 1, "stars": {}}
	if not FileAccess.file_exists(PROGRESS_PATH):
		return progress
	var file = FileAccess.open(PROGRESS_PATH, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if data is Dictionary:
			progress["unlocked"] = clampi(int(data.get("unlocked", 1)), 1, stage_count())
			if data.get("stars") is Dictionary:
				progress["stars"] = data["stars"]
	return progress

static func record_result(stage_id: int, stars: int) -> bool:
	# Saves a clear; returns true when it beats the previous star record
	var progress := load_progress()
	var key := str(stage_id)
	var prev: int = int(progress["stars"].get(key, 0))
	var improved := stars > prev
	if improved:
		progress["stars"][key] = stars
	progress["unlocked"] = clampi(maxi(progress["unlocked"], stage_id + 1), 1, stage_count())
	var file = FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(progress))
	return improved
