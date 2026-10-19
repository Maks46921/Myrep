extends SceneTree
# v55_1: подробные товары и новые сооружения: нулевое влияние на старте, цепочки, уровни, ремонт, мегапроект, стройка корпораций и других стран.
var bad := 0

func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)

func run_months(g, n: int) -> void:
	for i in n:
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty(): g.choose(0)
		g.next_turn()

func mk(o: Dictionary) -> Node:
	var m = load("res://main.gd").new()
	m.game_opts.merge({"agents": false, "k": 0, "seed": 3, "ev": 1.0, "news": 1.0, "econ": 1, "volat": 1.0, "cap": 1.0, "detail": false, "fedev": 0, "socev": 0, "exev": 0, "milev": 0, "revev": 0, "rlev": 0, "bldev": 0}, true)
	m.game_opts.merge(o, true)
	root.add_child(m)
	return m

func drop(g) -> void:
	root.remove_child(g)
	g.free()
	await process_frame

# 0.56: если выборы назначены в первые месяцы (HU, BG), сдвигаем их: тест рассчитан на игру у власти
func hold_parl(g) -> void:
	if g.turn - g.last_parl >= g.parl_term() - 6:
		g.last_parl = g.turn


func _init():
	var g = mk({})
	for i in 5: await process_frame
	hold_parl(g)
	var cc: String = g.ccode
	# список сооружений и товаров
	var nmega := 0
	for pd in g.PROJECTS:
		if bool(pd.get("mega", false)): nmega += 1
	print("[%s] сооружений %d, мегапроект «%s», товаров-ресурсов %d, подробных товаров %d" % [cc, g.PROJECTS.size(), g.con_mega().get("name", "-"), g.gi_ids().size(), g.gx_ids().size()])
	check(g.PROJECTS.size() - nmega >= 60, "сооружений меньше 60")
	check(nmega == 1, "мегапроектов должно быть ровно 1 (%d)" % nmega)
	check(g.con_mega_region() >= 0, "регион мегапроекта не найден")
	check(g.gi_ids().size() + g.gx_ids().size() >= 50, "товаров меньше 50")
	var ids := {}
	for pd in g.PROJECTS:
		check(not ids.has(pd["id"]), "сооружение %s повторяется" % pd["id"])
		ids[pd["id"]] = true
		check(int(pd["cat"]) >= 0 and int(pd["cat"]) < g.STRUCT_CATS.size(), "у %s неверная категория" % pd["id"])
	# на старте новые товары не влияют
	var z: float = absf(g.ind_g()) + absf(g.ind_arms_price() - 1.0)
	for gd in g.GOODS:
		z += absf(g.ind_cat_term(String(gd["id"])))
	for id in g.gi_ids(): z += absf(g.ind_dprem(String(id)))
	check(z < 1e-9, "на старте товары влияют (%.6f)" % z)
	var ex: Array = g.ind_exports()
	var parts := PackedStringArray()
	for k in mini(4, ex.size()): parts.append(String(ex[k][1]))
	print("  экспорт: %s; импорт: %d позиций" % [", ".join(parts), g.ind_imports().size()])
	# статика: цены подробных товаров не уходят
	run_months(g, 12)
	# в статике подробные цены лишь колеблются вокруг цены своей категории (в среднем по категории — ноль), на экономику не влияют
	var z2: float = absf(g.ind_g())
	for gd in g.GOODS:
		z2 += absf(g.ind_cat_term(String(gd["id"])))
		var avg := 0.0
		for x in g.gx_of_cat(String(gd["id"])): avg += float(g.ind["w"][x]) * float(g.ind["x"][x]["d"])
		z2 += absf(avg) if absf(avg) > 1e-3 else 0.0
	check(z2 < 1e-6, "в статике подробные товары влияют на экономику (%.6f)" % z2)
	# цепочка: металлургический комбинат поднимает самообеспеченность сталью
	g.capital = 500.0
	var ri := 0
	for i in g.regions.size():
		if g.bq_in_region(i).is_empty(): ri = i; break
	var ss0: float = g.ind_ss("steel")
	var g0: float = g.ind_g()
	check(g.project_start_at(ri, "steelworks") == "", "комбинат не заложен")
	g.complete_project(ri)
	check(g.con_lvl(ri, "steelworks") >= 1, "комбинат не построен")
	print("  комбинат: сталь %.2f → %.2f, рост %s" % [ss0, g.ind_ss("steel"), g.sg(g.ind_g() - g0, 3)])
	check(g.ind_ss("steel") > ss0 + 0.01, "комбинат не поднял выпуск стали")
	check(g.ind_g() > g0, "комбинат не ускорил рост")
	# улучшение до 2-го уровня
	var lv0: int = g.con_lvl(ri, "steelworks")
	var ss1: float = g.ind_ss("steel")
	check(g.con_upgrade_check(ri, "steelworks") == "", "улучшение недоступно: %s" % g.con_upgrade_check(ri, "steelworks"))
	check(g.con_upgrade_start(ri, "steelworks") == "", "улучшение не начато")
	check(bool(g.bq_in_region(ri).get("upg", false)), "стройка улучшения не помечена")
	g.complete_project(ri)
	check(g.con_lvl(ri, "steelworks") == lv0 + 1, "уровень не вырос")
	check(g.ind_ss("steel") > ss1, "улучшение не подняло выпуск")
	ss1 = g.ind_ss("steel")
	# износ и ремонт
	g.regions[ri]["built"]["steelworks"]["cond"] = 40.0
	g.struct_step(false)
	var ss2: float = g.ind_ss("steel")
	check(ss2 < ss1, "износ не снизил выпуск")
	var d0: float = g.debt
	check(g.con_repair_cost(ri, "steelworks") > 0.0, "ремонт ничего не стоит")
	check(g.con_repair(ri, "steelworks"), "ремонт не сработал")
	check(float(g.regions[ri]["built"]["steelworks"]["cond"]) >= 99.9 and g.debt > d0, "ремонт не восстановил состояние")
	check(g.ind_ss("steel") > ss2, "после ремонта выпуск не вырос")
	# мегапроект: только в своём регионе
	var mr: int = g.con_mega_region()
	var mid: String = String(g.con_mega().get("id", ""))
	if mr >= 0:
		var other := 0 if mr != 0 else 1
		if other < g.regions.size():
			g.regions[other]["proj"] = {}
			check(g.project_start_at(other, mid) != "", "мегапроект заложен не в своём регионе")
		g.regions[mr]["proj"] = {}
		check(g.project_start_at(mr, mid) == "", "мегапроект не заложен в своём регионе")
		g.complete_project(mr)
		check(int(g.cs["mega"]) == 2, "мегапроект не завершён")
		check(g.con_upgrade_check(mr, mid) != "", "мегапроект нельзя улучшать")
		g.regions[mr]["proj"] = {}
		check(g.project_start_at(mr, mid) != "", "мегапроект заложен второй раз")
	# новые сооружения: каждое строится, ни одного NaN
	var n_ok := 0
	for pd in g.PROJECTS:
		if bool(pd.get("mega", false)): continue
		var i: int = n_ok % g.regions.size()
		g.regions[i]["proj"] = {}
		if g.project_start_at(i, String(pd["id"])) == "":
			g.complete_project(i)
			n_ok += 1
	check(n_ok >= 60, "построено только %d сооружений" % n_ok)
	run_months(g, 2)
	check(not is_nan(g.gdp) and not is_nan(g.debt) and not is_nan(g.ind_g()), "NaN после стройки всех сооружений")
	print("  построены все %d, рост от стройки %s, армия: ПВО ×%.2f, мощности ×%.2f" % [n_ok, g.sg(g.ind_g(), 2), 1.0 + g.con_mil("ad"), 1.0 + g.con_mil("cap")])
	# события товаров: все виды и варианты
	for kind in ["chips", "dumping", "fert", "harvest", "tobacco", "arms", "export"]:
		for o in 3:
			g.current_event = {}
			g.election_open = false
			g.ind_events(kind)
			if g.current_event.is_empty(): continue
			g.choose(mini(o, (g.current_event["o"] as Array).size() - 1))
	run_months(g, 3)
	check(not is_nan(g.ind_g()), "NaN после событий товаров")
	# авария на изношенном сооружении
	g.regions[ri]["built"]["steelworks"]["cond"] = 3.0
	g.current_event = {}
	var got := false
	g.election_open = false
	if not g.regions[ri]["built"].has("steelworks"): g.complete_struct(ri, "steelworks")
	g.regions[ri]["built"]["steelworks"]["cond"] = 3.0
	for k in 600:
		g.con_accidents()
		if not g.current_event.is_empty():
			got = true
			break
	check(got, "авария не случилась")
	if got:
		g.choose(0)
		check(float(g.regions[ri]["built"]["steelworks"]["cond"]) >= 99.9, "срочный ремонт не сработал")
	# сохранение
	var snap: PackedByteArray = g.sv_pack()
	var lv: int = g.con_lvl(ri, "steelworks")
	g.regions[ri]["built"]["steelworks"]["lvl"] = 1
	check(g.sv_apply(snap), "загрузка не удалась")
	check(g.con_lvl(ri, "steelworks") == lv, "уровень сооружения не сохранился")
	await drop(g)

	# живая стройка: корпорации и другие страны
	g = mk({"bldev": 1, "exev": 1, "seed": 5})
	for i in 5: await process_frame
	hold_parl(g)
	var pre: int = g.struct_total_count()
	if not g.corp.is_empty() and not (g.corp["list"] as Array).is_empty():
		var c0: Dictionary = g.corp["list"][0]
		g.cs["cq"].append({"id": "factory", "i": 0, "left": 1, "corp": g.corp_name(c0)})
	run_months(g, 36)
	var ain := 0
	var amega := 0
	for c in g.cs["ai"]:
		ain += int(g.cs["ai"][c]["n"])
		if int(g.cs["ai"][c]["mega"]) > 0: amega += 1
	if g.game_over or g.opp_mode: print("  (игра: месяц %d, конец игры %s, оппозиция %s)" % [g.turn, g.game_over, g.opp_mode])
	print("  36 мес. живой стройки: сооружений %d → %d, в очереди корпораций %d, другие страны построили %d, мегапроектов начато %d, рост у соседа %s" % [
		pre, g.struct_total_count(), (g.cs["cq"] as Array).size(), ain, amega, g.sg(g.con_ai_g(String(g.cs["ai"].keys()[0])) if not (g.cs["ai"] as Dictionary).is_empty() else 0.0, 3)])
	if g.turn >= 30:
		check(ain > 10, "другие страны почти не строят")
	if not g.corp.is_empty():
		check(g.struct_total_count() > pre, "стройка корпорации не завершилась")
	check(not is_nan(g.gdp), "NaN в живой стройке")
	await drop(g)
	print("проблем %d" % bad)
	quit()
