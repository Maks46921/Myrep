# Интерфейс: «Технологии» (desk 15).
extends "res://scripts/ui/ui_soc.gd"

var tw_sum_rt: RichTextLabel
var tw_spk: Control
var tw_branch_rt: Array = []
var tw_bld_rt: RichTextLabel
var tw_bld_box: VBoxContainer
var tw_btn: Dictionary = {}
var tw_sel_b := 0
var tw_sig := ""


func build_tech_windows() -> void:
	var w: FloatWindow = new_window("tw_sum", "Исследования", 15, Rect2(0.0, 0.0, 0.22, 1.0))
	tw_sum_rt = make_rt(w.body)
	var rw := HBoxContainer.new()
	w.body.add_child(rw)
	for b in 3:
		tw_btn["w-%d" % b] = fed_btn("%s −" % String(TECH_BRANCHES[b]["name"]).substr(0, 4) + ".", rw, "Меньше сил на ветку «%s»." % TECH_BRANCHES[b]["name"])
		tw_btn["w-%d" % b].pressed.connect(on_tech_weight.bind(b, -1))
	var rw2 := HBoxContainer.new()
	w.body.add_child(rw2)
	for b2 in 3:
		tw_btn["w+%d" % b2] = fed_btn("%s +" % String(TECH_BRANCHES[b2]["name"]).substr(0, 4) + ".", rw2, "Больше сил на ветку «%s»." % TECH_BRANCHES[b2]["name"])
		tw_btn["w+%d" % b2].pressed.connect(on_tech_weight.bind(b2, 1))
	tw_btn["auto"] = fed_btn("Автовыбор технологий", w.body, "Если включён, свободная ветка сама берёт самую дешёвую доступную технологию. Выбрать вручную можно в любой момент: щёлкните по названию в ветке.")
	tw_btn["auto"].toggle_mode = true
	tw_btn["auto"].toggled.connect(on_tech_auto)
	tw_spk = Spark.new()
	w.body.add_child(tw_spk)
	add_note(w.body, "Скорость исследований зависит от расходов на образование (ползунок в бюджете) и от сооружений. Выше «потолка» прирост скорости быстро слабеет. Потолок растёт со временем, ВВП и свободой слова.", true)

	for b3 in 3:
		var wb: FloatWindow = new_window("tw_b%d" % b3, "Ветка: %s" % String(TECH_BRANCHES[b3]["name"]).to_lower(), 15, Rect2(0.22 + 0.16 * b3, 0.0, 0.16, 0.74))
		var rt := make_rt(wb.body)
		rt.meta_clicked.connect(on_tech_meta.bind(b3))
		tw_branch_rt.append(rt)

	var wc: FloatWindow = new_window("tw_bld", "Научные сооружения", 15, Rect2(0.22, 0.74, 0.48, 0.26))
	tw_bld_rt = make_rt(wc.body)
	tw_bld_box = VBoxContainer.new()
	tw_bld_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wc.body.add_child(tw_bld_box)


func on_tech_meta(meta: Variant, b: int) -> void:
	var id := String(meta)
	if id == "pause":
		tech_select(b, "")
	else:
		tech_select(b, id)


func on_tech_weight(b: int, d: int) -> void:
	tech_set_weight(b, d)


func on_tech_auto(on: bool) -> void:
	if tech.is_empty():
		return
	tech["auto"] = on
	refresh()


func on_tech_pick(b: int, id: String) -> void:
	tech_select(b, id)


func on_tech_build(id: String) -> void:
	tech_build(id)


func tech_bar(frac: float, n: int = 12) -> String:
	var k: int = int(round(clampf(frac, 0.0, 1.0) * n))
	return "█".repeat(k) + "░".repeat(n - k)


