# Интерфейс: «Регионы и автономия» (desk 8) и «Территории» (desk 9).
extends "res://scripts/ui/ui_events.gd"

const TW_MULT := [1.0, 1.5, 2.0]

var fw_state_rt: RichTextLabel
var fw_upper_rt: RichTextLabel
var fw_btn_up: Button
var fw_btn_down: Button
var fw_eq_btns: Array = []
var fw_list_rt: RichTextLabel
var fw_reg_rt: RichTextLabel
var fw_comp_rows: Array = []
var fw_st_dn: Button
var fw_st_up: Button
var fw_admit_btn: Button
var fw_bulk_rows: Array = []
var fw_dem_box: VBoxContainer
var tw_buy_pick: OptionButton
var tw_buy_mult: OptionButton
var tw_buy_how: OptionButton
var tw_buy_rt: RichTextLabel
var tw_buy_btn: Button
var tw_buy_units: Array = []
var tw_un_pick: OptionButton
var tw_un_terms: OptionButton
var tw_un_rt: RichTextLabel
var tw_un_btn: Button
var tw_court_btn: Button
var tw_un_cc: Array = []
var tw_sell_lbl: Label
var tw_sell_pick: OptionButton
var tw_sell_mult: OptionButton
var tw_sell_rt: RichTextLabel
var tw_sell_btn: Button
var tw_sell_cc: Array = []
var tw_sell_for := -1
var tw_terr_box: VBoxContainer
var tw_stat_rt: RichTextLabel
var fr_rt: RichTextLabel
var fr_buy_btn: Button
var fr_back_btn: Button


func fed_btn(text: String, parent: Control, tip: String = "") -> Button:
	var b := make_button(text, parent)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.tooltip_text = tip
	return b


func fed_opt(parent: Control, items: Array, tip: String = "") -> OptionButton:
	var o := OptionButton.new()
	o.focus_mode = Control.FOCUS_NONE
	o.clip_text = true
	o.fit_to_longest_item = false
	o.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	o.tooltip_text = tip
	for it in items:
		o.add_item(String(it))
	parent.add_child(o)
	return o


func build_fregion_window() -> void:
	var w: FloatWindow = new_window("fregion", "Чужой регион: сведения", 2, Rect2(0.0, 0.19, 0.25, 0.81))
	fr_rt = make_rt(w.body)
	fr_buy_btn = fed_btn("Перейти к покупке региона", w.body, "Откроет «Территории» с этим регионом: покупка возможна, только если он граничит с вашей страной и конституция продавца это допускает.")
	fr_buy_btn.pressed.connect(on_fregion_buy)
	fr_back_btn = fed_btn("← Назад к стране", w.body)
	fr_back_btn.pressed.connect(on_fregion_back)
	add_note(w.body, "Щёлкните по стране на карте ещё раз — откроется регион под курсором; щелчок по тому же региону возвращает к стране. Купить не весь регион, а одну или несколько АТЕ можно в окне «Административная реформа (АТЕ)» (кнопка в окне «Карта»).")


func on_fregion_back() -> void:
	fmap_win_open = false
	map_apply_mode()
	refresh()


func on_fregion_buy() -> void:
	if fmap_sel_unit_valid():
		show_desk(9)
		update_terr_desk()
		var k: int = tw_buy_units.find(map_sel_unit)
		if k >= 0:
			tw_buy_pick.select(k)
			update_terr_desk()


func fmap_sel_unit_valid() -> bool:
	return map_sel_unit >= 0 and map_sel_unit < WORLD_UNITS.size()


