# Карта Европы для выбора страны: страны закрашены по сложности, наведение подсвечивает, щелчок выбирает.
extends Control

signal picked(code: String)

var units: Array = []        # {cc, parts: Array[PackedVector2Array], rect}
var ctx: Array = []          # Array of Array[PackedVector2Array] — соседи, которых нельзя выбрать
var cols: Dictionary = {}    # код -> Color
var names: Dictionary = {}   # код -> название
var tips: Dictionary = {}    # код -> подсказка
var selected := ""
var hover := ""
var bounds := Rect2()
var labels: Dictionary = {}  # код -> Vector2 (мировые координаты подписи)
var crect: Dictionary = {}   # код -> Rect2
var zoom := 1.0              # масштаб (1 = вся карта целиком)
var center := Vector2.ZERO   # центр обзора в мировых координатах
var drag := false
var outlines: Dictionary = {}   # код -> внешний контур страны (v35)
var drag_moved := false
var drag_start := Vector2.ZERO
const ZMIN := 0.8
const ZMAX := 14.0

func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(560.0, 420.0)
	focus_mode = Control.FOCUS_NONE
	var bx := HBoxContainer.new()
	bx.add_theme_constant_override("separation", 4)
	bx.position = Vector2(8.0, 8.0)
	add_child(bx)
	for b in [["＋", "Приблизить (или колёсико мыши)", 1], ["−", "Отдалить", 2], ["⌂", "Вся карта — сбросить масштаб и положение", 3]]:
		var btn := Button.new()
		btn.text = b[0]
		btn.tooltip_text = b[1]
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(32.0, 30.0)
		var k: int = b[2]
		btn.pressed.connect(func() -> void: zoom_cmd(k))
		bx.add_child(btn)

func _fix(parts: Array) -> Array:
	var out: Array = []
	for pts in parts:
		if (Geometry2D.triangulate_polygon(pts) as PackedInt32Array).is_empty():
			for q in Geometry2D.offset_polygon(pts, 0.02):
				if not (Geometry2D.triangulate_polygon(q) as PackedInt32Array).is_empty():
					out.append(q)
		else:
			out.append(pts)
	return out

func _to_pts(part: Array) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in range(0, part.size(), 2):
		pts.append(Vector2(float(part[k]), float(part[k + 1])))
	return pts

func setup(world_units: Array, world_ctx: Array, codes: Array) -> void:
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	var acc := {}
	for u in world_units:
		var cc: String = String(u["cc"])
		if not (cc in codes):
			continue
		var raw: Array = []
		var rlo := Vector2(1e9, 1e9)
		var rhi := Vector2(-1e9, -1e9)
		for part in u["parts"]:
			var pts := _to_pts(part)
			raw.append(pts)
			for p in pts:
				rlo = Vector2(minf(rlo.x, p.x), minf(rlo.y, p.y))
				rhi = Vector2(maxf(rhi.x, p.x), maxf(rhi.y, p.y))
		units.append({"cc": cc, "parts": _fix(raw), "rect": Rect2(rlo, rhi - rlo)})
		lo = Vector2(minf(lo.x, rlo.x), minf(lo.y, rlo.y))
		hi = Vector2(maxf(hi.x, rhi.x), maxf(hi.y, rhi.y))
		if not acc.has(cc):
			acc[cc] = {"lo": rlo, "hi": rhi, "sx": Vector2.ZERO, "sa": 0.0}
		var a: Dictionary = acc[cc]
		a["lo"] = Vector2(minf(a["lo"].x, rlo.x), minf(a["lo"].y, rlo.y))
		a["hi"] = Vector2(maxf(a["hi"].x, rhi.x), maxf(a["hi"].y, rhi.y))
		for pts2 in (units[units.size() - 1]["parts"] as Array):
			var r2 := Rect2(pts2[0], Vector2.ZERO)
			for p2 in pts2:
				r2 = r2.expand(p2)
			var ar: float = absf(_area(pts2))
			a["sx"] += r2.get_center() * ar
			a["sa"] += ar
	bounds = Rect2(lo, hi - lo).grow(2.0)
	center = bounds.get_center()
	for cc in acc:
		var a2: Dictionary = acc[cc]
		labels[cc] = a2["sx"] / maxf(a2["sa"], 0.0001)
		crect[cc] = Rect2(a2["lo"], a2["hi"] - a2["lo"])
	for cx in world_ctx:
		var raw2: Array = []
		for part2 in cx["parts"]:
			raw2.append(_to_pts(part2))
		ctx.append(_fix(raw2))
	queue_redraw()

