# v50_1: настройки (кнопка ⚙ в правом верхнем углу): графика (тема интерфейса, море на карте, анимации, масштаб),
# звук (громкость, набор музыки, звук кнопок), сохранения и откат, справка. Настройки хранятся в user://settings.cfg.
# Здесь же — стартовое окно перед игрой (кто вы, что происходит в стране, первые шаги).
extends "res://scripts/ui/ui_army.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func settings_extra_pages() -> void:
	pass


func show_country_menu(in_game: bool) -> void:
	pass


# --- конец заглушек ---


const UI_THEMES := [
	{"name": "Ночная синь", "bg": Color(0.051, 0.063, 0.090), "panel": Color(0.090, 0.106, 0.149), "panel2": Color(0.122, 0.141, 0.200), "border": Color(0.169, 0.196, 0.282), "acc": Color(0.357, 0.553, 0.937)},
	{"name": "Графит", "bg": Color(0.062, 0.064, 0.068), "panel": Color(0.108, 0.112, 0.120), "panel2": Color(0.146, 0.151, 0.162), "border": Color(0.215, 0.225, 0.245), "acc": Color(0.300, 0.720, 0.680)},
	{"name": "Тёплый вечер", "bg": Color(0.080, 0.064, 0.054), "panel": Color(0.130, 0.103, 0.085), "panel2": Color(0.170, 0.135, 0.110), "border": Color(0.270, 0.210, 0.160), "acc": Color(0.930, 0.620, 0.300)},
	{"name": "Парламент", "bg": Color(0.040, 0.072, 0.064), "panel": Color(0.070, 0.118, 0.104), "panel2": Color(0.100, 0.155, 0.136), "border": Color(0.160, 0.250, 0.210), "acc": Color(0.860, 0.710, 0.350)},
]
const SEA_NAMES := ["Ночное море", "Атлас", "Графит"]
const MUSIC_SETS := ["Эмбиент", "Минимализм", "Всё подряд"]
const CLICK_SETS := ["Стандартный щелчок", "Мягкий (дерево)", "Клавиша"]
const UI_SCALES := [0.9, 1.0, 1.1, 1.25]
const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_KEYS := ["music", "sfx", "theme", "sea", "music_set", "click", "anim", "scale", "tip_size", "tip_delay", "nt_law", "nt_crisis", "nt_war", "nt_inbox", "nt_coal", "nt_bill", "nt_partner", "nt_opp", "nt_build", "nt_tech", "nt_treaty", "nt_world", "stop_on", "autoslow", "inbox", "chips_all", "toast_sec", "show_all", "bm", "lay_own", "lay_auto"]

var st_ov: Control = null
var st_tabs: TabContainer = null
var st_save_box: VBoxContainer = null
var st_btn: Button = null
var start_ov: Control = null


# ---------- хранение ----------
static func settings_load() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) != OK:
		return
	for k in SETTINGS_KEYS:
		if cf.has_section_key("opts", k):
			game_opts[k] = cf.get_value("opts", k)


func settings_save() -> void:
	var cf := ConfigFile.new()
	for k in SETTINGS_KEYS:
		if game_opts.has(k):
			cf.set_value("opts", k, game_opts[k])
	cf.save(SETTINGS_PATH)


# тема и море применяются до построения интерфейса (палитра — статические переменные data_core)
func settings_apply_static() -> void:
	var t: Dictionary = UI_THEMES[clampi(int(game_opts.get("theme", 0)), 0, UI_THEMES.size() - 1)]
	C_BG = t["bg"]
	C_PANEL = t["panel"]
	C_PANEL2 = t["panel2"]
	C_BORDER = t["border"]
	C_ACCENT = t["acc"]
	Gfx.set_sea_style(int(game_opts.get("sea", 0)))
	var win := get_window()
	if win != null and DisplayServer.get_name() != "headless":
		win.content_scale_factor = float(UI_SCALES[clampi(int(game_opts.get("scale", 1)), 0, UI_SCALES.size() - 1)])


func music_dirs() -> Array:
	match int(game_opts.get("music_set", 0)):
		1: return ["res://audio/music_b"]
		2: return ["res://audio/music", "res://audio/music_b"]
	return ["res://audio/music"]


