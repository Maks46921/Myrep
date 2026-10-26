# Финансы (0.63): центробанк, обменный курс, резервы, переход на евро и выход из него.
extends "res://scripts/logic/fin63.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func fin_bank_crisis(kind: String, sev: float) -> void:
	pass


func fin_debt_revalue(old: float, nw: float) -> void:
	pass


func fin_imf_offer(kind: String) -> void:
	pass


# --- конец заглушек ---


const FIN_HEAD := {"hawk": {"n": "ястреб", "b": 0.5, "c": 5.0}, "dove": {"n": "голубь", "b": -0.5, "c": -5.0}, "tech": {"n": "технократ", "b": 0.0, "c": 3.0}}


# ============================================================
#  ЦЕНТРОБАНК
# ============================================================
# опорная независимость, к которой тянется доверие к ЦБ (чем независимее банк, тем доверие устойчивее)
func fin_cred_anchor() -> float:
	return 30.0 + 0.4 * float(fin["cb"]["ind"])


# давление правительства на ЦБ (п.п. к ставке): отрицательное — просит дешёвых денег (высокий долг, скорые выборы)
func fin_cb_pull() -> float:
	var ratio: float = debt / maxf(gdp, 1.0) * 100.0
	var p := -clampf((ratio - 70.0) / 40.0, 0.0, 1.5)
	if turn - last_parl >= parl_term() - 6:
		p -= 0.6
	return p * 0.8


func fin_ecb_rate() -> float:
	return ea_infl + RATE_NEUTRAL_REAL + 0.55 * (ea_infl - I_TGT) + 0.3


# поправка к ставке по правилу (cb_target): давление власти, главный банкир, привязка курса, лоббирование в ЕЦБ
func fin_cb_bias(base: float) -> float:
	if not fin_on():
		return 0.0
	var cb: Dictionary = fin["cb"]
	if fin_euro_member():
		return float(cb["lobby"])
	var b := 0.0
	var dep: float = 1.0 - float(cb["ind"]) / 100.0
	b += (fin_cb_pull() - float(cb["pull0"])) * dep * 1.5
	b += float(cb["press"])
	b += float(FIN_HEAD[String(cb["head"])]["b"])
	var f: Dictionary = fin["fx"]
	if String(f["reg"]) == "peg" or (String(f["reg"]) == "corr" and float(f["band"]) <= 0.06):
		b += (fin_ecb_rate() + 0.3 - base) * 0.6 - float(f.get("peg0", 0.0))
	return b


func fin_cb_step() -> void:
	var cb: Dictionary = fin["cb"]
	if fin_euro_member() or String(fin["fx"]["reg"]) == "euro" and not bool(fin["fx"].get("uni", false)):
		cb["ind"] = 95.0
	else:
		cb["ind"] = clampf(float(cb["ind0"]) + float(cb["law"]) + (democracy_index() - float(cb["dem0"])) * 40.0, 0.0, 100.0)
	cb["press"] = float(cb["press"]) * wdec(0.9)
	cb["lobby"] = float(cb["lobby"]) * wdec(0.85)
	var infl_dev: float = absf(inflation - infl_tgt())
	var drift := 0.0
	drift -= 0.8 * maxf(0.0, inflation - maxf(4.0, float(cb["infl0"]) + 1.0))
	drift -= 0.5 * maxf(0.0, 1.0 - inflation)
	drift += 0.3 if infl_dev < 1.0 else 0.0
	drift -= 0.06 * float(cb["qe"])
	drift -= 0.5 * maxf(0.0, -(fin_cb_bias(cb_rule()))) * (1.0 - float(cb["ind"]) / 100.0)
	cb["cred"] = clampf(float(cb["cred"]) + drift * wdt + (fin_cred_anchor() - float(cb["cred"])) * rt(0.01, wdt), 0.0, 100.0)
	# покупки облигаций: свёртываются сами при высокой инфляции, ослабляют валюту
	var qe: float = float(cb["qe"])
	if qe > 0.0:
		if inflation > infl_tgt() + 2.0 and float(cb["ind"]) > 40.0:
			qe = maxf(0.0, qe - 0.5 * wdt)
		ec["fx_shock"] = float(ec["fx_shock"]) - 0.0008 * qe * wdt
		cb["qe"] = qe
	# эмиссия на дефицит закрыта при независимом ЦБ и в еврозоне
	if float(pol["emit"]) > 0.0 and (float(cb["ind"]) >= 60.0 or fin_euro_member()):
		pol["emit"] = 0.0
		if prev_pol.has("emit"):
			prev_pol["emit"] = 0.0
		if turn - int(cb["emit_msg"]) >= 12:
			cb["emit_msg"] = turn
			fin_note("цб", "Центробанк независим: печатать деньги на дефицит запрещено. Эмиссия обнулена.", COL_WARN)


