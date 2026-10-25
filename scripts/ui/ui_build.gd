# v50_1: окно «Строительство». Выберите сооружение — справа видно, сколько стоит, что даст, как отнесутся группы
# и есть ли спрос на продукцию его рынка; затем щёлкните по своей АТЕ на карте — там и встанет сооружение.
# Политкапитал на стройку не тратится; построенное рисуется значком на своей АТЕ.
extends "res://scripts/ui/ui_budget.gd"

const PROJ_CATS := ["Энергетика", "Транспорт", "Промышленность", "Сельское хозяйство", "Социальная сфера", "Технологии", "Жильё", "Экология",
	"Культура", "Религия", "Образование", "Здравоохранение", "Оборона", "Госуправление"]
const PROJ_CAT_ICO := ["energy", "grid", "work", "box", "people", "flask", "hall", "globe", "masks", "faith", "book", "medcross", "shield", "scales"]

var bld_btns := {}
var bld_info_rt: RichTextLabel = null
var bld_list_rt: RichTextLabel = null
var bld_hint: Label = null
var bld_reg_rt: RichTextLabel = null    # v55_1: сооружения выбранного региона (улучшение, ремонт)
var bld_mega_rt: RichTextLabel = null
var bld_corp_rt: RichTextLabel = null
var bld_cancel_btn: Button = null       # 0.56: выбранный тип остаётся после постройки — выйти из режима: «Отмена», Esc, правый щелчок


