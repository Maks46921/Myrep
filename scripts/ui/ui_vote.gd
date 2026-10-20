# v51_1: окно итогового голосования. Зал заседаний загорается место за местом: плитка в цвет партии, кружок в ней
# показывает голос (зелёный «за», красный «против», серый «воздержался»); табло считает голоса, черта показывает,
# сколько нужно; в конце — «ПРИНЯТ» или «ОТКЛОНЁН» и таблица по фракциям: кто нарушил дисциплину.
# 0.57.1: окно одно на весь день голосования. Сначала выбор стратегии (по своему законопроекту — как есть /
# договориться с отдельными партиями / надавить на партнёров; по чужому — как голосует ваша фракция), потом
# сразу зал и итог. Окно открывается и по законам других партий, и когда вы в оппозиции.
extends "res://scripts/ui/ui_treaty.gd"

var vt_ov: Control = null
var vt_hall: Control = null
var vt_title: Label = null
var vt_sub: Label = null
var vt_board: RichTextLabel = null
var vt_table: RichTextLabel = null
var vt_btn: Button = null
var vt_legend: RichTextLabel = null
var vt_next: RichTextLabel = null
var vt_next_btn: Button = null
var vt_res_box: VBoxContainer = null
var vt_plan_box: VBoxContainer = null
var vt_fc_lbl: RichTextLabel = null
var vt_fc_bar: StatBar = null
var vt_mode_row: HBoxContainer = null
var vt_plan_list: VBoxContainer = null
var vt_plan_note: RichTextLabel = null
var vt_later_btn: Button = null
var vt_seats: Array = []       # [Vector2 позиция, партия, голос 0 за/1 против/2 воздержался, порядок, отступник]
var vt_tile := 8.0             # сторона плитки места
var vt_t := 0.0                # 0..1 — ход анимации
var vt_tw: Tween = null
var vt_data := {}
var vt_stage := 0              # 0 окна нет, 1 выбор стратегии, 2 итог, 3 голосование идёт
var vt_plan_bid := -1
var vt_from_plan := false
var vt_mode := 0
var vt_deals: Array = []
var vt_press: Array = []
var vt_pv := "line"

const VT_ANIM := 2.0


# живая игра: спрашиваем игрока перед голосованием. В тестах и симуляциях — по-старому, без окна.
func vote_plan_live() -> bool:
	if observer or bool(ap["events"]):
		return false
	if DisplayServer.get_name() == "headless" or OS.get_cmdline_args().has("--script") or OS.get_cmdline_args().has("-s"):
		return bool(game_opts.get("voteplan", false))
	return true


func vt_plan_busy() -> bool:
	return vt_stage == 1 and vt_ov != null and vt_ov.visible


func vote_show() -> void:
	if last_vote.is_empty() or bool(last_vote.get("bypass", false)) or observer:
		return
	if DisplayServer.get_name() == "headless" or OS.get_cmdline_args().has("--script") or OS.get_cmdline_args().has("-s"):
		if not OS.get_cmdline_user_args().has("vote=1") and not bool(game_opts.get("voteplan", false)):
			return
	vt_data = last_vote.duplicate(true)
	if vt_ov == null:
		vote_build()
	vt_stage = 2
	vt_plan_box.visible = false
	vt_res_box.visible = true
	vt_next.visible = false
	vt_next_btn.visible = false
	vote_layout_seats()
	var tid: String = String(vt_data["tid"])
	var tp: Dictionary = law_index.get(tid, {})
	vt_title.text = "Голосование: «%s»" % String(tp.get("name", "закон"))
	var sp: int = int(vt_data.get("sponsor", 0))
	vt_sub.text = "Вариант: %s · вносит: %s · нужно %d голосов из %d" % [String(variant_of(tid, int(vt_data["idx"]))["n"]), "ваша партия" if sp == 0 else String(PARTY_NAMES[sp]), int(vt_data["need"]), SEATS]
	vt_table.text = ""
	vt_btn.text = "Пропустить ▶▶"
	vt_ov.visible = true
	win_fade_in(vt_ov, 0.2)
	vt_t = 0.0
	if vt_tw != null:
		vt_tw.kill()
	vt_tw = create_tween()
	vt_tw.tween_method(vote_step, 0.0, 1.0, VT_ANIM)
	vt_tw.tween_callback(vote_done)
	set_speed(0)


