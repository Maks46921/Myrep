# 0.62: семь квадратиков дней недели (Пн–Вс) для плашки «ДАТА»: прошедшие дни закрашены, текущий подсвечен, выходные с другим цветом.
extends Control

var cur := 0                                   # 0 — понедельник … 6 — воскресенье
var letters: PackedStringArray = ["·", "·", "·", "·", "·", "·", "·"]     # подписи задаёт ui_core (первые буквы названий дней)
var col_on := Color(0.36, 0.55, 0.94)
var col_past := Color(0.22, 0.28, 0.42)
var col_off := Color(0.12, 0.14, 0.2)
var col_text := Color(0.9, 0.92, 0.97)
var col_wk := Color(0.94, 0.71, 0.29)

const CELL_W := 9.0
const CELL_H := 10.0
const GAP := 1.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(7.0 * CELL_W + 6.0 * GAP, CELL_H)


func set_day(wd: int) -> void:
	if wd != cur:
		cur = wd
		queue_redraw()


func _draw() -> void:
	var f := ThemeDB.fallback_font
	for i in 7:
		var r := Rect2(float(i) * (CELL_W + GAP), 0.0, CELL_W, CELL_H)
		var c: Color = col_off
		if i < cur:
			c = col_past
		elif i == cur:
			c = col_on
		draw_rect(r, c, true)
		var tc: Color = col_text if i <= cur else Color(col_text.r, col_text.g, col_text.b, 0.45)
		if i > 4 and i != cur:
			tc = Color(col_wk.r, col_wk.g, col_wk.b, 1.0 if i < cur else 0.6)
		draw_string(f, Vector2(r.position.x + 1.5, r.position.y + 8.5), letters[i], HORIZONTAL_ALIGNMENT_LEFT, CELL_W, 8, tc)
