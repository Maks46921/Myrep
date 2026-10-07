extends SceneTree
func _init():
	root.size = Vector2i(1700, 900)
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	var shot := false
	var stage := "elec"
	for a in OS.get_cmdline_user_args():
		if a == "shot": shot = true
		if a.begins_with("stage="): stage = a.substr(6)
	g.show_desk(1)
	var term: int = g.parl_term()
	if stage == "reg":
		g.current_event = g.REG_EVENTS_GEN[0]
		g.event_region = 3
		g.present_event()
		for i in 8: await process_frame
		await create_timer(0.5).timeout
		root.get_texture().get_image().save_png("/tmp/s17_%s_reg.png" % g.ccode)
		quit(); return
	if stage == "hemi":
		g.show_desk(1)
		for i in 8: await process_frame
		await create_timer(0.5).timeout
		root.get_texture().get_image().save_png("/tmp/s18_%s_hemi.png" % g.ccode)
		quit(); return
	if stage == "pres":
		g.last_nocon = g.turn + 100
		g.pres_due = g.turn
		if String(g.ELEC["head"]) == "council":
			g.last_parl = g.turn - term + 1
			g.next_turn()
			g.election_continue()
			g.pres_due = g.turn
		g.next_turn()
		if g.election_open == false and not g.current_event.is_empty():
			g.choose(0)
			g.next_turn()
		print("окно главы: ", g.election_open)
		await create_timer(4.2).timeout
		for i in 6: await process_frame
		root.get_texture().get_image().save_png("/tmp/s18_%s_pres.png" % g.ccode)
		quit(); return
	if stage == "camp":
		g.last_parl = g.turn - (term - 3)
		g.last_nocon = g.turn + 100
		g.next_turn()
		# кампания срабатывает в конце хода
		print("событие: ", g.current_event.get("kind", "нет"), " | ", String(g.current_event.get("t", "")).substr(0, 90))
		for i in 8: await process_frame
		if shot:
			await create_timer(0.5).timeout
			root.get_texture().get_image().save_png("/tmp/s17_%s_camp.png" % g.ccode)
		g.choose(1)
		print("кампания выбрана, капитал ", g.capital)
		quit(); return
	g.last_parl = g.turn - term + 1
	g.next_turn()
	print("выборы открыты: ", g.election_open, " места ", g.seats)
	await create_timer(2.8).timeout
	for i in 6: await process_frame
	if shot:
		root.get_texture().get_image().save_png("/tmp/s18_%s_elec.png" % g.ccode)
	g.election_continue()
	print("после: open ", g.election_open, " game_over ", g.game_over, " next_btn disabled ", g.next_btn.disabled)
	for i in range(3):
		g.next_turn()
	print("turn ", g.turn)
	quit()
