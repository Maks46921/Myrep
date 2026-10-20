# Интерфейс: оппозиция и переговоры между партиями (экран «Политика»).
extends "res://scripts/ui/ui_realm.gd"

var opp_rt: RichTextLabel
var opp_btns := {}
var pact_rt: RichTextLabel
var pact_opt: OptionButton
var pact_btns := {}
var pact_sel := 1
var bill_rt: RichTextLabel
var bill_acc: Button
var bill_rej: Button
var bill_am := {}
var rider_kind: OptionButton = null
var rider_arg: OptionButton = null
var rider_btn: Button = null
var rider_args: Array = []


func build_opp_windows() -> void:
	var w: FloatWindow = new_window("opp", "Оппозиция и власть", 12, Rect2(0.0, 0.0, 0.35, 1.0))
	opp_rt = make_rt(w.body)
	for a in OPP_ACTS:
		var b := fed_btn("%s (капитал %.0f)" % [a["name"], a["cap"]], w.body, String(a["desc"]))
		b.pressed.connect(on_opp_act.bind(String(a["id"])))
		opp_btns[String(a["id"])] = b
	add_note(w.body, "Оппозиция не управляет бюджетом и министерствами: их ведёт правительство. Ваше оружие — критика, расследования, вотум недоверия, досрочные выборы и поиск союзников. На выборах ваша партия получает обратную часть недовольства властью.", true)

	w = new_window("pacts", "Переговоры и соглашения партий", 12, Rect2(0.35, 0.0, 0.355, 1.0))
	pact_opt = fed_opt(w.body, [], "Выберите партию для переговоров.")
	pact_opt.item_selected.connect(on_pact_party)
	pact_rt = make_rt(w.body)
	var cls_names := {"friend": "Дружеские действия", "support": "Поддержка и союзы", "hostile": "Враждебные действия"}
	for cls in ["friend", "support", "hostile"]:
		var hl := Label.new()
		hl.text = cls_names[cls]
		hl.add_theme_color_override("font_color", C_DIM)
		hl.add_theme_font_size_override("font_size", 13)
		w.body.add_child(hl)
		for k in PACT_KINDS:
			if String(k["cls"]) != cls:
				continue
			var b2 := fed_btn("%s (капитал %.0f)" % [k["name"], k["cap"]], w.body, String(k["desc"]))
			b2.pressed.connect(on_pact_do.bind(String(k["id"])))
			pact_btns[String(k["id"])] = b2

	# ---- законопроекты (экран «Законы») ----
	# 0.57.1: карточки вместо списка. Сверху те, что ждут вашего решения, остальные — по срокам и свёрнуты.
	w = new_window("bills", "Законопроекты и поправки", 3, Rect2(0.48, 0.22, 0.222, 0.58))
	var srow := HBoxContainer.new()
	srow.add_theme_constant_override("separation", 6)
	w.body.add_child(srow)
	var sl := Label.new()
	sl.text = "Сорт.:"
	sl.add_theme_color_override("font_color", C_DIM)
	srow.add_child(sl)
	var sg_group := ButtonGroup.new()
	for si in 2:
		var sb := Button.new()
		sb.theme_type_variation = "SmallButton"
		sb.toggle_mode = true
		sb.button_group = sg_group
		sb.focus_mode = Control.FOCUS_NONE
		sb.text = ["По сроку", "По важности"][si]
		sb.tooltip_text = ["Ближайший срок первым", "Сначала те, что требуют вашего решения"][si]
		sb.button_pressed = si == bill_sort
		var sidx := si
		sb.pressed.connect(func() -> void:
			bill_sort = sidx
			bill_sig = ""
			refresh())
		srow.add_child(sb)
	bill_att_title = add_title(w.body, "Ждут вашего решения")
	bill_att_box = VBoxContainer.new()
	bill_att_box.add_theme_constant_override("separation", 6)
	w.body.add_child(bill_att_box)
	bill_rest_btn = Button.new()
	bill_rest_btn.focus_mode = Control.FOCUS_NONE
	bill_rest_btn.toggle_mode = true
	bill_rest_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bill_rest_btn.pressed.connect(func() -> void:
		bill_rest_open = bill_rest_btn.button_pressed
		bill_sig = ""
		refresh())
	w.body.add_child(bill_rest_btn)
	bill_rest_box = VBoxContainer.new()
	bill_rest_box.add_theme_constant_override("separation", 6)
	w.body.add_child(bill_rest_box)
	bill_sel_title = add_title(w.body, "Выбранный законопроект")
	bill_rt = make_rt(w.body)
	bill_veto = fed_btn("Снять с повестки", w.body, "Правительство управляет повесткой: законопроект не будут голосовать. Цена — политкапитал, зависит от силы партии.")
	bill_veto.pressed.connect(func() -> void: pa_veto_bill(bill_sel))
	bill_acc = fed_btn("Принять просьбу о поправке", w.body, "Партия получит уступку и проголосует «за».")
	bill_acc.pressed.connect(on_bill_req.bind(true))
	bill_rej = fed_btn("Отклонить просьбу", w.body, "Отношения с партией ухудшатся.")
	bill_rej.pressed.connect(on_bill_req.bind(false))
	for am in [["soft", "Смягчить закон (сила −0.2)"], ["hard", "Усилить закон (сила +0.2)"], ["sweet", "Компенсации оппонентам (капитал 4)"], ["slow", "Отложить на месяц"], ["withdraw", "Отозвать законопроект"]]:
		var bb := fed_btn(String(am[1]), w.body)
		bb.pressed.connect(on_bill_amend.bind(String(am[0])))
		bill_am[String(am[0])] = bb
	# v50: оговорки — поправки в пользу группы интересов, показателя страны или партии (до 4 в законе)
	add_title(w.body, "Оговорки к закону")
	rider_kind = fed_opt(w.body, ["В пользу группы интересов (капитал 3)", "Улучшить показатель страны (капитал 3)", "Учесть требования партии (капитал 4)"], "Какую оговорку внести.")
	rider_kind.item_selected.connect(func(_i: int) -> void:
		rider_fill()
		refresh())
	rider_arg = fed_opt(w.body, [], "Кому или чему оговорка.")
	rider_btn = fed_btn("Внести оговорку", w.body, "Оговорка привлекает партии, которым дорога эта группа или показатель, а после принятия закона действует сама. Учёт требований партии может оттолкнуть её противников.")
	rider_btn.pressed.connect(on_rider_add)
	rider_fill()
	add_note(w.body, "Закон принимается не сразу: после внесения он идёт через парламент несколько месяцев. Партии присылают просьбы о поправках — вы можете принять их (цена — капитал, смягчение) или внести свои.", true)
	add_note(w.body, "Соглашения действуют и во власти, и в оппозиции: «поддержка» делает партию терпимой к правительству, «блок» добавляет голосов обеим на выборах, «союз по голосованию» помогает проводить законы.", true)


