# Интерфейс: окна, тема, верхняя панель, экран «Бюджет», обновление.
extends "res://scripts/logic/saves.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func build_crisis_windows() -> void:
	pass


func build_dip_windows() -> void:
	pass


func build_econ_windows() -> void:
	pass


func build_election_window() -> void:
	pass


func build_event_window() -> void:
	pass


func build_fed_windows() -> void:
	pass


func build_fleet_windows() -> void:
	pass


func build_goods_windows() -> void:
	pass


func build_gov_windows() -> void:
	pass


func build_law_windows() -> void:
	pass


func build_map_windows() -> void:
	pass


func build_opp_windows() -> void:
	pass


func build_politics_windows() -> void:
	pass


func build_pop_windows() -> void:
	pass


func build_realm_windows() -> void:
	pass


func build_soc_windows() -> void:
	pass


func build_tech_windows() -> void:
	pass


func build_war_windows() -> void:
	pass


func ec_slider(parent: Control, title: String, mn: float, mx: float, step: float, tip: String) -> Array:
	return []


func make_crisis_button(parent: Control) -> void:
	pass


func make_tech_button(parent: Control) -> void:
	pass


func map_apply_mode() -> void:
	pass


func show_country_menu(in_game: bool) -> void:
	pass


func update_crisis_windows() -> void:
	pass


func update_dip_windows() -> void:
	pass


func update_econ_windows() -> void:
	pass


func update_fed_windows() -> void:
	pass


func update_fleet_windows() -> void:
	pass


func update_goods_windows() -> void:
	pass


func update_gov_windows() -> void:
	pass


func update_law_windows() -> void:
	pass


func update_opp_windows() -> void:
	pass


func update_parliament() -> void:
	pass


func update_realm_windows() -> void:
	pass


func update_regions_ui() -> void:
	pass


func update_soc_windows() -> void:
	pass


func update_tech_windows() -> void:
	pass


func update_war_windows() -> void:
	pass


# --- конец заглушек ---


func new_window(id: String, title: String, desk: int, fr: Rect2, scrolling: bool = true) -> FloatWindow:
	var w := FloatWindow.new()
	w.setup(title, scrolling, accent_for_desk(desk))
	w.desk = desk
	w.frac = fr
	w.default_frac = fr
	w.set_closable(desk != -2)
	w.close_requested.connect(on_win_close)
	workspace.add_child(w)
	wins[id] = w
	return w


# окна, закрытые по умолчанию (открываются через «Окна»)
const WIN_DEFAULT_CLOSED := ["regtable", "regact", "regecon", "dtable", "adm"]


func win_vis(id: String, on: bool) -> void:
	if not wins.has(id):
		return
	var w: FloatWindow = wins[id]
	w.visible = on and not w.closed


func on_win_close(w: FloatWindow) -> void:
	w.closed = true
	w.visible = false


func win_menu_fill() -> void:
	var pm: PopupMenu = win_menu.get_popup()
	pm.clear()
	var ids: Array = []
	for id in wins:
		var w: FloatWindow = wins[id]
		if w.desk == -2 or not (w.desk == current_desk or w.desk == -1):
			continue
		ids.append(id)
	for k in ids.size():
		var w2: FloatWindow = wins[ids[k]]
		pm.add_check_item(w2.get_title(), k)
		pm.set_item_checked(k, not w2.closed)
		pm.set_item_metadata(k, ids[k])
	if ids.size() > 0:
		pm.add_separator()
		pm.add_item("Открыть все окна раздела", 1000)
		pm.add_item("Закрыть все окна раздела", 1001)


func on_win_menu(idx: int) -> void:
	var pm: PopupMenu = win_menu.get_popup()
	var mid: int = pm.get_item_id(idx)
	if mid >= 1000:
		for id in wins:
			var w: FloatWindow = wins[id]
			if w.desk == -2 or not (w.desk == current_desk or w.desk == -1):
				continue
			if mid == 1000 and false:
				continue
			w.closed = mid == 1001
		show_desk(current_desk)
		return
	var wid: String = String(pm.get_item_metadata(idx))
	var w3: FloatWindow = wins[wid]
	w3.closed = not w3.closed
	if not w3.closed:
		w3.move_to_front()
	show_desk(current_desk)


func layout_windows() -> void:
	for id in wins:
		(wins[id] as FloatWindow).apply_frac()
	fix_wraps_later()


func fix_wraps() -> void:
	for id in wins:
		(wins[id] as FloatWindow).refresh_wraps()


func fix_wraps_later() -> void:
	wrap_pass = 0
	if wrap_timer != null:
		wrap_timer.start(0.12)


func on_wrap_timer() -> void:
	fix_wraps()
	if wrap_pass < 1:
		wrap_pass += 1
		wrap_timer.start(0.3)


func reset_layout() -> void:
	for id in wins:
		var w: FloatWindow = wins[id]
		w.frac = w.default_frac
		w.closed = id in WIN_DEFAULT_CLOSED
		if w.collapsed:
			w.toggle_collapse()
		w.apply_frac()


func show_desk(i: int) -> void:
	if current_desk != i:
		sfx("click")
	current_desk = i
	if i == 1 or i == 3 or i == 4 or i == 6 or i == 11 or i == 12:
		politics_page = i
	if i == 5 or i == 7 or i == 10:
		econ_page = i
	if i == 2 or i == 8 or i == 9 or i == 13 or i == 14:
		map_page = i
	for id in wins:
		var w: FloatWindow = wins[id]
		w.visible = ((w.desk == i) or (w.desk == -1) or (w.desk == -2 and not current_event.is_empty())) and (w.desk == -2 or not w.closed)
	var tab: int = 0 if i == 0 else (1 if (i == 5 or i == 7 or i == 10) else (3 if (i == 2 or i == 8 or i == 9 or i == 13 or i == 14) else 2))
	if i == 2:
		map_apply_mode()
	for kb in desk_buttons.size():
		(desk_buttons[kb] as Button).set_pressed_no_signal(kb == tab)
	update_subbar(i)
	refresh()
	fix_wraps_later()