func click_name() -> String:
	return ["click", "click_soft", "click_key"][clampi(int(game_opts.get("click", 0)), 0, 2)]


# ---------- кнопка и окно ----------
func build_settings_button(hb: Control) -> void:
	st_btn = Button.new()
	st_btn.theme_type_variation = "SmallButton"
	st_btn.text = "⚙"
	st_btn.add_theme_font_size_override("font_size", 19)
	st_btn.custom_minimum_size = Vector2(36.0, 36.0)
	st_btn.tooltip_text = "Настройки: графика и тема, звук и музыка, сохранение и загрузка игры"
	st_btn.focus_mode = Control.FOCUS_NONE
	st_btn.pressed.connect(func() -> void: settings_open(st_ov == null or not st_ov.visible))
	hb.add_child(st_btn)


func settings_open(on: bool) -> void:
	if on and st_ov == null:
		build_settings_window()
	if st_ov == null:
		return
	if on:
		settings_fill_saves()
		st_ov.visible = true
		win_fade_in(st_ov, 0.16)
		sfx(click_name())
	else:
		st_ov.visible = false


func build_settings_window() -> void:
	st_ov = Control.new()
	st_ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	st_ov.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(st_ov)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		var mb := ev as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			settings_open(false))
	st_ov.add_child(dim)
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", sbox(C_PANEL, C_ACCENT.darkened(0.2), 2, 12, 14.0, 12.0))
	pan.anchor_left = 0.5
	pan.anchor_right = 0.5
	pan.anchor_top = 0.5
	pan.anchor_bottom = 0.5
	pan.offset_left = -330.0
	pan.offset_right = 330.0
	pan.offset_top = -270.0
	pan.offset_bottom = 270.0
	st_ov.add_child(pan)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	pan.add_child(vb)
	var hd := HBoxContainer.new()
	vb.add_child(hd)
	var ic: Control = Ico.make("gauge", C_ACCENT.lightened(0.2), 18.0)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hd.add_child(ic)
	var tl := Label.new()
	tl.text = "  Настройки"
	tl.add_theme_font_size_override("font_size", 22)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hd.add_child(tl)
	# 0.59: «Новая игра» переехала сюда с флага слева вверху
	var ng := Button.new()
	ng.text = "★ Новая игра"
	ng.tooltip_text = "Выбрать страну и начать новую игру. Текущая партия закроется (сохраните её на вкладке «Сохранения»)."
	ng.focus_mode = Control.FOCUS_NONE
	ng.pressed.connect(func() -> void:
		settings_open(false)
		show_country_menu(true))
	hd.add_child(ng)
	var cl := Button.new()
	cl.text = "✕ Закрыть"
	cl.focus_mode = Control.FOCUS_NONE
	cl.pressed.connect(settings_open.bind(false))
	hd.add_child(cl)
	st_tabs = TabContainer.new()
	st_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(st_tabs)
	# --- графика ---
	var g := st_page("Графика")
	st_option(g, "Тема интерфейса", UI_THEMES.map(func(t: Dictionary) -> String: return String(t["name"])), "theme",
		"Цвета фона, панелей и акцента. Полностью тема применяется к новым окнам и при следующем запуске; основное меняется сразу.", func(_i: int) -> void:
			settings_apply_static()
			theme = make_theme()
			refresh())
	st_option(g, "Море на карте", SEA_NAMES, "sea", "Цвет и глубина воды на карте мира и страны.", func(_i: int) -> void:
		settings_apply_static()
		if map_ctl != null:
			map_ctl.queue_redraw())
	st_option(g, "Масштаб интерфейса", UI_SCALES.map(func(x: float) -> String: return "%d%%" % int(round(x * 100.0))), "scale",
		"Размер шрифтов и кнопок. Удобно на больших или маленьких экранах.", func(_i: int) -> void: settings_apply_static())
	# 0.56: подсказки — размер шрифта и задержка перед показом
	st_option(g, "Размер подсказок", ["Мелкий", "Обычный", "Крупный"], "tip_size",
		"Размер шрифта и ширина всплывающих подсказок.", func(_i: int) -> void: pass)
	st_option(g, "Задержка подсказок", ["Сразу", "0,5 с", "1 с"], "tip_delay",
		"Сколько держать мышь над элементом, прежде чем появится подсказка.", func(_i: int) -> void: pass)
	st_check(g, "Плавные анимации (окна, камера, числа)", "anim", "Если выключить, окна и карта меняются сразу — быстрее на слабых компьютерах.")
	# --- звук ---
	var a := st_page("Звук")
	st_slider(a, "Музыка", "music", func(_v: float) -> void:
		audio_apply_volume()
		if music_btn != null:
			music_btn.text = "♪" if float(game_opts.get("music", 0.45)) > 0.001 else "🔇")
	st_slider(a, "Звуки", "sfx", func(_v: float) -> void: audio_apply_volume())
	st_option(a, "Музыка", MUSIC_SETS, "music_set", "Эмбиент — тёплые аккорды; Минимализм — тихие арпеджио; можно играть всё подряд.", func(_i: int) -> void:
		music_reload())
	st_option(a, "Звук кнопок", CLICK_SETS, "click", "Каким звуком отвечают кнопки и вкладки.", func(_i: int) -> void: sfx(click_name()))
	var nx := Button.new()
	nx.text = "▶▶ Следующая мелодия"
	nx.focus_mode = Control.FOCUS_NONE
	nx.pressed.connect(music_next)
	a.add_child(nx)
	# --- сохранения ---
	var s := st_page("Сохранения")
	st_save_box = VBoxContainer.new()
	st_save_box.add_theme_constant_override("separation", 6)
	s.add_child(st_save_box)
	settings_extra_pages()
	# --- игра ---
	var p := st_page("Игра")
	var tb := Button.new()
	tb.text = "Подсказки для новичка — сначала"
	tb.focus_mode = Control.FOCUS_NONE
	tb.pressed.connect(func() -> void:
		settings_open(false)
		tut_idx = 0
		update_tutorial())
	p.add_child(tb)
	var sb := Button.new()
	sb.text = "Окно «Начало игры» ещё раз"
	sb.focus_mode = Control.FOCUS_NONE
	sb.pressed.connect(func() -> void:
		settings_open(false)
		show_start_window())
	p.add_child(sb)
	var rl := Button.new()
	rl.text = "↺ Вернуть все окна на исходные места"
	rl.focus_mode = Control.FOCUS_NONE
	rl.pressed.connect(func() -> void:
		settings_open(false)
		reset_layout())
	p.add_child(rl)
	var cb := Button.new()
	cb.text = "Новая игра (выбрать страну)"
	cb.focus_mode = Control.FOCUS_NONE
	cb.pressed.connect(func() -> void:
		settings_open(false)
		show_country_menu(true))
	p.add_child(cb)
	var hr := make_rt(p)
	hr.text = "[b]Справка.[/b] Политический капитал — ресурс решений. Рейтинг — доля довольных. Сепаратизм падает от автономии и диалога. Коррупция растёт при слабых судах и несвободных СМИ. Цена энергии 100 — норма. Низкая лояльность армии и высокие амбиции генералов повышают риск переворота.\n\n[b]Клавиши:[/b] пробел — пауза/ход, Enter — продолжить после выборов, колёсико — масштаб карты."
	polish_tree(st_ov)


