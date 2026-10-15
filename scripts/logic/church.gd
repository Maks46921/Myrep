# v55_1: церковь и религиозная политика. Главная церковь страны (из data/cult.dat): влияние, отношения с властью,
# государственная религия или светское государство, способ финансирования, религиозность регионов, соперничающая церковь.
# Церковь давит на «моральные» законы (аборты, браки, семья, воскресная торговля, религия в школах): её позиция по закону —
# вариант, который больше нравится пенсионерам и селу и меньше — молодёжи и экологам.
# Как и всё в обществе, эффекты считаются от стартового состояния; живая динамика (секуляризация, обращение, события) — только при socev=1.
extends "res://scripts/logic/culture.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func con_rb_nat(k: String) -> float:
	return 0.0


func mil_at_war() -> bool:
	return false


# --- конец заглушек ---


const CH_FIN := ["Сама (пожертвования)", "Церковный налог", "Из государственного бюджета"]
const CH_FIN_COST := [0.0, 0.0, 0.0006]     # доля ВВП в год
# слова в id законов, которые церковь считает «своими»
const CH_LAW_KEYS := ["abort", "lgbt", "marri", "partnership", "church", "relig", "sunday", "family", "euthan", "cannab", "drug_pol", "blasph", "gender", "sex_ed"]
const CH_LAW_SKIP := ["china", "family_support", "family_benefits", "family_tax"]
# праздники: вера → [[месяц, название], ...]; у мусульман месяц считается по году (лунный календарь)
const CH_HOLI := {
	0: [[12, "Рождество"], [4, "Пасха"], [8, "Успение Богородицы"]],
	1: [[12, "Рождество"], [4, "Пасха"], [10, "День Реформации"]],
	2: [[1, "Рождество"], [4, "Пасха"], [8, "Преображение Господне"]],
	4: [[4, "Песах"], [9, "Йом-кипур"]],
	5: [[2, "Лунный Новый год"], [11, "Дивали"]],
}
const CH_LOY_K := 0.10
const CH_VOTE_K := 0.006

var ch := {}
var ch_rng := RandomNumberGenerator.new()


func ch_on() -> bool:
	return ch.has("faith")


# v55_3: подпись действующего варианта закона «Религия и государство» у стран с государственной
# или народной церковью (Дания, Финляндия, Греция…): вызывается из law_fit_generic до church_init
func ch_law_label(vs: Array) -> void:
	if CU.is_empty():
		var d = ext_load("res://data/cult.dat")
		CU = d if d != null else {}
	var chc: Dictionary = cu_cfg().get("church", {})
	if not chc.is_empty() and int(chc.get("state", -1)) >= 0:
		vs[0]["n"] = "Государственная (народная) церковь"
		vs[0]["d"] = "Действующий порядок: «%s» закреплена в конституции; другие религии свободны." % String(chc["name"])


func church_init() -> void:
	ch_rng.seed = hash(ccode) + 173
	var c: Dictionary = cu_cfg()["church"]
	if c.is_empty():
		ch = {}
		return
	var f: int = int(c["faith"])
	ch = {"name": String(c["name"]), "faith": f, "state": int(c["state"]), "state0": int(c["state"]), "fin": int(c["fin"]), "fin0": int(c["fin"]),
		"pow": float(c["pow"]), "pow0": float(c["pow"]), "rel": 60.0, "rel0": 60.0, "off": 0.0, "prom": {}, "cd": {}, "evlog": [], "conv": 0.0,
		"h": {"p": [], "r": [], "pi": []}, "riv": {}}
	if c.has("rival"):
		var s: float = float(c["rival"]["share"])
		ch["riv"] = {"name": String(c["rival"]["name"]), "share": s, "share0": s, "ten": ch_riv_target(s, 0.0), "ten0": ch_riv_target(s, 0.0), "hate": 0.0}
	ch_init_piety(float(c["piety"]))
	ch["mis0"] = ch_mismatch()
	ch["pie0"] = ch_nat_piety()


func ch_init_piety(p: float) -> void:
	# села и менее развитые регионы религиознее; средняя по населению = данным страны
	var raw: Array = []
	var avg := 0.0
	for i in regions.size():
		var v: float = maxf(1.0, p * (1.25 - 0.5 * float(regions[i]["dev"]) / 100.0))
		raw.append(v)
		avg += v * cu_pw(i)
	var k: float = p / maxf(0.01, avg)
	for i in regions.size():
		church_init_region(i, clampf(float(raw[i]) * k, 1.0, 95.0))


