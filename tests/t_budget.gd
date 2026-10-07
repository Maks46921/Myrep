extends SceneTree
# Бюджет: два ползунка субсидий, авто-подъём расходов до ожиданий групп, без кнопок пропуска времени.
var bad := 0
func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)
func _init():
	var g = load("res://main.gd").new()
	g.game_opts.merge({"ev": 0.0, "news": 0.0}, true)
	root.add_child(g)
	for i in 3: await process_frame
	check(g.pol.has("subs") and g.pol.has("agri"), "есть оба ползунка субсидий")
	check(g.sliders.has("agri"), "ползунок аграриев в окне")
	check(g.day_btn == null and g.week_btn == null and g.next_btn == null, "нет кнопок пропуска времени")
	check(g.floor_check != null, "есть кнопка авто-подъёма")
	var g0: float = g.growth
	g.set_policy("agri", float(g.pol["agri"]) + 1.0)
	check(g.target_support("Село") > 0.0, "поддержка считается")
	# v35: авто-подъём поднимает статьи до ожиданий социальных групп
	var fl: float = g.floor_share("edu")
	g.pol["edu"] = maxf(0.0, fl - 1.0)
	var e0: float = g.pol["edu"]
	var n: int = g.auto_floor()
	check(n >= 1 and float(g.pol["edu"]) >= minf(fl, e0 + 0.9), "расходы подняты до ожиданий групп (%s → %s, ждут %s)" % [str(e0), str(g.pol["edu"]), str(fl)])
	g.next_turn()
	check(is_finite(g.gdp), "месяц идёт")
	print("t_budget: проблем ", bad)
	quit(1 if bad > 0 else 0)