func update_fregion() -> void:
	if fr_rt == null or not fmap_win_open or not fmap_sel_unit_valid():
		return
	var ui: int = map_sel_unit
	var cc: String = fed_unit_cc(ui)
	var uid: String = String(WORLD_UNITS[ui]["id"])
	var wr: Dictionary = fed_wreg(cc, uid)
	if wr.is_empty():
		fr_rt.text = "Нет данных."
		return
	var t := "[b][font_size=17]%s[/font_size][/b]\n[color=%s]%s[/color]\n\n" % [wr["name"], COL_DIM, WORLD[cc]["name"]]
	t += "Население: [b]%.1f млн[/b] · ВВП на душу: [b]%.0f%%[/b] от среднего по стране\n" % [float(wr["popm"]), float(wr["pc"]) * 100.0]
	for kv in [["dev", "Развитие"], ["infra", "Инфраструктура"], ["edu", "Образование"], ["health", "Здоровье"], ["env", "Экология"], ["unrest", "Недовольство"], ["loy", "Лояльность центру"]]:
		if wr.has(kv[0]):
			t += "%s: [color=%s]%.0f[/color]\n" % [kv[1], "#" + stat_color(float(wr[kv[0]]), kv[0] == "unrest"), float(wr[kv[0]])]
	if wr.has("desc"):
		t += "\n[color=%s]%s[/color]\n" % [COL_DIM, wr["desc"]]
	var q := terr_buy_quote(ui, 1.0, "subject")
	t += "\n[b]Покупка:[/b] "
	if bool(q["ok"]):
		t += "возможна, цена ≈ [b]%.0f млрд[/b] (шанс согласия %s)" % [float(q.get("price", 0.0)), fed_pct(float(q.get("p", 0.0)))]
	else:
		t += "сейчас невозможна\n" + fed_why_text(q)
	fr_rt.text = t
	fr_buy_btn.disabled = false


