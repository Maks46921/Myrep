# 0.60: холст редактора флага: рисует флаг, сетку, направляющие и рамку выбранной фигуры; ловит мышь
# (создание, перемещение, размер, поворот, направляющие, пипетка, увеличение). Данные — в окне редактора (ed).
extends Control

const FD := preload("res://scripts/classes/flag_doc.gd")

var ed = null
var zoom := 1.0
var pan := Vector2.ZERO
var tex: ImageTexture = null
var img: Image = null
var rs := 8.0
var dirty := true

var drag := ""
var d_m0 := Vector2.ZERO
var d_s0 := Vector2.ZERO
var d_L0: Dictionary = {}
var d_h := Vector2i.ZERO
var d_moved := false
var d_guide := [0, 0]
var poly: Array = []
var mouse_doc := Vector2.ZERO
var snap_lines: Array = []

const DEF_SIZE := {"rect": [40, 26], "circle": [28, 28], "ellipse": [36, 24], "tri": [36, 30], "star": [30, 30], "moon": [26, 26],
	"cross": [48, 36], "xcross": [90, 60], "nordic": [90, 60], "chev": [40, 30], "rhomb": [36, 30], "ring": [30, 30], "wave": [70, 14],
	"rays": [50, 50], "sector": [36, 36], "arc": [36, 36], "wedge": [40, 30], "sym": [24, 24], "band": [170, 12]}


func _ready() -> void:
	clip_contents = true
	focus_mode = Control.FOCUS_CLICK
	mouse_filter = Control.MOUSE_FILTER_STOP


func fit() -> float:
	return maxf(minf((size.x - 40.0) / 90.0, (size.y - 40.0) / 60.0), 1.0)


func scl() -> float:
	return fit() * zoom


func org() -> Vector2:
	return size * 0.5 + pan - Vector2(45.0, 30.0) * scl()


func to_doc(p: Vector2) -> Vector2:
	return (p - org()) / scl()


func to_scr(d: Vector2) -> Vector2:
	return org() + d * scl()


func refresh() -> void:
	dirty = true
	queue_redraw()


func view_reset() -> void:
	zoom = 1.0
	pan = Vector2.ZERO
	refresh()


func zoom_by(f: float, at: Vector2) -> void:
	var before := to_doc(at)
	zoom = clampf(zoom * f, 1.0, 10.0)
	pan += at - to_scr(before)
	if zoom <= 1.001:
		pan = Vector2.ZERO
	refresh()


func _render() -> void:
	dirty = false
	rs = clampf(roundf(scl()), 2.0, 12.0)
	var svg: String = ed.build_svg()
	var im := Image.new()
	if im.load_svg_from_string(svg, rs) == OK and im.get_width() > 1:
		img = im
		tex = ImageTexture.create_from_image(im)
		ed.wind_update(tex)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.10, 0.11, 0.14))
	if ed == null:
		return
	if dirty or absf(clampf(roundf(scl()), 2.0, 12.0) - rs) > 0.1:
		_render()
	var s := scl()
	var o := org()
	var fr := Rect2(o, Vector2(90.0, 60.0) * s)
	if tex != null:
		draw_texture_rect(tex, fr, false)
	draw_rect(fr, Color(1, 1, 1, 0.55), false, 1.0)
	if ed.grid_on:
		var g: float = ed.grid
		var col := Color(0.35, 0.6, 1.0, 0.30)
		var x := g
		while x < 90.0 - 0.01:
			draw_line(to_scr(Vector2(x, 0)), to_scr(Vector2(x, 60)), col, 1.0)
			x += g
		var y := g
		while y < 60.0 - 0.01:
			draw_line(to_scr(Vector2(0, y)), to_scr(Vector2(90, y)), col, 1.0)
			y += g
	var gcol := Color(0.2, 0.95, 0.95, 0.9)
	for gx in ed.doc["gv"]:
		draw_line(Vector2(to_scr(Vector2(float(gx), 0)).x, 0), Vector2(to_scr(Vector2(float(gx), 0)).x, size.y), gcol, 1.0)
	for gy in ed.doc["gh"]:
		draw_line(Vector2(0, to_scr(Vector2(0, float(gy))).y), Vector2(size.x, to_scr(Vector2(0, float(gy))).y), gcol, 1.0)
	var mc := Color(1.0, 0.3, 0.8, 0.95)
	for sl in snap_lines:
		var a: Array = sl
		if int(a[0]) == 0:
			draw_line(Vector2(to_scr(Vector2(float(a[1]), 0)).x, o.y), Vector2(to_scr(Vector2(float(a[1]), 0)).x, o.y + 60.0 * s), mc, 1.0)
		else:
			draw_line(Vector2(o.x, to_scr(Vector2(0, float(a[1]))).y), Vector2(o.x + 90.0 * s, to_scr(Vector2(0, float(a[1]))).y), mc, 1.0)
	_draw_sel()
	if poly.size() > 0:
		var pc := Color(1.0, 0.85, 0.2)
		for i in poly.size():
			var p1: Vector2 = to_scr(poly[i])
			draw_circle(p1, 4.0, pc)
			if i > 0:
				draw_line(to_scr(poly[i - 1]), p1, pc, 2.0)
		draw_line(to_scr(poly[poly.size() - 1]), to_scr(mouse_doc), Color(pc, 0.6), 1.0)