func church_init_region(i: int, pie: float = -1.0) -> void:
	if not ch_on():
		return
	if pie < 0.0:
		pie = ch_nat_piety()
	regions[i]["pie"] = pie
	regions[i]["pie0"] = pie


func ch_nat_piety() -> float:
	var s := 0.0
	for i in regions.size():
		s += float(regions[i].get("pie", 0.0)) * cu_pw(i)
	return s


func ch_riv_target(s: float, hate: float) -> float:
	return clampf(140.0 * s * (1.0 - s) + 0.5 * hate, 0.0, 100.0)


# доля верующих главной церкви в регионе
func ch_believers(i: int) -> float:
	if not ch_on() or not regions[i].has("rel"):
		return 0.0
	var b: float = float(regions[i]["rel"][int(ch["faith"])])
	if not (ch["riv"] as Dictionary).is_empty():
		b *= 1.0 - float(ch["riv"]["share"])
	return b


func ch_faith_name(f: int) -> String:
	return String(SOC_FAITH[f]) if f >= 0 and f < SOC_FAITH.size() else "—"


func ch_state_name() -> String:
	var s: int = int(ch.get("state", -1))
	return "Светское государство" if s < 0 else "Государственная религия: " + ch_faith_name(s).to_lower()


# ---------------- законы, которые волнуют церковь ----------------


func ch_is_moral(tid: String) -> bool:
	for k in CH_LAW_SKIP:
		if tid.find(k) >= 0:
			return false
	for k in CH_LAW_KEYS:
		if tid.find(k) >= 0:
			return true
	return false


func ch_score(tid: String, idx: int) -> float:
	var s: Dictionary = variant_part(tid, idx, "s")
	return float(s.get("Пенсионеры", 0.0)) + float(s.get("Село", 0.0)) - float(s.get("Молодёжь", 0.0)) - 0.5 * float(s.get("Экологи", 0.0))


# [[tid, лучший для церкви вариант, насколько текущий хуже], ...]
func ch_laws() -> Array:
	var out: Array = []
	for tid in law_state:
		if not law_index.has(tid) or not ch_is_moral(String(tid)):
			continue
		var vs: Array = law_index[tid]["v"]
		var cur := cur_idx(tid)
		var best := cur
		var bs := ch_score(tid, cur)
		for k in vs.size():
			var sc := ch_score(tid, k)
			if sc > bs + 0.01:
				bs = sc
				best = k
		out.append([String(tid), best, bs - ch_score(tid, cur)])
	return out


func ch_mismatch() -> float:
	var s := 0.0
	for it in ch_laws():
		s += minf(6.0, float(it[2]))
	return s


# ---------------- влияние на государство ----------------


func ch_rel_target() -> float:
	var t: float = float(ch["rel0"])
	t -= 2.2 * (ch_mismatch() - float(ch["mis0"]))
	var f: int = int(ch["faith"])
	t += 12.0 * (float(int(ch["state"]) == f) - float(int(ch["state0"]) == f))
	t -= 8.0 * (float(int(ch["state"]) >= 0 and int(ch["state"]) != f) - float(int(ch["state0"]) >= 0 and int(ch["state0"]) != f))
	t += 7.0 * (float(int(ch["fin"]) == 2) - float(int(ch["fin0"]) == 2)) + 3.0 * (float(int(ch["fin"]) == 1) - float(int(ch["fin0"]) == 1))
	t -= 6.0 * (float(soc.get("sec", 1)) - 1.0)
	t += 3.0 * float(soc.get("fund", 0))
	t += minf(10.0, 0.5 * con_rb_nat("chrel"))
	return clampf(t + float(ch["off"]), 0.0, 100.0)


func ch_drel() -> float:
	return float(ch["rel"]) - float(ch["rel0"])


