# 0.56 (доп. 3 и 4): недемократические режимы, часть вторая.
# Страх и пропаганда действуют вдвое сильнее (AU2) — но стоят денег каждый месяц. Новые опоры и язвы режима:
# тайная полиция и осведомители, государственные СМИ с охватом по регионам, дефицит и чёрный рынок, эмиграция
# и утечка умов, молодёжные и массовые организации, преемник и возраст правителя, иностранные покровители,
# обход санкций, политзаключённые как показатель, постановочные выборы с явкой по разнарядке.
# И «одноразовые решения» новой власти: конструктор, где галочками собирается пакет и подписывается разом.
extends "res://scripts/logic/fpai.gd"

const AU2_ACTS := [
	["pol_up", "Расширить тайную полицию и осведомителей", 6.0, 3, "", "Страх +8, подполье слабеет, силовики довольны. Но растут расходы, элиты боятся доносов, а рост и молодёжь страдают."],
	["pol_dn", "Сократить тайную полицию", 0.0, 6, "", "Расходы и взаимная подозрительность падают, элиты спокойнее; подполье оживает."],
	["media_reg", "Государственное телевидение и радио в регионах", 4.0, 4, "", "Охват государственных СМИ в трёх самых слабых регионах растёт: меньше протестов и сепаратизма там. Разовые расходы 0,05% ВВП."],
	["bm_raid", "Облавы на спекулянтов", 4.0, 4, "", "Чёрный рынок −20, страх +4; но при дефиците без «второй экономики» очереди длиннее, а олигархи недовольны."],
	["bm_legal", "Узаконить «вторую экономику» (мелкая торговля и кооперативы)", 6.0, 12, "", "Чёрный рынок становится легальным: налоги идут в бюджет, коррупция ниже. Идеологи и аппарат недовольны."],
	["brain_ret", "Программа возвращения учёных и инженеров", 5.0, 6, "", "Утечка умов −15, оппозиция в эмиграции слабеет. Расходы 0,05% ВВП; при страхе выше 70 работает вполовину."],
	["borders_open", "Открыть границы", 4.0, 6, "", "Выезд снова свободен: отношения с демократиями лучше, торговля растёт, но эмиграция вырастет."],
	["youth_org", "Молодёжный и массовый союз", 6.0, 4, "", "Лояльная молодёжь и «общественные организации»: поддержка молодёжи и аппарата растёт, студенческое подполье слабеет. Содержание стоит денег."],
	["succ_train", "Готовить преемника (посты и наставники)", 5.0, 12, "", "Качество преемника растёт: смена власти пройдёт мягче. Нужен назначенный преемник."],
	["succ_swap", "Сменить преемника", 8.0, 12, "", "Прежний кандидат отставлен, назначен представитель другого клана. Прежний клан обижен."],
	["patron_east", "Покровитель: великая держава на Востоке", 8.0, 0, "", "Дешёвые кредиты, обход санкций, защита от переворота. Взамен растёт зависимость; недовольны националисты, демократии отдаляются."],
	["patron_gulf", "Покровитель: богатые нефтяные монархии", 8.0, 0, "", "Инвестиции и вклады, чуть помощи с санкциями. Зависимость растёт медленно."],
	["patron_bloc", "Покровитель: блок режимов-единомышленников", 8.0, 0, "", "Взаимная защита от санкций и общие методы контроля; денег мало, зависимость невелика."],
	["patron_drop", "Отказаться от покровителя", 4.0, 12, "", "Зависимость падает, демократии теплеют; кредиты и защита от санкций пропадают."],
	["evade", "Сеть обхода санкций (посредники, реэкспорт)", 5.0, 6, "", "Часть ущерба от санкций снимается (до 60%). Олигархи богатеют, коррупция растёт. Разовые расходы 0,05% ВВП."],
	["pris_swap", "Обмен политзаключённых на уступки", 5.0, 12, "", "Часть политзаключённых выходит на свободу: отношения с демократиями лучше, страх чуть слабее; подполье получает лидеров."],
	["turn_up", "Явка по разнарядке", 4.0, 3, "", "Бюджетников и работников госпредприятий свозят на участки: официальная явка и итог партии власти выше; аппарат довольн, но протесты против «каруселей» вероятнее."],
	["turn_dn", "Добровольная явка", 0.0, 3, "", "Явка по разнарядке отменена: меньше протестов, партии власти труднее."],
	["stage_on", "Постановочные выборы: допускать только «удобных» кандидатов", 8.0, 12, "hybrid,dictatorship,junta,oneparty,monarchy_abs,theocracy", "Реальные соперники не допускаются, остаются «технические» партии. Итог партии власти почти гарантирован; демократии не признают выборы."],
	["stage_off", "Допустить настоящую конкуренцию", 4.0, 12, "", "Допуск кандидатов расширен: итоги честнее, оппозиция оживает."],
]

const AU_PATRONS := {
	"patron_east": ["east", "великая держава на Востоке", 0.0008, 0.50, 0.9, 0.8],
	"patron_gulf": ["gulf", "нефтяные монархии", 0.0012, 0.15, 0.2, 0.3],
	"patron_bloc": ["bloc", "блок режимов-единомышленников", 0.0003, 0.30, 0.3, 0.2],
}

# одноразовые решения новой власти: id, название, цена в капитале, описание
const AU_DECS := [
	["nat", "Национализировать все крупные компании", 14.0, "Государство берёт под контроль крупнейшие компании. Выкуп дорог, но спокойнее; конфискация бесплатна, зато бизнес и инвесторы в шоке."],
	["orgs", "Выйти из ряда международных организаций", 8.0, "Отмечаются организации, из которых страна выходит разом. Отношения с их членами падают, зато уходят обязательства."],
	["const", "Принять новую конституцию", 10.0, "Сроки правителя обнуляются, аппарат доволен, подполье и демократии против."],
	["ban", "Запретить все партии, кроме правящей", 10.0, "Оппозиционные партии не допускаются к выборам. Доступно гибридным режимам; в остальных парламент и так декоративный."],
	["purge", "Очистить армию и спецслужбы", 9.0, "Силовые кланы теряют вес и растут в страхе. Сначала риск мятежа, потом режим надёжнее."],
	["close", "Закрыть границы и выезд", 8.0, "Эмиграция почти прекращается, но торговля и отношения с демократиями страдают, дефицит и чёрный рынок растут."],
	["econ", "Сменить экономическую модель", 12.0, "Выбирается модель экономики. Эффекты те же, что при её принятии законом."],
	["sym", "Новые символы и название государства", 6.0, "Новое официальное название, гимн и флаг: националисты довольны, меньшинства и регионы с сильной идентичностью недовольны."],
	["regs", "Распустить регионы или назначить губернаторов", 9.0, "Центр забирает власть на местах: меньше самостоятельности, но выше риск сепаратизма и недовольство регионального клана."],
]
const AU_NEW_NAMES := ["Великая Республика", "Народная Держава", "Союз Трудового Народа", "Свободное Государство", "Священная Держава", "Единая Федерация"]


