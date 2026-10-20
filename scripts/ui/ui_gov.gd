# Интерфейс: правительство и коалиционные переговоры.
extends "res://scripts/ui/ui_laws.gd"

func build_gov_windows() -> void:
	var w: FloatWindow = new_window("coal_sum", "Коалиция", 4, Rect2(0.0, 0.0, 0.25, 0.42))
	coal_head = make_rt(w.body)
	coal_pie = PieChart.new()
	coal_pie.custom_minimum_size = Vector2(0.0, 110.0)
	coal_pie.tooltip_text = "Влияние в коалиции: доля мест каждой партии среди мест коалиции. По ней решаются события, кабинет и бюджет (совет коалиции) и делятся затраты капитала."
	w.body.add_child(coal_pie)
	coal_rows.clear()
	for p in range(1, PARTY_NAMES.size()):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		w.body.add_child(row)
		var sq := ColorRect.new()
		sq.color = PARTY_COLORS[p]
		sq.custom_minimum_size = Vector2(9.0, 9.0)
		sq.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(sq)
		var nb := Button.new()
		nb.flat = true
		nb.theme_type_variation = "SmallButton"
		nb.add_theme_font_size_override("font_size", 13)
		nb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		nb.custom_minimum_size = Vector2(150.0, 0.0)
		nb.clip_text = true
		nb.focus_mode = Control.FOCUS_NONE
		color_button(nb, (PARTY_COLORS[p] as Color).lightened(0.3))
		nb.pressed.connect(select_neg_party.bind(p))
		row.add_child(nb)
		var bar := StatBar.new()
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.custom_minimum_size = Vector2(40.0, 12.0)
		bar.marker = SAT_LEAVE
		row.add_child(bar)
		var vl := Label.new()
		vl.custom_minimum_size = Vector2(26.0, 0.0)
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		vl.add_theme_font_size_override("font_size", 14)
		row.add_child(vl)
		var xb := Button.new()
		xb.theme_type_variation = "SmallButton"
		xb.text = "✕"
		xb.tooltip_text = "Исключить из коалиции"
		xb.focus_mode = Control.FOCUS_NONE
		xb.pressed.connect(toggle_coalition.bind(p))
		row.add_child(xb)
		coal_rows.append({"row": row, "name": nb, "bar": bar, "val": vl})
	var rb := make_button("Распределить министерства по квотам", w.body)
	rb.pressed.connect(reshuffle_cabinet)
	var nb2 := make_button("Коалиционные переговоры…", w.body)
	nb2.tooltip_text = "Большое окно переговоров: состав, глава правительства, министерства с весами, программа, поддержка извне."
	nb2.pressed.connect(func() -> void: cn_open(true))
	add_note(w.body, "Нажмите на партию, чтобы открыть переговоры с ней. Полоса — довольство партнёра; отметка — порог выхода из коалиции (%.0f)." % SAT_LEAVE)

	w = new_window("cabinet", "Кабинет министров", 4, Rect2(0.0, 0.42, 0.25, 0.58))
	cab_buttons.clear()
	var grp := ButtonGroup.new()
	for m in MINISTRIES.size():
		var b := Button.new()
		b.theme_type_variation = "TopicButton"
		b.toggle_mode = true
		b.button_group = grp
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if "autowrap_mode" in b:
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(select_ministry.bind(m))
		w.body.add_child(b)
		cab_buttons.append(b)

	w = new_window("min_detail", "Министерство: кто и что даёт", 4, Rect2(0.25, 0.0, 0.25, 0.66))
	min_head = make_rt(w.body)
	min_cand_rows.clear()
	for p in PARTY_NAMES.size():
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", sbox(C_PANEL2, C_BORDER, 1, 8, 8.0, 6.0))
		w.body.add_child(panel)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		panel.add_child(hb)
		var rt := make_rt(hb)
		var btn := Button.new()
		btn.theme_type_variation = "SmallButton"
		btn.custom_minimum_size = Vector2(84.0, 0.0)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(on_assign_ministry.bind(p))
		hb.add_child(btn)
		min_cand_rows.append({"panel": panel, "rt": rt, "btn": btn})
	min_replace_btn = make_button("", w.body)
	min_replace_btn.pressed.connect(on_replace_minister)

	w = new_window("cabfx", "Бонусы кабинета", 4, Rect2(0.25, 0.66, 0.25, 0.34))
	cabfx_rt = make_rt(w.body)
	make_tail(cabfx_rt, "Кто что приносит")

	w = new_window("neg", "Переговоры с партией", 4, Rect2(0.50, 0.0, 0.205, 0.58))
	neg_option = OptionButton.new()
	neg_option.focus_mode = Control.FOCUS_NONE
	neg_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	neg_option.fit_to_longest_item = false
	neg_option.clip_text = true
	for p in range(1, PARTY_NAMES.size()):
		if can_govern(p):
			neg_option.add_item(PARTY_NAMES[p], p)
	neg_option.item_selected.connect(on_neg_selected)
	w.body.add_child(neg_option)
	neg_promise_btn = Button.new()
	neg_promise_btn.toggle_mode = true
	neg_promise_btn.focus_mode = Control.FOCUS_NONE
	neg_promise_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if "autowrap_mode" in neg_promise_btn:
		neg_promise_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	neg_promise_btn.toggled.connect(on_neg_promise)
	w.body.add_child(neg_promise_btn)
	neg_mins_btn = make_button("", w.body)
	neg_mins_btn.tooltip_text = "Министерства сверх положенной по местам квоты: каждое +6 к готовности. Отдаются из портфелей вашей партии."
	neg_mins_btn.pressed.connect(on_neg_mins)
	neg_main_btn = make_button("", w.body)
	neg_main_btn.pressed.connect(on_neg_main)
	neg_conc_btn = make_button("", w.body)
	neg_conc_btn.pressed.connect(on_neg_conc)
	neg_dem_btn = make_button("", w.body)
	neg_dem_btn.pressed.connect(on_neg_dem)
	neg_rt = make_rt(w.body)
	make_tail(neg_rt, "Довольство и требования партии")

	w = new_window("commit", "Обязательства и предложения", 4, Rect2(0.50, 0.58, 0.205, 0.42))
	pa_box = VBoxContainer.new()
	pa_box.add_theme_constant_override("separation", 6)
	w.body.add_child(pa_box)
	commit_rt = make_rt(w.body)