func build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var top := PanelContainer.new()
	top.custom_minimum_size = Vector2(0.0, 58.0)
	var tsb := sbox(C_PANEL, C_BORDER, 0, 0, 10.0, 6.0)
	tsb.border_width_bottom = 1
	top.add_theme_stylebox_override("panel", tsb)
	add_child(top)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 0)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	top.add_child(hb)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	hb.add_child(tabs)
	var grp := ButtonGroup.new()
	var desk_names := ["Бюджет", "Экономика", "Политика", "Карта"]
	for i in 4:
		var b := Button.new()
		b.theme_type_variation = "TabButton"
		b.text = desk_names[i]
		b.toggle_mode = true
		b.button_group = grp
		b.custom_minimum_size = Vector2(0.0, 40.0)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(show_tab.bind(i))
		btn_icon(b, ["coin", "chart", "hall", "pin"][i])
		tabs.add_child(b)
		desk_buttons.append(b)
	(desk_buttons[0] as Button).set_pressed_no_signal(true)
	make_tech_button(tabs)
	make_crisis_button(tabs)
	var chip_row := HBoxContainer.new()
	chip_row.add_theme_constant_override("separation", 4)
	chip_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(chip_row)
	make_chip(chip_row, "date", "ДАТА", "Текущая дата игры. Календарь идёт по дням; экономика и политика считаются на границе месяцев.")
	make_chip(chip_row, "appr", "РЕЙТИНГ", "Общий рейтинг власти. Стрелка — изменение за прошлый месяц. Выше 50% — вы выигрываете выборы.")
	make_chip(chip_row, "gdp", "ВВП, МЛРД", "ВВП за год. Справа — общий темп роста за год.")
	make_chip(chip_row, "infl", "ИНФЛЯЦИЯ", "Годовая инфляция. Выше 6% — экономика страдает, выше 30% — гиперинфляция.")
	make_chip(chip_row, "unemp", "БЕЗРАБОТ.", "Доля безработных.")
	make_chip(chip_row, "debt", "ДОЛГ", "Госдолг в процентах ВВП. Выше 150% — дефолт.")
	make_chip(chip_row, "cap", "КАПИТАЛ", "Политический капитал: расходуется на законы, действия и переговоры.")
	make_chip(chip_row, "coal", "КОАЛИЦ.", "Мест у вашей коалиции из %d. Для большинства нужно %d." % [SEATS, MAJORITY])
	make_chip(chip_row, "elec", "ВЫБОРЫ", "Время до следующих парламентских выборов.")
	var cbtn := Button.new()
	cbtn.theme_type_variation = "SmallButton"
	cbtn.text = "🌍"
	cbtn.custom_minimum_size = Vector2(34.0, 34.0)
	cbtn.tooltip_text = "Сменить страну (начнётся новая игра)"
	cbtn.focus_mode = Control.FOCUS_NONE
	cbtn.pressed.connect(show_country_menu.bind(true))
	hb.add_child(cbtn)
	music_btn = Button.new()
	music_btn.theme_type_variation = "SmallButton"
	music_btn.text = "♪" if float(game_opts.get("music", 0.45)) > 0.001 else "🔇"
	music_btn.custom_minimum_size = Vector2(34.0, 34.0)
	music_btn.tooltip_text = "Музыка: включить или выключить. Громкость музыки и звуков — в настройках новой игры (кнопка 🌍 → «Настройки игры»)."
	music_btn.focus_mode = Control.FOCUS_NONE
	music_btn.pressed.connect(toggle_music)
	hb.add_child(music_btn)
	var rst := Button.new()
	rst.theme_type_variation = "SmallButton"
	rst.text = "↺"
	rst.custom_minimum_size = Vector2(34.0, 34.0)
	rst.tooltip_text = "Вернуть все окна на исходные места"
	rst.focus_mode = Control.FOCUS_NONE
	rst.pressed.connect(reset_layout)
	hb.add_child(rst)
	win_menu = MenuButton.new()
	win_menu.text = "▦"
	win_menu.flat = false
	win_menu.focus_mode = Control.FOCUS_NONE
	win_menu.custom_minimum_size = Vector2(34.0, 34.0)
	win_menu.tooltip_text = "Показать или скрыть окна текущего раздела (окна можно закрывать крестиком)"
	win_menu.about_to_popup.connect(win_menu_fill)
	win_menu.get_popup().index_pressed.connect(on_win_menu)
	hb.add_child(win_menu)
	play_btn = Button.new()
	play_btn.text = "▶"
	play_btn.toggle_mode = true
	play_btn.focus_mode = Control.FOCUS_NONE
	play_btn.custom_minimum_size = Vector2(36.0, 40.0)
	play_btn.tooltip_text = "Пустить время: дни идут сами, пока не случится событие или выборы"
	play_btn.toggled.connect(on_play_toggled)
	hb.add_child(play_btn)
	speed_opt = OptionButton.new()
	speed_opt.focus_mode = Control.FOCUS_NONE
	speed_opt.custom_minimum_size = Vector2(66.0, 40.0)
	speed_opt.fit_to_longest_item = false
	speed_opt.tooltip_text = "Скорость: сколько дней календаря проходит за секунду реального времени"
	for k in range(1, PLAY_SPEEDS.size()):
		speed_opt.add_item("%d×" % int(PLAY_SPEEDS[k]), k)
		speed_opt.set_item_tooltip(k - 1, "%d дн. в секунду" % int(PLAY_SPEEDS[k]))
	speed_opt.item_selected.connect(on_speed_selected)
	hb.add_child(speed_opt)
	wrap_timer = Timer.new()
	wrap_timer.one_shot = true
	wrap_timer.timeout.connect(on_wrap_timer)
	add_child(wrap_timer)

	map_base = Control.new()
	map_base.clip_contents = true
	add_child(map_base)
	map_base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_base.offset_top = 64.0
	map_base.offset_left = 6.0
	map_base.offset_right = -6.0
	map_base.offset_bottom = -6.0
	workspace = Control.new()
	workspace.clip_contents = true
	workspace.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(workspace)
	workspace.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	workspace.offset_top = 64.0
	workspace.offset_left = 6.0
	workspace.offset_right = -6.0
	workspace.offset_bottom = -6.0
	workspace.resized.connect(layout_windows)
	build_subbar()

	build_budget_windows()
	build_politics_windows()
	build_law_windows()
	build_gov_windows()
	build_pop_windows()
	build_map_windows()
	build_econ_windows()
	build_dip_windows()
	build_goods_windows()
	build_fed_windows()
	build_soc_windows()
	build_tech_windows()
	build_crisis_windows()
	build_opp_windows()
	build_fleet_windows()
	build_war_windows()
	build_auto_window()
	build_realm_windows()
	build_log_and_event()
	for wid in WIN_DEFAULT_CLOSED:
		if wins.has(wid):
			(wins[wid] as FloatWindow).closed = true
	polish_tree(self)


func add_title(parent: Control, text: String) -> Label:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	parent.add_child(box)
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", C_ACCENT.lightened(0.18))
	box.add_child(l)
	var line := ColorRect.new()
	line.color = C_BORDER
	line.custom_minimum_size = Vector2(0.0, 1.0)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(line)
	return l


