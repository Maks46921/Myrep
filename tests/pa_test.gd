extends SceneTree
# 0.56: проверка самостоятельных действий партий (country=DE): квартальные действия, предложения министров, чужие законопроекты
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	g.capital = 80.0
	var voted := false
	for m in 9:
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty(): g.choose(0)
		g.next_turn()
		for b in g.bills:
			if bool(b.get("pa", false)) and not voted:
				print("pa bill ", b["tid"], " sponsor ", b["sponsor"], " line ", g.pa_line(b))
				g.pa_set_vote(int(b["id"]), "free")
				voted = true
		if g.pa_props.size() > 0 and m == 4:
			var pr = g.pa_props[0]
			print("veto prop ", g.pa_prop_text(pr), " cost ", g.pa_veto_cost(int(pr["p"])))
			g.pa_veto_prop(int(pr["id"]))
	var tags := {}
	for e in g.log_entries:
		var tg := String(e.get("tag", ""))
		tags[tg] = int(tags.get(tg, 0)) + 1
	print("tags ", tags)
	for e in g.log_entries:
		var tg := String(e.get("tag", ""))
		if tg in ["МИНИСТР", "ПАРТНЁР", "ОППОЗИЦИЯ", "ЗАКОНОПРОЕКТ", "ФРАКЦИЯ", "ВЕТО", "КОАЛИЦИЯ"]:
			print("LOG [", tg, "] ", String(e.get("t", "")).left(230))
	print("pl_disc ", g.pl_disc)
	quit()
