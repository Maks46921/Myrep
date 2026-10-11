# Дипломатия и живой мир.
extends "res://scripts/logic/turn.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func ex_bot_g(c: String) -> float:
	return 0.0


func fa_explain(c: String) -> String:
	return ""


func fa_rel_term(c: String) -> float:
	return 0.0


func mil_dip_term(c: String) -> float:
	return 0.0


func open_mult(c: String) -> float:
	return 0.0


# --- конец заглушек ---


func foreign_region_text() -> String:
	if map_sel_unit < 0 or String(WORLD_UNITS[map_sel_unit]["cc"]) != dip_sel:
		return ""
	var id: String = String(WORLD_UNITS[map_sel_unit]["id"])
	for r in WORLD[dip_sel]["regions"]:
		if String(r["id"]) != id:
			continue
		var t := "\n[b][font_size=16]Регион: %s[/font_size][/b]\n[color=%s]%s[/color]\n" % [r["name"], COL_DIM, r["desc"]]
		t += "Население %.1f млн · ВВП на душу %.0f%% от среднего · развитие %.0f · лояльность власти %.0f · недовольство %.0f\n" % [float(r["popm"]), float(r["pc"]) * 100.0 / 0.85, float(r["dev"]), float(r["loy"]), float(r["unrest"])]
		t += "Инфраструктура %.0f · образование %.0f · здравоохранение %.0f · экология %.0f\n" % [float(r["infra"]), float(r["edu"]), float(r["health"]), float(r["env"])]
		var order: Array = []
		for p in (r["sh"] as Array).size():
			order.append([float(r["sh"][p]), p])
		order.sort_custom(func(a, b): return a[0] > b[0])
		var parts: PackedStringArray = []
		for k in 3:
			parts.append("%s %.0f%%" % [WORLD[dip_sel]["pn"][int(order[k][1])], float(order[k][0]) * 100.0])
		t += "По голосам на последних выборах лидируют: %s\n" % ", ".join(parts)
		return t + "\n"
	return ""


func dip_init() -> void:
	dip.clear()
	for c in DIP_ORDER:
		var d: Dictionary = DIP_C[c]
		dip[c] = {"rel": float(d["rel0"]), "lv": (d["lv0"] as Dictionary).duplicate(), "cd": {}}
	dip_sel = String(DIP_ORDER[0])


func dip_rel_name(r: float) -> String:
	for it in DIP_REL_NAMES:
		if r >= float(it[0]):
			return String(it[1])
	return "кризис"


func dip_target(c: String) -> float:
	var d: Dictionary = DIP_C[c]
	var t: float = float(d["rel0"]) + 4.0 * (float(mods["dip_bonus"]) - dip_bonus0)
	var likes: Dictionary = DIP_LIKES[c]
	for tid in likes:
		var idx: int = cur_idx(tid)
		if (likes[tid] as Dictionary).has(idx):
			t += float(likes[tid][idx])
	var lv: Dictionary = dip[c]["lv"]
	var dl := 0
	for k in lv:
		dl += int(lv[k]) - int((d["lv0"] as Dictionary)[k])
	t += 2.0 * float(dl) + mil_dip_term(c) + fa_rel_term(c)
	return clampf(t, 5.0, 98.0)


func dip_rel_factor(c: String) -> float:
	var d: Dictionary = DIP_C[c]
	var den: float = float(d["rel0"]) - 35.0
	if absf(den) < 0.5:          # v38: стартовое отношение ровно 35 (Северная Македония — Болгария) давало 0/0 и NaN во всей экономике
		den = 0.5
	return clampf((float(dip[c]["rel"]) - 35.0) / den, 0.0, 1.5)


func dip_growth() -> float:
	var g := 0.0
	for c in DIP_ORDER:
		var d: Dictionary = DIP_C[c]
		var lv: Dictionary = dip[c]["lv"]
		var l0: Dictionary = d["lv0"]
		var f := dip_rel_factor(c)
		var lvl_fx: float = 0.05 * float(int(lv["trade"]) - int(l0["trade"])) + 0.02 * float(int(lv["energy"]) - int(l0["energy"]))
		g += float(d["w"]) * (lvl_fx * f * 3.0)
		var dr: float = float(dip[c]["rel"]) - float(d["rel0"])
		g += float(d["w"]) * (0.10 * dr / 20.0 if dr < 0.0 else 0.04 * dr / 20.0)
	return g


