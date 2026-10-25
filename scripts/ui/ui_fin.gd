# 0.63: интерфейс финансов. Рамка «Экономика» → вкладка «Финансы» (desk 22): сводка, центробанк и курс, банки, биржа,
# долг и МВФ, фонды; маленькие графики истории fin["h"]; действия fin_acts(page) списком кнопок по группам (нажатие — fin_do(id)).
# Три плашки вверху (курс, ставка, доверие рынков) обновляет fin_chips_update() из update_chips_extra (ui_today.gd).
extends "res://scripts/ui/ui_econ.gd"

const FIN_DESK := 22
const FN_INS_NAMES := ["нет", "обычное, до предела", "полное, все вклады"]
const FN_REG_NAMES := ["слабый", "обычный", "строгий", "очень строгий"]
const FN_OUT_NAMES := {"never": "не тратить", "crisis": "в кризис", "fix": "4% остатка в год"}
const FN_FUND_NAMES := {"res": "Ресурсный фонд", "pen": "Пенсионный и резервный фонд", "own": "Свой фонд"}
const FN_SPARK_COL := {"mood": Color(0.45, 0.85, 0.65), "rate": Color(0.95, 0.75, 0.35), "fxs": Color(0.45, 0.75, 1.0), "res": Color(0.80, 0.70, 0.45),
	"car": Color(0.55, 0.85, 0.55), "npl": Color(1.0, 0.55, 0.45), "cr": Color(0.65, 0.70, 1.0), "idx": Color(0.70, 0.60, 1.0), "spr": Color(1.0, 0.60, 0.40), "for": Color(0.55, 0.85, 0.90)}

var fn_rt := {}          # ключ -> RichTextLabel
var fn_box := {}         # ключ -> Control (то, что прячется при выключенном модуле)
var fn_acts_ui := {}     # ключ блока действий -> {"box": VBoxContainer, "sig": String}
var fn_open := {}        # «блок/группа» -> раскрыта ли группа действий
var fn_sparks := {}      # ключ истории -> [Spark, подпись]
var fn_off_rt: RichTextLabel = null


# ============================================================
#  ПОСТРОЕНИЕ
# ============================================================
func build_fin_windows() -> void:
	# --- сводка ---
	var w: FloatWindow = new_window("fn_sum", "Сводка финансов", FIN_DESK, Rect2(0.0, 0.0, 0.235, 0.52))
	if int(game_opts.get("finlev", 0)) <= 0:
		# модуль выключен: окно в одну строку
		w.frac = Rect2(0.0, 0.0, 0.235, 0.12)
		w.default_frac = w.frac
	fn_off_rt = make_rt(w.body)
	var vb := fn_vbox(w.body, "sum")
	add_bar(vb, "fn_mood", "Доверие рынков", false, 60.0)
	fn_rt["sum"] = make_rt(vb)
	fn_tail(fn_rt["sum"], "Что такое доверие рынков")
	add_title(vb, "Последние события")
	fn_rt["log"] = make_rt(vb)
	fn_tail(fn_rt["log"], "Раньше")
	fn_spark_row(vb, [["mood", "Доверие"], ["rate", "Ставка"]])

	# --- центробанк и курс ---
	w = new_window("fn_cb", "Центробанк и курс", FIN_DESK, Rect2(0.235, 0.0, 0.235, 0.62))
	vb = fn_vbox(w.body, "cb")
	add_bar(vb, "fn_ind", "Независимость", false, 60.0)
	add_bar(vb, "fn_cred", "Доверие к ЦБ", false, 50.0)
	fn_rt["cb"] = make_rt(vb)
	fn_tail(fn_rt["cb"], "Подробнее")
	add_title(vb, "Действия")
	fn_acts_box(vb, "cbfx")
	fn_spark_row(vb, [["fxs", "Курс"], ["res", "Резервы"]])

	# --- фонды ---
	w = new_window("fn_fund", "Фонды", FIN_DESK, Rect2(0.235, 0.62, 0.235, 0.38))
	vb = fn_vbox(w.body, "fund")
	fn_rt["fund"] = make_rt(vb)
	fn_tail(fn_rt["fund"], "Как работают фонды")
	fn_acts_box(vb, "fund")

	# --- банки ---
	w = new_window("fn_bank", "Банки", FIN_DESK, Rect2(0.47, 0.0, 0.235, 0.52))
	vb = fn_vbox(w.body, "bank")
	add_bar(vb, "fn_trust", "Вкладчики", false, 55.0)
	fn_rt["bank"] = make_rt(vb)
	fn_tail(fn_rt["bank"], "Подробнее")
	add_title(vb, "Действия")
	fn_acts_box(vb, "bank")
	fn_spark_row(vb, [["car", "Капитал"], ["npl", "Плохие"], ["cr", "Кредит"]])

	# --- биржа ---
	w = new_window("fn_ex", "Биржа", FIN_DESK, Rect2(0.0, 0.52, 0.235, 0.48))
	vb = fn_vbox(w.body, "ex")
	fn_rt["ex"] = make_rt(vb)
	fn_tail(fn_rt["ex"], "Подробнее")
	add_title(vb, "Действия")
	fn_acts_box(vb, "ex")
	fn_spark_row(vb, [["idx", "Индекс биржи"]])

	# --- долг и МВФ ---
	w = new_window("fn_debt", "Долг и МВФ", FIN_DESK, Rect2(0.47, 0.52, 0.235, 0.48))
	vb = fn_vbox(w.body, "debt")
	fn_rt["debt"] = make_rt(vb)
	fn_tail(fn_rt["debt"], "Подробнее")
	add_title(vb, "Действия")
	fn_acts_box(vb, "debt")
	fn_spark_row(vb, [["spr", "Спред"], ["for", "У иностранцев"]])


