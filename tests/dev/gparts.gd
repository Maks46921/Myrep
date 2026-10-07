extends SceneTree
# разложение целевого роста по слагаемым в длинном пассивном прогоне
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	for m in 360:
		if g.game_over: break
		if g.election_open: g.election_continue()
		var guard := 0
		while not g.current_event.is_empty() and guard < 5:
			g.choose(0); guard += 1
		g.next_turn()
		if g.election_open: g.election_continue()
		if m % 24 == 0:
			var b = g.compute_budget()
			var dp: float = -float(b["balance"]) / g.gdp * 100.0
			print("m%d g %.2f lvl %.2f def %.2f(%.1f-%.1f) gb %.2f ecg %.2f unr %.1f ws %.2f soc %.2f ex %.2f infl5 %.2f debt90 %.2f | pot %.3f inv %.3f bconf %.0f util %.3f cconf %.0f ppi %.3f rw %.3f u %.1f rate %.2f" % [m, g.growth, g.lvl_sum("growth"), (dp - g.def0) * 0.2, dp, g.def0, float(g.mods["growth_bonus"]), float(g.last_ecf.get("g", 0)), g.reg_avg("unrest"), g.world_spill_g(), g.soc_g(), g.ex_g(), -maxf(0, g.inflation - 5) * 0.2, -maxf(0, g.debt / g.gdp * 100 - 90) * 0.02, g.regional_potential() / g.pot0, float(g.ec["inv"]), float(g.ec["bconf"]), float(g.ec["util"]), float(g.ec["cconf"]), float(g.ec["ppi"]), float(g.ec["rw"]), g.unemployment, float(g.ec["rate"])])
	quit()
