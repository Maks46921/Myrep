# 0.60: свой флаг из слоёв. Документ — словарь {"bg": "#rrggbb", "name": "...", "layers": [слой, ...], "gv": [...], "gh": [...]},
# холст 90 x 60. Слой 0 — нижний. Слой — фигура вокруг центра (x, y) в рамке w x h, повёрнутая на rot градусов.
# Здесь только данные и сборка SVG; окно редактора — flag_edit.gd.
extends RefCounted

const W := 90.0
const H := 60.0

# тип, название, есть ли скругление углов
const TYPES := [
	["rect", "Прямоугольник", true], ["band", "Полоса под углом", true], ["circle", "Круг", false], ["ellipse", "Эллипс", false],
	["tri", "Треугольник", true], ["poly", "Многоугольник", true], ["star", "Звезда", true], ["moon", "Полумесяц", false],
	["cross", "Прямой крест", true], ["xcross", "Косой крест", false], ["nordic", "Скандинавский крест", true], ["chev", "Шеврон", true],
	["rhomb", "Ромб", true], ["ring", "Кольцо", false], ["wave", "Волнистая линия", false], ["rays", "Лучи солнца", false],
	["sector", "Круговой сектор", false], ["arc", "Дуга", false], ["wedge", "Клин", true], ["sym", "Символ", false]]

# ползунки свойств по типам: [поле, подпись, мин, макс, шаг]
const PARAMS := {
	"tri": [["p", "Вершина по ширине", 0.0, 1.0, 0.05]],
	"star": [["n", "Лучей", 3, 12, 1]],
	"moon": [["p", "Сдвиг выреза", 0.05, 0.7, 0.01], ["q", "Размер выреза", 0.4, 1.0, 0.01]],
	"cross": [["p", "Толщина", 0.05, 0.9, 0.01], ["q", "Вертикаль по ширине", 0.1, 0.9, 0.01]],
	"nordic": [["p", "Толщина", 0.05, 0.9, 0.01], ["q", "Вертикаль по ширине", 0.1, 0.9, 0.01]],
	"xcross": [["p", "Толщина", 0.05, 0.9, 0.01]],
	"chev": [["p", "Толщина", 0.05, 0.9, 0.01]],
	"ring": [["p", "Размер дырки", 0.1, 0.95, 0.01]],
	"wave": [["n", "Волн", 1, 12, 1], ["p", "Толщина", 0.05, 0.6, 0.01]],
	"rays": [["n", "Лучей", 3, 32, 1]],
	"sector": [["p", "Доля круга", 0.04, 1.0, 0.01]],
	"arc": [["p", "Доля круга", 0.04, 1.0, 0.01], ["q", "Толщина", 0.05, 0.95, 0.01]],
	"wedge": [["p", "Острие по высоте", 0.0, 1.0, 0.05]],
}

const TEMPLATES := ["Две полосы (горизонтально)", "Три полосы (горизонтально)", "Три полосы (вертикально)", "Скандинавский крест", "Прямой крест",
	"Косой крест", "Деление по диагонали", "Кантон (угол) и поле", "Треугольник у древка", "Круг по центру", "Пять полос", "Две полосы (вертикально)"]


static func type_name(t: String) -> String:
	for ty in TYPES:
		if String(ty[0]) == t:
			return String(ty[1])
	return "Рисунок" if t == "raw" else t


static func has_corner(t: String) -> bool:
	for ty in TYPES:
		if String(ty[0]) == t:
			return bool(ty[2])
	return false


static func lock_aspect(t: String) -> bool:
	return t in ["circle", "star", "sym", "ring", "sector", "arc", "rays", "moon"]


static func new_doc(bg: String = "#ffffff") -> Dictionary:
	return {"bg": bg, "name": "Мой флаг", "layers": [], "gv": [], "gh": []}


