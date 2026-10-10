# v38: политика войны.
#  1) Цена войны для демократии: голосование в парламенте по партиям, удар по рейтингу и по отношениям партий
#     (сильнее, если демократия нападает на демократию); недовольство партий держится и после войны.
#  2) Переговоры: пакет требований (земли, репарации, разоружение, демилитаризованная зона, флот, торговля,
#     признание вины, нейтралитет), готовность противника, встречные предложения, перемирие, посредник.
#  3) Международная реакция: осуждение, санкции по доле торговли, премия за риск по долгу, ООН, оружие и
#     добровольцы для жертвы, беженцы, вступление третьих стран, непризнание аннексий.
extends "res://scripts/logic/army.gd"

# отношение архетипов партий к войне: >0 — «ястребы», <0 — «голуби»
const WAR_HAWK := {"popr": 0.6, "cons": 0.3, "own": 0.1, "region": -0.1, "none": 0.0, "oth": 0.0, "prot": -0.1, "popl": -0.3,
	"lib": -0.35, "soc": -0.45, "euro": -0.55, "left": -0.8, "green": -0.9}
# требования на переговорах
const TALK_IDS := ["land", "border", "repar", "disarm", "dmz", "fleet", "trade", "guilt", "neutral"]
const TALK_INFO := {
	"land": ["Все занятые земли", "Все занятые вами АТЕ противника (кроме столицы) переходят к вам."],
	"border": ["Только приграничные земли", "Только занятые АТЕ, граничащие с вашей довоенной территорией: дешевле, чем все занятые земли."],
	"repar": ["Репарации", "Противник платит процент своего ВВП — ваш долг уменьшается."],
	"disarm": ["Разоружение", "Армия противника сокращается вдвое на 5 лет: новая война с ним будет легче."],
	"dmz": ["Демилитаризованная зона", "10 лет противник не держит войска у вашей границы и реже решается на нападение."],
	"fleet": ["Передача флота", "Половина кораблей противника переходит к вам."],
	"trade": ["Торговые уступки", "Противник снижает пошлины для ваших товаров на 3 года: рост +0,15 п.п."],
	"guilt": ["Признание вины", "Противник официально признаёт ответственность за войну: рейтинг и политкапитал растут."],
	"neutral": ["Нейтралитет противника", "Противник выходит из НАТО и не получит помощи союзников в будущей войне с вами."]}
const TALK_REPAR := [1, 2, 3, 5]


# ---------- демократия и партии ----------
func war_demo(cc: String) -> float:
	var d: float = float(MIL_DEMO.get(cc, 0.8))
	if cc == ccode:
		d = clampf(d + float(mods.get("dem_shift", 0.0)), 0.0, 1.0)      # радикальные законы игрока
		if decree_power():
			d = minf(d, 0.2)
	return d


func war_hawk(p: int) -> float:
	var a: String = String(ARCHS[p]) if p < ARCHS.size() else "oth"
	if p == 0:
		a = String(PARCH[0]) if PARCH.size() > 0 and String(PARCH[0]) != "own" else "own"
	return float(WAR_HAWK.get(a, 0.0))


func war_rel(a: String, b: String) -> float:
	if a == b:
		return 100.0
	if a == ccode:
		return fed_rel(b)
	if b == ccode:
		return fed_rel(a)
	var k := a + b if a < b else b + a
	return float(WORLD_REL.get(k, 60.0))


func war_both_eu(a: String, b: String) -> bool:
	return bool(WORLD.get(a, {}).get("eu", false)) and bool(WORLD.get(b, {}).get("eu", false))


# голосование об объявлении войны: партия «за», если её отношение к войне (ястребы/голуби), лояльность коалиции,
# вражда к цели перевешивают демократичность цели и общий ЕС
func war_vote(cc: String) -> Dictionary:
	var dt := war_demo(cc)
	var rel := fed_rel(cc)
	var eu: bool = war_both_eu(ccode, cc)
	var rows: Array = []
	var yes := 0
	for p in PARTY_NAMES.size():
		var s: int = int(seats[p]) if p < seats.size() else 0
		if s <= 0:
			continue
		var v := 1.0
		if p != 0 or opp_mode:
			v = war_hawk(p) + (0.7 if in_coalition[p] and not opp_mode else -0.1) - 0.7 * dt + clampf((30.0 - rel) / 40.0, -0.5, 0.8) - (0.3 if eu else 0.0)
			if decree_power():
				v += 0.6
		var y: bool = v > 0.0
		if y:
			yes += s
		rows.append({"p": p, "s": s, "y": y, "v": v})
	return {"yes": yes, "total": SEATS, "ok": yes * 2 > SEATS, "rows": rows}


