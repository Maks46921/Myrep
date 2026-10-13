# Графические помощники (v45_1): процедурные текстуры рельефа и моря, градиенты, виньетка, маркеры, панели подписей.
# Всё рисуется средствами CanvasItem, без внешних картинок; текстуры создаются один раз и кешируются.
extends RefCounted

const TEX_N := 256
const LAND_UV := 150.0     # одна плитка текстуры рельефа на столько единиц карты
const SEA_UV := 260.0

static var _land: ImageTexture = null
static var _sea: ImageTexture = null
static var _ctx: ImageTexture = null
# v50: стиль моря на карте (настройки): 0 — ночное, 1 — атлас, 2 — графит
static var sea_style := 0
const SEA_STYLES := [[Color(0.030, 0.058, 0.105), Color(0.058, 0.110, 0.180)], [Color(0.060, 0.150, 0.235), Color(0.110, 0.255, 0.345)],
	[Color(0.070, 0.078, 0.086), Color(0.120, 0.132, 0.142)]]


static func set_sea_style(k: int) -> void:
	k = clampi(k, 0, SEA_STYLES.size() - 1)
	if k != sea_style:
		sea_style = k
		_sea = null


static func _noise_img(seed: int, freq: float, oct: int) -> Image:
	var n := FastNoiseLite.new()
	n.seed = seed
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	n.fractal_octaves = oct
	n.frequency = freq
	return n.get_seamless_image(TEX_N, TEX_N, false, false, 0.15, true)


static func _lum(img: Image) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(TEX_N * TEX_N)
	for y in TEX_N:
		for x in TEX_N:
			out[y * TEX_N + x] = img.get_pixel(x, y).r
	return out


# рельеф: тиснение (светотень с северо-запада) по шуму + мелкая зернистость; значения 0.78…1.0 (умножаются на цвет региона)
static func land_tex() -> ImageTexture:
	if _land != null:
		return _land
	var h := _lum(_noise_img(17, 0.014, 4))
	var g := _lum(_noise_img(5, 0.05, 2))
	var img := Image.create(TEX_N, TEX_N, false, Image.FORMAT_RGBA8)
	for y in TEX_N:
		for x in TEX_N:
			var x0 := (x + TEX_N - 1) % TEX_N
			var y0 := (y + TEX_N - 1) % TEX_N
			var x1 := (x + 1) % TEX_N
			var y1 := (y + 1) % TEX_N
			var slope: float = h[y1 * TEX_N + x1] - h[y0 * TEX_N + x0]
			var v: float = 0.93 - slope * 1.7 + (h[y * TEX_N + x] - 0.5) * 0.06 + (g[y * TEX_N + x] - 0.5) * 0.02
			v = clampf(v, 0.82, 1.0)
			img.set_pixel(x, y, Color(v, v, v * 0.985, 1.0))
	_land = ImageTexture.create_from_image(img)
	return _land


# море: глубина (крупные пятна) и рябь; хранит готовые цвета воды
static func sea_tex() -> ImageTexture:
	if _sea != null:
		return _sea
	var d := _lum(_noise_img(31, 0.012, 4))
	var r := _lum(_noise_img(77, 0.06, 3))
	var img := Image.create(TEX_N, TEX_N, false, Image.FORMAT_RGBA8)
	var deep: Color = SEA_STYLES[sea_style][0]
	var shal: Color = SEA_STYLES[sea_style][1]
	for y in TEX_N:
		for x in TEX_N:
			var t: float = clampf(d[y * TEX_N + x] * 1.1 - 0.05, 0.0, 1.0)
			var c: Color = deep.lerp(shal, t)
			var rip: float = (r[y * TEX_N + x] - 0.5) * 0.035
			img.set_pixel(x, y, Color(c.r + rip * 0.5, c.g + rip * 0.8, c.b + rip, 1.0))
	_sea = ImageTexture.create_from_image(img)
	return _sea


# чужие (неигровые) земли: приглушённый рельеф
static func ctx_tex() -> ImageTexture:
	if _ctx != null:
		return _ctx
	var h := _lum(_noise_img(23, 0.02, 4))
	var img := Image.create(TEX_N, TEX_N, false, Image.FORMAT_RGBA8)
	for y in TEX_N:
		for x in TEX_N:
			var x1 := (x + 1) % TEX_N
			var y1 := (y + 1) % TEX_N
			var x0 := (x + TEX_N - 1) % TEX_N
			var y0 := (y + TEX_N - 1) % TEX_N
			var v: float = clampf(0.93 - (h[y1 * TEX_N + x1] - h[y0 * TEX_N + x0]) * 2.0, 0.8, 1.0)
			img.set_pixel(x, y, Color(v, v, v, 1.0))
	_ctx = ImageTexture.create_from_image(img)
	return _ctx