# «хвост» текста в сворачиваемом блоке; в отличие от make_tail он свёрнут с самого начала (окна остаются короткими)
func fn_tail(head: RichTextLabel, title: String) -> void:
	make_tail(head, title)
	var fe: Array = fold_nodes[fold_nodes.size() - 1]
	(fe[0] as Button).set_pressed_no_signal(false)
	on_fold_toggled(false, fe[0], fe[1])


func fn_vbox(parent: Control, key: String) -> VBoxContainer:
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 5)
	parent.add_child(vb)
	fn_box[key] = vb
	return vb


func fn_spark_row(parent: Control, defs: Array) -> void:
	var g := GridContainer.new()
	g.columns = defs.size()
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 4)
	parent.add_child(g)
	for d in defs:
		var sp: Control = Spark.new()
		sp.custom_minimum_size = Vector2(80.0, 54.0)
		if String(d[0]) == "mood":
			sp.set("ymin", 0.0)
			sp.set("ymax", 100.0)
		g.add_child(sp)
		fn_sparks[String(d[0])] = [sp, String(d[1])]


func fn_acts_box(parent: Control, key: String) -> void:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 3)
	parent.add_child(box)
	fn_acts_ui[key] = {"box": box, "sig": ""}


# ============================================================
#  ДЕЙСТВИЯ: группы, кнопки, перерисовка при изменении
# ============================================================
# группа действия: своя у логики (grp), а у центробанка и курса — по виду действия
func fn_group_of(a: Dictionary) -> String:
	if a.has("grp"):
		return String(a["grp"])
	var id: String = String(a["id"])
	if id.begins_with("head_"):
		return "Глава центробанка"
	if id == "cb_qe" or id == "cb_unqe":
		return "Покупки облигаций"
	if id.begins_with("cb_") or id.begins_with("eu_lobby"):
		return "Ставка и независимость"
	if id == "euro_exit":
		return "Евро"
	if id.begins_with("fx_to_"):
		return "Состав резервов"
	if id in ["fx_sell", "fx_buy", "fx_capctl", "fx_swap", "fx_loan"]:
		return "Защита курса и резервы"
	return "Режим курса"


# почему сейчас нельзя ничего (событие на экране, наблюдатель, оппозиция); пусто — можно
func fn_block_why() -> String:
	if observer:
		return "в режиме наблюдателя решения принимает компьютер"
	if not current_event.is_empty():
		return "сначала примите решение в окне события"
	var pw: String = pl_why()
	return pw.trim_suffix(".").to_lower() if pw != "" else ""


func fn_acts_update(key: String, acts: Array, empty_text: String) -> void:
	if not fn_acts_ui.has(key):
		return
	var e: Dictionary = fn_acts_ui[key]
	var box: VBoxContainer = e["box"]
	var block: String = fn_block_why()
	var sig := block
	for a in acts:
		sig += "|%s;%s;%s;%s;%s" % [a["id"], a["name"], a["ok"], a["why"], a.get("cap", 0.0)]
	if sig == String(e["sig"]):
		return
	e["sig"] = sig
	for ch in box.get_children():
		box.remove_child(ch)
		ch.queue_free()
	if acts.is_empty():
		var r := make_rt(box)
		r.text = "[color=%s]%s[/color]" % [COL_DIM, empty_text]
		return
	# группы в порядке появления
	var order: Array = []
	var by: Dictionary = {}
	for a in acts:
		var gname: String = fn_group_of(a)
		if not by.has(gname):
			by[gname] = []
			order.append(gname)
		(by[gname] as Array).append(a)
	for gi in order.size():
		var gname: String = order[gi]
		var lst: Array = by[gname]
		var cont := VBoxContainer.new()
		cont.add_theme_constant_override("separation", 2)
		var ok_n := 0
		for a in lst:
			if bool(a["ok"]) and block == "":
				ok_n += 1
		var okey: String = key + "/" + gname
		# по умолчанию раскрыта первая группа и группа кризиса
		var open: bool = bool(fn_open.get(okey, gi == 0 or gname == "Кризис"))
		if order.size() > 1:
			var hb := Button.new()
			hb.theme_type_variation = "SmallButton"
			hb.toggle_mode = true
			hb.flat = true
			hb.focus_mode = Control.FOCUS_NONE
			hb.alignment = HORIZONTAL_ALIGNMENT_LEFT
			hb.clip_text = true
			var title := "%s (можно %d из %d)" % [gname, ok_n, lst.size()]
			hb.text = ("▾ " if open else "▸ ") + title
			hb.set_pressed_no_signal(open)
			hb.add_theme_color_override("font_color", C_ACCENT.lightened(0.2))
			hb.toggled.connect(func(on: bool) -> void:
				fn_open[okey] = on
				hb.text = ("▾ " if on else "▸ ") + title
				cont.visible = on)
			box.add_child(hb)
		else:
			open = true
		cont.visible = open
		box.add_child(cont)
		for a in lst:
			fn_act_button(cont, a, block)
	polish_tree(box)