func fin_month_cb() -> void:
	var cb: Dictionary = fin["cb"]
	var f: Dictionary = fin["fx"]
	if float(f["swap"]) > 0.0 and turn >= int(f["swap_t"]):
		f["swap"] = 0.0
		fin_note("курс", "Своп-линия закончилась.", COL_DIM)
	# срок главы ЦБ
	if not fin_euro_member() and turn - int(cb["head_t"]) >= 96 and fin_cd("head_ev") == 0 and not bool(fin["db"]["pend"]):
		fin_cd_set("head_ev", 24)
		fin_event("head", "Срок главы центробанка истёк. Пора назначить нового главу или оставить прежнего (сейчас: %s)." % String(FIN_HEAD[String(cb["head"])]["n"]), [
			{"l": "Назначить технократа: нейтральная политика, доверие растёт", "fx": {}, "act": "head_tech"},
			{"l": "Назначить «ястреба»: жёстче к инфляции, ставки выше (капитал −3)", "fx": {"capital": -3.0}, "act": "head_hawk"},
			{"l": "Назначить «голубя»: дешевле кредит, но инфляция опаснее (капитал −3)", "fx": {"capital": -3.0}, "act": "head_dove"},
			{"l": "Оставить прежнего", "fx": {}, "act": "head_keep"}])


func fin_cb_prob_press() -> float:
	return 0.15 + 0.85 * (1.0 - float(fin["cb"]["ind"]) / 100.0)


