extends Control

var value := 0.0
var good := 0.5
var marker := -1.0
var c_bad := Color(0.933, 0.420, 0.420)
var c_warn := Color(0.941, 0.714, 0.290)
var c_good := Color(0.345, 0.784, 0.529)
var c_bg := Color(0.055, 0.067, 0.098)

func _init() -> void:
	custom_minimum_size = Vector2(40.0, 12.0)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_state(v: float, g: float) -> void:
	value = clampf(v, 0.0, 100.0)
	good = clampf(g, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	var h: float = size.y
	var rad: int = int(h / 2.0)
	var bg := StyleBoxFlat.new()
	bg.bg_color = c_bg
	bg.set_corner_radius_all(rad)
	draw_style_box(bg, Rect2(Vector2.ZERO, size))
	var w: float = size.x * value / 100.0
	if w > 0.5:
		var col: Color = c_bad.lerp(c_warn, good / 0.38) if good < 0.38 else c_warn.lerp(c_good, clampf((good - 0.38) / 0.37, 0.0, 1.0))
		var fb := StyleBoxFlat.new()
		fb.bg_color = col
		fb.set_corner_radius_all(rad)
		draw_style_box(fb, Rect2(0.0, 0.0, maxf(w, h), h))
	if marker >= 0.0:
		var mx: float = size.x * marker / 100.0
		draw_line(Vector2(mx, -1.0), Vector2(mx, h + 1.0), Color(1, 1, 1, 0.55), 1.5)
