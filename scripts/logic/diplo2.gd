# Дипломатия, разведка, вмешательство в конфликты, признание новых государств, армия как политический игрок,
# совместные научные проекты, открытия и этика технологий (v44_1).
# Состояние — словарь dx. Работает только при включённом модуле «Государство и мир» (game_opts["rlev"] > 0).
extends "res://scripts/logic/realism.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func fpai_resolve(opt: Dictionary) -> void:
	pass


# --- конец заглушек ---


const DX_TREATIES := [
	{"id": "tech", "name": "Научный обмен", "cap": 5.0, "rel": 55.0, "desc": "Обмен учёными и данными: скорость исследований +2%, пассивное изучение от партнёра быстрее. Расход 0,02% ВВП в год."},
	{"id": "energy", "name": "Энергетическое партнёрство", "cap": 5.0, "rel": 50.0, "desc": "Долгие контракты и общие сети: зависимость от импорта энергии постепенно падает, скачки цен слабее."},
	{"id": "defense", "name": "Оборонный союз", "cap": 6.0, "rel": 65.0, "desc": "Совместные учения: партнёр помогает в гражданских конфликтах и сдерживает шпионов. Силовики довольны."},
	{"id": "visa", "name": "Безвизовый режим и мобильность", "cap": 4.0, "rel": 50.0, "desc": "Туризм и деловые поездки: рост +0,03 п.п. Чуть больше миграционного напряжения."},
	{"id": "nagg", "name": "Договор о ненападении и добрососедстве", "cap": 4.0, "rel": 40.0, "desc": "Отношения не опускаются ниже 40, риск войны с партнёром резко ниже."},
]
const DX_SPY := [
	{"id": "steal", "name": "Кража технологий", "cap": 5.0, "cd": 8, "desc": "Агенты добывают чертежи: текущее исследование получает +25% стоимости. Провал — скандал и отношения −8."},
	{"id": "destab", "name": "Поддержка оппозиции в стране", "cap": 6.0, "cd": 12, "desc": "Деньги и СМИ для оппозиции: стабильность страны −6. Провал — серьёзный скандал (−12 к отношениям)."},
	{"id": "cyber", "name": "Кибератака", "cap": 6.0, "cd": 10, "desc": "Парализует часть инфраструктуры: ВВП страны −0,2%, инфляция +0,2. Провал — отношения −10."},
]
const DX_CI_COST := [0.0, 0.03, 0.06, 0.1]   # % ВВП в год по уровню контрразведки

var dx: Dictionary = {}


func dx_on() -> bool:
	return rl_on() and not dx.is_empty()


func dx_init() -> void:
	dx = {"tr": {}, "ci": 0, "exposed": 0, "spylog": [], "cd": {}, "ndone": 0, "proj": [], "eth": 0, "adj": [], "bd": 0,
		"rec": {}, "army": {"loy": 55.0, "amb": 20.0}, "log": [], "last_pk": -99}
	var dem: float = democracy_index()
	dx["army"]["loy"] = 55.0 + (1.0 - dem) * 10.0
	dx["army"]["amb"] = 15.0 + (1.0 - dem) * 30.0
	tech_adj = 1.0
	tech_pas_mult = 1.0


func dx_log(text: String, col: String = "") -> void:
	var lg: Array = dx["log"]
	lg.append("%s: %s" % [date_text(), text])
	while lg.size() > 40:
		lg.pop_front()
	log_tag("ДИПЛОМАТИЯ", col if col != "" else COL_DIM, text)


func dx_cd_get(k: String) -> int:
	return int((dx["cd"] as Dictionary).get(k, 0))


func dx_countries() -> Array:
	var out: Array = []
	for c in wsim:
		if c != ccode and not w_minor(String(c)):
			out.append(String(c))
	out.sort()
	return out


func dx_name(c: String) -> String:
	if WORLD.has(c):
		return String(WORLD[c].get("name", c))
	return c


# ============================================================
#  ЕЖЕМЕСЯЧНЫЙ ШАГ
# ============================================================
func diplo_month() -> void:
	if not rl_on():
		return
	if dx.is_empty():
		dx_init()
	var cd: Dictionary = dx["cd"]
	for k in cd.keys():
		cd[k] = int(cd[k]) - 1
		if int(cd[k]) <= 0:
			cd.erase(k)
	dx_treaty_step()
	dx_spy_step()
	dx_conf_month()
	dx_rec_step()
	dx_army_step()
	dx_science_step()


# ---------- Б6. Договоры ----------
func dx_treaty_step() -> void:
	var tr: Dictionary = dx["tr"]
	var n_tech := 0
	var g := 0.0
	for c in tr.keys():
		var t: Dictionary = tr[c]
		var rel: float = fed_rel(String(c))
		if rel < 30.0:
			dx_log("отношения с «%s» рухнули — договоры расторгнуты." % dx_name(String(c)), COL_BAD)
			tr.erase(c)
			continue
		if bool(t.get("tech", false)):
			n_tech += 1
			debt += gdp * 0.02 / 100.0 / 12.0
		if bool(t.get("energy", false)):
			var e: Dictionary = rl["e"]
			e["dep"] = maxf(2.0, float(e["dep"]) - 0.05)
			if float(e["price"]) > 110.0:
				e["price"] = float(e["price"]) - 1.5
		if bool(t.get("defense", false)):
			ex_rel_change(String(c), 0.05)
		if bool(t.get("visa", false)):
			g += 0.03
		if bool(t.get("nagg", false)) and rel < 40.0:
			ex_rel_change(String(c), (40.0 - rel) * 0.1)
		# v50: пункты из конструктора договоров
		if bool(t.get("trade", false)):
			g += 0.025
		if bool(t.get("culture", false)):
			ex_rel_change(String(c), 0.08)
		if bool(t.get("invest", false)):
			g += 0.02
			debt += gdp * 0.01 / 100.0 / 12.0
		if bool(t.get("migr", false)) and rv_on():
			var nat: Dictionary = rv["nat"]
			nat["wave"] = rv_clamp(float(nat["wave"]) - 0.05)
	rl["g"] = float(rl["g"]) + g
	dx["n_tech"] = n_tech