func add_note(parent: Control, text: String, keep: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", C_DIM)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(l)
	if not keep:
		l.visible = ui_detail
		note_nodes.append(l)
	return l


# Сворачиваемый блок: заголовок-кнопка + текст, скрытый по умолчанию.
func make_fold(parent: Control, title: String, open: bool = false) -> RichTextLabel:
	var b := Button.new()
	b.theme_type_variation = "SmallButton"
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.flat = true
	parent.add_child(b)
	var rt := make_rt(parent)
	b.set_meta("title", title)
	b.toggled.connect(on_fold_toggled.bind(b, rt))
	fold_nodes.append([b, rt])
	b.set_pressed_no_signal(open or ui_detail)
	on_fold_toggled(open or ui_detail, b, rt)
	return rt


# Текст, разбитый на «голову» (всегда видна) и «хвост» (сворачиваемый).
func make_tail(head: RichTextLabel, title: String) -> void:
	var rt := make_fold(head.get_parent(), title)
	tails[head] = rt


func set_tail_text(head: RichTextLabel, t: String, n_lines: int) -> void:
	var parts := t.split("\n")
	head.text = "\n".join(parts.slice(0, n_lines))
	(tails[head] as RichTextLabel).text = "\n".join(parts.slice(n_lines)).strip_edges()


func on_fold_toggled(on: bool, b: Button, rt: RichTextLabel) -> void:
	b.text = ("▾ " if on else "▸ ") + String(b.get_meta("title"))
	rt.visible = on


func on_detail_toggled(on: bool) -> void:
	ui_detail = on
	for n in note_nodes:
		if is_instance_valid(n):
			(n as Control).visible = on
	for f in fold_nodes:
		var b: Button = f[0]
		b.set_pressed_no_signal(on)
		on_fold_toggled(on, b, f[1])
	refresh()


func add_wrap_label(parent: Control, text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(l)
	return l


func make_button(text: String, parent: Control) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.clip_text = false
	if "autowrap_mode" in b:
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	parent.add_child(b)
	return b


func make_rt(parent: Control) -> RichTextLabel:
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(rt)
	return rt


func add_slider(parent: Control, d: Dictionary) -> void:
	var key: String = d["key"]
	var acc: Color = C_ACCENT
	if key == "emit":
		acc = C_WARN
	elif String(d["kind"]) == "tax":
		acc = C_TEAL
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 1)
	parent.add_child(vb)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	vb.add_child(top)
	var tl := Label.new()
	tl.text = d["title"]
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tl.clip_text = true
	tl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tl.mouse_filter = Control.MOUSE_FILTER_PASS
	tl.add_theme_font_size_override("font_size", 15)
	top.add_child(tl)
	var vl := Label.new()
	vl.add_theme_font_size_override("font_size", 15)
	vl.add_theme_color_override("font_color", acc.lightened(0.25))
	top.add_child(vl)
	var mb := Button.new()
	mb.theme_type_variation = "SmallButton"
	mb.text = "% ВВП"
	mb.focus_mode = Control.FOCUS_NONE
	mb.custom_minimum_size = Vector2(54.0, 0.0)
	mb.tooltip_text = "Единицы ползунка: доля ВВП (сумма растёт вместе с экономикой) или фиксированная сумма в млрд в год (доля ВВП при росте экономики снижается)."
	top.add_child(mb)
	var s := HSlider.new()
	s.min_value = float(d["min"])
	s.max_value = float(d["max"])
	s.step = 0.1
	s.value = float(d["def"])
	s.scrollable = false
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.custom_minimum_size = Vector2(60.0, 20.0)
	s.add_theme_stylebox_override("grabber_area", sbox(acc.darkened(0.15), Color(0, 0, 0, 0), 0, 4, 0.0, 3.0))
	s.add_theme_stylebox_override("grabber_area_highlight", sbox(acc, Color(0, 0, 0, 0), 0, 4, 0.0, 3.0))
	vb.add_child(s)
	var sub := Label.new()
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", C_DIM)
	vb.add_child(sub)
	var lock_lbl := Label.new()
	lock_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lock_lbl.add_theme_font_size_override("font_size", 12)
	lock_lbl.add_theme_color_override("font_color", C_WARN)
	lock_lbl.visible = false
	vb.add_child(lock_lbl)
	tl.tooltip_text = String(d["title"])
	if key == "emit":
		tl.tooltip_text = "Печать денег пополняет бюджет. Пока вы печатаете не больше безопасного предела, инфляция не растёт. Выше предела — растёт."
	elif String(d["kind"]) == "spend":
		tl.tooltip_text = "Состояние страны зависит от суммы в млрд на душу населения, а не от доли ВВП. Группы интересов сравнивают сумму со своими ожиданиями."
	sliders[key] = {"slider": s, "title_lbl": tl, "value_lbl": vl, "sub_lbl": sub, "lock_lbl": lock_lbl, "title": d["title"], "mode_btn": mb, "accent": acc, "box": vb}
	s.value_changed.connect(on_slider.bind(key))
	mb.pressed.connect(toggle_slider_mode.bind(key))


func set_bar(key: String, v: float) -> void:
	var d: Dictionary = bars[key]
	var good := v / 100.0
	if d["invert"]:
		good = 1.0 - good
	(d["bar"] as StatBar).set_state(v, good)
	var vl: Label = d["val"]
	vl.text = "%.0f" % v
	vl.add_theme_color_override("font_color", scale_color(good))


func build_budget_windows() -> void:
	var w: FloatWindow = new_window("tax", "Налоги", 0, Rect2(0.0, 0.0, 0.235, 0.40))
	for d in POLICY:
		if d["kind"] == "tax" and d["key"] != "emit":
			add_slider(w.body, d)
	tax_total_label = add_wrap_label(w.body, "")
	for d in POLICY:
		if d["key"] == "emit":
			add_slider(w.body, d)
	emit_note = add_note(w.body, "", true)
	sync_emit()

	w = new_window("spend", "Расходы бюджета", 0, Rect2(0.0, 0.40, 0.235, 0.60))
	for d in POLICY:
		if d["kind"] == "spend":
			add_slider(w.body, d)
	spend_total_label = add_wrap_label(w.body, "")
	var fl := CheckButton.new()
	fl.text = "Авто-подъём до ожиданий групп"
	fl.tooltip_text = "Если на статью тратится меньше, чем ждут социальные группы («группы ждут ≈» под ползунком), ползунок сам поднимется до этого уровня (раз в месяц и при включении)."
	fl.focus_mode = Control.FOCUS_NONE
	fl.clip_text = true
	fl.toggled.connect(on_floor_toggle)
	w.body.add_child(fl)
	floor_check = fl
	add_note(w.body, "Кнопка рядом с названием переключает ползунок между долей ВВП и суммой в млрд. Состояние страны зависит от суммы на человека, а не от доли ВВП.")

	w = new_window("forecast", "Бюджет: доходы и расходы", 0, Rect2(0.235, 0.0, 0.235, 0.38))
	budget_viz = Control.new()
	budget_viz.custom_minimum_size = Vector2(0.0, 74.0)
	budget_viz.draw.connect(draw_budget_viz)
	w.body.add_child(budget_viz)
	forecast_sum_rt = make_rt(w.body)
	forecast_rt = make_fold(w.body, "Доходы и расходы по статьям")

	w = new_window("economy", "Экономика и состояние страны", 0, Rect2(0.235, 0.38, 0.235, 0.62))
	stats_label = make_rt(w.body)
	add_title(w.body, "Состояние государства")
	for d in LEVELS:
		add_bar(w.body, d["key"], d["title"], d["invert"])
	level_fx_rt = make_fold(w.body, "Как состояние влияет на игру")

	w = new_window("groups", "Группы интересов", 0, Rect2(0.47, 0.0, 0.235, 0.30))
	add_bar(w.body, "approval", "Общий рейтинг", false)
	for g in GROUPS:
		add_bar(w.body, g, g, false)
	add_note(w.body, "Цифры — поддержка власти группой (0–100). Рейтинг — взвешенная сумма по числу людей в группе.")

	w = new_window("measures", "Разовые меры", 0, Rect2(0.47, 0.78, 0.235, 0.22))
	for m in MEASURES:
		var b := make_button("", w.body)
		b.pressed.connect(do_measure.bind(m["id"]))
		measure_rows[m["id"]] = b
		b.tooltip_text = String(m["desc"])


func build_log_and_event() -> void:
	var w: FloatWindow = new_window("log", "Журнал событий и бюджета", -1, Rect2(0.705, 0.0, 0.295, 1.0), false)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	w.body.add_child(hb)
	log_toggle = Button.new()
	log_toggle.theme_type_variation = "SmallButton"
	log_toggle.text = "Подробный отчёт"
	log_toggle.toggle_mode = true
	log_toggle.focus_mode = Control.FOCUS_NONE
	log_toggle.tooltip_text = "Добавлять в ежемесячный отчёт доходы и расходы по каждой статье"
	log_toggle.toggled.connect(on_log_detail)
	hb.add_child(log_toggle)
	var clr := Button.new()
	clr.theme_type_variation = "SmallButton"
	clr.text = "Очистить"
	clr.focus_mode = Control.FOCUS_NONE
	clr.pressed.connect(log_clear)
	hb.add_child(clr)
	build_log_filters(w.body)
	log_box = RichTextLabel.new()
	log_box.bbcode_enabled = true
	log_box.scroll_following = true
	log_box.selection_enabled = true
	log_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_box.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_box.add_theme_font_size_override("normal_font_size", 14)
	log_box.add_theme_font_size_override("bold_font_size", 14)
	log_box.add_theme_constant_override("line_separation", 3)
	w.body.add_child(log_box)

	build_event_window()
	build_election_window()


func update_slider_label(key: String) -> void:
	var d: Dictionary = sliders[key]
	var share: float = pol[key]
	var a: float = amt(key)
	var vl: Label = d["value_lbl"]
	var sub: Label = d["sub_lbl"]
	var main_txt := ""
	var sub_txt := ""
	if is_abs(key):
		main_txt = "%s млрд" % fmt_n(a, 1)
		sub_txt = "%.1f%% ВВП · %.1f млрд в месяц" % [share, a / 12.0]
	else:
		main_txt = "%.1f%% ВВП" % share
		sub_txt = "%s млрд в год · %.1f в месяц" % [fmt_n(a, 1), a / 12.0]
	var col: Color = (d["accent"] as Color).lightened(0.25)
	if key == "emit":
		var safe := emit_safe_pct()
		sub_txt += "\nБезопасно до %.1f%% ВВП (%.1f млрд в год)" % [safe, gdp * safe / 100.0]
		if share > safe + 0.001:
			sub_txt += " — выше предела, инфляция растёт"
			col = C_BAD
	elif String(policy_by_key[key]["kind"]) == "spend":
		var want: float = expected_pp(key) * (GDP0 / 100.0) * pop_ratio() * std_index()
		sub_txt += " · группы ждут ≈ %.0f млрд (%.1f%% ВВП)" % [want, want / gdp * 100.0]
	vl.text = main_txt
	vl.add_theme_color_override("font_color", col)
	sub.text = sub_txt
	var warn: bool = col == C_BAD
	sub.visible = ui_detail or warn
	(d["slider"] as HSlider).tooltip_text = sub_txt
	var ll: Label = d["lock_lbl"]
	var ln := lock_note(key)
	ll.text = ln
	ll.visible = ln != ""


func update_forecast() -> void:
	if forecast_rt == null:
		return
	var b := compute_budget()
	var bal: float = float(b["balance"])
	viz_rev.clear()
	viz_exp.clear()
	var t := "[b]Доходы[/b]  %s млрд/мес  [color=%s](%.1f%% ВВП)[/color]\n[table=3]" % [fmt_n(float(b["revenue"]) / 12.0, 1), COL_DIM, float(b["revenue"]) / gdp * 100.0]
	t += "[cell][color=%s]статья[/color][/cell][cell][color=%s]  млрд/мес[/color][/cell][cell][color=%s]  %% ВВП[/color][/cell]" % [COL_DIM, COL_DIM, COL_DIM]
	var ci := 0
	for k in b["rev"]:
		var col: Color = REV_COLORS[ci % REV_COLORS.size()]
		viz_rev.append([k, float(b["rev"][k]), col])
		t += "[cell][color=#%s]■[/color] %s[/cell][cell]  %.1f[/cell][cell]  %.1f%%[/cell]" % [col.to_html(false), k, float(b["rev"][k]) / 12.0, float(b["rev"][k]) / gdp * 100.0]
		ci += 1
	t += "[/table]\n[b]Расходы[/b]  %s млрд/мес  [color=%s](%.1f%% ВВП)[/color]\n[table=3]" % [fmt_n(float(b["spending"]) / 12.0, 1), COL_DIM, float(b["spending"]) / gdp * 100.0]
	t += "[cell][color=%s]статья[/color][/cell][cell][color=%s]  млрд/мес[/color][/cell][cell][color=%s]  %% ВВП[/color][/cell]" % [COL_DIM, COL_DIM, COL_DIM]
	ci = 0
	for k in b["exp"]:
		var col2: Color = EXP_COLORS[ci % EXP_COLORS.size()]
		viz_exp.append([k, float(b["exp"][k]), col2])
		t += "[cell][color=#%s]■[/color] %s[/cell][cell]  %.1f[/cell][cell]  %.1f%%[/cell]" % [col2.to_html(false), k, float(b["exp"][k]) / 12.0, float(b["exp"][k]) / gdp * 100.0]
		ci += 1
	t += "[/table]"
	var sm := "[b]Доходы[/b] %s · [b]расходы[/b] %s млрд/мес\n[b]Баланс[/b]  %s млрд/мес  [color=%s](%s%% ВВП; за год %s млрд)[/color]\n[color=%s]Проценты по долгу: %.1f млрд/мес (%.1f%% ВВП)[/color]" % [
		fmt_n(float(b["revenue"]) / 12.0, 1), fmt_n(float(b["spending"]) / 12.0, 1), col_signed(bal / 12.0, 1), COL_DIM, sg(bal / gdp * 100.0), sg(bal, 0), COL_DIM, float(b["interest"]) / 12.0, float(b["interest"]) / gdp * 100.0]
	var lk := ""
	for key in locks:
		if lock_active(key):
			lk += "• %s — %s\n" % [policy_title(key), lock_note(key)]
	if lk != "":
		sm += "\n\n[color=%s][b]Ваши обязательства[/b] (пока действуют, откатить ползунок нельзя):[/color]\n[color=%s]%s[/color]" % [COL_WARN, COL_WARN, lk]
	sm += brake_text()
	if forecast_sum_rt != null:
		forecast_sum_rt.text = sm
	forecast_rt.text = t
	if budget_viz != null:
		budget_viz.queue_redraw()
	var tax_sum: float = float(pol["income"]) + float(pol["social"]) + float(pol["corp"]) + float(pol["vat"])
	if tax_total_label != null:
		tax_total_label.text = "Налоги всего: %.1f%% ВВП" % tax_sum
	if spend_total_label != null:
		var sp_sum := 0.0
		var sp_amt := 0.0
		for d in POLICY:
			if d["kind"] == "spend":
				sp_sum += float(pol[d["key"]])
				sp_amt += amt(d["key"])
		spend_total_label.text = "Расходы по ползункам: %s млрд в год (%.1f%% ВВП), без процентов и программ законов" % [fmt_n(sp_amt), sp_sum]
		if council_on() and bool(junior_info()["junior"]):
			spend_total_label.text += "\nВы младший партнёр: изменения бюджета в начале следующего месяца рассмотрит совет коалиции (решает большинство по местам)."


func update_stats() -> void:
	if stats_label == null:
		return
	var reg_fx: float = (regional_potential() / pot0 - 1.0) * 100.0
	var dr: float = debt / gdp * 100.0
	var t := "[color=%s]ВВП[/color]  [b]%s млрд[/b] в год · рост [b]%.1f%%[/b] [color=%s](регионы %s%%)[/color]\n" % [COL_DIM, fmt_n(gdp), growth, COL_DIM, sg(reg_fx, 1)]
	t += "[color=%s]Цены[/color]  инфляция [b][color=#%s]%.1f%%[/color][/b] · безработица [b][color=#%s]%.1f%%[/color][/b]\n" % [
		COL_DIM, scale_color(1.0 - inflation / 12.0).to_html(false), inflation, scale_color(1.0 - unemployment / 14.0).to_html(false), unemployment]
	t += "[color=%s]Долг[/color]  [b]%s млрд[/b] · [b][color=#%s]%.0f%% ВВП[/color][/b]\n" % [COL_DIM, fmt_n(debt), scale_color(1.0 - dr / 110.0).to_html(false), dr]
	t += "[color=%s]Капитал[/color]  [b]%.1f[/b] из 100 (%+.1f в месяц)" % [COL_DIM, capital, cap_rate()]
	stats_label.text = t
	if level_fx_rt != null:
		level_fx_rt.text = level_effects_text()


func update_polls() -> void:
	if polls_rt == null:
		return
	var parl_in := parl_term() - (turn - last_parl)
	var thr_t := ("барьер %.0f%%, " % (float(mods["threshold"]) * 100.0)) if float(mods["threshold"]) >= 0.005 else ""
	var t := "[b]Ближайшие выборы в Бундестаг[/b]\n%s: %s%s, через %s\n" % [
		String(ELEC.get("sys", "Пропорциональная система")), thr_t, date_after(parl_in), months_text(parl_in)]
	var hk0: String = String(ELEC.get("head", "none"))
	if (hk0 == "direct" or hk0 == "indirect" or hk0 == "council") and pres_due >= 0:
		t += "[b]Ближайшие выборы %s[/b]\n%s, через %s\n" % [String(ELEC["title"]), turn_date(maxi(pres_due, turn)), months_text(maxi(0, pres_due - turn))]
	elif hk0 == "monarch":
		t += "[color=%s]Глава государства — монарх, его не избирают.[/color]\n" % COL_DIM
	t += "\n"
	var ps := parl_shares()
	var ss := allocate_seats(ps)
	var po := sorted_parties(ps)
	t += "[b]Опрос: Бундестаг (прогноз мест)[/b]\n"
	for p in po:
		t += "[color=#%s]%s[/color] %s  %.1f%%%s\n" % [(PARTY_COLORS[p] as Color).to_html(false), "█".repeat(maxi(1, int(round(ps[p] * 40.0)))), PARTY_NAMES[p], ps[p] * 100.0, (" = %d мест" % ss[p]) if ss[p] > 0 else " (ниже барьера)"]
	var head_t := t
	t = ""
	if ccode == "DE":
		t += "[color=%s]Канцлера избирает Бундестаг; сместить его можно только конструктивным вотумом недоверия — когда оппозиция (без АдГ) сразу собирает большинство за нового канцлера.[/color]\n" % COL_DIM
	else:
		t += "\n[color=%s]Правительство держится, пока против него не сложится %d голосов %s%s. %s[/color]\n" % [COL_DIM, impeach_seats(), "(конструктивный вотум: оппозиция должна сразу выбрать нового главу правительства)" if int(mods["constr"]) == 1 else "", "", ("Правительство меньшинства живёт на терпимости партий-партнёров." if minority_ok else "")]
	t += democracy_text()
	polls_rt.text = loc(head_t.strip_edges())
	(tails[polls_rt] as RichTextLabel).text = loc(t.strip_edges())


# ---------- карта и регионы ----------


func add_bar(parent: Control, key: String, title: String, invert: bool, marker: float = 50.0) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var l := Label.new()
	l.text = title
	l.custom_minimum_size = Vector2(124.0, 0.0)
	l.clip_text = true
	l.add_theme_font_size_override("font_size", 14)
	row.add_child(l)
	var bar := StatBar.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size = Vector2(24.0, 13.0)
	bar.marker = marker
	row.add_child(bar)
	var vl := Label.new()
	vl.custom_minimum_size = Vector2(32.0, 0.0)
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vl.add_theme_font_size_override("font_size", 15)
	row.add_child(vl)
	bars[key] = {"bar": bar, "val": vl, "invert": invert, "row": row}


func color_button(b: Button, col: Color) -> void:
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, col)


