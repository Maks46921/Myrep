# Интерфейс: карта, таблица регионов, региональная экономика.
extends "res://scripts/ui/ui_core.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func draw_war_overlay(c: Control, ci: RID, s: float) -> void:
	pass


func draw_war_tokens(c: Control, s: float, off: Vector2, font: Font) -> void:
	pass


func fed_btn(text: String, parent: Control, tip: String = "") -> Button:
	return null


func fed_opt(parent: Control, items: Array, tip: String = "") -> OptionButton:
	return null


func fed_pct(p: float) -> String:
	return ""


func update_fregion() -> void:
	pass


func war_hover(pos: Vector2) -> void:
	pass


func war_map_click(pos: Vector2, shift: bool) -> void:
	pass


# --- конец заглушек ---


var reg_grid: GridContainer
var transfer_parent: Control
# v36: карта из АТЕ
const MAP_HCELL := 12.0
var map_ate_tris: Array = []          # АТЕ -> треугольники (PackedVector2Array, по 3 точки)
var map_all_mesh: ArrayMesh            # все АТЕ одним мешем (тень)
var map_unit_mesh: Array = []          # единица карты -> меш её АТЕ
var map_ln_ate := PackedVector2Array() # тонкие границы АТЕ внутри регионов
var map_ln_reg := PackedVector2Array() # границы регионов одной страны (пары точек)
var map_ln_cty := PackedVector2Array() # границы стран и побережье
var map_hash := {}
var map_seg_cache := {}
var map_hover_ate := -1
var map_fit_cc := ""
var adm_ui := {}

func on_layer_selected(i: int) -> void:
	map_layer = int(MAP_LAYER_ORDER[i])
	update_regions_ui()


func fill_table_rows() -> void:
	reg_table_rows.clear()
	for k in REGIONS.size():
		var nb := Button.new()
		nb.flat = true
		nb.theme_type_variation = "SmallButton"
		nb.add_theme_font_size_override("font_size", 13)
		nb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		nb.focus_mode = Control.FOCUS_NONE
		nb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nb.clip_text = true
		nb.pressed.connect(on_table_row.bind(k))
		reg_grid.add_child(nb)
		var cells: Array = []
		for c in 8:
			var cl := Label.new()
			cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cl.add_theme_font_size_override("font_size", 13)
			reg_grid.add_child(cl)
			cells.append(cl)
		reg_table_rows.append({"name": nb, "cells": cells})


func fill_transfer_rows() -> void:
	transfer_sliders.clear()
	transfer_labels.clear()
	for i in REGIONS.size():
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 0)
		transfer_parent.add_child(vb)
		var tl := Label.new()
		tl.add_theme_font_size_override("font_size", 13)
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(tl)
		var ts := HSlider.new()
		ts.min_value = 0.0
		ts.max_value = 5.0
		ts.step = 0.1
		ts.scrollable = false
		ts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ts.custom_minimum_size = Vector2(60.0, 18.0)
		ts.value_changed.connect(on_transfer_slider.bind(i))
		vb.add_child(ts)
		transfer_sliders.append(ts)
		transfer_labels.append(tl)


func rebuild_region_widgets() -> void:
	# число регионов изменилось (покупка, продажа, объединение): пересобрать списки и таблицы
	if reg_grid == null:
		return
	for row in reg_table_rows:
		(row["name"] as Node).queue_free()
		for cl in row["cells"]:
			(cl as Node).queue_free()
	fill_table_rows()
	for ts in transfer_sliders:
		(ts as Node).get_parent().queue_free()
	fill_transfer_rows()
	map_reg_pick.clear()
	for r in REGIONS:
		map_reg_pick.add_item(String(r["name"]))
	if selected_region >= 0 and selected_region < REGIONS.size():
		map_reg_pick.select(selected_region)
	fix_wraps_later()


func map_rebuild() -> void:
	# после передачи территории: пересчитать геометрию карты и обновить окна
	rebuild_region_widgets()
	map_prepare()
	if map_ctl != null:
		map_ctl.queue_redraw()
	update_regions_ui()


func map_prepare() -> void:
	# v36: карта строится из АТЕ — заливка регионов сеткой треугольников (меш на каждую единицу карты),
	# линии трёх уровней: тонкие границы АТЕ, границы регионов, границы стран и побережье
	ate_load()
	if ate_unit.size() != ate_n:
		ate_reset()
	elif ate_lists.size() != WORLD_UNITS.size():
		ate_rebuild([])
	map_unit_parts.clear()
	map_unit_rect.clear()
	map_unit_local.clear()
	map_ctx_parts.clear()
	map_cc_outline.clear()
	map_ctx_cent.clear()
	map_seg_cache.clear()
	var tv: PackedFloat32Array = ATE["tv"]
	var to: PackedInt32Array = ATE["to"]
	if map_ate_tris.size() != ate_n:
		map_ate_tris.clear()
		map_all_mesh = null
		var all := PackedVector2Array()
		for a in ate_n:
			var pts := PackedVector2Array()
			pts.resize((to[a + 1] - to[a]) * 3)
			var k0: int = to[a] * 6
			for k in pts.size():
				pts[k] = Vector2(tv[k0 + 2 * k], tv[k0 + 2 * k + 1])
			map_ate_tris.append(pts)
			all.append_array(pts)
		map_all_mesh = map_tri_mesh(all)
		# сетка-«хэш» для поиска АТЕ под курсором
		var hh := {}
		for a in ate_n:
			var r: Rect2 = ate_rect[a]
			for gx in range(floori(r.position.x / MAP_HCELL), floori(r.end.x / MAP_HCELL) + 1):
				for gy in range(floori(r.position.y / MAP_HCELL), floori(r.end.y / MAP_HCELL) + 1):
					var key := Vector2i(gx, gy)
					if not hh.has(key):
						hh[key] = []
					(hh[key] as Array).append(a)
		map_hash.clear()
		for key in hh:
			map_hash[key] = PackedInt32Array(hh[key])
	var local := {}
	for i in REGIONS.size():
		local[String(REGIONS[i].get("uid", ccode + "-" + String(REGIONS[i]["code"])))] = i
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	map_unit_mesh.clear()
	for ui in WORLD_UNITS.size():
		var u: Dictionary = WORLD_UNITS[ui]
		var lst: PackedInt32Array = ate_lists[ui] if ui < ate_lists.size() else PackedInt32Array()
		map_unit_parts.append([])
		if lst.is_empty():
			map_unit_rect.append(Rect2())
			map_unit_mesh.append(null)
			continue
		var rr: Rect2 = ate_rect[lst[0]]
		var pts := PackedVector2Array()
		for a in lst:
			rr = rr.merge(ate_rect[a])
			pts.append_array(map_ate_tris[a])
		map_unit_rect.append(rr)
		map_unit_mesh.append(map_tri_mesh(pts))
		lo = Vector2(minf(lo.x, rr.position.x), minf(lo.y, rr.position.y))
		hi = Vector2(maxf(hi.x, rr.end.x), maxf(hi.y, rr.end.y))
		if String(u["cc"]) == ccode and local.has(String(u["id"])):
			map_unit_local[ui] = int(local[String(u["id"])])
	map_bounds = Rect2(lo, hi - lo)
	# линии: каждое общее ребро АТЕ относится к одному из трёх уровней
	var ea: PackedInt32Array = ATE["ea"]
	var eb: PackedInt32Array = ATE["eb"]
	var eo: PackedInt32Array = ATE["eo"]
	var ep: PackedFloat32Array = ATE["ep"]
	var l_ate := PackedVector2Array()
	map_ln_reg = PackedVector2Array()
	map_ln_cty = PackedVector2Array()
	for e in ea.size():
		var ua: int = ate_unit[ea[e]]
		var lvl := 2
		if eb[e] >= 0:
			var ub: int = ate_unit[eb[e]]
			if ua == ub:
				lvl = 0
			elif String(WORLD_UNITS[ua]["cc"]) == String(WORLD_UNITS[ub]["cc"]):
				lvl = 1
		var dst: PackedVector2Array = l_ate if lvl == 0 else (map_ln_reg if lvl == 1 else map_ln_cty)
		for k in range(eo[e], eo[e + 1] - 1):
			dst.append(Vector2(ep[2 * k], ep[2 * k + 1]))
			dst.append(Vector2(ep[2 * k + 2], ep[2 * k + 3]))
	map_ln_ate = l_ate
	for cx in WORLD_CTX:
		var lst2: Array = []
		var best := PackedVector2Array()
		var ba := -1.0
		for part in cx["parts"]:
			var pts2 := PackedVector2Array()
			for k in range(0, (part as Array).size(), 2):
				pts2.append(Vector2(float(part[k]), float(part[k + 1])))
			lst2.append(pts2)
			var ar := absf(polygon_area(pts2))
			if ar > ba:
				ba = ar
				best = pts2
		map_ctx_parts.append(lst2)
		var cen := Vector2.ZERO
		for p in best:
			cen += p
		map_ctx_cent.append(cen / float(maxi(1, best.size())))
	if map_fit_cc != ccode:
		map_fit_cc = ccode
		map_inited = false


func map_tri_mesh(pts: PackedVector2Array) -> ArrayMesh:
	if pts.is_empty():
		return null
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = pts
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m


func map_border_segs(key: String) -> PackedVector2Array:
	# контур набора АТЕ как отрезки: "u<номер>" — единица карты, "c<код>" — страна, "s" — выделенные АТЕ
	if map_seg_cache.has(key):
		return map_seg_cache[key]
	var inside := func(a: int) -> bool: return false
	if key.begins_with("u"):
		var ui: int = int(key.substr(1))
		inside = func(a: int) -> bool: return ate_unit[a] == ui
	elif key.begins_with("c"):
		var cc := key.substr(1)
		inside = func(a: int) -> bool: return String(WORLD_UNITS[ate_unit[a]]["cc"]) == cc
	else:
		var ss := {}
		for a in ate_sel:
			ss[int(a)] = true
		inside = func(a: int) -> bool: return ss.has(a)
	var ea: PackedInt32Array = ATE["ea"]
	var eb: PackedInt32Array = ATE["eb"]
	var eo: PackedInt32Array = ATE["eo"]
	var ep: PackedFloat32Array = ATE["ep"]
	var out := PackedVector2Array()
	for e in ea.size():
		var ia: bool = inside.call(ea[e])
		var ib: bool = eb[e] >= 0 and inside.call(eb[e])
		if ia == ib:
			continue
		for k in range(eo[e], eo[e + 1] - 1):
			out.append(Vector2(ep[2 * k], ep[2 * k + 1]))
			out.append(Vector2(ep[2 * k + 2], ep[2 * k + 3]))
	map_seg_cache[key] = out
	return out


func map_view() -> Array:
	var c := map_ctl
	var s0: float = minf(c.size.x / maxf(1.0, map_bounds.size.x), c.size.y / maxf(1.0, map_bounds.size.y)) * 0.96
	var s: float = s0 * map_zoom
	return [s, c.size * 0.5 - map_center * s, s0]


