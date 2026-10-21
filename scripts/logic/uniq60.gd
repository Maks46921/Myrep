# 0.60: особые строи. У 19 стран есть «очень уникальный» строй, которого нет ни у кого другого (Евразийская империя,
# Республика жребия, Ландсгемайнде…). Он не включается кнопкой: к нему ведёт цепочка из трёх событий (предпосылка → решение
# → провозглашение), для каждой стадии нужны условия в стране, а любой отказ откладывает путь надолго.
# После провозглашения работают 12 механик (показатели 0-100 с кнопками): жребий, вето одного депутата, союз двух государств,
# советы, сословные палаты, закрытые границы, тотальная мобилизация, культ вождя, алгоритмы, общий фонд, церковь, кланы.
# Остальные страны отвечают: отношения, журнал, события соседей, санкции. Данные: scripts/data/data_regimes60.gd (tools/reg60/uniq.py).
extends "res://scripts/logic/regime60.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func uq_ui_open() -> void:
	pass


# --- конец заглушек ---


const UQ_COL := "#e0b25a"


func uq_init() -> void:
	uq = {"stage": 0, "next": 24, "on": false, "since": -1, "m": {}, "fund": 0.0, "react": [], "cd": {}, "seen": [], "ev_t": -99,
		"sanc": [0.0, 0], "log": [], "say": 0}


func uq_def() -> Dictionary:
	for d in REG_UNIQ60:
		if String(d["cc"]) == ccode:
			return d
	return {}


func uq_def_id(id: String) -> Dictionary:
	for d in REG_UNIQ60:
		if String(d["id"]) == id:
			return d
	return {}


func uq_on() -> bool:
	return not uq.is_empty() and bool(uq.get("on", false))


# название строя для шапок и окна «Государство»; "" — особого строя нет
func uq_title() -> String:
	if not uq_on():
		return ""
	return String(uq_def().get("n", ""))


func uq_mech_def(id: String) -> Dictionary:
	return UQ_MECH60.get(id, {})


func uq_val(id: String) -> float:
	if not uq_on():
		return 0.0
	return float((uq["m"] as Dictionary).get(id, 0.0))


func uq_mech_add(id: String, dv: float) -> void:
	if not uq_on():
		return
	var m: Dictionary = uq["m"]
	if m.has(id):
		m[id] = clampf(float(m[id]) + dv, 0.0, 100.0)


# ---------- условия пути ----------
func uq_cond(c: Array) -> bool:
	var k := String(c[0])
	var v: float = float(c[1]) if c.size() > 1 else 0.0
	match k:
		"turn": return turn >= int(v)
		"rating_min": return approval() >= v
		"rating_max": return approval() <= v
		"unrest_min": return reg_avg("unrest") >= v
		"war": return mil_at_war()
		"peace": return not mil_at_war()
		"dem_max": return democracy_index() <= v
		"dem_min": return democracy_index() >= v
		"debt_min": return debt / maxf(1.0, gdp) * 100.0 >= v
		"infl_min": return inflation >= v
		"unemp_min": return unemployment >= v
		"risk_min": return regime_risk >= v
		"church": return ch_on()
		"supp_min": return float(support[String(c[2])]) >= v
		"supp_max": return float(support[String(c[2])]) <= v
	return true


func uq_conds_ok(list: Array) -> bool:
	for c in list:
		if not uq_cond(c):
			return false
	return true


# ---------- ежемесячный шаг ----------
func uq_can_play() -> bool:
	return not observer and not opp_mode and not game_over


func uq_step() -> void:
	if uq.is_empty():
		uq_init()
	var d := uq_def()
	if d.is_empty() or not uq_can_play():
		return
	uq_react_step(d)
	if uq_on():
		uq_month(d)
		return
	if not current_event.is_empty() or turn < int(uq["next"]):
		return
	var st := int(uq["stage"])
	if st == 0:
		if not uq_conds_ok(d["need"]) or randf() > 0.12:
			return
	elif st >= 1 and not uq_conds_ok(d.get("keep", [])):
		return
	uq_stage_show(d, st)