func church_loy_term(i: int) -> float:
	if not ch_on() or not regions[i].has("pie"):
		return 0.0
	var b := ch_believers(i)
	var t: float = CH_LOY_K * ch_drel() * b * (float(regions[i]["pie"]) / 50.0 + 0.3) * (float(ch["pow"]) / 60.0)
	# государственная религия задевает иноверцев региона
	var other: float = 1.0 - float(regions[i]["rel"][int(ch["faith"])]) - float(regions[i]["rel"][6]) if regions[i].has("rel") else 0.0
	t -= 6.0 * maxf(0.0, other) * (ch_state_other() - ch_state_other0())
	return t


func ch_state_other() -> float:
	return 1.0 if int(ch["state"]) >= 0 else 0.0


func ch_state_other0() -> float:
	return 1.0 if int(ch["state0"]) >= 0 else 0.0


func church_unr_term(i: int) -> float:
	if not ch_on() or not regions[i].has("pie"):
		return 0.0
	var t: float = -0.6 * church_loy_term(i)
	var rv_d: Dictionary = ch["riv"]
	if not rv_d.is_empty():
		t += 0.25 * (float(rv_d["ten"]) - float(rv_d["ten0"])) * float(regions[i]["rel"][int(ch["faith"])])
	return t


# поддержка церкви на выборах: правящая партия (слот 0) выигрывает или теряет у верующих
func church_vote_mult(ri: int, p: int) -> float:
	if p != 0 or not ch_on() or ri < 0 or ri >= regions.size() or not regions[ri].has("pie"):
		return 1.0
	var m: float = 1.0 + CH_VOTE_K * ch_drel() * ch_believers(ri) * (float(regions[ri]["pie"]) / 50.0 + 0.3) * (float(ch["pow"]) / 60.0)
	return clampf(m, 0.7, 1.3)


# ---------------- ежемесячная динамика ----------------


func church_month() -> void:
	if not ch_on():
		return
	var cd: Dictionary = ch["cd"]
	for k in cd.keys():
		cd[k] = int(cd[k]) - 1
		if int(cd[k]) <= 0:
			cd.erase(k)
	ch_prom_step()
	var dyn := soc_dyn()
	var f: int = int(ch["faith"])
	if dyn:
		# секуляризация и возрождение веры
		var war_k: float = 1.0 if mil_at_war() else 0.0
		for i in regions.size():
			var r: Dictionary = regions[i]
			if not r.has("pie"):
				continue
			var sp: float = 0.35 + 0.012 * (float(r["dev"]) - 50.0) + 0.25 * (float(soc.get("sec", 1)) - 1.0)
			sp -= 0.3 * float(int(ch["state"]) == f) + 0.15 * float(int(ch["fin"]) == 2) + 0.6 * war_k
			sp -= 0.03 * maxf(0.0, unemployment - float(soc.get("u0", unemployment)))
			sp -= 0.004 * (float(ch["pow"]) - 50.0) + 0.15 * con_rb(i, "pie")
			r["pie"] = clampf(float(r["pie"]) - sp / 12.0 * (float(r["pie"]) / 50.0 + 0.2), 1.0, 95.0)
			# обращение нерелигиозных в государственную веру
			var st: int = int(ch["state"])
			if st >= 0 and st < 6 and r.has("rel"):
				var fl: float = float(r["rel"][6]) * 0.0015 / 12.0 * (float(r["pie"]) / 50.0)
				r["rel"][6] = float(r["rel"][6]) - fl
				r["rel"][st] = float(r["rel"][st]) + fl
				ch["conv"] = float(ch["conv"]) + fl * float(r["popm"]) * 1000000.0
		# соперничающая церковь
		var rv_d: Dictionary = ch["riv"]
		if not rv_d.is_empty():
			rv_d["hate"] = float(rv_d["hate"]) * 0.97
			rv_d["ten"] = clampf(float(rv_d["ten"]) + (ch_riv_target(float(rv_d["share"]), float(rv_d["hate"])) - float(rv_d["ten"])) * 0.1, 0.0, 100.0)
		# отношения и влияние
		ch["off"] = float(ch["off"]) * 0.98
		ch["rel"] = clampf(float(ch["rel"]) + (ch_rel_target() - float(ch["rel"])) * 0.12, 0.0, 100.0)
		var pt: float = float(ch["pow0"]) + 0.6 * (ch_nat_piety() - float(ch["pie0"])) + 8.0 * (float(int(ch["state"]) == f) - float(int(ch["state0"]) == f)) \
			+ 4.0 * (float(int(ch["fin"]) == 2) - float(int(ch["fin0"]) == 2)) - 4.0 * (float(soc.get("sec", 1)) - 1.0)
		ch["pow"] = clampf(float(ch["pow"]) + (clampf(pt, 2.0, 98.0) - float(ch["pow"])) * 0.03, 0.0, 100.0)
	var hh: Dictionary = ch["h"]
	(hh["p"] as Array).append(float(ch["pow"]))
	(hh["r"] as Array).append(float(ch["rel"]))
	(hh["pi"] as Array).append(ch_nat_piety())
	for hk in ["p", "r", "pi"]:
		if (hh[hk] as Array).size() > 144:
			(hh[hk] as Array).pop_front()
	# финансирование из бюджета (сверх стартового)
	var cost: float = float(CH_FIN_COST[int(ch["fin"])]) - float(CH_FIN_COST[int(ch["fin0"])])
	if cost != 0.0:
		debt += gdp * cost / 12.0
	if dyn:
		ch_holidays()
		ch_events()


