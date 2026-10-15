# v55_3: выгрузка стартовых данных страны в JSON — для сверки с реальностью (право, политология, экономика).
#   tools/godot.sh --headless --path . --script tools/dump_country.gd -- country=DE out=/tmp/DE.json
extends SceneTree


func _init():
	var out := "/tmp/country.json"
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="):
			out = String(a).substr(4)
	var g = load("res://main.gd").new()
	g.game_opts.merge({"agents": false, "seed": 7}, true)
	root.add_child(g)
	for i in 4:
		await process_frame
	var d := {}
	d["ccode"] = g.ccode
	d["start_date"] = g.date_text()
	for k in ["INFO", "TERMS", "MACRO", "UPPER"]:
		d[k] = g.get(k)
	d["seats_total"] = g.SEATS
	d["majority"] = g.MAJORITY
	var parties: Array = []
	var sh: Array = g.national_shares(false)
	for p in g.PARTY_NAMES.size():
		parties.append({"name": g.PARTY_NAMES[p], "desc": g.PARTY_DESC[p] if p < g.PARTY_DESC.size() else "", "leader": g.PARTY_LEADERS[p] if p < g.PARTY_LEADERS.size() else "",
			"seats": g.seats[p], "poll_share": snappedf(float(sh[p]) * 100.0, 0.1), "in_government": bool(g.in_coalition[p]) or p == 0})
	d["parties"] = parties
	d["player_party_index"] = 0
	d["government_seats"] = g.gov_seats()
	d["approval"] = snappedf(g.approval(), 0.1)
	d["interest_groups"] = {"base": g.GROUP_BASE, "weight": g.GROUP_WEIGHT, "lean_party_support": g.LEAN}
	d["regime_id"] = g.regime_id()
	d["regime_class"] = g.regime_class()
	d["democracy_index"] = snappedf(g.democracy_index(), 0.01)
	d["econ_model"] = g.econ_id()
	var b: Dictionary = g.compute_budget()
	d["budget_pct_gdp"] = {"revenue": snappedf(b["revenue"] / g.gdp * 100.0, 0.1), "spending": snappedf(b["spending"] / g.gdp * 100.0, 0.1),
		"balance": snappedf(b["balance"] / g.gdp * 100.0, 0.1), "debt": snappedf(g.debt / g.gdp * 100.0, 0.1)}
	var rev := {}
	for k in b["rev"]:
		rev[k] = snappedf(b["rev"][k] / g.gdp * 100.0, 0.01)
	d["budget_revenue_pct"] = rev
	var exp := {}
	for k in b["exp"]:
		exp[k] = snappedf(b["exp"][k] / g.gdp * 100.0, 0.01)
	d["budget_spending_pct"] = exp
	d["policy"] = g.pol.duplicate() if "pol" in g else {}
	# законы: название темы, действующий вариант и все варианты
	var laws: Array = []
	for tid in g.law_index:
		var t: Dictionary = g.law_index[tid]
		var vs: Array = []
		for v in t["v"]:
			vs.append(String(v["n"]))
		var ci: int = g.cur_idx(String(tid))
		laws.append({"id": tid, "name": String(t["name"]), "current": vs[ci] if ci < vs.size() else "?", "current_desc": String((t["v"] as Array)[ci].get("d", "")) if ci < vs.size() else "", "options": vs})
	d["laws"] = laws
	# организации
	var orgs := {}
	for o in g.ORG_ORDER:
		orgs[o] = {"name": String(g.ORGS[o]["n"]), "group": ["member", "candidate", "not_member"][g.io_group(String(o))] if g.has_method("io_group") else ("member" if g.io_member(String(o)) else "not_member")}
	d["organizations"] = orgs
	# регионы
	var regs: Array = []
	for i in g.REGIONS.size():
		regs.append({"name": String(g.REGIONS[i]["name"]), "popm": g.regions[i]["popm"], "autonomy": g.regions[i].get("auto", 0.0)})
	d["regions"] = regs
	# народы и церковь
	if g.cu_on():
		var nat: Dictionary = g.cu_national()
		var top: Array = g.cu_sorted(nat)
		var peoples: Array = []
		for k in mini(12, top.size()):
			peoples.append([g.cu_name(String(top[k][0])), snappedf(float(top[k][1]) * 100.0, 0.1)])
		d["peoples_pct"] = peoples
		d["culture_policy"] = g.cu["pol"]
	if g.ch_on():
		d["church"] = {"name": g.ch["name"], "state_religion": g.ch["state"], "finance_level": g.ch["fin"], "power": g.ch["pow"], "piety": snappedf(g.ch_nat_piety(), 0.1)}
		var rel := {}
		for i in g.regions.size():
			var r: Array = g.regions[i].get("rel", [])
			for f in r.size():
				rel[f] = float(rel.get(f, 0.0)) + float(r[f]) * g.cu_pw(i)
		d["religion_shares_by_faith_index"] = rel
	# события страны (тексты)
	var evs: Array = []
	for e in g.EVENTS_C + g.EVENTS_SPECIAL:
		evs.append(String(e.get("t", "")).substr(0, 400))
	d["country_events"] = evs
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify(d, "  "))
	f.close()
	print("saved ", out)
	quit()
