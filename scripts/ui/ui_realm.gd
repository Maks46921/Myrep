# Интерфейс v44_1: «Государство и мир» без отдельного окна — секции встроены в существующие разделы:
#  Бюджет → «Советник и автопилот» (сохранения, откат, справка) · Политика → «Парламент» (парламент и президент),
#  «Законы» (право и СМИ), «Религия и миграция» (демография и пенсии) · Экономика → «Товары и цены» (энергия, история),
#  «Влияние и зависимость» (союзы, договоры, разведка) · Карта → «Регионы и автономия» (выравнивание), «Армия и война» (армия как политический игрок)
#  · оверлей «Кризисы» (вмешательство, мирные конференции, признание) · оверлей «Технологии» (проекты, этика).
# Плюс подсказки для новичка.
extends "res://scripts/ui/ui_crisis.gd"

const TUT_STEPS := [
	"Добро пожаловать! Вверху — разделы «Бюджет», «Экономика», «Политика», «Карта» и окна «Технологии», «Кризисы». Время идёт кнопками справа вверху: «▶» запускает ход, паузой можно остановить.",
	"«Бюджет»: ползунки — налоги и расходы. Меняйте понемногу и смотрите прогноз роста, инфляции и рейтинга. Долг растёт, когда расходы выше доходов.",
	"«Политика»: парламент, законы, правительство, население. Чтобы править, нужно большинство мест. Недовольные партнёры по коалиции могут уйти.",
	"«Карта»: регионы страны. Щёлкните по региону — увидите недовольство и сепаратизм. Богатые и бедные регионы относятся к центру по-разному.",
	"«Технологии»: пять веток знаний. Исследования идут быстрее с образованием, ВВП и свободой слова. Соседи подсказывают то, что уже знают сами.",
	"«Кризисы»: протесты, мятежи и перевороты. Раннее вмешательство дешевле: диалог, инвестиции, автономия. Там же — мирные конференции и признание новых государств.",
	"Новое в окнах разделов: «Экономика → Влияние и зависимость» — союзы (ЕС, НАТО), договоры, разведка; «Товары и цены» — энергия и история показателей; «Политика → Религия и миграция» — старение и пенсии; «Законы» — коррупция и СМИ; «Карта → Армия и война» — армия как политический игрок.",
	"Политический капитал — валюта решений. Он копится со временем и тратится на законы, реформы и переговоры. Не тратьте весь запас: он нужен на кризисы.",
	"Игру можно сохранить в настройках (кнопка ⚙ в правом верхнем углу). Раз в год делается автоснимок, поэтому ошибку можно откатить на год назад. Удачи!",
]

var rm_boxes: Dictionary = {}   # ключ -> {"box": Control, "fn": Callable, "stamp": String}
var rm_ver := 0
var tut_panel: PanelContainer = null
var tut_label: Label = null
var tut_idx := -1


func rm_reg(key: String, box: Control, fn: Callable) -> void:
	rm_boxes[key] = {"box": box, "fn": fn, "stamp": ""}


func rm_win(key: String, id: String, title: String, desk: int, fr: Rect2, fn: Callable) -> void:
	var w: FloatWindow = new_window(id, title, desk, fr)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 5)
	w.body.add_child(box)
	rm_reg(key, box, fn)


func rm_attach(key: String, parent: Control, title: String, fn: Callable) -> void:
	# секция внутри уже существующего окна или оверлея
	if parent == null:
		return
	add_title(parent, title)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 5)
	parent.add_child(box)
	rm_reg(key, box, fn)


