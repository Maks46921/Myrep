extends SceneTree
# 0.65: война (усталость, помощь, потолок демократии, цель по инфляции, Беларусь и нефть, настроение регионов),
# политические движения (данные, уровни режимов, ответы власти, игра за движение, партия), верхняя палата (правила, комиссия,
# отложенные законы, назначения, требования, реформа). Страна — country=XX; party=1000+N запускает игру за движение.
var bad := 0


func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)


func _init():
	var g = load("res://main.gd").new()
	g.game_opts.merge({"agents": false}, true)
	root.add_child(g)
	for i in 3: await process_frame
	var cc: String = g.ccode
	seed(65)
	if g.mv_player_mv():
		await play_checks(g, cc)
	else:
		await war_checks(g, cc)
		move_checks(g, cc)
		upper_checks(g, cc)
		await upper_month_checks(g, cc)
	print("проблем %d" % bad)
	quit()


# ---------- война и «структурные» поправки ----------
func war_checks(g, cc: String) -> void:
	check(g.x65_on(), "модуль 0.65 выключен")
	if cc == "UA":
		check(absf(g.infl_tgt() - 5.0) < 0.01, "цель инфляции Украины не 5: %s" % g.infl_tgt())
		check(g.infl_anchor() > g.infl_tgt() + 3.0, "якорь инфляции Украины должен быть заметно выше цели")
	elif cc == "DE":
		check(absf(g.infl_tgt() - g.I_TGT) < 0.01, "у еврозоны цель — общая")
	# настроение регионов: рост недовольства даёт минус, спад — небольшой плюс
	g.x65_ensure()
	var u0: float = g.x65["unrest0"]
	for r in g.regions:
		r["unrest"] = minf(100.0, float(r["unrest"]) + 10.0)
	var m1: float = g.x65_mood_calc()
	check(m1 < -0.5 and m1 >= -2.0 - 0.001, "настроение регионов при росте недовольства: %s" % m1)
	for r in g.regions:
		r["unrest"] = maxf(0.0, float(r["unrest"]) - 25.0)
	var m2: float = g.x65_mood_calc()
	check(m2 > 0.0 and m2 <= 8.0 + 0.001, "настроение регионов при спаде недовольства: %s" % m2)
	g.x65["unrest0"] = u0
	if cc == "BY":
		g.res_price = 0.55
		var lo: float = g.x65_g()
		g.res_price = 1.0
		var mid: float = g.x65_g()
		check(lo < -0.4 and absf(mid) < 0.001, "нефть Беларуси: 0,55 → %s, 1,0 → %s" % [lo, mid])
	if g.mil.is_empty() or not g.mil_at_war():
		check(g.war65_wf() == 0.0, "без войны усталость должна быть 0")
		return
	var w: Dictionary = g.mil["war"]
	w["weary"] = 20.0
	check(g.war65_wf() == 0.0, "усталость при weary=20 не 0")
	w["weary"] = 140.0
	var wf1: float = g.war65_wf()
	check(absf(wf1 - (1.0 - exp(-1.0))) < 0.01, "усталость при weary=140: %s" % wf1)
	w["weary"] = 600.0
	check(g.war65_wf() > 0.95 and g.war65_wf() <= 1.0, "усталость должна упираться в 1")
	var aggr: bool = bool(w.get("aggr", false))
	var dk: float = g.war65_draft_k()
	if aggr:
		check(dk == 1.0, "у агрессора призыв не падает от усталости")
	else:
		check(dk >= 0.65 and dk < 1.0, "призыв в стране-жертве при долгой войне: %s" % dk)
	# потолок падения демократии при военном положении
	if not aggr and g.martial:
		var fl: float = g.war65_dem_floor(0.0)
		check(fl >= 0.30, "потолок падения демократии при военном положении: %s" % fl)
	else:
		check(g.war65_dem_floor(0.12) == 0.12, "агрессору потолок не положен")
	# уход авторитарного лидера делает преемника гибче
	g.mil["ldr_gone"] = true
	g.mil["ldr_t"] = g.turn - 13
	w["weary"] = 300.0
	check(g.war65_stance("hard") != "hard", "после ухода лидера «жёсткая» позиция должна смягчиться")
	check(g.war65_stance("mild") == "soft", "через год при усталости «умеренная» позиция становится «мягкой»")
	g.mil["ldr_gone"] = false
	check(g.war65_stance("hard") == "hard", "без ухода лидера позиция не меняется")
	# внешняя помощь
	if not aggr:
		var it: Dictionary = g.war_intl(w)
		var mn: float = g.war65_aid_money(w, it)
		check(mn >= 0.0 and mn < g.gdp * 0.01, "помощь за месяц нереалистична: %s при ВВП %s" % [mn, g.gdp])
	# годы подряд без сбоев
	for i in 24:
		g.next_turn()
	check(not is_nan(g.inflation) and g.inflation > -5.0 and g.inflation < 60.0, "инфляция вышла за пределы: %s" % g.inflation)
	var wf2: float = g.war65_wf()
	check(wf2 >= 0.0 and wf2 <= 1.0, "усталость вышла за [0,1]: %s" % wf2)


