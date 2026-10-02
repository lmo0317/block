class_name MapView
extends Node2D
## Draws the city in map pixels (16 per cell); the parent node scales and moves it (camera).
## Pass 1 draws the ground of every cell, pass 2 draws the sprites row by row so taller buildings
## overlap the row above.

const CELL := 16
const LOCKED := Color(0.05, 0.08, 0.12, 0.55)

var city: City
var time := 0.0
# preview while a tool is in use
var preview := {}               # cell -> true (ok) / false (not allowed)
var ghost := ""                 # sprite drawn on the hovered cell for facilities
var ghost_cell := -1
var ghost_radius := 0
var overlay := ""               # "", "power", "water" or "svc:<bit>"
var selected := -1
var fires := {}                 # cell -> seconds left


func _ready() -> void:
	Atlas.load_once()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta: float) -> void:
	var before := int(time * 2.0)
	time += delta
	for c in fires.keys():
		fires[c] -= delta
		if fires[c] <= 0.0:
			fires.erase(c)
	if int(time * 2.0) != before or not fires.is_empty():
		queue_redraw()


func _spr(name: String, cell: Vector2i, modulate: Color = Color.WHITE) -> void:
	var r := Atlas.region(name)
	var dst := Rect2(cell.x * CELL, cell.y * CELL + CELL - r.size.y, r.size.x, r.size.y)
	draw_texture_rect_region(Atlas.texture, dst, r, modulate)


func _tile(name: String, cell: Vector2i, modulate: Color = Color.WHITE) -> void:
	draw_texture_rect_region(Atlas.texture, Rect2(cell * CELL, Vector2(CELL, CELL)), Atlas.region(name), modulate)


func _road_mask(p: Vector2i) -> int:
	var m := 0
	var bits := [1, 2, 4, 8]
	for k in 4:
		var q: Vector2i = p + City.DIRS[k]
		if City.inside(q.x, q.y):
			if city.obj[City.idx(q.x, q.y)] == Defs.ROAD:
				m |= bits[k]
		elif k == 3:
			m |= 8          # the highway runs off the left edge
	return m


const ZONE_KEY := ["", "r", "c", "i"]


func sprite_for(i: int) -> String:
	var o := city.obj[i]
	if o >= 2:
		return Defs.fac(o)["key"]
	var z := city.zone[i]
	if z != Defs.Z.NONE and city.level[i] > 0:
		if city.build[i] > 0:
			return "scaffold_" + ZONE_KEY[z]
		var lv := city.level[i]
		var v := city.variant[i]
		match z:
			Defs.Z.R:
				if lv == 1:
					return ["house_a", "house_b", "house_c"][v % 3]
				return ("rowhouse" if lv == 2 else "apartment") + ["", "_b", "_c"][v % 3]
			Defs.Z.C:
				if lv == 3:
					return "dept" + ["", "_b"][v % 2]
				var shop: String = Defs.SHOPS[v % Defs.SHOPS.size()]
				return shop if lv == 1 else shop + "_2"
			Defs.Z.I:
				return ["", "workshop", "factory", "hightech"][lv] + ["", "_b"][v % 2]
	if city.terrain[i] == Defs.T.FOREST:
		return "forest"
	return ""


func _draw() -> void:
	if city == null:
		return
	var n := City.N
	var wf := int(time * 1.5) % 2
	# pass 1: ground, roads, lots
	for y in n:
		for x in n:
			var i := City.idx(x, y)
			var p := Vector2i(x, y)
			if city.terrain[i] == Defs.T.WATER:
				_tile("water%d" % wf, p)
				_shore(p)
			else:
				_tile("grass%d" % ((x * 7 + y * 13) % 3), p)
			if city.obj[i] == Defs.ROAD:
				var m := _road_mask(p)
				_tile(("bridge%d" if city.terrain[i] == Defs.T.WATER else "road%d") % m, p)
			elif city.zone[i] != Defs.Z.NONE and (city.level[i] == 0 or city.build[i] > 0):
				_lot(p, city.zone[i])
	# overlay tint under the sprites
	if overlay != "":
		_draw_overlay()
	# pass 2: sprites, row by row
	for y in n:
		for x in n:
			var i := City.idx(x, y)
			var s := sprite_for(i)
			if s != "":
				_spr(s, Vector2i(x, y))
			if fires.has(i):
				_spr("fire%d" % (int(time * 8.0) % 2), Vector2i(x, y))
	_draw_warnings()
	_draw_locked()
	_draw_preview()
	if selected >= 0:
		var sp := City.pos(selected)
		draw_rect(Rect2(sp * CELL, Vector2(CELL, CELL)), Color(1, 0.95, 0.4), false, 1.0)


