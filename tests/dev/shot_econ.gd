extends SceneTree
# v51: «Управление экономикой» и «Корпорации» при разных моделях.
#   country=XX model=mixed|market|social|statecap|planned|coop|libertarian out=DIR months=N
func _init():
	var outd := "/tmp"
	var model := "mixed"
	var months := 4
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="): outd = String(a).substr(4)
		if String(a).begins_with("model="): model = String(a).substr(6)
		if String(a).begins_with("months="): months = int(String(a).substr(7))
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 6: await process_frame
	if model != "mixed":
		var vs: Array = g.law_index["econ_model"]["v"]
		for k in vs.size():
			var v: Dictionary = vs[k]
			var n: String = String(v.get("n", ""))
			var rid: String = String(v.get("rid", ""))
			if rid == model or (model == "market" and n.begins_with("Рыночн")) or (model == "social" and n.begins_with("Социальн")) or (model == "statecap" and n.begins_with("Государственный капитализм")):
				var old: String = g.rid_of("econ_model")
				g.law_state["econ_model"] = k
				g.radical_enact("econ_model", k, old)
				g.recompute_mods()
				break
	print("econ_class=", g.econ_class())
	for m in months:
		while not g.current_event.is_empty():
			g.choose(0)
		if g.election_open: g.election_continue()
		g.next_turn()
	while not g.current_event.is_empty():
		g.choose(0)
	if g.election_open: g.election_continue()
	g.capital = 60.0
	if model == "statecap":
		g.es_act("prio:ind")
		g.es_act("credit:ene")
	g.corp["sel"] = 1
	g.show_desk(16)
	g.refresh()
	for i in 8: await process_frame
	await create_timer(0.6).timeout
	root.get_viewport().get_texture().get_image().save_png(outd + "/v51_es_%s.png" % model)
	g.show_desk(17)
	g.refresh()
	for i in 8: await process_frame
	await create_timer(0.6).timeout
	root.get_viewport().get_texture().get_image().save_png(outd + "/v51_co_%s.png" % model)
	quit()
