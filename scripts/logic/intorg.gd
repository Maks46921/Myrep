# v52_1: международные организации (данные — data_orgs.gd). Членство, вступление и выход, влияние внутри
# организации, взносы, особые действия и регулярные сессии: на каждой сессии — вопрос повестки, за который
# голосуют члены; голос игрока меняет исход (при консенсусе — вето) и отношения со странами-членами.
# ЕС, еврозона, Шенген и НАТО ведутся прежними механизмами «Реализма» (rl), здесь — только их показ и сессии.
extends "res://scripts/logic/history.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func rl_acts(page: String) -> Array:
	return []


func rl_cor_add(v: float) -> void:
	pass


func rl_do(id: String) -> bool:
	return false


func rl_on() -> bool:
	return false


func rl_pc() -> float:
	return 0.0


# --- конец заглушек ---


const IO_EAST := ["PL", "CZ", "SK", "HU", "SI", "HR", "BG", "RO", "EE", "LV", "LT", "AT", "GR"]
const IO_POSTSOV := ["RU", "BY", "UA", "MD", "EE", "LV", "LT"]
const IO_BLACKSEA := ["RU", "UA", "MD", "RO", "BG", "GR", "AL", "RS", "ME", "MK"]
const IO_GEO := {"v4": ["PL", "CZ", "SK", "HU"], "benelux": ["BE", "NL", "LU"], "nordic": ["DK", "NO", "SE", "FI"], "baltic": ["EE", "LV", "LT"], "union": ["RU", "BY"]}

var io := {}
var rl: Dictionary = {}   # состояние «Реализма» (объявлено здесь, чтобы организации видели ЕС/НАТО)


func io_init() -> void:
	io = {"mem": {}, "mem0": {}, "cand": {}, "bon": {}, "cd": {}, "pend": {}, "hist": {}, "next": {}, "log": [], "ibon": {}, "gb": [], "sel": "un", "sc_until": -1, "imf_until": -1, "susp": {}}
	var k := 0
	for o in ORG_ORDER:
		var d: Dictionary = ORGS[o]
		var m: bool = ccode in (d["mem"] as Array)
		io["mem"][o] = m
		io["next"][o] = 2 + (k * 5) % maxi(1, int(d["per"]))
		# 0.55.4: страна уже кандидат (переговоры о вступлении идут с прошлых лет)
		if not m and (d.get("cand0", {}) as Dictionary).has(ccode):
			io["cand"][o] = {"p": float(d["cand0"][ccode]), "m": 0, "met": 0, "need": 1, "start": true}
		k += 1
	io["mem0"] = (io["mem"] as Dictionary).duplicate()


func io_ready() -> bool:
	return not io.is_empty()


func io_member(o: String) -> bool:
	if io.is_empty():
		return false
	var d: Dictionary = ORGS.get(o, {})
	if d.has("rl") and rl_on():
		var key: String = String(d["rl"])
		return bool((rl["b"] as Dictionary).get(key, false))
	if o == "eea":
		return io_member("eu") or bool(io["mem"].get("eea", false))
	return bool(io["mem"].get(o, false))


# члены из 38 стран игры (с учётом того, вступила или вышла страна игрока)
func io_members(o: String) -> Array:
	var out: Array = (ORGS[o]["mem"] as Array).duplicate()
	var me := io_member(o)
	if me and not (ccode in out):
		out.append(ccode)
	elif not me and ccode in out:
		out.erase(ccode)
	return out


func io_avg_rel(o: String) -> float:
	var s := 0.0
	var n := 0
	for c in io_members(o):
		if c != ccode and dip.has(c):
			s += float(dip[c]["rel"])
			n += 1
	return s / float(n) if n > 0 else 55.0


# влияние в организации 0..100: доля в экономике членов, отношения, вклад и активность
func io_infl(o: String) -> float:
	var tot := 0.0
	for c in io_members(o):
		if WORLD.has(c):
			tot += float(WORLD[c]["gdp"])
	var ext_k: float = 2.5 if String(ORGS[o]["ext"]) != "" else 1.0
	if o in ["un", "imf", "wb", "wto"]:
		ext_k = 6.0
	var share: float = gdp / maxf(1.0, tot * ext_k + (0.0 if ccode in io_members(o) else gdp))
	var v: float = 8.0 + sqrt(share) * 110.0 + (io_avg_rel(o) - 50.0) * 0.3 + float(io["ibon"].get(o, 0.0))
	if o == "un" and turn < int(io.get("sc_until", -1)):
		v += 15.0
	return clampf(v, 0.0, 100.0)


