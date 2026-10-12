# v51_1: недемократические режимы изнутри. Власть держится не на парламенте, а на кланах элиты (их лояльности
# и влиянии), страхе, пропаганде, культе личности и фальсификациях. Против режима работает подполье; у каждого
# режима свои кланы и свои особые решения. Класс режима:
#   «dem» — демократия (механики режима не действуют), «hybrid» — гибридный режим (выборы есть, но управляемые),
#   dictatorship / junta / oneparty / monarchy_abs / theocracy — власть указами.
extends "res://scripts/logic/revolt.gd"

const AU_CLASS_NAMES := {"dem": "Демократия", "hybrid": "Гибридный режим", "dictatorship": "Диктатура", "junta": "Военная хунта",
	"oneparty": "Однопартийное государство", "monarchy_abs": "Абсолютная монархия", "theocracy": "Теократия"}
const AU_CLASS_MOTTO := {"hybrid": "Выборы есть, но исход известен заранее",
	"dictatorship": "Режим личной власти: правитель, его семья и силовики", "junta": "Военный совет: приказы вместо законов",
	"oneparty": "Партия — руководящая и направляющая сила", "monarchy_abs": "Воля монарха — закон",
	"theocracy": "Власть от веры: духовенство над государством"}
# кланы: id, название, значок, интерес (force — силовой, money — деньги, reg — регионы, apparat — аппарат,
# ideo_c — консерваторы и вера, ideo_r — реформаторы), исходное влияние
const AU_CLANS := {
	"hybrid": [["sil", "Силовики", "shield", "force", 0.32], ["olig", "Олигархи и госкорпорации", "coin", "money", 0.26], ["gov", "Губернаторы", "pin", "reg", 0.18], ["bur", "Администрация и бюрократия", "bank", "apparat", 0.24]],
	"dictatorship": [["sil", "Силовые структуры", "shield", "force", 0.34], ["olig", "Олигархи", "coin", "money", 0.22], ["gov", "Региональные бароны", "pin", "reg", 0.16], ["fam", "Семья и ближний круг", "person", "apparat", 0.28]],
	"junta": [["army", "Армейское командование", "shield", "force", 0.38], ["sec", "Спецслужбы", "gauge", "force", 0.22], ["biz", "Крупный бизнес", "coin", "money", 0.20], ["gov", "Военные губернаторы", "pin", "reg", 0.20]],
	"oneparty": [["pb", "Политбюро", "hall", "apparat", 0.32], ["cons", "Консерваторы", "scroll", "ideo_c", 0.24], ["ref", "Реформаторы", "flask", "ideo_r", 0.20], ["kgb", "Госбезопасность", "shield", "force", 0.24]],
	"monarchy_abs": [["court", "Двор и знать", "crown", "apparat", 0.30], ["guard", "Гвардия", "shield", "force", 0.28], ["clergy", "Духовенство", "faith", "ideo_c", 0.20], ["merch", "Купечество", "coin", "money", 0.22]],
	"theocracy": [["council", "Совет духовенства", "faith", "ideo_c", 0.34], ["guard", "Стражи веры", "shield", "force", 0.28], ["bazaar", "Торговые кланы", "coin", "money", 0.20], ["bur", "Чиновничество", "bank", "apparat", 0.18]],
}
const AU_UNDER := {
	"hybrid": [["lib", "Несистемная оппозиция"], ["media", "Независимые журналисты и блогеры"], ["union", "Независимые профсоюзы"]],
	"dictatorship": [["lib", "Демократическое подполье"], ["stud", "Студенческие кружки"], ["exile", "Оппозиция в эмиграции"]],
	"junta": [["civ", "Гражданское движение за выборы"], ["officers", "Недовольные младшие офицеры"], ["union", "Забастовочные комитеты"]],
	"oneparty": [["dis", "Диссиденты и самиздат"], ["union", "Свободные профсоюзы"], ["nat", "Национальные движения"]],
	"monarchy_abs": [["const", "Конституционалисты"], ["rep", "Республиканское подполье"], ["stud", "Студенты и интеллигенция"]],
	"theocracy": [["sec", "Светская оппозиция"], ["women", "Женское движение"], ["stud", "Студенческие протесты"]],
}
# рычаги режима: id, название, цена в капитале, перезарядка (мес.), классы ("" — все недемократические), подсказка
const AU_ACTS := [
	["arrests", "Аресты активистов", 5.0, 3, "", "Страх +12, подполье слабеет, растёт число политзаключённых. Молодёжь недовольна, демократии осуждают."],
	["amnesty", "Амнистия политзаключённых", 6.0, 12, "", "Политзаключённые выходят на свободу: страх −12, рейтинг и отношения с демократиями растут, но подполье оживает."],
	["prop_up", "Усилить пропаганду", 4.0, 2, "", "Пропаганда +12 (стоит ещё 0,05% ВВП): официальный рейтинг выше, недовольство тише."],
	["prop_dn", "Ослабить пропаганду", 0.0, 2, "", "Пропаганда −15: меньше расходов, чуть лучше отношения с демократиями."],
	["censor", "Цензура интернета (вкл./выкл.)", 5.0, 6, "", "Блокировки и фильтры: подполью труднее, но молодёжь и технологии страдают, демократии осуждают."],
	["cult", "Культ личности: ступень выше", 10.0, 6, "", "Аппарат сплачивается вокруг вас, капитал растёт быстрее; реформаторы и молодёжь недовольны, преемственность сложнее."],
	["decult", "Культ личности: ступень ниже", 4.0, 6, "", "Скромнее образ правителя: реформаторы довольны, аппарат теряет ориентиры."],
	["fraud_up", "Больше «административного ресурса» на выборах", 3.0, 3, "", "Фальсификации +15: партия власти получит больше голосов, но после выборов возможны протесты."],
	["fraud_dn", "Честнее выборы", 0.0, 3, "", "Фальсификации −15: меньше протестов после выборов, демократии одобряют."],
	["succ", "Назначить преемника", 15.0, 0, "", "Снимает «усталость от правителя» и страх элит перед будущим; клан, из которого вышел преемник, усиливается."],
	["lib", "Оттепель (либерализация)", 10.0, 12, "", "Страх, пропаганда, культ и фальсификации снижаются, часть заключённых на свободе. Реформаторы и молодёжь рады, силовики насторожены, подполье на время смелеет."],
	["roundtable", "Круглый стол и переход к демократии", 15.0, 0, "dictatorship,junta,oneparty,monarchy_abs,theocracy", "Договор с оппозицией: режим уступает место республике со свободными выборами. Конец власти указами."],
	["promise", "Пообещать передать власть гражданским (через 2 года)", 6.0, 0, "junta", "Риск переворота −12, отношения с миром лучше, подполье спокойнее. Но через 2 года обещание надо выполнить (круглый стол), иначе — взрыв недовольства."],
	["constitution", "Даровать конституцию", 12.0, 0, "monarchy_abs", "Монарх делит власть с парламентом: конституционная монархия. Двор и духовенство недовольны, конституционалисты удовлетворены."],
	["plenum_c", "Пленум ЦК: консервативный курс", 6.0, 6, "oneparty", "Консерваторы и госбезопасность усиливаются, реформаторы в опале, страх растёт."],
	["plenum_r", "Пленум ЦК: курс на реформы", 6.0, 6, "oneparty", "Реформаторы получают посты: два года экономика растёт быстрее, консерваторы недовольны."],
	["fatwa", "Указ духовного совета", 5.0, 6, "theocracy", "Совет духовенства и стражи веры довольны; молодёжь и женское движение — против."],
	["referendum", "Референдум о продлении полномочий", 8.0, 36, "dictatorship,hybrid", "«Обнуление»: усталость от правителя сброшена, но фальсификации растут, а подполье злится."],
]

