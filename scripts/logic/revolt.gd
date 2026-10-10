# Протесты, недовольство, сепаратизм, революция, гражданская война, война за отделение, независимость и государственные перевороты (v43_1).
# Состояние — словарь rv. Регионы в нём хранятся по uid (индексы регионов сдвигаются при потере территории).
#  region: стадия (0 спокойно … 4 война), сепаратизм sep, обида hate (от репрессий), счётчики; страна: волна протестов wave,
#  риск революции rev, риск переворота coup, общая обида hate; конфликты conf (секессия, мятеж, гражданская война).
# Все числа настраиваются в константах ниже; при настройке игры revev=0 модуль отключён (эталоны golden).
extends "res://scripts/logic/radical.gd"

const RV_STAGE_NAMES := ["спокойно", "протесты", "беспорядки", "вооружённый мятеж", "война"]
const RV_STAGE_COL := ["#58c887", "#e8c94a", "#f0a040", "#e0605a", "#d03050"]
# влияние стадии региона на рост ВВП страны (п.п. в год на единицу доли региона в ВВП) и на безработицу
const RV_STAGE_G := [0.0, 0.4, 1.3, 3.2, 5.0]
const RV_STAGE_U := [0.0, 0.3, 1.0, 2.2, 3.5]
const RV_REG_ACTS := [
	{"id": "talk", "name": "Диалог с лидерами протеста", "cap": 3.0, "cd": 4, "min": 1,
		"desc": "Встречи с представителями общин и профсоюзов: недовольство и обида падают, лояльность растёт. На стадии мятежа лидеры могут отказаться."},
	{"id": "invest", "name": "Инвестиции в регион (+0,15% ВВП в долг)", "cap": 4.0, "cd": 6, "min": 0,
		"desc": "Рабочие места и стройки: развитие региона растёт, недовольство спадает."},
	{"id": "police", "name": "Усилить полицию", "cap": 2.0, "cd": 3, "min": 1,
		"desc": "Быстро снижает недовольство, но копит обиду: потом протесты вспыхнут снова. Против вооружённого мятежа бессильна."},
	{"id": "troops", "name": "Войска и комендантский час", "cap": 5.0, "cd": 6, "min": 2,
		"desc": "Сильное подавление: недовольство резко падает, но обида и сепаратизм растут, демократии осуждают. На стадии мятежа начинается вооружённая борьба."},
	{"id": "amnesty", "name": "Амнистия и уступки", "cap": 6.0, "cd": 8, "min": 1,
		"desc": "Освобождение задержанных, пересмотр жёстких мер: обида и сепаратизм заметно падают."},
	{"id": "status", "name": "Особый статус и больше автономии", "cap": 8.0, "cd": 12, "min": 0,
		"desc": "Регион получает больше самоуправления: автономия +12, сепаратизм −12, обида падает. Другие регионы могут потребовать того же."},
	{"id": "referendum", "name": "Разрешить референдум о независимости", "cap": 10.0, "cd": 36, "min": 0,
		"desc": "Честный референдум сбивает накал, если сторонников независимости меньше половины. Если больше — придётся договариваться о разводе или воевать."},
]
const RV_CONF_ACTS := [
	{"id": "mob_up", "name": "Усилить наступление", "cap": 5.0, "desc": "Мобилизация выше: давление на повстанцев сильнее, но растут потери, расходы и обида."},
	{"id": "mob_down", "name": "Перейти к обороне", "cap": 0.0, "desc": "Меньше расходов и потерь, но повстанцы наступают увереннее."},
	{"id": "ally", "name": "Просить помощи союзников", "cap": 5.0, "desc": "Союзники по НАТО/ЕС присылают помощь: сила правительства растёт. Мир видит вашу слабость."},
	{"id": "truce", "name": "Предложить перемирие", "cap": 6.0, "desc": "Шанс зависит от соотношения сил и обиды. Перемирие замораживает бои и открывает переговоры."},
	{"id": "autonomy", "name": "Предложить автономию вместо независимости", "cap": 8.0, "desc": "Если сторона согласится, конфликт заканчивается особым статусом."},
	{"id": "recognize", "name": "Признать независимость", "cap": 4.0, "desc": "Бои прекращаются, регион уходит мирно. Тяжёлый удар по престижу."},
]
const RV_COUP_MEASURES := [
	{"id": "pay", "name": "Повысить жалованье и пайки военным", "cap": 4.0, "cd": 6,
		"desc": "Силовики довольнее, риск переворота ниже на время; армия получает постоянную прибавку к бюджету."},
	{"id": "loyal", "name": "Лояльные назначения в штабах", "cap": 5.0, "cd": 8,
		"desc": "Риск переворота заметно ниже на год, растёт коррупция."},
	{"id": "guard", "name": "Усилить гвардию и спецслужбы", "cap": 6.0, "cd": 12,
		"desc": "Защита правительства: переворот труднее, но общество настороже (демократии критикуют)."},
	{"id": "purge", "name": "Чистка офицерского корпуса", "cap": 6.0, "cd": 18,
		"desc": "Заговорщики устранены, риск переворота резко падает, но армия напугана: поддержка силовиков падает, качество войск тоже."},
]

var rv: Dictionary = {}


# ============================================================
#  СОСТОЯНИЕ
# ============================================================


func rv_lvl() -> int:
	return int(game_opts.get("revev", 1))


func rv_on() -> bool:
	return not rv.is_empty() and rv_lvl() > 0


func revolt_init() -> void:
	for c in WORLD.keys():
		if String(c).begins_with("SEP"):
			WORLD.erase(c)
	rv = {"r": {}, "nat": {"wave": 5.0, "rev": 4.0, "coup": 6.0, "hate": 0.0, "loyal": 0.0}, "conf": [], "states": [], "log": [],
		"cd": {}, "nid": 1, "sid": 1, "g": 0.0, "u": 0.0, "last": {}, "tags": [],
		"h": {"wave": [], "rev": [], "coup": [], "sep": [], "unrest": []}, "army_up": 0.0, "lost_gdp": 0.0}
	for i in regions.size():
		rv_reg(i)


func rv_uid(i: int) -> String:
	return String(REGIONS[i].get("uid", REGIONS[i].get("code", str(i))))


func rv_reg(i: int) -> Dictionary:
	var uid := rv_uid(i)
	var rr: Dictionary = rv["r"]
	if not rr.has(uid):
		rr[uid] = {"stage": 0, "sep": minf(40.0, float(REGIONS[i].get("reg", 0.3)) * 30.0), "hate": 0.0, "t3": 0, "ref": 0, "refcd": 0,
			"udi": false, "cd": {}, "calm": 0, "peak": 0}
	return rr[uid]


func rv_idx(uid: String) -> int:
	for i in REGIONS.size():
		if rv_uid(i) == uid:
			return i
	return -1


func rv_log(txt: String, col: String = "") -> void:
	var line := "%s: %s" % [date_text(), txt]
	var lg: Array = rv["log"]
	lg.append(line)
	if lg.size() > 40:
		lg.pop_front()
	log_tag("КРИЗИС", col if col != "" else COL_WARN, line)


func rv_cd(key: String) -> int:
	return int((rv["cd"] as Dictionary).get(key, 0))


func rv_cd_set(key: String, months: int) -> void:
	(rv["cd"] as Dictionary)[key] = months


func rv_cd_tick() -> void:
	var cd: Dictionary = rv["cd"]
	for k in cd.keys():
		cd[k] = int(cd[k]) - 1
		if int(cd[k]) <= 0:
			cd.erase(k)
	for uid in rv["r"]:
		var rc: Dictionary = (rv["r"][uid] as Dictionary)["cd"]
		for k2 in rc.keys():
			rc[k2] = int(rc[k2]) - 1
			if int(rc[k2]) <= 0:
				rc.erase(k2)
		var rr: Dictionary = rv["r"][uid]
		rr["refcd"] = maxi(0, int(rr["refcd"]) - 1)


func rv_clamp(v: float) -> float:
	return clampf(v, 0.0, 100.0)


func rv_conf_count(kind: String = "") -> int:
	var n := 0
	for c in rv["conf"]:
		if kind == "" or String(c["kind"]) == kind:
			n += 1
	return n


# ============================================================
#  ЕЖЕМЕСЯЧНЫЙ ШАГ
# ============================================================


func revolt_g() -> float:
	return float(rv.get("g", 0.0)) if rv_on() else 0.0


func revolt_unemp() -> float:
	return float(rv.get("u", 0.0)) if rv_on() else 0.0


func revolt_month() -> void:
	if rv.is_empty() or game_over:
		return
	if rv_lvl() == 0:
		rv["g"] = 0.0
		rv["u"] = 0.0
		return
	rv_cd_tick()
	rv_nat_step()
	var gs := 0.0
	var us := 0.0
	var sep_max := 0.0
	var unrest_max := 0.0
	for i in regions.size():
		rv_region_step(i)
		var rg: Dictionary = rv_reg(i)
		var st: int = int(rg["stage"])
		gs += RV_STAGE_G[st] * gdp_w[i]
		us += RV_STAGE_U[st] * gdp_w[i]
		sep_max = maxf(sep_max, float(rg["sep"]))
		unrest_max = maxf(unrest_max, float(regions[i]["unrest"]))
	rv_conf_month()
	var nat: Dictionary = rv["nat"]
	var wv: float = float(nat["wave"])
	gs += maxf(0.0, wv - 40.0) * 0.012
	us += maxf(0.0, wv - 40.0) * 0.01
	for c in rv["conf"]:
		if String(c["kind"]) == "civil":
			var sh: float = 0.4 + float(c["ctl"]) * 0.01
			gs += 3.5 * sh
			us += 2.0 * sh
	rv["g"] = -gs * float(rv_lvl()) * 0.6 if rv_lvl() > 0 else 0.0
	rv["u"] = us * float(rv_lvl()) * 0.6
	# последствия национальной волны для настроения групп
	if wv > 35.0:
		var dr: float = (wv - 35.0) * 0.0016
		add_support("Молодёжь", -dr)
		add_support("Рабочие", -dr * 0.6)
		add_support("Бюджетники", -dr * 0.4)
	var h: Dictionary = rv["h"]
	(h["wave"] as Array).append(wv)
	(h["rev"] as Array).append(float(nat["rev"]))
	(h["coup"] as Array).append(float(nat["coup"]))
	(h["sep"] as Array).append(sep_max)
	(h["unrest"] as Array).append(unrest_max)
	for k in h:
		if (h[k] as Array).size() > 240:
			(h[k] as Array).pop_front()
	rv_events()
	if observer or opp_mode:
		rv_ai_step()


