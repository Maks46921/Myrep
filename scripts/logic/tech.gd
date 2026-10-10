# Технологии (v39_1): три ветки исследований, специальные сооружения, скорость исследований с мягким потолком.
# Скорость = базовая × (расходы на образование) × (сооружения и технологии). Выше потолка прирост скорости убывает
# (предел — 1,6 потолка). Потолок растёт со временем, с ВВП и со свободой слова.
# Готовые технологии добавляют прибавки к модификаторам страны (tech_apply_mods), сооружения усиливают их (tech_power).
extends "res://scripts/logic/society.gd"

var tech: Dictionary = {}
var tech_idx: Dictionary = {}


func tech_init() -> void:
	tech_idx.clear()
	for k in TECHS.size():
		tech_idx[String(TECHS[k]["id"])] = k
	tech = {"done": {}, "prog": {}, "cur": ["", "", ""], "bank": [0.0, 0.0, 0.0], "wait": [0, 0, 0], "w": [1, 1, 1], "auto": true, "bld": {}, "q": [],
		"speed": 0.0, "raw": 0.0, "cap": 0.0, "idle": false, "pts": 0.0,
		"h": {"s": [], "c": [], "r": []}}
	for d in TECH_BUILDINGS:
		tech["bld"][d["id"]] = 0
	tech_refresh_rates()


func tech_def(id: String) -> Dictionary:
	if not tech_idx.has(id):
		return {}
	return TECHS[int(tech_idx[id])]


func tech_bdef(id: String) -> Dictionary:
	for d in TECH_BUILDINGS:
		if d["id"] == id:
			return d
	return {}


func tech_done(id: String) -> bool:
	return tech.has("done") and (tech["done"] as Dictionary).has(id)


func tech_alts(id: String) -> Array:
	# другие технологии того же уровня и ветки: изучить можно только одну из группы
	var d := tech_def(id)
	var out: Array = []
	if d.is_empty():
		return out
	for o in TECHS:
		if int(o["b"]) == int(d["b"]) and int(o["t"]) == int(d["t"]) and o["id"] != id:
			out.append(String(o["id"]))
	return out


func tech_is_choice(id: String) -> bool:
	return tech_alts(id).size() > 0


func tech_tier_done(b: int, t: int) -> String:
	# id изученной технологии уровня t ветки b ("" — нет)
	for o in TECHS:
		if int(o["b"]) == b and int(o["t"]) == t and tech_done(String(o["id"])):
			return String(o["id"])
	return ""


func tech_missing(id: String) -> String:
	# что мешает начать исследование: "" — ничего
	var d := tech_def(id)
	if d.is_empty():
		return "нет такой технологии"
	if tech_done(id):
		return "уже изучена"
	for a in tech_alts(id):
		if tech_done(String(a)):
			return "не выбрана: изучена «%s»" % tech_def(String(a))["name"]
	if int(d["t"]) > 0 and tech_tier_done(int(d["b"]), int(d["t"]) - 1) == "":
		return "нужен предыдущий уровень"
	for r in d.get("req", []):
		if not tech_done(String(r)):
			return "нужна «%s»" % tech_def(String(r))["name"]
	if years_passed() < float(d["yr"]):
		return "доступна с %d года" % (START_YEAR + int(d["yr"]))
	return ""


func tech_avail(id: String) -> bool:
	return tech_missing(id) == ""


func tech_freedom() -> float:
	# свобода слова: индекс демократии, поправка на закон о СМИ
	var f: float = democracy_index()
	var m: int = int(law_state.get("media_law", 0))
	if m == 1:
		f += 0.10
	elif m == 2:
		f -= 0.20
	return clampf(f, 0.0, 1.0)


func tech_sum(field: String) -> float:
	var s := 0.0
	for id in tech["done"]:
		s += float(tech_def(String(id)).get(field, 0.0))
	return s


func tech_bsum(field: String, branch: int) -> float:
	# сумма по сооружениям; branch < 0 — только универсальные
	var s := 0.0
	for d in TECH_BUILDINGS:
		var n: int = int(tech["bld"][d["id"]])
		if n == 0:
			continue
		var br: int = int(d["br"])
		if br == -1 or br == branch:
			s += float(d[field]) * n
	return s


func tech_power(branch: int) -> float:
	if tech.is_empty():
		return 1.0
	return clampf(1.0 + tech_bsum("pw", branch), 1.0, 2.2)


func tech_edu_term() -> float:
	var r: float = float(pol["edu"]) / maxf(0.1, float(pol_def["edu"]))
	var lv: float = float(lvl["edu_lvl"]) / 50.0
	return pow(maxf(r, 0.02), 0.9) * (0.75 + 0.25 * clampf(lv, 0.0, 2.0))


