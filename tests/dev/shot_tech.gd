extends SceneTree
# Скриншоты веток технологий: по одному файлу на ветку, окно ветки растянуто на всю рабочую область.
# xvfb-run -a -s "-screen 0 1700x2300x24" godot --rendering-driver opengl3 --script tests/dev/shot_tech.gd -- country=DE years=35 out=/tmp/tech
func _init():
	var years := 35
	var outp := "/tmp/tech"
	var cc := "DE"
	var a_scroll := 0
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("years="): years = int(String(a).substr(6))
		if String(a).begins_with("out="): outp = String(a).substr(4)
		if String(a).begins_with("country="): cc = String(a).substr(8)
		if String(a).begins_with("scroll="): a_scroll = int(String(a).substr(7))
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
			for id in ["rc", "campus", "tpark", "inst", "think", "pilot", "milab"]:
				g.tech_build(id)
		g.next_turn()
	while not g.current_event.is_empty():
		g.choose(0)
	if g.election_open: g.election_continue()
	g.set_tech_open(true)
	g.refresh()
	for i in 10: await process_frame
	var names := ["all", "eco", "soc", "pol", "ind", "mil"]
	print("pressed tabs: ", g.desk_buttons.map(func(b): return b.button_pressed))
	for k in names.size():
		g.on_tech_filter(k)
		g.tech_scroll.scroll_vertical = 0
		for i in 8: await process_frame
		g.tech_scroll_to_frontier()
		if k == 0 and a_scroll > 0:
			g.tech_scroll.scroll_horizontal = a_scroll
		# наведение на доступную технологию (если есть) — подсветка и описание
		var hv := ""
		for d in g.TECHS:
			var hid: String = d["id"]
			if g.tech_view.pos.has(hid) and g.tech_avail(hid) and (g.tech_nb_share(hid) > 0.0 or hv == ""):
				hv = hid
				if g.tech_nb_share(hid) > 0.0:
					break
		if hv != "":
			g.tech_view.hover_id = hv
			g.on_tech_hover(hv)
			g.tech_view.queue_redraw()
		for i in 3: await process_frame
		await create_timer(0.4).timeout
		var img: Image = root.get_viewport().get_texture().get_image()
		var path := "%s_%d_%s.png" % [outp, k, names[k]]
		img.save_png(path)
		print("saved ", path, " ", img.get_size())
	quit()
