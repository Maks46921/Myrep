# v51_1: «Экономика» → «Управление экономикой» (у каждой модели свой пульт: Госплан, промполитика, социальное
# партнёрство, госкорпорации, рыночный регулятор, самоуправление) и «Корпорации» (крупнейшие компании страны,
# иностранный капитал). Вид окон меняется вместе с моделью: свой цвет, своя панель показателей.
extends "res://scripts/ui/ui_regime.gd"

const ES_SKIN := {
	"mixed": Color(0.30, 0.72, 0.70), "market": Color(0.36, 0.80, 0.50), "libertarian": Color(0.95, 0.76, 0.28),
	"social": Color(0.42, 0.62, 0.96), "statecap": Color(0.88, 0.56, 0.26), "planned": Color(0.90, 0.24, 0.20), "coop": Color(0.96, 0.52, 0.28)}
const ECON_DESKS := [5, 7, 10, 16, 17]
const SECT_COL := {"agr": Color(0.55, 0.78, 0.35), "res": Color(0.62, 0.52, 0.42), "ind": Color(0.55, 0.62, 0.80), "ene": Color(0.95, 0.75, 0.25),
	"con": Color(0.85, 0.55, 0.35), "srv": Color(0.55, 0.75, 0.90)}

var ui_es_cls := ""
var es_head: Control = null
var es_ctl_box: VBoxContainer = null
var es_btns := {}
var es_dash: Control = null
var es_info_rt: RichTextLabel = null
var es_log_rt: RichTextLabel = null
var co_listc: Control = null
var co_head: Control = null
var co_card_rt: RichTextLabel = null
var co_btns := {}
var co_bar: Control = null
var co_for_rt: RichTextLabel = null
var co_for_btns := {}
var co_row_h := 46.0


func es_acc() -> Color:
	return ES_SKIN.get(ui_es_cls, C_TEAL)


func es_skin_acc(desk: int) -> Color:
	if ui_es_cls == "" or ui_es_cls == "mixed" or not (desk in ECON_DESKS):
		return accent_for_desk(desk)
	return es_acc()


func build_econsys_windows() -> void:
	var w: FloatWindow = new_window("es_main", "Пульт управления экономикой", 16, Rect2(0.0, 0.0, 0.30, 1.0))
	es_head = Control.new()
	es_head.custom_minimum_size = Vector2(0.0, 70.0)
	es_head.draw.connect(es_draw_head)
	w.body.add_child(es_head)
	es_ctl_box = VBoxContainer.new()
	es_ctl_box.add_theme_constant_override("separation", 5)
	w.body.add_child(es_ctl_box)

	w = new_window("es_dash", "Панель показателей", 16, Rect2(0.30, 0.0, 0.40, 0.62), false)
	es_dash = Control.new()
	es_dash.size_flags_vertical = Control.SIZE_EXPAND_FILL
	es_dash.custom_minimum_size = Vector2(0.0, 200.0)
	es_dash.draw.connect(es_draw_dash)
	w.body.add_child(es_dash)

	w = new_window("es_info", "Как устроена модель", 16, Rect2(0.30, 0.62, 0.40, 0.38))
	es_info_rt = make_rt(w.body)
	add_title(w.body, "Хроника")
	es_log_rt = make_rt(w.body)

	w = new_window("co_list", "Крупнейшие компании страны", 17, Rect2(0.0, 0.0, 0.34, 1.0))
	co_listc = Control.new()
	co_listc.custom_minimum_size = Vector2(0.0, 400.0)
	co_listc.draw.connect(co_draw_list)
	co_listc.gui_input.connect(co_list_input)
	co_listc.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	w.body.add_child(co_listc)

	w = new_window("co_card", "Компания", 17, Rect2(0.34, 0.0, 0.36, 0.60))
	co_head = Control.new()
	co_head.custom_minimum_size = Vector2(0.0, 84.0)
	co_head.draw.connect(co_draw_head)
	w.body.add_child(co_head)
	co_card_rt = make_rt(w.body)
	add_title(w.body, "Действия")
	for a in CO_ACTS:
		var b := make_button(String(a[1]), w.body)
		b.theme_type_variation = "SmallButton"
		b.tooltip_text = String(a[3])
		var aid: String = String(a[0])
		b.pressed.connect(func() -> void:
			sfx("good" if co_act(aid, int(corp.get("sel", 0))) else "bad")
			refresh())
		co_btns[aid] = b

	w = new_window("co_for", "Иностранный капитал", 17, Rect2(0.34, 0.60, 0.36, 0.40))
	co_bar = Control.new()
	co_bar.custom_minimum_size = Vector2(0.0, 58.0)
	co_bar.draw.connect(co_draw_bar)
	w.body.add_child(co_bar)
	co_for_rt = make_rt(w.body)
	for fid in [["invite", "Пригласить иностранных инвесторов (6)"], ["jv", "Совместное предприятие с иностранцами (6)"], ["restrict", "Ограничить иностранный капитал (6)"]]:
		var b2 := make_button(String(fid[1]), w.body)
		b2.theme_type_variation = "SmallButton"
		var f2: String = String(fid[0])
		b2.pressed.connect(func() -> void:
			sfx("good" if co_foreign(f2) else "bad")
			refresh())
		co_for_btns[f2] = b2


