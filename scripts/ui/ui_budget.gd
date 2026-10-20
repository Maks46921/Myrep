# v50_1: черновик бюджета и коалиционные переговоры о нём.
# Ползунки окна «Налоги и расходы» задают план; «Принять бюджет» утверждает его. Если правительство коалиционное,
# план рассматривает совет коалиции: окно переговоров показывает, кто не согласен и почему, и как его убедить.
extends "res://scripts/ui/ui_settings.gd"

var bn_ov: Control = null
var bn_rt: RichTextLabel = null
var bn_box: VBoxContainer = null


# черновик ведётся, когда бюджетом распоряжаетесь вы (не в оппозиции и не в режиме наблюдателя)
func bud_draft_on() -> bool:
	return not opp_mode and not observer and not game_over


# кому план выгоден и кому нет: рост расходов радует группу, рост налога бьёт по группе
const BUD_WIN := {"pensions": ["Пенсионеры"], "benefits": ["Рабочие", "Пенсионеры"], "health": ["Пенсионеры", "Бюджетники"], "edu": ["Молодёжь", "Бюджетники"],
	"army": ["Силовики"], "police": ["Силовики"], "admin": ["Бюджетники"], "infra": ["Бизнес", "Рабочие"], "eco": ["Экологи", "Молодёжь"], "subs": ["Бизнес", "Село"], "agri": ["Село"]}
const BUD_PAY := {"income": ["Рабочие"], "social": ["Рабочие", "Бизнес"], "corp": ["Бизнес"], "vat": ["Рабочие", "Пенсионеры"]}


func bud_preview() -> Dictionary:
	var plan := compute_budget()
	var h := bud_hold_begin()
	var base := compute_budget()
	bud_hold_end_quiet(h)
	var g1: float = maxf(1.0, gdp)
	var win := {}
	var lose := {}
	for c in bud_changes():
		var k := String(c[0])
		var dv := float(c[2]) - float(c[1])
		if absf(dv) < 0.05:
			continue
		var up: bool = dv > 0.0
		if BUD_WIN.has(k):
			for g in BUD_WIN[k]:
				(win if up else lose)[g] = true
		elif BUD_PAY.has(k):
			for g in BUD_PAY[k]:
				(lose if up else win)[g] = true
	for g in win.keys():
		if lose.has(g):
			win.erase(g)
			lose.erase(g)
	return {"plan": plan, "base": base, "win": win.keys(), "lose": lose.keys(),
		"def_plan": -float(plan["balance"]) / g1 * 100.0, "def_base": -float(base["balance"]) / g1 * 100.0,
		"debt_plan": (debt - float(plan["balance"])) / g1 * 100.0, "debt_base": (debt - float(base["balance"])) / g1 * 100.0}


func bud_preview_text() -> String:
	var pv := bud_preview()
	var lines: PackedStringArray = []
	var dp: float = float(pv["def_plan"])
	var db: float = float(pv["def_base"])
	var danger: bool = dp > 6.0 or float(pv["debt_plan"]) > 100.0
	lines.append("[b]Если принять:[/b]")
	lines.append("Дефицит %s → [color=%s]%.1f%%[/color] ВВП" % ["%.1f%%" % db, COL_BAD if dp > 5.0 else (COL_WARN if dp > 3.0 else COL_GOOD), dp])
	lines.append("Долг через год %.0f%% → [color=%s]%.0f%%[/color] ВВП" % [float(pv["debt_base"]), COL_BAD if float(pv["debt_plan"]) > 100.0 else (COL_WARN if float(pv["debt_plan"]) > 80.0 else COL_GOOD), float(pv["debt_plan"])])
	if not (pv["win"] as Array).is_empty():
		lines.append("[color=%s]Выиграют:[/color] %s" % [COL_GOOD, ", ".join(PackedStringArray(pv["win"]))])
	if not (pv["lose"] as Array).is_empty():
		lines.append("[color=%s]Проиграют:[/color] %s" % [COL_BAD, ", ".join(PackedStringArray(pv["lose"]))])
	if bud_needs_council():
		var cv := bud_council()
		lines.append("Коалиция: [color=%s]%s (за %.0f%%)[/color]" % [COL_GOOD if bool(cv["pass"]) else COL_BAD, "поддержит" if bool(cv["pass"]) else "не поддержит", float(cv["yes"]) * 100.0])
	if danger:
		lines.append("[color=%s][b]⚠ Красная черта:[/b] дефицит выше 6%% ВВП или долг выше 100%% ВВП. Рынки и рейтинг отреагируют.[/color]" % COL_BAD)
	return "[font_size=13]%s[/font_size]" % "\n".join(lines)


