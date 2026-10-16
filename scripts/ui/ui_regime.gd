# v51_1: раздел «Политика» при недемократическом режиме. Вместо парламента, партий и опросов — «Вертикаль власти»
# (кланы элиты вокруг правителя), «Инструменты режима», «Настроения и угрозы», «Фасадный парламент» и «Подполье и
# репрессии». Меняется и вид: своя палитра и эмблема у каждого режима, заставка при смене строя.
extends "res://scripts/ui/ui_vote.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func es_skin_acc(desk: int) -> Color:
	return Color.WHITE


# --- конец заглушек ---


# палитры режимов: акцент, фон, рамка, эмблема
const REG_SKIN := {
	"hybrid": {"acc": Color(0.56, 0.66, 0.82), "bg": Color(0.055, 0.062, 0.078), "border": Color(0.22, 0.25, 0.31), "emb": "hall", "gold": Color(0.78, 0.82, 0.90)},
	"dictatorship": {"acc": Color(0.86, 0.26, 0.24), "bg": Color(0.075, 0.040, 0.042), "border": Color(0.32, 0.14, 0.14), "emb": "star", "gold": Color(0.92, 0.74, 0.36)},
	"junta": {"acc": Color(0.66, 0.70, 0.36), "bg": Color(0.056, 0.064, 0.044), "border": Color(0.25, 0.28, 0.17), "emb": "shield", "gold": Color(0.86, 0.80, 0.50)},
	"oneparty": {"acc": Color(0.90, 0.30, 0.22), "bg": Color(0.080, 0.042, 0.036), "border": Color(0.36, 0.16, 0.12), "emb": "star", "gold": Color(0.98, 0.80, 0.30)},
	"monarchy_abs": {"acc": Color(0.84, 0.68, 0.32), "bg": Color(0.066, 0.046, 0.086), "border": Color(0.30, 0.22, 0.36), "emb": "crown", "gold": Color(0.95, 0.82, 0.45)},
	"theocracy": {"acc": Color(0.32, 0.74, 0.48), "bg": Color(0.040, 0.070, 0.055), "border": Color(0.15, 0.30, 0.22), "emb": "faith", "gold": Color(0.90, 0.85, 0.55)},
}
const REG_POL_DESKS := [1, 3, 4, 6, 11, 12]
const REG_HIDE_AUTH := ["parliament", "parties", "party", "polls", "opp", "pacts", "neg"]
const REG_HIDE_HYB := ["party", "polls"]
const REG_WINS_HYB := ["reg_vert", "reg_tools", "reg_mood"]
const REG_TOOL_GROUPS := [["Страх и репрессии", ["arrests", "amnesty", "censor"]], ["Пропаганда и культ", ["prop_up", "prop_dn", "cult", "decult"]],
	["Выборы", ["fraud_up", "fraud_dn", "referendum"]], ["Будущее режима", ["succ", "promise", "plenum_c", "plenum_r", "fatwa", "lib", "constitution", "roundtable"]]]

var ui_reg_cls := ""
var rg_head: Control = null
var rg_map: Control = null
var rg_clan_box: VBoxContainer = null
var rg_clan_rows := {}
var rg_tool_btns := {}
var rg_meters: Control = null
var rg_gauge: Control = null
var rg_mood_rt: RichTextLabel = null
var rg_log_rt: RichTextLabel = null
var rg_facade: Control = null
var rg_facade_rt: RichTextLabel = null
var rg_und_box: VBoxContainer = null
var rg_und_rows := {}
var rg_repr_rt: RichTextLabel = null
var rg_repr_btns := {}
var rg_trans: Control = null
var rg_clan_cls := ""


func reg_skin() -> Dictionary:
	return REG_SKIN.get(ui_reg_cls, {})


func reg_acc() -> Color:
	return reg_skin().get("acc", C_ACCENT)


