# v55_1: подробные товары и промышленность.
# 46 подробных потребительских товаров лежат ВНУТРИ 18 категорий корзины (хлеб, мясо, молочка… внутри «Продуктов»):
# цена категории считается как раньше, а цены её товаров отклоняются от неё за счёт цепочек и событий (в среднем по категории — ноль).
# 18 промышленных товаров и видов оружия (нефть, газ, уголь, руда, зерно, лес, сталь, цветмет, удобрения, химия, микросхемы,
# оборудование, шесть видов оружия): у страны есть самообеспеченность (производство / потребление). Если своего не хватает,
# а импорт ограничен санкциями или войной, появляется надбавка к цене; она идёт по цепочкам (руда → сталь → машины)
# и в цены потребительских товаров. Стройка заводов и мегапроекты повышают самообеспеченность. Всё — отклонение от старта.
extends "res://scripts/logic/church.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func ar_ind() -> float:
	return 0.0


func con_ind(id: String) -> float:
	return 0.0


func fa_ws_lvl() -> int:
	return 0


# --- конец заглушек ---


const IND_BLOCK := [0.0, 0.05, 0.45, 0.8]        # доля импорта, перекрытая санкциями (по уровню санкций Запада)
const IND_TECH := ["chips", "machinery", "arms_air", "arms_ad", "arms_drones"]   # высокие технологии: санкции бьют сильнее
const IND_W := {"raw": 0.03, "mid": 0.045, "arms": 0.012}   # вес товара в экономике для роста

var ind := {}
var ind_rng := RandomNumberGenerator.new()


func ind_on() -> bool:
	return ind.has("g")


func ind_dyn() -> bool:
	return int(game_opts.get("exev", 1)) == 1


func gi_def(id: String) -> Dictionary:
	return CU["gi"][id] if CU.has("gi") and (CU["gi"] as Dictionary).has(id) else {}


func gx_def(id: String) -> Dictionary:
	return CU["gx"][id] if CU.has("gx") and (CU["gx"] as Dictionary).has(id) else {}


func gi_ids() -> Array:
	return (CU["gi"] as Dictionary).keys() if CU.has("gi") else []


func gx_ids() -> Array:
	return (CU["gx"] as Dictionary).keys() if CU.has("gx") else []


func gx_of_cat(cat: String) -> Array:
	var out: Array = []
	for id in gx_ids():
		if String(CU["gx"][id]["cat"]) == cat:
			out.append(String(id))
	return out


func ind_init() -> void:
	if not CU.has("gi"):
		ind = {}
		return
	ind_rng.seed = hash(ccode) + 211
	var c := cu_cfg()
	var ci: Dictionary = c["ind"]
	var gm: Dictionary = c["gx"]
	ind = {"g": {}, "x": {}, "w": {}, "h": {}, "evlog": [], "cd": {}, "arm0": ar_ind()}
	for id in gi_ids():
		var ss: float = float(ci.get(id, 0.5))
		ind["g"][id] = {"ss0": ss, "boost": 0.0, "tmp": 0.0, "prem": 0.0, "prem0": 0.0, "p": 1.0}
		ind["h"][id] = [1.0]
	# доли подробных товаров в своей категории (с местными привычками)
	var cats := {}
	for id in gx_ids():
		var w: float = float(CU["gx"][id]["sh"]) * float(gm.get(id, 1.0))
		ind["w"][id] = w
		var cat := String(CU["gx"][id]["cat"])
		cats[cat] = float(cats.get(cat, 0.0)) + w
	for id in gx_ids():
		ind["w"][id] = float(ind["w"][id]) / maxf(0.0001, float(cats[String(CU["gx"][id]["cat"])]))
		ind["x"][id] = {"d": 0.0, "sh": 0.0, "n": 0.0, "p": 1.0}
		ind["h"][id] = [1.0]
	# стартовые надбавки (санкции и война на старте уже «в экономике»)
	for k in 24:
		ind_prem_step()
	for id in gi_ids():
		ind["g"][id]["prem0"] = float(ind["g"][id]["prem"])


# самообеспеченность сейчас: стартовая × стройка × оборонная промышленность (для оружия)
func ind_ss(id: String) -> float:
	var g: Dictionary = ind["g"][id]
	var b: float = float(g["boost"]) + con_ind(id)
	var ss: float = float(g["ss0"]) * (1.0 + b) + b * 0.3
	if String(gi_def(id).get("kind", "")) == "arms":
		ss *= (0.5 + ar_ind()) / maxf(0.1, 0.5 + float(ind["arm0"]))
	return maxf(0.0, ss - float(g["tmp"]))