var au := {}


func regime_class() -> String:
	var r := regime_id()
	if r in RAD_AUTH and r != "theocracy":
		return r
	if rid_of("state_church") == "theocracy" or r == "theocracy":
		return "theocracy"
	var d := democracy_index()
	if d < 0.25 or (r == "superpres" and d < 0.45):
		return "hybrid"
	return "dem"


func au_on() -> bool:
	return not au.is_empty() and String(au.get("cls", "dem")) != "dem"


func au_auth() -> bool:
	return au_on() and String(au["cls"]) != "hybrid"


func au_class_name(cls: String = "") -> String:
	if cls == "":
		cls = String(au.get("cls", "dem"))
	return String(AU_CLASS_NAMES.get(cls, cls))


# начальное состояние: у гибридных режимов (Россия, Беларусь) страх, пропаганда и фальсификации уже есть
func au_init() -> void:
	au = {"cls": "dem", "fear": 0.0, "prop": 0.0, "cult": 0, "fraud": 0.0, "succ": "", "cl": {}, "und": {}, "pris": 0, "exile": 0,
		"censor": false, "lib_t": -999, "promise": -1, "reform_t": -999, "fat_t": 0, "cd": {}, "ev_t": -99, "sw_t": -99, "sw_from": "", "log": []}
	var cls := regime_class()
	if cls == "dem":
		return
	var d := democracy_index()
	au["fear"] = clampf((0.6 - d) * 70.0, 0.0, 60.0)
	au["prop"] = clampf((0.6 - d) * 80.0, 0.0, 70.0)
	au["fraud"] = clampf((0.45 - d) * 90.0, 0.0, 45.0) if cls == "hybrid" else 0.0
	au["cult"] = 1 if d < 0.2 else 0
	au["pris"] = int(au["fear"] * 12.0)
	au["base"] = {"fear": au["fear"], "prop": au["prop"], "fraud": au["fraud"], "cult": au["cult"]}
	au_set_class(cls, true)


func au_set_class(cls: String, quiet: bool = false) -> void:
	var old: String = String(au.get("cls", "dem"))
	au["cls"] = cls
	if cls == "dem":
		au["cl"] = {}
		au["und"] = {}
		if not quiet:
			au["sw_t"] = turn
			au["sw_from"] = old
		return
	var cl := {}
	var oldcl: Dictionary = au.get("cl", {})
	for c in AU_CLANS[cls]:
		var id: String = String(c[0])
		var loy: float = 58.0 if String(c[3]) == "force" else 55.0
		if oldcl.has(id):
			loy = float(oldcl[id]["loy"])
		cl[id] = {"loy": loy, "w": float(c[4]), "b": 0.0}
	au["cl"] = cl
	var und := {}
	var oldund: Dictionary = au.get("und", {})
	var tot_old := 0.0
	for k in oldund:
		tot_old += float(oldund[k]["s"])
	for u in AU_UNDER[cls]:
		var s0: float = 18.0 if cls == "hybrid" else 28.0
		if oldund.size() > 0:
			s0 = tot_old / float(oldund.size())
		und[String(u[0])] = {"s": s0}
	au["und"] = und
	if old == "dem" and cls != "hybrid":
		au["fear"] = maxf(float(au["fear"]), 30.0)
		au["prop"] = maxf(float(au["prop"]), 25.0)
	if not quiet:
		au["sw_t"] = turn
		au["sw_from"] = old
		au["fat_t"] = turn
		if cls != "dem":
			log_line("[color=%s][b]%s.[/b] Теперь власть держится на кланах: %s. Раздел «Политика» перестроен под новый режим.[/color]" % [COL_WARN, au_class_name(cls),
				", ".join((AU_CLANS[cls] as Array).map(func(c: Array) -> String: return String(c[1])))])


