# Интерфейс: окно «Кризисы» (v43_1) — протесты, сепаратизм, войны за отделение, революция, гражданская война, перевороты.
extends "res://scripts/ui/ui_tech.gd"

var cr_ov: PanelContainer = null
var cr_btn: Button = null
var cr_sum_rt: RichTextLabel
var cr_reg_rt: RichTextLabel
var cr_sel_rt: RichTextLabel
var cr_conf_rt: RichTextLabel
var cr_log_rt: RichTextLabel
var cr_state_rt: RichTextLabel
var cr_coup_rt: RichTextLabel
var cr_spk: Control
var cr_reg_btn: Dictionary = {}
var cr_conf_btn: Dictionary = {}
var cr_coup_btn: Dictionary = {}
var cr_sel_reg := ""
var cr_sel_conf := -1
var cr_confirm: ConfirmationDialog = null
var cr_pending := ""
var cr_right_box: VBoxContainer = null   # правая колонка окна (сюда встраиваются секции v44_1)


func make_crisis_button(parent: Control) -> void:
	cr_btn = Button.new()
	cr_btn.theme_type_variation = "TabButton"
	cr_btn.text = "Кризисы"
	cr_btn.toggle_mode = true
	cr_btn.focus_mode = Control.FOCUS_NONE
	cr_btn.custom_minimum_size = Vector2(0.0, 40.0)
	cr_btn.tooltip_text = "Окно кризисов: протесты и сепаратизм по регионам, войны за отделение, риск революции и переворота."
	cr_btn.toggled.connect(on_crisis_toggle)
	btn_icon(cr_btn, "shield")
	parent.add_child(cr_btn)


func on_crisis_toggle(on: bool) -> void:
	set_crisis_open(on)


func crisis_is_open() -> bool:
	return cr_ov != null and cr_ov.visible


func set_crisis_open(on: bool) -> void:
	if cr_ov == null:
		return
	if on and not current_event.is_empty():
		on = false
	if on != cr_ov.visible:
		sfx("click")
	if on and tech_ov != null and tech_ov.visible:
		set_tech_open(false)
	var was: bool = cr_ov.visible
	cr_ov.visible = on
	if on and not was:
		win_fade_in(cr_ov, 0.18)
	if cr_btn != null:
		cr_btn.set_pressed_no_signal(on)
	overlay_tabs_sync()
	if on:
		refresh()


func cr_section(parent: Control, text: String) -> void:
	add_title(parent, text)


