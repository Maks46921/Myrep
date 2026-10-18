# Интерфейс: окно «Технологии» (v42_1) — отдельное окно поверх игры: схема технологий, сводка, сооружения.
extends "res://scripts/ui/ui_society.gd"

var tech_ov: PanelContainer = null
var tech_btn: Button = null
var tech_view: Control = null
var tech_scroll: ScrollContainer = null
var tw_left_box: VBoxContainer = null   # левая колонка (сюда встраиваются секции v44_1)
var tw_sum_rt: RichTextLabel
var tw_info_rt: RichTextLabel
var tw_spk: Control
var tw_bld_rt: RichTextLabel
var tw_bld_box: VBoxContainer
var tw_wlbl: Array = []
var tw_wbtn: Array = []
var tw_auto: Button
var tw_ai_all: Button
var tw_filter: Array = []
var tw_hover := ""
var tw_sig := ""
var tw_first := true
var tw_q_box: VBoxContainer = null      # 0.56: очередь изучения (правая колонка)
var tw_q_sig := ""


func make_tech_button(parent: Control) -> void:
	tech_btn = Button.new()
	tech_btn.theme_type_variation = "TabButton"
	tech_btn.text = "Технологии"
	tech_btn.toggle_mode = true
	tech_btn.focus_mode = Control.FOCUS_NONE
	tech_btn.custom_minimum_size = Vector2(0.0, 40.0)
	tech_btn.tooltip_text = "Окно технологий: схема исследований, сооружения, пассивное изучение от соседей."
	tech_btn.toggled.connect(on_tech_toggle)
	btn_icon(tech_btn, "flask")
	parent.add_child(tech_btn)


func tech_is_open() -> bool:
	return tech_ov != null and tech_ov.visible


func on_tech_toggle(on: bool) -> void:
	set_tech_open(on)


func set_tech_open(on: bool) -> void:
	if tech_ov == null:
		return
	if on != tech_ov.visible:
		sfx("click")
	if on and crisis_is_open():
		set_crisis_open(false)
	if on and meas_is_open():
		set_meas_open(false)
	if on and cn_is_open():
		cn_close()
	var was: bool = tech_ov.visible
	tech_ov.visible = on
	if on and not was:
		win_fade_in(tech_ov, 0.18)
	if tech_btn != null:
		tech_btn.set_pressed_no_signal(on)
	overlay_tabs_sync()
	if on:
		tw_sig = ""
		refresh()
		if tw_first:
			tw_first = false
			tech_scroll_to_frontier.call_deferred()


func tech_scroll_to_frontier() -> void:
	# прокрутить схему к первому неизученному уровню
	if tech_scroll == null or tech.is_empty():
		return
	var best := 99
	for b in TECH_NB:
		for t in (tech["grp"][b] as Dictionary):
			if tech_tier_done(b, int(t)) == "":
				best = mini(best, int(t))
				break
	var x := maxf(0.0, float(best - 1) * (TechView.NW + TechView.GX)) * float(tech_view.get("zoom"))
	tech_scroll.scroll_horizontal = int(x)


