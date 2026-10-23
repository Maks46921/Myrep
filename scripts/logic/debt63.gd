# Финансы (0.63): госдолг (срок, средняя ставка, иностранные держатели, валютный долг, аукционы), дефолт и реструктуризация, МВФ, фонды.
extends "res://scripts/logic/bank63.gd"

const FIN_COND := {
	"deficit": {"n": "сократить дефицит", "d": "дефицит бюджета постепенно до 3% ВВП"},
	"pension": {"n": "пенсионная реформа", "d": "повысить пенсионный возраст хотя бы на один уровень"},
	"tax": {"n": "налоговая реформа", "d": "поднять НДС и подоходный налог в сумме хотя бы на 1 п.п."},
	"priv": {"n": "приватизация", "d": "продать госкомпании не меньше чем на 1% ВВП (IPO на бирже)"},
}


# ============================================================
#  СТАВКА ПО ДОЛГУ
# ============================================================
# надбавка к ставке по госдолгу сверх прежней формулы, п.п.: недоверие рынков, память о дефолте, закрытые рынки, неудачные аукционы
func fin_prem() -> float:
	if not fin_on():
		return 0.0
	var db: Dictionary = fin["db"]
	var imf: Dictionary = fin["imf"]
	var p := 0.0
	p += maxf(0.0, (60.0 - float(fin["mood"])) * 0.05)
	p += float(db["hot"]) * 2.0
	if int(db["closed_t"]) > turn:
		p += 4.0
	p += float(db["auc_pen"])
	if int(imf["st"]) == 2:
		p -= 2.0
	if fin_euro_member():
		p *= 0.6
	return maxf(p, -2.0)


# ставка, по которой обслуживается долг (с учётом средневзвешенной ставки и выкупа ЦБ)
func fin_debt_rate() -> float:
	var db: Dictionary = fin["db"]
	var qe_share: float = clampf(float(fin["cb"]["qe"]) / 100.0 * gdp / maxf(debt, 1.0), 0.0, 0.5)
	return maxf(float(db["avg"]) * (1.0 - qe_share), 0.005)


func fin_debt_step() -> void:
	var db: Dictionary = fin["db"]
	var ratio: float = debt / maxf(gdp, 1.0) * 100.0
	var mkt: float = debt_mkt_rate()
	db["mkt"] = mkt
	db["spr"] = (mkt - float(MACRO.get("debt_base", 0.014)) - (float(ec["rate"]) - RATE0) / 100.0 * 0.35) * 100.0
	# средняя ставка: долг перекладывается постепенно (срок), плюс плавающая часть и новые заимствования
	var refi: float = wdt / (float(db["mat"]) * 12.0) + maxf(0.0, last_deficit_pct) / 100.0 * gdp / maxf(debt, 1.0) * wdt / 12.0 + 0.12 * rt(0.3, wdt)
	db["avg"] = float(db["avg"]) + (mkt - float(db["avg"])) * clampf(refi, 0.0, 1.0)
	# валютный долг переоценивается вместе с курсом
	var fxs: float = float(ec["fxs"])
	if not db.has("fx_prev"):
		db["fx_prev"] = fxs
	var dfx: float = float(db["fx_prev"]) / fxs - 1.0
	db["dfx"] = dfx
	if absf(dfx) > 0.0 and float(db["fcur"]) > 0.0:
		debt = maxf(0.0, debt * (1.0 + float(db["fcur"]) / 100.0 * clampf(dfx, -0.3, 0.5)))
	db["fx_prev"] = fxs
	# затухание
	db["hot"] = float(db["hot"]) * wdec(0.98)
	db["auc_pen"] = float(db["auc_pen"]) * wdec(0.9)
	db["auc_fail"] = float(db["auc_fail"]) * wdec(0.9)
	# иностранные держатели: уходят при тревоге рынков, давят на курс и резервы
	var mood: float = float(fin["mood"])
	var f_t: float = minf(95.0, float(db["for0"]) * (0.6 + 0.4 * clampf(mood / 60.0, 0.0, 1.3)))
	var f0: float = float(db["for"])
	db["for"] = f0 + (f_t - f0) * rt(0.1, wdt)
	var out: float = f0 - float(db["for"])
	if out > 0.0:
		ec["fx_shock"] = float(ec["fx_shock"]) - out * 0.004
		ec["res"] = float(ec["res"]) - out * ratio / 10000.0 * 0.5
	# аукционы: спрос и ставка
	var closed: bool = int(db["closed_t"]) > turn
	var cover: float = 2.4 * pow(clampf(mood / 60.0, 0.05, 2.0), 1.3) * (1.0 - 0.5 * clampf((ratio - 100.0) / 100.0, 0.0, 1.0)) * (0.5 if closed else 1.0) + fin_rn() * 0.25
	cover = clampf(cover, 0.3, 5.0)
	db["cover"] = cover
	db["auc_rate"] = mkt + maxf(0.0, 2.0 - cover) * 0.006
	db["auc_t"] = turn
	if cover < 1.0 and not closed:
		db["auc_fail"] = float(db["auc_fail"]) + 1.0
		db["auc_pen"] = minf(4.0, float(db["auc_pen"]) + 0.5)
		fin_mood_hit(-4.0)
		if fin_cd("auc_note") == 0:
			fin_cd_set("auc_note", 2)
			fin_note("долг", "Аукцион облигаций провалился: спроса не хватило (покрытие %.1f). Ставки растут." % cover, COL_BAD)
	if closed:
		fin_closed_financing()
	# приближение дефолта
	db["hot_spr"] = float(db.get("hot_spr", 0.0)) + wdt if float(db["spr"]) >= 12.0 else maxf(0.0, float(db.get("hot_spr", 0.0)) - wdt)
	fin_default_check(ratio)
	fin_imf_trigger(ratio)


