extends SceneTree
# v50: снимки карточек страны и региона, окна строительства, договоров
func _init():
	var outd := "/tmp"
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="): outd = String(a).substr(4)
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 6: await process_frame
	g.show_desk(2)
	g.selected_region = 0
	g.refresh()
	for i in 8: await process_frame
	await create_timer(0.5).timeout
	await snap(outd + "/v50_region.png")
	var nb: String = "PL" if g.ccode != "PL" else "DE"
	g.select_dip(nb)
	g.map_set_mode("dip") if g.has_method("map_set_mode") else null
	g.refresh()
	for i in 8: await process_frame
	await snap(outd + "/v50_country.png")
	g.show_desk(10)
	g.refresh()
	for i in 8: await process_frame
	await create_timer(0.4).timeout
	await snap(outd + "/v50_blocs.png")
	g.treaty_sheet_open()
	for i in 8: await process_frame
	await create_timer(0.3).timeout
	await snap(outd + "/v50_treaty.png")
	g.ts_ov.visible = false
	g.project_start_at(0, "factory", -1)
	g.project_start_at(1, "power_gas", -1)
	g.wins["build"].closed = false
	g.bld_pick = "solar_wind"
	g.show_desk(2)
	g.map_zoom_t = 2.6
	g.map_zoom = 2.6
	g.refresh()
	for i in 10: await process_frame
	await create_timer(0.6).timeout
	await snap(outd + "/v50_build.png")
	quit()

func snap(p: String) -> void:
	await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png(p)
	print("saved ", p)