func war_vote_text(cc: String) -> String:
	var vt := war_vote(cc)
	var za: PackedStringArray = []
	var pr: PackedStringArray = []
	for r in vt["rows"]:
		var nm := "%s %d" % [String(PARTY_NAMES[int(r["p"])]) if PARTY_NAMES.size() > int(r["p"]) else str(r["p"]), int(r["s"])]
		if bool(r["y"]):
			za.append(nm)
		else:
			pr.append(nm)
	return "Голосование в парламенте: [b]%d[/b] из %d «за» (%s)%s" % [int(vt["yes"]), int(vt["total"]), ", ".join(za),
		"; против: " + ", ".join(pr) if not pr.is_empty() else ""]


func war_anger_add(p: int, v: float) -> void:
	var an: Dictionary = mil.get("anger", {})
	an[p] = clampf(float(an.get(p, 0.0)) + v, 0.0, 40.0)
	mil["anger"] = an


func war_anger(p: int) -> float:
	return float((mil.get("anger", {}) as Dictionary).get(p, 0.0))


# слагаемое довольства партнёра по коалиции (coalition.gd: sat_breakdown)
func war_sat_term(p: int) -> float:
	return -0.6 * war_anger(p)


# слагаемое отношений с партией (opposition.gd: prel_base)
func war_prel_term(p: int) -> float:
	return -0.8 * war_anger(p)


# последствия объявления войны внутри страны
func war_on_declare(cc: String) -> String:
	var dm := war_demo(ccode)
	var dt := war_demo(cc)
	var f: float = 0.5 + 0.5 * dm + 1.2 * dm * dt
	add_support("Силовики", 3.0)
	add_support("Молодёжь", -6.0 * f)
	add_support("Экологи", -4.0 * f)
	add_support("Пенсионеры", -3.0 * f)
	add_support("Бизнес", -4.0 * f)
	add_support("Бюджетники", -1.5 * f)
	add_support("Рабочие", -1.0 * f)
	var vt := war_vote(cc)
	var angry: PackedStringArray = []
	for r in vt["rows"]:
		var p: int = int(r["p"])
		if p == 0:
			continue
		var dove: float = clampf(0.25 - war_hawk(p), 0.0, 1.2)
		var a: float = (4.0 + 14.0 * dt) * maxf(0.3, dm) * dove
		if in_coalition[p] and not bool(r["y"]):
			a += 6.0
		if a < 0.5:
			continue
		war_anger_add(p, a)
		if prel.size() > p:
			prel[p] = clampf(float(prel[p]) - a, 0.0, 100.0)
		if in_coalition[p]:
			satis[p] = clampf(float(satis.get(p, 50.0)) - a * 0.8, 0.0, 100.0)
		if a >= 6.0:
			angry.append(String(PARTY_NAMES[p]) if PARTY_NAMES.size() > p else str(p))
	var msg := ""
	if dm >= 0.6 and dt >= 0.6:
		msg = "Война демократии против демократии: общество расколото, рейтинг падает сильнее."
	elif dm >= 0.6:
		msg = "Общество демократической страны тяжело принимает войну."
	if not angry.is_empty():
		msg += " Резко против: %s — отношения с ними испорчены надолго." % ", ".join(angry)
	return msg.strip_edges()


func war_anger_month() -> void:
	var an: Dictionary = mil.get("anger", {})
	var w: Dictionary = mil.get("war", {})
	var aggr: bool = mil_at_war() and bool(w.get("aggr", false))
	var dm := war_demo(ccode)
	var dt := war_demo(String(w.get("lead", ""))) if mil_at_war() else 0.0
	for p in range(1, PARTY_NAMES.size()):
		var v: float = float(an.get(p, 0.0))
		if aggr:
			v += 0.5 * dm * dt * clampf(0.25 - war_hawk(p), 0.0, 1.2)
			v *= 0.98
		else:
			v *= 0.88
		if v < 0.2:
			an.erase(p)
		else:
			an[p] = v
	mil["anger"] = an


# ---------- переговоры ----------
func talk_sel() -> Dictionary:
	if not mil.has("tsel"):
		mil["tsel"] = {"land": true, "repar": 0}
	return mil["tsel"]


func talk_border_ates(cc: String) -> Array:
	var out: Array = []
	for a in mil_occupied_by_us(cc):
		for b in ate_nbs(int(a)):
			if ate_cc(b) == ccode:
				out.append(int(a))
				break
	return out


