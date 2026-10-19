extends SceneTree
# Одна партия до конца игры или до лимита месяцев. Печатает строку FINAL для tools/finals.py.
# godot --headless --path . --script tests/dev/finals.gd -- country=DE months=120 mode=passive seed=3
func _init():
	var months := 120
	var mode := "passive"
	var seed := 3
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("months="): months = int(String(a).substr(7))
		if String(a).begins_with("mode="): mode = String(a).substr(5)
		if String(a).begins_with("seed="): seed = int(String(a).substr(5))
	var g = load("res://main.gd").new()
	g.game_opts.merge({"agents": false, "seed": seed}, true)
	root.add_child(g)
	for i in 4: await process_frame
	if mode == "auto":
		g.ap["bal"] = true
	var m := 0
	while m < months and not g.game_over:
		if g.election_open: g.election_continue()
		var n := 0
		while not g.current_event.is_empty() and n < 8:
			g.choose(0)
			n += 1
		if mode == "auto":
			g.capital = maxf(g.capital, 10.0)
		g.next_turn()
		m += 1
	var why: String = g.end_reason if g.game_over else "дожила до лимита"
	var conf: int = g.rv["conf"].size() if not g.rv.is_empty() else 0
	print("FINAL|%s|%s|%d|%s|%.0f|%.0f|%.1f|%d" % [g.ccode, mode, m, why.replace("|", "/"), g.gdp, g.debt / maxf(1.0, g.gdp) * 100.0, g.approval(), conf])
	quit()
