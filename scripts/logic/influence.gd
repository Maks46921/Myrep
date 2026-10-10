# Экономическое влияние и зависимость: ваша страна ⇄ остальные страны мира (боты).
# Зависимость считается от торговли (w_share), энергии и долга; рычаги — торговые соглашения, пошлины, помощь, выкуп долга.
extends "res://scripts/logic/tech.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func fa_notify(kind: String, c: String, mag: float) -> void:
	pass


func fa_sanctioning(c: String) -> bool:
	return false


# --- конец заглушек ---


const EX_DEAL := ["нет", "базовое", "расширенное", "полный союз"]
const EX_TAR := ["нет", "лёгкие", "заметные", "торговая война"]
# убывающая отдача: вклад ступеней соглашения/пошлин (ступень 3 ≠ втрое больше ступени 1)
const EX_GAIN := [0.0, 1.0, 1.7, 2.2]
const EX_LOSS := [0.0, 1.0, 1.8, 2.6]

var ex := {}
var ex_rng := RandomNumberGenerator.new()

func ex_init() -> void:
	ex_rng.seed = hash(ccode) + 133
	ex = {"p": {}, "hist": []}
	for c in wsim:
		if c == ccode:
			continue
		ex["p"][c] = {"deal": 0, "tar": 0, "ret": 0, "aid": 0.0, "dbuy": 0, "infl": 50.0, "cd": {}}


func ex_partners() -> Array:
	var out: Array = []
	for c in wsim:
		if c != ccode and (ex["p"] as Dictionary).has(c) and wsim.has(c):
			out.append(c)
	return out


func ex_rel_change(cc: String, d: float) -> void:
	if dip.has(cc):
		dip_change(cc, d)
	else:
		(fst["rel_x"] as Dictionary)[cc] = clampf(float((fst["rel_x"] as Dictionary).get(cc, 0.0)) + d, -40.0, 45.0)


func ex_cd_get(cc: String, k: String) -> int:
	return int(ex["p"][cc]["cd"].get(k, 0))


func ex_dep(cc: String) -> Dictionary:
	if not wsim.has(cc) or not (ex["p"] as Dictionary).has(cc):
		return {"tr_out": 0.0, "tr_in": 0.0, "en_out": 0.0, "en_in": 0.0, "fin_out": 0.0, "fin_in": 0.0, "out": 0.0, "in": 0.0, "bal": 0.0, "debt_x": 0.0}
	# зависимости в % ВВП своей страны: out — ваша зависимость от cc, in — зависимость cc от вас
	var d := {}
	var tr_out: float = w_share(ccode, cc)
	var tr_in: float = w_share(cc, ccode)
	var p: Dictionary = ex["p"][cc]
	var cf: Dictionary = soc_cfg()
	var cx: Dictionary = (SOC["country"] as Dictionary).get(cc, {})
	var en_out := 0.0
	var en_in := 0.0
	if int(cx.get("exporter", 0)) == 1 and int(cf.get("exporter", 0)) == 0:
		en_out = float(cf["en"]) * 0.10
	if int(cf.get("exporter", 0)) == 1 and int(cx.get("exporter", 0)) == 0:
		en_in = float(cx.get("en", 0.5)) * 0.10
	var tot_o := 0.0
	var tot_i := 0.0
	for c in wsim:
		if c != ccode:
			tot_o += w_share(ccode, c)
	for c2 in wsim:
		if c2 != cc:
			tot_i += w_share(cc, c2)
	var fin_out: float = float(cf["fdebt"]) * debt / maxf(1.0, gdp) * w_share(ccode, cc) / maxf(0.0001, tot_o)
	var gx: float = float(wsim[cc]["gdp"])
	var debt_x: float = float(wsim[cc]["debt"]) / 100.0 * gx
	var fin_in: float = float(cx.get("fdebt", 0.4)) * float(wsim[cc]["debt"]) / 100.0 * w_share(cc, ccode) / maxf(0.0001, tot_i) * 0.0
	# ваши вложения в долг cc делают cc зависимее от вас
	fin_in += float(p["dbuy"]) * 0.004
	var mult: float = 1.0 + 0.25 * float(p["deal"]) - 0.2 * float(p["tar"])
	d["tr_out"] = tr_out * mult * 100.0
	d["tr_in"] = tr_in * mult * 100.0
	d["en_out"] = en_out * 100.0
	d["en_in"] = en_in * 100.0
	d["fin_out"] = fin_out * 100.0
	d["fin_in"] = fin_in * 100.0
	d["out"] = float(d["tr_out"]) + float(d["en_out"]) + float(d["fin_out"])
	d["in"] = float(d["tr_in"]) + float(d["en_in"]) + float(d["fin_in"])
	d["bal"] = float(d["in"]) - float(d["out"])
	d["debt_x"] = debt_x
	return d


