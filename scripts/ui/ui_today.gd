# 0.57: разгрузка игрока. Рамка «Сегодня», рамка «Мир» (бывшие «Карта» и «Организации»), поиск по игре (Ctrl+K),
# «Назад» (Alt+←), клавиши рамок 1–6, Esc закрывает верхнее окно, показатели вверху только когда плохо.
extends "res://scripts/ui/ui_orgs.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func bm_sig() -> String:
	return ""


func inbox_todo() -> Array:
	return []


func layout_remember(desk: int) -> void:
	pass


func rules_open(on: bool) -> void:
	pass


func rules_todo() -> Array:
	return []


func srch_extra(out: Array) -> void:
	pass


func today_bm_defs() -> Array:
	return []


# --- конец заглушек ---


const DESK_TODAY := 21
# рамки в порядке на экране: сначала «Сегодня», потом пять прежних (номера — индексы кнопок рамок, см. build_ui)
const FRAME_ORDER := [6, 0, 1, 2, 3, 5]
const DESK_NAMES := {
	0: "Бюджет", 21: "Сегодня",
	5: "Экономика: рынки и финансы", 7: "Экономика: товары и цены", 10: "Экономика: влияние и зависимость", 16: "Экономика: управление экономикой", 17: "Экономика: корпорации",
	1: "Политика: парламент", 3: "Политика: законы", 4: "Политика: правительство", 6: "Политика: население", 12: "Политика: оппозиция и сделки",
	2: "Мир: карта", 8: "Мир: регионы и автономия", 9: "Мир: территории", 13: "Мир: армия и война", 14: "Мир: флот", 15: "Мир: вооружённые силы", 18: "Мир: организации",
	11: "Общество: религия и миграция", 20: "Общество: церковь и государство", 19: "Общество: культура",
}

var td_todo_box: VBoxContainer = null
var td_todo_sig := ""
var td_prob_rt: RichTextLabel = null
var td_prob_more: RichTextLabel = null
var td_dates_rt: RichTextLabel = null
var td_nums_rt: RichTextLabel = null
var td_tip_rt: RichTextLabel = null
var td_act_box: HFlowContainer = null
var td_act_sig := ""
var nav_hist: Array = []
var nav_skip := false
var srch_ov: Control = null
var srch_edit: LineEdit = null
var srch_list: ItemList = null
var srch_hint: Label = null
var srch_items: Array = []


# ============================================================
#  «Сегодня»
# ============================================================
func build_today_windows() -> void:
	var w: FloatWindow = new_window("td_todo", "Нужно решить", DESK_TODAY, Rect2(0.0, 0.0, 0.27, 0.60))
	td_todo_box = VBoxContainer.new()
	td_todo_box.add_theme_constant_override("separation", 6)
	w.body.add_child(td_todo_box)

	w = new_window("td_prob", "Главные проблемы страны", DESK_TODAY, Rect2(0.27, 0.0, 0.22, 0.46))
	td_prob_rt = make_rt(w.body)
	td_prob_more = make_fold(w.body, "Остальные проблемы")

	w = new_window("td_dates", "Ближайшие даты", DESK_TODAY, Rect2(0.49, 0.0, 0.21, 0.46))
	td_dates_rt = make_rt(w.body)

	w = new_window("td_nums", "Ключевые числа", DESK_TODAY, Rect2(0.27, 0.46, 0.22, 0.54))
	td_nums_rt = make_rt(w.body)

	w = new_window("td_tip", "Подсказка дня", DESK_TODAY, Rect2(0.49, 0.46, 0.21, 0.54))
	td_tip_rt = make_rt(w.body)

	w = new_window("td_act", "Быстрые действия", DESK_TODAY, Rect2(0.0, 0.60, 0.27, 0.40))
	td_act_box = HFlowContainer.new()
	td_act_box.add_theme_constant_override("h_separation", 6)
	td_act_box.add_theme_constant_override("v_separation", 6)
	w.body.add_child(td_act_box)


