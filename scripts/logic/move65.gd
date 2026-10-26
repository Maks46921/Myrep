# 0.65: политические движения. Во всех 38 странах: типовые (профсоюзное, климатическое, студенческое, гражданское,
# национал-радикальное, фермерское) и особые (данные scripts/data/data_move65.gd, генерируются tools/gen_move65.py).
# Движение — не партия: мест в парламенте у него нет, оно действует улицей, подписями, забастовками, блогерами и деньгами,
# давит на рейтинг власти и подпитывает близкие партии. Власть отвечает по типу режима: от «ничего» до жёстких репрессий.
# Когда поддержка, возраст, организованность и разрешение режима есть, движение можно превратить в партию (слот «Прочие»).
extends "res://scripts/logic/war65.gd"

const MV_ACTS := [
	{"id": "rally", "name": "Митинги и шествия", "cap": 3.2, "cd": 2, "org": 5.0, "base": 1.0, "pub": true,
		"desc": "Выходят люди: растут поддержка и организованность, рейтинг власти слегка падает. В жёстких режимах за митинг штрафуют и задерживают."},
	{"id": "sign", "name": "Сбор подписей и петиции", "cap": 2.4, "cd": 3, "org": 10.0, "base": 1.1, "pub": true,
		"desc": "Тихая работа: поддержка растёт понемногу, приходят первые деньги. Дёшево и безопасно в любой стране, где разрешены подписи."},
	{"id": "strike", "name": "Забастовки и блокады", "cap": 4.8, "cd": 4, "org": 30.0, "base": 0.9, "pub": true,
		"desc": "Люди прекращают работу: растёт давление на власть, но экономика проседает на пару месяцев. Нужна организованность от 30."},
	{"id": "blog", "name": "Блогеры и соцсети", "cap": 1.6, "cd": 1, "org": 0.0, "base": 1.2, "pub": false,
		"desc": "Видео, разборы и сети соседей. Дёшево, достаёт молодёжь, но результат небольшой."},
	{"id": "donate", "name": "Сбор пожертвований", "cap": 0.0, "cd": 2, "org": 5.0, "base": 1.2, "pub": false,
		"desc": "Не тратит политкапитал, а даёт его: чем больше сторонников и организованность, тем больше собранное."},
	{"id": "probe", "name": "Расследования", "cap": 4.8, "cd": 4, "org": 20.0, "base": 0.8, "pub": false,
		"desc": "Журналисты и юристы вскрывают злоупотребления: сильно бьёт по рейтингу власти. В жёстких режимах вскрывшие рискуют."},
	{"id": "viol", "name": "Насильственные акции", "cap": 2.4, "cd": 2, "org": 0.0, "base": 1.1, "pub": false,
		"desc": "Погромы, драки с полицией, поджоги. Давление огромное, но люди отворачиваются, радикальность растёт. После нескольких актов власть объявляет движение угрозой безопасности."},
	{"id": "sabot", "name": "Саботаж", "cap": 4.0, "cd": 3, "org": 25.0, "base": 0.8, "pub": false,
		"desc": "Порча дорог, линий и техники. Давление и ущерб экономике на пару месяцев; считается за насилие наполовину."},
	{"id": "disobey", "name": "Гражданское неповиновение", "cap": 4.4, "cd": 3, "org": 35.0, "base": 0.85, "pub": true,
		"desc": "Блокады, отказ платить, занятые здания. Поддержка и давление растут сильно, но участников задерживают."},
]

const MV_GOV_ACTS := [
	{"id": "dialog", "name": "Начать диалог", "cap": 2.0, "cd": 3,
		"desc": "Встреча с лидерами: радикальность и давление падают, но движение получает признание."},
	{"id": "concede", "name": "Пойти на уступки", "cap": 6.0, "cd": 6,
		"desc": "Часть требований выполняется: поддержка движения падает на пятую часть, довольство близких групп растёт."},
	{"id": "split", "name": "Расколоть и подкупить лидеров", "cap": 4.0, "cd": 6,
		"desc": "Организованность падает, но 30% шанс, что это всплывёт и движение только вырастет."},
	{"id": "ban", "name": "Запретить движение", "cap": 3.0, "cd": 12,
		"desc": "Движение уходит в подполье: поддержка и организованность падают, но свободы страдают. В демократиях запретить можно только угрозу безопасности."},
	{"id": "lift", "name": "Снять запрет", "cap": 1.0, "cd": 6,
		"desc": "Движение выходит из подполья. Свободы растут."},
]

# какие социальные группы тянутся к типу движения
const MV_GROUPS := {
	"lab": {"Рабочие": 1.0, "Бюджетники": 0.7, "Пенсионеры": 0.3},
	"clim": {"Экологи": 1.0, "Молодёжь": 0.7},
	"stud": {"Молодёжь": 1.0, "Бюджетники": 0.3, "Экологи": 0.3},
	"civ": {"Молодёжь": 0.6, "Бизнес": 0.5, "Бюджетники": 0.4, "Пенсионеры": 0.2},
	"nat": {"Силовики": 0.8, "Село": 0.6, "Рабочие": 0.5, "Пенсионеры": 0.4},
	"farm": {"Село": 1.0, "Бизнес": 0.2},
	"peace": {"Пенсионеры": 0.6, "Молодёжь": 0.6, "Бюджетники": 0.3},
	"soc": {"Рабочие": 0.7, "Пенсионеры": 0.7, "Бюджетники": 0.5},
	"reg": {"Село": 0.5, "Рабочие": 0.3, "Бизнес": 0.3, "Силовики": 0.2},
}

# движения, которые подпитывают уже существующую партию-слот страны: cc -> {id движения: слот}
const MV_LINK := {"RU": {"ru_nonsys": 9}, "BY": {"by_democ": 9}, "RS": {"rs_stud": 9}, "MD": {"md_shor": 5}}

