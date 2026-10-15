# Symphony: корневой скрипт (вершина цепочки наследования, см. scripts/CHAIN.txt).
# Политико-экономическая игра, версия 8 (новая система коалиций).
# Время идёт по дням: скорость задают кнопки справа вверху, а экономика и политика считаются на границе месяцев. Три экрана: «Бюджет», «Политика», «Карта регионов».
# Все окна плавающие: двигайте за заголовок, меняйте размер за правый/нижний край и угол,
# двойной щелчок по заголовку (или кнопка «–») сворачивает окно.
# Весь интерфейс создаётся кодом. Повесьте скрипт на корневой узел Control (Godot 4.x).
extends "res://scripts/ui/ui_orgs.gd"

# ============================================================
#  СТРАНЫ: применение пакета данных
# ============================================================
func country_arg() -> String:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("country="):
			return String(a).substr(8)
	return ""


func party_arg() -> int:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("party="):
			return int(String(a).substr(6))
	return pending_party


# seed=N в аргументах запуска делает игру воспроизводимой (для тестов); без него — случайно
func seed_arg() -> int:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("seed="):
			return int(String(a).substr(5))
	return -1


func apply_country(code: String) -> void:
	ccode = code
	var d: Dictionary = CDATA[code]
	for k in d:
		var v = d[k]
		if v is Array or v is Dictionary:
			v = v.duplicate(true)
		set(k, v)
	split_subsidies()
	var mc: Dictionary = MACRO
	SEATS = int(SEATS)
	if code == "DE":
		SEATS = 630
	MAJORITY = SEATS / 2 + 1
	SUPER = int(ceil(float(SEATS) * 2.0 / 3.0))
	if code != "DE":
		gdp = GDP0
		debt = float(mc["debt"])
		growth = float(mc["growth"])
		inflation = float(mc["infl"])
		unemployment = float(mc["unemp"])
	other_rev = OTHER0
	growth_ema = growth
	growth_trend = -99.0
	def_ref = -99.0
	tax_ref = -99.0
	debt_start = -99.0
	gdp_base = gdp
	BASE_MODS["threshold"] = float(mc["threshold"])
	BASE_MODS["parl_term"] = int(mc["parl_term"])
	BASE_MODS["impeach_seats"] = int(mc["impeach_seats"])
	BASE_MODS["constr"] = int(mc["constr"])
	mods = BASE_MODS.duplicate()
	minority_ok = bool(mc["minority_ok"])
	last_parl = -int(mc["elapsed"])
	ELEC = (ELEC_DATA[code] if ELEC_DATA.has(code) else ELEC_DATA["DE"]).duplicate(true)
	pres_party = -1
	pres_camp = 0.0
	pres_camp_done = -100
	pres_due = -1
	var hk: String = String(ELEC["head"])
	if hk == "direct" or hk == "indirect":
		pres_due = int(ELEC["first"])
	elif hk == "council":
		pres_due = -int(mc["elapsed"]) + int(mc["parl_term"]) + 2
	fund_left = 500.0 if code == "DE" else 0.0
	apply_markets()
	DE_OWN.clear()
	for t in DE_TOPICS:
		DE_OWN[t["id"]] = true
	LAW_TOPICS = build_law_topics()
	if code != "DE":
		remap_base_ps()
	radical_inject()
	regecon_inject()
	law_text_apply()
	build_loc()
	apply_player_party(party_arg())
	if not get_window() == null:
		get_window().title = "Symphony: %s" % String(WORLD[code]["name"])


func apply_markets() -> void:
	for m in MARKETS:
		var o: Dictionary = MARKETS_OVR.get(m["id"], {})
		if o.has("x"):
			var dx: float = float(o["x"]) - float(m["x"])
			m["x"] = float(o["x"])
			m["c"] = maxf(0.0, float(m["c"]) - 0.7 * dx)
			m["g"] = maxf(0.0, float(m["g"]) - 0.3 * dx)
			var s: float = float(m["c"]) + float(m["i"]) + float(m["g"]) + float(m["x"])
			m["c"] = float(m["c"]) / s
			m["i"] = float(m["i"]) / s
			m["g"] = float(m["g"]) / s
			m["x"] = float(m["x"]) / s
		if o.has("imp"):
			m["imp"] = float(o["imp"])
		if o.has("w"):
			m["w"] = float(o["w"])
	var tot := 0.0
	for m in MARKETS:
		tot += float(m["w"])
	for m in MARKETS:
		m["w"] = float(m["w"]) / tot
	apply_goods()


# v50: исходные данные Германии (они живут в переменных скрипта и меняются в игре — при обмене партий, при загрузке другой страны);
# меню берёт их отсюда, а не из текущей партии (раньше после игры за Volt в меню путались правящая партия и партия игрока)
var de_base := {}
const DE_BASE_KEYS := ["PARTY_NAMES", "PARTY_COLORS", "PARTY_LEADERS", "PARTY_DESC", "PARTY_TRAITS", "DE_START_SEATS", "DE_START_MIN",
	"COALITION0", "REGIONS", "SEATS", "MARKETS_OVR"]


func de_base_snap() -> void:
	if not de_base.is_empty():
		return
	for k in DE_BASE_KEYS:
		var v = get(k)
		de_base[k] = v.duplicate(true) if (v is Array or v is Dictionary) else v


func cdat(code: String, key: String):
	var d: Dictionary = CDATA.get(code, {})
	if d.has(key):
		return d[key]
	return de_base[key] if de_base.has(key) else get(key)


func diff_color(d: int) -> Color:
	return [Color(0.30, 0.72, 0.50), Color(0.45, 0.75, 0.45), Color(0.90, 0.75, 0.30), Color(0.93, 0.55, 0.30), Color(0.90, 0.35, 0.35)][clampi(d - 1, 0, 4)]


func menu_title(parent: Control, text: String) -> void:
	# v49: значок раздела перед заголовком
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	parent.add_child(hb)
	var ik: String = String({"Паспорт": "scroll", "Политическая ситуация": "hall", "Ваше положение": "person", "Экономика": "chart",
		"Сильные стороны и риски": "warn", "Соседи и мир": "globe", "Регионы": "map", "Население (модель агентов)": "people",
		"Ход игры": "calendar", "Воспроизводимость и интерфейс": "gauge"}.get(text, ""))
	if ik != "":
		var ic: Control = Ico.make(ik, C_ACCENT.lightened(0.2), 13.0)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(ic)
	var l := Label.new()
	l.text = text.to_upper()
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", C_ACCENT.lightened(0.2))
	hb.add_child(l)
	var line := ColorRect.new()
	line.color = C_BORDER
	line.custom_minimum_size = Vector2(0.0, 1.0)
	parent.add_child(line)