# ---------- смена модели ----------
func es_ui_sync() -> void:
	if es.is_empty() or wins.is_empty() or not wins.has("es_main"):
		return
	var cls := econ_class()
	if cls != String(es["cls"]):
		es_class_changed(String(es["cls"]), cls)
	if cls == ui_es_cls:
		return
	var first: bool = ui_es_cls == ""
	ui_es_cls = cls
	es_build_controls()
	(wins["es_main"] as FloatWindow).set_title(String(ES_DESK.get(cls, "Пульт управления экономикой")))
	if sub2_buttons.size() >= 5:
		reg_tab_set_plain(sub2_buttons[3], String(ES_DESK.get(cls, "Управление")), "gauge", es_acc())
	for id in wins:
		var w: FloatWindow = wins[id]
		if w.desk in ECON_DESKS:
			w.set_skin(es_skin_acc(w.desk), C_PANEL, C_BORDER)
	if not first:
		es_flash()


func reg_tab_set_plain(b: Button, txt: String, ico: String, col: Color) -> void:
	for ch in b.get_children():
		ch.queue_free()
	b.text = txt
	btn_icon(b, ico, col.lightened(0.25))


# короткая вспышка-баннер о смене модели поверх раздела экономики
func es_flash() -> void:
	if DisplayServer.get_name() == "headless" or OS.get_cmdline_args().has("--script") or OS.get_cmdline_args().has("-s"):
		if not OS.get_cmdline_user_args().has("regime=1"):
			return
	var ov := Control.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ov)
	var cls := ui_es_cls
	ov.draw.connect(func() -> void:
		var sz: Vector2 = ov.size
		var acc: Color = ES_SKIN.get(cls, C_ACCENT)
		ov.draw_rect(Rect2(0.0, sz.y * 0.5 - 60.0, sz.x, 120.0), Color(0, 0, 0, 0.75))
		Gfx.hgrad(ov, Rect2(0.0, sz.y * 0.5 - 60.0, sz.x * 0.5, 120.0), Color(acc.r, acc.g, acc.b, 0.0), Color(acc.r, acc.g, acc.b, 0.3))
		Gfx.hgrad(ov, Rect2(sz.x * 0.5, sz.y * 0.5 - 60.0, sz.x * 0.5, 120.0), Color(acc.r, acc.g, acc.b, 0.3), Color(acc.r, acc.g, acc.b, 0.0))
		var f: Font = ov.get_theme_default_font()
		Gfx.label(ov, f, Vector2(0.0, sz.y * 0.5 - 10.0), "НОВАЯ ЭКОНОМИЧЕСКАЯ МОДЕЛЬ", 15, Color(0.85, 0.85, 0.85), sz.x, HORIZONTAL_ALIGNMENT_CENTER)
		Gfx.label(ov, f, Vector2(0.0, sz.y * 0.5 + 26.0), String(ES_NAMES.get(cls, cls)).to_upper(), 30, acc.lightened(0.3), sz.x, HORIZONTAL_ALIGNMENT_CENTER))
	ov.modulate.a = 0.0
	var tw := ov.create_tween()
	tw.tween_property(ov, "modulate:a", 1.0, 0.4)
	tw.tween_interval(1.8)
	tw.tween_property(ov, "modulate:a", 0.0, 0.6)
	tw.tween_callback(ov.queue_free)


func es_build_controls() -> void:
	for ch in es_ctl_box.get_children():
		ch.queue_free()
	es_btns.clear()
	var cls := ui_es_cls
	match cls:
		"planned":
			add_title(es_ctl_box, "Пятилетний план: задания отраслям")
			for s in ES_PLAN_SECT:
				var hb := HBoxContainer.new()
				hb.add_theme_constant_override("separation", 4)
				es_ctl_box.add_child(hb)
				var l := Label.new()
				l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				l.add_theme_font_size_override("font_size", 13)
				hb.add_child(l)
				for sg in ["-", "+"]:
					var b := Button.new()
					b.text = "−" if sg == "-" else "+"
					b.custom_minimum_size = Vector2(30.0, 0.0)
					b.focus_mode = Control.FOCUS_NONE
					var id: String = "plan:%s:%s" % [String(s[0]), sg]
					b.pressed.connect(es_do.bind(id))
					hb.add_child(b)
					es_btns[id] = b
				es_btns["lbl:" + String(s[0])] = l
			add_note(es_ctl_box, "Напряжённый план ускоряет рост, но его труднее выполнить; если урезать план по товарам народного потребления и селу — в магазинах дефицит.")
			add_title(es_ctl_box, "Цены и выполнение плана")
			for id2 in ["price_up", "price_dn", "storm"]:
				es_add_btn(id2)
		"mixed", "statecap":
			add_title(es_ctl_box, "Приоритетные отрасли (до двух)")
			var fl := HFlowContainer.new()
			fl.add_theme_constant_override("h_separation", 4)
			fl.add_theme_constant_override("v_separation", 4)
			es_ctl_box.add_child(fl)
			for m in ES_SECT_NAMES:
				var b2 := Button.new()
				b2.theme_type_variation = "SmallButton"
				b2.toggle_mode = true
				b2.text = String(ES_SECT_NAMES[m])
				b2.focus_mode = Control.FOCUS_NONE
				b2.pressed.connect(es_do.bind("prio:" + String(m)))
				fl.add_child(b2)
				es_btns["prio:" + String(m)] = b2
			add_note(es_ctl_box, "Приоритет: субсидии, льготные кредиты и госзаказ — рост +0,05 п. п. за каждый, расходы +0,1% ВВП.")
			if cls == "statecap":
				add_title(es_ctl_box, "Кредиты госбанков")
				var fl2 := HFlowContainer.new()
				fl2.add_theme_constant_override("h_separation", 4)
				fl2.add_theme_constant_override("v_separation", 4)
				es_ctl_box.add_child(fl2)
				for m2 in ES_SECT_NAMES:
					var b3 := Button.new()
					b3.theme_type_variation = "SmallButton"
					b3.toggle_mode = true
					b3.text = String(ES_SECT_NAMES[m2])
					b3.focus_mode = Control.FOCUS_NONE
					b3.pressed.connect(es_do.bind("credit:" + String(m2)))
					fl2.add_child(b3)
					es_btns["credit:" + String(m2)] = b3
				add_note(es_ctl_box, "Госбанки по указанию сверху кредитуют выбранный сектор: рост +0,08 п. п., коррупция +1.")
			else:
				add_title(es_ctl_box, "Другие меры")
				for id3 in ["dereg", "retrain"]:
					es_add_btn(id3)
		"market", "libertarian":
			add_title(es_ctl_box, "Рыночные реформы")
			for id4 in ["dereg", "startup", "voucher"]:
				es_add_btn(id4)
			add_note(es_ctl_box, "Государство не выбирает отрасли: оно задаёт правила. Работа с компаниями — в разделе «Корпорации» (антимонопольные расследования, приватизация, инвестсоглашения).")
		"social":
			add_title(es_ctl_box, "Социальное партнёрство")
			for id5 in ["deal", "wage_up", "wage_dn", "retrain"]:
				es_add_btn(id5)
		"coop":
			add_title(es_ctl_box, "Рабочее самоуправление")
			for id6 in ["share_up", "share_dn", "coop_bank", "congress"]:
				es_add_btn(id6)


