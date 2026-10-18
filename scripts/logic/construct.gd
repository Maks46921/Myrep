# v55_1: сооружения второго поколения. Ещё 42 вида сооружений (культура, религия, образование, здравоохранение, энергетика,
# промышленность, оборона, госуправление; всего 63), уровни и улучшения, ремонт каждого сооружения, аварии изношенных,
# уникальный мегапроект каждой страны, стройка корпораций и ИИ-стран (настройка bldev).
# Эффекты новых сооружений: обычные поля проектов (reg, nat, k, bc, xg, pr, cpi) плюс
#   ind — самообеспеченность промышленными товарами {товар: доля}, rb — постоянные эффекты в регионе
#   (cut — снижает культурную напряжённость, pie — религиозность, chrel — отношения с церковью, relt — религиозную напряжённость,
#   order — недовольство), mil — армия (ad — ПВО, cap — сколько солдат содержит бюджет), grp — реакция групп при закладке.
extends "res://scripts/logic/econsys.gd"

const CS_LVL_MAX := 3
const CS_UPG_COST := 0.6      # улучшение: доля стоимости × текущий уровень
const CS_UPG_TIME := 0.6
const CS_PROJECTS := [
	# --- энергетика ---
	{"id": "hydro", "name": "Гидроэлектростанция", "cat": 0, "cost": 0.80, "months": 20, "up": 0.03,
		"reg": {"infra": 8.0, "dev": 4.0, "env": -3.0}, "nat": {"shock": 0.1}, "k": {"ene": 0.050}, "grp": {"Экологи": -0.8, "Бизнес": 0.4, "Село": -0.3},
		"desc": "Дешёвая и чистая энергия на десятилетия, но затапливает долину."},
	{"id": "geotherm", "name": "Геотермальная станция", "cat": 0, "cost": 0.45, "months": 12, "up": 0.04,
		"reg": {"infra": 4.0, "dev": 3.0, "env": 2.0}, "nat": {}, "k": {"ene": 0.020}, "grp": {"Экологи": 0.6, "Бизнес": 0.2},
		"desc": "Тепло недр: стабильная мощность без выбросов, но месторождения есть не везде."},
	{"id": "hydrogen", "name": "Водородный завод (электролиз)", "cat": 0, "cost": 0.60, "months": 16, "up": 0.05,
		"reg": {"dev": 5.0, "env": 2.0}, "nat": {"shock": 0.1}, "k": {"ene": 0.012, "ind": 0.010}, "ind": {"chem": 0.05, "fert": 0.06}, "bc": 1.0,
		"grp": {"Экологи": 0.8, "Бизнес": 0.4}, "desc": "Зелёный водород для химии, удобрений и стали."},
	{"id": "storage", "name": "Накопители энергии", "cat": 0, "cost": 0.30, "months": 8, "up": 0.04,
		"reg": {"infra": 5.0}, "nat": {}, "k": {"ene": 0.010}, "bc": 0.5, "grp": {"Экологи": 0.4, "Бизнес": 0.2},
		"desc": "Батареи и гидроаккумуляторы сглаживают перебои солнца и ветра."},
	# --- транспорт ---
	{"id": "airport", "name": "Аэропорт", "cat": 1, "cost": 0.50, "months": 14, "up": 0.05,
		"reg": {"dev": 6.0, "infra": 6.0, "env": -3.0}, "nat": {}, "k": {"srv": 0.010}, "xg": 0.005, "grp": {"Бизнес": 0.6, "Экологи": -0.6, "Молодёжь": 0.2},
		"desc": "Туристы и деловые поездки, но шум и выбросы."},
	{"id": "metro", "name": "Метро и городской транспорт", "cat": 1, "cost": 0.70, "months": 20, "up": 0.05,
		"reg": {"infra": 10.0, "loyalty": 3.0, "env": 3.0}, "nat": {}, "cpi": 0.003, "pr": 0.010, "grp": {"Молодёжь": 0.6, "Рабочие": 0.4, "Экологи": 0.4},
		"desc": "Быстрее дорога на работу, чище воздух в городе."},
	# --- промышленность ---
	{"id": "steelworks", "name": "Металлургический комбинат", "cat": 2, "cost": 0.70, "months": 16, "up": 0.05,
		"reg": {"dev": 9.0, "env": -7.0, "unrest": -2.0}, "nat": {"shock": 0.15}, "k": {"ind": 0.030}, "ind": {"steel": 0.15, "metals": 0.05},
		"grp": {"Рабочие": 0.9, "Экологи": -1.2}, "desc": "Своя сталь для машин, стройки и армии."},
	{"id": "petrochem", "name": "Нефтехимический комбинат", "cat": 2, "cost": 0.70, "months": 16, "up": 0.05,
		"reg": {"dev": 8.0, "env": -6.0}, "nat": {"shock": 0.15}, "k": {"ind": 0.025}, "ind": {"chem": 0.15}, "xg": 0.005,
		"grp": {"Рабочие": 0.5, "Бизнес": 0.4, "Экологи": -1.0}, "desc": "Пластмассы, химия и топливо из своего сырья."},
	{"id": "shipyard", "name": "Судоверфь", "cat": 2, "cost": 0.55, "months": 14, "up": 0.05,
		"reg": {"dev": 7.0, "unrest": -2.0}, "nat": {}, "k": {"ind": 0.020}, "ind": {"arms_ships": 0.20, "machinery": 0.03}, "xg": 0.006,
		"grp": {"Рабочие": 0.8, "Силовики": 0.3}, "desc": "Торговые суда на экспорт и корабли для флота."},
	{"id": "pharma", "name": "Фармацевтический завод", "cat": 2, "cost": 0.45, "months": 12, "up": 0.05,
		"reg": {"dev": 6.0, "health": 3.0, "edu": 2.0}, "nat": {}, "k": {"ind": 0.015}, "ind": {"chem": 0.03}, "pr": 0.005,
		"grp": {"Пенсионеры": 0.4, "Бизнес": 0.4}, "desc": "Свои лекарства: меньше зависимость от импорта."},
	{"id": "chipfab", "name": "Завод микросхем", "cat": 2, "cost": 1.20, "months": 30, "up": 0.06,
		"reg": {"dev": 10.0, "edu": 5.0, "env": -2.0}, "nat": {"shock": 0.2}, "k": {"ind": 0.020}, "ind": {"chips": 0.20}, "bc": 1.5, "pr": 0.020,
		"grp": {"Бизнес": 0.6, "Молодёжь": 0.5}, "desc": "Очень дорого, но даёт стране собственные чипы."},
	{"id": "machtool", "name": "Станкостроительный завод", "cat": 2, "cost": 0.50, "months": 14, "up": 0.05,
		"reg": {"dev": 7.0, "edu": 2.0}, "nat": {}, "k": {"ind": 0.020}, "ind": {"machinery": 0.15}, "grp": {"Рабочие": 0.6, "Бизнес": 0.3},
		"desc": "Оборудование для своих заводов вместо импортного."},
	{"id": "fertplant", "name": "Завод удобрений", "cat": 2, "cost": 0.40, "months": 12, "up": 0.05,
		"reg": {"dev": 5.0, "env": -4.0}, "nat": {}, "k": {"ind": 0.010, "agr": 0.008}, "ind": {"fert": 0.20}, "grp": {"Село": 0.6, "Экологи": -0.6},
		"desc": "Удобрения для своих полей: урожаи выше, хлеб дешевле."},
	{"id": "carplant", "name": "Автозавод", "cat": 2, "cost": 0.80, "months": 18, "up": 0.05,
		"reg": {"dev": 10.0, "unrest": -3.0, "env": -2.0}, "nat": {"shock": 0.2}, "k": {"ind": 0.040}, "ind": {"machinery": 0.02}, "xg": 0.008,
		"grp": {"Рабочие": 1.0, "Бизнес": 0.5}, "desc": "Тысячи рабочих мест и экспорт машин."},
	{"id": "oilfield", "name": "Нефтегазовый промысел", "cat": 2, "cost": 0.60, "months": 14, "up": 0.06,
		"reg": {"dev": 6.0, "env": -8.0}, "nat": {"shock": 0.1}, "k": {"res": 0.040}, "ind": {"oil": 0.15, "natgas": 0.15},
		"grp": {"Рабочие": 0.5, "Бизнес": 0.4, "Экологи": -1.6}, "desc": "Своя нефть и газ: меньше импорта, больше доходов."},
	# --- сельское хозяйство ---
	{"id": "foodplant", "name": "Пищевой комбинат", "cat": 3, "cost": 0.25, "months": 8, "up": 0.04,
		"reg": {"dev": 5.0, "unrest": -1.0}, "nat": {}, "k": {"agr": 0.020}, "cpi": 0.002, "grp": {"Село": 0.6, "Рабочие": 0.3},
		"desc": "Переработка урожая дома: хлеб, мясо и молочка дешевле."},
	{"id": "winery", "name": "Винодельни и пивоварни", "cat": 3, "cost": 0.20, "months": 8, "up": 0.04,
		"reg": {"dev": 3.0, "loyalty": 1.0}, "nat": {}, "k": {"agr": 0.010}, "xg": 0.003, "grp": {"Село": 0.5, "Бизнес": 0.3},
		"desc": "Местные напитки на экспорт и для туристов."},
	{"id": "fishery", "name": "Рыбный порт и фермы", "cat": 3, "cost": 0.25, "months": 8, "up": 0.04,
		"reg": {"dev": 4.0, "env": -1.0}, "nat": {}, "k": {"agr": 0.015}, "grp": {"Село": 0.4, "Рабочие": 0.3},
		"desc": "Улов и аквакультура: больше рыбы на столе и на экспорт."},
	{"id": "livestock", "name": "Животноводческий комплекс", "cat": 3, "cost": 0.30, "months": 10, "up": 0.04,
		"reg": {"dev": 5.0, "env": -3.0}, "nat": {}, "k": {"agr": 0.025}, "grp": {"Село": 0.8, "Экологи": -0.5},
		"desc": "Мясо и молоко своего производства."},
	# --- культура ---
	{"id": "theatre", "name": "Театр и концертный зал", "cat": 8, "cost": 0.15, "months": 10, "up": 0.06,
		"reg": {"loyalty": 3.0, "edu": 2.0}, "nat": {}, "rb": {"cut": 3.0}, "grp": {"Молодёжь": 0.3, "Бюджетники": 0.3, "Пенсионеры": 0.2},
		"desc": "Культурная жизнь города, общий праздник для всех народов региона."},
	{"id": "museum", "name": "Музей и центр наследия", "cat": 8, "cost": 0.12, "months": 8, "up": 0.05,
		"reg": {"loyalty": 2.0, "edu": 2.0, "dev": 1.0}, "nat": {}, "k": {"srv": 0.003}, "rb": {"cut": 2.0}, "grp": {"Пенсионеры": 0.3, "Бюджетники": 0.2},
		"desc": "История края и туристы."},
	{"id": "library", "name": "Библиотека и культурный центр", "cat": 8, "cost": 0.08, "months": 6, "up": 0.05,
		"reg": {"edu": 3.0, "loyalty": 2.0}, "nat": {}, "rb": {"cut": 2.0}, "grp": {"Бюджетники": 0.3, "Пенсионеры": 0.2},
		"desc": "Книги, курсы языка, кружки для детей и мигрантов."},
	{"id": "mincult", "name": "Дом культуры меньшинств", "cat": 8, "cost": 0.08, "months": 6, "up": 0.05,
		"reg": {"loyalty": 2.0}, "nat": {}, "rb": {"cut": 6.0}, "grp": {"Молодёжь": 0.2, "Силовики": -0.3},
		"desc": "Язык, песни и праздники меньшинств: заметно снижает культурную напряжённость, если меньшинства в регионе есть."},
	{"id": "stadium", "name": "Стадион и спорткомплекс", "cat": 8, "cost": 0.25, "months": 12, "up": 0.05,
		"reg": {"loyalty": 3.0, "health": 3.0, "unrest": -2.0}, "nat": {}, "k": {"srv": 0.003}, "grp": {"Молодёжь": 0.6, "Рабочие": 0.3},
		"desc": "Спорт и большие матчи."},
	# --- религия ---
	{"id": "cathedral", "name": "Собор главной церкви", "cat": 9, "cost": 0.15, "months": 14, "up": 0.03,
		"reg": {"loyalty": 2.0}, "nat": {}, "rb": {"pie": 3.0, "chrel": 3.0}, "grp": {"Пенсионеры": 0.5, "Село": 0.4, "Молодёжь": -0.2},
		"desc": "Верующие и церковь довольны; религиозность в регионе держится дольше."},
	{"id": "mosque", "name": "Мечеть и исламский центр", "cat": 9, "cost": 0.08, "months": 10, "up": 0.03,
		"reg": {"loyalty": 1.0}, "nat": {}, "rb": {"relt": 4.0, "order": 0.5}, "grp": {"Молодёжь": 0.2, "Силовики": -0.3, "Село": -0.2},
		"desc": "Свой центр для мусульманской общины: меньше напряжённости и радикальных проповедников."},
	{"id": "monastery", "name": "Монастырь", "cat": 9, "cost": 0.06, "months": 10, "up": 0.03,
		"reg": {"env": 1.0}, "nat": {}, "k": {"srv": 0.002}, "rb": {"pie": 2.0, "chrel": 2.0}, "grp": {"Пенсионеры": 0.4, "Село": 0.3},
		"desc": "Паломники, ремёсла и тишина."},
	{"id": "interfaith", "name": "Межрелигиозный центр", "cat": 9, "cost": 0.06, "months": 6, "up": 0.04,
		"reg": {"loyalty": 1.0}, "nat": {}, "rb": {"relt": 5.0, "cut": 1.0}, "grp": {"Молодёжь": 0.3},
		"desc": "Площадка для диалога общин: меньше столкновений на религиозной почве."},
	# --- образование ---
	{"id": "school", "name": "Новые школы", "cat": 10, "cost": 0.12, "months": 6, "up": 0.06,
		"reg": {"edu": 8.0, "loyalty": 2.0}, "nat": {}, "pr": 0.006, "grp": {"Бюджетники": 0.4, "Молодёжь": 0.3},
		"desc": "Классы без второй смены, лучшие учителя."},
	{"id": "kinder", "name": "Детские сады", "cat": 10, "cost": 0.08, "months": 5, "up": 0.06,
		"reg": {"loyalty": 3.0, "edu": 2.0}, "nat": {}, "grp": {"Молодёжь": 0.5, "Рабочие": 0.3},
		"desc": "Родители могут работать: семьи довольны."},
	{"id": "college", "name": "Колледж и профобучение", "cat": 10, "cost": 0.12, "months": 8, "up": 0.05,
		"reg": {"edu": 5.0, "unrest": -2.0}, "nat": {}, "pr": 0.008, "k": {"ind": 0.004}, "grp": {"Молодёжь": 0.4, "Рабочие": 0.3, "Бизнес": 0.2},
		"desc": "Рабочие профессии, которых не хватает заводам."},
	# --- здравоохранение ---
	{"id": "clinic", "name": "Поликлиники", "cat": 11, "cost": 0.10, "months": 5, "up": 0.06,
		"reg": {"health": 8.0, "loyalty": 2.0}, "nat": {}, "grp": {"Пенсионеры": 0.6, "Бюджетники": 0.2},
		"desc": "Врач рядом с домом, меньше очередей."},
	{"id": "sanatorium", "name": "Санаторий и курорт", "cat": 11, "cost": 0.15, "months": 8, "up": 0.05,
		"reg": {"health": 4.0, "dev": 3.0}, "nat": {}, "k": {"srv": 0.004}, "grp": {"Пенсионеры": 0.5},
		"desc": "Лечение и отдых, туристы из других стран."},
	{"id": "medcenter", "name": "Медицинский центр высоких технологий", "cat": 11, "cost": 0.40, "months": 14, "up": 0.06,
		"reg": {"health": 12.0, "edu": 3.0}, "nat": {"state": {"health_lvl": 1.0}}, "pr": 0.010, "bc": 0.5, "grp": {"Пенсионеры": 0.5, "Бюджетники": 0.3},
		"desc": "Сложные операции дома, а не за границей."},
	# --- оборона ---
	{"id": "milbase", "name": "Военная база", "cat": 12, "cost": 0.35, "months": 12, "up": 0.06,
		"reg": {"dev": 3.0, "unrest": -1.0}, "nat": {"state": {"security_lvl": 1.0}}, "rb": {"order": 1.0}, "mil": {"cap": 0.03},
		"grp": {"Силовики": 0.8, "Экологи": -0.3, "Молодёжь": -0.2}, "desc": "Казармы, склады и полигоны: армия больше и ближе к границе."},
	{"id": "airdef", "name": "Комплекс ПВО", "cat": 12, "cost": 0.40, "months": 12, "up": 0.06,
		"reg": {}, "nat": {"state": {"security_lvl": 1.0}}, "mil": {"ad": 0.08}, "grp": {"Силовики": 0.6},
		"desc": "Защита неба от ракет и дронов."},
	{"id": "defplant", "name": "Оборонный завод", "cat": 12, "cost": 0.50, "months": 14, "up": 0.05,
		"reg": {"dev": 6.0, "unrest": -2.0}, "nat": {}, "k": {"ind": 0.015}, "ind": {"arms_small": 0.15, "arms_armor": 0.10},
		"grp": {"Силовики": 0.6, "Рабочие": 0.4, "Экологи": -0.4}, "desc": "Свои боеприпасы и бронетехника; излишки — на экспорт."},
	{"id": "droneplant", "name": "Завод беспилотников", "cat": 12, "cost": 0.30, "months": 10, "up": 0.05,
		"reg": {"dev": 4.0, "edu": 1.0}, "nat": {}, "ind": {"arms_drones": 0.30, "chips": 0.02}, "grp": {"Силовики": 0.5, "Молодёжь": 0.2},
		"desc": "Дроны для армии и на экспорт."},
	# --- госуправление и порядок ---
	{"id": "court", "name": "Суд и прокуратура", "cat": 13, "cost": 0.08, "months": 6, "up": 0.06,
		"reg": {"loyalty": 1.0}, "nat": {"state": {"corruption": -1.0}}, "rb": {"order": 2.0}, "bc": 0.3, "grp": {"Бизнес": 0.3},
		"desc": "Быстрее суды, меньше коррупции."},
	{"id": "police", "name": "Полицейский центр", "cat": 13, "cost": 0.08, "months": 5, "up": 0.06,
		"reg": {"loyalty": 1.0}, "nat": {"state": {"security_lvl": 0.5}}, "rb": {"order": 3.0}, "grp": {"Силовики": 0.4, "Молодёжь": -0.2},
		"desc": "Меньше преступности и беспорядков."},
	{"id": "prison", "name": "Современная тюрьма", "cat": 13, "cost": 0.10, "months": 8, "up": 0.07,
		"reg": {"unrest": -1.0}, "nat": {}, "rb": {"order": 2.0}, "grp": {"Силовики": 0.3, "Молодёжь": -0.2},
		"desc": "Порядок и исправление вместо переполненных камер."},
	{"id": "govcenter", "name": "Центр госуслуг", "cat": 13, "cost": 0.10, "months": 6, "up": 0.05,
		"reg": {"loyalty": 4.0}, "nat": {}, "rb": {"order": 1.0}, "bc": 0.5, "grp": {"Бизнес": 0.3, "Пенсионеры": 0.2},
		"desc": "Все справки в одном окне: люди и бизнес меньше раздражены."},
]
# что строят корпорации своего рынка (выбор по id компании)
const CS_CORP_MAP := {"agr": ["agro", "foodplant", "winery", "livestock", "fishery"], "res": ["mine", "oilfield"],
	"ind": ["factory", "carplant", "steelworks", "petrochem", "pharma", "machtool", "chipfab", "fertplant"], "ene": ["power_gas", "solar_wind", "hydro", "storage"],
	"con": ["housing"], "srv": ["telecom", "techpark", "airport", "sanatorium"]}

