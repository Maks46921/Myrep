extends SceneTree
# 0.59: окно голосования в длинной партии: сколько голосований прошло и сколько раз открылось окно (voteplan=1)
func _init():
	var g = load("res://main.gd").new()
	g.game_opts["voteplan"] = true
	g.game_opts.merge({"ev": 1.0, "news": 1.0}, true)
	root.add_child(g)
	for i in 4: await process_frame
	seed(5)
	var votes := 0
	var shown := 0
	var plan_shown := 0
	var months := 48
	var orig_adopt_cnt := 0
	for m in months:
		if g.election_open: g.election_continue()
		if g.coal_talks and g.cn_is_open(): g.cn_open(false)
		if not g.current_event.is_empty(): g.choose(0)
		var lv0 = g.last_vote.duplicate()
		g.advance_month()
		for k in 6:
			await process_frame
			if g.vt_stage == 1:
				plan_shown += 1
				g.vote_plan_go()
				await process_frame
			if g.vt_stage == 2 or g.vt_stage == 3:
				shown += 1
				g.vt_ov.visible = true
				g.vote_btn_pressed()
				if g.vt_t < 1.0: g.vote_btn_pressed()
		if g.last_vote != lv0 and not g.last_vote.is_empty():
			votes += 1
	print("месяцев %d, голосований с итогом %d, окон выбора %d, окон итога %d, законопроектов в очереди %d" % [months, votes, plan_shown, shown, g.bills.size()])
	quit()
