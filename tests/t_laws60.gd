extends SceneTree
# 0.60: новые законы: темы строятся, у каждой есть область, стартовые варианты и ползунки применены, расчёт эффектов не падает.
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
	var n60 := 0
	var base: Dictionary = g.compute_mods(g.law_state, false)
	for tp in g.LAW_TOPICS:
		var tid: String = String(tp["id"])
		check(g.law_area(tid) >= 0 and g.law_area(tid) < 11, "%s: нет области" % tid)
		if not g.is_law60(tid):
			continue
		n60 += 1
		var vs: Array = tp["v"]
		check(vs.size() >= 3, "%s: мало вариантов" % tid)
		var cur: int = int(g.law_state.get(tid, 0))
		for i in vs.size():
			var st: Dictionary = g.law_state.duplicate()
			st[tid] = i
			var m: Dictionary = g.compute_mods(st, false)
			for k in m:
				if typeof(m[k]) == TYPE_FLOAT:
					check(not is_nan(m[k]) and not is_inf(m[k]), "%s/%d: %s не число" % [tid, i, k])
			check(String(vs[i]["n"]) != "", "%s/%d: пустое имя" % [tid, i])
		if tp.has("param"):
			var pr: Dictionary = tp["param"]
			check(pr["grid"].size() >= 3, "%s: сетка ползунка мала" % tid)
	# особые законы страны: есть в списке, места партий в пределах числа партий
	var own: Array = g.COUNTRY_TOPICS60.get(g.ccode, [])
	check(own.size() >= 3, "особых законов страны мало (%d)" % own.size())
	for t in own:
		check(g.law_index.has(t["id"]), "особый закон %s не попал в список" % t["id"])
		for v in t["v"]:
			for p in v.get("ps", {}):
				check(int(p) >= 0 and int(p) < g.PARTY_NAMES.size(), "%s: место партии %s вне списка" % [t["id"], str(p)])
	print("%s: особых законов %d" % [g.ccode, own.size()])
	print("%s: тем 0.60 в стране %d, всего тем %d, стартовых отличий %d" % [g.ccode, n60, g.LAW_TOPICS.size(), g.LAW_START.size()])
	print("проблем %d" % bad)
	quit()
