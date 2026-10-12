# Внешнеполитический ИИ стран (v47_1). Состояние — словарь fa.
# У каждой страны: характер (FA_PERS: ястреб, торговец, ценности демократии, евро-солидарность, нейтралитет),
# долгая память о ваших поступках (mem, забывается за ~4 года), постоянные факторы (пошлины, соглашения, договоры,
# общий блок, разрыв в демократии, идейная близость правительств), санкции и собственные инициативы.
# Реакции на ваши действия приходят через fa_notify(kind, страна, сила) из модулей торговли, разведки, договоров, войны и т.д.
# Работает при включённом модуле «Государство и мир» (rlev > 0).
extends "res://scripts/logic/diplo2.gd"

const FA_PERS := {
	"DE": [0.3, 0.9, 0.8, 0.9, 0], "FR": [0.6, 0.6, 0.8, 0.9, 0], "NL": [0.4, 0.95, 0.8, 0.7, 0], "BE": [0.3, 0.8, 0.8, 0.9, 0],
	"LU": [0.1, 0.95, 0.8, 0.95, 0], "AT": [0.1, 0.7, 0.6, 0.7, 1], "CH": [0.1, 0.9, 0.7, 0.2, 1], "CZ": [0.5, 0.7, 0.6, 0.5, 0],
	"DK": [0.5, 0.8, 0.9, 0.6, 0], "ES": [0.3, 0.6, 0.7, 0.8, 0], "IT": [0.3, 0.6, 0.6, 0.7, 0], "NO": [0.5, 0.7, 0.9, 0.3, 0],
	"PL": [0.9, 0.6, 0.6, 0.6, 0], "PT": [0.2, 0.6, 0.7, 0.8, 0], "SE": [0.5, 0.8, 0.9, 0.6, 0], "GB": [0.8, 0.7, 0.8, 0.2, 0],
	"IE": [0.1, 0.9, 0.8, 0.7, 1], "SI": [0.2, 0.7, 0.6, 0.7, 0], "SK": [0.4, 0.7, 0.5, 0.6, 0], "HU": [0.3, 0.6, 0.1, 0.2, 0],
	"FI": [0.8, 0.7, 0.8, 0.7, 0], "HR": [0.4, 0.6, 0.5, 0.6, 0], "RS": [0.5, 0.5, 0.2, 0.2, 1], "BA": [0.2, 0.5, 0.4, 0.4, 0],
	"ME": [0.2, 0.5, 0.5, 0.6, 0], "MK": [0.2, 0.5, 0.5, 0.6, 0], "AL": [0.3, 0.5, 0.5, 0.7, 0], "XK": [0.3, 0.4, 0.6, 0.7, 0],
	"BG": [0.3, 0.6, 0.4, 0.5, 0], "RO": [0.6, 0.6, 0.6, 0.7, 0], "GR": [0.7, 0.6, 0.6, 0.7, 0], "EE": [0.9, 0.8, 0.8, 0.8, 0],
	"LV": [0.9, 0.7, 0.7, 0.8, 0], "LT": [0.9, 0.7, 0.8, 0.8, 0],
	"MD": [0.2, 0.6, 0.6, 0.8, 1], "BY": [0.6, 0.4, 0.1, 0.0, 0], "UA": [0.8, 0.5, 0.6, 0.8, 0], "RU": [0.95, 0.4, 0.05, 0.0, 0]}
const FA_MEM_DECAY := 0.985        # в месяц: обида или благодарность забываются примерно за 4 года
const FA_SANC_AT := -26.0           # порог, при котором страна вводит санкции
const FA_SANC_LIFT := -10.0

var fa: Dictionary = {}


func fa_on() -> bool:
	return not fa.is_empty() and rl_on()


func fa_init() -> void:
	fa = {"mem": {}, "sanc": {}, "why": {}, "cd": {}, "dem": democracy_index(), "stance": {}, "last_hit": {}, "eu_sanc": false, "log": []}
	for c in wsim:
		(fa["stance"] as Dictionary)[c] = float(wsim[c].get("stance", 0.0))
	fa_ws_init()


func fa_pers(c: String) -> Dictionary:
	var a: Array = FA_PERS.get(c, [0.4, 0.6, 0.5, 0.4, 0])
	return {"hawk": float(a[0]), "trade": float(a[1]), "values": float(a[2]), "eu": float(a[3]), "neutral": int(a[4]) == 1}


func fa_bots() -> Array:
	var out: Array = []
	for c in wsim:
		if c != ccode and not w_minor(String(c)):
			out.append(String(c))
	return out


func fa_is_eu(c: String) -> bool:
	return bool(WORLD.get(c, {}).get("eu", false))


func fa_me_eu() -> bool:
	return bool(rl["b"]["eu"]) if rl_on() else bool(MACRO.get("eu", false))


func fa_log(text: String, col: String = "") -> void:
	var lg: Array = fa["log"]
	lg.append("%s: %s" % [date_text(), text])
	while lg.size() > 40:
		lg.pop_front()
	log_tag("ДИПЛОМАТИЯ", col if col != "" else COL_DIM, text)


# изменение памяти страны о вас; why — короткое объяснение для подсказки
func fa_hit(c: String, v: float, why: String) -> void:
	if not fa_on() or c == ccode or not wsim.has(c) or absf(v) < 0.05:
		return
	var mem: Dictionary = fa["mem"]
	mem[c] = clampf(float(mem.get(c, 0.0)) + v, -70.0, 45.0)
	if dip.has(c):
		dip_change(c, v * 0.6)
	var w: Dictionary = fa["why"]
	var lst: Array = w.get(c, [])
	lst.append([why, v, turn])
	while lst.size() > 6:
		lst.pop_front()
	w[c] = lst
	if v < 0.0:
		(fa["last_hit"] as Dictionary)[c] = turn