func au2_def(id: String) -> Array:
	for a in AU2_ACTS:
		if String(a[0]) == id:
			return a
	return []


func au2_has(id: String) -> bool:
	return not au2_def(id).is_empty()


# ---------- состояние ----------
func au_x() -> Dictionary:
	if au.is_empty():
		return {}
	if not au.has("x"):
		var bs: Dictionary = au.get("base", {})
		var f: float = float(bs.get("fear", au.get("fear", 0.0)))
		var p: float = float(bs.get("prop", au.get("prop", 0.0)))
		au["x"] = {"pol": f * 0.7, "pol0": f * 0.7, "youth": p * 0.3, "youth0": p * 0.3, "bm": 0.0, "bm_off": 0.0, "sh": 0.0, "brain": 0.0, "closed": false,
			"patron": "", "dep": 0.0, "evade": 0.0, "turnq": 0.0, "staged": false, "ban": false, "sq": 0.0, "t0": turn - regime_t, "age0": 55.0,
			"med": [], "boost": [], "dec": [], "title": "", "centr": 0.0, "purge_t": -999, "pris0": int(au.get("pris", 0)), "off_t": 0.0, "real_t": 0.0, "gone": 0.0,
			"cred": 0.0, "upkeep": 0.0}
		(au["x"] as Dictionary)["bm"] = au2_bm_target()
	return au["x"]


func au_fe() -> float:
	var bf: float = float((au.get("base", {}) as Dictionary).get("fear", 0.0))
	return float(au["fear"]) + (float(au["fear"]) - bf) * (AU2 - 1.0)


func au_pe() -> float:
	var bp: float = float((au.get("base", {}) as Dictionary).get("prop", 0.0))
	return float(au["prop"]) + (float(au["prop"]) - bp) * (AU2 - 1.0)


# отклонение от стартового уровня с учётом 2× (то, что страна ещё «не заложила» в показатели)
func au_dfe() -> float:
	return (float(au["fear"]) - float((au.get("base", {}) as Dictionary).get("fear", 0.0))) * AU2


func au_dpe() -> float:
	return (float(au["prop"]) - float((au.get("base", {}) as Dictionary).get("prop", 0.0))) * AU2


func au_med() -> Array:
	var x: Dictionary = au_x()
	var med: Array = x["med"]
	if med.size() != regions.size():
		med.clear()
		(x["boost"] as Array).clear()
		for i in regions.size():
			med.append(au2_med_base(i))
			(x["boost"] as Array).append(0.0)
	return med


func au2_med_base(i: int) -> float:
	var dev: float = float(regions[i]["dev"]) - reg_avg("dev")
	return clampf(25.0 + float(au["prop"]) * 0.5 - dev * 0.25 - (0.0 if bool(au.get("censor", false)) else 5.0), 5.0, 95.0)


func au_med_avg() -> float:
	var med: Array = au_med()
	var s := 0.0
	for i in med.size():
		s += float(med[i]) * (gdp_w[i] if i < gdp_w.size() else 1.0 / float(maxi(1, med.size())))
	return s


func au2_n_sanc() -> int:
	if not fa_on():
		return 0
	return (fa["sanc"] as Dictionary).size()


func au_evade() -> float:
	if not au_on():
		return 0.0
	return clampf(float(au_x()["evade"]), 0.0, 0.6)


func au2_bm_target() -> float:
	var x: Dictionary = au["x"]
	var t: float = shortage * 0.5 + (15.0 if econ_id() == "planned" else 0.0) + float(au2_n_sanc()) * 1.2 * (1.0 - au_evade()) + maxf(0.0, inflation - 6.0) \
		+ float(lvl.get("corruption", 30.0)) * 0.12 + (8.0 if bool(x["closed"]) else 0.0) + float(x["sh"]) * 0.5 - float(x["bm_off"])
	return clampf(t, 0.0, 100.0)


# ---------- хуки в старые механики ----------
func au2_und_t() -> float:
	if not au_on():
		return 0.0
	var x: Dictionary = au_x()
	return -(float(x["pol"]) - float(x["pol0"])) * 0.15 - (float(x["youth"]) - float(x["youth0"])) * 0.10


func au2_clan_t(kind: String) -> float:
	if not au_on():
		return 0.0
	var x: Dictionary = au_x()
	var dp: float = float(x["pol"]) - float(x["pol0"])
	var t := 0.0
	match kind:
		"force": t += dp * 0.12 + (6.0 if turn - int(x["purge_t"]) > 12 and turn - int(x["purge_t"]) < 48 else 0.0)
		"apparat": t -= dp * 0.04
		"money": t -= float(x["bm"]) * 0.05 - (float(x["evade"]) * 6.0)
		"reg": t += (float(x["centr"]) * -10.0)
		"ideo_c": t += (float(x["dep"]) - 40.0) * -0.05 if float(x["dep"]) > 40.0 else 0.0
	if String(x["patron"]) != "" and float(x["dep"]) > 60.0 and kind in ["force", "apparat"]:
		t -= (float(x["dep"]) - 60.0) * 0.12
	return t


func au2_risk() -> float:
	if not au_on():
		return 0.0
	var x: Dictionary = au_x()
	var r := 0.0
	var dt: int = turn - int(x["purge_t"])
	if dt >= 0 and dt < 6:
		r += 8.0
	elif dt >= 6 and dt < 36:
		r -= 6.0
	if String(x["patron"]) != "":
		r -= 3.0 if String(x["patron"]) == "east" else 1.5
	if String(au.get("succ", "")) != "" and au["cl"].has(String(au["succ"])):
		var w: float = float(au["cl"][String(au["succ"])]["w"])
		r += maxf(0.0, w * 100.0 - 40.0) * 0.25 - float(x["sq"]) * 0.04
	if float(x["brain"]) > 60.0:
		r += (float(x["brain"]) - 60.0) * 0.05
	return r


