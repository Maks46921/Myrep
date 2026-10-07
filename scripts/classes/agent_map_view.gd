# Идеологическая карта: точки-агенты по двум осям, подписи концов осей, шкала, позиции партий.
extends Control

var pts := PackedVector2Array()
var cols := PackedColorArray()
var ids := PackedInt32Array()
var favs := PackedInt32Array()   # партия, за которую проголосует агент (для фильтра)
var marks: Array = []        # [Vector2, Color, String, float доля голосов 0..1, bool партия игрока]
var sel := Vector2(INF, INF)
var xr := 2.2
var picked := Callable()
var tipper := Callable()     # id агента -> текст подсказки
var ends: Array = ["", "", "", ""]   # левый, правый, нижний, верхний конец осей
var axis_names: Array = ["", ""]
var filter := -1             # показывать только агентов этой партии (-1 — всех)
var centroid := Vector2(INF, INF)
var hover := -1
var hover_mark := -1
var zoom := 1.0              # v35: приближение (колёсико), сдвиг — перетаскиванием
var pan := Vector2.ZERO      # центр вида в координатах осей
var _drag := false
var _drag_from := Vector2.ZERO
var _moved := false
const PAD := 22.0

func _init() -> void:
	custom_minimum_size = Vector2(160.0, 160.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true

# область графика (внутри полей под подписи)
func plot() -> Rect2:
	return Rect2(Vector2(PAD, PAD), size - Vector2(PAD, PAD) * 2.0)

func to_px(v: Vector2) -> Vector2:
	var r := plot()
	var u := (v - pan) * zoom
	return Vector2(r.position.x + r.size.x * 0.5 + u.x / xr * r.size.x * 0.5, r.position.y + r.size.y * 0.5 - u.y / xr * r.size.y * 0.5)

func from_px(p: Vector2) -> Vector2:
	var r := plot()
	var u := Vector2((p.x - r.position.x - r.size.x * 0.5) / (r.size.x * 0.5) * xr, -(p.y - r.position.y - r.size.y * 0.5) / (r.size.y * 0.5) * xr)
	return u / zoom + pan

func zoom_at(p: Vector2, k: float) -> void:
	var before := from_px(p)
	zoom = clampf(zoom * k, 1.0, 8.0)
	pan += before - from_px(p)
	clamp_pan()
	queue_redraw()

func clamp_pan() -> void:
	var lim: float = xr * (1.0 - 1.0 / zoom)
	pan = Vector2(clampf(pan.x, -lim, lim), clampf(pan.y, -lim, lim))

func reset_view() -> void:
	zoom = 1.0
	pan = Vector2.ZERO
	queue_redraw()

func text_box(f: Font, pos: Vector2, txt: String, fs: int, col: Color, align: int = 0) -> void:
	# align: 0 — от pos вправо, 1 — по центру, 2 — вправо-налево (pos — правый край)
	var w: float = f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var x: float = pos.x - (w * 0.5 if align == 1 else (w if align == 2 else 0.0))
	x = clampf(x, 2.0, maxf(2.0, size.x - w - 2.0))
	draw_rect(Rect2(Vector2(x - 3.0, pos.y - fs - 1.0), Vector2(w + 6.0, fs + 5.0)), Color(0.04, 0.05, 0.09, 0.78))
	draw_string(f, Vector2(x, pos.y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

func _draw() -> void:
	var f := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.07, 0.11))
	var r := plot()
	draw_rect(r, Color(0.075, 0.09, 0.14))
	var c0: Vector2 = to_px(Vector2.ZERO).clamp(r.position, r.end)
	# четверти слегка подкрашены, чтобы было видно, где «лево-право» и «верх-низ»
	draw_rect(Rect2(r.position, Vector2(c0.x - r.position.x, c0.y - r.position.y)), Color(1, 1, 1, 0.012))
	draw_rect(Rect2(c0, r.end - c0), Color(1, 1, 1, 0.012))
	# сетка и шкала
	for t in [-2, -1, 1, 2]:
		var gx: float = to_px(Vector2(float(t), 0.0)).x
		var gy: float = to_px(Vector2(0.0, float(t))).y
		if gx > r.position.x and gx < r.end.x:
			draw_line(Vector2(gx, r.position.y), Vector2(gx, r.end.y), Color(1, 1, 1, 0.06))
			draw_string(f, Vector2(gx - 6.0, r.end.y + 12.0), "%+d" % t, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.35))
		if gy > r.position.y and gy < r.end.y:
			draw_line(Vector2(r.position.x, gy), Vector2(r.end.x, gy), Color(1, 1, 1, 0.06))
			draw_string(f, Vector2(r.position.x - 18.0, gy + 4.0), "%+d" % t, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.35))
	draw_line(Vector2(c0.x, r.position.y), Vector2(c0.x, r.end.y), Color(1, 1, 1, 0.28), 1.5)
	draw_line(Vector2(r.position.x, c0.y), Vector2(r.end.x, c0.y), Color(1, 1, 1, 0.28), 1.5)
	draw_rect(r, Color(1, 1, 1, 0.18), false, 1.0)
	# точки агентов
	for i in pts.size():
		var col: Color = cols[i]
		if filter >= 0 and favs.size() > i and favs[i] != filter:
			col.a = 0.08
		var pp: Vector2 = to_px(pts[i])
		if r.grow(2.0).has_point(pp):
			draw_circle(pp, 2.3 if zoom < 2.5 else 3.2, col)
	# центр общества
	if centroid.x != INF:
		var cc: Vector2 = to_px(centroid)
		draw_line(cc + Vector2(-7, 0), cc + Vector2(7, 0), Color(1, 1, 1, 0.9), 2.0)
		draw_line(cc + Vector2(0, -7), cc + Vector2(0, 7), Color(1, 1, 1, 0.9), 2.0)
		text_box(f, cc + Vector2(9.0, -6.0), "центр общества", 10, Color(1, 1, 1, 0.8))
	# партии: размер кружка — доля голосов
	for mi in marks.size():
		var m: Array = marks[mi]
		var c: Vector2 = to_px(m[0])
		if not r.grow(6.0).has_point(c):
			continue
		var rad: float = 5.0 + 9.0 * sqrt(clampf(float(m[3]), 0.0, 1.0))
		if filter >= 0 and filter != mi:
			rad = 4.0
		draw_circle(c, rad + 2.0, Color(1, 1, 1, 0.95 if (hover_mark == mi or bool(m[4])) else 0.7))
		draw_circle(c, rad, m[1])
		if bool(m[4]):
			draw_string(f, c + Vector2(-4.0, 4.5), "★", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0, 0, 0, 0.8))
		if filter == mi or (filter < 0 and (float(m[3]) >= 0.04 or bool(m[4]) or hover_mark == mi)):
			text_box(f, c + Vector2(rad + 5.0, 4.0), String(m[2]), 11, Color(1, 1, 1, 0.95))
	if sel.x != INF:
		var s: Vector2 = to_px(sel)
		draw_arc(s, 9.0, 0.0, TAU, 24, Color(1, 0.9, 0.3), 2.5)
		draw_circle(s, 2.6, Color(1, 0.9, 0.3))
	if hover >= 0 and hover < pts.size():
		draw_arc(to_px(pts[hover]), 7.0, 0.0, TAU, 20, Color(1, 1, 1, 0.9), 1.5)
	# подписи концов осей: по краям графика
	var dim := Color(0.75, 0.82, 1.0, 0.9)
	if ends.size() >= 4:
		draw_string(f, Vector2(r.position.x + 3.0, r.end.y - 5.0), "◀ " + String(ends[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, dim)
		var rw: float = f.get_string_size(String(ends[1]) + " ▶", HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(f, Vector2(r.end.x - rw - 3.0, r.end.y - 5.0), String(ends[1]) + " ▶", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, dim)
		var tw: float = f.get_string_size("▲ " + String(ends[3]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(f, Vector2(c0.x - tw * 0.5, r.position.y + 13.0), "▲ " + String(ends[3]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, dim)
		var bw: float = f.get_string_size("▼ " + String(ends[2]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(f, Vector2(c0.x - bw * 0.5, r.end.y - 18.0), "▼ " + String(ends[2]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, dim)
	if axis_names.size() >= 2:
		draw_string(f, Vector2(r.position.x, 14.0), "→ " + String(axis_names[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.75))
		var yn: String = "↑ " + String(axis_names[1])
		var yw: float = f.get_string_size(yn, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(f, Vector2(r.end.x - yw, 14.0), yn, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.75))
	if zoom > 1.01:
		text_box(f, Vector2(r.end.x - 4.0, r.position.y + 14.0), "×%.1f · двойной щелчок — весь вид" % zoom, 10, Color(1, 1, 1, 0.75), 2)
	else:
		text_box(f, Vector2(r.end.x - 4.0, r.position.y + 14.0), "колёсико — приблизить", 10, Color(1, 1, 1, 0.45), 2)


func nearest_point(pos: Vector2, max_d: float) -> int:
	var best := -1
	var bd := max_d * max_d
	for i in pts.size():
		if filter >= 0 and favs.size() > i and favs[i] != filter:
			continue
		var d: float = to_px(pts[i]).distance_squared_to(pos)
		if d < bd:
			bd = d
			best = i
	return best

func nearest_mark(pos: Vector2) -> int:
	var best := -1
	var bd := 16.0 * 16.0
	for mi in marks.size():
		var d: float = to_px((marks[mi] as Array)[0]).distance_squared_to(pos)
		if d < bd:
			bd = d
			best = mi
	return best

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and (e.button_index == MOUSE_BUTTON_WHEEL_UP or e.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		zoom_at(e.position, 1.2 if e.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.2)
		accept_event()
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.double_click:
		reset_view()
		accept_event()
		return
	if e is InputEventMouseMotion and _drag and ((e as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		var mp: Vector2 = (e as InputEventMouseMotion).position
		if mp.distance_to(_drag_from) > 4.0 or _moved:
			_moved = true
			var r := plot()
			var rel: Vector2 = (e as InputEventMouseMotion).relative
			pan -= Vector2(rel.x / (r.size.x * 0.5) * xr, -rel.y / (r.size.y * 0.5) * xr) / zoom
			clamp_pan()
			queue_redraw()
			return
	if e is InputEventMouseMotion:
		var p: Vector2 = (e as InputEventMouseMotion).position
		var hm := nearest_mark(p)
		var hp := -1 if hm >= 0 else nearest_point(p, 8.0)
		if hm != hover_mark or hp != hover:
			hover_mark = hm
			hover = hp
			if hm >= 0:
				tooltip_text = String((marks[hm] as Array)[5]) if (marks[hm] as Array).size() > 5 else String((marks[hm] as Array)[2])
			elif hp >= 0 and tipper.is_valid():
				tooltip_text = String(tipper.call(ids[hp]))
			else:
				tooltip_text = ""
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if hp >= 0 else Control.CURSOR_ARROW
			queue_redraw()
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_drag = true
			_moved = false
			_drag_from = e.position
		else:
			_drag = false
			if not _moved:
				var best := nearest_point(e.position, 12.0)
				if best >= 0 and picked.is_valid():
					picked.call(ids[best])
			_moved = false

func _notification(what: int) -> void:
	# v35: карта сохраняет пропорции — растёт вместе с шириной окна (лишнее прокручивается)
	if what == NOTIFICATION_RESIZED:
		var want: float = clampf(size.x * 0.8, 160.0, 900.0)
		if absf(custom_minimum_size.y - want) > 2.0:
			custom_minimum_size.y = want
	if what == NOTIFICATION_MOUSE_EXIT and (hover >= 0 or hover_mark >= 0):
		hover = -1
		hover_mark = -1
		tooltip_text = ""
		queue_redraw()