# ============================================================
#  РЕАКЦИИ НА ДЕЙСТВИЯ ИГРОКА
# ============================================================
func fa_notify(kind: String, c: String, mag: float) -> void:
	if not fa_on():
		return
	var me_eu: bool = fa_me_eu()
	var me_nato: bool = mil_is_nato(ccode)
	for b in fa_bots():
		var p := fa_pers(b)
		var same_eu: bool = me_eu and fa_is_eu(b)
		var tgt: bool = b == c
		var v := 0.0
		var why := ""
		match kind:
			"tariff":
				if tgt:
					v = -7.0 * mag if mag > 0.0 else 3.0
					why = "пошлины против нас" if mag > 0.0 else "снятие пошлин"
				elif same_eu and fa_is_eu(c) and mag > 0.0:
					v = -1.5 * p["eu"]
					why = "пошлины внутри единого рынка"
			"deal":
				if tgt:
					v = 4.0 * mag
					why = "торговое соглашение" if mag > 0.0 else "сворачивание соглашения"
			"aid":
				if tgt:
					v = 6.0
					why = "помощь в трудный момент"
				else:
					v = 0.4 * p["values"]
					why = "щедрость к соседям"
			"spy":
				if tgt:
					v = -12.0 * mag
					why = "раскрытая шпионская операция"
				elif (fa_is_eu(c) and fa_is_eu(b)) or (mil_is_nato(c) and mil_is_nato(b)):
					v = -3.0 * mag * maxf(p["eu"], p["hawk"])
					why = "шпионаж против союзника"
				else:
					v = -0.8 * mag
					why = "репутация шпиона"
			"treaty":
				if tgt:
					v = 3.0
					why = "новый договор"
			"treaty_break":
				if tgt:
					v = -8.0
					why = "разрыв договора"
				else:
					v = -0.6
					why = "ненадёжный партнёр"
			"leave_nato":
				if mil_is_nato(b):
					v = -5.0 - 6.0 * p["hawk"]
					why = "выход из НАТО"
				elif p["neutral"]:
					v = 2.0
					why = "выбор нейтралитета"
			"join":
				if (c == "eu" and fa_is_eu(b)) or (c == "nato" and mil_is_nato(b)):
					v = 3.0
					why = "вступление в наш союз"
			"authoritarian":
				var dem_b: float = float(MIL_DEMO.get(b, 0.8))
				v = -28.0 * mag * p["values"] * clampf(dem_b, 0.2, 1.0)
				why = "отказ от демократии"
			"repression":
				fa_ws()["rep"] = turn
				v = -2.5 * p["values"] * mag
				why = "силовой разгон протестов"
			"war":
				if tgt:
					v = -30.0
					why = "нападение на нас"
				elif (fa_is_eu(c) and fa_is_eu(b)) or (mil_is_nato(c) and mil_is_nato(b)):
					v = -10.0 - 6.0 * maxf(p["hawk"], p["eu"])
					why = "нападение на союзника"
				elif p["neutral"]:
					v = -4.0
					why = "война в Европе"
				else:
					v = -5.0 * p["values"] - 2.0
					why = "агрессия"
			"peace":
				v = 5.0 if tgt else 2.5
				why = "заключение мира"
			"humane":
				v = 1.0 * p["values"]
				why = "гуманитарная помощь"
		if absf(v) > 0.05:
			fa_hit(b, v, why)
	# v53_1: и в хорошем тоже — помощь, соглашения и договоры с членом ЕС ценят его ближайшие союзники
	if c != "" and wsim.has(c) and fa_is_eu(c) and kind in ["aid", "deal", "treaty"] and mag > 0.0:
		for b3 in fa_bots():
			if b3 != c and fa_is_eu(b3) and fa_pers(b3)["eu"] >= 0.7:
				fa_hit(b3, 0.5 * mag, "дружба с «%s»" % dx_name(c))
	# солидарность: сильный удар по члену ЕС чувствуют все евроинтеграторы
	if c != "" and wsim.has(c) and fa_is_eu(c) and kind in ["spy", "tariff", "treaty_break"] and mag > 0.0:
		for b2 in fa_bots():
			if b2 != c and fa_is_eu(b2) and fa_pers(b2)["eu"] >= 0.7 and kind != "spy":
				fa_hit(b2, -1.0 * mag, "солидарность с «%s»" % dx_name(c))


