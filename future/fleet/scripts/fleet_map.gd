extends Control
# Схема морских путей: узлы, лини трафика, порты своей страны. Данные задаёт ui_fleet.gd.
var edges: Array = []      # [a:Vector2, b:Vector2, доля трафика, блок]
var nodes: Array = []      # [Vector2, имя, блок]
var ports: Array = []      # [Vector2, имя, загрузка, строится]
var font: Font = null

func _init() -> void:
	custom_minimum_size = Vector2(0.0, 300.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_data(e: Array, n: Array, p: Array) -> void:
	edges = e
	nodes = n
	ports = p
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.09, 0.15, 1.0))
	if font == null:
		font = ThemeDB.fallback_font
	var pts: Array = []
	for e0 in edges:
		pts.append(e0[0])
		pts.append(e0[1])
	for p in ports:
		pts.append(p[0])
	if pts.is_empty():
		return
	var lo: Vector2 = pts[0]
	var hi: Vector2 = pts[0]
	for v in pts:
		lo = Vector2(minf(lo.x, v.x), minf(lo.y, v.y))
		hi = Vector2(maxf(hi.x, v.x), maxf(hi.y, v.y))
	var span: Vector2 = (hi - lo).max(Vector2(1.0, 1.0))
	var m := 26.0
	var sc: float = minf((size.x - 2.0 * m) / span.x, (size.y - 2.0 * m) / span.y)
	var off: Vector2 = Vector2(m, m) + ((size - Vector2(2.0 * m, 2.0 * m)) - span * sc) * 0.5
	for e in edges:
		var a: Vector2 = ((e[0] as Vector2) - lo) * sc + off
		var b: Vector2 = ((e[1] as Vector2) - lo) * sc + off
		var col := Color(0.35, 0.75, 0.95, 0.75)
		if float(e[3]) > 0.0:
			col = Color(0.95, 0.32, 0.28, 0.9)
		draw_line(a, b, col, 1.0 + 4.0 * float(e[2]))
	for n in nodes:
		var q: Vector2 = ((n[0] as Vector2) - lo) * sc + off
		draw_circle(q, 3.5, Color(0.95, 0.35, 0.3) if bool(n[2]) else Color(0.7, 0.85, 1.0))
		if bool(n[2]):
			draw_string(font, q + Vector2(5.0, -4.0), String(n[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.75, 0.82, 0.92, 0.8))
	var pi := 0
	for p in ports:
		pi += 1
		var q2: Vector2 = ((p[0] as Vector2) - lo) * sc + off
		var u: float = float(p[2])
		var c := Color(0.4, 0.85, 0.5) if u < 0.8 else (Color(0.95, 0.8, 0.3) if u < 1.0 else Color(0.95, 0.35, 0.3))
		draw_rect(Rect2(q2 - Vector2(5.0, 5.0), Vector2(10.0, 10.0)), c)
		if bool(p[3]):
			draw_rect(Rect2(q2 - Vector2(7.0, 7.0), Vector2(14.0, 14.0)), Color(1, 1, 1, 0.9), false, 1.5)
		if pi <= 3:
			draw_string(font, q2 + Vector2(8.0, 4.0), String(p[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.95))
