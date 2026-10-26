# 0.65: верхняя палата во всех странах. У каждой страны свои правила: преодоление отказа (сразу или с задержкой),
# согласительная комиссия, независимость региональных делегаций, роль в формировании правительства, способ формирования
# и обновления. Есть «индекс конфликта палат», требования палаты и конституционная реформа: создать палату, упразднить её,
# изменить полномочия или способ формирования (нужно конституционное большинство, а согласие самой палаты — по шансу).
# Правила палат взяты из реальности (Бундесрат, Сенат Франции, Палата лордов, Совет Федерации и др.), см. UP65_META.
extends "res://scripts/logic/move65.gd"

# способ формирования палаты
const UP65_FORM := {
	"direct": "прямые выборы",
	"regional": "делегаты регионов (правительства и собрания земель)",
	"indirect": "косвенные выборы (выборщики)",
	"mixed": "смешанный порядок",
	"appointed": "назначение (глава государства или правительство)",
	"corporate": "представители профессий и общественных групп",
}
const UP65_FORM_DEF := {
	"direct": {"ind": 0.05, "reg": false, "tilt": 0.25},
	"regional": {"ind": 0.12, "reg": true, "tilt": 0.6},
	"indirect": {"ind": 0.04, "reg": true, "tilt": 0.15},
	"mixed": {"ind": 0.08, "reg": true, "tilt": 0.3},
	"appointed": {"ind": 0.06, "reg": false, "tilt": 0.0},
	"corporate": {"ind": 0.15, "reg": false, "tilt": 0.1},
}
const UP65_POW := {
	"none": "почти без полномочий",
	"override": "отлагательное вето",
	"consent": "согласие на законы о регионах",
	"full": "равноправная с нижней палатой",
}
const UP65_POW_RANK := {"none": 0, "override": 1, "consent": 2, "full": 3}
const UP65_POW_DEF := {
	"none": {"ovr": -1.0, "slow": 0, "conc": false},
	"override": {"ovr": 0.5, "slow": 2, "conc": false},
	"consent": {"ovr": 0.5, "slow": 0, "conc": true},
	"full": {"ovr": -1.0, "slow": 0, "conc": true},
}
const UP65_NAMES := {"direct": "Сенат", "indirect": "Сенат", "mixed": "Сенат", "regional": "Совет регионов", "appointed": "Палата старейшин", "corporate": "Палата профессий"}

# ovr — доля мест нижней палаты, которой хватает, чтобы преодолеть отказ сразу (-1: такого способа нет);
# slow — на сколько месяцев откладывается закон, если нижняя палата преодолевает отказ простым большинством (0: так нельзя);
# conc — есть ли согласительная комиссия; ind — доля «своих» мест, которая голосует по-своему (регионы, фракции);
# reg — палата представляет регионы; tilt — как сильно итоги региональных выборов следуют за рейтингом власти;
# GB: по Актам о парламенте задержка до года, но на практике Лорды уступают после двух-трёх раундов правок (принцип Солсбери), поэтому 4 мес.;
# role — "conf": правительство зависит от доверия палаты; app — власть может назначать новых членов.
const UP65_META := {
	"AT": {"form": "regional", "ovr": -1.0, "slow": 1, "conc": false, "ind": 0.10, "reg": true, "tilt": 0.7, "role": "", "app": false},
	"BA": {"form": "regional", "ovr": -1.0, "slow": 0, "conc": true, "ind": 0.14, "reg": true, "tilt": 0.2, "role": "", "app": false},
	"BE": {"form": "mixed", "ovr": -1.0, "slow": 0, "conc": false, "ind": 0.05, "reg": true, "tilt": 0.0, "role": "", "app": false},
	"BY": {"form": "appointed", "ovr": -1.0, "slow": 0, "conc": true, "ind": 0.0, "reg": true, "tilt": 0.0, "role": "", "app": true},
	"CH": {"form": "direct", "ovr": -1.0, "slow": 0, "conc": true, "ind": 0.18, "reg": true, "tilt": 0.0, "role": "", "app": false},
	"CZ": {"form": "direct", "ovr": 0.505, "slow": 0, "conc": false, "ind": 0.12, "reg": false, "tilt": 0.0, "role": "", "app": false},
	"DE": {"form": "regional", "ovr": 0.5, "slow": 0, "conc": true, "ind": 0.15, "reg": true, "tilt": 0.8, "role": "", "app": false},
	"ES": {"form": "mixed", "ovr": 0.5, "slow": 2, "conc": true, "ind": 0.10, "reg": true, "tilt": 0.0, "role": "", "app": false},
	"FR": {"form": "indirect", "ovr": -1.0, "slow": 2, "conc": true, "ind": 0.04, "reg": true, "tilt": 0.0, "role": "", "app": false},
	"GB": {"form": "appointed", "ovr": -1.0, "slow": 4, "conc": false, "ind": 0.12, "reg": false, "tilt": 0.0, "role": "", "app": true},
	"IE": {"form": "corporate", "ovr": -1.0, "slow": 3, "conc": false, "ind": 0.12, "reg": false, "tilt": 0.0, "role": "", "app": true},
	"IT": {"form": "direct", "ovr": -1.0, "slow": 0, "conc": false, "ind": 0.05, "reg": false, "tilt": 0.0, "role": "conf", "app": false},
	"NL": {"form": "indirect", "ovr": -1.0, "slow": 0, "conc": false, "ind": 0.03, "reg": true, "tilt": 0.0, "role": "", "app": false},
	"RO": {"form": "direct", "ovr": -1.0, "slow": 0, "conc": true, "ind": 0.05, "reg": false, "tilt": 0.0, "role": "conf", "app": false},
	"RU": {"form": "regional", "ovr": 0.667, "slow": 0, "conc": true, "ind": 0.03, "reg": true, "tilt": 0.05, "role": "", "app": true},
	"SI": {"form": "corporate", "ovr": 0.51, "slow": 0, "conc": false, "ind": 0.20, "reg": false, "tilt": 0.1, "role": "", "app": false},
}

