# v51_1: окно итогового голосования. Зал заседаний загорается место за местом — зелёным «за», красным «против»,
# серым «воздержались»; табло считает голоса, черта показывает, сколько нужно; в конце — «ПРИНЯТ» или «ОТКЛОНЁН»
# и таблица по фракциям: кто нарушил дисциплину.
extends "res://scripts/ui/ui_treaty.gd"

var vt_ov: Control = null
var vt_hall: Control = null
var vt_title: Label = null
var vt_sub: Label = null
var vt_board: RichTextLabel = null
var vt_table: RichTextLabel = null
var vt_btn: Button = null
var vt_seats: Array = []       # [Vector2 позиция, партия, голос 0 за/1 против/2 воздержался, порядок]
var vt_t := 0.0                # 0..1 — ход анимации
var vt_tw: Tween = null
var vt_data := {}


func vote_show() -> void:
	if last_vote.is_empty() or bool(last_vote.get("bypass", false)):
		return
	if int(last_vote.get("sponsor", -1)) != 0 or observer:
		return
	if DisplayServer.get_name() == "headless" or OS.get_cmdline_args().has("--script") or OS.get_cmdline_args().has("-s"):
		if not OS.get_cmdline_user_args().has("vote=1"):
			return
	vt_data = last_vote.duplicate(true)
	if vt_ov == null:
		vote_build()
	vote_layout_seats()
	var tp: Dictionary = law_index.get(String(vt_data["tid"]), {})
	vt_title.text = "Голосование: «%s»" % String(tp.get("name", "закон"))
	vt_sub.text = "Вариант: %s · нужно %d голосов из %d" % [String(variant_of(String(vt_data["tid"]), int(vt_data["idx"]))["n"]), int(vt_data["need"]), SEATS]
	vt_table.text = ""
	vt_btn.text = "Пропустить ▶▶"
	vt_ov.visible = true
	win_fade_in(vt_ov, 0.2)
	vt_t = 0.0
	if vt_tw != null:
		vt_tw.kill()
	vt_tw = create_tween()
	vt_tw.tween_method(vote_step, 0.0, 1.0, 3.6)
	vt_tw.tween_callback(vote_done)
	set_speed(0)


func vote_build() -> void:
	vt_ov = Control.new()
	vt_ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vt_ov.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(vt_ov)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vt_ov.add_child(dim)
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", sbox(C_PANEL, C_ACCENT.darkened(0.15), 2, 14, 16.0, 12.0))
	pan.anchor_left = 0.5
	pan.anchor_right = 0.5
	pan.anchor_top = 0.5
	pan.anchor_bottom = 0.5
	pan.offset_left = -380.0
	pan.offset_right = 380.0
	pan.offset_top = -300.0
	pan.offset_bottom = 300.0
	vt_ov.add_child(pan)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	pan.add_child(vb)
	vt_title = Label.new()
	vt_title.add_theme_font_size_override("font_size", 21)
	vt_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vt_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(vt_title)
	vt_sub = Label.new()
	vt_sub.add_theme_font_size_override("font_size", 13)
	vt_sub.add_theme_color_override("font_color", C_DIM)
	vt_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(vt_sub)
	vt_hall = Control.new()
	vt_hall.custom_minimum_size = Vector2(0.0, 250.0)
	vt_hall.draw.connect(vote_draw)
	vt_hall.resized.connect(vote_layout_seats)
	vb.add_child(vt_hall)
	vt_board = RichTextLabel.new()
	vt_board.bbcode_enabled = true
	vt_board.fit_content = true
	vt_board.scroll_active = false
	vb.add_child(vt_board)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(sc)
	vt_table = RichTextLabel.new()
	vt_table.bbcode_enabled = true
	vt_table.fit_content = true
	vt_table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(vt_table)
	vt_btn = Button.new()
	vt_btn.focus_mode = Control.FOCUS_NONE
	vt_btn.custom_minimum_size = Vector2(0.0, 36.0)
	vt_btn.pressed.connect(func() -> void:
		if vt_t < 1.0:
			if vt_tw != null:
				vt_tw.kill()
			vote_step(1.0)
			vote_done()
		else:
			vt_ov.visible = false
			refresh())
	vb.add_child(vt_btn)


# места полукругом: ряды от внутреннего к внешнему, фракции — секторами слева направо
func vote_layout_seats() -> void:
	vt_seats.clear()
	if vt_hall == null or vt_data.is_empty():
		return
	var w: float = maxf(200.0, vt_hall.size.x)
	var h: float = maxf(120.0, vt_hall.size.y)
	var n: int = SEATS
	var rows: int = clampi(int(sqrt(float(n) / 6.0)), 4, 14)
	var r0: float = h * 0.32
	var r1: float = minf(h * 0.95, w * 0.48)
	var caps: Array = []
	var tot_len := 0.0
	for r in rows:
		var rr: float = lerpf(r0, r1, float(r) / float(maxi(1, rows - 1)))
		caps.append(rr)
		tot_len += rr
	var pts: Array = []
	var left := n
	for r in rows:
		var k: int = int(round(float(n) * float(caps[r]) / tot_len)) if r < rows - 1 else left
		k = clampi(k, 1, left)
		left -= k
		for i in k:
			var a: float = PI - PI * (float(i) + 0.5) / float(k)
			pts.append([a, Vector2(w * 0.5 + cos(a) * float(caps[r]), h - 8.0 - sin(a) * float(caps[r]))])
		if left <= 0:
			break
	pts.sort_custom(func(x, y): return float(x[0]) > float(y[0]))
	# порядок фракций по полукругу
	var seq: Array = []
	var per := {}
	for it in vt_data["per"]:
		per[int(it[0])] = it
	for p in HEMI_ORDER:
		if not per.has(int(p)):
			continue
		var it: Array = per[int(p)]
		for j in int(it[3]):
			seq.append([int(p), 0])
		for j in int(it[4]):
			seq.append([int(p), 1])
		for j in int(it[5]):
			seq.append([int(p), 2])
	for p in per:
		if not (int(p) in HEMI_ORDER):
			var it2: Array = per[p]
			for j in int(it2[3]) + int(it2[4]) + int(it2[5]):
				seq.append([int(p), 0 if j < int(it2[3]) else (1 if j < int(it2[3]) + int(it2[4]) else 2)])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(vt_data["tid"]) + str(vt_data["turn"]))
	for i in mini(pts.size(), seq.size()):
		vt_seats.append([pts[i][1], seq[i][0], seq[i][1], rng.randf()])
	vt_hall.queue_redraw()


