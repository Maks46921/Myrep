extends Control

var rows: Array = []          # {name, col, share, prev, seats, pseat, gov, ok, you}
var order: Array = []         # партии по порядку в зале: {col, seats}
var thr := 0.05
var total := 100
var maj := 51
var progress := 0.0
var ctr_big := ""
var ctr_small := ""
var ctr_col := Color(1, 1, 1)
var lay: Dictionary = {}
var lay_total := -1
const ROW_H := 24.0
const HEMI_H := 190.0

func _init() -> void:
	custom_minimum_size = Vector2(320.0, 120.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

static func hemi_layout(total: int) -> Dictionary:
	var r0 := 0.40
	var rows_n := 3
	for k in range(3, 24):
		rows_n = k
		var dd: float = (1.0 - r0) / float(k - 1)
		var est: float = PI * float(k) * (1.0 + r0) * 0.5 / dd
		if est >= float(total):
			break
	var d: float = (1.0 - r0) / float(rows_n - 1)
	var radii: Array = []
	var tot_r := 0.0
	for k in rows_n:
		var rr: float = r0 + d * float(k)
		radii.append(rr)
		tot_r += rr
	var counts: Array = []
	var assigned := 0
	for k in rows_n:
		var n: int = int(round(float(total) * float(radii[k]) / tot_r))
		counts.append(n)
		assigned += n
	counts[rows_n - 1] = int(counts[rows_n - 1]) + total - assigned
	var pts: Array = []
	for k in rows_n:
		var n2: int = counts[k]
		for i in n2:
			var ang: float = PI * (1.0 - (float(i) + 0.5) / float(n2))
			pts.append([ang, float(radii[k])])
	pts.sort_custom(func(a, b):
		if absf(float(a[0]) - float(b[0])) > 0.0001:
			return float(a[0]) > float(b[0])
		return float(a[1]) < float(b[1]))
	var arc_sp: float = PI * tot_r / float(total)
	return {"pts": pts, "rad": minf(d, arc_sp) * 0.5 * 0.92, "rows": rows_n}

func set_data(r: Array, o: Array, t: float, tot: int, m: int, cb: String = "", cs: String = "", cc: Color = Color(1, 1, 1)) -> void:
	rows = r
	order = o
	thr = t
	total = tot
	maj = m
	ctr_big = cb
	ctr_small = cs
	ctr_col = cc
	update_minimum_size()
	queue_redraw()

func _get_minimum_size() -> Vector2:
	var h: float = float(rows.size()) * ROW_H + 40.0
	if size.x >= 780.0:
		h = maxf(h, HEMI_H + 12.0)
	else:
		h += HEMI_H
	return Vector2(320.0, h)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		update_minimum_size()

func set_progress(v: float) -> void:
	progress = v
	queue_redraw()

func _draw() -> void:
	var f: Font = get_theme_default_font()
	var FW: float = size.x
	var side: bool = FW >= 780.0
	var W: float = FW * 0.58 if side else FW
	var name_w: float = clampf(W * 0.34, 120.0, 260.0)
	var num_w: float = 206.0
	var bx: float = name_w + 10.0
	var bw: float = maxf(40.0, W - bx - num_w - 6.0)
	var mx := 0.05
	for r in rows:
		mx = maxf(mx, float(r["share"]))
	var scale: float = bw / (mx * 1.1)
	var e: float = 1.0 - pow(1.0 - progress, 3.0)
	for i in rows.size():
		var r: Dictionary = rows[i]
		var y: float = float(i) * ROW_H
		var ok: bool = bool(r["ok"])
		var col: Color = r["col"]
		var dim := 1.0 if ok else 0.45
		if i % 2 == 0:
			draw_rect(Rect2(0.0, y, W, ROW_H), Color(1, 1, 1, 0.03))
		draw_rect(Rect2(4.0, y + 7.0, 10.0, 13.0), Color(col.r, col.g, col.b, dim))
		var nm: String = String(r["name"])
		var tcol := Color(0.93, 0.95, 1.0, dim) if not bool(r["you"]) else Color(1.0, 0.85, 0.45, 1.0)
		draw_string(f, Vector2(20.0, y + 19.0), ("★ " if bool(r["gov"]) else "") + nm, HORIZONTAL_ALIGNMENT_LEFT, name_w - 22.0, 14, tcol)
		draw_rect(Rect2(bx, y + 6.0, bw, 15.0), Color(0.055, 0.067, 0.098))
		var fw: float = float(r["share"]) * scale * e
		if fw > 0.5:
			draw_rect(Rect2(bx, y + 6.0, fw, 15.0), Color(col.r, col.g, col.b, dim))
		var sh: float = float(r["share"]) * 100.0 * e
		var dpp: float = (float(r["share"]) - float(r["prev"])) * 100.0
		var t1 := "%.1f%%" % sh
		draw_string(f, Vector2(bx + bw + 8.0, y + 19.0), t1, HORIZONTAL_ALIGNMENT_LEFT, 60.0, 14, Color(0.93, 0.95, 1.0, dim))
		if progress > 0.85:
			var dcol := Color(0.345, 0.784, 0.529) if dpp > 0.05 else (Color(0.933, 0.420, 0.420) if dpp < -0.05 else Color(0.6, 0.63, 0.72))
			draw_string(f, Vector2(bx + bw + 62.0, y + 19.0), ("%+.1f" % dpp) if absf(dpp) >= 0.05 else "±0", HORIZONTAL_ALIGNMENT_LEFT, 44.0, 12, dcol)
		var st := "%d" % int(round(float(r["seats"]) * e)) if ok else "—"
		draw_string(f, Vector2(W - 92.0, y + 19.0), st, HORIZONTAL_ALIGNMENT_RIGHT, 50.0, 14, Color(1.0, 0.85, 0.45, dim) if bool(r["you"]) else Color(0.93, 0.95, 1.0, dim))
		# v35: изменение числа мест к прошлым выборам
		if progress > 0.85 and r.has("pseat"):
			var ds: int = int(r["seats"]) - int(r["pseat"])
			var scol := Color(0.345, 0.784, 0.529) if ds > 0 else (Color(0.933, 0.420, 0.420) if ds < 0 else Color(0.6, 0.63, 0.72))
			draw_string(f, Vector2(W - 38.0, y + 19.0), ("%+d" % ds) if ds != 0 else "±0", HORIZONTAL_ALIGNMENT_LEFT, 38.0, 12, scol)
	# барьер
	var tx: float = bx + thr * scale
	if thr >= 0.005 and tx < bx + bw:
		var yb: float = float(rows.size()) * ROW_H
		draw_line(Vector2(tx, 4.0), Vector2(tx, yb), Color(1, 1, 1, 0.38), 1.5)
		draw_string(f, Vector2(tx + 4.0, yb + 13.0), "барьер %.0f%%" % (thr * 100.0), HORIZONTAL_ALIGNMENT_LEFT, 120.0, 12, Color(0.75, 0.78, 0.88))
	# полукруг парламента
	var hx0 := 0.0
	var hw: float = FW
	var ys: float = float(rows.size()) * ROW_H + 30.0
	if side:
		hx0 = W + 10.0
		hw = FW - hx0
		ys = 14.0
	draw_string(f, Vector2(hx0 + 4.0, ys), "Парламент: %d мест" % total, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.6, 0.63, 0.72))
	var Rr: float = minf(hw * 0.46, HEMI_H - 28.0)
	var cc := Vector2(hx0 + hw / 2.0, ys + HEMI_H - 8.0)
	if lay_total != total:
		lay = hemi_layout(total)
		lay_total = total
	var pts: Array = lay["pts"]
	var dot: float = maxf(1.6, Rr * float(lay["rad"]))
	var seat_o: Array = []
	for o in order:
		for k in int(o["seats"]):
			seat_o.append(o)
	var shown: int = int(round(float(total) * e))
	draw_arc(cc, Rr * 1.07, PI, TAU, 64, Color(1, 1, 1, 0.10), 1.5)
	for i in pts.size():
		var a: float = pts[i][0]
		var rr: float = pts[i][1]
		var pos: Vector2 = cc + Vector2(cos(a), -sin(a)) * (Rr * rr)
		if i < shown and i < seat_o.size():
			var so: Dictionary = seat_o[i]
			var scol: Color = so["col"]
			var inc: bool = bool(so.get("gov", false))
			draw_circle(pos, dot, scol if inc else scol.darkened(0.4))
			if inc:
				draw_arc(pos, dot + 0.5, 0.0, TAU, 12, Color(1, 1, 1, 0.85), 1.2)
		else:
			draw_circle(pos, dot * 0.55, Color(1, 1, 1, 0.08))
	if ctr_big != "":
		var inner := Rr
		for hp in pts:
			inner = minf(inner, Rr * float(hp[1]))
		var fb := 28
		while fb > 11 and f.get_string_size(ctr_big, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fb).x > inner * 1.7:
			fb -= 1
		var wb: float = f.get_string_size(ctr_big, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fb).x
		draw_string(f, Vector2(cc.x - wb * 0.5, cc.y - Rr * 0.16), ctr_big, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fb, ctr_col)
		var fsm := 13
		while fsm > 9 and f.get_string_size(ctr_small, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fsm).x > inner * 1.9:
			fsm -= 1
		var wsm: float = f.get_string_size(ctr_small, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fsm).x
		draw_string(f, Vector2(cc.x - wsm * 0.5, cc.y - Rr * 0.16 + float(fb) * 0.7), ctr_small, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fsm, Color(0.8, 0.82, 0.9))
