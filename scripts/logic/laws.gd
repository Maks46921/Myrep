# Законы: варианты, голосование, числовые законы, меры и действия.
extends "res://scripts/logic/policy.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func hold_parliament(reason: String) -> void:
	pass


func junior_info() -> Dictionary:
	return {}


func law_locked(tid: String) -> String:
	return ""


func log_line(s: String) -> void:
	pass


func log_tag(tag: String, col: String, text: String) -> void:
	pass


func national_shares(pres: bool, only: Array = []) -> Array[float]:
	var r: Array[float] = []
	return r


func pact_has(p: int, kind: String) -> bool:
	return false


func party_stance(p: int, sup: Dictionary) -> float:
	return 0.0


func propose_variant(tid: String, idx: int, forced: Array = []) -> void:
	pass


func radical_bypass(tid: String, idx: int) -> bool:
	return false


func radical_enact(tid: String, idx: int, old_rid: String) -> void:
	pass


func radical_req(tid: String, idx: int) -> String:
	return ""


func refresh() -> void:
	pass


func rid_of(tid: String) -> String:
	return ""


# --- конец заглушек ---


func do_measure(id: String) -> void:
	if game_over or int(cooldown.get(id, 0)) > 0:
		return
	var m := find_by_id(MEASURES, id)
	cooldown[id] = int(m["cd"])
	var eff := apply_fx(m["fx"])
	log_line("[b]%s: разовая мера «%s».[/b] Последствия: %s." % [date_text(), m["name"], eff])
	refresh()


func do_action(id: String) -> void:
	if game_over or int(cooldown.get(id, 0)) > 0:
		return
	var a := find_by_id(ACTIONS, id)
	if capital < float(a["cost"]):
		log_line("[color=%s]Не хватает политического капитала для действия «%s».[/color]" % [COL_BAD, a["name"]])
		return
	if id == "snap":
		var si: Dictionary = snap_info()
		if not bool(si["ok"]):
			log_line("[color=%s]%s[/color]" % [COL_BAD, String(si["why"])])
			return
		if turn - last_parl < 12:
			log_line("[color=%s]Парламент выбран меньше года назад: досрочные выборы пока невозможны.[/color]" % COL_BAD)
			return
		capital -= float(a["cost"])
		var need: float = float(si["need"])
		if need > 0.0:
			var yes: int = snap_votes()
			if float(yes) < need * float(SEATS):
				log_line("[color=%s]Роспуск парламента не набрал голосов: за %d, нужно %d (%s). Политкапитал потрачен.[/color]" % [COL_BAD, yes, ceili(need * float(SEATS)), String(si["vote"])])
				refresh()
				return
		hold_parliament("досрочные выборы по вашему решению")
		return
	capital -= float(a["cost"])
	cooldown[id] = int(a["cd"])
	var eff := apply_fx(a["fx"])
	log_line("[b]%s: действие «%s».[/b] Последствия: %s." % [date_text(), a["name"], eff])
	refresh()


func level_effects_text() -> String:
	var t := "[color=%s]Отклонение уровня от 50 даёт эффект каждый месяц.[/color]\n" % COL_DIM
	for d in LEVELS:
		var key: String = d["key"]
		var cur: float = float(lvl[key])
		var v: float = cur - 50.0
		var inv: bool = key == "corruption"
		t += "\n[b]%s[/b]  [b][color=#%s]%.0f[/color][/b]\n" % [d["title"], scale_color((1.0 - cur / 100.0) if inv else (cur / 100.0)).to_html(false), cur]
		var rule: PackedStringArray = []
		for it in level_effect_list(key, 1.0):
			rule.append("%s %s%s" % [it[0], sg(float(it[1]), int(it[2])), it[4]])
		t += "[font_size=12][color=%s]за каждый пункт выше 50: %s[/color][/font_size]\n" % [COL_DIM, " · ".join(rule)]
		var now: PackedStringArray = []
		for it in level_effect_list(key, v):
			var val: float = float(it[1])
			if absf(val) < 0.5 * pow(10.0, -int(it[2])):
				continue
			var good: bool = (val >= 0.0) == bool(it[3])
			now.append("%s [color=%s]%s%s[/color]" % [it[0], COL_GOOD if good else COL_BAD, sg(val, int(it[2])), it[4]])
		if now.size() > 0:
			t += "сейчас: %s\n" % " · ".join(now)
		else:
			t += "[color=%s]сейчас эффектов нет: уровень средний[/color]\n" % COL_FAINT_HEX
	t += "\n[i][color=%s]Состояние растёт от суммы денег на человека (в млрд, а не от доли ВВП). Стандарты общества растут на 2%% в год сами по себе, поэтому суммы нужно понемногу увеличивать.[/color][/i]" % COL_DIM
	return t


