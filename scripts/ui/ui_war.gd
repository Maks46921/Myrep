# Экран «Армия и война» (desk 13): армия, мобилизация, объявление войны, ход войны, мир.
# На большой карте: занятые АТЕ, линия фронта, значки соединений; на экране флота — морские пути и эскадры.
extends "res://scripts/ui/ui_fleet.gd"

const WAR_C0 := Color(0.32, 0.62, 1.0)       # своя сторона
const WAR_C1 := Color(1.0, 0.36, 0.30)       # противник
var war_army_rt: RichTextLabel = null
var war_unit_rt: RichTextLabel = null
var war_ops_rt: RichTextLabel = null
var war_log_rt: RichTextLabel = null
var war_list: VBoxContainer = null
var war_list_key := ""
var war_btn: Dictionary = {}
var war_tgt: OptionButton = null
var war_tgt_ids: Array = []
var war_note: Label = null
var war_msg := ""
var war_occ_ver := -1
var war_occ_tris: Array = [PackedVector2Array(), PackedVector2Array()]
var war_front := PackedVector2Array()
var war_hover_tok := -1
var war_talk_rt: RichTextLabel = null
var war_intl_rt: RichTextLabel = null
var war_talk_chk: Dictionary = {}
var war_repar: OptionButton = null


func build_war_windows() -> void:
	var w: FloatWindow = new_window("war_army", "Армия", 13, Rect2(0.0, 0.0, 0.22, 0.5))
	war_army_rt = make_rt(w.body)
	var r0 := HBoxContainer.new()
	w.body.add_child(r0)
	war_btn["rec"] = fed_btn("Новое соединение (2)", r0, "Сформировать соединение за 90 суток. В мирное время — только в пределах численности, которую оплачивает бюджет (статья «армия»).")
	war_btn["rec"].pressed.connect(func() -> void:
		war_msg = mil_recruit_check()
		mil_recruit()
		refresh())
	add_title(w.body, "Мобилизация")
	var r1 := HBoxContainer.new()
	w.body.add_child(r1)
	for lv in 3:
		var b := fed_btn(["Нет", "Частичная (3)", "Всеобщая (6)"][lv], r1, ["Резервисты дома, экономика работает как обычно.", "Призыв части резерва: больше войск, но меньше рабочих рук и недовольна молодёжь.", "Призыв всего резерва и части населения: огромная армия, тяжёлый удар по экономике и рейтингу."][lv])
		b.toggle_mode = true
		b.pressed.connect(func() -> void:
			war_msg = mil_mob_check(lv)
			mil_mobilize(lv)
			refresh())
		war_btn["mob%d" % lv] = b
	add_title(w.body, "Соединения (щелчок — выбрать)")
	war_list = VBoxContainer.new()
	war_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	war_list.add_theme_constant_override("separation", 1)
	w.body.add_child(war_list)
	add_title(w.body, "Выбранное соединение")
	war_unit_rt = make_rt(w.body)
	var r2 := HBoxContainer.new()
	w.body.add_child(r2)
	war_btn["hold"] = fed_btn("Стоять", r2, "Остановиться и оборонять АТЕ.")
	war_btn["hold"].pressed.connect(func() -> void:
		mil_order_mode(int(mil.get("sel", -1)), "hold")
		refresh())
	war_btn["def"] = fed_btn("Оборонять", r2, "Соединение само занимает позицию на линии фронта и освобождает свои земли, когда есть перевес.")
	war_btn["def"].pressed.connect(func() -> void:
		mil_order_mode(int(mil.get("sel", -1)), "def")
		refresh())
	war_btn["auto"] = fed_btn("Наступать", r2, "Соединение само выбирает цель: освобождает свои земли, атакует ближайшие позиции противника и идёт на его столицу.")
	war_btn["auto"].pressed.connect(func() -> void:
		mil_order_mode(int(mil.get("sel", -1)), "auto")
		refresh())
	var r3 := HBoxContainer.new()
	w.body.add_child(r3)
	war_btn["all_auto"] = fed_btn("Все — наступать", r3, "Все ваши соединения переходят в самостоятельное наступление.")
	war_btn["all_auto"].pressed.connect(func() -> void:
		for f in mil_units_of(ccode):
			mil_order_mode(int(f["id"]), "auto")
		refresh())
	war_btn["all_hold"] = fed_btn("Все — оборона", r3, "Все соединения сами держат линию фронта и освобождают свои земли.")
	war_btn["all_hold"].pressed.connect(func() -> void:
		for f in mil_units_of(ccode):
			mil_order_mode(int(f["id"]), "def")
		refresh())
	war_note = add_note(w.body, "Приказы на карте: щёлкните по значку своего соединения, затем по АТЕ, куда ему идти. Shift+щелчок по побережью противника — морской десант (нужны десантные корабли и перевес флота у цели).", true)

	w = new_window("war_ops", "Война и мир", 13, Rect2(0.0, 0.5, 0.22, 0.5))
	war_tgt = fed_opt(w.body, [], "Страна, которой можно объявить войну: соседи по суше и (при своём флоте) по морю.")
	war_tgt.item_selected.connect(func(_i: int) -> void: refresh())
	war_btn["declare"] = fed_btn("Объявить войну (15)", w.body, "Нужны большинство в парламенте (голосуют партии) и 15 политического капитала. Отношения со всеми странами упадут; война внутри ЕС — санкции. В демократии война бьёт по рейтингу и отношениям с партиями, против другой демократии — сильнее.")
	war_btn["declare"].pressed.connect(on_war_declare)
	war_ops_rt = make_rt(w.body)
	add_title(w.body, "Журнал войны")
	war_log_rt = make_rt(w.body)

	# v38: переговоры и реакция мира
	w = new_window("war_talk", "Переговоры и мир", 13, Rect2(0.22, 0.36, 0.19, 0.64))
	war_talk_rt = make_rt(w.body)
	add_title(w.body, "Требования")
	for id in TALK_IDS:
		if id == "repar":
			var rr := HBoxContainer.new()
			w.body.add_child(rr)
			var lb := Label.new()
			lb.text = "Репарации:"
			rr.add_child(lb)
			war_repar = fed_opt(rr, ["нет", "1% ВВП", "2% ВВП", "3% ВВП", "5% ВВП"], String(TALK_INFO["repar"][1]))
			war_repar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			war_repar.item_selected.connect(func(i: int) -> void:
				talk_sel()["repar"] = i
				refresh())
			continue
		var cb := CheckBox.new()
		cb.text = String(TALK_INFO[id][0])
		cb.tooltip_text = String(TALK_INFO[id][1])
		cb.focus_mode = Control.FOCUS_NONE
		cb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cb.custom_minimum_size = Vector2(40.0, 0.0)
		cb.toggled.connect(func(on: bool) -> void:
			talk_sel()[id] = on
			refresh())
		w.body.add_child(cb)
		war_talk_chk[id] = cb
	var t0 := HBoxContainer.new()
	w.body.add_child(t0)
	war_btn["propose"] = fed_btn("Предложить мир", t0, "Предложить противнику мир на выбранных условиях. При отказе он может прислать встречное предложение; новое предложение — через 15 суток.")
	war_btn["propose"].pressed.connect(func() -> void:
		war_msg = String(talk_propose()["msg"])
		refresh())
	war_btn["p_white"] = fed_btn("Белый мир", t0, "Вернуться к довоенным границам. Противник согласится, если не выигрывает войну.")
	war_btn["p_white"].pressed.connect(on_war_peace.bind("white"))
	var t1 := HBoxContainer.new()
	w.body.add_child(t1)
	war_btn["cf"] = fed_btn("Перемирие", t1, "Остановить бои на 30 суток: фронт замирает, противник уступчивее, мир меньше осуждает. Повторно — через 60 суток.")
	war_btn["cf"].pressed.connect(func() -> void:
		war_msg = String(talk_ceasefire()["msg"])
		refresh())
	war_btn["cf_break"] = fed_btn("Возобновить бои", t1, "Прервать перемирие: войска снова воюют, мир осуждает срыв переговоров.")
	war_btn["cf_break"].pressed.connect(func() -> void:
		talk_ceasefire_break()
		war_msg = "Перемирие прервано."
		refresh())
	var t1b := HBoxContainer.new()
	w.body.add_child(t1b)
	war_btn["med"] = fed_btn("Посредник (3)", t1b, "Пригласить посредника (ЕС, нейтральная страна или ООН): противник уступчивее, осуждение ниже. 3 политического капитала.")
	war_btn["med"].pressed.connect(func() -> void:
		war_msg = String(talk_mediator()["msg"])
		refresh())
	war_btn["p_capit"] = fed_btn("Капитуляция", t1b, "Занятые АТЕ, репарации 3% ВВП противника и ослабление его армии. Нужен счёт +75 (или +50 при взятой столице).")
	war_btn["p_capit"].pressed.connect(on_war_peace.bind("capit"))
	war_btn["p_full"] = fed_btn("Присоединить всю страну", w.body, "Страна противника целиком входит в вашу (как при объединении). Нужен счёт +90 и взятая столица.")
	war_btn["p_full"].pressed.connect(on_war_peace.bind("full"))
	add_title(w.body, "Реакция мира")
	war_intl_rt = make_rt(w.body)


