extends SceneTree
# Скриншот окна «Кризисы» в напряжённой ситуации. xvfb-run -a -s "-screen 0 1700x1000x24" godot --rendering-driver opengl3 --script tests/dev/shot_crisis.gd -- country=ES out=/tmp/crisis.png
func _init():
	var outp := "/tmp/crisis.png"
	var seed := 5
	var pick := 0
	var months := 90
	var boost := 0.9
	var demo := false
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="): outp = String(a).substr(4)
		if String(a).begins_with("seed="): seed = int(String(a).substr(5))
		if String(a).begins_with("months="): months = int(String(a).substr(7))
		if String(a) == "demo": demo = true
		if String(a).begins_with("boost="): boost = float(String(a).substr(6))
	var g = load("res://main.gd").new()
	g.game_opts.merge({"agents": false, "seed": seed, "fedev": 0, "socev": 0, "exev": 0, "milev": 0, "revev": 1}, true)
	root.add_child(g)
	for i in 5: await process_frame
	g.ap["bal"] = true
	for m in months:
		if g.game_over: break
		if g.election_open: g.election_continue()
		while not g.current_event.is_empty():
			g.choose(clampi(pick, 0, (g.current_event["o"] as Array).size() - 1))
		g.capital = maxf(g.capital, 25.0)
		for rr in g.regions:
			rr["unrest"] = minf(100.0, float(rr["unrest"]) + boost)
			rr["loy"] = maxf(0.0, float(rr["loy"]) - 0.7)
		g.next_turn()
	if demo:
		# демонстрация: мятеж и война за независимость, обострение в других регионах, одно отделившееся государство
		var names := ["Каталония", "Басков+Нав.", "Канары", "Галисия", "Балеары"]
		var idx := {}
		for i in g.regions.size():
			idx[String(g.REGIONS[i]["short"])] = i
		for nm in names:
			if not idx.has(nm): continue
			var i2: int = idx[nm]
			g.regions[i2]["unrest"] = 80.0 if nm == "Каталония" else 62.0
			g.regions[i2]["loy"] = 18.0
			g.rv_reg(i2)["sep"] = 82.0 if nm == "Каталония" else 61.0
			g.rv_reg(i2)["hate"] = 58.0 if nm == "Каталония" else 30.0
			g.rv_reg(i2)["stage"] = 3 if nm == "Каталония" else 2
		if idx.has("Балеары"):
			g.rv_secede(idx["Балеары"], "referendum")
			idx = {}
			for i in g.regions.size():
				idx[String(g.REGIONS[i]["short"])] = i
		if idx.has("Каталония"):
			g.rv_conf_start("secession", idx["Каталония"], 41.0, "силовой ответ на требование независимости в регионе «Каталония»")
			g.rv["conf"][0]["kia"] = 3.4
			g.cr_sel_reg = g.rv_uid(idx["Каталония"])
		g.rv["nat"]["wave"] = 52.0
		g.rv["nat"]["rev"] = 41.0
		g.rv["nat"]["coup"] = 38.0
		g.rv["nat"]["hate"] = 31.0
		g.capital = 60.0
	while not g.current_event.is_empty():
		g.choose(0)
	g.set_crisis_open(true)
	g.refresh()
	for i in 10: await process_frame
	await create_timer(0.6).timeout
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png(outp)
	print("saved ", outp, " conf ", g.rv["conf"].size(), " game_over ", g.game_over)
	quit()
