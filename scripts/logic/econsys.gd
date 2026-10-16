# v51_1: система управления экономикой зависит от экономической модели (рынок, смешанная, социальная,
# госкапитализм, план, кооперативы, минимальное государство): у каждой — свои рычаги и показатели.
# Здесь же — корпорации страны: крупнейшие государственные и частные компании и иностранный капитал;
# способы работы с ними тоже зависят от модели.
extends "res://scripts/logic/regime.gd"

const ES_NAMES := {"mixed": "Смешанная экономика", "market": "Рыночная экономика", "libertarian": "Минимальное государство",
	"social": "Социальное рыночное хозяйство", "statecap": "Государственный капитализм", "planned": "Плановая экономика", "coop": "Кооперативный социализм"}
const ES_DESK := {"mixed": "Промышленная политика", "market": "Рыночное регулирование", "libertarian": "Минимальное государство",
	"social": "Социальное партнёрство", "statecap": "Госкорпорации", "planned": "Госплан", "coop": "Самоуправление"}
const ES_MOTTO := {"mixed": "Рынок работает, государство выбирает приоритеты и поддерживает отрасли",
	"market": "Правила для всех одинаковы: государство — арбитр, а не игрок",
	"libertarian": "Чем меньше государства, тем больше свободы — и риска",
	"social": "Профсоюзы, работодатели и правительство договариваются за одним столом",
	"statecap": "Командные высоты — у государства: госкорпорации и госбанки",
	"planned": "Пятилетний план: директивы вместо цен, нормы вместо прибыли",
	"coop": "Предприятия принадлежат трудовым коллективам"}
# сектора плана (Госплан): ключ, название, рынок
const ES_PLAN_SECT := [["heavy", "Тяжёлая промышленность", "ind"], ["fuel", "Топливо и энергия", "ene"], ["cons", "Товары народного потребления", "srv"], ["agr", "Сельское хозяйство", "agr"]]
const ES_PLAN_LVL := ["сниженный", "обычный", "напряжённый"]
const ES_SECT_NAMES := {"agr": "Агро", "res": "Сырьё", "ind": "Промышленность", "ene": "Энергетика", "con": "Стройка", "srv": "Услуги"}
# рычаги модели: id, название, капитал, перезарядка, модели, подсказка
const ES_ACTS := [
	["dereg", "Дерегуляция: отменить лишние проверки и лицензии", 6.0, 24, "market,libertarian,mixed", "Рост +0,12 п. п. на 3 года, деловой климат лучше; экологи и профсоюзы недовольны."],
	["startup", "Налоговые каникулы стартапам", 4.0, 24, "market,libertarian", "Рост +0,05 п. п. на 2 года, бюджет теряет 0,1% ВВП."],
	["voucher", "Ваучерная приватизация", 12.0, 0, "libertarian", "Госпакеты всех компаний раздаются гражданам: −1% ВВП долга, рабочие и бюджетники недовольны."],
	["deal", "Трёхсторонняя сделка о зарплатах", 5.0, 12, "social", "Профсоюзы, работодатели и правительство договорились: риск забастовок −30, рабочие и бизнес довольны."],
	["wage_up", "Поднять уровень зарплатных соглашений", 4.0, 6, "social", "Выше равенство и поддержка рабочих, но рост слабее и инфляция выше."],
	["wage_dn", "Сдержанные зарплатные соглашения", 4.0, 6, "social", "Бизнес доволен, рост быстрее; профсоюзы ворчат."],
	["retrain", "Программа переобучения", 5.0, 24, "social,mixed", "Безработица постепенно снижается; 0,15% ВВП в год."],
	["price_up", "Повысить госцены", 6.0, 12, "planned", "Дефицит −15, но цены выросли — все группы недовольны."],
	["price_dn", "Заморозить цены строже", 4.0, 12, "planned", "Цены ниже, но очереди длиннее: дефицит растёт быстрее."],
	["storm", "Штурмовщина: догнать план в конце квартала", 4.0, 12, "planned", "Выполнение плана +10, но качество падает и дефицит +5."],
	["share_up", "Больше прибыли — трудовым коллективам", 4.0, 12, "coop", "Рабочие довольны, равенство выше, инвестиции и рост ниже."],
	["share_dn", "Больше прибыли — в развитие", 4.0, 12, "coop", "Рост выше, рабочие менее довольны."],
	["coop_bank", "Кооперативный банк развития", 6.0, 36, "coop", "Кредиты кооперативам: рост +0,05 п. п. на 3 года, 0,2% ВВП."],
	["congress", "Съезд рабочих советов", 5.0, 24, "coop", "Рабочие и молодёжь вдохновлены, капитал +4."],
]