func uq_stage_show(d: Dictionary, st: int) -> void:
	var s: Dictionary = (d["st"] as Array)[st]
	var opts: Array = [
		{"l": String(s["l"]), "fx": s["fx"], "act": "uq_go"},
		{"l": "Отложить: время ещё не пришло", "fx": {}, "act": "uq_wait"},
		{"l": "Отказаться от этого пути", "fx": {"all": 1.0}, "act": "uq_no"}]
	current_event = {"special": "uq60", "t": "[b]%s[/b]: этап %d из 3. %s" % [String(d["n"]), st + 1, String(s["t"])], "o": opts}
	event_region = -1
	present_event()


# ---------- ответ на выбор в событии ----------
func uq_resolve(opt: Dictionary) -> void:
	var fx: Dictionary = opt.get("fx", {})
	if fx.has("uq"):
		for k in fx["uq"]:
			uq_mech_add(String(k), float(fx["uq"][k]))
	var act := String(opt.get("act", ""))
	var d := uq_def()
	if d.is_empty():
		return
	match act:
		"uq_go":
			var st := int(uq["stage"])
			if st >= 2:
				uq_proclaim(d)
			else:
				uq["stage"] = st + 1
				uq["next"] = turn + randi_range(4, 8)
				log_tag("СТРОЙ", UQ_COL, "«%s»: путь продолжается (этап %d из 3 пройден)." % [String(d["n"]), st + 1])
		"uq_wait":
			uq["next"] = turn + 10
		"uq_no":
			uq["stage"] = 0
			uq["next"] = turn + 48
			log_tag("СТРОЙ", UQ_COL, "Страна отказалась от пути к строю «%s». Вернуться к нему можно не раньше, чем через четыре года." % String(d["n"]))
		"uq_react":
			pass


func uq_proclaim(d: Dictionary) -> void:
	uq["on"] = true
	uq["since"] = turn
	uq["stage"] = 3
	var m := {}
	var start: Dictionary = d.get("start", {})
	for id in d["mech"]:
		m[String(id)] = float(start.get(id, 55.0))
	uq["m"] = m
	uq["fund"] = 0.0
	uq["cd"] = {}
	uq["ev_t"] = turn
	log_tag("СТРОЙ", UQ_COL, "[b]Провозглашён строй «%s».[/b] %s" % [String(d["n"]), String(d["mo"])])
	var gov := String(d.get("gov", ""))
	if gov != "":
		au_set_gov(gov)
	uq_world(d)
	recompute_mods()
	reg60_flag_offer()
	uq_ui_open()


# ---------- как мир отвечает ----------
func uq_world(d: Dictionary) -> void:
	var w: Dictionary = d.get("w", {})
	if w.has("dip"):
		dip_fx_apply(w["dip"])
	if w.has("all"):
		dip_all(float(w["all"]), false)
	if w.has("eu"):
		dip_all(float(w["eu"]), true)
	for line in w.get("news", []):
		log_tag("ДИПЛОМАТИЯ", COL_WARN, String(line))
	if w.has("sanc"):
		uq["sanc"] = [float(w["sanc"][0]), turn + int(w["sanc"][1])]
		log_tag("ДИПЛОМАТИЯ", COL_BAD, "Введены торговые ограничения против страны: рост ВВП станет медленнее примерно на %.2f п.п. в год на %d мес." % [float(w["sanc"][0]), int(w["sanc"][1])])
	for e in w.get("ev", []):
		(uq["react"] as Array).append({"t": turn + int(e["after"]), "e": e})


func uq_react_step(_d: Dictionary) -> void:
	var rl: Array = uq["react"]
	if rl.is_empty() or not current_event.is_empty():
		return
	for i in rl.size():
		var r: Dictionary = rl[i]
		if turn >= int(r["t"]):
			rl.remove_at(i)
			var e: Dictionary = r["e"]
			var opts: Array = []
			for o in e["o"]:
				opts.append({"l": o["l"], "fx": o["fx"], "act": "uq_react"})
			current_event = {"special": "uq60", "t": String(e["t"]), "o": opts}
			event_region = -1
			present_event()
			return