func build_build_window() -> void:
	var w: FloatWindow = new_window("build", "Строительство", 2, Rect2(0.25, 0.0, 0.45, 0.78))
	bld_hint = add_note(w.body, "", true)
	bld_cancel_btn = make_button("Отмена (Esc, правый щелчок)", w.body)
	bld_cancel_btn.tooltip_text = "Снять выбор сооружения. Пока оно выбрано, каждый щелчок по своей АТЕ ставит новую стройку в очередь."
	bld_cancel_btn.pressed.connect(bld_cancel)
	bld_cancel_btn.visible = false
	# 0.56: бюджет «Строительство» и мощность отрасли
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 6)
	w.body.add_child(bh)
	bld_sum_rt = make_rt(bh)
	for d in [-1, 1]:
		var b := Button.new()
		b.text = "−" if d < 0 else "+"
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(32.0, 0.0)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.tooltip_text = "Линия бюджета «Строительство»: ±0,1%% ВВП (с Shift — ±1%%). Изменение идёт через план бюджета."
		var dd: int = d
		b.pressed.connect(func() -> void:
			if pl_deny():
				return
			bld_set(bld_budget_ok() if bld_budget0 < 0.0 else bld_budget)
			bld_set(bld_budget + float(dd) * (1.0 if Input.is_key_pressed(KEY_SHIFT) else 0.1))
			refresh())
		bh.add_child(b)
	# две колонки: государство и частные инвесторы
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 10)
	w.body.add_child(cols)
	var lc := VBoxContainer.new()
	lc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lc.add_theme_constant_override("separation", 4)
	cols.add_child(lc)
	var rc := VBoxContainer.new()
	rc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rc.add_theme_constant_override("separation", 4)
	cols.add_child(rc)
	add_title(lc, "Государство строит")
	bld_state_box = VBoxContainer.new()
	bld_state_box.add_theme_constant_override("separation", 4)
	lc.add_child(bld_state_box)
	bld_auto_btn = make_button("", lc)
	bld_auto_btn.toggle_mode = true
	bld_auto_btn.tooltip_text = "Министерства сами составляют план строек на год (рынки с нехваткой мощностей, отстающие регионы) и ставят их в очередь, когда в бюджете «Строительство» есть свободные деньги. Лишние пункты плана можно вычеркнуть."
	bld_auto_btn.toggled.connect(func(on: bool) -> void:
		if pl_deny():
			bld_auto_btn.set_pressed_no_signal(not on)
			return
		ap["build"] = on
		if on:
			bld_plan_make()
		refresh())
	bld_plan_box = VBoxContainer.new()
	bld_plan_box.add_theme_constant_override("separation", 2)
	lc.add_child(bld_plan_box)
	add_title(rc, "Частные инвесторы")
	bld_priv_box = VBoxContainer.new()
	bld_priv_box.add_theme_constant_override("separation", 4)
	rc.add_child(bld_priv_box)
	add_title(rc, "Выгодно строить")
	bld_prof_box = VBoxContainer.new()
	bld_prof_box.add_theme_constant_override("separation", 2)
	rc.add_child(bld_prof_box)
	add_title(w.body, "Новая стройка")
	var grp := ButtonGroup.new()
	grp.allow_unpress = true
	for ci in PROJ_CATS.size():
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 4)
		w.body.add_child(hb)
		var ic: Control = Ico.make(String(PROJ_CAT_ICO[ci]), C_ACCENT.lightened(0.2), 13.0)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(ic)
		var cl := Label.new()
		cl.text = PROJ_CATS[ci]
		cl.add_theme_font_size_override("font_size", 12)
		cl.add_theme_color_override("font_color", C_DIM)
		hb.add_child(cl)
		var fl := HFlowContainer.new()
		fl.add_theme_constant_override("h_separation", 4)
		fl.add_theme_constant_override("v_separation", 4)
		w.body.add_child(fl)
		for pd in PROJECTS:
			if int(pd["cat"]) != ci:
				continue
			var b := Button.new()
			b.theme_type_variation = "SmallButton"
			b.text = String(pd["name"])
			# v55_3: длинное название (мегапроекты) переносится на 2 строки и не раздвигает окно
			if b.text.length() > 30:
				b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				b.custom_minimum_size.x = 240.0
			b.toggle_mode = true
			b.button_group = grp
			b.focus_mode = Control.FOCUS_NONE
			b.tooltip_text = String(pd["desc"])
			var pid: String = String(pd["id"])
			b.toggled.connect(func(on: bool) -> void:
				bld_pick = pid if on else ("" if bld_pick == pid else bld_pick)
				update_build_window())
			fl.add_child(b)
			bld_btns[pid] = b
	bld_info_rt = make_rt(w.body)
	# 0.56: перенесено сюда — научные сооружения (из «Технологий»), порты (из «Флота»), сооружения страны (из «Экономики»)
	add_title(w.body, "Наука")
	bld_sci_rt = make_rt(w.body)
	bld_sci_box = HFlowContainer.new()
	bld_sci_box.add_theme_constant_override("h_separation", 4)
	bld_sci_box.add_theme_constant_override("v_separation", 4)
	w.body.add_child(bld_sci_box)
	bld_port_title = add_title(w.body, "Порты")
	bld_port_box = VBoxContainer.new()
	w.body.add_child(bld_port_box)
	add_title(w.body, "Сооружения страны")
	bld_st_rt = make_rt(w.body)
	bld_rep_btn = make_button("Отремонтировать всё", w.body)
	bld_rep_btn.pressed.connect(repair_all)
	add_title(w.body, "Сооружения выбранного региона")
	bld_reg_rt = make_rt(w.body)
	bld_reg_rt.meta_clicked.connect(on_bld_meta)
	add_title(w.body, "Мегапроект страны")
	bld_mega_rt = make_rt(w.body)
	add_title(w.body, "Стройка других стран")
	bld_corp_rt = make_rt(w.body)


var bld_sum_rt: RichTextLabel = null
var bld_state_box: VBoxContainer = null
var bld_priv_box: VBoxContainer = null
var bld_prof_box: VBoxContainer = null
var bld_plan_box: VBoxContainer = null
var bld_auto_btn: Button = null
var bld_sci_rt: RichTextLabel = null
var bld_sci_box: HFlowContainer = null
var bld_port_title: Control = null
var bld_port_box: VBoxContainer = null
var bld_st_rt: RichTextLabel = null
var bld_sig := ""
var bld_rep_btn: Button = null


# открыть окно строительства (из карточки региона, «Технологий», «Флота», «Экономики»)
func bld_open() -> void:
	if not wins.has("build"):
		return
	var fw: FloatWindow = wins["build"]
	fw.closed = false
	if tech_is_open():
		set_tech_open(false)
	if current_desk != 2:
		show_desk(2)
	else:
		show_desk(current_desk)
	fw.move_to_front()


