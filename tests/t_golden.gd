extends SceneTree
# Детерминированный прогон (нужен seed=N): 72 месяца, первый вариант в событиях; печатает отпечаток состояния.
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	var lines := []
	for m in 72:
		if g.game_over: break
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty(): g.choose(0)
		g.next_turn()
		if m % 12 == 11:
			lines.append("m%d gdp %.3f debt %.3f infl %.4f unemp %.4f appr %.3f cap %.2f seats %s" % [m + 1, g.gdp, g.debt, g.inflation, g.unemployment, g.approval(), g.capital, str(g.seats)])
	for l in lines: print(l)
	var sh: Array = g.national_shares(false)
	var s := ""
	for x in sh: s += "%.3f " % x
	print("shares ", s, " over ", g.game_over, " turn ", g.turn)
	quit()
