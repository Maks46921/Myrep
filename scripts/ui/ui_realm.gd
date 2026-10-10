# Интерфейс: окно «Государство» (v44_1) — союзы и парламент, общество и энергия, дипломатия и разведка, конфликты,
# армия и наука, история (графики), сохранения; плюс подсказки для новичка.
extends "res://scripts/ui/ui_crisis.gd"

const RM_PAGES := [["blocs", "Союзы и парламент"], ["soc", "Общество, энергия, право"], ["dip", "Дипломатия и разведка"], ["conf", "Конфликты"], ["army", "Армия и наука"], ["hist", "История"], ["game", "Игра и справка"]]
const TUT_STEPS := [
	"Добро пожаловать! Вверху — кнопки «Бюджет», «Политика», «Карта» и окна «Технологии», «Кризисы», «Государство». Время идёт кнопками справа вверху: «▶» запускает ход, паузой можно остановить.",
	"«Бюджет»: ползунки — это налоги и расходы. Сначала меняйте понемногу и смотрите прогноз роста, инфляции и рейтинга. Долг растёт, когда расходы выше доходов.",
	"«Политика»: парламент, партии и коалиция. Чтобы править, нужно большинство мест. Недовольные партнёры по коалиции могут уйти — следите за их довольством.",
	"«Карта»: регионы страны. Щёлкните по региону — увидите недовольство и сепаратизм. Богатые и бедные регионы относятся к центру по-разному.",
	"«Технологии»: пять веток знаний. Исследования идут быстрее с образованием, ВВП и свободой слова. Соседи подсказывают то, что уже знают сами.",
	"«Кризисы»: протесты, мятежи и перевороты. Раннее вмешательство дешевле: диалог, инвестиции, автономия. Силой лучше не злоупотреблять.",
	"«Государство» (эта кнопка): членство в ЕС и НАТО, старение населения, цены на энергию, коррупция, СМИ, договоры с соседями, разведка и сохранения.",
	"Политический капитал — валюта решений. Он копится со временем и тратится на законы, реформы и переговоры. Не тратьте весь запас: он нужен на кризисы.",
	"Игру можно сохранить в окне «Государство → Игра». Раз в год делается автоснимок, поэтому ошибку можно откатить на год назад. Удачи!",
]

var rm_ov: PanelContainer = null
var rm_btn: Button = null
var rm_page := "blocs"
var rm_content: VBoxContainer = null
var rm_tabs: Dictionary = {}
var rm_stamp := ""
var rm_dip_sel := ""
var rm_dip_opt: OptionButton = null
var rm_conf_sel := 0
var rm_dirty := true
var tut_panel: PanelContainer = null
var tut_label: Label = null
var tut_idx := -1


func make_realm_button(parent: Control) -> void:
	rm_btn = Button.new()
	rm_btn.theme_type_variation = "TabButton"
	rm_btn.text = "Государство"
	rm_btn.toggle_mode = true
	rm_btn.focus_mode = Control.FOCUS_NONE
	rm_btn.custom_minimum_size = Vector2(0.0, 40.0)
	rm_btn.tooltip_text = "Блоки (ЕС, НАТО), демография, энергия, коррупция, СМИ, дипломатия, разведка, армия, графики истории, сохранения."
	rm_btn.toggled.connect(on_realm_toggle)
	btn_icon(rm_btn, "flag")
	parent.add_child(rm_btn)


func on_realm_toggle(on: bool) -> void:
	set_realm_open(on)


func set_realm_open(on: bool) -> void:
	if rm_ov == null:
		return
	if on and not current_event.is_empty():
		on = false
	if on != rm_ov.visible:
		sfx("click")
	if on:
		if tech_ov != null and tech_ov.visible:
			set_tech_open(false)
		if cr_ov != null and cr_ov.visible:
			set_crisis_open(false)
	rm_ov.visible = on
	if rm_btn != null:
		rm_btn.set_pressed_no_signal(on)
	if on:
		rm_dirty = true
		refresh()


