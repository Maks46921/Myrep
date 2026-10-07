extends SceneTree
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	for cc in ["LU", "DE", "NO", "GB"]:
		var parts: Array = []
		for ui in g.WORLD_UNITS.size():
			if String(g.WORLD_UNITS[ui]["cc"]) == cc:
				parts.append_array(g.map_unit_parts[ui])
		var t0 := Time.get_ticks_msec()
		var o = g.CountryMap.outline_of(parts)
		print(cc, " parts ", parts.size(), " -> ", o.size(), " ms ", Time.get_ticks_msec() - t0)
	quit()