# предпочтения действий ИИ-движений по типу: act -> вес
const MV_AI := {
	"lab": {"strike": 0.30, "rally": 0.30, "sign": 0.15, "donate": 0.15, "blog": 0.10},
	"clim": {"rally": 0.30, "disobey": 0.22, "blog": 0.25, "sign": 0.12, "donate": 0.06, "sabot": 0.05},
	"stud": {"rally": 0.35, "blog": 0.25, "sign": 0.18, "disobey": 0.10, "donate": 0.07, "probe": 0.05},
	"civ": {"probe": 0.28, "sign": 0.22, "blog": 0.22, "rally": 0.20, "donate": 0.08},
	"nat": {"rally": 0.30, "blog": 0.28, "donate": 0.14, "viol": 0.18, "sign": 0.10},
	"farm": {"disobey": 0.28, "rally": 0.30, "strike": 0.20, "sign": 0.12, "donate": 0.10},
	"peace": {"rally": 0.40, "sign": 0.28, "blog": 0.22, "donate": 0.10},
	"soc": {"rally": 0.38, "strike": 0.20, "sign": 0.20, "blog": 0.14, "donate": 0.08},
	"reg": {"rally": 0.38, "sign": 0.28, "disobey": 0.16, "blog": 0.10, "donate": 0.08},
}

const MV_HARD := 0.6            # множитель шанса успеха по сравнению с партией («заметно труднее»)
const MV_VIOL_N := 3.0          # столько насильственных актов за 12 месяцев — и власть объявляет движение угрозой
const MV_PARTY_SUP := 5.0       # поддержка (%), с которой можно регистрировать партию
const MV_PARTY_AGE := 12        # возраст движения, мес.
const MV_PARTY_ORG := 40.0      # организованность
const MV_PARTY_COST := 12.0     # политкапитал
const MV_TIER_NAMES := ["полная или устойчивая демократия", "несовершенная демократия", "гибридный режим", "авторитарный режим", "тоталитарный или военный режим"]
const MV_TIER_RISK := ["ничего не грозит", "штрафы и задержания", "аресты лидеров", "запрет как «экстремистского»", "жёсткие репрессии и розыск"]
const MV_ALLOW := [1.0, 0.97, 0.85, 0.55, 0.35]
const MV_ACT_TIER := {"pub": [1.0, 0.95, 0.80, 0.60, 0.40], "soft": [1.0, 1.0, 0.90, 0.70, 0.50]}


func mv_on() -> bool:
	return int(game_opts.get("mv65", 1)) != 0


var mv_pending := ""          # id движения, за которое играет игрок (до mv_init)


func mv_init() -> void:
	mv65 = {"v": 1, "list": [], "slot": {}, "play": mv_pending, "reg": false, "dem": 0.0, "P0": 0.0, "log": [], "n": 0, "seed_t": turn}
	var rows: Array = MV65_DATA.get(ccode, [])
	var links: Dictionary = MV_LINK.get(ccode, {})
	for r in rows:
		var tp: String = String(r[1])
		var m := {"id": String(r[0]), "tp": tp, "name": String(r[2]), "desc": String(r[3]), "B": float(r[4]), "sup": float(r[4]) * 0.9, "sup0": float(r[4]) * 0.9,
			"org": float(r[5]), "org0": float(r[5]), "rad": float(r[6]), "cap": 4.0 + float(r[5]) * 0.08, "age": 18 + int(float(r[5]) / 8.0), "leader": "Лидер движения",
			"gap": 0, "st": "on", "ban_t": 0, "thr": 0, "heat": 0.0, "press": 0.0, "eff": 0.0, "viol": [], "cd": {}, "strike": 0, "sabot": 0,
			"pro": String(r[7]) == "pro", "regn": String(r[7]) == "reg", "link": int(links.get(String(r[0]), -1)), "arrests": 0, "ln": 1, "acts": 0}
		if tp == "reg":
			m["regn"] = true
		(mv65["list"] as Array).append(m)
	mv65["P0"] = mv_eff_total()
	if mv_pending != "":
		var mm: Dictionary = mv_find(mv_pending)
		if not mm.is_empty():
			mm["link"] = -1
			mm["cap"] = 0.0
			capital = 14.0
	mv_pending = ""


func mv_ensure() -> void:
	if mv65.is_empty() or not mv65.has("list"):
		mv_init()


func mv_list() -> Array:
	mv_ensure()
	return mv65["list"]


func mv_find(id: String) -> Dictionary:
	for m in mv_list():
		if String(m["id"]) == id:
			return m
	return {}


# тип режима по индексу демократии: 0 — ничего, 1 — штрафы, 2 — аресты лидеров, 3 — запрет, 4 — репрессии
func mv_tier() -> int:
	var d: float = democracy_index()
	if d >= 0.80:
		return 0
	if d >= 0.60:
		return 1
	if d >= 0.30:
		return 2
	if d >= 0.15:
		return 3
	return 4


# «Оппозиция без места в парламенте»: до регистрации партии ваш список не стоит в бюллетене
func mv65_ballot() -> float:
	if mv_player_mv() and not bool(mv65.get("reg", false)):
		return 0.0
	return 1.0


# перед обменом слотов: строка «Прочие партии» превращается в ваше движение (мест нет, электорат — по типу движения)
func mv_play_prepare(idx: int) -> bool:
	var rows: Array = MV65_DATA.get(ccode, [])
	if idx < 0 or idx >= rows.size():
		return false
	var r: Array = rows[idx]
	mv_pending = String(r[0])
	PARTY_NAMES[6] = String(r[2])
	PARTY_LEADERS[6] = "Лидер движения"
	PARTY_DESC[6] = "Ваше движение. %s Мест в парламенте нет: пока вы не зарегистрируете партию, вас нет в бюллетене." % String(r[3])
	PARTY_COLORS[6] = Color.from_hsv(float(abs(String(r[0]).hash()) % 360) / 360.0, 0.55, 0.85)
	var gw: Dictionary = MV_GROUPS.get(String(r[1]), {})
	for g in GROUPS:
		(LEAN[g] as Array)[6] = 6.0 * (0.25 + 0.75 * float(gw.get(g, 0.0)))
	# места «Прочих» уходят прежней партии власти (слот 0): движение стартует с нуля
	DE_START_SEATS[0] = int(DE_START_SEATS[0]) + int(DE_START_SEATS[6])
	DE_START_SEATS[6] = 0
	return true


