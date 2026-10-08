# Религии и миграция. У каждого региона — религиозный состав; у каждого агента — своя вера.
# Все эффекты считаются как ОТКЛОНЕНИЕ от стартового состава и стартового уровня миграции (страна стартует откалиброванной),
# поэтому без решений игрока и без «живой динамики» (настройка socev=0) состояние не меняется.
extends "res://scripts/logic/admin.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func ex_fx(d: Dictionary) -> void:
	pass


func ex_rel_change(cc: String, d: float) -> void:
	pass


# --- конец заглушек ---


const SOC_FAITH := ["Католики", "Протестанты", "Православные", "Мусульмане", "Иудеи", "Восточные религии", "Нерелигиозные"]
const SOC_FCOL := ["#e0b050", "#6fa8dc", "#c27ba0", "#58c887", "#8fb4ff", "#e08a5a", "#9aa4b8"]
# эффекты вероисповедания на единицу доли: [сплочённость, рост экономики, рождаемость, налоговая дисциплина]
const SOC_FX := [[0.55, -0.02, 0.10, 0.03], [0.40, 0.00, 0.00, 0.04], [0.50, -0.02, 0.05, 0.02], [0.50, -0.03, 0.50, 0.03], [0.40, 0.03, 0.10, 0.03], [0.30, 0.02, 0.05, 0.02], [-0.30, 0.04, -0.30, -0.02]]
# Примечание: различия сознательно небольшие и опираются на общие механизмы (общинный капитал, демография, налоговая мораль), а не на стереотипы о группах.
const SOC_FNOTE := [
	"Приходские общины и благотворительность: больше сплочённости, чуть выше рождаемость; недавние дети и пожилые иждивенцы слегка тормозят рост.",
	"Небольшие самоуправляемые общины и высокая налоговая мораль: сплочённость и сбор налогов — выше среднего.",
	"Общинная и семейная культура: сплочённость выше среднего, рождаемость слегка выше.",
	"Молодая возрастная структура и высокая рождаемость, плотные общины. Пока население молодо, иждивенцев больше и рост чуть ниже; при быстрой миграции без интеграции растёт напряжённость.",
	"Небольшая, городская и высокообразованная община: рост и налоги — выше среднего.",
	"Разнообразные традиции (буддизм, индуизм и др.): мягкий вклад в рост и сплочённость.",
	"Светское общество: выше занятость женщин и образование (рост), но слабее общины, низкая рождаемость и чуть ниже налоговая мораль.",
]
const SOC_MIGM := [0.25, 0.65, 1.0, 1.45, 1.9]
const SOC_IN_CAP := 22.0   # потолок притока, на 1000 жителей в год (около 2% в год — исторический максимум)
const SOC_MIGN := ["Закрытые границы", "Строгий контроль", "Нынешний курс", "Открытая политика", "Широко открытые границы"]
const SOC_PROG := ["Нет программ", "Базовые", "Расширенные", "Полная интеграция"]
const SOC_SEC := ["Союз с традиционными конфессиями", "Нынешний курс", "Светское государство", "Жёсткий секуляризм"]
const SOC_SEL := ["Без отбора", "Приоритет квалифицированных", "Строгий отбор по навыкам"]

var SOC := {}
var soc := {}
var soc_rng := RandomNumberGenerator.new()

func soc_cfg() -> Dictionary:
	if SOC.has("country") and (SOC["country"] as Dictionary).has(ccode):
		return SOC["country"][ccode]
	return {"base": [0.2, 0.2, 0.05, 0.05, 0.01, 0.01, 0.48], "reg": {}, "in0": 4.0, "out0": 3.0, "mix": [0.2, 0.3, 0.2, 0.1, 0.1, 0.1], "en": 0.5, "fdebt": 0.4, "exporter": 0}


func soc_dyn() -> bool:
	return int(game_opts.get("socev", 1)) == 1


func soc_vec(cc: String, code: String) -> Array:
	var c: Dictionary = (SOC["country"] as Dictionary).get(cc, {})
	if c.is_empty():
		return soc_cfg()["base"].duplicate()
	var rg: Dictionary = c["reg"]
	var v: Array = (rg[code] if rg.has(code) else c["base"]).duplicate()
	var sm := 0.0
	for f in 7:
		sm += float(v[f])
	if sm > 0.0:
		for f in 7:
			v[f] = float(v[f]) / sm
	return v


