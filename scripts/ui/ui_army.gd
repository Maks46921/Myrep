# v48_1: экран «Вооружённые силы» (desk 15): обзор, оборонный бюджет и его структура, комплектование и резерв,
# закупки вооружений, учения и миссии, экспорт оружия, снабжение боеприпасами, баланс сил с соседями.
extends "res://scripts/ui/ui_war.gd"

const ArmyView := preload("res://scripts/classes/army_view.gd")
const StatBarA := preload("res://scripts/classes/stat_bar.gd")

var arw: Dictionary = {}     # элементы окон
var ar_msg := ""


func build_army_windows() -> void:
	# --- обзор ---
	var w: FloatWindow = new_window("ar_over", "Обзор вооружённых сил", 15, Rect2(0.0, 0.0, 0.25, 0.6))
	arw["view"] = ArmyView.new()
	w.body.add_child(arw["view"])
	arw["over_rt"] = make_rt(w.body)
	var hist := Spark.new()
	hist.title = "Боевая мощь армии по месяцам"
	w.body.add_child(hist)
	arw["spark"] = hist

	# --- оборонный бюджет ---
	w = new_window("ar_budget", "Оборонный бюджет", 15, Rect2(0.0, 0.6, 0.25, 0.4))
	arw["bud_rt"] = make_rt(w.body)
	var r0 := HBoxContainer.new()
	w.body.add_child(r0)
	var bm := fed_btn("−0,1% ВВП", r0, "Сократить статью бюджета «армия».")
	bm.pressed.connect(ar_ui_spend.bind(-0.1))
	var bp := fed_btn("+0,1% ВВП", r0, "Увеличить статью бюджета «армия» (то же, что ползунок на вкладке «Бюджет»).")
	bp.pressed.connect(ar_ui_spend.bind(0.1))
	arw["bs"] = {}
	for k in AR_BS_KEYS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		w.body.add_child(row)
		var lb := Label.new()
		lb.custom_minimum_size = Vector2(170.0, 0.0)
		lb.add_theme_font_size_override("font_size", 13)
		lb.tooltip_text = String(AR_BS_TIPS[k])
		lb.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(lb)
		var sb := StatBarA.new()
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sb.custom_minimum_size = Vector2(60.0, 12.0)
		row.add_child(sb)
		var b1 := make_button("−", row)
		b1.theme_type_variation = "SmallButton"
		b1.custom_minimum_size = Vector2(28.0, 0.0)
		b1.tooltip_text = "−5 п.п. этой статье, остальным — больше."
		b1.pressed.connect(ar_ui_bs.bind(k, -0.05))
		var b2 := make_button("+", row)
		b2.theme_type_variation = "SmallButton"
		b2.custom_minimum_size = Vector2(28.0, 0.0)
		b2.tooltip_text = "+5 п.п. этой статье за счёт остальных."
		b2.pressed.connect(ar_ui_bs.bind(k, 0.05))
		arw["bs"][k] = [lb, sb]
	arw["bs_note"] = add_note(w.body, "", true)

	# --- комплектование и резерв ---
	w = new_window("ar_svc", "Комплектование и резерв", 15, Rect2(0.25, 0.0, 0.225, 0.42))
	arw["svc_rt"] = make_rt(w.body)
	arw["svc_btn"] = {}
	for m in ["pro", "mix", "con"]:
		var b := fed_btn(String(AR_SVC[m]["n"]), w.body, String(AR_SVC[m]["d"]))
		b.toggle_mode = true
		b.pressed.connect(func() -> void:
			ar_msg = ar_svc_check(m)
			ar_set_svc(m)
			refresh())
		arw["svc_btn"][m] = b
	add_title(w.body, "Обученный резерв")
	arw["rsv_bar"] = StatBarA.new()
	arw["rsv_bar"].custom_minimum_size = Vector2(60.0, 12.0)
	arw["rsv_bar"].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	w.body.add_child(arw["rsv_bar"])
	arw["rsv_rt"] = make_rt(w.body)
	arw["td"] = fed_btn("Сформировать бригаду территориальной обороны (2)", w.body, "Добровольцы для обороны своей земли: дёшево, быстро, сильны только дома.")
	arw["td"].pressed.connect(func() -> void:
		ar_msg = ar_td_check()
		ar_td_form()
		refresh())

	# --- закупки ---
	w = new_window("ar_proc", "Закупки вооружений", 15, Rect2(0.25, 0.42, 0.225, 0.58))
	arw["proc_rt"] = make_rt(w.body)
	arw["proc_run"] = VBoxContainer.new()
	arw["proc_run"].add_theme_constant_override("separation", 2)
	w.body.add_child(arw["proc_run"])
	add_title(w.body, "Новые программы (2 капитала)")
	arw["proc_btn"] = {}
	for p in AR_PROG:
		var id := String(p["id"])
		var b := fed_btn(String(p["n"]), w.body, String(p["d"]))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.custom_minimum_size = Vector2(40.0, 0.0)
		b.pressed.connect(func() -> void:
			ar_msg = ar_prog_check(id)
			ar_prog_start(id)
			refresh())
		arw["proc_btn"][id] = b

	# --- учения, миссии, экспорт, снабжение ---
	w = new_window("ar_act", "Учения, миссии, экспорт, снабжение", 15, Rect2(0.475, 0.0, 0.225, 0.6))
	arw["act_rt"] = make_rt(w.body)
	add_title(w.body, "Учения")
	arw["ex_plan"] = fed_btn("Плановые учения (2)", w.body, "Готовность войск выше на несколько месяцев.")
	arw["ex_plan"].pressed.connect(func() -> void:
		ar_msg = ar_ex_check("plan")
		ar_exercise("plan")
		refresh())
	arw["ex_allied"] = fed_btn("Совместные учения с союзниками (3)", w.body, "Совместные учения с НАТО или партнёрами по оборонному договору: готовность, опыт, отношения.")
	arw["ex_allied"].pressed.connect(func() -> void:
		ar_msg = ar_ex_check("allied")
		ar_exercise("allied")
		refresh())
	var r2 := HBoxContainer.new()
	w.body.add_child(r2)
	arw["ex_tgt"] = fed_opt(r2, [], "Сосед, у границы с которым пройдут учения.")
	arw["ex_tgt_ids"] = []
	arw["ex_border"] = fed_btn("У границы (3)", r2, "Демонстрация силы: сосед не решится напасть ближайший год, но отношения с ним хуже; «ястреб» может ответить своими учениями.")
	arw["ex_border"].pressed.connect(func() -> void:
		var ids: Array = arw["ex_tgt_ids"]
		var i: int = (arw["ex_tgt"] as OptionButton).selected
		var c: String = String(ids[i]) if i >= 0 and i < ids.size() else ""
		ar_msg = ar_ex_check("border", c)
		ar_exercise("border", c)
		refresh())
	add_title(w.body, "Миротворческие миссии")
	arw["mis_btn"] = {}
	for m in AR_MIS:
		var id := String(m["id"])
		var b := fed_btn(String(m["n"]), w.body, String(m["d"]) + " Нужно %.1f тыс. военных; 2 капитала." % float(m["k"]))
		b.toggle_mode = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.custom_minimum_size = Vector2(40.0, 0.0)
		b.pressed.connect(func() -> void:
			ar_msg = ar_mis_check(id)
			ar_mis_toggle(id)
			refresh())
		arw["mis_btn"][id] = b
	add_title(w.body, "Экспорт оружия (3)")
	var r3 := HBoxContainer.new()
	w.body.add_child(r3)
	arw["exp_btn"] = []
	for lv in 3:
		var b := fed_btn(["Запрет", "Союзникам", "Активный"][lv], r3, ["Никакого экспорта: меньше заказов у заводов и доходов; экологи и левые довольны.", "Обычный режим: только союзникам и партнёрам.", "Экспорт всем, кто не под санкциями: доход в бюджет и рост производства, но страны, для которых важны ценности, недовольны."][lv])
		b.toggle_mode = true
		b.pressed.connect(func() -> void:
			ar_msg = ar_exp_check(lv)
			ar_set_exp(lv)
			refresh())
		(arw["exp_btn"] as Array).append(b)
	add_title(w.body, "Снабжение")
	var r4 := HBoxContainer.new()
	w.body.add_child(r4)
	arw["buy"] = fed_btn("Купить боеприпасы (2)", r4, "Срочная закупка у союзников: +0,3 месяца боёв. Членам НАТО поставляют быстрее.")
	arw["buy"].pressed.connect(func() -> void:
		ar_msg = ar_buy_check()
		ar_buy_ammo()
		refresh())
	arw["wecon"] = fed_btn("Военная экономика (4)", r4, "Только на войне или при всеобщей мобилизации: выпуск боеприпасов втрое больше, но рост −1,5 п.п. и инфляция +0,6 п.п.")
	arw["wecon"].toggle_mode = true
	arw["wecon"].pressed.connect(func() -> void:
		ar_msg = ar_wecon_check()
		ar_wecon_toggle()
		refresh())

	# --- соседи ---
	w = new_window("ar_world", "Баланс сил: соседи и крупные армии", 15, Rect2(0.475, 0.6, 0.225, 0.4))
	arw["riv"] = ArmyView.new()
	w.body.add_child(arw["riv"])
	arw["riv_rt"] = make_rt(w.body)


