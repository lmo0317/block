class_name ComboFx
extends Node2D
# Combo and fever effects drawn over the game screen:
#  - burst(): a shockwave ring from where lines cleared, stronger with the combo
#  - flash(): a quick full-screen tint
#  - set_fever(): rising embers around the board and a glowing screen edge while fever lasts

const SCREEN := Vector2(720, 1280)

var rings: Array = []   # {pos, radius, max_radius, width, color, age, life}
var embers: CPUParticles2D
var edge_glow: TextureRect
var flash_rect: ColorRect
var glow_tween: Tween

func _ready() -> void:
	z_index = 110
	flash_rect = ColorRect.new()
	flash_rect.size = SCREEN
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.color = Color(1, 1, 1, 0)
	add_child(flash_rect)

	# Screen edge glow: clear in the middle, warm at the edges
	var tex := GradientTexture2D.new()
	tex.width = 256
	tex.height = 456
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.1, 1.0)
	tex.gradient = Gradient.new()
	tex.gradient.set_color(0, Color(1.0, 0.45, 0.1, 0.0))
	tex.gradient.set_color(1, Color(1.0, 0.45, 0.1, 0.55))
	tex.gradient.add_point(0.62, Color(1.0, 0.45, 0.1, 0.0))
	edge_glow = TextureRect.new()
	edge_glow.texture = tex
	edge_glow.size = SCREEN
	edge_glow.stretch_mode = TextureRect.STRETCH_SCALE
	edge_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	edge_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge_glow.modulate.a = 0.0
	add_child(edge_glow)

func setup_embers(board_rect: Rect2) -> void:
	# Sparks rising from the bottom and sides of the board
	embers = CPUParticles2D.new()
	embers.texture = preload("res://assets/sprites/sparkle.png")
	embers.emitting = false
	embers.amount = 46
	embers.lifetime = 1.8
	embers.position = Vector2(board_rect.get_center().x, board_rect.end.y)
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(board_rect.size.x * 0.55, 12)
	embers.direction = Vector2(0, -1)
	embers.spread = 18.0
	embers.gravity = Vector2(0, -40)
	embers.initial_velocity_min = 90.0
	embers.initial_velocity_max = 190.0
	embers.scale_amount_min = 0.25
	embers.scale_amount_max = 0.6
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.85, 0.4, 0.95))
	ramp.set_color(1, Color(1.0, 0.35, 0.05, 0.0))
	embers.color_ramp = ramp
	# Additive: sparks only brighten what is behind them (dark pixels of the sprite vanish)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	embers.material = mat
	add_child(embers)

func burst(pos: Vector2, color: Color, strength: float) -> void:
	# strength 1 = a plain 2-combo; bigger for longer combos and multi-line clears
	rings.append({"pos": pos, "radius": 30.0, "max_radius": 170.0 + 90.0 * strength,
		"width": 8.0 + 4.0 * strength, "color": color, "age": 0.0, "life": 0.45})
	if strength >= 1.5:
		rings.append({"pos": pos, "radius": 10.0, "max_radius": 110.0 + 60.0 * strength,
			"width": 5.0, "color": color.lightened(0.4), "age": -0.08, "life": 0.4})

func flash(color: Color, alpha: float = 0.22) -> void:
	flash_rect.color = Color(color, alpha)
	var tw := create_tween()
	tw.tween_property(flash_rect, "color:a", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func set_fever(on: bool) -> void:
	if embers:
		embers.emitting = on
	if glow_tween:
		glow_tween.kill()
	if on:
		glow_tween = create_tween().set_loops()
		glow_tween.tween_property(edge_glow, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
		glow_tween.tween_property(edge_glow, "modulate:a", 0.55, 0.5).set_trans(Tween.TRANS_SINE)
	else:
		glow_tween = create_tween()
		glow_tween.tween_property(edge_glow, "modulate:a", 0.0, 0.4)

func _process(delta: float) -> void:
	if rings.is_empty():
		return
	for r in rings:
		r["age"] += delta
	rings = rings.filter(func(r): return r["age"] < r["life"])
	queue_redraw()

func _draw() -> void:
	for r in rings:
		if r["age"] < 0.0:
			continue
		var p: float = r["age"] / r["life"]
		var ease_out: float = 1.0 - pow(1.0 - p, 3.0)
		var radius: float = lerpf(r["radius"], r["max_radius"], ease_out)
		var c: Color = r["color"]
		c.a = (1.0 - p) * 0.85
		draw_arc(r["pos"], radius, 0.0, TAU, 64, c, maxf(1.0, r["width"] * (1.0 - p * 0.7)), true)