func menu_rt(parent: Control, text: String) -> RichTextLabel:
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rt.add_theme_font_size_override("normal_font_size", 14)
	rt.add_theme_font_size_override("bold_font_size", 14)
	rt.text = text
	parent.add_child(rt)
	return rt


func menu_bar(parent: Control, items: Array) -> void:
	# items: [значение, цвет, подсказка]
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 1)
	hb.custom_minimum_size = Vector2(0.0, 16.0)
	parent.add_child(hb)
	for it in items:
		if float(it[0]) <= 0.0:
			continue
		var cr := ColorRect.new()
		cr.color = it[1]
		cr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cr.size_flags_stretch_ratio = maxf(float(it[0]), 0.0001)
		cr.custom_minimum_size = Vector2(1.0, 16.0)
		cr.tooltip_text = String(it[2])
		cr.mouse_filter = Control.MOUSE_FILTER_STOP
		hb.add_child(cr)


func sector_shares(code: String) -> Dictionary:
	var ov: Dictionary = cdat(code, "MARKETS_OVR")
	var out := {}
	var tot := 0.0
	for m in MARKETS:
		var w: float = float((ov.get(m["id"], {}) as Dictionary).get("w", m["w"]))
		out[m["id"]] = w
		tot += w
	for k in out:
		out[k] = float(out[k]) / tot
	return out


func country_strengths(code: String) -> Array:
	# [знак, текст]: знак +1 плюс, -1 минус, 0 особенность
	var out: Array = []
	var mc: Dictionary = cdat(code, "MACRO")
	var w: Dictionary = WORLD[code]
	var sh := sector_shares(code)
	var debt_pct: float = float(w["debt"]) / maxf(1.0, float(w["gdp"])) * 100.0 if float(w["debt"]) > 300.0 or float(w["gdp"]) > 0.0 else 0.0
	var info: Dictionary = CDATA[code]["INFO"] if CDATA[code].has("INFO") else INFO
	debt_pct = float(info["debt_pct"])
	if debt_pct < 55.0:
		out.append([1, "Умеренный долг (%.0f%% ВВП): есть пространство для манёвра." % debt_pct])
	elif debt_pct > 100.0:
		out.append([-1, "Очень высокий долг (%.0f%% ВВП): каждая ошибка в бюджете дорого стоит." % debt_pct])
	if float(w["def"]) >= 4.0:
		out.append([-1, "Большой дефицит бюджета (%.1f%% ВВП)." % float(w["def"])])
	elif float(w["def"]) <= 1.0:
		out.append([1, "Бюджет почти сбалансирован."])
	if float(w["infl"]) >= 3.0:
		out.append([-1, "Инфляция выше цели (%.1f%%)." % float(w["infl"])])
	if float(w["unemp"]) >= 7.0:
		out.append([-1, "Высокая безработица (%.1f%%)." % float(w["unemp"])])
	elif float(w["unemp"]) <= 3.5:
		out.append([1, "Рынок труда напряжён: безработица всего %.1f%%." % float(w["unemp"])])
	if float(sh["res"]) + float(sh["ene"]) >= 0.10:
		out.append([0, "Сырьевая экономика: доходы зависят от мировых цен на нефть и газ."])
	if float(sh["ind"]) >= 0.20:
		out.append([1, "Сильная промышленность и экспорт: зависимость от мирового спроса."])
	if float(sh["srv"]) >= 0.74:
		out.append([0, "Экономика услуг: финансы, туризм, торговля."])
	if bool(mc.get("euro", true)):
		out.append([0, "Евро: ставку задаёт ЕЦБ, эмиссия недоступна."])
	else:
		out.append([0, "Собственная валюта: свой центробанк и эмиссия, но курс может качаться."])
	if not bool(mc.get("eu", true)):
		out.append([0, "Вне ЕС: свои торговые правила, но нет общего рынка."])
	if bool(mc.get("minority_ok", false)):
		out.append([-1, "Правительство меньшинства: опора на терпимость партий."])
	if float(w["appr"]) < 40.0:
		out.append([-1, "Низкий рейтинг власти (%.0f%%): выборы под угрозой." % float(w["appr"])])
	var regs: Array = cdat(code, "REGIONS")
	var unr := 0.0
	for r in regs:
		unr += float(r["unrest"])
	unr /= maxf(1.0, float(regs.size()))
	if unr >= 33.0:
		out.append([-1, "Напряжённые регионы: средняя неспокойность %.0f." % unr])
	var go: Dictionary = cdat(code, "GOODS_OVR") if CDATA[code].has("GOODS_OVR") else {}
	var best := ""
	var bv := 1.1
	for gid in go:
		var gv: float = float((go[gid] as Dictionary).get("kg", 1.0))
		if gv > bv:
			bv = gv
			best = String(gid)
	if best != "":
		for g in GOODS:
			if g["id"] == best:
				out.append([0, "В корзине людей особенно велика доля: %s." % String(g["name"]).to_lower()])
	return out