# закрытые рынки: дефицит покрывают фонды, резервы, а остаток — печатный станок (инфляция)
func fin_closed_financing() -> void:
	var f: Dictionary = fin["fd"]
	var db: Dictionary = fin["db"]
	var need: float = maxf(0.0, last_deficit_pct) * wdt / 12.0
	if need <= 0.0:
		return
	var left: float = need
	for k in ["res", "pen", "own"]:
		var take: float = minf(left, float(f[k]))
		f[k] = float(f[k]) - take
		left -= take
	var use_r: float = minf(left, maxf(0.0, float(ec["res"]) - 3.0))
	ec["res"] = float(ec["res"]) - use_r
	left -= use_r
	debt = maxf(0.0, debt - gdp * need / 100.0)
	if left > 0.0:
		inflation = clampf(inflation + left * 0.5, 0.0, 40.0)
		db["printed"] = float(db.get("printed", 0.0)) + left
		if fin_cd("print_note") == 0:
			fin_cd_set("print_note", 6)
			fin_note("долг", "Рынки закрыты: дефицит покрывается печатным станком, цены растут.", COL_BAD)


func fin_debt_revalue(old: float, nw: float) -> void:
	var db: Dictionary = fin["db"]
	if float(db["fcur"]) > 0.0 and nw > 0.0:
		debt = maxf(0.0, debt * (1.0 + float(db["fcur"]) / 100.0 * clampf(old / nw - 1.0, -0.3, 0.6)))
	db["fx_prev"] = nw


func fin_month_debt() -> void:
	var db: Dictionary = fin["db"]
	if int(db["closed_t"]) == turn:
		fin_note("долг", "Рынки снова открыты для страны: можно занимать, но ставки пока высоки.", COL_GOOD)
	fin_imf_review()


