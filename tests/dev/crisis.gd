extends SceneTree
# dev: выход из правительственного кризиса (country=PL months=N pick=K)
func _init():
	var months := 100
	var pick := 0
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("months="): months = int(String(a).substr(7))
		if String(a).begins_with("pick="): pick = int(String(a).substr(5))
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	for m in months:
		if g.game_over: break
		if not g.current_event.is_empty():
			var ev: Dictionary = g.current_event
			if String(ev.get("special", "")) == "crisis":
				print("t=%d CRISIS: %s" % [g.turn, ev["t"]])
				for o in ev["o"]: print("   - ", o["l"])
				g.choose(mini(pick, ev["o"].size() - 1))
				print("   => gov_ok %s seats %d minority %s techno %d coal %s" % [g.gov_ok(), g.gov_seats(), g.minority_gov, g.techno_until, g.coalition_names()])
			else:
				g.choose(0)
		if g.election_open: g.election_continue()
		var lp: int = g.last_parl
		g.next_turn()
		if g.election_open: g.election_continue()
		if g.last_parl != lp: print("t=%d ELECTION gov_ok %s seats %d crisis %d deadlock %d cap %.1f coal %s" % [g.turn, g.gov_ok(), g.gov_seats(), g.crisis_months, g.deadlock, g.capital, g.coalition_names()])
		if g.crisis_months == 1: print("t=%d crisis start, seats %d, minority %s, cap %.1f" % [g.turn, g.gov_seats(), g.minority_gov, g.capital])
	quit()