func ar_ui_spend(d: float) -> void:
	if opp_mode:
		ar_msg = "В оппозиции бюджетом распоряжается правительство."
		refresh()
		return
	var v: float = (float(pol_abs["army"]) + d * gdp / 100.0) if is_abs("army") else float(pol["army"]) + d
	var allowed := lock_allowed("army", v)
	if is_abs("army"):
		pol_abs["army"] = allowed
		pol["army"] = allowed / gdp * 100.0
	else:
		pol["army"] = allowed
	if sliders.has("army"):
		(sliders["army"]["slider"] as HSlider).set_value_no_signal(slider_value_for("army"))
		update_slider_label("army")
	ar_msg = "" if is_equal_approx(allowed, v) else "Дальше менять расходы нельзя: мешает закон или бюджетное правило."
	refresh()


func ar_ui_bs(k: String, d: float) -> void:
	ar_msg = ar_shift_bs(k, d)
	refresh()


func ar_card_fmt(v: float, dig: int = 0) -> String:
	return ("%." + str(dig) + "f") % v


func update_army_windows() -> void:
	if arw.is_empty() or current_desk != 15:
		return
	if not ar_on():
		(arw["over_rt"] as RichTextLabel).text = "У страны нет армии."
		return
	var sr: float = mil_spend_ratio()
	var cap: float = mil_cap()
	var tot: float = mil_total(ccode)
	var rd: float = ar_rd()
	var am: float = float(ar["ammo"])
	var cards: Array = [
		["Кадровая армия", "%.0f тыс." % tot, clampf(tot / maxf(cap * 1.3, 1.0), 0.0, 1.0), clampf(tot / maxf(cap, 1.0), 0.0, 1.0), "из %.0f" % cap],
		["Обученный резерв", "%.0f тыс." % ar_rsv(), clampf(ar_rsv() / maxf(tot * 3.0, 1.0), 0.0, 1.0), clampf(ar_rsv() / maxf(tot, 1.0), 0.0, 1.0), ""],
		["Выучка", "%.2f" % mil_q(ccode), clampf((mil_q(ccode) - 0.6) / 0.7, 0.0, 1.0), clampf((mil_q(ccode) - 0.7) / 0.5, 0.0, 1.0), ""],
		["Готовность", "%.0f%%" % rd, rd / 100.0, rd / 100.0, "моб. %d сут." % int(round(35.0 * ar_mob_speed()))],
		["Оснащение", "×%.2f" % float(ar["eq"]), clampf((float(ar["eq"]) - 0.5) / 1.1, 0.0, 1.0), clampf((float(ar["eq"]) - 0.6) / 0.7, 0.0, 1.0), ""],
		["Боеприпасы", "%.1f мес. боёв" % am, clampf(am / 3.0, 0.0, 1.0), clampf(am / 1.5, 0.0, 1.0), "+%.2f/мес" % ((0.1 + ar_ind() * 0.6) / 12.0 * (3.0 if bool(ar["wecon"]) else 1.0))],
		["Авиация", "%.0f самолётов" % float(ar["air"]), clampf(float(ar["air"]) / 200.0, 0.0, 1.0), clampf(float(ar["air"]) / 80.0, 0.0, 1.0), ""],
		["ПВО", "%.0f" % float(ar["ad"]), clampf(float(ar["ad"]) / 30.0, 0.0, 1.0), clampf(float(ar["ad"]) / 15.0, 0.0, 1.0), "+15%" if tech_done("m3") else ""]]
	var comp := ar_comp()
	var segs: Array = []
	for tp in AR_TYPES:
		segs.append([float(comp[tp]), ArmyView.TP_COL[tp], tp, String(AR_INFO[tp]["short"])])
	(arw["view"] as Control).call("set_cards", cards, segs)
	var t := "Расходы на оборону: [b]%.1f%% ВВП[/b] (%.1f млрд € в год). " % [ar_nato_pct(), ar_nato_pct() * gdp / 100.0]
	if mil_is_nato(ccode):
		var col: String = COL_GOOD if ar_nato_pct() >= 3.5 else (COL_WARN if ar_nato_pct() >= 2.0 else COL_BAD)
		t += "Цели НАТО: [color=%s]2%% — %s; 3,5%% к 2035 г. — %s[/color].\n" % [col, "выполнена" if ar_nato_pct() >= 2.0 else "не выполнена", "выполнена" if ar_nato_pct() >= 3.5 else "не выполнена"]
	else:
		t += "Страна не в НАТО: рассчитывать приходится на себя и договоры.\n"
	var parts: PackedStringArray = []
	for tp in AR_TYPES:
		if float(comp[tp]) > 0.0:
			parts.append("%s — %.0f тыс." % [String(AR_INFO[tp]["name"]), float(comp[tp])])
	t += "[color=%s]%s[/color]\n" % [COL_DIM, " · ".join(parts)]
	if int(ar["drone"]) > 0 or tech_done("m1"):
		t += "Беспилотники: все соединения сильнее на %d%%.\n" % int(round((ar_drone_mult(ccode) - 1.0) * 100.0))
	if String(ar["mis"]) != "":
		t += "В миротворческой миссии: [b]%.1f тыс.[/b] («%s»), опыт +%.1f%% к выучке.\n" % [ar_mis_k(), String(ar_mis_info(String(ar["mis"]))["n"]), float(ar["xp"]) * 100.0]
	if mil_at_war():
		t += "[b]Война:[/b] боевой дух армии [b]%.0f[/b], противника %.0f · господство в воздухе ×%.2f · удары по стране: рост %+.2f п.п." % [ar_mor(0), ar_mor(1), ar_air_mult(0), ar_strike_g()]
	(arw["over_rt"] as RichTextLabel).text = t
	var sp: Spark = arw["spark"]
	sp.series = [{"v": (ar["hist"]["pw"] as Array).duplicate(), "c": Color(0.45, 0.7, 1.0), "n": "мощь"}]
	sp.queue_redraw()

	# бюджет
	var bt := "Статья «армия»: [b]%.1f%% ВВП[/b] (на старте %.1f%%).\n" % [float(pol["army"]), float(pol_def["army"])]
	bt += "К чему идёт: готовность [b]%.0f%%[/b], оснащение [b]×%.2f[/b], запас [b]%.1f[/b] мес. боёв." % [clampf(25.0 + 35.0 * sr * ar_bs("trn") / 0.15, 15.0, 95.0), clampf(0.55 + 0.45 * sr * ar_bs("eq") / 0.25, 0.5, 1.6) + float(ar["eq_add"]), float(ar["ammo0"]) * pow(ar_bs("stk") / 0.1, 0.8) * sqrt(sr) + float(ar.get("ammo_add", 0.0))]
	(arw["bud_rt"] as RichTextLabel).text = bt
	for k in AR_BS_KEYS:
		var it: Array = arw["bs"][k]
		(it[0] as Label).text = "%s: %.0f%%" % [String(AR_BS_NAMES[k]), ar_bs(k) * 100.0]
		(it[1] as Control).call("set_state", ar_bs(k) * 100.0 / 0.75, 0.6)
	(arw["bs_note"] as Label).text = "Личный состав — сколько солдат; техника — сила каждого соединения и авиации; подготовка — выучка и быстрая мобилизация; запасы — снаряды на случай войны. Меняется постепенно, за месяцы."

	# комплектование
	var sv := String(ar["svc"])
	var st := "Сейчас: [b]%s[/b]. %s" % [String(AR_SVC[sv]["n"]), String(AR_SVC[sv]["d"])]
	if sv != String(ar["svc0"]):
		st += "\n[color=%s]Изменено по сравнению с началом игры (было: %s).[/color]" % [COL_DIM, String(AR_SVC[String(ar["svc0"])]["n"])]
	st += "\nСмена модели: закон (большинство в парламенте), 8 капитала; повторно — через 3 года."
	(arw["svc_rt"] as RichTextLabel).text = st
	for m in ["pro", "mix", "con"]:
		var b: Button = arw["svc_btn"][m]
		b.set_pressed_no_signal(m == sv)
		b.disabled = m != sv and ar_svc_check(m) != ""
		b.tooltip_text = String(AR_SVC[m]["d"]) + ("\n" + ar_svc_check(m) if m != sv else "")
	var b_r: Array = MIL_BASE[ccode]
	var base_r: float = maxf(float(b_r[1]), total_pop() * 1000.0 * 0.0005)
	var rsv_t: float = float(ar["rsv0"]) if sv == String(ar["svc0"]) else base_r * float(AR_SVC[sv]["r"]) / float(AR_SVC[String(ar["svc0"])]["r"])
	(arw["rsv_bar"] as Control).call("set_state", 100.0 * ar_rsv() / maxf(rsv_t, ar_rsv()) , clampf(ar_rsv() / maxf(rsv_t, 1.0), 0.0, 1.0))
	var rt := "Резервистов: [b]%.0f тыс.[/b] (к этому идёт: %.0f тыс.). При частичной мобилизации призывается ≈ %.0f тыс., при всеобщей ≈ %.0f тыс." % [ar_rsv(), rsv_t, mil_reserve_k(1), mil_reserve_k(2)]
	if float(ar["td"]) > 0.0:
		rt += "\nВ территориальной обороне: %.1f тыс. добровольцев." % float(ar["td"])
	(arw["rsv_rt"] as RichTextLabel).text = rt
	(arw["td"] as Button).disabled = ar_td_check() != ""
	(arw["td"] as Button).tooltip_text = "Добровольцы для обороны своей земли: дёшево, быстро, сильны только дома.\n" + ar_td_check()

	# закупки
	var pt := "Программы оплачиваются из специального фонда (в долг) помесячно до поставки. Чем больше обычный бюджет тратит на технику, тем дешевле программы."
	if ar_msg != "":
		pt += "\n[color=%s]%s[/color]" % [COL_WARN, ar_msg]
	(arw["proc_rt"] as RichTextLabel).text = pt
	var run: VBoxContainer = arw["proc_run"]
	for ch in run.get_children():
		ch.queue_free()
	for q in ar["prog"]:
		var p := ar_prog_info(String(q["id"]))
		var lb := Label.new()
		lb.text = "▸ %s — ещё %d мес. (%.2f млрд €)" % [String(p["n"]), int(q["left"]), float(q["cost"])]
		lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lb.add_theme_font_size_override("font_size", 12)
		run.add_child(lb)
		var sb := StatBarA.new()
		sb.custom_minimum_size = Vector2(60.0, 8.0)
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		run.add_child(sb)
		sb.call("set_state", 100.0 * (1.0 - float(q["left"]) / maxf(1.0, float(q["m"]))), 0.8)
	for p2 in AR_PROG:
		var id := String(p2["id"])
		var b2: Button = arw["proc_btn"][id]
		var chk := ar_prog_check(id)
		b2.text = "%s — %.2f млрд €, %d мес." % [String(p2["n"]), ar_prog_cost(id), int(p2["m"])]
		b2.disabled = chk != ""
		var done: int = int((ar["done"] as Dictionary).get(id, 0))
		b2.tooltip_text = String(p2["d"]) + ("\nУже поставлено: %d." % done if done > 0 else "") + ("\n" + chk if chk != "" else "")

	# действия
	var at := ""
	if ar_cd("ex") > 0:
		at += "Следующие учения — через %d мес. " % ar_cd("ex")
	var dt: Dictionary = ar["deter"]
	if not dt.is_empty():
		var nm: PackedStringArray = []
		for c in dt:
			nm.append("%s (%d мес.)" % [String(WORLD[c]["name"]), int(dt[c])])
		at += "Сдерживание после учений: %s. " % ", ".join(nm)
	at += "Экспорт: %s; %s." % [["запрещён", "только союзникам", "активный"][int(ar["exp"])], ("доход %+.2f млрд € в год к обычному" % ar_exp_rev()) if int(ar["exp"]) != 1 else "доходы обычные"]
	if not (ar["pq"] as Array).is_empty():
		at += "\nВ пути боеприпасы: %d партии." % (ar["pq"] as Array).size()
	(arw["act_rt"] as RichTextLabel).text = at
	(arw["ex_plan"] as Button).disabled = ar_ex_check("plan") != ""
	(arw["ex_allied"] as Button).disabled = ar_ex_check("allied") != ""
	var opt: OptionButton = arw["ex_tgt"]
	var ids: Array = mil_targets()
	if ids != arw["ex_tgt_ids"]:
		var sel: int = opt.selected
		opt.clear()
		for c2 in ids:
			opt.add_item(String(WORLD[c2]["name"]))
		arw["ex_tgt_ids"] = ids
		if sel >= 0 and sel < ids.size():
			opt.select(sel)
	var i_s: int = opt.selected
	var tgt: String = String(ids[i_s]) if i_s >= 0 and i_s < ids.size() else ""
	(arw["ex_border"] as Button).disabled = ar_ex_check("border", tgt) != ""
	for m2 in AR_MIS:
		var id2 := String(m2["id"])
		var b3: Button = arw["mis_btn"][id2]
		b3.set_pressed_no_signal(String(ar["mis"]) == id2)
		b3.disabled = ar_mis_check(id2) != ""
	for lv in 3:
		var b4: Button = arw["exp_btn"][lv]
		b4.set_pressed_no_signal(int(ar["exp"]) == lv)
		b4.disabled = lv != int(ar["exp"]) and ar_exp_check(lv) != ""
	(arw["buy"] as Button).disabled = ar_buy_check() != ""
	(arw["buy"] as Button).text = "Купить боеприпасы (2) — %.2f млрд €" % ar_ammo_price(0.3)
	(arw["wecon"] as Button).set_pressed_no_signal(bool(ar["wecon"]))
	(arw["wecon"] as Button).disabled = ar_wecon_check() != ""

	# соседи
	var rows: Array = []
	rows.append([String(WORLD[ccode]["name"]) if WORLD.has(ccode) else ccode, mil_country_power(ccode), 100.0, 0.0, true])
	for r in ar_rival_rows():
		rows.append([String(WORLD[String(r[0])]["name"]), float(r[1]), float(r[2]), float(r[3]), false])
	(arw["riv"] as Control).call("set_rivals", rows.slice(0, 9))
	var rt2 := "Сила = численность × выучка × оснащение. Цвет — отношения с вами; ▲ — страна наращивает армию."
	var up: PackedStringArray = []
	for r2 in ar_rival_rows():
		if float(r2[3]) > 0.04:
			up.append(String(WORLD[String(r2[0])]["name"]))
	if not up.is_empty():
		rt2 += "\n[color=%s]Наращивают армию: %s.[/color]" % [COL_WARN, ", ".join(up)]
	(arw["riv_rt"] as RichTextLabel).text = rt2
