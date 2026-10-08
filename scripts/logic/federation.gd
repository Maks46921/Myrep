# Федерация, автономия субъектов и передача территорий (покупка региона, добровольное объединение стран).
extends "res://scripts/logic/world.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func ate_unit_has_capital(cc: String, ui: int) -> bool:
	return false


func map_rebuild() -> void:
	pass


func soc_init_region(i: int, cc: String, code: String) -> void:
	pass


# --- конец заглушек ---


const FED_SPH := [
	["tax", "Налоги и бюджет", "Кто собирает и тратит налоги. Выше — богаче регион и его власти, но центру достаётся меньше."],
	["pol", "Полиция и порядок", "Кто отвечает за полицию и суды низшего звена. Региональная полиция снижает недовольство, но ослабляет единые стандарты."],
	["edu", "Образование и культура", "Школы, университеты, язык и культура. Самая «любимая» сфера регионов: даёт лояльность, особенно там, где силён местный национализм."],
	["hlt", "Здравоохранение и соцзащита", "Больницы и местные пособия. Хорошо работает при толковом главе региона, плохо — при слабом."],
	["eco", "Экономика и инфраструктура", "Развитие, дороги, поддержка бизнеса. Сильнее всего влияет на развитие региона (если у власти способный руководитель)."],
]
const FED_LV := ["Центр", "Совместно", "Регион", "Полная самостоятельность"]
# v35: что означает каждый уровень полномочий в каждой сфере
const FED_LV_DESC := [
	["налоги собирает и распределяет центр; регион живёт на трансферты", "часть налогов остаётся региону, ставки задаёт центр", "регион собирает свои налоги и сам решает, на что их тратить", "регион сам устанавливает налоги и лишь отчисляет взнос центру"],
	["единая национальная полиция и суды", "полиция подчиняется центру, но регион влияет на приоритеты", "своя региональная полиция, центр — только тяжкие преступления", "собственная полиция и суды низшего звена; центр почти не вмешивается"],
	["единые программы, язык и стандарты по всей стране", "центр задаёт стандарты, регион — часть программы и язык", "школы и вузы в ведении региона, свой язык обучения", "полностью своя система образования и культурная политика"],
	["больницы и пособия под управлением центра", "центр финансирует, регион управляет больницами", "регион ведёт здравоохранение и местные пособия", "своя система здравоохранения и соцзащиты"],
	["развитие и инфраструктуру планирует центр", "крупные проекты — центр, местные — регион", "регион сам строит дороги и поддерживает бизнес", "своя экономическая политика, инвестиции и господдержка"],
]
const FED_LVL_NAMES := ["Унитарное государство", "Децентрализованное государство", "Федерация"]
const FED_ST := ["Обычный", "Расширенная автономия", "Особый статус"]
const FED_EQ := ["нет", "слабое", "умеренное", "сильное"]
const FED_W := [0.5, 0.9, 0.9, 0.7, 0.6]       # вес сферы в лояльности
const FED_K := [0.8, 0.0, 0.4, 0.3, 1.5]       # вес сферы в развитии (с поправкой на умение главы)
const FED_SHOCK := 36                           # месяцев «притирки» присоединённой территории

var FED := {}
var fst := {}
var fed_u0 := {}        # индекс единицы мира -> исходная страна
var fed_w0 := {}        # страна -> исходный список регионов WORLD
var fed_ui := {}        # id единицы ("DE-BW") -> индекс
var fed_rng := RandomNumberGenerator.new()

# ============================================================
#  ДАННЫЕ И НАЧАЛО ИГРЫ
# ============================================================


func fed_cfg() -> Dictionary:
	if FED.has(ccode):
		return FED[ccode]
	return {"lvl": 0, "comp": [0, 0, 0, 0, 0], "eq": 1, "cede": 2, "need": 0.667, "refd": false, "seats": 0, "status": {}, "reg_comp": {}, "note": "", "spec": {}}


func fed_reset_world() -> void:
	ate_reset()
	for ui in fed_u0:
		WORLD_UNITS[int(ui)]["cc"] = String(fed_u0[ui])
	for cc in fed_w0:
		WORLD[cc]["regions"] = (fed_w0[cc] as Array).duplicate(true)
	fed_u0.clear()
	fed_w0.clear()
	fed_ui.clear()
	for ui in WORLD_UNITS.size():
		fed_ui[String(WORLD_UNITS[ui]["id"])] = ui


func fed_init() -> void:
	if FED.is_empty():
		var d = ext_load("res://data/fed.dat")
		FED = d if d != null else {}
	fed_reset_world()
	REGIONS = REGIONS.duplicate(true)
	UPPER = UPPER.duplicate(true)
	DIP_ORDER = DIP_ORDER.duplicate()
	var c := fed_cfg()
	fed_rng.seed = hash(ccode) + 17
	fst = {"lvl": int(c["lvl"]), "lvl0": int(c["lvl"]), "eq": int(c["eq"]), "eq0": int(c["eq"]), "demand": [], "terr_cd": {}, "cd": {}, "merged": [], "rel_x": {}, "acq": 0, "ceded": 0, "hist": []}
	for i in regions.size():
		fed_region_init(i)


func fed_region_init(i: int, terr: bool = false, status: int = -1) -> void:
	var c := fed_cfg()
	var code := String(REGIONS[i]["code"])
	var base: Array = (c["comp"] as Array).duplicate()
	if (c["reg_comp"] as Dictionary).has(code):
		base = ((c["reg_comp"] as Dictionary)[code] as Array).duplicate()
	var st: int = int((c["status"] as Dictionary).get(code, 0)) if status < 0 else status
	if terr:
		base = [0, 0, 0, 0, 0]
	var r: Dictionary = regions[i]
	r["comp"] = base.duplicate()
	r["cbase"] = base.duplicate()
	r["status"] = st
	r["status0"] = st
	r["terr"] = terr
	r["since"] = 999
	if not REGIONS[i].has("uid"):
		REGIONS[i]["uid"] = ccode + "-" + code


func fed_new_sub(i: int) -> void:
	# новый субъект получает типовой набор полномочий страны
	fed_region_init(i, false, 0)


# ============================================================
#  ВЛИЯНИЕ ПОЛНОМОЧИЙ (всё считается от стартового положения, поэтому в начале игры равно нулю)
# ============================================================


func fed_d(i: int, s: int) -> int:
	var r: Dictionary = regions[i]
	if not r.has("comp"):
		return 0
	return int(r["comp"][s]) - int(r["cbase"][s])


func fed_shock(i: int) -> float:
	return clampf(1.0 - float(regions[i].get("since", 999)) / float(FED_SHOCK), 0.0, 1.0)


func fed_loy_term(i: int) -> float:
	var r: Dictionary = regions[i]
	if not r.has("comp"):
		return 0.0
	var sepf: float = 0.5 + float(REGIONS[i].get("reg", 0.3))
	var t := 0.0
	for s in 5:
		t += float(fed_d(i, s)) * float(FED_W[s])
	t *= sepf * 1.2
	var dd: float = float(fst.get("eq", 0)) - float(fst.get("eq0", 0))
	if dd != 0.0:
		t += dd * 0.7 * (reg_avg("dev") - float(r["dev"])) / 25.0
	t += float(int(r["status"]) - int(r["status0"])) * 2.5 * sepf
	t -= fed_shock(i) * (9.0 if bool(r["terr"]) else 6.0)
	return t


