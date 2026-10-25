# Законы: варианты, голосование, числовые законы, меры и действия.
extends "res://scripts/logic/policy.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func ch_law_label(vs: Array) -> void:
	pass


func decree_power() -> bool:
	return false


func democracy_index() -> float:
	return 0.0


func hold_parliament(reason: String) -> void:
	pass


func junior_info() -> Dictionary:
	return {}


func law_locked(tid: String) -> String:
	return ""


func martial_on() -> bool:
	return false


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


func rl_jud() -> float:
	return 0.0


func rl_on() -> bool:
	return false


func sfx(name: String) -> void:
	pass


func tolerates(p: int) -> bool:
	return false


func vote_show(replay: bool = false) -> void:
	pass


# --- конец заглушек ---


# ============================================================
#  0.56 (п.14, 20): РАЗОВЫЕ МЕРЫ — ответственные и лимит
#  У каждой меры есть ответственный: министерство (если оно у партнёра и партнёр против — мера заблокирована)
#  или глава государства (подпишет ли он — зависит от конституции). Кроме своей перезарядки — общий лимит в квартал.
# ============================================================
# id -> [министерство (-1 — глава государства), статья, к которой близка мера, направление]
const MEAS_RESP := {"privatize": [0, "subs", -1], "amnesty": [0, "corp", -1], "stimulus": [0, "infra", 1], "pension_bonus": [9, "pensions", 1],
	"price_freeze": [5, "benefits", 1], "reserves": [0, "", 0], "cheap_credit": [5, "subs", 1], "fx_intervention": [0, "", 0],
	"food_import": [6, "benefits", 1], "food_cap": [6, "benefits", 1], "fuel_aid": [0, "eco", -1], "med_support": [3, "health", 1],
	"housing_aid": [8, "benefits", 1], "pardon": [-1, "police", -1], "unity": [-1, "", 0]}
const MEAS_Q_LIMIT := 2


func meas_quarter() -> int:
	return year * 4 + (month - 1) / 3


func meas_q_used() -> int:
	return meas_qn if meas_q == meas_quarter() else 0


func meas_min(id: String) -> int:
	return int((MEAS_RESP.get(id, [0, "", 0]) as Array)[0])


# партия, держащая министерство меры (0 — вы); -1 — министерство свободно
func meas_holder(id: String) -> int:
	var mi := meas_min(id)
	if mi < 0 or mi >= ministries.size():
		return 0
	return ministries[mi]


# против ли партнёр p меры (по его отношению к близкой статье бюджета)
func meas_partner_against(id: String, p: int) -> bool:
	var r: Array = MEAS_RESP.get(id, [0, "", 0])
	if String(r[1]) == "" or p <= 0:
		return false
	return ideo_stance(p, String(r[1])) * float(r[2]) < -0.25


func meas_resp_text(id: String) -> String:
	var mi := meas_min(id)
	if mi < 0:
		return "Глава государства (%s)" % String(ELEC.get("title_n", "глава государства")).to_lower()
	var h := meas_holder(id)
	var who: String = "ваша партия" if h == 0 else "партия «%s»" % PARTY_NAMES[h]
	return "Министерство «%s» — %s" % [String(MINISTRIES[mi]["name"]), who]


# подпишет ли глава государства (по конституции): монарх и коллегиальный совет — по совету правительства,
# избранный президент — только если он из вашей партии (прямые выборы) или из коалиции (выбран парламентом)
func meas_head_why() -> String:
	if decree_power():
		return ""
	var hk: String = String(ELEC.get("head", "monarch"))
	if hk == "monarch" or hk == "council" or hk == "none":
		return ""
	if pres_party == 0:
		return ""
	if hk != "direct" and pres_party > 0 and pres_party < in_coalition.size() and in_coalition[pres_party]:
		return ""
	if pres_party < 0:
		return ""
	return "это решает %s от партии «%s», а она не поддерживает ваше правительство" % [String(ELEC.get("title_n", "глава государства")).to_lower(), PARTY_NAMES[pres_party]]


func meas_why(id: String) -> String:
	var why := pl_why("gov")
	if why != "":
		return why
	if game_over:
		return "игра окончена"
	var cd: int = int(cooldown.get(id, 0))
	if cd > 0:
		return "мера недавно проводилась: ещё %d мес." % cd
	if meas_q_used() >= MEAS_Q_LIMIT:
		return "в этом квартале уже проведено %d меры — правительство не успевает больше" % MEAS_Q_LIMIT
	if meas_min(id) < 0:
		return meas_head_why()
	var h := meas_holder(id)
	if h > 0 and in_coalition.size() > h and in_coalition[h] and meas_partner_against(id, h):
		return "министерство «%s» у партии «%s», и она против этой меры" % [String(MINISTRIES[meas_min(id)]["name"]), PARTY_NAMES[h]]
	return ""


func do_measure(id: String) -> void:
	if pl_deny(): return
	var why := meas_why(id)
	if why != "":
		log_line("[color=%s]Мера недоступна: %s.[/color]" % [COL_WARN, why])
		return
	var m := find_by_id(MEASURES, id)
	cooldown[id] = int(m["cd"])
	if meas_q != meas_quarter():
		meas_q = meas_quarter()
		meas_qn = 0
	meas_qn += 1
	var eff := apply_fx(m["fx"])
	log_line("[b]%s: разовая мера «%s».[/b] Отвечает: %s. Последствия: %s." % [date_text(), m["name"], meas_resp_text(id), eff])
	refresh()


func do_action(id: String) -> void:
	if pl_deny(): return
	if game_over or int(cooldown.get(id, 0)) > 0:
		return
	var a := find_by_id(ACTIONS, id)
	if cap_spendable() < float(a["cost"]):
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
	if fx.has("dip_all") and absf(float(fx["dip_all"])) > 0.001:
		out.append(["отношения с другими странами %s" % sg(fx["dip_all"], 1), 1 if float(fx["dip_all"]) > 0.0 else -1])
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


const POW_MODERATION := 4.0   # v35: сдвиг позиции партий за каждую 1.0× силы (смягчение +, усиление −)


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
	if idx == law_start_idx(tid):
		return 6.0
	var k := 0.6 + 0.4 * pw_of(tid, true)
	# 0.55.4: у прежнего «нынешнего порядка» (вариант 0 при LAW_START) нет цены — берём цену стартового варианта
	var c0: float = float(variant_of(tid, law_start_idx(tid)).get("c", 6.0))
	return float(variant_of(tid, idx).get("c", c0)) * (1.3 if is_fund(tid) else 1.0) * k


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
	# v35: смягчённая редакция приемлема для большего числа партий, жёсткая — для меньшего
	if idx > 0 and idx != cur and is_hybrid(tid):
		s += (1.0 - pw_of(tid, true)) * POW_MODERATION
	return s


