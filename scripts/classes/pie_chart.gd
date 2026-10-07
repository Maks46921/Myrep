# Круговая диаграмма (v35: влияние партий в коалиции). data — массив [доля, цвет, подпись].
extends Control

var data: Array = []
var font_size := 12

func _init() -> void:
	custom_minimum_size = Vector2(0.0, 120.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_data(d: Array) -> void:
	data = d
	queue_redraw()

func _draw() -> void:
	var total := 0.0
	for it in data:
		total += maxf(0.0, float(it[0]))
	if total <= 0.0:
		return
	var r: float = minf(size.y * 0.5 - 4.0, size.x * 0.25)
	var c := Vector2(r + 6.0, size.y * 0.5)
	var a0 := -PI * 0.5
	for it in data:
		var frac: float = maxf(0.0, float(it[0])) / total
		if frac <= 0.0:
			continue
		var a1: float = a0 + frac * TAU
		var pts := PackedVector2Array([c])
		var n: int = maxi(3, int(48.0 * frac))
		for k in n + 1:
			var a: float = a0 + (a1 - a0) * float(k) / float(n)
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(pts, it[1])
		if frac < 0.999:
			draw_line(c, c + Vector2(cos(a0), sin(a0)) * r, Color(0.05, 0.06, 0.09), 1.5, true)
		a0 = a1
	var font := get_theme_default_font()
	var y: float = c.y - float(data.size()) * (font_size + 4) * 0.5 + font_size
	var x: float = c.x + r + 12.0
	for it in data:
		draw_rect(Rect2(x, y - font_size + 2, 9, 9), it[1])
		var t: String = "%s — %.0f%%" % [String(it[2]), maxf(0.0, float(it[0])) / total * 100.0]
		draw_string(font, Vector2(x + 14.0, y), t, HORIZONTAL_ALIGNMENT_LEFT, maxf(10.0, size.x - x - 16.0), font_size, Color(0.85, 0.87, 0.9))
		y += font_size + 4