func build_tech_windows() -> void:
	tech_ov = PanelContainer.new()
	tech_ov.add_theme_stylebox_override("panel", sbox(Color(0.055, 0.066, 0.096, 0.985), C_ACCENT.darkened(0.25), 2, 12, 12.0, 10.0))
	tech_ov.visible = false
	add_child(tech_ov)
	tech_ov.anchor_right = 1.0
	tech_ov.anchor_bottom = 1.0
	tech_ov.offset_left = 8.0
	tech_ov.offset_top = 62.0
	tech_ov.offset_right = -8.0
	tech_ov.offset_bottom = -8.0
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	tech_ov.add_child(root)
	# --- шапка ---
	var hd := HBoxContainer.new()
	hd.add_theme_constant_override("separation", 6)
	root.add_child(hd)
	var ttl := Label.new()
	ttl.text = "Технологии"
	ttl.add_theme_font_size_override("font_size", 22)
	ttl.add_theme_color_override("font_color", C_TEXT)
	hd.add_child(ttl)
	var sp0 := Control.new()
	sp0.custom_minimum_size = Vector2(14.0, 0.0)
	hd.add_child(sp0)
	var grp := ButtonGroup.new()
	var names := ["Все ветки"]
	for b in TECH_NB:
		names.append(String(TECH_BRANCHES[b]["name"]))
	for k in names.size():
		var fb := Button.new()
		fb.theme_type_variation = "TabButton"
		fb.text = names[k]
		fb.toggle_mode = true
		fb.button_group = grp
		fb.focus_mode = Control.FOCUS_NONE
		fb.custom_minimum_size = Vector2(0.0, 30.0)
		if k > 0:
			color_button(fb, Color(String(TECH_BRANCHES[k - 1]["col"])).lightened(0.2))
		fb.pressed.connect(on_tech_filter.bind(k))
		hd.add_child(fb)
		tw_filter.append(fb)
	(tw_filter[0] as Button).set_pressed_no_signal(true)
	var sp1 := Control.new()
	sp1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hd.add_child(sp1)
	var legend := Label.new()
	legend.text = "✔ изучено   ▶ изучается   ○ можно начать   ✖ не выбрана   ● соседи знают"
	legend.add_theme_font_size_override("font_size", 12)
	legend.add_theme_color_override("font_color", C_DIM)
	hd.add_child(legend)
	var cl := Button.new()
	cl.text = "✕ Закрыть"
	cl.focus_mode = Control.FOCUS_NONE
	cl.pressed.connect(set_tech_open.bind(false))
	hd.add_child(cl)
	# --- тело ---
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var left := PanelContainer.new()
	left.custom_minimum_size = Vector2(340.0, 0.0)
	left.add_theme_stylebox_override("panel", sbox(C_PANEL, C_BORDER, 1, 8, 8.0, 6.0))
	body.add_child(left)
	var lsc := ScrollContainer.new()
	lsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(lsc)
	var lv := VBoxContainer.new()
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lv.add_theme_constant_override("separation", 6)
	lsc.add_child(lv)
	tw_left_box = lv
	tw_sum_rt = make_rt(lv)
	add_title(lv, "Силы по веткам")
	for b2 in TECH_NB:
		var row := HBoxContainer.new()
		lv.add_child(row)
		var sw := ColorRect.new()
		sw.color = Color(String(TECH_BRANCHES[b2]["col"]))
		sw.custom_minimum_size = Vector2(10.0, 22.0)
		row.add_child(sw)
		var nl := Label.new()
		nl.text = " " + String(TECH_BRANCHES[b2]["name"])
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(nl)
		var bm := Button.new()
		bm.text = "−"
		bm.focus_mode = Control.FOCUS_NONE
		bm.pressed.connect(on_tech_weight.bind(b2, -1))
		row.add_child(bm)
		var wl := Label.new()
		wl.custom_minimum_size = Vector2(60.0, 0.0)
		wl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(wl)
		var bp := Button.new()
		bp.text = "+"
		bp.focus_mode = Control.FOCUS_NONE
		bp.pressed.connect(on_tech_weight.bind(b2, 1))
		row.add_child(bp)
		tw_wlbl.append(wl)
		tw_wbtn.append([bm, bp])
	tw_auto = fed_btn("ИИ-советник выбирает технологии", lv, "Если включён, свободная ветка сама берёт технологию, которая сильнее всего отвечает нуждам страны (рост, безработица, безопасность, коррупция, недовольные группы…). На уровнях «или» советник ждёт вашего решения полгода.")
	tw_auto.toggle_mode = true
	tw_auto.toggled.connect(on_tech_auto)
	tw_ai_all = fed_btn("Советник решает и «или» сразу", lv, "Не ждать вашего решения на уровнях «или»: советник сразу выбирает лучший вариант и пишет в журнал причину.")
	tw_ai_all.toggle_mode = true
	tw_ai_all.toggled.connect(on_tech_ai_all)
	tw_spk = Spark.new()
	lv.add_child(tw_spk)
	add_title(lv, "Научные сооружения")
	tw_bld_rt = make_rt(lv)
	tw_bld_box = VBoxContainer.new()
	tw_bld_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lv.add_child(tw_bld_box)
	# 0.56: строятся в окне «Строительство» (раздел «Наука»)
	var ob := make_button("Открыть строительство", lv)
	ob.tooltip_text = "Научные сооружения строятся в окне «Строительство», раздел «Наука»."
	ob.pressed.connect(bld_open)
	# схема + информация
	var rv := VBoxContainer.new()
	rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rv.add_theme_constant_override("separation", 8)
	body.add_child(rv)
	var sc := PanelContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.add_theme_stylebox_override("panel", sbox(Color(0.04, 0.05, 0.075), C_BORDER, 1, 8, 4.0, 4.0))
	rv.add_child(sc)
	tech_scroll = ScrollContainer.new()
	tech_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	tech_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	sc.add_child(tech_scroll)
	tech_view = TechView.new()
	tech_view.scroll = tech_scroll
	tech_scroll.add_child(tech_view)
	tech_view.picked.connect(on_tech_pick)
	tech_view.hovered.connect(on_tech_hover)
	var ip := PanelContainer.new()
	ip.custom_minimum_size = Vector2(0.0, 158.0)
	ip.add_theme_stylebox_override("panel", sbox(C_PANEL, C_BORDER, 1, 8, 10.0, 6.0))
	rv.add_child(ip)
	var isc := ScrollContainer.new()
	isc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ip.add_child(isc)
	tw_info_rt = make_rt(isc)
	# 0.56: очередь изучения справа — у каждой ветки своя колонка
	var qp := PanelContainer.new()
	qp.custom_minimum_size = Vector2(270.0, 0.0)
	qp.add_theme_stylebox_override("panel", sbox(C_PANEL, C_BORDER, 1, 8, 8.0, 6.0))
	body.add_child(qp)
	var qsc := ScrollContainer.new()
	qsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	qp.add_child(qsc)
	var qv := VBoxContainer.new()
	qv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	qv.add_theme_constant_override("separation", 4)
	qsc.add_child(qv)
	add_title(qv, "Очередь изучения")
	var qn := add_note(qv, "Shift + щелчок по технологии — добавить в очередь. Щелчок по ещё недоступной — тоже в очередь. Когда ветка изучит текущую, она возьмёт первую доступную из очереди.", true)
	qn.add_theme_font_size_override("font_size", 12)
	tw_q_box = VBoxContainer.new()
	tw_q_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tw_q_box.add_theme_constant_override("separation", 3)
	qv.add_child(tw_q_box)


