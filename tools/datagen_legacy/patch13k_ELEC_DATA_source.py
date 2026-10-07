# --- K (v18): профили выборов по странам, окно президентских выборов, новый полукруг парламента ---

# ---------- переменные ----------
rep('var last_pres := 0\n', '''var last_pres := 0
var ELEC := {}               # профиль выборов текущей страны (ELEC_DATA)
var pres_due := -1           # номер хода, когда выбирают главу государства (-1 — не предвидится)
var pres_camp := 0.0         # бонус вашему кандидату от кампании
var pres_camp_done := -100
var pres_party := -1         # партия действующего президента (если выбран на выборах в игре)
var hemi_rad := 0.036
var el_head
''')

# ---------- apply_country: профиль выборов ----------
rep('''	last_parl = -int(mc["elapsed"])
''', '''	last_parl = -int(mc["elapsed"])
	ELEC = (ELEC_DATA[code] if ELEC_DATA.has(code) else ELEC_DATA["DE"]).duplicate(true)
	pres_party = -1
	pres_camp = 0.0
	pres_camp_done = -100
	pres_due = -1
	var hk: String = String(ELEC["head"])
	if hk == "direct" or hk == "indirect":
		pres_due = int(ELEC["first"])
	elif hk == "council":
		pres_due = -int(mc["elapsed"]) + int(mc["parl_term"]) + 2
''')

# ---------- ход: выборы главы государства ----------
rep('''	# --- события ---
	campaign_check()
''', '''	if pres_due >= 0 and turn >= pres_due and not election_open and current_event.is_empty():
		hold_head("плановые выборы")
	if game_over:
		return

	# --- события ---
	campaign_check()
	head_campaign_check()
''')

rep('''	last_parl = turn
	crisis_months = 0
	impeach_warned = false
''', '''	last_parl = turn
	if String(ELEC.get("head", "")) == "council":
		pres_due = turn + 2
	crisis_months = 0
	impeach_warned = false
''')

# ---------- эффекты: кампания кандидата ----------
rep('''	if fx.has("capital"):
		capital = clampf(capital + float(fx["capital"]), 0.0, 100.0)
	if fx.has("reg") and rid >= 0:
		apply_reg_delta(rid, fx["reg"])''', '''	if fx.has("capital"):
		capital = clampf(capital + float(fx["capital"]), 0.0, 100.0)
	if fx.has("pcamp"):
		pres_camp += float(fx["pcamp"])
	if fx.has("reg") and rid >= 0:
		apply_reg_delta(rid, fx["reg"])''')
rep('''	if fx.has("capital"):
		out.append(["политкапитал %s" % sg(fx["capital"], 0), 1 if float(fx["capital"]) > 0.0 else -1])
''', '''	if fx.has("capital"):
		out.append(["политкапитал %s" % sg(fx["capital"], 0), 1 if float(fx["capital"]) > 0.0 else -1])
	if fx.has("pcamp"):
		out.append(["шансы вашего кандидата %s" % sg(float(fx["pcamp"]) * 100.0, 0), 1 if float(fx["pcamp"]) > 0.0 else -1])
''')
rep('''	if String(e.get("kind", "")) == "campaign":
		return ["ПРЕДВЫБОРНАЯ КАМПАНИЯ", "★", Color(1.0, 0.82, 0.40)]''', '''	if String(e.get("kind", "")) == "campaign":
		return ["ПРЕДВЫБОРНАЯ КАМПАНИЯ", "★", Color(1.0, 0.82, 0.40)]
	if String(e.get("kind", "")) == "pcampaign":
		return ["ВЫБОРЫ ГЛАВЫ ГОСУДАРСТВА", "★", Color(1.0, 0.82, 0.40)]''')

# ---------- полукруг парламента ----------
rep_between('func build_hemicycle() -> void:', '''# ============================================================
#  ЭФФЕКТЫ (дополнено''', '''func build_hemicycle() -> void:
	var lay: Dictionary = ElectionView.hemi_layout(SEATS)
	hemi_pos = lay["pts"]
	hemi_rad = float(lay["rad"])


''')
rep('	var dot: float = clampf(R * 0.036, 2.5, 12.0)\n', '	var dot: float = clampf(R * hemi_rad, 1.6, 12.0)\n')

