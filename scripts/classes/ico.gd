# Векторные значки (без картинок): рисуются кодом, масштабируются под размер контрола.
extends Control

var kind := ""
var col := Color(0.82, 0.88, 1.0)

static func make(k: String, c: Color = Color(0.82, 0.88, 1.0), px: float = 18.0) -> Control:
	var s = load("res://scripts/classes/ico.gd").new()
	s.kind = k
	s.col = c
	s.custom_minimum_size = Vector2(px, px)
	s.size = Vector2(px, px)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


func _draw() -> void:
	var u: float = minf(size.x, size.y)
	if u <= 1.0:
		return
	var o := Vector2((size.x - u) * 0.5, (size.y - u) * 0.5)
	var w: float = maxf(1.4, u * 0.1)
	draw_icon(kind, o, u, w, col, self)


# p(x,y) — точка в долях единичного квадрата
static func P(o: Vector2, u: float, x: float, y: float) -> Vector2:
	return o + Vector2(x, y) * u


static func draw_icon(k: String, o: Vector2, u: float, w: float, c: Color, d: CanvasItem) -> void:
	match k:
		"cath":
			d.draw_line(P(o, u, 0.5, 0.1), P(o, u, 0.5, 0.92), c, w)
			d.draw_line(P(o, u, 0.25, 0.34), P(o, u, 0.75, 0.34), c, w)
		"prot":
			d.draw_line(P(o, u, 0.5, 0.12), P(o, u, 0.5, 0.9), c, w)
			d.draw_line(P(o, u, 0.28, 0.4), P(o, u, 0.72, 0.4), c, w)
			d.draw_arc(P(o, u, 0.5, 0.4), u * 0.3, 0.0, TAU, 20, c, w * 0.6)
		"orth":
			d.draw_line(P(o, u, 0.5, 0.08), P(o, u, 0.5, 0.92), c, w)
			d.draw_line(P(o, u, 0.36, 0.22), P(o, u, 0.64, 0.22), c, w)
			d.draw_line(P(o, u, 0.24, 0.42), P(o, u, 0.76, 0.42), c, w)
			d.draw_line(P(o, u, 0.36, 0.78), P(o, u, 0.64, 0.64), c, w * 0.8)
		"musl":
			d.draw_arc(P(o, u, 0.46, 0.5), u * 0.36, 0.6, TAU - 0.6, 24, c, w)
			d.draw_circle(P(o, u, 0.7, 0.34), u * 0.07, c)
		"jew":
			var a: PackedVector2Array = PackedVector2Array([P(o, u, 0.5, 0.1), P(o, u, 0.86, 0.72), P(o, u, 0.14, 0.72), P(o, u, 0.5, 0.1)])
			var b: PackedVector2Array = PackedVector2Array([P(o, u, 0.5, 0.9), P(o, u, 0.86, 0.28), P(o, u, 0.14, 0.28), P(o, u, 0.5, 0.9)])
			d.draw_polyline(a, c, w * 0.8)
			d.draw_polyline(b, c, w * 0.8)
		"east":
			d.draw_arc(P(o, u, 0.5, 0.5), u * 0.38, 0.0, TAU, 24, c, w * 0.8)
			d.draw_circle(P(o, u, 0.5, 0.5), u * 0.07, c)
			for i in 6:
				var an: float = float(i) * TAU / 6.0
				d.draw_line(P(o, u, 0.5, 0.5), P(o, u, 0.5 + cos(an) * 0.38, 0.5 + sin(an) * 0.38), c, w * 0.6)
		"none":
			d.draw_arc(P(o, u, 0.5, 0.5), u * 0.36, 0.0, TAU, 24, c, w * 0.8)
			d.draw_line(P(o, u, 0.32, 0.5), P(o, u, 0.68, 0.5), c, w * 0.8)
		"coin":
			d.draw_arc(P(o, u, 0.5, 0.5), u * 0.38, 0.0, TAU, 24, c, w)
			d.draw_line(P(o, u, 0.5, 0.3), P(o, u, 0.5, 0.7), c, w * 0.8)
			d.draw_line(P(o, u, 0.38, 0.4), P(o, u, 0.62, 0.4), c, w * 0.7)
			d.draw_line(P(o, u, 0.38, 0.6), P(o, u, 0.62, 0.6), c, w * 0.7)
		"chart":
			d.draw_line(P(o, u, 0.12, 0.88), P(o, u, 0.92, 0.88), c, w * 0.8)
			d.draw_rect(Rect2(P(o, u, 0.2, 0.55), Vector2(u * 0.14, u * 0.33)), c)
			d.draw_rect(Rect2(P(o, u, 0.43, 0.32), Vector2(u * 0.14, u * 0.56)), c)
			d.draw_rect(Rect2(P(o, u, 0.66, 0.15), Vector2(u * 0.14, u * 0.73)), c)
		"hall":
			d.draw_colored_polygon(PackedVector2Array([P(o, u, 0.1, 0.4), P(o, u, 0.5, 0.1), P(o, u, 0.9, 0.4)]), c)
			for i in 4:
				d.draw_rect(Rect2(P(o, u, 0.16 + 0.2 * float(i), 0.46), Vector2(u * 0.1, u * 0.34)), c)
			d.draw_rect(Rect2(P(o, u, 0.08, 0.84), Vector2(u * 0.84, u * 0.07)), c)
		"pin":
			d.draw_arc(P(o, u, 0.5, 0.38), u * 0.26, 0.0, TAU, 20, c, w)
			d.draw_line(P(o, u, 0.3, 0.55), P(o, u, 0.5, 0.92), c, w)
			d.draw_line(P(o, u, 0.7, 0.55), P(o, u, 0.5, 0.92), c, w)
			d.draw_circle(P(o, u, 0.5, 0.38), u * 0.08, c)
		"scroll":
			d.draw_rect(Rect2(P(o, u, 0.2, 0.1), Vector2(u * 0.6, u * 0.8)), c, false, w * 0.8)
			for i in 3:
				d.draw_line(P(o, u, 0.32, 0.3 + 0.2 * float(i)), P(o, u, 0.68, 0.3 + 0.2 * float(i)), c, w * 0.6)
		"bank":
			d.draw_rect(Rect2(P(o, u, 0.12, 0.2), Vector2(u * 0.76, u * 0.62)), c, false, w * 0.8)
			d.draw_line(P(o, u, 0.12, 0.42), P(o, u, 0.88, 0.42), c, w * 0.7)
			d.draw_circle(P(o, u, 0.5, 0.62), u * 0.1, c)
		"people":
			d.draw_circle(P(o, u, 0.5, 0.28), u * 0.14, c)
			d.draw_arc(P(o, u, 0.5, 0.88), u * 0.3, PI, TAU, 16, c, w)
			d.draw_circle(P(o, u, 0.18, 0.4), u * 0.09, c)
			d.draw_circle(P(o, u, 0.82, 0.4), u * 0.09, c)
		"faith":
			d.draw_line(P(o, u, 0.5, 0.1), P(o, u, 0.5, 0.9), c, w)
			d.draw_line(P(o, u, 0.3, 0.32), P(o, u, 0.7, 0.32), c, w)
			d.draw_arc(P(o, u, 0.5, 0.62), u * 0.3, 0.2, PI - 0.2, 14, c, w * 0.7)
		"handshake":
			d.draw_line(P(o, u, 0.1, 0.5), P(o, u, 0.9, 0.5), c, w)
			d.draw_colored_polygon(PackedVector2Array([P(o, u, 0.1, 0.3), P(o, u, 0.1, 0.7), P(o, u, 0.4, 0.5)]), c)
			d.draw_colored_polygon(PackedVector2Array([P(o, u, 0.9, 0.3), P(o, u, 0.9, 0.7), P(o, u, 0.6, 0.5)]), c)
		"trend":
			d.draw_polyline(PackedVector2Array([P(o, u, 0.1, 0.78), P(o, u, 0.38, 0.5), P(o, u, 0.55, 0.64), P(o, u, 0.9, 0.2)]), c, w)
			d.draw_line(P(o, u, 0.9, 0.2), P(o, u, 0.72, 0.2), c, w)
			d.draw_line(P(o, u, 0.9, 0.2), P(o, u, 0.9, 0.38), c, w)
		"box":
			d.draw_rect(Rect2(P(o, u, 0.14, 0.3), Vector2(u * 0.72, u * 0.56)), c, false, w * 0.8)
			d.draw_line(P(o, u, 0.14, 0.3), P(o, u, 0.3, 0.12), c, w * 0.8)
			d.draw_line(P(o, u, 0.86, 0.3), P(o, u, 0.7, 0.12), c, w * 0.8)
			d.draw_line(P(o, u, 0.3, 0.12), P(o, u, 0.7, 0.12), c, w * 0.8)
			d.draw_line(P(o, u, 0.5, 0.3), P(o, u, 0.5, 0.52), c, w * 0.7)
		"flask":
			d.draw_line(P(o, u, 0.4, 0.12), P(o, u, 0.4, 0.4), c, w * 0.8)
			d.draw_line(P(o, u, 0.6, 0.12), P(o, u, 0.6, 0.4), c, w * 0.8)
			d.draw_line(P(o, u, 0.34, 0.12), P(o, u, 0.66, 0.12), c, w * 0.8)
			d.draw_polyline(PackedVector2Array([P(o, u, 0.4, 0.4), P(o, u, 0.14, 0.82), P(o, u, 0.86, 0.82), P(o, u, 0.6, 0.4)]), c, w * 0.8)
			d.draw_line(P(o, u, 0.26, 0.62), P(o, u, 0.74, 0.62), c, w * 0.7)
		"ship":
			d.draw_colored_polygon(PackedVector2Array([P(o, u, 0.1, 0.55), P(o, u, 0.9, 0.55), P(o, u, 0.72, 0.8), P(o, u, 0.28, 0.8)]), c)
			d.draw_line(P(o, u, 0.5, 0.55), P(o, u, 0.5, 0.15), c, w * 0.8)
			d.draw_colored_polygon(PackedVector2Array([P(o, u, 0.54, 0.18), P(o, u, 0.54, 0.48), P(o, u, 0.82, 0.48)]), c)
		"shield":
			d.draw_polyline(PackedVector2Array([P(o, u, 0.18, 0.14), P(o, u, 0.82, 0.14), P(o, u, 0.8, 0.52), P(o, u, 0.5, 0.9), P(o, u, 0.2, 0.52), P(o, u, 0.18, 0.14)]), c, w * 0.8)
			d.draw_line(P(o, u, 0.5, 0.22), P(o, u, 0.5, 0.74), c, w * 0.7)
			d.draw_line(P(o, u, 0.3, 0.42), P(o, u, 0.7, 0.42), c, w * 0.7)
		"grid":
			for i in 2:
				for j in 2:
					d.draw_rect(Rect2(P(o, u, 0.14 + 0.4 * float(i), 0.14 + 0.4 * float(j)), Vector2(u * 0.32, u * 0.32)), c)
		"flag":
			d.draw_line(P(o, u, 0.22, 0.1), P(o, u, 0.22, 0.92), c, w)
			d.draw_colored_polygon(PackedVector2Array([P(o, u, 0.22, 0.14), P(o, u, 0.84, 0.28), P(o, u, 0.22, 0.52)]), c)
		"warn":
			d.draw_polyline(PackedVector2Array([P(o, u, 0.5, 0.1), P(o, u, 0.92, 0.86), P(o, u, 0.08, 0.86), P(o, u, 0.5, 0.1)]), c, w * 0.8)
			d.draw_line(P(o, u, 0.5, 0.36), P(o, u, 0.5, 0.6), c, w)
			d.draw_circle(P(o, u, 0.5, 0.74), u * 0.05, c)
		"arrow_in":
			d.draw_line(P(o, u, 0.1, 0.5), P(o, u, 0.85, 0.5), c, w)
			d.draw_polyline(PackedVector2Array([P(o, u, 0.6, 0.25), P(o, u, 0.85, 0.5), P(o, u, 0.6, 0.75)]), c, w)
		"arrow_out":
			d.draw_line(P(o, u, 0.9, 0.5), P(o, u, 0.15, 0.5), c, w)
			d.draw_polyline(PackedVector2Array([P(o, u, 0.4, 0.25), P(o, u, 0.15, 0.5), P(o, u, 0.4, 0.75)]), c, w)
		"energy":
			d.draw_polyline(PackedVector2Array([P(o, u, 0.58, 0.08), P(o, u, 0.3, 0.55), P(o, u, 0.52, 0.55), P(o, u, 0.4, 0.92), P(o, u, 0.72, 0.4), P(o, u, 0.5, 0.4), P(o, u, 0.58, 0.08)]), c, w * 0.7)
		"tariff":
			d.draw_rect(Rect2(P(o, u, 0.12, 0.3), Vector2(u * 0.76, u * 0.44)), c, false, w * 0.8)
			d.draw_line(P(o, u, 0.3, 0.74), P(o, u, 0.7, 0.3), c, w * 0.8)
		"star":
			var pts := PackedVector2Array()
			for i in 11:
				var r: float = 0.4 if i % 2 == 0 else 0.17
				var an: float = -PI / 2.0 + float(i) * PI / 5.0
				pts.append(P(o, u, 0.5 + cos(an) * r, 0.52 + sin(an) * r))
			d.draw_colored_polygon(pts, c)
		# v49: новые значки (верхняя панель, паспорт страны, разделы)
		"calendar":
			d.draw_rect(Rect2(P(o, u, 0.14, 0.2), Vector2(u * 0.72, u * 0.66)), c, false, w * 0.8)
			d.draw_rect(Rect2(P(o, u, 0.14, 0.2), Vector2(u * 0.72, u * 0.16)), c)
			d.draw_line(P(o, u, 0.32, 0.1), P(o, u, 0.32, 0.27), c, w * 0.8)
			d.draw_line(P(o, u, 0.68, 0.1), P(o, u, 0.68, 0.27), c, w * 0.8)
			for i in 3:
				for j in 2:
					d.draw_rect(Rect2(P(o, u, 0.24 + 0.2 * float(i), 0.48 + 0.18 * float(j)), Vector2(u * 0.1, u * 0.09)), c)
		"ballot":
			d.draw_rect(Rect2(P(o, u, 0.14, 0.46), Vector2(u * 0.72, u * 0.42)), c, false, w * 0.8)
			d.draw_colored_polygon(PackedVector2Array([P(o, u, 0.34, 0.1), P(o, u, 0.66, 0.1), P(o, u, 0.66, 0.5), P(o, u, 0.34, 0.5)]), c)
			d.draw_line(P(o, u, 0.4, 0.3), P(o, u, 0.48, 0.38), Color(0.1, 0.12, 0.18), w * 0.6)
			d.draw_line(P(o, u, 0.48, 0.38), P(o, u, 0.6, 0.2), Color(0.1, 0.12, 0.18), w * 0.6)
		"percent":
			d.draw_line(P(o, u, 0.78, 0.16), P(o, u, 0.22, 0.84), c, w)
			d.draw_arc(P(o, u, 0.3, 0.28), u * 0.12, 0.0, TAU, 14, c, w * 0.8)
			d.draw_arc(P(o, u, 0.7, 0.72), u * 0.12, 0.0, TAU, 14, c, w * 0.8)
		"work":
			d.draw_rect(Rect2(P(o, u, 0.12, 0.34), Vector2(u * 0.76, u * 0.5)), c, false, w * 0.8)
			d.draw_polyline(PackedVector2Array([P(o, u, 0.36, 0.34), P(o, u, 0.36, 0.2), P(o, u, 0.64, 0.2), P(o, u, 0.64, 0.34)]), c, w * 0.8)
			d.draw_line(P(o, u, 0.12, 0.54), P(o, u, 0.88, 0.54), c, w * 0.6)
		"person":
			d.draw_circle(P(o, u, 0.5, 0.3), u * 0.16, c)
			d.draw_colored_polygon(PackedVector2Array([P(o, u, 0.2, 0.9), P(o, u, 0.26, 0.6), P(o, u, 0.5, 0.52), P(o, u, 0.74, 0.6), P(o, u, 0.8, 0.9)]), c)
		"crown":
			d.draw_colored_polygon(PackedVector2Array([P(o, u, 0.14, 0.76), P(o, u, 0.1, 0.3), P(o, u, 0.32, 0.52), P(o, u, 0.5, 0.18), P(o, u, 0.68, 0.52), P(o, u, 0.9, 0.3), P(o, u, 0.86, 0.76)]), c)
			d.draw_rect(Rect2(P(o, u, 0.14, 0.8), Vector2(u * 0.72, u * 0.08)), c)
		"map":
			d.draw_polyline(PackedVector2Array([P(o, u, 0.08, 0.22), P(o, u, 0.36, 0.12), P(o, u, 0.64, 0.22), P(o, u, 0.92, 0.12), P(o, u, 0.92, 0.78), P(o, u, 0.64, 0.88), P(o, u, 0.36, 0.78), P(o, u, 0.08, 0.88), P(o, u, 0.08, 0.22)]), c, w * 0.8)
			d.draw_line(P(o, u, 0.36, 0.12), P(o, u, 0.36, 0.78), c, w * 0.6)
			d.draw_line(P(o, u, 0.64, 0.22), P(o, u, 0.64, 0.88), c, w * 0.6)
		"gauge":
			d.draw_arc(P(o, u, 0.5, 0.62), u * 0.38, PI, TAU, 20, c, w)
			d.draw_line(P(o, u, 0.5, 0.62), P(o, u, 0.72, 0.36), c, w)
			d.draw_circle(P(o, u, 0.5, 0.62), u * 0.07, c)
		"globe":
			d.draw_arc(P(o, u, 0.5, 0.5), u * 0.38, 0.0, TAU, 24, c, w * 0.8)
			d.draw_line(P(o, u, 0.12, 0.5), P(o, u, 0.88, 0.5), c, w * 0.6)
			var eq := PackedVector2Array()
			for i in 17:
				var an2: float = -PI / 2.0 + PI * float(i) / 16.0
				eq.append(P(o, u, 0.5 + cos(an2) * 0.16, 0.5 + sin(an2) * 0.38))
			d.draw_polyline(eq, c, w * 0.6)
			var eq2 := PackedVector2Array()
			for i in 17:
				var an3: float = -PI / 2.0 + PI * float(i) / 16.0
				eq2.append(P(o, u, 0.5 - cos(an3) * 0.16, 0.5 + sin(an3) * 0.38))
			d.draw_polyline(eq2, c, w * 0.6)
		_:
			d.draw_circle(P(o, u, 0.5, 0.5), u * 0.3, c)