# вес проблемы 0–100: по нему выбираются три главные
func today_problems() -> Array:
	var out: Array = []
	var ap: float = approval()
	var dr: float = debt / maxf(1.0, gdp) * 100.0
	if not gov_ok():
		out.append({"sev": 96.0, "t": "У правительства нет большинства", "d": "Ваша коалиция держит %d мест из %d, нужно %d. Без большинства законы не проходят." % [gov_seats(), SEATS, MAJORITY], "desk": 4, "win": "coal_sum", "go": "Коалиция"})
	if ap < 50.0:
		out.append({"sev": 38.0 + (50.0 - ap) * 1.7, "t": "Рейтинг власти %.0f%%" % ap, "d": "Ниже 50%: на выборах вы проиграете. Смотрите, какие группы недовольны.", "desk": 0, "win": "groups", "go": "Группы"})
	if dr > 90.0:
		out.append({"sev": 36.0 + (dr - 90.0) * 0.8, "t": "Госдолг %.0f%% ВВП" % dr, "d": "Выше 150% — дефолт. Проценты по долгу съедают бюджет.", "desk": 0, "win": "tax", "go": "Бюджет"})
	if last_deficit_pct > 3.0:
		out.append({"sev": 30.0 + (last_deficit_pct - 3.0) * 9.0, "t": "Дефицит бюджета %.1f%% ВВП" % last_deficit_pct, "d": "Долг растёт. Поднимите налоги или урежьте расходы.", "desk": 0, "win": "forecast", "go": "Бюджет"})
	if inflation > 6.0:
		out.append({"sev": 34.0 + (inflation - 6.0) * 4.0, "t": "Инфляция %.1f%%" % inflation, "d": "Выше 6% экономика страдает. Помогает ключевая ставка и сдержанный бюджет.", "desk": 5, "win": "ec_cb", "go": "Центробанк"})
	if unemployment > 9.0:
		out.append({"sev": 30.0 + (unemployment - 9.0) * 5.0, "t": "Безработица %.1f%%" % unemployment, "d": "Много безработных: недовольны рабочие и бюджетники.", "desk": 5, "win": "ec_bz", "go": "Экономика"})
	if growth < -0.5:
		out.append({"sev": 34.0 + absf(growth) * 8.0, "t": "Спад экономики %.1f%%" % growth, "d": "ВВП сокращается. Нужны инвестиции и стабильная политика.", "desk": 5, "win": "ec_bz", "go": "Экономика"})
	if capital < 8.0:
		out.append({"sev": 44.0 + (8.0 - capital) * 2.0, "t": "Политический капитал на исходе: %.1f" % capital, "d": "Его не хватит на законы и переговоры. Он копится каждый месяц.", "desk": 1, "win": "actions", "go": "Действия"})
	if regime_risk > 40.0:
		out.append({"sev": 46.0 + (regime_risk - 40.0) * 0.9, "t": "Риск потрясений %.0f из 100" % regime_risk, "d": "Протесты и мятежи. Раннее вмешательство дешевле: диалог, инвестиции, автономия.", "crisis": true, "go": "Кризисы"})
	var unr: float = reg_avg("unrest")
	if unr > 35.0:
		out.append({"sev": 30.0 + (unr - 35.0) * 1.2, "t": "Недовольство в регионах %.0f из 100" % unr, "d": "Отдалённые и бедные регионы тянут в сторону от центра.", "desk": 2, "win": "regtable", "go": "Регионы"})
	if not ec.is_empty() and float(ec.get("res", 10.0)) < 3.0:
		out.append({"sev": 36.0, "t": "Резервы почти кончились: %.1f%% ВВП" % float(ec["res"]), "d": "Валюта уязвима.", "desk": 5, "win": "ec_gf", "go": "Торговля"})
	for d in LEVELS:
		var v: float = float(lvl[d["key"]])
		if v < 35.0:
			out.append({"sev": 26.0 + (35.0 - v) * 0.9, "t": "«%s» упало до %.0f" % [String(d["title"]), v], "d": "Отклонение от 50 действует каждый месяц.", "desk": 0, "win": "economy", "go": "Состояние"})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["sev"]) > float(b["sev"]))
	return out


