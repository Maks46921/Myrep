extends SceneTree
# Флот и морская торговля: инициализация, год по дням, заказ корабля, расширение порта.
var bad := 0
func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)

func _init():
	var cc := "DE"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("country="): cc = a.substr(8)
	var m = load("res://main.gd").new()
	m.game_opts.merge({"ev": 0.0, "news": 0.0, "fedev": 0, "socev": 0, "exev": 0}, true)
	m.game_opts["seed"] = 7
	m.game_opts["country"] = cc
	root.add_child(m)
	for i in 3: await process_frame
	check(m.ccode == cc, "страна " + cc)
	var sea: bool = m.flt_has_sea()
	print(cc, " море: ", sea, " портов: ", m.flt_ports_of(cc).size())
	if sea:
		check(m.fleet_util() >= 0.0 and m.fleet_util() <= 3.0, "загрузка портов разумна: %.2f" % m.fleet_util())
		var g0: float = m.gdp
		m.capital = 10.0
		var ok_o: bool = m.fleet_order("ptl")
		var ps: Array = m.fleet_ports_summary()
		check(ps.size() > 0 or m.flt_ports_of(cc).is_empty(), "сводка по портам")
		if ps.size() > 0:
			m.fleet_port_invest(String(ps[0]["id"]) if ps[0].has("id") else String(m.flt["ports"].keys()[0]))
		m.fleet_set_mission("escort") if m.FLT_MISSIONS.size() > 0 else null
		m.fleet_merch(1)
		print("заказ: ", ok_o, " очередь: ", (m.flt["queue"] as Array).size())
		var guard := 0
		while m.turn < 12 and guard < 800:
			guard += 1
			if m.election_open: m.election_continue()
			if not m.current_event.is_empty(): m.choose(0)
			m.advance_day()
		check(m.turn >= 12, "прошёл год")
		check(is_finite(m.gdp) and m.gdp > g0 * 0.5, "ВВП в норме %.0f" % m.gdp)
		check(is_finite(m.fleet_g()) and is_finite(m.fleet_infl()), "влияние конечно")
		print(m.fleet_status_text())
	else:
		for i in 60: m.advance_day()
		check(is_finite(m.gdp), "без моря всё живо")
	print("t_fleet: проблем ", bad)
	quit(1 if bad > 0 else 0)
