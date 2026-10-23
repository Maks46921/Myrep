# Финансы (0.63): банки (капитал, плохие кредиты, кредит экономике, пузыри, банковский кризис и его решения) и фондовая биржа.
extends "res://scripts/logic/cbank63.gd"

const FIN_CRIS := {
	"bubble": {"n": "лопнул пузырь", "t": "Лопнул пузырь на рынке недвижимости и кредита: цены падают, заёмщики не платят, банки несут убытки."},
	"rates": {"n": "резкий рост ставок", "t": "Ставки выросли слишком быстро: заёмщики не справляются с платежами, банки теряют на облигациях."},
	"sovereign": {"n": "долговой кризис", "t": "Госдолг обесценился: банки держат его в больших объёмах и теряют капитал."},
	"external": {"n": "внешний шок", "t": "Мировой финансовый шок: иностранные деньги уходят, банки теряют фондирование."},
	"panic": {"n": "паника вкладчиков", "t": "Вкладчики выстроились в очереди за деньгами: банки не успевают выдавать вклады."},
}


# ============================================================
#  БАНКИ
# ============================================================
func fin_bank_step() -> void:
	var b: Dictionary = fin["bk"]
	var cris: Dictionary = b["cris"]
	var gap: float = float(ec["real_gap"])
	var reg0: int = int(fin_data()["reg"])
	var on: bool = bool(cris["on"])
	var sev: float = float(cris["sev"]) if on else 0.0
	# кредитное сжатие
	var crunch_t: float = clampf(0.25 * sev, 0.0, 1.0) * (1.0 - 0.5 * float(b["state"]) / 100.0) if on else 0.0
	b["crunch"] = float(b["crunch"]) + (crunch_t - float(b["crunch"])) * rt(0.15, wdt)
	# кредит экономике
	var cr0: float = float(b["cr0"])
	var cr_t: float = cr0 * (1.0 + 0.04 * (growth_ema - G_NEU) - 0.03 * gap - 0.35 * float(b["crunch"]) - 0.02 * (float(b["reg"]) - reg0))
	b["cr"] = clampf(float(b["cr"]) + (cr_t - float(b["cr"])) * rt(0.04, wdt), cr0 * 0.4, cr0 * 1.8)
	var q: float = float(b["cr"]) / maxf(1.0, cr0)
	# пузыри: кредитный бум и недвижимость
	b["bub_c"] = clampf(float(b["bub_c"]) + clampf((q - 1.08) * 60.0, -3.0, 6.0) * wdt, 0.0, 100.0)
	var regk: float = 0.4 * (float(b["reg"]) - 1.0)
	b["bub_h"] = clampf(float(b["bub_h"]) + (-gap * 1.5 + (q - 1.0) * 30.0 - 1.0 - regk) * wdt, 0.0, 100.0)
	if float(b["bub_h"]) > 70.0 and randf() < wp(0.04 * (float(b["bub_h"]) - 70.0) / 30.0 * sqrt(fin_cr_mult())):
		fin_bubble_burst("h")
	elif float(b["bub_c"]) > 75.0 and randf() < wp(0.03 * (float(b["bub_c"]) - 75.0) / 25.0 * sqrt(fin_cr_mult())):
		fin_bubble_burst("c")
	# плохие кредиты
	b["shock"] = float(b["shock"]) * wdec(0.97)
	var npl_t: float = float(b["npl0"]) + 0.45 * (unemployment - U_NEU) - 0.35 * (growth - G_NEU) + float(b["shock"])
	npl_t += 0.04 * maxf(0.0, float(fin["db"]["mkt"]) * 100.0 - 5.0)
	b["npl"] = clampf(float(b["npl"]) + (npl_t - float(b["npl"])) * rt(0.06, wdt), 0.3, 60.0)
	# капитал
	b["inj"] = float(b.get("inj", 0.0)) * wdec(0.98)
	var spr: float = float(fin["db"]["spr"])
	var car_t: float = float(b["car0"]) - 0.5 * (float(b["npl"]) - float(b["npl0"])) + 1.2 * (float(b["reg"]) - reg0) + float(b["inj"])
	car_t -= 0.12 * maxf(0.0, spr - 2.0) * float(b["sov"]) / 8.0
	b["car"] = clampf(float(b["car"]) + (car_t - float(b["car"])) * rt(0.08, wdt), 2.0, 40.0)
	# доверие вкладчиков
	var ins: int = int(b["ins"])
	var tr_t: float = 74.0 + 6.0 * ins - 2.0 * maxf(0.0, float(b["npl"]) - float(b["npl0"]) - 2.0) - 3.0 * maxf(0.0, 12.0 - float(b["car"])) - 10.0 * sev
	if ins >= 2:
		tr_t = maxf(tr_t, 60.0)
	b["trust"] = clampf(float(b["trust"]) + (tr_t - float(b["trust"])) * rt(0.2, wdt), 3.0, 100.0)
	var trust: float = float(b["trust"])
	if trust < 40.0:
		ec["fx_shock"] = float(ec["fx_shock"]) - (40.0 - trust) * 0.0004 * wdt
	if trust < 25.0 and not on:
		fin_bank_crisis("panic", 2.0)
		return
	if on:
		fin_cris_step(cris)
	elif fin_cd("bk_quiet") == 0:
		fin_cris_roll()


