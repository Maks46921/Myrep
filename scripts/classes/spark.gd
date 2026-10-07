# Мини-график: одна или несколько линий по истории значений с подписью последнего значения.
extends Control

var series: Array = []   # [{ "v": Array[float], "c": Color, "n": String }]
var title := ""
var ymin := NAN
var ymax := NAN

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(200.0, 64.0)

func _draw() -> void:
	var f := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.07, 0.11, 0.8))
	draw_string(f, Vector2(5.0, 12.0), title, HORIZONTAL_ALIGNMENT_LEFT, size.x - 10.0, 11, Color(0.7, 0.76, 0.9))
	var lo := 1e18
	var hi := -1e18
	var n := 0
	for s in series:
		for v in s["v"]:
			lo = minf(lo, float(v))
			hi = maxf(hi, float(v))
		n = maxi(n, (s["v"] as Array).size())
	if n < 2:
		draw_string(f, Vector2(5.0, size.y - 8.0), "данных пока мало", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.4))
		return
	if not is_nan(ymin): lo = minf(lo, ymin)
	if not is_nan(ymax): hi = maxf(hi, ymax)
	if hi - lo < 0.001:
		hi = lo + 1.0
	var r := Rect2(6.0, 18.0, size.x - 12.0, size.y - 24.0)
	draw_line(Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y), Color(1, 1, 1, 0.12))
	for s in series:
		var pts := PackedVector2Array()
		var vs: Array = s["v"]
		for i in vs.size():
			pts.append(Vector2(r.position.x + r.size.x * float(i) / float(maxi(1, vs.size() - 1)), r.end.y - r.size.y * (float(vs[i]) - lo) / (hi - lo)))
		if pts.size() >= 2:
			draw_polyline(pts, s["c"], 1.8, true)
			draw_circle(pts[pts.size() - 1], 2.6, s["c"])
	var tx := size.x - 5.0
	for s in series:
		var vs2: Array = s["v"]
		var t: String = "%s %.1f" % [String(s.get("n", "")), float(vs2[vs2.size() - 1])]
		var wd: float = f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		tx -= wd + 6.0
		draw_string(f, Vector2(tx, 12.0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, s["c"])