var last_vote := {}    # v51: итог последнего голосования (для окна с анимацией)
var vote_notes := {}   # 0.57.1: пометки к фракциям в таблице итогов (сделки, давление, обмен голосами)


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
	# v51: фракции голосуют не единогласно: часть депутатов идёт против линии партии (зависит от того, насколько
	# партии близок вариант, от дисциплины и характера лидера). per: [партия, позиция, линия «за», за, против, воздержались]
	var no := 0
	var ab := 0
	for p in PARTY_NAMES.size():
		if seats[p] == 0:
			continue
		var s := variant_stance(p, tid, idx)
		var ok: bool = p == vote_sponsor or s >= 0.0 or (in_coalition[p] and s >= -1.0) or (p in forced) or (s >= -3.0 and pact_has(p, "votes"))
		# 0.56: по чужому законопроекту фракция игрока голосует так, как он решил
		if p == 0 and vote_sponsor != 0 and vote_pl != "" and vote_pl != "line":
			if vote_pl == "yes":
				ok = true
			elif vote_pl == "no":
				ok = false
			elif vote_pl == "abst":
				per.append([p, s, false, 0, 0, seats[0]])
				ab += seats[0]
				continue
			else:
				var fy: float = clampf(0.5 + 0.08 * s, 0.1, 0.9)
				var fyes: int = int(round(float(seats[0]) * fy))
				per.append([p, s, fy >= 0.5, fyes, seats[0] - fyes, 0])
				yes += fyes
				no += seats[0] - fyes
				continue
		# 0.58: партия, которая терпит правительство меньшинства, при неприятном ей законе воздерживается, а не голосует «против»
		# (воздержание не считается голосом «против»: так правительства меньшинства проводят обычные законы)
		if not ok and p != 0 and not is_fund(tid) and s >= -2.0 and (tolerates(p) or pact_has(p, "tol")):
			per.append([p, s, false, 0, 0, seats[p]])
			ab += seats[p]
			continue
		var cnt := party_vote_split(p, s, ok)
		per.append([p, s, ok, cnt[0], cnt[1], cnt[2]])
		yes += cnt[0]
		no += cnt[1]
		ab += cnt[2]
	return {"yes": yes, "no": no, "abst": ab, "per": per}


# доля депутатов партии p, голосующих против линии партии
func party_dissent(p: int, s: float, line_yes: bool) -> float:
	var r := 0.02
	if line_yes:
		r += clampf(0.10 - 0.04 * s, 0.0, 0.22)
	else:
		r += clampf(0.08 + 0.03 * s, 0.0, 0.16)
	var m := 1.0
	if p == vote_sponsor:
		m *= 0.3
	elif p < in_coalition.size() and in_coalition[p]:
		m *= 0.6
	if p == 0:
		m *= 0.6 * (1.0 + 2.0 * pl_disc)   # 0.56: голосования против линии партии расшатывают дисциплину
	var tr: String = String((PARTY_TRAITS[p] as Dictionary).get("trait", "")) if p < PARTY_TRAITS.size() else ""
	if tr == "идеолог":
		m *= 0.75
	elif tr == "прагматик":
		m *= 1.25
	# несвободные режимы: «партийная дисциплина» почти полная
	m *= clampf(democracy_index() * 1.6, 0.15, 1.0)
	return clampf(r * m, 0.0, 0.35)


# [за, против, воздержались] у партии; vote_live — настоящее голосование (случайные отступники и редкие случайные голоса)
var vote_live := false


func party_vote_split(p: int, s: float, line_yes: bool) -> Array:
	var n: int = seats[p]
	var fr := party_dissent(p, s, line_yes)
	var reb: int
	if vote_live:
		reb = clampi(int(round(randfn(float(n) * fr, sqrt(maxf(0.0, float(n) * fr * (1.0 - fr)))))), 0, n)
	else:
		reb = int(round(float(n) * fr))
	var loyal: int = n - reb
	var reb_no: int = int(ceil(float(reb) * 0.6))
	var reb_ab: int = reb - reb_no
	var yes: int
	var no: int
	if line_yes:
		yes = loyal
		no = reb_no
	else:
		yes = reb_no
		no = loyal
	var ab: int = reb_ab
	# редко — единичный случайный голос (ошибка, личные мотивы)
	if vote_live and n >= 3 and randf() < 0.10:
		if line_yes and yes > 0:
			yes -= 1
			no += 1
		elif not line_yes and no > 0:
			no -= 1
			yes += 1
	return [yes, no, ab]


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
	# 0.58: конституционные законы почти везде требуют согласия обеих палат; отлагательное вето верхней палаты на них не действует
	# (исключения: Великобритания, Ирландия, Словения, где верхняя палата может лишь задержать закон)
	var fund_bind: bool = is_fund(tid) and kind in ["override", "consent"] and not (ccode in ["GB", "IE", "SI"])
	if kind == "consent":
		binding = fund_bind or tid in (UPPER.get("consent", []) as Array)
	var res := {"on": true, "yes": yes, "need": need, "total": total, "passed": passed, "kind": kind, "name": String(UPPER["name"]), "block": false, "extra": 0.0, "binding": binding}
	if not passed:
		if kind == "full" or (kind == "consent" and binding) or fund_bind:
			res["block"] = true
		else:
			res["extra"] = 5.0
	return res


# 0.58: конституционный контроль. Страны, где суд реально может остановить закон (предварительно или после принятия);
# в остальных (Великобритания, Нидерланды, Швейцария, Скандинавия, Люксембург, автократии) суд закон не отменяет.
const REVIEW_STRONG := ["DE", "FR", "IT", "ES", "AT", "PT", "PL", "CZ", "SK", "SI", "HR", "RO", "BG", "HU", "LT", "LV", "EE", "IE", "BE", "GR", "MK",
	"AL", "RS", "ME", "XK", "MD", "UA", "BA"]


# шанс, что суд остановит закон: основа 12 % для конституционных и «правовых» законов, растёт с независимостью судов и с отходом от прав
func court_chance(tid: String, idx: int) -> float:
	if not (ccode in REVIEW_STRONG) or democracy_index() < 0.5 or not rl_on():
		return 0.0
	var dl: Dictionary = DEM_LAW.get(tid, {})
	var bad: bool = float(dl.get(idx, 0.0)) < -0.05
	if not is_fund(tid) and not bad:
		return 0.0
	var jud: float = rl_jud()
	var p: float = 0.12 * clampf(jud / 65.0, 0.2, 1.5)
	if bad:
		p *= 1.8
	if is_fund(tid) and idx != cur_idx(tid) and absf(float(dl.get(idx, 0.0))) < 0.02:
		p *= 0.8
	return clampf(p, 0.0, 0.4)


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
	if pl_deny("parl"): return
	if game_over or idx == cur_idx(tid):
		return
	var sw := variant_swing(tid, idx)
	if sw.is_empty() or cap_spendable() < float(sw["cost"]) + law_cost(tid, idx):
		return
	capital -= float(sw["cost"])
	var names: PackedStringArray = []
	for p in sw["parties"]:
		names.append(PARTY_NAMES[p])
	log_tag("ПЕРЕГОВОРЫ", COL_PURPLE, "по закону «%s»: договорённости с %s (политкапитал -%.0f)." % [law_index[tid]["name"], ", ".join(names), sw["cost"]])
	propose_variant(tid, idx, sw["parties"])


