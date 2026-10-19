# Структурированный журнал.
extends "res://scripts/logic/autopilot.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func log_is_big(e: Dictionary) -> bool:
	return false


func log_ui_add(e: Dictionary) -> void:
	pass


func log_ui_bump(e: Dictionary) -> void:
	pass


func log_ui_rebuild(to_end: bool) -> void:
	pass


func notify_log(e: Dictionary) -> void:
	pass


# --- конец заглушек ---


func log_guess_cat(s: String) -> String:
	var low := s.to_lower()
	for w in LOG_POL_WORDS:
		if low.contains(w):
			return "pol"
	for w in LOG_ECO_WORDS:
		if low.contains(w):
			return "eco"
	return "ev"


func log_match(e: Dictionary) -> bool:
	var k := String(e.get("k", ""))
	if log_big and (k == "line" or k == "head" or k == "note") and not log_is_big(e):
		return false
	if log_query != "" and (k == "line" or k == "head" or k == "note"):
		if not String(e.get("t", "")).to_lower().contains(log_query):
			return false
	if log_filter == 0:
		return true
	return String(e["cat"]) == String(LOG_FILTER_CATS[log_filter])


func log_add(e: Dictionary) -> void:
	if not LOC_RULES.is_empty():
		if e.has("t"):
			e["t"] = loc(String(e["t"]))
		if e.has("notes"):
			var nn: Array = []
			for x in e["notes"]:
				nn.append(loc(String(x)))
			e["notes"] = nn
	if not e.has("d"):
		e["d"] = date_chip()
	# 0.57: одинаковые подряд записи склеиваются («× 3»)
	if String(e.get("k", "")) == "line" and not log_entries.is_empty():
		var lst: Dictionary = log_entries.back()
		if String(lst.get("k", "")) == "line" and String(lst.get("t", "")) == String(e.get("t", "")) and String(lst.get("tag", "")) == String(e.get("tag", "")):
			lst["n"] = int(lst.get("n", 1)) + 1
			if log_box != null:
				log_ui_bump(lst)
			return
	log_uid += 1
	e["uid"] = log_uid
	log_entries.append(e)
	if log_entries.size() > 700:
		log_entries.pop_front()
	if log_box != null:
		log_ui_add(e)
	notify_log(e)


func log_chip(text: String, col: String) -> String:
	return "[bgcolor=%s][color=#0f1420][b] %s [/b][/color][/bgcolor]" % [col, text]


func log_render(e: Dictionary) -> String:
	var kind: String = e["k"]
	match kind:
		"head":
			return "\n[color=%s][b]▌ %s[/b][/color]\n" % [e["col"], e["t"]]
		"line":
			var cat: String = e["cat"]
			var ccol: String = LOG_CAT_COL.get(cat, "#8a93aa")
			if e.has("tag"):
				return "%s  %s\n" % [log_chip(e["tag"], e["col"]), e["t"]]
			return "[color=%s]●[/color] %s\n" % [ccol, e["t"]]
		"note":
			return "[indent][color=%s]%s[/color][/indent]\n" % [COL_DIM, e["t"]]
		"month":
			return log_render_month(e)
		"year":
			return log_render_year(e)
	return ""


func log_cell(caption: String, value: String) -> String:
	return "[cell][font_size=11][color=%s]%s[/color][/font_size]\n%s[/cell]" % [COL_DIM, caption, value]


func log_render_month(e: Dictionary) -> String:
	var t := "\n%s\n" % log_chip("   %s   " % e["date"], "#7fb0ff")
	t += "[table=4]"
	var gy: float = maxf(1.0, float(e["gdp"]))
	t += log_cell("Доходы", "[b]%s[/b] [color=%s]%.1f%% ВВП[/color]" % [fmt_n(float(e["rev"]), 1), COL_DIM, float(e["rev"]) * 1200.0 / gy])
	t += log_cell("Расходы", "[b]%s[/b] [color=%s]%.1f%% ВВП[/color]" % [fmt_n(float(e["exp"]), 1), COL_DIM, float(e["exp"]) * 1200.0 / gy])
	t += log_cell("Баланс", col_signed(float(e["bal"]), 1))
	t += log_cell("Долг", "[b]%s[/b] [color=%s]%.0f%%[/color]" % [fmt_n(float(e["debt"])), COL_DIM, float(e["debt_pct"])])
	t += log_cell("ВВП", "[b]%s[/b] [color=%s]%s%%[/color]" % [fmt_n(float(e["gdp"])), COL_DIM, sg(float(e["growth"]), 1)])
	t += log_cell("Инфляция", "[b]%.1f%%[/b] %s" % [float(e["infl"]), col_delta(float(e["dinfl"]), 2, true)])
	t += log_cell("Безработица", "[b]%.1f%%[/b] %s" % [float(e["unemp"]), col_delta(float(e["dunemp"]), 2, true)])
	t += log_cell("Рейтинг", "[b]%.0f%%[/b] %s" % [float(e["appr"]), col_delta(float(e["dappr"]), 1)])
	t += "[/table]\n"
	for n in e["notes"]:
		t += "[indent][color=%s]%s[/color][/indent]\n" % [COL_DIM, n]
	return t