var cs := {}
var cs_rng := RandomNumberGenerator.new()


func con_dyn() -> bool:
	return int(game_opts.get("bldev", 1)) == 1


func con_init() -> void:
	cs_rng.seed = hash(ccode) + 257
	con_projects()
	cs = {"rb": [], "ind": {}, "mil": {}, "cq": [], "ai": {}, "log": [], "mega": 0}
	for i in regions.size():
		cs["rb"].append({})
	con_struct_extra()


# новые сооружения и мегапроект страны добавляются к общему списку (повторно не дублируются)
func con_projects() -> void:
	var have := {}
	for k in range(PROJECTS.size() - 1, -1, -1):
		if bool(PROJECTS[k].get("mega", false)):
			PROJECTS.remove_at(k)
	for pd in PROJECTS:
		have[pd["id"]] = true
	for pd in CS_PROJECTS:
		if not have.has(pd["id"]):
			PROJECTS.append((pd as Dictionary).duplicate(true))
	var mg := con_mega_def(ccode)
	if not mg.is_empty():
		PROJECTS.append(mg)


func con_mega_def(cc: String) -> Dictionary:
	var c: Dictionary = cu_cfg(cc)
	var m: Dictionary = c.get("mega", {})
	if m.is_empty():
		return {}
	var nat: Dictionary = (m.get("nat", {}) as Dictionary).duplicate(true)
	var pd := {"id": String(m["id"]), "name": String(m["name"]), "cat": int(m["cat"]), "cost": float(m["cost"]), "months": int(m["months"]), "up": 0.015,
		"reg": (m.get("reg", {}) as Dictionary).duplicate(), "nat": nat, "k": (m.get("k", {}) as Dictionary).duplicate(), "ind": (m.get("ind", {}) as Dictionary).duplicate(),
		"desc": String(m["desc"]), "mega": true, "fixed": true, "region": String(m["region"])}
	for k in ["bc", "xg", "pr"]:
		if m.has(k):
			pd[k] = float(m[k])
	return pd