# ============================================================
#  ДЕФОЛТ
# ============================================================
func fin_default_check(ratio: float) -> void:
	var db: Dictionary = fin["db"]
	if bool(db["pend"]) and current_event.is_empty() and not election_open:
		fin_default_event()
		return
	if fin_cd("dflt_ev") > 0 or not current_event.is_empty() or election_open or int(db["closed_t"]) > turn:
		return
	var euro: bool = fin_euro_member()
	var imf_on: bool = int(fin["imf"]["st"]) == 2
	var lim_r: float = (200.0 if euro else 150.0) + (20.0 if imf_on else 0.0)
	var why := ""
	if ratio > lim_r:
		why = "долг вырос до %.0f%% ВВП" % ratio
	elif float(db["auc_fail"]) >= 3.0:
		why = "несколько аукционов подряд провалились"
	elif float(db["hot_spr"]) >= 8.0 and ratio > 100.0:
		why = "ставки по долгу остаются запредельными"
	elif float(ec["res"]) + float(fin["fx"]["swap"]) < 0.0 and float(db["fcur"]) >= 30.0 and ratio > 60.0 and not euro:
		why = "резервы кончились, а платить по валютному долгу нечем"
	if why == "":
		return
	db["why"] = why
	fin_default_event()


func fin_default_event() -> void:
	var db: Dictionary = fin["db"]
	if not current_event.is_empty() or election_open:
		db["pend"] = true
		return
	db["pend"] = false
	fin_cd_set("dflt_ev", 6)
	var why: String = String(db.get("why", "платить по долгу становится невозможно"))
	var opts: Array = [
		{"l": "Реструктуризация: списать 25%% долга по договорённости с кредиторами (рынки закрыты ≈1,5 года, нужны реформы)", "fx": {}, "act": "dflt_restr"},
		{"l": "Частичный дефолт: отсрочка и списание 15%% (рынки закрыты 1–2 года)", "fx": {}, "act": "dflt_part"},
		{"l": "Полный дефолт: списать 50%% долга (рынки закрыты 2,5–4 года, удар по доверию и банкам)", "fx": {}, "act": "dflt_full"},
		{"l": "Просить помощь МВФ и платить дальше", "fx": {}, "act": "dflt_imf"},
		{"l": "Платить любой ценой: жёсткая экономия (рост ниже, недовольство)", "fx": {}, "act": "dflt_pay"}]
	fin_event("debt", "[b]Долговой кризис.[/b] Причина: %s. Долг %.0f%% ВВП, средняя ставка %.1f%%. Дефолт — не конец игры, но тяжёлое испытание. Что делать?" % [why, debt / maxf(gdp, 1.0) * 100.0, float(db["avg"]) * 100.0], opts)


func fin_do_default(kind: String) -> void:
	var db: Dictionary = fin["db"]
	var b: Dictionary = fin["bk"]
	var h: float = {"restr": 0.25, "part": 0.15, "full": 0.5}[kind]
	var yrs: int = {"restr": 18, "part": randi_range(12, 24), "full": randi_range(30, 48)}[kind]
	debt *= 1.0 - h
	default_t = turn
	db["ds"] = {"restr": 1, "part": 1, "full": 2}[kind]
	db["ds_t"] = turn
	db["haircut"] = h
	db["closed_t"] = turn + yrs
	db["rest"] = int(db["rest"]) + 1
	db["hot"] = {"restr": 0.6, "part": 0.5, "full": 1.0}[kind]
	db["auc_fail"] = 0.0
	db["hot_spr"] = 0.0
	db["avg"] = float(db["avg"]) + 0.01
	fin_mood_hit({"restr": -12.0, "part": -15.0, "full": -35.0}[kind])
	risk_prem = minf(2.0, risk_prem + {"restr": 0.5, "part": 0.7, "full": 1.4}[kind])
	b["inj"] = float(b.get("inj", 0.0)) - float(b["sov"]) * h * 0.5
	b["shock"] = float(b["shock"]) + float(b["sov"]) * h * 0.1
	if kind == "full":
		dip_all(-6.0, false)
		add_all_support(-3.0)
	elif kind == "restr":
		add_all_support(-1.5)
	else:
		add_all_support(-2.0)
	fin_note("долг", "%s: долг списан на %.0f%%, рынки закрыты на %d мес." % [{"restr": "Реструктуризация", "part": "Частичный дефолт", "full": "Полный дефолт"}[kind], h * 100.0, yrs], COL_BAD)
	if kind == "restr" or kind == "part":
		fin_imf_offer("debt")


