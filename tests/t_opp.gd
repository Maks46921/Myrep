extends SceneTree
# Выбор партии и оппозиция: подмена партии, старт в оппозиции, действия, соглашения, выборы.
var bad := 0
func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)

func mk(k: int) -> Node:
	var m0 = load("res://main.gd")
	m0.pending_party = k
	var m = m0.new()
	m.game_opts.merge({"ev": 0.0, "news": 0.0, "fedev": 0, "socev": 0, "exev": 0}, true)
	m.game_opts["seed"] = 7
	root.add_child(m)
	return m

func settle(g) -> void:
	if g.election_open: g.election_continue()
	if not g.current_event.is_empty(): g.choose(0)

func _init():
	var cc := ""
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("country="): cc = String(a).substr(8)
	# 1) выбор каждой допустимой партии: загрузка, согласованность, 14 месяцев
	var base = mk(0)
	for i in 3: await process_frame
	var n: int = base.PARTY_NAMES.size()
	var orig_names: Array = base.PARTY_NAMES.duplicate()
	var orig_coal: Array = base.COALITION0.duplicate()
	var base_seats: Array = base.seats.duplicate()
	# 0.56: играть можно и за региональную, и за протестную партию (не за сборные списки и «прочих»)
	var ok_k: Array = []
	for k in range(1, n):
		if base.player_swap_ok(k): ok_k.append(k)
	var prot0: int = base.PROTEST_P
	var reg0: int = base.REGIONAL_P
	base.queue_free()
	var tried := 0
	for k in range(1, n):
		if not (k in ok_k): continue
		tried += 1
		var g = mk(k)
		for i in 3: await process_frame
		check(g.PARTY_NAMES[0] == orig_names[k], "имя партии %d" % k)
		check(g.PARTY_NAMES[k] == orig_names[0], "прежняя партия власти на месте %d" % k)
		check(g.PROTEST_P == g.swap_idx(prot0, k) and g.REGIONAL_P == g.swap_idx(reg0, k), "протестная/региональная партия не следует за обменом (%d)" % k)
		var sp := 0
		for s in g.seats: sp += int(s)
		check(sp == g.SEATS, "сумма мест %d: %d/%d" % [k, sp, g.SEATS])
		check(g.opp_mode == (not (k in orig_coal)), "режим оппозиции партии %d: %s" % [k, str(g.opp_mode)])
		if g.opp_mode:
			check(not g.in_coalition[0], "в оппозиции вы не в коалиции")
			check(not g.opp_gov.is_empty() and g.opp_gov["members"].size() > 0, "правительство без вас задано")
		for m in 14:
			settle(g)
			g.next_turn()
			if g.game_over: break
		check(g.PARTY_NAMES[0] == orig_names[k], "имя после игры %d" % k)
		print("  партия %d «%s»: опп=%s мест %d, правительство: %s, кап %.0f, рейтинг %.0f" % [k, g.PARTY_NAMES[0], str(g.opp_mode), g.seats[0], g.opp_gov_text() if g.opp_mode else "вы", g.capital, g.approval()])
		g.queue_free()
		await process_frame
	# 2) действия оппозиции и соглашения
	var o = null
	for k in range(1, n):
		if k in [6, 8, 9] or k in orig_coal or int(base_seats[k]) <= 0: continue
		o = mk(k)
		break
	if o != null:
		for i in 3: await process_frame
		for dk in [1, 4, 12, 0, 3, 5, 12]:
			o.show_desk(dk)
			for i in 3: await process_frame
			o.refresh()
		var key0: String = "income"
		var before: float = float(o.pol[key0])
		o.on_slider(before + 3.0, key0)
		check(absf(float(o.pol[key0]) - before) < 0.001, "бюджет в оппозиции заблокирован")
		o.show_desk(12)
		o.capital = 100.0
		for a in o.OPP_ACTS:
			if a["id"] in ["early", "nocon", "join"]: continue
			o.opp_cd.clear()
			o.capital = 100.0
			check(o.opp_act(a["id"]), "действие " + a["id"])
		o.capital = 100.0
		var tgt := -1
		for p in range(1, n):
			if not (p in [6, 8, 9]) and o.seats[p] > 0: tgt = p; break
		for kind in ["talk", "talk", "talk", "tol", "votes", "bloc", "attack"]:
			o.opp_cd.clear()
			o.capital = 100.0
			o.prel[tgt] = 80.0 if kind != "attack" else o.prel[tgt]
			var ok: bool = o.pact_do(tgt, kind)
			check(ok, "соглашение %s: %s" % [kind, o.pact_can(tgt, kind)])
		check(o.pact_has(tgt, "tol") and o.pact_has(tgt, "votes"), "соглашения действуют")
		o.capital = 100.0
		o.opp_cd.clear()
		o.opp_act("early")
		settle(o)
		o.opp_cd.clear()
		o.capital = 100.0
		o.opp_act("join")
		settle(o)
		for m in 30:
			settle(o)
			o.next_turn()
			if o.game_over: break
		print("  итог: опп=%s, ход %d, выборов было, мест %d" % [str(o.opp_mode), o.turn, o.seats[0]])
	# 3) переходы власть <-> оппозиция
	var g3 = mk(0)
	for i in 3: await process_frame
	check(not g3.opp_mode, "по умолчанию вы у власти")
	g3.opp_enter("тест")
	check(g3.opp_mode and not g3.in_coalition[0], "opp_enter")
	# вы получили большинство
	for p in range(n): g3.seats[p] = 0
	g3.seats[0] = g3.MAJORITY + 5
	g3.seats[1] = g3.SEATS - g3.seats[0]
	var r: String = g3.opp_after_election()
	check(r == "gov" and not g3.opp_mode and g3.in_coalition[0], "победа: возврат к власти (%s)" % r)
	g3.opp_enter("тест 2")
	for p in range(n): g3.seats[p] = 0
	g3.seats[0] = 120
	g3.seats[1] = 330
	g3.seats[2] = g3.SEATS - 450
	r = g3.opp_after_election()
	check(g3.opp_mode or r == "gov", "исход после выборов с чужим большинством: " + r)
	check(r == "opp", "чужое большинство -> оппозиция (%s)" % r)
	print("t_opp: партий ", tried, " проблем ", bad)
	quit(1 if bad > 0 else 0)
