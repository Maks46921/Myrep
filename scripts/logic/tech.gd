# Технологии (v39_1): три ветки исследований, специальные сооружения, скорость исследований с мягким потолком.
# Скорость = базовая × (расходы на образование) × (сооружения и технологии). Выше потолка прирост скорости убывает
# (предел — 1,6 потолка). Потолок растёт со временем, с ВВП и со свободой слова.
# Готовые технологии добавляют прибавки к модификаторам страны (tech_apply_mods), сооружения усиливают их (tech_power).
extends "res://scripts/logic/industry.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func ex_dep(cc: String) -> Dictionary:
	return {}


func ex_partners() -> Array:
	return []


func mil_land_neighbor(cc: String) -> bool:
	return false


# --- конец заглушек ---


var tech: Dictionary = {}
var tech_idx: Dictionary = {}


func tech_init() -> void:
	tech_idx.clear()
	for k in TECHS.size():
		tech_idx[String(TECHS[k]["id"])] = k
	tech = {"done": {}, "prog": {}, "cur": [], "bank": [], "wait": [], "w": [], "auto": true, "ai_all": false, "bld": {}, "q": [], "nbn": {}, "nbp": {}, "pas": {}, "pasm": [], "nb": [], "pace": {}, "grp": [], "ty": [],
		"speed": 0.0, "raw": 0.0, "cap": 0.0, "idle": false, "pts": 0.0,
		"h": {"s": [], "c": [], "r": []}}
	for b in TECH_NB:
		tech["cur"].append("")
		tech["bank"].append(0.0)
		tech["wait"].append(0)
		tech["w"].append(1)
		tech["pasm"].append(0.0)
		tech["grp"].append({})
	for d in TECHS:
		var gb: Dictionary = tech["grp"][int(d["b"])]
		if not gb.has(int(d["t"])):
			gb[int(d["t"])] = []
		(gb[int(d["t"])] as Array).append(String(d["id"]))
		while (tech["ty"] as Array).size() <= int(d["t"]):
			(tech["ty"] as Array).append(0.0)
		tech["ty"][int(d["t"])] = float(d["yr"])
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


# ---------- v50: подветки внутри разделов ----------
# В каждом разделе 2–3 подветки; технология относится к подветке по теме (ключевые слова названия и описания).
# Для перехода на следующий уровень годится любая технология предыдущего уровня — поэтому подветки пересекаются.
const TECH_SUBS := [
	[["Энергия и ресурсы", "энерг|солн|ветр|газ|атом|водород|ресурс|углерод|климат|топлив|сет"], ["Цифра и автоматизация", "цифр|автомат|робот|данн|интеллект|интернет|квант|платформ|вычисл|алгоритм|машин"], ["Финансы и рынки", "финанс|рын|бирж|кредит|налог|торг|валют|банк|инвест|платеж|экспорт|цен"]],
	[["Медицина", "мед|здрав|ген|лекар|вакцин|болез|долголет|био|клиник|диагност|пандем"], ["Образование и наука", "образ|школ|учеб|наук|универ|знан|навык|исследов|учён|учен"], ["Общество и быт", "соц|город|жиль|семь|культур|равен|общ|пенси|труд|занят|досуг"]],
	[["Госуправление", "управл|госуд|бюрократ|реестр|услуг|выбор|голос|бюджет|прозрач|коррупц|чиновн"], ["Безопасность", "безопас|полиц|развед|кибер|контрраз|наблюд|границ|кризис|защит"], ["Дипломатия и право", "диплом|прав|суд|договор|союз|междунар|санкц|влиян|перегов|закон"]],
	[["Заводы и стройка", "завод|произв|стро|материал|печат|стал|цемент|станк|фабрик|сборк"], ["Добыча и село", "добыч|шахт|нефт|руд|сельск|агро|урож|ферм|почв|вод|лес|рыб"], ["Транспорт и логистика", "транспорт|логист|дорог|желез|порт|доставк|склад|грузов|магистрал"]],
	[["Сухопутные войска", "танк|пехот|артил|сухопут|бронет|солдат|снаряж|резерв|мобилиз|подготов"], ["Авиация, флот и ПВО", "авиа|самол|флот|корабл|пво|ракет|беспилот|спутник|космос|радар"], ["Сдерживание и кибер", "ядер|сдерж|кибер|радиоэлектрон|рэб|информац|связ|командов|разведк"]],
]
var tech_lane_cache := {}