func fed_unr_term(i: int) -> float:
	var r: Dictionary = regions[i]
	if not r.has("comp"):
		return 0.0
	var sepf: float = 0.5 + float(REGIONS[i].get("reg", 0.3))
	var t: float = -(float(fed_d(i, 1)) * 1.2 + float(fed_d(i, 2)) * 0.5 + float(fed_d(i, 0)) * 0.3) * sepf
	t += fed_shock(i) * (8.0 if bool(r["terr"]) else 5.0)
	return t


func fed_dev_term(i: int) -> float:
	var r: Dictionary = regions[i]
	if not r.has("comp"):
		return 0.0
	var gs: float = float(r["gov"]["skill"]) / 60.0
	var t := 0.0
	for s in 5:
		t += float(FED_K[s]) * float(fed_d(i, s))
	t *= (gs - 0.85) * 3.0
	var dd: float = float(fst.get("eq", 0)) - float(fst.get("eq0", 0))
	if dd != 0.0:
		t += dd * 0.3 * (reg_avg("dev") - float(r["dev"])) / 25.0
	if bool(r["terr"]):
		t -= 3.0 * fed_shock(i)
	return t


func fed_auto_term(i: int) -> float:
	var r: Dictionary = regions[i]
	if not r.has("comp"):
		return 0.0
	var t := 0.0
	for s in 5:
		t += float(fed_d(i, s)) * 1.5
	t += float(int(r["status"]) - int(r["status0"])) * 5.0
	return t


func fed_tax_leak() -> float:
	var t := 0.0
	for i in regions.size():
		if regions[i].has("comp"):
			t += gdp_w[i] * float(fed_d(i, 0)) * 0.01
	return t


func fed_max_level(i: int) -> int:
	var r: Dictionary = regions[i]
	if bool(r["terr"]):
		return 0
	return mini(3, 1 + int(fst["lvl"]) + (1 if int(r["status"]) >= 1 else 0))


# ============================================================
#  ВНУТРЕННИЕ ПРОЦЕДУРЫ: большинство коалиции, верхняя палата, референдум
# ============================================================


func fed_coal_share() -> float:
	var s := 0
	for p in seats.size():
		if in_coalition[p]:
			s += seats[p]
	return float(s) / float(maxi(1, SEATS))


func fed_dom(super_need: bool) -> Dictionary:
	var c := fed_cfg()
	var need: float = float(c["need"]) if super_need else 0.5
	var sh: float = fed_coal_share()
	return {"ok": (sh >= need) if super_need else (sh > 0.5), "share": sh, "need": need,
		"text": "Мест у коалиции: %.0f%% (нужно %s %.0f%%)" % [sh * 100.0, ("не менее" if super_need else "более"), need * 100.0]}


func fed_upper() -> Dictionary:
	var kind: String = String(UPPER.get("kind", "none"))
	if UPPER.is_empty() or kind == "none" or int(UPPER.get("total", 0)) <= 0 or kind == "veto":
		return {"on": false, "ok": true, "yes": 0, "need": 0, "name": "", "binding": false}
	var all_mode: bool = String(UPPER.get("mode", "")) == "all"
	var yes := 0
	for bl in UPPER["blocs"]:
		var ps: Array = bl[1]
		var n_ok := 0
		for p in ps:
			if int(p) == 0 or bool(in_coalition[int(p)]):
				n_ok += 1
		var good: bool = (n_ok == ps.size()) if all_mode else (n_ok * 2 >= ps.size())
		if good:
			yes += int(bl[0])
	var total: int = int(UPPER["total"])
	var need: int = total / 2 + 1
	var binding: bool = kind == "full" or kind == "consent"
	return {"on": true, "ok": yes >= need or not binding, "yes": yes, "need": need, "total": total, "name": String(UPPER["name"]), "binding": binding}


func fed_ref_p(bonus: float) -> float:
	return clampf(0.25 + (approval() - 35.0) / 100.0 + bonus, 0.05, 0.92)


func fed_roll(p: float, force: int) -> bool:
	if force > 0:
		return true
	if force < 0:
		return false
	return fed_rng.randf() < p


func fed_cd_get(k: String) -> int:
	return int((fst["cd"] as Dictionary).get(k, 0))


# ============================================================
#  ДЕЙСТВИЯ: полномочия, статус, выравнивание, тип государства
# ============================================================


func fed_cap_ok(cost: float) -> bool:
	if game_over:
		return false
	if capital < cost:
		log_line("[color=%s]Не хватает политического капитала (нужно %.0f).[/color]" % [COL_BAD, cost])
		return false
	return true


func fed_comp_cost(i: int, s: int, dir: int) -> float:
	var r: Dictionary = regions[i]
	var c := 4.0 + float(int(r["comp"][s]))
	if dir < 0:
		c += 3.0
	return c


func fed_comp_check(i: int, s: int, dir: int) -> String:
	# пустая строка — можно; иначе причина отказа
	var r: Dictionary = regions[i]
	var lv: int = int(r["comp"][s]) + dir
	if lv < 0:
		return "Полномочие уже полностью у центра."
	if lv > fed_max_level(i):
		return "Выше нельзя: рамки устройства государства и статуса (максимум «%s»)." % FED_LV[fed_max_level(i)]
	if fed_cd_get("c%d_%d" % [i, s]) > 0:
		return "Недавно менялось (ещё %d мес.)." % fed_cd_get("c%d_%d" % [i, s])
	if dir < 0 and int(fst["lvl"]) == 2:
		var up := fed_upper()
		if bool(up["on"]) and not bool(up["ok"]):
			return "%s не одобрит: у коалиции %d из %d голосов (нужно %d)." % [up["name"], up["yes"], up["total"], up["need"]]
	return ""


func fed_comp_step(i: int, s: int, dir: int) -> bool:
	var why := fed_comp_check(i, s, dir)
	var cost := fed_comp_cost(i, s, dir)
	if why != "":
		log_line("[color=%s]%s: %s[/color]" % [COL_BAD, REGIONS[i]["short"], why])
		return false
	if not fed_cap_ok(cost):
		return false
	capital -= cost
	var r: Dictionary = regions[i]
	r["comp"][s] = int(r["comp"][s]) + dir
	(fst["cd"] as Dictionary)["c%d_%d" % [i, s]] = 6
	var sepf: float = 0.5 + float(REGIONS[i].get("reg", 0.3))
	if dir > 0:
		r["loy"] = clampf(float(r["loy"]) + 2.5 * sepf, 0.0, 100.0)
		r["unrest"] = clampf(float(r["unrest"]) - 1.5 * sepf, 0.0, 100.0)
	else:
		r["loy"] = clampf(float(r["loy"]) - 4.0 * sepf, 0.0, 100.0)
		r["unrest"] = clampf(float(r["unrest"]) + 3.0 * sepf, 0.0, 100.0)
	log_line("%s: «%s» — %s: теперь «%s» (%s)." % [date_text(), REGIONS[i]["short"], FED_SPH[s][1], FED_LV[int(r["comp"][s])], "передача полномочий вниз" if dir > 0 else "централизация"])
	refresh()
	return true