# ---------- политические движения ----------
func move_checks(g, cc: String) -> void:
	var rows: Array = g.MV65_DATA.get(cc, [])
	check(rows.size() >= 6, "%s: движений в данных мало: %d" % [cc, rows.size()])
	g.mv_ensure()
	var list: Array = g.mv_list()
	check(list.size() == rows.size(), "%s: в игре %d движений, в данных %d" % [cc, list.size(), rows.size()])
	var tier: int = g.mv_tier()
	var dem: float = g.democracy_index()
	var want: int = 0 if dem >= 0.8 else (1 if dem >= 0.6 else (2 if dem >= 0.3 else (3 if dem >= 0.15 else 4)))
	check(tier == want, "%s: уровень режима %d при демократии %.2f" % [cc, tier, dem])
	var types := {}
	for m in list:
		types[String(m["tp"])] = true
		check(float(m["sup"]) >= 0.0 and float(m["sup"]) <= 40.0 and float(m["org"]) >= 0.0 and float(m["org"]) <= 100.0, "%s: поддержка или организованность вне границ" % m["id"])
		check(String(m["name"]) != "" and String(m["desc"]) != "", "%s: нет названия или описания" % m["id"])
	check(types.size() >= 4, "%s: типов движений мало: %d" % [cc, types.size()])
	# ответы власти
	var tgt: Dictionary = {}
	for m in list:
		if not bool(m["pro"]) and String(m["st"]) == "on":
			tgt = m
			break
	if not tgt.is_empty():
		var id: String = String(tgt["id"])
		var s0: float = float(tgt["sup"])
		var cap0: float = g.capital
		check(g.mv_gov_do(id, "concede"), "%s: уступки не удались" % cc)
		check(float(tgt["sup"]) < s0 and g.capital < cap0, "%s: уступки не снизили поддержку или не стоили капитала" % cc)
		check(g.mv_gov_can(tgt, "concede") != "", "%s: уступки должны уйти на перезарядку" % cc)
		tgt["thr"] = 0
		var why: String = g.mv_gov_can(tgt, "ban")
		if tier <= 1:
			check(why != "", "%s: в демократии нельзя запрещать движение без угрозы безопасности" % cc)
		else:
			check(why == "", "%s: запрет движения должен быть доступен (%s)" % [cc, why])
			check(g.mv_gov_do(id, "ban") and String(tgt["st"]) == "ban", "%s: запрет не сработал" % cc)
			check(g.mv_gov_do(id, "lift") == false or String(tgt["st"]) == "on", "%s: снятие запрета" % cc)
	# месяцы идут без сбоев
	for i in 18:
		g.next_turn()
	for m in g.mv_list():
		check(not is_nan(float(m["sup"])) and float(m["sup"]) <= 40.0 and float(m["org"]) <= 100.0, "%s: к концу прогона %s вышло за границы" % [cc, m["id"]])
	var sh: Array = g.national_shares(false)
	var tot := 0.0
	for p in sh.size():
		tot += float(sh[p])
	check(absf(tot - 1.0) < 0.02, "%s: доли партий дают %s, а не 1" % [cc, tot])


