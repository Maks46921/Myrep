# Интерфейс: окна, тема, верхняя панель, экран «Бюджет», обновление.
extends "res://scripts/logic/saves.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func build_army_windows() -> void:
	pass


func build_bud_oneoff(parent: Control) -> void:
	pass


func build_bud_transfer(parent: Control) -> void:
	pass


func build_build_window() -> void:
	pass


func build_cn_overlay() -> void:
	pass


func build_crisis_windows() -> void:
	pass


func build_dip_windows() -> void:
	pass


func build_econ_windows() -> void:
	pass


func build_econsys_windows() -> void:
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


func build_io_windows() -> void:
	pass


func build_law_windows() -> void:
	pass


func build_map_windows() -> void:
	pass


func build_meas_overlay() -> void:
	pass


func build_more_menu(tabs: Control) -> void:
	pass


func build_notify_ui() -> void:
	pass


func build_opp_windows() -> void:
	pass


func build_politics_windows() -> void:
	pass


func build_pop_windows() -> void:
	pass


func build_realm_windows() -> void:
	pass


func build_regime_windows() -> void:
	pass


func build_settings_button(hb: Control) -> void:
	pass


func build_soc_windows() -> void:
	pass


func build_society_windows() -> void:
	pass


func build_tech_windows() -> void:
	pass


func build_today_windows() -> void:
	pass


func build_war_windows() -> void:
	pass


func click_name() -> String:
	return ""


func cn_is_open() -> bool:
	return false


func crisis_is_open() -> bool:
	return false


func es_ui_sync() -> void:
	pass


func flag_win_open(on: bool) -> void:
	pass


func io_bar_h() -> float:
	return 0.0


func make_crisis_button(parent: Control) -> void:
	pass


func make_meas_button(parent: Control) -> void:
	pass


func make_tech_button(parent: Control) -> void:
	pass


func map_apply_mode() -> void:
	pass


func meas_is_open() -> bool:
	return false


func music_dirs() -> Array:
	return []


func nav_init() -> void:
	pass


func nav_note(_i: int) -> void:
	pass


func on_bud_accept() -> void:
	pass


func on_win_help(w: FloatWindow) -> void:
	pass


func on_win_star(w: FloatWindow) -> void:
	pass


func overlays_lock() -> void:
	pass


func reg_ui_sync() -> void:
	pass


func set_crisis_open(on: bool) -> void:
	pass


func set_meas_open(on: bool) -> void:
	pass


func set_tech_open(on: bool) -> void:
	pass


func subbar_hide_absent() -> void:
	pass


func tech_is_open() -> bool:
	return false


func update_army_windows() -> void:
	pass


func update_bud_head() -> void:
	pass


func update_build_window() -> void:
	pass


func update_chips_extra() -> void:
	pass


func update_cn_window() -> void:
	pass


func update_corp_windows() -> void:
	pass


func update_crisis_windows() -> void:
	pass


func update_dip_windows() -> void:
	pass


func update_econ_windows() -> void:
	pass


func update_es_windows() -> void:
	pass


func update_fed_windows() -> void:
	pass


func update_fleet_windows() -> void:
	pass


func update_goods_detail() -> void:
	pass


func update_goods_windows() -> void:
	pass


func update_gov_windows() -> void:
	pass


func update_io_windows() -> void:
	pass


func update_law_windows() -> void:
	pass


func update_meas_window() -> void:
	pass


func update_opp_windows() -> void:
	pass


func update_parliament() -> void:
	pass


func update_realm_windows() -> void:
	pass


func update_regime_windows() -> void:
	pass


func update_regions_ui() -> void:
	pass


func update_soc_windows() -> void:
	pass


func update_society_windows() -> void:
	pass


func update_tech_windows() -> void:
	pass


func update_today() -> void:
	pass


func update_ui_extras() -> void:
	pass


func update_war_windows() -> void:
	pass


func vote_hist_menu(anchor: Control) -> void:
	pass


func vote_reopen(i: int) -> void:
	pass


func win_menu_extra(pm: PopupMenu) -> void:
	pass


func win_menu_pick(mid: int) -> bool:
	return false


func win_mode_ok(id: String) -> bool:
	return false


# --- конец заглушек ---


func new_window(id: String, title: String, desk: int, fr: Rect2, scrolling: bool = true) -> FloatWindow:
	var w := FloatWindow.new()
	w.setup(title, scrolling, accent_for_desk(desk))
	w.desk = desk
	w.frac = fr
	w.default_frac = fr
	w.set_closable(desk != -2)
	w.close_requested.connect(on_win_close)
	w.help_requested.connect(on_win_help)
	w.star_requested.connect(on_win_star)
	w.set_helpable(desk >= 0)
	workspace.add_child(w)
	wins[id] = w
	return w


# окна, закрытые по умолчанию (открываются через «Окна»)
const WIN_DEFAULT_CLOSED := ["regtable", "regact", "regecon", "dtable", "adm", "build", "pop_agent", "bud_tr", "reg_dec", "uq_win"]


func win_vis(id: String, on: bool) -> void:
	if not wins.has(id):
		return
	var w: FloatWindow = wins[id]
	var was: bool = w.visible
	w.visible = on and not w.closed and win_mode_ok(id)
	if w.visible and not was:
		win_fade_in(w)


# v49: окно появляется плавно (прозрачность 0 → 1); на ввод не влияет — по окну можно щёлкать сразу
func win_fade_in(w: Control, dur: float = 0.22) -> void:
	if w == null or not w.is_inside_tree():
		return
	if not bool(game_opts.get("anim", true)):
		w.modulate.a = 1.0
		return
	w.modulate.a = 0.0
	var tw: Tween = w.create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(w, "modulate:a", 1.0, dur)


func on_win_close(w: FloatWindow) -> void:
	w.closed = true
	w.visible = false


func win_menu_fill() -> void:
	var pm: PopupMenu = win_menu.get_popup()
	pm.clear()
	var ids: Array = []
	for id in wins:
		var w: FloatWindow = wins[id]
		if w.desk == -2 or not (w.desk == current_desk or w.desk == -1) or not win_mode_ok(String(id)):
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
	win_menu_extra(pm)


func on_win_menu(idx: int) -> void:
	var pm: PopupMenu = win_menu.get_popup()
	var mid: int = pm.get_item_id(idx)
	if win_menu_pick(mid):
		return
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


# рамка (верхняя кнопка) для вкладки: 0 Бюджет, 1 Экономика, 2 Политика, 3 Мир (карта, регионы, армия и организации), 5 Общество, 6 Сегодня
# (кнопка 4 «Организации» спрятана: они стали вкладкой рамки «Мир»)
func desk_tab(i: int) -> int:
	if i == 0:
		return 0
	if i in [5, 7, 10, 16, 17]:
		return 1
	if i in [2, 8, 9, 13, 14, 15, 18]:
		return 3
	if i == 21:
		return 6
	if i in [11, 19, 20]:
		return 5
	return 2