# ---------- ElectionView: полукруг вместо полосы мест ----------
rep('''	var progress := 0.0
	const ROW_H := 27.0

	func _init() -> void:
		custom_minimum_size = Vector2(320.0, 120.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_data(r: Array, o: Array, t: float, tot: int, m: int) -> void:
		rows = r
		order = o
		thr = t
		total = tot
		maj = m
		custom_minimum_size.y = float(rows.size()) * ROW_H + 112.0
		queue_redraw()
''', '''	var progress := 0.0
	var ctr_big := ""
	var ctr_small := ""
	var ctr_col := Color(1, 1, 1)
	var lay: Dictionary = {}
	var lay_total := -1
	const ROW_H := 27.0
	const HEMI_H := 210.0

	func _init() -> void:
		custom_minimum_size = Vector2(320.0, 120.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	static func hemi_layout(total: int) -> Dictionary:
		var r0 := 0.40
		var rows_n := 3
		for k in range(3, 24):
			rows_n = k
			var dd: float = (1.0 - r0) / float(k - 1)
			var est: float = PI * float(k) * (1.0 + r0) * 0.5 / dd
			if est >= float(total):
				break
		var d: float = (1.0 - r0) / float(rows_n - 1)
		var radii: Array = []
		var tot_r := 0.0
		for k in rows_n:
			var rr: float = r0 + d * float(k)
			radii.append(rr)
			tot_r += rr
		var counts: Array = []
		var assigned := 0
		for k in rows_n:
			var n: int = int(round(float(total) * float(radii[k]) / tot_r))
			counts.append(n)
			assigned += n
		counts[rows_n - 1] = int(counts[rows_n - 1]) + total - assigned
		var pts: Array = []
		for k in rows_n:
			var n2: int = counts[k]
			for i in n2:
				var ang: float = PI * (1.0 - (float(i) + 0.5) / float(n2))
				pts.append([ang, float(radii[k])])
		pts.sort_custom(func(a, b):
			if absf(float(a[0]) - float(b[0])) > 0.0001:
				return float(a[0]) > float(b[0])
			return float(a[1]) < float(b[1]))
		var arc_sp: float = PI * tot_r / float(total)
		return {"pts": pts, "rad": minf(d, arc_sp) * 0.5 * 0.92, "rows": rows_n}

	func set_data(r: Array, o: Array, t: float, tot: int, m: int, cb: String = "", cs: String = "", cc: Color = Color(1, 1, 1)) -> void:
		rows = r
		order = o
		thr = t
		total = tot
		maj = m
		ctr_big = cb
		ctr_small = cs
		ctr_col = cc
		update_minimum_size()
		queue_redraw()

	func _get_minimum_size() -> Vector2:
		var h: float = float(rows.size()) * ROW_H + 40.0
		if size.x >= 780.0:
			h = maxf(h, HEMI_H + 12.0)
		else:
			h += HEMI_H
		return Vector2(320.0, h)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			update_minimum_size()
''')

rep_between('		# полоса мест\n', 'class FloatWindow extends Control:', '''		# полукруг парламента
		var hx0 := 0.0
		var hw: float = FW
		var ys: float = float(rows.size()) * ROW_H + 30.0
		if side:
			hx0 = W + 10.0
			hw = FW - hx0
			ys = 14.0
		draw_string(f, Vector2(hx0 + 4.0, ys), "Парламент: %d мест" % total, HORIZONTAL_ALIGNMENT_LEFT, hw - 8.0, 13, Color(0.6, 0.63, 0.72))
		var Rr: float = minf(hw * 0.46, HEMI_H - 28.0)
		var cc := Vector2(hx0 + hw / 2.0, ys + HEMI_H - 8.0)
		if lay_total != total:
			lay = hemi_layout(total)
			lay_total = total
		var pts: Array = lay["pts"]
		var dot: float = maxf(1.6, Rr * float(lay["rad"]))
		var seat_o: Array = []
		for o in order:
			for k in int(o["seats"]):
				seat_o.append(o)
		var shown: int = int(round(float(total) * e))
		draw_arc(cc, Rr * 1.07, PI, TAU, 64, Color(1, 1, 1, 0.10), 1.5)
		for i in pts.size():
			var a: float = pts[i][0]
			var rr: float = pts[i][1]
			var pos: Vector2 = cc + Vector2(cos(a), -sin(a)) * (Rr * rr)
			if i < shown and i < seat_o.size():
				var so: Dictionary = seat_o[i]
				var scol: Color = so["col"]
				var inc: bool = bool(so.get("gov", false))
				draw_circle(pos, dot, scol if inc else scol.darkened(0.4))
				if inc:
					draw_arc(pos, dot + 0.5, 0.0, TAU, 12, Color(1, 1, 1, 0.85), 1.2)
			else:
				draw_circle(pos, dot * 0.55, Color(1, 1, 1, 0.08))
		if ctr_big != "":
			draw_string(f, cc + Vector2(-80.0, -Rr * 0.16), ctr_big, HORIZONTAL_ALIGNMENT_CENTER, 160.0, 28, ctr_col)
			draw_string(f, cc + Vector2(-110.0, -Rr * 0.16 + 20.0), ctr_small, HORIZONTAL_ALIGNMENT_CENTER, 220.0, 13, Color(0.8, 0.82, 0.9))


''')