func fin_acts_cb() -> Array:
	var out: Array = []
	var cb: Dictionary = fin["cb"]
	var euro: bool = fin_euro_member()
	var uni: bool = String(fin["fx"]["reg"]) == "euro" and not euro
	var pp: String = "Шанс успеха сейчас %.0f%%." % (fin_cb_prob_press() * 100.0)
	if euro:
		out.append({"id": "eu_lobby_dn", "name": "Лоббировать в ЕЦБ: ставку ниже", "cap": 5.0, "cd": 6, "desc": "Ваш голос в еврозоне мал, но не нулевой: ставка по правилу сдвигается вниз примерно на 0,25 п.п., действует несколько месяцев."})
		out.append({"id": "eu_lobby_up", "name": "Лоббировать в ЕЦБ: ставку выше", "cap": 5.0, "cd": 6, "desc": "Сдвигает ставку по правилу вверх примерно на 0,25 п.п.: помогает против инфляции, но тормозит рост."})
		out.append({"id": "euro_exit", "name": "Выйти из еврозоны", "cap": 15.0, "desc": "Своя валюта и свой ЦБ, но выход идёт как тяжёлый кризис: бегство вкладов, обвал курса, скачок долга в евро и цен. Эмиссия снова возможна."})
		return out
	if uni:
		return out
	out.append({"id": "cb_law_up", "name": "Закон о ЦБ: усилить независимость", "cap": 8.0, "cd": 24, "ok": float(cb["law"]) < 30.0 and float(cb["ind"]) < 100.0, "why": "предел", "desc": "Независимость +12. ЦБ меньше слушается власти, доверие рынков и доверие к деньгам растут; эмиссия на дефицит закрывается при независимости от 60."})
	out.append({"id": "cb_law_dn", "name": "Закон о ЦБ: подчинить правительству", "cap": 4.0, "cd": 24, "ok": float(cb["ind"]) > 5.0, "why": "предел", "desc": "Независимость −15. Можно просить дешёвые деньги, но рынки насторожатся: доверие и курс слабеют."})
	out.append({"id": "cb_press_dn", "name": "Надавить на ЦБ: снизить ставку", "cap": 6.0, "cd": 6, "desc": "Ставка по правилу сдвигается вниз на 0,6 п.п. на несколько месяцев. " + pp + " При неудаче теряется доверие."})
	out.append({"id": "cb_press_up", "name": "Попросить ЦБ поднять ставку", "cap": 4.0, "cd": 6, "desc": "Сдвигает ставку вверх на 0,6 п.п. Помогает против инфляции. " + pp})
	out.append({"id": "cb_qe", "name": "Попросить ЦБ купить облигации (+3% ВВП)", "cap": 10.0, "cd": 6, "ok": float(cb["qe"]) < (25.0 if float(cb["ind"]) < 30.0 else 12.0), "why": "предел покупок", "desc": "ЦБ выкупает госдолг: проценты по нему падают, но растёт инфляция, слабеет валюта, падает доверие к ЦБ. " + pp})
	out.append({"id": "cb_unqe", "name": "Свернуть покупки облигаций (−3% ВВП)", "cap": 0.0, "ok": float(cb["qe"]) > 0.0, "why": "покупок нет", "desc": "ЦБ продаёт облигации обратно рынку: проценты по долгу растут, инфляция остывает."})
	var termok: bool = turn - int(cb["head_t"]) >= 96
	var cp: float = 0.0 if termok else 8.0
	var why: String = "" if (termok or float(cb["ind"]) < 70.0) else "глава ЦБ назначается раз в 8 лет"
	for k in ["tech", "hawk", "dove"]:
		var h: Dictionary = FIN_HEAD[k]
		out.append({"id": "head_" + k, "name": "Назначить главу ЦБ: %s" % h["n"], "cap": cp, "ok": why == "" and String(cb["head"]) != k, "why": why if why != "" else "уже такой",
			"desc": "Смена руководства ЦБ: «ястреб» держит ставку выше, «голубь» ниже, технократ строго по правилу. Сейчас: %s." % String(FIN_HEAD[String(cb["head"])]["n"])})
	return out


# ============================================================
#  КУРС И РЕЗЕРВЫ
# ============================================================
func fin_fx_step() -> void:
	var f: Dictionary = fin["fx"]
	var w: Dictionary = fin["w"]
	var reg: String = String(f["reg"])
	# переоценка резервов: золото и доллар/евро
	var res: float = float(ec["res"])
	if res > 0.0:
		var usd_k: float = float(f["mix_usd"]) / 100.0
		var eur_k: float = float(f["mix_eur"]) / 100.0
		var du: float = float(w.get("du", 0.0))
		var val: float = float(f["gold"]) / 100.0 * float(w.get("dg", 0.0))
		if String(f["anc"]) == "USD":
			val += eur_k * (-du)
		elif reg != "euro" and not fin_euro_member():
			val += usd_k * du
		else:
			val += usd_k * du
		f["val"] = res * val
		res = clampf(res * (1.0 + val), -5.0, 80.0)
		ec["res"] = res
	f["imp"] = float(f["imp"]) * wdec(0.82)
	if reg != "peg" and reg != "corr":
		f["press"] = 0.0
		f["last"] = float(ec["fxs"])
		return
	var ft: float = float(ec.get("ft", ec["fxs"]))
	var lvl: float = float(f["lvl"])
	var band: float = float(f["band"])
	var tgt: float = clampf(ft, lvl * (1.0 - band), lvl * (1.0 + band))
	var press: float = ft - tgt
	if bool(f["capctl"]):
		press *= 0.6
	f["press"] = press
	var board: bool = reg == "peg" and band <= 0.02
	var k: float = 75.0 * (0.35 if board else 1.0)
	var dres: float = press * k * wdt
	if dres > 0.0:
		dres *= clampf(1.0 - (float(ec["res"]) - 15.0) / 25.0, 0.1, 1.0)     # копить резервы бесконечно не имеет смысла
	res = float(ec["res"]) + dres
	ec["res"] = res
	f["defended"] = float(f["defended"]) + minf(0.0, press) * k * wdt
	if reg == "corr" and press > 0.0 and float(ec["res"]) > 20.0:
		f["lvl"] = lvl + (ft - lvl) * rt(0.03, wdt)       # коридор ползёт вверх, если валюта сильна и резервы уже велики
	var avail: float = res + float(f["swap"])
	if press < -0.01 and avail < 0.3 and not (board and avail > -2.0):
		fin_peg_break(ft)
		return
	ec["fxs"] = clampf(float(ec["fxs"]), lvl * (1.0 - band), lvl * (1.0 + band))
	f["last"] = float(ec["fxs"])


