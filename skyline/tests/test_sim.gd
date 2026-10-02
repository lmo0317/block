extends Node
## Plays whole runs with CityBot on several seeds and checks the rules hold together.
## Prints a balance table. Run: Godot --headless --path . res://tests/test_sim.tscn

var fails := 0


func check(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", what)


func _ready() -> void:
	_rules()
	_runs()
	_save_round_trip()
	print("test_sim: ", "OK" if fails == 0 else "%d FAILED" % fails)
	get_tree().quit(1 if fails else 0)


func _rules() -> void:
	var c := City.new()
	c.new_game(5)
	var r := c.active_rect()
	check(r.size.x == 16, "start square is 16")
	check(c.obj[c.entrance] == Defs.ROAD, "highway starts at the edge")
	c.refresh()
	check(c.connected[c.entrance] == 1, "entrance is connected")
	# a lot next to the highway with power and water grows into a house
	var hp := City.pos(c.entrance)
	var lot := City.idx(r.position.x + 1, hp.y - 1)
	c.terrain[lot] = Defs.T.GRASS
	check(c.place_zone(lot, Defs.Z.R) == Defs.ZONE_COST, "zone costs ZONE_COST")
	var p_cell := City.idx(r.position.x + 3, hp.y + 2)
	var w_cell := City.idx(r.position.x + 4, hp.y + 2)
	c.terrain[p_cell] = Defs.T.GRASS
	c.terrain[w_cell] = Defs.T.GRASS
	c.money = 5000
	check(c.place_facility(p_cell, 2) > 0, "power plant placed")
	check(c.place_facility(w_cell, 3) > 0, "water tower placed")
	check(c.place_facility(p_cell, 3) == -1, "cannot stack facilities")
	c.refresh()
	check(c.working(lot), "lot has road, power and water")
	var grew := false
	for k in 40:
		c.step_week()
		if c.level[lot] > 0 and c.build[lot] == 0:
			grew = true
			break
	check(grew, "house grows on a serviced lot")
	check(c.pop > 0, "population counts the house")
	# bulldoze returns the cell to grass
	c.bulldoze(lot)
	check(c.zone[lot] == 0 and c.level[lot] == 0, "bulldoze clears the lot")
	# locked area cannot be edited
	check(c.place_road(City.idx(0, 0)) == -1, "outside the square is locked")


func _runs() -> void:
	print("seed  rank  pop   C    I   money  lmk happy score")
	var totals := []
	for s in [1, 2, 3, 4, 5, 6]:
		var c := City.new()
		c.new_game(s)
		var bot := CityBot.new(c)
		var ranks := []
		c.rank_up.connect(func(r): ranks.append("%d@%d" % [r, c.month]))
		bot.run()
		check(c.finished, "seed %d run finishes after 10 years" % s)
		check(c.final_score > 0, "seed %d has a score" % s)
		print("%4d  %4d %5d %4d %4d %6d %4d %4d %6d  %s" % [s, c.rank, c.pop, c.cjobs, c.ijobs, c.money, c.landmarks, c.happiness, c.final_score, " ".join(ranks)])
		totals.append(c.rank)
	var reached := 0
	for r in totals:
		if r >= 2:
			reached += 1
	check(reached >= 3, "the simple bot reaches 소도시 on most seeds")


func _save_round_trip() -> void:
	var c := City.new()
	c.new_game(9)
	var bot := CityBot.new(c)
	bot.run(2)
	var d := c.to_dict()
	var json := JSON.stringify(d)
	var c2 := City.new()
	check(c2.from_dict(JSON.parse_string(json)), "save loads")
	check(c2.money == c.money and c2.month == c.month and c2.pop == c.pop, "save keeps money, date, population")
	check(c2.obj == c.obj and c2.level == c.level, "save keeps the map")
	# both continue the same way
	for k in 8:
		c.step_week()
		c2.step_week()
	check(c2.pop == c.pop and c2.money == c.money, "loaded city continues identically")
