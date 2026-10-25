extends SceneTree
# 0.59: лампочки, требования партий идут в черновик бюджета, ... (наращивается по мере правок)
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
	# --- лампочки ---
	var iss: Array = g.lamp_issues()
	check(iss is Array, "лампочки: список проблем строится")
	for it in iss:
		check(it.has("id") and it.has("lv") and it.has("page") and it.has("off"), "лампочки: у проблемы есть поля")
	g.nav_extras()
	check(g.lamp_dots.size() >= 7, "лампочки: точки созданы на рамках и вкладках (%d)" % g.lamp_dots.size())
	# --- п.4: требования партнёров идут в черновик ---
	var p := -1
	for q in range(1, g.PARTY_NAMES.size()):
		if g.in_coalition[q] and not (g.PARTY_DEMANDS[q] as Array).is_empty():
			for d in g.PARTY_DEMANDS[q]:
				if not g.demand_met(d) and d["key"] != "reg_auto":
					p = q
	if p < 0:
		# требований нет или все выполнены: нарушаем одно искусственно
		for q in range(1, g.PARTY_NAMES.size()):
			if not g.in_coalition[q]:
				continue
			for d in g.PARTY_DEMANDS[q]:
				var k: String = d["key"]
				if k != "reg_transfer" and k != "reg_auto" and g.pol.has(k):
					g.set_policy(k, 0.0 if d["op"] == ">=" else g.pol_hi(k))
					if not g.demand_met(d):
						p = q
						break
			if p >= 0:
				break
	if p >= 0 and not g.pl_deny():
		check(g.bud_changes().is_empty(), "черновик пуст до требований")
		var cur_before: Dictionary = g.pol.duplicate()
		g.fulfill_party_demands(p)
		check(not g.bud_changes().is_empty(), "требования партии внесены в черновик")
		check(g.bud_demand_by == p, "запомнен автор правок")
		g.bud_cancel()
		check(g.bud_changes().is_empty(), "после отмены черновик пуст")
		for k in cur_before:
			check(absf(float(g.pol[k]) - float(cur_before[k])) < 0.001, "после отмены «%s» вернулась" % k)
	else:
		print("нет партнёра с невыполненными требованиями: пропуск п.4")
	# --- п.6: большая правка статьи вступает постепенно ---
	g.bud_cancel()
	var kk := "vat"
	var o0: float = float(g.pol[kk])
	g.bud_mark(kk, o0, -1.0)
	g.set_policy(kk, o0 + 4.0)
	check(g.bud_big_total() > g.BUD_BIG, "п.6: большая правка распознана (%.1f)" % g.bud_big_total())
	g.bud_apply(false)
	check(absf(float(g.pol[kk]) - (o0 + 1.0)) < 0.02, "п.6: первый шаг не больше 1 п.п. (%.2f)" % (float(g.pol[kk]) - o0))
	check(g.bud_glide.has(kk), "п.6: цель запомнена")
	var prev: float = float(g.pol[kk])
	for i in 6:
		g.bud_glide_step()
		check(float(g.pol[kk]) - prev <= 1.02, "п.6: шаг в месяц не больше 1 п.п.")
		prev = float(g.pol[kk])
	check(not g.bud_glide.has(kk) and absf(float(g.pol[kk]) - (o0 + 4.0)) < 0.02, "п.6: цель достигнута за несколько месяцев (%.2f)" % (float(g.pol[kk]) - o0))
	# --- п.13: законы-ползунки: барьер, сроки, налоги ---
	for tid in ["elect_threshold", "parl_term_law", "pres_term_law", "income_tax_law", "corp_tax_law", "vat_law"]:
		if not g.law_index.has(tid):
			continue
		var lt: Dictionary = g.law_index[tid]
		if not lt.has("param"):
			print("п.13: у страны свой закон «%s», не ползунок" % tid)
			continue
		var vs13: Array = lt["v"]
		check(vs13.size() >= 5, "п.13: у «%s» есть значения по сетке" % tid)
		check(g.cur_idx(tid) == 0, "п.13: «%s» стоит на действующем значении" % tid)
		for vv in vs13:
			check(not String(vv["n"]).contains("%!") and String(vv["n"]) != "", "п.13: у значения «%s» есть подпись" % tid)
	if g.law_index.has("elect_threshold") and g.law_index["elect_threshold"].has("param"):
		var thr0: float = float(g.mods["threshold"])
		var vsT: Array = g.law_index["elect_threshold"]["v"]
		var pick := -1
		for i in range(1, vsT.size()):
			if vsT[i].has("set") and float(vsT[i]["set"]["threshold"]) > thr0 + 0.01:
				pick = i
				break
		check(pick >= 0, "п.13: есть значение барьера выше нынешнего")
		if pick >= 0:
			g.capital = 900.0
			g.in_coalition.fill(true)
			var allp: Array = []
			for q in g.PARTY_NAMES.size():
				allp.append(q)
			g.adopt_variant("elect_threshold", pick, allp)
			g.recompute_mods()
			check(float(g.mods["threshold"]) > thr0 + 0.01, "п.13: барьер изменился (%.3f -> %.3f)" % [thr0, float(g.mods["threshold"])])
	# --- п.9: флаги ---
	check(g.Flags.db_has(g.ccode), "флаги: у страны есть исторические флаги")
	var ents: Array = g.Flags.entries(g.ccode)
	check(ents.size() >= 1, "флаги: список не пуст (%d)" % ents.size())
	var ids := {}
	var sigs := {}
	for e in ents:
		check(not ids.has(e["id"]), "флаги: id не повторяется: %s" % e["id"])
		ids[e["id"]] = true
		check(not sigs.has(String(e["svg"])), "флаги: нет одинаковых картинок внутри страны: %s и %s" % [e["id"], sigs.get(String(e["svg"]), "")])
		sigs[String(e["svg"])] = e["id"]
		check(g.Flags.render_image(String(e["svg"]), 60.0) != null, "флаги: SVG %s читается" % e["id"])
	var cur0: String = g.flag_cur_id()
	check(not g.Flags.entry(cur0).is_empty(), "флаги: текущий флаг есть в базе")
	if ents.size() >= 2:
		var other := ""
		for e in ents:
			if e["id"] != cur0:
				other = String(e["id"])
				break
		g.flag_set(other, "тест")
		check(g.flag_cur_id() == other and g.Flags.cur[g.ccode] == other, "флаги: смена флага применяется")
		check(g.flag_title() != "", "флаги: название государства не пустое")
	# редактор: свой флаг
	g.fe_reset()
	g.fe["name"] = "Тест"
	g.fe["sym"] = 0
	var svg_t: String = g.flag_build_svg(g.fe)
	check(g.Flags.render_image(svg_t, 90.0) != null, "флаги: SVG из редактора читается")
	g.flag_editor_save()
	check(g.flag_custom.size() == 1 and String(g.flag_cur_id()).begins_with("my"), "флаги: свой флаг сохранён и выбран")
	var pk: PackedByteArray = g.sv_pack()
	g.flag_custom = {}
	g.flag_id = ""
	g.sv_apply(pk)
	check(g.flag_custom.size() == 1 and String(g.flag_cur_id()).begins_with("my"), "флаги: сохранение игры хранит свой флаг")
	# смена строя: вопрос о флаге
	g.flag_id = ""
	g.flag_sync()
	g.flag_pending = {}
	g.flag_tags_last = ["Монархия"]
	g.flag_month()
	check(g.flag_tags_last == g.flag_tags_now(), "флаги: строй запомнен после месяца")
	print("t_v059: проблем ", bad)
	quit(1 if bad > 0 else 0)