func con_mega() -> Dictionary:
	for pd in PROJECTS:
		if bool(pd.get("mega", false)):
			return pd
	return {}


func con_mega_region() -> int:
	var m := con_mega()
	if m.is_empty():
		return -1
	for i in regions.size():
		if String(REGIONS[i]["code"]) == String(m["region"]):
			return i
	return -1


# ---------------- уровни, ремонт, аварии ----------------


func con_lvl(i: int, id: String) -> int:
	var bt: Dictionary = regions[i]["built"]
	return int((bt[id] as Dictionary).get("lvl", 1)) if bt.has(id) else 0


func con_upgrade_cost(i: int, id: String) -> float:
	var pd := find_by_id(PROJECTS, id)
	if pd.is_empty():
		return 0.0
	return project_cost_pct(i, pd) * CS_UPG_COST * float(con_lvl(i, id))


func con_upgrade_check(i: int, id: String) -> String:
	if game_over:
		return "игра окончена"
	if opp_mode:
		return "стройкой распоряжается правительство"
	if i < 0 or i >= regions.size():
		return "выберите регион"
	var pd := find_by_id(PROJECTS, id)
	if pd.is_empty() or bool(pd.get("mega", false)):
		return "это сооружение не улучшается"
	var lv := con_lvl(i, id)
	if lv <= 0:
		return "в регионе нет такого сооружения"
	if lv >= CS_LVL_MAX:
		return "уже наивысший уровень"
	if bq_has(i, id):
		return "улучшение уже в очереди"
	return ""


