# 0.57: навигация. Кнопки «?» и «★» в окнах, закладки, раскладки окон (плиткой, готовые наборы, «своя»), меню «Ещё»,
# люди и действия в поиске Ctrl+K.
extends "res://scripts/ui/ui_notify.gd"

const WIN_HELP := {
	"td_todo": "Здесь всё, что ждёт вашего решения: событие, коалиция, бюджет, письма во «Входящих». Если список пуст, можно пускать время.",
	"td_prob": "Три самые острые проблемы страны по важности. Остальные спрятаны в свёртке. Нажмите на проблему в списке, чтобы перейти к нужному окну.",
	"td_dates": "Ближайшие выборы, итоги года и стройки. Даты на три месяца вперёд.",
	"td_nums": "Главные числа и их изменение к прошлому месяцу. Наведите мышь на число вверху: появится объяснение и график за 12 месяцев.",
	"td_act": "Частые переходы и ваши закладки (★). Закладку ставит звёздочка в заголовке любого окна.",
	"tax": "Налоги и расходы. Ползунки задают план бюджета: он вступает в силу только после «Принять бюджет». Расходы сгруппированы по сферам. Пока двигаете ползунки, наверху видно, что будет с дефицитом и долгом, кому план выгоден и поддержит ли его коалиция.",
	"forecast": "Откуда приходят деньги и куда уходят. Тонкая штриховка показывает разницу между действующим бюджетом и планом.",
	"economy": "Состояние государства: образование, здоровье, безопасность, инфраструктура, экология, равенство, коррупция. Каждая шкала отражает ваши расходы и законы.",
	"groups": "Социальные группы и их поддержка власти. Рейтинг считается как сумма с учётом размера групп. Недовольная группа может выйти на улицу.",
	"measures": "Советник и разовые меры: быстрые шаги за счёт резерва бюджета. Подсказки «что сейчас важно» показывают самые острые проблемы.",
	"parliament": "Зал парламента: места партий, коалиция и глава государства. Здесь видно, хватает ли у правительства большинства.",
	"parties": "Список партий. Нажмите на название, чтобы увидеть программу, требования и отношение к вам.",
	"polls": "Опросы и выборы. Перед выборами опросы становятся подробнее. Следите за рейтингом и за тем, кто растёт.",
	"actions": "Политические действия за политический капитал: от переговоров до жёстких мер. Дорогие действия лучше планировать заранее.",
	"laws_list": "Законы по сферам. Выберите тему, затем вариант закона. Внесение стоит политического капитала и требует голосов в парламенте.",
	"law_detail": "Подробности закона: что изменится, кто за и против, во что обойдётся. «Было → станет» показывает три главные цифры.",
	"law_votes": "Прогноз голосования: кто поддержит, кто нет. Здесь же видно, какие поправки могут изменить расклад.",
	"bills": "Законопроекты в работе. Можно просить поправки у партий и следить за сроками голосования.",
	"laws_effects": "Итог всех действующих законов: что они дают бюджету, группам и показателям.",
	"cabinet": "Кабинет министров: кто какое министерство занимает. Министерства можно перераспределять между партиями коалиции.",
	"coal_sum": "Коалиция: партнёры, их доля мест и настроение. Недовольные партнёры могут выйти из коалиции.",
	"commit": "Обязательства перед партнёрами и предложения министров. Срочные требования — наверху.",
	"neg": "Переговоры с партией: что она требует и что готова дать. Помогает собрать большинство.",
	"ec_mk": "Рынки: спрос, предложение и цены по отраслям. Дефицит — повод строить новые мощности.",
	"ec_bz": "Деловой климат и инвестиции. Список причин показывает, что сильнее всего толкает климат вверх или вниз.",
	"ec_st": "Сооружения страны: электростанции, заводы, дороги. Каждое даёт мощности и стоит денег на содержание.",
	"ec_cb": "Центральный банк: ключевая ставка, эмиссия и курс валюты. Ставка и пошлины меняются вручную.",
	"ec_gf": "Торговля и единый рынок: пошлины, обмен с партнёрами и ограничения.",
	"ec_pp": "Покупательная способность населения: сколько товаров можно купить на доход.",
	"map": "Карта: слои и масштаб. Слои можно переключать готовыми наборами; регион выбирается щелчком.",
	"region": "Выбранный регион: население, настроение, экономика, автономия и действия.",
	"regtable": "Сводка по всем регионам. Нажмите на заголовок столбца, чтобы отсортировать.",
	"regact": "Действия и трансферты выбранного региона. Можно применять к нескольким регионам сразу.",
	"dinfo": "Страна: сведения. Отношения, торговля, договоры и возможные действия.",
	"dact": "Действия с выбранной страной: переговоры, помощь, санкции и многое другое.",
	"io_info": "Что даёт и чего требует организация. Здесь же видно, как вы голосуете в организации.",
	"io_act": "Действия внутри организации: заявки, голосование, взносы.",
	"war_ops": "Война и мир: фронт, приказы, снабжение. Мирный договор оформляется по шагам.",
	"war_army": "Армия: состав, боеготовность, снабжение. Приказы по секторам.",
	"ar_budget": "Оборонный бюджет и закупки. Больше расходов даёт больше армии, но давит на бюджет.",
	"pop_demo": "Демография: пирамида возрастов. Старение влияет на пенсии и рынок труда.",
	"pop_regions": "Протестные настроения по регионам. Красный цвет означает риск волнений.",
	"es_main": "Пульт управления экономикой: правила автоматики, ставка, пошлины и меры.",
	"log": "Журнал: события и итоги по месяцам. Фильтры сверху оставляют только нужные темы. Одинаковые записи склеиваются.",
}


