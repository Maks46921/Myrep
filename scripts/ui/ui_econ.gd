# Интерфейс: экран «Экономика».
extends "res://scripts/ui/ui_gov.gd"

func ec_slider(parent: Control, title: String, mn: float, mx: float, step: float, tip: String) -> Array:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 1)
	parent.add_child(vb)
	var top := HBoxContainer.new()
	vb.add_child(top)
	var tl := Label.new()
	tl.text = title
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tl.clip_text = true
	tl.tooltip_text = tip
	tl.add_theme_font_size_override("font_size", 15)
	top.add_child(tl)
	var vl := Label.new()
	vl.add_theme_font_size_override("font_size", 15)
	vl.add_theme_color_override("font_color", C_ACCENT.lightened(0.25))
	top.add_child(vl)
	var s := HSlider.new()
	s.min_value = mn
	s.max_value = mx
	s.step = step
	s.scrollable = false
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.custom_minimum_size = Vector2(60.0, 20.0)
	s.add_theme_stylebox_override("grabber_area", sbox(C_ACCENT.darkened(0.15), Color(0, 0, 0, 0), 0, 4, 0.0, 3.0))
	s.add_theme_stylebox_override("grabber_area_highlight", sbox(C_ACCENT, Color(0, 0, 0, 0), 0, 4, 0.0, 3.0))
	vb.add_child(s)
	return [s, vl]