func fed_comp_all(s: int, dir: int) -> int:
	# реформа сразу для всех субъектов: берутся только те, где это возможно; цена — 40% от суммы, но не меньше 8
	var idx: Array = []
	for i in regions.size():
		if fed_comp_check(i, s, dir) == "":
			idx.append(i)
	if idx.is_empty():
		log_line("[color=%s]Нигде нельзя изменить «%s» в эту сторону.[/color]" % [COL_BAD, FED_SPH[s][1]])
		return 0
	var cost := 0.0
	for i in idx:
		cost += fed_comp_cost(i, s, dir)
	cost = maxf(8.0, cost * 0.4)
	if not fed_cap_ok(cost):
		return 0
	capital -= cost
	for i in idx:
		var r: Dictionary = regions[i]
		r["comp"][s] = int(r["comp"][s]) + dir
		(fst["cd"] as Dictionary)["c%d_%d" % [i, s]] = 6
		var sepf: float = 0.5 + float(REGIONS[i].get("reg", 0.3))
		r["loy"] = clampf(float(r["loy"]) + (2.5 if dir > 0 else -4.0) * sepf, 0.0, 100.0)
		r["unrest"] = clampf(float(r["unrest"]) + (-1.5 if dir > 0 else 3.0) * sepf, 0.0, 100.0)
	log_line("[b]%s: реформа — «%s» %s у %d субъектов.[/b]" % [date_text(), FED_SPH[s][1], "передаётся регионам" if dir > 0 else "возвращается центру", idx.size()])
	refresh()
	return idx.size()


func fed_status_check(i: int, dir: int) -> String:
	var r: Dictionary = regions[i]
	if bool(r["terr"]):
		return "Федеральная территория не может иметь статуса — сначала примите её в состав как субъект."
	var st: int = int(r["status"]) + dir
	if st < 0 or st > 2:
		return "Статус уже крайний."
	if fed_cd_get("st%d" % i) > 0:
		return "Статус недавно менялся (ещё %d мес.)." % fed_cd_get("st%d" % i)
	var dm := fed_dom(dir > 0 and st == 2)
	if not bool(dm["ok"]):
		return "Нужно большинство в парламенте. " + String(dm["text"])
	if dir < 0 and int(fst["lvl"]) == 2:
		var up := fed_upper()
		if bool(up["on"]) and not bool(up["ok"]):
			return "%s блокирует: у коалиции %d из %d голосов." % [up["name"], up["yes"], up["total"]]
	return ""


func fed_status_step(i: int, dir: int) -> bool:
	var why := fed_status_check(i, dir)
	if why != "":
		log_line("[color=%s]%s: %s[/color]" % [COL_BAD, REGIONS[i]["short"], why])
		return false
	var cost := 14.0 if dir > 0 else 10.0
	if not fed_cap_ok(cost):
		return false
	capital -= cost
	var r: Dictionary = regions[i]
	r["status"] = int(r["status"]) + dir
	(fst["cd"] as Dictionary)["st%d" % i] = 24
	var sepf: float = 0.5 + float(REGIONS[i].get("reg", 0.3))
	if dir > 0:
		r["loy"] = clampf(float(r["loy"]) + 6.0 * sepf, 0.0, 100.0)
		r["unrest"] = clampf(float(r["unrest"]) - 4.0 * sepf, 0.0, 100.0)
		# особый статус открывает потолок полномочий: сразу даётся одна ступень в образовании
		if int(r["comp"][2]) < fed_max_level(i):
			r["comp"][2] = int(r["comp"][2]) + 1
	else:
		r["loy"] = clampf(float(r["loy"]) - 9.0 * sepf, 0.0, 100.0)
		r["unrest"] = clampf(float(r["unrest"]) + 6.0 * sepf, 0.0, 100.0)
		for s in 5:
			if int(r["comp"][s]) > fed_max_level(i):
				r["comp"][s] = fed_max_level(i)
	log_line("[b]%s: «%s» — статус «%s».[/b]" % [date_text(), REGIONS[i]["short"], FED_ST[int(r["status"])]])
	refresh()
	return true


func fed_set_eq(v: int) -> bool:
	v = clampi(v, 0, 3)
	if v == int(fst["eq"]) or fed_cd_get("eq") > 0:
		return false
	if not fed_cap_ok(6.0):
		return false
	capital -= 6.0
	fst["eq"] = v
	(fst["cd"] as Dictionary)["eq"] = 12
	log_line("[b]%s: бюджетное выравнивание между регионами — %s.[/b] Богатые регионы будут недовольны, бедные — довольны." % [date_text(), FED_EQ[v]])
	refresh()
	return true


func fed_reform_check(dir: int) -> String:
	var lv: int = int(fst["lvl"]) + dir
	if lv < 0 or lv > 2:
		return "Дальше менять устройство нельзя."
	if fed_cd_get("lvl") > 0:
		return "Реформа недавно проводилась (ещё %d мес.)." % fed_cd_get("lvl")
	var dm := fed_dom(true)
	if not bool(dm["ok"]):
		return "Это конституционная реформа. " + String(dm["text"])
	if dir < 0 and int(fst["lvl"]) == 2:
		var up := fed_upper()
		if bool(up["on"]) and not bool(up["ok"]):
			return "%s блокирует: у коалиции %d из %d голосов." % [up["name"], up["yes"], up["total"]]
	return ""


func fed_reform(dir: int, force: int = 0) -> bool:
	var why := fed_reform_check(dir)
	if why != "":
		log_line("[color=%s]%s[/color]" % [COL_BAD, why])
		return false
	if not fed_cap_ok(30.0):
		return false
	var c := fed_cfg()
	if bool(c["refd"]) and force == 0:
		var p := fed_ref_p(0.0)
		capital -= 30.0
		if not fed_roll(p, force):
			add_support("Бизнес", -2.0)
			log_line("[b]%s: референдум о смене устройства государства провален (шанс был %.0f%%).[/b]" % [date_text(), p * 100.0])
			(fst["cd"] as Dictionary)["lvl"] = 12
			return false
	else:
		capital -= 30.0
	fst["lvl"] = int(fst["lvl"]) + dir
	(fst["cd"] as Dictionary)["lvl"] = 36
	for i in regions.size():
		var r: Dictionary = regions[i]
		if bool(r["terr"]):
			continue
		for s in [2, 3, 4]:
			var lv: int = clampi(int(r["comp"][s]) + dir, 0, fed_max_level(i))
			r["comp"][s] = lv
		var sepf: float = 0.5 + float(REGIONS[i].get("reg", 0.3))
		r["loy"] = clampf(float(r["loy"]) + (5.0 if dir > 0 else -7.0) * sepf, 0.0, 100.0)
		for s in 5:
			if int(r["comp"][s]) > fed_max_level(i):
				r["comp"][s] = fed_max_level(i)
	if dir > 0 and (UPPER.is_empty() or String(UPPER.get("kind", "none")) == "none") and int(fst["lvl"]) == 2:
		fed_make_upper()
	log_line("[b]%s: конституционная реформа — теперь это «%s».[/b]" % [date_text(), FED_LVL_NAMES[int(fst["lvl"])].to_lower()])
	refresh()
	return true


func fed_party_for_bloc(i: int) -> Array:
	if float(regions[i]["loy"]) >= 52.0 or seats.size() < 2:
		return [0]
	var best := -1
	var bs := -1
	for p in seats.size():
		if p == 0 or in_coalition[p]:
			continue
		var sc: int = seats[p]
		if can_govern(p) and sc > bs:
			bs = sc
			best = p
	return [best] if best > 0 else [0]