var es := {}
var corp := {}


func econ_class() -> String:
	var r := econ_id()
	if r in ["planned", "coop", "libertarian"]:
		return r
	if not law_index.has("econ_model"):
		return "mixed"
	var n: String = String(variant_of("econ_model", cur_idx("econ_model")).get("n", ""))
	if n.begins_with("Рыночн"):
		return "market"
	if n.begins_with("Социальн"):
		return "social"
	if n.begins_with("Государственный капитализм"):
		return "statecap"
	return "mixed"


func es_init() -> void:
	es = {"cls": econ_class(), "prio": [], "plan": {"heavy": 1, "fuel": 1, "cons": 1, "agr": 1}, "ful": 100.0, "five_t": turn,
		"wage": 1, "strike": 20.0, "deal_t": -99, "share": 1, "conf": clampf(50.0 + (float(support["Бизнес"]) - 50.0) * 0.6, 10.0, 90.0),
		"idx": 100.0, "hist": [], "ful_hist": [], "ctl": 1, "cd": {}, "bon": {}, "credit": "", "log": [], "sw_t": -99}
	corp_init()


func es_class_changed(old: String, cls: String) -> void:
	es["cls"] = cls
	es["sw_t"] = turn
	es["prio"] = []
	es["credit"] = ""
	if cls == "planned":
		es["five_t"] = turn
		es["ful"] = 100.0
		for c in corp["list"]:
			c["st"] = 100
			c["att"] = 60.0
		corp["fs"] = float(corp["fs"]) * 0.5
		log_line("[color=%s]Плановая экономика: все крупные предприятия переданы государству, иностранные компании сворачивают работу. Начата первая пятилетка.[/color]" % COL_WARN)
	elif cls == "coop":
		for c in corp["list"]:
			if int(c["st"]) < 100 and String(c["mk"]) != "res":
				c["coop"] = true
		log_line("[color=%s]Кооперативный социализм: крупные частные предприятия переходят трудовым коллективам.[/color]" % COL_WARN)
	elif old == "planned":
		log_line("[color=%s]Конец плановой экономики: предприятия остаются государственными, пока их не приватизируют.[/color]" % COL_WARN)
	es_log("Новая экономическая модель: %s." % String(ES_NAMES.get(cls, cls)))


func es_bonus(key: String) -> bool:
	return turn < int((es.get("bon", {}) as Dictionary).get(key, -1))