func es_add_btn(id: String) -> void:
	var a := es_act_def(id)
	if not (ui_es_cls in String(a[4]).split(",")):
		return
	var b := make_button(String(a[1]), es_ctl_box)
	b.theme_type_variation = "SmallButton"
	b.tooltip_text = String(a[5])
	b.pressed.connect(es_do.bind(id))
	es_btns[id] = b


func es_do(id: String) -> void:
	sfx("good" if es_act(id) else "bad")
	refresh()


func update_es_windows() -> void:
	if es.is_empty() or es_head == null:
		return
	es_head.queue_redraw()
	es_dash.queue_redraw()
	for id in es_btns:
		if String(id).begins_with("lbl:"):
			var sk: String = String(id).substr(4)
			for s in ES_PLAN_SECT:
				if String(s[0]) == sk:
					(es_btns[id] as Label).text = "%s: %s" % [String(s[1]), ES_PLAN_LVL[int(es["plan"][sk])]]
			continue
		var b: Button = es_btns[id]
		var why := es_check(String(id))
		if String(id).begins_with("prio:"):
			b.set_pressed_no_signal(String(id).substr(5) in es["prio"])
			b.disabled = why != "" and not b.button_pressed
		elif String(id).begins_with("credit:"):
			b.set_pressed_no_signal(String(es.get("credit", "")) == String(id).substr(7))
			b.disabled = why != ""
		elif String(id).begins_with("plan:"):
			b.disabled = why != ""
		else:
			var a := es_act_def(String(id))
			b.disabled = why != ""
			b.text = String(a[1]) + (" (%.0f)" % float(a[2])) + ("" if why == "" or why.begins_with("нужно") else " — " + why)
		b.tooltip_text = (b.tooltip_text.split("\nСейчас")[0]) + ("" if why == "" else "\nСейчас нельзя: " + why)
	var cls: String = ui_es_cls
	var t := "[b]%s[/b]. %s.\n" % [String(ES_NAMES.get(cls, cls)), String(ES_MOTTO.get(cls, ""))]
	match cls:
		"planned":
			t += "Цены назначает государство, предприятия выполняют план. Первые годы план даёт рывок, потом растут дефицит и чёрный рынок. Выполнение плана — [b]%.0f%%[/b], дефицит — [b]%.0f[/b] из 100, до конца пятилетки — %s." % [float(es["ful"]), shortage, months_text(maxi(0, 60 - (turn - int(es["five_t"]))))]
		"social":
			t += "Зарплаты и условия труда согласуются в трёхсторонней комиссии. Риск забастовок — [b]%.0f[/b] из 100: растёт с инфляцией, безработицей и без новых соглашений." % float(es["strike"])
		"statecap":
			t += "Государство контролирует [b]%.0f%%[/b] выручки крупнейших компаний; госбанки кредитуют то, что велено." % (corp_state_share() * 100.0)
		"market", "libertarian":
			t += "Деловой климат — [b]%.0f[/b] из 100, биржевой индекс — [b]%.0f[/b] (старт = 100)." % [float(es["conf"]), float(es["idx"])]
		"coop":
			var n := 0
			for c in corp.get("list", []):
				if bool(c.get("coop", false)):
					n += 1
			t += "Кооперативов среди крупнейших компаний: [b]%d[/b] из %d. Доля прибыли коллективам: %s." % [n, (corp.get("list", []) as Array).size(), ["низкая", "средняя", "высокая"][int(es["share"])]]
		_:
			t += "Деловой климат — [b]%.0f[/b] из 100. Приоритетные отрасли: %s." % [float(es["conf"]), ", ".join((es["prio"] as Array).map(func(x) -> String: return String(ES_SECT_NAMES.get(x, x)))) if (es["prio"] as Array).size() > 0 else "не выбраны"]
	t += "\n[color=%s]Модель меняется законом «Экономическая модель» (раздел «Законы»). Вместе с ней меняются этот пульт, работа с компаниями и иностранный капитал.[/color]" % COL_DIM
	es_info_rt.text = t
	var lg: Array = es.get("log", [])
	es_log_rt.text = "[font_size=12]%s[/font_size]" % ("\n".join(lg.slice(0, 6)) if lg.size() > 0 else "[color=%s]Пока без решений.[/color]" % COL_DIM)