func con_upgrade_start(i: int, id: String) -> String:
	if pl_deny():
		return "нельзя"
	var why := con_upgrade_check(i, id)
	if why != "":
		return why
	var pd := find_by_id(PROJECTS, id)
	var m: int = maxi(3, int(round(float(pd["months"]) * CS_UPG_TIME)))
	var c := con_upgrade_cost(i, id)
	bq_add(id, i, -1, gdp * c / 100.0, m, true)
	log_tag("ПРОЕКТ", COL_TEAL, "%s — «%s»: улучшение «%s» до уровня %d поставлено в очередь строек (не меньше %d мес., %.1f млрд)." % [
		date_text(), REGIONS[i]["name"], pd["name"], con_lvl(i, id) + 1, m, gdp * c / 100.0])
	refresh()
	return ""


func con_upgrade_done(i: int, id: String) -> void:
	var bt: Dictionary = regions[i]["built"]
	if not bt.has(id):
		return
	var e: Dictionary = bt[id]
	e["lvl"] = mini(CS_LVL_MAX, int(e.get("lvl", 1)) + 1)
	e["cond"] = 100.0
	var pd := find_by_id(PROJECTS, id)
	# улучшение даёт региону ещё половину стартового эффекта
	var half := {}
	for k in (pd.get("reg", {}) as Dictionary):
		half[k] = float(pd["reg"][k]) * 0.5
	apply_reg_delta(i, half, true)
	struct_step(false)
	log_tag("ПРОЕКТ", COL_GOOD, "«%s» в регионе «%s» улучшен до уровня %d." % [pd.get("name", id), REGIONS[i]["name"], int(e["lvl"])])


func con_repair_cost(i: int, id: String) -> float:
	var bt: Dictionary = regions[i]["built"]
	if not bt.has(id):
		return 0.0
	var e: Dictionary = bt[id]
	var pd := find_by_id(PROJECTS, id)
	if pd.is_empty():
		return 0.0
	return project_cost_pct(i, pd) * float(e["n"]) * (100.0 - float(e["cond"])) / 100.0 * 0.45 * struct_lvl_k(e)


func con_repair(i: int, id: String) -> bool:
	if pl_deny() or game_over or ec.is_empty():
		return false
	var c := con_repair_cost(i, id)
	if c < 0.0005:
		return false
	debt += gdp * c / 100.0
	regions[i]["built"][id]["cond"] = 100.0
	var pd := find_by_id(PROJECTS, id)
	log_tag("РЕМОНТ", COL_TEAL, "%s — отремонтировано «%s» в регионе «%s», %.2f млрд добавлено к долгу." % [date_text(), pd.get("name", id), REGIONS[i]["name"], gdp * c / 100.0])
	struct_step(false)
	refresh()
	return true