func refresh() -> void:
	if chips.is_empty():
		return
	recompute_mods()
	update_chips()
	if current_desk == 0:
		for k in sliders:
			update_slider_label(k)
		update_forecast()
		update_stats()
		update_auto_window()
		for g in GROUPS:
			set_bar(g, float(support[g]))
		set_bar("approval", approval())
		for d in LEVELS:
			set_bar(d["key"], float(lvl[d["key"]]))
		for m in MEASURES:
			var b: Button = measure_rows[m["id"]]
			var cd: int = int(cooldown[m["id"]])
			b.text = m["name"] if cd == 0 else "%s (ещё %d мес.)" % [m["name"], cd]
			b.disabled = cd > 0 or game_over
	elif current_desk == 1:
		for a in ACTIONS:
			var b: Button = action_rows[a["id"]]
			var cd: int = int(cooldown[a["id"]])
			var anm: String = loc(String(a["name"])) if a["id"] != "snap" else String(snap_info()["name"])
			var txt: String = "%s (капитал %.0f)" % [anm, a["cost"]]
			if cd > 0:
				txt += " — ещё %d мес." % cd
			b.text = txt
			b.disabled = cd > 0 or game_over or capital < float(a["cost"]) or (a["id"] == "snap" and (turn - last_parl < 12 or not bool(snap_info()["ok"]) or opp_mode))
		update_parliament()
		update_polls()
	elif current_desk == 3:
		update_law_windows()
	elif current_desk == 4:
		update_gov_windows()
	elif current_desk == 5:
		update_econ_windows()
	elif current_desk == 7:
		update_goods_windows()
	elif current_desk == 6:
		update_pop_windows()
	elif current_desk == 8 or current_desk == 9:
		update_fed_windows()
	elif current_desk == 10 or current_desk == 11:
		update_soc_windows()
	elif current_desk == 12:
		update_opp_windows()
	elif current_desk == 13:
		update_war_windows()
	elif current_desk == 14:
		update_fleet_windows()
	if current_desk == 2:
		update_dip_windows()
	update_regions_ui()
	update_tech_windows()
	update_crisis_windows()
	update_realm_windows()