func dx_has_treaty(c: String, id: String) -> bool:
	return (dx["tr"] as Dictionary).has(c) and bool(dx["tr"][c].get(id, false))


# ---------- Б7. Разведка ----------
func dx_spy_step() -> void:
	var ci: int = int(dx["ci"])
	if ci > 0:
		debt += gdp * float(DX_CI_COST[ci]) / 100.0 / 12.0
	if observer or not current_event.is_empty():
		return
	for c in tech_nb():
		var rel: float = fed_rel(String(c))
		if rel >= 35.0 and not (rel < 45.0 and randf() < 0.0):
			continue
		var p: float = 0.018 * (1.0 - 0.25 * float(ci)) * (1.0 - (0.5 if dx_has_treaty(String(c), "defense") else 0.0))
		if randf() >= p:
			continue
		var kinds := ["leak", "cyber", "theft", "sabotage"]
		var kd: String = kinds[randi() % kinds.size()]
		var nm: String = dx_name(String(c))
		if ci >= 2 and randf() < 0.35:
			dx_log("контрразведка раскрыла операцию спецслужб «%s» (%s): отношения ухудшились, но ущерба нет." % [nm, kd], COL_GOOD)
			ex_rel_change(String(c), -3.0)
			continue
		match kd:
			"leak":
				add_all_support(-1.5)
				dx_log("утечка секретных документов, за которой стоят спецслужбы «%s»: рейтинг пострадал." % nm, COL_BAD)
			"cyber":
				debt += gdp * 0.2 / 100.0
				dx_log("кибератака на инфраструктуру из «%s»: убытки 0,2%% ВВП." % nm, COL_BAD)
			"theft":
				var cur: String = ""
				if not tech.is_empty():
					for b in TECH_NB:
						if String(tech["cur"][b]) != "":
							cur = String(tech["cur"][b])
							break
				if cur != "":
					tech["prog"][cur] = maxf(0.0, float(tech["prog"].get(cur, 0.0)) - float(tech_def(cur)["cost"]) * 0.1)
				dx_log("промышленный шпионаж: из страны «%s» украдены разработки." % nm, COL_BAD)
			"sabotage":
				if rl_on():
					rl["e"]["price"] = minf(300.0, float(rl["e"]["price"]) + 20.0)
				dx_log("диверсия на энергосетях, след ведёт в «%s»." % nm, COL_BAD)
		ex_rel_change(String(c), -2.0)


func dx_target_ok(c: String) -> bool:
	return c != ccode and wsim.has(c) and not w_minor(String(c))


# ---------- Г1. Вмешательство в конфликты ----------
func dx_conf_month() -> void:
	if not rv_on():
		return
	for k in (rv["conf"] as Array).size():
		var c: Dictionary = rv["conf"][k]
		if not c.has("fi"):
			c["fi"] = {"gov": [], "reb": [], "pk": false}
		var fi: Dictionary = c["fi"]
		if int(c["truce"]) > 0 and int(c["truce"]) < 9000:
			continue
		# чужая помощь повстанцам от враждебных соседей, помощь правительству от оборонных партнёров
		for p in tech_nb():
			var rel: float = fed_rel(String(p))
			if rel < 33.0 and (fi["reb"] as Array).size() < 3 and not (String(p) in fi["reb"]) and randf() < 0.05 and String(c["side"]) == "gov":
				(fi["reb"] as Array).append(String(p))
				c["aid"] = float(c["aid"]) + 1.2
				ex_rel_change(String(p), -2.0)
				dx_log("«%s» тайно помогает повстанцам в конфликте «%s»: оружие и деньги идут через границу." % [dx_name(String(p)), c["name"]], COL_BAD)
			if dx_has_treaty(String(p), "defense") and (fi["gov"] as Array).size() < 2 and not (String(p) in fi["gov"]):
				(fi["gov"] as Array).append(String(p))
				c["gaid"] = float(c["gaid"]) + 2.0
				dx_log("союзник «%s» по оборонному договору помогает правительству в конфликте «%s»." % [dx_name(String(p)), c["name"]], COL_GOOD)
		# предложение миротворцев
		var months: int = turn - int(c["start"])
		if months >= 8 and float(c["kia"]) > 1.5 and not bool(fi["pk"]) and turn - int(dx["last_pk"]) > 18 and int(c["truce"]) == 0 and randf() < 0.06:
			dx["last_pk"] = turn
			rl_event("dxpk", "Евросоюз и ООН предлагают ввести миротворцев в зону конфликта «%s»: потери растут, беженцев всё больше." % c["name"], [
				{"l": "Принять миротворцев и перемирие на год (капитал −3)", "fx": {"capital": -3.0}, "act": "dx_pk_yes", "arg": str(int(c["id"]))},
				{"l": "Отказаться: это внутреннее дело", "fx": {"support": {"Силовики": 1.0}}, "act": "dx_pk_no", "arg": str(int(c["id"]))}])
			return


func dx_conf_by_id(cid: int) -> int:
	if rv.is_empty():
		return -1
	for k in (rv["conf"] as Array).size():
		if int(rv["conf"][k]["id"]) == cid:
			return k
	return -1


func dx_conf_acts(k: int) -> Array:
	var out: Array = []
	if not dx_on() or k < 0 or k >= (rv["conf"] as Array).size():
		return out
	var c: Dictionary = rv["conf"][k]
	var fi: Dictionary = c.get("fi", {"gov": [], "reb": [], "pk": false})
	out.append({"id": "conf_peace", "name": "Мирная конференция с посредниками", "cap": 8.0,
		"desc": "Шанс зависит от отношений с посредниками, перемирия, миротворцев и баланса сил. Итог: автономия (если сильнее правительство) или мирный развод (если сильнее повстанцы)."})
	out.append({"id": "conf_pk", "name": "Запросить миротворцев ЕС/ООН", "cap": 5.0,
		"desc": "Миротворцы вводят годовое перемирие и наблюдают за ним. Репутация правительства растёт, а свобода рук падает."})
	for a in out:
		a["ok"] = true
		a["why"] = ""
		if capital < float(a["cap"]):
			a["ok"] = false
			a["why"] = "нужно %.0f капитала" % float(a["cap"])
		elif dx_cd_get(String(a["id"]) + str(int(c["id"]))) > 0:
			a["ok"] = false
			a["why"] = "перерыв %d мес." % dx_cd_get(String(a["id"]) + str(int(c["id"])))
		elif String(a["id"]) == "conf_pk" and bool(fi.get("pk", false)):
			a["ok"] = false
			a["why"] = "уже введены"
		elif String(c["side"]) == "rebel":
			a["ok"] = false
			a["why"] = "вы — повстанцы"
	return out