func au_clan_def(id: String) -> Array:
	for c in AU_CLANS.get(String(au.get("cls", "")), []):
		if String(c[0]) == id:
			return c
	return []


func au_und_def(id: String) -> Array:
	for u in AU_UNDER.get(String(au.get("cls", "")), []):
		if String(u[0]) == id:
			return u
	return []


func au_type_loy(kind: String) -> float:
	var s := 0.0
	var n := 0.0
	for id in au.get("cl", {}):
		var c := au_clan_def(String(id))
		if c.size() > 0 and String(c[3]) == kind:
			s += float(au["cl"][id]["loy"]) * float(au["cl"][id]["w"])
			n += float(au["cl"][id]["w"])
	return s / n if n > 0.0 else 50.0


func au_lib() -> bool:
	return turn - int(au.get("lib_t", -999)) < 24


func au_und_total() -> float:
	var s := 0.0
	for k in au.get("und", {}):
		s += float(au["und"][k]["s"])
	return s


func au_und_max() -> float:
	var s := 0.0
	for k in au.get("und", {}):
		s = maxf(s, float(au["und"][k]["s"]))
	return s


# целевая лояльность клана: общий фон (рейтинг, рост) + интерес клана + награды и обиды
func au_clan_target(id: String) -> float:
	var c := au_clan_def(id)
	if c.is_empty():
		return 50.0
	var e: Dictionary = au["cl"][id]
	var g: float = clampf(growth, -5.0, 5.0)
	var t: float = 50.0 + (approval() - 45.0) * 0.30 + g * 1.5 + float(e["b"])
	var fear: float = float(au["fear"])
	var lib: float = 1.0 if au_lib() else 0.0
	match String(c[3]):
		"force":
			var army_r: float = float(pol["army"]) / maxf(0.1, float(pol_def["army"]))
			t += (float(support["Силовики"]) - 50.0) * 0.35 + clampf((army_r - 1.0) * 25.0, -10.0, 10.0) + fear * 0.05 - lib * 8.0
		"money":
			var ei := econ_id()
			t += (float(support["Бизнес"]) - 50.0) * 0.35 + g * 1.5 - shortage * 0.2 + (4.0 if ei in ["market", "libertarian"] else (-8.0 if ei == "planned" else 0.0))
		"reg":
			t -= (reg_avg("unrest") - 25.0) * 0.4
		"apparat":
			t += float(au["cult"]) * 2.0 + clampf((capital - 40.0) * 0.1, -6.0, 6.0)
		"ideo_c":
			t += fear * 0.08 + float(au["prop"]) * 0.05 - lib * 10.0
		"ideo_r":
			t += -fear * 0.10 + lib * 12.0 - float(au["cult"]) * 2.0 + (6.0 if turn - int(au.get("reform_t", -999)) < 24 else 0.0)
	return clampf(t, 5.0, 95.0)


func au_und_target() -> float:
	var t: float = 10.0 + maxf(0.0, 50.0 - approval()) * 0.9 + float(au["fraud"]) * 0.25 - float(au["fear"]) * 0.45 + shortage * 0.2 + maxf(0.0, -growth) * 3.0
	if au_lib():
		t += 15.0
	if bool(au.get("censor", false)):
		t -= 6.0
	if au_auth():
		t += 5.0
	if String(au["cls"]) == "junta" and int(au.get("promise", -1)) > 0 and turn > int(au["promise"]):
		t += 25.0
	return clampf(t, 0.0, 100.0)