func on_war_declare() -> void:
	var i: int = war_tgt.selected
	if i < 0 or i >= war_tgt_ids.size():
		return
	var r := mil_declare(String(war_tgt_ids[i]))
	war_msg = String(r["msg"])
	refresh()


func update_war_talk() -> void:
	var at_war := mil_at_war()
	win_vis("war_talk", at_war and current_desk == 13)
	if not at_war or war_talk_rt == null:
		return
	var w: Dictionary = mil["war"]
	var sel := talk_sel()
	var q := talk_quote()
	var t := "Противник готов уступить: [b]%.0f[/b] · ваши требования: [b]%.0f[/b]\n" % [float(q["budget"]), float(q["cost"])]
	t += "Условия: %s\n" % talk_pkg_text(q.get("pkg", []))
	var p: float = float(q["p"])
	t += "Согласие: [b][color=%s]%.0f%%[/color][/b]%s\n" % [COL_GOOD if p >= 0.9 else (COL_WARN if p > 0.0 else COL_BAD), p * 100.0, " — " + String(q["why"]) if String(q["why"]) != "" else ""]
	if String(w.get("med", "")) != "":
		t += "Посредник: %s\n" % String(w["med"])
	t += "[color=%s]Готовность растёт с военным счётом, занятыми землями, длительностью войны, посредником и перемирием.[/color]" % COL_DIM
	war_talk_rt.text = t
	for id in war_talk_chk:
		var cb: CheckBox = war_talk_chk[id]
		var why := talk_avail(String(id))
		cb.set_pressed_no_signal(bool(sel.get(id, false)))
		cb.disabled = why != ""
		cb.text = "%s (%.0f)" % [String(TALK_INFO[id][0]), talk_cost(String(id))]
		cb.tooltip_text = String(TALK_INFO[id][1]) + ("\n" + why if why != "" else "")
	war_repar.select(clampi(int(sel.get("repar", 0)), 0, 4))
	for k in ["white", "capit", "full"]:
		var mq := mil_peace_quote(k)
		var b5: Button = war_btn["p_" + k]
		b5.disabled = not bool(mq["ok"])
		b5.tooltip_text = String(b5.tooltip_text).split("\n")[0] + "\n" + ("Противник согласится." if bool(mq["ok"]) else String(mq["why"]))
	(war_btn["propose"] as Button).disabled = String(q["why"]) != ""
	var cf_on: bool = int(w.get("cf", 0)) > 0
	(war_btn["cf"] as Button).visible = not cf_on
	(war_btn["cf"] as Button).disabled = talk_ceasefire_check() != ""
	(war_btn["cf"] as Button).tooltip_text = String((war_btn["cf"] as Button).tooltip_text).split("\n")[0] + ("\n" + talk_ceasefire_check() if talk_ceasefire_check() != "" else "")
	(war_btn["cf_break"] as Button).visible = cf_on
	(war_btn["med"] as Button).disabled = String(w.get("med", "")) != "" or capital < 3.0
	war_intl_rt.text = war_intl_text()