func ch_fin_cost_now() -> float:
	if not ch_on():
		return 0.0
	return (float(CH_FIN_COST[int(ch["fin"])]) - float(CH_FIN_COST[int(ch["fin0"])])) * gdp


func ch_prom_step() -> void:
	var pr: Dictionary = ch["prom"]
	if pr.is_empty():
		return
	var tid: String = pr["tid"]
	if law_state.has(tid) and cur_idx(tid) == int(pr["idx"]):
		ch["off"] = float(ch["off"]) + 8.0
		log_line("[color=%s]%s: обещание церкви выполнено — закон «%s» принят.[/color]" % [COL_GOOD, date_text(), String(law_index[tid]["name"])])
		ch["prom"] = {}
		return
	pr["left"] = int(pr["left"]) - 1
	if int(pr["left"]) <= 0:
		ch["off"] = float(ch["off"]) - 14.0
		ch["pow"] = minf(100.0, float(ch["pow"]) + 1.0)
		log_line("[color=%s]%s: церковь обвиняет власть в невыполненном обещании (закон «%s»).[/color]" % [COL_BAD, date_text(), String(law_index[tid]["name"]) if law_index.has(tid) else tid])
		ch["prom"] = {}


func ch_holi_list(f: int) -> Array:
	if f == 3:
		# Ураза-байрам и Курбан-байрам смещаются примерно на 11 дней в год раньше
		var d1: float = fposmod(79.0 - 10.875 * float(year - 2026), 365.0)
		var d2: float = fposmod(147.0 - 10.875 * float(year - 2026), 365.0)
		return [[int(d1 / 30.44) + 1, "Ураза-байрам"], [int(d2 / 30.44) + 1, "Курбан-байрам"]]
	return CH_HOLI.get(f, [])


func ch_holidays() -> void:
	var nat := soc_national()
	for f in 6:
		if f != int(ch["faith"]) and float(nat[f]) < 0.04:
			continue
		for hd in ch_holi_list(f):
			if int(hd[0]) != month:
				continue
			if f == int(ch["faith"]):
				ch["off"] = float(ch["off"]) + 0.5
				if ch_rng.randf() < 0.25 and current_event.is_empty():
					ch_fire_holiday(f, String(hd[1]))
				else:
					log_line("%s: %s — праздник верующих (%s)." % [date_text(), String(hd[1]), ch_faith_name(f).to_lower()])
			elif ch_rng.randf() < 0.3 and current_event.is_empty():
				ch_fire_minority_holiday(f, String(hd[1]), float(nat[f]))


func ch_fire_holiday(f: int, nm: String) -> void:
	ch_push({"t": "%s: %s приглашает руководство страны на праздничную службу. Камеры будут вести трансляцию." % [nm, String(ch["name"])], "o": [
		{"l": "Прийти на службу", "fx": {"support": {"Пенсионеры": 1.0, "Село": 1.0, "Молодёжь": -0.5}, "church": {"rel": 3.0}}},
		{"l": "Поздравить верующих обращением", "fx": {"church": {"rel": 1.0}}},
		{"l": "Не участвовать: государство светское", "fx": {"support": {"Молодёжь": 0.5, "Пенсионеры": -0.5}, "church": {"rel": -2.0}}}]})