func es_draw_head() -> void:
	var c := es_head
	var sz: Vector2 = c.size
	var acc := es_acc()
	Gfx.hgrad(c, Rect2(Vector2.ZERO, sz), Color(acc.r, acc.g, acc.b, 0.30), Color(acc.r, acc.g, acc.b, 0.0))
	var p := Vector2(34.0, sz.y * 0.5)
	c.draw_circle(p, 27.0, Color(acc.r, acc.g, acc.b, 0.25))
	c.draw_arc(p, 27.0, 0.0, TAU, 48, acc, 2.0, true)
	var ico: String = {"planned": "star", "market": "trend", "libertarian": "coin", "social": "handshake", "statecap": "bank", "coop": "people"}.get(ui_es_cls, "chart")
	if ico == "star":
		Gfx.star(c, p, 16.0, acc.lightened(0.3), Color(0, 0, 0, 0.4))
	else:
		Ico.draw_icon(ico, p - Vector2(15.0, 15.0), 30.0, 2.0, acc.lightened(0.3), c)
	var f: Font = c.get_theme_default_font()
	c.draw_string(f, Vector2(72.0, 28.0), String(ES_NAMES.get(ui_es_cls, "")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, sz.x - 76.0, 16, acc.lightened(0.35))
	c.draw_string(f, Vector2(72.0, 48.0), String(ES_MOTTO.get(ui_es_cls, "")), HORIZONTAL_ALIGNMENT_LEFT, sz.x - 76.0, 11, Color(0.80, 0.82, 0.88))


# ---------- панель показателей: своя у каждой модели ----------
func es_draw_dash() -> void:
	var c := es_dash
	if es.is_empty():
		return
	var sz: Vector2 = c.size
	var f: Font = c.get_theme_default_font()
	var acc := es_acc()
	match ui_es_cls:
		"planned":
			es_draw_plan(c, sz, f, acc)
		"social":
			es_draw_gauge(c, Vector2(sz.x * 0.28, sz.y * 0.62), minf(sz.x * 0.22, sz.y * 0.45), float(es["strike"]), "риск забастовок", f)
			var lv: int = int(es["wage"])
			c.draw_string(f, Vector2(sz.x * 0.56, 30.0), "Зарплатные соглашения", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.9, 0.95))
			for k in 3:
				var r := Rect2(sz.x * 0.56 + float(k) * 70.0, 44.0, 62.0, 26.0)
				c.draw_rect(r, Color(acc.r, acc.g, acc.b, 0.85) if k == lv else Color(1, 1, 1, 0.06))
				c.draw_string(f, r.position + Vector2(0.0, 18.0), ["сдерж.", "умерен.", "высокие"][k], HORIZONTAL_ALIGNMENT_CENTER, 62.0, 12, Color(0.95, 0.95, 0.95))
			es_draw_bars(c, Rect2(sz.x * 0.56, 96.0, sz.x * 0.40, sz.y - 110.0), f, [["Инфляция", inflation, 10.0], ["Безработица", unemployment, 20.0], ["Поддержка рабочих", float(support["Рабочие"]), 100.0], ["Поддержка бизнеса", float(support["Бизнес"]), 100.0]], acc)
		"statecap":
			es_draw_donut(c, Vector2(sz.x * 0.27, sz.y * 0.5), minf(sz.x * 0.2, sz.y * 0.38), corp_state_share(), "госсектор", f, acc)
			var rows: Array = []
			for m in ES_SECT_NAMES:
				var v: float = 0.0
				if not ec.is_empty() and (ec["mk"] as Dictionary).has(m):
					v = float(ec["mk"][m]["u"]) * 100.0
				rows.append([String(ES_SECT_NAMES[m]) + (" ★" if m in es["prio"] else "") + (" ₽" if String(es.get("credit", "")) == m else ""), v, 110.0])
			c.draw_string(f, Vector2(sz.x * 0.52, 22.0), "Загрузка отраслей (★ приоритет, ₽ кредиты)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.9, 0.9, 0.95))
			es_draw_bars(c, Rect2(sz.x * 0.52, 32.0, sz.x * 0.45, sz.y - 40.0), f, rows, acc)
		"coop":
			var n := 0
			var tot: int = maxi(1, (corp.get("list", []) as Array).size())
			for cc in corp.get("list", []):
				if bool(cc.get("coop", false)):
					n += 1
			es_draw_donut(c, Vector2(sz.x * 0.27, sz.y * 0.5), minf(sz.x * 0.2, sz.y * 0.38), float(n) / float(tot), "кооперативы", f, acc)
			es_draw_bars(c, Rect2(sz.x * 0.52, 20.0, sz.x * 0.45, sz.y - 30.0), f, [["Доля прибыли коллективам", float(es["share"]) * 50.0, 100.0], ["Поддержка рабочих", float(support["Рабочие"]), 100.0], ["Деловой климат", float(es["conf"]), 100.0], ["Равенство", float(lvl.get("equality", 50.0)), 100.0]], acc)
		_:
			es_draw_index(c, Rect2(10.0, 10.0, sz.x * 0.62, sz.y - 30.0), f, acc)
			es_draw_gauge(c, Vector2(sz.x * 0.82, sz.y * 0.55), minf(sz.x * 0.15, sz.y * 0.4), float(es["conf"]), "деловой климат", f)


func es_draw_index(c: Control, r: Rect2, f: Font, acc: Color) -> void:
	var h: Array = es.get("hist", [])
	c.draw_rect(r, Color(1, 1, 1, 0.03))
	c.draw_string(f, r.position + Vector2(6.0, 16.0), "Биржевой индекс (старт = 100): %.1f" % float(es["idx"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.9, 0.92, 0.96))
	if h.size() < 2:
		c.draw_string(f, r.position + Vector2(6.0, r.size.y * 0.5), "данные появятся через пару месяцев", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.62, 0.7))
		return
	var lo: float = 1e9
	var hi: float = -1e9
	for x in h:
		lo = minf(lo, float(x))
		hi = maxf(hi, float(x))
	if hi - lo < 2.0:
		hi += 1.0
		lo -= 1.0
	var pts := PackedVector2Array()
	for i in h.size():
		var x2: float = r.position.x + 6.0 + (r.size.x - 12.0) * float(i) / float(maxi(1, h.size() - 1))
		var y2: float = r.end.y - 8.0 - (r.size.y - 36.0) * (float(h[i]) - lo) / (hi - lo)
		pts.append(Vector2(x2, y2))
	var up: bool = float(h[h.size() - 1]) >= float(h[0])
	var lc: Color = Color(0.40, 0.85, 0.55) if up else Color(0.92, 0.40, 0.38)
	var poly := pts.duplicate()
	poly.append(Vector2(pts[pts.size() - 1].x, r.end.y - 6.0))
	poly.append(Vector2(pts[0].x, r.end.y - 6.0))
	c.draw_colored_polygon(poly, Color(lc.r, lc.g, lc.b, 0.12))
	c.draw_polyline(pts, lc, 2.0, true)
	c.draw_circle(pts[pts.size() - 1], 3.5, lc)


func es_draw_gauge(c: Control, cen: Vector2, R: float, v: float, lab: String, f: Font) -> void:
	for k in 30:
		var a0: float = PI + PI * float(k) / 30.0
		var a1: float = PI + PI * float(k + 1) / 30.0
		var t: float = float(k) / 29.0
		var cc: Color = Color(0.92, 0.34, 0.32).lerp(Color(0.93, 0.76, 0.32), clampf(t * 2.0, 0.0, 1.0)).lerp(Color(0.40, 0.80, 0.52), clampf(t * 2.0 - 1.0, 0.0, 1.0))
		if lab.begins_with("риск"):
			cc = Color(0.40, 0.80, 0.52).lerp(Color(0.93, 0.76, 0.32), clampf(t * 2.0, 0.0, 1.0)).lerp(Color(0.92, 0.34, 0.32), clampf(t * 2.0 - 1.0, 0.0, 1.0))
		c.draw_arc(cen, R, a0, a1, 4, cc, 9.0, true)
	var an: float = PI + PI * clampf(v / 100.0, 0.0, 1.0)
	c.draw_line(cen, cen + Vector2(cos(an), sin(an)) * (R - 4.0), Color(0.95, 0.95, 0.95), 3.0, true)
	c.draw_circle(cen, 5.0, Color(0.95, 0.95, 0.95))
	c.draw_string(f, Vector2(cen.x - 60.0, cen.y + 22.0), "%.0f" % v, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 18, Color(0.95, 0.95, 0.95))
	c.draw_string(f, Vector2(cen.x - 80.0, cen.y + 38.0), lab, HORIZONTAL_ALIGNMENT_CENTER, 160.0, 11, Color(0.75, 0.78, 0.86))


func es_draw_donut(c: Control, cen: Vector2, R: float, share: float, lab: String, f: Font, acc: Color) -> void:
	c.draw_arc(cen, R, 0.0, TAU, 64, Color(1, 1, 1, 0.08), R * 0.35, true)
	c.draw_arc(cen, R, -PI * 0.5, -PI * 0.5 + TAU * clampf(share, 0.0, 1.0), 64, acc, R * 0.35, true)
	c.draw_string(f, Vector2(cen.x - 60.0, cen.y + 6.0), "%.0f%%" % (share * 100.0), HORIZONTAL_ALIGNMENT_CENTER, 120.0, 20, Color(0.95, 0.95, 0.95))
	c.draw_string(f, Vector2(cen.x - 60.0, cen.y + 24.0), lab, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 11, Color(0.75, 0.78, 0.86))


func es_draw_bars(c: Control, r: Rect2, f: Font, rows: Array, acc: Color) -> void:
	var n: int = rows.size()
	var rh: float = minf(34.0, r.size.y / float(maxi(1, n)))
	for i in n:
		var y: float = r.position.y + float(i) * rh
		c.draw_string(f, Vector2(r.position.x, y + 13.0), String(rows[i][0]), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 40.0, 12, Color(0.85, 0.87, 0.92))
		c.draw_string(f, Vector2(r.end.x - 40.0, y + 13.0), "%.1f" % float(rows[i][1]), HORIZONTAL_ALIGNMENT_RIGHT, 40.0, 12, Color(0.85, 0.87, 0.92))
		c.draw_rect(Rect2(r.position.x, y + 17.0, r.size.x, 8.0), Color(1, 1, 1, 0.06))
		c.draw_rect(Rect2(r.position.x, y + 17.0, r.size.x * clampf(float(rows[i][1]) / float(rows[i][2]), 0.0, 1.0), 8.0), acc)


# Госплан: выполнение плана, отрасли, таймлайн пятилетки, дефицит
func es_draw_plan(c: Control, sz: Vector2, f: Font, acc: Color) -> void:
	var gold := Color(0.98, 0.80, 0.30)
	c.draw_rect(Rect2(0.0, 0.0, sz.x, 34.0), Color(acc.r, acc.g, acc.b, 0.35))
	Gfx.star(c, Vector2(18.0, 17.0), 10.0, gold, Color(0, 0, 0, 0.4))
	var yr: int = (turn - int(es["five_t"])) / 12 + 1
	c.draw_string(f, Vector2(36.0, 23.0), "ПЯТИЛЕТКА — ГОД %d-Й. ПЛАН ВЫПОЛНЕН НА %.0f%%" % [mini(5, yr), float(es["ful"])], HORIZONTAL_ALIGNMENT_LEFT, sz.x - 40.0, 15, gold)
	# таймлайн пяти лет
	var tx: float = 10.0
	var tw: float = sz.x - 20.0
	for k in 5:
		var r := Rect2(tx + tw * float(k) / 5.0 + 2.0, 44.0, tw / 5.0 - 4.0, 14.0)
		var done: float = clampf(float(turn - int(es["five_t"]) - k * 12) / 12.0, 0.0, 1.0)
		c.draw_rect(r, Color(1, 1, 1, 0.07))
		c.draw_rect(Rect2(r.position, Vector2(r.size.x * done, r.size.y)), Color(acc.r, acc.g, acc.b, 0.85))
		c.draw_string(f, r.position + Vector2(0.0, 11.0), "%d" % (k + 1), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 11, Color(0.95, 0.95, 0.95))
	# отрасли
	var y := 74.0
	for s in ES_PLAN_SECT:
		var lv: int = int(es["plan"][String(s[0])])
		var ful: float = float(es["ful"]) - float(lv - 1) * 6.0
		c.draw_string(f, Vector2(10.0, y + 12.0), "%s — %s" % [String(s[1]), ES_PLAN_LVL[lv]], HORIZONTAL_ALIGNMENT_LEFT, sz.x * 0.6, 12, Color(0.88, 0.88, 0.92))
		var bx: float = sz.x * 0.62
		var bw: float = sz.x * 0.30
		c.draw_rect(Rect2(bx, y + 3.0, bw, 10.0), Color(1, 1, 1, 0.06))
		c.draw_rect(Rect2(bx, y + 3.0, bw * clampf(ful / 130.0, 0.0, 1.0), 10.0), gold if ful >= 100.0 else acc)
		c.draw_line(Vector2(bx + bw * 100.0 / 130.0, y), Vector2(bx + bw * 100.0 / 130.0, y + 16.0), Color(1, 1, 1, 0.6), 1.0)
		c.draw_string(f, Vector2(bx + bw + 4.0, y + 12.0), "%.0f%%" % ful, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.9, 0.9, 0.9))
		y += 24.0
	# дефицит — очередь из человечков
	y += 8.0
	c.draw_string(f, Vector2(10.0, y + 12.0), "Дефицит товаров: %.0f из 100 — очереди:" % shortage, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.88, 0.88, 0.92))
	var nq: int = int(shortage / 5.0)
	for k2 in nq:
		var px: float = 10.0 + float(k2) * 13.0
		if px > sz.x - 14.0:
			break
		c.draw_circle(Vector2(px + 5.0, y + 24.0), 3.0, Color(0.85, 0.80, 0.75))
		c.draw_rect(Rect2(px + 2.0, y + 28.0, 6.0, 9.0), Color(0.55, 0.50, 0.48))
	# график выполнения
	var hh: Array = es.get("ful_hist", [])
	if hh.size() >= 2 and y + 50.0 < sz.y - 10.0:
		var r2 := Rect2(10.0, y + 44.0, sz.x - 20.0, sz.y - y - 54.0)
		c.draw_rect(r2, Color(1, 1, 1, 0.03))
		var pts := PackedVector2Array()
		for i in hh.size():
			pts.append(Vector2(r2.position.x + r2.size.x * float(i) / float(maxi(1, hh.size() - 1)), r2.end.y - r2.size.y * clampf((float(hh[i]) - 40.0) / 90.0, 0.0, 1.0)))
		var y100: float = r2.end.y - r2.size.y * 60.0 / 90.0
		c.draw_line(Vector2(r2.position.x, y100), Vector2(r2.end.x, y100), Color(gold.r, gold.g, gold.b, 0.4), 1.0)
		c.draw_polyline(pts, gold, 2.0, true)


