extends SceneTree
# dev v48_1: стартовые показатели армии страны: расходы % ВВП, численность, резерв, авиация, ПВО, боеприпасы, рода войск
func _init():
	var g = load("res://main.gd").new()
	g.game_opts.merge({"ev": 0.0, "news": 0.0, "milev": 0, "agents": false}, true)
	root.add_child(g)
	for i in 3: await process_frame
	var comp: Dictionary = g.ar_comp()
	var parts: PackedStringArray = []
	for tp in g.AR_TYPES:
		if float(comp[tp]) > 0.0: parts.append("%s %.0f" % [tp, float(comp[tp])])
	print("ARS|%s|%.2f|%.0f|%.0f|%.0f|%.0f|%.1f|%s|%s|%.0f" % [g.ccode, float(g.pol["army"]), g.mil_total(g.ccode), g.ar_rsv(), float(g.ar["air"]), float(g.ar["ad"]), float(g.ar["ammo"]), g.ar["svc"], " ".join(parts), g.gdp])
	quit()