func tech_lane(id: String) -> int:
	if tech_lane_cache.is_empty():
		tech_lanes_build()
	return int(tech_lane_cache.get(id, 1))


func tech_lanes_build() -> void:
	tech_lane_cache.clear()
	# v54_1: подветки ищутся по русским названиям и в английской версии (путь собран из частей,
	# чтобы tools/i18n.py не перенаправил его в en/) — раскладка технологий одинакова на обоих языках
	var subs: Array = TECH_SUBS
	var techs: Array = TECHS
	var ru_logic = load("res://" + "scripts/logic/tech.gd")
	var ru_data = load("res://" + "scripts/data/data_tech.gd")
	if ru_logic != null and ru_data != null:
		subs = ru_logic.get_script_constant_map().get("TECH_SUBS", subs)
		techs = ru_data.get_script_constant_map().get("TECHS", techs)
	var rx := []
	for b in subs.size():
		var row := []
		for sub in subs[b]:
			var re := RegEx.new()
			re.compile(String(sub[1]))
			row.append(re)
		rx.append(row)
	# по уровням: альтернативы одного уровня — в разных подветках
	var by_bt := {}
	for d in techs:
		var k := "%d_%d" % [int(d["b"]), int(d["t"])]
		if not by_bt.has(k):
			by_bt[k] = []
		(by_bt[k] as Array).append(d)
	for k in by_bt:
		var used := {}
		for d in by_bt[k]:
			var b: int = int(d["b"])
			var hay: String = (String(d["name"]) + " " + String(d.get("d", ""))).to_lower()
			var best := -1
			var bs := 0
			for li in (rx[b] as Array).size():
				var n: int = (rx[b][li] as RegEx).search_all(hay).size()
				if n > bs and not used.has(li):
					bs = n
					best = li
			if best < 0:
				for li in [1, 0, 2]:
					if not used.has(li) and li < (rx[b] as Array).size():
						best = li
						break
			used[best] = true
			tech_lane_cache[String(d["id"])] = best


func tech_lane_name(id: String) -> String:
	var d := tech_def(id)
	if d.is_empty():
		return ""
	return String(TECH_SUBS[int(d["b"])][tech_lane(id)][0])


# ---------- v50: откат выбора «или» за те же очки ----------
# Если в группе «или» уже изучена одна технология, можно перейти на другую: вложенные очки переносятся.
# Альтернатива дороже — доплачивается разница (переход станет текущим исследованием); дешевле — сразу изучена.
func tech_swap_check(id: String) -> String:
	if tech.is_empty() or game_over:
		return "нельзя"
	if tech_done(id):
		return "уже изучена"
	var cur_alt := ""
	for a in tech_alts(id):
		if tech_done(String(a)):
			cur_alt = String(a)
	if cur_alt == "":
		return "в этой группе ещё ничего не изучено"
	if int(tech.get("swap_cd", 0)) > turn:
		return "перестройка науки уже шла недавно (ещё %d мес.)" % (int(tech["swap_cd"]) - turn)
	return ""


