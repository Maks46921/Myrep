# Интерфейс: окно законов.
extends "res://scripts/ui/ui_politics.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func update_bill_window() -> void:
	pass


# --- конец заглушек ---


const LawScale := preload("res://scripts/classes/law_scale.gd")
# цвета 11 областей законов
const LAW_AREA_COLORS := ["#f0b64a", "#58c887", "#ee6b6b", "#6fa8dc", "#7fd16a", "#a58af0", "#45c4bc", "#e08fb0", "#d9a066", "#c9b6ff", "#7fb0ff"]

func build_law_windows() -> void:
	var w: FloatWindow = new_window("laws_list", "Законы по областям", 3, Rect2(0.0, 0.0, 0.22, 0.70))
	law_search = LineEdit.new()
	law_search.placeholder_text = "Поиск по названию и тексту закона…"
	law_search.clear_button_enabled = true
	law_search.text_changed.connect(on_law_search)
	w.body.add_child(law_search)
	law_area_opt = OptionButton.new()
	law_area_opt.focus_mode = Control.FOCUS_NONE
	law_area_opt.fit_to_longest_item = false
	law_area_opt.clip_text = true
	law_area_opt.tooltip_text = "Показать законы одной области"
	law_area_opt.add_item("Все области", 0)
	for ai in LAW_AREA_NAMES.size():
		law_area_opt.add_item(LAW_AREA_NAMES[ai], ai + 1)
	law_area_opt.item_selected.connect(on_law_area)
	w.body.add_child(law_area_opt)
	var fb := HFlowContainer.new()
	fb.add_theme_constant_override("h_separation", 4)
	fb.add_theme_constant_override("v_separation", 4)
	w.body.add_child(fb)
	var vgrp := ButtonGroup.new()
	law_view_btns.clear()
	for vi in 2:
		var vb := Button.new()
		vb.theme_type_variation = "SmallButton"
		vb.text = ["☰ Список", "▦ Плитки"][vi]
		vb.tooltip_text = ["Законы строками: название и действующий вариант", "Законы плитками со значками"][vi]
		vb.toggle_mode = true
		vb.button_group = vgrp
		vb.focus_mode = Control.FOCUS_NONE
		vb.pressed.connect(on_law_view.bind(vi))
		fb.add_child(vb)
		law_view_btns.append(vb)
	(law_view_btns[law_view] as Button).set_pressed_no_signal(true)
	var fgrp := ButtonGroup.new()
	law_filter_btns.clear()
	var fnames := ["Все", "Принятые", "На повестке", "Только страновые", "Фундаментальные"]
	var ftips := ["Все законы", "Только законы, в которых вы уже поменяли вариант", "Законы, которые требует коалиционный партнёр или будущий союзник", "Законы, которых нет в других странах: реальные законы и споры именно этой страны", "Законы, для изменения которых нужны две трети голосов"]
	for f in fnames.size():
		var fbtn := Button.new()
		fbtn.theme_type_variation = "SmallButton"
		fbtn.text = fnames[f]
		fbtn.tooltip_text = ftips[f]
		fbtn.toggle_mode = true
		fbtn.button_group = fgrp
		fbtn.focus_mode = Control.FOCUS_NONE
		fbtn.pressed.connect(on_law_filter.bind(f))
		fb.add_child(fbtn)
		law_filter_btns.append(fbtn)
	(law_filter_btns[0] as Button).set_pressed_no_signal(true)
	law_list_box = VBoxContainer.new()
	law_list_box.add_theme_constant_override("separation", 4)
	w.body.add_child(law_list_box)
	law_list_box.resized.connect(on_law_list_resized)
	var tgrp := ButtonGroup.new()
	law_topic_buttons.clear()
	build_law_list(tgrp)

	w = new_window("laws_effects", "Итог действующих законов", 3, Rect2(0.0, 0.70, 0.22, 0.30))
	law_prog.clear()
	for c in 3:
		var prow := HBoxContainer.new()
		prow.add_theme_constant_override("separation", 8)
		w.body.add_child(prow)
		var pl := Label.new()
		pl.custom_minimum_size = Vector2(112.0, 0.0)
		pl.clip_text = true
		pl.add_theme_font_size_override("font_size", 13)
		pl.add_theme_color_override("font_color", Color(LAW_CAT_COLORS[c]))
		prow.add_child(pl)
		var pb := StatBar.new()
		pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pb.custom_minimum_size = Vector2(24.0, 11.0)
		prow.add_child(pb)
		var pv := Label.new()
		pv.custom_minimum_size = Vector2(46.0, 0.0)
		pv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pv.add_theme_font_size_override("font_size", 13)
		prow.add_child(pv)
		law_prog.append([pl, pb, pv])
	law_effects_rt = make_rt(w.body)

	w = new_window("law_detail", "Закон и его варианты", 3, Rect2(0.22, 0.0, 0.26, 1.0))
	law_detail_head = make_rt(w.body)
	build_law_slider(w.body)
	law_scale = LawScale.new()
	law_scale.picked.connect(on_scale_pick)
	w.body.add_child(law_scale)
	law_cards.clear()
	for i in 8:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", sbox(C_PANEL2, C_BORDER, 1, 9, 10.0, 8.0))
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.gui_input.connect(on_card_input.bind(i))
		w.body.add_child(panel)
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 4)
		vb.mouse_filter = Control.MOUSE_FILTER_PASS
		panel.add_child(vb)
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 6)
		vb.add_child(top)
		var title := Label.new()
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.add_theme_font_size_override("font_size", 15)
		top.add_child(title)
		var badge := Label.new()
		badge.add_theme_font_size_override("font_size", 11)
		top.add_child(badge)
		var bar := StatBar.new()
		bar.custom_minimum_size = Vector2(40.0, 10.0)
		vb.add_child(bar)
		var desc := add_note(vb, "", true)
		var meta := make_rt(vb)
		var fx := make_rt(vb)
		var vote := Label.new()
		vote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vote.add_theme_font_size_override("font_size", 12)
		vb.add_child(vote)
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(on_adopt.bind(i))
		vb.add_child(btn)
		law_cards.append({"panel": panel, "bar": bar, "title": title, "badge": badge, "desc": desc, "meta": meta, "fx": fx, "vote": vote, "btn": btn})

	w = new_window("law_votes", "Голосование", 3, Rect2(0.48, 0.0, 0.222, 0.22))
	lv_head = make_rt(w.body)
	lv_bar = StatBar.new()
	lv_bar.custom_minimum_size = Vector2(40.0, 16.0)
	lv_bar.marker = float(MAJORITY) * 100.0 / float(SEATS)
	w.body.add_child(lv_bar)
	lv_sum = add_wrap_label(w.body, "")
	lv_rows.clear()
	for p in PARTY_NAMES.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 5)
		w.body.add_child(row)
		var sq := ColorRect.new()
		sq.color = PARTY_COLORS[p]
		sq.custom_minimum_size = Vector2(9.0, 9.0)
		sq.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(sq)
		var nm := Label.new()
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.clip_text = true
		nm.add_theme_font_size_override("font_size", 13)
		row.add_child(nm)
		var sl := Label.new()
		sl.add_theme_font_size_override("font_size", 12)
		sl.add_theme_color_override("font_color", C_DIM)
		row.add_child(sl)
		var vl := Label.new()
		vl.custom_minimum_size = Vector2(62.0, 0.0)
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		vl.add_theme_font_size_override("font_size", 12)
		row.add_child(vl)
		lv_rows.append({"row": row, "name": nm, "seats": sl, "verdict": vl})
	lv_neg = make_button("", w.body)
	lv_neg.pressed.connect(on_negotiate)
	add_note(w.body, "★ — партия в вашей коалиции. Коалиционные партнёры поддерживают закон, если он им не очень вредит. Колеблющихся можно убедить за политкапитал.")