func ind_ss0(id: String) -> float:
	return float(ind["g"][id]["ss0"])


func ind_block(id: String) -> float:
	var lv: int = clampi(fa_ws_lvl(), 0, 3)
	var b: float = float(IND_BLOCK[lv])
	if id in IND_TECH:
		b = minf(0.95, b * 1.25)
	return b


func ind_prem_step() -> void:
	var war: bool = mil_at_war()
	var old := {}
	for id in gi_ids():
		old[id] = float(ind["g"][id]["prem"])
	var inputs: Dictionary = CU.get("inputs", {})
	for id in gi_ids():
		var kind := String(gi_def(id)["kind"])
		var need: float = maxf(0.0, 1.0 - ind_ss(id))
		if war and kind == "arms":
			need = maxf(need, 0.6 - 0.3 * minf(1.0, ind_ss(id)))
		var pr: float = need * (ind_block(id) * 1.2 + (0.25 if war and kind == "arms" else 0.0))
		var inp: Dictionary = inputs.get(id, {})
		for h in inp:
			pr += float(inp[h]) * float(old.get(h, 0.0))
		ind["g"][id]["prem"] = clampf(pr, 0.0, 2.0)


func ind_dprem(id: String) -> float:
	var g: Dictionary = ind["g"][id]
	return float(g["prem"]) - float(g["prem0"])


# добавка к цене категории корзины от цепочек (0 на старте)
func ind_cat_term(cat: String) -> float:
	if not ind_on():
		return 0.0
	var inputs: Dictionary = CU.get("inputs", {})
	var t := 0.0
	for x in gx_of_cat(cat):
		var inp: Dictionary = inputs.get(x, {})
		var s := 0.0
		for h in inp:
			if (ind["g"] as Dictionary).has(h):
				s += float(inp[h]) * ind_dprem(h)
		t += float(ind["w"][x]) * s * 0.5
	return t


# рост: изменение выпуска (самообеспеченность) и надбавок относительно старта
func ind_g() -> float:
	if not ind_on():
		return 0.0
	var g := 0.0
	for id in gi_ids():
		var w: float = float(IND_W.get(String(gi_def(id)["kind"]), 0.03))
		g += w * (minf(ind_ss(id), 3.0) - minf(ind_ss0(id), 3.0)) * 0.8
		g -= w * ind_dprem(id) * 1.5
	return clampf(g, -2.0, 2.0)


# цена оружия для армии (1.0 — как на старте)
func ind_arms_price() -> float:
	if not ind_on():
		return 1.0
	return 1.0 + 0.5 * (ind_dprem("arms_small") + ind_dprem("arms_armor")) * 0.5


func ind_month() -> void:
	if not ind_on():
		return
	# 0.62: кулдауны и история цен (14 месяцев) — только при закрытии месяца; затухание, шумы и шоки идут на долю месяца wdt
	if wmonth:
		var cd: Dictionary = ind["cd"]
		for k in cd.keys():
			cd[k] = int(cd[k]) - 1
			if int(cd[k]) <= 0:
				cd.erase(k)
	var k_tmp: float = 0.9 if wdt == 1.0 else pow(0.9, wdt)
	for id in gi_ids():
		ind["g"][id]["tmp"] = float(ind["g"][id]["tmp"]) * k_tmp
	ind_prem_step()
	var comm: float = float(ec.get("comm", 1.0))
	for id in gi_ids():
		var g: Dictionary = ind["g"][id]
		var pw: float = 1.0 + float(gi_def(id)["dc"]) * (comm - 1.0)
		g["p"] = pw * (1.0 + float(g["prem"])) / (1.0 + float(g["prem0"]))
		if wmonth:
			ind_hist(id, float(g["p"]))
	# подробные товары: отклонение от цены своей категории, в среднем по категории — ноль
	var inputs: Dictionary = CU.get("inputs", {})
	var vol: float = float(game_opts.get("volat", 1.0))
	var raw := {}
	# шум и шоки цен товаров: затухание за неделю слабее месячного, амплитуда шума подобрана так, чтобы разброс остался прежним
	var k_n: float = 0.85 if wdt == 1.0 else pow(0.85, wdt)
	var k_sh: float = 0.88 if wdt == 1.0 else pow(0.88, wdt)
	var a_n: float = 1.0 if wdt == 1.0 else sqrt((1.0 - k_n * k_n) / (1.0 - 0.85 * 0.85))
	for x in gx_ids():
		var e: Dictionary = ind["x"][x]
		e["n"] = float(e["n"]) * k_n + ind_rng.randf_range(-0.006, 0.006) * vol * a_n
		e["sh"] = float(e["sh"]) * k_sh
		var s := 0.0
		var inp: Dictionary = inputs.get(x, {})
		for h in inp:
			if (ind["g"] as Dictionary).has(h):
				s += float(inp[h]) * (float(ind["g"][h]["p"]) - 1.0)
		raw[x] = 0.6 * s + float(e["n"]) + float(e["sh"])
	var gp: Dictionary = ec.get("gp", {})
	for g2 in GOODS:
		var cat: String = String(g2["id"])
		var xs := gx_of_cat(cat)
		var avg := 0.0
		for x in xs:
			avg += float(ind["w"][x]) * float(raw[x])
		for x in xs:
			var d: float = clampf(float(raw[x]) - avg, -0.6, 1.5)
			ind["x"][x]["d"] = d
			ind["x"][x]["p"] = float(gp.get(cat, 1.0)) * (1.0 + d)
			if wmonth:
				ind_hist(x, float(ind["x"][x]["p"]))
	if ind_dyn():
		ind_events()


