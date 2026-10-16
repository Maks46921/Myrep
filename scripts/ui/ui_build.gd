# v50_1: окно «Строительство». Выберите сооружение — справа видно, сколько стоит, что даст, как отнесутся группы
# и есть ли спрос на продукцию его рынка; затем щёлкните по своей АТЕ на карте — там и встанет сооружение.
# Политкапитал на стройку не тратится; построенное рисуется значком на своей АТЕ.
extends "res://scripts/ui/ui_budget.gd"

const PROJ_CATS := ["Энергетика", "Транспорт", "Промышленность", "Сельское хозяйство", "Социальная сфера", "Технологии", "Жильё", "Экология",
	"Культура", "Религия", "Образование", "Здравоохранение", "Оборона", "Госуправление"]
const PROJ_CAT_ICO := ["energy", "grid", "work", "box", "people", "flask", "hall", "globe", "masks", "faith", "book", "medcross", "shield", "scales"]

var bld_btns := {}
var bld_info_rt: RichTextLabel = null
var bld_list_rt: RichTextLabel = null
var bld_hint: Label = null
var bld_reg_rt: RichTextLabel = null    # v55_1: сооружения выбранного региона (улучшение, ремонт)
var bld_mega_rt: RichTextLabel = null
var bld_corp_rt: RichTextLabel = null


func build_build_window() -> void:
	var w: FloatWindow = new_window("build", "Строительство", 2, Rect2(0.25, 0.0, 0.21, 0.70))
	bld_hint = add_note(w.body, "", true)
	var grp := ButtonGroup.new()
	grp.allow_unpress = true
	for ci in PROJ_CATS.size():
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 4)
		w.body.add_child(hb)
		var ic: Control = Ico.make(String(PROJ_CAT_ICO[ci]), C_ACCENT.lightened(0.2), 13.0)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(ic)
		var cl := Label.new()
		cl.text = PROJ_CATS[ci]
		cl.add_theme_font_size_override("font_size", 12)
		cl.add_theme_color_override("font_color", C_DIM)
		hb.add_child(cl)
		var fl := HFlowContainer.new()
		fl.add_theme_constant_override("h_separation", 4)
		fl.add_theme_constant_override("v_separation", 4)
		w.body.add_child(fl)
		for pd in PROJECTS:
			if int(pd["cat"]) != ci:
				continue
			var b := Button.new()
			b.theme_type_variation = "SmallButton"
			b.text = String(pd["name"])
			# v55_3: длинное название (мегапроекты) переносится на 2 строки и не раздвигает окно
			if b.text.length() > 30:
				b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				b.custom_minimum_size.x = 240.0
			b.toggle_mode = true
			b.button_group = grp
			b.focus_mode = Control.FOCUS_NONE
			b.tooltip_text = String(pd["desc"])
			var pid: String = String(pd["id"])
			b.toggled.connect(func(on: bool) -> void:
				bld_pick = pid if on else ("" if bld_pick == pid else bld_pick)
				update_build_window())
			fl.add_child(b)
			bld_btns[pid] = b
	bld_info_rt = make_rt(w.body)
	add_title(w.body, "Идёт стройка")
	bld_list_rt = make_rt(w.body)
	add_title(w.body, "Сооружения выбранного региона")
	bld_reg_rt = make_rt(w.body)
	bld_reg_rt.meta_clicked.connect(on_bld_meta)
	add_title(w.body, "Мегапроект страны")
	bld_mega_rt = make_rt(w.body)
	add_title(w.body, "Стройка корпораций и других стран")
	bld_corp_rt = make_rt(w.body)


func on_bld_meta(meta: Variant) -> void:
	var s := String(meta)
	var why := ""
	if s.begins_with("upg:"):
		why = con_upgrade_start(selected_region, s.substr(4))
	elif s.begins_with("rep:"):
		con_repair(selected_region, s.substr(4))
	if why != "":
		log_line("[color=%s]Улучшение не начато: %s.[/color]" % [COL_WARN, why])
	update_build_window()