func _draw_sel() -> void:
	var L: Dictionary = ed.layer()
	if L.is_empty() or bool(L.get("hide", false)):
		return
	var acc := Color(1.0, 0.78, 0.2)
	var cs: Array = FD.corners(L)
	var pts := PackedVector2Array()
	for c in cs:
		pts.append(to_scr(c))
	pts.append(pts[0])
	draw_polyline(pts, Color(0, 0, 0, 0.6), 3.0)
	draw_polyline(pts, acc, 1.5)
	if bool(L.get("lock", false)):
		return
	for hx in [-1, 0, 1]:
		for hy in [-1, 0, 1]:
			if hx == 0 and hy == 0:
				continue
			var hp: Vector2 = to_scr(FD.from_local(L, Vector2(float(hx) * float(L["w"]) * 0.5, float(hy) * float(L["h"]) * 0.5)))
			draw_rect(Rect2(hp - Vector2(4.5, 4.5), Vector2(9, 9)), Color(0, 0, 0, 0.7))
			draw_rect(Rect2(hp - Vector2(3.5, 3.5), Vector2(7, 7)), Color(1, 1, 1))
	var top: Vector2 = to_scr(FD.from_local(L, Vector2(0.0, -float(L["h"]) * 0.5)))
	var rp := top + Vector2(0, -26.0).rotated(deg_to_rad(float(L.get("rot", 0.0))))
	draw_line(top, rp, acc, 1.5)
	draw_circle(rp, 6.0, Color(0, 0, 0, 0.7))
	draw_circle(rp, 4.5, acc)


# ---------- привязка ----------
func best_snap(vals: Array, axis: int) -> Vector2:
	var thr: float = 7.0 / scl()
	var lim: float = 90.0 if axis == 0 else 60.0
	var gl: Array = ed.doc["gv"] if axis == 0 else ed.doc["gh"]
	var best_d := 1e9
	var best_l := 0.0
	var g: float = ed.grid
	for v in vals:
		var fv: float = float(v)
		var ts: Array = [0.0, lim * 0.5, lim, roundf(fv / g) * g]
		for q in gl:
			ts.append(float(q))
		for t in ts:
			var d: float = float(t) - fv
			if absf(d) < absf(best_d) and absf(d) <= thr:
				best_d = d
				best_l = float(t)
	return Vector2(best_d, best_l)


func snap_pt(m: Vector2) -> Vector2:
	snap_lines = []
	if not ed.snap_on or Input.is_key_pressed(KEY_ALT):
		return m
	var sx := best_snap([m.x], 0)
	var sy := best_snap([m.y], 1)
	var out := m
	if absf(sx.x) < 1e8:
		out.x += sx.x
		snap_lines.append([0, sx.y])
	if absf(sy.x) < 1e8:
		out.y += sy.x
		snap_lines.append([1, sy.y])
	return out


