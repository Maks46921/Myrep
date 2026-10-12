# Интерфейс: парламент, полукруг, таблица партий.
extends "res://scripts/ui/ui_map.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func on_cr_power(kind: String) -> void:
	pass


func select_neg_party(p: int) -> void:
	pass


# --- конец заглушек ---


func build_hemicycle() -> void:
	var lay: Dictionary = ElectionView.hemi_layout(SEATS)
	hemi_pos = lay["pts"]
	hemi_rad = float(lay["rad"])


# ============================================================
#  ЭФФЕКТЫ (дополнено: отрасли, трансферты региона, довольство коалиции)
# ============================================================


func build_politics_windows() -> void:
	var w: FloatWindow = new_window("parliament", "Парламент: зал заседаний", 1, Rect2(0.0, 0.0, 0.28, 0.50), false)
	pol_header = add_wrap_label(w.body, "")
	hemi_ctl = Control.new()
	hemi_ctl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hemi_ctl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hemi_ctl.custom_minimum_size = Vector2(120.0, 90.0)
	hemi_ctl.clip_contents = true
	hemi_ctl.draw.connect(draw_hemi)
	hemi_ctl.gui_input.connect(on_hemi_input)
	hemi_ctl.mouse_exited.connect(func() -> void:
		hemi_hover = -1
		hemi_ctl.queue_redraw())
	w.body.add_child(hemi_ctl)
	upper_rt = make_rt(w.body)

	w = new_window("parties", "Партии (нажмите на название)", 1, Rect2(0.0, 0.50, 0.28, 0.50))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	w.body.add_child(grid)
	for h in ["Партия", "Мест", "Отнош.", "Довол.", ""]:
		var hl := Label.new()
		hl.text = h
		hl.add_theme_font_size_override("font_size", 12)
		hl.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8))
		grid.add_child(hl)
	party_rows.clear()
	for p in PARTY_NAMES.size():
		var nb := Button.new()
		nb.text = PARTY_NAMES[p]
		nb.flat = true
		nb.theme_type_variation = "SmallButton"
		nb.add_theme_font_size_override("font_size", 14)
		nb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		nb.focus_mode = Control.FOCUS_NONE
		nb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nb.clip_text = true
		color_button(nb, (PARTY_COLORS[p] as Color).lightened(0.25))
		nb.pressed.connect(select_party.bind(p))
		grid.add_child(nb)
		var l1 := Label.new()
		l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(l1)
		var l2 := Label.new()
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(l2)
		var l3 := Label.new()
		l3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(l3)
		var btn: Button = null
		if p > 0:
			btn = Button.new()
			btn.focus_mode = Control.FOCUS_NONE
			btn.custom_minimum_size = Vector2(70.0, 0.0)
			btn.add_theme_font_size_override("font_size", 13)
			btn.pressed.connect(toggle_coalition.bind(p))
			grid.add_child(btn)
		else:
			grid.add_child(Control.new())
		party_rows.append({"name": nb, "seats": l1, "att": l2, "sat": l3, "btn": btn})

	w = new_window("actions", "Политические действия", 1, Rect2(0.50, 0.64, 0.205, 0.36))
	for a in ACTIONS:
		var b := make_button("", w.body)
		b.pressed.connect(do_action.bind(a["id"]))
		action_rows[a["id"]] = b
		if a["id"] == "snap":
			var si: Dictionary = snap_info()
			add_note(w.body, "%s%s Рискованно, но при высоком рейтинге можно усилить большинство." % [String(si["desc"]), (" Голосование: %s." % String(si["vote"])) if String(si["vote"]) != "" else ""])
		else:
			add_note(w.body, a["desc"])
	# v50: захват власти, находясь у власти (самопереворот) — теперь и здесь, а не только в «Кризисах»
	add_title(w.body, "Захват всей власти")
	selfcoup_btn = make_button("Самопереворот: распустить парламент (12)", w.body)
	selfcoup_btn.tooltip_text = "Режим указов: парламент распущен, армия на вашей стороне. Младший партнёр при успехе ещё и отстраняет главу правительства. Шанс зависит от силовиков, безопасности, демократии и протестов."
	selfcoup_btn.pressed.connect(on_cr_power.bind("self"))
	selfcoup_note = add_note(w.body, "", true)

	w = new_window("party", "Партия: сведения", 1, Rect2(0.28, 0.0, 0.22, 1.0))
	party_detail_rt = make_rt(w.body)
	make_tail(party_detail_rt, "Подробнее о партии")
	party_btns.clear()
	for k in 4:
		var b := make_button("", w.body)
		b.pressed.connect(on_party_button.bind(k))
		party_btns.append(b)

	w = new_window("polls", "Выборы и опросы", 1, Rect2(0.50, 0.0, 0.205, 0.64))
	polls_rt = make_rt(w.body)
	make_tail(polls_rt, "О выборах и устойчивости власти")