func build_crisis_windows() -> void:
	cr_ov = PanelContainer.new()
	cr_ov.add_theme_stylebox_override("panel", sbox(Color(0.065, 0.05, 0.075, 0.985), C_BAD.darkened(0.35), 2, 12, 12.0, 10.0))
	cr_ov.visible = false
	add_child(cr_ov)
	cr_ov.anchor_right = 1.0
	cr_ov.anchor_bottom = 1.0
	cr_ov.offset_left = 8.0
	cr_ov.offset_top = 62.0
	cr_ov.offset_right = -8.0
	cr_ov.offset_bottom = -8.0
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	cr_ov.add_child(root)
	var hd := HBoxContainer.new()
	hd.add_theme_constant_override("separation", 10)
	root.add_child(hd)
	var ttl := Label.new()
	ttl.text = "Кризисы и власть"
	ttl.add_theme_font_size_override("font_size", 22)
	ttl.add_theme_color_override("font_color", C_TEXT)
	hd.add_child(ttl)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hd.add_child(sp)
	var legend := Label.new()
	legend.text = "стадии: спокойно → протесты → беспорядки → мятеж → война"
	legend.add_theme_font_size_override("font_size", 12)
	legend.add_theme_color_override("font_color", C_DIM)
	hd.add_child(legend)
	var cl := Button.new()
	cl.text = "✕ Закрыть"
	cl.focus_mode = Control.FOCUS_NONE
	cl.pressed.connect(set_crisis_open.bind(false))
	hd.add_child(cl)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	# ---- левая колонка: страна ----
	var left := PanelContainer.new()
	left.custom_minimum_size = Vector2(390.0, 0.0)
	left.add_theme_stylebox_override("panel", sbox(C_PANEL, C_BORDER, 1, 8, 8.0, 6.0))
	body.add_child(left)
	var lsc := ScrollContainer.new()
	lsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(lsc)
	var lv := VBoxContainer.new()
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lv.add_theme_constant_override("separation", 6)
	lsc.add_child(lv)
	cr_sum_rt = make_rt(lv)
	cr_spk = Spark.new()
	lv.add_child(cr_spk)
	cr_section(lv, "Защита от переворота")
	var f1 := VBoxContainer.new()
	f1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lv.add_child(f1)
	for a in RV_COUP_MEASURES:
		var b := fed_btn(String(a["name"]) + " (%.0f)" % float(a["cap"]), f1, String(a["desc"]))
		b.pressed.connect(on_cr_coup_measure.bind(String(a["id"])))
		cr_coup_btn[String(a["id"])] = b
	cr_section(lv, "Захват власти")
	cr_coup_rt = make_rt(lv)
	var f2 := VBoxContainer.new()
	lv.add_child(f2)
	for def in [["self", "Самопереворот: взять всю власть (12)", "Режим указов: парламент распущен, армия на вашей стороне. Шанс зависит от поддержки силовиков, безопасности, демократии и волны протестов. Провал — арест или тяжёлое ослабление."],
			["opp", "Заговор: захватить власть из оппозиции (15)", "Из оппозиции — захват власти с опорой на силовиков. Провал — партия запрещена, игра окончена."],
			["rising", "Поднять народное восстание из оппозиции (10)", "Начинает гражданскую войну на вашей стороне. Победа даёт власть, поражение — конец игры. Нужна волна протестов не ниже 25."]]:
		var b2 := fed_btn(String(def[1]), f2, String(def[2]))
		b2.pressed.connect(on_cr_power.bind(String(def[0])))
		cr_coup_btn[String(def[0])] = b2
	cr_section(lv, "Утраченные регионы и новые государства")
	cr_state_rt = make_rt(lv)
	# ---- правая колонка ----
	var rsc := ScrollContainer.new()
	rsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rsc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(rsc)
	var rv_box := VBoxContainer.new()
	rv_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rv_box.add_theme_constant_override("separation", 6)
	rsc.add_child(rv_box)
	cr_right_box = rv_box
	cr_section(rv_box, "Регионы: протесты и сепаратизм (щёлкните по названию)")
	cr_reg_rt = make_rt(rv_box)
	cr_reg_rt.meta_clicked.connect(on_cr_reg_meta)
	cr_sel_rt = make_rt(rv_box)
	var f3 := GridContainer.new()
	f3.columns = 3
	f3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rv_box.add_child(f3)
	for a2 in RV_REG_ACTS:
		var b3 := fed_btn("%s (%.0f)" % [String(a2["name"]), float(a2["cap"])], f3, String(a2["desc"]))
		b3.custom_minimum_size = Vector2(0.0, 44.0)
		b3.pressed.connect(on_cr_reg_act.bind(String(a2["id"])))
		cr_reg_btn[String(a2["id"])] = b3
	cr_section(rv_box, "Войны и мятежи")
	cr_conf_rt = make_rt(rv_box)
	cr_conf_rt.meta_clicked.connect(on_cr_conf_meta)
	var f4 := GridContainer.new()
	f4.columns = 3
	f4.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rv_box.add_child(f4)
	for a3 in RV_CONF_ACTS:
		var b4 := fed_btn(String(a3["name"]) + (" (%.0f)" % float(a3["cap"]) if float(a3["cap"]) > 0.0 else ""), f4, String(a3["desc"]))
		b4.pressed.connect(on_cr_conf_act.bind(String(a3["id"])))
		cr_conf_btn[String(a3["id"])] = b4
	cr_section(rv_box, "Хроника кризисов")
	cr_log_rt = make_rt(rv_box)
	cr_confirm = ConfirmationDialog.new()
	cr_confirm.title = "Подтвердите"
	cr_confirm.confirmed.connect(on_cr_confirmed)
	add_child(cr_confirm)


