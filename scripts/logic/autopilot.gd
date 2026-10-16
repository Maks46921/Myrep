# Помощник и автопилот.
extends "res://scripts/logic/agents.gd"

func ap_can_adj(key: String, d: float) -> bool:
	if lock_active(key):
		return false
	var def: Dictionary = policy_by_key[key]
	var nv: float = float(pol[key]) + d
	# 0.55.5: пределов нет; помощник не выходит за обычный диапазон сам, но может вернуть ставку в него
	return nv >= -0.0001 and (nv <= float(def["max"]) + 0.0001 or d < 0.0)


func ap_note_change(key: String, d: float) -> void:
	ap_log[key] = float(ap_log.get(key, 0.0)) + d


func ap_flush_log() -> void:
	if ap_log.is_empty():
		return
	var parts: PackedStringArray = []
	for k in ap_log:
		if absf(float(ap_log[k])) >= 0.05:
			parts.append("«%s» %s п.п. ВВП" % [policy_title(k), sg(float(ap_log[k]), 1)])
	ap_log.clear()
	if parts.size() > 0:
		log_tag("АВТОПИЛОТ", COL_TEAL, "автобаланс подстроил бюджет: %s" % ", ".join(parts))


func autobalance_step(target: float = -1.0, big: bool = false) -> bool:
	var tgt: float = float(ap["target"]) if target < 0.0 else target
	var b := compute_budget()
	var def: float = -float(b["balance"]) / gdp * 100.0
	var diff: float = def - tgt
	if absf(diff) < (0.5 if target < 0.0 else 0.15):
		return false
	var st: float = 0.2 if (absf(diff) > 1.5 or big) else 0.1
	if diff > 0.0:
		for key in ["vat", "income", "social", "corp"]:
			if ap_can_adj(key, st):
				set_policy(key, float(pol[key]) + st)
				ap_note_change(key, st)
				return true
	elif debt / gdp * 100.0 < 70.0:
		for key in ["income", "social", "vat", "corp"]:
			if ap_can_adj(key, -st):
				set_policy(key, float(pol[key]) - st)
				ap_note_change(key, -st)
				return true
	return false


func balance_now() -> void:
	if pl_deny(): return
	if game_over:
		return
	var n := 0
	for i in 60:
		if not autobalance_step(0.3, true):
			break
		n += 1
	ap_flush_log()
	if n == 0:
		log_tag("АВТОПИЛОТ", COL_TEAL, "бюджет уже близок к балансу или налоги упёрлись в ограничения.")
	prev_pol = pol.duplicate()
	refresh()


func apply_preset(id: String) -> void:
	if pl_deny(): return
	if game_over:
		return
	var pr: Dictionary = PRESETS[id]
	var parts: PackedStringArray = []
	for k in pr["vals"]:
		if lock_active(k):
			continue
		var old: float = float(pol[k])
		set_policy(k, float(pr["vals"][k]))
		if absf(float(pol[k]) - old) >= 0.05:
			parts.append("«%s» %.1f → %.1f" % [policy_title(k), old, float(pol[k])])
	log_tag("АВТОПИЛОТ", COL_TEAL, "%s: %s." % [pr["name"], ", ".join(parts) if parts.size() > 0 else "ничего не изменилось"])
	prev_pol = pol.duplicate()
	refresh()