func show_desk(i: int) -> void:
	if current_desk != i:
		sfx("click")
		nav_note(i)
	current_desk = i
	if i == 1 or i == 3 or i == 4 or i == 6 or i == 12:
		politics_page = i
	if i == 11 or i == 19 or i == 20:
		society_page = i
	if i == 5 or i == 7 or i == 10 or i == 16 or i == 17:
		econ_page = i
	if i == 2 or i == 8 or i == 9 or i == 13 or i == 14 or i == 15 or i == 18:
		map_page = i
	var k_fade := 0
	for id in wins:
		var w: FloatWindow = wins[id]
		var was: bool = w.visible
		# v50: окно выборов — только пока открыты итоги выборов, окно события — только при событии (раньше пустое окно выборов всплывало вместе с событием)
		var modal_on: bool = election_open if id == "election" else not current_event.is_empty()
		w.visible = ((w.desk == i) or (w.desk == -1) or (w.desk == -2 and modal_on)) and (w.desk == -2 or not w.closed) and win_mode_ok(String(id))
		if w.visible and not was:
			# v49: окна нового раздела проявляются с небольшой задержкой друг за другом
			win_fade_in(w, 0.18 + 0.04 * float(mini(k_fade, 5)))
			k_fade += 1
	var tab: int = desk_tab(i)
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
	ui_bg = bg

	var top := PanelContainer.new()
	top.custom_minimum_size = Vector2(0.0, 58.0)
	var tsb := sbox(C_PANEL, C_BORDER, 0, 0, 10.0, 6.0)
	tsb.border_width_bottom = 1
	tsb.shadow_color = Color(0, 0, 0, 0.45)
	tsb.shadow_size = 8
	tsb.shadow_offset = Vector2(0.0, 2.0)
	top.add_theme_stylebox_override("panel", tsb)
	# v45_1: отблеск сверху и тонкая светящаяся линия снизу
	top.draw.connect(func() -> void:
		Gfx.vgrad(top, Rect2(0.0, 0.0, top.size.x, top.size.y), Color(1, 1, 1, 0.045), Color(0, 0, 0, 0.0))
		Gfx.hgrad(top, Rect2(0.0, top.size.y - 1.0, top.size.x * 0.5, 1.0), Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.0), Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.55))
		Gfx.hgrad(top, Rect2(top.size.x * 0.5, top.size.y - 1.0, top.size.x * 0.5, 1.0), Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.55), Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.0)))
	add_child(top)
	ui_top = top
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 0)
	# 0.57: верхняя панель в две строки: вверху рамки и кнопки, под ними показатели (на 1920 они раньше обрезались справа)
	ui_top_h = 64.0 if int(game_opts.get("top_rows", 2)) == 1 else 112.0
	top.custom_minimum_size = Vector2(0.0, ui_top_h - 6.0)
	var top_v := VBoxContainer.new()
	top_v.add_theme_constant_override("separation", 4)
	top.add_child(top_v)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	top_v.add_child(hb)
	var hb2: HBoxContainer = hb
	if ui_top_h > 70.0:
		hb2 = HBoxContainer.new()
		hb2.add_theme_constant_override("separation", 6)
		top_v.add_child(hb2)
	# v50: флаг страны — в левом углу верхней панели (щелчок — смена страны)
	var cbtn := Button.new()
	cbtn.theme_type_variation = "SmallButton"
	cbtn.text = ""
	cbtn.custom_minimum_size = Vector2(46.0, 38.0)
	cbtn.tooltip_text = "%s: государство и флаг" % (String(WORLD[ccode]["name"]) if WORLD.has(ccode) else ccode)
	flag_sync()
	top_flag = Flags.make(ccode, 18.0)
	top_flag.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_flag.offset_left = 5.0
	top_flag.offset_right = -5.0
	top_flag.offset_top = 6.0
	top_flag.offset_bottom = -6.0
	cbtn.add_child(top_flag)
	cbtn.focus_mode = Control.FOCUS_NONE
	cbtn.pressed.connect(flag_win_open.bind(true))
	hb.add_child(cbtn)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	hb.add_child(tabs)
	var grp := ButtonGroup.new()
	var desk_names := ["Бюджет", "Экономика", "Политика", "Мир", "Организации", "Общество", "Сегодня"]
	for i in 7:
		var b := Button.new()
		b.theme_type_variation = "TabButton"
		b.text = desk_names[i]
		b.toggle_mode = true
		b.button_group = grp
		b.custom_minimum_size = Vector2(0.0, 40.0)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(show_tab.bind(i))
		btn_icon(b, ["coin", "chart", "hall", "globe", "globe", "people", "star"][i])
		tabs.add_child(b)
		desk_buttons.append(b)
	# 0.57: «Организации» стали вкладкой рамки «Мир», а «Сегодня» стоит первой
	(desk_buttons[4] as Button).visible = false
	tabs.move_child(desk_buttons[6], 0)
	(desk_buttons[0] as Button).set_pressed_no_signal(true)
	make_tech_button(tabs)
	make_crisis_button(tabs)
	make_meas_button(tabs)
	build_more_menu(tabs)
	# v50: показатели в прокрутке без полосы — на узком экране обрезаются справа, а кнопки времени и настроек всегда видны
	var chip_sc := ScrollContainer.new()
	chip_sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip_sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	chip_sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	chip_sc.custom_minimum_size = Vector2(120.0, 0.0)
	hb2.add_child(chip_sc)
	if hb2 != hb:
		var sp_top := Control.new()
		sp_top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(sp_top)
	var chip_row := HBoxContainer.new()
	chip_row.add_theme_constant_override("separation", 4)
	chip_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chip_sc.add_child(chip_row)
	make_chip(chip_row, "date", "ДАТА", "Текущая дата игры. Календарь идёт по дням, а экономика, политика и мир считаются каждую неделю.")
	# 0.62: семь квадратиков дней недели стоят в строке подписи, рядом со словом «ДАТА» (высота плашки не меняется)
	var wk := WeekStrip.new()
	var date_vb := (chips["date"]["pc"] as Control).get_child(0) as VBoxContainer
	var date_cap := date_vb.get_child(0) as Label
	var cap_row := HBoxContainer.new()
	cap_row.add_theme_constant_override("separation", 6)
	date_vb.add_child(cap_row)
	date_vb.move_child(cap_row, 0)
	date_cap.reparent(cap_row)
	var cap_sp := Control.new()
	cap_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cap_row.add_child(cap_sp)
	wk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cap_row.add_child(wk)
	chips["date"]["week"] = wk
	make_chip(chip_row, "appr", "РЕЙТИНГ", "Общий рейтинг власти. Стрелка — изменение за прошлый месяц. Выше 50% — вы выигрываете выборы.")
	make_chip(chip_row, "gdp", "ВВП, МЛРД", "ВВП за год. Справа — общий темп роста за год.")
	make_chip(chip_row, "infl", "ИНФЛЯЦИЯ", "Годовая инфляция. Выше 6% — экономика страдает, выше 30% — гиперинфляция.")
	make_chip(chip_row, "unemp", "БЕЗРАБОТ.", "Доля безработных.")
	make_chip(chip_row, "debt", "ДОЛГ", "Госдолг в процентах ВВП. Выше 150% — дефолт.")
	make_chip(chip_row, "res", "РЕЗЕРВЫ", "Валютные и золотые резервы, % ВВП. Ниже 3% валюта уязвима.")
	make_chip(chip_row, "fxs", "КУРС, 12 М", "Изменение курса вашей валюты за 12 месяцев.")
	make_chip(chip_row, "cap", "КАПИТАЛ", "Политический капитал: расходуется на законы, действия и переговоры.")
	make_chip(chip_row, "coal", "КОАЛИЦ.", "Мест у вашей коалиции из %d. Для большинства нужно %d." % [SEATS, MAJORITY])
	make_chip(chip_row, "elec", "ВЫБОРЫ", "Время до следующих парламентских выборов.")
	music_btn = Button.new()
	music_btn.theme_type_variation = "SmallButton"
	music_btn.text = "♪" if float(game_opts.get("music", 0.45)) > 0.001 else "🔇"
	music_btn.custom_minimum_size = Vector2(34.0, 34.0)
	music_btn.tooltip_text = "Музыка: включить или выключить. Громкость музыки и звуков — в настройках новой игры (кнопка с флагом → «Настройки игры»)."
	music_btn.focus_mode = Control.FOCUS_NONE
	music_btn.pressed.connect(toggle_music)
	hb.add_child(music_btn)
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
	speed_opt.custom_minimum_size = Vector2(84.0, 40.0)
	speed_opt.fit_to_longest_item = false
	speed_opt.tooltip_text = "Скорость: сколько недель календаря проходит за секунду реального времени"
	for k in range(1, PLAY_SPEEDS.size()):
		speed_opt.add_item(String(PLAY_NAMES[k]), k)
		speed_opt.set_item_tooltip(k - 1, "%d нед. в секунду" % int(PLAY_SPEEDS[k] / 7.0))
	speed_opt.item_selected.connect(on_speed_selected)
	hb.add_child(speed_opt)
	build_settings_button(hb)
	wrap_timer = Timer.new()
	wrap_timer.one_shot = true
	wrap_timer.timeout.connect(on_wrap_timer)
	add_child(wrap_timer)

	map_base = Control.new()
	map_base.clip_contents = true
	add_child(map_base)
	map_base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_base.offset_top = ui_top_h
	map_base.offset_left = 6.0
	map_base.offset_right = -6.0
	map_base.offset_bottom = -6.0
	workspace = Control.new()
	workspace.clip_contents = true
	workspace.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(workspace)
	workspace.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	workspace.offset_top = ui_top_h
	workspace.offset_left = 6.0
	workspace.offset_right = -6.0
	workspace.offset_bottom = -6.0
	workspace.resized.connect(layout_windows)
	build_subbar()

	build_budget_windows()
	build_politics_windows()
	build_regime_windows()
	build_law_windows()
	build_gov_windows()
	build_pop_windows()
	build_map_windows()
	build_build_window()
	build_econ_windows()
	build_econsys_windows()
	build_io_windows()
	build_dip_windows()
	build_goods_windows()
	build_fed_windows()
	build_soc_windows()
	build_society_windows()
	build_tech_windows()
	build_crisis_windows()
	build_meas_overlay()
	build_cn_overlay()
	build_opp_windows()
	build_fleet_windows()
	build_war_windows()
	build_army_windows()
	build_auto_window()
	build_realm_windows()
	build_today_windows()
	build_notify_ui()
	nav_init()
	build_log_and_event()
	# 0.56: событие и итоги выборов всплывают поверх «Технологий» и «Кризисов» и не закрывают их
	modal_layer = Control.new()
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(modal_layer)
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.offset_top = workspace.offset_top
	modal_layer.offset_left = workspace.offset_left
	modal_layer.offset_right = workspace.offset_right
	modal_layer.offset_bottom = workspace.offset_bottom
	for mid in ["event", "election"]:
		if wins.has(mid):
			(wins[mid] as FloatWindow).reparent(modal_layer, false)
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
	tone_button(b)
	return b


# v50: действия «расширить / повысить / усилить» — зелёный край, «урезать / понизить / отменить» — красный, чтобы не путать
const TONE_UP := ["Повысить", "Расширить", "Увеличить", "Поднять", "Усилить", "Принять в", "Заключить", "Начать", "Ввести"]
const TONE_DN := ["Понизить", "Урезать", "Сократить", "Снизить", "Ослабить", "Отменить", "Расторгнуть", "Отозвать", "Выйти", "Свернуть", "Замедлить", "Сдерживать", "Остановить"]


func tone_button(b: Button) -> void:
	var t: String = b.text.strip_edges()
	var tone := 0
	for k in TONE_UP:
		if t.begins_with(k):
			tone = 1
	for k in TONE_DN:
		if t.begins_with(k):
			tone = -1
	if t.contains(" +1") or t.contains("+1 ("):
		tone = 1
	elif t.contains(" −1") or t.contains(" -1"):
		tone = -1
	if tone == 0:
		return
	var col: Color = Color(0.36, 0.80, 0.55) if tone > 0 else Color(0.93, 0.45, 0.42)
	for st in ["normal", "hover", "pressed", "disabled"]:
		var base := b.get_theme_stylebox(st)
		if base is StyleBoxFlat:
			var sb := (base as StyleBoxFlat).duplicate() as StyleBoxFlat
			sb.border_width_left = 4
			sb.border_color = Color(col.r, col.g, col.b, 0.9 if st != "disabled" else 0.35)
			sb.bg_color = sb.bg_color.lerp(col, 0.08 if st != "disabled" else 0.03)
			b.add_theme_stylebox_override(st, sb)


func make_rt(parent: Control) -> RichTextLabel:
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rt.add_theme_constant_override("line_separation", 2)
	parent.add_child(rt)
	fmt_rts.append(rt)
	return rt


# v50: сплошной текст упорядочивается — строка-заголовок «[b]…[/b]» получает цветную метку и отступ сверху,
# пункты «• » — отступ. Проход после каждого обновления, только для изменившихся видимых текстов.
var fmt_rts: Array = []


func fmt_sections(t: String) -> String:
	if not t.contains("[b]") and not t.contains("• "):
		return t
	var lines := t.split("\n")
	var acc: String = C_ACCENT.lightened(0.25).to_html(false)
	var out: PackedStringArray = []
	for i in lines.size():
		var ln: String = lines[i]
		var st := ln.strip_edges()
		if st.begins_with("[b]") and st.ends_with("[/b]") and st.count("[b]") == 1 and st.length() < 90:
			if i > 0 and out.size() > 0 and String(out[out.size() - 1]).strip_edges() != "":
				out.append("")
			out.append("[color=#%s]▍[/color][b]%s[/b]" % [acc, st.substr(3, st.length() - 7)])
		elif st.begins_with("• ") and not ln.begins_with("[indent]"):
			out.append("[indent]" + ln + "[/indent]")
		else:
			out.append(ln)
	return "\n".join(out)


func fmt_pass() -> void:
	var keep: Array = []
	for rt in fmt_rts:
		if not is_instance_valid(rt):
			continue
		keep.append(rt)
		var r: RichTextLabel = rt
		if not r.is_visible_in_tree():
			continue
		if r.text == String(r.get_meta("fmt", "")):
			continue
		var f := fmt_sections(r.text)
		r.set_meta("fmt", f)
		if f != r.text:
			r.text = f
	fmt_rts = keep


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
	# 0.56: точный шаг ±0,1% ВВП (с Shift — 1%)
	for dir in [-1, 1]:
		var pb := Button.new()
		pb.theme_type_variation = "SmallButton"
		pb.text = "−" if dir < 0 else "+"
		pb.focus_mode = Control.FOCUS_NONE
		pb.custom_minimum_size = Vector2(24.0, 0.0)
		pb.tooltip_text = ("Уменьшить" if dir < 0 else "Увеличить") + " на 0,1% ВВП (с Shift — на 1%). Изменение идёт в план бюджета."
		pb.pressed.connect(slider_nudge.bind(key, dir))
		top.add_child(pb)
	if String(d["kind"]) == "spend":
		var fb := Button.new()
		fb.theme_type_variation = "SmallButton"
		fb.text = "⤒"
		fb.toggle_mode = true
		fb.focus_mode = Control.FOCUS_NONE
		fb.custom_minimum_size = Vector2(26.0, 0.0)
		fb.tooltip_text = "Авто-подъём этой статьи до ожиданий групп (раз в месяц)."
		fb.toggled.connect(func(on: bool) -> void:
			if on:
				floor_keys[key] = true
				auto_floor(true)
			else:
				floor_keys.erase(key)
			refresh())
		top.add_child(fb)
		floor_btns[key] = fb
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = slider_hi(key)
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
	s.drag_ended.connect(func(_ch: bool) -> void: slider_shrink(key))
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