func vote_build() -> void:
	vt_ov = Control.new()
	vt_ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vt_ov.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(vt_ov)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vt_ov.add_child(dim)
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", sbox(C_PANEL, C_ACCENT.darkened(0.15), 2, 14, 16.0, 12.0))
	pan.anchor_left = 0.5
	pan.anchor_right = 0.5
	pan.anchor_top = 0.5
	pan.anchor_bottom = 0.5
	var vp := get_viewport_rect().size
	var hw: float = minf(450.0, vp.x * 0.5 - 12.0)
	var hh: float = minf(440.0, vp.y * 0.5 - 8.0)
	pan.offset_left = -hw
	pan.offset_right = hw
	pan.offset_top = -hh
	pan.offset_bottom = hh
	vt_ov.add_child(pan)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	pan.add_child(vb)
	vt_title = Label.new()
	vt_title.add_theme_font_size_override("font_size", 21)
	vt_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vt_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(vt_title)
	vt_sub = Label.new()
	vt_sub.add_theme_font_size_override("font_size", 13)
	vt_sub.add_theme_color_override("font_color", C_DIM)
	vt_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vt_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(vt_sub)
	# ---- этап 1: выбор стратегии ----
	vt_plan_box = VBoxContainer.new()
	vt_plan_box.add_theme_constant_override("separation", 6)
	vt_plan_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(vt_plan_box)
	vt_fc_lbl = RichTextLabel.new()
	vt_fc_lbl.bbcode_enabled = true
	vt_fc_lbl.fit_content = true
	vt_fc_lbl.scroll_active = false
	vt_plan_box.add_child(vt_fc_lbl)
	vt_fc_bar = StatBar.new()
	vt_fc_bar.custom_minimum_size = Vector2(0.0, 16.0)
	vt_fc_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vt_plan_box.add_child(vt_fc_bar)
	vt_mode_row = HBoxContainer.new()
	vt_mode_row.add_theme_constant_override("separation", 6)
	vt_plan_box.add_child(vt_mode_row)
	var psc := ScrollContainer.new()
	psc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	psc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vt_plan_box.add_child(psc)
	vt_plan_list = VBoxContainer.new()
	vt_plan_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vt_plan_list.add_theme_constant_override("separation", 4)
	psc.add_child(vt_plan_list)
	vt_plan_note = RichTextLabel.new()
	vt_plan_note.bbcode_enabled = true
	vt_plan_note.fit_content = true
	vt_plan_note.scroll_active = false
	vt_plan_box.add_child(vt_plan_note)
	vt_later_btn = Button.new()
	vt_later_btn.focus_mode = Control.FOCUS_NONE
	vt_later_btn.text = "Отложить голосование на месяц"
	vt_later_btn.pressed.connect(vote_plan_later)
	vt_plan_box.add_child(vt_later_btn)
	# ---- этап 2: зал и итог ----
	vt_res_box = VBoxContainer.new()
	vt_res_box.add_theme_constant_override("separation", 6)
	vt_res_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(vt_res_box)
	vt_hall = Control.new()
	vt_hall.custom_minimum_size = Vector2(0.0, 290.0)
	vt_hall.draw.connect(vote_draw)
	vt_hall.resized.connect(vote_layout_seats)
	vt_res_box.add_child(vt_hall)
	vt_legend = RichTextLabel.new()
	vt_legend.bbcode_enabled = true
	vt_legend.fit_content = true
	vt_legend.scroll_active = false
	vt_res_box.add_child(vt_legend)
	vt_board = RichTextLabel.new()
	vt_board.bbcode_enabled = true
	vt_board.fit_content = true
	vt_board.scroll_active = false
	vt_res_box.add_child(vt_board)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vt_res_box.add_child(sc)
	var sbx := VBoxContainer.new()
	sbx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(sbx)
	vt_table = RichTextLabel.new()
	vt_table.bbcode_enabled = true
	vt_table.fit_content = true
	vt_table.scroll_active = false
	vt_table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sbx.add_child(vt_table)
	vt_next = RichTextLabel.new()
	vt_next.bbcode_enabled = true
	vt_next.fit_content = true
	vt_next.scroll_active = false
	vt_next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vt_next.visible = false
	sbx.add_child(vt_next)
	vt_next_btn = Button.new()
	vt_next_btn.focus_mode = Control.FOCUS_NONE
	vt_next_btn.text = "Что будет дальше"
	vt_next_btn.visible = false
	vt_next_btn.pressed.connect(func() -> void:
		vt_next.text = "[font_size=14]%s[/font_size]" % String(vt_data.get("next", ""))
		vt_next.visible = not vt_next.visible)
	vt_res_box.add_child(vt_next_btn)
	vt_btn = Button.new()
	vt_btn.focus_mode = Control.FOCUS_NONE
	vt_btn.custom_minimum_size = Vector2(0.0, 36.0)
	vt_btn.pressed.connect(vote_btn_pressed)
	vb.add_child(vt_btn)