func talk_avail(id: String) -> String:
	if not mil_at_war():
		return "Войны нет."
	var w: Dictionary = mil["war"]
	var lead := String(w["lead"])
	match id:
		"land":
			var n := 0
			for c in mil_side_ccs(1):
				n += mil_occupied_by_us(String(c)).size()
			if n == 0:
				return "Вы не занимаете земель противника."
		"border":
			var n2 := 0
			for c in mil_side_ccs(1):
				n2 += talk_border_ates(String(c)).size()
			if n2 == 0:
				return "Нет занятых приграничных АТЕ."
		"fleet":
			if float(FLEET.get("navy0", {}).get(lead, {}).size()) == 0.0 or not flt_has_sea() or bool(flt.get("land", true)):
				return "У противника нет флота или у вас нет выхода к морю."
		"neutral":
			if not mil_is_nato(lead) or lead in mil.get("neutral", []):
				return "Противник не в НАТО."
	return ""


func talk_cost(id: String, lvl: int = 0) -> float:
	var w: Dictionary = mil["war"]
	var cap_e: bool = mil_cap_held(String(w["lead"]))
	var land: float = maxf(5.0, 15.0 + float(w["occ"][1]) * 100.0 - (20.0 if cap_e else 0.0))
	match id:
		"land":
			return land
		"border":
			return maxf(5.0, land * 0.55)
		"repar":
			return 9.0 * float(TALK_REPAR[clampi(lvl, 0, TALK_REPAR.size() - 1)])
		"disarm":
			return 18.0
		"dmz":
			return 10.0
		"fleet":
			return 12.0
		"trade":
			return 8.0
		"guilt":
			return 6.0
		"neutral":
			return 22.0
	return 0.0


# выбранный пакет: [[id, уровень], ...] — только доступные требования; «все земли» исключают «приграничные»
func talk_package() -> Array:
	var sel := talk_sel()
	var out: Array = []
	for id in TALK_IDS:
		if not sel.has(id) or (id != "repar" and not bool(sel[id])):
			continue
		if id == "repar" and int(sel["repar"]) <= 0:
			continue
		if id == "border" and bool(sel.get("land", false)) and talk_avail("land") == "":
			continue
		if talk_avail(id) != "":
			continue
		out.append([id, int(sel["repar"]) - 1 if id == "repar" else 0])
	return out


# сколько противник готов уступить: военный счёт, усталость, посредник, перемирие
func talk_budget() -> float:
	var w: Dictionary = mil["war"]
	var months: float = float(w["days"]) / 30.0
	var b: float = float(w["score"]) + 10.0 + 1.5 * months + 15.0 * float(w["occ"][1]) + maxf(0.0, float(w["score"]) - 60.0)
	if String(w.get("med", "")) != "":
		b += 8.0
	if int(w.get("cf", 0)) > 0:
		b += 4.0
	return b


func talk_quote(pkg: Array = []) -> Dictionary:
	if not mil_at_war():
		return {"ok": false, "why": "Войны нет.", "cost": 0.0, "budget": 0.0, "p": 0.0}
	if pkg.is_empty():
		pkg = talk_package()
	var c := 0.0
	for it in pkg:
		c += talk_cost(String(it[0]), int(it[1]))
	var b := talk_budget()
	var p: float = 0.95 if c <= b else clampf(0.95 - (c - b) / 12.0, 0.0, 0.95)
	if c > b + 11.0:
		p = 0.0
	var why := ""
	var w: Dictionary = mil["war"]
	if int(w.get("prop_cd", 0)) > 0:
		why = "Противник недавно отверг предложение (ещё %d сут.)." % int(w["prop_cd"])
		p = 0.0
	return {"ok": p > 0.0, "why": why, "cost": c, "budget": b, "p": p, "pkg": pkg}


func talk_pkg_text(pkg: Array) -> String:
	if pkg.is_empty():
		return "белый мир (довоенные границы)"
	var parts: PackedStringArray = []
	for it in pkg:
		var id := String(it[0])
		if id == "repar":
			parts.append("репарации %d%% ВВП" % int(TALK_REPAR[int(it[1])]))
		else:
			parts.append(String(TALK_INFO[id][0]).to_lower())
	return ", ".join(parts)


func talk_terms(pkg: Array) -> Dictionary:
	var t := {}
	for it in pkg:
		t[String(it[0])] = int(TALK_REPAR[int(it[1])]) if String(it[0]) == "repar" else 1
	return t