# вероятность нового банковского кризиса: в среднем раз в 8–12 лет, выше при пузырях, слабом капитале, скачке ставок
func fin_cris_roll() -> void:
	var b: Dictionary = fin["bk"]
	var spr: float = float(fin["db"]["spr"])
	var vul: float = 1.0 + maxf(0.0, 12.0 - float(b["car"])) * 0.15 + maxf(0.0, float(b["npl"]) - 6.0) * 0.1 + float(b["mh"]) * 0.08
	var rup: float = float(b.get("rate_up", 0.0))
	var risk: float = 1.0 + 0.02 * float(b["bub_h"]) + 0.02 * float(b["bub_c"]) + 0.4 * maxf(0.0, rup - 1.0) + (0.5 if spr > 6.0 else 0.0) + 2.0 * float(fin["w"]["shock"]) + (0.6 if float(b["trust"]) < 50.0 else 0.0)
	var p: float = 0.0083 * fin_cr_mult() * risk * vul
	if turn - int(b["stress_t"]) < 24:
		p *= 0.7
	if randf() >= wp(p):
		return
	# причина: что сильнее всего давит
	var wts := {
		"bubble": maxf(0.0, maxf(float(b["bub_h"]), float(b["bub_c"])) - 40.0) / 20.0,
		"rates": maxf(0.0, rup - 1.0) * 2.0,
		"sovereign": maxf(0.0, spr - 4.0) / 3.0 * float(b["sov"]) / 8.0,
		"external": float(fin["w"]["shock"]) * 3.0 + 0.3,
		"panic": 2.0 if float(b["trust"]) < 55.0 else 0.0,
	}
	var tot := 0.0
	for k in wts:
		tot += float(wts[k])
	var r: float = randf() * tot
	var kind := "external"
	for k in wts:
		r -= float(wts[k])
		if r <= 0.0:
			kind = String(k)
			break
	var s: float = 0.8 + randf() * 0.8 + (float(b["bub_h"]) + float(b["bub_c"])) * 0.006 + maxf(0.0, 12.0 - float(b["car"])) * 0.08 + maxf(0.0, float(b["npl"]) - 6.0) * 0.05
	fin_bank_crisis(kind, clampf(roundf(s), 1.0, 3.0))


