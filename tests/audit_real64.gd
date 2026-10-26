extends SceneTree
# 0.64 (п. 4): проверка реалистичности России, Беларуси и Украины. Один прогон: страна (country=XX), сценарий (scn=...), зерно (seed=N), лет (years=25).
# Игра идёт в режиме наблюдателя (ИИ ведёт партию, бюджет, события и законы). Раз в год пишутся показатели; итог — .testlogs/real64/XX_scn_seed.json.
# Разбор и отчёт — tools/real64_report.py.
var g
var cc := "RU"
var scn := "calm"
var sd := 1
var years := 25
var outdir := ".testlogs/real64"
var rows: Array = []
var notes: Array = []
var done_flag := {}
var trace := false
var last_dem := 0.0


func gv(name: String, d = null):
	var v = g.get(name)
	return d if v == null else v


func note(s: String) -> void:
	if notes.size() < 40:
		notes.append("%s: %s" % [g.date_text(), s])


func war_info() -> Dictionary:
	var r := {"at_war": false}
	if g.mil.is_empty() or not g.mil_at_war():
		return r
	var w: Dictionary = g.mil["war"]
	r = {"at_war": true, "lead": String(w.get("lead", "")), "score": float(w.get("score", 0.0)), "days": int(w.get("days", 0)),
		"nwon": int(w.get("nwon", 0)), "nlost": int(w.get("nlost", 0)), "cap_lost": int(w.get("cap_lost", 0)),
		"kia0": float((w.get("kia", [0, 0]) as Array)[0]), "kia1": float((w.get("kia", [0, 0]) as Array)[1]), "weary": float(w.get("weary", 0.0)),
		"don_full": g.mil_don_full(), "sanct": bool(w.get("sanct", false)),
		"pw0": g.mil_side_power(0), "pw1": g.mil_side_power(1), "stale": int(w.get("stale", 0))}
	return r


func ws_info(c: String) -> Dictionary:
	if not g.wsim.has(c):
		return {}
	var w: Dictionary = g.wsim[c]
	return {"gdp": float(w.get("gdp", 0.0)), "growth": float(w.get("growth", 0.0)), "infl": float(w.get("infl", 0.0)), "unemp": float(w.get("unemp", 0.0)),
		"debt": float(w.get("debt", 0.0)), "stab": float(w.get("stab", 0.0)), "appr": float(w.get("appr", 0.0)), "stance": float(w.get("stance", 0.0))}