func es_step() -> void:
	if es.is_empty():
		es_init()
	var cls := econ_class()
	if cls != String(es["cls"]):
		es_class_changed(String(es["cls"]), cls)
	# деловой климат и биржевой индекс (рыночные модели)
	var conf_t: float = 50.0 + (float(support["Бизнес"]) - 50.0) * 0.6 + clampf(growth, -5.0, 5.0) * 4.0 - risk_prem * 10.0 + (8.0 if es_bonus("dereg") else 0.0)
	if cls == "planned":
		conf_t -= 25.0
	elif cls == "statecap" or cls == "coop":
		conf_t -= 8.0
	es["conf"] = clampf(float(es["conf"]) + (conf_t - float(es["conf"])) * 0.15, 0.0, 100.0)
	es["idx"] = maxf(10.0, float(es["idx"]) * (1.0 + (growth + inflation) / 1200.0 + (float(es["conf"]) - 50.0) * 0.0004))
	(es["hist"] as Array).append(snappedf(float(es["idx"]), 0.1))
	if (es["hist"] as Array).size() > 60:
		(es["hist"] as Array).pop_front()
	match cls:
		"social":
			var st_t: float = 20.0 + maxf(0.0, inflation - 2.0) * 6.0 + maxf(0.0, unemployment - 6.0) * 3.0 + (12.0 if int(es["wage"]) == 0 else 0.0) + minf(30.0, float(turn - int(es["deal_t"])) * 0.6)
			es["strike"] = clampf(float(es["strike"]) + (st_t - float(es["strike"])) * 0.1, 0.0, 100.0)
			add_support("Рабочие", (float(es["wage"]) - 1.0) * 0.15)
			add_support("Бизнес", -(float(es["wage"]) - 1.0) * 0.1)
			if es_bonus("retrain"):
				unemployment = maxf(1.0, unemployment - 0.02)
		"planned":
			var l := 0
			for k in es["plan"]:
				l += int(es["plan"][k])
			var corr: float = float(lvl.get("corruption", 30.0))
			var ful_t: float = clampf(108.0 - float(l - 4) * 8.0 - corr * 0.2 - shortage * 0.15 + float(lvl.get("infra_lvl", 50.0)) * 0.1, 40.0, 120.0)
			es["ful"] = clampf(float(es["ful"]) + (ful_t - float(es["ful"])) * 0.2, 30.0, 130.0)
			shortage = clampf(shortage + (1.0 - float(es["plan"]["cons"])) * 0.35 + (1.0 - float(es["plan"]["agr"])) * 0.2 - (float(es["ctl"]) - 1.0) * 0.3, 0.0, 100.0)
			if int(es["ctl"]) == 2:
				inflation += 0.05
			(es["ful_hist"] as Array).append(snappedf(float(es["ful"]), 0.1))
			if (es["ful_hist"] as Array).size() > 60:
				(es["ful_hist"] as Array).pop_front()
			if turn - int(es["five_t"]) >= 60:
				var avg := 0.0
				for x in es["ful_hist"]:
					avg += float(x)
				avg /= float(maxi(1, (es["ful_hist"] as Array).size()))
				log_line("[color=%s][b]Итоги пятилетки:[/b] план выполнен на %.0f%%. %s[/color]" % [COL_GOOD if avg >= 100.0 else COL_WARN, avg,
					"Ордена передовикам, премии министерствам." if avg >= 100.0 else "Виновных ищут в министерствах."])
				capital += 6.0 if avg >= 100.0 else -4.0
				es["five_t"] = turn
				es["ful_hist"] = []
		"coop":
			add_support("Рабочие", (float(es["share"]) - 1.0) * 0.12)
	corp_step()


# вклад модели в показатели (детерминированно, вызывается при пересчёте модификаторов)
func es_dyn() -> void:
	if es.is_empty() or mods.is_empty():
		return
	var g := 0.0
	var cls: String = String(es["cls"])
	if es_bonus("dereg"):
		g += 0.12
		mods["equal_shift"] = float(mods["equal_shift"]) - 1.0
	if es_bonus("startup"):
		g += 0.05
	if es_bonus("coop_bank"):
		g += 0.05
	if cls in ["mixed", "statecap"]:
		g += 0.05 * float((es["prio"] as Array).size())
		mods["extra_spend"] = float(mods["extra_spend"]) + 0.1 * float((es["prio"] as Array).size())
	if cls == "statecap" and String(es.get("credit", "")) != "":
		g += 0.08
		mods["corr_shift"] = float(mods["corr_shift"]) + 1.0
	if cls == "social":
		var wv: float = float(es["wage"]) - 1.0
		g -= wv * 0.08
		mods["equal_shift"] = float(mods["equal_shift"]) + wv * 1.5
	if cls == "planned":
		var l := 0
		for k in es["plan"]:
			l += int(es["plan"][k])
		g += float(l - 4) * 0.06 + (float(es["ful"]) - 100.0) * 0.004
	if cls == "coop":
		var sv: float = float(es["share"]) - 1.0
		g -= sv * 0.05
		mods["equal_shift"] = float(mods["equal_shift"]) + sv * 1.0
	g += corp_growth()
	mods["growth_bonus"] = float(mods["growth_bonus"]) + g


func es_log(txt: String) -> void:
	(es["log"] as Array).push_front("%s — %s" % [date_short(), txt])
	if (es["log"] as Array).size() > 10:
		(es["log"] as Array).resize(10)


func es_act_def(id: String) -> Array:
	for a in ES_ACTS:
		if String(a[0]) == id:
			return a
	return []