func rv_nat_step() -> void:
	var nat: Dictionary = rv["nat"]
	var dem: float = democracy_index()
	var ap_n := approval()
	var ag_t := 0.0
	if AG != null and ag_on and ag_prot0.size() == regions.size():
		for i in regions.size():
			ag_t += (AG.region_prot(i) - float(ag_prot0[i])) * pop_w[i]
	var wave_t: float = (reg_avg("unrest") - 25.0) * 1.25 + maxf(0.0, 45.0 - ap_n) * 1.1 + maxf(0.0, inflation - 5.0) * 2.0 \
		+ maxf(0.0, unemployment - 8.0) * 2.0 + ag_t * 50.0 + float(nat["hate"]) * 0.3 + maxf(0.0, float(lvl["corruption"]) - 55.0) * 0.5 \
		- (float(lvl["security_lvl"]) - 50.0) * 0.15 * (1.0 - dem * 0.5)
	wave_t = rv_clamp(wave_t)
	nat["wave"] = rv_clamp(float(nat["wave"]) + (wave_t - float(nat["wave"])) * 0.18)
	var cn := rv_conf_count()
	var rev_t: float = float(nat["wave"]) * 0.55 + maxf(0.0, 45.0 - ap_n) * 0.9 + (regime_risk * 0.3 if decree_power() else 0.0) + cn * 8.0 \
		+ float(nat["hate"]) * 0.2 + maxf(0.0, float(lvl["corruption"]) - 60.0) * 0.4 - maxf(0.0, float(support["Силовики"]) - 55.0) * 0.25
	nat["rev"] = rv_clamp(float(nat["rev"]) + (rv_clamp(rev_t) - float(nat["rev"])) * 0.10)
	var army_cut: float = maxf(0.0, float(pol_def["army"]) - float(pol["army"])) * 10.0
	var coup_t: float = maxf(0.0, 52.0 - float(support["Силовики"])) * 1.3 + army_cut + maxf(0.0, 42.0 - ap_n) * 0.9 + float(nat["rev"]) * 0.25 + cn * 5.0 \
		+ (1.0 - dem) * 22.0 + (regime_risk * 0.2 if decree_power() else 0.0) - float(nat["loyal"])
	nat["coup"] = rv_clamp(float(nat["coup"]) + (rv_clamp(coup_t) - float(nat["coup"])) * 0.08)
	nat["hate"] = float(nat["hate"]) * 0.97
	nat["loyal"] = float(nat["loyal"]) * 0.985
	rv["army_up"] = float(rv["army_up"]) * 0.99


# ============================================================
#  РЕГИОНЫ: СЕПАРАТИЗМ И СТАДИИ НЕДОВОЛЬСТВА
# ============================================================


func rv_identity_gap(i: int) -> float:
	# отличие религиозного состава региона от национального, 0..100 (половина суммы модулей разностей долей)
	var r: Dictionary = regions[i]
	if not r.has("rel") or soc.is_empty():
		return 0.0
	var nat: Array = soc_national()
	var s := 0.0
	for f in 7:
		s += absf(float(r["rel"][f]) - float(nat[f]))
	return clampf(s * 50.0, 0.0, 100.0)


func rv_sep_target(i: int) -> float:
	var r: Dictionary = regions[i]
	var rg: Dictionary = rv_reg(i)
	var ident: float = float(REGIONS[i].get("reg", 0.3))
	var t: float = ident * 45.0 + (50.0 - float(r["loy"])) * 0.55 + maxf(0.0, 35.0 - float(r["auto"])) * 0.5 - maxf(0.0, float(r["auto"]) - 60.0) * 0.25
	t += float(rg["hate"]) * 0.35 + rv_identity_gap(i) * 0.25
	t += clampf(float(r["dev"]) - reg_avg("dev"), -20.0, 30.0) * 0.15
	t -= float(r.get("status", 0)) * 3.0
	t += float((rv["states"] as Array).size()) * 4.0 * ident
	t += maxf(0.0, float((rv["nat"] as Dictionary)["wave"]) - 30.0) * 0.1
	if bool(r.get("terr", false)):
		t += 6.0
	return rv_clamp(t)


func rv_region_step(i: int) -> void:
	var r: Dictionary = regions[i]
	var rg: Dictionary = rv_reg(i)
	if bool(rg.get("lost", false)):
		return
	var u: float = float(r["unrest"])
	rg["hate"] = rv_clamp(float(rg["hate"]) * 0.985)
	rg["sep"] = rv_clamp(float(rg["sep"]) + (rv_sep_target(i) - float(rg["sep"])) * 0.05)
	var st: int = int(rg["stage"])
	var in_conf: bool = rv_conf_of(rv_uid(i)) >= 0
	# повышение и понижение стадий (с гистерезисом)
	var up := st
	if st < 1 and u >= 38.0:
		up = 1
	elif st == 1 and (u >= 58.0 or (u >= 50.0 and float(rg["hate"]) >= 45.0)):
		up = 2
	elif st == 2 and u >= 76.0 and (float(rg["sep"]) >= 45.0 or float(rg["hate"]) >= 60.0):
		up = 3
	if up > st:
		rg["stage"] = up
		st = up
		rg["calm"] = 0
		rg["peak"] = maxi(int(rg["peak"]), st)
		rv_stage_news(i, st, true)
	elif st > 0 and not in_conf:
		var down_at: Array = [0.0, 30.0, 50.0, 68.0]
		if u < float(down_at[st]):
			rg["calm"] = int(rg["calm"]) + 1
			if int(rg["calm"]) >= 2:
				rg["stage"] = st - 1
				st -= 1
				rg["calm"] = 0
				rv_stage_news(i, st, false)
		else:
			rg["calm"] = 0
	if in_conf:
		rg["stage"] = 4
		st = 4
	# последствия стадии
	var k: float = float(rv_lvl())
	if st >= 1:
		capital = maxf(0.0, capital - [0.0, 0.15, 0.4, 0.8, 1.2][st] * k * gdp_w[i] * 4.0)
	if st >= 2:
		r["infra"] = maxf(0.0, float(r["infra"]) - 0.35 * float(st - 1))
		r["dev"] = maxf(0.0, float(r["dev"]) - 0.12 * float(st - 1))
	if st >= 3:
		r["popm"] = float(r["popm"]) * (1.0 - 0.0008 * float(st - 2))
		rg["t3"] = int(rg["t3"]) + 1
	else:
		rg["t3"] = 0
	if st >= 2:
		for j in neighbors[i]:
			regions[j]["unrest"] = minf(100.0, float(regions[j]["unrest"]) + 0.25 * float(st - 1))
	# сепаратизм: требования, референдум, провозглашение независимости, мятеж
	if rv_conf_of(rv_uid(i)) >= 0 or not current_event.is_empty() or election_open:
		return
	var sep: float = float(rg["sep"])
	var capital_reg: bool = rv_is_capital(i)
	if st >= 1 and sep >= 60.0 and int(rg["refcd"]) == 0 and not capital_reg and regions.size() >= 3 and randf() < 0.07 * k:
		rv_event_referendum_demand(i)
		return
	if st >= 2 and sep >= 78.0 and not capital_reg and regions.size() >= 3 and (int(rg["ref"]) > 0 or float(rg["hate"]) >= 55.0) and randf() < 0.05 * k:
		rv_event_udi(i)
		return
	if st >= 3 and int(rg["t3"]) >= 2 and randf() < (0.2 + maxf(0.0, sep - 40.0) * 0.008) * k:
		var kind := "secession" if sep >= 55.0 and not capital_reg else "insurgency"
		rv_conf_start(kind, i, 12.0 + sep * 0.2, "мятеж в регионе «%s»" % REGIONS[i]["short"])


func rv_is_capital(i: int) -> bool:
	var ui: int = fed_ui_of_region(i)
	return ui >= 0 and fed_unit_is_capital(ccode, ui)


func rv_stage_news(i: int, st: int, up: bool) -> void:
	var nm := String(REGIONS[i]["short"])
	if up:
		match st:
			1:
				rv_log("в регионе «%s» начались протесты: недовольство %.0f, сепаратизм %.0f." % [nm, float(regions[i]["unrest"]), float(rv_reg(i)["sep"])], COL_WARN)
			2:
				rv_log("[b]в регионе «%s» беспорядки[/b]: перекрыты дороги, нападения на административные здания." % nm, COL_BAD)
			3:
				rv_log("[b]в регионе «%s» вооружённый мятеж[/b]: появились отряды, которые не подчиняются центру." % nm, COL_BAD)
	elif st == 0:
		rv_log("в регионе «%s» спокойно: протесты прекратились." % nm, COL_GOOD)


# ============================================================
#  ДЕЙСТВИЯ ИГРОКА В РЕГИОНЕ
# ============================================================


func rv_reg_act_def(id: String) -> Dictionary:
	for a in RV_REG_ACTS:
		if a["id"] == id:
			return a
	return {}


func rv_reg_act_check(id: String, i: int) -> String:
	# "" — действие доступно, иначе причина
	var a := rv_reg_act_def(id)
	if a.is_empty() or i < 0 or i >= regions.size():
		return "нет такого действия"
	if game_over:
		return "игра окончена"
	var rg: Dictionary = rv_reg(i)
	if int(rg["stage"]) < int(a["min"]):
		return "нужна стадия «%s» или выше" % RV_STAGE_NAMES[int(a["min"])]
	if int((rg["cd"] as Dictionary).get(id, 0)) > 0:
		return "ещё %d мес." % int(rg["cd"][id])
	if capital < float(a["cap"]):
		return "нужно %.0f политкапитала" % float(a["cap"])
	if rv_conf_of(rv_uid(i)) >= 0 and id in ["talk", "police", "invest"]:
		return "идёт война: используйте действия конфликта"
	if id == "referendum":
		if rv_is_capital(i):
			return "столичный регион"
		if regions.size() < 3:
			return "у страны должно остаться не меньше двух регионов"
		if int(rg["refcd"]) > 0:
			return "референдум недавно проводили"
	return ""


