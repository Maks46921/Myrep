extends SceneTree
# dev v37: снимки экранов «Армия и война» и «Флот» во время войны: country=XX foe=YY days=N desk=13|14 out=путь
func _init():
	var outp := "/tmp/shot_war.png"
	var foe := "PL"
	var days := 60
	var desk := 13
	var mob := 1
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="): outp = String(a).substr(4)
		if String(a).begins_with("foe="): foe = String(a).substr(4)
		if String(a).begins_with("days="): days = int(String(a).substr(5))
		if String(a).begins_with("desk="): desk = int(String(a).substr(5))
		if String(a).begins_with("mob="): mob = int(String(a).substr(4))
	var g = load("res://main.gd").new()
	g.game_opts.merge({"ev": 0.0, "news": 0.0, "milev": 0}, true)
	root.add_child(g)
	for i in 5: await process_frame
	if foe != "-":
		g.mil_declare(foe, true)
		g.mil_mobilize(mob)
		for f in g.mil_units_of(g.ccode):
			g.mil_order_mode(int(f["id"]), "auto")
		for d in days:
			if g.election_open: g.election_continue()
			if not g.current_event.is_empty(): g.choose(0)
			g.advance_day()
		if g.mil_units_of(g.ccode).size() > 0:
			g.mil["sel"] = int(g.mil_units_of(g.ccode)[0]["id"])
	g.show_desk(desk)
	for i in 3: await process_frame
	g.map_fit_rect(g.map_country_rect(g.ccode).merge(g.map_country_rect(foe) if foe != "-" else g.map_country_rect(g.ccode)))
	g.refresh()
	for i in 6: await process_frame
	await create_timer(0.5).timeout
	root.get_viewport().get_texture().get_image().save_png(outp)
	print("saved ", outp)
	quit()