func select_ministry(m: int) -> void:
	sel_ministry = m
	refresh()


func select_neg_party(p: int) -> void:
	if not can_govern(p):
		return
	neg_party = p
	selected_party = p
	if current_desk != 4:
		show_desk(4)
	else:
		refresh()


func on_neg_selected(idx: int) -> void:
	neg_party = neg_option.get_item_id(idx)
	selected_party = neg_party
	refresh()


func on_neg_promise(on: bool) -> void:
	neg_promise = on
	refresh()


func on_neg_mins() -> void:
	neg_offer_mins = (neg_offer_mins + 1) % 3
	refresh()


func on_neg_main() -> void:
	if in_coalition[neg_party]:
		toggle_coalition(neg_party)
	else:
		invite_party(neg_party, neg_promise, neg_offer_mins)
		if in_coalition[neg_party]:
			neg_offer_mins = 0


func on_neg_conc() -> void:
	do_concession(neg_party)


func on_neg_dem() -> void:
	fulfill_party_demands(neg_party)


func on_assign_ministry(p: int) -> void:
	assign_ministry(sel_ministry, p)


func on_replace_minister() -> void:
	replace_minister(sel_ministry)


func update_gov_windows() -> void:
	if coal_head == null:
		return
	update_coal_summary()
	update_cabinet()
	update_min_detail()
	update_neg()
	update_cabfx()
	update_commit()


func update_coal_summary() -> void:
	var gs := gov_seats()
	var members := 0
	var sum_sat := 0.0
	var weakest := -1
	for p in range(1, PARTY_NAMES.size()):
		if in_coalition[p]:
			members += 1
			var s: float = float(satis.get(p, 50.0))
			sum_sat += s
			if weakest < 0 or s < float(satis.get(weakest, 50.0)):
				weakest = p
	var avg: float = sum_sat / float(members) if members > 0 else 60.0
	var risk := "низкий"
	if not gov_ok() or avg < 40.0:
		risk = "высокий"
	elif gov_margin() < seat_pad() or avg < 50.0:
		risk = "средний"
	var t := "[b]Мест %d из %d[/b] [color=%s](запас %s над большинством)[/color]\n" % [gs, SEATS, COL_DIM, sg(float(gs - MAJORITY), 0)]
	if minority_ok:
		t = "[b]Мест %d из %d[/b] [color=%s](правительство меньшинства: против может выступить %d, для вотума нужно %d)[/color]\n" % [gs, SEATS, COL_DIM, against_seats(), MAJORITY]
	t += "Партнёров: [b]%d[/b] · среднее довольство [b]%s[/b] · риск вотума недоверия: [b]%s[/b]\n" % [members, ("%.0f" % avg) if members > 0 else "—", risk]
	if weakest > 0 and float(satis.get(weakest, 50.0)) < SAT_LEAVE + 14.0:
		t += "[color=%s]⚠ Ближе всех к выходу: %s (%.0f).[/color]\n" % [COL_WARN, PARTY_NAMES[weakest], float(satis.get(weakest, 50.0))]
	coal_head.text = t
	var pie: Array = []
	for p in PARTY_NAMES.size():
		if in_coalition[p] and seats[p] > 0:
			pie.append([float(seats[p]), PARTY_COLORS[p], party_abbr(p)])
	coal_pie.set_data(pie)
	coal_pie.visible = pie.size() >= 2
	for p in range(1, PARTY_NAMES.size()):
		var row: Dictionary = coal_rows[p - 1]
		(row["row"] as Control).visible = in_coalition[p]
		if in_coalition[p]:
			var s2: float = float(satis.get(p, 50.0))
			(row["name"] as Button).text = "%s (%d)" % [PARTY_NAMES[p], seats[p]]
			(row["bar"] as StatBar).set_state(s2, clampf((s2 - 20.0) / 55.0, 0.0, 1.0))
			var vl: Label = row["val"]
			vl.text = "%.0f" % s2
			vl.add_theme_color_override("font_color", scale_color(clampf((s2 - 20.0) / 55.0, 0.0, 1.0)))


func update_cabinet() -> void:
	for m in MINISTRIES.size():
		var b: Button = cab_buttons[m]
		var p: int = ministries[m]
		var mn: Dictionary = ministers[m] if ministers.size() > m else {}
		if mn.is_empty():
			continue
		var fx := ministry_fx(m, p, float(mn["skill"]))
		var star := "★ " if ministry_is_special(m, p) else ""
		b.text = "%s\n%s%s — %s (навык %.0f)\n%s" % [MINISTRIES[m]["name"], star, PARTY_NAMES[p], mn["name"], mn["skill"], bit_text(ministry_items(fx), 3)]
		b.set_pressed_no_signal(m == sel_ministry)
		b.add_theme_color_override("font_color", (PARTY_COLORS[p] as Color).lightened(0.4))