func _area(pts: PackedVector2Array) -> float:
	var s := 0.0
	for i in pts.size():
		var j := (i + 1) % pts.size()
		s += pts[i].x * pts[j].y - pts[j].x * pts[i].y
	return s * 0.5

func base_scale() -> float:
	return minf(size.x / maxf(1.0, bounds.size.x), size.y / maxf(1.0, bounds.size.y)) * 0.96

func _view() -> Array:
	var s: float = base_scale() * zoom
	var off: Vector2 = size * 0.5 - center * s
	return [s, off]

func clamp_center() -> void:
	var r := bounds.grow(maxf(bounds.size.x, bounds.size.y) * 0.1)
	center = Vector2(clampf(center.x, r.position.x, r.end.x), clampf(center.y, r.position.y, r.end.y))

func zoom_at(pos: Vector2, f: float) -> void:
	var v := _view()
	var wp: Vector2 = (pos - (v[1] as Vector2)) / float(v[0])
	zoom = clampf(zoom * f, ZMIN, ZMAX)
	var s2: float = base_scale() * zoom
	center = wp - (pos - size * 0.5) / s2
	clamp_center()
	queue_redraw()

func zoom_cmd(k: int) -> void:
	match k:
		1: zoom_at(size * 0.5, 1.4)
		2: zoom_at(size * 0.5, 1.0 / 1.4)
		3:
			zoom = 1.0
			center = bounds.get_center()
			queue_redraw()

# приблизиться к стране (используется при выборе из списка/карточки)
func focus_country(code: String) -> void:
	if not crect.has(code):
		return
	var r: Rect2 = crect[code]
	var z: float = minf(size.x / maxf(1.0, r.size.x), size.y / maxf(1.0, r.size.y)) * 0.55 / maxf(0.0001, base_scale())
	zoom = clampf(z, 1.0, 6.0)
	center = r.get_center()
	clamp_center()
	queue_redraw()

func _cc_at(local: Vector2) -> String:
	var v := _view()
	var pt: Vector2 = (local - (v[1] as Vector2)) / float(v[0])
	for u in units:
		if not (u["rect"] as Rect2).has_point(pt):
			continue
		for part in (u["parts"] as Array):
			if Geometry2D.is_point_in_polygon(pt, part):
				return String(u["cc"])
	return ""

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var mm := e as InputEventMouseMotion
		if drag:
			if (mm.position - drag_start).length() > 6.0:
				drag_moved = true
			if drag_moved:
				center -= mm.relative / (base_scale() * zoom)
				clamp_center()
				mouse_default_cursor_shape = Control.CURSOR_DRAG
				queue_redraw()
			return
		var c := _cc_at(mm.position)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if c != "" else Control.CURSOR_ARROW
		if c != hover:
			hover = c
			tooltip_text = String(tips.get(c, names.get(c, ""))) if c != "" else ""
			queue_redraw()
	elif e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_at(mb.position, 1.25)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_at(mb.position, 0.8)
		elif mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_MIDDLE or mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				drag = true
				drag_moved = false
				drag_start = mb.position
			else:
				if drag and not drag_moved and mb.button_index == MOUSE_BUTTON_LEFT:
					var c2 := _cc_at(mb.position)
					if c2 != "":
						select(c2)
				drag = false
				mouse_default_cursor_shape = Control.CURSOR_ARROW