func soc_init() -> void:
	if SOC.is_empty():
		var d = ext_load("res://data/soc.dat")
		SOC = d if d != null else {}
	soc_rng.seed = hash(ccode) + 91
	var c := soc_cfg()
	soc = {"lvl": 2, "prog": 1, "sec": 1, "fund": 0, "sel": 0, "integ": 50.0, "integ0": 50.0, "press": 1.0, "wave": 0, "cd": {},
		"in0": float(c["in0"]), "out0": float(c["out0"]), "mix": (c["mix"] as Array).duplicate(), "g0": growth_ema, "u0": unemployment,
		"in_now": float(c["in0"]), "out_now": float(c["out0"]), "net": 0.0, "tension": 0.0, "evlog": [], "h": {"t": [], "i": [], "n": []}}
	for i in regions.size():
		var v := soc_vec(ccode, String(REGIONS[i]["code"]))
		regions[i]["rel"] = v.duplicate()
		regions[i]["rel0"] = v.duplicate()
		regions[i]["relt"] = 0.0
		regions[i]["mnet"] = 0.0


func soc_init_region(i: int, cc: String, code: String) -> void:
	var v := soc_vec(cc, code)
	regions[i]["rel"] = v.duplicate()
	regions[i]["rel0"] = v.duplicate()
	regions[i]["relt"] = 0.0
	regions[i]["mnet"] = 0.0


func soc_national() -> Array:
	var out: Array = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	for i in regions.size():
		for f in 7:
			out[f] = float(out[f]) + float(regions[i]["rel"][f]) * pop_w[i]
	return out


func soc_div(v: Array) -> float:
	var s := 0.0
	for f in 7:
		s += float(v[f]) * float(v[f])
	return 1.0 - s


func soc_delta_dot(i: int, k: int) -> float:
	# Σ (доля − стартовая доля) × эффект k
	var r: Dictionary = regions[i]
	if not r.has("rel"):
		return 0.0
	var s := 0.0
	for f in 7:
		s += (float(r["rel"][f]) - float(r["rel0"][f])) * float(SOC_FX[f][k])
	return s


func soc_abs_dot(i: int, k: int) -> float:
	var s := 0.0
	for f in 7:
		s += float(regions[i]["rel"][f]) * float(SOC_FX[f][k])
	return s


func soc_nat_delta(k: int) -> float:
	var s := 0.0
	for i in regions.size():
		s += pop_w[i] * soc_delta_dot(i, k)
	return s


func soc_nat_abs(k: int) -> float:
	var s := 0.0
	for i in regions.size():
		s += pop_w[i] * soc_abs_dot(i, k)
	return s


func soc_din() -> float:
	return float(soc["in_now"]) - float(soc["in0"])


func soc_dout() -> float:
	return float(soc["out_now"]) - float(soc["out0"])


func soc_skill() -> float:
	var sk := 0.0
	var mx: Array = soc_mix_eff()
	for o in 6:
		sk += float(mx[o]) * float(SOC["oskill"][o])
	return sk


func soc_skill0() -> float:
	var sk := 0.0
	for o in 6:
		sk += float(soc["mix"][o]) * float(SOC["oskill"][o])
	return sk


func soc_mix_eff() -> Array:
	# происхождение мигрантов с учётом отбора по навыкам
	var out: Array = []
	var tot := 0.0
	for o in 6:
		var w: float = float(soc["mix"][o]) * pow(float(SOC["oskill"][o]) / 0.5, float(soc["sel"]))
		out.append(w)
		tot += w
	for o in 6:
		out[o] = float(out[o]) / maxf(tot, 0.0001)
	return out


func soc_mig_faith() -> Array:
	var mx := soc_mix_eff()
	var out: Array = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	for o in 6:
		for f in 7:
			out[f] = float(out[f]) + float(mx[o]) * float(SOC["ofaith"][o][f])
	return out


# ---------------- влияние на государство (вызывается из регионов, бюджета, роста) ----------------


