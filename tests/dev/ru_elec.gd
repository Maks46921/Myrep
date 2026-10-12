extends SceneTree
# Отладка: как держится партия власти в недемократической стране (по умолчанию Россия) — итоги выборов за N лет.
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	var yrs := 15
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("years="): yrs = int(String(a).substr(6))
	print("%s режим %s, индекс демократии %.2f, фальсификации %.0f, места партии 0: %d/%d, opp %s" % [g.ccode, g.au.get("cls", "?"), g.democracy_index(), float(g.au.get("fraud", 0.0)), g.seats[0], g.SEATS, g.opp_mode])
	var lp: int = g.last_parl
	for i in yrs * 12:
		if g.game_over:
			break
		if not g.current_event.is_empty():
			g.choose(randi() % g.current_event["o"].size())
		if g.election_open:
			g.election_continue()
		g.next_turn()
		if g.election_open:
			g.election_continue()
		if g.last_parl != lp:
			lp = g.last_parl
			var top := 0
			for p in g.seats.size():
				if g.seats[p] > g.seats[top]: top = p
			print("  %s: выборы — места %s; первая %s (%d), рейтинг %.0f, режим %s, comp_loss %.2f, opp %s" % [g.date_text(), str(g.seats), g.PARTY_NAMES[top].substr(0, 30), g.seats[top], g.approval(), g.au.get("cls", "?"), g.comp_loss, g.opp_mode])
	print("итог: ход %d, конец %s (%s)" % [g.turn, g.game_over, g.end_reason.substr(0, 60)])
	quit()
