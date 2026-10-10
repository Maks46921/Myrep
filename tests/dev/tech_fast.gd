extends SceneTree
# Быстрый симулятор исследований на 100 лет для выбранной страны (аргумент country=XX): без полной экономики.
# Считает только механику технологий: скорость, потолок, стройку, пассивное изучение соседей, ИИ-выбор. ВВП растёт на 2,2%/год плюс эффект технологий.
# Печатает строки FAST для tools/tech_report.py.
var strategies := [
	{"id": "обычная", "edu": 1.0, "bld": 0, "media": -1},
	{"id": "скупая", "edu": 0.5, "bld": 0, "media": -1},
	{"id": "усиленная", "edu": 1.5, "bld": 1, "media": -1},
	{"id": "максимум", "edu": 2.0, "bld": 2, "media": -1},
	{"id": "усиленная без свободы слова", "edu": 1.5, "bld": 1, "media": 2},
]

func _init():
	var g = load("res://main.gd").new()
	g.game_opts.merge({"agents": false, "seed": 3}, true)
	root.add_child(g)
	for i in 4: await process_frame
	var cc: String = g.ccode
	var edu0: float = g.pol["edu"]
	var gdp0: float = g.gdp
	var turn0: int = g.turn
	var media0 = g.law_state.get("media_law", 0)
	for st in strategies:
		g.tech_init()
		g.turn = turn0
		g.gdp = gdp0
		g.tech["auto"] = true
		g.tech["ai_all"] = true
		g.pol["edu"] = edu0 * float(st["edu"])
		g.law_state["media_law"] = media0 if int(st["media"]) < 0 else int(st["media"])
		var tiers_series := {}
		for m in 1200:
			g.turn += 1
			var mods_g := 0.0
			g.mods = g.BASE_MODS.duplicate()
			g.tech_apply_mods()
			mods_g = float(g.mods["growth_bonus"])
			g.gdp *= 1.0 + (0.014 + mods_g / 100.0) / 12.0
			g.lvl["edu_lvl"] = 100.0 * (float(g.pol["edu"]) / float(g.pol_def["edu"])) / (float(g.pol["edu"]) / float(g.pol_def["edu"]) + 1.0)
			var kb: int = int(st["bld"])
			if kb > 0 and g.turn % 6 == 0:
				for d in g.TECH_BUILDINGS:
					if kb == 1 and d["id"] in ["rc", "campus"]:
						g.tech_build(d["id"])
					elif kb == 2:
						g.tech_build(d["id"])
			g.tech_month()
			if (g.turn - turn0) % 300 == 0:
				var tiers := 0
				for b in g.TECH_NB:
					for t in (g.tech["grp"][b] as Dictionary):
						if g.tech_tier_done(b, int(t)) != "":
							tiers += 1
				g.mods = g.BASE_MODS.duplicate()
				g.tech_apply_mods()
				var needs: Dictionary = g.tech_needs_bot(cc)
				var val := 0.0
				for id in g.tech["done"]:
					val += g.tech_score(String(id), needs) * g.tech_power(int(g.tech_def(String(id))["b"]))
				var pas := 0.0
				for id2 in g.tech["pas"]:
					pas += float(g.tech["pas"][id2])
				print("FAST|%s|%s|%d|%d|%.1f|%.1f|%.3f|%.1f|%.0f" % [cc, String(st["id"]), (g.turn - turn0) / 12, tiers, g.tech["speed"], g.tech["cap"], float(g.mods["growth_bonus"]), val, g.gdp / gdp0 * 100.0])
	quit()
