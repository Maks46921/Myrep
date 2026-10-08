extends SceneTree
# v36: АТЕ и административные реформы: данные, передача АТЕ, создание и упразднение региона, покупка АТЕ, карта, сброс.
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

func pop_sum(g) -> float:
	var s := 0.0
	for r in g.regions: s += float(r["popm"])
	return s

func ready(g) -> void:
	g.capital = 500.0
	g.in_coalition.fill(true)
	g.fst["cd"].erase("adm")
	g.fst["terr_cd"].clear()

func arrays_ok(g, tag: String) -> void:
	var n: int = g.regions.size()
	check(g.REGIONS.size() == n and g.reg_cd.size() == n and g.reg_mix.size() == n and g.loy_off.size() == n and g.unr_off.size() == n, "%s: массивы регионов разной длины" % tag)
	check(g.neighbors.size() == n and g.region_polys.size() == n and g.pop_w.size() == n, "%s: геометрия не пересобрана" % tag)
	for i in n:
		var ui: int = g.adm_region_ui(i)
		check(ui >= 0 and (g.ate_lists[ui] as PackedInt32Array).size() > 0, "%s: у региона %d нет АТЕ" % [tag, i])
		check(float(g.regions[i]["popm"]) > 0.0 and float(g.REGIONS[i]["pc"]) > 0.0 and not is_nan(float(g.REGIONS[i]["pc"])), "%s: регион %d без населения/экономики" % [tag, i])
		for j in g.neighbors[i]:
			check(int(j) >= 0 and int(j) < n and int(j) != i, "%s: плохой сосед %d у региона %d" % [tag, int(j), i])
	var cnt := 0
	for l in g.ate_lists: cnt += (l as PackedInt32Array).size()
	check(cnt == g.ate_n, "%s: списки АТЕ не покрывают все АТЕ" % tag)

func border_ate(g, i: int, cap_ok: bool) -> Array:
	# АТЕ региона i на границе с другим своим регионом: [a, сосед-регион]
	var ui: int = g.adm_region_ui(i)
	for a in g.ate_lists[ui]:
		if not cap_ok and g.ate_cap.has(g.ccode) and int(g.ate_cap[g.ccode]) == a: continue
		for b in g.ate_nbs(a):
			if g.ate_unit[b] != ui and g.ate_cc(b) == g.ccode:
				return [a, g.ate_region(b)]
	return []

