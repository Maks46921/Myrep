extends SceneTree
# v51: раздел «Политика» при режимах. Аргументы: country=XX install=dictatorship|junta|oneparty|monarchy_abs out=DIR tag=имя
#   (без install — исходный режим страны, напр. Россия — гибридный); regime=1 — показать заставку смены режима
func _init():
	var outd := "/tmp"
	var inst := ""
	var tag := "reg"
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="): outd = String(a).substr(4)
		if String(a).begins_with("install="): inst = String(a).substr(8)
		if String(a).begins_with("tag="): tag = String(a).substr(4)
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 6: await process_frame
	if inst != "":
		g.support["Силовики"] = 85.0
		g.rv_install_regime(inst)
		g.rv["conf"] = []
	for m in 3:
		while not g.current_event.is_empty():
			g.choose(0)
		if g.election_open: g.election_continue()
		g.next_turn()
	while not g.current_event.is_empty():
		g.choose(0)
	g.capital = 60.0
	g.show_desk(1)
	g.refresh()
	for i in 10: await process_frame
	if OS.get_cmdline_user_args().has("regime=1"):
		await create_timer(0.9).timeout
		root.get_viewport().get_texture().get_image().save_png(outd + "/v51_%s_trans.png" % tag)
		await create_timer(3.5).timeout
	await create_timer(0.6).timeout
	root.get_viewport().get_texture().get_image().save_png(outd + "/v51_%s_pol.png" % tag)
	g.show_desk(12)
	for i in 6: await process_frame
	await create_timer(0.6).timeout
	root.get_viewport().get_texture().get_image().save_png(outd + "/v51_%s_repr.png" % tag)
	quit()