func fin_bubble_burst(which: String) -> void:
	var b: Dictionary = fin["bk"]
	var ex: Dictionary = fin["ex"]
	var lvl: float = float(b["bub_h"]) if which == "h" else float(b["bub_c"])
	b["shock"] = float(b["shock"]) + 1.5 + lvl * 0.03
	b["bub_h" if which == "h" else "bub_c"] = 15.0
	ec["cconf"] = clampf(float(ec["cconf"]) - 8.0, 0.0, 100.0)
	ex["idx"] = float(ex["idx"]) * 0.93
	fin_mood_hit(-6.0)
	fin_note("банки", "Пузырь лопнул: %s. Банки получают плохие кредиты, потребители пугаются." % ("цены на жильё рушатся" if which == "h" else "кредитный бум закончился"), COL_BAD)
	if not bool(b["cris"]["on"]) and randf() < 0.5:
		fin_bank_crisis("bubble", clampf(roundf(1.0 + lvl / 50.0), 1.0, 3.0))


func fin_bank_crisis(kind: String, sev: float) -> void:
	var b: Dictionary = fin["bk"]
	var cris: Dictionary = b["cris"]
	if bool(cris["on"]):
		return
	cris["on"] = true
	cris["kind"] = kind
	cris["sev"] = sev
	cris["left"] = 6.0 + sev * 6.0
	cris["wait"] = 0.0
	cris["wait_on"] = false
	cris["decided"] = false
	cris["start"] = turn
	b["count"] = int(b["count"]) + 1
	b["shock"] = float(b["shock"]) + 1.2 * sev
	b["inj"] = float(b.get("inj", 0.0)) - 1.5 * sev
	b["trust"] = maxf(5.0, float(b["trust"]) - 12.0 * sev)
	fin["ex"]["idx"] = float(fin["ex"]["idx"]) * pow(0.95, sev)
	fin_mood_hit(-5.0 * sev)
	fin_note("банки", "Банковский кризис (%s, тяжесть %d из 3). %s" % [String(FIN_CRIS[kind]["n"]), int(sev), String(FIN_CRIS[kind]["t"])], COL_BAD)
	fin_bank_crisis_event()


func fin_bank_crisis_event() -> void:
	var b: Dictionary = fin["bk"]
	var cris: Dictionary = b["cris"]
	if not bool(cris["on"]) or bool(cris.get("decided", false)):
		return
	if not current_event.is_empty() or election_open:
		b["pend"] = true
		return
	b["pend"] = false
	var sev: float = float(cris["sev"])
	var ins2: bool = int(b["ins"]) >= 2
	var opts: Array = [
		{"l": "Спасти банки за счёт бюджета (долг +%.1f%% ВВП)" % (0.8 * sev), "fx": {}, "act": "bk_bailout"},
		{"l": ("Bail-in: потери несут акционеры и крупные вкладчики (вклады гарантированы, эффект слабее)" if ins2 else "Bail-in: потери несут акционеры и крупные вкладчики"), "fx": {}, "act": "bk_bailin"},
		{"l": "Национализировать проблемные банки (долг +%.1f%% ВВП)" % (0.5 * sev), "fx": {}, "act": "bk_nat"},
		{"l": "Гарантировать все вклады (долг +%.1f%% ВВП, риск на будущее)" % (0.3 * sev), "fx": {}, "act": "bk_guar"},
		{"l": "Ждать: пусть рынок сам", "fx": {}, "act": "bk_wait"}]
	fin_event("bank", "[b]Банковский кризис — %s.[/b] %s Капитал банков %.1f%%, плохие кредиты %.1f%%, доверие вкладчиков %.0f%%. Что делать?" % [String(FIN_CRIS[String(cris["kind"])]["n"]), String(FIN_CRIS[String(cris["kind"])]["t"]), float(b["car"]), float(b["npl"]), float(b["trust"])], opts)