func fed_make_upper() -> void:
	var blocs: Array = []
	var tot := 0
	for i in regions.size():
		if bool(regions[i]["terr"]):
			continue
		blocs.append([3, fed_party_for_bloc(i)])
		tot += 3
	UPPER = {"name": "Совет субъектов", "kind": "override", "total": tot, "mode": "all", "blocs": blocs, "fund_need": 0.667, "note": "Создан при федерализации"}


# ============================================================
#  ПРИЁМ НОВЫХ СУБЪЕКТОВ
# ============================================================


func fed_admit_check(i: int) -> String:
	var r: Dictionary = regions[i]
	if not bool(r["terr"]):
		return "Уже полноправный субъект."
	if int(r["since"]) < 12:
		return "Территория присоединена менее года назад (ещё %d мес.)." % (12 - int(r["since"]))
	if float(r["loy"]) < 48.0:
		return "Лояльность ниже 48 — население не готово."
	if float(r["unrest"]) > 40.0:
		return "Недовольство выше 40."
	var dm := fed_dom(false)
	if not bool(dm["ok"]):
		return "Нужно большинство в парламенте. " + String(dm["text"])
	var up := fed_upper()
	if bool(up["on"]) and not bool(up["ok"]):
		return "%s не даст согласия: у коалиции %d из %d голосов (нужно %d)." % [up["name"], up["yes"], up["total"], up["need"]]
	return ""


func fed_admit(i: int) -> bool:
	var why := fed_admit_check(i)
	if why != "":
		log_line("[color=%s]Приём «%s» невозможен: %s[/color]" % [COL_BAD, REGIONS[i]["short"], why])
		return false
	if not fed_cap_ok(10.0):
		return false
	capital -= 10.0
	fed_new_sub(i)
	regions[i]["since"] = 0
	var c := fed_cfg()
	var seats_n: int = int(c["seats"])
	if seats_n > 0 and not UPPER.is_empty() and String(UPPER.get("kind", "none")) != "none":
		(UPPER["blocs"] as Array).append([seats_n, fed_party_for_bloc(i)])
		UPPER["total"] = int(UPPER["total"]) + seats_n
	regions[i]["loy"] = clampf(float(regions[i]["loy"]) + 6.0, 0.0, 100.0)
	fst["acq"] = int(fst["acq"])
	log_line("[b]%s: «%s» принят в состав как полноправный субъект.[/b]%s" % [date_text(), REGIONS[i]["name"], (" Верхняя палата получает +%d голосов." % seats_n) if seats_n > 0 and String(UPPER.get("kind", "none")) != "none" else ""])
	refresh()
	return true


# ============================================================
#  ТРЕБОВАНИЯ РЕГИОНОВ (входящие обращения)
# ============================================================


func fed_month() -> void:
	for k in (fst["cd"] as Dictionary).keys():
		(fst["cd"] as Dictionary)[k] = int((fst["cd"] as Dictionary)[k]) - 1
		if int((fst["cd"] as Dictionary)[k]) <= 0:
			(fst["cd"] as Dictionary).erase(k)
	for k in (fst["rel_x"] as Dictionary).keys():
		(fst["rel_x"] as Dictionary)[k] = float((fst["rel_x"] as Dictionary)[k]) * 0.99
	for k in (fst["terr_cd"] as Dictionary).keys():
		(fst["terr_cd"] as Dictionary)[k] = int((fst["terr_cd"] as Dictionary)[k]) - 1
		if int((fst["terr_cd"] as Dictionary)[k]) <= 0:
			(fst["terr_cd"] as Dictionary).erase(k)
	for i in regions.size():
		if int(regions[i].get("since", 999)) < 999:
			regions[i]["since"] = int(regions[i]["since"]) + 1
	var evs: int = int(game_opts.get("fedev", 1))
	if evs == 0:
		return
	# уже поданные требования: через 6 месяцев без ответа — отказ
	var keep: Array = []
	for dm in fst["demand"]:
		dm["age"] = int(dm["age"]) + 1
		if int(dm["age"]) > 6:
			fed_demand_decide(dm, false, true)
		else:
			keep.append(dm)
	fst["demand"] = keep
	for i in regions.size():
		var r: Dictionary = regions[i]
		if bool(r["terr"]) or not r.has("comp") or int(r["status"]) >= 2:
			continue
		if float(r["unrest"]) < 42.0 or float(r["loy"]) > 46.0 or fed_cd_get("dem%d" % i) > 0 or fed_demand_of(i) >= 0:
			continue
		if fed_rng.randf() > 0.12 * (0.5 + float(REGIONS[i].get("reg", 0.3))):
			continue
		var d := {"uid": String(REGIONS[i]["uid"]), "age": 0, "kind": "", "s": -1}
		if int(r["status"]) == 0 and fed_rng.randf() < 0.4:
			d["kind"] = "status"
		else:
			var best := -1
			var bv := 99
			for s in 5:
				var lv: int = int(r["comp"][s])
				if lv < fed_max_level(i) and lv < bv and s != 1:
					bv = lv
					best = s
			if best < 0:
				continue
			d["kind"] = "comp"
			d["s"] = best
		(fst["demand"] as Array).append(d)
		(fst["cd"] as Dictionary)["dem%d" % i] = 12
		log_line("[b]%s: «%s» требует %s.[/b] Решите во вкладке «Федерация» (на ответ — 6 месяцев)." % [date_text(), REGIONS[i]["short"], fed_demand_text(d)])


func fed_idx_of_uid(uid: String) -> int:
	for i in REGIONS.size():
		if String(REGIONS[i].get("uid", "")) == uid:
			return i
	return -1


func fed_demand_of(i: int) -> int:
	var uid := String(REGIONS[i].get("uid", ""))
	for k in (fst["demand"] as Array).size():
		if String(fst["demand"][k]["uid"]) == uid:
			return k
	return -1


func fed_demand_text(d: Dictionary) -> String:
	if String(d["kind"]) == "status":
		return "расширенной автономии"
	return "передачи полномочий: «%s»" % FED_SPH[int(d["s"])][1].to_lower()


func fed_demand_decide(d: Dictionary, accept: bool, expired: bool = false) -> bool:
	var i := fed_idx_of_uid(String(d["uid"]))
	if i < 0:
		fst["demand"].erase(d)
		return false
	var r: Dictionary = regions[i]
	var sepf: float = 0.5 + float(REGIONS[i].get("reg", 0.3))
	if accept:
		var ok := false
		if String(d["kind"]) == "status":
			ok = fed_status_step(i, 1)
		else:
			ok = fed_comp_step(i, int(d["s"]), 1)
		if not ok:
			return false
		r["loy"] = clampf(float(r["loy"]) + 3.0 * sepf, 0.0, 100.0)
	else:
		r["loy"] = clampf(float(r["loy"]) - (4.0 if expired else 3.0) * sepf, 0.0, 100.0)
		r["unrest"] = clampf(float(r["unrest"]) + 4.0 * sepf, 0.0, 100.0)
		(fst["cd"] as Dictionary)["dem%d" % i] = 18
		log_line("%s: требование «%s» (%s) %s." % [date_text(), REGIONS[i]["short"], fed_demand_text(d), "оставлено без ответа" if expired else "отклонено"])
	if fst["demand"].has(d):
		fst["demand"].erase(d)
	refresh()
	return true