func fn_act_button(parent: Control, a: Dictionary, block: String) -> void:
	var id: String = String(a["id"])
	var cap: float = float(a.get("cap", 0.0))
	var why: String = block if block != "" else String(a["why"])
	var ok: bool = bool(a["ok"]) and block == ""
	var txt: String = String(a["name"]) + ((" (%.0f)" % cap) if cap > 0.0 else "")
	if not ok and why != "":
		txt += " · " + why
	var tip: String = String(a.get("desc", "")).replace("%%", "%")
	tip += ("\n\nЦена: %.0f политического капитала." % cap) if cap > 0.0 else "\n\nБесплатно."
	if not ok and why != "":
		tip += "\nСейчас нельзя: %s." % why
	var b := make_button(txt, parent)
	b.theme_type_variation = "SmallButton"
	b.tooltip_text = tip
	b.disabled = not ok
	b.pressed.connect(func() -> void:
		var done: bool = fin_do(id)
		sfx("good" if done else "bad")
		refresh())


# ============================================================
#  ОБНОВЛЕНИЕ
# ============================================================
func update_fin_windows() -> void:
	if fn_off_rt == null:
		return
	var on: bool = fin_on()
	fn_off_rt.visible = not on
	for k in fn_box:
		(fn_box[k] as Control).visible = on
	if not on:
		fn_off_rt.text = "[color=%s]Финансовый модуль выключен.[/color]" % COL_DIM
		return
	fn_upd_sum()
	fn_upd_cb()
	fn_upd_bank()
	fn_upd_ex()
	fn_upd_debt()
	fn_upd_fund()
	fn_upd_sparks()
	var cbfx: Array = fin_acts("cb")
	cbfx.append_array(fin_acts("fx"))
	var uni: bool = String(fin["fx"]["reg"]) == "euro" and not fin_euro_member()
	fn_acts_update("cbfx", cbfx, "Своей валюты и своего центробанка нет: страна пользуется евро без членства в еврозоне. Курс и ставку задаёт ЕЦБ." if uni else "Действий нет.")
	fn_acts_update("bank", fin_acts("bank"), "Действий нет.")
	fn_acts_update("ex", fin_acts("ex"), "Действий нет.")
	fn_acts_update("debt", fin_acts("debt"), "Действий нет.")
	fn_acts_update("fund", fin_acts("fund"), "Действий нет.")


# цвет доверия рынков (как на плашке вверху): от 60 — хорошо, от 40 — тревожно, ниже — плохо
func fn_mood_col() -> String:
	var m: float = float(fin["mood"])
	return COL_GOOD if m >= 60.0 else (COL_WARN if m >= 40.0 else COL_BAD)


func fn_cur_name(anc: String) -> String:
	return "евро" if anc == "EUR" else ("доллару" if anc == "USD" else anc)


# режим курса простыми словами
func fn_reg_text() -> String:
	var f: Dictionary = fin["fx"]
	var reg: String = String(f["reg"])
	match reg:
		"euro":
			return "евро (общая валюта еврозоны)" if fin_euro_member() else "евро без членства в еврозоне: своей валюты нет"
		"float":
			return "плавающий: курс задаёт рынок"
		"peg":
			return "привязка к %s ±%.1f%%, центр %.0f" % [fn_cur_name(String(f["anc"])), float(f["band"]) * 100.0, float(f["lvl"]) * 100.0]
		"corr":
			return "коридор ±%.0f%% к %s, центр %.0f" % [float(f["band"]) * 100.0, fn_cur_name(String(f["anc"])), float(f["lvl"]) * 100.0]
	return reg


func fn_reg_short() -> String:
	match String(fin["fx"]["reg"]):
		"euro":
			return "евро"
		"float":
			return "плавающий"
		"peg":
			return "привязка к %s" % fn_cur_name(String(fin["fx"]["anc"]))
		"corr":
			return "коридор к %s" % fn_cur_name(String(fin["fx"]["anc"]))
	return ""


# изменение показателя истории fin["h"] за 12 месяцев (или с начала истории)
func fn_h_change(k: String) -> float:
	var a: Array = fin["h"].get(k, [])
	if a.size() < 2:
		return 0.0
	var ago: float = float(a[maxi(0, a.size() - 13)])
	return (float(a[a.size() - 1]) / maxf(0.0001, ago) - 1.0) * 100.0


func fn_debt_ratio() -> float:
	return debt / maxf(gdp, 1.0) * 100.0


