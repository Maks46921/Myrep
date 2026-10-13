extends SceneTree
# dev: 5 лет без вмешательства игрока; печатает по годам долю протестующих агентов, среднее недовольство регионов,
# максимальную стадию протестов в регионах и рейтинг. Строки AGL|год|протест|недовольство|макс.стадия|рейтинг
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	var months := 60
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("months="): months = int(String(a).substr(7))
	for m in months:
		while not g.current_event.is_empty(): g.choose(0)
		if g.election_open: g.election_continue()
		g.next_turn()
		if (m + 1) % 12 == 0:
			var pr := 0
			if g.AG != null:
				for i in g.AG.n: pr += g.AG.prot[i]
			var un := 0.0
			for r in g.regions.size(): un += float(g.regions[r].get("unrest", 0.0))
			un /= float(maxi(1, g.regions.size()))
			var ms := 0
			if not g.rv.is_empty():
				for uid in g.rv["r"]: ms = maxi(ms, int(g.rv["r"][uid]["stage"]))
			print("AGL|%d|%.3f|%.1f|%d|%.1f" % [(m + 1) / 12, float(pr) / float(maxi(1, g.AG.n if g.AG != null else 1)), un, ms, float(g.approval())])
			if g.AG != null and "trust" in g.AG and g.AG.trust.size() == g.AG.n:
				var A = g.AG
				var st := 0.0
				var sp := 0.0
				var sd := 0.0
				var lowt := 0
				var so := 0.0
				var so2 := 0.0
				for i in A.n:
					st += A.trust[i]
					sp += A.pb[i]
					sd += A.dist[i]
					so += A.off[i]
					so2 += A.off[i] * A.off[i]
					if A.trust[i] < 0.3: lowt += 1
				var nn := float(A.n)
				print("AGD|%d|trust %.3f low %.3f pb %.2f dist %.3f off_sd %.2f" % [(m + 1) / 12, st / nn, lowt / nn, sp / nn, sd / nn, sqrt(maxf(0.0, so2 / nn - (so / nn) * (so / nn)))])
	quit()
