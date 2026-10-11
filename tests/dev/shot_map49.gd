extends SceneTree
# v49: снимки карты: out=префикс country=XX. Своя страна, вся карта, слой «Мир», сильное приближение, меню выбора страны.
func snap(name: String, outp: String) -> void:
	for i in 6: await process_frame
	await create_timer(0.4).timeout
	root.get_viewport().get_texture().get_image().save_png("%s_%s.png" % [outp, name])
	print("saved ", name)

func _init():
	var outp := "/tmp/m49"
	var only := ""
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="): outp = String(a).substr(4)
		if String(a).begins_with("only="): only = String(a).substr(5)
	var g = load("res://main.gd").new()
	g.game_opts.merge({"ev": 0.0, "news": 0.0}, true)
	root.add_child(g)
	for i in 5: await process_frame
	g.show_desk(2)
	for i in 3: await process_frame
	if only == "" or only == "own":
		g.map_zoom_cmd(3)
		await snap("own", outp)
	if only == "" or only == "far":
		g.map_zoom_cmd(4)
		await snap("far", outp)
	if only == "" or only == "world":
		g.map_layer = 20
		g.map_apply_mode()
		g.map_zoom_cmd(3)
		g.map_zoom_at(g.map_ctl.size * 0.5, 0.45)
		await snap("world", outp)
		g.map_layer = 0
		g.map_apply_mode()
	if only == "" or only == "close":
		g.map_zoom_cmd(3)
		g.map_zoom_at(g.map_ctl.size * 0.5, 3.0)
		await snap("close", outp)
	if only == "" or only == "menu":
		g.show_country_menu(true)
		await snap("menu", outp)
	quit()
