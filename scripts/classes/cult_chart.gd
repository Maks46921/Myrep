# v55_1: столбцы народов: строка = подпись + полоса из долей народов (цвета народов) + метка напряжённости.
# Легенда — крупнейшие народы страны.
extends Control

var rows: Array = []     # [подпись, Array [[доля, Color], ...], напряжённость 0..100 или -1]
var legend: Array = []   # [[название, Color], ...]
var label_w := 112.0
var row_h := 20.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL


func set_rows(r: Array, lg: Array = []) -> void:
	rows = r
	legend = lg
	var lh := 0.0
	if not lg.is_empty():
		lh = 18.0 * ceilf(float(lg.size()) / 3.0) + 4.0
	custom_minimum_size = Vector2(240.0, lh + row_h * float(r.size()) + 4.0)
	queue_redraw()


func _draw() -> void:
	var f := ThemeDB.fallback_font
	var y := 2.0
	if not legend.is_empty():
		var cw: float = size.x / 3.0
		for k in legend.size():
			var x: float = cw * float(k % 3)
			var yy: float = y + 18.0 * float(k / 3)
			draw_rect(Rect2(x, yy + 3.0, 11.0, 11.0), legend[k][1])
			draw_string(f, Vector2(x + 15.0, yy + 13.0), String(legend[k][0]), HORIZONTAL_ALIGNMENT_LEFT, cw - 18.0, 11, Color(0.82, 0.85, 0.92))
		y += 18.0 * ceilf(float(legend.size()) / 3.0) + 4.0
	var bw: float = size.x - label_w - 40.0
	for r in rows:
		draw_string(f, Vector2(0.0, y + row_h - 6.0), String(r[0]), HORIZONTAL_ALIGNMENT_LEFT, label_w - 4.0, 12, Color(0.85, 0.88, 0.95))
		var x: float = label_w
		for seg in r[1]:
			var w: float = bw * float(seg[0])
			if w > 0.4:
				draw_rect(Rect2(x, y + 3.0, w, row_h - 8.0), seg[1])
			x += w
		var t: float = float(r[2]) if r.size() > 2 else -1.0
		if t >= 0.0:
			var tc := Color(0.4, 0.8, 0.5) if t < 20.0 else (Color(0.95, 0.75, 0.3) if t < 45.0 else Color(0.95, 0.35, 0.3))
			draw_circle(Vector2(label_w + bw + 14.0, y + row_h * 0.5), 5.0, tc)
			draw_string(f, Vector2(label_w + bw + 22.0, y + row_h - 6.0), "%.0f" % t, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.6))
		y += row_h