func dx_conf_do(id: String, k: int) -> bool:
	if not dx_on() or observer or not current_event.is_empty():
		return false
	var acts := dx_conf_acts(k)
	var a: Dictionary = {}
	for x in acts:
		if String(x["id"]) == id:
			a = x
	if a.is_empty() or not bool(a["ok"]):
		return false
	var c: Dictionary = rv["conf"][k]
	if not c.has("fi"):
		c["fi"] = {"gov": [], "reb": [], "pk": false}
	var cid: int = int(c["id"])
	capital -= float(a["cap"])
	(dx["cd"] as Dictionary)[id + str(cid)] = 8
	if id == "conf_pk":
		c["fi"]["pk"] = true
		c["truce"] = 12
		dip_all(1.0, false)
		dx_log("миротворцы введены в зону конфликта «%s»: перемирие на год." % c["name"], COL_GOOD)
		return true
	# conf_peace
	var ctl: float = float(c["ctl"])
	var p: float = 0.28 + (rl_avg_rel() - 50.0) * 0.004 + (0.14 if int(c["truce"]) > 0 else 0.0) + (0.14 if bool(c["fi"]["pk"]) else 0.0) + (0.12 if absf(ctl - 50.0) < 22.0 else 0.0)
	p = clampf(p, 0.1, 0.8)
	if randf() < p:
		if ctl >= 58.0 and String(c["kind"]) == "secession":
			dx_log("[b]мирная конференция по «%s» завершилась соглашением:[/b] регион уходит мирно, долг делится." % c["name"], COL_WARN)
			rv_conf_end(k, "recognize")
		else:
			dx_log("[b]мирная конференция по «%s» завершилась соглашением:[/b] автономия и амнистия вместо войны (шанс был %.0f%%)." % [c["name"], p * 100.0], COL_GOOD)
			rv_conf_end(k, "deal")
	else:
		c["talk_cd"] = 6
		ex_rel_change(dx_pick_neighbor(), -1.0)
		dx_log("конференция по «%s» сорвалась: стороны не договорились (шанс был %.0f%%)." % [c["name"], p * 100.0], COL_BAD)
	refresh()
	return true


func dx_pick_neighbor() -> String:
	var nb: Array = tech_nb()
	return String(nb[0]) if nb.size() > 0 else String(dx_countries()[0])


# ---------- Г3. Признание новых государств ----------
func dx_rec_step() -> void:
	if not rv_on():
		return
	var rec: Dictionary = dx["rec"]
	for st in rv["states"]:
		var code: String = String(st["code"])
		if not rec.has(code):
			rec[code] = {"by": [], "blk": 0, "us": false, "un": false}
		var r: Dictionary = rec[code]
		if int(r["blk"]) > 0:
			r["blk"] = int(r["blk"]) - 1
		var base: float = 0.05 if String(st["how"]) != "war" else 0.02
		var have: Array = r["by"]
		for c in dx_countries():
			if c in have or c == code:
				continue
			var rel: float = fed_rel(c)
			var p: float = base * (1.0 + (50.0 - rel) / 50.0)
			# члены ЕС и НАТО из блока осторожны, если мы их союзник
			if rel > 60.0:
				p *= 0.35
			if bool(WORLD.get(c, {}).get("eu", false)) and bool(rl["b"]["eu"]) and String(st["how"]) != "peace":
				p *= 0.5
			if int(r["blk"]) > 0:
				p *= 0.4
			if randf() < p:
				have.append(c)
				if rel > 55.0 and String(st["how"]) == "war":
					ex_rel_change(c, 0.0)
				elif rel < 55.0:
					ex_rel_change(c, 0.5)
		var share: float = float(have.size()) / maxf(1.0, float(dx_countries().size()))
		if share >= 0.5 and not bool(r["un"]):
			r["un"] = true
			dx_log("новое государство «%s» признано более чем половиной стран и принято в ООН." % st["name"], COL_WARN)
		if wsim.has(code):
			wsim[code]["growth"] = float(wsim[code]["growth"]) + (share - 0.3) * 0.02
			wsim[code]["stab"] = clampf(float(wsim[code]["stab"]) + (share - 0.35) * 0.1, 10.0, 95.0)


func dx_rec_text() -> String:
	var t := ""
	for st in rv.get("states", []):
		var code: String = String(st["code"])
		var r: Dictionary = (dx["rec"] as Dictionary).get(code, {"by": [], "un": false, "us": false})
		t += "«%s»: признали %d из %d стран%s%s\n" % [st["name"], (r["by"] as Array).size(), dx_countries().size(), ", член ООН" if bool(r["un"]) else "", ", вы признали" if bool(r["us"]) else ""]
	return t


func dx_rec_acts() -> Array:
	var out: Array = []
	if not dx_on():
		return out
	for st in rv.get("states", []):
		var code: String = String(st["code"])
		var r: Dictionary = (dx["rec"] as Dictionary).get(code, {"blk": 0, "us": false})
		out.append({"id": "rec_lobby", "arg": code, "name": "Дипломатическая кампания против признания: %s" % st["name"], "cap": 6.0,
			"desc": "Убедить партнёров не признавать: на год вероятность признания падает более чем вдвое.",
			"ok": capital >= 6.0 and dx_cd_get("lobby" + code) == 0, "why": "" if capital >= 6.0 and dx_cd_get("lobby" + code) == 0 else "капитал/перерыв"})
		out.append({"id": "rec_us", "arg": code, "name": "Признать самим: %s" % st["name"], "cap": 2.0,
			"desc": "Отношения с новым государством улучшаются, но партнёры по ЕС недовольны.",
			"ok": capital >= 2.0 and not bool(r["us"]), "why": "" if capital >= 2.0 and not bool(r["us"]) else "уже признали/нет капитала"})
	return out