func fx_items(fx: Dictionary, rid: int = -1) -> Array:
	# [текст, 1 — плюс, -1 — минус, 0 — нейтрально]
	var out: Array = []
	if fx.has("dip"):
		for dc in fx["dip"]:
			if not DIP_C.has(dc):
				continue
			out.append(["отношения: %s %s" % [DIP_C[dc]["name"], sg(float(fx["dip"][dc]), 0)], 1 if float(fx["dip"][dc]) > 0.0 else -1])
	if fx.has("debt"):
		out.append(["долг %s%% ВВП" % sg(fx["debt"]), 1 if float(fx["debt"]) < 0.0 else -1])
	if fx.has("shock"):
		out.append(["рост ВВП %s п.п." % sg(fx["shock"]), 1 if float(fx["shock"]) > 0.0 else -1])
	if fx.has("infl"):
		out.append(["инфляция %s п.п." % sg(fx["infl"]), 1 if float(fx["infl"]) < 0.0 else -1])
	if fx.has("unemp"):
		out.append(["безработица %s п.п." % sg(fx["unemp"]), 1 if float(fx["unemp"]) < 0.0 else -1])
	if fx.has("other_rev"):
		out.append(["прочие доходы %s%% ВВП" % sg(fx["other_rev"]), 1 if float(fx["other_rev"]) > 0.0 else -1])
	if fx.has("slider"):
		for k in fx["slider"]:
			var dv: float = float(fx["slider"][k])
			var spend: bool = String(policy_by_key[k]["kind"]) == "spend"
			var good: bool = (dv < 0.0) if spend else (dv > 0.0)
			out.append(["«%s» %s п.п. ВВП" % [policy_title(k), sg(dv)], 1 if good else -1])
		out.append(["обязательство на %d мес.: откатить ползунок нельзя" % int(fx.get("lock_months", 12)), 0])
	if fx.has("state"):
		for k in fx["state"]:
			var dv2: float = float(fx["state"][k])
			var good2: bool = (dv2 < 0.0) if k == "corruption" else (dv2 > 0.0)
			out.append(["%s %s" % [STATE_NAMES[k], sg(dv2, 0)], 1 if good2 else -1])
	if fx.has("all"):
		out.append(["все группы %s" % sg(fx["all"], 0), 1 if float(fx["all"]) > 0.0 else -1])
	if fx.has("support"):
		for g in fx["support"]:
			out.append(["%s %s" % [g, sg(fx["support"][g], 0)], 1 if float(fx["support"][g]) > 0.0 else -1])
	if fx.has("capital"):
		out.append(["политкапитал %s" % sg(fx["capital"], 0), 1 if float(fx["capital"]) > 0.0 else -1])
	if fx.has("pcamp"):
		out.append(["шансы вашего кандидата %s" % sg(float(fx["pcamp"]) * 100.0, 0), 1 if float(fx["pcamp"]) > 0.0 else -1])
	if fx.has("reg") and rid >= 0:
		for k in fx["reg"]:
			out.append(reg_item(k, float(fx["reg"][k]), "региона"))
	if fx.has("reg_transfer") and rid >= 0:
		out.append(["трансферты региона %s п.п." % sg(fx["reg_transfer"]), -1])
	if fx.has("regall"):
		for k in fx["regall"]:
			out.append(reg_item(k, float(fx["regall"][k]), "во всех регионах"))
	if fx.has("sector"):
		for sk in fx["sector"]:
			out.append(["отрасль «%s»: %s" % [SECTOR_NAMES[sk], describe_reg(fx["sector"][sk])], 0])
	if rid >= 0:
		if fx.has("rsec"):
			for sk in fx["rsec"]:
				out.append(["%s региона %s%%" % [SECTOR_NAMES[sk], sg(float(fx["rsec"][sk]) * 100.0, 0)], 1 if float(fx["rsec"][sk]) > 0.0 else -1])
		if fx.has("rdebt"):
			out.append(["долг региона %s п.п. ВРП" % sg(fx["rdebt"], 0), 1 if float(fx["rdebt"]) < 0.0 else -1])
		if fx.has("rmig"):
			out.append(["приток населения %s на 1000" % sg(fx["rmig"], 1), 1 if float(fx["rmig"]) > 0.0 else -1])
		if fx.get("rzone_end", false):
			out.append(["зоны региона сворачиваются", 0])
	if fx.has("coal_sat"):
		out.append(["довольство партнёров %s" % sg(fx["coal_sat"], 0), 1 if float(fx["coal_sat"]) > 0.0 else -1])
	if fx.get("coal_demands", false):
		out.append(["выполнить требования партнёров", -1])
	if fx.has("psat") and event_party > 0:
		out.append(["довольство «%s» %s" % [PARTY_NAMES[event_party], sg(fx["psat"], 0)], 1 if float(fx["psat"]) > 0.0 else -1])
	if fx.has("psat_others"):
		out.append(["довольство остальных партнёров %s" % sg(fx["psat_others"], 0), 1 if float(fx["psat_others"]) > 0.0 else -1])
	if fx.has("psat_all"):
		out.append(["довольство всех партнёров %s" % sg(fx["psat_all"], 0), 1 if float(fx["psat_all"]) > 0.0 else -1])
	if fx.get("give_min", false) and event_min >= 0 and event_party > 0:
		out.append(["министерство «%s» переходит партии «%s»" % [MINISTRIES[event_min]["name"], PARTY_NAMES[event_party]], 0])
	if fx.get("dismiss_min", false) and event_min >= 0:
		out.append(["министр «%s» сменён" % MINISTRIES[event_min]["name"], 0])
	if fx.get("promise", false) and event_party > 0:
		out.append(["обещание закона-условия: срок 18 мес.", -1])
	return out


func reg_item(k: String, dv: float, where: String) -> Array:
	var txt: String
	if k == "dev":
		txt = "ВВП %s %s%%" % [where, sg(dv * 0.8, 1)]
	else:
		txt = "%s %s %s" % [REG_TITLES[k], where, sg(dv, 0)]
	var kind := 0
	if k == "autonomy":
		kind = 0
	elif k == "unrest":
		kind = 1 if dv < 0.0 else -1
	else:
		kind = 1 if dv > 0.0 else -1
	return [txt, kind]


func fx_pros_cons(fx: Dictionary, rid: int = -1) -> String:
	var pros: PackedStringArray = []
	var cons: PackedStringArray = []
	var neut: PackedStringArray = []
	for it in fx_items(fx, rid):
		var k: int = it[1]
		if k > 0:
			pros.append(it[0])
		elif k < 0:
			cons.append(it[0])
		else:
			neut.append(it[0])
	var t := ""
	if pros.size() > 0:
		t += "[color=%s]▲ %s[/color]" % [COL_GOOD, "     ▲ ".join(pros)]
	if cons.size() > 0:
		t += ("\n" if t != "" else "") + "[color=%s]▼ %s[/color]" % [COL_BAD, "     ▼ ".join(cons)]
	if neut.size() > 0:
		t += ("\n" if t != "" else "") + "[color=%s]◆ %s[/color]" % [COL_DIM, "     ◆ ".join(neut)]
	if t == "":
		t = "[color=%s]без прямых последствий[/color]" % COL_DIM
	return t


