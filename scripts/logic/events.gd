# События и новости.
extends "res://scripts/logic/coalition.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func auto_event_ok(ev: Dictionary) -> bool:
	return false


func auto_event_pick(ev: Dictionary) -> int:
	return 0


func auto_resolve_event() -> void:
	pass


func cap_swap(p: int) -> float:
	return 0.0


func cap_unswap(p: int, old: float) -> void:
	pass


func council_event(pick: int) -> int:
	return 0


func council_event_note(i: int) -> String:
	return ""


func council_event_ok() -> bool:
	return false


func council_split(fx: Dictionary) -> Dictionary:
	return {}


func ev_ext_val(k: String) -> float:
	return 0.0


func fleet_resolve(i: int) -> void:
	pass


func flt_has_sea() -> bool:
	return false


func inbox_route() -> bool:
	return false


func io_member(o: String) -> bool:
	return false


func io_members(o: String) -> Array:
	return []


func io_ready() -> bool:
	return false


func mil_resolve(i: int) -> void:
	pass


func opp_resolve_offer(i: int) -> void:
	pass


func radical_events() -> Array:
	return []


func realism_resolve(opt: Dictionary) -> void:
	pass


func reg60_resolve(opt: Dictionary) -> void:
	pass


func resolve_crisis(opt: Dictionary) -> void:
	pass


func revolt_resolve(opt: Dictionary) -> void:
	pass


func set_time_btns(dis: bool) -> void:
	pass


func uq_resolve(opt: Dictionary) -> void:
	pass


func win_fade_in(w: Control, dur: float = 0.22) -> void:
	pass


# --- конец заглушек ---


func ev_de_only(t: String) -> bool:
	if ccode == "DE":
		return false
	for w in ["Бундес", "АдГ", "немецк", "Германи", "канцлер", "Берлин", "Бундестаг", "брандмауэр"]:
		if t.find(w) >= 0:
			return true
	return false


# v53_1: события про международную организацию — только её членам
# v54_1: список пар [слово, организации], а не словарь — в английской версии «фонды ЕС» и «Фонды ЕС» переводятся одинаково
const EV_ORG_WORDS := [
	["НАТО", ["nato"]], ["ОДКБ", ["csto"]], ["ЕАЭС", ["eaeu"]], ["СНГ", ["cis"]], ["Еврокомисс", ["eu"]],
	["Брюссель выделяет", ["eu"]], ["фонды ЕС", ["eu"]], ["Фонды ЕС", ["eu"]], ["Саммит ЕС", ["eu"]], ["еврозон", ["euro"]],
	["Шенген", ["schengen"]], ["Совет Европы", ["coe"]], ["ОБСЕ", ["osce"]],
]


func ev_org_blocked(t: String) -> bool:
	if not io_ready():
		return false
	for wo in EV_ORG_WORDS:
		if t.find(String(wo[0])) >= 0:
			var ok := false
			for o in wo[1]:
				if io_member(String(o)):
					ok = true
			if not ok:
				return true
	return false


func event_ok(e: Dictionary) -> bool:
	if ev_org_blocked(String(e.get("t", ""))):
		return false
	var cv: Variant = e.get("cond", "")
	if typeof(cv) == TYPE_DICTIONARY:
		return ev_cond_ok(cv)
	var c: String = String(cv)
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


# ============================================================
#  v46_1: движок событий — условия, веса и память, цепочки, отложенные последствия, риск, доступность вариантов
# ============================================================
const EV_COOLDOWN := 30        # месяцев, пока то же событие не повторится
const EV_LATER_MAX := 12


func ev_id(e: Dictionary) -> String:
	if e.has("id"):
		return String(e["id"])
	return "h%d" % hash(String(e.get("t", "")))