func st_page(title: String) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.name = title
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	st_tabs.add_child(sc)
	var mc := MarginContainer.new()
	mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + side, 10)
	sc.add_child(mc)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 10)
	mc.add_child(vb)
	return vb


func st_row(parent: Control, label: String, tip: String) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	hb.tooltip_text = tip
	parent.add_child(hb)
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(200.0, 0.0)
	l.tooltip_text = tip
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	hb.add_child(l)
	return hb


func st_option(parent: Control, label: String, items: Array, key: String, tip: String, after: Callable) -> void:
	var hb := st_row(parent, label, tip)
	var ob := OptionButton.new()
	ob.focus_mode = Control.FOCUS_NONE
	ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for it in items:
		ob.add_item(String(it))
	ob.select(clampi(int(game_opts.get(key, 1 if key in ["scale", "tip_size", "tip_delay"] else 0)), 0, items.size() - 1))
	ob.item_selected.connect(func(i: int) -> void:
		game_opts[key] = i
		settings_save()
		after.call(i))
	hb.add_child(ob)


func st_check(parent: Control, label: String, key: String, tip: String) -> void:
	var cb := CheckButton.new()
	cb.text = label
	cb.tooltip_text = tip
	cb.focus_mode = Control.FOCUS_NONE
	cb.button_pressed = bool(game_opts.get(key, true))
	cb.toggled.connect(func(on: bool) -> void:
		game_opts[key] = on
		settings_save())
	parent.add_child(cb)


