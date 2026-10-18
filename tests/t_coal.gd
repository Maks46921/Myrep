extends SceneTree
# v53: коалиционные переговоры после выборов (coal=1): партнёры не добавляются сами, игрок приглашает их через окно переговоров.
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	g.game_opts["coal"] = 1
	var bad := 0
	var tries := 0
	var talks := 0
	var formed := 0
	for k in 4:
		g.hold_parliament("проверка переговоров")
		if g.election_open:
			g.election_continue()
		if g.opp_mode or g.game_over:
			print("  выборы %d: оппозиция/конец игры — пропуск" % k)
			continue
		var partners := 0
		for p in range(1, g.PARTY_NAMES.size()):
			if g.in_coalition[p]:
				partners += 1
		if g.coal_talks:
			talks += 1
			if partners > 0:
				bad += 1; print("FAIL: партнёры вошли в коалицию сами, до переговоров")
			# 0.56: вместо события открывается большое окно «Коалиционные переговоры»
			if not g.cn_is_open():
				bad += 1; print("FAIL: нет окна переговоров после выборов")
			# собираем проект: добавляем самых сговорчивых, пока хватает мест, и предлагаем по раундам
			var guard := 0
			g.cn_ensure()
			while g.coal_talks and guard < 12:
				guard += 1
				tries += 1
				if g.cn_block() != "":
					var best := -1
					var bw := -1e9
					for p in range(1, g.PARTY_NAMES.size()):
						if g.seats[p] > 0 and g.can_govern(p) and g.cn_can_talk(p) and not (g.cn_draft["parties"] as Array).has(p):
							var w: float = g.willingness(p, false)
							if w > bw: bw = w; best = p
					if best < 0: break
					g.cn_toggle_party(best)
					g.cn_auto_mins()
					continue
				g.capital = maxf(g.capital, 60.0)
				g.cn_propose()
			if g.cn_is_open(): g.cn_open(false)
			if g.gov_ok():
				formed += 1
				if g.coal_talks:
					bad += 1; print("FAIL: большинство собрано, а переговоры не закончились")
			print("  выборы %d: мест у вас %d, коалиция %d из %d, нужно %d, приглашений %d, сформировано %s" % [k, g.seats[0], g.gov_seats(), g.SEATS, g.MAJORITY, guard, g.gov_ok()])
		else:
			print("  выборы %d: переговоры не понадобились (мест %d, коалиция %d, gov_ok %s)" % [k, g.seats[0], g.gov_seats(), g.gov_ok()])
		g.current_event = {}
		for m in 3:
			g.next_turn()
			if g.election_open:
				g.election_continue()
			if not g.current_event.is_empty():
				g.choose(0)
	print("%s: переговоров %d, сформировано %d, приглашений %d" % [g.ccode, talks, formed, tries])
	print("коалиция: проблем %d" % bad)
	quit()