const BUD_GROUPS := [["Расходы: социальная сфера", ["pensions", "benefits", "health", "edu"]],
	["Расходы: безопасность и государство", ["army", "police", "admin"]],
	["Расходы: экономика и развитие", ["infra", "eco", "subs", "agri"]]]


func build_budget_windows() -> void:
	# v50: налоги и расходы — одно окно; правки — это план, в силу он вступает кнопкой «Принять бюджет»
	var w: FloatWindow = new_window("tax", "Налоги и расходы", 0, Rect2(0.0, 0.0, 0.235, 1.0))
	bud_head = PanelContainer.new()
	bud_head.add_theme_stylebox_override("panel", sbox(C_PANEL2, C_ACCENT.darkened(0.3), 1, 8, 8.0, 6.0))
	w.body.add_child(bud_head)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 4)
	bud_head.add_child(hv)
	# 0.59: блок плана всегда одной высоты, внутри прокрутка: ползунки ниже не прыгают, когда план появляется и растёт
	var hsc := ScrollContainer.new()
	hsc.custom_minimum_size = Vector2(0.0, 150.0)
	hsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hv.add_child(hsc)
	var hin := VBoxContainer.new()
	hin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hin.add_theme_constant_override("separation", 4)
	hsc.add_child(hin)
	bud_head_rt = make_rt(hin)
	bud_prev_rt = make_rt(hin)
	bud_prev_rt.visible = false
	bud_tbl_btn = CheckButton.new()
	bud_tbl_btn.text = "Таблица «было → станет»"
	bud_tbl_btn.tooltip_text = "Показать план таблицей: что стоило, сколько будет и на сколько миллиардов изменится."
	bud_tbl_btn.focus_mode = Control.FOCUS_NONE
	bud_tbl_btn.visible = false
	bud_tbl_btn.toggled.connect(func(_on: bool) -> void: update_bud_head())
	hin.add_child(bud_tbl_btn)
	bud_tbl_rt = make_rt(hin)
	bud_tbl_rt.visible = false
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	hv.add_child(hb)
	bud_accept_btn = Button.new()
	bud_accept_btn.text = "✔ Принять бюджет"
	bud_accept_btn.focus_mode = Control.FOCUS_NONE
	bud_accept_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bud_accept_btn.tooltip_text = "Утвердить план. В коалиции его сначала рассмотрит совет: несогласных партнёров можно убедить."
	bud_accept_btn.pressed.connect(on_bud_accept)
	hb.add_child(bud_accept_btn)
	bud_cancel_btn = Button.new()
	bud_cancel_btn.text = "✖ Отменить"
	bud_cancel_btn.focus_mode = Control.FOCUS_NONE
	bud_cancel_btn.tooltip_text = "Вернуть ползунки к действующему бюджету."
	bud_cancel_btn.pressed.connect(func() -> void:
		bud_cancel()
		refresh())
	hb.add_child(bud_cancel_btn)
	add_title(w.body, "Налоги")
	for d in POLICY:
		if d["kind"] == "tax" and d["key"] != "emit":
			add_slider(w.body, d)
	tax_total_label = add_wrap_label(w.body, "")
	for d in POLICY:
		if d["key"] == "emit":
			add_slider(w.body, d)
	emit_note = add_note(w.body, "", true)
	sync_emit()
	# 0.57: расходы сгруппированы по сферам
	for grp in BUD_GROUPS:
		add_title(w.body, String(grp[0]))
		for d in POLICY:
			if d["kind"] == "spend" and (grp[1] as Array).has(d["key"]):
				add_slider(w.body, d)
	build_bud_transfer(w.body)
	bud_eq_box = VBoxContainer.new()
	w.body.add_child(bud_eq_box)
	build_bud_oneoff(w.body)
	spend_total_label = add_wrap_label(w.body, "")
	var fl := CheckButton.new()
	fl.text = "Авто-подъём всех статей до ожиданий групп"
	fl.tooltip_text = "Если на статью тратится меньше, чем ждут социальные группы («группы ждут ≈» под ползунком), ползунок сам поднимется до этого уровня (раз в месяц и при включении). Для отдельной статьи — кнопка ⤒ рядом с её названием."
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
	# v50: разовая подстройка налогов (не автопилот) — из бывшего окна автопилота
	var bal := make_button("Сбалансировать налоги сейчас", w.body)
	bal.tooltip_text = "Один раз подтянуть налоги (НДС, подоходный, на прибыль) так, чтобы дефицит был около 0.3% ВВП."
	bal.pressed.connect(balance_now)
	ap_btns = [bal]
	forecast_rt = make_fold(w.body, "Доходы и расходы по статьям")

	w = new_window("economy", "Экономика и состояние страны", 0, Rect2(0.235, 0.38, 0.235, 0.62))
	stats_label = make_rt(w.body)
	add_title(w.body, "Состояние государства")
	for d in LEVELS:
		add_bar(w.body, d["key"], d["title"], d["invert"])
	level_fx_rt = make_fold(w.body, "Как состояние влияет на игру")

	w = new_window("groups", "Группы интересов", 0, Rect2(0.47, 0.0, 0.235, 0.50))
	add_bar(w.body, "approval", "Общий рейтинг", false)
	for g in GROUPS:
		add_bar(w.body, g, g, false)
	add_note(w.body, "Цифры — поддержка власти группой (0–100). Рейтинг — взвешенная сумма по числу людей в группе.")
	gp_rt = make_fold(w.body, "Каким партиям симпатизируют группы")

	# 0.56 (п.20): разовые меры — в отдельном окне с карточками (кнопка «Меры» на верхней панели)
	w = new_window("measures", "Советник и разовые меры", 0, Rect2(0.47, 0.50, 0.235, 0.50))
	meas_note_rt = make_rt(w.body)
	var mob := make_button("Открыть окно разовых мер", w.body)
	mob.tooltip_text = "Карточки всех разовых мер: кто за меру отвечает, что она даст, когда её можно провести снова."
	mob.pressed.connect(func() -> void: set_meas_open(true))


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
	var vh := Button.new()
	vh.theme_type_variation = "SmallButton"
	vh.text = "Голосования ▾"
	vh.focus_mode = Control.FOCUS_NONE
	vh.tooltip_text = "Итоги прошлых голосований: выберите и посмотрите снова."
	vh.pressed.connect(func() -> void: vote_hist_menu(vh))
	hb.add_child(vh)
	var clr := Button.new()
	clr.theme_type_variation = "SmallButton"
	clr.text = "Очистить"
	clr.focus_mode = Control.FOCUS_NONE
	clr.pressed.connect(log_clear)
	hb.add_child(clr)
	build_log_filters(w.body)
	# 0.56: журнал «рамки в рамке» — месяц в общей рамке, каждое сообщение — карточка
	log_scroll = ScrollContainer.new()
	log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	w.body.add_child(log_scroll)
	log_box = VBoxContainer.new()
	log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_box.add_theme_constant_override("separation", 8)
	log_scroll.add_child(log_box)
	log_ui_rebuild(true)

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


var viz_rev0_t := 0.0
var bud_head: PanelContainer = null
var bud_head_rt: RichTextLabel = null
var bud_prev_rt: RichTextLabel = null   # 0.57: что будет, если принять план
var bud_tbl_rt: RichTextLabel = null    # 0.57: таблица «было → станет»
var bud_tbl_btn: CheckButton = null
var bud_accept_btn: Button = null
var bud_cancel_btn: Button = null
var floor_btns := {}
var viz_exp0_t := 0.0


