# Диаграмма взаимной зависимости: слева — наша зависимость от партнёра, справа — его от нас; точка — влияние.
extends Control

const Ico := preload("res://scripts/classes/ico.gd")

signal picked(cc: String)
var rows: Array = []    # [cc, имя, out, in, leverage, relations, tariff, ret, selected]
var vmax := 10.0
const RH := 24.0
const NW := 118.0

func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_rows(r: Array) -> void:
	rows = r
	vmax = 6.0
	for x in r:
		vmax = maxf(vmax, maxf(float(x[2]), float(x[3])))
	custom_minimum_size = Vector2(300.0, 22.0 + RH * float(r.size()) + 4.0)
	queue_redraw()

func _draw() -> void:
	var f := ThemeDB.fallback_font
	var mid: float = NW + (size.x - NW - 44.0) * 0.5
	var half: float = (size.x - NW - 44.0) * 0.5 - 4.0
	draw_string(f, Vector2(NW, 12.0), "◀ мы зависим", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.95, 0.5, 0.45))
	var t2 := "зависят от нас ▶"
	draw_string(f, Vector2(mid + half - f.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x, 12.0), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.45, 0.85, 0.55))
	var y := 20.0
	for r in rows:
		if bool(r[8]):
			draw_rect(Rect2(0.0, y, size.x, RH - 2.0), Color(0.36, 0.55, 0.94, 0.22))
		draw_string(f, Vector2(4.0, y + 16.0), String(r[1]), HORIZONTAL_ALIGNMENT_LEFT, NW - 8.0, 12, Color(0.88, 0.9, 0.96))
		var wo: float = half * clampf(float(r[2]) / vmax, 0.0, 1.0)
		var wi: float = half * clampf(float(r[3]) / vmax, 0.0, 1.0)
		draw_rect(Rect2(mid - wo, y + 4.0, wo, RH - 10.0), Color(0.92, 0.42, 0.38))
		draw_rect(Rect2(mid, y + 4.0, wi, RH - 10.0), Color(0.36, 0.78, 0.5))
		draw_line(Vector2(mid, y + 1.0), Vector2(mid, y + RH - 3.0), Color(1, 1, 1, 0.35))
		var lv: float = float(r[4])
		var lc := Color(0.4, 0.8, 0.5) if lv > 55.0 else (Color(0.95, 0.4, 0.35) if lv < 45.0 else Color(0.8, 0.82, 0.88))
		var cx: float = size.x - 22.0
		draw_circle(Vector2(cx, y + RH * 0.5 - 1.0), 8.0, lc.darkened(0.45))
		draw_string(f, Vector2(cx - 9.0, y + RH * 0.5 + 3.0), "%.0f" % lv, HORIZONTAL_ALIGNMENT_CENTER, 18.0, 10, Color(1, 1, 1))
		if int(r[6]) > 0 or int(r[7]) > 0:
			Ico.draw_icon("tariff", Vector2(NW - 20.0, y + 4.0), 14.0, 1.4, Color(0.95, 0.75, 0.3), self)
		y += RH

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var i: int = int((e.position.y - 20.0) / RH)
		if i >= 0 and i < rows.size():
			picked.emit(String(rows[i][0]))
