# v49: флаги стран, нарисованные кодом (без файлов картинок): полосы, кресты, треугольники и упрощённые гербы.
# Текстура создаётся один раз на страну и кэшируется; лёгкая «волна» светотени делает флаг живым.
extends RefCounted

const W := 66
const H := 44

static var _cache: Dictionary = {}


static func has(code: String) -> bool:
	return code in ["DE", "FR", "NL", "BE", "LU", "AT", "CH", "CZ", "DK", "ES", "IT", "NO", "PL", "PT", "SE", "GB", "IE", "SI", "SK",
		"HU", "FI", "HR", "RS", "BA", "ME", "MK", "AL", "XK", "BG", "RO", "GR", "EE", "LV", "LT", "MD", "BY", "UA", "RU", "PMR", "DNR", "LNR",
		"US", "CN", "JP", "KR", "TR", "IN", "CA", "AE", "SA", "IL", "TW"]


static func tex(code: String) -> Texture2D:
	if _cache.has(code):
		return _cache[code]
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in W:
			var u: float = (float(x) + 0.5) / float(W)
			var v: float = (float(y) + 0.5) / float(H)
			var c: Color = px(code, u, v)
			# светотень «полотнища на ветру»
			var sh: float = 1.0 + 0.10 * sin(u * 7.5 - 0.6) - 0.04 * u
			c = Color(clampf(c.r * sh, 0.0, 1.0), clampf(c.g * sh, 0.0, 1.0), clampf(c.b * sh, 0.0, 1.0), 1.0)
			if x == 0 or y == 0 or x == W - 1 or y == H - 1:
				c = c.darkened(0.35)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_cache[code] = t
	return t


# цвета
const RED := Color(0.82, 0.10, 0.15)
const WHITE := Color(0.97, 0.97, 0.97)
const BLUE := Color(0.05, 0.22, 0.58)
const LBLUE := Color(0.25, 0.60, 0.88)
const GREEN := Color(0.0, 0.55, 0.30)
const GOLD := Color(1.0, 0.80, 0.0)
const BLACK := Color(0.06, 0.06, 0.06)


static func h3(v: float, a: Color, b: Color, c: Color) -> Color:
	return a if v < 1.0 / 3.0 else (b if v < 2.0 / 3.0 else c)


static func v3(u: float, a: Color, b: Color, c: Color) -> Color:
	return a if u < 1.0 / 3.0 else (b if u < 2.0 / 3.0 else c)


# скандинавский крест: смещён к древку
static func nordic(u: float, v: float, bg: Color, cr: Color, inner: Color = Color(0, 0, 0, 0), w: float = 0.16, wi: float = 0.08) -> Color:
	var cx := 0.375
	var du: float = absf(u - cx) * 1.5
	var dv: float = absf(v - 0.5)
	if inner.a > 0.0 and (du < wi * 0.5 or dv < wi * 0.5):
		return inner
	if du < w * 0.5 or dv < w * 0.5:
		return cr
	return bg


static func circle(u: float, v: float, cu: float, cv: float, r: float) -> bool:
	var du: float = (u - cu) * 1.5
	var dv: float = v - cv
	return du * du + dv * dv < r * r