# ---------- события особого строя и месячная механика ----------
func uq_month(d: Dictionary) -> void:
	var m: Dictionary = uq["m"]
	if m.has("fund"):
		uq["fund"] = float(uq["fund"]) + gdp * 0.00025 * float(m["fund"]) / 100.0
	if m.has("church") and ch_on():
		church_fx({"pow": 0.05 * float(m["church"]) / 100.0})
	if m.has("union"):
		for c in d.get("partner", []):
			dip_change(String(c), 0.15 * float(m["union"]) / 100.0)
	# сила механик не стоит на месте: без внимания культ тускнеет, жребий и советы выдыхаются
	if turn % 6 == 0:
		for id in m:
			var dr: float = float(uq_mech_def(String(id)).get("drift", 0.0))
			if dr != 0.0:
				m[id] = clampf(float(m[id]) + dr, 0.0, 100.0)
	if not current_event.is_empty() or turn - int(uq["ev_t"]) < 5 or randf() > 0.16:
		return
	var pool: Array = []
	for e in REG_UEV60:
		if String(e["u"]) == String(d["id"]):
			pool.append(e)
	if pool.is_empty():
		return
	var seen: Array = uq["seen"]
	var fresh: Array = pool.filter(func(e: Dictionary) -> bool: return not (pool.find(e) in seen))
	if fresh.is_empty():
		seen.clear()
		fresh = pool
	var e: Dictionary = fresh[randi() % fresh.size()]
	seen.append(pool.find(e))
	uq["ev_t"] = turn
	var opts: Array = []
	for o in e["o"]:
		opts.append({"l": o["l"], "fx": o["fx"], "act": "uq_ev"})
	current_event = {"special": "uq60", "t": String(e["t"]), "o": opts}
	event_region = -1
	present_event()


# добавки в показатели каждый месяц (вызывается из radical_dyn)
func uq_dyn() -> void:
	if not uq_on() or mods.is_empty():
		return
	var d := uq_def()
	var m: Dictionary = d.get("m", {})
	for k in m:
		mods[k] = float(mods.get(k, 0.0)) + float(m[k])
	var mv: Dictionary = uq["m"]
	for id in mv:
		var f := float(mv[id]) / 100.0
		var mm: Dictionary = uq_mech_def(String(id)).get("m", {})
		for k in mm:
			mods[k] = float(mods.get(k, 0.0)) + float(mm[k]) * f
	if turn < int((uq["sanc"] as Array)[1]):
		mods["growth_bonus"] = float(mods["growth_bonus"]) - float((uq["sanc"] as Array)[0])
	mods["eff_bonus"] = clampf(float(mods.get("eff_bonus", 0.0)), -0.03, 0.03)


# человеческий текст эффектов набора добавок
func uq_effect_text(m: Dictionary, k: float = 1.0) -> String:
	var pros: PackedStringArray = []
	var cons: PackedStringArray = []
	for key in m:
		if not MOD_INFO.has(key):
			continue
		var val: float = float(m[key]) * k
		if not mod_visible(String(key), 0.0, val):
			continue
		var it: Array = mod_item(String(key), 0.0, val)
		if int(it[1]) < 0:
			cons.append(String(it[0]))
		else:
			pros.append(String(it[0]))
	var t := ""
	if pros.size() > 0:
		t += "[color=%s]▲ %s[/color]\n" % [COL_GOOD, "; ".join(pros)]
	if cons.size() > 0:
		t += "[color=%s]▼ %s[/color]\n" % [COL_BAD, "; ".join(cons)]
	return t


