# v48_1: обзор вооружённых сил — карточки показателей (значение, подпись, полоска) и полоса состава армии по родам войск
# со значками в стиле НАТО (APP-6): пехота — крест в рамке, танки — овал, артиллерия — точка, аэромобильные — крест и дуга,
# территориальная оборона — крест и буквы «ТО». Режим rivals — горизонтальные полосы силы соседей.
extends Control

var cards: Array = []   # [подпись, значение, доля 0..1, «хорошо» 0..1, подсказка-подстрочник]
var segs: Array = []    # [тыс., цвет, род войск, подпись]
var rivals: Array = []  # [название, сила, отношения 0..100, тренд, своя страна?]
var mode := "cards"

const TP_COL := {"inf": Color(0.42, 0.62, 0.95), "arm": Color(0.93, 0.62, 0.30), "art": Color(0.90, 0.40, 0.42),
	"lgt": Color(0.40, 0.82, 0.70), "td": Color(0.66, 0.66, 0.74)}


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(240.0, 210.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_cards(c: Array, s: Array) -> void:
	mode = "cards"
	cards = c
	segs = s
	var rows: int = int(ceil(float(cards.size()) / 2.0))
	custom_minimum_size = Vector2(240.0, 8.0 + float(rows) * 58.0 + (70.0 if not segs.is_empty() else 0.0))
	queue_redraw()


func set_rivals(r: Array) -> void:
	mode = "rivals"
	rivals = r
	custom_minimum_size = Vector2(240.0, 12.0 + float(rivals.size()) * 24.0)
	queue_redraw()


static func draw_symbol(ci: CanvasItem, r: Rect2, tp: String, col: Color, line: Color = Color(1, 1, 1, 0.85)) -> void:
	ci.draw_rect(r, col)
	ci.draw_rect(r, Color(0, 0, 0, 0.8), false, 1.0)
	var p0 := r.position + Vector2(2, 2)
	var p1 := r.end - Vector2(2, 2)
	match tp:
		"arm":
			var c := r.get_center()
			var pts := PackedVector2Array()
			for k in 25:
				var a: float = TAU * float(k) / 24.0
				pts.append(c + Vector2(cos(a) * r.size.x * 0.32, sin(a) * r.size.y * 0.26))
			ci.draw_polyline(pts, line, 1.2, true)
		"art":
			ci.draw_circle(r.get_center(), minf(r.size.x, r.size.y) * 0.17, line)
		"lgt":
			ci.draw_line(p0, p1, line, 1.0, true)
			ci.draw_line(Vector2(p0.x, p1.y), Vector2(p1.x, p0.y), line, 1.0, true)
			ci.draw_arc(Vector2(r.get_center().x, r.end.y - 1.0), r.size.x * 0.22, PI, TAU, 10, line, 1.0, true)
		"td":
			ci.draw_line(p0, p1, Color(line.r, line.g, line.b, 0.45), 1.0, true)
			ci.draw_line(Vector2(p0.x, p1.y), Vector2(p1.x, p0.y), Color(line.r, line.g, line.b, 0.45), 1.0, true)
			ci.draw_rect(Rect2(r.position + Vector2(r.size.x * 0.3, r.size.y * 0.3), r.size * 0.4), line, false, 1.0)
		_:
			ci.draw_line(p0, p1, line, 1.0, true)
			ci.draw_line(Vector2(p0.x, p1.y), Vector2(p1.x, p0.y), line, 1.0, true)


func _bar(r: Rect2, v: float, good: float) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.06, 0.09)
	bg.set_corner_radius_all(3)
	draw_style_box(bg, r)
	var col: Color = Color(0.93, 0.42, 0.42).lerp(Color(0.94, 0.71, 0.29), clampf(good / 0.45, 0.0, 1.0)) if good < 0.45 else Color(0.94, 0.71, 0.29).lerp(Color(0.35, 0.78, 0.53), clampf((good - 0.45) / 0.35, 0.0, 1.0))
	var fb := StyleBoxFlat.new()
	fb.bg_color = col
	fb.set_corner_radius_all(3)
	var w: float = r.size.x * clampf(v, 0.0, 1.0)
	if w > 1.0:
		draw_style_box(fb, Rect2(r.position, Vector2(maxf(w, 6.0), r.size.y)))