# ---------- окна ----------
func build_regime_windows() -> void:
	var w: FloatWindow = new_window("reg_vert", "Вертикаль власти", 1, Rect2(0.0, 0.0, 0.28, 0.60))
	rg_head = Control.new()
	rg_head.custom_minimum_size = Vector2(0.0, 64.0)
	rg_head.draw.connect(reg_draw_head)
	w.body.add_child(rg_head)
	rg_map = Control.new()
	rg_map.custom_minimum_size = Vector2(0.0, 200.0)
	rg_map.draw.connect(reg_draw_map)
	w.body.add_child(rg_map)
	rg_clan_box = VBoxContainer.new()
	rg_clan_box.add_theme_constant_override("separation", 4)
	w.body.add_child(rg_clan_box)
	add_note(w.body, "Награда: должности и контракты — лояльность клана растёт, его влияние тоже, остальные ревнуют. Чистка: влияние клана падает, остальные притихают; загнанный в угол клан может ответить мятежом.")

	w = new_window("reg_tools", "Инструменты режима", 1, Rect2(0.28, 0.0, 0.22, 1.0))
	rg_meters = Control.new()
	rg_meters.custom_minimum_size = Vector2(0.0, 92.0)
	rg_meters.draw.connect(reg_draw_meters)
	w.body.add_child(rg_meters)
	for grp in REG_TOOL_GROUPS:
		add_title(w.body, String(grp[0]))
		for id in grp[1]:
			var a := au_act_def(String(id))
			var b := make_button(String(a[1]), w.body)
			b.theme_type_variation = "SmallButton"
			b.tooltip_text = String(a[5])
			b.pressed.connect(reg_do.bind(String(id)))
			rg_tool_btns[String(id)] = b

	w = new_window("reg_mood", "Настроения и угрозы", 1, Rect2(0.50, 0.0, 0.205, 0.64))
	rg_gauge = Control.new()
	rg_gauge.custom_minimum_size = Vector2(0.0, 150.0)
	rg_gauge.draw.connect(reg_draw_gauge)
	w.body.add_child(rg_gauge)
	rg_mood_rt = make_rt(w.body)
	add_title(w.body, "Хроника режима")
	rg_log_rt = make_rt(w.body)

	w = new_window("reg_facade", "Фасадный парламент", 1, Rect2(0.0, 0.60, 0.28, 0.40), false)
	rg_facade = Control.new()
	rg_facade.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rg_facade.custom_minimum_size = Vector2(0.0, 90.0)
	rg_facade.draw.connect(reg_draw_facade)
	w.body.add_child(rg_facade)
	rg_facade_rt = make_rt(w.body)

	w = new_window("reg_repr", "Подполье и репрессии", 12, Rect2(0.0, 0.0, 0.35, 1.0))
	rg_repr_rt = make_rt(w.body)
	add_title(w.body, "Подпольные движения")
	rg_und_box = VBoxContainer.new()
	rg_und_box.add_theme_constant_override("separation", 6)
	w.body.add_child(rg_und_box)
	add_title(w.body, "Решения")
	for id in ["arrests", "amnesty", "censor", "lib", "roundtable"]:
		var a2 := au_act_def(id)
		var b2 := make_button(String(a2[1]), w.body)
		b2.tooltip_text = String(a2[5])
		b2.pressed.connect(reg_do.bind(id))
		rg_repr_btns[id] = b2
	for id in ["reg_vert", "reg_tools", "reg_mood", "reg_facade", "reg_repr"]:
		(wins[id] as FloatWindow).visible = false


func reg_do(id: String) -> void:
	if au_act(id):
		sfx("good")
	else:
		sfx("bad")
	refresh()


func win_mode_ok(id: String) -> bool:
	var cls := ui_reg_cls
	if cls == "" or cls == "dem":
		return not id.begins_with("reg_")
	if cls == "hybrid":
		return not (id in REG_HIDE_HYB) and (not id.begins_with("reg_") or id in REG_WINS_HYB)
	return not (id in REG_HIDE_AUTH)


# ---------- смена режима: раскладка, вкладки, палитра ----------
func reg_ui_sync() -> void:
	if au.is_empty() or wins.is_empty():
		return
	var cls := regime_class()
	if cls != String(au["cls"]):
		au_set_class(cls)
	if cls == ui_reg_cls:
		return
	var first: bool = ui_reg_cls == ""
	ui_reg_cls = cls
	reg_layout()
	reg_apply_skin()
	reg_tabs()
	reg_build_rows()
	if not first and cls != "dem":
		reg_transition()
	if not first:
		show_desk(current_desk)


func reg_layout() -> void:
	var lay := {}
	if ui_reg_cls == "hybrid":
		lay = {"reg_vert": Rect2(0.28, 0.0, 0.22, 0.58), "reg_tools": Rect2(0.28, 0.58, 0.22, 0.42), "reg_mood": Rect2(0.50, 0.0, 0.205, 0.64)}
	elif ui_reg_cls != "dem":
		lay = {"reg_vert": Rect2(0.0, 0.0, 0.28, 0.60), "reg_facade": Rect2(0.0, 0.60, 0.28, 0.40), "reg_tools": Rect2(0.28, 0.0, 0.22, 1.0),
			"reg_mood": Rect2(0.50, 0.0, 0.205, 0.64), "reg_repr": Rect2(0.0, 0.0, 0.35, 1.0)}
	for id in lay:
		var w: FloatWindow = wins[id]
		w.frac = lay[id]
		w.default_frac = lay[id]
		w.closed = false
		w.apply_frac()


func reg_tabs() -> void:
	if sub_buttons.size() < 6:
		return
	var auth: bool = ui_reg_cls != "dem" and ui_reg_cls != "hybrid"
	var n0: String = "Парламент" if ui_reg_cls == "dem" else "Вертикаль власти"
	var n5: String = "Подполье и репрессии" if auth else "Оппозиция и сделки"
	reg_tab_set(sub_buttons[0], n0, "hall" if ui_reg_cls == "dem" else String(reg_skin().get("emb", "hall")))
	reg_tab_set(sub_buttons[5], n5, "shield" if auth else "person")


