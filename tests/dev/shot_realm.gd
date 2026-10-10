extends SceneTree
# Скриншоты окна «Государство»: страницы по очереди. xvfb-run -a -s "-screen 0 1700x1000x24" godot --rendering-driver opengl3 --script tests/dev/shot_realm.gd -- tut=1 out=/tmp/realm months=30
func _init():
	var outp := "/tmp/realm"
	var months := 30
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="): outp = String(a).substr(4)
		if String(a).begins_with("months="): months = int(String(a).substr(7))
	var g = load("res://main.gd").new()
	g.game_opts.merge({"agents": false, "seed": 5, "fedev": 0, "socev": 0, "exev": 0, "milev": 0, "revev": 1, "rlev": 1, "tut": 1}, true)
	root.add_child(g)
	for i in 5: await process_frame
	var shot_tut := true
	for m in months:
		if g.game_over: break
		if g.election_open: g.election_continue()
		while not g.current_event.is_empty():
			g.choose(0)
		g.capital = maxf(g.capital, 40.0)
		g.next_turn()
	while not g.current_event.is_empty():
		g.choose(0)
	g.tut_idx = 6
	g.capital = 60.0
	g.rl_do("grn_up")
	g.rl_do("fam_up")
	var cs: Array = g.dx_countries()
	g.rm_dip_sel = String(g.tech_nb()[0])
	g.dx_treaty_do("summit", g.rm_dip_sel)
	g.sv_save(1)
	g.set_realm_open(true)
	for pg in g.RM_PAGES:
		g.on_realm_page(String(pg[0]))
		g.update_realm_windows()
		for i in 4: await process_frame
		var img := root.get_viewport().get_texture().get_image()
		img.save_png("%s_%s.png" % [outp, String(pg[0])])
		print("saved ", pg[0])
	quit()