# ---------- HeadView: окно выборов главы государства ----------
rep('class FloatWindow extends Control:', r'''class HeadView extends Control:
	var rounds: Array = []        # {title, need, need_text, rows: [{name, sub, col, val, win, out, note, lab}]}
	var progress := 0.0
	const ROW_H := 40.0
	const HEAD_H := 28.0

	func _init() -> void:
		custom_minimum_size = Vector2(320.0, 160.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_data(r: Array) -> void:
		rounds = r
		var h := 6.0
		for rd in rounds:
			h += HEAD_H + float((rd["rows"] as Array).size()) * ROW_H + 8.0
		custom_minimum_size.y = h
		queue_redraw()

	func set_progress(v: float) -> void:
		progress = v
		queue_redraw()

	func _draw() -> void:
		var f: Font = get_theme_default_font()
		var W: float = size.x
		var n: int = rounds.size()
		var y := 4.0
		var gold := Color(1.0, 0.82, 0.40)
		for ri in n:
			var rd: Dictionary = rounds[ri]
			var er: float = clampf(progress * float(n) - float(ri), 0.0, 1.0)
			var e: float = 1.0 - pow(1.0 - er, 3.0)
			var ha: float = 1.0 if er > 0.0 else 0.3
			draw_string(f, Vector2(6.0, y + 20.0), String(rd["title"]), HORIZONTAL_ALIGNMENT_LEFT, W * 0.55, 15, Color(0.78, 0.84, 1.0, ha))
			var ntxt: String = String(rd.get("need_text", ""))
			if ntxt != "":
				draw_string(f, Vector2(W * 0.45, y + 20.0), ntxt, HORIZONTAL_ALIGNMENT_RIGHT, W * 0.55 - 6.0, 12, Color(0.6, 0.63, 0.72, ha))
			draw_line(Vector2(0.0, y + HEAD_H - 3.0), Vector2(W, y + HEAD_H - 3.0), Color(1, 1, 1, 0.12), 1.0)
			y += HEAD_H
			var rows: Array = rd["rows"]
			var need: float = float(rd.get("need", 0.0))
			var mx := 0.3
			for r in rows:
				mx = maxf(mx, float(r["val"]))
			mx = maxf(mx, need * 1.04)
			var name_w: float = clampf(W * 0.40, 150.0, 300.0)
			var bx: float = name_w + 10.0
			var lab_w := 118.0
			var bw: float = maxf(40.0, W - bx - lab_w - 6.0)
			var sc: float = bw / (mx * 1.1)
			for i in rows.size():
				var r: Dictionary = rows[i]
				var col: Color = r["col"]
				var win: bool = bool(r.get("win", false))
				var out: bool = bool(r.get("out", false))
				var dim := 0.45 if out else 1.0
				dim *= ha
				var ry: float = y + float(i) * ROW_H
				if i % 2 == 0:
					draw_rect(Rect2(0.0, ry, W, ROW_H), Color(1, 1, 1, 0.03))
				if win and er >= 1.0:
					draw_rect(Rect2(0.0, ry, W, ROW_H), Color(gold.r, gold.g, gold.b, 0.11))
					draw_rect(Rect2(0.0, ry, 3.0, ROW_H), gold)
				var cen := Vector2(26.0, ry + ROW_H * 0.5)
				draw_circle(cen, 15.0, Color(col.r, col.g, col.b, dim))
				if win and er >= 1.0:
					draw_arc(cen, 17.0, 0.0, TAU, 28, gold, 2.2)
				var ch: String = String(r["name"]).substr(0, 1)
				var icol := Color(0.07, 0.08, 0.12, dim) if col.get_luminance() > 0.5 else Color(1, 1, 1, dim)
				draw_string(f, Vector2(cen.x - 8.0, cen.y + 6.0), ch, HORIZONTAL_ALIGNMENT_CENTER, 16.0, 17, icol)
				var tcol := Color(0.93, 0.95, 1.0, dim) if not bool(r.get("you", false)) else Color(1.0, 0.85, 0.45, dim)
				draw_string(f, Vector2(48.0, ry + 18.0), String(r["name"]), HORIZONTAL_ALIGNMENT_LEFT, name_w - 50.0, 15, tcol)
				draw_string(f, Vector2(48.0, ry + 33.0), String(r["sub"]), HORIZONTAL_ALIGNMENT_LEFT, name_w - 50.0, 12, Color(0.6, 0.63, 0.72, dim))
				draw_rect(Rect2(bx, ry + 12.0, bw, 16.0), Color(0.055, 0.067, 0.098, ha))
				var fw: float = float(r["val"]) * sc * e
				if fw > 0.5:
					draw_rect(Rect2(bx, ry + 12.0, fw, 16.0), Color(col.r, col.g, col.b, dim))
				if need > 0.0:
					var nx: float = bx + need * sc
					draw_line(Vector2(nx, ry + 8.0), Vector2(nx, ry + ROW_H - 8.0), Color(1, 1, 1, 0.5 * ha), 1.5)
				var lab: String = ("%.1f%%" % (float(r["val"]) * 100.0 * e)) if not r.has("lab") else (String(r["lab"]) if e >= 0.99 else "")
				draw_string(f, Vector2(bx + bw + 8.0, ry + 23.0), lab, HORIZONTAL_ALIGNMENT_LEFT, lab_w - 8.0, 15, Color(0.93, 0.95, 1.0, dim))
				var nt: String = String(r.get("note", ""))
				if win and er >= 1.0:
					nt = "ИЗБРАН"
				if nt != "" and er >= 1.0:
					draw_string(f, Vector2(bx + bw + 8.0, ry + 36.0), nt, HORIZONTAL_ALIGNMENT_LEFT, lab_w - 8.0, 11, gold if win else Color(0.6, 0.63, 0.72, dim))
			y += float(rows.size()) * ROW_H + 8.0


class FloatWindow extends Control:''')

# ---------- окно выборов: добавляем HeadView ----------
rep('''	w.body.add_child(el_view)
	el_verdict_box = PanelContainer.new()''', '''	w.body.add_child(el_view)
	el_head = HeadView.new()
	el_head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	el_head.visible = false
	w.body.add_child(el_head)
	el_verdict_box = PanelContainer.new()''')

# ---------- парламентские выборы: профиль страны ----------
rep('''		if seats[p] > 0:
			order.append({"col": PARTY_COLORS[p], "seats": seats[p]})
	el_view.set_data(rows, order, thr, SEATS, MAJORITY)''', '''		if seats[p] > 0:
			order.append({"col": PARTY_COLORS[p], "seats": seats[p], "gov": p == 0 or in_coalition[p]})
	el_view.visible = true
	el_head.visible = false
	var cst: String = String(rep["state"])
	el_view.set_data(rows, order, thr, SEATS, MAJORITY, "%d" % gov_seats(), "коалиция · нужно %d из %d" % [MAJORITY, SEATS], C_GOOD if cst == "gov" else (C_WARN if cst == "crisis" else C_BAD))''')

