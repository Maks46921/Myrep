extends SceneTree
# Скриншоты веток технологий: по одному файлу на ветку, окно ветки растянуто на всю рабочую область.
# xvfb-run -a -s "-screen 0 1700x2300x24" godot --rendering-driver opengl3 --script tests/dev/shot_tech.gd -- country=DE years=35 out=/tmp/tech
func _init():
	var years := 35
	var outp := "/tmp/tech"
	var cc := "DE"
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("years="): years = int(String(a).substr(6))
		if String(a).begins_with("out="): outp = String(a).substr(4)
		if String(a).begins_with("country="): cc = String(a).substr(8)
	var g = load("res://main.gd").new()
	g.game_opts.merge({"agents": false, "ev": 1.0, "fedev": 0, "socev": 0, "exev": 0, "milev": 0, "seed": 11}, true)
	root.add_child(g)
	for i in 5: await process_frame
	g.ap["bal"] = true
	g.ap["events"] = true
	var edu_fix: float = float(g.pol["edu"]) * 1.4
	for m in years * 12:
		if g.game_over:
			if g.debt / g.gdp > 1.4: break
			g.game_over = false
			g.low_months = 0
			g.end_reason = ""
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty(): g.choose(0)
		g.capital = 100.0
		g.pol["edu"] = edu_fix
		if g.turn % 6 == 0:
			for id in ["rc", "campus", "tpark", "inst", "think", "pilot"]:
				g.tech_build(id)
		g.next_turn()
	g.show_desk(15)
	g.refresh()
	for i in 10: await process_frame
	var names := ["eco", "soc", "pol", "ind"]
	for b in g.TECH_NB:
		for id in g.wins:
			var w = g.wins[id]
			if w.desk == 15:
				w.visible = (id == "tw_b%d" % b) or id == "tw_sum"
		var wb = g.wins["tw_b%d" % b]
		wb.visible = true
		wb.frac = Rect2(0.2, 0.0, 0.5, 1.0)
		wb.apply_frac()
		g.wins["tw_sum"].frac = Rect2(0.0, 0.0, 0.2, 1.0)
		g.wins["tw_sum"].apply_frac()
		for i in 8: await process_frame
		await create_timer(0.5).timeout
		var img: Image = root.get_viewport().get_texture().get_image()
		var path := "%s_%d_%s.png" % [outp, b + 1, names[b]]
		img.save_png(path)
		print("saved ", path, " ", img.get_size())
	quit()
