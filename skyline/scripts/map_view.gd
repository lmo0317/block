class_name MapView
extends Node2D
## Draws the city from above in the 3/4 view of 2D pixel games (square 48x48 tiles; buildings show
## their front wall and roof), in pixel-art pixels; the parent node scales by whole numbers and moves
## it (camera).
## Three layers, back to front:
##   this node      ground: grass, water, roads, lots, coverage tint, map edge
##   Buildings      sprites row by row from the top, so lower buildings overlap the row above
##   Overlays       fires, warnings, broken roads, previews, selection
## Sprites come from assets/sprites/px (tools/codex_art.py, tools/generate_ground.py).

const T := 48                   # tile size in map pixels
const DETAIL := 2.0             # sprites are stored at 2x: drawn at half size, so at zoom 2 one sprite
                                # pixel is one screen pixel
const EDGE_H := 10.0            # height of the dirt/water side under the bottom map edge
const ZONE_KEY := ["", "r", "c", "i"]
const ZONE_EMBLEM := ["", "ui_res", "ui_com", "ui_ind"]
const LOCKED := Color(0.5, 0.52, 0.6)
const WARN := {"road": "warn_road", "power": "warn_power", "water": "warn_water"}

var city: City
var time := 0.0
var preview := {}               # cell -> true (ok) / false (not allowed)
var ghost := ""                 # sprite drawn on the hovered cell for facilities
var ghost_cell := -1
var ghost_radius := 0
var overlay := ""               # "", "power", "water", "svc:<bit>" or "land"
var selected := -1
var fires := {}                 # cell -> seconds left
var has_warnings := false

var buildings: Node2D
var overlays: Node2D


class Layer:
	extends Node2D
	var paint: Callable

	func _draw() -> void:
		paint.call(self)


func _ready() -> void:
	Atlas.load_once()
	texture_filter = CanvasItem.TEXTURE_FILTER_PARENT_NODE   # the camera node picks smooth or crisp
	buildings = Layer.new()
	buildings.paint = _draw_buildings
	add_child(buildings)
	overlays = Layer.new()
	overlays.paint = _draw_overlays
	add_child(overlays)


func _process(delta: float) -> void:
	var before := int(time * 2.0)
	time += delta
	for c in fires.keys():
		fires[c] -= delta
		if fires[c] <= 0.0:
			fires.erase(c)
	# water ripples swap twice a second; warnings bob and broken roads pulse every frame
	if int(time * 2.0) != before:
		queue_redraw()
	elif not fires.is_empty() or has_warnings:
		overlays.queue_redraw()


# ---------------------------------------------------------------- geometry
static func grid_to_local(g: Vector2) -> Vector2:
	## Grid position (cell centers at whole numbers) -> map pixels.
	return g * T + Vector2(T, T) * 0.5


func cell_center(i: int) -> Vector2:
	return grid_to_local(Vector2(City.pos(i)))


func cell_rect(i: int) -> Rect2:
	return Rect2(Vector2(City.pos(i) * T), Vector2(T, T))


func cell_at(local: Vector2) -> int:
	var x := floori(local.x / T)
	var y := floori(local.y / T)
	if not City.inside(x, y):
		return -1
	return City.idx(x, y)


func active_bounds() -> Rect2:
	var a := city.active_rect()
	return Rect2(Vector2(a.position * T), Vector2(a.size * T))


# ---------------------------------------------------------------- drawing helpers
func _tile(ci: CanvasItem, name: String, i: int, modulate: Color = Color.WHITE) -> void:
	var t := Art.tex(name)
	if t != null:
		ci.draw_texture_rect(t, cell_rect(i), false, modulate)


func _spr(ci: CanvasItem, name: String, i: int, modulate: Color = Color.WHITE) -> void:
	## Sprite standing on its tile: bottom of the picture on the bottom of the cell.
	var t := Art.tex(name)
	var r := cell_rect(i)
	if t == null:
		# no pixel-art version yet: the old 16 px sprite at 3x
		var a := Atlas.region(name)
		if a.size != Vector2.ZERO:
			ci.draw_texture_rect_region(Atlas.texture, Rect2(r.position.x, r.end.y - a.size.y * 3, a.size.x * 3, a.size.y * 3), a, modulate)
		return
	var size := t.get_size() / DETAIL
	ci.draw_texture_rect(t, Rect2(Vector2(roundf(r.get_center().x - size.x * 0.5), r.end.y - size.y), size), false, modulate)


