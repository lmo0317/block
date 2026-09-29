class_name AnalyticsManagerClass
extends Node
# Buffers gameplay events and sends them to the leaderboard server in batches.
# Failures are silently dropped so logging never affects gameplay.

const FLUSH_THRESHOLD: int = 40
const MAX_BUFFER: int = 400

# Tests switch this off so nothing is sent
var enabled: bool = true
var session_id: String = ""
var buffer: Array[Dictionary] = []
var is_flushing: bool = false

func _ready() -> void:
	session_id = "ses_%d_%d" % [Time.get_unix_time_from_system(), randi() % 1000000]
	log_event("session_start", {
		"platform": OS.get_name(),
		"is_web": OS.has_feature("web")
	})

func log_event(event_name: String, fields: Dictionary = {}) -> void:
	if not enabled or not LeaderboardManager.is_online():
		return
	var ev: Dictionary = fields.duplicate()
	ev["event"] = event_name
	ev["ts"] = int(Time.get_unix_time_from_system() * 1000.0)
	buffer.append(ev)
	if buffer.size() > MAX_BUFFER:
		buffer = buffer.slice(buffer.size() - MAX_BUFFER)
	if buffer.size() >= FLUSH_THRESHOLD:
		flush()

func flush() -> void:
	if not enabled or is_flushing or buffer.is_empty():
		return
	is_flushing = true

	var batch: Array[Dictionary] = buffer.duplicate()
	buffer.clear()

	var http = HTTPRequest.new()
	http.timeout = 8.0
	add_child(http)

	var url = LeaderboardManager.get_api_base_url() + "/events"
	var headers = PackedStringArray(["Content-Type: application/json"])
	var payload = JSON.stringify({
		"user_id": LeaderboardManager.user_id,
		"session_id": session_id,
		"events": batch
	})

	http.request_completed.connect(func(_result: int, _code: int, _headers: PackedStringArray, _body: PackedByteArray):
		is_flushing = false
		http.queue_free()
	)

	var err = http.request(url, headers, HTTPClient.METHOD_POST, payload)
	if err != OK:
		is_flushing = false
		http.queue_free()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		flush()