func build_fed_windows() -> void:
	build_fregion_window()
	# ---- desk 8: регионы и автономия ----
	var w: FloatWindow = new_window("fw_state", "Устройство государства", 8, Rect2(0.0, 0.0, 0.24, 0.62))
	fw_state_rt = make_rt(w.body)
	fw_upper_rt = make_rt(w.body)
	fw_btn_up = fed_btn("Реформа: усилить регионы", w.body)
	fw_btn_up.pressed.connect(on_fed_reform.bind(1))
	fw_btn_down = fed_btn("Реформа: усилить центр", w.body)
	fw_btn_down.pressed.connect(on_fed_reform.bind(-1))
	add_title(w.body, "Выравнивание бюджетов регионов")
	add_note(w.body, "Богатые регионы делятся с бедными. Сильное выравнивание радует бедных и злит богатых; слабое — наоборот. Менять можно раз в год.")
	fw_eq_btns.clear()
	var eqr := HBoxContainer.new()
	eqr.add_theme_constant_override("separation", 4)
	w.body.add_child(eqr)
	for k in 4:
		var eb := Button.new()
		eb.toggle_mode = true
		eb.focus_mode = Control.FOCUS_NONE
		eb.text = String(FED_EQ[k]).capitalize()
		eb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		eb.theme_type_variation = "SmallButton"      # v37: при 1366×768 четыре кнопки не помещались
		eb.clip_text = true
		eb.custom_minimum_size = Vector2(30.0, 0.0)
		eb.pressed.connect(on_fed_eq.bind(k))
		eqr.add_child(eb)
		fw_eq_btns.append(eb)

	w = new_window("fw_list", "Субъекты и регионы", 8, Rect2(0.24, 0.0, 0.23, 0.62))
	fw_list_rt = make_rt(w.body)
	fw_list_rt.meta_clicked.connect(on_fed_meta)
	add_note(w.body, "Щёлкните по названию региона, чтобы управлять его полномочиями справа.")

	w = new_window("fw_reg", "Полномочия выбранного региона", 8, Rect2(0.47, 0.0, 0.23, 1.0))
	fw_reg_rt = make_rt(w.body)
	fw_comp_rows.clear()
	add_title(w.body, "Распределение полномочий")
	add_note(w.body, "◀ — забрать себе, ▶ — передать региону. Каждая передача и возврат стоят политического капитала; возврат полномочий злит регион, особенно сепаратистский.")
	for s in 5:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		w.body.add_child(row)
		var lb := Label.new()
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lb.add_theme_font_size_override("font_size", 13)
		lb.tooltip_text = String(FED_SPH[s][2])
		row.add_child(lb)
		var dn := Button.new()
		dn.text = "◀"
		dn.focus_mode = Control.FOCUS_NONE
		dn.pressed.connect(on_fed_comp.bind(s, -1))
		row.add_child(dn)
		var up := Button.new()
		up.text = "▶"
		up.focus_mode = Control.FOCUS_NONE
		up.pressed.connect(on_fed_comp.bind(s, 1))
		row.add_child(up)
		var dsc := Label.new()
		dsc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dsc.add_theme_font_size_override("font_size", 11)
		dsc.add_theme_color_override("font_color", C_DIM)
		dsc.custom_minimum_size = Vector2(40.0, 0.0)
		w.body.add_child(dsc)
		fw_comp_rows.append({"lbl": lb, "dn": dn, "up": up, "desc": dsc})
	add_title(w.body, "Статус региона")
	add_note(w.body, "Обычный → расширенная автономия → особый статус (как у Наварры, Сицилии, Азорских островов). Статус даёт потолок полномочий и лояльность, но повышение требует парламентского большинства.")
	var sr := HBoxContainer.new()
	sr.add_theme_constant_override("separation", 4)
	w.body.add_child(sr)
	fw_st_dn = fed_btn("Понизить статус", sr)
	fw_st_dn.pressed.connect(on_fed_status.bind(-1))
	fw_st_up = fed_btn("Повысить статус", sr)
	fw_st_up.pressed.connect(on_fed_status.bind(1))
	fw_admit_btn = fed_btn("Принять в субъекты федерации", w.body)
	fw_admit_btn.pressed.connect(on_fed_admit)

	w = new_window("fw_bulk", "Реформа для всех регионов сразу", 8, Rect2(0.0, 0.62, 0.24, 0.38))
	add_note(w.body, "Меняет сферу везде, где это возможно. Цена — 40% от суммы по регионам. Для федераций возврат полномочий требует согласия верхней палаты.", true)
	fw_bulk_rows.clear()
	for s in 5:
		var row2 := HBoxContainer.new()
		row2.add_theme_constant_override("separation", 4)
		w.body.add_child(row2)
		var lb2 := Label.new()
		lb2.text = String(FED_SPH[s][1])
		lb2.tooltip_text = String(FED_SPH[s][2])
		lb2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lb2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lb2.add_theme_font_size_override("font_size", 13)
		row2.add_child(lb2)
		var d2 := Button.new()
		d2.text = "◀ всем"
		d2.focus_mode = Control.FOCUS_NONE
		d2.pressed.connect(on_fed_bulk.bind(s, -1))
		row2.add_child(d2)
		var u2 := Button.new()
		u2.text = "всем ▶"
		u2.focus_mode = Control.FOCUS_NONE
		u2.pressed.connect(on_fed_bulk.bind(s, 1))
		row2.add_child(u2)
		fw_bulk_rows.append({"dn": d2, "up": u2})

	w = new_window("fw_dem", "Обращения регионов", 8, Rect2(0.24, 0.62, 0.23, 0.38))
	fw_dem_box = w.body

	# ---- desk 9: территории ----
	w = new_window("tw_buy", "Покупка региона", 9, Rect2(0.0, 0.0, 0.26, 1.0))
	add_note(w.body, "Можно купить регион соседней страны, если её конституция это допускает. Решают: правительство продавца, референдум в самом регионе и (если нужен) ваш референдум. Цена платится в долг.", true)
	tw_buy_pick = fed_opt(w.body, [], "Соседние регионы других стран")
	tw_buy_pick.item_selected.connect(on_tw_changed)
	tw_buy_mult = fed_opt(w.body, ["Цена ×1,0 (рыночная)", "Цена ×1,5 (щедрое предложение)", "Цена ×2,0 (очень щедро)"], "Чем выше цена, тем охотнее соглашаются власти продавца и жители региона")
	tw_buy_mult.item_selected.connect(on_tw_changed)
	tw_buy_how = fed_opt(w.body, ["Принять как новый субъект", "Присоединить как федеральную территорию"], "Новый субъект получает полномочия и места в верхней палате (если она есть и согласна). Федеральная территория управляется центром, её можно принять в субъекты позже.")
	tw_buy_how.item_selected.connect(on_tw_changed)
	tw_buy_rt = make_rt(w.body)
	tw_buy_btn = fed_btn("Предложить сделку", w.body)
	tw_buy_btn.pressed.connect(on_tw_buy)

	w = new_window("tw_union", "Объединение стран", 9, Rect2(0.26, 0.0, 0.23, 0.58))
	add_note(w.body, "Добровольное объединение: страна целиком входит в вашу, все её регионы становятся вашими. Нужны тёплые отношения (не ниже 60), референдум у них и конституционное большинство у вас. Вы принимаете 80% их долга.", true)
	tw_un_pick = fed_opt(w.body, [], "Соседние страны")
	tw_un_pick.item_selected.connect(on_tw_changed)
	tw_un_terms = fed_opt(w.body, ["Полное слияние (обычные субъекты)", "Союзный договор (расширенная автономия для их регионов)"], "Договор повышает шансы на согласие и сохраняет им самостоятельность")
	tw_un_terms.item_selected.connect(on_tw_changed)
	tw_un_rt = make_rt(w.body)
	tw_un_btn = fed_btn("Предложить объединение", w.body)
	tw_un_btn.pressed.connect(on_tw_union)
	tw_court_btn = fed_btn("Улучшить отношения (8 капитала)", w.body, "Дипломатическая работа: отношения растут, но со временем остывают. Раз в полгода.")
	tw_court_btn.pressed.connect(on_tw_court)

	w = new_window("tw_sell", "Продажа выбранного региона", 9, Rect2(0.26, 0.58, 0.23, 0.42))
	tw_sell_lbl = Label.new()
	tw_sell_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	w.body.add_child(tw_sell_lbl)
	tw_sell_pick = fed_opt(w.body, [], "Соседняя страна-покупатель")
	tw_sell_pick.item_selected.connect(on_tw_changed)
	tw_sell_mult = fed_opt(w.body, ["Цена ×1,0", "Цена ×1,5", "Цена ×2,0"], "Чем выше цена, тем меньше шансов, что покупатель согласится")
	tw_sell_mult.item_selected.connect(on_tw_changed)
	tw_sell_rt = make_rt(w.body)
	tw_sell_btn = fed_btn("Предложить продажу", w.body)
	tw_sell_btn.pressed.connect(on_tw_sell)

	w = new_window("tw_terr", "Территории и приём в субъекты", 9, Rect2(0.49, 0.0, 0.21, 1.0))
	tw_stat_rt = make_rt(w.body)
	add_title(w.body, "Федеральные территории")
	add_note(w.body, "Приём в субъекты: прошло ≥ 12 месяцев, лояльность ≥ 48, недовольство ≤ 40, большинство в парламенте и согласие верхней палаты.", true)
	tw_terr_box = VBoxContainer.new()
	tw_terr_box.add_theme_constant_override("separation", 4)
	w.body.add_child(tw_terr_box)


