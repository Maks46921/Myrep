extends SceneTree
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	for cc in ["DE"]:
		for tid in ["income_tax_law", "corp_tax_law", "vat_law"]:
			var t: Dictionary = g.law_index[tid]
			print(tid, " param=", t.has("param"), " n=", t["v"].size(), " cur=", g.cur_idx(tid))
			var vs: Array = t["v"]
			print("  last: ", vs[vs.size()-1]["n"], " x=", vs[vs.size()-1].get("x", {}), " c=", vs[vs.size()-1]["c"])
			print("  mid: ", vs[1]["n"], " x=", vs[1].get("x", {}))
	var inc0: float = float(g.mods.get("income_mult", 1.0))
	g.adopt_variant("income_tax_law", g.law_index["income_tax_law"]["v"].size() - 1)
	g.recompute_mods()
	print("income_mult ", inc0, " -> ", g.mods.get("income_mult"))
	quit()
