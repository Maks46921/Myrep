# Symphony: корневой скрипт (вершина цепочки наследования, см. scripts/CHAIN.txt).
# Политико-экономическая игра, версия 8 (новая система коалиций).
# Время идёт по дням: скорость задают кнопки справа вверху, а экономика и политика считаются на границе месяцев. Три экрана: «Бюджет», «Политика», «Карта регионов».
# Все окна плавающие: двигайте за заголовок, меняйте размер за правый/нижний край и угол,
# двойной щелчок по заголовку (или кнопка «–») сворачивает окно.
# Весь интерфейс создаётся кодом. Повесьте скрипт на корневой узел Control (Godot 4.x).
extends "res://scripts/ui/ui_rules.gd"

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
	# 0.55.4: необязательные ключи пакета страны — сброс, чтобы не остались от прошлой страны
	MAJ_BASE = 0
	PROTEST_P = 9
	REGIONAL_P = 8
	LAW_START = {}
	AID0 = 0.0
	AID_NOTE = ""
	REG_INDEX = ""
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
	var mb: int = int(MAJ_BASE) if int(MAJ_BASE) > SEATS else SEATS
	MAJORITY = mb / 2 + 1
	SUPER = int(ceil(float(mb) * 2.0 / 3.0))
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
	# 0.55.4: страна с темой «Режим военного положения» (Украина) начинает при военном положении
	martial = false
	for t in LAW_TOPICS:
		if String(t["id"]) == "martial_law":
			martial = true
	build_loc()
	apply_player_party(party_arg())
	if not get_window() == null:
		get_window().title = "Symphony %s: %s" % [game_version(), String(WORLD[code]["name"])]


# 0.55.4: номер версии вида 0.55.4 — из project.godot (application/config/version)
func game_version() -> String:
	return String(ProjectSettings.get_setting("application/config/version", ""))


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
	title.text = "Symphony %s — выберите страну на карте" % game_version()
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
		cmap.names[code] = String(WORLD[code]["name"])
		cmap.tips[code] = "%s — %s\nСложность %s · %.1f млн чел. · ВВП %.0f млрд\n%s%s · %s" % [WORLD[code]["name"], WORLD[code]["cap"], "★".repeat(int(inf["difficulty"])), float(inf["pop"]), menu_gdp(code),
			"член ЕС" if menu_in_org(code, "eu") else "вне ЕС", " · НАТО" if menu_in_org(code, "nato") else "", String(MENU_GOVFORM_N[menu_govform(code)])]
	# 0.56: фильтры над картой и раскраска «как на политической карте»
	var flt_row := HFlowContainer.new()
	flt_row.add_theme_constant_override("h_separation", 6)
	flt_row.add_theme_constant_override("v_separation", 4)
	flt_row.alignment = FlowContainer.ALIGNMENT_CENTER
	left.add_child(flt_row)
	for fk in MENU_FILTERS:
		var fob := OptionButton.new()
		fob.focus_mode = Control.FOCUS_NONE
		fob.add_theme_font_size_override("font_size", 13)
		var items: Array = fk[2]
		for i in items.size():
			fob.add_item(String(items[i]), i)
		fob.select(int(menu_flt.get(fk[0], 0)))
		fob.tooltip_text = String(fk[1])
		var fkey: String = String(fk[0])
		fob.item_selected.connect(func(i: int) -> void:
			menu_flt[fkey] = i
			menu_apply_filters(cmap, codes))
		flt_row.add_child(fob)
	menu_apply_filters(cmap, codes)
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
	menu_leg = leg
	leg.visible = int(menu_flt.get("col", 0)) == 1
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
	# 0.56: вкладка «Партия» — полукруг парламента и карточки партий
	var psc := ScrollContainer.new()
	psc.name = "Партия"
	psc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	psc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(psc)
	var pv := VBoxContainer.new()
	pv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pv.add_theme_constant_override("separation", 6)
	psc.add_child(pv)
	menu_hemi = PartyHemi.new()
	pv.add_child(menu_hemi)
	menu_party_grid = GridContainer.new()
	menu_party_grid.columns = 2
	menu_party_grid.add_theme_constant_override("h_separation", 6)
	menu_party_grid.add_theme_constant_override("v_separation", 6)
	menu_party_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pv.add_child(menu_party_grid)
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
	# 0.56: выбранная партия и кнопка перехода к карточкам партий
	var prow := HBoxContainer.new()
	prow.add_theme_constant_override("separation", 8)
	cv.add_child(prow)
	menu_party_lbl = RichTextLabel.new()
	menu_party_lbl.bbcode_enabled = true
	menu_party_lbl.fit_content = true
	menu_party_lbl.scroll_active = false
	menu_party_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_party_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_party_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prow.add_child(menu_party_lbl)
	var pbtn := Button.new()
	pbtn.text = "Выбрать партию…"
	pbtn.focus_mode = Control.FOCUS_NONE
	pbtn.tooltip_text = "Играть можно за любую партию: правящую, партнёра по коалиции, оппозицию, партию вне парламента, региональную или протестную."
	pbtn.pressed.connect(func() -> void: tabs.current_tab = 1)
	prow.add_child(pbtn)
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
		menu_fill_parties(code, 0)
		play.text = "Играть: %s" % String(WORLD[code]["name"])
		sc.scroll_vertical = 0)
	menu_hemi.picked.connect(func(p: int) -> void: menu_fill_parties(menu_sit_code, p))
	play.pressed.connect(func() -> void:
		if cur_code[0] != "":
			choose_country(cur_code[0], menu_party_sel))
	if in_game:
		var cb := Button.new()
		cb.text = "Отмена"
		cb.custom_minimum_size = Vector2(0.0, 32.0)
		cb.pressed.connect(func() -> void: ov.queue_free())
		root_v.add_child(cb)
	cmap.select(ccode if (in_game and ccode != "") else "DE")


