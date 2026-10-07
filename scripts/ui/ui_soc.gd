# Интерфейс: «Религия и миграция» (desk 11) и «Влияние и зависимость» (desk 10).
extends "res://scripts/ui/ui_fed.gd"

var sw_rel_rt: RichTextLabel
var sw_pol_rt: RichTextLabel
var sw_mig_rt: RichTextLabel
var sw_reg_rt: RichTextLabel
var sw_btn: Dictionary = {}
var xw_list_rt: RichTextLabel
var xw_info_rt: RichTextLabel
var xw_btn: Dictionary = {}
var sw_chart: Control
var sw_regchart: Control
var sw_spk_t: Control
var sw_spk_n: Control
var xw_chart: Control
var xw_spk: Control


func soc_btn(key: String, text: String, parent: Control, cb: Callable, tip: String = "") -> void:
	var b := fed_btn(text, parent, tip)
	b.pressed.connect(cb)
	sw_btn[key] = b


func build_soc_windows() -> void:
	# ---- desk 11: религия и миграция ----
	var w: FloatWindow = new_window("sw_rel", "Религиозный состав", 11, Rect2(0.0, 0.0, 0.36, 0.60))
	sw_chart = FaithChart.new()
	w.body.add_child(sw_chart)
	sw_rel_rt = make_rt(w.body)
	add_note(w.body, "У каждого агента своя вера. Влияние зависит от того, насколько доля конфессии выше или ниже её обычного уровня в стране: чем больше её сторонников, тем сильнее эффект. Данные приблизительные.", true)

	w = new_window("sw_pol", "Религия и государство", 11, Rect2(0.36, 0.0, 0.34, 0.60))
	sw_pol_rt = make_rt(w.body)
	var r1 := HBoxContainer.new()
	w.body.add_child(r1)
	soc_btn("sec-", "Больше традиции (8)", r1, on_soc_sec.bind(-1), "Сближение с традиционными конфессиями: радует пенсионеров и село, злит молодёжь.")
	soc_btn("sec+", "Больше секуляризма (8)", r1, on_soc_sec.bind(1), "Отделение религии от государства: радует молодёжь и экологов, злит пенсионеров и село.")
	var r2 := HBoxContainer.new()
	w.body.add_child(r2)
	soc_btn("fund-", "Меньше поддержки общин (6)", r2, on_soc_fund.bind(-1))
	soc_btn("fund+", "Больше поддержки общин (6)", r2, on_soc_fund.bind(1))
	soc_btn("dial", "Межконфессиональный совет", w.body, on_soc_dialog, "Снижает напряжённость между общинами.")

	w = new_window("sw_mig", "Миграционная политика", 11, Rect2(0.0, 0.60, 0.36, 0.40))
	sw_mig_rt = make_rt(w.body)
	var r3 := HBoxContainer.new()
	w.body.add_child(r3)
	soc_btn("mig-", "Строже границы", r3, on_soc_mig.bind(-1))
	soc_btn("mig+", "Мягче границы", r3, on_soc_mig.bind(1))
	var r4 := HBoxContainer.new()
	w.body.add_child(r4)
	soc_btn("prog-", "Меньше интеграции", r4, on_soc_prog.bind(-1))
	soc_btn("prog+", "Больше интеграции", r4, on_soc_prog.bind(1))
	var r5 := HBoxContainer.new()
	w.body.add_child(r5)
	soc_btn("sel-", "Меньше отбора", r5, on_soc_sel.bind(-1))
	soc_btn("sel+", "Строже отбор", r5, on_soc_sel.bind(1))
	sw_spk_t = Spark.new()
	w.body.add_child(sw_spk_t)
	sw_spk_n = Spark.new()
	w.body.add_child(sw_spk_n)

	w = new_window("sw_reg", "Регионы: вера и напряжённость", 11, Rect2(0.36, 0.60, 0.34, 0.40))
	sw_regchart = FaithChart.new()
	w.body.add_child(sw_regchart)
	sw_reg_rt = make_rt(w.body)
	sw_reg_rt.visible = false

	# ---- desk 10: влияние и зависимость ----
	w = new_window("xw_list", "Партнёры и зависимость", 10, Rect2(0.0, 0.0, 0.40, 1.0))
	xw_chart = DepChart.new()
	xw_chart.picked.connect(on_ex_meta)
	w.body.add_child(xw_chart)
	xw_list_rt = make_rt(w.body)
	xw_list_rt.visible = false
	add_note(w.body, "Зависимость — доля торговли, энергии и долга в ВВП. «Мы зависим» — насколько ваша страна зависит от партнёра, «Они зависят» — насколько партнёр зависит от вас. Щёлкните по стране, чтобы действовать.", true)

	w = new_window("xw_info", "Действия с выбранной страной", 10, Rect2(0.40, 0.0, 0.30, 1.0))
	xw_info_rt = make_rt(w.body)
	var r6 := HBoxContainer.new()
	w.body.add_child(r6)
	xw_btn["deal-"] = fed_btn("Соглашение −", r6)
	xw_btn["deal-"].pressed.connect(on_ex_deal.bind(-1))
	xw_btn["deal+"] = fed_btn("Соглашение + (10)", r6, "Торговое соглашение: больше торговли и влияния, отношения растут.")
	xw_btn["deal+"].pressed.connect(on_ex_deal.bind(1))
	var r7 := HBoxContainer.new()
	w.body.add_child(r7)
	xw_btn["tar-"] = fed_btn("Пошлины −", r7)
	xw_btn["tar-"].pressed.connect(on_ex_tar.bind(-1))
	xw_btn["tar+"] = fed_btn("Пошлины + (6)", r7, "Защищают рабочих, бьют по бизнесу и отношениям; партнёр может ответить.")
	xw_btn["tar+"].pressed.connect(on_ex_tar.bind(1))
	xw_btn["aid"] = fed_btn("Помощь и инвестиции (3)", w.body, "0,1% ВВП в долг: растёт влияние на страну.")
	xw_btn["aid"].pressed.connect(on_ex_aid)
	var r8 := HBoxContainer.new()
	w.body.add_child(r8)
	xw_btn["dbuy-"] = fed_btn("Продать их долг", r8)
	xw_btn["dbuy-"].pressed.connect(on_ex_dbuy.bind(-1))
	xw_btn["dbuy+"] = fed_btn("Выкуп их долга (5)", r8, "Вы кредитор: их зависимость от вас растёт.")
	xw_btn["dbuy+"].pressed.connect(on_ex_dbuy.bind(1))
	xw_btn["bonds"] = fed_btn("Просьба: купить наши облигации (6)", w.body, "Нужно влияние на страну от 60.")
	xw_btn["bonds"].pressed.connect(on_ex_favor.bind("bonds"))
	xw_btn["tariff"] = fed_btn("Просьба: смягчить пошлины (6)", w.body, "Нужно влияние от 60 и ответные пошлины.")
	xw_btn["tariff"].pressed.connect(on_ex_favor.bind("tariff"))
	xw_spk = Spark.new()
	w.body.add_child(xw_spk)