func soc_loy_term(i: int) -> float:
	var r: Dictionary = regions[i]
	if not r.has("rel"):
		return 0.0
	return 8.0 * soc_delta_dot(i, 0) + 0.3 * float(soc["fund"]) - 0.04 * float(r["relt"])


func soc_unr_term(i: int) -> float:
	var r: Dictionary = regions[i]
	if not r.has("rel"):
		return 0.0
	return -20.0 * soc_delta_dot(i, 0) - 1.2 * float(soc["fund"]) + 0.12 * float(r["relt"])


func soc_g() -> float:
	if not soc.has("lvl"):
		return 0.0
	var g: float = 15.0 * soc_nat_delta(1)
	var din: float = soc_din() - soc_dout()
	g += 0.05 * din * (0.4 + 0.6 * float(soc["integ"]) / 100.0) * (soc_skill() / maxf(0.01, soc_skill0()))
	g -= 0.02 * maxf(0.0, soc_dout())
	return g


func soc_unemp() -> float:
	if not soc.has("lvl"):
		return 0.0
	return 0.04 * soc_din() * (1.0 - float(soc["integ"]) / 100.0) * 1.6


func soc_tax() -> float:
	if not soc.has("lvl"):
		return 0.0
	return 0.02 * soc_nat_delta(3)


# ---------------- ежемесячная динамика ----------------


func soc_month() -> void:
	if not soc.has("lvl"):
		return
	for k in (soc["cd"] as Dictionary).keys():
		(soc["cd"] as Dictionary)[k] = int((soc["cd"] as Dictionary)[k]) - 1
		if int((soc["cd"] as Dictionary)[k]) <= 0:
			(soc["cd"] as Dictionary).erase(k)
	var dyn := soc_dyn()
	if int(soc["wave"]) > 0:
		soc["wave"] = int(soc["wave"]) - 1
		if int(soc["wave"]) == 0:
			soc["press"] = 1.0
			log_line("%s: волна беженцев схлынула, миграционное давление вернулось к обычному." % date_text())
	# интенсивность миграции
	var att := 1.0
	if dyn:
		att = clampf(1.0 + 0.05 * (growth_ema - float(soc["g0"])) - 0.03 * (unemployment - float(soc["u0"])), 0.6, 1.6)
	soc["in_now"] = minf(maxf(float(soc["in0"]) * 1.2, SOC_IN_CAP), float(soc["in0"]) * float(SOC_MIGM[int(soc["lvl"])]) * float(soc["press"]) * att)
	var out_f := 1.0
	if dyn:
		out_f = clampf(1.0 + 0.08 * (unemployment - float(soc["u0"])) - 0.05 * (growth_ema - float(soc["g0"])), 0.6, 2.0)
	# закрытые границы почти не толкают людей к отъезду: часть «оттока» — возвратная миграция иностранцев, она падает вместе с притоком
	soc["out_now"] = float(soc["out0"]) * out_f * (0.6 + 0.4 * minf(1.0, float(SOC_MIGM[int(soc["lvl"])])))
	var din: float = soc_din()
	var dout: float = soc_dout()
	var ptot: float = total_pop()
	var mf := soc_mig_faith()
	var net_m := 0.0
	var integ: float = float(soc["integ"])
	var tens_sum := 0.0
	for i in regions.size():
		var r: Dictionary = regions[i]
		if not r.has("rel"):
			continue
		var p: float = float(r["popm"])
		var imm: float = ptot * din / 1000.0 / 12.0 * gdp_w[i]
		var emi: float = ptot * dout / 1000.0 / 12.0 * pop_w[i]
		var nn: float = p + imm - emi
		if nn > 0.05 and (absf(imm) > 0.0 or absf(emi) > 0.0):
			for f in 7:
				var s: float = float(r["rel"][f])
				r["rel"][f] = (s * p + imm * float(mf[f]) - emi * s) / nn
			r["popm"] = nn
			r["mnet"] = float(r["mnet"]) + imm - emi
			net_m += imm - emi
		# естественная динамика религиозного состава
		if dyn:
			var bavg := 0.0
			for f in 7:
				bavg += float(r["rel"][f]) * float(SOC_FX[f][2])
			var sec_flow: float = (0.0002 + (float(soc["sec"]) - 1.0) * 0.0005) * (1.0 - 0.4 * float(soc["fund"]))
			var rs := 0.0
			for f in 7:
				var s2: float = float(r["rel"][f])
				var d: float = s2 * (float(SOC_FX[f][2]) - bavg) * 0.003
				if f < 6:
					var fl: float = s2 * sec_flow
					d -= fl
					rs += fl
				r["rel"][f] = maxf(0.0, s2 + d)
			r["rel"][6] = maxf(0.0, float(r["rel"][6]) + rs)
		var tot := 0.0
		for f in 7:
			tot += float(r["rel"][f])
		if tot > 0.0 and absf(tot - 1.0) > 1e-9:
			for f in 7:
				r["rel"][f] = float(r["rel"][f]) / tot
		# напряжённость
		var surge: float = maxf(0.0, imm / maxf(0.05, p) * 1200.0)
		var tt: float = 60.0 * (soc_div(r["rel"]) - soc_div(r["rel0"])) * (1.0 - 0.6 * integ / 100.0) + 28.0 * surge * (1.0 - integ / 100.0)
		tt = clampf(tt, 0.0, 100.0)
		r["relt"] = float(r["relt"]) + (tt - float(r["relt"])) * mrate(0.5)
		tens_sum += float(r["relt"]) * pop_w[i]
	soc["net"] = float(soc["net"]) + net_m
	# вера агентов следует за моделью (раз в 3 месяца, чтобы не тормозить ход)
	soc["syn"] = int(soc.get("syn", 0)) + 1
	if AG != null and ag_on and int(soc["syn"]) % 3 == 0:
		AG.sync_faith(regions.map(func(rg): return rg["rel"]), regions.map(func(rg): return rg["rel0"]))
	soc["tension"] = tens_sum
	var hh: Dictionary = soc["h"]
	(hh["t"] as Array).append(tens_sum)
	(hh["i"] as Array).append(float(soc["integ"]))
	(hh["n"] as Array).append(float(soc["net"]))
	for hk in ["t", "i", "n"]:
		if (hh[hk] as Array).size() > 144:
			(hh[hk] as Array).pop_front()
	# интеграция
	var it: float = 40.0 + 10.0 * float(soc["prog"]) - 0.7 * minf(maxf(0.0, din), 12.0) - 0.2 * tens_sum
	if dyn or din != 0.0:
		soc["integ"] = clampf(integ + (it - integ) * mrate(0.35), 0.0, 100.0)
	# расходы
	var cost: float = (float(soc["prog"]) - 1.0) * 0.0004 + float(soc["fund"]) * 0.0003
	debt += gdp * cost / 12.0
	if not dyn:
		return
	soc_events()