func rv_region_act(id: String, i: int) -> bool:
	if rv_reg_act_check(id, i) != "":
		return false
	var a := rv_reg_act_def(id)
	var r: Dictionary = regions[i]
	var rg: Dictionary = rv_reg(i)
	var st: int = int(rg["stage"])
	var dem: float = democracy_index()
	var nm := String(REGIONS[i]["short"])
	capital -= float(a["cap"])
	(rg["cd"] as Dictionary)[id] = int(a["cd"])
	match id:
		"talk":
			var p: float = 0.9 if st <= 2 else 0.45
			if randf() < p:
				r["unrest"] = rv_clamp(float(r["unrest"]) - 6.0 - 2.0 * float(st))
				rg["hate"] = rv_clamp(float(rg["hate"]) - 5.0)
				r["loy"] = rv_clamp(float(r["loy"]) + 2.0)
				rv_log("диалог в регионе «%s»: лидеры протеста согласились на переговоры, напряжение спадает." % nm, COL_GOOD)
			else:
				rg["hate"] = rv_clamp(float(rg["hate"]) + 2.0)
				rv_log("в регионе «%s» лидеры отказались от диалога: они не верят центру." % nm, COL_BAD)
		"invest":
			debt += gdp * 0.0015
			r["dev"] = rv_clamp(float(r["dev"]) + 3.0)
			r["unrest"] = rv_clamp(float(r["unrest"]) - 4.0)
			r["loy"] = rv_clamp(float(r["loy"]) + 2.0)
			rv_log("инвестиции в регион «%s»: стройки и рабочие места, недовольство падает." % nm, COL_GOOD)
		"police":
			var eff: float = clampf(float(lvl["security_lvl"]) / 50.0, 0.5, 1.6)
			var ok := st <= 2 or randf() < 0.3
			if ok:
				r["unrest"] = rv_clamp(float(r["unrest"]) - 9.0 * eff)
				rv_log("полиция в регионе «%s» разогнала акции: недовольство ниже, но обида растёт." % nm, COL_WARN)
			else:
				rv_log("полиция в регионе «%s» не справляется с вооружёнными группами." % nm, COL_BAD)
			rg["hate"] = rv_clamp(float(rg["hate"]) + 6.0)
			r["loy"] = rv_clamp(float(r["loy"]) - 2.0)
			rv["nat"]["hate"] = rv_clamp(float(rv["nat"]["hate"]) + 1.0)
		"troops":
			if st >= 3 and rv_conf_of(rv_uid(i)) < 0:
				var kind := "secession" if float(rg["sep"]) >= 55.0 and not rv_is_capital(i) else "insurgency"
				rv_conf_start(kind, i, 12.0 + float(rg["sep"]) * 0.2, "подавление мятежа в регионе «%s»" % nm)
			else:
				r["unrest"] = rv_clamp(float(r["unrest"]) - 15.0)
				if randf() < 0.55 + (float(lvl["security_lvl"]) - 50.0) * 0.004 and st > 0:
					rg["stage"] = maxi(0, st - 1)
				rv_log("войска и комендантский час в регионе «%s»: улицы пусты, но обида и сепаратизм растут." % nm, COL_WARN)
			rg["hate"] = rv_clamp(float(rg["hate"]) + 12.0)
			rg["sep"] = rv_clamp(float(rg["sep"]) + 3.0)
			r["loy"] = rv_clamp(float(r["loy"]) - 4.0)
			add_support("Силовики", 1.0)
			add_support("Молодёжь", -3.0)
			add_support("Экологи", -1.0)
			rv["nat"]["hate"] = rv_clamp(float(rv["nat"]["hate"]) + 3.0)
			if dem > 0.6:
				dip_all(-1.0, false)
		"amnesty":
			rg["hate"] = rv_clamp(float(rg["hate"]) - 14.0)
			rg["sep"] = rv_clamp(float(rg["sep"]) - 5.0)
			r["unrest"] = rv_clamp(float(r["unrest"]) - 6.0)
			r["loy"] = rv_clamp(float(r["loy"]) + 3.0)
			add_support("Силовики", -1.0)
			rv_log("амнистия и уступки в регионе «%s»: обида и сепаратизм падают." % nm, COL_GOOD)
		"status":
			r["auto"] = rv_clamp(float(r["auto"]) + 12.0)
			rg["sep"] = rv_clamp(float(rg["sep"]) - 12.0)
			rg["hate"] = rv_clamp(float(rg["hate"]) - 6.0)
			r["unrest"] = rv_clamp(float(r["unrest"]) - 5.0)
			r["loy"] = rv_clamp(float(r["loy"]) + 4.0)
			for j in regions.size():
				if j != i:
					var rj: Dictionary = rv_reg(j)
					rj["sep"] = rv_clamp(float(rj["sep"]) + 1.5 * float(REGIONS[j].get("reg", 0.3)))
			rv_log("регион «%s» получил особый статус: больше самоуправления, меньше недовольства. Соседи тоже заговорили о привилегиях." % nm, COL_GOOD)
		"referendum":
			rv_referendum(i, false)
	refresh()
	return true


# ============================================================
#  РЕФЕРЕНДУМ, ОТДЕЛЕНИЕ И НЕЗАВИСИМОСТЬ
# ============================================================


func rv_yes_share(i: int) -> float:
	var r: Dictionary = regions[i]
	var rg: Dictionary = rv_reg(i)
	return clampf(0.10 + float(rg["sep"]) * 0.0062 + float(rg["hate"]) * 0.002 - (float(r["loy"]) - 40.0) * 0.003 + randf_range(-0.04, 0.04), 0.03, 0.95)


func rv_referendum(i: int, by_demand: bool) -> void:
	var rg: Dictionary = rv_reg(i)
	var r: Dictionary = regions[i]
	var nm := String(REGIONS[i]["short"])
	var y := rv_yes_share(i)
	rg["ref"] = int(rg["ref"]) + 1
	rg["refcd"] = 36
	if y > 0.5:
		rv_log("[b]референдум в регионе «%s»: за независимость %.0f%%[/b]." % [nm, y * 100.0], COL_BAD)
		rv_event_ref_yes(i, y)
		return
	rg["sep"] = rv_clamp(float(rg["sep"]) - 15.0)
	rg["hate"] = rv_clamp(float(rg["hate"]) - 5.0)
	r["unrest"] = rv_clamp(float(r["unrest"]) - 8.0)
	r["loy"] = rv_clamp(float(r["loy"]) + 3.0)
	rg["stage"] = maxi(0, int(rg["stage"]) - 1)
	rv_log("референдум в регионе «%s»: за независимость лишь %.0f%% — вопрос закрыт на несколько лет." % [nm, y * 100.0], COL_GOOD)
	add_support("Бизнес", 1.0)


func rv_new_state_code() -> String:
	var n: int = int(rv["sid"])
	rv["sid"] = n + 1
	return "SEP%d" % n


func rv_can_secede(i: int) -> String:
	if rv_is_capital(i):
		return "столичный регион не может отделиться"
	if regions.size() < 3:
		return "у страны должно остаться не меньше двух регионов"
	if fed_ui_of_region(i) < 0:
		return "у региона нет территории на карте"
	return ""


func rv_secede(i: int, how: String) -> bool:
	# регион уходит из состава страны и становится независимым государством. how: peace | war | referendum
	if rv_can_secede(i) != "":
		return false
	var uid := rv_uid(i)
	var nm := String(REGIONS[i]["name"])
	var short := String(REGIONS[i]["short"])
	var ui: int = fed_ui_of_region(i)
	var g_r: float = gdp * gdp_w[i]
	var share: float = gdp_w[i]
	var code := rv_new_state_code()
	var wr := {"id": uid, "code": String(REGIONS[i]["code"]), "name": nm, "short": short, "popm": float(regions[i]["popm"]),
		"pc": float(REGIONS[i]["pc"]), "dev": float(regions[i]["dev"]), "unrest": 20.0, "auto": 100.0,
		"infra": float(regions[i]["infra"]), "edu": float(regions[i]["edu"]), "health": float(regions[i]["health"]), "env": float(regions[i]["env"]),
		"loy": 80.0, "desc": String(REGIONS[i].get("desc", "")), "sh": []}
	var parent: Dictionary = WORLD[ccode]
	var stub: Dictionary = parent.duplicate(true)
	stub["name"] = short
	stub["pop"] = float(regions[i]["popm"])
	stub["gdp"] = g_r
	stub["debt"] = g_r * 0.4
	stub["regions"] = [wr]
	stub["eu"] = false
	stub["euro"] = false
	stub["desc"] = "Независимое государство, отделившееся от страны «%s»." % String(parent.get("name", ccode))
	stub["leader"] = "Президент-основатель"
	WORLD[code] = stub
	wsim[code] = {"gdp": g_r, "growth": float(wsim[ccode]["growth"]) - 1.0 if wsim.has(ccode) else 0.5, "infl": inflation + 1.0, "unemp": unemployment + 1.5,
		"debt": 40.0, "def": 3.0, "stab": 55.0, "appr": 55.0, "stance": 0.0, "gov": "переходное правительство", "crisis": {},
		"next_elec": 36, "pot": float(wsim[ccode]["pot"]) if wsim.has(ccode) else 1.5, "gdp_hist": [g_r], "g_hist": [0.5], "i_hist": [inflation]}
	# долг делится при любом отделении: при мирном разводе — пропорционально доле ВВП региона, при войне — 70% этой доли
	# (иначе у сильно задолженной страны потеря региона сразу даёт дефолт: ВВП падает, долг остаётся)
	debt = maxf(0.0, debt - debt * share * (1.0 if how != "war" else 0.7))
	fed_set_unit_cc(ui, code)
	fed_drop_region(i)
	recalc_weights()
	gdp = maxf(1.0, gdp - g_r)
	fed_rebuild()
	var rg: Dictionary = rv["r"][uid]
	rg["lost"] = true
	rg["stage"] = 0
	var st := {"code": code, "name": short, "full": nm, "since": turn, "how": how, "rel": 55.0 if how != "war" else 20.0, "gdp": g_r, "pop": float(wr["popm"])}
	(rv["states"] as Array).append(st)
	# последствия
	for j in regions.size():
		var rj: Dictionary = rv_reg(j)
		rj["sep"] = rv_clamp(float(rj["sep"]) + 6.0 * float(REGIONS[j].get("reg", 0.3)))
	add_support("Пенсионеры", -2.0)
	add_support("Село", -2.0)
	add_support("Силовики", -4.0 if how == "war" else -2.0)
	rv["nat"]["hate"] = rv_clamp(float(rv["nat"]["hate"]) + 6.0)
	dip_all(-2.0 if how == "war" else -0.5, false)
	capital = maxf(0.0, capital - 4.0)
	var txt := "[b]Независимость.[/b] Регион «%s» (%.1f%% ВВП) вышел из состава страны" % [short, share * 100.0]
	txt += " в результате войны." if how == "war" else (" после референдума." if how == "referendum" else " мирно, долг поделён.")
	rv_log(txt, COL_BAD)
	sfx("bad")
	refresh()
	return true


