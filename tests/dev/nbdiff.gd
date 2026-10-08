extends SceneTree
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	var nd := 0
	for ui in g.wu_n0:
		var a: Array = (g.wu_nb0[ui] as Array).duplicate()
		var b: Array = (g.WORLD_UNITS[ui]["nb"] as Array).duplicate()
		a.sort(); b.sort()
		if a != b:
			nd += 1
			if nd < 12: print(g.WORLD_UNITS[ui]["id"], " было ", a.map(func(x): return g.WORLD_UNITS[int(x)]["id"]), " стало ", b.map(func(x): return g.WORLD_UNITS[int(x)]["id"]))
	print("различий ", nd, " admin_mult ", g.adm_admin_mult(), " nreg ", g.regions.size(), " u0 ", g.wu_cc0.count(g.ccode))
	quit()
