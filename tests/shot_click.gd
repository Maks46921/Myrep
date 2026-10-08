extends SceneTree
# Реальный щелчок мышью по карте (нужен xvfb): печатает, какой регион выбрался
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	g.show_desk(2)
	for i in 8: await process_frame
	await create_timer(0.5).timeout
	var v: Array = g.map_view()
	var gr: Rect2 = g.map_ctl.get_global_rect()
	print("карта на экране: ", gr, " окно ", g.wins["map"].visible if g.wins.has("map") else "?")
	var names := []
	var bad := 0
	for ri in g.regions.size():
		var ui := -1
		for u in g.map_unit_local:
			if int(g.map_unit_local[u]) == ri: ui = int(u)
		var c: Vector2 = pick_point(g, ui, v, gr)
		if c.x == INF:
			bad += 1
			print("  регион %d: нет точки, по которой он выбирается" % ri)
			continue
		var gp: Vector2 = gr.position + c * float(v[0]) + (v[1] as Vector2)
		if not gr.has_point(gp):
			names.append("%s: вне видимой карты" % g.REGIONS[ri]["name"]); continue
		var mm := InputEventMouseMotion.new(); mm.position = gp; mm.global_position = gp
		root.get_viewport().push_input(mm)
		await process_frame
		var pr := InputEventMouseButton.new(); pr.button_index = MOUSE_BUTTON_LEFT; pr.pressed = true; pr.position = gp; pr.global_position = gp
		root.get_viewport().push_input(pr)
		await process_frame
		var rl := InputEventMouseButton.new(); rl.button_index = MOUSE_BUTTON_LEFT; rl.pressed = false; rl.position = gp; rl.global_position = gp
		root.get_viewport().push_input(rl)
		await process_frame
		var ok: bool = g.selected_region == ri
		if not ok: bad += 1
		names.append("%s -> выбран %s%s" % [g.REGIONS[ri]["name"], g.REGIONS[g.selected_region]["name"] if g.selected_region >= 0 else "никто", "" if ok else "  <-- FAIL"])
	for n in names: print("  ", n)
	print("FAIL: щелчком выбрано неверно: %d" % bad if bad > 0 else "все регионы выбираются щелчком")
	quit()

func covered(g, gp: Vector2) -> bool:
	# точка закрыта плавающим окном поверх карты (с v29 окна лежат поверх неё) — щелчок туда до карты не дойдёт
	for id in g.wins:
		if id == "map": continue
		var w = g.wins[id]
		if w.visible and w.get_global_rect().has_point(gp): return true
	return false

func pick_point(g, ui: int, v: Array, gr: Rect2) -> Vector2:
	# точка внутри региона, по которой unit_at действительно возвращает этот регион (учитываем анклавы) и которая не закрыта окном
	var cen := Vector2(float(g.WORLD_UNITS[ui]["c"][0]), float(g.WORLD_UNITS[ui]["c"][1]))
	var lp := cen * float(v[0]) + (v[1] as Vector2)
	if g.unit_at(lp) == ui and not covered(g, gr.position + lp):
		return cen
	# v36: кандидаты — центры АТЕ региона
	var cands: Array = []
	for a in g.ate_lists[ui]:
		cands.append(g.ate_c[a])
	for c in cands:
		var px: Vector2 = c * float(v[0]) + (v[1] as Vector2)
		if g.unit_at(px) == ui and gr.has_point(gr.position + px) and not covered(g, gr.position + px):
			return c
	return Vector2(INF, INF)