func build_realm_windows() -> void:
	rm_ov = PanelContainer.new()
	rm_ov.add_theme_stylebox_override("panel", sbox(Color(0.05, 0.065, 0.085, 0.985), C_ACCENT.darkened(0.45), 2, 12, 12.0, 10.0))
	rm_ov.visible = false
	add_child(rm_ov)
	rm_ov.anchor_right = 1.0
	rm_ov.anchor_bottom = 1.0
	rm_ov.offset_left = 8.0
	rm_ov.offset_top = 62.0
	rm_ov.offset_right = -8.0
	rm_ov.offset_bottom = -8.0
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	rm_ov.add_child(root)
	var hd := HBoxContainer.new()
	hd.add_theme_constant_override("separation", 10)
	root.add_child(hd)
	var ttl := Label.new()
	ttl.text = "Государство и мир"
	ttl.add_theme_font_size_override("font_size", 22)
	ttl.add_theme_color_override("font_color", C_TEXT)
	hd.add_child(ttl)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hd.add_child(sp)
	var cl := Button.new()
	cl.text = "✕ Закрыть"
	cl.focus_mode = Control.FOCUS_NONE
	cl.pressed.connect(set_realm_open.bind(false))
	hd.add_child(cl)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(190.0, 0.0)
	left.add_theme_constant_override("separation", 4)
	body.add_child(left)
	for pg in RM_PAGES:
		var b := Button.new()
		b.text = String(pg[1])
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0.0, 34.0)
		b.pressed.connect(on_realm_page.bind(String(pg[0])))
		left.add_child(b)
		rm_tabs[String(pg[0])] = b
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(sc)
	rm_content = VBoxContainer.new()
	rm_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rm_content.add_theme_constant_override("separation", 6)
	sc.add_child(rm_content)
	build_tutorial()


func on_realm_page(pg: String) -> void:
	rm_page = pg
	rm_dirty = true
	update_realm_windows()


func rm_act_btn(parent: Control, a: Dictionary, cb: Callable) -> void:
	var cap_txt: String = (" (%.0f)" % float(a["cap"])) if float(a["cap"]) > 0.0 else ""
	var b := fed_btn(String(a["name"]) + cap_txt, parent, String(a["desc"]) + ("" if String(a["why"]) == "" else "\n\nСейчас недоступно: " + String(a["why"])))
	b.disabled = not bool(a["ok"])
	b.pressed.connect(func() -> void:
		cb.call()
		rm_dirty = true
		refresh()
		update_realm_windows())


func rm_acts_box(parent: Control, acts: Array, doer: Callable) -> void:
	var g := GridContainer.new()
	g.columns = 2
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 4)
	parent.add_child(g)
	for a in acts:
		var id: String = String(a["id"])
		var arg: String = String(a.get("arg", ""))
		rm_act_btn(g, a, func() -> void: doer.call(id, arg))


func update_realm_windows() -> void:
	if rm_btn != null:
		rm_btn.visible = rl_on()
	if tut_panel != null:
		update_tutorial()
	if rm_ov == null or not rm_ov.visible:
		return
	if not current_event.is_empty():
		set_realm_open(false)
		return
	for k in rm_tabs:
		(rm_tabs[k] as Button).set_pressed_no_signal(String(k) == rm_page)
	var stamp := "%s|%d|%s|%s" % [rm_page, turn, rm_dip_sel, str(rm_conf_sel)]
	if stamp == rm_stamp and not rm_dirty:
		return
	rm_stamp = stamp
	rm_dirty = false
	for ch in rm_content.get_children():
		rm_content.remove_child(ch)
		ch.queue_free()
	if not rl_on():
		var off := make_rt(rm_content)
		off.text = "Модуль «Государство и мир» выключен в настройках игры (главное меню → настройки)."
		return
	match rm_page:
		"blocs":
			rm_page_blocs()
		"soc":
			rm_page_soc()
		"dip":
			rm_page_dip()
		"conf":
			rm_page_conf()
		"army":
			rm_page_army()
		"hist":
			rm_page_hist()
		"game":
			rm_page_game()