# сводные эффекты новых полей сооружений (вызывается из struct_step)
func con_struct_extra() -> void:
	if cs.is_empty():
		return
	var ind_s := {}
	var mil_s := {}
	var rbs: Array = []
	for i in regions.size():
		var rb := {}
		var bt: Dictionary = regions[i]["built"]
		for id in bt:
			var e: Dictionary = bt[id]
			var n: int = int(e["n"])
			if n <= 0:
				continue
			var pd := find_by_id(PROJECTS, id)
			if pd.is_empty():
				continue
			var f: float = struct_cond_factor(float(e["cond"])) * float(n) * struct_lvl_k(e)
			for k in (pd.get("ind", {}) as Dictionary):
				ind_s[k] = float(ind_s.get(k, 0.0)) + float(pd["ind"][k]) * f
			for k in (pd.get("mil", {}) as Dictionary):
				mil_s[k] = float(mil_s.get(k, 0.0)) + float(pd["mil"][k]) * f
			for k in (pd.get("rb", {}) as Dictionary):
				rb[k] = float(rb.get(k, 0.0)) + float(pd["rb"][k]) * f
		rbs.append(rb)
	cs["ind"] = ind_s
	cs["mil"] = mil_s
	cs["rb"] = rbs


func con_rb(i: int, k: String) -> float:
	if cs.is_empty() or i < 0 or i >= (cs["rb"] as Array).size():
		return 0.0
	return float((cs["rb"][i] as Dictionary).get(k, 0.0))


func con_rb_nat(k: String) -> float:
	var s := 0.0
	for i in regions.size():
		s += con_rb(i, k)
	return s


func con_ind(id: String) -> float:
	if cs.is_empty():
		return 0.0
	return minf(1.5, float((cs["ind"] as Dictionary).get(id, 0.0)))


func con_mil(k: String) -> float:
	if cs.is_empty():
		return 0.0
	return minf(0.6, float((cs["mil"] as Dictionary).get(k, 0.0)))


func con_unr_term(i: int) -> float:
	if cs.is_empty():
		return 0.0
	var t: float = -0.8 * minf(8.0, con_rb(i, "order"))
	t -= minf(10.0, con_rb(i, "relt")) * minf(1.0, float(regions[i].get("relt", 0.0)) / 25.0)
	return t


# проверка перед закладкой (мегапроект — только в своём регионе и один раз)
func con_start_check(i: int, pd: Dictionary) -> String:
	if not bool(pd.get("mega", false)):
		return ""
	if String(REGIONS[i]["code"]) != String(pd.get("region", "")):
		var mr := con_mega_region()
		return "мегапроект строится только в регионе «%s»" % (String(REGIONS[mr]["name"]) if mr >= 0 else String(pd.get("region", "")))
	if struct_total(String(pd["id"])) > 0:
		return "мегапроект уже построен"
	return ""


func con_mega_done(i: int, id: String) -> void:
	var pd := find_by_id(PROJECTS, id)
	if not bool(pd.get("mega", false)):
		return
	cs["mega"] = 2
	log_tag("МЕГАПРОЕКТ", COL_GOOD, "[b]%s — завершён мегапроект «%s»![/b] %s" % [date_text(), pd["name"], pd.get("desc", "")])
	for k in (pd.get("ind", {}) as Dictionary):
		ind_add_boost(String(k), float(pd["ind"][k]))
	add_support("Пенсионеры", 0.5)
	add_support("Бизнес", 1.0)


# ---------------- ежемесячно: аварии, корпорации, ИИ-страны ----------------


func con_month() -> void:
	if cs.is_empty():
		return
	if not con_dyn():
		return
	con_accidents()
	con_ai_month()   # 0.56: стройки корпораций — в очереди частных инвесторов (bq_priv_spawn)


func con_accidents() -> void:
	if not current_event.is_empty() or election_open:
		return
	if cs_rng.randf() > 0.5:
		return
	var worst := -1
	var wid := ""
	var wc := 30.0
	for i in regions.size():
		var bt: Dictionary = regions[i]["built"]
		for id in bt:
			if float(bt[id]["cond"]) < wc and int(bt[id]["n"]) > 0:
				wc = float(bt[id]["cond"])
				worst = i
				wid = String(id)
	if worst < 0 or cs_rng.randf() > 0.04 * (30.0 - wc) / 30.0 + 0.01:
		return
	var pd := find_by_id(PROJECTS, wid)
	var rc := con_repair_cost(worst, wid)
	var ev := {"t": "Авария на изношенном сооружении «%s» в регионе «{r}»: остановка работы, пострадавшие, жители требуют наказать виновных." % pd.get("name", wid), "o": [
		{"l": "Срочный ремонт (долг +%.2f%% ВВП)" % (rc * 1.3), "fx": {"debt": rc * 1.3, "support": {"Рабочие": 0.5}, "con": {"fix": wid}}},
		{"l": "Закрыть сооружение", "fx": {"reg": {"loyalty": -3.0, "unrest": 3.0}, "con": {"close": wid}}},
		{"l": "Отремонтировать позже", "fx": {"reg": {"unrest": 5.0, "loyalty": -2.0}, "support": {"Рабочие": -1.0, "Пенсионеры": -0.5}}}]}
	ev["kind"] = "build"
	soc_push_event(ev, worst)


func con_fx(d: Dictionary) -> void:
	var i := event_region
	if i < 0 or i >= regions.size():
		return
	var bt: Dictionary = regions[i]["built"]
	if d.has("fix") and bt.has(d["fix"]):
		bt[d["fix"]]["cond"] = 100.0
	if d.has("close") and bt.has(d["close"]):
		var e: Dictionary = bt[d["close"]]
		e["n"] = int(e["n"]) - 1
		if int(e["n"]) <= 0:
			bt.erase(d["close"])
	struct_step(false)


func con_corp_month() -> void:
	# стройки корпораций идут без бюджета; по завершении — сооружение в регионе
	var q: Array = cs["cq"]
	for k in range(q.size() - 1, -1, -1):
		var it: Dictionary = q[k]
		it["left"] = int(it["left"]) - 1
		if int(it["left"]) > 0:
			continue
		q.remove_at(k)
		var i: int = int(it["i"])
		if i >= regions.size():
			continue
		var pd := find_by_id(PROJECTS, String(it["id"]))
		if pd.is_empty():
			continue
		complete_struct(i, String(pd["id"]), region_main_ate(i))
		var half := {}
		for rk in (pd.get("reg", {}) as Dictionary):
			half[rk] = float(pd["reg"][rk]) * 0.7
		apply_reg_delta(i, half, true)
		con_log("«%s» построила «%s» в регионе «%s» на свои деньги." % [String(it["corp"]), pd["name"], REGIONS[i]["name"]])
	if corp.is_empty() or q.size() >= 4:
		return
	for c in corp["list"]:
		if float(c["att"]) < 50.0 or int(c["st"]) >= 100 and String(es.get("cls", "")) == "planned":
			continue
		var p: float = 0.006 * clampf(float(c["rev"]) / 40.0, 0.3, 2.5) * (float(c["att"]) / 60.0)
		if cs_rng.randf() > p:
			continue
		var opts: Array = CS_CORP_MAP.get(String(c["mk"]), ["factory"])
		var pid: String = String(opts[absi(hash(String(c["id"]) + str(year))) % opts.size()])
		var pd := find_by_id(PROJECTS, pid)
		if pd.is_empty():
			continue
		# регион: чаще богатые и крупные
		var r: float = cs_rng.randf()
		var ri := 0
		for i in regions.size():
			r -= gdp_w[i] if i < gdp_w.size() else 0.0
			if r <= 0.0:
				ri = i
				break
		q.append({"id": pid, "i": ri, "left": int(pd["months"]), "corp": corp_name(c)})
		con_log("«%s» начала строить «%s» в регионе «%s» (%d мес.)." % [corp_name(c), pd["name"], REGIONS[ri]["name"], int(pd["months"])])
		if q.size() >= 4:
			break