# ============================================================
#  ЕЖЕМЕСЯЧНЫЙ ШАГ
# ============================================================
func fa_standing(c: String) -> float:
	# постоянные факторы: пошлины, соглашения, договоры, общий блок, разрыв в демократии, идейная близость, санкции
	var s := 0.0
	var p := fa_pers(c)
	if ex.has("p") and (ex["p"] as Dictionary).has(c):
		var ep: Dictionary = ex["p"][c]
		s += -4.0 * float(ep["tar"]) + 2.5 * float(ep["deal"]) - 1.0 * float(ep["ret"])
	if dx_on():
		var tr: Dictionary = (dx["tr"] as Dictionary).get(c, {})
		s += 1.5 * float(tr.size()) + (2.0 if tr.has("defense") else 0.0)
		for pj in dx["proj"]:
			if String(pj["cc"]) == c:
				s += 1.0
	if fa_me_eu() and fa_is_eu(c):
		s += 2.0 + 2.0 * p["eu"]
	if mil_is_nato(ccode) and mil_is_nato(c):
		s += 1.5 + 1.5 * p["hawk"]
	var gap: float = float(MIL_DEMO.get(c, 0.8)) - democracy_index()
	if gap > 0.15:
		s -= (gap - 0.15) * 40.0 * p["values"]
	var st: float = float(wsim[c].get("stance", 0.0))
	s += (0.5 - absf(st - w_player_stance())) * 5.0
	# идёт война: противник враждебен, его союзники по блоку тоже
	if mil_on() and mil_at_war():
		var foes: Array = mil_side_ccs(1)
		if c in foes:
			s -= 30.0
		elif foes.size() > 0 and String(foes[0]) != "" and ((fa_is_eu(c) and fa_is_eu(String(foes[0]))) or (mil_is_nato(c) and mil_is_nato(String(foes[0])))) and bool(mil["war"].get("we_attack", true)):
			s -= 8.0 * maxf(p["eu"], p["hawk"])
	return s


func fa_sanc_score(c: String) -> float:
	# союзнические «плюсы» смягчают, но не перекрывают обиду
	var st: float = fa_standing(c)
	return float((fa["mem"] as Dictionary).get(c, 0.0)) + minf(st, 0.0) + 0.3 * maxf(st, 0.0)


func fa_rel_term(c: String) -> float:
	if not fa_on() or not wsim.has(c):
		return 0.0
	return clampf(float((fa["mem"] as Dictionary).get(c, 0.0)) + fa_standing(c), -60.0, 35.0)


func fa_month() -> void:
	if not rl_on():
		return
	if fa.is_empty():
		fa_init()
	var cd: Dictionary = fa["cd"]
	for k in cd.keys():
		cd[k] = int(cd[k]) - 1
		if int(cd[k]) <= 0:
			cd.erase(k)
	var mem: Dictionary = fa["mem"]
	for c in mem.keys():
		mem[c] = float(mem[c]) * FA_MEM_DECAY
	# отказ от демократии замечают сразу (переворот, указы, хунта)
	var dem: float = democracy_index()
	if float(fa["dem"]) - dem >= 0.08:
		fa_notify("authoritarian", "", clampf((float(fa["dem"]) - dem) / 0.3, 0.3, 1.5))
		fa_log("демократии осуждают отказ от демократических институтов: отношения резко ухудшились.", COL_BAD)
	elif dem - float(fa["dem"]) >= 0.08:
		for b in fa_bots():
			fa_hit(b, 6.0 * fa_pers(b)["values"], "возвращение к демократии")
	fa["dem"] = dem
	fa_ws_month()
	# смена правительств у соседей: тёплее или холоднее к вам
	var stc: Dictionary = fa["stance"]
	for c2 in fa_bots():
		var now: float = float(wsim[c2].get("stance", 0.0))
		var was: float = float(stc.get(c2, now))
		if absf(now - was) > 0.25 and (dip.has(c2) or c2 in tech_nb()):
			var closer: bool = absf(now - w_player_stance()) < absf(was - w_player_stance())
			fa_log("новое правительство «%s» %s к вашему курсу." % [dx_name(c2), "ближе" if closer else "дальше"], COL_GOOD if closer else COL_WARN)
		stc[c2] = now
	fa_sanctions_step()
	fa_initiatives()


func fa_sanctions_step() -> void:
	var sanc: Dictionary = fa["sanc"]
	var g_pen := 0.0
	var n_eu := 0
	var n_eu_s := 0
	for c in fa_bots():
		var p := fa_pers(c)
		var score: float = fa_sanc_score(c)
		var on: bool = sanc.has(c)
		# v53_1: под мировыми санкциями (уровень 2–3) Запад держит их единым фронтом
		if fa_ws_forced(c):
			if not on:
				sanc[c] = turn
			if fa_is_eu(c):
				n_eu += 1
				n_eu_s += 1
			continue
		# нейтральные страны осторожнее, но при серьёзной обиде тоже присоединяются к санкциям
		var bar: float = FA_SANC_AT - (10.0 if p["neutral"] else 0.0)
		# «ценности» нужны для санкций за чужие грехи (авторитаризм, разница режимов); за личную обиду санкции вводит любой
		var personal: bool = float((fa["mem"] as Dictionary).get(c, 0.0)) < bar
		if not on and score < bar and (p["values"] >= 0.4 or personal or score < bar - 15.0):
			sanc[c] = turn
			if ex.has("p") and (ex["p"] as Dictionary).has(c):
				ex["p"][c]["ret"] = mini(3, int(ex["p"][c]["ret"]) + 1)
			fa_log("«%s» вводит санкции против вас: ограничения торговли и инвестиций." % dx_name(c), COL_BAD)
		elif on and score > FA_SANC_LIFT and turn - int(sanc[c]) >= 6:
			sanc.erase(c)
			if ex.has("p") and (ex["p"] as Dictionary).has(c):
				ex["p"][c]["ret"] = maxi(0, int(ex["p"][c]["ret"]) - 1)
			fa_log("«%s» снимает санкции." % dx_name(c), COL_GOOD)
		if sanc.has(c):
			g_pen += clampf(w_share(ccode, c) * 9.0, 0.02, 0.35)
		if fa_is_eu(c):
			n_eu += 1
			if sanc.has(c):
				n_eu_s += 1
	# общие санкции ЕС, если против вас треть его членов
	var eu_now: bool = n_eu > 0 and float(n_eu_s) / float(n_eu) >= 0.34
	var ws_eu: bool = fa_ws_lvl() >= 2
	if ws_eu:
		eu_now = true
	if eu_now and not bool(fa["eu_sanc"]) and not ws_eu:
		fa_log("[b]Евросоюз ввёл общие санкции против вас.[/b] Фонды ЕС заморожены, инвесторы уходят.", COL_BAD)
		add_all_support(-2.0)
	elif not eu_now and bool(fa["eu_sanc"]):
		fa_log("Евросоюз снял общие санкции.", COL_GOOD)
	fa["eu_sanc"] = eu_now
	if eu_now and not ws_eu:
		g_pen += 0.35
	rl["g"] = float(rl["g"]) - minf(g_pen, 2.0) + fa_ws_g()


