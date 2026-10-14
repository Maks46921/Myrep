extends SceneTree
# v54_1 (отладка): помесячный отпечаток для сравнения русской и английской версий (main=res://en/main.gd)
func _init():
	var mp := "res://main.gd"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("main="): mp = a.substr(5)
	var g = load(mp).new()
	root.add_child(g)
	for i in 3: await process_frame
	for m in 14:
		if g.election_open: g.election_continue()
		var ev := ""
		if not g.current_event.is_empty():
			ev = str(g.current_event.get("id", "")) + "/" + str(str(g.current_event.get("t", "")).length())
			var o0: Dictionary = (g.current_event.get("opts", g.current_event.get("o", [{}])) as Array)[0] if g.current_event.has("opts") or g.current_event.has("o") else {}
			print("EV keys ", g.current_event.keys(), " opt0 ", o0.get("fx", o0))
			g.choose(0)
			var sp := []
			for k in g.GROUPS: sp.append("%.5f" % float(g.support[k]))
			print("after choose sup ", sp, " cap %.4f gdp %.6f debt %.6f" % [g.capital, g.gdp, g.debt])
		g.next_turn()
		print("m%d gdp %.6f infl %.6f unemp %.6f appr %.6f cap %.3f ev %s" % [m + 1, g.gdp, g.inflation, g.unemployment, g.approval(), g.capital, ev])
	quit()
