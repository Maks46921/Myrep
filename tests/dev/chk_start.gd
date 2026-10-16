extends SceneTree
# 0.55.4: проверка стартовых вариантов законов (LAW_START): вариант применён, нет смены режима и заморозок
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	var out := []
	for tid in g.LAW_START:
		var v: Dictionary = g.variant_of(tid, int(g.law_start_idx(tid)))
		out.append("%s=%d(%s)%s%s" % [tid, int(g.law_state.get(tid, -1)), String(v.get("n", "")), " RID=" + str(v["rid"]) if v.has("rid") else "", " FREEZE=" + str(v["freeze"]) if v.has("freeze") else ""])
	var lk := []
	for t in g.LAW_TOPICS:
		var r = g.law_locked(String(t["id"]))
		if r is String and String(r) != "":
			lk.append(String(t["id"]))
	print("RES ", g.ccode, " cls=", g.regime_class(), " rid=", g.regime_id(), " dem=", snappedf(g.democracy_index(), 0.01), " appr=", snappedf(float(g.approval()), 0.1), " maj=", g.MAJORITY, " | ", ", ".join(out), " | locked:", ",".join(lk))
	quit()
