extends SceneTree
# События v46_1: данные, условия, применение эффектов, цепочки, отложенные последствия, доступность, память, частота, баланс.
var bad := 0

func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)

func mk(o: Dictionary) -> Node:
	var m = load("res://main.gd").new()
	m.game_opts.merge({"agents": false, "k": 0, "seed": 4, "ev": 1.0, "news": 1.0, "econ": 1, "volat": 1.0, "cap": 1.0, "detail": false, "fedev": 1, "socev": 1, "exev": 1, "milev": 0, "revev": 1, "rlev": 1}, true)
	m.game_opts.merge(o, true)
	root.add_child(m)
	return m

func settle(g) -> void:
	var n := 0
	while not g.current_event.is_empty() and n < 8:
		g.choose(0)
		n += 1
	if g.election_open: g.election_continue()

func _init():
	var g = mk({})
	for i in 4: await process_frame
	var cc: String = g.ccode
	# --- данные ---
	var ids := {}
	var chained := {}
	for e in g.EVENTS_X:
		var id: String = String(e.get("id", ""))
		check(id != "" and not ids.has(id), "id события пуст или повторяется: %s" % id)
		ids[id] = true
		check(g.EV_CATS.has(String(e.get("cat", ""))), "%s: неизвестная категория" % id)
		check(String(e.get("title", "")) != "" and String(e.get("t", "")).length() > 30, "%s: нет заголовка или текста" % id)
		var opts: Array = e["o"]
		check(opts.size() >= 2 and opts.size() <= 4, "%s: вариантов должно быть 2–4" % id)
		var free := false
		for o in opts:
			if float(o["fx"].get("capital", 0.0)) >= 0.0: free = true
			if o.has("next"): chained[String(o["next"]["id"])] = true
			if o.has("risk"): check(float(o["risk"]["p"]) > 0.0 and float(o["risk"]["p"]) < 1.0, "%s: вероятность риска вне (0,1)" % id)
		check(free, "%s: нет варианта без затрат капитала" % id)
	for e2 in g.EVENTS_X:
		if bool(e2.get("chain", false)):
			check(chained.has(String(e2["id"])), "продолжение %s никем не вызывается" % e2["id"])
	for nid in chained:
		check(ids.has(nid), "продолжение ссылается на несуществующее событие %s" % nid)
	check(g.EVENTS_X.size() >= 80, "событий мало: %d" % g.EVENTS_X.size())
	# --- условия и применение эффектов ко всем вариантам ---
	for e3 in g.EVENTS_X:
		g.event_ok(e3)
		g.event_region = 0 if bool(e3.get("rreg", false)) else -1
		for o2 in e3["o"]:
			g.apply_fx(o2["fx"], g.event_region)
			if o2.has("risk"): g.apply_fx(o2["risk"]["fx"], g.event_region)
			if o2.has("later"): g.apply_fx(o2["later"]["fx"], g.event_region)
		check(g.ev_text(String(e3["t"])).find("{country}") < 0, "%s: {country} не подставлен" % e3["id"])
	g.event_region = -1
	check(not is_nan(g.gdp) and not is_nan(g.debt) and not is_nan(g.inflation), "NaN после применения всех эффектов")
	var g2 = mk({})
	for i in 4: await process_frame
	g.queue_free()
	g = g2
	settle(g)
	# --- условия-словари ---
	g.inflation = 7.0
	check(g.ev_cond_ok({"infl_gt": 6.0}) and not g.ev_cond_ok({"infl_lt": 6.0}), "условие инфляции")
	check(g.ev_cond_ok({"lvl_lt": {"health_lvl": 99.0}}) and not g.ev_cond_ok({"lvl_gt": {"health_lvl": 99.0}}), "условие уровней")
	check(g.ev_cond_ok({"cor_gt": -1.0}) and not g.ev_cond_ok({"cor_gt": 999.0}), "внешнее условие (коррупция)")
	# --- доступность вариантов ---
	var ev: Dictionary = g.ev_by_id("x_referendum_call")
	# 0.55.5: капитал может уйти в минус — вариант с затратами капитала доступен и при нуле
	g.capital = 0.0
	check(g.ev_opt_block(ev["o"][0]) == "" and g.ev_opt_block(ev["o"][2]) == "", "вариант с капиталом доступен и при нехватке (капитал уходит в минус)")
	g.current_event = ev
	g.choose(0)
	check(g.ev_hist.has("x_referendum_call") and int(g.ev_hist["x_referendum_call"]["o"]) == 0, "должен быть выбран вариант 0")
	check(g.capital < 0.0, "капитал должен уйти в минус: %.1f" % g.capital)
	# --- память и повтор ---
	check(g.ev_weight(ev) == 0.0, "событие не должно повторяться сразу")
	# --- цепочки и отложенные последствия ---
	settle(g)
	g.capital = 50.0
	g.current_event = g.ev_by_id("x_pipeline")
	var opt: Dictionary = (g.current_event["o"][0] as Dictionary).duplicate(true)
	opt["next"]["p"] = 1.0
	opt["next"]["m"] = 1
	g.ev_after_choice(g.current_event, opt, 0, -1)
	g.current_event = {}
	check(g.ev_queue.size() == 1, "продолжение не запланировано")
	var later_opt := {"l": "т", "fx": {}, "later": {"m": 1, "fx": {"debt": 0.1}, "t": "проверка"}}
	g.ev_after_choice({"id": "test_later", "t": "т"}, later_opt, 0, -1)
	check(g.ev_later.size() >= 1, "отложенное последствие не запланировано")
	var shown := false
	for m in 4:
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty():
			if String(g.current_event.get("id", "")) == "x_pipeline_2":
				shown = true
			g.choose(0)
		g.next_turn()
	if String(g.current_event.get("id", "")) == "x_pipeline_2": shown = true
	settle(g)
	check(shown or g.ev_hist.has("x_pipeline_2"), "продолжение цепочки не показано")
	# v50: за эти месяцы другие события могли запланировать свои последствия — проверяем именно тестовое
	var left_test := 0
	for l in g.ev_later:
		if String(l.get("t", "")) == "проверка":
			left_test += 1
	check(left_test == 0, "отложенное последствие не применено")
	# --- частота событий за 5 лет ---
	var g3 = mk({"seed": 9})
	for i in 4: await process_frame
	var cnt := 0
	var seen := {}
	var seen_t := {}
	var mc := 0
	for m2 in 60:
		if g3.game_over: break
		if g3.election_open: g3.election_continue()
		# v49: в оппозиции события решает правительство — такие месяцы не считаем
		if g3.opp_mode or g3.observer:
			g3.next_turn()
			continue
		mc += 1
		var k := 0
		while not g3.current_event.is_empty() and k < 8:
			var idx: String = g3.ev_id(g3.current_event)
			if not seen.has(idx):
				seen[idx] = 0
				seen_t[idx] = String(g3.current_event.get("t", "")).substr(0, 60) + " / " + String(g3.current_event.get("special", ""))
			seen[idx] = int(seen[idx]) + 1
			cnt += 1
			g3.choose(randi() % (g3.current_event["o"] as Array).size())
			k += 1
		g3.next_turn()
	var per_year: float = float(cnt) / maxf(1.0, float(mc)) * 12.0
	if mc >= 12:
		check(per_year >= 3.0 and per_year <= 24.0, "решений в год %.1f вне 3–24 (у власти %d мес.)" % [per_year, mc])
	var rep := 0
	for s in seen:
		if int(seen[s]) > 2:
			rep += 1
			print("REPEAT ", s, " x", seen[s], " ", seen_t[s])
	check(rep <= 3, "слишком много повторов одних и тех же событий: %d" % rep)
	check(not is_nan(g3.gdp) and not is_nan(g3.debt), "NaN за 5 лет")
	print("events ", cc, " решений в год %.1f, разных %d, проблем %d" % [per_year, seen.size(), bad])
	quit(1 if bad > 0 else 0)
