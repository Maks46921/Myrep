extends SceneTree
# v48_1: скриншот вкладки «Вооружённые силы» (desk 15): out=путь, act=1 — перед снимком запустить программы, учения, миссию
func _init():
	var outp := "/tmp/shot_army.png"
	var act := 1
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="): outp = String(a).substr(4)
		if String(a).begins_with("act="): act = int(String(a).substr(4))
	var g = load("res://main.gd").new()
	g.game_opts.merge({"ev": 0.0, "news": 0.0, "milev": 0}, true)
	root.add_child(g)
	for i in 5: await process_frame
	if act == 1:
		g.capital = 60.0
		g.ar_shift_bs("eq", 0.05)
		g.ar_prog_start("sam_l")
		g.ar_prog_start("arty")
		g.ar_exercise("allied")
		g.ar_mis_toggle("nato" if g.mil_is_nato(g.ccode) else "un")
		for m in 7:
			while not g.current_event.is_empty(): g.choose(0)
			if g.election_open: g.election_continue()
			g.next_turn()
		while not g.current_event.is_empty(): g.choose(0)
		g.ar_prog_start("drones")
		g.ar_prog_start("fighter4")
	g.show_desk(15)
	for i in 4: await process_frame
	g.refresh()
	for i in 6: await process_frame
	await create_timer(0.5).timeout
	root.get_viewport().get_texture().get_image().save_png(outp)
	print("saved ", outp)
	quit()