# 0.59: окно голосования для всех видов голосований (бюджет, вотум недоверия, референдум и т.д.)
# per — строки [партия, позиция, по линии «за»?, за, против, воздержались] в местах
func vote_other(kind: String, title: String, sub: String, per: Array, need: int, passed: bool, final: String, need_text: String = "", next: String = "") -> void:
	var yes := 0
	var no := 0
	var ab := 0
	for it in per:
		yes += int(it[3])
		no += int(it[4])
		ab += int(it[5])
	last_vote = {"tid": "", "other": kind, "title": title, "sub": sub, "per": per, "need": need, "yes": yes, "no": no, "abst": ab, "passed": passed,
		"final": final, "need_text": need_text, "next": next, "sponsor": 0, "turn": turn, "bypass": false, "notes": {}, "extra": []}
	vote_show()


# всенародное голосование: ya — доля «за», %, need_pct — порог
func vote_popular(kind: String, title: String, sub: String, yes_pct: float, need_pct: float, passed: bool, final: String, next: String = "") -> void:
	last_vote = {"tid": "", "other": kind, "title": title, "sub": sub, "per": [], "need": 0, "yes": 0, "no": 0, "abst": 0, "passed": passed, "final": final,
		"pop": [yes_pct, need_pct, 100.0 - yes_pct], "need_text": "не меньше %.0f%%" % need_pct if need_pct > 50.5 else "больше половины", "next": next,
		"sponsor": 0, "turn": turn, "bypass": false, "notes": {}, "extra": []}
	vote_show()


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
	if cap_spendable() < cost:
		return
	var jn: Dictionary = junior_info()
	if bool(jn["junior"]) and vote_sponsor == 0 and not (int(jn["pm"]) in forced) and variant_stance(int(jn["pm"]), tid, idx) < -0.8:
		log_line("[color=%s]Закон «%s» заблокирован: партия главы правительства «%s» против, а вы в коалиции младший партнёр.[/color]" % [COL_BAD, topic["name"], PARTY_NAMES[int(jn["pm"])]])
		refresh()
		return
	var v := variant_votes(tid, idx, forced)
	if int(v["yes"]) < law_need(tid, v):
		log_line("[color=%s]Закон «%s» не вынесен на голосование: нужно %d голосов, есть %d.[/color]" % [COL_BAD, topic["name"], law_need(tid, v), v["yes"]])
		# 0.57.1: окно показывает и этот исход — зал с прогнозом и «ОТКЛОНЁН»
		last_vote = {"tid": tid, "idx": idx, "need": law_need(tid, v), "yes": int(v["yes"]), "no": int(v.get("no", 0)), "abst": int(v.get("abst", 0)),
			"per": v["per"], "passed": false, "sponsor": vote_sponsor, "turn": turn, "bypass": bool(v.get("bypass", false)), "noconv": true,
			"notes": vote_notes.duplicate(), "next": "Закон не вынесен на голосование: не хватало голосов уже по прогнозу."}
		vote_notes.clear()
		vote_show()
		refresh()
		return
	# v51: само голосование — с отступниками и случайными голосами; итог может разойтись с прогнозом
	vote_live = true
	var live := variant_votes(tid, idx, forced)
	vote_live = false
	last_vote = {"tid": tid, "idx": idx, "need": law_need(tid, live), "yes": int(live["yes"]), "no": int(live.get("no", 0)), "abst": int(live.get("abst", 0)),
		"per": live["per"], "passed": int(live["yes"]) >= law_need(tid, live), "sponsor": vote_sponsor, "turn": turn, "bypass": bool(live.get("bypass", false)),
		"notes": vote_notes.duplicate(), "next": vote_next_text(tid, idx, int(live["yes"]) >= law_need(tid, live), cost)}
	vote_notes.clear()
	if not bool(live.get("bypass", false)) and int(live["yes"]) < law_need(tid, live):
		capital -= cost * 0.5
		log_line("[color=%s]Закон «%s» провален при голосовании: за %d, против %d, воздержались %d — нужно %d. Часть депутатов нарушила дисциплину (политкапитал -%.0f).[/color]" % [COL_BAD, topic["name"], int(live["yes"]), int(live["no"]), int(live["abst"]), law_need(tid, live), cost * 0.5])
		vote_show()
		refresh()
		return
	var upc := upper_check(tid, idx, forced)
	last_vote["extra"] = []
	if bool(upc["on"]):
		(last_vote["extra"] as Array).append([upper_text(upc), not bool(upc["block"])])
	if bool(upc["block"]):
		log_line("[color=%s]Закон «%s» не прошёл: %s.[/color]" % [COL_BAD, topic["name"], upper_text(upc)])
		last_vote["passed"] = false
		last_vote["final"] = "ПРИНЯТ ПАРЛАМЕНТОМ, ЗАБЛОКИРОВАН ВЕРХНЕЙ ПАЛАТОЙ" if String(upc.get("kind", "")) != "veto" else "ПРИНЯТ ПАРЛАМЕНТОМ, НО ПРЕЗИДЕНТ НАЛОЖИЛ ВЕТО"
		vote_show()
		refresh()
		return
	var cch := court_chance(tid, idx)
	if cch > 0.0 and randf() < cch:
		if vote_sponsor == 0:
			capital -= cost * 0.4
		law_cd[tid] = 6
		log_line("[color=%s][b]Суд остановил закон «%s»:[/b] конституционный контроль признал его несовместимым с основным законом (независимость судов %.0f). Политкапитал -%.0f; вернуться к вопросу можно через полгода.[/color]" % [COL_BAD, topic["name"], rl_jud(), cost * 0.4])
		(last_vote["extra"] as Array).append(["Конституционный суд признал закон несовместимым с основным законом", false])
		last_vote["passed"] = false
		last_vote["final"] = "ПРИНЯТ ПАРЛАМЕНТОМ, ОСТАНОВЛЕН СУДОМ"
		vote_show()
		refresh()
		return
	# 0.58: обязательный референдум по конституционным поправкам (Ирландия, Швейцария, Румыния, Дания)
	if is_fund(tid) and bool(MACRO.get("amend_ref", false)) and idx != cur_idx(tid) and vote_sponsor >= 0:
		var yes_sh := 0.0
		var nsh := national_shares(false)
		for it in v["per"]:
			if bool(it[2]) or int(it[0]) == 0:
				yes_sh += float(nsh[int(it[0])])
		yes_sh = clampf(yes_sh + randfn(0.0, 0.03) - 0.02, 0.0, 1.0)   # избиратели чуть осторожнее депутатов
		if yes_sh <= 0.5:
			capital -= cost * 0.6
			law_cd[tid] = 12
			log_line("[color=%s][b]Референдум отклонил поправку «%s»:[/b] за %.0f%% голосов, нужно больше половины. Политкапитал -%.0f; повторить можно через год.[/color]" % [COL_BAD, topic["name"], yes_sh * 100.0, cost * 0.6])
			(last_vote["extra"] as Array).append(["Референдум: за %.0f%% голосов, нужно больше половины" % (yes_sh * 100.0), false])
			last_vote["passed"] = false
			last_vote["final"] = "ПРИНЯТ ПАРЛАМЕНТОМ, ОТКЛОНЁН НА РЕФЕРЕНДУМЕ"
			vote_show()
			refresh()
			return
		log_line("[color=%s]Референдум одобрил поправку «%s»: за %.0f%% голосов.[/color]" % [COL_GOOD, topic["name"], yes_sh * 100.0])
		(last_vote["extra"] as Array).append(["Референдум одобрил поправку: за %.0f%% голосов" % (yes_sh * 100.0), true])
	cost += float(upc["extra"])
	if cap_spendable() < cost:
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
	var ksup := 1.0 if vote_sponsor == 0 else (0.5 if not opp_mode else -0.6)   # 0.56: закон партнёра или оппозиции при вашей власти
	for g in sd:
		add_support(g, float(sd[g]) * ksup)
		bias[g] = float(bias[g]) + float(sd[g]) * 0.4 * ksup
	var std := dict_diff(variant_part(tid, cur, "st"), variant_part(tid, idx, "st", true))
	for k in std:
		lvl[k] = clampf(float(lvl[k]) + float(std[k]), 0.0, 100.0)
	var rgd := dict_diff(variant_part(tid, cur, "rg"), variant_part(tid, idx, "rg", true))
	if not rgd.is_empty():
		rg_drip.append({"d": rgd, "n": 12})
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
	if vote_sponsor == 0:
		sfx("good")
	var lv: Dictionary = last_vote if (not last_vote.is_empty() and String(last_vote.get("tid", "")) == tid and int(last_vote.get("turn", -1)) == turn) else {"yes": v["yes"], "no": v["no"], "abst": int(v.get("abst", 0))}
	log_tag("ЗАКОН", COL_GOOD, "%s%s — «%s»: %s → [b]%s[/b] [color=%s](за %d, против %d, воздержались %d; политкапитал -%.0f)[/color]. %s" % [
		date_text(), "" if vote_sponsor == 0 else " (правительство «%s»)" % PARTY_NAMES[vote_sponsor], topic["name"], old_v["n"], new_v["n"], COL_DIM, int(lv["yes"]), int(lv["no"]), int(lv.get("abst", 0)), cost, new_v["d"]])
	vote_show()
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