# ---------- ручки ----------
func handle_at(pos: Vector2) -> Vector2i:
	var L: Dictionary = ed.layer()
	if L.is_empty() or bool(L.get("lock", false)) or bool(L.get("hide", false)):
		return Vector2i.ZERO
	var top: Vector2 = to_scr(FD.from_local(L, Vector2(0.0, -float(L["h"]) * 0.5)))
	var rp := top + Vector2(0, -26.0).rotated(deg_to_rad(float(L.get("rot", 0.0))))
	if pos.distance_to(rp) <= 9.0:
		return Vector2i(9, 9)
	for hx in [-1, 0, 1]:
		for hy in [-1, 0, 1]:
			if hx == 0 and hy == 0:
				continue
			var hp: Vector2 = to_scr(FD.from_local(L, Vector2(float(hx) * float(L["w"]) * 0.5, float(hy) * float(L["h"]) * 0.5)))
			if pos.distance_to(hp) <= 8.0:
				return Vector2i(hx, hy)
	return Vector2i.ZERO


func _guide_at(pos: Vector2) -> Array:
	for i in (ed.doc["gv"] as Array).size():
		if absf(to_scr(Vector2(float(ed.doc["gv"][i]), 0)).x - pos.x) <= 4.0:
			return [0, i]
	for i in (ed.doc["gh"] as Array).size():
		if absf(to_scr(Vector2(0, float(ed.doc["gh"][i]))).y - pos.y) <= 4.0:
			return [1, i]
	return []


# ---------- ввод ----------
func _gui_input(ev: InputEvent) -> void:
	if ed == null:
		return
	var mb := ev as InputEventMouseButton
	if mb != null:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			zoom_by(1.15, mb.position)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			zoom_by(1.0 / 1.15, mb.position)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				grab_focus()
				_press(mb)
			else:
				_release(mb.position)
		elif mb.button_index == MOUSE_BUTTON_MIDDLE or mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				if mb.button_index == MOUSE_BUTTON_RIGHT and (ed.tool != "" or poly.size() > 0):
					cancel_tool()
				else:
					drag = "pan"
					d_s0 = mb.position
					d_L0 = {"px": pan.x, "py": pan.y}
			elif drag == "pan":
				drag = ""
		return
	var mm := ev as InputEventMouseMotion
	if mm != null:
		_motion(mm.position, mm.shift_pressed)


func cancel_tool() -> void:
	poly = []
	ed.set_tool("")
	queue_redraw()


func _press(mb: InputEventMouseButton) -> void:
	var m := to_doc(mb.position)
	if ed.tool == "pipette":
		ed.pipette_at(self, mb.position)
		return
	if ed.tool == "poly":
		var p := snap_pt(m)
		if poly.size() >= 3 and (mb.double_click or to_scr(p).distance_to(to_scr(poly[0])) < 9.0):
			finish_poly()
			return
		if poly.size() > 0 and (poly[poly.size() - 1] as Vector2).distance_to(p) < 0.05:
			return
		poly.append(p)
		queue_redraw()
		return
	if ed.tool != "":
		var t: String = ed.tool
		ed.snap_undo()
		var p0 := snap_pt(m)
		var L: Dictionary = ed.new_shape(t, p0.x, p0.y, 0.1, 0.1)
		ed.add_layer(L)
		drag = "create"
		d_m0 = p0
		d_moved = false
		return
	var hd := handle_at(mb.position)
	if hd != Vector2i.ZERO:
		d_L0 = (ed.layer() as Dictionary).duplicate(true)
		d_h = hd
		d_moved = false
		drag = "rotate" if hd.x == 9 else "resize"
		return
	var gd := _guide_at(mb.position)
	if gd.size() == 2:
		drag = "guide"
		d_guide = gd
		d_moved = false
		return
	var layers: Array = ed.doc["layers"]
	for i in range(layers.size() - 1, -1, -1):
		if FD.hit(layers[i], m):
			ed.select(i)
			d_L0 = (layers[i] as Dictionary).duplicate(true)
			d_m0 = m
			d_moved = false
			drag = "move"
			return
	ed.select(-1)