func talk_propose() -> Dictionary:
	var q := talk_quote()
	if not mil_at_war():
		return {"done": false, "msg": "Войны нет."}
	if String(q["why"]) != "":
		return {"done": false, "msg": String(q["why"])}
	var pkg: Array = q["pkg"]
	if mil_rng.randf() < float(q["p"]):
		var t := talk_terms(pkg)
		return mil_peace("annex" if t.has("land") or t.has("border") else "white", t)
	var w: Dictionary = mil["war"]
	w["prop_cd"] = 15
	capital = maxf(0.0, capital - 2.0)
	# встречное предложение: требования по порядку, пока помещаются в готовность противника
	var b := talk_budget()
	var cnt: Array = []
	var c := 0.0
	for it in pkg:
		var ci := talk_cost(String(it[0]), int(it[1]))
		if String(it[0]) == "repar" and c + ci > b:
			for lv in range(int(it[1]) - 1, -1, -1):
				if c + talk_cost("repar", lv) <= b:
					cnt.append(["repar", lv])
					c += talk_cost("repar", lv)
					break
			continue
		if c + ci <= b:
			cnt.append(it)
			c += ci
	var nm := String(WORLD[String(w["lead"])]["name"])
	mil_log("«%s» отвергла условия (%s)." % [nm, talk_pkg_text(pkg)], COL_BAD)
	if b >= 0.0 and current_event.is_empty():
		mil["cnt"] = cnt
		mil_event(["", "talk_cnt"], "«%s» отвергла ваши условия, но через посредников передала встречное предложение: %s. Принять?" % [nm, talk_pkg_text(cnt)],
			[{"l": "Отклонить и продолжать войну", "fx": {}}, {"l": "Принять встречное предложение", "fx": {}}])
		return {"done": false, "msg": "Противник отверг условия и предложил свои."}
	return {"done": false, "msg": "Противник отверг условия (готов уступить на %.0f, а вы просите на %.0f)." % [b, float(q["cost"])]}


func talk_ceasefire_check() -> String:
	if not mil_at_war():
		return "Войны нет."
	var w: Dictionary = mil["war"]
	if int(w.get("cf", 0)) > 0:
		return "Перемирие уже действует."
	if int(w.get("cf_cd", 0)) > 0:
		return "Противник не готов к новому перемирию (ещё %d сут.)." % int(w["cf_cd"])
	if talk_budget() < -15.0 and String(w.get("med", "")) == "":
		return "Противник побеждает и не хочет останавливаться (нужен посредник)."
	return ""


func talk_ceasefire() -> Dictionary:
	var why := talk_ceasefire_check()
	if why != "":
		return {"done": false, "msg": why}
	var w: Dictionary = mil["war"]
	w["cf"] = 30
	w["cf_cd"] = 60
	for f in mil["units"]:
		f["fight"] = -1
		f["path"] = []
	var msg := "Перемирие на 30 суток: бои остановлены, идут переговоры."
	mil_log(msg, COL_GOOD)
	return {"done": true, "msg": msg}


func talk_ceasefire_break() -> void:
	if mil_at_war() and int(mil["war"].get("cf", 0)) > 0:
		mil["war"]["cf"] = 0
		war_intl(mil["war"])["cond"] = minf(100.0, float(war_intl(mil["war"])["cond"]) + 10.0)
		mil_log("вы прервали перемирие: бои возобновились, мир осуждает срыв переговоров.", COL_BAD)


func talk_mediator_name() -> String:
	var w: Dictionary = mil["war"]
	var lead := String(w["lead"])
	if war_both_eu(ccode, lead):
		return "Евросоюз"
	var best := ""
	var bv := 0.0
	for c in ["CH", "AT", "NO", "IE", "FI", "SE", "LU", "PT", "GR", "SI"]:
		if c == ccode or c == lead or mil_side(c) >= 0 or not WORLD.has(c):
			continue
		var v := minf(war_rel(c, ccode), war_rel(c, lead))
		if v > bv:
			bv = v
			best = c
	return String(WORLD[best]["name"]) if best != "" and bv >= 55.0 else "ООН"


func talk_mediator() -> Dictionary:
	if not mil_at_war():
		return {"done": false, "msg": "Войны нет."}
	var w: Dictionary = mil["war"]
	if String(w.get("med", "")) != "":
		return {"done": false, "msg": "Посредник уже работает: %s." % String(w["med"])}
	if capital < 3.0:
		return {"done": false, "msg": "Нужно 3 политического капитала."}
	capital -= 3.0
	w["med"] = talk_mediator_name()
	var it := war_intl(w)
	it["cond"] = maxf(0.0, float(it["cond"]) - 8.0)
	var msg := "Посредник на переговорах: %s. Противник уступчивее (+8), мир меньше осуждает." % String(w["med"])
	mil_log(msg, COL_GOOD)
	return {"done": true, "msg": msg}