func ch_fire_minority_holiday(f: int, nm: String, share: float) -> void:
	ch_push({"t": "%s: община (%s, %.0f%% населения) просит сделать праздник выходным днём там, где она живёт." % [nm, ch_faith_name(f).to_lower(), share * 100.0], "o": [
		{"l": "Разрешить местный выходной", "fx": {"support": {"Молодёжь": 0.5, "Бизнес": -0.5, "Силовики": -0.5}, "soc": {"tension_all": -3.0}, "cult": {"cuh_all": -2.0}}},
		{"l": "Отказать: у страны единый календарь", "fx": {"support": {"Силовики": 0.5}, "soc": {"tension_all": 2.0}}}]})


func ch_push(ev: Dictionary, ri: int = -1) -> void:
	ev["kind"] = "church"
	(ch["evlog"] as Array).append("%s: %s" % [date_text(), String(ev["t"]).replace("{r}", String(REGIONS[ri]["name"]) if ri >= 0 else "")])
	if (ch["evlog"] as Array).size() > 12:
		(ch["evlog"] as Array).pop_front()
	soc_push_event(ev, ri)


func ch_events() -> void:
	if not current_event.is_empty() or election_open:
		return
	var pw: float = float(ch["pow"])
	# кризис: влиятельная церковь в конфликте с властью выводит людей на улицы
	if float(ch["rel"]) < 25.0 and pw >= 40.0 and ch_cd_get("protest") <= 0 and ch_rng.randf() < 0.05:
		(ch["cd"] as Dictionary)["protest"] = 18
		ch_fire("protest")
		return
	if ch_rng.randf() > 0.03 + 0.0004 * pw:
		return
	var kinds: Array = ["scandal", "property", "school", "pilgrim", "charity"]
	var worst: Array = []
	for it in ch_laws():
		if int(it[1]) != cur_idx(String(it[0])) and (worst.is_empty() or float(it[2]) > float(worst[2])):
			worst = it
	if not worst.is_empty() and (ch["prom"] as Dictionary).is_empty():
		kinds += ["demand", "demand", "demand"]
	if not (ch["riv"] as Dictionary).is_empty():
		kinds += ["schism", "schism"]
	var nat := soc_national()
	var minf_i := -1
	for f in 6:
		if f != int(ch["faith"]) and float(nat[f]) >= 0.03 and (minf_i < 0 or float(nat[f]) > float(nat[minf_i])):
			minf_i = f
	if minf_i >= 0:
		kinds += ["temple"]
	if ch_nat_piety() < float(ch["pie0"]) - 3.0 or mil_at_war():
		kinds += ["revival"]
	var kind: String = String(kinds[ch_rng.randi() % kinds.size()])
	if kind == "demand":
		ch_fire_demand(worst)
	elif kind == "temple":
		ch_fire_temple(minf_i)
	else:
		ch_fire(kind)


func ch_cd_get(k: String) -> int:
	return int((ch["cd"] as Dictionary).get(k, 0))


func ch_fire_demand(it: Array) -> void:
	var tid: String = it[0]
	var idx: int = it[1]
	var tn: String = String(law_index[tid]["name"])
	var vn: String = String(variant_of(tid, idx)["n"])
	ch_push({"t": "%s требует изменить закон «%s»: вариант «%s». Священники призывают верующих поддержать требование." % [String(ch["name"]), tn, vn], "o": [
		{"l": "Пообещать внести закон в течение года (капитал −2)", "fx": {"capital": -2.0, "support": {"Пенсионеры": 1.0, "Молодёжь": -1.0}, "church": {"rel": 5.0, "prom": [tid, idx]}}},
		{"l": "Отказать: законы пишет парламент", "fx": {"support": {"Молодёжь": 1.0, "Пенсионеры": -1.0, "Село": -0.5}, "church": {"rel": -8.0}}},
		{"l": "Создать общественный совет по вопросу (капитал −4)", "fx": {"capital": -4.0, "church": {"rel": 2.0}}}]})