func build_econ_windows() -> void:
	# --- рынки ---
	var w: FloatWindow = new_window("ec_mk", "Рынки: спрос и предложение", 5, Rect2(0.0, 0.0, 0.26, 0.60))
	ec_head_rt = make_rt(w.body)
	for m in MARKETS:
		var mb := MarketBar.new()
		mb.title = m["name"]
		mb.col = Color(String(MARKET_COLORS[m["id"]]))
		w.body.add_child(mb)
		ec_mk_bars[m["id"]] = mb
	add_note(w.body, "Тёмная полоса — мощность отрасли, цветная — внутренний спрос. Красный хвост — дефицит: товара не хватает, цены растут, растёт импорт. Если мощностей с запасом (загрузка ниже 70%), отрасль недоинвестирована спросом и цены давят вниз.")

	# --- покупательная способность ---
	w = new_window("ec_pp", "Покупательная способность населения", 5, Rect2(0.26, 0.0, 0.225, 0.60))
	add_bar(w.body, "ec_cconf", "Уверенность", false)
	ec_pp_rt = make_rt(w.body)
	ec_pp_fold = make_fold(w.body, "Доходы населения и корзина")

	# --- бизнес ---
	w = new_window("ec_bz", "Деловой климат и инвестиции", 5, Rect2(0.485, 0.0, 0.22, 0.60))
	add_bar(w.body, "ec_bconf", "Деловой климат", false)
	add_bar(w.body, "ec_inv", "Инвестиции", false, 55.0)
	ec_bz_rt = make_rt(w.body)

	# --- центробанк ---
	w = new_window("ec_cb", ("ЕЦБ (еврозона)" if bool(MACRO.get("euro", true)) else "Центральный банк"), 5, Rect2(0.0, 0.60, 0.165, 0.40))
	ec_cb_auto = CheckButton.new()
	ec_cb_auto.text = "Авто-ставка"
	ec_cb_auto.focus_mode = Control.FOCUS_NONE
	ec_cb_auto.tooltip_text = "Центробанк сам поднимает ставку при росте инфляции и снижает при охлаждении. Выключите, чтобы решать самому: низкая ставка разгоняет инвестиции и инфляцию, высокая — наоборот."
	ec_cb_auto.clip_text = true
	ec_cb_auto.toggled.connect(on_cb_auto)
	w.body.add_child(ec_cb_auto)
	var sl := ec_slider(w.body, "Ключевая ставка", 0.5, 25.0, 0.25, "Цена денег в экономике. Чем выше реальная ставка (ставка минус инфляция), тем дороже кредиты, тем меньше инвестиций и ниже инфляция.")
	ec_cb_slider = sl[0]
	ec_cb_val = sl[1]
	ec_cb_slider.value_changed.connect(on_rate_slider)
	ec_cb_auto.visible = false
	(ec_cb_slider.get_parent() as Control).visible = false
	ec_cb_rt = make_rt(w.body)
	ec_cb_fold = make_fold(w.body, "Как ставится ставка")

	# --- внешний сектор ---
	w = new_window("ec_gf", "Торговля (единый рынок ЕС)", 5, Rect2(0.165, 0.60, 0.19, 0.40))
	sl = ec_slider(w.body, "Ввозные пошлины", 0.0, 25.0, 0.5, "Пошлины защищают местных производителей и пополняют бюджет, но удорожают импорт, поднимают цены и вызывают ответные меры партнёров.")
	ec_tariff = sl[0]
	ec_tariff_val = sl[1]
	ec_tariff.value = 5.0
	ec_tariff.value_changed.connect(on_tariff_slider)
	sl = ec_slider(w.body, "Рента на сырьё", 0.0, 35.0, 0.5, "Доля экспортной выручки от сырья, которую забирает государство. Высокая рента наполняет бюджет, но отбивает у добытчиков желание расширяться.")
	ec_roy = sl[0]
	ec_roy_val = sl[1]
	ec_roy.value = 10.0
	ec_roy.value_changed.connect(on_roy_slider)
	(ec_tariff.get_parent() as Control).visible = false
	(ec_roy.get_parent() as Control).visible = false
	var fl := Label.new()
	fl.text = "Приоритет отрасли"
	fl.add_theme_font_size_override("font_size", 14)
	w.body.add_child(fl)
	ec_focus_opt = OptionButton.new()
	for nm in FOCUS_NAMES:
		ec_focus_opt.add_item(nm)
	ec_focus_opt.tooltip_text = "Бизнес охотнее вкладывается в выбранную отрасль: ей достаётся больше инвестиций. Остальным — меньше."
	ec_focus_opt.item_selected.connect(on_focus_selected)
	w.body.add_child(ec_focus_opt)
	ec_gf_rt = make_rt(w.body)
	ec_gf_fold = make_fold(w.body, "Внешняя торговля подробнее")

	# --- сооружения ---
	w = new_window("ec_st", "Сооружения страны", 5, Rect2(0.355, 0.60, 0.17, 0.40))
	ec_st_rt = make_rt(w.body)
	ec_st_fold = make_fold(w.body, "Сооружения подробнее")
	ec_repair_btn = make_button("Отремонтировать всё", w.body)
	ec_repair_btn.pressed.connect(repair_all)
	add_note(w.body, "Строить: «Карта» → кнопка «Строительство» (выберите сооружение и щёлкните по своей АТЕ) или карточка региона.")

	# --- графики ---
	w = new_window("ec_ch", "Графики", 5, Rect2(0.525, 0.60, 0.18, 0.40), false)
	ec_chart_opt = OptionButton.new()
	ec_chart_opt.fit_to_longest_item = false
	ec_chart_opt.clip_text = true
	for k in ec_chart_keys:
		ec_chart_opt.add_item(EC_CHART_NAMES[k])
	ec_chart_opt.item_selected.connect(on_chart_selected)
	w.body.add_child(ec_chart_opt)
	ec_chart = EconChart.new()
	w.body.add_child(ec_chart)


func on_cb_auto(on: bool) -> void:
	if ec.is_empty():
		return
	ec["rate_auto"] = on
	refresh()


func on_rate_slider(v: float) -> void:
	if ec.is_empty() or slider_busy:
		return
	ec["rate_auto"] = false
	set_rate(v)
	refresh()


func on_tariff_slider(v: float) -> void:
	if ec.is_empty() or slider_busy:
		return
	ec["tariff"] = v
	refresh()


func on_roy_slider(v: float) -> void:
	if ec.is_empty() or slider_busy:
		return
	ec["roy_pct"] = v
	refresh()


func on_focus_selected(i: int) -> void:
	if ec.is_empty() or slider_busy:
		return
	ec["focus"] = FOCUS_IDS[i]
	refresh()


func on_chart_selected(_i: int) -> void:
	update_chart()