func ev_cond_ok(c: Dictionary) -> bool:
	for k in c:
		var v: Variant = c[k]
		match String(k):
			"infl_gt":
				if inflation <= float(v): return false
			"infl_lt":
				if inflation >= float(v): return false
			"unemp_gt":
				if unemployment <= float(v): return false
			"unemp_lt":
				if unemployment >= float(v): return false
			"debt_gt":
				if debt / gdp * 100.0 <= float(v): return false
			"debt_lt":
				if debt / gdp * 100.0 >= float(v): return false
			"appr_lt":
				if approval() >= float(v): return false
			"appr_gt":
				if approval() <= float(v): return false
			"growth_lt":
				if growth >= float(v): return false
			"growth_gt":
				if growth <= float(v): return false
			"cap_gt":
				if capital <= float(v): return false
			"lvl_lt":
				for lk in v:
					if float(lvl.get(lk, 50.0)) >= float(v[lk]): return false
			"lvl_gt":
				for lk2 in v:
					if float(lvl.get(lk2, 50.0)) <= float(v[lk2]): return false
			"sup_lt":
				for g in v:
					if float(support.get(g, 50.0)) >= float(v[g]): return false
			"pre_elec":
				if bool(v) != (parl_term() - (turn - last_parl) <= 8): return false
			"post_elec":
				if bool(v) != (turn - last_parl <= 10 and turn > 6): return false
			"min_turn":
				if turn < int(v): return false
			"eu":
				var in_eu: bool = io_member("eu") if io_ready() else bool(MACRO.get("eu", WORLD.get(ccode, {}).get("eu", false)))
				if bool(v) != in_eu: return false
			"org":
				if not io_ready(): continue
				var any := false
				for o in (v if typeof(v) == TYPE_ARRAY else [v]):
					if io_member(String(o)): any = true
				if not any: return false
			"coast":
				if bool(v) != flt_has_sea(): return false
			"monarchy":
				if bool(v) != (ccode in RAD_MONARCHIES): return false
			"opp":
				if bool(v) != opp_mode: return false
			_:
				# внешние показатели модулей ниже по цепочке (коррупция, цена энергии, волна протестов…)
				var kk: String = String(k)
				if kk.ends_with("_gt"):
					if ev_ext_val(kk.substr(0, kk.length() - 3)) <= float(v): return false
				elif kk.ends_with("_lt"):
					if ev_ext_val(kk.substr(0, kk.length() - 3)) >= float(v): return false
	return true


func ev_weight(e: Dictionary) -> float:
	var w: float = float(e.get("w", 1.0))
	var h: Dictionary = ev_hist.get(ev_id(e), {})
	if not h.is_empty():
		if turn - int(h["t"]) < EV_COOLDOWN:
			return 0.0
		w /= 1.0 + 0.6 * float(h["n"])
	if typeof(e.get("cond", "")) == TYPE_DICTIONARY or String(e.get("cond", "")) != "":
		w *= 1.5     # событие по обстановке важнее случайного
	return w


func ev_pick(pool: Array) -> Dictionary:
	var tot := 0.0
	var ws: Array = []
	for e in pool:
		var w: float = ev_weight(e)
		ws.append(w)
		tot += w
	if tot <= 0.0:
		return {}
	var r: float = randf() * tot
	for i in pool.size():
		r -= float(ws[i])
		if r <= 0.0 and float(ws[i]) > 0.0:
			return pool[i]
	return pool[pool.size() - 1]


func ev_by_id(id: String) -> Dictionary:
	for e in EVENTS_X:
		if String(e["id"]) == id:
			return e
	return {}


func ev_text(t: String) -> String:
	t = t.replace("{country}", String(WORLD.get(ccode, {}).get("name", ccode)))
	if event_region >= 0 and event_region < REGIONS.size():
		t = t.replace("{r}", String(REGIONS[event_region]["name"]))
	return t


func ev_rand_region() -> int:
	if regions.is_empty():
		return -1
	return randi() % regions.size()


# оценка варианта советником: прямой эффект + ожидаемый риск + отложенное последствие
func ev_opt_score(opt: Dictionary) -> float:
	var sc: float = ev_fx_score(opt.get("fx", {}))
	if opt.has("risk"):
		sc += float(opt["risk"].get("p", 0.0)) * ev_fx_score(opt["risk"].get("fx", {}))
	if opt.has("later"):
		sc += 0.7 * ev_fx_score(opt["later"].get("fx", {}))
	return sc


