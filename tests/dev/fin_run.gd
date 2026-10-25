extends SceneTree
# 0.63: прогон финансового модуля. Параметры после "--": country=XX seed=N years=N mode=m|w ev=0|1 fin=0|1 cr=0|1|2 out=путь.tsv
# Печатает раз в 6 месяцев: макро и показатели финансов (доверие, ставка, курс, резервы, банки, биржа, долг, МВФ, фонды).
const COLS := ["month", "gdp", "growth", "infl", "unemp", "debt_pct", "appr", "mood", "rate", "fxs", "res", "reg", "cb_ind", "cred", "car", "npl", "cr", "trust", "bk_kind", "bub_h", "ex_idx", "ex_bub", "d_avg", "d_mkt", "spr", "cover", "closed", "imf", "fd", "n_cris", "n_dflt"]


func _init():
	var seed_ := 7
	var years := 5
	var mode := "w"
	var ev := 1.0
	var fin_on := 1
	var cr := 1
	var out := ""
	var every := 6
	for a in OS.get_cmdline_user_args():
		var s := String(a)
		if s.begins_with("seed="): seed_ = int(s.substr(5))
		elif s.begins_with("years="): years = int(s.substr(6))
		elif s.begins_with("mode="): mode = s.substr(5)
		elif s.begins_with("ev="): ev = float(s.substr(3))
		elif s.begins_with("fin="): fin_on = int(s.substr(4))
		elif s.begins_with("cr="): cr = int(s.substr(3))
		elif s.begins_with("out="): out = s.substr(4)
		elif s.begins_with("every="): every = int(s.substr(6))
	var m = load("res://main.gd").new()
	m.game_opts.merge({"ev": ev, "news": ev, "fedev": int(ev), "socev": int(ev), "exev": int(ev), "milev": int(ev), "revev": int(ev), "rlev": 1, "bldev": int(ev), "agents": false, "finlev": fin_on, "fincr": cr}, true)
	m.game_opts["seed"] = seed_
	root.add_child(m)
	for i in 3: await process_frame
	var lines: PackedStringArray = ["\t".join(PackedStringArray(COLS))]
	var n_dflt := 0
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
		if m.fin_on() and int(m.fin["db"]["rest"]) > n_dflt:
			n_dflt = int(m.fin["db"]["rest"])
		if (mo + 1) % every == 0 or m.game_over:
			lines.append(row(m, mo + 1))
	if m.game_over:
		lines.append("GAME OVER: " + m.end_reason)
	if m.fin_on():
		for e in m.fin["log"].slice(-12):
			lines.append("# " + str(e["d"]) + " [" + str(e["s"]) + "] " + str(e["t"]))
	var txt := "\n".join(lines) + "\n"
	if out != "":
		var f := FileAccess.open(out, FileAccess.WRITE)
		f.store_string(txt)
	else:
		print(txt)
	quit()


func row(m, mo: int) -> String:
	var r := "%d\t%.0f\t%.2f\t%.2f\t%.2f\t%.1f\t%.1f" % [mo, m.gdp, m.growth, m.inflation, m.unemployment, m.debt / m.gdp * 100.0, m.approval()]
	if not m.fin_on():
		return r
	var f: Dictionary = m.fin
	var b: Dictionary = f["bk"]
	var d: Dictionary = f["db"]
	r += "\t%.1f\t%.2f\t%.1f\t%.1f\t%s\t%.0f\t%.0f" % [f["mood"], m.ec["rate"], float(m.ec["fxs"]) * 100.0, m.ec["res"], f["fx"]["reg"], f["cb"]["ind"], f["cb"]["cred"]]
	r += "\t%.1f\t%.1f\t%.0f\t%.0f\t%s\t%.0f\t%.0f\t%.0f" % [b["car"], b["npl"], b["cr"], b["trust"], b["cris"]["kind"] if b["cris"]["on"] else "-", b["bub_h"], f["ex"]["idx"], f["ex"]["bub"]]
	r += "\t%.2f\t%.2f\t%.1f\t%.1f\t%s\t%d\t%.1f\t%d\t%d" % [float(d["avg"]) * 100.0, float(d["mkt"]) * 100.0, d["spr"], d["cover"], "Y" if int(d["closed_t"]) > m.turn else "-", f["imf"]["st"], m.fin_fund_total(), b["count"], d["rest"]]
	return r