func rm_do_rl(id: String, _arg: String) -> void:
	rl_do(id)


func rm_sec(title: String) -> void:
	add_title(rm_content, title)


func rm_page_blocs() -> void:
	rm_sec("Союзы: ЕС, евро, НАТО, Шенген")
	var t := make_rt(rm_content)
	var b: Dictionary = rl["b"]
	var s := ""
	s += "ЕС: [b]%s[/b] · евро: [b]%s[/b] · НАТО: [b]%s[/b] · Шенген: [b]%s[/b]%s\n" % [rl_yn(bool(b["eu"])), rl_yn(bool(b["euro"])), rl_yn(bool(b["nato"])), rl_yn(bool(b["schg"])), " (пограничный контроль включён)" if bool(b["ctrl"]) else ""]
	s += "Дефицит (скользящий) %.1f%% ВВП · долг %.0f%% ВВП" % [float(rl["defe"]), debt / maxf(1.0, gdp) * 100.0]
	if bool(b["eu"]) and int(rl["edp"]) > 0:
		s += " · [color=%s]процедура чрезмерного дефицита: %d мес.[/color]" % [COL_WARN, int(rl["edp"])]
	s += "\n"
	for k in rl["acc"]:
		var a: Dictionary = rl["acc"][k]
		var goal: float = {"eu": 40.0, "euro": 24.0, "nato": 18.0}.get(k, 30.0)
		s += "Заявка «%s»: прогресс %.0f%%, критериев выполнено %d из 4\n" % [rl_bloc_name(String(k)), float(a["p"]) / goal * 100.0, int(a["met"])]
	t.text = s
	rm_acts_box(rm_content, rl_acts("blocs"), rm_do_rl)
	rm_sec("Парламент и президент")
	var t2 := make_rt(rm_content)
	t2.text = "Вотум недоверия: [b]%s[/b]%s" % ["конструктивный (оппозиции нужен преемник)" if noc_constr else "обычный", ("\n[color=%s]Сожительство с президентом из оппозиции: %d мес.[/color]" % [COL_WARN, int(rl.get("cohab", 0))]) if rl_cohab() else ""]
	rm_acts_box(rm_content, rl_acts("parl"), rm_do_rl)


func rm_page_soc() -> void:
	var d: Dictionary = rl["d"]
	var e: Dictionary = rl["e"]
	var l: Dictionary = rl["l"]
	var m: Dictionary = rl["m"]
	var lv: Dictionary = rl["lv"]
	rm_sec("Демография и пенсии")
	var t1 := make_rt(rm_content)
	t1.text = "Старше 65 лет: [b]%.1f%%[/b] (при старте %.1f%%) · рождаемость [b]%.2f[/b] · давление пенсий на бюджет [b]+%.2f%% ВВП[/b]\nПрограммы: семья %d · миграция %d · пенсионная реформа %d" % [float(d["age"]), float(d["age0"]), float(d["tfr"]), float(d["pen"]), lv["fam"], lv["imm"], lv["ret"]]
	rm_acts_box(rm_content, rl_acts("demo"), rm_do_rl)
	rm_sec("Энергия и климат")
	var t2 := make_rt(rm_content)
	t2.text = "Цена энергии [b]%.0f[/b] (норма 100) · зависимость от импорта [b]%.0f%%[/b] · зелёная доля [b]%.0f%%[/b] · климатический риск [b]%.0f[/b]\nПрограммы: зелёный переход %d · запасы %d" % [float(e["price"]), float(e["dep"]), float(e["green"]), float(e["clim"]), lv["grn"], lv["gas"]]
	rm_acts_box(rm_content, rl_acts("energy"), rm_do_rl)
	rm_sec("Право и коррупция")
	var t3 := make_rt(rm_content)
	t3.text = "Независимость судов [b]%.0f[/b] · коррупция [b]%.0f[/b] (чем выше, тем хуже)" % [float(l["jud"]), float(l["cor"])]
	rm_acts_box(rm_content, rl_acts("law"), rm_do_rl)
	rm_sec("СМИ")
	var t4 := make_rt(rm_content)
	t4.text = "Свобода прессы [b]%.0f[/b] · доверие [b]%.0f[/b] · дезинформация [b]%.0f[/b]%s" % [float(m["free"]), float(m["trust"]), float(m["fake"]), (" · контроль власти ×%d" % int(m["state"])) if int(m["state"]) > 0 else ""]
	rm_acts_box(rm_content, rl_acts("media"), rm_do_rl)
	rm_sec("Регионы: выравнивание")
	var t5 := make_rt(rm_content)
	t5.text = "Выравнивание: уровень %d из 3. Бедные регионы благодарны, богатые недовольны платежами." % int(lv["eq"])
	rm_acts_box(rm_content, rl_acts("region"), rm_do_rl)


