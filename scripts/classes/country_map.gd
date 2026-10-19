# Карта Европы для выбора страны: страны закрашены по сложности, наведение подсвечивает, щелчок выбирает.
extends Control

const Gfx := preload("res://scripts/classes/gfx.gd")
const MapLabels := preload("res://scripts/classes/map_labels.gd")
const Flags := preload("res://scripts/classes/flags.gd")

signal picked(code: String)

var units: Array = []        # {cc, parts: Array[PackedVector2Array], rect}
var ctx: Array = []          # Array of Array[PackedVector2Array] — соседи, которых нельзя выбрать
var cols: Dictionary = {}    # код -> Color
var names: Dictionary = {}   # код -> название
var tips: Dictionary = {}    # код -> подсказка
var dim: Dictionary = {}     # 0.56: код -> true — страна не подходит под фильтры меню (серая, не выбирается)
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
var minor: Dictionary = {}      # v49: код -> подсказка (непризнанные образования: видны, но не выбираются)
var munits: Array = []          # их участки {cc, parts, rect}
var labs: Dictionary = {}       # v49: код -> подпись вдоль формы страны (MapLabels.compute)
var lab_pts: Dictionary = {}    # v49: код -> точки сетки внутри страны (для подписи видимой части)
var home := Rect2()             # v49: обзор «Европа» (карта стала шире — до Чукотки)
var home_pending := true
# v49: плавная камера — целевые масштаб и центр, к которым вид подтягивается каждый кадр
var zoom_t := 1.0
var center_t := Vector2.ZERO
var hov_a: Dictionary = {}       # v49: плавная подсветка при наведении: код -> 0..1
var geo: Node2D = null           # v53: суша и границы (перерисовка только при смене выбора)
var hl: Node2D = null            # v53: подсветка под курсором
var over: Control = null         # v53: подписи, контур выбранной страны, виньетка (экранные координаты)
var view_s := -1.0
var view_off := Vector2.ZERO
const ZMIN := 0.8
const ZMAX := 40.0

func _init() -> void:
	clip_contents = true
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(560.0, 420.0)
	focus_mode = Control.FOCUS_NONE
	# v53: слои — суша рисуется один раз в координатах карты, камера двигает только преобразование слоя
	geo = Node2D.new()
	geo.draw.connect(_draw_geo)
	add_child(geo)
	hl = Node2D.new()
	hl.draw.connect(_draw_hl)
	add_child(hl)
	over = Control.new()
	over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	over.draw.connect(_draw_over)
	add_child(over)
	over.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bx := HBoxContainer.new()
	bx.add_theme_constant_override("separation", 4)
	bx.position = Vector2(8.0, 8.0)
	add_child(bx)
	for b in [["＋", "Приблизить (или колёсико мыши)", 1], ["−", "Отдалить", 2], ["⌂", "Европа — вернуть обычный обзор", 3], ["◯", "Вся карта — от Португалии до Чукотки", 4]]:
		var btn := Button.new()
		btn.text = b[0]
		btn.tooltip_text = b[1]
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(32.0, 30.0)
		var k: int = b[2]
		btn.pressed.connect(func() -> void: zoom_cmd(k))
		bx.add_child(btn)

# v53: упрощение контура (Дуглас — Пекер): карта выбора не нуждается в 200 тыс. вершин
const SIMPLIFY := 0.15      # точный контур (крупный масштаб, попадание щелчком)
const SIMPLIFY_LO := 0.9    # грубый контур для обзора (до масштаба LOD_Z)
const LOD_Z := 5.0
var lod_hi := false

