# v49: подписи стран вдоль их формы (как на исторических картах): название растянуто по главной оси страны и слегка изогнуто,
# высота букв зависит от ширины страны. Ось и изгиб считаются по центрам АТЕ самой крупной связной части страны
# (острова и заморские земли не перекашивают подпись). На крупном масштабе подпись гаснет — видно административное деление.
extends RefCounted


# pts — центры АТЕ части страны, w — их площади. Результат: центр, направление оси, нормаль, длина, изгиб u(t)=a·t²+b·t+c, толщина.
# max_deg — наибольший наклон подписи; bend — разрешён ли изгиб (для видимой части страны — прямая).
static func compute(pts: PackedVector2Array, w: PackedFloat32Array, max_deg: float = 38.0, bend: bool = true) -> Dictionary:
	var n: int = pts.size()
	if n < 1:
		return {}
	var sw := 0.0
	var m := Vector2.ZERO
	for i in n:
		m += pts[i] * w[i]
		sw += w[i]
	m /= maxf(sw, 1e-6)
	if n < 3:
		return {"m": m, "d": Vector2.RIGHT, "nrm": Vector2.DOWN, "t0": -6.0, "t1": 6.0, "a": 0.0, "b": 0.0, "c": 0.0, "th": 6.0}
	var sxx := 0.0
	var syy := 0.0
	var sxy := 0.0
	for i in n:
		var p: Vector2 = pts[i] - m
		sxx += w[i] * p.x * p.x
		syy += w[i] * p.y * p.y
		sxy += w[i] * p.x * p.y
	var ang: float = 0.5 * atan2(2.0 * sxy, sxx - syy)
	# читаемость: не круче 38° к горизонтали, слева направо
	var d := Vector2(cos(ang), sin(ang))
	if d.x < 0.0:
		d = -d
	var a0: float = clampf(atan2(d.y, d.x), deg_to_rad(-max_deg), deg_to_rad(max_deg))
	d = Vector2(cos(a0), sin(a0))
	var nrm := Vector2(-d.y, d.x)
	var ts := PackedFloat32Array()
	var us := PackedFloat32Array()
	ts.resize(n)
	us.resize(n)
	for i in n:
		var p2: Vector2 = pts[i] - m
		ts[i] = p2.dot(d)
		us[i] = p2.dot(nrm)
	var srt := Array(ts)
	srt.sort()
	var t0: float = float(srt[int(0.04 * float(n - 1))])
	var t1: float = float(srt[int(0.96 * float(n - 1))])
	# изгиб: медианы поперечного смещения в 10 полосах вдоль оси, затем парабола методом наименьших квадратов
	var nb := 10
	var bins: Array = []
	for k in nb:
		bins.append([])
	for i in n:
		if ts[i] < t0 or ts[i] > t1:
			continue
		var k2: int = clampi(int((ts[i] - t0) / maxf(t1 - t0, 1e-6) * float(nb)), 0, nb - 1)
		(bins[k2] as Array).append(us[i])
	var xs: Array = []
	var ys: Array = []
	var ths: Array = []
	for k3 in nb:
		var b: Array = bins[k3]
		if b.size() < 2:
			continue
		b.sort()
		xs.append(t0 + (float(k3) + 0.5) * (t1 - t0) / float(nb))
		ys.append(float(b[b.size() / 2]))
		ths.append(float(b[int(0.9 * float(b.size() - 1))]) - float(b[int(0.1 * float(b.size() - 1))]))
	var qa := 0.0
	var qb := 0.0
	var qc := 0.0
	if xs.size() >= 3:
		var q := fit2(xs, ys) if bend else fit1(xs, ys)
		qa = q[0]
		qb = q[1]
		qc = q[2]
		# наклон прямой части не выводит подпись за предел max_deg (иначе ограничение оси обходится через b)
		var amax: float = deg_to_rad(max_deg + 8.0)
		var tb: float = atan(qb)
		var tb2: float = clampf(a0 + tb, -amax, amax) - a0
		if tb2 != tb:
			var tm: float = (t0 + t1) * 0.5
			var u_m: float = qa * tm * tm + qb * tm + qc
			qb = tan(tb2)
			qc = u_m - qa * tm * tm - qb * tm
		# не слишком изогнуто: отклонение от прямой — не больше 18% длины
		var L: float = t1 - t0
		var dev: float = absf(qa) * L * L * 0.25
		if dev > 0.18 * L:
			var k4: float = 0.18 * L / dev
			qa *= k4
			qb *= k4
	elif xs.size() > 0:
		qc = float(ys[0])
	var th := 6.0
	if not ths.is_empty():
		ths.sort()
		th = maxf(2.0, float(ths[ths.size() / 2]))
	return {"m": m, "d": d, "nrm": nrm, "t0": t0, "t1": t1, "a": qa, "b": qb, "c": qc, "th": th}