func finish_poly() -> void:
	if poly.size() >= 3:
		ed.snap_undo()
		ed.add_layer(FD.new_poly(poly, ed.cur_fill))
	poly = []
	ed.set_tool("")
	queue_redraw()


func _motion(pos: Vector2, shift: bool) -> void:
	mouse_doc = to_doc(pos)
	if ed.tool == "poly" and poly.size() > 0:
		queue_redraw()
	if drag == "":
		var hd := handle_at(pos)
		if ed.tool != "":
			mouse_default_cursor_shape = Control.CURSOR_CROSS
		elif hd == Vector2i(9, 9):
			mouse_default_cursor_shape = Control.CURSOR_CROSS
		elif hd != Vector2i.ZERO:
			mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE if hd.x * hd.y > 0 else (Control.CURSOR_BDIAGSIZE if hd.x * hd.y < 0 else (Control.CURSOR_HSIZE if hd.x != 0 else Control.CURSOR_VSIZE))
		elif _guide_at(pos).size() == 2:
			mouse_default_cursor_shape = Control.CURSOR_HSIZE if int(_guide_at(pos)[0]) == 0 else Control.CURSOR_VSIZE
		else:
			mouse_default_cursor_shape = Control.CURSOR_ARROW
		return
	if drag == "pan":
		pan = Vector2(float(d_L0["px"]), float(d_L0["py"])) + (pos - d_s0)
		refresh()
		return
	var m := mouse_doc
	if drag == "guide":
		if not d_moved:
			ed.snap_undo()
			d_moved = true
		var ax: int = int(d_guide[0])
		var arr: Array = ed.doc["gv"] if ax == 0 else ed.doc["gh"]
		var v: float = m.x if ax == 0 else m.y
		if ed.snap_on:
			v = roundf(v / (ed.grid * 0.5)) * ed.grid * 0.5
		arr[int(d_guide[1])] = v
		queue_redraw()
		return
	var L: Dictionary = ed.layer()
	if L.is_empty():
		return
	if not d_moved:
		d_moved = true
		if drag != "create":
			ed.snap_undo()
	if drag == "create":
		_do_create(m)
	elif drag == "move":
		_do_move(L, m)
	elif drag == "resize":
		_do_resize(L, m, shift)
	elif drag == "rotate":
		_do_rotate(L, m)
	refresh()


func _do_create(m: Vector2) -> void:
	var L: Dictionary = ed.layer()
	var t: String = String(L["t"])
	var p1 := snap_pt(m)
	var d := p1 - d_m0
	if t == "band":
		L["x"] = d_m0.x
		L["y"] = d_m0.y
		if d.length() > 1.0:
			L["rot"] = rad_to_deg(d.angle())
		return
	var w: float = absf(d.x)
	var h: float = absf(d.y)
	if FD.lock_aspect(t) or t == "poly":
		var sz: float = maxf(w, h)
		w = sz
		h = sz
		L["x"] = d_m0.x + (1.0 if d.x >= 0.0 else -1.0) * sz * 0.5
		L["y"] = d_m0.y + (1.0 if d.y >= 0.0 else -1.0) * sz * 0.5
	else:
		L["x"] = (d_m0.x + p1.x) * 0.5
		L["y"] = (d_m0.y + p1.y) * 0.5
	L["w"] = maxf(w, 0.1)
	L["h"] = maxf(h, 0.1)


func _do_move(L: Dictionary, m: Vector2) -> void:
	var dl := m - d_m0
	L["x"] = float(d_L0["x"]) + dl.x
	L["y"] = float(d_L0["y"]) + dl.y
	snap_lines = []
	if not ed.snap_on or Input.is_key_pressed(KEY_ALT):
		return
	var bb := FD.aabb(L)
	var sx := best_snap([bb.position.x, bb.position.x + bb.size.x * 0.5, bb.end.x], 0)
	var sy := best_snap([bb.position.y, bb.position.y + bb.size.y * 0.5, bb.end.y], 1)
	if absf(sx.x) < 1e8:
		L["x"] = float(L["x"]) + sx.x
		snap_lines.append([0, sx.y])
	if absf(sy.x) < 1e8:
		L["y"] = float(L["y"]) + sy.x
		snap_lines.append([1, sy.y])