# ============================================================
#  ПЕРЕДАЧА ТЕРРИТОРИИ: общее
# ============================================================


func fed_world_cc(cc: String) -> Dictionary:
	return WORLD[cc]


func fed_wreg(cc: String, uid: String) -> Dictionary:
	for r in WORLD[cc]["regions"]:
		if String(r["id"]) == uid:
			return r
	return {}


func fed_wreg_gdp(cc: String, uid: String) -> float:
	var tot := 0.0
	var mine := 0.0
	for r in WORLD[cc]["regions"]:
		var g: float = float(r["popm"]) * float(r["pc"])
		tot += g
		if String(r["id"]) == uid:
			mine = g
	if tot <= 0.0:
		return 0.0
	return float(WORLD[cc]["gdp"]) * mine / tot


func fed_unit_is_capital(cc: String, ui: int) -> bool:
	# v36: столица — в АТЕ, принадлежащей этой единице карты
	return ate_unit_has_capital(cc, ui)


func fed_unit_cc(ui: int) -> String:
	return String(WORLD_UNITS[ui]["cc"])


func fed_set_unit_cc(ui: int, cc: String) -> void:
	if not fed_u0.has(ui):
		fed_u0[ui] = String(WORLD_UNITS[ui]["cc"])
	WORLD_UNITS[ui]["cc"] = cc


func fed_backup_world(cc: String) -> void:
	if not fed_w0.has(cc):
		fed_w0[cc] = (WORLD[cc]["regions"] as Array).duplicate(true)


func fed_adjacent_units() -> Array:
	# чужие единицы, граничащие с вашей территорией
	var out: Array = []
	for ui in WORLD_UNITS.size():
		if fed_unit_cc(ui) == ccode:
			continue
		for nb in WORLD_UNITS[ui]["nb"]:
			if fed_unit_cc(int(nb)) == ccode:
				out.append(ui)
				break
	return out


func fed_rel(cc: String) -> float:
	if dip.has(cc):
		return float(dip[cc]["rel"])
	return 45.0 + float((fst["rel_x"] as Dictionary).get(cc, 0.0))


func fed_court(cc: String) -> bool:
	# дипломатическая работа с соседом ради будущей сделки
	if fed_cd_get("court_" + cc) > 0:
		log_line("[color=%s]С этой страной недавно уже работали (ещё %d мес.).[/color]" % [COL_BAD, fed_cd_get("court_" + cc)])
		return false
	if not fed_cap_ok(8.0):
		return false
	capital -= 8.0
	(fst["cd"] as Dictionary)["court_" + cc] = 6
	if dip.has(cc):
		dip_change(cc, 6.0)
	else:
		(fst["rel_x"] as Dictionary)[cc] = minf(35.0, float((fst["rel_x"] as Dictionary).get(cc, 0.0)) + 8.0)
	log_line("%s: дипломатическая работа с «%s»: отношения улучшились (теперь %.0f)." % [date_text(), WORLD[cc]["name"], fed_rel(cc)])
	refresh()
	return true


func fed_pc_ratio(cc: String) -> float:
	# подушевой ВВП вашей страны к подушевому ВВП другой
	var a: float = gdp / maxf(1.0, total_pop())
	var b: float = float(WORLD[cc]["gdp"]) / maxf(0.1, float(WORLD[cc]["pop"]))
	return a / maxf(0.01, b)


func fed_avg_dict(key: String) -> Dictionary:
	# среднее (по населению) долей секторов ("sec") или групп избирателей ("mix")
	var out := {}
	var tw := 0.0
	for i in regions.size():
		var w: float = float(regions[i]["popm"])
		var src: Dictionary = REGIONS[i]["sec"] if key == "sec" else reg_mix[i]
		tw += w
		for k in src:
			out[k] = float(out.get(k, 0.0)) + float(src[k]) * w
	for k in out:
		out[k] = float(out[k]) / maxf(0.001, tw)
	return out


func fed_take_unit(ui: int, how: String, k0: float, status: int = 0) -> int:
	# переводит единицу мира в состав вашей страны; how: "subject" | "territory". Возвращает индекс нового региона. Пересборку делает вызывающий.
	var cc := fed_unit_cc(ui)
	var uid := String(WORLD_UNITS[ui]["id"])
	var wr := fed_wreg(cc, uid)
	var g_r := fed_wreg_gdp(cc, uid)
	var avg_sec := fed_avg_dict("sec")
	var avg_mix := fed_avg_dict("mix")
	var nd := {"code": String(wr["code"]), "uid": uid, "name": String(wr["name"]), "short": String(wr["short"]),
		"popm": float(wr["popm"]), "pc": 1.0, "dev": float(wr["dev"]), "loy": 40.0, "unrest": maxf(float(wr["unrest"]), 28.0),
		"auto": float(wr["auto"]), "reg": 0.6, "tr": 0.8, "sec": avg_sec, "infra": float(wr["infra"]), "edu": float(wr["edu"]),
		"health": float(wr["health"]), "env": float(wr["env"]), "mix": avg_mix, "desc": String(wr["desc"])}
	var r: Dictionary = (regions[0] as Dictionary).duplicate(true)
	for kk in ["loy", "unrest", "dev", "auto", "infra", "edu", "health", "env"]:
		r[kk] = float(nd[kk])
	r["transfer"] = 0.8 if how == "subject" else 0.5
	r["popm"] = float(nd["popm"])
	r["unemp"] = unemployment
	r["gov"] = new_governor(0)
	r["proj"] = {}
	r["built"] = {}
	r["bonus"] = {"dev": 0.0, "infra": 0.0, "edu": 0.0, "health": 0.0, "env": 0.0}
	r["smul"] = {"ind": 1.0, "agr": 1.0, "srv": 1.0, "res": 1.0}
	r["legacy"] = {"ind": 0.0, "agr": 0.0, "srv": 0.0, "res": 0.0}
	r["zones"] = []
	r["upk"] = 0.0
	r["rdebt"] = 40.0
	r["rcrisis"] = false
	r["migr"] = 0.0
	r["mbonus"] = 0.0
	r["grp_h"] = []
	REGIONS.append(nd)
	regions.append(r)
	reg_cd.append({})
	var mix := {}
	var tot := 0.0
	for g in GROUPS:
		mix[g] = float(avg_mix.get(g, 0.2))
		tot += float(mix[g])
	for g in GROUPS:
		mix[g] = float(mix[g]) / maxf(tot, 0.0001)
	reg_mix.append(mix)
	var bias: Array = []
	for p in PARTY_NAMES.size():
		bias.append(1.0)
	REG_BIAS.append(bias)
	var i: int = regions.size() - 1
	# подушевой показатель подбирается так, чтобы вклад региона в ВВП равнялся его реальному ВВП
	var unit: float = float(nd["popm"]) * (0.6 + 0.8 * float(r["dev"]) / 100.0) * sec_idx(i)
	nd["pc"] = g_r / maxf(0.001, k0 * unit)
	loy_off.append(0.0)
	unr_off.append(0.0)
	soc_init_region(i, cc, String(nd["code"]))
	fed_region_init(i, how == "territory", status)
	regions[i]["since"] = 0
	if status > 0:
		regions[i]["loy"] = float(regions[i]["loy"]) + 4.0
	gdp += g_r
	return i