# применение условий мира (вызывается из mil_peace): t — {id: 1 | процент репараций}
func talk_apply(t: Dictionary, enemies: Array, lead: String, parts: PackedStringArray) -> void:
	if t.has("disarm"):
		var lim: Dictionary = mil.get("lim", {})
		for c in enemies:
			lim[String(c)] = {"arm": 0.5, "m": 60}
		mil["lim"] = lim
		parts.append("армия противника сокращена вдвое на 5 лет")
	if t.has("dmz"):
		var dz: Dictionary = mil.get("dmz", {})
		dz[lead] = 120
		mil["dmz"] = dz
		parts.append("демилитаризованная зона на 10 лет")
	if t.has("fleet"):
		var nv0: Dictionary = FLEET.get("navy0", {}).get(lead, {})
		var got := 0
		for cid in nv0:
			var n: int = int(nv0[cid]) / 2
			if n > 0 and (flt["navy"] as Dictionary).has(cid):
				flt["navy"][cid] = int(flt["navy"][cid]) + n
				got += n
		var nvl: Dictionary = mil.get("nvl", {})
		nvl[lead] = 0.5
		mil["nvl"] = nvl
		if got > 0:
			fleet_recalc_f()
			parts.append("получено %d кораблей" % got)
	if t.has("trade"):
		var tr: Dictionary = mil.get("trd", {})
		tr[lead] = 36
		mil["trd"] = tr
		parts.append("торговые уступки на 3 года")
	if t.has("guilt"):
		for g in GROUPS:
			add_support(g, 2.0)
		capital = minf(100.0, capital + 4.0)
		parts.append("противник признал вину за войну")
	if t.has("neutral"):
		var nl: Array = mil.get("neutral", [])
		if not (lead in nl):
			nl.append(lead)
		mil["neutral"] = nl
		parts.append("противник объявил нейтралитет")


# ---------- международная реакция ----------
func war_intl(w: Dictionary) -> Dictionary:
	if not w.has("intl"):
		w["intl"] = {"cond": 0.0, "sanc": [], "share": 0.0, "eu": false, "aid": 0.0, "vol": 0, "ref": 0.0, "joined": [], "un": 0, "press": 0}
	return w["intl"]


# кто агрессор и кто жертва
func war_aggressor() -> String:
	var w: Dictionary = mil["war"]
	return ccode if bool(w["aggr"]) else String(w["lead"])


func war_victim() -> String:
	var w: Dictionary = mil["war"]
	return String(w["lead"]) if bool(w["aggr"]) else ccode


# стартовое осуждение агрессора ag за нападение на vi
func war_cond0(ag: String, vi: String) -> float:
	var c: float = 20.0 + 35.0 * war_demo(vi) + (15.0 if war_both_eu(ag, vi) else 0.0) + (10.0 if mil_is_nato(vi) else 0.0) - 15.0 * (1.0 - war_demo(ag))
	return clampf(c, 5.0, 100.0)


func war_eu0(ag: String, vi: String, cond: float) -> bool:
	if war_both_eu(ag, vi):
		return true
	return bool(WORLD.get(vi, {}).get("eu", false)) and ag == ccode and not decree_power() and cond >= 40.0


func war_intl_init(w: Dictionary) -> void:
	var it := war_intl(w)
	var ag := war_aggressor()
	var vi := war_victim()
	it["cond"] = war_cond0(ag, vi)
	it["eu"] = war_eu0(ag, vi, float(it["cond"]))
	w["sanct"] = bool(it["eu"]) and ag == ccode
	war_sanctions_update(w)


# кто введёт санкции против агрессора ag: [страны, доля торговли игрока с ними]
func war_sanc_list(ag: String, vi: String, cond: float, eu: bool) -> Array:
	var out: Array = []
	for c in WORLD:
		var cs := String(c)
		if cs == ag or cs == vi or mil_side(cs) >= 0:
			continue
		var eu_m: bool = bool(WORLD[cs].get("eu", false)) or cs in ["NO", "CH", "GB", "IS"]
		var on: bool = eu and eu_m
		if not on:
			var k: float = war_demo(cs) * cond / 100.0 * (1.0 + (war_rel(cs, vi) - war_rel(cs, ag)) / 100.0)
			on = k > 0.5
		if on:
			out.append(cs)
	var tot := 0.0
	var sh := 0.0
	if ag == ccode:
		for c in dip:
			var tv: float = float((DIP_C[c] as Dictionary).get("trade", 0.0)) if DIP_C.has(c) else 0.0
			tot += tv
			if c in out:
				sh += tv
	return [out, sh / tot if tot > 0.0 else 0.0]


func war_sanctions_update(w: Dictionary) -> void:
	var it := war_intl(w)
	var r := war_sanc_list(war_aggressor(), war_victim(), float(it["cond"]), bool(it["eu"]))
	it["sanc"] = r[0]
	it["share"] = r[1]