# ---------- жребий на выборах ----------
func uq_lot_shares(sh: Array[float]) -> Array[float]:
	if not uq_on() or not uq["m"].has("lot") or sh.size() < 2:
		return sh
	var k := clampf(float(uq["m"]["lot"]) / 100.0 * 0.6, 0.0, 0.6)
	var n := float(sh.size())
	var out: Array[float] = []
	var tot := 0.0
	for p in sh.size():
		var x: float = sh[p] * (1.0 - k) + k / n * randf_range(0.4, 1.6)
		out.append(x)
		tot += x
	for p in out.size():
		out[p] = out[p] / tot
	return out


# ---------- кнопки механик ----------
func uq_btn(id: String) -> Dictionary:
	var pr := id.split(":")
	if pr.size() < 2:
		return {}
	for b in uq_mech_def(pr[0]).get("b", []):
		if String(b["id"]) == pr[1]:
			return b
	return {}


func uq_act_check(id: String) -> String:
	if not uq_on():
		return "особый строй не провозглашён"
	var why := pl_why("gov")
	if why != "":
		return why
	var b := uq_btn(id)
	if b.is_empty():
		return "нет такого действия"
	if cap_spendable() < float(b["cost"]):
		return "нужно %.0f капитала" % float(b["cost"])
	if int(uq["cd"].get(id, -99)) > turn:
		return "ещё %d мес." % (int(uq["cd"][id]) - turn)
	var fx: Dictionary = b.get("fx", {})
	if (fx.has("fund_pay") or fx.has("fund_bud")) and float(uq["fund"]) <= 0.0:
		return "фонд пуст"
	var mech := id.split(":")[0]
	var dv: float = float(b.get("d", 0.0))
	if dv > 0.0 and uq_val(mech) >= 100.0:
		return "показатель уже на максимуме"
	if dv < 0.0 and uq_val(mech) <= 0.0:
		return "показатель уже на нуле"
	return ""


func uq_act(id: String) -> bool:
	var why := uq_act_check(id)
	if why != "":
		log_line("[color=%s]Нельзя: %s.[/color]" % [COL_WARN, why])
		return false
	var b := uq_btn(id)
	var mech := id.split(":")[0]
	capital -= float(b["cost"])
	uq["cd"][id] = turn + int(b["cd"])
	uq_mech_add(mech, float(b.get("d", 0.0)))
	var fx: Dictionary = (b.get("fx", {}) as Dictionary).duplicate()
	var extra := ""
	if fx.has("fund_pay"):
		var amt: float = float(uq["fund"]) * float(fx["fund_pay"])
		uq["fund"] = float(uq["fund"]) - amt
		add_all_support(clampf(amt / maxf(1.0, gdp) * 800.0, 0.5, 6.0))
		extra = " Выплачено %.1f млрд €." % amt
		fx.erase("fund_pay")
	if fx.has("fund_bud"):
		var amt2: float = float(uq["fund"])
		uq["fund"] = 0.0
		debt = maxf(0.0, debt - amt2)
		extra = " В бюджет направлено %.1f млрд € (долг уменьшен)." % amt2
		fx.erase("fund_bud")
	if fx.has("uq"):
		for k in fx["uq"]:
			uq_mech_add(String(k), float(fx["uq"][k]))
		fx.erase("uq")
	var eff := apply_fx(fx) if not fx.is_empty() else ""
	log_tag("СТРОЙ", UQ_COL, "%s.%s%s" % [String(b["l"]), extra, (" Последствия: %s." % eff) if eff != "" else ""])
	return true


# отказ от особого строя: дорогое решение, возврат к прежнему порядку
func uq_abandon() -> bool:
	if not uq_on() or not uq_can_play():
		return false
	if cap_spendable() < 6.0:
		log_line("[color=%s]Нельзя: нужно 6 капитала.[/color]" % COL_WARN)
		return false
	capital -= 6.0
	var d := uq_def()
	uq["on"] = false
	uq["stage"] = 0
	uq["next"] = turn + 60
	uq["m"] = {}
	uq["fund"] = 0.0
	add_all_support(-2.0)
	log_tag("СТРОЙ", UQ_COL, "Страна отказалась от строя «%s». Прежний порядок восстановлен." % String(d.get("n", "")))
	recompute_mods()
	return true