func reg_tab_set(b: Button, txt: String, ico: String) -> void:
	for ch in b.get_children():
		ch.queue_free()
	b.text = txt
	btn_icon(b, ico, Color(0.78, 0.86, 1.0) if ui_reg_cls == "dem" else reg_acc().lightened(0.25))


func reg_apply_skin() -> void:
	settings_apply_static()
	var sk := reg_skin()
	if not sk.is_empty():
		var acc: Color = sk["acc"]
		C_BG = (sk["bg"] as Color).lerp(C_BG, 0.25)
		C_PANEL = C_BG.lightened(0.05).lerp(acc, 0.04)
		C_PANEL2 = C_BG.lightened(0.09).lerp(acc, 0.06)
		C_BORDER = sk["border"]
		C_ACCENT = acc
	theme = make_theme()
	if ui_bg != null:
		ui_bg.color = C_BG
		if not ui_bg.draw.is_connected(reg_draw_watermark):
			ui_bg.draw.connect(reg_draw_watermark)
		ui_bg.queue_redraw()
	if ui_top != null:
		var tsb := sbox(C_PANEL, C_BORDER, 0, 0, 10.0, 6.0)
		tsb.border_width_bottom = 1
		tsb.shadow_color = Color(0, 0, 0, 0.45)
		tsb.shadow_size = 8
		tsb.shadow_offset = Vector2(0.0, 2.0)
		ui_top.add_theme_stylebox_override("panel", tsb)
		ui_top.queue_redraw()
	for id in wins:
		var w: FloatWindow = wins[id]
		if sk.is_empty():
			w.set_skin(es_skin_acc(w.desk), Color(0.090, 0.106, 0.149), Color(0.169, 0.196, 0.282))
		elif w.desk in REG_POL_DESKS:
			w.set_skin(C_ACCENT, C_PANEL, C_BORDER)
		else:
			w.set_skin(es_skin_acc(w.desk), C_PANEL, C_BORDER)


# большая бледная эмблема режима на фоне рабочей области
func reg_draw_watermark() -> void:
	var sk := reg_skin()
	if sk.is_empty() or ui_bg == null:
		return
	var sz: Vector2 = ui_bg.size
	var r: float = minf(sz.x, sz.y) * 0.30
	reg_emblem(ui_bg, ui_reg_cls, Vector2(sz.x * 0.86, sz.y * 0.62), r, Color(sk["acc"].r, sk["acc"].g, sk["acc"].b, 0.06), 0.06)


# эмблема: кольцо, лавры или лучи, знак режима в центре
func reg_emblem(c: CanvasItem, cls: String, p: Vector2, r: float, col: Color, alpha_gold: float = 1.0) -> void:
	var sk: Dictionary = REG_SKIN.get(cls, {})
	if sk.is_empty():
		return
	var gold: Color = sk["gold"]
	gold.a = alpha_gold if alpha_gold < 1.0 else 0.95
	c.draw_circle(p, r, Color(col.r, col.g, col.b, col.a * (0.35 if alpha_gold < 1.0 else 0.25)))
	c.draw_arc(p, r, 0.0, TAU, 64, gold, maxf(1.5, r * 0.05), true)
	c.draw_arc(p, r * 0.84, 0.0, TAU, 64, Color(gold.r, gold.g, gold.b, gold.a * 0.6), maxf(1.0, r * 0.02), true)
	match cls:
		"dictatorship", "monarchy_abs":
			# лавровые ветви
			for side in [-1.0, 1.0]:
				for k in 7:
					var a: float = PI * 0.5 + side * (0.35 + float(k) * 0.32)
					var q: Vector2 = p + Vector2(cos(a), sin(a)) * r * 0.92
					var tang: Vector2 = Vector2(-sin(a), cos(a)) * float(side)
					c.draw_line(q, q + (tang * 0.6 + (q - p).normalized() * 0.5) * r * 0.16, gold, maxf(1.2, r * 0.035), true)
		"oneparty", "theocracy":
			for k in 16:
				var a2: float = TAU * float(k) / 16.0
				c.draw_line(p + Vector2(cos(a2), sin(a2)) * r * 1.04, p + Vector2(cos(a2), sin(a2)) * r * 1.18, gold, maxf(1.0, r * 0.03), true)
		"junta":
			for side2 in [-1.0, 1.0]:
				c.draw_line(p + Vector2(-0.75 * side2, 0.75) * r, p + Vector2(0.75 * side2, -0.75) * r, Color(gold.r, gold.g, gold.b, gold.a * 0.8), maxf(1.5, r * 0.06), true)
		"hybrid":
			for k2 in 3:
				var yy: float = p.y + r * (0.25 + 0.2 * float(k2)) - r * 0.1
				var hw: float = r * (0.25 + 0.18 * float(k2))
				c.draw_line(Vector2(p.x - hw, yy + r * 0.12), Vector2(p.x + hw, yy + r * 0.12), Color(gold.r, gold.g, gold.b, gold.a * 0.7), maxf(1.0, r * 0.04), true)
	var u: float = r * 1.05
	var emb: String = String(sk["emb"])
	if emb == "star":
		Gfx.star(c, p, r * 0.55, gold, Color(0, 0, 0, gold.a * 0.4))
	else:
		Ico.draw_icon(emb, p - Vector2(u, u) * 0.5, u, maxf(1.6, r * 0.07), gold, c)


