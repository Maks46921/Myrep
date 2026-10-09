extends SceneTree
var g
func _init():
	var s = load("res://main.gd")
	g = s.new()
	root.add_child(g)
	await process_frame
	await process_frame
	var b: Dictionary = g.compute_budget()
	print("ВВП ", g.gdp, " доходы %.1f%% расходы %.1f%% баланс %.1f%% долг %.1f%% проценты %.2f%%" % [b["revenue"]/g.gdp*100, b["spending"]/g.gdp*100, b["balance"]/g.gdp*100, g.debt/g.gdp*100, b["interest"]/g.gdp*100])
	for k in b["rev"]: print("  дох ", k, " %.2f" % (b["rev"][k]/g.gdp*100))
	for k in b["exp"]: print("  рас ", k, " %.2f" % (b["exp"][k]/g.gdp*100))
	var sh = g.national_shares(false)
	var t := ""
	for p in range(10): t += "%s %.1f  " % [g.PARTY_NAMES[p], sh[p]*100]
	print(t)
	print("места ", g.seats, " коалиция ", g.gov_seats(), " рейтинг %.1f" % g.approval())
	print("def0 ", g.def0, " growth ", g.growth, " rate ", g.ec["rate"])
	var n := 24
	for a in OS.get_cmdline_user_args():
		if String(a).is_valid_int():
			n = int(a)
	for i in range(n):
		if not g.current_event.is_empty():
			g.choose(0)
		if g.election_open:
			g.election_continue()
		g.next_turn()
		if g.game_over:
			print("КОНЕЦ: ", g.end_reason); break
		if i % 6 == 5:
			var sh2 = g.national_shares(false)
			var bb: Dictionary = g.compute_budget()
			print("м%d: рост %.2f инфл %.2f безр %.2f рейтинг %.1f ставка %.2f дефицит %.2f%% долг %.1f%% ХДС %.1f АдГ %.1f СДПГ %.1f unrest %.1f loy %.1f" % [g.turn, g.growth, g.inflation, g.unemployment, g.approval(), g.ec["rate"], -bb["balance"]/g.gdp*100, g.debt/g.gdp*100, sh2[0]*100, sh2[9]*100, sh2[1]*100, g.reg_avg("unrest"), g.reg_avg("loy")])
	quit()
