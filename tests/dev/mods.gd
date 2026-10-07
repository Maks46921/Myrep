extends SceneTree
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	var ks: Array = g.mods.keys()
	ks.sort()
	for k in ks:
		print("MOD %s %s" % [k, str(g.mods[k])])
	var b: Dictionary = g.compute_budget()
	for k in b:
		if typeof(b[k]) == TYPE_FLOAT: print("BUD %s %.2f" % [k, b[k]])
	quit()
