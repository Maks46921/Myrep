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
	if not (regions[i]["proj"] as Dictionary).is_empty():
		return "в регионе уже идёт стройка"
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
	regions[i]["proj"] = {"id": id, "left": m, "months": m, "cost": c, "ate": -1, "upg": true}
	log_tag("ПРОЕКТ", COL_TEAL, "%s — «%s»: начато улучшение «%s» до уровня %d (%d мес., %.1f млрд)." % [
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
	con_corp_month()
	con_ai_month()


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