func build_realm_windows() -> void:
	# v50: Евросоюз и НАТО — отдельные окна
	rm_win("blocs", "rm_blocs", "Европейский союз", 10, Rect2(0.0, 0.66, 0.175, 0.34), rm_b_blocs)
	rm_win("nato", "rm_nato", "НАТО", 10, Rect2(0.175, 0.66, 0.155, 0.34), rm_b_nato)
	rm_win("treaty", "rm_treaty", "Договоры и научные проекты", 10, Rect2(0.33, 0.66, 0.21, 0.34), rm_b_treaty)
	rm_win("spy", "rm_spy", "Разведка", 10, Rect2(0.54, 0.66, 0.165, 0.34), rm_b_spy)
	rm_win("energy", "rm_energy", "Энергия и климат", 7, Rect2(0.0, 0.58, 0.30, 0.42), rm_b_energy)
	rm_win("hist", "rm_hist", "История показателей", 7, Rect2(0.30, 0.58, 0.405, 0.42), rm_b_hist)
	rm_win("demo", "rm_demo", "Демография и пенсии", 11, Rect2(0.0, 0.78, 0.705, 0.22), rm_b_demo)
	rm_win("law", "rm_law", "Право, коррупция и СМИ", 3, Rect2(0.48, 0.60, 0.222, 0.40), rm_b_law)
	rm_win("army", "rm_army", "Армия как политический игрок", 13, Rect2(0.22, 0.0, 0.19, 0.36), rm_b_army)
	rm_attach("conf", cr_right_box, "Вмешательство, переговоры и признание новых государств", rm_b_conf)
	rm_attach("science", tw_left_box, "Государство и наука", rm_b_science)
	if wins.has("actions"):
		rm_attach("parl", (wins["actions"] as FloatWindow).body, "Парламент и президент", rm_b_parl)
	if wins.has("fw_bulk"):
		rm_attach("eq", (wins["fw_bulk"] as FloatWindow).body, "Выравнивание регионов", rm_b_eq)
	# v50: сохранения, откат и справка перенесены в настройки (⚙)
	build_tutorial()


func rm_dirty_all() -> void:
	rm_ver += 1


func update_realm_windows() -> void:
	if tut_panel != null:
		update_tutorial()
	if not rl_on() or not current_event.is_empty():
		return
	var stamp := "%d|%d|%s" % [turn, rm_ver, ex_sel]
	for k in rm_boxes:
		var e: Dictionary = rm_boxes[k]
		var box: Control = e["box"]
		if not box.is_visible_in_tree() or String(e["stamp"]) == stamp:
			continue
		e["stamp"] = stamp
		for ch in box.get_children():
			box.remove_child(ch)
			ch.queue_free()
		(e["fn"] as Callable).call(box)


func rm_act_btn(parent: Control, a: Dictionary, cb: Callable) -> void:
	var cap_txt: String = (" (%.0f)" % float(a["cap"])) if float(a["cap"]) > 0.0 else ""
	var b := fed_btn(String(a["name"]) + cap_txt, parent, String(a["desc"]) + ("" if String(a["why"]) == "" else "\n\nСейчас недоступно: " + String(a["why"])))
	b.disabled = not bool(a["ok"])
	b.pressed.connect(func() -> void:
		cb.call()
		rm_dirty_all()
		refresh())


func rm_acts_box(parent: Control, acts: Array, doer: Callable) -> void:
	for a in acts:
		var id: String = String(a["id"])
		var arg: String = String(a.get("arg", ""))
		rm_act_btn(parent, a, func() -> void: doer.call(id, arg))


func rm_text(parent: Control, t: String) -> void:
	var r := make_rt(parent)
	r.text = t


func rm_do_rl(id: String, _arg: String) -> void:
	rl_do(id)


# ---------- содержимое секций ----------
func rm_flags_row(box: Control, codes: Array) -> void:
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 3)
	fl.add_theme_constant_override("v_separation", 3)
	box.add_child(fl)
	for c in codes:
		if not Flags.has(String(c)):
			continue
		var f: TextureRect = Flags.make(String(c), 13.0)
		f.tooltip_text = String(WORLD[c]["name"]) if WORLD.has(c) else String(c)
		f.mouse_filter = Control.MOUSE_FILTER_PASS
		fl.add_child(f)