const UP65_CONSENT_IDS := ["state_structure", "regional_gov", "regional_policy", "federal_overhaul"]


func up65_on() -> bool:
	return int(game_opts.get("up65", 1)) != 0


func up65_ensure() -> void:
	if up65.is_empty() or String(up65.get("cc", "")) != ccode or not up65.has("conf"):
		up65 = {"cc": ccode, "conf": 8.0, "tilt": 0.0, "q": [], "log": [], "dem": {}, "rcd": -99, "tcd": -99, "pcd": -99, "dcd": -99,
			"loy_until": -1, "pack": 0, "mo": {}, "cm": [0, 0], "blk": 0, "ovr": 0}


func up65_meta() -> Dictionary:
	up65_ensure()
	var m: Dictionary = (UP65_META.get(ccode, {}) as Dictionary).duplicate()
	var mo: Dictionary = up65["mo"]
	if not mo.is_empty():
		m.merge(mo, true)
	return m


func up65_active() -> bool:
	return up65_on() and upper_on()


func up65_share() -> float:
	if not upper_on():
		return 0.0
	return float(upper_gov()) / maxf(1.0, float(UPPER["total"]))


func up65_log(s: String) -> void:
	up65_ensure()
	var l: Array = up65["log"]
	l.append(date_text() + ": " + s)
	if l.size() > 14:
		l.pop_front()


func up65_grievance() -> float:
	var s := 0.0
	var w := 0.0
	for r in regions:
		var pw: float = float(r.get("popm", 1.0))
		s += clampf((58.0 - float(r.get("loy", 58.0))) / 58.0, 0.0, 1.0) * pw
		w += pw
	return s / w if w > 0.0 else 0.0


# доля «своих» мест, голосующих по-своему
func up65_def_rate(m: Dictionary) -> float:
	var r: float = float(m.get("ind", 0.0))
	if r <= 0.0:
		return 0.0
	r *= 0.55 + float(up65["conf"]) / 100.0 * 0.9
	if bool(m.get("reg", false)):
		r *= 1.0 + up65_grievance() * 0.9
	if int(up65.get("loy_until", -1)) >= turn:
		r *= 0.25
	return clampf(r, 0.0, 0.45)


# места палаты, которые голосуют «за» закон благодаря партиям коалиции
func up65_aligned_yes(tid: String, idx: int, forced: Array) -> int:
	var all_mode: bool = String(UPPER.get("mode", "")) == "all"
	var okp := {}
	for p in PARTY_NAMES.size():
		if p == 0 or in_coalition[p]:
			var s := variant_stance(p, tid, idx)
			okp[p] = p == 0 or s >= 0.0 or s >= -1.0 or (p in forced)
	var yes := 0
	for bl in UPPER["blocs"]:
		var ps: Array = bl[1]
		var n_ok := 0
		for p in ps:
			if bool(okp.get(int(p), false)):
				n_ok += 1
		var good: bool = (n_ok == ps.size()) if all_mode else (n_ok * 2 >= ps.size())
		if good:
			yes += int(bl[0])
	return yes


