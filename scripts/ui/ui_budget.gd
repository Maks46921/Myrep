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


func update_bud_head() -> void:
	if bud_head == null:
		return
	var ch := bud_changes()
	bud_accept_btn.disabled = ch.is_empty() or game_over
	bud_cancel_btn.disabled = ch.is_empty()
	if ch.is_empty():
		var t := "[color=%s]Бюджет утверждён. Двигайте ползунки — получится план; он вступит в силу после «Принять бюджет».[/color]" % COL_DIM
		if bud_needs_council():
			t += "\n[color=%s]Правительство коалиционное: план рассмотрит совет коалиции.[/color]" % COL_DIM
		bud_head_rt.text = "[font_size=13]%s[/font_size]" % t
		return
	var parts: PackedStringArray = []
	for c in ch:
		var dv: float = float(c[2]) - float(c[1])
		parts.append("%s [color=%s]%s[/color]" % [policy_title(String(c[0])), COL_GOOD if dv > 0.0 else COL_BAD, sg(dv, 1)])
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
		parts.append("«%s» %.1f → %.1f%% ВВП" % [policy_title(String(c[0])), float(c[1]), float(c[2])])
	t += "[b]План:[/b] %s\n\n" % "; ".join(parts)
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