func au_step() -> void:
	if au.is_empty():
		au_init()
	var cls := regime_class()
	if cls != String(au["cls"]):
		au_set_class(cls)
	if cls == "dem":
		au["fear"] = float(au["fear"]) * 0.9
		au["prop"] = float(au["prop"]) * 0.9
		au["fraud"] = float(au["fraud"]) * 0.9
		au["pris"] = int(float(au["pris"]) * 0.8)
		return
	# лояльность и влияние кланов
	var cl: Dictionary = au["cl"]
	var wsum := 0.0
	for id in cl:
		var e: Dictionary = cl[id]
		e["loy"] = clampf(float(e["loy"]) + (au_clan_target(String(id)) - float(e["loy"])) * 0.08, 0.0, 100.0)
		e["b"] = float(e["b"]) * 0.93
		var w0: float = float(au_clan_def(String(id))[4])
		e["w"] = float(e["w"]) + (w0 - float(e["w"])) * 0.02
		wsum += float(e["w"])
	for id in cl:
		cl[id]["w"] = float(cl[id]["w"]) / maxf(0.01, wsum)
	# страх и пропаганда постепенно выветриваются, политзаключённых понемногу выпускают
	# страх и пропаганда сползают к «фону» аппарата: у сложившегося режима — к стартовому уровню, у нового — к 15
	var bs: Dictionary = au.get("base", {})
	var ff: float = maxf(float(bs.get("fear", 0.0)), 15.0 if au_auth() else 0.0)
	var pf: float = maxf(float(bs.get("prop", 0.0)), 15.0 if au_auth() else 0.0)
	au["fear"] = float(au["fear"]) + (ff - float(au["fear"])) * 0.015
	au["prop"] = float(au["prop"]) + (pf - float(au["prop"])) * 0.01
	au["pris"] = int(float(au["pris"]) * 0.99)
	var ut := au_und_target()
	for k in au["und"]:
		var u: Dictionary = au["und"][k]
		var tk: float = ut + (8.0 if String(k) in ["exile", "media"] and bool(au.get("censor", false)) else 0.0)
		u["s"] = clampf(float(u["s"]) + (tk - float(u["s"])) * 0.06, 0.0, 100.0)
	# последствия: силовики и бизнес чувствуют настроение своих кланов, страх гасит протест, фальсификации злят молодёжь
	add_support("Силовики", (au_type_loy("force") - 50.0) * 0.01)
	add_support("Бизнес", (au_type_loy("money") - 50.0) * 0.008)
	add_support("Молодёжь", -float(au["fear"]) * 0.004 - float(au["fraud"]) * 0.002 - (0.05 if bool(au.get("censor", false)) else 0.0))
	var supp: float = float(au["fear"]) * (0.008 if au_auth() else 0.004)
	var rloy: float = au_type_loy("reg")
	for r in regions:
		r["unrest"] = clampf(float(r["unrest"]) - supp + (50.0 - rloy) * 0.004 + au_und_max() * 0.002, 0.0, 100.0)
	if int(au["cult"]) > 0:
		capital += float(au["cult"]) * 0.15
	# хунта обещала уйти — и не ушла
	if String(au["cls"]) == "junta" and int(au.get("promise", -1)) > 0 and turn == int(au["promise"]):
		log_line("[color=%s][b]Срок обещания хунты истёк.[/b] Власть не передана гражданским — недовольство резко растёт.[/color]" % COL_BAD)
		regime_risk = minf(100.0, regime_risk + 20.0)
	if observer:
		au_ai()
	au_events()


# угроза режиму от недовольных кланов и подполья (добавляется к риску переворота)
func au_risk_add() -> float:
	if not au_on():
		return 0.0
	var r := 0.0
	for id in au["cl"]:
		var e: Dictionary = au["cl"][id]
		r += float(e["w"]) * maxf(0.0, 50.0 - float(e["loy"])) * 0.6
	for k in au["und"]:
		r += maxf(0.0, float(au["und"][k]["s"]) - 30.0) * 0.12
	if String(au.get("succ", "")) != "":
		r -= 4.0
	return r


# месяцы «усталости от правителя»: сбрасываются преемником и референдумом
func au_fat_months() -> int:
	if au.is_empty():
		return regime_t
	return mini(regime_t, turn - int(au.get("fat_t", 0)))


func au_dyn() -> void:
	if not au_on() or mods.is_empty():
		return
	# эффекты считаются от стартового уровня: то, что было в стране с начала игры, уже заложено в её показатели
	var bs: Dictionary = au.get("base", {})
	var fear: float = float(au["fear"]) - float(bs.get("fear", 0.0))
	var fraud: float = float(au["fraud"]) - float(bs.get("fraud", 0.0))
	var cult: float = float(au["cult"]) - float(bs.get("cult", 0.0))
	var prop: float = float(au["prop"]) - float(bs.get("prop", 0.0))
	mods["growth_bonus"] = float(mods["growth_bonus"]) + (au_type_loy("money") - 55.0) * 0.004 - fear * 0.002 - (0.05 if bool(au.get("censor", false)) else 0.0) \
		+ (0.2 if String(au["cls"]) == "oneparty" and turn - int(au.get("reform_t", -999)) < 24 else 0.0)
	mods["corr_shift"] = float(mods["corr_shift"]) + maxf(0.0, 50.0 - au_type_loy("apparat")) * 0.05 + cult * 0.5
	mods["mood_shift"] = float(mods["mood_shift"]) + prop * 0.002 - fraud * 0.001
	mods["dem_shift"] = float(mods.get("dem_shift", 0.0)) - fear * 0.0012 - fraud * 0.001 - cult * 0.01 - (0.03 if bool(au.get("censor", false)) else 0.0)


# официальный рейтинг (то, что показывают государственные СМИ и «правильные» опросы)
func au_official_approval() -> float:
	var a := approval()
	if not au_on():
		return a
	return minf(97.0, a + float(au["prop"]) * 0.25 + float(au["fear"]) * 0.15 + (8.0 if au_auth() else 0.0))


# выборы в гибридном режиме: «административный ресурс» переносит часть голосов к партии власти
func au_fraud_shares(sh: Array[float]) -> Array[float]:
	if not au_on() or opp_mode or sh.is_empty() or sh[0] <= 0.0001:
		return sh
	# официальные итоги прошлых выборов уже включают «привычный» уровень приписок — считаем только сверх него
	var f: float = (float(au["fraud"]) - float((au.get("base", {}) as Dictionary).get("fraud", 0.0))) * 0.003
	if f <= 0.0005:
		return sh
	var out: Array[float] = []
	var rest := 0.0
	for p in range(1, sh.size()):
		rest += sh[p]
	var mv: float = minf(rest * 0.6, f)
	out.append(sh[0] + mv)
	for p in range(1, sh.size()):
		out.append(sh[p] - (mv * sh[p] / rest if rest > 0.0 else 0.0))
	return out