func on_party_button(k: int) -> void:
	var p := selected_party
	if k == 0:
		toggle_coalition(p)
	elif k == 1:
		do_concession(p)
	elif k == 2:
		fulfill_party_demands(p)
	else:
		select_neg_party(p)


func update_parliament() -> void:
	if pol_header == null:
		return
	var gs := gov_seats()
	var status := "большинство есть" if gs >= MAJORITY else "меньшинство, но поддержка есть"
	if not gov_ok():
		status = "КРИЗИС, осталось %d мес." % maxi(0, crisis_limit() - crisis_months)
	var opp_only := opp_bloc()
	var imp := ""
	if opp_only >= impeach_seats() - 10:
		imp = " Оппозиция без «%s» близка к большинству (%d из %d): возможен конструктивный вотум недоверия при рейтинге ниже 42%%." % [party_abbr(9), opp_only, impeach_seats()]
	pol_header.text = loc("Коалиция: %d из %d (%s). Оппозиция: %d.%s" % [gs, SEATS, status, SEATS - gs, imp])
	pol_header.tooltip_text = "Яркие кружки с белым ободком — партии коалиции. Наведите на кружок или щёлкните, чтобы выбрать партию."
	hemi_ctl.queue_redraw()
	if upper_rt != null:
		upper_rt.text = loc(upper_summary())
	update_party_table()
	update_party_detail()


func draw_hemi() -> void:
	var c := hemi_ctl
	if c == null or hemi_pos.is_empty():
		return
	var w: float = c.size.x
	var h: float = c.size.y
	if w < 30.0 or h < 30.0:
		return
	var R: float = minf(w * 0.48, h * 0.94)
	var center := Vector2(w / 2.0, h * 0.97)
	var dot: float = clampf(R * hemi_rad, 1.6, 12.0)
	hemi_dot = dot
	var backdrop := PackedVector2Array()
	backdrop.append(center)
	for k in 49:
		var ang: float = PI + PI * float(k) / 48.0
		backdrop.append(center + Vector2(cos(ang), sin(ang)) * R * 1.07)
	c.draw_colored_polygon(backdrop, Color(1, 1, 1, 0.035))
	c.draw_arc(center, R * 1.07, PI, TAU, 64, Color(1, 1, 1, 0.10), 1.5)
	var assign: Array[int] = []
	for p in HEMI_ORDER:
		for k in seats[p]:
			assign.append(p)
	hemi_party.clear()
	hemi_px.clear()
	for i in hemi_pos.size():
		var a: float = hemi_pos[i][0]
		var rr: float = hemi_pos[i][1]
		var pos := center + Vector2(cos(a), -sin(a)) * (R * rr)
		var p: int = assign[i] if i < assign.size() else 9
		hemi_party.append(p)
		hemi_px.append(pos)
	var hov_party := -1
	if hemi_hover >= 0 and hemi_hover < hemi_party.size():
		hov_party = hemi_party[hemi_hover]
	for i in hemi_px.size():
		var p: int = hemi_party[i]
		var col: Color = PARTY_COLORS[p]
		var inc: bool = in_coalition[p]
		c.draw_circle(hemi_px[i], dot, col if inc else col.darkened(0.4))
		if inc:
			c.draw_arc(hemi_px[i], dot + 0.5, 0.0, TAU, 14, Color(1, 1, 1, 0.85), 1.3)
		if p == selected_party:
			c.draw_arc(hemi_px[i], dot + 2.5, 0.0, TAU, 14, Color(1, 0.9, 0.3, 0.9), 1.6)
		if p == hov_party:
			c.draw_circle(hemi_px[i], dot * 0.35, Color(1, 1, 1, 0.95))
	var font := c.get_theme_default_font()
	var gs := gov_seats()
	var tcol := Color(0.6, 1.0, 0.6) if gov_ok() else Color(1.0, 0.55, 0.5)
	# подпись «мест / всего» — по центру внутреннего круга, размер шрифта подбирается по ширине (без обрезки)
	var rin := R
	for hp in hemi_pos:
		rin = minf(rin, R * float(hp[1]))
	var txt := "%d / %d" % [gs, SEATS]
	var fs := int(clampf(R * 0.13, 11.0, 28.0))
	while fs > 9 and (font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).x > rin * 1.6 or float(fs) > rin * 0.5):
		fs -= 1
	var tw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).x
	var base_y: float = center.y - rin * 0.30
	c.draw_string(font, Vector2(center.x - tw * 0.5, base_y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, tcol)
	var sub := "нужно %d" % MAJORITY
	var fs2 := maxi(9, int(float(fs) * 0.62))
	var sw: float = font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs2).x
	c.draw_string(font, Vector2(center.x - sw * 0.5, base_y + float(fs) * 0.95), sub, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs2, Color(0.8, 0.8, 0.85))