const GLOSSARY := {
	"Политический капитал": "Ресурс решений. Растёт каждый месяц от рейтинга и коалиции. Тратится на законы, реформы и дорогие варианты событий. Ниже нуля растёт риск отставки.",
	"Рейтинг власти": "Доля довольных вашей работой, от 0 до 100. Складывается из настроения социальных групп с учётом их размера. Ниже 50% выборы под угрозой.",
	"Дефицит бюджета": "На сколько расходы больше доходов, в процентах ВВП. Дефицит копится в долг. Выше 6% ВВП рынки начинают тревожиться.",
	"Госдолг": "Накопленные долги государства в процентах годового ВВП. Выше 90–100% кредиторы требуют больше процентов.",
	"Инфляция": "На сколько дорожают цены за год. Её разгоняют эмиссия, слабая валюта и дорогая энергия. Выше 5–6% бьёт по рейтингу.",
	"Безработица": "Доля людей без работы. Растёт при спаде экономики, падает при росте и субсидиях.",
	"Коалиция": "Союз партий, у которого больше половины мест. Без большинства правительство не работает, а недовольные партнёры могут уйти.",
	"Вотум недоверия": "Голосование, которым парламент может отправить правительство в отставку. Опасен при шаткой коалиции и низком рейтинге.",
	"Резервы": "Запас валюты и золота в процентах ВВП. Помогает держать курс валюты в трудные месяцы.",
	"Ключевая ставка": "Цена кредита в экономике. Выше ставка: меньше инфляция, но слабее инвестиции. Меняется вручную в центральном банке.",
	"Пошлины": "Налоги на ввоз товаров. Защищают местных производителей, но дорожают импорт и вызывают ответные меры.",
	"Эмиссия": "Печать денег для бюджета. Пока она ниже безопасного предела, инфляция почти не растёт. В еврозоне эмиссии нет: деньги печатает ЕЦБ.",
	"Автономия региона": "Доля полномочий, которую регион решает сам. Больше автономии снижает сепаратизм, но ослабляет центр.",
	"Сепаратизм": "Желание региона отделиться. Падает от диалога, автономии и денег; растёт от репрессий и бедности.",
	"Трансферты регионам": "Деньги из центра регионам. Идут через план бюджета и вступают в силу после «Принять бюджет».",
	"Санкции": "Торговые и финансовые ограничения против страны. Бьют по экономике обеих сторон, их сложно снять.",
	"Законопроект": "Закон на пути к голосованию. Внесение стоит политического капитала, голосование проходит через три месяца.",
	"Входящие": "Малые события, которые не останавливают игру. Ответьте сами или оставьте: через три месяца решится по вашим принципам.",
}

var help_ov: Control = null
var help_title: Label = null
var help_rt: RichTextLabel = null
var lay_prev := ""


