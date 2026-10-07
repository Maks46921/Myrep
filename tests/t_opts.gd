extends SceneTree
# Настройки новой игры (меню перед стартом): агенты вкл/выкл, число людей на агента, капитал, события, зерно.
const DEF := {"agents": true, "k": 0, "seed": 0, "ev": 1.0, "news": 1.0, "econ": 1, "volat": 1.0, "cap": 1.0, "detail": false, "fedev": 1}
var bad := 0

func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)

func mk(o: Dictionary) -> Node:
	var m = load("res://main.gd").new()
	m.game_opts.merge(DEF, true)
	m.game_opts.merge(o, true)
	root.add_child(m)
	return m

func run_months(g, n: int) -> void:
	for i in n:
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty(): g.choose(0)
		g.next_turn()

func drop(g) -> void:
	root.remove_child(g)
	g.free()
	await process_frame

func _init():
	var g0 = mk({})
	for i in 3: await process_frame
	var cc: String = g0.ccode
	check(g0.AG != null and g0.ag_on, "по умолчанию модель агентов включена")
	var cap0: float = g0.capital
	var n0: int = g0.AG.n
	var k0: int = g0.AG.k
	check(g0.econ_pool().size() == g0.ECON_EVENTS.size(), "econ=1: обычный пул экономических событий")
	await drop(g0)
	# агенты выключены
	var g1 = mk({"agents": false})
	for i in 3: await process_frame
	check(g1.AG == null and not g1.ag_on, "agents=false: модели агентов нет")
	run_months(g1, 8)
	check(not is_nan(g1.gdp) and g1.gdp > 0.0, "agents=false: игра идёт без агентов")
	await drop(g1)
	# людей на агента
	var g2 = mk({"k": 500})
	for i in 3: await process_frame
	check(g2.AG != null and g2.AG.k == 500, "k=500: на агента 500 человек (получилось %d)" % (g2.AG.k if g2.AG != null else -1))
	check(g2.AG.n < n0 or k0 >= 500, "k=500: агентов не больше, чем при авто")
	await drop(g2)
	# капитал, экономические события
	var g3 = mk({"cap": 1.6, "econ": 2, "detail": true})
	for i in 3: await process_frame
	check(absf(g3.capital - cap0 * 1.6) < 0.01, "cap=1.6: стартовый капитал %.1f, ожидался %.1f" % [g3.capital, cap0 * 1.6])
	check(g3.econ_pool().size() == 2 * g3.ECON_EVENTS.size(), "econ=2: события вдвое чаще")
	check(g3.ui_detail, "detail=true: пояснения включены с начала")
	await drop(g3)
	var g4 = mk({"econ": 0, "ev": 0.0, "news": 0.0})
	for i in 3: await process_frame
	check(g4.econ_pool().is_empty(), "econ=0: экономических событий нет")
	run_months(g4, 18)
	check(g4.gdp > 0.0, "ev=0: игра идёт")
	await drop(g4)
	# зерно: два запуска дают одинаковый результат
	var res := []
	for r in 2:
		var g5 = mk({"seed": 4242})
		for i in 3: await process_frame
		run_months(g5, 10)
		res.append("%.4f %.4f %.3f" % [g5.gdp, g5.debt, g5.approval()])
		await drop(g5)
	check(res[0] == res[1], "seed=4242: запуски различаются: %s | %s" % [res[0], res[1]])
	print("[%s] настройки новой игры: проблем %d" % [cc, bad])
	quit()