# Канал, по которому закон влияет на показатель: чтобы игрок видел, откуда берётся эффект.
func mod_channel(key: String) -> String:
	if key in ["income_mult", "corp_mult", "vat_mult", "eff_bonus"]:
		return "через налоги"
	if key in ["pension_mult", "admin_mult", "extra_spend", "edu_eff", "health_eff", "env_eff", "infra_eff", "zone_eff", "army_q"]:
		return "через бюджет"
	if key == "growth_bonus" or key == "unemp_base":
		return "напрямую"
	if key in ["sec_bonus", "corr_shift", "equal_shift", "dem_shift", "reg_dev_bonus", "fed_share", "rdebt_shift", "reg_unrest_shift", "auto_shift"]:
		return "через институты"
	if key == "mood_shift" or key.begins_with("gb_"):
		return "через настроение групп"
	return "правило игры"


# Не показываем сдвиги, которые после округления выглядели бы как «0» или «-0».
func mod_visible(key: String, old_v: Variant, new_v: Variant) -> bool:
	var info: Dictionary = MOD_INFO[key]
	var kind: String = info["k"]
	if kind == "mul":
		return absf(float(new_v) / float(old_v) - 1.0) * 100.0 >= 0.5
	if kind == "add":
		var d: float = absf(float(new_v) - float(old_v)) * float(info.get("sc", 1.0))
		return d * pow(10.0, float(int(info["dg"]))) >= 0.5
	return true


# что будет дальше — для кнопки «Что будет дальше» в окне итогов (считается до применения закона)
func vote_next_text(tid: String, idx: int, passed: bool, cost: float) -> String:
	if not passed:
		return "Закон не принят. Часть политкапитала (%.0f) потеряна. Внести его заново можно сразу, но состав голосов зависит от дисциплины и сделок." % (cost * 0.5)
	var t := "[b]Закон вступает в силу сразу.[/b] Изменения по сравнению с прежним порядком:\n"
	t += items_pros_cons(variant_effect_items(tid, idx))
	t += "\n[color=%s]Менять его снова можно через %d мес.[/color]" % [COL_DIM, 24 if is_fund(tid) else 12]
	return t


# 0.57.2: разброс оценки зависит от канала: налоги предсказуемее, настроение групп зыбче всего
const CHAN_WIDTH := {"через налоги": 0.25, "через бюджет": 0.30, "напрямую": 0.40, "через институты": 0.35, "через настроение групп": 0.40}
const NO_RANGE := ["dem_shift", "capital_bonus", "dip_bonus", "auto_shift"]   # правила игры и индексы: считаются точно
const CHAN_WHY := {
	"через налоги": "сбор налогов зависит от того, как отреагируют плательщики",
	"через бюджет": "отдача расходов зависит от качества управления",
	"напрямую": "эффект считается по правилу закона, но экономика отвечает не сразу",
	"через институты": "институты меняются медленно и неравномерно",
	"через настроение групп": "настроение людей самый зыбкий канал",
}
# показатели, у которых есть и постоянная поправка закона (mods), и разовый сдвиг уровня (st): показываем одной строкой с суммой
const MERGE_STAT := {"sec_bonus": "security_lvl", "corr_shift": "corruption", "equal_shift": "equality"}


func range_factor() -> float:
	# слабые институты (высокая коррупция) расширяют разброс
	return clampf(0.75 + float(lvl.get("corruption", 40.0)) / 100.0, 0.75, 1.5)


func range_part(w: float, dg: int) -> String:
	if absf(w) * pow(10.0, float(dg)) < 0.5:
		return ""
	return " ± %s" % String.num(absf(w), dg)


func range_tip(chan: String, extra: String = "") -> String:
	var t := "Канал: %s. Разброс показывает, насколько оценка неточна: %s." % [chan, CHAN_WHY.get(chan, "эффект зависит от обстоятельств")]
	if range_factor() > 1.05:
		t += " Слабые институты в стране (коррупция %d) расширяют его." % int(float(lvl.get("corruption", 40.0)))
	if extra != "":
		t += " " + extra
	return t.replace("[", "(").replace("]", ")")


func thr_party_info(thr: float) -> Array:
	var raw := national_shares(false)
	var exempt: Array = MACRO.get("thr_exempt", [])
	var reserved: Dictionary = MACRO.get("reserved", {})
	# 0.58: то же правило, что в parl_shares: слот «Прочие» барьер не проходит, зарезервированные места остаются
	var lump_out: bool = thr >= 0.005 and not bool(MACRO.get("others_pass", false)) and not (6 in exempt)
	var n := 0
	var wasted := 0.0
	for p in raw.size():
		var ex: bool = (p in exempt) or reserved.has(p) or reserved.has(str(p))
		if (raw[p] >= thr and not (p == 6 and lump_out and not ex)) or (ex and raw[p] > 0.0):
			n += 1
		else:
			wasted += raw[p]
	return [n, wasted]