func fin_act_debt(id: String, opt: Dictionary) -> bool:
	var db: Dictionary = fin["db"]
	match id:
		"dflt_restr":
			fin_do_default("restr")
		"dflt_part":
			fin_do_default("part")
		"dflt_full":
			fin_do_default("full")
		"dflt_imf":
			fin_cd_set("dflt_ev", 6)
			fin_imf_offer("debt")
		"dflt_pay":
			fin_cd_set("dflt_ev", 8)
			shock -= 1.0
			add_all_support(-4.0)
			db["auc_fail"] = 0.0
			db["hot_spr"] = 0.0
			fin_mood_hit(5.0)
			fin_note("долг", "Власть выбрала платить любой ценой: расходы урезаны, рост ниже, население недовольно.", COL_WARN)
		"dflt_open":
			db["why"] = "вы сами решили пересмотреть долг"
			db["pend"] = true
			fin_cd_set("dflt_ev", 0)
		"imf_ask":
			fin_imf_offer("ask")
		"imf_stop":
			fin["imf"]["st"] = 3
			fin_cd_set("imf_ev", 36)
			fin_mood_hit(-4.0)
			fin_note("мвф", "Программа МВФ прекращена по вашему решению.", COL_WARN)
		"debt_mat":
			db["mat"] = minf(20.0, float(db["mat"]) + 1.0)
			db["avg"] = float(db["avg"]) + 0.002
			fin_note("долг", "Размещены длинные облигации: срок долга %.1f лет." % float(db["mat"]), COL_DIM)
		"debt_fcur":
			db["fcur"] = maxf(0.0, float(db["fcur"]) - 10.0)
			db["avg"] = float(db["avg"]) + 0.004
			fin_note("долг", "Часть валютного долга переведена в национальную валюту.", COL_DIM)
		"imf_yes", "imf_cn", "imf_ally", "imf_no":
			fin_imf_choice(id)
		_:
			return false
	return true


func fin_acts_debt() -> Array:
	var out: Array = []
	var db: Dictionary = fin["db"]
	var imf: Dictionary = fin["imf"]
	var ratio: float = debt / maxf(gdp, 1.0) * 100.0
	out.append({"id": "debt_mat", "grp": "Долг", "name": "Удлинить срок долга (+1 год)", "cap": 4.0, "cd": 12, "ok": float(db["mat"]) < 20.0, "why": "предел", "desc": "Длинные облигации: меньше риск, что придётся занимать в плохое время, но чуть дороже. Сейчас срок %.1f лет%s." % [float(db["mat"]), fin_est_note("mat")]})
	out.append({"id": "debt_fcur", "grp": "Долг", "name": "Снизить долг в иностранной валюте (−10 п.п.)", "cap": 4.0, "cd": 12, "ok": float(db["fcur"]) > 0.0, "why": "валютного долга нет", "desc": "Перевести долг в национальную валюту: удар курса по долгу слабее, но ставка выше. Сейчас %.0f%% долга в валюте%s." % [float(db["fcur"]), fin_est_note("fcur")]})
	out.append({"id": "dflt_open", "grp": "Дефолт", "name": "Пересмотреть долг: реструктуризация или дефолт", "cap": 10.0, "cd": 24, "ok": ratio > 90.0 and int(db["closed_t"]) <= turn, "why": "долг не так велик" if ratio <= 90.0 else "рынки и так закрыты", "desc": "Добровольно открыть переговоры с кредиторами. Списание долга ценой доверия и закрытых на годы рынков; дефолт — не конец игры."})
	var st: int = int(imf["st"])
	out.append({"id": "imf_ask", "grp": "МВФ", "name": "Попросить помощь МВФ", "cap": 4.0, "cd": 12, "ok": st != 2 and fin_cd("imf_ev") == 0, "why": "программа уже идёт" if st == 2 else "МВФ пока не готов говорить", "desc": "МВФ даёт кредит траншами в обмен на условия: сократить дефицит, провести реформы. Рынки успокаиваются, но реформы болезненны. Условия можно сорвать, но тогда транши прекращаются."})
	if st == 2:
		out.append({"id": "imf_stop", "grp": "МВФ", "name": "Выйти из программы МВФ", "cap": 4.0, "desc": "Прекратить программу: условий больше нет, но денег и доверия тоже."})
	return out


