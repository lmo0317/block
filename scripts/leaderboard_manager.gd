class_name LeaderboardManagerClass
extends Node

signal score_submitted(rank: int, is_new_best: bool, best_score: int)
signal nickname_changed(new_nickname: String)

const PROFILE_SAVE_PATH: String = "user://player_profile.json"
const DEFAULT_API_HOST: String = "http://192.168.219.112:3000"

var user_id: String = ""
var nickname: String = ""
var last_known_rank: int = -1
var last_best_score: int = 0

func _ready() -> void:
	load_profile()
	if user_id.is_empty():
		user_id = _generate_unique_id()
		nickname = "블록러_%03d" % (randi() % 900 + 100)
		save_profile()

func get_api_base_url() -> String:
	if OS.has_feature("web"):
		var origin = JavaScriptBridge.eval("window.location.origin")
		if origin != null and str(origin) != "null" and not str(origin).is_empty():
			return str(origin) + "/api/block-game"
	return DEFAULT_API_HOST + "/api/block-game"

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
				last_known_rank = data.get("last_known_rank", -1)
				last_best_score = data.get("last_best_score", 0)

func save_profile() -> void:
	var file = FileAccess.open(PROFILE_SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"user_id": user_id,
			"nickname": nickname,
			"last_known_rank": last_known_rank,
			"last_best_score": last_best_score
		}
		file.store_string(JSON.stringify(data))

func submit_score(score: int, callback: Callable = Callable()) -> void:
	var http = HTTPRequest.new()
	http.timeout = 8.0
	add_child(http)
	
	var url = get_api_base_url() + "/score"
	var headers = PackedStringArray(["Content-Type: application/json"])
	var body_dict = {
		"user_id": user_id,
		"nickname": nickname,
		"score": score
	}
	var payload = JSON.stringify(body_dict)
	
	http.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, response_body: PackedByteArray):
		var res_data: Dictionary = {}
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var parsed = JSON.parse_string(response_body.get_string_from_utf8())
			if parsed is Dictionary:
				res_data = parsed
				if res_data.get("success", false):
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

func update_nickname(new_nick: String, callback: Callable = Callable()) -> void:
	var clean_nick = new_nick.strip_edges()
	if clean_nick.is_empty():
		if callback.is_valid():
			callback.call(false)
		return
		
	clean_nick = clean_nick.substr(0, 15)
	nickname = clean_nick
	save_profile()
	nickname_changed.emit(nickname)
	
	var http = HTTPRequest.new()
	http.timeout = 8.0
	add_child(http)
	
	var url = get_api_base_url() + "/nickname"
	var headers = PackedStringArray(["Content-Type: application/json"])
	var body_dict = {
		"user_id": user_id,
		"nickname": nickname
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

func _generate_unique_id() -> String:
	var chars = "abcdefghijklmnopqrstuvwxyz0123456789"
	var rand_part = ""
	for i in range(12):
		rand_part += chars[randi() % chars.length()]
	return "usr_%d_%s" % [Time.get_unix_time_from_system(), rand_part]