func upper_check(tid: String, idx: int, forced: Array = []) -> Dictionary:
	var res: Dictionary = upper_check_base(tid, idx, forced)
	if not bool(res.get("on", false)) or String(res.get("kind", "")) == "veto" or not up65_active():
		return res
	var m: Dictionary = up65_meta()
	var kind: String = String(res["kind"])
	var total: int = int(res["total"])
	var yes: int = int(res["yes"])
	var conf: float = float(up65["conf"])
	var loss := 0.0
	var al := 0
	var dr := up65_def_rate(m)
	var tl: float = float(up65.get("tilt", 0.0))
	if dr > 0.0 or absf(tl) > 0.001:
		al = mini(up65_aligned_yes(tid, idx, forced), yes)
		loss += float(al) * dr
		if tl >= 0.0:
			loss += float(al) * tl
		else:
			loss += tl * float(total - yes) * 0.4
	yes = clampi(yes - int(round(loss)), 0, total)
	var need: int = int(res["need"])
	var passed: bool = yes >= need
	res["yes"] = yes
	res["passed"] = passed
	res["block"] = false
	res["extra"] = 0.0
	var fund_bind: bool = is_fund(tid) and kind in ["override", "consent"] and not (ccode in ["GB", "IE", "SI"])
	if passed:
		res["extra"] = conf * 0.03
		return res
	if kind == "full" or (kind == "consent" and bool(res.get("binding", true))) or fund_bind:
		res["block"] = true
		return res
	# отказ можно преодолеть: сразу (если хватает мест нижней палаты), с задержкой или никак
	var ly: int = int(variant_votes(tid, idx, forced)["yes"])
	var ovr: float = float(m.get("ovr", -1.0))
	var slow: int = int(m.get("slow", 0))
	var ex: float = 5.0 + conf * 0.06
	if ovr > 0.0 and ly >= int(ceil(ovr * float(SEATS))):
		res["extra"] = ex
		res["ovr"] = "fast"
	elif slow > 0:
		res["extra"] = ex
		res["delay"] = slow
		res["ovr"] = "slow"
	else:
		res["block"] = true
		res["ovr"] = "no"
		res["need_low"] = int(ceil(ovr * float(SEATS))) if ovr > 0.0 else SEATS
		res["have_low"] = ly
	return res


func upper_text(up: Dictionary) -> String:
	var t: String = upper_text_base(up)
	if t == "" or String(up.get("kind", "")) == "veto":
		return t
	match String(up.get("ovr", "")):
		"fast":
			t += "; нижняя палата преодолеет отказ сразу"
		"slow":
			t += "; закон вступит в силу только через %d мес." % int(up.get("delay", 0))
		"no":
			t += "; чтобы преодолеть отказ, в нижней палате нужно %d голосов, есть %d" % [int(up.get("need_low", 0)), int(up.get("have_low", 0))]
	return t


# --- согласительная комиссия (при блокировке закона палатой) ---
func up65_conciliate(tid: String, idx: int, upc: Dictionary) -> Dictionary:
	var out := {"ok": false, "msg": ""}
	if not up65_active():
		return out
	var m: Dictionary = up65_meta()
	if not bool(m.get("conc", false)):
		return out
	var conf: float = float(up65["conf"])
	var p: float = 0.62 - conf / 100.0 * 0.45 + (up65_share() - 0.35) * 0.5
	if is_fund(tid):
		p *= 0.6
	p = clampf(p, 0.08, 0.9)
	var cm: Array = up65["cm"]
	if randf() < p:
		cm[0] = int(cm[0]) + 1
		var u2: Dictionary = upc.duplicate()
		u2["block"] = false
		u2["passed"] = true
		u2["extra"] = float(upc.get("extra", 0.0)) + 3.0 + conf * 0.04
		up65["conf"] = maxf(0.0, conf - 3.0)
		out["ok"] = true
		out["upc"] = u2
		out["msg"] = "Согласительная комиссия палат нашла компромисс (шанс был %.0f%%): закон уточнён, цена выше на %.0f" % [p * 100.0, float(u2["extra"]) - float(upc.get("extra", 0.0))]
		up65_log("комиссия палат согласовала закон «%s»." % law_index[tid]["name"])
		log_tag("ВЕРХНЯЯ ПАЛАТА", COL_GOOD, "%s. Закон «%s» идёт дальше." % [out["msg"], law_index[tid]["name"]])
	else:
		cm[1] = int(cm[1]) + 1
		up65["conf"] = minf(100.0, conf + 5.0)
		law_cd[tid] = 3
		out["msg"] = "Согласительная комиссия палат не договорилась (шанс был %.0f%%)" % (p * 100.0)
		up65_log("комиссия палат не согласовала закон «%s»." % law_index[tid]["name"])
	return out


func up65_note_block(tid: String) -> void:
	up65_ensure()
	up65["blk"] = int(up65.get("blk", 0)) + 1
	up65["conf"] = minf(100.0, float(up65["conf"]) + 7.0)
	up65_log("палата заблокировала закон «%s»." % law_index[tid]["name"])


func up65_note_override(tid: String, delayed: bool) -> void:
	up65_ensure()
	up65["ovr"] = int(up65.get("ovr", 0)) + 1
	up65["conf"] = minf(100.0, float(up65["conf"]) + 3.0)
	up65_log("нижняя палата преодолела отказ по закону «%s»%s." % [law_index[tid]["name"], " (с задержкой)" if delayed else ""])