func fin_cris_step(cris: Dictionary) -> void:
	var b: Dictionary = fin["bk"]
	cris["left"] = float(cris["left"]) - wdt
	if bool(b["pend"]) and current_event.is_empty() and not election_open:
		fin_bank_crisis_event()
	if bool(cris.get("wait_on", false)):
		cris["sev"] = minf(3.5, float(cris["sev"]) + 0.08 * wdt)
		cris["left"] = float(cris["left"]) + 0.3 * wdt
	if float(cris["left"]) <= 0.0:
		if float(b["trust"]) > 55.0 and float(b["car"]) >= float(b["car0"]) * 0.65:
			cris["on"] = false
			cris["decided"] = false
			cris["sev"] = 0.0
			fin_cd_set("bk_quiet", 12)
			fin_note("банки", "Банковский кризис закончился: капитал и доверие вкладчиков восстановились.", COL_GOOD)
		else:
			cris["left"] = 3.0


func fin_month_bank() -> void:
	var b: Dictionary = fin["bk"]
	var rs: Array = b["rates"]
	rs.append(float(ec["rate"]))
	while rs.size() > 7:
		rs.pop_front()
	b["rate_up"] = float(ec["rate"]) - float(rs[0])
	b["mh"] = maxf(0.0, float(b["mh"]) - 0.02)
	b["sov"] = clampf(float(b["sov"]) + (6.0 + maxf(0.0, debt / maxf(gdp, 1.0) * 100.0 - 50.0) * 0.08 - float(b["sov"])) * 0.1, 3.0, 25.0)
	fin_ex_month()
	if bool(b["pend"]) and current_event.is_empty():
		fin_bank_crisis_event()


func fin_stress_shortfall() -> float:
	# нехватка капитала банков при стрессе, % ВВП
	var b: Dictionary = fin["bk"]
	var sc: float = float(b["car"]) - 0.8 * (float(b["npl"]) + 4.0 + float(b["bub_h"]) * 0.05 - float(b["npl0"]))
	return maxf(0.0, 9.0 - sc) / 100.0 * float(b["cr"]) * 1.3


func fin_acts_bank() -> Array:
	var out: Array = []
	var b: Dictionary = fin["bk"]
	var cris: Dictionary = b["cris"]
	var sev: float = float(cris["sev"])
	if bool(cris["on"]):
		var dec: bool = bool(cris.get("decided", false))
		var why := "решение уже принято" if dec else ""
		out.append({"id": "bk_bailout", "grp": "Кризис", "name": "Спасти банки за счёт бюджета (долг +%.1f%% ВВП)" % (0.8 * sev), "cap": 0.0, "ok": not dec, "why": why, "desc": "Капитал банков +4, доверие вкладчиков восстанавливается. Но налогоплательщики платят, а банки привыкают к спасению: будущие кризисы вероятнее."})
		out.append({"id": "bk_bailin", "grp": "Кризис", "name": "Bail-in: потери несут акционеры и вкладчики", "cap": 0.0, "ok": not dec, "why": why, "desc": "Бюджет не платит. Крупные вклады и акции частично списываются: капитал растёт, но доверие вкладчиков падает, бизнес недоволен."})
		out.append({"id": "bk_nat", "grp": "Кризис", "name": "Национализировать проблемные банки (долг +%.1f%% ВВП)" % (0.5 * sev), "cap": 0.0, "ok": not dec, "why": why, "desc": "Государство берёт банки под контроль: кредит стабилен, но долго неэффективен. Бизнес против, рабочие довольны."})
		out.append({"id": "bk_guar", "grp": "Кризис", "name": "Гарантировать все вклады (долг +%.1f%% ВВП)" % (0.3 * sev), "cap": 0.0, "ok": not dec, "why": why, "desc": "Паника прекращается сразу, но государство отвечает по всем вкладам, а банки идут на риск."})
	out.append({"id": "bk_stress", "grp": "Надзор", "name": "Стресс-тест банков", "cap": 4.0, "cd": 24, "desc": "Проверка устойчивости: покажет, сколько капитала банкам не хватит при ударе. Снижает вероятность кризиса на два года, а выявленные дыры можно закрыть."})
	var sh: float = float(b.get("stress_short", 0.0))
	out.append({"id": "bk_recap", "grp": "Надзор", "name": "Докапитализировать слабые банки (по итогам теста)", "cap": 2.0, "cd": 12, "ok": sh > 0.0, "why": "стресс-тест не выявил нехватки" if sh <= 0.0 else "", "desc": "Закрыть нехватку капитала, найденную тестом: %.2f%% ВВП из бюджета. Капитал и доверие растут, кризис становится менее вероятным." % sh})
	out.append({"id": "bk_reg_up", "grp": "Надзор", "name": "Ужесточить надзор (сейчас %d из 3)" % int(b["reg"]), "cap": 6.0, "cd": 24, "ok": int(b["reg"]) < 3, "why": "предел", "desc": "Требования к капиталу и кредитам выше: банки устойчивее, пузыри растут медленнее, но кредит дороже и рост чуть ниже."})
	out.append({"id": "bk_reg_dn", "grp": "Надзор", "name": "Ослабить надзор", "cap": 2.0, "cd": 24, "ok": int(b["reg"]) > 0, "why": "предел", "desc": "Банки охотнее кредитуют: рост и кредит выше, но растут пузыри и риск кризиса."})
	out.append({"id": "bk_ins_up", "grp": "Вклады", "name": "Расширить страхование вкладов", "cap": 4.0, "cd": 24, "ok": int(b["ins"]) < 2, "why": "уже полное", "desc": "Вклады застрахованы шире: паника вкладчиков менее вероятна, но риск для бюджета и азарт банков выше."})
	out.append({"id": "bk_ins_dn", "grp": "Вклады", "name": "Сузить страхование вкладов", "cap": 2.0, "cd": 24, "ok": int(b["ins"]) > 0, "why": "уже нет", "desc": "Дешевле для бюджета и меньше азарта у банков, но вкладчики нервничают при любых новостях."})
	return out


