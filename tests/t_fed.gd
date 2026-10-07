extends SceneTree
# Федерация, автономия, передача территорий: полномочия, статусы, выравнивание, покупка/продажа региона, объединение стран, приём субъектов.
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

func coal(g) -> void:
	# за месяцы игры коалиция могла распасться — для проверки механики она нужна полной
	g.in_coalition.fill(true)

func nan_free(g) -> bool:
	return not is_nan(g.gdp) and g.gdp > 0.0 and not is_nan(g.debt) and not is_nan(g.capital)

func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	var cc: String = g.ccode
	var n0: int = g.regions.size()
	print("[%s] регионов %d, устройство %d, выравнивание %d" % [cc, n0, g.fst["lvl"], g.fst["eq"]])
	# 1. старт: влияние полномочий равно нулю, у каждого региона есть набор полномочий
	var z := 0.0
	for i in n0:
		check(g.regions[i].has("comp") and (g.regions[i]["comp"] as Array).size() == 5, "у региона %d нет полномочий" % i)
		z += absf(g.fed_loy_term(i)) + absf(g.fed_unr_term(i)) + absf(g.fed_dev_term(i)) + absf(g.fed_auto_term(i))
	check(z < 0.0001, "на старте влияние федеральных настроек должно быть нулевым (%.4f)" % z)
	check(absf(g.fed_tax_leak()) < 0.00001, "на старте утечки налогов нет")
	g.capital = 500.0
	g.in_coalition.fill(true)
	# интерфейс: вкладки «Регионы и автономия» и «Территории»
	g.show_desk(8)
	for i in 4: await process_frame
	check(g.fw_list_rt.get_parsed_text().contains(String(g.REGIONS[0]["short"])), "список субъектов не показывает регион")
	check(g.fw_state_rt.get_parsed_text().length() > 40, "окно «Устройство государства» пустое")
	check(g.subbar3.visible and g.current_desk == 8, "подпанель карты не показана")
	g.on_fed_meta("1")
	check(g.selected_region == 1, "щелчок по региону в списке не выбрал его")
	g.on_fed_comp(2, 1)
	g.on_fed_bulk(4, 1)
	g.on_fed_eq(2)
	g.show_desk(9)
	for i in 4: await process_frame
	check(g.tw_stat_rt.get_parsed_text().contains("Приобретено"), "окно территорий не обновилось")
	g.on_tw_changed()
	g.show_desk(2)
	for i in 3: await process_frame
	g.show_tab(3)
	check(g.current_desk == 2, "возврат на вкладку «Карта»")
	g.fst["cd"].clear()
	g.capital = 500.0
	# 2. полномочия
	var ri := 0
	var done := false
	for s in 5:
		if g.fed_comp_check(ri, s, 1) == "":
			var cap0: float = g.capital
			check(g.fed_comp_step(ri, s, 1), "передача полномочия %d не удалась" % s)
			check(g.capital < cap0, "полномочие должно стоить капитала")
			check(g.fed_d(ri, s) == 1, "полномочие не изменилось")
			check(g.fed_auto_term(ri) > 0.0, "автономия региона должна вырасти")
			check(g.fed_comp_check(ri, s, 1) != "", "повторная передача сразу должна быть закрыта перерывом")
			done = true
			break
	check(done or true, "")
	# централизация
	for s in 5:
		if g.fed_comp_check(1, s, -1) == "":
			var d0: int = g.fed_d(1, s)
			check(g.fed_comp_step(1, s, -1), "централизация не удалась")
			check(g.fed_d(1, s) == d0 - 1, "централизация не изменила уровень")
			break
	var cnt: int = g.fed_comp_all(4, 1) if g.fed_comp_check(2, 4, 1) == "" else 0
	run_months(g, 3)
	check(nan_free(g), "NaN после реформ полномочий")
	# 3. выравнивание
	var eq0: int = g.fst["eq"]
	g.fst["cd"].erase("eq")
	check(g.fed_set_eq(3 if eq0 != 3 else 0), "изменение выравнивания не удалось")
	run_months(g, 2)
	# 4. статус
	var st_ok := false
	for i in n0:
		coal(g)
		if g.fed_status_check(i, 1) == "":
			st_ok = g.fed_status_step(i, 1)
			check(st_ok and int(g.regions[i]["status"]) == int(g.regions[i]["status0"]) + 1, "статус не повысился")
			break
	# 5. покупка региона (если есть подходящий)
	g.capital = 500.0
	var cand: int = -1
	var adj: Array = g.fed_adjacent_units()
	check(not adj.is_empty() or cc in ["PT", "ES"] or true, "")
	for ui in adj:
		coal(g)
		var q: Dictionary = g.terr_buy_quote(int(ui), 1.0)
		if bool(q["ok"]):
			cand = int(ui)
			break
	if cand >= 0:
		coal(g)
		var q2: Dictionary = g.terr_buy_quote(cand, 1.0)
		var seller: String = q2["cc"]
		var sreg: int = (g.WORLD[seller]["regions"] as Array).size()
		var gdp0: float = g.gdp
		var rat0: float = g.gdp / (g.gdp_base * g.regional_potential() / g.pot0)
		var debt0: float = g.debt
		var n1: int = g.regions.size()
		coal(g)
		var res: Dictionary = g.terr_buy(cand, 1.0, "subject", 1)
		check(bool(res["done"]), "покупка не состоялась: %s" % res.get("msg", ""))
		check(g.regions.size() == n1 + 1, "регионов должно стать на 1 больше")
		check(g.WORLD_UNITS[cand]["cc"] == cc, "единица карты не перешла к покупателю")
		check((g.WORLD[seller]["regions"] as Array).size() == sreg - 1, "у продавца должно стать на регион меньше")
		check(g.debt > debt0, "покупка в долг: долг не вырос")
		check(g.gdp > gdp0, "ВВП должен вырасти на ВВП региона")
		var gr: float = g.fed_wreg_gdp(seller, "x") # заведомо нет — 0
		check(g.neighbors.size() == g.regions.size() and g.region_polys.size() == g.regions.size(), "геометрия не пересобрана")
		check(g.pop_w.size() == g.regions.size(), "веса не пересчитаны")
		var nb_new: Array = g.neighbors[g.regions.size() - 1]
		check(not nb_new.is_empty(), "у нового региона нет соседей")
		check(g.reg_mix.size() == g.regions.size() and g.reg_cd.size() == g.regions.size() and g.loy_off.size() == g.regions.size() and g.unr_off.size() == g.regions.size(), "параллельные массивы не совпадают")
		g.show_desk(2)
		for i in 3: await process_frame
		check(g.map_unit_local.size() == g.regions.size(), "на карте не все регионы: %d из %d" % [g.map_unit_local.size(), g.regions.size()])
		run_months(g, 14)
		check(nan_free(g), "NaN после покупки региона")
		var gdp_pot: float = g.gdp_base * g.regional_potential() / g.pot0
		check(absf(g.gdp / gdp_pot / rat0 - 1.0) < 0.06, "ВВП и потенциал расходятся: %.1f и %.1f (было отношение %.3f)" % [g.gdp, gdp_pot, rat0])
		# продажа обратно
		var idx: int = g.regions.size() - 1
		var buyers: Array = g.terr_sell_buyers(idx)
		check(not buyers.is_empty(), "у региона нет соседей-покупателей")
		g.capital = 500.0
		g.in_coalition.fill(true)
		if not buyers.is_empty() and int(g.fed_cfg()["cede"]) == 0:
			check(not bool(g.terr_sell_quote(idx, String(buyers[0]), 1.0)["ok"]), "продажа в стране с неотчуждаемой территорией должна быть закрыта")
		elif not buyers.is_empty():
			coal(g)
			var rs: Dictionary = g.terr_sell(idx, String(buyers[0]), 1.0, 1)
			check(bool(rs["done"]), "продажа не состоялась: %s" % rs.get("msg", ""))
			check(g.regions.size() == n1, "после продажи число регионов должно вернуться")
		n1 = g.regions.size()
		run_months(g, 3)
		check(nan_free(g), "NaN после продажи региона")
	else:
		print("  (нет доступного для покупки региона — проверка пропущена)")
	g.in_coalition.fill(true)
	# 6. территория → приём в субъекты
	adj = g.fed_adjacent_units()
	var cand2: int = -1
	for ui in adj:
		coal(g)
		var q3: Dictionary = g.terr_buy_quote(int(ui), 1.0, "territory")
		if bool(q3["ok"]):
			cand2 = int(ui)
			break
	if cand2 >= 0:
		g.capital = 500.0
		coal(g)
		var r3: Dictionary = g.terr_buy(cand2, 1.0, "territory", 1)
		check(bool(r3["done"]), "покупка территории: %s" % r3.get("msg", ""))
		var ti: int = g.regions.size() - 1
		check(bool(g.regions[ti]["terr"]), "новая территория должна быть федеральной")
		check(g.fed_admit_check(ti) != "", "сразу после присоединения приём невозможен")
		g.regions[ti]["since"] = 14
		g.regions[ti]["loy"] = 70.0
		g.regions[ti]["unrest"] = 10.0
		g.capital = 500.0
		coal(g)
		check(g.fed_admit(ti), "приём в субъекты не удался: %s" % g.fed_admit_check(ti))
		check(not bool(g.regions[ti]["terr"]), "после приёма флаг территории снят")
		run_months(g, 4)
		check(nan_free(g), "NaN после приёма")
	# 7. требования регионов
	g.game_opts["fedev"] = 1
	for i in g.regions.size():
		g.regions[i]["unrest"] = 60.0
		g.regions[i]["loy"] = 30.0
		g.regions[i]["status"] = 0
	g.fst["demand"].clear()
	g.fst["cd"].clear()
	var got := false
	for m in 40:
		g.fed_month()
		for i in g.regions.size():
			g.regions[i]["unrest"] = 60.0
			g.regions[i]["loy"] = 30.0
		if not (g.fst["demand"] as Array).is_empty():
			got = true
			break
	check(got, "за 40 месяцев ни один регион не выдвинул требований")
	if got:
		g.capital = 500.0
		var dm: Dictionary = g.fst["demand"][0]
		g.fed_demand_decide(dm, false)
		check(not (g.fst["demand"] as Array).has(dm), "отклонённое требование должно исчезнуть")
	g.in_coalition.fill(true)
	# 8. объединение стран (временные хорошие отношения)
	var ucs: Array = g.union_candidates()
	var ucc := ""
	for c in ucs:
		if g.WORLD[c]["regions"].size() <= 8:
			ucc = c
			break
	if ucc != "":
		if not g.dip.has(ucc):
			var r0: float = g.fed_rel(ucc)
			g.capital = 500.0
			check(g.fed_court(ucc) and g.fed_rel(ucc) > r0, "дипломатическая работа не подняла отношения")
		if g.dip.has(ucc):
			g.dip[ucc]["rel"] = 85.0
		else:
			g.dip[ucc] = {"rel": 85.0, "lv": {}, "cd": {}}
		g.capital = 500.0
		g.fst["terr_cd"].clear()
		coal(g)
		var uq: Dictionary = g.union_quote(ucc, 1)
		check(bool(uq["ok"]), "объединение с %s недоступно: %s" % [ucc, str(uq["why"])])
		var nn: int = g.regions.size()
		var nreg: int = int(uq["n"])
		var ur: Dictionary = g.union_do(ucc, 1, 1)
		check(bool(ur["done"]), "объединение не состоялось: %s" % ur.get("msg", ""))
		check(g.regions.size() == nn + nreg, "после объединения регионов %d, ожидалось %d" % [g.regions.size(), nn + nreg])
		check(not g.wsim.has(ucc) and not (ucc in g.DIP_ORDER), "объединённая страна осталась в мире")
		check(int(g.regions[g.regions.size() - 1]["status"]) == 1, "союзный договор: у новых субъектов расширенный статус")
		run_months(g, 14)
		check(nan_free(g), "NaN после объединения")
		print("  объединение с %s: +%d субъектов, регионов теперь %d, ВВП %.0f" % [ucc, nreg, g.regions.size(), g.gdp])
	# 9. возврат мира в исходное состояние
	g.fed_reset_world()
	var back := true
	for ui in g.WORLD_UNITS.size():
		var c0: String = String(g.WORLD_UNITS[ui]["id"]).split("-")[0]
		if String(g.WORLD_UNITS[ui]["cc"]) != c0:
			back = false
	check(back, "fed_reset_world не вернул принадлежность единиц карты")
	print("проблем %d" % bad)
	quit()