# что ждёт решения игрока: [{t, btn, f: Callable}]
func today_todo() -> Array:
	var out: Array = []
	if not current_event.is_empty():
		out.append({"t": "[b]Ждёт решения событие[/b]\nВремя остановлено, пока вы не выберете.", "btn": "К событию", "f": func() -> void: show_desk(current_desk)})
	out.append_array(inbox_todo())
	out.append_array(rules_todo())
	if coal_talks:
		out.append({"t": "[b]Идут коалиционные переговоры[/b]\nСоберите большинство, иначе правительство не сформируется.", "btn": "Переговоры", "f": func() -> void: cn_open(true)})
	if not bud_changes().is_empty():
		out.append({"t": "[b]Бюджет изменён, но не принят[/b]\nПравки вступят в силу только после «Принять бюджет».", "btn": "К бюджету", "f": func() -> void: goto_win("tax")})
	if pa_props.size() > 0:
		out.append({"t": "[b]Министры предлагают изменить бюджет: %d[/b]\nМожно согласиться или наложить вето." % pa_props.size(), "btn": "К предложениям", "f": func() -> void: goto_win("cabinet")})
	if offer_pending:
		out.append({"t": "[b]Вам предложили войти в правительство[/b]", "btn": "Оппозиция", "f": func() -> void: show_desk(12)})
	if bills.size() > 0:
		out.append({"t": "[b]Законопроекты в работе: %d[/b]\nГолосования и поправки." % bills.size(), "btn": "Законопроекты", "f": func() -> void: goto_win("bills")})
	if capital >= 60.0:
		out.append({"t": "[b]Накоплено %.0f политического капитала[/b]\nЕго можно потратить на законы и реформы." % capital, "btn": "Законы", "f": func() -> void: show_desk(3)})
	return out


func today_dates() -> PackedStringArray:
	var out: PackedStringArray = []
	var parl_in: int = parl_term() - (turn - last_parl)
	out.append("[b]Выборы парламента[/b]: %s (%s)" % [months_short(parl_in) if parl_in >= 3 else "%d дн." % days_until_months(parl_in), turn_date(turn + maxi(0, parl_in))])
	if pres_due >= 0 and pres_due >= turn:
		out.append("[b]Выборы главы государства[/b]: %s (%s)" % [months_short(pres_due - turn), turn_date(pres_due)])
	var to_jan: int = (13 - month) % 12
	if to_jan == 0:
		to_jan = 12
	out.append("[b]Итоги года[/b]: январь, через %s" % months_short(to_jan))
	for k in bq.size():
		var b: Dictionary = bq[k]
		var left: int = int(b.get("months", 0)) - int(b.get("done", 0))
		if left > 0 and left <= 3:
			out.append("Стройка завершится через %s" % months_short(left))
			break
	return out


func today_nums() -> String:
	var pv: Dictionary = top_prev
	var ap: float = approval()
	var dr: float = debt / maxf(1.0, gdp) * 100.0
	var rows: PackedStringArray = []
	rows.append(today_row("Рейтинг", "%.0f%%" % ap, ap - float(pv.get("appr", ap)), true, 1, scale_color(ap / 100.0)))
	rows.append(today_row("ВВП, млрд", fmt_n(gdp), growth, true, 1, C_TEXT, "% за год"))
	rows.append(today_row("Инфляция", "%.1f%%" % inflation, inflation - float(pv.get("infl", inflation)), false, 2, scale_color(1.0 - inflation / 12.0)))
	rows.append(today_row("Безработица", "%.1f%%" % unemployment, unemployment - float(pv.get("unemp", unemployment)), false, 2, scale_color(1.0 - unemployment / 14.0)))
	rows.append(today_row("Долг", "%.0f%% ВВП" % dr, dr - float(pv.get("debt", dr)), false, 1, scale_color(1.0 - dr / 110.0)))
	rows.append(today_row("Дефицит", "%.1f%% ВВП" % last_deficit_pct, 0.0, false, 1, C_GOOD if last_deficit_pct <= 3.0 else (C_WARN if last_deficit_pct <= 5.0 else C_BAD), ""))
	rows.append(today_row("Капитал", "%.1f" % capital, cap_rate(), true, 1, C_BAD if capital < 0.0 else (C_WARN if capital < 15.0 else C_TEXT), "в месяц"))
	rows.append(today_row("Коалиция", "%d из %d" % [gov_seats(), SEATS], 0.0, true, 0, C_GOOD if gov_ok() else C_BAD, ""))
	if not ec.is_empty():
		rows.append(today_row("Резервы", "%.1f%% ВВП" % float(ec.get("res", 0.0)), 0.0, true, 1, C_GOOD if float(ec.get("res", 10.0)) >= 3.0 else C_BAD, ""))
	return "[table=3]" + "".join(rows) + "[/table]"