# заставка при смене режима
func reg_transition() -> void:
	if DisplayServer.get_name() == "headless" or OS.get_cmdline_args().has("--script") or OS.get_cmdline_args().has("-s"):
		if not OS.get_cmdline_user_args().has("regime=1"):
			return
	if rg_trans != null and is_instance_valid(rg_trans):
		rg_trans.queue_free()
	var cls := ui_reg_cls
	rg_trans = Control.new()
	rg_trans.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rg_trans.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(rg_trans)
	var ov := rg_trans
	ov.draw.connect(func() -> void:
		var sz: Vector2 = ov.size
		ov.draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, 0.78))
		var sk: Dictionary = REG_SKIN.get(cls, {})
		var acc: Color = sk.get("acc", C_ACCENT)
		Gfx.hgrad(ov, Rect2(0.0, sz.y * 0.5 - 150.0, sz.x * 0.5, 300.0), Color(acc.r, acc.g, acc.b, 0.0), Color(acc.r, acc.g, acc.b, 0.22))
		Gfx.hgrad(ov, Rect2(sz.x * 0.5, sz.y * 0.5 - 150.0, sz.x * 0.5, 300.0), Color(acc.r, acc.g, acc.b, 0.22), Color(acc.r, acc.g, acc.b, 0.0))
		reg_emblem(ov, cls, Vector2(sz.x * 0.5, sz.y * 0.5 - 40.0), 80.0, acc)
		var f: Font = ov.get_theme_default_font()
		Gfx.label(ov, f, Vector2(0.0, sz.y * 0.5 + 78.0), "СМЕНА РЕЖИМА", 16, Color(0.85, 0.85, 0.85), sz.x, HORIZONTAL_ALIGNMENT_CENTER)
		Gfx.label(ov, f, Vector2(0.0, sz.y * 0.5 + 116.0), au_class_name(cls).to_upper(), 34, (sk.get("gold", Color.WHITE) as Color), sz.x, HORIZONTAL_ALIGNMENT_CENTER)
		Gfx.label(ov, f, Vector2(0.0, sz.y * 0.5 + 146.0), String(AU_CLASS_MOTTO.get(cls, "")), 15, Color(0.80, 0.82, 0.88), sz.x, HORIZONTAL_ALIGNMENT_CENTER))
	ov.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			ov.queue_free())
	ov.modulate.a = 0.0
	var tw := ov.create_tween()
	tw.tween_property(ov, "modulate:a", 1.0, 0.5)
	tw.tween_interval(2.4)
	tw.tween_property(ov, "modulate:a", 0.0, 0.7)
	tw.tween_callback(ov.queue_free)
	sfx("bad")


# ---------- строки кланов и движений ----------
func reg_build_rows() -> void:
	if rg_clan_box == null or ui_reg_cls == rg_clan_cls:
		return
	rg_clan_cls = ui_reg_cls
	for ch in rg_clan_box.get_children():
		ch.queue_free()
	for ch in rg_und_box.get_children():
		ch.queue_free()
	rg_clan_rows.clear()
	rg_und_rows.clear()
	if ui_reg_cls == "dem":
		return
	for c in AU_CLANS[ui_reg_cls]:
		var id: String = String(c[0])
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 5)
		rg_clan_box.add_child(hb)
		var ic: Control = Ico.make(String(c[2]), reg_acc().lightened(0.2), 16.0)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(ic)
		var l := Label.new()
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # v55_3: «Олигархи и госкорпорации — 55%» не обрезается
		l.add_theme_font_size_override("font_size", 13)
		hb.add_child(l)
		var br := Button.new()
		br.text = "Наградить"
		br.theme_type_variation = "SmallButton"
		br.focus_mode = Control.FOCUS_NONE
		br.pressed.connect(reg_do.bind("reward:" + id))
		hb.add_child(br)
		var bp := Button.new()
		bp.text = "Чистка"
		bp.theme_type_variation = "SmallButton"
		bp.focus_mode = Control.FOCUS_NONE
		bp.pressed.connect(reg_do.bind("purge:" + id))
		hb.add_child(bp)
		rg_clan_rows[id] = {"l": l, "r": br, "p": bp}
	for u in AU_UNDER[ui_reg_cls]:
		var uid: String = String(u[0])
		var bar := Control.new()
		bar.custom_minimum_size = Vector2(0.0, 34.0)
		bar.draw.connect(reg_draw_und.bind(bar, uid))
		rg_und_box.add_child(bar)
		rg_und_rows[uid] = bar