func io_log(txt: String, col: String = "") -> void:
	(io["log"] as Array).push_front("%s — %s" % [date_short(), txt])
	if (io["log"] as Array).size() > 16:
		(io["log"] as Array).resize(16)
	log_line(("[color=%s]" % col if col != "" else "") + "Международные организации: " + txt + ("[/color]" if col != "" else ""))


# ---------- требования ----------
func io_req(id: String) -> Array:
	var ratio: float = debt / maxf(1.0, gdp) * 100.0
	var cor: float = float((rl["l"] as Dictionary)["cor"]) if rl_on() else 40.0
	var defe: float = float(rl["defe"]) if rl_on() else 2.0
	match id:
		"recog": return ["Государство признано большинством стран", ccode != "XK"]
		"dem40": return ["Индекс демократии не ниже 40%", democracy_index() >= 0.4]
		"dem50": return ["Индекс демократии не ниже 50%", democracy_index() >= 0.5]
		"dem60": return ["Индекс демократии не ниже 60%", democracy_index() >= 0.6]
		"cor55": return ["Коррупция не выше 55", cor <= 55.0]
		"cor45": return ["Коррупция не выше 45", cor <= 45.0]
		"def3": return ["Дефицит бюджета не выше 3% ВВП", defe <= 3.0]
		"debt90": return ["Госдолг не выше 90% ВВП", ratio <= 90.0]
		"debt70": return ["Госдолг не выше 70% ВВП", ratio <= 70.0]
		"infl35": return ["Инфляция не выше 3,5%", inflation <= 3.5]
		"market": return ["Рыночная экономика (не плановая)", econ_class() != "planned"]
		"notauth": return ["Нет диктатуры, хунты, однопартийности", not au_auth()]
		"noteaeu": return ["Не член ЕАЭС", not io_member("eaeu")]
		"notcsto": return ["Не член ОДКБ", not io_member("csto")]
		"notnato": return ["Не член НАТО", not io_member("nato")]
		"noteu": return ["Не член ЕС", not io_member("eu")]
		"ineu": return ["Член ЕС", io_member("eu")]
		"ineu_or_efta": return ["Член ЕС или ЕАСТ", io_member("eu") or io_member("efta")]
		"milspend": return ["Расходы на армию не ниже стандарта альянса", (not mil_on()) or mil_spend_ratio() >= 0.95]
		"rel45": return ["Средние отношения с членами не ниже 45", io_avg_rel("nato") >= 45.0]
		"border": return ["Надёжная охрана внешних границ", true]
		"nodeath": return ["Нет смертной казни", true]
		"rich": return ["Доход на душу не ниже 25 тыс. €", rl_pc() >= 25.0]
		"east": return ["Страна между Балтийским, Адриатическим и Чёрным морями", ccode in IO_EAST]
		"postsoviet": return ["Бывшая республика СССР", ccode in IO_POSTSOV]
		"blacksea": return ["Страна Черноморского региона", ccode in IO_BLACKSEA]
		"notrus": return ["Не ведёт агрессивную войну и не под санкциями Запада", not (mil_on() and mil_at_war() and war_aggressor() == ccode) and fa_ws_lvl() < 2]
		"nosanc": return ["Нет мировых санкций", fa_ws_lvl() == 0]
	if IO_GEO.has(id):
		return ["Входит в исторический круг стран-основательниц", ccode in IO_GEO[id]]
	return [id, true]


func io_reqs(o: String) -> Array:
	var out: Array = []
	for r in ORGS[o]["req"]:
		out.append(io_req(String(r)))
	for x in ORGS[o].get("excl", []):
		if io_member(String(x)):
			out.append(["Выйти из несовместимой организации: %s" % String(ORGS[String(x)]["sh"]), false])
	return out


