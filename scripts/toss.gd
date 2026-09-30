class_name Toss
extends RefCounted
# Apps in Toss (토스 미니앱) glue. The "Toss" export preset builds with the "toss" feature into
# build/toss; toss/ wraps it with toss/src/bridge.js, which puts the SDK on window.TossBridge.
# Everything here is a no-op in other builds.

# Top-right area the Toss game bar ("more" and X buttons) floats over, in game units
const NAV_BAR_RESERVE_W: float = 250.0

static var _bridge = null
# JavaScript callbacks are only valid while referenced
static var _callbacks: Array = []

static func active() -> bool:
	if not OS.has_feature("toss"):
		return false
	if _bridge == null:
		_bridge = JavaScriptBridge.get_interface("TossBridge")
	return _bridge != null

static func _cb(f: Callable) -> JavaScriptObject:
	var c := JavaScriptBridge.create_callback(func(args: Array): f.call(args[0] if args.size() > 0 else null))
	_callbacks.append(c)
	return c

# done(hash: String), "" when unavailable
static func fetch_user_key(done: Callable) -> void:
	if active():
		_bridge.userKey(_cb(func(v): done.call("" if v == null else str(v))))

# done(nickname: String), "" when the player has no Toss game profile yet
static func fetch_nickname(done: Callable) -> void:
	if active():
		_bridge.nickname(_cb(func(v): done.call("" if v == null else str(v))))

# done(status: String): "SUCCESS", "LEADERBOARD_NOT_FOUND", "PROFILE_NOT_FOUND", "UNSUPPORTED" ...
static func submit_score(score: int, done: Callable) -> void:
	if active():
		_bridge.submitScore(str(score), _cb(func(v): done.call("" if v == null else str(v))))

static func open_leaderboard() -> void:
	if active():
		_bridge.openLeaderboard()

# Strength by how long a plain vibration would have been
static func haptic(duration_ms: int) -> void:
	if not active():
		return
	var type := "tickWeak"
	if duration_ms >= 150:
		type = "success"
	elif duration_ms >= 80:
		type = "basicMedium"
	elif duration_ms >= 40:
		type = "tickMedium"
	_bridge.haptic(type)

# Taking over the Android back button means the game must confirm and close by itself
static func on_back(handler: Callable) -> void:
	if active():
		_bridge.onBack(_cb(func(_v): handler.call()))

static func close() -> void:
	if active():
		_bridge.close()