func sprite_top(i: int) -> float:
	var s := sprite_for(i)
	var t := Art.tex(s) if s != "" else null
	return cell_rect(i).end.y - (t.get_height() / DETAIL if t != null else T)


func _road_mask(p: Vector2i) -> int:
	var m := 0
	var bits := [1, 2, 4, 8]
	for k in 4:
		var q: Vector2i = p + City.DIRS[k]
		if City.inside(q.x, q.y):
			if city.obj[City.idx(q.x, q.y)] == Defs.ROAD:
				m |= bits[k]
		elif k == 3:
			m |= 8          # the highway runs off the map edge
	return m


func _shore_mask(p: Vector2i) -> int:
	var m := 0
	var bits := [1, 2, 4, 8]
	for k in 4:
		var q: Vector2i = p + City.DIRS[k]
		if City.inside(q.x, q.y) and city.terrain[City.idx(q.x, q.y)] != Defs.T.WATER:
			m |= bits[k]
	return m


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
				return _variant("rowhouse" if lv == 2 else "apartment", v)
			Defs.Z.C:
				if lv == 3:
					return _variant("dept", v)
				var shop: String = Defs.SHOPS[v % Defs.SHOPS.size()]
				return shop if lv == 1 else shop + "_2"
			Defs.Z.I:
				return _variant(["", "workshop", "factory", "hightech"][lv], v)
	if city.terrain[i] == Defs.T.FOREST:
		return "forest"
	return ""


func _variant(base: String, v: int) -> String:
	var names := [base]
	for suffix in ["_b", "_c"]:
		if Art.has(base + suffix):
			names.append(base + suffix)
	return names[v % names.size()]


# ---------------------------------------------------------------- layer 1: ground
func _draw() -> void:
	if city == null:
		return
	var frame := int(time * 2.0) % 2
	for i in City.CELLS:
		var p := City.pos(i)
		var tint := Color.WHITE if city.is_active(i) else LOCKED
		if city.terrain[i] == Defs.T.WATER:
			_tile(self, "water%d_%d" % [_shore_mask(p), frame], i, tint)
		else:
			_tile(self, "grass%d" % ((p.x * 7 + p.y * 13) % 3), i, tint)
		if city.obj[i] == Defs.ROAD:
			_tile(self, ("bridge%d" if city.terrain[i] == Defs.T.WATER else "road%d") % _road_mask(p), i, tint)
		elif city.zone[i] != Defs.Z.NONE and (city.level[i] == 0 or city.build[i] > 0):
			_lot(i, city.zone[i])
	# dirt (or water) side under the bottom edge, so the map reads as a block of land
	for x in City.N:
		var i := City.idx(x, City.N - 1)
		var r := cell_rect(i)
		var col := Color(0.32, 0.5, 0.78) if city.terrain[i] == Defs.T.WATER else Color(0.55, 0.4, 0.28)
		draw_rect(Rect2(r.position.x, r.end.y, T, EDGE_H), col * (Color.WHITE if city.is_active(i) else LOCKED))
	if overlay != "":
		_draw_overlay()
	buildings.queue_redraw()
	overlays.queue_redraw()


func _lot(i: int, z: int) -> void:
	_tile(self, "lot_" + ZONE_KEY[z], i)
	# faint house / shop / factory picture: "this is a residential / commercial / industrial plot"
	var emblem := Art.tex(ZONE_EMBLEM[z])
	if emblem != null:
		var size := emblem.get_size() / DETAIL
		draw_texture_rect(emblem, Rect2((cell_center(i) - size * 0.5).round(), size), false, Color(1, 1, 1, 0.5))


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
				draw_rect(cell_rect(i), Color(1.0 - v, v, 0.2, 0.35))
		return
	else:
		return
	for i in City.CELLS:
		if city.is_active(i) and (arr[i] & bit):
			draw_rect(cell_rect(i), Color(col, 0.3))


