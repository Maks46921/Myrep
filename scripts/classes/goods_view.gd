# Список строк с расходящейся полосой: цветной квадрат, название, полоса «ниже ↔ выше», значение, подсказка по наведению.
extends Control

const ROW_H := 27.0
var rows: Array = []          # {label, col, v (в %), vt (текст значения), tip}
var span := 25.0              # ± процентов на полную полосу
var good_when_low := true     # снижение (влево) — хорошо (зелёное)
var c_good := Color(0.345, 0.784, 0.529)
var c_bad := Color(0.933, 0.420, 0.420)
var c_dim := Color(0.596, 0.631, 0.722)
var c_text := Color(0.910, 0.922, 0.957)
var c_bg := Color(0.055, 0.067, 0.098)

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

func set_rows(r: Array) -> void:
	rows = r
	custom_minimum_size = Vector2(120.0, ROW_H * float(rows.size()) + 2.0)
	queue_redraw()

func _get_tooltip(at_position: Vector2) -> String:
	var i := int(at_position.y / ROW_H)
	if i >= 0 and i < rows.size():
		return String(rows[i].get("tip", ""))
	return ""

func _draw() -> void:
	var font := get_theme_default_font()
	var lw: float = clampf(size.x * 0.40, 90.0, 190.0)
	var vw := 86.0
	var bx: float = 16.0 + lw
	var bw: float = maxf(20.0, size.x - bx - vw - 4.0)
	for i in rows.size():
		var r: Dictionary = rows[i]
		var y: float = float(i) * ROW_H
		draw_rect(Rect2(2.0, y + 9.0, 8.0, 8.0), r.get("col", c_dim))
		var txt := String(r.get("label", ""))
		var fs := 14
		while fs > 10 and font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > lw:
			fs -= 1
		draw_string(font, Vector2(16.0, y + 18.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c_text)
		var bar := Rect2(bx, y + 8.0, bw, 11.0)
		draw_rect(bar, c_bg)
		var mid: float = bx + bw * 0.5
		draw_rect(Rect2(mid - 0.5, y + 5.0, 1.0, 17.0), Color(1, 1, 1, 0.25))
		var v: float = float(r.get("v", 0.0))
		var f: float = clampf(v / span, -1.0, 1.0)
		var low_is_good := good_when_low
		var col: Color = c_dim
		if absf(v) >= 0.5:
			var good: bool = (v < 0.0) == low_is_good
			col = c_good if good else c_bad
		if f >= 0.0:
			draw_rect(Rect2(mid, y + 8.0, bw * 0.5 * f, 11.0), col)
		else:
			draw_rect(Rect2(mid + bw * 0.5 * f, y + 8.0, -bw * 0.5 * f, 11.0), col)
		var vt := String(r.get("vt", "%+.1f%%" % v))
		var w2: float = font.get_string_size(vt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(font, Vector2(size.x - w2 - 2.0, y + 18.0), vt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col if absf(v) >= 0.5 else c_dim)
