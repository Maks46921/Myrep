extends SceneTree
# Балансный стенд: policy=idle|open|closed|secular|trade_war|deals|aid|mix ; months=N. Печатает строку BAL {json}
func arg(k: String, d: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(k + "="):
			return a.substr(k.length() + 1)
	return d

func act(g, pol: String, m: int) -> void:
	g.capital = maxf(g.capital, 60.0)
	g.game_over = false
	match pol:
		"open":
			g.soc["cd"].clear(); g.soc_set_mig(1); g.soc_set_prog(1)
		"closed":
			g.soc["cd"].clear(); g.soc_set_mig(-1)
		"secular":
			g.soc["cd"].clear(); g.soc_set_sec(1)
		"trade_war":
			for c in g.ex_partners():
				g.ex["p"][c]["cd"].clear(); g.ex_tariff_set(c, 1)
		"deals":
			for c in g.ex_partners():
				g.ex["p"][c]["cd"].clear(); g.ex_deal_set(c, 1)
		"aid":
			for c in g.ex_partners():
				g.ex["p"][c]["cd"].clear(); g.ex_aid_give(c); g.ex_dbuy_set(c, 1)
		"mix":
			if m % 12 == 0:
				g.soc["cd"].clear(); g.soc_set_mig(1)
				for c in g.ex_partners():
					g.ex["p"][c]["cd"].clear(); g.ex_deal_set(c, 1)

func _init():
	var pol := arg("policy", "idle")
	var months := int(arg("months", "120"))
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	var g0: float = g.gdp
	var d0: float = g.debt
	var u0: float = g.unemployment
	var p0: float = g.total_pop()
	var nat0: Array = g.soc_national()
	var gmin := 99.0
	var tmax := 0.0
	var umax := 0.0
	var imax := 0.0
	var m := 0
	while m < months and not g.game_over:
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty(): g.choose(0)
		act(g, pol, m)
		g.next_turn()
		if g.election_open: g.election_continue()
		gmin = minf(gmin, g.growth)
		tmax = maxf(tmax, float(g.soc["tension"]))
		umax = maxf(umax, g.unemployment)
		imax = maxf(imax, g.inflation)
		m += 1
	var nat: Array = g.soc_national()
	var d := {"cc": g.ccode, "pol": pol, "m": m, "over": g.game_over, "gdp": snappedf(g.gdp / g0, 0.001), "debt": snappedf(g.debt / maxf(1.0, g.gdp) * 100.0, 0.1), "debt0": snappedf(d0 / g0 * 100.0, 0.1),
		"u": snappedf(g.unemployment, 0.1), "u0": snappedf(u0, 0.1), "umax": snappedf(umax, 0.1), "infl": snappedf(g.inflation, 0.1), "imax": snappedf(imax, 0.1), "appr": snappedf(g.approval(), 0.1),
		"pop": snappedf(g.total_pop() / p0, 0.001), "tens": snappedf(float(g.soc["tension"]), 0.1), "tmax": snappedf(tmax, 0.1), "integ": snappedf(float(g.soc["integ"]), 0.1),
		"musl": snappedf((float(nat[3]) - float(nat0[3])) * 100.0, 0.1), "nonrel": snappedf((float(nat[6]) - float(nat0[6])) * 100.0, 0.1), "gmin": snappedf(gmin, 0.1), "cap": snappedf(g.capital, 0.1)}
	print("BAL ", JSON.stringify(d))
	quit()