func on_soc_sec(d: int) -> void:
	soc_set_sec(d)
func on_soc_fund(d: int) -> void:
	soc_set_fund(d)
func on_soc_dialog() -> void:
	soc_dialog()
func on_soc_mig(d: int) -> void:
	soc_set_mig(d)
func on_soc_prog(d: int) -> void:
	soc_set_prog(d)
func on_soc_sel(d: int) -> void:
	soc_set_sel(d)
func on_ex_meta(meta: Variant) -> void:
	ex_sel = String(meta)
	update_soc_windows()
func on_ex_deal(d: int) -> void:
	if ex_sel != "": ex_deal_set(ex_sel, d)
func on_ex_tar(d: int) -> void:
	if ex_sel != "": ex_tariff_set(ex_sel, d)
func on_ex_aid() -> void:
	if ex_sel != "": ex_aid_give(ex_sel)
func on_ex_dbuy(d: int) -> void:
	if ex_sel != "": ex_dbuy_set(ex_sel, d)
func on_ex_favor(k: String) -> void:
	if ex_sel != "": ex_favor(ex_sel, k)


func soc_eff_line(f: int) -> String:
	var fx: Array = SOC_FX[f]
	var t := ""
	var names := ["сплоч.", "рост", "рожд.", "налоги"]
	for k in 4:
		var v: float = float(fx[k])
		if absf(v) < 0.04:
			continue
		t += "%s%s " % [("▲" if v > 0 else "▼"), names[k]]
	return t.strip_edges()