func map_country_rect(code: String) -> Rect2:
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	for ui in WORLD_UNITS.size():
		if String(WORLD_UNITS[ui]["cc"]) != code:
			continue
		var r: Rect2 = map_unit_rect[ui]
		lo = Vector2(minf(lo.x, r.position.x), minf(lo.y, r.position.y))
		hi = Vector2(maxf(hi.x, r.end.x), maxf(hi.y, r.end.y))
	return Rect2(lo, hi - lo)


# часть карты, не закрытая боковыми окнами (окна лежат поверх карты с v29), в координатах map_ctl
func map_free_rect() -> Rect2:
	var c := map_ctl
	var gr := c.get_global_rect()
	var lo := 0.0
	var hi := c.size.x
	for id in wins:
		if id == "map": continue
		var w: Control = wins[id]
		if w == null or not w.visible: continue
		var wr := w.get_global_rect()
		if not wr.intersects(gr) or wr.size.y < gr.size.y * 0.3: continue
		var a := wr.position.x - gr.position.x
		var b := wr.end.x - gr.position.x
		if (a + b) * 0.5 < c.size.x * 0.5: lo = maxf(lo, b)
		else: hi = minf(hi, a)
	if hi - lo < c.size.x * 0.35:      # окна закрывают почти всё — вписываем в карту целиком
		return Rect2(Vector2.ZERO, c.size)
	return Rect2(Vector2(lo, 0.0), Vector2(hi - lo, c.size.y))


func map_fit_rect(r: Rect2) -> void:
	var v := map_view()
	var s0: float = v[2]
	var c := map_ctl
	var fr := map_free_rect()
	var s: float = minf(fr.size.x / maxf(1.0, r.size.x * 1.15), fr.size.y / maxf(1.0, r.size.y * 1.2))
	map_zoom = clampf(s / s0, 0.7, 16.0)
	s = s0 * map_zoom
	# центр страны — в середину свободной части карты
	map_center = r.get_center() - (fr.get_center() - c.size * 0.5) / s
	map_ctl.queue_redraw()


func map_zoom_cmd(k: int) -> void:
	match k:
		1: map_zoom_at(map_ctl.size * 0.5, 1.35)
		2: map_zoom_at(map_ctl.size * 0.5, 1.0 / 1.35)
		3: map_fit_rect(map_country_rect(ccode))
		4:
			map_zoom = 1.0
			map_center = map_bounds.get_center()
			map_ctl.queue_redraw()


func map_zoom_at(pos: Vector2, f: float) -> void:
	var v := map_view()
	var s: float = v[0]
	var off: Vector2 = v[1]
	var wp: Vector2 = (pos - off) / s
	map_zoom = clampf(map_zoom * f, 0.7, 16.0)
	var s2: float = float(map_view()[0])
	map_center = wp - (pos - map_ctl.size * 0.5) / s2
	map_clamp()
	map_ctl.queue_redraw()


func map_clamp() -> void:
	var r := map_bounds.grow(maxf(map_bounds.size.x, map_bounds.size.y) * 0.15)
	map_center = Vector2(clampf(map_center.x, r.position.x, r.end.x), clampf(map_center.y, r.position.y, r.end.y))


# малые регионы своей страны (Берлин, Бремен…) на текущем масштабе: их можно выбрать по «булавке»
func unit_is_tiny(ui: int, s: float) -> bool:
	var r: Rect2 = map_unit_rect[ui]
	return maxf(r.size.x, r.size.y) * s < 16.0


func ate_at(local: Vector2) -> int:
	# АТЕ под точкой экрана
	var v := map_view()
	var pt: Vector2 = (local - (v[1] as Vector2)) / float(v[0])
	var key := Vector2i(floori(pt.x / MAP_HCELL), floori(pt.y / MAP_HCELL))
	if not map_hash.has(key):
		return -1
	for a in (map_hash[key] as PackedInt32Array):
		if not (ate_rect[a] as Rect2).has_point(pt):
			continue
		var t: PackedVector2Array = map_ate_tris[a]
		for k in range(0, t.size(), 3):
			if Geometry2D.point_is_inside_triangle(pt, t[k], t[k + 1], t[k + 2]):
				return a
	return -1


func unit_at(local: Vector2) -> int:
	var v := map_view()
	var s: float = v[0]
	var off: Vector2 = v[1]
	# 1) булавки малых регионов своей страны
	if not ate_mode:
		for ui in map_unit_local:
			if unit_is_tiny(ui, s):
				var cp := Vector2(float(WORLD_UNITS[ui]["c"][0]), float(WORLD_UNITS[ui]["c"][1])) * s + off
				if cp.distance_to(local) <= 9.0:
					return ui
	var a := ate_at(local)
	if a >= 0:
		return ate_unit[a]
	# 2) допуск у границы: щелчок рядом с регионом своей страны (побережье, дрожание руки)
	var pt: Vector2 = (local - off) / s
	var tol: float = 7.0 / s
	var best := -1
	var bd := tol * tol
	var key := Vector2i(floori(pt.x / MAP_HCELL), floori(pt.y / MAP_HCELL))
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			var k2 := key + Vector2i(dx, dy)
			if not map_hash.has(k2):
				continue
			for b in (map_hash[k2] as PackedInt32Array):
				if not map_unit_local.has(ate_unit[b]) or not (ate_rect[b] as Rect2).grow(tol).has_point(pt):
					continue
				for q in (map_ate_tris[b] as PackedVector2Array):
					var d2: float = q.distance_squared_to(pt)
					if d2 < bd:
						bd = d2
						best = ate_unit[b]
	return best


func ctx_at(local: Vector2) -> int:
	var v := map_view()
	var pt: Vector2 = (local - (v[1] as Vector2)) / float(v[0])
	for ci in map_ctx_parts.size():
		for part in (map_ctx_parts[ci] as Array):
			if Geometry2D.is_point_in_polygon(pt, part):
				return ci
	return -1


func unit_tip(ui: int) -> String:
	if ui < 0:
		return ""
	var u: Dictionary = WORLD_UNITS[ui]
	var cc: String = String(u["cc"])
	if cc == ccode:
		return region_tip(int(map_unit_local[ui]))
	var rn := ""
	for r in WORLD[cc]["regions"]:
		if String(r["id"]) == String(u["id"]):
			rn = String(r["name"])
	var w: Dictionary = wsim[cc]
	var t := "%s — %s\nРост %.1f%%, инфляция %.1f%%, безработица %.1f%%, долг %.0f%% ВВП\n" % [WORLD[cc]["name"], rn, float(w["growth"]), float(w["infl"]), float(w["unemp"]), float(w["debt"])]
	if dip.has(cc):
		t += "Отношения с вами: %.0f (%s)\n" % [float(dip[cc]["rel"]), dip_rel_name(float(dip[cc]["rel"]))]
	return t + "Щёлкните, чтобы открыть сведения."


func map_click(ui: int) -> void:
	if ui < 0:
		return
	var cc: String = String(WORLD_UNITS[ui]["cc"])
	if cc == ccode:
		map_mode = "own"
		map_sel_unit = -1
		fmap_win_open = false
		selected_region = int(map_unit_local[ui])
	elif map_mode == "foreign" and dip_sel == cc:
		# повторный щелчок по той же стране: открываем окно региона (ещё один щелчок по нему — назад к стране)
		if fmap_win_open and map_sel_unit == ui:
			fmap_win_open = false
		else:
			fmap_win_open = true
			map_sel_unit = ui
	else:
		# первый щелчок по чужой стране: сначала окно взаимодействия со страной
		map_mode = "foreign"
		map_sel_unit = ui
		dip_sel = cc
		fmap_win_open = false
	map_apply_mode()
	refresh()


func on_region_picked(i: int) -> void:
	map_mode = "own"
	map_sel_unit = -1
	fmap_win_open = false
	selected_region = i
	map_apply_mode()
	refresh()


func map_apply_mode() -> void:
	if current_desk != 2:
		return
	for id in ["region", "regact", "regecon", "regtable"]:
		win_vis(id, map_mode == "own")
	var fr: bool = map_mode == "foreign"
	win_vis("dinfo", fr and not fmap_win_open)
	win_vis("fregion", fr and fmap_win_open)
	win_vis("dact", fr)
	win_vis("dtable", fr)


func on_map_input(ev: InputEvent) -> void:
	var mm := ev as InputEventMouseMotion
	if mm != null:
		if map_drag:
			if (mm.position - map_drag_start).length() > 10.0:
				map_drag_moved = true
			if map_drag_moved:
				map_center -= mm.relative / float(map_view()[0])
				map_clamp()
				map_ctl.queue_redraw()
			return
		if current_desk == 13 or current_desk == 14:
			war_hover(mm.position)
			return
		var ui := unit_at(mm.position)
		var ha := ate_at(mm.position) if ate_mode else -1
		var ci := -1
		if ui < 0:
			ci = ctx_at(mm.position)
		map_ctl.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if ui >= 0 else Control.CURSOR_ARROW
		if ui != map_hover_unit or ci != map_hover_ctx or ha != map_hover_ate:
			map_hover_unit = ui
			map_hover_ctx = ci
			map_hover_ate = ha
			if ha >= 0:
				map_ctl.tooltip_text = ate_tip(ha)
			elif ui >= 0:
				map_ctl.tooltip_text = unit_tip(ui)
			elif ci >= 0:
				map_ctl.tooltip_text = "%s\nСтрана пока не входит в игру." % String(WORLD_CTX[ci]["name"])
			else:
				map_ctl.tooltip_text = ""
			map_ctl.queue_redraw()
		return
	var mb := ev as InputEventMouseButton
	if mb == null:
		return
	if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
		map_zoom_at(mb.position, 1.25)
	elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		map_zoom_at(mb.position, 0.8)
	elif mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_MIDDLE or mb.button_index == MOUSE_BUTTON_RIGHT:
		if mb.pressed:
			map_drag = true
			map_drag_moved = false
			map_drag_start = mb.position
		else:
			if map_drag and not map_drag_moved and mb.button_index == MOUSE_BUTTON_LEFT and (current_desk == 13 or current_desk == 14):
				war_map_click(mb.position, mb.shift_pressed)
			elif map_drag and not map_drag_moved and mb.button_index == MOUSE_BUTTON_LEFT:
				if current_desk != 2 and current_desk != 8 and current_desk != 9:
					show_desk(2)
				if ate_mode and current_desk == 2:
					ate_click(ate_at(mb.position), mb.shift_pressed)
				else:
					map_click(unit_at(mb.position))
			map_drag = false