# ============================================================
#  ВОЙНЫ: СЕКЕССИЯ, МЯТЕЖ, ГРАЖДАНСКАЯ ВОЙНА
# ============================================================


func rv_conf_of(uid: String) -> int:
	if rv.is_empty():
		return -1
	var cf: Array = rv["conf"]
	for k in cf.size():
		if String(cf[k]["uid"]) == uid:
			return k
	return -1


func rv_aid0() -> float:
	var a := 0.5
	for c in tech_nb():
		if dip.has(c) and float(dip[c]["rel"]) < 35.0:
			a += 1.2
	return a


func rv_conf_start(kind: String, i: int, ctl0: float, cause: String) -> void:
	var uid := ""
	var nm := ""
	var r0 := 0.0
	if kind == "civil":
		nm = "Гражданская война"
		r0 = 16.0 + float((rv["nat"] as Dictionary)["wave"]) * 0.25 + float((rv["nat"] as Dictionary)["hate"]) * 0.2
	else:
		uid = rv_uid(i)
		var rg: Dictionary = rv_reg(i)
		nm = ("Война за независимость: " if kind == "secession" else "Мятеж: ") + String(REGIONS[i]["short"])
		r0 = 10.0 + float(rg["sep"]) * 0.3 + float(rg["hate"]) * 0.2
		rg["stage"] = 4
	if kind != "civil" and rv_conf_of(uid) >= 0:
		return
	if kind == "civil" and rv_conf_count("civil") > 0:
		return
	var c := {"id": int(rv["nid"]), "kind": kind, "uid": uid, "name": nm, "start": turn, "R": clampf(r0, 6.0, 80.0), "ctl": ctl0, "mob": 1, "aid": rv_aid0(),
		"gaid": 0.0, "kia": 0.0, "ref": 0.0, "truce": 0, "side": "gov", "cause": cause, "talk_cd": 0}
	rv["nid"] = int(rv["nid"]) + 1
	(rv["conf"] as Array).append(c)
	rv_log("[b]%s[/b]: %s. Сила повстанцев %.0f, контроль %.0f%%." % [nm, cause, float(c["R"]), ctl0], COL_BAD)
	sfx("bad")


func rv_gov_power() -> float:
	var sec: float = float(lvl["security_lvl"])
	var force: float = float(support["Силовики"])
	var army_r: float = float(pol["army"]) / maxf(0.1, float(pol_def["army"]))
	var p: float = 38.0 + (sec - 40.0) * 0.6 + (force - 45.0) * 0.35 + (army_r - 1.0) * 22.0 + float(rv.get("army_up", 0.0)) * 20.0
	p *= float(mods["army_q"])
	if mil_at_war():
		p *= 0.75
	if decree_power():
		p += 6.0
	return clampf(p, 8.0, 96.0)


func rv_conf_month() -> void:
	var cf: Array = rv["conf"]
	for k in range(cf.size() - 1, -1, -1):
		if k >= cf.size():
			continue
		rv_conf_step(k)


func rv_conf_step(k: int) -> void:
	var c: Dictionary = rv["conf"][k]
	var i: int = rv_idx(String(c["uid"])) if String(c["uid"]) != "" else -1
	if String(c["kind"]) != "civil" and i < 0:
		(rv["conf"] as Array).remove_at(k)
		return
	var rg: Dictionary = rv_reg(i) if i >= 0 else {}
	var hate: float = float(rg["hate"]) if i >= 0 else float((rv["nat"] as Dictionary)["hate"])
	var mob: int = int(c["mob"])
	var g_pow: float = rv_gov_power() * [0.7, 1.0, 1.3][mob] + float(c["gaid"]) * 2.5
	var side_rebel: bool = String(c["side"]) == "rebel"
	if side_rebel:
		# вы — повстанцы: сила правительства определяется слабостью власти и режимом
		g_pow = 34.0 + (1.0 - democracy_index()) * 14.0 + randf_range(-2.0, 2.0)
	var truce: int = int(c["truce"])
	c["talk_cd"] = maxi(0, int(c["talk_cd"]) - 1)
	if truce > 0:
		c["truce"] = truce - 1
		if int(c["truce"]) == 0:
			rv_log("перемирие в конфликте «%s» закончилось, бои возобновились." % c["name"], COL_BAD)
		return
	var r_pow: float = float(c["R"])
	if side_rebel:
		r_pow = 18.0 + float((rv["nat"] as Dictionary)["wave"]) * 0.35 + (float(support["Силовики"]) - 45.0) * 0.25 + float(mob) * 6.0
	else:
		var sep_v: float = float(rg["sep"]) if i >= 0 else 40.0
		var r_eq: float = 14.0 + hate * 0.25 + sep_v * 0.15 + float(c["aid"]) * 2.0 + (float(c["ctl"]) - 30.0) * 0.12 - (g_pow - 40.0) * 0.2
		c["R"] = clampf(r_pow + (r_eq - r_pow) * 0.07 + randf_range(-1.0, 1.0), 3.0, 95.0)
		r_pow = float(c["R"])
	var terr: float = 1.0
	if i >= 0:
		terr += float(rg["sep"]) * 0.003
	var d: float = 0.12 * (r_pow * terr - g_pow) + randf_range(-4.0, 4.0)
	c["ctl"] = clampf(float(c["ctl"]) + d, 0.0, 100.0)
	# потери и разрушения
	var pop_k: float = (float(regions[i]["popm"]) * 1000.0) if i >= 0 else total_pop() * 1000.0
	var dead: float = pop_k * 0.00004 * (r_pow + g_pow) / 100.0 * (float(mob) + 0.6)
	c["kia"] = float(c["kia"]) + dead
	c["ref"] = float(c["ref"]) + dead * 3.0
	debt += gdp * 0.0007 * (float(mob) + 0.5) * (1.0 if not side_rebel else 0.0)
	if i >= 0:
		regions[i]["popm"] = float(regions[i]["popm"]) * (1.0 - 0.0006 * (float(mob) + 0.6))
		regions[i]["infra"] = maxf(0.0, float(regions[i]["infra"]) - 0.8)
		regions[i]["dev"] = maxf(0.0, float(regions[i]["dev"]) - 0.4)
		regions[i]["unrest"] = rv_clamp(float(regions[i]["unrest"]) + 0.3)
		rg["hate"] = rv_clamp(float(rg["hate"]) + 0.8 * float(mob))
		for j in neighbors[i]:
			regions[j]["unrest"] = minf(100.0, float(regions[j]["unrest"]) + 0.4)
	else:
		for rr in regions:
			rr["unrest"] = rv_clamp(float(rr["unrest"]) + 0.25)
	if mob == 2:
		add_support("Молодёжь", -0.05)
	if i >= 0 and (rv["nat"] as Dictionary).has("hate"):
		rv["nat"]["hate"] = rv_clamp(float(rv["nat"]["hate"]) + 0.15 * float(mob))
	capital = maxf(0.0, capital - 0.6)
	# исходы
	var ctl: float = float(c["ctl"])
	var months: int = turn - int(c["start"])
	if String(c["kind"]) == "civil":
		if ctl >= 80.0:
			rv_conf_end(k, "rebel_win")
		elif ctl <= 6.0 and float(c["R"]) <= 38.0 and not side_rebel:
			rv_conf_end(k, "gov_win")
		elif side_rebel and ctl <= 4.0:
			rv_conf_end(k, "gov_win")
		return
	if String(c["kind"]) == "secession":
		if ctl >= 85.0:
			rv_conf_end(k, "rebel_win")
			return
	elif ctl >= 80.0:
		rv_conf_end(k, "rebel_win")
		return
	if ctl <= 6.0 and float(c["R"]) <= 38.0:
		rv_conf_end(k, "gov_win")
		return
	if months >= 60 and ctl > 20.0 and ctl < 80.0 and int(c["truce"]) == 0:
		c["truce"] = 9999
		rv_log("конфликт «%s» заморожен: обе стороны выдохлись, вводятся международные наблюдатели." % c["name"], COL_WARN)