func mv_gov_rating() -> float:
	return gov_pop() if opp_mode else approval()


func mv_gsup(g: String) -> float:
	return target_gov_support(g) if opp_mode else float(support[g])


func mv_gov_hit(d: float) -> void:
	# d < 0 — удар по власти: в оппозиции падает устойчивость правительства, у власти — рейтинг
	if opp_mode:
		if not opp_gov.is_empty():
			opp_gov["stab"] = clampf(float(opp_gov.get("stab", 60.0)) + d * 4.0, 0.0, 100.0)
	else:
		add_all_support(d)


func mv_player_mv() -> bool:
	return String(mv65.get("play", "")) != ""


func mv_is_mine(m: Dictionary) -> bool:
	return mv_player_mv() and String(mv65["play"]) == String(m["id"])


# ---------------- недовольство и целевая поддержка ----------------
func mv_grp(gs: Array) -> float:
	var s := 0.0
	for g in gs:
		s += clampf((50.0 - mv_gsup(String(g))) / 40.0, 0.0, 1.0)
	return s / float(maxi(1, gs.size()))


func mv_grief(tp: String) -> float:
	var a: float = clampf((55.0 - mv_gov_rating()) / 35.0, 0.0, 1.0)
	var inf: float = clampf((inflation - 5.0) / 10.0, 0.0, 1.0)
	var un: float = clampf((unemployment - 6.0) / 10.0, 0.0, 1.0)
	var cor: float = clampf((float(lvl["corruption"]) - 45.0) / 40.0, 0.0, 1.0)
	var env: float = clampf((55.0 - float(lvl["env_lvl"])) / 35.0, 0.0, 1.0)
	var war := 0.0
	if mil_on() and mil_at_war():
		war = 0.4 + 0.6 * war65_wf()
	match tp:
		"lab":
			return 0.30 * a + 0.25 * inf + 0.25 * un + 0.20 * mv_grp(["Рабочие", "Бюджетники"])
		"clim":
			return 0.50 * env + 0.20 * a + 0.30 * mv_grp(["Экологи", "Молодёжь"])
		"stud":
			return 0.35 * mv_grp(["Молодёжь"]) + 0.30 * a + 0.20 * un + 0.15 * cor
		"civ":
			return 0.50 * cor + 0.30 * a + 0.20 * un
		"nat":
			return 0.35 * a + 0.25 * inf + 0.40 * mv_grp(["Силовики", "Село"])
		"farm":
			return 0.45 * mv_grp(["Село"]) + 0.30 * a + 0.25 * inf
		"peace":
			return 0.70 * war + 0.30 * a
		"soc":
			return 0.40 * inf + 0.30 * un + 0.30 * a
		"reg":
			var sp := 0.0
			var n := 0
			for i in regions.size():
				sp += float(rv_reg(i).get("sep", 0.0))
				n += 1
			return 0.55 * clampf(sp / float(maxi(1, n)) / 40.0, 0.0, 1.0) + 0.45 * a
	return a


func mv_target(m: Dictionary) -> float:
	var tier: int = mv_tier()
	if bool(m["pro"]):
		return float(m["B"]) * (0.6 + 0.8 * clampf(mv_gov_rating() / 55.0, 0.3, 1.5))
	var t: float = float(m["B"]) * (0.45 + 1.6 * mv_grief(String(m["tp"]))) * float(MV_ALLOW[tier])
	if String(m["st"]) == "ban":
		t *= 0.6
	if String(m["st"]) == "party":
		t *= 0.85
	return minf(t, 40.0)


func mv_eff_of(m: Dictionary) -> float:
	if String(m["st"]) == "gone":
		return 0.0
	return float(m["sup"]) * (0.25 + 0.75 * float(m["org"]) / 100.0) * (0.35 + minf(1.0, float(m["press"]) / 8.0))


func mv_eff_total(only_anti: bool = true) -> float:
	var s := 0.0
	for m in mv65.get("list", []):
		if bool(m["pro"]) == only_anti:
			continue
		s += mv_eff_of(m)
	return s


# ---------------- влияние на страну ----------------
func mv65_mood() -> float:
	if not mv_on() or mv65.is_empty() or not mv65.has("list"):
		return 0.0
	var anti := 0.0
	var pro := 0.0
	for m in mv65["list"]:
		if bool(m["pro"]):
			pro += mv_eff_of(m)
		else:
			anti += mv_eff_of(m)
	var base: float = float(mv65.get("P0", 0.0))
	return -clampf((anti - base) * 0.07, -0.8, 3.0) + clampf(pro * 0.03, 0.0, 0.8)


func mv65_g() -> float:
	if not mv_on() or mv65.is_empty() or not mv65.has("list"):
		return 0.0
	var g := 0.0
	for m in mv65["list"]:
		if int(m["strike"]) > 0:
			g -= 0.10 * clampf(float(m["sup"]) / 6.0, 0.5, 1.5)
		if int(m["sabot"]) > 0:
			g -= 0.06
	return g


# вклад движения в голоса: связанная партия-слот растёт вместе с его поддержкой сверх стартовой; бывшее движение-партия — по своей поддержке
func mv65_vote_mult(p: int) -> float:
	if not mv_on() or mv65.is_empty() or not mv65.has("list"):
		return 1.0
	var mult := 1.0
	var sl: Dictionary = mv65.get("slot", {})
	if not sl.is_empty() and int(sl.get("p", -1)) == p:
		var m0: Dictionary = mv_find(String(sl["mid"]))
		if not m0.is_empty():
			mult *= clampf(0.4 + 0.6 * float(m0["sup"]) / maxf(0.5, float(sl["ref"])), 0.4, 2.5)
	for m in mv65["list"]:
		if int(m["link"]) == p and String(m["st"]) != "party":
			mult *= clampf(1.0 + 0.02 * (float(m["sup"]) - float(m["sup0"])) * (0.5 if String(m["st"]) == "ban" else 1.0), 0.5, 1.8)
	return mult