func bud_table_text() -> String:
	var pv := bud_preview()
	var pl: Dictionary = pv["plan"]
	var bs: Dictionary = pv["base"]
	var rows := "[table=4][cell][color=%s]Статья[/color]   [/cell][cell][color=%s]Было, млрд[/color]   [/cell][cell][color=%s]Станет[/color]   [/cell][cell][color=%s]Разница[/color][/cell]" % [COL_DIM, COL_DIM, COL_DIM, COL_DIM]
	var keys: Array = []
	for k in pl["rev"]:
		keys.append(["rev", k])
	for k in pl["exp"]:
		keys.append(["exp", k])
	for kk in keys:
		var a: float = float(bs[kk[0]].get(kk[1], 0.0))
		var b: float = float(pl[kk[0]].get(kk[1], 0.0))
		if absf(b - a) < 0.05:
			continue
		var good: bool = (b > a) == (kk[0] == "rev")
		rows += "[cell]%s   [/cell][cell]%.1f   [/cell][cell]%.1f   [/cell][cell][color=%s]%s[/color][/cell]" % [String(kk[1]), a, b, COL_GOOD if good else COL_BAD, sg(b - a, 1)]
	rows += "[/table]"
	return "[font_size=12]%s[/font_size]" % rows


func update_bud_head() -> void:
	if bud_head == null:
		return
	update_bud_oneoff()
	var ch := bud_changes()
	bud_accept_btn.disabled = ch.is_empty() or game_over
	bud_cancel_btn.disabled = ch.is_empty()
	bud_prev_rt.visible = not ch.is_empty()
	bud_tbl_btn.visible = not ch.is_empty()
	bud_tbl_rt.visible = not ch.is_empty() and bud_tbl_btn.button_pressed
	if not ch.is_empty():
		bud_prev_rt.text = bud_preview_text()
		if bud_tbl_rt.visible:
			bud_tbl_rt.text = bud_table_text()
	if ch.is_empty():
		var t := "[color=%s]Бюджет утверждён. Двигайте ползунки — получится план; он вступит в силу после «Принять бюджет».[/color]" % COL_DIM
		if bud_needs_council():
			t += "\n[color=%s]Правительство коалиционное: план рассмотрит совет коалиции.[/color]" % COL_DIM
		bud_head_rt.text = "[font_size=13]%s[/font_size]" % t
		return
	var parts: PackedStringArray = []
	for c in ch:
		var dv: float = float(c[2]) - float(c[1])
		parts.append("%s [color=%s]%s[/color]" % [bud_title(String(c[0])), COL_GOOD if dv > 0.0 else COL_BAD, sg(dv, 2 if String(c[0]) == "reg_transfer" else 1)])
	var t2 := "[b]План (не принят):[/b] %s" % ", ".join(parts)
	if bud_needs_council():
		var cv := bud_council()
		t2 += "\nСовет коалиции сейчас: [color=%s]за %.0f%%[/color]" % [COL_GOOD if bool(cv["pass"]) else COL_BAD, float(cv["yes"]) * 100.0]
	bud_head_rt.text = "[font_size=13]%s[/font_size]" % t2


func on_bud_accept() -> void:
	if pl_deny():
		return
	if bud_changes().is_empty():
		return
	if not bud_needs_council():
		bud_apply(false)
		sfx("good")
		refresh()
		return
	bud_neg_open()