func dip_sec() -> float:
	var s := 0.0
	for c in DIP_ORDER:
		var d: Dictionary = DIP_C[c]
		var dl: int = int(dip[c]["lv"]["sec"]) - int((d["lv0"] as Dictionary)["sec"])
		s += float(d["w"]) * 0.8 * float(dl) * dip_rel_factor(c) * 3.0
	return s


func dip_infra_bonus() -> float:
	var s := 0.0
	for c in DIP_ORDER:
		var d: Dictionary = DIP_C[c]
		var dl: int = int(dip[c]["lv"]["energy"]) - int((d["lv0"] as Dictionary)["energy"])
		s += float(d["w"]) * 0.02 * float(dl) * 3.0
	return s


func dip_avg_rel() -> float:
	var s := 0.0
	for c in DIP_ORDER:
		s += float(dip[c]["rel"]) * float((DIP_C[c] as Dictionary)["w"])
	return s


func dip_apply_mods() -> void:
	if dip.is_empty():
		return
	mods["growth_bonus"] = float(mods["growth_bonus"]) + dip_growth()
	mods["sec_bonus"] = float(mods["sec_bonus"]) + dip_sec()
	mods["capital_bonus"] = float(mods["capital_bonus"]) + clampf((dip_avg_rel() - 70.0) * 0.004, -0.15, 0.15)


func dip_change(c: String, delta: float) -> void:
	if not dip.has(c):
		return
	dip[c]["rel"] = clampf(float(dip[c]["rel"]) + delta, 0.0, 100.0)


func dip_step() -> void:
	if dip.is_empty():
		return
	for c in DIP_ORDER:
		var cur: float = float(dip[c]["rel"])
		var tg := dip_target(c)
		dip[c]["rel"] = clampf(cur + (tg - cur) * 0.04 + randf_range(-0.25, 0.25), 0.0, 100.0)
		var cd: Dictionary = dip[c]["cd"]
		for k in cd:
			cd[k] = maxi(0, int(cd[k]) - 1)
		if float(dip[c]["rel"]) < 28.0 and randf() < 0.04:
			var lv: Dictionary = dip[c]["lv"]
			var keys: Array = []
			for k in lv:
				if int(lv[k]) > 0:
					keys.append(k)
			if not keys.is_empty():
				var kk: String = keys[randi() % keys.size()]
				lv[kk] = int(lv[kk]) - 1
				log_tag("ДИПЛОМАТИЯ", COL_BAD, "%s: из-за кризиса в отношениях (%s) %s снижено до уровня %d." % [date_text(), DIP_C[c]["name"], track_name(kk).to_lower(), int(lv[kk])])


func track_name(id: String) -> String:
	for t in DIP_TRACKS:
		if t["id"] == id:
			return String(t["name"])
	return id


func dip_fx_apply(dd: Dictionary) -> void:
	for c in dd:
		dip_change(String(c), float(dd[c]))


func dip_fx_text(dd: Dictionary) -> String:
	var parts: PackedStringArray = []
	for c in dd:
		if DIP_C.has(c):
			parts.append("%s %s" % [DIP_C[c]["name"], sg(float(dd[c]), 0)])
	return "отношения: " + ", ".join(parts)


func dip_do_action(id: String) -> void:
	if game_over:
		return
	var a: Dictionary = find_by_id(DIP_ACTIONS, id)
	var cd: Dictionary = dip[dip_sel]["cd"]
	if int(cd.get(id, 0)) > 0 or capital < float(a["cap"]):
		return
	capital -= float(a["cap"])
	if float(a["money"]) > 0.0:
		debt += gdp * float(a["money"]) / 100.0
	cd[id] = int(a["cd"])
	dip_change(dip_sel, float(a["rel"]))
	var eff := apply_fx(a["fx"])
	log_tag("ДИПЛОМАТИЯ", COL_TEAL, "%s — %s: «%s». Отношения %s%s." % [date_text(), DIP_C[dip_sel]["name"], a["name"], sg(float(a["rel"]), 0), (", " + eff) if eff != "" else ""])
	refresh()


func dip_track_cost(c: String, tid: String) -> Array:
	var L: int = int(dip[c]["lv"][tid])
	return [4.0 + 3.0 * float(L), 0.06 * float(L + 1), 40.0 + 8.0 * float(L)]