# ============================================================
#  МВФ
# ============================================================
func fin_imf_trigger(ratio: float) -> void:
	var imf: Dictionary = fin["imf"]
	var db: Dictionary = fin["db"]
	if int(imf["st"]) != 0 or fin_cd("imf_ev") > 0 or not current_event.is_empty() or election_open:
		return
	if float(db["spr"]) >= 8.0 or (float(ec["res"]) + float(fin["fx"]["swap"]) < 1.0 and String(fin["fx"]["reg"]) in ["peg", "corr"]) or (int(db["closed_t"]) > turn and ratio > 80.0):
		fin_imf_offer("crisis")


func fin_imf_offer(kind: String) -> void:
	var imf: Dictionary = fin["imf"]
	if int(imf["st"]) == 2 or fin_cd("imf_ev") > 0 and kind != "debt":
		return
	if not current_event.is_empty() or election_open:
		imf["pend"] = true
		imf["pend_kind"] = kind
		return
	imf["pend"] = false
	fin_cd_set("imf_ev", 3)
	var ratio: float = debt / maxf(gdp, 1.0) * 100.0
	var conds: Array = ["deficit"]
	var pool: Array = ["pension", "tax", "priv"]
	pool.shuffle()
	for i in (1 if kind == "ask" else 2):
		conds.append(pool[i])
	imf["cond"] = conds
	imf["amt"] = clampf(3.0 + 0.05 * (ratio - 60.0), 3.0, 8.0)
	var ctxt := ""
	for c in conds:
		ctxt += "\n• %s: %s" % [String(FIN_COND[c]["n"]), String(FIN_COND[c]["d"])]
	var west: bool = not rl.is_empty() and (bool(rl["b"]["eu"]) or bool(rl["b"]["nato"]))
	var opts: Array = [
		{"l": "Принять программу МВФ: %.1f%% ВВП шестью траншами, условия выше" % float(imf["amt"]), "fx": {}, "act": "imf_yes"},
		{"l": "Отказаться и просить Китай: 4%% ВВП под 6%% годовых, отношения с Западом портятся", "fx": {}, "act": "imf_cn"},
		{"l": ("Просить союзников: 2,5%% ВВП под 2%% (ЕС, НАТО)" if west else "Просить союзников: 2,5%% ВВП под 2%% (без гарантии отношений)"), "fx": {}, "act": "imf_ally"},
		{"l": "Обойтись без помощи", "fx": {}, "act": "imf_no"}]
	fin_event("imf", "[b]МВФ готов помочь.[/b] Фонд предлагает программу %.1f%% ВВП траншами раз в три месяца. Условия:%s\nЕсли условия не выполнять, транши прекратятся." % [float(imf["amt"]), ctxt], opts)