func bld_clear(box: Control) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func bld_bar(parent: Control, frac: float, col: Color) -> void:
	var pb := ProgressBar.new()
	pb.min_value = 0.0
	pb.max_value = 1.0
	pb.value = clampf(frac, 0.0, 1.0)
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0.0, 8.0)
	var fg := sbox(col, Color(0, 0, 0, 0), 0, 3, 0.0, 0.0)
	var bg := sbox(C_PANEL2.darkened(0.2), Color(0, 0, 0, 0), 0, 3, 0.0, 0.0)
	pb.add_theme_stylebox_override("fill", fg)
	pb.add_theme_stylebox_override("background", bg)
	parent.add_child(pb)


func bld_sbtn(parent: Control, txt: String, tip: String, cb: Callable) -> Button:
	var b := Button.new()
	b.theme_type_variation = "SmallButton"
	b.focus_mode = Control.FOCUS_NONE
	b.text = txt
	b.tooltip_text = tip
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func bld_row_card(parent: Control, col: Color) -> VBoxContainer:
	var pc := PanelContainer.new()
	var sb := sbox(C_PANEL2, col, 0, 6, 8.0, 4.0)
	sb.border_width_left = 3
	pc.add_theme_stylebox_override("panel", sb)
	parent.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	pc.add_child(vb)
	return vb


func bld_lbl(parent: Control, txt: String, fs: int = 12, col: Color = C_TEXT) -> Label:
	var l := Label.new()
	l.text = txt
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l


func update_build_queues() -> void:
	if bld_state_box == null:
		return
	var a := bq_alloc(false)
	var t := "[b]Бюджет «Строительство»:[/b] %.1f%% ВВП — %.1f млрд в год" % [bld_budget_ok(), float(a["money"]) * 12.0]
	if bld_budget0 >= 0.0:
		t += " [color=%s](в плане бюджета: %.1f%%)[/color]" % [COL_WARN, bld_budget]
	t += "
Мощность стройотрасли: [b]%.1f[/b] млрд в месяц · занято: государство %.1f, частные %.1f" % [float(a["cap"]), float(a["state"]), float(a["priv"])]
	if float(a["state"]) < float(a["money"]) * 0.5 and not bq.is_empty():
		t += "