func on_dip_sel(idx: int) -> void:
	rm_dip_sel = String(dx_countries()[idx])
	rm_dirty = true
	update_realm_windows()


func rm_page_dip() -> void:
	var cs: Array = dx_countries()
	if rm_dip_sel == "" or not (rm_dip_sel in cs):
		rm_dip_sel = String(tech_nb()[0]) if tech_nb().size() > 0 else String(cs[0])
	rm_sec("Страна-партнёр")
	rm_dip_opt = OptionButton.new()
	rm_dip_opt.focus_mode = Control.FOCUS_NONE
	rm_dip_opt.clip_text = true
	rm_content.add_child(rm_dip_opt)
	for i in cs.size():
		rm_dip_opt.add_item("%s (отношения %.0f)" % [dx_name(String(cs[i])), fed_rel(String(cs[i]))])
		if String(cs[i]) == rm_dip_sel:
			rm_dip_opt.select(i)
	rm_dip_opt.item_selected.connect(on_dip_sel)
	var tinfo := make_rt(rm_content)
	var tr: Dictionary = (dx["tr"] as Dictionary).get(rm_dip_sel, {})
	var names := []
	for k in tr:
		for d in DX_TREATIES:
			if String(d["id"]) == String(k):
				names.append(String(d["name"]))
	tinfo.text = "Отношения: [b]%.0f[/b] · договоры: %s" % [fed_rel(rm_dip_sel), ", ".join(names) if names.size() > 0 else "нет"]
	rm_sec("Договоры и проекты")
	rm_acts_box(rm_content, dx_treaty_acts(rm_dip_sel), rm_do_dx_tr)
	rm_sec("Разведка")
	rm_acts_box(rm_content, dx_spy_acts(rm_dip_sel), rm_do_dx_spy)
	var tlog := make_rt(rm_content)
	tlog.text = "\n".join((dx["log"] as Array).slice(maxi(0, (dx["log"] as Array).size() - 8)))


func rm_do_dx_tr(id: String, arg: String) -> void:
	dx_treaty_do(id, arg if arg != "" else rm_dip_sel)


func rm_do_dx_spy(id: String, arg: String) -> void:
	dx_spy_do(id, arg if arg != "" else rm_dip_sel)