func au_sep_term(i: int) -> float:
	if not au_on() or au.is_empty():
		return 0.0
	var x: Dictionary = au_x()
	var med: Array = au_med()
	var reach: float = float(med[i]) / 100.0 if i < med.size() else 0.3
	var boost: float = float((x["boost"] as Array)[i]) / 100.0 if i < (x["boost"] as Array).size() else 0.0
	var t: float = -au_dfe() * 0.10 - (reach + boost) * au_dpe() * 0.08
	t += maxf(0.0, float(au["fear"]) - 75.0) * 0.15 + maxf(0.0, float(au["pris"]) - float(x["pris0"])) * 0.002
	t += float(x["centr"]) * 6.0 * float(REGIONS[i].get("reg", 0.3))
	return clampf(t, -25.0, 25.0)


# недовольство региона: страх и охват пропаганды (выше стартовых, с множителем 2×) гасят его, дефицит и переборы — раскачивают
func au_unr_term(i: int) -> float:
	if au.is_empty() or not au_on():
		return 0.0
	var x: Dictionary = au_x()
	var med: Array = au_med()
	var reach: float = float(med[i]) / 100.0 if i < med.size() else 0.3
	var boost: float = float((x["boost"] as Array)[i]) / 100.0 if i < (x["boost"] as Array).size() else 0.0
	var t: float = -au_dfe() * 0.12 - (reach + boost) * au_dpe() * 0.05 + float(x["sh"]) * 0.04 + float(x["bm"]) * 0.01
	t += maxf(0.0, float(au["fear"]) - 80.0) * 0.3 + maxf(0.0, float(au["pris"]) - float(x["pris0"])) * 0.002
	return clampf(t, -25.0, 25.0)


func au_ag_term(i: int) -> float:
	if not au_on() or au.is_empty():
		return 0.0
	var x: Dictionary = au_x()
	var med: Array = au_med()
	var reach: float = float(med[i]) / 100.0 if i < med.size() else 0.3
	return clampf(au_dfe() * 0.05 + reach * au_dpe() * 0.03 - (float(x["sh"]) + float(x["bm"]) * 0.2) * 0.02, -6.0, 6.0)


# множитель голосов несистемных партий: страх и пропаганда (выше стартовых) отбивают избирателя от оппозиции
func au_opp_mult(p: int, role: float) -> float:
	if au.is_empty() or role > 0.0 or not au.has("om"):
		return 1.0
	return float(au["om"])


func au2_dyn() -> void:
	if not au_on() or mods.is_empty():
		return
	var x: Dictionary = au_x()
	var dp: float = float(x["pol"]) - float(x["pol0"])
	var dy: float = float(x["youth"]) - float(x["youth0"])
	mods["growth_bonus"] = float(mods["growth_bonus"]) - maxf(0.0, dp) * 0.0006 - float(x["bm"]) * 0.0008 - float(x["brain"]) * 0.0008 - (0.15 if bool(x["closed"]) else 0.0)
	mods["corr_shift"] = float(mods["corr_shift"]) + float(x["bm"]) * 0.01 + float(x["evade"]) * 2.0 + float(x["turnq"]) * 0.01
	mods["mood_shift"] = float(mods["mood_shift"]) - float(x["sh"]) * 0.004 - maxf(0.0, dp) * 0.001 + dy * 0.001
	mods["dem_shift"] = float(mods.get("dem_shift", 0.0)) - (0.04 if bool(x["ban"]) else 0.0) - (0.03 if bool(x["staged"]) else 0.0) - (0.02 if bool(x["closed"]) else 0.0)
	mods["auto_shift"] = float(mods.get("auto_shift", 0.0)) - float(x["centr"]) * 25.0