# ---------- парламент ----------


func on_slider(v: float, key: String) -> void:
	if slider_busy:
		return
	var allowed := lock_allowed(key, v)
	if not is_equal_approx(allowed, v):
		(sliders[key]["slider"] as HSlider).set_value_no_signal(allowed)
		v = allowed
	if is_abs(key):
		pol_abs[key] = v
		pol[key] = v / gdp * 100.0
	else:
		pol[key] = v
	update_slider_label(key)
	update_forecast()


func slider_value_for(key: String) -> float:
	return float(pol_abs[key]) if is_abs(key) else float(pol[key])


func configure_slider(key: String) -> void:
	if not sliders.has(key):
		return
	var s: HSlider = sliders[key]["slider"]
	var d: Dictionary = policy_by_key[key]
	slider_busy = true
	if is_abs(key):
		var r := abs_range(key)
		s.min_value = r.x
		s.max_value = r.y
		s.step = 0.5
		s.set_value_no_signal(clampf(float(pol_abs[key]), r.x, r.y))
	else:
		s.min_value = float(d["min"])
		s.max_value = float(d["max"])
		s.step = 0.1
		s.set_value_no_signal(float(pol[key]))
	slider_busy = false
	var b: Button = sliders[key]["mode_btn"]
	b.text = "млрд" if is_abs(key) else "% ВВП"
	update_slider_label(key)


func toggle_slider_mode(key: String) -> void:
	var d: Dictionary = policy_by_key[key]
	if is_abs(key):
		pol_abs_mode[key] = false
		pol[key] = clampf(float(pol[key]), float(d["min"]), float(d["max"]))
	else:
		pol_abs_mode[key] = true
		var r := abs_range(key)
		pol_abs[key] = clampf(amt(key), r.x, r.y)
		pol[key] = float(pol_abs[key]) / gdp * 100.0
	configure_slider(key)
	update_forecast()