func fin_act_bank(id: String, opt: Dictionary) -> bool:
	var b: Dictionary = fin["bk"]
	var cris: Dictionary = b["cris"]
	var sev: float = maxf(1.0, float(cris["sev"]))
	match id:
		"bk_bailout":
			debt += gdp * 0.008 * sev
			b["inj"] = float(b.get("inj", 0.0)) + 4.0 * sev
			b["car"] = minf(40.0, float(b["car"]) + 3.0 * sev)
			b["trust"] = minf(100.0, float(b["trust"]) + 15.0)
			b["mh"] = float(b["mh"]) + 1.0
			cris["left"] = float(cris["left"]) * 0.6
			cris["decided"] = true
			add_support("Бизнес", 2.0)
			add_support("Рабочие", -2.0)
			fin_note("банки", "Банки спасены за счёт бюджета: долг вырос на %.1f%% ВВП." % (0.8 * sev), COL_WARN)
		"bk_bailin":
			var ins2: bool = int(b["ins"]) >= 2
			b["inj"] = float(b.get("inj", 0.0)) + (1.5 if ins2 else 3.0) * sev
			b["car"] = minf(40.0, float(b["car"]) + (1.5 if ins2 else 3.0) * sev)
			b["trust"] = maxf(5.0, float(b["trust"]) - (3.0 if ins2 else 8.0))
			b["mh"] = maxf(0.0, float(b["mh"]) - 0.5)
			cris["left"] = float(cris["left"]) * 0.8
			cris["decided"] = true
			add_support("Бизнес", -3.0)
			add_support("Пенсионеры", -1.0)
			fin_note("банки", "Bail-in: убытки списаны на акционеров и крупных вкладчиков, бюджет не пострадал.", COL_WARN)
		"bk_nat":
			debt += gdp * 0.005 * sev
			b["state"] = minf(100.0, float(b["state"]) + 30.0)
			b["inj"] = float(b.get("inj", 0.0)) + 3.0 * sev
			b["car"] = minf(40.0, float(b["car"]) + 2.0 * sev)
			b["trust"] = minf(100.0, float(b["trust"]) + 10.0)
			b["crunch"] = float(b["crunch"]) * 0.6
			cris["left"] = float(cris["left"]) * 0.7
			cris["decided"] = true
			add_support("Бизнес", -4.0)
			add_support("Рабочие", 2.0)
			fin_note("банки", "Проблемные банки национализированы.", COL_WARN)
		"bk_guar":
			debt += gdp * 0.003 * sev
			b["ins"] = 2
			b["trust"] = maxf(float(b["trust"]), 85.0)
			b["mh"] = float(b["mh"]) + 1.0
			cris["left"] = float(cris["left"]) * 0.7
			cris["decided"] = true
			add_support("Пенсионеры", 2.0)
			fin_note("банки", "Государство гарантировало все вклады: паника остановлена.", COL_GOOD)
		"bk_wait":
			cris["wait_on"] = true
			cris["decided"] = true
			fin_note("банки", "Власть выжидает: кризис может углубиться.", COL_BAD)
		"bk_stress":
			var sh: float = fin_stress_shortfall()
			b["stress_t"] = turn
			b["stress_short"] = sh
			if sh > 0.0:
				b["trust"] = maxf(5.0, float(b["trust"]) - 3.0)
				fin_note("банки", "Стресс-тест: банкам при ударе не хватит капитала на %.2f%% ВВП. Дыру можно закрыть докапитализацией." % sh, COL_WARN)
			else:
				b["trust"] = minf(100.0, float(b["trust"]) + 3.0)
				fin_mood_hit(2.0)
				fin_note("банки", "Стресс-тест пройден: капитала хватает даже при сильном ударе.", COL_GOOD)
		"bk_recap":
			var sh2: float = float(b.get("stress_short", 0.0))
			debt += gdp * sh2 / 100.0
			b["inj"] = float(b.get("inj", 0.0)) + 3.0
			b["car"] = minf(40.0, float(b["car"]) + 2.0)
			b["trust"] = minf(100.0, float(b["trust"]) + 4.0)
			b["stress_short"] = 0.0
			fin_note("банки", "Слабые банки докапитализированы.", COL_GOOD)
		"bk_reg_up":
			b["reg"] = mini(3, int(b["reg"]) + 1)
			add_support("Бизнес", -1.0)
			fin_note("банки", "Банковский надзор ужесточён.", COL_TEAL)
		"bk_reg_dn":
			b["reg"] = maxi(0, int(b["reg"]) - 1)
			add_support("Бизнес", 1.0)
			fin_note("банки", "Банковский надзор ослаблен.", COL_WARN)
		"bk_ins_up":
			b["ins"] = mini(2, int(b["ins"]) + 1)
			if int(b["ins"]) >= 2:
				b["mh"] = float(b["mh"]) + 0.5
			fin_note("банки", "Страхование вкладов расширено.", COL_TEAL)
		"bk_ins_dn":
			b["ins"] = maxi(0, int(b["ins"]) - 1)
			b["trust"] = maxf(5.0, float(b["trust"]) - 5.0)
			fin_note("банки", "Страхование вкладов сужено.", COL_WARN)
		_:
			return false
	return true


