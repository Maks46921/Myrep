# Радикальные законы: форма правления, строй, выход из ЕС и т.д.
extends "res://scripts/logic/council.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func au_dyn() -> void:
	pass


func au_fat_months() -> int:
	return 0


func au_risk_add() -> float:
	return 0.0


func au_step() -> void:
	pass


func es_dyn() -> void:
	pass


func es_step() -> void:
	pass


func hist_dyn() -> void:
	pass


func io_dyn() -> void:
	pass


func io_step() -> void:
	pass


# --- конец заглушек ---


func arch_ps(tbl: Dictionary) -> Dictionary:
	var out := {}
	for p in PARTY_NAMES.size():
		var a: String = String(ARCHS[p]) if p < ARCHS.size() else "oth"
		var key := a
		if p == 9:
			key = "prot"
		elif a == "none":
			key = "oth"
		if tbl.has(key):
			out[p] = float(tbl[key])
	return out


func RV(n: String, d: String, c: float, s: Dictionary, a: Dictionary, pst: Dictionary, extra: Dictionary = {}) -> Dictionary:
	var v := {"n": n, "d": d, "c": c, "s": s, "a": a, "ps": arch_ps(pst)}
	for k in extra:
		v[k] = extra[k]
	return v


func rid_of(tid: String) -> String:
	if not law_index.has(tid):
		return ""
	var vs: Array = law_index[tid]["v"]
	var i := cur_idx(tid)
	if i < 0 or i >= vs.size():
		return ""
	return String((vs[i] as Dictionary).get("rid", ""))


func regime_id() -> String:
	return rid_of("gov_form")


func econ_id() -> String:
	return rid_of("econ_model")


func decree_power() -> bool:
	return regime_id() in RAD_AUTH or rid_of("state_church") == "theocracy"


func radical_bypass(tid: String, idx: int) -> bool:
	if decree_power():
		return true
	var vs: Array = law_index[tid]["v"]
	if idx < vs.size() and bool((vs[idx] as Dictionary).get("coup", false)):
		return radical_req(tid, idx) == ""
	return false


func radical_req(tid: String, idx: int) -> String:
	var vs: Array = law_index[tid]["v"]
	if idx >= vs.size():
		return ""
	var v: Dictionary = vs[idx]
	var rq: Dictionary = v.get("req", {})
	if rq.is_empty():
		return ""
	if rq.has("force") and float(support["Силовики"]) < float(rq["force"]):
		return "нужна поддержка силовиков не ниже %.0f (сейчас %.0f)." % [float(rq["force"]), float(support["Силовики"])]
	if rq.has("unrest") and reg_avg("unrest") < float(rq["unrest"]) and approval() > 40.0:
		return "нужен кризис: недовольство в регионах не ниже %.0f или рейтинг ниже 40%%." % float(rq["unrest"])
	if rq.get("noteu", false) and bool(MACRO.get("eu", true)):
		return "несовместимо с членством в ЕС: сначала выйдите из ЕС."
	if rq.get("nodefault", false) and turn - default_t < 120:
		return "дефолт уже объявляли: повторить можно не раньше чем через 10 лет."
	return ""


func law_locked(tid: String) -> String:
	if decree_power() and tid in RAD_AUTH_TOPICS and tid != "gov_form":
		return "заморожен режимом «%s»" % String(variant_of("gov_form", cur_idx("gov_form"))["n"]) if rid_of("gov_form") in RAD_AUTH else "заморожен религиозным режимом"
	for rt in ["gov_form", "econ_model", "civil_rights", "trade_policy", "state_church", "military_state"]:
		if rt == tid or not law_index.has(rt):
			continue
		var vs: Array = law_index[rt]["v"]
		var i := cur_idx(rt)
		if i < 0 or i >= vs.size():
			continue
		var fr: Array = (vs[i] as Dictionary).get("freeze", [])
		if tid in fr:
			return "заморожен режимом «%s»" % String((vs[i] as Dictionary)["n"])
	return ""


func auth_idx(tid: String) -> int:
	var vs: Array = law_index[tid]["v"]
	var best := cur_idx(tid)
	var bd := 0.0
	var cd0: float = float(((vs[best] as Dictionary).get("a", {}) as Dictionary).get("dem_shift", 0.0))
	bd = cd0
	for i in vs.size():
		var dsh: float = float(((vs[i] as Dictionary).get("a", {}) as Dictionary).get("dem_shift", 0.0))
		if dsh < bd - 0.0001:
			bd = dsh
			best = i
	return best