# --- отложенные законы (отлагательное вето) ---
func up65_delay_law(tid: String, idx: int, cost: float, delay: int, v: Dictionary) -> void:
	up65_ensure()
	capital -= cost
	var q: Array = up65["q"]
	q.append({"tid": tid, "idx": idx, "due": turn + delay, "cost": cost, "sp": vote_sponsor, "yes": int(v.get("yes", 0)), "no": int(v.get("no", 0)), "abst": int(v.get("abst", 0))})
	law_cd[tid] = delay + 1
	up65_note_override(tid, true)
	log_tag("ВЕРХНЯЯ ПАЛАТА", COL_WARN, "%s отклонила закон «%s», нижняя палата преодолела отказ: закон вступит в силу через %d мес. (политкапитал -%.0f)." % [String(UPPER.get("name", "Палата")), law_index[tid]["name"], delay, cost])
	if not last_vote.is_empty():
		(last_vote["extra"] as Array).append(["Верхняя палата отложила вступление закона на %d мес." % delay, true])
		last_vote["final"] = "ПРИНЯТ, ВСТУПИТ В СИЛУ ЧЕРЕЗ %d МЕС." % delay
	vote_show()
	refresh()


func up65_flush(force: bool = false) -> void:
	up65_ensure()
	var q: Array = up65["q"]
	if q.is_empty():
		return
	var keep: Array = []
	for it in q:
		if not force and int(it["due"]) > turn:
			keep.append(it)
			continue
		var tid: String = String(it["tid"])
		if opp_mode or not law_index.has(tid) or int(it["idx"]) == cur_idx(tid):
			law_cd[tid] = 0
			continue
		var old_sp := vote_sponsor
		vote_sponsor = int(it["sp"])
		law_cd[tid] = 0
		law_apply(tid, int(it["idx"]), float(it["cost"]), {"yes": it["yes"], "no": it["no"], "abst": it["abst"]}, false, false)
		vote_sponsor = old_sp
	up65["q"] = keep


# --- ежемесячный ход палаты ---
func up65_g() -> float:
	if up65_active() and not up65.is_empty():
		return -clampf(float(up65.get("conf", 0.0)) - 50.0, 0.0, 50.0) * 0.004
	return 0.0


func up65_month() -> void:
	if not up65_on() or not wmonth or game_over:
		return
	up65_ensure()
	up65_flush()
	var conf: float = float(up65["conf"])
	if not upper_on() or opp_mode:
		up65["conf"] = maxf(0.0, conf - 2.0)
		if opp_mode:
			(up65["dem"] as Dictionary).clear()
		return
	var m: Dictionary = up65_meta()
	var share := up65_share()
	var kind: String = String(UPPER.get("kind", "none"))
	var kmul: float = {"none": 0.0, "override": 0.5, "consent": 0.8, "full": 1.0}.get(kind, 0.5)
	# конфликт растёт, пока у власти нет большинства в палате, и сам собой понемногу остывает
	if share < 0.5:
		conf += (0.15 + (0.5 - share) * 2.0) * kmul - conf * 0.012
	else:
		conf -= 1.8 + (share - 0.5) * 4.0
	if bool(m.get("reg", false)):
		conf += up65_grievance() * 1.0 * kmul
	conf = clampf(conf, 0.0, 100.0)
	up65["conf"] = conf
	# региональные выборы сдвигают состав палаты вслед за рейтингом власти
	var tlk: float = float(m.get("tilt", 0.0))
	if tlk > 0.0:
		var target: float = clampf((52.0 - mv_gov_rating()) / 100.0 * 1.2 * tlk, -0.25 * tlk, 0.35 * tlk)
		up65["tilt"] = float(up65["tilt"]) + (target - float(up65["tilt"])) * 0.08
	# требование палаты
	var dem: Dictionary = up65["dem"]
	if dem.is_empty():
		if conf >= 35.0 and share < 0.5 and turn >= int(up65["tcd"]) and kmul > 0.0:
			var reg_ok: bool = bool(m.get("reg", false))
			var cst: float = (5.0 + conf * 0.1) if reg_ok else (4.0 + conf * 0.12)
			dem = {"k": "regions" if reg_ok else "policy", "cost": cst, "due": turn + 6}
			up65["dem"] = dem
			up65_log("палата выдвинула требование.")
			log_tag("ВЕРХНЯЯ ПАЛАТА", COL_WARN, "%s выдвигает требование: %s. Ответить можно в окне «Верхняя палата»; срок — полгода, иначе конфликт усилится." % [String(UPPER.get("name", "Палата")), up65_dem_text(dem)])
	elif turn >= int(dem["due"]):
		up65["conf"] = minf(100.0, conf + 10.0)
		mv_gov_hit(-0.6)
		up65["dem"] = {}
		up65["tcd"] = turn + 8
		up65_log("требование палаты осталось без ответа: конфликт усилился.")
		log_tag("ВЕРХНЯЯ ПАЛАТА", COL_BAD, "%s: требование осталось без ответа, палата обвиняет правительство в неуважении, конфликт усилился." % String(UPPER.get("name", "Палата")))
	# доверие палаты (Италия, Румыния)
	if String(m.get("role", "")) == "conf" and share < 0.5 and conf >= 50.0 and not gov_blocked_for_nocon():
		if randf() < 0.01 + (conf - 50.0) * 0.002:
			log_tag("ВЕРХНЯЯ ПАЛАТА", COL_BAD, "Правительство потеряло опору в %s: оппозиция вносит вотум недоверия." % String(UPPER.get("name", "палате")))
			show_no_confidence()