func update_forecast() -> void:
	if forecast_rt == null:
		return
	if bud_pending():
		var hh := bud_hold_begin()
		var b0 := compute_budget()
		bud_hold_end_quiet(hh)
		viz_rev0_t = 0.0
		viz_exp0_t = 0.0
		for k0 in b0["rev"]:
			viz_rev0_t += float(b0["rev"][k0])
		for k1 in b0["exp"]:
			viz_exp0_t += float(b0["exp"][k1])
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
		var aid: float = aid_now()
		if aid > 0.0:
			tax_total_label.text += "\nПомощь партнёров: %.1f%% ВВП (%s млрд в год)%s.\nДефицит до помощи: %.1f%% ВВП, после помощи: %.1f%% ВВП." % [aid, fmt_n(gdp * aid / 100.0, 0), (" — " + AID_NOTE) if AID_NOTE != "" else "", -bal / gdp * 100.0 + aid, -bal / gdp * 100.0]
	if spend_total_label != null:
		var sp_sum := 0.0
		var sp_amt := 0.0
		for d in POLICY:
			if d["kind"] == "spend":
				sp_sum += float(pol[d["key"]])
				sp_amt += amt(d["key"])
		spend_total_label.text = "Расходы по ползункам: %s млрд в год (%.1f%% ВВП), без процентов и программ законов" % [fmt_n(sp_amt), sp_sum]
		if council_on() and bool(junior_info()["junior"]):
			spend_total_label.text += "\nВы младший партнёр: план бюджета рассмотрит совет коалиции (влияние — по портфелям и местам)."


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
	# 0.56: подсказка к рейтингу — почему у партии такой потолок и предел сдвига
	var tp := "Откуда рейтинг: потолок партии и предел сдвига с прошлых выборов."
	var shown := 0
	for p in po:
		if shown >= 4 or ps[p] < 0.05:
			break
		shown += 1
		tp += "\n\n[b]%s[/b], сейчас %.1f%%\n%s" % [PARTY_NAMES[p], ps[p] * 100.0, er_tip(p)]
	polls_rt.tooltip_text = tp
	polls_rt.mouse_filter = Control.MOUSE_FILTER_PASS
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
	reg_ui_sync()
	es_ui_sync()
	if current_desk == 0:
		for k in sliders:
			update_slider_label(k)
		update_forecast()
		update_stats()
		update_auto_window()
		update_group_parties()
		update_bud_head()
		for fk in floor_btns:
			(floor_btns[fk] as Button).set_pressed_no_signal(floor_keys.has(fk))
		for g in GROUPS:
			set_bar(g, float(support[g]))
		set_bar("approval", approval())
		for d in LEVELS:
			set_bar(d["key"], float(lvl[d["key"]]))
		if meas_note_rt != null:
			var nready := 0
			for m in MEASURES:
				if meas_why(String(m["id"])) == "":
					nready += 1
			meas_note_rt.text = "[font_size=13]Можно провести сейчас: [b]%d[/b] из %d. В этом квартале проведено %d из %d.[/font_size]" % [nready, MEASURES.size(), meas_q_used(), MEAS_Q_LIMIT]
	elif current_desk == 1:
		for a in ACTIONS:
			var b: Button = action_rows[a["id"]]
			var cd: int = int(cooldown[a["id"]])
			var anm: String = loc(String(a["name"])) if a["id"] != "snap" else String(snap_info()["name"])
			var txt: String = "%s (капитал %.0f)" % [anm, a["cost"]]
			if cd > 0:
				txt += " — ещё %d мес." % cd
			b.text = txt
			b.disabled = cd > 0 or game_over or cap_spendable() < float(a["cost"]) or (a["id"] == "snap" and (turn - last_parl < 12 or not bool(snap_info()["ok"]) or opp_mode))
		update_parliament()
		update_polls()
		update_regime_windows()
		if selfcoup_btn != null and not rv.is_empty():
			var why := rv_selfcoup_check()
			selfcoup_btn.disabled = why != ""
			selfcoup_note.text = ("Сейчас нельзя: %s." % why) if why != "" else "Шанс успеха сейчас %.0f%%. Провал — арест или тяжёлое ослабление." % (rv_selfcoup_prob() * 100.0)
	elif current_desk == 3:
		update_law_windows()
	elif current_desk == 4:
		update_gov_windows()
	elif current_desk == 5:
		update_econ_windows()
		update_auto_window()
	elif current_desk == 7:
		update_goods_windows()
		update_goods_detail()
	elif current_desk == 18:
		update_io_windows()
	elif current_desk == 21:
		update_today()
	elif current_desk == 16:
		update_es_windows()
		update_goods_detail()
	elif current_desk == 17:
		update_corp_windows()
	elif current_desk == 6:
		update_pop_windows()
	elif current_desk == 8 or current_desk == 9:
		update_fed_windows()
	elif current_desk == 10 or current_desk == 11:
		update_soc_windows()
	elif current_desk == 19 or current_desk == 20:
		update_society_windows()
	elif current_desk == 12:
		update_opp_windows()
		update_regime_windows()
	elif current_desk == 13:
		update_war_windows()
	elif current_desk == 14:
		update_fleet_windows()
	elif current_desk == 15:
		update_army_windows()
	if current_desk == 2:
		update_dip_windows()
		update_build_window()
	update_regions_ui()
	update_tech_windows()
	update_meas_window()
	update_cn_window()
	update_crisis_windows()
	overlays_lock()
	update_realm_windows()
	update_win_locks()
	update_ui_extras()
	fmt_pass()


# v50: окна, которыми распоряжается только правительство (и те, где нужны места в парламенте), затемняются с объяснением
const WIN_GOV_ONLY := ["tax", "measures", "ec_st", "ec_cb", "ec_gf", "cabinet", "neg", "commit", "actions", "xw_info", "war_ops", "war_talk",
	"regact", "ar_budget", "ar_svc", "ar_proc", "ar_act", "dact", "fw_reg", "fw_bulk", "fw_dem", "tw_buy", "tw_union", "tw_sell",
	"tw_terr", "fw_navy", "sw_pol", "sw_mig", "rm_treaty", "rm_spy", "reg_tools", "reg_repr", "es_main", "co_card", "co_for", "io_act"]
const WIN_PARL_ONLY := ["bills"]


func update_win_locks() -> void:
	var gw := pl_why("gov")
	var pw := pl_why("parl")
	for id in WIN_GOV_ONLY:
		if wins.has(id):
			(wins[id] as FloatWindow).set_locked(gw)
	for id in WIN_PARL_ONLY:
		if wins.has(id):
			(wins[id] as FloatWindow).set_locked(pw)


# ---------- парламент ----------


func on_slider(v: float, key: String) -> void:
	if slider_busy:
		return
	var allowed := lock_allowed(key, v)
	if not is_equal_approx(allowed, v):
		(sliders[key]["slider"] as HSlider).set_value_no_signal(allowed)
		v = allowed
	var old_share: float = float(pol[key])
	var old_abs: float = float(pol_abs.get(key, -1.0)) if is_abs(key) else -1.0
	if is_abs(key):
		pol_abs[key] = v
		pol[key] = v / gdp * 100.0
	else:
		pol[key] = v
	if bud_draft_on():
		bud_mark(key, old_share, old_abs)
	# 0.55.5: пределов нет — дотянули ползунок до правого края, край отодвигается дальше
	var sl: HSlider = sliders[key]["slider"]
	if v >= sl.max_value - sl.step * 0.5 and key != "emit":
		sl.max_value = sl.max_value * 1.5
	update_slider_label(key)
	update_forecast()
	update_bud_head()


# 0.56: шаг кнопок ± — 0,1% ВВП, с Shift — 1% (в режиме «млрд» — та же сумма в млрд)
func nudge_step() -> float:
	return 1.0 if Input.is_key_pressed(KEY_SHIFT) else 0.1


func slider_nudge(key: String, dir: int) -> void:
	if not sliders.has(key):
		return
	var sl: HSlider = sliders[key]["slider"]
	var st: float = maxf(nudge_step() * (gdp / 100.0 if is_abs(key) else 1.0), sl.step)
	var v: float = maxf(0.0, slider_value_for(key) + dir * st)
	if key == "emit":
		v = minf(v, sl.max_value)
	elif v > sl.max_value:
		sl.max_value = v * 1.5
	sl.value = v
	slider_shrink(key)


# 0.56: край ползунка возвращается к обычному, когда ставка снова в обычном диапазоне
# (иначе после растяжения малейший сдвиг значил бы сотни процентов)
func slider_shrink(key: String) -> void:
	if not sliders.has(key) or key == "emit":
		return
	var sl: HSlider = sliders[key]["slider"]
	var hi: float = abs_range(key).y if is_abs(key) else slider_hi(key)
	if sl.max_value > hi + sl.step * 0.5:
		sl.max_value = hi


func slider_value_for(key: String) -> float:
	return float(pol_abs[key]) if is_abs(key) else float(pol[key])


# 0.55.5: пересчитать края ползунка, не трогая режим (после изменения ставки извне)
func configure_slider_range(key: String) -> void:
	var s: HSlider = sliders[key]["slider"]
	var hi: float = abs_range(key).y if is_abs(key) else slider_hi(key)
	if hi > s.max_value or key == "emit":
		s.max_value = hi
	s.min_value = 0.0


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
		s.min_value = 0.0
		s.max_value = slider_hi(key)
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
		pol[key] = clampf(float(pol[key]), 0.0, pol_hi(key))
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
		# v45_1: глубина (тень снизу) и мягкое свечение при наведении
		sdepth(th.get_stylebox("normal", t), Color(0, 0, 0, 0.32), 2, Vector2(0.0, 1.5))
		sdepth(th.get_stylebox("hover", t), Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.22), 6, Vector2.ZERO)
		sdepth(th.get_stylebox("pressed", t), Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.30), 4, Vector2.ZERO)
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
	sdepth(th.get_stylebox("normal", "AccentButton"), Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.30), 6, Vector2.ZERO)
	sdepth(th.get_stylebox("hover", "AccentButton"), Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.55), 10, Vector2.ZERO)
	th.set_font_size("font_size", "AccentButton", 16)
	# вкладки экранов
	th.set_type_variation("TabButton", "Button")
	th.set_stylebox("normal", "TabButton", sbox(C_PANEL2, C_BORDER, 1, 8, 8.0, 6.0))
	th.set_stylebox("hover", "TabButton", sbox(C_PANEL2.lightened(0.12), C_ACCENT.darkened(0.2), 1, 8, 8.0, 6.0))
	var tab_on := sbox(C_ACCENT.darkened(0.30), C_ACCENT, 1, 8, 8.0, 6.0)
	tab_on.border_width_bottom = 3
	sdepth(tab_on, Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.28), 7, Vector2.ZERO)
	sdepth(th.get_stylebox("normal", "TabButton"), Color(0, 0, 0, 0.30), 2, Vector2(0.0, 1.5))
	sdepth(th.get_stylebox("hover", "TabButton"), Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.18), 5, Vector2.ZERO)
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
	var pmb := sbox(C_PANEL2, C_ACCENT.darkened(0.3), 1, 7, 6.0, 6.0)
	sdepth(pmb, Color(0, 0, 0, 0.45), 10, Vector2(0.0, 3.0))
	th.set_stylebox("panel", "PopupMenu", pmb)
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
	# 0.56: подсказка в цветах интерфейса — фон панели, цветная полоса слева (содержимое рисует tip_on_added)
	var tip := sbox(C_PANEL, C_BORDER, 1, 8, 14.0, 10.0)
	tip.border_width_left = 4
	tip.border_color = C_BORDER
	tip.border_blend = false
	tip.content_margin_left = 16.0
	sdepth(tip, Color(0, 0, 0, 0.45), 10, Vector2(0.0, 3.0))
	th.set_stylebox("panel", "TooltipPanel", tip)
	th.set_color("font_color", "TooltipLabel", C_TEXT)
	th.set_font_size("font_size", "TooltipLabel", 14)
	var line := StyleBoxLine.new()
	line.color = C_BORDER
	line.thickness = 1
	th.set_stylebox("separator", "HSeparator", line)
	th.set_constant("separation", "HSeparator", 8)
	return th


# ============================================================
#  0.56: общий построитель подсказок. Все подсказки игры (tooltip_text) перехватываются при показе:
#  вместо простой строки — заголовок, разделы с подзаголовками, числа таблицей (плюс зелёным, минус красным).
#  Текст подсказки остаётся обычной строкой, оформление выводится из её вида:
#    первая строка (короткая) — заголовок; строка «Раздел:» — подзаголовок; «название: +число» — строка таблицы;
#    «Сейчас нельзя: …» / «Сейчас недоступно: …» — предупреждение. tip_make() собирает такую строку из частей.
#  Размер шрифта и задержка — в настройках (Графика → «Подсказки»).
# ============================================================
const TIP_SIZES := [13, 15, 17]
const TIP_WIDTHS := [400.0, 460.0, 540.0]
const TIP_DELAYS := [0.1, 0.5, 1.0]      # project.godot: gui/timers/tooltip_delay_sec = 0.1, остальное добирает tip_on_added
const TIP_WARN_HEADS := ["Внимание:", "Сейчас нельзя:", "Сейчас недоступно:", "Пока нельзя:", "Недоступно:", "Нельзя:"]

const TIP_BAD_UP := ["долг", "инфляц", "безработ", "коррупц", "дефицит", "недовольств", "цены", "цена ", "сепаратизм", "risk", "риск"]
var tip_re_num: RegEx = null
var tip_re_row: RegEx = null


