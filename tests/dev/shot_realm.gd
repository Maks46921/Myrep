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
	g.dx_treaty_do("summit", String(g.tech_nb()[0]))
	g.sv_save(1)
	var shots := [[10, "ex"], [7, "goods"], [11, "soc"], [3, "laws"], [13, "war"], [1, "parl"], [8, "fed"], [0, "budget"]]
	for sh in shots:
		g.show_desk(int(sh[0]))
		g.rm_dirty_all()
		g.refresh()
		for i in 5: await process_frame
		await create_timer(0.3).timeout
		var img := root.get_viewport().get_texture().get_image()
		img.save_png("%s_%s.png" % [outp, String(sh[1])])
		print("saved ", sh[1])
	g.show_desk(0)
	g.tut_idx = -1
	g.set_crisis_open(true)
	g.refresh()
	for i in 5: await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s_crisis.png" % outp)
	g.set_crisis_open(false)
	g.set_tech_open(true)
	g.refresh()
	for i in 5: await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s_tech.png" % outp)
	print("saved overlays")
	quit()