func on_law_search(t: String) -> void:
	law_query = t.strip_edges().to_lower()
	update_law_windows()


func on_law_filter(f: int) -> void:
	law_filter = f
	update_law_windows()


func on_law_view(v: int) -> void:
	law_view = v
	update_law_windows()


func on_law_area(i: int) -> void:
	law_area_sel = i - 1
	update_law_windows()


func on_section_toggle(a: int) -> void:
	law_collapsed[a] = not bool(law_collapsed.get(a, false))
	update_law_windows()


func on_scale_pick(i: int) -> void:
	var topic: Dictionary = law_index[sel_topic]
	if topic.has("param"):
		var grid: Array = topic["param"]["grid"]
		var gi: int = int(law_scale_map[clampi(i, 0, law_scale_map.size() - 1)]) if not law_scale_map.is_empty() else i
		sel_variant = int(grid[clampi(gi, 0, grid.size() - 1)])
	else:
		sel_variant = i
	update_law_windows()


# шанс принятия: чем больше запас голосов над нужным числом, тем увереннее (разброс — несколько голосов дисциплины)
func law_chance(vt: Dictionary, need: int) -> int:
	var z: float = float(int(vt["yes"]) - need) / (0.025 * float(SEATS))
	return clampi(int(roundf(100.0 / (1.0 + exp(-z)))), 1, 99)


func short_party(p: int) -> String:
	return String(PARTY_NAMES[p]).split(" (")[0]


# строки карточки варианта: цена, шанс, кто за и против, влияние на бюджет
func law_card_meta(tid: String, vi: int, vt: Dictionary, need: int) -> String:
	var t := "[font_size=12][color=%s]Цена:[/color] [b]%.0f[/b] политкапитала" % [COL_DIM, law_cost(tid, vi)]
	if radical_bypass(tid, vi):
		t += "  ·  [color=%s]принимается указом[/color]" % COL_DIM
	else:
		var ch := law_chance(vt, need)
		t += "  ·  [color=%s]Шанс принятия:[/color] [b]%d%%[/b]" % [COL_DIM, ch]
	var yes: PackedStringArray = []
	var no: PackedStringArray = []
	for it in vt["per"]:
		var p: int = int(it[0])
		if seats[p] <= 0:
			continue
		if bool(it[2]):
			yes.append(short_party(p))
		else:
			no.append(short_party(p))
	if yes.size() > 0:
		t += "\n[color=%s]За:[/color] %s" % [COL_GOOD, ", ".join(yes)]
	if no.size() > 0:
		t += "\n[color=%s]Против:[/color] %s" % [COL_BAD, ", ".join(no)]
	var st2: Dictionary = law_state.duplicate()
	st2[tid] = vi
	var d: float = float(compute_mods(st2, true, tid)["extra_spend"]) - float(compute_mods(law_state, true)["extra_spend"])
	if absf(d) >= 0.005:
		t += "\n[color=%s]Бюджет:[/color] %s%% ВВП в год" % [COL_DIM, sg(d, 2)]
	return t + "[/font_size]"


