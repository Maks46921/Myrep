extends SceneTree
# v38: политика войны — голосование, недовольство партий, переговоры, перемирие, посредник, реакция мира.

var bad := 0


func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)


func play_days(m, n: int) -> void:
	for i in n:
		m.game_over = false
		if m.election_open:
			m.election_continue()
		if m.opp_mode:
			m.opp_to_gov([0], 0, "Тест.")
		if not m.current_event.is_empty():
			m.choose(0)
		m.advance_day()


func new_game(cc: String):
	var m = load("res://main.gd").new()
	m.game_opts.merge({"ev": 0.0, "news": 0.0, "fedev": 0, "socev": 0, "exev": 0, "milev": 0}, true)
	m.game_opts["seed"] = 11
	m.game_opts["country"] = cc
	root.add_child(m)
	return m


func _init():
	var cc := "DE"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("country="): cc = a.substr(8)
	var m = new_game(cc)
	for i in 3: await process_frame
	check(m.ccode == cc, "страна " + cc)
	var land: Array = []
	for c in m.mil_targets():
		if m.mil_land_neighbor(c):
			land.append(String(c))
	var tg: Array = land if not land.is_empty() else m.mil_targets()
	if tg.is_empty():
		print("нет соседей — проверяем только расчёты")
		check(m.war_intl_text() is String, "текст реакции мира")
		print("t_warpol: проблем ", bad)
		quit(1 if bad > 0 else 0)
		return
	var foe: String = String(tg[0])
	for c in tg:
		if m.mil_country_power(c) < m.mil_country_power(foe):
			foe = String(c)
	print("противник: ", foe, " демократия ", m.war_demo(foe), ", своя ", m.war_demo(cc))

	# голосование
	var vt: Dictionary = m.war_vote(foe)
	check(int(vt["total"]) > 0 and int(vt["yes"]) <= int(vt["total"]), "голосование посчитано")
	check(int(vt["yes"]) >= int(m.seats[0]), "своя партия голосует «за»")
	check((vt["rows"] as Array).size() >= 2, "в голосовании несколько партий")
	print(m.war_vote_text(foe))

	# нападение демократии на демократию бьёт сильнее, чем на автократию (два одинаковых старта)
	var m2 = new_game(cc)
	for i in 3: await process_frame
	var a1: float = m.approval()
	var a2: float = m2.approval()
	m.war_on_declare("CH" if cc != "CH" else "NO")
	m2.war_on_declare("RS" if cc != "RS" else "HU")
	var d1: float = a1 - m.approval()
	var d2: float = a2 - m2.approval()
	print("падение одобрения: против демократии %.2f, против слабой демократии %.2f" % [d1, d2])
	check(d1 > 0.0, "нападение снижает одобрение")
	if m.war_demo(cc) >= 0.6:
		check(d1 > d2, "нападение на демократию бьёт сильнее (%.2f > %.2f)" % [d1, d2])
		check(not (m.mil.get("anger", {}) as Dictionary).is_empty(), "партии недовольны войной")
	m2.queue_free()
	m.mil["anger"] = {}

	# объявление войны
	var sat0 := {}
	for p in m.PARTY_NAMES.size():
		if m.in_coalition[p] and p != 0:
			sat0[p] = float(m.satis.get(p, 50.0))
	var r: Dictionary = m.mil_declare(foe, true)
	check(bool(r["done"]) and m.mil_at_war(), "война объявлена: " + String(r["msg"]))
	print(r["msg"])
	if m.war_demo(cc) >= 0.6 and m.war_demo(foe) >= 0.6:
		var an: Dictionary = m.mil.get("anger", {})
		check(not an.is_empty(), "демократия против демократии: партии злятся")
		for p in an:
			check(m.war_prel_term(int(p)) < 0.0, "отношения с недовольной партией хуже")
		for p in sat0:
			if an.has(p):
				check(float(m.satis.get(p, 50.0)) < float(sat0[p]), "партнёр по коалиции недоволен войной")
	var w: Dictionary = m.mil["war"]
	var it: Dictionary = m.war_intl(w)
	check(float(it["cond"]) > 0.0, "мир осуждает агрессора (%.0f)" % float(it["cond"]))
	if m.war_both_eu(cc, foe):
		check(bool(it["eu"]) and bool(w["sanct"]), "ЕС вводит санкции при войне внутри ЕС")
	check(m.war_prem() > 0.0, "премия за риск по долгу")
	var dr0: float = m.debt_rate()
	m.mil_mobilize(2)
	for f in m.mil_units_of(cc):
		m.mil_order_mode(int(f["id"]), "auto")
	play_days(m, 70)
	if m.mil_at_war():
		check(int(it["un"]) >= 1, "ООН осудила нападение")
		print(m.war_intl_text())
		check(m.war_intl_text().length() > 20, "текст реакции мира")

	# перемирие и посредник
	if m.mil_at_war():
		m.mil["war"]["cf_cd"] = 0
		m.mil["war"]["score"] = 0.0
		var cf: Dictionary = m.talk_ceasefire()
		check(bool(cf["done"]), "перемирие: " + String(cf["msg"]))
		var k0: float = float(m.mil["war"]["kia"][0]) + float(m.mil["war"]["kia"][1])
		var ctl0: int = (m.mil["ctl"] as Dictionary).size()
		play_days(m, 10)
		if m.mil_at_war():
			check(float(m.mil["war"]["kia"][0]) + float(m.mil["war"]["kia"][1]) == k0, "в перемирие нет потерь")
			check((m.mil["ctl"] as Dictionary).size() == ctl0, "в перемирие фронт стоит")
			check(m.talk_ceasefire_check() != "", "второе перемирие сразу нельзя")
			m.capital = 30.0
			var md: Dictionary = m.talk_mediator()
			check(bool(md["done"]) and String(m.mil["war"].get("med", "")) != "", "посредник: " + String(md["msg"]))
			m.talk_ceasefire_break()
			check(int(m.mil["war"]["cf"]) == 0, "перемирие прервано")

	# переговоры: пакет требований
	if m.mil_at_war():
		var sel: Dictionary = m.talk_sel()
		sel["land"] = true
		sel["repar"] = 2
		sel["disarm"] = true
		sel["guilt"] = true
		var q: Dictionary = m.talk_quote()
		check(float(q["cost"]) > 0.0, "цена требований посчитана (%.0f при готовности %.0f)" % [float(q["cost"]), float(q["budget"])])
		# слишком много требований при плохом счёте — отказ и встречное предложение
		m.mil["war"]["score"] = -5.0
		m.mil["war"]["prop_cd"] = 0
		var pr: Dictionary = m.talk_propose()
		check(not bool(pr.get("done", false)) or not m.mil_at_war(), "завышенные требования: " + String(pr["msg"]))
		if not m.current_event.is_empty():
			m.choose(0)
		# побеждаем — условия принимаются
		m.mil["war"]["score"] = 95.0
		m.mil["war"]["prop_cd"] = 0
		var occ: Array = m.mil_occupied_by_us(foe)
		var debt0: float = m.debt
		var pr2: Dictionary = m.talk_propose()
		for att in 4:      # принятие вероятностное (p = 0.95): при редком отказе повторяем
			if bool(pr2["done"]):
				break
			if not m.current_event.is_empty():
				m.choose(0)
			m.mil["war"]["prop_cd"] = 0
			pr2 = m.talk_propose()
		print(pr2["msg"])
		check(bool(pr2["done"]) and not m.mil_at_war(), "мир на условиях игрока: " + String(pr2["msg"]))
		check(m.debt < debt0, "репарации уменьшили долг")
		check((m.mil.get("lim", {}) as Dictionary).has(foe), "армия противника ограничена")
		check(m.mil_country_power(foe) < m.MIL_BASE[foe][0] * m.MIL_COMBAT * m.MIL_BASE[foe][2] * 0.6, "ограничение армии снижает силу")
		if not occ.is_empty() and m.war_demo(foe) >= 0.5:
			check(m.war_nonrec_any(), "аннексия не признана")
			check(m.war_prem() > 0.0, "непризнание: надбавка к ставке")
		for k in 3:
			m.war_timers_month()
		if (m.mil.get("lim", {}) as Dictionary).has(foe):
			check(int(m.mil["lim"][foe]["m"]) == 57, "срок ограничения идёт")
	print("ставка по долгу в войну: %.2f%%" % (dr0 * 100.0))

	# противник побеждает: выкуп земель
	m.mil["truce"] = {}
	m.mil["lim"] = {}
	var foe2 := foe
	for c in tg:
		if String(c) != foe and m.wsim.has(c):
			foe2 = String(c)
			break
	if m.wsim.has(foe2) and not m.mil_at_war():
		m.capital = 50.0
		m.mil_declare(foe2, true)
		check(m.mil_at_war(), "вторая война")
		if m.mil_at_war():
			var w2: Dictionary = m.mil["war"]
			# вступление третьей страны
			var third := ""
			for c in m.wsim:
				if m.mil_side(String(c)) < 0 and m.MIL_BASE.has(c) and c != m.ccode:
					third = String(c)
					break
			if third != "":
				var n0: int = m.mil_units_of(third).size()
				m.war_join(third, 1)
				check(m.mil_side(third) == 1 and m.mil_units_of(third).size() > n0, "третья страна вступила в войну: " + third)
			w2["score"] = -50.0
			w2["offer_cd"] = 0
			w2["days"] = 40
			m.current_event = {}
			m.election_open = false
			var ates0: int = m.mil_cc_ates(cc).filter(func(a): return m.ate_cc(int(a)) == cc).size()
			var d0: float = m.debt
			m.mil_ai_peace()
			var ks: Array = m.mil.get("pend", {}).get("kinds", [])
			check("lose_pay" in ks, "противник предлагает и выкуп: " + str(ks))
			if "lose_pay" in ks:
				m.choose(ks.find("lose_pay"))
				check(not m.mil_at_war(), "мир с выкупом заключён")
				check(m.debt > d0, "выкуп стоит денег")
				var ates1: int = m.mil_cc_ates(cc).filter(func(a): return m.ate_cc(int(a)) == cc).size()
				check(ates1 == ates0, "земли не уступлены")
		# давление мира: отказ повышает осуждение
	m.mil["truce"] = {}
	if not m.mil_at_war() and m.wsim.has(foe2):
		m.mil_declare(foe2, true)
		if m.mil_at_war():
			var it3: Dictionary = m.war_intl(m.mil["war"])
			var c0: float = float(it3["cond"])
			m.mil["pend"] = {"kinds": ["press_no", "press_cf", "press_med"]}
			m.mil_resolve(0)
			check(float(it3["cond"]) > c0 or c0 >= 100.0, "отказ от перемирия усиливает осуждение")
			m.mil["pend"] = {"kinds": ["press_no", "press_cf", "press_med"]}
			m.mil["war"]["cf_cd"] = 0
			m.mil_resolve(1)
			check(int(m.mil["war"].get("cf", 0)) > 0, "согласие на перемирие")
			m.mil_peace("white")
	# нейтралитет: союзники не помогают
	m.mil["neutral"] = ["PL"]
	check(m.mil_allies_for("PL", "XX").is_empty(), "нейтральная страна без союзников")
	m.mil["neutral"] = []
	play_days(m, 35)
	check(is_finite(m.debt) and is_finite(m.gdp), "экономика конечна")
	print("t_warpol: проблем ", bad)
	quit(1 if bad > 0 else 0)