func layer_ramp() -> Array:
	match map_layer:
		0: return ["rg", "ниже", "выше"]
		1: return ["gr", "спокойно", "волнения"]
		2: return ["blue", "беднее", "богаче"]
		3: return ["blue", "мало", "много"]
		6: return ["blue", "меньше", "больше"]
		7: return ["blue", "меньше", "больше"]
		8: return ["gr", "ниже", "выше"]
		9, 10, 11, 12: return ["rg", "хуже", "лучше"]
		13: return ["blue", "меньше", "больше"]
		15: return ["rg", "спад", "рост"]
		16: return ["gr", "ниже", "выше"]
		17: return ["rg", "отток", "приток"]
		18: return ["blue", "нет", "много"]
		19: return ["blue", "меньше", "больше"]
		20, 21, 25: return ["rg", "хуже", "лучше"]
		22, 23, 24: return ["rg", "хуже", "лучше"]
		26: return ["blue", "меньше", "больше"]
		28: return ["gr", "спокойно", "напряжённо"]
	return ["none", "", ""]


func level_effect_list(key: String, v: float) -> Array:
	var fx: Dictionary = LEVEL_EFFECTS[key]
	var out: Array = []
	if fx.has("growth"):
		out.append(["рост ВВП", float(fx["growth"]) * v, 2, true, " п.п./год"])
	if fx.has("unemp"):
		out.append(["безработица", float(fx["unemp"]) * v, 2, false, " п.п."])
	if fx.has("reg_dev"):
		out.append(["выпуск регионов", float(fx["reg_dev"]) * v * 0.8, 2, true, "%"])
	if fx.has("reg_unrest"):
		out.append(["недовольство регионов", float(fx["reg_unrest"]) * v, 2, false, ""])
	if fx.has("tax_eff"):
		out.append(["сбор налогов", float(fx["tax_eff"]) * v * 100.0, 2, true, "%"])
	if key == "env_lvl":
		out.append(["здоровье нации", 0.1 * v, 2, true, ""])
	if fx.has("mood"):
		out.append(["настроение групп", float(fx["mood"]) * v, 2, true, ""])
	if fx.has("coal"):
		out.append(["довольство партнёров", float(fx["coal"]) * v, 2, true, ""])
	if fx.has("party"):
		var pct: float = (v if key == "corruption" else -v)
		out.append(["голоса «%s»" % PARTY_NAMES[int(fx["party"])], pct, 1, false, "%"])
	return out


# сменить только силу действия уже принятого варианта
func law_tweak(tid: String) -> bool:
	return is_hybrid(tid) and cur_idx(tid) > 0 and absf(pw_of(tid, true) - pw_of(tid)) > 0.01


func variant_of(tid: String, idx: int) -> Dictionary:
	return (law_index[tid]["v"] as Array)[idx]


func variant_part(tid: String, idx: int, key: String, cand: bool = false) -> Dictionary:
	var v := variant_of(tid, idx)
	var d: Dictionary = v.get(key, {})
	if idx > 0 and key in ["s", "st", "rg", "ps"] and is_hybrid(tid):
		return scale_dict(d, pw_of(tid, cand))
	return d


func cur_idx(tid: String) -> int:
	return int(law_state[tid])


func law_cost(tid: String, idx: int) -> float:
	if idx == 0:
		return 6.0
	var k := 0.6 + 0.4 * pw_of(tid, true)
	return float(variant_of(tid, idx)["c"]) * (1.3 if is_fund(tid) else 1.0) * k


