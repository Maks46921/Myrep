# Интерфейс: дипломатия.
extends "res://scripts/ui/ui_econ.gd"

# ---------- (карта Европы объединена с картой страны) ----------
func select_dip(code: String) -> void:
	dip_sel = code
	update_dip_windows()


func on_dip_far_ex() -> void:
	ex_sel = dip_sel
	show_desk(10)


func build_dip_windows() -> void:
	var w: FloatWindow
	w = new_window("dtable", "Страны мира: сводка", 2, Rect2(0.25, 0.70, 0.45, 0.30))
	dip_table_rt = make_rt(w.body)
	dip_mod_rt = make_rt(w.body)
	make_tail(dip_mod_rt, "О саммитах ЕС")

	w = new_window("dinfo", "Страна: сведения", 2, Rect2(0.0, 0.19, 0.25, 0.81))
	dip_info_rt = make_rt(w.body)

	w = new_window("dact", "Взаимодействие со страной", 2, Rect2(0.45, 0.0, 0.255, 1.0))
	add_title(w.body, "Быстрые действия")
	dip_act_box = VBoxContainer.new()
	dip_act_box.add_theme_constant_override("separation", 4)
	w.body.add_child(dip_act_box)
	dip_act_btns.clear()
	for a in DIP_ACTIONS:
		var b := make_button("", dip_act_box)
		b.pressed.connect(dip_do_action.bind(a["id"]))
		b.tooltip_text = String(a["desc"])
		dip_act_btns[a["id"]] = b
	add_title(w.body, "Соглашения о сотрудничестве")
	dip_track_btns.clear()
	dip_track_lbls.clear()
	for t in DIP_TRACKS:
		var lb := add_wrap_label(w.body, "")
		dip_track_lbls[t["id"]] = lb
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		w.body.add_child(row)
		var up := make_button("", row)
		up.pressed.connect(dip_upgrade.bind(t["id"]))
		var dn := Button.new()
		dn.text = "−"
		dn.focus_mode = Control.FOCUS_NONE
		dn.tooltip_text = "Сократить соглашение (отношения -5)"
		dn.pressed.connect(dip_downgrade.bind(t["id"]))
		row.add_child(dn)
		dip_track_btns[t["id"]] = [up, dn]
	dip_far_box = VBoxContainer.new()
	w.body.add_child(dip_far_box)
	dip_far_lbl = add_wrap_label(dip_far_box, "")
	var fb := make_button("Влияние и зависимость: действовать с этой страной", dip_far_box)
	fb.pressed.connect(on_dip_far_ex)
	dip_far_box.visible = false
	add_note(w.body, "Каждое соглашение даёт эффект, пока отношения достаточно тёплые. Уровни выше обычных усиливают экономику и безопасность; в кризисе отношений соглашения рушатся.")


