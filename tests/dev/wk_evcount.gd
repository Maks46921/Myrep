extends SceneTree
# 0.62: сколько окон событий за N лет в месячном и недельном режиме (частота событий должна совпадать). Параметры: country seed years mode
func _init():
	var cc := "FR"
	var seed_ := 7
	var years := 8
	var mode := "w"
	for a in OS.get_cmdline_user_args():
		var s := String(a)
		if s.begins_with("country="): cc = s.substr(8)
		elif s.begins_with("seed="): seed_ = int(s.substr(5))
		elif s.begins_with("years="): years = int(s.substr(6))
		elif s.begins_with("mode="): mode = s.substr(5)
	var m = load("res://main.gd").new()
	m.game_opts.merge({"ev": 1.0, "news": 1.0, "fedev": 1, "socev": 1, "exev": 1, "milev": 1, "revev": 1, "rlev": 1, "bldev": 1, "agents": false}, true)
	m.game_opts["seed"] = seed_
	m.game_opts["country"] = cc
	root.add_child(m)
	for i in 3: await process_frame
	var kinds := {}
	var tot := 0
	for mo in years * 12:
		if m.game_over: break
		var target: int = m.turn + 1
		var guard := 0
		while m.turn < target and guard < 3000 and not m.game_over:
			guard += 1
			if m.election_open: m.election_continue()
			var g2 := 0
			while not m.current_event.is_empty() and g2 < 5:
				var k := String(m.current_event.get("kind", "?"))
				if k == "?": k = "?" + String(m.current_event.get("id", m.current_event.get("t", m.current_event.get("title", "")))).left(22).replace(" ", "_")
				kinds[k] = int(kinds.get(k, 0)) + 1
				tot += 1
				m.choose(0); g2 += 1
			if mode == "m": m.next_turn()
			else: m.advance_day()
	var ks := kinds.keys()
	ks.sort()
	var parts: PackedStringArray = []
	for k in ks: parts.append("%s=%d" % [k, kinds[k]])
	print("EV ", mode, " ", cc, " seed ", seed_, " всего ", tot, ": ", " ".join(parts))
	quit()