func update_chart() -> void:
	if ec.is_empty() or ec_chart == null:
		return
	var k: String = ec_chart_keys[ec_chart_opt.selected]
	var ref := -1.0
	if k in ["ppi", "cpi", "fxs"]:
		ref = 100.0
	ec_chart.set_series(EC_CHART_NAMES[k], ec["hist"].get(k, []), Color(String(EC_CHART_COLORS[k])), ref)


func update_econ_windows() -> void:
	if ec.is_empty() or ec_head_rt == null:
		return
	var mk: Dictionary = ec["mk"]
	var util: float = float(ec["util"])
	var st: float = float(ec["short_tot"])
	var cpi: float = (float(ec["cpi_idx"]) / maxf(0.0001, float(h12_ago("cpi_idx", ec["cpi_idx"]))) - 1.0) * 100.0
	ec_head_rt.text = ("[b]Загрузка мощностей[/b]: [color=%s]%.0f%%[/color]   [b]Дефицит товаров[/b]: [color=%s]%.1f%%[/color]   [b]Цены в корзине " + h12_label("cpi_idx") + "[/b]: %s%%\n[color=%s]Вклад экономики в рост: %s п.п., в инфляцию: %s п.п., в безработицу: %s п.п.[/color]") % [
		COL_GOOD if util < 0.97 and util > 0.75 else COL_WARN, util * 100.0, COL_BAD if st > 0.01 else COL_GOOD, st * 100.0, sg(cpi, 1),
		COL_DIM, sg(float(ec["ec_g"]), 1), sg(float(ec["d_infl"]), 1), sg(float(ec["d_unemp"]), 1)]
	for m in MARKETS:
		var s: Dictionary = mk[m["id"]]
		var d := {"u": s["u"], "short": s["short"], "K": float(s["K"]) + float(s["sk"]), "Dd": s["Dd"], "p": s["p"], "margin": s["margin"]}
		(ec_mk_bars[m["id"]] as MarketBar).set_data(d)
		(ec_mk_bars[m["id"]] as MarketBar).tooltip_text = "%s\nСпрос: потребление %.0f%%, инвестиции %.0f%%, госзаказ %.0f%%, экспорт %.0f%%.\nДоля импорта на рынке сейчас %.0f%%.\nРост мощностей: %s%% в год.\nИнвестиции отрасли: %.1f%% ВВП." % [
			m["name"], float(m["c"]) * 100.0, float(m["i"]) * 100.0, float(m["g"]) * 100.0, float(m["x"]) * 100.0, float(s["imp"]) * 100.0,
			sg(float(s["gk"]) * 100.0, 1), float(ec["inv"]) * float(s["alloc"]) * 100.0]
	# покупательная способность
	var inc: Dictionary = ec["inc"]
	var ppi: float = float(ec["ppi"])
	set_bar("ec_cconf", float(ec["cconf"]))
	var lines: PackedStringArray = []
	var ppc: float = (ppi / maxf(0.0001, float(h12_ago("ppi", ppi))) - 1.0) * 100.0
	var rwc: float = (float(ec["rw"]) / maxf(0.0001, float(h12_ago("rw", ec["rw"]))) - 1.0) * 100.0
	var pp_head := "[b]Покупательная способность[/b] %s: [color=%s][b]%s%%[/b][/color]   Реальная зарплата: %s%%" % [h12_label("ppi"), good_col(ppc >= -0.5), sg(ppc, 1), sg(rwc, 1)]
	lines.append("[b]Доходы населения, млрд в год[/b]")
	lines.append("  Зарплаты: %s    Подоходный налог: −%s" % [fmt_n(float(inc["wages"])), fmt_n(float(inc["tax"]))])
	lines.append("  Пенсии: %s    Пособия: %s" % [fmt_n(float(inc["pens"])), fmt_n(float(inc["ben"]))])
	lines.append("  [b]Итого на руки: %s[/b]" % fmt_n(float(inc["total"])))
	lines.append("Норма сбережений: %.1f%% (выше ставка — больше откладывают, меньше тратят)" % (float(ec["sav"]) * 100.0))
	lines.append("[b]Потребительская корзина[/b] (изменение цен %s)" % h12_label("mk:" + String(MARKETS[0]["id"])))
	for m in MARKETS:
		if float(m["kg"]) > 0.0:
			var p_now: float = float(mk[m["id"]]["p"])
			var pm: float = (p_now / maxf(0.0001, float(h12_ago("mk:" + String(m["id"]), p_now))) - 1.0) * 100.0
			lines.append("  %s (%.0f%% корзины): [color=%s]%s%%[/color]" % [m["short"], float(m["kg"]) * 100.0, COL_BAD if pm > 3.0 else (COL_GOOD if pm < -3.0 else COL_DIM), sg(pm, 0)])
	var tips: PackedStringArray = []
	if inflation > 6.5:
		tips.append(hint_line(false, "Инфляция съедает зарплаты: люди тратят меньше."))
	if unemployment > 8.0:
		tips.append(hint_line(false, "Безработица давит на доходы и настроения."))
	if float(inc["tax"]) / maxf(float(inc["wages"]), 1.0) > 0.26:
		tips.append(hint_line(false, "Высокий подоходный налог уменьшает потребление."))
	if ppi > 1.05:
		tips.append(hint_line(true, "Доходы растут быстрее цен: спрос на товары увеличивается."))
	if tips.is_empty():
		tips.append(hint_line(true, "Покупательная способность в норме."))
	ec_pp_rt.text = pp_head + "\n" + "\n".join(tips)
	ec_pp_fold.text = "\n".join(lines)
	# бизнес
	set_bar("ec_bconf", float(ec["bconf"]))
	set_bar("ec_inv", clampf((float(ec["inv"]) - 0.10) / 0.24 * 100.0, 0.0, 100.0))
	(bars["ec_inv"]["val"] as Label).text = "%.0f%%" % (float(ec["inv"]) * 100.0)
	var rs: Array = (ec["reasons"] as Array).duplicate()
	rs.sort_custom(func(a, b): return absf(float(a[1])) > absf(float(b[1])))
	var bl: PackedStringArray = []
	bl.append("[b]Что влияет на желание бизнеса вкладываться[/b]")
	for e in rs:
		var v: float = float(e[1])
		if absf(v) < 0.4:
			continue
		bl.append("  [color=%s]%s[/color]  %s" % [COL_GOOD if v > 0.0 else COL_BAD, sg(v, 1), e[0]])
	bl.append("")
	bl.append("Норма инвестиций: [b]%.1f%%[/b] ВВП. Инвестиции строят новые мощности: от них зависят рост и дефицит." % (float(ec["inv"]) * 100.0))
	var fcs: String = String(ec["focus"])
	if fcs != "":
		bl.append("Приоритет политики: [b]%s[/b]." % FOCUS_NAMES[FOCUS_IDS.find(fcs)])
	ec_bz_rt.text = "\n".join(bl)
	# ЦБ
	slider_busy = true
	ec_cb_auto.set_pressed_no_signal(bool(ec["rate_auto"]))
	ec_cb_slider.set_value_no_signal(float(ec["rate"]))
	ec_cb_slider.editable = not bool(ec["rate_auto"])
	ec_tariff.set_value_no_signal(float(ec["tariff"]))
	ec_roy.set_value_no_signal(float(ec["roy_pct"]))
	ec_focus_opt.select(maxi(0, FOCUS_IDS.find(String(ec["focus"]))))
	slider_busy = false
	ec_cb_val.text = "%.2f%%" % float(ec["rate"])
	ec_tariff_val.text = "%.1f%%" % float(ec["tariff"])
	ec_roy_val.text = "%.1f%%" % float(ec["roy_pct"])
	var gap: float = float(ec["real_gap"])
	var cl: PackedStringArray = []
	cl.append("Инфляция: [b]%.1f%%[/b]   Реальная ставка: [color=%s][b]%s[/b][/color] (норма +%.0f)" % [inflation, COL_GOOD if absf(gap) < 1.0 else COL_WARN, sg(gap + RATE_NEUTRAL_REAL, 1), RATE_NEUTRAL_REAL])
	var cb_more: PackedStringArray = []
	if bool(MACRO.get("euro", true)):
		cb_more.append("Ключевая ставка ЕЦБ: [b]%.2f%%[/b]. Её задаёт ЕЦБ для всей еврозоны: инфляция еврозоны %.1f%%, вес вашей страны — около %.0f%%. Ставка по правилу: %.1f%%" % [float(ec["rate"]), ea_infl, float(MACRO.get("ecb_w", 0.0)) * 100.0, float(ec["rate_goal"])])
	else:
		cb_more.append("Ключевая ставка национального центрального банка: [b]%.2f%%[/b]. Банк смотрит на вашу инфляцию и рост (инфляция в еврозоне %.1f%% влияет лишь частично). Ставка по правилу: %.1f%%" % [float(ec["rate"]), ea_infl, float(ec["rate_goal"])])
	if gap < -1.5:
		cl.append(hint_line(false, "Деньги слишком дешёвые: инфляция выше, кредиты и инвестиции разгоняются, нацвалюта слабеет."))
	elif gap > 1.5:
		cl.append(hint_line(false, "Деньги слишком дорогие: инвестиции и сбережения растут, но бизнесу тяжело, инфляция снижается."))
	else:
		cl.append(hint_line(true, "Ставка близка к нейтральной."))
	cb_more.append("Процент по госдолгу: %.1f%% (часть долга привязана к ключевой ставке)." % (debt_rate() * 100.0))
	ec_cb_rt.text = "\n".join(cl)
	ec_cb_fold.text = "\n".join(cb_more)
	# торговля
	var gl: PackedStringArray = []
	var fxs: float = float(ec["fxs"])
	gl.append("Курс валюты %s: [b]%s%%[/b]   Валютные и золотые резервы: [b]%.1f%%[/b] ВВП" % [h12_label("fxs"), sg((fxs / maxf(0.0001, float(h12_ago("fxs", fxs))) - 1.0) * 100.0, 1), float(ec["res"])])
	gl.append("Экспорт: %s млрд   Импорт: %s млрд   Баланс: [color=%s]%s%% ВВП[/color]" % [fmt_n(float(ec["exp_v"])), fmt_n(float(ec["imp_v"])), good_col(float(ec["nx"]) > -1.5), sg(float(ec["nx"]), 1)])
	var gf_more: PackedStringArray = []
	gf_more.append("Мировой спрос: [b]%.0f[/b]   Цены на сырьё: [b]%.0f[/b]" % [float(ec["wd"]) * 100.0, float(ec["comm"]) * 100.0])
	gf_more.append("Внешний тариф ЕС приносит бюджету около %s млрд в год. Торговую политику определяет ЕС; ваша страна влияет на неё через законы и дипломатию." % fmt_n(gdp * tariff_rev_share() / 100.0, 1))
	if float(ec["res"]) < 3.0:
		gl.append(hint_line(false, "Резервы почти кончились: валюта уязвима."))
	if float(ec["tariff"]) > 12.0:
		gl.append(hint_line(false, "Высокие пошлины: импорт дорог, цены растут, партнёры отвечают на них."))
	ec_gf_rt.text = "\n".join(gl)
	ec_gf_fold.text = "\n".join(gf_more)
	# сооружения
	var sl2: PackedStringArray = []
	var total := 0
	var cond_sum := 0.0
	var by_cat := {}
	for i in regions.size():
		var bt: Dictionary = regions[i]["built"]
		for id in bt:
			var pd := find_by_id(PROJECTS, id)
			var e2: Dictionary = bt[id]
			total += int(e2["n"])
			cond_sum += float(e2["cond"]) * float(e2["n"])
			var cn: String = STRUCT_CATS[int(pd["cat"])]
			by_cat[cn] = int(by_cat.get(cn, 0)) + int(e2["n"])
	if total == 0:
		sl2.append("Сооружений пока нет. Страна растёт на мощностях, которые строит бизнес: если спрос обгоняет предложение, возникает дефицит.")
	else:
		var avg: float = cond_sum / float(total)
		sl2.append("Построено: [b]%d[/b]   Состояние: [color=%s][b]%.0f%%[/b][/color]   Содержание: [b]%s млрд[/b] в год" % [total, good_col(avg > 60.0), avg, fmt_n(float(ec["struct_up"]) * gdp / 100.0, 1)])
		for cn in by_cat:
			sl2.append("  %s: %d" % [cn, by_cat[cn]])
		sl2.append("[b]Прирост мощностей[/b]")
		for m in MARKETS:
			var sk: float = float(mk[m["id"]]["sk"])
			if sk > 0.0005:
				sl2.append("  %s: +%.1f%% (от общей мощности)" % [m["name"], sk / float(mk[m["id"]]["K"]) * 100.0])
		if float(ec["bc_struct"]) > 0.0:
			sl2.append("Деловой климат от сооружений: +%.1f" % float(ec["bc_struct"]))
		if float(ec["pr"]) > 0.0:
			sl2.append("Рост производительности: +%.2f п.п. в год" % float(ec["pr"]))
		if avg < 60.0:
			sl2.append(hint_line(false, "Сооружения изнашиваются: их отдача падает. Отремонтируйте."))
	ec_st_rt.text = sl2[0] if sl2.size() > 0 else ""
	ec_st_fold.text = "\n".join(sl2.slice(1))
	var rc: float = repair_cost_pct()
	ec_repair_btn.text = "Отремонтировать всё (%.1f млрд)" % (gdp * rc / 100.0)
	ec_repair_btn.disabled = game_over or rc < 0.005
	update_chart()