func update_regime_windows() -> void:
	if ui_reg_cls == "" or ui_reg_cls == "dem" or au.is_empty():
		return
	reg_build_rows()
	rg_head.queue_redraw()
	rg_map.queue_redraw()
	rg_meters.queue_redraw()
	rg_gauge.queue_redraw()
	rg_facade.queue_redraw()
	for id in rg_clan_rows:
		if not (au["cl"] as Dictionary).has(id):
			continue
		var e: Dictionary = au["cl"][id]
		var row: Dictionary = rg_clan_rows[id]
		var loy: float = float(e["loy"])
		var col: String = COL_GOOD if loy >= 55.0 else (COL_WARN if loy >= 35.0 else COL_BAD)
		(row["l"] as Label).text = "%s — %.0f%%" % [String(au_clan_def(id)[1]), loy]
		(row["l"] as Label).add_theme_color_override("font_color", Color(col))
		(row["l"] as Label).tooltip_text = "Лояльность %.0f из 100, влияние %.0f%%. %s" % [loy, float(e["w"]) * 100.0, reg_clan_hint(id)]
		for k in ["r", "p"]:
			var why := au_check(("reward:" if k == "r" else "purge:") + id)
			var b: Button = row[k]
			b.disabled = why != ""
			b.tooltip_text = ("Наградить (капитал 6, 0,1% ВВП)" if k == "r" else "Чистка (капитал 8)") + ("" if why == "" else "\nСейчас нельзя: " + why)
	for id in rg_tool_btns:
		var b2: Button = rg_tool_btns[id]
		var a := au_act_def(id)
		var cls_req: String = String(a[4])
		b2.visible = cls_req == "" or ui_reg_cls in cls_req.split(",")
		var why2 := au_check(id)
		b2.disabled = why2 != ""
		var nm: String = String(a[1])
		if id == "censor":
			nm = "Отменить цензуру интернета" if bool(au.get("censor", false)) else "Ввести цензуру интернета"
		b2.text = nm + (" (%.0f)" % float(a[2]) if float(a[2]) > 0.0 else "") + ("" if why2 == "" or why2.begins_with("нужно") else " — " + why2)
		b2.tooltip_text = String(a[5]) + ("" if why2 == "" else "\nСейчас нельзя: " + why2)
	for id in rg_repr_btns:
		var b3: Button = rg_repr_btns[id]
		var a3 := au_act_def(id)
		var why3 := au_check(id)
		b3.disabled = why3 != ""
		var nm3: String = String(a3[1])
		if id == "censor":
			nm3 = "Отменить цензуру интернета" if bool(au.get("censor", false)) else "Ввести цензуру интернета"
		b3.text = nm3 + (" (капитал %.0f)" % float(a3[2]) if float(a3[2]) > 0.0 else "") + ("" if why3 == "" else " — " + why3)
	for uid in rg_und_rows:
		(rg_und_rows[uid] as Control).queue_redraw()
	# настроения
	var t := ""
	var real := approval()
	var off := au_official_approval()
	t += "Официальный рейтинг: [b]%.0f%%[/b] · на самом деле: [b]%.0f%%[/b]\n" % [off, real]
	if au_auth():
		var colr := COL_GOOD if regime_risk < 35.0 else (COL_WARN if regime_risk < 60.0 else COL_BAD)
		t += "Риск переворота или восстания: [b][color=%s]%.0f%%[/color][/b]\n" % [colr, regime_risk]
	var ra := au_risk_add()
	t += "Угроза от элит и подполья: [b]%.0f[/b] пунктов риска\n" % ra
	t += "Усталость от правителя: %s%s\n" % [months_text(au_fat_months()), " · преемник назван" if String(au.get("succ", "")) != "" else ""]
	t += "Политзаключённых: [b]%d[/b] · цензура: %s\n" % [int(au["pris"]), "есть" if bool(au.get("censor", false)) else "нет"]
	if au_lib():
		t += "[color=%s]Идёт оттепель (ещё %s): подполье смелее, реформаторы на подъёме.[/color]\n" % [COL_WARN, months_text(24 - (turn - int(au["lib_t"])))]
	if ui_reg_cls == "junta" and int(au.get("promise", -1)) > 0:
		var left: int = int(au["promise"]) - turn
		t += ("[color=%s]Обещание передать власть гражданским: осталось %s.[/color]\n" % [COL_WARN, months_text(left)]) if left > 0 else ("[color=%s]Обещание нарушено — недовольство растёт.[/color]\n" % COL_BAD)
	if ui_reg_cls == "hybrid":
		t += "[color=%s]Выборы проводятся: партия власти получает «административный ресурс» (+%.0f п. п.), но после выборов с фальсификациями возможны протесты.[/color]" % [COL_DIM, float(au["fraud"]) * 0.3]
	rg_mood_rt.text = t
	var lg: Array = au.get("log", [])
	rg_log_rt.text = "[font_size=12]%s[/font_size]" % ("\n".join(lg.slice(0, 6)) if lg.size() > 0 else "[color=%s]Пока ничего не происходило.[/color]" % COL_DIM)
	rg_facade_rt.text = "[font_size=12]Парламент собирается, чтобы единогласно одобрять указы. Следующие «выборы без выбора»: %s.[/font_size]" % date_after(maxi(0, parl_term() - (turn - last_parl)))
	var tot: int = int(au["pris"])
	rg_repr_rt.text = "Режим: [b]%s[/b]. Политзаключённых: [b]%d[/b]. Страх: [b]%.0f[/b] из 100. Подполье крепнет, когда рейтинг низкий, выборы подделаны и страх слабеет; аресты его ослабляют, но злят молодёжь и демократии.%s" % [au_class_name(), tot, float(au["fear"]),
		"" if au_und_max() < 60.0 else "\n[color=%s]Подполье сильно: возможны массовые выступления.[/color]" % COL_BAD]


