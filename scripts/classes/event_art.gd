# Иллюстрированная шапка окна события (v46_1): градиент цвета категории, лучи и узор, крупный значок,
# категория, заголовок, дата/место и метки («цепочка», «по обстановке», «повтор»).
extends Control

const Ico := preload("res://scripts/classes/ico.gd")

var col := Color(0.65, 0.54, 0.94)
var ico := "hall"
var cat := "ПОЛИТИКА"
var title := ""
var meta := ""
var badges: Array = []     # [[текст, цвет]]
var seed_v := 0


func _init() -> void:
	custom_minimum_size = Vector2(0.0, 118.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(c: Color, ic: String, ct: String, tt: String, mt: String, bd: Array, sd: int) -> void:
	col = c
	ico = ic
	cat = ct
	title = tt
	meta = mt
	badges = bd
	seed_v = sd
	queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var f: Font = get_theme_default_font()
	# фон: скруглённая плашка с тенью
	var sb := StyleBoxFlat.new()
	sb.bg_color = col.darkened(0.78)
	sb.border_color = col.darkened(0.25)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 6
	sb.anti_aliasing = true
	draw_style_box(sb, Rect2(Vector2.ZERO, size))
	# диагональный градиент цвета категории
	var a0 := Color(col.r, col.g, col.b, 0.42)
	var a1 := Color(col.r, col.g, col.b, 0.0)
	draw_polygon(PackedVector2Array([Vector2(2, 2), Vector2(w * 0.75, 2), Vector2(w * 0.45, h - 2), Vector2(2, h - 2)]),
		PackedColorArray([a0, a1, a1, Color(col.r, col.g, col.b, 0.22)]))
	# лучи из-за значка
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var c0 := Vector2(w - 70.0, h * 0.5)
	for k in 9:
		var ang: float = -PI * 0.95 + float(k) * PI * 0.22 + rng.randf_range(-0.05, 0.05)
		var p1: Vector2 = c0 + Vector2(cos(ang), sin(ang)) * 260.0
		var p2: Vector2 = c0 + Vector2(cos(ang + 0.07), sin(ang + 0.07)) * 260.0
		draw_colored_polygon(PackedVector2Array([c0, p1, p2]), Color(col.r, col.g, col.b, 0.05))
	# узор: точки-сетка справа
	for gx in 10:
		for gy in 5:
			var p := Vector2(w * 0.55 + float(gx) * 14.0, 16.0 + float(gy) * 20.0)
			if p.x < w - 8.0:
				draw_circle(p, 1.3, Color(1, 1, 1, 0.05 + 0.03 * float((gx + gy) % 3)))
	# крупный значок с ореолом
	draw_circle(c0, 46.0, Color(col.r, col.g, col.b, 0.12))
	draw_circle(c0, 34.0, Color(col.r, col.g, col.b, 0.20))
	draw_arc(c0, 46.0, 0.0, TAU, 48, Color(col.r, col.g, col.b, 0.45), 1.5, true)
	Ico.draw_icon(ico, c0 - Vector2(24.0, 24.0), 48.0, 3.4, col.lightened(0.35), self)
	# тексты
	draw_string(f, Vector2(18.0, 26.0), cat, HORIZONTAL_ALIGNMENT_LEFT, w - 160.0, 13, col.lightened(0.35))
	var tw: float = w - 170.0
	var fs := 26
	while fs > 16 and f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > tw:
		fs -= 1
	draw_string_outline(f, Vector2(18.0, 62.0), title, HORIZONTAL_ALIGNMENT_LEFT, tw, fs, 5, Color(0, 0, 0, 0.45))
	draw_string(f, Vector2(18.0, 62.0), title, HORIZONTAL_ALIGNMENT_LEFT, tw, fs, Color(0.97, 0.98, 1.0))
	draw_string(f, Vector2(18.0, 86.0), meta, HORIZONTAL_ALIGNMENT_LEFT, tw, 13, Color(0.78, 0.82, 0.92))
	# метки
	var bx := 18.0
	for b in badges:
		var txt: String = String(b[0])
		var bc: Color = b[1]
		var bw: float = f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 14.0
		var bs := StyleBoxFlat.new()
		bs.bg_color = Color(bc.r, bc.g, bc.b, 0.22)
		bs.border_color = bc
		bs.set_border_width_all(1)
		bs.set_corner_radius_all(9)
		draw_style_box(bs, Rect2(bx, 94.0, bw, 18.0))
		draw_string(f, Vector2(bx + 7.0, 107.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, bc.lightened(0.3))
		bx += bw + 6.0