func fx_score(fx: Dictionary, style: int) -> float:
	var wd: float = [2.0, 0.6, 1.0][style]
	var ws: float = [0.5, 1.0, 0.35][style]
	var we: float = [0.3, 0.3, 1.0][style]
	var s := 0.0
	s -= float(fx.get("debt", 0.0)) * wd * 2.0
	s -= float(fx.get("infl", 0.0)) * 2.0
	s -= float(fx.get("unemp", 0.0)) * 2.5
	s += float(fx.get("shock", 0.0)) * 3.0 * (1.5 if style == 2 else 1.0)
	s += float(fx.get("all", 0.0)) * ws * 4.0
	for g in fx.get("support", {}):
		var m := 1.0
		if style == 2 and g == "Бизнес":
			m = 2.0
		s += float(fx["support"][g]) * ws * m
	if fx.has("slider"):
		s -= 3.0 * float((fx["slider"] as Dictionary).size()) * (1.0 if style == 0 else 0.4)
	for k in fx.get("state", {}):
		var v: float = float(fx["state"][k])
		s += (-v if k == "corruption" else v) * 0.8
	var ec_fx: Dictionary = fx.get("econ", {})
	s += float(ec_fx.get("bc", 0.0)) * 0.4 * we + float(ec_fx.get("cc", 0.0)) * 0.2 + float(ec_fx.get("inv", 0.0)) * 100.0 * 0.6 * we
	s += float(ec_fx.get("wd", 0.0)) * 0.2 + float(ec_fx.get("fxs", 0.0)) * 0.05
	for m2 in ec_fx.get("k", {}):
		s += float(ec_fx["k"][m2]) * 20.0 * we
	for m3 in ec_fx.get("p", {}):
		s -= float(ec_fx["p"][m3]) * 6.0
	s += float(fx.get("capital", 0.0)) * 0.2
	return s


func auto_event_pick(ev: Dictionary) -> int:
	var best := 0
	var bs := -1e9
	var opts: Array = ev["o"]
	for i in opts.size():
		var sc := fx_score(opts[i]["fx"], int(ap["style"]))
		if sc > bs:
			bs = sc
			best = i
	return best


func auto_event_ok(ev: Dictionary) -> bool:
	return bool(ap["events"]) and not ev.has("special")  and event_party < 0 and event_min < 0


func auto_resolve_event() -> void:
	var i := auto_event_pick(current_event)
	var opt: Dictionary = current_event["o"][i]
	var gov_pm: int = int(opp_gov["pm"]) if (opp_mode and not opp_gov.is_empty()) else -1
	var old_cap := cap_swap(gov_pm) if gov_pm >= 0 else 0.0
	log_tag("СОБЫТИЕ", COL_WARN, "%s — %s" % [date_text(), current_event["t"].replace("{r}", String(REGIONS[event_region]["name"]) if event_region >= 0 else "")])
	log_tag("АВТОПИЛОТ", COL_TEAL, "выбран вариант «%s» (стиль: %s)." % [opt["l"], String(AP_STYLES[int(ap["style"])]).to_lower()])
	choose(i)
	if gov_pm >= 0:
		cap_unswap(gov_pm, old_cap)


func autobuild_step() -> void:
	if ec.is_empty() or debt / gdp * 100.0 > 85.0:
		return
	var active := 0
	for r in regions:
		if not (r["proj"] as Dictionary).is_empty():
			active += 1
	if active >= 3:
		return
	var mk: Dictionary = ec["mk"]
	var best := ""
	var bu := 0.0
	for id in mk:
		var u: float = float(mk[id]["u"]) + float(mk[id]["short"]) * 3.0
		if u > bu:
			bu = u
			best = id
	if best == "" or bu < 0.96:
		return
	var pid: String = AP_BUILD_MAP[best]
	var ri := -1
	var bd := 1000.0
	for i in regions.size():
		if (regions[i]["proj"] as Dictionary).is_empty() and float(regions[i]["dev"]) < bd:
			bd = float(regions[i]["dev"])
			ri = i
	if ri < 0:
		return
	var old_sel := selected_region
	var old_opt: int = proj_option.selected
	selected_region = ri
	for k in PROJECTS.size():
		if PROJECTS[k]["id"] == pid:
			proj_option.select(k)
	start_project()
	selected_region = old_sel
	proj_option.select(old_opt)
	log_tag("АВТОПИЛОТ", COL_TEAL, "спрос на рынке «%s» превышает мощности — начато строительство в регионе «%s»." % [String(mk_def(best)["name"]).to_lower(), REGIONS[ri]["name"]])