func rm_b_blocs(box: Control) -> void:
	var b: Dictionary = rl["b"]
	var mem: Array = []
	for c in RL_EU:
		if c != ccode:
			mem.append(c)
	if bool(b["eu"]):
		mem.append(ccode)
	var s := "Статус: [b]%s[/b] · членов: %d\nЕвро: [b]%s[/b] · Шенген: [b]%s[/b]%s\n" % ["член ЕС" if bool(b["eu"]) else ("кандидат" if (rl["acc"] as Dictionary).has("eu") else "вне ЕС"), mem.size(), rl_yn(bool(b["euro"])), rl_yn(bool(b["schg"])), " (контроль на границах)" if bool(b["ctrl"]) else ""]
	if bool(b["eu"]):
		var pc: float = rl_pc()
		var fund: float = maxf(0.0, (35.0 - pc) / 35.0 * 0.5)
		s += "Структурные фонды: [b]%s%% ВВП[/b] в год%s · единый рынок: рост +0,12 п.п.\n" % ["%.2f" % fund, " · скидка на взнос" if bool(rl.get("eu_rebate", false)) else ""]
		s += "Дефицит %.1f%% (правило — 3%%) · долг %.0f%% (правило — 60%%)" % [float(rl["defe"]), debt / maxf(1.0, gdp) * 100.0]
		if int(rl["edp"]) > 0:
			s += "\n[color=%s]Процедура чрезмерного дефицита: %d мес.[/color]" % [COL_WARN, int(rl["edp"])]
	for k in rl["acc"]:
		if String(k) == "nato":
			continue
		var a: Dictionary = rl["acc"][k]
		var goal: float = {"eu": 40.0, "euro": 24.0, "nato": 18.0}.get(k, 30.0)
		s += "\nЗаявка «%s»: %.0f%%, критериев %d из 4" % [rl_bloc_name(String(k)), float(a["p"]) / goal * 100.0, int(a["met"])]
	rm_text(box, s)
	rm_flags_row(box, mem)
	var acts: Array = []
	for a2 in rl_acts("blocs"):
		if String(a2["id"]) in ["acc_eu", "acc_euro", "ctrl"]:
			acts.append(a2)
	acts.append_array(rl_acts("eu"))
	rm_acts_box(box, acts, rm_do_rl)


func rm_b_nato(box: Control) -> void:
	var b: Dictionary = rl["b"]
	var mem: Array = []
	for c in MIL_NATO:
		if c != ccode:
			mem.append(c)
	if bool(b["nato"]):
		mem.append(ccode)
	var sr: float = mil_spend_ratio() if mil_on() else 1.0
	var s := "Статус: [b]%s[/b] · членов в игре: %d\n" % ["член НАТО" if bool(b["nato"]) else ("кандидат" if (rl["acc"] as Dictionary).has("nato") else "вне альянса"), mem.size()]
	s += "Оборонные расходы: [color=%s][b]%.0f%%[/b][/color] от обязательства%s\n" % [COL_GOOD if sr >= 0.95 else (COL_WARN if sr >= 0.85 else COL_BAD), sr * 100.0, " · статья 5: союзники защитят" if bool(b["nato"]) else ""]
	if bool(b["nato"]) and int(rl["natop"]) > 0:
		s += "[color=%s]Союзники недовольны расходами: %d мес.[/color]\n" % [COL_WARN, int(rl["natop"])]
	if bool(rl.get("nato_base", false)):
		s += "На территории — база союзников.\n"
	if (rl["acc"] as Dictionary).has("nato"):
		var a: Dictionary = rl["acc"]["nato"]
		s += "Заявка: %.0f%%, критериев %d из 4" % [float(a["p"]) / 18.0 * 100.0, int(a["met"])]
	rm_text(box, s)
	rm_flags_row(box, mem)
	var acts: Array = []
	for a2 in rl_acts("blocs"):
		if String(a2["id"]) in ["acc_nato", "leave_nato"]:
			acts.append(a2)
	acts.append_array(rl_acts("nato"))
	rm_acts_box(box, acts, rm_do_rl)


var rm_partner := ""   # v50: партнёр, выбранный прямо в окне договоров


