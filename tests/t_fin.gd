extends SceneTree
# 0.63: финансовый модуль: старт, годы без ошибок, все действия игрока, банковский кризис, дефолт, МВФ, евро, привязка курса, сохранение.
var bad := 0


func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)


func run_months(g, n: int) -> void:
	var target: int = g.turn + n
	var guard := 0
	while g.turn < target and guard < 4000 and not g.game_over:
		guard += 1
		if g.election_open: g.election_continue()
		var g2 := 0
		while not g.current_event.is_empty() and g2 < 5:
			g.choose(0); g2 += 1
		g.advance_day()


func sane(g, tag: String) -> void:
	var f: Dictionary = g.fin
	for k in ["mood", "ind"]:
		pass
	var vals := {"mood": f["mood"], "car": f["bk"]["car"], "npl": f["bk"]["npl"], "cr": f["bk"]["cr"], "trust": f["bk"]["trust"], "idx": f["ex"]["idx"], "avg": f["db"]["avg"],
		"res": g.ec["res"], "fxs": g.ec["fxs"], "rate": g.ec["rate"], "debt": g.debt, "infl": g.inflation}
	for k in vals:
		var v: float = float(vals[k])
		check(not is_nan(v) and not is_inf(v), "%s: %s конечно (%s)" % [tag, k, str(v)])
	check(float(f["mood"]) >= 0.0 and float(f["mood"]) <= 100.0, "%s: доверие 0..100" % tag)
	check(float(f["bk"]["car"]) >= 1.0 and float(f["bk"]["car"]) <= 45.0, "%s: капитал банков в пределах" % tag)
	check(float(f["db"]["avg"]) >= 0.0 and float(f["db"]["avg"]) < 0.6, "%s: средняя ставка в пределах (%.3f)" % [tag, float(f["db"]["avg"])])
	check(float(g.ec["fxs"]) >= 0.6 and float(g.ec["fxs"]) <= 1.5, "%s: курс в пределах" % tag)


func _init():
	var g = load("res://main.gd").new()
	g.game_opts.merge({"ev": 0.0, "news": 0.0, "finlev": 1, "fincr": 1}, true)
	root.add_child(g)
	for i in 3: await process_frame
	g.current_event = {}
	check(g.fin_on(), "финансовый модуль включён")
	check(not g.fin.is_empty() and float(g.fin["mood"]) > 40.0, "старт: доверие рынков нормальное")
	check(absf(float(g.fin["mood"]) - 60.0) < 1.0, "старт: доверие 60 (%.1f)" % float(g.fin["mood"]))
	# --- годы игры ---
	run_months(g, 24)
	sane(g, "через 2 года")
	check(g.fin["h"]["mood"].size() >= 20, "история доверия копится")
	# --- все действия игрока ---
	g.capital = 90.0
	var n_ok := 0
	for pg in g.FIN_PAGES:
		for a in g.fin_acts(pg):
			g.capital = 90.0
			g.current_event = {}
			if bool(a["ok"]):
				if g.fin_do(String(a["id"])):
					n_ok += 1
				run_months(g, 1)
	check(n_ok >= 6, "выполнено действий: %d" % n_ok)
	sane(g, "после действий")
	# --- банковский кризис и его решения ---
	for opt in ["bk_bailout", "bk_bailin", "bk_nat", "bk_guar", "bk_wait"]:
		g.current_event = {}
		g.fin["bk"]["cris"]["on"] = false
		g.fin["bk"]["ins"] = 1
		g.fin_bank_crisis("bubble", 2.0)
		check(bool(g.fin["bk"]["cris"]["on"]), "кризис начался")
		g.fin_apply_act(opt, {})
		check(bool(g.fin["bk"]["cris"].get("decided", false)), "кризис: решение «%s» принято" % opt)
		g.current_event = {}
		run_months(g, 2)
	sane(g, "после кризисов")
	# --- дефолт ---
	g.current_event = {}
	for kind in ["restr", "part", "full"]:
		var d0: float = g.debt
		g.fin_do_default(kind)
		check(g.debt < d0 and int(g.fin["db"]["closed_t"]) > g.turn, "дефолт «%s»: долг списан, рынки закрыты" % kind)
		g.current_event = {}
		run_months(g, 3)
	sane(g, "после дефолтов")
	check(not g.game_over or g.end_reason.find("Государственный дефолт") < 0, "дефолт не заканчивает игру")
	# --- МВФ ---
	g.current_event = {}
	g.fin["imf"]["st"] = 0
	g.fin["cd"]["imf_ev"] = 0
	g.fin_imf_offer("crisis")
	check(g.current_event.has("o"), "МВФ: окно предложения")
	g.choose(0)
	check(int(g.fin["imf"]["st"]) == 2, "МВФ: программа принята")
	run_months(g, 8)
	check(int(g.fin["imf"]["tr"]) < int(g.fin["imf"]["tr_n"]) or int(g.fin["imf"]["st"]) != 2, "МВФ: идут проверки")
	# --- сохранение ---
	var col: Dictionary = g.sv_collect()
	check(col.has("fin"), "сохранение содержит финансы")
	print("t_fin: проблем ", bad, " (страна ", g.ccode, ")")
	quit(1 if bad > 0 else 0)