func today_row(name: String, val: String, dv: float, up_good: bool, digits: int, col: Color, unit: String = "") -> String:
	var dt := ""
	if absf(dv) >= 0.005:
		var good: bool = (dv > 0.0) == up_good
		dt = "[color=%s]%s %s[/color]" % [COL_GOOD if good else COL_BAD, "▲" if dv > 0.0 else "▼", ("%." + str(digits) + "f") % absf(dv)]
		if unit != "":
			dt += " [color=%s]%s[/color]" % [COL_DIM, unit]
	elif unit != "":
		dt = "[color=%s]%s[/color]" % [COL_DIM, unit]
	return "[cell][color=%s]%s[/color]   [/cell][cell][b][color=#%s]%s[/color][/b]   [/cell][cell]%s[/cell]" % [COL_DIM, name, col.to_html(false), val, dt]


const DAY_TIPS := [
	"Любое число вверху можно навести мышью: появится объяснение и причины изменения.",
	"Ctrl+K открывает поиск по игре: окна, законы, страны, регионы и действия.",
	"Клавиши 1–6 переключают рамки, Alt+← возвращает назад, Esc закрывает верхнее окно.",
	"Пробел ставит игру на паузу и пускает время снова.",
	"Бюджет вступает в силу только после «Принять бюджет». Правки до этого — просто план.",
	"Политический капитал копится каждый месяц. Не тратьте его весь: он нужен на кризисы.",
	"Раннее вмешательство в кризис дешевле позднего: диалог, инвестиции, автономия.",
	"Коалиционные партнёры недовольны уступками другим. Следите за их довольством в окне коалиции.",
]


func today_tip() -> String:
	return "[font_size=14]%s[/font_size]" % DAY_TIPS[(turn + day_total / 30) % DAY_TIPS.size()]


func update_today() -> void:
	if td_todo_box == null:
		return
	# --- нужно решить ---
	var todo: Array = today_todo()
	var sig := ""
	for it in todo:
		sig += String(it["t"]) + "|"
	if sig != td_todo_sig:
		td_todo_sig = sig
		for ch in td_todo_box.get_children():
			ch.queue_free()
		if todo.is_empty():
			var rt0 := make_rt(td_todo_box)
			rt0.text = "[font_size=15][b]Срочных решений нет.[/b][/font_size]\n[color=%s]Можно пускать время. Игра остановится сама, когда понадобится ваш ответ.[/color]" % COL_DIM
		for it in todo:
			var pc := PanelContainer.new()
			pc.add_theme_stylebox_override("panel", sbox(C_PANEL2, C_BORDER, 1, 8, 10.0, 8.0))
			td_todo_box.add_child(pc)
			var hb := HBoxContainer.new()
			hb.add_theme_constant_override("separation", 10)
			pc.add_child(hb)
			var rt := make_rt(hb)
			rt.text = "[font_size=13]%s[/font_size]" % String(it["t"])
			var bt := Button.new()
			bt.text = String(it["btn"])
			bt.focus_mode = Control.FOCUS_NONE
			bt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			bt.pressed.connect(it["f"])
			bt.visible = String(it["btn"]) != ""
			hb.add_child(bt)
			if it.has("btn2"):
				var b2 := Button.new()
				b2.text = String(it["btn2"])
				b2.focus_mode = Control.FOCUS_NONE
				b2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				b2.pressed.connect(it["f2"])
				hb.add_child(b2)
	# --- проблемы ---
	var probs: Array = today_problems()
	var head: PackedStringArray = []
	var rest: PackedStringArray = []
	for k in probs.size():
		var p: Dictionary = probs[k]
		var sev: float = float(p["sev"])
		var col: String = COL_BAD if sev >= 60.0 else (COL_WARN if sev >= 40.0 else COL_DIM)
		var ln: String = "[color=%s]●[/color] [b]%s[/b]\n[color=%s]%s[/color]" % [col, String(p["t"]), COL_DIM, String(p["d"])]
		if k < 3:
			head.append(ln)
		else:
			rest.append(ln)
	if head.is_empty():
		td_prob_rt.text = "[font_size=14][color=%s][b]Серьёзных проблем нет.[/b][/color][/font_size]\n[color=%s]Главные показатели в пределах нормы.[/color]" % [COL_GOOD, COL_DIM]
	else:
		td_prob_rt.text = "\n\n".join(head)
	td_prob_more.text = "\n\n".join(rest) if not rest.is_empty() else "[color=%s]Больше ничего.[/color]" % COL_DIM
	# --- даты, числа, недавнее ---
	td_dates_rt.text = "\n".join(today_dates())
	td_nums_rt.text = today_nums()
	td_tip_rt.text = today_tip()
	# --- быстрые действия ---
	var asig := "%d|%s" % [play_idx, bm_sig()]
	if asig != td_act_sig:
		td_act_sig = asig
		for ch in td_act_box.get_children():
			ch.queue_free()
		var defs: Array = [
			["Бюджет", func() -> void: goto_win("tax")],
			["Законы", func() -> void: show_desk(3)],
			["Коалиция и кабинет", func() -> void: show_desk(4)],
			["Парламент", func() -> void: show_desk(1)],
			["Мир: карта", func() -> void: show_desk(2)],
			["Организации", func() -> void: show_desk(18)],
			["Автоматика", func() -> void: rules_open(true)],
			["Поиск по игре (Ctrl+K)", func() -> void: srch_open(true)],
			["Пауза" if play_idx > 0 else "Пустить время", func() -> void: on_play_toggled(play_idx <= 0)],
		]
		defs.append_array(today_bm_defs())
		for d in defs:
			var b := Button.new()
			b.text = String(d[0])
			b.focus_mode = Control.FOCUS_NONE
			b.pressed.connect(d[1])
			td_act_box.add_child(b)


