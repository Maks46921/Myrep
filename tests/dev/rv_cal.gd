extends SceneTree
# Калибровка движка конфликтов: исходы и сроки при разных силе власти, мобилизации и сепаратизме (без полной игры).
func _init():
	var g = load("res://main.gd").new()
	g.game_opts.merge({"agents": true, "seed": 3, "fedev": 0, "socev": 0, "exev": 0, "milev": 0, "revev": 1}, true)
	root.add_child(g)
	for i in 4: await process_frame
	var scen := [
		["слабая власть", 30.0, 35.0, 0.8],
		["средняя власть", 50.0, 50.0, 1.0],
		["сильная власть", 70.0, 62.0, 1.2],
	]
	var base_pol: float = g.pol["army"]
	for sc in scen:
		for mob in [0, 1, 2]:
			for sep in [55.0, 75.0, 90.0]:
				var res := {"rebel_win": 0, "gov_win": 0, "frozen": 0}
				var dur := 0.0
				var n := 40
				for t in n:
					g.rv["conf"].clear()
					var i := 2
					g.lvl["security_lvl"] = sc[1]
					g.support["Силовики"] = sc[2]
					g.pol["army"] = base_pol * float(sc[3])
					var rg: Dictionary = g.rv_reg(i)
					rg["sep"] = sep
					rg["hate"] = 30.0 + (sep - 55.0) * 0.8
					g.regions[i]["unrest"] = 70.0
					g.rv_conf_start("secession", i, 14.0 + sep * 0.2, "кал")
					g.rv["conf"][0]["mob"] = mob
					g.rv["last"] = {}
					var months := 0
					while months < 240 and g.rv["conf"].size() > 0:
						months += 1
						g.turn += 1
						g.rv_conf_month()
						g.regions[i]["popm"] = 5.0
						g.regions[i]["infra"] = 50.0
						g.regions[i]["dev"] = 50.0
						g.regions[i]["unrest"] = 70.0
						if g.rv["conf"].size() > 0:
							rg["hate"] = minf(rg["hate"], 90.0)
						if g.game_over: g.game_over = false
						# защита от потери региона при независимости: восстановим
						if g.regions.size() < 10: break
					var rs := String((g.rv["last"] as Dictionary).get("res", "frozen"))
					if rs not in res: rs = "frozen"
					res[rs] = int(res[rs]) + 1
					dur += float(months)
				print("CAL|%s|mob %d|sep %.0f|победа повстанцев %d%% | правительства %d%% | заморожено %d%% | ср. срок %.0f мес." % [sc[0], mob, sep, res["rebel_win"] * 100 / n, res["gov_win"] * 100 / n, res["frozen"] * 100 / n, dur / n])
				g.rv["conf"].clear()
	quit()
