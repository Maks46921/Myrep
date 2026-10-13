extends SceneTree
# Отладка: война страны country с foe, auto=1 — свои войска наступают сами. Печать по месяцам.
func _init():
	var cc := "DE"
	var foe := "PL"
	var auto := 1
	var months := 8
	for a in OS.get_cmdline_user_args():
		if a.begins_with("country="): cc = a.substr(8)
		if a.begins_with("foe="): foe = a.substr(4)
		if a.begins_with("auto="): auto = int(a.substr(5))
		if a.begins_with("months="): months = int(a.substr(7))
	var m = load("res://main.gd").new()
	m.game_opts.merge({"ev": 0.0, "news": 0.0, "fedev": 0, "socev": 0, "exev": 0, "milev": 0, "seed": 5, "country": cc}, true)
	root.add_child(m)
	for i in 3: await process_frame
	m.mil_declare(foe, true)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("mob="): m.mil_mobilize(int(a.substr(4)))
	print("сторон: ", m.mil["war"]["side"], " юнитов: ", m.mil["units"].size())
	for mo in months:
		var t0 := Time.get_ticks_msec()
		for d in 30:
			if m.election_open: m.election_continue()
			if not m.current_event.is_empty():
				print("  событие: ", m.current_event["t"])
				m.choose(0)
			if auto == 1:
				for f in m.mil_units_of(cc):
					if String(f["mode"]) != "auto": m.mil_order_mode(int(f["id"]), "auto")
			m.advance_day()
			if not m.mil_at_war(): break
		if not m.mil_at_war():
			print("мир: ", m.mil["last"]["msg"])
			break
		var w = m.mil["war"]
		print("мес %d: %d мс, счёт %.0f, занято у них %.1f%%, у нас %.1f%%, силы %.0f / %.0f, потери %.1f / %.1f, бои %d:%d, рост %.2f, одобрение %.1f, ВВП %.0f, цель %.2f, mil_g %.2f, fleet_g %.2f, f %.2f" % [mo + 1, Time.get_ticks_msec() - t0, w["score"], w["occ"][1] * 100, w["occ"][0] * 100, m.mil_side_total(0), m.mil_side_total(1), w["kia"][0], w["kia"][1], w["won"], w["lost"], m.growth, m.approval(), m.gdp, m.g_target_last, m.mil_g(), m.fleet_g(), float(m.flt.get("f", 1.0))])
		if "ar" in m and not m.ar.is_empty():
			print("   армия: боеприпасы %.2f (у противника %.2f), дух %.0f / %.0f, воздух x%.2f, авиация %.0f, ПВО %.0f, оснащение %.2f, готовность %.0f" % [float(m.ar["ammo"]), float(w.get("ammo_e", 0.0)), float(w.get("mor", 0.0)), float(w.get("mor_e", 0.0)), m.ar_air_mult(0), float(m.ar["air"]), float(m.ar["ad"]), float(m.ar["eq"]), m.ar_rd()])
	quit()