# ============================================================
#  Переходы: окно по идентификатору, «Назад»
# ============================================================
func goto_win(id: String) -> void:
	if not wins.has(id):
		return
	var w: FloatWindow = wins[id]
	var d: int = w.desk
	if d == -2:
		return
	if d == -1:
		d = current_desk
	if tech_is_open():
		set_tech_open(false)
	if crisis_is_open():
		set_crisis_open(false)
	if meas_is_open():
		set_meas_open(false)
	if cn_is_open():
		cn_close()
	w.closed = false
	show_desk(d)
	w.move_to_front()
	if w.visible and bool(game_opts.get("anim", true)):
		w.modulate = Color(1.5, 1.5, 1.3)
		w.create_tween().tween_property(w, "modulate", Color.WHITE, 0.7)


# вызывается из show_desk перед сменой раздела: запоминаем, откуда пришли
func nav_note(_i: int) -> void:
	layout_remember(current_desk)
	if not nav_skip and not wins.is_empty():
		nav_hist.append(current_desk)
		if nav_hist.size() > 30:
			nav_hist.pop_front()


func nav_back() -> void:
	if nav_hist.is_empty():
		return
	var d: int = int(nav_hist.pop_back())
	nav_skip = true
	show_desk(d)
	nav_skip = false


# ============================================================
#  Показатели вверху: инфляция и безработица только когда плохо; резервы и курс
# ============================================================
func update_chips_extra() -> void:
	if chips.is_empty():
		return
	for ck in CHIP_HELP:
		if chips.has(ck):
			(chips[ck]["pc"] as Control).tooltip_text = chip_tip(ck)
	var all: bool = bool(game_opts.get("chips_all", false))
	var pv: Dictionary = top_prev
	if chips.has("infl"):
		var bad_i: bool = inflation >= 5.0 or inflation - float(pv.get("infl", inflation)) >= 0.5
		(chips["infl"]["pc"] as Control).visible = all or bad_i
	if chips.has("unemp"):
		var bad_u: bool = unemployment >= 8.0 or unemployment - float(pv.get("unemp", unemployment)) >= 0.4
		(chips["unemp"]["pc"] as Control).visible = all or bad_u
	if chips.has("res") and not ec.is_empty():
		var res: float = float(ec.get("res", 0.0))
		set_chip_num("res", res, func(x: float) -> String: return "%.1f%%" % x, C_BAD if res < 3.0 else (C_WARN if res < 6.0 else C_TEXT))
	if chips.has("fxs") and not ec.is_empty():
		var fxs: float = float(ec.get("fxs", 1.0))
		var ago: float = maxf(0.0001, float(h12_ago("fxs", fxs)))
		var ch: float = (fxs / ago - 1.0) * 100.0
		set_chip("fxs", "%s%.1f%%" % ["+" if ch >= 0.0 else "", ch], C_BAD if ch < -8.0 else (C_WARN if ch < -3.0 else C_TEXT), "", C_DIM)