func make_theme() -> Theme:
	var th := Theme.new()
	th.default_font_size = 15
	th.set_color("font_color", "Label", C_TEXT)
	th.set_color("default_color", "RichTextLabel", C_TEXT)
	th.set_constant("line_separation", "RichTextLabel", 2)
	# --- кнопки ---
	for t in ["Button", "OptionButton"]:
		th.set_stylebox("normal", t, sbox(C_PANEL2, C_BORDER, 1, 6, 10.0, 5.0))
		th.set_stylebox("hover", t, sbox(C_PANEL2.lightened(0.10), C_ACCENT.darkened(0.15), 1, 6, 10.0, 5.0))
		th.set_stylebox("pressed", t, sbox(C_ACCENT.darkened(0.50), C_ACCENT, 1, 6, 10.0, 5.0))
		th.set_stylebox("hover_pressed", t, sbox(C_ACCENT.darkened(0.40), C_ACCENT.lightened(0.1), 1, 6, 10.0, 5.0))
		th.set_stylebox("disabled", t, sbox(C_PANEL, C_BORDER.darkened(0.25), 1, 6, 10.0, 5.0))
		th.set_stylebox("focus", t, StyleBoxEmpty.new())
		th.set_color("font_color", t, C_TEXT)
		th.set_color("font_hover_color", t, Color(1, 1, 1))
		th.set_color("font_pressed_color", t, Color(1, 1, 1))
		th.set_color("font_hover_pressed_color", t, Color(1, 1, 1))
		th.set_color("font_disabled_color", t, C_FAINT)
		th.set_color("font_focus_color", t, C_TEXT)
	# акцентная кнопка («Следующий месяц»)
	th.set_type_variation("AccentButton", "Button")
	th.set_stylebox("normal", "AccentButton", sbox(C_ACCENT.darkened(0.20), C_ACCENT.lightened(0.15), 1, 8, 14.0, 6.0))
	th.set_stylebox("hover", "AccentButton", sbox(C_ACCENT, Color(1, 1, 1, 0.5), 1, 8, 14.0, 6.0))
	th.set_stylebox("pressed", "AccentButton", sbox(C_ACCENT.darkened(0.45), C_ACCENT, 1, 8, 14.0, 6.0))
	th.set_stylebox("disabled", "AccentButton", sbox(C_PANEL2, C_BORDER, 1, 8, 14.0, 6.0))
	th.set_font_size("font_size", "AccentButton", 16)
	# вкладки экранов
	th.set_type_variation("TabButton", "Button")
	th.set_stylebox("normal", "TabButton", sbox(C_PANEL2, C_BORDER, 1, 8, 8.0, 6.0))
	th.set_stylebox("hover", "TabButton", sbox(C_PANEL2.lightened(0.12), C_ACCENT.darkened(0.2), 1, 8, 8.0, 6.0))
	var tab_on := sbox(C_ACCENT.darkened(0.30), C_ACCENT, 1, 8, 8.0, 6.0)
	tab_on.border_width_bottom = 3
	th.set_stylebox("pressed", "TabButton", tab_on)
	th.set_stylebox("hover_pressed", "TabButton", tab_on)
	th.set_font_size("font_size", "TabButton", 15)
	# варианты ответа на событие
	th.set_type_variation("ChoiceButton", "Button")
	th.set_stylebox("normal", "ChoiceButton", sbox(C_PANEL2, C_BORDER, 1, 8, 12.0, 8.0))
	th.set_stylebox("hover", "ChoiceButton", sbox(C_PANEL2.lightened(0.10), C_WARN, 1, 8, 12.0, 8.0))
	th.set_stylebox("pressed", "ChoiceButton", sbox(C_WARN.darkened(0.55), C_WARN, 1, 8, 12.0, 8.0))
	th.set_font_size("font_size", "ChoiceButton", 15)
	th.set_type_variation("OptButton", "Button")
	th.set_stylebox("normal", "OptButton", sbox(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 8, 8.0, 7.0))
	th.set_stylebox("hover", "OptButton", sbox(Color(1, 1, 1, 0.07), Color(0, 0, 0, 0), 0, 8, 8.0, 7.0))
	th.set_stylebox("pressed", "OptButton", sbox(C_WARN.darkened(0.55), C_WARN, 1, 8, 8.0, 7.0))
	th.set_stylebox("focus", "OptButton", sbox(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 8, 8.0, 7.0))
	th.set_font_size("font_size", "OptButton", 16)
	th.set_type_variation("TopicButton", "Button")
	th.set_stylebox("normal", "TopicButton", sbox(C_PANEL2, C_BORDER, 1, 8, 10.0, 6.0))
	th.set_stylebox("hover", "TopicButton", sbox(C_PANEL2.lightened(0.10), C_PURPLE.darkened(0.2), 1, 8, 10.0, 6.0))
	th.set_stylebox("pressed", "TopicButton", sbox(C_PURPLE.darkened(0.58), C_PURPLE, 2, 8, 10.0, 6.0))
	th.set_stylebox("hover_pressed", "TopicButton", sbox(C_PURPLE.darkened(0.50), C_PURPLE, 2, 8, 10.0, 6.0))
	th.set_font_size("font_size", "TopicButton", 14)
	# мелкая кнопка
	th.set_type_variation("SmallButton", "Button")
	for st in ["normal", "hover", "pressed", "disabled"]:
		var base: StyleBoxFlat = th.get_stylebox(st, "Button").duplicate()
		base.content_margin_left = 6.0
		base.content_margin_right = 6.0
		base.content_margin_top = 2.0
		base.content_margin_bottom = 2.0
		th.set_stylebox(st, "SmallButton", base)
	th.set_font_size("font_size", "SmallButton", 12)
	# --- выпадающее меню ---
	th.set_stylebox("panel", "PopupMenu", sbox(C_PANEL2, C_ACCENT.darkened(0.3), 1, 7, 6.0, 6.0))
	th.set_stylebox("hover", "PopupMenu", sbox(C_ACCENT.darkened(0.45), Color(0, 0, 0, 0), 0, 4, 6.0, 3.0))
	th.set_color("font_color", "PopupMenu", C_TEXT)
	th.set_color("font_hover_color", "PopupMenu", Color(1, 1, 1))
	# --- ползунки ---
	th.set_stylebox("slider", "HSlider", sbox(C_BG, C_BORDER, 1, 4, 0.0, 3.0))
	th.set_stylebox("grabber_area", "HSlider", sbox(C_ACCENT.darkened(0.15), Color(0, 0, 0, 0), 0, 4, 0.0, 3.0))
	th.set_stylebox("grabber_area_highlight", "HSlider", sbox(C_ACCENT, Color(0, 0, 0, 0), 0, 4, 0.0, 3.0))
	th.set_icon("grabber", "HSlider", make_dot_tex(18, C_TEXT, C_ACCENT, 3.0))
	th.set_icon("grabber_highlight", "HSlider", make_dot_tex(18, Color(1, 1, 1), C_ACCENT.lightened(0.2), 3.0))
	th.set_icon("grabber_disabled", "HSlider", make_dot_tex(18, C_FAINT, C_BORDER, 3.0))
	# --- полосы прокрутки ---
	for t in ["VScrollBar", "HScrollBar"]:
		th.set_stylebox("scroll", t, sbox(Color(0, 0, 0, 0.0), Color(0, 0, 0, 0), 0, 5, 3.0, 3.0))
		th.set_stylebox("grabber", t, sbox(C_BORDER.lightened(0.12), Color(0, 0, 0, 0), 0, 4, 3.0, 3.0))
		th.set_stylebox("grabber_highlight", t, sbox(C_ACCENT.darkened(0.25), Color(0, 0, 0, 0), 0, 4, 3.0, 3.0))
		th.set_stylebox("grabber_pressed", t, sbox(C_ACCENT, Color(0, 0, 0, 0), 0, 4, 3.0, 3.0))
	# --- подсказки и разделители ---
	th.set_stylebox("panel", "TooltipPanel", sbox(Color(0.055, 0.067, 0.095, 0.98), C_ACCENT.darkened(0.3), 1, 8, 11.0, 8.0))
	th.set_color("font_color", "TooltipLabel", C_TEXT)
	th.set_font_size("font_size", "TooltipLabel", 14)
	var line := StyleBoxLine.new()
	line.color = C_BORDER
	line.thickness = 1
	th.set_stylebox("separator", "HSeparator", line)
	th.set_constant("separation", "HSeparator", 8)
	return th


func accent_for_desk(desk: int) -> Color:
	match desk:
		0: return C_ACCENT
		1: return C_PURPLE
		2: return C_TEAL
		3: return C_PURPLE
		4: return C_PURPLE
		5: return C_GOOD
		7: return C_TEAL
		8: return C_PURPLE
		10: return C_TEAL
		11: return C_WARN
		12: return C_PURPLE
		13: return C_BAD
		14: return C_TEAL
		9: return C_GOOD
		6: return C_WARN
		-2: return C_WARN
	return Color(0.55, 0.62, 0.80)


func polish_tree(n: Node) -> void:
	for ch in n.get_children():
		if ch is Button or ch is HSlider:
			(ch as Control).mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if ch is Label and (ch as Label).clip_text:
			(ch as Label).text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		elif ch is Button and (ch as Button).clip_text:
			(ch as Button).text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		polish_tree(ch)


func make_chip(parent: Control, key: String, caption: String, tip: String) -> void:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", sbox(C_PANEL2, C_BORDER, 1, 8, 5.0, 3.0))
	pc.tooltip_text = tip
	pc.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", -2)
	pc.add_child(vb)
	var cap := Label.new()
	cap.text = caption
	cap.add_theme_font_size_override("font_size", 10)
	cap.add_theme_color_override("font_color", C_DIM)
	vb.add_child(cap)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	vb.add_child(row)
	var v := Label.new()
	v.add_theme_font_size_override("font_size", 15)
	row.add_child(v)
	var d := Label.new()
	d.add_theme_font_size_override("font_size", 10)
	d.size_flags_vertical = Control.SIZE_SHRINK_END
	row.add_child(d)
	chips[key] = {"value": v, "delta": d}


func set_chip(key: String, text: String, col: Color, delta_text: String = "", dcol: Color = Color(0.6, 0.63, 0.72)) -> void:
	var d: Dictionary = chips[key]
	var v: Label = d["value"]
	v.text = text
	v.add_theme_color_override("font_color", col)
	var dl: Label = d["delta"]
	dl.text = delta_text
	dl.visible = delta_text != ""
	dl.add_theme_color_override("font_color", dcol)