# ---------------------------------------------------------------- layer 2: buildings (top row first)
func _draw_buildings(ci: CanvasItem) -> void:
	if city == null:
		return
	for i in City.CELLS:
		var name := sprite_for(i)
		if name != "":
			_spr(ci, name, i, Color.WHITE if city.is_active(i) else LOCKED)
	if ghost_cell >= 0 and ghost != "":
		_spr(ci, ghost, ghost_cell, Color(1, 1, 1, 0.7))


# ---------------------------------------------------------------- layer 3: overlays
func _draw_overlays(ci: CanvasItem) -> void:
	if city == null:
		return
	for c in fires:
		var r := Atlas.region("fire%d" % (int(time * 8.0) % 2))
		var at := cell_rect(c).end - Vector2(T * 0.5 + r.size.x, r.size.y * 2)
		ci.draw_texture_rect_region(Atlas.texture, Rect2(at, r.size * 2), r)
	_draw_warnings(ci)
	_draw_active_outline(ci)
	_draw_preview(ci)
	if selected >= 0:
		ci.draw_rect(cell_rect(selected), Color(1, 0.95, 0.4), false, 2.0)


func warning_of(i: int) -> String:
	## What a zoned cell is missing first: "road", "power", "water" or "".
	if city.zone[i] == Defs.Z.NONE:
		return ""
	if city.access_road[i] < 0:
		return "road"
	if city.power[i] == 0:
		return "power"
	if city.water[i] == 0:
		return "water"
	return ""


func _draw_warnings(ci: CanvasItem) -> void:
	var any := false
	# roads that do not reach the highway pulse red
	var pulse := 0.3 + 0.2 * sin(time * 5.0)
	for i in City.CELLS:
		if city.obj[i] == Defs.ROAD and city.connected[i] == 0 and city.is_active(i):
			ci.draw_rect(cell_rect(i), Color(1.0, 0.15, 0.1, pulse))
			any = true
	if any or city.road_count < 14:
		_draw_highway_arrow(ci)
		any = true
	var bob := roundf(sin(time * 4.0) * 1.5)
	for i in City.CELLS:
		var w := warning_of(i)
		if w == "":
			continue
		any = true
		var t := Art.tex(WARN[w])
		if t == null:
			t = Atlas.icon(["icon_road", "icon_power", "icon_water"][["road", "power", "water"].find(w)])
		var built := city.level[i] > 0 and city.build[i] == 0
		var size := t.get_size() / DETAIL if t.get_width() > 16 else t.get_size()
		var top := sprite_top(i) - size.y + 4 if built else cell_rect(i).position.y + 2
		ci.draw_texture_rect(t, Rect2(Vector2(roundf(cell_center(i).x - size.x * 0.5), top + bob), size), false)
	has_warnings = any


func _draw_highway_arrow(ci: CanvasItem) -> void:
	## Bobbing arrow over the end of the highway: build roads from here.
	# the highway is built up to one cell inside the starting square (City._generate_once)
	var p := Vector2i((City.N - Defs.rank_size(0)) / 2 + 1, City.pos(city.entrance).y)
	var c := cell_center(City.idx(p.x, p.y)) + Vector2(0, -20.0 + roundf(sin(time * 5.0) * 2.0))
	var pts := PackedVector2Array([c + Vector2(-5, -10), c + Vector2(5, -10), c + Vector2(5, -4), c + Vector2(10, -4), c + Vector2(0, 6), c + Vector2(-10, -4), c + Vector2(-5, -4)])
	ci.draw_colored_polygon(pts, Color(1.0, 0.85, 0.2))
	pts.append(pts[0])
	ci.draw_polyline(pts, Color(0.17, 0.14, 0.21), 1.0)


func _draw_active_outline(ci: CanvasItem) -> void:
	ci.draw_rect(active_bounds(), Color(1, 1, 1, 0.45), false, 1.0)


func _draw_preview(ci: CanvasItem) -> void:
	for c in preview:
		ci.draw_rect(cell_rect(c), Color(0.4, 1.0, 0.5, 0.45) if preview[c] else Color(1.0, 0.3, 0.3, 0.45))
	if ghost_cell >= 0 and ghost_radius > 0:
		ci.draw_arc(cell_center(ghost_cell), (ghost_radius + 0.5) * T, 0, TAU, 72, Color(1, 1, 1, 0.85), 2.0)
