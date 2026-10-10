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
	bg.border_color = Color(0, 0, 0, 0.35)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(rad)
	draw_style_box(bg, Rect2(Vector2.ZERO, size))
	var w: float = size.x * value / 100.0
	if w > 0.5:
		var col: Color = c_bad.lerp(c_warn, good / 0.38) if good < 0.38 else c_warn.lerp(c_good, clampf((good - 0.38) / 0.37, 0.0, 1.0))
		var fb := StyleBoxFlat.new()
		fb.bg_color = col.darkened(0.12)
		fb.set_corner_radius_all(rad)
		fb.shadow_color = Color(col.r, col.g, col.b, 0.25)
		fb.shadow_size = 3
		draw_style_box(fb, Rect2(0.0, 0.0, maxf(w, h), h))
		# v45_1: блик сверху и светлый торец
		var hl := StyleBoxFlat.new()
		hl.bg_color = Color(1, 1, 1, 0.16)
		hl.set_corner_radius_all(rad)
		draw_style_box(hl, Rect2(1.0, 1.0, maxf(w, h) - 2.0, h * 0.45))
		draw_circle(Vector2(maxf(w, h) - h * 0.5, h * 0.5), h * 0.32, col.lightened(0.35))
	if marker >= 0.0:
		var mx: float = size.x * marker / 100.0
		draw_line(Vector2(mx, -1.0), Vector2(mx, h + 1.0), Color(1, 1, 1, 0.55), 1.5)
