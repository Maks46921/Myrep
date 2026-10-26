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
	"up_house": "Верхняя палата: правила страны, конфликт с нижней палатой, требования, переговоры и конституционная реформа (создать, упразднить, изменить полномочия или способ формирования).",
	"mv_list": "Политические движения страны: поддержка, организованность и состояние. Нажмите на движение, чтобы увидеть подробности. Движения давят на рейтинг власти и подпитывают близкие партии.",
	"mv_act": "Выбранное движение: поддержка, организованность, радикальность, политкапитал, риски. Если вы играете за движение — его действия и регистрация партии, если нет — ответы власти: диалог, уступки, запрет.",
	"fn_sum": "Сводка финансов: доверие рынков, ставка, курс, резервы, долг и банки в одном месте. Ниже последние события финансов, самые новые сверху. Графики показывают историю по месяцам.",
	"fn_cb": "Центробанк задаёт ставку, а в еврозоне её задаёт ЕЦБ. Независимый банк вызывает больше доверия, зависимый можно попросить о дешёвых деньгах. Режим курса: плавающий, привязка или коридор; защита привязки тратит резервы. Кнопки действий сгруппированы, в скобках цена в политическом капитале.",
	"fn_bank": "Банки: капитал (запас прочности), плохие кредиты, кредит экономике, пузыри и доверие вкладчиков. Когда начинается кризис, здесь появляются меры спасения. Строгий надзор и стресс-тесты делают кризис реже.",
	"fn_ex": "Биржа: индекс растёт вместе с экономикой и доверием, а перегрев может закончиться обвалом. Можно продать госкомпании (выручка гасит долг), ввести налог на сделки, ограничить спекуляции или закрыть биржу в панику.",
	"fn_debt": "Госдолг глазами рынков: средняя ставка, спред (надбавка за риск), срок, доля иностранцев и долга в валюте, итоги аукционов. Если рынки закрыты, занимать нельзя. Дефолт и программа МВФ тоже здесь.",
	"fn_fund": "Суверенные фонды копят профицит и фиксированные взносы. Правило трат решает, когда фонд сам покрывает дефицит. Рынки считают половину фондов подушкой безопасности.",
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
#  0.59: рамки «Технологии», «Кризисы», «Меры», «Автоматика», «Справочник» стоят в верхней строке значками;
#  «Ещё» нужно только на узком окне
# ============================================================
var more_btn: MenuButton = null
var nav_rare: Array = []          # значки редких рамок в верхней строке
var nav_narrow := false


func nav_icon_only(b: Button, tip: String) -> void:
	b.text = ""
	b.custom_minimum_size = Vector2(42.0, 40.0)
	b.tooltip_text = tip
	for ch in b.get_children():
		if ch is Control and (ch as Control).get_script() != null and ch.get("kind") != null:
			var ic := ch as Control
			ic.anchor_left = 0.5
			ic.anchor_right = 0.5
			ic.offset_left = -9.0
			ic.offset_right = 9.0


func nav_make_icon_btn(tabs: Control, kind: String, tip: String, f: Callable) -> Button:
	var b := Button.new()
	b.theme_type_variation = "TabButton"
	b.focus_mode = Control.FOCUS_NONE
	b.text = " "
	btn_icon(b, kind)
	nav_icon_only(b, tip)
	b.pressed.connect(f)
	tabs.add_child(b)
	return b


func build_more_menu(tabs: Control) -> void:
	nav_icon_only(tech_btn, "Технологии: схема исследований, сооружения, пассивное изучение от соседей.")
	nav_icon_only(cr_btn, "Кризисы и протесты: протесты и сепаратизм по регионам, войны за отделение, риск революции и переворота.")
	nav_icon_only(meas_btn, "Разовые меры: карточки с ответственными, последствиями и перерывом между мерами.")
	var auto_b := nav_make_icon_btn(tabs, "gauge", "Автоматика и правила «если — то»", func() -> void: rules_open(true))
	var ref_b := nav_make_icon_btn(tabs, "scroll", "Справочник (энциклопедия) и поиск по игре, Ctrl+K", func() -> void: srch_open(true))
	nav_rare = [tech_btn, cr_btn, meas_btn, auto_b, ref_b]
	more_btn = MenuButton.new()
	more_btn.text = "Ещё ▾"
	more_btn.flat = false
	more_btn.focus_mode = Control.FOCUS_NONE
	more_btn.custom_minimum_size = Vector2(0.0, 40.0)
	more_btn.theme_type_variation = "TabButton"
	more_btn.tooltip_text = "Технологии, кризисы, разовые меры, автоматика и справочник (на узком окне)"
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
	more_btn.visible = false
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
	get_viewport().size_changed.connect(nav_fit)
	nav_fit.call_deferred()


