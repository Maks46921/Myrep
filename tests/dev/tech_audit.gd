extends SceneTree
# Аудит баланса вариантов «или»: как часто каждый вариант оказывается лучшим для 34 стран мира и для 10 условных ситуаций.
# godot --headless --path . --script tests/dev/tech_audit.gd -- country=DE
func _init():
	var g = load("res://main.gd").new()
	g.game_opts.merge({"agents": false}, true)
	root.add_child(g)
	for i in 4: await process_frame
	var profiles := {}
	for pr in g.tech_audit_profiles():
		profiles[String(pr[0])] = pr[1]
	var total: int = profiles.size()
	var bad := 0
	var rows := []
	for b in g.TECH_NB:
		for t in (g.tech["grp"][b] as Dictionary):
			var grp: Array = g.tech["grp"][b][t]
			if grp.size() < 2:
				continue
			var wins := {}
			var avg := {}
			for id in grp:
				wins[id] = 0
				avg[id] = 0.0
			for pk in profiles:
				var best := ""
				var bs := -1e18
				for id in grp:
					var s: float = g.tech_score(String(id), profiles[pk])
					avg[id] = float(avg[id]) + s
					if s > bs:
						bs = s
						best = String(id)
				wins[best] = int(wins[best]) + 1
			var line := "%s ур.%2d |" % [String(g.TECH_BRANCHES[b]["id"]), int(t) + 1]
			var flag := ""
			for id in grp:
				var share: float = float(wins[id]) / float(total)
				line += " %s %3.0f%% (оц. %.2f)" % [id, share * 100.0, float(avg[id]) / float(total)]
				print("AUD ", id, " ", float(avg[id]) / float(total), " ", share)
				if share < 0.08:
					flag = " ← почти никогда не выбирают"
				if share > 0.80:
					flag = " ← почти всегда побеждает"
			if flag != "":
				bad += 1
			rows.append(line + flag)
	# суммарная ценность ветки: по каждому уровню — средняя оценка вариантов (одиночные технологии — их оценка), среднее по профилям
	for b2 in g.TECH_NB:
		var tot := 0.0
		for t2 in (g.tech["grp"][b2] as Dictionary):
			var gl: Array = g.tech["grp"][b2][t2]
			var m := 0.0
			for pk2 in profiles:
				var mm := 0.0
				for id2 in gl:
					mm += g.tech_score(String(id2), profiles[pk2])
				m += mm / float(gl.size())
			tot += m / float(total)
		print("BR ", b2, " ", tot)
	for r in rows: print(r)
	print("групп с перекосом: %d из %d, профилей %d" % [bad, rows.size(), total])
	quit()