# ---------- обработчики ----------


func on_fed_reform(dir: int) -> void:
	fed_reform(dir)


func on_fed_eq(k: int) -> void:
	if not fed_set_eq(k):
		refresh()


func on_fed_meta(meta: Variant) -> void:
	select_region(int(String(meta)))


func on_fed_comp(s: int, dir: int) -> void:
	fed_comp_step(selected_region, s, dir)


func on_fed_bulk(s: int, dir: int) -> void:
	fed_comp_all(s, dir)


func on_fed_status(dir: int) -> void:
	fed_status_step(selected_region, dir)


func on_fed_admit() -> void:
	fed_admit(selected_region)


func on_fed_demand(k: int, accept: bool) -> void:
	if k < (fst["demand"] as Array).size():
		fed_demand_decide(fst["demand"][k], accept)


func on_tw_changed(_i: int = 0) -> void:
	update_terr_desk()


func on_tw_buy() -> void:
	var k: int = tw_buy_pick.selected
	if k < 0 or k >= tw_buy_units.size():
		return
	terr_buy(int(tw_buy_units[k]), float(TW_MULT[tw_buy_mult.selected]), "subject" if tw_buy_how.selected == 0 else "territory")


func on_tw_union() -> void:
	var k: int = tw_un_pick.selected
	if k < 0 or k >= tw_un_cc.size():
		return
	union_do(String(tw_un_cc[k]), tw_un_terms.selected)


func on_tw_court() -> void:
	var k: int = tw_un_pick.selected
	if k >= 0 and k < tw_un_cc.size():
		fed_court(String(tw_un_cc[k]))


func on_tw_sell() -> void:
	var k: int = tw_sell_pick.selected
	if k < 0 or k >= tw_sell_cc.size():
		return
	terr_sell(selected_region, String(tw_sell_cc[k]), float(TW_MULT[tw_sell_mult.selected]))


func on_tw_admit(i: int) -> void:
	fed_admit(i)


# ---------- обновление ----------


func update_fed_windows() -> void:
	if fw_state_rt == null:
		return
	if current_desk == 8:
		update_fed_desk()
	elif current_desk == 9:
		update_terr_desk()


func fed_pct(p: float) -> String:
	var col := COL_GOOD if p >= 0.5 else (COL_WARN if p >= 0.25 else COL_BAD)
	return "[color=%s]%.0f%%[/color]" % [col, p * 100.0]