func cr_col_for(v: float, lo: float, hi: float) -> String:
	return COL_GOOD if v < lo else (COL_WARN if v < hi else COL_BAD)


func cr_bar(v: float, n: int = 18) -> String:
	var k: int = int(round(clampf(v, 0.0, 100.0) / 100.0 * n))
	return "█".repeat(k) + "░".repeat(n - k)


func on_cr_reg_meta(meta: Variant) -> void:
	cr_sel_reg = String(meta)
	update_crisis_windows()


func on_cr_conf_meta(meta: Variant) -> void:
	cr_sel_conf = int(String(meta))
	update_crisis_windows()


func cr_sel_region_idx() -> int:
	var i: int = rv_idx(cr_sel_reg) if cr_sel_reg != "" else -1
	if i < 0:
		var best := -1
		var bs := -1.0
		for k in regions.size():
			var sc: float = float(rv_reg(k)["stage"]) * 100.0 + float(rv_reg(k)["sep"])
			if sc > bs:
				bs = sc
				best = k
		i = best
		if i >= 0:
			cr_sel_reg = rv_uid(i)
	return i


func cr_sel_conf_idx() -> int:
	var cf: Array = rv["conf"]
	for k in cf.size():
		if int(cf[k]["id"]) == cr_sel_conf:
			return k
	if cf.size() > 0:
		cr_sel_conf = int(cf[0]["id"])
		return 0
	cr_sel_conf = -1
	return -1


func on_cr_reg_act(id: String) -> void:
	if pl_deny():
		return
	var i := cr_sel_region_idx()
	if i < 0:
		return
	if id == "referendum" or id == "troops":
		cr_pending = "reg:" + id
		cr_confirm.dialog_text = ("Разрешить референдум о независимости в регионе «%s»? Если «за» наберёт больше половины, придётся договариваться о разводе или воевать. Ожидаемая доля «за»: около %.0f%%." % [REGIONS[i]["short"], (rv_yes_share(i)) * 100.0]) if id == "referendum" else ("Ввести войска и комендантский час в регионе «%s»? Недовольство упадёт, но обида и сепаратизм вырастут; на стадии мятежа начнётся война." % REGIONS[i]["short"])
		cr_confirm.popup_centered(Vector2i(520, 160))
		return
	rv_region_act(id, i)


func on_cr_conf_act(id: String) -> void:
	if pl_deny():
		return
	var k := cr_sel_conf_idx()
	if k < 0:
		return
	if id == "recognize":
		cr_pending = "conf:" + id
		cr_confirm.dialog_text = "Признать независимость региона? Бои прекратятся, регион уйдёт мирно. Это необратимо."
		cr_confirm.popup_centered(Vector2i(480, 140))
		return
	rv_conf_act(id, k)


func on_cr_coup_measure(id: String) -> void:
	if pl_deny():
		return
	rv_coup_measure(id)


func on_cr_power(kind: String) -> void:
	var p := 0.0
	var txt := ""
	match kind:
		"self":
			p = rv_selfcoup_prob()
			txt = "Самопереворот: шанс успеха %.0f%%. Провал: арест и конец игры (55%%) или тяжёлое ослабление. Успех: режим указов, рост протестов и риск гражданской войны. Продолжить?" % (p * 100.0)
		"opp":
			p = rv_oppcoup_prob()
			txt = "Заговор: шанс успеха %.0f%%. Провал: партия запрещена, игра окончена. Продолжить?" % (p * 100.0)
		"rising":
			txt = "Народное восстание начнёт гражданскую войну на вашей стороне. Победа — власть, поражение — конец игры. Продолжить?"
	cr_pending = "pow:" + kind
	cr_confirm.dialog_text = txt
	cr_confirm.popup_centered(Vector2i(560, 170))


func on_cr_confirmed() -> void:
	var parts := cr_pending.split(":")
	cr_pending = ""
	if parts.size() < 2:
		return
	match parts[0]:
		"reg":
			var i := cr_sel_region_idx()
			if i >= 0:
				rv_region_act(parts[1], i)
		"conf":
			var k := cr_sel_conf_idx()
			if k >= 0:
				rv_conf_act(parts[1], k)
		"pow":
			match parts[1]:
				"self":
					rv_selfcoup()
				"opp":
					rv_oppcoup()
				"rising":
					rv_uprising()
	update_crisis_windows()


