extends SceneTree
# Баланс технологий: godot --headless --path . --script tests/dev/tech_bal.gd -- country=DE edu=1.5 bld=1 years=100 media=0
func _init():
	var kmul := 1.0
	var bld := 0
	var years := 100
	var media := -1
	var notech := false
	var seed := 5
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("edu="): kmul = float(String(a).substr(4))
		if String(a).begins_with("bld="): bld = int(String(a).substr(4))
		if String(a).begins_with("years="): years = int(String(a).substr(6))
		if String(a).begins_with("seed="): seed = int(String(a).substr(5))
		if String(a) == "notech": notech = true
		if String(a).begins_with("media="): media = int(String(a).substr(6))
	var g = load("res://main.gd").new()
	g.game_opts.merge({"agents": false, "ev": 1.0, "fedev": 0, "socev": 0, "exev": 0, "milev": 0, "seed": seed}, true)
	root.add_child(g)
	for i in 5: await process_frame
	g.ap["bal"] = true
	g.ap["events"] = true
	g.pol["edu"] = minf(float(g.pol["edu"]) * kmul, 10.0)
	if media >= 0:
		g.law_state["media_law"] = media
	if notech:
		g.tech["w"] = [0, 0, 0, 0]
	var edu_fix: float = g.pol["edu"]
	var rows := []
	var gdp0: float = g.gdp
	for m in years * 12:
		if g.game_over:
			if g.debt / g.gdp > 1.4 or g.inflation >= 28.0: break
			g.game_over = false     # отставки по рейтингу для баланса не нужны
			g.low_months = 0
			g.end_reason = ""
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty(): g.choose(0)
		g.capital = 100.0
		g.pol["edu"] = edu_fix        # совет коалиции сам двигает ползунки; для баланса держим выбранный уровень
		if bld > 0 and g.turn % 6 == 0:
			for d in g.TECH_BUILDINGS:
				if bld == 1 and d["id"] in ["rc", "campus"]:
					g.tech_build(d["id"])
				elif bld == 2:
					g.tech_build(d["id"])
		for bb in g.TECH_NB:        # внимательный игрок: на уровнях «или» сразу выбирает самую дешёвую
			if g.tech_choice_waiting(bb):
				g.tech["cur"][bb] = g.tech_ai_pick(bb, true)
		g.next_turn()
		if g.turn % 120 == 0:
			rows.append("  %3d лет: техн. %2d/%d скор %.1f/потолок %.1f сыр %.1f | рост+ %.2f эфф %.2f корр %.0f | ВВП %.0f долг%% %.0f безр %.1f" % [g.turn / 12, g.tech_count(), g.tech_total(), g.tech["speed"], g.tech["cap"], g.tech["raw"], float(g.mods["growth_bonus"]), float(g.mods["edu_eff"]), float(g.lvl["corruption"]), g.gdp, g.debt / g.gdp * 100.0, g.unemployment])
	print("== %s edu×%.1f bld=%d media=%d" % [g.ccode, kmul, bld, media])
	for r in rows: print(r)
	print("RES|%s|%d|%.1f|%d|%s|%d|%.0f|%d|%.2f" % [g.ccode, seed, kmul, bld, str(notech), years, g.gdp, g.tech_count(), float(g.mods["growth_bonus"])])
	var ch := PackedStringArray()
	for id in g.tech["done"]:
		if g.tech_is_choice(String(id)): ch.append(String(id))
	print("  выборы: ", " ".join(ch), " | сооружения ", g.tech["bld"], " | игра окончена: ", g.game_over, " ", g.end_reason, " на %d-м году" % (g.turn / 12))
	quit()
