class_name AuthManager
extends RefCounted

const AUTH_SAVE_PATH: String = "user://instagram_profile.json"

static var is_logged_in: bool = false
static var username: String = ""
static var display_name: String = ""

# Default initial friends list with realistic Instagram handles
static var friends_leaderboard: Array[Dictionary] = [
	{
		"username": "puzzle_master_kr",
		"display_name": "퍼즐마스터 민서",
		"score": 3420,
		"avatar_color": Color(0.96, 0.45, 0.71), # Pink
		"is_me": false
	},
	{
		"username": "jenny_blocks",
		"display_name": "Jenny (블록장인)",
		"score": 2890,
		"avatar_color": Color(0.22, 0.74, 0.97), # Blue
		"is_me": false
	},
	{
		"username": "block_champion",
		"display_name": "준호 (BlockPro)",
		"score": 2450,
		"avatar_color": Color(0.99, 0.82, 0.25), # Gold
		"is_me": false
	},
	{
		"username": "alex_juggler",
		"display_name": "Alex K.",
		"score": 1980,
		"avatar_color": Color(0.20, 0.83, 0.60), # Green
		"is_me": false
	},
	{
		"username": "sohee_daily",
		"display_name": "소희 🌸",
		"score": 1620,
		"avatar_color": Color(0.75, 0.52, 0.99), # Purple
		"is_me": false
	},
	{
		"username": "minwoo_game",
		"display_name": "민우",
		"score": 1120,
		"avatar_color": Color(0.98, 0.57, 0.24), # Orange
		"is_me": false
	},
	{
		"username": "david_k_photo",
		"display_name": "David",
		"score": 980,
		"avatar_color": Color(0.97, 0.44, 0.44), # Red
		"is_me": false
	}
]

static func init_auth() -> void:
	load_profile()

static func login_player(raw_name: String) -> void:
	var clean_name = raw_name.strip_edges()
	if clean_name.is_empty():
		clean_name = "블록러_%03d" % (randi() % 900 + 100)
		
	username = clean_name
	display_name = clean_name
	is_logged_in = true
	save_profile()
	
	# Sync with real-time leaderboard backend
	var lm = Engine.get_main_loop().root.get_node_or_null("/root/LeaderboardManager")
	if lm:
		lm.update_nickname(display_name)

static func login_with_instagram(raw_handle: String) -> void:
	login_player(raw_handle)

static func logout() -> void:
	is_logged_in = false
	username = ""
	display_name = ""
	save_profile()
	
	# Sync guest with leaderboard backend
	var lm = Engine.get_main_loop().root.get_node_or_null("/root/LeaderboardManager")
	if lm:
		lm.update_nickname("게스트")

static func update_my_score(best_score: int) -> void:
	# Update or add my entry in friends_leaderboard
	var found = false
	for entry in friends_leaderboard:
		if entry.get("is_me", false):
			entry["score"] = maxi(entry["score"], best_score)
			if is_logged_in:
				entry["username"] = username
				entry["display_name"] = display_name + " (나)"
			found = true
			break
			
	if not found and is_logged_in:
		friends_leaderboard.append({
			"username": username,
			"display_name": display_name + " (나)",
			"score": best_score,
			"avatar_color": Color(0.96, 0.35, 0.5),
			"is_me": true
		})
	elif not found and not is_logged_in:
		friends_leaderboard.append({
			"username": "guest_player",
			"display_name": "나 (게스트)",
			"score": best_score,
			"avatar_color": Color(0.38, 0.74, 0.97),
			"is_me": true
		})
	
	save_profile()

static func get_sorted_leaderboard(current_best_score: int) -> Array[Dictionary]:
	update_my_score(current_best_score)
	
	var list = friends_leaderboard.duplicate(true)
	# Sort descending by score
	list.sort_custom(func(a, b): return a["score"] > b["score"])
	return list

static func add_friend(handle: String, custom_score: int = -1) -> bool:
	var clean = handle.strip_edges()
	if clean.begins_with("@"):
		clean = clean.substr(1)
	if clean.is_empty():
		return false
		
	# Check if already exists
	for f in friends_leaderboard:
		if f["username"].to_lower() == clean.to_lower():
			return false
			
	var score_val = custom_score
	if score_val < 0:
		score_val = randi_range(800, 3200)
		
	var colors = [
		Color(0.96, 0.45, 0.71),
		Color(0.22, 0.74, 0.97),
		Color(0.99, 0.82, 0.25),
		Color(0.20, 0.83, 0.60),
		Color(0.75, 0.52, 0.99),
		Color(0.98, 0.57, 0.24)
	]
	
	friends_leaderboard.append({
		"username": clean,
		"display_name": "@" + clean,
		"score": score_val,
		"avatar_color": colors[randi() % colors.size()],
		"is_me": false
	})
	save_profile()
	return true

static func save_profile() -> void:
	var file = FileAccess.open(AUTH_SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"is_logged_in": is_logged_in,
			"username": username,
			"display_name": display_name,
			"friends": friends_leaderboard
		}
		file.store_string(JSON.stringify(data))

static func load_profile() -> void:
	if not FileAccess.file_exists(AUTH_SAVE_PATH):
		return
	var file = FileAccess.open(AUTH_SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		if json.parse(content) == OK:
			var data = json.get_data()
			if data is Dictionary:
				is_logged_in = data.get("is_logged_in", false)
				username = data.get("username", "")
				display_name = data.get("display_name", "")
				if data.has("friends") and data["friends"] is Array:
					friends_leaderboard.clear()
					for item in data["friends"]:
						var col_str = item.get("avatar_color", "")
						var col = Color(0.2, 0.7, 0.9)
						if col_str is String and not col_str.is_empty():
							col = Color.from_string(col_str, col)
						friends_leaderboard.append({
							"username": item.get("username", ""),
							"display_name": item.get("display_name", ""),
							"score": int(item.get("score", 0)),
							"avatar_color": col,
							"is_me": item.get("is_me", false)
						})