# какие законы требуют партии: {id закона: [названия партий]}
func law_demand_map() -> Dictionary:
	var out := {}
	for p in range(1, PARTY_NAMES.size()):
		if seats[p] <= 0 or p >= PARTY_LAW_DEMAND.size():
			continue
		var ld := law_demand_of(p)
		if ld.is_empty() or law_demand_met(p):
			continue
		var tid: String = String(ld["tid"])
		if not out.has(tid):
			out[tid] = []
		(out[tid] as Array).append(PARTY_NAMES[p])
	return out


func on_law_cat(c: int) -> void:
	law_cat = c
	refresh()


func on_topic_pressed(tid: String) -> void:
	sel_topic = tid
	law_cat = int(law_index[tid]["cat"])
	sel_variant = first_other_variant(tid)
	refresh()


func first_other_variant(tid: String) -> int:
	if law_index[tid].has("param"):
		return cur_idx(tid)
	var n: int = (law_index[tid]["v"] as Array).size()
	var cur := cur_idx(tid)
	for i in range(0, n):
		if i != cur:
			return i
	return 0


func on_card_input(ev: InputEvent, i: int) -> void:
	var mb := ev as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and not law_index[sel_topic].has("param"):
		sel_variant = i
		update_law_windows()


func on_adopt(i: int) -> void:
	if not law_index[sel_topic].has("param"):
		sel_variant = i
	propose_variant(sel_topic, sel_variant)


func on_negotiate() -> void:
	negotiate_variant(sel_topic, sel_variant)


func update_law_windows() -> void:
	if law_list_box == null:
		return
	update_bill_window()
	# v55_3: тема по умолчанию («Барьер») может быть убрана у страны (DE_REMOVE у Франции)
	if not law_index.has(sel_topic) and not LAW_TOPICS.is_empty():
		sel_topic = String(LAW_TOPICS[0]["id"])
		sel_variant = first_other_variant(sel_topic)
	var nvar: int = (law_index[sel_topic]["v"] as Array).size()
	if sel_variant >= nvar or (sel_variant == cur_idx(sel_topic) and not law_index[sel_topic].has("param") and not is_hybrid(sel_topic)):
		sel_variant = first_other_variant(sel_topic)
	var dem := law_demand_map()
	for fi in law_filter_btns.size():
		(law_filter_btns[fi] as Button).set_pressed_no_signal(fi == law_filter)
	for vi in law_view_btns.size():
		(law_view_btns[vi] as Button).set_pressed_no_signal(vi == law_view)
	if law_area_opt != null and law_area_opt.selected != law_area_sel + 1:
		law_area_opt.select(law_area_sel + 1)
	var tiles: bool = law_view == 1
	var avail: float = law_list_box.size.x
	var cols: int = maxi(2, int(avail / 112.0)) if tiles else 1
	var shown := 0
	var area_shown := {}
	for t in LAW_TOPICS:
		var id: String = t["id"]
		var btn: Button = law_topic_buttons[id]
		var ar: int = law_area(id)
		var cur := cur_idx(id)
		var vis: bool = law_area_sel < 0 or law_area_sel == ar
		if law_query != "" and String(law_text_idx.get(id, "")).find(law_query) < 0:
			vis = false
		if law_filter == 1 and cur == law_start_idx(id):
			vis = false
		elif law_filter == 2 and not dem.has(id):
			vis = false
		elif law_filter == 3 and not DE_OWN.has(id):
			vis = false
		elif law_filter == 4 and not bool(t.get("fund", false)):
			vis = false
		if bool(law_collapsed.get(ar, false)) and law_query == "" and law_filter == 0 and law_area_sel < 0:
			vis = false
		btn.visible = vis
		if vis:
			shown += 1
		area_shown[ar] = int(area_shown.get(ar, 0)) + (1 if vis else 0)
		var cd: int = int(law_cd.get(id, 0))
		var cur_name: String = variant_of(id, cur)["n"]
		var tag := ""
		if bool(t.get("fund", false)):
			tag += "◆ "
		if dem.has(id):
			tag += "★ "
		if DE_OWN.has(id):
			tag += "● "
		var acol := Color(LAW_AREA_COLORS[ar])
		if tiles:
			var short := cur_name if cur_name.length() <= 24 else cur_name.substr(0, 23) + "…"
			btn.text = "\n\n%s%s\n%s%s" % [tag, t["name"], "▸ " if cur > 0 else "", short]
			btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
			btn.custom_minimum_size = Vector2(80.0, 92.0)
		else:
			var line2 := ("▸ " + cur_name) if cur > 0 else ("— " + cur_name)
			if cd > 0:
				line2 += "   (ещё %d мес.)" % cd
			btn.text = "      %s%s\n      %s" % [tag, t["name"], line2]
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.custom_minimum_size = Vector2(0.0, 0.0)
		var ic: Control = law_icons.get(id)
		if ic != null:
			if tiles:
				ic.anchor_left = 0.5
				ic.anchor_right = 0.5
				ic.anchor_top = 0.0
				ic.anchor_bottom = 0.0
				ic.offset_left = -10.0
				ic.offset_right = 10.0
				ic.offset_top = 8.0
				ic.offset_bottom = 28.0
			else:
				ic.anchor_left = 0.0
				ic.anchor_right = 0.0
				ic.anchor_top = 0.5
				ic.anchor_bottom = 0.5
				ic.offset_left = 7.0
				ic.offset_right = 23.0
				ic.offset_top = -8.0
				ic.offset_bottom = 8.0
		btn.tooltip_text = ("◆ фундаментальный закон (две трети голосов)\n" if bool(t.get("fund", false)) else "") + (("★ требуют партии: %s\n" % ", ".join(PackedStringArray(dem[id]))) if dem.has(id) else "") + ("● закон именно этой страны\n" if DE_OWN.has(id) else "") + "Сейчас: %s" % cur_name
		btn.set_pressed_no_signal(id == sel_topic)
		if cur != law_start_idx(id):
			btn.add_theme_color_override("font_color", acol.lightened(0.25))
		else:
			btn.remove_theme_color_override("font_color")
	for sec in law_sections:
		var ar2: int = sec["area"]
		var grid: GridContainer = sec["grid"]
		grid.columns = cols
		var n_all: int = (sec["ids"] as Array).size()
		var n_ref := 0
		for id2 in sec["ids"]:
			if cur_idx(id2) != law_start_idx(id2):
				n_ref += 1
		var hb: Button = sec["hdr"]
		var shown_here: int = int(area_shown.get(ar2, 0))
		var collapsed: bool = bool(law_collapsed.get(ar2, false)) and law_query == "" and law_filter == 0 and law_area_sel < 0
		hb.text = "%s %s   %d · реформ %d" % ["▸" if collapsed else "▾", LAW_AREA_NAMES[ar2].to_upper(), n_all, n_ref]
		hb.visible = shown_here > 0 or collapsed
		hb.add_theme_color_override("font_color", Color(LAW_AREA_COLORS[ar2]))
		grid.visible = shown_here > 0
	update_law_headers()
	update_law_effects()
	update_law_detail()
	update_law_votes()


