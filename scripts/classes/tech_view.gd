# Схема технологий (v42_1): дорожки веток, уровни слева направо, связи между уровнями, группы выбора «или».
# Данные берёт у игры (game): TECHS, TECH_BRANCHES, tech_*; сообщает о наведении и щелчке сигналами.
extends Control

signal picked(id: String)
signal hovered(id: String)

const NW := 180.0          # ширина карточки
const NH := 54.0           # высота карточки
const GX := 46.0           # промежуток между уровнями
const GY := 6.0            # промежуток между карточками уровня
const LANE_PAD := 12.0
const LABEL_W := 126.0
const HEAD_H := 34.0

var game: Object = null
var scroll: ScrollContainer = null
var vis: Array = []            # какие ветки показаны (bool)
var pos: Dictionary = {}       # id -> Rect2
var lanes: Array = []          # [{b, y, h}]
var hover_id := ""
var zoom := 1.0               # одна ветка на экране — рисуем крупнее
var _drag := false
var _drag_from := Vector2.ZERO
var _drag_scroll := Vector2.ZERO


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	focus_mode = Control.FOCUS_NONE


func set_game(g: Object) -> void:
	game = g
	vis.clear()
	for b in g.TECH_NB:
		vis.append(true)
	relayout()


func set_visible_branches(v: Array) -> void:
	vis = v.duplicate()
	relayout()


func relayout() -> void:
	pos.clear()
	lanes.clear()
	if game == null or game.tech.is_empty():
		return
	var y := HEAD_H
	for b in game.TECH_NB:
		if not bool(vis[b]):
			continue
		var grp: Dictionary = game.tech["grp"][b]
		var mx := 1
		for t in grp:
			mx = maxi(mx, (grp[t] as Array).size())
		var lh: float = mx * NH + (mx - 1) * GY + 2.0 * LANE_PAD
		lanes.append({"b": b, "y": y, "h": lh})
		for t in grp:
			var ids: Array = grp[t]
			var tot: float = ids.size() * NH + (ids.size() - 1) * GY
			var y0: float = y + (lh - tot) * 0.5
			for k in ids.size():
				pos[String(ids[k])] = Rect2(LABEL_W + float(t) * (NW + GX), y0 + float(k) * (NH + GY), NW, NH)
		y += lh + 6.0
	zoom = 1.25 if lanes.size() == 1 else 1.0
	custom_minimum_size = Vector2(LABEL_W + float(game.tech["ty"].size()) * (NW + GX), y + 4.0) * zoom
	queue_redraw()


func node_at(p: Vector2) -> String:
	p /= zoom
	for id in pos:
		if (pos[id] as Rect2).has_point(p):
			return String(id)
	return ""


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		var m := ev as InputEventMouseMotion
		if _drag and scroll != null:
			var d: Vector2 = _drag_from - m.global_position
			scroll.scroll_horizontal = int(_drag_scroll.x + d.x)
			scroll.scroll_vertical = int(_drag_scroll.y + d.y)
			return
		var id := node_at(m.position)
		if id != hover_id:
			hover_id = id
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if id != "" else Control.CURSOR_ARROW
			hovered.emit(id)
			queue_redraw()
	elif ev is InputEventMouseButton:
		var b := ev as InputEventMouseButton
		if b.button_index == MOUSE_BUTTON_LEFT:
			if b.pressed:
				var id2 := node_at(b.position)
				if id2 != "":
					picked.emit(id2)
					accept_event()
				elif scroll != null:
					_drag = true
					_drag_from = b.global_position
					_drag_scroll = Vector2(scroll.scroll_horizontal, scroll.scroll_vertical)
			else:
				_drag = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_drag = false
		if hover_id != "":
			hover_id = ""
			hovered.emit("")
			queue_redraw()


func _branch_col(b: int) -> Color:
	return Color(String(game.TECH_BRANCHES[b]["col"]))