func fn_upd_sum() -> void:
	var mood: float = float(fin["mood"])
	set_bar("fn_mood", mood)
	(bars["fn_mood"]["val"] as Label).add_theme_color_override("font_color", Color(fn_mood_col()))
	var euro: bool = fin_euro_member() or String(fin["fx"]["reg"]) == "euro"
	var fxs: float = float(ec["fxs"])
	var fx12: float = (fxs / maxf(0.0001, float(h12_ago("fxs", fxs))) - 1.0) * 100.0
	var db: Dictionary = fin["db"]
	var b: Dictionary = fin["bk"]
	var cris: Dictionary = b["cris"]
	var l: PackedStringArray = []
	l.append("Настроение рынков: [color=%s][b]%s[/b][/color]" % [fn_mood_col(), fin_mood_text()])
	l.append("Ставка: [b]%.2f%%[/b]%s   Инфляция: [b]%.1f%%[/b]" % [float(ec["rate"]), " (ЕЦБ)" if euro else "", inflation])
	l.append("Курс: [b]%.0f[/b] (%s [color=%s]%s%%[/color]), %s" % [fxs * 100.0, h12_label("fxs"), COL_BAD if fx12 < -5.0 else (COL_WARN if fx12 < -2.0 else COL_DIM), sg(fx12, 1), fn_reg_short()])
	l.append("Резервы: [color=%s][b]%.1f%%[/b][/color] ВВП   Долг: [b]%.0f%%[/b] ВВП" % [fin_col(float(ec["res"]), 3.0, 8.0, true), float(ec["res"]), fn_debt_ratio()])
	l.append("Спред по долгу: [color=%s][b]%s п.п.[/b][/color]" % [fin_col(float(db["spr"]), 2.0, 5.0, false), sg(float(db["spr"]), 1)])
	if bool(cris["on"]):
		l.append("[color=%s][b]Банковский кризис[/b][/color]: %s, тяжесть %d из 3" % [COL_BAD, String(FIN_CRIS[String(cris["kind"])]["n"]), int(round(float(cris["sev"])))])
	else:
		l.append("Банки: [color=%s]кризиса нет[/color], капитал %.1f%%" % [fin_col(float(b["car"]), 10.0, 14.0, true), float(b["car"])])
	if int(db["closed_t"]) > turn:
		l.append(hint_line(false, "Рынки займов закрыты ещё %d мес.: дефицит покрывают фонды, резервы и печатный станок." % (int(db["closed_t"]) - turn)))
	if float(fin["w"]["shock"]) > 0.2:
		l.append(hint_line(false, "На мировых рынках паника: деньги уходят от риска, займы дорожают."))
	if int(fin["imf"]["st"]) == 2:
		l.append(hint_line(true, "Идёт программа МВФ: рынки спокойнее, но нужно выполнять условия."))
	var m: PackedStringArray = []
	m.append("[color=%s]Доверие рынков (%.0f из 100) растёт, когда экономика растёт, инфляция и дефицит невелики, долг умеренный, а центробанку верят. Высокое доверие удешевляет займы и поддерживает биржу и курс, паника делает всё наоборот.[/color]" % [COL_DIM, mood])
	fn_set_text("sum", l, m)
	# журнал финансов: последние сверху
	var lg: Array = fin["log"]
	var ll: PackedStringArray = []
	for i in range(lg.size() - 1, maxi(-1, lg.size() - 16), -1):
		var e: Dictionary = lg[i]
		ll.append("[color=%s]●[/color] [color=%s]%s, %s:[/color] %s" % [String(e.get("c", COL_DIM)), COL_DIM, String(e.get("d", "")), String(e.get("s", "")), String(e.get("t", ""))])
	if ll.is_empty():
		ll.append("[color=%s]Пока ничего не случилось.[/color]" % COL_DIM)
	set_tail_text(fn_rt["log"], "\n".join(ll), 3)