# ---------- месяц ----------
func au2_step() -> void:
	if not au_on():
		return
	var x: Dictionary = au_x()
	var bs: Dictionary = au.get("base", {})
	var fear: float = float(au["fear"])
	var prop: float = float(au["prop"])
	var df: float = maxf(0.0, fear - float(bs.get("fear", 0.0)))
	var dpr: float = maxf(0.0, prop - float(bs.get("prop", 0.0)))
	var dp: float = maxf(0.0, float(x["pol"]) - float(x["pol0"]))
	var dy: float = maxf(0.0, float(x["youth"]) - float(x["youth0"]))
	# содержание страха и пропаганды: сверх уровня, уже заложенного в бюджет страны на старте
	var up: float = df * 0.00004 + dpr * 0.00003 + dp * 0.00003 + dy * 0.00002
	x["upkeep"] = up
	debt += gdp * up / 12.0
	# тайная полиция: слабое подполье, но недоверие внутри элит
	var dpol: float = float(x["pol"]) - float(x["pol0"])
	x["pol"] = clampf(float(x["pol"]) + (float(x["pol0"]) - float(x["pol"])) * 0.01, 0.0, 100.0)
	if dpol > 0.0:
		au["pris"] = int(au["pris"]) + int(au_und_total() * dpol * 0.0004)
		for k in au["cl"]:
			au["cl"][k]["b"] = float(au["cl"][k]["b"]) - dpol * 0.004
		add_support("Молодёжь", -dpol * 0.002)
	# государственные СМИ по регионам
	var med: Array = au_med()
	var bst: Array = x["boost"]
	var dpe: float = au_dpe()
	for i in regions.size():
		var tg: float = au2_med_base(i)
		med[i] = float(med[i]) + (tg - float(med[i])) * 0.03
		bst[i] = float(bst[i]) * 0.985
	# дефицит и чёрный рынок
	var sh_t: float = float(au2_n_sanc()) * 1.5 * (1.0 - au_evade()) + (10.0 if bool(x["closed"]) else 0.0)
	x["sh"] = clampf(float(x["sh"]) + (sh_t - float(x["sh"])) * 0.05, 0.0, 100.0)
	var bt: float = au2_bm_target()
	x["bm"] = clampf(float(x["bm"]) + (bt - float(x["bm"])) * 0.06, 0.0, 100.0)
	debt += gdp * float(x["bm"]) * 0.00004 / 12.0
	# эмиграция и утечка умов
	var press: float = maxf(0.0, (fear - 40.0) * 0.02) + maxf(0.0, -growth) * 0.3 + maxf(0.0, 50.0 - approval()) * 0.015 + (0.3 if bool(au.get("censor", false)) else 0.0) \
		+ float(x["bm"]) * 0.004 + float(x["sh"]) * 0.006
	if bool(x["closed"]):
		press *= 0.1
	x["emig"] = press
	x["brain"] = clampf(float(x["brain"]) + (clampf(press * 40.0, 0.0, 100.0) - float(x["brain"])) * 0.04, 0.0, 100.0)
	x["gone"] = float(x["gone"]) + total_pop() * press / 1200.0
	if float(x["brain"]) > 20.0:
		au_und_add(float(x["brain"]) * 0.01, "exile")
	# молодёжные союзы
	x["youth"] = clampf(float(x["youth"]) + (float(x["youth0"]) - float(x["youth"])) * 0.012, 0.0, 100.0)
	if dy > 0.0:
		add_support("Молодёжь", dy * 0.003)
		for k in au_clan_of_kind("apparat"):
			au_clan_add(k, dy * 0.004)
	# преемник и возраст правителя
	var age: float = au2_age()
	var succ: String = String(au.get("succ", ""))
	if succ != "" and au["cl"].has(succ):
		au["cl"][succ]["w"] = minf(0.7, float(au["cl"][succ]["w"]) + 0.0003)
	if age > 68.0 and current_event.is_empty() and randf() < (age - 68.0) * 0.0004:
		au2_ruler_gone()
	# покровитель
	var pt: String = String(x["patron"])
	if pt != "":
		var pd: Array = AU_PATRONS["patron_" + pt]
		debt = maxf(0.0, debt - gdp * float(pd[2]) / 12.0)
		x["cred"] = float(x["cred"]) + gdp * float(pd[2]) / 12.0
		x["dep"] = clampf(float(x["dep"]) + float(pd[5]) * 0.12, 0.0, 100.0)
		x["evade"] = maxf(float(x["evade"]), float(pd[3]))
	else:
		x["dep"] = maxf(0.0, float(x["dep"]) - 0.4)
	x["evade"] = maxf(0.0, float(x["evade"]) - (0.004 if pt == "" else 0.0))
	if float(x["dep"]) > 60.0 and turn % 6 == 0:
		dip_all(-0.8, true)
	# политзаключённые видны миру
	var extra: float = maxf(0.0, float(au["pris"]) - float(x["pris0"]))
	if turn % 6 == 0 and extra > 100.0:
		dip_all(-clampf(extra / 800.0, 0.0, 2.5), true)
	# готовность оппозиции: множитель голосов
	au["om"] = clampf(1.0 - au_dfe() * 0.004 - dpe * 0.003 - maxf(0.0, float(x["pol"]) - float(x["pol0"])) * 0.002, 0.55, 1.4)


func au2_age() -> float:
	var x: Dictionary = au_x()
	return float(x["age0"]) + float(turn - int(x["t0"])) / 12.0


# правитель умер или ушёл по здоровью
func au2_ruler_gone() -> void:
	var x: Dictionary = au_x()
	var succ: String = String(au.get("succ", ""))
	var cl: Dictionary = au["cl"]
	if succ != "" and cl.has(succ):
		var q: float = float(x["sq"])
		au_log("Правитель ушёл из жизни. Власть без потрясений перешла к преемнику из клана «%s»." % String(au_clan_def(succ)[1]))
		au["fat_t"] = turn
		for k in cl:
			au_clan_add(String(k), 3.0 + q * 0.08 if String(k) == succ else -2.0)
		regime_risk = minf(100.0, regime_risk + maxf(0.0, 12.0 - q * 0.12))
		au["succ"] = ""
	else:
		au_log("Правитель умер, преемника нет. Кланы делят наследство: схватка за власть.")
		for k in cl:
			au_clan_add(String(k), -12.0)
		regime_risk = minf(100.0, regime_risk + 25.0)
		au["fear"] = maxf(0.0, float(au["fear"]) - 10.0)
		au_und_add(10.0)
		au["fat_t"] = turn
		# власть берёт самый влиятельный клан
		var best := ""
		var bw := -1.0
		for k in cl:
			if float(cl[k]["w"]) > bw:
				bw = float(cl[k]["w"])
				best = String(k)
		if best != "":
			au_clan_add(best, 14.0, 1.15)
	x["t0"] = turn
	x["age0"] = 52.0 + randf() * 8.0
	x["sq"] = 0.0
	if not current_event.is_empty():
		return
	log_line("[color=%s][b]Смена правителя.[/b] Новый руководитель обещает «продолжить курс».[/color]" % COL_WARN)


# ---------- рычаги ----------
func au2_check(id: String) -> String:
	var why := pl_why("gov")
	if why != "":
		return why
	if game_over:
		return "игра окончена"
	if not au_on():
		return "при демократии эти рычаги недоступны"
	var a := au2_def(id)
	var cls_req: String = String(a[4])
	if cls_req != "" and not (String(au["cls"]) in cls_req.split(",")):
		return "только для режима: %s" % ", ".join(Array(cls_req.split(",")).map(func(c: String) -> String: return au_class_name(c)))
	if cap_spendable() < float(a[2]):
		return "нужно %.0f капитала" % float(a[2])
	if int(au["cd"].get(id, -99)) > turn:
		return "ещё %d мес." % (int(au["cd"][id]) - turn)
	var x: Dictionary = au_x()
	match id:
		"pol_up":
			if float(x["pol"]) >= 95.0:
				return "осведомители уже везде"
		"pol_dn":
			if float(x["pol"]) <= 5.0:
				return "тайной полиции почти нет"
		"bm_raid":
			if float(x["bm"]) < 5.0:
				return "чёрного рынка почти нет"
		"bm_legal":
			if float(x["bm"]) < 5.0:
				return "чёрного рынка почти нет"
		"brain_ret":
			if float(x["brain"]) < 8.0:
				return "утечки умов почти нет"
		"borders_open":
			if not bool(x["closed"]):
				return "границы и так открыты"
		"youth_org":
			if float(x["youth"]) >= 90.0:
				return "союзы уже охватили всю молодёжь"
		"succ_train":
			if String(au.get("succ", "")) == "":
				return "преемник не назначен"
			if float(x["sq"]) >= 90.0:
				return "преемник уже подготовлен"
		"succ_swap":
			if String(au.get("succ", "")) == "":
				return "преемник не назначен"
		"patron_east", "patron_gulf", "patron_bloc":
			if String(x["patron"]) != "":
				return "покровитель уже есть"
		"patron_drop":
			if String(x["patron"]) == "":
				return "покровителя нет"
		"evade":
			if au2_n_sanc() == 0 and float(x["evade"]) <= 0.0:
				return "санкций нет"
			if float(x["evade"]) >= 0.6:
				return "обход санкций уже на пределе"
		"pris_swap":
			if int(au["pris"]) < 30:
				return "политзаключённых почти нет"
		"turn_up":
			if float(x["turnq"]) >= 90.0:
				return "явка и так по разнарядке"
		"turn_dn":
			if float(x["turnq"]) <= 1.0:
				return "явка и так добровольная"
		"stage_on":
			if bool(x["staged"]):
				return "выборы уже постановочные"
		"stage_off":
			if not bool(x["staged"]):
				return "допуск кандидатов и так свободный"
	return ""