func rv_conf_end(k: int, res: String) -> void:
	var c: Dictionary = (rv["conf"] as Array)[k]
	var i: int = rv_idx(String(c["uid"])) if String(c["uid"]) != "" else -1
	var kind := String(c["kind"])
	rv["last"] = {"res": res, "kind": kind, "months": turn - int(c["start"]), "kia": float(c["kia"])}
	(rv["conf"] as Array).remove_at(k)
	var nm := String(c["name"])
	var kia := int(float(c["kia"]))
	if kind == "civil":
		if res == "rebel_win":
			if String(c["side"]) == "rebel":
				rv_log("[b]%s: победа![/b] Правительство низложено, власть в ваших руках." % nm, COL_GOOD)
				rv_take_power("гражданская война")
			else:
				end_game("Гражданская война проиграна: повстанцы вошли в столицу, правительство низложено. Погибло около %d тыс. человек." % kia)
		elif res == "gov_win":
			if String(c["side"]) == "rebel":
				end_game("Восстание разгромлено: вы схвачены или бежали за границу. Погибло около %d тыс. человек." % kia)
			else:
				var nat: Dictionary = rv["nat"]
				nat["wave"] = rv_clamp(float(nat["wave"]) - 30.0)
				nat["rev"] = rv_clamp(float(nat["rev"]) - 35.0)
				nat["coup"] = rv_clamp(float(nat["coup"]) - 20.0)
				nat["hate"] = rv_clamp(float(nat["hate"]) + 20.0)
				add_support("Силовики", 4.0)
				for rr in regions:
					rr["unrest"] = rv_clamp(float(rr["unrest"]) - 15.0)
				rv_log("[b]%s: мятежники разгромлены.[/b] Порядок восстановлен, погибло около %d тыс. человек; в обществе страх и обида." % [nm, kia], COL_WARN)
		elif res == "deal":
			var nat2: Dictionary = rv["nat"]
			nat2["wave"] = rv_clamp(float(nat2["wave"]) - 25.0)
			nat2["rev"] = rv_clamp(float(nat2["rev"]) - 40.0)
			nat2["coup"] = rv_clamp(float(nat2["coup"]) - 15.0)
			rv_log("[b]%s: мирное соглашение.[/b] Назначены выборы, повстанцы получили места в парламенте." % nm, COL_GOOD)
			hold_parliament("выборы после мирного соглашения")
		refresh()
		return
	var rg: Dictionary = rv_reg(i)
	var rr: Dictionary = regions[i]
	match res:
		"rebel_win":
			if kind == "secession" and rv_can_secede(i) == "":
				rv_log("[b]%s: победа сторонников независимости.[/b] Погибло около %d тыс. человек." % [nm, kia], COL_BAD)
				rv_secede(i, "war")
			else:
				rg["stage"] = 2
				rr["auto"] = rv_clamp(float(rr["auto"]) + 35.0)
				rg["sep"] = rv_clamp(float(rg["sep"]) - 25.0)
				rg["hate"] = rv_clamp(float(rg["hate"]) - 15.0)
				rr["unrest"] = rv_clamp(float(rr["unrest"]) - 20.0)
				rv_log("[b]%s: правительство уступило.[/b] Регион получил широкую автономию и амнистию; погибло около %d тыс. человек." % [nm, kia], COL_WARN)
		"gov_win":
			rg["stage"] = 1
			rg["sep"] = rv_clamp(float(rg["sep"]) - 35.0)
			rg["hate"] = rv_clamp(float(rg["hate"]) + 25.0)
			rr["unrest"] = rv_clamp(float(rr["unrest"]) - 25.0)
			rr["loy"] = rv_clamp(float(rr["loy"]) - 8.0)
			rr["auto"] = rv_clamp(float(rr["auto"]) - 8.0)
			rg["refcd"] = 60
			add_support("Силовики", 3.0)
			add_support("Молодёжь", -2.0)
			if democracy_index() > 0.6:
				dip_all(-1.5, false)
			rv_log("[b]%s: мятеж подавлен.[/b] Погибло около %d тыс. человек. Регион лишён части льгот; сепаратизм подавлен, но обида осталась." % [nm, kia], COL_WARN)
		"deal":
			rg["stage"] = 1
			rr["auto"] = rv_clamp(float(rr["auto"]) + 30.0)
			rg["sep"] = rv_clamp(float(rg["sep"]) - 35.0)
			rg["hate"] = rv_clamp(float(rg["hate"]) - 25.0)
			rr["unrest"] = rv_clamp(float(rr["unrest"]) - 25.0)
			rr["loy"] = rv_clamp(float(rr["loy"]) + 8.0)
			rg["refcd"] = 36
			rv_log("[b]%s: соглашение об автономии.[/b] Бои прекращены, погибло около %d тыс. человек." % [nm, kia], COL_GOOD)
		"recognize":
			rv_log("[b]%s: независимость признана.[/b]" % nm, COL_BAD)
			rv_secede(i, "peace")
	refresh()


func rv_take_power(why: String) -> void:
	# повстанцы/заговорщики — это вы: власть переходит к вам
	var nat: Dictionary = rv["nat"]
	nat["wave"] = rv_clamp(float(nat["wave"]) - 20.0)
	nat["rev"] = rv_clamp(float(nat["rev"]) - 40.0)
	nat["coup"] = rv_clamp(float(nat["coup"]) - 25.0)
	if opp_mode:
		var mem: Array = [0]
		opp_to_gov(mem, 0, "вы пришли к власти: %s." % why)
	rv_log("[b]Вы у власти: %s.[/b]" % why, COL_GOOD)
	refresh()


# ---------- действия игрока в конфликте ----------


func rv_conf_act_check(id: String, k: int) -> String:
	var cf: Array = rv["conf"]
	if k < 0 or k >= cf.size() or game_over:
		return "нет конфликта"
	var c: Dictionary = cf[k]
	var a: Dictionary = {}
	for x in RV_CONF_ACTS:
		if x["id"] == id:
			a = x
	if a.is_empty():
		return "нет такого действия"
	if capital < float(a["cap"]):
		return "нужно %.0f политкапитала" % float(a["cap"])
	if String(c["side"]) == "rebel" and id in ["ally", "autonomy", "recognize"]:
		return "недоступно для повстанцев"
	match id:
		"mob_up":
			if int(c["mob"]) >= 2:
				return "мобилизация уже максимальная"
		"mob_down":
			if int(c["mob"]) <= 0:
				return "мобилизация уже минимальная"
		"ally":
			if float(c["gaid"]) >= 8.0:
				return "помощь уже оказана"
			if not mil_is_nato(ccode) and not bool(MACRO.get("eu", false)):
				return "нужно членство в НАТО или ЕС"
		"truce":
			if int(c["truce"]) > 0 or int(c["talk_cd"]) > 0:
				return "переговоры уже идут" if int(c["truce"]) > 0 else "ещё %d мес." % int(c["talk_cd"])
		"autonomy":
			if String(c["kind"]) == "civil":
				return "недоступно при гражданской войне"
			if int(c["talk_cd"]) > 0:
				return "ещё %d мес." % int(c["talk_cd"])
		"recognize":
			if String(c["kind"]) != "secession":
				return "это не война за независимость"
			var i: int = rv_idx(String(c["uid"]))
			if i < 0 or rv_can_secede(i) != "":
				return "регион не может отделиться"
	return ""


func rv_conf_act(id: String, k: int) -> bool:
	if rv_conf_act_check(id, k) != "":
		return false
	var c: Dictionary = (rv["conf"] as Array)[k]
	var cap := 0.0
	for x in RV_CONF_ACTS:
		if x["id"] == id:
			cap = float(x["cap"])
	capital -= cap
	var ctl: float = float(c["ctl"])
	var rebel_pow: float = float(c["R"])
	match id:
		"mob_up":
			c["mob"] = int(c["mob"]) + 1
			rv_log("мобилизация в конфликте «%s» повышена: потери и расходы растут." % c["name"], COL_WARN)
		"mob_down":
			c["mob"] = int(c["mob"]) - 1
			rv_log("в конфликте «%s» избрана оборона: меньше потерь и расходов." % c["name"], COL_DIM)
		"ally":
			c["gaid"] = float(c["gaid"]) + 4.0
			add_support("Силовики", -1.0)
			dip_all(-0.3, false)
			rv_log("союзники по НАТО/ЕС помогают в конфликте «%s»: сила правительства выросла." % c["name"], COL_WARN)
		"truce":
			c["talk_cd"] = 6
			var p: float = clampf(0.55 - (ctl - 40.0) * 0.006 - (rebel_pow - 35.0) * 0.004 + (35.0 - (float(rv_reg(rv_idx(String(c["uid"])))["hate"]) if String(c["uid"]) != "" else 30.0)) * 0.004, 0.08, 0.85)
			if randf() < p:
				c["truce"] = 6
				rv_log("[b]перемирие в конфликте «%s»[/b] на 6 месяцев: бои прекращены, можно вести переговоры (шанс был %.0f%%)." % [c["name"], p * 100.0], COL_GOOD)
			else:
				rv_log("повстанцы отвергли перемирие в конфликте «%s» (шанс был %.0f%%)." % [c["name"], p * 100.0], COL_BAD)
		"autonomy":
			c["talk_cd"] = 6
			var p2: float = clampf(0.5 - (ctl - 35.0) * 0.006 + (1.0 - float(rv_reg(rv_idx(String(c["uid"])))["sep"]) / 100.0) * 0.25, 0.06, 0.85)
			if randf() < p2:
				rv_log("повстанцы приняли предложение об автономии (шанс был %.0f%%)." % (p2 * 100.0), COL_GOOD)
				rv_conf_end(k, "deal")
				refresh()
				return true
			rv_log("повстанцы отвергли автономию и требуют независимости (шанс был %.0f%%)." % (p2 * 100.0), COL_BAD)
		"recognize":
			rv_conf_end(k, "recognize")
			refresh()
			return true
	refresh()
	return true


# ============================================================
#  СОБЫТИЯ
# ============================================================


func rv_event(kind: String, text: String, opts: Array, rid: int = -1) -> void:
	if not current_event.is_empty() or election_open or game_over:
		return
	current_event = {"t": text, "special": "revolt", "rvk": kind, "o": opts}
	event_region = rid
	if observer or opp_mode:
		var ai_i := rv_ai_choice(kind, opts)
		log_tag("НАБЛЮДАТЕЛЬ" if observer else "КРИЗИС", COL_TEAL, "%s — решение: «%s»." % [text.replace("{r}", String(REGIONS[rid]["short"]) if rid >= 0 else ""), opts[ai_i]["l"]])
		choose(ai_i)
		return
	present_event()


func rv_events() -> void:
	if not current_event.is_empty() or election_open or game_over or opp_mode:
		return
	var nat: Dictionary = rv["nat"]
	var k: float = float(rv_lvl())
	if float(nat["wave"]) >= 58.0 and rv_cd("wave") == 0 and randf() < 0.18 * k:
		rv_cd_set("wave", 12)
		rv_event_wave()
		return
	if float(nat["rev"]) >= 72.0 and rv_cd("rev") == 0 and randf() < 0.10 * k:
		rv_cd_set("rev", 36)
		rv_event_rev()
		return
	if float(nat["coup"]) >= 58.0 and rv_cd("coup") == 0 and randf() < (float(nat["coup"]) - 52.0) * 0.006 * k:
		rv_cd_set("coup", 36)
		rv_event_coup()


