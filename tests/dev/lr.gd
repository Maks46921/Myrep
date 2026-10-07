extends SceneTree
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	for m in 360:
		if g.game_over: break
		if g.election_open: g.election_continue()
		var guard := 0
		while not g.current_event.is_empty() and guard < 5:
			g.choose(0); guard += 1
		g.next_turn()
		if g.election_open: g.election_continue()
		if m % 24 == 0: print("m%d gdp %.0f g %.2f infl %.2f u %.1f debt %.0f opp %s" % [m, g.gdp, g.growth, g.inflation, g.unemployment, g.debt / g.gdp * 100.0, g.opp_mode])
	print("END ", g.game_over, " ", String(g.end_reason).substr(0,50))
	quit()