func update_min_detail() -> void:
	var m := sel_ministry
	var holder: int = ministries[m]
	var mn: Dictionary = ministers[m] if ministers.size() > m else {}
	if mn.is_empty():
		return
	var fx := ministry_fx(m, holder, float(mn["skill"]))
	var t := "[b][font_size=19]%s[/font_size][/b]\n[color=%s]%s[/color]\n" % [MINISTRIES[m]["name"], COL_DIM, MINISTRIES[m]["desc"]]
	t += "Министр: [b]%s[/b] [color=%s](навык %.0f: усиливает полезные эффекты ×%.2f)[/color]\n" % [mn["name"], COL_DIM, mn["skill"], clampf(float(mn["skill"]) / 65.0, 0.6, 1.5)]
	t += "Партия: [color=#%s][b]%s[/b][/color] — %s\n" % [(PARTY_COLORS[holder] as Color).lightened(0.3).to_html(false), PARTY_NAMES[holder], ministry_role_text(m, holder)]
	t += "[b]Что даёт сейчас:[/b]\n[font_size=13]%s[/font_size]" % items_pros_cons(ministry_items(fx))
	min_head.text = t
	for p in PARTY_NAMES.size():
		var row: Dictionary = min_cand_rows[p]
		var vis: bool = p == 0 or in_coalition[p]
		(row["panel"] as Control).visible = vis
		if not vis:
			continue
		var cfx := ministry_fx(m, p, 65.0)
		var star := "★ " if ministry_is_special(m, p) else ""
		var txt := "[color=#%s][b]%s[/b][/color]  [color=%s]%s%s[/color]\n[font_size=12]%s[/font_size]" % [
			(PARTY_COLORS[p] as Color).lightened(0.3).to_html(false), PARTY_NAMES[p], COL_DIM, star, ministry_role_text(m, p), items_pros_cons(ministry_items(cfx))]
		(row["rt"] as RichTextLabel).text = txt
		var btn: Button = row["btn"]
		btn.text = "Сейчас" if p == holder else "Назначить"
		btn.disabled = game_over or p == holder
	min_replace_btn.text = "Сменить министра (политкапитал 5)"
	min_replace_btn.disabled = game_over or cap_spendable() < 5.0
	call_deferred("refit_gov")


func refit_gov() -> void:
	for row in min_cand_rows:
		var rt: RichTextLabel = row["rt"]
		var tx := rt.text
		rt.text = ""
		rt.text = tx


func update_neg() -> void:
	var p := neg_party
	if not can_govern(p):
		p = 1
		neg_party = 1
	neg_option.select(neg_option.get_item_index(p))
	var tr: Dictionary = PARTY_TRAITS[p]
	var col: String = (PARTY_COLORS[p] as Color).lightened(0.25).to_html(false)
	var t := "[b][font_size=18][color=#%s]%s[/color][/font_size][/b]\nЛидер: %s. Характер: [b]%s[/b]\n[color=%s]%s[/color]\n" % [col, PARTY_NAMES[p], PARTY_LEADERS[p], tr["trait"], COL_DIM, tr["desc"]]
	t += "Мест: [b]%d[/b] · отношение избирателей к власти [b]%.0f[/b]\n\n" % [seats[p], party_attitude(p)]
	var ld := law_demand_of(p)
	if in_coalition[p]:
		var s: float = float(satis.get(p, 50.0))
		t += "[b]В коалиции.[/b] Довольство [b][color=#%s]%.0f[/color][/b] (выйдет при < %.0f)\n" % [scale_color(clampf((s - 20.0) / 55.0, 0.0, 1.0)).to_html(false), s, SAT_LEAVE]
		t += "[color=%s]Из чего складывается довольство (цель %.0f):[/color]\n[table=2]" % [COL_DIM, sat_target(p)]
		for it in sat_breakdown(p):
			var v: float = float(it[1])
			t += "[cell]%s  [/cell][cell][color=%s]%s[/color][/cell]" % [it[0], COL_GOOD if v >= 0.0 else COL_BAD, sg(v, 1)]
		t += "[/table]\n"
		t += "Министерства: [b]%s[/b] (положено ≈ %d)\n" % [ministries_of(p), quota_for(p)]
		if s < SAT_LEAVE + 14.0:
			t += "[color=%s]⚠ Причины недовольства: %s.[/color]\n" % [COL_WARN, sat_reason(p)]
	else:
		var w := invite_offer_w(p, neg_promise, neg_offer_mins)
		t += "[b]Не в коалиции.[/b] Готовность войти: [b][color=#%s]%.0f[/color][/b] (нужно %.0f, с уступками %.0f)\n" % [
			scale_color(clampf((w - 30.0) / 30.0, 0.0, 1.0)).to_html(false), w, COALITION_JOIN, COALITION_JOIN_PAID]
		t += "[color=%s]Складывается из настроения избирателей, характера лидера, отношений с вами%s%s.[/color]\n" % [COL_DIM, " и обещания закона" if neg_promise else "", (", министерств сверх квоты (+%d)" % (6 * neg_offer_mins)) if neg_offer_mins > 0 else ""]
		if is_cordon(p):
			t += "[color=%s]Вокруг партии «санитарный кордон»: без хороших отношений (переговоры во вкладке «Оппозиция и партии»), щедрых обещаний или затяжного кризиса она не войдёт.[/color]\n" % COL_WARN
		if coal_members().size() >= 2:
			var cv := council_invite_vote(p)
			t += "Согласие партнёров: [b]%.0f%%[/b] влияния %s\n" % [float(cv["yes"]) * 100.0, ("[color=%s](против: %s)[/color]" % [COL_BAD, ", ".join(cv["no"])]) if not bool(cv["ok"]) else "[color=%s](достаточно)[/color]" % COL_GOOD]
	t += "\n[b]Чего хочет партия[/b]\n"
	t += "[b]Министерства:[/b] "
	var pn: PackedStringArray = []
	for mi in (PARTY_MINISTRIES[p] as Array):
		pn.append(("✔ " if ministries[mi] == p else "") + String(MINISTRIES[mi]["name"]))
	t += (", ".join(pn) if pn.size() > 0 else "любые") + "\n"
	if not ld.is_empty():
		var met := law_demand_met(p)
		t += "[b]Закон-условие:[/b] [color=%s]%s %s[/color]\n" % [COL_GOOD if met else COL_BAD, "✔" if met else "✘", law_demand_text(p)]
	t += "[b]Бюджет:[/b]\n" + demand_lines(p)
	set_tail_text(neg_rt, t, 6)
	var can_promise: bool = not ld.is_empty() and not law_demand_met(p) and not in_coalition[p]
	neg_promise_btn.visible = can_promise
	neg_promise_btn.set_pressed_no_signal(neg_promise and can_promise)
	neg_promise_btn.text = "Пообещать закон-условие в течение 18 мес. (готовность +8)"
	neg_mins_btn.visible = not in_coalition[p]
	neg_mins_btn.text = "Предложить министерства сверх квоты: %d (готовность +%d)" % [neg_offer_mins, 6 * neg_offer_mins]
	if in_coalition[p]:
		neg_main_btn.text = "Исключить из коалиции"
		neg_main_btn.disabled = game_over
		neg_conc_btn.visible = true
		neg_conc_btn.text = "Уступки партии (политкапитал 12)"
		neg_conc_btn.disabled = game_over or cap_spendable() < 12.0
		neg_dem_btn.visible = true
		neg_dem_btn.text = "Выполнить бюджетные требования партии"
		var unmet := false
		for d in PARTY_DEMANDS[p]:
			if not demand_met(d):
				unmet = true
		neg_dem_btn.disabled = game_over or not unmet
	else:
		var w2 := invite_offer_w(p, neg_promise and can_promise, neg_offer_mins)
		if w2 >= COALITION_JOIN:
			neg_main_btn.text = "Пригласить в коалицию"
			neg_main_btn.disabled = game_over or seats[p] == 0
		elif w2 >= COALITION_JOIN_PAID:
			neg_main_btn.text = "Пригласить с уступками (политкапитал %.0f)" % CONCESSION_COST
			neg_main_btn.disabled = game_over or cap_spendable() < CONCESSION_COST or seats[p] == 0
		else:
			neg_main_btn.text = "Откажется войти: слишком низкая готовность"
			neg_main_btn.disabled = true
		neg_conc_btn.visible = false
		neg_dem_btn.visible = false
	call_deferred("refit_neg")


