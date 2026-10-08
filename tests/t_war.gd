extends SceneTree
# v37: армия и войны. Мирное время (набор, мобилизация, приказ), война с соседом (бои, оккупация, мир с присоединением АТЕ),
# поражение (уступка АТЕ), нападение ИИ и белый мир, полное присоединение страны, десант. Печатает «проблем N».
var bad := 0
func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)


func own_ates(m) -> int:
	return m.mil_cc_ates(m.ccode).size()


func play_days(m, n: int) -> void:
	for i in n:
		if m.game_over:
			# проигранная война может довести до дефолта — для проверки механик войны игру продолжаем
			print("игра окончена: ", m.end_reason, " (тест продолжает)")
			m.game_over = false
		if m.election_open:
			m.election_continue()
		if m.opp_mode:
			# проигранные выборы или капитуляция уводят в оппозицию — тест проверяет войну, поэтому возвращаем власть
			print("ушли в оппозицию на ходу %d (тест возвращает власть)" % m.turn)
			m.opp_to_gov([0], 0, "Тест.")
		if not m.current_event.is_empty():
			m.choose(0)
		m.advance_day()


func consistent(m, tag: String) -> void:
	check(m.regions.size() == m.REGIONS.size(), tag + ": regions/REGIONS")
	var empty := 0
	for i in m.REGIONS.size():
		if m.adm_region_ates(i).size() == 0:
			empty += 1
	check(empty == 0, tag + ": пустых регионов %d" % empty)
	check(is_finite(m.gdp) and m.gdp > 0.0, tag + ": ВВП %.1f" % m.gdp)
	check(is_finite(m.debt), tag + ": долг")
	print("  ", tag, ": долг %.0f%% ВВП, ВВП %.0f, одобрение %.0f" % [m.debt / m.gdp * 100.0, m.gdp, m.approval()])
	var cap: int = int(m.ate_cap.get(m.ccode, -1))
	check(cap < 0 or m.ate_cc(cap) == m.ccode, tag + ": столица своя")


