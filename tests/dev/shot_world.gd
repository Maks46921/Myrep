extends SceneTree
# Скриншот рамки «Влияние» (desk 10) с окном «Мир и санкции» и листа мирного договора (desk 13).
func _init():
	var outp := "/tmp/world"
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="): outp = String(a).substr(4)
	var g = load("res://main.gd").new()
	g.game_opts.merge({"agents": false, "seed": 5, "tut": 0}, true)
	root.add_child(g)
	for i in 5: await process_frame
	for m in 3:
		if g.election_open: g.election_continue()
		while not g.current_event.is_empty(): g.choose(0)
		g.next_turn()
	while not g.current_event.is_empty(): g.choose(0)
	g.capital = 40.0
	for sh in [[10, "ex"], [13, "war"]]:
		g.show_desk(int(sh[0]))
		g.rm_dirty_all()
		g.refresh()
		for i in 5: await process_frame
		await create_timer(0.3).timeout
		root.get_viewport().get_texture().get_image().save_png("%s_%s.png" % [outp, String(sh[1])])
		print("saved ", sh[1])
	quit()