func rv_event_wave() -> void:
	var opts := [
		{"l": "Начать диалог с профсоюзами и общественными движениями (капитал −4)", "fx": {"capital": -4.0, "support": {"Рабочие": 2.0}}, "act": "wave_talk"},
		{"l": "Пойти на уступки: меры против дороговизны (долг +0,3% ВВП)", "fx": {"debt": 0.3, "all": 1.5}, "act": "wave_concede"},
		{"l": "Ужесточить порядок: полиция и запреты (капитал −3)", "fx": {"capital": -3.0, "support": {"Молодёжь": -3.0, "Силовики": 2.0}}, "act": "wave_crack"},
		{"l": "Переждать: протесты сами утихнут", "fx": {}, "act": "wave_ignore"},
	]
	rv_event("wave", "Забастовки и демонстрации охватили крупнейшие города. Люди недовольны ценами, властью и будущим. Требования растут с каждым днём.", opts)


func rv_event_rev() -> void:
	var dem: float = democracy_index()
	var opts := [
		{"l": "Приказать армии и полиции разогнать толпу (капитал −8)", "fx": {"capital": -8.0}, "act": "rev_force"},
		{"l": ("Отправить правительство в отставку и назначить досрочные выборы (капитал −6)" if dem >= 0.4 else "Объявить реформы и широкую амнистию (капитал −6)"), "fx": {"capital": -6.0, "all": 2.0}, "act": "rev_early"},
		{"l": "Переговоры за круглым столом с лидерами протеста (капитал −5)", "fx": {"capital": -5.0}, "act": "rev_talks"},
		{"l": "Покинуть страну", "fx": {}, "act": "rev_flee"},
	]
	rv_event("rev", "Массовое восстание: сотни тысяч людей заняли центр столицы, захвачены административные здания. Часть гарнизона колеблется, генералы ждут приказа.", opts)


func rv_event_coup() -> void:
	var rid := regime_id()
	var t := "Ночью танки вышли на улицы столицы. Военные требуют вашей отставки, заняты телецентр и правительственные здания."
	if rid == "junta":
		t = "Внутри хунты вспыхнул мятеж: младшие офицеры заняли казармы и требуют смены руководства."
	elif rid == "monarchy_abs":
		t = "Дворцовый переворот: гвардия окружила резиденцию, заговорщики требуют вашего отречения."
	elif rid == "oneparty":
		t = "Заговор в аппарате и службах безопасности: вам предъявляют ультиматум об отставке."
	var opts := [
		{"l": "Сопротивляться: верные части и гвардия (капитал −6)", "fx": {"capital": -6.0}, "act": "coup_resist"},
		{"l": "Призвать народ на улицы (капитал −5)", "fx": {"capital": -5.0}, "act": "coup_people"},
		{"l": "Договориться: бюджет и привилегии военным (капитал −8)", "fx": {"capital": -8.0, "slider": {"army": 0.3}, "support": {"Силовики": 6.0, "Молодёжь": -3.0}}, "act": "coup_deal"},
		{"l": "Подать в отставку и передать власть", "fx": {}, "act": "coup_step"},
	]
	rv_event("coup", t, opts)


func rv_event_referendum_demand(i: int) -> void:
	var rg: Dictionary = rv_reg(i)
	rg["refcd"] = 18
	var opts := [
		{"l": "Разрешить референдум (капитал −10)", "fx": {"capital": -10.0}, "act": "ref_allow", "arg": rv_uid(i)},
		{"l": "Предложить особый статус вместо референдума (капитал −8)", "fx": {"capital": -8.0}, "act": "ref_status", "arg": rv_uid(i)},
		{"l": "Отказать: референдум неконституционен", "fx": {"support": {"Силовики": 1.0}}, "act": "ref_ban", "arg": rv_uid(i)},
		{"l": "Ввести войска и подавить движение (капитал −5)", "fx": {"capital": -5.0, "support": {"Силовики": 2.0, "Молодёжь": -3.0}}, "act": "ref_force", "arg": rv_uid(i)},
	]
	rv_event("refdem", "Региональные власти «{r}» требуют референдума о независимости. Сторонников отделения, по опросам, около %.0f%%." % (rv_yes_share(i) * 100.0), opts, i)


func rv_event_udi(i: int) -> void:
	var uid := rv_uid(i)
	var opts := [
		{"l": "Начать переговоры о мирном разводе (капитал −10)", "fx": {"capital": -10.0}, "act": "udi_peace", "arg": uid},
		{"l": "Объявить акт незаконным и ввести войска (капитал −8)", "fx": {"capital": -8.0, "support": {"Силовики": 2.0}}, "act": "udi_force", "arg": uid},
		{"l": "Предложить конфедерацию: максимум автономии (капитал −8)", "fx": {"capital": -8.0}, "act": "udi_confed", "arg": uid},
		{"l": "Ничего не предпринимать", "fx": {"support": {"Силовики": -2.0}}, "act": "udi_ignore", "arg": uid},
	]
	rv_event("udi", "Региональный парламент «{r}» провозгласил независимость. Улицы заполнены флагами, местная полиция переходит на сторону региональных властей.", opts, i)


func rv_event_ref_yes(i: int, y: float) -> void:
	var uid := rv_uid(i)
	var opts := [
		{"l": "Признать итоги и договориться о разводе (капитал −8)", "fx": {"capital": -8.0}, "act": "yes_accept", "arg": uid},
		{"l": "Не признавать итоги: референдум неконституционен", "fx": {"support": {"Силовики": 2.0}}, "act": "yes_reject", "arg": uid},
		{"l": "Предложить конфедерацию: максимум автономии (капитал −8)", "fx": {"capital": -8.0}, "act": "yes_confed", "arg": uid},
	]
	rv_event("refyes", "За независимость «{r}» проголосовало %.0f%%. Региональные власти требуют начать переговоры о разделе страны." % (y * 100.0), opts, i)


