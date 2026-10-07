extends SceneTree
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	print("GP %s G_POT %.2f G_NEU %.2f gb %.2f growth %.2f" % [g.ccode, g.G_POT, g.G_NEU, float(g.mods["growth_bonus"]), g.growth])
	quit()