func update_tech_windows() -> void:
	if tw_sum_rt == null or tech.is_empty():
		return
	tech_refresh_rates()
	var spd: float = tech["speed"]
	var raw: float = tech["raw"]
	var cap: float = tech["cap"]
	var fr: float = tech_freedom()
	var s := "[b]Скорость исследований: %.1f очк./мес.[/b]\n" % spd
	s += "Потолок скорости: [b]%.1f[/b] · «сырая» скорость: %.1f\n" % [cap, raw]
	if raw > cap:
		s += "[color=%s]Вы выше потолка: лишние %.1f дают только %.1f. Поднять потолок — время, рост ВВП, свобода слова.[/color]\n" % [COL_WARN, raw - cap, spd - cap]
	else:
		s += "[color=%s]До потолка: ещё %.1f очк. Можно увеличить расходы на образование и построить сооружения.[/color]\n" % [COL_DIM, cap - raw]
	s += "\n[b]Из чего складывается[/b]\n"
	s += "Расходы на образование: %.1f%% ВВП (обычно %.1f%%) → ×%.2f\n" % [float(pol["edu"]), float(pol_def["edu"]), tech_edu_term()]
	s += "Сооружения: %s · технологии: %s\n" % [sg(tech_bsum("sp", -2) * 100.0, 0) + "%", sg(tech_sum("rs") * 100.0, 0) + "%"]
	var yrs: float = years_passed()
	s += "\n[b]Что поднимает потолок[/b]\n"
	s += "Время: ×%.2f · ВВП: ×%.2f\n" % [1.0 + TECH_CAP_YEAR * yrs, clampf(sqrt(gdp / maxf(1.0, gdp_base)), 0.8, 3.0)]
	var fcol: String = COL_GOOD if fr >= 0.6 else (COL_WARN if fr >= 0.4 else COL_BAD)
	s += "Свобода слова: [color=%s]%.0f%%[/color] → ×%.2f (закон о СМИ и индекс демократии)\n" % [fcol, fr * 100.0, TECH_FREE_BASE + TECH_FREE_SPAN * fr]
	var bonus: float = tech_sum("cp") + tech_bsum("cpb", -2)
	if bonus > 0.0:
		s += "Технологии и лаборатории: +%.0f%%\n" % (bonus * 100.0)
	s += "\n[b]Изучено: %d из %d[/b] · накоплено очков: %.0f" % [tech_count(), tech_total(), float(tech["pts"])]
	if bool(tech["idle"]):
		s += "\n[color=%s]Всем веткам задан вес 0: исследований нет.[/color]" % COL_BAD
	var wsum := 0.0
	for b in 3:
		wsum += float(tech["w"][b])
	s += "\n\n[b]Распределение сил[/b]\n"
	for b2 in 3:
		var sh: float = float(tech["w"][b2]) / wsum if wsum > 0.0 else 0.0
		var st := ""
		if String(tech["cur"][b2]) == "":
			st = " (нечего изучать — копится запас)"
		s += "[color=%s]■[/color] %s: вес %d → %.1f очк./мес.%s\n" % [TECH_BRANCHES[b2]["col"], TECH_BRANCHES[b2]["name"], int(tech["w"][b2]), spd * sh, st]
	var nch := 0
	for b6 in 3:
		if tech_choice_waiting(b6):
			nch += 1
	if nch > 0:
		s += "\n[color=%s][b]Ждут вашего выбора: %d ветк.[/b] (в окнах веток отмечено «Нужен ваш выбор»)[/color]" % [COL_WARN, nch]
	var up: float = tech_edu_upkeep()
	if up > 0.0:
		s += "\nСодержание сооружений: %.2f%% ВВП (%.1f млрд) в год — входит в расходы на образование." % [up, gdp * up / 100.0]
	tw_sum_rt.text = s
	(tw_btn["auto"] as Button).set_pressed_no_signal(bool(tech["auto"]))
	for b3 in 3:
		(tw_btn["w-%d" % b3] as Button).disabled = game_over or int(tech["w"][b3]) <= 0
		(tw_btn["w+%d" % b3] as Button).disabled = game_over or int(tech["w"][b3]) >= 4
	var hh: Dictionary = tech["h"]
	tw_spk.title = "Скорость и потолок по месяцам"
	tw_spk.series = [{"v": hh["s"], "c": Color("#58c887"), "n": "скорость"}, {"v": hh["c"], "c": Color("#e8b84a"), "n": "потолок"}]
	tw_spk.queue_redraw()
	# списки пересобираем только при изменении состава
	var sig := "%s|%s|%d|%d|%s" % [str(tech["bld"]), str(tech["done"].keys()), tech["q"].size(), int(gdp / 50.0), str(game_over)]
	if sig != tw_sig:
		tw_sig = sig
		tech_build_buildings()
	for b5 in 3:
		tech_branch_text(b5)
	tech_buildings_text()


func tech_short(s: String, n: int = 34) -> String:
	return s if s.length() <= n else s.substr(0, n - 1) + "…"


