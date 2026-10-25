# Интерфейс: окна событий и выборов.
extends "res://scripts/ui/ui_pop.gd"

func show_head_election(rep: Dictionary) -> void:
	sfx("election")
	election_open = true
	elec_end = String(rep["end"])
	el_view.visible = false
	el_head.visible = true
	var sham: bool = bool(rep["sham"])
	var gold := Color(1.0, 0.82, 0.40) if not sham else C_BAD
	el_banner.add_theme_stylebox_override("panel", ev_style(gold))
	el_title.text = loc(String(rep["title"]))
	el_title.add_theme_color_override("font_color", gold.lightened(0.2))
	var rs: String = String(rep["reason"])
	el_sub.text = loc("%s  ·  %s" % [date_text(), rs.substr(0, 1).to_upper() + rs.substr(1)])
	el_meta.text = loc(String(rep["meta"]))
	var vcol: Color = rep["vcol"]
	el_verdict_box.add_theme_stylebox_override("panel", ev_style(vcol))
	el_verdict_title.text = loc(String(rep["vtitle"]))
	el_verdict_title.add_theme_color_override("font_color", vcol.lightened(0.3))
	el_verdict_rt.text = loc(String(rep["vtext"]))
	el_verdict_box.modulate = Color(1, 1, 1, 0.0)
	el_btn.text = "Продолжить  (Enter)" if elec_end == "" else "Принять итоги  (Enter)"
	el_btn.disabled = true
	el_head.set_data(rep["rounds"])
	var w: FloatWindow = wins["election"]
	w.visible = true
	w.move_to_front()
	if wins.has("event"):
		(wins["event"] as FloatWindow).visible = false
	set_time_btns(true)
	el_head.set_progress(0.0)
	if el_tween != null:
		el_tween.kill()
	var nr: int = (rep["rounds"] as Array).size()
	el_tween = create_tween()
	el_tween.tween_method(func(v: float) -> void: el_head.set_progress(v), 0.0, 1.0, 1.0 + 0.9 * float(nr))
	el_tween.tween_property(el_verdict_box, "modulate", Color(1, 1, 1, 1), 0.45)
	el_tween.tween_callback(func() -> void: el_btn.disabled = false)
	if observer and is_inside_tree():
		get_tree().create_timer(3.5).timeout.connect(election_continue)
	if observer and is_inside_tree():
		get_tree().create_timer(3.5).timeout.connect(election_continue)


func build_election_window() -> void:
	var w: FloatWindow = new_window("election", "Выборы", -2, Rect2(0.09, 0.02, 0.62, 0.96))
	w.custom_minimum_size = Vector2(520.0, 420.0)
	el_banner = PanelContainer.new()
	var gold := Color(1.0, 0.82, 0.40)
	el_banner.add_theme_stylebox_override("panel", ev_style(gold))
	w.body.add_child(el_banner)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	el_banner.add_child(hb)
	var gl := Label.new()
	gl.text = "★"
	gl.add_theme_font_size_override("font_size", 40)
	gl.add_theme_color_override("font_color", gold)
	gl.custom_minimum_size = Vector2(44.0, 0.0)
	gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hb.add_child(gl)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(vb)
	el_title = Label.new()
	el_title.add_theme_font_size_override("font_size", 24)
	el_title.add_theme_color_override("font_color", gold.lightened(0.2))
	vb.add_child(el_title)
	el_sub = Label.new()
	el_sub.add_theme_font_size_override("font_size", 14)
	el_sub.add_theme_color_override("font_color", C_DIM)
	vb.add_child(el_sub)
	el_meta = add_note(w.body, "")
	el_view = ElectionView.new()
	el_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	w.body.add_child(el_view)
	el_head = HeadView.new()
	el_head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	el_head.visible = false
	w.body.add_child(el_head)
	el_verdict_box = PanelContainer.new()
	w.body.add_child(el_verdict_box)
	var vv := VBoxContainer.new()
	vv.add_theme_constant_override("separation", 4)
	el_verdict_box.add_child(vv)
	el_verdict_title = Label.new()
	el_verdict_title.add_theme_font_size_override("font_size", 19)
	el_verdict_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vv.add_child(el_verdict_title)
	el_verdict_rt = make_rt(vv)
	el_btn = Button.new()
	el_btn.text = "Продолжить  (Enter)"
	el_btn.focus_mode = Control.FOCUS_NONE
	el_btn.theme_type_variation = "AccentButton"
	el_btn.custom_minimum_size = Vector2(190.0, 44.0)
	el_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	el_btn.pressed.connect(election_continue)
	hb.add_child(el_btn)
	w.body.move_child(el_verdict_box, 2)