static func fit1(xs: Array, ys: Array) -> Array:
	# прямая y = b·x + c
	var n := float(xs.size())
	var sx := 0.0
	var sy := 0.0
	var sxx := 0.0
	var sxy := 0.0
	for i in xs.size():
		var x: float = float(xs[i])
		var y: float = float(ys[i])
		sx += x
		sy += y
		sxx += x * x
		sxy += x * y
	var den: float = n * sxx - sx * sx
	if absf(den) < 1e-9:
		return [0.0, 0.0, sy / maxf(n, 1.0)]
	var b: float = (n * sxy - sx * sy) / den
	return [0.0, b, (sy - b * sx) / n]


static func fit2(xs: Array, ys: Array) -> Array:
	# парабола y = a·x² + b·x + c (нормальные уравнения 3×3)
	var s0 := 0.0
	var s1 := 0.0
	var s2 := 0.0
	var s3 := 0.0
	var s4 := 0.0
	var y0 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	for i in xs.size():
		var x: float = float(xs[i])
		var y: float = float(ys[i])
		s0 += 1.0
		s1 += x
		s2 += x * x
		s3 += x * x * x
		s4 += x * x * x * x
		y0 += y
		y1 += x * y
		y2 += x * x * y
	var M := [[s4, s3, s2, y2], [s3, s2, s1, y1], [s2, s1, s0, y0]]
	for c in 3:
		var piv := c
		for r in range(c + 1, 3):
			if absf(float(M[r][c])) > absf(float(M[piv][c])):
				piv = r
		var tmp = M[c]
		M[c] = M[piv]
		M[piv] = tmp
		if absf(float(M[c][c])) < 1e-9:
			return [0.0, 0.0, y0 / maxf(s0, 1.0)]
		for r2 in 3:
			if r2 == c:
				continue
			var f: float = float(M[r2][c]) / float(M[c][c])
			for k in range(c, 4):
				M[r2][k] = float(M[r2][k]) - f * float(M[c][k])
	return [float(M[0][3]) / float(M[0][0]), float(M[1][3]) / float(M[1][1]), float(M[2][3]) / float(M[2][2])]


static func point(lab: Dictionary, t: float) -> Vector2:
	var u: float = float(lab["a"]) * t * t + float(lab["b"]) * t + float(lab["c"])
	return (lab["m"] as Vector2) + (lab["d"] as Vector2) * t + (lab["nrm"] as Vector2) * u


static func tangent_angle(lab: Dictionary, t: float) -> float:
	var du: float = 2.0 * float(lab["a"]) * t + float(lab["b"])
	var tg: Vector2 = (lab["d"] as Vector2) + (lab["nrm"] as Vector2) * du
	return atan2(tg.y, tg.x)


# высота букв в пикселях при масштабе s (0 — подпись не помещается)
static func font_px(lab: Dictionary, txt: String, font: Font, s: float, max_px: float) -> float:
	var fpx: float = clampf(float(lab["th"]) * 0.42 * s, 0.0, max_px)
	var L: float = (float(lab["t1"]) - float(lab["t0"])) * 0.86 * s
	var wt: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(1, int(fpx))).x
	if wt > L and wt > 0.0:
		fpx *= L / wt
	return fpx


