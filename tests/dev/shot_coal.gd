extends SceneTree
# 0.59: после выборов открывается окно коалиционных переговоров (скриншот). Аргументы country=XX coal=1 out=путь
func _init():
	var g = load("res://main.gd").new()
	g.game_opts["coal"] = 1
	root.add_child(g)
	for i in 5: await process_frame
	var outp := "/tmp/shot_coal.png"
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="): outp = String(a).substr(4)
	var tries := 0
	while tries < 6 and not g.coal_talks:
		tries += 1
		g.hold_parliament("проверка")
		print("выборы: open=", g.election_open, " talks=", g.coal_talks, " gov_ok=", g.gov_ok(), " seats0=", g.seats[0])
		for i in 8: await process_frame
		if g.election_open:
			var img0: Image = root.get_viewport().get_texture().get_image()
			img0.save_png(outp.replace(".png", "_elec.png"))
			g.election_continue()
	for i in 20: await process_frame
	await create_timer(0.6).timeout
	print("coal_talks=", g.coal_talks, " cn_is_open=", g.cn_is_open(), " game_opts.coal=", g.game_opts["coal"], " opp=", g.opp_mode)
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png(outp)
	print("saved ", outp)
	quit()