func dip_upgrade(tid: String) -> void:
	if game_over:
		return
	var L: int = int(dip[dip_sel]["lv"][tid])
	if L >= 3:
		return
	var cost := dip_track_cost(dip_sel, tid)
	var cd: Dictionary = dip[dip_sel]["cd"]
	if capital < float(cost[0]) or float(dip[dip_sel]["rel"]) < float(cost[2]) or int(cd.get("t_" + tid, 0)) > 0:
		return
	capital -= float(cost[0])
	debt += gdp * float(cost[1]) / 100.0
	cd["t_" + tid] = 8
	dip[dip_sel]["lv"][tid] = L + 1
	dip_change(dip_sel, 3.0)
	log_tag("ДИПЛОМАТИЯ", COL_GOOD, "%s — %s: соглашение «%s» углублено до уровня %d (политкапитал -%.0f, расходы %.2f%% ВВП)." % [date_text(), DIP_C[dip_sel]["name"], track_name(tid), L + 1, float(cost[0]), float(cost[1])])
	refresh()


func dip_downgrade(tid: String) -> void:
	if game_over:
		return
	var L: int = int(dip[dip_sel]["lv"][tid])
	if L <= 0:
		return
	dip[dip_sel]["lv"][tid] = L - 1
	dip_change(dip_sel, -5.0)
	log_tag("ДИПЛОМАТИЯ", COL_WARN, "%s — %s: соглашение «%s» сокращено до уровня %d. Отношения -5." % [date_text(), DIP_C[dip_sel]["name"], track_name(tid), L - 1])
	refresh()


func w_codes() -> Array:
	var out: Array = []
	for c in WORLD:
		out.append(String(c))
	return out


# v49: непризнанные образования (ПМР, ДНР, ЛНР) и новые государства из отделившихся регионов (SEP…): есть на карте и в мировой
# симуляции, но не играбельны, без пакета данных, торговых соглашений, разведки и внешнеполитического ИИ
func w_unrec(c: String) -> bool:
	return WORLD.has(c) and bool((WORLD[c] as Dictionary).get("unrec", false))


func w_minor(c: String) -> bool:
	return c.begins_with("SEP") or w_unrec(c)


func world_init() -> void:
	wsim.clear()
	for c in WORLD:
		var d: Dictionary = WORLD[c]
		var elapsed: int = int(CDATA[c]["MACRO"]["elapsed"]) if CDATA.has(c) else 12
		var term: int = int(CDATA[c]["MACRO"]["parl_term"]) if CDATA.has(c) else 48
		wsim[c] = {
			"gdp": float(d["gdp"]), "growth": float(d["growth"]), "infl": float(d["infl"]), "unemp": float(d["unemp"]),
			"debt": float(d["debt"]) / float(d["gdp"]) * 100.0, "def": float(d["def"]),
			"stab": float(d["stab"]), "appr": float(d["appr"]), "stance": W_STANCE0.get(c, 0.0),
			"gov": String(d["gov"]), "crisis": {}, "next_elec": term - elapsed, "pot": float(d["pot"]),
			"gdp_hist": [float(d["gdp"])], "g_hist": [float(d["growth"])], "i_hist": [float(d["infl"])],
		}
	w_pot_player = G_POT
	w_shock = {}
	w_stress = 0.0
	ea_rest = 2.0
	w_crises_log.clear()


func w_stance_name(s: float) -> String:
	if s < -0.5:
		return "левое"
	if s < -0.15:
		return "левоцентристское"
	if s <= 0.15:
		return "центристское"
	if s <= 0.5:
		return "правоцентристское"
	return "правое"


# вес торговли страны a со страной b (для спилловеров)
# v49: стартовые санкции: торговля страны под санкциями с ЕС и присоединившимися к санкциям сократилась примерно вчетверо
const W_SANCT0 := ["RU", "BY"]
const W_SANCT_JOIN := ["GB", "NO", "CH", "AL", "ME", "MK", "XK", "UA", "MD"]


# v49: насколько экономики связаны: санкции режут связь (на 75%), непризнанные образования торгуют через покровителя
func w_link(a: String, b: String) -> float:
	if w_unrec(a) or w_unrec(b):
		return 0.15
	var sa: bool = a in W_SANCT0
	var sb: bool = b in W_SANCT0
	if sa == sb:
		return 1.0
	var o: String = b if sa else a
	if bool((WORLD[o] as Dictionary).get("eu", false)) or o in W_SANCT_JOIN:
		return 0.25
	return 1.0