var bill_veto: Button = null
var bill_sort := 1                 # 0 по сроку, 1 сначала требующие решения
var bill_rest_open := false
var bill_sig := ""
var bill_att_title: Label = null
var bill_att_box: VBoxContainer = null
var bill_rest_btn: Button = null
var bill_rest_box: VBoxContainer = null
var bill_sel_title: Label = null


func on_bill_req(acc: bool) -> void:
	var bi := bill_index(bill_sel)
	if bi < 0:
		return
	var reqs: Array = bills[bi]["req"]
	for i in reqs.size():
		if int(reqs[i]["state"]) == 0:
			bill_request(bill_sel, i, acc)
			return


func on_bill_amend(kind: String) -> void:
	bill_amend(bill_sel, kind)


func rider_fill() -> void:
	if rider_arg == null:
		return
	rider_arg.clear()
	rider_args.clear()
	match rider_kind.selected:
		0:
			for g in GROUPS:
				rider_arg.add_item(g)
				rider_args.append(["group", g])
		1:
			for k in RIDER_CHARS:
				rider_arg.add_item(String(RIDER_CHARS[k][0]))
				rider_args.append(["char", k])
		_:
			for p in range(1, PARTY_NAMES.size()):
				if seats[p] > 0 and not (p in NO_GOV_SLOTS):
					rider_arg.add_item(party_abbr(p) + " — " + String(PARTY_NAMES[p]).left(40))
					rider_args.append(["party", str(p)])


func on_rider_add() -> void:
	var i := rider_arg.selected
	if i < 0 or i >= rider_args.size():
		return
	bill_rider_add(bill_sel, String(rider_args[i][0]), String(rider_args[i][1]))