func fed_rebuild_world_side(cc_from: String, uid: String) -> void:
	# убирает регион из списка WORLD страны-продавца и уменьшает её ВВП
	fed_backup_world(cc_from)
	var g_r := fed_wreg_gdp(cc_from, uid)
	var lst: Array = WORLD[cc_from]["regions"]
	for k in lst.size():
		if String(lst[k]["id"]) == uid:
			lst.remove_at(k)
			break
	if wsim.has(cc_from):
		wsim[cc_from]["gdp"] = maxf(1.0, float(wsim[cc_from]["gdp"]) - g_r)


func fed_rebuild() -> void:
	recalc_weights()
	build_geometry()
	var order: Array[int] = []
	for j in table_order:
		if int(j) < regions.size():
			order.append(int(j))
	for j in regions.size():
		if not (j in order):
			order.append(j)
	table_order = order
	if selected_region >= regions.size():
		selected_region = 0
	map_rebuild()
	ag_build()


func fed_calibrate_new(i: int) -> void:
	calibrate_region(i)


func fed_news_world(cc: String, text: String) -> void:
	log_line("[b]%s: %s[/b]" % [date_text(), text])


# ============================================================
#  ПОКУПКА РЕГИОНА ЧУЖОЙ СТРАНЫ
# ============================================================


func terr_price(cc: String, uid: String, mult: float) -> float:
	return fed_wreg_gdp(cc, uid) * 0.75 * mult


func terr_buy_quote(ui: int, mult: float, how: String = "subject") -> Dictionary:
	var u: Dictionary = WORLD_UNITS[ui]
	var cc := fed_unit_cc(ui)
	var uid := String(u["id"])
	var q := {"ok": true, "why": [], "ui": ui, "cc": cc, "uid": uid, "mult": mult, "how": how}
	var wr := fed_wreg(cc, uid)
	if cc == ccode or wr.is_empty():
		q["ok"] = false
		(q["why"] as Array).append("Это уже ваша территория.")
		return q
	var cf: Dictionary = FED.get(cc, {})
	var cede: int = int(cf.get("cede", 2))
	var g_r := fed_wreg_gdp(cc, uid)
	var price: float = terr_price(cc, uid, mult)
	var w: Dictionary = wsim[cc]
	var n_left: int = (WORLD[cc]["regions"] as Array).size() - 1
	var adj := false
	for nb in u["nb"]:
		if fed_unit_cc(int(nb)) == ccode:
			adj = true
	if not adj:
		q["ok"] = false
		(q["why"] as Array).append("Территория не граничит с вашей.")
	if cede == 0:
		q["ok"] = false
		(q["why"] as Array).append("Конституция страны «%s» не допускает отчуждения территории (возможно только объединение стран целиком)." % WORLD[cc]["name"])
	if fed_unit_is_capital(cc, ui):
		q["ok"] = false
		(q["why"] as Array).append("В этом регионе находится столица страны — она не продаётся.")
	if n_left < 2:
		q["ok"] = false
		(q["why"] as Array).append("У страны останется меньше двух регионов.")
	if int((fst["terr_cd"] as Dictionary).get(cc, 0)) > 0:
		q["ok"] = false
		(q["why"] as Array).append("Недавние переговоры с «%s» провалились (ещё %d мес.)." % [WORLD[cc]["name"], int((fst["terr_cd"] as Dictionary)[cc])])
	var dm := fed_dom(true)
	var dom_ok: bool = bool(dm["ok"])
	if not dom_ok:
		q["ok"] = false
		(q["why"] as Array).append("Присоединение требует конституционного большинства. " + String(dm["text"]))
	var up := fed_upper()
	var admit_blocked := false
	if how == "subject" and bool(up["on"]) and not bool(up["ok"]):
		admit_blocked = true
	var rel := fed_rel(cc)
	var p_gov: float = clampf(0.25 + (mult - 1.0) * 0.5 + (60.0 - float(w["stab"])) / 150.0 + (float(w["debt"]) - 60.0) / 400.0 + (rel - 50.0) / 200.0 - (g_r / maxf(1.0, float(WORLD[cc]["gdp"]))) * 0.8 - (0.05 if cede == 1 else 0.0), 0.02, 0.9)
	var p_loc: float = clampf(0.25 + (mult - 1.0) * 0.15 + (50.0 - float(wr["loy"])) / 150.0 + (fed_pc_ratio(cc) - 1.0) * 0.25, 0.05, 0.95)
	var c := fed_cfg()
	var gdp_pct: float = price / maxf(1.0, gdp) * 100.0
	var p_dom := 1.0
	if bool(c["refd"]):
		p_dom = fed_ref_p(-gdp_pct * 0.004)
	var cap: float = 12.0 + mult * 6.0
	q.merge({"price": price, "gdp_r": g_r, "p_gov": p_gov, "p_loc": p_loc, "p_dom": p_dom, "p": p_gov * p_loc * p_dom, "cap": cap, "pop": float(wr["popm"]),
		"name": String(wr["name"]), "country": String(WORLD[cc]["name"]), "admit_blocked": admit_blocked, "rel": rel, "need_dom": dm, "gdp_pct": gdp_pct}, true)
	if capital < cap:
		q["afford"] = false
	else:
		q["afford"] = true
	return q


func terr_buy(ui: int, mult: float, how: String = "subject", force: int = 0) -> Dictionary:
	var q := terr_buy_quote(ui, mult, how)
	if how == "subject" and bool(q.get("admit_blocked", false)):
		how = "territory"
		q["how"] = how
	if not bool(q["ok"]):
		return {"done": false, "msg": "; ".join(PackedStringArray(q["why"]))}
	if not fed_cap_ok(float(q["cap"])):
		return {"done": false, "msg": "Не хватает политического капитала."}
	capital -= float(q["cap"])
	var cc := String(q["cc"])
	var nm := String(q["name"])
	var res := {"done": false, "msg": ""}
	if not fed_roll(float(q["p_gov"]), force):
		(fst["terr_cd"] as Dictionary)[cc] = 12
		if dip.has(cc):
			dip_change(cc, -3.0)
		res["msg"] = "Правительство страны «%s» отказалось продавать «%s» (шанс был %.0f%%)." % [q["country"], nm, float(q["p_gov"]) * 100.0]
	elif not fed_roll(float(q["p_loc"]), force):
		(fst["terr_cd"] as Dictionary)[cc] = 12
		res["msg"] = "Власти согласились, но жители «%s» на референдуме отказались менять страну (шанс был %.0f%%)." % [nm, float(q["p_loc"]) * 100.0]
	elif not fed_roll(float(q["p_dom"]), force):
		(fst["terr_cd"] as Dictionary)[cc] = 6
		add_support("Рабочие", -2.0)
		res["msg"] = "Сделка заключена, но на вашем референдуме избиратели отвергли присоединение (шанс был %.0f%%)." % (float(q["p_dom"]) * 100.0)
	else:
		var k0: float = gdp / maxf(0.001, regional_potential())
		var old_auto := reg_avg("auto")
		debt += float(q["price"])
		var uid := String(q["uid"])
		var i := fed_take_unit(ui, how, k0)
		fed_rebuild_world_side(cc, uid)
		fed_set_unit_cc(ui, ccode)
		fst["acq"] = int(fst["acq"]) + 1
		recalc_weights()
		auto0 += reg_avg("auto") - old_auto
		fed_rebuild()
		fed_calibrate_new(i)
		if dip.has(cc):
			dip_change(cc, -2.0)
		res = {"done": true, "msg": "Регион «%s» куплен у страны «%s» за %.0f млрд (в долг) и %s." % [nm, q["country"], float(q["price"]), "принят как новый субъект" if how == "subject" else "присоединён как федеральная территория (приём в субъекты — позже)"], "idx": i}
	log_line("[b]%s: %s[/b]" % [date_text(), res["msg"]])
	refresh()
	return res