func fa_initiatives() -> void:
	if not current_event.is_empty() or election_open or game_over or observer:
		return
	# темп: обычно 5% в месяц, но чем дольше страны молчали, тем вероятнее инициатива (не бывает долгих «пустых» лет)
	var quiet: int = turn - int(fa.get("last_ini", 0))
	if randf() > clampf(0.05 + 0.006 * float(quiet - 12), 0.05, 0.25):
		return
	var bots: Array = fa_bots()
	bots.shuffle()
	var weak: bool = (mil_on() and mil_spend_ratio() < 0.9) or (rv_on() and (rv["conf"] as Array).size() > 0)
	var crisis: bool = debt / gdp > 1.1 or (rv_on() and (rv["conf"] as Array).size() > 0) or growth < -1.0
	for c in bots:
		var p := fa_pers(c)
		var rel: float = fed_rel(c)
		var mem: float = float((fa["mem"] as Dictionary).get(c, 0.0))
		var nm: String = dx_name(c)
		# помощь друга в беде
		if crisis and rel >= 60.0 and (p["trade"] >= 0.6 or p["eu"] >= 0.6) and fa_cd("aid" + c):
			(fa["cd"] as Dictionary)["aid" + c] = 36
			fa["last_ini"] = turn
			rl_event("fa_aid", "«%s» предлагает помощь в трудный момент: льготный кредит и экспертов. Условия — прозрачность и реформы." % nm, [
				{"l": "Принять помощь", "fx": {"debt": -0.5, "support": {"Силовики": -1.0}}, "act": "fa_aid_yes", "arg": c},
				{"l": "Поблагодарить и отказаться", "fx": {}, "act": "fa_aid_no", "arg": c}])
			return
		# давление ястреба-соседа на слабого
		if weak and rel < 32.0 and p["hawk"] >= 0.5 and c in tech_nb() and fa_cd("press" + c):
			(fa["cd"] as Dictionary)["press" + c] = 30
			fa["last_ini"] = turn
			rl_event("fa_press", "«%s» стягивает войска к границе и требует уступок по спорным вопросам, пользуясь вашей слабостью." % nm, [
				{"l": "Мобилизовать резервы (армия +0,2% ВВП)", "fx": {"slider": {"army": 0.2}, "support": {"Силовики": 3.0}}, "act": "fa_press_arm", "arg": c},
				{"l": "Пойти на уступки (капитал −4)", "fx": {"capital": -4.0, "all": -1.0}, "act": "fa_press_give", "arg": c},
				{"l": "Обратиться к союзникам (капитал −3)", "fx": {"capital": -3.0}, "act": "fa_press_allies", "arg": c}])
			return
		# предложение сотрудничества от друга
		if rel >= 70.0 and dx_on() and not dx_has_treaty(c, "tech") and fa_cd("coop" + c):
			(fa["cd"] as Dictionary)["coop" + c] = 48
			fa["last_ini"] = turn
			rl_event("fa_coop", "«%s» предлагает договор о научном обмене и совместных проектах: «у наших стран общие интересы»." % nm, [
				{"l": "Подписать (капитал −2)", "fx": {"capital": -2.0}, "act": "fa_coop_yes", "arg": c},
				{"l": "Отклонить вежливо", "fx": {}, "act": "fa_coop_no", "arg": c}])
			return
		# предложение «перезагрузки» после старой обиды
		if mem < -22.0 and turn - int((fa["last_hit"] as Dictionary).get(c, 0)) > 18 and fa_cd("reset" + c):
			(fa["cd"] as Dictionary)["reset" + c] = 36
			fa["last_ini"] = turn
			rl_event("fa_reset", "Новое руководство «%s» предлагает перевернуть страницу: встреча лидеров и общее заявление о будущем отношений." % nm, [
				{"l": "Принять: встреча и уступки в спорных вопросах (капитал −3)", "fx": {"capital": -3.0}, "act": "fa_reset_yes", "arg": c},
				{"l": "Отказаться: обиды не забыты", "fx": {"support": {"Силовики": 1.0}}, "act": "fa_reset_no", "arg": c}])
			return


func fa_eu_sanc() -> bool:
	return fa_on() and bool(fa.get("eu_sanc", false))


func fa_sanctioning(c: String) -> bool:
	return fa_on() and (fa["sanc"] as Dictionary).has(c)


func fa_cd(k: String) -> bool:
	return not (fa["cd"] as Dictionary).has(k)