func soc_push_event(ev: Dictionary, rid: int = -1) -> void:
	if not current_event.is_empty() or election_open:
		return
	current_event = ev
	event_region = rid
	if auto_event_ok(ev):
		auto_resolve_event()
	else:
		present_event()


func soc_events() -> void:
	if not current_event.is_empty() or election_open:
		return
	if soc_rng.randf() > 0.045:
		return
	var crises := 0
	for c in wsim:
		if c != ccode and not (wsim[c]["crisis"] as Dictionary).is_empty():
			crises += 1
	var kinds: Array = ["wave", "labour", "incident", "faith"]
	var ws: Array = [0.2 + 0.5 * float(crises), 0.5, 0.35 + 0.01 * float(soc["tension"]), 0.3]
	var tw := 0.0
	for w in ws:
		tw += float(w)
	var r: float = soc_rng.randf() * tw
	var kind := "faith"
	for k in kinds.size():
		r -= float(ws[k])
		if r <= 0.0:
			kind = String(kinds[k])
			break
	if kind == "wave":
		if int(soc["wave"]) > 0:
			return
		soc_push_event({"t": "Новая волна беженцев из зон конфликта у границ: десятки тысяч людей просят убежища. Страны региона ждут вашего решения.", "o": [
			{"l": "Принять квоту (расходы +0.1% ВВП)", "fx": {"debt": 0.1, "support": {"Молодёжь": 2.0, "Силовики": -2.0, "Село": -2.0}, "soc": {"wave": 12, "press": 1.7}}},
			{"l": "Закрыть границу (вернее — усилить контроль)", "fx": {"support": {"Силовики": 3.0, "Село": 2.0, "Молодёжь": -2.0}, "soc": {"wave": 6, "press": 1.25}}},
			{"l": "Просить поддержки партнёров (капитал -4)", "fx": {"capital": -4.0, "soc": {"wave": 9, "press": 1.4}}}]})
	elif kind == "labour":
		soc_push_event({"t": "Бизнес бьёт тревогу: не хватает рабочих рук и специалистов. Предприятия просят упростить въезд квалифицированных работников.", "o": [
			{"l": "Упростить визы для специалистов (капитал -4)", "fx": {"capital": -4.0, "support": {"Бизнес": 3.0, "Рабочие": -1.0}, "soc": {"sel": 1}}},
			{"l": "Расширить общий приём (больше мигрантов)", "fx": {"support": {"Бизнес": 2.0, "Село": -2.0}, "soc": {"lvl": 1}}},
			{"l": "Ничего не менять: поддержать своих безработных", "fx": {"support": {"Рабочие": 2.0, "Бизнес": -3.0}}}]})
	elif kind == "incident":
		var worst := 0
		for i in regions.size():
			if float(regions[i].get("relt", 0.0)) > float(regions[worst].get("relt", 0.0)):
				worst = i
		soc_push_event({"t": "Столкновение на межконфессиональной почве в регионе «{r}»: пострадавшие, акции протеста с обеих сторон.", "o": [
			{"l": "Жёсткие меры полиции (капитал -2)", "fx": {"capital": -2.0, "support": {"Силовики": 3.0, "Молодёжь": -2.0}, "soc": {"tension_r": -12.0}}},
			{"l": "Созвать межконфессиональный совет (капитал -5)", "fx": {"capital": -5.0, "soc": {"tension_r": -22.0, "integ": 2.0}}},
			{"l": "Не вмешиваться", "fx": {"soc": {"tension_r": 10.0}}}]}, worst)
	else:
		soc_push_event({"t": "Общины требуют уважения к религиозным традициям: спор о праздниках, школьных программах и символах в публичных местах.", "o": [
			{"l": "Подтвердить светский курс", "fx": {"support": {"Молодёжь": 3.0, "Экологи": 1.0, "Пенсионеры": -3.0, "Село": -2.0}, "soc": {"sec": 1}}},
			{"l": "Пойти навстречу традиционным общинам", "fx": {"support": {"Пенсионеры": 3.0, "Село": 2.0, "Молодёжь": -3.0}, "soc": {"sec": -1}}},
			{"l": "Компромисс (капитал -4)", "fx": {"capital": -4.0, "soc": {"tension_all": -5.0}}}]})