func con_log(txt: String) -> void:
	(cs["log"] as Array).append("%s: %s" % [date_text(), txt])
	if (cs["log"] as Array).size() > 30:
		(cs["log"] as Array).pop_front()
	log_tag("СТРОЙКА", COL_TEAL, txt)


# ИИ-страны тоже строят: обычные сооружения (немного ускоряют рост) и свой мегапроект
func con_ai_month() -> void:
	var ai: Dictionary = cs["ai"]
	for c in wsim:
		if c == ccode:
			continue
		if not ai.has(c):
			ai[c] = {"n": 0, "q": [], "mega": 0, "ml": 0}
		var a: Dictionary = ai[c]
		var w: Dictionary = wsim[c]
		var qq: Array = a["q"]
		for k in range(qq.size() - 1, -1, -1):
			qq[k] = int(qq[k]) - 1
			if int(qq[k]) <= 0:
				qq.remove_at(k)
				a["n"] = int(a["n"]) + 1
		var room: float = clampf((100.0 - float(w.get("debt", 60.0))) / 60.0, 0.1, 1.3)
		if qq.size() < 3 and cs_rng.randf() < 0.05 * room:
			qq.append(8 + cs_rng.randi() % 10)
		if int(a["mega"]) == 0 and turn >= 6 and cs_rng.randf() < 0.006 * room:
			var md := con_mega_def(String(c))
			if not md.is_empty():
				a["mega"] = 1
				a["ml"] = int(md["months"])
				con_log_world("«%s» начала мегапроект «%s»." % [String(WORLD[c]["name"]) if WORLD.has(c) else c, md["name"]])
		elif int(a["mega"]) == 1:
			a["ml"] = int(a["ml"]) - 1
			if int(a["ml"]) <= 0:
				a["mega"] = 2
				var md2 := con_mega_def(String(c))
				con_log_world("«%s» завершила мегапроект «%s»." % [String(WORLD[c]["name"]) if WORLD.has(c) else c, md2.get("name", "")])


func con_log_world(txt: String) -> void:
	(cs["log"] as Array).append("%s: %s" % [date_text(), txt])
	if (cs["log"] as Array).size() > 30:
		(cs["log"] as Array).pop_front()
	log_tag("МИР", COL_NEUTRAL, txt)


func con_ai_g(c: String) -> float:
	if cs.is_empty() or not (cs["ai"] as Dictionary).has(c):
		return 0.0
	var a: Dictionary = cs["ai"][c]
	return minf(0.35, 0.006 * float(a["n"])) + (0.12 if int(a["mega"]) == 2 else 0.0)


func con_ai_rows() -> Array:
	var out: Array = []
	if cs.is_empty():
		return out
	for c in cs["ai"]:
		var a: Dictionary = cs["ai"][c]
		var md := con_mega_def(String(c))
		out.append([String(c), int(a["n"]), (a["q"] as Array).size(), int(a["mega"]), int(a["ml"]), String(md.get("name", ""))])
	out.sort_custom(func(x, y): return int(x[1]) > int(y[1]))
	return out


# ============================================================
#  0.56 (п.6): ОЧЕРЕДЬ СТРОЕК КАК В VICTORIA 3
#  Государство строит из линии бюджета «Строительство» (bld_budget, % ВВП в год): деньги и мощности отрасли
#  делятся по очереди сверху вниз, у каждой стройки — полоса прогресса. Частные инвесторы строят на свои деньги
#  то, что окупается; игрок привлекает их налоговыми льготами. Мощность стройотрасли общая для всех.
#  Автостроительство министерств — годовой план, из которого можно вычёркивать пункты.
# ============================================================
const BQ_BRK_SHARE := 0.2      # льгота: государство возвращает инвестору 20% затрат
const BQ_PRIV_MAX := 6
# министерство, которое ведёт стройку категории (для плана автостроительства)
const BQ_CAT_MIN := [5, 8, 5, 6, 9, 4, 8, 7, 4, 10, 4, 3, 1, 0]


func bld_budget_init() -> void:
	if bld_budget < 0.0:
		bld_budget = clampf(0.3 * float(pol_def.get("infra", 3.0)), 0.5, 1.8)


func bld_budget_ok() -> float:
	bld_budget_init()
	return bld_budget0 if bld_budget0 >= 0.0 else bld_budget


func bld_set(v: float) -> void:
	bld_budget_init()
	v = clampf(snappedf(v, 0.01), 0.0, 6.0)
	if bud_draft_on():
		if bld_budget0 < 0.0:
			bld_budget0 = bld_budget
		bld_budget = v
		if absf(bld_budget - bld_budget0) < 0.001:
			bld_budget0 = -1.0
		bud_persuaded.clear()
	else:
		bld_budget = v


func bld_money_month() -> float:
	return gdp * bld_budget_ok() / 100.0 / 12.0


# мощность стройотрасли, млрд в месяц: растёт вместе с рынком «Строительство» (жилые кварталы его расширяют)
func bld_cap_month() -> float:
	var kf := 1.0
	if not ec.is_empty() and (ec["mk"] as Dictionary).has("con"):
		var mk: Dictionary = ec["mk"]["con"]
		kf = clampf(float(mk["K"]) * float(mk_def("con").get("u0", 0.9)), 0.6, 2.5)
	return gdp * (1.6 + bld_budget_ok()) * kf / 100.0 / 12.0


func bq_find(uid: int) -> int:
	for k in bq.size():
		if int(bq[k]["uid"]) == uid:
			return k
	return -1


func bq_in_region(i: int) -> Dictionary:
	for it in bq:
		if int(it["i"]) == i:
			return it
	return {}


func bq_has(i: int, id: String) -> bool:
	for it in bq:
		if int(it["i"]) == i and String(it["id"]) == id:
			return true
	return false


func bq_rate(it: Dictionary) -> float:
	return float(it["cost"]) / maxf(1.0, float(it["months"]))


