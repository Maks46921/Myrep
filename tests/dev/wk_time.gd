extends SceneTree
# 0.62: время одного вызова переведённых функций (недельный режим wdt = 0.23, wmonth = false) и месячного шага.
# Параметры после "--": country=XX seed=N warm=N (месяцев прогрева) calls=N
func _init():
	var warm := 24
	var calls := 20
	for a in OS.get_cmdline_user_args():
		var s := String(a)
		if s.begins_with("warm="): warm = int(s.substr(5))
		elif s.begins_with("calls="): calls = int(s.substr(6))
	var m = load("res://main.gd").new()
	m.game_opts.merge({"ev": 0.0, "news": 0.0, "agents": false}, true)
	m.game_opts["seed"] = 7
	root.add_child(m)
	for i in 3: await process_frame
	for i in warm:
		if m.election_open: m.election_continue()
		while not m.current_event.is_empty(): m.choose(0)
		m.next_turn()
	var names := ["compute_budget", "bud_glide_step", "brake_week", "update_levels", "update_regions", "economy_week", "es_step", "econ_week", "week_tick"]
	m.wdt = 0.23
	m.wmonth = false
	var out := "ВРЕМЯ (мс на вызов, среднее по %d) %s\n" % [calls, m.ccode]
	for n in names:
		var t0 := Time.get_ticks_usec()
		for i in calls:
			if n == "week_tick":
				m.wdt = 1.0; m.wmonth = true
				m.week_tick()
				m.wdt = 0.23; m.wmonth = false
			else:
				m.call(n)
		var dt := float(Time.get_ticks_usec() - t0) / 1000.0 / float(calls)
		out += "  %-16s %.3f\n" % [n, dt]
	m.wdt = 1.0
	m.wmonth = true
	var t1 := Time.get_ticks_usec()
	for i in 6:
		if m.election_open: m.election_continue()
		while not m.current_event.is_empty(): m.choose(0)
		m.next_turn()
	out += "  %-16s %.3f\n" % ["next_turn", float(Time.get_ticks_usec() - t1) / 1000.0 / 6.0]
	# месяц целиком по дням (3 недельных тика + закрывающий шаг)
	var t2 := Time.get_ticks_usec()
	var days := 0
	for i in 6:
		var target: int = m.turn + 1
		var guard := 0
		while m.turn < target and guard < 100 and not m.game_over:
			guard += 1
			if m.election_open: m.election_continue()
			while not m.current_event.is_empty(): m.choose(0)
			m.advance_day()
	out += "  %-16s %.3f\n" % ["месяц по дням", float(Time.get_ticks_usec() - t2) / 1000.0 / 6.0]
	print(out)
	quit()
