extends SceneTree
var g
func _init():
	var s = load("res://main.gd")
	g = s.new()
	root.add_child(g)
	await process_frame
	await process_frame
	var bad := 0
	for d in [0, 1, 2, 3, 4, 5, 6]:
		g.show_desk(d)
		await process_frame
	for l in range(27):
		g.map_layer = l
		g.show_desk(2)
		g.refresh()
	g.show_desk(5)
	for i in range(60):
		if not g.current_event.is_empty():
			g.choose(randi() % g.current_event["o"].size())
		if g.election_open:
			g.election_continue()
		g.next_turn()
		if g.game_over:
			break
		for k in ["inflation", "unemployment", "growth", "gdp", "debt"]:
			var v: float = g.get(k)
			if is_nan(v) or is_inf(v):
				print("NAN ", k, " turn ", g.turn)
				bad += 1
		for m in g.ec["mk"]:
			for f in g.ec["mk"][m]:
				if typeof(g.ec["mk"][m][f]) == TYPE_FLOAT and (is_nan(g.ec["mk"][m][f]) or is_inf(g.ec["mk"][m][f])):
					print("NAN mk ", m, f); bad += 1
		g.refresh()
	print("turn ", g.turn, " over ", g.game_over, " infl ", g.inflation, " unemp ", g.unemployment, " growth ", g.growth, " bad ", bad)
	print("util ", g.ec["util"], " bconf ", g.ec["bconf"], " inv ", g.ec["inv"], " fxs ", g.ec["fxs"], " ppi ", g.ec["ppi"], " rate ", g.ec["rate"], " nx ", g.ec["nx"])
	quit()