func refit_neg() -> void:
	var tx := neg_rt.text
	neg_rt.text = ""
	neg_rt.text = tx
	var tf: RichTextLabel = tails[neg_rt]
	var ty := tf.text
	tf.text = ""
	tf.text = ty


func update_cabfx() -> void:
	var t := "[b]Суммарно от министров[/b] [color=%s](вместе с навыками)[/color]\n%s\n\n" % [COL_DIM, items_pros_cons(cabinet_items())]
	t += "[b]Кто что приносит[/b]\n"
	for p in PARTY_NAMES.size():
		var held: PackedStringArray = []
		for m in MINISTRIES.size():
			if ministries[m] == p:
				held.append(("★" if ministry_is_special(m, p) else "") + String(MINISTRIES[m]["name"]))
		if held.size() > 0:
			t += "[color=#%s]■[/color] %s: %s\n" % [(PARTY_COLORS[p] as Color).lightened(0.3).to_html(false), PARTY_NAMES[p], ", ".join(held)]
	t += "\n[color=%s]★ — министр-специалист: даёт сильный бонус, но с издержкой. Остальные министры работают вполсилы.[/color]" % COL_DIM
	var cut := t.find("\n\n")
	cabfx_rt.text = t.substr(0, cut)
	(tails[cabfx_rt] as RichTextLabel).text = t.substr(cut).strip_edges()


var pa_box: VBoxContainer = null
var pa_sig := ""


# 0.56 (п.15): предложения министров-партнёров — можно наложить вето за политкапитал
func update_pa_box() -> void:
	var sig := "%s|%d|%d" % [str(pa_props), int(capital), turn]
	if sig == pa_sig:
		return
	pa_sig = sig
	for c in pa_box.get_children():
		pa_box.remove_child(c)
		c.queue_free()
	var hl := Label.new()
	hl.text = "Предложения министров-партнёров"
	hl.add_theme_font_size_override("font_size", 14)
	pa_box.add_child(hl)
	if pa_props.is_empty():
		var nl := Label.new()
		nl.text = "Сейчас предложений нет. Министры-партнёры раз в квартал предлагают сдвинуть статьи бюджета своих министерств."
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nl.add_theme_font_size_override("font_size", 12)
		nl.add_theme_color_override("font_color", C_DIM)
		pa_box.add_child(nl)
		return
	for pr in pa_props:
		var p: int = int(pr["p"])
		var pc := PanelContainer.new()
		var sb := sbox(C_PANEL2, PARTY_COLORS[p], 0, 6, 8.0, 5.0)
		sb.border_width_left = 4
		pc.add_theme_stylebox_override("panel", sb)
		pa_box.add_child(pc)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 6)
		pc.add_child(hb)
		var l := Label.new()
		l.text = pa_prop_text(pr)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.add_theme_font_size_override("font_size", 12)
		hb.add_child(l)
		var b := Button.new()
		b.theme_type_variation = "SmallButton"
		b.focus_mode = Control.FOCUS_NONE
		b.text = "Вето (−%.0f)" % pa_veto_cost(p)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.disabled = game_over or opp_mode or cap_spendable() < pa_veto_cost(p)
		b.tooltip_text = "Запретить изменение. Цена зависит от силы партии; министр будет недоволен."
		b.pressed.connect(pa_veto_prop.bind(int(pr["id"])))
		hb.add_child(b)