func vote_btn_pressed() -> void:
	if vt_stage == 1:
		vote_plan_go()
		return
	if vt_t < 1.0:
		if vt_tw != null:
			vt_tw.kill()
		vote_step(1.0)
		vote_done()
		return
	vt_ov.visible = false
	vt_stage = 0
	var again := vt_from_plan
	vt_from_plan = false
	vt_plan_bid = -1
	refresh()
	if again:
		bills_due_step()


# ============================================================
#  ЭТАП 1: ВЫБОР СТРАТЕГИИ
# ============================================================
func vote_plan_open(bid: int) -> void:
	var bi := bill_index(bid)
	if bi < 0:
		return
	var b: Dictionary = bills[bi]
	if vt_ov == null:
		vote_build()
	vt_plan_bid = bid
	vt_stage = 1
	vt_from_plan = true
	vt_mode = 0
	vt_deals = []
	vt_press = []
	vt_pv = String(b.get("pv", "line"))
	if vt_pv == "":
		vt_pv = "line"
	if vt_tw != null:
		vt_tw.kill()
	vt_plan_box.visible = true
	vt_res_box.visible = false
	vt_next.visible = false
	var tid: String = String(b["tid"])
	var sp: int = int(b["sponsor"])
	vt_title.text = "День голосования: «%s»" % String(law_index[tid]["name"])
	vt_sub.text = "Вариант: %s · вносит: %s · нужно %d голосов из %d" % [String(variant_of(tid, int(b["idx"]))["n"]), "ваша партия" if sp == 0 else String(PARTY_NAMES[sp]), law_need(tid, bill_preview(b)), SEATS]
	vt_later_btn.visible = sp == 0 and int((b["did"] as Dictionary).get("slow", 0)) < 2
	vt_ov.visible = true
	win_fade_in(vt_ov, 0.2)
	set_speed(0)
	vote_plan_refresh()


func vt_party_tag(p: int) -> String:
	return "[color=#%s]■[/color] %s" % [(PARTY_COLORS[p] as Color).lightened(0.2).to_html(false), party_abbr(p)]


func vt_toggle_btn(text: String, on: bool, cb: Callable, tip: String = "") -> Button:
	var bt := Button.new()
	bt.toggle_mode = true
	bt.focus_mode = Control.FOCUS_NONE
	bt.text = text
	bt.button_pressed = on
	bt.tooltip_text = tip
	bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bt.alignment = HORIZONTAL_ALIGNMENT_LEFT
	bt.pressed.connect(cb)
	return bt


func vt_label(text: String, col: Color = Color(0, 0, 0, 0)) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 13)
	if col.a > 0.0:
		l.add_theme_color_override("font_color", col)
	return l


func vote_plan_refresh() -> void:
	var bi := bill_index(vt_plan_bid)
	if bi < 0:
		return
	var b: Dictionary = bills[bi]
	var tid: String = String(b["tid"])
	var own: bool = int(b["sponsor"]) == 0
	# прогноз
	var extra: Array = []
	var pvm := ""
	if own:
		extra = vt_deals + vt_press
	else:
		pvm = "yes" if vt_pv == "trade" else vt_pv
	var v := bill_plan_preview(b, extra, pvm)
	var yes: int = int(v["yes"])
	var need: int = law_need(tid, v)
	var ok: bool = yes >= need
	vt_fc_lbl.text = "[center][font_size=18][color=%s]за %d[/color]   [color=%s]против %d[/color]   [color=%s]воздержатся %d[/color][/font_size]\n[font_size=13][color=%s]прогноз: нужно %d — [b]%s[/b][/color][/font_size][/center]" % [
		COL_GOOD, yes, COL_BAD, int(v.get("no", 0)), COL_DIM, int(v.get("abst", 0)), COL_GOOD if ok else COL_BAD, need, "пройдёт" if ok else "не пройдёт"]
	vt_fc_bar.marker = float(need) * 100.0 / float(SEATS)
	vt_fc_bar.set_state(float(yes) * 100.0 / float(SEATS), 0.85 if ok else 0.08)
	for c in vt_mode_row.get_children():
		c.queue_free()
	for c in vt_plan_list.get_children():
		c.queue_free()
	var hint := ""
	if own:
		var names := ["Голосовать как есть", "Договориться с партиями", "Надавить на партнёров"]
		for i in names.size():
			var mi := i
			vt_mode_row.add_child(vt_toggle_btn(names[i], vt_mode == i, func() -> void:
				vt_mode = mi
				vote_plan_refresh()))
		hint = vote_plan_own(b, v)
	else:
		hint = vote_plan_other(b, v)
	vt_plan_note.text = "[font_size=13]%s[/font_size]" % hint
	if own and not ok:
		vt_btn.text = "Всё равно голосовать (закон не пройдёт, взнос пропадёт)"
	else:
		vt_btn.text = "Голосовать"


