extends SceneTree
# v35: стили игры для длинных прогонов. style=… months=360 party=K country=XX. Печатает строку STY {json}.
#   passive    — ничего не делает сам: только решает события (первый вариант)
#   careful    — автопилот бюджета (осторожный), события по осторожному стилю, бережёт коалицию
#   populist   — раздаёт: социальный курс, события ради рейтинга, в оппозиции — критика и митинги
#   austerity  — экономия: режет расходы и долг, события — минимум долгов
#   growth     — курс на рост, стройки, деловой стиль событий
#   reformer   — активно вносит законы (ИИ-подбор под свою партию), переговоры и союзы по голосованию
#   coalition  — дипломат: уступки и требования партнёров, приглашения с обещаниями, договоры в оппозиции
#   chaos      — случайные решения, случайные ползунки и действия
const STYLES := ["passive", "careful", "populist", "austerity", "growth", "reformer", "coalition", "chaos"]

func arg(k: String, d: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(k + "="):
			return a.substr(k.length() + 1)
	return d

var st := {"gov_m": 0, "opp_m": 0, "elections": 0, "won": 0, "crisis_m": 0, "partner_left": 0, "laws": 0, "deadlocks": 0, "snap": 0, "nan": 0, "low_appr_m": 0}

func pick_event(g, style: String) -> int:
	var n: int = (g.current_event["o"] as Array).size()
	match style:
		"passive": return 0
		"chaos": return randi() % n
		"careful", "austerity", "coalition": g.ap["style"] = 0
		"populist": g.ap["style"] = 1
		"growth", "reformer": g.ap["style"] = 2
	if String(g.current_event.get("special", "")) == "crisis":
		return 0
	return g.auto_event_pick(g.current_event)

func gov_actions(g, style: String, m: int) -> void:
	match style:
		"careful":
			g.ap["bal"] = true; g.ap["repair"] = true
			if m % 6 == 0: coal_care(g, 0.0)
		"populist":
			if m % 12 == 0 and g.capital > 10: g.apply_preset("social")
			if m % 4 == 0 and g.capital > 14: g.do_action("address")
		"austerity":
			g.ap["bal"] = true; g.ap["target"] = -0.5
		"growth":
			g.ap["build"] = true; g.ap["repair"] = true
			if m % 12 == 0: g.apply_preset("growth")
			g.ap["bal"] = m % 2 == 0
		"reformer":
			g.ap["bal"] = true
			var mine := false
			for b in g.bills:
				if int(b["sponsor"]) == 0: mine = true
			if not mine and g.capital >= 16.0:
				var members: Array = []
				for p in g.coal_members():
					if p != 0: members.append(p)
				g.ai_pick_law(0, members if members.size() > 0 else [0])
		"coalition":
			g.ap["bal"] = true
			coal_care(g, 1.0)
		"chaos":
			if randf() < 0.3:
				var d: Dictionary = g.POLICY[randi() % g.POLICY.size()]
				var k: String = d["key"]
				g.set_policy(k, float(g.pol[k]) + randf_range(-1.0, 1.0))
	# любой стиль, кроме пассивного и хаоса, пытается спасти правительство в кризисе
	if style != "passive" and style != "chaos" and not g.gov_ok():
		var best := -1
		var bw := -INF
		for p in range(1, g.PARTY_NAMES.size()):
			if g.can_govern(p) and not g.in_coalition[p] and g.seats[p] > 0:
				var w: float = g.invite_offer_w(p, true, 1)
				if w > bw: bw = w; best = p
		if best > 0:
			g.invite_party(best, true, 1 if bw - 6.0 < g.COALITION_JOIN else 0)

func coal_care(g, eager: float) -> void:
	for p in g.coal_members():
		if p == 0: continue
		var s: float = float(g.satis.get(p, 60.0))
		if s < g.SAT_LEAVE + 12.0 + 8.0 * eager and g.capital >= 14.0:
			g.do_concession(p)
		elif s < g.SAT_LEAVE + 20.0 and eager > 0.5:
			g.fulfill_party_demands(p)

func opp_actions(g, style: String, m: int) -> void:
	var tries: Array = []
	match style:
		"passive": return
		"populist": tries = ["critic", "rally", "early"]
		"reformer", "coalition": tries = ["join"]
		"chaos": tries = [["critic", "rally", "probe", "early", "nocon", "join"][randi() % 6]]
		_: tries = ["critic", "rally"]
	for id in tries:
		if g.opp_act(id): break
	if style in ["reformer", "coalition"] and m % 3 == 0:
		var best := -1
		var bv := -1.0
		for p in range(1, g.PARTY_NAMES.size()):
			if g.pact_can(p, "talk") == "" and float(g.prel[p]) > bv and g.seats[p] > 0:
				bv = float(g.prel[p]); best = p
		if best > 0:
			for k in ["votes", "tol", "bloc", "talk"]:
				if g.pact_can(best, k) == "":
					g.pact_do(best, k)
					break

func _init():
	var style := arg("style", "careful")
	var months := int(arg("months", "360"))
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	var g0: float = g.gdp
	var pop0: float = g.total_pop()
	var imax := 0.0
	var dmax := 0.0
	var m := 0
	var last_parl: int = g.last_parl
	var prev_opp: bool = g.opp_mode
	while m < months and not g.game_over:
		if g.election_open: g.election_continue()
		var guard := 0
		while not g.current_event.is_empty() and guard < 5:
			g.choose(pick_event(g, style)); guard += 1
		if g.opp_mode: opp_actions(g, style, m)
		else: gov_actions(g, style, m)
		var coal0: int = g.coal_members().size()
		g.next_turn()
		if g.election_open: g.election_continue()
		if g.last_parl != last_parl:
			st["elections"] += 1
			last_parl = g.last_parl
			if not g.opp_mode: st["won"] += 1
		if g.deadlock > 0: st["deadlocks"] = maxi(st["deadlocks"], g.deadlock)
		if g.opp_mode: st["opp_m"] += 1
		else: st["gov_m"] += 1
		if g.crisis_months > 0: st["crisis_m"] += 1
		if g.approval() < 30.0 and not g.opp_mode: st["low_appr_m"] += 1
		if not g.opp_mode and not prev_opp and g.coal_members().size() < coal0 and g.last_parl != g.turn: st["partner_left"] += 1
		prev_opp = g.opp_mode
		for k in ["inflation", "unemployment", "growth", "gdp", "debt"]:
			var v: float = g.get(k)
			if is_nan(v) or is_inf(v): st["nan"] += 1
		if arg("trace", "0") == "1" and m % 12 == 0:
			print("m%d gdp %.0f g %.2f infl %.2f u %.1f debt %.0f appr %.1f cap %.0f opp %s seats %d/%d" % [m, g.gdp, g.growth, g.inflation, g.unemployment, g.debt / g.gdp * 100.0, g.approval(), g.capital, g.opp_mode, g.gov_seats(), g.SEATS])
		imax = maxf(imax, g.inflation)
		dmax = maxf(dmax, g.debt / maxf(1.0, g.gdp) * 100.0)
		m += 1
	var laws := 0
	var d := {"cc": g.ccode, "style": style, "party": g.PARTY_NAMES[0], "slot": int(arg("party", "0")), "m": m, "over": g.game_over, "why": String(g.end_reason).substr(0, 60),
		"gdp_x": snappedf(g.gdp / g0, 0.001), "growth_y": snappedf((pow(g.gdp / g0, 12.0 / maxf(1.0, float(m))) - 1.0) * 100.0, 0.01), "debt": snappedf(g.debt / maxf(1.0, g.gdp) * 100.0, 0.1), "dmax": snappedf(dmax, 0.1),
		"infl": snappedf(g.inflation, 0.1), "imax": snappedf(imax, 0.1), "u": snappedf(g.unemployment, 0.1), "appr": snappedf(g.approval(), 0.1), "cap": snappedf(g.capital, 0.1),
		"pop_x": snappedf(g.total_pop() / pop0, 0.001), "opp_end": g.opp_mode}
	d.merge(st)
	print("STY ", JSON.stringify(d))
	quit()
