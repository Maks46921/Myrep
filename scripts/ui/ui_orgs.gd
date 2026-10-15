# v52_1: рамка «Организации». Вкладки — международные организации (ваши — с отметкой ●). Окна: шапка организации,
# члены (флаги, отношения, позиция по текущему вопросу), «Что даёт и чего требует», действия, сессия и голосование.
extends "res://scripts/ui/ui_econsys.gd"

const IO_TYPE_COL := {"global": Color(0.36, 0.62, 0.95), "eu": Color(0.30, 0.45, 0.90), "security": Color(0.88, 0.36, 0.34), "rights": Color(0.66, 0.50, 0.92),
	"econ": Color(0.36, 0.78, 0.52), "regional": Color(0.30, 0.74, 0.74), "eurasia": Color(0.93, 0.58, 0.28), "culture": Color(0.92, 0.48, 0.70)}

var io_tabs := {}
var io_head_ctl: Control = null
var io_mem_ctl: Control = null
var io_ext_rt: RichTextLabel = null
var io_info_rt: RichTextLabel = null
var io_act_box: VBoxContainer = null
var io_ses_rt: RichTextLabel = null
var io_vote_btns: Array = []
var io_hist_rt: RichTextLabel = null
var io_built_for := ""


var io_row_mem: HFlowContainer = null
var io_row_oth: HFlowContainer = null
var io_lbl_cand: Label = null
var io_lbl_oth: Label = null
var io_other_opt: OptionButton = null
var io_groups_key := ""
var io_bar_hh := 76.0


func io_bar_h() -> float:
	if io_bar == null:
		return 40.0
	return io_bar_hh


func io_bar_row(parent: Control, title: String) -> HFlowContainer:
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 4)
	fl.add_theme_constant_override("v_separation", 4)
	var l := Label.new()
	l.text = title
	l.custom_minimum_size = Vector2(130.0, 0.0)
	l.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	l.add_theme_font_size_override("font_size", 13)
	fl.add_child(l)
	parent.add_child(fl)
	return fl


# группа организации: 0 — член, 1 — заявка или кандидат, 2 — остальные
func io_group(o: String) -> int:
	if io_member(o):
		return 0
	if (io["cand"] as Dictionary).has(o):
		return 1
	var d: Dictionary = ORGS[o]
	if d.has("rl") and rl_on() and (rl["acc"] as Dictionary).has(String(d["rl"])):
		return 1
	return 2


# высота строки организаций считается сама (по ширине кнопок), чтобы окна под ней не перекрывались
func io_bar_layout() -> void:
	if io_bar == null:
		return
	var w: float = maxf(600.0, size.x - 28.0)
	var hh := 0.0
	for row in [io_row_mem, io_row_oth]:
		var x := 0.0
		var lines := 1
		var lh := 0.0
		for ch in (row as HFlowContainer).get_children():
			var c: Control = ch
			if not c.visible:
				continue
			var ms: Vector2 = c.get_combined_minimum_size()
			lh = maxf(lh, ms.y)
			if x > 0.0 and x + ms.x > w:
				lines += 1
				x = 0.0
			x += ms.x + 4.0
		hh += float(lines) * (maxf(lh, 26.0) + 4.0)
	io_bar.size = Vector2(w + 12.0, hh + 6.0)
	(io_row_mem as Control).custom_minimum_size = Vector2(w, 0.0)
	(io_row_oth as Control).custom_minimum_size = Vector2(w, 0.0)
	io_bar_hh = hh + 14.0
	if io_bar.visible and workspace != null:
		workspace.offset_top = 64.0 + io_bar_hh


