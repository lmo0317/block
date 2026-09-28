class_name AchievementManagerClass
extends Node
# Tracks lifetime stats and unlocks achievements; each achievement doubles as a selectable title.
# Saved locally in user://achievements.json.

signal achievement_unlocked(def: Dictionary)

const SAVE_PATH: String = "user://achievements.json"

# stat: which lifetime stat is compared against target
const DEFS: Array[Dictionary] = [
	{"id": "first_clear", "title": "첫 폭발", "desc": "처음으로 줄 지우기", "stat": "total_lines", "target": 1},
	{"id": "lines_100", "title": "라인 수집가", "desc": "누적 100줄 지우기", "stat": "total_lines", "target": 100},
	{"id": "lines_1000", "title": "라인 마스터", "desc": "누적 1,000줄 지우기", "stat": "total_lines", "target": 1000},
	{"id": "combo_5", "title": "콤보 입문", "desc": "한 판에 5콤보 달성", "stat": "max_combo", "target": 5},
	{"id": "combo_10", "title": "콤보 장인", "desc": "한 판에 10콤보 달성", "stat": "max_combo", "target": 10},
	{"id": "combo_20", "title": "콤보의 신", "desc": "한 판에 20콤보 달성", "stat": "max_combo", "target": 20},
	{"id": "perfect_1", "title": "완벽주의자", "desc": "퍼펙트 클리어 1회", "stat": "perfect_clears", "target": 1},
	{"id": "perfect_10", "title": "청소왕", "desc": "퍼펙트 클리어 10회", "stat": "perfect_clears", "target": 10},
	{"id": "score_5k", "title": "5천점 돌파", "desc": "클래식 5,000점 달성", "stat": "best_score", "target": 5000},
	{"id": "score_20k", "title": "2만점 돌파", "desc": "클래식 20,000점 달성", "stat": "best_score", "target": 20000},
	{"id": "score_50k", "title": "전설의 점수", "desc": "클래식 50,000점 달성", "stat": "best_score", "target": 50000},
	{"id": "games_10", "title": "단골 손님", "desc": "10판 플레이", "stat": "games_played", "target": 10},
	{"id": "games_100", "title": "블록 중독", "desc": "100판 플레이", "stat": "games_played", "target": 100},
	{"id": "new_best_5", "title": "자기 경신", "desc": "최고 기록 5번 경신", "stat": "new_bests", "target": 5},
	{"id": "daily_7", "title": "매일 도전자", "desc": "서로 다른 7일 챌린지 참여", "stat": "daily_days", "target": 7},
	{"id": "adventure_10", "title": "모험가", "desc": "어드벤처 별 10개", "stat": "adventure_stars", "target": 10},
	{"id": "adventure_60", "title": "별 수집 완료", "desc": "어드벤처 별 60개 전부", "stat": "adventure_stars", "target": 60},
]

var stats: Dictionary = {}
var unlocked: Dictionary = {} # id -> unix time
var daily_day_keys: Array = []

func _ready() -> void:
	load_data()

func get_stat(stat_name: String) -> int:
	return int(stats.get(stat_name, 0))

func add_stat(stat_name: String, amount: int) -> void:
	if amount == 0:
		return
	stats[stat_name] = get_stat(stat_name) + amount
	_check_unlocks()

func max_stat(stat_name: String, value: int) -> void:
	if value > get_stat(stat_name):
		stats[stat_name] = value
		_check_unlocks()

func record_daily_day(day_key: String) -> void:
	if day_key.is_empty() or daily_day_keys.has(day_key):
		return
	daily_day_keys.append(day_key)
	stats["daily_days"] = daily_day_keys.size()
	_check_unlocks()

func is_unlocked(id: String) -> bool:
	return unlocked.has(id)

func unlocked_titles() -> Array[String]:
	var out: Array[String] = []
	for d in DEFS:
		if unlocked.has(d["id"]):
			out.append(d["title"])
	return out

func _check_unlocks() -> void:
	var newly: Array[Dictionary] = []
	for d in DEFS:
		if not unlocked.has(d["id"]) and get_stat(d["stat"]) >= int(d["target"]):
			unlocked[d["id"]] = int(Time.get_unix_time_from_system())
			newly.append(d)
	save_data()
	for d in newly:
		achievement_unlocked.emit(d)

func load_data() -> void:
	stats = {}
	unlocked = {}
	daily_day_keys = []
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if data is Dictionary:
			if data.get("stats") is Dictionary:
				stats = data["stats"]
			if data.get("unlocked") is Dictionary:
				unlocked = data["unlocked"]
			if data.get("daily_days") is Array:
				daily_day_keys = data["daily_days"]

func save_data() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"stats": stats, "unlocked": unlocked, "daily_days": daily_day_keys}))