func update_bill_window() -> void:
	if bill_att_box == null:
		return
	if bill_index(bill_sel) < 0 and bills.size() > 0:
		var att0 := bills_attention()
		bill_sel = int(att0[0]["id"]) if att0.size() > 0 else int(bills[0]["id"])
	var att := bills_attention()
	var att_ids := {}
	for a in att:
		att_ids[int(a["id"])] = a
	# перестраиваем карточки только если что-то изменилось
	var sig: PackedStringArray = ["%d|%s|%d|%d|%s" % [bill_sort, str(bill_rest_open), bill_sel, turn, str(game_over)]]
	for b in bills:
		var rs := ""
		for r in b["req"]:
			rs += str(int(r["state"]))
		sig.append("%d,%d,%s,%s,%.1f,%s,%d,%d" % [int(b["id"]), int(b["due"]), String(b.get("pv", "line")), rs, float(b["pow"]), str(att_ids.has(int(b["id"]))), int(bill_preview(b)["yes"]), (b["forced"] as Array).size()])
	var sg_now := ";".join(sig)
	if sg_now != bill_sig:
		bill_sig = sg_now
		bill_cards_build(att_ids)
	var bi := bill_index(bill_sel)
	bill_sel_title.visible = bi >= 0
	bill_rt.visible = bi >= 0
	for k in bill_am:
		var bt: Button = bill_am[k]
		bt.disabled = bi < 0 or int(bills[bi]["sponsor"]) != 0 or game_over
		if not bt.disabled and k in ["soft", "hard"]:
			var why := bill_pow_block(bills[bi], String(k))
			bt.disabled = why != ""
			bt.tooltip_text = loc(why if why != "" else ("Сила −0.2: слабее эффекты, но закон приемлем для большего числа партий." if k == "soft" else "Сила +0.2: сильнее эффекты, но часть колеблющихся партий будет против."))
	bill_acc.disabled = true
	bill_rej.disabled = true
	var foreign: bool = bi >= 0 and int(bills[bi]["sponsor"]) != 0
	bill_veto.visible = foreign and bool(bills[bi].get("pa", false)) and not opp_mode
	if foreign:
		var vc := pa_veto_cost(int(bills[bi]["sponsor"]))
		bill_veto.text = loc("Снять с повестки (политкапитал −%.0f)" % vc)
		bill_veto.disabled = game_over or cap_spendable() < vc
	if bi < 0:
		return
	var b: Dictionary = bills[bi]
	var v := bill_preview(b)
	var t := "[b]%s[/b] → %s
" % [law_index[b["tid"]]["name"], variant_of(b["tid"], int(b["idx"]))["n"]]
	if int(b["sponsor"]) != 0:
		var lyes := pa_line(b)
		t += "Внесла: [b]%s[/b]. Линия вашей партии: [b]%s[/b]. Ваша фракция: [b]%s[/b].
" % [PARTY_NAMES[int(b["sponsor"])], "за" if lyes else "против", PA_VOTE_NAMES.get(String(b.get("pv", "line")), "по линии партии")]
	t += "Голосование через %d мес. Сейчас «за» %d из нужных %d.
" % [maxi(0, int(b["due"]) - turn), int(v["yes"]), law_need(String(b["tid"]), v)]
	if is_hybrid(String(b["tid"])):
		t += "Сила действия: %.1f×
" % float(b["pow"])
	var pend := false
	for r in b["req"]:
		var st := int(r["state"])
		t += "• %s %s
" % [String(r["txt"]), "[color=%s](принято)[/color]" % COL_GOOD if st == 1 else ("[color=%s](отклонено)[/color]" % COL_BAD if st == 2 else "")]
		if st == 0:
			pend = true
	var rl: Array = b.get("riders", [])
	if rl.size() > 0:
		var rt: PackedStringArray = []
		for r in rl:
			rt.append(String(r["t"]))
		t += "Оговорки: %s\n" % ", ".join(rt)
	bill_rt.text = loc(t)
	if rider_btn != null:
		var ai := rider_arg.selected
		var why2 := bill_rider_check(b, String(rider_args[ai][0]), String(rider_args[ai][1])) if ai >= 0 and ai < rider_args.size() else "выберите"
		rider_btn.disabled = why2 != "" or game_over
		rider_btn.tooltip_text = why2 if why2 != "" else "Оговорка привлекает партии, которым дорога эта группа или показатель, а после принятия закона действует сама."
	if int(b["sponsor"]) == 0:
		bill_acc.disabled = not pend or game_over
		bill_rej.disabled = not pend or game_over


