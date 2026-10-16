extends SceneTree
# 0.55.5: Косово — барьер 5%, списки общин без барьера
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	print("threshold=", g.mods["threshold"], " shares=", g.parl_shares())
	g.hold_parliament("тест")
	if g.election_open: g.election_continue()
	print("seats=", g.seats)
	var lt: Dictionary = g.law_index.get("elect_threshold", {})
	if not lt.is_empty():
		print("variant0=", lt["v"][0]["n"])
	quit()