rep('''	var turnout: float = clampf(0.58 + 0.14 * democracy_index() + (reg_avg("unrest") - 20.0) * 0.002 + randf_range(-0.02, 0.02), 0.35, 0.92)''',
'''	var turnout: float = clampf(float(ELEC.get("turn", 0.7)) + 0.12 * (democracy_index() - 0.8) + (reg_avg("unrest") - 20.0) * 0.002 + randf_range(-0.02, 0.02), 0.3, 0.95)''')

rep('''	el_meta.text = loc("Пропорциональная система, барьер %.0f%%, %d мест. Явка %.0f%%. ★ — партии вашей коалиции." % [thr * 100.0, SEATS, turnout * 100.0])''',
'''	var mt: String = String(ELEC.get("sys", "Пропорциональная система")) + ". "
	if thr >= 0.005:
		mt += "Барьер %.0f%%, " % (thr * 100.0)
	mt += "%d мест. Явка %.0f%%." % [SEATS, turnout * 100.0]
	if String(ELEC.get("note", "")) != "":
		mt += " " + String(ELEC["note"])
	var hk: String = String(ELEC.get("head", "none"))
	if (hk == "direct" or hk == "indirect") and pres_due > turn:
		mt += " Следующие выборы %s — %s." % [String(ELEC["title"]), turn_date(pres_due)]
	mt += "  ★ — партии вашей коалиции."
	el_meta.text = loc(mt)''')

