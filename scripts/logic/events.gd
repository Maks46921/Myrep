# События и новости.
extends "res://scripts/logic/coalition.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func auto_event_ok(ev: Dictionary) -> bool:
	return false


func auto_event_pick(ev: Dictionary) -> int:
	return 0


func auto_resolve_event() -> void:
	pass


func council_event(pick: int) -> int:
	return 0


func council_event_note(i: int) -> String:
	return ""


func council_event_ok() -> bool:
	return false


func council_split(fx: Dictionary) -> Dictionary:
	return {}


func fleet_resolve(i: int) -> void:
	pass


func mil_resolve(i: int) -> void:
	pass


func opp_resolve_offer(i: int) -> void:
	pass


func radical_events() -> Array:
	return []


func resolve_crisis(opt: Dictionary) -> void:
	pass


func set_time_btns(dis: bool) -> void:
	pass


# --- конец заглушек ---


func ev_de_only(t: String) -> bool:
	if ccode == "DE":
		return false
	for w in ["Бундес", "АдГ", "немецк", "Германи", "канцлер", "Берлин", "Бундестаг", "брандмауэр"]:
		if t.find(w) >= 0:
			return true
	return false


func event_ok(e: Dictionary) -> bool:
	var c: String = e.get("cond", "")
	match c:
		"": return true
		"env_low": return float(lvl["env_lvl"]) < 45.0
		"infl_high": return inflation > 5.5
		"debt_high": return debt / gdp > 0.8
		"unemp_high": return unemployment > 8.0
		"sec_low": return float(lvl["security_lvl"]) < 45.0
		"appr_low": return approval() < 42.0
		"rich": return debt / gdp < 0.45
		"pre_elec": return parl_term() - (turn - last_parl) <= 8
	return true


func show_news() -> void:
	var np: Array = []
	for nn in NEWS:
		if not ev_de_only(String(nn["text"])):
			np.append(nn)
	np.append_array(NEWS_C)
	np.append_array(NEWS_C)
	var n: Dictionary = np[randi() % np.size()]
	var eff := apply_fx(n["fx"])
	log_tag("НОВОСТЬ", COL_HEAD, "%s — %s%s" % [date_text(), loc(String(n["text"])), (" [color=%s](%s)[/color]" % [COL_DIM, eff]) if eff != "" else ""])


func ev_kind_info() -> Array:
	# [название, значок, цвет]
	var e: Dictionary = current_event
	if String(e.get("special", "")) == "nocon":
		return ["ВОТУМ НЕДОВЕРИЯ", "!", C_BAD]
	if String(e.get("kind", "")) == "campaign":
		return ["ПРЕДВЫБОРНАЯ КАМПАНИЯ", "★", Color(1.0, 0.82, 0.40)]
	if String(e.get("kind", "")) == "pcampaign":
		return ["ВЫБОРЫ ГЛАВЫ ГОСУДАРСТВА", "★", Color(1.0, 0.82, 0.40)]
	if event_party >= 0:
		return ["КОАЛИЦИЯ", "◆", C_ACCENT]
	if e.has("rid"):
		return ["РЕЖИМ", "■", C_BAD]
	if e.has("reg"):
		return ["РЕГИОН", "●", C_TEAL]
	if ECON_EVENTS.has(e):
		return ["ЭКОНОМИКА", "▲", C_WARN]
	return ["ПОЛИТИКА", "◆", C_PURPLE]