func show_election(rep: Dictionary) -> void:
	sfx("election")
	election_open = true
	elec_end = String(rep["end"])
	var shares: Array = rep["shares"]
	var raw: Array = rep["raw"]
	var prev: Array = rep["prev"]
	var old_seats: Array = rep["old_seats"]
	var thr: float = float(rep["thr"])
	var rows: Array = []
	var failed_n := 0
	for p in PARTY_NAMES.size():
		var passed: bool = seats[p] > 0
		var sh: float = float(shares[p]) if passed else float(raw[p])
		if not passed and (sh < 0.015 or failed_n >= 2):
			continue
		if not passed:
			failed_n += 1
		rows.append({"name": PARTY_NAMES[p], "col": PARTY_COLORS[p], "share": sh, "prev": float(prev[p]) if p < prev.size() else 0.0,
			"seats": seats[p], "pseat": old_seats[p] if p < old_seats.size() else 0, "gov": p > 0 and in_coalition[p], "ok": passed, "you": p == 0})
	rows.sort_custom(func(a, b): return float(a["share"]) > float(b["share"]))
	var order: Array = []
	for p in HEMI_ORDER:
		if seats[p] > 0:
			order.append({"col": PARTY_COLORS[p], "seats": seats[p], "gov": (p == 0 and not opp_mode) or in_coalition[p]})
	el_view.visible = true
	el_head.visible = false
	var cst: String = String(rep["state"])
	el_view.set_data(rows, order, thr, SEATS, MAJORITY, "%d" % gov_seats(), "коалиция · нужно %d из %d" % [MAJORITY, SEATS], C_GOOD if cst == "gov" else (C_WARN if (cst == "crisis" or cst == "opp" or cst == "talks") else C_BAD))
	var sham: bool = bool(rep["sham"])
	var gold := Color(1.0, 0.82, 0.40) if not sham else C_BAD
	el_banner.add_theme_stylebox_override("panel", ev_style(gold))
	el_title.text = election_title() if not sham else "ВЫБОРЫ БЕЗ ВЫБОРА"
	el_title.add_theme_color_override("font_color", gold.lightened(0.2))
	var turnout: float = clampf(float(ELEC.get("turn", 0.7)) + 0.12 * (democracy_index() - 0.8) + (reg_avg("unrest") - 20.0) * 0.002 + randf_range(-0.02, 0.02), 0.3, 0.95)
	if sham:
		turnout = clampf(0.9 + randf_range(-0.04, 0.05), 0.5, 0.99)
	el_sub.text = loc("%s  ·  %s" % [date_text(), String(rep["reason"]).substr(0, 1).to_upper() + String(rep["reason"]).substr(1)])
	var mt: String = String(ELEC.get("sys", "Пропорциональная система")) + ". "
	if thr >= 0.005:
		mt += "Барьер %.0f%%, " % (thr * 100.0)
	mt += "%d мест. Явка %.0f%%." % [SEATS, turnout * 100.0]
	if String(ELEC.get("note", "")) != "":
		mt += " " + String(ELEC["note"])
	var hk: String = String(ELEC.get("head", "none"))
	if (hk == "direct" or hk == "indirect") and pres_due > turn:
		mt += " Следующие выборы %s — %s." % [String(ELEC["title"]), turn_date(pres_due)]
	mt += "  ★ — партии вашей коалиции."
	el_meta.text = loc(mt)
	# итог
	var st: String = String(rep["state"])
	var vcol: Color = C_GOOD
	var vtitle := ""
	if st == "gov":
		vtitle = "Правительство сформировано"
		vcol = C_GOOD
	elif st == "crisis":
		vtitle = "Правительственный кризис: нет большинства"
		vcol = C_WARN
	elif st == "talks":
		vtitle = "Коалиционные переговоры"
		vcol = C_WARN
	elif st == "opp":
		vtitle = "Вы в оппозиции"
		vcol = C_WARN
	else:
		vtitle = "Вы потеряли власть"
		vcol = C_BAD
	if sham and st == "gov":
		vtitle = "Результат предрешён"
		vcol = C_WARN
	el_verdict_box.add_theme_stylebox_override("panel", ev_style(vcol))
	el_verdict_title.text = vtitle
	el_verdict_title.add_theme_color_override("font_color", vcol.lightened(0.3))
	var my_sh: float = float(shares[0]) if seats[0] > 0 else float(raw[0])
	var dsh: float = (my_sh - float(prev[0])) * 100.0 if prev.size() > 0 else 0.0
	var dse: int = seats[0] - int(old_seats[0]) if old_seats.size() > 0 else 0
	var t := "Ваша партия «%s»: [b]%.1f%%[/b] [color=%s](%s п.п.)[/color], [b]%d мест[/b] [color=%s](%s)[/color]. Первое место в [b]%d из %d[/b] регионов.\n" % [
		PARTY_NAMES[0], my_sh * 100.0, COL_GOOD if dsh >= 0.0 else COL_BAD, sg(dsh, 1), seats[0], COL_GOOD if dse >= 0 else COL_BAD, sg(float(dse), 0), int(rep["won"]), regions.size()]
	if int(rep["best"]) >= 0 and regions.size() > 3:
		t += "[color=%s]Лучший результат — «%s», худший — «%s».[/color]\n" % [COL_DIM, REGIONS[int(rep["best"])]["name"], REGIONS[int(rep["worst"])]["name"]]
	# главный соперник и главный победитель
	var rival := -1
	var gainer := -1
	var gain_v := -9.0
	for p in range(1, PARTY_NAMES.size()):
		var s2: float = float(shares[p])
		if rival < 0 or s2 > float(shares[rival]):
			rival = p
		var dd: float = s2 - (float(prev[p]) if p < prev.size() else 0.0)
		if dd > gain_v:
			gain_v = dd
			gainer = p
	if rival >= 0:
		t += "Главный соперник: «%s» — %.1f%%." % [PARTY_NAMES[rival], float(shares[rival]) * 100.0]
	if gainer >= 0 and gain_v > 0.005:
		t += " Больше всех выиграла «%s» (%s п.п.).\n" % [PARTY_NAMES[gainer], sg(gain_v * 100.0, 1)]
	else:
		t += "\n"
	if st == "gov":
		t += "[color=%s]Коалиция: %s — %d мест из %d (большинство %d). Политкапитал +8.[/color]" % [COL_GOOD, coalition_names(), gov_seats(), SEATS, MAJORITY]
	elif st == "crisis":
		t += "[color=%s]В вашей коалиции %d мест из %d. У вас %d мес., чтобы найти партнёров, иначе будут назначены новые выборы.[/color]" % [COL_WARN, gov_seats(), SEATS, crisis_limit()]
	elif st == "talks":
		t += "[color=%s]Большинства у вашей партии нет: %d мест из %d, нужно %d. Коалицию собираете вы — после этого окна откроются переговоры с партиями (%d мес.).[/color]" % [COL_WARN, seats[0], SEATS, MAJORITY, crisis_limit()]
	elif st == "opp":
		t += "[color=%s]%s Игра продолжается: критикуйте власть, договаривайтесь с партиями и добивайтесь возвращения к власти.[/color]" % [COL_WARN, String(rep.get("opp", ""))]
	else:
		t += "[color=%s]%s[/color]" % [COL_BAD, String(rep["end"])]
	if sham:
		t += "\n[color=%s]Оппозиция запрещена или несвободна, исход определён заранее (индекс демократии %.0f%%).[/color]" % [COL_DIM, democracy_index() * 100.0]
	el_verdict_rt.text = loc(t)
	el_verdict_box.modulate = Color(1, 1, 1, 0.0)
	el_btn.text = "Продолжить  (Enter)" if st != "lost" else "Принять итоги  (Enter)"
	el_btn.disabled = true
	var w: FloatWindow = wins["election"]
	w.visible = true
	w.move_to_front()
	if wins.has("event"):
		(wins["event"] as FloatWindow).visible = false
	set_time_btns(true)
	el_view.set_progress(0.0)
	if el_tween != null:
		el_tween.kill()
	el_tween = create_tween()
	el_tween.tween_method(func(v: float) -> void: el_view.set_progress(v), 0.0, 1.0, 1.8)
	el_tween.tween_property(el_verdict_box, "modulate", Color(1, 1, 1, 1), 0.45)
	el_tween.tween_callback(func() -> void: el_btn.disabled = false)


