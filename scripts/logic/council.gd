# Совет коалиции (v35): партнёры голосуют по событиям, кабинету, бюджету и приёму новых партий;
# выход из затяжного правительственного кризиса.
extends "res://scripts/logic/aiparty.gd"

const COUNCIL_TOL := 0.6        # насколько вариант может быть хуже любимого, чтобы партнёр всё же поддержал выбор игрока


# члены правительства (включая вашу партию)
func coal_members() -> Array:
	var out: Array = []
	for p in PARTY_NAMES.size():
		if in_coalition[p] and seats[p] > 0:
			out.append(p)
	return out


# влияние в коалиции: доля мест партии среди мест коалиции
func coal_share(p: int) -> float:
	return float(seats[p]) / float(maxi(1, gov_seats()))


func council_on() -> bool:
	return not opp_mode and not game_over and in_coalition[0] and coal_members().size() >= 2 and not decree_power()


# ---------- события ----------
func fx_utility(p: int, fx: Dictionary) -> float:
	var sup := {}
	if fx.has("support"):
		for g in fx["support"]:
			sup[g] = float(fx["support"][g])
	if fx.has("all"):
		for g in GROUPS:
			sup[g] = float(sup.get(g, 0.0)) + float(fx["all"])
	var u := party_stance(p, sup) if sup.size() > 0 else 0.0
	u += float(fx.get("capital", 0.0)) * coal_share(p) * 0.3
	u += float(fx.get("coal_sat", 0.0)) * 0.3
	u -= float(fx.get("debt", 0.0)) * 0.5
	if fx.has("slider"):
		for k in fx["slider"]:
			if policy_by_key.has(k):
				var d: Dictionary = policy_by_key[k]
				u += ideo_stance(p, k) * float(fx["slider"][k]) / maxf(0.01, float(d["max"]) - float(d["min"])) * 8.0
	return u


# кто из партнёров готов поддержать вариант i (его польза не хуже любимого варианта более чем на COUNCIL_TOL)
func council_backers(i: int) -> Array:
	var opts: Array = current_event["o"]
	var out: Array = []
	for p in coal_members():
		if p == 0:
			continue
		var best := -INF
		for o in opts:
			best = maxf(best, fx_utility(p, o["fx"]))
		if fx_utility(p, opts[i]["fx"]) >= best - COUNCIL_TOL:
			out.append(p)
	return out


func council_fav(p: int) -> int:
	var opts: Array = current_event["o"]
	var bi := 0
	var bu := -INF
	for i in opts.size():
		var u := fx_utility(p, opts[i]["fx"])
		if u > bu:
			bu = u
			bi = i
	return bi


func council_event_ok() -> bool:
	return council_on() and String(current_event.get("special", "")) == "" and event_party <= 0


# голосование совета: возвращает итоговый вариант
func council_event(pick: int) -> int:
	var opts: Array = current_event["o"]
	var tally := {}
	var lines: PackedStringArray = []
	var back := council_backers(pick)
	for p in coal_members():
		var c := pick if (p == 0 or p in back) else council_fav(p)
		tally[c] = float(tally.get(c, 0.0)) + coal_share(p)
		if p != 0:
			lines.append("%s — %s" % [PARTY_NAMES[p], "за ваш вариант" if c == pick else "за «%s»" % coal_text(String(opts[c]["l"]))])
	var win := pick
	for c in tally:
		if float(tally[c]) > float(tally.get(win, 0.0)) + 0.0001:
			win = int(c)
	var txt := "совет коалиции (%s): %s." % ["ваш голос %.0f%%" % (coal_share(0) * 100.0), "; ".join(lines)]
	if win != pick:
		txt += " [color=%s]Большинство коалиции выбрало другой вариант.[/color]" % COL_WARN
	log_tag("КОАЛИЦИЯ", COL_PURPLE, txt)
	return win


# затраты капитала делятся по влиянию в коалиции: вы платите свою долю, партнёры — из своего капитала
func council_split(fx: Dictionary) -> Dictionary:
	var cap: float = float(fx.get("capital", 0.0))
	if cap >= 0.0:
		return fx
	var out := fx.duplicate(true)
	out["capital"] = cap * coal_share(0)
	var parts: PackedStringArray = []
	for p in coal_members():
		if p == 0:
			continue
		var pay: float = -cap * coal_share(p)
		if pcap.size() > p:
			pcap[p] = maxf(0.0, float(pcap[p]) - pay)
		parts.append("%s −%.1f" % [PARTY_NAMES[p], pay])
	log_tag("КОАЛИЦИЯ", COL_DIM, "затраты политкапитала разделены по влиянию: вы −%.1f; %s." % [-float(out["capital"]), ", ".join(parts)])
	return out


