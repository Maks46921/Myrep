extends SceneTree
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	var s := 0.0
	for m in 24:
		if g.election_open: g.election_continue()
		while not g.current_event.is_empty(): g.choose(0)
		g.next_turn()
		if g.election_open: g.election_continue()
		s += g.growth
	print("G12 %s avg_growth_2y %.2f u %.1f infl %.1f" % [g.ccode, s / 24.0, g.unemployment, g.inflation])
	quit()