func on_tech_filter(k: int) -> void:
	if tech.is_empty() or tech_view == null:
		return
	var v: Array = []
	for b in TECH_NB:
		v.append(k == 0 or k - 1 == b)
	tech_view.set_game(self)
	tech_view.set_visible_branches(v)
	tech_scroll.scroll_vertical = 0
	tech_scroll_to_frontier.call_deferred()
	refresh()


func on_tech_weight(b: int, d: int) -> void:
	if pl_deny():
		return
	tech_set_weight(b, d)


func on_tech_auto(on: bool) -> void:
	if tech.is_empty() or pl_deny():
		refresh()
		return
	tech["auto"] = on
	refresh()


func on_tech_ai_all(on: bool) -> void:
	if tech.is_empty() or pl_deny():
		refresh()
		return
	tech["ai_all"] = on
	refresh()


func on_tech_hover(id: String) -> void:
	tw_hover = id
	tech_info_update()


func on_tech_pick(id: String) -> void:
	var d := tech_def(id)
	if d.is_empty() or game_over or pl_deny():
		return
	var b: int = int(d["b"])
	# 0.56: Shift + щелчок — в очередь изучения
	if Input.is_key_pressed(KEY_SHIFT):
		if tech_q_add(id):
			sfx("click")
		refresh()
		return
	if String(tech["cur"][b]) == id:
		if not bool(tech["auto"]):
			tech_select(b, "")
		return
	if tech_avail(id):
		tech_select(b, id)
		sfx("click")
	elif tech_swap_check(id) == "":
		# v50: щелчок по невыбранной альтернативе — пересмотреть выбор «или» за те же очки
		tech_swap(id)
		sfx("click")
	elif not tech_never(id) and tech_q_add(id):
		# 0.56: недоступная пока технология встаёт в очередь
		sfx("click")
		refresh()
	tech_info_update()