func ch_fire_temple(f: int) -> void:
	var worst := 0
	for i in regions.size():
		if regions[i].has("rel") and float(regions[i]["rel"][f]) > float(regions[worst]["rel"][f]):
			worst = i
	var what: String = ["костёл", "кирху", "православный храм", "мечеть", "синагогу", "храм", "храм"][f]
	ch_push({"t": "Община (%s) в регионе «{r}» хочет построить большую %s. Часть жителей собирает подписи против." % [ch_faith_name(f).to_lower(), what], "o": [
		{"l": "Поддержать стройку: свобода вероисповедания", "fx": {"support": {"Молодёжь": 0.5, "Село": -1.0, "Силовики": -0.5}, "soc": {"tension_r": -6.0}, "church": {"rel": -2.0}}},
		{"l": "Отложить: провести местный референдум", "fx": {"soc": {"tension_r": 4.0}}},
		{"l": "Запретить стройку", "fx": {"support": {"Село": 1.0, "Силовики": 0.5, "Молодёжь": -1.0}, "soc": {"tension_r": 10.0}, "church": {"rel": 1.0, "rvhate": 6.0}}}]}, worst)


func ch_fire(kind: String) -> void:
	var cn: String = String(ch["name"])
	var ev := {}
	match kind:
		"protest":
			ev = {"t": "%s в открытом конфликте с властью: священники призывают к молитвенным шествиям, на улицы выходят десятки тысяч верующих." % cn, "o": [
				{"l": "Пойти на уступки и встретиться с главой церкви (капитал −6)", "fx": {"capital": -6.0, "support": {"Пенсионеры": 1.5, "Молодёжь": -1.0}, "church": {"rel": 15.0}}},
				{"l": "Выстоять: не поддаваться давлению", "fx": {"support": {"Молодёжь": 1.5, "Пенсионеры": -2.0, "Село": -2.0}, "regall": {"unrest": 6.0}, "church": {"rel": -5.0, "hate": 10.0}}},
				{"l": "Разогнать шествия силой", "fx": {"support": {"Силовики": 1.5, "Пенсионеры": -3.0, "Село": -3.0, "Молодёжь": -1.0}, "regall": {"unrest": 10.0}, "church": {"rel": -12.0, "pow": 4.0, "hate": 20.0}}}]}
		"scandal":
			ev = {"t": "Журналисты раскрыли скандал в церкви: злоупотребления и сокрытие преступлений священниками. Общество требует расследования.", "o": [
				{"l": "Создать независимую комиссию", "fx": {"support": {"Молодёжь": 1.5, "Пенсионеры": -0.5}, "church": {"rel": -6.0, "pow": -5.0, "pie_all": -1.5}}},
				{"l": "Доверить расследование самой церкви", "fx": {"support": {"Молодёжь": -1.5, "Пенсионеры": 0.5}, "church": {"rel": 4.0, "pow": -2.0, "pie_all": -0.8}}}]}
		"property":
			ev = {"t": "%s просит вернуть земли и здания, отнятые в прошлом веке, или выплатить компенсацию." % cn, "o": [
				{"l": "Вернуть имущество (долг +0.05% ВВП)", "fx": {"debt": 0.05, "support": {"Пенсионеры": 1.0, "Молодёжь": -1.0}, "church": {"rel": 8.0, "pow": 2.0}}},
				{"l": "Отказать", "fx": {"church": {"rel": -6.0}}},
				{"l": "Вернуть только храмы и монастыри", "fx": {"church": {"rel": 3.0}}}]}
		"school":
			ev = {"t": "Церковь предлагает сделать уроки религии обязательными в школах; родители и учителя спорят.", "o": [
				{"l": "Ввести обязательные уроки", "fx": {"support": {"Пенсионеры": 1.5, "Село": 1.0, "Молодёжь": -2.0, "Бюджетники": -0.5}, "church": {"rel": 7.0, "pow": 2.0, "pie_all": 0.8}, "soc": {"tension_all": 2.0}}},
				{"l": "Уроки по выбору: религия или этика", "fx": {"church": {"rel": 2.0}}},
				{"l": "Оставить школу светской", "fx": {"support": {"Молодёжь": 1.0, "Пенсионеры": -1.0}, "church": {"rel": -5.0}}}]}
		"pilgrim":
			ev = {"t": "Глава церкви объявил большое паломничество и пригласил гостей из соседних стран. Ожидаются сотни тысяч верующих.", "o": [
				{"l": "Помочь с организацией (долг +0.01% ВВП)", "fx": {"debt": 0.01, "support": {"Пенсионеры": 1.0, "Село": 0.5}, "church": {"rel": 5.0, "pie_all": 0.6}}},
				{"l": "Только обеспечить безопасность", "fx": {"church": {"rel": 1.0}}}]}
		"charity":
			ev = {"t": "Церковные приюты и столовые помогают тысячам бедных; церковь просит налоговых льгот для благотворительности.", "o": [
				{"l": "Дать льготы (долг +0.02% ВВП)", "fx": {"debt": 0.02, "support": {"Пенсионеры": 1.0, "Рабочие": 0.5}, "church": {"rel": 5.0}}},
				{"l": "Отказать", "fx": {"church": {"rel": -3.0}}}]}
		"revival":
			ev = {"t": "Социологи фиксируют возрождение интереса к вере: в трудные времена люди чаще приходят в храмы, особенно молодёжь.", "o": [
				{"l": "Поддержать церковные молодёжные программы", "fx": {"debt": 0.01, "support": {"Пенсионеры": 1.0}, "church": {"rel": 4.0, "pie_all": 1.5}}},
				{"l": "Не вмешиваться", "fx": {"church": {"pie_all": 0.8}}}]}
		"schism":
			var rn: String = String(ch["riv"]["name"])
			var worst := 0
			for i in regions.size():
				if float(regions[i].get("rel", [0, 0, 0, 0, 0, 0, 0])[int(ch["faith"])]) * cu_pw(i) > float(regions[worst].get("rel", [0, 0, 0, 0, 0, 0, 0])[int(ch["faith"])]) * cu_pw(worst):
					worst = i
			ev = {"t": "Спор двух церквей в регионе «{r}»: приходы переходят от одной к другой («%s»), у храмов стычки прихожан." % rn, "o": [
				{"l": "Поддержать главную церковь (%s)" % cn, "fx": {"support": {"Пенсионеры": 0.5}, "church": {"rel": 5.0, "riv": -0.03, "rhate": 12.0, "rvhate": 6.0}}},
				{"l": "Поддержать «%s»" % rn, "fx": {"church": {"rel": -8.0, "riv": 0.04, "rhate": 8.0}}},
				{"l": "Нейтралитет: суды решают споры об имуществе (капитал −3)", "fx": {"capital": -3.0, "church": {"rhate": -6.0}}}]}
			ch_push(ev, worst)
			return
	if not ev.is_empty():
		ch_push(ev)


