extends SceneTree
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	for cc in ["PL","DE","FR"]:
		print(cc, " names ", g.PARTY_NAMES.size(), " traits ", g.PARTY_TRAITS.size(), " mins ", g.PARTY_MINISTRIES.size(), " adj ", g.DE_JOIN_ADJ.size(), " dem ", g.PARTY_DEMANDS.size())
		print("  9: ", g.PARTY_NAMES[9], " traits ", g.PARTY_TRAITS[9], " mins ", g.PARTY_MINISTRIES[9], " w ", g.willingness(9, false))
		break
	quit()
