extends SceneTree
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	var lay: Dictionary = g.ElectionView.hemi_layout(g.SEATS)
	var pts: Array = lay["pts"]
	var mind := 1e9
	var R := 100.0
	var ps: Array = []
	for p in pts:
		ps.append(Vector2(cos(p[0]), -sin(p[0])) * R * p[1])
	for i in ps.size():
		for j in range(i + 1, ps.size()):
			mind = minf(mind, ps[i].distance_to(ps[j]))
	var dot: float = R * float(lay["rad"])
	print("[%s] места %d ряды %d точек %d  мин.расстояние %.2f  диаметр точки %.2f  отношение %.2f" % [g.ccode, g.SEATS, lay["rows"], pts.size(), mind, dot * 2.0, mind / (dot * 2.0)])
	print("  глава: ", g.ELEC["head"], " pres_due ", g.pres_due)
	# парламентские выборы
	var nopar := "nopar" in OS.get_cmdline_user_args()
	if not nopar:
		g.last_parl = g.turn - g.parl_term() + 1
	g.last_nocon = g.turn + 100
	g.next_turn()
	print("  парл. выборы окно: ", g.election_open, " мест всего ", g.seats.reduce(func(a, b): return a + b), " meta: ", g.el_meta.text.substr(0, 100))
	if g.election_open:
		g.election_continue()
	if g.game_over:
		print("  game over после парл. выборов: ", g.end_reason.substr(0, 80))
		quit(); return
	var kind: String = g.ELEC["head"]
	if kind == "monarch":
		print("  монархия: выборов главы нет, pres_due ", g.pres_due)
		quit(); return
	if kind != "council":
		g.pres_due = g.turn + 2
		g.last_nocon = g.turn + 100
		if not nopar:
			g.last_parl = g.turn
		var ev_seen := false
		for i in 3:
			g.next_turn()
			if not g.current_event.is_empty():
				print("  событие: ", g.current_event.get("kind", ""), " | ", String(g.current_event["t"]).substr(0, 70))
				ev_seen = true
				g.choose(0)
			if g.election_open:
				print("  президентские: заголовок ", g.el_title.text, " | раундов ", g.el_head.rounds.size(), " | вердикт ", g.el_verdict_title.text)
				for rd in g.el_head.rounds:
					var s := "    " + String(rd["title"]) + ": "
					for r in rd["rows"]:
						s += "%s %.1f%%%s; " % [String(r["name"]).substr(0, 16), float(r["val"]) * 100.0, "*" if r.get("win", false) else ""]
					print(s)
				g.election_continue()
				break
		print("  кампания была: ", ev_seen, " следующие выборы в ход ", g.pres_due, " (сейчас ", g.turn, ") президент-партия ", g.pres_party)
	else:
		# Швейцария: совет через 2 месяца после выборов
		g.last_nocon = g.turn + 100
		print("  pres_due после парл. выборов: ", g.pres_due, " ход ", g.turn)
		for i in 8:
			if not g.current_event.is_empty():
				g.choose(0)
			g.next_turn()
			if g.election_open:
				print("  выборы, pres_due ", g.pres_due, " ход ", g.turn)
				if g.el_head.visible:
					print("  Совет: ", g.el_verdict_title.text)
				g.election_continue()
	quit()