func tip_setup() -> void:
	if not get_tree().node_added.is_connected(tip_on_added):
		get_tree().node_added.connect(tip_on_added)


# собрать текст подсказки: заголовок + разделы [подзаголовок, строки [[название, значение], …] или текст]
func tip_make(title: String, secs: Array = []) -> String:
	var out: PackedStringArray = [title]
	for sec in secs:
		var head: String = String(sec[0]) if sec.size() > 0 else ""
		if head != "":
			out.append(head + ":")
		var body: Variant = sec[1] if sec.size() > 1 else ""
		if body is Array:
			for r in body:
				out.append("%s: %s" % [String(r[0]), String(r[1])])
		elif String(body) != "":
			out.append(String(body))
	return "\n".join(out)


func tip_num_text(v: float, dec: int = 1, unit: String = "") -> String:
	return sg(v, dec) + unit


func tip_color_nums(t: String) -> String:
	if tip_re_num == null:
		tip_re_num = RegEx.new()
		tip_re_num.compile("(?m)(^|[\\s(«/])([+−-])(\\d+(?:[.,]\\d+)?(?:\\s?%| п\\.п\\.| млрд)?)")
	var out := ""
	var pos := 0
	for m in tip_re_num.search_all(t):
		var up: bool = m.get_string(2) == "+"
		# рост долга, инфляции, безработицы, коррупции — плохо: цвета наоборот
		var before: String = t.substr(maxi(0, m.get_start(2) - 28), mini(28, m.get_start(2))).to_lower()
		for sep in [",", ";", "\n", "·", "(", "."]:
			var si: int = before.rfind(sep)
			if si >= 0 and si < before.length() - 1:
				before = before.substr(si + 1)
		for bw in TIP_BAD_UP:
			if before.contains(bw):
				up = not up
				break
		var col: String = COL_GOOD if up else COL_BAD
		out += t.substr(pos, m.get_start(2) - pos) + "[color=%s]%s%s[/color]" % [col, m.get_string(2), m.get_string(3)]
		pos = m.get_end(3)
	return out + t.substr(pos)


func tip_is_row(line: String) -> PackedStringArray:
	# «название: значение», где значение короткое и начинается с числа или знака
	if tip_re_row == null:
		tip_re_row = RegEx.new()
		tip_re_row.compile("^(.{1,60}?):\\s+([+−\\-×≈~]?\\s?\\d[^\\n]{0,22})$")
	var m := tip_re_row.search(line)
	if m == null:
		return PackedStringArray()
	return PackedStringArray([m.get_string(1), m.get_string(2)])


func tip_bbcode(src: String, fs: int) -> String:
	var lines: PackedStringArray = src.replace("\r", "").split("\n")
	var out := ""
	var i0 := 0
	if lines.size() > 1 and lines[0].length() <= 70 and lines[0].strip_edges() != "":
		out += "[font_size=%d][b]%s[/b][/font_size]\n" % [fs + 2, lines[0].strip_edges().replace("[", "[lb]")]
		i0 = 1
	var rows: Array = []
	var flush := func() -> String:
		if rows.is_empty():
			return ""
		var t := "[table=2]"
		for r in rows:
			t += "[cell padding=0,1,14,1]%s[/cell][cell padding=0,1,0,1][right]%s[/right][/cell]" % [String(r[0]), tip_color_nums(" " + String(r[1])).substr(1) if String(r[1]).begins_with("+") or String(r[1]).begins_with("−") or String(r[1]).begins_with("-") else String(r[1])]
		rows.clear()
		return t + "[/table]\n"
	for i in range(i0, lines.size()):
		var ln: String = lines[i].strip_edges(false, true)
		var esc: String = ln.replace("[", "[lb]")
		var row := tip_is_row(esc.strip_edges())
		if row.size() == 2:
			rows.append(row)
			continue
		out += flush.call()
		if ln.strip_edges() == "":
			out += "[font_size=6] [/font_size]\n"
			continue
		var warn := false
		for wh in TIP_WARN_HEADS:
			if ln.strip_edges().begins_with(wh) or ln.contains("\n" + wh):
				warn = true
		if warn:
			out += "[color=%s]%s[/color]\n" % [COL_WARN, esc]
		elif ln.ends_with(":") and ln.length() <= 48:
			out += "[font_size=%d][color=%s]%s[/color][/font_size]\n" % [fs - 1, COL_DIM, esc.trim_suffix(":").to_upper()]
		else:
			out += tip_color_nums(esc) + "\n"
	out += flush.call()
	return out.trim_suffix("\n")


func tip_on_added(n: Node) -> void:
	if not (n is Label) or not (n.get_parent() is PopupPanel):
		return
	if n.get_class() != "TooltipLabel" and (n.get_parent() as PopupPanel).theme_type_variation != "TooltipPanel":
		return
	var lb := n as Label
	var src: String = lb.text
	if src.strip_edges() == "":
		return
	var szi: int = clampi(int(game_opts.get("tip_size", 1)), 0, TIP_SIZES.size() - 1)
	var fs: int = TIP_SIZES[szi]
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rt.add_theme_font_size_override("normal_font_size", fs)
	rt.add_theme_font_size_override("bold_font_size", fs)
	rt.add_theme_color_override("default_color", C_TEXT)
	rt.add_theme_constant_override("line_separation", 2)
	# ширина: короткие подсказки — по тексту, длинные переносятся по словам
	var font: Font = rt.get_theme_font("normal_font")
	var longest := 0.0
	for ln in src.split("\n"):
		longest = maxf(longest, font.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	var w: float = clampf(longest + 24.0, 120.0, TIP_WIDTHS[szi])
	rt.custom_minimum_size = Vector2(w, 0.0)
	rt.text = tip_bbcode(src, fs)
	lb.text = ""
	lb.add_child(rt)
	lb.custom_minimum_size = Vector2(w, rt.get_content_height() + 2.0)
	# цветная полоса слева — цвет раздела, из которого открыта подсказка
	var pan := lb.get_parent() as PopupPanel
	var sb: StyleBox = pan.get_theme_stylebox("panel")
	if sb is StyleBoxFlat:
		var sf := (sb as StyleBoxFlat).duplicate() as StyleBoxFlat
		sf.border_color = accent_for_desk(current_desk)
		sf.border_width_top = 0
		sf.border_width_right = 0
		sf.border_width_bottom = 0
		pan.add_theme_stylebox_override("panel", sf)
	var extra: float = float(TIP_DELAYS[clampi(int(game_opts.get("tip_delay", 1)), 0, TIP_DELAYS.size() - 1)]) - TIP_DELAYS[0]
	if extra > 0.01:
		pan.call_deferred("hide")
		# метод с id, а не лямбда: подсказка может исчезнуть раньше таймера
		get_tree().create_timer(extra).timeout.connect(tip_show_later.bind(pan.get_instance_id()))


func tip_show_later(id: int) -> void:
	var pan := instance_from_id(id) as PopupPanel
	if pan != null and pan.is_inside_tree():
		pan.show()


# ============================================================
#  0.56: ЖУРНАЛ «РАМКИ В РАМКЕ»
#  Сообщения месяца собраны в общую рамку с заголовком месяца, каждое сообщение — карточка
#  с меткой, датой и цифрами (плюс зелёным, минус красным). Важные (выборы, кризисы, война,
#  отставка, коалиция, вступление в ЕС/НАТО) крупнее и ярче. Открыты последние 3 месяца и текущий.
# ============================================================
const LOG_KEEP_OPEN := 3
const LOG_BIG_TAGS := ["ВОЙНА", "КРИЗИС", "ВОЕННОЕ ПОЛОЖЕНИЕ", "ВЛАСТЬ", "ГОСУДАРСТВО", "СКАНДАЛ"]
const LOG_QUIET_TAGS := ["МИР", "НАУКА", "АВТОПИЛОТ", "СОХРАНЕНИЕ", "РЕМОНТ", "ПРОЕКТ", "НАБЛЮДАТЕЛЬ", "ТОРГОВЛЯ"]
const LOG_BIG_WORDS := ["итоги выборов", "результаты выборов", "досрочные выборы", "победил на выборах", "бунт", "восстан", "мятеж",
	"объявил войну", "объявила войну", "начало войны", "перемири", "мирный договор", "капитуляц", "отставк", "недовери", "вотум",
	"коалиция распалась", "распад коалиц", "новое правительство", "правительство сформировано", "коалиция сформирована",
	"переворот", "революц", "импичмент", "новая конституция", "референдум"]


func log_is_big(e: Dictionary) -> bool:
	var k: String = String(e.get("k", ""))
	if k == "head":
		return true
	if k != "line":
		return false
	var tag: String = String(e.get("tag", ""))
	if tag in LOG_BIG_TAGS:
		return true
	if tag in LOG_QUIET_TAGS:
		return false
	var low: String = String(e.get("t", "")).to_lower()
	for w in LOG_BIG_WORDS:
		if low.contains(w):
			return true
	if (low.contains("вступ") or low.contains("принят")) and (low.contains("нато") or low.contains("евросоюз") or low.contains(" ес")):
		return true
	return false


func log_groups() -> Array:
	var gs: Array = []
	var cur: Array = []
	for e in log_entries:
		var k: String = String(e["k"])
		if k == "year" and cur.is_empty() and not gs.is_empty():
			(gs.back()["es"] as Array).append(e)
			continue
		cur.append(e)
		if k == "month":
			gs.append({"title": String(e["date"]), "es": cur, "closed": true})
			cur = []
	gs.append({"title": "", "es": cur, "closed": false})
	return gs


func log_ui_rebuild(to_end: bool) -> void:
	if log_box == null:
		return
	for c in log_box.get_children():
		log_box.remove_child(c)
		c.queue_free()
	log_ui_gs.clear()
	var gs := log_groups()
	var last_closed: int = gs.size() - 2
	for i in gs.size():
		var src: Dictionary = gs[i]
		var closed: bool = src["closed"]
		var key: String = String(src["title"]) if closed else "@cur"
		var def_open: bool = (not closed) or i > last_closed - LOG_KEEP_OPEN
		var g := log_ui_new_group(key, String(src["title"]), closed, bool(log_open.get(key, def_open)))
		for e in src["es"]:
			log_ui_put(g, e)
		log_ui_head(g)
	if to_end:
		log_ui_scroll_end(true)


func log_ui_new_group(key: String, title: String, closed: bool, open: bool) -> Dictionary:
	var fr := PanelContainer.new()
	fr.add_theme_stylebox_override("panel", sbox(C_BG.lerp(C_PANEL, 0.55), C_BORDER, 1, 8, 8.0, 6.0))
	fr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_box.add_child(fr)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	fr.add_child(vb)
	var head := Button.new()
	head.flat = true
	head.alignment = HORIZONTAL_ALIGNMENT_LEFT
	head.focus_mode = Control.FOCUS_NONE
	head.add_theme_font_size_override("font_size", 14)
	head.tooltip_text = "Свернуть или развернуть месяц"
	vb.add_child(head)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 5)
	vb.add_child(body)
	var g := {"key": key, "title": title, "closed": closed, "fr": fr, "head": head, "body": body, "es": [], "n": 0, "nbig": 0, "open": open, "last": null}
	head.pressed.connect(func() -> void: log_ui_toggle(g))
	log_ui_gs.append(g)
	return g