func on_war_peace(kind: String) -> void:
	var r := mil_peace_propose(kind)
	war_msg = String(r["msg"])
	refresh()


func war_select(id: int) -> void:
	mil["sel"] = id
	refresh()
	if map_ctl != null:
		map_ctl.queue_redraw()


func update_war_windows() -> void:
	if war_army_rt == null or current_desk != 13 or not mil_on():
		if war_army_rt != null and not mil_on():
			war_army_rt.text = "Армии нет."
		return
	var t := mil_status_text() + "\n"
	t += "Расходы на армию: [b]%.1f%%[/b] ВВП (на старте %.1f%%). Больше расходов — больше войск можно содержать и выше выучка.\n" % [float(pol["army"]), float(pol_def["army"])]
	if not (mil["rec"] as Array).is_empty():
		var parts: PackedStringArray = []
		for r in mil["rec"]:
			parts.append("%.0f тыс. через %d сут." % [float(r["str"]), int(r["days"])])
		t += "Формируются: %s\n" % ", ".join(parts)
	if int(mil["mob_t"]) > 0:
		t += "Резервисты прибудут через [b]%d[/b] сут. (%.0f тыс.)\n" % [int(mil["mob_t"]), float(mil["mob_k"])]
	if mil_mob_k() > 0.0:
		t += "Мобилизовано %.0f тыс.: рост %+.2f п.п., безработица %+.2f п.п.\n" % [mil_mob_k(), mil_mob_g(), mil_unemp()]
	if war_msg != "":
		t += "[color=%s]%s[/color]" % [COL_WARN, war_msg]
	war_army_rt.text = t
	(war_btn["rec"] as Button).disabled = mil_recruit_check() != "" and not mil_at_war()
	(war_btn["rec"] as Button).tooltip_text = "Сформировать соединение за 90 суток.\n" + mil_recruit_check()
	for lv in 3:
		var b: Button = war_btn["mob%d" % lv]
		b.set_pressed_no_signal(int(mil["mob"]) == lv)
		b.disabled = lv != int(mil["mob"]) and mil_mob_check(lv) != ""
	# список соединений
	var mine := mil_units_of(ccode)
	var key := ""
	for f in mine:
		key += "%d," % int(f["id"])
	if key != war_list_key:
		war_list_key = key
		for ch in war_list.get_children():
			ch.queue_free()
		for f in mine:
			var b2 := Button.new()
			b2.theme_type_variation = "SmallButton"
			b2.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b2.toggle_mode = true
			b2.focus_mode = Control.FOCUS_NONE
			b2.clip_text = true
			b2.custom_minimum_size = Vector2(40.0, 0.0)
			b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b2.set_meta("id", int(f["id"]))
			b2.pressed.connect(war_select.bind(int(f["id"])))
			war_list.add_child(b2)
	var sel: int = int(mil.get("sel", -1))
	for b3 in war_list.get_children():
		var f2 := mil_unit(int((b3 as Button).get_meta("id")))
		if f2.is_empty():
			continue
		var where := "в море" if int(f2["a"]) < 0 else ate_name(int(f2["a"]))
		var st := "бой" if int(f2["fight"]) >= 0 else ("идёт" if not (f2["path"] as Array).is_empty() else ("наступает" if String(f2["mode"]) == "auto" else ("обороняет" if String(f2["mode"]) == "def" else "стоит")))
		(b3 as Button).text = "%s · %.1f тыс. · %s · %s" % [String(f2["nm"]), float(f2["str"]), where, st]
		(b3 as Button).set_pressed_no_signal(int(f2["id"]) == sel)
	var fs := mil_unit(sel)
	if fs.is_empty() or String(fs["cc"]) != ccode:
		war_unit_rt.text = "Не выбрано. Щёлкните по соединению в списке или по его значку на карте."
	else:
		var u := "[b]%s[/b]: %.1f из %.1f тыс., боеспособность %.0f%%, выучка %.2f\n" % [String(fs["nm"]), float(fs["str"]), float(fs["max"]), float(fs["org"]) * 100.0, float(fs["q"])]
		u += "Где: %s" % ("в море, высадка через %d сут." % int(fs["sea"].get("days", 0)) if int(fs["a"]) < 0 else ate_name(int(fs["a"])))
		if not (fs["path"] as Array).is_empty():
			u += " → %s (%d АТЕ)" % [ate_name(int(fs["path"][-1])), (fs["path"] as Array).size()]
		if int(fs["fight"]) >= 0:
			u += "\n[color=%s]Ведёт бой за «%s»[/color]" % [COL_WARN, ate_name(int(fs["fight"]))]
		war_unit_rt.text = u
	for k in ["hold", "def", "auto"]:
		(war_btn[k] as Button).disabled = fs.is_empty()
	# война и мир
	var o := ""
	war_btn["declare"].visible = not mil_at_war()
	war_tgt.visible = not mil_at_war()
	update_war_talk()
	if not mil_at_war():
		var ts := mil_targets()
		if ts != war_tgt_ids:
			war_tgt_ids = ts
			war_tgt.clear()
			for c in ts:
				war_tgt.add_item(String(WORLD[c]["name"]))
		var ci: int = war_tgt.selected
		o += "[b]Мир.[/b] Войн проведено: %d.\n" % int(mil["wars"])
		o += war_intl_text()
		if not (mil["last"] as Dictionary).is_empty():
			o += "Последняя война: %s\n" % String(mil["last"]["msg"])
		if ci >= 0 and ci < war_tgt_ids.size():
			var c2 := String(war_tgt_ids[ci])
			var b4: Array = MIL_BASE.get(c2, [0.0, 0.0, 1.0])
			o += "\n[b]%s[/b]: армия ≈ %.0f тыс. (боевых %.0f), резерв %.0f тыс., выучка %.2f. Ваша боевая армия %.0f тыс.\n" % [String(WORLD[c2]["name"]), float(b4[0]), float(b4[0]) * MIL_COMBAT * float((mil["loss"] as Dictionary).get(c2, 1.0)), float(b4[1]), float(b4[2]), mil_total(ccode)]
			o += "Отношения: %.0f. %s%s\n" % [fed_rel(c2), "Общая граница по суше." if mil_land_neighbor(c2) else "Только по морю (нужен десант).", " Член НАТО." if c2 in MIL_NATO else ""]
			var al := mil_allies_for(c2, ccode)
			if not al.is_empty():
				var nms: PackedStringArray = []
				for a in al:
					nms.append(String(WORLD[a]["name"]))
				o += "[color=%s]На её сторону встанут: %s.[/color]\n" % [COL_BAD, ", ".join(nms)]
			o += war_vote_text(c2) + "\n"
			o += war_preview_text(c2) + "\n"
			var why := mil_declare_check(c2)
			if why != "":
				o += "[color=%s]%s[/color]\n" % [COL_DIM, why]
			(war_btn["declare"] as Button).disabled = why != ""
		else:
			(war_btn["declare"] as Button).disabled = true
			if war_tgt_ids.is_empty():
				o += "Воевать не с кем: нет соседей."
	else:
		var w: Dictionary = mil["war"]
		var sc: float = float(w["score"])
		o += "[b]Война со страной «%s»[/b], %d сут.\n" % [String(WORLD[String(w["lead"])]["name"]), int(w["days"])]
		var foes := mil_side_ccs(1)
		var fr := mil_side_ccs(0)
		if foes.size() > 1 or fr.size() > 1:
			var f1: PackedStringArray = []
			for c in foes:
				f1.append(String(WORLD[c]["name"]))
			o += "Противники: %s\n" % ", ".join(f1)
			if fr.size() > 1:
				var f0: PackedStringArray = []
				for c in fr:
					if c != ccode:
						f0.append(String(WORLD[c]["name"]))
				o += "Союзники: %s\n" % ", ".join(f0)
		o += "Военный счёт: [b][color=%s]%+.0f[/color][/b] (от −100 до +100)\n" % [COL_GOOD if sc > 0.0 else (COL_BAD if sc < 0.0 else COL_DIM), sc]
		o += "Занято у противника: [b]%.1f%%[/b] населения%s\n" % [float(w["occ"][1]) * 100.0, " · столица взята!" if mil_cap_held(String(w["lead"])) else ""]
		o += "Противник занял у вас: [b]%.1f%%[/b]%s\n" % [float(w["occ"][0]) * 100.0, " · [color=%s]столица у противника![/color]" % COL_BAD if mil_cap_held(ccode) else ""]
		o += "Силы: ваши %.0f тыс., противника %.0f тыс.\n" % [mil_total(ccode), mil_side_total(1)]
		o += "Потери: ваши ≈ %.1f тыс., противника ≈ %.1f тыс. · бои: %d побед, %d поражений\n" % [float(w["kia"][0]), float(w["kia"][1]), int(w["won"]), int(w["lost"])]
		if int(w.get("cf", 0)) > 0:
			o += "[color=%s]Перемирие: ещё %d сут.[/color]\n" % [COL_GOOD, int(w["cf"])]
		if bool(w["sanct"]):
			o += "[color=%s]Санкции ЕС: рост −1,2 п.п.[/color]\n" % COL_BAD
		o += "Война стоит: рост %+.1f п.п., инфляция %+.1f п.п., долг +%.1f млрд/мес.\n" % [mil_g(), mil_infl(), gdp * 0.0025 + mil_total(ccode) * 0.004]
	if war_msg != "" and current_desk == 13:
		o += "\n[color=%s]%s[/color]" % [COL_WARN, war_msg]
	war_ops_rt.text = o
	var lg: Array = mil["log"]
	var lt := ""
	for k in range(lg.size() - 1, maxi(-1, lg.size() - 14), -1):
		lt += str(lg[k]) + "\n"
	war_log_rt.text = lt if lt != "" else "Пока тихо."