# ценность эффекта для страны (используется советником и проверкой баланса): долг, рост, цены, поддержка групп,
# постоянные расходы (ползунки), доходы, уровни государства, регион, отношения, капитал
func ev_fx_score(fx: Dictionary) -> float:
	var dr: float = debt / maxf(1.0, gdp)
	var s := 0.0
	s -= float(fx.get("debt", 0.0)) * 2.2 * (1.0 + maxf(0.0, dr - 0.6))
	s -= float(fx.get("infl", 0.0)) * 2.0
	s -= float(fx.get("unemp", 0.0)) * 2.5
	s += float(fx.get("shock", 0.0)) * 3.0
	s += float(fx.get("other_rev", 0.0)) * 12.0
	s += float(fx.get("all", 0.0)) * 3.6
	for g in fx.get("support", {}):
		s += float(fx["support"][g]) * 0.9
	for k in fx.get("slider", {}):
		# налог вверх — доход бюджету, расход вверх — постоянная нагрузка
		s += float(fx["slider"][k]) * (4.0 if String(k) in ["income", "social", "corp", "vat"] else -4.0)
	for k2 in fx.get("state", {}):
		var v: float = float(fx["state"][k2])
		s += (-v if k2 == "corruption" else v) * 0.8
	for d in [fx.get("reg", {}), fx.get("regall", {})]:
		var mul: float = 1.0 if d == fx.get("reg", {}) else 2.5
		for rk in d:
			var rv0: float = float(d[rk])
			match String(rk):
				"loyalty": s += rv0 * 0.35 * mul
				"unrest": s -= rv0 * 0.35 * mul
				"dev": s += rv0 * 0.6 * mul
				_: s += rv0 * 0.2 * mul
	s += float(fx.get("dip_all", 0.0)) * 1.5
	for dc in fx.get("dip", {}):
		s += float(fx["dip"][dc]) * 0.3
	s += float(fx.get("coal_sat", 0.0)) * 0.3
	s -= float(fx.get("reg_transfer", 0.0)) * 3.0
	s += float(fx.get("capital", 0.0)) * 0.45
	return s


func ev_title(e: Dictionary, text: String) -> String:
	if e.has("title"):
		return String(e["title"])
	var t: String = text.split(".")[0].split("!")[0].split(":")[0]
	if t.length() > 58:
		t = t.substr(0, 56) + "…"
	return t


# Цена в капитале показана только на кнопке, в строке последствий её не повторяем.
# Некоторые варианты имели цену прямо в тексте «(капитал -4)»: убираем, цена стоит в скобках кнопки.
func strip_capital_note(t: String) -> String:
	var re := RegEx.new()
	re.compile("\\s*\\(капитал [-−+]?\\d+\\)")
	return re.sub(t, "", true)


func fx_no_capital(fx: Dictionary) -> Dictionary:
	if not fx.has("capital"):
		return fx
	var d: Dictionary = fx.duplicate()
	d.erase("capital")
	return d


# "" — вариант доступен, иначе причина
func ev_opt_block(opt: Dictionary) -> String:
	var fx: Dictionary = opt.get("fx", {})
	var cost: float = -float(fx.get("capital", 0.0))
	if cost > 0.0 and cap_spendable() < cost:
		return "не хватает политкапитала (нужно %.0f)" % cost
	return ""


func ev_first_ok(opts: Array) -> int:
	for i in opts.size():
		if ev_opt_block(opts[i]) == "":
			return i
	return 0


func _ev_chain_due() -> bool:
	for q in ev_queue:
		if int((q as Dictionary)["due"]) <= turn:
			return true
	return false


func ev_tick() -> bool:
	# раз в месяц: отложенные последствия; true — показано продолжение цепочки
	for i in range(ev_later.size() - 1, -1, -1):
		var l: Dictionary = ev_later[i]
		if int(l["due"]) <= turn:
			ev_later.remove_at(i)
			var old_r := event_region
			event_region = int(l.get("rid", -1)) if int(l.get("rid", -1)) < regions.size() else -1
			var eff := apply_fx(l["fx"], event_region)
			log_tag("ПОСЛЕДСТВИЯ", COL_TEAL, "%s — %s%s" % [date_text(), ev_text(String(l.get("t", "Сказываются прошлые решения."))), (" [color=%s](%s)[/color]" % [COL_DIM, eff]) if eff != "" else ""])
			event_region = old_r
	if not current_event.is_empty() or election_open or game_over:
		return false
	for j in ev_queue.size():
		var q: Dictionary = ev_queue[j]
		if int(q["due"]) <= turn:
			ev_queue.remove_at(j)
			var e: Dictionary = ev_by_id(String(q["id"]))
			if e.is_empty():
				return false
			current_event = e
			event_region = int(q.get("rid", -1)) if int(q.get("rid", -1)) < regions.size() else -1
			if auto_event_ok(e):
				auto_resolve_event()
			else:
				present_event()
			return true
	return false