func au2_act(id: String) -> bool:
	var why := au2_check(id)
	if why != "":
		log_line("[color=%s]Нельзя: %s.[/color]" % [COL_WARN, why])
		return false
	var a := au2_def(id)
	capital -= float(a[2])
	au_cd(id, int(a[3]))
	var x: Dictionary = au_x()
	var txt := ""
	match id:
		"pol_up":
			x["pol"] = minf(100.0, float(x["pol"]) + 18.0)
			au["fear"] = minf(100.0, float(au["fear"]) + 8.0)
			au_und_add(-10.0)
			au["pris"] = int(au["pris"]) + 40
			for k in au_clan_of_kind("force"):
				au_clan_add(k, 6.0, 1.05)
			add_support("Молодёжь", -2.0)
			txt = "Тайная полиция расширена: осведомители на заводах и в университетах. Страх %.0f из 100." % float(au["fear"])
		"pol_dn":
			x["pol"] = maxf(0.0, float(x["pol"]) - 18.0)
			for k in au_clan_of_kind("force"):
				au_clan_add(k, -5.0)
			for k in au["cl"]:
				au_clan_add(String(k), 1.5)
			au_und_add(4.0)
			txt = "Тайная полиция сокращена: меньше слежки и доносов, подполье осмелело."
		"media_reg":
			var med: Array = au_med()
			var bst: Array = x["boost"]
			var idx: Array = []
			for i in regions.size():
				idx.append(i)
			idx.sort_custom(func(p: int, q: int) -> bool: return float(med[p]) + float(bst[p]) < float(med[q]) + float(bst[q]))
			var names: PackedStringArray = []
			for k in mini(3, idx.size()):
				bst[idx[k]] = minf(60.0, float(bst[idx[k]]) + 30.0)
				names.append(String(REGIONS[idx[k]]["name"]))
			debt += gdp * 0.0005
			au["prop"] = minf(100.0, float(au["prop"]) + 2.0)
			txt = "Вышки, телеканалы и радио в слабых регионах (%s): охват государственных СМИ растёт." % ", ".join(names)
		"bm_raid":
			x["bm"] = maxf(0.0, float(x["bm"]) - 20.0)
			x["sh"] = minf(100.0, float(x["sh"]) + 4.0)
			au["fear"] = minf(100.0, float(au["fear"]) + 4.0)
			for k in au_clan_of_kind("money"):
				au_clan_add(k, -7.0)
			txt = "Облавы на спекулянтов: чёрный рынок прижат, но на прилавках пусто, а олигархи ворчат."
		"bm_legal":
			x["bm_off"] = float(x["bm_off"]) + 10.0
			x["bm"] = maxf(0.0, float(x["bm"]) - 10.0)
			lvl["corruption"] = clampf(float(lvl["corruption"]) - 2.0, 0.0, 100.0)
			for k in au_clan_of_kind("money"):
				au_clan_add(k, 8.0)
			for k in au_clan_of_kind("ideo_c") + au_clan_of_kind("apparat"):
				au_clan_add(k, -5.0)
			txt = "Мелкая торговля и кооперативы разрешены: «вторая экономика» вышла из тени и платит налоги."
		"brain_ret":
			var k2: float = 0.5 if float(au["fear"]) > 70.0 else 1.0
			x["brain"] = maxf(0.0, float(x["brain"]) - 15.0 * k2)
			debt += gdp * 0.0005
			au_und_add(-3.0, "exile")
			txt = "Программа возвращения: льготы и лаборатории для вернувшихся учёных."
		"borders_open":
			x["closed"] = false
			dip_all(5.0, true)
			au["fear"] = maxf(0.0, float(au["fear"]) - 4.0)
			txt = "Границы открыты: выезд свободен, торговля оживает."
		"youth_org":
			x["youth"] = minf(100.0, float(x["youth"]) + 20.0)
			add_support("Молодёжь", 1.5)
			debt += gdp * 0.0003
			txt = "Создан молодёжный и массовый союз: слёты, лагеря, значки и карьерные лифты для лояльных."
		"succ_train":
			x["sq"] = minf(100.0, float(x["sq"]) + 20.0)
			var s1: String = String(au["succ"])
			au_clan_add(s1, 4.0)
			txt = "Преемник получил посты и наставников: качество подготовки %.0f из 100." % float(x["sq"])
		"succ_swap":
			var old: String = String(au["succ"])
			var best := ""
			var bw := -1.0
			for k in au["cl"]:
				if String(k) != old and float(au["cl"][k]["w"]) > bw:
					bw = float(au["cl"][k]["w"])
					best = String(k)
			if best != "":
				au_clan_add(old, -8.0, 0.9)
				au_clan_add(best, 10.0, 1.08)
				au["succ"] = best
				x["sq"] = 30.0
				txt = "Новый преемник — выходец из клана «%s»; прежнему кандидату указали на дверь." % String(au_clan_def(best)[1])
		"patron_east", "patron_gulf", "patron_bloc":
			var pd: Array = AU_PATRONS[id]
			x["patron"] = String(pd[0])
			x["dep"] = maxf(float(x["dep"]), 10.0)
			x["evade"] = maxf(float(x["evade"]), float(pd[3]))
			dip_all(-2.0 if String(pd[0]) != "gulf" else -0.5, true)
			if String(pd[0]) == "east":
				for k in au_clan_of_kind("apparat") + au_clan_of_kind("ideo_c"):
					au_clan_add(k, -4.0)
			txt = "Заключено соглашение с покровителем: %s. Кредиты и защита от санкций в обмен на зависимость." % String(pd[1])
		"patron_drop":
			x["patron"] = ""
			x["dep"] = maxf(0.0, float(x["dep"]) - 20.0)
			x["evade"] = 0.0
			dip_all(3.0, true)
			for k in au_clan_of_kind("apparat") + au_clan_of_kind("ideo_c"):
				au_clan_add(k, 4.0)
			txt = "Страна отказалась от покровителя: зависимость падает, но кредиты и защита от санкций пропали."
		"evade":
			x["evade"] = minf(0.6, float(x["evade"]) + 0.15)
			debt += gdp * 0.0005
			lvl["corruption"] = clampf(float(lvl["corruption"]) + 1.5, 0.0, 100.0)
			for k in au_clan_of_kind("money"):
				au_clan_add(k, 6.0)
			txt = "Сеть посредников и реэкспорта: ущерб от санкций снижен на %.0f%%." % (float(x["evade"]) * 100.0)
		"pris_swap":
			au["pris"] = int(float(au["pris"]) * 0.7)
			au["fear"] = maxf(0.0, float(au["fear"]) - 3.0)
			dip_all(3.0, true)
			au_und_add(2.0)
			txt = "Обмен политзаключённых: часть вышла на свободу и уехала. Политзаключённых — %d." % int(au["pris"])
		"turn_up":
			x["turnq"] = minf(100.0, float(x["turnq"]) + 20.0)
			au["fraud"] = minf(100.0, float(au["fraud"]) + 4.0)
			for k in au_clan_of_kind("apparat") + au_clan_of_kind("reg"):
				au_clan_add(k, 3.0)
			txt = "Явка по разнарядке: руководителям предприятий и школ даны планы по голосам (%.0f из 100)." % float(x["turnq"])
		"turn_dn":
			x["turnq"] = maxf(0.0, float(x["turnq"]) - 20.0)
			au["fraud"] = maxf(0.0, float(au["fraud"]) - 3.0)
			dip_all(1.0, true)
			txt = "Явка по разнарядке отменена: на участки ходят только добровольно."
		"stage_on":
			x["staged"] = true
			dip_all(-3.0, true)
			au_und_add(5.0)
			txt = "Выборы стали постановочными: соперников не допускают, остаются «технические» партии."
		"stage_off":
			x["staged"] = false
			dip_all(3.0, true)
			au_und_add(-2.0)
			txt = "Допуск кандидатов расширен: выборы станут честнее."
	au_log(txt)
	recompute_mods()
	return true