func fn_upd_cb() -> void:
	var cb: Dictionary = fin["cb"]
	var f: Dictionary = fin["fx"]
	var euro: bool = fin_euro_member()
	var uni: bool = String(f["reg"]) == "euro" and not euro
	var reg: String = String(f["reg"])
	set_bar("fn_ind", float(cb["ind"]))
	set_bar("fn_cred", float(cb["cred"]))
	(bars["fn_ind"]["row"] as Control).visible = not euro and not uni
	var l: PackedStringArray = []     # видно сразу
	var m: PackedStringArray = []     # «Подробнее»
	if euro:
		l.append("Ставку [b]%.2f%%[/b] задаёт ЕЦБ для всей еврозоны (инфляция там %.1f%%). Ваш голос в нём невелик." % [float(ec["rate"]), ea_infl])
		if absf(float(cb["lobby"])) > 0.02:
			l.append("Ваше лоббирование сдвигает ставку на %s п.п." % sg(float(cb["lobby"]), 2))
	elif uni:
		l.append("Своего центробанка нет: страна пользуется евро без членства в еврозоне. Ставка [b]%.2f%%[/b] следует за ЕЦБ." % float(ec["rate"]))
	else:
		l.append("Ключевая ставка: [b]%.2f%%[/b] (по правилу %.1f%%)" % [float(ec["rate"]), float(ec["rate_goal"])])
		if float(cb["qe"]) > 0.0:
			l.append("ЦБ держит облигаций государства на [color=%s]%.0f%% ВВП[/color]: проценты по долгу ниже, но растут инфляция и недоверие." % [COL_WARN, float(cb["qe"])])
		if float(cb["ind"]) < 60.0:
			l.append(hint_line(false, "ЦБ зависим от власти: можно печатать деньги на дефицит, но ему верят меньше."))
	l.append("[b]Курс[/b]: %.0f, %s" % [float(ec["fxs"]) * 100.0, fn_reg_text()])
	if reg == "peg" or reg == "corr":
		var press: float = float(f["press"]) * 100.0
		if press < -0.3:
			l.append(hint_line(false, "Курс давят вниз на %.1f%%: ЦБ тратит резервы, чтобы удержать привязку." % absf(press)))
		elif press > 0.3:
			l.append(hint_line(true, "Валюту покупают: резервы растут."))
	l.append("Резервы: [color=%s][b]%.1f%%[/b][/color] ВВП%s" % [fin_col(float(ec["res"]), 3.0, 8.0, true), float(ec["res"]),
		(", своп-линия %.0f%% ВВП (%s, ещё %s)" % [float(f["swap"]), String(f["swap_by"]), months_text(maxi(0, int(f["swap_t"]) - turn))]) if float(f["swap"]) > 0.0 else ""])
	if bool(f["capctl"]):
		l.append(hint_line(false, "Введён контроль капитала: вывоз денег ограничен, инвесторы осторожнее."))
	# подробнее
	if not euro and not uni:
		var since: int = turn - int(cb["head_t"])
		var left: int = 96 - since
		m.append("Глава ЦБ: [b]%s[/b], %s. %s" % [String(FIN_HEAD[String(cb["head"])]["n"]), ("на посту %s" % months_text(since)) if since > 0 else "назначен в этом месяце", ("Срок истекает через %s." % months_text(left)) if left > 0 else "Срок истёк: можно назначить нового."])
		if absf(float(cb["press"])) > 0.05:
			m.append("Давление власти на ставку: %s п.п." % sg(float(cb["press"]), 1))
	if not euro and (String(f["anc"]) == "EUR" or (not rl.is_empty() and bool(rl["b"]["eu"]))):
		m.append("Путь к евро: %s." % fin_erm_text())
	m.append("Контроль капитала: %s" % ("введён" if bool(f["capctl"]) else "нет"))
	m.append("Резервы: золото %.0f%%%s, евро %.0f%%, доллар %.0f%%, юань %.0f%%. Золото защищает в кризис, но его цена колеблется." % [float(f["gold"]), fin_est_note("gold"), float(f["mix_eur"]), float(f["mix_usd"]), float(f["mix_cny"])])
	var w: Dictionary = fin["w"]
	m.append("Мировые цены: золото %.0f, доллар %.0f (обычный уровень 100)%s" % [float(w["gold"]) * 100.0, float(w["usd"]) * 100.0, (", [color=%s]мировой шок %.0f%%[/color]" % [COL_BAD, float(w["shock"]) * 100.0]) if float(w["shock"]) > 0.05 else ""])
	fn_set_text("cb", l, m)


# голова видна всегда, остальное в сворачиваемом «Подробнее»
func fn_set_text(key: String, head: PackedStringArray, more: PackedStringArray) -> void:
	var all: PackedStringArray = head.duplicate()
	all.append_array(more)
	set_tail_text(fn_rt[key], "\n".join(all), head.size())


