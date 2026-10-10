extends SceneTree
# Серия скриншотов для работы над графикой: out=префикс months=N. xvfb 1700x1000.
func snap(name: String, outp: String) -> void:
	for i in 6: await process_frame
	await create_timer(0.4).timeout
	root.get_viewport().get_texture().get_image().save_png("%s_%s.png" % [outp, name])
	print("saved ", name)

func _init():
	var outp := "/tmp/gfx"
	var months := 6
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="): outp = String(a).substr(4)
		if String(a).begins_with("months="): months = int(String(a).substr(7))
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	for m in months:
		if g.election_open: g.election_continue()
		while not g.current_event.is_empty(): g.choose(0)
		g.next_turn()
	if g.election_open: g.election_continue()
	while not g.current_event.is_empty(): g.choose(0)
	g.show_desk(0)
	await snap("budget", outp)
	g.show_desk(1)
	await snap("parl", outp)
	g.show_desk(5)
	await snap("econ", outp)
	g.show_desk(2)
	await snap("map", outp)
	g.map_zoom_cmd(4)
	g.map_ctl.queue_redraw()
	await snap("map_far", outp)
	g.map_layer = 20
	g.map_apply_mode()
	g.map_ctl.queue_redraw()
	await snap("map_world", outp)
	g.map_layer = 0
	g.map_apply_mode()
	g.show_desk(13)
	await snap("war", outp)
	g.show_desk(0)
	g.rv_event_wave()
	await snap("event", outp)
	while not g.current_event.is_empty(): g.choose(0)
	g.show_country_menu(true)
	await snap("menu", outp)
	quit()