func es_check(id: String) -> String:
	var why := pl_why("gov")
	if why != "":
		return why
	if game_over:
		return "игра окончена"
	var cls := econ_class()
	var parts := id.split(":")
	var base: String = parts[0]
	if base == "prio":
		if not (cls in ["mixed", "statecap"]):
			return "только при смешанной экономике или госкапитализме"
		var sec: String = parts[1]
		if not (sec in es["prio"]) and (es["prio"] as Array).size() >= 2:
			return "приоритетов не больше двух — сначала снимите один"
		if cap_spendable() < 3.0:
			return "нужно 3 капитала"
		return ""
	if base == "credit":
		if cls != "statecap":
			return "только при госкапитализме"
		if cap_spendable() < 5.0:
			return "нужно 5 капитала"
		if int(es["cd"].get("credit", -99)) > turn:
			return "ещё %d мес." % (int(es["cd"]["credit"]) - turn)
		return ""
	if base == "plan":
		if cls != "planned":
			return "только при плановой экономике"
		var v: int = int(es["plan"].get(parts[1], 1)) + (1 if parts[2] == "+" else -1)
		if v < 0 or v > 2:
			return "предел"
		if cap_spendable() < 2.0:
			return "нужно 2 капитала"
		return ""
	var a := es_act_def(base)
	if a.is_empty():
		return "неизвестное действие"
	if not (cls in String(a[4]).split(",")):
		return "не при этой модели"
	if cap_spendable() < float(a[2]):
		return "нужно %.0f капитала" % float(a[2])
	if int(es["cd"].get(base, -99)) > turn:
		return "ещё %d мес." % (int(es["cd"][base]) - turn)
	match base:
		"wage_up":
			if int(es["wage"]) >= 2:
				return "уже высокий"
		"wage_dn":
			if int(es["wage"]) <= 0:
				return "уже сдержанный"
		"share_up":
			if int(es["share"]) >= 2:
				return "уже максимум"
		"share_dn":
			if int(es["share"]) <= 0:
				return "уже минимум"
		"price_up":
			if int(es["ctl"]) >= 2:
				return "цены уже подняты"
		"price_dn":
			if int(es["ctl"]) <= 0:
				return "цены уже заморожены"
	return ""