# ---------- корпорации ----------
func update_corp_windows() -> void:
	if corp.is_empty() or co_listc == null:
		return
	var n: int = (corp["list"] as Array).size()
	co_listc.custom_minimum_size = Vector2(0.0, 62.0 + co_row_h * float(n))
	co_listc.queue_redraw()
	co_head.queue_redraw()
	co_bar.queue_redraw()
	var i: int = clampi(int(corp.get("sel", 0)), 0, maxi(0, n - 1))
	if n == 0:
		co_card_rt.text = "Нет данных о компаниях."
		return
	var c: Dictionary = corp["list"][i]
	var cls := ui_es_cls
	var t := "%s\n" % String(c["note"])
	t += "Отрасль: [b]%s[/b] · выручка [b]%.1f млрд €[/b] · работников [b]%d тыс.[/b]\n" % [String(c["lab"]), float(c["rev"]), int(c["emp"])]
	t += "Собственник: [b]%s[/b]%s%s%s\n" % [corp_owner_text(c), " · национальный чемпион" if bool(c["champ"]) else "", " · свои люди в правлении" if bool(c["board"]) else "", " · работники в совете" if bool(c["codet"]) else ""]
	var att: float = float(c["att"])
	t += "Отношение к власти: [b][color=%s]%.0f[/color][/b] из 100" % [COL_GOOD if att >= 55.0 else (COL_WARN if att >= 35.0 else COL_BAD), att]
	if cls == "planned":
		t += " · план предприятия: [b]%s[/b]" % ES_PLAN_LVL[int(c["pl"])]
	co_card_rt.text = t
	for id in co_btns:
		var b: Button = co_btns[id]
		var a := co_act_def(String(id))
		b.visible = cls in String(a[2]).split(",")
		var why := co_check(String(id), i)
		b.disabled = why != ""
		b.text = String(a[1]) + ("" if why == "" else " — " + why)
	var ft := "Иностранные компании дают около [b]%.0f%%[/b] оборота бизнеса (на старте — %.0f%%).\n" % [float(corp["fs"]) * 100.0, float(corp["fs0"]) * 100.0]
	if cls == "planned":
		ft += "[color=%s]В плановой экономике иностранцы уходят: остаются только совместные предприятия.[/color]\n" % COL_WARN
	for fc in corp["f"]:
		ft += "• %s — %s, ≈%.1f млрд €\n" % [String(fc["n"]), String(fc["lab"]).to_lower(), float(fc["rev"]) * float(corp["fs"]) / maxf(0.01, float(corp["fs0"]))]
	co_for_rt.text = "[font_size=13]%s[/font_size]" % ft
	for fid in co_for_btns:
		var why2 := co_foreign_check(String(fid))
		var b2: Button = co_for_btns[fid]
		b2.visible = not ((fid == "invite" and cls == "planned") or (fid == "jv" and cls != "planned"))
		b2.disabled = why2 != ""
		b2.tooltip_text = "" if why2 == "" else "Сейчас нельзя: " + why2


