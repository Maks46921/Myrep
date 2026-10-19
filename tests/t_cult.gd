extends SceneTree
# v55_1: народы (культуры) и церковь: состав регионов, нулевое влияние на старте, политика, ассимиляция, события, сохранение.
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
	m.game_opts.merge({"agents": false, "k": 0, "seed": 3, "ev": 1.0, "news": 1.0, "econ": 1, "volat": 1.0, "cap": 1.0, "detail": false, "fedev": 0, "socev": 0, "exev": 0, "milev": 0, "revev": 1, "rlev": 1, "bldev": 0}, true)
	m.game_opts.merge(o, true)
	root.add_child(m)
	return m

func drop(g) -> void:
	root.remove_child(g)
	g.free()
	await process_frame

func shares_ok(g) -> bool:
	for r in g.regions:
		if not r.has("cul"): return false
		var s := 0.0
		for k in r["cul"]:
			var v: float = float(r["cul"][k])
			if v < -1e-9 or is_nan(v): return false
			s += v
		if absf(s - 1.0) > 1e-3: return false
	return true

func zero_terms(g) -> float:
	var m := 0.0
	for i in g.regions.size():
		m = maxf(m, absf(g.cult_loy_term(i)) + absf(g.cult_unr_term(i)) + absf(g.cult_sep_term(i)) + absf(g.church_loy_term(i)) + absf(g.church_unr_term(i)))
		for p in g.PARTY_NAMES.size():
			m = maxf(m, absf(g.cult_vote_mult(i, p) - 1.0) + absf(g.church_vote_mult(i, p) - 1.0))
	return m + absf(g.cult_g())

func fire_all(g) -> void:
	var worst := 0
	for i in g.regions.size():
		if float(g.regions[i]["cut"]) > float(g.regions[worst]["cut"]): worst = i
	var minor: String = g.cu_region_minority(worst)
	var kinl: Array = g.cu_kin_list()
	var kinds := ["festival", "mixed", "census"]
	if minor != "": kinds += ["lang", "monument", "school", "march", "sport", "autonomy"]
	if not kinl.is_empty(): kinds += ["kin"]
	for kind in kinds:
		for o in 3:
			g.current_event = {}
			g.election_open = false
			g.cu_fire(kind, worst, minor, kinl)
			if g.current_event.is_empty(): continue
			if o < (g.current_event["o"] as Array).size(): g.choose(o)
			else: g.choose(0)
	if g.ch_on():
		var ck := ["scandal", "property", "school", "pilgrim", "charity", "revival", "protest"]
		if not (g.ch["riv"] as Dictionary).is_empty(): ck.append("schism")
		for kind in ck:
			g.current_event = {}
			g.ch_fire(kind)
			if not g.current_event.is_empty(): g.choose(1 if (g.current_event["o"] as Array).size() > 1 else 0)
		for it in g.ch_laws():
			if int(it[1]) != g.cur_idx(String(it[0])):
				g.current_event = {}
				g.ch_fire_demand(it)
				if not g.current_event.is_empty(): g.choose(0)
				break
		for f in 6:
			g.current_event = {}
			g.ch_fire_minority_holiday(f, "праздник", 0.05)
			if not g.current_event.is_empty(): g.choose(0)
		g.current_event = {}
		g.ch_fire_holiday(int(g.ch["faith"]), "праздник")
		if not g.current_event.is_empty(): g.choose(0)
		g.current_event = {}
		g.ch_fire_temple(3)
		if not g.current_event.is_empty(): g.choose(2)