func build_map_windows() -> void:
	var w: FloatWindow = new_window("map", "Карта: слои и масштаб", 2, Rect2(0.0, 0.0, 0.25, 0.19))
	var hb := HBoxContainer.new()
	w.body.add_child(hb)
	var l := Label.new()
	l.text = "Слой:"
	hb.add_child(l)
	var ob := OptionButton.new()
	ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ob.focus_mode = Control.FOCUS_NONE
	ob.fit_to_longest_item = false
	ob.clip_text = true
	for lid in MAP_LAYER_ORDER:
		ob.add_item(MAP_LAYERS[lid])
	ob.item_selected.connect(on_layer_selected)
	hb.add_child(ob)
	var hb2 := HBoxContainer.new()
	w.body.add_child(hb2)
	var l2 := Label.new()
	l2.text = "Регион:"
	hb2.add_child(l2)
	map_reg_pick = OptionButton.new()
	map_reg_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_reg_pick.focus_mode = Control.FOCUS_NONE
	map_reg_pick.fit_to_longest_item = false
	map_reg_pick.clip_text = true
	map_reg_pick.tooltip_text = "Выбор региона из списка — то же, что щелчок по региону на карте."
	for r in REGIONS:
		map_reg_pick.add_item(String(r["name"]))
	map_reg_pick.item_selected.connect(on_region_picked)
	hb2.add_child(map_reg_pick)
	map_ctl = Control.new()
	map_base.add_child(map_ctl)
	map_ctl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_ctl.clip_contents = true
	map_ctl.draw.connect(draw_map)
	map_ctl.gui_input.connect(on_map_input)
	map_ctl.mouse_exited.connect(func() -> void:
		map_drag = false
		map_hover_unit = -1
		map_hover_ate = -1
		map_ctl.queue_redraw())
	map_prepare()
	var zrow := HBoxContainer.new()
	zrow.add_theme_constant_override("separation", 3)
	w.body.add_child(zrow)
	for zb in [["＋", "Приблизить (или колёсико мыши)", 1], ["−", "Отдалить", 2], ["⌂", "К вашей стране", 3], ["Европа", "Показать все страны", 4]]:
		var zbtn := Button.new()
		zbtn.text = zb[0]
		zbtn.tooltip_text = zb[1]
		zbtn.focus_mode = Control.FOCUS_NONE
		zbtn.theme_type_variation = "SmallButton"
		zbtn.pressed.connect(map_zoom_cmd.bind(int(zb[2])))
		zrow.add_child(zbtn)
	var ab := make_button("Административная реформа (АТЕ)…", w.body)
	ab.tooltip_text = "Регионы состоят из АТЕ — единиц ~600 км². Здесь можно перекроить границы регионов, создать или упразднить регион, купить часть земли соседа."
	ab.pressed.connect(adm_open)
	map_legend = add_note(w.body, "")

	w = new_window("regtable", "Регионы: сводка (заголовки сортируют)", 2, Rect2(0.25, 0.70, 0.45, 0.30))
	reg_summary = add_wrap_label(w.body, "")
	var grid := GridContainer.new()
	grid.columns = 9
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 0)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	w.body.add_child(grid)
	var heads := ["Регион", "Нас.", "ВВП", "Лоял.", "Недов.", "ВВП/душа", "Безр.", "Рост", "Долг"]
	for c in heads.size():
		var hbn := Button.new()
		hbn.text = heads[c]
		hbn.flat = true
		hbn.theme_type_variation = "SmallButton"
		hbn.focus_mode = Control.FOCUS_NONE
		hbn.add_theme_font_size_override("font_size", 12)
		hbn.tooltip_text = "Сортировать по этому столбцу"
		hbn.alignment = HORIZONTAL_ALIGNMENT_LEFT if c == 0 else HORIZONTAL_ALIGNMENT_CENTER
		if c == 0:
			hbn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbn.pressed.connect(set_sort.bind(c))
		grid.add_child(hbn)
	reg_grid = grid
	fill_table_rows()

	w = new_window("region", "Регион: сведения", 2, Rect2(0.0, 0.19, 0.25, 0.81))
	reg_info_rt = make_rt(w.body)
	add_bar(w.body, "rb_loy", "Лояльность", false)
	add_bar(w.body, "rb_unrest", "Недовольство", true)
	add_bar(w.body, "rb_infra", "Инфраструктура", false)
	add_bar(w.body, "rb_edu", "Образование", false)
	add_bar(w.body, "rb_health", "Здоровье", false)
	add_bar(w.body, "rb_env", "Экология", false)
	add_title(w.body, "Министр-президент земли")
	gov_info_rt = make_rt(w.body)
	gov_buttons.clear()
	for kind in [1, 2, 3]:
		var b := make_button("", w.body)
		b.pressed.connect(appoint_governor.bind(kind))
		gov_buttons.append(b)
	add_title(w.body, "Строительный проект")
	proj_label = add_wrap_label(w.body, "")
	proj_option = OptionButton.new()
	proj_option.focus_mode = Control.FOCUS_NONE
	proj_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	proj_option.fit_to_longest_item = false
	proj_option.clip_text = true
	proj_option.custom_minimum_size = Vector2(60.0, 0.0)
	for pd in PROJECTS:
		proj_option.add_item("%s: %.2f%% ВВП, %d мес." % [pd["name"], pd["cost"], pd["months"]])
	proj_option.item_selected.connect(func(_i: int) -> void: update_region_info())
	w.body.add_child(proj_option)
	proj_start = make_button("Начать проект (политкапитал 2)", w.body)
	proj_start.pressed.connect(start_project)
	proj_cancel = make_button("Остановить проект", w.body)
	proj_cancel.pressed.connect(cancel_project)

	build_regecon_window()
	w = new_window("regact", "Действия и трансферты", 2, Rect2(0.45, 0.55, 0.255, 0.45))
	add_title(w.body, "Быстрые действия")
	for a in REGION_ACTIONS:
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 1)
		w.body.add_child(vb)
		var b := make_button("", vb)
		b.pressed.connect(do_region_action.bind(a["id"]))
		var note := add_note(vb, a["desc"])
		reg_action_rows[a["id"]] = {"btn": b, "note": note}
	add_title(w.body, "Трансферт региону")
	reg_transfer_label = add_wrap_label(w.body, "")
	reg_transfer_slider = HSlider.new()
	reg_transfer_slider.min_value = 0.0
	reg_transfer_slider.max_value = 5.0
	reg_transfer_slider.step = 0.1
	reg_transfer_slider.scrollable = false
	reg_transfer_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reg_transfer_slider.custom_minimum_size = Vector2(60.0, 20.0)
	reg_transfer_slider.value_changed.connect(func(v: float) -> void: set_transfer(selected_region, v))
	w.body.add_child(reg_transfer_slider)
	add_title(w.body, "Трансферты всем")
	add_note(w.body, "Постоянные ежемесячные выплаты, % ВВП региона. Попадают в расходы бюджета. Больше — лояльнее и спокойнее регион, быстрее развитие.")
	var b0 := make_button("Поровну (0.8%)", w.body)
	b0.pressed.connect(equalize_transfers.bind(0))
	var b1 := make_button("Больше бедным (сумма прежняя)", w.body)
	b1.pressed.connect(equalize_transfers.bind(1))
	var b2 := make_button("Урезать до 0.3%", w.body)
	b2.pressed.connect(equalize_transfers.bind(2))
	transfer_parent = w.body
	fill_transfer_rows()
	build_adm_window()


func on_transfer_slider(v: float, i: int) -> void:
	set_transfer(i, v)


func on_table_row(k: int) -> void:
	select_region(table_order[k])


func set_sort(c: int) -> void:
	c = clampi(c, 0, 6)
	if sort_col == c:
		sort_desc = not sort_desc
	else:
		sort_col = c
		sort_desc = c != 0
	update_region_table()


func is_world_layer() -> bool:
	return map_layer >= 20 and map_layer <= 26


func layer_info(i: int) -> Array:
	var r: Dictionary = regions[i]
	match map_layer:
		27:
			if not r.has("rel"):
				return [0.5, "", 2]
			return [0.5, String(SOC_FAITH[soc_dominant(i)]), 2]
		28:
			if not r.has("relt"):
				return [0.5, "", 0]
			return [1.0 - clampf(float(r["relt"]) / 60.0, 0.0, 1.0), "%.0f" % float(r["relt"]), 0]
		0: return [float(r["loy"]) / 100.0, "%.0f" % float(r["loy"]), 0]
		1: return [1.0 - float(r["unrest"]) / 100.0, "%.0f" % float(r["unrest"]), 0]
		2:
			var pc: float = per_capita(i)
			return [clampf(pc / avg_per_capita() / 2.2, 0.0, 1.0), "%.1f тыс." % pc, 1]
		3: return [float(r["auto"]) / 60.0, "%.0f" % float(r["auto"]), 1]
		6:
			var mx := 0.0
			for w in pop_w:
				mx = maxf(mx, w)
			return [pop_w[i] / mx, "%.1f млн" % float(r["popm"]), 1]
		7: return [clampf(gdp_w[i] / 0.35, 0.0, 1.0), "%.1f%%" % (gdp_w[i] * 100.0), 1]
		8: return [1.0 - float(r["unemp"]) / 20.0, "%.1f%%" % float(r["unemp"]), 0]
		9: return [float(r["infra"]) / 100.0, "%.0f" % float(r["infra"]), 0]
		10: return [float(r["edu"]) / 100.0, "%.0f" % float(r["edu"]), 0]
		11: return [float(r["health"]) / 100.0, "%.0f" % float(r["health"]), 0]
		12: return [float(r["env"]) / 100.0, "%.0f" % float(r["env"]), 0]
		13: return [float(r["transfer"]) / 3.0, "%.1f%%" % float(r["transfer"]), 1]
		14:
			var cnt := 0
			for sid in r["built"]:
				cnt += int(r["built"][sid]["n"])
			var has: bool = not (r["proj"] as Dictionary).is_empty()
			return [clampf(float(cnt) / 8.0, 0.0, 1.0), ("%d" % cnt) + ("+стр." if has else ""), 1]
		15:
			var gr: float = reg_growth(i)
			return [clampf((gr + 2.0) / 8.0, 0.0, 1.0), "%s%%" % sg(gr, 1), 0]
		16: return [1.0 - clampf(float(r["rdebt"]) / 100.0, 0.0, 1.0), "%.0f%%" % float(r["rdebt"]), 0]
		17: return [clampf(0.5 + float(r["migr"]) / 12.0, 0.0, 1.0), sg(float(r["migr"]), 1), 0]
		18: return [clampf(float((r["zones"] as Array).size()) / 3.0, 0.0, 1.0), "%d" % (r["zones"] as Array).size(), 1]
		19:
			var sc19 := sec_cur(i)
			var ir: float = float(sc19["ind"]) + float(sc19["res"])
			return [clampf(ir / 0.45, 0.0, 1.0), "%.0f%%" % (ir * 100.0), 1]
	return [0.5, "", 0]


func layer_leader(i: int) -> int:
	var rs := region_shares(i, false)
	var best := 0
	for p in rs.size():
		if rs[p] > rs[best]:
			best = p
	if map_layer == 5:
		var sec := -1
		for p in rs.size():
			if p != best and (sec < 0 or rs[p] > rs[sec]):
				sec = p
		return sec
	return best


func layer_color(i: int) -> Color:
	if map_layer == 4 or map_layer == 5:
		return (PARTY_COLORS[layer_leader(i)] as Color).darkened(0.1)
	if map_layer == 27 and regions[i].has("rel"):
		return Color(String(SOC_FCOL[soc_dominant(i)])).darkened(0.15)
	var info := layer_info(i)
	var good: float = clampf(float(info[0]), 0.0, 1.0)
	var mode: int = info[2]
	if mode == 1:
		return Color.from_hsv(0.58, 0.15 + 0.6 * good, 0.55 + 0.35 * good)
	if mode == 2:
		return Color(0.95, 0.60, 0.15) if good > 0.0 else Color(0.28, 0.30, 0.36)
	return scale_color(good).darkened(0.12)