# карточки законопроектов: сверху те, что ждут решения, остальные по срокам и свёрнуты
func bill_cards_build(att_ids: Dictionary) -> void:
	for c in bill_att_box.get_children():
		c.queue_free()
	for c in bill_rest_box.get_children():
		c.queue_free()
	var wait: Array = []
	var rest: Array = []
	for b in bills:
		if att_ids.has(int(b["id"])):
			wait.append(b)
		else:
			rest.append(b)
	var by_due := func(x, y): return int(x["due"]) < int(y["due"]) or (int(x["due"]) == int(y["due"]) and int(x["id"]) < int(y["id"]))
	var by_att := func(x, y):
		var ax: Dictionary = att_ids[int(x["id"])]
		var ay: Dictionary = att_ids[int(y["id"])]
		return int(ax["sev"]) > int(ay["sev"]) or (int(ax["sev"]) == int(ay["sev"]) and int(x["due"]) < int(y["due"]))
	wait.sort_custom(by_att if bill_sort == 1 else by_due)
	rest.sort_custom(by_due)
	bill_att_title.visible = wait.size() > 0
	bill_att_box.visible = wait.size() > 0
	for b in wait:
		bill_att_box.add_child(bill_make_card(b, att_ids[int(b["id"])]))
	if bills.is_empty():
		bill_att_title.visible = true
		bill_att_title.text = loc("Законопроектов в работе нет")
		var l := Label.new()
		l.text = loc("Выберите закон слева и нажмите «Внести законопроект» — он пройдёт через парламент за несколько месяцев.")
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_color_override("font_color", C_DIM)
		bill_att_box.visible = true
		bill_att_box.add_child(l)
	else:
		bill_att_title.text = loc("Ждут вашего решения")
	bill_rest_btn.visible = rest.size() > 0
	bill_rest_btn.set_pressed_no_signal(bill_rest_open)
	bill_rest_btn.text = loc("%s Остальные законопроекты: %d (по срокам)" % ["▾" if bill_rest_open else "▸", rest.size()])
	bill_rest_box.visible = bill_rest_open and rest.size() > 0
	if bill_rest_open:
		var last_grp := -1
		for b in rest:
			var left := maxi(0, int(b["due"]) - turn)
			var grp: int = 0 if left <= 0 else (1 if left <= 2 else 2)
			if grp != last_grp:
				last_grp = grp
				var gl := Label.new()
				gl.text = loc(["В этом месяце", "Через 1–2 месяца", "Позже"][grp])
				gl.add_theme_color_override("font_color", C_DIM)
				gl.add_theme_font_size_override("font_size", 13)
				bill_rest_box.add_child(gl)
			bill_rest_box.add_child(bill_make_card(b, {}))


func bill_card_btn(text: String, parent: Control, cb: Callable, tip: String = "", disabled: bool = false) -> Button:
	var bt := Button.new()
	bt.theme_type_variation = "SmallButton"
	bt.focus_mode = Control.FOCUS_NONE
	bt.text = loc(text)
	bt.tooltip_text = loc(tip)
	bt.disabled = disabled or game_over
	bt.pressed.connect(cb)
	parent.add_child(bt)
	return bt