func radical_enact(tid: String, idx: int, old_rid: String) -> void:
	var v: Dictionary = variant_of(tid, idx)
	var new_rid: String = String(v.get("rid", ""))
	# выход из авторитарного режима: освобождаем законы
	if tid == "gov_form" and old_rid in RAD_AUTH and not (new_rid in RAD_AUTH):
		for t2 in RAD_AUTH_TOPICS:
			if law_index.has(t2) and cur_idx(t2) != 0:
				law_state[t2] = 0
		log_line("[color=%s]Демократизация: ограничительные законы отменены, политические права восстановлены.[/color]" % COL_GOOD)
	for t2 in v.get("reset", []):
		if law_index.has(t2) and cur_idx(t2) != 0:
			law_state[t2] = 0
	if new_rid in RAD_AUTH:
		for t2 in RAD_AUTH_TOPICS:
			if law_index.has(t2) and t2 != tid:
				law_state[t2] = auth_idx(t2)
	if v.has("fxnow"):
		var txt := apply_fx(v["fxnow"])
		if txt != "":
			log_line("[color=%s]Немедленные последствия: %s.[/color]" % [COL_WARN, txt])
	match String(v.get("enact", "")):
		"regime_shock":
			dip_all(-9.0, false)
			dip_all(-6.0, true)
			regime_risk = 25.0
			last_parl = turn
			log_line("[color=%s][b]Режим установлен.[/b] Парламент распущен или превращён в декорацию, демократические страны отзывают послов.[/color]" % COL_BAD)
			hold_parliament("роспуск парламента режимом")
		"eu_exit":
			MACRO["eu"] = false
			eu_left_t = turn
			dip_all(-14.0, true)
			risk_prem = minf(2.0, risk_prem + 0.4)
			if bool(MACRO.get("euro", false)):
				MACRO["euro"] = false
				MACRO["cb_own"] = 1.0
				MACRO["cb_off"] = float(MACRO.get("cb_off", 0.0)) + 0.4
				log_line("[color=%s]Страна покинула еврозону: ставку теперь задаёт национальный центробанк, курс валюты колеблется.[/color]" % COL_WARN)
			log_line("[color=%s][b]Выход из ЕС завершён.[/b] Единый рынок, фонды ЕС и общие правила больше не действуют.[/color]" % COL_BAD)
			sync_emit()
			log_line("Теперь у страны своя денежная политика: на экране «Бюджет» в блоке «Налоги» появился ползунок эмиссии.")
		"default_light":
			debt *= 0.75
			risk_prem = minf(2.0, risk_prem + 0.8)
			default_t = turn
		"default_hard":
			debt *= 0.35
			risk_prem = minf(2.0, risk_prem + 1.8)
			default_t = turn
			dip_all(-10.0, false)
			log_line("[color=%s][b]Дефолт объявлен.[/b] Кредиторы теряют деньги, рынки закрыты для вашей страны на годы.[/color]" % COL_BAD)
		"republic":
			dip_all(1.0, true)
		"monarchy":
			pass


func open_mult(c: String) -> float:
	if c != ccode:
		return 1.0
	var m := 1.0
	if rid_of("trade_policy") == "autarky":
		m *= 0.3
	if turn - eu_left_t < 60:
		m *= 0.8
	if turn - default_t < 60:
		m *= 0.8
	return m


func radical_dyn() -> void:
	if mods.is_empty():
		return
	mods["eff_bonus"] = clampf(float(mods["eff_bonus"]), -0.03, 0.03)
	var eid := econ_id()
	if eid == "planned":
		var pg: float = 0.35 if plan_t < 24 else lerpf(0.35, -1.0, clampf(float(plan_t - 24) / 96.0, 0.0, 1.0))
		mods["growth_bonus"] = float(mods["growth_bonus"]) + pg - shortage * 0.012
		mods["mood_shift"] = float(mods["mood_shift"]) - shortage * 0.006
		mods["corr_shift"] = float(mods["corr_shift"]) + shortage * 0.03
	if turn - default_t < 36:
		mods["growth_bonus"] = float(mods["growth_bonus"]) - 0.25
	if turn - eu_left_t < 60:
		mods["growth_bonus"] = float(mods["growth_bonus"]) - 0.12 * (1.0 - float(turn - eu_left_t) / 60.0)
	if decree_power() and regime_risk > 40.0:
		mods["mood_shift"] = float(mods["mood_shift"]) - (regime_risk - 40.0) * 0.004
	au_dyn()
	es_dyn()
	hist_dyn()
	io_dyn()