func log_render_year(e: Dictionary) -> String:
	var ys: Dictionary = e["ys"]
	var t := "\n%s\n[table=4]" % log_chip("   ИТОГИ %d ГОДА   " % int(e["year"]), "#ffd166")
	t += log_cell("ВВП", "%s → [b]%s[/b] %s" % [fmt_n(float(ys["gdp"])), fmt_n(float(e["gdp"])), col_delta((float(e["gdp"]) / float(ys["gdp"]) - 1.0) * 100.0, 1)])
	t += log_cell("Долг", "%s → [b]%s[/b]" % [fmt_n(float(ys["debt"])), fmt_n(float(e["debt"]))])
	t += log_cell("Инфляция", "%.1f → [b]%.1f%%[/b] %s" % [float(ys["infl"]), float(e["infl"]), col_delta(float(e["infl"]) - float(ys["infl"]), 1, true)])
	t += log_cell("Безработица", "%.1f → [b]%.1f%%[/b] %s" % [float(ys["unemp"]), float(e["unemp"]), col_delta(float(e["unemp"]) - float(ys["unemp"]), 1, true)])
	t += "[cell][font_size=11][color=%s]Рейтинг[/color][/font_size]\n%.0f → [b]%.0f%%[/b] %s[/cell][/table]\n" % [COL_DIM, float(ys["appr"]), float(e["appr"]), col_delta(float(e["appr"]) - float(ys["appr"]), 0)]
	return t


func log_rebuild() -> void:
	if log_box != null:
		log_ui_rebuild(true)


func log_clear() -> void:
	log_entries.clear()
	log_open.clear()
	log_rebuild()


func on_log_filter(i: int) -> void:
	log_filter = i
	for k in log_filter_btns.size():
		(log_filter_btns[k] as Button).set_pressed_no_signal(k == i)
	log_rebuild()


func build_log_filters(parent: Control) -> void:
	var fr := HFlowContainer.new()
	fr.add_theme_constant_override("h_separation", 4)
	fr.add_theme_constant_override("v_separation", 4)
	parent.add_child(fr)
	log_filter_btns.clear()
	for i in LOG_FILTERS.size():
		var b := Button.new()
		b.theme_type_variation = "SmallButton"
		b.text = LOG_FILTERS[i]
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(on_log_filter.bind(i))
		fr.add_child(b)
		log_filter_btns.append(b)
	(log_filter_btns[0] as Button).set_pressed_no_signal(true)
	var bg := Button.new()
	bg.theme_type_variation = "SmallButton"
	bg.text = "★ Важное"
	bg.toggle_mode = true
	bg.focus_mode = Control.FOCUS_NONE
	bg.tooltip_text = "Оставить только крупные события: войны, кризисы, выборы, принятые законы."
	bg.toggled.connect(func(on: bool) -> void:
		log_big = on
		log_rebuild())
	fr.add_child(bg)
	var qe := LineEdit.new()
	qe.placeholder_text = "Поиск в журнале"
	qe.custom_minimum_size = Vector2(150.0, 0.0)
	qe.clear_button_enabled = true
	qe.text_changed.connect(func(t: String) -> void:
		log_query = t.strip_edges().to_lower()
		log_rebuild())
	fr.add_child(qe)


func log_line(s: String) -> void:
	log_add({"k": "line", "cat": log_guess_cat(s), "t": s})


func log_sys(s: String) -> void:
	log_add({"k": "line", "cat": "sys", "t": s})


func log_header(text: String, col: String) -> void:
	var low := text.to_lower()
	var cat := "pol" if (low.contains("выбор") or low.contains("конец")) else "ev"
	if low.contains("начало"):
		cat = "sys"
	log_add({"k": "head", "cat": cat, "t": text, "col": col})


func log_tag(tag: String, col: String, text: String) -> void:
	log_add({"k": "line", "cat": LOG_TAG_CAT.get(tag, "ev"), "tag": tag, "col": col, "t": text})


# ============================================================
#  v35: ИСТОРИЯ ЗА 12 МЕСЯЦЕВ (вместо сравнений «с начала игры»)
# ============================================================
func h12_push(k: String, v: Variant) -> void:
	var a: Array = h12.get(k, [])
	a.append(v.duplicate() if v is Array else v)
	while a.size() > 13:
		a.pop_front()
	h12[k] = a


# значение год назад (или самое старое из накопленных); now — если истории ещё нет
func h12_ago(k: String, now: Variant) -> Variant:
	var a: Array = h12.get(k, [])
	return a[0] if a.size() > 0 else now


# за сколько месяцев есть сравнение
func h12_months(k: String) -> int:
	return maxi(0, (h12.get(k, []) as Array).size() - 1)


func h12_label(k: String) -> String:
	var m := h12_months(k)
	return "за 12 мес." if m >= 12 else ("за %d мес." % m if m > 0 else "пока без истории")


func h12_snap() -> void:
	# 0.57: главные показатели для подсказок с графиком за 12 месяцев
	h12_push("appr", approval())
	h12_push("infl", inflation)
	h12_push("unemp", unemployment)
	h12_push("debtr", debt / maxf(1.0, gdp) * 100.0)
	h12_push("gdp", gdp)
	h12_push("cap", capital)
	if not ec.is_empty() and ec.has("res"):
		h12_push("res", float(ec["res"]))
	if not ec.is_empty():
		for key in ["ppi", "rw", "fxs", "cpi_idx"]:
			if ec.has(key):
				h12_push(key, float(ec[key]))
		if ec.has("mk"):
			for m in MARKETS:
				h12_push("mk:" + String(m["id"]), float(ec["mk"][m["id"]]["p"]))
		if ec.has("gp"):
			h12_push("cpi_goods", cpi_goods())
			for gr in GROUPS:
				h12_push("gcpi:" + String(gr), group_cpi(gr))
	if pol.has("vat"):
		h12_push("vat", float(pol["vat"]))
	if not soc.is_empty() and soc.has("in_now"):
		h12_push("mig_in", float(soc["in_now"]))
	if regions.size() > 0 and (regions[0] as Dictionary).has("rel"):
		h12_push("faith", soc_national())
	if AG != null and ag_on:
		var pr: Array = []
		for r in regions.size():
			pr.append(AG.region_prot(r))
		h12_push("prot", pr)