func on_hemi_input(ev: InputEvent) -> void:
	var mm := ev as InputEventMouseMotion
	if mm != null:
		var best := -1
		var bd: float = hemi_dot * 1.9
		for i in hemi_px.size():
			var d: float = (hemi_px[i] as Vector2).distance_to(mm.position)
			if d < bd:
				bd = d
				best = i
		if best != hemi_hover:
			hemi_hover = best
			if best >= 0:
				var p: int = hemi_party[best]
				hemi_ctl.tooltip_text = "%s: %d мест%s" % [PARTY_NAMES[p], seats[p], " (в коалиции)" if in_coalition[p] else ""]
			else:
				hemi_ctl.tooltip_text = ""
			hemi_ctl.queue_redraw()
		return
	var mb := ev as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and hemi_hover >= 0:
		select_party(hemi_party[hemi_hover])


func update_party_table() -> void:
	var ps := parl_shares()
	for p in PARTY_NAMES.size():
		var row: Dictionary = party_rows[p]
		(row["name"] as Button).text = ("▶ " if p == selected_party else "") + PARTY_NAMES[p]
		(row["seats"] as Label).text = "%d" % seats[p]
		(row["att"] as Label).text = "%.0f" % party_attitude(p)
		var sl: Label = row["sat"]
		if p == 0:
			sl.text = "—"
		elif in_coalition[p]:
			var s: float = float(satis.get(p, 50.0))
			sl.text = "%.0f" % s
			sl.modulate = Color.html("#" + stat_color(s, false))
		else:
			sl.text = "—"
			sl.modulate = Color(1, 1, 1)
		var btn: Button = row["btn"]
		if btn != null:
			btn.text = "Исключить" if in_coalition[p] else "Позвать"
			btn.disabled = game_over or seats[p] == 0 or opp_mode
	var _unused := ps