static func draw(ci: CanvasItem, font: Font, lab: Dictionary, txt: String, s: float, off: Vector2, col: Color, max_px: float, min_px: float = 9.0) -> bool:
	if lab.is_empty() or txt == "":
		return false
	var fpx: float = font_px(lab, txt, font, s, max_px)
	if fpx < min_px:
		return false
	var fs: int = int(fpx)
	var n: int = txt.length()
	var wts := PackedFloat32Array()
	var wsum := 0.0
	for i in n:
		var cw: float = font.get_string_size(txt[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		wts.append(cw)
		wsum += cw
	# разрядка: растягиваем по длине страны, но не реже полутора высот букв между знаками
	var L: float = (float(lab["t1"]) - float(lab["t0"])) * 0.86 * s
	var gap: float = clampf((L - wsum) / float(maxi(1, n - 1)), 0.0, fpx * 1.5)
	var tot: float = wsum + gap * float(n - 1)
	var tmid: float = (float(lab["t0"]) + float(lab["t1"])) * 0.5
	var x: float = -tot * 0.5
	var oc := Color(0.02, 0.03, 0.06, 0.55 * col.a)
	for i in n:
		var cx: float = x + wts[i] * 0.5
		var t: float = tmid + cx / s
		var p: Vector2 = point(lab, t) * s + off
		var a: float = tangent_angle(lab, t)
		ci.draw_set_transform(p, a, Vector2.ONE)
		var ch: String = txt[i]
		ci.draw_char_outline(font, Vector2(-wts[i] * 0.5, fpx * 0.36), ch, fs, maxi(2, int(fpx * 0.16)), oc)
		ci.draw_char(font, Vector2(-wts[i] * 0.5, fpx * 0.36), ch, fs, col)
		x += wts[i] + gap
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true


# полосатая штриховка (непризнанные образования, спорные территории): белые диагонали на прозрачном фоне
static var _hatch: ImageTexture = null


static func hatch_tex() -> ImageTexture:
	if _hatch != null:
		return _hatch
	var N := 64
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	for y in N:
		for x in N:
			var v: int = (x + y) % 16
			var a: float = 1.0 if v < 4 else (0.5 if v == 4 or v == 15 else 0.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_hatch = ImageTexture.create_from_image(img)
	return _hatch


# v49: подпись видимой части страны — когда страна шире экрана или её середина за краем (Россия при обзоре Европы).
# Ось и изгиб пересчитываются по точкам, попавшим в окно обзора; результат кэшируется, пока вид почти не менялся.
static var _vis: Dictionary = {}


static func visible_label(key: String, pts: PackedVector2Array, w: PackedFloat32Array, s: float, off: Vector2, view: Rect2) -> Dictionary:
	var c: Dictionary = _vis.get(key, {})
	if not c.is_empty() and absf(float(c["s"]) / s - 1.0) < 0.04 and ((c["off"] as Vector2) - off).length() < 24.0 and (c["view"] as Rect2) == view:
		return c["lab"]
	var inner: Rect2 = view.grow(-maxf(16.0, view.size.y * 0.04))
	var sub := PackedVector2Array()
	var sw := PackedFloat32Array()
	for i in pts.size():
		if inner.has_point(pts[i] * s + off):
			sub.append(pts[i])
			sw.append(w[i] if i < w.size() else 1.0)
	var lab: Dictionary = {} if sub.size() < 10 else compute(sub, sw, 70.0, false)
	if not lab.is_empty():
		# запас у краёв обзора: буквы не заходят под окна
		var dt: float = (float(lab["t1"]) - float(lab["t0"])) * 0.07
		lab["t0"] = float(lab["t0"]) + dt
		lab["t1"] = float(lab["t1"]) - dt
	_vis[key] = {"s": s, "off": off, "view": view, "lab": lab}
	return lab


# подпись целиком, если страна помещается в обзор, иначе — подпись её видимой части
static func draw_fit(ci: CanvasItem, font: Font, key: String, lab: Dictionary, pts: PackedVector2Array, w: PackedFloat32Array, txt: String, s: float, off: Vector2, view: Rect2, col: Color, max_px: float, min_px: float = 9.0) -> bool:
	if lab.is_empty():
		return false
	var lpx: float = (float(lab["t1"]) - float(lab["t0"])) * s
	var mid: Vector2 = point(lab, (float(lab["t0"]) + float(lab["t1"])) * 0.5) * s + off
	if lpx <= view.size.x * 0.85 and view.has_point(mid):
		return draw(ci, font, lab, txt, s, off, col, max_px, min_px)
	if pts.is_empty():
		return false
	var vl: Dictionary = visible_label(key, pts, w, s, off, view)
	return draw(ci, font, vl, txt, s, off, col, max_px, min_px)