func revolt_resolve(opt: Dictionary) -> void:
	# вызывается из choose() после применения эффектов варианта
	var act := String(opt.get("act", ""))
	var uid := String(opt.get("arg", ""))
	var i: int = rv_idx(uid) if uid != "" else -1
	var nat: Dictionary = rv["nat"]
	var dem: float = democracy_index()
	match act:
		"wave_talk":
			nat["wave"] = rv_clamp(float(nat["wave"]) - 12.0)
			nat["hate"] = rv_clamp(float(nat["hate"]) - 8.0)
			rv_log("диалог с профсоюзами и движениями: накал снизился.", COL_GOOD)
		"wave_concede":
			nat["wave"] = rv_clamp(float(nat["wave"]) - 20.0)
			rv_log("уступки против дороговизны остудили улицу.", COL_GOOD)
		"wave_crack":
			var ok: bool = randf() < clampf(0.45 + (float(lvl["security_lvl"]) - 50.0) * 0.008, 0.2, 0.85)
			nat["hate"] = rv_clamp(float(nat["hate"]) + 10.0)
			nat["rev"] = rv_clamp(float(nat["rev"]) + 3.0)
			if ok:
				nat["wave"] = rv_clamp(float(nat["wave"]) - 14.0)
				rv_log("полиция разогнала акции, но улица затаила обиду.", COL_WARN)
			else:
				nat["wave"] = rv_clamp(float(nat["wave"]) + 6.0)
				rv_log("силовой разгон спровоцировал новые акции: обида и накал выросли.", COL_BAD)
			if dem > 0.6:
				dip_all(-1.0, false)
		"wave_ignore":
			nat["wave"] = rv_clamp(float(nat["wave"]) + 4.0)
		"rev_force":
			var p: float = clampf(0.30 + (float(support["Силовики"]) - 40.0) * 0.012 + (float(lvl["security_lvl"]) - 50.0) * 0.004 + (0.12 if decree_power() else 0.0), 0.08, 0.92)
			if randf() < p:
				nat["rev"] = rv_clamp(float(nat["rev"]) - 30.0)
				nat["wave"] = rv_clamp(float(nat["wave"]) - 20.0)
				nat["hate"] = rv_clamp(float(nat["hate"]) + 25.0)
				for rr in regions:
					rr["unrest"] = rv_clamp(float(rr["unrest"]) - 8.0)
				add_support("Молодёжь", -6.0)
				add_support("Экологи", -4.0)
				add_support("Силовики", 3.0)
				if dem > 0.5:
					dip_all(-2.0, false)
				rv_log("[b]восстание подавлено силой[/b] (шанс успеха был %.0f%%). Страна напугана и озлоблена." % (p * 100.0), COL_WARN)
			else:
				rv_log("[b]армия отказалась стрелять в толпу[/b] (шанс успеха был %.0f%%)." % (p * 100.0), COL_BAD)
				if randf() < 0.5:
					rv_conf_start("civil", -1, 45.0, "армия раскололась, часть войск перешла на сторону восставших")
				else:
					end_game("Революция победила: армия отказалась стрелять, толпа заняла правительственные здания. Вы низложены.")
		"rev_early":
			nat["rev"] = rv_clamp(float(nat["rev"]) - 35.0)
			nat["wave"] = rv_clamp(float(nat["wave"]) - 25.0)
			nat["hate"] = rv_clamp(float(nat["hate"]) - 10.0)
			if dem >= 0.4:
				rv_log("правительство ушло в отставку, назначены досрочные выборы.", COL_GOOD)
				hold_parliament("досрочные выборы после массовых протестов")
			else:
				rv_log("объявлены реформы и амнистия: часть восставших разошлась по домам.", COL_GOOD)
		"rev_talks":
			if randf() < 0.6:
				nat["rev"] = rv_clamp(float(nat["rev"]) - 18.0)
				nat["wave"] = rv_clamp(float(nat["wave"]) - 12.0)
				nat["hate"] = rv_clamp(float(nat["hate"]) - 10.0)
				rv_log("круглый стол: договорённость о реформах, накал снизился.", COL_GOOD)
			else:
				nat["rev"] = rv_clamp(float(nat["rev"]) + 5.0)
				nat["wave"] = rv_clamp(float(nat["wave"]) + 5.0)
				rv_log("переговоры провалились: требования радикализировались.", COL_BAD)
		"rev_flee":
			end_game("Революция: вы покинули страну, власть перешла к временному революционному комитету.")
		"coup_resist":
			var pw: float = clampf(0.30 + (float(support["Силовики"]) - 40.0) * 0.008 + (float(lvl["security_lvl"]) - 50.0) * 0.004 + approval() * 0.002 - float(nat["coup"]) * 0.002 + dem * 0.1 + float(nat["loyal"]) * 0.004, 0.1, 0.9)
			if randf() < pw:
				nat["coup"] = rv_clamp(float(nat["coup"]) - 40.0)
				nat["hate"] = rv_clamp(float(nat["hate"]) + 10.0)
				add_support("Силовики", -8.0)
				nat["loyal"] = float(nat["loyal"]) + 10.0
				rv_log("[b]переворот подавлен[/b] верными частями (шанс был %.0f%%): заговорщики арестованы, в армии чистка." % (pw * 100.0), COL_GOOD)
			else:
				rv_log("[b]часть армии поддержала заговорщиков[/b] (шанс на успех был %.0f%%)." % (pw * 100.0), COL_BAD)
				if randf() < 0.5:
					rv_conf_start("civil", -1, 45.0, "армия раскололась: верные части воюют с мятежниками")
				else:
					end_game("Переворот удался: военные взяли столицу и объявили о смене власти. Вы арестованы или бежали из страны.")
		"coup_people":
			var pp: float = clampf(0.10 + dem * 0.35 + (approval() - 30.0) * 0.006 - float(nat["wave"]) * 0.002, 0.05, 0.8)
			if randf() < pp:
				nat["coup"] = rv_clamp(float(nat["coup"]) - 45.0)
				add_all_support(6.0)
				add_support("Силовики", -10.0)
				rv_log("[b]народ вышел на улицы и остановил танки[/b] (шанс был %.0f%%): заговор сорван." % (pp * 100.0), COL_GOOD)
			else:
				end_game("Люди не вышли на улицы: переворот удался. Вы арестованы.")
		"coup_deal":
			nat["coup"] = rv_clamp(float(nat["coup"]) - 25.0)
			nat["loyal"] = float(nat["loyal"]) + 10.0
			rv_log("вы договорились с военными: больше денег и влияния армии, переворот отменён.", COL_WARN)
		"coup_step":
			end_game("Вы подали в отставку под давлением военных: власть перешла к военному совету.")
		"ref_allow":
			if i >= 0:
				rv_referendum(i, true)
		"ref_status":
			if i >= 0:
				var rg: Dictionary = rv_reg(i)
				if randf() < clampf(0.55 - float(rg["sep"]) * 0.003 - float(rg["hate"]) * 0.002, 0.2, 0.8):
					regions[i]["auto"] = rv_clamp(float(regions[i]["auto"]) + 12.0)
					rg["sep"] = rv_clamp(float(rg["sep"]) - 14.0)
					rg["hate"] = rv_clamp(float(rg["hate"]) - 8.0)
					regions[i]["loy"] = rv_clamp(float(regions[i]["loy"]) + 4.0)
					rg["refcd"] = 24
					rv_log("регион «%s» принял предложение об особом статусе: референдум отложен." % REGIONS[i]["short"], COL_GOOD)
				else:
					rg["hate"] = rv_clamp(float(rg["hate"]) + 6.0)
					rv_log("регион «%s» счёл особый статус недостаточным и настаивает на референдуме." % REGIONS[i]["short"], COL_BAD)
		"ref_ban":
			if i >= 0:
				var rg2: Dictionary = rv_reg(i)
				rg2["hate"] = rv_clamp(float(rg2["hate"]) + 8.0)
				rg2["sep"] = rv_clamp(float(rg2["sep"]) + 5.0)
				regions[i]["unrest"] = rv_clamp(float(regions[i]["unrest"]) + 6.0)
				rg2["refcd"] = 12
				if dem > 0.6:
					dip_all(-0.5, false)
				rv_log("референдум в регионе «%s» запрещён: напряжение выросло." % REGIONS[i]["short"], COL_WARN)
		"ref_force", "udi_force", "yes_reject":
			if i >= 0:
				var rg3: Dictionary = rv_reg(i)
				rg3["hate"] = rv_clamp(float(rg3["hate"]) + 12.0)
				regions[i]["loy"] = rv_clamp(float(regions[i]["loy"]) - 4.0)
				rv_conf_start("secession" if not rv_is_capital(i) else "insurgency", i, 22.0 if act == "ref_force" else 32.0, "силовой ответ на требование независимости в регионе «%s»" % REGIONS[i]["short"])
		"udi_peace", "yes_accept":
			if i >= 0:
				rv_secede(i, "peace" if act == "udi_peace" else "referendum")
		"udi_confed", "yes_confed":
			if i >= 0:
				var rg4: Dictionary = rv_reg(i)
				var pc: float = clampf(0.50 - float(rg4["sep"]) * 0.003 - float(rg4["hate"]) * 0.002 + 0.1, 0.15, 0.8)
				if randf() < pc:
					regions[i]["auto"] = rv_clamp(float(regions[i]["auto"]) + 35.0)
					rg4["sep"] = rv_clamp(float(rg4["sep"]) - 30.0)
					rg4["hate"] = rv_clamp(float(rg4["hate"]) - 10.0)
					rg4["stage"] = 1
					rg4["refcd"] = 36
					rv_log("регион «%s» согласился на конфедеративный статус (шанс был %.0f%%): независимость отложена." % [REGIONS[i]["short"], pc * 100.0], COL_GOOD)
				else:
					rv_log("регион «%s» отверг конфедерацию (шанс был %.0f%%)." % [REGIONS[i]["short"], pc * 100.0], COL_BAD)
					rv_conf_start("secession" if not rv_is_capital(i) else "insurgency", i, 40.0, "региональные власти не приняли предложение, началось вооружённое противостояние")
		"udi_ignore":
			if i >= 0:
				rv_conf_start("secession" if not rv_is_capital(i) else "insurgency", i, 45.0, "центр бездействует: региональные власти берут управление в свои руки")
		"regime":
			rv_install_regime(String(opt.get("rid", "")))
	refresh()


# ============================================================
#  ПЕРЕВОРОТЫ, КОТОРЫЕ СОВЕРШАЕТЕ ВЫ
# ============================================================


func rv_regime_options() -> Array:
	# доступные режимы: id -> индекс варианта закона «форма правления»
	var out: Array = []
	if not law_index.has("gov_form"):
		return out
	var vs: Array = law_index["gov_form"]["v"]
	for k in vs.size():
		var rid := String((vs[k] as Dictionary).get("rid", ""))
		if rid in ["dictatorship", "junta", "oneparty", "monarchy_abs"]:
			out.append({"rid": rid, "idx": k, "name": String((vs[k] as Dictionary)["n"])})
	return out


func rv_install_regime(rid: String) -> bool:
	for o in rv_regime_options():
		if String(o["rid"]) != rid:
			continue
		var idx: int = int(o["idx"])
		var cur := cur_idx("gov_form")
		var old_rid := rid_of("gov_form")
		var sd := support_delta("gov_form", idx)
		for g in sd:
			add_support(g, float(sd[g]))
			bias[g] = float(bias[g]) + float(sd[g]) * 0.4
		var std := dict_diff(variant_part("gov_form", cur, "st"), variant_part("gov_form", idx, "st", true))
		for k in std:
			lvl[k] = clampf(float(lvl[k]) + float(std[k]), 0.0, 100.0)
		law_state["gov_form"] = idx
		law_cd["gov_form"] = 24
		radical_enact("gov_form", idx, old_rid)
		recompute_mods()
		var nat: Dictionary = rv["nat"]
		nat["wave"] = rv_clamp(float(nat["wave"]) + 15.0)
		nat["hate"] = rv_clamp(float(nat["hate"]) + 15.0)
		nat["coup"] = rv_clamp(float(nat["coup"]) * 0.4)
		rv_log("[b]Установлен режим: %s.[/b]" % String(o["name"]), COL_BAD)
		# сопротивление перевороту
		var p_civ: float = clampf(0.10 + democracy_index_before() * 0.25 + float(nat["wave"]) * 0.002 - (float(support["Силовики"]) - 50.0) * 0.004, 0.05, 0.5)
		if randf() < p_civ:
			rv_conf_start("civil", -1, 35.0, "сторонники прежнего порядка взялись за оружие")
		return true
	return false


func democracy_index_before() -> float:
	return clampf(float(rv.get("dem_before", 0.6)), 0.0, 1.0)


func rv_selfcoup_prob() -> float:
	var nat: Dictionary = rv["nat"]
	var army_r: float = float(pol["army"]) / maxf(0.1, float(pol_def["army"]))
	return clampf(0.28 + (float(support["Силовики"]) - 45.0) * 0.010 + (float(lvl["security_lvl"]) - 50.0) * 0.005 + (army_r - 1.0) * 0.10 \
		+ clampf((float(nat["wave"]) - 30.0) * 0.003, 0.0, 0.15) - democracy_index() * 0.38 + float(nat["loyal"]) * 0.004, 0.05, 0.85)


func rv_selfcoup_check() -> String:
	if not rv_on():
		return "система кризисов отключена в настройках игры"
	if game_over:
		return "игра окончена"
	if opp_mode:
		return "вы в оппозиции: используйте заговор"
	if decree_power():
		return "у вас уже власть указами"
	if not current_event.is_empty() or election_open:
		return "сначала решите текущее событие"
	if capital < 12.0:
		return "нужно 12 политкапитала"
	if float(support["Силовики"]) < 38.0:
		return "нужна поддержка силовиков не ниже 38"
	if rv_cd("selfcoup") > 0:
		return "ещё %d мес." % rv_cd("selfcoup")
	if rv_regime_options().is_empty():
		return "нет доступных режимов"
	return ""


