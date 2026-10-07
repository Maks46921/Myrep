extends SceneTree
# dev: окно идеологической карты: растянуть, приблизить, снять (out=путь)
func _init():
	var outp := "/tmp/shot_pop.png"
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="): outp = String(a).substr(4)
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	g.show_desk(6)
	for i in 5: await process_frame
	var w = g.wins["pop_map"]
	var mv = g.ag_ui["map"]
	var h0: float = mv.size.y
	w.size = Vector2(w.size.x + 120.0, w.size.y + 160.0)
	for i in 5: await process_frame
	print("map h before %.0f after %.0f (window %.0f)" % [h0, mv.size.y, w.size.y])
	mv.zoom_at(mv.size * 0.5, 2.5)
	for i in 5: await process_frame
	await create_timer(0.5).timeout
	root.get_viewport().get_texture().get_image().save_png(outp)
	print("saved ", outp, " zoom ", mv.zoom)
	quit()