func fin_peg_break(ft: float) -> void:
	var f: Dictionary = fin["fx"]
	var b: Dictionary = fin["bk"]
	f["reg"] = "float"
	f["crash_t"] = turn
	f["peg_t"] = -999
	var old: float = float(ec["fxs"])
	ec["fxs"] = clampf(minf(old, ft) * 0.96, 0.6, 1.5)
	f["imp"] = float(f["imp"]) + 0.8
	fin_mood_hit(-18.0)
	risk_prem = minf(2.0, risk_prem + 0.6)
	b["shock"] = float(b["shock"]) + 0.8 + float(fin["db"]["fcur"]) * 0.01
	fin["db"]["hot"] = minf(1.0, float(fin["db"]["hot"]) + 0.2)
	fin_debt_revalue(old, float(ec["fxs"]))
	fin_cd_set("fx_peg_eur", 12)
	fin_cd_set("fx_peg_usd", 12)
	fin_cd_set("fx_corr_eur", 12)
	fin_note("курс", "Курс удержать не удалось: резервы кончились, привязка сорвана, валюта обвалилась на %.0f%%. Цены на импорт растут, долг в валюте дорожает." % ((1.0 - float(ec["fxs"]) / old) * 100.0), COL_BAD)
	if not observer and current_event.is_empty() and not opp_mode:
		fin_imf_offer("fx")


func fin_mix_shift(target: String, amt: float) -> void:
	var f: Dictionary = fin["fx"]
	var keys: Array = ["gold", "mix_eur", "mix_usd", "mix_cny"]
	var tk: String = {"gold": "gold", "eur": "mix_eur", "usd": "mix_usd", "cny": "mix_cny"}[target]
	var pool := 0.0
	for k in keys:
		if k != tk:
			pool += float(f[k])
	var take: float = minf(amt, pool)
	if take <= 0.0:
		return
	for k in keys:
		if k != tk:
			f[k] = float(f[k]) - take * float(f[k]) / pool
	f[tk] = float(f[tk]) + take


func fin_erm_ready() -> bool:
	var f: Dictionary = fin["fx"]
	if not fin_on():
		return true
	return (String(f["reg"]) == "peg" or String(f["reg"]) == "corr") and String(f["anc"]) == "EUR" and float(f["band"]) <= 0.15 and turn - int(f["peg_t"]) >= 24


func fin_erm_text() -> String:
	var f: Dictionary = fin["fx"]
	if fin_erm_ready():
		return "механизм ERM II пройден"
	if (String(f["reg"]) == "peg" or String(f["reg"]) == "corr") and String(f["anc"]) == "EUR":
		return "ERM II: курс привязан к евро %d из 24 мес." % maxi(0, turn - int(f["peg_t"]))
	return "ERM II: сначала привяжите валюту к евро и продержите курс 24 месяца"


