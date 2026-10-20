extends SceneTree
# 0.57.1: день голосования — окно выбора стратегии, сделки, обмен голосами, повестка, последствия закона.
var bad := 0

func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)

func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	var cc := "DE"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("country="):
			cc = a.substr(8)
	if cc != g.ccode:
		g.choose_country(cc)
		for i in 3: await process_frame
	seed(11)
	for m in 14:
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty(): g.choose(0)
		g.advance_month()
	if g.election_open: g.election_continue()
	if not g.current_event.is_empty(): g.choose(0)
	g.capital = 100.0
	if g.opp_mode:
		print("OK voteplan пропуск: после выборов партия игрока в оппозиции (в оппозиции окно выбора не нужно)")
		quit(0)
		return
	# 1) последствия закона: у действующего варианта разницы с действующим порядком нет
	for t in g.LAW_TOPICS:
		var tid: String = t["id"]
		var its: Array = g.variant_effect_items(tid, g.cur_idx(tid))
		check(its.is_empty(), "действующий вариант %s показывает последствия: %s" % [tid, str(its)])
	# 2) без живого режима окно не открывается, голосование по-старому
	var free: Array = []
	for t in g.LAW_TOPICS:
		var tid2: String = t["id"]
		if g.bill_of(tid2) < 0 and g.law_locked(tid2) == "" and int(g.law_cd.get(tid2, 0)) == 0 and (t["v"] as Array).size() > 2:
			free.append(tid2)
	check(free.size() >= 4, "мало свободных законов для проверки")
	var n0: int = g.bills.size()
	g.propose_variant(free[0], (g.cur_idx(free[0]) + 1) % (g.law_index[free[0]]["v"] as Array).size())
	check(g.bills.size() == n0 + 1, "законопроект не внесён")
	for b in g.bills: b["due"] = g.turn
	g.bills_step()
	check(g.vt_stage == 0, "окно выбора открылось вне живого режима")
	# ИИ-партии могли внести новый законопроект уже в этом шаге: он ещё не дошёл до голосования
	var due_left := 0
	for b in g.bills:
		if int(b["due"]) <= g.turn: due_left += 1
	check(due_left == 0, "не все законопроекты проголосованы вне живого режима: %d" % due_left)
	# 3) живой режим
	g.game_opts["voteplan"] = true
	check(g.vote_plan_live(), "живой режим не включился")
	g.capital = 100.0
	var idx1: int = (g.cur_idx(free[1]) + 1) % (g.law_index[free[1]]["v"] as Array).size()
	g.propose_variant(free[1], idx1)
	var own_id := -1
	for b in g.bills:
		if int(b["sponsor"]) == 0: own_id = int(b["id"])
	check(own_id >= 0, "свой законопроект не внесён")
	var sp := 0
	for p in range(1, g.PARTY_NAMES.size()):
		if g.seats[p] > 0 and sp == 0 and not (p in g.NO_GOV_SLOTS): sp = p
	g.bill_seq += 1
	var oid: int = g.bill_seq
	g.bills.append({"id": oid, "tid": free[2], "idx": (g.cur_idx(free[2]) + 1) % (g.law_index[free[2]]["v"] as Array).size(), "sponsor": sp, "start": g.turn, "due": g.turn, "forced": [], "pow": 1.0, "req": [], "paid": 0.0, "did": {}, "pa": true, "pv": "line"})
	for b in g.bills: b["due"] = g.turn
	var att: Array = g.bills_attention()
	check(att.size() >= 1, "повестка не видит законопроекты, ждущие решения")
	g.bills_step()
	check(g.vt_stage == 1 and g.vt_plan_busy(), "окно выбора не открылось в день голосования")
	var shown: int = g.vt_plan_bid
	var n1: int = g.bills.size()
	g.bills_step()
	check(g.bills.size() == n1 and g.vt_plan_bid == shown, "второй вызов bills_step сломал открытое окно")
	# сделка: покупаем голоса у первой партии, которая против
	var guard := 0
	while g.vt_stage != 0 and guard < 6:
		guard += 1
		var bi: int = g.bill_index(g.vt_plan_bid)
		check(bi >= 0, "законопроект окна выбора пропал")
		if bi < 0: break
		var b: Dictionary = g.bills[bi]
		if int(b["sponsor"]) == 0:
			var sw: Array = g.bill_swing_parties(b)
			var y0: int = int(g.bill_plan_preview(b, [], "")["yes"])
			var y1: int = int(g.bill_plan_preview(b, sw, "")["yes"])
			check(y1 >= y0, "сделки уменьшили прогноз «за»")
			if sw.size() > 0:
				var cap0: float = g.capital
				check(g.bill_plan_apply(g.vt_plan_bid, [sw[0]], []), "сделка не применилась")
				check(g.capital <= cap0, "сделка не списала капитал")
				check(int(sw[0]) in (b["forced"] as Array), "партия сделки не попала в forced")
		else:
			var cap1: float = g.capital
			check(g.pa_trade(g.vt_plan_bid), "обмен голосами не сработал")
			check(g.capital > cap1, "обмен голосами не дал капитала")
			check(String(b["pv"]) == "yes", "после обмена фракция не голосует «за»")
		g.vote_plan_go()
		check(g.vt_stage == 2 or g.vt_stage == 0, "после голосования окно в состоянии %d" % g.vt_stage)
		if g.vt_stage == 2:
			g.vote_btn_pressed()      # пропустить анимацию
			g.vote_btn_pressed()      # закрыть, подхватить следующий законопроект
	var due_left2 := 0
	for b in g.bills:
		if int(b["due"]) <= g.turn: due_left2 += 1
	check(g.vt_stage == 0 and due_left2 == 0, "после всех голосований остались законопроекты (%d) или окно (%d)" % [due_left2, g.vt_stage])
	# 4) предупреждение за месяц до голосования и вето повестки не ломают
	g.game_opts["voteplan"] = false
	print("OK voteplan bad=", bad)
	quit(1 if bad > 0 else 0)