static func new_layer(t: String, x: float, y: float, w: float, h: float, fill: String = "#cc1a1f") -> Dictionary:
	var L := {"t": t, "x": x, "y": y, "w": w, "h": h, "rot": 0.0, "fill": fill, "stroke": "", "sw": 1.0, "fx": false, "fy": false,
		"r": 0.0, "n": 5, "p": 0.3, "q": 0.5, "lock": false, "hide": false}
	match t:
		"tri":
			L["p"] = 0.5
		"moon":
			L["p"] = 0.35
			L["q"] = 0.82
		"cross":
			L["p"] = 0.3
		"nordic":
			L["p"] = 0.2
			L["q"] = 0.36
		"xcross":
			L["p"] = 0.22
		"chev":
			L["p"] = 0.3
		"ring":
			L["p"] = 0.62
		"wave":
			L["n"] = 3
			L["p"] = 0.22
		"rays":
			L["n"] = 12
		"sector":
			L["p"] = 0.25
		"arc":
			L["p"] = 0.5
			L["q"] = 0.3
		"wedge":
			L["p"] = 0.5
		"star":
			L["n"] = 5
	return L


static func new_poly(abs_pts: Array, fill: String) -> Dictionary:
	var mn := Vector2(1e9, 1e9)
	var mx := Vector2(-1e9, -1e9)
	for p in abs_pts:
		var v: Vector2 = p
		mn = Vector2(minf(mn.x, v.x), minf(mn.y, v.y))
		mx = Vector2(maxf(mx.x, v.x), maxf(mx.y, v.y))
	var sz := Vector2(maxf(mx.x - mn.x, 0.5), maxf(mx.y - mn.y, 0.5))
	var c := (mn + mx) * 0.5
	var L := new_layer("poly", c.x, c.y, sz.x, sz.y, fill)
	var pts: Array = []
	for p in abs_pts:
		var v: Vector2 = (p - c) / sz
		pts.append([v.x, v.y])
	L["pts"] = pts
	return L


# слой «рисунок»: готовый кусок SVG (заключён в рамку bw x bh с центром cx, cy), его можно двигать и менять размер
static func new_raw(inner: String, cx: float, cy: float, bw: float, bh: float, x: float, y: float, w: float, h: float) -> Dictionary:
	var L := new_layer("raw", x, y, w, h)
	L["svg"] = inner
	L["cx"] = cx
	L["cy"] = cy
	L["bw"] = bw
	L["bh"] = bh
	return L


static func col_hex(c: Color) -> String:
	return "#" + c.to_html(false)


static func col_of(s: String, def: Color = Color.WHITE) -> Color:
	if s == "":
		return def
	return Color.html(s) if s.begins_with("#") else def


# ---------- шаблоны ----------
static func template_doc(i: int, c1: String = "#cc1a1f", c2: String = "#f7f7f7", c3: String = "#0d3a94") -> Dictionary:
	var d := new_doc(c2)
	var ls: Array = d["layers"]
	match i:
		0:
			ls.append(new_layer("rect", 45, 15, 90, 30, c1))
			ls.append(new_layer("rect", 45, 45, 90, 30, c2))
		1:
			ls.append(new_layer("rect", 45, 10, 90, 20, c1))
			ls.append(new_layer("rect", 45, 30, 90, 20, c2))
			ls.append(new_layer("rect", 45, 50, 90, 20, c3))
		2:
			ls.append(new_layer("rect", 15, 30, 30, 60, c1))
			ls.append(new_layer("rect", 45, 30, 30, 60, c2))
			ls.append(new_layer("rect", 75, 30, 30, 60, c3))
		3:
			d["bg"] = c1
			var a := new_layer("nordic", 45, 30, 90, 60, c2)
			a["p"] = 0.2
			ls.append(a)
			var b := new_layer("nordic", 45, 30, 90, 60, c3)
			b["p"] = 0.1
			ls.append(b)
		4:
			d["bg"] = c1
			var a := new_layer("cross", 45, 30, 90, 60, c2)
			a["p"] = 0.24
			ls.append(a)
		5:
			d["bg"] = c1
			var a := new_layer("xcross", 45, 30, 90, 60, c2)
			a["p"] = 0.22
			ls.append(a)
		6:
			d["bg"] = c1
			var a := new_layer("tri", 45, 30, 90, 60, c2)
			a["p"] = 1.0
			a["fy"] = true
			ls.append(a)
		7:
			d["bg"] = c1
			ls.append(new_layer("rect", 20, 16, 40, 32, c2))
		8:
			d["bg"] = c1
			var a := new_layer("wedge", 22.5, 30, 45, 60, c2)
			ls.append(a)
		9:
			d["bg"] = c1
			ls.append(new_layer("circle", 45, 30, 34, 34, c2))
		10:
			for k in 5:
				ls.append(new_layer("rect", 45, 6 + 12.0 * k, 90, 12, c1 if k % 2 == 0 else c2))
		11:
			ls.append(new_layer("rect", 22.5, 30, 45, 60, c1))
			ls.append(new_layer("rect", 67.5, 30, 45, 60, c2))
	return d