# ---------- окно переговоров ----------
func bud_neg_open() -> void:
	if bn_ov == null:
		bn_ov = Control.new()
		bn_ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bn_ov.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(bn_ov)
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.5)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bn_ov.add_child(dim)
		var pan := PanelContainer.new()
		pan.add_theme_stylebox_override("panel", sbox(C_PANEL, C_PURPLE.darkened(0.2), 2, 12, 14.0, 12.0))
		pan.anchor_left = 0.5
		pan.anchor_right = 0.5
		pan.anchor_top = 0.5
		pan.anchor_bottom = 0.5
		pan.offset_left = -330.0
		pan.offset_right = 330.0
		pan.offset_top = -280.0
		pan.offset_bottom = 280.0
		bn_ov.add_child(pan)
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 8)
		pan.add_child(vb)
		var tl := Label.new()
		tl.text = "Совет коалиции: переговоры о бюджете"
		tl.add_theme_font_size_override("font_size", 20)
		tl.add_theme_color_override("font_color", C_PURPLE.lightened(0.3))
		vb.add_child(tl)
		var sc := ScrollContainer.new()
		sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		vb.add_child(sc)
		var inner := VBoxContainer.new()
		inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inner.add_theme_constant_override("separation", 8)
		sc.add_child(inner)
		bn_rt = make_rt(inner)
		bn_box = VBoxContainer.new()
		bn_box.add_theme_constant_override("separation", 6)
		inner.add_child(bn_box)
	bn_ov.visible = true
	win_fade_in(bn_ov, 0.16)
	bud_neg_fill()


func bud_neg_close() -> void:
	if bn_ov != null:
		bn_ov.visible = false
	refresh()


func bud_neg_fill() -> void:
	for ch in bn_box.get_children():
		bn_box.remove_child(ch)
		ch.queue_free()
	var cv := bud_council()
	var t := "[font_size=14]"
	var parts: PackedStringArray = []
	for c in bud_changes():
		parts.append(bud_change_text(c))
	if bud_demand_by >= 0 and bud_demand_by < PARTY_NAMES.size():
		t += "[b]Автор правок:[/b] партия «%s» (её бюджетные требования внесены в черновик, но ещё не приняты).\n" % PARTY_NAMES[bud_demand_by]
	var fp := finance_party()
	if fp >= 0 and fp < PARTY_NAMES.size():
		t += "[b]Министр финансов:[/b] партия «%s».\n" % PARTY_NAMES[fp]
	t += "[b]Было → станет:[/b] %s\n\n" % "; ".join(parts)
	t += bud_preview_text() + "\n\n"
	t += "[b]За план — %.0f%% влияния[/b] (влияние — по министерским портфелям и местам; нужно больше половины).\n" % (float(cv["yes"]) * 100.0)
	t += "[/font_size]"
	bn_rt.text = t
	for q in cv["views"]:
		var v: Dictionary = cv["views"][q]
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", sbox(C_PANEL2, (PARTY_COLORS[q] as Color).darkened(0.2), 1, 8, 8.0, 5.0))
		bn_box.add_child(row)
		var rv2 := VBoxContainer.new()
		row.add_child(rv2)
		var rt := make_rt(rv2)
		var st: String
		if bool(v["persuaded"]):
			st = "[color=%s]согласна (после уступки)[/color]" % COL_GOOD
		elif bool(v["ok"]):
			st = "[color=%s]согласна[/color]" % COL_GOOD
		else:
			st = "[color=%s]против[/color]: %s" % [COL_BAD, ", ".join(v["bad"]) if (v["bad"] as PackedStringArray).size() > 0 else "план расходится с её программой"]
		rt.text = "[font_size=14][color=#%s]■[/color] [b]%s[/b] — влияние %.0f%% · %s[/font_size]" % [(PARTY_COLORS[q] as Color).to_html(false), PARTY_NAMES[q], coal_share(q) * 100.0, st]
		if not bool(v["ok"]):
			var b := Button.new()
			b.text = "Убедить уступкой (12 капитала)"
			b.focus_mode = Control.FOCUS_NONE
			b.disabled = cap_spendable() < 12.0
			b.tooltip_text = "Партия получит уступку (её довольство вырастет) и поддержит план."
			var qq: int = q
			b.pressed.connect(func() -> void:
				bud_persuade(qq)
				bud_neg_fill())
			rv2.add_child(b)
	var hb := HFlowContainer.new()
	hb.add_theme_constant_override("h_separation", 6)
	hb.add_theme_constant_override("v_separation", 6)
	bn_box.add_child(hb)
	var ok := Button.new()
	ok.text = "✔ Принять" + ("" if _all_agree(cv) else " (несогласные обидятся)")
	ok.focus_mode = Control.FOCUS_NONE
	ok.disabled = not bool(cv["pass"])
	ok.tooltip_text = "Совет принимает план большинством влияния. Несогласные партнёры теряют довольство." if bool(cv["pass"]) else "Большинства в совете нет: убедите партнёров или уберите спорные пункты."
	ok.pressed.connect(func() -> void:
		bud_apply(true)
		sfx("good")
		bud_neg_close())
	hb.add_child(ok)
	var dr := Button.new()
	dr.text = "Убрать спорные пункты"
	dr.focus_mode = Control.FOCUS_NONE
	dr.tooltip_text = "Вернуть к действующим значениям статьи, против которых возражают партнёры."
	dr.pressed.connect(func() -> void:
		bud_drop_disputed()
		if bud_changes().is_empty():
			bud_neg_close()
		else:
			bud_neg_fill())
	hb.add_child(dr)
	var bk := Button.new()
	bk.text = "Вернуться к правке"
	bk.focus_mode = Control.FOCUS_NONE
	bk.pressed.connect(bud_neg_close)
	hb.add_child(bk)
	var cn := Button.new()
	cn.text = "Отменить план"
	cn.focus_mode = Control.FOCUS_NONE
	cn.pressed.connect(func() -> void:
		bud_cancel()
		bud_neg_close())
	hb.add_child(cn)
	polish_tree(bn_ov)


