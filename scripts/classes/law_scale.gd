extends Control
# 0.60: шкала вариантов закона: точки на линии с подписями; щелчок по точке выбирает вариант.
signal picked(i: int)

var labels: PackedStringArray = []
var tips: PackedStringArray = []
var cur := -1       # действующий вариант
var sel := -1       # выбранный для голосования
var c_line := Color(0.169, 0.196, 0.282)
var c_cur := Color(0.345, 0.784, 0.529)
var c_sel := Color(0.357, 0.553, 0.937)
var c_dot := Color(0.122, 0.141, 0.200)
var c_text := Color(0.596, 0.631, 0.722)
var c_hi := Color(0.910, 0.922, 0.957)

func _init() -> void:
	custom_minimum_size = Vector2(60.0, 70.0)
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_stops(l: PackedStringArray, t: PackedStringArray, c: int, s: int) -> void:
	labels = l
	tips = t
	cur = c
	sel = s
	queue_redraw()

func _pos(i: int) -> Vector2:
	var n := labels.size()
	var m := 16.0
	if n <= 1:
		return Vector2(size.x * 0.5, 14.0)
	return Vector2(m + (size.x - 2.0 * m) * float(i) / float(n - 1), 14.0)

func _near(x: float) -> int:
	var best := 0
	var bd := 1e9
	for i in labels.size():
		var d := absf(_pos(i).x - x)
		if d < bd:
			bd = d
			best = i
	return best

func _draw() -> void:
	var n := labels.size()
	if n == 0:
		return
	var font: Font = ThemeDB.fallback_font
	if n > 1:
		draw_line(_pos(0), _pos(n - 1), c_line, 3.0, true)
	var step := (size.x - 32.0) / float(maxi(1, n - 1))
	var wlab := clampf(step - 2.0, 44.0, 120.0)
	for i in n:
		var p := _pos(i)
		var col := c_dot
		var ring := c_line.lightened(0.25)
		if i == cur:
			col = c_cur
			ring = c_cur.lightened(0.3)
		if i == sel and i != cur:
			col = c_sel
			ring = c_sel.lightened(0.3)
		draw_circle(p, 9.0, ring)
		draw_circle(p, 7.5, col)
		var num := str(i + 1)
		draw_string(font, p + Vector2(-3.5 * num.length(), 4.0), num, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, c_hi if (i == cur or i == sel) else c_text)
		var lab := labels[i]
		draw_multiline_string(font, Vector2(clampf(p.x - wlab * 0.5, 0.0, maxf(0.0, size.x - wlab)), 34.0), lab, HORIZONTAL_ALIGNMENT_CENTER, wlab, 10, 3, c_hi if (i == cur or i == sel) else c_text)

func _gui_input(ev: InputEvent) -> void:
	var mb := ev as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and labels.size() > 0:
		picked.emit(_near(mb.position.x))

func _get_tooltip(at_position: Vector2) -> String:
	if labels.is_empty():
		return ""
	var i := _near(at_position.x)
	return tips[i] if i < tips.size() else labels[i]
