extends SceneTree
func _init():
	var outd := "/tmp"
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="): outd = String(a).substr(4)
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 6: await process_frame
	g.capital = 100.0
	for m in 30:
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty(): g.choose(0)
		g.next_turn()
	if g.election_open: g.election_continue()
	if not g.current_event.is_empty(): g.choose(0)
	g.set_tech_open(true)
	for i in 10: await process_frame
	await create_timer(0.6).timeout
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png(outd + "/v50_tech.png")
	# откат выбора
	var swapped := false
	for d in g.TECHS:
		if g.tech_swap_check(String(d["id"])) == "":
			swapped = g.tech_swap(String(d["id"]))
			print("swap ", d["id"], " -> ", swapped)
			break
	g.set_tech_open(false)
	g.show_desk(6)
	g.refresh()
	for i in 10: await process_frame
	await create_timer(0.5).timeout
	img = root.get_viewport().get_texture().get_image()
	img.save_png(outd + "/v50_pop.png")
	g.show_desk(1)
	g.refresh()
	for i in 10: await process_frame
	await create_timer(0.4).timeout
	img = root.get_viewport().get_texture().get_image()
	img.save_png(outd + "/v50_parl.png")
	g.show_desk(3)
	g.refresh()
	for i in 10: await process_frame
	await create_timer(0.4).timeout
	img = root.get_viewport().get_texture().get_image()
	img.save_png(outd + "/v50_laws.png")
	quit()
