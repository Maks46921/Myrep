extends SceneTree
# v52: скриншот раздела. country=XX desk=N [tech=1|crisis=1] [party=K — играть за другую партию] tag=имя out=DIR months=M
func _init():
	var outd := "/tmp"
	var desk := 1
	var tag := "v52"
	var months := 1
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="): outd = String(a).substr(4)
		if String(a).begins_with("desk="): desk = int(String(a).substr(5))
		if String(a).begins_with("tag="): tag = String(a).substr(4)
		if String(a).begins_with("months="): months = int(String(a).substr(7))
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 6: await process_frame
	for m in months:
		while not g.current_event.is_empty():
			g.choose(0)
		if g.election_open: g.election_continue()
		g.next_turn()
	while not g.current_event.is_empty():
		g.choose(0)
	if g.election_open: g.election_continue()
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("org="): g.io["sel"] = String(a).substr(4)
	g.show_desk(desk)
	if OS.get_cmdline_user_args().has("tech=1"): g.set_tech_open(true)
	if OS.get_cmdline_user_args().has("crisis=1"): g.set_crisis_open(true)
	g.refresh()
	for i in 8: await process_frame
	await create_timer(0.7).timeout
	root.get_viewport().get_texture().get_image().save_png(outd + "/v52_%s.png" % tag)
	quit()