static func simplify(pts: PackedVector2Array, eps: float) -> PackedVector2Array:
	var n: int = pts.size()
	if n < 12:
		return pts
	var keep := PackedByteArray()
	keep.resize(n)
	keep.fill(0)
	keep[0] = 1
	keep[n - 1] = 1
	var e2: float = eps * eps
	var stack: Array = [Vector2i(0, n - 1)]
	while not stack.is_empty():
		var seg: Vector2i = stack.pop_back()
		var a: Vector2 = pts[seg.x]
		var ab: Vector2 = pts[seg.y] - a
		var l2: float = ab.length_squared()
		var dmax := 0.0
		var idx := -1
		for i in range(seg.x + 1, seg.y):
			var ap: Vector2 = pts[i] - a
			var d: float
			if l2 < 1e-12:
				d = ap.length_squared()
			else:
				var tt: float = clampf(ap.dot(ab) / l2, 0.0, 1.0)
				d = (ap - ab * tt).length_squared()
			if d > dmax:
				dmax = d
				idx = i
		if idx >= 0 and dmax > e2:
			keep[idx] = 1
			if idx - seg.x > 1:
				stack.append(Vector2i(seg.x, idx))
			if seg.y - idx > 1:
				stack.append(Vector2i(idx, seg.y))
	var out := PackedVector2Array()
	for i in n:
		if keep[i] == 1:
			out.append(pts[i])
	if out.size() < 4:
		return pts
	return out

func _fix(parts0: Array, eps: float = SIMPLIFY) -> Array:
	var out: Array = []
	var parts: Array = []
	for p0 in parts0:
		parts.append(simplify(p0, eps))
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

func setup(world_units: Array, world_ctx: Array, codes: Array, minor_tips: Dictionary = {}) -> void:
	minor = minor_tips
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	var acc := {}
	for u0 in world_units:
		var mc: String = String(u0["cc"])
		if not minor.has(mc):
			continue
		var mraw: Array = []
		var mlo := Vector2(1e9, 1e9)
		var mhi := Vector2(-1e9, -1e9)
		for part0 in u0["parts"]:
			var mp := _to_pts(part0)
			mraw.append(mp)
			for p0 in mp:
				mlo = Vector2(minf(mlo.x, p0.x), minf(mlo.y, p0.y))
				mhi = Vector2(maxf(mhi.x, p0.x), maxf(mhi.y, p0.y))
		munits.append({"cc": mc, "parts": _fix(mraw), "lo": _fix(mraw, SIMPLIFY_LO), "rect": Rect2(mlo, mhi - mlo)})
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
		units.append({"cc": cc, "id": String(u.get("id", "")), "parts": _fix(raw), "lo": _fix(raw, SIMPLIFY_LO), "rect": Rect2(rlo, rhi - rlo)})
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
	var hr := Rect2()
	for cc in acc:
		var a2: Dictionary = acc[cc]
		labels[cc] = a2["sx"] / maxf(a2["sa"], 0.0001)
		crect[cc] = Rect2(a2["lo"], a2["hi"] - a2["lo"])
		if cc != "RU":
			hr = crect[cc] if hr.size == Vector2.ZERO else hr.merge(crect[cc])
	# «Европа»: все страны, кроме России, плюс европейская часть России (до Урала, ≈ 52° в. д.)
	if hr.size != Vector2.ZERO:
		if acc.has("RU"):
			hr = hr.expand(Vector2(minf(25.7085 * 52.0 + 154.29, bounds.end.x), hr.get_center().y))
		home = hr.grow(hr.size.x * 0.02)
	else:
		home = bounds
	for cc5 in acc:
		labs[cc5] = _shape_label(cc5, _parts_of(units, cc5), crect[cc5])
	for mu in munits:
		labs[String(mu["cc"])] = _shape_label(String(mu["cc"]), mu["parts"], mu["rect"])
	zoom_t = zoom
	center_t = center
	for cx in world_ctx:
		var raw2: Array = []
		for part2 in cx["parts"]:
			raw2.append(_to_pts(part2))
		ctx.append(_fix(raw2, SIMPLIFY_LO))
	geo.queue_redraw()
	queue_redraw()

func _parts_of(arr: Array, cc: String) -> Array:
	var out: Array = []
	for u in arr:
		if String(u["cc"]) == cc:
			out.append_array(u["parts"] as Array)
	return out