func _init():
	var g = mk({})
	for i in 5: await process_frame
	var cc: String = g.ccode
	check(g.cu_on(), "культуры не загружены")
	check(shares_ok(g), "доли народов в регионах должны давать 1")
	var nat: Dictionary = g.cu_national()
	var top: Array = g.cu_sorted(nat)
	var parts := PackedStringArray()
	for k in mini(5, top.size()): parts.append("%s %.1f%%" % [g.cu_name(String(top[k][0])), float(top[k][1]) * 100.0])
	print("[%s] народы: %s; меньшинства %.1f%%, напряжённость %.1f" % [cc, ", ".join(parts), (1.0 - g.cu_tit_share()) * 100.0, float(g.cu["tension"])])
	check(g.cu_tit_share() > 0.3, "государствообразующих народов меньше 30%")
	check(zero_terms(g) < 1e-9, "на старте культура и церковь не должны влиять (%.6f)" % zero_terms(g))
	if g.ch_on():
		print("  церковь: %s, влияние %.0f, религиозность %.1f, моральных законов %d" % [g.ch["name"], float(g.ch["pow"]), g.ch_nat_piety(), g.ch_laws().size()])
	# статичный режим: за 24 месяца без решений ничего не меняется
	var reg0: Array = []
	for r in g.regions: reg0.append((r["cul"] as Dictionary).duplicate())
	run_months(g, 24)
	check(shares_ok(g), "после 24 мес. доли народов не дают 1")
	# состав каждого региона не меняется (общий по стране чуть плывёт из-за разной рождаемости регионов)
	var dmax := 0.0
	for i in g.regions.size():
		for k in reg0[i]: dmax = maxf(dmax, absf(float(g.regions[i]["cul"].get(k, 0.0)) - float(reg0[i][k])))
	check(dmax < 1e-6, "в статичном режиме состав народов изменился на %.6f" % dmax)
	check(zero_terms(g) < 1e-6, "в статичном режиме появилось влияние культуры/церкви (%.6f)" % zero_terms(g))
	# жёсткая политика: растёт напряжённость там, где есть меньшинства
	g.capital = 500.0
	if g.pl_why() != "":
		print("  (партия игрока ушла в оппозицию на выборах — для проверки возвращаем её в правительство)")
		g.opp_mode = false
	var ms: float = 1.0 - g.cu_tit_share()
	for k in ["school", "lang", "auto"]:
		g.cu["cd"].clear()
		g.cu_set_pol(k, -1)
	run_months(g, 12)
	var dts := 0.0
	var lt := 0.0
	for i in g.regions.size():
		dts += g.pop_w[i] * g.cu_dt(i)
		lt += g.pop_w[i] * g.cult_loy_term(i)
	print("  жёсткая политика: напряжённость %s, лояльность %s (меньшинств %.1f%%)" % [g.sg(dts, 2), g.sg(lt, 2), ms * 100.0])
	if ms > 0.03 and g.cu_dr() > 0.0:
		check(dts > 0.05, "жёсткая политика не подняла напряжённость")
		check(lt < 0.0, "рост напряжённости не снизил лояльность")
	g.cu["cd"].clear()
	g.opp_mode = false
	g.capital = 500.0
	check(g.cu_dialog(), "круглый стол не сработал")
	# церковь: встреча улучшает отношения; государственная религия
	if g.ch_on():
		var r0: float = float(g.ch["rel"])
		check(g.ch_meet(), "встреча с церковью не сработала")
		check(float(g.ch["rel"]) > r0, "встреча не улучшила отношения")
		var st0: int = int(g.ch["state"])
		check(g.ch_set_state(int(g.ch["faith"]) if st0 < 0 else -1), "смена статуса церкви не сработала")
		g.ch["cd"].clear()
		check(g.ch_set_fin((int(g.ch["fin"]) + 1) % 3), "смена финансирования не сработала")
	# события культуры и церкви: все виды, все варианты
	fire_all(g)
	run_months(g, 6)
	check(shares_ok(g), "после событий доли народов не дают 1")
	# сохранение и загрузка
	var snap: PackedByteArray = g.sv_pack()
	var t0: float = float(g.cu["tension"])
	var p0: Dictionary = (g.cu["pol"] as Dictionary).duplicate()
	g.cu["tension"] = 99.0
	g.cu["pol"]["lang"] = 0
	check(g.sv_apply(snap), "загрузка сохранения не удалась")
	check(absf(float(g.cu["tension"]) - t0) < 1e-6 and int(g.cu["pol"]["lang"]) == int(p0["lang"]), "сохранение не вернуло культуры")
	await drop(g)

	# живая динамика: ассимиляция, рождаемость, агитация, события, миграция
	g = mk({"socev": 1, "exev": 1, "seed": 5})
	for i in 5: await process_frame
	g.capital = 500.0
	g.soc["cd"].clear()
	g.soc_set_mig(1)
	run_months(g, 48)
	check(shares_ok(g), "живая динамика: доли народов не дают 1")
	var nat3: Dictionary = g.cu_national()
	var mig0 := 0.0
	var mig1 := 0.0
	var n0: Dictionary = g.cu_national0()
	for k in nat3:
		if g.cu_is_mig(String(k)): mig1 += float(nat3[k])
	for k in n0:
		if g.cu_is_mig(String(k)): mig0 += float(n0[k])
	print("  живая динамика 48 мес.: ассимилировалось %.0f тыс., мигрантские народы %.2f%% → %.2f%%, напряжённость %.1f → %.1f, отношения с церковью %.0f" % [
		float(g.cu["assim"]) / 1000.0, mig0 * 100.0, mig1 * 100.0, float(g.cu["tension0"]), float(g.cu["tension"]), float(g.ch.get("rel", 0.0))])
	check(not is_nan(float(g.cu["tension"])) and not is_nan(g.gdp), "NaN в живой динамике")
	if g.ch_on():
		check(g.ch_nat_piety() > 0.5 and g.ch_nat_piety() < 96.0, "религиозность вышла за пределы")
	await drop(g)
	print("проблем %d" % bad)
	quit()