func reg_clan_hint(id: String) -> String:
	match String(au_clan_def(id)[3]):
		"force": return "Силовикам нужны деньги на армию, поддержка «силовой» группы и страх в обществе; оттепель их пугает."
		"money": return "Деньгам нужен рост экономики и рыночные правила; дефицит и план их злят."
		"reg": return "Регионам нужен покой: недовольство на местах бьёт по их лояльности."
		"apparat": return "Аппарату нужны капитал власти и культ правителя."
		"ideo_c": return "Консерваторы и духовенство любят порядок, страх и пропаганду; оттепель им чужда."
		"ideo_r": return "Реформаторы ждут оттепели и реформ; страх и культ их отталкивают."
	return ""


# ---------- рисование ----------
func reg_draw_head() -> void:
	var c := rg_head
	var sz: Vector2 = c.size
	var sk := reg_skin()
	if sk.is_empty():
		return
	var acc: Color = sk["acc"]
	Gfx.hgrad(c, Rect2(Vector2.ZERO, sz), Color(acc.r, acc.g, acc.b, 0.28), Color(acc.r, acc.g, acc.b, 0.0))
	reg_emblem(c, ui_reg_cls, Vector2(32.0, sz.y * 0.5), 26.0, acc)
	var f: Font = c.get_theme_default_font()
	# v54_1: длинное название режима (особенно по-английски) уменьшает шрифт, а не обрезается
	var cnm: String = au_class_name().to_upper()
	var cfs := 18
	while cfs > 11 and f.get_string_size(cnm, HORIZONTAL_ALIGNMENT_LEFT, -1, cfs).x > sz.x - 72.0:
		cfs -= 1
	c.draw_string(f, Vector2(68.0, 26.0), cnm, HORIZONTAL_ALIGNMENT_LEFT, sz.x - 72.0, cfs, sk["gold"])
	c.draw_string(f, Vector2(68.0, 46.0), String(AU_CLASS_MOTTO.get(ui_reg_cls, "")), HORIZONTAL_ALIGNMENT_LEFT, sz.x - 72.0, 11, Color(0.80, 0.82, 0.88))


func reg_loy_col(loy: float) -> Color:
	if loy >= 55.0:
		return Color(0.40, 0.80, 0.52)
	if loy >= 35.0:
		return Color(0.93, 0.76, 0.32)
	return Color(0.92, 0.38, 0.36)


# правитель вверху, кланы дугой ниже: размер круга — влияние, цвет — лояльность, толщина связи — лояльность
func reg_draw_map() -> void:
	var c := rg_map
	if au.is_empty() or not au_on():
		return
	var sz: Vector2 = c.size
	var sk := reg_skin()
	var f: Font = c.get_theme_default_font()
	var top := Vector2(sz.x * 0.5, 30.0)
	var ids: Array = (au["cl"] as Dictionary).keys()
	var n: int = ids.size()
	var pts: Array = []
	# кланы — в ряд под правителем, через один чуть ниже, чтобы подписи не налезали
	var colw: float = sz.x / float(maxi(1, n))
	for k in n:
		pts.append(Vector2(colw * (float(k) + 0.5), top.y + 62.0 + float(k % 2) * 34.0))
	for k in n:
		var e: Dictionary = au["cl"][ids[k]]
		var loy: float = float(e["loy"])
		var lc := reg_loy_col(loy)
		var wd: float = 1.0 + loy / 100.0 * 4.0
		if loy < 30.0:
			var seg := 10
			for s in seg:
				if s % 2 == 0:
					c.draw_line(top.lerp(pts[k], float(s) / seg), top.lerp(pts[k], float(s + 1) / seg), Color(lc.r, lc.g, lc.b, 0.7), wd, true)
		else:
			c.draw_line(top, pts[k], Color(lc.r, lc.g, lc.b, 0.75), wd, true)
	reg_emblem(c, ui_reg_cls, top, 22.0, sk.get("acc", C_ACCENT))
	c.draw_string(f, Vector2(0.0, sz.y - 4.0), "кольцо — лояльность, размер — влияние", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 11, Color(0.65, 0.68, 0.76))
	for k in n:
		var id: String = String(ids[k])
		var e2: Dictionary = au["cl"][id]
		var r: float = minf(12.0 + float(e2["w"]) * 50.0, colw * 0.38)
		var lc2 := reg_loy_col(float(e2["loy"]))
		c.draw_circle(pts[k], r + 2.0, Color(0, 0, 0, 0.5))
		c.draw_circle(pts[k], r, lc2.darkened(0.55))
		c.draw_arc(pts[k], r, -PI * 0.5, -PI * 0.5 + TAU * float(e2["loy"]) / 100.0, 32, lc2, 3.0, true)
		var cd := au_clan_def(id)
		Ico.draw_icon(String(cd[2]), pts[k] - Vector2(r, r) * 0.55, r * 1.1, 1.6, Color(0.95, 0.95, 0.95, 0.9), c)
		var nm: String = String(cd[1]).split(" ")[0]
		var lw: float = colw * 1.5
		var lx: float = clampf(pts[k].x - lw * 0.5, 0.0, maxf(0.0, sz.x - lw))
		Gfx.label(c, f, Vector2(lx, pts[k].y + r + 14.0), nm, 12, Color(0.92, 0.93, 0.96), lw, HORIZONTAL_ALIGNMENT_CENTER, 3)
		Gfx.label(c, f, Vector2(lx, pts[k].y + r + 27.0), "%.0f%% · %.0f%%" % [float(e2["loy"]), float(e2["w"]) * 100.0], 11, lc2, lw, HORIZONTAL_ALIGNMENT_CENTER, 3)