# ============================================================
#  БИРЖА
# ============================================================
func fin_ex_step() -> void:
	var ex: Dictionary = fin["ex"]
	var b: Dictionary = fin["bk"]
	var w: Dictionary = fin["w"]
	var mult: float = 0.6 if bool(ex["restr"]) else 1.0
	var sq: float = sqrt(wdt)
	var drift: float = 1.0 + 1.0 * (growth - G_NEU) - 0.6 * (float(ec["rate"]) - RATE0) - 0.15 * maxf(0.0, float(fin["db"]["mkt"]) * 100.0 - 4.0) + 0.1 * (float(fin["mood"]) - 60.0) - 15.0 * float(w["shock"]) - float(ex["tax"]) * 3.0
	var f: float = float(ex["fund"])
	f = clampf(f * (1.0 + drift / 1200.0 * wdt + 0.045 * mult * sq * fin_rn() * 0.4), 20.0, 400.0)
	ex["fund"] = f
	if float(ex["closed"]) > 0.0:
		ex["closed"] = maxf(0.0, float(ex["closed"]) - wdt)
		if float(ex["closed"]) <= 0.0:
			ex["idx"] = float(ex["idx"]) + (f * (1.0 + float(ex["bub"]) / 100.0 * 0.6) - float(ex["idx"])) * 0.5
			fin_note("биржа", "Биржа открылась после закрытия.", COL_DIM)
		return
	var gap: float = float(ec["real_gap"])
	var bub: float = float(ex["bub"]) + (1.5 * maxf(0.0, -gap) + 0.08 * float(b["bub_c"]) + 0.04 * maxf(0.0, float(fin["mood"]) - 65.0) - 1.2) * wdt * (0.5 if bool(ex["restr"]) else 1.0)
	bub = clampf(bub, 0.0, 100.0)
	ex["bub"] = bub
	var old: float = float(ex["idx"])
	var nw: float = f * (1.0 + bub / 100.0 * 0.6)
	ex["idx"] = clampf(old + (nw - old) * rt(0.5, wdt), 10.0, 600.0)
	ex["ma"] = float(ex["ma"]) + (float(ex["idx"]) - float(ex["ma"])) * rt(0.05, wdt)
	ex["ret_w"] = float(ex["idx"]) / maxf(1.0, old) - 1.0
	if bub > 70.0 and randf() < wp(0.05 * (bub - 70.0) / 30.0 * sqrt(fin_cr_mult())):
		var drop: float = randf_range(0.2, 0.4)
		ex["idx"] = float(ex["idx"]) * (1.0 - drop)
		ex["fund"] = f
		ex["bub"] = 5.0
		ex["crash_t"] = turn
		b["shock"] = float(b["shock"]) + 0.6 + drop * 3.0
		ec["cconf"] = clampf(float(ec["cconf"]) - 6.0, 0.0, 100.0)
		fin_mood_hit(-7.0)
		fin_note("биржа", "Обвал биржи: индекс упал на %.0f%%. Потери инвесторов бьют по банкам и потреблению." % (drop * 100.0), COL_BAD)
		if not bool(b["cris"]["on"]) and randf() < 0.25:
			fin_bank_crisis("bubble", 1.0)


