# v50_1: конструктор договоров — «чистый лист». Игрок выбирает партнёра, отмечает пункты, даёт договору название
# и предлагает его; партнёр решает по отношениям и выгоде пунктов. Тот же лист — у мирного договора (окно «Переговоры и мир»).
extends "res://scripts/ui/ui_build.gd"

const PAPER := Color(0.94, 0.91, 0.83)
const INK := Color(0.16, 0.14, 0.12)
const INK_DIM := Color(0.40, 0.36, 0.30)

var ts_ov: Control = null
var ts_title: LineEdit = null
var ts_partner: OptionButton = null
var ts_partners: Array = []
var ts_checks := {}
var ts_eval: RichTextLabel = null
var ts_go: Button = null


func paper_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER
	sb.border_color = Color(0.55, 0.45, 0.30)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 14
	sb.content_margin_left = 26.0
	sb.content_margin_right = 26.0
	sb.content_margin_top = 18.0
	sb.content_margin_bottom = 18.0
	return sb


func ink_label(parent: Control, text: String, size: int, col: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l


func treaty_sheet_open() -> void:
	if ts_ov == null:
		treaty_sheet_build()
	ts_partners = dx_countries()
	ts_partner.clear()
	var cur: String = rm_dip_target()
	for i in ts_partners.size():
		ts_partner.add_item(dx_name(String(ts_partners[i])))
		if String(ts_partners[i]) == cur:
			ts_partner.select(i)
	for id in ts_checks:
		(ts_checks[id] as CheckBox).set_pressed_no_signal(false)
	ts_title.text = ""
	ts_ov.visible = true
	win_fade_in(ts_ov, 0.18)
	treaty_sheet_update()


func treaty_sheet_build() -> void:
	ts_ov = Control.new()
	ts_ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ts_ov.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(ts_ov)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ts_ov.add_child(dim)
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", paper_style())
	pan.anchor_left = 0.5
	pan.anchor_right = 0.5
	pan.anchor_top = 0.5
	pan.anchor_bottom = 0.5
	pan.offset_left = -310.0
	pan.offset_right = 310.0
	pan.offset_top = -300.0
	pan.offset_bottom = 300.0
	ts_ov.add_child(pan)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	pan.add_child(vb)
	var hd := ink_label(vb, "ДОГОВОР", 24)
	hd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ts_title = LineEdit.new()
	ts_title.placeholder_text = "Название договора (например, «Балтийское партнёрство»)"
	ts_title.alignment = HORIZONTAL_ALIGNMENT_CENTER
	ts_title.add_theme_color_override("font_color", INK)
	ts_title.add_theme_color_override("font_placeholder_color", INK_DIM)
	var lsb := StyleBoxFlat.new()
	lsb.bg_color = Color(1, 1, 1, 0.0)
	lsb.border_color = INK_DIM
	lsb.border_width_bottom = 1
	ts_title.add_theme_stylebox_override("normal", lsb)
	ts_title.add_theme_stylebox_override("focus", lsb)
	vb.add_child(ts_title)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	vb.add_child(hb)
	var sl := ink_label(hb, "Стороны: %s и" % (String(WORLD[ccode]["name"]) if WORLD.has(ccode) else "мы"), 15)
	sl.autowrap_mode = TextServer.AUTOWRAP_OFF
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ts_partner = OptionButton.new()
	ts_partner.focus_mode = Control.FOCUS_NONE
	ts_partner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ts_partner.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ts_partner.fit_to_longest_item = false
	ts_partner.item_selected.connect(func(_i: int) -> void: treaty_sheet_update())
	hb.add_child(ts_partner)
	var line := ColorRect.new()
	line.color = INK_DIM
	line.custom_minimum_size = Vector2(0.0, 1.0)
	vb.add_child(line)
	ink_label(vb, "Статьи договора", 15, INK_DIM)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(sc)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 2)
	sc.add_child(list)
	var k := 0
	for d in DX_CLAUSES:
		k += 1
		var cb := CheckBox.new()
		var th: float = float(d["them"])
		cb.text = "Статья %d. %s%s" % [k, d["name"], "" if float(d["cap"]) <= 0.0 else "  (капитал %.0f)" % float(d["cap"])]
		cb.focus_mode = Control.FOCUS_NONE
		cb.clip_text = true
		cb.add_theme_color_override("font_color", INK)
		cb.add_theme_color_override("font_hover_color", Color(0.05, 0.05, 0.05))
		cb.add_theme_color_override("font_pressed_color", Color(0.10, 0.25, 0.12))
		cb.add_theme_color_override("font_hover_pressed_color", Color(0.10, 0.25, 0.12))
		for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			var em := StyleBoxFlat.new()
			em.bg_color = Color(0.55, 0.45, 0.30, 0.10) if st.begins_with("hover") else Color(0, 0, 0, 0)
			em.content_margin_left = 4.0
			em.content_margin_top = 3.0
			em.content_margin_bottom = 3.0
			cb.add_theme_stylebox_override(st, em)
		cb.tooltip_text = "Выгода партнёру: %s" % ("высокая" if th >= 5.0 else ("есть" if th > 0.0 else ("невыгодно ему" if th < 0.0 else "нейтрально")))
		cb.toggled.connect(func(_on: bool) -> void: treaty_sheet_update())
		list.add_child(cb)
		var dl := ink_label(list, "        " + String(d["us"]).capitalize().substr(0, 1) + String(d["us"]).substr(1) + ("" if th == 0.0 else ("  · партнёру выгодно" if th > 0.0 else "  · партнёру невыгодно")), 12, INK_DIM)
		dl.autowrap_mode = TextServer.AUTOWRAP_OFF
		dl.clip_text = true
		ts_checks[String(d["id"])] = cb
	var line2 := ColorRect.new()
	line2.color = INK_DIM
	line2.custom_minimum_size = Vector2(0.0, 1.0)
	vb.add_child(line2)
	ts_eval = RichTextLabel.new()
	ts_eval.bbcode_enabled = true
	ts_eval.fit_content = true
	ts_eval.add_theme_color_override("default_color", INK)
	vb.add_child(ts_eval)
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 10)
	vb.add_child(bh)
	ts_go = Button.new()
	ts_go.text = "✒ Подписать и предложить"
	ts_go.focus_mode = Control.FOCUS_NONE
	ts_go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ts_go.pressed.connect(func() -> void:
		var c: String = String(ts_partners[ts_partner.selected])
		var ids: Array = []
		for id in ts_checks:
			if (ts_checks[id] as CheckBox).button_pressed:
				ids.append(id)
		if dx_draft_propose(c, ids, ts_title.text):
			sfx("good")
		else:
			sfx("bad")
		ts_ov.visible = false
		rm_dirty_all()
		refresh())
	bh.add_child(ts_go)
	var cn := Button.new()
	cn.text = "Отложить"
	cn.focus_mode = Control.FOCUS_NONE
	cn.pressed.connect(func() -> void: ts_ov.visible = false)
	bh.add_child(cn)


func treaty_sheet_update() -> void:
	if ts_partner == null or ts_partner.selected < 0 or ts_partners.is_empty():
		return
	var c: String = String(ts_partners[ts_partner.selected])
	var ids: Array = []
	for id in ts_checks:
		if (ts_checks[id] as CheckBox).button_pressed:
			ids.append(id)
	var ev := dx_draft_eval(c, ids)
	var p: float = float(ev["p"])
	var pc: String = "#2e7d32" if p >= 0.6 else ("#a06a00" if p >= 0.35 else "#b23b3b")
	var t := "Отношения: [b]%.0f[/b] · цена переговоров: [b]%.0f[/b] капитала · шанс согласия: [b][color=%s]%.0f%%[/color][/b]" % [fed_rel(c), float(ev["cap"]), pc, p * 100.0]
	if (ev["why"] as PackedStringArray).size() > 0:
		t += "\n[color=#b23b3b]%s[/color]" % "; ".join(ev["why"])
	ts_eval.text = t
	ts_go.disabled = (ev["why"] as PackedStringArray).size() > 0 or game_over