func win_id_of(w: FloatWindow) -> String:
	for id in wins:
		if wins[id] == w:
			return String(id)
	return ""


# ============================================================
#  «?»: справка по окну
# ============================================================
func win_help_text(id: String) -> String:
	var w: FloatWindow = wins.get(id, null)
	var t := String(WIN_HELP.get(id, ""))
	if t == "":
		t = "Это окно показывает данные раздела. Наведите мышь на любое число или кнопку: появится подсказка."
	t += "\n\n[color=%s]Окно можно двигать за заголовок, менять размер за край, сворачивать «–» и закрывать «×». Закрытые окна возвращаются через кнопку «▦». Звёздочка добавляет окно в закладки. Ctrl+K ищет по всей игре.[/color]" % COL_DIM
	return t


func on_win_help(w: FloatWindow) -> void:
	help_open(win_id_of(w))


func help_open(id: String) -> void:
	if help_ov == null:
		help_build()
	var w: FloatWindow = wins.get(id, null)
	help_title.text = "  %s" % (w.get_title() if w != null else "Справка")
	help_rt.text = "[font_size=15]%s[/font_size]" % win_help_text(id)
	help_ov.visible = true
	help_ov.move_to_front()


func help_term(term: String) -> void:
	if help_ov == null:
		help_build()
	help_title.text = "  %s" % term
	help_rt.text = "[font_size=16]%s[/font_size]" % String(GLOSSARY.get(term, ""))
	help_ov.visible = true
	help_ov.move_to_front()


func help_build() -> void:
	help_ov = Control.new()
	help_ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	help_ov.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(help_ov)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		var mb := ev as InputEventMouseButton
		if mb != null and mb.pressed:
			help_ov.visible = false)
	help_ov.add_child(dim)
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", sbox(C_PANEL, C_ACCENT.darkened(0.2), 2, 12, 16.0, 12.0))
	pan.anchor_left = 0.5
	pan.anchor_right = 0.5
	pan.anchor_top = 0.5
	pan.anchor_bottom = 0.5
	pan.offset_left = -300.0
	pan.offset_right = 300.0
	pan.offset_top = -170.0
	pan.offset_bottom = 170.0
	help_ov.add_child(pan)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	pan.add_child(vb)
	var hd := HBoxContainer.new()
	vb.add_child(hd)
	help_title = Label.new()
	help_title.add_theme_font_size_override("font_size", 20)
	help_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hd.add_child(help_title)
	var cl := Button.new()
	cl.text = "✕"
	cl.focus_mode = Control.FOCUS_NONE
	cl.pressed.connect(func() -> void: help_ov.visible = false)
	hd.add_child(cl)
	help_rt = RichTextLabel.new()
	help_rt.bbcode_enabled = true
	help_rt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(help_rt)
	help_ov.visible = false


# ============================================================
#  Закладки: окна, показатели, регионы, страны
# ============================================================
func bm_list() -> Array:
	var a: Variant = game_opts.get("bm", [])
	return a if a is Array else []


func bm_has(key: String) -> bool:
	return bm_list().has(key)


func bm_toggle(key: String) -> void:
	var a: Array = bm_list().duplicate()
	if a.has(key):
		a.erase(key)
	else:
		a.append(key)
	game_opts["bm"] = a
	settings_save()
	td_act_sig = ""
	for id in wins:
		(wins[id] as FloatWindow).set_starred(bm_has("win:" + String(id)))
	refresh()


# звёздочка в заголовке: окно «Регион» и «Страна» запоминают выбранный регион или страну, остальные — само окно
func on_win_star(w: FloatWindow) -> void:
	var id := win_id_of(w)
	if id == "region" and selected_region >= 0:
		bm_toggle("reg:%d" % selected_region)
	elif id == "dinfo" and dip_sel != "":
		bm_toggle("cty:" + dip_sel)
	else:
		bm_toggle("win:" + id)