[color=%s]Стройки упираются в мощность отрасли — жилые кварталы её расширяют.[/color]" % COL_WARN
	bld_sum_rt.text = "[font_size=13]%s[/font_size]" % t
	var sig := "%s|%s|%s|%s|%s|%d|%d" % [str(bq), str(bq_priv), str(bld_plan), str(bld_breaks), str(ap.get("build", false)), int(capital), turn]
	if sig == bld_sig:
		return
	bld_sig = sig
	bld_clear(bld_state_box)
	if bq.is_empty():
		bld_lbl(bld_state_box, "Очередь пуста. Выберите сооружение ниже и щёлкните по своей АТЕ на карте.", 12, C_DIM)
	for k in bq.size():
		var it: Dictionary = bq[k]
		var pd := find_by_id(PROJECTS, String(it["id"]))
		var vb := bld_row_card(bld_state_box, C_ACCENT if not bool(it.get("auto", false)) else C_TEAL)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 3)
		vb.add_child(hb)
		var eta := bq_eta(it)
		var st := ("ещё %d мес." % eta) if eta > 0 else ("ждёт денег или мощностей" if eta < 0 else "готово")
		bld_lbl(hb, "%d. %s%s — «%s»" % [k + 1, "улучшение: " if bool(it.get("upg", false)) else "", pd.get("name", it["id"]), REGIONS[int(it["i"])]["name"]], 12)
		var uid: int = int(it["uid"])
		bld_sbtn(hb, "⤒", "В начало очереди", func() -> void: bq_move(uid, -1000)).disabled = k == 0
		bld_sbtn(hb, "▲", "Выше в очереди", func() -> void: bq_move(uid, -1)).disabled = k == 0
		bld_sbtn(hb, "▼", "Ниже в очереди", func() -> void: bq_move(uid, 1)).disabled = k == bq.size() - 1
		bld_sbtn(hb, "✕", "Остановить стройку: потраченное не вернётся, жители региона недовольны", func() -> void: bq_cancel(uid))
		bld_bar(vb, float(it["done"]) / maxf(0.001, float(it["cost"])), C_GOOD if eta >= 0 else C_WARN)
		bld_lbl(vb, "%.1f из %.1f млрд · %s%s" % [float(it["done"]), float(it["cost"]), st, " · по плану министерств" if bool(it.get("auto", false)) else ""], 11, C_DIM)
	var on: bool = bool(ap.get("build", false))
	bld_auto_btn.set_pressed_no_signal(on)
	bld_auto_btn.text = "Автостроительство министерств: %s" % ("включено" if on else "выключено")
	bld_clear(bld_plan_box)
	if on:
		if bld_plan.is_empty():
			bld_lbl(bld_plan_box, "План на год пока пуст: министерства не нашли, что строить в пределах бюджета.", 11, C_DIM)
		for k in bld_plan.size():
			var pl: Dictionary = bld_plan[k]
			var ck := CheckBox.new()
			ck.focus_mode = Control.FOCUS_NONE
			ck.set_pressed_no_signal(not bool(pl["off"]))
			ck.disabled = bool(pl["done"])
			ck.text = "%s — «%s» (%s; министерство «%s»)%s" % [find_by_id(PROJECTS, String(pl["id"])).get("name", pl["id"]), REGIONS[int(pl["i"])]["name"], pl["why"],
				MINISTRIES[int(pl["min"])]["name"] if int(pl["min"]) < MINISTRIES.size() else "?", " — начато" if bool(pl["done"]) else ""]
			ck.add_theme_font_size_override("font_size", 12)
			var kk: int = k
			ck.toggled.connect(func(_on: bool) -> void: bld_plan_toggle(kk))
			bld_plan_box.add_child(ck)
	bld_clear(bld_priv_box)
	if not con_dyn():
		bld_lbl(bld_priv_box, "Выключено в настройках новой игры («Стройка корпораций и других стран»).", 12, C_DIM)
	elif bq_priv.is_empty():
		bld_lbl(bld_priv_box, "Сейчас частные инвесторы ничего не строят: им выгодно то, что быстро окупается. Налоговые льготы ускоряют окупаемость.", 12, C_DIM)
	for it in bq_priv:
		var pd2 := find_by_id(PROJECTS, String(it["id"]))
		var vb2 := bld_row_card(bld_priv_box, C_PURPLE)
		bld_lbl(vb2, "%s — «%s»" % [pd2.get("name", it["id"]), REGIONS[clampi(int(it["i"]), 0, REGIONS.size() - 1)]["name"]], 12)
		var eta2 := bq_eta(it)
		bld_bar(vb2, float(it["done"]) / maxf(0.001, float(it["cost"])), C_PURPLE.lightened(0.2))
		bld_lbl(vb2, "Инвестор: %s · %.1f из %.1f млрд · %s%s" % [String(it["corp"]), float(it["done"]), float(it["cost"]), ("ещё %d мес." % eta2) if eta2 > 0 else "ждёт мощностей", " · льгота" if bool(it.get("brk", false)) else ""], 11, C_DIM)
	bld_clear(bld_prof_box)
	var pr := bld_profitable()
	if pr.is_empty():
		bld_lbl(bld_prof_box, "Пока ничего не окупается быстрее 40 лет.", 11, C_DIM)
	for r in pr.slice(0, 8):
		var pid: String = String(r[1])
		var hb2 := HBoxContainer.new()
		hb2.add_theme_constant_override("separation", 4)
		bld_prof_box.add_child(hb2)
		var yr: float = float(r[0])
		var col: Color = C_GOOD if yr <= 8.0 else (C_WARN if yr <= 12.0 else C_DIM)
		bld_lbl(hb2, "%s — окупится примерно за %.0f г." % [find_by_id(PROJECTS, pid).get("name", pid), yr], 12, col)
		var lb := bld_sbtn(hb2, "Льгота ✓" if bld_breaks.has(pid) else "Льгота", "Налоговая льгота инвесторам, которые строят такое сооружение: государство возвращает им %d%% затрат (статья «Льготы инвесторам»), окупаемость короче на четверть. Инвесторы строят то, что окупается быстрее 12 лет." % int(BQ_BRK_SHARE * 100.0), func() -> void: bld_toggle_break(pid))
		lb.toggle_mode = true
		lb.set_pressed_no_signal(bld_breaks.has(pid))
	bld_update_moved()