func dx_rec_do(id: String, code: String) -> bool:
	if not dx_on() or observer or not current_event.is_empty() or not (dx["rec"] as Dictionary).has(code):
		return false
	var r: Dictionary = dx["rec"][code]
	if id == "rec_lobby":
		if capital < 6.0 or dx_cd_get("lobby" + code) > 0:
			return false
		capital -= 6.0
		r["blk"] = 12
		(dx["cd"] as Dictionary)["lobby" + code] = 12
		dx_log("дипломатическая кампания против признания «%s» запущена." % code, COL_DIM)
		return true
	if id == "rec_us":
		if capital < 2.0 or bool(r["us"]):
			return false
		capital -= 2.0
		r["us"] = true
		if not (ccode in r["by"]):
			pass
		for c in dx_countries():
			if bool(WORLD.get(c, {}).get("eu", false)):
				ex_rel_change(c, -0.4)
		dx_log("вы признали независимость «%s»." % code, COL_WARN)
		return true
	return false


# ---------- Г5. Армия как политический игрок ----------
func dx_army_step() -> void:
	var a: Dictionary = dx["army"]
	var loy: float = float(a["loy"])
	var amb: float = float(a["amb"])
	var spend: float = mil_spend_ratio() if mil_on() else 1.0
	var target: float = 45.0 + (spend - 1.0) * 25.0 + (float(support["Силовики"]) - 45.0) * 0.4 + (democracy_index() - 0.5) * 8.0
	if rv_on():
		for c in rv["conf"]:
			if float(c["ctl"]) > 55.0 and String(c["side"]) == "gov":
				target -= 6.0
	loy += (target - loy) * 0.03
	if loy < 40.0:
		amb += 0.15
	else:
		amb -= 0.05
	amb = clampf(amb + (0.6 - democracy_index()) * 0.02, 0.0, 100.0)
	a["loy"] = clampf(loy, 0.0, 100.0)
	a["amb"] = amb
	if rv_on():
		var nat: Dictionary = rv["nat"]
		nat["coup"] = rv_clamp(float(nat["coup"]) + maxf(0.0, 45.0 - loy) * 0.04 + maxf(0.0, amb - 50.0) * 0.03)
	if amb > 55.0 and dx_cd_get("gen") == 0 and current_event.is_empty() and not observer and randf() < 0.02:
		(dx["cd"] as Dictionary)["gen"] = 24
		rl_event("dxgen", "Генералы собрались у министра обороны и заявили: армия «устала от политиков». Они требуют больше денег и места в принятии решений.", [
			{"l": "Удовлетворить: бюджет армии выше (капитал −2)", "fx": {"capital": -2.0, "slider": {"army": 0.15}}, "act": "dx_gen_pay"},
			{"l": "Отказать и усилить гражданский контроль (капитал −6)", "fx": {"capital": -6.0}, "act": "dx_gen_civil"},
			{"l": "Дать генералам место в правительстве", "fx": {"support": {"Силовики": 3.0}}, "act": "dx_gen_seat"}])


func dx_army_acts() -> Array:
	var out: Array = []
	if not dx_on():
		return out
	out.append({"id": "army_civil", "name": "Реформа гражданского контроля над армией", "cap": 8.0, "cd": 36,
		"desc": "Парламентский надзор, ротация командиров: амбиции генералов −15, лояльность −5. Долгосрочно снижает риск переворота."})
	out.append({"id": "army_loyal", "name": "Назначить лояльных командиров", "cap": 5.0, "cd": 12,
		"desc": "Лояльность армии +10, но коррупция растёт и профессионалы недовольны."})
	out.append({"id": "army_bonus", "name": "Разовая выплата и льготы военным (долг +0,2% ВВП)", "cap": 3.0, "cd": 12,
		"desc": "Лояльность +7, амбиции +2."})
	for a in out:
		var cdk: int = dx_cd_get(String(a["id"]))
		a["ok"] = cdk == 0 and capital >= float(a["cap"])
		a["why"] = "" if bool(a["ok"]) else ("перерыв %d мес." % cdk if cdk > 0 else "нужно %.0f капитала" % float(a["cap"]))
	return out


func dx_army_do(id: String) -> bool:
	if not dx_on() or observer or not current_event.is_empty():
		return false
	var found: Dictionary = {}
	for a in dx_army_acts():
		if String(a["id"]) == id:
			found = a
	if found.is_empty() or not bool(found["ok"]):
		return false
	capital -= float(found["cap"])
	(dx["cd"] as Dictionary)[id] = int(found["cd"])
	var ar: Dictionary = dx["army"]
	match id:
		"army_civil":
			ar["amb"] = maxf(0.0, float(ar["amb"]) - 15.0)
			ar["loy"] = maxf(0.0, float(ar["loy"]) - 5.0)
			add_support("Силовики", -1.0)
			dx_log("проведена реформа гражданского контроля над армией.", COL_GOOD)
		"army_loyal":
			ar["loy"] = minf(100.0, float(ar["loy"]) + 10.0)
			rl_cor_add(1.5)
			dx_log("в штабах — лояльные командиры.", COL_DIM)
		"army_bonus":
			ar["loy"] = minf(100.0, float(ar["loy"]) + 7.0)
			ar["amb"] = minf(100.0, float(ar["amb"]) + 2.0)
			debt += gdp * 0.2 / 100.0
			add_support("Силовики", 2.0)
			dx_log("военным выплачены премии и льготы.", COL_DIM)
	return true