func fin_ex_month() -> void:
	var ex: Dictionary = fin["ex"]
	ex["mcap"] = maxf(1.0, float(fin_data()["mcap"]) * float(ex["idx"]) / 100.0)


func fin_acts_ex() -> Array:
	var out: Array = []
	var ex: Dictionary = fin["ex"]
	var m0: float = float(fin_data()["mcap"])
	var closed: bool = float(ex["closed"]) > 0.0
	for s in [1, 2, 3]:
		out.append({"id": "ex_ipo%d" % s, "grp": "Приватизация", "name": "IPO: разместить госкомпании на %d%% ВВП" % s, "cap": 6.0, "cd": 24, "ok": m0 >= 8.0 and not closed and fin_cd("ex_ipo1") + fin_cd("ex_ipo2") + fin_cd("ex_ipo3") == 0,
			"why": "биржа слишком мала" if m0 < 8.0 else ("биржа закрыта" if closed else "перерыв между размещениями"),
			"desc": "Продать акции госкомпаний: выручка идёт на погашение долга (примерно %.1f%% ВВП при нынешнем индексе), но рабочие и бюджетники недовольны, а индекс слегка падает от предложения." % (float(s) * (0.7 + 0.3 * float(ex["idx"]) / 100.0))})
	out.append({"id": "ex_tax_up", "grp": "Налоги", "name": "Налог на биржевые сделки +0,1%", "cap": 3.0, "cd": 6, "ok": float(ex["tax"]) < 0.5, "why": "предел", "desc": "Новый доход бюджета, но биржа дешевеет и охладевают спекулянты. Сейчас ставка %.1f%%." % float(ex["tax"])})
	out.append({"id": "ex_tax_dn", "grp": "Налоги", "name": "Налог на биржевые сделки −0,1%", "cap": 0.0, "cd": 6, "ok": float(ex["tax"]) > 0.0, "why": "налога нет", "desc": "Дешевле торговать, доход бюджета меньше."})
	out.append({"id": "ex_restr", "grp": "Регулирование", "name": ("Снять ограничения спекуляций" if bool(ex["restr"]) else "Ограничить спекуляции (запрет коротких продаж, лимиты)"), "cap": 4.0, "cd": 6,
		"desc": "Ограничения сглаживают пузыри и обвалы (колебания на 40% слабее), но инвесторы нервничают: доверие рынков падает."})
	out.append({"id": "ex_close1", "grp": "Регулирование", "name": "Закрыть биржу на 1 месяц", "cap": 6.0, "cd": 6, "ok": not closed, "why": "уже закрыта", "desc": "Остановить панику: курс акций заморожен. После открытия цены наверстают половину падения. Доверие рынков падает, бизнесу трудно."})
	out.append({"id": "ex_close3", "grp": "Регулирование", "name": "Закрыть биржу на 3 месяца", "cap": 10.0, "cd": 12, "ok": not closed, "why": "уже закрыта", "desc": "Долгое закрытие в тяжёлый кризис: глубже удар по доверию и росту."})
	return out


