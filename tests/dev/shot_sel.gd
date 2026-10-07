extends SceneTree
# dev: скриншот карты с выделенной чужой страной: sel=GB out=путь
func _init():
	var sel := "GB"
	var outp := "/tmp/shot_sel.png"
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("sel="): sel = String(a).substr(4)
		if String(a).begins_with("out="): outp = String(a).substr(4)
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	g.show_desk(2)
	for ui in g.WORLD_UNITS.size():
		if String(g.WORLD_UNITS[ui]["cc"]) == sel:
			g.map_click(ui)
			break
	g.map_fit_rect(g.map_country_rect(sel))
	g.refresh()
	for i in 10: await process_frame
	await create_timer(0.5).timeout
	root.get_viewport().get_texture().get_image().save_png(outp)
	print("saved ", outp)
	quit()