func variant_effect_items(tid: String, idx: int) -> Array:
	var cur := cur_idx(tid)
	var items: Array = []
	var sd := support_delta(tid, idx)
	for g in GROUPS:
		if sd.has(g) and absf(float(sd[g])) >= 0.55:
			items.append(["%s %s" % [g, sg(float(sd[g]), 0)], 1 if float(sd[g]) > 0.0 else -1])
	var st2: Dictionary = law_state.duplicate()
	st2[tid] = idx
	var m2 := compute_mods(st2, true, tid)
	# 0.57.1: сравниваем с действующим порядком, а не с живыми mods (там ещё слои технологий, дипломатии и радикалов)
	var m1 := compute_mods(law_state, true)
	var std := dict_diff(variant_part(tid, cur, "st"), variant_part(tid, idx, "st", true))
	var rf := range_factor()
	var merged_st := {}
	for key in MOD_INFO:
		if absf(float(m2[key]) - float(m1[key])) <= 0.00001 or not mod_visible(key, m1[key], m2[key]):
			continue
		var info: Dictionary = MOD_INFO[key]
		var kind: String = info["k"]
		var chan := mod_channel(key)
		if (kind != "add" and kind != "mul") or key in NO_RANGE:
			var mi0 := mod_item(key, m1[key], m2[key])
			mi0[0] = "%s (%s)" % [mi0[0], chan]
			mi0.append("Это правило или индекс игры: меняется точно, без разброса.")
			items.append(mi0)
			continue
		var g: int = int(info["g"])
		var wf: float = float(CHAN_WIDTH.get(chan, 0.5)) * rf
		if kind == "mul":
			var pct: float = (float(m2[key]) / float(m1[key]) - 1.0) * 100.0
			var good: int = 0
			if g != 0:
				good = 1 if ((pct > 0.0) == (g > 0)) else -1
			items.append(["%s %s%%%s (%s)" % [info["t"], sg(pct, 0), range_part(absf(pct) * wf, 0), chan], good, range_tip(chan)])
			continue
		var d: float = (float(m2[key]) - float(m1[key])) * float(info.get("sc", 1.0))
		var dg: int = int(info["dg"])
		var extra := ""
		var stk: String = String(MERGE_STAT.get(key, ""))
		if stk != "" and std.has(stk):
			merged_st[stk] = true
			var ds: float = float(std[stk])
			extra = "Из них: %s постоянная поправка закона, %s разовый сдвиг уровня при принятии." % [sg(d, dg), sg(ds, 0)]
			d += ds
		if absf(d) * pow(10.0, float(dg)) < 0.51:
			continue
		var good2: int = 0
		if g != 0:
			good2 = 1 if ((d > 0.0) == (g > 0)) else -1
		if key == "growth_bonus" and absf(float(m2["dem_shift"]) - float(m1["dem_shift"])) > 0.01:
			extra = "Рост считается одной формулой от потери демократичности (не больше -%.2f п.п. в год), а не отдельным числом у каждой формы правления." % DEM_GROWTH_CAP
		var u: String = String(info["u"])
		items.append(["%s %s%s%s (%s)" % [info["t"], sg(d, dg), range_part(absf(d) * wf, dg), u, chan], good2, range_tip(chan, extra)])
	if m2["threshold"] != m1["threshold"]:
		var a0 := thr_party_info(float(m1["threshold"]))
		var a1 := thr_party_info(float(m2["threshold"]))
		items.append(["партий в парламенте по нынешним опросам: %d → %d, потерянных голосов: %d%% → %d%%" % [int(a0[0]), int(a1[0]), int(roundf(float(a0[1]) * 100.0)), int(roundf(float(a1[1]) * 100.0))], 0,
			"Считается по нынешним опросам, на выборах цифры будут другими. Чем выше барьер, тем больше голосов за малые партии не даёт мест."])
	for k in std:
		if merged_st.has(k):
			continue
		var good3: bool = (float(std[k]) < 0.0) == (k == "corruption")
		items.append(["%s %s (через институты)" % [STATE_NAMES[k], sg(float(std[k]), 0)], 1 if good3 else -1, "Разовый сдвиг уровня при принятии закона.".replace("[", "(")])
	var rgd := dict_diff(variant_part(tid, cur, "rg"), variant_part(tid, idx, "rg", true))
	for k in rgd:
		items.append(reg_item(k, float(rgd[k]), "во всех регионах (постепенно, 12 мес.)"))
	var fxn: Dictionary = variant_of(tid, idx).get("fxnow", {})
	if idx != cur and fxn.has("rgrel"):
		for k in fxn["rgrel"]:
			items.append(["%s в регионах при принятии: %s, сильнее в светских, слабее в религиозных" % [REG_TITLES[k], sg(float(fxn["rgrel"][k]), 0)], -1 if k == "unrest" else 0, "Где больше деревни и пенсионеров, закон встречают спокойнее."])
	var dd: float = float(variant_of(tid, idx).get("debt", 0.0)) * (pw_of(tid, true) if idx > 0 else 1.0) - float(variant_of(tid, cur).get("debt", 0.0)) * (pw_of(tid) if cur > 0 else 1.0)
	if absf(dd) > 0.0001:
		items.append(["долг %s%% ВВП (разово)" % sg(dd), 1 if dd < 0.0 else -1])
	return items


# 0.57.2: региональные сдвиги закона идут по 1/12 в месяц, а не одним скачком
func rg_drip_step() -> void:
	if rg_drip.is_empty():
		return
	var keep: Array = []
	for e in rg_drip:
		var n: int = int(e["n"])
		var part := {}
		for k in e["d"]:
			part[k] = float(e["d"][k]) / 12.0
		for i in regions.size():
			apply_reg_delta(i, part)
		e["n"] = n - 1
		if n - 1 > 0:
			keep.append(e)
	rg_drip = keep


func items_pros_cons(items: Array) -> String:
	var pros: PackedStringArray = []
	var cons: PackedStringArray = []
	var neut: PackedStringArray = []
	for it in items:
		var k: int = it[1]
		var tx: String = String(it[0])
		if it.size() > 2 and String(it[2]) != "":
			tx = "[hint=%s]%s[/hint]" % [String(it[2]), tx]
		if k > 0:
			pros.append(tx)
		elif k < 0:
			cons.append(tx)
		else:
			neut.append(tx)
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
		if int(t["cat"]) == cat and cur_idx(t["id"]) != law_start_idx(t["id"]):
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
		if p.has("ps"):
			var ps: Dictionary = {}
			for q in p["ps"]:
				ps[q] = snappedf(float(p["ps"][q]) * k, 0.1)
			one["ps"] = ps
		if p.has("setk"):
			one["set"] = {String(p["setk"]): (int(roundf(v * float(p["setm"]))) if float(p["setm"]) >= 1.0 else v * float(p["setm"]))}
		vars.append(one)
		grid.append(vars.size() - 1)
	return {"id": p["id"], "cat": int(p["cat"]), "name": p["name"], "desc": p["desc"], "v": vars,
		"param": {"vals": grid_vals, "grid": grid, "ref": ref, "fmt": p["fmt"], "unit": p["unit"], "lo": float(grid_vals[0]), "hi": float(grid_vals[grid_vals.size() - 1])}}


