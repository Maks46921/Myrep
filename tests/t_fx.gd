extends SceneTree
var bad := []
func walk(x, path: String) -> void:
	if x is Dictionary:
		for k in [] if not path.ends_with("/fx") else ["econ", "reg", "regall", "state", "support", "sector", "rsec", "slider"]:
			if x.has(k) and not (x[k] is Dictionary):
				# reg: 0.1 в других словарях (не fx) — отфильтруем по наличию l/fx соседей
				bad.append("%s: ключ %s = %s" % [path, k, str(x[k])])
		for k in x:
			walk(x[k], path + "/" + str(k))
	elif x is Array:
		for i in x.size():
			walk(x[i], path + "[" + str(i) + "]")
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	var srcs := {"EVENTS_C": g.get("EVENTS_C"), "EVENTS_SPECIAL": g.get("EVENTS_SPECIAL"), "NEWS_C": g.get("NEWS_C"), "REG_GEN": g.REG_EVENTS_GEN, "REG_CC": g.REG_EVENTS_CC.get(g.ccode, []), "ECON_EVENTS": g.ECON_EVENTS}
	for k in srcs:
		if srcs[k] != null:
			walk(srcs[k], k)
	print("%s: проблем %d" % [g.ccode, bad.size()])
	for b in bad.slice(0, 6):
		print("   ", String(b).substr(0, 200))
	quit()
