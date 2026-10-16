extends SceneTree
# dev: экономика под автопилотом бюджета (bal=1) или без него: country=XX bal=0/1 months=N
func _init():
	var bal := false
	var months := 120
	for a in OS.get_cmdline_user_args():
		if String(a) == "bal=1": bal = true
		if String(a).begins_with("months="): months = int(String(a).substr(7))
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	g.ap["bal"] = bal
	for m in months:
		if g.game_over: break
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty(): g.choose(0)
		g.next_turn()
		if g.election_open: g.election_continue()
		if m % 6 == 0 or m == months - 1: print("m%d gdp %.0f g %.2f infl %.2f u %.1f debt %.0f def %.1f floor %s" % [m, g.gdp, g.growth, g.inflation, g.unemployment, g.debt / g.gdp * 100.0, g.last_deficit_pct, g.auto_floor_on])
	quit()