func update_law_effects() -> void:
	var t := ""
	for c in 3:
		var total := 0
		for tp in LAW_TOPICS:
			if int(tp["cat"]) == c:
				total += 1
		var row: Array = law_prog[c]
		(row[0] as Label).text = LAW_CATS[c]
		(row[1] as StatBar).set_state(float(law_reform_count(c)) * 100.0 / float(maxi(1, total)), 0.6)
		(row[2] as Label).text = "%d/%d" % [law_reform_count(c), total]
	var items: Array = []
	var lm := compute_mods(law_state, false)
	for key in MOD_INFO:
		if absf(float(lm[key]) - float(BASE_MODS[key])) > 0.00001:
			items.append(mod_item(key, BASE_MODS[key], lm[key]))
	if items.is_empty():
		t += "[color=%s]Пока все законы в действующем порядке. Каждый закон можно заменить другим вариантом.[/color]\n" % COL_DIM
	else:
		t += "[b]Накопленное влияние законов[/b] [color=%s](относительно исходного порядка)[/color]\n%s\n" % [COL_DIM, items_pros_cons(items)]
	var act: PackedStringArray = []
	for tp in LAW_TOPICS:
		var cur := cur_idx(tp["id"])
		if cur > 0:
			act.append("[color=%s]■[/color] %s: %s" % [LAW_CAT_COLORS[int(tp["cat"])], tp["name"], variant_of(tp["id"], cur)["n"]])
	if act.size() > 0:
		t += "\n[b]Действующие реформы[/b]\n" + "\n".join(act)
	law_effects_rt.text = t


func refit_law_cards() -> void:
	for card in law_cards:
		var fx: RichTextLabel = card["fx"]
		var tx := fx.text
		fx.text = ""
		fx.text = tx