func on_tech_build(id: String) -> void:
	if pl_deny():
		return
	tech_build(id)


func tech_bar(frac: float, n: int = 12) -> String:
	var k: int = int(round(clampf(frac, 0.0, 1.0) * n))
	return "█".repeat(k) + "░".repeat(n - k)


func tech_info_text(id: String) -> String:
	var d := tech_def(id)
	var b: int = int(d["b"])
	var bc: String = TECH_BRANCHES[b]["col"]
	var t := "[color=%s][b][font_size=17]%s[/font_size][/b][/color]  [color=%s]%s ветка · уровень %d[/color]\n" % [bc, d["name"], COL_DIM, String(TECH_BRANCHES[b]["name"]), int(d["t"]) + 1]
	t += "%s\n" % d["d"]
	t += "[color=%s]Эффект:[/color] %s\n" % [COL_DIM, tech_fx_text(d)]
	var miss := tech_missing(id)
	var st := ""
	if tech_done(id):
		st = "[color=%s]Изучено[/color]" % COL_GOOD
	elif String(tech["cur"][b]) == id:
		st = "[color=%s]Изучается: %.0f%%[/color] (%d из %d очк.)" % [bc, tech_progress(id) * 100.0, int(float(tech["prog"].get(id, 0.0))), int(d["cost"])]
	elif miss == "":
		st = "[color=%s]Можно изучать[/color] — щёлкните по карточке. Стоимость: %d очк." % [COL_WARN, int(d["cost"])]
	else:
		st = "[color=%s]Недоступно: %s[/color]" % [COL_BAD, miss]
	t += st + "\n"
	var al := tech_alts(id)
	if al.size() > 0:
		var an := PackedStringArray()
		for a in al:
			an.append("«%s»" % tech_def(String(a))["name"])
		t += "[color=%s]Выбор «или»: изучив эту технологию, вы закроете %s.[/color]\n" % [COL_WARN, ", ".join(an)]
	if not tech_done(id):
		var needs := tech_needs_player()
		var sc: float = tech_score(id, needs)
		var why := tech_score_text(id, needs)
		t += "[color=%s]Оценка ИИ-советника: %.1f%s.[/color]" % ["#b9e0a5", sc, (" — главное: " + why) if why != "" else ""]
		if al.size() > 0:
			var bestid := id
			var bsc := sc
			for a2 in al:
				var s2: float = tech_score(String(a2), needs)
				if s2 > bsc:
					bsc = s2
					bestid = String(a2)
			if bestid == id:
				t += " [color=%s]Лучший вариант в группе по мнению ИИ.[/color]\n" % "#b9e0a5"
			else:
				t += " [color=%s]Лучше, по мнению ИИ: «%s» (%.1f).[/color]\n" % [COL_DIM, tech_def(bestid)["name"], bsc]
		else:
			t += "\n"
	var nbs := tech_nb()
	if nbs.size() > 0 and not tech_done(id):
		var who := tech_nb_who(id)
		if who.size() > 0:
			var wn := PackedStringArray()
			for c in who:
				wn.append(String(WORLD[c]["name"]))
			t += "[color=%s]Соседи знают (%d из %d): %s. Пассивное изучение: +%.2f очк./мес. (не более %.0f%% цены).[/color]" % ["#7fd8ff", who.size(), nbs.size(), ", ".join(wn), tech_passive_rate(id), TECH_PASSIVE_CAP * 100.0]
		else:
			t += "[color=%s]У соседей (%d) этой технологии пока нет.[/color]" % [COL_DIM, nbs.size()]
	return t


func tech_swap_note(id: String) -> String:
	var why := tech_swap_check(id)
	if why == "":
		return "\n[color=%s]Щёлкните, чтобы пересмотреть выбор «или»: перейти на эту технологию за уже вложенные очки (раз в год).[/color]" % COL_TEAL
	return ""