func ev_after_choice(ev: Dictionary, opt: Dictionary, i: int, rid: int) -> String:
	# риск, отложенные последствия, продолжения; запись в историю. Возвращает текст исхода для журнала
	var out := ""
	var id: String = ev_id(ev)
	var h: Dictionary = ev_hist.get(id, {"t": turn, "n": 0, "o": i})
	h["t"] = turn
	h["n"] = int(h["n"]) + 1
	h["o"] = i
	ev_hist[id] = h
	if opt.has("risk"):
		var rk: Dictionary = opt["risk"]
		if randf() < float(rk.get("p", 0.0)):
			var old_r := event_region
			event_region = rid
			var eff := apply_fx(rk.get("fx", {}), rid)
			event_region = old_r
			out = "[color=%s]Не повезло:[/color] %s%s" % [COL_BAD, ev_text(String(rk.get("t", ""))), (" (%s)" % eff) if eff != "" else ""]
		elif opt.has("ok"):
			out = "[color=%s]Обошлось:[/color] %s" % [COL_GOOD, String(opt["ok"])]
	if opt.has("later") and ev_later.size() < EV_LATER_MAX:
		var l: Dictionary = opt["later"]
		ev_later.append({"due": turn + int(l.get("m", 6)), "fx": l.get("fx", {}), "t": String(l.get("t", "")), "rid": rid})
	if opt.has("next"):
		var nx: Dictionary = opt["next"]
		if randf() < float(nx.get("p", 1.0)):
			ev_queue.append({"id": String(nx["id"]), "due": turn + int(nx.get("m", 2)), "rid": rid})
	ev_log.append({"date": date_text(), "title": String(ev.get("title", "")), "opt": String(opt["l"]), "res": out})
	while ev_log.size() > 40:
		ev_log.pop_front()
	return out


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
	# [название, значок, цвет, векторный значок]
	var a: Array = ev_kind_info0()
	var map := {"!": "warn", "★": "star", "◆": "hall", "■": "shield", "●": "pin", "▲": "trend"}
	a.append(String(map.get(String(a[1]), "hall")))
	var e: Dictionary = current_event
	if e.has("cat") and EV_CATS.has(String(e["cat"])):
		var ci: Dictionary = EV_CATS[String(e["cat"])]
		return [String(ci["n"]), String(a[1]), ci["col"], String(ci["ico"])]
	if String(e.get("special", "")) == "revolt" or String(e.get("special", "")) == "war":
		return [String(a[0]) if String(a[0]) != "ПОЛИТИКА" else "КРИЗИС", "!", C_BAD, "shield"]
	if String(e.get("special", "")) == "rl":
		return ["ГОСУДАРСТВО", "◆", C_TEAL, "flag"]
	return a


func ev_kind_info0() -> Array:
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


# v50: какие события касаются самой партии игрока, даже когда она вне власти (предложение войти в правительство, предвыборная кампания)
func ev_for_player(ev: Dictionary) -> bool:
	return String(ev.get("special", "")) == "offer" or String(ev.get("kind", "")) == "campaign"