func tech_swap(id: String) -> bool:
	var why := tech_swap_check(id)
	if why != "":
		log_line("[color=%s]Сменить выбор нельзя: %s.[/color]" % [COL_WARN, why])
		return false
	var d := tech_def(id)
	var b: int = int(d["b"])
	var old := ""
	for a in tech_alts(id):
		if tech_done(String(a)):
			old = String(a)
	var od := tech_def(old)
	(tech["done"] as Dictionary).erase(old)
	var paid: float = float(od["cost"])
	tech["swap_cd"] = turn + 12
	if paid >= float(d["cost"]):
		tech["done"][id] = turn
		log_tag("НАУКА", COL_TEAL, "%s: выбор пересмотрен — вместо «%s» изучена «%s» за те же очки." % [date_text(), od["name"], d["name"]])
	else:
		tech["prog"][id] = paid
		tech["cur"][b] = id
		log_tag("НАУКА", COL_TEAL, "%s: выбор пересмотрен — «%s» заменяется на «%s»; вложенные %.0f очк. засчитаны, осталось %.0f." % [date_text(), od["name"], d["name"], paid, float(d["cost"]) - paid])
	refresh()
	return true


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
	return clampf(f + free_adj, 0.0, 1.0)


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
	tech["speed"] = tech_soft(raw, cap) * tech_adj


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
	if tech.is_empty() or b < 0 or b >= TECH_NB:
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


# ---------- 0.56: очередь изучения — у каждой ветки своя, без ограничения длины ----------
# В очередь можно ставить и технологии, до которых ещё не дошли: после изучения ветка берёт первую доступную из очереди.
func tech_rq(b: int) -> Array:
	if not tech.has("rq"):
		tech["rq"] = []
	while (tech["rq"] as Array).size() < TECH_NB:
		(tech["rq"] as Array).append([])
	return tech["rq"][b]


func tech_never(id: String) -> bool:
	# изучить уже нельзя: изучена или выбрана альтернатива уровня
	if tech_done(id):
		return true
	for a in tech_alts(id):
		if tech_done(String(a)):
			return true
	return false


func tech_q_add(id: String) -> bool:
	var d := tech_def(id)
	if d.is_empty() or tech_never(id):
		return false
	var b: int = int(d["b"])
	var q := tech_rq(b)
	if q.has(id) or String(tech["cur"][b]) == id:
		return false
	q.append(id)
	return true


func tech_q_del(b: int, k: int) -> void:
	var q := tech_rq(b)
	if k >= 0 and k < q.size():
		q.remove_at(k)


func tech_q_move(b: int, k: int, dir: int) -> void:
	var q := tech_rq(b)
	var j: int = k + dir
	if k < 0 or k >= q.size() or j < 0 or j >= q.size():
		return
	var t: String = q[k]
	q[k] = q[j]
	q[j] = t