# ---------- сборка SVG ----------
static func _f(v: float) -> String:
	return "%.3f" % v


static func _pt(v: Vector2) -> String:
	return "%.3f,%.3f" % [v.x, v.y]


# ломаная со скруглёнными углами (радиус r не больше половины стороны)
static func rpoly(pts: Array, r: float) -> String:
	var n := pts.size()
	var s := ""
	if r <= 0.01:
		for i in n:
			s += ("M" if i == 0 else "L") + _pt(pts[i])
		return s + "Z"
	for i in n:
		var p: Vector2 = pts[i]
		var a: Vector2 = pts[(i + n - 1) % n]
		var b: Vector2 = pts[(i + 1) % n]
		var la := p.distance_to(a)
		var lb := p.distance_to(b)
		if la < 0.001 or lb < 0.001:
			continue
		var rr := minf(r, minf(la, lb) * 0.5)
		var s0: Vector2 = p + (a - p) / la * rr
		var s1: Vector2 = p + (b - p) / lb * rr
		s += ("M" if s == "" else "L") + _pt(s0) + "Q" + _pt(p) + " " + _pt(s1)
	return s + "Z"


static func star_pts(n: int, rx: float, ry: float) -> Array:
	n = clampi(n, 3, 12)
	var ratio := 0.5
	if n == 4:
		ratio = 0.4
	elif n >= 5:
		ratio = cos(TAU / float(n)) / cos(PI / float(n))
	var out: Array = []
	for i in 2 * n:
		var a: float = -PI * 0.5 + float(i) * PI / float(n)
		var k: float = 1.0 if i % 2 == 0 else ratio
		out.append(Vector2(cos(a) * rx * k, sin(a) * ry * k))
	return out


static func cross_pts(w: float, h: float, t: float, vx: float) -> Array:
	var a := t * 0.5
	return [Vector2(vx - a, -h / 2), Vector2(vx + a, -h / 2), Vector2(vx + a, -a), Vector2(w / 2, -a), Vector2(w / 2, a), Vector2(vx + a, a),
		Vector2(vx + a, h / 2), Vector2(vx - a, h / 2), Vector2(vx - a, a), Vector2(-w / 2, a), Vector2(-w / 2, -a), Vector2(vx - a, -a)]


static func _line_x(p: Vector2, d: Vector2, q: Vector2, e: Vector2) -> Vector2:
	var den: float = d.x * e.y - d.y * e.x
	if absf(den) < 1e-6:
		return p
	var t: float = ((q.x - p.x) * e.y - (q.y - p.y) * e.x) / den
	return p + d * t