func present_event() -> void:
	# v50: вне власти решения по государственным событиям принимает правительство (своим капиталом)
	if opp_mode and not observer and not ev_for_player(current_event):
		var gi := 0 if String(current_event.get("special", "")) == "crisis" else auto_event_pick(current_event)
		var gov_pm: int = int(opp_gov["pm"]) if not opp_gov.is_empty() else -1
		var old_cap := cap_swap(gov_pm) if gov_pm >= 0 else 0.0
		log_tag("ПРАВИТЕЛЬСТВО", COL_TEAL, "%s — решение правительства: «%s»." % [coal_text(String(current_event["t"])).replace("{r}", String(REGIONS[event_region]["name"]) if event_region >= 0 else "").left(160), coal_text(String(current_event["o"][gi]["l"]))])
		choose(gi)
		if gov_pm >= 0:
			cap_unswap(gov_pm, old_cap)
		return
	if observer:
		# v35: в режиме наблюдателя решения принимает ИИ
		var ai_i := 0 if String(current_event.get("special", "")) == "crisis" else auto_event_pick(current_event)
		log_tag("НАБЛЮДАТЕЛЬ", COL_TEAL, "%s — ИИ выбрал: «%s»." % [coal_text(String(current_event["t"])).replace("{r}", String(REGIONS[event_region]["name"]) if event_region >= 0 else ""), coal_text(String(current_event["o"][ai_i]["l"]))])
		choose(ai_i)
		return
	if inbox_route():
		return
	sfx("event")
	var text: String = ev_text(String(current_event["t"]))
	if event_region >= 0:
		text = text.replace("{r}", REGIONS[event_region]["name"])
	text = coal_text(text)
	var w: FloatWindow = wins["event"]
	var was_vis: bool = w.visible
	w.visible = true
	w.move_to_front()
	if not was_vis:
		win_fade_in(w, 0.25)
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
	# v46_1: иллюстрированная шапка, метки, совет и память
	var spec: String = String(current_event.get("special", ""))
	var badges: Array = []
	if bool(current_event.get("chain", false)):
		badges.append(["ПРОДОЛЖЕНИЕ ИСТОРИИ", C_WARN])
	var cnd: Variant = current_event.get("cond", "")
	if (typeof(cnd) == TYPE_DICTIONARY and not (cnd as Dictionary).is_empty()) or (typeof(cnd) == TYPE_STRING and String(cnd) != ""):
		badges.append(["ПО ОБСТАНОВКЕ", C_TEAL])
	if spec in ["nocon", "revolt", "war", "crisis", "coal"]:
		badges.append(["ВАЖНО", C_BAD])
	var hid: String = ev_id(current_event)
	var hh: Dictionary = ev_hist.get(hid, {})
	if not hh.is_empty():
		badges.append(["УЖЕ БЫЛО", C_DIM])
	if ev_art != null:
		# v49: событие связано с другой страной — в шапке её флаг
		var fcc: String = String(current_event.get("cc", ""))
		if fcc == "":
			for o0 in (current_event.get("o", []) as Array):
				var ar0: Variant = (o0 as Dictionary).get("arg", null)
				if typeof(ar0) == TYPE_STRING and WORLD.has(String(ar0)):
					fcc = String(ar0)
					break
		ev_art.set("flag", fcc)
		ev_art.setup(kc, String(ki[3]), String(ki[0]), ev_title(current_event, text), loc("  ·  ".join(meta)), badges, hash(hid))
	event_text = "[font_size=19]%s[/font_size]" % text
	var opts0: Array = current_event["o"]
	var scores: Array = []
	var best := -1
	var bsc := -1e9
	var smin := 1e9
	for k0 in opts0.size():
		var sc0: float = ev_opt_score(opts0[k0])
		scores.append(sc0)
		smin = minf(smin, sc0)
		if sc0 > bsc and (spec != "" or ev_opt_block(opts0[k0]) == ""):
			bsc = sc0
			best = k0
	# v50: рекомендации советника по выбору варианта убраны (по просьбе игрока): решать нужно самому, по последствиям
	var adv := ""
	best = -1
	if not hh.is_empty():
		var po: int = int(hh.get("o", 0))
		if po < opts0.size():
			adv += ("\n" if adv != "" else "") + "[color=%s]В прошлый раз (%d мес. назад) вы выбрали:[/color] «%s»." % [COL_DIM, turn - int(hh["t"]), coal_text(ev_text(String(opts0[po]["l"])))]
	if ev_adv != null:
		ev_adv.text = "[font_size=14]%s[/font_size]" % adv
		ev_adv.visible = adv != ""
	event_label.text = event_text
	ev_ctx.text = ev_context_text()
	var opts: Array = current_event["o"]
	for i in event_buttons.size():
		(event_boxes[i] as Control).visible = i < opts.size()
		if i < opts.size():
			var b: Button = event_buttons[i]
			var o: Dictionary = opts[i]
			var ccost: float = -float((o["fx"] as Dictionary).get("capital", 0.0))
			var csuf := ""
			if ccost >= 0.5:
				csuf = "   [цена: %.0f капитала%s]" % [ccost, ", капитал уйдёт в минус" if capital < ccost else ""]
			elif ccost <= -0.5:
				csuf = "   [+%.0f капитала]" % -ccost
			b.text = "%d   %s%s" % [i + 1, coal_text(ev_text(strip_capital_note(String(o["l"])))), csuf]
			var d := describe_fx(o["fx"], event_region)
			b.tooltip_text = ("Последствия: " + d) if d != "" else "Без прямых последствий"
			var blk: String = ev_opt_block(o) if spec == "" else ""
			b.disabled = blk != ""
			var cn := council_event_note(i)
			var extra := ""
			if o.has("risk"):
				var rk: Dictionary = o["risk"]
				extra += "\n[color=%s]⚠ Риск %.0f%%:[/color] %s" % [COL_WARN, float(rk.get("p", 0.0)) * 100.0, ev_text(String(rk.get("t", "")))]
				var rd := describe_fx(rk.get("fx", {}), event_region)
				if rd != "":
					extra += " [color=%s](%s)[/color]" % [COL_DIM, rd]
			if o.has("later"):
				var lt: Dictionary = o["later"]
				extra += "\n[color=%s]⏳ Через %d мес.:[/color] %s" % [COL_TEAL, int(lt.get("m", 6)), describe_fx(lt.get("fx", {}), event_region)]
			if o.has("next"):
				extra += "\n[color=%s]↪ Продолжение: у этого решения может быть следующая глава истории.[/color]" % COL_DIM
			if blk != "":
				extra += "\n[color=%s]✖ Недоступно: %s[/color]" % [COL_BAD, blk]
			var stars := ""
			(event_fx_rts[i] as RichTextLabel).text = "[font_size=13]%s%s%s%s[/font_size]" % [(stars + "\n") if stars != "" else "", fx_pros_cons(fx_no_capital(o["fx"]), event_region), extra, ("\n[color=%s]%s[/color]" % [COL_DIM, cn]) if cn != "" else ""]
			var card: PanelContainer = event_boxes[i]
			var bcol: Color = C_TEAL if i == best else kc.darkened(0.45)
			var csb := sbox(C_PANEL2.darkened(0.18) if blk == "" else C_PANEL.darkened(0.2), bcol, 2 if i == best else 1, 10, 4.0, 3.0)
			csb.shadow_color = Color(bcol.r, bcol.g, bcol.b, 0.18 if i == best else 0.0)
			csb.shadow_size = 6 if i == best else 0
			card.add_theme_stylebox_override("panel", csb)
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
	var xreg: Array = []
	for ex in EVENTS_X:
		if bool(ex.get("chain", false)) or not event_ok(ex):
			continue
		if bool(ex.get("rreg", false)):
			xreg.append(ex)
		else:
			pool.append(ex)
	if not xreg.is_empty() and randf() < 0.25 and not regions.is_empty():
		var xr: Dictionary = ev_pick(xreg)
		if not xr.is_empty():
			current_event = xr
			event_region = ev_rand_region()
			if auto_event_ok(xr):
				auto_resolve_event()
			else:
				present_event()
			return
	for e in EVENTS + econ_pool() + EVENTS_C + EVENTS_C + radical_events() + reg_events_all():
		if ccode != "DE" and not e.has("reg") and ev_de_only(String(e.get("t", ""))) and not EVENTS_C.has(e):
			continue
		if e.has("reg"):
			if not ev_org_blocked(String(e.get("t", ""))):
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
		chosen = ev_pick(pool)
		if chosen.is_empty():
			return
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
	if special == "" and ev_opt_block(opts[i]) != "":
		i = ev_first_ok(opts)     # v46_1: недоступный вариант (нет капитала) — берётся первый доступный
	var fx_in: Dictionary = opts[i]["fx"]
	if council_event_ok():
		# v35: событие решает совет коалиции; затраты капитала делятся по влиянию
		i = council_event(i)
		# v49: совет коалиции тоже не выбирает вариант, на который нет капитала
		if special == "" and ev_opt_block(opts[i]) != "":
			i = ev_first_ok(opts)
		fx_in = council_split(opts[i]["fx"])
	var opt: Dictionary = opts[i]
	var eff := apply_fx(fx_in, event_region)
	log_line("[color=%s]    ► Выбрано:[/color] «%s». %s" % [COL_DIM, ev_text(String(opt["l"])), ("[color=%s]Последствия:[/color] %s." % [COL_DIM, eff]) if eff != "" else "Прямых последствий нет."])
	if special == "":
		var res := ev_after_choice(current_event, opt, i, event_region)
		if res != "":
			log_line("        %s" % res)
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
	elif special == "coal":
		coal_resolve(opt)
	elif special == "offer":
		opp_resolve_offer(i)
	elif special == "fleet":
		fleet_resolve(i)
	elif special == "war":
		mil_resolve(i)
	elif special == "revolt":
		revolt_resolve(opt)
	elif special == "rl":
		realism_resolve(opt)
	elif special == "reg60":
		reg60_resolve(opt)
	elif special == "uq60":
		uq_resolve(opt)
	refresh()


