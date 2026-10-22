extends SceneTree
# 0.62: сравнение «месячный шаг» и «недельный шаг» (дни → недельные тики) для одной страны и одного seed.
# Параметры после "--": country=XX seed=N years=N mode=m|w ev=0|1 agents=0|1 out=путь.tsv
# mode=m: next_turn() подряд (старый месячный расчёт); mode=w: advance_day() до конца месяца (недельные тики + месячный шаг).
# Выводит по строке на год (и на каждый 6-й месяц): год, ВВП, рост, инфляция, безработица, долг %, рейтинг, недовольство, капитал, поддержка групп.
# показатели группы «экономика»: ставка, индекс цен, загрузка, деловой климат и климат потребителей, лояльность и развитие регионов,
# региональный долг, коррупция, надбавка за риск
const ECON_COLS := ["rate", "cpi", "util", "bconf", "cconf", "loy", "dev", "rdebt", "corr", "rprem"]


func econ_vals(m) -> Array:
	return [float(m.ec["rate"]), float(m.ec["cpi_idx"]) * 100.0, float(m.ec["util"]) * 100.0, float(m.ec["bconf"]), float(m.ec["cconf"]),
		m.reg_avg("loy"), m.reg_avg("dev"), m.reg_avg("rdebt"), float(m.lvl["corruption"]), float(m.risk_prem)]


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
	lines.append("month\tgdp\tgrowth\tinfl\tunemp\tdebt_pct\tappr\tunrest\tcapital\t" + "\t".join(PackedStringArray(ECON_COLS)) + "\t" + "\t".join(PackedStringArray(m.GROUPS.map(func(g): return "sup_" + str(g)))))
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
			row += "\t%.3f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.3f" % econ_vals(m)
			for g in m.GROUPS:
				row += "\t%.2f" % float(m.support[g])
			lines.append(row)
	var txt := "\n".join(lines) + "\n"
	if out != "":
		var f := FileAccess.open(out, FileAccess.WRITE)
		f.store_string(txt)
	else:
		print(txt)
	quit()