func bq_add(pid: String, i: int, ate: int, cost_bn: float, months: int, upg: bool = false, auto: bool = false) -> Dictionary:
	bq_uid += 1
	var it := {"uid": bq_uid, "id": pid, "i": i, "ate": ate, "cost": cost_bn, "done": 0.0, "months": months, "upg": upg, "auto": auto, "start": turn, "got": 0.0}
	bq.append(it)
	return it


# распределение денег и мощностей: сначала госочередь по порядку, остаток мощностей — частным
func bq_alloc(apply: bool) -> Dictionary:
	var money := bld_money_month()
	var cap := bld_cap_month()
	var st := 0.0
	for it in bq:
		var need: float = minf(bq_rate(it), float(it["cost"]) - float(it["done"]))
		var use: float = clampf(minf(need, minf(money - st, cap - st)), 0.0, need)
		if apply:
			it["done"] = float(it["done"]) + use
			it["got"] = use
		st += use
	var pv := 0.0
	var brk := 0.0
	for it in bq_priv:
		var need2: float = minf(bq_rate(it), float(it["cost"]) - float(it["done"]))
		var use2: float = clampf(minf(need2, cap - st - pv), 0.0, need2)
		if apply:
			it["done"] = float(it["done"]) + use2
			it["got"] = use2
		pv += use2
		if bool(it.get("brk", false)):
			brk += use2 * BQ_BRK_SHARE
	return {"state": st, "priv": pv, "brk": brk, "money": money, "cap": cap}


# сколько месяцев осталось при нынешнем темпе (−1 — стоит, денег или мощностей нет)
func bq_eta(it: Dictionary) -> int:
	var g: float = float(it.get("got", 0.0))
	var left: float = float(it["cost"]) - float(it["done"])
	if left <= 0.001:
		return 0
	if g <= 0.0001:
		return -1
	return int(ceil(left / g))


func bq_move(uid: int, d: int) -> void:
	var k := bq_find(uid)
	if k < 0:
		return
	var j: int = clampi(k + d, 0, bq.size() - 1) if d > -100 else 0
	if j == k:
		return
	var it: Dictionary = bq[k]
	bq.remove_at(k)
	bq.insert(j, it)
	refresh()


func bq_cancel(uid: int) -> void:
	if pl_deny():
		return
	var k := bq_find(uid)
	if k < 0:
		return
	var it: Dictionary = bq[k]
	bq.remove_at(k)
	var pd := find_by_id(PROJECTS, String(it["id"]))
	var i: int = int(it["i"])
	if float(it["done"]) > 0.0:
		apply_reg_delta(i, {"loyalty": -3.0, "unrest": 3.0})
	log_line("[color=%s]%s: стройка «%s» в регионе «%s» остановлена%s.[/color]" % [COL_BAD, date_text(), pd.get("name", it["id"]), REGIONS[i]["name"],
		" — потрачено %.1f млрд, жители недовольны" % float(it["done"]) if float(it["done"]) > 0.0 else ""])
	refresh()


# старые сохранения: стройка в регионе и очередь корпораций переходят в новую очередь
func bq_migrate() -> void:
	for i in regions.size():
		var pr: Dictionary = regions[i]["proj"]
		if pr.is_empty():
			continue
		var pd := find_by_id(PROJECTS, String(pr["id"]))
		var cost: float = gdp * float(pr.get("cost", 0.3)) / 100.0
		var m: int = maxi(1, int(pr.get("months", pd.get("months", 6))))
		var it := bq_add(String(pr["id"]), i, int(pr.get("ate", -1)), cost, m, bool(pr.get("upg", false)))
		it["done"] = cost * clampf(1.0 - float(pr.get("left", m)) / float(m), 0.0, 1.0)
		regions[i]["proj"] = {}
	if not cs.is_empty() and cs.has("cq"):
		for c in (cs["cq"] as Array):
			var pd2 := find_by_id(PROJECTS, String(c["id"]))
			if pd2.is_empty():
				continue
			var m2: int = maxi(1, int(pd2["months"]))
			var cost2: float = gdp * project_cost_pct(clampi(int(c["i"]), 0, regions.size() - 1), pd2) / 100.0
			bq_uid += 1
			bq_priv.append({"uid": bq_uid, "id": String(c["id"]), "i": int(c["i"]), "cost": cost2, "done": cost2 * clampf(1.0 - float(c["left"]) / float(m2), 0.0, 0.99),
				"months": m2, "corp": String(c["corp"]), "brk": false, "got": 0.0})
		(cs["cq"] as Array).clear()


func bq_month() -> void:
	bld_budget_init()
	bq_migrate()
	var a := bq_alloc(true)
	bq_spent = float(a["state"])
	bq_priv_spent = float(a["priv"])
	bq_brk_spent = float(a["brk"])
	for k in range(bq.size() - 1, -1, -1):
		var it: Dictionary = bq[k]
		if float(it["done"]) >= float(it["cost"]) - 0.0001:
			bq.remove_at(k)
			complete_project_pr(int(it["i"]), it)
	for k in range(bq_priv.size() - 1, -1, -1):
		var it2: Dictionary = bq_priv[k]
		if float(it2["done"]) >= float(it2["cost"]) - 0.0001:
			bq_priv.remove_at(k)
			bq_priv_done(it2)
	if con_dyn():
		bq_priv_spawn()
	if bool(ap.get("build", false)) and not opp_mode:
		bld_plan_step()


func bq_priv_done(it: Dictionary) -> void:
	var i: int = int(it["i"])
	if i >= regions.size():
		return
	var pd := find_by_id(PROJECTS, String(it["id"]))
	if pd.is_empty():
		return
	complete_struct(i, String(pd["id"]), region_main_ate(i))
	var half := {}
	for rk in (pd.get("reg", {}) as Dictionary):
		half[rk] = float(pd["reg"][rk]) * 0.7
	apply_reg_delta(i, half, true)
	con_log("«%s» построила «%s» в регионе «%s» на свои деньги%s." % [String(it["corp"]), pd["name"], REGIONS[i]["name"], " (с налоговой льготой)" if bool(it.get("brk", false)) else ""])


# общественные сооружения: частный инвестор их не строит
const BQ_PUBLIC := ["road", "grid", "eco", "granary", "museum", "monastery", "stadium", "college", "storage"]