func fpai_resolve(opt: Dictionary) -> void:
	var act := String(opt.get("act", ""))
	var c := String(opt.get("arg", ""))
	match act:
		"fa_aid_yes":
			fa_hit(c, 4.0, "вы приняли нашу помощь")
			fa_log("принята помощь «%s»." % dx_name(c), COL_GOOD)
		"fa_aid_no":
			fa_hit(c, -1.0, "отказ от помощи")
		"fa_press_arm":
			fa_hit(c, -3.0, "мобилизация у границы")
			fa_log("мобилизация остудила «%s»: давление ослабло." % dx_name(c), COL_WARN)
		"fa_press_give":
			fa_hit(c, 6.0, "уступки")
		"fa_press_allies":
			var help: bool = mil_is_nato(ccode) or fa_me_eu()
			if help:
				fa_hit(c, -2.0, "призыв к союзникам")
				dip_all(1.0, false)
				fa_log("союзники выступили с заявлением: «%s» отводит войска." % dx_name(c), COL_GOOD)
			else:
				add_all_support(-1.0)
				fa_log("союзников не нашлось: давление продолжается.", COL_BAD)
		"fa_coop_yes":
			if dx_on():
				var tr: Dictionary = dx["tr"]
				if not tr.has(c):
					tr[c] = {}
				tr[c]["tech"] = true
			fa_hit(c, 3.0, "договор о науке")
		"fa_coop_no":
			fa_hit(c, -1.0, "отказ от сотрудничества")
		"fa_reset_yes":
			fa_hit(c, 14.0, "перезагрузка отношений")
			fa_log("отношения с «%s» перезагружены." % dx_name(c), COL_GOOD)
		"fa_reset_no":
			fa_hit(c, -3.0, "отказ мириться")
		"fa_civ_ok":
			pass


# ============================================================
#  v53_1: МИРОВЫЕ САНКЦИИ И ВОЗВРАЩЕНИЕ В МИРОВОЕ СООБЩЕСТВО
# ============================================================
# Режим санкций Запада (ЕС, Британия, Норвегия, Швейцария и союзники за пределами Европы) против страны игрока:
# 0 — нет, 1 — персональные (чиновники, силовики), 2 — секторальные (финансы, технологии, экспорт), 3 — полная блокада.
# Вводится за агрессивную войну или слом демократии; сам собой не исчезает с концом войны.
# Снимается по ступеням через переговоры, когда выполнены условия (fa_ws_conds).
const FA_WS_NAMES := ["нет", "персональные", "секторальные", "полная блокада"]
const FA_WS_PEN := [0.0, 0.25, 0.6, 1.2]      # п.п. роста в год
const FA_WS_WEST := ["GB", "NO", "CH", "IS"]
# стартовые режимы: [уровень, причины, аннексии без признания, нужна компенсация]
const FA_WS0 := {
	"RU": [3, ["war", "annex", "auth"], ["UA"], true],
	"BY": [2, ["complicity", "auth"], [], false]}
const FA_WS_WHY := {"war": "агрессивную войну", "annex": "аннексию чужих земель", "auth": "слом демократии и репрессии",
	"complicity": "соучастие в чужой агрессии", "coup": "государственный переворот"}


func fa_ws() -> Dictionary:
	if not fa.has("ws"):
		fa["ws"] = {"lvl": 0, "lvl0": 0, "why": [], "since": 0, "dem0": democracy_index(), "ever": false, "annex": [], "recog": false,
			"comp_need": false, "comp": false, "rep": -999, "evade": -1, "civ": false, "boom": -1, "vic": ""}
	return fa["ws"]


func fa_ws_init() -> void:
	var ws := fa_ws()
	if not FA_WS0.has(ccode):
		return
	var a: Array = FA_WS0[ccode]
	ws["lvl"] = int(a[0])
	ws["lvl0"] = int(a[0])
	ws["why"] = (a[1] as Array).duplicate()
	ws["annex"] = (a[2] as Array).duplicate()
	ws["comp_need"] = bool(a[3])
	ws["vic"] = String((a[2] as Array)[0]) if (a[2] as Array).size() > 0 else ""
	ws["ever"] = true
	ws["since"] = turn - 24
	# стартовая цена санкций уже в экономике страны; у воюющей её считает военный модуль до конца войны
	ws["base"] = 0.0 if fa_ws_war_sanct() else FA_WS_PEN[int(a[0])]
	fa["eu_sanc"] = int(a[0]) >= 2


func fa_ws_lvl() -> int:
	if not fa_on():
		return 0
	return int(fa_ws()["lvl"])


func fa_west(c: String) -> bool:
	return fa_is_eu(c) or c in FA_WS_WEST


# страна обязана держать санкции (единый фронт Запада при уровне 2–3)
func fa_ws_forced(c: String) -> bool:
	return fa_ws_lvl() >= 2 and fa_west(c)


func fa_ws_war_sanct() -> bool:
	return mil_on() and mil_at_war() and bool(mil["war"].get("sanct", false)) and war_aggressor() == ccode


# влияние на рост: относительно старта (стартовые санкции уже заложены в экономику страны);
# пока идёт война с санкциями, их цену считает военный модуль
func fa_ws_g() -> float:
	var ws := fa_ws()
	var g := 0.0
	if not fa_ws_war_sanct():
		var pen: float = FA_WS_PEN[clampi(int(ws["lvl"]), 0, 3)]
		if int(ws["evade"]) > turn:
			pen *= 0.6
		g -= pen - float(ws.get("base", 0.0))
	if int(ws["boom"]) > turn:
		g += 0.3
	return g


