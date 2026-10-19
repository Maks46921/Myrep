extends SceneTree
# Отладка (v53_1): отношения страны с миром — санкции, память, постоянные факторы, по годам.
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	var yrs := 6
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("years="): yrs = int(String(a).substr(6))
	var peace_at := -1
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("peace="): peace_at = int(String(a).substr(6))
	for i in yrs * 12:
		if g.game_over:
			break
		if not g.current_event.is_empty():
			g.choose(randi() % g.current_event["o"].size())
		if g.election_open:
			g.election_continue()
		g.next_turn()
		if g.election_open:
			g.election_continue()
		if i % 12 == 0 and g.fa_on():
			var s := []
			for c in g.fa_bots():
				if (g.fa["sanc"] as Dictionary).has(c): s.append(c)
			var avg := 0.0
			for c in g.fa_bots(): avg += g.fed_rel(c) if g.dip.has(c) else 50.0
			avg /= maxf(1.0, g.fa_bots().size())
			print("%s дем %.2f санкции %d ЕС %s ср.отн %.0f мир %.0f режим %d rl.g %.2f рост %.2f война %s" % [g.date_text(), g.democracy_index(), s.size(), g.fa_eu_sanc(), avg, g.fa_world(), g.fa_ws_lvl(), float(g.rl.get("g", 0.0)), g.growth, g.mil_at_war()])
		if peace_at > 0 and i == peace_at and g.mil_at_war():
			print("  мир: ", g.mil_peace("white").get("msg", ""))
			print(g.fa_ws_text())
		if peace_at > 0 and i > peace_at and i % 6 == 0 and g.current_event.is_empty():
			g.capital = 60.0
			for id in ["ws_comp", "ws_talks"]:
				if g.fa_ws_do(id):
					print("  %s: режим %d %s rep %d" % [id, g.fa_ws_lvl(), str(g.fa_ws_step_ok()), int(g.fa_ws()["rep"])])
			if g.au_on() and int(g.au.get("pris", 0)) >= 50:
				g.au_act("amnesty")
	print(g.fa_ws_text())
	quit()