func update_fed_desk() -> void:
	var st := fed_stats()
	var c := fed_cfg()
	var t := "[b][font_size=17]%s[/font_size][/b]\n" % FED_LVL_NAMES[int(fst["lvl"])]
	t += "[color=%s]%s[/color]\n\n" % [COL_DIM, c["note"]]
	t += "Субъектов: [b]%d[/b] · расширенная автономия: %d · особый статус: %d · федеральных территорий: %d\n" % [st["n"], st["st1"], st["st2"], st["terr"]]
	t += "Бюджетное выравнивание: [b]%s[/b]" % FED_EQ[int(fst["eq"])]
	fw_state_rt.text = t
	var up := fed_upper()
	if bool(up["on"]):
		fw_upper_rt.text = "[b]%s[/b]: у вашей коалиции %d из %d голосов (нужно %d). %s" % [up["name"], up["yes"], up["total"], up["need"], ("Палата может заблокировать возврат полномочий и приём новых субъектов." if bool(up["binding"]) else "Палата может лишь задержать законы.")]
	else:
		fw_upper_rt.text = "[color=%s]Верхней палаты с правом блокировки нет.[/color]" % COL_DIM
	var lv: int = int(fst["lvl"])
	var why_up := fed_reform_check(1)
	var why_dn := fed_reform_check(-1)
	fw_btn_up.text = "Реформа: %s (30 капитала)" % (FED_LVL_NAMES[lv + 1].to_lower() if lv < 2 else "—")
	fw_btn_up.disabled = why_up != "" or game_over
	fw_btn_up.tooltip_text = why_up if why_up != "" else "Конституционная реформа: регионы получают больше прав в образовании, здравоохранении и экономике. Нужно ≥ %.0f%% мест у коалиции%s." % [float(c["need"]) * 100.0, " и успех референдума" if bool(c["refd"]) else ""]
	fw_btn_down.text = "Реформа: %s (30 капитала)" % (FED_LVL_NAMES[lv - 1].to_lower() if lv > 0 else "—")
	fw_btn_down.disabled = why_dn != "" or game_over
	fw_btn_down.tooltip_text = why_dn if why_dn != "" else "Конституционная реформа: регионы теряют часть прав, центр сильнее. Регионы недовольны, особенно сепаратистские."
	for k in 4:
		var eb: Button = fw_eq_btns[k]
		eb.set_pressed_no_signal(k == int(fst["eq"]))
		eb.disabled = game_over or (k != int(fst["eq"]) and fed_cd_get("eq") > 0)
		eb.tooltip_text = "Недавно менялось (ещё %d мес.)" % fed_cd_get("eq") if fed_cd_get("eq") > 0 else "Стоимость смены — 6 капитала."
	# список регионов
	var l := "[table=5][cell][color=%s]Регион[/color][/cell][cell][color=%s] Статус[/color][/cell][cell][color=%s] Лоял.[/color][/cell][cell][color=%s] Недов.[/color][/cell][cell][color=%s] Права[/color][/cell]" % [COL_DIM, COL_DIM, COL_DIM, COL_DIM, COL_DIM]
	for i in regions.size():
		var r: Dictionary = regions[i]
		var tot := 0
		for s in 5:
			tot += int(r["comp"][s])
		var stn: String = "терр." if bool(r["terr"]) else ["обыч.", "расшир.", "особый"][int(r["status"])]
		var nm := "[url=%d]%s%s[/url]" % [i, "▶ " if i == selected_region else "", REGIONS[i]["short"]]
		l += "[cell]%s[/cell][cell] %s[/cell][cell] [color=%s]%.0f[/color][/cell][cell] [color=%s]%.0f[/color][/cell][cell] %d/15[/cell]" % [nm, stn, "#" + stat_color(float(r["loy"]), false), float(r["loy"]), "#" + stat_color(float(r["unrest"]), true), float(r["unrest"]), tot]
	l += "[/table]"
	fw_list_rt.text = l
	# выбранный регион
	var i2 := selected_region
	if i2 < 0 or i2 >= regions.size():
		return
	var r2: Dictionary = regions[i2]
	var gv: Dictionary = r2["gov"]
	var h := "[b][font_size=16]%s[/font_size][/b]\n" % REGIONS[i2]["name"]
	h += "Статус: [b]%s[/b]%s\n" % ["федеральная территория" if bool(r2["terr"]) else FED_ST[int(r2["status"])], ""]
	h += "Лояльность %.0f · недовольство %.0f · автономия %.0f · развитие %.0f\n" % [float(r2["loy"]), float(r2["unrest"]), float(r2["auto"]), float(r2["dev"])]
	h += "Глава: %s (%s, умение %.0f) — от умения главы зависит, насколько полезна самостоятельность." % [gv["name"], GOV_KINDS[int(gv["kind"])], gv["skill"]]
	if bool(r2["terr"]):
		h += "\n[color=%s]Территория управляется напрямую из центра: полномочий нет, а в верхней палате она не представлена.[/color]" % COL_WARN
	fw_reg_rt.text = h
	for s in 5:
		var row: Dictionary = fw_comp_rows[s]
		var d := fed_d(i2, s)
		var mark := "" if d == 0 else (" (+%d)" % d if d > 0 else " (%d)" % d)
		(row["lbl"] as Label).text = "%s: %s%s" % [FED_SPH[s][1], FED_LV[int(r2["comp"][s])], mark]
		var lvn: int = clampi(int(r2["comp"][s]), 0, 3)
		(row["desc"] as Label).text = loc("Сейчас: %s. %s" % [String(FED_LV_DESC[s][lvn]), String(FED_SPH[s][2])])
		var wu := fed_comp_check(i2, s, 1)
		var wd := fed_comp_check(i2, s, -1)
		(row["up"] as Button).disabled = wu != "" or game_over
		(row["dn"] as Button).disabled = wd != "" or game_over
		(row["up"] as Button).tooltip_text = wu if wu != "" else "Передать региону: %.0f капитала." % fed_comp_cost(i2, s, 1)
		(row["dn"] as Button).tooltip_text = wd if wd != "" else "Забрать себе: %.0f капитала." % fed_comp_cost(i2, s, -1)
		var br: Dictionary = fw_bulk_rows[s]
		var bu := 0
		var bd := 0
		for j in regions.size():
			if fed_comp_check(j, s, 1) == "":
				bu += 1
			if fed_comp_check(j, s, -1) == "":
				bd += 1
		(br["up"] as Button).disabled = bu == 0 or game_over
		(br["dn"] as Button).disabled = bd == 0 or game_over
		(br["up"] as Button).tooltip_text = "Можно в %d регионах." % bu
		(br["dn"] as Button).tooltip_text = "Можно в %d регионах." % bd
	var su := fed_status_check(i2, 1)
	var sd := fed_status_check(i2, -1)
	fw_st_up.disabled = su != "" or game_over
	fw_st_dn.disabled = sd != "" or game_over
	fw_st_up.tooltip_text = su if su != "" else "14 капитала. Регион становится лояльнее, растёт потолок полномочий."
	fw_st_dn.tooltip_text = sd if sd != "" else "10 капитала. Регион будет возмущён."
	fw_admit_btn.visible = bool(r2["terr"])
	var wa := fed_admit_check(i2)
	fw_admit_btn.disabled = wa != "" or game_over
	fw_admit_btn.tooltip_text = wa if wa != "" else "10 капитала. Регион получает полномочия и голоса в верхней палате."
	# обращения
	for ch in fw_dem_box.get_children():
		ch.queue_free()
	var dl := Label.new()
	dl.text = "Обращения регионов"
	dl.add_theme_font_size_override("font_size", 14)
	fw_dem_box.add_child(dl)
	if (fst["demand"] as Array).is_empty():
		var nl := Label.new()
		nl.text = "Сейчас регионы ничего не требуют. Недовольные регионы (недовольство ≥ 42, лояльность ≤ 46) могут выдвинуть требования; на ответ — 6 месяцев."
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nl.add_theme_font_size_override("font_size", 13)
		nl.add_theme_color_override("font_color", C_DIM)
		fw_dem_box.add_child(nl)
	for k in (fst["demand"] as Array).size():
		var dm: Dictionary = fst["demand"][k]
		var di := fed_idx_of_uid(String(dm["uid"]))
		if di < 0:
			continue
		var hl := Label.new()
		hl.text = "«%s» требует %s (осталось %d мес.)" % [REGIONS[di]["short"], fed_demand_text(dm), 6 - int(dm["age"])]
		hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hl.add_theme_font_size_override("font_size", 13)
		fw_dem_box.add_child(hl)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 4)
		fw_dem_box.add_child(hb)
		var ya := fed_btn("Принять", hb, "Исполнить требование (стоит капитала). Регион станет лояльнее.")
		ya.pressed.connect(on_fed_demand.bind(k, true))
		var na := fed_btn("Отклонить", hb, "Регион обидится: лояльность ниже, недовольство выше.")
		na.pressed.connect(on_fed_demand.bind(k, false))


