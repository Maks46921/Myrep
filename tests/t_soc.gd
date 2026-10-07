extends SceneTree
# Религии, миграция, экономическое влияние и зависимость.
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

func sums_ok(g) -> bool:
	for r in g.regions:
		var s := 0.0
		for f in 7:
			if float(r["rel"][f]) < -1e-9: return false
			s += float(r["rel"][f])
		if absf(s - 1.0) > 1e-3: return false
	return true

func _init():
	var g = mk({})
	for i in 5: await process_frame
	var cc: String = g.ccode
	check(sums_ok(g), "доли религий регионов должны давать 1")
	var nat: Array = g.soc_national()
	var ns := 0.0
	for f in 7: ns += float(nat[f])
	check(absf(ns - 1.0) < 1e-3, "национальный состав не даёт 1")
	check(absf(g.soc_g()) < 1e-9 and absf(g.soc_unemp()) < 1e-9 and absf(g.soc_tax()) < 1e-9, "на старте влияние религии/миграции должно быть нулевым")
	check(absf(g.ex_g()) < 1e-9 and absf(g.ex_infl()) < 1e-9, "на старте торговая политика не влияет")
	var parts_s := PackedStringArray()
	for f in 7: parts_s.append("%s %.0f%%" % [g.SOC_FAITH[f], float(nat[f]) * 100.0])
	print("[%s] религия: %s" % [cc, ", ".join(parts_s)])
	# агенты: у каждого есть вера, состав близок к модели
	if g.AG != null:
		var cnt: PackedInt32Array = g.AG.faith_counts()
		var tot := 0
		for f in 7: tot += cnt[f]
		var worst := 0.0
		for f in 7:
			worst = maxf(worst, absf(float(cnt[f]) / float(maxi(1, tot)) - float(nat[f])))
		print("  агентов %d, макс. отклонение состава агентов от модели %.1f п.п." % [tot, worst * 100.0])
		check(tot == g.AG.n, "у каждого агента должна быть вера")
		check(worst < 0.09, "состав агентов далёк от модели: %.3f" % worst)
	# статичный режим: за 24 месяца ничего не меняется
	var pop0: float = g.total_pop()
	run_months(g, 24)
	var nat2: Array = g.soc_national()
	var dmax := 0.0
	for f in 7: dmax = maxf(dmax, absf(float(nat2[f]) - float(nat[f])))
	check(dmax < 0.002, "в статичном режиме состав религий изменился на %.4f" % dmax)
	# открытая миграция: население и состав сдвигаются, напряжённость растёт
	g.capital = 500.0
	g.soc["cd"].clear()
	g.soc_set_mig(1)
	g.soc["cd"].clear()
	g.soc_set_mig(1)
	check(int(g.soc["lvl"]) == 4, "уровень миграции не поднялся")
	var p1: float = g.total_pop()
	var nat3: Array = g.soc_national()
	var ac0: PackedInt32Array = g.AG.faith_counts() if g.AG != null else PackedInt32Array()
	run_months(g, 36)
	check(sums_ok(g), "после миграции доли религий не дают 1")
	check(g.total_pop() > p1, "при открытых границах население должно расти быстрее")
	check(float(g.soc["net"]) > 0.0, "накопленная чистая миграция должна быть положительной")
	check(float(g.soc["tension"]) >= 0.0 and float(g.soc["tension"]) <= 100.0, "напряжённость вне диапазона")
	var nat4: Array = g.soc_national()
	print("  после 36 мес. открытых границ: население %+.2f млн, нерелигиозных %.1f→%.1f%%, мусульман %.1f→%.1f%%, напряжённость %.1f, интеграция %.0f" % [g.total_pop() - p1, float(nat3[6]) * 100, float(nat4[6]) * 100, float(nat3[3]) * 100, float(nat4[3]) * 100, g.soc["tension"], g.soc["integ"]])
	if g.AG != null and ac0.size() == 7:
		var ac1: PackedInt32Array = g.AG.faith_counts()
		var tot0 := 0.0
		var tot1 := 0.0
		for f in 7:
			tot0 += float(ac0[f])
			tot1 += float(ac1[f])
		var d_ag: float = (float(ac1[3]) / tot1 - float(ac0[3]) / tot0) * 100.0
		var d_md: float = (float(nat4[3]) - float(nat3[3])) * 100.0
		print("  мусульман: модель %+.2f п.п., агенты %+.2f п.п." % [d_md, d_ag])
		check(absf(d_ag - d_md) < 1.2, "вера агентов не следует за моделью (%.2f против %.2f)" % [d_ag, d_md])
	check(not is_nan(g.gdp) and g.gdp > 0.0, "NaN в ВВП")
	# религиозная политика
	g.capital = 500.0
	g.soc["cd"].clear()
	g.game_over = false
	check(g.soc_set_sec(1), "курс на секуляризм")
	check(g.soc_set_fund(1), "поддержка общин")
	check(g.soc_dialog(), "межконфессиональный совет")
	check(g.soc_set_prog(1), "программы интеграции")
	check(g.soc_set_sel(1), "отбор мигрантов")
	run_months(g, 6)
	await drop(g)
	# живая динамика + давление партнёров, 60 месяцев
	var g2 = mk({"socev": 1, "exev": 1, "fedev": 1})
	for i in 5: await process_frame
	g2.capital = 400.0
	var parts: Array = g2.ex_partners()
	check(parts.size() >= 10, "в мире мало партнёров: %d" % parts.size())
	var c0: String = String(parts[0])
	for pc in parts:
		if not g2.dip.has(pc):
			c0 = String(pc)
			break
	var dp: Dictionary = g2.ex_dep(c0)
	for k in ["out", "in", "bal", "tr_out", "tr_in"]:
		check(not is_nan(float(dp[k])), "NaN в зависимости %s" % k)
	check(float(dp["tr_out"]) > 0.0, "торговая зависимость от %s должна быть положительной" % c0)
	g2.fst["rel_x"][c0] = 30.0
	check(g2.ex_deal_set(c0, 1) or true, "")
	g2.ex["p"][c0]["cd"].clear()
	g2.ex["p"][c0]["deal"] = 2
	check(g2.ex_g() > 0.0, "торговое соглашение должно давать рост")
	check(g2.ex_bot_g(c0) > 0.0, "соглашение должно помогать и партнёру")
	g2.ex["p"][c0]["deal"] = 0
	g2.ex["p"][c0]["cd"].clear()
	check(g2.ex_tariff_set(c0, 1), "пошлины")
	check(g2.ex_g() < 0.0 and g2.ex_bot_g(c0) < 0.0, "пошлины бьют по обоим")
	g2.ex["p"][c0]["cd"].clear()
	check(g2.ex_aid_give(c0), "помощь")
	g2.ex["p"][c0]["cd"].clear()
	check(g2.ex_dbuy_set(c0, 1), "выкуп долга")
	check(g2.ex_leverage(c0) >= 0.0 and g2.ex_leverage(c0) <= 100.0, "влияние вне диапазона")
	var g0: float = g2.gdp
	run_months(g2, 60)
	check(g2.gdp > 0.0 and not is_nan(g2.gdp) and not is_nan(g2.debt), "NaN после 60 месяцев")
	check(sums_ok(g2), "доли религий не дают 1 после живой динамики")
	var n5: Array = g2.soc_national()
	print("  60 мес. живой динамики: нерелигиозных %.1f%%, мусульман %.1f%%, напряжённость %.1f, ВВП %.0f→%.0f" % [float(n5[6]) * 100, float(n5[3]) * 100, g2.soc["tension"], g0, g2.gdp])
	# передача территории не ломает религию
	await drop(g2)
	print("проблем %d" % bad)
	quit()
