extends SceneTree
# стартовая загрузка мощностей и импорт по рынкам (проверка калибровки)
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	g.next_turn()
	var s := "UTIL %s util %.3f util0 %.3f k0 %.2f ecg %.2f |" % [g.ccode, float(g.ec["util"]), float(g.ec["util0"]), float(g.ec["k0"]), float(g.ec["ec_g"])]
	for m in g.MARKETS:
		var mk: Dictionary = g.ec["mk"][m["id"]]
		s += " %s u%.2f imp0 %.2f" % [m["id"], float(mk["u"]), float(m["imp"]) * float(g.ec["k0"])]
	print(s)
	quit()