# узкое окно: значки уходят в «Ещё»
func nav_fit() -> void:
	if more_btn == null:
		return
	var narrow: bool = get_viewport().get_visible_rect().size.x < 1330.0
	nav_narrow = narrow
	for b in nav_rare:
		(b as Control).visible = not narrow
	more_btn.visible = narrow


# ============================================================
#  0.59: лампочки над рамками и вкладками. Цвет по срочности: красная «решить сейчас», жёлтая «можно улучшить»,
#  серая «новое». Лампочка горит, пока проблема есть, и гаснет, когда её решили. Красная мигает.
#  Правая кнопка на рамке или вкладке: отключить лампочку для конкретной проблемы.
# ============================================================
const LAMP_COLS := [Color(0, 0, 0, 0), Color(0.62, 0.66, 0.74), Color(0.98, 0.78, 0.25), Color(0.95, 0.30, 0.28)]
const LAMP_WORD := ["", "новое", "можно улучшить", "решить сейчас"]
var lamp_dots := {}            # Button -> ColorRect
var lamp_tw := {}              # Button -> Tween (мигание)
var lamp_base := {}            # Button -> исходная подсказка
var lamp_btn_issues := {}      # Button -> Array проблем (для правой кнопки)
var lamp_sig := ""


func lamp_it(id: String, text: String, lv: int, page: int, btn: String = "") -> Dictionary:
	return {"id": id, "t": text, "lv": lv, "page": page, "btn": btn}


func lamp_off_list() -> Array:
	var a: Variant = game_opts.get("lamp_off", [])
	return a if a is Array else []