func log_ui_put(g: Dictionary, e: Dictionary) -> void:
	(g["es"] as Array).append(e)
	if not log_match(e):
		return
	if String(e["k"]) != "note":
		g["n"] = int(g["n"]) + 1
		if log_is_big(e):
			g["nbig"] = int(g["nbig"]) + 1
	if bool(g["open"]):
		log_ui_card(g, e)


func log_ui_head(g: Dictionary) -> void:
	var b := g["head"] as Button
	var t: String = String(g["title"]) if bool(g["closed"]) else "Текущий месяц · %s" % date_text()
	t = ("▾ " if bool(g["open"]) else "▸ ") + t
	if int(g["n"]) > 0:
		t += "  ·  %d" % int(g["n"])
	if int(g["nbig"]) > 0:
		t += "  ·  ★ %d" % int(g["nbig"])
	b.text = t
	b.add_theme_color_override("font_color", C_TEXT if bool(g["open"]) else Color(COL_DIM))
	(g["body"] as Control).visible = bool(g["open"])


func log_ui_toggle(g: Dictionary) -> void:
	g["open"] = not bool(g["open"])
	log_open[String(g["key"])] = g["open"]
	var body := g["body"] as VBoxContainer
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	g["last"] = null
	if bool(g["open"]):
		for e in g["es"]:
			if log_match(e):
				log_ui_card(g, e)
	log_ui_head(g)


func log_ui_add(e: Dictionary) -> void:
	if log_ui_gs.is_empty():
		log_ui_rebuild(true)
		return
	var g: Dictionary = log_ui_gs.back()
	if String(e["k"]) == "year" and (g["es"] as Array).is_empty() and log_ui_gs.size() > 1:
		g = log_ui_gs[log_ui_gs.size() - 2]
	log_ui_put(g, e)
	if String(e["k"]) == "month":
		# месяц закрыт: рамка получает заголовок, начинается новая; старые месяцы сворачиваются
		g["closed"] = true
		g["title"] = String(e["date"])
		g["key"] = String(e["date"])
		log_ui_head(g)
		var ng := log_ui_new_group("@cur", "", false, true)
		log_ui_head(ng)
		var old_i: int = log_ui_gs.size() - 2 - LOG_KEEP_OPEN
		if old_i >= 0:
			var og: Dictionary = log_ui_gs[old_i]
			if bool(og["open"]) and not log_open.has(String(og["key"])):
				og["open"] = true
				log_ui_toggle(og)
				log_open.erase(String(og["key"]))
	else:
		log_ui_head(g)
	log_ui_scroll_end(false)


# 0.59 (п.10): запись журнала — короткая строка «суть + цифра»; подробности (полный текст, кнопки) открываются под строкой
const LOG_ACT := {"ЗАКОН": ["Открыть законы", 3], "ЗАКОНОПРОЕКТ": ["Открыть законопроекты", -3], "БЮДЖЕТ": ["Открыть бюджет", 0], "КОАЛИЦИЯ": ["Открыть коалицию", 4],
	"ПЕРЕГОВОРЫ": ["Открыть коалицию", 4], "ОППОЗИЦИЯ": ["Открыть оппозицию", 12], "КРИЗИС": ["Открыть кризисы", -99], "МИНИСТР": ["Открыть кабинет", 4],
	"ТЕХНОЛОГИИ": ["Открыть технологии", -98], "НАУКА": ["Открыть технологии", -98]}


func log_plain(t: String) -> String:
	var rx := RegEx.new()
	rx.compile("\\[[^\\]]*\\]")
	return rx.sub(t, "", true).strip_edges()


func log_headline(t: String) -> String:
	var p := log_plain(t)
	var cut := p.length()
	for sep in [". ", ": ", "; ", " — "]:
		var k := p.find(sep, 12)
		if k > 0:
			cut = mini(cut, k)
	p = p.substr(0, cut)
	var ws := p.split(" ", false)
	if ws.size() > 8:
		return " ".join(ws.slice(0, 8)) + "…"
	return p


func log_main_num(t: String) -> String:
	var rx := RegEx.new()
	rx.compile("([+\\-−]?\\d[\\d  .,]*\\s?(?:%|млрд|млн|мест[а-я]*|голос[а-я]*|п\\.п\\.|мес\\.))")
	var m := rx.search(log_plain(t))
	return m.get_string(1).strip_edges() if m != null else ""


func log_who(t: String) -> String:
	for p in PARTY_NAMES.size():
		if String(PARTY_NAMES[p]) != "" and t.contains(String(PARTY_NAMES[p])):
			return "[color=#%s]■[/color] %s" % [(PARTY_COLORS[p] as Color).lightened(0.2).to_html(false), party_abbr(p)]
	return ""


func log_do_act(code: int) -> void:
	if code == -3:
		goto_win("bills")
	elif code == -99:
		set_crisis_open(true)
	elif code == -98:
		set_tech_open(true)
	else:
		show_desk(code)


func log_ui_line_card(g: Dictionary, e: Dictionary) -> void:
	var body := g["body"] as VBoxContainer
	var big := log_is_big(e)
	var cat: String = String(e.get("cat", "ev"))
	var col := Color(String(LOG_CAT_COL.get(cat, "#8a93aa")))
	var label: String = String(LOG_CAT_NAME.get(cat, ""))
	var tag := ""
	if e.has("tag"):
		col = Color(String(e["col"]))
		tag = String(e["tag"])
		label = tag
	var full: String = String(e["t"])
	var pc := PanelContainer.new()
	var sb := sbox(C_PANEL2.lerp(col, 0.16 if big else 0.0), col if big else col.darkened(0.15), 1 if big else 0, 6, 10.0, 5.0)
	sb.border_width_left = 4 if big else 3
	sb.content_margin_left = 12.0
	pc.add_theme_stylebox_override("panel", sb)
	pc.mouse_filter = Control.MOUSE_FILTER_STOP
	pc.tooltip_text = "Нажмите, чтобы раскрыть подробности"
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	pc.add_child(vb)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	vb.add_child(top)
	var who := log_who(full)
	var trt := RichTextLabel.new()
	trt.bbcode_enabled = true
	trt.fit_content = true
	trt.scroll_active = false
	trt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trt.text = "[font_size=11][b][color=#%s]%s[/color][/b]  [color=%s]%s[/color]%s[/font_size]" % [col.lightened(0.15).to_html(false), label, COL_DIM, String(e.get("d", "")), ("  " + who) if who != "" else ""]
	top.add_child(trt)
	var num := log_main_num(full)
	var nl := Label.new()
	nl.text = num
	nl.add_theme_font_size_override("font_size", 14)
	nl.add_theme_color_override("font_color", col.lightened(0.3))
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(nl)
	var hrt := RichTextLabel.new()
	hrt.bbcode_enabled = true
	hrt.fit_content = true
	hrt.scroll_active = false
	hrt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hrt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hrt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hrt.add_theme_font_size_override("normal_font_size", 15 if big else 14)
	hrt.add_theme_font_size_override("bold_font_size", 15 if big else 14)
	var base := ("[b]★ %s[/b]" if big else "%s") % log_headline(full)
	hrt.text = base
	hrt.set_meta("uid", int(e.get("uid", -1)))
	hrt.set_meta("base", base)
	vb.add_child(hrt)
	var det := VBoxContainer.new()
	det.add_theme_constant_override("separation", 4)
	det.visible = false
	vb.add_child(det)
	var drt := RichTextLabel.new()
	drt.bbcode_enabled = true
	drt.fit_content = true
	drt.scroll_active = false
	drt.selection_enabled = true
	drt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	drt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drt.add_theme_font_size_override("normal_font_size", 13)
	drt.add_theme_font_size_override("bold_font_size", 13)
	drt.text = tip_color_nums(full)
	det.add_child(drt)
	var btns := HFlowContainer.new()
	btns.add_theme_constant_override("h_separation", 6)
	det.add_child(btns)
	if LOG_ACT.has(tag):
		var ab := Button.new()
		ab.theme_type_variation = "SmallButton"
		ab.focus_mode = Control.FOCUS_NONE
		ab.text = String(LOG_ACT[tag][0])
		var code: int = int(LOG_ACT[tag][1])
		ab.pressed.connect(func() -> void: log_do_act(code))
		btns.add_child(ab)
	var vi := log_vote_of(e)
	if vi >= 0:
		var vbn := Button.new()
		vbn.theme_type_variation = "SmallButton"
		vbn.focus_mode = Control.FOCUS_NONE
		vbn.text = "Показать голосование"
		vbn.pressed.connect(func() -> void: vote_reopen(vi))
		btns.add_child(vbn)
	btns.visible = btns.get_child_count() > 0
	pc.gui_input.connect(func(ev: InputEvent) -> void:
		var mb := ev as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			det.visible = not det.visible
			pc.tooltip_text = "Нажмите, чтобы свернуть" if det.visible else "Нажмите, чтобы раскрыть подробности")
	body.add_child(pc)
	g["last"] = drt
	g["last_head"] = hrt


# какое голосование относится к записи журнала (-1 — никакое)
func log_vote_of(e: Dictionary) -> int:
	var u: int = int(e.get("uid", -1))
	var low: String = String(e.get("t", "")).to_lower()
	var tag: String = String(e.get("tag", ""))
	if not (tag in ["ЗАКОН", "БЮДЖЕТ", "ЗАКОНОПРОЕКТ"] or low.contains("недовер") or low.contains("референдум") or low.contains("голосовани")):
		return -1
	for i in range(vote_hist.size() - 1, -1, -1):
		var d: int = u - int((vote_hist[i] as Dictionary).get("uid0", -9))
		if d == 0 or d == 1:
			return i
	return -1