# ---------- выборы главы государства ----------
rep_between('func hold_presidential(reason: String) -> void:', 'func hold_parliament(reason: String) -> void:', r'''func turn_date(t: int) -> String:
	var idx: int = year * 12 + (month - 1) + (t - turn)
	return "%s %d" % [MONTHS[idx % 12], idx / 12]


func head_cand_ok(p: int) -> bool:
	if p == 0:
		return true
	var s: String = String(PARTY_LEADERS[p])
	return s != "—" and s != ""


func head_cand_name(p: int) -> String:
	if p == 0:
		return String(ELEC.get("cand0", "Кандидат вашей партии"))
	return String(PARTY_LEADERS[p]).replace(" (вы)", "")


func head_row(p: int, val: float, win: bool, out: bool, note: String) -> Dictionary:
	return {"name": head_cand_name(p), "sub": PARTY_NAMES[p], "col": PARTY_COLORS[p], "val": val, "win": win, "out": out, "note": note, "you": p == 0}


func head_term_months() -> int:
	var t: int = int(ELEC["term"])
	var m: int = int(mods.get("pres_term", 60))
	if m != 60:
		t = m
	return t


func hold_head(reason: String) -> void:
	var kind: String = String(ELEC.get("head", "none"))
	if kind == "direct":
		hold_head_direct(reason)
	elif kind == "indirect":
		hold_head_indirect(reason)
	elif kind == "council":
		hold_head_council(reason)
	else:
		pres_due = -1
		return
	if kind == "council":
		pres_due = -1
	else:
		pres_due = turn + head_term_months()
	pres_camp = 0.0
	for p in charisma.size():
		charisma[p] = 1.0


# итог выборов главы государства: возвращает [заголовок, цвет, текст]
func head_outcome(w: int) -> Array:
	pres_party = w
	if String(UPPER.get("kind", "")) == "veto":
		UPPER["veto_p"] = w
	var tt: String = String(ELEC["title_n"])
	var nm: String = head_cand_name(w)
	var vt := ""
	var vc: Color = C_GOOD
	var t := ""
	if w == 0:
		vt = "Ваш кандидат избран"
		capital = clampf(capital + 8.0, 0.0, 100.0)
		add_all_support(1.5)
		t = "%s: [b]%s[/b] — человек вашего лагеря. У вас союзник на посту главы государства. Политкапитал +8." % [tt, nm]
	elif in_coalition[w]:
		vt = "Избран кандидат партнёра по коалиции"
		capital = clampf(capital + 4.0, 0.0, 100.0)
		add_all_support(0.5)
		t = "%s: [b]%s[/b] («%s»), партнёр по вашей коалиции. Отношения с главой государства дружественные. Политкапитал +4." % [tt, nm, PARTY_NAMES[w]]
	else:
		vt = "Избран оппонент: придётся сотрудничать"
		vc = C_WARN
		capital = clampf(capital - 8.0, 0.0, 100.0)
		add_all_support(-1.0)
		t = "%s: [b]%s[/b] («%s»), политический оппонент. Правительству придётся работать с неприязненным главой государства. Политкапитал -8." % [tt, nm, PARTY_NAMES[w]]
	if String(UPPER.get("kind", "")) == "veto":
		t += "\nНовый президент блокирует законы линией партии «%s»: вето теперь работает в её интересах." % PARTY_NAMES[w]
	return [vt, vc, t]


func head_present(rep: Dictionary) -> void:
	log_header(String(rep["title"]) + " — " + date_text(), COL_ELECT)
	log_line(String(rep["log"]))
	show_head_election(rep)
	if not game_over:
		refresh()


func hold_head_direct(reason: String) -> void:
	var n: int = PARTY_NAMES.size()
	var sham: bool = decree_power()
	for p in n:
		charisma[p] = randf_range(0.85, 1.2) if p != 0 else 1.0 + pres_camp
	var cands: Array = []
	for p in n:
		if head_cand_ok(p):
			cands.append(p)
	var s1: Array[float] = []
	if sham:
		var base := sham_shares(national_shares(true))
		var tot := 0.0
		for p in n:
			if p in cands:
				tot += base[p]
		for p in n:
			s1.append(base[p] / tot if p in cands else 0.0)
	else:
		s1 = national_shares(true, cands)
	var order: Array = cands.duplicate()
	order.sort_custom(func(a, b): return s1[a] > s1[b])
	var runoff: bool = float(s1[order[0]]) <= 0.5
	var winner: int = order[0]
	var rounds: Array = []
	var rows1: Array = []
	for i in mini(5, order.size()):
		var p: int = order[i]
		if runoff:
			rows1.append(head_row(p, s1[p], false, i >= 2, "во 2-й тур" if i < 2 else "выбыл"))
		else:
			rows1.append(head_row(p, s1[p], i == 0, false, ""))
	rounds.append({"title": "1-й тур · кандидатов: %d" % cands.size(), "need": 0.5, "need_text": "для победы нужно больше 50%", "rows": rows1})
	var logt := "Первый тур: " + "; ".join(PackedStringArray([
		"%s %.1f%%" % [PARTY_NAMES[order[0]], s1[order[0]] * 100.0], "%s %.1f%%" % [PARTY_NAMES[order[1]], s1[order[1]] * 100.0]]))
	if runoff:
		var a: int = order[0]
		var b: int = order[1]
		var s2 := national_shares(true, [a, b])
		var ma: float = 0.5 + (s2[a] - 0.5) * 0.6
		s2[a] = ma
		s2[b] = 1.0 - ma
		winner = a if s2[a] > s2[b] else b
		rounds.append({"title": "2-й тур", "need": 0.5, "need_text": "побеждает набравший больше половины", "rows": [
			head_row(a, s2[a], winner == a, false, ""), head_row(b, s2[b], winner == b, false, "")]})
		logt += ". Второй тур: %.1f%% против %.1f%%" % [s2[a] * 100.0, s2[b] * 100.0]
	var out: Array = head_outcome(winner)
	var rep := {"title": "ВЫБОРЫ " + String(ELEC["title"]).to_upper() if not sham else "ВЫБОРЫ БЕЗ ВЫБОРА", "reason": reason, "rounds": rounds, "sham": sham,
		"meta": "Прямое голосование, два тура: во второй выходят двое лучших. Срок полномочий — %d лет. Следующие выборы — %s." % [head_term_months() / 12, turn_date(turn + head_term_months())],
		"vtitle": out[0], "vcol": out[1], "vtext": out[2], "end": "", "log": logt + ". Победил: %s." % head_cand_name(winner)}
	head_present(rep)


func hold_head_indirect(reason: String) -> void:
	var n: int = PARTY_NAMES.size()
	var sham: bool = decree_power()
	var tot_s := 0
	for p in n:
		tot_s += seats[p]
	tot_s = maxi(tot_s, 1)
	var camp: Array = []
	var best := [-1, -1, -1]
	var bs := [-1, -1, -1]
	for p in n:
		var c := 1
		if p == 0 or in_coalition[p]:
			c = 0
		elif String(PARCH[p]) in ["popr", "none"]:
			c = 2
		camp.append(c)
		if head_cand_ok(p) and seats[p] > bs[c]:
			bs[c] = seats[p]
			best[c] = p
	var vf := [0.0, 0.0, 0.0]
	for p in n:
		vf[camp[p]] += float(seats[p]) / float(tot_s)
	if best[1] < 0:
		best[1] = best[2]
		vf[1] += vf[2]
		vf[2] = 0.0
	if best[2] < 0:
		vf[1] += vf[2]
		vf[2] = 0.0
	if best[1] < 0:
		for p in range(1, n):
			if head_cand_ok(p) and (best[1] < 0 or seats[p] > seats[best[1]]):
				best[1] = p
	var electors: int = int(round(float(SEATS) * float(ELEC["ele_x"]) + float(ELEC["ele_add"])))
	var need: Array = ELEC["need"]
	var secret: float = float(ELEC.get("secret", 0.04))
	var all_rounds: Array = []
	var winner := -1
	for r in need.size():
		var nr: float = float(need[r])
		var d: float = 0.0 if sham else secret * randf_range(0.3, 1.5)
		var shift: float = minf(vf[1], pres_camp * 0.6)
		var va: float = vf[0] * (1.0 - d) + shift
		var vb: float = vf[1] + vf[0] * d * 0.8 - shift
		var vc: float = vf[2]
		var vals := [va, vb, vc]
		var rows: Array = []
		var top := 0
		for k in 3:
			if k < 2 or best[k] >= 0:
				if float(vals[k]) > float(vals[top]):
					top = k
		var hit := -1
		if nr > 0.0:
			for k in 3:
				if best[k] >= 0 and float(vals[k]) >= nr:
					hit = k
		else:
			hit = top
		for k in 3:
			if best[k] >= 0 and (k < 2 or float(vals[k]) > 0.005):
				var cnt: int = int(round(float(vals[k]) * float(electors)))
				rows.append(head_row(best[k], vals[k], k == hit, false, ""))
				(rows[rows.size() - 1] as Dictionary)["lab"] = "%.1f%%" % (float(vals[k]) * 100.0)
				(rows[rows.size() - 1] as Dictionary)["note"] = "%d голосов" % cnt
		rows.sort_custom(func(a, b): return float(a["val"]) > float(b["val"]))
		var nt := "нужно %.0f%% голосов" % (nr * 100.0) if nr > 0.0 else "достаточно большинства из поданных"
		all_rounds.append({"title": "%d-й тур голосования" % (r + 1), "need": nr, "need_text": nt, "rows": rows})
		if hit >= 0:
			winner = best[hit]
			break
	if winner < 0:
		winner = best[0] if best[0] >= 0 else 0
	var skipped := 0
	var rounds: Array = all_rounds
	if all_rounds.size() > 3:
		skipped = all_rounds.size() - 3
		rounds = all_rounds.slice(all_rounds.size() - 3)
	var out: Array = head_outcome(winner)
	var meta := "Голосуют %d выборщиков: %s. " % [electors, String(ELEC["body"])]
	if skipped > 0:
		meta += "Первые %d тура(ов) никто не набрал нужного большинства. " % skipped
	meta += "Срок — %d лет. Следующие выборы — %s." % [head_term_months() / 12, turn_date(turn + head_term_months())]
	var rep := {"title": "ВЫБОРЫ " + String(ELEC["title"]).to_upper() if not sham else "ВЫБОРЫ БЕЗ ВЫБОРА", "reason": reason, "rounds": rounds, "sham": sham,
		"meta": meta, "vtitle": out[0], "vcol": out[1], "vtext": out[2], "end": "",
		"log": "%s избран в %d-м туре голосования выборщиков." % [head_cand_name(winner), all_rounds.size()]}
	head_present(rep)


func hold_head_council(reason: String) -> void:
	var n: int = PARTY_NAMES.size()
	var cn: int = int(ELEC.get("council_n", 7))
	var got: Array = []
	for p in n:
		got.append(0)
	var tot_s := 0
	for p in n:
		tot_s += seats[p]
	for k in cn:
		var bp := -1
		var bq := 0.0
		for p in n:
			if float(seats[p]) < float(tot_s) * 0.05:
				continue
			var q: float = float(seats[p]) / (float(got[p]) + 1.0)
			if q > bq:
				bq = q
				bp = p
		if bp >= 0:
			got[bp] += 1
	var rows: Array = []
	for p in n:
		if got[p] > 0:
			var rw := head_row(p, float(got[p]) / float(cn), false, false, "")
			rw["name"] = "Ваша партия" if p == 0 else String(PARTY_NAMES[p]).split(" (")[0]
			rw["sub"] = "кандидатов: %d" % got[p]
			rw["lab"] = "%d из %d" % [got[p], cn]
			rw["win"] = p == 0
			rw["note"] = ""
			rows.append(rw)
	rows.sort_custom(func(a, b): return float(a["val"]) > float(b["val"]))
	var rounds: Array = [{"title": "Места в Федеральном совете (%d)" % cn, "need": 0.0, "need_text": "делятся между сильнейшими партиями «волшебной формулой»", "rows": rows}]
	var end_msg := ""
	var vt := ""
	var vc: Color = C_GOOD
	var vtx := ""
	if got[0] >= 1:
		vt = "Вы сохранили место в правительстве"
		capital = clampf(capital + 5.0, 0.0, 100.0)
		vtx = "Федеральное собрание подтвердило состав Федерального совета: у вашей партии %d из %d мест. Политкапитал +5." % [got[0], cn]
	else:
		vt = "Вас не переизбрали"
		vc = C_BAD
		end_msg = "Федеральное собрание не переизбрало вас в Федеральный совет: ваша партия осталась без мест в правительстве."
		vtx = end_msg
	var out_t := "Новый состав Федерального совета: " + ", ".join(PackedStringArray(rows.map(func(r): return "%s — %s" % [r["name"], r["lab"]])))
	var rep := {"title": "ВЫБОРЫ ФЕДЕРАЛЬНОГО СОВЕТА", "reason": reason, "rounds": rounds, "sham": false,
		"meta": "Новый парламент избирает всех семерых членов правительства. Президент Конфедерации — выборная должность на один год, глава правительства лишь первый среди равных.",
		"vtitle": vt, "vcol": vc, "vtext": vtx, "end": end_msg, "log": out_t}
	head_present(rep)


func show_head_election(rep: Dictionary) -> void:
	election_open = true
	elec_end = String(rep["end"])
	el_view.visible = false
	el_head.visible = true
	var sham: bool = bool(rep["sham"])
	var gold := Color(1.0, 0.82, 0.40) if not sham else C_BAD
	el_banner.add_theme_stylebox_override("panel", ev_style(gold))
	el_title.text = loc(String(rep["title"]))
	el_title.add_theme_color_override("font_color", gold.lightened(0.2))
	var rs: String = String(rep["reason"])
	el_sub.text = loc("%s  ·  %s" % [date_text(), rs.substr(0, 1).to_upper() + rs.substr(1)])
	el_meta.text = loc(String(rep["meta"]))
	var vcol: Color = rep["vcol"]
	el_verdict_box.add_theme_stylebox_override("panel", ev_style(vcol))
	el_verdict_title.text = loc(String(rep["vtitle"]))
	el_verdict_title.add_theme_color_override("font_color", vcol.lightened(0.3))
	el_verdict_rt.text = loc(String(rep["vtext"]))
	el_verdict_box.modulate = Color(1, 1, 1, 0.0)
	el_btn.text = "Продолжить  (Enter)" if elec_end == "" else "Принять итоги  (Enter)"
	el_btn.disabled = true
	el_head.set_data(rep["rounds"])
	var w: FloatWindow = wins["election"]
	w.visible = true
	w.move_to_front()
	if wins.has("event"):
		(wins["event"] as FloatWindow).visible = false
	next_btn.disabled = true
	el_head.set_progress(0.0)
	if el_tween != null:
		el_tween.kill()
	var nr: int = (rep["rounds"] as Array).size()
	el_tween = create_tween()
	el_tween.tween_method(func(v: float) -> void: el_head.set_progress(v), 0.0, 1.0, 1.0 + 0.9 * float(nr))
	el_tween.tween_property(el_verdict_box, "modulate", Color(1, 1, 1, 1), 0.45)
	el_tween.tween_callback(func() -> void: el_btn.disabled = false)


func head_campaign_check() -> void:
	var kind: String = String(ELEC.get("head", "none"))
	if kind != "direct" and kind != "indirect":
		return
	if game_over or election_open or not current_event.is_empty() or decree_power():
		return
	if pres_due < 0 or turn < pres_due - 2 or turn >= pres_due or pres_camp_done == pres_due:
		return
	pres_camp_done = pres_due
	var tt: String = String(ELEC["title"])
	var txt := ""
	var opts: Array = []
	if kind == "direct":
		var sh := national_shares(true)
		var rival := 1
		for p in range(1, PARTY_NAMES.size()):
			if head_cand_ok(p) and sh[p] > sh[rival]:
				rival = p
		txt = "Через два месяца — выборы %s (%s). Ваш лагерь может получить союзника на этом посту или оппонента. По опросам главный соперник вашего кандидата — %s («%s», %.1f%%). Как поддержать кандидата?" % [
			tt, turn_date(pres_due), head_cand_name(rival), PARTY_NAMES[rival], sh[rival] * 100.0]
		opts = [
			{"l": "Выдвинуть яркого лидера вашей партии (капитал -4)", "fx": {"capital": -4.0, "pcamp": 0.06}},
			{"l": "Единый кандидат широкой коалиции (капитал -3)", "fx": {"capital": -3.0, "pcamp": 0.04, "coal_sat": 4.0}},
			{"l": "Бросить на кампанию бюджетные ресурсы (долг +0.4% ВВП)", "fx": {"debt": 0.4, "pcamp": 0.07, "support": {"Пенсионеры": 2.0, "Бюджетники": 2.0}}},
			{"l": "Не вмешиваться (капитал +2)", "fx": {"capital": 2.0}},
		]
	else:
		txt = "Через два месяца %s выберут %s. Голосование тайное: часть выборщиков вашей коалиции может проголосовать против. Что предпринять?" % [String(ELEC["body"]), tt]
		opts = [
			{"l": "Выдвинуть собственного кандидата и дисциплинировать выборщиков (капитал -4)", "fx": {"capital": -4.0, "pcamp": 0.05}},
			{"l": "Искать общего кандидата с оппозицией (довольство партнёров -4)", "fx": {"coal_sat": -4.0, "pcamp": 0.03, "all": 0.5}},
			{"l": "Закулисные договорённости: посты и обещания (долг +0.3% ВВП)", "fx": {"debt": 0.3, "pcamp": 0.08, "capital": -3.0}},
			{"l": "Не вмешиваться (капитал +2)", "fx": {"capital": 2.0}},
		]
	current_event = {"t": txt, "kind": "pcampaign", "o": opts}
	event_region = -1
	event_party = -1
	event_min = -1
	present_event()


''')