func autopilot_step() -> void:
	if bool(ap["bal"]):
		autobalance_step()
	if turn % 3 == 0:
		ap_flush_log()
		if bool(ap["repair"]) and not ec.is_empty() and debt / gdp * 100.0 < 90.0:
			var total := 0
			var cs := 0.0
			for i in regions.size():
				for id in regions[i]["built"]:
					total += int(regions[i]["built"][id]["n"])
					cs += float(regions[i]["built"][id]["cond"]) * float(regions[i]["built"][id]["n"])
			if total > 0 and cs / float(total) < 60.0:
				repair_all()
		if bool(ap["build"]):
			autobuild_step()


# ---------- v50: стиль правления партий ----------
# Стиль выводится из электората партии (идеология) и черты лидера; сила стиля — от власти лидера:
# черта («идеолог» жёстче, «прагматик» мягче) и вес партии в правительстве.
const GOV_STYLES := ["Осторожный", "Народный", "Деловой"]


func party_style(p: int) -> Dictionary:
	var soc := 0.0
	var biz := 0.0
	var tot := 0.0
	for g in GROUPS:
		var w: float = float(LEAN[g][p]) * float(GROUP_WEIGHT[g])
		tot += w
		if g == "Рабочие" or g == "Пенсионеры" or g == "Бюджетники" or g == "Село":
			soc += w
		elif g == "Бизнес":
			biz += w * 2.2
	var st := 0
	if soc / maxf(tot, 1e-6) > 0.62 and soc > biz * 1.5:
		st = 1
	elif biz > soc * 0.55:
		st = 2
	var tr: String = String((PARTY_TRAITS[p] as Dictionary).get("trait", "")) if p < PARTY_TRAITS.size() else ""
	var k: float = 1.3 if tr == "идеолог" else (0.75 if tr == "прагматик" else 1.0)
	var gs: float = float(seats[p]) / float(maxi(1, gov_seats() if not opp_mode else int(opp_gov.get("seats", SEATS))))
	var power: float = clampf(k * (0.55 + 0.7 * gs), 0.3, 1.5)
	var desc: String = ["бережёт бюджет: держит дефицит ниже, резких шагов не делает",
		"щедр к людям: поднимает пенсии и пособия, при нехватке денег — налог на прибыль",
		"за рост и бизнес: снижает налог на прибыль и подоходный, урезает пособия при дефиците"][st]
	return {"st": st, "name": GOV_STYLES[st], "power": power, "desc": desc, "trait": tr}


func party_style_text(p: int) -> String:
	var d := party_style(p)
	return "Стиль правления: [b]%s[/b] (сила %.1f) — %s." % [d["name"], float(d["power"]), d["desc"]]


# ИИ-правительство (вы вне власти) правит в своём стиле: раз в месяц один небольшой шаг, суммарно не больше «силы» п.п. ВВП на статью
var gs_drift := {}


func gov_style_step() -> void:
	if not opp_mode or opp_gov.is_empty() or game_over:
		return
	var pm: int = int(opp_gov["pm"])
	if int(gs_drift.get("_pm", -1)) != pm:
		gs_drift = {"_pm": pm}
	var d := party_style(pm)
	var st: int = int(d["st"])
	ap["style"] = st
	ap["target"] = 0.3 if st == 0 else (1.2 if st == 1 else 0.8)
	var lim: float = float(d["power"])
	var b := compute_budget()
	var def: float = -float(b["balance"]) / gdp * 100.0
	var moves: Array = []
	if st == 1:
		moves = [["pensions", 0.05], ["benefits", 0.05]]
		if def > 3.0:
			moves = [["corp", 0.05]]
	elif st == 2:
		moves = [["corp", -0.05], ["income", -0.05]]
		if def > 3.0:
			moves = [["benefits", -0.05]]
	for mv in moves:
		var key: String = mv[0]
		var dv: float = mv[1]
		if not policy_by_key.has(key):
			continue
		var cur: float = float(gs_drift.get(key, 0.0))
		if absf(cur + dv) > lim or not ap_can_adj(key, dv):
			continue
		set_policy(key, float(pol[key]) + dv)
		gs_drift[key] = cur + dv
		return