func log_ui_card(g: Dictionary, e: Dictionary) -> void:
	var k: String = String(e["k"])
	var body := g["body"] as VBoxContainer
	var last: Variant = g["last"]
	if k == "line" and not bool(game_opts.get("log_old", false)):
		log_ui_line_card(g, e)
		return
	if k == "note":
		if last != null and is_instance_valid(last):
			(last as RichTextLabel).append_text("\n[font_size=13][color=%s]%s[/color][/font_size]" % [COL_DIM, tip_color_nums(String(e["t"]))])
			return
	var big := log_is_big(e)
	var cat: String = String(e.get("cat", "ev"))
	var col := Color(String(LOG_CAT_COL.get(cat, "#8a93aa")))
	var label: String = String(LOG_CAT_NAME.get(cat, ""))
	var txt := ""
	match k:
		"head":
			col = Color(String(e["col"]))
			label = ""
			txt = "[font_size=17][b][color=%s]%s[/color][/b][/font_size]" % [String(e["col"]), String(e["t"])]
		"line":
			if e.has("tag"):
				col = Color(String(e["col"]))
				label = String(e["tag"])
			txt = tip_color_nums(String(e["t"]))
			if big:
				txt = "[font_size=16][b]%s[/b][/font_size]" % txt
		"note":
			txt = "[color=%s]%s[/color]" % [COL_DIM, tip_color_nums(String(e["t"]))]
		"month":
			col = Color("#7fb0ff")
			label = "ИТОГИ МЕСЯЦА"
			txt = log_render_month(e).strip_edges()
			txt = txt.substr(txt.find("[table=4]"))
		"year":
			col = Color("#ffd166")
			label = "ИТОГИ %d ГОДА" % int(e["year"])
			txt = log_render_year(e).strip_edges()
			txt = txt.substr(txt.find("[table=4]"))
	var pc := PanelContainer.new()
	var sb := sbox(C_PANEL2.lerp(col, 0.16 if big else 0.0), col if big else col.darkened(0.15), 1 if big else 0, 6, 10.0, 6.0)
	sb.border_width_left = 4 if big else 3
	sb.content_margin_left = 12.0
	pc.add_theme_stylebox_override("panel", sb)
	pc.mouse_filter = Control.MOUSE_FILTER_PASS
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.selection_enabled = true
	rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rt.mouse_filter = Control.MOUSE_FILTER_PASS
	rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rt.add_theme_font_size_override("normal_font_size", 14)
	rt.add_theme_font_size_override("bold_font_size", 14)
	rt.add_theme_constant_override("line_separation", 2)
	var top := ""
	if label != "":
		top = "[font_size=11][b][color=#%s]%s[/color][/b][/font_size]" % [col.lightened(0.15).to_html(false), label]
	if k != "month" and k != "year":
		top += ("  " if top != "" else "") + "[font_size=11][color=%s]%s[/color][/font_size]" % [COL_DIM, String(e.get("d", ""))]
	rt.text = (top + "\n" if top != "" else "") + txt
	if int(e.get("n", 1)) > 1:
		rt.text += "  [color=%s]× %d[/color]" % [COL_DIM, int(e["n"])]
	rt.set_meta("uid", int(e.get("uid", -1)))
	rt.set_meta("base", (top + "\n" if top != "" else "") + txt)
	pc.add_child(rt)
	body.add_child(pc)
	g["last"] = rt


# запись повторилась: у последней карточки появляется «× N»
func log_ui_bump(e: Dictionary) -> void:
	if log_ui_gs.is_empty():
		return
	var gl: Dictionary = log_ui_gs.back()
	var rt: Variant = gl.get("last_head", null)
	if rt == null or not is_instance_valid(rt):
		rt = gl["last"]
	if rt != null and is_instance_valid(rt) and int((rt as RichTextLabel).get_meta("uid", -2)) == int(e.get("uid", -1)):
		(rt as RichTextLabel).text = String((rt as RichTextLabel).get_meta("base")) + "  [color=%s]× %d[/color]" % [COL_DIM, int(e["n"])]


func log_ui_scroll_end(force: bool) -> void:
	if log_scroll == null or not log_scroll.is_inside_tree():
		return
	var vb := log_scroll.get_v_scroll_bar()
	if not force and vb.value < vb.max_value - vb.page - 80.0:
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(log_scroll):
		log_scroll.scroll_vertical = int(vb.max_value)


func sdepth(sb: StyleBox, col: Color, sz: int, off: Vector2) -> void:
	# v45_1: тень/свечение у плоского стиля
	if sb is StyleBoxFlat:
		var f := sb as StyleBoxFlat
		f.shadow_color = col
		f.shadow_size = sz
		f.shadow_offset = off
		f.anti_aliasing = true


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
		if ch is BaseButton and not (ch as Node).has_meta("hov"):
			# v49: мягкая подсветка кнопки при наведении (плавно, без рывка)
			var bb := ch as BaseButton
			bb.set_meta("hov", true)
			bb.mouse_entered.connect(func() -> void:
				if not bb.disabled:
					bb.create_tween().tween_property(bb, "self_modulate", Color(1.16, 1.18, 1.25), 0.12))
			bb.mouse_exited.connect(func() -> void:
				bb.create_tween().tween_property(bb, "self_modulate", Color.WHITE, 0.25))
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
	chips[key] = {"value": v, "delta": d, "pc": pc}
	# v49: значок в правом верхнем углу плашки (только если есть место рядом с подписью — ширина панели не меняется)
	var ik: String = String({"date": "calendar", "appr": "person", "gdp": "chart", "infl": "percent", "unemp": "work", "debt": "bank", "cap": "star", "coal": "hall", "elec": "ballot"}.get(key, ""))
	if ik != "":
		pc.draw.connect(func() -> void:
			var cw: float = cap.get_theme_default_font().get_string_size(cap.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			var free: float = pc.size.x - 10.0 - cw
			if free >= 15.0:
				var u: float = 11.0
				Ico.draw_icon(ik, Vector2(pc.size.x - u - 5.0, 4.0), u, 1.3, Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.75), pc))


func set_chip(key: String, text: String, col: Color, delta_text: String = "", dcol: Color = Color(0.6, 0.63, 0.72)) -> void:
	var d: Dictionary = chips[key]
	var v: Label = d["value"]
	v.text = text
	v.add_theme_color_override("font_color", col)
	var dl: Label = d["delta"]
	dl.text = delta_text
	dl.visible = delta_text != ""
	dl.add_theme_color_override("font_color", dcol)


# v49: число на плашке плавно «докручивается» до нового значения, а плашка коротко вспыхивает
func set_chip_num(key: String, val: float, fmt: Callable, col: Color, delta_text: String = "", dcol: Color = Color(0.6, 0.63, 0.72)) -> void:
	var d: Dictionary = chips[key]
	var v: Label = d["value"]
	var old: Variant = d.get("num", null)
	d["num"] = val
	set_chip(key, fmt.call(val), col, delta_text, dcol)
	if old == null or not v.is_visible_in_tree() or fmt.call(float(old)) == fmt.call(val):
		return
	var tw0: Variant = d.get("tw", null)
	if tw0 != null and (tw0 as Tween).is_valid():
		(tw0 as Tween).kill()
	var tw: Tween = v.create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(x: float) -> void: v.text = fmt.call(x), float(old), val, 0.45)
	d["tw"] = tw
	# вспышка — только при заметном изменении (ежедневные мелочи не мигают)
	if absf(float(old) - val) >= 0.02 * maxf(absf(val), 1.0):
		var pc: Control = d["pc"]
		pc.modulate = Color(1.35, 1.35, 1.25)
		pc.create_tween().tween_property(pc, "modulate", Color.WHITE, 0.6)


func update_chips() -> void:
	if chips.is_empty():
		return
	flag_top_refresh()
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
	var wkc: Control = chips["date"]["week"]
	wkc.call("set_day", weekday())
	(chips["date"]["pc"] as Control).tooltip_text = "%s, %d %s %d. Неделя %d из 4 в этом месяце. Календарь идёт по дням, а экономика, политика и мир считаются каждую неделю." % [WEEKDAYS[weekday()], day, MONTHS_GEN[month - 1], year, week_of_month()]
	set_chip_num("appr", ap, func(x: float) -> String: return "%.0f%%" % x, scale_color(ap / 100.0), arrow_text(dap, 1), delta_col(dap, true))
	set_chip_num("gdp", gdp, func(x: float) -> String: return fmt_n(x), C_TEXT, "%s%.1f%%" % ["+" if growth >= 0.0 else "", growth], C_GOOD if growth >= 2.0 else (C_WARN if growth >= 0.0 else C_BAD))
	set_chip_num("infl", inflation, func(x: float) -> String: return "%.1f%%" % x, scale_color(1.0 - inflation / 12.0), arrow_text(dinfl, 2), delta_col(dinfl, false))
	set_chip_num("unemp", unemployment, func(x: float) -> String: return "%.1f%%" % x, scale_color(1.0 - unemployment / 14.0), arrow_text(dun, 2), delta_col(dun, false))
	set_chip_num("debt", dr, func(x: float) -> String: return "%.0f%%" % x, scale_color(1.0 - dr / 110.0), arrow_text(ddebt, 1), delta_col(ddebt, false))
	var cr: float = cap_rate()
	(chips["cap"]["pc"] as Control).tooltip_text = cap_tip()
	set_chip_num("cap", capital, func(x: float) -> String: return "%.1f" % x, C_BAD if capital < 0.0 else (C_WARN if capital < 15.0 else C_TEXT), "%s%.1f/мес" % ["+" if cr >= 0.0 else "", cr], C_GOOD if cr >= 0.7 else C_DIM)
	set_chip("coal", "%d/%d" % [gs, SEATS], C_GOOD if gov_ok() else C_BAD, "кризис" if not gov_ok() else "", C_BAD)
	var el_d: int = days_until_months(parl_in)
	set_chip("elec", ("%d дн." % el_d) if el_d < 90 else months_short(parl_in), C_TEXT)
	(chips["elec"]["value"] as Label).tooltip_text = loc("Выборы в Бундестаг через %s (%d дн.)" % [months_text(parl_in), el_d])
	update_chips_extra()


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
		# v50: пока бюджет не принят — сплошным цветом действующий, а разница с планом: доходы прозрачно, расходы штриховкой
		var cur_t: float = (viz_rev0_t if String(row[0]) == "Доходы" else viz_exp0_t) if bud_pending() else rowtot
		var cur_w: float = w * cur_t / mx
		for seg in segs:
			var sw: float = total_w * float(seg[1]) / maxf(rowtot, 0.001)
			if sw > 0.4:
				var x0: float = x
				var x1: float = x + maxf(sw - 1.0, 0.5)
				var sc: Color = seg[2]
				if x0 < lw + cur_w:
					c.draw_rect(Rect2(x0, y, minf(x1, lw + cur_w) - x0, 17.0), sc)
				if x1 > lw + cur_w:
					var xa: float = maxf(x0, lw + cur_w)
					c.draw_rect(Rect2(xa, y, x1 - xa, 17.0), Color(sc.r, sc.g, sc.b, 0.35))
					if String(row[0]) != "Доходы":
						var hx: float = xa - 17.0
						while hx < x1:
							var p0 := Vector2(maxf(hx, xa), y + 17.0 - (maxf(hx, xa) - hx))
							var p1 := Vector2(minf(hx + 17.0, x1), y + 17.0 - (minf(hx + 17.0, x1) - hx))
							c.draw_line(p0, p1, Color(sc.r, sc.g, sc.b, 0.95), 1.5)
							hx += 5.0
			x += sw
		if bud_pending() and cur_w > total_w + 0.5:
			# план меньше действующего: срезаемая часть — пунктирная рамка
			c.draw_rect(Rect2(lw + total_w, y, cur_w - total_w, 17.0), Color(0.93, 0.42, 0.42, 0.18))
			c.draw_rect(Rect2(lw + total_w, y, cur_w - total_w, 17.0), Color(0.93, 0.42, 0.42, 0.7), false, 1.0)
		y += 24.0
	var bal := tr - te
	var txt := "%s%.1f млрд в год" % ["профицит +" if bal >= 0.0 else "дефицит ", absf(bal)]
	if bud_pending():
		txt = "план: " + txt + " (сейчас %s%.1f)" % ["+" if viz_rev0_t - viz_exp0_t >= 0.0 else "−", absf(viz_rev0_t - viz_exp0_t)]
	c.draw_string(font, Vector2(lw, y + 10.0), txt, HORIZONTAL_ALIGNMENT_LEFT, w, 12, C_GOOD if bal >= 0.0 else C_BAD)