func vote_plan_own(b: Dictionary, v: Dictionary) -> String:
	var swing := bill_swing_parties(b)
	var t := ""
	if vt_mode == 0:
		vt_plan_list.add_child(vt_label("Голосуем с тем расчётом, который показан выше. Депутаты могут нарушить дисциплину, итог может немного отличаться от прогноза."))
		var against: PackedStringArray = []
		for it in v["per"]:
			var p: int = int(it[0])
			if p == 0 or (it as Array).size() < 6:
				continue
			var tot: int = int(it[3]) + int(it[4]) + int(it[5])
			if int(it[3]) * 2 < tot:
				against.append("%s (%d)" % [party_abbr(p), tot])
		if against.size() > 0:
			vt_plan_list.add_child(vt_label("Против или воздержатся: %s" % ", ".join(against), C_DIM))
	elif vt_mode == 1:
		if swing.is_empty():
			vt_plan_list.add_child(vt_label("Все партии, которых можно уговорить, уже за закон."))
		for p in swing:
			var pp := int(p)
			var cost: float = bill_deal_cost(b, pp)
			var cb1 := func() -> void:
				if pp in vt_deals:
					vt_deals.erase(pp)
				else:
					vt_deals.append(pp)
					vt_press.erase(pp)
				vote_plan_refresh()
			vt_plan_list.add_child(vt_toggle_btn("%s · %d мест · голоса за %.0f капитала" % [party_abbr(pp), seats[pp], cost], pp in vt_deals, cb1, "Отношения с партией улучшатся, она проголосует «за» по линии."))
	else:
		var any := false
		for p in swing:
			var pp := int(p)
			if not bill_press_ok(pp):
				continue
			any = true
			var cb2 := func() -> void:
				if pp in vt_press:
					vt_press.erase(pp)
				else:
					vt_press.append(pp)
					vt_deals.erase(pp)
				vote_plan_refresh()
			vt_plan_list.add_child(vt_toggle_btn("%s · %d мест · довольство партии −%.0f, отношения −5" % [party_abbr(pp), seats[pp], bill_press_cost(b, pp)], pp in vt_press, cb2, "Партнёр проголосует «за», но станет менее доволен коалицией."))
		if not any:
			vt_plan_list.add_child(vt_label("Среди партнёров по коалиции нет тех, кто против этого закона."))
	var total := 0.0
	for p in vt_deals:
		total += bill_deal_cost(b, int(p))
	var warn := ""
	if total > capital:
		warn = "   [color=%s]политкапитал уйдёт в минус[/color]" % COL_BAD
	if total > 0.0 or vt_press.size() > 0:
		t = "Выбрано: политкапитал −%.0f (сейчас %.0f), давление на партнёров: %d%s" % [total, capital, vt_press.size(), warn]
	else:
		t = "Ничего не куплено и ни на кого не давили."
	return t