func fn_upd_bank() -> void:
	var b: Dictionary = fin["bk"]
	var cris: Dictionary = b["cris"]
	set_bar("fn_trust", float(b["trust"]))
	var l: PackedStringArray = []
	var m: PackedStringArray = []
	if bool(cris["on"]):
		var kind: String = String(cris["kind"])
		l.append("[color=%s][b]Банковский кризис: %s[/b][/color], тяжесть %d из 3, ещё около %s." % [COL_BAD, String(FIN_CRIS[kind]["n"]), int(round(float(cris["sev"]))), months_text(maxi(1, int(ceil(float(cris["left"])))))])
		l.append(String(FIN_CRIS[kind]["t"]))
		if bool(cris.get("wait_on", false)):
			l.append(hint_line(false, "Власть выжидает: кризис углубляется."))
		elif not bool(cris.get("decided", false)):
			l.append(hint_line(false, "Решение по кризису ещё не принято: выберите меру в группе «Кризис»."))
	var car: float = float(b["car"])
	var cr0: float = float(b["cr0"])
	l.append("Капитал банков: [color=%s][b]%.1f%%[/b][/color]%s (норма от 12%%)" % [fin_col(car, 10.0, 14.0, true), car, fin_est_note("car")])
	l.append("Плохие кредиты: [color=%s][b]%.1f%%[/b][/color]%s" % [fin_col(float(b["npl"]), 4.0, 10.0, false), float(b["npl"]), fin_est_note("npl")])
	var bub: float = maxf(float(b["bub_h"]), float(b["bub_c"]))
	var bub_l: String = "Пузыри: жильё [color=%s]%.0f[/color], кредит [color=%s]%.0f[/color] из 100 (опасно от 70)" % [fin_col(float(b["bub_h"]), 40.0, 70.0, false), float(b["bub_h"]), fin_col(float(b["bub_c"]), 40.0, 70.0, false), float(b["bub_c"])]
	if bub >= 40.0:
		l.append(bub_l)
	if float(b["crunch"]) > 0.05:
		l.append(hint_line(false, "Банки почти не дают кредитов (сжатие %.0f%%): бизнесу не на что расширяться." % (float(b["crunch"]) * 100.0)))
	m.append("Кредит экономике: [b]%.0f%%[/b] ВВП%s (%s%% к началу игры)" % [float(b["cr"]), fin_est_note("cr"), sg((float(b["cr"]) / maxf(1.0, cr0) - 1.0) * 100.0, 0)])
	if bub < 40.0:
		m.append(bub_l)
	m.append("Страхование вкладов: %s. Надзор: %s." % [FN_INS_NAMES[clampi(int(b["ins"]), 0, 2)], FN_REG_NAMES[clampi(int(b["reg"]), 0, 3)]])
	if float(b["state"]) > 0.5:
		m.append("Банки под контролем государства: %.0f%%" % float(b["state"]))
	if int(b["stress_t"]) > -999:
		var sh: float = float(b.get("stress_short", 0.0))
		var sago: int = turn - int(b["stress_t"])
		m.append("Стресс-тест %s: %s" % [("%s назад" % months_text(sago)) if sago > 0 else "в этом месяце", ("нехватка капитала %.2f%% ВВП" % sh) if sh > 0.0 else "пройден"])
	m.append("Кризисов за игру: %d." % int(b["count"]))
	m.append("[color=%s]Кризис вероятнее, когда раздуты пузыри, у банков мало капитала и много плохих кредитов, ставки резко выросли, госдолг дешевеет или на мировых рынках паника. Пузыри растут от дешёвых денег и быстрого роста кредита, строгий надзор их сдерживает.[/color]" % COL_DIM)
	fn_set_text("bank", l, m)


func fn_upd_ex() -> void:
	var ex: Dictionary = fin["ex"]
	var l: PackedStringArray = []
	var m: PackedStringArray = []
	var ch: float = fn_h_change("idx")
	l.append("Индекс: [b]%.0f[/b] (в начале игры 100), %s [color=%s]%s%%[/color]" % [float(ex["idx"]), "за 12 мес." if (fin["h"]["idx"] as Array).size() >= 13 else "с начала", COL_GOOD if ch > 0.0 else (COL_BAD if ch < -10.0 else COL_DIM), sg(ch, 0)])
	l.append("Перегрев: [color=%s][b]%.0f[/b][/color] из 100 (обвал вероятен от 70)" % [fin_col(float(ex["bub"]), 40.0, 70.0, false), float(ex["bub"])])
	if float(ex["closed"]) > 0.0:
		l.append(hint_line(false, "Биржа закрыта ещё %s." % months_text(maxi(1, int(ceil(float(ex["closed"])))))))
	m.append("Стоимость компаний на бирже: %.0f%% ВВП%s" % [float(ex["mcap"]), fin_est_note("mcap")])
	m.append("Налог на сделки: %.1f%%%s" % [float(ex["tax"]), (" (≈%.2f%% ВВП в год)" % (fin_tx_rev() * 100.0)) if float(ex["tax"]) > 0.0 else ""])
	m.append("Ограничения спекуляций: %s" % ("есть" if bool(ex["restr"]) else "нет"))
	if float(ex["ipo"]) > 0.0:
		m.append("Продано госкомпаний на бирже: %.1f%% ВВП" % float(ex["ipo"]))
	fn_set_text("ex", l, m)