# следующая из очереди: убирает невозможные, берёт первую доступную (недоступные пока остаются ждать)
func tech_q_next(b: int) -> String:
	var q := tech_rq(b)
	for k in range(q.size() - 1, -1, -1):
		if tech_never(String(q[k])):
			q.remove_at(k)
	for k in q.size():
		var id: String = q[k]
		if tech_avail(id):
			q.remove_at(k)
			return id
	return ""


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
	# 0.62: стройка (сроки в целых месяцах), выбор исследований и ожидание выбора — только при закрытии месяца; очки идут понедельно
	if wmonth:
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
		for b in TECH_NB:
			var c: String = tech["cur"][b]
			if c != "" and (tech_done(c) or not tech_avail(c)):
				tech["cur"][b] = ""
			if String(tech["cur"][b]) == "" and not opp_mode:
				tech["cur"][b] = tech_q_next(b)
			if String(tech["cur"][b]) == "" and (bool(tech["auto"]) or opp_mode):
				tech["cur"][b] = tech_ai_pick(b, false)
				if String(tech["cur"][b]) == "" and tech_choice_waiting(b):
					# выбор «или»: ИИ-советник решает сразу, если разрешено (или партией управляет ИИ), иначе ждёт вашего решения полгода
					tech["wait"][b] = int(tech["wait"][b]) + 1
					if int(tech["wait"][b]) >= TECH_WAIT_MONTHS or observer or opp_mode or bool(tech["ai_all"]):
						var pick := tech_ai_pick(b, true)
						tech["cur"][b] = pick
						tech["wait"][b] = 0
						if pick != "":
							var why := tech_score_text(pick, tech_needs_player())
							log_tag("НАУКА", COL_DIM, "%s: ИИ-советник выбрал «%s» (ветка «%s»)%s." % [date_text(), tech_def(pick)["name"], String(TECH_BRANCHES[b]["name"]).to_lower(), (": " + why) if why != "" else ""])
				else:
					tech["wait"][b] = 0
	tech_refresh_rates()
	var spd: float = tech["speed"]
	var wsum := 0.0
	for b in TECH_NB:
		wsum += float(tech["w"][b])
	tech["idle"] = wsum <= 0.0
	if wsum > 0.0:
		for b in TECH_NB:
			if float(tech["w"][b]) <= 0.0:
				continue
			var add: float = spd * float(tech["w"][b]) / wsum * wdt
			tech["pts"] = float(tech["pts"]) + add
			var id: String = tech["cur"][b]
			if id == "":
				# нечего изучать (или ветка на паузе): очки копятся в запасе и достанутся следующей технологии
				tech["bank"][b] = minf(float(tech["bank"][b]) + add, spd * 12.0)
				continue
			var d := tech_def(id)
			var pas := 0.0
			var room: float = TECH_PASSIVE_CAP * float(d["cost"]) - float(tech["pas"].get(id, 0.0))
			if room > 0.0:
				pas = minf(tech_passive_rate(id) * wdt, room)
				tech["pas"][id] = float(tech["pas"].get(id, 0.0)) + pas
			tech["pasm"][b] = pas / maxf(wdt, 0.05)     # для окна технологий — очков в месяц
			var pg: float = float(tech["prog"].get(id, 0.0)) + add + pas + float(tech["bank"][b])
			tech["bank"][b] = 0.0
			if pg >= float(d["cost"]):
				pg -= float(d["cost"])
				tech["prog"].erase(id)
				tech["pas"].erase(id)
				tech["done"][id] = turn
				tech["cur"][b] = ""
				tech["bank"][b] = pg
				log_tag("НАУКА", COL_GOOD, "%s: изучена технология «%s» (%s ветка). %s" % [date_text(), d["name"], String(TECH_BRANCHES[b]["name"]).to_lower(), tech_fx_text(d)])
				if not opp_mode:
					tech["cur"][b] = tech_q_next(b)
					if String(tech["cur"][b]) != "":
						log_tag("НАУКА", COL_DIM, "Из очереди начато изучение «%s»." % tech_def(String(tech["cur"][b]))["name"])
				if String(tech["cur"][b]) == "" and (bool(tech["auto"]) or opp_mode):
					tech["cur"][b] = tech_ai_pick(b, false)
					if String(tech["cur"][b]) == "" and tech_choice_waiting(b) and not bool(tech["ai_all"]) and not opp_mode:
						log_tag("НАУКА", COL_WARN, "В ветке «%s» открыт выбор «или»: можно изучить только одну технологию. Выберите в окне технологий, иначе ИИ-советник выберет сам через %d мес." % [String(TECH_BRANCHES[b]["name"]).to_lower(), TECH_WAIT_MONTHS])
			else:
				tech["prog"][id] = pg
	if wmonth:
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


# ---------- соседи и пассивное изучение ----------


func tech_nb() -> Array:
	# соседи: страны с общей сухопутной границей; если их меньше трёх — самые тесные торговые партнёры
	if tech.is_empty():
		return []
	if (tech["nb"] as Array).is_empty():
		var out: Array = []
		for c in wsim:
			if c != ccode and mil_land_neighbor(String(c)):
				out.append(String(c))
		if out.size() < 3:
			var ps: Array = ex_partners()
			ps.sort_custom(func(a, b): return float(ex_dep(a)["out"]) + float(ex_dep(a)["in"]) > float(ex_dep(b)["out"]) + float(ex_dep(b)["in"]))
			for c2 in ps:
				if out.size() >= 3:
					break
				if not (c2 in out):
					out.append(String(c2))
		tech["nb"] = out
	return tech["nb"]


