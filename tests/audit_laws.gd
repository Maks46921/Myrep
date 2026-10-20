extends SceneTree
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	var base: Dictionary = g.compute_mods(g.law_state, false)
	var out := []
	for tp in g.LAW_TOPICS:
		var tid: String = String(tp["id"])
		var cur: int = int(g.law_state.get(tid, 0))
		var vs: Array = tp.get("v", [])
		for i in vs.size():
			var st: Dictionary = g.law_state.duplicate()
			st[tid] = i
			var m: Dictionary = g.compute_mods(st, false)
			var d := []
			for k in m:
				var a = base.get(k, 0)
				if typeof(m[k]) in [TYPE_FLOAT, TYPE_INT] and absf(float(m[k]) - float(a)) > 1e-6:
					d.append("%s:%+.3f" % [k, float(m[k]) - float(a)])
			out.append("%s|%d|%s" % [tid, i, " ".join(d)])
	var f := FileAccess.open("/tmp/work056/audit_laws_%s.txt" % g.ccode, FileAccess.WRITE)
	for l in out: f.store_line(l)
	f.close()
	quit()
