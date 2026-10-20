extends SceneTree
# 0.59: лампочки, требования партий идут в черновик бюджета, ... (наращивается по мере правок)
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
	# --- лампочки ---
	var iss: Array = g.lamp_issues()
	check(iss is Array, "лампочки: список проблем строится")
	for it in iss:
		check(it.has("id") and it.has("lv") and it.has("page") and it.has("off"), "лампочки: у проблемы есть поля")
	g.nav_extras()
	check(g.lamp_dots.size() >= 7, "лампочки: точки созданы на рамках и вкладках (%d)" % g.lamp_dots.size())
	# --- п.4: требования партнёров идут в черновик ---
	var p := -1
	for q in range(1, g.PARTY_NAMES.size()):
		if g.in_coalition[q] and not (g.PARTY_DEMANDS[q] as Array).is_empty():
			for d in g.PARTY_DEMANDS[q]:
				if not g.demand_met(d):
					p = q
	if p < 0:
		# требований нет или все выполнены: нарушаем одно искусственно
		for q in range(1, g.PARTY_NAMES.size()):
			if not g.in_coalition[q]:
				continue
			for d in g.PARTY_DEMANDS[q]:
				var k: String = d["key"]
				if k != "reg_transfer" and k != "reg_auto" and g.pol.has(k):
					g.set_policy(k, 0.0 if d["op"] == ">=" else g.pol_hi(k))
					if not g.demand_met(d):
						p = q
						break
			if p >= 0:
				break
	if p >= 0:
		check(g.bud_changes().is_empty(), "черновик пуст до требований")
		var cur_before: Dictionary = g.pol.duplicate()
		g.fulfill_party_demands(p)
		check(not g.bud_changes().is_empty(), "требования партии внесены в черновик")
		check(g.bud_demand_by == p, "запомнен автор правок")
		g.bud_cancel()
		check(g.bud_changes().is_empty(), "после отмены черновик пуст")
		for k in cur_before:
			check(absf(float(g.pol[k]) - float(cur_before[k])) < 0.001, "после отмены «%s» вернулась" % k)
	else:
		print("нет партнёра с невыполненными требованиями: пропуск п.4")
	print("t_v059: проблем ", bad)
	quit(1 if bad > 0 else 0)