func tech_hash(c: String, tag: String) -> int:
	return int(hash(c + "|" + tag))


func tech_nb_pace(c: String) -> float:
	# чем богаче страна, тем раньше она осваивает уровни (0,9…1,5 от нашего графика)
	var pc: Dictionary = tech["pace"]
	if not pc.has(c):
		var g0: float = float(WORLD[c]["gdp"]) / maxf(0.1, float(WORLD[c]["pop"]))
		var lower := 0
		var n := 0
		for o in wsim:
			if o == c or not WORLD.has(o):
				continue
			n += 1
			if float(WORLD[o]["gdp"]) / maxf(0.1, float(WORLD[o]["pop"])) < g0:
				lower += 1
		pc[c] = 1.5 - 0.6 * float(lower) / maxf(1.0, float(n))
	return float(pc[c])


func tech_nb_tiers(c: String, b: int) -> int:
	# сколько уровней ветки b уже открыто у страны c (с запаздыванием и своим темпом в ветке)
	var f: float = tech_nb_pace(c) * (0.9 + 0.3 * float(tech_hash(c, "bf%d" % b) % 100) / 100.0)
	var lag: float = 2.0 * float(tech_hash(c, "lag%d" % b) % 100) / 100.0
	var yrs: float = years_passed()
	var n := 0
	var ty: Array = tech["ty"]
	for t in ty.size():
		if yrs >= float(ty[t]) * f + (lag if t > 0 else 0.0):
			n = t + 1
		else:
			break
	return n


func tech_nb_has(c: String, id: String) -> bool:
	var d := tech_def(id)
	if d.is_empty():
		return false
	var b: int = int(d["b"])
	var t: int = int(d["t"])
	if t >= tech_nb_tiers(c, b):
		return false
	var grp: Array = (tech["grp"][b] as Dictionary)[t]
	if grp.size() == 1:
		return String(grp[0]) == id
	return tech_nb_pick(c, b, t) == id


func tech_nb_who(id: String) -> Array:
	var out: Array = []
	for c in tech_nb():
		if tech_nb_has(String(c), id):
			out.append(String(c))
	return out


func tech_nb_share(id: String) -> float:
	var n: int = tech_nb().size()
	if n == 0:
		return 0.0
	return float(tech_nb_who(id).size()) / float(n)


func tech_passive_rate(id: String) -> float:
	# очков в месяц, которые изучаемая технология получает от того, что её знают соседи (без учёта предела)
	var d := tech_def(id)
	if d.is_empty():
		return 0.0
	return TECH_PASSIVE * float(d["cost"]) * tech_nb_share(id) * tech_pas_mult


# ---------- ИИ-выбор технологий (v43_1) ----------
# Потребности страны — словарь «модификатор → вес». Оценка технологии = Σ вес × (эффект / масштаб) × знак (знак — по MOD_INFO["g"]).
# Один и тот же расчёт служит советнику игрока (по текущему состоянию страны) и странам-соседям (по их стартовым данным).


func tech_state_player() -> Dictionary:
	# показатели страны игрока, от которых зависят потребности
	var sup := {}
	for g in GROUPS:
		sup[g] = float(support[g])
	return {"growth": growth, "unemp": unemployment, "dbt": debt / maxf(1.0, gdp) * 100.0, "deficit": clampf(last_deficit_pct, -3.0, 8.0),
		"war": 1.0 if mil_at_war() else 0.0, "infra": float(lvl["infra_lvl"]), "env": float(lvl["env_lvl"]), "edu": float(lvl["edu_lvl"]),
		"health": float(lvl["health_lvl"]), "sec": float(lvl["security_lvl"]), "corr": float(lvl["corruption"]), "equal": float(lvl["equality"]),
		"appr": approval(), "risk": regime_risk, "unrest": reg_avg("unrest"), "threat": tech_threat(), "sup": sup}