# ---------- данные выборов стран ----------
src += r'''

# Профили выборов стран (v18). У каждой страны ОБЯЗАНА быть запись (см. w13/SPEC_NEW.md, раздел «Выборы»).
# head: direct — прямые президентские выборы, indirect — глава государства избирается парламентом/коллегией,
# council — выборный коллегиальный орган (Швейцария), monarch — монархия, выборов главы государства нет.
const ELEC_DATA := {
	"DE": {"sys": "Персонализированная пропорциональная система: два голоса — за кандидата в округе и за партийный список", "turn": 0.76,
		"note": "Бундесрат формируется правительствами земель и не переизбирается.",
		"head": "indirect", "title": "федерального президента", "title_n": "Федеральный президент", "term": 60, "first": 13,
		"body": "депутаты Бундестага и столько же делегатов от земель", "ele_x": 2.0, "ele_add": 0, "need": [0.5, 0.5, 0.0], "secret": 0.03, "cand0": "Кандидат вашей партии"},
	"FR": {"sys": "Мажоритарная система в два тура по одномандатным округам", "turn": 0.67,
		"note": "Сенат избирается выборщиками и сейчас не переизбирается.",
		"head": "direct", "title": "президента Республики", "title_n": "Президент Республики", "term": 60, "first": 15, "cand0": "Кандидат президентского лагеря"},
	"NL": {"sys": "Чистая пропорциональная система: один общенациональный округ", "turn": 0.78,
		"note": "Нидерланды — монархия: король не избирается, а Первую палату выбирают провинциальные советы.", "head": "monarch"},
	"BE": {"sys": "Пропорциональная система по 11 избирательным округам", "turn": 0.88,
		"note": "Явка обязательна. Бельгия — монархия, главу государства не избирают.", "head": "monarch"},
	"LU": {"sys": "Пропорциональная система по 4 округам с правом смешивать списки (панашаж)", "turn": 0.89,
		"note": "Явка обязательна. Люксембург — великое герцогство, глава государства не избирается.", "head": "monarch"},
	"CH": {"sys": "Пропорциональная система по кантонам (Национальный совет)", "turn": 0.46,
		"note": "Совет кантонов избирают сами кантоны; важнейшие вопросы решают ещё и референдумы.",
		"head": "council", "title": "Федерального совета", "title_n": "Федеральный совет", "council_n": 7},
	"AT": {"sys": "Пропорциональная система по спискам: округ, земля, федерация", "turn": 0.78,
		"note": "Федеральный совет формируют ландтаги.",
		"head": "direct", "title": "федерального президента", "title_n": "Федеральный президент", "term": 72, "first": 33, "cand0": "Кандидат вашей партии"},
	"PL": {"sys": "Пропорциональная система по 41 округу, метод Д'Ондта", "turn": 0.74,
		"note": "Сенат избирается в тот же день по одномандатным округам.",
		"head": "direct", "title": "президента Республики", "title_n": "Президент Республики", "term": 60, "first": 52, "cand0": "Кандидат вашей партии"},
	"CZ": {"sys": "Пропорциональная система по 14 краям, для коалиций барьер выше", "turn": 0.68,
		"note": "Сенат обновляется по третям раз в два года, отдельно.",
		"head": "direct", "title": "президента Республики", "title_n": "Президент Республики", "term": 60, "first": 24, "cand0": "Кандидат вашей партии"},
	"DK": {"sys": "Пропорциональная система: 135 мест по округам и 40 компенсационных", "turn": 0.84,
		"note": "Парламент однопалатный. Дания — монархия, главу государства не избирают.", "head": "monarch"},
	"NO": {"sys": "Пропорциональная система по 19 округам", "turn": 0.77,
		"note": "Парламент однопалатный. Норвегия — монархия, главу государства не избирают.", "head": "monarch"},
	"SE": {"sys": "Пропорциональная система по 29 округам", "turn": 0.84,
		"note": "Риксдаг однопалатный. Швеция — монархия, главу государства не избирают.", "head": "monarch"},
	"IT": {"sys": "Смешанная система: около трети мест — одномандатные округа, остальные по спискам", "turn": 0.64,
		"note": "Сенат избирается в тот же день.",
		"head": "indirect", "title": "президента Республики", "title_n": "Президент Республики", "term": 84, "first": 36,
		"body": "депутаты, сенаторы и 58 делегатов от регионов", "ele_x": 1.5, "ele_add": 58, "need": [0.667, 0.667, 0.667, 0.5, 0.5, 0.5, 0.0], "secret": 0.12, "cand0": "Кандидат вашей партии"},
	"ES": {"sys": "Пропорциональная система по 52 провинциальным округам, метод Д'Ондта", "turn": 0.70,
		"note": "Сенат избирается в тот же день. Испания — монархия, главу государства не избирают.", "head": "monarch"},
	"PT": {"sys": "Пропорциональная система по 22 округам, метод Д'Ондта", "turn": 0.64,
		"note": "Ассамблея Республики однопалатная.",
		"head": "direct", "title": "президента Республики", "title_n": "Президент Республики", "term": 60, "first": 60, "cand0": "Кандидат вашей партии"},
}
'''