# v49: подпись вдоль формы: точки равномерной сетки внутри страны -> ось, длина, изгиб (как у большой карты)
func _shape_label(cc: String, parts: Array, r: Rect2) -> Dictionary:
	var area := 0.0
	for pts in parts:
		area += absf(_area(pts))
	if area <= 0.0:
		return {}
	var step: float = maxf(0.5, sqrt(area / 300.0))
	var pp := PackedVector2Array()
	var ww := PackedFloat32Array()
	# только крупные участки (острова не влияют на подпись) и проверка по габаритам — сетка строится быстро
	var big: Array = []
	var brs: Array = []
	for pts1 in parts:
		if absf(_area(pts1)) < area * 0.004:
			continue
		var br := Rect2(pts1[0], Vector2.ZERO)
		for q in pts1:
			br = br.expand(q)
		big.append(pts1)
		brs.append(br)
	var y: float = r.position.y + step * 0.5
	while y < r.end.y:
		var x: float = r.position.x + step * 0.5
		while x < r.end.x:
			var pt := Vector2(x, y)
			for bi in big.size():
				if (brs[bi] as Rect2).has_point(pt) and Geometry2D.is_point_in_polygon(pt, big[bi]):
					pp.append(pt)
					ww.append(1.0)
					break
			x += step
		y += step
	if pp.size() < 3:
		return {}
	lab_pts[cc] = pp
	return MapLabels.compute(pp, ww)

func _area(pts: PackedVector2Array) -> float:
	var s := 0.0
	for i in pts.size():
		var j := (i + 1) % pts.size()
		s += pts[i].x * pts[j].y - pts[j].x * pts[i].y
	return s * 0.5

func base_scale() -> float:
	return minf(size.x / maxf(1.0, bounds.size.x), size.y / maxf(1.0, bounds.size.y)) * 0.96

func _fit_zoom(r: Rect2) -> float:
	var s2: float = minf(size.x / maxf(1.0, r.size.x), size.y / maxf(1.0, r.size.y)) * 0.96
	return s2 / maxf(0.0001, base_scale())

# v49: обзор «Европа» при открытии меню (размер карты известен только после раскладки)
func go_home(instant: bool = false) -> void:
	if size.x < 2.0 or home.size == Vector2.ZERO:
		return
	zoom_t = clampf(_fit_zoom(home), ZMIN, ZMAX)
	center_t = home.get_center()
	if instant:
		zoom = zoom_t
		center = center_t
	queue_redraw()

func _process(delta: float) -> void:
	# подсветка под курсором нарастает и гаснет плавно
	var hk: float = 1.0 - exp(-delta * 14.0)
	var redraw := false
	if hover != "" and not hov_a.has(hover):
		hov_a[hover] = 0.0
	for hc in hov_a.keys():
		var tgt: float = 1.0 if hc == hover else 0.0
		var cur: float = float(hov_a[hc])
		var nv: float = lerpf(cur, tgt, hk)
		if absf(nv - tgt) < 0.01:
			nv = tgt
		if nv != cur:
			redraw = true
		if nv <= 0.0 and hc != hover:
			hov_a.erase(hc)
		else:
			hov_a[hc] = nv
	if redraw:
		hl.queue_redraw()
	_sync_view()
	# плавная камера: экспоненциальное приближение к цели (не зависит от частоты кадров)
	var k: float = 1.0 - exp(-delta * 12.0)
	var dz: float = zoom_t - zoom
	var dc: Vector2 = center_t - center
	if absf(dz) < zoom * 0.001 and dc.length() * base_scale() * zoom < 0.3:
		if dz != 0.0 or dc != Vector2.ZERO:
			zoom = zoom_t
			center = center_t
			queue_redraw()
		return
	# масштаб интерполируем в логарифме — приближение выглядит равномерным
	zoom = exp(lerpf(log(zoom), log(zoom_t), k))
	center = center.lerp(center_t, k)
	_sync_view()

