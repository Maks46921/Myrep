extends SceneTree
# Внешнеполитический ИИ стран (v47_1): память, характер, солидарность, санкции, инициативы, пояснения.
var bad := 0

func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)

func mk(o: Dictionary) -> Node:
	var m = load("res://main.gd").new()
	m.game_opts.merge({"agents": false, "seed": 11, "ev": 0.0, "news": 0.0, "milev": 0, "revev": 1, "rlev": 1, "exev": 1, "ongoing": false}, true)
	m.game_opts.merge(o, true)
	root.add_child(m)
	return m

func months(g, n: int) -> void:
	for i in n:
		if g.game_over: return
		if g.election_open: g.election_continue()
		var k := 0
		while not g.current_event.is_empty() and k < 8:
			g.choose(0)
			k += 1
		g.next_turn()

func drop(g) -> void:
	root.remove_child(g)
	g.free()

func _init():
	var g = mk({})
	for i in 4: await process_frame
	var cc: String = g.ccode
	check(g.fa_on(), "модуль ИИ стран не включён")
	var nb: Array = g.tech_nb()
	var t: String = String(nb[0])
	var eu_other := ""
	for c in g.fa_bots():
		if c != t and g.fa_is_eu(c) and g.fa_pers(c)["eu"] >= 0.7:
			eu_other = c
			break
	# --- помощь и соглашение помнят долго ---
	g.capital = 100.0
	check(g.ex_aid_give(t), "помощь не оказана")
	var m0: float = float(g.fa["mem"].get(t, 0.0))
	check(m0 > 3.0, "помощь должна запомниться: %.1f" % m0)
	months(g, 24)
	# v50: распад памяти за 24 мес. — 0,985^24 ≈ 0,70; если партия игрока ушла в оппозицию, решения нового правительства могут
	# немного остудить отношения, поэтому порог 0,5 (короткая память дала бы много меньше)
	check(float(g.fa["mem"].get(t, 0.0)) > m0 * 0.5, "память о помощи слишком короткая: %.1f из %.1f" % [float(g.fa["mem"].get(t, 0.0)), m0])
	# --- шпионаж: санкции и солидарность ---
	for k in 4:
		g.capital = 100.0
		g.dx["cd"].clear()
		g.fa_notify("spy", t, 1.0)
	months(g, 2)
	check(g.fa_sanctioning(t), "после серии раскрытых операций «%s» должна ввести санкции" % t)
	if eu_other != "" and g.fa_is_eu(t):
		check(float(g.fa["mem"].get(eu_other, 0.0)) < 0.0, "союзники по ЕС должны осудить шпионаж")
	check(g.fa_explain(t).find("Помнят") >= 0, "пояснение должно перечислять причины")
	var rl_before: float = float(g.rl.get("g", 0.0))
	drop(g)
	# --- выход из НАТО, отказ от демократии ---
	var g2 = mk({})
	for i in 4: await process_frame
	var nato_c := ""
	var neutral_c := ""
	for c2 in g2.fa_bots():
		if g2.mil_is_nato(c2) and nato_c == "": nato_c = c2
		if g2.fa_pers(c2)["neutral"] and neutral_c == "": neutral_c = c2
	if g2.mil_is_nato(cc):
		g2.capital = 100.0
		check(g2.rl_do("leave_nato"), "выход из НАТО")
		check(float(g2.fa["mem"].get(nato_c, 0.0)) < -4.0, "члены НАТО должны отреагировать на выход")
		if neutral_c != "":
			check(float(g2.fa["mem"].get(neutral_c, 0.0)) > 0.0, "нейтральные страны одобряют нейтралитет")
	var avg0 := 0.0
	for c3 in g2.fa_bots(): avg0 += g2.fed_rel(c3)
	g2.fa_notify("authoritarian", "", 1.0)
	months(g2, 2)
	var avg1 := 0.0
	for c4 in g2.fa_bots(): avg1 += g2.fed_rel(c4)
	check(avg1 < avg0 - 5.0 * float(g2.fa_bots().size()), "отказ от демократии должен ухудшить отношения (%.1f → %.1f)" % [avg0 / g2.fa_bots().size(), avg1 / g2.fa_bots().size()])
	drop(g2)
	# --- война: жертва вводит санкции, ЕС охладевает ---
	var g3 = mk({"milev": 1})
	for i in 4: await process_frame
	var vic: String = String(g3.tech_nb()[0])
	var eu_avg0 := 0.0
	var n_eu := 0
	for c5 in g3.fa_bots():
		if g3.fa_is_eu(c5) and c5 != vic:
			eu_avg0 += g3.fed_rel(c5)
			n_eu += 1
	g3.capital = 100.0
	var res: Dictionary = g3.mil_declare(vic, true)
	check(bool(res.get("done", false)), "объявление войны")
	months(g3, 2)
	var eu_avg1 := 0.0
	for c6 in g3.fa_bots():
		if g3.fa_is_eu(c6) and c6 != vic:
			eu_avg1 += g3.fed_rel(c6)
	if n_eu > 0:
		check(eu_avg1 / n_eu < eu_avg0 / n_eu - 8.0, "страны ЕС должны осудить войну: %.1f → %.1f" % [eu_avg0 / n_eu, eu_avg1 / n_eu])
	check(g3.fa_sanctioning(vic) or not g3.mil_at_war(), "жертва нападения должна ввести санкции")
	drop(g3)
	# --- инициативы: помощь в кризисе ---
	var g4 = mk({})
	for i in 4: await process_frame
	g4.debt = g4.gdp * 1.25
	for c7 in g4.fa_bots():
		g4.fa_hit(c7, 30.0, "тест")
	var seen := {}
	for m in 60:
		if g4.game_over: break
		g4.debt = clampf(g4.debt, g4.gdp * 1.2, g4.gdp * 1.35)     # кризис, но без дефолта (у России высокая ставка по долгу)
		if g4.election_open: g4.election_continue()
		var kk := 0
		while not g4.current_event.is_empty() and kk < 8:
			var rk: String = String(g4.current_event.get("rlk", ""))
			if rk.begins_with("fa_"): seen[rk] = true
			g4.choose(0)
			kk += 1
		g4.next_turn()
	# в режиме оппозиции решение принимает государство автоматически — тогда инициативу видно по перезарядке
	var cdk: Array = (g4.fa["cd"] as Dictionary).keys().filter(func(k): return String(k).begins_with("aid") or String(k).begins_with("coop"))
	# v50: у России под санкциями друзей с тёплыми отношениями и торговым/европейским характером может не быть вовсе
	var can_help := 0
	for c8 in g4.fa_bots():
		var p8: Dictionary = g4.fa_pers(c8)
		if g4.fed_rel(c8) >= 55.0 and (float(p8["trade"]) >= 0.6 or float(p8["eu"]) >= 0.6):
			can_help += 1
	if can_help > 0:
		check(seen.has("fa_aid") or seen.has("fa_coop") or cdk.size() > 0 or int(g4.fa.get("last_ini", 0)) > 0, "за 5 лет друзья должны предложить помощь или сотрудничество: %s" % str(seen.keys()))
	for act in ["fa_aid_yes", "fa_aid_no", "fa_press_arm", "fa_press_give", "fa_press_allies", "fa_coop_yes", "fa_coop_no", "fa_reset_yes", "fa_reset_no"]:
		g4.fpai_resolve({"act": act, "arg": String(g4.fa_bots()[0])})
	check(not is_nan(g4.gdp) and not is_nan(g4.debt), "NaN")
	drop(g4)
	# --- выключено ---
	var g5 = mk({"rlev": 0})
	for i in 4: await process_frame
	check(g5.fa_rel_term(String(g5.fa_bots()[0])) == 0.0, "при rlev=0 ИИ стран не влияет на отношения")
	print("fpai ", cc, " проблем ", bad)
	quit(1 if bad > 0 else 0)