func co_initials(n: String) -> String:
	var parts := n.replace("«", "").replace("»", "").split(" ", false)
	if parts.size() >= 2:
		return (parts[0].substr(0, 1) + parts[1].substr(0, 1)).to_upper()
	return n.substr(0, 2).to_upper()


func co_list_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var k: int = int(((ev as InputEventMouseButton).position.y - 40.0) / co_row_h)
		if k >= 0 and k < (corp.get("list", []) as Array).size():
			corp["sel"] = k
			sfx("click")
			update_corp_windows()


func co_draw_list() -> void:
	var c := co_listc
	if corp.is_empty():
		return
	var sz: Vector2 = c.size
	var f: Font = c.get_theme_default_font()
	var acc := es_acc()
	var cls := ui_es_cls
	var title: String = {"planned": "НАРОДНОЕ ХОЗЯЙСТВО: ВЕДУЩИЕ ПРЕДПРИЯТИЯ", "coop": "ТРУДОВЫЕ КОЛЛЕКТИВЫ И ПРЕДПРИЯТИЯ", "statecap": "ГОСКОРПОРАЦИИ И КРУПНЫЙ БИЗНЕС",
		"market": "БИРЖА: ГОЛУБЫЕ ФИШКИ", "libertarian": "БИРЖА: ГОЛУБЫЕ ФИШКИ"}.get(cls, "КРУПНЕЙШИЕ КОМПАНИИ")
	Gfx.hgrad(c, Rect2(0.0, 0.0, sz.x, 30.0), Color(acc.r, acc.g, acc.b, 0.35), Color(acc.r, acc.g, acc.b, 0.0))
	c.draw_string(f, Vector2(8.0, 20.0), title, HORIZONTAL_ALIGNMENT_LEFT, sz.x - 16.0, 13, acc.lightened(0.35))
	var sel: int = int(corp.get("sel", 0))
	for i in (corp["list"] as Array).size():
		var co: Dictionary = corp["list"][i]
		var y: float = 40.0 + float(i) * co_row_h
		var r := Rect2(0.0, y, sz.x, co_row_h - 4.0)
		c.draw_rect(r, Color(acc.r, acc.g, acc.b, 0.22) if i == sel else Color(1, 1, 1, 0.035))
		if i == sel:
			c.draw_rect(Rect2(0.0, y, 3.0, co_row_h - 4.0), acc)
		var sc: Color = SECT_COL.get(String(co["mk"]), Color.GRAY)
		var p := Vector2(24.0, y + (co_row_h - 4.0) * 0.5)
		if cls == "planned":
			Gfx.star(c, p, 13.0, Color(0.90, 0.24, 0.20), Color(0.98, 0.80, 0.30))
		else:
			c.draw_circle(p, 15.0, sc.darkened(0.35))
			c.draw_arc(p, 15.0, 0.0, TAU, 24, sc, 1.5, true)
			c.draw_string(f, p + Vector2(-15.0, 5.0), co_initials(String(co["n"])), HORIZONTAL_ALIGNMENT_CENTER, 30.0, 12, Color(0.97, 0.97, 0.97))
		c.draw_string(f, Vector2(46.0, y + 17.0), corp_name(co), HORIZONTAL_ALIGNMENT_LEFT, sz.x - 150.0, 14, Color(0.93, 0.94, 0.97))
		c.draw_string(f, Vector2(46.0, y + 34.0), "%s · %.1f млрд €" % [String(co["lab"]), float(co["rev"])], HORIZONTAL_ALIGNMENT_LEFT, sz.x - 150.0, 11, Color(0.68, 0.71, 0.80))
		# полоса собственности: государство / частные / коллектив
		var bx: float = sz.x - 98.0
		var st: float = float(co["st"]) / 100.0
		c.draw_rect(Rect2(bx, y + 9.0, 90.0, 9.0), Color(0.40, 0.62, 0.92) if not bool(co.get("coop", false)) else Color(0.96, 0.52, 0.28))
		c.draw_rect(Rect2(bx, y + 9.0, 90.0 * st, 9.0), Color(0.88, 0.30, 0.26))
		var lab: String = "коллектив" if bool(co.get("coop", false)) else ("гос. %d%%" % int(co["st"]) if int(co["st"]) > 0 else "частная")
		c.draw_string(f, Vector2(bx, y + 33.0), lab, HORIZONTAL_ALIGNMENT_LEFT, 70.0, 11, Color(0.75, 0.78, 0.86))
		var ac := reg_loy_col(float(co["att"]))
		c.draw_circle(Vector2(sz.x - 12.0, y + 29.0), 4.0, ac)
	c.draw_string(f, Vector2(8.0, sz.y - 4.0), "красное — доля государства, синее — частные акционеры; точка — отношение к власти", HORIZONTAL_ALIGNMENT_LEFT, sz.x - 16.0, 10, Color(0.6, 0.63, 0.72))