func update_party_detail() -> void:
	var p := selected_party
	var col: String = (PARTY_COLORS[p] as Color).lightened(0.2).to_html(false)
	var ps := parl_shares()
	var t := "[b][font_size=18][color=#%s]%s[/color][/font_size][/b]\nЛидер: %s\n%s\n" % [col, PARTY_NAMES[p], PARTY_LEADERS[p], PARTY_DESC[p]]
	t += "Мест: [b]%d[/b] из %d. По опросу сейчас: %.1f%% голосов.\n" % [seats[p], SEATS, ps[p] * 100.0]
	var fm := funding_mode()
	if fm == 1:
		var fr := party_funded(p)
		t += "Госфинансирование: [color=%s]%s[/color] (голоса %s)\n" % [COL_GOOD if fr else COL_BAD, "получает" if fr else "не получает", sg((funding_mult(p) - 1.0) * 100.0, 0) + "%"]
	elif fm == 2:
		t += "Доноры без лимитов: влияние на голоса партии [b]%s[/b]\n" % (sg((funding_mult(p) - 1.0) * 100.0, 0) + "%")
	if p == 0:
		t += "Это ваша партия. Она всегда голосует за ваши законы.\n"
	else:
		t += electorate_text(p) + "\n"
		t += party_style_text(p) + "\n"
		if can_govern(p):
			if String(PARTY_TRAITS[p]["trait"]) != "":
				t += "[b]Характер лидера: %s.[/b] %s\n" % [PARTY_TRAITS[p]["trait"], PARTY_TRAITS[p]["desc"]]
			if is_cordon(p):
				t += "[color=%s]Другие партии держат вокруг неё «санитарный кордон»: коалиция возможна только при очень удачных обстоятельствах — хорошие отношения, щедрые обещания или затяжной кризис.[/color]\n" % COL_WARN
		t += "Отношение избирателей партии к власти: %.0f.\n" % party_attitude(p)
		if in_coalition[p]:
			var s: float = float(satis.get(p, 50.0))
			t += "[b]В коалиции.[/b] Довольство [color=#%s]%.0f[/color] (выйдет при < %.0f). Причины недовольства: %s.\n" % [stat_color(s, false), s, SAT_LEAVE, sat_reason(p)]
			t += "Министерства: %s.\n" % ministries_of(p)
		else:
			t += "Сейчас в оппозиции. Готовность войти в коалицию: %.0f (нужно %.0f).\n" % [willingness(p, false), COALITION_JOIN]
		if can_govern(p):
			var ld := law_demand_of(p)
			if not ld.is_empty():
				var met := law_demand_met(p)
				t += "\n[b]Закон-условие:[/b] [color=%s]%s %s[/color]\n" % [COL_GOOD if met else COL_BAD, "✔" if met else "✘", law_demand_text(p)]
			t += "[b]Бюджетные требования:[/b]\n" + demand_lines(p)
			var prefs: Array = PARTY_MINISTRIES[p]
			if prefs.size() > 0:
				var pn: PackedStringArray = []
				for m in prefs:
					var held: bool = ministries[m] == p
					pn.append(("✔ " if held else "") + String(MINISTRIES[m]["name"]))
				t += "Хочет министерства: %s.\n" % ", ".join(pn)
	set_tail_text(party_detail_rt, t, 4)
	var b0: Button = party_btns[0]
	var b1: Button = party_btns[1]
	var b2: Button = party_btns[2]
	var b3: Button = party_btns[3]
	b0.visible = can_govern(p)
	b1.visible = can_govern(p)
	b2.visible = can_govern(p) and not (PARTY_DEMANDS[p] as Array).is_empty()
	b3.visible = can_govern(p)
	if can_govern(p):
		b0.text = "Исключить из коалиции" if in_coalition[p] else "Пригласить в коалицию"
		b0.disabled = game_over or seats[p] == 0 or opp_mode
		b1.text = "Уступки партии (политкапитал 12)"
		b1.disabled = game_over or opp_mode or not in_coalition[p] or capital < 12.0
		b2.text = "Выполнить бюджетные требования"
		var unmet := false
		for d in PARTY_DEMANDS[p]:
			if not demand_met(d):
				unmet = true
		b2.disabled = game_over or not unmet
		b3.text = "Открыть переговоры (вкладка «Правительство»)"


func ministry_effect_text(m: int) -> String:
	var lv: String = MINISTRIES[m]["lvl"]
	match lv:
		"": return ""
		"growth": return "если министр из партии, которой оно нужно, рост ВВП слегка выше"
		"reg_dev": return "регионы развиваются быстрее"
		"corruption": return "коррупция ниже"
	return "%s выше" % STATE_NAMES.get(lv, lv)


# ---------- карта и регионы ----------