func fill_country_card(code: String, box: VBoxContainer, head: Label, sub: Label) -> void:
	for ch in box.get_children():
		ch.queue_free()
	var w: Dictionary = WORLD[code]
	var info: Dictionary = CDATA[code]["INFO"] if CDATA[code].has("INFO") else INFO
	var dif: int = int(info["difficulty"])
	var mc: Dictionary = cdat(code, "MACRO")
	var terms: Dictionary = cdat(code, "TERMS")
	var elec: Dictionary = ELEC_DATA.get(code, ELEC_DATA["DE"])
	var up: Dictionary = cdat(code, "UPPER")
	var pnames: Array = cdat(code, "PARTY_NAMES")
	var pcols: Array = cdat(code, "PARTY_COLORS")
	var pleaders: Array = cdat(code, "PARTY_LEADERS")
	var pseats: Array = cdat(code, "DE_START_SEATS")
	var seats_n: int = 630 if code == "DE" else int(cdat(code, "SEATS"))
	var coal: Array = cdat(code, "COALITION0")
	head.text = String(w["name"])
	sub.text = "%s · сложность %s" % [String(w["cap"]), "★".repeat(dif) + "☆".repeat(5 - dif)]
	sub.add_theme_color_override("font_color", diff_color(dif))
	# --- паспорт ---
	menu_title(box, "Паспорт")
	var headk: String = String(elec.get("head", "none"))
	var head_txt: String = {"direct": "президент избирается всенародно", "indirect": "президент избирается собранием выборщиков", "council": "коллегиальный глава (совет)", "monarch": "монарх (не избирается)"}.get(headk, "—")
	var regs: Array = cdat(code, "REGIONS")
	var cur: String = "евро" if bool(mc.get("euro", true)) else "собственная валюта"
	# v49: паспорт — строки со значками
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 3)
	box.add_child(grid)
	for row in [
		["people", "Население", "%.1f млн чел." % float(info["pop"])],
		["chart", "ВВП", "%s млрд € (%.1f тыс. на человека)" % [fmt_n(float(info["gdp"])), float(info["gdp"]) / maxf(0.01, float(info["pop"]))]],
		["bank", "Госдолг", "%.0f%% ВВП" % float(info["debt_pct"])],
		["map", "Деление", "%d %s" % [regs.size(), String(terms.get("regs", "регионов"))]],
		["coin", "Валюта", cur + (", в ЕС" if bool(mc.get("eu", true)) else ", вне ЕС")],
		["crown" if headk == "monarch" else "person", "Глава государства", head_txt],
		["hall", "Парламент", "%d мест, большинство — %d" % [seats_n, seats_n / 2 + 1]],
		["ballot", "Верхняя палата", String(up.get("name", "")) if String(up.get("name", "")) != "" else "нет"],
	]:
		var ic: Control = Ico.make(String(row[0]), Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b).lightened(0.25), 16.0)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		grid.add_child(ic)
		var k := Label.new()
		k.text = String(row[1])
		k.add_theme_color_override("font_color", C_DIM)
		k.add_theme_font_size_override("font_size", 14)
		grid.add_child(k)
		var vl := Label.new()
		vl.text = String(row[2])
		vl.add_theme_font_size_override("font_size", 14)
		vl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(vl)
	# --- ситуация ---
	menu_title(box, "Политическая ситуация")
	menu_rt(box, String(info["blurb"]))
	var tot := 0.0
	var items: Array = []
	for p in pnames.size():
		var sv: float = float(pseats[p]) if p < pseats.size() else 0.0
		if sv > 0.0:
			var star := "★ " if p in coal or p == 0 else ""
			items.append([sv, (pcols[p] as Color), "%s%s — %d мест" % [star, pnames[p], int(sv)]])
			tot += sv
	var cs := 0.0
	var cn: PackedStringArray = []
	for p in coal:
		if p < pseats.size():
			cs += float(pseats[p])
			cn.append(String(pnames[p]))
	menu_rt(box, "[color=#98a1b8]Состав парламента на старте (наведите на цвет):[/color]")
	menu_bar(box, items)
	menu_rt(box, "[b]Правящая партия:[/b] %s, лидер — %s\n[b]Коалиция:[/b] %s — [b]%d[/b] мест из %d (%s)\n[b]Выборы:[/b] %s" % [pnames[0], String(pleaders[0]).replace(" (вы)", ""), ", ".join(cn), int(cs), seats_n, "есть большинство" if cs > float(seats_n) / 2.0 else "большинства нет", String(elec.get("sys", "—"))])
	# v35: ситуация глазами выбранной партии
	menu_title(box, "Ваше положение")
	menu_sit_rt = menu_rt(box, "")
	menu_sit_code = code
	# --- экономика ---
	menu_title(box, "Экономика")
	var sh := sector_shares(code)
	var sitems: Array = []
	var sl: PackedStringArray = []
	for m in MARKETS:
		var share: float = float(sh[m["id"]])
		sitems.append([share, Color(String(MARKET_COLORS[m["id"]])), "%s — %.1f%%" % [m["name"], share * 100.0]])
		if share >= 0.04:
			sl.append("[color=%s]■[/color] %s %.0f%%" % [MARKET_COLORS[m["id"]], m["short"], share * 100.0])
	menu_bar(box, sitems)
	menu_rt(box, "  ".join(sl))
	menu_rt(box, "[table=2][cell][color=#98a1b8]Рост ВВП  [/color][/cell][cell]%.1f%%[/cell][cell][color=#98a1b8]Инфляция  [/color][/cell][cell]%.1f%%[/cell][cell][color=#98a1b8]Безработица  [/color][/cell][cell]%.1f%%[/cell][cell][color=#98a1b8]Дефицит бюджета  [/color][/cell][cell]%.1f%% ВВП[/cell][/table]" % [float(w["growth"]), float(w["infl"]), float(w["unemp"]), float(w["def"])])
	# --- сильные стороны и риски ---
	menu_title(box, "Сильные стороны и риски")
	var st := ""
	for it in country_strengths(code):
		var sign: int = int(it[0])
		st += "[color=%s]%s[/color] %s\n" % [COL_GOOD if sign > 0 else (COL_BAD if sign < 0 else COL_WARN), "▲" if sign > 0 else ("▼" if sign < 0 else "◆"), it[1]]
	menu_rt(box, st.strip_edges())


# ============================================================
#  НАСТРОЙКИ НОВОЙ ИГРЫ (меню перед стартом; во время игры не меняются)
# ============================================================
var menu_est_code := ""
var menu_sit_rt: RichTextLabel = null
var menu_sit_code := ""
var menu_est_lbl: Label = null
var menu_ag_k: HSlider = null


func opt_index(arr: Array, v: float) -> int:
	var bi := 0
	for i in arr.size():
		if absf(float(arr[i]) - v) < absf(float(arr[bi]) - v):
			bi = i
	return bi


# оценка числа агентов для выбранной страны и текущей настройки
func menu_update_est() -> void:
	if menu_est_lbl == null or menu_est_code == "":
		return
	if not bool(game_opts["agents"]):
		menu_est_lbl.text = "Модель агентов выключена: население считается группами (быстро, но без отдельных людей, карты идеологий и опросов по агентам)."
		return
	var pop: float = float(cdat(menu_est_code, "INFO")["pop"]) * 1000000.0
	var k: int = int(game_opts["k"])
	if k <= 0:
		k = clampi(int(round(pop / 40000.0 / 50.0)) * 50, 100, 1000)
	var n: int = int(pop / float(k))
	menu_est_lbl.text = "%s: ≈ %s агентов, 1 агент = %d чел.%s" % [String(WORLD[menu_est_code]["name"]), str(n).insert(maxi(0, str(n).length() - 3), " ") if n >= 1000 else str(n), k, ("  ⚠ много — на слабом компьютере игра будет медленной" if n > 60000 else "")]


