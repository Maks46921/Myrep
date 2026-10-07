extends SceneTree
# Бюджет: два ползунка субсидий, авто-подъём расходов до минимума коалиции, без кнопок пропуска времени.
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
	# искусственное требование коалиции
	var p := -1
	for k in range(1, g.PARTY_NAMES.size()):
		p = k
		break
	g.in_coalition[p] = true
	var old_d = g.PARTY_DEMANDS[p]
	g.PARTY_DEMANDS[p] = [{"key": "edu", "op": ">=", "val": float(g.pol["edu"]) + 1.0, "text": "тест"}]
	var e0: float = g.pol["edu"]
	var n: int = g.auto_floor()
	check(n >= 1 and float(g.pol["edu"]) > e0 + 0.9, "расходы подняты до минимума (%s → %s)" % [str(e0), str(g.pol["edu"])])
	g.PARTY_DEMANDS[p] = old_d
	g.next_turn()
	check(is_finite(g.gdp), "месяц идёт")
	print("t_budget: проблем ", bad)
	quit(1 if bad > 0 else 0)
