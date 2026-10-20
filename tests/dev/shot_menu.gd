extends SceneTree
# dev: скриншот окна выбора страны и партии: cc=DE party=2 out=путь
func _init():
	var cc := "DE"
	var party := 2
	var outp := "/tmp/shot_menu.png"
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("cc="): cc = String(a).substr(3)
		if String(a).begins_with("party="): party = int(String(a).substr(6))
		if String(a).begins_with("out="): outp = String(a).substr(4)
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	g.show_country_menu(false)
	for i in 5: await process_frame
	g.menu_sit_code = cc
	g.menu_fill_parties(cc, party)
	for i in 10: await process_frame
	await create_timer(0.5).timeout
	var tc: Array = g.find_children("*", "TabContainer", true, false)
	for t in tc:
		(t as TabContainer).current_tab = 1
	for i in 5: await process_frame
	root.get_viewport().get_texture().get_image().save_png(outp)
	print("saved ", outp)
	for t in tc:
		(t as TabContainer).current_tab = 1
	for sc in g.find_children("*", "ScrollContainer", true, false):
		(sc as ScrollContainer).scroll_vertical = 100000
	for i in 5: await process_frame
	root.get_viewport().get_texture().get_image().save_png(outp.replace(".png", "_b.png"))
	quit()
