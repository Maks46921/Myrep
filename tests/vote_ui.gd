extends SceneTree
# 0.57.1: окно голосования — выбор стратегии и итог. Аргументы: kind=own|other tid=.. idx=N out=/путь/префикс
func _init():
	var kind := "own"
	var tid := "elect_threshold"
	var idx := 1
	var outp := "/tmp/vote_ui"
	var mode := 0
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("kind="): kind = String(a).substr(5)
		if String(a).begins_with("tid="): tid = String(a).substr(4)
		if String(a).begins_with("idx="): idx = int(String(a).substr(4))
		if String(a).begins_with("out="): outp = String(a).substr(4)
		if String(a).begins_with("mode="): mode = int(String(a).substr(5))
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	for m in 14:
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty(): g.choose(0)
		g.next_turn()
	if g.election_open: g.election_continue()
	if not g.current_event.is_empty(): g.choose(0)
	g.capital = 100.0
	if idx < 0: idx = g.law_index[tid]["v"].size() - 1
	g.game_opts["voteplan"] = true
	if kind == "own":
		g.propose_variant(tid, idx)
	else:
		var sp := 0
		for p in range(1, g.PARTY_NAMES.size()):
			if g.seats[p] > 0 and sp == 0: sp = p
		g.bill_seq += 1
		g.bills.append({"id": g.bill_seq, "tid": tid, "idx": idx, "sponsor": sp, "start": g.turn, "due": g.turn, "forced": [], "pow": 1.0, "req": [], "paid": 0.0, "did": {}, "pa": true, "pv": "line"})
	if kind == "own":
		g.bills = g.bills.filter(func(b): return int(b["sponsor"]) == 0)
	print("BILLS ", g.bills.size(), " ", g.bills.map(func(b): return [b["tid"], b["sponsor"], b["due"]]))
	if g.bills.is_empty():
		print("NO BILLS")
		quit()
		return
	for b in g.bills: b["due"] = g.turn
	g.bills_step()
	print("STAGE ", g.vt_stage, " busy ", g.vt_plan_busy())
	for i in 8: await process_frame
	await create_timer(0.5).timeout
	root.get_viewport().get_texture().get_image().save_png(outp + "_plan0.png")
	if kind == "own":
		g.vt_mode = mode
		if mode == 1:
			var b: Dictionary = g.bills[0]
			for p in g.bill_swing_parties(b):
				g.vt_deals.append(int(p))
		if mode == 2:
			var b2: Dictionary = g.bills[0]
			for p in g.bill_swing_parties(b2):
				if g.bill_press_ok(int(p)): g.vt_press.append(int(p))
		g.vote_plan_refresh()
		for i in 6: await process_frame
		root.get_viewport().get_texture().get_image().save_png(outp + "_plan1.png")
	g.vote_plan_go()
	print("STAGE after go ", g.vt_stage)
	await create_timer(0.9).timeout
	root.get_viewport().get_texture().get_image().save_png(outp + "_mid.png")
	await create_timer(2.2).timeout
	root.get_viewport().get_texture().get_image().save_png(outp + "_res.png")
	g.vt_next_btn.pressed.emit()
	await create_timer(0.3).timeout
	root.get_viewport().get_texture().get_image().save_png(outp + "_next.png")
	print("PASSED ", g.vt_data.get("passed"), " ", g.vt_data.get("yes"), "/", g.vt_data.get("need"))
	quit()