func update_build_window() -> void:
	if bld_info_rt == null:
		return
	for pid in bld_btns:
		(bld_btns[pid] as Button).set_pressed_no_signal(pid == bld_pick)
	if bld_pick == "":
		bld_hint.text = "Выберите сооружение, затем щёлкните по своей АТЕ на карте. Политкапитал не нужен — но на стройку реагируют группы интересов."
		bld_info_rt.text = ""
	else:
		var pd := find_by_id(PROJECTS, bld_pick)
		bld_hint.text = "Щёлкните по своей АТЕ на карте, чтобы начать «%s». Ещё раз нажмите кнопку — отменить выбор." % pd["name"]
		var lo := 1e9
		var hi := 0.0
		for i in regions.size():
			var c: float = gdp * project_cost_pct(i, pd) / 100.0
			lo = minf(lo, c)
			hi = maxf(hi, c)
		var t := "[b]%s[/b] — %d мес., %s млрд (в крупных регионах дороже)\n" % [pd["name"], int(pd["months"]), ("%.1f" % lo) if absf(hi - lo) < 0.05 else ("%.1f–%.1f" % [lo, hi])]
		t += "%s\n" % struct_effect_text(pd)
		t += "Группы: %s\n" % proj_group_text(bld_pick)
		t += bld_demand_text(pd)
		bld_info_rt.text = "[font_size=13]%s[/font_size]" % t
	var rows: PackedStringArray = []
	for i in regions.size():
		var pr: Dictionary = regions[i]["proj"]
		if pr.is_empty():
			continue
		var pd2 := find_by_id(PROJECTS, pr["id"])
		var a: int = int(pr.get("ate", -1))
		rows.append("• %s — «%s»%s: ещё %d мес." % [pd2.get("name", "?"), REGIONS[i]["name"], (", " + ate_name(a)) if a >= 0 else "", int(pr["left"])])
	bld_list_rt.text = "[font_size=13]%s[/font_size]" % ("\n".join(rows) if rows.size() > 0 else "[color=%s]Сейчас ничего не строится.[/color]" % COL_DIM)
	update_build_extra()


func update_build_extra() -> void:
	if bld_reg_rt == null:
		return
	var si := selected_region
	var t := ""
	if si < 0 or si >= regions.size():
		t = "[color=%s]Выберите регион на карте.[/color]" % COL_DIM
	else:
		var bt: Dictionary = regions[si]["built"]
		if bt.is_empty():
			t = "[color=%s]В регионе «%s» пока нет сооружений.[/color]" % [COL_DIM, REGIONS[si]["name"]]
		else:
			t = "Регион «%s»:\n" % REGIONS[si]["name"]
			for id in bt:
				var e: Dictionary = bt[id]
				var pd := find_by_id(PROJECTS, String(id))
				var cond: float = float(e["cond"])
				var lv: int = int(e.get("lvl", 1))
				var cc: String = COL_GOOD if cond >= 60.0 else (COL_WARN if cond >= 30.0 else COL_BAD)
				var links: PackedStringArray = []
				if lv < CS_LVL_MAX and not bool(pd.get("mega", false)):
					links.append("[url=upg:%s]улучшить до %d (%.1f млрд)[/url]" % [id, lv + 1, gdp * con_upgrade_cost(si, String(id)) / 100.0])
				var rc := con_repair_cost(si, String(id))
				if rc >= 0.0005:
					links.append("[url=rep:%s]ремонт (%.2f млрд)[/url]" % [id, gdp * rc / 100.0])
				t += "• %s%s · уровень %d · состояние [color=%s]%.0f%%[/color]%s\n" % [pd.get("name", id), (" ×%d" % int(e["n"])) if int(e["n"]) > 1 else "", lv, cc, cond,
					(" — " + " · ".join(links)) if links.size() > 0 else ""]
			t += "[color=%s]Уровень 2 даёт эффекты ×1,6, уровень 3 — ×2,1 (и столько же содержание). Сооружения в состоянии ниже 30%% могут попасть в аварию.[/color]" % COL_DIM
	bld_reg_rt.text = "[font_size=13]%s[/font_size]" % t
	var m := con_mega()
	if m.is_empty():
		bld_mega_rt.text = ""
	else:
		var mr := con_mega_region()
		var st := "не начат"
		if struct_total(String(m["id"])) > 0:
			st = "[color=%s]построен[/color]" % COL_GOOD
		elif mr >= 0 and String((regions[mr]["proj"] as Dictionary).get("id", "")) == String(m["id"]):
			st = "строится, ещё %d мес." % int(regions[mr]["proj"]["left"])
		bld_mega_rt.text = "[font_size=13][b]%s[/b] — %s\n%s\nГде: «%s» · %.1f%% ВВП (%.0f млрд) · %d мес. Чтобы начать, выберите его в списке выше и щёлкните по региону.\n%s[/font_size]" % [
			m["name"], st, m.get("desc", ""), String(REGIONS[mr]["name"]) if mr >= 0 else "?", float(m["cost"]), gdp * float(m["cost"]) / 100.0, int(m["months"]), struct_effect_text(m)]
	var ct := ""
	if not con_dyn():
		ct = "[color=%s]Выключено в настройках новой игры («Стройка корпораций и других стран»).[/color]" % COL_DIM
	else:
		var q: Array = cs.get("cq", [])
		for it in q:
			ct += "• «%s» строит «%s» в регионе «%s»: ещё %d мес.\n" % [it["corp"], find_by_id(PROJECTS, String(it["id"])).get("name", it["id"]), REGIONS[int(it["i"])]["name"] if int(it["i"]) < REGIONS.size() else "?", int(it["left"])]
		var lg: Array = cs.get("log", [])
		for k in range(lg.size() - 1, maxi(-1, lg.size() - 6), -1):
			ct += "[color=%s]%s[/color]\n" % [COL_DIM, String(lg[k])]
		var done: PackedStringArray = []
		for r in con_ai_rows():
			if int(r[3]) == 2:
				done.append(String(WORLD[r[0]]["name"]) if WORLD.has(r[0]) else String(r[0]))
		if done.size() > 0:
			ct += "Мегапроекты завершили: %s." % ", ".join(done)
		if ct == "":
			ct = "[color=%s]Пока никто не строит.[/color]" % COL_DIM
	bld_corp_rt.text = "[font_size=13]%s[/font_size]" % ct


