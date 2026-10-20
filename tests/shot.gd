extends SceneTree
# Скриншот экрана: аргументы country=XX desk=N months=N out=путь.png (см. tools/shot.sh)
func _init():
	var desk := 6
	var months := 14
	var outp := ""
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("desk="): desk = int(String(a).substr(5))
		if String(a).begins_with("months="): months = int(String(a).substr(7))
		if String(a).begins_with("out="): outp = String(a).substr(4)
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	for m in months:
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty(): g.choose(0)
		g.next_turn()
	if g.election_open: g.election_continue()
	if not g.current_event.is_empty(): g.choose(0)
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("war="):
			g.capital = 100.0
			g.mil_declare(String(a).substr(4), true)
			for k in 40:
				if not g.current_event.is_empty(): g.choose(0)
				g.advance_day()
	g.show_desk(desk)
	# 0.55.5: gdopen=food,fuel — раскрыть подробные товары; region=N — выбрать регион на карте
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("gdopen="):
			for k in String(a).substr(7).split(","):
				g.gd_open[k] = true
			g.update_goods_windows()
		if String(a).begins_with("call="):
			g.call(String(a).substr(5))
		# 0.56: open=meas|tech|crisis — открыть окно поверх игры
		if String(a).begins_with("open="):
			match String(a).substr(5):
				"meas": g.set_meas_open(true)
				"tech": g.set_tech_open(true)
				"crisis": g.set_crisis_open(true)
				"coal": g.cn_open(true)
				"rules": g.rules_open(true)
				"help": g.help_open("tax")
				"search": g.srch_open(true)
		if String(a).begins_with("pol="):
			for kv in String(a).substr(4).split(","):
				var pr := kv.split(":")
				(g.sliders[pr[0]]["slider"] as HSlider).value = float(pr[1])
			g.refresh()
		if String(a).begins_with("org="):
			g.io["sel"] = String(a).substr(4)
			g.refresh()
		if String(a).begins_with("region="):
			g.on_region_picked(int(String(a).substr(7)))
	if desk == 6: g.ag_random_agent()
	for i in 12: await process_frame
	await create_timer(0.8).timeout
	if outp == "": outp = OS.get_temp_dir().path_join("shot_%s.png" % g.ccode)
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png(outp)
	print("saved ", outp)
	quit()
