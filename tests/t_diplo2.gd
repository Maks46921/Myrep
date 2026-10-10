extends SceneTree
# Договоры, разведка, вмешательство и миротворцы, признание, армия, наука, мирные пути (v44_1).
var bad := 0

func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)

func mk(o: Dictionary) -> Node:
	var m = load("res://main.gd").new()
	m.game_opts.merge({"agents": true, "k": 0, "seed": 4, "ev": 1.0, "news": 1.0, "econ": 1, "volat": 1.0, "cap": 1.0, "detail": false, "fedev": 0, "socev": 0, "exev": 0, "milev": 0, "revev": 1, "rlev": 1}, true)
	m.game_opts.merge(o, true)
	root.add_child(m)
	return m

func settle(g) -> void:
	var n := 0
	while not g.current_event.is_empty() and n < 8:
		g.choose(0)
		n += 1
	if g.election_open: g.election_continue()

func months(g, n: int) -> void:
	for i in n:
		if g.game_over: return
		settle(g)
		g.next_turn()

func region_noncap(g) -> int:
	for i in g.regions.size():
		if not g.rv_is_capital(i):
			return i
	return 0

func _init():
	var g = mk({})
	for i in 5: await process_frame
	var cc: String = g.ccode
	check(g.dx_on(), "состояние dx не создано")
	var nbs: Array = g.dx_countries()
	check(nbs.size() >= 20, "мало стран для дипломатии: %d" % nbs.size())
	var c1: String = String(g.tech_nb()[0])
	# --- договоры ---
	g.capital = 90.0
	for d in g.dip: g.dip[d]["rel"] = 80.0
	g.fst["rel_x"][c1] = 30.0
	check(g.dx_treaty_acts(c1).size() >= 6, "список договоров")
	check(g.dx_treaty_do("tr_tech", c1) and g.dx_has_treaty(c1, "tech"), "научный обмен")
	check(g.dx_treaty_do("tr_energy", c1) and g.dx_has_treaty(c1, "energy"), "энергетическое партнёрство")
	check(g.dx_treaty_do("tr_defense", c1), "оборонный союз")
	check(g.dx_treaty_do("proj", c1) and g.dx["proj"].size() == 1, "совместный проект")
	check(g.dx_treaty_do("summit", c1), "саммит")
	months(g, 3)
	check(g.tech_adj > 1.0, "скорость науки должна вырасти от обмена и проекта: %.3f" % g.tech_adj)
	check(g.tech_pas_mult > 1.0, "пассивное изучение должно ускориться")
	settle(g)
	g.capital = 90.0
	check(g.dx_treaty_do("tr_tech", c1) and not g.dx_has_treaty(c1, "tech"), "расторжение договора")
	# --- разведка ---
	g.capital = 90.0
	var nm: String = String(nbs[0])
	check(g.dx_spy_do("spy_steal", nm), "кража технологий")
	check(not g.dx_spy_do("spy_steal", nm), "перерыв разведки")
	check(g.dx_spy_do("spy_cyber", nm), "кибератака")
	check(g.dx_spy_do("spy_destab", nm), "поддержка оппозиции")
	check(g.dx_spy_do("ci_up", "") and int(g.dx["ci"]) == 1, "контрразведка")
	months(g, 6)
	# --- этика ---
	settle(g)
	g.capital = 90.0
	var ta: float = g.tech_adj
	check(g.dx_eth_do("eth_up") and int(g.dx["eth"]) == 1, "этика технологий")
	months(g, 2)
	check(g.tech_adj < ta, "этика должна замедлять науку")
	# --- армия ---
	settle(g)
	g.capital = 90.0
	for k in ["army_civil", "army_loyal", "army_bonus"]:
		check(g.dx_army_do(k), "армия: " + k)
	for k in ["dx_gen_pay", "dx_gen_civil", "dx_gen_seat", "dx_brain_pay", "dx_brain_ret", "dx_brain_none", "dx_disc_open", "dx_disc_biz", "dx_disc_mil", "dx_pk_no"]:
		g.realism_resolve({"act": k})
	# --- конфликт, миротворцы, конференция ---
	settle(g)
	g.rv["conf"].clear()
	var j: int = region_noncap(g)
	g.rv_conf_start("secession", j, 40.0, "тест")
	check(g.rv["conf"].size() == 1, "конфликт не начался")
	g.capital = 90.0
	check(g.dx_conf_acts(0).size() == 2, "действия конфликта")
	check(g.dx_conf_do("conf_pk", 0) and bool(g.rv["conf"][0]["fi"]["pk"]) and int(g.rv["conf"][0]["truce"]) > 0, "миротворцы")
	months(g, 2)
	var cid: int = int(g.rv["conf"][0]["id"])
	g.realism_resolve({"act": "dx_pk_yes", "arg": str(cid)})
	var got := false
	for t in 12:
		settle(g)
		g.capital = 90.0
		if g.rv["conf"].size() == 0:
			got = true
			break
		g.dx["cd"].clear()
		g.dx_conf_do("conf_peace", 0)
		if g.rv["conf"].size() == 0:
			got = true
			break
	check(got, "мирная конференция должна рано или поздно завершить конфликт")
	# --- признание нового государства ---
	settle(g)
	g.rv["conf"].clear()
	var j2: int = region_noncap(g)
	g.regions[j2]["unrest"] = 90.0
	var n0: int = g.rv["states"].size()
	g.rv_secede(j2, "peace")
	check(g.rv["states"].size() == n0 + 1, "новое государство не создано")
	months(g, 36)
	var code: String = String(g.rv["states"][g.rv["states"].size() - 1]["code"])
	check(g.dx["rec"].has(code) and g.dx["rec"][code]["by"].size() > 0, "признание не идёт")
	settle(g)
	g.capital = 90.0
	check(g.dx_rec_acts().size() >= 2, "действия по признанию")
	check(g.dx_rec_do("rec_lobby", code) and g.dx_rec_do("rec_us", code), "признание: действия")
	check(g.dx_rec_text().length() > 10, "текст признания")
	# --- мирные пути ---
	if not g.game_over and g.regions.size() >= 3:
		settle(g)
		var j3: int = region_noncap(g)
		g.capital = 99.0
		var rg: Dictionary = g.rv_reg(j3)
		rg["sep"] = 60.0
		rg["hate"] = 40.0
		rg["stage"] = 1
		for k in ["fiscal", "lang", "commission"]:
			g.capital = 99.0
			rg["cd"].clear()
			check(g.rv_region_act(k, j3), "мирное действие: " + k)
		check(float(rg["sep"]) < 60.0, "сепаратизм должен снизиться")
		months(g, 6)
		check(float(g.rv_reg(j3)["sep"]) < 52.0, "комиссия должна снижать сепаратизм")
		g.capital = 99.0
		rg["cd"].clear()
		rg["refcd"] = 0
		var n1: int = g.regions.size()
		check(g.rv_reg_act_check("agreed_ref", j3) == "", "согласованный референдум доступен: " + g.rv_reg_act_check("agreed_ref", j3))
		rg["sep"] = 5.0
		rg["hate"] = 0.0
		g.rv_region_act("agreed_ref", j3)
		check(g.regions.size() == n1, "при низком сепаратизме референдум не даёт отделения")
	check(not is_nan(g.gdp) and not is_nan(g.debt), "NaN")
	months(g, 24)
	# --- выключено ---
	var g2 = mk({"rlev": 0})
	for i in 3: await process_frame
	months(g2, 6)
	check(not g2.dx_on() or g2.dx_treaty_acts(c1).is_empty(), "при rlev=0 модуль молчит")
	print("diplo2 ", cc, " проблем ", bad)
	quit(1 if bad > 0 else 0)