func ev_style(col: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col.darkened(0.72)
	s.border_color = col
	s.border_width_left = 5
	s.set_corner_radius_all(10)
	s.content_margin_left = 14.0
	s.content_margin_right = 12.0
	s.content_margin_top = 8.0
	s.content_margin_bottom = 8.0
	return s


func ev_context_text() -> String:
	var cs: String = ("[color=%s]Политкапитал[/color] [b]%.0f[/b]   [color=%s]Рейтинг[/color] [b]%.0f%%[/b]   [color=%s]Долг[/color] [b]%.0f%% ВВП[/b]   [color=%s]Инфляция[/color] [b]%.1f%%[/b]   [color=%s]Безработица[/color] [b]%.1f%%[/b]" % [
		COL_DIM, capital, COL_DIM, approval(), COL_DIM, debt / gdp * 100.0, COL_DIM, inflation, COL_DIM, unemployment])
	return "[font_size=13]%s[/font_size]" % cs


func present_event() -> void:
	if observer:
		# v35: в режиме наблюдателя решения принимает ИИ
		var ai_i := 0 if String(current_event.get("special", "")) == "crisis" else auto_event_pick(current_event)
		log_tag("НАБЛЮДАТЕЛЬ", COL_TEAL, "%s — ИИ выбрал: «%s»." % [coal_text(String(current_event["t"])).replace("{r}", String(REGIONS[event_region]["name"]) if event_region >= 0 else ""), coal_text(String(current_event["o"][ai_i]["l"]))])
		choose(ai_i)
		return
	sfx("event")
	var text: String = String(current_event["t"])
	if event_region >= 0:
		text = text.replace("{r}", REGIONS[event_region]["name"])
	text = coal_text(text)
	var w: FloatWindow = wins["event"]
	w.visible = true
	w.move_to_front()
	var ki := ev_kind_info()
	var kc: Color = ki[2]
	ev_banner.add_theme_stylebox_override("panel", ev_style(kc))
	ev_glyph.text = String(ki[1])
	ev_glyph.add_theme_color_override("font_color", kc.lightened(0.25))
	ev_kind_lbl.text = String(ki[0])
	ev_kind_lbl.add_theme_color_override("font_color", kc.lightened(0.25))
	var meta: PackedStringArray = [date_text()]
	if event_region >= 0:
		meta.append(String(REGIONS[event_region]["name"]))
	if event_party > 0:
		meta.append(String(PARTY_NAMES[event_party]))
	if event_min >= 0:
		meta.append(String(MINISTRIES[event_min]["name"]))
	ev_meta_lbl.text = loc("  ·  ".join(meta))
	event_text = "[font_size=21]%s[/font_size]" % text
	event_label.text = event_text
	ev_ctx.text = ev_context_text()
	var opts: Array = current_event["o"]
	for i in event_buttons.size():
		(event_boxes[i] as Control).visible = i < opts.size()
		if i < opts.size():
			var b: Button = event_buttons[i]
			b.text = "%d   %s" % [i + 1, coal_text(String(opts[i]["l"]))]
			var d := describe_fx(opts[i]["fx"], event_region)
			b.tooltip_text = ("Последствия: " + d) if d != "" else "Без прямых последствий"
			var cn := council_event_note(i)
			(event_fx_rts[i] as RichTextLabel).text = "[font_size=13]%s%s[/font_size]" % [fx_pros_cons(opts[i]["fx"], event_region), ("\n[color=%s]%s[/color]" % [COL_DIM, cn]) if cn != "" else ""]
			var card: PanelContainer = event_boxes[i]
			card.add_theme_stylebox_override("panel", sbox(C_PANEL2.darkened(0.18), kc.darkened(0.45), 1, 10, 4.0, 3.0))
	set_time_btns(true)
	log_tag("СОБЫТИЕ", COL_WARN, "%s — %s" % [date_text(), text])
	call_deferred("refit_event")


# экономические события в пуле: 0 — нет, 1 — обычно, 2 — вдвое чаще (настройка новой игры)
func econ_pool() -> Array:
	var out: Array = []
	var n: int = int(round(float(game_opts["econ"]) * float(ECON_EVENTS.size())))
	for i in n:
		out.append(ECON_EVENTS[i % ECON_EVENTS.size()])
	return out


func show_event() -> void:
	if not current_event.is_empty() or election_open:
		return
	if randf() < 0.22 and show_coal_event():
		return
	var rpool: Array = []
	var pool: Array = []
	for e in EVENTS + econ_pool() + EVENTS_C + EVENTS_C + radical_events() + reg_events_all():
		if ccode != "DE" and not e.has("reg") and ev_de_only(String(e.get("t", ""))) and not EVENTS_C.has(e):
			continue
		if e.has("reg"):
			rpool.append(e)
		elif event_ok(e):
			pool.append(e)
	var chosen: Dictionary = {}
	var rid := -1
	if randf() < 0.5:
		rpool.shuffle()
		for ev in rpool:
			var rs: Array = []
			for i in regions.size():
				if region_ok(ev["reg"], i):
					rs.append(i)
			if not rs.is_empty():
				chosen = ev
				rid = rs[randi() % rs.size()]
				break
	if chosen.is_empty():
		if pool.is_empty():
			return
		chosen = pool[randi() % pool.size()]
	current_event = chosen
	event_region = rid
	if auto_event_ok(chosen):
		auto_resolve_event()
	else:
		present_event()


func choose(i: int) -> void:
	if current_event.is_empty():
		return
	var opts: Array = current_event["o"]
	if i >= opts.size():
		return
	var special: String = current_event.get("special", "")
	var fx_in: Dictionary = opts[i]["fx"]
	if council_event_ok():
		# v35: событие решает совет коалиции; затраты капитала делятся по влиянию
		i = council_event(i)
		fx_in = council_split(opts[i]["fx"])
	var opt: Dictionary = opts[i]
	var eff := apply_fx(fx_in, event_region)
	log_line("[color=%s]    ► Выбрано:[/color] «%s». %s" % [COL_DIM, opt["l"], ("[color=%s]Последствия:[/color] %s." % [COL_DIM, eff]) if eff != "" else "Прямых последствий нет."])
	current_event = {}
	event_region = -1
	event_party = -1
	event_min = -1
	(wins["event"] as FloatWindow).visible = false
	set_time_btns(game_over)
	if special == "nocon":
		resolve_no_confidence()
	elif special == "crisis":
		resolve_crisis(opt)
	elif special == "offer":
		opp_resolve_offer(i)
	elif special == "fleet":
		fleet_resolve(i)
	elif special == "war":
		mil_resolve(i)
	refresh()


func dip_events() -> void:
	if not current_event.is_empty() or dip.is_empty():
		return
	var summit_months := [3, 6, 10, 12]
	if month in summit_months and turn - dip_last_summit >= 2 and randf() < 0.55:
		dip_last_summit = turn
		var ev: Dictionary = DIP_SUMMITS[randi() % DIP_SUMMITS.size()] if ccode == "DE" else gen_dip_event(true)
		current_event = ev
		event_region = -1
		if auto_event_ok(ev):
			auto_resolve_event()
		else:
			present_event()
		return
	if randf() < 0.06:
		var ev2: Dictionary = DIP_EVENTS[randi() % DIP_EVENTS.size()] if ccode == "DE" else gen_dip_event(false)
		current_event = ev2
		event_region = -1
		if auto_event_ok(ev2):
			auto_resolve_event()
		else:
			present_event()


func gen_dip_event(summit: bool) -> Dictionary:
	var oth: Array = DIP_ORDER.duplicate()
	var p: String = String(oth[randi() % oth.size()])
	var pn: String = String(DIP_C[p]["name"])
	var allp := {}
	var allp_n := {}
	var allp_m := {}
	for c in oth:
		allp[c] = 3.0
		allp_n[c] = -4.0
		allp_m[c] = 2.0
	var cb: String = "@"
	var kinds: Array = []
	if summit:
		kinds = [
			{"t": "Саммит ЕС: обсуждается общий оборонный фонд. Мнения разделились.", "o": [
				{"l": "Поддержать фонд (долг +0.3% ВВП)", "fx": {"debt": 0.3, "dip": {p: 5.0}, "state": {"security_lvl": 1.0}, "support": {"Силовики": 2.0}}},
				{"l": "Предложить национальное финансирование", "fx": {"dip": {p: -3.0}, "support": {"Бизнес": 1.0}}},
				{"l": "Компромисс: ограниченный фонд (капитал -4)", "fx": {"capital": -4.0, "dip": allp_m}}]},
			{"t": "Саммит ЕС: спор о правилах миграции и распределении беженцев.", "o": [
				{"l": "Поддержать квоты и общую систему убежища", "fx": {"dip": {p: 4.0}, "support": {"Молодёжь": 2.0, "Силовики": -2.0}}},
				{"l": "Потребовать усиления внешних границ", "fx": {"dip": {p: -2.0}, "support": {"Силовики": 3.0, "Село": 2.0}}},
				{"l": "Компромисс (капитал -4)", "fx": {"capital": -4.0, "dip": allp_m}}]},
			{"t": "Саммит ЕС: бюджет союза на следующий период. Спор о взносах и выплатах.", "o": [
				{"l": "Согласиться на увеличение взноса (долг +0.3% ВВП)", "fx": {"debt": 0.3, "dip": allp, "support": {"Бизнес": 1.0}}},
				{"l": "Требовать экономии и скидки", "fx": {"dip": {p: -4.0}, "support": {"Бизнес": 2.0, "Пенсионеры": 1.0}}},
				{"l": "Компромисс (капитал -4)", "fx": {"capital": -4.0, "dip": allp_m}}]},
			{"t": "Саммит ЕС: торговые отношения с США и Китаем. Нужна общая позиция.", "o": [
				{"l": "Твёрдая общая позиция против пошлин", "fx": {"dip": allp, "shock": -0.1, "support": {"Рабочие": 1.0}}},
				{"l": "Искать двусторонние сделки", "fx": {"dip": {p: -3.0}, "shock": 0.2, "support": {"Бизнес": 2.0}}},
				{"l": "Компромисс (капитал -4)", "fx": {"capital": -4.0, "dip": allp_m}}]}]
	else:
		kinds = [
			{"t": "%s предлагает совместный оборонный проект: общая система ПВО и закупки техники." % pn, "o": [
				{"l": "Согласиться (долг +0.4% ВВП)", "fx": {"debt": 0.4, "dip": {p: 7.0}, "state": {"security_lvl": 2.0}, "support": {"Силовики": 3.0, "Бизнес": 1.0}}},
				{"l": "Участвовать частично (капитал -2)", "fx": {"capital": -2.0, "dip": {p: 3.0}, "state": {"security_lvl": 1.0}}},
				{"l": "Отказаться: у нас свои проекты", "fx": {"dip": {p: -6.0}, "support": {"Бизнес": 1.0}}}]},
			{"t": "%s жалуется: энергосети и транзит электроэнергии через границу перегружены." % pn, "o": [
				{"l": "Ускорить строительство линий (долг +0.3% ВВП)", "fx": {"debt": 0.3, "dip": {p: 6.0}, "state": {"infra_lvl": 2.0}, "support": {"Экологи": 2.0}}},
				{"l": "Сослаться на местные власти", "fx": {"dip": {p: -4.0}, "support": {"Село": 1.0}}}]},
			{"t": "Торговый спор: %s требует снять барьеры для своих товаров." % pn, "o": [
				{"l": "Договориться о компромиссе (капитал -2)", "fx": {"capital": -2.0, "dip": {p: 6.0}, "support": {"Бизнес": 1.0}}},
				{"l": "Отстаивать национальные интересы", "fx": {"dip": {p: -6.0}, "other_rev": 0.05, "support": {"Рабочие": 1.0}}}]},
			{"t": "Власти приграничных регионов просят возобновить трансграничные железнодорожные линии с партнёром — %s." % pn, "o": [
				{"l": "Профинансировать (долг +0.2% ВВП)", "fx": {"debt": 0.2, "dip": {p: 5.0}, "state": {"infra_lvl": 2.0}, "support": {"Рабочие": 2.0}}},
				{"l": "Отложить", "fx": {"dip": {p: -2.0}}}]},
			{"t": "Из-за миграционного давления соседи спорят, кто отвечает за контроль на внутренних границах.", "o": [
				{"l": "Усилить совместное патрулирование (долг +0.1% ВВП)", "fx": {"debt": 0.1, "dip": allp_m, "state": {"security_lvl": 2.0}}},
				{"l": "Ввести временный контроль", "fx": {"dip": allp_n, "state": {"security_lvl": 3.0}, "support": {"Силовики": 4.0, "Село": 2.0, "Бизнес": -3.0}}},
				{"l": "Оставить как есть", "fx": {"support": {"Силовики": -2.0}}}]},
			{"t": "Крупная авария на трансграничном железнодорожном узле. %s требует расследования." % pn, "o": [
				{"l": "Совместное расследование и компенсации (долг +0.2% ВВП)", "fx": {"debt": 0.2, "dip": {p: 4.0}, "support": {"Рабочие": 2.0}}},
				{"l": "Отрицать вину", "fx": {"dip": {p: -5.0}, "all": -1.0}}]}]
	return kinds[randi() % kinds.size()]


func w_help_event(c: String, kind: Dictionary) -> void:
	var name: String = String(WORLD[c]["name"])
	var n: String = String(kind["n"])
	current_event = {"t": "%s переживает %s и просит у соседей поддержки: ваши торговые связи под угрозой." % [name, n], "o": [
		{"l": "Выделить помощь (долг +0.3% ВВП): кризис там сократится", "fx": {"debt": 0.3, "wc_help": c, "dip": {c: 9.0}, "support": {"Бизнес": 1.0}}},
		{"l": "Ограничиться заявлениями поддержки (капитал -1)", "fx": {"capital": -1.0, "dip": {c: 3.0}}},
		{"l": "Дистанцироваться: у нас свои проблемы", "fx": {"dip": {c: -7.0}, "support": {"Пенсионеры": 1.0}}}]}
	event_region = -1
	present_event()


func fire_scripted() -> bool:
	if not current_event.is_empty() or election_open:
		return false
	for i in EVENTS_SPECIAL.size():
		var e: Dictionary = EVENTS_SPECIAL[i]
		if int(e.get("turn", -1)) != turn or scripted_done.has(i):
			continue
		if not event_ok(e):
			continue
		scripted_done[i] = true
		current_event = e
		event_region = -1
		present_event()
		return true
	return false