func _all_agree(cv: Dictionary) -> bool:
	for q in cv["views"]:
		if not bool(cv["views"][q]["ok"]):
			return false
	return true


# ---------- 0.56 (п.8): резерв на разовые меры ----------
func build_bud_oneoff(parent: Control) -> void:
	var acc: Color = accent_for_desk(0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	parent.add_child(vb)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	vb.add_child(top)
	var tl := Label.new()
	tl.text = "Резерв на разовые меры"
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tl.clip_text = true
	tl.mouse_filter = Control.MOUSE_FILTER_PASS
	tl.tooltip_text = tip_make("Резерв на разовые меры", [["", "Из него оплачиваются разовые траты: грант региону, программы развития регионов, меры управления экономикой, инвестиции при бунтах, помощь другим странам, срочные закупки и программы армии."],
		["", "Деньги берутся в долг только при трате, неизрасходованный резерв ничего не стоит. Новый год — резерв полный."],
		["", "Размер резерва меняется только здесь и проходит через план бюджета, как другие статьи."]])
	top.add_child(tl)
	bud_oo_label = Label.new()
	bud_oo_label.add_theme_color_override("font_color", acc.lightened(0.25))
	top.add_child(bud_oo_label)
	for dir in [-1, 1]:
		var pb := Button.new()
		pb.theme_type_variation = "SmallButton"
		pb.text = "−" if dir < 0 else "+"
		pb.focus_mode = Control.FOCUS_NONE
		pb.custom_minimum_size = Vector2(24.0, 0.0)
		pb.tooltip_text = "Изменить резерв на 0,1% ВВП (с Shift — на 1%)."
		pb.pressed.connect(bud_oo_nudge.bind(dir))
		top.add_child(pb)
	bud_oo_rt = make_rt(vb)
	update_bud_oneoff()


func bud_oo_nudge(dir: int) -> void:
	if pl_deny():
		return
	oneoff_set(snappedf(oneoff_cap + float(dir) * nudge_step(), 0.1))
	update_bud_oneoff()
	update_bud_head()


func update_bud_oneoff() -> void:
	if bud_oo_label == null:
		return
	var capn: float = gdp * oneoff_cap / 100.0
	if oneoff_cap0 >= 0.0:
		bud_oo_label.text = "%.1f → %.1f%% ВВП · %.1f млрд (план)" % [oneoff_cap0, oneoff_cap, capn]
	else:
		bud_oo_label.text = "%.1f%% ВВП · %.1f млрд" % [oneoff_cap, capn]
	var t := "[font_size=12][color=%s]В этом году потрачено %.1f млрд, осталось %.1f млрд.[/color]" % [COL_DIM, oneoff_used, oneoff_left()]
	var n: int = oneoff_log.size()
	for k in range(maxi(0, n - 4), n):
		var it: Array = oneoff_log[k]
		t += "\n[color=%s]%s[/color]  %s  [color=%s]%.2f млрд[/color]" % [COL_DIM, String(it[0]), String(it[1]), COL_BAD, float(it[2])]
	bud_oo_rt.text = t + "[/font_size]"


# ============================================================
#  0.56 (п.20): ОКНО РАЗОВЫХ МЕР — сетка карточек поверх игры (кнопка «Меры» на верхней панели)
# ============================================================
var meas_ov: PanelContainer = null
var meas_btn: Button = null
var meas_grid: HFlowContainer = null
var meas_head_rt: RichTextLabel = null
var meas_cards := {}       # id -> {"pc", "rt", "btn"}
var meas_sig := ""


func make_meas_button(parent: Control) -> void:
	meas_btn = Button.new()
	meas_btn.theme_type_variation = "TabButton"
	meas_btn.text = "Меры"
	meas_btn.toggle_mode = true
	meas_btn.focus_mode = Control.FOCUS_NONE
	meas_btn.custom_minimum_size = Vector2(0.0, 40.0)
	meas_btn.tooltip_text = "Окно разовых мер: карточки с ответственными, последствиями и перерывом между мерами."
	meas_btn.toggled.connect(func(on: bool) -> void: set_meas_open(on))
	btn_icon(meas_btn, "scales")
	parent.add_child(meas_btn)


func meas_is_open() -> bool:
	return meas_ov != null and meas_ov.visible


func set_meas_open(on: bool) -> void:
	if meas_ov == null:
		return
	if on != meas_ov.visible:
		sfx("click")
	if on and tech_is_open():
		set_tech_open(false)
	if on and crisis_is_open():
		set_crisis_open(false)
	if on and cn_is_open():
		cn_close()
	var was: bool = meas_ov.visible
	meas_ov.visible = on
	if on and not was:
		win_fade_in(meas_ov, 0.18)
	if meas_btn != null:
		meas_btn.set_pressed_no_signal(on)
	overlay_tabs_sync()
	if on:
		meas_sig = ""
		update_meas_window()


func build_meas_overlay() -> void:
	meas_ov = PanelContainer.new()
	meas_ov.add_theme_stylebox_override("panel", sbox(Color(C_BG, 0.985), C_ACCENT.darkened(0.25), 2, 12, 14.0, 10.0))
	meas_ov.visible = false
	add_child(meas_ov)
	meas_ov.anchor_right = 1.0
	meas_ov.anchor_bottom = 1.0
	meas_ov.offset_left = 8.0
	meas_ov.offset_top = 62.0
	meas_ov.offset_right = -8.0
	meas_ov.offset_bottom = -8.0
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	meas_ov.add_child(root)
	var hd := HBoxContainer.new()
	hd.add_theme_constant_override("separation", 10)
	root.add_child(hd)
	var ttl := Label.new()
	ttl.text = "Разовые меры"
	ttl.add_theme_font_size_override("font_size", 22)
	hd.add_child(ttl)
	meas_head_rt = RichTextLabel.new()
	meas_head_rt.bbcode_enabled = true
	meas_head_rt.fit_content = true
	meas_head_rt.scroll_active = false
	meas_head_rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meas_head_rt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hd.add_child(meas_head_rt)
	var cb := Button.new()
	cb.text = "✕"
	cb.focus_mode = Control.FOCUS_NONE
	cb.tooltip_text = "Закрыть окно мер"
	cb.pressed.connect(func() -> void: set_meas_open(false))
	hd.add_child(cb)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(sc)
	meas_grid = HFlowContainer.new()
	meas_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meas_grid.add_theme_constant_override("h_separation", 10)
	meas_grid.add_theme_constant_override("v_separation", 10)
	sc.add_child(meas_grid)
	for m in MEASURES:
		var id: String = String(m["id"])
		var pc := PanelContainer.new()
		pc.custom_minimum_size = Vector2(330.0, 0.0)
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 6)
		pc.add_child(vb)
		var rt := RichTextLabel.new()
		rt.bbcode_enabled = true
		rt.fit_content = true
		rt.scroll_active = false
		rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rt.custom_minimum_size = Vector2(300.0, 0.0)
		rt.add_theme_font_size_override("normal_font_size", 13)
		rt.add_theme_font_size_override("bold_font_size", 13)
		vb.add_child(rt)
		var b := Button.new()
		b.text = "Провести"
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func() -> void:
			do_measure(id)
			meas_sig = ""
			update_meas_window())
		vb.add_child(b)
		meas_grid.add_child(pc)
		meas_cards[id] = {"pc": pc, "rt": rt, "btn": b}