func au_after_election() -> void:
	if not au_on():
		return
	var f: float = float(au["fraud"]) - float((au.get("base", {}) as Dictionary).get("fraud", 0.0)) * 0.5
	if f < 20.0:
		return
	for r in regions:
		r["unrest"] = clampf(float(r["unrest"]) + f * 0.05, 0.0, 100.0)
	for k in au["und"]:
		au["und"][k]["s"] = clampf(float(au["und"][k]["s"]) + f * 0.15, 0.0, 100.0)
	dip_all(-f * 0.04, true)
	log_line("[color=%s]Наблюдатели фиксируют вбросы и «карусели»: в городах протесты против фальсификаций, демократии не признают итоги.[/color]" % COL_WARN)


# ---------- рычаги ----------
func au_act_def(id: String) -> Array:
	for a in AU_ACTS:
		if String(a[0]) == id:
			return a
	return []


func au_check(id: String) -> String:
	var why := pl_why("gov")
	if why != "":
		return why
	if game_over:
		return "игра окончена"
	if not au_on():
		return "при демократии эти рычаги недоступны"
	var parts := id.split(":")
	var base: String = parts[0]
	if base == "reward" or base == "purge":
		var cid: String = parts[1] if parts.size() > 1 else ""
		if not (au["cl"] as Dictionary).has(cid):
			return "нет такого клана"
		var cost: float = 6.0 if base == "reward" else 8.0
		if capital < cost:
			return "нужно %.0f капитала" % cost
		if int(au["cd"].get(id, -99)) > turn:
			return "ещё %d мес." % (int(au["cd"][id]) - turn)
		if base == "purge" and au_type_loy("force") < 30.0 and String(au_clan_def(cid)[3]) != "force":
			return "силовики ненадёжны — проводить чистку некому"
		return ""
	var a := au_act_def(base)
	if a.is_empty():
		return "неизвестное действие"
	var cls_req: String = String(a[4])
	if cls_req != "" and not (String(au["cls"]) in cls_req.split(",")):
		return "только для режима: %s" % ", ".join(Array(cls_req.split(",")).map(func(x: String) -> String: return au_class_name(x)))
	if capital < float(a[2]):
		return "нужно %.0f капитала" % float(a[2])
	if int(au["cd"].get(base, -99)) > turn:
		return "ещё %d мес." % (int(au["cd"][base]) - turn)
	match base:
		"cult":
			if int(au["cult"]) >= 5:
				return "культ уже на высшей ступени"
		"decult":
			if int(au["cult"]) <= 0:
				return "культа личности нет"
		"prop_up":
			if float(au["prop"]) >= 95.0:
				return "пропаганда уже повсюду"
		"prop_dn":
			if float(au["prop"]) <= 1.0:
				return "пропаганды почти нет"
		"fraud_up":
			if float(au["fraud"]) >= 90.0:
				return "больше подделывать некуда"
		"fraud_dn":
			if float(au["fraud"]) <= 1.0:
				return "выборы и так честные"
		"amnesty":
			if int(au["pris"]) < 10:
				return "политзаключённых почти нет"
		"succ":
			if String(au.get("succ", "")) != "":
				return "преемник уже назван"
		"promise":
			if int(au.get("promise", -1)) > 0:
				return "обещание уже дано"
		"roundtable":
			if au_und_max() < 25.0 and approval() > 45.0:
				return "оппозиция слишком слаба, чтобы садиться с ней за стол"
	return ""


func au_cd(id: String, months: int) -> void:
	if months > 0:
		au["cd"][id] = turn + months


func au_clan_add(id: String, b: float, wmul: float = 1.0) -> void:
	var cl: Dictionary = au["cl"]
	if not cl.has(id):
		return
	cl[id]["b"] = float(cl[id]["b"]) + b
	cl[id]["loy"] = clampf(float(cl[id]["loy"]) + b * 0.4, 0.0, 100.0)
	if wmul != 1.0:
		cl[id]["w"] = float(cl[id]["w"]) * wmul
		var s := 0.0
		for k in cl:
			s += float(cl[k]["w"])
		for k in cl:
			cl[k]["w"] = float(cl[k]["w"]) / maxf(0.01, s)


func au_clan_of_kind(kind: String) -> Array:
	var out: Array = []
	for id in au.get("cl", {}):
		var c := au_clan_def(String(id))
		if c.size() > 0 and String(c[3]) == kind:
			out.append(String(id))
	return out


func au_und_add(d: float, only: String = "") -> void:
	for k in au["und"]:
		if only == "" or String(k) == only:
			au["und"][k]["s"] = clampf(float(au["und"][k]["s"]) + d, 0.0, 100.0)


