extends SceneTree
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	for t in g.LAW_TOPICS:
		if t.has("param"): continue
		var ns: Array = []
		for v in t["v"]: ns.append(String(v["n"]))
		print("T ", t["id"], " | ", " / ".join(ns))
	quit()
