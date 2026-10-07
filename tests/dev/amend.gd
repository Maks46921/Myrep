extends SceneTree
# dev: поправки смягчения/усиления законопроекта
func _init():
	var g = load("res://main.gd").new()
	g.game_opts.merge({"ev": 0.0, "news": 0.0}, true)
	root.add_child(g)
	for i in 3: await process_frame
	g.capital = 100.0
	var tid := ""
	for t in g.law_index:
		if g.is_hybrid(t) and g.cur_idx(t) == 0 and g.law_locked(t) == "" and g.radical_req(t, 1) == "":
			tid = t
			break
	print("tid ", tid, " hybrid ", g.is_hybrid(tid))
	g.propose_variant(tid, 1)
	print("bills ", g.bills.size())
	var bid: int = g.bill_sel
	print("pow0 ", g.bills[0]["pow"], " v ", g.bill_preview(g.bills[0])["yes"])
	print("soft ", g.bill_amend(bid, "soft"), " pow ", g.bills[0]["pow"], " v ", g.bill_preview(g.bills[0])["yes"])
	print("hard ", g.bill_amend(bid, "hard"), " hard ", g.bill_amend(bid, "hard"), " pow ", g.bills[0]["pow"], " v ", g.bill_preview(g.bills[0])["yes"])
	g.update_bill_window()
	print("btn soft disabled ", g.bill_am["soft"].disabled, " hard ", g.bill_am["hard"].disabled)
	for m in 6:
		if not g.current_event.is_empty(): g.choose(0)
		g.next_turn()
	print("cur ", g.cur_idx(tid), " law_pow ", g.law_pow.get(tid, -1))
	quit()