# ============================================================
#  НАУКА: проекты, открытия, этика
# ============================================================
func dx_science_step() -> void:
	if tech.is_empty():
		return
	# утечка умов и временные поправки скорости
	var adj: Array = dx["adj"]
	var mult := 1.0
	for i in range(adj.size() - 1, -1, -1):
		var a: Dictionary = adj[i]
		mult *= float(a["m"])
		a["left"] = int(a["left"]) - 1
		if int(a["left"]) <= 0:
			adj.remove_at(i)
	# договоры научного обмена
	mult *= 1.0 + 0.02 * float(mini(3, int(dx.get("n_tech", 0))))
	# совместные проекты
	var proj: Array = dx["proj"]
	var pm := 1.0
	for i in range(proj.size() - 1, -1, -1):
		var p: Dictionary = proj[i]
		mult *= 1.05
		pm += 0.6
		debt += gdp * 0.15 / 100.0 / 24.0
		p["left"] = int(p["left"]) - 1
		if int(p["left"]) <= 0:
			dx_log("совместный научный проект с «%s» завершён." % dx_name(String(p["cc"])), COL_GOOD)
			proj.remove_at(i)
	tech_pas_mult = pm
	# этика технологий замедляет исследования
	mult *= 1.0 - 0.05 * float(int(dx["eth"]))
	tech_adj = mult
	# открытия
	var nd: int = (tech["done"] as Dictionary).size()
	if nd > int(dx["ndone"]):
		var fresh: int = nd - int(dx["ndone"])
		dx["ndone"] = nd
		if fresh > 0 and dx_cd_get("disc") == 0 and current_event.is_empty() and not observer and randf() < 0.35:
			(dx["cd"] as Dictionary)["disc"] = 10
			dx_discovery_event()
			return
	# утечка умов: слабые институты, низкая свобода
	if dx_cd_get("brain") == 0 and current_event.is_empty() and not observer:
		var bad: float = maxf(0.0, 45.0 - float(rl["m"]["free"])) * 0.1 + maxf(0.0, float(rl["l"]["cor"]) - 55.0) * 0.1
		if bad > 0.5 and randf() < 0.004 * bad:
			(dx["cd"] as Dictionary)["brain"] = 36
			rl_event("dxbrain", "Лучшие учёные и инженеры уезжают за границу: платят больше, а работать там спокойнее. Научные центры пустеют.", [
				{"l": "Повысить зарплаты учёных и дать гранты (долг +0,4% ВВП)", "fx": {"debt": 0.4}, "act": "dx_brain_pay"},
				{"l": "Программа возвращения: налоговые льготы (капитал −4)", "fx": {"capital": -4.0, "support": {"Бизнес": 1.0}}, "act": "dx_brain_ret"},
				{"l": "Ничего не делать", "fx": {}, "act": "dx_brain_none"}])


func dx_discovery_event() -> void:
	rl_event("dxdisc", "Учёные страны совершили прорыв, о котором пишут мировые журналы. Вокруг открытия — ажиотаж, инвесторы и министры обороны уже звонят.", [
		{"l": "Открыть данные миру: престиж и сотрудничество (рейтинг +1)", "fx": {"all": 1.0}, "act": "dx_disc_open"},
		{"l": "Коммерциализировать: патенты и стартапы (Бизнес +3)", "fx": {"support": {"Бизнес": 3.0}}, "act": "dx_disc_biz"},
		{"l": "Передать армии: засекретить (Силовики +3)", "fx": {"support": {"Силовики": 3.0}}, "act": "dx_disc_mil"}])


func diplo_resolve(opt: Dictionary) -> void:
	var act := String(opt.get("act", ""))
	match act:
		"dx_pk_yes":
			var k: int = dx_conf_by_id(int(String(opt.get("arg", "-1"))))
			if k >= 0:
				var c: Dictionary = rv["conf"][k]
				if not c.has("fi"):
					c["fi"] = {"gov": [], "reb": [], "pk": false}
				c["fi"]["pk"] = true
				c["truce"] = 12
				dip_all(1.0, false)
				dx_log("миротворцы введены в зону конфликта «%s»: перемирие на год." % c["name"], COL_GOOD)
		"dx_pk_no":
			dip_all(-0.5, false)
			dx_log("предложение о миротворцах отклонено.", COL_WARN)
		"dx_gen_pay":
			dx["army"]["loy"] = minf(100.0, float(dx["army"]["loy"]) + 8.0)
			dx["army"]["amb"] = minf(100.0, float(dx["army"]["amb"]) + 4.0)
		"dx_gen_civil":
			dx["army"]["loy"] = maxf(0.0, float(dx["army"]["loy"]) - 6.0)
			dx["army"]["amb"] = maxf(0.0, float(dx["army"]["amb"]) - 10.0)
			if rv_on() and randf() < 0.35:
				rv["nat"]["coup"] = rv_clamp(float(rv["nat"]["coup"]) + 10.0)
				dx_log("генералы оскорблены отказом: слухи о заговоре.", COL_BAD)
		"dx_gen_seat":
			dx["army"]["loy"] = minf(100.0, float(dx["army"]["loy"]) + 12.0)
			dx["army"]["amb"] = minf(100.0, float(dx["army"]["amb"]) + 8.0)
			rl["l"]["jud"] = maxf(3.0, float(rl["l"]["jud"]) - 3.0)
			rl["l"]["j0"] = float(rl["l"]["j0"]) - 3.0
		"dx_brain_pay":
			(dx["adj"] as Array).append({"m": 0.99, "left": 6})
		"dx_brain_ret":
			(dx["adj"] as Array).append({"m": 0.985, "left": 12})
		"dx_brain_none":
			(dx["adj"] as Array).append({"m": 0.94, "left": 24})
			dx_log("утечка умов замедляет науку.", COL_BAD)
		"dx_disc_open":
			rl["m"]["trust"] = minf(95.0, float(rl["m"]["trust"]) + 2.0)
			dip_all(1.0, false)
			tech_pas_mult *= 1.0
		"dx_disc_biz":
			rl["g"] = float(rl["g"]) + 0.0
			shock += 0.3
		"dx_disc_mil":
			if mods.has("army_q"):
				dx["adj"].append({"m": 1.0, "left": 1})
			add_support("Молодёжь", -1.0)
		_:
			fpai_resolve(opt)