func fin_set_peg(anc: String, band: float, reg: String) -> void:
	var f: Dictionary = fin["fx"]
	f["reg"] = reg
	f["anc"] = anc
	f["band"] = band
	f["lvl"] = float(ec["fxs"])
	f["peg_t"] = turn if anc == "EUR" else -999
	f["press"] = 0.0
	fin_mood_hit(2.0)
	fin_note("курс", "Валюта привязана к %s%s: курс держится у %.0f%%. Резервы тратятся на защиту курса." % ["евро" if anc == "EUR" else "доллару", " с коридором ±%.0f%%" % (band * 100.0) if reg == "corr" else "", float(ec["fxs"]) * 100.0], COL_TEAL)


func fin_acts_fx() -> Array:
	var out: Array = []
	var f: Dictionary = fin["fx"]
	var reg: String = String(f["reg"])
	var euro: bool = reg == "euro"
	if euro:
		return out
	var res: float = float(ec["res"])
	var closed: bool = int(fin["db"]["closed_t"]) > turn
	var pegged: bool = reg == "peg" or reg == "corr"
	if pegged:
		out.append({"id": "fx_float", "name": "Отпустить курс (плавающий)", "cap": 4.0, "desc": "Резервы больше не тратятся на защиту курса, но валюта начнёт колебаться, а доверие к привязке пропадёт."})
		for x in [5, 10, 15]:
			out.append({"id": "fx_dev%d" % x, "name": "Девальвация на %d%%" % x, "cap": 4.0 + x * 0.4, "cd": 6, "desc": "Центральный курс ниже на %d%%: экспорт дешевеет, давление на резервы спадает. Импорт и долг в валюте дорожают, цены растут, доверие падает." % x})
		out.append({"id": "fx_rev5", "name": "Ревальвация на 5%", "cap": 4.0, "cd": 6, "desc": "Валюта крепче: импорт и долг в валюте дешевле, цены растут медленнее, но экспортёры страдают."})
	if not pegged or reg == "corr":
		out.append({"id": "fx_peg_eur", "name": "Привязать валюту к евро (±2%)", "cap": 8.0, "cd": 12, "ok": res >= 6.0, "why": "мало резервов (нужно от 6% ВВП)", "desc": "Жёсткая привязка: стабильные цены и торговля, шаг к евро (ERM II), но резервы тратятся на защиту курса, а ставка следует за ЕЦБ."})
		out.append({"id": "fx_corr_eur", "name": "Коридор к евро (±10%, как ERM II)", "cap": 6.0, "cd": 12, "ok": res >= 4.0 and reg != "corr", "why": "уже коридор" if reg == "corr" else "мало резервов", "desc": "Мягкая привязка: курс гуляет в пределах 10% от центра. Подходит для подготовки к евро, дешевле для резервов."})
		out.append({"id": "fx_peg_usd", "name": "Привязать валюту к доллару (±2%)", "cap": 8.0, "cd": 12, "ok": res >= 6.0, "why": "мало резервов (нужно от 6% ВВП)", "desc": "Привязка к доллару: удобна для сырьевых экспортёров. Ставка следует за мировыми, валюта зависит от доллара."})
	if not pegged:
		out.append({"id": "fx_sell", "name": "Интервенция: продать резервы (2% ВВП)", "cap": 2.0, "cd": 2, "ok": res >= 3.0, "why": "мало резервов", "desc": "Поддержать курс: валюта крепнет на пару процентов на несколько месяцев, резервы падают."})
		out.append({"id": "fx_buy", "name": "Интервенция: купить валюту (накопить 2% ВВП)", "cap": 2.0, "cd": 2, "desc": "Ослабить национальную валюту и пополнить резервы: экспорт дешевеет, но цены на импорт растут."})
	out.append({"id": "fx_capctl", "name": ("Снять контроль капитала" if bool(f["capctl"]) else "Ввести контроль капитала"), "cap": 2.0 if bool(f["capctl"]) else 6.0, "cd": 6,
		"desc": "Ограничения на вывоз денег гасят давление на курс на 40%, но бьют по инвестициям и росту, а инвесторы теряют доверие. Снятие вернёт доверие постепенно."})
	for k in [["gold", "в золото"], ["usd", "в доллары"], ["eur", "в евро"], ["cny", "в юани"]]:
		out.append({"id": "fx_to_" + k[0], "name": "Перевести 5%% резервов %s" % k[1], "cap": 1.0, "cd": 3,
			"desc": "Структура резервов: золото защищает в кризис, но колеблется в цене; доллар, евро и юань дают ликвидность. Сейчас: золото %.0f%%, евро %.0f%%, доллар %.0f%%, юань %.0f%%%s." % [float(f["gold"]), float(f["mix_eur"]), float(f["mix_usd"]), float(f["mix_cny"]), fin_est_note("gold")]})
	var sw: String = fin_swap_partner()
	out.append({"id": "fx_swap", "name": "Своп-линия с другим ЦБ (+3% ВВП на 2 года)", "cap": 6.0, "cd": 24, "ok": sw != "" and float(f["swap"]) <= 0.0, "why": "нет партнёра" if sw == "" else "линия уже открыта",
		"desc": "Партнёр: %s. Запас иностранной валюты на случай нападения на курс; тратить можно как резервы. Через 2 года линия закрывается." % (sw if sw != "" else "нет")})
	out.append({"id": "fx_loan", "name": "Валютный заём (+3% ВВП резервов)", "cap": 3.0, "cd": 12, "ok": not closed, "why": "рынки закрыты", "desc": "Занять в валюте у иностранных банков: резервы растут сразу, долг вырастет на 3% ВВП и станет чувствительнее к курсу."})
	return out