func vote_plan_other(b: Dictionary, _v: Dictionary) -> String:
	var sp: int = int(b["sponsor"])
	var line := pa_line(b)
	var opts := [
		["yes", "За", "Фракция голосует за."],
		["no", "Против", "Фракция голосует против."],
		["abst", "Воздержаться", "Голоса фракции не идут ни за, ни против."],
		["line", "Как велит линия партии (сейчас: %s)" % ("за" if line else "против"), "Дисциплина не страдает."],
		["free", "Свободное голосование", "Каждый депутат решает сам; дисциплина слегка слабеет."],
		["trade", "Обменять свои голоса (политкапитал +%.0f)" % pa_trade_value(b), "Фракция голосует «за», а вам должны: отношения с партией лучше."]]
	for o in opts:
		var key: String = o[0]
		if key == "trade" and bool(b.get("traded", false)):
			continue
		var cb3 := func() -> void:
			vt_pv = key
			vote_plan_refresh()
		vt_plan_list.add_child(vt_toggle_btn(String(o[1]), vt_pv == key, cb3, String(o[2])))
	# поправка
	var amv := VBoxContainer.new()
	amv.add_theme_constant_override("separation", 4)
	amv.add_child(vt_label("Внести поправку (сила закона сейчас %.1f×):" % float(b["pow"]), C_DIM))
	var am := HBoxContainer.new()
	am.add_theme_constant_override("separation", 6)
	amv.add_child(am)
	for kind in ["soft", "hard"]:
		var kk: String = kind
		var bt := Button.new()
		bt.focus_mode = Control.FOCUS_NONE
		bt.text = ("Смягчить" if kk == "soft" else "Усилить") + " (капитал −3)"
		var why := bill_pow_block(b, kk)
		bt.disabled = why != "" or cap_spendable() < 3.0
		bt.tooltip_text = why if why != "" else "Партия, внёсшая закон, обидится, зато голосов может стать больше или меньше."
		bt.pressed.connect(func() -> void:
			if pa_amend(vt_plan_bid, kk):
				vote_plan_refresh())
		am.add_child(bt)
	vt_plan_list.add_child(amv)
	var eff: String = vt_pv
	if eff == "trade":
		eff = "yes"
	elif eff == "line":
		eff = "yes" if line else "no"
	var t := ""
	if (eff == "yes" and not line) or (eff == "no" and line):
		t = "[color=%s]Это против линии вашей партии: дисциплина ослабнет, часть избирателей будет недовольна.[/color]" % COL_WARN
	elif vt_pv == "free":
		t = "Свободное голосование чуть ослабляет дисциплину фракции."
	elif eff == "no" and sp < in_coalition.size() and in_coalition[sp] and not opp_mode:
		t = "[color=%s]Партнёр по коалиции обидится: довольство его −6.[/color]" % COL_WARN
	elif eff == "yes":
		t = "Поддержка укрепляет отношения с внёсшей партией."
	return t


func vote_plan_later() -> void:
	if vt_plan_bid < 0:
		return
	if bill_amend(vt_plan_bid, "slow"):
		vt_ov.visible = false
		vt_stage = 0
		vt_from_plan = false
		vt_plan_bid = -1
		refresh()


func vote_plan_go() -> void:
	var bi := bill_index(vt_plan_bid)
	if bi < 0:
		vt_ov.visible = false
		vt_stage = 0
		return
	var b: Dictionary = bills[bi]
	var own: bool = int(b["sponsor"]) == 0
	if own:
		if not bill_plan_apply(vt_plan_bid, vt_deals, vt_press):
			vt_plan_note.text = "[font_size=13][color=%s]Не хватает политкапитала на выбранные сделки.[/color][/font_size]" % COL_BAD
			return
	else:
		if vt_pv == "trade":
			if not pa_trade(vt_plan_bid):
				b["pv"] = "yes"
		else:
			b["pv"] = vt_pv
	b["go"] = true
	vt_stage = 3                    # ждём, покажет ли игра итог
	bill_run_vote(b)
	if vt_stage == 3:               # итог не показан (например, закон нельзя изменить) — закрываем окно
		vt_ov.visible = false
		vt_stage = 0
		vt_from_plan = false
		vt_plan_bid = -1
		refresh()
		bills_due_step()