func w_share(a: String, b: String) -> float:
	var tot := 0.0
	for c in wsim:
		if c == a:
			continue
		tot += pow(float(wsim[c]["gdp"]), 0.7) * w_link(a, c)
	if tot <= 0.0:
		return 0.0
	return float(W_OPEN.get(a, 0.4)) * open_mult(a) * pow(float(wsim[b]["gdp"]), 0.7) * w_link(a, b) / tot


func w_cur_growth(c: String) -> float:
	if c == ccode:
		return growth
	return float(wsim[c]["growth"])


func w_pot(c: String) -> float:
	return w_pot_player if c == ccode else float(wsim[c]["pot"])


func world_spill_g() -> float:
	if wsim.is_empty():
		return 0.0
	var s := 0.0
	for c in wsim:
		if c == ccode:
			continue
		s += w_share(ccode, c) * (float(wsim[c]["growth"]) - float(wsim[c]["pot"])) * 0.30
	s += w_shock_g(ccode)
	if bool(WORLD[ccode].get("euro", false)) or bool(WORLD[ccode].get("eu", false)):
		s -= w_stress * 0.12
	return s


func w_shock_g(c: String) -> float:
	if w_shock.is_empty():
		return 0.0
	return float(w_shock["g"]) * clampf(float(W_OPEN.get(c, 0.4)), 0.2, 1.0)


func world_spill_infl() -> float:
	var s := 0.0
	for c in wsim:
		if c == ccode:
			continue
		s += w_share(ccode, c) * (float(wsim[c]["infl"]) - float(wsim[ccode]["infl"] if wsim.has(ccode) else 2.0)) * 0.2
	if not w_shock.is_empty():
		s += float(w_shock["infl"]) * 0.8 * clampf(float(W_OPEN.get(ccode, 0.4)), 0.2, 1.0)
	return s


func world_ea_update() -> void:
	ea_rest += (2.0 - ea_rest) * 0.05 + randf_range(-0.10, 0.10)
	var tw := 0.0
	var sm := 0.0
	for c in wsim:
		if not bool(WORLD[c].get("euro", true)):
			continue
		var wgt: float = float(wsim[c]["gdp"])
		var inf: float = inflation if c == ccode else float(wsim[c]["infl"])
		sm += wgt * inf
		tw += wgt
	var core: float = sm / maxf(tw, 1.0)
	ea_infl = 0.62 * core + 0.38 * ea_rest


func w_start_crisis(c: String, kind: Dictionary) -> void:
	var w: Dictionary = wsim[c]
	w["crisis"] = {"id": kind["id"], "n": kind["n"], "left": int(kind["dur"]) + randi() % 4}
	var name: String = String(WORLD[c]["name"])
	var good: bool = kind["id"] == "boom"
	var txt := ""
	match String(kind["id"]):
		"gov":
			txt = "%s: правительство потеряло большинство и ушло в отставку, назначены досрочные выборы." % name
		"bank":
			txt = "%s: банковский кризис, вкладчики выстраиваются в очереди, рынки нервничают." % name
		"energy":
			txt = "%s: энергетический кризис, цены на электричество и газ резко выросли." % name
		"strike":
			txt = "%s: общенациональные забастовки парализовали транспорт и школы." % name
		"riots":
			txt = "%s: массовые беспорядки в крупных городах, на улицах полиция." % name
		"debt":
			txt = "%s: инвесторы теряют доверие к государственному долгу, ставки по облигациям растут." % name
		"boom":
			txt = "%s: инвестиционный бум — приходят иностранные заводы и дата-центры." % name
	log_tag("МИР", COL_GOOD if good else COL_WARN, "%s — %s" % [date_text(), txt])
	w_crises_log.append({"turn": turn, "c": c, "id": kind["id"], "t": txt})
	if w_crises_log.size() > 40:
		w_crises_log.pop_front()
	if kind["id"] == "bank":
		w_stress = minf(1.0, w_stress + 0.30 * clampf(float(w_share(ccode, c)) * 8.0 + 0.4, 0.4, 1.0))
	elif kind["id"] == "debt":
		w_stress = minf(1.0, w_stress + (0.45 if bool(WORLD[c].get("euro", false)) else 0.25))
	if kind["id"] == "gov":
		w["next_elec"] = 3
	# событие помощи, если соседняя страна важна для торговли
	if not good and c != ccode and DIP_C.has(c) and w_share(ccode, c) >= 0.045 and current_event.is_empty() and randf() < 0.65:
		w_help_event(c, kind)