func tech_state_neutral() -> Dictionary:
	# нейтральное состояние для аудита баланса: не зависит от страны игрока
	var sup := {}
	for g in GROUPS:
		sup[g] = 50.0
	return {"growth": 1.5, "unemp": 6.0, "dbt": 70.0, "deficit": 2.0, "war": 0.0, "infra": 50.0, "env": 50.0, "edu": 50.0, "health": 50.0, "sec": 50.0,
		"corr": 40.0, "equal": 50.0, "appr": 50.0, "risk": 0.0, "unrest": 25.0, "threat": 0.0, "sup": sup}


func tech_needs_player() -> Dictionary:
	return tech_needs_from(tech_state_player())


func tech_needs_from(st: Dictionary) -> Dictionary:
	var n := {}
	var dbt: float = float(st["dbt"])
	var deficit: float = float(st["deficit"])
	var war: float = float(st["war"])
	n["growth_bonus"] = 1.0 + clampf(1.6 - float(st["growth"]), 0.0, 1.5) * 0.5
	n["eff_bonus"] = 0.5 + clampf(deficit, 0.0, 6.0) * 0.15 + clampf(dbt - 70.0, 0.0, 60.0) * 0.01
	n["infra_eff"] = 0.35 + clampf(55.0 - float(st["infra"]), 0.0, 40.0) * 0.02
	n["env_eff"] = 0.35 + clampf(55.0 - float(st["env"]), 0.0, 40.0) * 0.02
	n["edu_eff"] = 0.45 + clampf(55.0 - float(st["edu"]), 0.0, 40.0) * 0.02
	n["health_eff"] = 0.45 + clampf(55.0 - float(st["health"]), 0.0, 40.0) * 0.02
	n["unemp_base"] = 0.4 + clampf(float(st["unemp"]) - 5.0, 0.0, 10.0) * 0.18
	n["sec_bonus"] = 0.35 + war * 1.5 + clampf(float(st["risk"]), 0.0, 100.0) * 0.01 + clampf(55.0 - float(st["sec"]), 0.0, 40.0) * 0.02
	n["corr_shift"] = 0.3 + clampf(float(st["corr"]) - 35.0, 0.0, 40.0) * 0.03
	n["equal_shift"] = 0.25 + clampf(55.0 - float(st["equal"]), 0.0, 40.0) * 0.02
	n["dip_bonus"] = 0.35 + war * 0.6
	n["capital_bonus"] = 0.7
	n["mood_shift"] = 0.35 + clampf(50.0 - float(st["appr"]), 0.0, 30.0) * 0.03
	n["dem_shift"] = 0.0
	n["admin_mult"] = 0.3 + clampf(deficit, 0.0, 6.0) * 0.12
	n["extra_spend"] = 0.3 + clampf(deficit, 0.0, 6.0) * 0.12
	n["corp_mult"] = 0.45 + clampf(deficit, 0.0, 6.0) * 0.05
	n["zone_eff"] = 0.3
	n["reg_unrest_shift"] = 0.3 + clampf(float(st["unrest"]) - 25.0, 0.0, 40.0) * 0.04
	n["army_q"] = 0.3 + war * 2.2 + clampf(float(st["threat"]), 0.0, 1.0) * 0.8
	for g in GROUPS:
		n["gb_" + g] = 0.15 + 0.4 + clampf(55.0 - float((st["sup"] as Dictionary)[g]), 0.0, 30.0) * 0.03
	n["rs"] = 1.1
	n["cp"] = 0.9
	return n


func tech_threat() -> float:
	# 0..1: насколько страна ощущает военную угрозу (враждебные соседи, недавняя война, напряжённость в мире)
	var t := 0.0
	for c in tech_nb():
		if dip.has(c) and float(dip[c]["rel"]) < 30.0:
			t += 0.25
	return clampf(t, 0.0, 1.0)