func update_commit() -> void:
	update_pa_box()
	var t := "[b]Обещания партиям[/b]\n"
	if commitments.is_empty():
		t += "[color=%s]Пока обещаний нет. Обещание закона-условия повышает готовность партии войти в коалицию, но у него есть срок.[/color]\n" % COL_DIM
	for c in commitments:
		var p: int = c["p"]
		var left: int = int(c["deadline"]) - turn
		t += "[color=#%s]■[/color] %s: принять %s — осталось [b]%s[/b]\n" % [(PARTY_COLORS[p] as Color).lightened(0.3).to_html(false), PARTY_NAMES[p], law_demand_text(p), months_text(maxi(left, 0))]
	t += "\n[b]Невыполненные требования партнёров[/b]\n"
	var any := false
	for p in range(1, PARTY_NAMES.size()):
		if not in_coalition[p]:
			continue
		var lines: PackedStringArray = []
		if not law_demand_met(p):
			lines.append("закон " + law_demand_text(p))
		for d in PARTY_DEMANDS[p]:
			if not demand_met(d):
				lines.append(String(d["text"]))
		if lines.size() > 0:
			any = true
			t += "[color=#%s]■[/color] %s: %s\n" % [(PARTY_COLORS[p] as Color).lightened(0.3).to_html(false), PARTY_NAMES[p], "; ".join(lines)]
	if not any:
		t += "[color=%s]Все требования выполнены.[/color]\n" % COL_GOOD
	commit_rt.text = t


# ============================================================
#  0.56 (п.16): ОКНО «КОАЛИЦИОННЫЕ ПЕРЕГОВОРЫ»
#  Слева — партии (места, готовность, мнение избирателей о союзе, требования), в центре — проект соглашения
#  (глава правительства, министерства с весами, программа, тип правительства, срок), справа — ответы партий.
# ============================================================
var cn_ov: PanelContainer = null
var cn_left: VBoxContainer = null
var cn_mid: VBoxContainer = null
var cn_right: VBoxContainer = null
var cn_head_rt: RichTextLabel = null
var cn_sig := ""


func cn_is_open() -> bool:
	return cn_ov != null and cn_ov.visible


func cn_open(on: bool) -> void:
	if cn_ov == null:
		return
	if on:
		var why := cn_why()
		if why != "":
			log_line("[color=%s]Переговоры о коалиции сейчас недоступны: %s.[/color]" % [COL_WARN, why])
			nt_toast("Переговоры о коалиции сейчас недоступны: %s." % why, "coal", -1)
			return
		cn_ensure()
		if tech_is_open():
			set_tech_open(false)
		if crisis_is_open():
			set_crisis_open(false)
		if meas_is_open():
			set_meas_open(false)
	if on != cn_ov.visible:
		sfx("click")
	var was: bool = cn_ov.visible
	cn_ov.visible = on
	if on and not was:
		win_fade_in(cn_ov, 0.18)
	overlay_tabs_sync()
	if on:
		cn_sig = ""
		update_cn_window()


func cn_close() -> void:
	cn_open(false)


# открыть само (после выборов или при распаде коалиции) и поставить игру на паузу
func cn_auto_open() -> void:
	if cn_ov == null or cn_why() != "":
		return
	set_speed(0)
	cn_open(true)


func cn_mk_rt(parent: Control, fs: int = 13) -> RichTextLabel:
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rt.add_theme_font_size_override("normal_font_size", fs)
	rt.add_theme_font_size_override("bold_font_size", fs)
	parent.add_child(rt)
	return rt


func cn_card(parent: Control, col: Color) -> VBoxContainer:
	var pc := PanelContainer.new()
	var sb := sbox(C_PANEL2, col, 0, 8, 10.0, 7.0)
	sb.border_width_left = 4
	pc.add_theme_stylebox_override("panel", sb)
	parent.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	pc.add_child(vb)
	return vb


func cn_col(parent: Control, title: String, min_w: float, expand: bool) -> VBoxContainer:
	var outer := VBoxContainer.new()
	outer.custom_minimum_size = Vector2(min_w, 0.0)
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if expand:
		outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		outer.size_flags_stretch_ratio = 1.4
	parent.add_child(outer)
	var l := Label.new()
	l.text = title
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", C_DIM)
	outer.add_child(l)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(sc)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 8)
	sc.add_child(vb)
	return vb


func build_cn_overlay() -> void:
	cn_ov = PanelContainer.new()
	cn_ov.add_theme_stylebox_override("panel", sbox(Color(C_BG, 0.985), C_ACCENT.darkened(0.25), 2, 12, 14.0, 10.0))
	cn_ov.visible = false
	add_child(cn_ov)
	cn_ov.anchor_right = 1.0
	cn_ov.anchor_bottom = 1.0
	cn_ov.offset_left = 8.0
	cn_ov.offset_top = 62.0
	cn_ov.offset_right = -8.0
	cn_ov.offset_bottom = -8.0
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	cn_ov.add_child(root)
	var hd := HBoxContainer.new()
	hd.add_theme_constant_override("separation", 10)
	root.add_child(hd)
	var ttl := Label.new()
	ttl.text = "Коалиционные переговоры"
	ttl.add_theme_font_size_override("font_size", 22)
	hd.add_child(ttl)
	cn_head_rt = cn_mk_rt(hd, 14)
	cn_head_rt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var cb := Button.new()
	cb.text = "✕"
	cb.focus_mode = Control.FOCUS_NONE
	cb.tooltip_text = "Закрыть окно переговоров (проект сохранится до конца месяца)"
	cb.pressed.connect(cn_close)
	hd.add_child(cb)
	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 14)
	root.add_child(cols)
	cn_left = cn_col(cols, "Партии", 330.0, false)
	cn_mid = cn_col(cols, "Проект соглашения", 420.0, true)
	cn_right = cn_col(cols, "Ответы партий", 340.0, false)