# ============================================================
#  ДЕЙСТВИЯ: договоры, разведка, проекты, этика
# ============================================================
func dx_treaty_acts(c: String) -> Array:
	var out: Array = []
	if not dx_on() or not dx_target_ok(c):
		return out
	var rel: float = fed_rel(c)
	for d in DX_TREATIES:
		var id: String = String(d["id"])
		var have: bool = dx_has_treaty(c, id)
		var a := {"id": "tr_" + id, "name": ("Расторгнуть: " if have else "Заключить: ") + String(d["name"]), "cap": 0.0 if have else float(d["cap"]), "desc": d["desc"], "arg": c}
		a["ok"] = true
		a["why"] = ""
		if not have and rel < float(d["rel"]):
			a["ok"] = false
			a["why"] = "нужны отношения %.0f (сейчас %.0f)" % [float(d["rel"]), rel]
		elif not have and capital < float(d["cap"]):
			a["ok"] = false
			a["why"] = "нужно %.0f капитала" % float(d["cap"])
		elif not have and id == "tech" and int(dx.get("n_tech", 0)) >= 3:
			a["ok"] = false
			a["why"] = "не больше трёх научных обменов"
		out.append(a)
	var pa := {"id": "proj", "name": "Совместный научный проект (капитал 6, долг 0,15% ВВП за 2 года)", "cap": 6.0, "arg": c,
		"desc": "Общая лаборатория: скорость исследований +5%, пассивное изучение от партнёров быстрее. Длится 36 месяцев, не больше трёх проектов."}
	pa["ok"] = true
	pa["why"] = ""
	if rel < 50.0:
		pa["ok"] = false
		pa["why"] = "нужны отношения 50"
	elif capital < 6.0:
		pa["ok"] = false
		pa["why"] = "нужно 6 капитала"
	elif (dx["proj"] as Array).size() >= 3:
		pa["ok"] = false
		pa["why"] = "уже три проекта"
	else:
		for p in dx["proj"]:
			if String(p["cc"]) == c:
				pa["ok"] = false
				pa["why"] = "с этой страной проект уже идёт"
	out.append(pa)
	var sm := {"id": "summit", "name": "Двусторонний саммит (отношения +4)", "cap": 2.0, "arg": c, "desc": "Встреча лидеров: отношения растут."}
	sm["ok"] = capital >= 2.0 and dx_cd_get("summit" + c) == 0
	sm["why"] = "" if bool(sm["ok"]) else ("перерыв %d мес." % dx_cd_get("summit" + c) if dx_cd_get("summit" + c) > 0 else "нужно 2 капитала")
	out.append(sm)
	return out


func dx_treaty_do(id: String, c: String) -> bool:
	if pl_deny(): return false
	if not dx_on() or observer or not current_event.is_empty():
		return false
	var found: Dictionary = {}
	for a in dx_treaty_acts(c):
		if String(a["id"]) == id:
			found = a
	if found.is_empty() or not bool(found["ok"]):
		return false
	capital -= float(found["cap"])
	var tr: Dictionary = dx["tr"]
	if id == "summit":
		(dx["cd"] as Dictionary)["summit" + c] = 6
		ex_rel_change(c, 4.0)
		return true
	if id == "proj":
		(dx["proj"] as Array).append({"cc": c, "left": 36})
		ex_rel_change(c, 3.0)
		dx_log("запущен совместный научный проект с «%s»." % dx_name(c), COL_GOOD)
		return true
	var tid: String = id.substr(3)
	if not tr.has(c):
		tr[c] = {}
	if dx_has_treaty(c, tid):
		tr[c].erase(tid)
		ex_rel_change(c, -5.0)
		dx_log("договор с «%s» расторгнут." % dx_name(c), COL_WARN)
		fa_notify("treaty_break", c, 1.0)
		if (tr[c] as Dictionary).is_empty():
			tr.erase(c)
	else:
		tr[c][tid] = true
		ex_rel_change(c, 3.0)
		if tid == "defense":
			add_support("Силовики", 1.5)
		fa_notify("treaty", c, 1.0)
		dx_log("заключён договор «%s» с «%s»." % [String(found["name"]).substr(String(found["name"]).find(": ") + 2), dx_name(c)], COL_GOOD)
	return true


# ---------- v50: конструктор договоров («чистый лист») ----------
# Пункт: us — что даёт нам (текст), them — выгода партнёру (−10…+10, влияет на согласие), cap — политкапитал, once — разовый эффект.
const DX_CLAUSES := [
	{"id": "tech", "name": "Научный обмен", "them": 3.0, "cap": 2.0, "us": "исследования быстрее"},
	{"id": "energy", "name": "Энергетическое партнёрство", "them": 4.0, "cap": 2.0, "us": "меньше зависимость от импорта энергии"},
	{"id": "trade", "name": "Снижение пошлин", "them": 5.0, "cap": 2.0, "us": "рост +0,025 п.п. в месяц от торговли"},
	{"id": "invest", "name": "Взаимная защита инвестиций", "them": 3.0, "cap": 2.0, "us": "рост +0,02 п.п.; расходы 0,01% ВВП"},
	{"id": "visa", "name": "Безвизовый режим", "them": 4.0, "cap": 1.0, "us": "туризм и деловые поездки"},
	{"id": "culture", "name": "Культурный и молодёжный обмен", "them": 3.0, "cap": 1.0, "us": "отношения медленно растут"},
	{"id": "nagg", "name": "Ненападение и добрососедство", "them": 2.0, "cap": 1.0, "us": "отношения не ниже 40"},
	{"id": "defense", "name": "Оборонный союз", "them": -2.0, "cap": 3.0, "us": "помощь в конфликтах; нужно доверие"},
	{"id": "migr", "name": "Возврат нелегальных мигрантов", "them": -4.0, "cap": 1.0, "us": "меньше миграционного напряжения"},
	{"id": "loan", "name": "Мы даём кредит (0,1% ВВП)", "them": 8.0, "cap": 0.0, "us": "расход сразу; партнёр благодарен", "once": true},
	{"id": "aid", "name": "Партнёр даёт нам льготный кредит", "them": -7.0, "cap": 0.0, "us": "долг −0,1% ВВП сразу", "once": true},
]