func bm_entry(key: String) -> Dictionary:
	var kind := key.get_slice(":", 0)
	var arg := key.substr(kind.length() + 1)
	match kind:
		"win":
			if wins.has(arg):
				return {"k": "★ Окно", "t": (wins[arg] as FloatWindow).get_title(), "f": func() -> void: goto_win(arg)}
		"reg":
			var ri := int(arg)
			if ri >= 0 and ri < regions.size():
				return {"k": "★ Регион", "t": String(regions[ri].get("name", "Регион")), "f": func() -> void:
					show_desk(2)
					on_region_picked(ri)}
		"cty":
			if WORLD.has(arg):
				return {"k": "★ Страна", "t": String(WORLD[arg]["name"]), "f": func() -> void:
					show_desk(2)
					dip_sel = arg
					map_mode = "foreign"
					map_apply_mode()
					refresh()}
	return {}


func today_bm_defs() -> Array:
	var out: Array = []
	for key in bm_list():
		var e := bm_entry(String(key))
		if not e.is_empty():
			out.append(["★ " + String(e["t"]), e["f"]])
	return out


func bm_sig() -> String:
	return ",".join(PackedStringArray(bm_list()))


# дополнения поиска Ctrl+K: закладки, люди, раскладки
func srch_extra(out: Array) -> void:
	for key in bm_list():
		var e := bm_entry(String(key))
		if not e.is_empty():
			e["x"] = "закладка избранное"
			out.push_front(e)
	for p in PARTY_LEADERS.size():
		if p >= PARTY_NAMES.size() or String(PARTY_LEADERS[p]) in ["—", ""]:
			continue
		var pj: int = p
		out.append({"k": "Человек", "t": String(PARTY_LEADERS[p]), "x": String(PARTY_NAMES[p]) + " лидер партия", "f": func() -> void:
			show_desk(1)
			selected_party = pj
			refresh()})
	for m in MINISTRIES.size():
		var mj: int = m
		out.append({"k": "Министерство", "t": String(MINISTRIES[m]["name"]), "x": "министр кабинет", "f": func() -> void:
			show_desk(4)
			select_ministry(mj)})
	for term in GLOSSARY:
		var tm: String = String(term)
		out.append({"k": "Справка", "t": tm, "x": "термин что это значит справка", "f": func() -> void: help_term(tm)})
	for pr in LAYOUT_PRESETS:
		var pk: String = String(pr)
		out.append({"k": "Раскладка", "t": String(LAYOUT_PRESETS[pr]["name"]), "x": "окна плитка раскладка", "f": func() -> void: layout_preset(pk)})
	out.append({"k": "Действие", "t": "Автоматика: правила «если — то»", "x": "правила автопилот автоматика", "f": func() -> void: rules_open(true)})
	out.append({"k": "Раскладка", "t": "Расставить окна плиткой", "x": "плитка окна", "f": func() -> void: layout_tile(current_desk)})
	out.append({"k": "Раскладка", "t": "Запомнить раскладку как «Свою»", "x": "своя раскладка сохранить", "f": func() -> void: layout_own_save()})
	out.append({"k": "Раскладка", "t": "Включить «Свою» раскладку", "x": "своя раскладка", "f": func() -> void: layout_own_load()})


# ============================================================
#  Раскладки окон
# ============================================================
const LAYOUT_PRESETS := {
	"budget": {"name": "Бюджетный день", "desk": 0, "ids": ["tax", "forecast", "groups", "economy"]},
	"politics": {"name": "Политический день", "desk": 4, "ids": ["coal_sum", "cabinet", "commit", "neg"]},
	"crisis": {"name": "Кризис", "desk": 6, "ids": ["pop_regions", "pop_hist", "pop_groups", "pop_demo"]},
	"elections": {"name": "Выборы", "desk": 1, "ids": ["polls", "parliament", "parties", "actions"]},
	"war": {"name": "Война", "desk": 13, "ids": ["war_ops", "war_army", "war_talk"]},
	"diplomacy": {"name": "Дипломатия", "desk": 10, "ids": ["xw_list", "xw_info"]},
}
const TILE_LEFT := 0.70       # справа остаётся журнал


func layout_ids(desk: int) -> Array:
	var ids: Array = []
	for id in wins:
		var w: FloatWindow = wins[id]
		if w.desk == desk and not w.closed and win_mode_ok(String(id)):
			ids.append(String(id))
	return ids