func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	var cc: String = g.ccode
	var n0: int = g.regions.size()
	# 1. данные
	check(g.ate_n > 6000, "АТЕ не загружены (%d)" % g.ate_n)
	var mine := 0
	var km := 0.0
	for a in g.ate_n:
		if g.ate_cc(a) == cc:
			mine += 1
			km += g.ate_km[a]
	print("[%s] регионов %d, АТЕ %d, площадь %.0f км², в среднем %.0f км²" % [cc, n0, mine, km, km / maxf(1.0, mine)])
	check(mine >= n0, "АТЕ меньше, чем регионов")
	check(g.ate_cap.has(cc) and int(g.ate_cap[cc]) >= 0 and g.ate_cc(int(g.ate_cap[cc])) == cc, "столица не найдена среди АТЕ")
	var pw_bad := 0
	for ui in g.wu_n0:
		var s := 0.0
		for a in g.ate_lists[ui]: s += g.ate_pw[a]
		if absf(s - 1.0) > 0.001: pw_bad += 1
	check(pw_bad == 0, "доли населения АТЕ не дают 1 у %d регионов" % pw_bad)
	arrays_ok(g, "старт")
	var tot := 0.0
	for a in g.adm_region_ates(0): tot += g.ate_pop(a)
	check(absf(tot - float(g.regions[0]["popm"])) < 0.001, "население АТЕ не сходится с регионом")
	# 2. передача АТЕ соседнему региону
	ready(g)
	var p0 := pop_sum(g)
	var pot0: float = g.regional_potential()
	var gdp0: float = g.gdp
	var ba: Array = []
	for i in n0:
		if (g.adm_region_ates(i) as PackedInt32Array).size() >= 2:
			ba = border_ate(g, i, false)
			if not ba.is_empty(): break
	if n0 >= 2:
		check(not ba.is_empty(), "не найдена пограничная АТЕ между регионами")
	if not ba.is_empty():
		var a: int = ba[0]
		var dst: int = ba[1]
		var src: int = g.ate_region(a)
		var ps: float = float(g.regions[src]["popm"])
		var cap0: float = g.capital
		var r: Dictionary = g.adm_move([a], dst)
		check(bool(r["done"]), "передача АТЕ не прошла: %s" % r["msg"])
		check(g.ate_region(a) == dst, "АТЕ не перешла")
		check(absf(pop_sum(g) - p0) < 1e-6, "население страны изменилось при передаче (%.6f)" % (pop_sum(g) - p0))
		check(absf(g.regional_potential() / pot0 - 1.0) < 1e-6, "потенциал ВВП изменился при передаче")
		check(absf(g.gdp - gdp0) < 1e-6, "ВВП изменился при передаче")
		check(float(g.regions[src]["popm"]) < ps, "население региона-источника не уменьшилось")
		check(g.capital < cap0, "реформа бесплатна")
		check(int(g.regions[dst].get("adm", 0)) > 0, "нет «притирки» после реформы")
		check(g.fed_cd_get("adm") > 0, "нет паузы между реформами")
		check(g.adm_move_check([a], src) != "", "вторая реформа сразу же разрешена")
		arrays_ok(g, "передача")
		# обратно и нельзя оставить регион без АТЕ
		ready(g)
		var all_src: Array = Array(g.adm_region_ates(src))
		check(g.adm_move_check(all_src, dst) != "", "можно передать все АТЕ региона")
	# 3. новый регион из 3 соседних АТЕ
	ready(g)
	var big := -1
	for i in g.regions.size():
		if (g.adm_region_ates(i) as PackedInt32Array).size() >= 6:
			big = i
			break
	if big >= 0:
		var lst: PackedInt32Array = g.adm_region_ates(big)
		var sel: Array = [lst[0]]
		var k := 0
		while sel.size() < 3 and k < sel.size():
			for b in g.ate_nbs(int(sel[k])):
				if g.ate_unit[b] == g.ate_unit[lst[0]] and not (b in sel) and sel.size() < 3:
					sel.append(b)
			k += 1
		p0 = pop_sum(g)
		pot0 = g.regional_potential()
		var nb_before: int = g.regions.size()
		var r2: Dictionary = g.adm_create(sel, "Тестовый край")
		check(bool(r2["done"]), "новый регион не создан: %s" % r2["msg"])
		if bool(r2["done"]):
			var ni: int = r2["idx"]
			check(g.regions.size() == nb_before + 1, "число регионов не выросло")
			check(String(g.REGIONS[ni]["name"]) == "Тестовый край", "имя нового региона")
			check(absf(pop_sum(g) - p0) < 1e-6, "население изменилось при создании региона")
			check(absf(g.regional_potential() / pot0 - 1.0) < 1e-6, "потенциал ВВП изменился при создании региона")
			check(g.adm_region_ates(ni).size() == sel.size(), "в новом регионе не те АТЕ")
			check(g.adm_admin_mult() > 1.0, "лишний регион не удорожает госаппарат")
			arrays_ok(g, "создание")
			# 4. упразднение нового региона
			ready(g)
			var nbs: Array = g.adm_region_nbs(ni)
			if nbs.is_empty():
				print("[%s] новый регион — остров без соседей, упразднение не проверяется" % cc)
			else:
				var r3: Dictionary = g.adm_delete(ni, int(nbs[0]))
				check(bool(r3["done"]), "регион не упразднён: %s" % r3["msg"])
				check(g.regions.size() == nb_before, "число регионов не вернулось")
				check(absf(pop_sum(g) - p0) < 1e-6, "население изменилось при упразднении")
				check(absf(g.regional_potential() / pot0 - 1.0) < 1e-6, "потенциал ВВП изменился при упразднении")
				arrays_ok(g, "упразднение")
	# 5. покупка АТЕ у соседа: к своему региону и отдельной территорией
	for mode in [0, 1]:
		ready(g)
		var cand := -1
		var cand_dst := -1
		for a in g.ate_n:
			var c2: String = g.ate_cc(a)
			if c2 == cc or not g.WORLD.has(c2) or not g.wsim.has(c2) or int(g.FED.get(c2, {}).get("cede", 2)) == 0: continue
			if g.ate_cap.has(c2) and int(g.ate_cap[c2]) == a: continue
			if (g.ate_lists[g.ate_unit[a]] as PackedInt32Array).size() < 2: continue
			for b in g.ate_nbs(a):
				if g.ate_cc(b) == cc:
					cand = a
					cand_dst = g.ate_region(b)
					break
			if cand >= 0: break
		if cand < 0:
			print("[%s] нет соседних АТЕ для покупки — проверка покупки пропущена" % cc)
			break
		var c3: String = g.ate_cc(cand)
		var uid: String = String(g.WORLD_UNITS[g.ate_unit[cand]]["id"])
		var wp0: float = float(g.fed_wreg(c3, uid)["popm"])
		var wg0: float = float(g.wsim[c3]["gdp"])
		p0 = pop_sum(g)
		gdp0 = g.gdp
		var debt0: float = g.debt
		var nreg: int = g.regions.size()
		var dsti: int = cand_dst if mode == 0 else -1
		var q: Dictionary = g.ate_buy_quote([cand], 1.0, dsti)
		if not bool(q["ok"]):
			print("[%s] покупка у %s невозможна: %s" % [cc, c3, "; ".join(PackedStringArray(q["why"]))])
			continue
		check(float(q["price"]) > 0.0 and float(q["pop"]) > 0.0, "пустая цена или население")
		var r4: Dictionary = g.ate_buy([cand], 1.0, dsti, 1)
		check(bool(r4["done"]), "покупка АТЕ не прошла: %s" % r4["msg"])
		if not bool(r4["done"]): continue
		check(g.ate_cc(cand) == cc, "АТЕ не стала нашей")
		check(absf(pop_sum(g) - p0 - float(q["pop"])) < 1e-4, "население выросло не на население АТЕ")
		check(g.gdp > gdp0 and absf(g.gdp - gdp0 - float(q["gdp_r"])) < 1e-3, "ВВП не вырос на ВВП АТЕ")
		check(absf(g.debt - debt0 - float(q["price"])) < 1e-3, "цена не ушла в долг")
		check(float(g.fed_wreg(c3, uid)["popm"]) < wp0, "у продавца не уменьшилось население региона")
		check(float(g.wsim[c3]["gdp"]) < wg0, "у продавца не уменьшился ВВП")
		check(g.regions.size() == nreg + mode, "число регионов после покупки")
		print("[%s] куплена АТЕ у %s (%s): %.3f млн жителей за %.1f млрд%s" % [cc, c3, uid, float(q["pop"]), float(q["price"]), " — новой территорией" if mode == 1 else ""])
		arrays_ok(g, "покупка")
	# 6. игра идёт дальше
	run_months(g, 26)
	var nan := 0
	for r in g.regions:
		for k in ["popm", "loy", "unrest", "dev"]:
			if is_nan(float(r[k])): nan += 1
	check(nan == 0 and not is_nan(g.gdp) and g.gdp > 0.0, "NaN после реформ")
	var shock := 0
	for r in g.regions: shock += int(r.get("adm", 0))
	check(shock == 0, "«притирка» не закончилась за 2 года")
	# 7. карта
	g.show_desk(2)
	for i in 3: await process_frame
	check(g.map_unit_rect.size() == g.WORLD_UNITS.size() and g.map_unit_mesh.size() == g.WORLD_UNITS.size(), "карта не пересобрана")
	check(g.map_ln_ate.size() > 1000 and g.map_ln_reg.size() > 0 and g.map_ln_cty.size() > 1000, "линии карты пусты")
	var v: Array = g.map_view()
	var hit := 0
	var tried := 0
	for i in g.regions.size():
		var a: int = (g.adm_region_ates(i) as PackedInt32Array)[0]
		var px: Vector2 = g.ate_c[a] * float(v[0]) + (v[1] as Vector2)
		tried += 1
		if g.ate_at(px) == a: hit += 1
	check(hit == tried, "ate_at попадает не во все АТЕ (%d из %d)" % [hit, tried])
	g.adm_open()
	for i in 2: await process_frame
	check(g.ate_mode and not (g.wins["adm"] as Control).visible == false, "окно реформы не открылось")
	var a0: int = (g.adm_region_ates(0) as PackedInt32Array)[0]
	g.ate_click(a0, false)
	check(a0 in g.ate_sel, "щелчок не выделил АТЕ")
	g.ate_sel.clear()
	g.ate_click(a0, true)
	check(g.ate_sel.size() == (g.adm_region_ates(0) as PackedInt32Array).size(), "Shift-щелчок не выделил регион")
	check(g.ate_tip(a0).contains("км²"), "подсказка АТЕ")
	g.ate_click(a0, true)
	check(g.ate_sel.is_empty(), "повторный Shift-щелчок не снял выделение")
	# 8. сброс к исходному миру
	g.fed_reset_world()
	check(g.WORLD_UNITS.size() == g.wu_n0, "новые единицы карты не удалены при сбросе")
	check(g.ate_unit == g.ate_unit0, "принадлежность АТЕ не сброшена")
	print("bad %d" % bad)
	quit()