func lamp_issues() -> Array:
	var out: Array = []
	if not current_event.is_empty():
		out.append(lamp_it("event", "Событие ждёт вашего выбора", 3, 21))
	if coal_talks:
		out.append(lamp_it("coal_talks", "Идут коалиционные переговоры: нужно собрать большинство", 3, 4))
	if not gov_ok():
		out.append(lamp_it("no_major", "У правительства нет большинства", 3, 4))
	elif gov_seats() - MAJORITY < 8:
		out.append(lamp_it("shaky", "Коалиция шатается: большинство держится на %d местах" % (gov_seats() - MAJORITY + 1), 2, 4))
	for p in PARTY_NAMES.size():
		if not in_coalition[p] or p == 0:
			continue
		var sat: float = float(satis.get(p, 50.0))
		if sat < SAT_LEAVE + 10.0:
			out.append(lamp_it("sat%d" % p, "Партнёр «%s» недоволен (%.0f), может выйти" % [PARTY_NAMES[p], sat], 3 if sat < SAT_LEAVE + 4.0 else 2, 4))
		var ld := law_demand_of(p)
		if not ld.is_empty() and not law_demand_met(p):
			out.append(lamp_it("ld%d" % p, "«%s» ждёт закон: %s" % [PARTY_NAMES[p], law_demand_text(p)], 2, 4))
		else:
			for d in PARTY_DEMANDS[p]:
				if not demand_met(d):
					out.append(lamp_it("bd%d" % p, "«%s» требует изменить бюджет" % PARTY_NAMES[p], 2, 4))
					break
	if offer_pending:
		out.append(lamp_it("offer", "Вам предложили войти в правительство", 2, 12))
	if pa_props.size() > 0:
		out.append(lamp_it("props", "Министры предлагают изменить бюджет: %d" % pa_props.size(), 2, 4))
	for a in bills_attention():
		var urgent: bool = int(a["left"]) <= 1 and int(a["sev"]) >= 2
		out.append(lamp_it("bill", "Законопроект ждёт решения (%s), голосование через %d мес." % [String(a["why"]), int(a["left"])], 3 if urgent else 2, 3))
	if not bud_changes().is_empty():
		out.append(lamp_it("bud_draft", "Бюджет изменён, но не принят", 2, 0))
	if last_deficit_pct > 3.0:
		out.append(lamp_it("deficit", "Дефицит бюджета %.1f%% ВВП" % last_deficit_pct, 3 if last_deficit_pct > 6.0 else 2, 0))
	# 0.63: финансы — банковский кризис, закрытые рынки займов, паника на рынках, провал условий МВФ
	if fin_on():
		var fb: Dictionary = fin["bk"]["cris"]
		if bool(fb["on"]):
			out.append(lamp_it("fin_bank", "Банковский кризис: %s" % String(FIN_CRIS[String(fb["kind"])]["n"]), 3 if not bool(fb.get("decided", false)) else 2, 22))
		if int(fin["db"]["closed_t"]) > turn:
			out.append(lamp_it("fin_closed", "Рынки займов закрыты для страны ещё %d мес." % (int(fin["db"]["closed_t"]) - turn), 3, 22))
		elif float(fin["mood"]) < 35.0:
			out.append(lamp_it("fin_mood", "Паника на финансовых рынках: доверие %.0f из 100" % float(fin["mood"]), 2, 22))
		var fx: Dictionary = fin["fx"]
		if String(fx["reg"]) in ["peg", "corr"] and float(ec["res"]) + float(fx["swap"]) < 3.0:
			out.append(lamp_it("fin_res", "Резервы на исходе (%.1f%% ВВП): привязку курса может сорвать" % float(ec["res"]), 3, 22))
	if regime_risk > 40.0:
		out.append(lamp_it("risk", "Риск потрясений %.0f из 100" % regime_risk, 3 if regime_risk > 70.0 else 2, 6, "cr"))
	elif reg_avg("unrest") > 35.0:
		out.append(lamp_it("unrest", "Недовольство в регионах %.0f из 100" % reg_avg("unrest"), 2, 6, "cr"))
	var idle := tech_idle_branches()
	if idle > 0:
		out.append(lamp_it("tech_idle", "В %d ветках технологий ничего не изучается" % idle, 2, 2, "tech"))
	# угроза впереди: выборы близко, а рейтинг ниже 50%
	var parl_in: int = parl_term() - (turn - last_parl)
	if parl_in >= 0 and parl_in <= 4 and approval() < 50.0:
		out.append(lamp_it("elect_soon", "До выборов %d мес., а рейтинг %.0f%%" % [parl_in, approval()], 2, 1))
	var off := lamp_off_list()
	for it in out:
		it["off"] = off.has(it["id"])
	return out


# наибольший уровень среди включённых проблем списка
func lamp_level(items: Array) -> int:
	var lv := 0
	for it in items:
		if not bool(it["off"]):
			lv = maxi(lv, int(it["lv"]))
	return lv


func lamp_make_dot(b: Button, sz: float) -> void:
	if lamp_dots.has(b):
		return
	var dot := ColorRect.new()
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.anchor_left = 1.0
	dot.anchor_right = 1.0
	dot.offset_left = -5.0 - sz
	dot.offset_right = -5.0
	dot.offset_top = 4.0
	dot.offset_bottom = 4.0 + sz
	dot.visible = false
	b.add_child(dot)
	lamp_dots[b] = dot
	lamp_base[b] = b.tooltip_text
	b.gui_input.connect(func(ev: InputEvent) -> void:
		var mb := ev as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			lamp_menu(b))


func lamp_set(b: Button, items: Array, grey: bool) -> void:
	lamp_make_dot(b, 10.0)
	var dot: ColorRect = lamp_dots[b]
	var lv := lamp_level(items)
	if lv == 0 and grey:
		lv = 1
	dot.visible = lv > 0 and b.visible
	dot.color = LAMP_COLS[lv]
	lamp_btn_issues[b] = items
	# мигает только срочная
	if lv >= 3:
		if not lamp_tw.has(b) or not (lamp_tw[b] as Tween).is_valid():
			var tw := dot.create_tween().set_loops()
			tw.tween_property(dot, "modulate:a", 0.25, 0.55)
			tw.tween_property(dot, "modulate:a", 1.0, 0.55)
			lamp_tw[b] = tw
	else:
		if lamp_tw.has(b):
			(lamp_tw[b] as Tween).kill()
			lamp_tw.erase(b)
		dot.modulate.a = 1.0
	# подсказка: исходный текст и список проблем
	var tip: String = String(lamp_base.get(b, ""))
	if not items.is_empty():
		var n_on := 0
		var lines: PackedStringArray = []
		for it in items:
			if not bool(it["off"]):
				n_on += 1
			lines.append("%s %s%s" % ["●", String(it["t"]), "  (лампочка выключена)" if bool(it["off"]) else "  [%s]" % LAMP_WORD[int(it["lv"])]])
		tip += ("\n\n" if tip != "" else "") + "Проблем здесь: %d\n" % items.size() + "\n".join(lines) + "\n(Правая кнопка: отключить лампочку для проблемы.)"
	b.tooltip_text = tip