func fa_ws_set(lvl: int, why: String) -> void:
	var ws := fa_ws()
	var was: int = int(ws["lvl"])
	if not (why in ws["why"]):
		(ws["why"] as Array).append(why)
	if lvl <= was:
		return
	if was == 0:
		ws["dem0"] = democracy_index()
		ws["since"] = turn
	ws["lvl"] = lvl
	ws["ever"] = true
	ws["civ"] = false
	fa_log("[b]Мировые санкции: %s[/b] (за %s). Финансы, технологии и рынки Запада закрываются." % [FA_WS_NAMES[lvl], String(FA_WS_WHY.get(why, why))], COL_BAD)


func fa_ws_month() -> void:
	var ws := fa_ws()
	# агрессивная война под санкциями ЕС — полная блокада и долг перед жертвой
	if fa_ws_war_sanct():
		var vic: String = war_victim()
		if int(ws["lvl"]) < 3:
			fa_ws_set(3, "war")
		ws["vic"] = vic
		ws["comp_need"] = true
		ws["comp"] = false
	# слом демократии: хунта, переворот, однопартийность
	if au_auth() and float(ws["dem0"]) >= 0.45 and int(ws["lvl"]) < 1:
		fa_ws_set(1, "auth")
	# «возвращение в цивилизованный мир»
	if bool(ws["ever"]) and int(ws["lvl"]) == 0 and not bool(ws["civ"]) and democracy_index() >= 0.5 and fa_world() >= 45.0 and not observer:
		ws["civ"] = true
		ws["boom"] = turn + 36
		for b in fa_bots():
			fa_hit(b, 6.0 + 6.0 * fa_pers(b)["values"], "возвращение в мировое сообщество")
		capital = minf(100.0, capital + 5.0)
		add_all_support(1.0)
		var t := "Страна возвращается в мировое сообщество: санкции сняты, демократические институты работают. Инвесторы возвращаются (рост +0,3 п.п. три года), открыты двери в Совет Европы, ОЭСР и западные союзы."
		fa_log("[b]%s[/b]" % t, COL_GOOD)
		rl_event("fa_civ", t, [{"l": "Это наш общий успех", "fx": {"all": 1.0}, "act": "fa_civ_ok"}])


# конец войны: санкции остаются, но меняются условия их снятия
func fa_war_ended(kind: String, terms: Dictionary, annexed: bool, lead: String) -> void:
	if not fa_on():
		return
	var ws := fa_ws()
	if int(ws["lvl"]) == 0 and String(ws["vic"]) != lead:
		return
	var an: Array = ws["annex"]
	if annexed:
		if not (lead in an):
			an.append(lead)
		ws["recog"] = false
		if not ("annex" in ws["why"]):
			(ws["why"] as Array).append("annex")
	elif kind.begins_with("lose") or terms.has("return") or (kind == "white" and not (lead in (FA_WS0.get(ccode, [0, [], []]) as Array)[2])):
		# земли, присоединённые до начала игры, белый мир не возвращает — нужен пункт о признании
		an.erase(lead)
	if terms.has("recog"):
		ws["recog"] = true
	if kind.begins_with("lose") or terms.has("comp"):
		ws["comp"] = true
	if int(ws["lvl"]) > 0:
		fa_log("Война окончена, но санкции (%s) остаются, пока не выполнены условия Запада." % FA_WS_NAMES[int(ws["lvl"])], COL_WARN)


func fa_ws_annex_has(c: String) -> bool:
	return fa_on() and c in (fa_ws()["annex"] as Array)


func fa_ws_need_dem() -> float:
	return clampf(float(fa_ws()["dem0"]) + 0.2, 0.3, 0.5)


# условия снятия: [ключ, текст, выполнено, как выполнить]
func fa_ws_conds() -> Array:
	var ws := fa_ws()
	var war_ok: bool = not (mil_on() and mil_at_war() and war_aggressor() == ccode)
	var an: Array = ws["annex"]
	var bord_ok: bool = an.is_empty() or bool(ws["recog"])
	var need: float = fa_ws_need_dem()
	var dem_ok: bool = democracy_index() >= need
	var pris: int = int(au.get("pris", 0)) if au_on() else 0
	var rep_ok: bool = turn - int(ws["rep"]) >= 12 and pris < 100
	var comp_ok: bool = not bool(ws["comp_need"]) or bool(ws["comp"])
	var an_n: PackedStringArray = []
	for c in an:
		an_n.append(dx_name(String(c)))
	return [
		["war", "Нет агрессивной войны", war_ok, "заключить мир"],
		["border", "Границы урегулированы" + ("" if an.is_empty() else " (%s)" % ", ".join(an_n)), bord_ok, "мир на довоенных границах или пункт о признании границ в мирном договоре"],
		["dem", "Индекс демократии не ниже %.0f%% (сейчас %.0f%%)" % [need * 100.0, democracy_index() * 100.0], dem_ok, "законы о свободе СМИ, судах и выборах, демократизация"],
		["rep", "Нет репрессий год и политзаключённых меньше 100 (сейчас %d)" % pris, rep_ok, "амнистия политзаключённых, отказ от силовых разгонов"],
		["comp", "Компенсация ущерба пострадавшей стране", comp_ok, "фонд компенсаций или пункт о компенсации в мирном договоре"]]