func fin_act_ex(id: String, opt: Dictionary) -> bool:
	var ex: Dictionary = fin["ex"]
	match id:
		"ex_ipo1", "ex_ipo2", "ex_ipo3":
			var s: float = float(id.substr(6))
			var rev: float = s * (0.7 + 0.3 * float(ex["idx"]) / 100.0)
			debt = maxf(0.0, debt - gdp * rev / 100.0)
			ex["ipo"] = float(ex["ipo"]) + rev
			ex["ipo_t"] = turn
			ex["idx"] = float(ex["idx"]) * (1.0 - 0.012 * s)
			for k in [1, 2, 3]:
				fin_cd_set("ex_ipo%d" % k, 24)
			add_support("Рабочие", -s)
			add_support("Бюджетники", -s * 0.7)
			add_support("Бизнес", 0.5 * s)
			fin_note("биржа", "IPO госкомпаний: выручка %.1f%% ВВП направлена на погашение долга." % rev, COL_GOOD)
		"ex_tax_up":
			ex["tax"] = minf(0.5, float(ex["tax"]) + 0.1)
			fin_note("биржа", "Налог на биржевые сделки: %.1f%%." % float(ex["tax"]), COL_DIM)
		"ex_tax_dn":
			ex["tax"] = maxf(0.0, float(ex["tax"]) - 0.1)
			fin_note("биржа", "Налог на биржевые сделки: %.1f%%." % float(ex["tax"]), COL_DIM)
		"ex_restr":
			ex["restr"] = not bool(ex["restr"])
			if bool(ex["restr"]):
				fin_mood_hit(-3.0)
			fin_note("биржа", "Спекуляции %s." % ("ограничены" if bool(ex["restr"]) else "свободны"), COL_DIM)
		"ex_close1", "ex_close3":
			ex["closed"] = 1.0 if id == "ex_close1" else 3.0
			fin_mood_hit(-8.0 if id == "ex_close1" else -14.0)
			ec["bconf"] = clampf(float(ec["bconf"]) - 4.0, 0.0, 100.0)
			fin_note("биржа", "Биржа закрыта на %d мес." % int(ex["closed"]), COL_WARN)
		_:
			return false
	return true
