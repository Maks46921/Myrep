# Столбцы религиозного состава: строка = подпись + разноцветная полоса из 7 долей (+ метка напряжённости).
extends Control

const Ico := preload("res://scripts/classes/ico.gd")

const FCOL := [Color("#e0b050"), Color("#6fa8dc"), Color("#c27ba0"), Color("#58c887"), Color("#8fb4ff"), Color("#e08a5a"), Color("#9aa4b8")]
const FKIND := ["cath", "prot", "orth", "musl", "jew", "east", "none"]
var rows: Array = []     # [подпись, Array(7) доли, напряжённость 0..100 или -1, Array(7) стартовые доли или null]
var label_w := 112.0
var row_h := 20.0
var legend := true

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

func set_rows(r: Array, lg: bool = true) -> void:
	rows = r
	legend = lg
	custom_minimum_size = Vector2(240.0, (22.0 if lg else 0.0) + row_h * float(r.size()) + 4.0)
	queue_redraw()

func _draw() -> void:
	var f := ThemeDB.fallback_font
	var y := 2.0
	if legend:
		var x := 0.0
		for k in 7:
			Ico.draw_icon(FKIND[k], Vector2(x, y), 13.0, 1.4, FCOL[k], self)
			x += 17.0
		y += 22.0
	var bw: float = size.x - label_w - 40.0
	for r in rows:
		draw_string(f, Vector2(0.0, y + row_h - 6.0), String(r[0]), HORIZONTAL_ALIGNMENT_LEFT, label_w - 4.0, 12, Color(0.85, 0.88, 0.95))
		var x0: float = label_w
		var x: float = x0
		var v: Array = r[1]
		for k in 7:
			var w: float = bw * float(v[k])
			if w > 0.4:
				draw_rect(Rect2(x, y + 3.0, w, row_h - 8.0), FCOL[k])
			x += w
		if r.size() > 3 and r[3] != null:
			var xs: float = x0
			for k in 7:
				xs += bw * float((r[3] as Array)[k])
				draw_line(Vector2(xs, y + 1.0), Vector2(xs, y + row_h - 3.0), Color(1, 1, 1, 0.5), 1.0)
		var t: float = float(r[2]) if r.size() > 2 else -1.0
		if t >= 0.0:
			var tc := Color(0.4, 0.8, 0.5) if t < 25.0 else (Color(0.95, 0.75, 0.3) if t < 55.0 else Color(0.95, 0.35, 0.3))
			draw_circle(Vector2(x0 + bw + 14.0, y + row_h * 0.5), 5.0, tc)
			draw_string(f, Vector2(x0 + bw + 22.0, y + row_h - 6.0), "%.0f" % t, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.6))
		y += row_h