# v53: камера меняет только положение и масштаб слоёв; суша не перерисовывается
func _sync_view() -> void:
	if bounds.size.x <= 0.0 or geo == null:
		return
	var v := _view()
	var s: float = v[0]
	var off: Vector2 = v[1]
	if s == view_s and off == view_off:
		return
	var want_hi: bool = zoom >= LOD_Z
	if want_hi != lod_hi:
		lod_hi = want_hi
		geo.queue_redraw()
		hl.queue_redraw()
	view_s = s
	view_off = off
	for l in [geo, hl]:
		(l as Node2D).position = off
		(l as Node2D).scale = Vector2(s, s)
	over.size = size
	over.queue_redraw()
	queue_redraw()

func _view() -> Array:
	var s: float = base_scale() * zoom
	var off: Vector2 = size * 0.5 - center * s
	return [s, off]

func clamp_center() -> void:
	var r := bounds.grow(maxf(bounds.size.x, bounds.size.y) * 0.1)
	center_t = Vector2(clampf(center_t.x, r.position.x, r.end.x), clampf(center_t.y, r.position.y, r.end.y))

func zoom_at(pos: Vector2, f: float) -> void:
	# точка под курсором остаётся на месте (считаем от целевого вида, чтобы быстрые прокрутки складывались)
	var s0: float = base_scale() * zoom_t
	var off0: Vector2 = size * 0.5 - center_t * s0
	var wp: Vector2 = (pos - off0) / s0
	zoom_t = clampf(zoom_t * f, ZMIN, ZMAX)
	var s2: float = base_scale() * zoom_t
	center_t = wp - (pos - size * 0.5) / s2
	clamp_center()
	queue_redraw()

func zoom_cmd(k: int) -> void:
	match k:
		1: zoom_at(size * 0.5, 1.4)
		2: zoom_at(size * 0.5, 1.0 / 1.4)
		3: go_home()
		4:
			zoom_t = 1.0
			center_t = bounds.get_center()
			queue_redraw()

# приблизиться к стране (используется при выборе из списка/карточки)
func focus_country(code: String) -> void:
	if not crect.has(code):
		return
	var r: Rect2 = crect[code]
	var z: float = minf(size.x / maxf(1.0, r.size.x), size.y / maxf(1.0, r.size.y)) * 0.55 / maxf(0.0001, base_scale())
	zoom_t = clampf(z, 1.0, 24.0)
	center_t = r.get_center()
	clamp_center()
	queue_redraw()

# v49: непризнанное образование под курсором (для подсказки)
func _minor_at(pt: Vector2) -> String:
	for u in munits:
		if not (u["rect"] as Rect2).has_point(pt):
			continue
		for part in (u["parts"] as Array):
			if Geometry2D.is_point_in_polygon(pt, part):
				return String(u["cc"])
	return ""


func _cc_at(local: Vector2) -> String:
	var v := _view()
	var pt: Vector2 = (local - (v[1] as Vector2)) / float(v[0])
	if _minor_at(pt) != "":
		return ""
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
				center_t -= mm.relative / (base_scale() * zoom)
				clamp_center()
				center = center_t
				mouse_default_cursor_shape = Control.CURSOR_DRAG
				queue_redraw()
			return
		var c := _cc_at(mm.position)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if c != "" else Control.CURSOR_ARROW
		if c != hover:
			hover = c
			tooltip_text = (String(tips.get(c, names.get(c, ""))) + ("\nНе подходит под выбранные фильтры." if dim.has(c) else "")) if c != "" else ""
			over.queue_redraw()
		if c == "":
			var v2 := _view()
			var mc: String = _minor_at((mm.position - (v2[1] as Vector2)) / float(v2[0]))
			tooltip_text = String(minor.get(mc, ""))
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
					if c2 != "" and not dim.has(c2):
						select(c2)
				drag = false
				mouse_default_cursor_shape = Control.CURSOR_ARROW

func select(code: String) -> void:
	selected = code
	geo.queue_redraw()
	over.queue_redraw()
	picked.emit(code)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and home_pending and size.x > 2.0 and home.size != Vector2.ZERO:
		home_pending = false
		go_home(true)
	if what == NOTIFICATION_MOUSE_EXIT:
		drag = false
		if hover != "":
			hover = ""
			tooltip_text = ""
			over.queue_redraw()