# запреты и снятие запретов сдвигают индекс демократии; со временем возвращается к норме
func mv65_dem() -> float:
	if mv65.is_empty():
		return 0.0
	return float(mv65.get("dem", 0.0))


func mv65_slot_on() -> bool:
	return not (mv65.get("slot", {}) as Dictionary).is_empty()


# партия «Прочие» стала партией движения: её можно приглашать в коалицию и играть за неё
func no_gov(p: int) -> bool:
	return mv_others(p)


func no_play(p: int) -> bool:
	return mv_others(p)


# слот 6 — сводная строка «Прочие партии» (не партия): пока из него не выросла партия движения и пока вы не играете за движение
func mv_others(p: int) -> bool:
	return p == 6 and player_orig != 6 and not mv65_slot_on()


# ---------------- действия ----------------
func mv_act_def(id: String) -> Dictionary:
	for a in MV_ACTS:
		if String(a["id"]) == id:
			return a
	return {}


func mv_cost(a: Dictionary) -> float:
	return float(a["cap"])


func mv_cap_of(m: Dictionary) -> float:
	return capital if mv_is_mine(m) else float(m["cap"])


func mv_cap_add(m: Dictionary, d: float) -> void:
	if mv_is_mine(m):
		capital += d
	else:
		m["cap"] = clampf(float(m["cap"]) + d, 0.0, 80.0)


func mv_chance(m: Dictionary, a: Dictionary) -> float:
	var tier: int = mv_tier()
	var k := 1.0
	if bool(a["pub"]):
		k = float(MV_ACT_TIER["pub"][tier])
	elif String(a["id"]) in ["blog", "donate", "sign", "probe"]:
		k = float(MV_ACT_TIER["soft"][tier])
	if String(m["st"]) == "ban" and String(a["id"]) in ["rally", "sign", "strike", "disobey", "probe"]:
		return 0.0
	if int(m["thr"]) > 0:
		k *= 0.75
	var ch: float = float(a["base"]) * MV_HARD * (0.55 + 0.9 * float(m["org"]) / 100.0) * k
	return clampf(ch, 0.05, 0.92)


func mv_can(m: Dictionary, id: String) -> String:
	var a: Dictionary = mv_act_def(id)
	if a.is_empty() or m.is_empty():
		return "нельзя"
	if String(m["st"]) == "gone":
		return "движения больше нет"
	if String(m["st"]) == "party" and id in ["viol", "sabot", "disobey", "strike"]:
		return "партия отказалась от уличных действий и насилия"
	if String(m["st"]) == "ban" and id in ["rally", "sign", "strike", "disobey", "probe"]:
		return "движение запрещено: публичные акции невозможны"
	if int(m["cd"].get(id, 0)) > 0:
		return "ещё %d мес." % int(m["cd"][id])
	if float(m["org"]) < float(a["org"]):
		return "нужна организованность %.0f" % float(a["org"])
	if id == "donate" and float(m["sup"]) < 1.0:
		return "слишком мало сторонников"
	if float(a["cap"]) > 0.0 and mv_cap_of(m) < float(a["cap"]) and not (mv_is_mine(m) and cap_spendable() == INF):
		return "не хватает политкапитала"
	return ""


func mv_tp_bonus(m: Dictionary, id: String) -> float:
	var tp: String = String(m["tp"])
	if id == "strike" and tp in ["lab", "farm"]:
		return 1.25
	if id == "blog" and tp in ["stud", "clim"]:
		return 1.3
	if id == "probe" and tp == "civ":
		return 1.3
	if id == "disobey" and tp in ["clim", "farm"]:
		return 1.2
	return 1.0


func mv_act(mid: String, id: String) -> bool:
	var m: Dictionary = mv_find(mid)
	if mv_can(m, id) != "":
		return false
	var a: Dictionary = mv_act_def(id)
	var mine: bool = mv_is_mine(m)
	if float(a["cap"]) > 0.0:
		mv_cap_add(m, -float(a["cap"]))
	m["cd"][id] = int(a["cd"])
	m["acts"] = int(m["acts"]) + 1
	var ch: float = mv_chance(m, a) * mv_tp_bonus(m, id)
	var ok: bool = randf() < clampf(ch, 0.05, 0.95)
	mv_apply(m, id, ok, mine)
	if mine:
		refresh()
	return true


func mv_say(m: Dictionary, col: String, text: String, mine: bool = false) -> void:
	if mine:
		log_tag("ДВИЖЕНИЕ", col, text)
	elif int(mv65.get("said", 0)) < 3:
		mv65["said"] = int(mv65.get("said", 0)) + 1
		log_tag("ДВИЖЕНИЯ", col, text)