func dip_events() -> void:
	if not current_event.is_empty() or dip.is_empty():
		return
	var summit_months := [3, 6, 10, 12]
	if month in summit_months and turn - dip_last_summit >= 2 and randf() < 0.42:
		dip_last_summit = turn
		# v46_1: тема саммита не повторяется 18 месяцев (несколько попыток найти свежую)
		var ev: Dictionary = {}
		for _try in 5:
			# v53: саммиты — только организаций, в которых страна состоит (Германия вне ЕС тоже не зовётся на саммит ЕС)
			var cand: Dictionary = DIP_SUMMITS[randi() % DIP_SUMMITS.size()] if (ccode == "DE" and io_member("eu")) else gen_dip_event(true)
			if cand.is_empty():
				break
			var hc: Dictionary = ev_hist.get(ev_id(cand), {})
			if hc.is_empty() or turn - int(hc["t"]) >= 18:
				ev = cand
				break
		if ev.is_empty():
			return
		current_event = ev
		event_region = -1
		if auto_event_ok(ev):
			auto_resolve_event()
		else:
			present_event()
		return
	if randf() < 0.06:
		var ev2: Dictionary = DIP_EVENTS[randi() % DIP_EVENTS.size()] if (ccode == "DE" and io_member("eu")) else gen_dip_event(false)
		current_event = ev2
		event_region = -1
		if auto_event_ok(ev2):
			auto_resolve_event()
		else:
			present_event()


