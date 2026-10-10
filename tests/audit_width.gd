extends SceneTree
# Аудит: какие элементы шире своего окна (горизонтальный клиппинг). Аргументы country=XX; экран окна задаёт xvfb.
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	for m in 3:
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty(): g.choose(0)
		g.next_turn()
	if g.election_open: g.election_continue()
	if not g.current_event.is_empty(): g.choose(0)
	var bad := 0
	for d in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 13]:      # v38: «Армия и война» ещё раз — во время войны (переговоры)
		if d == 14 and not g.mil_targets().is_empty():
			g.mil_declare(String(g.mil_targets()[0]), true)       # v37: экраны армии и флота во время войны
			for k in 10: g.advance_day()
		g.show_desk(d)
		for i in 6: await process_frame
		for w in g.workspace.get_children():
			if not (w is Control) or not (w as Control).is_visible_in_tree():
				continue
			var body = w.get("body")
			if body == null: continue
			var lim: float = (w as Control).size.x - 22.0
			_walk(body, lim, str(d), String(w.get("title_text") if w.get("title_text") != null else w.name))
	print("audit done")
	quit()
func _walk(n: Node, lim: float, desk: String, wn: String) -> bool:
	for ch in n.get_children():
		if ch is Control and (ch as Control).is_visible_in_tree():
			var c := ch as Control
			if c.get_combined_minimum_size().x > lim + 2.0 and not (c is ScrollContainer):
				if not _walk(c, lim, desk, wn):
					var txt := ""
					if "text" in c: txt = str(c.get("text")).substr(0, 40)
					for k in c.get_children():
						if "text" in k: txt += "|" + str(k.get("text")).substr(0, 20)
					print("FAIL: WIDE desk=%s %s min=%.0f lim=%.0f text=%s parent=%s" % [desk, c.get_class(), c.get_combined_minimum_size().x, lim, txt, c.get_parent().get_class()])
				return true
		elif _walk(ch, lim, desk, wn):
			return true
	return false
