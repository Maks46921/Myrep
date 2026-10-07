extends SceneTree
var bad := []
func walk(x, path: String, depth: int) -> void:
	if depth > 12:
		return
	if x is Dictionary:
		for k in ["regall", "sector", "econ"]:
			if x.has(k) and not (x[k] is Dictionary):
				bad.append("%s: %s = %s" % [path, k, str(x[k])])
		if x.has("sector") and x["sector"] is Dictionary:
			for sk in x["sector"]:
				if not (x["sector"][sk] is Dictionary):
					bad.append("%s: sector.%s = %s" % [path, sk, str(x["sector"][sk])])
		if x.has("reg") and (x["reg"] is float or x["reg"] is int) and not ("REGIONS" in path):
			bad.append("%s: reg = %s" % [path, str(x["reg"])])
		for k in x:
			walk(x[k], path + "/" + str(k), depth + 1)
	elif x is Array:
		for i in x.size():
			walk(x[i], path + "[" + str(i) + "]", depth + 1)
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	var cm: Dictionary = g.get_script().get_script_constant_map()
	for k in cm:
		if k == "CDATA":
			var d: Dictionary = cm[k]
			walk(d.get(g.ccode, {}), "CDATA." + g.ccode, 0)
		else:
			walk(cm[k], k, 0)
	for p in g.get_property_list():
		if p["usage"] & 4096 and (p["type"] == TYPE_ARRAY or p["type"] == TYPE_DICTIONARY) and p["name"] != "regions":
			walk(g.get(p["name"]), "var." + p["name"], 0)
	print("%s: проблем %d" % [g.ccode, bad.size()])
	var seen := {}
	for b in bad:
		var key: String = String(b).substr(0, 90)
		if not seen.has(key):
			seen[key] = true
			if seen.size() < 8:
				print("   ", String(b).substr(0, 220))
	quit()