func gov_blocked_for_nocon() -> bool:
	return opp_mode or turn - last_nocon < 18 or not current_event.is_empty() or not gov_ok()


func up65_dem_text(d: Dictionary) -> String:
	if String(d.get("k", "")) == "regions":
		return "больше денег и самостоятельности регионам (цена %.0f капитала)" % float(d["cost"])
	return "уступки по спорным законам (цена %.0f капитала)" % float(d["cost"])


func up65_dem_answer(yes: bool) -> void:
	up65_ensure()
	var dem: Dictionary = up65["dem"]
	if dem.is_empty():
		return
	if yes:
		capital -= float(dem["cost"])
		up65["conf"] = maxf(0.0, float(up65["conf"]) - 18.0)
		up65["loy_until"] = turn + 8
		if String(dem["k"]) == "regions":
			for r in regions:
				if not bool(r.get("terr", false)):
					r["loy"] = minf(100.0, float(r.get("loy", 50.0)) + 2.0)
		up65_log("правительство выполнило требование палаты.")
		log_tag("ВЕРХНЯЯ ПАЛАТА", COL_GOOD, "Правительство выполнило требование палаты (политкапитал -%.0f): конфликт ослаб, палата полгода уступчивее." % float(dem["cost"]))
	else:
		up65["conf"] = minf(100.0, float(up65["conf"]) + 8.0)
		up65["tcd"] = turn + 6
		up65_log("правительство отказало палате.")
		log_tag("ВЕРХНЯЯ ПАЛАТА", COL_BAD, "Правительство отказало палате: конфликт усилился.")
	up65["dem"] = {}
	refresh()


func up65_deal_cost() -> float:
	return 4.0 + float(up65.get("conf", 0.0)) * 0.08


func up65_deal_why() -> String:
	if opp_mode:
		return "вы в оппозиции"
	if not upper_on():
		return "палаты с полномочиями нет"
	if turn < int(up65.get("dcd", -99)):
		return "ещё %d мес." % (int(up65["dcd"]) - turn)
	return ""


# «договориться»: переговоры с фракциями палаты
func up65_deal() -> void:
	if up65_deal_why() != "":
		return
	var c := up65_deal_cost()
	capital -= c
	up65["conf"] = maxf(0.0, float(up65["conf"]) - 12.0)
	up65["loy_until"] = turn + 6
	up65["dcd"] = turn + 3
	up65_log("правительство договорилось с фракциями палаты.")
	log_tag("ВЕРХНЯЯ ПАЛАТА", COL_TEAL, "Переговоры с фракциями %s (политкапитал -%.0f): конфликт ослаб, полгода фракции реже голосуют по-своему." % [String(UPPER.get("name", "палаты")), c])
	refresh()


func up65_pack_n() -> int:
	return maxi(3, int(round(float(UPPER.get("total", 0)) * 0.05)))


func up65_pack_why() -> String:
	if opp_mode:
		return "вы в оппозиции"
	if not upper_on() or not bool(up65_meta().get("app", false)):
		return "в этой палате власть не назначает членов"
	if turn < int(up65.get("pcd", -99)):
		return "ещё %d мес." % (int(up65["pcd"]) - turn)
	return ""


# назначить сторонников (Палата лордов, Сенат Белоруссии и др.): места растут, а недовольство тоже
func up65_pack() -> void:
	if up65_pack_why() != "":
		return
	var n := up65_pack_n()
	var c := 6.0 + float(n) * 0.3
	capital -= c
	var blocs: Array = UPPER["blocs"]
	var done := false
	for bl in blocs:
		if (bl[1] as Array).size() == 1 and int(bl[1][0]) == 0:
			bl[0] = int(bl[0]) + n
			done = true
			break
	if not done:
		blocs.append([n, [0]])
	UPPER["total"] = int(UPPER["total"]) + n
	up65["pack"] = int(up65.get("pack", 0)) + n
	up65["pcd"] = turn + 12
	up65["conf"] = minf(100.0, float(up65["conf"]) + 5.0)
	mv_gov_hit(-0.4)
	up65_log("назначено %d сторонников." % n)
	log_tag("ВЕРХНЯЯ ПАЛАТА", COL_WARN, "Назначено %d новых членов %s (политкапитал -%.0f). Критики говорят о «забивании» палаты: рейтинг власти чуть упал, конфликт вырос." % [n, String(UPPER.get("name", "палаты")), c])
	refresh()