func update_chips() -> void:
	if chips.is_empty():
		return
	var parl_in := parl_term() - (turn - last_parl)
	var pv: Dictionary = top_prev
	var ap := approval()
	var dap: float = ap - float(pv.get("appr", ap))
	var dinfl: float = inflation - float(pv.get("infl", inflation))
	var dun: float = unemployment - float(pv.get("unemp", unemployment))
	var dr: float = debt / gdp * 100.0
	var ddebt: float = dr - float(pv.get("debt", dr))
	var gs := gov_seats()
	set_chip("date", date_chip(), C_TEXT)
	set_chip("appr", "%.0f%%" % ap, scale_color(ap / 100.0), arrow_text(dap, 1), delta_col(dap, true))
	set_chip("gdp", fmt_n(gdp), C_TEXT, "%s%.1f%%" % ["+" if growth >= 0.0 else "", growth], C_GOOD if growth >= 2.0 else (C_WARN if growth >= 0.0 else C_BAD))
	set_chip("infl", "%.1f%%" % inflation, scale_color(1.0 - inflation / 12.0), arrow_text(dinfl, 2), delta_col(dinfl, false))
	set_chip("unemp", "%.1f%%" % unemployment, scale_color(1.0 - unemployment / 14.0), arrow_text(dun, 2), delta_col(dun, false))
	set_chip("debt", "%.0f%%" % dr, scale_color(1.0 - dr / 110.0), arrow_text(ddebt, 1), delta_col(ddebt, false))
	var cr: float = cap_rate()
	set_chip("cap", "%.1f" % capital, C_WARN if capital < 15.0 else C_TEXT, "%s%.1f/мес" % ["+" if cr >= 0.0 else "", cr], C_GOOD if cr >= 0.7 else C_DIM)
	set_chip("coal", "%d/%d" % [gs, SEATS], C_GOOD if gov_ok() else C_BAD, "кризис" if not gov_ok() else "", C_BAD)
	var el_d: int = days_until_months(parl_in)
	set_chip("elec", ("%d дн." % el_d) if el_d < 90 else months_short(parl_in), C_TEXT)
	(chips["elec"]["value"] as Label).tooltip_text = loc("Выборы в Бундестаг через %s (%d дн.)" % [months_text(parl_in), el_d])


func draw_budget_viz() -> void:
	var c := budget_viz
	if c == null:
		return
	var font := c.get_theme_default_font()
	var lw := 62.0
	var w: float = c.size.x - lw - 2.0
	var tr := 0.0
	var te := 0.0
	for r in viz_rev:
		tr += float(r[1])
	for e in viz_exp:
		te += float(e[1])
	var mx: float = maxf(maxf(tr, te), 0.001)
	var rows: Array = [["Доходы", viz_rev, tr], ["Расходы", viz_exp, te]]
	var y := 3.0
	for row in rows:
		c.draw_string(font, Vector2(0.0, y + 13.0), String(row[0]), HORIZONTAL_ALIGNMENT_LEFT, lw, 12, C_DIM)
		var x := lw
		var segs: Array = row[1]
		var rowtot: float = row[2]
		var total_w: float = w * rowtot / mx
		c.draw_rect(Rect2(lw, y, w, 17.0), Color(0.055, 0.067, 0.098))
		for seg in segs:
			var sw: float = total_w * float(seg[1]) / maxf(rowtot, 0.001)
			if sw > 0.4:
				c.draw_rect(Rect2(x, y, maxf(sw - 1.0, 0.5), 17.0), seg[2])
			x += sw
		y += 24.0
	var bal := tr - te
	var txt := "%s%.1f млрд в год" % ["профицит +" if bal >= 0.0 else "дефицит ", absf(bal)]
	c.draw_string(font, Vector2(lw, y + 10.0), txt, HORIZONTAL_ALIGNMENT_LEFT, w, 12, C_GOOD if bal >= 0.0 else C_BAD)


func on_log_detail(on: bool) -> void:
	log_detail = on


func show_tab(t: int) -> void:
	show_desk(0 if t == 0 else (econ_page if t == 1 else (politics_page if t == 2 else map_page)))


func update_subbar(i: int) -> void:
	if subbar == null:
		return
	var on: bool = i == 1 or i == 3 or i == 4 or i == 6 or i == 11 or i == 12
	var on2: bool = i == 5 or i == 7 or i == 10
	subbar.visible = on
	if subbar2 != null:
		subbar2.visible = on2
		(sub2_buttons[0] as Button).set_pressed_no_signal(i == 5)
		(sub2_buttons[1] as Button).set_pressed_no_signal(i == 7)
		(sub2_buttons[2] as Button).set_pressed_no_signal(i == 10)
	var on3: bool = i == 2 or i == 8 or i == 9 or i == 13 or i == 14
	if subbar3 != null:
		subbar3.visible = on3
		var pg3 := [2, 8, 9, 13, 14]
		for k3 in 5:
			(sub3_buttons[k3] as Button).set_pressed_no_signal(i == pg3[k3])
	workspace.offset_top = 64.0 + (40.0 if (on or on2 or on3) else 0.0)
	var pages := [1, 3, 4, 6, 11, 12]
	for k in 6:
		(sub_buttons[k] as Button).set_pressed_no_signal(i == pages[k])


func btn_icon(b: Button, kind: String, col: Color = Color(0.78, 0.86, 1.0)) -> void:
	var ic: Control = Ico.make(kind, col, 18.0)
	ic.anchor_top = 0.5
	ic.anchor_bottom = 0.5
	ic.offset_left = 9.0
	ic.offset_right = 27.0
	ic.offset_top = -9.0
	ic.offset_bottom = 9.0
	b.add_child(ic)
	b.text = "     " + b.text.strip_edges()


func build_subbar() -> void:
	subbar = HBoxContainer.new()
	subbar.add_theme_constant_override("separation", 6)
	add_child(subbar)
	subbar.position = Vector2(8.0, 64.0)
	var names := ["Парламент", "Законы", "Правительство", "Население", "Религия и миграция", "Оппозиция и сделки"]
	var pages := [1, 3, 4, 6, 11, 12]
	sub_buttons.clear()
	for k in 6:
		var b := Button.new()
		b.theme_type_variation = "TabButton"
		b.text = names[k]
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(168.0 if k < 4 else 210.0, 32.0)
		b.pressed.connect(show_desk.bind(pages[k]))
		btn_icon(b, ["hall", "scroll", "bank", "people", "faith", "hall"][k])
		subbar.add_child(b)
		sub_buttons.append(b)
	subbar.visible = false
	subbar2 = HBoxContainer.new()
	subbar2.add_theme_constant_override("separation", 6)
	add_child(subbar2)
	subbar2.position = Vector2(8.0, 64.0)
	sub2_buttons.clear()
	var n2 := ["Рынки и финансы", "Товары и цены", "Влияние и зависимость"]
	var p2 := [5, 7, 10]
	for k in 3:
		var b2 := Button.new()
		b2.theme_type_variation = "TabButton"
		b2.text = n2[k]
		b2.toggle_mode = true
		b2.focus_mode = Control.FOCUS_NONE
		b2.custom_minimum_size = Vector2(190.0 if k < 2 else 226.0, 32.0)
		b2.pressed.connect(show_desk.bind(p2[k]))
		btn_icon(b2, ["trend", "box", "handshake"][k])
		subbar2.add_child(b2)
		sub2_buttons.append(b2)
	subbar2.visible = false
	subbar3 = HBoxContainer.new()
	subbar3.add_theme_constant_override("separation", 6)
	add_child(subbar3)
	subbar3.position = Vector2(8.0, 64.0)
	sub3_buttons.clear()
	var n3 := ["Карта", "Регионы и автономия", "Территории", "Армия и война", "Флот"]
	var p3 := [2, 8, 9, 13, 14]
	for k in 5:
		var b3 := Button.new()
		b3.theme_type_variation = "TabButton"
		b3.text = n3[k]
		b3.toggle_mode = true
		b3.focus_mode = Control.FOCUS_NONE
		b3.custom_minimum_size = Vector2(170.0 if k < 3 else 150.0, 32.0)
		b3.pressed.connect(show_desk.bind(p3[k]))
		btn_icon(b3, ["pin", "grid", "flag", "shield", "ship"][k])
		subbar3.add_child(b3)
		sub3_buttons.append(b3)
	subbar3.visible = false