func cn_clear(box: Control) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func cn_pc(p: int) -> Color:
	return (PARTY_COLORS[p] as Color)


func cn_pname(p: int) -> String:
	return "[color=#%s]%s[/color]" % [cn_pc(p).lightened(0.3).to_html(false), PARTY_NAMES[p]]


func cn_verdict_text(p: int) -> String:
	match cn_verdict(p):
		2:
			return "[color=%s]согласится[/color]" % COL_GOOD
		1:
			return "[color=%s]согласится за уступки (капитал −%.0f)[/color]" % [COL_WARN, CN_PAY]
	return "[color=%s]откажет[/color]" % COL_BAD


func update_cn_window() -> void:
	if not cn_is_open():
		return
	if cn_why() != "":
		cn_close()
		return
	cn_ensure()
	var sig := "%s|%s|%s|%s|%d|%d|%d" % [str(cn_draft), str(cn_ans), str(cn_pat), str(cn_out), int(capital), turn, crisis_months]
	if sig == cn_sig:
		return
	cn_sig = sig
	var s := cn_seats()
	var hcol: String = COL_GOOD if s >= MAJORITY else COL_WARN
	var h := "Раунд %d · у проекта [b][color=%s]%d[/color][/b] мест из %d, большинство — %d" % [cn_round + 1, hcol, s, SEATS, MAJORITY]
	if coal_talks or crisis_months > 0:
		h += " · [color=%s]срок: ещё %d мес., потом — кризис и новые выборы[/color]" % [COL_WARN, maxi(1, crisis_limit() - crisis_months + 1)]
	cn_head_rt.text = h
	cn_build_left()
	cn_build_mid()
	cn_build_right()


func cn_build_left() -> void:
	cn_clear(cn_left)
	var sh := national_shares(false)
	var me := cn_card(cn_left, cn_pc(0))
	cn_mk_rt(me).text = "[b]%s[/b] — ваша партия\nМест: [b]%d[/b] · рейтинг %.1f%%\nВаши избиратели о таком союзе: [b]%.0f[/b] из 100" % [cn_pname(0), seats[0], float(sh[0]) * 100.0 if sh.size() > 0 else 0.0, cn_voters(0)]
	var order: Array = []
	for p in range(1, PARTY_NAMES.size()):
		if seats[p] > 0 and can_govern(p):
			order.append([seats[p], p])
	order.sort_custom(func(a, b) -> bool: return int(a[0]) > int(b[0]))
	for o in order:
		var p: int = int(o[1])
		var inp: bool = p in cn_parties()
		var tolp: bool = int(cn_draft.get("tol", -1)) == p
		var vb := cn_card(cn_left, cn_pc(p))
		var t := "[b]%s[/b]%s\nМест: [b]%d[/b] · рейтинг %.1f%%" % [cn_pname(p), "  [color=%s]· в проекте[/color]" % COL_GOOD if inp else ("  [color=%s]· поддержка извне[/color]" % COL_TEAL if tolp else ""), seats[p], float(sh[p]) * 100.0 if sh.size() > p else 0.0]
		if inp or tolp:
			t += "\nОценка проекта: [b]%.0f[/b] из %.0f — %s" % [float(cn_score(p)[0]), COALITION_JOIN, cn_verdict_text(p)]
		else:
			var w := willingness(p, false)
			t += "\nГотовность к союзу: [b][color=#%s]%.0f[/color][/b] (нужно %.0f)" % [scale_color(clampf((w - 30.0) / 30.0, 0.0, 1.0)).to_html(false), w, COALITION_JOIN]
		t += "\nИзбиратели о союзе с вами: %.0f" % clampf(0.75 * rel(p, 0) + 0.25 * party_attitude(p), 0.0, 100.0)
		var pm: PackedStringArray = []
		for mi in (PARTY_MINISTRIES[p] as Array):
			pm.append(String(MINISTRIES[mi]["name"]))
		t += "\n[color=%s]Хочет: %s[/color]" % [COL_DIM, ", ".join(pm) if pm.size() > 0 else "любые министерства"]
		if cn_law_open(p):
			t += "\n[color=%s]Закон-условие: %s[/color]" % [COL_DIM, law_demand_text(p)]
		var nb := 0
		for d in PARTY_DEMANDS[p]:
			if not demand_met(d):
				nb += 1
		if nb > 0:
			t += "\n[color=%s]Бюджетных требований не выполнено: %d[/color]" % [COL_DIM, nb]
		if is_cordon(p):
			t += "\n[color=%s]Вокруг партии «санитарный кордон»[/color]" % COL_WARN
		var pat: int = int(cn_pat.get(p, CN_PAT))
		t += "\nТерпение: %s" % ("●".repeat(pat) + "○".repeat(maxi(0, CN_PAT - pat)))
		var out: bool = not cn_can_talk(p)
		if out:
			t += "\n[color=%s]Ушла из переговоров до следующего месяца[/color]" % COL_BAD
		cn_mk_rt(vb).text = t
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 6)
		vb.add_child(hb)
		var b1 := Button.new()
		b1.theme_type_variation = "SmallButton"
		b1.focus_mode = Control.FOCUS_NONE
		b1.text = "Убрать из проекта" if inp else "В коалицию"
		b1.disabled = out and not inp
		b1.tooltip_text = "Партия войдёт в правительство и получит министерства." if not inp else "Партия не войдёт в правительство (если она сейчас в коалиции — выйдет после подписания)."
		b1.pressed.connect(cn_toggle_party.bind(p))
		hb.add_child(b1)
		var b2 := Button.new()
		b2.theme_type_variation = "SmallButton"
		b2.focus_mode = Control.FOCUS_NONE
		b2.toggle_mode = true
		b2.set_pressed_no_signal(tolp)
		b2.text = "Поддержка извне"
		b2.disabled = out and not tolp
		b2.tooltip_text = "Правительство меньшинства: партия не входит в кабинет, но обещает не голосовать за вотум недоверия до следующих выборов. Министерств не требует."
		b2.pressed.connect(cn_set_tol.bind(p))
		hb.add_child(b2)