# ============================================================
#  ПРОДАЖА СВОЕГО РЕГИОНА
# ============================================================


func terr_sell_buyers(i: int) -> Array:
	var ui := fed_ui_of_region(i)
	var out: Array = []
	if ui < 0:
		return out
	for nb in WORLD_UNITS[ui]["nb"]:
		var cc := fed_unit_cc(int(nb))
		if cc != ccode and not (cc in out) and WORLD.has(cc) and wsim.has(cc):
			out.append(cc)
	return out


func fed_ui_of_region(i: int) -> int:
	return int(fed_ui.get(String(REGIONS[i].get("uid", "")), -1))


func terr_sell_quote(i: int, cc: String, mult: float) -> Dictionary:
	var q := {"ok": true, "why": [], "i": i, "cc": cc, "mult": mult}
	var ui := fed_ui_of_region(i)
	var r: Dictionary = regions[i]
	var c := fed_cfg()
	if regions.size() < 3:
		q["ok"] = false
		(q["why"] as Array).append("У страны должно остаться не меньше двух регионов.")
	if int(c["cede"]) == 0:
		q["ok"] = false
		(q["why"] as Array).append("Конституция вашей страны не допускает отчуждения территории.")
	if fed_unit_is_capital(ccode, ui):
		q["ok"] = false
		(q["why"] as Array).append("Это столичный регион.")
	var dm := fed_dom(true)
	if not bool(dm["ok"]):
		q["ok"] = false
		(q["why"] as Array).append("Нужно конституционное большинство. " + String(dm["text"]))
	var g_r: float = gdp * gdp_w[i]
	var price: float = g_r * 0.75 * mult
	var w: Dictionary = wsim[cc]
	var p_buy: float = clampf(0.55 - (mult - 1.0) * 0.1 + (float(w["stab"]) - 50.0) / 200.0 - (float(w["debt"]) - 80.0) / 300.0 - (g_r / maxf(1.0, float(w["gdp"]))) * 0.6, 0.05, 0.9)
	var p_loc: float = clampf(0.5 - (float(r["loy"]) - 50.0) / 80.0 + (mult - 1.0) * 0.1 - (float(r["auto"]) - 20.0) / 200.0, 0.03, 0.9)
	var p_dom := 1.0
	if bool(c["refd"]):
		p_dom = fed_ref_p(0.0)
	q.merge({"price": price, "gdp_r": g_r, "p_buy": p_buy, "p_loc": p_loc, "p_dom": p_dom, "p": p_buy * p_loc * p_dom, "cap": 14.0,
		"name": String(REGIONS[i]["name"]), "country": String(WORLD[cc]["name"]), "pop": float(r["popm"])}, true)
	return q


func terr_sell(i: int, cc: String, mult: float, force: int = 0) -> Dictionary:
	var q := terr_sell_quote(i, cc, mult)
	if not bool(q["ok"]):
		return {"done": false, "msg": "; ".join(PackedStringArray(q["why"]))}
	if not fed_cap_ok(float(q["cap"])):
		return {"done": false, "msg": "Не хватает политического капитала."}
	capital -= float(q["cap"])
	var nm := String(q["name"])
	var res := {"done": false, "msg": ""}
	if not fed_roll(float(q["p_buy"]), force):
		res["msg"] = "Страна «%s» отказалась покупать «%s» по такой цене." % [q["country"], nm]
	elif not fed_roll(float(q["p_loc"]), force):
		add_support("Бизнес", -1.0)
		res["msg"] = "Жители «%s» на референдуме отказались менять страну; сделка сорвана." % nm
	elif not fed_roll(float(q["p_dom"]), force):
		res["msg"] = "Избиратели отвергли продажу «%s» на вашем референдуме." % nm
	else:
		var ui := fed_ui_of_region(i)
		var uid := String(REGIONS[i]["uid"])
		var wr := {"id": uid, "code": String(REGIONS[i]["code"]), "name": nm, "short": String(REGIONS[i]["short"]), "popm": float(regions[i]["popm"]),
			"pc": float(REGIONS[i]["pc"]), "dev": float(regions[i]["dev"]), "unrest": float(regions[i]["unrest"]), "auto": float(regions[i]["auto"]),
			"infra": float(regions[i]["infra"]), "edu": float(regions[i]["edu"]), "health": float(regions[i]["health"]), "env": float(regions[i]["env"]),
			"loy": 50.0, "desc": String(REGIONS[i]["desc"]), "sh": []}
		var pn: Array = WORLD[cc]["pn"]
		for p in pn.size():
			(wr["sh"] as Array).append(1.0 / float(pn.size()))
		fed_backup_world(cc)
		var g_r := float(q["gdp_r"])
		(WORLD[cc]["regions"] as Array).append(wr)
		wsim[cc]["gdp"] = float(wsim[cc]["gdp"]) + g_r
		debt = maxf(0.0, debt - float(q["price"]))
		fed_set_unit_cc(ui, cc)
		var old_auto := reg_avg("auto")
		fed_drop_region(i)
		recalc_weights()
		auto0 += reg_avg("auto") - old_auto
		fst["ceded"] = int(fst["ceded"]) + 1
		gdp = maxf(1.0, gdp - g_r)
		fed_rebuild()
		res = {"done": true, "msg": "Регион «%s» продан стране «%s» за %.0f млрд (долг уменьшен)." % [nm, q["country"], float(q["price"])]}
		add_support("Рабочие", -2.0)
		add_support("Село", -1.0)
	log_line("[b]%s: %s[/b]" % [date_text(), res["msg"]])
	refresh()
	return res


func fed_drop_region(i: int) -> void:
	var uid := String(REGIONS[i].get("uid", ""))
	REGIONS.remove_at(i)
	regions.remove_at(i)
	reg_cd.remove_at(i)
	reg_mix.remove_at(i)
	if REG_BIAS.size() > i:
		REG_BIAS.remove_at(i)
	if loy_off.size() > i:
		loy_off.remove_at(i)
	if unr_off.size() > i:
		unr_off.remove_at(i)
	var no: Array[int] = []
	for j in table_order:
		if int(j) != i:
			no.append(int(j) - (1 if int(j) > i else 0))
	table_order = no
	var keep: Array = []
	for d in fst["demand"]:
		if String(d["uid"]) != uid:
			keep.append(d)
	fst["demand"] = keep
	# индексы в cd (по регионам) сдвигаются — проще очистить
	for k in (fst["cd"] as Dictionary).keys():
		if String(k).begins_with("c") or String(k).begins_with("st") or String(k).begins_with("dem"):
			(fst["cd"] as Dictionary).erase(k)
	if selected_region >= regions.size():
		selected_region = 0