func fa_ws_step_ok() -> Array:
	# можно ли снизить уровень на ступень: [да/нет, чего не хватает]
	var ws := fa_ws()
	var lvl: int = int(ws["lvl"])
	var ok := {}
	for c in fa_ws_conds():
		ok[String(c[0])] = bool(c[2])
	var miss: PackedStringArray = []
	var need: Array = []
	match lvl:
		3: need = ["war", "border|comp"]
		2: need = ["war", "border", "dem|rep+comp"]
		_: need = ["war", "border", "dem", "rep", "comp"]
	for n in need:
		var any := false
		for alt in String(n).split("|"):
			var all := true
			for k in String(alt).split("+"):
				if not bool(ok.get(k, true)):
					all = false
			if all:
				any = true
		if not any:
			var names: PackedStringArray = []
			for alt2 in String(n).split("|"):
				for k2 in String(alt2).split("+"):
					for c2 in fa_ws_conds():
						if String(c2[0]) == k2 and not bool(c2[2]):
							names.append(String(c2[1]).to_lower())
			miss.append(" или ".join(names))
	return [miss.is_empty(), "; ".join(miss)]


func fa_world() -> float:
	# отношение мира к стране: среднее по странам, взвешенное по размеру экономики
	var s := 0.0
	var wt := 0.0
	for c in fa_bots():
		var w: float = sqrt(maxf(1.0, float(wsim[c].get("gdp", 100.0))))
		s += fed_rel(c) * w
		wt += w
	return s / wt if wt > 0.0 else 50.0


func fa_world_name(v: float) -> String:
	if v < 25.0: return "изгой"
	if v < 40.0: return "в изоляции"
	if v < 55.0: return "сдержанное"
	if v < 70.0: return "уважаемый партнёр"
	return "признанный лидер"


func fa_ws_acts() -> Array:
	var out: Array = []
	if not fa_on():
		return out
	var ws := fa_ws()
	var lvl: int = int(ws["lvl"])
	var cd: Dictionary = fa["cd"]
	if lvl > 0:
		var st: Array = fa_ws_step_ok()
		out.append({"id": "ws_talks", "name": "Переговоры о снятии санкций", "cap": 5.0, "arg": "",
			"desc": "Запад рассмотрит смягчение на одну ступень (сейчас: %s). %s" % [FA_WS_NAMES[lvl], "Условия для этой ступени выполнены." if bool(st[0]) else "Не хватает: " + String(st[1]) + "."],
			"ok": capital >= 5.0 and fa_cd("ws_talks"), "why": ("перерыв %d мес." % int(cd["ws_talks"])) if not fa_cd("ws_talks") else ("нужно 5 капитала" if capital < 5.0 else "")})
		if bool(ws["comp_need"]) and not bool(ws["comp"]):
			out.append({"id": "ws_comp", "name": "Фонд компенсаций (долг +1,5% ВВП)", "cap": 3.0, "arg": "",
				"desc": "Выплаты пострадавшей стране за разрушения: условие снятия санкций. Силовики недовольны, пострадавшая страна и Европа оценят.",
				"ok": capital >= 3.0, "why": "" if capital >= 3.0 else "нужно 3 капитала"})
		out.append({"id": "ws_evade", "name": "Обход санкций через третьи страны", "cap": 3.0, "arg": "",
			"desc": "Серый импорт и посредники: на год потери от санкций меньше на 40%. Если схему раскроют (30%), отношения с Западом ухудшатся, а переговоры отложат на год.",
			"ok": capital >= 3.0 and fa_cd("ws_evade"), "why": ("перерыв %d мес." % int(cd["ws_evade"])) if not fa_cd("ws_evade") else ("" if capital >= 3.0 else "нужно 3 капитала")})
	out.append({"id": "ws_diplo", "name": "Дипломатическое наступление", "cap": 4.0, "arg": "",
		"desc": "Визиты, форумы, гуманитарные жесты: отношения со всеми странами чуть лучше. Под санкциями Запад верит слабо — сильнее отзываются нейтральные и далёкие от «ценностей».",
		"ok": capital >= 4.0 and fa_cd("ws_diplo"), "why": ("перерыв %d мес." % int(cd["ws_diplo"])) if not fa_cd("ws_diplo") else ("" if capital >= 4.0 else "нужно 4 капитала")})
	return out