func st_slider(parent: Control, label: String, key: String, after: Callable) -> void:
	var hb := st_row(parent, label, "")
	var sl := HSlider.new()
	sl.min_value = 0.0
	sl.max_value = 1.0
	sl.step = 0.05
	sl.value = float(game_opts.get(key, 0.5))
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.focus_mode = Control.FOCUS_NONE
	hb.add_child(sl)
	var vl := Label.new()
	vl.text = "%d%%" % int(round(sl.value * 100.0))
	vl.custom_minimum_size = Vector2(46.0, 0.0)
	hb.add_child(vl)
	sl.value_changed.connect(func(v: float) -> void:
		game_opts[key] = v
		vl.text = "%d%%" % int(round(v * 100.0))
		settings_save()
		after.call(v))


func settings_fill_saves() -> void:
	if st_save_box == null:
		return
	for ch in st_save_box.get_children():
		st_save_box.remove_child(ch)
		ch.queue_free()
	rm_text(st_save_box, "Сохранение записывает всё состояние страны; слоты у каждой страны свои. Раз в год делается автоснимок — ошибку можно откатить.")
	for sl in [1, 2, 3]:
		rm_slot_row(st_save_box, sl)
	var names := []
	for x in sv_hist:
		names.append(String(x["date"]))
	rm_text(st_save_box, "Автоснимки (раз в год): %s" % (", ".join(names) if names.size() > 0 else "первый появится в январе"))
	var rb := fed_btn("Откатиться на предыдущий снимок", st_save_box, "Вернёт игру на последний снимок до текущего месяца. Всё после него будет потеряно.")
	rb.disabled = sv_hist.is_empty()
	rb.pressed.connect(func() -> void:
		sv_rollback()
		rm_dirty_all()
		settings_fill_saves()
		refresh())


func music_reload() -> void:
	if music_player == null:
		return
	music_list.clear()
	for dir in music_dirs():
		var d := DirAccess.open(dir)
		if d == null:
			continue
		for f in d.get_files():
			var fs := String(f)
			var base := fs.trim_suffix(".import")
			if base.ends_with(".ogg") and not music_list.has(dir + "/" + base):
				music_list.append(dir + "/" + base)
	music_list.sort()
	music_idx = randi() % maxi(1, music_list.size())
	music_next()