func world_help(c: String) -> void:
	if not wsim.has(c):
		return
	var cr: Dictionary = wsim[c]["crisis"]
	if cr.is_empty():
		return
	cr["left"] = maxi(1, int(cr["left"]) - 4)
	wsim[c]["stab"] = clampf(float(wsim[c]["stab"]) + 4.0, 0.0, 100.0)


func w_election(c: String) -> void:
	var w: Dictionary = wsim[c]
	var name: String = String(WORLD[c]["name"])
	var old: float = float(w["stance"])
	var swing: float = randf_range(-0.45, 0.45) - (float(w["appr"]) - 45.0) / 100.0 * 0.5 * signf(old if absf(old) > 0.05 else 0.1)
	w["stance"] = clampf(old * 0.5 + swing, -0.9, 0.9)
	var term: int = int(CDATA[c]["MACRO"]["parl_term"]) if CDATA.has(c) else 48
	w["next_elec"] = term
	w["appr"] = clampf(50.0 + randf_range(-6.0, 8.0), 15.0, 80.0)
	w["stab"] = clampf(float(w["stab"]) + 8.0, 0.0, 100.0)
	var pi: int = w_party_for(c, float(w["stance"]), (50.0 - float(w["appr"])) / 50.0 + 0.3)
	if pi >= 0:
		w["gov"] = "правительство партии «%s» (выборы %s %d)" % [w_party_name(c, pi), MONTHS[month - 1], year]
	else:
		w["gov"] = "%s правительство (после выборов %s %d)" % [w_stance_name(float(w["stance"])), MONTHS[month - 1], year]
	var shifted := ""
	if absf(float(w["stance"]) - old) > 0.3:
		shifted = " Политический курс сместился: %s." % ("вправо" if float(w["stance"]) > old else "влево")
	var who: String = ("партия «%s»" % w_party_name(c, pi)) if pi >= 0 else ("%s правительство" % w_stance_name(float(w["stance"])))
	log_tag("МИР", COL_HEAD, "%s — выборы в стране «%s»: у власти %s.%s" % [date_text(), name, who, shifted])
	if DIP_C.has(c):
		# отношения подстраиваются под политический курс: общий язык с похожим по взглядам правительством
		var mine: float = w_player_stance()
		var d: float = -absf(float(w["stance"]) - mine) * 6.0 + 3.0
		dip_change(c, d)


func w_player_stance() -> float:
	# от -1 (левая политика) до +1 (правая): налоги и соцрасходы против базовых
	var s := 0.0
	s -= (float(pol["income"]) - float(pol_def["income"])) * 0.08
	s -= (float(pol["corp"]) - float(pol_def["corp"])) * 0.10
	s += (float(pol_def["benefits"]) - float(pol["benefits"])) * 0.15
	s += (float(pol_def["pensions"]) - float(pol["pensions"])) * 0.10
	return clampf(s, -1.0, 1.0)


func w_shock_step() -> void:
	w_stress *= 0.94
	if not w_shock.is_empty():
		w_shock["left"] = int(w_shock["left"]) - 1
		if int(w_shock["left"]) <= 0:
			log_tag("МИР", COL_GOOD, "%s — мировая обстановка успокаивается: завершено (%s)." % [date_text(), String(w_shock["n"])])
			w_shock = {}
		return
	if randf() >= 0.009:
		return
	var opts := [
		{"id": "energy", "n": "мировой энергетический шок", "g": -0.45, "infl": 1.2, "dur": 9, "t": "Цены на нефть и газ взлетели из-за перебоев с поставками: дорожают топливо и электричество во всех странах."},
		{"id": "recess", "n": "мировая рецессия", "g": -0.85, "infl": -0.3, "dur": 12, "t": "Мировая торговля сжимается, заказы падают: экономики открытых стран замедляются."},
		{"id": "boom", "n": "глобальный подъём", "g": 0.5, "infl": 0.25, "dur": 10, "t": "Мировой спрос растёт, экспорт на подъёме: страны Европы получают попутный ветер."},
		{"id": "trade", "n": "торговая война", "g": -0.4, "infl": 0.5, "dur": 10, "t": "Крупные державы ввели взаимные пошлины: цепочки поставок рвутся, цены растут."},
	]
	var o: Dictionary = opts[randi() % opts.size()]
	w_shock = {"id": o["id"], "n": o["n"], "g": o["g"], "infl": o["infl"], "left": int(o["dur"]) + randi() % 4}
	log_tag("МИР", COL_GOOD if o["id"] == "boom" else COL_WARN, "%s — %s. %s" % [date_text(), String(o["n"]).capitalize(), o["t"]])