# ---------- товары и цены (вкладка «Экономика» → «Товары и цены») ----------


func build_goods_windows() -> void:
	var w: FloatWindow = new_window("gd_list", "Товары: цены и спрос", 7, Rect2(0.0, 0.0, 0.37, 0.58))
	gd_head_rt = make_rt(w.body)
	gd_mode_opt = OptionButton.new()
	gd_mode_opt.add_item("Цены за 12 месяцев")
	gd_mode_opt.add_item("Спрос (100 — обычный уровень)")
	gd_mode_opt.fit_to_longest_item = false
	gd_mode_opt.clip_text = true
	gd_mode_opt.item_selected.connect(func(_i: int) -> void: update_goods_windows())
	w.body.add_child(gd_mode_opt)
	gv_goods = GoodsView.new()
	w.body.add_child(gv_goods)
	add_note(w.body, "Цвет квадрата — отрасль-поставщик. Цена товара следует за ценой его отрасли, а ещё зависит от курса, пошлин, мировых цен на сырьё и НДС. Спрос зависит от доходов (роскошь реагирует сильнее еды) и от цены.")

	w = new_window("gd_groups", "Корзины групп: кому дорожает", 7, Rect2(0.37, 0.0, 0.335, 0.29))
	gv_groups = GoodsView.new()
	gv_groups.span = 6.0
	w.body.add_child(gv_groups)
	gd_grp_rt = make_rt(w.body)

	w = new_window("gd_drv", "Что двигает цены сейчас", 7, Rect2(0.37, 0.29, 0.335, 0.29))
	gd_drv_rt = make_rt(w.body)