func update_law_votes() -> void:
	if lv_bar == null:
		return
	var tid := sel_topic
	var idx := sel_variant
	var topic: Dictionary = law_index[tid]
	var vt := variant_votes(tid, idx)
	var need := law_need(tid, vt)
	var upc := upper_check(tid, idx)
	var ok: bool = int(vt["yes"]) >= need and not bool(upc["block"])
	lv_bar.marker = float(need) * 100.0 / float(SEATS)
	lv_head.text = "[b]%s[/b]%s\n[color=%s]%s → [/color][b]%s[/b]" % [topic["name"], " [color=%s](фундаментальный: %s)[/color]" % [COL_WARN, super_text()] if is_fund(tid) else "", COL_DIM, variant_of(tid, cur_idx(tid))["n"], variant_of(tid, idx)["n"]]
	lv_bar.set_state(float(vt["yes"]) * 100.0 / float(SEATS), 0.85 if ok else 0.08)
	lv_sum.text = "За %d · против %d · нужно %d" % [vt["yes"], vt["no"], need]
	if bool(vt.get("bypass", false)):
		lv_sum.text = "Принимается указом, без голосования. Позиции партий ниже — настоящие: они против, но не решают."
	if bool(upc["on"]):
		lv_sum.text += "\n" + upper_text(upc)
	var order: Array = []
	for p0 in PARTY_NAMES.size():
		order.append(p0)
	order.sort_custom(func(a, b): return int(seats[a]) > int(seats[b]))
	var base_i := 9999
	for rr in lv_rows:
		base_i = mini(base_i, (rr["row"] as Node).get_index())
	for k0 in order.size():
		var rw: Control = lv_rows[order[k0]]["row"]
		rw.get_parent().move_child(rw, base_i + k0)
	var verdicts := {}
	for it in vt["per"]:
		verdicts[int(it[0])] = it
	for p in PARTY_NAMES.size():
		var row: Dictionary = lv_rows[p]
		var has: bool = verdicts.has(p)
		(row["row"] as Control).visible = seats[p] > 0
		if seats[p] == 0:
			continue
		(row["name"] as Label).text = ("★ " if in_coalition[p] else "") + PARTY_NAMES[p]
		(row["name"] as Label).add_theme_color_override("font_color", (PARTY_COLORS[p] as Color).lightened(0.35))
		(row["seats"] as Label).text = "%d" % seats[p]
		var vl: Label = row["verdict"]
		if has:
			var it: Array = verdicts[p]
			# v51: фракция голосует не единогласно — показываем ожидаемых отступников
			var reb: int = 0
			if it.size() > 5:
				reb = (int(it[4]) + int(it[5])) if bool(it[2]) else (int(it[3]) + int(it[5]))
			var tail: String = (" (−%d)" % reb) if reb > 0 else ""
			if bool(it[2]):
				vl.text = "ЗА" + tail
				vl.add_theme_color_override("font_color", C_GOOD)
			elif float(it[1]) >= -4.5:
				vl.text = "колеблется" + tail
				vl.add_theme_color_override("font_color", C_WARN)
			else:
				vl.text = "ПРОТИВ" + tail
				vl.add_theme_color_override("font_color", C_BAD)
			vl.tooltip_text = ("Ожидается: за %d, против %d, воздержатся %d. Часть депутатов может нарушить дисциплину; итог голосования случаен в пределах нескольких голосов." % [int(it[3]), int(it[4]), int(it[5])]) if it.size() > 5 else ""
	var sw := {} if ok else variant_swing(tid, idx)
	lv_neg.visible = not sw.is_empty()
	if lv_neg.visible:
		var names: PackedStringArray = []
		for p in sw["parties"]:
			names.append(PARTY_NAMES[p])
		lv_neg.text = "Договориться: %s (капитал %.0f + закон %.0f)" % [", ".join(names), sw["cost"], law_cost(tid, idx)]
		lv_neg.disabled = game_over or int(law_cd.get(tid, 0)) > 0 or cap_spendable() < float(sw["cost"]) + law_cost(tid, idx)


func build_law_slider(parent: Control) -> void:
	law_slider_box = VBoxContainer.new()
	law_slider_box.add_theme_constant_override("separation", 4)
	parent.add_child(law_slider_box)
	law_slider_val = Label.new()
	law_slider_val.add_theme_font_size_override("font_size", 18)
	law_slider_val.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	law_slider_val.custom_minimum_size = Vector2(40.0, 0.0)
	law_slider_box.add_child(law_slider_val)
	law_slider = HSlider.new()
	law_slider.custom_minimum_size = Vector2(60.0, 26.0)
	law_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	law_slider.focus_mode = Control.FOCUS_NONE
	law_slider.step = 1.0
	law_slider.value_changed.connect(on_law_slider)
	law_slider_box.add_child(law_slider)
	law_slider_range = Label.new()
	law_slider_range.add_theme_font_size_override("font_size", 11)
	law_slider_range.add_theme_color_override("font_color", C_DIM)
	law_slider_range.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	law_slider_range.custom_minimum_size = Vector2(40.0, 0.0)
	law_slider_box.add_child(law_slider_range)
	law_slider_box.visible = false
	law_pow_box = VBoxContainer.new()
	law_pow_box.add_theme_constant_override("separation", 4)
	parent.add_child(law_pow_box)
	law_pow_lbl = Label.new()
	law_pow_lbl.add_theme_font_size_override("font_size", 15)
	law_pow_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	law_pow_lbl.custom_minimum_size = Vector2(40.0, 0.0)
	law_pow_box.add_child(law_pow_lbl)
	law_pow_slider = HSlider.new()
	law_pow_slider.custom_minimum_size = Vector2(60.0, 24.0)
	law_pow_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	law_pow_slider.focus_mode = Control.FOCUS_NONE
	law_pow_slider.min_value = 0.5
	law_pow_slider.max_value = 1.5
	law_pow_slider.step = 0.1
	law_pow_slider.value = 1.0
	law_pow_slider.tooltip_text = "Сила действия выбранного варианта: ниже — мягче эффекты и дешевле, выше — сильнее выгоды и издержки."
	law_pow_slider.value_changed.connect(on_law_pow)
	law_pow_box.add_child(law_pow_slider)
	var pn := Label.new()
	pn.text = "0.5× — мягко · 1.0× — как описано · 1.5× — жёстко. Меняет эффекты, цену и позиции партий."
	pn.add_theme_font_size_override("font_size", 11)
	pn.add_theme_color_override("font_color", C_DIM)
	pn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pn.custom_minimum_size = Vector2(40.0, 0.0)
	law_pow_box.add_child(pn)
	law_pow_box.visible = false