func cn_opt(parent: Control, cur: int, cb: Callable) -> OptionButton:
	var ob := OptionButton.new()
	ob.focus_mode = Control.FOCUS_NONE
	ob.fit_to_longest_item = false
	ob.clip_text = true
	ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var holders: Array = [0] + cn_parties()
	for q in holders:
		ob.add_item(party_abbr(q), q)
	ob.select(maxi(0, ob.get_item_index(cur)))
	ob.item_selected.connect(func(i: int) -> void: cb.call(ob.get_item_id(i)))
	parent.add_child(ob)
	return ob


func cn_build_mid() -> void:
	cn_clear(cn_mid)
	var s := cn_seats()
	var tol: int = int(cn_draft.get("tol", -1))
	var kind := ""
	if cn_parties().is_empty() and tol < 0:
		kind = "Однопартийное правительство"
	elif s >= MAJORITY:
		kind = "Коалиция большинства"
	else:
		kind = "Правительство меньшинства"
	if tol > 0:
		kind += " с поддержкой извне: %s" % cn_pname(tol)
	var top := cn_card(cn_mid, C_ACCENT)
	var t := "[b][font_size=16]%s[/font_size][/b]\n" % kind
	t += "Состав: %s" % ", ".join(PackedStringArray([cn_pname(0)] + cn_parties().map(func(q: int) -> String: return cn_pname(q))))
	t += "\nМест: [b]%d[/b] из %d (нужно %d)" % [s, SEATS, MAJORITY]
	if s < MAJORITY and tol > 0:
		t += " · против правительства без поддержки: %d" % cn_against()
	cn_mk_rt(top).text = t
	# 0.59: ИИ предлагает состав, решает игрок
	var sug: Array = cn_ai_suggest()
	var aic := cn_card(cn_mid, C_TEAL)
	if sug.is_empty():
		cn_mk_rt(aic, 12).text = "[b]Совет ИИ:[/b] [color=%s]собрать большинство из готовых партий не получается. Можно искать поддержку извне и править меньшинством.[/color]" % COL_DIM
	else:
		var names: PackedStringArray = []
		var ss: int = seats[0]
		for q in sug:
			names.append(PARTY_NAMES[int(q)])
			ss += int(seats[int(q)])
		cn_mk_rt(aic, 12).text = "[b]Совет ИИ:[/b] позвать %s: вместе %d мест из %d. Это только предложение: состав, министерства и программу решаете вы." % [", ".join(names), ss, SEATS]
		var ab2 := Button.new()
		ab2.theme_type_variation = "SmallButton"
		ab2.focus_mode = Control.FOCUS_NONE
		ab2.text = "Подставить предложение ИИ в проект"
		ab2.tooltip_text = "Заполнит проект составом и министерствами по совету ИИ. Дальше можно менять всё вручную и только потом предлагать соглашение."
		ab2.pressed.connect(func() -> void:
			cn_apply_ai()
			refresh())
		aic.add_child(ab2)
	var bar := StatBar.new()
	bar.custom_minimum_size = Vector2(0.0, 12.0)
	bar.marker = float(MAJORITY) / float(SEATS) * 100.0
	top.add_child(bar)
	bar.set_state(float(s) / float(SEATS) * 100.0, 1.0 if s >= MAJORITY else 0.3)
	# глава правительства
	var pmc := cn_card(cn_mid, C_BORDER)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	pmc.add_child(hb)
	var l := Label.new()
	l.text = "Глава правительства"
	l.custom_minimum_size = Vector2(200.0, 0.0)
	hb.add_child(l)
	cn_opt(hb, int(cn_draft.get("pm", 0)), cn_set_pm)
	if int(cn_draft.get("pm", 0)) != 0:
		cn_mk_rt(pmc, 12).text = "[color=%s]Пост отдаётся партнёру: вы станете младшим партнёром — меньше влияния на решения кабинета.[/color]" % COL_WARN
	# министерства
	var mc := cn_card(cn_mid, C_BORDER)
	var mh := HBoxContainer.new()
	mc.add_child(mh)
	var ml := Label.new()
	ml.text = "Министерства (★ — вес)"
	ml.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mh.add_child(ml)
	var ab := Button.new()
	ab.theme_type_variation = "SmallButton"
	ab.focus_mode = Control.FOCUS_NONE
	ab.text = "Распределить по весу мест"
	ab.tooltip_text = "Каждая партия получает министерства пропорционально местам: сначала профильные, потом остальные."
	ab.pressed.connect(func() -> void:
		cn_auto_mins()
		refresh())
	mh.add_child(ab)
	var gr := GridContainer.new()
	gr.columns = 2
	gr.add_theme_constant_override("h_separation", 8)
	gr.add_theme_constant_override("v_separation", 4)
	mc.add_child(gr)
	var mins: Dictionary = cn_draft.get("mins", {})
	for m in MINISTRIES.size():
		var nl := Label.new()
		nl.text = "%s %s" % ["★".repeat(cn_min_w(m)), MINISTRIES[m]["name"]]
		nl.custom_minimum_size = Vector2(240.0, 0.0)
		nl.add_theme_font_size_override("font_size", 13)
		gr.add_child(nl)
		cn_opt(gr, int(mins.get(m, 0)), func(q: int) -> void: cn_set_min(m, q))
	var wl := PackedStringArray()
	for q in [0] + cn_parties():
		wl.append("%s %d из %.1f" % [party_abbr(q), cn_got_w(q), cn_fair_w(q)])
	cn_mk_rt(mc, 12).text = "[color=%s]Вес у партий (получено из положенного по местам): %s[/color]" % [COL_DIM, " · ".join(wl)]
	# программа
	var who: Array = cn_parties().duplicate()
	if tol > 0:
		who.append(tol)
	var any := false
	var pc := cn_card(cn_mid, C_BORDER)
	var pl := Label.new()
	pl.text = "Программа правительства"
	pc.add_child(pl)
	for p in who:
		if cn_law_open(p):
			any = true
			var ck := CheckBox.new()
			ck.focus_mode = Control.FOCUS_NONE
			ck.text = "%s: принять закон %s за 18 мес." % [party_abbr(p), law_demand_text(p)]
			if "autowrap_mode" in ck:
				ck.set("autowrap_mode", TextServer.AUTOWRAP_WORD_SMART)
			ck.set_pressed_no_signal(p in (cn_draft["laws"] as Array))
			ck.toggled.connect(func(_on: bool) -> void: cn_toggle_list("laws", p))
			pc.add_child(ck)
		if cn_bud_open(p):
			any = true
			var ds: PackedStringArray = []
			for d in PARTY_DEMANDS[p]:
				if not demand_met(d):
					ds.append(String(d["text"]))
			var ck2 := CheckBox.new()
			ck2.focus_mode = Control.FOCUS_NONE
			ck2.text = "%s: бюджет — %s" % [party_abbr(p), "; ".join(ds)]
			if "autowrap_mode" in ck2:
				ck2.set("autowrap_mode", TextServer.AUTOWRAP_WORD_SMART)
			ck2.set_pressed_no_signal(p in (cn_draft["budget"] as Array))
			ck2.toggled.connect(func(_on: bool) -> void: cn_toggle_list("budget", p))
			pc.add_child(ck2)
	if not any:
		cn_mk_rt(pc, 12).text = "[color=%s]Добавьте партнёров: здесь появятся их законы-условия и бюджетные требования.[/color]" % COL_DIM
	cn_mk_rt(cn_mid, 12).text = "[color=%s]Нарушение соглашения злит партнёра: невыполненная программа — минус довольство, второе нарушение — выход. Отобранное министерство — партнёр уходит сразу.[/color]" % COL_DIM