func rm_page_conf() -> void:
	rm_sec("Идущие конфликты")
	var cf: Array = rv.get("conf", []) if rv_on() else []
	if cf.is_empty():
		var t0 := make_rt(rm_content)
		t0.text = "Сейчас внутренних конфликтов нет."
	rm_conf_sel = clampi(rm_conf_sel, 0, maxi(0, cf.size() - 1))
	for k in cf.size():
		var c: Dictionary = cf[k]
		var fi: Dictionary = c.get("fi", {"gov": [], "reb": [], "pk": false})
		var t := make_rt(rm_content)
		var gov_n := []
		for x in fi["gov"]:
			gov_n.append(dx_name(String(x)))
		var reb_n := []
		for x2 in fi["reb"]:
			reb_n.append(dx_name(String(x2)))
		t.text = "[b]%s[/b]: контроль повстанцев %.0f%% · сила повстанцев %.0f · потери ≈ %.1f тыс.\nПомогают правительству: %s · помогают повстанцам: %s · миротворцы: %s%s" % [c["name"], float(c["ctl"]), float(c["R"]), float(c["kia"]), ", ".join(gov_n) if gov_n.size() > 0 else "никто", ", ".join(reb_n) if reb_n.size() > 0 else "никто", "да" if bool(fi["pk"]) else "нет", (" · перемирие %d мес." % int(c["truce"])) if int(c["truce"]) > 0 and int(c["truce"]) < 9000 else ""]
		var kk: int = k
		rm_acts_box(rm_content, dx_conf_acts(k), func(id: String, _a: String) -> void: dx_conf_do(id, kk))
	rm_sec("Новые государства и признание")
	var tr := make_rt(rm_content)
	var rt: String = dx_rec_text() if rv_on() else ""
	tr.text = rt if rt != "" else "Новых государств нет."
	rm_acts_box(rm_content, dx_rec_acts(), func(id: String, arg: String) -> void: dx_rec_do(id, arg))
	rm_sec("Мирные шаги на карте")
	var t3 := make_rt(rm_content)
	t3.text = "Налоговая автономия, признание языка, конституционная комиссия и согласованный референдум доступны в окне «Кризисы» (кнопки действий региона)."


func rm_page_army() -> void:
	rm_sec("Армия как политический игрок")
	var t := make_rt(rm_content)
	var a: Dictionary = dx["army"]
	t.text = "Лояльность армии [b]%.0f[/b] · амбиции генералов [b]%.0f[/b] (при низкой лояльности и высоких амбициях растёт риск переворота)" % [float(a["loy"]), float(a["amb"])]
	rm_acts_box(rm_content, dx_army_acts(), func(id: String, _g: String) -> void: dx_army_do(id))
	rm_sec("Наука: проекты, этика, утечка умов")
	var t2 := make_rt(rm_content)
	var pj := []
	for p in dx["proj"]:
		pj.append("%s (ещё %d мес.)" % [dx_name(String(p["cc"])), int(p["left"])])
	t2.text = "Множитель скорости исследований: [b]×%.2f[/b] · пассивное изучение: ×%.1f · проекты: %s\nЭтика технологий: уровень [b]%d[/b] из 3" % [tech_adj, tech_pas_mult, ", ".join(pj) if pj.size() > 0 else "нет", int(dx["eth"])]
	rm_acts_box(rm_content, dx_eth_acts(), func(id: String, _g: String) -> void: dx_eth_do(id))
	var t3 := make_rt(rm_content)
	t3.text = "Научные проекты и договоры оформляются на странице «Дипломатия и разведка»."


func rm_page_hist() -> void:
	rm_sec("История показателей")
	var h: Dictionary = rl["h"]
	var defs := [["gdp", "ВВП, млрд €", Color(0.45, 0.8, 1.0)], ["debt", "Долг, % ВВП", Color(1.0, 0.6, 0.4)], ["appr", "Рейтинг, %", Color(0.5, 0.95, 0.6)],
		["unemp", "Безработица, %", Color(1.0, 0.85, 0.4)], ["infl", "Инфляция, %", Color(0.9, 0.5, 0.9)], ["growth", "Рост ВВП, %", Color(0.6, 0.9, 0.9)],
		["age", "Старше 65 лет, %", Color(0.8, 0.7, 0.5)], ["cor", "Коррупция", Color(1.0, 0.45, 0.45)], ["jud", "Независимость судов", Color(0.55, 0.8, 1.0)],
		["free", "Свобода прессы", Color(0.7, 1.0, 0.7)], ["price", "Цена энергии", Color(1.0, 0.75, 0.3)], ["green", "Зелёная доля, %", Color(0.4, 0.9, 0.5)]]
	var g := GridContainer.new()
	g.columns = 3
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	rm_content.add_child(g)
	for d in defs:
		var sp: Control = Spark.new()
		sp.custom_minimum_size = Vector2(200.0, 110.0)
		sp.title = "%s: %.1f" % [String(d[1]), float((h[String(d[0])] as Array).back()) if (h[String(d[0])] as Array).size() > 0 else 0.0]
		sp.series = [{"v": (h[String(d[0])] as Array).duplicate(), "c": d[2], "n": String(d[1])}]
		g.add_child(sp)
	var t := make_rt(rm_content)
	t.text = "Показатели записываются каждый месяц; на графиках — вся история игры."


