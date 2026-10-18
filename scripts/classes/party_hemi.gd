extends Control
# 0.56: полукруг парламента в меню выбора партии. Места окрашены по партиям (слева направо — как в зале),
# выбранная партия яркая, остальные приглушены; щелчок по месту выбирает партию.

signal picked(p: int)

const EV := preload("res://scripts/classes/election_view.gd")

var order: Array = []       # [{p, col, seats}] слева направо
var total := 0
var maj := 0
var sel := -1
var pts: Array = []         # [Vector2, p] — центры мест в локальных координатах
var rad := 3.0


func _init() -> void:
	custom_minimum_size = Vector2(260.0, 150.0)
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_data(o: Array, tot: int, m: int, s: int) -> void:
	order = o
	total = maxi(1, tot)
	maj = m
	sel = s
	queue_redraw()


func _layout() -> void:
	pts.clear()
	var n := 0
	for it in order:
		n += int(it["seats"])
	if n <= 0:
		return
	var lay: Dictionary = EV.hemi_layout(n)
	var r_out: float = minf(size.x * 0.5 - 6.0, size.y - 22.0)
	var c := Vector2(size.x * 0.5, size.y - 16.0)
	rad = maxf(1.2, float(lay["rad"]) * r_out)
	var k := 0
	var who: Array = []
	for it in order:
		for i in int(it["seats"]):
			who.append(int(it["p"]))
	for q in (lay["pts"] as Array):
		var ang: float = float(q[0])
		var rr: float = float(q[1]) * r_out
		pts.append([c + Vector2(cos(ang), -sin(ang)) * rr, int(who[mini(k, who.size() - 1)])])
		k += 1


func _col_of(p: int) -> Color:
	for it in order:
		if int(it["p"]) == p:
			return it["col"]
	return Color(0.5, 0.5, 0.5)


func _draw() -> void:
	_layout()
	for q in pts:
		var p: int = int(q[1])
		var col: Color = _col_of(p)
		if sel >= 0 and p != sel:
			col = col.darkened(0.55)
			col.a = 0.75
		draw_circle(q[0], rad, col)
		if p == sel:
			draw_arc(q[0], rad + 0.8, 0.0, TAU, 10, Color(1, 1, 1, 0.55), 1.0)
	var f: Font = get_theme_default_font()
	var t := "большинство — %d из %d" % [maj, total]
	draw_string(f, Vector2(0.0, size.y - 2.0), t, HORIZONTAL_ALIGNMENT_CENTER, size.x, 11, Color(0.6, 0.64, 0.74))


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and (e as InputEventMouseButton).pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var best := -1
		var bd := 1e9
		for q in pts:
			var d: float = (q[0] as Vector2).distance_to((e as InputEventMouseButton).position)
			if d < bd:
				bd = d
				best = int(q[1])
		if best >= 0 and bd < rad * 4.0:
			picked.emit(best)
	elif e is InputEventMouseMotion:
		var best2 := -1
		var bd2 := 1e9
		for q in pts:
			var d2: float = (q[0] as Vector2).distance_to((e as InputEventMouseMotion).position)
			if d2 < bd2:
				bd2 = d2
				best2 = int(q[1])
		var nm := ""
		if best2 >= 0 and bd2 < rad * 4.0:
			for it in order:
				if int(it["p"]) == best2:
					nm = "%s — мест: %d" % [String(it.get("name", "")), int(it["seats"])]
		tooltip_text = nm


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