# v53: саммиты организаций, в которых состоит страна (раньше «Саммит ЕС» приходил и России, и Швейцарии)
const SUMMIT_ORGS := ["eu", "nato", "un", "osce", "coe", "csto", "eaeu", "cis"]


func dip_summit_orgs() -> Array:
	var out: Array = []
	for o in SUMMIT_ORGS:
		if io_member(String(o)):
			out.append(String(o))
	return out


func gen_dip_event(summit: bool) -> Dictionary:
	var oth: Array = DIP_ORDER.duplicate()
	var org := ""
	if summit:
		var orgs := dip_summit_orgs()
		if orgs.is_empty():
			return {}
		org = String(orgs[randi() % orgs.size()])
		# партнёры по саммиту — члены той же организации
		var mem: Array = io_members(org)
		var both: Array = oth.filter(func(c) -> bool: return c in mem)
		if not both.is_empty():
			oth = both
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
		match org:
			"nato":
				kinds = [
					{"t": "Саммит НАТО: союзники обсуждают новую цель расходов на оборону — 3,5% ВВП к 2035 году.", "o": [
						{"l": "Поддержать новую цель (долг +0.3% ВВП)", "fx": {"debt": 0.3, "dip": allp, "state": {"security_lvl": 2.0}, "support": {"Силовики": 3.0, "Пенсионеры": -1.0}}},
						{"l": "Просить отсрочку: бюджет не выдержит", "fx": {"dip": {p: -4.0}, "support": {"Пенсионеры": 1.0}}},
						{"l": "Компромисс: рост расходов по графику (капитал -4)", "fx": {"capital": -4.0, "dip": allp_m}}]},
					{"t": "Саммит НАТО: усиление восточного фланга. %s просит прислать войска и технику для передового присутствия." % pn, "o": [
						{"l": "Направить батальон (долг +0.2% ВВП)", "fx": {"debt": 0.2, "dip": {p: 7.0}, "state": {"security_lvl": 1.0}, "support": {"Силовики": 2.0}}},
						{"l": "Ограничиться деньгами на общий фонд (капитал -2)", "fx": {"capital": -2.0, "dip": {p: 2.0}}},
						{"l": "Отказаться: наши войска нужны дома", "fx": {"dip": {p: -6.0}, "support": {"Силовики": -1.0}}}]},
					{"t": "Саммит НАТО: спор о поставках оружия Украине и общем фонде закупок.", "o": [
						{"l": "Увеличить вклад (долг +0.2% ВВП)", "fx": {"debt": 0.2, "dip": allp, "support": {"Молодёжь": 1.0, "Пенсионеры": -1.0}}},
						{"l": "Сохранить прежний уровень", "fx": {"dip": allp_m}},
						{"l": "Выступить за переговоры вместо оружия", "fx": {"dip": allp_n, "support": {"Пенсионеры": 2.0}}}]}]
			"un":
				kinds = [
					{"t": "Генеральная Ассамблея ООН голосует по резолюции о гуманитарном перемирии в крупном конфликте.", "o": [
						{"l": "Голосовать «за» вместе с большинством", "fx": {"dip_all": 1.0, "support": {"Молодёжь": 1.0}}},
						{"l": "Воздержаться", "fx": {"capital": 1.0}},
						{"l": "Голосовать «против» вслед за союзником", "fx": {"dip": {p: 3.0}, "dip_all": -1.0}}]},
					{"t": "ООН просит взнос в фонд помощи беженцам и миротворческим миссиям.", "o": [
						{"l": "Внести щедрый взнос (долг +0.1% ВВП)", "fx": {"debt": 0.1, "dip_all": 1.0}},
						{"l": "Обычный взнос", "fx": {}},
						{"l": "Отказаться: у нас свои беженцы", "fx": {"dip_all": -1.0, "support": {"Силовики": 1.0}}}]}]
			"osce":
				kinds = [
					{"t": "Совет министров ОБСЕ спорит о мандате миссий наблюдателей и бюджете организации.", "o": [
						{"l": "Поддержать продление миссий (капитал -2)", "fx": {"capital": -2.0, "dip": allp_m}},
						{"l": "Требовать сократить бюджет", "fx": {"dip": {p: -3.0}, "support": {"Бизнес": 1.0}}}]}]
			"coe":
				kinds = [
					{"t": "ПАСЕ готовит доклад о свободе СМИ и независимости судов. %s предлагает смягчить формулировки." % pn, "o": [
						{"l": "Поддержать жёсткий доклад", "fx": {"dip_all": 0.5, "dip": {p: -3.0}, "support": {"Молодёжь": 1.0}}},
						{"l": "Согласиться на компромисс (капитал -2)", "fx": {"capital": -2.0, "dip": {p: 3.0}}}]}]
			"csto":
				kinds = [
					{"t": "Саммит ОДКБ: Москва предлагает расширить коллективные силы быстрого реагирования и провести совместные учения.", "o": [
						{"l": "Выделить контингент (долг +0.2% ВВП)", "fx": {"debt": 0.2, "dip": {p: 6.0}, "state": {"security_lvl": 1.0}, "support": {"Силовики": 3.0}}},
						{"l": "Участвовать символически", "fx": {"dip": {p: 1.0}}},
						{"l": "Уклониться: «у нас другие приоритеты»", "fx": {"dip": {p: -6.0}, "support": {"Молодёжь": 1.0}}}]},
					{"t": "Саммит ОДКБ: %s просит союзников о военной помощи на границе." % pn, "o": [
						{"l": "Отправить инструкторов и технику (долг +0.1% ВВП)", "fx": {"debt": 0.1, "dip": {p: 7.0}, "support": {"Силовики": 2.0}}},
						{"l": "Ограничиться заявлением", "fx": {"dip": {p: -3.0}}}]}]
			"eaeu":
				kinds = [
					{"t": "Высший Евразийский экономический совет: спор о единых пошлинах и допуске товаров друг друга.", "o": [
						{"l": "Согласиться на общие правила", "fx": {"dip": allp, "shock": 0.1, "support": {"Бизнес": 1.0, "Село": -1.0}}},
						{"l": "Защищать свой рынок", "fx": {"dip": {p: -4.0}, "support": {"Село": 2.0, "Рабочие": 1.0}}},
						{"l": "Компромисс с изъятиями (капитал -3)", "fx": {"capital": -3.0, "dip": allp_m}}]},
					{"t": "ЕАЭС обсуждает общий рынок газа и нефти: %s хочет единых цен." % pn, "o": [
						{"l": "Поддержать единые цены", "fx": {"dip": {p: 5.0}, "support": {"Бизнес": -1.0}}},
						{"l": "Требовать скидку для себя", "fx": {"dip": {p: -3.0}, "support": {"Рабочие": 1.0}}}]}]
			"cis":
				kinds = [
					{"t": "Саммит СНГ: обсуждаются взаимное признание дипломов и трудовая миграция.", "o": [
						{"l": "Поддержать облегчение миграции", "fx": {"dip": allp, "support": {"Бизнес": 2.0, "Силовики": -1.0}}},
						{"l": "Ужесточить правила для мигрантов", "fx": {"dip": allp_n, "support": {"Силовики": 2.0, "Рабочие": 1.0}}}]}]
			_:
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
		for kd in kinds:
			(kd as Dictionary)["org"] = org
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