func build_auto_window() -> void:
	var w: FloatWindow = new_window("autopilot", "Советник и автопилот", 0, Rect2(0.47, 0.30, 0.235, 0.48))
	ap_advisor_rt = make_rt(w.body)
	add_title(w.body, "Автопилот")
	var defs := [
		["bal", "Автобаланс бюджета", "Каждый месяц сам подстраивает налоги (НДС, подоходный, на прибыль) так, чтобы дефицит не превышал заданный предел."],
		["events", "Автоответ на события", "Решает события за вас по выбранному стилю. Коалиционные и партийные события остаются за вами."],
		["repair", "Авторемонт сооружений", "Ремонтирует сооружения, когда их износ ниже 60%, если долг не слишком высок."],
		["build", "Автостроительство мощностей", "Если рынку не хватает мощностей, сам начинает стройку в самом бедном свободном регионе (тратит политкапитал)."],
		["cb", "Автоматическая ставка центробанка", "Центробанк сам управляет ключевой ставкой."],
	]
	for d in defs:
		var cbn := CheckButton.new()
		cbn.text = d[1]
		cbn.tooltip_text = d[2]
		cbn.focus_mode = Control.FOCUS_NONE
		cbn.clip_text = true
		cbn.toggled.connect(on_ap_toggle.bind(d[0]))
		w.body.add_child(cbn)
		ap_checks[d[0]] = cbn
		if d[0] == "bal":
			var sl := ec_slider(w.body, "Допустимый дефицит", 0.0, 4.0, 0.5, "Автобаланс не даст дефициту превысить это значение (% ВВП).")
			ap_target_slider = sl[0]
			ap_target_label = sl[1]
			ap_target_slider.value = 0.5
			ap_target_slider.value_changed.connect(on_ap_target)
		elif d[0] == "events":
			ap_style_opt = OptionButton.new()
			ap_style_opt.clip_text = true
			ap_style_opt.tooltip_text = "Осторожный: меньше долгов и рисков. Народный: больше поддержки групп. Деловой: рост и интересы бизнеса."
			for st in AP_STYLES:
				ap_style_opt.add_item(st)
			ap_style_opt.item_selected.connect(on_ap_style)
			w.body.add_child(ap_style_opt)
	add_title(w.body, "Быстрые действия")
	var fr := HFlowContainer.new()
	fr.add_theme_constant_override("h_separation", 4)
	fr.add_theme_constant_override("v_separation", 4)
	w.body.add_child(fr)
	var bal := Button.new()
	bal.text = "Сбалансировать сейчас"
	bal.tooltip_text = "Один раз подтянуть налоги так, чтобы дефицит был около 0.3% ВВП."
	bal.focus_mode = Control.FOCUS_NONE
	bal.pressed.connect(balance_now)
	fr.add_child(bal)
	for id in PRESETS:
		var pb := Button.new()
		pb.text = PRESETS[id]["name"]
		pb.tooltip_text = "Задаёт сразу несколько ползунков: " + PRESETS[id]["info"] + ". Заблокированные ползунки не меняются."
		pb.focus_mode = Control.FOCUS_NONE
		pb.pressed.connect(apply_preset.bind(id))
		fr.add_child(pb)
	ap_btns = [bal]


func on_ap_toggle(on: bool, key: String) -> void:
	if slider_busy:
		return
	if key == "cb":
		if not ec.is_empty():
			ec["rate_auto"] = on
	else:
		ap[key] = on
	refresh()


func on_ap_target(v: float) -> void:
	if slider_busy:
		return
	ap["target"] = v
	refresh()


func on_ap_style(i: int) -> void:
	ap["style"] = i


func update_auto_window() -> void:
	if ap_advisor_rt == null:
		return
	var lines: PackedStringArray = []
	var cols := [COL_GOOD, COL_DIM, COL_WARN, COL_BAD]
	var n := 0
	for it in advisor_lines():
		lines.append("[color=%s]●[/color] %s" % [cols[int(it[0])], it[1]])
		n += 1
		if n >= 5:
			break
	ap_advisor_rt.text = "[b]Что сейчас важно[/b]\n" + "\n".join(lines)
	slider_busy = true
	for k in ap_checks:
		var on: bool = bool(ap.get(k, false)) if k != "cb" else (bool(ec["rate_auto"]) if not ec.is_empty() else false)
		(ap_checks[k] as CheckButton).set_pressed_no_signal(on)
	ap_target_slider.set_value_no_signal(float(ap["target"]))
	ap_style_opt.select(int(ap["style"]))
	slider_busy = false
	ap_target_label.text = "%.1f%% ВВП" % float(ap["target"])
	ap_style_opt.disabled = not bool(ap["events"])
	ap_target_slider.editable = bool(ap["bal"])
	for b in ap_btns:
		(b as Button).disabled = game_over


func on_floor_toggle(on: bool) -> void:
	auto_floor_on = on
	if on:
		auto_floor()
	refresh()


# ============================================================
#  v35: МУЗЫКА И ЗВУКИ (спокойный эмбиент; свои *.ogg можно положить в audio/music/)
# ============================================================
var music_player: AudioStreamPlayer = null
var sfx_players: Array = []
var sfx_cache := {}
var music_list: Array = []
var music_idx := 0
var sfx_last := {}


func audio_ok() -> bool:
	return DisplayServer.get_name() != "headless"


func audio_load(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		var r = load(path)
		if r is AudioStream:
			return r
	var gp := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(gp) or FileAccess.file_exists(path):
		return AudioStreamOggVorbis.load_from_file(gp if FileAccess.file_exists(gp) else path)
	return null


func audio_init() -> void:
	if not audio_ok() or music_player != null:
		return
	music_player = AudioStreamPlayer.new()
	music_player.name = "Music"
	add_child(music_player)
	music_player.finished.connect(music_next)
	for i in 4:
		var p := AudioStreamPlayer.new()
		add_child(p)
		sfx_players.append(p)
	music_list.clear()
	var d := DirAccess.open("res://audio/music")
	if d != null:
		for f in d.get_files():
			var fs := String(f)
			if fs.ends_with(".ogg"):
				music_list.append("res://audio/music/" + fs)
			elif fs.ends_with(".ogg.import"):
				var base := fs.trim_suffix(".import")
				if not music_list.has("res://audio/music/" + base):
					music_list.append("res://audio/music/" + base)
	music_list.sort()
	music_idx = randi() % maxi(1, music_list.size())
	audio_apply_volume()
	music_next()


func audio_apply_volume() -> void:
	if music_player == null:
		return
	var mv: float = float(game_opts.get("music", 0.45))
	music_player.volume_db = linear_to_db(maxf(0.0001, mv * 0.55))
	music_player.stream_paused = mv <= 0.001
	var sv: float = float(game_opts.get("sfx", 0.6))
	for p in sfx_players:
		(p as AudioStreamPlayer).volume_db = linear_to_db(maxf(0.0001, sv * 0.7))


func music_next() -> void:
	if music_player == null or music_list.is_empty():
		return
	var st := audio_load(String(music_list[music_idx % music_list.size()]))
	music_idx += 1
	if st == null:
		return
	if st is AudioStreamOggVorbis:
		(st as AudioStreamOggVorbis).loop = false
	music_player.stream = st
	music_player.play()
	music_player.stream_paused = float(game_opts.get("music", 0.45)) <= 0.001


func sfx(name: String) -> void:
	if sfx_players.is_empty() or float(game_opts.get("sfx", 0.6)) <= 0.001:
		return
	var now := Time.get_ticks_msec()
	if now - int(sfx_last.get(name, -10000)) < 120:
		return
	sfx_last[name] = now
	if not sfx_cache.has(name):
		sfx_cache[name] = audio_load("res://audio/sfx/%s.ogg" % name)
	var st: AudioStream = sfx_cache[name]
	if st == null:
		return
	for p in sfx_players:
		var ap2: AudioStreamPlayer = p
		if not ap2.playing:
			ap2.stream = st
			ap2.play()
			return


func toggle_music() -> void:
	game_opts["music"] = 0.0 if float(game_opts.get("music", 0.45)) > 0.001 else 0.45
	audio_apply_volume()
	if music_btn != null:
		music_btn.text = "♪" if float(game_opts["music"]) > 0.001 else "🔇"