func cl_info(c: String) -> Array:
	# [доля 0..1 (хорошо — больше), текст]; доля < 0 — нейтрально
	var w: Dictionary = wsim[c]
	match map_layer:
		20:
			if c == ccode:
				return [-1.0, "вы"]
			var r: float = fed_rel(c)
			return [r / 100.0, "%.0f" % r]
		21: return [clampf((float(w["growth"]) + 1.0) / 5.0, 0.0, 1.0), "%.1f%%" % float(w["growth"])]
		22: return [1.0 - clampf(float(w["infl"]) / 8.0, 0.0, 1.0), "%.1f%%" % float(w["infl"])]
		23: return [1.0 - clampf(float(w["unemp"]) / 14.0, 0.0, 1.0), "%.1f%%" % float(w["unemp"])]
		24: return [1.0 - clampf(float(w["debt"]) / 150.0, 0.0, 1.0), "%.0f%%" % float(w["debt"])]
		25: return [clampf(float(w["stab"]) / 100.0, 0.0, 1.0), "%.0f" % float(w["stab"])]
		26:
			if c == ccode:
				return [-1.0, "вы"]
			var tr: float = float((DIP_C[c] as Dictionary)["trade"]) if DIP_C.has(c) else clampf(w_share(ccode, c) * 1200.0, 0.0, 125.0)
			return [clampf(tr / 125.0, 0.0, 1.0), "%.0f" % tr]
	return [0.5, ""]


func cl_color(c: String) -> Color:
	var info := cl_info(c)
	var g: float = float(info[0])
	if g < 0.0:
		return Color(0.36, 0.40, 0.55)
	if map_layer == 26:
		return Color.from_hsv(0.58, 0.15 + 0.6 * g, 0.55 + 0.35 * g)
	return scale_color(g).darkened(0.12)


func unit_color(ui: int) -> Color:
	var cc: String = String(WORLD_UNITS[ui]["cc"])
	if is_world_layer():
		return cl_color(cc)
	if cc == ccode:
		return layer_color(int(map_unit_local[ui]))
	return (WORLD_CCOL[cc] as Color).darkened(0.38)