func tech_cap() -> float:
	var yrs: float = years_passed()
	var g: float = clampf(sqrt(gdp / maxf(1.0, gdp_base)), 0.8, 3.0)
	var fr: float = TECH_FREE_BASE + TECH_FREE_SPAN * tech_freedom()
	return TECH_CAP0 * (1.0 + TECH_CAP_YEAR * yrs) * g * fr * (1.0 + tech_sum("cp") + tech_bsum("cpb", -2))


func tech_raw() -> float:
	return TECH_R0 * tech_edu_term() * (1.0 + tech_bsum("sp", -2) + tech_sum("rs"))


func tech_soft(raw: float, cap: float) -> float:
	# до потолка — линейно; выше — прирост убывает, предел 1,6×потолок
	if raw <= cap:
		return maxf(raw, 0.0)
	var ex: float = raw - cap
	return cap + ex / (1.0 + ex / (0.6 * cap))


func tech_refresh_rates() -> void:
	var cap: float = tech_cap()
	var raw: float = tech_raw()
	tech["cap"] = cap
	tech["raw"] = raw
	tech["speed"] = tech_soft(raw, cap)


func tech_apply_mods() -> void:
	if tech.is_empty():
		return
	for id in tech["done"]:
		var d := tech_def(String(id))
		var p: float = tech_power(int(d["b"]))
		var fx: Dictionary = d["fx"]
		for k in fx:
			if mods.has(k):
				mods[k] = float(mods[k]) + float(fx[k]) * p


func tech_edu_upkeep() -> float:
	# расходы сооружений, % ВВП в год: входят в статью «Образование»
	if tech.is_empty():
		return 0.0
	var s := 0.0
	for d in TECH_BUILDINGS:
		s += float(d["up"]) * int(tech["bld"][d["id"]])
	return s


func tech_build_missing(id: String) -> String:
	var d := tech_bdef(id)
	if d.is_empty():
		return "нет такого сооружения"
	if String(d["need"]) != "" and not tech_done(String(d["need"])):
		return "нужна технология «%s»" % tech_def(String(d["need"]))["name"]
	var n: int = int(tech["bld"][id])
	for q in tech["q"]:
		if q["id"] == id:
			n += 1
	if n >= int(d["max"]):
		return "достигнут предел (%d)" % int(d["max"])
	return ""


func tech_build(id: String) -> bool:
	if game_over or tech.is_empty() or tech_build_missing(id) != "":
		return false
	var d := tech_bdef(id)
	var price: float = gdp * float(d["cost"]) / 100.0
	debt += price
	(tech["q"] as Array).append({"id": id, "left": int(d["months"])})
	log_tag("НАУКА", COL_WARN, "%s: начато строительство — «%s» (%.1f млрд в долг, %d мес.; содержание +%.2f%% ВВП в год в расходы на образование)." % [date_text(), d["name"], price, int(d["months"]), float(d["up"])])
	refresh()
	return true


func tech_select(b: int, id: String) -> bool:
	if tech.is_empty() or b < 0 or b > 2:
		return false
	if id != "":
		if int(tech_def(id).get("b", -1)) != b or not tech_avail(id):
			return false
	tech["cur"][b] = id
	refresh()
	return true


func tech_set_weight(b: int, dw: int) -> void:
	tech["w"][b] = clampi(int(tech["w"][b]) + dw, 0, 4)
	refresh()


func tech_auto_pick(b: int, allow_choice: bool = false) -> String:
	# самая дешёвая из доступных; технологии «на выбор» берёт только с allow_choice
	var best := ""
	var bl := 1e18
	for d in TECHS:
		var id: String = d["id"]
		if int(d["b"]) != b or not tech_avail(id):
			continue
		if not allow_choice and tech_is_choice(id):
			continue
		var left: float = float(d["cost"]) - float(tech["prog"].get(id, 0.0))
		if left < bl:
			bl = left
			best = id
	return best


func tech_choice_waiting(b: int) -> bool:
	# в ветке открыт выбор, а технология не выбрана
	if String(tech["cur"][b]) != "":
		return false
	for d in TECHS:
		if int(d["b"]) == b and tech_is_choice(String(d["id"])) and tech_avail(String(d["id"])):
			return true
	return false


func tech_progress(id: String) -> float:
	return float(tech["prog"].get(id, 0.0)) / maxf(1.0, float(tech_def(id).get("cost", 1.0)))


func tech_total() -> int:
	# сколько технологий можно изучить в одной игре (по одной на уровень ветки)
	var seen := {}
	for d in TECHS:
		seen["%d_%d" % [int(d["b"]), int(d["t"])]] = true
	return seen.size()