# --- состав палаты при реформе ---
func up65_alloc(weights: Array, total: int) -> Array:
	var tot := 0.0
	for w in weights:
		tot += float(w)
	var out: Array = []
	var acc := 0
	var order: Array = []
	for i in weights.size():
		var v: float = float(total) * (float(weights[i]) / tot if tot > 0.0 else 0.0)
		out.append(int(floor(v)))
		acc += int(out[i])
		order.append([v - floor(v), i])
	order.sort_custom(func(a, b): return a[0] > b[0])
	var k := 0
	while acc < total and k < order.size():
		out[int(order[k][1])] = int(out[int(order[k][1])]) + 1
		acc += 1
		k += 1
	return out


func up65_party_blocs(total: int, gov_bias: float) -> Array:
	var shares: Array = national_shares(false)
	var w: Array = []
	for p in PARTY_NAMES.size():
		var s: float = float(shares[p]) if (p < shares.size() and seats[p] > 0) else 0.0
		if gov_bias != 1.0 and (p == 0 or in_coalition[p]):
			s *= gov_bias
		w.append(s)
	var al := up65_alloc(w, total)
	var blocs: Array = []
	for p in al.size():
		if int(al[p]) > 0:
			blocs.append([int(al[p]), [p]])
	return blocs


func up65_regional_blocs(total: int) -> Array:
	var ids: Array = []
	var ws: Array = []
	for i in regions.size():
		if bool(regions[i].get("terr", false)):
			continue
		ids.append(i)
		ws.append(float(regions[i].get("popm", 1.0)) + 2.0)
	var al := up65_alloc(ws, maxi(total, ids.size()))
	var blocs: Array = []
	for k in ids.size():
		blocs.append([maxi(1, int(al[k])), fed_party_for_bloc(int(ids[k]))])
	return blocs


func up65_make_blocs(form: String, total: int) -> Array:
	match form:
		"regional":
			return up65_regional_blocs(total)
		"appointed":
			return up65_party_blocs(total, 1.7)
		"mixed":
			return up65_regional_blocs(total / 2) + up65_party_blocs(total - total / 2, 1.0)
		"indirect":
			return up65_regional_blocs(total)
	return up65_party_blocs(total, 1.0)


func up65_size_total(size: int) -> int:
	var f: float = [0.15, 0.3, 0.5][clampi(size, 0, 2)]
	return clampi(int(round(float(SEATS) * f)), 15, 400)


# --- конституционная реформа палаты ---
const UP65_OPS := {"create": "Создать палату", "abolish": "Упразднить палату", "powers": "Изменить полномочия", "form": "Изменить способ формирования"}


func up65_reform_info(op: String, pw: String, form: String, size: int) -> Dictionary:
	up65_ensure()
	var out := {"ok": false, "why": "", "cost": 0.0, "have": 0.0, "need": 0.0, "p_up": 1.0, "p_ref": 1.0, "ref": false}
	var exists := upper_on()
	if opp_mode:
		out["why"] = "Реформу проводит правительство, а вы в оппозиции"
		return out
	if turn < int(up65["rcd"]):
		out["why"] = "Следующая реформа палаты возможна через %d мес." % (int(up65["rcd"]) - turn)
		return out
	if op == "create" and exists:
		out["why"] = "Верхняя палата уже есть"
		return out
	if op != "create" and not exists:
		out["why"] = "Верхней палаты нет"
		return out
	if op == "powers" and String(UPPER.get("kind", "")) == pw:
		out["why"] = "Такие полномочия уже есть"
		return out
	if op == "form" and String(up65_meta().get("form", "")) == form:
		out["why"] = "Такой способ формирования уже действует"
		return out
	if op == "create" and pw == "none":
		out["why"] = "Выберите полномочия новой палаты"
		return out
	var need: float = float(super_need()) / float(SEATS)
	var have: float = float(gov_seats()) / float(SEATS)
	out["need"] = need
	out["have"] = have
	var short: float = maxf(0.0, need - have)
	if short > 0.2:
		out["why"] = "В нижней палате не хватает голосов: у коалиции %.0f%%, нужно %.0f%% (разрыв больше 20 пунктов, купить его нельзя)" % [have * 100.0, need * 100.0]
		return out
	out["cost"] = 25.0 + short * 100.0 * 1.4 + (10.0 if op == "abolish" else 0.0) + (8.0 if op == "create" else 0.0)
	if exists:
		var g := up65_share()
		var base: float = 0.85 if g > 0.5 else (0.45 if g > 0.34 else 0.2)
		if op == "abolish":
			base *= 0.45
		elif op == "powers":
			if int(UP65_POW_RANK.get(pw, 0)) < int(UP65_POW_RANK.get(String(UPPER.get("kind", "none")), 0)):
				base *= 0.65
		elif op == "form":
			base *= 0.8
		if String(UPPER.get("kind", "none")) == "none":
			base = 0.9
		out["p_up"] = clampf(base - float(up65["conf"]) / 300.0, 0.05, 0.95)
	if bool(MACRO.get("amend_ref", false)):
		out["ref"] = true
		out["p_ref"] = clampf(0.5 + (mv_gov_rating() - 45.0) / 100.0 + (0.08 if op == "abolish" else 0.0), 0.1, 0.9)
	out["ok"] = true
	return out