func fin_swap_partner() -> String:
	if rl.is_empty():
		return ""
	var b: Dictionary = rl["b"]
	if bool(b["eu"]):
		return "ЕЦБ"
	if bool(b["nato"]) or ccode in ["GB", "CH", "NO", "RS", "BA", "MK", "AL", "ME", "XK"]:
		return "ФРС США"
	if ccode in ["RU", "BY"]:
		return "Народный банк Китая"
	return ""


# ============================================================
#  ЕВРО
# ============================================================
func fin_euro_join() -> void:
	if not fin_on():
		return
	var cb: Dictionary = fin["cb"]
	var f: Dictionary = fin["fx"]
	f["reg"] = "euro"
	f["anc"] = ""
	f["uni"] = false
	cb["ind0"] = 95.0
	cb["ind"] = 95.0
	cb["law"] = 0.0
	cb["cred"] = maxf(float(cb["cred"]), 68.0)
	cb["qe"] = 0.0
	fin["db"]["fcur"] = maxf(0.0, float(fin["db"]["fcur"]) - 40.0)
	fin_mood_hit(8.0)
	fin_note("евро", "Страна перешла на евро: курс и ставка теперь общие с еврозоной, долг в евро стал внутренним, доверие инвесторов выросло.", COL_GOOD)


func fin_euro_exit() -> void:
	if not fin_on():
		return
	var f: Dictionary = fin["fx"]
	var cb: Dictionary = fin["cb"]
	var b: Dictionary = fin["bk"]
	if String(f["reg"]) != "euro" or bool(f.get("uni", false)):
		return
	if bool(MACRO.get("euro", true)):
		MACRO["euro"] = false
		MACRO["cb_own"] = 1.0
		MACRO["cb_off"] = float(MACRO.get("cb_off", 0.0)) + 0.4
	if not rl.is_empty():
		rl["b"]["euro"] = false
	f["reg"] = "float"
	f["anc"] = ""
	f["lvl"] = float(ec["fxs"])
	f["capctl"] = true
	f["capctl_t"] = turn
	fin_cd_set("fx_capctl", 6)
	f["crash_t"] = turn
	cb["ind0"] = 45.0
	cb["law"] = 0.0
	cb["ind"] = 45.0
	cb["cred"] = 32.0
	var old: float = float(ec["fxs"])
	ec["fx_shock"] = float(ec["fx_shock"]) - 0.18
	f["imp"] = float(f["imp"]) + 1.2
	fin_mood_hit(-25.0)
	risk_prem = minf(2.0, risk_prem + 0.8)
	b["trust"] = maxf(10.0, float(b["trust"]) - 35.0)
	b["shock"] = float(b["shock"]) + 1.5
	fin["db"]["fcur"] = maxf(float(fin["db"]["fcur"]), 55.0)
	fin["db"]["hot"] = minf(1.0, float(fin["db"]["hot"]) + 0.35)
	fin_bank_crisis("panic", 2.0)
	if has_method("sync_emit"):
		call("sync_emit")
	fin_note("евро", "Выход из еврозоны: вкладчики снимают деньги, введён контроль капитала, новая валюта слабеет, долг в евро дорожает. Ставку теперь задаёт национальный ЦБ, эмиссия возможна.", COL_BAD)
	dip_all(-6.0, true)


