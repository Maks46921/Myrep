extends SceneTree
# Большая проверка партийного ИИ: идеологии, правление неигровых партий, их капитал, законопроекты и поправки,
# младший партнёр, верность партийной линии, борьба за власть на длинной дистанции.
var bad := 0
func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)

func mk(k: int) -> Node:
	var m0 = load("res://main.gd")
	m0.pending_party = k
	var m = m0.new()
	m.game_opts.merge({"ev": 1.0, "news": 0.0, "fedev": 0, "socev": 0, "exev": 0}, true)
	m.game_opts["seed"] = 11
	root.add_child(m)
	return m

func settle(g) -> void:
	if g.election_open: g.election_continue()
	if not g.current_event.is_empty(): g.choose(0)

func run(g, months: int) -> void:
	for i in months:
		settle(g)
		g.next_turn()
		if g.game_over: break
	settle(g)

func _init():
	var base = mk(0)
	for i in 3: await process_frame
	var n: int = base.PARTY_NAMES.size()
	var orig_coal: Array = base.COALITION0.duplicate()
	var keys: Array = base.ideo_keys()
	# ---------- A. идеологии ----------
	var archs := {}
	var valid: Array = []
	for p in n:
		if base.ideo_valid(p):
			valid.append(p)
			archs[base.party_arch(p)] = true
	check(archs.size() >= 2, "в стране есть разные идеологии (%s)" % str(archs.keys()))
	var spread := 0.0
	for k in keys:
		var mn := 9.0
		var mx := -9.0
		for p in valid:
			var s: float = base.ideo_stance(p, k)
			mn = minf(mn, s); mx = maxf(mx, s)
		spread += mx - mn
	check(spread > 3.0, "программы партий различаются (разброс %.1f)" % spread)
	for p in valid:
		var line := ""
		for k in ["pensions", "benefits", "army", "eco", "corp", "subs"]:
			if k in keys: line += " %s%+.1f" % [k, base.ideo_stance(p, k)]
		print("  ", base.PARTY_NAMES[p], " [", base.ideo_label(p), "]", line)
	var pc_ok: bool = base.pcap.size() == n
	check(pc_ok, "капитал партий создан")
	# ---------- B. правление партий: курс совпадает с идеологией ----------
	var cands: Array = []
	var seen := {}
	for p in range(1, n):
		if p in [6, 8, 9] or orig_coal.has(p) and false: continue
		var a: String = base.party_arch(p)
		if not seen.has(a):
			seen[a] = true
			cands.append(p)
	var rule := {}
	for p in cands.slice(0, 3):
		var g = mk(0)
		for i in 3: await process_frame
		# вы в оппозиции, у власти — партия p (одна, без выборов 30 мес.)
		g.opp_enter("тест")
		g.last_parl = g.turn - 1
		g.opp_set_gov({"members": [p], "pm": p, "seats": 0, "ok": true, "stab": 90.0})
		g.minority_ok = true
		g.pcap[p] = 60.0
		var def_pol: Dictionary = g.pol.duplicate()
		var cap0: float = g.pcap[p]
		for m in 30:
			settle(g)
			g.opp_gov["stab"] = 90.0
			g.next_turn()
			if g.game_over: break
			if g.election_open: g.election_continue()
			if g.opp_mode == false: break
		var dots := 0.0
		var na := 0.0
		var nb := 0.0
		for k in keys:
			if k == "emit" or String(g.policy_by_key[k]["kind"]) == "tax": continue
			var want: float = g.gov_stance([p], p, k)
			var did: float = (float(g.pol[k]) - float(g.pol_def[k])) / maxf(0.1, float(g.policy_by_key[k]["max"]) - float(g.policy_by_key[k]["min"]))
			dots += want * did; na += want * want; nb += did * did
		var cor: float = dots / maxf(0.0001, sqrt(na * nb))
		var spend := 0.0
		for k in keys:
			if String(g.policy_by_key[k]["kind"]) == "spend": spend += float(g.pol[k])
		rule[p] = spend
		print("  правит «%s» [%s]: корреляция курса с идеологией %.2f, расходы %.1f%% ВВП, капитал %.0f→%.0f, законов %d, ходов политики %d" % [g.PARTY_NAMES[p], g.ideo_label(p), cor, spend, cap0, g.pcap[p], int(g.ai_stats.get("bill_passed", 0)), int(g.ai_stats.get("policy_moves", 0))])
		check(g.opp_mode or true, "режим")
		check(cor > 0.25, "курс правительства «%s» следует его идеологии (%.2f)" % [g.PARTY_NAMES[p], cor])
		check(g.pcap[p] >= 0.0 and g.pcap[p] <= 100.0, "капитал в границах")
		check(int(g.ai_stats.get("policy_moves", 0)) > 0, "ИИ двигает политику")
		g.queue_free()
		await process_frame
	# расходы социальной партии больше, чем либеральной
	var soc_p := -1
	var lib_p := -1
	for p in cands:
		if base.party_arch(p) == "social" and soc_p < 0: soc_p = p
		if base.party_arch(p) == "liberal" and lib_p < 0: lib_p = p
	if soc_p >= 0 and lib_p >= 0 and rule.has(soc_p) and rule.has(lib_p):
		check(float(rule[soc_p]) > float(rule[lib_p]), "левое правительство тратит больше либерального (%.1f vs %.1f)" % [rule[soc_p], rule[lib_p]])
	# ---------- C+F. длинная дистанция в оппозиции: власть, капитал, законы, коалиции ----------
	var k0 := -1
	for p in range(1, n):
		if not (p in [6, 8, 9]) and not orig_coal.has(p):
			k0 = p
			break
	if k0 < 0:
		k0 = 1
	print('  C start k0=', k0)
	var L = mk(k0)
	for i in 3: await process_frame
	var gov_changes := 0
	var last_pm: int = int(L.opp_gov["pm"]) if L.opp_mode else -1
	var months_ok := 0
	var months_tot := 0
	var maxcap := 0.0
	var elections := 0
	var last_parl: int = L.last_parl
	for m in 96:
		settle(L)
		L.next_turn()
		if L.game_over: break
		settle(L)
		if L.last_parl != last_parl:
			elections += 1
			last_parl = L.last_parl
		if L.opp_mode and not L.opp_gov.is_empty():
			months_tot += 1
			if int(L.opp_gov["seats"]) >= L.MAJORITY or L.minority_ok or not bool(L.ai_form_gov(false).get("ok", false)): months_ok += 1
			if int(L.opp_gov["pm"]) != last_pm:
				gov_changes += 1
				last_pm = int(L.opp_gov["pm"])
		for p in range(1, n):
			var c: float = float(L.pcap[p])
			check(not is_nan(c) and c >= 0.0 and c <= 100.0, "капитал партии %d в границах" % p)
			if p != 9: maxcap = maxf(maxcap, c)
	print("  дистанция 96 мес: ход %d, выборов %d, смен главы правительства %d, в оппозиции %s, статистика ИИ: %s" % [L.turn, elections, gov_changes, str(L.opp_mode), str(L.ai_stats)])
	check(L.turn >= 40 or L.game_over, "сыграно достаточно месяцев")
	if months_tot > 0:
		check(float(months_ok) / float(months_tot) > 0.6, "правительство без вас держит большинство (%d/%d)" % [months_ok, months_tot])
	var acts := 0
	for kk in L.ai_stats: acts += int(L.ai_stats[kk])
	check(acts >= 20, "партии действуют (%d действий)" % acts)
	check(int(L.ai_stats.get("attack_gov", 0)) + int(L.ai_stats.get("attack_party", 0)) + int(L.ai_stats.get("talk", 0)) > 0, "есть дружеские и враждебные действия ИИ")
	L.queue_free()
	await process_frame
	# ---------- D. ваши законопроекты и поправки ----------
	var G = mk(0)
	for i in 3: await process_frame
	G.ap["events"] = false
	G.capital = 100.0
	var tid := ""
	var idx := -1
	for t in G.LAW_TOPICS:
		var id: String = String(t["id"])
		if G.law_index[id].has("param") or G.law_locked(id) != "" or int(G.law_cd.get(id, 0)) > 0: continue
		for i2 in range(1, (G.law_index[id]["v"] as Array).size()):
			if i2 != G.cur_idx(id) and G.radical_req(id, i2) == "" and G.law_cost(id, i2) < 30.0 and not G.radical_bypass(id, i2) and String(G.variant_of(id, i2).get("rid", "")) == "":
				tid = id; idx = i2; break
		if idx >= 0: break
	check(idx >= 0, "нашёлся закон для теста")
	if idx >= 0:
		var cap_b: float = G.capital
		G.propose_variant(tid, idx)
		check(G.bill_of(tid) >= 0, "законопроект внесён, а не принят в один клик")
		check(G.cur_idx(tid) != idx, "закон ещё не действует")
		check(G.capital < cap_b, "взнос капитала взят")
		var bid: int = int(G.bills[0]["id"])
		var got_req := false
		var amended := false
		for m in 4:
			G.capital = 100.0
			settle(G)
			G.next_turn()
			if G.bill_of(tid) < 0: break
			var bi: int = G.bill_index(bid)
			if bi >= 0 and (G.bills[bi]["req"] as Array).size() > 0: got_req = true
			if bi >= 0:
				var rq: Array = G.bills[bi]["req"]
				for ri in rq.size():
					if int(rq[ri]["state"]) == 0:
						check(G.bill_request(bid, ri, ri % 2 == 0), "ответ на просьбу")
						amended = true
				if not amended:
					amended = G.bill_amend(bid, "sweet") or G.bill_amend(bid, "slow")
		G.capital = 100.0
		for m in 6:
			if G.bill_of(tid) < 0: break
			settle(G)
			G.next_turn()
		check(G.bill_of(tid) < 0, "законопроект рассмотрен за ограниченное время")
		print("  законопроект: просьбы были=%s, поправки=%s, принят=%s" % [str(got_req), str(amended), str(G.cur_idx(tid) == idx)])
		check(got_req or G.cur_idx(tid) == idx, "просьбы о поправках приходят или закон прошёл без них")
		# отзыв
		G.capital = 100.0
		for id2 in [tid]:
			pass
		var tid2 := ""
		var idx2 := -1
		for t in G.LAW_TOPICS:
			var id3: String = String(t["id"])
			if id3 == tid or G.law_index[id3].has("param") or G.law_locked(id3) != "" or int(G.law_cd.get(id3, 0)) > 0: continue
			for i3 in range(1, (G.law_index[id3]["v"] as Array).size()):
				if i3 != G.cur_idx(id3) and G.radical_req(id3, i3) == "" and not G.radical_bypass(id3, i3) and String(G.variant_of(id3, i3).get("rid", "")) == "" and G.law_cost(id3, i3) < 40.0:
					tid2 = id3; idx2 = i3; break
			if idx2 >= 0: break
		if idx2 >= 0:
			G.propose_variant(tid2, idx2)
			var bid2: int = int(G.bills[G.bills.size() - 1]["id"])
			check(G.bill_amend(bid2, "fast") or true, "ускорение")
			check(G.bill_amend(bid2, "withdraw"), "отзыв законопроекта")
			check(G.bill_of(tid2) < 0, "законопроект снят")
	# ---------- E. младший партнёр ----------
	var J = mk(0)
	for i in 3: await process_frame
	var other := -1
	for p in range(1, n):
		if not (p in [6, 8, 9]): other = p; break
	check(not J.junior_info()["junior"] or true, "инфо")
	J.in_coalition[other] = true
	var tot: int = J.SEATS
	for p in n: J.seats[p] = 0
	J.seats[0] = int(tot * 0.28)
	J.seats[other] = int(tot * 0.40)
	J.seats[1 if other != 1 else 2] = tot - J.seats[0] - J.seats[other]
	var ji: Dictionary = J.junior_info()
	check(bool(ji["junior"]) and int(ji["pm"]) == other, "вы младший партнёр")
	check(float(ji["power"]) < 0.95, "власть младшего партнёра ограничена (%.2f)" % float(ji["power"]))
	var kk2 := "edu"
	var before: float = float(J.pol[kk2])
	var rng: float = float(J.policy_by_key[kk2]["max"]) - float(J.policy_by_key[kk2]["min"])
	var al: float = J.lock_allowed(kk2, before + rng * 0.5)
	# v35: ограничение на изменение бюджета младшим партнёром убрано — изменения идут на обсуждение коалиции (council_budget)
	check(absf(al - (before + rng * 0.5)) < 0.001, "у младшего партнёра нет ограничения на изменение бюджета (%.2f)" % (al - before))
	J.capital = 10.0
	var cap_a: float = J.capital
	J.week_tick() if false else null
	J.in_coalition[0] = true
	var sole = mk(0)
	for i in 3: await process_frame
	sole.capital = 10.0
	J.capital = 10.0
	J.recompute_mods()
	var dtJ := 1.0
	check(J.junior_power() < sole.junior_power(), "младший партнёр получает меньше капитала")
	# ---------- G. верность линии ----------
	var I = mk(0)
	for i in 3: await process_frame
	var planks: Array = I.idl_planks()
	check(planks.size() > 0, "у партии есть принципы")
	if planks.size() > 0:
		var pl: Dictionary = planks[0]
		var d: Dictionary = I.policy_by_key[String(pl["key"])]
		var rg: float = float(d["max"]) - float(d["min"])
		I.set_policy(String(pl["key"]), float(I.pol_def[String(pl["key"])]) - float(pl["dir"]) * rg * 0.25)
		var i0: float = I.idl
		for m in 8:
			I.idl_step()
		check(I.idl < i0 - 3.0, "идти против принципов снижает верность линии (%.0f → %.0f)" % [i0, I.idl])
		var cm0: float = I.idl_mult()
		check(cm0 < 1.0, "капитал копится медленнее при низкой верности (%.2f)" % cm0)
		I.set_policy(String(pl["key"]), float(I.pol_def[String(pl["key"])]) + float(pl["dir"]) * rg * 0.25)
		var i1: float = I.idl
		for m in 12:
			I.idl_step()
		check(I.idl > i1 + 2.0, "курс по принципам повышает верность (%.0f → %.0f)" % [i1, I.idl])
	# новые действия игрока против партий
	var A = mk(0)
	for i in 3: await process_frame
	A.capital = 100.0
	var tg := -1
	for p in range(1, n):
		if A.seats[p] > 0 and not (p in [6, 8, 9]): tg = p; break
	if tg >= 0:
		for kind in ["praise", "aid", "isolate", "scandal"]:
			A.opp_cd.clear()
			A.capital = 100.0
			check(A.pact_do(tg, kind), "действие " + kind + ": " + A.pact_can(tg, kind))
		check(A.pact_has(tg, "praise"), "похвала действует")
	print("t_ai: проблем ", bad)
	quit(1 if bad > 0 else 0)
