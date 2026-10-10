extends SceneTree
# Вооружённые силы (v48_1): рода войск, оборонный бюджет, комплектование и резерв, закупки, учения, миссии, экспорт,
# война (боеприпасы, боевой дух, авиация), гонка вооружений, сохранение.
var bad := 0

func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)

func mk(o: Dictionary) -> Node:
	var m = load("res://main.gd").new()
	m.game_opts.merge({"agents": false, "seed": 13, "ev": 0.0, "news": 0.0, "milev": 0, "revev": 0, "rlev": 1, "exev": 1}, true)
	m.game_opts.merge(o, true)
	root.add_child(m)
	return m

func months(g, n: int) -> void:
	for i in n:
		if g.game_over: return
		if g.election_open: g.election_continue()
		var k := 0
		while not g.current_event.is_empty() and k < 8:
			g.choose(0)
			k += 1
		g.next_turn()

func drop(g) -> void:
	root.remove_child(g)
	g.free()

func finite(v: float) -> bool:
	return not is_nan(v) and not is_inf(v)

func _init():
	var g = mk({})
	for i in 4: await process_frame
	var cc: String = g.ccode
	check(g.ar_on(), "модуль армии не включён")
	check(g.AR_DATA.has(cc), "нет данных армии для страны")
	# --- рода войск и исходное состояние ---
	var types := {}
	for f in g.mil_units_of(cc):
		types[String(f.get("tp", ""))] = true
		check(String(f.get("tp", "")) in g.AR_TYPES, "неизвестный род войск: %s" % String(f.get("tp", "")))
	check(absf(g.ar_cap_mult() - 1.0) < 0.001, "на старте бюджет должен содержать прежнюю армию: %.3f" % g.ar_cap_mult())
	check(absf(g.ar_q_mult() - 1.0) < 0.01, "на старте выучка не должна меняться: %.3f" % g.ar_q_mult())
	check(absf(g.ar_mob_speed() - 1.0) < 0.01, "на старте мобилизация в прежние сроки")
	if g.mil_units_of(cc).size() >= 5:
		check(types.size() >= 2, "у армии из 5+ соединений должно быть больше одного рода войск: %s" % str(types.keys()))
	# --- структура бюджета ---
	var eq0: float = float(g.ar["eq"])
	check(g.ar_shift_bs("eq", 0.10) == "", "доля на технику не меняется")
	var s := 0.0
	for k in g.AR_BS_KEYS: s += g.ar_bs(k)
	check(absf(s - 1.0) < 0.001, "доли бюджета в сумме не 100%%: %.3f" % s)
	check(g.ar_bs("eq") > 0.34, "доля на технику не выросла")
	check(g.ar_shift_bs("pers", -0.5) == "" and g.ar_bs("pers") >= 0.299, "нижний предел доли на личный состав")
	g.ar_shift_bs("pers", 0.2)
	months(g, 6)
	check(float(g.ar["eq"]) > eq0, "оснащение должно расти при большей доле на технику: %.3f → %.3f" % [eq0, float(g.ar["eq"])])
	# --- готовность и учения ---
	g.capital = 100.0
	var rd0: float = g.ar_rd()
	check(g.ar_exercise("plan"), "плановые учения: " + g.ar_ex_check("plan"))
	check(g.ar_rd() > rd0 + 4.0, "учения должны поднять готовность")
	check(g.ar_ex_check("plan") != "", "повторные учения сразу — нельзя")
	var tg: Array = g.mil_targets()
	if not tg.is_empty():
		g.ar["cd"].erase("ex")
		check(g.ar_exercise("border", String(tg[0])), "учения у границы: " + g.ar_ex_check("border", String(tg[0])))
		check(g.ar_deterred(String(tg[0])), "после учений у границы сосед должен быть сдержан")
	# --- территориальная оборона ---
	var n0: int = g.mil_units_of(cc).size()
	check(g.ar_td_form(), "бригада ТО: " + g.ar_td_check())
	var has_td := false
	for f in g.mil_units_of(cc):
		if String(f["tp"]) == "td": has_td = true
	check(has_td and g.mil_units_of(cc).size() == n0 + 1, "бригада ТО не появилась")
	# --- закупки: хотя бы пополнение складов доступно всем ---
	g.capital = 100.0
	var am0: float = float(g.ar["ammo"])
	check(g.ar_prog_check("stock") == "", "пополнение складов недоступно: " + g.ar_prog_check("stock"))
	check(g.ar_prog_start("stock"), "пополнение складов не запущено")
	for p in g.AR_PROG:
		var why: String = g.ar_prog_check(String(p["id"]))
		check(why == "" or why == "Эта программа уже идёт." or why.length() > 5, "программа %s без причины отказа" % String(p["id"]))
	var cheap := ""
	for id in ["sam_s", "ifv", "arty", "mlrs"]:
		if g.ar_prog_check(id) == "":
			cheap = id
			break
	var ad0: float = float(g.ar["ad"])
	var eqa0: float = float(g.ar["eq_add"])
	if cheap != "":
		check(g.ar_prog_start(cheap), "программа %s не запущена" % cheap)
	months(g, 20)
	check(float(g.ar["ammo"]) > am0 + 0.3 or float(g.ar["ammo"]) > 1.0, "склады не пополнились: %.2f → %.2f" % [am0, float(g.ar["ammo"])])
	if cheap == "sam_s":
		check(float(g.ar["ad"]) > ad0 + 3.0, "ПВО не поставлена")
	elif cheap != "":
		check(int(g.ar["done"].get(cheap, 0)) == 1, "программа %s не завершилась" % cheap)
	check(g.ar_prog_cost("stock") > 0.0 and g.ar_prog_cost("sam_l") > 0.0, "программы должны стоить денег")
	check(int(g.ar["done"].get("stock", 0)) == 1, "пополнение складов не завершилось")
	# в оппозиции армией командует правительство — дальше проверяем только сохранение
	var opp: bool = g.opp_mode
	if opp:
		print("(игрок в оппозиции — действия армии пропущены)")
	# --- миссия ---
	g.capital = 100.0
	if not opp and g.ar_mis_check("un") == "":
		var cap0: float = g.mil_cap()
		check(g.ar_mis_toggle("un"), "миссия ООН")
		check(g.mil_cap() < cap0, "войска в миссии уменьшают армию дома")
		months(g, 6)
		check(float(g.ar["xp"]) > 0.0, "миссия должна давать опыт")
		check(g.ar_mis_toggle("un") and String(g.ar["mis"]) == "", "возврат контингента")
	# --- экспорт ---
	g.capital = 100.0
	if not opp:
		var gb_e: float = float(g.mods.get("gb_Экологи", 0.0))
		check(g.ar_set_exp(2), "активный экспорт: " + g.ar_exp_check(2))
		check(float(g.mods.get("gb_Экологи", 0.0)) < gb_e, "активный экспорт должен огорчить экологов")
		check(g.ar_exp_rev() >= 0.0, "доход от экспорта")
	else:
		check(g.ar_exp_check(2) != "", "в оппозиции экспорт менять нельзя")
	# --- комплектование ---
	g.capital = 100.0
	var why2: String = g.ar_svc_check("con" if String(g.ar["svc"]) != "con" else "pro")
	if why2 == "" and not opp:
		var m2: String = "con" if String(g.ar["svc"]) != "con" else "pro"
		var r0: float = g.ar_rsv()
		var gy: float = float(g.mods.get("gb_Молодёжь", 0.0))
		check(g.ar_set_svc(m2), "смена модели комплектования")
		months(g, 12)
		if m2 == "con":
			check(g.ar_rsv() > r0, "при призыве резерв растёт: %.1f → %.1f" % [r0, g.ar_rsv()])
			check(float(g.mods.get("gb_Молодёжь", 0.0)) < gy, "призыв недоволит молодёжь")
		else:
			check(g.ar_rsv() < r0, "без призыва резерв уменьшается")
	else:
		check(why2.length() > 5, "нет причины отказа в смене модели")
	check(finite(g.gdp) and finite(g.debt) and finite(float(g.ar["eq"])) and finite(float(g.ar["ammo"])), "NaN в мирное время")
	# --- сохранение ---
	var svc_s: String = String(g.ar["svc"])
	var tps: Array = []
	for f in g.mil_units_of(cc): tps.append(String(f["tp"]))
	var bytes: PackedByteArray = g.sv_pack()
	g.ar["svc"] = "mix" if svc_s != "mix" else "pro"
	check(g.sv_apply(bytes), "загрузка")
	check(String(g.ar["svc"]) == svc_s, "модель комплектования не сохранилась")
	var tps2: Array = []
	for f in g.mil_units_of(cc): tps2.append(String(f["tp"]))
	check(tps == tps2, "рода войск не сохранились")
	drop(g)
	# --- война ---
	var g2 = mk({})
	for i in 4: await process_frame
	var tg2: Array = g2.mil_targets()
	if not tg2.is_empty():
		var foe := String(tg2[0])
		g2.capital = 100.0
		var am1: float = float(g2.ar["ammo"])
		var res: Dictionary = g2.mil_declare(foe, true)
		check(bool(res.get("done", false)), "объявление войны")
		check(g2.mil["war"].has("mor") and g2.mil["war"].has("ammo_e"), "нет боевого духа или боеприпасов противника")
		var et := {}
		for f in g2.mil["units"]:
			if String(f["cc"]) != cc: et[String(f["tp"])] = true
		check(not et.is_empty(), "у противника нет соединений с родами войск")
		var am_ = g2.ar_air_mult(0)
		check(am_ >= 0.879 and am_ <= 1.121, "господство в воздухе вне пределов: %.3f" % am_)
		for f in g2.mil_units_of(cc): g2.mil_order_mode(int(f["id"]), "auto")
		for d in 60:
			if g2.election_open: g2.election_continue()
			var kk := 0
			while not g2.current_event.is_empty() and kk < 5:
				g2.choose(0)
				kk += 1
			g2.advance_day()
			if not g2.mil_at_war(): break
		if g2.mil_at_war():
			var fought: bool = int(g2.mil["war"]["won"]) + int(g2.mil["war"]["lost"]) > 0
			if fought:
				check(float(g2.ar["ammo"]) < am1 + 0.2, "в боях боеприпасы должны тратиться: %.2f → %.2f" % [am1, float(g2.ar["ammo"])])
			var mo: float = g2.ar_mor(0)
			check(mo >= 10.0 and mo <= 95.0, "боевой дух вне пределов")
			g2.capital = 100.0
			check(g2.ar_buy_ammo() or g2.ar_buy_check() != "", "закупка боеприпасов без причины отказа")
			check(g2.ar_wecon_toggle(), "военная экономика: " + g2.ar_wecon_check())
			check(g2.mil_g() <= 0.0 and g2.mil_infl() >= 0.6, "военная экономика должна тормозить рост и разгонять цены")
			g2.mil_peace("white")
			months(g2, 1)
			check(not bool(g2.ar["wecon"]), "после мира промышленность возвращается к мирной продукции")
		check(finite(g2.gdp) and finite(g2.debt) and finite(float(g2.ar["ammo"])), "NaN на войне")
	drop(g2)
	# --- гонка вооружений: соседи реагируют на резкое усиление ---
	var g3 = mk({})
	for i in 4: await process_frame
	g3.set_policy("army", float(g3.pol["army"]) * 2.2)
	g3.capital = 200.0
	for k3 in 6:
		g3.mil_recruit()
		months(g3, 4)
	var mx := 0.0
	for c in g3.ar["wm"]:
		mx = maxf(mx, float(g3.ar["wm"][c]))
		check(float(g3.ar["wm"][c]) >= 0.99 and float(g3.ar["wm"][c]) <= 1.7, "множитель армии соседа вне пределов: %s %.2f" % [c, float(g3.ar["wm"][c])])
	check(mx > 1.01, "за два года соседи (НАТО или угроза) должны нарастить армии: %.3f" % mx)
	drop(g3)
	print("army ", cc, " проблем ", bad)
	quit(1 if bad > 0 else 0)