# список партий страны для выбора: ваша по умолчанию, остальные — с указанием положения
const OBSERVER_ID := 99


# ============================================================
#  0.56: МЕНЮ — ЦВЕТА ПОЛИТИЧЕСКОЙ КАРТЫ, ФИЛЬТРЫ СТРАН, ВЫБОР ПАРТИИ КАРТОЧКАМИ
# ============================================================
const MENU_POL_COLS := {
	"DE": Color(0.47, 0.49, 0.53), "FR": Color(0.32, 0.45, 0.76), "NL": Color(0.86, 0.56, 0.26), "BE": Color(0.80, 0.70, 0.32),
	"LU": Color(0.47, 0.72, 0.86), "CH": Color(0.76, 0.33, 0.31), "AT": Color(0.74, 0.69, 0.62), "PL": Color(0.80, 0.43, 0.50),
	"CZ": Color(0.36, 0.56, 0.76), "DK": Color(0.72, 0.36, 0.31), "NO": Color(0.62, 0.29, 0.36), "SE": Color(0.46, 0.63, 0.88),
	"IT": Color(0.41, 0.66, 0.41), "ES": Color(0.86, 0.73, 0.31), "PT": Color(0.27, 0.53, 0.39), "GB": Color(0.79, 0.31, 0.36),
	"IE": Color(0.47, 0.76, 0.46), "SI": Color(0.56, 0.73, 0.61), "SK": Color(0.57, 0.52, 0.77), "HU": Color(0.81, 0.56, 0.41),
	"FI": Color(0.79, 0.81, 0.87), "HR": Color(0.41, 0.51, 0.79), "RS": Color(0.63, 0.36, 0.31), "BA": Color(0.81, 0.71, 0.41),
	"ME": Color(0.66, 0.46, 0.31), "MK": Color(0.86, 0.56, 0.31), "AL": Color(0.71, 0.31, 0.41), "XK": Color(0.46, 0.61, 0.81),
	"BG": Color(0.46, 0.63, 0.43), "RO": Color(0.81, 0.71, 0.31), "GR": Color(0.41, 0.66, 0.86), "EE": Color(0.41, 0.56, 0.81),
	"LV": Color(0.66, 0.36, 0.41), "LT": Color(0.81, 0.71, 0.36), "MD": Color(0.71, 0.51, 0.36), "BY": Color(0.63, 0.76, 0.46),
	"UA": Color(0.46, 0.61, 0.86), "RU": Color(0.31, 0.53, 0.37),
}
const MENU_GOVFORM := {"GB": 2, "NL": 2, "BE": 2, "LU": 2, "DK": 2, "NO": 2, "SE": 2, "ES": 2,
	"FR": 1, "PT": 1, "RO": 1, "LT": 1, "UA": 1, "PL": 1, "RU": 3, "BY": 3}