func soc_fx(d: Dictionary) -> void:
	if not soc.has("lvl"):
		return
	if d.has("press"):
		soc["press"] = float(d["press"])
	if d.has("wave"):
		soc["wave"] = int(d["wave"])
	if d.has("lvl"):
		soc["lvl"] = clampi(int(soc["lvl"]) + int(d["lvl"]), 0, 4)
	if d.has("sel"):
		soc["sel"] = clampi(int(soc["sel"]) + int(d["sel"]), 0, 2)
	if d.has("sec"):
		soc["sec"] = clampi(int(soc["sec"]) + int(d["sec"]), 0, 3)
	if d.has("integ"):
		soc["integ"] = clampf(float(soc["integ"]) + float(d["integ"]), 0.0, 100.0)
	if d.has("tension_all"):
		for r in regions:
			r["relt"] = clampf(float(r["relt"]) + float(d["tension_all"]), 0.0, 100.0)
	if d.has("tension_r") and event_region >= 0 and event_region < regions.size():
		regions[event_region]["relt"] = clampf(float(regions[event_region]["relt"]) + float(d["tension_r"]), 0.0, 100.0)
	if d.has("rel"):
		for cc in d["rel"]:
			ex_rel_change(String(cc), float(d["rel"][cc]))
	if d.has("ex"):
		ex_fx(d["ex"])