func es_act(id: String) -> bool:
	var why := es_check(id)
	if why != "":
		log_line("[color=%s]Нельзя: %s.[/color]" % [COL_WARN, why])
		return false
	var parts := id.split(":")
	var base: String = parts[0]
	var txt := ""
	match base:
		"prio":
			capital -= 3.0
			var sec: String = parts[1]
			if sec in es["prio"]:
				(es["prio"] as Array).erase(sec)
				txt = "Сектор «%s» больше не приоритетный." % String(ES_SECT_NAMES.get(sec, sec))
			else:
				(es["prio"] as Array).append(sec)
				txt = "Сектор «%s» объявлен приоритетным: субсидии, льготные кредиты, госзаказ." % String(ES_SECT_NAMES.get(sec, sec))
		"credit":
			capital -= 5.0
			es["cd"]["credit"] = turn + 12
			es["credit"] = parts[1]
			txt = "Госбанки направляют льготные кредиты в сектор «%s»." % String(ES_SECT_NAMES.get(parts[1], parts[1]))
		"plan":
			capital -= 2.0
			es["plan"][parts[1]] = int(es["plan"][parts[1]]) + (1 if parts[2] == "+" else -1)
			for s in ES_PLAN_SECT:
				if String(s[0]) == parts[1]:
					txt = "План по отрасли «%s»: %s." % [String(s[1]), ES_PLAN_LVL[int(es["plan"][parts[1]])]]
		_:
			var a := es_act_def(base)
			capital -= float(a[2])
			if int(a[3]) > 0:
				es["cd"][base] = turn + int(a[3])
			match base:
				"dereg":
					es["bon"]["dereg"] = turn + 36
					add_support("Экологи", -2.0)
					add_support("Рабочие", -1.0)
					add_support("Бизнес", 2.0)
					txt = "Дерегуляция: отменены сотни проверок и лицензий."
				"startup":
					es["bon"]["startup"] = turn + 24
					debt += gdp * 0.001
					add_support("Молодёжь", 1.5)
					txt = "Стартапы освобождены от налогов на 2 года."
				"voucher":
					var got := 0.0
					for c in corp["list"]:
						if int(c["st"]) > 0:
							got += float(c["rev"]) * 0.3 * float(c["st"]) / 100.0
							c["st"] = int(float(c["st"]) * 0.3)
					debt = maxf(0.0, debt - gdp * 0.01)
					add_support("Рабочие", -3.0)
					add_support("Бюджетники", -3.0)
					add_support("Бизнес", 3.0)
					txt = "Ваучерная приватизация: госпакеты распроданы, долг снижен."
				"deal":
					es["deal_t"] = turn
					es["strike"] = maxf(0.0, float(es["strike"]) - 30.0)
					add_support("Рабочие", 2.0)
					add_support("Бизнес", 1.0)
					txt = "Трёхсторонняя сделка подписана: зарплаты растут вместе с производительностью."
				"wage_up":
					es["wage"] = int(es["wage"]) + 1
					inflation += 0.2
					txt = "Профсоюзы добились более высоких ставок."
				"wage_dn":
					es["wage"] = int(es["wage"]) - 1
					txt = "Зарплатные соглашения сдержанные: ставка на конкурентоспособность."
				"retrain":
					es["bon"]["retrain"] = turn + 24
					debt += gdp * 0.0015
					txt = "Запущена программа переобучения для безработных."
				"price_up":
					es["ctl"] = int(es["ctl"]) + 1
					shortage = maxf(0.0, shortage - 15.0)
					inflation += 2.0
					for g in GROUPS:
						add_support(g, -2.0)
					txt = "Госцены повышены: в магазинах появились товары, но кошельки опустели."
				"price_dn":
					es["ctl"] = int(es["ctl"]) - 1
					txt = "Цены заморожены строже."
				"storm":
					es["ful"] = float(es["ful"]) + 10.0
					shortage = minf(100.0, shortage + 5.0)
					txt = "Штурмовщина: заводы работают в три смены, план догоняют любой ценой."
				"share_up":
					es["share"] = int(es["share"]) + 1
					txt = "Трудовые коллективы получают большую долю прибыли."
				"share_dn":
					es["share"] = int(es["share"]) - 1
					txt = "Больше прибыли направлено на развитие предприятий."
				"coop_bank":
					es["bon"]["coop_bank"] = turn + 36
					debt += gdp * 0.002
					txt = "Основан кооперативный банк развития."
				"congress":
					add_support("Рабочие", 3.0)
					add_support("Молодёжь", 1.5)
					capital += 4.0
					txt = "Съезд рабочих советов одобрил курс правительства."
	es_log(txt)
	log_line("[color=%s]Экономика: %s[/color]" % [COL_WARN, txt])
	recompute_mods()
	return true


# ============================================================
#  КОРПОРАЦИИ
# ============================================================
func corp_init() -> void:
	var d: Dictionary = CORP_DATA.get(ccode, {})
	var lst: Array = []
	for r in d.get("c", []):
		lst.append({"id": String(r[0]), "n": String(r[1]), "mk": String(r[2]), "lab": String(r[3]), "st": int(r[4]), "rev": float(r[5]),
			"emp": int(r[6]), "note": String(r[7]), "att": 55.0, "champ": false, "board": false, "coop": false, "codet": false, "cd": -99, "pl": 1})
	var fl: Array = []
	for r in d.get("f", []):
		fl.append({"n": String(r[0]), "o": String(r[1]), "mk": String(r[2]), "lab": String(r[3]), "rev": float(r[4])})
	corp = {"list": lst, "f": fl, "fs": float(d.get("fs", 0.25)), "fs0": float(d.get("fs", 0.25)), "sel": 0, "log": [], "inv": 0.0}