func draw_map() -> void:
	if map_ctl == null or map_unit_parts.is_empty() or wsim.is_empty():
		return
	if map_unit_rect.size() != WORLD_UNITS.size() or ate_lists.size() != WORLD_UNITS.size():
		map_prepare()
	var c := map_ctl
	if not map_inited and c.size.x > 50.0:
		map_inited = true
		map_fit_rect(map_country_rect(ccode))
	var v := map_view()
	var s: float = v[0]
	var off: Vector2 = v[1]
	var font := c.get_theme_default_font()
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.060, 0.098, 0.150))
	# контекст
	for ci in map_ctx_parts.size():
		for part in (map_ctx_parts[ci] as Array):
			var px := PackedVector2Array()
			for p in (part as PackedVector2Array):
				px.append(p * s + off)
			c.draw_colored_polygon(px, Color(0.13, 0.16, 0.22) if ci != map_hover_ctx else Color(0.18, 0.21, 0.28))
			var cl := px.duplicate()
			cl.append(px[0])
			c.draw_polyline(cl, Color(0.04, 0.05, 0.08, 0.7), 1.0)
		if s < 1.6:
			var cp: Vector2 = (map_ctx_cent[ci] as Vector2) * s + off
			c.draw_string(font, cp + Vector2(-30.0, 0.0), String(WORLD_CTX[ci]["name"]), HORIZONTAL_ALIGNMENT_CENTER, 60.0, 10, Color(0.45, 0.50, 0.58))
	var view_rect := Rect2(Vector2.ZERO, c.size).grow(40.0)
	var vis: Array = []
	for ui in map_unit_rect.size():
		var rr: Rect2 = map_unit_rect[ui]
		if rr.size == Vector2.ZERO:
			continue
		if view_rect.intersects(Rect2(rr.position * s + off, rr.size * s)):
			vis.append(ui)
	# v36: всё, что ниже, рисуется в координатах карты (масштаб задаёт преобразование); толщина линий — в пикселях / s
	var ci := c.get_canvas_item()
	var xf := Transform2D(0.0, Vector2(s, s), 0.0, off)
	if map_all_mesh != null:
		c.draw_mesh(map_all_mesh, null, Transform2D(0.0, Vector2(s, s), 0.0, off + Vector2(2.0, 3.0)), Color(0, 0, 0, 0.30))
	for ui in vis:
		var m: ArrayMesh = map_unit_mesh[ui]
		if m == null:
			continue
		c.draw_mesh(m, null, xf, unit_color(ui))
		if ui == map_hover_unit and not ate_mode:
			c.draw_mesh(m, null, xf, Color(1, 1, 1, 0.13))
	c.draw_set_transform_matrix(xf)
	# выделенные АТЕ и АТЕ под курсором
	if not ate_sel.is_empty():
		var sp := PackedVector2Array()
		for a in ate_sel:
			sp.append_array(map_ate_tris[int(a)])
		RenderingServer.canvas_item_add_triangle_array(ci, PackedInt32Array(), sp, PackedColorArray([Color(1.0, 0.92, 0.45, 0.45)]))
	if ate_mode and map_hover_ate >= 0:
		RenderingServer.canvas_item_add_triangle_array(ci, PackedInt32Array(), map_ate_tris[map_hover_ate], PackedColorArray([Color(1, 1, 1, 0.22)]))
	# тонкие границы АТЕ (заметнее при приближении; в режиме АТЕ — всегда)
	var cell_px: float = 8.5 * s
	var al: float = clampf((cell_px - 4.0) / 14.0, 0.0, 0.42)
	if ate_mode:
		al = maxf(al, 0.30)
	if al > 0.01 and not map_ln_ate.is_empty():
		c.draw_multiline(map_ln_ate, Color(0.02, 0.03, 0.06, al), -1.0)
	if not map_ln_reg.is_empty():
		c.draw_multiline(map_ln_reg, Color(0.04, 0.05, 0.08, 0.9), 1.1 / s)
	if not map_ln_cty.is_empty():
		c.draw_multiline(map_ln_cty, Color(0.02, 0.02, 0.04, 1.0), 1.9 / s)
	# выбранный объект: своя страна — регион; чужая — вся страна, а после второго щелчка только регион
	var whole_cc := ""
	if map_mode == "foreign" and dip_sel != "" and not fmap_win_open:
		whole_cc = dip_sel
	if whole_cc != "":
		for ui in vis:
			if String(WORLD_UNITS[ui]["cc"]) == whole_cc and map_unit_mesh[ui] != null:
				c.draw_mesh(map_unit_mesh[ui], null, Transform2D.IDENTITY, Color(1, 1, 1, 0.12))
		var cs := map_border_segs("c" + whole_cc)
		if not cs.is_empty():
			c.draw_multiline(cs, Color(1, 1, 1, 0.25), 7.0 / s)
			c.draw_multiline(cs, Color(1, 1, 1, 0.97), 2.6 / s)
	var sel_ui := -1
	if map_mode == "own":
		for ui in map_unit_local:
			if int(map_unit_local[ui]) == selected_region:
				sel_ui = int(ui)
	elif map_mode == "foreign" and fmap_win_open:
		sel_ui = map_sel_unit
	if sel_ui >= 0 and sel_ui < map_unit_mesh.size():
		var us := map_border_segs("u%d" % sel_ui)
		if not us.is_empty():
			c.draw_multiline(us, Color(1, 1, 1, 0.22), 7.0 / s)
			c.draw_multiline(us, Color(1, 1, 1, 0.95), 2.4 / s)
	if not ate_sel.is_empty():
		var ss := map_border_segs("s")
		if not ss.is_empty():
			c.draw_multiline(ss, Color(1.0, 0.85, 0.2, 1.0), 2.0 / s)
	draw_war_overlay(c, ci, s)
	c.draw_set_transform_matrix(Transform2D.IDENTITY)
	var px_parts: Dictionary = {}
	for ui in vis:
		px_parts[ui] = true
	# булавки малых регионов своей страны (иначе их не поймать курсором) и подпись выбранного
	for ui in map_unit_local:
		if not unit_is_tiny(ui, s):
			continue
		var pp := Vector2(float(WORLD_UNITS[ui]["c"][0]), float(WORLD_UNITS[ui]["c"][1])) * s + off
		var is_sel: bool = map_mode == "own" and int(map_unit_local[ui]) == selected_region
		c.draw_circle(pp, 9.0, Color(0.05, 0.05, 0.08, 0.85))
		c.draw_arc(pp, 8.0, 0.0, TAU, 20, Color(1, 1, 1, 0.95) if (is_sel or ui == map_hover_unit) else Color(1, 1, 1, 0.55), 2.0 if is_sel else 1.3)
		c.draw_circle(pp, 3.0, unit_color(ui))
		var pn := String(REGIONS[int(map_unit_local[ui])]["short"])
		c.draw_string_outline(font, pp + Vector2(11.0, 4.0), pn, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 3, Color(0, 0, 0, 0.9))
		c.draw_string(font, pp + Vector2(11.0, 4.0), pn, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.95))
	var cap_txt := "Щёлкните по региону, чтобы открыть его сведения · колёсико — масштаб, перетаскивание — сдвиг"
	if map_mode == "own" and selected_region >= 0 and selected_region < REGIONS.size():
		cap_txt = "Выбран регион: %s   (щёлкните по другому; малые регионы отмечены кружками)" % String(REGIONS[selected_region]["name"])
	elif map_mode == "foreign" and dip_sel != "" and WORLD.has(dip_sel):
		cap_txt = "Выбрана страна: %s" % String(WORLD[dip_sel]["name"])
	var cw: float = font.get_string_size(cap_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	c.draw_rect(Rect2(Vector2(6.0, c.size.y - 24.0), Vector2(minf(cw + 14.0, c.size.x - 12.0), 20.0)), Color(0.03, 0.05, 0.09, 0.82))
	c.draw_string(font, Vector2(13.0, c.size.y - 9.0), cap_txt, HORIZONTAL_ALIGNMENT_LEFT, c.size.x - 24.0, 12, Color(1, 1, 1, 0.92))
	# дипломатические линии
	if map_layer == 20 or map_layer == 26:
		var dep: Vector2 = (WORLD_CAPS[ccode] as Vector2) * s + off
		for code in DIP_ORDER:
			var cp2: Vector2 = (WORLD_CAPS[code] as Vector2) * s + off
			var r2: float = float(dip[code]["rel"])
			var lc := scale_color(clampf(r2 / 100.0, 0.0, 1.0))
			var wdt: float = 1.5 + float((DIP_C[code] as Dictionary)["trade"]) / 40.0
			c.draw_line(dep, cp2, Color(0, 0, 0, 0.35), wdt + 1.5)
			c.draw_line(dep, cp2, Color(lc.r, lc.g, lc.b, 0.75), wdt)
	# подписи
	var fs2: int = clampi(int(s * 3.0), 9, 14)
	for ui in px_parts:
		var u: Dictionary = WORLD_UNITS[ui]
		var cc3: String = String(u["cc"])
		var rr2: Rect2 = map_unit_rect[ui]
		var wpx: float = rr2.size.x * s
		if is_world_layer() or (cc3 != ccode and s < 2.4):
			continue
		var ctr: Vector2 = Vector2(float(u["c"][0]), float(u["c"][1])) * s + off
		var nm := ""
		var val := ""
		if cc3 == ccode:
			var li: int = int(map_unit_local[ui])
			nm = String(REGIONS[li]["short"])
			if map_layer == 4 or map_layer == 5:
				var rs := region_shares(li, false)
				val = "%.0f%%" % (rs[layer_leader(li)] * 100.0)
			else:
				val = String(layer_info(li)[1])
			if (regions[li]["proj"] as Dictionary).size() > 0 and map_layer != 14:
				c.draw_circle(ctr + Vector2(0.0, -float(fs2) * 1.6), 4.5, Color(0.05, 0.05, 0.08))
				c.draw_circle(ctr + Vector2(0.0, -float(fs2) * 1.6), 3.2, C_WARN)
		else:
			for r in WORLD[cc3]["regions"]:
				if String(r["id"]) == String(u["id"]):
					nm = String(r["short"])
		if wpx < 18.0 and s < 5.0:
			continue
		if wpx < 46.0:
			nm = nm.substr(0, 5)
		var y2 := -float(fs2) * 0.5
		for ln in [nm, val]:
			if ln == "" or (ln == val and wpx < 34.0):
				continue
			var tc := Color(1, 0.95, 0.70) if ln == val else Color(1, 1, 1)
			var pos := ctr + Vector2(-35.0, y2)
			c.draw_string_outline(font, pos, ln, HORIZONTAL_ALIGNMENT_CENTER, 70.0, fs2, 4, Color(0, 0, 0, 0.9))
			c.draw_string(font, pos, ln, HORIZONTAL_ALIGNMENT_CENTER, 70.0, fs2, tc)
			y2 += float(fs2) + 1.0
	# названия и показатели стран (без наложений: сначала крупные экономики)
	if is_world_layer() or s < 2.4:
		var order: Array = wsim.keys()
		order.sort_custom(func(a, b) -> bool: return float(WORLD[a]["gdp"]) * (10.0 if a == ccode else 1.0) > float(WORLD[b]["gdp"]) * (10.0 if b == ccode else 1.0))
		var placed: Array = []
		for code in order:
			var cp3: Vector2 = (WORLD_CAPS[code] as Vector2) * s + off
			var is_me: bool = code == ccode
			c.draw_circle(cp3, 4.5, Color(0.05, 0.05, 0.08))
			c.draw_circle(cp3, 3.2, Color(1, 0.92, 0.55) if not is_me else Color(0.5, 1.0, 0.6))
			var cn: String = String(WORLD[code]["name"])
			var cv := ""
			if is_world_layer():
				cv = String(cl_info(code)[1])
			var lines: Array = [cn]
			if cv != "":
				lines.append(cv)
			var bw := 8.0 + 6.4 * float(maxi(cn.length(), cv.length()))
			var bh := 13.0 * float(lines.size())
			var lr := Rect2(cp3 + Vector2(-bw * 0.5, -10.0 - bh), Vector2(bw, bh))
			var clash := false
			for pr in placed:
				if (pr as Rect2).intersects(lr):
					clash = true
					break
			if clash and not is_me:
				continue
			placed.append(lr)
			var lp: Vector2 = cp3 + Vector2(0.0, -10.0 - bh + 11.0)
			for ln in lines:
				var tc2 := Color(1, 0.95, 0.70) if ln == cv else Color(1, 1, 1)
				var pos2 := lp + Vector2(-50.0, 0.0)
				c.draw_string_outline(font, pos2, ln, HORIZONTAL_ALIGNMENT_CENTER, 100.0, 12, 4, Color(0, 0, 0, 0.9))
				c.draw_string(font, pos2, ln, HORIZONTAL_ALIGNMENT_CENTER, 100.0, 12, tc2)
				lp.y += 13.0
	var ramp := layer_ramp()
	var kind: String = ramp[0]
	if kind != "none":
		var lx := 10.0
		var ly := 26.0
		var lw := 130.0
		c.draw_rect(Rect2(lx - 6.0, ly - 18.0, lw + 12.0, 38.0), Color(0, 0, 0, 0.45))
		for k in 26:
			var t: float = float(k) / 25.0
			var col2 := Color.WHITE
			if kind == "rg":
				col2 = scale_color(t).darkened(0.1)
			elif kind == "gr":
				col2 = scale_color(1.0 - t).darkened(0.1)
			else:
				col2 = Color.from_hsv(0.58, 0.15 + 0.6 * t, 0.55 + 0.35 * t)
			c.draw_rect(Rect2(lx + lw * float(k) / 26.0, ly, lw / 26.0 + 0.6, 8.0), col2)
		c.draw_string(font, Vector2(lx, ly - 4.0), String(ramp[1]), HORIZONTAL_ALIGNMENT_LEFT, lw, 11, C_DIM)
		c.draw_string(font, Vector2(lx, ly - 4.0), String(ramp[2]), HORIZONTAL_ALIGNMENT_RIGHT, lw, 11, C_DIM)
	draw_war_tokens(c, s, off, font)


func region_tip(i: int) -> String:
	if i < 0:
		return ""
	var r: Dictionary = regions[i]
	var gv: Dictionary = r["gov"]
	return "%s — %s\nНаселение %.1f млн, ВВП на душу %.1f тыс. € в год\nЛояльность %.0f, недовольство %.0f, автономия %.0f\nРост ВРП %s%%, долг региона %.0f%% ВРП, миграция %s на 1000\nМинистр-президент: %s (%s)\nЩёлкните, чтобы выбрать." % [
		REGIONS[i]["name"], tier_name(i), r["popm"], per_capita(i), r["loy"], r["unrest"], r["auto"], sg(reg_growth(i), 1), r["rdebt"], sg(r["migr"], 1), gv["name"], GOV_KINDS[int(gv["kind"])]]


func region_sort_value(i: int, col: int) -> float:
	var r: Dictionary = regions[i]
	match col:
		1: return pop_w[i]
		2: return gdp_w[i]
		3: return float(r["loy"])
		4: return float(r["unrest"])
		5: return per_capita(i)
		6: return float(r["unemp"])
		7: return reg_growth(i)
		8: return float(r["rdebt"])
	return float(i)


func update_regions_ui() -> void:
	if map_ctl == null:
		return
	update_fregion()
	if not LOC_RULES.is_empty():
		for wid in ["region", "regact", "regecon", "regtable", "dinfo", "dact", "dtable"]:
			loc_tree(wins[wid])
	map_legend.text = MAP_LEGENDS[map_layer] + " Колёсико — масштаб, перетаскивание — перемещение, щелчок по стране или региону — сведения."
	map_ctl.queue_redraw()
	if map_reg_pick != null and selected_region >= 0 and selected_region < map_reg_pick.item_count and map_reg_pick.selected != selected_region:
		map_reg_pick.select(selected_region)
	update_region_info()
	update_regecon()
	update_region_table()
	update_transfer_ui()
	update_adm_ui()


func update_region_table() -> void:
	var idx: Array = []
	for i in regions.size():
		idx.append(i)
	idx.sort_custom(func(a, b): return region_sort_value(a, sort_col) < region_sort_value(b, sort_col))
	if sort_desc:
		idx.reverse()
	table_order.clear()
	for i in idx:
		table_order.append(i)
	var avg_pc := avg_per_capita()
	for k in regions.size():
		var i: int = table_order[k]
		var r: Dictionary = regions[i]
		var row: Dictionary = reg_table_rows[k]
		var has_proj: bool = not (r["proj"] as Dictionary).is_empty()
		(row["name"] as Button).text = ("▶ " if i == selected_region else "") + ("● " if has_proj else "") + String(REGIONS[i]["name"])
		var cells: Array = row["cells"]
		(cells[0] as Label).text = "%.1f%%" % (pop_w[i] * 100.0)
		(cells[1] as Label).text = "%.1f%%" % (gdp_w[i] * 100.0)
		(cells[2] as Label).text = "%.0f" % float(r["loy"])
		(cells[3] as Label).text = "%.0f" % float(r["unrest"])
		(cells[4] as Label).text = "%.1f" % per_capita(i)
		(cells[5] as Label).text = "%.1f" % float(r["unemp"])
		(cells[6] as Label).text = sg(reg_growth(i), 1)
		(cells[7] as Label).text = "%.0f" % float(r["rdebt"])
		(cells[6] as Label).modulate = Color.html("#" + stat_color(clampf(50.0 + (reg_growth(i) - growth) * 12.0, 0.0, 100.0), false))
		(cells[7] as Label).modulate = Color.html("#" + stat_color(clampf(float(r["rdebt"]), 0.0, 100.0), true))
		(cells[2] as Label).modulate = Color.html("#" + stat_color(float(r["loy"]), false))
		(cells[3] as Label).modulate = Color.html("#" + stat_color(float(r["unrest"]), true))
		(cells[4] as Label).modulate = Color.html("#" + stat_color(clampf(per_capita(i) / avg_pc * 50.0, 0.0, 100.0), false))
	var angry := 0
	var disloyal := 0
	var projects := 0
	for r in regions:
		if float(r["unrest"]) >= 60.0:
			angry += 1
		if float(r["loy"]) < 40.0:
			disloyal += 1
		if not (r["proj"] as Dictionary).is_empty():
			projects += 1
	reg_summary.text = "Регионов: %d. Неспокойных (недовольство ≥ 60): %d. Нелояльных (< 40): %d. Строек (●): %d. ВВП/душа — тыс. в год, в среднем по стране %.1f. Сортировка: %s%s." % [
		regions.size(), angry, disloyal, projects, avg_pc, ["название", "население", "ВВП", "лояльность", "недовольство", "ВВП на душу", "безработица", "рост ВРП", "долг региона"][sort_col], " (по убыванию)" if sort_desc else ""]


func update_transfer_ui() -> void:
	if reg_transfer_slider == null:
		return
	var r: Dictionary = regions[selected_region]
	reg_transfer_slider.set_value_no_signal(float(r["transfer"]))
	reg_transfer_label.text = "«%s»: %.1f%% ВВП региона = %.1f млрд в год" % [REGIONS[selected_region]["name"], r["transfer"], gdp * gdp_w[selected_region] * float(r["transfer"]) / 100.0]
	for i in regions.size():
		(transfer_sliders[i] as HSlider).set_value_no_signal(float(regions[i]["transfer"]))
		(transfer_labels[i] as Label).text = "%s: %.1f%% (%.1f млрд/год)" % [REGIONS[i]["name"], regions[i]["transfer"], gdp * gdp_w[i] * float(regions[i]["transfer"]) / 100.0]


func update_region_info() -> void:
	var i := selected_region
	var r: Dictionary = regions[i]
	var d: Dictionary = REGIONS[i]
	var sec: Dictionary = d["sec"]
	var avg_pc := avg_per_capita()
	var ratio: float = per_capita(i) / avg_pc
	var tcol: Color = scale_color(clampf(ratio / 2.0, 0.0, 1.0))
	var rowf := func(k: String, v: String) -> String:
		return "[cell][color=%s]%s[/color]   [/cell][cell]%s[/cell]" % [COL_DIM, k, v]
	var t := "[b][font_size=19]%s[/font_size][/b]   [color=#%s][b]%s[/b][/color]\n[color=%s]%s[/color]\n" % [d["name"], tcol.to_html(false), tier_name(i), COL_DIM, d["desc"]]
	var tax_sum := 0.0
	var bg2 := compute_budget()
	for k in ["Подоходный налог", "Налог на прибыль", "НДС и акцизы"]:
		tax_sum += float(bg2["rev"][k])
	var tr_amt: float = gdp * gdp_w[i] * float(r["transfer"]) / 100.0
	var net: float = tax_sum * gdp_w[i] - tr_amt
	t += "[table=2]"
	t += rowf.call("Население", "[b]%.1f млн[/b] (%.1f%% страны)" % [r["popm"], pop_w[i] * 100.0])
	t += rowf.call("ВВП/душа", "[b]%.1f тыс.[/b] (%.0f%% ср.)" % [per_capita(i), ratio * 100.0])
	t += rowf.call("Вклад в ВВП", "[b]%s млрд[/b] (%.1f%%)" % [fmt_n(gdp * gdp_w[i], 1), gdp_w[i] * 100.0])
	t += rowf.call("Безработица", "[b]%.1f%%[/b]" % r["unemp"])
	t += rowf.call("Налоги", "[b]%s млрд[/b] в год" % fmt_n(tax_sum * gdp_w[i], 1))
	t += rowf.call("Трансферт", "[b]%s млрд[/b] в год" % fmt_n(tr_amt, 1))
	t += rowf.call("Итог", "%s млрд в год" % col_signed(net, 1))
	t += "[/table]\n"
	var sp: PackedStringArray = []
	for k in ["ind", "agr", "srv", "res"]:
		if float(sec[k]) >= 0.05:
			sp.append("%s %.0f%%" % [SECTOR_NAMES[k], float(sec[k]) * 100.0])
	t += "[color=%s]Отрасли:[/color] %s\n" % [COL_DIM, " · ".join(sp)]
	var nb: PackedStringArray = []
	for j in (neighbors[i] as Array):
		nb.append("%s [color=%s](%.0f)[/color]" % [REGIONS[j]["name"], stat_color(float(regions[j]["unrest"]), true).insert(0, "#"), regions[j]["unrest"]])
	t += "[color=%s]Соседи (недовольство):[/color] %s\n" % [COL_DIM, ", ".join(nb)]
	var mixa: Array = []
	var mix: Dictionary = reg_mix[i]
	for g in GROUPS:
		mixa.append([float(mix[g]), g])
	mixa.sort_custom(func(a, c): return a[0] > c[0])
	t += "[color=%s]Крупнейшие группы:[/color] %s %.0f%% · %s %.0f%% · %s %.0f%%\n" % [COL_DIM, mixa[0][1], mixa[0][0] * 100.0, mixa[1][1], mixa[1][0] * 100.0, mixa[2][1], mixa[2][0] * 100.0]
	var rs := region_shares(i, false)
	var order := sorted_parties(rs)
	var polls: PackedStringArray = []
	for k in 3:
		var pp: int = order[k]
		polls.append("[color=#%s]■[/color] %s %.0f%%" % [(PARTY_COLORS[pp] as Color).lightened(0.2).to_html(false), PARTY_NAMES[pp], rs[pp] * 100.0])
	t += "[color=%s]Лидеры опроса:[/color] %s" % [COL_DIM, "   ".join(polls)]
	t += fed_region_line(i)
	if float(r["unrest"]) >= 70.0:
		t += "\n[color=%s]⚠ Регион на грани восстания![/color]" % COL_BAD
	reg_info_rt.text = t
	set_bar("rb_loy", float(r["loy"]))
	set_bar("rb_unrest", float(r["unrest"]))
	set_bar("rb_infra", float(r["infra"]))
	set_bar("rb_edu", float(r["edu"]))
	set_bar("rb_health", float(r["health"]))
	set_bar("rb_env", float(r["env"]))
	var gv: Dictionary = r["gov"]
	var gk: int = int(gv["kind"])
	gov_info_rt.text = "%s — %s, умение %.0f. Эффект: %s." % [gv["name"], GOV_KINDS[gk], gv["skill"], GOV_DESC[gk]]
	var cd: Dictionary = reg_cd[i]
	var gleft: int = int(cd.get("gov", 0))
	var gnames := ["", "Назначить лоялиста", "Назначить технократа", "Назначить местного авторитета"]
	for k in 3:
		var kind: int = k + 1
		var bb: Button = gov_buttons[k]
		bb.text = "%s (капитал 8)%s" % [gnames[kind], (" — ещё %d мес." % gleft) if gleft > 0 else ""]
		bb.disabled = game_over or gleft > 0 or capital < 8.0
		bb.tooltip_text = GOV_DESC[kind].capitalize()
	for k in PROJECTS.size():
		var pdk: Dictionary = PROJECTS[k]
		proj_option.set_item_text(k, "%s: %.1f млрд, %d мес." % [pdk["name"], gdp * project_cost_pct(i, pdk) / 100.0, pdk["months"]])
	var pr: Dictionary = r["proj"]
	if pr.is_empty():
		var pd: Dictionary = PROJECTS[proj_option.selected]
		proj_label.text = "Сейчас в регионе ничего не строится. Деньги списываются в расходы бюджета равными частями каждый месяц. Крупным регионам проекты стоят дороже, в уже развитых регионах отдача меньше.\n%s По завершении: %s." % [
			roi_text(i, pd["reg"], project_cost_pct(i, pd)), describe_reg(effective_reg(i, pd["reg"]))]
		proj_label.text += "\n" + struct_effect_text(pd) + "\n" + region_struct_text(i)
		proj_option.disabled = false
		proj_start.disabled = game_over or capital < 2.0
		proj_cancel.disabled = true
	else:
		var pd2 := find_by_id(PROJECTS, pr["id"])
		proj_label.text = "Идёт проект «%s»: осталось %d из %d мес. (%.1f млрд всего). По завершении: %s." % [pd2["name"], pr["left"], pr["months"], gdp * float(pr["cost"]) / 100.0, describe_reg(effective_reg(i, pd2["reg"]))]
		proj_label.text += "\n" + region_struct_text(i)
		proj_option.disabled = true
		proj_start.disabled = true
		proj_cancel.disabled = game_over
	for a in REGION_ACTIONS:
		var row: Dictionary = reg_action_rows[a["id"]]
		var bt: Button = row["btn"]
		var left: int = int(cd.get(a["id"], 0))
		var cost_parts: PackedStringArray = []
		if float(a["cap"]) > 0.0:
			cost_parts.append("капитал %.0f" % a["cap"])
		if float(a["money"]) > 0.0:
			cost_parts.append("%.1f млрд в долг" % (gdp * float(a["money"]) / 100.0))
		var txt: String = loc(String(a["name"]))
		if cost_parts.size() > 0:
			txt += " — " + ", ".join(cost_parts)
		if left > 0:
			txt += " (ещё %d мес.)" % left
		bt.text = txt
		bt.disabled = left > 0 or game_over or capital < float(a["cap"])
		var tip: String = "Эффект: " + describe_reg(effective_reg(i, a["reg"]))
		if a["reg"].has("dev"):
			tip += ". " + roi_text(i, a["reg"], float(a["money"]))
		bt.tooltip_text = tip


func on_tool_selected(_i: int) -> void:
	update_regecon()


func build_regecon_window() -> void:
	var w: FloatWindow = new_window("regecon", "Экономика региона", 2, Rect2(0.45, 0.0, 0.255, 0.55))
	re_rt = make_rt(w.body)
	add_title(w.body, "Зоны и программы")
	re_tool_label = add_wrap_label(w.body, "")
	re_tool_opt = OptionButton.new()
	re_tool_opt.focus_mode = Control.FOCUS_NONE
	re_tool_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	re_tool_opt.fit_to_longest_item = false
	re_tool_opt.clip_text = true
	re_tool_opt.custom_minimum_size = Vector2(60.0, 0.0)
	for t in REG_TOOLS:
		re_tool_opt.add_item(String(t["name"]))
	re_tool_opt.item_selected.connect(on_tool_selected)
	w.body.add_child(re_tool_opt)
	re_tool_btn = make_button("Запустить", w.body)
	re_tool_btn.pressed.connect(reg_tool_buy)
	re_tool_note = add_note(w.body, "Эффект нарастает постепенно; по окончании срока часть остаётся. До 3 программ в регионе. Содержание идёт в расходы бюджета.")


func update_regecon() -> void:
	if re_rt == null:
		return
	var i := selected_region
	var r: Dictionary = regions[i]
	var d: Dictionary = REGIONS[i]
	var sc := sec_cur(i)
	var base: Dictionary = REGIONS[i]["sec"]
	var tb := 0.0
	for k in RSEC:
		tb += float(base[k])
	var grp: float = gdp * gdp_w[i]
	var g: float = reg_growth(i)
	var gcol: String = COL_GOOD if g >= growth else COL_BAD
	var t := "[b][font_size=17]%s[/font_size][/b]\n" % d["name"]
	t += "[color=%s]ВРП[/color] [b]%s млрд[/b], рост за год [color=%s][b]%s%%[/b][/color] (страна %s%%)\n" % [COL_DIM, fmt_n(grp, 1), gcol, sg(g, 1), sg(growth, 1)]
	t += "[color=%s]Безработица[/color] [b]%.1f%%[/b] (страна %.1f%%)\n" % [COL_DIM, float(r["unemp"]), unemployment]
	var mg: float = float(r["migr"])
	t += "[color=%s]Миграция[/color] [color=%s][b]%s[/b][/color] на 1000 жителей в год\n" % [COL_DIM, COL_GOOD if mg >= 0.0 else COL_BAD, sg(mg, 1)]
	var rdv: float = float(r["rdebt"])
	var dcol: String = COL_GOOD if rdv < 45.0 else (COL_WARN if rdv < 70.0 else COL_BAD)
	t += "[color=%s]Долг региона[/color] [color=%s][b]%.0f%% ВРП[/b][/color]\n" % [COL_DIM, dcol, rdv]
	t += "[color=%s]Содержание зон[/color] [b]%s млрд[/b] в год\n" % [COL_DIM, fmt_n(grp * float(r["upk"]) / 100.0, 2)]
	var sp: PackedStringArray = []
	for k in RSEC:
		var now: float = float(sc[k]) * 100.0
		var b0: float = float(base[k]) / tb * 100.0
		if now < 1.0 and b0 < 1.0:
			continue
		var df := now - b0
		var arrow := ""
		if absf(df) >= 0.5:
			arrow = " [color=%s]%s%.1f[/color]" % [COL_GOOD if df > 0.0 else COL_BAD, "▲" if df > 0.0 else "▼", absf(df)]
		sp.append("%s %.0f%%%s" % [SECTOR_NAMES[k], now, arrow])
	t += "[color=%s]Структура экономики:[/color] %s\n" % [COL_DIM, " · ".join(sp)]
	if float(base["res"]) >= 0.03:
		t += "[color=%s]Цены на сырьё:[/color] %.0f%% от нормы\n" % [COL_DIM, res_price * 100.0]
	if bool(r["rcrisis"]):
		t += "[color=%s]⚠ Долговой кризис: расходы региона урезаны.[/color]\n" % COL_BAD
	var zl: Array = r["zones"]
	if zl.is_empty():
		t += "[color=%s]Зоны и программы:[/color] нет\n" % COL_DIM
	else:
		t += "[color=%s]Зоны и программы:[/color]\n" % COL_DIM
		for z in zl:
			t += "  • %s — ещё %d мес.\n" % [z["name"], int(z["left"])]
	re_rt.text = loc(t)
	# инструменты
	var cd: Dictionary = reg_cd[i]
	for k in REG_TOOLS.size():
		var tl: Dictionary = REG_TOOLS[k]
		re_tool_opt.set_item_text(k, "%s: %.1f млрд" % [tl["name"], gdp * tool_cost_pct(i, tl) / 100.0])
	var tool: Dictionary = REG_TOOLS[re_tool_opt.selected]
	var req := tool_req(tool, i)
	var key := "tool_" + String(tool["id"])
	var left: int = int(cd.get(key, 0))
	var active := false
	for z in zl:
		if String(z["id"]) == String(tool["id"]):
			active = true
	var txt: String = String(tool["desc"]) + "\nЭффект: " + tool_effect_text(tool, i) + "."
	if int(tool["months"]) > 0:
		txt += " Срок %d мес., содержание %.2f%% ВРП в год." % [int(tool["months"]), float(tool["up"])]
	txt += " Цена: политкапитал %.0f." % float(tool["cap"])
	if req != "":
		txt += "\nНедоступно: " + req + "."
	elif active:
		txt += "\nУже действует в регионе."
	elif left > 0:
		txt += "\nПовторно через %d мес." % left
	elif zl.size() >= 3 and int(tool["months"]) > 0:
		txt += "\nУже три программы — больше нельзя."
	re_tool_label.text = loc(txt)
	re_tool_btn.disabled = game_over or req != "" or active or left > 0 or capital < float(tool["cap"]) or (zl.size() >= 3 and int(tool["months"]) > 0)


func regecon_inject() -> void:
	var tg := {"id": "regional_econ", "cat": 1, "name": "Региональная экономическая политика", "fund": false,
		"desc": "Как государство относится к экономике регионов: выравнивает ли доходы, оставляет ли налоги на местах, делает ли ставку на кластеры или на крупные города, разрешает ли регионам занимать. Влияет на развитие, долги и недовольство в регионах.",
		"v": [{"n": "Действующий порядок", "d": "Центр собирает налоги и распределяет трансферты по нынешним правилам; регионы занимают в обычных пределах."}]}
	var vs: Array = tg["v"]
	vs.append(RV("Фонд выравнивания регионов", "Центр направляет часть налогов в фонд для бедных регионов: они растут быстрее и спокойнее, богатые недовольны, бюджет тратит больше.", 34.0,
		{"Бюджетники": 2.0, "Село": 2.0, "Рабочие": 1.0, "Бизнес": -2.0}, {"fed_share": -1.2, "extra_spend": 0.18, "reg_dev_bonus": 0.8, "reg_unrest_shift": -0.8},
		{"soc": 6, "left": 7, "green": 2, "cons": -3, "lib": -6, "region": 3, "popl": 2, "euro": 1, "own": -1}))
	vs.append(RV("Фискальный федерализм", "Регионы оставляют себе больше налогов и сами решают, как их тратить: богатые растут быстрее, бедные отстают и сильнее зависят от займов, автономия растёт.", 38.0,
		{"Бизнес": 2.0, "Молодёжь": 1.0, "Село": -2.0, "Бюджетники": -1.0}, {"fed_share": 1.4, "growth_bonus": 0.05, "auto_shift": 4.0, "reg_unrest_shift": 0.6, "eff_bonus": 0.002},
		{"lib": 6, "cons": 3, "region": 8, "soc": -4, "left": -5, "popr": 1, "popl": -1},
		{"rg": {"autonomy": 4.0, "loyalty": 1.0}}))
	vs.append(RV("Региональные точки роста", "Государство делает ставку на кластеры и особые зоны: каждая вложенная в зону сумма работает сильнее, но равенство между регионами падает.", 36.0,
		{"Бизнес": 2.0, "Молодёжь": 1.0, "Бюджетники": -1.0}, {"growth_bonus": 0.04, "extra_spend": 0.10, "equal_shift": -1.0},
		{"lib": 3, "cons": 2, "soc": -1, "green": -1, "region": 2, "own": 1, "left": -2},
		{"x": {"zone_eff": 1.5}}))
	vs.append(RV("Ставка на метрополии", "Инвестиции идут в крупные города, малые регионы теряют людей и услуги. Рост быстрее, но периферия озлобляется, автономия падает.", 36.0,
		{"Бизнес": 3.0, "Молодёжь": 2.0, "Село": -4.0, "Бюджетники": -1.0}, {"growth_bonus": 0.09, "fed_share": 0.8, "reg_unrest_shift": 1.2, "auto_shift": -3.0, "equal_shift": -1.5},
		{"lib": 4, "euro": 3, "cons": 1, "region": -7, "popl": -3, "popr": -2, "left": -2, "soc": -2}))
	vs.append(RV("Строгие долговые лимиты для регионов", "Регионам запрещено занимать сверх нормы: долги падают, кризисы реже, но стройки и услуги на местах урезаются.", 30.0,
		{"Бизнес": 2.0, "Пенсионеры": 1.0, "Бюджетники": -2.0, "Село": -1.0}, {"rdebt_shift": -1.5, "eff_bonus": 0.003, "reg_dev_bonus": -0.4},
		{"cons": 5, "lib": 5, "soc": -2, "left": -3, "region": -5, "own": 1, "popr": 2}))
	vs.append(RV("Региональные банки развития", "Государственные банки кредитуют регионы и местный бизнес на льготных условиях: быстрее развитие, но выше долги и риск плохих кредитов.", 32.0,
		{"Бюджетники": 1.0, "Село": 2.0, "Бизнес": 1.0, "Пенсионеры": -1.0}, {"rdebt_shift": 1.2, "reg_dev_bonus": 1.2, "growth_bonus": 0.03},
		{"soc": 3, "region": 5, "left": 2, "lib": -3, "cons": -2, "popl": 3, "popr": 2}))
	LAW_TOPICS.append(tg)


# ============================================================
#  v36: АТЕ на карте — выделение, подсказка
# ============================================================


func ate_tip(a: int) -> String:
	var cc := ate_cc(a)
	var i := ate_region(a)
	var t := "АТЕ «%s» — %.0f км², ≈%s жителей\n" % [ate_name(a), ate_km[a], fmt_people(ate_pop(a))]
	if i >= 0:
		t += "Регион: %s\n" % String(REGIONS[i]["name"])
	else:
		var u: Dictionary = WORLD_UNITS[ate_unit[a]]
		t += "%s — %s\n" % [String(WORLD[cc]["name"]) if WORLD.has(cc) else cc, String(fed_wreg(cc, String(u["id"])).get("name", ""))]
	if ate_cap.has(cc) and int(ate_cap[cc]) == a:
		t += "Здесь столица страны.\n"
	return t + ("Щелчок — выделить/снять; с Shift — выделить весь регион." if not (a in ate_sel) else "Выделена. Щелчок — снять выделение.")


func fmt_people(m: float) -> String:
	if m >= 1.0:
		return "%.2f млн" % m
	return "%.0f тыс." % (m * 1000.0)


func ate_click(a: int, whole: bool) -> void:
	if a < 0:
		return
	# выделение только одной страны: щелчок по другой стране начинает новое выделение
	if not ate_sel.is_empty() and ate_cc(int(ate_sel[0])) != ate_cc(a):
		ate_sel.clear()
	if whole:
		var lst: PackedInt32Array = ate_lists[ate_unit[a]]
		var all_in := true
		for b in lst:
			if not (b in ate_sel):
				all_in = false
		for b in lst:
			if all_in:
				ate_sel.erase(b)
			elif not (b in ate_sel):
				ate_sel.append(b)
	elif a in ate_sel:
		ate_sel.erase(a)
	else:
		ate_sel.append(a)
	map_seg_cache.erase("s")
	if ate_cc(a) == ccode:
		var i := ate_region(a)
		if i >= 0 and ate_sel.size() <= 1:
			selected_region = i
	update_adm_ui()
	map_ctl.queue_redraw()


# ============================================================
#  v36: окно «Административная реформа (АТЕ)»
# ============================================================


func build_adm_window() -> void:
	var w: FloatWindow = new_window("adm", "Административная реформа (АТЕ)", 2, Rect2(0.25, 0.0, 0.21, 0.66))
	var cb := CheckButton.new()
	cb.text = "Режим АТЕ: щелчок по карте выделяет АТЕ"
	cb.focus_mode = Control.FOCUS_NONE
	cb.tooltip_text = "АТЕ — административно-территориальная единица (~600 км²), из которых состоят регионы. В этом режиме щелчок выделяет АТЕ (с Shift — весь регион), повторный щелчок снимает выделение."
	cb.toggled.connect(func(on: bool) -> void:
		ate_mode = on
		if not on:
			ate_sel.clear()
			map_seg_cache.erase("s")
		update_adm_ui()
		map_ctl.queue_redraw())
	w.body.add_child(cb)
	adm_ui["mode"] = cb
	var clr := fed_btn("Снять выделение", w.body)
	clr.pressed.connect(func() -> void:
		ate_sel.clear()
		map_seg_cache.erase("s")
		update_adm_ui()
		map_ctl.queue_redraw())
	adm_ui["clear"] = clr
	adm_ui["sel"] = make_rt(w.body)
	# свои АТЕ: передать или создать регион
	var own := VBoxContainer.new()
	w.body.add_child(own)
	adm_ui["own"] = own
	add_title(own, "Перекроить границы")
	adm_ui["dst"] = fed_opt(own, [], "Регион, которому перейдут выделенные АТЕ (только соседний с ними).")
	adm_ui["dst"].item_selected.connect(func(_i: int) -> void: update_adm_ui())
	adm_ui["move"] = fed_btn("Передать выделенные АТЕ", own)
	adm_ui["move"].pressed.connect(on_adm_move)
	var nrow := HBoxContainer.new()
	own.add_child(nrow)
	var le := LineEdit.new()
	le.placeholder_text = "Название нового региона"
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nrow.add_child(le)
	adm_ui["name"] = le
	adm_ui["create"] = fed_btn("Создать регион из выделенных", own)
	adm_ui["create"].pressed.connect(on_adm_create)
	adm_ui["own_why"] = add_note(own, "")
	# чужие АТЕ: покупка
	var fr := VBoxContainer.new()
	w.body.add_child(fr)
	adm_ui["for"] = fr
	add_title(fr, "Купить выделенные АТЕ")
	adm_ui["bdst"] = fed_opt(fr, [], "Куда войдёт купленная земля: в соседний ваш регион или отдельной федеральной территорией.")
	adm_ui["bdst"].item_selected.connect(func(_i: int) -> void: update_adm_ui())
	adm_ui["bmult"] = fed_opt(fr, ["Цена: рыночная", "Цена: щедрая (×1.5)", "Цена: очень щедрая (×2)"])
	adm_ui["bmult"].item_selected.connect(func(_i: int) -> void: update_adm_ui())
	adm_ui["bq"] = make_rt(fr)
	adm_ui["buy"] = fed_btn("Предложить сделку", fr)
	adm_ui["buy"].pressed.connect(on_adm_buy)
	# выбранный регион: переименовать, упразднить
	var rg := VBoxContainer.new()
	w.body.add_child(rg)
	adm_ui["reg"] = rg
	adm_ui["rtitle"] = add_title(rg, "Регион")
	adm_ui["rinfo"] = add_wrap_label(rg, "")
	var rrow := HBoxContainer.new()
	rg.add_child(rrow)
	var rn := LineEdit.new()
	rn.placeholder_text = "Новое название"
	rn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rrow.add_child(rn)
	adm_ui["rname"] = rn
	var rb := make_button("Переименовать", rrow)
	rb.pressed.connect(func() -> void:
		adm_rename(selected_region, String((adm_ui["rname"] as LineEdit).text))
		(adm_ui["rname"] as LineEdit).text = "")
	adm_ui["merge_to"] = fed_opt(rg, [], "Соседний регион, к которому отойдёт вся территория упразднённого.")
	adm_ui["merge_to"].item_selected.connect(func(_i: int) -> void: update_adm_ui())
	adm_ui["merge"] = fed_btn("Упразднить регион (присоединить к соседу)", rg)
	adm_ui["merge"].pressed.connect(on_adm_delete)
	adm_ui["reg_why"] = add_note(rg, "")
	add_note(w.body, "Перекройка границ меняет население, экономику и политический состав регионов (а значит, и выборы). Затронутые регионы на время теряют лояльность и спокойствие, развитие замедляется на 2 года; каждый регион сверх стартового числа удорожает госаппарат на 1.2%%, упразднение — удешевляет. Реформа — не чаще раза в %d мес." % ADM_CD)


func adm_open() -> void:
	var w: FloatWindow = wins["adm"]
	w.closed = false
	ate_mode = true
	show_desk(2)
	w.move_to_front()
	update_adm_ui()
	map_ctl.queue_redraw()


func adm_opt_fill(o: OptionButton, items: Array, keep_id: int) -> void:
	# items: [[id, текст], ...]; сохраняет выбранный id, если он остался
	var cur: int = o.get_item_id(o.selected) if o.selected >= 0 and o.item_count > 0 else keep_id
	o.clear()
	for it in items:
		o.add_item(String(it[1]), int(it[0]))
	var k: int = o.get_item_index(cur)
	if k >= 0:
		o.select(k)
	elif o.item_count > 0:
		o.select(0)


func adm_sel_regions_adjacent() -> Array:
	# свои регионы, граничащие с выделением (кроме тех, где всё выделение уже лежит)
	var out: Array = []
	var inset := {}
	for a in ate_sel:
		inset[int(a)] = true
	for a in ate_sel:
		for b in ate_nbs(int(a)):
			if inset.has(b) or ate_cc(b) != ccode:
				continue
			var i := ate_region(b)
			if i >= 0 and not (i in out):
				out.append(i)
	for a in ate_sel:
		var i2 := ate_region(int(a))
		if i2 >= 0 and not (i2 in out):
			out.append(i2)
	return out


func update_adm_ui() -> void:
	if adm_ui.is_empty():
		return
	(adm_ui["mode"] as CheckButton).set_pressed_no_signal(ate_mode)
	(adm_ui["clear"] as Button).visible = not ate_sel.is_empty()
	var own_sel: bool = not ate_sel.is_empty() and ate_cc(int(ate_sel[0])) == ccode
	var for_sel: bool = not ate_sel.is_empty() and not own_sel
	var t := ""
	if ate_sel.is_empty():
		t = "[color=%s]Включите режим АТЕ и щёлкайте по карте, чтобы выделить единицы. Своя страна — перекройка границ регионов; соседняя — покупка части её территории.[/color]" % COL_DIM if ate_mode else "[color=%s]Регионы состоят из АТЕ (~600 км² каждая). Включите режим АТЕ, чтобы перекраивать границы, создавать регионы или покупать землю соседей по частям.[/color]" % COL_DIM
	else:
		var by := {}
		for a in ate_sel:
			var ui: int = ate_unit[int(a)]
			by[ui] = int(by.get(ui, 0)) + 1
		var names: Array = []
		for ui in by:
			var u: Dictionary = WORLD_UNITS[int(ui)]
			var nm := String(u["id"])
			if String(u["cc"]) == ccode:
				var ri := fed_idx_of_uid(nm)
				if ri >= 0:
					nm = String(REGIONS[ri]["short"])
			else:
				nm = String(fed_wreg(String(u["cc"]), nm).get("short", nm))
			names.append("%s (%d)" % [nm, int(by[ui])])
		t = "Выделено [b]%d АТЕ[/b]: %.0f км², ≈[b]%s[/b] жителей\n%s%s" % [ate_sel.size(), adm_sel_km(ate_sel), fmt_people(adm_sel_pop(ate_sel)),
			("" if own_sel else "[b]%s[/b]: " % String(WORLD[ate_cc(int(ate_sel[0]))]["name"]) if WORLD.has(ate_cc(int(ate_sel[0]))) else ""), ", ".join(PackedStringArray(names))]
	(adm_ui["sel"] as RichTextLabel).text = t
	(adm_ui["own"] as Control).visible = own_sel
	(adm_ui["for"] as Control).visible = for_sel
	if own_sel:
		var items: Array = []
		for i in adm_sel_regions_adjacent():
			items.append([i, String(REGIONS[i]["name"])])
		adm_opt_fill(adm_ui["dst"], items, -1)
		var o: OptionButton = adm_ui["dst"]
		var dst: int = o.get_item_id(o.selected) if o.selected >= 0 else -1
		var why := adm_move_check(ate_sel, dst)
		var cost := adm_cost(adm_sel_pop(ate_sel), ate_sel.size())
		(adm_ui["move"] as Button).text = "Передать выделенные АТЕ (капитал %.1f)" % cost
		(adm_ui["move"] as Button).disabled = why != ""
		var why2 := adm_create_check(ate_sel)
		(adm_ui["create"] as Button).text = "Создать регион из выделенных (капитал %.1f)" % (cost + 4.0)
		(adm_ui["create"] as Button).disabled = why2 != ""
		var notes: Array = []
		if why != "":
			notes.append("Передать нельзя: " + why)
		if why2 != "" and why2 != why:
			notes.append("Создать нельзя: " + why2)
		(adm_ui["own_why"] as Label).text = "\n".join(PackedStringArray(notes))
	if for_sel:
		var items2: Array = []
		var inset := {}
		for a in ate_sel:
			inset[int(a)] = true
		for a in ate_sel:
			for b in ate_nbs(int(a)):
				if ate_cc(b) == ccode:
					var i := ate_region(b)
					if i >= 0 and not ([i, String(REGIONS[i]["name"])] in items2):
						items2.append([i, String(REGIONS[i]["name"])])
		items2.append([1000, "Отдельной федеральной территорией"])
		adm_opt_fill(adm_ui["bdst"], items2, -1)
		var ob: OptionButton = adm_ui["bdst"]
		var bd: int = ob.get_item_id(ob.selected) if ob.selected >= 0 else 1000
		var mult: float = [1.0, 1.5, 2.0][maxi(0, (adm_ui["bmult"] as OptionButton).selected)]
		var q := ate_buy_quote(ate_sel, mult, -1 if bd == 1000 else bd)
		var qt := ""
		if q.has("price"):
			qt = "Цена ≈ [b]%.1f млрд[/b] (%.2f%% вашего ВВП, в долг), политкапитал %.1f\nСогласие правительства %s · жителей %s%s → итого [b]%s[/b]" % [float(q["price"]), float(q["gdp_pct"]), float(q["cap"]),
				fed_pct(float(q["p_gov"])), fed_pct(float(q["p_loc"])), (" · вашего референдума " + fed_pct(float(q["p_dom"]))) if float(q["p_dom"]) < 1.0 else "", fed_pct(float(q["p"]))]
		if not bool(q["ok"]):
			qt += ("\n" if qt != "" else "") + "[color=%s]%s[/color]" % [COL_BAD, "\n".join(PackedStringArray(q["why"]))]
		(adm_ui["bq"] as RichTextLabel).text = qt
		(adm_ui["buy"] as Button).disabled = not bool(q["ok"]) or not bool(q.get("afford", false))
	# выбранный регион
	var ok_reg: bool = selected_region >= 0 and selected_region < regions.size()
	(adm_ui["reg"] as Control).visible = ok_reg and map_mode == "own"
	if ok_reg:
		var i := selected_region
		(adm_ui["rtitle"] as Label).text = "Регион «%s»" % String(REGIONS[i]["name"])
		(adm_ui["rinfo"] as Label).text = "%d АТЕ, %.0f км², %s жителей. Регионов в стране: %d (на старте %d)." % [adm_region_ates(i).size(), adm_region_km(i), fmt_people(float(regions[i]["popm"])), regions.size(), wu_cc0.count(ccode)]
		var items3: Array = []
		for j in adm_region_nbs(i):
			items3.append([j, String(REGIONS[j]["name"])])
		adm_opt_fill(adm_ui["merge_to"], items3, -1)
		var om: OptionButton = adm_ui["merge_to"]
		var mj: int = om.get_item_id(om.selected) if om.selected >= 0 else -1
		var why3 := adm_delete_check(i, mj)
		(adm_ui["merge"] as Button).text = "Упразднить «%s» (капитал %.1f)" % [String(REGIONS[i]["short"]), adm_cost(float(regions[i]["popm"]), adm_region_ates(i).size()) + 2.0]
		(adm_ui["merge"] as Button).disabled = why3 != ""
		(adm_ui["reg_why"] as Label).text = "" if why3 == "" else "Упразднить нельзя: " + why3


func on_adm_move() -> void:
	var o: OptionButton = adm_ui["dst"]
	if o.selected < 0:
		return
	var r := adm_move(ate_sel.duplicate(), o.get_item_id(o.selected))
	if not bool(r["done"]):
		log_line("[color=%s]%s[/color]" % [COL_BAD, r["msg"]])
		refresh()


func on_adm_create() -> void:
	var r := adm_create(ate_sel.duplicate(), String((adm_ui["name"] as LineEdit).text))
	if bool(r["done"]):
		(adm_ui["name"] as LineEdit).text = ""
	else:
		log_line("[color=%s]%s[/color]" % [COL_BAD, r["msg"]])
		refresh()


func on_adm_delete() -> void:
	var om: OptionButton = adm_ui["merge_to"]
	if om.selected < 0:
		return
	var r := adm_delete(selected_region, om.get_item_id(om.selected))
	if not bool(r["done"]):
		log_line("[color=%s]%s[/color]" % [COL_BAD, r["msg"]])
		refresh()


func on_adm_buy() -> void:
	var ob: OptionButton = adm_ui["bdst"]
	var bd: int = ob.get_item_id(ob.selected) if ob.selected >= 0 else 1000
	var mult: float = [1.0, 1.5, 2.0][maxi(0, (adm_ui["bmult"] as OptionButton).selected)]
	var r := ate_buy(ate_sel.duplicate(), mult, -1 if bd == 1000 else bd)
	if not bool(r["done"]):
		refresh()
