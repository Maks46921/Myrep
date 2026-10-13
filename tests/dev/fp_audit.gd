extends SceneTree
# Аудит внешнеполитических реакций стран: сценарий против контрольного прогона с тем же зерном.
# Печатает FPA|сценарий|месяц|отношение цели|среднее ЕС|среднее всех|санкции/пошлины.
func mk():
	var g = load("res://main.gd").new()
	g.game_opts.merge({"agents": false, "seed": 11, "ev": 0.0, "news": 0.0, "milev": 0, "revev": 1, "rlev": 1}, true)
	root.add_child(g)
	return g

func rel_stats(g, target: String) -> Array:
	var eu := 0.0
	var neu := 0
	var all := 0.0
	var na := 0
	for c in g.wsim:
		if c == g.ccode or String(c).begins_with("SEP") or c == target: continue
		var r: float = g.fed_rel(String(c))
		all += r
		na += 1
		if bool(g.WORLD.get(c, {}).get("eu", false)):
			eu += r
			neu += 1
	return [g.fed_rel(target), eu / float(maxi(1, neu)), all / float(maxi(1, na))]

func run(sc: String, target: String) -> void:
	var g = mk()
	for i in 4: await process_frame
	g.capital = 100.0
	match sc:
		"insult": g.ex_rel_change(target, -20.0)
		"tariff":
			g.ex_tariff_set(target, 1)
			g.capital = 100.0
			g.ex_tariff_set(target, 1)
		"aid":
			g.ex_aid_give(target)
		"deal":
			g.ex_deal_set(target, 1)
		"spy":
			g.dx["cd"].clear()
			for k in 3:
				g.capital = 100.0
				g.dx["cd"].clear()
				g.dx_spy_do("spy_destab", target)
		"leave_nato":
			g.rl_do("leave_nato")
		"auth":
			g.fa_notify("authoritarian", "", 1.0)
		"war":
			g.game_opts["milev"] = 1
			g.capital = 100.0
			g.mil_declare(target, true)
	var line := ""
	for m in 25:
		if m in [1, 6, 12, 24]:
			var st := rel_stats(g, target)
			var ret: int = int(g.ex["p"].get(target, {}).get("ret", 0)) if g.ex.has("p") else 0
			var sanc: int = 0
			if not g.mil.is_empty() and not (g.mil.get("war", {}) as Dictionary).is_empty():
				sanc = (g.mil["war"].get("intl", {}).get("sanc", []) as Array).size()
			var fs: int = (g.fa["sanc"] as Dictionary).size() if not g.fa.is_empty() else 0
			print("FPA|%s|%d|%.1f|%.1f|%.1f|ret=%d sanc=%d fa_sanc=%d eu_sanc=%s" % [sc, m, st[0], st[1], st[2], ret, sanc, fs, str(g.fa.get("eu_sanc", false))])
		if g.election_open: g.election_continue()
		var n := 0
		while not g.current_event.is_empty() and n < 8:
			g.choose(0)
			n += 1
		g.next_turn()
	root.remove_child(g)
	g.free()

func _init():
	var target := "FR"
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("target="): target = String(a).substr(7)
	var only := ""
	for a2 in OS.get_cmdline_user_args():
		if String(a2).begins_with("only="): only = String(a2).substr(5)
	for sc in ["control", "insult", "tariff", "aid", "deal", "spy", "leave_nato", "auth", "war"]:
		if only != "" and not (sc in only.split(",")): continue
		await run(sc, target if sc != "war" else "CZ")
	quit()