func bill_make_card(b: Dictionary, att: Dictionary) -> PanelContainer:
	var bid: int = int(b["id"])
	var tid: String = String(b["tid"])
	var sp: int = int(b["sponsor"])
	var pv0: Dictionary = bill_preview(b)
	var need: int = law_need(tid, pv0)
	var yes: int = int(pv0["yes"])
	var left: int = maxi(0, int(b["due"]) - turn)
	var pc := PanelContainer.new()
	var border: Color = C_WARN if not att.is_empty() else C_PANEL2.lightened(0.18)
	pc.add_theme_stylebox_override("panel", sbox(C_PANEL2.lerp(C_ACCENT, 0.10) if bid == bill_sel else C_PANEL2, border, 2 if (bid == bill_sel or not att.is_empty()) else 1, 8, 8.0, 6.0))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	pc.add_child(vb)
	var top := HBoxContainer.new()
	vb.add_child(top)
	var tl := Label.new()
	tl.text = loc("%s → %s" % [String(law_index[tid]["name"]), String(variant_of(tid, int(b["idx"]))["n"])])
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tl.add_theme_font_size_override("font_size", 14)
	top.add_child(tl)
	var spl := Label.new()
	spl.text = loc("ваш законопроект" if sp == 0 else ("внесла: %s" % party_abbr(sp)))
	spl.add_theme_font_size_override("font_size", 12)
	spl.add_theme_color_override("font_color", C_ACCENT if sp == 0 else C_DIM)
	top.add_child(spl)
	var dl := Label.new()
	var dtxt := "голосование в этом месяце" if left <= 0 else ("голосование через %d мес." % left)
	if not att.is_empty():
		dtxt += " · " + String(att["why"])
	dl.text = loc(dtxt)
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.add_theme_font_size_override("font_size", 12)
	dl.add_theme_color_override("font_color", C_WARN if not att.is_empty() else C_DIM)
	vb.add_child(dl)
	var br := HBoxContainer.new()
	br.add_theme_constant_override("separation", 8)
	vb.add_child(br)
	var bar := StatBar.new()
	bar.custom_minimum_size = Vector2(80.0, 12.0)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.marker = float(need) * 100.0 / float(SEATS)
	bar.set_state(float(yes) * 100.0 / float(SEATS), 0.85 if yes >= need else 0.08)
	bar.tooltip_text = loc("Прогноз: «за» %d, нужно %d. Белая черта — порог большинства." % [yes, need])
	br.add_child(bar)
	var nl := Label.new()
	nl.text = loc("за %d / нужно %d" % [yes, need])
	nl.add_theme_font_size_override("font_size", 12)
	nl.add_theme_color_override("font_color", C_GOOD if yes >= need else C_BAD)
	br.add_child(nl)
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 4)
	row.add_theme_constant_override("v_separation", 4)
	vb.add_child(row)
	if sp == 0:
		var ri := -1
		for i in (b["req"] as Array).size():
			if int(b["req"][i]["state"]) == 0:
				ri = i
				break
		if ri >= 0:
			var r: Dictionary = b["req"][ri]
			var rl := Label.new()
			rl.text = loc(String(r["txt"]))
			rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			rl.add_theme_font_size_override("font_size", 12)
			vb.add_child(rl)
			vb.move_child(rl, 2)
			var cst := float(r["cost"])
			bill_card_btn("Принять просьбу%s" % ((" (−%.0f)" % cst) if cst > 0.0 else ""), row, func() -> void: bill_request(bid, ri, true), "Партия получит уступку и проголосует «за».")
			bill_card_btn("Отклонить", row, func() -> void: bill_request(bid, ri, false), "Отношения с партией ухудшатся.")
		for kind in ["soft", "hard"]:
			var kk: String = kind
			var why := bill_pow_block(b, kk)
			bill_card_btn("Смягчить" if kk == "soft" else "Усилить", row, func() -> void: bill_amend(bid, kk), why if why != "" else ("Сила −0.2: приемлемее для большего числа партий." if kk == "soft" else "Сила +0.2: эффекты сильнее, часть партий будет против."), why != "")
		bill_card_btn("Договориться с партиями", row, func() -> void:
			var sw := bill_swing_parties(b)
			if sw.size() > 0:
				pact_sel = int(sw[0])
			show_desk(12)
			refresh(), "Переговоры и соглашения: встречи, поддержка, голоса за закон.")
	else:
		var vg := ButtonGroup.new()
		var cur_pv: String = String(b.get("pv", "line"))
		var can_vote: bool = pl_parl() and seats[0] > 0
		for vk in ["line", "yes", "no", "abst", "free"]:
			var vkk: String = vk
			var vbt := bill_card_btn({"line": "По линии", "yes": "За", "no": "Против", "abst": "Воздержаться", "free": "Свободно"}[vk], row, func() -> void: pa_set_vote(bid, vkk), "Как голосует ваша фракция по этому законопроекту.", not can_vote)
			vbt.toggle_mode = true
			vbt.button_group = vg
			vbt.set_pressed_no_signal(vk == cur_pv)
		bill_card_btn("Переговоры с партией", row, func() -> void:
			pact_sel = sp
			show_desk(12)
			refresh(), "Договориться с внёсшей партией.")
	bill_card_btn("Подробнее ▸", row, func() -> void:
		bill_sel = bid
		bill_sig = ""
		refresh(), "Оговорки, отзыв, вето и сводка по выбранному законопроекту.")
	return pc


func on_opp_act(id: String) -> void:
	opp_act(id)
	refresh()