# ---------------- действия игрока ----------------


func soc_cd_get(k: String) -> int:
	return int((soc["cd"] as Dictionary).get(k, 0))


func soc_spend(cost: float) -> bool:
	if game_over:
		return false
	if capital < cost:
		log_line("[color=%s]Не хватает политического капитала (нужно %.0f).[/color]" % [COL_BAD, cost])
		return false
	capital -= cost
	return true


func soc_set_mig(dir: int) -> bool:
	var v: int = int(soc["lvl"]) + dir
	if v < 0 or v > 4 or soc_cd_get("lvl") > 0:
		return false
	if not soc_spend(8.0):
		return false
	soc["lvl"] = v
	(soc["cd"] as Dictionary)["lvl"] = 6
	if dir > 0:
		add_support("Бизнес", 1.5)
		add_support("Молодёжь", 1.0)
		add_support("Село", -2.5)
		add_support("Силовики", -1.5)
	else:
		add_support("Село", 2.0)
		add_support("Силовики", 1.5)
		add_support("Молодёжь", -1.5)
		add_support("Бизнес", -1.0)
	log_line("[b]%s: миграционная политика — «%s».[/b]" % [date_text(), SOC_MIGN[v]])
	refresh()
	return true


func soc_set_prog(dir: int) -> bool:
	var v: int = int(soc["prog"]) + dir
	if v < 0 or v > 3 or soc_cd_get("prog") > 0:
		return false
	if not soc_spend(5.0):
		return false
	soc["prog"] = v
	(soc["cd"] as Dictionary)["prog"] = 6
	log_line("%s: программы интеграции — «%s»." % [date_text(), SOC_PROG[v]])
	refresh()
	return true


func soc_set_sel(dir: int) -> bool:
	var v: int = int(soc["sel"]) + dir
	if v < 0 or v > 2 or soc_cd_get("sel") > 0:
		return false
	if not soc_spend(6.0):
		return false
	soc["sel"] = v
	(soc["cd"] as Dictionary)["sel"] = 9
	add_support("Бизнес", 1.0 * float(dir))
	log_line("%s: отбор мигрантов — «%s»." % [date_text(), SOC_SEL[v]])
	refresh()
	return true


func soc_set_sec(dir: int) -> bool:
	var v: int = int(soc["sec"]) + dir
	if v < 0 or v > 3 or soc_cd_get("sec") > 0:
		return false
	if not soc_spend(8.0):
		return false
	soc["sec"] = v
	(soc["cd"] as Dictionary)["sec"] = 12
	var k := float(dir)
	add_support("Молодёжь", 3.0 * k)
	add_support("Экологи", 1.0 * k)
	add_support("Пенсионеры", -3.0 * k)
	add_support("Село", -2.5 * k)
	log_line("[b]%s: отношения государства и религии — «%s».[/b]" % [date_text(), SOC_SEC[v]])
	refresh()
	return true


func soc_set_fund(dir: int) -> bool:
	var v: int = int(soc["fund"]) + dir
	if v < 0 or v > 2 or soc_cd_get("fund") > 0:
		return false
	if not soc_spend(6.0):
		return false
	soc["fund"] = v
	(soc["cd"] as Dictionary)["fund"] = 9
	log_line("%s: поддержка религиозных общин — уровень %d (расходы %.2f%% ВВП в год)." % [date_text(), v, 0.03 * float(v)])
	refresh()
	return true


func soc_dialog() -> bool:
	if soc_cd_get("dialog") > 0:
		return false
	if not soc_spend(6.0):
		return false
	(soc["cd"] as Dictionary)["dialog"] = 12
	for r in regions:
		r["relt"] = maxf(0.0, float(r["relt"]) - 15.0)
	soc["integ"] = minf(100.0, float(soc["integ"]) + 2.0)
	log_line("%s: созван межконфессиональный совет — напряжённость снижена во всех регионах." % date_text())
	refresh()
	return true


func soc_dominant(i: int) -> int:
	var b := 0
	for f in 7:
		if float(regions[i]["rel"][f]) > float(regions[i]["rel"][b]):
			b = f
	return b


func soc_effect_text(k: int) -> String:
	return ""
