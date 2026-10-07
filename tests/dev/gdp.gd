extends SceneTree
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	for m in 36:
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty(): g.choose(0)
		g.next_turn()
		if m % 6 == 0: print("m%d gdp %.1f infl %.2f growth %.2f u %.1f" % [m, g.gdp, g.inflation, g.growth, g.unemployment])
	quit()