func rv_selfcoup() -> bool:
	if rv_selfcoup_check() != "":
		return false
	capital -= 12.0
	rv_cd_set("selfcoup", 60)
	rv["dem_before"] = democracy_index()
	var p := rv_selfcoup_prob()
	var nat: Dictionary = rv["nat"]
	if randf() < p:
		rv_log("[b]Самопереворот удался[/b] (шанс был %.0f%%): парламент распущен, армия на вашей стороне." % (p * 100.0), COL_BAD)
		rv_event_regime_choice()
	else:
		nat["rev"] = rv_clamp(float(nat["rev"]) + 25.0)
		nat["hate"] = rv_clamp(float(nat["hate"]) + 20.0)
		if randf() < 0.45:
			capital = maxf(0.0, capital - 10.0)
			add_support("Силовики", -12.0)
			add_all_support(-8.0)
			rv_log("[b]Попытка захвата власти провалилась[/b] (шанс был %.0f%%), но вы остались у власти: доверие подорвано, в армии чистка." % (p * 100.0), COL_BAD)
		else:
			end_game("Попытка захвата власти провалилась (шанс был %.0f%%): парламент и суды отстранили вас, вы арестованы." % (p * 100.0))
	refresh()
	return true


func rv_event_regime_choice() -> void:
	var opts: Array = []
	for o in rv_regime_options():
		opts.append({"l": String(o["name"]), "fx": {}, "act": "regime", "rid": String(o["rid"])})
	if opts.is_empty():
		return
	rv_event("newregime", "Власть в ваших руках. Какую форму правления вы установите?", opts)


func rv_oppcoup_prob() -> float:
	var nat: Dictionary = rv["nat"]
	return clampf(0.18 + (float(support["Силовики"]) - 45.0) * 0.010 + (50.0 - gov_pop()) * 0.004 + float(nat["wave"]) * 0.003 - democracy_index() * 0.30, 0.04, 0.8)


func rv_oppcoup_check() -> String:
	if not rv_on():
		return "система кризисов отключена в настройках игры"
	if not opp_mode:
		return "доступно только в оппозиции"
	if game_over:
		return "игра окончена"
	if capital < 15.0:
		return "нужно 15 политкапитала"
	if float(support["Силовики"]) < 35.0:
		return "нужна симпатия силовиков не ниже 35"
	if rv_cd("oppcoup") > 0:
		return "ещё %d мес." % rv_cd("oppcoup")
	if not current_event.is_empty() or election_open:
		return "сначала решите текущее событие"
	return ""


func rv_oppcoup() -> bool:
	if rv_oppcoup_check() != "":
		return false
	capital -= 15.0
	rv_cd_set("oppcoup", 60)
	rv["dem_before"] = democracy_index()
	var p := rv_oppcoup_prob()
	if randf() < p:
		rv_log("[b]Заговор удался[/b] (шанс был %.0f%%): правительство низложено, вы захватили власть." % (p * 100.0), COL_BAD)
		rv_take_power("государственный переворот")
		rv_event_regime_choice()
	else:
		end_game("Заговор раскрыт (шанс был %.0f%%): партия запрещена, её лидеры арестованы." % (p * 100.0))
	refresh()
	return true


func rv_uprising_check() -> String:
	if not rv_on():
		return "система кризисов отключена в настройках игры"
	if not opp_mode:
		return "доступно только в оппозиции"
	if game_over:
		return "игра окончена"
	if capital < 10.0:
		return "нужно 10 политкапитала"
	if float((rv["nat"] as Dictionary)["wave"]) < 25.0:
		return "нужна волна протестов не ниже 25"
	if rv_conf_count("civil") > 0:
		return "гражданская война уже идёт"
	if rv_cd("uprising") > 0:
		return "ещё %d мес." % rv_cd("uprising")
	return ""


func rv_uprising() -> bool:
	if rv_uprising_check() != "":
		return false
	capital -= 10.0
	rv_cd_set("uprising", 48)
	rv["dem_before"] = democracy_index()
	rv_conf_start("civil", -1, 20.0, "вы подняли народное восстание против правительства")
	var cf: Array = rv["conf"]
	if not cf.is_empty():
		(cf[cf.size() - 1] as Dictionary)["side"] = "rebel"
	refresh()
	return true


# ============================================================
#  ЗАЩИТА ОТ ПЕРЕВОРОТА
# ============================================================


func rv_coup_measure_check(id: String) -> String:
	var a: Dictionary = {}
	for x in RV_COUP_MEASURES:
		if x["id"] == id:
			a = x
	if a.is_empty():
		return "нет такого действия"
	if not rv_on() or opp_mode or game_over:
		return "недоступно"
	if rv_cd("cm_" + id) > 0:
		return "ещё %d мес." % rv_cd("cm_" + id)
	if capital < float(a["cap"]):
		return "нужно %.0f политкапитала" % float(a["cap"])
	return ""


func rv_coup_measure(id: String) -> bool:
	if rv_coup_measure_check(id) != "":
		return false
	var a: Dictionary = {}
	for x in RV_COUP_MEASURES:
		if x["id"] == id:
			a = x
	capital -= float(a["cap"])
	rv_cd_set("cm_" + id, int(a["cd"]))
	var nat: Dictionary = rv["nat"]
	match id:
		"pay":
			add_support("Силовики", 4.0)
			nat["loyal"] = float(nat["loyal"]) + 8.0
			rv["army_up"] = float(rv["army_up"]) + 0.15
			debt += gdp * 0.002
			rv_log("военным повышены жалованье и пайки: риск переворота ниже.", COL_GOOD)
		"loyal":
			nat["loyal"] = float(nat["loyal"]) + 14.0
			mods["corr_shift"] = float(mods["corr_shift"])
			lvl["corruption"] = rv_clamp(float(lvl["corruption"]) + 1.5)
			rv_log("в штабах лояльные назначения: риск переворота заметно ниже.", COL_GOOD)
		"guard":
			nat["loyal"] = float(nat["loyal"]) + 10.0
			lvl["security_lvl"] = rv_clamp(float(lvl["security_lvl"]) + 2.0)
			if democracy_index() > 0.5:
				add_support("Молодёжь", -2.0)
				dip_all(-0.5, false)
			rv_log("усилены гвардия и спецслужбы: заговор организовать труднее.", COL_WARN)
		"purge":
			nat["coup"] = rv_clamp(float(nat["coup"]) - 25.0)
			nat["loyal"] = float(nat["loyal"]) + 6.0
			add_support("Силовики", -6.0)
			rv["army_up"] = float(rv["army_up"]) - 0.12
			rv_log("чистка офицерского корпуса: заговорщики устранены, но армия напугана.", COL_WARN)
	refresh()
	return true


# ============================================================
#  ИИ (режим наблюдателя и оппозиция)
# ============================================================


func rv_ai_choice(kind: String, opts: Array) -> int:
	var dem: float = democracy_index()
	var force: float = float(support["Силовики"])
	var best := 0
	var bs := -1e9
	for k in opts.size():
		var act := String(opts[k].get("act", ""))
		var s := 0.0
		match act:
			"wave_talk":
				s = 3.0
			"wave_concede":
				s = 2.5 if debt / maxf(1.0, gdp) < 0.9 else 1.0
			"wave_crack":
				s = 1.0
			"rev_early":
				s = 3.0
			"rev_talks":
				s = 2.0
			"rev_force":
				s = 1.5 if force >= 55.0 else 0.5
			"rev_flee":
				s = -5.0
			"coup_resist":
				s = 3.0 if rv_selfcoup_prob() >= 0.0 and force >= 50.0 else 1.5
			"coup_deal":
				s = 2.5
			"coup_people":
				s = 2.0 if dem > 0.6 else 0.5
			"coup_step":
				s = -5.0
			"ref_status":
				s = 3.0
			"ref_allow":
				s = 2.0
			"ref_ban":
				s = 1.0
			"ref_force":
				s = 0.5
			"udi_confed", "yes_confed":
				s = 3.0
			"udi_peace", "yes_accept":
				s = 2.0
			"udi_force", "yes_reject":
				s = 1.0 + (1.0 if force >= 55.0 else 0.0)
			"udi_ignore":
				s = 0.0
			"regime":
				s = 1.0
		if s > bs:
			bs = s
			best = k
	return best


func rv_ai_step() -> void:
	# ИИ вместо игрока: реагирует на протесты, конфликты и риск переворота (политкапитал не тратится)
	var save := capital
	capital = 100.0
	for i in regions.size():
		var rg: Dictionary = rv_reg(i)
		var st: int = int(rg["stage"])
		if st == 0 or rv_conf_of(rv_uid(i)) >= 0:
			continue
		if st >= 3:
			rv_region_act("troops", i)
		elif st == 2:
			if float(rg["hate"]) > 40.0:
				rv_region_act("amnesty", i)
			elif not rv_region_act("talk", i):
				rv_region_act("police", i)
		elif st == 1 and float(regions[i]["unrest"]) > 45.0:
			if not rv_region_act("talk", i):
				rv_region_act("invest", i)
	for k in range(rv["conf"].size() - 1, -1, -1):
		var c: Dictionary = rv["conf"][k]
		if String(c["side"]) == "rebel":
			continue
		if float(c["ctl"]) > 55.0:
			rv_conf_act("ally", k)
			rv_conf_act("truce", k)
		elif float(c["ctl"]) < 25.0 and int(c["mob"]) > 1:
			rv_conf_act("mob_down", k)
		elif int(c["mob"]) < 2 and float(c["ctl"]) > 35.0:
			rv_conf_act("mob_up", k)
	if not opp_mode and float((rv["nat"] as Dictionary)["coup"]) >= 45.0:
		for id in ["pay", "loyal", "purge"]:
			if rv_coup_measure(id):
				break
	capital = save


func revolt_nationwide_uprising() -> bool:
	# вместо мгновенного конца игры: восстания в нескольких регионах сливаются в гражданскую войну
	if not rv_on():
		return false
	if rv_conf_count("civil") == 0:
		rv_conf_start("civil", -1, 38.0, "восстания в нескольких регионах слились в общее вооружённое противостояние")
	for i in regions.size():
		if float(regions[i]["unrest"]) >= 90.0:
			regions[i]["unrest"] = 82.0
	return true