func tech_clear(box: Control) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func tech_line(d: Dictionary, b: int) -> String:
	var id: String = d["id"]
	var bc: String = TECH_BRANCHES[b]["col"]
	var miss := tech_missing(id)
	if tech_done(id):
		return "\n[color=%s]✔ %s[/color]\n[color=%s]%s[/color]" % [COL_GOOD, d["name"], COL_DIM, tech_fx_text(d)]
	if String(tech["cur"][b]) == id:
		return "\n[color=%s][b]▶ %s[/b][/color]\n%s %.0f%% (%d очк.)\n[color=%s]%s\n%s[/color]" % [bc, d["name"], tech_bar(tech_progress(id)), tech_progress(id) * 100.0, int(d["cost"]), COL_DIM, d["d"], tech_fx_text(d)]
	if miss == "":
		return "\n[url=%s][color=%s]○ %s[/color][/url] [color=%s]%d очк.[/color]\n[color=%s]%s\n%s[/color]" % [id, bc, d["name"], COL_DIM, int(d["cost"]), COL_DIM, d["d"], tech_fx_text(d)]
	if miss.begins_with("не выбрана"):
		return "\n[color=%s]✖ %s — %s[/color]" % [COL_DIM, d["name"], miss]
	return "\n[color=%s]· %s — %s[/color]" % [COL_DIM, d["name"], miss]


func tech_branch_text(b: int) -> void:
	var rt: RichTextLabel = tw_branch_rt[b]
	var t := "[color=%s]%s[/color]\nСила технологий ветки: [b]×%.2f[/b] (даёт научная инфраструктура)\n" % [COL_DIM, TECH_BRANCHES[b]["d"], tech_power(b)]
	var bank: float = float(tech["bank"][b])
	if bank >= 1.0:
		t += "[color=%s]Запас очков: %.0f — достанется следующей технологии.[/color]\n" % [COL_DIM, bank]
	if tech_choice_waiting(b):
		t += "[color=%s][b]Нужен ваш выбор[/b] — щёлкните по названию.%s[/color]\n" % [COL_WARN, (" Авто через %d мес." % (6 - int(tech["wait"][b]))) if bool(tech["auto"]) else ""]
	elif String(tech["cur"][b]) == "" and not bool(tech["auto"]):
		t += "[color=%s]Ветка без задачи: выберите технологию (щелчок по названию) или включите автовыбор.[/color]\n" % COL_WARN
	var last_t := -1
	for d in TECHS:
		if int(d["b"]) != b:
			continue
		var tr: int = int(d["t"])
		if tr != last_t:
			last_t = tr
			var opts := 1 + tech_alts(String(d["id"])).size()
			var hdr := "Уровень %d" % (tr + 1)
			if opts > 1:
				hdr += " — выбор: одна из %d" % opts
			t += "\n[color=%s][b]%s[/b][/color]" % [COL_DIM, hdr]
		t += tech_line(d, b)
	rt.text = t


func tech_build_buildings() -> void:
	tech_clear(tw_bld_box)
	var flow := HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tw_bld_box.add_child(flow)
	for d in TECH_BUILDINGS:
		var id: String = d["id"]
		var miss := tech_build_missing(id)
		var btn := make_button("%s (%.1f млрд)" % [d["name"], gdp * float(d["cost"]) / 100.0], flow)
		btn.disabled = game_over or miss != ""
		btn.tooltip_text = "%s\nСрок: %d мес. Содержание: %.2f%% ВВП в год.%s" % [d["d"], int(d["months"]), float(d["up"]), ("\nСейчас нельзя: " + miss) if miss != "" else ""]
		btn.pressed.connect(on_tech_build.bind(id))


func tech_buildings_text() -> void:
	var t := "[table=4][cell][color=%s]Сооружение[/color][/cell][cell][color=%s] Построено[/color][/cell][cell][color=%s] Строится[/color][/cell][cell][color=%s] Что даёт[/color][/cell]" % [COL_DIM, COL_DIM, COL_DIM, COL_DIM]
	for d in TECH_BUILDINGS:
		var id: String = d["id"]
		var inq := 0
		var left := 0
		for q in tech["q"]:
			if q["id"] == id:
				inq += 1
				left = maxi(left, int(q["left"]))
		var gives: PackedStringArray = []
		if float(d["sp"]) > 0.0:
			gives.append("скорость +%.0f%%" % (float(d["sp"]) * 100.0))
		if float(d["pw"]) > 0.0:
			gives.append("сила %s +%.0f%%" % ["всех технологий" if int(d["br"]) < 0 else "ветки «%s»" % String(TECH_BRANCHES[int(d["br"])]["name"]).to_lower(), float(d["pw"]) * 100.0])
		if float(d["cpb"]) > 0.0:
			gives.append("потолок +%.0f%%" % (float(d["cpb"]) * 100.0))
		t += "[cell]%s[/cell][cell] %d/%d[/cell][cell] %s[/cell][cell] [color=%s]%s[/color][/cell]" % [d["name"], int(tech["bld"][id]), int(d["max"]), ("%d (ещё %d мес.)" % [inq, left]) if inq > 0 else "—", COL_DIM, ", ".join(gives)]
	t += "[/table]"
	tw_bld_rt.text = t