func advisor_lines() -> Array:
	var out: Array = []
	var b := compute_budget()
	var def: float = -float(b["balance"]) / gdp * 100.0
	var dr: float = debt / gdp * 100.0
	if def > 3.0:
		out.append([3, "Дефицит бюджета %.1f%% ВВП. Поднимите налоги или урежьте расходы (кнопка «Сбалансировать налоги сейчас» в окне бюджета)." % def])
	elif def > 1.5:
		out.append([2, "Дефицит %.1f%% ВВП: долг растёт." % def])
	if dr > 100.0:
		out.append([3, "Долг %.0f%% ВВП — близко к дефолту (150%%). Нужны сокращения или налоги." % dr])
	elif dr > 80.0:
		out.append([2, "Долг %.0f%% ВВП: проценты съедают бюджет." % dr])
	if inflation > 8.0:
		out.append([3, "Инфляция %.1f%%: уберите эмиссию, проверьте ключевую ставку и дефицит." % inflation])
	elif inflation > 6.0:
		out.append([2, "Инфляция %.1f%% выше нормы." % inflation])
	if unemployment > 9.0:
		out.append([3, "Безработица %.1f%%: нужны рост, строительство и субсидии." % unemployment])
	elif unemployment > 7.0:
		out.append([2, "Безработица %.1f%% повышена." % unemployment])
	if approval() < 40.0:
		out.append([3, "Рейтинг %.0f%%: ниже 25%% три месяца подряд — вас свергнут. Поддержите группы." % approval()])
	elif approval() < 50.0:
		out.append([2, "Рейтинг %.0f%% — ниже 50%%, выборы под угрозой." % approval()])
	if not minority_ok and gov_seats() < MAJORITY:
		out.append([3, "У коалиции нет большинства (%d из %d): законы не пройдут. Откройте «Политика → Правительство»." % [gov_seats(), SEATS]])
	if not ec.is_empty():
		var mk: Dictionary = ec["mk"]
		for m in MARKETS:
			if float(mk[m["id"]]["short"]) > 0.02:
				out.append([2, "Дефицит на рынке «%s»: стройте мощности (вкладка «Карта») или включите автостроительство." % String(m["name"]).to_lower()])
		if float(ec["util"]) < 0.78:
			out.append([1, "Мощности простаивают (%.0f%%): стимулируйте спрос — госзаказ, субсидии, низкая ставка." % (float(ec["util"]) * 100.0)])
		if float(ec["bconf"]) < 35.0:
			out.append([2, "Бизнес не хочет инвестировать (климат %.0f). Причины — на вкладке «Экономика»." % float(ec["bconf"])])
		if float(ec["res"]) < 3.0:
			out.append([2, "Резервы почти кончились: валюта уязвима."])
		var total := 0
		var cs := 0.0
		for i in regions.size():
			for id in regions[i]["built"]:
				total += int(regions[i]["built"][id]["n"])
				cs += float(regions[i]["built"][id]["cond"]) * float(regions[i]["built"][id]["n"])
		if total > 0 and cs / float(total) < 55.0:
			out.append([1, "Сооружения изношены (%.0f%%): отремонтируйте их на вкладке «Экономика»." % (cs / float(total))])
	if capital > 60.0:
		out.append([1, "Накоплено %.0f политкапитала — можно менять законы или проводить действия." % capital])
	if out.is_empty():
		out.append([0, "Всё спокойно. Пусть время идёт или включите «Авто»."])
	out.sort_custom(func(a, c): return int(a[0]) > int(c[0]))
	return out
