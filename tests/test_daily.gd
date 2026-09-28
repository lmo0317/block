extends Node
# Headless test for T-07: the daily challenge sequence depends only on the day key.
# Run: Godot_console.exe --headless --path . res://tests/test_daily.tscn

const TRIOS: int = 30

var failures: Array[String] = []

func _ready() -> void:
	var day := LeaderboardManager.get_kst_day_key()
	if not RegEx.create_from_string("^\\d{4}-\\d{2}-\\d{2}$").search(day):
		failures.append("bad day key: " + day)

	var a := _sequence(day)
	var b := _sequence(day)
	var other := _sequence("2000-01-01")
	if a != b:
		failures.append("same day produced different sequences")
	if a == other:
		failures.append("different days produced the same sequence")

	# Seeded draws must not touch the global RNG used by classic mode
	seed(7)
	var before := randi()
	seed(7)
	_sequence(day)
	if randi() != before:
		failures.append("seeded trio consumed the global RNG")

	for trio in a:
		var large := 0
		for id in trio:
			if _category(id) == "large":
				large += 1
			if id == "dot_1x1":
				failures.append("dot in daily trio")
		if large > 1:
			failures.append("more than one large piece: %s" % str(trio))

	print("day=%s first trio=%s" % [day, str(a[0])])
	if failures.is_empty():
		print("DAILY OK")
	else:
		for f in failures:
			printerr("FAIL: " + f)
	get_tree().quit(0 if failures.is_empty() else 1)

func _sequence(day: String) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("block-daily-" + day)
	var out: Array = []
	for i in range(TRIOS):
		out.append(BlockData.get_seeded_trio(rng).map(func(s): return s["id"]))
	return out

func _category(id: String) -> String:
	for s in BlockData.SHAPES:
		if s["id"] == id:
			return s["category"]
	return ""