func build_law_topics() -> Array:
	var LAW_PARAMS: Array = de_law_params()
	var pidx := {}
	for p in LAW_PARAMS:
		if p.has("refk"):
			var rv: float = snappedf(float(BASE_MODS[String(p["refk"])]) * float(p["refm"]), 0.5)
			p["ref"] = rv
			p["lo"] = minf(float(p["lo"]), rv)
			p["hi"] = maxf(float(p["hi"]), rv)
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
	for t in NEW_TOPICS60:
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
	for t in out:
		sq_effects(t)
	return out


# v35: действующий порядок (вариант 0) тоже действует: если у него нет своих постоянных эффектов,
# он получает зеркальные к альтернативам, ослабленные (что дают альтернативы — того сейчас нет, и наоборот).
const SQ_K := 0.3


func sq_effects(t: Dictionary) -> void:
	if t.has("param") or bool(t.get("rad", false)):
		return
	var vs: Array = t["v"]
	if vs.size() < 2:
		return
	var v0: Dictionary = vs[0]
	if not (v0.get("a", {}) as Dictionary).is_empty() or not (v0.get("x", {}) as Dictionary).is_empty():
		return
	var sa := {}
	var sx := {}
	var n: float = float(vs.size() - 1)
	for i in range(1, vs.size()):
		var ad: Dictionary = (vs[i] as Dictionary).get("a", {})
		for k in ad:
			if k == "dem_shift":
				continue
			sa[k] = float(sa.get(k, 0.0)) + float(ad[k]) / n
		var xd: Dictionary = (vs[i] as Dictionary).get("x", {})
		for k in xd:
			sx[k] = float(sx.get(k, 0.0)) + (float(xd[k]) - 1.0) / n
	var a0 := {}
	var x0 := {}
	for k in sa:
		if absf(float(sa[k])) > 0.0005:
			a0[k] = -float(sa[k]) * SQ_K
	for k in sx:
		if absf(float(sx[k])) > 0.0005:
			x0[k] = 1.0 - float(sx[k]) * SQ_K
	if a0.is_empty() and x0.is_empty():
		return
	if not a0.is_empty():
		v0["a"] = a0
	if not x0.is_empty():
		v0["x"] = x0
	v0["sq"] = true


# постоянные эффекты варианта (то, что он даёт, пока действует)
func variant_own_items(tid: String, idx: int) -> Array:
	var v := variant_of(tid, idx)
	var pw: float = pw_of(tid) if idx > 0 else 1.0
	var items: Array = []
	var xs: Dictionary = v.get("x", {})
	for k in xs:
		if MOD_INFO.has(k) and absf(float(xs[k]) - 1.0) > 0.0001:
			items.append(mod_item(k, 1.0, 1.0 + (float(xs[k]) - 1.0) * pw))
	var ad: Dictionary = v.get("a", {})
	for k in ad:
		if MOD_INFO.has(k) and absf(float(ad[k])) > 0.0001:
			items.append(mod_item(k, 0.0, float(ad[k]) * pw))
	return items


func is_fund(tid: String) -> bool:
	return bool(law_index[tid].get("fund", false))


# 0.58: сколько голосов «за» нужно. Конституционные темы — доля состава палаты по стране (MACRO.const_need, обычно 2/3);
# избирательные законы — абсолютное большинство состава; обычные законы — больше голосов «за», чем «против»
# (воздержавшиеся не считаются «против»), кроме стран, где нужно большинство состава (MACRO.law_all: Россия, Украина, Беларусь).
# Без итогов голосования (v пуст) показываем большинство состава как ориентир.
func super_need() -> int:
	return int(ceil(float(SEATS) * float(MACRO.get("const_need", 0.667)) - 0.0001))


func super_text() -> String:
	var f := float(MACRO.get("const_need", 0.667))
	if absf(f - 0.667) < 0.01:
		return "2/3"
	if absf(f - 0.6) < 0.01:
		return "3/5"
	if absf(f - 0.75) < 0.01:
		return "3/4"
	return "больше половины" if f <= 0.5 else "%d%%" % int(round(f * 100.0))


func law_need(tid: String, v: Dictionary = {}) -> int:
	if is_fund(tid):
		return super_need()
	if tid in ORGANIC_IDS or bool(MACRO.get("law_all", false)) or v.is_empty():
		return MAJORITY
	return mini(MAJORITY, maxi(int(v.get("no", 0)) + 1, int(ceil(float(SEATS) / 3.0))))


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
	var v := variant_votes(tid, idx)
	var need := law_need(tid, v)
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
# v55_3: общие темы «Срок парламента» и «Избирательный барьер» написаны под Германию (4 года, 5 %);
# у страны с другим сроком или барьером действующий вариант подписывается её значением, а совпадающий с ним — заменяется немецким
func law_years(n: int) -> String:
	return "%d %s" % [n, "год" if n % 10 == 1 and n % 100 != 11 else ("года" if n % 10 in [2, 3, 4] and not (n % 100 in [12, 13, 14]) else "лет")]


func law_scaled(v: Dictionary, k: float) -> Dictionary:
	var o := {}
	for key in ["s", "ps", "a"]:
		if not v.has(key):
			continue
		var d := {}
		for x in v[key]:
			d[x] = float(v[key][x]) * k
		o[key] = d
	return o


func law_fit_generic() -> void:
	for t in LAW_TOPICS:
		var vs: Array = t["v"]
		if String(t["id"]) == "parl_term_law" and String(vs[0]["n"]) == "4 года":
			var n: int = int(round(float(BASE_MODS["parl_term"]) / 12.0))
			if n == 4:
				continue
			vs[0]["n"] = law_years(n)
			for i in range(1, vs.size()):
				if int((vs[i].get("set", {}) as Dictionary).get("parl_term", -1)) == n * 12:
					var src: Dictionary = vs[1] if n > 4 else vs[vs.size() - 1]
					var nv := law_scaled(src, 0.6)
					nv["n"] = "4 года"
					nv["d"] = "Выборы чаще: власть ближе к избирателям, но предвыборная гонка почти не прекращается." if n > 4 else "Выборы реже: больше стабильности, меньше подотчётности."
					nv["c"] = 14.0
					nv["set"] = {"parl_term": 48}
					vs[i] = nv
		elif String(t["id"]) == "elect_threshold" and String(vs[0]["n"]) == "Барьер 5%":
			var thr: float = float(BASE_MODS["threshold"])
			if absf(thr - 0.05) < 0.001:
				continue
			vs[0]["n"] = ("Барьер %s%%" % str(snappedf(thr * 100.0, 0.1)).trim_suffix(".0").replace(".", ",")) if thr >= 0.005 else "Без барьера"
			for i in range(1, vs.size()):
				if absf(float((vs[i].get("set", {}) as Dictionary).get("threshold", -1.0)) - thr) < 0.001:
					var nv2 := law_scaled(vs[1] if thr > 0.05 else vs[2], 0.6)
					nv2["n"] = "Барьер 5%"
					nv2["d"] = "Барьер ниже нынешнего: мелким партиям проще пройти в парламент." if thr > 0.05 else "Барьер выше нынешнего: мелкие партии отсеиваются, у крупных больше мест."
					nv2["c"] = 14.0
					nv2["set"] = {"threshold": 0.05}
					vs[i] = nv2
		elif String(t["id"]) == "state_church" and String(vs[0]["n"]).begins_with("Светское государство"):
			ch_law_label(vs)