# ============================================================
#  ИСПОЛНЕНИЕ ДЕЙСТВИЙ
# ============================================================
func fin_act_cb(id: String, opt: Dictionary) -> bool:
	var cb: Dictionary = fin["cb"]
	match id:
		"cb_law_up":
			cb["law"] = float(cb["law"]) + 12.0
			cb["cred"] = minf(100.0, float(cb["cred"]) + 6.0)
			fin_mood_hit(4.0)
			add_support("Бизнес", 1.0)
			fin_note("цб", "Закон о ЦБ принят: независимость банка выше.", COL_GOOD)
		"cb_law_dn":
			cb["law"] = float(cb["law"]) - 15.0
			cb["cred"] = maxf(0.0, float(cb["cred"]) - 8.0)
			fin_mood_hit(-6.0)
			add_support("Бизнес", -1.0)
			fin_note("цб", "ЦБ подчинён правительству: рынки насторожились.", COL_WARN)
		"cb_press_dn", "cb_press_up":
			var dn: bool = id == "cb_press_dn"
			if randf() < fin_cb_prob_press():
				cb["press"] = float(cb["press"]) + (-0.6 if dn else 0.6)
				fin_note("цб", "ЦБ уступил: ставка по правилу %s на 0,6 п.п." % ("снижена" if dn else "повышена"), COL_TEAL)
			else:
				cb["cred"] = minf(100.0, float(cb["cred"]) + 2.0)
				fin_mood_hit(-3.0)
				add_support("Бизнес", -0.5)
				fin_note("цб", "ЦБ отказался: независимый банк не поддался давлению, а попытка стала новостью.", COL_WARN)
		"cb_qe":
			if randf() < fin_cb_prob_press():
				cb["qe"] = float(cb["qe"]) + 3.0
				cb["cred"] = maxf(0.0, float(cb["cred"]) - 2.0)
				fin_note("цб", "ЦБ выкупает госдолг: проценты по нему падают, но риск инфляции растёт.", COL_WARN)
			else:
				fin_mood_hit(-3.0)
				fin_note("цб", "ЦБ отказался покупать облигации.", COL_WARN)
		"cb_unqe":
			cb["qe"] = maxf(0.0, float(cb["qe"]) - 3.0)
			fin_note("цб", "ЦБ сворачивает покупки облигаций: проценты по долгу вернутся к рыночным.", COL_DIM)
		"eu_lobby_dn":
			cb["lobby"] = float(cb["lobby"]) - 0.25
			fin_note("цб", "Вы добились от ЕЦБ чуть более мягкого тона.", COL_TEAL)
		"eu_lobby_up":
			cb["lobby"] = float(cb["lobby"]) + 0.25
			fin_note("цб", "Вы добились от ЕЦБ чуть более жёсткого тона.", COL_TEAL)
		"euro_exit":
			fin_euro_exit()
		"head_hawk", "head_dove", "head_tech":
			var k: String = id.substr(5)
			cb["head"] = k
			cb["head_t"] = turn
			cb["cred"] = clampf(float(cb["cred"]) + float(FIN_HEAD[k]["c"]), 0.0, 100.0)
			fin_note("цб", "Новый глава центробанка — %s." % String(FIN_HEAD[k]["n"]), COL_TEAL)
		"head_keep":
			cb["head_t"] = turn - 72
		_:
			return false
	return true