func on_law_pow(v: float) -> void:
	if law_slider_busy or not is_hybrid(sel_topic):
		return
	law_pow_sel[sel_topic] = snappedf(v, 0.1)
	update_law_windows()


func on_law_slider(v: float) -> void:
	if law_slider_busy:
		return
	var topic: Dictionary = law_index[sel_topic]
	if not topic.has("param"):
		return
	var grid: Array = topic["param"]["grid"]
	sel_variant = int(grid[clampi(int(v), 0, grid.size() - 1)])
	update_law_windows()


func build_law_list(tgrp: ButtonGroup) -> void:
	law_headers.clear()
	law_sections.clear()
	law_icons.clear()
	law_text_idx.clear()
	for t in LAW_TOPICS:
		var hay: String = String(t["name"]) + " " + String(t["desc"])
		for v in (t["v"] as Array):
			hay += " " + String(v["n"]) + " " + String(v.get("d", ""))
		law_text_idx[t["id"]] = hay.to_lower()
	for a in LAW_AREA_NAMES.size():
		var members: Array = []
		for t in LAW_TOPICS:
			if law_area(t["id"]) == a:
				members.append(t)
		if members.is_empty():
			continue
		var hb := Button.new()
		hb.theme_type_variation = "SmallButton"
		hb.flat = true
		hb.clip_text = true
		hb.focus_mode = Control.FOCUS_NONE
		hb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		hb.add_theme_font_size_override("font_size", 12)
		hb.pressed.connect(on_section_toggle.bind(a))
		hb.tooltip_text = "Нажмите, чтобы свернуть или развернуть область"
		law_list_box.add_child(hb)
		var grid := GridContainer.new()
		grid.columns = 1
		grid.add_theme_constant_override("h_separation", 4)
		grid.add_theme_constant_override("v_separation", 4)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		law_list_box.add_child(grid)
		var ids: Array = []
		for t in members:
			ids.append(t["id"])
			var b := Button.new()
			b.theme_type_variation = "TopicButton"
			b.toggle_mode = true
			b.button_group = tgrp
			b.focus_mode = Control.FOCUS_NONE
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.clip_text = true
			if "autowrap_mode" in b:
				b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.pressed.connect(on_topic_pressed.bind(t["id"]))
			grid.add_child(b)
			law_topic_buttons[t["id"]] = b
			# v50: значок закона
			var ic: Control = Ico.make(law_icon(t), Color(LAW_AREA_COLORS[a]).lightened(0.15), 16.0)
			ic.anchor_top = 0.5
			ic.anchor_bottom = 0.5
			ic.offset_left = 7.0
			ic.offset_right = 23.0
			ic.offset_top = -8.0
			ic.offset_bottom = 8.0
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(ic)
			law_icons[t["id"]] = ic
		law_sections.append({"area": a, "hdr": hb, "grid": grid, "ids": ids})


# v50: значок закона — по ключевым словам названия и кода, иначе по сфере
const LAW_ICON_KEYS := [
	["налог|tax|ндс|vat|акциз", "coin"], ["пенси|pens", "person"], ["здрав|health|мед|больн|аборт|эвтан", "people"],
	["образ|школ|edu|универ|наук", "flask"], ["арми|оборон|воен|призыв|army|draft|nato|нато", "shield"],
	["полиц|police|безопас|оружи|gun|тюрьм|наказ|смерт", "shield"], ["сми|медиа|media|пресс|интернет|цензур", "scroll"],
	["выбор|elect|голос|референд|партий|vote", "ballot"], ["суд|court|конституц|прав|const", "hall"],
	["мигра|migr|граждан|убежищ|границ", "globe"], ["религ|церк|faith|relig|вер", "faith"], ["энерг|energy|климат|climate|атом|уголь|газ", "energy"],
	["торг|trade|тариф|tariff|таможн|санкц", "tariff"], ["банк|bank|финанс|долг|debt|бюджет|валют|евро", "bank"],
	["труд|работ|labor|зарплат|wage|профсоюз|забастов", "work"], ["регион|автоном|федер|region|местн", "map"],
	["эколог|environ|природ|лес|отход", "globe"], ["жиль|housing|аренд|ипотек", "hall"], ["семь|брак|family|дет|материн", "people"],
	["нарко|drug|алкогол|табак", "warn"], ["сельск|аграр|farm|agri|земл", "box"], ["транспорт|дорог|transport|желез", "grid"],
	["собствен|property|приватиз|национализ|рынок|market", "handshake"], ["пособ|social|бедн|безработ|минимал", "person"],
	["монарх|президент|президен|король|глава", "crown"], ["ес\b|евросоюз|\beu\b|союз", "star"],
]