func radical_step() -> void:
	var rid := regime_id()
	var eid := econ_id()
	if rid != last_regime:
		last_regime = rid
		regime_t = 0
	regime_t += 1
	if eid == "planned":
		plan_t += 1
		var corr: float = float(lvl.get("corruption", 30.0))
		var ex: float = maxf(0.0, inflation - 2.2)
		shortage = clampf(shortage + 0.40 + corr * 0.006 + ex * 0.8 - float(lvl.get("infra_lvl", 50.0)) * 0.003, 0.0, 100.0)
		inflation = minf(inflation, 2.2)
		if turn % 12 == 0:
			log_line("[color=%s]План: выпуск по директивам, но дефицит товаров %.0f из 100 (очереди, чёрный рынок).[/color]" % [COL_WARN, shortage])
	else:
		plan_t = 0
		shortage *= 0.9
	if decree_power():
		crisis_months = 0
		var force: float = float(support["Силовики"])
		var tgt: float = 22.0 + minf(12.0, float(au_fat_months()) * 0.1) + au_risk_add() + maxf(0.0, 48.0 - approval()) * 1.6 + maxf(0.0, reg_avg("unrest") - 20.0) * 1.2 + shortage * 0.3 - maxf(0.0, force - 45.0) * 0.4
		regime_risk += (clampf(tgt, 0.0, 100.0) - regime_risk) * 0.15
		if turn % 6 == 0:
			dip_all(-1.5, true)
		if bool(MACRO.get("eu", true)):
			risk_prem = minf(1.0, risk_prem + 0.008)
		if regime_risk > 45.0 and current_event.is_empty() and turn - last_uprising >= 10 and randf() < (regime_risk - 40.0) * 0.0018:
			show_uprising()
	else:
		regime_risk *= 0.9
	au_step()
	es_step()
	io_step()


func show_uprising() -> void:
	last_uprising = turn
	var kind: String = regime_id()
	var t := "Недовольство режимом выплеснулось на улицы: колонны демонстрантов у главных зданий, часть гарнизона колеблется."
	if kind == "junta":
		t = "Младшие офицеры шепчутся о «возвращении в казармы», а на площадях требуют выборов. Хунта теряет контроль над частью гарнизонов."
	elif kind == "monarchy_abs":
		t = "При дворе зреет заговор: родственники монарха и генералы обсуждают замену правителя, а в городах вспыхнули протесты."
	elif kind == "oneparty":
		t = "Внутри партии раскол: реформаторы требуют конкуренции, а на заводах начались забастовки."
	current_event = {"t": t, "o": [
		{"l": "Подавить силой (капитал -8): жёстко, но шансы на успех зависят от прочности режима", "fx": {"capital": -8.0, "regall": {"unrest": -9.0}, "support": {"Молодёжь": -4.0, "Экологи": -3.0}, "rev_roll": 1.0, "risk_mul": 0.6}},
		{"l": "Уступки и частичная амнистия (капитал -10)", "fx": {"capital": -10.0, "all": 3.0, "regall": {"unrest": -5.0}, "support": {"Силовики": -3.0}, "rev_roll": 0.35, "risk_mul": 0.7}},
		{"l": "Чистка в армии и службах (капитал -6): заговорщики устранены, но верхушка напугана", "fx": {"capital": -6.0, "support": {"Силовики": -7.0}, "regall": {"unrest": -3.0}, "rev_roll": 0.55, "risk_mul": 0.65}}]}
	event_region = -1
	present_event()


func radical_roll(base: float) -> void:
	var pf: float = clampf(base * regime_risk / 100.0 * 0.7 + 0.02, 0.0, 0.85)
	if randf() >= pf:
		return
	var rid := regime_id()
	var msg := "Режим пал: восстание охватило страну, силовики отказались стрелять в толпу. Вы смещены, вас ждёт суд или изгнание."
	if rid == "junta":
		msg = "Хунта пала: внутри армии вспыхнул мятеж, и вы смещены своими же сослуживцами."
	elif rid == "monarchy_abs":
		msg = "Дворцовый переворот: заговорщики вынудили вас отречься от престола."
	elif rid == "oneparty":
		msg = "Партия отстранила вас от власти: на внеочередном съезде вас обвинили в провале курса."
	end_game(msg)


func radical_text() -> String:
	var t := ""
	var gv := ""
	if law_index.has("gov_form"):
		gv = String(variant_of("gov_form", cur_idx("gov_form"))["n"])
	var ec := ""
	if law_index.has("econ_model"):
		ec = String(variant_of("econ_model", cur_idx("econ_model"))["n"])
	t += "\n[b]Форма правления и строй[/b]\nФорма правления: [b]%s[/b]\nЭкономическая модель: [b]%s[/b]\n" % [gv, ec]
	if decree_power():
		var col := COL_GOOD if regime_risk < 35.0 else (COL_WARN if regime_risk < 60.0 else COL_BAD)
		t += "[color=%s]Власть указами: парламент и верхняя палата законы не блокируют. Риск восстания или переворота: [b]%.0f%%[/b] — растёт при низком рейтинге, недовольстве регионов и слабости силовиков.[/color]\n" % [col, regime_risk]
	if econ_id() == "planned":
		var colp := COL_GOOD if shortage < 30.0 else (COL_WARN if shortage < 60.0 else COL_BAD)
		t += "[color=%s]Плановая экономика: %d-й месяц плана, дефицит товаров [b]%.0f[/b] из 100. Цены заморожены, инфляция скрыта.[/color]\n" % [colp, plan_t, shortage]
	if turn - default_t < 60:
		t += "[color=%s]Последствия дефолта: рынки закрыты, рост подавлен ещё около %s.[/color]\n" % [COL_WARN, months_text(maxi(0, 60 - (turn - default_t)))]
	if turn - eu_left_t < 60:
		t += "[color=%s]Последствия выхода из ЕС: торговля и инвестиции перестраиваются ещё около %s.[/color]\n" % [COL_WARN, months_text(maxi(0, 60 - (turn - eu_left_t)))]
	return t