func opt_row(parent: Control, title: String, tip: String) -> void:
	var l := Label.new()
	l.text = title
	l.add_theme_font_size_override("font_size", 14)
	l.tooltip_text = tip
	l.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(l)


func opt_choice(parent: Control, title: String, tip: String, items: Array, cur: int, on_pick: Callable) -> OptionButton:
	opt_row(parent, title, tip)
	var ob := OptionButton.new()
	ob.focus_mode = Control.FOCUS_NONE
	ob.tooltip_text = tip
	for t in items:
		ob.add_item(String(t))
	ob.selected = cur
	ob.item_selected.connect(on_pick)
	parent.add_child(ob)
	var n := Label.new()
	n.text = tip
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	n.add_theme_font_size_override("font_size", 12)
	n.add_theme_color_override("font_color", C_DIM)
	parent.add_child(n)
	return ob


func opt_slider(parent: Control, title: String, tip: String, mn: float, mx: float, step: float, cur: float, fmt: Callable, on_change: Callable) -> HSlider:
	var hb := HBoxContainer.new()
	var l := Label.new()
	l.text = title
	l.add_theme_font_size_override("font_size", 14)
	l.tooltip_text = tip
	l.mouse_filter = Control.MOUSE_FILTER_STOP
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(l)
	var v := Label.new()
	v.add_theme_font_size_override("font_size", 14)
	v.add_theme_color_override("font_color", C_ACCENT.lightened(0.25))
	hb.add_child(v)
	parent.add_child(hb)
	var sl := HSlider.new()
	sl.min_value = mn
	sl.max_value = mx
	sl.step = step
	sl.value = cur
	sl.focus_mode = Control.FOCUS_NONE
	sl.tooltip_text = tip
	sl.custom_minimum_size = Vector2(0.0, 22.0)
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.text = String(fmt.call(cur))
	sl.value_changed.connect(func(x: float) -> void:
		v.text = String(fmt.call(x))
		on_change.call(x))
	parent.add_child(sl)
	var n := Label.new()
	n.text = tip
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	n.add_theme_font_size_override("font_size", 12)
	n.add_theme_color_override("font_color", C_DIM)
	parent.add_child(n)
	return sl


func fmt_mult(x: float) -> String:
	return "×%s" % String.num(x, 2).replace(".", ",")


func fmt_k(x: float) -> String:
	return "Авто" if int(x) <= 0 else "%d чел." % int(x)