# ============================================================
#  Подсказки к числам вверху: простыми словами, график за 12 месяцев, куда нажать
# ============================================================
const CHIP_HELP := {
	"appr": ["Рейтинг власти", "Доля довольных вашей работой. От него зависят выборы и устойчивость коалиции.", "доходы и пособия, налоги, события, скандалы, настроение групп", "Бюджет → «Группы интересов»"],
	"gdp": ["ВВП", "Всё, что страна производит за год. Мелкий значок рядом — рост за год.", "деловой климат, инвестиции, налоги на бизнес, курс, энергия", "Экономика → «Рынки» и «Товары»"],
	"infl": ["Инфляция", "На сколько в среднем дорожают товары за год. Выше 5–6% начинает бить по рейтингу.", "эмиссия, ставка, пошлины, цены на энергию, курс валюты", "Экономика → «Рынки», «Управление экономикой»"],
	"unemp": ["Безработица", "Доля людей без работы. Растёт при спаде и падает при росте и субсидиях.", "рост экономики, субсидии, пособия, миграция", "Бюджет → «Экономика и состояние страны»"],
	"debt": ["Госдолг", "Долг государства в процентах от годового ВВП. Выше 90–100% рынки требуют больше процентов.", "дефицит бюджета, процентная ставка, рост ВВП", "Бюджет → «Налоги и расходы»"],
	"res": ["Резервы", "Запас валюты и золота в процентах ВВП. Помогает держать курс в трудные месяцы.", "торговый баланс, помощь партнёров, интервенции", "Экономика → «Управление экономикой»"],
	"fxs": ["Курс валюты за 12 месяцев", "Изменение курса к началу года. Слабая валюта дорожит импорт и разгоняет инфляцию.", "торговый баланс, резервы, доверие инвесторов", "Экономика → «Управление экономикой»"],
	"cap": ["Политический капитал", "Ресурс решений: законы, реформы и дорогие варианты событий. Растёт каждый месяц.", "рейтинг, коалиция, сильные министры", "Законы"],
}
const SPARK := ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
const CHIP_HKEY := {"appr": "appr", "gdp": "gdp", "infl": "infl", "unemp": "unemp", "debt": "debtr", "res": "res", "fxs": "fxs", "cap": "cap"}


func spark_text(a: Array) -> String:
	if a.size() < 3:
		return ""
	var lo := 1e18
	var hi := -1e18
	for v in a:
		lo = minf(lo, float(v))
		hi = maxf(hi, float(v))
	var out := ""
	for v in a:
		var k := 3 if hi - lo < maxf(0.05, 0.02 * absf(hi)) else int(round((float(v) - lo) / (hi - lo) * 7.0))
		out += String(SPARK[clampi(k, 0, 7)])
	return out


func chip_tip(key: String) -> String:
	var h: Array = CHIP_HELP.get(key, [])
	if h.is_empty():
		return ""
	var secs: Array = [["Что это", String(h[1])]]
	var hk: String = String(CHIP_HKEY.get(key, key))
	var arr: Array = h12.get(hk, [])
	var sp := spark_text(arr)
	if sp != "":
		var lo := 1e18
		var hi := -1e18
		for v in arr:
			lo = minf(lo, float(v))
			hi = maxf(hi, float(v))
		secs.append(["За %d мес." % (arr.size() - 1), "%s   от %s до %s" % [sp, fmt_n(lo) if hk == "gdp" else "%.1f" % lo, fmt_n(hi) if hk == "gdp" else "%.1f" % hi]])
	var why := ""
	if key == "gdp" and not ec.is_empty() and ec.has("reasons"):
		var rs: Array = (ec["reasons"] as Array).duplicate()
		rs.sort_custom(func(a: Array, b: Array) -> bool: return absf(float(a[1])) > absf(float(b[1])))
		var top: PackedStringArray = []
		for k in mini(3, rs.size()):
			top.append("%s (%s)" % [String(rs[k][0]).to_lower(), sg(float(rs[k][1]), 1)])
		why = "сильнее всего сейчас: " + ", ".join(top)
	secs.append(["Что влияет", why if why != "" else String(h[2])])
	secs.append(["Куда нажать", String(h[3])])
	return tip_make(String(h[0]), secs)