func _halo(ci: CanvasItem, pts: PackedVector2Array, w: float) -> void:
	var q := pts.duplicate()
	q.append(q[0])
	ci.draw_polyline(q, Color(0.45, 0.75, 0.95, 0.07), w * 2.0)
	ci.draw_polyline(q, Color(0.45, 0.75, 0.95, 0.10), w)


# фон: море в экранных координатах (текстура привязана к карте)
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.035, 0.05, 0.085))
	if bounds.size.x <= 0.0:
		return
	var v := _view()
	var s: float = v[0]
	var off: Vector2 = v[1]
	var wtl: Vector2 = (Vector2.ZERO - off) / s
	var wbr: Vector2 = (size - off) / s
	var scr := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0.0), size, Vector2(0.0, size.y)])
	var wpts := PackedVector2Array([wtl, Vector2(wbr.x, wtl.y), wbr, Vector2(wtl.x, wbr.y)])
	draw_colored_polygon(scr, Color.WHITE, Gfx.uvs(wpts, Gfx.SEA_UV * 1.6), Gfx.sea_tex())
	Gfx.vgrad(self, Rect2(0.0, 0.0, size.x, size.y * 0.5), Color(0.35, 0.55, 0.85, 0.07), Color(0, 0, 0, 0))


# v53: суша в координатах карты (слой geo). Тонкие линии шириной -1 остаются в 1 пиксель при любом масштабе.
func _draw_geo() -> void:
	if bounds.size.x <= 0.0:
		return
	var hw := 0.35
	var key: String = "parts" if lod_hi else "lo"
	for parts0 in ctx:
		for pts0 in (parts0 as Array):
			_halo(geo, pts0, hw)
	for u0 in units:
		for pts1 in (u0[key] as Array):
			_halo(geo, pts1, hw)
	var ctex: Texture2D = Gfx.ctx_tex()
	for parts in ctx:
		for pts in (parts as Array):
			geo.draw_colored_polygon(pts, Color(0.16, 0.175, 0.20), Gfx.uvs(pts, Gfx.LAND_UV * 1.4), ctex)
			var cq := (pts as PackedVector2Array).duplicate()
			cq.append(cq[0])
			geo.draw_polyline(cq, Color(0.5, 0.58, 0.68, 0.22), -1.0)
	var ltex: Texture2D = Gfx.land_tex()
	var htex: Texture2D = MapLabels.hatch_tex()
	for u in units:
		var cc3: String = String(u["cc"])
		var base: Color = cols.get(cc3, Color(0.4, 0.5, 0.7))
		if dim.has(cc3) and cc3 != selected:
			base = Color(0.20, 0.215, 0.24)
		var col: Color = base.lightened(0.25) if cc3 == selected else base.darkened(0.25)
		for pts in (u[key] as Array):
			geo.draw_colored_polygon(pts, col, Gfx.uvs(pts, Gfx.LAND_UV * 1.4), ltex)
			if String(u.get("id", "")) in ["RU-CR", "RU-SEV", "RU-DNR", "RU-LNR", "RU-ZAP", "RU-KHE"]:
				# v50: занятые Россией территории Украины (Крым, ДНР, ЛНР, юг Запорожской и Херсонской областей): светлая штриховка
				geo.draw_colored_polygon(pts, Color(1.0, 0.85, 0.55, 0.22), Gfx.uvs(pts, 40.0), htex)
			var closed := (pts as PackedVector2Array).duplicate()
			closed.append(closed[0])
			geo.draw_polyline(closed, Color(1, 1, 1, 0.35) if cc3 == selected else Color(0.03, 0.04, 0.07, 0.45), -1.0)
	# v49: непризнанные образования — серые со штриховкой, выбрать нельзя
	for mu in munits:
		for pts3 in (mu[key] as Array):
			geo.draw_colored_polygon(pts3, Color(0.30, 0.27, 0.29), Gfx.uvs(pts3, Gfx.LAND_UV * 1.4), ltex)
			geo.draw_colored_polygon(pts3, Color(0.06, 0.04, 0.05, 0.45), Gfx.uvs(pts3, 40.0), htex)
			var c3 := (pts3 as PackedVector2Array).duplicate()
			c3.append(c3[0])
			geo.draw_polyline(c3, Color(0.85, 0.35, 0.30, 0.55), -1.0)