func cn_build_right() -> void:
	cn_clear(cn_right)
	var who: Array = cn_parties().duplicate()
	var tol: int = int(cn_draft.get("tol", -1))
	if tol > 0:
		who.append(tol)
	if who.is_empty():
		cn_mk_rt(cn_right).text = "[color=%s]В проекте пока нет партнёров.%s[/color]" % [COL_DIM, " У вашей партии своё большинство — можно править одной." if seats[0] >= MAJORITY else " Добавьте партии слева."]
	for p in who:
		var sc: Array = cn_score(p)
		var vb := cn_card(cn_right, cn_pc(p))
		var t := "[b]%s[/b]\nОценка: [b]%.0f[/b] из %.0f — %s\n[table=2]" % [cn_pname(p), float(sc[0]), COALITION_JOIN, cn_verdict_text(p)]
		for r in (sc[1] as Array):
			var v: float = float(r[1])
			t += "[cell][color=%s]%s  [/color][/cell][cell][color=%s]%s[/color][/cell]" % [COL_DIM, r[0], COL_GOOD if v >= 0.0 else COL_BAD, sg(v, 0) if absf(v) >= 0.5 else "0"]
		t += "[/table]"
		if cn_ans.has(p):
			t += "\n[i]%s[/i]" % String(cn_ans[p])
		cn_mk_rt(vb, 12).text = t
	var blk := cn_block()
	var cost := cn_cost()
	var bot := cn_card(cn_right, C_ACCENT)
	var bt := ""
	if blk != "":
		bt = "[color=%s]Сейчас нельзя: %s.[/color]" % [COL_WARN, blk]
	else:
		bt = "Уступки при подписании: [b]%s[/b] политкапитала (доступно %.0f)." % ["−%.0f" % cost if cost > 0.0 else "0", minf(cap_spendable(), capital)]
	cn_mk_rt(bot).text = bt
	var pb := Button.new()
	pb.text = "Предложить соглашение"
	pb.focus_mode = Control.FOCUS_NONE
	pb.custom_minimum_size = Vector2(0.0, 38.0)
	pb.disabled = blk != ""
	pb.tooltip_text = "Партии ответят на проект. Все согласны — соглашение подписано. Кто-то против — его терпение уменьшается; раундов сколько угодно."
	pb.pressed.connect(cn_propose)
	bot.add_child(pb)
	var rb := Button.new()
	rb.theme_type_variation = "SmallButton"
	rb.text = "Начать проект заново"
	rb.focus_mode = Control.FOCUS_NONE
	rb.pressed.connect(func() -> void:
		cn_new_draft()
		refresh())
	bot.add_child(rb)
