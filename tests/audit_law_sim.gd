extends SceneTree
# 0.57.1 (замечание 5): как закон влияет на рост ВВП на самом деле. Принимаем вариант и 24 месяца считаем рост против контроля.
# Запуск: godot --headless --path . --script tests/audit_law_sim.gd -- law=elect_threshold idx=3 country=DE
func run(tid: String, idx: int, sd: int = 12345) -> Array:
	var g = load("res://main.gd").new()
	g.game_opts.merge({"ev": 0.0, "news": 0.0}, true)
	root.add_child(g)
	await process_frame
	seed(sd)
	g.capital = 1000.0
	if idx >= 0:
		g.law_cd[tid] = 0
		g.adopt_variant(tid, idx, range(g.PARTY_NAMES.size()))
	var gr := []
	var rt := []
	for m in 24:
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty(): g.choose(0)
		g.next_turn()
		gr.append(g.growth)
	var res := [gr, g.gdp, g.cur_idx(tid) if idx >= 0 else -1, g.democracy_index(), g.mods.get("growth_bonus", 0.0)]
	g.queue_free()
	await process_frame
	return res
func _init():
	var tid := "elect_threshold"
	var idx := 3
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("law="): tid = String(a).substr(4)
		if String(a).begins_with("idx="): idx = int(String(a).substr(4))
	var cs := 0.0
	var ts := 0.0
	var cg := 0.0
	var tg := 0.0
	var n := 4
	for k in n:
		var c = await run(tid, -1, 100 + k)
		var t = await run(tid, idx, 100 + k)
		cs += c[1]
		ts += t[1]
		cg += (c[0] as Array).slice(0, 12).reduce(func(a, b): return a + b, 0.0) / 12.0
		tg += (t[0] as Array).slice(0, 12).reduce(func(a, b): return a + b, 0.0) / 12.0
		print("seed %d: gdp control %.1f treated %.1f; adopted idx %d" % [100 + k, c[1], t[1], t[2]])
	print("RESULT %s idx %d: mean growth 1st year control %.2f treated %.2f; gdp after 24m control %.1f treated %.1f" % [tid, idx, cg / n, tg / n, cs / n, ts / n])
	quit()