func build_settings_panel(sc: ScrollContainer) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(box)
	var intro := Label.new()
	intro.text = "Эти настройки задаются только здесь, до начала игры. Во время игры изменить их нельзя."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_color_override("font_color", C_DIM)
	box.add_child(intro)
	menu_title(box, "Население (модель агентов)")
	var chk := CheckBox.new()
	chk.text = "Модель агентов: население как набор отдельных людей"
	chk.button_pressed = bool(game_opts["agents"])
	chk.focus_mode = Control.FOCUS_NONE
	chk.tooltip_text = "Каждый агент — тысячи человек с возрастом, доходом, отраслью, взглядами и потребительской корзиной. Это самая тяжёлая часть игры."
	box.add_child(chk)
	menu_ag_k = opt_slider(box, "Человек на одного агента", "Меньше человек на агента — точнее модель, но больше агентов и медленнее ход. 0 — «Авто»: подбирается по численности страны.", 0.0, 1000.0, 50.0, float(int(game_opts["k"])), fmt_k, func(x: float) -> void:
		game_opts["k"] = int(x)
		menu_update_est())
	menu_ag_k.editable = bool(game_opts["agents"])
	chk.toggled.connect(func(on: bool) -> void:
		game_opts["agents"] = on
		menu_ag_k.editable = on
		menu_update_est())
	menu_est_lbl = Label.new()
	menu_est_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_est_lbl.add_theme_font_size_override("font_size", 13)
	menu_est_lbl.add_theme_color_override("font_color", C_ACCENT.lightened(0.25))
	box.add_child(menu_est_lbl)
	menu_title(box, "Ход игры")
	opt_slider(box, "Политические события", "Как часто случаются события, требующие вашего решения.", 0.0, 3.0, 0.1, float(game_opts["ev"]), fmt_mult, func(x: float) -> void: game_opts["ev"] = x)
	opt_slider(box, "Новости", "Как часто в журнале появляются новости (без выбора).", 0.0, 3.0, 0.1, float(game_opts["news"]), fmt_mult, func(x: float) -> void: game_opts["news"] = x)
	opt_slider(box, "Экономические потрясения", "Кризисы, скачки цен на сырьё, торговые войны. «Нет» — события об экономике не выпадают.", 0.0, 3.0, 0.25, float(game_opts["econ"]), fmt_mult, func(x: float) -> void: game_opts["econ"] = x)
	opt_slider(box, "Колебания цен на товары", "Случайные скачки цен на продукты, топливо, лекарства, жильё и прочие товары.", 0.0, 4.0, 0.1, float(game_opts["volat"]), fmt_mult, func(x: float) -> void: game_opts["volat"] = x)
	opt_choice(box, "Требования регионов", "Регионы с растущим недовольством сами выдвигают требования об автономии (их можно принять или отклонить). «Нет» — регионы молчат, всё решаете вы.", ["Нет", "Да"], clampi(int(game_opts["fedev"]), 0, 1), func(i: int) -> void: game_opts["fedev"] = i)
	opt_choice(box, "Живая демография (религии, миграция)", "«Да» — религиозный состав и миграция меняются сами (рождаемость, секуляризация, волны беженцев, события). «Нет» — меняется только от ваших решений.", ["Нет, только мои решения", "Да"], clampi(int(game_opts["socev"]), 0, 1), func(i: int) -> void: game_opts["socev"] = i)
	opt_choice(box, "Давление партнёров", "Другие страны сами вводят пошлины, предлагают соглашения, поднимают цены на энергию и просят помощи.", ["Нет", "Да"], clampi(int(game_opts["exev"]), 0, 1), func(i: int) -> void: game_opts["exev"] = i)
	opt_choice(box, "Военные угрозы и происшествия на море", "«Да» — соседи с очень плохими отношениями и сильной армией могут сами напасть на вас; на морских путях случаются штормы, аварии и нападения. «Нет» — войны начинаете только вы, море спокойно.", ["Нет", "Да"], clampi(int(game_opts.get("milev", 1)), 0, 1), func(i: int) -> void: game_opts["milev"] = i)
	opt_choice(box, "Кризисы: протесты, сепаратизм, перевороты", "Недовольство регионов растёт в стадии: протесты, беспорядки, мятеж; возможны референдумы о независимости, войны за отделение, революция, гражданская война и перевороты. «Нет» — ничего этого нет. «Часто» — кризисы случаются заметно чаще.", ["Нет", "Обычно", "Часто"], clampi(int(game_opts.get("revev", 1)), 0, 2), func(i: int) -> void: game_opts["revev"] = i)
	opt_choice(box, "Государство и мир: блоки, демография, энергия, коррупция, СМИ", "«Да» — работают членство в ЕС/НАТО/евро/Шенгене, старение и пенсии, цены на энергию и климат, коррупция и суды, свобода СМИ, выравнивание регионов, дипломатия и разведка. «Нет» — этого нет.", ["Нет", "Да"], clampi(int(game_opts.get("rlev", 1)), 0, 1), func(i: int) -> void: game_opts["rlev"] = i)
	opt_choice(box, "Стройка корпораций и других стран", "«Да» — корпорации сами строят заводы и сооружения в ваших регионах, другие страны строят своё и свои мегапроекты, изношенные сооружения могут попасть в аварию. «Нет» — строите только вы.", ["Нет", "Да"], clampi(int(game_opts.get("bldev", 1)), 0, 1), func(i: int) -> void: game_opts["bldev"] = i)
	opt_choice(box, "Коалиция после выборов", "«Вручную» — если у вашей партии нет большинства, вы сами ведёте переговоры: кого пригласить, что пообещать, какие министерства отдать. «Автоматически» — партнёров подбирает ИИ, как раньше.", ["Автоматически", "Вручную"], clampi(int(game_opts.get("coal", 1)), 0, 1), func(i: int) -> void: game_opts["coal"] = i)
	opt_choice(box, "Подсказки для новичка", "Короткий тур по окнам игры в начале партии. Его можно пропустить или запустить снова в окне «Государство → Игра».", ["Нет", "Да"], clampi(int(game_opts.get("tut", 1)), 0, 1), func(i: int) -> void: game_opts["tut"] = i)
	opt_slider(box, "Громкость музыки", "Спокойная фоновая музыка. 0 — выключена. Свои треки (*.ogg) можно положить в папку audio/music проекта.", 0.0, 1.0, 0.05, float(game_opts.get("music", 0.45)), func(x: float) -> String: return "%.0f%%" % (x * 100.0), func(x: float) -> void:
		game_opts["music"] = x
		audio_apply_volume())
	opt_slider(box, "Громкость звуков", "Тихие звуки интерфейса: события, выборы, принятые и проваленные законы.", 0.0, 1.0, 0.05, float(game_opts.get("sfx", 0.6)), func(x: float) -> String: return "%.0f%%" % (x * 100.0), func(x: float) -> void:
		game_opts["sfx"] = x
		audio_apply_volume())
	opt_slider(box, "Стартовый политический капитал", "Запас капитала для коалиций, законов и действий в первый месяц.", 0.3, 3.0, 0.1, float(game_opts["cap"]), fmt_mult, func(x: float) -> void: game_opts["cap"] = x)
	menu_title(box, "Воспроизводимость и интерфейс")
	opt_row(box, "Зерно случайности", "Одно и то же число даёт одну и ту же последовательность случайных событий. Пусто — каждый раз по-разному.")
	var le := LineEdit.new()
	le.placeholder_text = "случайно"
	le.text = "" if int(game_opts["seed"]) <= 0 else str(int(game_opts["seed"]))
	le.max_length = 9
	le.tooltip_text = "Число от 1 до 999999999. Пусто — случайно."
	le.text_changed.connect(func(t: String) -> void: game_opts["seed"] = int(t) if t.is_valid_int() and int(t) > 0 else 0)
	box.add_child(le)
	var rs := Button.new()
	rs.text = "Сбросить все настройки"
	rs.focus_mode = Control.FOCUS_NONE
	rs.pressed.connect(func() -> void:
		game_opts.merge({"agents": true, "k": 0, "seed": 0, "ev": 1.0, "news": 1.0, "econ": 1, "volat": 1.0, "cap": 1.0, "detail": false, "fedev": 1, "socev": 1, "exev": 1, "milev": 1, "revev": 1, "rlev": 1, "bldev": 1, "tut": 1, "coal": 1}, true)
		for ch in sc.get_children():
			ch.queue_free()
		build_settings_panel(sc)
		menu_update_est())
	box.add_child(rs)
	menu_update_est()


# параметры запуска для тестов: agents=0|1 k=250 ev=1.6 news=1 econ=0|1|2 volat=2 cap=1.6 hints=1 gseed=N
func opts_from_args() -> void:
	var tut_given := false
	var coal_given := false
	var test_run := false
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("tut="):
			tut_given = true
		if String(a).begins_with("coal="):
			coal_given = true
		if String(a).begins_with("country="):
			test_run = true
	if test_run and not tut_given:
		game_opts["tut"] = 0   # в тестах подсказки новичка не мешают щелчкам
	if test_run and not coal_given:
		game_opts["coal"] = 0  # v53: в тестах коалицию после выборов собирает ИИ (coal=1 — вручную)
	for a in OS.get_cmdline_user_args():
		var t := String(a)
		if not t.contains("="):
			continue
		var kv := t.split("=", true, 1)
		match kv[0]:
			"agents": game_opts["agents"] = kv[1] != "0"
			"k": game_opts["k"] = int(kv[1])
			"ev": game_opts["ev"] = float(kv[1])
			"news": game_opts["news"] = float(kv[1])
			"econ": game_opts["econ"] = float(kv[1])
			"volat": game_opts["volat"] = float(kv[1])
			"cap": game_opts["cap"] = float(kv[1])
			"hints": game_opts["detail"] = kv[1] != "0"
			"gseed": game_opts["seed"] = int(kv[1])
			"fedev": game_opts["fedev"] = int(kv[1])
			"socev": game_opts["socev"] = int(kv[1])
			"exev": game_opts["exev"] = int(kv[1])
			"milev": game_opts["milev"] = int(kv[1])
			"revev": game_opts["revev"] = int(kv[1])
			"rlev": game_opts["rlev"] = int(kv[1])
			"bldev": game_opts["bldev"] = int(kv[1])
			"tut": game_opts["tut"] = int(kv[1])
			"coal": game_opts["coal"] = int(kv[1])
			"observer": game_opts["observer"] = kv[1] != "0"