const MENU_GOVFORM_N := ["парламентская республика", "полупрезидентская республика", "конституционная монархия", "авторитарный режим"]
const MENU_FILTERS := [
	["diff", "Сложность страны", ["Сложность: все", "Сложность: ★–★★", "Сложность: ★★★", "Сложность: ★★★★", "Сложность: ★★★★★"]],
	["eu", "Членство в Европейском союзе", ["ЕС: все", "В ЕС", "Вне ЕС"]],
	["nato", "Членство в НАТО", ["НАТО: все", "В НАТО", "Вне НАТО"]],
	["form", "Форма правления (Швейцария — директориальная республика, отнесена к парламентским)", ["Правление: любое", "Парламентская республика", "Полупрезидентская", "Монархия", "Авторитарный режим"]],
	["size", "Размер экономики (ВВП)", ["Экономика: любая", "Крупная (больше 1000 млрд)", "Средняя (100–1000 млрд)", "Малая (меньше 100 млрд)"]],
	["col", "Чем раскрашены страны", ["Цвета: политическая карта", "Цвета: сложность"]],
]
const MENU_ROLE_N := {"head": "во главе правительства", "gov": "в коалиции", "opp": "оппозиция", "out": "вне парламента", "obs": "наблюдатель"}
var menu_flt := {}
var menu_leg: Control = null
var menu_hemi: Control = null
var menu_party_grid: GridContainer = null
var menu_party_lbl: RichTextLabel = null
var menu_party_sel := 0


# тёмные цвета партий (ХДС/ХСС — почти чёрный) на тёмном фоне не видны: осветлить
func menu_vis_col(c: Color) -> Color:
	return c.lightened(0.35) if c.get_luminance() < 0.22 else c


func menu_seats_txt(n: int) -> String:
	var m10 := n % 10
	var m100 := n % 100
	if m10 == 1 and m100 != 11:
		return "%d место" % n
	if m10 >= 2 and m10 <= 4 and (m100 < 12 or m100 > 14):
		return "%d места" % n
	return "%d мест" % n


func menu_gdp(code: String) -> float:
	return float(WORLD[code].get("gdp", 0.0))


func menu_in_org(code: String, org: String) -> bool:
	return ORGS.has(org) and (ORGS[org].get("mem", []) as Array).has(code)


func menu_govform(code: String) -> int:
	return int(MENU_GOVFORM.get(code, 0))


func menu_country_ok(code: String) -> bool:
	var inf: Dictionary = CDATA[code]["INFO"] if CDATA[code].has("INFO") else INFO
	var d: int = int(inf["difficulty"])
	match int(menu_flt.get("diff", 0)):
		1:
			if d > 2: return false
		2:
			if d != 3: return false
		3:
			if d != 4: return false
		4:
			if d != 5: return false
	var fe: int = int(menu_flt.get("eu", 0))
	if fe > 0 and menu_in_org(code, "eu") != (fe == 1):
		return false
	var fn: int = int(menu_flt.get("nato", 0))
	if fn > 0 and menu_in_org(code, "nato") != (fn == 1):
		return false
	var ff: int = int(menu_flt.get("form", 0))
	if ff > 0 and menu_govform(code) != ff - 1:
		return false
	var g: float = menu_gdp(code)
	match int(menu_flt.get("size", 0)):
		1:
			if g < 1000.0: return false
		2:
			if g < 100.0 or g >= 1000.0: return false
		3:
			if g >= 100.0: return false
	return true