func _do_resize(L: Dictionary, m: Vector2, shift: bool) -> void:
	var rot: float = float(d_L0.get("rot", 0.0))
	var p := m
	var quarter: bool = absf(fposmod(rot, 90.0)) < 0.01 or absf(fposmod(rot, 90.0) - 90.0) < 0.01
	snap_lines = []
	if quarter:
		p = snap_pt(m)
	var lm := FD.to_local(d_L0, p)
	var w0: float = float(d_L0["w"])
	var h0: float = float(d_L0["h"])
	var nw := w0
	var nh := h0
	var cx := 0.0
	var cy := 0.0
	if d_h.x != 0:
		var ox: float = -float(d_h.x) * w0 * 0.5
		nw = maxf(absf(lm.x - ox), 1.0)
		cx = ox + float(d_h.x) * nw * 0.5
	if d_h.y != 0:
		var oy: float = -float(d_h.y) * h0 * 0.5
		nh = maxf(absf(lm.y - oy), 1.0)
		cy = oy + float(d_h.y) * nh * 0.5
	if FD.lock_aspect(String(L["t"])) or shift:
		if d_h.x != 0 and d_h.y != 0:
			var k: float = maxf(nw / w0, nh / h0)
			nw = w0 * k
			nh = h0 * k
			cx = -float(d_h.x) * w0 * 0.5 + float(d_h.x) * nw * 0.5
			cy = -float(d_h.y) * h0 * 0.5 + float(d_h.y) * nh * 0.5
		elif d_h.x != 0:
			nh = h0 * nw / w0
			cy = 0.0
		else:
			nw = w0 * nh / h0
			cx = 0.0
	if not quarter and ed.snap_on and not Input.is_key_pressed(KEY_ALT):
		var g: float = ed.grid * 0.5
		if d_h.x != 0 and absf(nw - roundf(nw / g) * g) < 0.8:
			var nw2: float = roundf(nw / g) * g
			cx += float(d_h.x) * (nw2 - nw) * 0.5
			nw = nw2
		if d_h.y != 0 and absf(nh - roundf(nh / g) * g) < 0.8:
			var nh2: float = roundf(nh / g) * g
			cy += float(d_h.y) * (nh2 - nh) * 0.5
			nh = nh2
	var c := FD.from_local(d_L0, Vector2(cx, cy))
	L["x"] = c.x
	L["y"] = c.y
	L["w"] = maxf(nw, 0.5)
	L["h"] = maxf(nh, 0.5)


func _do_rotate(L: Dictionary, m: Vector2) -> void:
	var c := Vector2(float(d_L0["x"]), float(d_L0["y"]))
	var a: float = rad_to_deg((m - c).angle()) + 90.0
	if ed.snap_on and not Input.is_key_pressed(KEY_ALT):
		var r: float = roundf(a / 15.0) * 15.0
		if absf(a - r) < 5.0:
			a = r
	L["rot"] = wrapf(a, -180.0, 180.0)


func _release(pos: Vector2) -> void:
	var was := drag
	drag = ""
	snap_lines = []
	if was == "create":
		var L: Dictionary = ed.layer()
		if not L.is_empty():
			var t: String = String(L["t"])
			if maxf(float(L["w"]), float(L["h"])) < 2.5 and t != "band":
				var ds: Array = DEF_SIZE.get(t, [30, 30])
				L["w"] = float(ds[0])
				L["h"] = float(ds[1])
			elif t == "band":
				L["w"] = float((DEF_SIZE["band"] as Array)[0])
				L["h"] = float((DEF_SIZE["band"] as Array)[1])
		ed.set_tool("")
		ed.after_edit()
	elif was == "guide":
		var ax: int = int(d_guide[0])
		var arr: Array = ed.doc["gv"] if ax == 0 else ed.doc["gh"]
		if not Rect2(Vector2.ZERO, size).has_point(pos):
			arr.remove_at(int(d_guide[1]))
		ed.after_edit(false)
	elif was in ["move", "resize", "rotate"]:
		ed.after_edit(false)
	refresh()