func corp_step() -> void:
	if corp.is_empty():
		return
	var cls: String = String(es.get("cls", "mixed"))
	for c in corp["list"]:
		var u := 1.0
		if not ec.is_empty() and (ec["mk"] as Dictionary).has(String(c["mk"])):
			u = float(ec["mk"][String(c["mk"])]["u"])
		c["rev"] = float(c["rev"]) * (1.0 + (growth + inflation) / 1200.0 + (u - 0.9) * 0.002)
		var t: float = 50.0 + (float(support["Бизнес"]) - 50.0) * 0.4 if int(c["st"]) < 50 else 60.0
		if bool(c["champ"]):
			t += 15.0
		if bool(c["board"]):
			t += 12.0
		if bool(c["codet"]):
			t -= 5.0
		if cls == "planned":
			t = 55.0 + (float(es["ful"]) - 100.0) * 0.3 - float(int(c["pl"]) - 1) * 10.0
		c["att"] = clampf(float(c["att"]) + (t - float(c["att"])) * 0.05, 0.0, 100.0)
	# иностранный капитал: уходит из плановой и автаркичной экономики, приходит при хорошем климате
	var ft: float = float(corp["fs0"]) + float(corp["inv"])
	if cls == "planned" or rid_of("trade_policy") == "autarky":
		ft *= 0.3
	elif cls in ["statecap", "coop"]:
		ft *= 0.85
	if au_auth():
		ft *= 0.8
	corp["fs"] = clampf(float(corp["fs"]) + (ft - float(corp["fs"])) * 0.02, 0.0, 0.9)


func corp_growth() -> float:
	if corp.is_empty():
		return 0.0
	var g := 0.0
	for c in corp["list"]:
		if bool(c["champ"]):
			g += 0.03
	if es_bonus("taxdeal"):
		g += 0.04
	g += (float(corp["fs"]) - float(corp["fs0"])) * 1.5
	return g


func corp_name(c: Dictionary) -> String:
	var cls: String = String(es.get("cls", "mixed"))
	if cls == "planned":
		if String(c["mk"]) in ["ind", "res", "ene", "agr", "con"]:
			return "ПО «%s»" % String(c["n"])
		return "Госпредприятие «%s»" % String(c["n"])
	if bool(c.get("coop", false)):
		return "Коллектив «%s»" % String(c["n"])
	return String(c["n"])


func corp_owner_text(c: Dictionary) -> String:
	if bool(c.get("coop", false)):
		return "собственность трудового коллектива"
	var st: int = int(c["st"])
	if st >= 100:
		return "100% у государства"
	if st >= 50:
		return "государство — %d%% (контроль)" % st
	if st > 0:
		return "государство — %d%%" % st
	return "частная"


# действия с компанией: id, название, модели ("" — все), подсказка
const CO_ACTS := [
	["taxdeal", "Инвестиционное соглашение (налоговые льготы)", "market,libertarian,mixed,social,statecap", "Компания обещает инвестиции: рост +0,04 п. п. на 2 года, бюджет −0,05% ВВП, отношение +10."],
	["antitrust", "Антимонопольное расследование", "market,libertarian,mixed,social", "Штраф 2% выручки в бюджет; компания и бизнес недовольны."],
	["privatize", "Продать госпакет (25%)", "market,libertarian,mixed,social", "Деньги на погашение долга; рабочие насторожены."],
	["buy", "Купить пакет акций (25%)", "mixed,social,statecap", "Государство усиливает контроль; долг растёт, бизнес недоволен."],
	["nationalize", "Национализировать", "statecap,mixed,social", "Полный контроль государства. Бизнес и инвесторы в шоке, иностранный капитал уходит."],
	["windfall", "Налог на сверхприбыль", "social,mixed,statecap", "Разовый сбор 3% выручки (для сырья и энергетики); компания недовольна."],
	["codet", "Работники — в наблюдательный совет", "social", "Соуправление по-немецки: рабочие довольны, менеджмент чуть менее."],
	["board", "Назначить своих людей в правление", "statecap", "Компания послушна, но коррупция растёт."],
	["champ", "Национальный чемпион: поддержать", "statecap,mixed", "Субсидии и госзаказ: рост +0,03 п. п., 0,05% ВВП в год."],
	["plan_up", "Повысить план предприятию", "planned", "Выпуск растёт, директор недоволен, качество падает."],
	["plan_dn", "Снизить план предприятию", "planned", "Директор доволен, выпуск меньше."],
	["order", "Наградить орденом Трудового Красного Знамени", "planned", "Коллектив вдохновлён: отношение +15."],
	["director", "Сменить директора", "planned,statecap", "Новый директор: отношение 60, коррупция −1."],
	["coopify", "Передать трудовому коллективу", "coop", "Предприятие становится кооперативом: рабочие довольны, бизнес — нет."],
]


func co_act_def(id: String) -> Array:
	for a in CO_ACTS:
		if String(a[0]) == id:
			return a
	return []