func council_event_note(i: int) -> String:
	if not council_event_ok():
		return ""
	var back := council_backers(i)
	var share := coal_share(0)
	var names: PackedStringArray = []
	for p in back:
		share += coal_share(p)
		names.append(PARTY_NAMES[p])
	var t := "Совет коалиции: %s — %.0f%% влияния" % [("вы и " + ", ".join(names)) if names.size() > 0 else "только вы", share * 100.0]
	t += " (пройдёт)" if share > 0.5 else " [color=%s](не хватит большинства)[/color]" % COL_WARN
	var cap: float = float((current_event["o"][i]["fx"] as Dictionary).get("capital", 0.0))
	if cap < 0.0:
		t += ". Ваша доля затрат: %.1f из %.0f" % [-cap * coal_share(0), -cap]
	return t


# ---------- кабинет ----------
# голос партнёра q за передачу министерства m партии p (old — прежний держатель)
func council_min_yes(q: int, m: int, p: int, old: int) -> bool:
	if q == 0:
		return true
	if q == p:
		return true
	if q == old:
		return false
	if m in (PARTY_MINISTRIES[q] as Array):
		return false
	return rel(q, p) >= 40.0


func council_min_vote(m: int, p: int, old: int) -> Dictionary:
	var yes := 0.0
	var no_names: PackedStringArray = []
	for q in coal_members():
		if council_min_yes(q, m, p, old):
			yes += coal_share(q)
		else:
			no_names.append(PARTY_NAMES[q])
	return {"ok": yes > 0.5, "yes": yes, "no": no_names}


# ---------- бюджет (младший партнёр) ----------
func council_budget() -> void:
	if not council_on() or not bool(junior_info()["junior"]):
		return
	var ok_parts: PackedStringArray = []
	var bad_parts: PackedStringArray = []
	for d in POLICY:
		var k: String = d["key"]
		var dv: float = float(pol[k]) - float(prev_pol.get(k, pol[k]))
		if absf(dv) < 0.05:
			continue
		var yes := coal_share(0)
		var against: PackedStringArray = []
		for q in coal_members():
			if q == 0:
				continue
			if ideo_stance(q, k) * signf(dv) > -0.2:
				yes += coal_share(q)
			else:
				against.append(PARTY_NAMES[q])
		var title := "«%s» %.1f → %.1f" % [d["title"], float(prev_pol[k]), float(pol[k])]
		if yes > 0.5:
			ok_parts.append(title)
		else:
			bad_parts.append("%s (против: %s)" % [title, ", ".join(against)])
			var old: float = pol[k]
			set_policy(k, float(prev_pol[k]))
			if absf(float(pol[k]) - old) < 0.001:
				continue
	if ok_parts.size() > 0:
		log_tag("КОАЛИЦИЯ", COL_GOOD, "совет коалиции одобрил изменения бюджета: %s." % "; ".join(ok_parts))
	if bad_parts.size() > 0:
		log_tag("КОАЛИЦИЯ", COL_BAD, "совет коалиции отклонил изменения бюджета, они отменены: %s." % "; ".join(bad_parts))


# ---------- приглашение в коалицию ----------
func invite_offer_w(p: int, promise: bool, mins: int) -> float:
	return willingness(p, promise) + 6.0 * float(mins)


# согласие нынешних партнёров принять партию p
func council_invite_vote(p: int) -> Dictionary:
	var yes := 0.0
	var no_names: PackedStringArray = []
	for q in coal_members():
		var ok: bool = q == 0 or rel(q, p) >= (45.0 if is_cordon(p) else 30.0)
		if ok:
			yes += coal_share(q)
		else:
			no_names.append(PARTY_NAMES[q])
	return {"ok": yes > 0.5, "yes": yes, "no": no_names}