# спрос на продукцию рынка, который расширяет сооружение
func bld_demand_text(pd: Dictionary) -> String:
	var k: Dictionary = pd.get("k", {})
	if k.is_empty() or ec.is_empty():
		return "[color=%s]Мощности рынков не меняет.[/color]" % COL_DIM
	var parts: PackedStringArray = []
	for m in k:
		if not (ec["mk"] as Dictionary).has(m):
			continue
		var mk: Dictionary = ec["mk"][m]
		var u: float = float(mk["u"])
		var short: float = float(mk["short"])
		var col: String = COL_GOOD if u > 0.95 or short > 0.01 else (COL_WARN if u > 0.85 else COL_DIM)
		var verdict: String = "спрос выше мощностей — стройка окупится" if u > 0.95 or short > 0.01 else ("спрос высокий" if u > 0.85 else "мощностей пока хватает")
		parts.append("«%s»: загрузка [color=%s]%.0f%%[/color] — %s" % [String(mk_def(String(m))["name"]), col, u * 100.0, verdict])
	return "Спрос: " + "; ".join(parts)


func build_click(pos: Vector2) -> void:
	if pl_deny():
		return
	var a := ate_at(pos)
	var ri := -1
	if a >= 0:
		ri = ate_region(a)
	if ri < 0:
		var ui := unit_at(pos)
		if ui >= 0 and map_unit_local.has(ui):
			ri = int(map_unit_local[ui])
			a = -1
	if ri < 0:
		log_line("[color=%s]Строить можно только на своей территории.[/color]" % COL_WARN)
		return
	var why := project_start_at(ri, bld_pick, a)
	if why != "":
		log_line("[color=%s]Стройка не начата: %s.[/color]" % [COL_WARN, why])
		sfx("bad")
		return
	sfx("good")
	selected_region = ri
	bld_pick = ""
	update_build_window()
	map_ctl.queue_redraw()


# значки сооружений и строек на своих АТЕ (при приближении, на слое «Сооружения»)
func draw_struct_icons(c: Control, s: float, off: Vector2) -> void:
	# 0.55.5: значки только на слое карты «Сооружения» (по умолчанию выключен) или пока выбираете место для стройки
	if map_layer != 14 and bld_pick == "":
		return
	if map_zoom < 1.6 or ate_c.size() == 0:
		return
	var al: float = clampf((map_zoom - 1.6) / 0.8, 0.0, 1.0)
	var rect := Rect2(Vector2.ZERO, c.size)
	for i in regions.size():
		var bt: Dictionary = regions[i]["built"]
		for id in bt:
			var e: Dictionary = bt[id]
			if not e.has("ate"):
				continue
			var pd := find_by_id(PROJECTS, String(id))
			var cat: int = int(pd.get("cat", 0))
			for a in (e["ate"] as Array):
				if int(a) < 0 or int(a) >= ate_c.size():
					continue
				var p: Vector2 = ate_c[int(a)] * s + off
				if not rect.has_point(p):
					continue
				c.draw_circle(p, 8.5, Color(0.06, 0.08, 0.12, 0.85 * al))
				c.draw_arc(p, 8.5, 0.0, TAU, 20, Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.9 * al), 1.2, true)
				Ico.draw_icon(String(PROJ_CAT_ICO[clampi(cat, 0, PROJ_CAT_ICO.size() - 1)]), p - Vector2(5.5, 5.5), 11.0, 1.2, Color(0.95, 0.92, 0.80, al), c)
		var pr: Dictionary = regions[i]["proj"]
		if not pr.is_empty() and int(pr.get("ate", -1)) >= 0 and int(pr["ate"]) < ate_c.size():
			var p2: Vector2 = ate_c[int(pr["ate"])] * s + off
			if rect.has_point(p2):
				var done: float = 1.0 - float(pr["left"]) / maxf(1.0, float(pr["months"]))
				c.draw_circle(p2, 8.5, Color(0.06, 0.08, 0.12, 0.7 * al))
				c.draw_arc(p2, 8.5, -PI / 2.0, -PI / 2.0 + TAU * done, 24, Color(1.0, 0.80, 0.35, al), 2.0, true)
				c.draw_string(c.get_theme_default_font(), p2 + Vector2(-4.0, 4.0), "⚒", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.85, 0.5, al))
