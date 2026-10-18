extends SceneTree
# 0.56: симуляция 30 лет одной страны под ИИ-управлением событий (первый вариант), вывод в .testlogs/sim30_XX.tsv
func _init():
	var years := 30
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("years="): years = int(String(a).substr(6))
	var m0 = load("res://main.gd")
	var g = m0.new()
	g.game_opts.merge({"ev": 1.0, "news": 1.0, "agents": false}, true)
	root.add_child(g)
	for i in 3: await process_frame
	var cc: String = g.ccode
	var f := FileAccess.open("res://.testlogs/sim30_%s.tsv" % cc, FileAccess.WRITE)
	var hdr := "year\tgdp\tgrowth\tinfl\tunemp\tdebt_pct\tapproval\topp_mode\tgame_over\tcoalition_seats\t" + "\t".join(PackedStringArray(g.PARTY_NAMES.map(func(n): return String(n).replace("\t", " "))))
	f.store_line(hdr)
	var last_parl: int = -1
	var elections: Array = []
	for m in years * 12:
		if g.election_open:
			g.election_continue()
		var guard := 0
		while not g.current_event.is_empty() and guard < 5:
			g.choose(0)
			guard += 1
		g.next_turn()
		if g.game_over:
			break
		if g.last_parl != last_parl:
			last_parl = g.last_parl
			elections.append(g.turn)
			var s := "%d\t%.0f\t%.1f\t%.1f\t%.1f\t%.0f\t%.0f\t%s\t%s\t%d" % [g.turn / 12, g.gdp, g.growth, g.inflation, g.unemployment, g.debt / g.gdp * 100.0, g.approval(), str(g.opp_mode), str(g.game_over), g.gov_seats()]
			for sh in g.prev_vote:
				s += "\t%.1f" % (float(sh) * 100.0)
			f.store_line("ELECTION\t" + s)
		if m % 12 == 11:
			var sh2 = g.national_shares(false)
			var s2 := "%d\t%.0f\t%.1f\t%.1f\t%.1f\t%.0f\t%.0f\t%s\t%s\t%d" % [g.turn / 12, g.gdp, g.growth, g.inflation, g.unemployment, g.debt / g.gdp * 100.0, g.approval(), str(g.opp_mode), str(g.game_over), g.gov_seats()]
			for x in sh2:
				s2 += "\t%.1f" % (float(x) * 100.0)
			f.store_line(s2)
	f.store_line("END\tturn=%d\tgame_over=%s\telections=%d" % [g.turn, str(g.game_over), elections.size()])
	f.close()
	quit()