func church_fx(d: Dictionary) -> void:
	if not ch_on():
		return
	if d.has("rel"):
		ch["off"] = float(ch["off"]) + float(d["rel"])
		ch["rel"] = clampf(float(ch["rel"]) + float(d["rel"]), 0.0, 100.0)
	if d.has("pow"):
		ch["pow"] = clampf(float(ch["pow"]) + float(d["pow"]), 0.0, 100.0)
	if d.has("pie_all"):
		for r in regions:
			if r.has("pie"):
				r["pie"] = clampf(float(r["pie"]) + float(d["pie_all"]), 1.0, 95.0)
	if d.has("prom"):
		ch["prom"] = {"tid": String(d["prom"][0]), "idx": int(d["prom"][1]), "left": 12}
	var rv_d: Dictionary = ch["riv"]
	if not rv_d.is_empty():
		if d.has("riv"):
			rv_d["share"] = clampf(float(rv_d["share"]) + float(d["riv"]), 0.0, 0.95)
		if d.has("rhate"):
			rv_d["hate"] = clampf(float(rv_d["hate"]) + float(d["rhate"]), 0.0, 100.0)
	if d.has("hate"):
		rv_add_hate(-1, float(d["hate"]))
	if d.has("rvhate") and event_region >= 0:
		rv_add_hate(event_region, float(d["rvhate"]))


# ---------------- действия игрока ----------------


func ch_spend(cost: float) -> bool:
	return cu_spend(cost)