# ---------- шаг ----------
func io_step() -> void:
	if io.is_empty():
		io_init()
	# взносы
	for o in ORG_ORDER:
		if io_member(o) and not ORGS[o].has("rl"):
			debt += gdp * float(ORGS[o]["fee"]) / 100.0 / 12.0
	# временные бонусы роста
	var gb: Array = io["gb"]
	for i in range(gb.size() - 1, -1, -1):
		if turn >= int(gb[i]["until"]):
			gb.remove_at(i)
	# заявки
	for o in (io["cand"] as Dictionary).keys():
		io_cand_step(String(o))
	# Совет Европы приостанавливает членство диктатур
	if io_member("coe") and au_auth() and not bool(io["susp"].get("coe", false)):
		io["susp"]["coe"] = true
		io["mem"]["coe"] = false
		dip_all(-3.0, true)
		io_log("Совет Европы исключил страну за отказ от демократии и прав человека.", COL_BAD)
	# сессии
	for o in ORG_ORDER:
		if not io_member(o):
			continue
		var pd: Dictionary = io["pend"].get(o, {})
		if not pd.is_empty() and turn - int(pd["t0"]) >= 2:
			io_vote(o, io_ai_vote(o), true)
		if turn >= int(io["next"][o]) and (io["pend"].get(o, {}) as Dictionary).is_empty():
			io["next"][o] = turn + int(ORGS[o]["per"])
			var ag: Array = ORGS[o]["agenda"]
			if ag.is_empty():
				continue
			var k: int = (turn / maxi(1, int(ORGS[o]["per"])) + o.length()) % ag.size()
			io["pend"][o] = {"i": k, "t0": turn}
			if observer:
				io_vote(o, io_ai_vote(o), true)


func io_cand_step(o: String) -> void:
	var a: Dictionary = io["cand"][o]
	var rs := io_reqs(o)
	var met := 0
	for r in rs:
		if bool(r[1]):
			met += 1
	a["met"] = met
	a["need"] = rs.size()
	a["m"] = int(a["m"]) + 1
	a["p"] = clampf(float(a["p"]) + float(met) / float(maxi(1, rs.size())) * 1.0 - 0.15, 0.0, 12.0)
	if float(a["p"]) >= 12.0 and met == rs.size():
		var veto: PackedStringArray = []
		for c in io_members(o):
			if c != ccode and dip.has(c) and (float(dip[c]["rel"]) < 35.0 or hist_rel(c) <= -3):
				veto.append(String(WORLD[c]["name"]) if WORLD.has(c) else c)
		if veto.size() > 0 and String(ORGS[o]["rule"]) in ["consensus", "twothirds"]:
			if int(a["m"]) % 6 == 0:
				io_log("Вступление в %s блокируют: %s. Нужно улучшить отношения." % [String(ORGS[o]["sh"]), ", ".join(veto)], COL_WARN)
			return
		io["mem"][o] = true
		(io["cand"] as Dictionary).erase(o)
		for c in io_members(o):
			if c != ccode and dip.has(c):
				dip_change(c, 2.0)
		add_all_support(1.0)
		io_log("Страна принята в организацию «%s»!" % String(ORGS[o]["n"]), COL_GOOD)


# эффекты членства — только отличие от стартового состава (то, что было на старте, уже в показателях страны)
func io_dyn() -> void:
	if io.is_empty() or mods.is_empty():
		return
	for o in ORG_ORDER:
		if ORGS[o].has("rl"):
			continue
		var now: bool = io_member(o)
		var was: bool = bool(io["mem0"].get(o, false))
		if now == was:
			continue
		var sgn: float = 1.0 if now else -1.0
		var fx: Dictionary = ORGS[o].get("fx", {})
		for k in fx:
			mods[k] = float(mods.get(k, 0.0)) + float(fx[k]) * sgn
	for b in io["gb"]:
		var key: String = String(b.get("k", "growth_bonus"))
		mods[key] = float(mods.get(key, 0.0)) + float(b["v"])


# ---------- голосование на сессии ----------
func io_item(o: String) -> Dictionary:
	var pd: Dictionary = io["pend"].get(o, {})
	if pd.is_empty():
		return {}
	return ORGS[o]["agenda"][int(pd["i"])]


func io_stance(it: Dictionary, c: String) -> int:
	if c in (it.get("pro", []) as Array):
		return 1
	if c in (it.get("con", []) as Array):
		return -1
	return 1 if (hash(c + io_ru_title(String(it["t"]))) % 4) != 0 else 0


# v54_1: позиция «по умолчанию» считается от русской формулировки вопроса и в английской версии
# (путь собран из частей, чтобы tools/i18n.py не перенаправил его в en/) — игра на обоих языках идёт одинаково
var io_ru_titles := {}


