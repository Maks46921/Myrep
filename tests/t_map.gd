extends SceneTree
# Карта: каждый регион своей страны можно выбрать щелчком (проверка для всех регионов).
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	g.show_desk(2)
	for i in 6: await process_frame
	var v: Array = g.map_view()
	var bad := 0
	var n := 0
	var sz: Vector2 = g.map_ctl.size
	print("[%s] карта %dx%d, масштаб %.2f, юнитов %d, регионов %d" % [g.ccode, sz.x, sz.y, v[0], g.map_unit_parts.size(), g.regions.size()])
	for ri in g.regions.size():
		var ui := -1
		for u in g.map_unit_local:
			if int(g.map_unit_local[u]) == ri:
				ui = int(u)
		n += 1
		if ui < 0:
			print("  регион %d: нет юнита на карте" % ri); bad += 1; continue
		var c: Vector2 = pick_point(g, ui, v)
		if c.x == INF:
			bad += 1
			print("  регион %d: нет точки, по которой он выбирается" % ri)
			continue
		var px: Vector2 = c * float(v[0]) + (v[1] as Vector2)
		var hit: int = g.unit_at(px)
		g.selected_region = -1
		g.map_click(hit)
		if g.selected_region == ri and (not g.reg_info_rt.get_parsed_text().contains(String(g.REGIONS[ri]["name"])) or g.map_reg_pick.selected != ri):
			bad += 1
			print("  регион %d (%s): выбран, но окно «Регион: сведения»/список не обновились" % [ri, g.REGIONS[ri]["name"]])
		if hit != ui or g.selected_region != ri:
			bad += 1
			print("  регион %d (%s): юнит %d, по клику юнит %d, выбран %d, точка %s" % [ri, g.REGIONS[ri]["name"], ui, hit, g.selected_region, str(px)])
	print("  выбрано верно: %d из %d" % [n - bad, n])
	if bad > 0: print("FAIL: регионы на карте не выбираются (%d)" % bad)
	quit()

func pick_point(g, ui: int, v: Array) -> Vector2:
	# точка внутри региона, по которой unit_at действительно возвращает этот регион (учитываем анклавы)
	var cen := Vector2(float(g.WORLD_UNITS[ui]["c"][0]), float(g.WORLD_UNITS[ui]["c"][1]))
	if g.unit_at(cen * float(v[0]) + (v[1] as Vector2)) == ui:
		return cen
	var cands: Array = []
	var parts: Array = g.map_unit_parts[ui]
	for part in parts:
		var bb := Rect2(part[0], Vector2.ZERO)
		for q in part: bb = bb.expand(q)
		for iy in 16:
			for ix in 16:
				cands.append(bb.position + Vector2((ix + 0.5) / 16.0 * bb.size.x, (iy + 0.5) / 16.0 * bb.size.y))
	for c in cands:
		var px: Vector2 = c * float(v[0]) + (v[1] as Vector2)
		if g.unit_at(px) == ui:
			return c
	return Vector2(INF, INF)