func ex_leverage(cc: String) -> float:
	# ваше влияние на cc, 0..100 (50 — равновесие)
	var d := ex_dep(cc)
	var p: Dictionary = ex["p"][cc]
	return clampf(50.0 + 2.0 * float(d["bal"]) + 0.2 * (fed_rel(cc) - 50.0) + 4.0 * float(p["deal"]) + 5.0 * float(p["dbuy"]) + float(p["aid"]), 0.0, 100.0)


func ex_leverage_on_us(cc: String) -> float:
	var d := ex_dep(cc)
	return clampf(50.0 - 2.0 * float(d["bal"]) - 0.2 * (fed_rel(cc) - 50.0) - 3.0 * float(ex["p"][cc]["ret"]), 0.0, 100.0)


func ex_g() -> float:
	# вклад торговой политики и давления партнёров в ваш рост, п.п. в год
	if not ex.has("p"):
		return 0.0
	var g := 0.0
	for c in ex["p"]:
		if not wsim.has(c):
			continue
		var p: Dictionary = ex["p"][c]
		if int(p["deal"]) == 0 and int(p["tar"]) == 0 and int(p["ret"]) == 0:
			continue
		var t: float = w_share(ccode, c)
		g += 0.4 * float(EX_GAIN[int(p["deal"])]) * t - 0.5 * float(EX_LOSS[int(p["tar"])]) * t - 0.8 * float(EX_LOSS[int(p["ret"])]) * t
	return g


func ex_infl() -> float:
	if not ex.has("p"):
		return 0.0
	var s := 0.0
	for c in ex["p"]:
		if not wsim.has(c):
			continue
		var p: Dictionary = ex["p"][c]
		s += (0.8 * float(EX_LOSS[int(p["tar"])]) + 0.4 * float(EX_LOSS[int(p["ret"])])) * w_share(ccode, c)
	return s


func ex_bot_g(c: String) -> float:
	# вклад ваших мер в рост страны-бота, п.п. в год
	if not ex.has("p") or not (ex["p"] as Dictionary).has(c):
		return 0.0
	var p: Dictionary = ex["p"][c]
	if int(p["deal"]) == 0 and int(p["tar"]) == 0 and int(p["ret"]) == 0 and float(p["aid"]) == 0.0 and int(p["dbuy"]) == 0:
		return 0.0
	var t: float = w_share(c, ccode)
	return 0.5 * float(EX_GAIN[int(p["deal"])]) * t - 0.9 * float(EX_LOSS[int(p["tar"])]) * t - 0.3 * float(EX_LOSS[int(p["ret"])]) * t + 0.02 * float(p["aid"]) + 0.1 * float(p["dbuy"])


func ex_month() -> void:
	if not ex.has("p"):
		return
	var evs: int = int(game_opts.get("exev", 1))
	var lv_sum := 0.0
	var lv_n := 0
	for c in (ex["p"] as Dictionary).keys():
		if not wsim.has(c):
			ex["p"].erase(c)
			continue
		var p: Dictionary = ex["p"][c]
		for k in (p["cd"] as Dictionary).keys():
			p["cd"][k] = int(p["cd"][k]) - 1
			if int(p["cd"][k]) <= 0:
				(p["cd"] as Dictionary).erase(k)
		p["aid"] = float(p["aid"]) * 0.97
		if float(p["aid"]) < 0.2:
			p["aid"] = 0.0
		if int(p["dbuy"]) > 0:
			debt -= ex_dbuy_amt(c) * float(p["dbuy"]) * 0.03 / 12.0
		if evs == 1:
			if int(p["tar"]) > int(p["ret"]) and ex_rng.randf() < 0.22:
				p["ret"] = int(p["ret"]) + 1
				ex_rel_change(c, -4.0)
				log_tag("ТОРГОВЛЯ", COL_WARN, "%s — «%s» вводит ответные пошлины (уровень %d)." % [date_text(), WORLD[c]["name"], int(p["ret"])])
			elif int(p["tar"]) < int(p["ret"]) and not fa_sanctioning(c) and ex_rng.randf() < 0.12:
				p["ret"] = int(p["ret"]) - 1
				log_tag("ТОРГОВЛЯ", COL_GOOD, "%s — «%s» смягчает ответные пошлины (уровень %d)." % [date_text(), WORLD[c]["name"], int(p["ret"])])
		# рейтинг влияния
		var lv: float = ex_leverage(c)
		p["infl"] = float(p["infl"]) + (lv - float(p["infl"])) * 0.2
		lv_sum += lv
		lv_n += 1
	if lv_n > 0:
		(ex["hist"] as Array).append(lv_sum / float(lv_n))
		if (ex["hist"] as Array).size() > 144:
			(ex["hist"] as Array).pop_front()
	if evs == 1:
		ex_events()