# выборы: запрет оппозиции, постановочный допуск и явка по разнарядке (поверх обычных фальсификаций)
func au2_stage(sh: Array[float]) -> Array[float]:
	if not au_on() or sh.is_empty():
		return sh
	var x: Dictionary = au_x()
	var ban: float = 0.8 if bool(x["ban"]) else (0.35 if bool(x["staged"]) else 0.0)
	var boost: float = float(x["turnq"]) * 0.0006 + (0.04 if bool(x["staged"]) else 0.0)
	if ban <= 0.0 and boost <= 0.0:
		return sh
	var pp := au_pp()
	if pp >= sh.size():
		return sh
	var out: Array[float] = sh.duplicate()
	var moved := 0.0
	for p in out.size():
		if p != pp:
			var cut: float = out[p] * ban
			out[p] -= cut
			moved += cut
	var rest := 0.0
	for p in out.size():
		if p != pp:
			rest += out[p]
	var more: float = minf(rest * 0.5, boost)
	if rest > 0.0:
		for p in out.size():
			if p != pp:
				out[p] -= more * out[p] / rest
	out[pp] += moved + more
	au["last_add"] = float(au.get("last_add", 0.0)) + moved + more
	return out


func au2_after_election() -> void:
	if not au_on():
		return
	var x: Dictionary = au_x()
	var real: float = clampf(0.40 + approval() * 0.004 - float(au["fear"]) * 0.0005, 0.30, 0.85)
	var off: float = minf(0.98, real + float(x["turnq"]) * 0.0035 + (0.08 if bool(x["staged"]) else 0.0) + float(au["fraud"]) * 0.001)
	x["real_t"] = real
	x["off_t"] = off
	log_line("[color=%s]Явка: по официальным данным %.0f%%, по оценкам независимых наблюдателей около %.0f%%.[/color]" % [COL_DIM, off * 100.0, real * 100.0])
	var gap: float = off - real
	if gap > 0.15:
		for r in regions:
			r["unrest"] = clampf(float(r["unrest"]) + (gap - 0.15) * 30.0, 0.0, 100.0)
		au_und_add((gap - 0.15) * 40.0)
		dip_all(-gap * 6.0, true)
		log_line("[color=%s]Явка «нарисована»: избиратели видят автобусы с бюджетниками и «карусели», в городах недовольство.[/color]" % COL_WARN)


# краткий отчёт для окна режима
func au2_report() -> String:
	if not au_on():
		return ""
	var x: Dictionary = au_x()
	var t := ""
	t += "Тайная полиция: [b]%.0f[/b] · молодёжные союзы: [b]%.0f[/b] · охват госСМИ: [b]%.0f%%[/b]\n" % [float(x["pol"]), float(x["youth"]), au_med_avg()]
	t += "Чёрный рынок: [b]%.0f[/b] · дефицит от санкций и границ: [b]%.0f[/b]\n" % [float(x["bm"]), float(x["sh"])]
	t += "Утечка умов: [b]%.0f[/b] (давление %.1f)%s\n" % [float(x["brain"]), float(x.get("emig", 0.0)), " · границы закрыты" if bool(x["closed"]) else ""]
	var pt: String = String(x["patron"])
	if pt != "":
		t += "Покровитель: [b]%s[/b], зависимость %.0f из 100\n" % [String(AU_PATRONS["patron_" + pt][1]), float(x["dep"])]
	else:
		t += "Покровителя нет"
		if au2_n_sanc() > 0:
			t += " · санкции против вас вводят %d стран, обход санкций %.0f%%" % [au2_n_sanc(), au_evade() * 100.0]
		t += "\n"
	t += "Содержание страха, пропаганды и аппарата: [b]%.2f%%[/b] ВВП в год (сверх стартового)\n" % (float(x["upkeep"]) * 100.0)
	var succ: String = String(au.get("succ", ""))
	t += "Правителю около %.0f лет%s\n" % [au2_age(), (" · преемник: «%s», подготовка %.0f" % [String(au_clan_def(succ)[1]), float(x["sq"])]) if succ != "" and not au_clan_def(succ).is_empty() else " · преемника нет"]
	var pris: int = int(au["pris"])
	t += "Политзаключённых: [b]%d[/b] (%.1f на 100 тыс. жителей)\n" % [pris, float(pris) / maxf(0.1, total_pop() * 10.0)]
	if bool(x["ban"]) or bool(x["staged"]) or float(x["turnq"]) > 0.0:
		t += "Выборы: %s%s%s\n" % ["оппозиция запрещена · " if bool(x["ban"]) else "", "постановочные · " if bool(x["staged"]) else "", "явка по разнарядке %.0f" % float(x["turnq"])]
	if String(x["title"]) != "":
		t += "Официальное название: [b]%s[/b]\n" % String(x["title"])
	return t