func fa_ws_do(id: String) -> bool:
	if not fa_on() or observer or game_over or not current_event.is_empty():
		return false
	var ws := fa_ws()
	var cd: Dictionary = fa["cd"]
	match id:
		"ws_talks":
			if int(ws["lvl"]) <= 0 or capital < 5.0 or not fa_cd("ws_talks"):
				return false
			capital -= 5.0
			var st: Array = fa_ws_step_ok()
			if bool(st[0]):
				ws["lvl"] = int(ws["lvl"]) - 1
				cd["ws_talks"] = 12
				for b in fa_bots():
					if fa_west(b):
						fa_hit(b, 4.0, "договорённости о санкциях")
				if int(ws["lvl"]) < 2:
					for b2 in fa_bots():
						if fa_west(b2) and (fa["sanc"] as Dictionary).has(b2):
							fa_hit(b2, 6.0, "снятие общих санкций")
				fa_log("[b]Санкции смягчены: теперь «%s».[/b]%s" % [FA_WS_NAMES[int(ws["lvl"])], " Мировые санкции сняты полностью." if int(ws["lvl"]) == 0 else ""], COL_GOOD)
				add_support("Бизнес", 2.0)
				add_support("Молодёжь", 1.0)
			else:
				cd["ws_talks"] = 6
				fa_log("переговоры о санкциях без результата. Не хватает: %s." % String(st[1]), COL_WARN)
			return true
		"ws_comp":
			if capital < 3.0 or bool(ws["comp"]):
				return false
			capital -= 3.0
			debt += gdp * 0.015
			ws["comp"] = true
			add_support("Силовики", -3.0)
			var v: String = String(ws["vic"])
			if v != "":
				fa_hit(v, 15.0, "компенсация ущерба")
			for b in fa_bots():
				if fa_west(b) and b != v:
					fa_hit(b, 2.0, "компенсация ущерба соседу")
			fa_log("создан фонд компенсаций пострадавшей стране (%.1f млрд €)." % (gdp * 0.015), COL_GOOD)
			return true
		"ws_evade":
			if capital < 3.0 or not fa_cd("ws_evade"):
				return false
			capital -= 3.0
			cd["ws_evade"] = 24
			ws["evade"] = turn + 12
			if randf() < 0.3:
				cd["ws_talks"] = maxi(int(cd.get("ws_talks", 0)), 12)
				for b in fa_bots():
					if fa_west(b):
						fa_hit(b, -4.0, "обход санкций")
				fa_log("схему обхода санкций раскрыли: Запад ужесточает контроль, переговоры отложены на год.", COL_BAD)
			else:
				fa_log("налажен серый импорт через третьи страны: потери от санкций меньше.", COL_WARN)
			return true
		"ws_diplo":
			if capital < 4.0 or not fa_cd("ws_diplo"):
				return false
			capital -= 4.0
			cd["ws_diplo"] = 12
			var lvl: int = int(ws["lvl"])
			for b in fa_bots():
				var p := fa_pers(b)
				var v2: float = 3.0 if p["neutral"] else 2.5 - 1.5 * p["values"]
				if lvl >= 2 and fa_west(b):
					v2 *= 0.3
				fa_hit(b, maxf(0.3, v2), "дипломатическое наступление")
			fa_log("дипломатическое наступление: визиты и форумы улучшили отношения.", COL_GOOD)
			return true
	return false


func fa_ws_text() -> String:
	if not fa_on():
		return "Модуль «Государство и мир» выключен."
	var ws := fa_ws()
	var wv: float = fa_world()
	var t := "Отношение мира: [b]%.0f[/b] из 100 — %s\n" % [wv, fa_world_name(wv)]
	var n_s := 0
	for c in fa_bots():
		if (fa["sanc"] as Dictionary).has(c):
			n_s += 1
	var lvl: int = int(ws["lvl"])
	t += "Мировые санкции: [b][color=%s]%s[/color][/b]" % [COL_BAD if lvl >= 2 else (COL_WARN if lvl == 1 else COL_GOOD), FA_WS_NAMES[lvl]]
	if lvl > 0:
		var wn: PackedStringArray = []
		for w in ws["why"]:
			wn.append(String(FA_WS_WHY.get(String(w), String(w))))
		t += " — за %s" % ", ".join(wn)
	t += "\nСанкции отдельных стран: %d · потери роста от режима санкций: %.2f п.п. в год\n" % [n_s, FA_WS_PEN[lvl] * (0.6 if int(ws["evade"]) > turn else 1.0)]
	if lvl > 0:
		t += "[b]Условия снятия[/b] (ступень за ступенью через переговоры):\n"
		for c in fa_ws_conds():
			t += "[color=%s]%s %s[/color]%s\n" % [COL_GOOD if bool(c[2]) else COL_BAD, "✓" if bool(c[2]) else "✗", c[1], "" if bool(c[2]) else " — " + String(c[3])]
	elif bool(ws["civ"]):
		t += "[color=%s]Страна принята в мировое сообщество.[/color]\n" % COL_GOOD
	elif bool(ws["ever"]):
		t += "Для полного возвращения в мировое сообщество: индекс демократии не ниже 50%% и отношение мира не ниже 45.\n"
	return t


# ============================================================
#  ПОЯСНЕНИЕ ДЛЯ ИГРОКА
# ============================================================
func fa_explain(c: String) -> String:
	if not fa_on() or not wsim.has(c) or c == ccode:
		return ""
	var p := fa_pers(c)
	var traits: PackedStringArray = []
	if p["hawk"] >= 0.7:
		traits.append("ястреб в безопасности")
	if p["trade"] >= 0.85:
		traits.append("ценит торговлю")
	if p["values"] >= 0.75:
		traits.append("защищает демократию")
	if p["eu"] >= 0.8:
		traits.append("за единую Европу")
	if p["neutral"]:
		traits.append("нейтральная страна")
	var t := "[b]Как к вам относятся:[/b] память %+.0f, постоянные факторы %+.0f%s\n" % [float((fa["mem"] as Dictionary).get(c, 0.0)), fa_standing(c), (" · [color=%s]санкции против вас[/color]" % COL_BAD) if (fa["sanc"] as Dictionary).has(c) else ""]
	if traits.size() > 0:
		t += "Характер: %s\n" % ", ".join(traits)
	var lst: Array = (fa["why"] as Dictionary).get(c, [])
	if lst.size() > 0:
		var parts: PackedStringArray = []
		for it in lst.slice(maxi(0, lst.size() - 4)):
			parts.append("%s (%+.0f)" % [it[0], float(it[1])])
		t += "Помнят: %s\n" % "; ".join(parts)
	return t