func mil_side_total(side: int) -> float:
	var s := 0.0
	for f in mil.get("units", []):
		if mil_side(String(f["cc"])) == side:
			s += float(f["str"])
	return s


# ---------- карта ----------


func war_map_on() -> bool:
	return mil_on() and (current_desk == 13 or current_desk == 14 or mil_at_war())


func war_occ_build() -> void:
	if war_occ_ver == int(mil.get("ctl_ver", 0)) + 100000 * int(mil.get("wars", 0)) and map_ate_tris.size() == ate_n:
		return
	war_occ_ver = int(mil.get("ctl_ver", 0)) + 100000 * int(mil.get("wars", 0))
	war_occ_tris = [PackedVector2Array(), PackedVector2Array()]
	war_front = PackedVector2Array()
	if not mil_at_war() or map_ate_tris.size() != ate_n:
		return
	for a in mil["ctl"]:
		var sd := mil_side(String(mil["ctl"][a]))
		if sd >= 0:
			(war_occ_tris[sd] as PackedVector2Array).append_array(map_ate_tris[int(a)])
	# линия фронта: рёбра между АТЕ, которые держат разные стороны
	var ea: PackedInt32Array = ATE["ea"]
	var eb: PackedInt32Array = ATE["eb"]
	var eo: PackedInt32Array = ATE["eo"]
	var ep: PackedFloat32Array = ATE["ep"]
	mil_idx()
	for e in ea.size():
		if eb[e] < 0:
			continue
		var s1: int = mil_cs[ea[e]]
		var s2: int = mil_cs[eb[e]]
		if s1 < 0 or s2 < 0 or s1 == s2:
			continue
		for k in range(eo[e], eo[e + 1] - 1):
			war_front.append(Vector2(ep[2 * k], ep[2 * k + 1]))
			war_front.append(Vector2(ep[2 * k + 2], ep[2 * k + 3]))