func layout_tile_ids(ids: Array) -> void:
	var n := ids.size()
	if n == 0:
		return
	var cols := clampi(int(round(sqrt(float(n) * 1.45))), 1, 4)
	var rows := int(ceil(float(n) / float(cols)))
	for k in n:
		var w: FloatWindow = wins[ids[k]]
		var r := k / cols
		var c := k % cols
		var inrow: int = mini(cols, n - r * cols)
		var cw: float = TILE_LEFT / float(inrow)
		w.frac = Rect2(cw * float(c), float(r) / float(rows), cw, 1.0 / float(rows))
		w.apply_frac()
	fix_wraps_later()


func layout_tile(desk: int) -> void:
	layout_tile_ids(layout_ids(desk))
	lay_prev = ""


func layout_preset(key: String) -> void:
	var pr: Dictionary = LAYOUT_PRESETS.get(key, {})
	if pr.is_empty():
		return
	var d: int = int(pr["desk"])
	var ids: Array = []
	for id in pr["ids"]:
		if wins.has(id):
			ids.append(String(id))
	for id in wins:
		var w: FloatWindow = wins[id]
		if w.desk == d:
			w.closed = not ids.has(String(id))
	show_desk(d)
	layout_tile_ids(ids)


func layout_snapshot(desk: int) -> Dictionary:
	var d := {}
	for id in wins:
		var w: FloatWindow = wins[id]
		if w.desk == desk:
			d[String(id)] = [w.frac.position.x, w.frac.position.y, w.frac.size.x, w.frac.size.y, w.closed]
	return d


func layout_apply_snapshot(snap: Dictionary) -> void:
	for id in snap:
		if not wins.has(id):
			continue
		var a: Array = snap[id]
		var w: FloatWindow = wins[id]
		w.frac = Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))
		w.closed = bool(a[4])
		w.apply_frac()
	show_desk(current_desk)


func layout_own_save() -> void:
	var all: Dictionary = (game_opts.get("lay_own", {}) as Dictionary).duplicate()
	all[str(current_desk)] = layout_snapshot(current_desk)
	game_opts["lay_own"] = all
	settings_save()
	nt_toast("Раскладка окон запомнена как «Своя»", "inbox", -1)


func layout_own_load() -> void:
	var all: Dictionary = game_opts.get("lay_own", {})
	if all.has(str(current_desk)):
		layout_apply_snapshot(all[str(current_desk)])


# раскладка запоминается для каждой вкладки: при уходе с неё положение окон сохраняется
func layout_remember(desk: int) -> void:
	if wins.is_empty() or desk < 0 or DisplayServer.get_name() == "headless":
		return
	var all: Dictionary = (game_opts.get("lay_auto", {}) as Dictionary).duplicate()
	var snap := layout_snapshot(desk)
	if snap.is_empty() or all.get(str(desk), {}) == snap:
		return
	all[str(desk)] = snap
	game_opts["lay_auto"] = all
	settings_save()


# 0.57.1: окна экрана «Законы» перекроены ради карточек законопроектов; прежние положения по умолчанию заменяются новыми
const LAY_MIGRATE := {"law_votes": [0.48, 0.0, 0.222, 0.28], "bills": [0.48, 0.28, 0.222, 0.32], "rm_law": [0.48, 0.60, 0.222, 0.40]}


func lay_is_old_default(a: Array, old: Array) -> bool:
	for i in 4:
		if absf(float(a[i]) - float(old[i])) > 0.003:
			return false
	return true


func layout_restore_all() -> void:
	var all: Dictionary = game_opts.get("lay_auto", {})
	for k in all:
		var snap: Dictionary = all[k]
		for id in snap:
			if not wins.has(id):
				continue
			var a: Array = snap[id]
			if a.size() < 5:
				continue
			if LAY_MIGRATE.has(id) and lay_is_old_default(a, LAY_MIGRATE[id]):
				continue    # 0.57.1: окно в прежнем положении по умолчанию — берём новое
			var w: FloatWindow = wins[id]
			w.frac = Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))
			w.closed = bool(a[4])
	layout_windows()


func win_menu_extra(pm: PopupMenu) -> void:
	pm.add_separator()
	pm.add_item("Расставить плиткой", 1002)
	var k := 0
	for key in LAYOUT_PRESETS:
		pm.add_item("Раскладка: " + String(LAYOUT_PRESETS[key]["name"]), 1010 + k)
		k += 1
	pm.add_item("Запомнить как «Свою»", 1020)
	pm.add_item("Включить «Свою»", 1021)