func rm_dip_target() -> String:
	var cs: Array = dx_countries()
	if ex_sel != "" and ex_sel in cs:
		return ex_sel
	if rm_partner != "" and rm_partner in cs:
		return rm_partner
	return String(tech_nb()[0]) if tech_nb().size() > 0 else String(cs[0])


func rm_b_treaty(box: Control) -> void:
	var c: String = rm_dip_target()
	# v50: свой договор — «чистый лист» с пунктами и названием
	var nb := fed_btn("📜 Предложить договор…", box, "Составить договор из статей, дать ему название и предложить партнёру.")
	nb.pressed.connect(treaty_sheet_open)
	var nl: Array = dx.get("named", [])
	for k in nl.size():
		var e: Dictionary = nl[k]
		var row := HBoxContainer.new()
		box.add_child(row)
		var l := Label.new()
		l.text = "«%s» — %s" % [e["name"], dx_name(String(e["c"]))]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.clip_text = true
		l.tooltip_text = ", ".join(PackedStringArray((e["ids"] as Array).map(func(i): return String(dx_clause(String(i)).get("name", i)))))
		row.add_child(l)
		var kk: int = k
		var xb := Button.new()
		xb.text = "Расторгнуть"
		xb.theme_type_variation = "SmallButton"
		xb.focus_mode = Control.FOCUS_NONE
		xb.pressed.connect(func() -> void:
			dx_named_break(kk)
			rm_dirty_all())
		row.add_child(xb)
	var tr: Dictionary = (dx["tr"] as Dictionary).get(c, {})
	var names := []
	for k in tr:
		for d in DX_TREATIES:
			if String(d["id"]) == String(k):
				names.append(String(d["name"]))
	var pj := []
	for p in dx["proj"]:
		pj.append("%s (ещё %d мес.)" % [dx_name(String(p["cc"])), int(p["left"])])
	# v50: список стран прямо в окне (раньше партнёр не переключался, если страна из окна «Партнёры» не участвует в договорах)
	var cs: Array = dx_countries()
	var ob := OptionButton.new()
	ob.focus_mode = Control.FOCUS_NONE
	ob.fit_to_longest_item = false
	ob.clip_text = true
	ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in cs.size():
		ob.add_item(dx_name(String(cs[i])))
		if String(cs[i]) == c:
			ob.select(i)
	ob.item_selected.connect(func(i: int) -> void:
		rm_partner = String(cs[i])
		ex_sel = rm_partner
		rm_dirty_all()
		refresh())
	box.add_child(ob)
	if ex_sel != "" and not (ex_sel in cs):
		rm_text(box, "[color=%s]С %s договоры и научные проекты не заключаются — выберите страну из списка.[/color]" % [COL_WARN, dx_name(ex_sel)])
	rm_text(box, "Партнёр: [b]%s[/b]\nОтношения [b]%.0f[/b] · договоры: %s\nПроекты: %s" % [dx_name(c), fed_rel(c), ", ".join(names) if names.size() > 0 else "нет", ", ".join(pj) if pj.size() > 0 else "нет"])
	rm_acts_box(box, dx_treaty_acts(c), func(id: String, arg: String) -> void: dx_treaty_do(id, arg if arg != "" else c))


func rm_b_spy(box: Control) -> void:
	var c: String = rm_dip_target()
	rm_text(box, "Цель: [b]%s[/b] (выбирается в окне «Партнёры и зависимость»)\nКонтрразведка %d из 3 · провалов %d" % [dx_name(c), int(dx["ci"]), int(dx["exposed"])])
	rm_acts_box(box, dx_spy_acts(c), func(id: String, arg: String) -> void: dx_spy_do(id, arg if arg != "" else c))
	var lg: Array = dx["log"]
	if lg.size() > 0:
		rm_text(box, "\n".join(lg.slice(maxi(0, lg.size() - 5))))