func fin_imf_choice(id: String) -> void:
	var imf: Dictionary = fin["imf"]
	var db: Dictionary = fin["db"]
	match id:
		"imf_yes":
			imf["st"] = 2
			imf["tr"] = 6
			imf["tr_n"] = 6
			imf["since"] = turn
			imf["tr_t"] = turn + 3
			imf["fail"] = 0
			imf["base_def"] = maxf(last_deficit_pct, 3.0)
			imf["base_ret"] = int(rl["lv"]["ret"]) if not rl.is_empty() else 0
			imf["base_tax"] = float(pol["vat"]) + float(pol["income"])
			imf["base_ipo"] = float(fin["ex"]["ipo"])
			imf["done"] = 0
			fin_imf_disburse()
			fin_mood_hit(10.0)
			db["auc_fail"] = 0.0
			db["hot_spr"] = 0.0
			if "pension" in (imf["cond"] as Array):
				add_support("Пенсионеры", -2.0)
			add_support("Рабочие", -1.0)
			fin_note("мвф", "Программа МВФ принята: %.1f%% ВВП траншами. Условия под наблюдением." % float(imf["amt"]), COL_TEAL)
		"imf_cn":
			var amt: float = 4.0
			debt += gdp * amt / 100.0
			ec["res"] = float(ec["res"]) + amt
			db["fcur"] = (float(db["fcur"]) * (debt - gdp * amt / 100.0) + 100.0 * gdp * amt / 100.0) / maxf(debt, 1.0)
			db["avg"] = float(db["avg"]) + (0.06 - float(db["avg"])) * gdp * amt / 100.0 / maxf(debt, 1.0)
			fin_mood_hit(4.0)
			dip_all(-4.0, true)
			fin_cd_set("imf_ev", 24)
			fin_note("мвф", "Китай выдал заём 4%% ВВП под 6%%: резервы пополнены, но отношения с Западом ухудшились.", COL_WARN)
		"imf_ally":
			var amt2: float = 2.5
			debt += gdp * amt2 / 100.0
			ec["res"] = float(ec["res"]) + amt2
			db["avg"] = float(db["avg"]) + (0.02 - float(db["avg"])) * gdp * amt2 / 100.0 / maxf(debt, 1.0)
			fin_mood_hit(5.0)
			fin_cd_set("imf_ev", 24)
			fin_note("мвф", "Союзники выдали заём 2,5%% ВВП под 2%%.", COL_GOOD)
		"imf_no":
			imf["st"] = 3
			fin_cd_set("imf_ev", 12)
			fin_note("мвф", "Вы отказались от внешней помощи.", COL_DIM)


func fin_imf_disburse() -> void:
	var imf: Dictionary = fin["imf"]
	var db: Dictionary = fin["db"]
	var t: float = float(imf["amt"]) / float(imf["tr_n"])
	debt += gdp * t / 100.0
	ec["res"] = float(ec["res"]) + t
	db["avg"] = float(db["avg"]) + (0.02 - float(db["avg"])) * gdp * t / 100.0 / maxf(debt, 1.0)
	imf["tr"] = int(imf["tr"]) - 1


# проверка условия: [выполнено, текст]
func fin_imf_check(c: String) -> Array:
	var imf: Dictionary = fin["imf"]
	var rev: int = int(imf.get("done", 0))
	match c:
		"deficit":
			var tg: float = lerpf(float(imf["base_def"]), 3.0, minf(1.0, float(rev) / 3.0)) + 0.5
			return [last_deficit_pct <= tg, "дефицит %.1f%% (нужно не больше %.1f%%)" % [last_deficit_pct, tg]]
		"pension":
			var cur: int = int(rl["lv"]["ret"]) if not rl.is_empty() else 0
			return [rev < 1 or cur >= int(imf["base_ret"]) + 1, "пенсионная реформа: уровень %d (нужен %d)" % [cur, int(imf["base_ret"]) + 1]]
		"tax":
			var cur2: float = float(pol["vat"]) + float(pol["income"])
			return [rev < 1 or cur2 >= float(imf["base_tax"]) + 1.0, "НДС и подоходный: %.1f п.п. (нужно %.1f)" % [cur2, float(imf["base_tax"]) + 1.0]]
		"priv":
			var cur3: float = float(fin["ex"]["ipo"]) - float(imf["base_ipo"])
			return [rev < 1 or cur3 >= 1.0, "приватизация: %.1f%% ВВП (нужно 1,0)" % cur3]
	return [true, ""]