func win_menu_pick(mid: int) -> bool:
	if mid == 1002:
		layout_tile(current_desk)
	elif mid >= 1010 and mid < 1020:
		layout_preset(String(LAYOUT_PRESETS.keys()[mid - 1010]))
	elif mid == 1020:
		layout_own_save()
	elif mid == 1021:
		layout_own_load()
	else:
		return false
	return true


# ============================================================
#  «Ещё»: редкие вкладки под одним меню
# ============================================================
var more_btn: MenuButton = null


func build_more_menu(tabs: Control) -> void:
	for b in [tech_btn, cr_btn, meas_btn]:
		if b != null:
			(b as Control).visible = false
	more_btn = MenuButton.new()
	more_btn.text = "Ещё ▾"
	more_btn.flat = false
	more_btn.focus_mode = Control.FOCUS_NONE
	more_btn.custom_minimum_size = Vector2(0.0, 40.0)
	more_btn.theme_type_variation = "TabButton"
	more_btn.tooltip_text = "Технологии, кризисы и разовые меры"
	tabs.add_child(more_btn)
	var pm := more_btn.get_popup()
	pm.add_item("Технологии", 0)
	pm.add_item("Кризисы и протесты", 1)
	pm.add_item("Разовые меры", 2)
	pm.add_separator()
	pm.add_item("Автоматика и правила", 4)
	pm.add_item("Справочник (энциклопедия)", 3)
	pm.id_pressed.connect(func(i: int) -> void:
		if i == 0:
			set_tech_open(true)
		elif i == 1:
			set_crisis_open(true)
		elif i == 2:
			set_meas_open(true)
		elif i == 3:
			srch_open(true)
		elif i == 4:
			rules_open(true))
	# точка на «Ещё», когда есть что-то острое (идут кризисы)
	var dot := ColorRect.new()
	dot.color = C_BAD
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.anchor_left = 1.0
	dot.anchor_right = 1.0
	dot.offset_left = -14.0
	dot.offset_right = -5.0
	dot.offset_top = 5.0
	dot.offset_bottom = 14.0
	dot.visible = false
	more_btn.add_child(dot)
	nt_dots[7] = dot


func nav_extras() -> void:
	if nt_dots.has(7):
		var sev := 0.0
		for p in today_problems():
			if String((p as Dictionary)["t"]).begins_with("Недовольство") or float((p as Dictionary)["sev"]) >= 70.0:
				sev = 100.0
		(nt_dots[7] as ColorRect).visible = sev >= 70.0


func nav_init() -> void:
	for id in wins:
		(wins[id] as FloatWindow).set_starred(bm_has("win:" + String(id)))
	layout_restore_all()


# ============================================================
#  Скрываем то, чего нет в стране (флот без моря), с кнопкой «Показать всё»
# ============================================================
var show_all_btn: Button = null


func subbar_hide_absent() -> void:
	if subbar3 == null or sub3_buttons.size() < 7:
		return
	var all: bool = bool(game_opts.get("show_all", false))
	var hidden := 0
	var fleet_b: Button = sub3_buttons[4]
	var no_sea: bool = not flt_has_sea() and not all
	fleet_b.visible = not no_sea
	if no_sea:
		hidden += 1
	if show_all_btn == null:
		show_all_btn = Button.new()
		show_all_btn.theme_type_variation = "SmallButton"
		show_all_btn.focus_mode = Control.FOCUS_NONE
		show_all_btn.custom_minimum_size = Vector2(0.0, 32.0)
		show_all_btn.pressed.connect(func() -> void:
			game_opts["show_all"] = not bool(game_opts.get("show_all", false))
			settings_save()
			subbar_hide_absent())
		subbar3.add_child(show_all_btn)
	var could: bool = not flt_has_sea()
	show_all_btn.visible = could
	show_all_btn.text = "Скрыть лишнее" if all else "Показать всё (скрыто: %d)" % maxi(hidden, 1)
	show_all_btn.tooltip_text = "В вашей стране нет моря, поэтому «Флот» спрятан. Нажмите, чтобы показать все вкладки."