func au_act(id: String) -> bool:
	var why := au_check(id)
	if why != "":
		log_line("[color=%s]Нельзя: %s.[/color]" % [COL_WARN, why])
		return false
	var parts := id.split(":")
	var base: String = parts[0]
	var txt := ""
	if base == "reward" or base == "purge":
		var cid: String = parts[1]
		var cname: String = String(au_clan_def(cid)[1])
		if base == "reward":
			capital -= 6.0
			debt += gdp * 0.001
			au_clan_add(cid, 14.0, 1.12)
			for k in au["cl"]:
				if String(k) != cid:
					au_clan_add(String(k), -2.0)
			au_cd(id, 3)
			txt = "Клан «%s» получил должности, контракты и привилегии (0,1%% ВВП): лояльность растёт, остальные ревнуют." % cname
		else:
			capital -= 8.0
			var was_low: bool = float(au["cl"][cid]["loy"]) < 30.0
			au_clan_add(cid, -10.0, 0.6)
			for k in au["cl"]:
				if String(k) != cid:
					au_clan_add(String(k), 4.0)
			au["fear"] = minf(100.0, float(au["fear"]) + 10.0)
			au["pris"] = int(au["pris"]) + 40
			lvl["corruption"] = clampf(float(lvl["corruption"]) - 2.0, 0.0, 100.0)
			au_cd(id, 6)
			txt = "Чистка в клане «%s»: аресты, отставки, конфискации. Влияние клана упало, остальные притихли." % cname
			if was_low and randf() < 0.25:
				regime_risk = minf(100.0, regime_risk + 12.0)
				txt += " [color=%s]Загнанный в угол клан ответил попыткой мятежа — её подавили, но режим пошатнулся.[/color]" % COL_BAD
		au_log(txt)
		return true
	var a := au_act_def(base)
	capital -= float(a[2])
	au_cd(base, int(a[3]))
	match base:
		"arrests":
			au["fear"] = minf(100.0, float(au["fear"]) + 12.0)
			au["pris"] = int(au["pris"]) + int(60.0 + au_und_total() * 2.0)
			au_und_add(-12.0)
			add_support("Молодёжь", -3.0)
			dip_all(-2.0, true)
			txt = "Волна арестов: страх растёт, подполье теряет людей. Политзаключённых — %d." % int(au["pris"])
		"amnesty":
			au["pris"] = int(float(au["pris"]) * 0.2)
			au["fear"] = maxf(0.0, float(au["fear"]) - 12.0)
			au_und_add(4.0)
			for g in GROUPS:
				add_support(g, 1.5)
			dip_all(3.0, true)
			txt = "Амнистия: политзаключённые на свободе. Общество вздохнуло, но подполье получило своих лидеров обратно."
		"prop_up":
			au["prop"] = minf(100.0, float(au["prop"]) + 12.0)
			debt += gdp * 0.0005
			add_support("Молодёжь", -1.0)
			txt = "Государственные СМИ и блогеры получили новые бюджеты: пропаганда %.0f из 100." % float(au["prop"])
		"prop_dn":
			au["prop"] = maxf(0.0, float(au["prop"]) - 15.0)
			dip_all(1.0, true)
			txt = "Пропагандистские программы урезаны: пропаганда %.0f из 100." % float(au["prop"])
		"censor":
			au["censor"] = not bool(au.get("censor", false))
			if bool(au["censor"]):
				au_und_add(-6.0)
				au["prop"] = minf(100.0, float(au["prop"]) + 6.0)
				add_support("Молодёжь", -3.0)
				dip_all(-2.0, true)
				txt = "Введена цензура интернета: блокировки соцсетей, VPN вне закона."
			else:
				add_support("Молодёжь", 2.0)
				dip_all(1.5, true)
				txt = "Цензура интернета отменена."
		"cult":
			au["cult"] = int(au["cult"]) + 1
			for k in au_clan_of_kind("apparat"):
				au_clan_add(k, 8.0)
			for k in au_clan_of_kind("ideo_r"):
				au_clan_add(k, -6.0)
			add_support("Молодёжь", -2.0)
			txt = "Портреты на каждом углу: культ личности — ступень %d из 5." % int(au["cult"])
		"decult":
			au["cult"] = int(au["cult"]) - 1
			for k in au_clan_of_kind("ideo_r"):
				au_clan_add(k, 6.0)
			for k in au_clan_of_kind("apparat"):
				au_clan_add(k, -6.0)
			txt = "Культ личности приглушён: ступень %d из 5." % int(au["cult"])
		"fraud_up":
			au["fraud"] = minf(100.0, float(au["fraud"]) + 15.0)
			dip_all(-2.0, true)
			au_und_add(3.0)
			txt = "Избиркомам даны «рекомендации»: фальсификации %.0f из 100." % float(au["fraud"])
		"fraud_dn":
			au["fraud"] = maxf(0.0, float(au["fraud"]) - 15.0)
			dip_all(2.0, true)
			txt = "Наблюдатели допущены на участки: фальсификации %.0f из 100." % float(au["fraud"])
		"succ":
			var best := ""
			var bw := -1.0
			for k in au["cl"]:
				if float(au["cl"][k]["w"]) > bw:
					bw = float(au["cl"][k]["w"])
					best = String(k)
			au["succ"] = best
			au["fat_t"] = turn
			au_clan_add(best, 10.0, 1.1)
			for k in au["cl"]:
				if String(k) != best:
					au_clan_add(String(k), -4.0)
			txt = "Назван преемник — выходец из клана «%s». Элиты знают, что будет дальше, усталость от правителя снята." % String(au_clan_def(best)[1])
		"lib":
			au["lib_t"] = turn
			au["fear"] = maxf(0.0, float(au["fear"]) - 20.0)
			au["prop"] = maxf(0.0, float(au["prop"]) - 10.0)
			au["fraud"] = maxf(0.0, float(au["fraud"]) - 15.0)
			au["cult"] = maxi(0, int(au["cult"]) - 1)
			au["pris"] = int(float(au["pris"]) * 0.3)
			for k in au_clan_of_kind("ideo_r"):
				au_clan_add(k, 10.0)
			for k in au_clan_of_kind("force"):
				au_clan_add(k, -8.0)
			add_support("Молодёжь", 4.0)
			dip_all(4.0, true)
			regime_risk = minf(100.0, regime_risk + 5.0)
			txt = "Оттепель: цензура мягче, часть заключённых на свободе, на кухнях спорят открыто. Силовики насторожены."
		"roundtable":
			au_und_add(-30.0)
			au["fear"] = maxf(0.0, float(au["fear"]) - 10.0)
			au_log("Круглый стол с оппозицией: договорились о свободных выборах и новой конституции.")
			au_set_gov("")
			return true
		"promise":
			au["promise"] = turn + 24
			regime_risk = maxf(0.0, regime_risk - 12.0)
			dip_all(6.0, true)
			au_und_add(-10.0)
			txt = "Хунта обещала передать власть гражданскому правительству через 2 года. Мир ждёт, подполье выжидает."
		"constitution":
			for k in au_clan_of_kind("apparat") + au_clan_of_kind("ideo_c"):
				au_clan_add(k, -8.0)
			au_und_add(-40.0, "const")
			dip_all(8.0, true)
			au_log("Монарх даровал конституцию: власть разделена с парламентом.")
			au_set_gov("monarchy_const")
			return true
		"plenum_c":
			for k in au_clan_of_kind("ideo_c") + au_clan_of_kind("force"):
				au_clan_add(k, 12.0, 1.08)
			for k in au_clan_of_kind("ideo_r"):
				au_clan_add(k, -10.0, 0.85)
			au["fear"] = minf(100.0, float(au["fear"]) + 5.0)
			txt = "Пленум ЦК взял консервативный курс: реформаторы выведены из Политбюро."
		"plenum_r":
			au["reform_t"] = turn
			for k in au_clan_of_kind("ideo_r"):
				au_clan_add(k, 12.0, 1.15)
			for k in au_clan_of_kind("ideo_c"):
				au_clan_add(k, -10.0)
			au_und_add(-5.0)
			txt = "Пленум ЦК объявил курс на реформы: хозрасчёт, кооперативы, гласность в разумных пределах."
		"fatwa":
			for k in au_clan_of_kind("ideo_c"):
				au_clan_add(k, 12.0)
			for k in au_clan_of_kind("force"):
				au_clan_add(k, 6.0)
			add_support("Молодёжь", -4.0)
			au_und_add(8.0, "women")
			au["fear"] = minf(100.0, float(au["fear"]) + 6.0)
			txt = "Духовный совет издал указ о нравах: стражи веры на улицах."
		"referendum":
			au["fat_t"] = turn
			au["fraud"] = minf(100.0, float(au["fraud"]) + 10.0)
			au_und_add(6.0)
			dip_all(-3.0, true)
			txt = "Референдум одобрил продление полномочий (по официальным данным — %.0f%% «за»)." % minf(97.0, au_official_approval() + 15.0)
	au_log(txt)
	return true