# наука, порты и сооружения страны — то, что раньше жило в других окнах
func bld_update_moved() -> void:
	if bld_sci_box == null:
		return
	bld_clear(bld_sci_box)
	if not tech.is_empty():
		var t := ""
		for d in TECH_BUILDINGS:
			var id: String = d["id"]
			var inq := 0
			var left := 0
			for q in tech["q"]:
				if q["id"] == id:
					inq += 1
					left = maxi(left, int(q["left"]))
			t += "%s: построено %d/%d%s\n" % [d["name"], int(tech["bld"][id]), int(d["max"]), (", строится %d (ещё %d мес.)" % [inq, left]) if inq > 0 else ""]
			var miss := tech_build_missing(id)
			var b := Button.new()
			b.theme_type_variation = "SmallButton"
			b.focus_mode = Control.FOCUS_NONE
			b.text = "%s (%.1f млрд)" % [d["name"], gdp * float(d["cost"]) / 100.0]
			b.disabled = game_over or miss != ""
			b.tooltip_text = "%s\nСрок: %d мес. Содержание: %.2f%% ВВП в год.%s" % [d["d"], int(d["months"]), float(d["up"]), ("\nСейчас нельзя: " + miss) if miss != "" else ""]
			b.pressed.connect(on_tech_build.bind(id))
			bld_sci_box.add_child(b)
		bld_sci_rt.text = "[font_size=13]%s[/font_size]" % t.strip_edges()
	bld_clear(bld_port_box)
	var ps: Array = fleet_ports_summary() if not flt.is_empty() else []
	bld_port_title.visible = not ps.is_empty()
	for p in ps:
		var row := HBoxContainer.new()
		bld_port_box.add_child(row)
		var stt := " · строится, осталось %d сут." % int(p["build"]) if int(p["build"]) > 0 else ""
		bld_lbl(row, "%s — загрузка %.0f%%%s" % [String(p["name"]), float(p["util"]) * 100.0, stt], 12)
		var b2 := bld_sbtn(row, "Расширить (%.1f млрд)" % fleet_port_cost(String(p["id"])), "Расширение на 12 месяцев: пропускная способность порта +12%, стоит долга и 2 капитала.", on_fleet_port.bind(String(p["id"])))
		b2.disabled = int(p["build"]) > 0 or cap_spendable() < 2.0 or game_over
	var sl := struct_lines()
	bld_st_rt.text = "[font_size=13]%s[/font_size]" % "\n".join(sl)
	var rc: float = repair_cost_pct()
	bld_rep_btn.text = "Отремонтировать всё (%.1f млрд)" % (gdp * rc / 100.0)
	bld_rep_btn.disabled = game_over or rc < 0.005


func bld_cancel() -> void:
	if bld_pick == "":
		return
	bld_pick = ""
	update_build_window()
	if map_ctl != null:
		map_redraw()


func on_bld_meta(meta: Variant) -> void:
	var s := String(meta)
	var why := ""
	if s.begins_with("upg:"):
		why = con_upgrade_start(selected_region, s.substr(4))
	elif s.begins_with("rep:"):
		con_repair(selected_region, s.substr(4))
	if why != "":
		log_line("[color=%s]Улучшение не начато: %s.[/color]" % [COL_WARN, why])
	update_build_window()


func update_build_window() -> void:
	if bld_info_rt == null:
		return
	for pid in bld_btns:
		(bld_btns[pid] as Button).set_pressed_no_signal(pid == bld_pick)
	bld_cancel_btn.visible = bld_pick != ""
	if bld_pick == "":
		bld_hint.text = "Выберите сооружение, затем щёлкните по своей АТЕ на карте — стройка встанет в очередь. Деньги идут из линии бюджета «Строительство» по очереди сверху вниз; на стройку реагируют группы интересов."
		bld_info_rt.text = ""
	else:
		var pd := find_by_id(PROJECTS, bld_pick)
		bld_hint.text = "Щёлкайте по своим АТЕ на карте — в каждой начнётся «%s». Выбор остаётся, пока не нажмёте «Отмена», Esc или правую кнопку мыши." % pd["name"]
		var lo := 1e9
		var hi := 0.0
		for i in regions.size():
			var c: float = gdp * project_cost_pct(i, pd) / 100.0
			lo = minf(lo, c)
			hi = maxf(hi, c)
		var t := "[b]%s[/b] — не меньше %d мес., %s млрд (в крупных регионах дороже)\n" % [pd["name"], int(pd["months"]), ("%.1f" % lo) if absf(hi - lo) < 0.05 else ("%.1f–%.1f" % [lo, hi])]
		var yb := bld_payback(bld_pick, false)
		if yb < 40.0:
			t += "Для частного инвестора окупается за [b]%.0f[/b] лет%s.\n" % [yb, (" (с льготой — %.0f)" % bld_payback(bld_pick)) if bld_breaks.has(bld_pick) else ""]
		t += "%s\n" % struct_effect_text(pd)
		t += "Группы: %s\n" % proj_group_text(bld_pick)
		t += bld_demand_text(pd)
		bld_info_rt.text = "[font_size=13]%s[/font_size]" % t
	update_build_queues()
	update_build_extra()