func active_rids() -> Array:
	var out: Array = []
	for tid in law_index:
		var r := rid_of(String(tid))
		if r != "":
			out.append(r)
	return out


func radical_events() -> Array:
	var act := active_rids()
	var out: Array = []
	for e in RAD_EVENTS:
		var need: Array = e["rid"]
		var ok := false
		for r in need:
			if r in act:
				ok = true
		if ok:
			out.append(e)
			out.append(e)
	return out


func radical_add_variants(tid: String, vars: Array, fund_flag: bool = true) -> void:
	if not law_index_pre.has(tid):
		return
	var t: Dictionary = law_index_pre[tid]
	for v in vars:
		if (t["v"] as Array).size() >= 8:
			break
		(t["v"] as Array).append(v)
	if fund_flag:
		t["fund"] = true


func radical_inject() -> void:
	law_index_pre.clear()
	for t in LAW_TOPICS:
		law_index_pre[t["id"]] = t
	var mon: bool = ccode in RAD_MONARCHIES
	var cur_name: String = String(RAD_CUR.get(ccode, ""))
	# --- форма правления ---
	var gov_new: Array = []
	if not mon:
		gov_new.append(RV("Конституционная монархия", "Республика заменяется монархией: на трон возводится представитель династии, глава государства становится символом единства, а власть остаётся у правительства. Президентские законы упраздняются.", 48.0,
			{"Пенсионеры": 2.0, "Село": 3.0, "Силовики": 2.0, "Молодёжь": -4.0, "Рабочие": -1.0, "Экологи": -2.0}, {"dem_shift": -0.02, "mood_shift": -0.1, "capital_bonus": 0.05},
			{"own": 1, "cons": 4, "popr": 4, "lib": -3, "soc": -6, "left": -10, "green": -6, "popl": -4, "euro": -5, "region": -1, "oth": -2},
			{"rid": "monarchy_const", "freeze": ["pres_term_law", "pres_vote_rule", "presidency_powers", "president_powers"]}))
	else:
		gov_new.append(RV("Республика", "Монархия упраздняется по итогам референдума: глава государства избирается, а династия лишается привилегий. Молодёжь довольна, консерваторы и деревня возмущены.", 48.0,
			{"Молодёжь": 3.0, "Рабочие": 1.0, "Пенсионеры": -2.0, "Село": -2.0, "Силовики": -1.0}, {"dem_shift": 0.03, "capital_bonus": -0.05},
			{"left": 8, "soc": 3, "green": 3, "popl": 3, "cons": -6, "popr": -3, "region": 1, "euro": 1}, {"rid": "republic"}))
	gov_new.append(RV("Абсолютная монархия", "Монарх правит указами, парламент распущен или совещателен, суды подчиняются двору. Решения мгновенны, политкапитал не нужен, но страна выпадает из семьи демократий, а власть зависит от верности армии. Переворот: голосование не требуется, нужна поддержка силовиков.", 55.0,
		{"Силовики": 4.0, "Село": 3.0, "Пенсионеры": 2.0, "Молодёжь": -8.0, "Бюджетники": -3.0, "Рабочие": -3.0, "Экологи": -3.0},
		{"dem_shift": -0.60, "capital_bonus": 0.55, "mood_shift": -0.5, "corr_shift": 6.0, "dip_bonus": -1.2, "growth_bonus": -0.10, "sec_bonus": 2.0},
		{"cons": 2, "popr": 2, "own": 5, "lib": -8, "soc": -10, "left": -10, "green": -9, "popl": -6, "euro": -9, "region": -4, "oth": -3},
		{"rid": "monarchy_abs", "coup": true, "req": {"force": 55}, "set": {"parl_term": 120}, "st": {"corruption": 4.0, "security_lvl": 2.0},
		 "fxnow": {"all": -5.0, "regall": {"unrest": 5.0}}, "enact": "regime_shock"}))
	gov_new.append(RV("Суперпрезидентская республика", "Вся власть у президента: парламент и суды ему подчинены, но выборы ещё проводятся. Решения быстрее, политкапитала больше, демократия слабеет, а коррупция растёт.", 40.0,
		{"Силовики": 4.0, "Бизнес": 1.0, "Молодёжь": -5.0, "Рабочие": -1.0}, {"dem_shift": -0.22, "capital_bonus": 0.30, "corr_shift": 3.0},
		{"own": 8, "soc": -4, "lib": -4, "left": -3, "green": -5, "popl": -2, "cons": -1, "euro": -5, "region": -4, "prot": -6},
		{"rid": "superpres", "freeze": ["impeach_rule", "censure_rule"], "set": {"pres_term": 84}}))
	gov_new.append(RV("Диктатура (режим личной власти)", "Вы становитесь единоличным правителем: выборы превращаются в ритуал, оппозиция запрещена, СМИ и суды под контролем. Закон принимается указом, политкапитал растёт, силовики довольны, но международная изоляция, коррупция и риск восстания реальны. Переворот: голосование не требуется, нужна поддержка силовиков.", 50.0,
		{"Силовики": 6.0, "Молодёжь": -9.0, "Бюджетники": -2.0, "Рабочие": -2.0, "Экологи": -5.0},
		{"dem_shift": -0.80, "capital_bonus": 0.60, "mood_shift": -0.6, "corr_shift": 8.0, "sec_bonus": 3.0, "dip_bonus": -1.5, "growth_bonus": -0.05},
		{"own": 6, "cons": -3, "popr": -2, "lib": -10, "soc": -10, "left": -10, "green": -10, "popl": -7, "euro": -10, "region": -6, "oth": -4},
		{"rid": "dictatorship", "coup": true, "req": {"force": 60}, "set": {"parl_term": 120}, "st": {"security_lvl": 5.0, "corruption": 6.0, "equality": -2.0},
		 "fxnow": {"all": -6.0, "regall": {"unrest": 7.0, "loyalty": -3.0}}, "enact": "regime_shock"}))
	gov_new.append(RV("Военное правление (хунта)", "Власть переходит к военному совету: конституция приостановлена, комендантский час, армия получает бюджеты и контроль над ведомствами. Порядок и безопасность растут, свободы исчезают. Нужен кризис и сильная опора на силовиков; голосование не требуется.", 50.0,
		{"Силовики": 8.0, "Молодёжь": -8.0, "Экологи": -4.0, "Бюджетники": -2.0, "Рабочие": -2.0},
		{"dem_shift": -0.75, "capital_bonus": 0.50, "sec_bonus": 4.0, "growth_bonus": -0.15, "mood_shift": -0.5, "corr_shift": 4.0, "dip_bonus": -1.5, "extra_spend": 0.3},
		{"own": 5, "cons": -2, "popr": -1, "lib": -10, "soc": -10, "left": -10, "green": -10, "popl": -7, "euro": -10, "region": -6, "oth": -4},
		{"rid": "junta", "coup": true, "req": {"force": 65, "unrest": 28}, "set": {"parl_term": 120}, "st": {"security_lvl": 6.0},
		 "fxnow": {"all": -5.0, "regall": {"unrest": 5.0, "loyalty": -2.0}}, "enact": "regime_shock"}))
	gov_new.append(RV("Однопартийное государство", "Остаётся одна легальная партия — ваша: остальные запрещены, парламент собирается для одобрения решений. Бюджетники и рабочие получают стабильность и равенство, но политических свобод нет. Нужна опора на силовиков; голосование не требуется.", 50.0,
		{"Бюджетники": 3.0, "Рабочие": 1.0, "Силовики": 4.0, "Молодёжь": -7.0, "Бизнес": -3.0, "Экологи": -4.0},
		{"dem_shift": -0.70, "capital_bonus": 0.50, "corr_shift": 5.0, "mood_shift": -0.3, "equal_shift": 1.5, "sec_bonus": 2.5, "dip_bonus": -1.3, "growth_bonus": -0.08},
		{"own": 6, "cons": -4, "popr": -3, "lib": -10, "soc": -10, "left": -9, "green": -10, "popl": -6, "euro": -10, "region": -6, "oth": -4},
		{"rid": "oneparty", "coup": true, "req": {"force": 50}, "set": {"parl_term": 120}, "st": {"security_lvl": 3.0, "corruption": 4.0},
		 "fxnow": {"all": -5.0, "regall": {"unrest": 5.0}}, "enact": "regime_shock"}))
	gov_new.append(RV("Прямая демократия", "Важные решения принимают референдумы, граждане могут отменить любой закон. Власть ближе к людям и общество доверяет государству, но правительству трудно вести долгие программы и непопулярные реформы.", 45.0,
		{"Молодёжь": 4.0, "Рабочие": 2.0, "Село": 2.0, "Бизнес": -3.0, "Силовики": -4.0, "Бюджетники": -1.0},
		{"dem_shift": 0.15, "capital_bonus": -0.40, "mood_shift": 0.3, "growth_bonus": -0.05, "corr_shift": -3.0, "reg_unrest_shift": -1.0},
		{"popl": 6, "popr": 6, "prot": 5, "region": 4, "own": -6, "lib": -3, "cons": -4, "soc": -2, "euro": -5, "left": 3, "green": 2},
		{"rid": "direct_dem"}))
	if law_index_pre.has("gov_form"):
		radical_add_variants("gov_form", [gov_new[0], gov_new[1], gov_new[3 + 1], gov_new[3 + 2], gov_new[3 + 3]])
	else:
		var tg := {"id": "gov_form", "cat": 0, "name": "Форма правления", "desc": "Кто и как управляет страной: от конституционной монархии и республики до диктатуры. Радикальные формы правления меняют всю политическую систему и замораживают несовместимые законы.", "fund": true,
			"v": [{"n": cur_name if cur_name != "" else "Действующий строй", "d": "Действующий порядок."}]}
		for v in gov_new:
			(tg["v"] as Array).append(v)
		var at := 0
		LAW_TOPICS.insert(at, tg)
		law_index_pre["gov_form"] = tg
	# --- экономика ---
	radical_add_variants("econ_model", [
		RV("Директивная плановая экономика", "Государство национализирует крупные предприятия и банки, составляет пятилетние планы, фиксирует цены и зарплаты. Первые годы растут мобилизационный выпуск и занятость, потом приходят дефицит, очереди и чёрный рынок. Рыночные законы сбрасываются и замораживаются.", 55.0,
			{"Рабочие": 3.0, "Бюджетники": 4.0, "Пенсионеры": 2.0, "Силовики": 2.0, "Бизнес": -9.0, "Молодёжь": -3.0, "Село": -2.0},
			{"equal_shift": 4.0, "extra_spend": 1.0, "unemp_base": -2.0, "dem_shift": -0.10, "corr_shift": 3.0, "capital_bonus": 0.2, "dip_bonus": -0.8},
			{"left": 10, "popl": 6, "soc": 2, "popr": -2, "lib": -10, "cons": -8, "euro": -6, "green": -2, "prot": 2},
			{"rid": "planned", "x": {"admin_mult": 1.3, "vat_mult": 0.9, "income_mult": 0.85}, "st": {"equality": 5.0, "corruption": 3.0}, "debt": 4.0,
			 "reset": RAD_MARKET_TOPICS, "freeze": RAD_MARKET_TOPICS}),
		RV("Кооперативный социализм (рабочее самоуправление)", "Крупные предприятия переходят трудовым коллективам и кооперативам; рынок сохраняется, но прибыль распределяют работники. Выше равенство и вовлечённость, ниже инвестиции и управляемость.", 50.0,
			{"Рабочие": 5.0, "Молодёжь": 2.0, "Бюджетники": 2.0, "Бизнес": -8.0, "Силовики": -2.0, "Село": 1.0, "Экологи": 1.0},
			{"equal_shift": 4.0, "growth_bonus": -0.15, "mood_shift": 0.3, "dem_shift": 0.02, "corr_shift": -1.0, "extra_spend": 0.2},
			{"left": 9, "green": 3, "popl": 5, "soc": 4, "lib": -8, "cons": -6, "popr": -3, "euro": -2},
			{"rid": "coop", "st": {"equality": 5.0}, "reset": ["state_property", "antimonopoly", "bankruptcy_law", "invest_code"], "freeze": ["state_property", "antimonopoly", "bankruptcy_law", "invest_code"]}),
		RV("Радикальный свободный рынок (минимальное государство)", "Государство сокращается до суда, полиции и армии: налоги и регулирование падают, госсектор приватизируется, соцзащита становится частной. Быстрый рост и приток капитала, но неравенство и недовольство низов.", 55.0,
			{"Бизнес": 8.0, "Молодёжь": 1.0, "Рабочие": -6.0, "Бюджетники": -8.0, "Пенсионеры": -6.0, "Село": -2.0, "Экологи": -3.0},
			{"growth_bonus": 0.35, "equal_shift": -5.0, "extra_spend": -1.2, "mood_shift": -0.3, "corr_shift": -1.0, "capital_bonus": -0.05, "unemp_base": 0.4},
			{"lib": 10, "cons": 3, "soc": -8, "left": -10, "popl": -5, "green": -4, "euro": 2},
			{"rid": "libertarian", "x": {"admin_mult": 0.7, "income_mult": 0.9, "pension_mult": 0.85}, "st": {"equality": -6.0}, "debt": -6.0})])
	radical_add_variants("civil_rights", [
		RV("Полицейское государство (тотальный надзор)", "Слежка, обыски без санкции, доносы и закрытые суды: безопасность растёт, свободы исчезают. Молодёжь и экологи возмущены.", 40.0,
			{"Силовики": 6.0, "Молодёжь": -8.0, "Экологи": -4.0, "Бизнес": -1.0},
			{"dem_shift": -0.35, "sec_bonus": 4.0, "mood_shift": -0.6, "corr_shift": 3.0, "capital_bonus": 0.2},
			{"own": 5, "cons": 2, "popr": 2, "lib": -4, "soc": -6, "left": -9, "green": -8, "popl": -4, "euro": -6, "prot": -4},
			{"rid": "police_state", "st": {"security_lvl": 6.0}})])
	radical_add_variants("trade_policy", [
		RV("Автаркия (самообеспечение)", "Страна закрывается от мировой торговли: импорт под лицензиями, ставка на собственное производство. Меньше внешних шоков и безработицы, но товары хуже и дороже, рост слабее. Несовместимо с ЕС.", 40.0,
			{"Рабочие": 2.0, "Село": 3.0, "Силовики": 3.0, "Бизнес": -7.0, "Молодёжь": -4.0, "Экологи": 1.0},
			{"growth_bonus": -0.35, "unemp_base": -0.3, "dip_bonus": -1.0, "extra_spend": 0.2, "equal_shift": 0.5},
			{"popl": 4, "popr": 5, "left": 3, "prot": 4, "lib": -9, "cons": -4, "euro": -8},
			{"rid": "autarky", "req": {"noteu": true}})])
	radical_add_variants("social_model", [
		RV("Безусловный базовый доход", "Каждый гражданин получает ежемесячную выплату без условий. Бедность и тревога падают, но расходы огромны, а рабочих рук местами не хватает.", 45.0,
			{"Рабочие": 2.0, "Молодёжь": 4.0, "Пенсионеры": 1.0, "Бюджетники": 1.0, "Бизнес": -3.0, "Село": 1.0},
			{"extra_spend": 1.2, "equal_shift": 3.0, "mood_shift": 0.4, "growth_bonus": -0.05, "unemp_base": 0.3},
			{"left": 6, "green": 4, "popl": 3, "soc": 2, "lib": -2, "cons": -5, "popr": -3, "euro": 0},
			{"rid": "ubi", "st": {"equality": 4.0}})])
	if bool(MACRO.get("eu", true)):
		radical_add_variants("eu_policy", [
			RV("Выход из ЕС", "Страна выходит из Евросоюза (а если она в еврозоне — и из неё): нет взносов и правил Брюсселя, но рвутся торговые и финансовые связи, партнёры охладевают, рынки нервничают.", 50.0,
				{"Силовики": 3.0, "Село": 3.0, "Бизнес": -6.0, "Молодёжь": -8.0, "Пенсионеры": 1.0, "Экологи": -3.0},
				{"dip_bonus": -1.2, "growth_bonus": -0.20},
				{"popr": 9, "popl": 6, "prot": 9, "euro": -10, "lib": -4, "cons": -3, "soc": -6, "green": -8, "own": -1, "region": 1},
				{"rid": "eu_exit", "enact": "eu_exit", "set": {"brake_room": 99.0}, "fxnow": {"all": -2.0}})])
	radical_add_variants("state_structure", [
		RV("Конфедерация (почти независимые регионы)", "Центр сохраняет армию и внешнюю политику, всё остальное решают регионы. Автономистов успокоить легко, но единства и сборов налогов меньше.", 50.0,
			{"Силовики": -7.0, "Бюджетники": -3.0, "Село": 2.0},
			{"auto_shift": 20.0, "growth_bonus": -0.08, "dem_shift": 0.03, "corr_shift": 2.0},
			{"region": 10, "own": -5, "cons": -2, "popr": -3, "left": 1},
			{"rid": "confed", "rg": {"autonomy": 25.0, "unrest": -8.0, "loyalty": -4.0}})])
	# --- новые темы ---
	var news: Array = []
	news.append({"id": "military_state", "cat": 0, "name": "Милитаризация общества", "desc": "Роль армии в жизни страны: от профессиональной армии до мобилизационного государства или полного разоружения.", "fund": true, "v": [
		{"n": "Профессиональная армия", "d": "Действующий порядок: контрактная армия и обычные расходы на оборону."},
		RV("Всеобщий призыв и мобилизационный резерв", "Каждый юноша проходит службу, создаётся резерв. Страна безопаснее, но молодёжь недовольна, а бюджет тяжелее.", 30.0,
			{"Силовики": 4.0, "Молодёжь": -5.0, "Село": 1.0, "Бизнес": -1.0, "Экологи": -2.0}, {"sec_bonus": 2.0, "extra_spend": 0.4, "growth_bonus": -0.05, "mood_shift": -0.2},
			{"cons": 4, "popr": 4, "own": 2, "left": -6, "green": -6, "soc": -3, "lib": -3, "popl": -3}, {"st": {"security_lvl": 3.0}, "rid": "conscription"}),
		RV("Мобилизационное государство", "Экономика и общество переведены на военные рельсы: заказы оборонке, занятость высокая, жёсткая дисциплина. Свободы урезаны, страна живёт готовностью к войне.", 50.0,
			{"Силовики": 7.0, "Молодёжь": -7.0, "Бизнес": -1.0, "Рабочие": 1.0, "Бюджетники": 1.0, "Экологи": -4.0},
			{"sec_bonus": 4.0, "extra_spend": 1.2, "growth_bonus": 0.05, "mood_shift": -0.4, "dem_shift": -0.15, "unemp_base": -0.4, "dip_bonus": -0.6},
			{"popr": 5, "cons": 3, "own": 3, "left": -8, "green": -8, "soc": -4, "lib": -4, "popl": -2, "euro": -4}, {"st": {"security_lvl": 6.0}, "rid": "militarized"}),
		RV("Демилитаризация и нейтралитет", "Армия распускается, остаются пограничная служба и полиция. Бюджет легче, молодёжь рада, но безопасность и вес в союзе слабее.", 40.0,
			{"Молодёжь": 3.0, "Экологи": 3.0, "Бюджетники": 1.0, "Силовики": -9.0},
			{"extra_spend": -0.6, "sec_bonus": -3.0, "dip_bonus": 0.3, "mood_shift": 0.1},
			{"left": 6, "green": 6, "popl": 2, "soc": 1, "cons": -7, "popr": -5, "own": -3, "lib": -1}, {"st": {"security_lvl": -4.0}, "rid": "demilitarized"})]})
	news.append({"id": "debt_default", "cat": 1, "name": "Государственный долг", "desc": "Что делать с накопленным долгом: платить, пересмотреть условия или отказаться платить.", "fund": true, "v": [
		{"n": "Обслуживание долга по графику", "d": "Действующий порядок."},
		RV("Реструктуризация долга", "Долг списывается примерно на четверть по договорённости с кредиторами. Бремя легче, но рынки закрыты на год-два, а ставки выше.", 40.0,
			{"Бизнес": -3.0, "Пенсионеры": -2.0, "Рабочие": 1.0, "Бюджетники": 2.0}, {"growth_bonus": -0.10},
			{"left": 5, "popl": 4, "popr": 2, "lib": -6, "cons": -4, "soc": 1, "euro": -4, "green": 0}, {"enact": "default_light", "req": {"nodefault": true}}),
		RV("Отказ платить по долгам (дефолт)", "Большая часть долга аннулируется. Бюджет получает передышку, но кредиторы не простят: рынки закрыты на годы, ставки взлетают, бизнес и вкладчики в ярости.", 50.0,
			{"Рабочие": 2.0, "Бюджетники": 3.0, "Бизнес": -7.0, "Пенсионеры": -4.0, "Молодёжь": -1.0},
			{"growth_bonus": -0.10, "dip_bonus": -0.8},
			{"left": 8, "popl": 7, "prot": 6, "popr": 3, "lib": -10, "cons": -7, "soc": -2, "euro": -9, "green": -1}, {"enact": "default_hard", "req": {"nodefault": true}, "fxnow": {"shock": -1.0, "all": -3.0}})]})
	news.append({"id": "state_church", "cat": 2, "name": "Религия и государство", "desc": "Отношения государства с религией: от строгого лаицизма до теократии.", "fund": true, "v": [
		{"n": "Светское государство", "d": "Действующий порядок: церковь отделена от государства."},
		RV("Государственная церковь и религиозное образование", "Одна конфессия получает статус государственной, религия вводится в школах. Пенсионеры и деревня довольны, молодёжь и либералы нет.", 35.0,
			{"Пенсионеры": 4.0, "Село": 4.0, "Молодёжь": -5.0, "Экологи": -2.0, "Силовики": 1.0}, {"mood_shift": -0.1, "dem_shift": -0.03},
			{"cons": 5, "popr": 5, "own": 1, "lib": -4, "left": -8, "green": -6, "soc": -4, "popl": -2}, {"rid": "church"}),
		RV("Теократия: религиозное право", "Религиозные нормы становятся законом, духовенство получает право вето на решения власти. Ценности объединяют часть общества, остальные теряют права, а мир отворачивается.", 55.0,
			{"Пенсионеры": 5.0, "Село": 5.0, "Силовики": 2.0, "Молодёжь": -9.0, "Экологи": -4.0, "Бизнес": -2.0, "Рабочие": -1.0},
			{"dem_shift": -0.50, "mood_shift": -0.4, "capital_bonus": 0.30, "sec_bonus": 2.0, "dip_bonus": -1.2, "growth_bonus": -0.10, "equal_shift": -1.0},
			{"popr": 5, "cons": 2, "own": 2, "lib": -10, "left": -10, "green": -10, "soc": -9, "popl": -4, "euro": -9}, {"rid": "theocracy", "fxnow": {"regall": {"unrest": 4.0}}, "enact": "regime_shock"}),
		RV("Строгий лаицизм", "Религиозные символы убираются из общественной жизни. Секулярные группы довольны, верующие чувствуют давление.", 30.0,
			{"Молодёжь": 2.0, "Экологи": 1.0, "Силовики": 1.0, "Пенсионеры": -2.0, "Село": -2.0}, {"mood_shift": -0.1, "reg_unrest_shift": 0.4, "sec_bonus": 0.5},
			{"left": 4, "lib": 3, "green": 2, "cons": -3, "popr": 1, "soc": 3}, {"rid": "laicite"})]})
	for t in news:
		var at2 := LAW_TOPICS.size()
		for i in LAW_TOPICS.size():
			if int(LAW_TOPICS[i]["cat"]) > int(t["cat"]):
				at2 = i
				break
		LAW_TOPICS.insert(at2, t)
		law_index_pre[t["id"]] = t
