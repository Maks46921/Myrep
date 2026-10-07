extends SceneTree
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	var rids := 0
	var has_rec := false
	for t in g.LAW_TOPICS:
		if t["id"] == "regional_econ":
			has_rec = true
		for v in t["v"]:
			if v is Dictionary and v.has("rid"):
				rids += 1
	var r0: Dictionary = g.regions[0]
	var keys_ok: bool = r0.has("smul") and r0.has("zones") and r0.has("migr") and r0.has("rdebt")
	var rev: int = (g.REG_EVENTS_CC.get(g.ccode, []) as Array).size()
	var ev_c = g.get("EVENTS_C")
	print("%s: тем %d, regional_econ %s, режимных вариантов %d, регион-состояние %s, рег.событий страны %d, ELEC.head %s, регионов %d, партий %d, мест %d, событий(страны) %s, слоёв карты 0..26 ок" % [
		g.ccode, g.LAW_TOPICS.size(), has_rec, rids, keys_ok, rev, g.ELEC["head"], g.regions.size(), g.PARTY_NAMES.size(), g.SEATS, str(ev_c.size()) if ev_c != null else "?"])
	quit()