func rm_b_energy(box: Control) -> void:
	var e: Dictionary = rl["e"]
	var lv: Dictionary = rl["lv"]
	rm_text(box, "Цена энергии [b]%.0f[/b] (норма 100) · зависимость от импорта [b]%.0f%%[/b]\nЗелёная доля [b]%.0f%%[/b] · климатический риск [b]%.0f[/b]\nПрограммы: зелёный переход %d · запасы %d" % [float(e["price"]), float(e["dep"]), float(e["green"]), float(e["clim"]), lv["grn"], lv["gas"]])
	rm_acts_box(box, rl_acts("energy"), rm_do_rl)


func rm_b_demo(box: Control) -> void:
	var d: Dictionary = rl["d"]
	var lv: Dictionary = rl["lv"]
	rm_text(box, "Старше 65 лет: [b]%.1f%%[/b] (при старте %.1f%%) · рождаемость [b]%.2f[/b] · давление пенсий на бюджет [b]+%.2f%% ВВП[/b]\nПрограммы: семья %d · миграция %d · пенсионная реформа %d" % [float(d["age"]), float(d["age0"]), float(d["tfr"]), float(d["pen"]), lv["fam"], lv["imm"], lv["ret"]])
	var g := GridContainer.new()
	g.columns = 3
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(g)
	rm_acts_box(g, rl_acts("demo"), rm_do_rl)


func rm_b_law(box: Control) -> void:
	var l: Dictionary = rl["l"]
	var m: Dictionary = rl["m"]
	rm_text(box, "Независимость судов [b]%.0f[/b] · коррупция [b]%.0f[/b] (выше — хуже)" % [float(l["jud"]), float(l["cor"])])
	rm_acts_box(box, rl_acts("law"), rm_do_rl)
	add_title(box, "СМИ")
	rm_text(box, "Свобода прессы [b]%.0f[/b] · доверие [b]%.0f[/b] · дезинформация [b]%.0f[/b]%s" % [float(m["free"]), float(m["trust"]), float(m["fake"]), (" · контроль власти ×%d" % int(m["state"])) if int(m["state"]) > 0 else ""])
	rm_acts_box(box, rl_acts("media"), rm_do_rl)


func rm_b_parl(box: Control) -> void:
	rm_text(box, "Вотум недоверия: [b]%s[/b]%s" % ["конструктивный (нужен преемник)" if noc_constr else "обычный", ("\n[color=%s]Сожительство с президентом из оппозиции: %d мес.[/color]" % [COL_WARN, int(rl.get("cohab", 0))]) if rl_cohab() else ""])
	rm_acts_box(box, rl_acts("parl"), rm_do_rl)


func rm_b_eq(box: Control) -> void:
	rm_text(box, "Уровень: %d из 3. Бедные регионы благодарны за трансферты, богатые недовольны платежами." % int(rl["lv"]["eq"]))
	rm_acts_box(box, rl_acts("region"), rm_do_rl)


func rm_b_army(box: Control) -> void:
	var a: Dictionary = dx["army"]
	rm_text(box, "Лояльность армии [b]%.0f[/b] · амбиции генералов [b]%.0f[/b]\nПри низкой лояльности и высоких амбициях растёт риск переворота." % [float(a["loy"]), float(a["amb"])])
	rm_acts_box(box, dx_army_acts(), func(id: String, _g: String) -> void: dx_army_do(id))


func rm_b_hist(box: Control) -> void:
	var h: Dictionary = rl["h"]
	var defs := [["gdp", "ВВП, млрд €", Color(0.45, 0.8, 1.0)], ["debt", "Долг, % ВВП", Color(1.0, 0.6, 0.4)], ["appr", "Рейтинг, %", Color(0.5, 0.95, 0.6)],
		["unemp", "Безработица, %", Color(1.0, 0.85, 0.4)], ["infl", "Инфляция, %", Color(0.9, 0.5, 0.9)], ["growth", "Рост ВВП, %", Color(0.6, 0.9, 0.9)],
		["age", "Старше 65 лет, %", Color(0.8, 0.7, 0.5)], ["cor", "Коррупция", Color(1.0, 0.45, 0.45)], ["jud", "Независимость судов", Color(0.55, 0.8, 1.0)],
		["free", "Свобода прессы", Color(0.7, 1.0, 0.7)], ["price", "Цена энергии", Color(1.0, 0.75, 0.3)], ["green", "Зелёная доля, %", Color(0.4, 0.9, 0.5)]]
	var g := GridContainer.new()
	g.columns = 2
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	box.add_child(g)
	for d in defs:
		var sp: Control = Spark.new()
		sp.custom_minimum_size = Vector2(180.0, 84.0)
		var arr: Array = h[String(d[0])]
		sp.title = "%s: %.1f" % [String(d[1]), float(arr.back()) if arr.size() > 0 else 0.0]
		sp.series = [{"v": arr.duplicate(), "c": d[2], "n": String(d[1])}]
		g.add_child(sp)
	rm_text(box, "Показатели записываются каждый месяц; на графиках — вся история игры.")


