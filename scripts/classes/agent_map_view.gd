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
const PAD := 22.0

func _init() -> void:
	custom_minimum_size = Vector2(220.0, 240.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true

# область графика (внутри полей под подписи)
func plot() -> Rect2:
	return Rect2(Vector2(PAD, PAD), size - Vector2(PAD, PAD) * 2.0)

func to_px(v: Vector2) -> Vector2:
	var r := plot()
	return Vector2(r.position.x + r.size.x * 0.5 + v.x / xr * r.size.x * 0.5, r.position.y + r.size.y * 0.5 - v.y / xr * r.size.y * 0.5)

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
	var c0: Vector2 = to_px(Vector2.ZERO)
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
		draw_circle(to_px(pts[i]), 2.3, col)
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
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var best := nearest_point(e.position, 12.0)
		if best >= 0 and picked.is_valid():
			picked.call(ids[best])

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and (hover >= 0 or hover_mark >= 0):
		hover = -1
		hover_mark = -1
		tooltip_text = ""
		queue_redraw()