func ind_hist(id: String, v: float) -> void:
	var h: Array = ind["h"][id]
	h.append(v)
	if h.size() > 14:
		h.pop_front()


func ind_yoy(id: String) -> float:
	var h: Array = ind["h"].get(id, [])
	return float(h[h.size() - 1]) / float(h[0]) - 1.0 if h.size() > 1 else 0.0


func gx_price(id: String) -> float:
	return float(ind["x"][id]["p"]) if ind_on() and (ind["x"] as Dictionary).has(id) else 1.0


func gi_price(id: String) -> float:
	return float(ind["g"][id]["p"]) if ind_on() and (ind["g"] as Dictionary).has(id) else 1.0


func gx_name(id: String) -> String:
	return String(gx_def(id).get("name", id))


func gi_name(id: String) -> String:
	return String(gi_def(id).get("name", id))


# стройка и мегапроекты: прибавка к самообеспеченности (доля)
func ind_add_boost(id: String, v: float) -> void:
	if ind_on() and (ind["g"] as Dictionary).has(id):
		ind["g"][id]["boost"] = maxf(-0.9, float(ind["g"][id]["boost"]) + v)


# экспортные товары страны: [[id, название, самообеспеченность], ...]
func ind_exports() -> Array:
	var out: Array = []
	if not ind_on():
		return out
	for id in gi_ids():
		if ind_ss(id) >= 1.15:
			out.append([String(id), gi_name(id), ind_ss(id)])
	var ci: Dictionary = cu_cfg()["ind"]
	for id in ci:
		if (ind["x"] as Dictionary).has(id) and float(ci[id]) >= 1.15:
			out.append([String(id), gx_name(id), float(ci[id])])
	out.sort_custom(func(a, b): return float(a[2]) > float(b[2]))
	return out


# 0.55.5: главные товары региона — по его отраслям (сырьё, сельское хозяйство, промышленность), самообеспеченности страны
# и сооружениям в регионе. Это оценка для подсказки, на экономику не влияет.
func region_goods(i: int, n: int) -> Array:
	if not ind_on() or i < 0 or i >= REGIONS.size():
		return []
	var sec: Dictionary = REGIONS[i].get("sec", {})
	var sc := {}
	for id in gi_ids():
		var g: Dictionary = gi_def(String(id))
		var s0: float = float(sec.get(String(g.get("mk", "ind")), 0.0))
		var ss: float = ind_ss(String(id))
		if ss < 0.3 or s0 < 0.05:
			continue
		sc[id] = s0 * minf(ss, 2.5)
	var ci: Dictionary = cu_cfg()["ind"]
	for id in ci:
		if not (ind["x"] as Dictionary).has(id) or float(ci[id]) < 1.15:
			continue
		var cat: String = String(gx_def(String(id)).get("cat", ""))
		var mk: String = String(good_def(cat).get("mk", "ind")) if cat != "" else "ind"
		var s1: float = float(sec.get(mk if mk in ["agr", "ind", "res"] else "srv", 0.0))
		sc[id] = s1 * minf(float(ci[id]), 2.5)
	if i < regions.size():
		var bt: Dictionary = regions[i].get("built", {})
		for bid in bt:
			var pd := find_by_id(PROJECTS, String(bid))
			for k in (pd.get("ind", {}) as Dictionary):
				sc[k] = float(sc.get(k, 0.0)) + 0.5 * float(int((bt[bid] as Dictionary).get("n", 0)))
	var arr: Array = []
	for id in sc:
		arr.append([String(id), float(sc[id])])
	arr.sort_custom(func(a, b): return float(a[1]) > float(b[1]))
	var out: Array = []
	for it in arr:
		if out.size() >= n:
			break
		var nm: String = gi_name(String(it[0])) if gi_def(String(it[0])).size() > 0 else gx_name(String(it[0]))
		out.append(nm.to_lower())
	return out