func vote_step(t: float) -> void:
	vt_t = t
	var y := 0
	var n := 0
	var a := 0
	for st in vt_seats:
		if float(st[3]) <= t:
			match int(st[2]):
				0: y += 1
				1: n += 1
				_: a += 1
	var need: int = int(vt_data.get("need", 0))
	vt_board.text = "[center][font_size=22][color=%s]ЗА %d[/color]   [color=%s]ПРОТИВ %d[/color]   [color=%s]ВОЗДЕРЖАЛИСЬ %d[/color][/font_size]\n[font_size=13][color=%s]нужно %d[/color][/font_size][/center]" % [COL_GOOD, y, COL_BAD, n, COL_DIM, a, COL_DIM, need]
	vt_hall.queue_redraw()


func vote_draw() -> void:
	var c := vt_hall
	if vt_seats.is_empty():
		return
	var dot: float = clampf(260.0 / sqrt(float(maxi(1, vt_seats.size()))), 3.0, 9.0)
	for st in vt_seats:
		var p: int = int(st[1])
		var pc: Color = PARTY_COLORS[p] if p < PARTY_COLORS.size() else Color.GRAY
		var lit: bool = float(st[3]) <= vt_t
		if not lit:
			c.draw_circle(st[0], dot * 0.5, Color(pc.r, pc.g, pc.b, 0.25))
			continue
		var vc: Color = [Color(0.35, 0.80, 0.50), Color(0.93, 0.40, 0.40), Color(0.55, 0.58, 0.66)][int(st[2])]
		c.draw_circle(st[0], dot * 0.55, vc)
		c.draw_arc(st[0], dot * 0.55, 0.0, TAU, 10, Color(pc.r, pc.g, pc.b, 0.9), 1.4, true)
	# черта большинства — дуга-индикатор внизу
	var need: int = int(vt_data.get("need", 0))
	var y := 0
	for st in vt_seats:
		if float(st[3]) <= vt_t and int(st[2]) == 0:
			y += 1
	var w: float = c.size.x
	var bw: float = w * 0.6
	var x0: float = (w - bw) * 0.5
	var yb: float = c.size.y - 4.0
	c.draw_rect(Rect2(x0, yb - 6.0, bw, 6.0), Color(1, 1, 1, 0.08))
	c.draw_rect(Rect2(x0, yb - 6.0, bw * clampf(float(y) / float(maxi(1, SEATS)), 0.0, 1.0), 6.0), Color(0.35, 0.80, 0.50))
	var xn: float = x0 + bw * float(need) / float(maxi(1, SEATS))
	c.draw_line(Vector2(xn, yb - 10.0), Vector2(xn, yb + 2.0), Color(1.0, 0.85, 0.4), 2.0)


func vote_done() -> void:
	vt_t = 1.0
	vote_step(1.0)
	var ok: bool = bool(vt_data.get("passed", false))
	sfx("good" if ok else "bad")
	var t := "[center][font_size=26][b][color=%s]%s[/color][/b][/font_size][/center]\n" % [COL_GOOD if ok else COL_BAD, "ЗАКОН ПРИНЯТ" if ok else "ЗАКОН ОТКЛОНЁН"]
	t += "[table=5][cell][b]Фракция[/b]   [/cell][cell][b]за[/b]  [/cell][cell][b]против[/b]  [/cell][cell][b]возд.[/b]  [/cell][cell][b]дисциплина[/b][/cell]"
	for it in vt_data["per"]:
		var p: int = int(it[0])
		var tot: int = int(it[3]) + int(it[4]) + int(it[5])
		var line_cnt: int = int(it[3]) if bool(it[2]) else int(it[4])
		var reb: int = tot - line_cnt
		t += "[cell][color=#%s]■[/color] %s   [/cell][cell]%d  [/cell][cell]%d  [/cell][cell]%d  [/cell][cell]%s[/cell]" % [(PARTY_COLORS[p] as Color).lightened(0.2).to_html(false), party_abbr(p), int(it[3]), int(it[4]), int(it[5]),
			("[color=%s]единогласно[/color]" % COL_DIM) if reb == 0 else ("[color=%s]%d отступн.[/color]" % [COL_WARN, reb])]
	t += "[/table]"
	vt_table.text = t
	vt_btn.text = "Продолжить"