# v55_3: правки текстов и вариантов общих законов под страну (LAW_TEXT из данных страны)
func law_text_apply() -> void:
	law_fit_generic()
	if LAW_TEXT.is_empty():
		return
	for t in LAW_TOPICS:
		var id: String = String(t["id"])
		if not LAW_TEXT.has(id):
			continue
		var o: Dictionary = LAW_TEXT[id]
		for k in ["name", "desc"]:
			if o.has(k):
				t[k] = o[k]
		var vs: Dictionary = o.get("v", {})
		for vi in vs:
			var i: int = int(vi)
			if i < 0 or i >= (t["v"] as Array).size():
				continue
			var nv: Dictionary = vs[vi]
			# 0.59: у законов-ползунков варианты строятся по сетке, из страны берём только описание действующего порядка
			if t.has("param"):
				if i == 0 and nv.has("d"):
					t["v"][0]["d"] = nv["d"]
				continue
			for k in nv:
				t["v"][i][k] = nv[k]


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
	# 0.60: новые ползунки; действующее значение берётся из PARAM_REF60 для выбранной страны
	var refs: Dictionary = PARAM_REF60.get(ccode, {})
	for p in LAW_PARAMS60:
		var id60: String = p["id"]
		if id60 in DE_REMOVE or id60 in REMOVE60.get(ccode, []):
			continue
		var q60: Dictionary = (p as Dictionary).duplicate(true)
		if refs.has(id60):
			q60["ref"] = float(refs[id60])
		if DE_PARAM.has(id60):
			var o60: Dictionary = DE_PARAM[id60]
			for k in o60:
				q60[k] = o60[k]
		out.append(q60)
	for p in DE_NEW_PARAMS:
		out.append((p as Dictionary).duplicate(true))
	return out


# 0.60: область закона (0..10, см. LAW_AREA_NAMES); у id без записи — по сфере темы
func law_area(tid: String) -> int:
	if LAW_AREA60.has(tid):
		return int(LAW_AREA60[tid])
	var tp: Dictionary = law_index.get(tid, {})
	match int(tp.get("cat", 0)):
		1: return 0
		2: return 1
	return 10


# 0.60: тема из data_laws60.gd (их доли партий заданы по архетипам и не пересчитываются)
func is_law60(tid: String) -> bool:
	if law60_ids.is_empty():
		for t in NEW_TOPICS60:
			law60_ids[t["id"]] = true
		for p in LAW_PARAMS60:
			law60_ids[p["id"]] = true
	return law60_ids.has(tid)


func de_fix_ps(topics: Array) -> void:
	for t in topics:
		for v in (t["v"] as Array):
			if not v.has("ps"):
				continue
			var ps: Dictionary = (v["ps"] as Dictionary).duplicate()
			if t["id"] in ["debt_brake", "eu_policy", "citizenship_law", "rent_control", "auto_policy", "schengen"] or DE_OWN.has(t["id"]) or is_law60(t["id"]):
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
	var own60: Array = COUNTRY_TOPICS60.get(ccode, [])
	for t in own60:
		DE_OWN[t["id"]] = true
	for t in DE_TOPICS:
		DE_OWN[t["id"]] = true
	var res: Array = []
	for t in out:
		if t["id"] in DE_REMOVE or DE_OWN.has(t["id"]) or (is_law60(t["id"]) and t["id"] in REMOVE60.get(ccode, [])):
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
	# 0.60: особые законы страны (реальные законы; доли партий — по местам партий страны)
	for t in own60:
		var t60: Dictionary = (t as Dictionary).duplicate(true)
		var at60 := res.size()
		for i in res.size():
			if int(res[i]["cat"]) > int(t60["cat"]):
				at60 = i
				break
		res.insert(at60, t60)
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


# 0.62: недельный шаг: спецфонд, надбавка за риск и штрафы текут по доле месяца wdt; счётчик месяцев нарушения и журнал — только при wmonth
func brake_step(deficit_pct: float) -> void:
	if fund_left > 0.0:
		fund_left = maxf(0.0, fund_left - 0.010 * gdp / 12.0 * wdt)
	if not brake_active():
		brake_over = 0
		return
	var over: float = deficit_pct - brake_allowed() - 0.5
	if wmonth:
		if over > 0.0:
			brake_over += 1
		else:
			brake_over = maxi(0, brake_over - 2)
	if ccode != "DE":
		var fname := String(MACRO.get("fiscal_name", "Правила ЕС"))
		var strict: bool = float(MACRO.get("fiscal_base", 3.0)) < 1.5
		if over > 0.0:
			risk_prem = minf(2.0 if not strict else 0.5, risk_prem + 0.03 * minf(over, 3.0) * wdt)
		else:
			risk_prem = maxf(0.0, risk_prem - 0.05 * wdt)
		if not wmonth:
			if brake_over >= 6:
				capital -= (0.8 if strict else 0.15) * wdt
				add_support("Бизнес", (-0.3 if not strict else -0.4) * wdt)
		elif brake_over == 3:
			log_line("[color=%s][b]%s:[/b] дефицит %.1f%% ВВП выше допустимых %.1f%%. %s[/color]" % [COL_WARN, fname, deficit_pct, brake_allowed(), "Звучат предупреждения министерства финансов и суда." if strict else ("Еврокомиссия предупреждает" if bool(MACRO.get("eu", false)) else "Рейтинговые агентства предупреждают") + " правительство, инвесторы требуют премию за риск."])
		elif brake_over >= 6:
			capital -= (0.8 if strict else 0.15) * wdt
			if brake_over % 6 == 0:
				log_line("[color=%s][b]Нарушение бюджетного правила (%s).[/b] Рынки и партнёры давят на правительство (политкапитал -%s в месяц, ставка по долгу выше).[/color]" % [COL_BAD, fname, "0.8" if strict else "0.15"])
			apply_fx({"support": {"Бизнес": (-0.3 if not strict else -0.4) * wdt}})
		return
	if not wmonth:
		if brake_over >= 6:
			capital -= 0.8 * wdt
			add_support("Бизнес", -0.4 * wdt)
			add_support("Пенсионеры", -0.2 * wdt)
		return
	if brake_over == 3:
		log_line("[color=%s][b]Долговой тормоз:[/b] дефицит %.1f%% ВВП выше допустимых %.1f%%. Федеральное министерство финансов и Конституционный суд предупреждают правительство.[/color]" % [COL_WARN, deficit_pct, brake_allowed()])
	elif brake_over >= 6:
		capital -= 0.8 * wdt
		if brake_over % 6 == 0:
			log_line("[color=%s][b]Нарушение долгового тормоза.[/b] Суд требует сократить дефицит (политкапитал -0.8 в месяц, доверие рынков падает).[/color]" % COL_BAD)
		apply_fx({"support": {"Бизнес": -0.4 * wdt, "Пенсионеры": -0.2 * wdt}})