func io_ru_title(t: String) -> String:
	if io_ru_titles.is_empty():
		io_ru_titles[""] = ""
		var ru = load("res://" + "scripts/data/data_orgs.gd")
		var rorgs: Dictionary = ru.get_script_constant_map().get("ORGS", {}) if ru != null else {}
		for o in ORGS:
			var a: Array = (ORGS[o] as Dictionary).get("agenda", [])
			var b: Array = (rorgs.get(o, {}) as Dictionary).get("agenda", [])
			for i in mini(a.size(), b.size()):
				io_ru_titles[String(a[i]["t"])] = String(b[i]["t"])
	return String(io_ru_titles.get(t, t))


# голос ИИ-советника: с большинством союзников
func io_ai_vote(o: String) -> int:
	var it := io_item(o)
	if it.is_empty():
		return 0
	if ccode in (it.get("pro", []) as Array):
		return 1
	if ccode in (it.get("con", []) as Array):
		return -1
	var s := 0.0
	for c in io_members(o):
		if c != ccode and dip.has(c):
			s += float(io_stance(it, c)) * float(dip[c]["rel"])
	return 1 if s > 0.0 else (0 if s == 0.0 else -1)


# итог голосования (без применения): {"pass", "yes", "no", "ab", "veto"}
func io_tally(o: String, my: int) -> Dictionary:
	var it := io_item(o)
	var rule: String = String(it.get("rule", ORGS[o]["rule"]))
	var y := 0
	var n := 0
	var ab := 0
	var ypop := 0.0
	var tpop := 0.0
	var ygdp := 0.0
	var tgdp := 0.0
	var vetoer := ""
	for c in io_members(o):
		var v: int = my if c == ccode else io_stance(it, c)
		var p: float = float(WORLD[c]["pop"]) if WORLD.has(c) else 5.0
		var g: float = float(WORLD[c]["gdp"]) if WORLD.has(c) else 50.0
		tpop += p
		tgdp += g
		if v > 0:
			y += 1
			ypop += p
			ygdp += g
		elif v < 0:
			n += 1
			if vetoer == "":
				vetoer = c
			if c == ccode:
				vetoer = c
		else:
			ab += 1
	var tot: int = y + n + ab
	var ok := false
	match rule:
		"consensus":
			ok = n == 0
		"qmv":
			ok = float(y) >= 0.55 * float(tot) and ypop >= 0.65 * tpop
		"twothirds":
			ok = float(y) >= 2.0 / 3.0 * float(y + n)
		"weighted":
			ok = ygdp > 0.5 * tgdp
		_:
			ok = y > n
	return {"pass": ok, "yes": y, "no": n, "ab": ab, "veto": vetoer if rule == "consensus" and n > 0 else "", "rule": rule}


func io_vote(o: String, my: int, auto: bool = false) -> bool:
	if not auto and pl_deny():
		return false
	var it := io_item(o)
	if it.is_empty():
		return false
	var tl := io_tally(o, my)
	var ok: bool = bool(tl["pass"])
	# отношения: совпавшие голоса сближают, разошедшиеся — отдаляют
	if my != 0:
		for c in io_members(o):
			if c == ccode or not dip.has(c):
				continue
			var s := io_stance(it, c)
			if s == my:
				dip_change(c, 1.0)
			elif s == -my:
				dip_change(c, -1.0)
	if String(tl["veto"]) == ccode:
		for c2 in (it.get("pro", []) as Array):
			if dip.has(String(c2)):
				dip_change(String(c2), -1.5)
	if ok:
		io_apply_yes(o, it.get("yes", {}))
	var rec := {"t": String(it["t"]), "ok": ok, "y": int(tl["yes"]), "n": int(tl["no"]), "a": int(tl["ab"]), "my": my, "d": date_short()}
	var hl: Array = io["hist"].get(o, [])
	hl.push_front(rec)
	if hl.size() > 8:
		hl.resize(8)
	io["hist"][o] = hl
	(io["pend"] as Dictionary).erase(o)
	var mv: String = ["против", "воздержались", "за"][my + 1]
	io_log("%s: «%s» — %s (%d за, %d против, %d возд.; вы — %s)%s." % [String(ORGS[o]["sh"]), String(it["t"]), "принято" if ok else "отклонено", int(tl["yes"]), int(tl["no"]), int(tl["ab"]), mv,
		(", вето — %s" % (String(WORLD[String(tl["veto"])]["name"]) if WORLD.has(String(tl["veto"])) else String(tl["veto"]))) if String(tl["veto"]) != "" else ""], COL_GOOD if ok else COL_WARN)
	recompute_mods()
	return true