# раскладка кнопок по группам; пересобирается, только когда членство или заявки изменились
func io_bar_groups() -> void:
	var key := ""
	for o in ORG_ORDER:
		key += str(io_group(o))
	if key == io_groups_key:
		return
	io_groups_key = key
	var n_c := 0
	for o in ORG_ORDER:
		var b: Button = io_tabs[o]
		var g := io_group(o)
		var want: Control = io_row_mem if g == 0 else io_row_oth
		if b.get_parent() != want:
			b.get_parent().remove_child(b)
			want.add_child(b)
		b.visible = g != 2
		if g == 1:
			n_c += 1
	# порядок во второй строке: подпись «Заявка», кнопки заявок, подпись «Остальные», список
	for o in ORG_ORDER:
		if io_group(o) == 1:
			io_row_oth.move_child(io_tabs[o], -1)
	io_row_oth.move_child(io_lbl_oth, -1)
	io_row_oth.move_child(io_other_opt, -1)
	io_lbl_cand.visible = n_c > 0
	io_other_opt.clear()
	io_other_opt.add_item("— выбрать —")
	io_other_opt.set_item_metadata(0, "")
	for o in ORG_ORDER:
		if io_group(o) == 2:
			io_other_opt.add_item(String(ORGS[o]["sh"]) + " — " + String(ORGS[o]["n"]))
			io_other_opt.set_item_metadata(io_other_opt.item_count - 1, String(o))
	io_lbl_oth.visible = io_other_opt.item_count > 1
	io_other_opt.visible = io_other_opt.item_count > 1
	io_bar_layout()


func io_col(o: String) -> Color:
	return IO_TYPE_COL.get(String(ORGS[o]["type"]), C_ACCENT)


func build_io_windows() -> void:
	# v55_3: организации в три группы — «Вы состоите» (кнопки), «Заявка / кандидат» (кнопки), «Остальные» (выпадающий список)
	var bar := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.09, 0.13, 0.92)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 6.0
	sb.content_margin_right = 6.0
	sb.content_margin_top = 3.0
	sb.content_margin_bottom = 3.0
	bar.add_theme_stylebox_override("panel", sb)
	add_child(bar)
	bar.position = Vector2(8.0, 66.0)
	io_bar = bar
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 4)
	bar.add_child(rows)
	io_row_mem = io_bar_row(rows, "Вы состоите:")
	io_row_oth = io_bar_row(rows, "Заявка / кандидат:")
	io_lbl_cand = io_row_oth.get_child(0)
	var grp := ButtonGroup.new()
	for o in ORG_ORDER:
		var b := Button.new()
		b.theme_type_variation = "SmallButton"
		b.toggle_mode = true
		b.button_group = grp
		b.focus_mode = Control.FOCUS_NONE
		b.text = String(ORGS[o]["sh"])
		b.tooltip_text = String(ORGS[o]["n"])
		color_button(b, io_col(o).lightened(0.25))
		var oid: String = o
		b.pressed.connect(func() -> void:
			io["sel"] = oid
			sfx("click")
			refresh())
		io_row_mem.add_child(b)
		io_tabs[o] = b
	io_lbl_oth = Label.new()
	io_lbl_oth.text = "Остальные:"
	io_lbl_oth.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	io_lbl_oth.add_theme_font_size_override("font_size", 13)
	io_row_oth.add_child(io_lbl_oth)
	io_other_opt = OptionButton.new()
	io_other_opt.focus_mode = Control.FOCUS_NONE
	io_other_opt.theme_type_variation = "SmallButton"
	io_other_opt.fit_to_longest_item = false
	io_other_opt.custom_minimum_size = Vector2(260.0, 0.0)
	io_other_opt.item_selected.connect(func(idx: int) -> void:
		var oid2: String = String(io_other_opt.get_item_metadata(idx))
		if oid2 != "":
			io["sel"] = oid2
			sfx("click")
			refresh())
	io_row_oth.add_child(io_other_opt)
	bar.visible = false
	resized.connect(func() -> void:
		if io_bar != null:
			io_bar_layout())
	io_bar_layout()

	var w: FloatWindow = new_window("io_head", "Организация", 18, Rect2(0.0, 0.0, 0.70, 0.21), false)
	io_head_ctl = Control.new()
	io_head_ctl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	io_head_ctl.custom_minimum_size = Vector2(0.0, 88.0)
	io_head_ctl.draw.connect(io_draw_head)
	w.body.add_child(io_head_ctl)

	w = new_window("io_mem", "Члены организации", 18, Rect2(0.0, 0.21, 0.23, 0.79))
	io_mem_ctl = Control.new()
	io_mem_ctl.custom_minimum_size = Vector2(0.0, 100.0)
	io_mem_ctl.draw.connect(io_draw_members)
	w.body.add_child(io_mem_ctl)
	io_ext_rt = make_rt(w.body)

	w = new_window("io_info", "Что даёт и чего требует", 18, Rect2(0.23, 0.21, 0.47, 0.39))
	io_info_rt = make_rt(w.body)

	w = new_window("io_act", "Действия", 18, Rect2(0.23, 0.60, 0.22, 0.40))
	io_act_box = VBoxContainer.new()
	io_act_box.add_theme_constant_override("separation", 4)
	w.body.add_child(io_act_box)

	w = new_window("io_ses", "Сессия и голосование", 18, Rect2(0.45, 0.60, 0.25, 0.40))
	io_ses_rt = make_rt(w.body)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 4)
	w.body.add_child(hb)
	for v in [1, 0, -1]:
		var vb := Button.new()
		vb.text = {1: "За", 0: "Воздержаться", -1: "Против"}[v]
		vb.focus_mode = Control.FOCUS_NONE
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var vv: int = v
		vb.pressed.connect(func() -> void:
			if io_vote(String(io["sel"]), vv):
				sfx("good")
			refresh())
		hb.add_child(vb)
		io_vote_btns.append(vb)
	add_title(w.body, "Прошлые решения")
	io_hist_rt = make_rt(w.body)
	# окна ЕС и НАТО из «Влияния» теперь живут во вкладках организаций
	for id in ["rm_blocs", "rm_nato"]:
		if wins.has(id):
			(wins[id] as FloatWindow).desk = 99