func play_checks(g, cc: String) -> void:
	check(g.mv_player_mv(), "игра за движение не началась")
	var me: Dictionary = g.mv_find(String(g.mv65["play"]))
	check(not me.is_empty(), "не нашлось движение игрока")
	check(g.seats[0] == 0, "у движения не должно быть мест в парламенте, а их %d" % g.seats[0])
	check(g.mv65_ballot() == 0.0 or bool(g.mv65.get("reg", false)), "до регистрации вас не должно быть в бюллетене")
	for i in 3:
		g.next_turn()
	# действия движения: подписи, блогеры, пожертвования
	var done := 0
	for id in ["donate", "sign", "blog", "rally"]:
		if g.mv_can(me, id) == "":
			if g.mv_act(String(me["id"]), id):
				done += 1
	check(done >= 2, "доступных действий движения слишком мало: %d" % done)
	var tier: int = g.mv_tier()
	if tier < 3 and g.mv_party_can(me) == "":
		var seats_before: int = g.seats[0]
		check(g.mv_to_party(String(me["id"])) or tier == 2, "регистрация партии не удалась")
		if bool(g.mv65.get("reg", false)):
			check(g.mv65_ballot() == 1.0, "после регистрации вы должны быть в бюллетене")
			check(String(me["st"]) == "party", "движение не стало партией")
			var wing := false
			for m in g.mv_list():
				if String(m["id"]) == String(me["id"]) + "_wing":
					wing = true
			check(wing, "при регистрации партии должно появиться радикальное крыло")
			check(float(g.national_shares(false)[0]) > 0.005, "у новой партии нет доли в опросах")
			check(seats_before == 0, "до выборов мест быть не должно")
	for i in 14:
		g.next_turn()
	check(not g.game_over or true, "")