func ind_imports() -> Array:
	var out: Array = []
	if not ind_on():
		return out
	for id in gi_ids():
		if ind_ss(id) < 0.6:
			out.append([String(id), gi_name(id), ind_ss(id)])
	out.sort_custom(func(a, b): return float(a[2]) < float(b[2]))
	return out


# ---------------- события ----------------


func ind_events(force: String = "") -> void:
	if not current_event.is_empty() or election_open:
		return
	if force == "" and ind_rng.randf() > wp(0.03):
		return
	var kinds: Array = ["harvest", "tobacco"]
	if ind_ss("chips") < 0.6:
		kinds += ["chips"]
	if ind_ss("steel") >= 0.5:
		kinds += ["dumping"]
	if ind_ss("natgas") < 0.8:
		kinds += ["fert"]
	var arms := ""
	for id in ["arms_small", "arms_armor", "arms_air", "arms_ad", "arms_ships", "arms_drones"]:
		if ind_ss(id) >= 0.9 and (arms == "" or ind_ss(id) > ind_ss(arms)):
			arms = id
	if arms != "" and not mil_at_war():
		kinds += ["arms"]
	if not ind_exports().is_empty():
		kinds += ["export"]
	var kind: String = String(kinds[ind_rng.randi() % kinds.size()])
	if force != "" and (force in kinds):
		kind = force
	var ev := {}
	match kind:
		"chips":
			ev = {"t": "Мировой дефицит микросхем: автозаводы и производители техники останавливают конвейеры, машины и электроника дорожают.", "o": [
				{"l": "Субсидировать закупки и местную сборку (долг +0.05% ВВП)", "fx": {"debt": 0.05, "support": {"Рабочие": 1.0}, "ind": {"tmp": {"chips": 0.05}, "xsh": {"newcars": 0.04, "phones": 0.03}}}},
				{"l": "Переждать", "fx": {"support": {"Рабочие": -1.0, "Бизнес": -1.0}, "ind": {"tmp": {"chips": 0.2}, "xsh": {"newcars": 0.1, "evcars": 0.08, "phones": 0.08, "tv": 0.06}}}}]}
		"dumping":
			ev = {"t": "На рынок пришла дешёвая импортная сталь: местные комбинаты жалуются на демпинг и грозят сокращениями.", "o": [
				{"l": "Ввести защитные пошлины", "fx": {"support": {"Рабочие": 1.5, "Бизнес": -1.0}, "ind": {"boost": {"steel": 0.03}, "xsh": {"appliances": 0.02, "newcars": 0.01}}}},
				{"l": "Оставить рынок открытым", "fx": {"support": {"Рабочие": -2.0, "Бизнес": 1.0}, "ind": {"boost": {"steel": -0.05}, "xsh": {"appliances": -0.02}}}}]}
		"fert":
			ev = {"t": "Газ подорожал — заводы удобрений сокращают выпуск, фермеры боятся неурожая и роста цен на хлеб и овощи.", "o": [
				{"l": "Дотировать удобрения фермерам (долг +0.03% ВВП)", "fx": {"debt": 0.03, "support": {"Село": 2.0}, "ind": {"tmp": {"fert": 0.05}}}},
				{"l": "Не вмешиваться", "fx": {"support": {"Село": -2.0}, "ind": {"tmp": {"fert": 0.25}, "xsh": {"bread": 0.05, "vegfruit": 0.06}}}}]}
		"harvest":
			if ind_rng.randf() < 0.5:
				ev = {"t": "Засуха: урожай зерна и овощей заметно ниже обычного. Хлеб, мясо и овощи дорожают.", "o": [
					{"l": "Выкупить зерно из госрезерва (долг +0.03% ВВП)", "fx": {"debt": 0.03, "support": {"Село": 1.0, "Пенсионеры": 1.0}, "ind": {"tmp": {"grain": 0.1}, "xsh": {"bread": 0.02}}}},
					{"l": "Компенсировать фермерам потери (долг +0.04% ВВП)", "fx": {"debt": 0.04, "support": {"Село": 2.5}, "ind": {"tmp": {"grain": 0.25}, "xsh": {"bread": 0.06, "meat": 0.04, "vegfruit": 0.08}}}},
					{"l": "Ничего не делать", "fx": {"support": {"Село": -2.0, "Пенсионеры": -1.0}, "ind": {"tmp": {"grain": 0.3}, "xsh": {"bread": 0.08, "meat": 0.05, "vegfruit": 0.1}}}}]}
			else:
				ev = {"t": "Рекордный урожай: зерно и овощи дешевеют, фермеры просят закупочных интервенций.", "o": [
					{"l": "Провести интервенции (долг +0.02% ВВП)", "fx": {"debt": 0.02, "support": {"Село": 2.0}, "ind": {"xsh": {"bread": -0.02}}}},
					{"l": "Пусть цены падают", "fx": {"support": {"Село": -1.5, "Пенсионеры": 1.0, "Рабочие": 0.5}, "ind": {"xsh": {"bread": -0.06, "vegfruit": -0.08, "meat": -0.03}}}}]}
		"tobacco":
			ev = {"t": "Минздрав предлагает резко поднять акцизы на табак и крепкий алкоголь: меньше болезней, больше денег в бюджете.", "o": [
				{"l": "Поднять акцизы", "fx": {"debt": -0.03, "support": {"Пенсионеры": -0.5, "Рабочие": -1.0, "Бюджетники": 0.5}, "ind": {"xsh": {"tobacco": 0.15, "spirits": 0.08}}, "regall": {"health": 0.5}}},
				{"l": "Поднять только на табак", "fx": {"debt": -0.015, "support": {"Рабочие": -0.5}, "ind": {"xsh": {"tobacco": 0.12}}}},
				{"l": "Отказаться", "fx": {"support": {"Бюджетники": -0.5}}}]}
		"arms":
			ev = {"t": "Иностранный покупатель предлагает крупный контракт: %s с наших заводов." % gi_name(arms).to_lower(), "o": [
				{"l": "Подписать контракт (доход 0.06% ВВП)", "fx": {"debt": -0.06, "support": {"Рабочие": 1.0, "Силовики": 1.0, "Экологи": -1.5, "Молодёжь": -0.5}, "ind": {"tmp": {arms: 0.1}}}},
				{"l": "Отказать: оружие нужно своей армии", "fx": {"support": {"Силовики": 0.5, "Бизнес": -0.5}}}]}
		"export":
			var ex: Array = ind_exports()[ind_rng.randi() % ind_exports().size()]
			ev = {"t": "Экспортёры («%s») нашли новые рынки сбыта и просят государственную поддержку: кредиты и выставки за рубежом." % String(ex[1]).to_lower(), "o": [
				{"l": "Поддержать экспорт (долг +0.02% ВВП)", "fx": {"debt": 0.02, "support": {"Бизнес": 1.5}, "ind": {"boost": {String(ex[0]): 0.03}}}},
				{"l": "Без поддержки", "fx": {"support": {"Бизнес": -0.5}}}]}
	if ev.is_empty():
		return
	ev["kind"] = "ind"
	(ind["evlog"] as Array).append("%s: %s" % [date_text(), String(ev["t"])])
	if (ind["evlog"] as Array).size() > 12:
		(ind["evlog"] as Array).pop_front()
	soc_push_event(ev, -1)


func ind_fx(d: Dictionary) -> void:
	if not ind_on():
		return
	if d.has("boost"):
		for id in d["boost"]:
			ind_add_boost(String(id), float(d["boost"][id]))
	if d.has("tmp"):
		for id in d["tmp"]:
			if (ind["g"] as Dictionary).has(id):
				ind["g"][id]["tmp"] = clampf(float(ind["g"][id]["tmp"]) + float(d["tmp"][id]), 0.0, 0.9)
	if d.has("xsh"):
		for id in d["xsh"]:
			if (ind["x"] as Dictionary).has(id):
				ind["x"][id]["sh"] = float(ind["x"][id]["sh"]) + float(d["xsh"][id])
				# заметная часть шока ложится и на категорию корзины
				goods_shock(String(CU["gx"][id]["cat"]), float(d["xsh"][id]) * float(ind["w"][id]) * 0.8)
