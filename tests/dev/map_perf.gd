extends SceneTree
# 0.59: замер большой карты: подготовка и время кадра при сдвиге и приближении
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	var t0 := Time.get_ticks_usec()
	g.map_prepare()
	print("PERF map_prepare ", snappedf(float(Time.get_ticks_usec() - t0) / 1000.0, 0.1), " мс; АТЕ ", g.ate_n, " линий рег/стр/берег ", g.map_ln_reg.size(), "/", g.map_ln_cty.size(), "/", g.map_ln_coast.size(), " ate ", g.map_ln_ate.size())
	g.show_desk(2)
	for i in 10: await process_frame
	var mc = g.map_ctl
	if mc == null:
		print("PERF map_ctl null, desk ", g.current_desk)
		quit()
		return
	print("PERF map size ", mc.size, " zoom ", g.map_zoom)
	for zz in [1.0, 3.0, 8.0]:
		g.map_zoom = zz
		g.map_zoom_t = zz
		for i in 5: await process_frame
		var t1 := Time.get_ticks_usec()
		var n := 40
		for k in n:
			g.map_center += Vector2(0.2, 0.1)
			g.map_center_t = g.map_center
			mc.queue_redraw()
			await process_frame
		print("PERF zoom ", zz, " кадр ", snappedf(float(Time.get_ticks_usec() - t1) / 1000.0 / n, 0.1), " мс")
	var nv := 0
	for ci in g.map_ctx_parts: 
		for p in ci: nv += p.size()
	print("PERF ctx вершин ", nv, " юнитов ", g.map_unit_mesh.size(), " WORLD_UNITS ", g.WORLD_UNITS.size())
	var t3 := Time.get_ticks_usec()
	for p in g.WORLD_UNITS.size(): g.unit_color(p)
	print("PERF unit_color ×все ", snappedf(float(Time.get_ticks_usec() - t3) / 1000.0, 0.1), " мс")
	var t2 := Time.get_ticks_usec()
	g.draw_map()
	print("PERF draw_map (без отрисовки) ", snappedf(float(Time.get_ticks_usec() - t2) / 1000.0, 0.1), " мс")
	quit()