func snap(y: int) -> Dictionary:
	var r := {"year": y, "turn": g.turn}
	r["gdp"] = g.gdp
	r["growth"] = g.growth
	r["infl"] = g.inflation
	r["unemp"] = g.unemployment
	r["debt_pct"] = g.debt / maxf(1.0, g.gdp) * 100.0
	r["appr"] = g.approval()
	r["auth"] = g.au_auth()
	r["au_on"] = g.au_on()
	r["dem"] = g.democracy_index()
	r["pm"] = g.gov_pm_party()
	r["res"] = float(gv("res_price", 1.0))
	r["war"] = war_info()
	r["ws_lvl"] = g.fa_ws_lvl()
	r["ldr_gone"] = bool(g.mil.get("ldr_gone", false)) if not g.mil.is_empty() else false
	r["mob"] = int(g.mil.get("mob", 0)) if not g.mil.is_empty() else 0
	r["martial"] = g.martial_on()
	r["nato"] = {"UA": g.mil_is_nato("UA"), "BY": g.mil_is_nato("BY"), "RU": g.mil_is_nato("RU")}
	r["eu"] = bool((g.rl.get("b", {}) as Dictionary).get("eu", false)) if typeof(g.rl) == TYPE_DICTIONARY else false
	var rel := {}
	for c in ["RU", "BY", "UA", "PL", "DE", "CN"]:
		if g.dip.has(c):
			rel[c] = float(g.dip[c].get("rel", 0.0))
	r["rel"] = rel
	if g.has_method("war65_wf"):
		r["x65"] = {"wf": g.war65_wf(), "ls": float(g.x65.get("ls", 100.0)), "ls_pk": float(g.x65.get("ls_pk", 100.0)), "cut": float(g.x65.get("cut", 0.0)), "aid": float(g.x65.get("aid", 0.0)),
			"aid_m": float(g.x65.get("aid_m", 0.0)), "mood": float(g.x65.get("mood", 0.0)), "fear": float(g.au.get("fear", 0.0)) if g.au_on() else 0.0, "tgt": g.infl_tgt(),
			"stale": int((g.mil.get("war", {}) as Dictionary).get("stale", 0)) if not g.mil.is_empty() else 0}
	r["gt"] = {"target": g.g_target_last, "mil": g.mil_g(), "rl": g.rl_g(), "fin": g.fin_g(), "soc": g.soc_g(), "ex": g.ex_g(), "spill": g.world_spill_g(),
		"ddrag": g.debt_drag(g.debt / maxf(1.0, g.gdp) * 100.0), "lvl": g.lvl_sum("growth"), "mil_i": g.mil_infl(), "mil_u": g.mil_unemp()}
	r["sanc"] = (g.fa["sanc"] as Dictionary).keys() if typeof(g.fa) == TYPE_DICTIONARY and g.fa.has("sanc") else []
	r["ws_g"] = g.fa_ws_g()
	r["falog"] = (g.fa["log"] as Array).slice(maxi(0, (g.fa["log"] as Array).size() - 6)) if typeof(g.fa) == TYPE_DICTIONARY and g.fa.has("log") else []
	if g.fin_on():
		var b: Dictionary = g.fin["bk"]
		var db: Dictionary = g.fin["db"]
		r["fin"] = {"cr": float(b["cr"]) / maxf(1.0, float(b["cr0"])), "crunch": float(b["crunch"]), "closed": int(db["closed_t"]) > g.turn, "hot": float(db["hot"]),
			"exr": float(g.fin["ex"]["idx"]) / maxf(1.0, float(g.fin["ex"]["ma"])), "imf": int(g.fin["imf"]["st"]), "mood": float(g.fin["mood"]), "capctl": bool(g.fin["fx"]["capctl"]),
			"qe": float(g.fin["cb"]["qe"]), "cred": float(g.fin["cb"]["cred"]), "fx_imp": float(g.fin["fx"]["imp"]),
			"cris": String(b["cris"]["kind"]) if bool(b["cris"]["on"]) else "", "sev": float(b["cris"]["sev"]), "npl": float(b["npl"]), "car": float(b["car"]), "trust": float(b["trust"]), "spr": float(db["spr"]), "mkt": float(db["mkt"])}
	var w := {}
	for c in ["RU", "BY", "UA"]:
		if c != cc:
			w[c] = ws_info(c)
	r["wsim"] = w
	r["regions"] = g.regions.size()
	r["unrest"] = g.reg_avg("unrest") if g.has_method("reg_avg") else 0.0
	r["capital"] = g.capital
	r["over"] = g.game_over
	return r


func scenario_month(m: int) -> void:
	var y := m / 12
	match scn:
		"war":
			# затяжная война: ИИ не идёт на мир, пока война не окончена сама
			pass
		"oil":
			if y >= 1 and y < 5:
				g.res_price = 0.55
		"sanctions":
			if m == 6:
				g.fa_ws_set(3, "war")
				var ws: Dictionary = g.fa_ws()
				ws["evade"] = -1
				note("полные санкции, обход закрыт")
		"leader":
			if m == 36 and not done_flag.has("leader"):
				done_flag["leader"] = true
				if g.au_on():
					g.au2_ruler_gone()
					note("правитель ушёл")
				else:
					g.pres_due = g.turn + 1
					note("досрочная смена президента (выборы %s)" % ("запрещены военным положением" if g.martial_on() else "возможны"))
		"mobilize":
			if m == 12 or m == 24:
				var lvl := 1 if m == 12 else 2
				if g.mil_at_war() or cc != "BY":
					if g.mil_mobilize(lvl):
						note("мобилизация уровня %d" % lvl)
		"unrest":
			if y >= 1 and y < 3:
				for i in g.regions.size():
					g.regions[i]["unrest"] = minf(100.0, float(g.regions[i]["unrest"]) + 1.5)
					g.regions[i]["loy"] = maxf(0.0, float(g.regions[i]["loy"]) - 0.8)
		"weird":
			# нестандартная игра: рваный бюджет, пустая казна, случайные события
			if m % 6 == 0:
				g.capital = 0.0
			if m % 12 == 5:
				g.ap["style"] = randi() % 3
		"union":
			if cc == "RU" and m == 24 and not done_flag.has("union"):
				done_flag["union"] = true
				g.capital = 200.0
				var res: Dictionary = g.union_do("BY", 1, 1)
				note("союз с Беларусью: %s" % str(res.get("msg", "")).substr(0, 90))
		"eunato":
			if cc == "UA" and m == 24 and not done_flag.has("eunato"):
				done_flag["eunato"] = true
				g.nato_ovr = 1
				if typeof(g.rl) == TYPE_DICTIONARY and (g.rl.get("b", {}) as Dictionary).has("eu"):
					g.rl["b"]["eu"] = true
				note("Украина принята в НАТО и ЕС")