# ============================================================
#  Поиск по игре (Ctrl+K)
# ============================================================
func srch_collect() -> Array:
	var out: Array = []
	for d in DESK_NAMES:
		var dd: int = d
		out.append({"k": "Раздел", "t": String(DESK_NAMES[d]), "x": "", "f": func() -> void: show_desk(dd)})
	for id in wins:
		var w: FloatWindow = wins[id]
		if w.desk < 0:
			continue
		var wid: String = String(id)
		out.append({"k": "Окно", "t": w.get_title(), "x": String(DESK_NAMES.get(w.desk, "")), "f": func() -> void: goto_win(wid)})
	var ind: Array = [
		["Рейтинг власти", "рейтинг одобрение", 0, "groups"], ["ВВП и рост", "ввп рост экономика", 0, "economy"], ["Инфляция", "инфляция цены ставка", 5, "ec_cb"],
		["Безработица", "безработица занятость", 5, "ec_bz"], ["Госдолг", "долг дефицит проценты", 0, "forecast"], ["Политический капитал", "капитал", 1, "actions"],
		["Резервы и курс", "резервы курс валюта", 5, "ec_gf"], ["Налоги", "налог ндс подоходный", 0, "tax"], ["Расходы бюджета", "расходы пенсии", 0, "tax"],
	]
	for it in ind:
		var iw: String = String(it[3])
		out.append({"k": "Показатель", "t": String(it[0]), "x": String(it[1]), "f": func() -> void: goto_win(iw)})
	if not law_index.is_empty():
		for tid in law_index:
			var ti: String = String(tid)
			out.append({"k": "Закон", "t": String(law_index[tid]["name"]), "x": String(law_index[tid].get("desc", "")), "f": func() -> void:
				show_desk(3)
				on_topic_pressed(ti)})
	for ri in regions.size():
		var rj: int = ri
		out.append({"k": "Регион", "t": String(regions[ri].get("name", "Регион %d" % ri)), "x": "карта регион", "f": func() -> void:
			show_desk(2)
			on_region_picked(rj)})
	for cc in WORLD:
		if String(cc) == ccode:
			continue
		var c2: String = String(cc)
		out.append({"k": "Страна", "t": String(WORLD[cc]["name"]), "x": c2, "f": func() -> void:
			show_desk(2)
			dip_sel = c2
			map_mode = "foreign"
			map_apply_mode()
			refresh()})
	var acts: Array = [
		["Пауза / пустить время", "пробел время", func() -> void: on_play_toggled(play_idx <= 0)],
		["Принять бюджет", "бюджет утвердить", func() -> void: on_bud_accept()],
		["Настройки", "настройки звук тема", func() -> void: settings_open(true)],
		["Технологии", "технологии наука", func() -> void: set_tech_open(true)],
		["Кризисы", "кризис протест мятеж", func() -> void: set_crisis_open(true)],
		["Разовые меры", "меры советник", func() -> void: set_meas_open(true)],
		["Назад", "alt назад", func() -> void: nav_back()],
	]
	for a in acts:
		out.append({"k": "Действие", "t": String(a[0]), "x": String(a[1]), "f": a[2]})
	srch_extra(out)
	return out


func srch_open(on: bool) -> void:
	if on and srch_ov == null:
		srch_build()
	if srch_ov == null:
		return
	srch_ov.visible = on
	if on:
		srch_items = srch_collect()
		srch_edit.text = ""
		srch_fill("")
		srch_edit.grab_focus()
		win_fade_in(srch_ov, 0.12)
	else:
		srch_edit.release_focus()


func srch_build() -> void:
	srch_ov = Control.new()
	srch_ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	srch_ov.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(srch_ov)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		var mb := ev as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			srch_open(false))
	srch_ov.add_child(dim)
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", sbox(C_PANEL, C_ACCENT.darkened(0.2), 2, 12, 12.0, 10.0))
	pan.anchor_left = 0.5
	pan.anchor_right = 0.5
	pan.anchor_top = 0.14
	pan.offset_left = -300.0
	pan.offset_right = 300.0
	pan.offset_top = 0.0
	srch_ov.add_child(pan)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	pan.add_child(vb)
	srch_edit = LineEdit.new()
	srch_edit.placeholder_text = "Что открыть? Окно, закон, страна, регион, действие…"
	srch_edit.add_theme_font_size_override("font_size", 17)
	srch_edit.text_changed.connect(srch_fill)
	srch_edit.text_submitted.connect(func(_t: String) -> void: srch_run(srch_list.get_selected_items()[0] if srch_list.get_selected_items().size() > 0 else 0))
	srch_edit.gui_input.connect(srch_key)
	vb.add_child(srch_edit)
	srch_list = ItemList.new()
	srch_list.custom_minimum_size = Vector2(0.0, 340.0)
	srch_list.focus_mode = Control.FOCUS_NONE
	srch_list.select_mode = ItemList.SELECT_SINGLE
	srch_list.item_activated.connect(srch_run)
	vb.add_child(srch_list)
	srch_hint = Label.new()
	srch_hint.add_theme_font_size_override("font_size", 12)
	srch_hint.add_theme_color_override("font_color", C_DIM)
	srch_hint.text = "↑ ↓ — выбрать, Enter — открыть, Esc — закрыть"
	vb.add_child(srch_hint)
	srch_ov.visible = false