func dict_diff(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := {}
	for k in b:
		var d: float = float(b[k]) - float(a.get(k, 0.0))
		if absf(d) > 0.0001:
			out[k] = d
	for k in a:
		if not b.has(k):
			out[k] = -float(a[k])
	return out


func support_delta(tid: String, idx: int) -> Dictionary:
	return dict_diff(variant_part(tid, cur_idx(tid), "s"), variant_part(tid, idx, "s", true))


func variant_stance(p: int, tid: String, idx: int) -> float:
	var cur := cur_idx(tid)
	var s := party_stance(p, support_delta(tid, idx))
	var pd := dict_diff(variant_part(tid, cur, "ps"), variant_part(tid, idx, "ps", true))
	s += float(pd.get(p, 0.0))
	if p == REGIONAL_P:
		var rgd := dict_diff(variant_part(tid, cur, "rg"), variant_part(tid, idx, "rg", true))
		s += float(rgd.get("autonomy", 0.0)) * 0.2
	return s


func variant_votes(tid: String, idx: int, forced: Array = []) -> Dictionary:
	var yes := 0
	var per: Array = []
	if radical_bypass(tid, idx):
		# решение принимается указом, но позиции партий показываем настоящие
		for p in PARTY_NAMES.size():
			if seats[p] > 0:
				var s0 := variant_stance(p, tid, idx)
				per.append([p, s0, p == vote_sponsor or s0 >= 0.0])
		return {"yes": SEATS, "no": 0, "per": per, "bypass": true}
	for p in PARTY_NAMES.size():
		if seats[p] == 0:
			continue
		var s := variant_stance(p, tid, idx)
		var ok: bool = p == vote_sponsor or s >= 0.0 or (in_coalition[p] and s >= -1.0) or (p in forced) or (s >= -3.0 and pact_has(p, "votes"))
		per.append([p, s, ok])
		if ok:
			yes += seats[p]
	return {"yes": yes, "no": SEATS - yes, "per": per}


func upper_check(tid: String, idx: int, forced: Array = []) -> Dictionary:
	var kind: String = String(UPPER.get("kind", "none"))
	if radical_bypass(tid, idx):
		return {"on": false, "block": false, "extra": 0.0}
	if UPPER.is_empty() or kind == "none" or int(UPPER.get("total", 0)) <= 0:
		return {"on": false, "block": false, "extra": 0.0}
	if kind == "veto":
		var vp: int = int(UPPER.get("veto_p", -1))
		var need60: int = int(ceil(float(SEATS) * float(UPPER.get("veto_frac", 0.6))))
		var lowyes: int = int(variant_votes(tid, idx, forced)["yes"])
		var pres_ok: bool = vp < 0 or vp in forced or variant_stance(vp, tid, idx) >= 0.0
		var okv: bool = pres_ok or lowyes >= need60
		return {"on": true, "yes": lowyes, "need": need60, "total": SEATS, "passed": okv, "kind": "veto", "name": String(UPPER["name"]), "block": not okv, "extra": 0.0, "binding": true, "pres_ok": pres_ok}
	var total: int = int(UPPER["total"])
	var need: int = total / 2 + 1
	if is_fund(tid):
		need = int(ceil(float(total) * float(UPPER.get("fund_need", 0.667))))
	var yes := 0
	var all_mode: bool = String(UPPER.get("mode", "")) == "all"
	var okp := {}
	for p in PARTY_NAMES.size():
		var s := variant_stance(p, tid, idx)
		okp[p] = p == 0 or s >= 0.0 or (in_coalition[p] and s >= -1.0) or (p in forced)
	for bl in UPPER["blocs"]:
		var ps: Array = bl[1]
		var n_ok := 0
		for p in ps:
			if bool(okp.get(int(p), false)):
				n_ok += 1
		var good: bool = (n_ok == ps.size()) if all_mode else (n_ok * 2 >= ps.size())
		if good:
			yes += int(bl[0])
	var passed: bool = yes >= need
	var binding := true
	if kind == "consent":
		binding = tid in (UPPER.get("consent", []) as Array)
	var res := {"on": true, "yes": yes, "need": need, "total": total, "passed": passed, "kind": kind, "name": String(UPPER["name"]), "block": false, "extra": 0.0, "binding": binding}
	if not passed:
		if kind == "full" or (kind == "consent" and binding):
			res["block"] = true
		else:
			res["extra"] = 5.0
	return res


func upper_text(up: Dictionary) -> String:
	if not bool(up.get("on", false)):
		return ""
	if String(up.get("kind", "")) == "veto":
		if bool(up.get("pres_ok", false)):
			return "Президент подпишет закон"
		if bool(up["passed"]):
			return "Президент наложит вето, но голосов хватает для преодоления: за %d, нужно %d" % [up["yes"], up["need"]]
		return "Президент наложит вето: за %d, чтобы преодолеть вето нужно %d" % [up["yes"], up["need"]]
	var t := "%s: за %d из %d, нужно %d" % [up["name"], up["yes"], up["total"], up["need"]]
	if bool(up["passed"]):
		return t + " — одобрит"
	if bool(up["block"]):
		return t + " — заблокирует закон"
	return t + " — отклонит, но нижняя палата преодолеет отказ (капитал +%.0f)" % float(up["extra"])


func negotiate_variant(tid: String, idx: int) -> void:
	if game_over or idx == cur_idx(tid):
		return
	var sw := variant_swing(tid, idx)
	if sw.is_empty() or capital < float(sw["cost"]) + law_cost(tid, idx):
		return
	capital -= float(sw["cost"])
	var names: PackedStringArray = []
	for p in sw["parties"]:
		names.append(PARTY_NAMES[p])
	log_tag("ПЕРЕГОВОРЫ", COL_PURPLE, "по закону «%s»: договорённости с %s (политкапитал -%.0f)." % [law_index[tid]["name"], ", ".join(names), sw["cost"]])
	propose_variant(tid, idx, sw["parties"])


func adopt_variant(tid: String, idx: int, forced: Array = []) -> void:
	if game_over or (idx == cur_idx(tid) and not law_tweak(tid)):
		return
	var topic: Dictionary = law_index[tid]
	if int(law_cd.get(tid, 0)) > 0:
		return
	var lk := law_locked(tid)
	if lk != "":
		log_line("[color=%s]Закон «%s» изменить нельзя: %s.[/color]" % [COL_BAD, topic["name"], lk])
		return
	var rq := radical_req(tid, idx)
	if rq != "":
		log_line("[color=%s]Закон «%s» не принят: %s[/color]" % [COL_BAD, topic["name"], rq])
		return
	var cost := law_cost(tid, idx) * cost_mult
	if capital < cost:
		return
	var jn: Dictionary = junior_info()
	if bool(jn["junior"]) and vote_sponsor == 0 and not (int(jn["pm"]) in forced) and variant_stance(int(jn["pm"]), tid, idx) < -0.8:
		log_line("[color=%s]Закон «%s» заблокирован: партия главы правительства «%s» против, а вы в коалиции младший партнёр.[/color]" % [COL_BAD, topic["name"], PARTY_NAMES[int(jn["pm"])]])
		refresh()
		return
	var v := variant_votes(tid, idx, forced)
	if int(v["yes"]) < law_need(tid):
		log_line("[color=%s]Закон «%s» не вынесен на голосование: нужно %d голосов, есть %d.[/color]" % [COL_BAD, topic["name"], law_need(tid), v["yes"]])
		refresh()
		return
	var upc := upper_check(tid, idx, forced)
	if bool(upc["block"]):
		log_line("[color=%s]Закон «%s» не прошёл: %s.[/color]" % [COL_BAD, topic["name"], upper_text(upc)])
		refresh()
		return
	cost += float(upc["extra"])
	if capital < cost:
		log_line("[color=%s]Для закона «%s» не хватает капитала: %s.[/color]" % [COL_BAD, topic["name"], upper_text(upc)])
		refresh()
		return
	var cur := cur_idx(tid)
	var old_v := variant_of(tid, cur)
	var new_v := variant_of(tid, idx)
	var sd := support_delta(tid, idx)
	var partner_stance: Dictionary = {}
	for p in range(1, PARTY_NAMES.size()):
		if in_coalition[p]:
			partner_stance[p] = variant_stance(p, tid, idx)
	capital -= cost
	var ksup := 1.0 if vote_sponsor == 0 else -0.6
	for g in sd:
		add_support(g, float(sd[g]) * ksup)
		bias[g] = float(bias[g]) + float(sd[g]) * 0.4 * ksup
	var std := dict_diff(variant_part(tid, cur, "st"), variant_part(tid, idx, "st", true))
	for k in std:
		lvl[k] = clampf(float(lvl[k]) + float(std[k]), 0.0, 100.0)
	var rgd := dict_diff(variant_part(tid, cur, "rg"), variant_part(tid, idx, "rg", true))
	if not rgd.is_empty():
		for i in regions.size():
			apply_reg_delta(i, rgd)
	var dd: float = float(new_v.get("debt", 0.0)) * (pw_of(tid, true) if idx > 0 else 1.0) - float(old_v.get("debt", 0.0)) * (pw_of(tid) if cur > 0 else 1.0)
	if absf(dd) > 0.0001:
		debt += gdp * dd / 100.0
	for p in partner_stance:
		var s: float = partner_stance[p]
		if s < -1.0:
			conc[p] = float(conc.get(p, 0.0)) - 8.0
		elif s > 1.0:
			conc[p] = float(conc.get(p, 0.0)) + 3.0
	var old_rid0 := rid_of(tid)
	law_state[tid] = idx
	if is_hybrid(tid):
		law_pow[tid] = pw_of(tid, true) if idx > 0 else 1.0
		law_pow_sel[tid] = float(law_pow[tid])
	law_cd[tid] = 24 if is_fund(tid) else 12
	radical_enact(tid, idx, old_rid0)
	recompute_mods()
	log_tag("ЗАКОН", COL_GOOD, "%s%s — «%s»: %s → [b]%s[/b] [color=%s](за %d, против %d; политкапитал -%.0f)[/color]. %s" % [
		date_text(), "" if vote_sponsor == 0 else " (правительство «%s»)" % PARTY_NAMES[vote_sponsor], topic["name"], old_v["n"], new_v["n"], COL_DIM, v["yes"], v["no"], cost, new_v["d"]])
	refresh()


func mod_item(key: String, old_v: Variant, new_v: Variant) -> Array:
	var info: Dictionary = MOD_INFO[key]
	var g: int = int(info["g"])
	var kind: String = info["k"]
	if kind == "mul":
		var pct: float = (float(new_v) / float(old_v) - 1.0) * 100.0
		var good: int = 0
		if g != 0:
			good = 1 if ((pct > 0.0) == (g > 0)) else -1
		return ["%s %s%%" % [info["t"], sg(pct, 0)], good]
	if kind == "add":
		var d: float = (float(new_v) - float(old_v)) * float(info.get("sc", 1.0))
		var good2: int = 0
		if g != 0:
			good2 = 1 if ((d > 0.0) == (g > 0)) else -1
		return ["%s %s%s" % [info["t"], sg(d, int(info["dg"])), info["u"]], good2]
	if key == "pres_rule":
		return ["%s: %s → %s" % [info["t"], PRES_RULE_NAMES[int(old_v)], PRES_RULE_NAMES[int(new_v)]], 0]
	var sc: float = float(info.get("sc", 1.0))
	return ["%s: %s%s → %s%s" % [info["t"], String.num(float(old_v) * sc, 0), info["u"], String.num(float(new_v) * sc, 0), info["u"]], 0]


func variant_effect_items(tid: String, idx: int) -> Array:
	var cur := cur_idx(tid)
	var items: Array = []
	var sd := support_delta(tid, idx)
	for g in GROUPS:
		if sd.has(g):
			items.append(["%s %s" % [g, sg(float(sd[g]), 0)], 1 if float(sd[g]) > 0.0 else -1])
	var st2: Dictionary = law_state.duplicate()
	st2[tid] = idx
	var m2 := compute_mods(st2, true, tid)
	for key in MOD_INFO:
		if absf(float(m2[key]) - float(mods[key])) > 0.00001:
			items.append(mod_item(key, mods[key], m2[key]))
	var std := dict_diff(variant_part(tid, cur, "st"), variant_part(tid, idx, "st", true))
	for k in std:
		var good: bool = (float(std[k]) < 0.0) == (k == "corruption")
		items.append(["%s %s" % [STATE_NAMES[k], sg(float(std[k]), 0)], 1 if good else -1])
	var rgd := dict_diff(variant_part(tid, cur, "rg"), variant_part(tid, idx, "rg", true))
	for k in rgd:
		items.append(reg_item(k, float(rgd[k]), "во всех регионах (разово)"))
	var dd: float = float(variant_of(tid, idx).get("debt", 0.0)) * (pw_of(tid, true) if idx > 0 else 1.0) - float(variant_of(tid, cur).get("debt", 0.0)) * (pw_of(tid) if cur > 0 else 1.0)
	if absf(dd) > 0.0001:
		items.append(["долг %s%% ВВП (разово)" % sg(dd), 1 if dd < 0.0 else -1])
	return items


func items_pros_cons(items: Array) -> String:
	var pros: PackedStringArray = []
	var cons: PackedStringArray = []
	var neut: PackedStringArray = []
	for it in items:
		var k: int = it[1]
		if k > 0:
			pros.append(it[0])
		elif k < 0:
			cons.append(it[0])
		else:
			neut.append(it[0])
	var t := ""
	if pros.size() > 0:
		t += "[color=%s]▲ %s[/color]" % [COL_GOOD, "   ▲ ".join(pros)]
	if cons.size() > 0:
		t += ("\n" if t != "" else "") + "[color=%s]▼ %s[/color]" % [COL_BAD, "   ▼ ".join(cons)]
	if neut.size() > 0:
		t += ("\n" if t != "" else "") + "[color=%s]◆ %s[/color]" % [COL_DIM, "   ◆ ".join(neut)]
	if t == "":
		t = "[color=%s]без прямых последствий[/color]" % COL_DIM
	return t


func pres_needs_runoff(s1: Array[float], order: Array) -> bool:
	var rule: int = int(mods["pres_rule"])
	if rule == 1:
		return false
	if rule == 2:
		return not (s1[order[0]] >= 0.40 and s1[order[0]] - s1[order[1]] >= 0.10)
	return s1[order[0]] <= 0.5


func law_reform_count(cat: int) -> int:
	var n := 0
	for t in LAW_TOPICS:
		if int(t["cat"]) == cat and cur_idx(t["id"]) > 0:
			n += 1
	return n


func law_demand_of(p: int) -> Dictionary:
	return PARTY_LAW_DEMAND[p]


func law_demand_met(p: int) -> bool:
	var d := law_demand_of(p)
	if d.is_empty():
		return true
	return demand_dict_met(d)


func law_demand_text(p: int) -> String:
	var d := law_demand_of(p)
	if d.is_empty():
		return ""
	if d.has("val"):
		var pf: String = String(law_index[d["tid"]]["param"]["fmt"])
		var vv: float = float(d["val"])
		return "«%s: %s %s»" % [law_index[d["tid"]]["name"], "не выше" if String(d.get("op", "ge")) == "le" else "не ниже", pf % (int(vv) if is_equal_approx(vv, roundf(vv)) else vv)]
	return "«%s» (%s)" % [variant_of(d["tid"], int(d["idx"]))["n"], law_index[d["tid"]]["name"]]


func fmt_param(p: Dictionary, v: float) -> String:
	var iv: Variant = int(roundf(v)) if is_equal_approx(v, roundf(v)) else v
	return String(p["fmt"]) % iv


func param_grid(p: Dictionary) -> Array:
	var lo: float = float(p["lo"])
	var hi: float = float(p["hi"])
	var fs: float = float(p["fs"])
	var ref: float = float(p["ref"])
	var n: int = int(roundf((hi - lo) / fs))
	var out: Array = []
	var has_ref := false
	for i in n + 1:
		var v: float = lo + fs * float(i)
		if is_equal_approx(v, ref):
			has_ref = true
		out.append(v)
	if not has_ref:
		out.append(ref)
		out.sort()
	return out


func make_param_topic(p: Dictionary) -> Dictionary:
	var ref: float = float(p["ref"])
	var step: float = float(p["step"])
	var grid_vals: Array = param_grid(p)
	var vars: Array = [{"n": "%s — действует" % fmt_param(p, ref), "d": "Нынешнее значение. Любой сдвиг от него меняет эффект тем сильнее, чем дальше значение.", "val": ref}]
	var grid: Array = []
	for vv in grid_vals:
		var v: float = float(vv)
		if is_equal_approx(v, ref):
			grid.append(0)
			continue
		var k: float = (v - ref) / step
		var one := {"n": fmt_param(p, v), "val": v, "c": float(p["c0"]) + float(p["ck"]) * absf(k)}
		one["d"] = "%s нынешнего значения (на %s)." % ["▲ Выше" if v > ref else "▼ Ниже", String.num(absf(v - ref), 1).trim_suffix(".0")]
		var s: Dictionary = {}
		for g in p.get("s", {}):
			s[g] = snappedf(float(p["s"][g]) * k, 0.1)
		if not s.is_empty():
			one["s"] = s
		var a: Dictionary = {}
		for key in p.get("a", {}):
			a[key] = float(p["a"][key]) * k
		if not a.is_empty():
			one["a"] = a
		var xx: Dictionary = {}
		for key in p.get("x", {}):
			xx[key] = maxf(0.2, 1.0 + float(p["x"][key]) * k)
		if not xx.is_empty():
			one["x"] = xx
		var st: Dictionary = {}
		for key in p.get("st", {}):
			st[key] = snappedf(float(p["st"][key]) * k, 0.1)
		if not st.is_empty():
			one["st"] = st
		vars.append(one)
		grid.append(vars.size() - 1)
	return {"id": p["id"], "cat": int(p["cat"]), "name": p["name"], "desc": p["desc"], "v": vars,
		"param": {"vals": grid_vals, "grid": grid, "ref": ref, "fmt": p["fmt"], "unit": p["unit"], "lo": float(grid_vals[0]), "hi": float(grid_vals[grid_vals.size() - 1])}}


func build_law_topics() -> Array:
	var LAW_PARAMS: Array = de_law_params()
	var pidx := {}
	for p in LAW_PARAMS:
		pidx[p["id"]] = p
	var out: Array = []
	var used := {}
	for t in LAW_TOPICS_BASE:
		if pidx.has(t["id"]):
			out.append(make_param_topic(pidx[t["id"]]))
			used[t["id"]] = true
		else:
			out.append((t as Dictionary).duplicate(true))
	var extra: Array = []
	for p in LAW_PARAMS:
		if not used.has(p["id"]):
			extra.append(make_param_topic(p))
	for t in NEW_TOPICS:
		extra.append((t as Dictionary).duplicate(true))
	# новые законы вставляем в конец своей сферы
	for t in extra:
		var at := out.size()
		for i in out.size():
			if int(out[i]["cat"]) > int(t["cat"]):
				at = i
				break
		out.insert(at, t)
	out = de_adapt_topics(out)
	for t in out:
		if t["id"] in FUND_IDS:
			t["fund"] = true
		if DEM_LAW.has(t["id"]):
			var tbl: Dictionary = DEM_LAW[t["id"]]
			for idx in tbl:
				if int(idx) >= (t["v"] as Array).size():
					continue
				var vv: Dictionary = (t["v"] as Array)[int(idx)]
				var a: Dictionary = (vv.get("a", {}) as Dictionary).duplicate()
				a["dem_shift"] = float(tbl[idx])
				vv["a"] = a
	return out


func is_fund(tid: String) -> bool:
	return bool(law_index[tid].get("fund", false))


func law_need(tid: String) -> int:
	return SUPER if is_fund(tid) else MAJORITY


func demand_idx(d: Dictionary) -> int:
	if d.has("idx"):
		return int(d["idx"])
	var vars: Array = law_index[d["tid"]]["v"]
	var best := 0
	var bd := 1e9
	for i in vars.size():
		var dv: float = absf(float(vars[i].get("val", 0.0)) - float(d["val"]))
		if dv < bd:
			bd = dv
			best = i
	return best


func demand_dict_met(d: Dictionary) -> bool:
	if d.has("val"):
		var cv: float = float(variant_of(d["tid"], cur_idx(d["tid"])).get("val", 0.0))
		if String(d.get("op", "ge")) == "le":
			return cv <= float(d["val"]) + 0.0001
		return cv >= float(d["val"]) - 0.0001
	return cur_idx(d["tid"]) == int(d["idx"])


func param_scale_text(tid: String) -> String:
	var topic: Dictionary = law_index[tid]
	if not topic.has("param"):
		return ""
	var pr: Dictionary = topic["param"]
	var cur: float = float(variant_of(tid, cur_idx(tid)).get("val", 0.0))
	return "[color=%s]Двигайте ползунок: диапазон %s … %s, сейчас [b]%s[/b]. Чем дальше значение от нынешнего, тем сильнее эффект — и выгоды, и издержки.[/color]" % [
		COL_DIM, fmt_param(pr, float(pr["lo"])), fmt_param(pr, float(pr["hi"])), fmt_param(pr, cur)]


func variant_swing(tid: String, idx: int) -> Dictionary:
	var need := law_need(tid)
	var v := variant_votes(tid, idx)
	if int(v["yes"]) >= need:
		return {}
	var cands: Array = []
	for it in v["per"]:
		var p: int = it[0]
		if bool(it[2]) or p == 0:
			continue
		if float(it[1]) >= -4.5:
			cands.append([seats[p], p])
	cands.sort_custom(func(a, b): return a[0] > b[0])
	var acc: int = v["yes"]
	var picked: Array = []
	for c in cands:
		picked.append(c[1])
		acc += int(c[0])
		if acc >= need:
			break
	if acc < need:
		return {}
	return {"parties": picked, "cost": (8.0 if is_fund(tid) else 6.0) * float(picked.size())}


# --- слияние с базовыми законами ---
func de_law_params() -> Array:
	var out: Array = []
	for p in LAW_PARAMS_V11:
		var id: String = p["id"]
		if id in DE_REMOVE:
			continue
		var q: Dictionary = (p as Dictionary).duplicate(true)
		if DE_PARAM.has(id):
			var o: Dictionary = DE_PARAM[id]
			for k in o:
				q[k] = o[k]
		out.append(q)
	for p in DE_NEW_PARAMS:
		out.append((p as Dictionary).duplicate(true))
	return out


func de_fix_ps(topics: Array) -> void:
	for t in topics:
		for v in (t["v"] as Array):
			if not v.has("ps"):
				continue
			var ps: Dictionary = (v["ps"] as Dictionary).duplicate()
			if t["id"] in ["debt_brake", "eu_policy", "citizenship_law", "rent_control", "auto_policy", "schengen"] or DE_OWN.has(t["id"]):
				v["ps"] = ps
				continue
			# старые слоты: 3 «Земля и порядок» -> Левые, 5 «Нац. союз» -> BSW, 6 -> Прочие
			if ps.has(1):
				ps[3] = float(ps[1]) * 1.1
			else:
				ps.erase(3)
			if ps.has(5) and ps.has(1):
				ps[5] = 0.5 * float(ps[5]) + 0.5 * float(ps[1])
			ps.erase(6)
			v["ps"] = ps


func de_adapt_topics(out: Array) -> Array:
	for t in DE_TOPICS:
		DE_OWN[t["id"]] = true
	var res: Array = []
	for t in out:
		if t["id"] in DE_REMOVE or DE_OWN.has(t["id"]):
			continue
		res.append(t)
	de_fix_ps(res)
	for t in DE_TOPICS:
		var tt: Dictionary = (t as Dictionary).duplicate(true)
		var at := res.size()
		for i in res.size():
			if int(res[i]["cat"]) > int(tt["cat"]):
				at = i
				break
		res.insert(at, tt)
	for t in res:
		if t["id"] in DE_FUND_ADD:
			t["fund"] = true
	return res


func brake_allowed() -> float:
	if ccode != "DE":
		return float(MACRO.get("fiscal_base", 3.0)) + float(mods["brake_room"])
	var allowed := 0.35 + maxf(0.0, float(pol["army"]) - 1.0) + float(mods["brake_room"])
	if fund_left > 0.0:
		allowed += 1.0
	return allowed


func brake_active() -> bool:
	return float(mods["brake_room"]) < 50.0


func brake_step(deficit_pct: float) -> void:
	if fund_left > 0.0:
		fund_left = maxf(0.0, fund_left - 0.010 * gdp / 12.0)
	if not brake_active():
		brake_over = 0
		return
	var over: float = deficit_pct - brake_allowed() - 0.5
	if over > 0.0:
		brake_over += 1
	else:
		brake_over = maxi(0, brake_over - 2)
	if ccode != "DE":
		var fname := String(MACRO.get("fiscal_name", "Правила ЕС"))
		var strict: bool = float(MACRO.get("fiscal_base", 3.0)) < 1.5
		if over > 0.0:
			risk_prem = minf(2.0 if not strict else 0.5, risk_prem + 0.03 * minf(over, 3.0))
		else:
			risk_prem = maxf(0.0, risk_prem - 0.05)
		if brake_over == 3:
			log_line("[color=%s][b]%s:[/b] дефицит %.1f%% ВВП выше допустимых %.1f%%. %s[/color]" % [COL_WARN, fname, deficit_pct, brake_allowed(), "Звучат предупреждения министерства финансов и суда." if strict else "Еврокомиссия предупреждает правительство, инвесторы требуют премию за риск."])
		elif brake_over >= 6:
			capital = maxf(0.0, capital - (0.8 if strict else 0.15))
			if brake_over % 6 == 0:
				log_line("[color=%s][b]Нарушение бюджетного правила (%s).[/b] Рынки и партнёры давят на правительство (политкапитал -%s в месяц, ставка по долгу выше).[/color]" % [COL_BAD, fname, "0.8" if strict else "0.15"])
			apply_fx({"support": {"Бизнес": -0.3 if not strict else -0.4}})
		return
	if brake_over == 3:
		log_line("[color=%s][b]Долговой тормоз:[/b] дефицит %.1f%% ВВП выше допустимых %.1f%%. Федеральное министерство финансов и Конституционный суд предупреждают правительство.[/color]" % [COL_WARN, deficit_pct, brake_allowed()])
	elif brake_over >= 6:
		capital = maxf(0.0, capital - 0.8)
		if brake_over % 6 == 0:
			log_line("[color=%s][b]Нарушение долгового тормоза.[/b] Суд требует сократить дефицит (политкапитал -0.8 в месяц, доверие рынков падает).[/color]" % COL_BAD)
		apply_fx({"support": {"Бизнес": -0.4, "Пенсионеры": -0.2}})


func brake_text() -> String:
	if ccode != "DE":
		var b0 := compute_budget()
		var dp: float = -float(b0["balance"]) / gdp * 100.0
		var col0 := COL_GOOD if dp <= brake_allowed() + 0.5 else COL_BAD
		return "\n[b]%s:[/b] допустимый дефицит ≈ [b]%.1f%%[/b] ВВП, сейчас [color=%s][b]%.1f%%[/b][/color]. Надбавка к ставке по долгу из-за недоверия рынков: %.2f п.п." % [String(MACRO.get("fiscal_name", "Правила ЕС")), brake_allowed(), col0, dp, risk_prem]
	var allowed := brake_allowed()
	var b := compute_budget()
	var def_pct: float = -float(b["balance"]) / gdp * 100.0
	if not brake_active():
		return "\n[color=%s]Долговой тормоз отменён. Спецфонд на инфраструктуру: осталось %.0f млрд €.[/color]" % [COL_DIM, fund_left]
	var col := COL_GOOD if def_pct <= allowed + 0.5 else COL_BAD
	return "\n[b]Долговой тормоз:[/b] допустимый дефицит ≈ [b]%.1f%%[/b] ВВП (0,35%% + оборона выше 1%% + спецфонд), сейчас [color=%s][b]%.1f%%[/b][/color]. Спецфонд: осталось %.0f из 500 млрд €." % [allowed, col, def_pct, fund_left]


# v35: досрочные выборы по стране: кто распускает парламент и нужно ли квалифицированное большинство.
# need — доля мест, которая должна проголосовать за самороспуск (0 — решает глава государства по просьбе правительства).
const SNAP_RULES := {
	"DE": ["Вопрос о доверии (досрочные выборы)", "Канцлер сознательно проигрывает вотум доверия, и федеральный президент распускает Бундестаг.", 0.0, ""],
	"FR": ["Роспуск Национального собрания", "Президент распускает Национальное собрание (не чаще раза в год) по просьбе правительства.", 0.0, ""],
	"NL": ["Роспуск Палаты представителей", "Король по предложению кабинета распускает Вторую палату и назначает выборы.", 0.0, ""],
	"BE": ["Досрочный роспуск палаты", "Роспуск возможен только после потери доверия: правительство проигрывает вотум, и король распускает палату.", 0.0, ""],
	"LU": ["Роспуск Палаты депутатов", "Великий герцог по предложению правительства распускает палату.", 0.0, ""],
	"CH": ["", "В Швейцарии нет досрочных выборов: Национальный совет избирается строго на 4 года, а Федеральный совет не уходит в отставку.", -1.0, ""],
	"AT": ["Самороспуск Национального совета", "Национальный совет распускается собственным решением большинством голосов.", 0.5, "нужно простое большинство"],
	"PL": ["Самороспуск Сейма", "Сейм может сократить свой срок только решением 2/3 депутатов.", 0.667, "нужно 2/3 Сейма"],
	"CZ": ["Самороспуск Палаты депутатов", "Палата может распустить себя решением 3/5 депутатов, после чего президент назначает выборы.", 0.6, "нужно 3/5 палаты"],
	"DK": ["Досрочные выборы", "Премьер-министр в любой момент назначает выборы в Фолькетинг.", 0.0, ""],
	"NO": ["", "Стортинг нельзя распустить: выборы проходят строго раз в 4 года.", -1.0, ""],
	"SE": ["Внеочередные выборы", "Правительство может назначить внеочередные выборы в Риксдаг (через 3 месяца после прошлых).", 0.0, ""],
	"IT": ["Досрочный роспуск парламента", "Президент республики распускает палаты, если правительство не может работать.", 0.0, ""],
	"ES": ["Роспуск Генеральных кортесов", "Председатель правительства предлагает королю распустить Кортесы.", 0.0, ""],
	"PT": ["Роспуск Ассамблеи республики", "Президент распускает Ассамблею после консультаций (не в первые 6 месяцев).", 0.0, ""],
	"GB": ["Досрочные всеобщие выборы", "Премьер-министр просит короля распустить парламент.", 0.0, ""],
	"IE": ["Роспуск Дойла", "Премьер (тишах) просит президента распустить Дойл.", 0.0, ""],
	"SI": ["Досрочные выборы в Государственное собрание", "Президент распускает собрание, если правительство проигрывает вотум доверия.", 0.0, ""],
	"SK": ["Сокращение срока Национального совета", "Национальный совет может сократить свой срок решением 3/5 депутатов.", 0.6, "нужно 3/5 совета"],
	"HU": ["Самороспуск Государственного собрания", "Собрание может распустить себя большинством голосов депутатов.", 0.5, "нужно большинство собрания"],
	"FI": ["Досрочные выборы в эдускунту", "Президент по предложению премьер-министра назначает досрочные выборы.", 0.0, ""],
}


func snap_info() -> Dictionary:
	var r: Array = SNAP_RULES.get(ccode, SNAP_RULES["DE"])
	var ok: bool = float(r[2]) >= 0.0
	return {"name": String(r[0]) if ok else "Досрочные выборы невозможны", "desc": String(r[1]), "need": maxf(0.0, float(r[2])), "vote": String(r[3]), "ok": ok,
		"why": String(r[1])}


# голоса за самороспуск: коалиция и партии, которые по опросам выигрывают от новых выборов
func snap_votes() -> int:
	var sh := national_shares(false)
	var yes := 0
	for p in PARTY_NAMES.size():
		if seats[p] <= 0:
			continue
		var cur: float = float(seats[p]) / float(maxi(1, SEATS))
		if p == 0 or in_coalition[p] or sh[p] > cur * 1.05:
			yes += int(seats[p])
	return yes