func io_apply_yes(o: String, fx: Dictionary) -> void:
	if fx.is_empty():
		return
	var f2 := {}
	for k in ["support", "dip", "debt"]:
		if fx.has(k):
			f2[k] = fx[k]
	if not f2.is_empty():
		apply_fx(f2)
	if fx.has("growth"):
		(io["gb"] as Array).append({"v": float(fx["growth"]), "until": turn + 24})
	if fx.has("sec"):
		(io["gb"] as Array).append({"k": "sec_bonus", "v": float(fx["sec"]), "until": turn + 36})
	if fx.has("risk"):
		risk_prem = clampf(risk_prem + float(fx["risk"]), 0.0, 3.0)


# ---------- действия ----------
const IO_GEN_ACTS := [["join", "Подать заявку на вступление", 8.0], ["leave", "Выйти из организации", 10.0], ["contrib", "Увеличить добровольный взнос (0,05% ВВП)", 3.0],
	["init", "Выдвинуть свою инициативу", 6.0]]


func io_act_list(o: String) -> Array:
	var out: Array = []
	var me := io_member(o)
	var d: Dictionary = ORGS[o]
	if d.has("rl"):
		var page: String = {"eu": "eu", "nato": "nato"}.get(String(d["rl"]), "")
		var keyset := {"eu": ["acc_eu"], "euro": ["acc_euro"], "nato": ["acc_nato", "leave_nato"], "schg": ["ctrl"]}
		for a in rl_acts("blocs"):
			if String(a["id"]) in keyset.get(String(d["rl"]), []):
				out.append({"id": "rl:" + String(a["id"]), "n": String(a["name"]), "cap": float(a["cap"]), "why": String(a["why"]), "tip": String(a["desc"])})
		if page != "":
			for a2 in rl_acts(page):
				out.append({"id": "rl:" + String(a2["id"]), "n": String(a2["name"]), "cap": float(a2["cap"]), "why": String(a2["why"]), "tip": String(a2["desc"])})
	else:
		if not me:
			out.append({"id": "join", "n": "Подать заявку на вступление", "cap": 8.0, "why": io_check(o, "join"), "tip": "Год переговоров при выполненных условиях; любой член с плохими отношениями может заблокировать (при консенсусе)."})
		elif o != "un":
			out.append({"id": "leave", "n": "Выйти из организации", "cap": 10.0, "why": io_check(o, "leave"), "tip": "Выгоды членства пропадут, члены организации обидятся."})
	if me:
		out.append({"id": "contrib", "n": "Увеличить добровольный взнос (0,05% ВВП)", "cap": 3.0, "why": io_check(o, "contrib"), "tip": "Влияние в организации +8."})
		out.append({"id": "init", "n": "Выдвинуть свою инициативу", "cap": 6.0, "why": io_check(o, "init"), "tip": "Успех зависит от влияния: при успехе рост +0,03 п. п. на 2 года, влияние +5 и отношения с членами лучше; при провале — капитал потрачен."})
		for a3 in d.get("acts", []):
			out.append({"id": String(a3[0]), "n": String(a3[1]), "cap": float(a3[2]), "why": io_check(o, String(a3[0])), "tip": String(a3[4])})
	return out


func io_check(o: String, id: String) -> String:
	var why := pl_why("gov")
	if why != "":
		return why
	if game_over:
		return "игра окончена"
	var me := io_member(o)
	var cost := 0.0
	var cdm := 0
	match id:
		"join":
			if me:
				return "уже член"
			if (io["cand"] as Dictionary).has(o):
				return "заявка рассматривается"
			if bool(io["susp"].get(o, false)) and au_auth():
				return "исключены за отказ от демократии"
			cost = 8.0
		"leave":
			if not me:
				return "не член"
			if o == "un":
				return "из ООН не выходят"
			cost = 10.0
		"contrib":
			cost = 3.0
			cdm = 12
		"init":
			cost = 6.0
			cdm = 12
		_:
			for a in ORGS[o].get("acts", []):
				if String(a[0]) == id:
					cost = float(a[2])
					cdm = int(a[3])
			if not me:
				return "только для членов"
			if id == "wb_loan" and rl_pc() >= 30.0:
				return "кредиты получают страны с доходом ниже 30 тыс. € на душу"
			if id == "csto_help" and reg_avg("unrest") < 30.0:
				return "беспорядков нет"
			if id == "union_cur" and bool(io["bon"].get("union_cur", false)):
				return "переговоры уже идут"
	if capital < cost:
		return "нужно %.0f капитала" % cost
	if int(io["cd"].get(o + ":" + id, -99)) > turn:
		return "ещё %d мес." % (int(io["cd"][o + ":" + id]) - turn)
	return ""


