extends SceneTree
func _init():
	var m = load("res://main.gd").new()
	m.game_opts.merge({"ev": 0.0, "news": 0.0, "fedev": 0, "socev": 0, "exev": 0, "milev": 0, "seed": 5, "country": "CZ"}, true)
	root.add_child(m)
	for i in 3: await process_frame
	print("ccode ", m.ccode)
	m.mil_declare("AT", true)
	m.mil_mobilize(1)
	for d in 60:
		if not m.current_event.is_empty(): m.choose(0)
		for f in m.mil_units_of(m.ccode):
			if String(f["mode"]) != "auto": m.mil_order_mode(int(f["id"]), "auto")
		m.advance_day()
		if d % 10 == 9:
			var s := ""
			for f in m.mil["units"]:
				s += "[%s %s a=%s p=%d fight=%d org=%.2f str=%.1f m=%s] " % [f["cc"], f["nm"].substr(0, 6), m.ate_name(int(f["a"])) if int(f["a"]) >= 0 else "-", (f["path"] as Array).size(), int(f["fight"]), f["org"], f["str"], f["mode"]]
			print("день ", d + 1, " P0 ", snappedf(m.mil_side_power(0), 0.1), " P1 ", snappedf(m.mil_side_power(1), 0.1), " occ ", m.mil["war"]["occ"], "\n  ", s)
	quit()