# ---------- «Выборы и опросы»: система страны и выборы главы государства ----------
rep(r'''	var t := "[b]Ближайшие выборы в Бундестаг[/b]\nПропорциональная система, барьер %.0f%%: %s, через %s\n\n" % [
		float(mods["threshold"]) * 100.0, date_after(parl_in), months_text(parl_in)]''', r'''	var thr_t := ("барьер %.0f%%, " % (float(mods["threshold"]) * 100.0)) if float(mods["threshold"]) >= 0.005 else ""
	var t := "[b]Ближайшие выборы в Бундестаг[/b]\n%s: %s%s, через %s\n" % [
		String(ELEC.get("sys", "Пропорциональная система")), thr_t, date_after(parl_in), months_text(parl_in)]
	var hk0: String = String(ELEC.get("head", "none"))
	if (hk0 == "direct" or hk0 == "indirect" or hk0 == "council") and pres_due >= 0:
		t += "[b]Ближайшие выборы %s[/b]\n%s, через %s\n" % [String(ELEC["title"]), turn_date(maxi(pres_due, turn)), months_text(maxi(0, pres_due - turn))]
	elif hk0 == "monarch":
		t += "[color=%s]Глава государства — монарх, его не избирают.[/color]\n" % COL_DIM
	t += "\n"''')

# итог выборов — сразу под шапкой, чтобы не уходил за край окна
rep('''	el_btn.pressed.connect(election_continue)
	hb.add_child(el_btn)
''', '''	el_btn.pressed.connect(election_continue)
	hb.add_child(el_btn)
	w.body.move_child(el_verdict_box, 2)
''')
rep('	const HEMI_H := 210.0\n', '	const HEMI_H := 190.0\n')

rep('	const ROW_H := 27.0\n	const HEMI_H := 190.0\n', '	const ROW_H := 24.0\n	const HEMI_H := 190.0\n')

rep('''		var W: float = size.x
		var name_w: float = clampf(W * 0.34, 120.0, 260.0)''', '''		var FW: float = size.x
		var side: bool = FW >= 780.0
		var W: float = FW * 0.58 if side else FW
		var name_w: float = clampf(W * 0.34, 120.0, 260.0)''')

rep('''	log_line("Система: пропорциональная, барьер %.0f%%, %d мест." % [thr * 100.0, SEATS])''', '''	log_line("Система: %s%s, %d мест." % [low1(String(ELEC.get("sys", "пропорциональная"))), (", барьер %.0f%%" % (thr * 100.0)) if thr >= 0.005 else "", SEATS])''')