# 0.62: недельный тик долгового тормоза: дефицит по текущему бюджету
func brake_week() -> void:
	var b := compute_budget()
	brake_step(-float(b["balance"]) / gdp * 100.0)


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
	"GB": ["Досрочные всеобщие выборы", "Премьер-министр просит короля распустить парламент; по истечении пяти лет парламент распускается автоматически.", 0.0, ""],
	"IE": ["Роспуск Дойла", "Премьер (тишах) просит президента распустить Дойл.", 0.0, ""],
	"SI": ["Досрочные выборы в Государственное собрание", "Президент распускает собрание, если правительство проигрывает вотум доверия.", 0.0, ""],
	"SK": ["Сокращение срока Национального совета", "Национальный совет может сократить свой срок решением 3/5 депутатов.", 0.6, "нужно 3/5 совета"],
	"HU": ["Самороспуск Государственного собрания", "Собрание может распустить себя большинством голосов депутатов.", 0.5, "нужно большинство собрания"],
	"FI": ["Досрочные выборы в эдускунту", "Президент по предложению премьер-министра назначает досрочные выборы.", 0.0, ""],
	"RS": ["Роспуск Народной скупщины", "Президент Республики по обоснованному предложению правительства распускает Народную скупщину и назначает выборы (не в период чрезвычайного положения и не в течение 90 дней после избрания правительства).", 0.0, ""],
	"BG": ["Досрочные выборы в Народное собрание", "Народное собрание не может распустить себя само: если правительство уходит в отставку, а три мандата на формирование кабинета (первой, второй и выбранной президентом партии) не дают правительства, президент назначает служебное правительство, распускает собрание и назначает выборы в течение двух месяцев.", 0.0, ""],
	"HR": ["Самороспуск Сабора", "Сабор может распустить себя решением большинства всех депутатов (76 из 151); кроме того, президент распускает Сабор, если за 30 дней после вотума недоверия не сформировано правительство или не принят бюджет.", 0.5, "нужно большинство Сабора"],
	"AL": ["Роспуск Народного собрания", "Самороспуска нет: президент распускает Собрание, если правительство проигрывает вотум доверия, а депутаты за 15 дней не избирают нового премьер-министра (или если Собрание не может избрать президента). Премьер с большинством может сознательно проиграть вопрос о доверии.", 0.0, ""],
	"ME": ["Сокращение мандата Скупщины", "Скупщина может досрочно прекратить свои полномочия решением большинства депутатов (41 из 81); кроме того, президент распускает её, если новое правительство не избрано в течение 90 дней.", 0.5, "нужно большинство Скупщины"],
	"XK": ["Роспуск Собрания", "Собрание распускается решением 2/3 всех депутатов по предложению президента или правительства; кроме того, президент обязан объявить выборы, если правительство не удалось сформировать.", 0.667, "нужно 2/3 Собрания"],
	"RO": ["Роспуск Парламента президентом", "Президент может распустить Парламент, только если тот в течение 60 дней после первого запроса и минимум после двух голосований отказал в доверии новому правительству (ст. 89 Конституции); не чаще раза в год и не в последние 6 месяцев полномочий президента. Самороспуска нет.", 0.5, "нужно, чтобы большинство палат дважды отказало в доверии правительству"],
	"EE": ["Досрочные выборы в Рийгикогу", "Рийгикогу не может распустить себя сам: президент назначает внеочередные выборы, если парламент не принял бюджет в течение двух месяцев, не поддержал вынесенный на референдум закон, четырежды не смог утвердить премьер-министра или если после вотума недоверия правительство предлагает президенту роспуск.", 0.0, ""],
	"LV": ["Досрочные выборы в Сейм", "Президент может предложить роспуск Сейма, но тогда проводится референдум: если большинство против роспуска, уходит в отставку сам президент. Роспуск Сейма можно также инициировать подписями 1/10 избирателей с последующим референдумом. Сейм сам себя распустить не может.", 0.0, ""],
	"LT": ["Досрочные выборы в Сейм", "Сейм может объявить досрочные выборы решением 3/5 своих членов (85 голосов из 141). Президент вправе распустить Сейм, если тот в течение 30 дней не рассмотрел программу нового правительства или дважды подряд её не одобрил, а также по предложению правительства, которому отказано в доверии; вновь избранный Сейм в таком случае может назначить досрочные выборы президента.", 0.6, "нужно 3/5 Сейма"],
	"GR": ["Досрочные выборы в Парламент", "Президент распускает Парламент по предложению правительства, получившего вотум доверия, «для обновления мандата по вопросу национальной важности» или если правительства подряд уходят в отставку и Парламент не может обеспечить стабильность. На практике выборы назначает премьер-министр.", 0.0, ""],
	"BA": ["", "Конституция БиГ не знает роспуска государственного парламента: Палата представителей и Президиум работают до конца четырёхлетнего срока, а при кризисе Совет министров остаётся исполняющим обязанности. Досрочные выборы возможны только в энтити (так было в Республике Сербской в 2025 году).", -1.0, ""],
	"MD": ["Роспуск Парламента", "Президент распускает Парламент, если тот в течение 45 дней не выразил доверия правительству и отклонил не менее двух запросов о доверии; в последние 6 месяцев мандата президента роспуск запрещён.", 0.0, ""],
	"UA": ["Досрочное прекращение полномочий Рады", "Президент прекращает полномочия Верховной Рады, если за месяц не сформирована коалиция депутатских фракций; при военном положении выборы невозможны.", 0.0, ""],
	"BY": ["Роспуск Палаты представителей", "Президент после консультаций с председателями палат распускает Палату представителей и назначает выборы.", 0.0, ""],
	"RU": ["Роспуск Государственной думы", "Президент распускает Думу, если она трижды отклонила кандидатуру премьера или выразила недоверие правительству повторно.", 0.0, ""],
	"MK": ["Самороспуск Собрания", "Собрание может распустить себя решением большинства от общего числа депутатов (61 из 120); по договорённости партий за 100 дней до выборов формируется «техническое» правительство с министрами внутренних дел и труда от оппозиции.", 0.5, "нужно большинство депутатов (61 из 120)"],
}


func snap_info() -> Dictionary:
	if martial_on():
		return {"name": "Досрочные выборы невозможны", "desc": "Действует военное положение: роспуск парламента запрещён.", "need": 0.0, "vote": "", "ok": false, "why": "Действует военное положение: роспуск парламента и выборы запрещены."}
	var r: Array = SNAP_RULES.get(ccode, SNAP_RULES["DE"])
	var ok: bool = float(r[2]) >= 0.0
	# 0.58: в Италии и Португалии президент не может распускать парламент в последние 6 месяцев своего мандата
	if ok and ccode in ["IT", "PT"] and pres_due >= 0 and pres_due - turn <= 6:
		return {"name": "Досрочные выборы невозможны", "desc": String(r[1]), "need": 0.0, "vote": "", "ok": false,
			"why": "В последние 6 месяцев мандата президента парламент распустить нельзя (осталось %d мес.)." % maxi(0, pres_due - turn)}
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