func law_icon(t: Dictionary) -> String:
	var hay: String = (String(t["id"]) + " " + String(t["name"])).to_lower()
	for kv in LAW_ICON_KEYS:
		var re := RegEx.new()
		re.compile(String(kv[0]))
		if re.search(hay) != null:
			return String(kv[1])
	return ["hall", "chart", "people"][clampi(int(t["cat"]), 0, 2)]


func update_law_headers() -> void:
	pass


func update_law_detail() -> void:
	var tid := sel_topic
	var topic: Dictionary = law_index[tid]
	var is_param: bool = topic.has("param")
	var cur := cur_idx(tid)
	var cd: int = int(law_cd.get(tid, 0))
	var vars: Array = topic["v"]
	var need := law_need(tid)
	var t := "[b][font_size=19]%s[/font_size][/b]   [color=%s]%s[/color]\n[color=%s]%s[/color]\nСейчас действует: [b]%s[/b]" % [
		topic["name"], LAW_CAT_COLORS[int(topic["cat"])], LAW_CATS[int(topic["cat"])].to_lower(), COL_DIM, topic["desc"], variant_of(tid, cur)["n"]]
	if is_fund(tid):
		t += "\n[color=%s][b]Фундаментальный закон:[/b] для изменения нужно %d голосов из %d (%s). Смена обходится дороже, а следующую можно проводить не раньше чем через 2 года.[/color]" % [COL_WARN, need, SEATS, super_text()]
	if cd > 0:
		t += "\n[color=%s]Закон недавно меняли: следующая смена возможна через %s.[/color]" % [COL_WARN, months_text(cd)]
	var pst := param_scale_text(tid)
	if pst != "":
		t += "\n" + pst
	elif not is_param:
		t += "\n[color=%s]Щёлкните по варианту, чтобы увидеть, как за него проголосует парламент.[/color]" % COL_FAINT_HEX
	law_detail_head.text = t
	# ползунок силы действия (гибридные законы)
	var hyb: bool = is_hybrid(tid) and sel_variant > 0
	var skey := "%s:%d" % [tid, sel_variant]
	if skey != law_sel_key:
		law_sel_key = skey
		law_pow_sel[tid] = float(law_pow.get(tid, 1.0)) if sel_variant == cur else 1.0
	law_pow_box.visible = hyb
	if hyb:
		law_slider_busy = true
		law_pow_slider.value = pw_of(tid, true)
		law_slider_busy = false
		law_pow_lbl.text = "Сила действия: %.1f×%s" % [pw_of(tid, true), ("  (сейчас %.1f×)" % pw_of(tid)) if sel_variant == cur else ""]
	# ползунок
	law_slider_box.visible = is_param
	if is_param:
		var pr: Dictionary = topic["param"]
		var grid: Array = pr["grid"]
		var pos := 0
		for k in grid.size():
			if int(grid[k]) == sel_variant:
				pos = k
		law_slider_busy = true
		law_slider.min_value = 0.0
		law_slider.max_value = float(grid.size() - 1)
		law_slider.value = float(pos)
		law_slider_busy = false
		var sv: Dictionary = variant_of(tid, sel_variant)
		var cv: Dictionary = variant_of(tid, cur)
		law_slider_val.text = "Выбрано: %s" % fmt_param(pr, float(sv["val"]))
		law_slider_val.add_theme_color_override("font_color", C_GOOD if sel_variant == cur else C_ACCENT)
		law_slider_range.text = "от %s до %s (сейчас %s)" % [fmt_param(pr, float(pr["lo"])), fmt_param(pr, float(pr["hi"])), fmt_param(pr, float(cv["val"]))]
	# 0.60: шкала вариантов (точки на линии), рядом ниже — карточки
	var labs: PackedStringArray = []
	var tps: PackedStringArray = []
	var cur_pos := cur
	var sel_pos := sel_variant
	law_scale_map = []
	if is_param:
		var pr2: Dictionary = topic["param"]
		var grid2: Array = pr2["grid"]
		var stride: int = maxi(1, int(ceil(float(grid2.size()) / 7.0)))
		var gcur := 0
		var gsel := 0
		for k in grid2.size():
			if int(grid2[k]) == cur:
				gcur = k
			if int(grid2[k]) == sel_variant:
				gsel = k
		var picks: Array = []
		for k in range(0, grid2.size(), stride):
			picks.append(k)
		if not picks.has(grid2.size() - 1):
			picks.append(grid2.size() - 1)
		if not picks.has(gcur):
			picks.append(gcur)
		picks.sort()
		for k in picks:
			law_scale_map.append(k)
			var vv: Dictionary = variant_of(tid, int(grid2[k]))
			labs.append(fmt_param(pr2, float(vv["val"])))
			tps.append(fmt_param(pr2, float(vv["val"])))
			if k == gcur:
				cur_pos = labs.size() - 1
			if k == gsel:
				sel_pos = labs.size() - 1
	else:
		for k in vars.size():
			labs.append(String(vars[k]["n"]))
			tps.append("%d. %s — %s" % [k + 1, vars[k]["n"], vars[k].get("d", "")])
	(law_scale as LawScale).set_stops(labs, tps, cur_pos, sel_pos)
	for i in law_cards.size():
		var card: Dictionary = law_cards[i]
		var panel: PanelContainer = card["panel"]
		var vi: int = i
		if is_param:
			vi = sel_variant
			panel.visible = i == 0
		else:
			panel.visible = i < vars.size()
		if not panel.visible:
			continue
		var v: Dictionary = vars[vi]
		var is_cur: bool = vi == cur
		var tweak: bool = is_cur and law_tweak(tid)
		if tweak:
			is_cur = false
		var selected: bool = vi == sel_variant and not is_cur
		var border: Color = C_ACCENT if selected else (C_GOOD.darkened(0.2) if is_cur else C_BORDER)
		panel.add_theme_stylebox_override("panel", sbox(C_PANEL2.lerp(C_ACCENT, 0.10) if selected else C_PANEL2, border, 2 if (selected or is_cur) else 1, 9, 10.0, 8.0))
		(card["title"] as Label).text = String(v["n"]) if is_param else "%d. %s" % [vi + 1, v["n"]]
		var badge: Label = card["badge"]
		badge.text = "ДЕЙСТВУЕТ" if (is_cur or tweak) else ("ВЫБРАН ДЛЯ ГОЛОСОВАНИЯ" if selected else "")
		badge.add_theme_color_override("font_color", C_GOOD if is_cur else C_ACCENT)
		(card["desc"] as Label).text = v["d"]
		var fx: RichTextLabel = card["fx"]
		var vote: Label = card["vote"]
		var btn: Button = card["btn"]
		var bar: StatBar = card["bar"]
		var expanded: bool = is_param or selected or is_cur
		(card["desc"] as Control).visible = expanded
		fx.visible = expanded
		btn.visible = expanded
		if is_cur:
			var own: Array = variant_own_items(tid, vi)
			fx.text = ("[font_size=13][color=%s]Пока действует, даёт:[/color]\n%s[/font_size]" % [COL_DIM, items_pros_cons(own)]) if own.size() > 0 else ""
			fx.visible = own.size() > 0
			vote.text = ""
			vote.visible = false
			bar.visible = false
			(card["meta"] as RichTextLabel).visible = false
			btn.text = ("Действует · силу можно изменить ползунком выше" if (is_hybrid(tid) and vi > 0) else "Действует сейчас") if not is_param else "Это нынешнее значение — сдвиньте ползунок"
			btn.disabled = true
			continue
		vote.visible = true
		bar.visible = true
		fx.text = "[font_size=13]%s[/font_size]" % items_pros_cons(variant_effect_items(tid, vi))
		var vt := variant_votes(tid, vi)
		var meta: RichTextLabel = card["meta"]
		meta.visible = expanded
		meta.text = law_card_meta(tid, vi, vt, need)
		var upc := upper_check(tid, vi)
		var ok_low: bool = int(vt["yes"]) >= need
		var ok: bool = ok_low and not bool(upc["block"])
		bar.marker = float(need) * 100.0 / float(SEATS)
		bar.set_state(float(vt["yes"]) * 100.0 / float(SEATS), 0.85 if ok else 0.08)
		vote.text = "Голосование: за %d, против %d (нужно %d) — %s" % [vt["yes"], vt["no"], need, "пройдёт" if ok else "не пройдёт"]
		if radical_bypass(tid, vi):
			vote.text = "Голосование не требуется: решение принимается указом, без парламента и верхней палаты."
		if bool(upc["on"]):
			vote.text += "\n" + upper_text(upc)
		vote.add_theme_color_override("font_color", C_GOOD if ok else C_BAD)
		var cost := law_cost(tid, vi)
		var lk2 := law_locked(tid)
		var rq2 := radical_req(tid, vi)
		if lk2 != "":
			btn.text = lk2
			btn.disabled = true
		elif rq2 != "":
			btn.text = rq2
			btn.disabled = true
		elif cd > 0:
			btn.text = "Менять закон можно через %s" % months_text(cd)
			btn.disabled = true
		elif ok_low and not ok:
			btn.text = "Верхняя палата заблокирует закон"
			btn.disabled = true
		elif not ok:
			btn.text = "Нет нужного числа голосов: нужны переговоры (справа)" if not variant_swing(tid, vi).is_empty() else "Нет нужного числа голосов: парламент не поддержит"
			btn.disabled = true
		else:
			btn.text = ("Внести законопроект (политкапитал %.0f)" if vi > 0 else "Вернуть действующий порядок (политкапитал %.0f)") % cost
			if tweak:
				btn.text = "Изменить силу действия до %.1f× (политкапитал %.0f)" % [pw_of(tid, true), cost]
			btn.disabled = game_over or cap_spendable() < cost + float(upc["extra"])
	call_deferred("refit_law_cards")

# число колонок плиток подгоняется под ширину окна
func on_law_list_resized() -> void:
	if law_list_box == null:
		return
	var cols: int = maxi(2, int(law_list_box.size.x / 112.0)) if law_view == 1 else 1
	for sec in law_sections:
		var grid: GridContainer = sec["grid"]
		if grid.columns != cols:
			grid.columns = cols
