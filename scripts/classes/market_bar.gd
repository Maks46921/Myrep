extends Control

var title := ""
var col := Color(0.5, 0.7, 1.0)
var data := {}

func _init() -> void:
	custom_minimum_size = Vector2(60.0, 50.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS

func set_data(d: Dictionary) -> void:
	data = d
	queue_redraw()

func _draw() -> void:
	var f: Font = get_theme_default_font()
	var w: float = size.x
	if data.is_empty():
		return
	var u: float = float(data["u"])
	var short: float = float(data["short"])
	var ucol := Color(0.345, 0.784, 0.529)
	if short > 0.001:
		ucol = Color(0.933, 0.420, 0.420)
	elif u > 0.97:
		ucol = Color(0.941, 0.714, 0.290)
	elif u < 0.70:
		ucol = Color(0.55, 0.60, 0.72)
	draw_circle(Vector2(5.0, 9.0), 4.0, col)
	draw_string(f, Vector2(14.0, 14.0), title, HORIZONTAL_ALIGNMENT_LEFT, w * 0.58, 14, Color(0.90, 0.92, 0.97))
	var ut := "загрузка %.0f%%" % (u * 100.0)
	if short > 0.001:
		ut = "ДЕФИЦИТ %.1f%%" % (short * 100.0)
	draw_string(f, Vector2(0.0, 14.0), ut, HORIZONTAL_ALIGNMENT_RIGHT, w, 14, ucol)
	var k: float = float(data["K"])
	var dd: float = float(data["Dd"])
	var mx: float = maxf(k, dd) * 1.08
	var by := 21.0
	var bh := 9.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.055, 0.067, 0.098)
	bg.set_corner_radius_all(4)
	draw_style_box(bg, Rect2(0.0, by, w, bh))
	var kw: float = w * k / mx
	var kb := StyleBoxFlat.new()
	kb.bg_color = Color(0.20, 0.24, 0.34)
	kb.set_corner_radius_all(4)
	draw_style_box(kb, Rect2(0.0, by, kw, bh))
	var fw: float = w * minf(dd, k) / mx
	var fb := StyleBoxFlat.new()
	fb.bg_color = col.darkened(0.1)
	fb.set_corner_radius_all(4)
	if fw > 1.0:
		draw_style_box(fb, Rect2(0.0, by, maxf(fw, bh), bh))
	if dd > k:
		var ob := StyleBoxFlat.new()
		ob.bg_color = Color(0.933, 0.420, 0.420)
		ob.set_corner_radius_all(3)
		draw_style_box(ob, Rect2(kw, by, w * (dd - k) / mx, bh))
	draw_line(Vector2(kw, by - 2.0), Vector2(kw, by + bh + 2.0), Color(1, 1, 1, 0.7), 1.5)
	var pdelta: float = (float(data["p"]) - 1.0) * 100.0
	var txt := "спрос %.2f · мощность %.2f · цена %s%% · прибыль %.0f%%" % [dd, k, ("+%.0f" % pdelta) if pdelta >= 0.0 else ("%.0f" % pdelta), float(data["margin"]) * 100.0]
	draw_string(f, Vector2(0.0, 44.0), txt, HORIZONTAL_ALIGNMENT_LEFT, w, 12, Color(0.60, 0.65, 0.78))