# объединение двух полос, пересекающихся в нуле: 8 углов и 4 точки пересечения, по кругу
static func xcross_pts(w: float, h: float, t: float) -> Array:
	var ang: float = atan2(h, w)
	var diag: float = sqrt(w * w + h * h) + t * 1.6
	var pts: Array = []
	var lines: Array = []
	for sgn in [1.0, -1.0]:
		var d := Vector2(cos(ang), sgn * sin(ang))
		var nrm := Vector2(-d.y, d.x)
		var hl: float = diag * 0.5
		var e: float = t * 0.5
		pts.append(d * hl + nrm * e)
		pts.append(d * hl - nrm * e)
		pts.append(-d * hl + nrm * e)
		pts.append(-d * hl - nrm * e)
		lines.append([d, nrm * e])
	var d1: Vector2 = lines[0][0]
	var d2: Vector2 = lines[1][0]
	for s1 in [1.0, -1.0]:
		for s2 in [1.0, -1.0]:
			pts.append(_line_x(lines[0][1] * s1, d1, lines[1][1] * s2, d2))
	pts.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.angle() < b.angle())
	return pts


static func moon_path(w: float, h: float, p: float, q: float) -> String:
	var R: float = w * 0.5
	var k: float = h / maxf(w, 0.001)
	var r: float = R * q
	var d: float = R * p
	var x0: float = (d * d + R * R - r * r) / (2.0 * d)
	var y2: float = R * R - x0 * x0
	if y2 <= 0.0:
		return "M%s A%s %s 0 1 0 %s Z" % [_pt(Vector2(R, 0)), _f(R), _f(R * k), _pt(Vector2(-R, 0))] + "A%s %s 0 1 0 %s Z" % [_f(R), _f(R * k), _pt(Vector2(R, 0))]
	var y0: float = sqrt(y2)
	var big: int = 1 if x0 > d else 0
	return "M%s A%s %s 0 1 0 %s A%s %s 0 %d 1 %s Z" % [_pt(Vector2(x0, -y0 * k)), _f(R), _f(R * k), _pt(Vector2(x0, y0 * k)),
		_f(r), _f(r * k), big, _pt(Vector2(x0, -y0 * k))]


static func _ell(rx: float, ry: float) -> String:
	return "M%s A%s %s 0 1 0 %s A%s %s 0 1 0 %s Z" % [_pt(Vector2(-rx, 0)), _f(rx), _f(ry), _pt(Vector2(rx, 0)), _f(rx), _f(ry), _pt(Vector2(-rx, 0))]


static func _eP(a: float, rx: float, ry: float) -> Vector2:
	return Vector2(cos(a) * rx, sin(a) * ry)