func co_check(id: String, i: int) -> String:
	var why := pl_why("gov")
	if why != "":
		return why
	if corp.is_empty() or i < 0 or i >= (corp["list"] as Array).size():
		return "компания не выбрана"
	var a := co_act_def(id)
	var cls := econ_class()
	if not (cls in String(a[2]).split(",")):
		return "не при этой модели"
	var c: Dictionary = corp["list"][i]
	if int(c["cd"]) > turn:
		return "с компанией недавно уже работали (ещё %d мес.)" % (int(c["cd"]) - turn)
	if cap_spendable() < 4.0:
		return "нужно 4 капитала"
	match id:
		"privatize":
			if int(c["st"]) <= 0:
				return "госпакета нет"
		"buy":
			if int(c["st"]) >= 100:
				return "уже полностью государственная"
		"nationalize":
			if int(c["st"]) >= 100:
				return "уже государственная"
		"antitrust":
			if int(c["st"]) >= 50:
				return "государственную компанию не штрафуют"
		"windfall":
			if not (String(c["mk"]) in ["res", "ene"]):
				return "только для сырья и энергетики"
		"board":
			if int(c["st"]) < 25:
				return "нужен госпакет от 25%"
			if bool(c["board"]):
				return "уже назначены"
		"champ":
			if bool(c["champ"]):
				return "уже чемпион"
		"codet":
			if bool(c["codet"]):
				return "уже есть"
		"plan_up":
			if int(c["pl"]) >= 2:
				return "план уже напряжённый"
		"plan_dn":
			if int(c["pl"]) <= 0:
				return "план уже снижен"
		"coopify":
			if bool(c["coop"]):
				return "уже кооператив"
	return ""


func co_act(id: String, i: int) -> bool:
	var why := co_check(id, i)
	if why != "":
		log_line("[color=%s]Нельзя: %s.[/color]" % [COL_WARN, why])
		return false
	var c: Dictionary = corp["list"][i]
	capital -= 4.0
	c["cd"] = turn + 6
	var nm := corp_name(c)
	var txt := ""
	match id:
		"taxdeal":
			es["bon"]["taxdeal"] = turn + 24
			debt += gdp * 0.0005
			c["att"] = minf(100.0, float(c["att"]) + 10.0)
			txt = "%s подписала инвестиционное соглашение: новые заводы в обмен на льготы." % nm
		"antitrust":
			var fine: float = float(c["rev"]) * 0.02
			debt = maxf(0.0, debt - fine)
			c["att"] = maxf(0.0, float(c["att"]) - 15.0)
			add_support("Бизнес", -1.5)
			add_support("Рабочие", 0.8)
			txt = "Антимонопольный штраф %s: %.2f млрд в бюджет." % [nm, fine]
		"privatize":
			var sold: int = mini(25, int(c["st"]))
			var got: float = float(c["rev"]) * 0.6 * float(sold) / 100.0
			c["st"] = int(c["st"]) - sold
			debt = maxf(0.0, debt - got)
			add_support("Рабочие", -1.0)
			add_support("Бизнес", 1.0)
			txt = "Продан госпакет %d%% «%s»: %.1f млрд на погашение долга." % [sold, String(c["n"]), got]
		"buy":
			var add: int = mini(25, 100 - int(c["st"]))
			var cost: float = float(c["rev"]) * 0.6 * float(add) / 100.0
			c["st"] = int(c["st"]) + add
			debt += cost
			add_support("Бизнес", -1.0)
			txt = "Государство купило %d%% «%s» за %.1f млрд." % [add, String(c["n"]), cost]
		"nationalize":
			var comp: float = 0.0 if au_auth() else float(c["rev"]) * 0.3 * float(100 - int(c["st"])) / 100.0
			c["st"] = 100
			debt += comp
			c["att"] = 40.0
			add_support("Бизнес", -4.0)
			add_support("Рабочие", 1.5)
			corp["inv"] = float(corp["inv"]) - 0.03
			risk_prem = minf(2.0, risk_prem + 0.05)
			txt = "«%s» национализирована%s. Инвесторы встревожены." % [String(c["n"]), "" if comp <= 0.0 else " (компенсация %.1f млрд)" % comp]
		"windfall":
			var tax: float = float(c["rev"]) * 0.03
			debt = maxf(0.0, debt - tax)
			c["att"] = maxf(0.0, float(c["att"]) - 20.0)
			add_support("Бизнес", -2.0)
			txt = "Налог на сверхприбыль с «%s»: %.2f млрд." % [String(c["n"]), tax]
		"codet":
			c["codet"] = true
			add_support("Рабочие", 1.5)
			txt = "В наблюдательном совете «%s» — представители работников." % String(c["n"])
		"board":
			c["board"] = true
			lvl["corruption"] = clampf(float(lvl["corruption"]) + 1.0, 0.0, 100.0)
			txt = "В правление «%s» вошли люди из администрации." % String(c["n"])
		"champ":
			c["champ"] = true
			debt += gdp * 0.0005
			txt = "«%s» — национальный чемпион: субсидии и госзаказ." % String(c["n"])
		"plan_up":
			c["pl"] = int(c["pl"]) + 1
			es["ful"] = float(es["ful"]) + 2.0
			txt = "%s получило повышенный план." % nm
		"plan_dn":
			c["pl"] = int(c["pl"]) - 1
			txt = "%s получило сниженный план." % nm
		"order":
			c["att"] = minf(100.0, float(c["att"]) + 15.0)
			txt = "Коллектив %s награждён орденом." % nm
		"director":
			c["att"] = 60.0
			lvl["corruption"] = clampf(float(lvl["corruption"]) - 1.0, 0.0, 100.0)
			txt = "В %s новый директор." % nm
		"coopify":
			c["coop"] = true
			c["st"] = 0
			add_support("Рабочие", 2.0)
			add_support("Бизнес", -2.0)
			txt = "«%s» передана трудовому коллективу." % String(c["n"])
	corp_log(txt)
	log_line("[color=%s]Корпорации: %s[/color]" % [COL_WARN, txt])
	recompute_mods()
	return true


