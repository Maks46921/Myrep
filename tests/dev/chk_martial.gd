extends SceneTree
# 0.55.4: проверка военного положения: выборы не проводятся, роспуск запрещён, после отмены выборы откладываются
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	var s0: Array = (g.seats as Array).duplicate()
	print("RES ", g.ccode, " martial=", g.martial_on(), " war=", g.mil_at_war(), " check_on=", g.martial_check(true), " | snap=", g.snap_info())
	if g.martial_on():
		g.hold_parliament("досрочные выборы по вашему решению")
		print("RES seats_same=", str(g.seats) == str(s0), " locked_gov_form=", g.law_locked("gov_form"))
		var ok: bool = g.martial_set(false)
		print("RES lift ok=", ok, " martial=", g.martial_on(), " turn=", g.turn, " last_parl=", g.last_parl, " pres_due=", g.get("pres_due"), " check_off=", g.martial_check(true))
	quit()
