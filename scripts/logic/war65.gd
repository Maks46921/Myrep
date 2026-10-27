# Затяжная война и «структурные» поправки 0.65: внешняя помощь жертве, усталость от войны, уход авторитарного лидера,
# страх протестов, потолок падения демократии при военном положении, цель по инфляции, зависимость Беларуси от нефти,
# влияние недовольства регионов на одобрение. Состояние — словарь x65 (state_data.gd). Опция game_opts["x65"]=0 выключает модуль.
extends "res://scripts/logic/debt63.gd"

# цель центробанка по инфляции (% в год): официальные цели (Россия 4%, но на деле центробанк терпит 5–6; Украина 5%; Беларусь 5%)
const X65_INFL := {"RU": 5.0, "BY": 6.0, "UA": 5.0, "MD": 5.0, "PM": 5.0}
# «якорь» инфляции — к нему тянут цены структурные причины (дефицит, импорт, ожидания): в этих странах он выше цели, поэтому
# инфляция в среднем держится на 5–8% (Россия 2015–2025: 5–9%, Беларусь: 5–10%, Украина 2023–2025: 5–12%), а не на цели
const X65_ANCH := {"RU": 7.6, "BY": 9.5, "UA": 12.0, "MD": 6.5, "PM": 6.0}


func x65_on() -> bool:
	return float(game_opts.get("x65", 1.0)) > 0.0


func x65_init() -> void:
	x65 = {"v": 1, "ls": 100.0, "ls_pk": 100.0, "unrest0": reg_avg("unrest"), "fear0": -1.0, "cut": 0.0, "cut_log": 0,
		"aid": 0.0, "aid_m": 0.0, "mood": 0.0, "wf": 0.0}


func x65_ensure() -> void:
	if x65.is_empty():
		x65_init()


func infl_tgt() -> float:
	if not x65_on() or fin_euro_member():
		return I_TGT
	return float(X65_INFL.get(ccode, I_TGT))


func infl_anchor() -> float:
	if not x65_on() or fin_euro_member():
		return I_TGT
	return float(X65_ANCH.get(ccode, I_TGT))


# ---------- усталость от войны ----------
# 0 — нет войны или она только началась, 1 — предел. Идёт от счётчика w["weary"] (растёт примерно на 12 в год): первые ≈20 единиц
# («усталость четвёртого года» на старте) не в счёт, дальше насыщение: через 5 лет ≈ 0,4, через 10 ≈ 0,65, через 25 ≈ 0,9
func war65_wf() -> float:
	if not x65_on() or not mil_on() or not mil_at_war():
		return 0.0
	var w: Dictionary = mil["war"]
	return clampf(1.0 - exp(-maxf(0.0, float(w["weary"]) - 20.0) / 120.0), 0.0, 1.0)


# призыв и мобилизация в демократии-жертве: чем дольше война, тем меньше желающих («на Украине не хотят»)
func war65_draft_k() -> float:
	if not x65_on() or not mil_at_war() or bool((mil["war"] as Dictionary).get("aggr", false)):
		return 1.0
	return 1.0 - 0.35 * war65_wf() * war_demo(ccode)


# после ухода авторитарного лидера преемник гибче в вопросе мира: «жёсткая» позиция становится «умеренной», а через год
# и при заметной усталости — «мягкой» (согласен на мир по текущей линии фронта)
func war65_stance(st: String) -> String:
	if not x65_on() or not bool(mil.get("ldr_gone", false)):
		return st
	var out := st
	if out == "hard":
		out = "mild"
	var since: int = turn - int(mil.get("ldr_t", turn))
	if out == "mild" and since >= 12 and war65_wf() >= 0.25:
		out = "soft"
	return out


# ---------- внешняя помощь жертве ----------
# грант в бюджет в долях ВВП за месяц: зависит от осуждения нападавшего, числа стран-доноров (тех, что ввели санкции) и
# демократичности жертвы; донорская усталость срезает помощь на 4% в год после четвёртого года войны (не ниже половины)
func war65_aid_money(w: Dictionary, it: Dictionary) -> float:
	if not x65_on():
		return gdp * 0.002 * float(it["cond"]) / 100.0 * wdt
	var donors: float = clampf(float((it.get("sanc", []) as Array).size()) / 20.0, 0.3, 1.0)
	var yrs: float = maxf(0.0, float(w["days"]) / 365.0 - 4.0)
	var fatigue: float = clampf(1.0 - 0.04 * yrs, 0.5, 1.0)
	var dem_k: float = clampf(0.35 + war_demo(ccode), 0.4, 1.0)
	var money: float = gdp * 0.008 * float(it["cond"]) / 100.0 * donors * fatigue * dem_k * wdt
	x65_ensure()
	x65["aid"] = float(x65["aid"]) + money
	x65["aid_m"] = money / maxf(wdt, 0.01)
	return money