# прогноз реакции мира перед объявлением войны стране cc
func war_preview_text(cc: String) -> String:
	var cond := war_cond0(ccode, cc)
	var eu := war_eu0(ccode, cc, cond)
	var r := war_sanc_list(ccode, cc, cond, eu)
	var t := "Прогноз реакции мира: осуждение [b]%.0f[/b] из 100" % cond
	if eu:
		t += ", санкции ЕС"
	if not (r[0] as Array).is_empty():
		t += "; санкции %d стран (%.0f%% вашей торговли): рост ≈ %+.1f п.п." % [(r[0] as Array).size(), float(r[1]) * 100.0, -(0.3 + 3.0 * float(r[1])) - (1.2 if eu else 0.0)]
	else:
		t += "; санкций не ждите"
	var dm := war_demo(ccode)
	var dt := war_demo(cc)
	if dm >= 0.6 and dt >= 0.6:
		t += ".\n[color=%s]Нападение демократии на демократию: рейтинг и отношения с партиями упадут сильнее.[/color]" % COL_BAD
	elif dm >= 0.6:
		t += ".\n[color=%s]Общество демократической страны тяжело принимает войну.[/color]" % COL_WARN
	return t


func war_intl_month() -> void:
	var w: Dictionary = mil["war"]
	var it := war_intl(w)
	var ag := war_aggressor()
	var vi := war_victim()
	var months: int = int(w["days"]) / 30
	var occ_v: float = float(w["occ"][1]) if ag == ccode else float(w["occ"][0])
	var dc: float = 1.5 + 25.0 * occ_v - (3.0 if int(w.get("cf", 0)) > 0 else 0.0) - (2.0 if String(w.get("med", "")) != "" else 0.0) + float(it["ref"]) / 400.0
	it["cond"] = clampf(float(it["cond"]) + dc, 0.0, 100.0)
	if ag == ccode and not bool(it["eu"]) and bool(WORLD.get(vi, {}).get("eu", false)) and float(it["cond"]) >= 40.0:
		it["eu"] = true
		w["sanct"] = true
		mil_log("Евросоюз ввёл санкции против вас.", COL_BAD)
	war_sanctions_update(w)
	var vn := String(WORLD[vi]["name"])
	var an := String(WORLD[ag]["name"])
	# ООН
	if months >= 1 and int(it["un"]) == 0 or (months >= 3 and months % 3 == 0 and float(it["cond"]) >= 50.0):
		it["un"] = int(it["un"]) + 1
		var za: int = clampi(int(60.0 + float(it["cond"]) * 0.9), 60, 145)
		mil_log("Генеральная Ассамблея ООН %sосудила нападение страны «%s» на «%s» (за — %d государств)." % ["снова " if int(it["un"]) > 1 else "", an, vn, za], COL_BAD if ag == ccode else COL_WARN)
	# беженцы с занятых земель
	var occ_pop := 0.0
	for a in mil.get("ctl", {}):
		if ate_cc(int(a)) == vi:
			occ_pop += ate_pop(int(a))
	var add_r: float = occ_pop * 1000.0 * 0.12
	var cap_r: float = occ_pop * 1000.0 * 0.35
	if float(it["ref"]) < cap_r:
		it["ref"] = minf(cap_r, float(it["ref"]) + add_r)
	if vi == ccode and add_r > 1.0:
		add_support("Пенсионеры", -0.3)
		add_support("Рабочие", -0.3)
	# помощь жертве: оружие, деньги, добровольцы
	var k_aid: float = float(it["cond"]) / 100.0 * (0.05 if mil_is_nato(vi) or bool(WORLD.get(vi, {}).get("eu", false)) else 0.03)
	if months >= 1 and k_aid > 0.01:
		var add_k := 0.0
		for f in mil_units_of(vi):
			var d: float = float(f["max"]) * k_aid
			f["str"] = minf(float(f["max"]) * 1.2, float(f["str"]) + d)
			f["q"] = minf(1.25, float(f["q"]) + 0.01 * float(it["cond"]) / 100.0)
			add_k += d
		it["aid"] = float(it["aid"]) + add_k
		if vi == ccode:
			var money: float = gdp * 0.002 * float(it["cond"]) / 100.0
			debt = maxf(0.0, debt - money)
		if months % 2 == 1 and add_k > 0.2:
			mil_log("Партнёры передали стране «%s» оружие и снаряжение (≈ %.1f тыс. бойцов пополнения)." % [vn, add_k], COL_GOOD if vi == ccode else COL_WARN)
	if months >= 2 and float(it["cond"]) >= 55.0 and int(it["vol"]) < 3 and months % 3 == 2:
		it["vol"] = int(it["vol"]) + 1
		var home := mil_home_spots(vi, 1)
		if not home.is_empty():
			var sz: float = 2.0 + float(it["cond"]) / 40.0
			var f2 := mil_new_unit(vi, sz, 0.95, int(home[0]), "vol")
			f2["nm"] = "Добровольцы-%d" % int(it["vol"])
			f2["mode"] = "auto" if vi != ccode else "def"
			mil_log("На сторону страны «%s» прибыли иностранные добровольцы (%.1f тыс.)." % [vn, sz], COL_GOOD if vi == ccode else COL_WARN)
	# третьи страны вступают в войну
	if months >= 2 and (it["joined"] as Array).size() < 2:
		war_join_check(w, it)
	# давление: требование прекратить огонь
	if ag == ccode and months >= 2 and float(it["cond"]) >= 60.0 and int(it["press"]) == 0 and current_event.is_empty() and not election_open:
		it["press"] = 1
		mil_event(["press_no", "press_cf", "press_med"], "ЕС, США и ООН требуют немедленно прекратить огонь и начать переговоры с «%s». Иначе — новые санкции и изоляция." % vn,
			[{"l": "Отклонить: война продолжается", "fx": {"support": {"Силовики": 1.0}}},
			{"l": "Согласиться на перемирие на 30 суток", "fx": {"support": {"Молодёжь": 2.0, "Бизнес": 1.0}}},
			{"l": "Пригласить посредника (капитал −3)", "fx": {"support": {"Бизнес": 1.0}}}])