func mv_apply(m: Dictionary, id: String, ok: bool, mine: bool) -> void:
	var nm: String = "«%s»" % String(m["name"])
	var tier: int = mv_tier()
	var org: float = float(m["org"])
	match id:
		"rally":
			if ok:
				m["sup"] = float(m["sup"]) + 0.25 + 0.015 * org
				m["org"] = minf(100.0, org + 1.5)
				m["heat"] = float(m["heat"]) + 0.35
				m["press"] = float(m["press"]) + 3.0
				if mine or float(m["sup"]) >= 4.0:
					mv_say(m, COL_TEAL, "%s вывело людей на улицы: поддержка растёт, рейтинг власти слегка падает." % nm, mine)
			else:
				m["org"] = maxf(0.0, org - 1.0)
				m["heat"] = float(m["heat"]) + 0.2
				if mine:
					mv_say(m, COL_WARN, "митинг %s собрал мало людей." % nm, true)
		"sign":
			if ok:
				m["sup"] = float(m["sup"]) + 0.18
				m["org"] = minf(100.0, org + 0.8)
				mv_cap_add(m, 0.5)
				m["press"] = float(m["press"]) + 1.5
				if mine:
					mv_say(m, COL_TEAL, "сбор подписей %s прошёл: поддержка растёт, пришли первые взносы." % nm, true)
			else:
				m["org"] = maxf(0.0, org - 0.3)
		"strike":
			if ok:
				m["strike"] = 2
				m["press"] = float(m["press"]) + 6.0
				m["heat"] = float(m["heat"]) + 0.5
				m["sup"] = float(m["sup"]) + 0.2
				m["org"] = minf(100.0, org + 1.5)
				if not opp_mode:
					for g in (MV_GROUPS.get(String(m["tp"]), {}) as Dictionary):
						add_support(String(g), -0.8 * float(MV_GROUPS[String(m["tp"])][g]))
				mv_say(m, COL_WARN, "забастовка %s: работа встала, экономика проседает на пару месяцев." % nm, mine)
			else:
				m["org"] = maxf(0.0, org - 2.0)
				m["sup"] = maxf(0.2, float(m["sup"]) - 0.1)
		"blog":
			if ok:
				m["sup"] = float(m["sup"]) + 0.14
				m["org"] = minf(100.0, org + 0.3)
				m["press"] = float(m["press"]) + 1.0
			else:
				m["sup"] = maxf(0.2, float(m["sup"]) - 0.03)
		"donate":
			if ok:
				mv_cap_add(m, 2.2 + float(m["sup"]) * 0.25 + org * 0.02)
				if mine:
					mv_say(m, COL_GOOD, "%s собрало пожертвования: политкапитал пополнен." % nm, true)
			else:
				mv_cap_add(m, 0.5)
		"probe":
			if ok:
				m["press"] = float(m["press"]) + 4.0
				m["sup"] = float(m["sup"]) + 0.2
				m["org"] = minf(100.0, org + 1.0)
				mv_gov_hit(-0.4)
				mv_say(m, COL_WARN, "расследование %s вскрыло злоупотребления: рейтинг власти падает." % nm, mine)
			elif tier >= 3 and randf() < 0.5:
				m["org"] = maxf(0.0, org - 8.0)
				mv_say(m, COL_BAD, "за расследование %s взялись силовики: часть активистов задержана." % nm, mine)
		"viol":
			m["press"] = float(m["press"]) + 8.0
			m["heat"] = float(m["heat"]) + 0.8
			m["sup"] = maxf(0.2, float(m["sup"]) - 0.35)
			m["rad"] = minf(100.0, float(m["rad"]) + 4.0)
			m["org"] = minf(100.0, org + 1.0)
			(m["viol"] as Array).append([turn, 1.0])
			mv_gov_hit(-0.4)
			mv_say(m, COL_BAD, "%s прибегло к насилию: давление на власть огромно, но люди отворачиваются." % nm, true if mine else float(m["sup"]) >= 2.0)
		"sabot":
			if ok:
				m["sabot"] = 2
				m["press"] = float(m["press"]) + 5.0
				m["rad"] = minf(100.0, float(m["rad"]) + 3.0)
				mv_say(m, COL_BAD, "саботаж %s: повреждены дороги и линии, экономика теряет." % nm, mine)
			(m["viol"] as Array).append([turn, 0.5])
		"disobey":
			if ok:
				m["sup"] = float(m["sup"]) + 0.3
				m["org"] = minf(100.0, org + 1.5)
				m["press"] = float(m["press"]) + 6.0
				m["heat"] = float(m["heat"]) + 0.7
				mv_say(m, COL_TEAL, "%s начало гражданское неповиновение: давление на власть растёт." % nm, mine)
			else:
				m["org"] = maxf(0.0, org - 3.0)
			if tier >= 1 and randf() < 0.15 * float(tier):
				m["org"] = maxf(0.0, float(m["org"]) - 6.0)
				if mine:
					mv_say(m, COL_WARN, "участников %s задержали." % nm, true)
	m["sup"] = clampf(float(m["sup"]), 0.0, 40.0)


# ---------------- реакция власти ----------------
func mv_viol_sum(m: Dictionary) -> float:
	var s := 0.0
	for e in m["viol"]:
		if turn - int(e[0]) <= 12:
			s += float(e[1])
	return s


func mv_respond(m: Dictionary, tier: int) -> void:
	var nm: String = "«%s»" % String(m["name"])
	var mine: bool = mv_is_mine(m)
	var heat: float = float(m["heat"])
	var sup: float = float(m["sup"])
	# объявление угрозой безопасности: в любой стране, если насилия набралось на порог
	if mv_viol_sum(m) >= MV_VIOL_N and int(m["thr"]) <= 0 and String(m["st"]) not in ["gone", "party"]:
		m["thr"] = 12
		m["org"] = maxf(0.0, float(m["org"]) - 18.0)
		m["sup"] = float(m["sup"]) * 0.75
		m["viol"] = []
		m["arrests"] = int(m["arrests"]) + 1
		m["leader"] = ""
		m["gap"] = 0
		mv_say(m, COL_BAD, "власть объявила %s угрозой безопасности: лидеры разысканы, организация разгромлена." % nm, true)
		if tier >= 2 and String(m["st"]) != "ban":
			m["st"] = "ban"
			m["ban_t"] = 0
		return
	var base_rad: float = 0.4 + float(m["rad"]) / 80.0
	match tier:
		1:
			if heat > 0.5 and randf() < 0.3:
				m["org"] = maxf(0.0, float(m["org"]) - 1.5)
				mv_cap_add(m, -0.8)
				if mine:
					mv_say(m, COL_WARN, "участников %s оштрафовали и задержали." % nm, true)
		2:
			if sup >= 0.8 and randf() < 0.05 * (1.0 + 2.0 * heat) * base_rad and String(m["leader"]) != "":
				m["leader"] = ""
				m["gap"] = 0
				m["arrests"] = int(m["arrests"]) + 1
				m["org"] = maxf(0.0, float(m["org"]) - 12.0)
				m["sup"] = sup * 0.96 + 0.25      # арест лидера отчасти работает на движение
				m["press"] = float(m["press"]) + 2.0
				mv_say(m, COL_BAD, "арестован лидер %s: организация потеряла голову." % nm, mine or sup >= 3.0)
		3:
			if String(m["st"]) == "on" and sup >= 1.5 and randf() < 0.04 * (1.0 + sup / 5.0) * base_rad:
				m["st"] = "ban"
				m["ban_t"] = 0
				m["sup"] = sup * 0.75
				m["org"] = maxf(0.0, float(m["org"]) - 15.0)
				m["leader"] = ""
				m["gap"] = 0
				mv_say(m, COL_BAD, "%s объявлено «экстремистским» и запрещено: оно уходит в подполье." % nm, true)
			elif sup >= 1.0 and randf() < 0.05 * (1.0 + 2.0 * heat) * base_rad and String(m["leader"]) != "":
				m["leader"] = ""
				m["gap"] = 0
				m["org"] = maxf(0.0, float(m["org"]) - 12.0)
				mv_say(m, COL_BAD, "лидер %s арестован." % nm, mine)
		4:
			if sup >= 0.4:
				m["sup"] = sup * 0.97
				m["org"] = maxf(0.0, float(m["org"]) - 2.0)
			if String(m["st"]) == "on" and sup >= 1.0 and randf() < 0.10 * base_rad:
				m["st"] = "ban"
				m["ban_t"] = 0
				m["leader"] = ""
				m["gap"] = 0
				mv_say(m, COL_BAD, "%s разгромлено: лидеры арестованы, движение запрещено, идёт розыск." % nm, true)
	# запрет снимается, когда режим смягчился надолго
	if String(m["st"]) == "ban":
		m["ban_t"] = int(m["ban_t"]) + 1
		m["org"] = maxf(0.0, float(m["org"]) - 0.8)
		if tier <= 2 and int(m["ban_t"]) >= 6 and not bool(m["pro"]):
			m["st"] = "on"
			mv_say(m, COL_GOOD, "запрет %s снят: оно возвращается из подполья." % nm, true)