# окупаемость сооружения для инвестора, лет (99 — не коммерческое)
func bld_payback(pid: String, with_brk: bool = true) -> float:
	var pd := find_by_id(PROJECTS, pid)
	var k: Dictionary = pd.get("k", {})
	if pd.is_empty() or k.is_empty() or ec.is_empty() or bool(pd.get("mega", false)) or BQ_PUBLIC.has(pid):
		return 99.0
	var cost: float = float(pd["cost"]) * (0.6 + 4.5 / float(maxi(1, regions.size())))
	var prof := 0.0
	for m in k:
		if not (ec["mk"] as Dictionary).has(m):
			continue
		var mk: Dictionary = ec["mk"][m]
		var sell: float = clampf((float(mk["u"]) - 0.6) / 0.35, 0.1, 1.2) + float(mk["short"]) * 3.0
		# доля рынка в ВВП под корнем: большие рынки (услуги) не дают мгновенной окупаемости, малые (энергия) не безнадёжны
		prof += 30.0 * sqrt(float(mk_def(String(m)).get("w", 0.05))) * float(k[m]) * (float(mk.get("margin", 0.12)) + 0.15) * sell
	if prof <= 0.00001:
		return 99.0
	# 6 лет — стройка, запуск и выход на мощность; дальше — сама окупаемость
	var yrs: float = 6.0 + 1.2 * cost / prof
	if with_brk and bld_breaks.has(pid):
		yrs *= 1.0 - BQ_BRK_SHARE * 1.25
	return clampf(yrs, 3.0, 99.0)


# список выгодных строек: [окупаемость, pid], лучшие сверху
func bld_profitable() -> Array:
	var out: Array = []
	for pd in PROJECTS:
		var y := bld_payback(String(pd["id"]))
		if y < 40.0:
			out.append([y, String(pd["id"])])
	out.sort_custom(func(a, b) -> bool: return float(a[0]) < float(b[0]))
	return out


# частные инвесторы решают по выгоде: чем быстрее окупается, тем охотнее строят
func bq_priv_spawn() -> void:
	if corp.is_empty() or bq_priv.size() >= BQ_PRIV_MAX:
		return
	for c in corp["list"]:
		if float(c["att"]) < 45.0 or int(c["st"]) >= 100 and String(es.get("cls", "")) == "planned":
			continue
		var opts: Array = CS_CORP_MAP.get(String(c["mk"]), ["factory"])
		var best := ""
		var by := 99.0
		for pid in opts:
			if find_by_id(PROJECTS, String(pid)).is_empty():
				continue
			var y := bld_payback(String(pid))
			if y < by:
				by = y
				best = String(pid)
		if best == "" or by > 12.0:
			continue
		var p: float = 0.012 * clampf(float(c["rev"]) / 40.0, 0.3, 2.5) * (float(c["att"]) / 60.0) * clampf((12.0 - by) / 6.0, 0.1, 1.5)
		if cs_rng.randf() > p:
			continue
		var pd := find_by_id(PROJECTS, best)
		var r: float = cs_rng.randf()
		var ri := 0
		for i in regions.size():
			r -= gdp_w[i] if i < gdp_w.size() else 0.0
			if r <= 0.0:
				ri = i
				break
		var cost: float = gdp * project_cost_pct(ri, pd) / 100.0
		bq_uid += 1
		bq_priv.append({"uid": bq_uid, "id": best, "i": ri, "cost": cost, "done": 0.0, "months": int(pd["months"]), "corp": corp_name(c), "brk": bld_breaks.has(best), "got": 0.0})
		con_log("«%s» начала строить «%s» в регионе «%s»: окупится примерно за %.0f г." % [corp_name(c), pd["name"], REGIONS[ri]["name"], by])
		if bq_priv.size() >= BQ_PRIV_MAX:
			break


func bld_toggle_break(pid: String) -> void:
	if pl_deny():
		return
	if bld_breaks.has(pid):
		bld_breaks.erase(pid)
	else:
		bld_breaks[pid] = true
	refresh()


# ---------- автостроительство министерств: годовой план ----------
func bld_plan_make() -> void:
	bld_plan.clear()
	var budget_y: float = bld_money_month() * 12.0
	var plan_cost := 0.0
	for it in bq:
		plan_cost += float(it["cost"]) - float(it["done"])
	var cands: Array = []
	if not ec.is_empty():
		for m in (ec["mk"] as Dictionary):
			var mk: Dictionary = ec["mk"][m]
			var u: float = float(mk["u"]) + float(mk["short"]) * 3.0
			if u >= 0.93 and AP_BUILD_MAP.has(m):
				cands.append([u, String(AP_BUILD_MAP[m]), "спрос на рынке «%s»" % String(mk_def(String(m))["name"]).to_lower()])
	# слабые регионы: больница, университет, жильё, дороги
	var order: Array = []
	for i in regions.size():
		order.append([float(regions[i]["dev"]), i])
	order.sort_custom(func(a, b) -> bool: return float(a[0]) < float(b[0]))
	var soc := ["hospital", "university", "housing", "road"]
	for k in mini(4, order.size()):
		cands.append([0.9 - 0.05 * float(k), String(soc[k % soc.size()]), "отстающий регион", int(order[k][1])])
	for c in cands:
		var pid: String = String(c[1])
		var pd := find_by_id(PROJECTS, pid)
		if pd.is_empty():
			continue
		var ri: int = int(c[3]) if c.size() > 3 else int(order[0][1]) if order.size() > 0 else 0
		if c.size() <= 3:
			# рыночная стройка — в самом развитом регионе без такой стройки
			var bd := -1.0
			for i in regions.size():
				if not bq_has(i, pid) and float(regions[i]["dev"]) > bd:
					bd = float(regions[i]["dev"])
					ri = i
		var cost: float = gdp * project_cost_pct(ri, pd) / 100.0
		if plan_cost + cost > budget_y * 1.3:
			continue
		plan_cost += cost
		bld_plan.append({"id": pid, "i": ri, "why": String(c[2]), "off": false, "done": false, "min": int(BQ_CAT_MIN[int(pd["cat"])]) if int(pd["cat"]) < BQ_CAT_MIN.size() else 8})
		if bld_plan.size() >= 6:
			break
	bld_plan_year = year


func bld_plan_step() -> void:
	if bld_plan_year != year or (month == 1 and bld_plan.is_empty()):
		bld_plan_make()
		if not bld_plan.is_empty():
			log_tag("СТРОЙКА", COL_TEAL, "министерства составили план строек на %d год: %d объектов. Лишнее можно вычеркнуть в окне «Строительство»." % [year, bld_plan.size()])
	# новая стройка из плана — когда госочереди не хватает работы
	var a := bq_alloc(false)
	if float(a["state"]) >= float(a["money"]) * 0.85:
		return
	for pl in bld_plan:
		if bool(pl["off"]) or bool(pl["done"]):
			continue
		pl["done"] = true
		var why := project_start_at(int(pl["i"]), String(pl["id"]), -1, true)
		if why == "":
			return


func bld_plan_toggle(k: int) -> void:
	if k < 0 or k >= bld_plan.size():
		return
	bld_plan[k]["off"] = not bool(bld_plan[k]["off"])
	refresh()
