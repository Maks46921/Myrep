extends SceneTree
# dev v36: скриншоты карты АТЕ: country=XX zoom=N out=путь  (mode=1 — режим АТЕ с выделением)
func _init():
	var outp := "/tmp/shot_ate.png"
	var zoom := 1.0
	var mode := 0
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="): outp = String(a).substr(4)
		if String(a).begins_with("zoom="): zoom = float(String(a).substr(5))
		if String(a).begins_with("mode="): mode = int(String(a).substr(5))
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	var t := Time.get_ticks_msec()
	g.show_desk(2)
	for i in 3: await process_frame
	g.map_fit_rect(g.map_country_rect(g.ccode))
	if zoom != 1.0:
		g.map_zoom_at(g.map_ctl.size * 0.5, zoom)
	if mode == 1:
		g.adm_open()
		var r0: PackedInt32Array = g.adm_region_ates(0)
		for k in mini(6, r0.size()):
			g.ate_sel.append(r0[k])
		g.update_adm_ui()
	g.refresh()
	for i in 6: await process_frame
	print("draw ms ", Time.get_ticks_msec() - t)
	var nm := 0
	for m in g.map_unit_mesh:
		if m != null: nm += 1
	print("ate ", g.ate_n, " unit ", g.ate_unit.size(), " lists ", g.ate_lists.size(), " meshes ", nm, " bounds ", g.map_bounds, " view ", g.map_view(), " lnreg ", g.map_ln_reg.size())
	await create_timer(0.5).timeout
	root.get_viewport().get_texture().get_image().save_png(outp)
	print("saved ", outp)
	quit()
