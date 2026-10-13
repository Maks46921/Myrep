extends SceneTree
func _init():
	var g = load("res://main.gd").new()
	g.game_opts.merge({"agents": false, "seed": 11, "ev": 0.0, "news": 0.0, "milev": 0, "revev": 1, "rlev": 1, "exev": 1, "ongoing": false}, true)
	root.add_child(g)
	for i in 4: await process_frame
	var t: String = String(g.tech_nb()[0])
	g.capital = 100.0
	g.ex_aid_give(t)
	var prev: float = float(g.fa["mem"].get(t, 0.0))
	for m in 24:
		if g.election_open: g.election_continue()
		var k := 0
		while not g.current_event.is_empty() and k < 8:
			print("  ev ", g.current_event.get("id", g.current_event.get("t", "").left(50)), " opp=", g.opp_mode)
			g.choose(0)
			k += 1
		var before: float = float(g.fa["mem"].get(t, 0.0))
		var n0: int = g.log_entries.size()
		g.next_turn()
		var now: float = float(g.fa["mem"].get(t, 0.0))
		print("m", m, " opp=", g.opp_mode, " mem ", "%.2f -> %.2f" % [before, now], (" <<<" if now < before * 0.95 else ""))
		if now < before * 0.95:
			for j in range(n0, g.log_entries.size()):
				print("     | ", str(g.log_entries[j]).left(220))
	quit()