# ============================================================
#  ЭТАП 2: ЗАЛ
# ============================================================
# места полукругом: ряды от внутреннего к внешнему, фракции — секторами слева направо
func vote_layout_seats() -> void:
	vt_seats.clear()
	if vt_hall == null or vt_data.is_empty():
		return
	var w: float = maxf(200.0, vt_hall.size.x)
	var h: float = maxf(120.0, vt_hall.size.y)
	var n: int = SEATS
	var r0: float = h * 0.30
	var r1: float = minf(h * 0.95, w * 0.48)
	# число рядов подбираем так, чтобы расстояние между рядами равнялось расстоянию между местами в ряду
	var avg_r: float = (r0 + r1) * 0.5
	var rows: int = clampi(int(round(0.5 + sqrt(0.25 + (r1 - r0) * float(n) / (PI * avg_r)))), 4, 24)
	var caps: Array = []
	var tot_len := 0.0
	for r in rows:
		var rr: float = lerpf(r0, r1, float(r) / float(maxi(1, rows - 1)))
		caps.append(rr)
		tot_len += rr
	var pts: Array = []
	var left := n
	var arc_min := 1e9
	for r in rows:
		var k: int = int(round(float(n) * float(caps[r]) / tot_len)) if r < rows - 1 else left
		k = clampi(k, 1, left)
		left -= k
		arc_min = minf(arc_min, PI * float(caps[r]) / float(k))
		for i in k:
			var a: float = PI - PI * (float(i) + 0.5) / float(k)
			pts.append([a, Vector2(w * 0.5 + cos(a) * float(caps[r]), h - 8.0 - sin(a) * float(caps[r]))])
		if left <= 0:
			break
	# плитка занимает место целиком, но соседние не заходят друг на друга
	var row_gap: float = (r1 - r0) / float(maxi(1, rows - 1))
	vt_tile = clampf(minf(row_gap, arc_min) * 0.94, 4.0, 22.0)
	pts.sort_custom(func(x, y): return float(x[0]) > float(y[0]))
	# порядок фракций по полукругу; отступник — тот, кто голосует не по линии партии
	var seq: Array = []
	var per := {}
	for it in vt_data["per"]:
		per[int(it[0])] = it
	var order: Array = []
	for p in HEMI_ORDER:
		if per.has(int(p)):
			order.append(int(p))
	for p in per:
		if not (int(p) in order):
			order.append(int(p))
	for p in order:
		var it: Array = per[p]
		if it.size() < 6:
			continue
		var line_yes: bool = bool(it[2])
		for j in int(it[3]):
			seq.append([p, 0, not line_yes])
		for j in int(it[4]):
			seq.append([p, 1, line_yes])
		for j in int(it[5]):
			seq.append([p, 2, int(it[3]) + int(it[4]) > 0])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(vt_data["tid"]) + str(vt_data["turn"]))
	for i in mini(pts.size(), seq.size()):
		vt_seats.append([pts[i][1], seq[i][0], seq[i][1], rng.randf(), seq[i][2]])
	vt_legend.text = vote_legend_text(order, per)
	vt_hall.queue_redraw()


# легенда под залом: партии и число мест; отступники подсвечены белой рамкой
func vote_legend_text(order: Array, per: Dictionary) -> String:
	var parts: PackedStringArray = []
	for p in order:
		var it: Array = per[p]
		if it.size() < 6:
			continue
		parts.append("%s %d" % [vt_party_tag(p), int(it[3]) + int(it[4]) + int(it[5])])
	return "[center][font_size=12]%s\n[color=%s]круг в плитке — голос: зелёный «за», красный «против», серый «воздержался»; белая рамка — нарушил дисциплину[/color][/font_size][/center]" % ["    ".join(parts), COL_DIM]


func vote_step(t: float) -> void:
	vt_t = t
	var y := 0
	var n := 0
	var a := 0
	for st in vt_seats:
		if float(st[3]) <= t:
			match int(st[2]):
				0: y += 1
				1: n += 1
				_: a += 1
	var need: int = int(vt_data.get("need", 0))
	vt_board.text = "[center][font_size=22][color=%s]ЗА %d[/color]   [color=%s]ПРОТИВ %d[/color]   [color=%s]ВОЗДЕРЖАЛИСЬ %d[/color][/font_size]\n[font_size=13][color=%s]нужно %d[/color][/font_size][/center]" % [COL_GOOD, y, COL_BAD, n, COL_DIM, a, COL_DIM, need]
	vt_hall.queue_redraw()