func ex_events() -> void:
	if not current_event.is_empty() or election_open:
		return
	if ex_rng.randf() > 0.035:
		return
	var parts: Array = ex_partners()
	if parts.is_empty():
		return
	var c: String = String(parts[ex_rng.randi() % parts.size()])
	var p: Dictionary = ex["p"][c]
	var nm: String = String(WORLD[c]["name"])
	var rel: float = fed_rel(c)
	var cx: Dictionary = (SOC["country"] as Dictionary).get(c, {})
	var kinds: Array = []
	if rel < 52.0 and ex_leverage_on_us(c) > 45.0 and int(p["ret"]) < 2:
		kinds.append("tariff")
	if rel >= 55.0 and int(p["deal"]) < 3 and w_share(ccode, c) > 0.02:
		kinds.append("deal")
	if int(cx.get("exporter", 0)) == 1 and float(soc_cfg()["en"]) > 0.3:
		kinds.append("energy")
	if not (wsim[c]["crisis"] as Dictionary).is_empty():
		kinds.append("aid")
	if kinds.is_empty():
		return
	var k: String = String(kinds[ex_rng.randi() % kinds.size()])
	if k == "tariff":
		soc_push_event({"t": "«%s» объявляет новые пошлины на ваш экспорт, ссылаясь на «несправедливую конкуренцию». Ваша зависимость от этого рынка делает удар чувствительным." % nm, "o": [
			{"l": "Уступить: пересмотреть спорные субсидии (долг +0.15% ВВП)", "fx": {"debt": 0.15, "support": {"Бизнес": -1.0}, "soc": {"rel": {c: 4.0}}}},
			{"l": "Принять удар и искать новые рынки", "fx": {"support": {"Бизнес": -2.0}, "soc": {"ex": {"cc": c, "ret": 1}, "rel": {c: -3.0}}}},
			{"l": "Ответные пошлины", "fx": {"support": {"Рабочие": 1.0, "Бизнес": -2.0}, "soc": {"ex": {"cc": c, "ret": 1, "tar": 1}, "rel": {c: -6.0}}}}]})
	elif k == "deal":
		soc_push_event({"t": "«%s» предлагает расширить торговое соглашение: меньше барьеров для обеих сторон, но и больше взаимной зависимости." % nm, "o": [
			{"l": "Принять (капитал -4)", "fx": {"capital": -4.0, "support": {"Бизнес": 2.0}, "soc": {"ex": {"cc": c, "deal": 1}, "rel": {c: 4.0}}}},
			{"l": "Отказаться: сохранить самостоятельность", "fx": {"support": {"Рабочие": 1.0}, "soc": {"rel": {c: -2.0}}}}]})
	elif k == "energy":
		soc_push_event({"t": "«%s» — ключевой поставщик энергии — повышает цены на контракты. Ваша зависимость от импортной энергии делает вас уязвимыми." % nm, "o": [
			{"l": "Согласиться на новые цены (долг +0.2% ВВП)", "fx": {"debt": 0.2, "infl": 0.15, "soc": {"rel": {c: 2.0}}}},
			{"l": "Торговаться и искать альтернативы (капитал -5)", "fx": {"capital": -5.0, "shock": -0.1, "soc": {"rel": {c: -2.0}}}}]})
	else:
		soc_push_event({"t": "«%s» переживает кризис и просит финансовой помощи у соседей. Помощь укрепит ваше влияние там." % nm, "o": [
			{"l": "Выделить помощь (долг +0.15% ВВП)", "fx": {"debt": 0.15, "support": {"Бизнес": -1.0}, "soc": {"ex": {"cc": c, "aid": 12.0}, "rel": {c: 5.0}}}},
			{"l": "Отказать", "fx": {"soc": {"rel": {c: -3.0}}}}]})


func ex_fx(d: Dictionary) -> void:
	var c: String = String(d.get("cc", ""))
	if c == "" or not ex.has("p") or not (ex["p"] as Dictionary).has(c):
		return
	var p: Dictionary = ex["p"][c]
	if d.has("ret"):
		p["ret"] = clampi(int(p["ret"]) + int(d["ret"]), 0, 3)
	if d.has("tar"):
		p["tar"] = clampi(int(p["tar"]) + int(d["tar"]), 0, 3)
	if d.has("deal"):
		p["deal"] = clampi(int(p["deal"]) + int(d["deal"]), 0, 3)
	if d.has("aid"):
		p["aid"] = minf(40.0, float(p["aid"]) + float(d["aid"]))