func update_build_extra() -> void:
	if bld_reg_rt == null:
		return
	var si := selected_region
	var t := ""
	if si < 0 or si >= regions.size():
		t = "[color=%s]Выберите регион на карте.[/color]" % COL_DIM
	else:
		var bt: Dictionary = regions[si]["built"]
		if bt.is_empty():
			t = "[color=%s]В регионе «%s» пока нет сооружений.[/color]" % [COL_DIM, REGIONS[si]["name"]]
		else:
			t = "Регион «%s»:\n" % REGIONS[si]["name"]
			for id in bt:
				var e: Dictionary = bt[id]
				var pd := find_by_id(PROJECTS, String(id))
				var cond: float = float(e["cond"])
				var lv: int = int(e.get("lvl", 1))
				var cc: String = COL_GOOD if cond >= 60.0 else (COL_WARN if cond >= 30.0 else COL_BAD)
				var links: PackedStringArray = []
				if lv < CS_LVL_MAX and not bool(pd.get("mega", false)):
					links.append("[url=upg:%s]улучшить до %d (%.1f млрд)[/url]" % [id, lv + 1, gdp * con_upgrade_cost(si, String(id)) / 100.0])
				var rc := con_repair_cost(si, String(id))
				if rc >= 0.0005:
					links.append("[url=rep:%s]ремонт (%.2f млрд)[/url]" % [id, gdp * rc / 100.0])
				t += "• %s%s · уровень %d · состояние [color=%s]%.0f%%[/color]%s\n" % [pd.get("name", id), (" ×%d" % int(e["n"])) if int(e["n"]) > 1 else "", lv, cc, cond,
					(" — " + " · ".join(links)) if links.size() > 0 else ""]
			t += "[color=%s]Уровень 2 даёт эффекты ×1,6, уровень 3 — ×2,1 (и столько же содержание). Сооружения в состоянии ниже 30%% могут попасть в аварию.[/color]" % COL_DIM
	bld_reg_rt.text = "[font_size=13]%s[/font_size]" % t
	var m := con_mega()
	if m.is_empty():
		bld_mega_rt.text = ""
	else:
		var mr := con_mega_region()
		var st := "не начат"
		if struct_total(String(m["id"])) > 0:
			st = "[color=%s]построен[/color]" % COL_GOOD
		elif mr >= 0 and bq_has(mr, String(m["id"])):
			st = "в очереди строек"
		bld_mega_rt.text = "[font_size=13][b]%s[/b] — %s\n%s\nГде: «%s» · %.1f%% ВВП (%.0f млрд) · %d мес. Чтобы начать, выберите его в списке выше и щёлкните по региону.\n%s[/font_size]" % [
			m["name"], st, m.get("desc", ""), String(REGIONS[mr]["name"]) if mr >= 0 else "?", float(m["cost"]), gdp * float(m["cost"]) / 100.0, int(m["months"]), struct_effect_text(m)]
	var ct := ""
	if not con_dyn():
		ct = "[color=%s]Выключено в настройках новой игры («Стройка корпораций и других стран»).[/color]" % COL_DIM
	else:
		var lg: Array = cs.get("log", [])
		for k in range(lg.size() - 1, maxi(-1, lg.size() - 6), -1):
			ct += "[color=%s]%s[/color]\n" % [COL_DIM, String(lg[k])]
		var done: PackedStringArray = []
		for r in con_ai_rows():
			if int(r[3]) == 2:
				done.append(String(WORLD[r[0]]["name"]) if WORLD.has(r[0]) else String(r[0]))
		if done.size() > 0:
			ct += "Мегапроекты завершили: %s." % ", ".join(done)
		if ct == "":
			ct = "[color=%s]Пока никто не строит.[/color]" % COL_DIM
	bld_corp_rt.text = "[font_size=13]%s[/font_size]" % ct