func _init():
	var cc := "DE"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("country="): cc = a.substr(8)
	var m = load("res://main.gd").new()
	m.game_opts.merge({"ev": 0.0, "news": 0.0, "fedev": 0, "socev": 0, "exev": 0, "milev": 0}, true)
	m.game_opts["seed"] = 11
	m.game_opts["country"] = cc
	root.add_child(m)
	for i in 3: await process_frame
	check(m.ccode == cc, "страна " + cc)
	check(m.mil_on(), "армия создана")
	var n0: int = m.mil_units_of(cc).size()
	print(cc, " соединений ", n0, " тыс. ", snappedf(m.mil_total(cc), 0.1), " бюджет содержит ", snappedf(m.mil_cap(), 0.1))
	check(n0 >= 1 and absf(m.mil_total(cc) - m.mil_cap()) < 1.0, "армия по бюджету")
	for f in m.mil_units_of(cc):
		check(m.ate_cc(int(f["a"])) == cc, "соединение стоит на своей земле")
	# мирное время: набор (поднимаем бюджет армии), мобилизация, приказ
	m.capital = 60.0
	m.pol["army"] = float(m.pol["army"]) * 3.0
	check(m.mil_recruit_check() == "", "набор возможен после роста расходов: " + m.mil_recruit_check())
	check(m.mil_recruit(), "набор начат")
	check(m.mil_mobilize(1), "частичная мобилизация")
	var f0: Dictionary = m.mil_units_of(cc)[0]
	var own: Array = m.mil_cc_ates(cc)
	var tgt: int = int(own[own.size() / 2])
	check(m.mil_order_move(int(f0["id"]), tgt) == "" or int(f0["a"]) == tgt, "приказ на своей территории")
	var t0 := Time.get_ticks_msec()
	play_days(m, 100)
	print("100 мирных дней: ", Time.get_ticks_msec() - t0, " мс")
	check(m.mil_units_of(cc).size() > n0, "новые соединения и резервисты прибыли (%d)" % m.mil_units_of(cc).size())
	check(int(f0["a"]) == tgt or not (f0["path"] as Array).is_empty() or m.mil_unit(int(f0["id"])).is_empty(), "соединение дошло")
	check(m.mil_mobilize(0), "демобилизация")
	consistent(m, "мир")
	# война с соседом
	var tg: Array = m.mil_targets()
	var land: Array = []
	for c in tg:
		if m.mil_land_neighbor(c):
			land.append(c)
	print("цели: ", tg, " по суше: ", land)
	check(not tg.is_empty() or cc == "LU", "есть с кем воевать")
	if tg.is_empty():
		print("t_war: проблем ", bad)
		quit(1 if bad > 0 else 0)
		return
	var foe: String = String(land[0]) if not land.is_empty() else String(tg[0])
	# противник — самый слабый сосед по суше, чтобы была оккупация
	for c in land:
		if m.mil_country_power(c) < m.mil_country_power(foe):
			foe = String(c)
	var ates0 := own_ates(m)
	var r: Dictionary = m.mil_declare(foe, true)
	check(bool(r["done"]) and m.mil_at_war(), "война объявлена: " + String(r["msg"]))
	m.mil_mobilize(2)
	for f in m.mil_units_of(cc):
		m.mil_order_mode(int(f["id"]), "auto")
	t0 = Time.get_ticks_msec()
	var max_occ := 0
	for k in 8:
		play_days(m, 30)
		for f in m.mil_units_of(cc):
			m.mil_order_mode(int(f["id"]), "auto")
		max_occ = maxi(max_occ, m.mil_occupied_by_us(foe).size())
		if not m.mil_at_war():
			break
	var ms := Time.get_ticks_msec() - t0
	print("война с ", foe, ": ", ms, " мс за ≈240 дней; занято АТЕ ", max_occ, "; счёт ", snappedf(float(m.mil["war"].get("score", 0.0)) if m.mil_at_war() else 0.0, 0.1))
	check(ms < 60000, "война считается быстро (%d мс)" % ms)
	if m.mil_at_war():
		var w: Dictionary = m.mil["war"]
		check(is_finite(float(w["score"])), "счёт конечен")
		check(float(w["kia"][0]) + float(w["kia"][1]) > 0.0 or not m.mil_land_neighbor(foe), "бои были")
		check(max_occ > 0 or not m.mil_land_neighbor(foe), "заняты АТЕ противника")
		var occ: Array = m.mil_occupied_by_us(foe)
		var res: Dictionary = m.mil_peace("annex")
		print(res["msg"])
		check(not m.mil_at_war(), "мир заключён")
		if not occ.is_empty():
			check(own_ates(m) > ates0, "АТЕ присоединены: было %d, стало %d" % [ates0, own_ates(m)])
			check(m.ate_cc(int(occ[0])) == cc, "занятая АТЕ стала своей")
	consistent(m, "после победы")
	check(m.mil_declare_check(foe) != "", "перемирие запрещает новую войну")
	play_days(m, 40)
	consistent(m, "месяц после мира")
	# поражение: противник занимает часть земли, мир на его условиях
	var foe2 := ""
	for c in land:
		if c != foe and m.wsim.has(c):
			foe2 = String(c)
	if foe2 == "" and tg.size() > 1:
		for c in tg:
			if c != foe and m.wsim.has(c):
				foe2 = String(c)
	if foe2 != "":
		var ates1 := own_ates(m)
		m.mil_start_war(foe2, [], [], false)
		check(m.mil_at_war() and m.mil_side(foe2) == 1, "нападение ИИ: война идёт")
		# отдаём противнику приграничные АТЕ (не столицу)
		var given := 0
		for a in m.mil_border_spots(cc, [foe2], 6):
			if int(a) != int(m.ate_cap.get(cc, -1)):
				m.mil_set_ctl(int(a), foe2)
				given += 1
		m.mil_score_update()
		var res2: Dictionary = m.mil_peace("lose_cede")
		print(res2["msg"])
		check(not m.mil_at_war(), "мир после поражения")
		if given > 0:
			check(own_ates(m) < ates1, "АТЕ уступлены: было %d, стало %d" % [ates1, own_ates(m)])
		consistent(m, "после поражения")
		play_days(m, 35)
		consistent(m, "месяц после поражения")
	# белый мир после нападения ИИ (по событию)
	var foe3 := ""
	for c in tg:
		if m.wsim.has(c) and int((m.mil["truce"] as Dictionary).get(c, 0)) == 0:
			foe3 = String(c)
	if foe3 != "":
		m.mil_start_war(foe3, [], [], false)
		play_days(m, 20)
		var q: Dictionary = m.mil_peace_quote("white")
		print("белый мир: ", q)
		m.mil_peace("white")
		check(not m.mil_at_war(), "белый мир")
		consistent(m, "после белого мира")
	# полное присоединение: малый сосед со взятой столицей
	var small := ""
	for c in m.wsim:
		if c != cc and m.MIL_BASE.has(c) and int((m.mil["truce"] as Dictionary).get(c, 0)) == 0 and m.mil_land_neighbor(c):
			if small == "" or float(m.WORLD[c]["pop"]) < float(m.WORLD[small]["pop"]):
				small = String(c)
	if small != "" and float(m.WORLD[small]["pop"]) < 12.0:
		m.mil_start_war(small, [], [], true)
		m.mil_set_ctl(int(m.ate_cap[small]), cc)
		m.mil["war"]["score"] = 95.0
		var qf: Dictionary = m.mil_peace_quote("full")
		check(bool(qf["ok"]), "можно присоединить всю страну: " + String(qf["why"]))
		var nreg: int = m.regions.size()
		var rf: Dictionary = m.mil_peace("full")
		print(rf["msg"])
		check(not m.wsim.has(small), "страна %s присоединена" % small)
		check(m.regions.size() > nreg, "регионов стало больше")
		consistent(m, "после присоединения страны")
		play_days(m, 35)
		consistent(m, "месяц после присоединения")
	if m.game_over:
		# серия войн подряд в тесте может уронить рейтинг до отставки — это не ошибка; продолжаем проверять механику
		print("игра окончена: ", m.end_reason, " (тест продолжает)")
		m.game_over = false
	# десант: своя прибрежная АТЕ -> чужое побережье
	m.mil_coast_build()
	if m.flt_has_sea() and not bool(m.flt["land"]):
		var foe4 := ""
		for c in m.wsim:
			if c != cc and m.MIL_BASE.has(c) and int((m.mil["truce"] as Dictionary).get(c, 0)) == 0 and not m.flt_ports_of(String(c)).is_empty():
				foe4 = String(c)
				break
		if foe4 != "":
			m.mil_start_war(foe4, [], [], true)
			var src := -1
			var dst := -1
			for a in m.mil_coast:
				if m.ate_cc(int(a)) == cc and src < 0:
					src = int(a)
				if m.ate_cc(int(a)) == foe4 and m.mil_hostile_units_at(int(a), cc).is_empty() and dst < 0:
					dst = int(a)
			if src >= 0 and dst >= 0:
				m.flt["navy"]["amp"] = maxi(2, int(m.flt["navy"]["amp"]))
				var fl: Dictionary = m.mil_units_of(cc)[0]
				fl["a"] = src
				fl["str"] = minf(float(fl["str"]), m.mil_amp_cap())
				for e in m.mil["war"]["nv"]:
					m.mil["war"]["nv"][e]["pow"] = 0.0
				var why: String = m.mil_land_order(int(fl["id"]), dst)
				check(why == "", "десант: " + why)
				play_days(m, 30)
				check(int(fl["a"]) >= 0, "десант завершён (высадка или эвакуация): game_over %s, sea %s, fight %d" % [m.game_over, fl["sea"], int(fl["fight"])])
				print("десант на ", m.ate_name(dst), ": соединение в ", m.ate_name(int(fl["a"])) if int(fl["a"]) >= 0 else "море")
			m.mil_peace("white")
			consistent(m, "после десанта")
	if m.game_over:
		print("игра окончена: ", m.end_reason, " (тест продолжает)")
		m.game_over = false
	# переброска морем на свой остров (без войны)
	m.mil_coast_build()
	var fz: Dictionary = m.mil_units_of(cc)[0] if m.mil_units_of(cc).size() > 0 else {}
	if not fz.is_empty() and m.mil_coast.has(int(fz["a"])) == false:
		for a in m.mil_coast:
			if m.ate_cc(int(a)) == cc:
				fz["a"] = int(a)
				break
	if not fz.is_empty() and m.mil_coast.has(int(fz["a"])):
		m.mil_bfs(int(fz["a"]), cc)
		var isl := -1
		for a in m.mil_coast:
			if m.ate_cc(int(a)) == cc and not m.mil_reached(int(a)):
				isl = int(a)
				break
		if isl >= 0:
			var why2: String = m.mil_order_move(int(fz["id"]), isl)
			check(why2 == "", "переброска на остров: " + why2)
			play_days(m, 25)
			check(int(fz["a"]) == isl, "соединение доставлено на остров %s (game_over %s, sea %s, a %d)" % [m.ate_name(isl), m.game_over, fz["sea"], int(fz["a"])])
			print("переброска на ", m.ate_name(isl), ": ", int(fz["a"]) == isl)
	# нападение ИИ: плохие отношения и слабая армия
	m.game_opts["milev"] = 1
	var att := ""
	for c in m.mil_targets():
		if m.mil_land_neighbor(c) and int((m.mil["truce"] as Dictionary).get(c, 0)) == 0 and m.wsim.has(c):
			if att == "" or m.mil_country_power(c) > m.mil_country_power(att):
				att = String(c)
	if att != "" and not m.mil_at_war():
		if m.dip.has(att):
			m.dip[att]["rel"] = 0.0
		else:
			m.fst["rel_x"][att] = -45.0
		for f in m.mil_units_of(cc):
			f["str"] = 0.05
		m.turn = maxi(m.turn, 13)
		for k in 800:
			if m.election_open: m.election_continue()
			if not m.current_event.is_empty(): m.choose(0)
			m.mil_ai_declare()
			if m.mil_at_war(): break
		check(m.mil_at_war() and m.mil_side(String(m.mil["war"]["lead"])) == 1 if m.mil_at_war() else false, "ИИ объявил войну (%s): opp %s, rel %.0f, сила %.1f / %.1f, перемирие %s, событие %s, выборы %s, сосед %s, war %s" % [att, m.opp_mode, m.fed_rel(att), m.mil_country_power(att), m.mil_country_power(cc), m.mil["truce"], String(m.current_event.get("t", "")).left(80), m.election_open, m.mil_land_neighbor(att), m.mil_side(att)])
		if m.mil_at_war():
			check(not m.current_event.is_empty() and String(m.current_event.get("special", "")) == "war", "событие о нападении")
			m.choose(1)
			check(int(m.mil["mob"]) == 1, "по выбору объявлена мобилизация")
			play_days(m, 20)
			m.mil_peace("white")
		consistent(m, "после нападения ИИ")
	for i in 3:
		m.next_turn()
	consistent(m, "месячные ходы")
	print("t_war: проблем ", bad)
	quit(1 if bad > 0 else 0)