func _curve(a: Vector2, b: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var dx: float = (b.x - a.x) * 0.5
	for i in 17:
		var t: float = float(i) / 16.0
		var u: float = 1.0 - t
		pts.append(u * u * u * a + 3.0 * u * u * t * (a + Vector2(dx, 0.0)) + 3.0 * u * t * t * (b - Vector2(dx, 0.0)) + t * t * t * b)
	return pts


func _state(id: String, b: int) -> String:
	if game.tech_done(id):
		return "done"
	if String(game.tech["cur"][b]) == id:
		return "cur"
	var miss: String = game.tech_missing(id)
	if miss == "":
		return "avail"
	if miss.begins_with("не выбрана"):
		return "excl"
	return "locked"


func _draw() -> void:
	if game == null or game.tech.is_empty():
		return
	var f := ThemeDB.fallback_font
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(zoom, zoom))
	var w: float = size.x / zoom
	var yrs: float = game.years_passed()
	var ty: Array = game.tech["ty"]
	# колонки: заголовки уровней
	for t in ty.size():
		var x: float = LABEL_W + float(t) * (NW + GX)
		var open: bool = yrs >= float(ty[t])
		var col := Color(0.80, 0.86, 1.0, 0.95) if open else Color(0.55, 0.60, 0.72, 0.65)
		draw_string(f, Vector2(x, 14.0), "Уровень %d" % (t + 1), HORIZONTAL_ALIGNMENT_LEFT, NW, 12, col)
		draw_string(f, Vector2(x, 28.0), ("с %d г." % (game.START_YEAR + int(ty[t]))) if not open else "открыт", HORIZONTAL_ALIGNMENT_LEFT, NW, 10, Color(col.r, col.g, col.b, 0.7))
		draw_line(Vector2(x - GX * 0.5, 0.0), Vector2(x - GX * 0.5, size.y / zoom), Color(1, 1, 1, 0.035), 1.0)
	# дорожки
	for ln in lanes:
		var b: int = ln["b"]
		var c := _branch_col(b)
		draw_rect(Rect2(0.0, ln["y"], w, ln["h"]), Color(c.r, c.g, c.b, 0.07))
		draw_rect(Rect2(0.0, ln["y"], 4.0, ln["h"]), Color(c.r, c.g, c.b, 0.9))
		draw_multiline_string(f, Vector2(14.0, float(ln["y"]) + 22.0), String(game.TECH_BRANCHES[b]["name"]), HORIZONTAL_ALIGNMENT_LEFT, LABEL_W - 18.0, 13, 2, Color(c.r, c.g, c.b, 1.0).lightened(0.25))
		var nd := 0
		for t in game.tech["grp"][b]:
			if game.tech_tier_done(b, int(t)) != "":
				nd += 1
		draw_string(f, Vector2(14.0, float(ln["y"]) + 62.0), "%d / %d" % [nd, (game.tech["grp"][b] as Dictionary).size()], HORIZONTAL_ALIGNMENT_LEFT, LABEL_W - 18.0, 12, Color(1, 1, 1, 0.6))
	# связи
	var hl: String = hover_id
	for d in game.TECHS:
		var id: String = d["id"]
		if not pos.has(id):
			continue
		var b2: int = int(d["b"])
		var r: Rect2 = pos[id]
		var bc := _branch_col(b2)
		var srcs: Array = []
		if int(d["t"]) > 0:
			srcs = (game.tech["grp"][b2] as Dictionary)[int(d["t"]) - 1]
		for sid in srcs:
			if not pos.has(sid):
				continue
			var sr: Rect2 = pos[sid]
			var done_s: bool = game.tech_done(String(sid))
			var ex: bool = _state(id, b2) == "excl" or _state(String(sid), b2) == "excl"
			var col2 := Color(0.5, 0.56, 0.7, 0.28)
			var wd := 1.4
			if done_s and not ex:
				col2 = Color(bc.r, bc.g, bc.b, 0.95)
				wd = 2.6
			elif ex:
				col2 = Color(0.4, 0.4, 0.45, 0.10)
			if hl == id or hl == String(sid):
				col2 = col2.lightened(0.35)
				col2.a = 1.0
				wd += 1.0
			draw_polyline(_curve(Vector2(sr.end.x, sr.position.y + NH * 0.5), Vector2(r.position.x, r.position.y + NH * 0.5)), col2, wd, true)
		for rq in d.get("req", []):
			if not pos.has(rq):
				continue
			if not (hl == id or hl == String(rq)):
				continue
			var rr: Rect2 = pos[rq]
			var pts := _curve(Vector2(rr.end.x, rr.position.y + NH * 0.5), Vector2(r.position.x, r.position.y + NH * 0.5))
			for i in range(0, pts.size() - 1, 2):
				draw_line(pts[i], pts[i + 1], Color(1.0, 0.95, 0.6, 0.95), 2.0, true)
	# группы выбора
	for t2 in ty.size():
		for ln2 in lanes:
			var grp: Array = (game.tech["grp"][int(ln2["b"])] as Dictionary).get(t2, [])
			if grp.size() < 2:
				continue
			var r0: Rect2 = pos[grp[0]]
			var r1: Rect2 = pos[grp[grp.size() - 1]]
			var xb: float = r0.position.x - 9.0
			draw_polyline(PackedVector2Array([Vector2(xb + 4.0, r0.position.y + 6.0), Vector2(xb, r0.position.y + 6.0), Vector2(xb, r1.end.y - 6.0), Vector2(xb + 4.0, r1.end.y - 6.0)]), Color(1.0, 0.85, 0.5, 0.75), 1.6)
			var ym: float = (r0.position.y + r1.end.y) * 0.5
			draw_rect(Rect2(xb - 34.0, ym - 8.0, 24.0, 15.0), Color(0.07, 0.08, 0.12, 0.95))
			draw_string(f, Vector2(xb - 30.0, ym + 4.0), "или", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.85, 0.5, 0.95))
	# карточки
	var nbn: int = game.tech_nb().size()
	for d2 in game.TECHS:
		var id2: String = d2["id"]
		if not pos.has(id2):
			continue
		var b3: int = int(d2["b"])
		var r2: Rect2 = pos[id2]
		var c3 := _branch_col(b3)
		var st := _state(id2, b3)
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(8)
		sb.set_border_width_all(2)
		var tcol := Color(0.93, 0.95, 1.0)
		match st:
			"done":
				sb.bg_color = c3.darkened(0.62)
				sb.border_color = c3
			"cur":
				sb.bg_color = Color(0.09, 0.11, 0.16)
				sb.border_color = c3.lightened(0.5)
				sb.set_border_width_all(3)
			"avail":
				sb.bg_color = Color(0.11, 0.13, 0.19)
				sb.border_color = Color(c3.r, c3.g, c3.b, 0.9)
			"excl":
				sb.bg_color = Color(0.07, 0.08, 0.10)
				sb.border_color = Color(0.25, 0.27, 0.32)
				sb.set_border_width_all(1)
				tcol = Color(0.45, 0.47, 0.54)
			_:
				sb.bg_color = Color(0.085, 0.10, 0.14)
				sb.border_color = Color(0.22, 0.26, 0.36)
				sb.set_border_width_all(1)
				tcol = Color(0.62, 0.66, 0.76)
		if id2 == hl:
			sb.border_color = Color(1, 1, 1)
			sb.set_border_width_all(3)
			sb.shadow_color = Color(c3.r, c3.g, c3.b, 0.5)
			sb.shadow_size = 8
		draw_style_box(sb, r2)
		if st == "cur":
			var pr: float = game.tech_progress(id2)
			draw_rect(Rect2(r2.position.x + 4.0, r2.end.y - 7.0, (r2.size.x - 8.0) * clampf(pr, 0.0, 1.0), 4.0), c3)
			draw_rect(Rect2(r2.position.x + 4.0, r2.end.y - 7.0, r2.size.x - 8.0, 4.0), Color(1, 1, 1, 0.10))
		var mark := ""
		if st == "done":
			mark = "✔ "
		elif st == "cur":
			mark = "▶ "
		var nm: String = mark + String(d2["name"])
		draw_multiline_string(f, Vector2(r2.position.x + 8.0, r2.position.y + 15.0), nm, HORIZONTAL_ALIGNMENT_LEFT, NW - 16.0, 12, 2, tcol)
		var sub := ""
		match st:
			"done":
				sub = "изучено"
			"cur":
				sub = "%.0f%% · %d очк." % [game.tech_progress(id2) * 100.0, int(d2["cost"])]
			"avail":
				sub = "%d очк." % int(d2["cost"])
			"excl":
				sub = "не выбрана"
			_:
				sub = String(game.tech_missing(id2)).replace("доступна ", "").replace("нужен предыдущий уровень", "нужен ур. выше")
		if st != "cur":
			draw_string(f, Vector2(r2.position.x + 8.0, r2.end.y - 7.0), sub, HORIZONTAL_ALIGNMENT_LEFT, NW - 16.0, 10, Color(tcol.r, tcol.g, tcol.b, 0.75))
		else:
			draw_string(f, Vector2(r2.position.x + 8.0, r2.end.y - 11.0), sub, HORIZONTAL_ALIGNMENT_LEFT, NW - 16.0, 10, Color(tcol.r, tcol.g, tcol.b, 0.85))
		# соседи: кружки по числу стран, знающих технологию
		if nbn > 0 and st != "done" and st != "excl":
			var have: int = game.tech_nb_who(id2).size()
			if have > 0:
				for k in nbn:
					var cx: float = r2.end.x - 8.0 - float(nbn - 1 - k) * 6.5
					var cy: float = r2.position.y + r2.size.y - 12.0
					if k < have:
						draw_circle(Vector2(cx, cy), 2.6, Color(0.55, 0.9, 1.0, 0.95))
					else:
						draw_arc(Vector2(cx, cy), 2.4, 0.0, TAU, 10, Color(0.55, 0.9, 1.0, 0.35), 1.0)