func w_party_name(c: String, i: int) -> String:
	if c == "DE":
		return ["ХДС/ХСС", "СДПГ", "СвДП", "Левые", "Зелёные", "BSW", "Прочие партии", "Volt", "Свободные избиратели", "АдГ"][i]
	return String(CDATA[c]["PARTY_NAMES"][i])


func w_party_for(c: String, stance: float, discontent: float) -> int:
	var archs: Array = CDATA[c].get("PARCH", []) if CDATA.has(c) else []
	if archs.is_empty():
		return -1
	var want: Array = []
	if randf() < clampf(discontent * 0.6, 0.0, 0.3):
		want = ["popr", "none"] if stance > 0.0 else ["popl", "left", "none"]
	elif stance < -0.5:
		want = ["left", "soc", "popl"]
	elif stance < -0.15:
		want = ["soc", "green", "left"]
	elif stance <= 0.15:
		want = ["lib", "own", "euro", "cons", "soc"]
	elif stance <= 0.5:
		want = ["cons", "lib", "own"]
	else:
		want = ["popr", "cons"]
	var cand: Array = []
	for i in range(archs.size()):
		if String(archs[i]) in want and i != 6:
			cand.append(i)
	if cand.is_empty():
		return -1
	return int(cand[randi() % cand.size()])


