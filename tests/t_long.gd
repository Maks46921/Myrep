extends SceneTree
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	var parl := 0
	var head := 0
	var bad := 0
	var n := 180
	for i in n:
		if g.game_over:
			break
		if not g.current_event.is_empty():
			g.choose(randi() % g.current_event["o"].size())
		if g.election_open:
			if g.el_head.visible:
				head += 1
			else:
				parl += 1
			g.election_continue()
		if g.game_over:
			break
		g.next_turn()
		if g.election_open:
			if g.el_head.visible:
				head += 1
			else:
				parl += 1
			g.election_continue()
		for k in ["inflation", "unemployment", "growth", "gdp", "debt"]:
			var v: float = g.get(k)
			if is_nan(v) or is_inf(v):
				bad += 1
	print("%s: ход %d, конец игры %s (%s), парл. выборов %d, главы гос-ва %d, NaN %d, pres_due %d" % [g.ccode, g.turn, g.game_over, g.end_reason.substr(0, 50), parl, head, bad, g.pres_due])
	quit()