# ---------- потолок падения демократии при военном положении ----------
# пока страна-жертва живёт под военным положением, индекс демократии не падает больше чем на 0,15 от исходного
# (внешний мир это понимает: Украина 2022–2025 остаётся «частично свободной», а не авторитарной)
func war65_dem_floor(d: float) -> float:
	if not x65_on() or not martial or mil.is_empty() or not mil_at_war() or bool((mil["war"] as Dictionary).get("aggr", false)):
		return d
	var base: float = minf(DEM_BASE, float(MIL_DEMO.get(ccode, DEM_BASE)))
	return maxf(d, maxf(0.30, base - 0.15))


# ---------- позиционная война: потери на линии соприкосновения ----------
# Раз в три дня соединения, стоящие вплотную к противнику, теряют бойцов от обстрелов и дронов, даже когда никто не наступает
# (за год ≈15% силы соединения; пополнение идёт отдельно). Потери копятся в счёте войны и в усталости.
func war65_attrition() -> void:
	if not x65_on() or not mil_at_war():
		return
	var w: Dictionary = mil["war"]
	if int(w.get("cf", 0)) > 0:
		return
	mil_un_build()
	var no: PackedInt32Array = ATE["no"]
	var nb: PackedInt32Array = ATE["nb"]
	var pw := [mil_side_power(0), mil_side_power(1)]
	var lost := [0.0, 0.0]
	for f in mil["units"]:
		if int(f["fight"]) >= 0 or int(f["a"]) < 0 or not (f["sea"] as Dictionary).is_empty():
			continue
		var sd := mil_side(String(f["cc"]))
		if sd < 0:
			continue
		var a: int = int(f["a"])
		var ebit: int = 1 << (1 - sd)
		var contact := (mil_un[a] & ebit) != 0
		if not contact:
			for j in range(no[a], no[a + 1]):
				if (mil_un[nb[j]] & ebit) != 0:
					contact = true
					break
		if not contact:
			continue
		var r: float = clampf(maxf(0.01, float(pw[1 - sd])) / maxf(0.01, float(pw[sd])), 0.6, 1.6)
		var loss: float = float(f["str"]) * 0.0004 * 3.0 * sqrt(r)
		f["str"] = maxf(0.0, float(f["str"]) - loss)
		f["org"] = maxf(0.0, float(f["org"]) - 0.004)
		lost[sd] += loss
	(w["kia"] as Array)[0] = float(w["kia"][0]) + float(lost[0])
	(w["kia"] as Array)[1] = float(w["kia"][1]) + float(lost[1])
	w["weary"] = float(w["weary"]) + float(lost[0]) * 0.01
	mil_cleanup()


# ---------- ИИ ведёт войну за страну наблюдателя или правительства при оппозиции ----------
# Раз в квартал: если армия слабее противника — мобилизация и новые соединения; если сильно сильнее и мобилизация давно идёт — отбой.
# (Игрок сам этого не ждёт: на него это не действует.)
func war65_ai_manage() -> void:
	if not (observer or opp_mode) or not mil_on() or not mil_at_war() or turn % 3 != 0:
		return
	if not current_event.is_empty() or int(x65.get("ai_cd", 0)) > turn:
		return
	var pw0: float = mil_side_power(0)
	var pw1: float = maxf(1.0, mil_side_power(1))
	var r: float = pw0 / pw1
	var sc: float = float((mil["war"] as Dictionary)["score"])
	var m: int = int(mil["mob"])
	# частичная мобилизация — при заметном отставании; всеобщая — только при явном разгроме
	if m == 0 and r < 0.8 and sc < 0.0:
		if mil_mobilize(1):
			x65["ai_cd"] = turn + 9
			x65["mob_t"] = turn
			return
	if m == 1 and r < 0.55 and sc < -40.0:
		if mil_mobilize(2):
			x65["ai_cd"] = turn + 12
			x65["mob_t"] = turn
			return
	if r < 0.95 and mil_recruit():
		x65["ai_cd"] = turn + 3
		return
	if r > 1.5 and m > 0 and turn - int(x65.get("mob_t", -99)) >= 12:
		if mil_mobilize(m - 1):
			x65["ai_cd"] = turn + 9
			x65["mob_t"] = turn


# ---------- ежемесячный шаг ----------
func x65_month() -> void:
	if not x65_on() or ec.is_empty():
		return
	x65_ensure()
	x65_ls_step()
	x65_fear_step()
	x65_war_step()
	if wmonth:
		x65["mood"] = x65_mood_calc()


# индекс уровня жизни (реальные доходы): растёт вместе с ростом сверх «нейтрального», падает от инфляции выше 4%, санкций и потерь рабочих рук
func x65_ls_step() -> void:
	var d: float = growth - G_NEU - 0.6 * maxf(0.0, inflation - 4.0)
	if mil_on() and mil_at_war():
		var w: Dictionary = mil["war"]
		var it: Dictionary = war_intl(w)
		if war_aggressor() == ccode:
			d -= 0.5 * float(it.get("share", 0.0)) * (1.0 if bool(w.get("sanct", false)) else 0.0)
			d -= 0.35 + 0.5 * war65_wf()      # удары по НПЗ и логистике, дорогая война, рост цен на импорт
		d -= mil_mob_k() / maxf(100.0, total_pop() * 1000.0 * 0.5) * 100.0 * 0.3
	x65["ls"] = float(x65["ls"]) * (1.0 + d / 1200.0 * wdt)
	x65["ls_pk"] = maxf(float(x65["ls_pk"]), float(x65["ls"]))