# геометрия фигуры вокруг нуля: {"tags": [...«@» вместо краски...], "lw": ширина линии (0 — заливка), "eo": чётно-нечётное}
static func geo(L: Dictionary) -> Dictionary:
	var t: String = String(L["t"])
	var w: float = maxf(float(L["w"]), 0.1)
	var h: float = maxf(float(L["h"]), 0.1)
	var p: float = float(L.get("p", 0.3))
	var q: float = float(L.get("q", 0.5))
	var r: float = float(L.get("r", 0.0))
	var n: int = int(L.get("n", 5))
	var tags: Array = []
	var lw := 0.0
	var eo := false
	match t:
		"rect", "band":
			var rr: float = minf(r, minf(w, h) * 0.5)
			tags.append('<rect x="%s" y="%s" width="%s" height="%s" rx="%s" @/>' % [_f(-w / 2), _f(-h / 2), _f(w), _f(h), _f(rr)])
		"circle", "ellipse":
			tags.append('<ellipse rx="%s" ry="%s" @/>' % [_f(w / 2), _f(h / 2)])
		"tri":
			tags.append('<path d="%s" @/>' % rpoly([Vector2((p - 0.5) * w, -h / 2), Vector2(w / 2, h / 2), Vector2(-w / 2, h / 2)], r))
		"wedge":
			tags.append('<path d="%s" @/>' % rpoly([Vector2(-w / 2, -h / 2), Vector2(w / 2, (p - 0.5) * h), Vector2(-w / 2, h / 2)], r))
		"rhomb":
			tags.append('<path d="%s" @/>' % rpoly([Vector2(0, -h / 2), Vector2(w / 2, 0), Vector2(0, h / 2), Vector2(-w / 2, 0)], r))
		"chev":
			var tt: float = p * w
			tags.append('<path d="%s" @/>' % rpoly([Vector2(-w / 2, -h / 2), Vector2(-w / 2 + tt, -h / 2), Vector2(w / 2, 0), Vector2(-w / 2 + tt, h / 2), Vector2(-w / 2, h / 2), Vector2(w / 2 - tt, 0)], r))
		"poly":
			var ps: Array = []
			for a in L.get("pts", []):
				ps.append(Vector2(float(a[0]) * w, float(a[1]) * h))
			if ps.size() >= 3:
				tags.append('<path d="%s" @/>' % rpoly(ps, r))
		"star":
			tags.append('<path d="%s" @/>' % rpoly(star_pts(n, w / 2, h / 2), r))
		"moon":
			tags.append('<path d="%s" @/>' % moon_path(w, h, clampf(p, 0.05, 0.7), clampf(q, 0.4, 1.0)))
		"cross", "nordic":
			var tc: float = p * minf(w, h)
			tags.append('<path d="%s" @/>' % rpoly(cross_pts(w, h, tc, (q - 0.5) * w), r))
		"xcross":
			tags.append('<path d="%s" @/>' % rpoly(xcross_pts(w, h, p * minf(w, h)), 0.0))
		"ring":
			tags.append('<path d="%s %s" @/>' % [_ell(w / 2, h / 2), _ell(w / 2 * p, h / 2 * p)])
			eo = true
		"wave":
			var th: float = p * h
			var amp: float = maxf((h - th) * 0.5, 0.0)
			var nn: int = clampi(n, 1, 12)
			var steps: int = 24 * nn
			var d := ""
			for i in steps + 1:
				var u: float = float(i) / float(steps)
				d += ("M" if i == 0 else "L") + _pt(Vector2(-w / 2 + u * w, -amp * sin(u * TAU * float(nn))))
			tags.append('<path d="%s" @/>' % d)
			lw = th
		"rays":
			var nn2: int = clampi(n, 3, 32)
			var step: float = TAU / float(nn2)
			var d2 := ""
			for i in nn2:
				var a0: float = -PI * 0.5 - step * 0.25 + float(i) * step
				var a1: float = a0 + step * 0.5
				d2 += "M0,0 L%s A%s %s 0 0 1 %s Z " % [_pt(_eP(a0, w / 2, h / 2)), _f(w / 2), _f(h / 2), _pt(_eP(a1, w / 2, h / 2))]
			tags.append('<path d="%s" @/>' % d2)
		"sector":
			var fr: float = clampf(p, 0.02, 1.0)
			if fr >= 0.999:
				tags.append('<ellipse rx="%s" ry="%s" @/>' % [_f(w / 2), _f(h / 2)])
			else:
				var a1: float = -PI * 0.5 + fr * TAU
				tags.append('<path d="M0,0 L%s A%s %s 0 %d 1 %s Z" @/>' % [_pt(Vector2(0, -h / 2)), _f(w / 2), _f(h / 2), 1 if fr > 0.5 else 0, _pt(_eP(a1, w / 2, h / 2))])
		"arc":
			var fr2: float = clampf(p, 0.02, 0.999)
			var th2: float = clampf(q, 0.05, 0.95)
			var a1b: float = -PI * 0.5 + fr2 * TAU
			var big: int = 1 if fr2 > 0.5 else 0
			var rx0: float = w / 2
			var ry0: float = h / 2
			var rx1: float = rx0 * (1.0 - th2)
			var ry1: float = ry0 * (1.0 - th2)
			tags.append('<path d="M%s A%s %s 0 %d 1 %s L%s A%s %s 0 %d 0 %s Z" @/>' % [_pt(Vector2(0, -ry0)), _f(rx0), _f(ry0), big, _pt(_eP(a1b, rx0, ry0)),
				_pt(_eP(a1b, rx1, ry1)), _f(rx1), _f(ry1), big, _pt(Vector2(0, -ry1))])
	return {"tags": tags, "lw": lw, "eo": eo}