func fn_upd_debt() -> void:
	var db: Dictionary = fin["db"]
	var imf: Dictionary = fin["imf"]
	var l: PackedStringArray = []
	var m: PackedStringArray = []
	var ratio: float = fn_debt_ratio()
	l.append("Госдолг: [b]%.0f%%[/b] ВВП, для рынков %.0f%%" % [ratio, fin_ratio_net()])
	l.append("Средняя ставка: [b]%.2f%%[/b]   Спред: [color=%s][b]%s п.п.[/b][/color]" % [float(db["avg"]) * 100.0, fin_col(float(db["spr"]), 2.0, 5.0, false), sg(float(db["spr"]), 1)])
	var closed: bool = int(db["closed_t"]) > turn
	if closed:
		l.append(hint_line(false, "Рынки займов закрыты ещё %s." % months_text(int(db["closed_t"]) - turn)))
	else:
		l.append("Рынки займов: [color=%s]открыты[/color]" % COL_GOOD)
	if int(db["ds"]) > 0:
		var ago: int = turn - int(db["ds_t"])
		l.append("[color=%s]%s %s: списано %.0f%% долга.[/color]" % [COL_WARN, "Полный дефолт" if int(db["ds"]) >= 2 else "Реструктуризация долга", ("%s назад" % months_text(ago)) if ago > 0 else "в этом месяце", float(db["haircut"]) * 100.0])
	if bool(db["pend"]):
		l.append(hint_line(false, "Долговой кризис ждёт вашего решения."))
	var st: int = int(imf["st"])
	if st == 2:
		var it: String = fin_imf_text().strip_edges()
		for ln in it.replace("✓", "[color=%s]✓[/color]" % COL_GOOD).replace("✗", "[color=%s]✗[/color]" % COL_BAD).split("\n"):
			l.append(ln)
	m.append("Рыночная ставка: %.2f%%. Срок долга: %.1f лет%s" % [float(db["mkt"]) * 100.0, float(db["mat"]), fin_est_note("mat")])
	m.append("У иностранцев: %.0f%%%s   В валюте: [color=%s]%.0f%%[/color]%s" % [float(db["for"]), fin_est_note("for"), fin_col(float(db["fcur"]), 20.0, 50.0, false), float(db["fcur"]), fin_est_note("fcur")])
	m.append("Последний аукцион: спрос в [color=%s]%.1f[/color] раза выше предложения (ниже 1 значит провал), ставка %.2f%%" % [fin_col(float(db["cover"]), 1.2, 2.0, true), float(db["cover"]), float(db["auc_rate"]) * 100.0])
	if float(db.get("printed", 0.0)) > 0.0:
		m.append("Напечатано денег на дефицит: %.1f%% ВВП" % float(db["printed"]))
	if st != 2:
		m.append("МВФ: %s" % ("программы нет" if st == 0 else "программы нет (отказ или срыв)"))
	m.append("[color=%s]МВФ даёт деньги траншами раз в три месяца, если условия выполняются; дважды сорванные условия прекращают программу. Дефолт не конец игры, но рынки закрываются на годы.[/color]" % COL_DIM)
	fn_set_text("debt", l, m)


func fn_upd_fund() -> void:
	var f: Dictionary = fin["fd"]
	var rules: Dictionary = f["rules"]
	var l: PackedStringArray = []
	l.append("Всего в фондах: [b]%.1f%%[/b] ВВП" % fin_fund_total())
	for k in ["res", "pen", "own"]:
		if k == "own" and not bool(f["own_on"]):
			continue
		var r: Dictionary = rules[k]
		var v: float = float(f[k])
		if v <= 0.0 and float(r["in_s"]) <= 0.0 and float(r["in_fix"]) <= 0.0 and k != "own":
			continue
		l.append("[b]%s[/b]: %.1f%% ВВП" % [FN_FUND_NAMES[k], v])
		l.append("  взнос: %.0f%% профицита + %.1f%% ВВП в год, траты: %s" % [float(r["in_s"]), float(r["in_fix"]), String(FN_OUT_NAMES.get(String(r["out"]), String(r["out"])))])
	if fin_fund_total() <= 0.0 and not bool(f["own_on"]):
		l.append("[color=%s]Фондов пока нет. Можно создать свой и копить в хорошие годы.[/color]" % COL_DIM)
	var m: PackedStringArray = ["[color=%s]Суверенные фонды: запас на чёрный день. Рынки считают половину их суммы подушкой и меньше боятся долга. Правило трат решает, когда фонд сам покрывает дефицит. Если рынки закрыты, дефицит сначала покрывают фонды.[/color]" % COL_DIM]
	fn_set_text("fund", l, m)


func fn_upd_sparks() -> void:
	var h: Dictionary = fin["h"]
	for k in fn_sparks:
		var sp: Control = fn_sparks[k][0]
		if not sp.is_visible_in_tree():
			continue
		var arr: Array = h.get(k, [])
		sp.set("title", String(fn_sparks[k][1]))
		sp.set("series", [{"v": arr.duplicate(), "c": FN_SPARK_COL.get(k, C_ACCENT), "n": ""}])
		sp.queue_redraw()