# ============================================================
#  ОДНОРАЗОВЫЕ РЕШЕНИЯ НОВОЙ ВЛАСТИ (конструктор пакета)
# ============================================================
func au2_dec_def(id: String) -> Array:
	for d in AU_DECS:
		if String(d[0]) == id:
			return d
	return []


func au2_dec_done(id: String) -> bool:
	return au_on() and id in (au_x()["dec"] as Array)


# организации, из которых можно выйти разом (ООН исключена)
func au2_dec_orgs() -> Array:
	var out: Array = []
	if io.is_empty():
		return out
	for o in ORGS:
		if String(o) in ["un", "euro", "schg", "eea"]:
			continue
		if io_member(String(o)):
			out.append(String(o))
	return out


func au2_dec_econ_variants() -> Array:
	var out: Array = []
	if not law_index.has("econ_model"):
		return out
	var vs: Array = law_index["econ_model"]["v"]
	var cur := cur_idx("econ_model")
	for k in vs.size():
		if k != cur:
			out.append([k, String((vs[k] as Dictionary).get("n", "?"))])
	return out


func au2_dec_avail(id: String) -> String:
	if not au_on():
		return "при демократии недоступно"
	if au2_dec_done(id):
		return "уже принято"
	match id:
		"nat":
			if corp.is_empty() or corp_state_share() >= 0.99:
				return "нечего национализировать"
		"orgs":
			if au2_dec_orgs().is_empty():
				return "страна не состоит в организациях"
		"ban":
			if String(au["cls"]) != "hybrid":
				return "при власти указами парламент и так декоративный"
		"close":
			if bool(au_x()["closed"]):
				return "границы уже закрыты"
		"econ":
			if au2_dec_econ_variants().is_empty():
				return "модель менять не на что"
	return ""


# opts: nat_mode ("buyout"/"confiscate"), orgs (Array), econ (индекс варианта), name (строка), reg_mode ("appoint"/"dissolve")
func au2_dec_cost_raw(sel: Array, opts: Dictionary) -> float:
	var s := 0.0
	for id in sel:
		var d := au2_dec_def(String(id))
		if not d.is_empty():
			s += float(d[2])
	if "orgs" in sel:
		s += float((opts.get("orgs", []) as Array).size()) * 1.0
	return s


func au2_dec_cost(sel: Array, opts: Dictionary) -> float:
	var s := au2_dec_cost_raw(sel, opts)
	# пакетная скидка: решения подписываются одним указом
	if sel.size() >= 3:
		s *= 0.85
	elif sel.size() == 2:
		s *= 0.92
	return s


func au2_dec_check(sel: Array, opts: Dictionary) -> String:
	var why := pl_why("gov")
	if why != "":
		return why
	if sel.is_empty():
		return "ничего не выбрано"
	for id in sel:
		var w := au2_dec_avail(String(id))
		if w != "":
			return "«%s»: %s" % [String(au2_dec_def(String(id))[1]), w]
	if "orgs" in sel and (opts.get("orgs", []) as Array).is_empty():
		return "отметьте организации для выхода"
	if "econ" in sel and not opts.has("econ"):
		return "выберите новую экономическую модель"
	var c := au2_dec_cost(sel, opts)
	if cap_spendable() < c:
		return "нужно %.0f капитала" % c
	return ""


func au2_dec_sign(sel: Array, opts: Dictionary) -> bool:
	var why := au2_dec_check(sel, opts)
	if why != "":
		log_line("[color=%s]Нельзя: %s.[/color]" % [COL_WARN, why])
		return false
	capital -= au2_dec_cost(sel, opts)
	var x: Dictionary = au_x()
	var names: PackedStringArray = []
	for id in sel:
		var sid: String = String(id)
		names.append(String(au2_dec_def(sid)[1]).to_lower())
		au2_dec_apply(sid, opts)
		(x["dec"] as Array).append(sid)
	au["dec_offer"] = false
	var pk: String = "" if sel.size() < 3 else " [b]Пакет решений подписан одним указом: элиты не успели возразить.[/b]"
	au_log("Указ новой власти: %s.%s" % [", ".join(names), pk])
	recompute_mods()
	return true


