extends SceneTree
# Клик по каждой чужой стране (первый и второй щелчок) и все слои карты: без вылетов.
var bad := 0
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	g.show_desk(2)
	for i in 4: await process_frame
	var firstu := {}
	for ui in g.WORLD_UNITS.size():
		var cc: String = String(g.WORLD_UNITS[ui]["cc"])
		if cc != g.ccode and not firstu.has(cc):
			firstu[cc] = ui
	for cc in firstu:
		g.map_click(int(firstu[cc]))
		await process_frame
		g.map_click(int(firstu[cc]))
		await process_frame
		g.refresh()
		if g.dip_sel != cc:
			bad += 1; print("FAIL: страна не выбрана ", cc)
	for ly in [20, 21, 22, 23, 24, 25, 26]:
		g.map_layer = ly
		for cc in g.WORLD:
			g.cl_info(cc)
		g.map_apply_mode()
		g.refresh()
		await process_frame
	print("t_far: стран ", firstu.size(), " проблем ", bad)
	quit(1 if bad > 0 else 0)
