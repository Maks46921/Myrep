extends SceneTree
# v55_3: большой тест графики и механик. Части (аргумент part=):
#   ui   — все рамки, вкладки, окна, 33 слоя карты, окна события/выборов/войны/кризиса: скриншоты + автопроверка
#          (текст вылезает или обрезан, окна наезжают друг на друга, пустые окна, следы перевода и немецкого шаблона), нажатие всех кнопок;
#   mech — каждое событие и каждый вариант ответа, каждый закон и вариант, меры и действия, сохранение и загрузка в разные моменты;
#   bal  — 20 лет игры под управлением ИИ: экономика и политика по годам, выход за правдоподобные пределы.
# Запуск: tools/test.py big_ui|big_mech|big_bal -c DE,FR [--en]; весь набор — tools/test.py big [--en] (6 стран: DE FR GB PL UA RU).
# Скриншоты и находки: .testlogs/big/<язык>_<страна>/ ; отчёт: python3 tools/big_report.py
# FAIL — ошибка (NaN, сломанная кнопка, пустое окно, сохранение теряет данные); FIND — находка для отчёта (графика, перевод, баланс).
var bad := 0
var finds: Array = []
var shots: Array = []
var stats := {}
var trims: Array = []
var out_dir := ""
var part := "ui"
var en := false
var cc := ""
var where := ""
var seen := {}
var CYR := RegEx.new()
var PH := RegEx.new()
var NANRX := RegEx.new()

func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)
		finds.append({"cat": "ошибка", "where": where, "t": msg})

func find(cat: String, t: String) -> void:
	# графика и перевод повторяются на многих экранах — считаем одной находкой (первое место)
	var key := cat + "|" + t if cat in ["графика", "перевод", "шаблон", "текст"] else cat + "|" + where + "|" + t
	if seen.has(key):
		return
	seen[key] = true
	print("FIND: %s | %s | %s" % [cat, where, t])
	finds.append({"cat": cat, "where": where, "t": t})

func mk(o: Dictionary = {}) -> Node:
	var m = load("res://en/main.gd" if en else "res://main.gd").new()
	m.game_opts.merge({"agents": false, "seed": 11}, true)
	m.game_opts.merge(o, true)
	root.add_child(m)
	return m

func settle(g) -> void:
	var n := 0
	while not g.current_event.is_empty() and n < 8:
		g.choose(0)
		n += 1
	if g.election_open: g.election_continue()

func months(g, n: int) -> void:
	for i in n:
		if g.game_over: return
		settle(g)
		g.next_turn()
	settle(g)

func healthy(g, what: String) -> bool:
	for k in ["gdp", "debt", "inflation", "unemployment", "growth", "capital"]:
		var v: float = float(g.get(k))
		if is_nan(v) or is_inf(v):
			check(false, "%s: %s = %s" % [what, k, v])
			return false
	var a: float = g.approval()
	if is_nan(a):
		check(false, "%s: рейтинг NaN" % what)
		return false
	for i in g.regions.size():
		for k2 in ["unrest", "loyalty", "gdppc", "popm"]:
			if (g.regions[i] as Dictionary).has(k2) and is_nan(float(g.regions[i][k2])):
				check(false, "%s: регион %d, %s NaN" % [what, i, k2])
				return false
	return true