func _init():
	for a in OS.get_cmdline_user_args():
		var s := String(a)
		if s.begins_with("country="): cc = s.substr(8)
		elif s.begins_with("scn="): scn = s.substr(4)
		elif s.begins_with("seed="): sd = int(s.substr(5))
		elif s.begins_with("years="): years = int(s.substr(6))
		elif s.begins_with("out="): outdir = s.substr(4)
		elif s == "trace=1": trace = true
	var m0 = load("res://main.gd")
	g = m0.new()
	g.game_opts.merge({"ev": 1.0, "news": 1.0, "agents": false, "seed": sd}, true)
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("opt="):
			var kv := String(a).substr(4).split(":")
			g.game_opts[kv[0]] = float(kv[1])
	root.add_child(g)
	for i in 3: await process_frame
	g.choose_country(cc, 99)
	for i in 3: await process_frame
	seed(sd * 7919 + 13)
	if not g.mil.is_empty():
		g.mil_rng.seed = sd * 104729 + 7
	g.game_opts["observer"] = true
	g.observer_start()
	if OS.get_cmdline_user_args().has("nobal=1"):
		g.ap["bal"] = false
	if scn == "weird":
		g.ap["style"] = randi() % 3
	var t0 := Time.get_ticks_msec()
	rows.append(snap(0))
	var err := ""
	for m in years * 12:
		scenario_month(m)
		if g.election_open:
			g.election_continue()
		var guard := 0
		while not g.current_event.is_empty() and guard < 6:
			if scn == "war" and String(g.current_event.get("special", "")) == "war":
				g.choose(0)
			elif scn == "weird" and randf() < 0.5:
				g.choose(randi() % (g.current_event["o"] as Array).size())
			else:
				g.auto_resolve_event()
			guard += 1
		g.next_turn()
		if g.election_open:
			g.election_continue()
		if trace:
			var dn: float = g.democracy_index()
			if absf(dn - last_dem) >= 0.02:
				print("TRACE ", g.date_text(), " dem %.2f -> %.2f shift %.2f cls %s rid %s" % [last_dem, dn, float(g.mods.get("dem_shift", 0.0)), str(g.au.get("cls", "")), g.regime_id()])
				for e in (g.log_entries as Array).slice(maxi(0, (g.log_entries as Array).size() - 4)):
					print("   LOG ", str(e).left(200))
			last_dem = dn
		if trace and m % 3 == 2 and not g.mil.is_empty() and g.mil_at_war():
			var w2: Dictionary = g.mil["war"]
			var n0 := 0
			var s0 := 0.0
			var n1 := 0
			var s1 := 0.0
			var fg := 0
			for f in g.mil["units"]:
				if g.mil_side(String(f["cc"])) == 0:
					n0 += 1
					s0 += float(f["str"])
				else:
					n1 += 1
					s1 += float(f["str"])
				if int(f["fight"]) >= 0:
					fg += 1
			print("WAR m%d units %d/%d str %.0f/%.0f pw %.0f/%.0f fights %d won %d/%d nw %d/%d occ %s stale %d sc %.0f" % [m + 1, n0, n1, s0, s1, g.mil_side_power(0), g.mil_side_power(1), fg, int(w2["won"]), int(w2["lost"]), int(w2["nwon"]), int(w2["nlost"]), str(w2["occ"]), int(w2.get("stale", 0)), float(w2["score"])])
		if m % 12 == 11:
			rows.append(snap((m + 1) / 12))
		if g.game_over:
			err = String(g.end_reason).replace("\n", " ")
			if (m % 12) != 11:
				rows.append(snap((m + 1) / 12))
			break
	var out := {"cc": cc, "scn": scn, "seed": sd, "years": years, "rows": rows, "notes": notes, "game_over": g.game_over, "end": err,
		"turns": g.turn, "observer": g.observer, "last_ev": str(g.current_event).left(400), "sec": (Time.get_ticks_msec() - t0) / 1000.0, "start_year": g.START_YEAR}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + outdir))
	var f := FileAccess.open("res://%s/%s_%s_%d.json" % [outdir, cc, scn, sd], FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	print("OK real64 %s %s %d: ход %d, конец игры %s" % [cc, scn, sd, g.turn, str(g.game_over)])
	quit()