# ---------- стартовое окно (п. 31) ----------
func show_start_window() -> void:
	# в тестах и скриптах снимков (запуск с --script) окно не мешает щелчкам — только по просьбе start=1
	var scripted: bool = OS.get_cmdline_args().has("--script") or OS.get_cmdline_args().has("-s")
	if (DisplayServer.get_name() == "headless" or scripted) and not OS.get_cmdline_user_args().has("start=1"):
		return
	if start_ov != null:
		start_ov.queue_free()
	start_ov = Control.new()
	start_ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	start_ov.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(start_ov)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	start_ov.add_child(dim)
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", sbox(C_PANEL, C_ACCENT.darkened(0.15), 2, 14, 18.0, 14.0))
	pan.anchor_left = 0.5
	pan.anchor_right = 0.5
	pan.anchor_top = 0.5
	pan.anchor_bottom = 0.5
	pan.offset_left = -380.0
	pan.offset_right = 380.0
	pan.offset_top = -290.0
	pan.offset_bottom = 290.0
	start_ov.add_child(pan)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	pan.add_child(vb)
	var hd := HBoxContainer.new()
	hd.add_theme_constant_override("separation", 14)
	vb.add_child(hd)
	var fl: Control = Flags.make(ccode, 40.0)
	fl.custom_minimum_size = Vector2(66.0, 44.0)
	fl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hd.add_child(fl)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hd.add_child(tv)
	var t1 := Label.new()
	t1.text = String(WORLD[ccode]["name"]) if WORLD.has(ccode) else ccode
	t1.add_theme_font_size_override("font_size", 28)
	t1.add_theme_color_override("font_color", C_TEXT)
	tv.add_child(t1)
	var t2 := Label.new()
	t2.text = "Январь %d · ваша партия — «%s»" % [START_YEAR, String(PARTY_NAMES[0]).replace("«", "").replace("»", "")]
	t2.add_theme_font_size_override("font_size", 15)
	t2.add_theme_color_override("font_color", C_ACCENT.lightened(0.25))
	tv.add_child(t2)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(sc)
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rt.add_theme_font_size_override("normal_font_size", 15)
	rt.add_theme_font_size_override("bold_font_size", 15)
	rt.text = start_text()
	sc.add_child(rt)
	var go := Button.new()
	go.text = "Начать игру  (Enter)"
	go.custom_minimum_size = Vector2(0.0, 42.0)
	go.focus_mode = Control.FOCUS_ALL
	color_button(go, C_ACCENT.lightened(0.35))
	go.pressed.connect(func() -> void:
		sfx(click_name())
		start_ov.queue_free()
		start_ov = null)
	vb.add_child(go)
	go.grab_focus.call_deferred()
	win_fade_in(start_ov, 0.3)
	polish_tree(start_ov)


func start_text() -> String:
	var t := ""
	var role: String
	if observer:
		role = "Вы [b]наблюдаете[/b]: партией, бюджетом и решениями управляет ИИ."
	elif opp_mode:
		role = ("Ваша партия [b]в оппозиции[/b]: бюджетом, министрами и решениями государства распоряжается правительство «%s». Вы можете вносить законопроекты, договариваться с партиями и готовиться к выборам." % String(PARTY_NAMES[int(opp_gov.get("pm", 1))])) if pl_parl() else "Ваша партия [b]не прошла в парламент[/b]: государством вы не управляете и законопроекты вносить не можете. Цель — преодолеть барьер на выборах: помогут предвыборные блоки и союзы."
	elif bool(junior_info()["junior"]):
		role = "Вы — [b]младший партнёр[/b] в коалиции: бюджет, кабинет и решения проходят через совет коалиции."
	else:
		role = "Вы [b]во главе правительства[/b]: бюджет, министры, законы и решения по событиям — ваши. Держите коалицию и выигрывайте выборы."
	t += role + "\n\n"
	var blurb: String = String(INFO.get("blurb", ""))
	if blurb != "":
		t += "[color=%s]%s[/color]\n\n" % [COL_DIM, blurb]
	t += "[b]Страна сейчас[/b]\nВВП %s млрд · рост %s%% · инфляция %.1f%% · безработица %.1f%% · долг %.0f%% ВВП · рейтинг власти %.0f%%\n" % [String.num(gdp, 0), String.num(growth, 1), inflation, unemployment, debt / maxf(1.0, gdp) * 100.0, approval()]
	t += "Выборы в парламент — через %s.\n" % months_text(parl_term() - (turn - last_parl))
	if MIL_ONGOING.has(ccode) and bool(game_opts.get("ongoing", true)):
		var foe: String = String(MIL_ONGOING[ccode][0])
		t += "[color=%s]Идёт война (противник — %s), четвёртый год; фронт почти неподвижен. Армия, мобилизация и переговоры — на экране «Карта → Армия и война».[/color]\n" % [COL_BAD, String(WORLD[foe]["name"]) if WORLD.has(foe) else foe]
	t += "\n[b]С чего начать[/b]\n• «Бюджет» — налоги и расходы; смотрите прогноз роста и рейтинга.\n• «Политика» — парламент, законы, коалиция и партии.\n• «Карта» — регионы, недовольство, армия и соседи.\n• ▶ или пробел — пустить время. ⚙ — настройки и сохранения."
	return t
