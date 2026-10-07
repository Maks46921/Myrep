# Структурированный журнал.
extends "res://scripts/logic/autopilot.gd"

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
	log_entries.append(e)
	if log_entries.size() > 700:
		log_entries.pop_front()
	if log_box != null and log_match(e):
		log_box.append_text(log_render(e))


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
	if log_box == null:
		return
	log_box.clear()
	for e in log_entries:
		if log_match(e):
			log_box.append_text(log_render(e))


func log_clear() -> void:
	log_entries.clear()
	if log_box != null:
		log_box.clear()


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