func show_country_menu(in_game: bool) -> void:
	var ov := ColorRect.new()
	ov.color = Color(0.04, 0.06, 0.10, 1.0 if not in_game else 0.97)
	ov.name = "CountryMenu"
	add_child(ov)
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# v45_1: глубокий градиент и мягкое сияние за заголовком
	ov.draw.connect(func() -> void:
		Gfx.vgrad(ov, Rect2(Vector2.ZERO, ov.size), Color(0.06, 0.09, 0.16, 0.0), Color(0.0, 0.0, 0.02, 0.55))
		var cx: float = ov.size.x * 0.5
		for k in 6:
			var rr: float = 60.0 + float(k) * 55.0
			ov.draw_circle(Vector2(cx, 20.0), rr, Color(0.30, 0.50, 0.95, 0.018)))
	var mg := MarginContainer.new()
	for k in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		mg.add_theme_constant_override(k, 16)
	ov.add_child(mg)
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var root_v := VBoxContainer.new()
	root_v.add_theme_constant_override("separation", 8)
	mg.add_child(root_v)
	var title := Label.new()
	title.text = "Symphony — выберите страну на карте"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0))
	title.add_theme_constant_override("outline_size", 6)
	title.add_theme_color_override("font_outline_color", Color(0.10, 0.20, 0.45, 0.85))
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_v.add_child(title)
	var sub := Label.new()
	sub.text = "Щёлкните по стране (колёсико — масштаб, перетаскивание — сдвиг карты). Параметры игры — на вкладке «Настройки игры» справа. У каждой страны своя политика, парламент, партии, законы, события и экономика; остальные страны живут сами и влияют на вашу." if not in_game else "Смена страны начнёт новую игру: текущий прогресс будет потерян."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_color_override("font_color", C_DIM)
	root_v.add_child(sub)
	# v54_1: язык игры (русская и английская версии — разные деревья скриптов, смена перезапускает меню)
	var boot = load("res://boot.gd")
	var lang_row := HBoxContainer.new()
	lang_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root_v.add_child(lang_row)
	var lang_lb := Label.new()
	lang_lb.text = "🌐"
	lang_row.add_child(lang_lb)
	var lang_pick := OptionButton.new()
	lang_pick.name = "LangPick"
	var cur_lang: String = boot.lang()
	for i in boot.LANGS.size():
		lang_pick.add_item(String(boot.LANGS[i][1]), i)
		if String(boot.LANGS[i][0]) == cur_lang:
			lang_pick.select(i)
	lang_pick.item_selected.connect(func(i: int):
		boot.set_lang(String(boot.LANGS[i][0]))
		get_tree().reload_current_scene())
	lang_row.add_child(lang_pick)
	var hs := HBoxContainer.new()
	hs.add_theme_constant_override("separation", 12)
	hs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_v.add_child(hs)
	# карта
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.55
	hs.add_child(left)
	var cmap := CountryMap.new()
	var codes: Array = WORLD.keys().filter(func(c) -> bool: return CDATA.has(c))
	for code in codes:
		var inf: Dictionary = CDATA[code]["INFO"] if CDATA[code].has("INFO") else INFO
		cmap.cols[code] = diff_color(int(inf["difficulty"]))
		cmap.names[code] = String(WORLD[code]["name"])
		cmap.tips[code] = "%s — %s\nСложность %s · %.1f млн чел." % [WORLD[code]["name"], WORLD[code]["cap"], "★".repeat(int(inf["difficulty"])), float(inf["pop"])]
	# v49: непризнанные образования (ПМР, ДНР, ЛНР) видны на карте, но не выбираются
	var mtips := {}
	for mc in WORLD.keys():
		if w_unrec(String(mc)):
			var mw: Dictionary = WORLD[mc]
			mtips[mc] = "%s — непризнанное образование\nПод контролем: %s. Международно признано территорией: %s.\nИграть за него нельзя." % [mw["name"], WORLD[mw["patron"]]["name"] if WORLD.has(mw["patron"]) else "?", WORLD[mw["claim"]]["name"] if WORLD.has(mw["claim"]) else "?"]
	cmap.setup(WORLD_UNITS, WORLD_CTX, codes, mtips)
	left.add_child(cmap)
	var leg := HBoxContainer.new()
	leg.add_theme_constant_override("separation", 8)
	leg.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_child(leg)
	var ll := Label.new()
	ll.text = "Сложность:"
	ll.add_theme_color_override("font_color", C_DIM)
	leg.add_child(ll)
	for d in range(1, 6):
		var sq := ColorRect.new()
		sq.color = diff_color(d)
		sq.custom_minimum_size = Vector2(14.0, 14.0)
		sq.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		leg.add_child(sq)
		var dl := Label.new()
		dl.text = "★".repeat(d)
		dl.add_theme_font_size_override("font_size", 12)
		leg.add_child(dl)
	# карточка
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_stretch_ratio = 1.0
	card.custom_minimum_size = Vector2(440.0, 0.0)
	card.add_theme_stylebox_override("panel", sbox(C_PANEL, C_BORDER, 1, 10, 14.0, 12.0))
	hs.add_child(card)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 6)
	card.add_child(cv)
	# v49: флаг страны рядом с названием
	var nmh := HBoxContainer.new()
	nmh.add_theme_constant_override("separation", 10)
	cv.add_child(nmh)
	var mflag: TextureRect = Flags.make("DE", 30.0)
	mflag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nmh.add_child(mflag)
	var nm := Label.new()
	nm.add_theme_font_size_override("font_size", 26)
	nmh.add_child(nm)
	var st := Label.new()
	st.add_theme_font_size_override("font_size", 14)
	cv.add_child(st)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cv.add_child(tabs)
	var sc := ScrollContainer.new()
	sc.name = "Страна"
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(sc)
	var ssc := ScrollContainer.new()
	ssc.name = "Настройки игры"
	ssc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ssc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(ssc)
	build_settings_panel(ssc)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(body)
	var pl := Label.new()
	pl.text = "Играть за партию:"
	pl.add_theme_color_override("font_color", C_DIM)
	cv.add_child(pl)
	var pick := OptionButton.new()
	pick.custom_minimum_size = Vector2(0.0, 32.0)
	# v49: длинное название партии не раздвигает карточку (обрезается с «…», полное — в списке)
	pick.clip_text = true
	pick.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	cv.add_child(pick)
	var play := Button.new()
	play.theme_type_variation = "AccentButton"
	play.custom_minimum_size = Vector2(0.0, 44.0)
	cv.add_child(play)
	var cur_code := [""]
	cmap.picked.connect(func(code: String) -> void:
		cur_code[0] = code
		menu_est_code = code
		menu_update_est()
		fill_country_card(code, body, nm, st)
		mflag.texture = Flags.tex(code)
		mflag.modulate.a = 0.0
		mflag.create_tween().tween_property(mflag, "modulate:a", 1.0, 0.25)
		fill_party_pick(code, pick)
		update_menu_party(pick.get_selected_id())
		play.text = "Играть: %s" % String(WORLD[code]["name"])
		sc.scroll_vertical = 0)
	pick.item_selected.connect(func(i: int) -> void: update_menu_party(pick.get_item_id(i)))
	play.pressed.connect(func() -> void:
		if cur_code[0] != "":
			choose_country(cur_code[0], int(pick.get_selected_id())))
	if in_game:
		var cb := Button.new()
		cb.text = "Отмена"
		cb.custom_minimum_size = Vector2(0.0, 32.0)
		cb.pressed.connect(func() -> void: ov.queue_free())
		root_v.add_child(cb)
	cmap.select(ccode if (in_game and ccode != "") else "DE")