static func px(code: String, u: float, v: float) -> Color:
	match code:
		"DE": return h3(v, BLACK, Color(0.87, 0.0, 0.0), Color(1.0, 0.81, 0.0))
		"FR": return v3(u, Color(0.0, 0.14, 0.58), WHITE, Color(0.93, 0.16, 0.22))
		"NL": return h3(v, Color(0.68, 0.11, 0.16), WHITE, Color(0.13, 0.28, 0.55))
		"BE": return v3(u, BLACK, Color(0.99, 0.85, 0.15), Color(0.94, 0.20, 0.25))
		"LU": return h3(v, Color(0.93, 0.16, 0.22), WHITE, Color(0.0, 0.64, 0.88))
		"AT": return h3(v, Color(0.93, 0.16, 0.22), WHITE, Color(0.93, 0.16, 0.22))
		"CH":
			var cu: float = (u - 0.5) * 1.5
			var cv: float = v - 0.5
			if (absf(cu) < 0.09 and absf(cv) < 0.30) or (absf(cv) < 0.09 and absf(cu) < 0.30):
				return WHITE
			return Color(0.85, 0.0, 0.0)
		"CZ":
			if u < 0.5 * (1.0 - absf(v - 0.5) * 2.0):
				return Color(0.07, 0.27, 0.49)
			return WHITE if v < 0.5 else Color(0.84, 0.08, 0.13)
		"DK": return nordic(u, v, Color(0.78, 0.06, 0.18), WHITE)
		"SE": return nordic(u, v, Color(0.0, 0.42, 0.66), Color(1.0, 0.80, 0.0))
		"FI": return nordic(u, v, WHITE, Color(0.0, 0.21, 0.50), Color(0, 0, 0, 0), 0.20)
		"NO": return nordic(u, v, Color(0.73, 0.05, 0.18), WHITE, Color(0.0, 0.13, 0.36), 0.22, 0.11)
		"ES":
			if v < 0.25 or v > 0.75:
				return Color(0.67, 0.08, 0.11)
			if u > 0.22 and u < 0.36 and v > 0.34 and v < 0.66:
				return Color(0.67, 0.08, 0.11).lerp(Color(1.0, 0.77, 0.0), 0.35)
			return Color(0.98, 0.77, 0.0)
		"IT": return v3(u, Color(0.0, 0.57, 0.27), WHITE, Color(0.81, 0.17, 0.22))
		"IE": return v3(u, Color(0.09, 0.61, 0.38), WHITE, Color(1.0, 0.53, 0.24))
		"PL": return WHITE if v < 0.5 else Color(0.86, 0.08, 0.24)
		"UA": return Color(0.0, 0.36, 0.73) if v < 0.5 else Color(1.0, 0.84, 0.0)
		"RU": return h3(v, WHITE, Color(0.0, 0.22, 0.65), Color(0.84, 0.17, 0.12))
		"PT":
			if circle(u, v, 0.4, 0.5, 0.17):
				if circle(u, v, 0.4, 0.5, 0.11):
					return WHITE if circle(u, v, 0.4, 0.52, 0.07) else Color(0.85, 0.10, 0.10)
				return Color(1.0, 0.85, 0.0)
			return Color(0.0, 0.40, 0.0) if u < 0.4 else Color(1.0, 0.0, 0.0)
		"GB":
			var x: float = (u - 0.5) * 1.5
			var y: float = v - 0.5
			if absf(x) < 0.07 or absf(y) < 0.10:
				return Color(0.78, 0.06, 0.18)
			if absf(x) < 0.12 or absf(y) < 0.17:
				return WHITE
			var d1: float = absf(x / 0.75 - y / 0.5)
			var d2: float = absf(x / 0.75 + y / 0.5)
			if (d1 < 0.10 and x * y > 0.0) or (d2 < 0.10 and x * y < 0.0):
				return Color(0.78, 0.06, 0.18)
			if d1 < 0.22 or d2 < 0.22:
				return WHITE
			return Color(0.0, 0.14, 0.41)
		"GR":
			if u < 0.40 and v < 5.0 / 9.0:
				var cu2: float = u / 0.40
				var cv2: float = v / (5.0 / 9.0)
				if absf(cu2 - 0.5) < 0.1 or absf(cv2 - 0.5) < 0.1:
					return WHITE
				return Color(0.05, 0.37, 0.69)
			return Color(0.05, 0.37, 0.69) if int(v * 9.0) % 2 == 0 else WHITE
		"HR":
			if u > 0.40 and u < 0.60 and v > 0.28 and v < 0.62:
				var ci: int = int((u - 0.40) / 0.04) + int((v - 0.28) / 0.068)
				return Color(0.85, 0.10, 0.15) if ci % 2 == 0 else WHITE
			return h3(v, Color(1.0, 0.0, 0.0), WHITE, Color(0.09, 0.09, 0.59))
		"HU": return h3(v, Color(0.80, 0.16, 0.24), WHITE, Color(0.28, 0.44, 0.31))
		"SI":
			if u > 0.18 and u < 0.34 and v > 0.18 and v < 0.48:
				return Color(0.0, 0.33, 0.66) if v < 0.40 else WHITE
			return h3(v, WHITE, Color(0.0, 0.33, 0.66), Color(0.93, 0.11, 0.14))
		"SK":
			if u > 0.20 and u < 0.42 and v > 0.22 and v < 0.74:
				var cu3: float = (u - 0.31) * 1.5
				if v > 0.62:
					return Color(0.0, 0.31, 0.60)
				if (absf(cu3) < 0.025 and v > 0.28) or (absf(v - 0.40) < 0.025 and absf(cu3) < 0.09) or (absf(v - 0.50) < 0.025 and absf(cu3) < 0.12):
					return WHITE
				return Color(0.93, 0.11, 0.14)
			return h3(v, WHITE, Color(0.04, 0.31, 0.62), Color(0.93, 0.11, 0.14))
		"RS":
			if u > 0.22 and u < 0.40 and v > 0.22 and v < 0.74:
				var cu4: float = (u - 0.31) * 1.5
				if absf(cu4) < 0.03 or absf(v - 0.47) < 0.04:
					return WHITE
				return Color(0.78, 0.21, 0.25)
			return h3(v, Color(0.78, 0.21, 0.25), Color(0.05, 0.25, 0.46), WHITE)
		"BA":
			var bx: float = u - 0.25
			if bx > 0.0 and u < 0.72 and v < (bx / 0.47):
				return Color(1.0, 0.80, 0.0)
			for k in 9:
				var tk: float = -0.06 + 0.14 * float(k)
				if circle(u, v, 0.25 + 0.47 * tk - 0.085, tk, 0.036):
					return WHITE
			return Color(0.0, 0.14, 0.53)
		"ME":
			if u < 0.05 or u > 0.95 or v < 0.075 or v > 0.925:
				return Color(0.83, 0.68, 0.21)
			if circle(u, v, 0.5, 0.5, 0.18):
				return Color(0.83, 0.68, 0.21) if not circle(u, v, 0.5, 0.52, 0.09) else Color(0.70, 0.12, 0.10)
			return Color(0.77, 0.0, 0.0)
		"MK":
			var mx: float = (u - 0.5) * 1.5
			var my: float = v - 0.5
			if mx * mx + my * my < 0.13 * 0.13:
				return Color(0.97, 0.87, 0.10)
			var an: float = atan2(my, mx)
			var m8: float = fposmod(an, PI / 4.0)
			if absf(m8 - PI / 8.0) < 0.10 * (1.0 + sqrt(mx * mx + my * my)):
				return Color(0.97, 0.87, 0.10)
			return Color(0.82, 0.0, 0.0)
		"AL":
			var ax: float = absf(u - 0.5) * 1.5
			var ay: float = v - 0.5
			# упрощённый двуглавый орёл: тело, крылья с перьями, две головы с клювами наружу, хвост
			var body: bool = ax < 0.06 and ay > -0.20 and ay < 0.16
			var wing: bool = ax < 0.31 and ay > -0.24 + ax * 0.15 and ay < 0.02 + 0.05 * absf(sin(ax * 34.0)) - ax * 0.15
			var neck: bool = ax > 0.02 and ax < 0.08 and ay > -0.32 and ay <= -0.20
			var head: bool = ax > 0.03 and ax < 0.15 and ay > -0.36 and ay < -0.28 + (0.0 if ax < 0.10 else -(ax - 0.10) * 0.8)
			var tail: bool = ay >= 0.14 and ay < 0.32 and ax < 0.03 + (ay - 0.14) * 0.5
			if body or wing or neck or head or tail:
				return BLACK
			return Color(0.89, 0.07, 0.12)
		"XK":
			# очертание страны (упрощённо) и шесть звёзд дугой
			var kx: float = (u - 0.5) * 1.5
			var ky: float = v - 0.58
			if absf(kx) + absf(ky) * 1.15 < 0.20 and ky > -0.18:
				return Color(0.82, 0.67, 0.29)
			for k2 in 6:
				var sa: float = PI + PI * (float(k2) + 0.5) / 6.0
				if circle(u, v, 0.5 + cos(sa) * 0.24 / 1.5, 0.52 + sin(sa) * 0.26, 0.03):
					return WHITE
			return Color(0.15, 0.30, 0.62)
		"BG": return h3(v, WHITE, Color(0.0, 0.59, 0.43), Color(0.84, 0.15, 0.0))
		"RO": return v3(u, Color(0.0, 0.17, 0.50), Color(0.99, 0.82, 0.09), Color(0.81, 0.07, 0.15))
		"EE": return h3(v, Color(0.0, 0.45, 0.81), BLACK, WHITE)
		"LV": return WHITE if absf(v - 0.5) < 0.10 else Color(0.62, 0.19, 0.21)
		"LT": return h3(v, Color(0.99, 0.73, 0.07), Color(0.0, 0.42, 0.27), Color(0.76, 0.15, 0.17))
		"MD":
			if u > 0.40 and u < 0.60 and v > 0.28 and v < 0.72:
				var ex: float = absf(u - 0.5) * 1.5
				var ey: float = v - 0.5
				if (ex < 0.05 and absf(ey) < 0.18) or (ex < 0.13 and ey > -0.10 and ey < 0.04 and ey > -0.10 + ex * 0.4):
					return Color(0.55, 0.32, 0.12)
			return v3(u, Color(0.0, 0.27, 0.62), Color(1.0, 0.82, 0.0), Color(0.80, 0.06, 0.18))
		"BY":
			if u < 0.11:
				# орнамент у древка: красные ромбы на белом
				var ox: float = absf(u / 0.11 - 0.5) * 2.0
				var oy: float = fposmod(v * 7.0, 1.0)
				return Color(0.78, 0.15, 0.17) if ox + absf(oy - 0.5) * 2.0 < 0.9 else WHITE
			return Color(0.78, 0.15, 0.17) if v < 2.0 / 3.0 else Color(0.0, 0.60, 0.28)
		"PMR":
			if circle(u, v, 0.17, 0.2, 0.06) or (u > 0.13 and u < 0.21 and v > 0.22 and v < 0.31 and absf(u - 0.17) < 0.04 + (v - 0.22) * 0.0):
				return Color(1.0, 0.82, 0.0)
			return Color(0.0, 0.47, 0.25) if absf(v - 0.5) < 0.10 else Color(0.75, 0.05, 0.10)
		"DNR": return h3(v, BLACK, Color(0.0, 0.31, 0.65), Color(0.80, 0.08, 0.10))
		"LNR": return h3(v, Color(0.36, 0.67, 0.92), Color(0.05, 0.20, 0.55), Color(0.80, 0.08, 0.10))
		# v51: страны происхождения иностранных компаний
		"US":
			if u < 0.42 and v < 0.54:
				return WHITE if fposmod(u * 18.0, 1.0) < 0.25 and fposmod(v * 13.0, 1.0) < 0.3 else Color(0.20, 0.23, 0.45)
			return Color(0.70, 0.13, 0.20) if int(v * 13.0) % 2 == 0 else WHITE
		"CN":
			if circle(u, v, 0.17, 0.27, 0.09):
				return GOLD
			for k3 in 4:
				var sa2: float = -0.9 + float(k3) * 0.6
				if circle(u, v, 0.17 + cos(sa2) * 0.17, 0.27 + sin(sa2) * 0.25, 0.03):
					return GOLD
			return Color(0.87, 0.16, 0.06)
		"JP": return Color(0.74, 0.0, 0.18) if circle(u, v, 0.5, 0.5, 0.2) else WHITE
		"KR":
			if circle(u, v, 0.5, 0.5, 0.17):
				return Color(0.80, 0.05, 0.20) if v < 0.5 else Color(0.0, 0.20, 0.55)
			return WHITE
		"TR":
			if circle(u, v, 0.38, 0.5, 0.17) and not circle(u, v, 0.42, 0.5, 0.135):
				return WHITE
			if circle(u, v, 0.60, 0.5, 0.05):
				return WHITE
			return Color(0.89, 0.04, 0.09)
		"IN":
			if circle(u, v, 0.5, 0.5, 0.07) and not circle(u, v, 0.5, 0.5, 0.05):
				return Color(0.0, 0.0, 0.53)
			return h3(v, Color(1.0, 0.60, 0.20), WHITE, Color(0.07, 0.53, 0.03))
		"CA":
			if u < 0.25 or u > 0.75:
				return Color(0.85, 0.0, 0.0)
			return Color(0.85, 0.0, 0.0) if circle(u, v, 0.5, 0.5, 0.13) else WHITE
		"AE":
			if u < 0.25:
				return Color(1.0, 0.0, 0.0)
			return h3(v, Color(0.0, 0.45, 0.18), WHITE, BLACK)
		"SA": return WHITE if absf(v - 0.5) < 0.05 and u > 0.25 and u < 0.75 else Color(0.0, 0.42, 0.21)
		"IL":
			if absf(v - 0.15) < 0.06 or absf(v - 0.85) < 0.06:
				return Color(0.0, 0.22, 0.72)
			return Color(0.0, 0.22, 0.72) if circle(u, v, 0.5, 0.5, 0.15) and not circle(u, v, 0.5, 0.5, 0.12) else WHITE
		"TW":
			if u < 0.5 and v < 0.5:
				return WHITE if circle(u, v, 0.25, 0.25, 0.10) else Color(0.0, 0.0, 0.58)
			return Color(1.0, 0.0, 0.0)
	return Color(0.45, 0.48, 0.55)


# флаг в прямоугольнике с тонкой тенью (для _draw любых контролов)
static func draw(ci: CanvasItem, code: String, r: Rect2, alpha: float = 1.0) -> void:
	if not has(code):
		return
	ci.draw_rect(Rect2(r.position + Vector2(1.0, 1.5), r.size), Color(0, 0, 0, 0.35 * alpha))
	ci.draw_texture_rect(tex(code), r, false, Color(1, 1, 1, alpha))


# контрол-флаг для интерфейса
static func make(code: String, h: float = 22.0) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex(code) if has(code) else null
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(h * 1.5, h)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t