# страх протестов у авторитарного агрессора слабеет по мере падения уровня жизни (Россия 2026+: «страшно выходить» → «терять нечего»)
func x65_fear_step() -> void:
	if not au_on() or not mil_on() or not mil_at_war() or war_aggressor() != ccode:
		return
	var bs: Dictionary = au.get("base", {})
	if bs.is_empty():
		return
	if float(x65["fear0"]) < 0.0:
		x65["fear0"] = float(bs.get("fear", 0.0))
	var drop: float = 1.0 - float(x65["ls"]) / maxf(1.0, float(x65["ls_pk"]))
	var tgt: float = 25.0 * clampf(drop / 0.12, 0.0, 1.0)
	var cut: float = float(x65["cut"])
	var step: float = (tgt - cut) * rt(0.03, wdt)
	if absf(step) < 0.0005:
		return
	x65["cut"] = cut + step
	au["fear"] = clampf(float(au["fear"]) - step, 0.0, 100.0)
	bs["fear"] = maxf(12.0, float(bs.get("fear", 0.0)) - step)
	var cl: int = int(float(x65["cut"]) / 8.0)
	if wmonth and cl > int(x65["cut_log"]):
		x65["cut_log"] = cl
		log_tag("ОБЩЕСТВО", COL_WARN, "%s Люди всё реже боятся выходить на улицы: годы войны отняли у семей %.0f%% реальных доходов, и «терять нечего» звучит всё чаще. Страх перед властью слабеет." % [date_text(), drop * 100.0])


# усталость от войны давит на общество: молодёжь, рабочие и пенсионеры хуже терпят затянувшуюся войну. В авторитарной стране страх гасит
# недовольство, в демократии (Украина) оно выходит наружу как нежелание воевать дальше
func x65_war_step() -> void:
	if not mil_on() or not mil_at_war():
		x65["wf"] = 0.0
		x65["aid_m"] = 0.0
		return
	var wf: float = war65_wf()
	x65["wf"] = wf
	x65_lead_step()
	if wmonth:
		war65_ai_manage()
	if wf <= 0.01:
		return
	var fear_k: float = clampf(float(au.get("fear", 0.0)) / 80.0, 0.0, 1.0) if au_auth() else 0.0
	var k: float = wf * (1.0 - 0.7 * fear_k)
	add_support("Молодёжь", -0.5 * k * wdt)
	add_support("Рабочие", -0.2 * k * wdt)
	add_support("Пенсионеры", -0.15 * k * wdt)


# уход правителя страны-противника (когда это не наша страна): возрастной риск, как у своего правителя (regime2.gd);
# преемник в любом случае гибче в вопросе мира (war65_stance), а война получает шанс закончиться
const X65_LEADER_AGE := {"RU": 74.0, "BY": 72.0}


func x65_lead_step() -> void:
	if not wmonth:
		return
	var lead := String(mil["war"]["lead"])
	if lead == ccode or not X65_LEADER_AGE.has(lead) or bool(mil.get("ldr_gone", false)) or not current_event.is_empty():
		return
	var age: float = float(X65_LEADER_AGE[lead]) + float(turn) / 12.0
	if age > 68.0 and randf() < (age - 68.0) * 0.0004:
		mil["ldr_gone"] = true
		mil["ldr_t"] = turn
		log_tag("ВОЙНА", COL_WARN, "%s В «%s» умер правитель. Новое руководство обещает продолжить курс, но торопиться с победой ему незачем: в переговорах оно гибче." % [date_text(), String(WORLD[lead]["name"])])


# ---------- зависимость экономики от нефти и поправки к росту ----------
# Белоруссия: нефтепереработка на российской нефти и пошлины — цена нефти и отношения с Россией двигают рост (при цене 0,55 от нормы ≈ −0,9 п.п.)
func x65_g() -> float:
	if not x65_on():
		return 0.0
	if ccode != "BY":
		# внешняя помощь жертве войны поддерживает спрос и бюджет: ≈ +0,15 п.п. роста на каждый процент ВВП помощи в год
		if x65.is_empty() or not mil_on() or not mil_at_war():
			return 0.0
		return 0.15 * float(x65.get("aid_m", 0.0)) * 12.0 / maxf(1.0, gdp) * 100.0
	var rr: float = 70.0
	if dip.has("RU"):
		rr = float((dip["RU"] as Dictionary).get("rel", 70.0))
	return (res_price - 1.0) * 2.0 * clampf(rr / 80.0, 0.3, 1.2)


# ---------- недовольство регионов → одобрение ----------
# отклонение среднего недовольства (по населению) от стартового: хуже — минус ко всем группам, лучше — небольшой плюс
func x65_mood_calc() -> float:
	var d: float = reg_avg("unrest") - float(x65["unrest0"])
	return -clampf(d * 0.12, -2.0, 8.0)


func x65_mood() -> float:
	if not x65_on() or x65.is_empty():
		return 0.0
	return float(x65.get("mood", 0.0))