func menu_apply_filters(cmap, codes: Array) -> void:
	var by_diff: bool = int(menu_flt.get("col", 0)) == 1
	cmap.dim.clear()
	for code in codes:
		var inf: Dictionary = CDATA[code]["INFO"] if CDATA[code].has("INFO") else INFO
		cmap.cols[code] = diff_color(int(inf["difficulty"])) if by_diff else (MENU_POL_COLS.get(code, Color(0.5, 0.55, 0.65)) as Color)
		if not menu_country_ok(String(code)):
			cmap.dim[code] = true
	if menu_leg != null and is_instance_valid(menu_leg):
		menu_leg.visible = by_diff
	cmap.recolor()


# партии страны для карточек: слот, имя, лидер, цвет, места, рейтинг ≈, положение слева направо, роль, сложность
func menu_party_rows(code: String) -> Array:
	var pnames: Array = cdat(code, "PARTY_NAMES")
	var pseats: Array = cdat(code, "DE_START_SEATS")
	var pcols: Array = cdat(code, "PARTY_COLORS")
	var pleaders: Array = cdat(code, "PARTY_LEADERS")
	var coal: Array = cdat(code, "COALITION0")
	var hemi: Array = cdat(code, "HEMI_ORDER")
	var lean: Dictionary = cdat(code, "LEAN")
	var gw: Dictionary = cdat(code, "GROUP_WEIGHT")
	var gb: Dictionary = cdat(code, "GROUP_BASE")
	var traits: Array = cdat(code, "PARTY_TRAITS")
	var seats_n: int = 630 if code == "DE" else int(cdat(code, "SEATS"))
	var inf: Dictionary = CDATA[code]["INFO"] if CDATA[code].has("INFO") else INFO
	var cd: int = int(inf["difficulty"])
	var reg: int = int(cdat(code, "REGIONAL_P"))
	# рейтинг на старте: та же основа, что и в выборах (веса групп × близость партии), без региональных поправок
	var raw: Array = []
	var tot := 0.0
	for p in pnames.size():
		var v := 0.0
		for g in gw:
			if not lean.has(g):
				continue
			var la: Array = lean[g]
			var l: float = float(la[p]) if p < la.size() else 0.0
			if p == 0:
				l = 6.0 * pow(float(gb.get(g, 50.0)) / 50.0, 3.0)
			v += l * float(gw[g])
		raw.append(v)
		tot += v
	var out: Array = []
	for p in pnames.size():
		var nm: String = String(pnames[p]).replace(" (вы)", "")
		if p in NO_PLAY_SLOTS or not party_name_playable(nm):
			continue
		var sv: int = int(pseats[p]) if p < pseats.size() else 0
		var role := "out"
		if p == 0:
			role = "head"
		elif p in coal:
			role = "gov"
		elif sv > 0:
			role = "opp"
		var sh: float = float(sv) / float(maxi(1, seats_n))
		var d := cd
		match role:
			"gov":
				d = cd + 1
			"opp":
				d = cd + (1 if sh >= 0.15 else 2)
			"out":
				d = 5
		var cordon: bool = p > 0 and p < traits.size() and float((traits[p] as Dictionary).get("join", 0.0)) <= -50.0
		if cordon:
			d += 1
		var hi: int = hemi.find(p)
		var ld: String = String(pleaders[p]).replace(" (вы)", "").replace("Канцлер", "").strip_edges() if p < pleaders.size() else ""
		out.append({"p": p, "name": nm, "leader": ld, "col": menu_vis_col(pcols[p] if p < pcols.size() else Color(0.5, 0.5, 0.5)), "seats": sv,
			"rate": 100.0 * float(raw[p]) / maxf(0.001, tot), "lr": float(hi) / float(maxi(1, hemi.size() - 1)) if hi >= 0 else 0.5,
			"role": role, "diff": clampi(d, 1, 5), "small": sh < 0.05, "cordon": cordon, "prot": p == 9, "reg": p == reg})
	return out