# уровни рычагов: страх, пропаганда, фальсификации, культ (5 ступеней)
func reg_draw_meters() -> void:
	var c := rg_meters
	if au.is_empty() or not au_on():
		return
	var sz: Vector2 = c.size
	var f: Font = c.get_theme_default_font()
	var rows := [["Страх", float(au["fear"]), Color(0.85, 0.35, 0.35)], ["Пропаганда", float(au["prop"]), Color(0.95, 0.70, 0.30)],
		["Фальсификации", float(au["fraud"]), Color(0.70, 0.55, 0.95)]]
	var y := 4.0
	for r in rows:
		c.draw_string(f, Vector2(0.0, y + 12.0), String(r[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.80, 0.83, 0.90))
		var x0: float = 104.0
		var bw: float = sz.x - x0 - 34.0
		c.draw_rect(Rect2(x0, y + 3.0, bw, 10.0), Color(1, 1, 1, 0.07))
		c.draw_rect(Rect2(x0, y + 3.0, bw * clampf(float(r[1]) / 100.0, 0.0, 1.0), 10.0), r[2])
		c.draw_string(f, Vector2(x0 + bw + 4.0, y + 12.0), "%.0f" % float(r[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.85, 0.87, 0.92))
		y += 20.0
	c.draw_string(f, Vector2(0.0, y + 12.0), "Культ личности", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.80, 0.83, 0.90))
	var gold: Color = reg_skin().get("gold", Color(0.95, 0.8, 0.4))
	for k in 5:
		var p := Vector2(112.0 + float(k) * 22.0, y + 8.0)
		if k < int(au["cult"]):
			Gfx.star(c, p, 8.0, gold, Color(0, 0, 0, 0.4))
		else:
			Gfx.star(c, p, 8.0, Color(1, 1, 1, 0.10), Color(1, 1, 1, 0.2))


# официальный и настоящий рейтинг, стрелка риска
func reg_draw_gauge() -> void:
	var c := rg_gauge
	if au.is_empty() or not au_on():
		return
	var sz: Vector2 = c.size
	var f: Font = c.get_theme_default_font()
	var off := au_official_approval()
	var real := approval()
	var bx: float = 8.0
	for k in 2:
		var v: float = off if k == 0 else real
		var col: Color = reg_acc() if k == 0 else Color(0.85, 0.88, 0.95)
		var h: float = (sz.y - 40.0) * clampf(v / 100.0, 0.0, 1.0)
		var x: float = bx + float(k) * 46.0
		c.draw_rect(Rect2(x, 10.0, 34.0, sz.y - 40.0), Color(1, 1, 1, 0.05))
		c.draw_rect(Rect2(x, 10.0 + sz.y - 40.0 - h, 34.0, h), Color(col.r, col.g, col.b, 0.85))
		c.draw_string(f, Vector2(x, 10.0 + sz.y - 40.0 - h - 3.0), "%.0f" % v, HORIZONTAL_ALIGNMENT_CENTER, 34.0, 13, col)
		c.draw_string(f, Vector2(x - 6.0, sz.y - 14.0), "офиц." if k == 0 else "реальн.", HORIZONTAL_ALIGNMENT_CENTER, 46.0, 11, Color(0.75, 0.78, 0.86))
	# полукруглая шкала риска
	var risk: float = regime_risk if au_auth() else clampf(au_risk_add() * 2.0, 0.0, 100.0)
	var cx: float = 110.0 + (sz.x - 110.0) * 0.5
	var R: float = minf((sz.x - 120.0) * 0.45, sz.y * 0.55)
	var cen := Vector2(cx, sz.y * 0.68)
	for k2 in 30:
		var a0: float = PI + PI * float(k2) / 30.0
		var a1: float = PI + PI * float(k2 + 1) / 30.0
		var t: float = float(k2) / 29.0
		var cc: Color = Color(0.40, 0.80, 0.52).lerp(Color(0.93, 0.76, 0.32), clampf(t * 2.0, 0.0, 1.0)).lerp(Color(0.92, 0.34, 0.32), clampf(t * 2.0 - 1.0, 0.0, 1.0))
		c.draw_arc(cen, R, a0, a1, 4, cc, 10.0, true)
	var an: float = PI + PI * clampf(risk / 100.0, 0.0, 1.0)
	c.draw_line(cen, cen + Vector2(cos(an), sin(an)) * (R - 4.0), Color(0.95, 0.95, 0.95), 3.0, true)
	c.draw_circle(cen, 5.0, Color(0.95, 0.95, 0.95))
	c.draw_string(f, Vector2(cen.x - 60.0, cen.y + 22.0), "%.0f%%" % risk, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 18, Color(0.95, 0.95, 0.95))
	c.draw_string(f, Vector2(cen.x - 80.0, cen.y + 38.0), "риск переворота" if au_auth() else "раскол элит", HORIZONTAL_ALIGNMENT_CENTER, 160.0, 11, Color(0.75, 0.78, 0.86))


# фасадный парламент: все места одного цвета, штамп «ОДОБРЕНО»
func reg_draw_facade() -> void:
	var c := rg_facade
	if hemi_pos.is_empty() or seats.is_empty():
		return
	var w: float = c.size.x
	var h: float = c.size.y
	if w < 30.0 or h < 30.0:
		return
	var R: float = minf(w * 0.46, h * 0.92)
	var center := Vector2(w / 2.0, h * 0.97)
	var dot: float = clampf(R * hemi_rad, 1.4, 9.0)
	var assign: Array[int] = []
	for p in HEMI_ORDER:
		for k in seats[p]:
			assign.append(p)
	for i in hemi_pos.size():
		var a: float = hemi_pos[i][0]
		var rr: float = hemi_pos[i][1]
		var pos := center + Vector2(cos(a), -sin(a)) * (R * rr)
		var p2: int = assign[i] if i < assign.size() else 0
		var col: Color = reg_acc() if p2 == 0 else (PARTY_COLORS[p2] as Color).darkened(0.6)
		c.draw_circle(pos, dot, col)
	var f: Font = c.get_theme_default_font()
	var sk := reg_skin()
	var st: Color = sk.get("acc", Color(0.9, 0.3, 0.3))
	var sp := Vector2(w * 0.5, h * 0.62)
	c.draw_set_transform(sp, -0.18, Vector2.ONE)
	c.draw_rect(Rect2(-78.0, -18.0, 156.0, 32.0), Color(0.05, 0.04, 0.04, 0.7))
	c.draw_rect(Rect2(-78.0, -18.0, 156.0, 32.0), Color(st.r, st.g, st.b, 0.85), false, 3.0)
	c.draw_string(f, Vector2(-78.0, 6.0), "ОДОБРЕНО", HORIZONTAL_ALIGNMENT_CENTER, 156.0, 20, Color(st.r, st.g, st.b, 0.9))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func reg_draw_und(bar: Control, uid: String) -> void:
	if au.is_empty() or not (au.get("und", {}) as Dictionary).has(uid):
		return
	var sz: Vector2 = bar.size
	var f: Font = bar.get_theme_default_font()
	var s: float = float(au["und"][uid]["s"])
	var nm: String = String(au_und_def(uid)[1])
	bar.draw_string(f, Vector2(0.0, 13.0), nm, HORIZONTAL_ALIGNMENT_LEFT, sz.x - 50.0, 13, Color(0.90, 0.92, 0.96))
	bar.draw_string(f, Vector2(sz.x - 48.0, 13.0), "%.0f" % s, HORIZONTAL_ALIGNMENT_RIGHT, 48.0, 13, reg_loy_col(100.0 - s))
	bar.draw_rect(Rect2(0.0, 19.0, sz.x, 9.0), Color(1, 1, 1, 0.06))
	var col := reg_loy_col(100.0 - s)
	bar.draw_rect(Rect2(0.0, 19.0, sz.x * clampf(s / 100.0, 0.0, 1.0), 9.0), col)
	# точки-ячейки: чем сильнее движение, тем больше «ячеек»
	var cells: int = int(s / 10.0)
	for k in cells:
		bar.draw_circle(Vector2(sz.x * clampf(s / 100.0, 0.0, 1.0) * (float(k) + 0.5) / float(maxi(1, cells)), 23.5), 2.0, Color(0, 0, 0, 0.35))
