extends SceneTree
# Эмиссия: недоступна в еврозоне, доступна при своей валюте и после выхода из еврозоны/ЕС.
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	var own: bool = not bool(g.MACRO.get("euro", true))
	g.sync_emit()
	var shown: bool = (g.sliders["emit"]["box"] as Control).visible
	print("[%s] евро %s, эмиссия доступна %s, ползунок виден %s, предел %.1f" % [g.ccode, not own, g.emit_cap() > 0.0, shown, g.emit_cap()])
	if shown != (g.emit_cap() > 0.0) or (g.emit_cap() > 0.0) != own: print("FAIL: эмиссия не соответствует валюте")
	if own:
		g.set_policy("emit", 1.5)
		g.recompute_mods()
		print("  эмиссия 1.5%% ВВП: значение %.1f" % g.pol["emit"])
		if float(g.pol["emit"]) != 1.5: print("FAIL: эмиссию нельзя выставить")
	else:
		g.MACRO["euro"] = false
		g.MACRO["eu"] = false
		g.sync_emit()
		g.set_policy("emit", 1.0)
		print("  после выхода: предел %.1f, значение %.1f, ползунок виден %s" % [g.emit_cap(), g.pol["emit"], (g.sliders["emit"]["box"] as Control).visible])
		if g.emit_cap() <= 0.0 or float(g.pol["emit"]) != 1.0: print("FAIL: после выхода эмиссия недоступна")
	g.next_turn()
	print("  месяц ок, инфляция %.2f" % g.inflation)
	quit()