func menu_fill_parties(code: String, sel: int) -> void:
	if menu_party_grid == null or not is_instance_valid(menu_party_grid) or code == "":
		return
	menu_party_sel = sel
	var rows := menu_party_rows(code)
	if sel != OBSERVER_ID and rows.filter(func(r) -> bool: return int(r["p"]) == sel).is_empty():
		menu_party_sel = 0
	var seats_n: int = 630 if code == "DE" else int(cdat(code, "SEATS"))
	var hemi: Array = cdat(code, "HEMI_ORDER")
	var pnames: Array = cdat(code, "PARTY_NAMES")
	var pseats: Array = cdat(code, "DE_START_SEATS")
	var pcols: Array = cdat(code, "PARTY_COLORS")
	var ord: Array = []
	for p in hemi:
		var sv: int = int(pseats[p]) if int(p) < pseats.size() else 0
		if sv > 0:
			ord.append({"p": int(p), "col": menu_vis_col(pcols[p]), "seats": sv, "name": String(pnames[p]).replace(" (вы)", "")})
	var mb: int = int(CDATA[code].get("MAJ_BASE", 0))
	var mj: int = mb if mb > seats_n else seats_n
	menu_hemi.set_data(ord, seats_n, mj / 2 + 1, menu_party_sel if menu_party_sel != OBSERVER_ID else -1)
	for ch in menu_party_grid.get_children():
		menu_party_grid.remove_child(ch)
		ch.queue_free()
	rows.sort_custom(func(a, b) -> bool: return int(a["seats"]) > int(b["seats"]) if int(a["seats"]) != int(b["seats"]) else float(a["rate"]) > float(b["rate"]))
	for r in rows:
		menu_party_card(r, code)
	menu_party_card({"p": OBSERVER_ID, "name": "Никем — наблюдать", "leader": "", "col": Color(0.45, 0.5, 0.6), "seats": 0, "rate": 0.0, "lr": -1.0, "role": "obs", "diff": 0, "small": false, "cordon": false, "prot": false, "reg": false}, code)
	update_menu_party(menu_party_sel)
	var cur: Dictionary = {}
	for r in rows:
		if int(r["p"]) == menu_party_sel:
			cur = r
	if menu_party_lbl != null:
		if menu_party_sel == OBSERVER_ID:
			menu_party_lbl.text = "[color=#98a1b8]Партия:[/color] [b]никем — наблюдать[/b]"
		elif not cur.is_empty():
			menu_party_lbl.text = "[color=#98a1b8]Партия:[/color] [color=#%s]●[/color] [b]%s[/b] [color=#98a1b8]· %s · сложность %s[/color]" % [(cur["col"] as Color).to_html(false), String(cur["name"]), MENU_ROLE_N[String(cur["role"])], "★".repeat(int(cur["diff"]))]