# иностранный капитал: привлечь или ограничить
func co_foreign_check(id: String) -> String:
	var why := pl_why("gov")
	if why != "":
		return why
	if cap_spendable() < 6.0:
		return "нужно 6 капитала"
	if int(es["cd"].get("for_" + id, -99)) > turn:
		return "ещё %d мес." % (int(es["cd"]["for_" + id]) - turn)
	var cls := econ_class()
	if id == "invite" and cls == "planned":
		return "в плановой экономике возможны только совместные предприятия"
	if id == "jv" and cls != "planned":
		return "совместные предприятия — инструмент плановой экономики"
	return ""


func co_foreign(id: String) -> bool:
	var why := co_foreign_check(id)
	if why != "":
		log_line("[color=%s]Нельзя: %s.[/color]" % [COL_WARN, why])
		return false
	capital -= 6.0
	es["cd"]["for_" + id] = turn + 12
	var txt := ""
	match id:
		"invite":
			corp["inv"] = minf(0.15, float(corp["inv"]) + 0.03)
			add_support("Бизнес", 1.0)
			txt = "Инвестиционный форум: иностранные компании открывают заводы и офисы."
		"jv":
			corp["inv"] = minf(0.05, float(corp["inv"]) + 0.02)
			txt = "Открыто совместное предприятие с иностранным концерном."
		"restrict":
			corp["inv"] = maxf(-0.2, float(corp["inv"]) - 0.04)
			add_support("Силовики", 1.0)
			add_support("Бизнес", -1.5)
			var top := ""
			var best := 0.0
			for f in corp["f"]:
				if float(f["rev"]) > best:
					best = float(f["rev"])
					top = String(f["o"])
			if DIP_C.has(top):
				dip_fx_apply({top: -5.0})
			txt = "Ограничения для иностранного капитала: стратегические отрасли закрыты."
	corp_log(txt)
	log_line("[color=%s]Корпорации: %s[/color]" % [COL_WARN, txt])
	recompute_mods()
	return true


func corp_log(txt: String) -> void:
	(corp["log"] as Array).push_front("%s — %s" % [date_short(), txt])
	if (corp["log"] as Array).size() > 10:
		(corp["log"] as Array).resize(10)


# доля государства в выручке крупнейших компаний
func corp_state_share() -> float:
	var s := 0.0
	var t := 0.0
	for c in corp.get("list", []):
		t += float(c["rev"])
		s += float(c["rev"]) * float(c["st"]) / 100.0
	return s / t if t > 0.0 else 0.0