func dx_clause(id: String) -> Dictionary:
	for d in DX_CLAUSES:
		if String(d["id"]) == id:
			return d
	return {}


# оценка проекта договора: шанс согласия партнёра, цена, причины
func dx_draft_eval(c: String, ids: Array) -> Dictionary:
	var rel: float = fed_rel(c)
	var them := 0.0
	var cap := 2.0
	var why: PackedStringArray = []
	for id in ids:
		var d := dx_clause(String(id))
		if d.is_empty():
			continue
		them += float(d["them"])
		cap += float(d["cap"])
		if not bool(d.get("once", false)) and dx_has_treaty(c, String(id)):
			why.append("«%s» уже действует" % d["name"])
	if "defense" in ids and rel < 60.0:
		them -= 8.0
	var score: float = (rel - 50.0) * 0.8 + them * 2.2 - float(ids.size()) * 1.2 + float(hist_rel(c)) * 1.6
	var p: float = clampf(0.5 + score / 40.0, 0.03, 0.97)
	if ids.is_empty():
		why.append("добавьте хотя бы один пункт")
	if capital < cap:
		why.append("нужно %.0f капитала" % cap)
	if rel < 25.0:
		why.append("отношения слишком плохие (%.0f)" % rel)
	return {"p": p, "cap": cap, "why": why, "them": them}


func dx_draft_propose(c: String, ids: Array, title: String) -> bool:
	if pl_deny(): return false
	if not dx_on() or not dx_target_ok(c):
		return false
	var ev := dx_draft_eval(c, ids)
	if (ev["why"] as PackedStringArray).size() > 0:
		log_line("[color=%s]Договор не предложен: %s.[/color]" % [COL_WARN, "; ".join(ev["why"])])
		return false
	capital -= float(ev["cap"])
	var nm: String = title.strip_edges()
	if nm == "":
		nm = "Договор с «%s»" % dx_name(c)
	if randf() >= float(ev["p"]):
		ex_rel_change(c, -1.0)
		dx_log("«%s» отклонила проект «%s» (шанс был %.0f%%). Политкапитал потрачен на переговоры." % [dx_name(c), nm, float(ev["p"]) * 100.0], COL_WARN)
		return false
	var tr: Dictionary = dx["tr"]
	if not tr.has(c):
		tr[c] = {}
	var names: PackedStringArray = []
	for id in ids:
		var d := dx_clause(String(id))
		names.append(String(d["name"]))
		match String(id):
			"loan":
				debt += gdp * 0.1 / 100.0
				ex_rel_change(c, 6.0)
			"aid":
				debt = maxf(0.0, debt - gdp * 0.1 / 100.0)
				ex_rel_change(c, -2.0)
			_:
				tr[c][String(id)] = true
	if (tr[c] as Dictionary).is_empty():
		tr.erase(c)
	if not dx.has("named"):
		dx["named"] = []
	(dx["named"] as Array).append({"c": c, "name": nm, "ids": ids.duplicate(), "turn": turn})
	ex_rel_change(c, 2.0 + maxf(0.0, float(ev["them"])) * 0.3)
	fa_notify("treaty", c, 1.0)
	dx_log("подписан «%s» с «%s»: %s." % [nm, dx_name(c), ", ".join(names)], COL_GOOD)
	refresh()
	return true


func dx_named_break(k: int) -> void:
	if pl_deny(): return
	var nl: Array = dx.get("named", [])
	if k < 0 or k >= nl.size():
		return
	var e: Dictionary = nl[k]
	var c: String = String(e["c"])
	var tr: Dictionary = dx["tr"]
	if tr.has(c):
		for id in e["ids"]:
			(tr[c] as Dictionary).erase(String(id))
		if (tr[c] as Dictionary).is_empty():
			tr.erase(c)
	nl.remove_at(k)
	ex_rel_change(c, -6.0)
	fa_notify("treaty_break", c, 1.0)
	dx_log("«%s» с «%s» расторгнут." % [e["name"], dx_name(c)], COL_WARN)
	refresh()


func dx_spy_acts(c: String) -> Array:
	var out: Array = []
	if not dx_on():
		return out
	if dx_target_ok(c):
		for d in DX_SPY:
			var a := {"id": "spy_" + String(d["id"]), "name": d["name"], "cap": d["cap"], "desc": d["desc"], "arg": c}
			var cdk: int = dx_cd_get("spy" + String(d["id"]) + c)
			a["ok"] = cdk == 0 and capital >= float(d["cap"])
			a["why"] = "" if bool(a["ok"]) else ("перерыв %d мес." % cdk if cdk > 0 else "нужно %.0f капитала" % float(d["cap"]))
			out.append(a)
	var ci: int = int(dx["ci"])
	var ca := {"id": "ci_up", "name": "Контрразведка +1 (расход %.2f%% ВВП/год)" % float(DX_CI_COST[mini(3, ci + 1)]), "cap": 5.0, "desc": "Меньше шансов у иностранных операций, больше шансов раскрыть их. Сейчас уровень %d из 3." % ci, "arg": ""}
	ca["ok"] = ci < 3 and capital >= 5.0
	ca["why"] = "" if bool(ca["ok"]) else ("предел" if ci >= 3 else "нужно 5 капитала")
	out.append(ca)
	var cb := {"id": "ci_dn", "name": "Контрразведка −1", "cap": 0.0, "desc": "Экономия за счёт защиты.", "arg": ""}
	cb["ok"] = ci > 0
	cb["why"] = "" if ci > 0 else "минимум"
	out.append(cb)
	return out