func tech_info_update() -> void:
	if tw_info_rt == null or tech.is_empty():
		return
	if tw_hover != "":
		tw_info_rt.text = tech_info_text(tw_hover) + "\n[color=%s]Подветка: %s[/color]" % [COL_DIM, tech_lane_name(tw_hover)] + tech_swap_note(tw_hover)
		return
	var t := "[color=%s]Наведите курсор на карточку технологии, чтобы увидеть описание; щёлкните, чтобы начать изучение. Схему можно двигать, зажав левую кнопку на пустом месте, или колесом (Shift — по горизонтали).[/color]\n" % COL_DIM
	var cur := PackedStringArray()
	for b in TECH_NB:
		var id: String = tech["cur"][b]
		if id != "":
			cur.append("[color=%s]■[/color] %s — %.0f%%" % [TECH_BRANCHES[b]["col"], tech_def(id)["name"], tech_progress(id) * 100.0])
		elif tech_choice_waiting(b):
			cur.append("[color=%s]■[/color] [color=%s]%s: нужен ваш выбор[/color]" % [TECH_BRANCHES[b]["col"], COL_WARN, TECH_BRANCHES[b]["name"]])
		else:
			cur.append("[color=%s]■[/color] %s: ждёт новых открытий" % [TECH_BRANCHES[b]["col"], TECH_BRANCHES[b]["name"]])
	t += "\n".join(cur)
	tw_info_rt.text = t


# v50: ветки, где сейчас ничего не изучается, хотя есть что начать (очки уходят впустую)
func tech_idle_branches() -> int:
	var n := 0
	for b in TECH_NB:
		if String(tech["cur"][b]) != "" or int(tech["w"][b]) <= 0:
			continue
		if tech_ai_pick(b, true) != "":
			n += 1
	return n


func tech_tab_mark() -> void:
	if tech_btn == null or tech.is_empty():
		return
	var idle := tech_idle_branches()
	if idle > 0:
		color_button(tech_btn, Color(1.0, 0.42, 0.40))
		tech_btn.self_modulate = Color(1.0, 0.62, 0.60)
		tech_btn.tooltip_text = "Внимание: в %d ветк. ничего не изучается — выберите технологию (или включите автовыбор в окне технологий)." % idle
	else:
		color_button(tech_btn, C_TEXT)
		tech_btn.self_modulate = Color(1, 1, 1)
		tech_btn.tooltip_text = "Окно технологий: схема исследований, сооружения, пассивное изучение от соседей."