static func layer_svg(L: Dictionary, syms: Array) -> String:
	if bool(L.get("hide", false)):
		return ""
	var t: String = String(L["t"])
	var sx: float = -1.0 if bool(L.get("fx", false)) else 1.0
	var sy: float = -1.0 if bool(L.get("fy", false)) else 1.0
	var x: float = float(L["x"])
	var y: float = float(L["y"])
	var tr := 'translate(%s %s) rotate(%s)' % [_f(x), _f(y), _f(float(L.get("rot", 0.0)))]
	var fill: String = String(L.get("fill", "#000000"))
	if t == "raw":
		var bw: float = maxf(float(L["bw"]), 0.001)
		var bh: float = maxf(float(L["bh"]), 0.001)
		return '<g transform="%s scale(%s %s) scale(%s %s) translate(%s %s)">%s</g>' % [tr, _f(sx), _f(sy), _f(float(L["w"]) / bw), _f(float(L["h"]) / bh), _f(-float(L["cx"])), _f(-float(L["cy"])), String(L["svg"])]
	if t == "sym":
		var i: int = int(L.get("n", 0))
		if i < 0 or i >= syms.size():
			return ""
		var body: String = String((syms[i] as Array)[1]).replace('"C"', '"%s"' % fill)
		return '<g transform="%s scale(%s %s) scale(%s %s)">%s</g>' % [tr, _f(sx), _f(sy), _f(float(L["w"]) / 24.0), _f(float(L["h"]) / 24.0), body]
	var g := geo(L)
	var out := '<g transform="%s scale(%s %s)">' % [tr, _f(sx), _f(sy)]
	var stroke: String = String(L.get("stroke", ""))
	var sw: float = float(L.get("sw", 1.0))
	var lw: float = float(g["lw"])
	var eo: String = ' fill-rule="evenodd"' if bool(g["eo"]) else ""
	if stroke != "" and sw > 0.0:
		for tg in g["tags"]:
			if lw > 0.0:
				out += String(tg).replace("@", 'fill="none" stroke="%s" stroke-width="%s" stroke-linejoin="round"' % [stroke, _f(lw + 2.0 * sw)])
			else:
				out += String(tg).replace("@", 'fill="%s"%s stroke="%s" stroke-width="%s" stroke-linejoin="miter" stroke-miterlimit="3"' % [stroke, eo, stroke, _f(2.0 * sw)])
	for tg in g["tags"]:
		if lw > 0.0:
			out += String(tg).replace("@", 'fill="none" stroke="%s" stroke-width="%s"' % [fill, _f(lw)])
		else:
			out += String(tg).replace("@", 'fill="%s"%s' % [fill, eo])
	return out + "</g>"


static func build_svg(doc: Dictionary, syms: Array) -> String:
	var s := '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 90 60"><rect width="90" height="60" fill="%s"/>' % String(doc.get("bg", "#ffffff"))
	for L in doc["layers"]:
		s += layer_svg(L, syms)
	return s + "</svg>"


# ---------- попадание точки и габариты ----------
static func to_local(L: Dictionary, p: Vector2) -> Vector2:
	var d: Vector2 = p - Vector2(float(L["x"]), float(L["y"]))
	d = d.rotated(-deg_to_rad(float(L.get("rot", 0.0))))
	return d


static func from_local(L: Dictionary, lp: Vector2) -> Vector2:
	return Vector2(float(L["x"]), float(L["y"])) + lp.rotated(deg_to_rad(float(L.get("rot", 0.0))))