# ============================================================
#  ДОБРОВОЛЬНОЕ ОБЪЕДИНЕНИЕ СТРАН
# ============================================================


func union_candidates() -> Array:
	var out: Array = []
	for ui in fed_adjacent_units():
		var cc := fed_unit_cc(ui)
		if not (cc in out) and wsim.has(cc):
			out.append(cc)
	return out


func union_quote(cc: String, terms: int) -> Dictionary:
	# terms: 0 — полное слияние (земли — обычные субъекты); 1 — союзный договор (расширенная автономия земель бывшей страны)
	var q := {"ok": true, "why": [], "cc": cc, "terms": terms}
	var w: Dictionary = wsim[cc]
	var d: Dictionary = WORLD[cc]
	var rel := fed_rel(cc)
	var dm := fed_dom(true)
	if not bool(dm["ok"]):
		q["ok"] = false
		(q["why"] as Array).append("Объединение — конституционное решение. " + String(dm["text"]))
	if rel < 60.0:
		q["ok"] = false
		(q["why"] as Array).append("Отношения с «%s» слишком холодные: %.0f (нужно не ниже 60)." % [d["name"], rel])
	if int((fst["terr_cd"] as Dictionary).get(cc, 0)) > 0:
		q["ok"] = false
		(q["why"] as Array).append("Недавний отказ «%s» (ещё %d мес.)." % [d["name"], int((fst["terr_cd"] as Dictionary)[cc])])
	var my_pop: float = total_pop()
	var share: float = float(d["pop"]) / maxf(1.0, my_pop)
	var p_x: float = clampf(0.08 + (rel - 60.0) / 120.0 + (fed_pc_ratio(cc) - 1.0) * 0.3 + (50.0 - float(w["stab"])) / 250.0 - share * 0.35 + (0.12 if terms == 1 else 0.0), 0.02, 0.9)
	var c := fed_cfg()
	var p_dom: float = fed_ref_p(share * 0.1) if bool(c["refd"]) else 1.0
	var take_debt: float = float(d["debt"]) * 0.8
	var n: int = (d["regions"] as Array).size()
	q.merge({"p_x": p_x, "p_dom": p_dom, "p": p_x * p_dom, "cap": 30.0 + 20.0 * share, "debt": take_debt, "n": n, "pop": float(d["pop"]), "gdp": float(d["gdp"]),
		"name": String(d["name"]), "rel": rel, "share": share}, true)
	return q


func union_do(cc: String, terms: int, force: int = 0) -> Dictionary:
	var q := union_quote(cc, terms)
	if not bool(q["ok"]):
		return {"done": false, "msg": "; ".join(PackedStringArray(q["why"]))}
	if not fed_cap_ok(float(q["cap"])):
		return {"done": false, "msg": "Не хватает политического капитала."}
	capital -= float(q["cap"])
	var nm := String(q["name"])
	var res := {"done": false, "msg": ""}
	if not fed_roll(float(q["p_x"]), force):
		(fst["terr_cd"] as Dictionary)[cc] = 24
		if dip.has(cc):
			dip_change(cc, -5.0)
		res["msg"] = "Жители страны «%s» на референдуме отвергли объединение (шанс был %.0f%%)." % [nm, float(q["p_x"]) * 100.0]
	elif not fed_roll(float(q["p_dom"]), force):
		(fst["terr_cd"] as Dictionary)[cc] = 12
		res["msg"] = "«%s» согласилась, но ваши избиратели отвергли объединение (шанс был %.0f%%)." % [nm, float(q["p_dom"]) * 100.0]
	else:
		var k0: float = gdp / maxf(0.001, regional_potential())
		var old_auto := reg_avg("auto")
		var units: Array = []
		for ui in WORLD_UNITS.size():
			if fed_unit_cc(ui) == cc:
				units.append(ui)
		fed_backup_world(cc)
		var pop_in := 0.0
		var first := regions.size()
		for ui in units:
			fed_take_unit(ui, "subject", k0, 1 if terms == 1 else 0)
			fed_set_unit_cc(ui, ccode)
		for i in range(first, regions.size()):
			pop_in += float(regions[i]["popm"])
		debt += float(q["debt"])
		WORLD[cc]["regions"] = []
		wsim.erase(cc)
		dip.erase(cc)
		DIP_ORDER.erase(cc)
		if dip_sel == cc:
			dip_sel = String(DIP_ORDER[0]) if not DIP_ORDER.is_empty() else ""
		(fst["merged"] as Array).append(cc)
		recalc_weights()
		auto0 += reg_avg("auto") - old_auto
		fed_rebuild()
		for i in range(first, regions.size()):
			fed_calibrate_new(i)
		# новые субъекты получают места в верхней палате, если она есть
		var seats_n: int = int(fed_cfg()["seats"])
		if seats_n > 0 and not UPPER.is_empty() and String(UPPER.get("kind", "none")) != "none":
			for i in range(first, regions.size()):
				(UPPER["blocs"] as Array).append([seats_n, fed_party_for_bloc(i)])
				UPPER["total"] = int(UPPER["total"]) + seats_n
		fst["acq"] = int(fst["acq"]) + units.size()
		add_support("Рабочие", 1.0)
		res = {"done": true, "msg": "Страна «%s» добровольно объединилась с вами: +%d субъектов, +%.1f млн жителей, принят долг %.0f млрд." % [nm, units.size(), pop_in, float(q["debt"])]}
	log_line("[b]%s: %s[/b]" % [date_text(), res["msg"]])
	refresh()
	return res


# ============================================================
#  ТЕКСТЫ ДЛЯ ИНТЕРФЕЙСА
# ============================================================


func fed_comp_text(i: int) -> String:
	var r: Dictionary = regions[i]
	var parts: PackedStringArray = []
	for s in 5:
		var d := fed_d(i, s)
		var col := COL_NEUTRAL if d == 0 else (COL_GOOD if d > 0 else COL_WARN)
		parts.append("%s — [color=%s]%s[/color]" % [FED_SPH[s][1], col, FED_LV[int(r["comp"][s])]])
	return "; ".join(parts)


func fed_region_line(i: int) -> String:
	var r: Dictionary = regions[i]
	if not r.has("comp"):
		return ""
	var t := "\n[color=%s]Статус:[/color] %s" % [COL_DIM, "федеральная территория (напрямую управляется центром)" if bool(r["terr"]) else FED_ST[int(r["status"])]]
	var spec: String = String((fed_cfg()["spec"] as Dictionary).get(String(REGIONS[i]["code"]), ""))
	if spec != "":
		t += " ([i]%s[/i])" % spec
	if int(r.get("since", 999)) < FED_SHOCK:
		t += "\n[color=%s]Недавно присоединён: притирка ещё %d мес.[/color]" % [COL_WARN, FED_SHOCK - int(r["since"])]
	t += "\n[color=%s]Полномочия:[/color] %s" % [COL_DIM, fed_comp_text(i)]
	return t


func fed_stats() -> Dictionary:
	var n_terr := 0
	var st1 := 0
	var st2 := 0
	for r in regions:
		if bool(r["terr"]):
			n_terr += 1
		elif int(r["status"]) == 1:
			st1 += 1
		elif int(r["status"]) == 2:
			st2 += 1
	return {"n": regions.size(), "terr": n_terr, "st1": st1, "st2": st2}
