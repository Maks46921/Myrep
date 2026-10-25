extends SceneTree
# Время по календарным дням: +1 день, конец месяца запускает месячный шаг, скорости, пауза, блокировка событиями.
var bad := 0

func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)

func _init():
	var m = load("res://main.gd").new()
	root.add_child(m)
	for i in 3: await process_frame
	var g = m
	g.game_opts["ev"] = 0.0
	g.current_event = {}
	var t0: int = g.turn
	var d0: int = g.day
	check(d0 == 1, "игра начинается с 1-го числа (день %d)" % d0)
	check(g.PLAY_SPEEDS.size() >= 6 and g.PLAY_SPEEDS[0] == 0.0, "есть пауза и несколько скоростей")
	check(g.days_in_month(2024, 2) == 29 and g.days_in_month(2023, 2) == 28 and g.days_in_month(2023, 4) == 30, "длины месяцев, високосный год")
	var ok: bool = g.advance_day()
	check(ok and g.day == 2 and g.turn == t0, "+1 день: число сменилось, месяц тот же")
	var left: int = g.days_in_month(g.year, g.month) - g.day
	g.advance_days(left)
	check(g.day == g.days_in_month(g.year, g.month) and g.turn == t0, "дошли до конца месяца без месячного шага")
	g.current_event = {}
	g.advance_day()
	check(g.turn == t0 + 1 and g.day == 1, "день после конца месяца запускает месячный шаг (turn %d)" % g.turn)
	# событие блокирует время
	g.current_event = {"title": "x"}
	check(not g.advance_day(), "при открытом событии время стоит")
	g.current_event = {}
	# скорость и пауза
	g.set_speed(0)
	var dt0: int = g.day_total
	g._process(5.0)
	check(g.day_total == dt0, "на паузе дни не идут")
	g.set_speed(3)
	g._process(1.0)
	check(g.day_total > dt0, "на скорости дни идут (%d → %d)" % [dt0, g.day_total])
	g.set_speed(0)
	for tries in 4:      # 0.62: по пути может открыться окно (воскресные выборы, среда с голосованием): закрываем и идём дальше
		if g.election_open: g.election_continue()
		g.current_event = {}
		g.advance_month()
		if g.day == 1:
			break
	check(g.day == 1, "«Месяц» доводит до 1-го числа")
	print("t_time: проблем ", bad)
	m.free()
	quit(1 if bad > 0 else 0)