func co_draw_head() -> void:
	var c := co_head
	if corp.is_empty() or (corp["list"] as Array).is_empty():
		return
	var sz: Vector2 = c.size
	var f: Font = c.get_theme_default_font()
	var co: Dictionary = corp["list"][clampi(int(corp.get("sel", 0)), 0, (corp["list"] as Array).size() - 1)]
	var acc := es_acc()
	var sc: Color = SECT_COL.get(String(co["mk"]), Color.GRAY)
	Gfx.hgrad(c, Rect2(Vector2.ZERO, sz), Color(sc.r, sc.g, sc.b, 0.25), Color(acc.r, acc.g, acc.b, 0.05))
	var p := Vector2(42.0, sz.y * 0.5)
	c.draw_circle(p, 32.0, sc.darkened(0.3))
	c.draw_arc(p, 32.0, 0.0, TAU, 40, sc.lightened(0.2), 2.5, true)
	c.draw_string(f, p + Vector2(-32.0, 8.0), co_initials(String(co["n"])), HORIZONTAL_ALIGNMENT_CENTER, 64.0, 22, Color(0.98, 0.98, 0.98))
	c.draw_string(f, Vector2(86.0, 32.0), corp_name(co), HORIZONTAL_ALIGNMENT_LEFT, sz.x - 90.0, 19, Color(0.96, 0.96, 0.98))
	c.draw_string(f, Vector2(86.0, 54.0), "%s · %s" % [String(co["lab"]), corp_owner_text(co)], HORIZONTAL_ALIGNMENT_LEFT, sz.x - 90.0, 12, Color(0.75, 0.78, 0.86))
	# отношение к власти — шкала
	var bx := 86.0
	var bw: float = minf(220.0, sz.x - 100.0)
	c.draw_rect(Rect2(bx, 64.0, bw, 7.0), Color(1, 1, 1, 0.07))
	c.draw_rect(Rect2(bx, 64.0, bw * float(co["att"]) / 100.0, 7.0), reg_loy_col(float(co["att"])))