# ---------------- месячный шаг ----------------
func mv_ai_pick(m: Dictionary) -> String:
	var pref: Dictionary = MV_AI.get(String(m["tp"]), MV_AI["civ"])
	var tot := 0.0
	var opts: Array = []
	for id in pref:
		var w: float = float(pref[id])
		if id in ["viol", "sabot"]:
			w *= float(m["rad"]) / 60.0
		if mv_can(m, String(id)) != "":
			continue
		tot += w
		opts.append([w, String(id)])
	if opts.is_empty() or tot <= 0.0:
		return ""
	var r: float = randf() * tot
	for o in opts:
		r -= float(o[0])
		if r <= 0.0:
			return String(o[1])
	return String(opts[opts.size() - 1][1])


func mv65_month() -> void:
	if not mv_on() or not wmonth or game_over:
		return
	mv_ensure()
	mv65["said"] = 0
	var tier: int = mv_tier()
	var list: Array = mv65["list"]
	for m in list.duplicate():
		var st: String = String(m["st"])
		if st == "gone":
			continue
		var mine: bool = mv_is_mine(m)
		m["age"] = int(m["age"]) + 1
		for k in (m["cd"] as Dictionary).keys():
			m["cd"][k] = maxi(0, int(m["cd"][k]) - 1)
		m["strike"] = maxi(0, int(m["strike"]) - 1)
		m["sabot"] = maxi(0, int(m["sabot"]) - 1)
		m["thr"] = maxi(0, int(m["thr"]) - 1)
		m["heat"] = float(m["heat"]) * 0.6
		m["press"] = float(m["press"]) * 0.6
		# поддержка идёт к цели, организованность растёт с поддержкой и падает под давлением
		var tgt: float = mv_target(m)
		m["sup"] = clampf(float(m["sup"]) + (tgt - float(m["sup"])) * 0.07 + randf_range(-0.05, 0.05), 0.2 if not bool(m["pro"]) else 0.5, 40.0)
		if st == "on" or st == "party":
			m["org"] = clampf(float(m["org"]) + 0.25 * (float(m["sup"]) / 5.0) * (1.0 if int(m["thr"]) <= 0 else 0.0) - 0.15, 0.0, 100.0)
		# политкапитал движения: взносы активистов и мелкие пожертвования; свободнее при свободе, труднее под запретом
		var inc: float = float(m["sup"]) * float(m["org"]) / 450.0 + (0.15 if String(m["leader"]) != "" else 0.0)
		if st == "ban":
			inc *= 0.4
		mv_cap_add(m, inc)
		# лидер: нет лидера — через 3 месяца выбирают нового
		if String(m["leader"]) == "" and st != "gone":
			m["gap"] = int(m["gap"]) + 1
			if int(m["gap"]) >= 3 and float(m["org"]) >= 12.0:
				m["ln"] = int(m["ln"]) + 1
				m["leader"] = "Лидер движения №%d" % int(m["ln"])
				m["gap"] = 0
		if not mine:
			if st in ["on", "party"] and randf() < 0.25 + 0.4 * float(m["org"]) / 100.0:
				var id: String = mv_ai_pick(m)
				if id != "":
					mv_act(String(m["id"]), id)
			elif st == "ban" and randf() < 0.15:
				var id2: String = mv_ai_pick(m)
				if id2 != "":
					mv_act(String(m["id"]), id2)
		mv_respond(m, tier)
		if st != "party" and not mine:
			mv_ai_party(m, tier)
	mv65["dem"] = float(mv65.get("dem", 0.0)) * 0.99
	mv_group_effects()


func mv_group_effects() -> void:
	# давление движений на довольство близких групп (слабее, чем общий рейтинг): возвращается само
	var base: float = float(mv65.get("P0", 0.0))
	var over: float = maxf(0.0, mv_eff_total() - base)
	if over <= 0.5 or opp_mode:
		return
	for m in mv65["list"]:
		if bool(m["pro"]) or float(m["press"]) < 1.0:
			continue
		for g in (MV_GROUPS.get(String(m["tp"]), {}) as Dictionary):
			add_support(String(g), -0.015 * float(m["press"]) * float(MV_GROUPS[String(m["tp"])][g]))


