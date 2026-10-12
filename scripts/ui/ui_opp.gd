# Интерфейс: оппозиция и переговоры между партиями (экран «Политика»).
extends "res://scripts/ui/ui_realm.gd"

var opp_rt: RichTextLabel
var opp_btns := {}
var pact_rt: RichTextLabel
var pact_opt: OptionButton
var pact_btns := {}
var pact_sel := 1
var bill_opt: OptionButton
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
	w = new_window("bills", "Законопроекты и поправки", 3, Rect2(0.48, 0.28, 0.222, 0.32))
	bill_opt = fed_opt(w.body, [], "Законопроекты в работе.")
	bill_opt.item_selected.connect(on_bill_pick)
	bill_rt = make_rt(w.body)
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


func on_bill_pick(i: int) -> void:
	bill_sel = bill_opt.get_item_id(i)
	refresh()


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
	if bill_opt == null:
		return
	var mine: Array = []
	for b in bills:
		mine.append(b)
	var ids: Array = []
	for i in bill_opt.item_count:
		ids.append(bill_opt.get_item_id(i))
	var want: Array = []
	for b in mine:
		want.append(int(b["id"]))
	if ids != want:
		bill_opt.clear()
		for b in mine:
			bill_opt.add_item("", int(b["id"]))
	for i in bill_opt.item_count:
		var bb: Dictionary = bills[bill_index(bill_opt.get_item_id(i))]
		bill_opt.set_item_text(i, loc("%s%s" % [String(law_index[bb["tid"]]["name"]), "" if int(bb["sponsor"]) == 0 else " (правительство)"]))
	if bill_index(bill_sel) < 0 and mine.size() > 0:
		bill_sel = int(mine[0]["id"])
	var bi := bill_index(bill_sel)
	for k in bill_am:
		var bt: Button = bill_am[k]
		bt.disabled = bi < 0 or int(bills[bi]["sponsor"]) != 0 or game_over
		if not bt.disabled and k in ["soft", "hard"]:
			var why := bill_pow_block(bills[bi], String(k))
			bt.disabled = why != ""
			bt.tooltip_text = loc(why if why != "" else ("Сила −0.2: слабее эффекты, но закон приемлем для большего числа партий." if k == "soft" else "Сила +0.2: сильнее эффекты, но часть колеблющихся партий будет против."))
	bill_acc.disabled = true
	bill_rej.disabled = true
	if bi < 0:
		bill_rt.text = loc("Законопроектов в работе нет. Выберите закон слева и нажмите «Внести законопроект» — он пройдёт через парламент за несколько месяцев.")
		return
	bill_opt.select(bill_opt.get_item_index(bill_sel))
	var b: Dictionary = bills[bi]
	var v := bill_preview(b)
	var t := "[b]%s[/b] → %s
" % [law_index[b["tid"]]["name"], variant_of(b["tid"], int(b["idx"]))["n"]]
	t += "Голосование через %d мес. Сейчас «за» %d из нужных %d.
" % [maxi(0, int(b["due"]) - turn), int(v["yes"]), law_need(String(b["tid"]))]
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
		"финансировать союзные партии за рубежом (окно «Влияние и зависимость»)"]
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
		b.disabled = (not opp_mode) or game_over or cd > 0 or capital < float(a["cap"]) or (bool(a["seats"]) and seats[0] <= 0)
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