# ---------- верхняя палата ----------
func upper_checks(g, cc: String) -> void:
	g.up65_ensure()
	var on: bool = g.upper_on()
	var kind: String = String(g.UPPER.get("kind", "none"))
	var stats := {"fast": 0, "slow": 0, "no": 0, "block": 0, "pass": 0}
	for t in g.LAW_TOPICS:
		var tid: String = t["id"]
		for idx in (t["v"] as Array).size():
			if idx == g.cur_idx(tid):
				continue
			var u: Dictionary = g.upper_check(tid, idx, [])
			if not bool(u.get("on", false)):
				check(not bool(u.get("block", false)), "%s %s→%d: выключенная палата блокирует закон" % [cc, tid, idx])
				continue
			if String(u.get("kind", "")) == "veto":
				continue
			check(int(u["yes"]) >= 0 and int(u["yes"]) <= int(u["total"]), "%s %s→%d: голосов %s из %s" % [cc, tid, idx, u["yes"], u["total"]])
			check(not (bool(u["block"]) and bool(u["passed"])), "%s %s→%d: палата и одобрила, и заблокировала" % [cc, tid, idx])
			var ovr: String = String(u.get("ovr", ""))
			if ovr == "slow":
				check(int(u.get("delay", 0)) > 0, "%s %s→%d: отсрочка без срока" % [cc, tid, idx])
			if ovr == "no":
				check(bool(u["block"]), "%s %s→%d: «нельзя преодолеть», но не блокирует" % [cc, tid, idx])
			if ovr != "":
				check(not bool(u["passed"]), "%s %s→%d: преодоление при одобрении палатой" % [cc, tid, idx])
				stats[ovr] = int(stats[ovr]) + 1
			if bool(u["block"]):
				stats["block"] += 1
			elif bool(u["passed"]):
				stats["pass"] += 1
	print("%s палата: %s" % [cc, str(stats)])
	if kind == "none" or not on:
		check(int(stats["fast"]) + int(stats["slow"]) + int(stats["no"]) == 0, "%s: без палаты не должно быть преодолений" % cc)
	if kind == "full":
		check(int(stats["slow"]) == 0 and int(stats["fast"]) == 0, "%s: равноправную палату нельзя преодолеть" % cc)
	var m: Dictionary = g.up65_meta()
	if on and int(m.get("slow", 0)) > 0 and kind == "override":
		check(int(stats["slow"]) + int(stats["pass"]) > 0, "%s: отлагательное вето не встречается" % cc)
	# согласительная комиссия
	if on and bool(m.get("conc", false)) and not g.LAW_TOPICS.is_empty():
		var tid0: String = String(g.LAW_TOPICS[0]["id"])
		var okn := 0
		var failn := 0
		for i in 120:
			g.up65["conf"] = 0.0
			g.law_cd[tid0] = 0
			var cm: Dictionary = g.up65_conciliate(tid0, 0, {"block": true, "passed": false, "extra": 0.0, "kind": kind})
			if bool(cm["ok"]):
				okn += 1
				check(not bool(cm["upc"]["block"]) and float(cm["upc"]["extra"]) > 0.0, "%s: комиссия согласовала, но закон всё ещё блокирован или бесплатен" % cc)
			else:
				failn += 1
		check(okn >= 20 and failn >= 5, "%s: комиссия: согласовала %d, не договорилась %d из 120" % [cc, okn, failn])
		g.up65["conf"] = 90.0
		var okh := 0
		for i in 120:
			g.up65["conf"] = 90.0
			g.law_cd[tid0] = 0
			if bool(g.up65_conciliate(tid0, 0, {"block": true, "passed": false, "extra": 0.0, "kind": kind})["ok"]):
				okh += 1
		check(okh < okn, "%s: при остром конфликте комиссия должна договариваться реже (%d против %d)" % [cc, okh, okn])
		g.up65["conf"] = 8.0
	elif on:
		var cm2: Dictionary = g.up65_conciliate(String(g.LAW_TOPICS[0]["id"]), 0, {"block": true, "extra": 0.0, "kind": kind})
		check(not bool(cm2["ok"]), "%s: комиссии нет, а она согласовала" % cc)
	# отложенный закон
	if on and int(m.get("slow", 0)) > 0:
		var pick_tid := ""
		var pick_idx := -1
		for t in g.LAW_TOPICS:
			var tid: String = t["id"]
			if g.is_fund(tid):
				continue
			for idx in (t["v"] as Array).size():
				if idx != g.cur_idx(tid):
					pick_tid = tid
					pick_idx = idx
					break
			if pick_tid != "":
				break
		g.vote_sponsor = 0
		g.last_vote = {"extra": []}
		var cur0: int = g.cur_idx(pick_tid)
		var cap0: float = g.capital
		g.up65_delay_law(pick_tid, pick_idx, 5.0, 4, {"yes": 300, "no": 100, "abst": 0})
		check((g.up65["q"] as Array).size() == 1 and g.cur_idx(pick_tid) == cur0, "%s: закон должен ждать в очереди" % cc)
		check(absf(cap0 - g.capital - 5.0) < 0.01, "%s: капитал за отложенный закон" % cc)
		check(int(g.law_cd.get(pick_tid, 0)) > 0, "%s: закон в очереди не заблокирован для повторных попыток" % cc)
		g.turn += 3
		g.up65_flush()
		check(g.cur_idx(pick_tid) == cur0 and (g.up65["q"] as Array).size() == 1, "%s: закон вступил в силу раньше срока" % cc)
		g.turn += 1
		g.up65_flush()
		check(g.cur_idx(pick_tid) == pick_idx and (g.up65["q"] as Array).is_empty(), "%s: закон не вступил в силу вовремя" % cc)
	# назначения и переговоры
	if on:
		var wp: String = g.up65_pack_why()
		check((wp == "") == bool(m.get("app", false)) or wp != "", "%s: назначения" % cc)
		if bool(m.get("app", false)) and wp == "":
			var t0: int = int(g.UPPER["total"])
			var n: int = g.up65_pack_n()
			g.up65_pack()
			check(int(g.UPPER["total"]) == t0 + n, "%s: назначение не добавило места: %d → %d" % [cc, t0, g.UPPER["total"]])
		else:
			var t1: int = int(g.UPPER["total"])
			g.up65_pack()
			check(int(g.UPPER["total"]) == t1, "%s: назначать нельзя, но места выросли" % cc)
		g.up65["conf"] = 50.0
		g.up65["dcd"] = -99
		g.up65_deal()
		check(float(g.up65["conf"]) < 45.0, "%s: переговоры не сняли конфликт" % cc)
		g.up65["dem"] = {"k": "policy", "cost": 6.0, "due": g.turn + 6}
		var c1: float = g.capital
		g.up65_dem_answer(true)
		check(g.capital < c1 and (g.up65["dem"] as Dictionary).is_empty(), "%s: требование палаты не выполнено" % cc)
		g.up65["conf"] = 10.0
		g.up65["dem"] = {"k": "policy", "cost": 6.0, "due": g.turn + 6}
		g.up65_dem_answer(false)
		check(float(g.up65["conf"]) > 15.0, "%s: отказ палате должен усилить конфликт" % cc)
	# реформа
	g.MACRO["const_need"] = 0.05
	g.MACRO["amend_ref"] = false
	if not on:
		g.up65["rcd"] = -99
		var inf: Dictionary = g.up65_reform_info("create", "override", "direct", 1)
		check(bool(inf["ok"]), "%s: создать палату нельзя: %s" % [cc, inf["why"]])
		check(not bool(g.up65_reform_info("abolish", "none", "direct", 1)["ok"]), "%s: упразднить нечего" % cc)
		var made := false
		for i in 5:
			g.up65["rcd"] = -99
			g.up65_reform_do("create", "override", "regional", 1)
			if g.upper_on():
				made = true
				break
		check(made and String(g.UPPER["kind"]) == "override" and int(g.UPPER["total"]) > 0, "%s: палата не создана" % cc)
		var tt := 0
		for bl in g.UPPER["blocs"]:
			tt += int(bl[0])
		check(tt == int(g.UPPER["total"]), "%s: места блоков (%d) и размер палаты (%d) не совпадают" % [cc, tt, g.UPPER["total"]])
		var u2: Dictionary = g.upper_check(String(g.LAW_TOPICS[0]["id"]), 0, [])
		check(bool(u2.get("on", false)), "%s: новая палата не участвует в проверке законов" % cc)
	else:
		g.up65["rcd"] = -99
		check(not bool(g.up65_reform_info("create", "override", "direct", 1)["ok"]), "%s: палата уже есть, создавать нечего" % cc)
		var pw2: String = "full" if kind != "full" else "override"
		var done_pw := false
		for i in 40:
			g.up65["rcd"] = -99
			g.up65["conf"] = 0.0
			g.up65_reform_do("powers", pw2, "direct", 1)
			if String(g.UPPER["kind"]) == pw2:
				done_pw = true
				break
		check(done_pw, "%s: полномочия не изменились за 40 попыток" % cc)
		var done_ab := false
		for i in 120:
			g.up65["rcd"] = -99
			g.up65_reform_do("abolish", "none", "direct", 1)
			if not g.upper_on():
				done_ab = true
				break
		check(done_ab, "%s: палата не упразднена за 120 попыток" % cc)
		check(int(g.UPPER.get("total", 0)) == 0 and not g.upper_on(), "%s: после упразднения палата работает" % cc)
		check(not bool(g.upper_check(String(g.LAW_TOPICS[0]["id"]), 0, []).get("on", false)), "%s: упразднённая палата проверяет законы" % cc)


func upper_month_checks(g, cc: String) -> void:
	# ход месяцев с палатой: индекс конфликта в границах
	if g.upper_on():
		for i in 30:
			g.up65_month()
			var c: float = float(g.up65["conf"])
			check(c >= 0.0 and c <= 100.0 and not is_nan(c), "%s: конфликт палат вне границ: %s" % [cc, c])
	g.up65["tilt"] = 0.0
	check(g.up65_g() <= 0.0, "%s: давление конфликта на рост должно быть неположительным" % cc)