static func hit(L: Dictionary, p: Vector2) -> bool:
	if bool(L.get("hide", false)) or bool(L.get("lock", false)):
		return false
	var lp := to_local(L, p)
	var hw: float = maxf(float(L["w"]) * 0.5, 1.0)
	var hh: float = maxf(float(L["h"]) * 0.5, 1.0)
	if String(L["t"]) in ["circle", "ellipse", "ring"]:
		return (lp.x / hw) * (lp.x / hw) + (lp.y / hh) * (lp.y / hh) <= 1.0
	return absf(lp.x) <= hw and absf(lp.y) <= hh


static func corners(L: Dictionary) -> Array:
	var hw: float = float(L["w"]) * 0.5
	var hh: float = float(L["h"]) * 0.5
	return [from_local(L, Vector2(-hw, -hh)), from_local(L, Vector2(hw, -hh)), from_local(L, Vector2(hw, hh)), from_local(L, Vector2(-hw, hh))]


static func aabb(L: Dictionary) -> Rect2:
	var cs := corners(L)
	var mn: Vector2 = cs[0]
	var mx: Vector2 = cs[0]
	for c in cs:
		mn = Vector2(minf(mn.x, (c as Vector2).x), minf(mn.y, (c as Vector2).y))
		mx = Vector2(maxf(mx.x, (c as Vector2).x), maxf(mx.y, (c as Vector2).y))
	return Rect2(mn, mx - mn)


# ---------- разбор готового флага ----------
static func _num(v: String, d: float = 0.0) -> float:
	return v.to_float() if v != "" else d


static func _color(s: String) -> String:
	s = s.strip_edges()
	if s == "" or s == "none" or s.begins_with("url") or s.begins_with("rgb") or s.begins_with("hsl"):
		return ""
	if s.begins_with("#"):
		if s.length() == 4:
			s = "#" + s[1] + s[1] + s[2] + s[2] + s[3] + s[3]
		return s.to_lower() if s.length() == 7 else ""
	var c := Color.from_string(s, Color(0, 0, 0, 0))
	if c.a < 0.5:
		return ""
	return col_hex(c)


static func _ser(px: XMLParser) -> String:
	var nm := px.get_node_name()
	var s := "<" + nm
	for i in px.get_attribute_count():
		s += ' %s="%s"' % [px.get_attribute_name(i), px.get_attribute_value(i).xml_escape(true)]
	if px.is_empty():
		return s + "/>"
	s += ">"
	var depth := 1
	while depth > 0 and px.read() == OK:
		match px.get_node_type():
			XMLParser.NODE_ELEMENT:
				s += "<" + px.get_node_name()
				for i in px.get_attribute_count():
					s += ' %s="%s"' % [px.get_attribute_name(i), px.get_attribute_value(i).xml_escape(true)]
				if px.is_empty():
					s += "/>"
				else:
					s += ">"
					depth += 1
			XMLParser.NODE_ELEMENT_END:
				s += "</%s>" % px.get_node_name()
				depth -= 1
			XMLParser.NODE_TEXT:
				s += px.get_node_data().xml_escape()
	return s + "</%s>" % nm


static func view_box(svg: String) -> Rect2:
	var rx := RegEx.new()
	rx.compile('viewBox="([-0-9. ,]+)"')
	var m := rx.search(svg)
	if m != null:
		var v := m.get_string(1).replace(",", " ").split(" ", false)
		if v.size() == 4:
			return Rect2(float(v[0]), float(v[1]), maxf(float(v[2]), 1.0), maxf(float(v[3]), 1.0))
	return Rect2(0, 0, 90, 60)


# весь флаг одним слоём «рисунок» на всём холсте
static func base_layer(svg: String) -> Dictionary:
	var vb := view_box(svg)
	var a: int = svg.find(">")
	var z: int = svg.rfind("</svg>")
	var inner: String = svg.substr(a + 1, z - a - 1)
	return new_raw(inner, vb.position.x + vb.size.x * 0.5, vb.position.y + vb.size.y * 0.5, vb.size.x, vb.size.y, 45.0, 30.0, W, H)