func select(code: String) -> void:
	selected = code
	queue_redraw()
	picked.emit(code)

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		drag = false
		if hover != "":
			hover = ""
			tooltip_text = ""
			queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.035, 0.05, 0.085))
	if bounds.size.x <= 0.0:
		return
	var v := _view()
	var s: float = v[0]
	var off: Vector2 = v[1]
	for parts in ctx:
		for pts in (parts as Array):
			var q := PackedVector2Array()
			for p in pts:
				q.append(p * s + off)
			draw_colored_polygon(q, Color(0.13, 0.15, 0.2))
			draw_polyline(q, Color(0.2, 0.23, 0.3), 1.0)
	var order: Array = []
	for u in units:
		var cc: String = String(u["cc"])
		if cc != selected and cc != hover:
			order.append(u)
	for u in units:
		var cc2: String = String(u["cc"])
		if cc2 == hover and cc2 != selected:
			order.append(u)
	for u in units:
		if String(u["cc"]) == selected:
			order.append(u)
	for u in order:
		var cc3: String = String(u["cc"])
		var base: Color = cols.get(cc3, Color(0.4, 0.5, 0.7))
		var col: Color = base.darkened(0.25)
		if cc3 == selected:
			col = base.lightened(0.25)
		elif cc3 == hover:
			col = base.lightened(0.1)
		for pts in (u["parts"] as Array):
			var q2 := PackedVector2Array()
			for p in pts:
				q2.append(p * s + off)
			draw_colored_polygon(q2, col)
			var edge := Color(0.03, 0.04, 0.07, 0.55)
			var wdt := 0.8
			if cc3 == selected:
				edge = Color(1, 1, 1, 0.35)
				wdt = 0.8
			elif cc3 == hover:
				edge = Color(1, 1, 1, 0.5)
				wdt = 1.2
			var closed := q2.duplicate()
			closed.append(q2[0])
			draw_polyline(closed, edge, wdt)
	if selected != "":
		for ring in outline(selected):
			var pr := PackedVector2Array()
			for p in (ring as PackedVector2Array):
				pr.append(p * s + off)
			pr.append(pr[0])
			draw_polyline(pr, Color(1, 1, 1, 0.95), 2.0)
	var font := get_theme_default_font()
	for cc4 in labels:
		var rc: Rect2 = crect[cc4]
		var px: float = rc.size.x * s
		var txt: String = String(names.get(cc4, cc4)) if px > 74.0 else cc4
		var fs := 13 if px > 74.0 else 11
		var tw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var pos: Vector2 = (labels[cc4] as Vector2) * s + off + Vector2(-tw * 0.5, 4.0)
		draw_string(font, pos + Vector2(1, 1), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.85))
		draw_string(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.95 if cc4 == selected or cc4 == hover else 0.8))
	var hint := "Колёсико — масштаб · перетащите карту · щелчок — выбрать страну   (×%.1f)" % zoom
	draw_string(font, Vector2(10.0, size.y - 8.0), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.45))


# v35: внешний контур набора полигонов (объединение; мелкие щели между единицами из разных источников закрываются).
static func outline_of(parts: Array) -> Array:
	const GROW := 0.6
	var res: Array = []
	for part in parts:
		var grown: Array = Geometry2D.offset_polygon(part, GROW)
		if grown.is_empty():
			continue
		var cur: PackedVector2Array = grown[0]
		var keep: Array = []
		for q in res:
			if (Geometry2D.intersect_polygons(cur, q) as Array).is_empty():
				keep.append(q)
				continue
			var best := PackedVector2Array()
			var ba := -1.0
			for m in Geometry2D.merge_polygons(cur, q):
				var ar := absf(_area_s(m))
				if ar > ba:
					ba = ar
					best = m
			cur = best
		keep.append(cur)
		res = keep
	var out: Array = []
	for q in res:
		for sh in Geometry2D.offset_polygon(q, -GROW):
			if absf(_area_s(sh)) > 0.5:
				out.append(sh)
	return out

static func _area_s(pts: PackedVector2Array) -> float:
	var s := 0.0
	for i in pts.size():
		var j := (i + 1) % pts.size()
		s += pts[i].x * pts[j].y - pts[j].x * pts[i].y
	return s * 0.5

func outline(cc: String) -> Array:
	if not outlines.has(cc):
		var parts: Array = []
		for u in units:
			if String(u["cc"]) == cc:
				parts.append_array(u["parts"] as Array)
		outlines[cc] = outline_of(parts)
	return outlines[cc]