func update_crisis_windows() -> void:
	if cr_btn != null and not rv.is_empty():
		var hot := rv_conf_count() > 0
		color_button(cr_btn, COL_BAD if hot else Color(0.78, 0.86, 1.0))
	if cr_ov == null or rv.is_empty():
		return
	if cr_ov.visible and not current_event.is_empty():
		set_crisis_open(false)
	if not cr_ov.visible:
		return
	var nat: Dictionary = rv["nat"]
	var off := rv_lvl() == 0
	# --- сводка ---
	var s := ""
	if off:
		s += "[color=%s]Система кризисов отключена в настройках новой игры.[/color]\n\n" % COL_DIM
	var rows := [["Волна протестов", float(nat["wave"]), 35.0, 60.0, "недовольство людей по всей стране"],
		["Риск революции", float(nat["rev"]), 40.0, 65.0, "массовое восстание против власти"],
		["Риск переворота", float(nat["coup"]), 35.0, 58.0, "заговор в армии и аппарате"],
		["Общая обида", float(nat["hate"]), 25.0, 50.0, "память о репрессиях и насилии"]]
	for r in rows:
		var col: String = cr_col_for(float(r[1]), float(r[2]), float(r[3]))
		s += "[b]%s[/b] [color=%s]%.0f[/color] [color=%s]— %s[/color]\n[color=%s]%s[/color]\n" % [r[0], col, float(r[1]), COL_DIM, r[4], col, cr_bar(float(r[1]), 24)]
	s += "\nПоддержка силовиков: %.0f · безопасность: %.0f · лояльность армии: +%.0f" % [float(support["Силовики"]), float(lvl["security_lvl"]), float(nat["loyal"])]
	s += "\nСила армии для подавления: [b]%.0f[/b] · власть указами: %s · индекс демократии: %.0f%%" % [rv_gov_power(), "да" if decree_power() else "нет", democracy_index() * 100.0]
	s += "\nПотери рынка и безработица от кризисов: рост %+.2f п.п., безработица %+.2f п.п." % [revolt_g(), revolt_unemp()]
	cr_sum_rt.text = s
	var h: Dictionary = rv["h"]
	cr_spk.title = "Волна · революция · переворот"
	cr_spk.series = [{"v": h["wave"], "c": Color("#f0707a"), "n": "волна"}, {"v": h["rev"], "c": Color("#e8b84a"), "n": "революция"}, {"v": h["coup"], "c": Color("#6fa8dc"), "n": "переворот"}]
	cr_spk.ymin = 0.0
	cr_spk.ymax = 100.0
	cr_spk.queue_redraw()
	# --- перевороты ---
	for a in RV_COUP_MEASURES:
		var chk := rv_coup_measure_check(String(a["id"]))
		var bb: Button = cr_coup_btn[String(a["id"])]
		bb.disabled = chk != ""
		bb.tooltip_text = String(a["desc"]) + (("\nСейчас недоступно: " + chk) if chk != "" else "")
	var cs := ""
	var ch1 := rv_selfcoup_check()
	var ch2 := rv_oppcoup_check()
	var ch3 := rv_uprising_check()
	(cr_coup_btn["self"] as Button).disabled = ch1 != ""
	(cr_coup_btn["opp"] as Button).disabled = ch2 != ""
	(cr_coup_btn["rising"] as Button).disabled = ch3 != ""
	if not opp_mode:
		cs += "Самопереворот: шанс [b]%.0f%%[/b]%s\n" % [rv_selfcoup_prob() * 100.0, (" — недоступно: " + ch1) if ch1 != "" else ""]
	else:
		cs += "Заговор: шанс [b]%.0f%%[/b]%s\n" % [rv_oppcoup_prob() * 100.0, (" — недоступно: " + ch2) if ch2 != "" else ""]
		cs += "Восстание%s\n" % ((" — недоступно: " + ch3) if ch3 != "" else ": можно начать")
	cs += "[color=%s]Чем выше поддержка силовиков и безопасность, тем выше шанс; демократия и протесты против вас его снижают.[/color]" % COL_DIM
	cr_coup_rt.text = cs
	# --- потерянные регионы ---
	var st := ""
	for x in rv["states"]:
		st += "[b]%s[/b] — независимое государство с %s (%s), население %.1f млн, ВВП %.0f млрд\n" % [x["name"], date_after_turn(int(x["since"])), "после войны" if String(x["how"]) == "war" else "мирно", float(x["pop"]), float(x["gdp"])]
	cr_state_rt.text = st if st != "" else "[color=%s]Пока ни один регион не отделился.[/color]" % COL_DIM
	# --- регионы ---
	var order: Array = []
	for i in regions.size():
		order.append(i)
	order.sort_custom(func(a, b): return float(rv_reg(a)["stage"]) * 1000.0 + float(rv_reg(a)["sep"]) + float(regions[a]["unrest"]) > float(rv_reg(b)["stage"]) * 1000.0 + float(rv_reg(b)["sep"]) + float(regions[b]["unrest"]))
	var sel := cr_sel_region_idx()
	var t := "[table=7][cell][color=%s]Регион[/color][/cell][cell][color=%s] Стадия[/color][/cell][cell][color=%s] Недовол.[/color][/cell][cell][color=%s] Лояльн.[/color][/cell][cell][color=%s] Сепаратизм[/color][/cell][cell][color=%s] Обида[/color][/cell][cell][color=%s] Автоном.[/color][/cell]" % [COL_DIM, COL_DIM, COL_DIM, COL_DIM, COL_DIM, COL_DIM, COL_DIM]
	for i2 in order:
		var rg: Dictionary = rv_reg(i2)
		var stg: int = int(rg["stage"])
		var mark := "▶ " if i2 == sel else ""
		t += "[cell]%s[url=%s]%s[/url][/cell][cell] [color=%s]%s[/color][/cell][cell] %.0f[/cell][cell] %.0f[/cell][cell] [color=%s]%.0f[/color][/cell][cell] %.0f[/cell][cell] %.0f[/cell]" % [mark, rv_uid(i2), REGIONS[i2]["short"], RV_STAGE_COL[stg], RV_STAGE_NAMES[stg], float(regions[i2]["unrest"]), float(regions[i2]["loy"]), cr_col_for(float(rg["sep"]), 35.0, 60.0), float(rg["sep"]), float(rg["hate"]), float(regions[i2]["auto"])]
	t += "[/table]"
	cr_reg_rt.text = t
	if sel >= 0:
		var rg2: Dictionary = rv_reg(sel)
		var stg2: int = int(rg2["stage"])
		var d := "[b][font_size=16]%s[/font_size][/b]  [color=%s]%s[/color]\n" % [REGIONS[sel]["name"], RV_STAGE_COL[stg2], RV_STAGE_NAMES[stg2]]
		d += "Недовольство %.0f · лояльность %.0f · сепаратизм [b]%.0f[/b] (цель %.0f) · обида %.0f · автономия %.0f · население %.1f млн · доля ВВП %.1f%%\n" % [float(regions[sel]["unrest"]), float(regions[sel]["loy"]), float(rg2["sep"]), rv_sep_target(sel), float(rg2["hate"]), float(regions[sel]["auto"]), float(regions[sel]["popm"]), gdp_w[sel] * 100.0]
		d += "Самосознание региона: %.0f%%, отличие по вере: %.0f%%. Ожидаемая доля «за» на референдуме: около %.0f%%." % [float(REGIONS[sel].get("reg", 0.3)) * 100.0, rv_identity_gap(sel), (0.10 + float(rg2["sep"]) * 0.0062 + float(rg2["hate"]) * 0.002 - (float(regions[sel]["loy"]) - 40.0) * 0.003) * 100.0]
		if rv_is_capital(sel):
			d += "\n[color=%s]Столичный регион: отделиться не может.[/color]" % COL_DIM
		cr_sel_rt.text = d
		for a2 in RV_REG_ACTS:
			var chk2 := rv_reg_act_check(String(a2["id"]), sel)
			var b5: Button = cr_reg_btn[String(a2["id"])]
			b5.disabled = chk2 != ""
			b5.tooltip_text = String(a2["desc"]) + (("\nСейчас недоступно: " + chk2) if chk2 != "" else "")
	# --- конфликты ---
	var cf: Array = rv["conf"]
	var ks := cr_sel_conf_idx()
	var ct := ""
	if cf.is_empty():
		ct = "[color=%s]Вооружённых конфликтов нет.[/color]" % COL_DIM
	for k in cf.size():
		var c: Dictionary = cf[k]
		var mark2 := "▶ " if k == ks else ""
		var ctl: float = float(c["ctl"])
		var kindn: String = {"secession": "война за независимость", "insurgency": "мятеж", "civil": "гражданская война"}.get(String(c["kind"]), "конфликт")
		ct += "%s[url=%d][b]%s[/b][/url] — %s%s\n" % [mark2, int(c["id"]), c["name"], kindn, " (вы — повстанцы)" if String(c["side"]) == "rebel" else ""]
		ct += "Контроль повстанцев [color=%s]%s %.0f%%[/color] · сила повстанцев %.0f · сила власти %.0f · мобилизация %d/2 · потери ≈ %d тыс. · %d мес.%s\n" % [cr_col_for(ctl, 35.0, 60.0), cr_bar(ctl, 14), ctl, float(c["R"]), rv_gov_power(), int(c["mob"]), int(float(c["kia"])), turn - int(c["start"]), (" · перемирие" if int(c["truce"]) > 0 and int(c["truce"]) < 9000 else (" · заморожен" if int(c["truce"]) >= 9000 else ""))]
		ct += "[color=%s]%s[/color]\n\n" % [COL_DIM, c["cause"]]
	cr_conf_rt.text = ct
	for a3 in RV_CONF_ACTS:
		var chk3 := rv_conf_act_check(String(a3["id"]), ks) if ks >= 0 else "нет конфликта"
		var b6: Button = cr_conf_btn[String(a3["id"])]
		b6.disabled = chk3 != ""
		b6.tooltip_text = String(a3["desc"]) + (("\nСейчас недоступно: " + chk3) if chk3 != "" else "")
	var lg := ""
	var arr: Array = rv["log"]
	for k2 in range(arr.size() - 1, maxi(-1, arr.size() - 16), -1):
		lg += String(arr[k2]) + "\n"
	cr_log_rt.text = lg if lg != "" else "[color=%s]Пока тихо.[/color]" % COL_DIM