func war_join_check(w: Dictionary, it: Dictionary) -> void:
	var ag := war_aggressor()
	var vi := war_victim()
	var ag_side := mil_side(ag)
	for c in wsim:
		var cs := String(c)
		if mil_side(cs) >= 0 or not MIL_BASE.has(cs) or cs == ccode:
			continue
		var touch_ag := false
		var touch_vi := false
		for a in mil_cc_ates(cs):
			for b in ate_nbs(int(a)):
				var o := ate_cc(b)
				if o == ag:
					touch_ag = true
				elif o == vi:
					touch_vi = true
			if touch_ag and touch_vi:
				break
		var rv := war_rel(cs, vi)
		var ra := war_rel(cs, ag)
		var p := 0.0
		var sd := -1
		if touch_ag and rv - ra > 35.0:
			p = 0.03 * clampf((rv - ra - 35.0) / 30.0, 0.0, 1.0) * (1.0 + float(it["cond"]) / 100.0) * war_demo(cs)
			sd = 1 - ag_side
		elif touch_vi and ra > 80.0 and rv < 30.0:
			p = 0.015
			sd = ag_side
		if sd >= 0 and mil_rng.randf() < p:
			war_join(cs, sd)
			(it["joined"] as Array).append(cs)
			return


func war_join(cs: String, sd: int) -> void:
	var w: Dictionary = mil["war"]
	(w["side"] as Dictionary)[cs] = sd
	var foes: Array = []
	for c2 in w["side"]:
		if int(w["side"][c2]) != sd:
			foes.append(String(c2))
	mil_spawn_army(cs, foes)
	for a in mil_cc_ates(cs):
		(w["pop"] as Dictionary)[int(a)] = ate_pop(int(a))
		(w["tot"] as Array)[sd] = float(w["tot"][sd]) + ate_pop(int(a))
	mil_dirty = true
	var dd: float = -45.0 if sd == 1 else 5.0
	if dip.has(cs):
		dip_change(cs, dd)
	else:
		(fst["rel_x"] as Dictionary)[cs] = float((fst["rel_x"] as Dictionary).get(cs, 0.0)) + dd
	var msg := "«%s» вступила в войну на %s стороне!" % [String(WORLD[cs]["name"]), "вашей" if sd == 0 else "стороне противника"]
	log_line("[b][color=%s]%s: %s[/color][/b]" % [COL_GOOD if sd == 0 else COL_BAD, date_text(), msg])
	mil_log(msg, COL_GOOD if sd == 0 else COL_BAD)


# экономические последствия реакции мира для игрока
func war_intl_g() -> float:
	if not mil_at_war():
		return -0.25 if war_nonrec_any() else 0.0
	var it := war_intl(mil["war"])
	if war_aggressor() != ccode:
		return 0.0
	return -(0.3 * float((it["sanc"] as Array).size() > 0) + 3.0 * float(it["share"]))


func war_intl_infl() -> float:
	if not mil_at_war() or war_aggressor() != ccode:
		return 0.0
	return 1.0 * float(war_intl(mil["war"])["share"])


