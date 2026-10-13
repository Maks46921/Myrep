extends SceneTree
# Прогон механик режима: godot --headless --path . --script tests/dev/au_sim.gd -- country=RU years=5 install=dictatorship act=1
func _init():
	var years := 5
	var inst := ""
	var act := 0
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("years="): years = int(String(a).substr(6))
		if String(a).begins_with("install="): inst = String(a).substr(8)
		if String(a).begins_with("act="): act = int(String(a).substr(4))
	var g = load("res://main.gd").new()
	g.game_opts.merge({"seed": 3}, true)
	root.add_child(g)
	for i in 5: await process_frame
	print("start cls=", g.au.get("cls"), " dem=", snappedf(g.democracy_index(), 0.01), " fear=", snappedf(float(g.au.get("fear", 0)), 0.1), " prop=", snappedf(float(g.au.get("prop", 0)), 0.1), " fraud=", snappedf(float(g.au.get("fraud", 0)), 0.1))
	if inst != "":
		g.support["Силовики"] = 80.0
		print("install ", inst, " -> ", g.rv_install_regime(inst))
		g.au_step()
		print("cls now=", g.au["cls"])
	for m in years * 12:
		if g.game_over: break
		if g.election_open: g.election_continue()
		while not g.current_event.is_empty():
			g.choose(0)
			if g.game_over: break
		if act == 1 and m % 6 == 0 and g.au_on():
			for k in g.au["cl"]:
				if float(g.au["cl"][k]["loy"]) < 45.0:
					g.au_act("reward:" + String(k))
			if g.au_und_max() > 50.0: g.au_act("arrests")
		g.next_turn()
		if m % 12 == 11 and g.au_on():
			var cl := []
			for k in g.au["cl"]:
				cl.append("%s:%d/%d%%" % [k, int(g.au["cl"][k]["loy"]), int(float(g.au["cl"][k]["w"]) * 100)])
			print("y", m / 12 + 1, " ", g.au["cls"], " appr=", int(g.approval()), " off=", int(g.au_official_approval()), " risk=", int(g.regime_risk), " add=", snappedf(g.au_risk_add(), 0.1), " fear=", int(g.au["fear"]), " und=", int(g.au_und_max()), " pris=", g.au["pris"], " gdp_g=", snappedf(g.growth, 0.1), " ", " ".join(cl))
	print("over=", g.game_over, " ", g.game_over_msg if "game_over_msg" in g else "")
	quit()