func update_io_windows() -> void:
	if io.is_empty() or io_head_ctl == null:
		return
	var o: String = String(io.get("sel", "un"))
	if not ORGS.has(o):
		o = "un"
	io_bar_groups()
	for k in io_tabs:
		var b: Button = io_tabs[k]
		b.set_pressed_no_signal(k == o)
	var sel_i := 0
	for i in io_other_opt.item_count:
		if String(io_other_opt.get_item_metadata(i)) == o:
			sel_i = i
	io_other_opt.select(sel_i)
	var d: Dictionary = ORGS[o]
	(wins["io_head"] as FloatWindow).set_title(String(d["n"]))
	io_head_ctl.queue_redraw()
	var mem: Array = io_members(o)
	io_mem_ctl.custom_minimum_size = Vector2(0.0, 26.0 + 22.0 * float(mem.size()))
	io_mem_ctl.queue_redraw()
	io_ext_rt.text = ("[font_size=12][color=%s]Остальные члены: %s.[/color][/font_size]" % [COL_DIM, String(d["ext"])]) if String(d["ext"]) != "" else ""
	# что даёт и чего требует
	var me := io_member(o)
	var t := "%s\n" % String(d["desc"])
	t += "[b]Правило решений:[/b] %s. Сессии — раз в %s\n" % [String(ORG_RULES.get(String(d["rule"]), d["rule"])), months_text(int(d["per"]))]
	var fx: Dictionary = d.get("fx", {})
	if not fx.is_empty():
		t += "[b]Что даёт членство:[/b] %s.\n" % io_fx_text(fx)
	if d.has("rl"):
		t += "[b]Что даёт членство:[/b] %s\n" % {"eu": "единый рынок (рост +0,12 п. п. в месяц к итогу года), структурные фонды для бедных членов, свободное движение; правила о дефиците (3% ВВП) с санкциями.",
			"euro": "низкая премия за риск и доверие инвесторов; своя денежная политика и эмиссия невозможны.", "schg": "торговля и туризм без границ (+0,08 к росту), можно временно ввести контроль.",
			"nato": "статья 5 — гарантии безопасности союзников; обязанность тратить на оборону не меньше стандарта."}.get(String(d["rl"]), "")
	if float(d["fee"]) > 0.0:
		t += "[b]Взнос:[/b] %.3f%% ВВП в год (≈%.2f млрд €).\n" % [float(d["fee"]), gdp * float(d["fee"]) / 100.0]
	var ex2: Array = d.get("excl", [])
	if ex2.size() > 0:
		t += "[b]Несовместимо с:[/b] %s.\n" % ", ".join(ex2.map(func(x) -> String: return String(ORGS[String(x)]["sh"])))
	t += "\n[b]Условия членства:[/b]\n"
	for r in io_reqs(o):
		t += "[color=%s]%s[/color] %s\n" % [COL_GOOD if bool(r[1]) else COL_BAD, "✓" if bool(r[1]) else "✗", String(r[0])]
	if (io["cand"] as Dictionary).has(o):
		var a: Dictionary = io["cand"][o]
		t += "\n[b]Заявка рассматривается:[/b] %s %.0f%% (выполнено условий %d из %d, %s переговоров)\n" % [cr_bar(float(a["p"]) / 12.0 * 100.0, 16), float(a["p"]) / 12.0 * 100.0, int(a["met"]), int(a["need"]), months_text(int(a["m"]))]
	if d.has("rl") and rl_on() and (rl["acc"] as Dictionary).has(String(d["rl"])):
		var a2: Dictionary = rl["acc"][String(d["rl"])]
		t += "\n[b]Заявка рассматривается:[/b] выполнено условий %d, прогресс %.0f, %s.\n" % [int(a2.get("met", 0)), float(a2.get("p", 0.0)), months_text(int(a2.get("m", 0)))]
	t += "\nВаш статус: [b]%s[/b] · влияние в организации: [b]%.0f[/b] из 100" % ["член" if me else ("кандидат" if (io["cand"] as Dictionary).has(o) else "не член"), io_infl(o)]
	io_info_rt.text = t
	# действия
	if io_built_for != o + str(me) + str((io["cand"] as Dictionary).has(o)):
		io_built_for = o + str(me) + str((io["cand"] as Dictionary).has(o))
		for ch in io_act_box.get_children():
			ch.queue_free()
		for a3 in io_act_list(o):
			var b2 := make_button(String(a3["n"]), io_act_box)
			b2.theme_type_variation = "SmallButton"
			var aid: String = String(a3["id"])
			b2.set_meta("aid", aid)
			b2.pressed.connect(func() -> void:
				sfx("good" if io_act(String(io["sel"]), aid) else "bad")
				io_built_for = ""
				refresh())
	var lst: Array = io_act_list(o)
	var bi := 0
	for ch2 in io_act_box.get_children():
		if not (ch2 is Button) or ch2.is_queued_for_deletion():
			continue
		if bi < lst.size():
			var a4: Dictionary = lst[bi]
			var why: String = String(a4["why"])
			var b3: Button = ch2
			b3.disabled = why != ""
			b3.text = String(a4["n"]) + (" (%.0f)" % float(a4["cap"]) if float(a4["cap"]) > 0.0 else "") + ("" if why == "" else " — " + why)
			b3.tooltip_text = String(a4["tip"])
		bi += 1
	if lst.is_empty() and io_act_box.get_child_count() == 0:
		add_note(io_act_box, "Особых действий нет.")
	# v55_3: текст кнопок меняется (цена, причина запрета) — пересчитать высоту переносимых строк
	(wins["io_act"] as FloatWindow).refresh_wraps.call_deferred()
	# сессия
	var it := io_item(o)
	var s := ""
	if not me:
		s = "[color=%s]Голосовать могут только члены организации.[/color]" % COL_DIM
	elif it.is_empty():
		s = "Сейчас вопросов на голосовании нет. Следующая сессия: [b]%s[/b]." % date_after(maxi(0, int(io["next"].get(o, turn)) - turn))
	else:
		var ty := io_tally(o, 1)
		var tn := io_tally(o, -1)
		s = "[b]На голосовании:[/b] %s\n" % String(it["t"])
		s += "[font_size=12]Если вы «за» — %s (%d за, %d против); если «против» — %s%s. Голос нужно отдать до %s, иначе решит советник.[/font_size]\n" % [
			"[color=%s]примут[/color]" % COL_GOOD if bool(ty["pass"]) else "[color=%s]отклонят[/color]" % COL_BAD, int(ty["yes"]), int(ty["no"]),
			"[color=%s]примут[/color]" % COL_GOOD if bool(tn["pass"]) else "[color=%s]отклонят[/color]" % COL_BAD,
			" (ваше вето)" if String(tn["veto"]) == ccode else "", date_after(maxi(0, int(io["pend"][o]["t0"]) + 2 - turn))]
		var fxy: Dictionary = it.get("yes", {})
		if not fxy.is_empty():
			s += "[font_size=12][color=%s]Если примут: %s.[/color][/font_size]" % [COL_DIM, io_agenda_fx_text(fxy)]
	io_ses_rt.text = s
	for vb in io_vote_btns:
		(vb as Button).disabled = not me or it.is_empty() or pl_why() != ""
	var hl: Array = io["hist"].get(o, [])
	var ht := ""
	for r2 in hl:
		ht += "%s — %s: [color=%s]%s[/color] (%d/%d/%d; вы %s)\n" % [String(r2["d"]), String(r2["t"]), COL_GOOD if bool(r2["ok"]) else COL_BAD, "принято" if bool(r2["ok"]) else "отклонено",
			int(r2["y"]), int(r2["n"]), int(r2["a"]), ["против", "воздерж.", "за"][int(r2["my"]) + 1]]
	io_hist_rt.text = "[font_size=12]%s[/font_size]" % (ht if ht != "" else "[color=%s]Пока ничего.[/color]" % COL_DIM)