func update_meas_window() -> void:
	if not meas_is_open():
		return
	var sig := "%d|%d|%d|%s|%s" % [turn, meas_q_used(), int(opp_mode), str(cooldown), str(ministries)]
	if sig == meas_sig:
		return
	meas_sig = sig
	meas_head_rt.text = "[color=%s]В этом квартале проведено [b]%d[/b] из %d мер. У каждой меры свой перерыв; часть мер отвечает министерство партнёра, часть — глава государства.[/color]" % [COL_DIM, meas_q_used(), MEAS_Q_LIMIT]
	for m in MEASURES:
		var id: String = String(m["id"])
		var cd: Dictionary = meas_cards[id]
		var why := meas_why(id)
		var mi := meas_min(id)
		var h := meas_holder(id)
		var col: Color = C_ACCENT if mi < 0 else (PARTY_COLORS[h] as Color)
		var ok: bool = why == ""
		var sb := sbox(C_PANEL2 if ok else C_PANEL, col.darkened(0.1) if ok else C_BORDER, 1, 8, 12.0, 10.0)
		sb.border_width_left = 4
		sb.border_color = col if ok else col.darkened(0.45)
		(cd["pc"] as PanelContainer).add_theme_stylebox_override("panel", sb)
		var t := "[font_size=16][b]%s[/b][/font_size]\n" % String(m["name"])
		t += "[font_size=11][color=#%s]%s[/color][/font_size]\n" % [col.lightened(0.25).to_html(false), meas_resp_text(id).to_upper()]
		t += "%s\n" % String(m["desc"])
		t += "[color=%s]Последствия:[/color] %s\n" % [COL_DIM, tip_color_nums(describe_fx(m["fx"]))]
		var left: int = int(cooldown.get(id, 0))
		t += "[color=%s]Перерыв после меры: %d мес.%s[/color]" % [COL_DIM, int(m["cd"]), (" Сейчас: ещё %d мес." % left) if left > 0 else ""]
		if not ok:
			t += "\n[color=%s]Сейчас нельзя: %s.[/color]" % [COL_WARN, why]
		(cd["rt"] as RichTextLabel).text = t
		var b := cd["btn"] as Button
		b.disabled = not ok
		b.tooltip_text = "Провести меру «%s»." % String(m["name"]) if ok else "Сейчас нельзя: %s." % why
