class_name MapView
extends Node2D
## Draws the city in map units (16 per cell); the parent node scales and moves it (camera).
## Three layers, back to front:
##   this node      ground: grass, water, roads, lots, coverage tint
##   Buildings      sprites row by row, so taller buildings overlap the row above
##   Overlays       fires, warnings, locked land, previews, selection
## Painted sprites (Art, assets/sprites/hd) are used when present, else the pixel atlas.

const CELL := 16
const LOCKED := Color(0.05, 0.08, 0.12, 0.55)
const ZONE_KEY := ["", "r", "c", "i"]
const SPRITE_W := 15.0          # painted sprites leave half a unit free on each side

var city: City
var time := 0.0
# preview while a tool is in use
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
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	buildings = Layer.new()
	buildings.paint = _draw_buildings
	buildings.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(buildings)
	overlays = Layer.new()
	overlays.paint = _draw_overlays
	overlays.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(overlays)


func _process(delta: float) -> void:
	var before := int(time * 2.0)
	time += delta
	for c in fires.keys():
		fires[c] -= delta
		if fires[c] <= 0.0:
			fires.erase(c)
	# warnings bob and broken roads pulse, so the overlay layer redraws every frame while any show
	if int(time * 2.0) != before or not fires.is_empty() or has_warnings:
		overlays.queue_redraw()


func redraw() -> void:
	queue_redraw()
	buildings.queue_redraw()
	overlays.queue_redraw()


# ---------------------------------------------------------------- drawing helpers
func _spr(ci: CanvasItem, name: String, cell: Vector2i, modulate: Color = Color.WHITE) -> void:
	## Sprite standing on the bottom of a cell.
	var hd := Art.tex(name)
	if hd != null:
		var h := SPRITE_W * hd.get_height() / hd.get_width()
		ci.draw_texture_rect(hd, Rect2(cell.x * CELL + (CELL - SPRITE_W) * 0.5, cell.y * CELL + CELL - h - 0.5, SPRITE_W, h), false, modulate)
		return
	var r := Atlas.region(name)
	ci.draw_texture_rect_region(Atlas.texture, Rect2(cell.x * CELL, cell.y * CELL + CELL - r.size.y, r.size.x, r.size.y), r, modulate)


func _tile(ci: CanvasItem, name: String, cell: Vector2i, modulate: Color = Color.WHITE) -> void:
	var dst := Rect2(cell * CELL, Vector2(CELL, CELL))
	var hd := Art.tex(name)
	if hd != null:
		ci.draw_texture_rect(hd, dst, false, modulate)
	else:
		ci.draw_texture_rect_region(Atlas.texture, dst, Atlas.region(name), modulate)


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
	## base, base_b or base_c, using only the looks that exist.
	var names := [base]
	for suffix in ["_b", "_c"]:
		if Art.has(base + suffix) or (not Art.has(base) and Atlas.regions.has(base + suffix)):
			names.append(base + suffix)
	return names[v % names.size()]


# ---------------------------------------------------------------- layer 1: ground
func _draw() -> void:
	if city == null:
		return
	var n := City.N
	var hd_ground := Art.has("tex_grass")
	for y in n:
		for x in n:
			var i := City.idx(x, y)
			var p := Vector2i(x, y)
			# tiny brightness change per cell so a big lawn is not one flat repeat
			var shade := 1.0 + (((x * 7 + y * 13) % 5) - 2) * 0.015
			var tint := Color(shade, shade, shade)
			if city.terrain[i] == Defs.T.WATER:
				_tile(self, "tex_water" if hd_ground else "water0", p)
				_shore(p)
			else:
				_tile(self, "tex_grass" if hd_ground else "grass%d" % ((x * 7 + y * 13) % 3), p, tint)
			if city.obj[i] == Defs.ROAD:
				var m := _road_mask(p)
				_tile(self, ("bridge%d" if city.terrain[i] == Defs.T.WATER else "road%d") % m, p)
			elif city.zone[i] != Defs.Z.NONE and (city.level[i] == 0 or city.build[i] > 0):
				_lot(p, city.zone[i])
	if overlay != "":
		_draw_overlay()
	buildings.queue_redraw()
	overlays.queue_redraw()


func _shore(p: Vector2i) -> void:
	var edge := Color(0.9, 0.84, 0.62)
	for k in 4:
		var q: Vector2i = p + City.DIRS[k]
		if not City.inside(q.x, q.y) or city.terrain[City.idx(q.x, q.y)] == Defs.T.WATER:
			continue
		var r := Rect2(p * CELL, Vector2(CELL, CELL))
		match k:
			0:
				draw_rect(Rect2(r.position, Vector2(CELL, 1.5)), edge)
			1:
				draw_rect(Rect2(r.position + Vector2(CELL - 1.5, 0), Vector2(1.5, CELL)), edge)
			2:
				draw_rect(Rect2(r.position + Vector2(0, CELL - 1.5), Vector2(CELL, 1.5)), edge)
			3:
				draw_rect(Rect2(r.position, Vector2(1.5, CELL)), edge)


const ZONE_EMBLEM := ["", "ui_res", "ui_com", "ui_ind"]