func update_tech_windows() -> void:
	if tech_ov == null or tech.is_empty():
		return
	tech_tab_mark()
	if not tech_ov.visible:
		return
	tech_refresh_rates()
	var spd: float = tech["speed"]
	var raw: float = tech["raw"]
	var cap: float = tech["cap"]
	var fr: float = tech_freedom()
	var s := "[b][font_size=17]Скорость: %.1f очк./мес.[/font_size][/b]\n" % spd
	s += "Потолок скорости: [b]%.1f[/b] · «сырая» скорость: %.1f\n" % [cap, raw]
	if raw > cap:
		s += "[color=%s]Вы выше потолка: лишние %.1f дают только %.1f.[/color]\n" % [COL_WARN, raw - cap, spd - cap]
	else:
		s += "[color=%s]До потолка ещё %.1f очк.: можно поднять расходы на образование и построить сооружения.[/color]\n" % [COL_DIM, cap - raw]
	s += "\n[b]Откуда берётся скорость[/b]\n"
	s += "Образование: %.1f%% ВВП (обычно %.1f%%) → ×%.2f\n" % [float(pol["edu"]), float(pol_def["edu"]), tech_edu_term()]
	s += "Сооружения: %s · технологии: %s\n" % [sg(tech_bsum("sp", -2) * 100.0, 0) + "%", sg(tech_sum("rs") * 100.0, 0) + "%"]
	var yrs: float = years_passed()
	s += "\n[b]Что поднимает потолок[/b]\n"
	s += "Время ×%.2f · ВВП ×%.2f\n" % [1.0 + TECH_CAP_YEAR * yrs, clampf(sqrt(gdp / maxf(1.0, gdp_base)), 0.8, 3.0)]
	var fcol: String = COL_GOOD if fr >= 0.6 else (COL_WARN if fr >= 0.4 else COL_BAD)
	s += "Свобода слова [color=%s]%.0f%%[/color] → ×%.2f\n" % [fcol, fr * 100.0, TECH_FREE_BASE + TECH_FREE_SPAN * fr]
	var bonus: float = tech_sum("cp") + tech_bsum("cpb", -2)
	if bonus > 0.0:
		s += "Технологии и лаборатории: +%.0f%%\n" % (bonus * 100.0)
	var pas := 0.0
	for b in TECH_NB:
		pas += float(tech["pasm"][b])
	s += "\n[b]Пассивное изучение[/b]\nСоседей: %d (%s). Сейчас даёт +%.2f очк./мес.\n" % [tech_nb().size(), ", ".join(PackedStringArray(tech_nb())), pas]
	s += "\n[b]Изучено: %d из %d[/b] · очков накоплено: %.0f" % [tech_count(), tech_total(), float(tech["pts"])]
	var nch := 0
	for b6 in TECH_NB:
		if tech_choice_waiting(b6):
			nch += 1
	if nch > 0:
		s += "\n[color=%s][b]Ждут вашего выбора: %d ветк.[/b][/color]" % [COL_WARN, nch]
	var up: float = tech_edu_upkeep()
	if up > 0.0:
		s += "\nСодержание сооружений: %.2f%% ВВП (%.1f млрд) в год — входит в расходы на образование." % [up, gdp * up / 100.0]
	tw_sum_rt.text = s
	var wsum := 0.0
	for b2 in TECH_NB:
		wsum += float(tech["w"][b2])
	for b3 in TECH_NB:
		var sh: float = float(tech["w"][b3]) / wsum if wsum > 0.0 else 0.0
		(tw_wlbl[b3] as Label).text = "%d · %.1f" % [int(tech["w"][b3]), spd * sh]
		(tw_wbtn[b3][0] as Button).disabled = game_over or int(tech["w"][b3]) <= 0
		(tw_wbtn[b3][1] as Button).disabled = game_over or int(tech["w"][b3]) >= 4
	tw_auto.set_pressed_no_signal(bool(tech["auto"]))
	tw_ai_all.set_pressed_no_signal(bool(tech["ai_all"]))
	tw_ai_all.disabled = not bool(tech["auto"])
	var hh: Dictionary = tech["h"]
	tw_spk.title = "Скорость (зелёная) и потолок (жёлтая)"
	tw_spk.series = [{"v": hh["s"], "c": Color("#58c887"), "n": "скорость"}, {"v": hh["c"], "c": Color("#e8b84a"), "n": "потолок"}]
	tw_spk.queue_redraw()
	var sig := "%s|%d|%d|%s" % [str(tech["bld"]), tech["q"].size(), int(gdp / 50.0), str(game_over)]
	if sig != tw_sig:
		tw_sig = sig
		tech_build_buildings()
	tech_buildings_text()
	tech_queue_ui()
	if tech_view != null:
		if tech_view.game == null:
			tech_view.set_game(self)
		tech_view.queue_redraw()
	tech_info_update()


