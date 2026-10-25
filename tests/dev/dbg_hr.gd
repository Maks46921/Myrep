extends SceneTree
func _init():
	var g = load("res://main.gd").new()
	g.game_opts.merge({"ev": 0.0, "news": 0.0}, true)
	root.add_child(g)
	for i in 3: await process_frame
	for q in range(1, g.PARTY_NAMES.size()):
		print(q, g.PARTY_NAMES[q], " coal ", g.in_coalition[q], " dem ", g.PARTY_DEMANDS[q].map(func(d): return [d["key"], d["val"], g.demand_met(d)]))
	print("draft ", g.bud_draft_on(), " opp ", g.opp_mode, " deny ", g.pl_deny())
	quit()