func wsim_step() -> void:
	if wsim.is_empty():
		return
	w_shock_step()
	for c in wsim:
		var w: Dictionary = wsim[c]
		if c == ccode:
			# состояние страны игрока берём из настоящей симуляции
			w["gdp"] = gdp
			w["growth"] = growth
			w["infl"] = inflation
			w["unemp"] = unemployment
			w["debt"] = debt / gdp * 100.0
			w["def"] = -float(compute_budget()["balance"]) / gdp * 100.0 if turn % 3 == 0 else float(w["def"])
			w["stab"] = clampf(100.0 - reg_avg("unrest") * 1.2, 0.0, 100.0)
			w["appr"] = approval()
			if turn % 3 == 0:
				var gh: Array = w["g_hist"]
				gh.append(growth)
				(w["i_hist"] as Array).append(inflation)
				(w["gdp_hist"] as Array).append(gdp)
			if w_stress > 0.35 and bool(WORLD[c].get("euro", false)) and debt / gdp * 100.0 > 85.0:
				risk_prem = minf(2.0, risk_prem + 0.025 * w_stress)
			continue
		var cr: Dictionary = w["crisis"]
		var ck := {}
		if not cr.is_empty():
			for k in W_KINDS:
				if k["id"] == cr["id"]:
					ck = k
		# --- рост ---
		var pot: float = float(w["pot"])
		var spill := 0.0
		for d in wsim:
			if d == c:
				continue
			var gd: float = growth if d == ccode else float(wsim[d]["growth"])
			var pd: float = w_pot_player if d == ccode else float(wsim[d]["pot"])
			spill += w_share(c, d) * (gd - pd) * 0.30
		var gt: float = pot + spill - maxf(0.0, float(w["debt"]) - 110.0) * 0.012 - maxf(0.0, float(w["infl"]) - 5.0) * 0.2
		gt -= maxf(0.0, float(w["def"]) - float(WORLD[c]["def"]) - 1.0) * 0.0
		if not ck.is_empty():
			gt += float(ck["g"])
		gt += w_shock_g(c) + ex_bot_g(c)
		gt -= w_stress * (0.30 if float(w["debt"]) > 90.0 else 0.10)
		var consol: bool = float(w["debt"]) > 100.0 and float(w["def"]) > 3.5 and ck.is_empty()
		if consol:
			gt -= 0.25
		w["growth"] = float(w["growth"]) + (gt - float(w["growth"])) * 0.28 + randf_range(-0.25, 0.25)
		w["gdp"] = float(w["gdp"]) * (1.0 + float(w["growth"]) / 1200.0)
		# --- инфляция и безработица ---
		var it: float = ea_infl + (float(WORLD[c]["infl"]) - 2.1) * 0.25 + (float(w["growth"]) - pot) * 0.20 + world_infl_bias(c)
		if not ck.is_empty():
			it += float(ck["infl"])
		if not w_shock.is_empty():
			it += float(w_shock["infl"]) * 0.8 * clampf(float(W_OPEN.get(c, 0.4)), 0.2, 1.0)
		w["infl"] = clampf(float(w["infl"]) + (it - float(w["infl"])) * 0.14 + randf_range(-0.08, 0.08), 0.0, 25.0)
		var ut: float = float(WORLD[c]["unemp"]) - (float(w["growth"]) - pot) * 0.6
		w["unemp"] = clampf(float(w["unemp"]) + (ut - float(w["unemp"])) * 0.06, 2.0, 30.0)
		# --- бюджет и долг ---
		var dt: float = float(WORLD[c]["def"]) + (pot - float(w["growth"])) * 0.45
		if not ck.is_empty():
			dt += float(ck["def"])
		if consol:
			dt -= 0.9
		w["def"] = float(w["def"]) + (dt - float(w["def"])) * 0.12
		var db: float = float(w["debt"])
		w["debt"] = db + (float(w["def"]) - float(w["growth"]) * db / 100.0 - 0.0) / 12.0
		# --- стабильность и рейтинг ---
		var st_t: float = float(WORLD[c]["stab"]) - maxf(0.0, float(w["unemp"]) - float(WORLD[c]["unemp"])) * 3.0 - maxf(0.0, float(w["infl"]) - 4.0) * 3.0
		if not ck.is_empty():
			st_t += float(ck["stab"]) * 4.0
		w["stab"] = clampf(float(w["stab"]) + (st_t - float(w["stab"])) * 0.08 + randf_range(-0.6, 0.6), 0.0, 100.0)
		var ap_t: float = float(WORLD[c]["appr"]) + (float(w["growth"]) - pot) * 4.0 - (float(w["infl"]) - float(WORLD[c]["infl"])) * 3.0 - (float(w["unemp"]) - float(WORLD[c]["unemp"])) * 2.0
		w["appr"] = clampf(float(w["appr"]) + (ap_t - float(w["appr"])) * 0.06 + randf_range(-0.8, 0.8), 10.0, 85.0)
		# --- кризис идёт / заканчивается ---
		if not cr.is_empty():
			cr["left"] = int(cr["left"]) - 1
			if int(cr["left"]) <= 0:
				log_tag("МИР", COL_GOOD, "%s — %s: завершено (%s)." % [date_text(), WORLD[c]["name"], String(cr["n"])])
				w["crisis"] = {}
		else:
			var risk: float = (0.005 if consol else 0.0) + 0.011 + maxf(0.0, 50.0 - float(w["stab"])) * 0.0004 + maxf(0.0, float(w["debt"]) - 100.0) * 0.00012 + maxf(0.0, float(w["infl"]) - 4.0) * 0.0015
			if randf() < risk:
				var tot := 0.0
				for k in W_KINDS:
					var pw: float = float(k["p"])
					if k["id"] == "debt":
						pw = 1.2 if float(w["debt"]) > 100.0 and float(w["def"]) > 4.0 else 0.0
					if k["id"] == "gov" and int(w["next_elec"]) < 8:
						pw = 0.0
					tot += pw
				var r: float = randf() * tot
				for k in W_KINDS:
					var pw2: float = float(k["p"])
					if k["id"] == "debt":
						pw2 = 1.2 if float(w["debt"]) > 100.0 and float(w["def"]) > 4.0 else 0.0
					if k["id"] == "gov" and int(w["next_elec"]) < 8:
						pw2 = 0.0
					r -= pw2
					if r <= 0.0:
						w_start_crisis(c, k)
						break
		# --- выборы ---
		w["next_elec"] = int(w["next_elec"]) - 1
		if int(w["next_elec"]) <= 0:
			w_election(c)
	# воздействие кризисов у соседей на страну игрока (отношения со страной в кризисе чуть падают от нестабильности)
	if turn % 6 == 0:
		world_news()
	# обновить историю
	if turn % 3 == 0:
		for c in wsim:
			if c == ccode:
				continue
			(wsim[c]["g_hist"] as Array).append(wsim[c]["growth"])
			(wsim[c]["i_hist"] as Array).append(wsim[c]["infl"])
			(wsim[c]["gdp_hist"] as Array).append(wsim[c]["gdp"])


func world_infl_bias(c: String) -> float:
	return 0.0