# v53: плавная подсветка страны под курсором (слой hl, перерисовка только пока она нарастает или гаснет)
func _draw_hl() -> void:
	var key2: String = "parts" if lod_hi else "lo"
	for hc in hov_a:
		if hc == selected:
			continue
		var a: float = float(hov_a[hc])
		for u in units:
			if String(u["cc"]) != hc:
				continue
			for pts in (u[key2] as Array):
				hl.draw_colored_polygon(pts, Color(1.0, 1.0, 1.0, 0.16 * a))
				var q := (pts as PackedVector2Array).duplicate()
				q.append(q[0])
				hl.draw_polyline(q, Color(1, 1, 1, 0.5 * a), -1.0)


# экранный слой: контур выбранной страны, подписи, виньетка, подсказка
func _draw_over() -> void:
	if bounds.size.x <= 0.0:
		return
	var v := _view()
	var s: float = v[0]
	var off: Vector2 = v[1]
	if selected != "":
		over.draw_set_transform(off, 0.0, Vector2(s, s))
		for ring in outline(selected):
			var pr := (ring as PackedVector2Array).duplicate()
			pr.append(pr[0])
			over.draw_polyline(pr, Color(0.6, 0.85, 1.0, 0.18), 9.0 / s, true)
			over.draw_polyline(pr, Color(1, 1, 1, 0.95), 2.0 / s, true)
		over.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var font := get_theme_default_font()
	# v53: подпись привязана к стране и не ездит за камерой; если не помещается — флажок или код в центре страны
	for cc4 in labels:
		var hi4: bool = cc4 == selected or cc4 == hover
		var lc := Color(1, 1, 1, 0.97 if hi4 else 0.86)
		var nm4: String = String(names.get(cc4, cc4)).to_upper()
		if MapLabels.draw(over, font, labs.get(cc4, {}), nm4, s, off, lc, 34.0, 11.0):
			continue
		var rc: Rect2 = crect[cc4]
		var px: float = rc.size.x * s
		if px <= 74.0 and Flags.has(String(cc4)):
			# v49: маленькая страна — флажок вместо кода (название — в подсказке)
			var fw: float = 18.0 if not hi4 else 24.0
			var fp: Vector2 = (labels[cc4] as Vector2) * s + off - Vector2(fw * 0.5, fw / 3.0)
			Flags.draw(over, String(cc4), Rect2(fp, Vector2(fw, fw / 1.5)))
			continue
		var txt: String = String(names.get(cc4, cc4)) if px > 74.0 else cc4
		var fs := 13 if px > 74.0 else 11
		var tw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var pos: Vector2 = (labels[cc4] as Vector2) * s + off + Vector2(-tw * 0.5, 4.0)
		Gfx.label(over, font, pos, txt, fs, lc, -1.0, HORIZONTAL_ALIGNMENT_LEFT, 3)
	for mc4 in minor:
		var mt: String = String(minor[mc4]).get_slice(" —", 0).to_upper()
		MapLabels.draw(over, font, labs.get(mc4, {}), mt, s, off, Color(1.0, 0.86, 0.86, 0.8), 18.0, 9.0)
	Gfx.vignette(over, size, 0.40, minf(130.0, size.x * 0.12))
	var hint := "Колёсико — масштаб · перетащите карту · щелчок — выбрать страну   (×%.1f)" % zoom
	over.draw_string(font, Vector2(10.0, size.y - 8.0), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.45))


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


# 0.56: перекрасить карту (цвета или фильтры меню изменились)
func recolor() -> void:
	if geo != null:
		geo.queue_redraw()
	if over != null:
		over.queue_redraw()