# ---------------- действия игрока ----------------


func ex_cap(cost: float) -> bool:
	return soc_spend(cost)


func ex_deal_set(c: String, dir: int) -> bool:
	var p: Dictionary = ex["p"][c]
	var v: int = int(p["deal"]) + dir
	if v < 0 or v > 3 or ex_cd_get(c, "deal") > 0:
		return false
	if dir > 0 and fed_rel(c) < 50.0:
		log_line("[color=%s]«%s» не хочет углублять соглашение: отношения ниже 50.[/color]" % [COL_BAD, WORLD[c]["name"]])
		return false
	if not ex_cap(10.0 if dir > 0 else 3.0):
		return false
	p["deal"] = v
	p["cd"]["deal"] = 12
	ex_rel_change(c, 4.0 if dir > 0 else -3.0)
	add_support("Бизнес", 1.5 if dir > 0 else -1.0)
	log_line("[b]%s: торговое соглашение с «%s» — %s.[/b]" % [date_text(), WORLD[c]["name"], EX_DEAL[v]])
	fa_notify("deal", c, float(dir))
	refresh()
	return true


func ex_tariff_set(c: String, dir: int) -> bool:
	var p: Dictionary = ex["p"][c]
	var v: int = int(p["tar"]) + dir
	if v < 0 or v > 3 or ex_cd_get(c, "tar") > 0:
		return false
	if not ex_cap(6.0 if dir > 0 else 2.0):
		return false
	p["tar"] = v
	p["cd"]["tar"] = 6
	if dir > 0:
		ex_rel_change(c, -8.0)
		add_support("Рабочие", 1.0)
		add_support("Бизнес", -1.5)
	else:
		ex_rel_change(c, 3.0)
	log_line("[b]%s: пошлины против «%s» — %s.[/b]" % [date_text(), WORLD[c]["name"], EX_TAR[v]])
	fa_notify("tariff", c, float(dir))
	refresh()
	return true


func ex_aid_give(c: String) -> bool:
	var p: Dictionary = ex["p"][c]
	if ex_cd_get(c, "aid") > 0:
		return false
	if not ex_cap(3.0):
		return false
	debt += gdp * 0.1 / 100.0
	p["aid"] = minf(40.0, float(p["aid"]) + 8.0)
	p["cd"]["aid"] = 6
	ex_rel_change(c, 3.0)
	add_support("Бизнес", -0.5)
	log_line("%s: помощь и инвестиции в «%s» (0.1%% ВВП в долг): влияние растёт." % [date_text(), WORLD[c]["name"]])
	fa_notify("aid", c, 1.0)
	refresh()
	return true


func ex_dbuy_amt(c: String) -> float:
	# размер одной «ступени» вложений в долг партнёра, млрд: 0,4% его ВВП, но не больше 1,5% ВВП вашей страны (малым странам не по силам крупные покупки)
	return minf(float(wsim[c]["gdp"]) * 0.004, gdp * 0.015)


func ex_dbuy_set(c: String, dir: int) -> bool:
	var p: Dictionary = ex["p"][c]
	var v: int = int(p["dbuy"]) + dir
	if v < 0 or v > 3 or ex_cd_get(c, "dbuy") > 0:
		return false
	if not ex_cap(5.0):
		return false
	var amt: float = ex_dbuy_amt(c)
	if dir > 0:
		debt += amt
	else:
		debt = maxf(0.0, debt - amt)
		ex_rel_change(c, -2.0)
	p["dbuy"] = v
	p["cd"]["dbuy"] = 6
	log_line("%s: вложения в госдолг «%s» — уровень %d (%.0f млрд)." % [date_text(), WORLD[c]["name"], v, amt * float(v)])
	refresh()
	return true


func ex_favor(c: String, kind: String) -> bool:
	var p: Dictionary = ex["p"][c]
	if ex_cd_get(c, "favor") > 0 or float(p["infl"]) < 60.0:
		return false
	if kind == "tariff" and int(p["ret"]) == 0:
		return false
	if not ex_cap(6.0):
		return false
	p["cd"]["favor"] = 12
	p["infl"] = float(p["infl"]) - 6.0
	if kind == "bonds":
		risk_prem = maxf(0.0, risk_prem - 0.2)
		log_line("%s: «%s» по вашей просьбе скупает ваши облигации — ставки по долгу снижены." % [date_text(), WORLD[c]["name"]])
	else:
		p["ret"] = maxi(0, int(p["ret"]) - 1)
		log_line("%s: «%s» по вашей просьбе смягчает пошлины против вас." % [date_text(), WORLD[c]["name"]])
	refresh()
	return true