func tech_needs_bot(c: String) -> Dictionary:
	# потребности страны-бота по стартовым данным мира (WORLD): слабый рост → рост, безработица → занятость, нестабильность → безопасность…
	var nb: Dictionary = tech["nbn"]
	if nb.has(c):
		return nb[c]
	var w: Dictionary = WORLD[c]
	var dem: float = float(MIL_DEMO.get(c, 0.6))
	var rich: float = float(w["gdp"]) / maxf(0.1, float(w["pop"]))
	var n := {}
	n["growth_bonus"] = 1.0 + clampf(1.6 - float(w["growth"]), 0.0, 1.5) * 0.5
	n["eff_bonus"] = 0.5 + clampf(float(w["def"]), 0.0, 6.0) * 0.15 + clampf(float(w["debt"]) - 70.0, 0.0, 60.0) * 0.01
	n["infra_eff"] = 0.5 - clampf(rich, 0.0, 80.0) * 0.003 + 0.2
	n["env_eff"] = 0.35 + dem * 0.3
	n["edu_eff"] = 0.5 + (1.0 - clampf(rich / 70.0, 0.0, 1.0)) * 0.3
	n["health_eff"] = 0.5
	n["unemp_base"] = 0.4 + clampf(float(w["unemp"]) - 5.0, 0.0, 10.0) * 0.18
	n["sec_bonus"] = 0.4 + clampf(60.0 - float(w["stab"]), 0.0, 40.0) * 0.03 + (0.5 if c in ["RS", "BA", "XK", "MK", "AL", "ME", "PL", "LT", "LV", "EE", "FI"] else 0.0)
	n["corr_shift"] = 0.3 + (1.0 - dem) * 1.2
	n["equal_shift"] = 0.3 + (1.0 - dem) * 0.2
	n["dip_bonus"] = 0.4
	n["capital_bonus"] = 0.6
	n["mood_shift"] = 0.35 + clampf(50.0 - float(w["appr"]), 0.0, 30.0) * 0.03
	n["dem_shift"] = 0.0
	n["admin_mult"] = 0.3 + clampf(float(w["def"]), 0.0, 6.0) * 0.1
	n["extra_spend"] = 0.3 + clampf(float(w["def"]), 0.0, 6.0) * 0.1
	n["corp_mult"] = 0.45
	n["zone_eff"] = 0.3
	n["reg_unrest_shift"] = 0.3 + clampf(60.0 - float(w["stab"]), 0.0, 40.0) * 0.02
	n["army_q"] = 0.3 + (0.7 if c in ["PL", "LT", "LV", "EE", "FI", "RS", "BA", "XK", "GR", "BG", "RO", "NO", "DK"] else 0.0) + clampf(60.0 - float(w["stab"]), 0.0, 40.0) * 0.01
	for g in GROUPS:
		n["gb_" + g] = 0.15 + 0.4
	n["rs"] = 1.1
	n["cp"] = 0.9
	nb[c] = n
	return n


func tech_score(id: String, needs: Dictionary) -> float:
	var d := tech_def(id)
	if d.is_empty():
		return 0.0
	var s := 0.0
	var fx: Dictionary = d["fx"]
	for k in fx:
		if not TECH_AI_SCALE.has(k) or not needs.has(k):
			continue
		var g: int = int(MOD_INFO[k]["g"]) if MOD_INFO.has(k) else 1
		if g == 0:
			g = 1
		s += float(needs[k]) * float(g) * float(fx[k]) / float(TECH_AI_SCALE[k])
	for k2 in ["rs", "cp"]:
		if d.has(k2):
			s += float(needs[k2]) * float(d[k2]) / float(TECH_AI_SCALE[k2])
	return s