func fin_imf_review() -> void:
	var imf: Dictionary = fin["imf"]
	if int(imf["pend"] if imf["pend"] is int else (1 if bool(imf["pend"]) else 0)) == 1 and current_event.is_empty() and not election_open and int(imf["st"]) != 2:
		fin_imf_offer(String(imf.get("pend_kind", "crisis")))
	if int(imf["st"]) != 2 or turn < int(imf["tr_t"]):
		return
	var ok := true
	var lines := ""
	for c in imf["cond"]:
		var r: Array = fin_imf_check(c)
		if not bool(r[0]):
			ok = false
			lines += "\n• " + String(r[1])
	imf["tr_t"] = turn + 3
	imf["done"] = int(imf.get("done", 0)) + 1
	if ok:
		imf["fail"] = 0
		fin_imf_disburse()
		fin_mood_hit(3.0)
		fin_note("мвф", "Очередной транш МВФ выдан: условия выполнены (осталось траншей: %d)." % int(imf["tr"]), COL_GOOD)
		if int(imf["tr"]) <= 0:
			imf["st"] = 0
			fin_cd_set("imf_ev", 36)
			fin_mood_hit(5.0)
			fin_note("мвф", "Программа МВФ завершена успешно.", COL_GOOD)
	else:
		imf["fail"] = int(imf["fail"]) + 1
		fin_mood_hit(-5.0)
		if int(imf["fail"]) >= 2:
			imf["st"] = 3
			fin_cd_set("imf_ev", 36)
			fin_mood_hit(-10.0)
			fin["db"]["auc_pen"] = float(fin["db"]["auc_pen"]) + 1.0
			fin_note("мвф", "Программа МВФ сорвана: условия не выполнены дважды.%s" % lines, COL_BAD)
		else:
			fin_note("мвф", "МВФ задержал транш: условия не выполнены.%s" % lines, COL_WARN)


func fin_imf_step() -> void:
	pass


func fin_imf_text() -> String:
	var imf: Dictionary = fin["imf"]
	var t := ""
	match int(imf["st"]):
		0:
			return "Программы МВФ нет."
		3:
			return "Программы МВФ нет (отказ или срыв)."
	t = "Программа МВФ: %.1f%% ВВП, транш раз в 3 мес., осталось %d из %d. Следующая проверка через %d мес.\n" % [float(imf["amt"]), int(imf["tr"]), int(imf["tr_n"]), maxi(0, int(imf["tr_t"]) - turn)]
	for c in imf["cond"]:
		var r: Array = fin_imf_check(c)
		t += "%s %s: %s\n" % ["✓" if bool(r[0]) else "✗", String(FIN_COND[c]["n"]), String(r[1])]
	return t


# ============================================================
#  ФОНДЫ
# ============================================================
func fin_fund_total() -> float:
	var f: Dictionary = fin["fd"]
	return float(f["res"]) + float(f["pen"]) + float(f["own"])


func fin_fund_step() -> void:
	var f: Dictionary = fin["fd"]
	var ex: Dictionary = fin["ex"]
	var dfx: float = float(fin["db"].get("dfx", 0.0))
	var grow: float = 0.03 / 12.0 * wdt + 0.4 * float(ex["ret_w"]) + 0.8 * clampf(dfx, -0.1, 0.1)
	var rules: Dictionary = f["rules"]
	var surplus: float = maxf(0.0, -last_deficit_pct)
	var crisis: bool = growth < 0.0 or last_deficit_pct > 4.0
	for k in ["res", "pen", "own"]:
		if k == "own" and not bool(f["own_on"]):
			continue
		var v: float = float(f[k])
		var r: Dictionary = rules[k]
		v += v * grow
		var inflow: float = (surplus * float(r["in_s"]) / 100.0 + float(r["in_fix"])) * wdt / 12.0
		if inflow > 0.0:
			v += inflow
			debt += gdp * inflow / 100.0
		var out := 0.0
		match String(r["out"]):
			"crisis":
				if crisis:
					out = minf(v, maxf(0.0, last_deficit_pct - 2.0) * 0.6 * wdt / 12.0 + (0.5 * wdt / 12.0 if growth < 0.0 else 0.0))
			"fix":
				out = v * 0.04 * wdt / 12.0
		if out > 0.0:
			v -= out
			debt = maxf(0.0, debt - gdp * out / 100.0)
		f[k] = maxf(0.0, v)