func rm_slot_row(box: Control, slot: int) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 4)
	box.add_child(hb)
	var info: String = sv_info(slot)
	var lab := Label.new()
	lab.text = "Слот %d: %s" % [slot, info if info != "" else "пусто"]
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lab.custom_minimum_size = Vector2(90.0, 0.0)
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(lab)
	var bs := Button.new()
	bs.text = "Сохр."
	bs.tooltip_text = "Сохранить игру в этот слот."
	bs.focus_mode = Control.FOCUS_NONE
	bs.pressed.connect(func() -> void:
		sv_save(slot)
		rm_dirty_all()
		refresh())
	hb.add_child(bs)
	var bl := Button.new()
	bl.text = "Загр."
	bl.tooltip_text = "Загрузить игру из этого слота."
	bl.focus_mode = Control.FOCUS_NONE
	bl.disabled = info == ""
	bl.pressed.connect(func() -> void:
		if sv_load(slot):
			rm_dirty_all()
			refresh())
	hb.add_child(bl)


func rm_b_game(box: Control) -> void:
	rm_text(box, "Сохранение записывает всё состояние страны; слоты у каждой страны свои.")
	for s in [1, 2, 3]:
		rm_slot_row(box, s)
	var names := []
	for x in sv_hist:
		names.append(String(x["date"]))
	rm_text(box, "Автоснимки (раз в год): %s" % (", ".join(names) if names.size() > 0 else "первый появится в январе"))
	var rb := fed_btn("Откатиться на предыдущий снимок", box, "Вернёт игру на последний снимок до текущего месяца. Всё после него будет потеряно.")
	rb.disabled = sv_hist.is_empty()
	rb.pressed.connect(func() -> void:
		sv_rollback()
		rm_dirty_all()
		refresh())
	var tb := fed_btn("Подсказки для новичка — сначала", box, "Короткий тур по окнам игры.")
	tb.pressed.connect(func() -> void:
		tut_idx = 0
		update_tutorial())
	rm_text(box, "[b]Справка.[/b] Политический капитал — ресурс решений. Рейтинг — доля довольных. Сепаратизм падает от автономии и диалога. Коррупция растёт при слабых судах и несвободных СМИ. Цена энергии 100 — норма. Низкая лояльность армии и высокие амбиции генералов повышают риск переворота.")