func dx_spy_do(id: String, c: String) -> bool:
	if pl_deny(): return false
	if not dx_on() or observer or not current_event.is_empty():
		return false
	var found: Dictionary = {}
	for a in dx_spy_acts(c):
		if String(a["id"]) == id:
			found = a
	if found.is_empty() or not bool(found["ok"]):
		return false
	capital -= float(found["cap"])
	if id == "ci_up":
		dx["ci"] = int(dx["ci"]) + 1
		return true
	if id == "ci_dn":
		dx["ci"] = int(dx["ci"]) - 1
		return true
	var kind: String = id.substr(4)
	var cd_m := 8
	for d in DX_SPY:
		if String(d["id"]) == kind:
			cd_m = int(d["cd"])
	(dx["cd"] as Dictionary)["spy" + kind + c] = cd_m
	var rel: float = fed_rel(c)
	var p: float = clampf(0.5 + (0.1 if democracy_index() < 0.5 else 0.0) - (0.1 if rel > 60.0 else 0.0), 0.2, 0.7)
	if kind == "steal":
		p = clampf(p + 0.05, 0.2, 0.75)
	var ok: bool = randf() < p
	var nm: String = dx_name(c)
	if ok:
		match kind:
			"steal":
				var cur: String = ""
				for b in TECH_NB:
					if String(tech["cur"][b]) != "":
						cur = String(tech["cur"][b])
						break
				if cur != "":
					tech["prog"][cur] = float(tech["prog"].get(cur, 0.0)) + float(tech_def(cur)["cost"]) * 0.25
				dx_log("операция удалась: из «%s» добыты чертежи, исследование ускорено." % nm, COL_GOOD)
			"destab":
				wsim[c]["stab"] = clampf(float(wsim[c]["stab"]) - 6.0, 5.0, 95.0)
				dx_log("операция удалась: стабильность «%s» упала." % nm, COL_GOOD)
			"cyber":
				wsim[c]["gdp"] = float(wsim[c]["gdp"]) * 0.998
				wsim[c]["infl"] = float(wsim[c]["infl"]) + 0.2
				dx_log("кибератака на «%s» удалась." % nm, COL_GOOD)
		if randf() < 0.12:
			ex_rel_change(c, -10.0)
			fa_notify("spy", c, 0.7)
			dx_log("позже в «%s» нашли следы вашей операции: отношения испорчены." % nm, COL_WARN)
	else:
		var pen: float = {"steal": 8.0, "destab": 12.0, "cyber": 10.0}.get(kind, 8.0)
		ex_rel_change(c, -pen)
		dx["exposed"] = int(dx["exposed"]) + 1
		add_support("Молодёжь", -1.0)
		fa_notify("spy", c, 1.0)
		dx_log("[b]провал:[/b] операция против «%s» раскрыта, дипломатический скандал." % nm, COL_BAD)
	return true


func dx_eth_acts() -> Array:
	var out: Array = []
	if not dx_on():
		return out
	var eth: int = int(dx["eth"])
	var a := {"id": "eth_up", "name": "Этика технологий +1 (скорость исследований −5%)", "cap": 5.0,
		"desc": "Законы о данных, слежке и ИИ: доверие к государству растёт, Молодёжь и Экологи довольны, шпионам труднее, но исследования идут медленнее. Уровень %d из 3." % eth, "arg": ""}
	a["ok"] = eth < 3 and capital >= 5.0
	a["why"] = "" if bool(a["ok"]) else ("предел" if eth >= 3 else "нужно 5 капитала")
	out.append(a)
	var b := {"id": "eth_dn", "name": "Этика технологий −1", "cap": 0.0, "desc": "Ослабить ограничения.", "arg": ""}
	b["ok"] = eth > 0
	b["why"] = "" if eth > 0 else "минимум"
	out.append(b)
	return out


func dx_eth_do(id: String) -> bool:
	if not dx_on() or observer or not current_event.is_empty():
		return false
	var eth: int = int(dx["eth"])
	if id == "eth_up" and eth < 3 and capital >= 5.0:
		capital -= 5.0
		dx["eth"] = eth + 1
		rl["m"]["trust"] = minf(95.0, float(rl["m"]["trust"]) + 4.0)
		add_support("Молодёжь", 2.0)
		add_support("Экологи", 1.0)
		add_support("Бизнес", -0.5)
		dx["ci"] = mini(3, int(dx["ci"]))
		return true
	if id == "eth_dn" and eth > 0:
		dx["eth"] = eth - 1
		rl["m"]["trust"] = maxf(5.0, float(rl["m"]["trust"]) - 2.0)
		return true
	return false


func dx_summary_text() -> String:
	if not dx_on():
		return ""
	var t := ""
	var n_tr := 0
	for c in dx["tr"]:
		n_tr += (dx["tr"][c] as Dictionary).size()
	t += "[b]Договоры[/b]: %d действует · проекты: %d · научный обмен: %d\n" % [n_tr, (dx["proj"] as Array).size(), int(dx.get("n_tech", 0))]
	t += "[b]Разведка[/b]: контрразведка %d/3 · провалов %d\n" % [int(dx["ci"]), int(dx["exposed"])]
	t += "[b]Армия[/b]: лояльность %.0f · амбиции генералов %.0f\n" % [float(dx["army"]["loy"]), float(dx["army"]["amb"])]
	t += "[b]Этика технологий[/b]: уровень %d из 3 · скорость науки ×%.2f" % [int(dx["eth"]), tech_adj]
	return t


# v46_1: показатели модулей для условий событий (cor_gt, price_gt, age_gt, wave_gt, rev_gt, coup_gt, sep_gt, tech_gt…)
func ev_ext_val(k: String) -> float:
	match k:
		"cor":
			return float(rl["l"]["cor"]) if rl_on() else float(lvl["corruption"])
		"price":
			return float(rl["e"]["price"]) if rl_on() else 100.0
		"age":
			return float(rl["d"]["age"]) if rl_on() else 20.0
		"free":
			return float(rl["m"]["free"]) if rl_on() else 70.0
		"wave":
			return float(rv["nat"]["wave"]) if rv_on() else 0.0
		"rev":
			return float(rv["nat"]["rev"]) if rv_on() else 0.0
		"coup":
			return float(rv["nat"]["coup"]) if rv_on() else 0.0
		"sep":
			var mx := 0.0
			if rv_on():
				for i in regions.size():
					mx = maxf(mx, float(rv_reg(i)["sep"]))
			return mx
		"tech":
			return float((tech["done"] as Dictionary).size()) if not tech.is_empty() else 0.0
		"army":
			return float(dx["army"]["loy"]) if dx_on() else 60.0
	return 0.0
