extends SceneTree
# dev: трасса капитала/коалиции по месяцам: country=XX months=N party=K
func _init():
	var months := 60
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("months="): months = int(String(a).substr(7))
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	for m in months:
		if g.game_over: break
		var cap0: float = g.capital
		var lp: int = g.last_parl
		if not g.current_event.is_empty(): g.choose(0)
		if g.election_open: g.election_continue()
		g.next_turn()
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty() and g.current_event.get("special", "") == "": pass
		print("t=%d cap %.1f->%.1f seats_gov %d/%d crisis %d opp %s elec %s coal %s" % [g.turn, cap0, g.capital, g.gov_seats(), g.SEATS, g.crisis_months, g.opp_mode, "YES" if g.last_parl != lp else "", g.coalition_names()])
	quit()
