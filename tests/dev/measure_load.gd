extends SceneTree
# замер нагрузки: законопроекты ИИ-партий и записи журнала за 24 месяца
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	g.capital = 80.0
	var maxb := 0
	var sumb := 0
	var created := 0
	var seen := {}
	var logs0: int = g.log_entries.size()
	for m in 24:
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty(): g.choose(0)
		g.next_turn()
		maxb = maxi(maxb, g.bills.size())
		sumb += g.bills.size()
		for b in g.bills:
			if bool(b.get("pa", false)) and not seen.has(int(b["id"])):
				seen[int(b["id"])] = 1
				created += 1
	print("MEASURE bills_max ", maxb, " bills_avg ", snappedf(float(sumb) / 24.0, 0.1), " ai_created_24m ", created, " log_per_month ", snappedf(float(g.log_entries.size() - logs0) / 24.0, 0.1))
	quit()
