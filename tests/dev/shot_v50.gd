extends SceneTree
# v50: снимки — стартовое окно, настройки, затемнённые окна в оппозиции, вкладка технологий
func _init():
	var outd := "/tmp"
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="): outd = String(a).substr(4)
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 6: await process_frame
	g.show_start_window()
	for i in 6: await process_frame
	await create_timer(0.6).timeout
	await snap(outd + "/v50_start.png")
	if g.start_ov != null:
		g.start_ov.queue_free()
		g.start_ov = null
	g.settings_open(true)
	for i in 6: await process_frame
	await create_timer(0.4).timeout
	await snap(outd + "/v50_settings.png")
	g.st_tabs.current_tab = 2
	for i in 6: await process_frame
	await snap(outd + "/v50_saves.png")
	g.settings_open(false)
	g.opp_enter("проверка")
	g.show_desk(0)
	g.refresh()
	for i in 10: await process_frame
	await create_timer(0.6).timeout
	await snap(outd + "/v50_opp_budget.png")
	g.show_desk(5)
	g.refresh()
	for i in 10: await process_frame
	await create_timer(0.6).timeout
	await snap(outd + "/v50_econ.png")
	quit()

func snap(p: String) -> void:
	await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png(p)
	print("saved ", p)