func fin_acts_fund() -> Array:
	var out: Array = []
	var f: Dictionary = fin["fd"]
	var names := {"res": "Ресурсный фонд", "pen": "Пенсионный и резервный фонд", "own": "Свой фонд"}
	var rules: Dictionary = f["rules"]
	if not bool(f["own_on"]):
		out.append({"id": "fd_create", "grp": "Свой фонд", "name": "Создать свой суверенный фонд", "cap": 6.0, "desc": "Копить в лучшие времена: в фонд идёт часть профицита и/или фиксированная сумма, тратить можно по правилу. Рынки считают фонд подушкой: ставки по долгу ниже, но копить придётся занимая."})
	for k in ["res", "pen", "own"]:
		if k == "own" and not bool(f["own_on"]):
			continue
		var r: Dictionary = rules[k]
		out.append({"id": "fd_%s_in_s" % k, "grp": names[k], "name": "%s: доля профицита в фонд %.0f%% (сменить)" % [names[k], float(r["in_s"])], "cap": 0.0, "desc": "Какую долю профицита бюджета откладывать: 0 → 50 → 100%. В дефицитные годы взноса из профицита нет."})
		out.append({"id": "fd_%s_fix" % k, "grp": names[k], "name": "%s: фиксированный взнос %.1f%% ВВП в год (сменить)" % [names[k], float(r["in_fix"])], "cap": 0.0, "desc": "Постоянный взнос независимо от профицита: 0 → 0,5 → 1 → 2%% ВВП. Деньги берутся в долг, пока бюджет в минусе."})
		var o: String = String(r["out"])
		out.append({"id": "fd_%s_out" % k, "grp": names[k], "name": "%s: правило трат — %s (сменить)" % [names[k], {"never": "не тратить", "crisis": "в кризис", "fix": "4% остатка в год"}[o]], "cap": 0.0, "desc": "Когда фонд идёт на покрытие дефицита: никогда, в кризис (спад или дефицит больше 4%) или ежегодно 4% остатка."})
	out.append({"id": "fd_withdraw", "grp": "Разовое", "name": "Изъять 2% ВВП из фондов на покрытие дефицита", "cap": 3.0, "cd": 3, "ok": fin_fund_total() >= 2.0, "why": "в фондах меньше 2% ВВП", "desc": "Разово погасить долг из фондов. Рынки видят, что подушка тает: доверие чуть падает."})
	return out


func fin_act_fund(id: String, opt: Dictionary) -> bool:
	var f: Dictionary = fin["fd"]
	var rules: Dictionary = f["rules"]
	if id == "fd_create":
		f["own_on"] = true
		fin_note("фонды", "Создан суверенный фонд.", COL_GOOD)
		return true
	if id == "fd_withdraw":
		var left := 2.0
		for k in ["res", "pen", "own"]:
			var take: float = minf(left, float(f[k]))
			f[k] = float(f[k]) - take
			left -= take
		debt = maxf(0.0, debt - gdp * (2.0 - left) / 100.0)
		fin_mood_hit(-2.0)
		fin_note("фонды", "Из фондов изъято 2% ВВП, долг сокращён.", COL_DIM)
		return true
	if id.begins_with("fd_"):
		var parts: PackedStringArray = id.split("_")
		if parts.size() >= 3 and rules.has(parts[1]):
			var r: Dictionary = rules[parts[1]]
			if id.ends_with("_in_s"):
				var cyc: Array = [0.0, 50.0, 100.0]
				r["in_s"] = cyc[(cyc.find(float(r["in_s"])) + 1) % 3]
			elif id.ends_with("_fix"):
				var cyc2: Array = [0.0, 0.5, 1.0, 2.0]
				r["in_fix"] = cyc2[(cyc2.find(float(r["in_fix"])) + 1) % 4]
			elif id.ends_with("_out"):
				var cyc3: Array = ["never", "crisis", "fix"]
				r["out"] = cyc3[(cyc3.find(String(r["out"])) + 1) % 3]
			return true
	return false


# ============================================================
#  РАСПРЕДЕЛЕНИЕ ДЕЙСТВИЙ
# ============================================================
func fin_apply_act(id: String, opt: Dictionary) -> void:
	if fin_act_cb(id, opt) or fin_act_fx(id, opt) or fin_act_bank(id, opt) or fin_act_ex(id, opt) or fin_act_debt(id, opt) or fin_act_fund(id, opt):
		return