func world_news() -> void:
	# короткая сводка: самая «горячая» страна мира
	var worst := ""
	var wv := 100.0
	for c in wsim:
		if c == ccode:
			continue
		if float(wsim[c]["stab"]) < wv:
			wv = float(wsim[c]["stab"])
			worst = c
	var best := ""
	var bv := -9.0
	for c2 in wsim:
		if c2 != ccode and float(wsim[c2]["growth"]) > bv:
			bv = float(wsim[c2]["growth"])
			best = c2
	if best != "" and bv > 2.2 and randf() < 0.3:
		log_tag("МИР", COL_DIM, "%s — экономика страны «%s» лидирует в регионе: рост %.1f%% в годовом выражении." % [date_text(), WORLD[best]["name"], bv])
	if w_stress > 0.5 and randf() < 0.5:
		log_tag("МИР", COL_WARN, "%s — на рынках облигаций тревога: инвесторы боятся долговых проблем в Европе." % date_text())
	if worst != "" and wv < 40.0 and randf() < 0.5:
		log_tag("МИР", COL_WARN, "%s — в стране «%s» нарастает политическая нестабильность (индекс %.0f)." % [date_text(), WORLD[worst]["name"], wv])


func world_info(c: String) -> String:
	var d: Dictionary = WORLD[c]
	var w: Dictionary = wsim[c]
	var is_me: bool = c == ccode
	var t := "[b][font_size=18]%s[/font_size][/b]%s\n" % [d["name"], "  [color=%s](ваша страна)[/color]" % COL_GOOD if is_me else ""]
	t += "[color=%s]%s[/color]\n" % [COL_DIM, d["desc"]]
	t += "Столица: %s · население %.1f млн\n" % [d["cap"], float(d["pop"])]
	t += "ВВП: [b]%s млрд €[/b] · рост [b]%.1f%%[/b] · инфляция [b]%.1f%%[/b] · безработица [b]%.1f%%[/b]\n" % [fmt_n(float(w["gdp"])), float(w["growth"]), float(w["infl"]), float(w["unemp"])]
	t += "Долг: [b]%.0f%% ВВП[/b] · дефицит [b]%.1f%%[/b] · стабильность [b]%.0f[/b] · одобрение власти [b]%.0f%%[/b]\n" % [float(w["debt"]), float(w["def"]), float(w["stab"]), float(w["appr"])]
	t += "Власть: %s\n" % (String(w["gov"]) if not is_me else "ваше правительство")
	var cr: Dictionary = w["crisis"]
	if not cr.is_empty():
		t += "[color=%s][b]Сейчас: %s[/b] (ещё около %d мес.)[/color]\n" % [COL_WARN if cr["id"] != "boom" else COL_GOOD, cr["n"], int(cr["left"])]
	if not is_me and int(w["next_elec"]) > 0:
		t += "Следующие выборы: через %s\n" % months_text(int(w["next_elec"]))
	if not is_me and dip.has(c):
		t += "Отношения с вами: [b]%.0f[/b] (%s) · торговля %s млрд € в год\n" % [float(dip[c]["rel"]), dip_rel_name(float(dip[c]["rel"])), fmt_n(float((DIP_C[c] as Dictionary)["trade"]))]
		t += "Влияние на вашу экономику: рост %s п.п., связано с темпом их роста\n" % sg(w_share(ccode, c) * (float(w["growth"]) - float(w["pot"])) * 0.30, 2)
	if not is_me:
		t += fa_explain(c)
	return t


func remap_base_ps() -> void:
	var srcmap: Array = []
	for p in PARTY_NAMES.size():
		var a: String = String(ARCHS[p]) if p < ARCHS.size() else "oth"
		var m := -1
		match a:
			"own": m = 0
			"soc": m = 1
			"lib": m = 2
			"left": m = 3
			"green": m = 4
			"popl": m = 5
			"oth": m = 6
			"euro": m = 7
			"region": m = 8
			"prot": m = 9
			"popr": m = 9
			"cons": m = 0
		srcmap.append(m)
	for t in LAW_TOPICS:
		if DE_OWN.has(t["id"]):
			continue
		for v in t["v"]:
			if not (v as Dictionary).has("ps"):
				continue
			var old: Dictionary = v["ps"]
			var nw := {}
			for p in srcmap.size():
				var sp: int = int(srcmap[p])
				if sp >= 0 and old.has(sp):
					var k: float = 0.8 if String(ARCHS[p]) == "cons" else (0.7 if String(ARCHS[p]) == "popr" else 1.0)
					nw[p] = float(old[sp]) * k
			v["ps"] = nw


func dip_all(delta: float, eu_only: bool) -> void:
	for c in dip.keys():
		if eu_only and not bool(WORLD.get(c, {}).get("eu", false)):
			continue
		dip_change(String(c), delta)
