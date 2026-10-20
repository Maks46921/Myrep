extends SceneTree
# 0.58: что даёт расчёт мест при стартовых опросах: доли, места, число партий. Запуск: -- country=GB
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	var ps: Array = g.parl_shares()
	var raw: Array = g.national_shares(false)
	var ss: Array = g.allocate_seats(ps)
	var tot := 0
	var parts := []
	for p in ps.size():
		tot += int(ss[p])
		parts.append("%d:%.1f%%/%d" % [p, float(raw[p]) * 100.0, ss[p]])
	print("PROBE %s sys=%s seats=%d/%d | %s" % [g.ccode, g.ELEC.get("alloc", "hare"), tot, g.SEATS, " ".join(parts)])
	quit()