func war_nonrec_any() -> bool:
	return not (mil.get("nonrec", {}) as Dictionary).is_empty()


# надбавка к ставке по долгу (policy.gd: debt_rate)
func war_prem() -> float:
	if not mil_on():
		return 0.0
	if not mil_at_war():
		return 0.2 if war_nonrec_any() else 0.0
	var w: Dictionary = mil["war"]
	var it := war_intl(w)
	var p: float = 0.3 + float(w["occ"][0]) * 2.0
	if war_aggressor() == ccode:
		p += float(it["cond"]) / 100.0 * 1.2
	return p


func war_dip_extra(c: String) -> float:
	var t := 0.0
	if mil_at_war() and mil_side(c) < 0:
		var it := war_intl(mil["war"])
		if war_aggressor() == ccode:
			t -= float(it["cond"]) * 0.15 * war_demo(c)
		else:
			t += float(it["cond"]) * 0.05 * war_demo(c)
	var nr: Dictionary = mil.get("nonrec", {})
	if not nr.is_empty() and not nr.has(c):
		t -= 8.0 * war_demo(c)
	return t


func war_timers_month() -> void:
	for key in ["lim", "dmz", "trd", "nonrec"]:
		var d: Dictionary = mil.get(key, {})
		for c in d.keys():
			if key == "lim":
				d[c]["m"] = int(d[c]["m"]) - 1
				if int(d[c]["m"]) <= 0:
					d.erase(c)
			else:
				d[c] = int(d[c]) - 1
				if int(d[c]) <= 0:
					d.erase(c)
					if key == "nonrec":
						mil_log("международное непризнание аннексии ослабло: отношения постепенно восстанавливаются.", COL_GOOD)
		mil[key] = d
	war_anger_month()


func war_trade_g() -> float:
	return 0.15 * float((mil.get("trd", {}) as Dictionary).size())


func war_intl_text() -> String:
	if not mil_at_war():
		var t0 := ""
		var nr: Dictionary = mil.get("nonrec", {})
		if not nr.is_empty():
			t0 += "[color=%s]Мир не признаёт вашу аннексию земель (ещё %d мес.): отношения с демократиями хуже, ставка по долгу +0,2 п.п., рост −0,25 п.п.[/color]\n" % [COL_BAD, int(nr.values().max())]
		var an := ""
		for p in (mil.get("anger", {}) as Dictionary):
			if float(mil["anger"][p]) >= 3.0:
				an += "%s (−%.0f), " % [String(PARTY_NAMES[int(p)]) if PARTY_NAMES.size() > int(p) else str(p), float(mil["anger"][p])]
		if an != "":
			t0 += "Партии, не простившие войну: %s\n" % an.trim_suffix(", ")
		return t0
	var w: Dictionary = mil["war"]
	var it := war_intl(w)
	var ag := war_aggressor()
	var t := "Осуждение агрессора («%s»): [b]%.0f[/b] из 100\n" % [String(WORLD[ag]["name"]), float(it["cond"])]
	var sc: Array = it["sanc"]
	if ag == ccode:
		if sc.is_empty():
			t += "Санкций против вас пока нет.\n"
		else:
			var nms: PackedStringArray = []
			for c in sc:
				nms.append(String(WORLD[c]["name"]))
			t += "[color=%s]Санкции: %d стран%s (%.0f%% вашей торговли): рост %+.1f п.п.[/color]\n" % [COL_BAD, sc.size(), " и ЕС" if bool(it["eu"]) else "", float(it["share"]) * 100.0, war_intl_g()]
			t += "[color=%s]%s[/color]\n" % [COL_DIM, ", ".join(nms)]
	else:
		t += "Мир на вашей стороне: помощь оружием %.1f тыс. бойцов пополнения%s.\n" % [float(it["aid"]), ", добровольцы" if int(it["vol"]) > 0 else ""]
	if ag == ccode and float(it["aid"]) > 0.0:
		t += "Противнику передали оружие: ≈ %.1f тыс. бойцов пополнения%s.\n" % [float(it["aid"]), ", добровольцы — %d отряда" % int(it["vol"]) if int(it["vol"]) > 0 else ""]
	if float(it["ref"]) >= 1.0:
		t += "Беженцы с занятых земель: ≈ %.0f тыс.\n" % float(it["ref"])
	t += "Надбавка к ставке по долгу: +%.1f п.п.\n" % war_prem()
	if not (it["joined"] as Array).is_empty():
		var j: PackedStringArray = []
		for c in it["joined"]:
			j.append(String(WORLD[c]["name"]))
		t += "Вступили в войну: %s\n" % ", ".join(j)
	return t