func update_dip_windows() -> void:
	if dip_info_rt == null or dip.is_empty():
		return
	var far: bool = not (DIP_C.has(dip_sel) and dip.has(dip_sel))
	if wins.has("dact"):
		for ch in (wins["dact"] as FloatWindow).body.get_children():
			if ch != dip_far_box and not note_nodes.has(ch):
				ch.visible = not far
		dip_far_box.visible = far
	if far:
		if WORLD.has(dip_sel):
			dip_info_rt.text = world_info(dip_sel) + foreign_region_text() + "\nОтношения с вами: [b]%.0f[/b] (%s)\n" % [fed_rel(dip_sel), dip_rel_name(fed_rel(dip_sel))]
			dip_far_lbl.text = "С этой страной нет двусторонних соглашений: она не входит в круг ближайших соседей. Доступны торговля, влияние, помощь и пошлины."
		return
	var d: Dictionary = DIP_C[dip_sel]
	var st: Dictionary = dip[dip_sel]
	var rel: float = float(st["rel"])
	var tg := dip_target(dip_sel)
	var t := world_info(dip_sel) + foreign_region_text()
	t += "\nОтношения: [b][color=#%s]%.0f[/color][/b] — %s   (тенденция к %.0f)\n" % [scale_color(clampf(rel / 100.0, 0.0, 1.0)).to_html(false), rel, dip_rel_name(rel), tg]
	t += "[color=%s]Ценит:[/color] %s\n[color=%s]Не любит:[/color] %s\n" % [COL_GOOD, d["likes"], COL_BAD, d["dislikes"]]
	var lv: Dictionary = st["lv"]
	t += "\n[b]Соглашения:[/b] торговля %d/3 · безопасность %d/3 · энергия и инфраструктура %d/3" % [int(lv["trade"]), int(lv["sec"]), int(lv["energy"])]
	var shown := false
	var likes: Dictionary = DIP_LIKES[dip_sel]
	var reasons := ""
	for tid in likes:
		var idx: int = cur_idx(tid)
		if (likes[tid] as Dictionary).has(idx):
			var dv: float = float(likes[tid][idx])
			reasons += "• %s: «%s» (%s)\n" % [law_index[tid]["name"], variant_of(tid, idx)["n"], sg(dv, 0)]
			shown = true
	if shown:
		t += "\n\n[b]Ваши законы влияют на отношения:[/b]\n" + reasons.strip_edges()
	dip_info_rt.text = t
	# действия
	var cd: Dictionary = st["cd"]
	for a in DIP_ACTIONS:
		var b: Button = dip_act_btns[a["id"]]
		var left: int = int(cd.get(a["id"], 0))
		var txt := "%s (капитал %.0f)" % [loc(String(a["name"])), a["cap"]]
		if left > 0:
			txt += " — ещё %d мес." % left
		b.text = txt
		b.disabled = left > 0 or game_over or capital < float(a["cap"])
	for tr in DIP_TRACKS:
		var tid: String = tr["id"]
		var L: int = int(lv[tid])
		var cost := dip_track_cost(dip_sel, tid)
		(dip_track_lbls[tid] as Label).text = "%s — уровень %d из 3. %s" % [tr["name"], L, tr["desc"]]
		var pair: Array = dip_track_btns[tid]
		var up: Button = pair[0]
		var dn: Button = pair[1]
		var tl: int = int(cd.get("t_" + tid, 0))
		if L >= 3:
			up.text = "Максимальный уровень"
			up.disabled = true
		else:
			up.text = "Углубить: капитал %.0f, %.2f%% ВВП (отношения от %.0f)" % [cost[0], cost[1], cost[2]]
			if tl > 0:
				up.text = "Углубить через %d мес." % tl
			up.disabled = game_over or capital < float(cost[0]) or rel < float(cost[2]) or tl > 0
		dn.disabled = game_over or L <= 0
	# таблица
	var tb := "[b]Страны на карте[/b]\n[table=7]"
	tb += "[cell][color=%s]страна[/color][/cell][cell][color=%s] отнош.[/color][/cell][cell][color=%s] рост[/color][/cell][cell][color=%s] инфл.[/color][/cell][cell][color=%s] долг[/color][/cell][cell][color=%s] стаб.[/color][/cell][cell][color=%s] сейчас[/color][/cell]" % [COL_DIM, COL_DIM, COL_DIM, COL_DIM, COL_DIM, COL_DIM, COL_DIM]
	for c in [ccode] + DIP_ORDER:
		var ws: Dictionary = wsim[c]
		var rel_s := "вы"
		if c != ccode:
			var r: float = float(dip[c]["rel"])
			rel_s = "[color=#%s]%.0f[/color]" % [scale_color(clampf(r / 100.0, 0.0, 1.0)).to_html(false), r]
		var cr: Dictionary = ws["crisis"]
		tb += "[cell]%s %s[/cell][cell] %s[/cell][cell] %.1f%%[/cell][cell] %.1f%%[/cell][cell] %.0f%%[/cell][cell] %.0f[/cell][cell] %s[/cell]" % ["▶" if c == dip_sel else "", WORLD[c]["name"], rel_s, float(ws["growth"]), float(ws["infl"]), float(ws["debt"]), float(ws["stab"]), String(cr.get("n", "—"))]
	tb += "[/table]"
	dip_table_rt.text = tb
	var gm := dip_growth()
	var sm := dip_sec()
	var mt := "[b]Эффект дипломатии для страны[/b]\nРост ВВП: %s п.п./год   Безопасность: %s\nДипломатическое влияние (МИД, законы): [b]%s[/b]   Средние отношения: [b]%.0f[/b]\n[color=%s]Ближайшие саммиты ЕС проходят в марте, июне, октябре и декабре: на них приходится выбирать сторону. Министр иностранных дел и ваши законы по ЕС и границам смещают отношения со всеми соседями.[/color]" % [sg(gm, 2), sg(sm, 1), sg(float(mods["dip_bonus"]) - dip_bonus0, 1), dip_avg_rel(), COL_DIM]
	set_tail_text(dip_mod_rt, mt, 3)
	if dip_ctl != null:
		dip_ctl.queue_redraw()
	if dip_legend != null:
		dip_legend.text = ""
