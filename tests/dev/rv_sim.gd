extends SceneTree
# Прогон системы кризисов: godot --headless --path . --script tests/dev/rv_sim.gd -- country=ES years=30 seed=5 pick=0 revev=1
func _init():
	var years := 30
	var seed := 5
	var pick := 0
	var revev := 1
	var boost := 0.0
	var lowloy := false
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("years="): years = int(String(a).substr(6))
		if String(a).begins_with("seed="): seed = int(String(a).substr(5))
		if String(a).begins_with("pick="): pick = int(String(a).substr(5))
		if String(a).begins_with("revev="): revev = int(String(a).substr(6))
		if String(a).begins_with("boost="): boost = float(String(a).substr(6))
		if String(a) == "lowloy": lowloy = true
	var g = load("res://main.gd").new()
	g.game_opts.merge({"agents": true, "seed": seed, "fedev": 0, "socev": 0, "exev": 0, "milev": 0, "revev": revev}, true)
	root.add_child(g)
	for i in 5: await process_frame
	g.ap["bal"] = true
	var maxst := 0
	var stage_months := [0, 0, 0, 0, 0]
	var events := {}
	for m in years * 12:
		if g.game_over: break
		if g.election_open: g.election_continue()
		while not g.current_event.is_empty():
			var ev: Dictionary = g.current_event
			var k := String(ev.get("rvk", "-"))
			events[k] = int(events.get(k, 0)) + 1
			g.choose(clampi(pick, 0, (ev["o"] as Array).size() - 1))
			if g.game_over: break
		g.capital = maxf(g.capital, 20.0)
		if boost > 0.0:
			for rr in g.regions:
				rr["unrest"] = minf(100.0, float(rr["unrest"]) + boost)
				if lowloy:
					rr["loy"] = maxf(0.0, float(rr["loy"]) - boost * 0.8)
		g.next_turn()
		for i in g.regions.size():
			var st: int = int(g.rv_reg(i)["stage"])
			stage_months[st] += 1
			maxst = maxi(maxst, st)
	var nat: Dictionary = g.rv["nat"]
	print("RV|%s|seed %d|pick %d|лет %d|макс.стадия %d|мес. по стадиям %s|события %s|конфликтов активно %d|независимых %d|wave %.0f rev %.0f coup %.0f|конец: %s" % [g.ccode, seed, pick, g.turn / 12, maxst, str(stage_months), str(events), g.rv["conf"].size(), g.rv["states"].size(), nat["wave"], nat["rev"], nat["coup"], g.end_reason if g.game_over else "-"])
	for l in g.rv["log"].slice(-6):
		print("   ", String(l).replace("[b]", "").replace("[/b]", ""))
	quit()