# государственная религия: f — индекс веры или −1 (светское государство)
func ch_set_state(f: int) -> bool:
	if pl_deny() or not ch_on():
		return false
	if f == int(ch["state"]) or f >= 6 or f < -1 or ch_cd_get("state") > 0:
		return false
	if not ch_spend(12.0):
		return false
	var old: int = int(ch["state"])
	ch["state"] = f
	(ch["cd"] as Dictionary)["state"] = 24
	var main_f: int = int(ch["faith"])
	if f == main_f:
		add_support("Пенсионеры", 2.0)
		add_support("Село", 2.0)
		add_support("Молодёжь", -2.5)
		add_support("Экологи", -1.0)
	elif f < 0:
		add_support("Молодёжь", 2.0)
		add_support("Экологи", 1.0)
		add_support("Пенсионеры", -2.0 if old == main_f else -0.5)
		add_support("Село", -1.5 if old == main_f else -0.5)
	else:
		add_support("Пенсионеры", -2.0)
		add_support("Село", -2.0)
		add_support("Силовики", -1.0)
	# иноверцы и неверующие воспринимают государственную религию как давление
	if f >= 0:
		for r in regions:
			if r.has("rel"):
				r["relt"] = clampf(float(r["relt"]) + 25.0 * (1.0 - float(r["rel"][f]) - float(r["rel"][6])), 0.0, 100.0)
	log_line("[b]%s: %s.[/b]" % [date_text(), ch_state_name()])
	refresh()
	return true


func ch_set_fin(v: int) -> bool:
	if pl_deny() or not ch_on():
		return false
	if v < 0 or v > 2 or v == int(ch["fin"]) or ch_cd_get("fin") > 0:
		return false
	if not ch_spend(6.0):
		return false
	var up: float = float(v) - float(ch["fin"])
	ch["fin"] = v
	(ch["cd"] as Dictionary)["fin"] = 12
	add_support("Пенсионеры", 0.8 * up)
	add_support("Молодёжь", -0.8 * up)
	if v == 1:
		add_support("Бизнес", -0.5)
	log_line("[b]%s: финансирование церкви — «%s».[/b]" % [date_text(), CH_FIN[v]])
	refresh()
	return true


func ch_meet() -> bool:
	if pl_deny() or not ch_on() or ch_cd_get("meet") > 0:
		return false
	if not ch_spend(4.0):
		return false
	(ch["cd"] as Dictionary)["meet"] = 12
	church_fx({"rel": 8.0})
	add_support("Пенсионеры", 0.5)
	log_line("%s: встреча с главой церкви — отношения улучшились." % date_text())
	refresh()
	return true


func ch_criticize() -> bool:
	if pl_deny() or not ch_on() or ch_cd_get("crit") > 0:
		return false
	(ch["cd"] as Dictionary)["crit"] = 12
	church_fx({"rel": -10.0, "pow": -3.0})
	add_support("Молодёжь", 1.5)
	add_support("Пенсионеры", -1.5)
	add_support("Село", -1.0)
	log_line("%s: власть публично раскритиковала церковь за вмешательство в политику." % date_text())
	refresh()
	return true


# соперничающая церковь: +1 — признать и передать часть храмов, −1 — ограничить
func ch_rival(dir: int) -> bool:
	if pl_deny() or not ch_on() or (ch["riv"] as Dictionary).is_empty() or ch_cd_get("riv") > 0:
		return false
	if not ch_spend(8.0):
		return false
	(ch["cd"] as Dictionary)["riv"] = 18
	if dir > 0:
		church_fx({"riv": 0.05, "rel": -8.0, "rhate": 10.0})
	else:
		church_fx({"riv": -0.05, "rel": 6.0, "rhate": 15.0})
		add_support("Молодёжь", -0.5)
	log_line("[b]%s: %s «%s».[/b]" % [date_text(), "поддержка церкви" if dir > 0 else "ограничения для церкви", String(ch["riv"]["name"])])
	refresh()
	return true


func ch_effect_text() -> String:
	if not ch_on():
		return ""
	var s := 0.0
	for i in regions.size():
		s += cu_pw(i) * church_loy_term(i)
	return "Отношения с церковью %.0f (на старте %.0f), влияние %.0f: лояльность верующих регионов %s в среднем; голоса правящей партии у верующих %s%%." % [
		float(ch["rel"]), float(ch["rel0"]), float(ch["pow"]), sg(s, 1), sg(CH_VOTE_K * ch_drel() * (float(ch["pow"]) / 60.0) * 100.0 * 0.5, 1)]
