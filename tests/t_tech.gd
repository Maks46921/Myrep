extends SceneTree
# Технологии (v39_1): данные, скорость и потолок, сооружения, эффекты, расходы на образование, окно.
var bad := 0

func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)

func run_months(g, n: int) -> void:
	for i in n:
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty(): g.choose(0)
		g.next_turn()

func mk(o: Dictionary) -> Node:
	var m = load("res://main.gd").new()
	m.game_opts.merge({"agents": true, "k": 0, "seed": 0, "ev": 1.0, "news": 1.0, "econ": 1, "volat": 1.0, "cap": 1.0, "detail": false, "fedev": 0, "socev": 0, "exev": 0}, true)
	m.game_opts.merge(o, true)
	root.add_child(m)
	return m

func drop(g) -> void:
	root.remove_child(g)
	g.free()
	await process_frame

func _init():
	var g = mk({})
	for i in 5: await process_frame
	var cc: String = g.ccode
	# --- данные ---
	var ids := {}
	for d in g.TECHS:
		check(not ids.has(d["id"]), "повтор id технологии %s" % d["id"])
		ids[d["id"]] = d
	var per := [0, 0, 0]
	for d in g.TECHS:
		per[int(d["b"])] += 1
		for r in d.get("req", []):
			check(ids.has(r), "%s: нет требуемой технологии %s" % [d["id"], r])
			if ids.has(r):
				check(int(ids[r]["yr"]) <= int(d["yr"]), "%s раньше своей зависимости %s" % [d["id"], r])
		for k in d["fx"]:
			check(g.BASE_MODS.has(k) and g.MOD_INFO.has(k), "%s: неизвестный модификатор %s" % [d["id"], k])
	check(per == [19, 19, 19], "в каждой ветке по 19 технологий: %s" % str(per))
	check(g.tech_total() == 36, "36 уровней: %d" % g.tech_total())
	# выбор: на уровнях с вариантами они взаимоисключающие
	var nch := 0
	for d in g.TECHS:
		var al: Array = g.tech_alts(String(d["id"]))
		if al.size() > 0:
			nch += 1
			for a in al:
				check(g.tech_alts(String(a)).has(d["id"]), "несимметричный выбор %s/%s" % [d["id"], a])
				check(int(ids[a]["yr"]) == int(d["yr"]), "варианты одного уровня открываются одновременно")
	check(nch == 36, "вариантов на выбор: %d" % nch)
	for b in g.TECH_BUILDINGS:
		check(String(b["need"]) == "" or ids.has(b["need"]), "сооружение %s: нет технологии %s" % [b["id"], b["need"]])
	# --- старт ---
	check(not g.tech.is_empty(), "состояние технологий не создано")
	var raw0: float = g.tech["raw"]
	var cap0: float = g.tech["cap"]
	check(raw0 > 0.0 and cap0 > raw0 * 0.9, "на старте скорость %.1f должна быть около потолка %.1f или ниже" % [raw0, cap0])
	var m0: Dictionary = g.mods.duplicate()
	check(absf(float(g.tech_edu_upkeep())) < 1e-9, "на старте нет расходов сооружений")
	# --- потолок: время, ВВП, свобода слова ---
	var c1: float = g.tech_cap()
	g.turn += 120
	var c2: float = g.tech_cap()
	g.turn -= 120
	check(c2 > c1 * 1.1, "потолок должен расти со временем (%.2f → %.2f)" % [c1, c2])
	var gd: float = g.gdp
	g.gdp = gd * 2.0
	check(g.tech_cap() > c1 * 1.2, "потолок должен расти с ВВП")
	g.gdp = gd
	var law0 = g.law_state.get("media_law", 0)
	g.law_state["media_law"] = 1
	var cf: float = g.tech_cap()
	g.law_state["media_law"] = 2
	var cs: float = g.tech_cap()
	g.law_state["media_law"] = law0
	check(cf > cs * 1.1, "свобода слова должна поднимать потолок (%.2f vs %.2f)" % [cf, cs])
	# --- расходы на образование и убывающая отдача ---
	var edu0: float = g.pol["edu"]
	var sp_prev := -1.0
	var gain_prev := 1e9
	var raw_prev := 0.0
	for k in [0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 6.0]:
		g.pol["edu"] = edu0 * k
		g.tech_refresh_rates()
		var sp: float = g.tech["speed"]
		check(sp > sp_prev, "скорость должна расти с расходами на образование (×%.1f)" % k)
		check(sp <= 1.6 * g.tech["cap"] + 1e-6, "скорость не выше 1,6 потолка")
		if k > 1.0 and raw_prev > g.tech["cap"]:
			var gain: float = (sp - sp_prev) / maxf(1e-9, float(g.tech["raw"]) - raw_prev)
			check(gain < 1.0, "выше потолка отдача должна убывать")
		sp_prev = sp
		raw_prev = g.tech["raw"]
	g.pol["edu"] = edu0
	g.pol["edu"] = 0.0
	g.tech_refresh_rates()
	check(float(g.tech["speed"]) < raw0 * 0.3, "без расходов на образование исследования почти стоят")
	g.pol["edu"] = edu0
	# --- сооружения ---
	var up0: float = g.tech_edu_upkeep()
	var ed_before: float = float(g.compute_budget()["exp"]["Образование"])
	var debt0: float = g.debt
	check(g.tech_build("rc"), "исследовательский центр не заложен")
	check(g.debt > debt0, "стройка должна идти в долг")
	check(g.tech_build_missing("qlab") != "", "прорывная лаборатория закрыта до технологии")
	run_months(g, 9)
	check(int(g.tech["bld"]["rc"]) == 1, "центр не построен за срок (%s)" % str(g.tech["bld"]))
	check(g.tech_edu_upkeep() > up0, "содержание сооружений не выросло")
	var ed_after: float = float(g.compute_budget()["exp"]["Образование"])
	check(ed_after > ed_before * 0.97 and ed_after - float(g.gdp) * g.pol["edu"] / 100.0 > 0.0, "расходы на образование должны включать содержание")
	g.tech_refresh_rates()
	check(float(g.tech["raw"]) / g.tech_edu_term() > g.TECH_R0 * 1.04, "центр должен ускорять исследования")
	for i in 5:
		g.tech["bld"]["rc"] = int(g.tech["bld"]["rc"])
	g.tech["q"].clear()
	for i in 10:
		g.tech_build("rc")
	check(int(g.tech["bld"]["rc"]) + g.tech["q"].size() <= int(g.tech_bdef("rc")["max"]), "число сооружений ограничено")
	# --- технологии изучаются, эффекты применяются ---
	g.capital = 100.0
	run_months(g, 90)
	var n1: int = g.tech_count()
	check(n1 >= 4, "за 8 лет должно быть изучено хотя бы 4 технологии, а %d" % n1)
	g.recompute_mods()
	var any_fx := false
	for k in ["growth_bonus", "corr_shift", "health_eff", "edu_eff"]:
		if absf(float(g.mods[k]) - float(m0[k])) > 1e-6:
			any_fx = true
	check(any_fx, "изученные технологии должны менять модификаторы")
	for id in g.tech["done"]:
		check(g.tech_missing(String(id)) == "уже изучена", "изученная %s" % id)
		var dd: Dictionary = g.tech_def(String(id))
		check(int(dd["t"]) == 0 or g.tech_tier_done(int(dd["b"]), int(dd["t"]) - 1) != "", "%s изучена без предыдущего уровня" % id)
		for a in g.tech_alts(String(id)):
			check(not g.tech_done(String(a)), "изучены обе взаимоисключающие %s и %s" % [id, a])
		check(int(g.tech_def(String(id))["yr"]) <= g.tech["done"][id] / 12 + 1, "%s изучена раньше срока" % id)
	check(not is_nan(g.gdp) and not is_nan(g.debt), "NaN в экономике")
	# --- ручной выбор ---
	g.tech["auto"] = false
	for b in 3:
		g.tech["cur"][b] = ""
	var pick := ""
	for d in g.TECHS:
		if int(d["b"]) == 0 and g.tech_avail(String(d["id"])):
			pick = String(d["id"])
			break
	if pick != "":
		check(g.tech_select(0, pick), "ручной выбор")
		check(not g.tech_select(1, pick), "нельзя выбрать технологию чужой ветки")
		run_months(g, 3)
		check(g.tech_progress(pick) > 0.0 or g.tech_done(pick), "выбранная технология не продвигается")
	var hs: Array = g.tech["h"]["s"]
	check(hs.size() > 50, "история скорости")
	# --- окно ---
	g.show_desk(15)
	g.refresh()
	check(g.current_desk == 15, "вкладка технологий не открылась")
	check(g.tw_sum_rt.text.contains("Скорость исследований"), "текст окна пуст")
	g.show_desk(0)
	print("[%s] изучено %d, скорость %.1f/%.1f (потолок), сооружения %s, ВВП %.0f" % [cc, g.tech_count(), g.tech["speed"], g.tech["cap"], str(g.tech["bld"]), g.gdp])
	await drop(g)
	print("проблем %d" % bad)
	quit()