func io_act(o: String, id: String) -> bool:
	if id.begins_with("rl:"):
		return rl_do(id.substr(3))
	var why := io_check(o, id)
	if why != "":
		log_line("[color=%s]Нельзя: %s.[/color]" % [COL_WARN, why])
		return false
	var nm: String = String(ORGS[o]["sh"])
	match id:
		"join":
			capital -= 8.0
			io["cand"][o] = {"p": 0.0, "m": 0, "met": 0, "need": 1}
			io_log("Подана заявка на вступление в %s." % nm)
		"leave":
			capital -= 10.0
			io["mem"][o] = false
			(io["pend"] as Dictionary).erase(o)
			for c in io_members(o):
				if dip.has(c):
					dip_change(c, -3.0)
			io_log("Страна вышла из %s." % nm, COL_WARN)
		"contrib":
			capital -= 3.0
			debt += gdp * 0.0005
			io["ibon"][o] = minf(30.0, float(io["ibon"].get(o, 0.0)) + 8.0)
			io["cd"][o + ":contrib"] = turn + 12
			io_log("Увеличен взнос в %s: влияние выше." % nm)
		"init":
			capital -= 6.0
			io["cd"][o + ":init"] = turn + 12
			var p: float = clampf(0.25 + io_infl(o) / 100.0 * 0.7, 0.2, 0.9)
			if randf() < p:
				(io["gb"] as Array).append({"v": 0.03, "until": turn + 24})
				io["ibon"][o] = minf(30.0, float(io["ibon"].get(o, 0.0)) + 5.0)
				for c in io_members(o):
					if dip.has(c):
						dip_change(c, 1.0)
				io_log("Ваша инициатива в %s принята: совместная программа запущена." % nm, COL_GOOD)
			else:
				io_log("Ваша инициатива в %s не набрала поддержки (шанс был %.0f%%)." % [nm, p * 100.0], COL_WARN)
		_:
			io_special(o, id)
	recompute_mods()
	return true