func on_log_detail(on: bool) -> void:
	log_detail = on


# v50: «Технологии» и «Кризисы» ведут себя как остальные разделы: открытие снимает подсветку с вкладки раздела,
# а нажатие на любую вкладку раздела закрывает их
func overlay_tabs_sync() -> void:
	var ov_on: bool = tech_is_open() or crisis_is_open() or meas_is_open() or cn_is_open()
	var tab: int = desk_tab(current_desk)
	for kb in desk_buttons.size():
		(desk_buttons[kb] as Button).set_pressed_no_signal(kb == tab and not ov_on)


func show_tab(t: int) -> void:
	if tech_is_open():
		set_tech_open(false)
	if crisis_is_open():
		set_crisis_open(false)
	if meas_is_open():
		set_meas_open(false)
	if cn_is_open():
		cn_close()
	if politics_page == 11:
		politics_page = 1
	show_desk(0 if t == 0 else (econ_page if t == 1 else (politics_page if t == 2 else (18 if t == 4 else (21 if t == 6 else (society_page if t == 5 else map_page))))))


func update_subbar(i: int) -> void:
	if subbar == null:
		return
	var on: bool = i == 1 or i == 3 or i == 4 or i == 6 or i == 12
	var on5: bool = i == 11 or i == 19 or i == 20
	if subbar4 != null:
		subbar4.visible = on5
		var pg4 := [11, 20, 19]
		for k4 in sub4_buttons.size():
			(sub4_buttons[k4] as Button).set_pressed_no_signal(i == pg4[k4])
	var on2: bool = i == 5 or i == 7 or i == 10 or i == 16 or i == 17
	subbar.visible = on
	if subbar2 != null:
		subbar2.visible = on2
		var pg2 := [5, 7, 10, 16, 17]
		for k2 in sub2_buttons.size():
			(sub2_buttons[k2] as Button).set_pressed_no_signal(i == pg2[k2])
	var on3: bool = i == 2 or i == 8 or i == 9 or i == 13 or i == 14 or i == 15 or i == 18
	if subbar3 != null:
		subbar3.visible = on3
		var pg3 := [2, 8, 9, 13, 14, 15, 18]
		for k3 in 7:
			(sub3_buttons[k3] as Button).set_pressed_no_signal(i == pg3[k3])
	var on4: bool = i == 18
	if io_bar != null:
		io_bar.visible = on4
	workspace.offset_top = ui_top_h + (40.0 if (on or on2 or on3 or on5) else 0.0) + (io_bar_h() if on4 else 0.0)
	if modal_layer != null:
		modal_layer.offset_top = workspace.offset_top
	var pages := [1, 3, 4, 6, 12]
	for k in 5:
		(sub_buttons[k] as Button).set_pressed_no_signal(i == pages[k])
	subbar_hide_absent()


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
	subbar.position = Vector2(8.0, ui_top_h)
	var names := ["Парламент", "Законы", "Правительство", "Население", "Оппозиция и сделки"]
	var pages := [1, 3, 4, 6, 12]
	sub_buttons.clear()
	for k in 5:
		var b := Button.new()
		b.theme_type_variation = "TabButton"
		b.text = names[k]
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(168.0 if k < 4 else 210.0, 32.0)
		b.pressed.connect(show_desk.bind(pages[k]))
		btn_icon(b, ["hall", "scroll", "bank", "people", "person"][k])
		subbar.add_child(b)
		sub_buttons.append(b)
	subbar.visible = false
	subbar2 = HBoxContainer.new()
	subbar2.add_theme_constant_override("separation", 6)
	add_child(subbar2)
	subbar2.position = Vector2(8.0, ui_top_h)
	sub2_buttons.clear()
	var n2 := ["Рынки и финансы", "Товары и цены", "Влияние и зависимость", "Управление экономикой", "Корпорации"]
	var p2 := [5, 7, 10, 16, 17]
	for k in 5:
		var b2 := Button.new()
		b2.theme_type_variation = "TabButton"
		b2.text = n2[k]
		b2.toggle_mode = true
		b2.focus_mode = Control.FOCUS_NONE
		b2.custom_minimum_size = Vector2([180.0, 170.0, 216.0, 220.0, 150.0][k], 32.0)
		b2.pressed.connect(show_desk.bind(p2[k]))
		btn_icon(b2, ["trend", "box", "handshake", "gauge", "work"][k])
		subbar2.add_child(b2)
		sub2_buttons.append(b2)
	subbar2.visible = false
	subbar3 = HBoxContainer.new()
	subbar3.add_theme_constant_override("separation", 6)
	add_child(subbar3)
	subbar3.position = Vector2(8.0, ui_top_h)
	sub3_buttons.clear()
	var n3 := ["Карта", "Регионы и автономия", "Территории", "Армия и война", "Флот", "Вооружённые силы", "Организации"]
	var p3 := [2, 8, 9, 13, 14, 15, 18]
	for k in 7:
		var b3 := Button.new()
		b3.theme_type_variation = "TabButton"
		b3.text = n3[k]
		b3.toggle_mode = true
		b3.focus_mode = Control.FOCUS_NONE
		b3.custom_minimum_size = Vector2(170.0 if k < 3 else (150.0 if k < 5 else (196.0 if k < 6 else 170.0)), 32.0)
		b3.pressed.connect(show_desk.bind(p3[k]))
		btn_icon(b3, ["map", "grid", "flag", "shield", "ship", "star", "globe"][k])
		subbar3.add_child(b3)
		sub3_buttons.append(b3)
	subbar3.visible = false
	# v55_1: рамка «Общество»
	subbar4 = HBoxContainer.new()
	subbar4.add_theme_constant_override("separation", 6)
	add_child(subbar4)
	subbar4.position = Vector2(8.0, ui_top_h)
	sub4_buttons.clear()
	var n4 := ["Религия и миграция", "Церковь и государство", "Культура"]
	var p4 := [11, 20, 19]
	for k in 3:
		var b4 := Button.new()
		b4.theme_type_variation = "TabButton"
		b4.text = n4[k]
		b4.toggle_mode = true
		b4.focus_mode = Control.FOCUS_NONE
		b4.custom_minimum_size = Vector2([210.0, 230.0, 150.0][k], 32.0)
		b4.pressed.connect(show_desk.bind(p4[k]))
		btn_icon(b4, ["faith", "cath", "flag"][k])
		subbar4.add_child(b4)
		sub4_buttons.append(b4)
	subbar4.visible = false


func build_auto_window() -> void:
	# v50: в автопилоте остались только стройка и ремонт мощностей; он живёт в «Экономике» (окно «Сооружения страны»),
	# советник «Что сейчас важно» — в окне разовых мер на экране «Бюджет», сохранения — в настройках (⚙)
	var mw: FloatWindow = wins["measures"]
	ap_advisor_rt = make_rt(mw.body)
	mw.body.move_child(ap_advisor_rt, 0)
	var sw: FloatWindow = wins["ec_st"]
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	sw.body.add_child(box)
	sw.body.move_child(box, 0)
	add_title(box, "Автопилот")
	var defs := [
		["repair", "Авторемонт сооружений", "Ремонтирует сооружения, когда их износ ниже 60%, если долг не слишком высок."],
		["build", "Автостроительство мощностей", "Если рынку не хватает мощностей, сам начинает стройку в самом бедном свободном регионе."],
	]
	for d in defs:
		var cbn := CheckButton.new()
		cbn.text = d[1]
		cbn.tooltip_text = d[2]
		cbn.focus_mode = Control.FOCUS_NONE
		cbn.clip_text = true
		cbn.toggled.connect(on_ap_toggle.bind(d[0]))
		box.add_child(cbn)
		ap_checks[d[0]] = cbn


func on_ap_toggle(on: bool, key: String) -> void:
	if slider_busy:
		return
	# v50: режимы автопилота меняет только правительство
	if pl_deny():
		refresh()
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
		if n >= 4:
			break
	ap_advisor_rt.text = "[b]Что сейчас важно[/b]\n" + "\n".join(lines)
	slider_busy = true
	for k in ap_checks:
		(ap_checks[k] as CheckButton).set_pressed_no_signal(bool(ap.get(k, false)))
	slider_busy = false


# v50: группы относятся к партиям по-разному; оценка власти (бюджет, события) достаётся только правящим партиям
var gp_rt: RichTextLabel = null
var selfcoup_btn: Button = null
var ui_bg: ColorRect = null
var ui_top: PanelContainer = null
var io_bar: Control = null
var ui_top_h := 64.0          # 0.57: высота верхней панели (в две строки — больше)
var selfcoup_note: Label = null


func update_group_parties() -> void:
	if gp_rt == null or not gp_rt.is_visible_in_tree():
		return
	var sh: Array = group_party_shares()
	var roles := gov_roles()
	var t := "[font_size=13]"
	for gi in GROUPS.size():
		var arr: Array = []
		for p in PARTY_NAMES.size():
			arr.append([float(sh[gi][p]), p])
		arr.sort_custom(func(a, b): return a[0] > b[0])
		var parts: PackedStringArray = []
		for k in mini(3, arr.size()):
			var p: int = int(arr[k][1])
			if float(arr[k][0]) < 0.02:
				break
			parts.append("[color=#%s]■[/color] %s %.0f%%%s" % [(PARTY_COLORS[p] as Color).lightened(0.15).to_html(false), party_abbr(p), float(arr[k][0]) * 100.0, " ★" if roles[p] > 0.0 else ""])
		t += "[b]%s[/b] (власть %.0f): %s\n" % [GROUPS[gi], float(support[GROUPS[gi]]), ", ".join(parts)]
	t += "[color=%s]★ — правящие партии: только им идёт в плюс (или в минус) оценка власти группой — бюджет, законы, события. Оппозиция растёт, когда власть теряет доверие.[/color][/font_size]" % COL_DIM
	gp_rt.text = t


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
	for dir in music_dirs():
		var d := DirAccess.open(dir)
		if d == null:
			continue
		for f in d.get_files():
			var base := String(f).trim_suffix(".import")
			if base.ends_with(".ogg") and not music_list.has(dir + "/" + base):
				music_list.append(dir + "/" + base)
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
	if name == "click":
		name = click_name()
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
