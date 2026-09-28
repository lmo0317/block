class_name LeaderboardManagerClass
extends Node

signal score_submitted(rank: int, is_new_best: bool, best_score: int)
signal nickname_changed(new_nickname: String)
signal profile_updated(new_nickname: String, new_avatar_id: int)

const PROFILE_SAVE_PATH: String = "user://player_profile.json"
const DEFAULT_API_HOST: String = "http://192.168.219.112:3000"
const MAX_NICKNAME_LENGTH: int = 12

var user_id: String = ""
var nickname: String = ""
var avatar_id: int = 1
# Representative title (an unlocked achievement title), shown next to the nickname in rankings
var title: String = ""
var is_profile_setup_done: bool = false
var last_known_rank: int = -1
var last_best_score: int = 0

var avatar_textures: Dictionary = {}

func _ready() -> void:
	# Load avatar textures (1 to 8)
	for i in range(1, 9):
		var path = "res://assets/avatars/avatar_%d.png" % i
		if ResourceLoader.exists(path):
			avatar_textures[i] = load(path)
			
	load_profile()
	if user_id.is_empty():
		user_id = _generate_unique_id()
		nickname = "블록러_%03d" % (randi() % 900 + 100)
		avatar_id = randi_range(1, 8)
		is_profile_setup_done = false
		save_profile()

func get_avatar_texture(id: int = -1) -> Texture2D:
	var target_id = avatar_id if id <= 0 else id
	if avatar_textures.has(target_id):
		return avatar_textures[target_id]
	if avatar_textures.has(1):
		return avatar_textures[1]
	return null

func get_api_base_url() -> String:
	if OS.has_feature("web"):
		var origin = JavaScriptBridge.eval("window.location.origin")
		if origin != null and str(origin) != "null" and not str(origin).is_empty():
			return str(origin) + "/api/block-game"
	# BLOCK_API_HOST lets desktop/editor runs target a local server (e.g. http://127.0.0.1:3000)
	var host = OS.get_environment("BLOCK_API_HOST")
	if host.is_empty():
		host = DEFAULT_API_HOST
	return host + "/api/block-game"

func load_profile() -> void:
	if not FileAccess.file_exists(PROFILE_SAVE_PATH):
		return
	var file = FileAccess.open(PROFILE_SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		if json.parse(content) == OK:
			var data = json.get_data()
			if data is Dictionary:
				user_id = data.get("user_id", "")
				nickname = data.get("nickname", "")
				avatar_id = int(data.get("avatar_id", 1))
				if avatar_id < 1 or avatar_id > 8:
					avatar_id = 1
				is_profile_setup_done = bool(data.get("is_profile_setup_done", false))
				last_known_rank = int(data.get("last_known_rank", -1))
				last_best_score = int(data.get("last_best_score", 0))
				title = str(data.get("title", ""))

func save_profile() -> void:
	var file = FileAccess.open(PROFILE_SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"user_id": user_id,
			"nickname": nickname,
			"avatar_id": avatar_id,
			"is_profile_setup_done": is_profile_setup_done,
			"last_known_rank": last_known_rank,
			"last_best_score": last_best_score,
			"title": title
		}
		file.store_string(JSON.stringify(data))

func get_kst_day_key() -> String:
	# Daily challenge day in KST (UTC+9); the server uses the same rule
	var d: Dictionary = Time.get_datetime_dict_from_unix_time(int(Time.get_unix_time_from_system()) + 9 * 3600)
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]