func on_pact_party(i: int) -> void:
	pact_sel = pact_opt.get_item_id(i)
	refresh()


func on_pact_do(kind: String) -> void:
	pact_do(pact_sel, kind)
	refresh()


# v50: что партия может и чего не может вне власти
func powers_text() -> String:
	var parl := pl_parl()
	var yes: PackedStringArray = ["критиковать правительство и проводить кампании", "договариваться с партиями: встречи, похвала, помощь, предвыборный блок",
		"финансировать партии за рубежом (карта → окно «Страна: сведения»)"]
	var no: PackedStringArray = ["бюджет, налоги и разовые меры", "министры и кабинет", "дипломатия, договоры, санкции и армия", "автопилот, стройка и ремонт"]
	if parl:
		yes.append("вносить законопроекты и поправки, голосовать в парламенте")
		yes.append("соглашения о терпимости и о голосах")
		yes.append("вотум недоверия и сбор альтернативного большинства")
	else:
		no.append("законопроекты и поправки (нет мест в парламенте)")
	return "[b]Ваши полномочия[/b]\n[color=%s]✔ %s[/color]\n[color=%s]✖ %s[/color]" % [COL_GOOD, "\n✔ ".join(yes), COL_DIM, "\n✖ ".join(no)]


func update_opp_windows() -> void:
	if opp_rt == null or prel.is_empty():
		return
	if opp_mode:
		opp_rt.text = loc(opp_status_text() + "\n\n" + powers_text() + "\n\n" + ideology_text())
	else:
		opp_rt.text = loc("[b]Вы в правительстве.[/b] Если вы проиграете выборы или не сможете собрать большинство, игра продолжится в оппозиции.\n\n" + ideology_text())
	for a in OPP_ACTS:
		var id := String(a["id"])
		var b: Button = opp_btns[id]
		var cd := cd_left(id)
		var txt := "%s (капитал %.0f)" % [a["name"], a["cap"]]
		if cd > 0:
			txt += " — ещё %d мес." % cd
		b.text = loc(txt)
		b.disabled = (not opp_mode) or game_over or cd > 0 or cap_spendable() < float(a["cap"]) or (bool(a["seats"]) and seats[0] <= 0)
	# список партий для переговоров
	var want: Array = []
	for p in range(1, PARTY_NAMES.size()):
		if not (p in NO_GOV_SLOTS):
			want.append(p)
	var have: Array = []
	for i in pact_opt.item_count:
		have.append(pact_opt.get_item_id(i))
	var rebuild := have != want
	if rebuild:
		pact_opt.clear()
		for p in want:
			pact_opt.add_item("", p)
	for i in pact_opt.item_count:
		var p: int = pact_opt.get_item_id(i)
		var tag := ""
		if in_coalition[p]:
			tag = " ★"
		pact_opt.set_item_text(i, loc("%s%s — отн. %.0f, мест %d" % [PARTY_NAMES[p], tag, float(prel[p]), seats[p]]))
	if rebuild or pact_opt.get_selected_id() != pact_sel:
		var idx := pact_opt.get_item_index(pact_sel)
		if idx < 0 and pact_opt.item_count > 0:
			idx = 0
			pact_sel = pact_opt.get_item_id(0)
		if idx >= 0:
			pact_opt.select(idx)
	var t := "[b]%s[/b]: отношения [b]%.0f[/b]/100, сходство программ %.0f%%. " % [PARTY_NAMES[pact_sel], float(prel[pact_sel]), party_sim(0, pact_sel) * 100.0]
	var act: PackedStringArray = []
	for k in PACT_KINDS:
		var left := pact_left(pact_sel, String(k["id"]))
		if left != 0 and String(k["id"]) != "talk":
			act.append("%s (%s)" % [String(k["name"]).to_lower(), ("до выборов" if left < 0 or String(k["id"]) == "bloc" else "%d мес." % left)])
	t += ("Действует: " + ", ".join(act) + ".") if act.size() > 0 else "Соглашений нет."
	pact_rt.text = loc(t)
	for k in PACT_KINDS:
		var id2 := String(k["id"])
		var why := pact_can(pact_sel, id2)
		var b2: Button = pact_btns[id2]
		b2.disabled = why != ""
		b2.text = loc("%s (капитал %.0f)%s" % [k["name"], k["cap"], (" — " + why) if why != "" else ""])