# ---------- выход из кризиса ----------
# лучшая партия для правительства меньшинства (её терпимость снимает угрозу вотума)
func crisis_tol_pick() -> int:
	var best := -1
	var bw := -INF
	for p in range(1, PARTY_NAMES.size()):
		if not can_govern(p) or in_coalition[p] or seats[p] <= 0:
			continue
		var against := 0
		for q in range(1, PARTY_NAMES.size()):
			if q != p and not in_coalition[q] and not tolerates(q):
				against += seats[q]
		if against >= MAJORITY:
			continue
		var w := willingness(p, true)
		if w > bw:
			bw = w
			best = p
	return best


# партнёр для «большой коалиции»: с ним набирается большинство
func crisis_grand_pick() -> int:
	var best := -1
	var bw := -INF
	for p in range(1, PARTY_NAMES.size()):
		if not can_govern(p) or in_coalition[p] or seats[p] <= 0:
			continue
		if gov_seats() + seats[p] < MAJORITY:
			continue
		var w := willingness(p, true) + float(seats[p]) / float(SEATS) * 10.0
		if w > bw:
			bw = w
			best = p
	return best


func show_crisis_exit() -> bool:
	if not current_event.is_empty() or election_open:
		return false
	crisis_offered = true
	var opts: Array = []
	var gp := crisis_grand_pick()
	if gp > 0:
		opts.append({"l": "Большая коалиция с «%s»: щедрые уступки и министерства (капитал −8)" % PARTY_NAMES[gp], "fx": {"capital": -8.0, "all": -0.5}, "crisis": "grand", "p": gp})
	var tp := crisis_tol_pick()
	if tp > 0:
		opts.append({"l": "Правительство меньшинства: «%s» обещает не голосовать против (капитал −5)" % PARTY_NAMES[tp], "fx": {"capital": -5.0}, "crisis": "tol", "p": tp})
	opts.append({"l": "Техническое правительство экспертов до следующих выборов: стабильность, но меньше капитала", "fx": {"all": -1.0}, "crisis": "techno", "p": -1})
	opts.append({"l": "Распустить парламент: новые выборы", "fx": {}, "crisis": "elect", "p": -1})
	var t := "Правительственный кризис затянулся: за %d мес. так и не собрано большинство (у коалиции %d мест из %d, нужно %d)." % [crisis_months, gov_seats(), SEATS, MAJORITY]
	if deadlock > 0:
		t += " Это уже %d-е подряд выборы без правительства — партии устали от тупика и стали сговорчивее." % (deadlock + 1)
	t += " Как выйти из кризиса?"
	current_event = {"t": t, "special": "crisis", "o": opts}
	event_region = -1
	event_party = -1
	event_min = -1
	present_event()
	return true


func resolve_crisis(opt: Dictionary) -> void:
	var kind: String = String(opt.get("crisis", "elect"))
	var p: int = int(opt.get("p", -1))
	match kind:
		"grand":
			add_member(p)
			extra_mins[p] = 1
			grant_ministries(p)
			conc[p] = float(conc.get(p, 0.0)) + 12.0
			add_commitment(p)
			log_tag("КОАЛИЦИЯ", COL_GOOD, "большая коалиция: «%s» входит в правительство в обмен на министерства и уступки. У правительства %d мест." % [PARTY_NAMES[p], gov_seats()])
		"tol":
			minority_gov = true
			if not pacts.has(p):
				pacts[p] = {}
			pacts[p]["tol"] = parl_term() - (turn - last_parl)
			prel[p] = clampf(float(prel[p]) + 5.0, 0.0, 100.0)
			log_tag("КОАЛИЦИЯ", COL_GOOD, "правительство меньшинства: «%s» обязуется не поддерживать вотум недоверия до следующих выборов." % PARTY_NAMES[p])
		"techno":
			techno_until = last_parl + parl_term()
			log_tag("КОАЛИЦИЯ", COL_WARN, "сформировано техническое правительство экспертов до %s. Политкапитал растёт вдвое медленнее." % date_after(techno_until - turn))
		_:
			deadlock += 1
			crisis_offered = false
			hold_parliament("правительство не получило поддержки парламента")
			return
	crisis_months = 0
	crisis_offered = false
	deadlock = 0
	recompute_mods()


# короткое имя партии для подписей: аббревиатура в скобках или начало названия
func party_abbr(p: int) -> String:
	var n: String = String(PARTY_NAMES[p])
	var a := n.rfind("(")
	var b := n.rfind(")")
	if a >= 0 and b > a + 1 and b - a <= 26:
		return n.substr(a + 1, b - a - 1)
	return n if n.length() <= 22 else n.substr(0, 20) + "…"