# под преобразованием карты (координаты карты)
func draw_war_overlay(c: Control, ci: RID, s: float) -> void:
	if not mil_on():
		return
	if mil_at_war():
		war_occ_build()
		for sd in 2:
			var tr: PackedVector2Array = war_occ_tris[sd]
			if not tr.is_empty():
				var col: Color = WAR_C0 if sd == 0 else WAR_C1
				RenderingServer.canvas_item_add_triangle_array(ci, PackedInt32Array(), tr, PackedColorArray([Color(col.r, col.g, col.b, 0.38)]))
		if not war_front.is_empty():
			c.draw_multiline(war_front, Color(0, 0, 0, 0.6), 4.0 / s)
			c.draw_multiline(war_front, Color(1.0, 0.85, 0.3, 1.0), 2.0 / s)
	if current_desk == 13 and map_hover_ate >= 0 and map_hover_ate < map_ate_tris.size():
		RenderingServer.canvas_item_add_triangle_array(ci, PackedInt32Array(), map_ate_tris[map_hover_ate], PackedColorArray([Color(1, 1, 1, 0.25)]))
	# путь выбранного соединения
	var f := mil_unit(int(mil.get("sel", -1)))
	if current_desk == 13 and not f.is_empty() and int(f["a"]) >= 0 and not (f["path"] as Array).is_empty():
		var pts := PackedVector2Array([ate_c[int(f["a"])]])
		for a in f["path"]:
			pts.append(ate_c[int(a)])
		c.draw_polyline(pts, Color(1, 1, 1, 0.9), 2.0 / s)