func lamp_menu(b: Button) -> void:
	var items: Array = lamp_btn_issues.get(b, [])
	var off := lamp_off_list()
	if items.is_empty() and off.is_empty():
		return
	var pm := PopupMenu.new()
	add_child(pm)
	var ids: Array = []
	for it in items:
		var on: bool = not bool(it["off"])
		pm.add_item(("Не напоминать: " if on else "Снова напоминать: ") + String(it["t"]).left(60))
		ids.append(String(it["id"]))
	if not off.is_empty():
		pm.add_separator()
		pm.add_item("Вернуть все отключённые лампочки")
		ids.append("")
	pm.id_pressed.connect(func(i: int) -> void:
		var k := 0
		var o: Array = lamp_off_list().duplicate()
		var idx := 0
		for j in pm.item_count:
			if pm.is_item_separator(j):
				continue
			if pm.get_item_id(j) == i:
				idx = k
			k += 1
		var id: String = ids[idx] if idx < ids.size() else ""
		if id == "":
			o.clear()
		elif o.has(id):
			o.erase(id)
		else:
			o.append(id)
		game_opts["lamp_off"] = o
		settings_save()
		lamp_sig = ""
		nav_extras())
	pm.popup_hide.connect(pm.queue_free)
	pm.position = Vector2i(get_global_mouse_position()) + Vector2i(get_window().position)
	pm.popup()


func nav_extras() -> void:
	if desk_buttons.is_empty():
		return
	var iss := lamp_issues()
	# рамки: 0 Бюджет, 1 Экономика, 2 Политика, 3 Мир, 5 Общество, 6 Сегодня
	for i in desk_buttons.size():
		var b: Button = desk_buttons[i]
		var mine: Array = []
		for it in iss:
			if desk_tab(int(it["page"])) == i:
				mine.append(it)
		var grey: bool = int(nt_new.get(i, 0)) > 0 and desk_tab(current_desk) != i
		lamp_set(b, mine, grey)
		if nt_dots.has(i):
			(nt_dots[i] as ColorRect).visible = false
	# вкладки
	var groups := [[sub_buttons, [1, 3, 4, 6, 12]], [sub2_buttons, [5, 7, 10, 16, 17, 22]], [sub3_buttons, [2, 8, 9, 13, 14, 15, 18]], [sub4_buttons, [11, 20, 19]]]
	for g in groups:
		var bl: Array = g[0]
		var pg: Array = g[1]
		for k in bl.size():
			if k >= pg.size():
				break
			var mine2: Array = []
			for it in iss:
				if int(it["page"]) == int(pg[k]):
					mine2.append(it)
			lamp_set(bl[k], mine2, false)
	# редкие рамки
	var rare := {"tech": tech_btn, "cr": cr_btn, "meas": meas_btn}
	for key in rare:
		var rb: Button = rare[key]
		if rb == null:
			continue
		var mine3: Array = []
		for it in iss:
			if String(it["btn"]) == key:
				mine3.append(it)
		lamp_set(rb, mine3, false)
	# «Ещё» на узком окне: точка, если у скрытых значков есть проблема
	if nt_dots.has(7):
		var lv_more := 0
		for key in rare:
			if rare[key] != null:
				lv_more = maxi(lv_more, lamp_level(lamp_btn_issues.get(rare[key], [])))
		var md: ColorRect = nt_dots[7]
		md.visible = nav_narrow and lv_more > 0
		md.color = LAMP_COLS[maxi(lv_more, 1)]


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