func update_soc_windows() -> void:
	if sw_rel_rt == null or soc.is_empty():
		return
	if current_desk == 11:
		update_soc_desk()
	elif current_desk == 10:
		update_ex_desk()


func update_soc_desk() -> void:
	var nat: Array = soc_national()
	var cnt := PackedInt32Array()
	if AG != null and ag_on:
		cnt = AG.faith_counts()
	var base: Array = soc_cfg()["base"]
	var t := "[table=5][cell][color=%s]Конфессия[/color][/cell][cell][color=%s] Доля[/color][/cell][cell][color=%s] За год[/color][/cell][cell][color=%s] Агентов[/color][/cell][cell][color=%s] Эффект[/color][/cell]" % [COL_DIM, COL_DIM, COL_DIM, COL_DIM, COL_DIM]
	for f in 7:
		var fy: Array = h12_ago("faith", nat)
		var dl: float = (float(nat[f]) - float(fy[f])) * 100.0
		var dc: String = COL_GOOD if dl > 0.05 else (COL_BAD if dl < -0.05 else COL_DIM)
		t += "[cell][color=%s]■[/color] %s[/cell][cell] %.1f%%[/cell][cell][color=%s] %+.1f[/color][/cell][cell] %s[/cell][cell] [color=%s]%s[/color][/cell]" % [SOC_FCOL[f], SOC_FAITH[f], float(nat[f]) * 100.0, dc, dl, (str(cnt[f]) if cnt.size() == 7 else "—"), COL_DIM, soc_eff_line(f)]
	t += "[/table]\n"
	t += "\nВлияние состава общества на страну сейчас: рост %+.2f п.п., безработица %+.2f п.п., налоговая дисциплина %+.1f%%." % [soc_g(), soc_unemp(), soc_tax() * 100.0]
	sw_rel_rt.text = t
	var rows: Array = [["Сейчас", nat, -1.0, null], ["Год назад" if h12_months("faith") >= 12 else ("%d мес. назад" % h12_months("faith")), h12_ago("faith", nat), -1.0, null]]
	(sw_chart as FaithChart).set_rows(rows, true)
	var p := "Курс: [b]%s[/b]\nПоддержка общин: [b]%s[/b]\nИнтеграция общества: [b]%.0f[/b]/100 · напряжённость: [b]%.0f[/b]/100\n" % [SOC_SEC[int(soc["sec"])], ["нет", "базовая", "щедрая"][int(soc["fund"])], float(soc["integ"]), float(soc["tension"])]
	p += "[color=%s]Секуляризм сокращает долю верующих, но злит консервативные группы. Поддержка общин укрепляет сплочённость и стоит денег.[/color]" % COL_DIM
	sw_pol_rt.text = p
	_soc_btn_state("sec-", soc_cd_get("sec") > 0 or int(soc["sec"]) <= 0, "")
	_soc_btn_state("sec+", soc_cd_get("sec") > 0 or int(soc["sec"]) >= 3, "")
	_soc_btn_state("fund-", soc_cd_get("fund") > 0 or int(soc["fund"]) <= 0, "")
	_soc_btn_state("fund+", soc_cd_get("fund") > 0 or int(soc["fund"]) >= 2, "")
	_soc_btn_state("dial", soc_cd_get("dialog") > 0, "")
	var m := "Курс: [b]%s[/b]\nПрограммы интеграции: [b]%s[/b] · отбор: [b]%s[/b]\n" % [SOC_MIGN[int(soc["lvl"])], SOC_PROG[int(soc["prog"])], SOC_SEL[int(soc["sel"])]]
	m += "Приток: [b]%.1f[/b] на 1000 жителей в год (%s: %.1f) · отток: %.1f · накоплено чистой миграции: %+.2f млн\n" % [float(soc["in_now"]), "год назад" if h12_months("mig_in") >= 12 else "в начале наблюдений", float(h12_ago("mig_in", soc["in_now"])), float(soc["out_now"]), float(soc["net"])]
	var mx: Array = soc["mix"]
	var parts := PackedStringArray()
	for k in mx.size():
		parts.append("%s %.0f%%" % [["Европа", "Ближний Восток", "Африка", "Азия", "Восточная Европа", "Америка"][k] if k < 6 else str(k), float(mx[k]) * 100.0])
	m += "Откуда: " + ", ".join(parts)
	sw_mig_rt.text = m
	_soc_btn_state("mig-", soc_cd_get("lvl") > 0 or int(soc["lvl"]) <= 0, "")
	_soc_btn_state("mig+", soc_cd_get("lvl") > 0 or int(soc["lvl"]) >= 4, "")
	_soc_btn_state("prog-", soc_cd_get("prog") > 0 or int(soc["prog"]) <= 0, "")
	_soc_btn_state("prog+", soc_cd_get("prog") > 0 or int(soc["prog"]) >= 3, "")
	_soc_btn_state("sel-", soc_cd_get("sel") > 0 or int(soc["sel"]) <= 0, "")
	_soc_btn_state("sel+", soc_cd_get("sel") > 0 or int(soc["sel"]) >= 2, "")
	var r := "[table=4][cell][color=%s]Регион[/color][/cell][cell][color=%s] Главная вера[/color][/cell][cell][color=%s] Нерелиг.[/color][/cell][cell][color=%s] Мусульм.[/color][/cell]" % [COL_DIM, COL_DIM, COL_DIM, COL_DIM]
	for i in regions.size():
		var dm: int = soc_dominant(i)
		r += "[cell]%s[/cell][cell] [color=%s]%s[/color][/cell][cell] %.0f%%[/cell][cell] %.0f%%[/cell]" % [REGIONS[i]["name"], SOC_FCOL[dm], SOC_FAITH[dm], float(regions[i]["rel"][6]) * 100.0, float(regions[i]["rel"][3]) * 100.0]
	r += "[/table]"
	sw_reg_rt.text = r
	var rr: Array = []
	for i2 in regions.size():
		rr.append([REGIONS[i2]["name"], regions[i2]["rel"], float(regions[i2]["relt"]), null])
	(sw_regchart as FaithChart).set_rows(rr, false)
	var hh: Dictionary = soc["h"]
	sw_spk_t.title = "Напряжённость и интеграция по месяцам"
	sw_spk_t.series = [{"v": hh["t"], "c": Color("#f0707a"), "n": "напр."}, {"v": hh["i"], "c": Color("#58c887"), "n": "интегр."}]
	sw_spk_t.ymin = 0.0
	sw_spk_t.ymax = 100.0
	sw_spk_t.queue_redraw()
	sw_spk_n.title = "Накопленная чистая миграция, млн"
	sw_spk_n.series = [{"v": hh["n"], "c": Color("#6fa8dc"), "n": "млн"}]
	sw_spk_n.queue_redraw()