# флаг по элементам: прямоугольники, круги, эллипсы и многоугольники становятся фигурами, остальное — слоями «рисунок».
# Если в файле есть defs, градиенты и т. п., делить нельзя: вернётся пустой список.
static func split_svg(svg: String) -> Array:
	var low := svg.to_lower()
	for bad in ["<defs", "clippath", "<mask", "gradient", "<use", "<style", "<image", "<filter", "<pattern", "<symbol"]:
		if low.find(bad) >= 0:
			return []
	var vb := view_box(svg)
	var sx: float = W / vb.size.x
	var sy: float = H / vb.size.y
	var px := XMLParser.new()
	if px.open_buffer(svg.to_utf8_buffer()) != OK:
		return []
	var out: Array = []
	var depth := 0
	while px.read() == OK:
		var ty := px.get_node_type()
		if ty == XMLParser.NODE_ELEMENT:
			if depth == 0:
				depth = 1
				continue
			var nm := px.get_node_name()
			var at := {}
			for i in px.get_attribute_count():
				at[px.get_attribute_name(i)] = px.get_attribute_value(i)
			var raw := _ser(px)
			var L: Dictionary = _shape_of(nm, at, vb, sx, sy)
			if L.is_empty():
				out.append(new_raw(raw, vb.position.x + vb.size.x * 0.5, vb.position.y + vb.size.y * 0.5, vb.size.x, vb.size.y, 45.0, 30.0, W, H))
			else:
				out.append(L)
		elif ty == XMLParser.NODE_ELEMENT_END:
			depth -= 1
	return out


static func _shape_of(nm: String, at: Dictionary, vb: Rect2, sx: float, sy: float) -> Dictionary:
	for k in at:
		if not String(k) in ["x", "y", "width", "height", "rx", "ry", "cx", "cy", "r", "points", "fill", "stroke", "stroke-width", "id", "fill-rule"]:
			return {}
	var fill: String = _color(String(at.get("fill", "#000000")))
	if fill == "":
		return {}
	var stroke := ""
	if at.has("stroke"):
		stroke = _color(String(at["stroke"]))
		if stroke == "":
			return {}
	var L := {}
	var ox: float = vb.position.x
	var oy: float = vb.position.y
	match nm:
		"rect":
			var x: float = (_num(String(at.get("x", "0"))) - ox) * sx
			var y: float = (_num(String(at.get("y", "0"))) - oy) * sy
			var w: float = _num(String(at.get("width", "0"))) * sx
			var h: float = _num(String(at.get("height", "0"))) * sy
			if w <= 0.0 or h <= 0.0:
				return {}
			L = new_layer("rect", x + w * 0.5, y + h * 0.5, w, h, fill)
			L["r"] = _num(String(at.get("rx", "0"))) * sx
		"circle", "ellipse":
			var cx: float = (_num(String(at.get("cx", "0"))) - ox) * sx
			var cy: float = (_num(String(at.get("cy", "0"))) - oy) * sy
			var rx: float = _num(String(at.get("r" if nm == "circle" else "rx", "0"))) * sx
			var ry: float = _num(String(at.get("r" if nm == "circle" else "ry", "0"))) * sy
			if rx <= 0.0 or ry <= 0.0:
				return {}
			L = new_layer("circle" if absf(rx - ry) < 0.01 else "ellipse", cx, cy, rx * 2.0, ry * 2.0, fill)
		"polygon":
			var nums := String(at.get("points", "")).replace(",", " ").split(" ", false)
			if nums.size() < 6 or nums.size() % 2 != 0:
				return {}
			var ps: Array = []
			for i in range(0, nums.size(), 2):
				ps.append(Vector2((float(nums[i]) - ox) * sx, (float(nums[i + 1]) - oy) * sy))
			L = new_poly(ps, fill)
		_:
			return {}
	if stroke != "":
		L["stroke"] = stroke
		L["sw"] = maxf(_num(String(at.get("stroke-width", "1")), 1.0) * sx * 0.5, 0.2)
	return L