func io_fx_text(fx: Dictionary) -> String:
	var names := {"growth_bonus": "рост", "dip_bonus": "дипломатия", "dem_shift": "демократия", "sec_bonus": "безопасность", "mood_shift": "настроение"}
	var parts: PackedStringArray = []
	for k in fx:
		parts.append("%s %+.2f" % [names.get(k, k), float(fx[k])])
	return ", ".join(parts)


func io_agenda_fx_text(fx: Dictionary) -> String:
	var parts: PackedStringArray = []
	if fx.has("growth"):
		parts.append("рост %+.2f п. п. на 2 года" % float(fx["growth"]))
	if fx.has("sec"):
		parts.append("безопасность %+.1f" % float(fx["sec"]))
	if fx.has("debt"):
		parts.append("расходы %.2f%% ВВП" % float(fx["debt"]))
	if fx.has("risk"):
		parts.append("премия за риск %+.2f" % float(fx["risk"]))
	if fx.has("support"):
		for g in fx["support"]:
			parts.append("%s %+.0f" % [g, float(fx["support"][g])])
	if fx.has("dip"):
		for c in fx["dip"]:
			parts.append("отношения с %s %+.0f" % [String(WORLD[c]["name"]) if WORLD.has(c) else c, float(fx["dip"][c])])
	return ", ".join(parts) if parts.size() > 0 else "только символическое значение"


