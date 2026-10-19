extends SceneTree
# 0.56 (доп. 3 и 4): рычаги режима второй части, одноразовые решения, страх и пропаганда ×2.
var bad := 0
func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)
func _init():
	var g = load("res://main.gd").new()
	g.game_opts.merge({"ev": 0.0, "news": 0.0}, true)
	root.add_child(g)
	for i in 3: await process_frame
	check(g.au_on(), "режим недемократический (%s)" % String(g.au.get("cls", "?")))
	var x: Dictionary = g.au_x()
	check(x.has("pol") and x.has("bm") and x.has("patron"), "состояние au.x создано")
	for i in 6: g.next_turn()
	check(g.au_med().size() == g.regions.size(), "охват СМИ по регионам")
	# рычаги: каждый либо проходит, либо честно объясняет отказ
	var ok := 0
	for a in g.AU2_ACTS:
		g.capital = 300.0
		g.au["cd"].clear()
		var id := String(a[0])
		var why: String = g.au_check(id)
		if why == "":
			var ft0: float = float(g.au["fear"])
			check(g.au_act(id), "рычаг %s выполнен" % id)
			ok += 1
		g.au["cd"].clear()
	check(ok >= 10, "работает достаточно рычагов (%d)" % ok)
	g.capital = 300.0
	var f0: float = float(g.au["fear"])
	g.au["cd"].clear()
	if g.au_check("pol_up") == "":
		g.au_act("pol_up")
		check(float(g.au["fear"]) > f0, "тайная полиция поднимает страх")
	# содержание: долг растёт
	var d0: float = g.debt
	for i in 3: g.next_turn()
	check(float(g.au_x()["upkeep"]) >= 0.0, "содержание считается")
	check(is_finite(g.debt) and is_finite(g.gdp), "числа конечные")
	# множитель оппозиции и 2× относительно старта
	var fe0: float = g.au_fe()
	g.au["fear"] = float(g.au["base"]["fear"]) + 10.0
	check(absf(g.au_fe() - (float(g.au["base"]["fear"]) + 20.0)) < 0.01, "страх выше старта действует вдвое")
	g.au["fear"] = float(g.au["base"]["fear"])
	check(absf(g.au_fe() - float(g.au["fear"])) < 0.01, "на стартовом уровне эффект единичный")
	# одноразовые решения
	g.capital = 300.0
	var sel := ["const", "purge", "regs", "sym"]
	var opts := {"reg_mode": "appoint", "name": "Великая Республика"}
	check(g.au2_dec_check(sel, opts) == "", "пакет решений допустим: %s" % g.au2_dec_check(sel, opts))
	var c_pack: float = g.au2_dec_cost(sel, opts)
	var c_sum := 0.0
	for id in sel: c_sum += float(g.au2_dec_def(id)[2])
	check(c_pack < c_sum, "пакетная скидка (%.1f < %.1f)" % [c_pack, c_sum])
	var cap0: float = g.capital
	check(g.au2_dec_sign(sel, opts), "пакет подписан")
	check(absf(cap0 - g.capital - c_pack) < 0.01, "списан капитал пакета")
	check(g.au2_dec_done("purge") and String(g.au_x()["title"]) == "Великая Республика", "решения отмечены принятыми")
	check(g.au2_dec_avail("purge") != "", "повторно принять нельзя")
	g.capital = 300.0
	if g.au2_dec_avail("nat") == "":
		check(g.au2_dec_sign(["nat"], {"nat_mode": "confiscate"}), "национализация")
		check(g.corp_state_share() > 0.99, "все компании государственные")
	if g.au2_dec_avail("close") == "":
		check(g.au2_dec_sign(["close"], {}), "закрытие границ")
		check(bool(g.au_x()["closed"]), "границы закрыты")
	var ev: Array = g.au2_dec_econ_variants()
	if ev.size() > 0:
		g.capital = 300.0
		g.law_cd["econ_model"] = 0
		check(g.au2_dec_sign(["econ"], {"econ": int(ev[0][0])}), "смена экономической модели")
	if g.au2_dec_avail("ban") == "" or String(g.au["cls"]) == "hybrid":
		g.capital = 300.0
		if g.au2_dec_avail("ban") == "":
			check(g.au2_dec_sign(["ban"], {}), "запрет партий")
	# месяцы идут, выборы со всеми флагами не падают
	g.au_x()["staged"] = true
	g.au_x()["turnq"] = 60.0
	var sh: Array[float] = []
	for p in g.PARTY_NAMES.size(): sh.append(1.0 / float(g.PARTY_NAMES.size()))
	var out: Array[float] = g.au_fraud_shares(sh)
	var tot := 0.0
	for v in out: tot += v
	check(absf(tot - 1.0) < 0.001, "доли после постановочных выборов дают 100%% (%.4f)" % tot)
	check(out[g.au_pp()] > sh[g.au_pp()], "партия власти получила прибавку")
	g.au2_after_election()
	for i in 36: g.next_turn()
	check(is_finite(g.gdp) and g.gdp > 0.0, "36 месяцев после решений")
	print("t_au2: проблем ", bad, " | ", g.au2_report().replace("\n", " ; ").substr(0, 300))
	quit(1 if bad > 0 else 0)