# список партий страны для выбора: ваша по умолчанию, остальные — с указанием положения
const OBSERVER_ID := 99


func fill_party_pick(code: String, ob: OptionButton) -> void:
	ob.clear()
	var pnames: Array = cdat(code, "PARTY_NAMES")
	var pseats: Array = cdat(code, "DE_START_SEATS")
	var coal: Array = cdat(code, "COALITION0")
	for p in pnames.size():
		if p in [6, 8, 9]:
			continue
		var sv: int = int(pseats[p]) if p < pseats.size() else 0
		var stt := ""
		if p == 0:
			stt = "у власти (по умолчанию)"
		elif p in coal:
			stt = "в коалиции, %d мест" % sv
		elif sv > 0:
			stt = "оппозиция, %d мест" % sv
		else:
			stt = "вне парламента"
		ob.add_item("%s — %s" % [qn(String(pnames[p]).replace(" (вы)", "")), stt], p)
	ob.add_item("Никем — наблюдать за игрой (всеми партиями управляет ИИ)", OBSERVER_ID)
	ob.select(0)


# v35: описание политической ситуации для выбранной партии
func update_menu_party(p: int) -> void:
	if menu_sit_rt == null or not is_instance_valid(menu_sit_rt) or menu_sit_code == "":
		return
	var code := menu_sit_code
	var pnames: Array = cdat(code, "PARTY_NAMES")
	var pleaders: Array = cdat(code, "PARTY_LEADERS")
	var pseats: Array = cdat(code, "DE_START_SEATS")
	var pdesc: Array = cdat(code, "PARTY_DESC")
	var traits: Array = cdat(code, "PARTY_TRAITS")
	var coal: Array = cdat(code, "COALITION0")
	var seats_n: int = 630 if code == "DE" else int(cdat(code, "SEATS"))
	var elec: Dictionary = ELEC_DATA.get(code, ELEC_DATA["DE"])
	var gov: Array = coal
	var gs := 0
	for q in gov:
		gs += int(pseats[q]) if q < pseats.size() else 0
	if p == OBSERVER_ID:
		menu_sit_rt.text = "Вы не управляете ни одной партией. Правительство (%s, %d мест из %d) и оппозиция действуют сами: ИИ принимает бюджет, законы, решения по событиям и формирует коалиции после выборов. Время можно ускорять, ставить на паузу пробелом и смотреть любые экраны." % [", ".join(PackedStringArray(gov.map(func(q): return String(pnames[q])))), gs, seats_n]
		return
	var sv: int = int(pseats[p]) if p < pseats.size() else 0
	var nm: String = String(pnames[p])
	var t := "[b]«%s»[/b], лидер — %s. %d мест из %d.\n" % [nm, String(pleaders[p]).replace(" (вы)", "").replace("Канцлер", "вы"), sv, seats_n]
	if p < pdesc.size() and String(pdesc[p]) != "":
		t += "[color=#98a1b8]%s[/color]\n" % String(pdesc[p]).replace("Ваша партия — ", "")
	if p == 0:
		var big := true
		for q in coal:
			if q != 0 and int(pseats[q]) > sv:
				big = false
		t += "[color=%s]Вы во главе правительства[/color]%s. Коалиция: %d мест из %d — %s. Задача: удержать партнёров, провести свою программу и выиграть следующие выборы (%s)." % [COL_GOOD, "" if big else " (но партнёр крупнее вас)", gs, seats_n, "большинство есть" if gs * 2 > seats_n else "большинства нет, правительство держится на терпимости", String(elec.get("sys", ""))]
	elif p in coal:
		t += "[color=%s]Вы младший партнёр в коалиции «%s»[/color]. Влияние в правительстве — %.0f%% мест коалиции: бюджет, кабинет и решения по событиям проходят через совет коалиции, где решает большинство. Капитал растёт медленнее, зато его хватает на свои законы и торг." % [COL_WARN, String(pnames[0]), float(sv) / float(maxi(1, gs)) * 100.0]
	elif sv > 0:
		t += "[color=%s]Вы в оппозиции[/color] к правительству «%s» (%d мест). Критикуйте власть, договаривайтесь с другими партиями, вносите законопроекты и готовьтесь к выборам — или соберите альтернативное большинство." % [COL_WARN, String(pnames[0]), gs]
	else:
		t += "[color=%s]Партии нет в парламенте.[/color] Нужно преодолеть барьер на следующих выборах: союзы и блоки с другими партиями помогут." % COL_BAD
	if p < traits.size() and float((traits[p] as Dictionary).get("join", 0.0)) <= -50.0:
		t += "\n[color=%s]Вокруг вас «санитарный кордон»: другие партии не хотят с вами коалиций. Он ослабевает при хороших отношениях, щедрых обещаниях или затяжном кризисе.[/color]" % COL_WARN
	menu_sit_rt.text = t


