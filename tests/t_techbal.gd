extends SceneTree
# Баланс технологий: допуски по вариантам «или», ветвям, скорости исследований и итогам 50 лет (быстрый симулятор без полной экономики).
var bad := 0

func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)

func _init():
	var g = load("res://main.gd").new()
	g.game_opts.merge({"agents": false, "seed": 3}, true)
	root.add_child(g)
	for i in 4: await process_frame
	# --- варианты «или»: у каждого варианта есть ситуации, где он лучший, и нет варианта-«убийцы» ---
	var profiles := []
	for pr in g.tech_audit_profiles():
		profiles.append(pr[1])
	var groups := 0
	for b in g.TECH_NB:
		for t in (g.tech["grp"][b] as Dictionary):
			var grp: Array = g.tech["grp"][b][t]
			if grp.size() < 2:
				continue
			groups += 1
			var wins := {}
			var sums := {}
			for id in grp:
				wins[id] = 0
				sums[id] = 0.0
			for p in profiles:
				var best := ""
				var bs := -1e18
				for id in grp:
					var s: float = g.tech_score(String(id), p)
					sums[id] = float(sums[id]) + s
					if s > bs:
						bs = s
						best = String(id)
				wins[best] = int(wins[best]) + 1
			var mn := 1e18
			var mx := -1e18
			for id in grp:
				var share: float = float(wins[id]) / float(profiles.size())
				check(share >= 0.04 and share <= 0.88, "группа %s: вариант %s побеждает в %.0f%% ситуаций" % [str(grp), id, share * 100.0])
				mn = minf(mn, float(sums[id]))
				mx = maxf(mx, float(sums[id]))
			check(mx <= mn * 1.25 + 0.2, "группа %s: средние оценки вариантов расходятся (%.2f … %.2f)" % [str(grp), mn / profiles.size(), mx / profiles.size()])
	check(groups == 30, "групп «или»: %d" % groups)
	# --- ветви сопоставимы по суммарной ценности ---
	var br := []
	for b2 in g.TECH_NB:
		var tot := 0.0
		for t2 in (g.tech["grp"][b2] as Dictionary):
			var gl: Array = g.tech["grp"][b2][t2]
			var m := 0.0
			for p2 in profiles:
				var mm := 0.0
				for id2 in gl:
					mm += g.tech_score(String(id2), p2)
				m += mm / float(gl.size())
			tot += m / float(profiles.size())
		br.append(tot)
	var bmean := 0.0
	for v in br: bmean += float(v) / br.size()
	for b3 in br.size():
		check(float(br[b3]) >= bmean * (0.78 if b3 == 4 else 0.88) and float(br[b3]) <= bmean * 1.12, "ветка %d: ценность %.1f при среднем %.1f" % [b3, br[b3], bmean])
	# --- быстрая симуляция 50 лет: «обычная» и «усиленная» стратегии ---
	var edu0: float = g.pol["edu"]
	var gdp0: float = g.gdp
	var turn0: int = g.turn
	var res := {}
	for st in [["обычная", 1.0, 0], ["усиленная", 1.5, 1], ["скупая", 0.5, 0]]:
		g.tech_init()
		g.turn = turn0
		g.gdp = gdp0
		g.tech["auto"] = true
		g.tech["ai_all"] = true
		g.pol["edu"] = edu0 * float(st[1])
		var cap_prev := 0.0
		for m in 600:
			g.turn += 1
			g.mods = g.BASE_MODS.duplicate()
			g.tech_apply_mods()
			g.gdp *= 1.0 + (0.014 + float(g.mods["growth_bonus"]) / 100.0) / 12.0
			var r: float = float(st[1])
			g.lvl["edu_lvl"] = 100.0 * r / (r + 1.0)
			if int(st[2]) > 0 and g.turn % 6 == 0:
				for id in ["rc", "campus"]:
					g.tech_build(id)
			g.tech_month()
			if m % 60 == 59:
				check(float(g.tech["cap"]) >= cap_prev * 0.97, "потолок скорости не должен падать (%.1f → %.1f)" % [cap_prev, g.tech["cap"]])
				cap_prev = g.tech["cap"]
			check(float(g.tech["speed"]) <= 1.6 * float(g.tech["cap"]) + 1e-6, "скорость выше 1,6 потолка")
		g.mods = g.BASE_MODS.duplicate()
		g.tech_apply_mods()
		res[st[0]] = [g.tech_count(), float(g.mods["growth_bonus"]), float(g.tech["speed"])]
	var d50: int = res["обычная"][0]
	check(d50 >= 20 and d50 <= 45, "к 50-му году при обычных расходах изучено %d из 70 (ожидали 20–45)" % d50)
	check(int(res["усиленная"][0]) >= d50 + 4, "вложения в науку должны давать выигрыш: %d против %d" % [res["усиленная"][0], d50])
	check(int(res["скупая"][0]) <= d50 - 2, "экономия на образовании должна замедлять: %d против %d" % [res["скупая"][0], d50])
	check(float(res["усиленная"][1]) < 1.6 and float(res["обычная"][1]) < 1.0, "слишком большая прибавка роста: %.2f / %.2f" % [res["усиленная"][1], res["обычная"][1]])
	print("[%s] 50 лет: обычная %d (рост+ %.2f), усиленная %d (рост+ %.2f), скупая %d; групп «или» %d" % [g.ccode, d50, res["обычная"][1], res["усиленная"][0], res["усиленная"][1], res["скупая"][0], groups])
	print("проблем %d" % bad)
	quit()