# ---------- секции в оверлеях ----------
func rm_b_conf(box: Control) -> void:
	var cf: Array = rv.get("conf", []) if rv_on() else []
	if cf.is_empty():
		rm_text(box, "Сейчас внутренних конфликтов нет.")
	for k in cf.size():
		var c: Dictionary = cf[k]
		var fi: Dictionary = c.get("fi", {"gov": [], "reb": [], "pk": false})
		var gov_n := []
		for x in fi["gov"]:
			gov_n.append(dx_name(String(x)))
		var reb_n := []
		for x2 in fi["reb"]:
			reb_n.append(dx_name(String(x2)))
		rm_text(box, "[b]%s[/b]: контроль повстанцев %.0f%% · сила %.0f\nПомогают правительству: %s · помогают повстанцам: %s · миротворцы: %s%s" % [c["name"], float(c["ctl"]), float(c["R"]), ", ".join(gov_n) if gov_n.size() > 0 else "никто", ", ".join(reb_n) if reb_n.size() > 0 else "никто", "да" if bool(fi["pk"]) else "нет", (" · перемирие %d мес." % int(c["truce"])) if int(c["truce"]) > 0 and int(c["truce"]) < 9000 else ""])
		var kk: int = k
		var g := GridContainer.new()
		g.columns = 2
		g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(g)
		rm_acts_box(g, dx_conf_acts(k), func(id: String, _a: String) -> void: dx_conf_do(id, kk))
	add_title(box, "Новые государства и признание")
	var rt: String = dx_rec_text() if rv_on() else ""
	rm_text(box, rt if rt != "" else "Новых государств нет.")
	var g2 := GridContainer.new()
	g2.columns = 2
	g2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(g2)
	rm_acts_box(g2, dx_rec_acts(), func(id: String, arg: String) -> void: dx_rec_do(id, arg))


func rm_b_science(box: Control) -> void:
	var pj := []
	for p in dx["proj"]:
		pj.append("%s (ещё %d мес.)" % [dx_name(String(p["cc"])), int(p["left"])])
	rm_text(box, "Множитель скорости: [b]×%.2f[/b] · пассивное изучение ×%.1f\nПроекты: %s\nЭтика технологий: уровень [b]%d[/b] из 3\nСовместные проекты и научный обмен оформляются в «Экономика → Влияние и зависимость».\n" % [tech_adj, tech_pas_mult, ", ".join(pj) if pj.size() > 0 else "нет", int(dx["eth"])])
	rm_acts_box(box, dx_eth_acts(), func(id: String, _g: String) -> void: dx_eth_do(id))


# ---------- подсказки новичка ----------
func build_tutorial() -> void:
	tut_panel = PanelContainer.new()
	tut_panel.add_theme_stylebox_override("panel", sbox(Color(0.07, 0.09, 0.14, 0.96), C_ACCENT, 2, 10, 10.0, 8.0))
	tut_panel.visible = false
	add_child(tut_panel)
	tut_panel.anchor_left = 0.0
	tut_panel.anchor_top = 1.0
	tut_panel.anchor_right = 0.0
	tut_panel.anchor_bottom = 1.0
	tut_panel.offset_left = 12.0
	tut_panel.offset_bottom = -12.0
	tut_panel.offset_top = -150.0
	tut_panel.offset_right = 430.0
	tut_panel.z_index = 40
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	tut_panel.add_child(vb)
	tut_label = Label.new()
	tut_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tut_label.custom_minimum_size = Vector2(390.0, 0.0)
	tut_label.add_theme_font_size_override("font_size", 13)
	vb.add_child(tut_label)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	vb.add_child(hb)
	var nx := Button.new()
	nx.text = "Далее ▸"
	nx.focus_mode = Control.FOCUS_NONE
	nx.pressed.connect(on_tut_next)
	hb.add_child(nx)
	var sk := Button.new()
	sk.text = "Пропустить"
	sk.focus_mode = Control.FOCUS_NONE
	sk.pressed.connect(on_tut_skip)
	hb.add_child(sk)
	if int(game_opts.get("tut", 1)) == 1 and turn == 0:
		tut_idx = 0


func on_tut_next() -> void:
	tut_idx += 1
	if tut_idx >= TUT_STEPS.size():
		tut_idx = -1
	update_tutorial()


func on_tut_skip() -> void:
	tut_idx = -1
	update_tutorial()


func update_tutorial() -> void:
	if tut_panel == null:
		return
	var ov_open: bool = (tech_ov != null and tech_ov.visible) or (cr_ov != null and cr_ov.visible)
	var show_it: bool = tut_idx >= 0 and tut_idx < TUT_STEPS.size() and current_event.is_empty() and not ov_open
	tut_panel.visible = show_it
	if show_it:
		tut_label.text = "Подсказка %d из %d\n%s" % [tut_idx + 1, TUT_STEPS.size(), String(TUT_STEPS[tut_idx])]
