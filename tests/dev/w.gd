extends SceneTree
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	await process_frame
	await process_frame
	for cc in g.WORLD:
		var w = g.WORLD[cc]
		print(cc, " ", w["name"], " gdp ", w["gdp"], " pop ", w.get("pop", "?"), " eu ", w.get("eu", "?"), " regions ", (w["regions"] as Array).size())
	print("DIP_ORDER ", g.DIP_ORDER)
	print("ate_n ", g.ate_n)
	var cnt = {}
	for a in g.ate_n:
		var c = g.ate_cc(a)
		cnt[c] = cnt.get(c, 0) + 1
	print(cnt)
	print(g.pol_def["army"], " ", g.gdp)
	quit()