# спрос на продукцию рынка, который расширяет сооружение
func bld_demand_text(pd: Dictionary) -> String:
	var k: Dictionary = pd.get("k", {})
	if k.is_empty() or ec.is_empty():
		return "[color=%s]Мощности рынков не меняет.[/color]" % COL_DIM
	var parts: PackedStringArray = []
	for m in k:
		if not (ec["mk"] as Dictionary).has(m):
			continue
		var mk: Dictionary = ec["mk"][m]
		var u: float = float(mk["u"])
		var short: float = float(mk["short"])
		var col: String = COL_GOOD if u > 0.95 or short > 0.01 else (COL_WARN if u > 0.85 else COL_DIM)
		var verdict: String = "спрос выше мощностей — стройка окупится" if u > 0.95 or short > 0.01 else ("спрос высокий" if u > 0.85 else "мощностей пока хватает")
		parts.append("«%s»: загрузка [color=%s]%.0f%%[/color] — %s" % [String(mk_def(String(m))["name"]), col, u * 100.0, verdict])
	return "Спрос: " + "; ".join(parts)


func build_click(pos: Vector2) -> void:
	if pl_deny():
		return
	var a := ate_at(pos)
	var ri := -1
	if a >= 0:
		ri = ate_region(a)
	if ri < 0:
		var ui := unit_at(pos)
		if ui >= 0 and map_unit_local.has(ui):
			ri = int(map_unit_local[ui])
			a = -1
	if ri < 0:
		log_line("[color=%s]Строить можно только на своей территории.[/color]" % COL_WARN)
		return
	var why := project_start_at(ri, bld_pick, a)
	if why != "":
		log_line("[color=%s]Стройка не начата: %s.[/color]" % [COL_WARN, why])
		sfx("bad")
		return
	sfx("good")
	selected_region = ri
	update_build_window()
	map_redraw()


# значки сооружений и строек на своих АТЕ (при приближении, на слое «Сооружения»)
func draw_struct_icons(c: Control, s: float, off: Vector2) -> void:
	# 0.55.5: значки только на слое карты «Сооружения» (по умолчанию выключен) или пока выбираете место для стройки
	if map_layer != 14 and bld_pick == "":
		return
	if map_zoom < 1.6 or ate_c.size() == 0:
		return
	var al: float = clampf((map_zoom - 1.6) / 0.8, 0.0, 1.0)
	var rect := Rect2(Vector2.ZERO, c.size)
	for i in regions.size():
		var bt: Dictionary = regions[i]["built"]
		for id in bt:
			var e: Dictionary = bt[id]
			if not e.has("ate"):
				continue
			var pd := find_by_id(PROJECTS, String(id))
			var cat: int = int(pd.get("cat", 0))
			for a in (e["ate"] as Array):
				if int(a) < 0 or int(a) >= ate_c.size():
					continue
				var p: Vector2 = ate_c[int(a)] * s + off
				if not rect.has_point(p):
					continue
				c.draw_circle(p, 8.5, Color(0.06, 0.08, 0.12, 0.85 * al))
				c.draw_arc(p, 8.5, 0.0, TAU, 20, Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.9 * al), 1.2, true)
				Ico.draw_icon(String(PROJ_CAT_ICO[clampi(cat, 0, PROJ_CAT_ICO.size() - 1)]), p - Vector2(5.5, 5.5), 11.0, 1.2, Color(0.95, 0.92, 0.80, al), c)
		for pr in bq:
			if int(pr["i"]) != i or int(pr.get("ate", -1)) < 0 or int(pr["ate"]) >= ate_c.size():
				continue
			var p2: Vector2 = ate_c[int(pr["ate"])] * s + off
			if rect.has_point(p2):
				var done: float = float(pr["done"]) / maxf(0.001, float(pr["cost"]))
				c.draw_circle(p2, 8.5, Color(0.06, 0.08, 0.12, 0.7 * al))
				c.draw_arc(p2, 8.5, -PI / 2.0, -PI / 2.0 + TAU * done, 24, Color(1.0, 0.80, 0.35, al), 2.0, true)
				c.draw_string(c.get_theme_default_font(), p2 + Vector2(-4.0, 4.0), "⚒", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.85, 0.5, al))