# иностранный капитал: полоса по странам происхождения с флагами
func co_draw_bar() -> void:
	var c := co_bar
	if corp.is_empty():
		return
	var sz: Vector2 = c.size
	var f: Font = c.get_theme_default_font()
	var by := {}
	var tot := 0.0
	for fc in corp["f"]:
		by[String(fc["o"])] = float(by.get(String(fc["o"]), 0.0)) + float(fc["rev"])
		tot += float(fc["rev"])
	var x := 0.0
	var w: float = sz.x * clampf(float(corp["fs"]) / 0.7, 0.05, 1.0)
	c.draw_rect(Rect2(0.0, 6.0, sz.x, 18.0), Color(1, 1, 1, 0.05))
	var k := 0
	var cols := [Color(0.45, 0.65, 0.95), Color(0.95, 0.65, 0.35), Color(0.55, 0.85, 0.55), Color(0.85, 0.50, 0.85), Color(0.95, 0.85, 0.40), Color(0.60, 0.80, 0.85)]
	for o in by:
		var ww: float = w * float(by[o]) / maxf(0.01, tot)
		c.draw_rect(Rect2(x, 6.0, ww - 1.0, 18.0), cols[k % cols.size()])
		var fx: float = 4.0 + float(k) * 40.0
		c.draw_rect(Rect2(fx, 32.0, 6.0, 16.0), cols[k % cols.size()])
		Flags.draw(c, String(o), Rect2(fx + 9.0, 32.0, 24.0, 16.0))
		x += ww
		k += 1
	c.draw_string(f, Vector2(minf(x + 6.0, sz.x - 120.0), 20.0), "%.0f%% экономики" % (float(corp["fs"]) * 100.0), HORIZONTAL_ALIGNMENT_LEFT, 120.0, 12, Color(0.9, 0.9, 0.95))