func tech_count() -> int:
	return (tech["done"] as Dictionary).size() if not tech.is_empty() else 0


func tech_month() -> void:
	if tech.is_empty():
		return
	# стройка
	var q: Array = tech["q"]
	for i in range(q.size() - 1, -1, -1):
		q[i]["left"] = int(q[i]["left"]) - 1
		if int(q[i]["left"]) <= 0:
			var bd := tech_bdef(String(q[i]["id"]))
			tech["bld"][q[i]["id"]] = int(tech["bld"][q[i]["id"]]) + 1
			log_tag("НАУКА", COL_GOOD, "%s: построено — «%s». Исследования идут быстрее, технологии сильнее." % [date_text(), bd["name"]])
			q.remove_at(i)
	# выбор исследований
	for b in 3:
		var c: String = tech["cur"][b]
		if c != "" and (tech_done(c) or not tech_avail(c)):
			tech["cur"][b] = ""
		if String(tech["cur"][b]) == "" and bool(tech["auto"]):
			tech["cur"][b] = tech_auto_pick(b)
			if String(tech["cur"][b]) == "" and tech_choice_waiting(b):
				# выбор за вами; автовыбор берёт сам лишь после полугода ожидания (или если партией управляет ИИ)
				tech["wait"][b] = int(tech["wait"][b]) + 1
				if int(tech["wait"][b]) >= 6 or observer:
					tech["cur"][b] = tech_auto_pick(b, true)
					tech["wait"][b] = 0
					if String(tech["cur"][b]) != "":
						log_tag("НАУКА", COL_DIM, "%s: ветка «%s» не получила вашего выбора — автоматически выбрано «%s»." % [date_text(), String(TECH_BRANCHES[b]["name"]).to_lower(), tech_def(String(tech["cur"][b]))["name"]])
			else:
				tech["wait"][b] = 0
	tech_refresh_rates()
	var spd: float = tech["speed"]
	var wsum := 0.0
	for b in 3:
		wsum += float(tech["w"][b])
	tech["idle"] = wsum <= 0.0
	if wsum > 0.0:
		for b in 3:
			if float(tech["w"][b]) <= 0.0:
				continue
			var add: float = spd * float(tech["w"][b]) / wsum
			tech["pts"] = float(tech["pts"]) + add
			var id: String = tech["cur"][b]
			if id == "":
				# нечего изучать (или ветка на паузе): очки копятся в запасе и достанутся следующей технологии
				tech["bank"][b] = minf(float(tech["bank"][b]) + add, spd * 12.0)
				continue
			var pg: float = float(tech["prog"].get(id, 0.0)) + add + float(tech["bank"][b])
			tech["bank"][b] = 0.0
			var d := tech_def(id)
			if pg >= float(d["cost"]):
				pg -= float(d["cost"])
				tech["prog"].erase(id)
				tech["done"][id] = turn
				tech["cur"][b] = ""
				tech["bank"][b] = pg
				log_tag("НАУКА", COL_GOOD, "%s: изучена технология «%s» (%s ветка). %s" % [date_text(), d["name"], String(TECH_BRANCHES[b]["name"]).to_lower(), tech_fx_text(d)])
				if bool(tech["auto"]):
					tech["cur"][b] = tech_auto_pick(b)
					if String(tech["cur"][b]) == "" and tech_choice_waiting(b):
						log_tag("НАУКА", COL_WARN, "В ветке «%s» открыт выбор: изучить можно только одну из технологий. Выберите в окне ветки (иначе через полгода выберется само)." % String(TECH_BRANCHES[b]["name"]).to_lower())
			else:
				tech["prog"][id] = pg
	var h: Dictionary = tech["h"]
	for k in ["s", "c", "r"]:
		(h[k] as Array).append(float(tech[{"s": "speed", "c": "cap", "r": "raw"}[k]]))
		if (h[k] as Array).size() > 240:
			(h[k] as Array).pop_front()


func tech_fx_text(d: Dictionary) -> String:
	var parts: PackedStringArray = []
	var p: float = tech_power(int(d["b"]))
	var fx: Dictionary = d["fx"]
	for k in fx:
		var v: float = float(fx[k]) * p
		if MOD_INFO.has(k):
			var base: float = 1.0 if String(MOD_INFO[k]["k"]) == "mul" else 0.0
			parts.append(String(mod_item(k, base, base + v)[0]))
	if float(d.get("rs", 0.0)) > 0.0:
		parts.append("скорость исследований +%.0f%%" % (float(d["rs"]) * 100.0))
	if float(d.get("cp", 0.0)) > 0.0:
		parts.append("потолок скорости +%.0f%%" % (float(d["cp"]) * 100.0))
	return "; ".join(parts)
