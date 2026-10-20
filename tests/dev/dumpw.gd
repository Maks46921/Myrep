extends SceneTree
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	print("W ", g.WORLD["DE"])
	print("C ", g.CDATA.keys().slice(0,5) if g.get("CDATA") != null else "")
	quit()
