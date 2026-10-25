extends SceneTree
# dev: проверка законов-ползунков: барьер, срок парламента, срок президента
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	for tid in ["elect_threshold", "parl_term_law", "pres_term_law"]:
		if not g.law_index.has(tid):
			print(tid, ": нет в стране")
			continue
		var t: Dictionary = g.law_index[tid]
		print(tid, " param=", t.has("param"), " ref=", t["param"]["ref"] if t.has("param") else "-", " вариантов ", t["v"].size(), " сейчас ", g.cur_idx(tid))
		if t.has("param"):
			var vs: Array = t["v"]
			var j: int = vs.size() - 1
			print("  ", vs[j]["n"], " set=", vs[j].get("set", {}), " c=", vs[j].get("c", 0), " ps=", vs[j].get("ps", {}))
	var tid2 := "elect_threshold"
	var vs2: Array = g.law_index[tid2]["v"]
	var base_thr: float = float(g.mods["threshold"])
	g.adopt_variant(tid2, 1)
	g.recompute_mods()
	print("после варианта 1: threshold ", base_thr, " -> ", g.mods["threshold"], " (", vs2[1]["n"], ")")
	quit()