# шапка: эмблема (круг с сокращением), тип, год, штаб-квартира, статус, влияние
func io_draw_head() -> void:
	var c := io_head_ctl
	var o: String = String(io.get("sel", "un"))
	var d: Dictionary = ORGS.get(o, {})
	if d.is_empty():
		return
	var sz: Vector2 = c.size
	var col := io_col(o)
	var f: Font = c.get_theme_default_font()
	Gfx.hgrad(c, Rect2(Vector2.ZERO, sz), Color(col.r, col.g, col.b, 0.30), Color(col.r, col.g, col.b, 0.02))
	var p := Vector2(48.0, sz.y * 0.5)
	c.draw_circle(p, 38.0, col.darkened(0.45))
	c.draw_arc(p, 38.0, 0.0, TAU, 64, col.lightened(0.3), 2.5, true)
	for k in 12:
		var a: float = TAU * float(k) / 12.0
		Gfx.star(c, p + Vector2(cos(a), sin(a)) * 30.0, 3.0, Color(1.0, 0.85, 0.35, 0.85), Color(0, 0, 0, 0.0))
	c.draw_string(f, p + Vector2(-38.0, 6.0), String(d["sh"]).substr(0, 7), HORIZONTAL_ALIGNMENT_CENTER, 76.0, 15 if String(d["sh"]).length() <= 5 else 11, Color(1, 1, 1))
	var x := 100.0
	c.draw_string(f, Vector2(x, 26.0), String(d["n"]), HORIZONTAL_ALIGNMENT_LEFT, sz.x - x - 230.0, 18, Color(0.97, 0.97, 0.99))
	c.draw_string(f, Vector2(x, 48.0), "%s · основана в %d · штаб-квартира: %s · членов в игре: %d" % [io_cap1(String(ORG_TYPES.get(String(d["type"]), ""))), int(d["est"]), String(d["hq"]), io_members(o).size()], HORIZONTAL_ALIGNMENT_LEFT, sz.x - x - 230.0, 12, Color(0.78, 0.81, 0.88))
	var me := io_member(o)
	var cand: bool = (io["cand"] as Dictionary).has(o)
	var st: String = "ВЫ — ЧЛЕН" if me else ("ВЫ — КАНДИДАТ" if cand else "ВЫ НЕ ЧЛЕН")
	var stc: Color = Color(0.40, 0.82, 0.52) if me else (Color(0.95, 0.78, 0.35) if cand else Color(0.70, 0.72, 0.80))
	var chip := Rect2(x, 56.0, 130.0, 22.0)
	c.draw_rect(chip, Color(stc.r, stc.g, stc.b, 0.22))
	c.draw_rect(chip, stc, false, 1.5)
	c.draw_string(f, chip.position + Vector2(0.0, 16.0), st, HORIZONTAL_ALIGNMENT_CENTER, chip.size.x, 12, stc)
	# влияние
	var gx: float = sz.x - 210.0
	var inf := io_infl(o)
	c.draw_string(f, Vector2(gx, 26.0), "Влияние: %.0f из 100" % inf, HORIZONTAL_ALIGNMENT_LEFT, 200.0, 13, Color(0.9, 0.92, 0.96))
	c.draw_rect(Rect2(gx, 34.0, 190.0, 10.0), Color(1, 1, 1, 0.07))
	c.draw_rect(Rect2(gx, 34.0, 190.0 * inf / 100.0, 10.0), col.lightened(0.15))
	c.draw_string(f, Vector2(gx, 64.0), "Отношения с членами: %.0f" % io_avg_rel(o), HORIZONTAL_ALIGNMENT_LEFT, 200.0, 12, Color(0.78, 0.81, 0.88))
	if o == "un" and turn < int(io.get("sc_until", -1)):
		c.draw_string(f, Vector2(gx, 82.0), "Член Совета Безопасности", HORIZONTAL_ALIGNMENT_LEFT, 200.0, 12, Color(1.0, 0.85, 0.4))