func _init():
	for a in OS.get_cmdline_user_args():
		var s := String(a)
		if s.begins_with("part="): part = s.substr(5)
		if s.begins_with("out="): out_dir = s.substr(4)
	en = (get_script() as Script).resource_path.begins_with("res://en/")
	CYR.compile("[А-Яа-яЁё]")
	PH.compile("%[-+0-9.]*[sdf]|\\{[a-z_]+\\}|\\[/?color[^\\]]*$")
	NANRX.compile("(?i)(?<![a-z])(nan|inf)(?![a-z])")
	var g = mk()
	for i in 6: await process_frame
	cc = g.ccode
	if out_dir == "":
		out_dir = ProjectSettings.globalize_path("res://.testlogs/big/%s_%s" % ["en" if en else "ru", cc])
	DirAccess.make_dir_recursive_absolute(out_dir)
	print("[%s %s] часть %s → %s" % [cc, "en" if en else "ru", part, out_dir])
	if part == "ui":
		await run_ui(g)
	elif part == "mech":
		await run_mech(g)
	elif part == "bal":
		await run_bal(g)
	var f := FileAccess.open(out_dir + "/" + part + ".json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"cc": cc, "lang": "en" if en else "ru", "part": part, "bad": bad, "finds": finds, "shots": shots, "stats": stats, "trims": trims}, " "))
	f.close()
	print("находок %d" % finds.size())
	print("проблем %d" % bad)
	quit()


# ---------------- текст ----------------
const DE_WORDS_RU := ["Бундестаг", "Бундесрат", "канцлер", "Канцлер", "АдГ", "Бундесвер", "ХДС", "Шольц", "Мерц"]
const DE_WORDS_EN := ["Bundestag", "Bundesrat", "chancellor", "Chancellor", "AfD", "Bundeswehr", "CDU", "Scholz", "Merz"]

func text_check(g, t: String, ctx: String) -> void:
	if t == "":
		return
	var plain := t
	var m := NANRX.search(plain)
	if m != null:
		check(false, "%s: в тексте «%s»: …%s…" % [ctx, m.get_string(), plain.substr(maxi(0, m.get_start() - 40), 90)])
	var p := PH.search(plain)
	if p != null:
		find("текст", "%s: не подставлено «%s»: …%s…" % [ctx, p.get_string(), plain.substr(maxi(0, p.get_start() - 40), 90)])
	if en:
		var c := CYR.search(plain)
		if c != null:
			find("перевод", "%s: русский текст в английской версии: …%s…" % [ctx, plain.substr(maxi(0, c.get_start() - 30), 80)])
	if cc != "DE" and cc != "AT":
		var ws: Array = DE_WORDS_EN if en else DE_WORDS_RU
		var own := (JSON.stringify(g.TERMS) + JSON.stringify(g.UPPER) + JSON.stringify(g.MINISTRIES) + " ".join(g.PARTY_NAMES)).to_lower()
		for w in ws:
			if plain.contains(w) and not own.contains(String(w).to_lower()):
				var k := plain.find(w)
				find("шаблон", "%s: слово «%s» из немецкого шаблона: …%s…" % [ctx, w, plain.substr(maxi(0, k - 40), 100)])
				break


# ---------------- интерфейс ----------------
func shot(name: String) -> void:
	await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null:
		return
	img.save_png(out_dir + "/" + name + ".png")
	shots.append({"f": name + ".png", "where": where})

func win_title(w) -> String:
	if w.has_method("get_title"):
		return String(w.get_title())
	return String(w.name)

func vis_wins(g) -> Array:
	var out: Array = []
	for id in g.wins:
		var w = g.wins[id]
		if w.is_visible_in_tree() and not bool(w.collapsed):
			out.append([String(id), w])
	return out

func in_hscroll(c: Node, stop: Node) -> bool:
	var n := c.get_parent()
	while n != null and n != stop:
		if n is ScrollContainer and (n as ScrollContainer).horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			return true
		n = n.get_parent()
	return false

func in_scroll(c: Node, stop: Node) -> bool:
	var n := c.get_parent()
	while n != null and n != stop:
		if n is ScrollContainer:
			return true
		n = n.get_parent()
	return false

func ctl_text(c: Control) -> String:
	if c is Label: return (c as Label).text
	if c is Button: return (c as Button).text
	if c is RichTextLabel: return (c as RichTextLabel).get_parsed_text()
	if c is LineEdit: return (c as LineEdit).text
	return ""

# проверка одного окна: вылезающие и обрезанные элементы, пустое окно, текст
func audit_win(g, id: String, w) -> void:
	var wr: Rect2 = (w as Control).get_global_rect()
	var body: Control = w.get("body")
	if body == null:
		return
	var n_vis := [0]
	var texts: Array = []
	_audit_walk(g, body, w, wr, id, n_vis, texts)
	var has_draw := false
	for t in texts:
		if String(t).strip_edges() != "": has_draw = true
	if not has_draw:
		has_draw = _has_drawn(body)
	if n_vis[0] == 0 or not has_draw:
		if String(w.get("lock_why")) == "":
			check(false, "окно «%s» (%s) пустое" % [win_title(w), id])

# содержимое без текста: рисуется само (графики, полосы, диаграммы), списки, картинки
func _has_drawn(n: Node) -> bool:
	for ch in n.get_children():
		if not (ch is Control) or not (ch as Control).is_visible_in_tree():
			continue
		var c := ch as Control
		if c.get_signal_connection_list("draw").size() > 0 or (c.get_script() != null and c.has_method("_draw")):
			return true
		if (c is ItemList and (c as ItemList).item_count > 0) or (c is TextureRect and (c as TextureRect).texture != null) or c is Range:
			return true
		if _has_drawn(c):
			return true
	return false

func _trim(w, label: String, have: float, need: float) -> void:
	stats["trim"] = int(stats.get("trim", 0)) + 1
	var k := win_title(w) + label
	if seen.has("trim|" + k): return
	seen["trim|" + k] = true
	trims.append({"where": where, "t": "окно «%s»: %s сокращено многоточием (%.0f из %.0f px)" % [win_title(w), label, have, need]})

func _audit_walk(g, n: Node, w, wr: Rect2, id: String, n_vis: Array, texts: Array) -> void:
	for ch in n.get_children():
		if not (ch is Control):
			continue
		var c := ch as Control
		if not c.is_visible_in_tree():
			continue
		var r := c.get_global_rect()
		if r.size.x > 2.0 and r.size.y > 2.0:
			n_vis[0] += 1
		var t := ctl_text(c)
		if t != "":
			texts.append(t)
			text_check(g, t, "окно «%s»" % win_title(w))
		var label := ("«%s»" % t.left(40).replace("\n", " ")) if t != "" else c.get_class()
		# за правым краем окна (горизонтальной прокрутки нет — значит, обрезано)
		if r.size.x > 4.0 and r.end.x > wr.end.x + 3.0 and not in_hscroll(c, w):
			find("графика", "окно «%s»: %s вылезает за правый край на %.0f px" % [win_title(w), label, r.end.x - wr.end.x])
			continue
		if not in_scroll(c, w) and r.size.y > 4.0 and r.end.y > wr.end.y + 3.0 and r.position.y < wr.end.y:
			find("графика", "окно «%s»: %s обрезан снизу на %.0f px" % [win_title(w), label, r.end.y - wr.end.y])
		if c is Label:
			var l := c as Label
			if l.autowrap_mode != TextServer.AUTOWRAP_OFF and l.max_lines_visible < 0 and l.get_line_count() > l.get_visible_line_count() and l.clip_text:
				find("графика", "окно «%s»: текст %s не помещается (%d из %d строк)" % [win_title(w), label, l.get_visible_line_count(), l.get_line_count()])
			elif l.autowrap_mode == TextServer.AUTOWRAP_OFF and l.text != "" and (l.clip_text or l.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING):
				var fw: float = l.get_theme_font("font").get_string_size(l.text.get_slice("\n", 0), HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size")).x
				if fw > l.size.x + 4.0 and l.size.x > 8.0:
					if l.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING:
						_trim(w, "подпись " + label, l.size.x, fw)
					else:
						find("графика", "окно «%s»: подпись %s обрезана без многоточия (%.0f из %.0f px)" % [win_title(w), label, l.size.x, fw])
		elif c is Button and (c as Button).text != "" and c.size.x > 8.0:
			var b := c as Button
			var fnt: Font = b.get_theme_font("font")
			var fs: int = b.get_theme_font_size("font_size")
			if b.autowrap_mode != TextServer.AUTOWRAP_OFF:
				# перенос строк: текст должен помещаться по высоте
				var sb: StyleBox = b.get_theme_stylebox("normal")
				var padx: float = (sb.get_margin(SIDE_LEFT) + sb.get_margin(SIDE_RIGHT)) if sb != null else 16.0
				var pady: float = (sb.get_margin(SIDE_TOP) + sb.get_margin(SIDE_BOTTOM)) if sb != null else 0.0
				var th: float = fnt.get_multiline_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, b.size.x - padx, fs).y + pady
				if th > b.size.y + 2.0:
					find("графика", "окно «%s»: текст кнопки %s не помещается по высоте (%.0f из %.0f px)" % [win_title(w), label, b.size.y, th])
			elif b.clip_text:
				var bw: float = fnt.get_string_size(b.text.get_slice("\n", 0), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				if bw > b.size.x - 8.0:
					if b.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING:
						_trim(w, "кнопка " + label, b.size.x, bw + 8.0)
					else:
						find("графика", "окно «%s»: кнопка %s обрезана без многоточия (%.0f из %.0f px)" % [win_title(w), label, b.size.x, bw + 8.0])
		elif c is RichTextLabel:
			var rt := c as RichTextLabel
			if not rt.fit_content and not rt.scroll_active and rt.get_content_height() > rt.size.y + 4.0 and rt.size.y > 4.0:
				find("графика", "окно «%s»: текст %s не помещается по высоте (%d из %d px)" % [win_title(w), label, int(rt.size.y), rt.get_content_height()])
		_audit_walk(g, c, w, wr, id, n_vis, texts)

# окна одного экрана не должны наезжать друг на друга и на полосу организаций, вылезать за экран
func audit_layout(g) -> void:
	var vw: Array = []
	# окна, открываемые по запросу (WIN_DEFAULT_CLOSED), появляются поверх — их наложение не считаем
	for pr in vis_wins(g):
		if not (String(pr[0]) in g.WIN_DEFAULT_CLOSED): vw.append(pr)
	var scr: Rect2 = root.get_visible_rect()
	for k in vw.size():
		var w = vw[k][1]
		if int(w.desk) == -2:
			continue
		var r: Rect2 = (w as Control).get_global_rect()
		if r.end.x > scr.end.x + 2.0 or r.end.y > scr.end.y + 2.0 or r.position.x < -2.0:
			find("графика", "окно «%s» выходит за экран" % win_title(w))
		for j in range(k + 1, vw.size()):
			var w2 = vw[j][1]
			if int(w2.desk) == -2:
				continue
			var r2: Rect2 = (w2 as Control).get_global_rect()
			var x := r.intersection(r2)
			if x.size.x > 6.0 and x.size.y > 6.0 and x.get_area() > 0.03 * minf(r.get_area(), r2.get_area()):
				find("графика", "окна «%s» и «%s» наезжают друг на друга (%.0f×%.0f px)" % [win_title(w), win_title(w2), x.size.x, x.size.y])
		if g.get("io_bar") != null and (g.io_bar as Control).is_visible_in_tree():
			var br: Rect2 = (g.io_bar as Control).get_global_rect()
			var xb := r.intersection(br)
			if xb.size.x > 4.0 and xb.size.y > 4.0:
				find("графика", "полоса организаций наезжает на окно «%s»" % win_title(w))

func audit_screen(g, name: String) -> void:
	await create_timer(0.45).timeout
	for i in 3: await process_frame
	await shot(name)
	audit_layout(g)
	for pr in vis_wins(g):
		audit_win(g, String(pr[0]), pr[1])
	# верхняя панель и подписи вне окон
	for n in [g.get("ui_top"), g.get("subbar"), g.get("subbar2"), g.get("subbar4")]:
		if n != null and (n as Control).is_visible_in_tree():
			_walk_text_only(g, n as Control, "верхняя панель")
	healthy(g, where)

func _walk_text_only(g, n: Control, ctx: String) -> void:
	for ch in n.get_children():
		if ch is Control and (ch as Control).is_visible_in_tree():
			var t := ctl_text(ch as Control)
			if t != "":
				text_check(g, t, ctx)
				if ch is Button and (ch as Button).clip_text:
					var b := ch as Button
					var bw: float = b.get_theme_font("font").get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, b.get_theme_font_size("font_size")).x
					if bw > b.size.x - 8.0:
						find("графика", "%s: кнопка «%s» обрезана" % [ctx, b.text.left(30)])
			_walk_text_only(g, ch as Control, ctx)

const DESK_NAMES := {0: "Бюджет", 1: "Парламент", 2: "Карта", 3: "Законы", 4: "Правительство", 5: "Экономика", 6: "Население", 7: "Экономика 2", 8: "Карта 2", 9: "Карта 3", 10: "Экономика 3", 11: "Общество", 12: "Политика 5", 13: "Армия", 14: "Армия 2", 15: "Карта 6", 16: "Экономика 4", 17: "Экономика 5", 18: "Организации", 19: "Общество 3", 20: "Общество 2"}

func run_ui(g) -> void:
	months(g, 2)
	# 1) все рамки и вкладки
	for d in range(0, 21):
		where = "экран %d" % d
		g.show_desk(d)
		await audit_screen(g, "d%02d" % d)
	# технологии и кризисы — отдельные окна поверх
	where = "технологии"
	g.set_tech_open(true)
	await audit_screen(g, "tech")
	g.set_tech_open(false)
	where = "кризисы"
	g.set_crisis_open(true)
	await audit_screen(g, "crisis")
	g.set_crisis_open(false)
	# все окна, закрытые по умолчанию
	for id in g.WIN_DEFAULT_CLOSED:
		if not g.wins.has(id): continue
		var w = g.wins[id]
		if int(w.desk) < 0: continue
		where = "окно %s" % id
		w.closed = false
		g.show_desk(int(w.desk))
		await audit_screen(g, "w_%s" % id)
	g.reset_layout()
	# 2) слои карты
	g.show_desk(2)
	for i in g.MAP_LAYER_ORDER.size():
		where = "слой карты %d" % int(g.MAP_LAYER_ORDER[i])
		g.on_layer_selected(i)
		await create_timer(0.15).timeout
		await shot("map%02d" % int(g.MAP_LAYER_ORDER[i]))
		var lg: String = g.map_legend.text
		check(lg.length() > 20, "у слоя карты %d нет легенды" % int(g.MAP_LAYER_ORDER[i]))
		text_check(g, lg, "легенда слоя %d" % int(g.MAP_LAYER_ORDER[i]))
		healthy(g, where)
	g.on_layer_selected(0)
	# 3) окно события: событие страны, общее, региональное
	var evs: Array = []
	if not g.EVENTS_C.is_empty(): evs.append([g.EVENTS_C[0], -1])
	if not g.EVENTS_X.is_empty(): evs.append([g.EVENTS_X[3 % g.EVENTS_X.size()], 0 if bool(g.EVENTS_X[3 % g.EVENTS_X.size()].get("rreg", false)) else -1])
	var re: Array = g.reg_events_all()
	for e in re:
		var ok_r := -1
		for i in g.regions.size():
			if g.region_ok(e["reg"], i): ok_r = i; break
		if ok_r >= 0: evs.append([e, ok_r]); break
	for k in evs.size():
		where = "окно события %d" % (k + 1)
		g.current_event = evs[k][0]
		g.event_region = int(evs[k][1])
		g.present_event()
		g.show_desk(0)
		await audit_screen(g, "event%d" % (k + 1))
		g.choose(0)
	# 4) выборы
	where = "выборы"
	g.hold_parliament("досрочные выборы по вашему решению")
	if g.election_open:
		g.show_desk(1)
		await audit_screen(g, "election")
		g.election_continue()
	settle(g)
	# 5) кризис: высокое недовольство в нескольких регионах
	where = "кризис"
	for i in mini(5, g.regions.size()):
		g.regions[i]["unrest"] = 93.0
	months(g, 1)
	g.set_crisis_open(true)
	await audit_screen(g, "crisis2")
	g.set_crisis_open(false)
	# 6) кнопки: нажать каждую на каждом экране (с откатом состояния)
	await press_all(g)
	# 7) война: экраны армии и переговоров
	var tg: Array = g.mil_targets()
	if not tg.is_empty():
		where = "война"
		g.capital = 200.0
		g.mil_declare(String(tg[0]), true)
		for k in 45:
			settle(g)
			g.advance_day()
		settle(g)
		for d in [13, 14, 2]:
			where = "война, экран %d" % d
			g.show_desk(d)
			await audit_screen(g, "war_d%02d" % d)
		where = "война, кнопки"
		await press_all(g, [13, 14])

# --- нажатие кнопок ---
const SKIP_BTN := ["Выход", "Выйти", "Новая игра", "Главное меню", "Сменить страну", "Загрузить", "Quit", "Exit", "New game", "Main menu", "Change country", "Load", "×", "✕"]

func btn_skip(b: BaseButton) -> bool:
	var t := ""
	if b is Button: t = (b as Button).text
	for s in SKIP_BTN:
		if t.contains(s): return true
	if b.disabled: return true
	return false

func collect_btns(n: Node, out: Array, keyset: Dictionary, wt: String) -> void:
	for ch in n.get_children():
		if ch is Control and (ch as Control).is_visible_in_tree():
			if ch is BaseButton and not btn_skip(ch as BaseButton):
				var t := (ch as Button).text if ch is Button else ch.get_class()
				var key := wt + "|" + t.left(18)
				if not keyset.has(key):
					keyset[key] = true
					out.append([ch, wt + ": " + t.left(40).replace("\n", " ")])
			collect_btns(ch, out, keyset, wt)

func press_all(g, desks: Array = []) -> void:
	if desks.is_empty():
		desks = range(0, 21)
	var snap: PackedByteArray = g.sv_pack()
	var n_press := 0
	var t0 := Time.get_ticks_msec()
	for d in desks:
		g.show_desk(d)
		await process_frame
		var lst: Array = []
		var ks := {}
		for pr in vis_wins(g):
			if int(pr[1].desk) == -1 and d != desks[0]: continue
			collect_btns(pr[1].get("body"), lst, ks, win_title(pr[1]))
		for k in mini(lst.size(), 90):
			var b = lst[k][0]
			if not is_instance_valid(b) or not (b as Control).is_visible_in_tree():
				continue
			where = "экран %d, кнопка %s" % [d, lst[k][1]]
			if b is OptionButton:
				var ob := b as OptionButton
				if ob.item_count > 1:
					var sel := (ob.selected + 1) % ob.item_count
					ob.select(sel)
					ob.item_selected.emit(sel)
			elif b is CheckBox or b is CheckButton or (b as BaseButton).toggle_mode:
				(b as BaseButton).button_pressed = not (b as BaseButton).button_pressed
			else:
				(b as BaseButton).pressed.emit()
			n_press += 1
			await process_frame
			healthy(g, where)
			# закрыть всплывающие окна и вернуть состояние
			for pw in g.find_children("*", "Window", true, false):
				if (pw as Window).visible: (pw as Window).hide()
			if not g.current_event.is_empty() or g.election_open or n_press % 6 == 0:
				g.sv_apply(snap)
				g.current_event = {}
				g.election_open = false
				for wid in ["event", "election"]:
					if g.wins.has(wid): g.wins[wid].visible = false
			if g.current_desk != d or g.tech_is_open() or g.crisis_is_open():
				if g.tech_is_open(): g.set_tech_open(false)
				if g.crisis_is_open(): g.set_crisis_open(false)
				g.show_desk(d)
				await process_frame
		g.sv_apply(snap)
		g.refresh()
	where = "кнопки"
	stats["buttons"] = int(stats.get("buttons", 0)) + n_press
	print("  нажато кнопок: %d за %.0f с" % [n_press, (Time.get_ticks_msec() - t0) / 1000.0])


# ---------------- механики ----------------
func ev_pools(g) -> Array:
	var out: Array = []
	var seen_ids := {}
	var add := func(lst: Array, kind: String) -> void:
		for e in lst:
			var key := String(e.get("id", "")) + String(e.get("t", "")).left(60)
			if seen_ids.has(key): continue
			seen_ids[key] = true
			out.append([e, kind])
	for e in g.EVENTS:
		if cc != "DE" and not e.has("reg") and g.ev_de_only(String(e.get("t", ""))) and not g.EVENTS_C.has(e):
			continue
		add.call([e], "общее")
	add.call(g.ECON_EVENTS, "экономика")
	add.call(g.EVENTS_C, "страна")
	add.call(g.EVENTS_SPECIAL, "сценарий")
	add.call(g.EVENTS_X, "событие v46")
	add.call(g.radical_events(), "радикалы")
	add.call(g.reg_events_all(), "регион")
	return out

func ev_region(g, e: Dictionary) -> int:
	if e.has("reg"):
		for i in g.regions.size():
			if g.region_ok(e["reg"], i): return i
		return -2
	if bool(e.get("rreg", false)):
		return 0
	return -1

func run_mech(g) -> void:
	months(g, 1)
	g.observer = false
	var snap: PackedByteArray = g.sv_pack()
	# 1) все события и все варианты
	var evs: Array = ev_pools(g)
	var n_opt := 0
	var n_ev := 0
	var t0 := Time.get_ticks_msec()
	for k in evs.size():
		var e: Dictionary = evs[k][0]
		var ri: int = ev_region(g, e)
		if ri == -2: continue
		n_ev += 1
		var tt: String = String(e.get("title", "")) if e.has("title") else String(e.get("t", "")).left(50)
		where = "событие «%s» (%s)" % [tt.replace("\n", " "), evs[k][1]]
		var txt: String = g.coal_text(g.ev_text(String(e.get("t", ""))))
		if ri >= 0: txt = txt.replace("{r}", String(g.REGIONS[ri]["name"]))
		text_check(g, g.loc(txt), "текст события")
		var opts: Array = e.get("o", [])
		check(opts.size() >= 1, "у события нет вариантов")
		for o in opts.size():
			text_check(g, g.loc(g.coal_text(g.ev_text(String(opts[o]["l"])))), "вариант %d" % (o + 1))
			text_check(g, g.describe_fx(opts[o]["fx"], ri), "последствия варианта %d" % (o + 1))
			g.capital = maxf(g.capital, 60.0)
			g.current_event = e
			g.event_region = ri
			g.choose(o)
			n_opt += 1
			settle(g)
			if (n_opt % 40) == 0:
				g.next_turn()
				settle(g)
			healthy(g, where + ", вариант %d" % (o + 1))
			if n_opt % 12 == 0:
				g.sv_apply(snap)
			if n_opt % 100 == 0:
				print("  … вариантов %d, %.0f с" % [n_opt, (Time.get_ticks_msec() - t0) / 1000.0])
	stats["events"] = n_ev
	stats["options"] = n_opt
	print("  событий %d, вариантов %d за %.0f с" % [n_ev, n_opt, (Time.get_ticks_msec() - t0) / 1000.0])
	# 2) все законы и все варианты: принятие с поддержкой всех партий
	var allp: Array = range(1, g.PARTY_NAMES.size())
	var n_law := 0
	var n_ok := 0
	var not_ok: Array = []
	for tid in g.law_index:
		var t: Dictionary = g.law_index[tid]
		for idx in (t["v"] as Array).size():
			if idx == g.cur_idx(String(tid)): continue
			where = "закон «%s» → «%s»" % [t["name"], t["v"][idx]["n"]]
			text_check(g, String(t["v"][idx].get("d", "")), "описание варианта")
			g.capital = 1000.0
			g.law_cd.clear()
			g.adopt_variant(String(tid), idx, allp)
			n_law += 1
			if g.cur_idx(String(tid)) == idx or g.is_hybrid(String(tid)):
				n_ok += 1
			else:
				not_ok.append("%s → %s" % [t["name"], t["v"][idx]["n"]])
			settle(g)
			healthy(g, where)
			if n_law % 8 == 0:
				g.sv_apply(snap)
	stats["laws"] = n_law
	stats["laws_ok"] = n_ok
	stats["laws_no"] = not_ok
	print("  законов-вариантов %d, принято %d; не приняты (блокировки, верхняя палата, условия): %d" % [n_law, n_ok, not_ok.size()])
	for s in not_ok.slice(0, 12): print("    не принят: ", s)
	# все законы сразу в крайнее положение и 12 месяцев
	where = "все законы в крайнем варианте"
	for tid in g.law_index:
		g.capital = 1000.0
		g.law_cd.clear()
		g.adopt_variant(String(tid), (g.law_index[tid]["v"] as Array).size() - 1, allp)
		settle(g)
	months(g, 12)
	healthy(g, where)
	g.sv_apply(snap)
	# 3) меры и действия
	var n_m := 0
	for m in g.MEASURES:
		where = "мера «%s»" % m["name"]
		g.capital = 500.0
		g.cooldown.clear()
		g.do_measure(String(m["id"]))
		settle(g)
		n_m += 1
		healthy(g, where)
	g.sv_apply(snap)
	for a in g.ACTIONS:
		if String(a["id"]) in ["snap"]: continue
		where = "действие «%s»" % a["name"]
		g.capital = 500.0
		g.cooldown.clear()
		g.do_action(String(a["id"]))
		settle(g)
		n_m += 1
		healthy(g, where)
	g.sv_apply(snap)
	stats["measures"] = n_m
	print("  мер и действий: %d" % n_m)
	# 4) сохранение и загрузка в разные моменты
	await save_cycle(g, "начало игры")
	months(g, 13)
	await save_cycle(g, "после 13 месяцев")
	var tg: Array = g.mil_targets()
	if not tg.is_empty():
		g.capital = 200.0
		g.mil_declare(String(tg[0]), true)
		for k in 40:
			settle(g)
			g.advance_day()
		await save_cycle(g, "во время войны")
	g.hold_parliament("досрочные выборы по вашему решению")
	await save_cycle(g, "во время выборов")
	settle(g)

func vars_of(bytes: PackedByteArray) -> Dictionary:
	var d: Dictionary = bytes_to_var(bytes)
	return d["vars"]

func save_cycle(g, moment: String) -> void:
	where = "сохранение: " + moment
	var p1: PackedByteArray = g.sv_pack()
	var v1 := vars_of(p1)
	months(g, 2)
	check(g.sv_apply(p1), "снимок не загрузился")
	var v2 := vars_of(g.sv_pack())
	var diff: Array = []
	for k in v1:
		if k in ["election_open", "game_over", "ag_ver"]: continue
		if not v2.has(k) or var_to_str(v1[k]) != var_to_str(v2[k]):
			diff.append(String(k))
	check(diff.size() == 0, "после загрузки отличаются: %s" % ", ".join(diff.slice(0, 12)))
	# загрузка в новую игру (как после перезапуска) и файл на диске
	check(g.sv_save(9), "файл сохранения не записан")
	var g2 = mk()
	for i in 4: await process_frame
	check(g2.sv_load(9), "файл сохранения не загрузился в новую игру")
	check(g2.turn == g.turn and absf(g2.gdp - g.gdp) < 1e-6 and absf(g2.debt - g.debt) < 1e-6, "новая игра после загрузки: месяц/ВВП/долг не совпадают")
	for d in [0, 1, 2, 3, 5, 11, 13, 18]:
		g2.show_desk(d)
	months(g2, 3)
	healthy(g2, where + " (новая игра после загрузки)")
	root.remove_child(g2)
	g2.free()
	DirAccess.remove_absolute(g.sv_path(9))
	await process_frame
	stats["saves"] = int(stats.get("saves", 0)) + 1
	print("  сохранение «%s»: отличий %d" % [moment, diff.size()])


# ---------------- баланс: 20 лет под управлением ИИ ----------------
func run_bal(g) -> void:
	g.observer_start()
	var rows: Array = []
	var gdp0: float = g.gdp
	var low_appr := 0
	var hi_inf := 0
	var hi_un := 0
	for y in 20:
		for m in 12:
			if g.game_over: break
			if not g.current_event.is_empty(): g.choose(0)
			if g.election_open: g.election_continue()
			g.next_turn()
			if not healthy(g, "баланс, год %d" % (y + 1)): return
		settle(g)
		if g.game_over: break
		var row := {"y": 2026 + y + 1, "gdp": snappedf(g.gdp / gdp0 * 100.0, 0.1), "growth": snappedf(g.growth, 0.1), "infl": snappedf(g.inflation, 0.1), "unemp": snappedf(g.unemployment, 0.1),
			"debt": snappedf(g.debt / g.gdp * 100.0, 0.1), "appr": snappedf(g.approval(), 0.1), "cap": snappedf(g.capital, 0.1), "regime": String(g.regime_id()), "gov": g.gov_seats(), "opp": g.opp_mode}
		rows.append(row)
		print("  %d: ВВП %.0f%% от старта, рост %.1f%%, инфляция %.1f%%, безработица %.1f%%, долг %.0f%% ВВП, рейтинг %.0f%%, капитал %.0f, режим %s%s" % [row["y"], row["gdp"], row["growth"], row["infl"], row["unemp"], row["debt"], row["appr"], row["cap"], row["regime"], ", в оппозиции" if g.opp_mode else ""])
		where = "баланс, %d" % row["y"]
		if float(row["infl"]) > 25.0 or float(row["infl"]) < -5.0: hi_inf += 1
		if float(row["unemp"]) > 25.0 or float(row["unemp"]) < 0.5: hi_un += 1
		if float(row["appr"]) < 8.0 or float(row["appr"]) > 92.0: low_appr += 1
		if float(row["debt"]) > 250.0: find("баланс", "долг %.0f%% ВВП" % row["debt"])
	where = "баланс, итог"
	if g.game_over: find("баланс", "игра закончилась через %d мес.: %s" % [g.turn, String(g.end_reason).left(120)])
	if hi_inf >= 2: find("баланс", "инфляция вне 5…25%% %d лет из %d" % [hi_inf, rows.size()])
	if hi_un >= 2: find("баланс", "безработица вне 0,5…25%% %d лет из %d" % [hi_un, rows.size()])
	if low_appr >= 3: find("баланс", "рейтинг у края шкалы (<8%% или >92%%) %d лет" % low_appr)
	if not rows.is_empty():
		var last: Dictionary = rows[rows.size() - 1]
		var yrs: float = float(rows.size())
		var cagr: float = (pow(float(last["gdp"]) / 100.0, 1.0 / yrs) - 1.0) * 100.0
		stats["cagr"] = snappedf(cagr, 0.01)
		print("  итог: %d лет, средний номинальный рост ВВП %.1f%% в год" % [rows.size(), cagr])
		if cagr > 9.0 or cagr < -3.0: find("баланс", "средний рост ВВП %.1f%% в год за %d лет" % [cagr, rows.size()])
	stats["rows"] = rows
	var f := FileAccess.open(out_dir + "/bal_rows.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(rows))
	f.close()
