extends SceneTree
# Замер скорости карты выбора страны: число вершин и время кадра при движении камеры.
func _init():
	var ts := Time.get_ticks_usec()
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	print("запуск до меню: %.0f мс" % (float(Time.get_ticks_usec() - ts) / 1000.0))
	var menu = g.get_node_or_null("CountryMenu")
	var cm = _find(menu)
	var nv := 0
	var nlo := 0
	var np := 0
	for u in cm.units:
		for p in u["parts"]:
			nv += p.size(); np += 1
		for p in []:
			nlo += p.size()
	var nc := 0
	for parts in cm.ctx:
		for p in parts:
			nc += p.size()
	print("units %d parts %d verts %d (обзор %d) ctx verts %d" % [cm.units.size(), np, nv, nlo, nc])
	await create_timer(1.0).timeout
	var t0 := Time.get_ticks_usec()
	var n := 60
	for k in n:
		cm.center_t += Vector2(0.3, 0.1)
		cm.center = cm.center_t
		cm.queue_redraw()
		await process_frame
	var dt: float = float(Time.get_ticks_usec() - t0) / 1000.0 / n
	print("кадр при сдвиге: %.1f мс  bounds %s s %.3f" % [dt, cm.bounds, cm._view()[0]])
	for mode in ["без подписей", "без суши", "без всего"]:
		if mode == "без подписей": pass
		if mode == "без суши": pass
		if mode == "без всего": pass
		t0 = Time.get_ticks_usec()
		for k in 30:
			cm.center_t += Vector2(0.3, 0.1)
			cm.center = cm.center_t
			cm.queue_redraw()
			await process_frame
		print("%s: %.1f мс" % [mode, float(Time.get_ticks_usec() - t0) / 1000.0 / 30])
	quit()
func _find(n: Node):
	for ch in n.get_children():
		if ch.has_method("select") and ch.has_method("setup"):
			return ch
		var r = _find(ch)
		if r != null:
			return r
	return null