# члены: флаг, название, отношения (полоса), позиция по вопросу сессии
func io_draw_members() -> void:
	var c := io_mem_ctl
	var o: String = String(io.get("sel", "un"))
	if not ORGS.has(o):
		return
	var f: Font = c.get_theme_default_font()
	var sz: Vector2 = c.size
	var it := io_item(o)
	c.draw_string(f, Vector2(0.0, 14.0), "страна · отношения%s" % (" · позиция" if not it.is_empty() else ""), HORIZONTAL_ALIGNMENT_LEFT, sz.x, 11, Color(0.62, 0.66, 0.75))
	var mem: Array = io_members(o)
	mem.sort_custom(func(a, b): return (String(WORLD[a]["name"]) if WORLD.has(a) else a) < (String(WORLD[b]["name"]) if WORLD.has(b) else b))
	var y := 22.0
	for cc in mem:
		var me: bool = cc == ccode
		if me:
			c.draw_rect(Rect2(0.0, y, sz.x, 20.0), Color(1, 1, 1, 0.07))
		Flags.draw(c, String(cc), Rect2(2.0, y + 3.0, 21.0, 14.0))
		var nm: String = String(WORLD[cc]["name"]) if WORLD.has(cc) else String(cc)
		c.draw_string(f, Vector2(28.0, y + 15.0), nm + (" (вы)" if me else ""), HORIZONTAL_ALIGNMENT_LEFT, sz.x - 120.0, 12, Color(0.92, 0.93, 0.97) if not me else Color(1.0, 0.85, 0.4))
		if not me:
			var rel: float = fed_rel(String(cc))
			var bx: float = sz.x - 86.0
			c.draw_rect(Rect2(bx, y + 7.0, 50.0, 7.0), Color(1, 1, 1, 0.07))
			c.draw_rect(Rect2(bx, y + 7.0, 50.0 * rel / 100.0, 7.0), scale_color(clampf(rel / 100.0, 0.0, 1.0)))
		if not it.is_empty() and not me:
			var s := io_stance(it, String(cc))
			var sc: Color = [Color(0.92, 0.40, 0.38), Color(0.65, 0.68, 0.75), Color(0.40, 0.82, 0.52)][s + 1]
			c.draw_string(f, Vector2(sz.x - 28.0, y + 15.0), ["✗", "–", "✓"][s + 1], HORIZONTAL_ALIGNMENT_CENTER, 24.0, 13, sc)
		y += 22.0


func io_cap1(t: String) -> String:
	return t.substr(0, 1).to_upper() + t.substr(1)