func au_log(txt: String) -> void:
	if txt == "":
		return
	log_line("[color=%s]Режим: %s[/color]" % [COL_WARN, txt])
	(au["log"] as Array).push_front("%s — %s" % [date_short(), txt])
	if (au["log"] as Array).size() > 12:
		(au["log"] as Array).resize(12)


# смена формы правления указом ("" — возврат к исходной демократической форме)
func au_set_gov(rid: String) -> void:
	if not law_index.has("gov_form"):
		return
	var vs: Array = law_index["gov_form"]["v"]
	var idx := 0
	if rid != "":
		for k in vs.size():
			if String((vs[k] as Dictionary).get("rid", "")) == rid:
				idx = k
	var cur := cur_idx("gov_form")
	if idx == cur:
		return
	var old_rid := rid_of("gov_form")
	var std := dict_diff(variant_part("gov_form", cur, "st"), variant_part("gov_form", idx, "st", true))
	for k in std:
		lvl[k] = clampf(float(lvl[k]) + float(std[k]), 0.0, 100.0)
	law_state["gov_form"] = idx
	law_cd["gov_form"] = 24
	radical_enact("gov_form", idx, old_rid)
	if rid_of("state_church") == "theocracy" and law_index.has("state_church"):
		law_state["state_church"] = 0
	recompute_mods()
	regime_risk = 0.0
	au_set_class(regime_class())
	dip_all(10.0, true)
	if regime_class() != "dem":
		return
	last_parl = turn - parl_term()
	log_line("[color=%s][b]Переход к демократии.[/b] Назначены свободные выборы, партии снова легальны.[/color]" % COL_GOOD)


# ---------- события режима ----------
func au_events() -> void:
	if not current_event.is_empty() or turn - int(au.get("ev_t", -99)) < 8:
		return
	# недовольный сильный клан
	var worst := ""
	var wl := 100.0
	for id in au["cl"]:
		var e: Dictionary = au["cl"][id]
		if float(e["w"]) >= 0.2 and float(e["loy"]) < wl:
			wl = float(e["loy"])
			worst = String(id)
	if worst != "" and wl < 28.0 and randf() < 0.25:
		au["ev_t"] = turn
		au_event_clan(worst)
		return
	if au_und_max() > 65.0 and randf() < 0.15:
		au["ev_t"] = turn
		au_event_protest()


