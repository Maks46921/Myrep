# Интерфейс: правительство и коалиционные переговоры.
extends "res://scripts/ui/ui_laws.gd"

func build_gov_windows() -> void:
	var w: FloatWindow = new_window("coal_sum", "Коалиция", 4, Rect2(0.0, 0.0, 0.25, 0.42))
	coal_head = make_rt(w.body)
	coal_rows.clear()
	for p in range(1, 9):
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
	for p in range(0, 9):
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

	w = new_window("neg", "Переговоры с партией", 4, Rect2(0.50, 0.0, 0.205, 0.70))
	neg_option = OptionButton.new()
	neg_option.focus_mode = Control.FOCUS_NONE
	neg_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	neg_option.fit_to_longest_item = false
	neg_option.clip_text = true
	for p in range(1, 9):
		neg_option.add_item(PARTY_NAMES[p])
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
	neg_main_btn = make_button("", w.body)
	neg_main_btn.pressed.connect(on_neg_main)
	neg_conc_btn = make_button("", w.body)
	neg_conc_btn.pressed.connect(on_neg_conc)
	neg_dem_btn = make_button("", w.body)
	neg_dem_btn.pressed.connect(on_neg_dem)
	neg_rt = make_rt(w.body)
	make_tail(neg_rt, "Довольство и требования партии")

	w = new_window("commit", "Обязательства и требования", 4, Rect2(0.50, 0.70, 0.205, 0.30))
	commit_rt = make_rt(w.body)


func select_ministry(m: int) -> void:
	sel_ministry = m
	refresh()


func select_neg_party(p: int) -> void:
	neg_party = clampi(p, 1, 8)
	selected_party = p
	if current_desk != 4:
		show_desk(4)
	else:
		refresh()


func on_neg_selected(idx: int) -> void:
	neg_party = idx + 1
	selected_party = neg_party
	refresh()


func on_neg_promise(on: bool) -> void:
	neg_promise = on
	refresh()


func on_neg_main() -> void:
	if in_coalition[neg_party]:
		toggle_coalition(neg_party)
	else:
		invite_party(neg_party, neg_promise)


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
	for p in range(1, 9):
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
	for p in range(1, 9):
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
	for p in range(0, 9):
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
	min_replace_btn.disabled = game_over or capital < 5.0
	call_deferred("refit_gov")


func refit_gov() -> void:
	for row in min_cand_rows:
		var rt: RichTextLabel = row["rt"]
		var tx := rt.text
		rt.text = ""
		rt.text = tx


func update_neg() -> void:
	var p := neg_party
	neg_option.select(p - 1)
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
		var w := willingness(p, neg_promise)
		t += "[b]Не в коалиции.[/b] Готовность войти: [b][color=#%s]%.0f[/color][/b] (нужно %.0f, с уступками %.0f)\n" % [
			scale_color(clampf((w - 30.0) / 30.0, 0.0, 1.0)).to_html(false), w, COALITION_JOIN, COALITION_JOIN_PAID]
		t += "[color=%s]Складывается из настроения избирателей, характера лидера%s.[/color]\n" % [COL_DIM, " и обещания закона" if neg_promise else ""]
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
	if in_coalition[p]:
		neg_main_btn.text = "Исключить из коалиции"
		neg_main_btn.disabled = game_over
		neg_conc_btn.visible = true
		neg_conc_btn.text = "Уступки партии (политкапитал 12)"
		neg_conc_btn.disabled = game_over or capital < 12.0
		neg_dem_btn.visible = true
		neg_dem_btn.text = "Выполнить бюджетные требования партии"
		var unmet := false
		for d in PARTY_DEMANDS[p]:
			if not demand_met(d):
				unmet = true
		neg_dem_btn.disabled = game_over or not unmet
	else:
		var w2 := willingness(p, neg_promise and can_promise)
		if w2 >= COALITION_JOIN:
			neg_main_btn.text = "Пригласить в коалицию"
			neg_main_btn.disabled = game_over or seats[p] == 0
		elif w2 >= COALITION_JOIN_PAID:
			neg_main_btn.text = "Пригласить с уступками (политкапитал %.0f)" % CONCESSION_COST
			neg_main_btn.disabled = game_over or capital < CONCESSION_COST or seats[p] == 0
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
	for p in range(0, 9):
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


func update_commit() -> void:
	var t := "[b]Обещания партиям[/b]\n"
	if commitments.is_empty():
		t += "[color=%s]Пока обещаний нет. Обещание закона-условия повышает готовность партии войти в коалицию, но у него есть срок.[/color]\n" % COL_DIM
	for c in commitments:
		var p: int = c["p"]
		var left: int = int(c["deadline"]) - turn
		t += "[color=#%s]■[/color] %s: принять %s — осталось [b]%s[/b]\n" % [(PARTY_COLORS[p] as Color).lightened(0.3).to_html(false), PARTY_NAMES[p], law_demand_text(p), months_text(maxi(left, 0))]
	t += "\n[b]Невыполненные требования партнёров[/b]\n"
	var any := false
	for p in range(1, 9):
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