func io_special(o: String, id: String) -> void:
	var cost := 0.0
	var cdm := 0
	for a in ORGS[o].get("acts", []):
		if String(a[0]) == id:
			cost = float(a[2])
			cdm = int(a[3])
	capital -= cost
	if cdm > 0:
		io["cd"][o + ":" + id] = turn + cdm
	match id:
		"un_sc":
			io["sc_until"] = turn + 24
			dip_all(2.0, false)
			io_log("Страна избрана непостоянным членом Совета Безопасности ООН на 2 года.", COL_GOOD)
		"un_peace":
			dip_all(2.0, false)
			debt += gdp * 0.0003
			add_support("Силовики", 1.0)
			io_log("Батальон миротворцев отправлен в миссию ООН.")
		"un_aid":
			debt += gdp * 0.0005
			io["ibon"][o] = minf(30.0, float(io["ibon"].get(o, 0.0)) + 6.0)
			io_log("Взнос в гуманитарные фонды ООН.")
		"osce_obs":
			dip_all(1.5, true)
			if not au.is_empty() and au_on():
				au["fraud"] = maxf(0.0, float(au["fraud"]) - 10.0)
			io_log("На выборы приглашены наблюдатели БДИПЧ ОБСЕ.")
		"osce_mission":
			var best := -1
			var bu := -1.0
			for i in regions.size():
				if float(regions[i]["unrest"]) > bu:
					bu = float(regions[i]["unrest"])
					best = i
			if best >= 0:
				regions[best]["unrest"] = maxf(0.0, float(regions[best]["unrest"]) - 10.0)
			io_log("Миссия ОБСЕ работает в регионе «%s»." % (String(REGIONS[best]["name"]) if best >= 0 else "—"))
		"osce_chair", "epc_host":
			io["ibon"][o] = minf(30.0, float(io["ibon"].get(o, 0.0)) + 12.0)
			dip_all(2.0, false)
			io_log("Страна принимает председательство / саммит: влияние выше.", COL_GOOD)
		"coe_echr":
			debt += gdp * 0.0001
			if rl_on():
				rl["l"]["jud"] = minf(98.0, float(rl["l"]["jud"]) + 3.0)
			dip_all(1.0, true)
			io_log("Решения ЕСПЧ исполнены, компенсации выплачены.")
		"coe_venice":
			if rl_on():
				rl_cor_add(-2.0)
			io_log("Венецианская комиссия дала заключение по законам.")
		"oecd_tax":
			io["bon"]["oecd_tax"] = true
			(io["gb"] as Array).append({"k": "growth_bonus", "v": -0.01, "until": turn + 600})
			debt -= gdp * 0.0005
			io_log("Страна ввела глобальный минимальный налог 15%.")
		"oecd_review":
			(io["gb"] as Array).append({"k": "eff_bonus", "v": 0.005, "until": turn + 36})
			io_log("Опубликован обзор экономики ОЭСР с рекомендациями.")
		"wto_case":
			io_log("Жалоба подана в ВТО: торговые споры урегулированы в вашу пользу.")
			if not ex.is_empty():
				for c in ex["p"]:
					ex["p"][c]["ret"] = 0
		"imf_loan":
			io["imf_until"] = turn + 24
			risk_prem = maxf(0.0, risk_prem - 0.4)
			add_support("Бюджетники", -4.0)
			add_support("Пенсионеры", -3.0)
			io_log("МВФ одобрил программу: деньги и доверие инвесторов в обмен на экономию.", COL_WARN)
		"imf_art4":
			risk_prem = maxf(0.0, risk_prem - 0.02)
			io_log("Опубликован доклад МВФ по статье IV.")
		"wb_loan":
			debt += gdp * 0.01
			(io["gb"] as Array).append({"v": 0.05, "until": turn + 48})
			io_log("Всемирный банк выделил кредит на инфраструктуру.")
		"wb_donor":
			debt += gdp * 0.0005
			io["ibon"][o] = minf(30.0, float(io["ibon"].get(o, 0.0)) + 6.0)
			io_log("Взнос в фонд МАР Всемирного банка.")
		"efta_fta", "cefta_market", "3si_fund", "bnl_energy", "balt_rail", "guam_corr", "cis_trade", "eaeu_energy":
			var dv := {"efta_fta": 0.03, "cefta_market": 0.04, "3si_fund": 0.04, "bnl_energy": 0.02, "balt_rail": 0.03, "guam_corr": 0.02, "cis_trade": 0.02, "eaeu_energy": 0.04}
			var dd := {"3si_fund": 0.001, "balt_rail": 0.002}
			(io["gb"] as Array).append({"v": float(dv[id]), "until": turn + 36})
			debt += gdp * float(dd.get(id, 0.0))
			if id == "guam_corr":
				dip_change("RU", -2.0)
			if id == "cis_trade" or id == "eaeu_energy":
				dip_change("RU", 2.0)
			if id == "efta_fta":
				add_support("Село", -1.0)
			io_log("Запущен совместный проект: %s." % id)
		"v4_common":
			io["ibon"]["eu"] = minf(30.0, float(io["ibon"].get("eu", 0.0)) + 5.0)
			dip_all(-0.5, true)
			io_log("Вишеградская четвёрка выступила с общей позицией.")
		"nord_def":
			(io["gb"] as Array).append({"k": "sec_bonus", "v": 1.0, "until": turn + 48})
			io_log("Северное оборонное сотрудничество расширено.")
		"csto_help":
			for r in regions:
				r["unrest"] = maxf(0.0, float(r["unrest"]) - 8.0)
			add_support("Силовики", 2.0)
			dip_all(-3.0, true)
			dip_change("RU", 3.0)
			io_log("Силы ОДКБ введены для «восстановления порядка».", COL_WARN)
		"union_gas":
			(io["gb"] as Array).append({"v": 0.06, "until": turn + 24})
			io_log("Скидка на газ и кредит партнёра по Союзному государству.")
		"union_cur":
			io["bon"]["union_cur"] = true
			(io["gb"] as Array).append({"k": "dem_shift", "v": -0.03, "until": turn + 600})
			add_support("Молодёжь", -3.0)
			io_log("Начаты переговоры о единой валюте Союзного государства.", COL_WARN)
		"franco_edu":
			dip_change("FR", 2.0)
			dip_change("BE", 1.0)
			io_log("Открыты франкоязычные школы и стипендии.")