func up65_new_upper(pw: String, form: String, size: int) -> Dictionary:
	var total := up65_size_total(size)
	var blocs: Array = up65_make_blocs(form, total)
	var tot := 0
	for bl in blocs:
		tot += int(bl[0])
	var u := {"name": String(UP65_NAMES.get(form, "Сенат")), "kind": pw, "total": tot, "blocs": blocs, "fund_need": 0.667,
		"note": "Создана конституционной реформой 0.65: %s, %s." % [String(UP65_FORM.get(form, "")), String(UP65_POW.get(pw, ""))]}
	if form == "regional":
		u["mode"] = "all"
	if pw == "consent":
		var ids: Array = []
		for t in UP65_CONSENT_IDS:
			if law_index.has(t):
				ids.append(t)
		u["consent"] = ids
	return u


func up65_mo_for(pw: String, form: String) -> Dictionary:
	var mo: Dictionary = (UP65_FORM_DEF.get(form, {}) as Dictionary).duplicate()
	mo.merge(UP65_POW_DEF.get(pw, {}), true)
	mo["form"] = form
	mo["role"] = ""
	mo["app"] = form == "appointed"
	mo["norenew"] = true
	return mo


func upper_renew(shares: Array) -> String:
	up65_ensure()
	if bool((up65["mo"] as Dictionary).get("norenew", false)):
		return ""
	return upper_renew_base(shares)


func up65_reform_do(op: String, pw: String, form: String, size: int) -> void:
	var info: Dictionary = up65_reform_info(op, pw, form, size)
	if not bool(info["ok"]):
		return
	var cst: float = float(info["cost"])
	capital -= cst
	up65["rcd"] = turn + 12
	var nm: String = String(UPPER.get("name", "")) if upper_on() else String(UP65_NAMES.get(form, "палата"))
	var title: String = String(UP65_OPS[op])
	if bool(info["ref"]) and randf() > float(info["p_ref"]):
		log_tag("ВЕРХНЯЯ ПАЛАТА", COL_BAD, "Референдум отклонил реформу (%s): шанс был %.0f%%. Политкапитал -%.0f; новая попытка — через год." % [title.to_lower(), float(info["p_ref"]) * 100.0, cst])
		up65_log("реформа палаты отклонена на референдуме.")
		refresh()
		return
	if upper_on() and randf() > float(info["p_up"]):
		up65["conf"] = minf(100.0, float(up65["conf"]) + 10.0)
		capital += cst * 0.4
		log_tag("ВЕРХНЯЯ ПАЛАТА", COL_BAD, "%s не согласилась на реформу (%s): шанс был %.0f%%. Конфликт палат вырос, часть капитала (%.0f) потрачена." % [nm, title.to_lower(), float(info["p_up"]) * 100.0, cst * 0.6])
		up65_log("палата отказалась от реформы.")
		refresh()
		return
	match op:
		"create":
			UPPER = up65_new_upper(pw, form, size)
			up65["mo"] = up65_mo_for(pw, form)
			up65["conf"] = 5.0
			up65["tilt"] = 0.0
			log_tag("ВЕРХНЯЯ ПАЛАТА", COL_GOOD, "[b]Конституционная реформа:[/b] создана верхняя палата «%s» (%d мест, %s, формирование: %s). Политкапитал -%.0f." % [UPPER["name"], UPPER["total"], UP65_POW[pw], UP65_FORM[form], cst])
		"abolish":
			up65_flush(true)
			UPPER = {"blocs": [], "fund_need": float(UPPER.get("fund_need", 0.667)), "kind": "none", "name": "", "total": 0, "note": "Верхняя палата «%s» упразднена конституционной реформой 0.65; парламент однопалатный." % nm}
			up65["mo"] = {"gone": true}
			up65["conf"] = 0.0
			log_tag("ВЕРХНЯЯ ПАЛАТА", COL_GOOD, "[b]Конституционная реформа:[/b] верхняя палата «%s» упразднена, парламент стал однопалатным. Политкапитал -%.0f." % [nm, cst])
		"powers":
			var old_pw := String(UPPER.get("kind", "none"))
			UPPER["kind"] = pw
			if pw == "consent" and not UPPER.has("consent"):
				var ids: Array = []
				for t in UP65_CONSENT_IDS:
					if law_index.has(t):
						ids.append(t)
				UPPER["consent"] = ids
			var mo: Dictionary = up65_meta().duplicate()
			mo.merge(UP65_POW_DEF.get(pw, {}), true)
			up65["mo"] = mo
			log_tag("ВЕРХНЯЯ ПАЛАТА", COL_GOOD, "[b]Конституционная реформа:[/b] полномочия палаты «%s» изменены: было — %s, стало — %s. Политкапитал -%.0f." % [nm, UP65_POW[old_pw], UP65_POW[pw], cst])
		"form":
			var tot2: int = int(UPPER["total"])
			UPPER["blocs"] = up65_make_blocs(form, tot2)
			var t3 := 0
			for bl in UPPER["blocs"]:
				t3 += int(bl[0])
			UPPER["total"] = t3
			UPPER["mode"] = "all" if form == "regional" else "any"
			var mo2: Dictionary = up65_meta().duplicate()
			mo2.merge(UP65_FORM_DEF.get(form, {}), true)
			mo2["form"] = form
			mo2["app"] = form == "appointed"
			mo2["norenew"] = true
			up65["mo"] = mo2
			up65["tilt"] = 0.0
			log_tag("ВЕРХНЯЯ ПАЛАТА", COL_GOOD, "[b]Конституционная реформа:[/b] палата «%s» теперь формируется так: %s. Состав пересчитан. Политкапитал -%.0f." % [nm, UP65_FORM[form], cst])
	up65_log("%s: реформа проведена." % title)
	refresh()