func choose_country(code: String, party: int = 0) -> void:
	pending_code = code
	game_opts["observer"] = party == OBSERVER_ID
	pending_party = 0 if party == OBSERVER_ID else party
	get_tree().reload_current_scene()


func _ready() -> void:
	de_base_snap()
	opts_from_args()
	var sd := seed_arg()
	if sd < 0 and int(game_opts["seed"]) > 0:
		sd = int(game_opts["seed"])
	if sd >= 0:
		seed(sd)
	else:
		randomize()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_load()
	settings_apply_static()
	theme = make_theme()
	audio_init()
	var win := get_window()
	win.min_size = Vector2i(1340, 700)
	if DisplayServer.get_name() != "headless":
		var scr := DisplayServer.screen_get_size()
		if scr.x >= 1400 and win.mode == Window.MODE_WINDOWED:
			win.size = Vector2i(int(scr.x * 0.92), int(scr.y * 0.88))
			win.position = (scr - win.size) / 2
	var code0 := country_arg()
	if code0 == "":
		code0 = pending_code
	if code0 == "" and DisplayServer.get_name() != "headless":
		show_country_menu(false)
		return
	if code0 == "":
		code0 = "DE"
	apply_country(code0)
	ag_on = bool(game_opts["agents"])
	ag_k_pref = int(game_opts["k"])
	ui_detail = true   # v35: пояснения и подробные таблицы всегда показаны (кнопка ⓘ убрана)
	init_state()
	capital *= float(game_opts["cap"])
	build_geometry()
	build_hemicycle()
	build_ui()
	loc_tree(self)
	log_header("Начало игры", COL_HEAD)
	if ccode != "DE":
		log_sys("[b][color=%s]Вы — %s, январь 2026.[/color][/b] %s" % [COL_HEAD, tm("head_role").to_lower(), String(INFO.get("blurb", ""))])
		log_sys("Время идёт по дням: скорость задают кнопки справа вверху, а экономика и политика считаются на границе месяцев. Налоги и расходы настраиваются на экране «Бюджет»; законы, коалиции и выборы — на экране «Политика»; страна и регионы — на экране «Карта»; соседи и мир — там же, слоем «Дипломатия». Выборы в %s пройдут через %s. %s, %s." % [tm("parl_in").replace("во ", "").replace("в ", ""), months_text(parl_term() - (turn - last_parl)),
			"Ставку задаёт ЕЦБ" if bool(MACRO.get("euro", true)) else "Ставку задаёт национальный центробанк",
			"действуют бюджетные правила ЕС" if bool(MACRO.get("eu", true)) else "действуют свои бюджетные правила"])
	if ccode == "DE": log_sys("[b][color=%s]Вы — федеральный канцлер Германии, январь 2026.[/color][/b] Время идёт по дням: скорость задают кнопки справа вверху, а экономика и политика считаются на границе месяцев. Налоги и расходы настраиваются на экране «Бюджет»; законы, коалиции и выборы — на экране «Политика»; земли — на экране «Карта земель»; соседи — на экране «Дипломатия»." % COL_HEAD)
	if ccode == "DE": log_sys("Окна можно двигать за заголовок и менять им размер за край или угол. Выборы в Бундестаг пройдут через 3 года (%s %d). Валюта — евро, ставку задаёт ЕЦБ, действует долговой тормоз." % [MONTHS[0], START_YEAR + 3])
	log_sys("Ваша партия — %s. Для принятия законов нужна коалиция, у которой не меньше %d мест из %d." % [qn(PARTY_NAMES[0]), MAJORITY, SEATS])
	# v38: для стран без евро (Польша, Сербия, Румыния…) не писать про ЕЦБ
	log_sys("Совет: кнопка рядом с названием каждого ползунка переключает его между долей ВВП и суммой в млрд. %s" % ("Эмиссии нет: деньги печатает ЕЦБ." if bool(MACRO.get("euro", true)) else "Своя валюта: эмиссия на экране «Бюджет» даёт деньги, но разгоняет инфляцию."))
	log_sys("[b]Правительство:[/b] у министров есть имена, навыки и бонусы, которые зависят от партии. Откройте «Политика» → «Правительство».")
	log_sys("[b]Законы устроены иначе:[/b] у каждого закона есть действующий вариант и альтернативы, которые можно менять друг на друга. Откройте «Политика» → «Законы».")
	log_sys("[b]Экономика устроена глубже:[/b] отрасли со спросом и мощностью, покупательная способность людей, желание бизнеса инвестировать, центробанк, внешняя торговля и сооружения. Откройте вкладку «Экономика».")
	if bool(game_opts.get("observer", false)):
		observer_start()
	show_desk(2)
	refresh()
	call_deferred("layout_windows")
	# v50: стартовое окно перед игрой
	if not bool(game_opts.get("observer", false)):
		call_deferred("show_start_window")


# v35: пробел — пауза / пуск времени (если фокус не в поле ввода и не открыто меню стран)
func _input(e: InputEvent) -> void:
	if not (e is InputEventKey):
		return
	var ke := e as InputEventKey
	if not ke.pressed or ke.echo or ke.keycode != KEY_SPACE or election_open or has_node("CountryMenu"):
		return
	if start_ov != null or (st_ov != null and st_ov.visible):
		return
	if play_btn == null or game_over:
		return
	var fo := get_viewport().gui_get_focus_owner()
	if fo is LineEdit or fo is TextEdit:
		return
	on_play_toggled(play_idx <= 0)
	get_viewport().set_input_as_handled()


func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey):
		return
	var ke := e as InputEventKey
	if not ke.pressed or ke.echo:
		return
	var k: int = ke.keycode
	if election_open:
		if k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_SPACE:
			election_continue()
			get_viewport().set_input_as_handled()
		return
	if current_event.is_empty() or not wins.has("event") or not (wins["event"] as FloatWindow).visible:
		return
	var idx := -1
	if k >= KEY_1 and k <= KEY_4:
		idx = k - KEY_1
	elif k >= KEY_KP_1 and k <= KEY_KP_4:
		idx = k - KEY_KP_1
	if idx >= 0 and idx < (current_event["o"] as Array).size():
		choose(idx)
		get_viewport().set_input_as_handled()