func fin_act_fx(id: String, opt: Dictionary) -> bool:
	var f: Dictionary = fin["fx"]
	match id:
		"fx_float":
			f["reg"] = "float"
			fin_mood_hit(-4.0)
			fin_note("курс", "Курс отпущен: он определяется рынком.", COL_WARN)
		"fx_dev5", "fx_dev10", "fx_dev15":
			var x: float = float(id.substr(6)) / 100.0
			var old: float = float(ec["fxs"])
			f["lvl"] = float(f["lvl"]) * (1.0 - x)
			ec["fxs"] = clampf(old * (1.0 - x), 0.6, 1.5)
			f["imp"] = float(f["imp"]) + x * 6.0
			fin_mood_hit(-(3.0 + x * 40.0))
			fin_debt_revalue(old, float(ec["fxs"]))
			add_support("Пенсионеры", -x * 15.0)
			f["crash_t"] = turn
			fin_note("курс", "Девальвация на %.0f%%: экспорт дешевле, импорт и долг в валюте дороже, цены растут." % (x * 100.0), COL_WARN)
		"fx_rev5":
			f["lvl"] = float(f["lvl"]) * 1.05
			ec["fxs"] = clampf(float(ec["fxs"]) * 1.05, 0.6, 1.5)
			f["imp"] = float(f["imp"]) - 0.3
			fin_mood_hit(1.0)
			fin_note("курс", "Ревальвация на 5%: импорт дешевеет, экспортёры недовольны.", COL_DIM)
		"fx_peg_eur":
			fin_set_peg("EUR", 0.02, "peg")
		"fx_corr_eur":
			fin_set_peg("EUR", 0.10, "corr")
		"fx_peg_usd":
			fin_set_peg("USD", 0.02, "peg")
		"fx_sell":
			ec["res"] = float(ec["res"]) - 2.0
			ec["fx_shock"] = float(ec["fx_shock"]) + 0.02
			fin_note("курс", "ЦБ продал валюту из резервов (2% ВВП): курс поддержан.", COL_DIM)
		"fx_buy":
			ec["res"] = float(ec["res"]) + 2.0
			ec["fx_shock"] = float(ec["fx_shock"]) - 0.02
			f["imp"] = float(f["imp"]) + 0.12
			fin_note("курс", "ЦБ скупил валюту (2% ВВП): резервы выросли, национальная валюта слабее.", COL_DIM)
		"fx_capctl":
			var on: bool = not bool(f["capctl"])
			f["capctl"] = on
			f["capctl_t"] = turn
			if on:
				bk_invest_hit(-8.0)
				fin_mood_hit(-8.0)
				fin_note("курс", "Введён контроль капитала: вывоз денег ограничен.", COL_WARN)
			else:
				fin_mood_hit(5.0)
				fin_note("курс", "Контроль капитала снят.", COL_GOOD)
		"fx_to_gold", "fx_to_usd", "fx_to_eur", "fx_to_cny":
			fin_mix_shift(id.substr(6), 5.0)
			fin_note("курс", "Структура резервов изменена.", COL_DIM)
		"fx_swap":
			f["swap"] = 3.0
			f["swap_t"] = turn + 24
			f["swap_by"] = fin_swap_partner()
			fin_note("курс", "Открыта своп-линия с партнёром (%s): +3%% ВВП валюты на 2 года." % fin_swap_partner(), COL_GOOD)
		"fx_loan":
			ec["res"] = float(ec["res"]) + 3.0
			var add: float = gdp * 0.03
			var dbv: Dictionary = fin["db"]
			dbv["fcur"] = (float(dbv["fcur"]) * debt + 100.0 * add) / (debt + add)
			debt += add
			fin_note("курс", "Валютный заём: резервы +3% ВВП, долг +3% ВВП.", COL_DIM)
		_:
			return false
	return true


func bk_invest_hit(v: float) -> void:
	ec["bconf"] = clampf(float(ec["bconf"]) + v, 0.0, 100.0)
