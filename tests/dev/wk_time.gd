extends SceneTree
# 0.62: время одного недельного вызова каждой функции из WEEK_HOOKS (мкс). Параметры после "--": country=XX months=N only=имя1,имя2
func _init():
	var months := 18
	var only: PackedStringArray = []
	for a in OS.get_cmdline_user_args():
		var s := String(a)
		if s.begins_with("months="): months = int(s.substr(7))
		elif s.begins_with("only="): only = s.substr(5).split(",")
	var m = load("res://main.gd").new()
	m.game_opts.merge({"ev": 1.0, "news": 1.0, "fedev": 1, "socev": 1, "exev": 1, "milev": 1, "revev": 1, "rlev": 1, "bldev": 1, "agents": false}, true)
	m.game_opts["seed"] = 7
	root.add_child(m)
	for i in 3: await process_frame
	for mo in months:
		if m.game_over: break
		var guard := 0
		var t0: int = m.turn
		while m.turn == t0 and guard < 400 and not m.game_over:
			guard += 1
			if m.election_open: m.election_continue()
			var g2 := 0
			while not m.current_event.is_empty() and g2 < 5:
				m.choose(0); g2 += 1
			m.advance_day()
	# замер: каждый хук 20 раз с wdt = 0.23, wmonth = false (состояние не откатывается: важен порядок величины)
	var hooks: Array = m.WEEK_HOOKS
	var tot := 0
	for h in hooks:
		if not only.is_empty() and not (String(h) in only): continue
		var t1 := Time.get_ticks_usec()
		var n := 20
		m.wdt = 0.2333
		m.wmonth = false
		for k in n:
			m.call(h)
		var dt := float(Time.get_ticks_usec() - t1) / float(n)
		m.wdt = 1.0
		m.wmonth = true
		tot += int(dt)
		print("%-22s %9.0f мкс на вызов" % [h, dt])
	print("итого за недельный тик: %d мкс (%d мс)" % [tot, tot / 1000])
	quit()
