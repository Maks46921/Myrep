extends SceneTree
# v49: снимки новой графики: out=префикс country=XX foe=YY.
# own — карта с розой ветров и линейкой; dip — окно чужой страны с флагом; event — событие с флагом страны; menu — меню.
func snap(name: String, outp: String) -> void:
	for i in 6: await process_frame
	await create_timer(0.9).timeout
	root.get_viewport().get_texture().get_image().save_png("%s_%s.png" % [outp, name])
	print("saved ", name)

func _init():
	var outp := "/tmp/v49"
	var foe := "PL"
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="): outp = String(a).substr(4)
		if String(a).begins_with("foe="): foe = String(a).substr(4)
	var g = load("res://main.gd").new()
	g.game_opts.merge({"ev": 0.0, "news": 0.0}, true)
	root.add_child(g)
	for i in 5: await process_frame
	g.show_desk(2)
	for i in 3: await process_frame
	g.map_zoom_cmd(3)
	await snap("own", outp)
	# окно чужой страны
	for ui in g.WORLD_UNITS.size():
		if String(g.WORLD_UNITS[ui]["cc"]) == foe:
			g.map_click(ui)
			break
	await snap("dip", outp)
	# событие с флагом страны
	g.rl_event("fa_aid", "«%s» предлагает помощь в трудный момент: льготный кредит и экспертов. Условия — прозрачность и реформы." % String(g.WORLD[foe]["name"]), [
		{"l": "Принять помощь", "fx": {}, "act": "fa_aid_yes", "arg": foe},
		{"l": "Поблагодарить и отказаться", "fx": {}, "act": "fa_aid_no", "arg": foe}])
	await snap("event", outp)
	quit()
