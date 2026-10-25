extends SceneTree
var n := 0
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 10: await process_frame
	g.show_desk(2)
	for i in 10: await process_frame
	g.map_cv.draw.connect(func(): n += 1)
	for i in 60: await process_frame
	print("ИДЛ перерисовок за 60 кадров: ", n)
	n = 0
	g.map_zoom_at(g.map_ctl.size * 0.5, 1.35)
	for i in 60: await process_frame
	print("ЗУМ перерисовок за 60 кадров: ", n, " зум ", g.map_zoom)
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png("/tmp/mapdbg.png")
	quit()
