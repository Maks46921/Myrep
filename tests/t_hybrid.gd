extends SceneTree
# Гибридные законы: сила действия, финансирование партий (бонусы/штрафы к голосам).
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
	var hyb := 0
	for t in g.LAW_TOPICS:
		if g.is_hybrid(String(t["id"])):
			hyb += 1
	check(hyb >= 3, "есть гибридные законы (%d)" % hyb)
	check(g.law_pow_slider != null, "есть ползунок силы")
	var tid := "healthcare"
	if not g.is_hybrid(tid):
		for t in g.LAW_TOPICS:
			if g.is_hybrid(String(t["id"])):
				tid = String(t["id"]); break
	g.capital = 100.0
	g.law_pow_sel[tid] = 0.5
	var c_low: float = g.law_cost(tid, 1)
	g.law_pow_sel[tid] = 1.5
	var c_hi: float = g.law_cost(tid, 1)
	check(c_hi > c_low, "цена растёт с силой (%.1f → %.1f)" % [c_low, c_hi])
	g.law_pow_sel[tid] = 0.5
	var sd_low: Dictionary = g.support_delta(tid, 1)
	g.law_pow_sel[tid] = 1.5
	var sd_hi: Dictionary = g.support_delta(tid, 1)
	var sl := 0.0
	var sh := 0.0
	for k in sd_low: sl += absf(float(sd_low[k]))
	for k in sd_hi: sh += absf(float(sd_hi[k]))
	check(sh > sl, "эффект растёт с силой (%.1f → %.1f)" % [sl, sh])
	# принять и потом изменить силу
	g.law_pow_sel[tid] = 1.0
	g.law_cd[tid] = 0
	g.adopt_variant(tid, 1, [1, 2, 3, 4, 5, 6, 7, 8, 9])
	if g.cur_idx(tid) == 1:
		check(is_equal_approx(float(g.law_pow[tid]), 1.0), "сила принята")
		g.law_cd[tid] = 0
		g.law_pow_sel[tid] = 1.4
		g.capital = 100.0
		check(g.law_tweak(tid), "изменение силы распознано")
		g.adopt_variant(tid, 1, [1, 2, 3, 4, 5, 6, 7, 8, 9])
		check(is_equal_approx(float(g.law_pow[tid]), 1.4), "сила изменена до 1.4")
	# финансирование
	if g.law_index.has("party_funding"):
		var base: Array = []
		for p in g.PARTY_NAMES.size():
			base.append(g.funding_mult(p))
		check(is_equal_approx(float(base[1]), 1.0), "частное финансирование нейтрально")
		g.law_state["party_funding"] = 1
		g.law_pow["party_funding"] = 1.0
		var funded := -1
		var unfunded := -1
		for p in range(1, g.PARTY_NAMES.size()):
			if g.party_funded(p) and funded < 0: funded = p
			if not g.party_funded(p) and unfunded < 0: unfunded = p
		if funded >= 0: check(g.funding_mult(funded) > 1.0, "получающая партия: бонус")
		if unfunded >= 0: check(g.funding_mult(unfunded) < 1.0, "не получающая партия: штраф")
		g.law_state["party_funding"] = 2
		var lo := 9.0
		var hi := -9.0
		for p in range(1, g.PARTY_NAMES.size()):
			lo = minf(lo, g.funding_mult(p)); hi = maxf(hi, g.funding_mult(p))
		check(hi > lo, "доноры: разные множители")
		g.law_state["party_funding"] = 0
	g.next_turn()
	check(is_finite(g.gdp), "месяц идёт")
	g.show_desk(3)
	for i in 3: await process_frame
	g.sel_topic = tid
	g.refresh()
	print("t_hybrid: проблем ", bad)
	quit(1 if bad > 0 else 0)
