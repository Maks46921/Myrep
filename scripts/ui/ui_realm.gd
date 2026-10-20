# Интерфейс v44_1: «Государство и мир» без отдельного окна — секции встроены в существующие разделы:
#  Бюджет → «Советник и автопилот» (сохранения, откат, справка) · Политика → «Парламент» (парламент и президент),
#  «Законы» (право и СМИ), «Религия и миграция» (демография и пенсии) · Экономика → «Товары и цены» (энергия, история),
#  «Влияние и зависимость» (союзы, договоры, разведка) · Карта → «Регионы и автономия» (выравнивание), «Армия и война» (армия как политический игрок)
#  · оверлей «Кризисы» (вмешательство, мирные конференции, признание) · оверлей «Технологии» (проекты, этика).
# Плюс подсказки для новичка.
extends "res://scripts/ui/ui_crisis.gd"

# 0.56 (п.1): обучение со стрелкой и светящейся рамкой. t — текст, tg — на что указывает стрелка
# (play, speed, cap, appr, tab0…tab5, tech, crisis, meas, set или win:<id окна>), do — что открыть перед показом шага
const TUT_STEPS := [
	{"t": "Добро пожаловать! Время идёт кнопкой «▶»: дни сменяют друг друга, пока не случится событие или выборы. Рядом — скорость, а паузой можно остановиться и подумать.", "tg": "play", "do": "tab:0"},
	{"t": "«Сегодня»: всё, что нужно сейчас. Слева ждущие решения и письма во «Входящих», рядом три главные проблемы, ближайшие даты и ключевые числа. Если здесь пусто, можно пускать время: игра сама остановится, когда понадобится ваш ответ.", "tg": "tab6", "do": "tab:6"},
	{"t": "«Бюджет»: ползунки налогов и расходов. Меняйте понемногу и смотрите прогноз роста, инфляции и рейтинга. Долг растёт, когда расходы выше доходов. Кнопки «−» и «+» меняют ставку на 0,1% ВВП.", "tg": "win:tax", "do": "tab:0"},
	{"t": "Поиск по игре: Ctrl+K находит окна, законы, регионы, страны, людей и действия. Клавиши 1–6 переключают рамки, пробел ставит паузу, Alt+← возвращает назад. Звёздочка в заголовке окна кладёт его в закладки, «?» объясняет окно.", "tg": "play", "do": "tab:6"},
	{"t": "«Экономика»: рынки, товары, компании страны, сооружения и пульт экономической модели. Здесь видно, что дорожает, чего не хватает и кто в стране зарабатывает.", "tg": "tab1", "do": "tab:1"},
	{"t": "«Политика»: парламент, законы, правительство, население и оппозиция. Чтобы править, нужно большинство мест. Недовольные партнёры по коалиции могут уйти, а при другом режиме раздел выглядит иначе.", "tg": "win:parliament", "do": "tab:2"},
	{"t": "«Мир»: карта и регионы страны. Щёлкните по региону, чтобы увидеть недовольство, сепаратизм и экономику. Богатые и бедные регионы относятся к центру по-разному.", "tg": "win:map", "do": "tab:3"},
	{"t": "«Мир → Организации»: ЕС, НАТО, ООН и другие. Вступление и выход, взносы, голосования на сессиях и влияние внутри организации. Членство даёт выгоды, но и требует обязательств.", "tg": "win:io_head", "do": "desk:18"},
	{"t": "«Общество → Народы»: народы страны, их регионы и напряжённость, культурная политика и родные страны диаспор. Недовольное меньшинство может потребовать автономии.", "tg": "win:cu_nat", "do": "desk:19"},
	{"t": "«Общество → Религия»: главная церковь, её законы и религиозность регионов. Союз с церковью приносит голоса консерваторов, но сердит светских избирателей.", "tg": "win:ch_main", "do": "desk:20"},
	{"t": "«Строительство»: очередь государственных строек, частные инвесторы, налоговые льготы и годовой план министерств. Стройка занимает месяцы и упирается в мощность строительной отрасли.", "tg": "win:build", "do": "bld"},
	{"t": "«Ещё → Технологии»: пять веток знаний. Исследования идут быстрее с образованием, ВВП и свободой слова. Соседи подсказывают то, что уже знают сами. Очередь изучения — справа.", "tg": "tech", "do": "tab:0"},
	{"t": "«Ещё → Кризисы»: протесты, мятежи и перевороты. Раннее вмешательство дешевле: диалог, инвестиции, автономия. Там же — мирные конференции и признание новых государств.", "tg": "crisis", "do": "tab:0"},
	{"t": "«Карта → Армия и война»: здесь объявляют войну и мир, а также вводят военное положение. Пока оно действует, выборы не проводятся, а конституцию менять нельзя.", "tg": "win:war_ops", "do": "desk:13"},
	{"t": "«Ещё → Разовые меры»: меры за часть ВВП и советник. Они оплачиваются из резерва бюджета, поэтому следите за запасом.", "tg": "meas", "do": "tab:0"},
	{"t": "Политический капитал — валюта решений. Он копится со временем (места в парламенте, пост главы правительства, министерства, рейтинг) и тратится на законы, реформы и переговоры. Не тратьте весь запас: он нужен на кризисы.", "tg": "cap", "do": "tab:0"},
	{"t": "Игру можно сохранить в настройках (кнопка ⚙). Раз в год делается автоснимок, поэтому ошибку можно откатить на год назад. Там же — кнопка «Пройти обучение заново». Удачи!", "tg": "set", "do": "tab:0"},
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
	# 0.55.5: окна «Европейский союз» и «НАТО» убраны из «Влияния» — всё это теперь в рамке «Организации» (вкладки ЕС и НАТО)
	rm_win("treaty", "rm_treaty", "Договоры и научные проекты", 10, Rect2(0.0, 0.66, 0.235, 0.34), rm_b_treaty)
	rm_win("spy", "rm_spy", "Разведка", 10, Rect2(0.235, 0.66, 0.235, 0.34), rm_b_spy)
	rm_win("world", "rm_world", "Мир и санкции", 10, Rect2(0.47, 0.66, 0.235, 0.34), rm_b_world)
	rm_win("energy", "rm_energy", "Энергия и климат", 16, Rect2(0.0, 0.42, 0.30, 0.58), rm_b_energy)
	rm_win("hist", "rm_hist", "История показателей", 7, Rect2(0.35, 0.5, 0.355, 0.5), rm_b_hist)
	rm_win("demo", "rm_demo", "Демография и пенсии", 11, Rect2(0.0, 0.78, 0.705, 0.22), rm_b_demo)
	rm_win("law", "rm_law", "Право, коррупция и СМИ", 3, Rect2(0.48, 0.80, 0.222, 0.20), rm_b_law)
	rm_win("army", "rm_army", "Армия как политический игрок", 13, Rect2(0.22, 0.0, 0.19, 0.36), rm_b_army)
	rm_attach("conf", cr_right_box, "Вмешательство, переговоры и признание новых государств", rm_b_conf)
	rm_attach("science", tw_left_box, "Государство и наука", rm_b_science)
	if wins.has("actions"):
		rm_attach("parl", (wins["actions"] as FloatWindow).body, "Парламент и президент", rm_b_parl)
	# 0.56 (п.8): программа выравнивания тратит общий бюджет — она в «Бюджете», под трансфертами регионам
	rm_attach("eq", bud_eq_box, "Выравнивание регионов", rm_b_eq)
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


# 0.55.5: состояние страны в ЕС — показывается во вкладке ЕС рамки «Организации»
func rl_eu_status() -> String:
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
	return s


func rl_nato_status() -> String:
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
	return s


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


# v53_1: отношение мира, мировые санкции и путь их снятия
func rm_b_world(box: Control) -> void:
	rm_text(box, fa_ws_text())
	var g := GridContainer.new()
	g.columns = 1
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(g)
	rm_acts_box(g, fa_ws_acts(), func(id: String, _a: String) -> void: fa_ws_do(id))
	if fa_on():
		var lg: Array = fa["log"]
		if lg.size() > 0:
			add_title(box, "Последние события")
			rm_text(box, "\n".join(PackedStringArray(lg.slice(maxi(0, lg.size() - 6)))))


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
	rm_text(box, "Уровень: %d из 3 (%.2f%% ВВП в год из бюджета). Бедные регионы благодарны за доплаты, богатые недовольны.\n[color=%s][font_size=12]Это доплаты бедным регионам из общего бюджета. «Выравнивание бюджетов регионов» во вкладке «Федерация» — другое: там богатые регионы делятся налогами с бедными, общий бюджет не тратится.[/font_size][/color]" % [int(rl["lv"]["eq"]), 0.25 * float(rl["lv"]["eq"]), COL_DIM])
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


# ---------- подсказки новичка (0.56: стрелка и светящаяся рамка, предложение при первом запуске) ----------
var tut_fx: Control = null
var tut_btns: HBoxContainer = null
var tut_offer_btns: HBoxContainer = null
var tut_title: Label = null
var tut_done := -1
var tut_timer: Timer = null
var tut_tr := Rect2()


func build_tutorial() -> void:
	tut_fx = Control.new()
	tut_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tut_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tut_fx.z_index = 39
	tut_fx.visible = false
	tut_fx.draw.connect(tut_draw)
	add_child(tut_fx)
	tut_panel = PanelContainer.new()
	tut_panel.add_theme_stylebox_override("panel", sbox(Color(0.07, 0.09, 0.14, 0.97), C_ACCENT, 2, 10, 12.0, 10.0))
	tut_panel.visible = false
	add_child(tut_panel)
	tut_panel.z_index = 40
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	tut_panel.add_child(vb)
	tut_title = Label.new()
	tut_title.add_theme_font_size_override("font_size", 12)
	tut_title.add_theme_color_override("font_color", C_ACCENT.lightened(0.2))
	vb.add_child(tut_title)
	tut_label = Label.new()
	tut_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tut_label.custom_minimum_size = Vector2(380.0, 0.0)
	tut_label.add_theme_font_size_override("font_size", 14)
	vb.add_child(tut_label)
	tut_btns = HBoxContainer.new()
	tut_btns.add_theme_constant_override("separation", 6)
	vb.add_child(tut_btns)
	var bk := Button.new()
	bk.text = "◂ Назад"
	bk.focus_mode = Control.FOCUS_NONE
	bk.pressed.connect(on_tut_back)
	tut_btns.add_child(bk)
	var nx := Button.new()
	nx.text = "Далее ▸"
	nx.focus_mode = Control.FOCUS_NONE
	nx.pressed.connect(on_tut_next)
	tut_btns.add_child(nx)
	var sk := Button.new()
	sk.text = "Пропустить"
	sk.focus_mode = Control.FOCUS_NONE
	sk.pressed.connect(on_tut_skip)
	tut_btns.add_child(sk)
	tut_offer_btns = HBoxContainer.new()
	tut_offer_btns.add_theme_constant_override("separation", 6)
	vb.add_child(tut_offer_btns)
	var y1 := Button.new()
	y1.text = "Пройти обучение"
	y1.focus_mode = Control.FOCUS_NONE
	y1.pressed.connect(on_tut_start)
	tut_offer_btns.add_child(y1)
	var y2 := Button.new()
	y2.text = "Не сейчас"
	y2.focus_mode = Control.FOCUS_NONE
	y2.pressed.connect(on_tut_skip)
	tut_offer_btns.add_child(y2)
	var y3 := Button.new()
	y3.text = "Больше не предлагать"
	y3.focus_mode = Control.FOCUS_NONE
	y3.pressed.connect(on_tut_never)
	tut_offer_btns.add_child(y3)
	tut_timer = Timer.new()
	tut_timer.wait_time = 0.04
	tut_timer.timeout.connect(tut_tick)
	add_child(tut_timer)
	tut_timer.start()
	# при первом запуске предлагаем, а не навязываем
	if int(game_opts.get("tut", 1)) == 1 and turn == 0:
		tut_idx = -2


func on_tut_start() -> void:
	tut_idx = 0
	tut_done = -1
	update_tutorial()


func on_tut_next() -> void:
	tut_idx += 1
	if tut_idx >= TUT_STEPS.size():
		tut_idx = -1
		show_tab(0)
	update_tutorial()


func on_tut_back() -> void:
	tut_idx = maxi(0, tut_idx - 1)
	update_tutorial()


func on_tut_skip() -> void:
	tut_idx = -1
	update_tutorial()


func on_tut_never() -> void:
	game_opts["tut"] = 0
	tut_idx = -1
	update_tutorial()


func tut_target(key: String) -> Control:
	if key.begins_with("tab"):
		var k: int = int(key.substr(3))
		return desk_buttons[k] if k < desk_buttons.size() else null
	if key.begins_with("win:"):
		var id: String = key.substr(4)
		if wins.has(id) and (wins[id] as FloatWindow).visible:
			return wins[id]
		return null
	match key:
		"play": return play_btn
		"speed": return speed_opt
		"tech", "crisis", "meas": return get("more_btn") as Control   # меню «Ещё» объявлено в модулях ниже по цепочке
		"set": return get("st_btn") as Control
		"cap": return (chips["cap"]["pc"] as Control) if chips.has("cap") else null
		"appr": return (chips["appr"]["pc"] as Control) if chips.has("appr") else null
	return null


func tut_do(act: String) -> void:
	if tech_is_open():
		set_tech_open(false)
	if crisis_is_open():
		set_crisis_open(false)
	if meas_is_open():
		set_meas_open(false)
	if act.begins_with("tab:"):
		show_tab(int(act.substr(4)))
	elif act.begins_with("desk:"):
		show_desk(int(act.substr(5)))
	elif act == "bld":
		bld_open()


func update_tutorial() -> void:
	if tut_panel == null:
		return
	var ov_open: bool = (tech_ov != null and tech_ov.visible) or (cr_ov != null and cr_ov.visible)
	var step_on: bool = tut_idx >= 0 and tut_idx < TUT_STEPS.size()
	var offer: bool = tut_idx == -2
	var show_it: bool = (step_on or offer) and current_event.is_empty() and not election_open and (not ov_open or step_on)
	tut_panel.visible = show_it
	tut_fx.visible = show_it and step_on
	tut_btns.visible = step_on
	tut_offer_btns.visible = offer
	if not show_it:
		return
	if offer:
		tut_title.text = "Обучение"
		tut_label.text = "Хотите пройти короткое обучение? Стрелка и светящаяся рамка покажут главные разделы игры. Его можно прервать в любой момент и повторить из настроек (⚙)."
		tut_tr = Rect2()
	else:
		var st: Dictionary = TUT_STEPS[tut_idx]
		if tut_done != tut_idx:
			tut_done = tut_idx
			tut_do(String(st.get("do", "")))
		tut_title.text = "Обучение · шаг %d из %d" % [tut_idx + 1, TUT_STEPS.size()]
		tut_label.text = String(st["t"])
		var tc: Control = tut_target(String(st.get("tg", "")))
		tut_tr = tc.get_global_rect() if tc != null and tc.is_inside_tree() and tc.is_visible_in_tree() else Rect2()
	tut_place()


# панель — рядом с целью, но не поверх неё
func tut_place() -> void:
	tut_panel.reset_size()
	var vp: Vector2 = get_viewport_rect().size
	var ps: Vector2 = tut_panel.get_combined_minimum_size()
	var pos := Vector2(16.0, vp.y - ps.y - 16.0)
	if tut_tr.size.x > 0.0:
		var cx: float = tut_tr.position.x + tut_tr.size.x * 0.5
		if tut_tr.position.y < 140.0:
			pos = Vector2(cx - ps.x * 0.5, tut_tr.end.y + 64.0)
		elif tut_tr.get_center().y < vp.y * 0.5:
			pos = Vector2(tut_tr.get_center().x - ps.x * 0.5, tut_tr.end.y + 64.0)
		else:
			pos = Vector2(tut_tr.get_center().x - ps.x * 0.5, tut_tr.position.y - ps.y - 64.0)
		pos.x = clampf(pos.x, 10.0, vp.x - ps.x - 10.0)
		pos.y = clampf(pos.y, 70.0, vp.y - ps.y - 10.0)
	else:
		pos = Vector2((vp.x - ps.x) * 0.5, vp.y * 0.5 - ps.y * 0.5) if tut_idx == -2 else pos
	tut_panel.position = pos
	tut_panel.size = ps


func tut_tick() -> void:
	if tut_fx != null and tut_fx.visible:
		if tut_idx >= 0 and tut_idx < TUT_STEPS.size():
			var tc: Control = tut_target(String(TUT_STEPS[tut_idx].get("tg", "")))
			var r: Rect2 = tc.get_global_rect() if tc != null and tc.is_inside_tree() and tc.is_visible_in_tree() else Rect2()
			if r != tut_tr:
				tut_tr = r
				tut_place()
		tut_fx.queue_redraw()


func tut_draw() -> void:
	if tut_tr.size.x <= 0.0:
		return
	var ph: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 230.0)
	var r: Rect2 = tut_tr.grow(5.0)
	var col: Color = C_ACCENT.lightened(0.35)
	# свечение: несколько расходящихся рамок
	for k in 5:
		var g: float = float(k) * 2.5 + ph * 3.0
		var a: float = (0.28 - float(k) * 0.045) * (0.55 + 0.45 * ph)
		tut_fx.draw_rect(r.grow(g), Color(col.r, col.g, col.b, maxf(0.02, a)), false, 2.0)
	tut_fx.draw_rect(r, Color(col.r, col.g, col.b, 0.95), false, 2.5)
	tut_fx.draw_rect(r, Color(col.r, col.g, col.b, 0.06 + 0.06 * ph), true)
	# стрелка от панели к рамке
	var pr := Rect2(tut_panel.position, tut_panel.size)
	var from := Vector2(clampf(r.get_center().x, pr.position.x + 16.0, pr.end.x - 16.0), pr.position.y if r.get_center().y < pr.get_center().y else pr.end.y)
	var to := Vector2(r.get_center().x, r.end.y + 4.0 if r.get_center().y < pr.get_center().y else r.position.y - 4.0)
	to = to + (from - to).normalized() * (4.0 + ph * 5.0)
	var d: Vector2 = (to - from)
	if d.length() < 10.0:
		return
	var dir: Vector2 = d.normalized()
	var perp := Vector2(-dir.y, dir.x)
	var tail: Vector2 = to - dir * 12.0
	tut_fx.draw_line(from, tail, Color(col.r, col.g, col.b, 0.9), 3.0, true)
	tut_fx.draw_colored_polygon(PackedVector2Array([to, tail + perp * 9.0, tail - perp * 9.0]), Color(col.r, col.g, col.b, 0.98))