func rm_slot_row(slot: int) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	rm_content.add_child(hb)
	var info: String = sv_info(slot)
	var lab := Label.new()
	lab.text = "Слот %d: %s" % [slot, info if info != "" else "пусто"]
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(lab)
	var bs := Button.new()
	bs.text = "Сохранить"
	bs.focus_mode = Control.FOCUS_NONE
	bs.pressed.connect(func() -> void:
		sv_save(slot)
		rm_dirty = true
		update_realm_windows())
	hb.add_child(bs)
	var bl := Button.new()
	bl.text = "Загрузить"
	bl.focus_mode = Control.FOCUS_NONE
	bl.disabled = info == ""
	bl.pressed.connect(func() -> void:
		if sv_load(slot):
			rm_dirty = true
			update_realm_windows())
	hb.add_child(bl)


func rm_page_game() -> void:
	rm_sec("Сохранения")
	var t0 := make_rt(rm_content)
	t0.text = "Сохранение записывает всё состояние страны. Слоты у каждой страны свои."
	for s in [1, 2, 3]:
		rm_slot_row(s)
	rm_sec("Откат")
	var t := make_rt(rm_content)
	var hs: Array = sv_hist
	var names := []
	for x in hs:
		names.append(String(x["date"]))
	t.text = "Автоснимки (раз в год): %s" % (", ".join(names) if names.size() > 0 else "пока нет — первый появится в январе")
	var rb := fed_btn("Откатиться на предыдущий снимок", rm_content, "Вернёт игру на последний снимок до текущего месяца. Всё после него будет потеряно.")
	rb.disabled = hs.is_empty()
	rb.pressed.connect(func() -> void:
		sv_rollback()
		rm_dirty = true
		update_realm_windows())
	rm_sec("Подсказки для новичка")
	var tb := fed_btn("Показать подсказки сначала", rm_content, "Короткий тур по окнам игры.")
	tb.pressed.connect(func() -> void:
		tut_idx = 0
		update_tutorial())
	rm_sec("Справка по показателям")
	var th := make_rt(rm_content)
	th.text = "[b]Политический капитал[/b] — ресурс решений; копится со временем.\n[b]Рейтинг[/b] — доля довольных граждан; от него зависят выборы.\n[b]Сепаратизм[/b] — желание региона отделиться; падает от автономии и диалога.\n[b]Коррупция[/b] — утечка денег и доверия; растёт при слабых судах и несвободных СМИ.\n[b]Давление пенсий[/b] — дополнительные расходы из-за старения населения.\n[b]Цена энергии[/b] — индекс: 100 — норма; выше — инфляция и спад.\n[b]Лояльность армии[/b] — низкая лояльность и высокие амбиции повышают риск переворота."
	rm_sec("Итог правления")
	var ts := make_rt(rm_content)
	ts.text = rl_summary_text()


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
	var ov_open: bool = (rm_ov != null and rm_ov.visible) or (tech_ov != null and tech_ov.visible) or (cr_ov != null and cr_ov.visible)
	var show_it: bool = tut_idx >= 0 and tut_idx < TUT_STEPS.size() and current_event.is_empty() and not ov_open
	tut_panel.visible = show_it
	if show_it:
		tut_label.text = "Подсказка %d из %d\n%s" % [tut_idx + 1, TUT_STEPS.size(), String(TUT_STEPS[tut_idx])]