func vote_draw() -> void:
	var c := vt_hall
	if vt_seats.is_empty():
		return
	var side: float = vt_tile
	for st in vt_seats:
		var p: int = int(st[1])
		var pc: Color = PARTY_COLORS[p] if p < PARTY_COLORS.size() else Color.GRAY
		var lit: bool = float(st[3]) <= vt_t
		var pos: Vector2 = st[0]
		var rect := Rect2(pos - Vector2(side, side) * 0.5, Vector2(side, side))
		if not lit:
			c.draw_rect(rect, Color(pc.r, pc.g, pc.b, 0.22))
			continue
		c.draw_rect(rect, Color(pc.r, pc.g, pc.b, 0.85))
		var vc: Color = [Color(0.35, 0.80, 0.50), Color(0.93, 0.40, 0.40), Color(0.55, 0.58, 0.66)][int(st[2])]
		c.draw_circle(pos, side * 0.36, vc)
		c.draw_arc(pos, side * 0.36, 0.0, TAU, 10, Color(0, 0, 0, 0.45), 1.0, true)
		if bool(st[4]):
			c.draw_rect(rect.grow(0.6), Color(1, 1, 1, 0.95), false, 1.3)
	# черта большинства — шкала внизу: сколько «за» набрано и где порог
	var need: int = int(vt_data.get("need", 0))
	var y := 0
	for st in vt_seats:
		if float(st[3]) <= vt_t and int(st[2]) == 0:
			y += 1
	var w: float = c.size.x
	var bw: float = w * 0.6
	var x0: float = (w - bw) * 0.5
	var yb: float = c.size.y - 4.0
	c.draw_rect(Rect2(x0, yb - 6.0, bw, 6.0), Color(1, 1, 1, 0.08))
	c.draw_rect(Rect2(x0, yb - 6.0, bw * clampf(float(y) / float(maxi(1, SEATS)), 0.0, 1.0), 6.0), Color(0.35, 0.80, 0.50))
	var xn: float = x0 + bw * float(need) / float(maxi(1, SEATS))
	c.draw_line(Vector2(xn, yb - 10.0), Vector2(xn, yb + 2.0), Color(1.0, 0.85, 0.4), 2.0)


func vt_stance_text(s: float) -> String:
	var k: int = clampi(int(round(s)), -3, 3)
	var col: String = COL_GOOD if k > 0 else (COL_BAD if k < 0 else COL_DIM)
	return "[color=%s]%s[/color]" % [col, ("+%d" % k) if k > 0 else str(k)]


func vote_done() -> void:
	vt_t = 1.0
	vote_step(1.0)
	var ok: bool = bool(vt_data.get("passed", false))
	sfx("good" if ok else "bad")
	var notes: Dictionary = vt_data.get("notes", {})
	var t := "[center][font_size=26][b][color=%s]%s[/color][/b][/font_size][/center]\n" % [COL_GOOD if ok else COL_BAD, "ЗАКОН ПРИНЯТ" if ok else "ЗАКОН ОТКЛОНЁН"]
	t += "[table=7][cell][b]Фракция[/b]   [/cell][cell][b]позиция[/b]  [/cell][cell][b]за[/b]  [/cell][cell][b]против[/b]  [/cell][cell][b]возд.[/b]  [/cell][cell][b]дисциплина[/b]  [/cell][cell][b]что получила или потеряла[/b][/cell]"
	for it in vt_data["per"]:
		if (it as Array).size() < 6:
			continue
		var p: int = int(it[0])
		var s: float = float(it[1])
		var tot: int = int(it[3]) + int(it[4]) + int(it[5])
		var line_cnt: int = int(it[3]) if bool(it[2]) else int(it[4])
		var reb: int = tot - line_cnt
		var disc: String = ("[color=%s]единогласно[/color]" % COL_DIM) if reb == 0 else ("[color=%s]%d нарушили[/color]" % [COL_WARN, reb])
		var gain := ""
		if notes.has(p):
			gain = String(notes[p])
		elif ok and s >= 1.5:
			gain = "[color=%s]добилась желаемого[/color]" % COL_GOOD
		elif ok and s <= -1.5:
			gain = "[color=%s]закон прошёл вопреки ей[/color]" % COL_BAD
		elif not ok and s >= 1.5:
			gain = "[color=%s]проиграла[/color]" % COL_BAD
		elif not ok and s <= -1.5:
			gain = "[color=%s]отстояла своё[/color]" % COL_GOOD
		else:
			gain = "[color=%s]без существенных последствий[/color]" % COL_DIM
		t += "[cell]%s   [/cell][cell]%s  [/cell][cell]%d  [/cell][cell]%d  [/cell][cell]%d  [/cell][cell]%s  [/cell][cell]%s[/cell]" % [vt_party_tag(p), vt_stance_text(s), int(it[3]), int(it[4]), int(it[5]), disc, gain]
	t += "[/table]"
	vt_table.text = t
	vt_btn.text = "Продолжить"
	vt_next_btn.visible = String(vt_data.get("next", "")) != ""
	vt_next.visible = false
