extends SceneTree
# Блоки, демография, энергия, право, СМИ, регионы (v44_1).
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

func _init():
	var g = mk({})
	for i in 5: await process_frame
	var cc: String = g.ccode
	check(g.rl_on() and not g.rl.is_empty(), "состояние rl не создано")
	var b: Dictionary = g.rl["b"]
	check(bool(b["eu"]) == (cc in g.RL_EU), "членство в ЕС не совпадает с данными: %s" % cc)
	check(bool(b["nato"]) == (cc in g.MIL_NATO), "членство в НАТО не совпадает с данными: %s" % cc)
	check(float(g.rl["l"]["cor"]) > 0.0 and float(g.rl["d"]["age"]) > 5.0, "стартовые значения")
	for pg in ["blocs", "demo", "energy", "law", "media", "region", "parl"]:
		check(g.rl_acts(pg).size() > 0, "нет действий на странице " + pg)
	check(g.rl_summary_text().length() > 100, "сводка пуста")
	# --- действия ---
	g.capital = 90.0
	var f0: float = g.rl["m"]["free"]
	check(g.rl_do("pub"), "общественное вещание")
	check(float(g.rl["m"]["free"]) > f0, "свобода прессы должна вырасти")
	check(not g.rl_do("pub"), "перерыв должен блокировать повтор")
	g.capital = 90.0
	var j0: float = g.rl["l"]["jud"]
	check(g.rl_do("courts"), "реформа судов")
	months(g, 7)
	check(float(g.rl["l"]["jud"]) > j0 + 4.0, "суды должны стать независимее: %.1f → %.1f" % [j0, float(g.rl["l"]["jud"])])
	settle(g)
	g.capital = 90.0
	check(g.rl_do("fam_up") and int(g.rl["lv"]["fam"]) == 1, "семейная политика")
	check(g.rl_do("grn_up") and int(g.rl["lv"]["grn"]) == 1, "зелёный переход")
	var gr0: float = g.rl["e"]["green"]
	months(g, 12)
	check(float(g.rl["e"]["green"]) > gr0 + 3.0, "зелёная доля должна расти")
	var age0: float = g.rl["d"]["age"]
	months(g, 12)
	check(float(g.rl["d"]["age"]) > age0, "население стареет")
	check(not is_nan(g.gdp) and not is_nan(g.debt) and not is_nan(g.inflation), "NaN в экономике")
	# --- блоки ---
	settle(g)
	g.capital = 90.0
	if bool(g.rl["b"]["nato"]):
		check(g.rl_do("leave_nato") and not g.mil_is_nato(cc), "выход из НАТО")
		g.capital = 90.0
		check(g.rl_do("acc_nato"), "заявка в НАТО")
		g.rl["acc"]["nato"]["p"] = 99.0
		for d in g.dip: g.dip[d]["rel"] = 80.0
		months(g, 2)
		check(g.mil_is_nato(cc), "приём в НАТО")
	elif not bool(g.rl["b"]["eu"]):
		check(g.rl_do("acc_eu") and g.rl["acc"].has("eu"), "заявка в ЕС")
		g.rl["acc"]["eu"]["p"] = 99.0
		for d in g.dip: g.dip[d]["rel"] = 80.0
		months(g, 2)
		check(bool(g.rl["b"]["eu"]) and bool(g.MACRO["eu"]), "приём в ЕС")
	g.capital = 90.0
	settle(g)
	check(g.rl_do("coal_summit"), "саммит коалиции")
	check(g.noc_constr == (cc in g.RL_CONSTR), "конструктивный вотум")
	for k2 in ["coh_comp", "coh_fight", "coh_wait"]:
		g.realism_resolve({"act": k2})
	# --- события ---
	for k in ["shock_sub", "shock_div", "shock_none", "clim_aid", "clim_adapt", "clim_min", "scand_fire", "scand_probe", "scand_hide", "fake_fact", "fake_ban", "fake_ignore", "demo_ret", "demo_tax", "demo_debt"]:
		g.realism_resolve({"act": k})
	check(not is_nan(float(g.rl["e"]["price"])), "цена энергии")
	# --- длинный прогон ---
	months(g, 60)
	check(not is_nan(g.gdp) and g.gdp > 0.0, "ВВП после длинного прогона")
	check(g.rl["h"]["age"].size() > 20, "история не копится")
	# --- сохранения и откат ---
	var gdp_s: float = g.gdp
	var turn_s: int = g.turn
	var cap_s: float = g.capital
	check(g.sv_save(2), "сохранение не записано")
	check(g.sv_info(2) != "", "информация о слоте пуста")
	months(g, 8)
	check(g.turn > turn_s, "ход не идёт после сохранения")
	check(g.sv_load(2), "загрузка не удалась")
	check(g.turn == turn_s and absf(g.gdp - gdp_s) < 1e-6 and absf(g.capital - cap_s) < 1e-6, "состояние после загрузки не совпало: turn %d/%d gdp %.3f/%.3f" % [g.turn, turn_s, g.gdp, gdp_s])
	check(g.rl_on() and g.dx_on() and not g.rl["h"]["gdp"].is_empty(), "rl/dx после загрузки")
	months(g, 14)
	check(g.sv_hist.size() > 0, "автоснимки не делаются")
	var tt: int = g.turn
	check(g.sv_rollback() and g.turn < tt, "откат не удался")
	months(g, 3)
	check(not is_nan(g.gdp), "NaN после отката")
	# --- выключение ---
	var g2 = mk({"rlev": 0})
	for i in 3: await process_frame
	months(g2, 6)
	check(g2.rl_g() == 0.0 and g2.rl_infl() == 0.0 and g2.rl_acts("blocs").is_empty(), "при rlev=0 модуль должен молчать")
	print("realism ", cc, " проблем ", bad)
	quit(1 if bad > 0 else 0)
