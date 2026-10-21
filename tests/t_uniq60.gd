extends SceneTree
# 0.60: особые строи — данные, путь из трёх этапов, провозглашение, механики, кнопки, реакции мира, жребий на выборах
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
	var ccs := {}
	var used := {}
	for d in g.REG_UNIQ60:
		check(not ccs.has(d["cc"]), "особый строй: страна %s один раз" % d["cc"])
		ccs[d["cc"]] = true
		check(String(d["d"]).length() > 80 and String(d["mo"]) != "", "строй %s: описание и девиз" % d["id"])
		check((d["st"] as Array).size() == 3, "строй %s: три этапа" % d["id"])
		check((d["mech"] as Array).size() >= 2, "строй %s: механики" % d["id"])
		for m in d["mech"]:
			check(g.UQ_MECH60.has(m), "строй %s: механика %s описана" % [d["id"], m])
			used[m] = true
		for k in d["m"]:
			check(g.MOD_INFO.has(k), "строй %s: показатель %s" % [d["id"], k])
		for dc in (d["w"].get("dip", {}) as Dictionary):
			check(dc != d["cc"], "строй %s: реакция не на себя" % d["id"])
		for e in d["w"].get("ev", []):
			check((e["o"] as Array).size() >= 2, "строй %s: событие соседей" % d["id"])
		var n := 0
		for e in g.REG_UEV60:
			if e["u"] == d["id"]:
				n += 1
				check((e["o"] as Array).size() >= 2, "событие %s: два варианта" % d["id"])
		check(n >= 5, "строй %s: событий %d" % [d["id"], n])
	check(ccs.size() == 19, "особых строёв 19 (%d)" % ccs.size())
	check(used.size() == 12, "используются все 12 механик (%d)" % used.size())
	for id in g.UQ_MECH60:
		var md: Dictionary = g.UQ_MECH60[id]
		for k in md["m"]:
			check(g.MOD_INFO.has(k), "механика %s: показатель %s" % [id, k])
		check((md["b"] as Array).size() >= 2, "механика %s: кнопки" % id)
	var d: Dictionary = g.uq_def()
	if d.is_empty():
		print("t_uniq60: ", g.ccode, " без особого строя; проблем ", bad)
		quit(1 if bad > 0 else 0)
		return
	print("страна ", g.ccode, ": ", d["n"], "; индекс демократии ", snappedf(g.democracy_index(), 0.01), ", рейтинг ", snappedf(g.approval(), 0.1), ", условия сразу ", g.uq_conds_ok(d["need"]))
	g.uq_init()
	check(g.uq_title() == "", "до провозглашения названия нет")
	# путь
	for st in 3:
		g.uq["next"] = 0
		g.current_event = {}
		g.uq_stage_show(d, int(g.uq["stage"]))
		check(not g.current_event.is_empty() and String(g.current_event.get("special", "")) == "uq60", "этап %d: событие показано" % (st + 1))
		g.choose(0)
	check(g.uq_on(), "строй провозглашён")
	check(g.uq_title() == d["n"], "название строя в шапке")
	g.recompute_mods()
	var g0: float = g.mods["growth_bonus"]
	# отказ и откладывание
	var save_on: bool = g.uq["on"]
	g.uq["on"] = false
	g.uq["stage"] = 1
	g.uq_stage_show(d, 1)
	g.choose(1)
	check(int(g.uq["stage"]) == 1 and int(g.uq["next"]) >= g.turn + 9, "«Отложить» оставляет этап и сдвигает срок")
	g.uq_stage_show(d, 1)
	g.choose(2)
	check(int(g.uq["stage"]) == 0 and int(g.uq["next"]) >= g.turn + 40, "«Отказаться» сбрасывает путь надолго")
	g.uq["on"] = save_on
	g.uq["stage"] = 3
	# кнопки механик
	g.capital = 300.0
	for mid in d["mech"]:
		var md: Dictionary = g.UQ_MECH60[mid]
		for b in md["b"]:
			g.uq["cd"] = {}
			var id: String = "%s:%s" % [mid, b["id"]]
			g.uq["fund"] = 50.0
			var why: String = g.uq_act_check(id)
			if why == "":
				check(g.uq_act(id), "кнопка %s срабатывает" % id)
			else:
				print("кнопка ", id, ": ", why)
	for e in g.REG_UEV60:
		if e["u"] == d["id"]:
			for o in e["o"]:
				g.apply_fx(o["fx"])
				if (o["fx"] as Dictionary).has("uq"):
					for k in o["fx"]["uq"]:
						g.uq_mech_add(String(k), float(o["fx"]["uq"][k]))
	g.recompute_mods()
	check(is_finite(float(g.mods["growth_bonus"])), "показатели конечны")
	# месяцы
	g.uq["m"] = {}
	for m in d["mech"]:
		g.uq["m"][m] = 55.0
	g.recompute_mods()
	var months := 0
	for m in 48:
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty(): g.choose(0)
		g.next_turn()
		months += 1
		if g.game_over: break
	check(months >= 12, "прошло %d мес." % months)
	check(g.uq_on() or g.game_over, "строй сохраняется")
	if g.game_over:
		print("t_uniq60: ", g.ccode, " игра окончена за время теста; проблем ", bad)
		quit(1 if bad > 0 else 0)
		return
	# реакции мира отыгрались
	g.uq["react"] = [{"t": 0, "e": d["w"]["ev"][0] if d["w"].has("ev") and d["w"]["ev"].size() > 0 else {"t": "x", "o": [{"l": "a", "fx": {}}, {"l": "b", "fx": {}}]}}]
	g.current_event = {}
	g.uq_react_step(d)
	check(not g.current_event.is_empty() or g.game_over, "событие соседей показано")
	if not g.current_event.is_empty(): g.choose(0)
	# жребий
	var sh: Array[float] = [0.3, 0.3, 0.2, 0.2]
	g.uq["m"]["lot"] = 100.0
	var sh2: Array[float] = g.uq_lot_shares(sh) if d["mech"].has("lot") else sh
	var s := 0.0
	for x in sh2: s += x
	check(absf(s - 1.0) < 0.001, "жребий сохраняет сумму долей")
	# сохранение
	var sv: Variant = g.uq.duplicate(true)
	check(sv is Dictionary and sv.has("m"), "состояние строя можно сохранить")
	# отказ от строя
	g.capital = 100.0
	if g.uq_on():
		check(g.uq_abandon(), "отказ от особого строя")
		check(not g.uq_on(), "строй снят")
	print("t_uniq60: ", g.ccode, " проблем ", bad, ", рост ", snappedf(g0, 0.01))
	quit(1 if bad > 0 else 0)