func date_after_turn(t: int) -> String:
	var months_total: int = (START_YEAR * 12 + 0) + t
	return "%d г." % (months_total / 12)


# v52: окна технологий и кризисов — только для правительства; вне власти сверху плашка с объяснением,
# содержимое можно читать, но кнопки не действуют (решения принимает правительство, технологии ведёт его советник)
func ov_lock_banner(ov: Control, why: String) -> void:
	if ov == null or ov.get_child_count() == 0:
		return
	var root: Node = ov.get_child(0)
	var ban: PanelContainer = root.get_node_or_null("LockBanner")
	if ban == null:
		ban = PanelContainer.new()
		ban.name = "LockBanner"
		ban.add_theme_stylebox_override("panel", sbox(Color(0.30, 0.10, 0.10, 0.92), C_BAD, 1, 8, 10.0, 6.0))
		var l := Label.new()
		l.name = "L"
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 14)
		l.add_theme_color_override("font_color", Color(1.0, 0.88, 0.85))
		ban.add_child(l)
		root.add_child(ban)
		root.move_child(ban, mini(1, root.get_child_count() - 1))
	ban.visible = why != ""
	(ban.get_node("L") as Label).text = "Недоступно. " + why + " Окно открыто для чтения; решения принимает правительство (технологии выбирает его советник)."


func overlays_lock() -> void:
	ov_lock_banner(tech_ov, pl_why())
	ov_lock_banner(cr_ov, pl_why())