func tech_queue_ui() -> void:
	if tw_q_box == null:
		return
	var sig := str(tech.get("rq", [])) + "|" + str(tech["cur"]) + "|" + str(game_over)
	if sig == tw_q_sig:
		return
	tw_q_sig = sig
	tech_clear(tw_q_box)
	for b in TECH_NB:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 4)
		tw_q_box.add_child(hb)
		var sw := ColorRect.new()
		sw.color = Color(String(TECH_BRANCHES[b]["col"]))
		sw.custom_minimum_size = Vector2(8.0, 18.0)
		hb.add_child(sw)
		var nl := Label.new()
		nl.text = String(TECH_BRANCHES[b]["name"])
		nl.add_theme_font_size_override("font_size", 13)
		hb.add_child(nl)
		var cur: String = tech["cur"][b]
		var cl := Label.new()
		cl.text = ("▶ " + String(tech_def(cur)["name"])) if cur != "" else "▶ —"
		cl.add_theme_font_size_override("font_size", 12)
		cl.add_theme_color_override("font_color", C_DIM)
		cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tw_q_box.add_child(cl)
		var q := tech_rq(b)
		for k in q.size():
			var id: String = q[k]
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 2)
			tw_q_box.add_child(row)
			var il := Label.new()
			il.text = "%d. %s" % [k + 1, tech_def(id).get("name", id)]
			il.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			il.clip_text = true
			il.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			il.add_theme_font_size_override("font_size", 12)
			var miss := tech_missing(id)
			il.tooltip_text = String(tech_def(id).get("name", id)) + ("" if miss == "" else "\nПока нельзя: " + miss)
			if miss != "":
				il.add_theme_color_override("font_color", C_DIM)
			il.mouse_filter = Control.MOUSE_FILTER_PASS
			row.add_child(il)
			for e in [["↑", -1, "Выше"], ["↓", 1, "Ниже"], ["✕", 0, "Убрать из очереди"]]:
				var bb := Button.new()
				bb.theme_type_variation = "SmallButton"
				bb.text = String(e[0])
				bb.focus_mode = Control.FOCUS_NONE
				bb.tooltip_text = String(e[2])
				bb.disabled = game_over or (int(e[1]) < 0 and k == 0) or (int(e[1]) > 0 and k == q.size() - 1)
				var bk: int = b
				var kk: int = k
				var dd: int = int(e[1])
				bb.pressed.connect(func() -> void:
					if dd == 0:
						tech_q_del(bk, kk)
					else:
						tech_q_move(bk, kk, dd)
					refresh())
				row.add_child(bb)
		if q.is_empty():
			var el := Label.new()
			el.text = "очередь пуста"
			el.add_theme_font_size_override("font_size", 12)
			el.add_theme_color_override("font_color", C_DIM)
			tw_q_box.add_child(el)


func tech_clear(box: Control) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func tech_build_buildings() -> void:
	tech_clear(tw_bld_box)
	return
	for d in TECH_BUILDINGS:
		var id: String = d["id"]
		var miss := tech_build_missing(id)
		var btn := make_button("%s (%.1f млрд)" % [d["name"], gdp * float(d["cost"]) / 100.0], tw_bld_box)
		btn.disabled = game_over or miss != ""
		btn.tooltip_text = "%s\nСрок: %d мес. Содержание: %.2f%% ВВП в год.%s" % [d["d"], int(d["months"]), float(d["up"]), ("\nСейчас нельзя: " + miss) if miss != "" else ""]
		btn.pressed.connect(on_tech_build.bind(id))


func tech_buildings_text() -> void:
	var t := ""
	for d in TECH_BUILDINGS:
		var id: String = d["id"]
		var inq := 0
		var left := 0
		for q in tech["q"]:
			if q["id"] == id:
				inq += 1
				left = maxi(left, int(q["left"]))
		var gives: PackedStringArray = []
		if float(d["sp"]) > 0.0:
			gives.append("скорость +%.0f%%" % (float(d["sp"]) * 100.0))
		if float(d["pw"]) > 0.0:
			gives.append("сила %s +%.0f%%" % ["всех технологий" if int(d["br"]) < 0 else "ветки «%s»" % String(TECH_BRANCHES[int(d["br"])]["name"]).to_lower(), float(d["pw"]) * 100.0])
		if float(d["cpb"]) > 0.0:
			gives.append("потолок +%.0f%%" % (float(d["cpb"]) * 100.0))
		t += "%s: построено %d/%d%s — [color=%s]%s[/color]\n" % [d["name"], int(tech["bld"][id]), int(d["max"]), (", строится %d (ещё %d мес.)" % [inq, left]) if inq > 0 else "", COL_DIM, ", ".join(gives)]
	tw_bld_rt.text = t
