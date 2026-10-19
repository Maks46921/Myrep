extends SceneTree
# 0.55.5: политкапитал уходит в минус; в минусе растёт риск вотума недоверия
func _init():
	var cc := "DE"
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("country="): cc = String(a).substr(8)
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	g.capital = 2.0
	g.do_action(String(g.ACTIONS[0]["id"]))
	print("after action cost ", g.ACTIONS[0]["cost"], ": capital=", g.capital)
	g.capital = -40.0
	print("risk=", g.cap_neg_risk(), " spendable=", g.cap_spendable())
	var nocon := 0
	var last: int = g.last_nocon
	for m in 24:
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty(): g.choose(0)
		g.capital = minf(g.capital, -40.0)
		g.next_turn()
		if g.last_nocon != last:
			nocon += 1
			last = g.last_nocon
	print("nocon votes in 24 months at -40: ", nocon, " game_over=", g.game_over, " capital=", g.capital)
	quit()