func regions_rel0_vec() -> Array:
	var out: Array = []
	for f in 7:
		out.append(regions_rel0_nat(f))
	return out


func regions_rel0_nat(f: int) -> float:
	var s := 0.0
	for i in regions.size():
		s += float(regions[i]["rel0"][f]) * pop_w[i]
	return s


func _soc_btn_state(k: String, dis: bool, tip: String) -> void:
	var b: Button = sw_btn[k]
	b.disabled = dis or game_over


func update_ex_desk() -> void:
	var ps: Array = ex_partners()
	if ex_sel == "" or not (ex_sel in ps):
		ex_sel = ps[0] if ps.size() > 0 else ""
	var chart_rows: Array = []
	var t := "[table=6][cell][color=%s]Страна[/color][/cell][cell][color=%s] Мы зависим[/color][/cell][cell][color=%s] Они зависят[/color][/cell][cell][color=%s] Влияние[/color][/cell][cell][color=%s] Отнош.[/color][/cell][cell][color=%s] Пошлины/ответ[/color][/cell]" % [COL_DIM, COL_DIM, COL_DIM, COL_DIM, COL_DIM, COL_DIM]
	var rows: Array = []
	for c in ps:
		rows.append([c, float(ex_dep(c)["out"]) + float(ex_dep(c)["in"])])
	rows.sort_custom(func(a, b): return float(a[1]) > float(b[1]))
	for rw in rows:
		var c: String = rw[0]
		var d: Dictionary = ex_dep(c)
		var lv: float = ex_leverage(c)
		var p: Dictionary = ex["p"][c]
		var mark: String = "▶ " if c == ex_sel else ""
		t += "[cell]%s[url=%s]%s[/url][/cell][cell] %.1f%%[/cell][cell] %.1f%%[/cell][cell] [color=%s]%.0f[/color][/cell][cell] %.0f[/cell][cell] %d/%d[/cell]" % [mark, c, WORLD[c]["name"], float(d["out"]), float(d["in"]), (COL_GOOD if lv > 55.0 else (COL_BAD if lv < 45.0 else COL_DIM)), lv, fed_rel(c), int(p["tar"]), int(p["ret"])]
	t += "[/table]"
	xw_list_rt.text = t
	for rw2 in rows:
		var c3: String = rw2[0]
		var d3: Dictionary = ex_dep(c3)
		var p3: Dictionary = ex["p"][c3]
		chart_rows.append([c3, WORLD[c3]["name"], float(d3["out"]), float(d3["in"]), ex_leverage(c3), fed_rel(c3), int(p3["tar"]), int(p3["ret"]), c3 == ex_sel])
	(xw_chart as DepChart).set_rows(chart_rows)
	xw_spk.title = "Среднее влияние на партнёров по месяцам"
	xw_spk.series = [{"v": ex["hist"], "c": Color("#58c8c0"), "n": "влияние"}]
	xw_spk.ymin = 30.0
	xw_spk.ymax = 70.0
	xw_spk.queue_redraw()
	if ex_sel == "":
		xw_info_rt.text = "Нет партнёров."
		return
	var c2: String = ex_sel
	var d2: Dictionary = ex_dep(c2)
	var p2: Dictionary = ex["p"][c2]
	var s := "[b][font_size=16]%s[/font_size][/b]\n" % WORLD[c2]["name"]
	s += "[color=%s]Наша зависимость от них / их зависимость от нас, %% ВВП своей страны:[/color]\n" % COL_DIM
	s += "Торговля: %.1f / %.1f · Энергия: %.1f / %.1f · Долг: %.1f / %.1f\n" % [float(d2["tr_out"]), float(d2["tr_in"]), float(d2["en_out"]), float(d2["en_in"]), float(d2["fin_out"]), float(d2["fin_in"])]
	var bal: float = float(d2["bal"])
	var who: String = "они зависят от нас сильнее, чем мы от них" if bal > 0.05 else ("мы зависим от них сильнее, чем они от нас" if bal < -0.05 else "зависимость взаимная и равная")
	s += "Баланс зависимости: [b]%+.1f[/b] — %s\n" % [bal, who]
	s += "Наше влияние на них: [b]%.0f[/b] · их влияние на нас: [b]%.0f[/b]\n" % [ex_leverage(c2), ex_leverage_on_us(c2)]
	s += "Соглашение: %s · пошлины: %s · ответ партнёра: %s\n" % [EX_DEAL[int(p2["deal"])], EX_TAR[int(p2["tar"])], EX_TAR[int(p2["ret"])]]
	s += "[color=%s]Чем выше наше влияние, тем легче просить об услугах; чем выше их влияние на нас, тем сильнее они могут давить (пошлины, ставки, энергия).[/color]" % COL_DIM
	xw_info_rt.text = s
	var off: bool = game_over
	xw_btn["deal-"].disabled = off or int(p2["deal"]) <= 0 or ex_cd_get(c2, "deal") > 0
	xw_btn["deal+"].disabled = off or int(p2["deal"]) >= 3 or ex_cd_get(c2, "deal") > 0
	xw_btn["tar-"].disabled = off or int(p2["tar"]) <= 0 or ex_cd_get(c2, "tar") > 0
	xw_btn["tar+"].disabled = off or int(p2["tar"]) >= 3 or ex_cd_get(c2, "tar") > 0
	xw_btn["aid"].disabled = off or ex_cd_get(c2, "aid") > 0
	xw_btn["dbuy-"].disabled = off or int(p2["dbuy"]) <= 0 or ex_cd_get(c2, "dbuy") > 0
	xw_btn["dbuy+"].disabled = off or int(p2["dbuy"]) >= 3 or ex_cd_get(c2, "dbuy") > 0
	xw_btn["bonds"].disabled = off or float(p2["infl"]) < 60.0 or ex_cd_get(c2, "favor") > 0
	xw_btn["tariff"].disabled = off or float(p2["infl"]) < 60.0 or int(p2["ret"]) == 0 or ex_cd_get(c2, "favor") > 0