func fed_why_text(q: Dictionary) -> String:
	var t := ""
	for w in q["why"]:
		t += "[color=%s]✖ %s[/color]\n" % [COL_BAD, w]
	return t


func tw_fill_options(o: OptionButton, labels: Array, keep: int) -> void:
	o.clear()
	for lb in labels:
		o.add_item(String(lb))
	if labels.size() > 0:
		o.select(clampi(keep, 0, labels.size() - 1))


func update_terr_desk() -> void:
	# --- покупка ---
	var units: Array = fed_adjacent_units()
	var sig: Array = []
	var lbls: Array = []
	for ui in units:
		var cc := fed_unit_cc(int(ui))
		var wr := fed_wreg(cc, String(WORLD_UNITS[int(ui)]["id"]))
		if wr.is_empty():
			continue
		sig.append(int(ui))
		lbls.append("%s — %s (%.1f млн)" % [WORLD[cc]["name"], wr["short"], float(wr["popm"])])
	if sig != tw_buy_units:
		var keep := tw_buy_units.find(tw_buy_units[tw_buy_pick.selected]) if (tw_buy_pick.selected >= 0 and tw_buy_pick.selected < tw_buy_units.size()) else 0
		var prev: int = int(tw_buy_units[tw_buy_pick.selected]) if (tw_buy_pick.selected >= 0 and tw_buy_pick.selected < tw_buy_units.size()) else -1
		tw_buy_units = sig
		tw_fill_options(tw_buy_pick, lbls, sig.find(prev) if prev >= 0 and sig.has(prev) else 0)
	if tw_buy_units.is_empty():
		tw_buy_rt.text = "[color=%s]Рядом нет чужих регионов.[/color]" % COL_DIM
		tw_buy_btn.disabled = true
	else:
		var q := terr_buy_quote(int(tw_buy_units[tw_buy_pick.selected]), float(TW_MULT[tw_buy_mult.selected]), "subject" if tw_buy_how.selected == 0 else "territory")
		var tb := "[b]%s[/b] (%s), %.1f млн жителей\n" % [q["name"], q["country"], q["pop"]]
		tb += fed_why_text(q)
		if q.has("price"):
			tb += "ВВП региона %.0f млрд; цена [b]%.0f млрд[/b] (%.1f%% вашего ВВП, в долг); политкапитал: %.0f\n" % [q["gdp_r"], q["price"], q["gdp_pct"], q["cap"]]
			tb += "Отношения с продавцом: %.0f\n" % q["rel"]
			tb += "Шанс согласия: правительство продавца %s × жители региона %s" % [fed_pct(float(q["p_gov"])), fed_pct(float(q["p_loc"]))]
			if float(q["p_dom"]) < 1.0:
				tb += " × ваш референдум %s" % fed_pct(float(q["p_dom"]))
			tb += " = [b]%s[/b]\n" % fed_pct(float(q["p"]))
			if bool(q.get("admit_blocked", false)) and tw_buy_how.selected == 0:
				tb += "[color=%s]Верхняя палата не одобрит нового субъекта — регион будет присоединён как федеральная территория.[/color]\n" % COL_WARN
			var dmx: Dictionary = q["need_dom"]
			tb += "[color=%s]%s[/color]" % [COL_DIM, dmx["text"]]
		tw_buy_rt.text = tb
		tw_buy_btn.disabled = not bool(q["ok"]) or not bool(q.get("afford", true)) or game_over
		tw_buy_btn.tooltip_text = "Не хватает политического капитала." if not bool(q.get("afford", true)) else ""
	# --- объединение ---
	var ucs: Array = union_candidates()
	if ucs != tw_un_cc:
		var prevc: String = String(tw_un_cc[tw_un_pick.selected]) if (tw_un_pick.selected >= 0 and tw_un_pick.selected < tw_un_cc.size()) else ""
		tw_un_cc = ucs
		var ul: Array = []
		for c in ucs:
			ul.append("%s (%.1f млн, %d рег.)" % [WORLD[c]["name"], float(WORLD[c]["pop"]), (WORLD[c]["regions"] as Array).size()])
		tw_fill_options(tw_un_pick, ul, ucs.find(prevc) if prevc != "" and ucs.has(prevc) else 0)
	if tw_un_cc.is_empty():
		tw_un_rt.text = "[color=%s]Соседних стран нет.[/color]" % COL_DIM
		tw_un_btn.disabled = true
	else:
		var uq := union_quote(String(tw_un_cc[tw_un_pick.selected]), tw_un_terms.selected)
		var tu := "[b]%s[/b]: %.1f млн жителей, ВВП %.0f млрд, %d регионов\n" % [uq["name"], uq["pop"], uq["gdp"], uq["n"]]
		tu += fed_why_text(uq)
		tu += "Отношения: %.0f · принимаемый долг %.0f млрд · политкапитал %.0f\n" % [uq["rel"], uq["debt"], uq["cap"]]
		tu += "Шанс: референдум у них %s" % fed_pct(float(uq["p_x"]))
		if float(uq["p_dom"]) < 1.0:
			tu += " × ваш референдум %s" % fed_pct(float(uq["p_dom"]))
		tu += " = [b]%s[/b]" % fed_pct(float(uq["p"]))
		tw_un_rt.text = tu
		tw_court_btn.disabled = game_over or fed_cd_get("court_" + String(tw_un_cc[tw_un_pick.selected])) > 0
		tw_un_btn.disabled = not bool(uq["ok"]) or cap_spendable() < float(uq["cap"]) or game_over
	# --- продажа ---
	var si := selected_region
	var buyers: Array = terr_sell_buyers(si) if si >= 0 and si < regions.size() else []
	if si != tw_sell_for or buyers != tw_sell_cc:
		tw_sell_for = si
		tw_sell_cc = buyers
		var bl: Array = []
		for c in buyers:
			bl.append(String(WORLD[c]["name"]))
		tw_fill_options(tw_sell_pick, bl, 0)
	tw_sell_lbl.text = "Выбранный регион: %s" % (String(REGIONS[si]["name"]) if si >= 0 and si < REGIONS.size() else "—")
	if buyers.is_empty():
		tw_sell_rt.text = "[color=%s]У этого региона нет соседних стран-покупателей. Выберите на карте приграничный регион.[/color]" % COL_DIM
		tw_sell_btn.disabled = true
	else:
		var sq := terr_sell_quote(si, String(buyers[tw_sell_pick.selected]), float(TW_MULT[tw_sell_mult.selected]))
		var ts := fed_why_text(sq)
		ts += "Цена [b]%.0f млрд[/b] (долг уменьшится); политкапитал %.0f\n" % [sq["price"], sq["cap"]]
		ts += "Шанс: покупатель %s × референдум в регионе %s" % [fed_pct(float(sq["p_buy"])), fed_pct(float(sq["p_loc"]))]
		if float(sq["p_dom"]) < 1.0:
			ts += " × ваш референдум %s" % fed_pct(float(sq["p_dom"]))
		ts += " = [b]%s[/b]\n[color=%s]Продажа территории бьёт по рейтингу.[/color]" % [fed_pct(float(sq["p"])), COL_DIM]
		tw_sell_rt.text = ts
		tw_sell_btn.disabled = not bool(sq["ok"]) or cap_spendable() < float(sq["cap"]) or game_over
	# --- территории ---
	tw_stat_rt.text = "Приобретено регионов за игру: [b]%d[/b] · продано: [b]%d[/b] · присоединено стран: [b]%d[/b]" % [int(fst["acq"]), int(fst["ceded"]), (fst["merged"] as Array).size()]
	for ch in tw_terr_box.get_children():
		ch.queue_free()
	var any := false
	for i in regions.size():
		if not bool(regions[i]["terr"]):
			continue
		any = true
		var lb := Label.new()
		lb.text = "%s: лояльность %.0f, недовольство %.0f, прошло %d мес." % [REGIONS[i]["short"], float(regions[i]["loy"]), float(regions[i]["unrest"]), int(regions[i]["since"])]
		lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lb.add_theme_font_size_override("font_size", 13)
		tw_terr_box.add_child(lb)
		var wa := fed_admit_check(i)
		var ab := fed_btn("Принять в субъекты", tw_terr_box, wa if wa != "" else "10 капитала.")
		ab.disabled = wa != "" or game_over
		ab.pressed.connect(on_tw_admit.bind(i))
	if not any:
		var nl := Label.new()
		nl.text = "Федеральных территорий нет."
		nl.add_theme_color_override("font_color", C_DIM)
		tw_terr_box.add_child(nl)