func _lot(p: Vector2i, z: int) -> void:
	_tile(self, "lot_" + ZONE_KEY[z], p)
	var col: Color = Defs.ZONE_COLORS[z]
	draw_rect(Rect2(p * CELL, Vector2(CELL, CELL)), Color(col.darkened(0.2), 0.8), false, 0.6)
	# faint house / shop / factory picture: "this is a residential / commercial / industrial plot"
	var emblem := Art.tex(ZONE_EMBLEM[z])
	if emblem != null:
		var w := 9.0
		var h := w * emblem.get_height() / emblem.get_width()
		draw_texture_rect(emblem, Rect2(p.x * CELL + (CELL - w) * 0.5, p.y * CELL + CELL - h - 2.0, w, h), false, Color(1, 1, 1, 0.55))


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


# ---------------------------------------------------------------- layer 2: buildings
func _draw_buildings(ci: CanvasItem) -> void:
	if city == null:
		return
	for y in City.N:
		for x in City.N:
			var s := sprite_for(City.idx(x, y))
			if s != "":
				_spr(ci, s, Vector2i(x, y))
	if ghost_cell >= 0 and ghost != "":
		_spr(ci, ghost, City.pos(ghost_cell), Color(1, 1, 1, 0.75))


# ---------------------------------------------------------------- layer 3: overlays
func _draw_overlays(ci: CanvasItem) -> void:
	if city == null:
		return
	for c in fires:
		_spr(ci, "fire%d" % (int(time * 8.0) % 2), City.pos(c))
	_draw_warnings(ci)
	_draw_locked(ci)
	_draw_preview(ci)
	if selected >= 0:
		var sp := City.pos(selected)
		ci.draw_rect(Rect2(sp * CELL, Vector2(CELL, CELL)), Color(1, 0.95, 0.4), false, 1.0)


const WARN := {"road": "warn_road", "power": "warn_power", "water": "warn_water"}
const WARN_OLD := {"road": "icon_road", "power": "icon_power", "water": "icon_water"}
const WARN_SIZE := 9.0


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
			ci.draw_rect(Rect2(City.pos(i) * CELL, Vector2(CELL, CELL)), Color(1.0, 0.15, 0.1, pulse))
			any = true
	if any or city.road_count < 14:
		_draw_highway_arrow(ci)
		any = true
	var bob := sin(time * 4.0) * 0.8
	for i in City.CELLS:
		var w := warning_of(i)
		if w == "":
			continue
		any = true
		var p := City.pos(i)
		var built := city.level[i] > 0 and city.build[i] == 0
		var top := p.y * CELL + 1.0
		if built:
			var hd := Art.tex(sprite_for(i))
			var h := SPRITE_W * hd.get_height() / hd.get_width() if hd != null else 8.0
			top = p.y * CELL + CELL - h - WARN_SIZE + 1.0
		var tex := Art.tex(WARN[w])
		if tex != null:
			var size := Vector2(WARN_SIZE, WARN_SIZE * tex.get_height() / tex.get_width())
			ci.draw_texture_rect(tex, Rect2(Vector2(p.x * CELL + (CELL - size.x) * 0.5, top + bob), size), false)
		else:
			var r := Atlas.region(WARN_OLD[w])
			ci.draw_texture_rect_region(Atlas.texture, Rect2(Vector2(p.x * CELL + 4.5, top + bob), r.size), r)
	has_warnings = any


func _draw_highway_arrow(ci: CanvasItem) -> void:
	## Bobbing arrow over the end of the highway: build roads from here.
	# the highway is built up to one cell inside the starting square (City._generate_once)
	var p := Vector2i((City.N - Defs.rank_size(0)) / 2 + 1, City.pos(city.entrance).y)
	var c := Vector2(p * CELL) + Vector2(CELL * 0.5, -3.0 + sin(time * 5.0) * 1.5)
	var pts := PackedVector2Array([c + Vector2(-5, -7), c + Vector2(5, -7), c + Vector2(5, -3), c + Vector2(8, -3), c + Vector2(0, 4), c + Vector2(-8, -3), c + Vector2(-5, -3)])
	ci.draw_colored_polygon(pts, Color(1.0, 0.85, 0.2))
	pts.append(pts[0])
	ci.draw_polyline(pts, Color(0.17, 0.14, 0.21), 0.8)


func _draw_locked(ci: CanvasItem) -> void:
	var a := city.active_rect()
	var full := City.N * CELL
	var r := Rect2(a.position * CELL, a.size * CELL)
	ci.draw_rect(Rect2(0, 0, full, r.position.y), LOCKED)
	ci.draw_rect(Rect2(0, r.end.y, full, full - r.end.y), LOCKED)
	ci.draw_rect(Rect2(0, r.position.y, r.position.x, r.size.y), LOCKED)
	ci.draw_rect(Rect2(r.end.x, r.position.y, full - r.end.x, r.size.y), LOCKED)
	ci.draw_rect(r, Color(1, 1, 1, 0.5), false, 1.0)


func _draw_preview(ci: CanvasItem) -> void:
	for c in preview:
		var col := Color(0.4, 1.0, 0.5, 0.45) if preview[c] else Color(1.0, 0.3, 0.3, 0.45)
		ci.draw_rect(Rect2(City.pos(c) * CELL, Vector2(CELL, CELL)), col)
	if ghost_cell >= 0 and ghost_radius > 0:
		var center := Vector2(City.pos(ghost_cell) * CELL) + Vector2(CELL, CELL) * 0.5
		ci.draw_arc(center, (ghost_radius + 0.5) * CELL, 0, TAU, 64, Color(1, 1, 1, 0.8), 1.0)


func cell_center(i: int) -> Vector2:
	return Vector2(City.pos(i) * CELL) + Vector2(CELL, CELL) * 0.5
