class_name Walkers
extends Node2D
## Citizens and cars moving along the roads, in map pixels. Citizens walk from a home to a shop,
## park or landmark; when one enters a shop a coin pops (shop_visit). Cars are decoration.

signal shop_visit(cell: int)

const CELL := 16
const MAX_CITIZENS := 36
const MAX_CARS := 14

var city: City
var speed := 1.0                # game speed; 0 = paused
var walkers: Array = []         # {path: Array[Vector2], t, speed, sprite, car, dest}
var homes: Array[int] = []
var places: Array[int] = []     # shops, parks, landmarks with a road
var spawn_timer := 0.0
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rng.randomize()


func city_changed() -> void:
	homes.clear()
	places.clear()
	for i in City.CELLS:
		if city.access_road[i] < 0:
			continue
		var k := city.kind_of(i)
		if k == "":
			continue
		if city.zone[i] == Defs.Z.R and city.working(i):
			homes.append(i)
		elif (city.zone[i] == Defs.Z.C and city.working(i)) or k in ["park", "fountain", "clock", "wheel", "stadium"]:
			places.append(i)
	# drop walkers whose road was removed
	walkers = walkers.filter(func(w): return _path_ok(w))


func _path_ok(w: Dictionary) -> bool:
	for c in w["cells"]:
		if city.obj[c] != Defs.ROAD:
			return false
	return true


func clear() -> void:
	walkers.clear()
	queue_redraw()


func _process(delta: float) -> void:
	if city == null:
		return
	if speed > 0.0:
		var pace := 1.0 + (speed - 1.0) * 0.5
		spawn_timer -= delta * pace
		if spawn_timer <= 0.0:
			spawn_timer = 0.25
			_spawn()
		for w in walkers:
			w["t"] += delta * w["speed"] * pace
		var done := walkers.filter(func(w): return w["t"] >= w["path"].size() - 1)
		for w in done:
			if w["dest"] >= 0:
				shop_visit.emit(w["dest"])
		walkers = walkers.filter(func(w): return w["t"] < w["path"].size() - 1)
	queue_redraw()


func _count(car: bool) -> int:
	var n := 0
	for w in walkers:
		if w["car"] == car:
			n += 1
	return n


func _spawn() -> void:
	var want_cit := mini(MAX_CITIZENS, city.pop / 12 + (2 if city.pop > 0 else 0))
	var want_car := mini(MAX_CARS, (city.cjobs + city.ijobs) / 18)
	if _count(false) < want_cit and not homes.is_empty() and not places.is_empty():
		var home: int = homes[rng.randi_range(0, homes.size() - 1)]
		var dest: int = places[rng.randi_range(0, places.size() - 1)]
		var cells := _route(city.access_road[home], city.access_road[dest])
		if not cells.is_empty() and cells.size() <= 40:
			var pts: Array[Vector2] = [_center(home)]
			var side := Vector2(rng.randf_range(-4.0, 4.0), rng.randf_range(-4.0, 4.0))
			for c in cells:
				pts.append(_center(c) + side)
			pts.append(_center(dest) + Vector2(0, 4))
			walkers.append({"path": pts, "cells": cells, "t": 0.0, "speed": rng.randf_range(1.4, 2.0),
				"sprite": rng.randi_range(0, 5), "car": false, "dest": dest if city.zone[dest] == Defs.Z.C else -1})
	if _count(true) < want_car:
		var roads := _random_road()
		if roads >= 0:
			var target := _random_road()
			var cells := _route(roads, target)
			if cells.size() >= 4:
				var pts: Array[Vector2] = []
				for c in cells:
					pts.append(_center(c))
				walkers.append({"path": pts, "cells": cells, "t": 0.0, "speed": rng.randf_range(2.5, 3.5),
					"sprite": rng.randi_range(0, 3), "car": true, "dest": -1})


func _random_road() -> int:
	for k in 20:
		var i := rng.randi_range(0, City.CELLS - 1)
		if city.connected[i] == 1 and city.is_active(i):
			return i
	return -1


func _center(i: int) -> Vector2:
	return Vector2(City.pos(i) * CELL) + Vector2(CELL, CELL) * 0.5


func _route(a: int, b: int) -> Array:
	## Shortest road path a -> b (cells), [] when unreachable.
	if a < 0 or b < 0:
		return []
	if a == b:
		return [a]
	var prev := {a: -1}
	var queue: Array[int] = [a]
	var head := 0
	while head < queue.size():
		var c := queue[head]
		head += 1
		if c == b:
			break
		var p := City.pos(c)
		for d in City.DIRS:
			var q: Vector2i = p + d
			if not City.inside(q.x, q.y):
				continue
			var j := City.idx(q.x, q.y)
			if city.obj[j] == Defs.ROAD and not prev.has(j):
				prev[j] = c
				queue.append(j)
	if not prev.has(b):
		return []
	var out: Array = []
	var c := b
	while c != -1:
		out.push_front(c)
		c = prev[c]
	return out


func _draw() -> void:
	for w in walkers:
		var path: Array = w["path"]
		var t: float = w["t"]
		var k := int(t)
		var f := t - k
		var a: Vector2 = path[k]
		var b: Vector2 = path[mini(k + 1, path.size() - 1)]
		var at := a.lerp(b, f)
		var dir := b - a
		if w["car"]:
			var vertical := absf(dir.y) > absf(dir.x)
			var name := ("car_v%d" if vertical else "car_h%d") % w["sprite"]
			var r := Atlas.region(name)
			# keep to the right-hand lane
			var lane := Vector2(-2.5, 0) if (vertical and dir.y < 0) else (Vector2(2.5, 0) if vertical else (Vector2(0, -2.5) if dir.x < 0 else Vector2(0, 2.5)))
			draw_texture_rect_region(Atlas.texture, Rect2((at + lane - r.size * 0.5).round(), r.size), r)
		else:
			var frame := int(t * 4.0) % 2
			var r := Atlas.region("cit%d_%d" % [w["sprite"], frame])
			draw_texture_rect_region(Atlas.texture, Rect2((at - Vector2(r.size.x * 0.5, r.size.y)).round(), r.size), r)