# --- текст для окна ---
func up65_status_text() -> String:
	up65_ensure()
	var m: Dictionary = up65_meta()
	if not upper_on():
		if String(UPPER.get("kind", "")) == "veto":
			return "[b]%s[/b]: здесь нет обычной верхней палаты, закон проверяет президент: %s" % [String(UPPER.get("name", "Президент")), upper_summary()]
		var note: String = String(UPPER.get("note", ""))
		return "[b]Верхней палаты нет.[/b] %s\nМожно провести конституционную реформу и создать её (внизу)." % note
	var kind: String = String(UPPER.get("kind", "none"))
	var total: int = int(UPPER["total"])
	var g := upper_gov()
	var conf: float = float(up65["conf"])
	var t := "[b]%s[/b] — %d мест; у коалиции [b]%d[/b] (%.0f%%). Полномочия: %s.\n" % [String(UPPER["name"]), total, g, up65_share() * 100.0, UP65_POW.get(kind, kind)]
	t += "Формирование: %s.\n" % UP65_FORM.get(String(m.get("form", "")), "—")
	var ovr: float = float(m.get("ovr", -1.0))
	var slow: int = int(m.get("slow", 0))
	if kind == "override" or kind == "consent":
		var parts: PackedStringArray = []
		if ovr > 0.0:
			parts.append("отказ преодолевается сразу при %d голосах нижней палаты из %d" % [int(ceil(ovr * float(SEATS))), SEATS])
		if slow > 0:
			parts.append("простым большинством — с задержкой %d мес." % slow)
		if parts.is_empty():
			parts.append("отказ преодолеть нельзя")
		t += "Отказ палаты: %s.\n" % "; ".join(parts)
	t += "Согласительная комиссия: %s.\n" % ("есть" if bool(m.get("conc", false)) else "нет")
	if String(m.get("role", "")) == "conf":
		t += "Правительство зависит от доверия этой палаты: при потере опоры возможен вотум недоверия.\n"
	t += "Независимость фракций: %.0f%% «своих» мест голосуют по-своему%s.\n" % [up65_def_rate(m) * 100.0, " (после переговоров меньше)" if int(up65.get("loy_until", -1)) >= turn else ""]
	var cm: Array = up65["cm"]
	t += "\n[b]Конфликт палат: %.0f из 100[/b] (%s). Блокировок: %d, преодолений: %d, комиссий: согласовали %d, не договорились %d.\n" % [conf, "острый" if conf >= 66.0 else ("напряжённый" if conf >= 33.0 else "спокойный"), int(up65.get("blk", 0)), int(up65.get("ovr", 0)), int(cm[0]), int(cm[1])]
	if bool(m.get("reg", false)):
		t += "Недовольство регионов: %.0f%% (усиливает самостоятельность делегаций).\n" % (up65_grievance() * 100.0)
	var tl: float = float(up65.get("tilt", 0.0))
	if absf(tl) > 0.02:
		t += "Региональные выборы сдвинули палату: %s%.0f%% мест коалиции.\n" % ["−" if tl > 0.0 else "+", absf(tl) * 100.0]
	var dem: Dictionary = up65["dem"]
	if not dem.is_empty():
		t += "\n[color=%s][b]Требование палаты:[/b][/color] %s. Срок — до %d мес. от сегодня.\n" % [COL_WARN, up65_dem_text(dem), maxi(0, int(dem["due"]) - turn)]
	var q: Array = up65["q"]
	if not q.is_empty():
		t += "\n[b]Законы с отложенным вступлением:[/b]\n"
		for it in q:
			t += "· «%s»: через %d мес.\n" % [law_index[String(it["tid"])]["name"], maxi(0, int(it["due"]) - turn)]
	var l: Array = up65["log"]
	if not l.is_empty():
		t += "\n[b]Последнее:[/b]\n"
		for i in range(maxi(0, l.size() - 5), l.size()):
			t += "· %s\n" % l[i]
	return t