func au_event_clan(id: String) -> void:
	var c := au_clan_def(id)
	var nm: String = String(c[1])
	var t := ""
	var o: Array = []
	match String(c[3]):
		"force":
			t = "%s недовольны: зарплаты не растут, генералов обходят наградами, в штабах говорят о «спасении страны»." % nm
			o = [{"l": "Повысить довольствие и наградить (капитал −6)", "fx": {"capital": -6.0, "debt": 0.2, "au": {"clan": id, "b": 18.0}}},
				{"l": "Сменить командование (чистка): риск мятежа", "fx": {"capital": -5.0, "au": {"clan": id, "b": -6.0, "w": 0.6, "fear": 8.0, "risk": 6.0}}},
				{"l": "Ничего не делать", "fx": {"au": {"clan": id, "b": -5.0, "risk": 10.0}}}]
		"money":
			t = "%s выводят капиталы за рубеж и скупают валюту: им не нравится курс власти." % nm
			o = [{"l": "Гарантии собственности и налоговые льготы (капитал −5)", "fx": {"capital": -5.0, "support": {"Бизнес": 3.0}, "au": {"clan": id, "b": 16.0}}},
				{"l": "Национализировать активы непокорных", "fx": {"au": {"clan": id, "b": -10.0, "w": 0.5, "fear": 6.0, "risk": 5.0}, "support": {"Бизнес": -6.0, "Рабочие": 2.0}}},
				{"l": "Пусть уезжают", "fx": {"au": {"clan": id, "b": -4.0}, "support": {"Бизнес": -3.0}}}]
		"reg":
			t = "%s саботируют указы центра и требуют денег и самостоятельности." % nm
			o = [{"l": "Увеличить трансферты регионам (0,3% ВВП)", "fx": {"debt": 0.3, "au": {"clan": id, "b": 16.0}}},
				{"l": "Заменить губернаторов назначенцами из центра", "fx": {"capital": -4.0, "au": {"clan": id, "b": -8.0, "w": 0.7, "fear": 4.0}, "regall": {"unrest": 3.0}}},
				{"l": "Ничего не делать", "fx": {"au": {"clan": id, "b": -4.0, "risk": 6.0}}}]
		_:
			t = "%s раскалываются: часть открыто критикует курс и ищет нового покровителя." % nm
			o = [{"l": "Должности и привилегии (капитал −5)", "fx": {"capital": -5.0, "au": {"clan": id, "b": 15.0}}},
				{"l": "Кадровая чистка", "fx": {"capital": -4.0, "au": {"clan": id, "b": -8.0, "w": 0.65, "fear": 6.0, "risk": 4.0}}},
				{"l": "Ничего не делать", "fx": {"au": {"clan": id, "b": -4.0, "risk": 6.0}}}]
	current_event = {"t": "[b]Кризис в верхушке.[/b] " + t, "o": o}
	event_region = -1
	present_event()


func au_event_protest() -> void:
	var best := ""
	var bs := 0.0
	for k in au["und"]:
		if float(au["und"][k]["s"]) > bs:
			bs = float(au["und"][k]["s"])
			best = String(k)
	var nm: String = String(au_und_def(best)[1]) if best != "" else "Подполье"
	current_event = {"t": "[b]Улица против режима.[/b] %s вывели людей на площади: десятки тысяч, лозунги против власти, полиция колеблется." % nm, "o": [
		{"l": "Разогнать и арестовать зачинщиков", "fx": {"capital": -4.0, "regall": {"unrest": -6.0}, "support": {"Молодёжь": -4.0}, "au": {"fear": 12.0, "und": -15.0, "pris": 300, "risk": 4.0}}},
		{"l": "Пойти на уступки: отставка одиозных чиновников", "fx": {"capital": -8.0, "all": 2.0, "regall": {"unrest": -4.0}, "au": {"und": -8.0, "fear": -6.0}}},
		{"l": "Переждать", "fx": {"regall": {"unrest": 5.0}, "au": {"und": 5.0, "risk": 6.0}}}]}
	event_region = -1
	present_event()


func au_fx(d: Dictionary) -> void:
	if not au_on():
		return
	if d.has("clan"):
		au_clan_add(String(d["clan"]), float(d.get("b", 0.0)), float(d.get("w", 1.0)))
	if d.has("fear"):
		au["fear"] = clampf(float(au["fear"]) + float(d["fear"]), 0.0, 100.0)
	if d.has("und"):
		au_und_add(float(d["und"]))
	if d.has("pris"):
		au["pris"] = int(au["pris"]) + int(d["pris"])
	if d.has("risk"):
		regime_risk = clampf(regime_risk + float(d["risk"]), 0.0, 100.0)


# режим за наблюдателя: ИИ награждает самый нелояльный клан и сажает подполье, если оно крепнет
func au_ai() -> void:
	if turn % 3 != 0:
		return
	var worst := ""
	var wl := 100.0
	for id in au["cl"]:
		if float(au["cl"][id]["loy"]) < wl:
			wl = float(au["cl"][id]["loy"])
			worst = String(id)
	if worst != "" and wl < 40.0 and au_check("reward:" + worst) == "":
		au_act("reward:" + worst)
	elif au_und_max() > 55.0 and au_check("arrests") == "":
		au_act("arrests")