func tech_score_text(id: String, needs: Dictionary) -> String:
	# главные причины оценки: два самых весомых слагаемых
	var d := tech_def(id)
	var parts: Array = []
	var fx: Dictionary = d["fx"]
	for k in fx:
		if not TECH_AI_SCALE.has(k) or not needs.has(k):
			continue
		var g: int = int(MOD_INFO[k]["g"]) if MOD_INFO.has(k) else 1
		if g == 0:
			g = 1
		parts.append([float(needs[k]) * float(g) * float(fx[k]) / float(TECH_AI_SCALE[k]), k])
	parts.sort_custom(func(a, b): return float(a[0]) > float(b[0]))
	var out := PackedStringArray()
	for i in mini(2, parts.size()):
		if float(parts[i][0]) <= 0.05:
			break
		out.append(String(MOD_INFO[parts[i][1]]["t"]) if MOD_INFO.has(parts[i][1]) else String(parts[i][1]))
	return ", ".join(out)


func tech_ai_pick(b: int, allow_choice: bool = true) -> String:
	# лучший по оценке вариант среди доступных в ветке (оценка делится на корень цены: дешёвое окупается раньше)
	var needs := tech_needs_player()
	var best := ""
	var bs := -1e18
	for d in TECHS:
		var id: String = d["id"]
		if int(d["b"]) != b or not tech_avail(id):
			continue
		if not allow_choice and tech_is_choice(id):
			continue
		var left: float = float(d["cost"]) - float(tech["prog"].get(id, 0.0))
		var sc: float = tech_score(id, needs) / sqrt(maxf(50.0, left))
		if sc > bs:
			bs = sc
			best = id
	return best


func tech_nb_pick(c: String, b: int, t: int) -> String:
	# выбор страны-бота на уровне «или»: самая полезная для неё технология; небольшой шум от хэша, чтобы одинаковые страны различались
	var key := "%s|%d|%d" % [c, b, t]
	var cache: Dictionary = tech["nbp"]
	if cache.has(key):
		return String(cache[key])
	var grp: Array = (tech["grp"][b] as Dictionary)[t]
	var needs := tech_needs_bot(c)
	var best := String(grp[0])
	var bs := -1e18
	for id in grp:
		var noise: float = 0.9 + 0.2 * float(tech_hash(c, "n" + String(id)) % 100) / 100.0
		var sc: float = tech_score(String(id), needs) * noise
		if sc > bs:
			bs = sc
			best = String(id)
	cache[key] = best
	return best


func tech_audit_profiles() -> Array:
	# профили для аудита баланса: потребности 34 стран мира и 10 условных ситуаций поверх нейтрального игрока (имена в паре [имя, потребности])
	var out: Array = []
	for c in WORLD:
		out.append([String(c), tech_needs_bot(String(c))])
	var base := tech_needs_from(tech_state_neutral())
	var sit := {
		"война": {"army_q": 2.5, "sec_bonus": 1.5, "dip_bonus": 0.5},
		"безработица": {"unemp_base": 2.0, "gb_Рабочие": 1.0},
		"долг": {"extra_spend": 1.5, "admin_mult": 1.2, "eff_bonus": 1.5, "corp_mult": 1.0},
		"волнения": {"reg_unrest_shift": 2.0, "mood_shift": 1.5, "sec_bonus": 1.0, "equal_shift": 1.0},
		"коррупция": {"corr_shift": 2.5},
		"стагнация": {"growth_bonus": 2.0, "corp_mult": 1.0, "zone_eff": 1.0},
		"экология": {"env_eff": 2.0, "gb_Экологи": 1.5},
		"старение": {"health_eff": 1.5, "gb_Пенсионеры": 1.5},
		"молодёжь": {"edu_eff": 1.5, "gb_Молодёжь": 1.5, "rs": 1.5},
		"сильная власть": {"capital_bonus": 1.5, "admin_mult": 1.0, "sec_bonus": 0.8},
	}
	for k in sit:
		var n: Dictionary = base.duplicate()
		for key in sit[k]:
			n[key] = float(n.get(key, 0.0)) * 0.5 + float(sit[k][key])
		out.append(["#" + String(k), n])
	return out
