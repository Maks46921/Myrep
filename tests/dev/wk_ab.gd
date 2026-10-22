extends SceneTree
# 0.62: сравнение «месячный шаг» и «недельный шаг» (дни → недельные тики) для одной страны и одного seed.
# Параметры после "--": country=XX seed=N years=N mode=m|w ev=0|1 agents=0|1 out=путь.tsv
# mode=m: next_turn() подряд (старый месячный расчёт); mode=w: advance_day() до конца месяца (недельные тики + месячный шаг).
# Выводит по строке на год (и на каждый 6-й месяц): год, ВВП, рост, инфляция, безработица, долг %, рейтинг, недовольство, капитал, поддержка групп.
func _init():
	var seed_ := 7
	var years := 5
	var mode := "m"
	var ev := 0.0
	var ag := false
	var out := ""
	var extra := {}
	for a in OS.get_cmdline_user_args():
		var s := String(a)
		if s.begins_with("seed="): seed_ = int(s.substr(5))
		elif s.begins_with("years="): years = int(s.substr(6))
		elif s.begins_with("mode="): mode = s.substr(5)
		elif s.begins_with("ev="): ev = float(s.substr(3))
		elif s.begins_with("agents="): ag = s.substr(7) == "1"
		elif s.begins_with("out="): out = s.substr(4)
	var m = load("res://main.gd").new()
	m.game_opts.merge({"ev": ev, "news": ev, "fedev": int(ev), "socev": int(ev), "exev": int(ev), "milev": int(ev), "revev": int(ev), "rlev": int(ev), "bldev": int(ev), "agents": ag}, true)
	m.game_opts["seed"] = seed_
	root.add_child(m)
	for i in 3: await process_frame
	var lines: PackedStringArray = []
	var xn := ["x_army", "x_ready", "x_ammo", "x_fleet", "x_wave", "x_rev", "x_coup", "x_sep", "x_built", "x_dip"]      # показатели подсистем mil (армия, флот, революции, стройка)
	lines.append("month\tgdp\tgrowth\tinfl\tunemp\tdebt_pct\tappr\tunrest\tcapital\t" + "\t".join(PackedStringArray(m.GROUPS.map(func(g): return "sup_" + str(g)))) + "\t" + "\t".join(PackedStringArray(xn)))
	for mo in years * 12:
		if m.game_over: break
		var target: int = m.turn + 1
		var guard := 0
		while m.turn < target and guard < 3000 and not m.game_over:
			guard += 1
			if m.election_open: m.election_continue()
			var g2 := 0
			while not m.current_event.is_empty() and g2 < 5:
				m.choose(0); g2 += 1
			if mode == "m":
				m.next_turn()
			else:
				m.advance_day()
		if (mo + 1) % 6 == 0:
			var row := "%d\t%.1f\t%.3f\t%.3f\t%.3f\t%.2f\t%.2f\t%.2f\t%.2f" % [mo + 1, m.gdp, m.growth, m.inflation, m.unemployment, m.debt / m.gdp * 100.0, m.approval(), m.reg_avg("unrest"), m.capital]
			for g in m.GROUPS:
				row += "\t%.2f" % float(m.support[g])
			row += "\t" + "\t".join(PackedStringArray(wk_x(m).map(func(v): return "%.3f" % v)))
			lines.append(row)
	var txt := "\n".join(lines) + "\n"
	if out != "":
		var f := FileAccess.open(out, FileAccess.WRITE)
		f.store_string(txt)
	else:
		print(txt)
	quit()


# показатели подсистем mil: армия, боеготовность, боеприпасы, флот, революционная волна/риск, переворот, сепаратизм, число сооружений, отношения
func wk_x(m) -> Array:
	var army := 0.0
	var rdy := 0.0
	var ammo := 0.0
	var fl := 0.0
	if m.mil_on():
		army = m.mil_total(m.ccode)
	if m.ar_on():
		rdy = m.ar_rd()
		ammo = float(m.ar["ammo"])
	if m.flt_has_sea():
		fl = m.fleet_power()
	var wave := 0.0
	var rev := 0.0
	var coup := 0.0
	var sep := 0.0
	if m.rv_on():
		wave = float(m.rv["nat"]["wave"])
		rev = float(m.rv["nat"]["rev"])
		coup = float(m.rv["nat"]["coup"])
		for k in m.rv["r"]:
			sep += float(m.rv["r"][k]["sep"]) / float(maxi(1, (m.rv["r"] as Dictionary).size()))
	var built := 0.0
	for r in m.regions:
		for id in r["built"]:
			built += float(r["built"][id]["n"])
	return [army, rdy, ammo, fl, wave, rev, coup, sep, built, m.dip_avg_rel() if not m.dip.is_empty() else 0.0]
