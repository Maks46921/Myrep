extends SceneTree
# Анализ баланса событий: оценка вариантов, доминирование, разброс. Печатает строки EVB|… для разбора.
func vec(g, fx: Dictionary) -> Array:
	# многомерный вектор последствий для проверки доминирования (больше — лучше)
	var supv: Array = []
	for gname in g.GROUPS:
		supv.append(float(fx.get("support", {}).get(gname, 0.0)) + float(fx.get("all", 0.0)))
	var stt := 0.0
	for k2 in fx.get("state", {}): stt += (-1.0 if k2 == "corruption" else 1.0) * float(fx["state"][k2])
	var reg := 0.0
	for d in [fx.get("reg", {}), fx.get("regall", {})]:
		for rk in d: reg += float(d[rk]) * (-1.0 if rk == "unrest" else 1.0)
	var sl := 0.0
	for k3 in fx.get("slider", {}): sl += float(fx["slider"][k3])
	return [-float(fx.get("debt", 0.0)) - sl * 2.0 - float(fx.get("reg_transfer", 0.0)), float(fx.get("shock", 0.0)), -float(fx.get("unemp", 0.0)), -float(fx.get("infl", 0.0)), stt, reg, float(fx.get("capital", 0.0)), float(fx.get("dip_all", 0.0)), float(fx.get("coal_sat", 0.0)), float(fx.get("other_rev", 0.0))] + supv

func dominates(a: Array, b: Array) -> bool:
	var strict := false
	for i in a.size():
		if float(a[i]) < float(b[i]) - 1e-6: return false
		if float(a[i]) > float(b[i]) + 1e-6: strict = true
	return strict

func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 4: await process_frame
	var sets := {"EVENTS": g.EVENTS, "X": g.EVENTS_X, "ECON": g.ECON_EVENTS, "C": g.EVENTS_C}
	var n_dom := 0
	var n_spread := 0
	for sk in sets:
		for e in sets[sk]:
			var opts: Array = e["o"]
			var sc: Array = []
			var vs: Array = []
			for o in opts:
				sc.append(g.ev_opt_score(o))
				var fx: Dictionary = (o["fx"] as Dictionary).duplicate(true)
				vs.append(vec(g, fx))
			var mx: float = sc.max()
			var mn: float = sc.min()
			var dom := []
			for i in opts.size():
				for j in opts.size():
					if i != j and dominates(vs[i], vs[j]) and float(sc[i]) - float(sc[j]) > 2.0 and not opts[j].has("risk") and not opts[i].has("risk") and not opts[j].has("later") and not opts[i].has("later") and not opts[j].has("next"):
						dom.append("%d>%d" % [i + 1, j + 1])
			if dom.size() > 0: n_dom += 1
			if mx - mn > 22.0: n_spread += 1
			var t: String = String(e.get("id", String(e["t"]).substr(0, 50)))
			print("EVB|%s|%s|%s|%.1f|%s" % [sk, t, ",".join(sc.map(func(x): return "%.1f" % x)), mx - mn, ";".join(dom)])
	print("EVB_SUM dominated=%d spread=%d" % [n_dom, n_spread])
	quit()
