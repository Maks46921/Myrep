extends Control

var vals: Array = []
var title := ""
var col := Color(0.5, 0.7, 1.0)
var base_ref := -1.0

func _init() -> void:
	custom_minimum_size = Vector2(80.0, 150.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_series(t: String, v: Array, c: Color, ref: float = -1.0) -> void:
	title = t
	vals = v
	col = c
	base_ref = ref
	queue_redraw()

func _draw() -> void:
	var f: Font = get_theme_default_font()
	var w: float = size.x
	var h: float = size.y
	var pad_l := 40.0
	var pad_b := 16.0
	var pad_t := 6.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.050, 0.062, 0.094)
	bg.border_color = Color(1, 1, 1, 0.05)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(7)
	draw_style_box(bg, Rect2(Vector2.ZERO, size))
	if vals.size() < 2:
		draw_string(f, Vector2(10.0, h * 0.5), "Данные появятся после первых месяцев.", HORIZONTAL_ALIGNMENT_LEFT, w - 20.0, 13, Color(0.6, 0.65, 0.78))
		return
	var lo: float = vals[0]
	var hi: float = vals[0]
	for v in vals:
		lo = minf(lo, float(v))
		hi = maxf(hi, float(v))
	if base_ref >= 0.0:
		lo = minf(lo, base_ref)
		hi = maxf(hi, base_ref)
	var span: float = maxf(hi - lo, 0.5)
	lo -= span * 0.1
	hi += span * 0.1
	span = hi - lo
	var pw: float = w - pad_l - 8.0
	var ph: float = h - pad_b - pad_t
	for g in 5:
		var y: float = pad_t + ph * float(g) / 4.0
		draw_line(Vector2(pad_l, y), Vector2(w - 8.0, y), Color(1, 1, 1, 0.07), 1.0)
		var gv: float = hi - span * float(g) / 4.0
		draw_string(f, Vector2(2.0, y + 4.0), "%.1f" % gv, HORIZONTAL_ALIGNMENT_RIGHT, pad_l - 6.0, 11, Color(0.6, 0.65, 0.78))
	if base_ref >= 0.0:
		var yr: float = pad_t + ph * (hi - base_ref) / span
		draw_line(Vector2(pad_l, yr), Vector2(w - 8.0, yr), Color(1, 1, 1, 0.30), 1.0)
	var n: int = vals.size()
	var pts := PackedVector2Array()
	for i in n:
		pts.append(Vector2(pad_l + pw * float(i) / float(n - 1), pad_t + ph * (hi - float(vals[i])) / span))
	var poly := pts.duplicate()
	var by: float = pad_t + ph
	poly.append(Vector2(pts[n - 1].x, by))
	poly.append(Vector2(pts[0].x, by))
	var cols := PackedColorArray()
	for k in n:
		var tt: float = clampf((by - pts[k].y) / maxf(1.0, ph), 0.0, 1.0)
		cols.append(Color(col.r, col.g, col.b, 0.06 + 0.22 * tt))
	cols.append(Color(col.r, col.g, col.b, 0.0))
	cols.append(Color(col.r, col.g, col.b, 0.0))
	if Geometry2D.triangulate_polygon(poly).size() > 0:
		draw_polygon(poly, cols)
	draw_polyline(pts, Color(col.r, col.g, col.b, 0.25), 5.0, true)
	draw_polyline(pts, col, 2.0, true)
	var last: Vector2 = pts[n - 1]
	draw_circle(last, 7.0, Color(col.r, col.g, col.b, 0.22))
	draw_circle(last, 3.5, col)
	draw_string(f, Vector2(pad_l, h - 3.0), "%d мес. назад" % (n - 1), HORIZONTAL_ALIGNMENT_LEFT, 120.0, 11, Color(0.6, 0.65, 0.78))
	draw_string(f, Vector2(w - 128.0, h - 3.0), "сейчас: %.1f" % float(vals[n - 1]), HORIZONTAL_ALIGNMENT_RIGHT, 120.0, 11, col.lightened(0.2))


# ============================================================
#  СОСТОЯНИЕ ИГРЫ
# ============================================================