func _draw() -> void:
	var f: Font = get_theme_default_font()
	if mode == "rivals":
		_draw_rivals(f)
		return
	var cw: float = (size.x - 6.0) / 2.0
	for i in cards.size():
		var c: Array = cards[i]
		var x: float = float(i % 2) * (cw + 6.0)
		var y: float = 4.0 + float(i / 2) * 58.0
		var r := Rect2(x, y, cw, 52.0)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.07, 0.09, 0.14, 0.9)
		sb.border_color = Color(1, 1, 1, 0.07)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(6)
		draw_style_box(sb, r)
		draw_string(f, Vector2(x + 8.0, y + 15.0), String(c[0]), HORIZONTAL_ALIGNMENT_LEFT, cw - 16.0, 11, Color(0.66, 0.72, 0.84))
		var fs := 17
		while fs > 11 and f.get_string_size(String(c[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > cw - 16.0:
			fs -= 1
		draw_string(f, Vector2(x + 8.0, y + 35.0), String(c[1]), HORIZONTAL_ALIGNMENT_LEFT, cw - 16.0, fs, Color(0.96, 0.97, 1.0))
		if c.size() > 4 and String(c[4]) != "":
			var lw0: float = f.get_string_size(String(c[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
			var sw: float = f.get_string_size(String(c[4]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			if sw <= cw - 26.0 - lw0:
				draw_string(f, Vector2(x + 14.0 + lw0, y + 15.0), String(c[4]), HORIZONTAL_ALIGNMENT_RIGHT, cw - 22.0 - lw0, 10, Color(0.56, 0.62, 0.74))
		_bar(Rect2(x + 8.0, y + 41.0, cw - 16.0, 5.0), float(c[2]), float(c[3]))
	if segs.is_empty():
		return
	var y0: float = 8.0 + ceil(float(cards.size()) / 2.0) * 58.0
	draw_string(f, Vector2(2.0, y0 + 10.0), "Состав по родам войск, тыс. человек", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.66, 0.72, 0.84))
	var tot := 0.0
	for sg in segs:
		tot += maxf(0.0, float(sg[0]))
	var bx := 2.0
	var bw: float = size.x - 4.0
	var by: float = y0 + 16.0
	if tot > 0.0:
		for sg in segs:
			var w: float = bw * maxf(0.0, float(sg[0])) / tot
			if w < 0.5:
				continue
			draw_rect(Rect2(bx, by, w, 14.0), sg[1] as Color)
			bx += w
	draw_rect(Rect2(2.0, by, bw, 14.0), Color(0, 0, 0, 0.6), false, 1.0)
	# легенда со значками
	var lx := 2.0
	var ly: float = by + 22.0
	for sg in segs:
		if float(sg[0]) <= 0.0:
			continue
		var txt := "%s %.0f" % [String(sg[3]), float(sg[0])]
		var tw: float = f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		if lx + 26.0 + tw > size.x:
			lx = 2.0
			ly += 18.0
		draw_symbol(self, Rect2(lx, ly, 20.0, 13.0), String(sg[2]), (sg[1] as Color).darkened(0.2))
		draw_string(f, Vector2(lx + 24.0, ly + 11.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.86, 0.9, 0.98))
		lx += 32.0 + tw


func _draw_rivals(f: Font) -> void:
	var mx := 1.0
	for r in rivals:
		mx = maxf(mx, float(r[1]))
	var lw := 116.0
	for i in rivals.size():
		var r: Array = rivals[i]
		var y: float = 6.0 + float(i) * 24.0
		var me: bool = r.size() > 4 and bool(r[4])
		draw_string(f, Vector2(2.0, y + 13.0), String(r[0]), HORIZONTAL_ALIGNMENT_LEFT, lw - 6.0, 11, Color(1.0, 0.92, 0.5) if me else Color(0.86, 0.9, 0.98))
		var rel: float = float(r[2])
		var col: Color = Color(0.93, 0.42, 0.42).lerp(Color(0.94, 0.78, 0.35), clampf(rel / 50.0, 0.0, 1.0)) if rel < 50.0 else Color(0.94, 0.78, 0.35).lerp(Color(0.35, 0.78, 0.53), clampf((rel - 50.0) / 30.0, 0.0, 1.0))
		if me:
			col = Color(0.45, 0.66, 1.0)
		var bw: float = (size.x - lw - 58.0) * float(r[1]) / mx
		draw_rect(Rect2(lw, y + 3.0, maxf(2.0, bw), 13.0), col.darkened(0.15))
		draw_rect(Rect2(lw, y + 3.0, maxf(2.0, bw), 4.0), Color(1, 1, 1, 0.12))
		var tr: float = float(r[3])
		var tt := "%.0f" % float(r[1])
		if tr > 0.02:
			tt += " ▲"
		elif tr < -0.02:
			tt += " ▼"
		draw_string(f, Vector2(lw + bw + 5.0, y + 14.0), tt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.6, 0.5) if tr > 0.02 else Color(0.8, 0.84, 0.92))