# ---------------- превращение в партию ----------------
func mv_party_can(m: Dictionary) -> String:
	if m.is_empty() or String(m["st"]) in ["gone", "party"]:
		return "уже нельзя"
	if int(m["link"]) >= 0:
		return "у движения уже есть партия «%s»" % PARTY_NAMES[int(m["link"])]
	if mv65_slot_on():
		return "в стране уже есть партия, выросшая из движения"
	if bool(m["pro"]):
		return "движение при власти не нуждается в партии"
	if String(m["st"]) == "ban":
		return "движение запрещено"
	if mv_tier() >= 3:
		return "режим не регистрирует партии оппозиции"
	if float(m["sup"]) < MV_PARTY_SUP:
		return "поддержка ниже %.0f%%" % MV_PARTY_SUP
	if int(m["age"]) < MV_PARTY_AGE:
		return "движению меньше %d мес." % MV_PARTY_AGE
	if float(m["org"]) < MV_PARTY_ORG:
		return "организованность ниже %.0f" % MV_PARTY_ORG
	if String(m["leader"]) == "":
		return "нет выбранного лидера"
	if mv_cap_of(m) < MV_PARTY_COST and not (mv_is_mine(m) and cap_spendable() == INF):
		return "не хватает политкапитала (%.0f)" % MV_PARTY_COST
	return ""


func mv_ai_party(m: Dictionary, tier: int) -> void:
	if float(m["sup"]) < MV_PARTY_SUP * 1.4 or mv_party_can(m) != "":
		return
	if randf() < 0.02:
		mv_to_party(String(m["id"]))


func mv_party_name(m: Dictionary) -> String:
	var tp: String = String(m["tp"])
	var nm: String = String(m["name"])
	if nm.begins_with("Движение"):
		nm = nm.substr(9)
	return "Партия «%s»" % nm.strip_edges().trim_prefix("«").trim_suffix("»")


func mv_to_party(mid: String) -> bool:
	var m: Dictionary = mv_find(mid)
	var why: String = mv_party_can(m)
	if why != "":
		return false
	var mine: bool = mv_is_mine(m)
	if mv_tier() == 2 and randf() < 0.3:
		mv_cap_add(m, -MV_PARTY_COST)
		m["org"] = maxf(0.0, float(m["org"]) - 6.0)
		mv_say(m, COL_BAD, "властям не понравилась заявка: в регистрации партии «%s» отказали, заявку признали недействительной." % String(m["name"]), true)
		return false
	mv_cap_add(m, -MV_PARTY_COST)
	var tp: String = String(m["tp"])
	var p: int = 0 if mine else 6
	var nm: String = mv_party_name(m)
	PARTY_NAMES[p] = nm
	PARTY_LEADERS[p] = String(m["leader"]) + (" (вы)" if mine else "")
	if not mine:
		PARTY_COLORS[p] = Color.from_hsv(float(abs(mid.hash()) % 360) / 360.0, 0.55, 0.85)
		var gw: Dictionary = MV_GROUPS.get(tp, {})
		for g in GROUPS:
			var arr: Array = LEAN[g]
			arr[p] = maxf(0.4, float(arr[p]) * (0.5 + float(gw.get(g, 0.0)) * 1.4))
	PARTY_DESC[p] = ("Ваша партия. " if mine else "") + "%s. Выросла из движения «%s»: %s" % [nm, String(m["name"]), String(m["desc"])]
	mv65["slot"] = {"p": p, "mid": mid, "ref": float(m["sup"]), "t": turn}
	# часть радикалов уходит: радикальное крыло продолжает улицу, партия отказывается от насилия и уличных акций
	var wing := {"id": mid + "_wing", "tp": tp, "name": "Радикальное крыло «%s»" % String(m["name"]), "desc": "Те, кто не пошёл в партию: остались на улице и считают участие в выборах предательством.",
		"B": float(m["B"]) * 0.4, "sup": float(m["sup"]) * 0.3, "sup0": float(m["sup"]) * 0.3, "org": float(m["org"]) * 0.4, "org0": float(m["org"]) * 0.4,
		"rad": minf(100.0, float(m["rad"]) + 30.0), "cap": float(m["cap"]) * 0.3, "age": 0, "leader": "", "gap": 0, "st": "on", "ban_t": 0, "thr": 0, "heat": 0.0, "press": 0.0,
		"eff": 0.0, "viol": [], "cd": {}, "strike": 0, "sabot": 0, "pro": false, "regn": bool(m["regn"]), "link": -1, "arrests": 0, "ln": 1, "acts": 0}
	(mv65["list"] as Array).append(wing)
	m["st"] = "party"
	m["sup"] = float(m["sup"]) * 0.7
	m["rad"] = maxf(0.0, float(m["rad"]) - 15.0)
	m["org"] = minf(100.0, float(m["org"]) + 5.0)
	mv_say(m, COL_GOOD, "%s зарегистрировало партию «%s»: на ближайших выборах она получит места. Часть радикалов ушла в отдельное крыло." % ["«%s»" % String(m["name"]), nm], true)
	if mine:
		mv65["reg"] = true
		mv_calibrate_party(m)
	prel_init()
	refresh()
	return true


# ваша новая партия: поддержка групп подгоняется так, чтобы её доля в опросах была около 110% поддержки движения
func mv_calibrate_party(m: Dictionary) -> void:
	var target: float = clampf(float(m["sup"]) * 1.1, 1.0, 40.0) / 100.0
	for i in 8:
		var sh: float = float(national_shares(false)[0])
		var k: float = clampf(1.0 + (target - sh) * 2.5, 0.7, 1.4)
		for g in GROUPS:
			support[g] = clampf(float(support[g]) * k, 15.0, 90.0)
		if absf(target - sh) < 0.004:
			break


# ---------------- ответы власти (вы у власти) ----------------
func mv_gov_def(id: String) -> Dictionary:
	for a in MV_GOV_ACTS:
		if String(a["id"]) == id:
			return a
	return {}


func mv_gov_can(m: Dictionary, id: String) -> String:
	var a: Dictionary = mv_gov_def(id)
	if a.is_empty() or m.is_empty() or mv_player_mv():
		return "нельзя"
	if String(m["st"]) in ["gone", "party"]:
		return "нельзя"
	if cd_left("mv_" + String(m["id"]) + "_" + id) > 0:
		return "ещё %d мес." % cd_left("mv_" + String(m["id"]) + "_" + id)
	if cap_spendable() < float(a["cap"]):
		return "не хватает политкапитала"
	if id == "ban":
		if String(m["st"]) == "ban":
			return "уже запрещено"
		if mv_tier() <= 1 and int(m["thr"]) <= 0:
			return "в демократии запрещать можно только угрозу безопасности"
		if bool(m["pro"]):
			return "нельзя"
	if id == "lift" and String(m["st"]) != "ban":
		return "запрета нет"
	return ""