static func uvs(pts: PackedVector2Array, k: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(pts.size())
	for i in pts.size():
		out[i] = pts[i] / k
	return out


# вертикальный градиент прямоугольника
static func vgrad(c: CanvasItem, r: Rect2, top: Color, bot: Color) -> void:
	c.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([top, top, bot, bot]))


static func hgrad(c: CanvasItem, r: Rect2, left: Color, right: Color) -> void:
	c.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([left, right, right, left]))


# затемнение краёв области
static func vignette(c: CanvasItem, sz: Vector2, a: float, w: float = 140.0) -> void:
	var z := Color(0, 0, 0, 0)
	var k := Color(0.0, 0.01, 0.03, a)
	hgrad(c, Rect2(0.0, 0.0, w, sz.y), k, z)
	hgrad(c, Rect2(sz.x - w, 0.0, w, sz.y), z, k)
	vgrad(c, Rect2(0.0, 0.0, sz.x, w * 0.7), k, z)
	vgrad(c, Rect2(0.0, sz.y - w * 0.7, sz.x, w * 0.7), z, k)


# пятиконечная звезда (столица своей страны)
static func star(c: CanvasItem, p: Vector2, r: float, col: Color, edge: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var ang: float = -PI * 0.5 + float(i) * PI / 5.0
		var rr: float = r if i % 2 == 0 else r * 0.45
		pts.append(p + Vector2(cos(ang), sin(ang)) * rr)
	c.draw_colored_polygon(pts, col)
	var cl := pts.duplicate()
	cl.append(pts[0])
	c.draw_polyline(cl, edge, 1.2, true)


# маркер столицы: тень, кольцо, точка
static func capital(c: CanvasItem, p: Vector2, col: Color, big: bool) -> void:
	var r: float = 4.6 if big else 3.6
	c.draw_circle(p + Vector2(0.6, 1.0), r + 1.6, Color(0, 0, 0, 0.45))
	c.draw_circle(p, r + 1.2, Color(0.04, 0.05, 0.08, 0.95))
	c.draw_circle(p, r, col)
	c.draw_circle(p + Vector2(-r * 0.3, -r * 0.3), r * 0.35, Color(1, 1, 1, 0.55))


# скруглённая полупрозрачная плашка (подписи, легенды)
static func plate(c: CanvasItem, r: Rect2, bg: Color = Color(0.03, 0.05, 0.09, 0.82), border: Color = Color(1, 1, 1, 0.10), rad: int = 6) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(rad)
	sb.anti_aliasing = true
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 4
	sb.draw(c.get_canvas_item(), r)


# подпись с мягкой тенью и обводкой; spaced — вразрядку (названия стран)
static func label(c: CanvasItem, font: Font, p: Vector2, txt: String, fs: int, col: Color, w: float = -1.0, align: int = HORIZONTAL_ALIGNMENT_LEFT, outline: int = 4) -> void:
	c.draw_string_outline(font, p + Vector2(0.0, 1.5), txt, align, w, fs, outline + 2, Color(0, 0, 0, 0.35))
	c.draw_string_outline(font, p, txt, align, w, fs, outline, Color(0.01, 0.02, 0.04, 0.88))
	c.draw_string(font, p, txt, align, w, fs, col)


static func spaced(txt: String) -> String:
	# вразрядку: тонкий пробел между буквами (для коротких названий)
	if txt.length() > 12:
		return txt
	var out := ""
	for i in txt.length():
		out += txt[i]
		if i < txt.length() - 1:
			out += "\u2009"
	return out


# компас (роза ветров) и масштабная линейка
static func compass(c: CanvasItem, font: Font, p: Vector2, r: float) -> void:
	c.draw_circle(p, r + 3.0, Color(0.02, 0.04, 0.08, 0.55))
	c.draw_arc(p, r + 2.0, 0.0, TAU, 32, Color(1, 1, 1, 0.25), 1.2, true)
	var n := PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.28, 0), p + Vector2(-r * 0.28, 0)])
	var s := PackedVector2Array([p + Vector2(0, r), p + Vector2(r * 0.28, 0), p + Vector2(-r * 0.28, 0)])
	c.draw_colored_polygon(n, Color(0.95, 0.55, 0.45, 0.95))
	c.draw_colored_polygon(s, Color(0.85, 0.88, 0.95, 0.75))
	c.draw_line(p + Vector2(-r * 0.75, 0), p + Vector2(r * 0.75, 0), Color(1, 1, 1, 0.3), 1.0)
	c.draw_string(font, p + Vector2(-4.0, -r - 6.0), "С", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.8))