func goods_market_color(mid: String) -> Color:
	return Color(String(MARKET_COLORS.get(mid, "#8a93aa")))


func update_goods_windows() -> void:
	if gv_goods == null or ec.is_empty() or not ec.has("gp"):
		return
	var cpi: float = cpi_goods()
	var months: int = int((ec["gh"]["food"] as Array).size()) - 1
	var cpi12 := 0.0
	for g in GOODS:
		cpi12 += float(g["kg"]) * float((ec["gh"][g["id"]] as Array)[0])
	gd_head_rt.text = "[b]Корзина товаров и услуг[/b]: цены за последние %d мес. [b][color=%s]%s%%[/color][/b]\n[color=%s]Цены показаны относительно общего уровня: «+3%%» — товар дорожает быстрее остальных. Инфляция страны: %.1f%%. В корзине 18 видов расходов, у каждой страны своя структура.[/color]" % [
		months, COL_BAD if cpi / cpi12 > 1.02 else COL_DIM, sg((cpi / cpi12 - 1.0) * 100.0, 1), COL_DIM, inflation]
	var mode: int = gd_mode_opt.selected + 1
	var rows: Array = []
	var order: Array = GOODS.duplicate()
	for g in order:
		var id: String = g["id"]
		var p: float = float(ec["gp"][id])
		var d: float = float(ec["gd"][id])
		var v := 0.0
		var vt := ""
		if mode == 0:
			v = (p - 1.0) * 100.0
			vt = "%s%%" % sg(v, 1)
		elif mode == 1:
			v = good_yoy(id) * 100.0
			vt = "%s%%" % sg(v, 1)
		else:
			v = (d - 1.0) * 100.0
			vt = "%.0f" % (d * 100.0)
		var best: PackedStringArray = []
		for gr in GROUPS:
			if prof_mult(gr, id) >= 1.6:
				best.append(String(gr))
		var tip := "%s\nОтрасль: %s. Доля в корзине %.1f%%.\nЦена за 12 мес.: %s%%. Спрос: %.0f (100 — обычный уровень).\nЦена следует за отраслью на %.0f%%; зависит от курса %s, пошлин %s, мировых цен на сырьё %s, НДС %s.\nУ кого сильно заметна: %s." % [
			g["name"], String(mk_def(g["mk"])["name"]), float(g["kg"]) * 100.0, sg(good_yoy(id) * 100.0, 1), d * 100.0, float(g["ps"]) * 100.0,
			"да" if float(g["xf"]) > 0.0 else "нет", "да" if float(g["tf"]) > 0.0 else "нет", "да" if float(g["dc"]) > 0.0 else "нет", "да" if float(g["vat"]) > 0.0 else "нет",
			", ".join(best) if best.size() > 0 else "у всех примерно поровну"]
		rows.append({"label": "%s  %.0f%%" % [g["short"], float(g["kg"]) * 100.0], "col": goods_market_color(g["mk"]), "v": v, "vt": vt, "tip": tip})
	(gv_goods as Control).set("good_when_low", mode != 2)
	var mx := 0.0
	for r in rows:
		mx = maxf(mx, absf(float(r["v"])))
	(gv_goods as Control).set("span", clampf(mx * 1.35, 4.0, 40.0))
	(gv_goods as Control).call("set_rows", rows)
	# группы
	var grows: Array = []
	var best_g := ""
	var best_v := -99.0
	var worst_g := ""
	var worst_v := 99.0
	for gr in GROUPS:
		var gap: float = group_gap(gr)
		var tops: PackedStringArray = []
		for it in group_top_goods(gr, 3):
			tops.append("%s %.0f%%" % [String(good_def(it[0])["short"]).to_lower(), float(it[1]) * 100.0])
		var gc_now: float = group_cpi(gr)
		var gi: float = (gc_now / maxf(0.0001, float(h12_ago("gcpi:" + String(gr), gc_now))) - 1.0) * 100.0
		var cpi_y: float = (cpi / maxf(0.0001, float(h12_ago("cpi_goods", cpi))) - 1.0) * 100.0
		if gap > best_v:
			best_v = gap
			best_g = gr
		if gap < worst_v:
			worst_v = gap
			worst_g = gr
		var sup_t := goods_support_term(gr)
		grows.append({"label": gr, "col": Color("#a58af0"), "v": gap, "vt": "%s п.п." % sg(gap, 1),
			"tip": "%s: главные траты — %s.\nКорзина подорожала %s на %s%% (средняя по стране: %s%%).\nНакопленная разница со средней: %s п.п. — влияет на поддержку власти: %s." % [gr, ", ".join(tops), h12_label("cpi_goods"), sg(gi, 1), sg(cpi_y, 1), sg(gap, 1), sg(sup_t, 1)]})
	var gmx := 0.0
	for r2 in grows:
		gmx = maxf(gmx, absf(float(r2["v"])))
	(gv_groups as Control).set("span", clampf(gmx * 1.4, 1.0, 10.0))
	(gv_groups as Control).call("set_rows", grows)
	var gt := ""
	if best_v - worst_v < 0.4:
		gt = "[color=%s]Цены растут (или падают) почти одинаково для всех групп.[/color]" % COL_DIM
	else:
		gt = "Сильнее всего дорожает корзина группы «[b]%s[/b]» (%s п.п. к средней), слабее всего — «[b]%s[/b]» (%s п.п.). Это сдвигает поддержку групп и недовольство отдельных агентов во вкладке «Население».\n[color=%s]Наведите на строку: там главные траты группы.[/color]" % [best_g, sg(best_v, 1), worst_g, sg(worst_v, 1), COL_DIM]
	gd_grp_rt.text = gt
	# что двигает
	var vat_r: float = float(pol["vat"]) / maxf(0.01, float(pol_def["vat"])) - 1.0
	var dl: PackedStringArray = []
	dl.append("[b]Внешние и политические факторы[/b]")
	dl.append("Курс валюты %s: [b]%s%%[/b] — %s" % [h12_label("fxs"), sg((float(ec["fxs"]) / maxf(0.0001, float(h12_ago("fxs", ec["fxs"]))) - 1.0) * 100.0, 1), "импорт дорожает: электроника, топливо, одежда" if float(ec["fxs"]) < 0.97 else ("импорт дешевеет" if float(ec["fxs"]) > 1.03 else "нейтрально")])
	dl.append("Мировые цены на сырьё: [b]%.0f[/b] — %s" % [float(ec["comm"]) * 100.0, "дорожают топливо и электричество" if float(ec["comm"]) > 1.05 else ("топливо и электричество дешевеют" if float(ec["comm"]) < 0.95 else "нейтрально")])
	dl.append("Ввозные пошлины: [b]%.1f%%[/b] (норма 5%%) — %s" % [float(ec["tariff"]), "дорожают импортные товары" if float(ec["tariff"]) > 6.0 else "без влияния"])
	dl.append("НДС: [b]%.1f%%[/b] ВВП (%s %s п.п.) — %s" % [float(pol["vat"]), h12_label("vat"), sg(float(pol["vat"]) - float(h12_ago("vat", pol["vat"])), 1), "цены на товары и услуги растут (кроме жилья, образования, медицины)" if vat_r > 0.02 else ("цены снижаются" if vat_r < -0.02 else "без влияния")])
	dl.append("Реальная ставка: [b]%s[/b] — %s" % [sg(float(ec["real_gap"]), 1), "дешёвые кредиты разгоняют цены на жильё" if float(ec["real_gap"]) < -1.0 else ("дорогие кредиты охлаждают рынок жилья" if float(ec["real_gap"]) > 1.0 else "жильё в норме")])
	dl.append("[b]Спрос и предложение отраслей[/b]")
	for m in MARKETS:
		var s: Dictionary = ec["mk"][m["id"]]
		dl.append("  %s: цена %.0f, загрузка %.0f%%" % [m["short"], float(s["p"]) * 100.0, float(s["u"]) * 100.0])
	var hot: Array = []
	for g in GOODS:
		hot.append([g["id"], float(ec["gp"][g["id"]]) - 1.0])
	hot.sort_custom(func(a, b): return float(a[1]) > float(b[1]))
	dl.append("[b]Дороже всего[/b]: %s" % ", ".join(PackedStringArray([_hot_txt(hot[0]), _hot_txt(hot[1]), _hot_txt(hot[2])])))
	dl.append("[b]Дешевле всего[/b]: %s" % ", ".join(PackedStringArray([_hot_txt(hot[hot.size() - 1]), _hot_txt(hot[hot.size() - 2]), _hot_txt(hot[hot.size() - 3])])))
	dl.append("[color=%s]Рычаги: разовые меры (потолок цен на еду, скидка на топливо, льготные лекарства, жилищная программа), НДС, пошлины, ставка, мощности отраслей.[/color]" % COL_DIM)
	gd_drv_rt.text = "\n".join(dl)


func _hot_txt(it: Array) -> String:
	return "%s %s%%" % [String(good_def(it[0])["short"]).to_lower(), sg(float(it[1]) * 100.0, 1)]