func submit_score(score: int, callback: Callable = Callable(), mode: String = "classic", day_key: String = "", play_log: Array = []) -> void:
	var http = HTTPRequest.new()
	http.timeout = 8.0
	add_child(http)
	
	var url = get_api_base_url() + "/score"
	var headers = PackedStringArray(["Content-Type: application/json"])
	var body_dict = {
		"user_id": user_id,
		"nickname": nickname,
		"avatar_id": avatar_id,
		"title": title,
		"score": score
	}
	if mode == "daily":
		body_dict["mode"] = "daily"
		body_dict["day_key"] = day_key
	if not play_log.is_empty():
		body_dict["log"] = play_log
	var payload = JSON.stringify(body_dict)
	
	http.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, response_body: PackedByteArray):
		var res_data: Dictionary = {}
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var parsed = JSON.parse_string(response_body.get_string_from_utf8())
			if parsed is Dictionary:
				res_data = parsed
				# Daily ranks are separate; keep the cached all-time rank untouched
				if res_data.get("success", false) and mode != "daily":
					last_known_rank = int(res_data.get("rank", -1))
					last_best_score = int(res_data.get("best_score", score))
					save_profile()
					score_submitted.emit(last_known_rank, res_data.get("is_new_best", false), last_best_score)
		else:
			res_data = {"success": false, "error": "HTTP %d" % response_code}
			
		if callback.is_valid():
			callback.call(res_data)
		http.queue_free()
	)
	
	var err = http.request(url, headers, HTTPClient.METHOD_POST, payload)
	if err != OK:
		http.queue_free()
		if callback.is_valid():
			callback.call({"success": false, "error": "Request failed to start"})

func fetch_leaderboard(type: String = "all", limit: int = 30, callback: Callable = Callable()) -> void:
	var http = HTTPRequest.new()
	http.timeout = 8.0
	add_child(http)
	
	var url = "%s/leaderboard?type=%s&limit=%d&user_id=%s" % [
		get_api_base_url(),
		type.uri_encode(),
		limit,
		user_id.uri_encode()
	]
	
	http.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, response_body: PackedByteArray):
		var res_data: Dictionary = {}
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var parsed = JSON.parse_string(response_body.get_string_from_utf8())
			if parsed is Dictionary:
				res_data = parsed
		else:
			res_data = {"success": false, "error": "HTTP %d" % response_code}
			
		if callback.is_valid():
			callback.call(res_data)
		http.queue_free()
	)
	
	var err = http.request(url, PackedStringArray([]), HTTPClient.METHOD_GET)
	if err != OK:
		http.queue_free()
		if callback.is_valid():
			callback.call({"success": false, "error": "Request failed to start"})

func update_profile(new_nick: String, new_avatar_id: int, callback: Callable = Callable()) -> void:
	var clean_nick = new_nick.strip_edges()
	if clean_nick.is_empty():
		clean_nick = nickname
	clean_nick = clean_nick.substr(0, MAX_NICKNAME_LENGTH)
	
	nickname = clean_nick
	avatar_id = clampi(new_avatar_id, 1, 8)
	is_profile_setup_done = true
	save_profile()
	
	profile_updated.emit(nickname, avatar_id)
	nickname_changed.emit(nickname)
	
	var http = HTTPRequest.new()
	http.timeout = 8.0
	add_child(http)
	
	var url = get_api_base_url() + "/profile"
	var headers = PackedStringArray(["Content-Type: application/json"])
	var body_dict = {
		"user_id": user_id,
		"nickname": nickname,
		"avatar_id": avatar_id,
		"title": title
	}
	var payload = JSON.stringify(body_dict)
	
	http.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, _response_body: PackedByteArray):
		var success = (result == HTTPRequest.RESULT_SUCCESS and response_code == 200)
		if callback.is_valid():
			callback.call(success)
		http.queue_free()
	)
	
	var err = http.request(url, headers, HTTPClient.METHOD_POST, payload)
	if err != OK:
		http.queue_free()
		if callback.is_valid():
			callback.call(false)

func set_title(new_title: String) -> void:
	title = new_title
	update_profile(nickname, avatar_id)

func update_nickname(new_nick: String, callback: Callable = Callable()) -> void:
	update_profile(new_nick, avatar_id, callback)

func reset_profile() -> void:
	user_id = _generate_unique_id()
	nickname = "블록러_%03d" % (randi() % 900 + 100)
	avatar_id = randi_range(1, 8)
	is_profile_setup_done = false
	last_known_rank = -1
	save_profile()
	profile_updated.emit(nickname, avatar_id)
	nickname_changed.emit(nickname)

func _generate_unique_id() -> String:
	var chars = "abcdefghijklmnopqrstuvwxyz0123456789"
	var rand_part = ""
	for i in range(12):
		rand_part += chars[randi() % chars.length()]
	return "usr_%d_%s" % [Time.get_unix_time_from_system(), rand_part]
