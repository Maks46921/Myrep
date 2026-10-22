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
	lines.append("month\tgdp\tgrowth\tinfl\tunemp\tdebt_pct\tappr\tunrest\tcapital\t" + "\t".join(PackedStringArray(m.GROUPS.map(func(g): return "sup_" + str(g)))) + "\tpop\tnonrel\tsoc_t\tcu_t\tch_pow\ttech_n\ttech_pts\tind_g")
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
			row += _soc_cols(m)
			lines.append(row)
	var txt := "\n".join(lines) + "\n"
	if out != "":
		var f := FileAccess.open(out, FileAccess.WRITE)
		f.store_string(txt)
	else:
		print(txt)
	quit()


# показатели подсистемы soc (население, религия, культура, церковь, технологии, промышленность)
func _soc_cols(m) -> String:
	var nonrel: float = float(m.soc_national()[6]) * 100.0 if m.soc.has("lvl") else 0.0
	var soc_t: float = float(m.soc.get("tension", 0.0)) if m.soc.has("lvl") else 0.0
	var cu_t: float = float(m.cu.get("tension", 0.0)) if m.cu_on() else 0.0
	var ch_p: float = float(m.ch.get("pow", 0.0)) if m.ch_on() else 0.0
	var tn: int = m.tech_count() if not m.tech.is_empty() else 0
	var tp: float = float(m.tech.get("pts", 0.0)) if not m.tech.is_empty() else 0.0
	var ig: float = m.ind_g() if m.ind_on() else 0.0
	return "\t%.3f\t%.2f\t%.2f\t%.2f\t%.2f\t%d\t%.0f\t%.3f" % [m.total_pop(), nonrel, soc_t, cu_t, ch_p, tn, tp, ig]