func election_continue() -> void:
	if not election_open:
		return
	if el_tween != null:
		el_tween.kill()
	election_open = false
	(wins["election"] as FloatWindow).visible = false
	set_time_btns(game_over)
	if elec_end != "":
		var m := elec_end
		elec_end = ""
		end_game(m)
		return
	refresh()
	coal_talks_event()


func build_event_window() -> void:
	var w: FloatWindow = new_window("event", "Требуется решение", -2, Rect2(0.15, 0.02, 0.52, 0.92))
	w.custom_minimum_size = Vector2(460.0, 320.0)
	# v45_1: затемнение под окном решения (щелчки не перехватывает)
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.01, 0.03, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.visible = false
	workspace.add_child(dim)
	workspace.move_child(dim, w.get_index())
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	w.visibility_changed.connect(func() -> void:
		dim.visible = w.visible
		if w.visible:
			workspace.move_child(dim, maxi(0, w.get_index() - 1) if dim.get_index() < w.get_index() else w.get_index()))
	ev_banner = PanelContainer.new()
	ev_banner.add_theme_stylebox_override("panel", ev_style(C_PURPLE))
	w.body.add_child(ev_banner)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	ev_banner.add_child(hb)
	ev_glyph = Label.new()
	ev_glyph.add_theme_font_size_override("font_size", 32)
	ev_glyph.custom_minimum_size = Vector2(36.0, 0.0)
	ev_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ev_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(ev_glyph)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 1)
	hb.add_child(vb)
	ev_kind_lbl = Label.new()
	ev_kind_lbl.add_theme_font_size_override("font_size", 15)
	vb.add_child(ev_kind_lbl)
	ev_meta_lbl = Label.new()
	ev_meta_lbl.add_theme_font_size_override("font_size", 13)
	ev_meta_lbl.add_theme_color_override("font_color", C_DIM)
	vb.add_child(ev_meta_lbl)
	ev_banner.visible = false
	ev_art = EventArt.new()
	w.body.add_child(ev_art)
	w.body.move_child(ev_art, 0)
	event_label = make_rt(w.body)
	ev_ctx = make_rt(w.body)
	ev_adv = make_rt(w.body)
	add_title(w.body, "Ваш ответ")
	event_buttons.clear()
	event_boxes.clear()
	event_fx_rts.clear()
	for i in 5:     # 0.63: окна финансов (банковский кризис, дефолт) дают пять вариантов
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", sbox(C_PANEL2.darkened(0.18), C_BORDER, 1, 10, 4.0, 3.0))
		w.body.add_child(card)
		var vb2 := VBoxContainer.new()
		vb2.add_theme_constant_override("separation", 0)
		card.add_child(vb2)
		var b := Button.new()
		b.theme_type_variation = "OptButton"
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if "autowrap_mode" in b:
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(choose.bind(i))
		vb2.add_child(b)
		var mc := MarginContainer.new()
		mc.add_theme_constant_override("margin_left", 18)
		mc.add_theme_constant_override("margin_right", 8)
		mc.add_theme_constant_override("margin_bottom", 6)
		vb2.add_child(mc)
		var rt := make_rt(mc)
		event_buttons.append(b)
		event_boxes.append(card)
		event_fx_rts.append(rt)
	ev_hint = add_note(w.body, "Выберите вариант щелчком или клавишами 1–5. Последствия показаны под каждым вариантом: зелёное — плюсы, красное — минусы.")


func refit_event() -> void:
	# после показа окна пересчитываем высоту текстов
	event_label.text = ""
	event_label.text = event_text
	if current_event.is_empty():
		return
	var opts: Array = current_event["o"]
	for i in mini(opts.size(), event_fx_rts.size()):
		var rt: RichTextLabel = event_fx_rts[i]
		var tx := rt.text
		rt.text = ""
		rt.text = tx