func mv_gov_do(mid: String, id: String) -> bool:
	var m: Dictionary = mv_find(mid)
	if mv_gov_can(m, id) != "":
		return false
	var a: Dictionary = mv_gov_def(id)
	capital -= float(a["cap"])
	opp_cd["mv_" + mid + "_" + id] = int(a["cd"])
	var nm: String = "«%s»" % String(m["name"])
	match id:
		"dialog":
			m["rad"] = maxf(0.0, float(m["rad"]) - 6.0)
			m["press"] = float(m["press"]) * 0.5
			m["org"] = minf(100.0, float(m["org"]) + 1.5)
			log_tag("ДВИЖЕНИЯ", COL_TEAL, "вы встретились с лидерами %s: накал спал, но движение получило признание." % nm)
		"concede":
			m["sup"] = float(m["sup"]) * 0.8
			m["rad"] = maxf(0.0, float(m["rad"]) - 8.0)
			for g in (MV_GROUPS.get(String(m["tp"]), {}) as Dictionary):
				add_support(String(g), 1.5 * float(MV_GROUPS[String(m["tp"])][g]))
			log_tag("ДВИЖЕНИЯ", COL_GOOD, "вы пошли навстречу %s: поддержка движения упала, довольство близких групп выросло." % nm)
		"split":
			if randf() < 0.30:
				m["sup"] = float(m["sup"]) * 1.15
				m["rad"] = minf(100.0, float(m["rad"]) + 6.0)
				add_all_support(-1.0)
				log_tag("ДВИЖЕНИЯ", COL_BAD, "история с подкупом лидеров %s всплыла: движение выросло, а вы потеряли в рейтинге." % nm)
			else:
				m["org"] = maxf(0.0, float(m["org"]) - 15.0)
				m["sup"] = float(m["sup"]) * 0.92
				m["leader"] = ""
				m["gap"] = 0
				log_tag("ДВИЖЕНИЯ", COL_TEAL, "в руководстве %s раскол: организованность упала." % nm)
		"ban":
			m["st"] = "ban"
			m["ban_t"] = 0
			m["sup"] = float(m["sup"]) * 0.8
			m["org"] = maxf(0.0, float(m["org"]) - 15.0)
			if mv_tier() <= 2:
				mv65["dem"] = clampf(float(mv65.get("dem", 0.0)) - 0.015, -0.08, 0.04)
			log_tag("ДВИЖЕНИЯ", COL_BAD, "вы запретили %s: оно ушло в подполье." % nm)
		"lift":
			m["st"] = "on"
			m["thr"] = 0
			mv65["dem"] = clampf(float(mv65.get("dem", 0.0)) + 0.01, -0.08, 0.04)
			log_tag("ДВИЖЕНИЯ", COL_GOOD, "вы сняли запрет с %s." % nm)
	refresh()
	return true


# ---------------- тексты ----------------
func mv_status_name(m: Dictionary) -> String:
	match String(m["st"]):
		"ban":
			return "запрещено"
		"party":
			return "стало партией"
		"gone":
			return "распалось"
	if int(m["thr"]) > 0:
		return "объявлено угрозой"
	return "действует"


func mv_tp_name(tp: String) -> String:
	var t: Array = (MV65_TYPES.get(tp, []) as Array)
	if t.is_empty():
		return tp
	return String(t[0])


func mv_summary_text() -> String:
	if not mv_on():
		return "Движения выключены в настройках."
	var tier: int = mv_tier()
	var t := "[b]Режим:[/b] %s. Что грозит активному движению: %s.\n" % [MV_TIER_NAMES[tier], MV_TIER_RISK[tier]]
	var d: float = mv_eff_total() - float(mv65.get("P0", 0.0))
	t += "Давление улицы на рейтинг власти: [b]%s[/b] п.п. к норме." % sg(mv65_mood(), 1)
	if mv65_slot_on():
		t += "\nПартия из движения: [b]%s[/b]." % PARTY_NAMES[6]
	return t


func mv_detail_text(m: Dictionary) -> String:
	if m.is_empty():
		return ""
	var tier: int = mv_tier()
	var t := "[b]%s[/b] — %s\n%s\n\n" % [m["name"], mv_tp_name(String(m["tp"])).to_lower(), m["desc"]]
	t += "Статус: [b]%s[/b]. Возраст: %d мес. Лидер: %s.\n" % [mv_status_name(m), int(m["age"]), (String(m["leader"]) if String(m["leader"]) != "" else "нет (выберут через %d мес.)" % maxi(0, 3 - int(m["gap"])))]
	t += "Поддержка: [b]%.1f%%[/b] избирателей (стартовая %.1f%%, цель %.1f%%). Организованность: [b]%.0f[/b]. Радикальность: [b]%.0f[/b].\n" % [float(m["sup"]), float(m["sup0"]), mv_target(m), float(m["org"]), float(m["rad"])]
	t += "Политкапитал движения: [b]%.1f[/b] (взносы активистов растут с поддержкой и организованностью, можно собирать пожертвования). Давление на власть: %.1f.\n" % [mv_cap_of(m), float(m["press"])]
	if int(m["link"]) >= 0:
		t += "Подпитывает партию «%s»: её голоса растут с поддержкой движения.\n" % PARTY_NAMES[int(m["link"])]
	var vs: float = mv_viol_sum(m)
	if vs > 0.0:
		t += "[color=%s]Насилия за 12 мес.: %.1f из %.0f — на пороге власть объявит движение угрозой.[/color]\n" % [COL_WARN, vs, MV_VIOL_N]
	var why: String = mv_party_can(m)
	t += "В партию: [color=%s]%s[/color]\n" % [COL_GOOD if why == "" else COL_DIM, "можно зарегистрировать" if why == "" else why]
	return t