# ============================================================
#  ОКНА ВЫБОРА (special == "fin"): последствия вариантов словами
# ============================================================
const FN_EV_DESC := {
	"bk_wait": "Бюджет не тратится, но кризис может углубиться: тяжесть растёт, и он длится дольше.",
	"dflt_restr": "Долг уменьшится на четверть по договорённости с кредиторами. Рынки займов закроются примерно на полтора года, доверие упадёт. Затем МВФ предложит программу.",
	"dflt_part": "Долг уменьшится на 15%. Рынки займов закроются на 1–2 года, доверие и рейтинг упадут. Затем МВФ предложит программу.",
	"dflt_full": "Долг уменьшится вдвое. Но рынки закроются на 2,5–4 года, доверие рухнет, банки потеряют на облигациях, рейтинг и отношения с другими странами пострадают.",
	"dflt_imf": "МВФ предложит кредит в обмен на условия: сократить дефицит и провести реформы.",
	"dflt_pay": "Расходы урезаются: рост ниже, все группы недовольны, зато рынки немного успокаиваются.",
	"imf_yes": "Деньги приходят траншами раз в три месяца, рынки успокаиваются, ставки по долгу ниже. Условия проверяются: если дважды не выполнить, программа прекратится.",
	"imf_cn": "Резервы сразу растут на 4% ВВП, но долг дорогой (6%), часть его в валюте, а отношения с Западом ухудшатся.",
	"imf_ally": "Резервы растут на 2,5% ВВП, заём дешёвый (2%) и без условий.",
	"imf_no": "Никаких условий, но и денег нет: справляться придётся самим.",
	"head_tech": "Ставка строго по правилу, доверие к центробанку растёт.",
	"head_hawk": "Ставка выше правила: инфляция ниже, кредит дороже, доверие к центробанку растёт.",
	"head_dove": "Ставка ниже правила: кредит дешевле, но инфляция опаснее и доверие к центробанку падает.",
	"head_keep": "Прежний глава остаётся ещё на несколько лет.",
}


# описание варианта окна финансов: своё (FN_EV_DESC) или подсказка того же действия на вкладке «Финансы»
func fin_opt_desc(act: String) -> String:
	if FN_EV_DESC.has(act):
		return String(FN_EV_DESC[act])
	if not fin_on():
		return ""
	for pg in FIN_PAGES:
		for a in fin_acts(pg):
			if String(a["id"]) == act:
				return String(a.get("desc", "")).replace("%%", "%")
	return ""


# ============================================================
#  ПЛАШКИ ВВЕРХУ: курс, ставка, доверие рынков (вызывается из update_chips_extra)
# ============================================================
func fin_chips_update() -> void:
	if chips.is_empty() or not chips.has("fmood"):
		return
	var on: bool = fin_on() and not ec.is_empty()
	(chips["frate"]["pc"] as Control).visible = on
	(chips["fmood"]["pc"] as Control).visible = on
	# плашка курса: при включённых финансах — уровень курса, а изменение за 12 месяцев мелко рядом
	var cap_l := ((chips["fxs"]["pc"] as Control).get_child(0) as VBoxContainer).get_child(0) as Label
	cap_l.text = "КУРС" if on else "КУРС, 12 М"
	if not on:
		return
	var fxs: float = float(ec["fxs"])
	var ch: float = (fxs / maxf(0.0001, float(h12_ago("fxs", fxs))) - 1.0) * 100.0
	set_chip("fxs", "%.0f" % (fxs * 100.0), C_BAD if ch < -8.0 else (C_WARN if ch < -3.0 else C_TEXT), "%s%%" % sg(ch, 1), C_BAD if ch < -3.0 else C_DIM)
	(chips["fxs"]["pc"] as Control).tooltip_text = tip_make("Курс валюты", [["Сейчас", "%.0f (в начале игры 100), %s %s%%" % [fxs * 100.0, h12_label("fxs"), sg(ch, 1)]],
		["Режим", fn_reg_text()], ["Резервы", "%.1f%% ВВП" % float(ec["res"])], ["Куда нажать", "Экономика → «Финансы»"]])
	var rate: float = float(ec["rate"])
	var euro: bool = fin_euro_member() or String(fin["fx"]["reg"]) == "euro"
	var rh: Array = fin["h"]["rate"]
	var dr: float = rate - float(rh[rh.size() - 1]) if rh.size() > 0 else 0.0
	set_chip_num("frate", rate, func(x: float) -> String: return "%.2f%%" % x, C_TEXT, arrow_text(dr, 2), C_DIM)
	(chips["frate"]["pc"] as Control).tooltip_text = tip_make("Ключевая ставка", [["Сейчас", "%.2f%%, инфляция %.1f%%" % [rate, inflation]],
		["Кто задаёт", "ЕЦБ для всей еврозоны" if euro else "центробанк страны (глава: %s, независимость %.0f из 100)" % [String(FIN_HEAD[String(fin["cb"]["head"])]["n"]), float(fin["cb"]["ind"])]],
		["Что значит", "Высокая ставка сдерживает инфляцию и держит курс, но удорожает кредиты и тормозит рост."], ["Куда нажать", "Экономика → «Финансы»"]])
	var mood: float = float(fin["mood"])
	var mh: Array = fin["h"]["mood"]
	var dm: float = mood - float(mh[mh.size() - 1]) if mh.size() > 0 else 0.0
	set_chip_num("fmood", mood, func(x: float) -> String: return "%.0f" % x, Color(fn_mood_col()), arrow_text(dm, 0), delta_col(dm, true))
	(chips["fmood"]["pc"] as Control).tooltip_text = tip_make("Доверие рынков", [["Сейчас", "%.0f из 100, %s" % [mood, fin_mood_text()]],
		["Что значит", "Насколько инвесторы верят стране. От него зависят ставки по долгу, курс, биржа и риск кризиса."],
		["Что влияет", "рост экономики, инфляция, дефицит и долг, доверие к центробанку, кризисы банков"], ["Куда нажать", "Экономика → «Финансы»"]])