func menu_party_card(r: Dictionary, code: String) -> void:
	var p: int = int(r["p"])
	var on: bool = p == menu_party_sel
	var col: Color = r["col"]
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.mouse_filter = Control.MOUSE_FILTER_STOP
	pc.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sb := sbox(C_PANEL2 if not on else C_PANEL2.lerp(col, 0.18), col if on else C_BORDER, 2 if on else 1, 8, 8.0, 6.0)
	sb.border_width_left = 4
	sb.border_color = col if on else col.darkened(0.35)
	pc.add_theme_stylebox_override("panel", sb)
	pc.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			menu_fill_parties(code, p))
	menu_party_grid.add_child(pc)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(hb)
	# заглушка портрета: силуэт в цветах партии и инициалы лидера
	var por := Control.new()
	por.custom_minimum_size = Vector2(40.0, 40.0)
	por.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	por.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ini := ""
	for wd in String(r["leader"]).split(" ", false):
		var c0: String = wd.substr(0, 1)
		if ini.length() < 2 and c0 != "(" and c0 == c0.to_upper() and c0 != c0.to_lower():
			ini += c0
	if ini == "":
		ini = "?" if p == OBSERVER_ID else String(r["name"]).substr(0, 1)
	por.draw.connect(func() -> void:
		var c := Vector2(20.0, 20.0)
		por.draw_circle(c, 19.0, col.darkened(0.55))
		por.draw_circle(Vector2(20.0, 15.0), 7.0, col.darkened(0.2))
		por.draw_circle(Vector2(20.0, 34.0), 12.0, col.darkened(0.2))
		por.draw_arc(c, 19.0, 0.0, TAU, 32, col, 2.0, true)
		var f: Font = por.get_theme_default_font()
		por.draw_string_outline(f, Vector2(0.0, 25.0), ini, HORIZONTAL_ALIGNMENT_CENTER, 40.0, 14, 4, Color(0, 0, 0, 0.75))
		por.draw_string(f, Vector2(0.0, 25.0), ini, HORIZONTAL_ALIGNMENT_CENTER, 40.0, 14, Color(1, 1, 1, 0.95)))
	hb.add_child(por)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 1)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(vb)
	var nm := Label.new()
	nm.text = String(r["name"])
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.add_theme_font_size_override("font_size", 13)
	nm.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0) if on else C_TEXT)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(nm)
	var info := RichTextLabel.new()
	info.bbcode_enabled = true
	info.fit_content = true
	info.scroll_active = false
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_theme_font_size_override("normal_font_size", 11)
	info.add_theme_font_size_override("bold_font_size", 11)
	var role: String = String(r["role"])
	var rc: String = String({"head": COL_GOOD, "gov": "#8fd18f", "opp": COL_WARN}.get(role, "#98a1b8"))
	var t := ""
	if p == OBSERVER_ID:
		t = "[color=#98a1b8]Всеми партиями управляет ИИ, вы смотрите за страной.[/color]"
	else:
		if String(r["leader"]) != "":
			t += "[color=#98a1b8]%s[/color]\n" % String(r["leader"])
		t += "[color=%s]%s[/color]" % [rc, MENU_ROLE_N[role]]
		if int(r["seats"]) > 0:
			t += " · %s · ≈%.0f%%" % [menu_seats_txt(int(r["seats"])), float(r["rate"])]
		else:
			t += " · опросы ≈%.0f%%" % float(r["rate"])
		var tags: PackedStringArray = []
		if bool(r["prot"]):
			tags.append("протестная")
		if bool(r["reg"]):
			tags.append("региональная")
		if bool(r["cordon"]):
			tags.append("«санитарный кордон»")
		if not tags.is_empty():
			t += "\n[color=#98a1b8]%s[/color]" % ", ".join(tags)
		t += "\n[color=#%s]%s[/color]" % [diff_color(int(r["diff"])).to_html(false), "★".repeat(int(r["diff"]))]
		if bool(r["small"]) or int(r["diff"]) >= 5:
			t += " [b][color=%s]сложно[/color][/b]" % COL_BAD
	info.text = t
	vb.add_child(info)
	# шкала «левые — правые» (по месту в зале парламента)
	if float(r["lr"]) >= 0.0:
		var lr := Control.new()
		lr.custom_minimum_size = Vector2(0.0, 12.0)
		lr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var x: float = clampf(float(r["lr"]), 0.03, 0.97)
		lr.draw.connect(func() -> void:
			var w: float = lr.size.x
			var n := 24
			for i in n:
				var a: float = float(i) / float(n)
				lr.draw_rect(Rect2(w * a, 5.0, w / float(n) + 0.5, 3.0), Color(0.85, 0.32, 0.32).lerp(Color(0.32, 0.50, 0.90), a).darkened(0.25))
			lr.draw_circle(Vector2(x * w, 6.5), 4.5, Color(1, 1, 1, 0.9))
			lr.draw_circle(Vector2(x * w, 6.5), 3.2, col))
		vb.add_child(lr)


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
	tip_setup()
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
		log_sys("Время идёт по дням: скорость задают кнопки справа вверху, а экономика и политика считаются на границе месяцев. Налоги и расходы настраиваются на экране «Бюджет»; законы, коалиции и выборы — на экране «Политика»; страна и регионы — на экране «Мир»; соседи и мир — там же, слоем «Дипломатия». Выборы в %s пройдут через %s. %s, %s." % [tm("parl_in").replace("во ", "").replace("в ", ""), months_text(parl_term() - (turn - last_parl)),
			"Ставку задаёт ЕЦБ" if bool(MACRO.get("euro", true)) else "Ставку задаёт национальный центробанк",
			"действуют бюджетные правила ЕС" if bool(MACRO.get("eu", true)) else "действуют свои бюджетные правила"])
	if ccode == "DE": log_sys("[b][color=%s]Вы — федеральный канцлер Германии, январь 2026.[/color][/b] Время идёт по дням: скорость задают кнопки справа вверху, а экономика и политика считаются на границе месяцев. Налоги и расходы настраиваются на экране «Бюджет»; законы, коалиции и выборы — на экране «Политика»; земли — на экране «Мир»; соседи — на экране «Дипломатия»." % COL_HEAD)
	if ccode == "DE": log_sys("Окна можно двигать за заголовок и менять им размер за край или угол. Выборы в Бундестаг пройдут через 3 года (%s %d). Валюта — евро, ставку задаёт ЕЦБ, действует долговой тормоз." % [MONTHS[0], START_YEAR + 3])
	log_sys("Ваша партия — %s. Для принятия законов нужна коалиция, у которой не меньше %d мест из %d." % [qn(PARTY_NAMES[0]), MAJORITY, SEATS])
	# v38: для стран без евро (Польша, Сербия, Румыния…) не писать про ЕЦБ
	log_sys("Совет: кнопка рядом с названием каждого ползунка переключает его между долей ВВП и суммой в млрд. %s" % ("Эмиссии нет: деньги печатает ЕЦБ." if bool(MACRO.get("euro", true)) else "Своя валюта: эмиссия на экране «Бюджет» даёт деньги, но разгоняет инфляцию."))
	log_sys("[b]Правительство:[/b] у министров есть имена, навыки и бонусы, которые зависят от партии. Откройте «Политика» → «Правительство».")
	log_sys("[b]Законы устроены иначе:[/b] у каждого закона есть действующий вариант и альтернативы, которые можно менять друг на друга. Откройте «Политика» → «Законы».")
	log_sys("[b]Экономика устроена глубже:[/b] отрасли со спросом и мощностью, покупательная способность людей, желание бизнеса инвестировать, центробанк, внешняя торговля и сооружения. Откройте вкладку «Экономика».")
	if bool(game_opts.get("observer", false)):
		observer_start()
	show_desk(21)    # 0.57: игра открывается на рамке «Сегодня»
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
	# 0.56: пока открыты итоги выборов, пробел ничего не делает — окно закрывается только кнопкой
	if election_open and ke.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		return
	if not ke.pressed or ke.echo or ke.keycode != KEY_SPACE or has_node("CountryMenu"):
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
		return
	if k == KEY_ESCAPE and bld_pick != "":
		bld_cancel()
		get_viewport().set_input_as_handled()
		return
	if current_event.is_empty() or not wins.has("event") or not (wins["event"] as FloatWindow).visible:
		# 0.57: Ctrl+K, Alt+←, клавиши рамок 1–6 и Esc (но не пока ждёт выбор в событии)
		if ui_hotkey(ke):
			get_viewport().set_input_as_handled()
		return
	if k == KEY_K and ke.ctrl_pressed:
		srch_open(true)
		get_viewport().set_input_as_handled()
		return
	var idx := -1
	if k >= KEY_1 and k <= KEY_4:
		idx = k - KEY_1
	elif k >= KEY_KP_1 and k <= KEY_KP_4:
		idx = k - KEY_KP_1
	if idx >= 0 and idx < (current_event["o"] as Array).size():
		choose(idx)
		get_viewport().set_input_as_handled()