func _shore(p: Vector2i) -> void:
	var edge := Color(0.86, 0.82, 0.62)
	for k in 4:
		var q: Vector2i = p + City.DIRS[k]
		if not City.inside(q.x, q.y) or city.terrain[City.idx(q.x, q.y)] == Defs.T.WATER:
			continue
		var r := Rect2(p * CELL, Vector2(CELL, CELL))
		match k:
			0:
				draw_rect(Rect2(r.position, Vector2(CELL, 2)), edge)
			1:
				draw_rect(Rect2(r.position + Vector2(CELL - 2, 0), Vector2(2, CELL)), edge)
			2:
				draw_rect(Rect2(r.position + Vector2(0, CELL - 2), Vector2(CELL, 2)), edge)
			3:
				draw_rect(Rect2(r.position, Vector2(2, CELL)), edge)


func _lot(p: Vector2i, z: int) -> void:
	_tile("lot_" + ZONE_KEY[z], p)
	var col: Color = Defs.ZONE_COLORS[z]
	draw_rect(Rect2(p * CELL, Vector2(CELL, CELL)), Color(col.darkened(0.2), 0.8), false, 1.0)


func _draw_overlay() -> void:
	var arr: PackedByteArray
	var bit := 1
	var col := Color(1, 1, 1)
	if overlay == "power":
		arr = city.power
		col = Color(1.0, 0.85, 0.2)
	elif overlay == "water":
		arr = city.water
		col = Color(0.3, 0.7, 1.0)
	elif overlay.begins_with("svc:"):
		arr = city.service
		bit = int(overlay.substr(4))
		col = Color(0.5, 1.0, 0.6)
	elif overlay == "land":
		for i in City.CELLS:
			if city.is_active(i):
				var v := city.land[i] / 100.0
				draw_rect(Rect2(City.pos(i) * CELL, Vector2(CELL, CELL)), Color(1.0 - v, v, 0.2, 0.35))
		return
	else:
		return
	for i in City.CELLS:
		if city.is_active(i) and (arr[i] & bit):
			draw_rect(Rect2(City.pos(i) * CELL, Vector2(CELL, CELL)), Color(col, 0.28))


func _draw_warnings() -> void:
	if int(time * 2.0) % 2 == 0:
		return
	for i in City.CELLS:
		if city.zone[i] == Defs.Z.NONE:
			continue
		var icon := ""
		if city.access_road[i] < 0:
			icon = "icon_road"
		elif city.power[i] == 0:
			icon = "icon_power"
		elif city.water[i] == 0:
			icon = "icon_water"
		if icon == "":
			continue
		var p := City.pos(i)
		var built := city.level[i] > 0 and city.build[i] == 0
		var r := Atlas.region(icon)
		var at := Vector2(p.x * CELL + 4.5, p.y * CELL - 6.0) if built else Vector2(p.x * CELL + 1.5, p.y * CELL + 8.0)
		draw_texture_rect_region(Atlas.texture, Rect2(at, r.size), r, Color(1, 1, 1, 1.0 if built else 0.75))


func _draw_locked() -> void:
	var a := city.active_rect()
	var full := City.N * CELL
	var r := Rect2(a.position * CELL, a.size * CELL)
	draw_rect(Rect2(0, 0, full, r.position.y), LOCKED)
	draw_rect(Rect2(0, r.end.y, full, full - r.end.y), LOCKED)
	draw_rect(Rect2(0, r.position.y, r.position.x, r.size.y), LOCKED)
	draw_rect(Rect2(r.end.x, r.position.y, full - r.end.x, r.size.y), LOCKED)
	draw_rect(r, Color(1, 1, 1, 0.5), false, 1.0)


func _draw_preview() -> void:
	for c in preview:
		var col := Color(0.4, 1.0, 0.5, 0.45) if preview[c] else Color(1.0, 0.3, 0.3, 0.45)
		draw_rect(Rect2(City.pos(c) * CELL, Vector2(CELL, CELL)), col)
	if ghost_cell >= 0:
		var p := City.pos(ghost_cell)
		if ghost_radius > 0:
			var center := Vector2(p * CELL) + Vector2(CELL, CELL) * 0.5
			draw_arc(center, (ghost_radius + 0.5) * CELL, 0, TAU, 64, Color(1, 1, 1, 0.8), 1.0)
		if ghost != "":
			_spr(ghost, p, Color(1, 1, 1, 0.75))


func cell_center(i: int) -> Vector2:
	return Vector2(City.pos(i) * CELL) + Vector2(CELL, CELL) * 0.5