func srch_key(ev: InputEvent) -> void:
	var ke := ev as InputEventKey
	if ke == null or not ke.pressed:
		return
	var n: int = srch_list.item_count
	var cur: int = srch_list.get_selected_items()[0] if srch_list.get_selected_items().size() > 0 else 0
	if ke.keycode == KEY_DOWN and n > 0:
		srch_list.select(mini(n - 1, cur + 1))
		srch_list.ensure_current_is_visible()
		srch_edit.accept_event()
	elif ke.keycode == KEY_UP and n > 0:
		srch_list.select(maxi(0, cur - 1))
		srch_list.ensure_current_is_visible()
		srch_edit.accept_event()
	elif ke.keycode == KEY_ESCAPE:
		srch_open(false)
		srch_edit.accept_event()


# совпадение: все слова запроса входят в название или подсказку; название, начинающееся с запроса, — выше
func srch_fill(q: String) -> void:
	srch_list.clear()
	var words: PackedStringArray = q.strip_edges().to_lower().split(" ", false)
	var scored: Array = []
	for i in srch_items.size():
		var it: Dictionary = srch_items[i]
		var t: String = String(it["t"]).to_lower()
		var hay: String = t + " " + String(it["x"]).to_lower()
		var ok := true
		var sc := 0
		for w in words:
			if hay.find(w) < 0:
				ok = false
				break
			if t.begins_with(w):
				sc += 3
			elif t.find(w) >= 0:
				sc += 2
			else:
				sc += 1
		if ok:
			if words.is_empty():
				sc = 0 if String(it["k"]) in ["Раздел", "Действие"] else -1
				if sc < 0:
					continue
			scored.append([sc, i])
	scored.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) > int(b[0]) or (int(a[0]) == int(b[0]) and int(a[1]) < int(b[1])))
	srch_map = []
	for s in scored:
		if srch_map.size() >= 14:
			break
		var it2: Dictionary = srch_items[int(s[1])]
		var line: String = "%s   ·   %s" % [String(it2["t"]), String(it2["k"])]
		srch_list.add_item(line)
		srch_map.append(int(s[1]))
	if srch_list.item_count > 0:
		srch_list.select(0)


var srch_map: Array = []


func srch_run(idx: int) -> void:
	if idx < 0 or idx >= srch_map.size():
		return
	var it: Dictionary = srch_items[int(srch_map[idx])]
	srch_open(false)
	sfx("click")
	(it["f"] as Callable).call()


# ============================================================
#  Клавиши: Ctrl+K, Alt+←, 1–6 (рамки), Esc (закрыть верхнее окно)
# ============================================================
func ui_hotkey(ke: InputEventKey) -> bool:
	var k: int = ke.keycode
	if k == KEY_K and (ke.ctrl_pressed or ke.meta_pressed):
		srch_open(srch_ov == null or not srch_ov.visible)
		return true
	if srch_ov != null and srch_ov.visible:
		return false
	var fo := get_viewport().gui_get_focus_owner()
	if fo is LineEdit or fo is TextEdit:
		return false
	if k == KEY_LEFT and ke.alt_pressed:
		nav_back()
		return true
	if k == KEY_ESCAPE:
		return esc_close()
	if k >= KEY_1 and k <= KEY_6 and not (ke.ctrl_pressed or ke.alt_pressed or ke.meta_pressed or ke.shift_pressed):
		if has_node("CountryMenu") or start_ov != null or (st_ov != null and st_ov.visible):
			return false
		show_tab(int(FRAME_ORDER[k - KEY_1]))
		return true
	return false


func esc_close() -> bool:
	if st_ov != null and st_ov.visible:
		settings_open(false)
		return true
	if tech_is_open():
		set_tech_open(false)
		return true
	if crisis_is_open():
		set_crisis_open(false)
		return true
	if meas_is_open():
		set_meas_open(false)
		return true
	if cn_is_open():
		cn_close()
		return true
	var kids: Array = workspace.get_children()
	for i in range(kids.size() - 1, -1, -1):
		var w := kids[i] as FloatWindow
		if w != null and w.visible and w.closable and w.desk != -2 and w.desk != -1:
			on_win_close(w)
			return true
	return false