func au2_dec_apply(id: String, opts: Dictionary) -> void:
	var x: Dictionary = au_x()
	match id:
		"nat":
			var buy: bool = String(opts.get("nat_mode", "buyout")) == "buyout"
			var cost := 0.0
			var gain := 0.0
			for c in corp["list"]:
				var left: float = float(100 - int(c["st"])) / 100.0
				cost += float(c["rev"]) * 0.6 * left
				gain += float(c["rev"]) * 0.04 * left
				c["st"] = 100
				c["att"] = 40.0
			if buy:
				debt += cost
				corp["inv"] = maxf(-0.2, float(corp["inv"]) - 0.03)
				add_support("Бизнес", -3.0)
				risk_prem = minf(2.0, risk_prem + 0.05)
			else:
				debt = maxf(0.0, debt - gain)
				corp["inv"] = maxf(-0.2, float(corp["inv"]) - 0.15)
				add_support("Бизнес", -8.0)
				add_support("Рабочие", 3.0)
				risk_prem = minf(2.0, risk_prem + 0.2)
				for k in au_clan_of_kind("money"):
					au_clan_add(k, -12.0, 0.6)
			corp_log("Национализированы все крупные компании (%s)." % ("выкуп по рыночной цене" if buy else "конфискация"))
		"orgs":
			for o in (opts.get("orgs", []) as Array):
				var os: String = String(o)
				var d: Dictionary = ORGS.get(os, {})
				if d.has("rl") and rl_on():
					var rid: String = "eu_leave" if os == "eu" else ("leave_nato" if os == "nato" else "")
					if rid != "":
						capital += 15.0
						rl_do(rid)
				else:
					io["mem"][os] = false
					(io["pend"] as Dictionary).erase(os)
					for c in io_members(os):
						if dip.has(c):
							dip_change(c, -3.0)
					io_log("Страна вышла из %s." % String(d.get("sh", os)), COL_WARN)
			dip_all(-3.0, true)
		"const":
			au["fat_t"] = turn
			au["fraud"] = minf(100.0, float(au["fraud"]) + 8.0)
			for k in au_clan_of_kind("apparat"):
				au_clan_add(k, 12.0)
			for k in au_clan_of_kind("ideo_r"):
				au_clan_add(k, -8.0)
			au_und_add(6.0)
			dip_all(-4.0, true)
			x["t0"] = turn
		"ban":
			x["ban"] = true
			au["fraud"] = minf(100.0, float(au["fraud"]) + 10.0)
			au_und_add(8.0)
			dip_all(-5.0, true)
		"purge":
			x["purge_t"] = turn
			for k in au_clan_of_kind("force"):
				au_clan_add(k, -10.0, 0.7)
			au["fear"] = minf(100.0, float(au["fear"]) + 12.0)
			au["pris"] = int(au["pris"]) + 150
			add_support("Силовики", -6.0)
		"close":
			x["closed"] = true
			au["fear"] = minf(100.0, float(au["fear"]) + 5.0)
			dip_all(-6.0, true)
			add_support("Молодёжь", -4.0)
			add_support("Бизнес", -3.0)
		"econ":
			var idx: int = int(opts.get("econ", -1))
			au2_set_law_idx("econ_model", idx)
		"sym":
			var nm: String = String(opts.get("name", ""))
			if nm != "":
				x["title"] = nm
			au["cult"] = mini(5, int(au["cult"]) + 1)
			debt += gdp * 0.001
			for k in au_clan_of_kind("ideo_c") + au_clan_of_kind("force"):
				au_clan_add(k, 6.0)
			for i in regions.size():
				if float(REGIONS[i].get("reg", 0.3)) > 0.5:
					regions[i]["unrest"] = clampf(float(regions[i]["unrest"]) + 3.0, 0.0, 100.0)
					rv_add_hate(i, 4.0)
		"regs":
			var dis: bool = String(opts.get("reg_mode", "appoint")) == "dissolve"
			x["centr"] = 1.0 if dis else 0.5
			for i in regions.size():
				regions[i]["gov"] = new_governor(1)
				apply_reg_delta(i, {"loyalty": 4.0}, true)
				if dis:
					regions[i]["unrest"] = clampf(float(regions[i]["unrest"]) + 4.0, 0.0, 100.0)
					if float(REGIONS[i].get("reg", 0.3)) > 0.4:
						rv_add_hate(i, 8.0)
			for k in au_clan_of_kind("reg"):
				au_clan_add(k, -15.0 if dis else -8.0, 0.5 if dis else 0.75)


# смена закона указом: как au_set_gov, но для любого закона по индексу варианта
func au2_set_law_idx(tid: String, idx: int) -> bool:
	if not law_index.has(tid):
		return false
	var vs: Array = law_index[tid]["v"]
	var cur := cur_idx(tid)
	if idx < 0 or idx >= vs.size() or idx == cur:
		return false
	var old_rid := rid_of(tid)
	var sd := support_delta(tid, idx)
	for g in sd:
		add_support(g, float(sd[g]))
	var std := dict_diff(variant_part(tid, cur, "st"), variant_part(tid, idx, "st", true))
	for k in std:
		lvl[k] = clampf(float(lvl[k]) + float(std[k]), 0.0, 100.0)
	law_state[tid] = idx
	law_cd[tid] = 24
	radical_enact(tid, idx, old_rid)
	recompute_mods()
	return true


# что произойдёт, если подписать пакет (для окна решений)
func au2_dec_preview(sel: Array, opts: Dictionary) -> String:
	var lines: PackedStringArray = []
	for id in sel:
		match String(id):
			"nat":
				var cost := 0.0
				for c in corp.get("list", []):
					cost += float(c["rev"]) * 0.6 * float(100 - int(c["st"])) / 100.0
				if String(opts.get("nat_mode", "buyout")) == "buyout":
					lines.append("Национализация с выкупом: долг вырастет примерно на %.0f млрд, бизнес −3, инвесторы почти не реагируют." % cost)
				else:
					lines.append("Национализация без выкупа: бюджет получит около %.1f млрд, но бизнес −8, иностранный капитал бежит, олигархи в ярости." % (cost / 15.0))
			"orgs":
				var n: int = (opts.get("orgs", []) as Array).size()
				lines.append("Выход из организаций (%d): отношения с их членами −3 каждый, демократии недовольны, обязательства сняты." % n)
			"const":
				lines.append("Новая конституция: усталость от правителя сбрасывается, аппарат +12, фальсификации +8, подполье +6, демократии −4.")
			"ban":
				lines.append("Запрет партий: оппозиция на выборах почти не получает голосов (−80%), фальсификации +10, подполье +8.")
			"purge":
				lines.append("Чистка силовиков: силовые кланы теряют 30% влияния, страх +12, первые полгода риск переворота +8, потом на 3 года −6.")
			"close":
				lines.append("Закрытие границ: эмиграция почти исчезает, рост −0,15 п. п., дефицит и чёрный рынок растут, демократии −6.")
			"econ":
				var nm := ""
				for v in au2_dec_econ_variants():
					if int(v[0]) == int(opts.get("econ", -1)):
						nm = String(v[1])
				lines.append("Экономическая модель: «%s». Эффекты те же, что при принятии законом." % (nm if nm != "" else "не выбрана"))
			"sym":
				lines.append("Новое название «%s»: культ +1 ступень, националисты и силовые кланы +6, регионы с сильной идентичностью недовольны." % String(opts.get("name", "")))
			"regs":
				if String(opts.get("reg_mode", "appoint")) == "dissolve":
					lines.append("Роспуск регионов: самостоятельность почти исчезает (−25), губернаторы назначены, сепаратизм и недовольство в регионах растут, клан регионов −15.")
				else:
					lines.append("Назначение губернаторов: лояльность регионов +4, самостоятельность −10, клан регионов −8.")
	return "\n".join(lines)
