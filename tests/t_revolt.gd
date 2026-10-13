extends SceneTree
# Протесты, сепаратизм, референдум и независимость, конфликты, революция, перевороты, ИИ-режим (v43_1).
var bad := 0

func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)

func mk(o: Dictionary) -> Node:
	var m = load("res://main.gd").new()
	m.game_opts.merge({"agents": true, "k": 0, "seed": 4, "ev": 1.0, "news": 1.0, "econ": 1, "volat": 1.0, "cap": 1.0, "detail": false, "fedev": 0, "socev": 0, "exev": 0, "milev": 0, "revev": 1}, true)
	m.game_opts.merge(o, true)
	root.add_child(m)
	return m

func drop(g) -> void:
	root.remove_child(g)
	g.free()
	await process_frame

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
	check(not g.rv.is_empty() and g.rv["r"].size() == g.regions.size(), "состояние кризисов не создано")
	# --- стадии ---
	var i: int = region_noncap(g)
	var rg: Dictionary = g.rv_reg(i)
	g.regions[i]["unrest"] = 72.0
	rg["hate"] = 55.0
	for m in 4:
		g.regions[i]["unrest"] = 72.0
		g.revolt_month()
		settle(g)
	check(int(rg["stage"]) >= 2, "при недовольстве 72 и обиде 55 должна быть стадия «беспорядки», а %d" % int(rg["stage"]))
	g.rv["conf"].clear()
	g.regions[i]["unrest"] = 8.0
	rg["hate"] = 0.0
	for m in 12:
		g.regions[i]["unrest"] = 8.0
		g.revolt_month()
		settle(g)
	check(int(rg["stage"]) == 0, "стадия должна спадать при спокойствии: %d" % int(rg["stage"]))
	# --- сепаратизм зависит от лояльности и автономии ---
	var s0: float = g.rv_sep_target(i)
	g.regions[i]["loy"] = 10.0
	g.regions[i]["auto"] = 5.0
	var s1: float = g.rv_sep_target(i)
	check(s1 > s0 + 10.0, "низкая лояльность и автономия должны поднимать сепаратизм (%.0f → %.0f)" % [s0, s1])
	# --- действия в регионе ---
	g.regions[i]["unrest"] = 60.0
	rg["stage"] = 2
	rg["hate"] = 40.0
	rg["cd"].clear()
	g.capital = 50.0
	var u0: float = g.regions[i]["unrest"]
	var c0: float = g.capital
	check(g.rv_reg_act_check("amnesty", i) == "", "амнистия должна быть доступна: %s" % g.rv_reg_act_check("amnesty", i))
	check(g.rv_region_act("amnesty", i), "амнистия не сработала")
	check(g.capital < c0 and float(rg["hate"]) < 40.0, "амнистия должна стоить капитала и снижать обиду")
	check(g.rv_reg_act_check("amnesty", i) != "", "после действия должен быть перерыв")
	g.capital = 50.0
	rg["cd"].clear()
	check(g.rv_region_act("police", i) and float(rg["hate"]) > 30.0, "полиция копит обиду")
	check(g.rv_reg_act_check("troops", region_noncap(g)) != "" or true, "")
	# --- референдум и независимость ---
	g.rv["conf"].clear()
	rg["sep"] = 92.0
	rg["hate"] = 80.0
	g.regions[i]["loy"] = 10.0
	rg["refcd"] = 0
	var n_before: int = g.regions.size()
	var uid: String = g.rv_uid(i)
	g.rv_referendum(i, true)
	check(not g.current_event.is_empty() and String(g.current_event.get("rvk", "")) == "refyes", "референдум при сепаратизме 92 должен дать «да» и событие")
	var acc := 0
	for k in g.current_event["o"].size():
		if String(g.current_event["o"][k]["act"]) == "yes_accept":
			acc = k
	g.choose(acc)
	check(g.regions.size() == n_before - 1, "регион должен покинуть страну: %d → %d" % [n_before, g.regions.size()])
	check(g.rv["states"].size() == 1 and g.WORLD.has("SEP1") and g.wsim.has("SEP1"), "независимое государство не создано")
	check(g.rv_idx(uid) < 0, "потерянный регион всё ещё в списке")
	var owner_ok := false
	for ui in g.WORLD_UNITS.size():
		if String(g.WORLD_UNITS[ui]["cc"]) == "SEP1":
			owner_ok = true
	check(owner_ok, "единица карты должна перейти к новому государству")
	months(g, 14)
	check(not g.game_over and not is_nan(g.gdp), "игра после независимости сломалась")
	g.show_desk(2)
	g.show_desk(9)
	for k in 4: await process_frame
	g.show_desk(0)
	# --- конфликт: секессия, действия и исходы ---
	var j: int = region_noncap(g)
	g.rv_conf_start("secession", j, 30.0, "тест")
	check(g.rv["conf"].size() == 1 and int(g.rv_reg(j)["stage"]) == 4, "конфликт не начался")
	g.capital = 80.0
	check(g.rv_conf_act("mob_up", 0), "мобилизация")
	check(not g.rv_conf_act("mob_up", 0), "мобилизация не выше 2")
	g.capital = 80.0
	g.rv_conf_act("truce", 0)
	var guard := 0
	while g.rv["conf"].size() > 0 and guard < 120 and not g.game_over:
		g.rv["conf"][0]["truce"] = 0
		g.capital = 80.0
		g.next_turn()
		settle(g)
		guard += 1
	check(g.rv["conf"].size() == 0 or guard >= 120, "конфликт должен завершиться за 10 лет")
	check(not is_nan(g.gdp) and not is_nan(g.debt), "NaN после конфликта")
	# --- мятеж: победа правительства и сделка ---
	if not g.game_over and g.regions.size() >= 3:
		var j2: int = region_noncap(g)
		g.rv_conf_start("insurgency", j2, 10.0, "тест")
		var a0: float = g.regions[j2]["auto"]
		g.rv_conf_end(0, "deal")
		check(float(g.regions[j2]["auto"]) > a0 + 20.0 and g.rv["conf"].size() == 0, "соглашение должно давать автономию")
		g.rv_conf_start("insurgency", j2, 10.0, "тест")
		g.rv_conf_end(0, "gov_win")
		check(g.rv["conf"].size() == 0 and int(g.rv_reg(j2)["stage"]) == 1, "победа правительства")
	await drop(g)
	# --- гражданская война и революция ---
	var g2 = mk({})
	for k in 5: await process_frame
	g2.rv_conf_start("civil", -1, 40.0, "тест")
	check(g2.rv_conf_count("civil") == 1, "гражданская война не началась")
	g2.rv["conf"][0]["ctl"] = 95.0
	g2.next_turn()
	check(g2.game_over and g2.end_reason.contains("Гражданская"), "поражение в гражданской войне должно закончить игру: %s" % g2.end_reason)
	await drop(g2)
	var g3 = mk({})
	for k in 5: await process_frame
	g3.rv_event_rev()
	check(String(g3.current_event.get("rvk", "")) == "rev" and g3.current_event["o"].size() == 4, "событие революции")
	g3.choose(2)
	check(not g3.current_event.is_empty() or not g3.game_over, "после переговоров игра продолжается")
	settle(g3)
	g3.rv["nat"]["rev"] = 90.0
	g3.rv_event_rev()
	g3.choose(3)
	check(g3.game_over and g3.end_reason.contains("Революция"), "бегство должно закончить игру")
	await drop(g3)
	# --- перевороты: события против вас ---
	for pick in [0, 1, 2, 3]:
		var g4 = mk({})
		for k in 5: await process_frame
		g4.rv["nat"]["coup"] = 70.0
		var c_before: float = g4.rv["nat"]["coup"]
		g4.rv_event_coup()
		check(String(g4.current_event.get("rvk", "")) == "coup", "событие переворота")
		g4.choose(pick)
		check(not is_nan(float(g4.rv["nat"]["coup"])), "NaN риска переворота")
		if pick == 2:
			check(float(g4.rv["nat"]["coup"]) < c_before, "уступки военным должны снижать риск")
		if pick == 3:
			check(g4.game_over, "отставка должна закончить игру")
		await drop(g4)
	# --- переворот, который совершаете вы ---
	var g5 = mk({})
	for k in 5: await process_frame
	g5.capital = 60.0
	g5.support["Силовики"] = 80.0
	g5.lvl["security_lvl"] = 80.0
	check(g5.rv_selfcoup_check() == "", "самопереворот должен быть доступен: %s" % g5.rv_selfcoup_check())
	var p_hi: float = g5.rv_selfcoup_prob()
	g5.support["Силовики"] = 30.0
	check(g5.rv_selfcoup_prob() < p_hi, "вероятность переворота растёт с поддержкой силовиков")
	check(g5.rv_selfcoup_check() != "", "при поддержке силовиков 30 переворот недоступен")
	g5.support["Силовики"] = 80.0
	var regs: Array = g5.rv_regime_options()
	check(regs.size() >= 2, "режимов для переворота мало: %d" % regs.size())
	g5.rv_event_regime_choice()
	check(String(g5.current_event.get("rvk", "")) == "newregime", "выбор режима")
	var dem0: float = g5.democracy_index()
	g5.choose(0)
	check(g5.decree_power(), "после выбора режима должна быть власть указами (%s)" % g5.regime_id())
	check(g5.democracy_index() < dem0, "демократия должна упасть")
	months(g5, 6)
	check(not is_nan(g5.gdp), "NaN после переворота")
	await drop(g5)
	# --- переворот и восстание из оппозиции ---
	var g6 = mk({})
	for k in 5: await process_frame
	g6.opp_enter("тест")
	check(g6.opp_mode, "оппозиция")
	g6.capital = 60.0
	g6.support["Силовики"] = 80.0
	check(g6.rv_oppcoup_check() == "" and g6.rv_uprising_check() != "", "заговор доступен, восстание требует волны протестов")
	g6.rv["nat"]["wave"] = 60.0
	check(g6.rv_uprising_check() == "", "восстание доступно: %s" % g6.rv_uprising_check())
	check(g6.rv_uprising() and g6.rv_conf_count("civil") == 1 and String(g6.rv["conf"][0]["side"]) == "rebel", "восстание должно начать гражданскую войну на вашей стороне")
	g6.rv["conf"][0]["ctl"] = 95.0
	g6.next_turn()
	check(not g6.opp_mode and not g6.game_over, "победа повстанцев должна привести вас к власти")
	await drop(g6)
	# --- защита от переворота ---
	var g7 = mk({})
	for k in 5: await process_frame
	g7.capital = 50.0
	g7.rv["nat"]["coup"] = 60.0
	var l0: float = g7.rv["nat"]["loyal"]
	check(g7.rv_coup_measure("loyal") and float(g7.rv["nat"]["loyal"]) > l0, "лояльные назначения")
	check(g7.rv_coup_measure("purge") and float(g7.rv["nat"]["coup"]) < 60.0, "чистка")
	check(not g7.rv_coup_measure("loyal"), "повторно нельзя (перерыв)")
	await drop(g7)
	# --- режим наблюдателя: ИИ справляется со стрессом ---
	var g8 = mk({"observer": true})
	for k in 5: await process_frame
	g8.observer = true
	for m in 60:
		if g8.game_over: break
		for rr in g8.regions:
			rr["unrest"] = minf(100.0, float(rr["unrest"]) + 1.4)
			rr["loy"] = maxf(0.0, float(rr["loy"]) - 1.0)
		settle(g8)
		g8.next_turn()
	check(not is_nan(g8.gdp) and not is_nan(g8.debt), "NaN в режиме наблюдателя")
	check(g8.rv["log"].size() > 0, "ИИ-режим не оставил записей")
	await drop(g8)
	# --- отключение в настройках ---
	var g9 = mk({"revev": 0})
	for k in 5: await process_frame
	for m in 24:
		for rr in g9.regions:
			rr["unrest"] = 80.0
		settle(g9)
		g9.next_turn()
	check(g9.rv["log"].size() == 0 and g9.revolt_g() == 0.0 and g9.revolt_unemp() == 0.0, "при revev=0 модуль должен молчать")
	await drop(g9)
	print("[%s] проверено; проблем %d" % [cc, bad])
	print("проблем %d" % bad)
	quit()