func war_token_pos(a: int, s: float, off: Vector2) -> Vector2:
	return ate_c[a] * s + off


# поверх карты (экранные координаты)
func draw_war_tokens(c: Control, s: float, off: Vector2, font: Font) -> void:
	if not mil_on():
		return
	if current_desk == 14 or (current_desk == 13 and flt_has_sea()):
		draw_sea_lanes(c, s, off, font)
	if not (current_desk == 13 or current_desk == 2 and mil_at_war() or current_desk == 14 and mil_at_war()):
		return
	var by := {}
	for f in mil["units"]:
		var a: int = int(f["a"])
		if a < 0:
			continue
		if not by.has(a):
			by[a] = []
		(by[a] as Array).append(f)
	var sel: int = int(mil.get("sel", -1))
	var r := Rect2(Vector2.ZERO, c.size)
	for a in by:
		var p := war_token_pos(int(a), s, off)
		if not r.has_point(p):
			continue
		var lst: Array = by[a]
		var tot := 0.0
		var sd := mil_side(String(lst[0]["cc"]))
		var is_sel := false
		var fighting := false
		for f in lst:
			tot += float(f["str"])
			if int(f["id"]) == sel:
				is_sel = true
			if int(f["fight"]) >= 0:
				fighting = true
		var col: Color = WAR_C0 if sd == 0 else WAR_C1
		if String(lst[0]["cc"]) != ccode and sd == 0:
			col = col.lerp(Color(0.5, 0.9, 1.0), 0.5)
		var bw := 26.0
		var bh := 16.0
		var rr := Rect2(p - Vector2(bw, bh) * 0.5, Vector2(bw, bh))
		c.draw_rect(rr.grow(1.5), Color(0, 0, 0, 0.85))
		c.draw_rect(rr, col.darkened(0.25))
		# знак пехоты: крест в рамке
		c.draw_line(rr.position + Vector2(2, 2), rr.end - Vector2(2, 2), Color(1, 1, 1, 0.55), 1.0)
		c.draw_line(Vector2(rr.position.x + 2, rr.end.y - 2), Vector2(rr.end.x - 2, rr.position.y + 2), Color(1, 1, 1, 0.55), 1.0)
		var txt := "%.0f" % tot if tot >= 1.0 else "<1"
		if lst.size() > 1:
			txt = "%d×%s" % [lst.size(), txt]
		c.draw_string_outline(font, rr.position + Vector2(0, 12), txt, HORIZONTAL_ALIGNMENT_CENTER, bw, 10, 3, Color(0, 0, 0, 0.9))
		c.draw_string(font, rr.position + Vector2(0, 12), txt, HORIZONTAL_ALIGNMENT_CENTER, bw, 10, Color.WHITE)
		if is_sel:
			c.draw_rect(rr.grow(3.0), Color(1, 0.92, 0.4), false, 2.0)
		if fighting:
			c.draw_circle(rr.end + Vector2(1, -bh), 4.0, Color(1, 0.8, 0.2))
	# десанты в пути
	for f in mil["units"]:
		if int(f["a"]) >= 0 or (f["sea"] as Dictionary).is_empty():
			continue
		var p2 := war_token_pos(int(f["sea"]["to"]), s, off) + Vector2(0, -18)
		c.draw_circle(p2, 7.0, Color(0, 0, 0, 0.8))
		c.draw_circle(p2, 5.0, WAR_C0)
		c.draw_string(font, p2 + Vector2(8, 4), "десант %d сут." % int(f["sea"]["days"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)


func draw_sea_lanes(c: Control, s: float, off: Vector2, font: Font) -> void:
	if not flt_has_sea():
		return
	for e in fleet_lane_edges():
		var a: Vector2 = (e[0] as Vector2) * s + off
		var b: Vector2 = (e[1] as Vector2) * s + off
		var wd: float = 1.0 + 4.0 * float(e[2])
		var col := Color(0.35, 0.80, 0.78, 0.55) if float(e[3]) <= 0.0 else Color(1.0, 0.35, 0.3, 0.85)
		c.draw_line(a, b, col, wd)
	var st := String(mil.get("nav", {}).get("station", ""))
	for nid in flt_nodes:
		var n: Dictionary = flt_nodes[nid]
		var p := Vector2(float(n["x"]), float(n["y"])) * s + off
		var inc: bool = (flt["inc"] as Dictionary).has(nid)
		c.draw_circle(p, 5.0, Color(0, 0, 0, 0.7))
		c.draw_circle(p, 3.5, Color(1.0, 0.35, 0.3) if inc else Color(0.6, 0.85, 0.95))
		if s >= 1.2:
			c.draw_string_outline(font, p + Vector2(7, 4), String(n["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, Color(0, 0, 0, 0.85))
			c.draw_string(font, p + Vector2(7, 4), String(n["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.75, 0.9, 1.0))
	for p0 in flt_ports_of(ccode):
		var pp := Vector2(float(p0["x"]), float(p0["y"])) * s + off
		var u := fleet_port_util(String(p0["id"])) if (flt["ports"] as Dictionary).has(String(p0["id"])) else 0.5
		var pc := C_GOOD if u < 0.9 else (C_WARN if u < 1.0 else C_BAD)
		c.draw_rect(Rect2(pp - Vector2(4, 4), Vector2(8, 8)), Color(0, 0, 0, 0.8))
		c.draw_rect(Rect2(pp - Vector2(3, 3), Vector2(6, 6)), pc)
	# эскадры
	if flt_nodes.has(st) and fleet_power() > 0.0:
		var sp := Vector2(float(flt_nodes[st]["x"]), float(flt_nodes[st]["y"])) * s + off
		war_ship(c, sp + Vector2(-10, -12), WAR_C0, "%.0f" % fleet_power(), font)
	if mil_at_war():
		for cc in mil["war"]["nv"]:
			var e2: Dictionary = mil["war"]["nv"][cc]
			if float(e2["pow"]) <= 0.5 or not flt_nodes.has(String(e2["node"])):
				continue
			var ep2 := Vector2(float(flt_nodes[String(e2["node"])]["x"]), float(flt_nodes[String(e2["node"])]["y"])) * s + off
			war_ship(c, ep2 + Vector2(10, -12), WAR_C1, "%.0f" % float(e2["pow"]), font)


func war_ship(c: Control, p: Vector2, col: Color, txt: String, font: Font) -> void:
	var hull := PackedVector2Array([p + Vector2(-11, -2), p + Vector2(11, -2), p + Vector2(7, 4), p + Vector2(-7, 4)])
	c.draw_colored_polygon(hull, col)
	c.draw_polyline(PackedVector2Array([hull[0], hull[1], hull[2], hull[3], hull[0]]), Color(0, 0, 0, 0.9), 1.0)
	c.draw_rect(Rect2(p + Vector2(-3, -7), Vector2(6, 5)), col.lightened(0.2))
	c.draw_string_outline(font, p + Vector2(-20, 16), txt, HORIZONTAL_ALIGNMENT_CENTER, 40, 10, 3, Color(0, 0, 0, 0.9))
	c.draw_string(font, p + Vector2(-20, 16), txt, HORIZONTAL_ALIGNMENT_CENTER, 40, 10, Color.WHITE)


func war_token_at(pos: Vector2) -> int:
	# соединение под курсором: возвращает id (своё — в приоритете)
	if not mil_on():
		return -1
	var v := map_view()
	var s: float = v[0]
	var off: Vector2 = v[1]
	var best := -1
	var bd := 15.0 * 15.0
	for f in mil["units"]:
		if int(f["a"]) < 0:
			continue
		var d: float = war_token_pos(int(f["a"]), s, off).distance_squared_to(pos)
		if String(f["cc"]) == ccode:
			d *= 0.5
		if d < bd:
			bd = d
			best = int(f["id"])
	return best


func war_node_at(pos: Vector2) -> String:
	var v := map_view()
	var s: float = v[0]
	var off: Vector2 = v[1]
	for nid in flt_nodes:
		var n: Dictionary = flt_nodes[nid]
		if (Vector2(float(n["x"]), float(n["y"])) * s + off).distance_to(pos) <= 9.0:
			return String(nid)
	return ""


func war_map_click(pos: Vector2, shift: bool) -> void:
	if current_desk == 14:
		var nid := war_node_at(pos)
		if nid != "" and flt_has_sea() and not bool(flt["land"]):
			mil_nav_station_set(nid)
			refresh()
			map_ctl.queue_redraw()
		return
	var tk := war_token_at(pos)
	var fsel := mil_unit(int(mil.get("sel", -1)))
	if tk >= 0 and String(mil_unit(tk)["cc"]) == ccode and (fsel.is_empty() or tk != int(fsel["id"])):
		war_select(tk)
		return
	var a := ate_at(pos)
	if a < 0 or fsel.is_empty() or String(fsel["cc"]) != ccode:
		if tk >= 0:
			war_select(tk)
		return
	if shift:
		war_msg = mil_land_order(int(fsel["id"]), a)
	else:
		war_msg = mil_order_move(int(fsel["id"]), a)
	refresh()
	map_ctl.queue_redraw()


func war_tip(a: int) -> String:
	if a < 0:
		return ""
	var ow := ate_cc(a)
	var t := "%s — %s" % [ate_name(a), String(WORLD[ow]["name"]) if WORLD.has(ow) else ow]
	var ct := mil_ctl(a)
	if ct != ow:
		t += "\n[занято: %s]" % (String(WORLD[ct]["name"]) if WORLD.has(ct) else ct)
	t += "\nНаселение ≈ %s" % fmt_people(ate_pop(a))
	for f in mil_units_at(a):
		t += "\n%s (%s): %.1f тыс., боеспособность %.0f%%" % [String(f["nm"]), String(WORLD[String(f["cc"])]["name"]), float(f["str"]), float(f["org"]) * 100.0]
	mil_coast_build()
	if mil_coast.has(a):
		t += "\nПобережье (морской район «%s»)" % String(flt_nodes[String(mil_coast[a])]["name"])
	var fs := mil_unit(int(mil.get("sel", -1)))
	if not fs.is_empty() and current_desk == 13:
		t += "\nЩелчок — отправить «%s» сюда" % String(fs["nm"])
	return t


func war_hover(pos: Vector2) -> void:
	var a := ate_at(pos)
	var tk := war_token_at(pos)
	if a != map_hover_ate or tk != war_hover_tok:
		map_hover_ate = a
		war_hover_tok = tk
		map_ctl.tooltip_text = war_tip(a)
		if current_desk == 14:
			var nid := war_node_at(pos)
			if nid != "":
				map_ctl.tooltip_text = "%s\nЩелчок — поставить эскадру сюда." % String(flt_nodes[nid]["name"])
		map_ctl.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if (tk >= 0 or a >= 0) else Control.CURSOR_ARROW
		map_ctl.queue_redraw()
