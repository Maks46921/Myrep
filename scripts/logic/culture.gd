# v55_1: народы (культуры). У каждого региона — состав по народам (словарь id → доля), народы объединены в группы.
# Государствообразующие народы (tit) и защищённые нации (prot) не ассимилируются; остальные меньшинства со временем
# ассимилируются или интегрируются — скорость зависит от культурной политики (язык, школы, автономия, курс).
# Напряжённость региона растёт с обидой меньшинств; её ОТКЛОНЕНИЕ от старта влияет на лояльность, недовольство,
# сепаратизм, рост, голоса партий меньшинств и отношения с родными странами меньшинств.
# Живая динамика (ассимиляция, рождаемость, агитация соседей, события) — только при socev=1, как у религий.
extends "res://scripts/logic/society.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func con_rb(i: int, k: String) -> float:
	return 0.0


func rv_add_hate(i: int, v: float) -> void:
	pass


# --- конец заглушек ---


const CU_LANG := ["Только государственный язык", "Региональные языки в быту", "Официальные региональные языки", "Несколько государственных языков"]
const CU_SCHOOL := ["Обучение только на государственном языке", "Родной язык как предмет", "Смешанные школы", "Полное обучение на родном языке"]
const CU_AUTO := ["Нет органов меньшинств", "Национально-культурные общества", "Советы меньшинств", "Культурная автономия"]
const CU_COURSE := ["Ассимиляция", "Интеграция", "Мультикультурализм"]
const CU_FUND := ["Без поддержки культур меньшинств", "Базовая поддержка", "Щедрая поддержка"]
const CU_POL_MAX := {"lang": 3, "school": 3, "auto": 3, "course": 2, "fund": 2}
const CU_POL_COST := {"lang": 8.0, "school": 7.0, "auto": 8.0, "course": 9.0, "fund": 5.0}
# доли мигрантских групп народов: выходцы из других частей света интегрируются, а не «растворяются»
const CU_MIG_GROUPS := ["mena", "afr", "asia", "amer"]
const CU_LOY_K := 0.34      # лояльность на пункт напряжённости сверх стартовой
const CU_UNR_K := 0.50      # недовольство на пункт
const CU_SEP_K := 0.40      # сепаратизм на пункт

var CU := {}
var cu := {}
var cu_rng := RandomNumberGenerator.new()


func cu_cfg(cc: String = "") -> Dictionary:
	if cc == "":
		cc = ccode
	if CU.has("country") and (CU["country"] as Dictionary).has(cc):
		return CU["country"][cc]
	return {"cl": ["oth"], "base": [1.0], "reg": {}, "tit": ["oth"], "prot": [], "pol": {"lang": 1, "school": 1, "auto": 1, "course": 1},
		"griev": {}, "party": {}, "orig": [[1.0], [1.0], [1.0], [1.0], [1.0], [1.0]], "church": {}, "ind": {}, "gx": {}, "mega": {}}


func cu_def(cid: String) -> Dictionary:
	if CU.has("cults") and (CU["cults"] as Dictionary).has(cid):
		return CU["cults"][cid]
	return {"name": cid, "grp": "oth", "lang": "", "home": "", "faith": 6, "fert": 1.0}


func cu_name(cid: String) -> String:
	return String(cu_def(cid)["name"])


func cu_grp(cid: String) -> String:
	return String(cu_def(cid)["grp"])


func cu_grp_name(gid: String) -> String:
	if CU.has("groups") and (CU["groups"] as Dictionary).has(gid):
		return String(CU["groups"][gid]["name"])
	return gid


func cu_col(cid: String) -> Color:
	# цвет народа: оттенок группы, сдвинутый по хэшу id (народы одной группы похожи, но различимы)
	var gid := cu_grp(cid)
	var base := Color(String(CU["groups"][gid]["col"])) if CU.has("groups") and (CU["groups"] as Dictionary).has(gid) else Color(0.6, 0.62, 0.7)
	var h: int = absi(hash(cid)) % 7
	return base.lightened(0.06 * float(h - 3)) if h >= 3 else base.darkened(0.07 * float(3 - h))


func cu_vec(cc: String, code: String) -> Dictionary:
	var c := cu_cfg(cc)
	var cl: Array = c["cl"]
	var src: Array = (c["reg"] as Dictionary).get(code, c["base"])
	var out := {}
	var sm := 0.0
	for k in cl.size():
		var v: float = float(src[k]) if k < src.size() else 0.0
		if v > 0.0:
			out[String(cl[k])] = v
			sm += v
	if sm <= 0.0:
		return {"oth": 1.0}
	for k in out:
		out[k] = float(out[k]) / sm
	return out


# вес региона по населению (новый регион из федерации или войны получает вес чуть позже, до этого — 0)
func cu_pw(i: int) -> float:
	return pop_w[i] if i >= 0 and i < pop_w.size() else 0.0


func cu_on() -> bool:
	return cu.has("pol")


func cult_init() -> void:
	if CU.is_empty():
		var d = ext_load("res://data/cult.dat")
		CU = d if d != null else {}
	cu_rng.seed = hash(ccode) + 131
	var c := cu_cfg()
	var pol: Dictionary = (c["pol"] as Dictionary).duplicate()
	pol["fund"] = 1
	cu = {"pol": pol, "pol0": pol.duplicate(), "cd": {}, "kin": {}, "dia": {}, "hate": {}, "evlog": [], "h": {"t": [], "m": []},
		"assim": 0.0, "tension": 0.0, "tension0": 0.0, "griev": (c["griev"] as Dictionary).duplicate(), "dip": {}, "pass": {}}
	for i in regions.size():
		cult_init_region(i, ccode, String(REGIONS[i]["code"]), true)
	cu["tension"] = cu_nat_tension()
	cu["tension0"] = float(cu["tension"])


# регион: состав, стартовый состав, напряжённость (для купленных/присоединённых регионов — состав их страны и стартовая напряжённость ниже текущей)
func cult_init_region(i: int, cc: String, code: String, at_start: bool = false) -> void:
	if not cu_on():
		return
	var v := cu_vec(cc, code)
	regions[i]["cul"] = v
	regions[i]["cul0"] = v.duplicate()
	regions[i]["cuh"] = 0.0
	var t := cu_target_t(i)
	regions[i]["cut"] = t
	regions[i]["cut0"] = t if at_start else t * 0.5


# ---------------- кто есть кто ----------------


func cu_tit_list() -> Array:
	return cu_cfg()["tit"]


func cu_is_tit(cid: String) -> bool:
	return cid in cu_cfg()["tit"]


func cu_is_prot(cid: String) -> bool:
	return cid in cu_cfg()["prot"]


func cu_is_mig(cid: String) -> bool:
	return cu_grp(cid) in CU_MIG_GROUPS


func cu_home(cid: String) -> String:
	var h := String(cu_def(cid)["home"])
	return h if h != ccode else ""


# близость культур: один народ — 1, одна группа — 0.6, иначе 0.25
func cu_prox(a: String, b: String) -> float:
	if a == b:
		return 1.0
	if cu_grp(a) == cu_grp(b) and cu_grp(a) != "oth":
		return 0.6
	return 0.25


# культурная близость с другой страной (по государствообразующим народам)
func cu_country_prox(cc: String) -> float:
	if not CU.has("country") or not (CU["country"] as Dictionary).has(cc):
		return 0.25
	var best := 0.0
	for a in cu_tit_list():
		for b in CU["country"][cc]["tit"]:
			best = maxf(best, cu_prox(String(a), String(b)))
	return best


func cu_national() -> Dictionary:
	var out := {}
	for i in regions.size():
		if not regions[i].has("cul"):
			continue
		var v: Dictionary = regions[i]["cul"]
		for k in v:
			out[k] = float(out.get(k, 0.0)) + float(v[k]) * cu_pw(i)
	return out


func cu_national0() -> Dictionary:
	var out := {}
	for i in regions.size():
		if not regions[i].has("cul0"):
			continue
		var v: Dictionary = regions[i]["cul0"]
		for k in v:
			out[k] = float(out.get(k, 0.0)) + float(v[k]) * cu_pw(i)
	return out


func cu_sorted(v: Dictionary) -> Array:
	var items: Array = []
	for k in v:
		items.append([k, float(v[k])])
	items.sort_custom(func(a, b): return float(a[1]) > float(b[1]))
	return items


func cu_minority_share(i: int) -> float:
	if not regions[i].has("cul"):
		return 0.0
	var v: Dictionary = regions[i]["cul"]
	var t := 0.0
	for k in v:
		if not cu_is_tit(String(k)):
			t += float(v[k])
	return t


func cu_dominant(i: int) -> String:
	if not regions[i].has("cul"):
		return "oth"
	var best := "oth"
	var bv := -1.0
	var v: Dictionary = regions[i]["cul"]
	for k in v:
		if float(v[k]) > bv:
			bv = float(v[k])
			best = String(k)
	return best


# крупнейший государствообразующий народ региона (к нему идёт ассимиляция); "" — если в регионе их нет
func cu_region_tit(i: int) -> String:
	var v: Dictionary = regions[i].get("cul", {})
	var best := ""
	var bv := 0.0
	for k in cu_tit_list():
		if float(v.get(k, 0.0)) > bv:
			bv = float(v.get(k, 0.0))
			best = String(k)
	return best


# ---------------- политика и обида ----------------


# насколько политика ограничивает меньшинства: 0 — самая мягкая, 1 — самая жёсткая
func cu_restrict(p: Dictionary) -> float:
	return (3.0 - float(p["lang"])) / 3.0 * 0.30 + (3.0 - float(p["school"])) / 3.0 * 0.34 + (3.0 - float(p["auto"])) / 3.0 * 0.20 + (2.0 - float(p["course"])) / 2.0 * 0.16


func cu_dr() -> float:
	if not cu_on():
		return 0.0
	return cu_restrict(cu["pol"]) - cu_restrict(cu["pol0"])


func cu_griev(cid: String, i: int = -1) -> float:
	if cu_is_tit(cid):
		return 0.0
	var g: float = float((cu["griev"] as Dictionary).get(cid, 0.18 if not cu_is_mig(cid) else 0.12))
	var dr := cu_dr()
	g += dr * (0.45 if cu_is_mig(cid) else 0.95)
	g -= 0.05 * (float(cu["pol"]["fund"]) - float(cu["pol0"]["fund"]))
	var h := cu_home(cid)
	if h != "":
		g += 0.0018 * float((cu["kin"] as Dictionary).get(h, {}).get("agit", 0.0))
	g += 0.004 * float((cu["hate"] as Dictionary).get(cid, 0.0))
	if i >= 0:
		g += 0.003 * float(regions[i].get("cuh", 0.0))
	return clampf(g, 0.0, 1.0)


func cu_target_t(i: int) -> float:
	if not regions[i].has("cul"):
		return 0.0
	var v: Dictionary = regions[i]["cul"]
	var t := 0.0
	for k in v:
		var s: float = float(v[k])
		if s < 0.003 or cu_is_tit(String(k)):
			continue
		# крупная община в регионе сильнее ощущает свои права; совсем мелкие — слабее
		t += s * cu_griev(String(k), i) * (1.0 + 1.2 * minf(s, 0.5))
	return clampf(t * 125.0 - con_rb(i, "cut") * minf(1.0, cu_minority_share(i) * 4.0), 0.0, 100.0)


func cu_nat_tension() -> float:
	var s := 0.0
	for i in regions.size():
		s += float(regions[i].get("cut", 0.0)) * cu_pw(i)
	return s


func cu_dt(i: int) -> float:
	var r: Dictionary = regions[i]
	if not r.has("cut"):
		return 0.0
	return float(r["cut"]) - float(r["cut0"])


# ---------------- влияние на государство ----------------


func cult_loy_term(i: int) -> float:
	if not cu_on():
		return 0.0
	return -CU_LOY_K * cu_dt(i)


func cult_unr_term(i: int) -> float:
	if not cu_on():
		return 0.0
	return CU_UNR_K * cu_dt(i)


func cult_sep_term(i: int) -> float:
	if not cu_on():
		return 0.0
	return CU_SEP_K * cu_dt(i)


func cult_g() -> float:
	if not cu_on():
		return 0.0
	var s := 0.0
	for i in regions.size():
		s += cu_pw(i) * cu_dt(i)
	var g: float = -0.012 * s
	# интеграция мигрантов: при мультикультурной/интеграционной политике и поддержке культур — небольшой плюс к росту
	g += 0.03 * (float(cu["pol"]["fund"]) - float(cu["pol0"]["fund"])) * cu_mig_share()
	return g


func cu_mig_share() -> float:
	var nat := cu_national()
	var s := 0.0
	for k in nat:
		if cu_is_mig(String(k)):
			s += float(nat[k])
	return s


# партии меньшинств: голоса растут вместе с долей своего народа и с его напряжённостью
func cult_vote_mult(ri: int, p: int) -> float:
	if not cu_on() or ri < 0 or ri >= regions.size():
		return 1.0
	var cid := cu_party_cult(p)
	if cid == "":
		return 1.0
	var r: Dictionary = regions[ri]
	if not r.has("cul"):
		return 1.0
	var s: float = float((r["cul"] as Dictionary).get(cid, 0.0))
	var s0: float = float((r["cul0"] as Dictionary).get(cid, 0.0))
	var m: float = 1.0 + 1.6 * (s - s0) / maxf(s0, 0.03) + 0.010 * cu_dt(ri) * minf(1.0, s * 3.0)
	return clampf(m, 0.3, 3.0)


func cu_party_cult(p: int) -> String:
	# слот в данных — исходный; при игре не за стартовую партию слоты 0 и player_orig меняются местами
	var orig := p
	if player_orig > 0:
		if p == 0:
			orig = player_orig
		elif p == player_orig:
			orig = 0
	var pm: Dictionary = cu_cfg()["party"]
	return String(pm.get(str(orig), ""))


# ---------------- ежемесячная динамика ----------------


func cult_month() -> void:
	if not cu_on():
		return
	var cd: Dictionary = cu["cd"]
	for k in cd.keys():
		cd[k] = int(cd[k]) - 1
		if int(cd[k]) <= 0:
			cd.erase(k)
	var dyn := soc_dyn()
	var p: Dictionary = cu["pol"]
	var course_f: float = [1.8, 1.0, 0.45][int(p["course"])]
	var school_f: float = [1.4, 1.15, 0.9, 0.6][int(p["school"])]
	var lang_f: float = [1.2, 1.05, 0.9, 0.7][int(p["lang"])]
	var integ: float = float(soc.get("integ", 50.0)) / 100.0
	for i in regions.size():
		var r: Dictionary = regions[i]
		if not r.has("cul"):
			continue
		var v: Dictionary = r["cul"]
		if dyn:
			var tt := cu_region_tit(i)
			# ассимиляция и интеграция: часть меньшинства переходит к государствообразующему народу региона
			if tt != "":
				var moved := 0.0
				for k in v.keys():
					var cid := String(k)
					if cu_is_tit(cid):
						continue
					var s: float = float(v[k])
					if s <= 0.0:
						continue
					var a: float = 0.006 * course_f * school_f * lang_f * (1.0 + 0.6 * (cu_prox(cid, tt) - 0.25)) * (1.0 - 0.8 * minf(s, 0.9))
					if cu_is_prot(cid):
						a *= 0.08 if int(p["course"]) == 0 else 0.0
					elif cu_is_mig(cid):
						a *= 0.5 + 0.6 * integ
					a *= 1.0 - 0.5 * cu_griev(cid, i)
					var f: float = s * a / 12.0
					v[k] = s - f
					moved += f
				v[tt] = float(v.get(tt, 0.0)) + moved
				cu["assim"] = float(cu["assim"]) + moved * float(r["popm"]) * 1000000.0
			# естественное движение: рождаемость народов
			var favg := 0.0
			for k in v:
				favg += float(v[k]) * float(cu_def(String(k))["fert"])
			for k in v.keys():
				var s2: float = float(v[k])
				v[k] = maxf(0.0, s2 + s2 * (float(cu_def(String(k))["fert"]) - favg) * 0.004 / 12.0)
			cu_norm(v)
			r["cuh"] = maxf(0.0, float(r["cuh"]) * 0.97)
		var tg := cu_target_t(i)
		r["cut"] = clampf(float(r["cut"]) + (tg - float(r["cut"])) * mrate(0.45), 0.0, 100.0)
	cu["tension"] = cu_nat_tension()
	var hh: Dictionary = cu["h"]
	(hh["t"] as Array).append(float(cu["tension"]))
	(hh["m"] as Array).append(1.0 - cu_tit_share())
	for hk in ["t", "m"]:
		if (hh[hk] as Array).size() > 144:
			(hh[hk] as Array).pop_front()
	cu_kin_month(dyn)
	cu_dia_month()
	# расходы на поддержку культур (сверх стартового уровня)
	var cost: float = (float(p["fund"]) - float(cu["pol0"]["fund"])) * 0.0004 * maxf(0.2, 1.0 - cu_tit_share()) * 3.0
	cost += float((cu["dia"] as Dictionary).get("lvl", 0)) * 0.0002
	if cost != 0.0:
		debt += gdp * cost / 12.0
	if dyn:
		cu_events()


func cu_norm(v: Dictionary) -> void:
	var tot := 0.0
	for k in v:
		tot += float(v[k])
	if tot > 0.0 and absf(tot - 1.0) > 1e-9:
		for k in v:
			v[k] = float(v[k]) / tot


func cu_tit_share() -> float:
	var nat := cu_national()
	var s := 0.0
	for k in cu_tit_list():
		s += float(nat.get(k, 0.0))
	return s


# миграция приносит свои народы (вызывается из soc_month для каждого региона)
func cult_mig(i: int, imm: float, emi: float, p: float) -> void:
	if not cu_on() or not regions[i].has("cul"):
		return
	var nn: float = p + imm - emi
	if nn <= 0.05:
		return
	var v: Dictionary = regions[i]["cul"]
	var mix := cu_mig_mix()
	for k in v.keys():
		v[k] = float(v[k]) * (p - emi) / nn
	for k in mix:
		v[k] = float(v.get(k, 0.0)) + imm * float(mix[k]) / nn
	cu_norm(v)


func cu_mig_mix() -> Dictionary:
	var c := cu_cfg()
	var cl: Array = c["cl"]
	var mx: Array = soc_mix_eff() if soc.has("mix") else [1.0 / 6.0, 1.0 / 6.0, 1.0 / 6.0, 1.0 / 6.0, 1.0 / 6.0, 1.0 / 6.0]
	var out := {}
	for o in 6:
		var om: Array = c["orig"][o]
		for k in mini(om.size(), cl.size()):
			var w: float = float(mx[o]) * float(om[k])
			if w > 0.0:
				out[String(cl[k])] = float(out.get(String(cl[k]), 0.0)) + w
	return out


# ---------------- родные страны меньшинств и наши соотечественники за рубежом ----------------


# меньшинства с родной страной в игре: [[id народа, страна, доля в стране], ...]
func cu_kin_list() -> Array:
	var out: Array = []
	var nat := cu_national()
	for k in nat:
		var h := cu_home(String(k))
		if h != "" and wsim.has(h) and float(nat[k]) >= 0.004:
			out.append([String(k), h, float(nat[k])])
	out.sort_custom(func(a, b): return float(a[2]) > float(b[2]))
	return out


func cu_kin_month(dyn: bool) -> void:
	var kin: Dictionary = cu["kin"]
	for it in cu_kin_list():
		var cid: String = it[0]
		var h: String = it[1]
		var s: float = it[2]
		if not kin.has(h):
			kin[h] = {"agit": 0.0, "d": 0.0}
		var e: Dictionary = kin[h]
		# отношения с родной страной следуют за политикой к её народу (отклонение от старта)
		var tgt: float = -26.0 * minf(1.0, s * 18.0) * cu_dr() - 0.25 * float((cu["hate"] as Dictionary).get(cid, 0.0))
		tgt += 4.0 * (float(cu["pol"]["fund"]) - float(cu["pol0"]["fund"])) * minf(1.0, s * 18.0)
		var step: float = (tgt - float(e["d"])) * 0.08
		if absf(step) > 0.0005:
			e["d"] = float(e["d"]) + step
			ex_rel_change(h, step)
		if dyn:
			# недружественная родная страна агитирует меньшинство (особенно крупное)
			var rel: float = fed_rel(h)
			var at: float = clampf((40.0 - rel) * 1.6, 0.0, 70.0) * minf(1.0, s * 10.0)
			e["agit"] = float(e["agit"]) + (at - float(e["agit"])) * 0.05
		else:
			e["agit"] = float(e["agit"]) * 0.95


# наш народ за рубежом: [[страна, доля нашего народа там], ...]
func cu_diaspora() -> Array:
	var out: Array = []
	if not CU.has("country"):
		return out
	for cc in CU["country"]:
		if cc == ccode or not wsim.has(cc):
			continue
		var c: Dictionary = CU["country"][cc]
		var cl: Array = c["cl"]
		var s := 0.0
		for t in cu_tit_list():
			if t in c["tit"]:
				continue
			var k: int = cl.find(t)
			if k >= 0:
				s += float(c["base"][k])
		if s >= 0.008:
			out.append([String(cc), s])
	out.sort_custom(func(a, b): return float(a[1]) > float(b[1]))
	return out


func cu_dia_month() -> void:
	var dia: Dictionary = cu["dia"]
	var lv: int = int(dia.get("lvl", 0))
	if lv <= 0:
		return
	for it in cu_diaspora():
		var cc: String = it[0]
		var s: float = it[1]
		# поддержка соотечественников раздражает правительства этих стран (тем сильнее, чем больше община)
		ex_rel_change(cc, -0.05 * float(lv) * minf(1.0, s * 10.0))


# ---------------- события ----------------


func cu_events() -> void:
	if not current_event.is_empty() or election_open:
		return
	var nat_t: float = float(cu["tension"])
	if cu_rng.randf() > 0.028 + 0.0006 * nat_t:
		return
	# регион с самой высокой напряжённостью и его крупнейшее меньшинство
	var worst := -1
	for i in regions.size():
		if regions[i].has("cut") and (worst < 0 or float(regions[i]["cut"]) > float(regions[worst]["cut"])):
			worst = i
	if worst < 0:
		return
	var minor := cu_region_minority(worst)
	var kinl := cu_kin_list()
	var kinds: Array = ["festival", "mixed", "census"]
	if minor != "":
		kinds += ["lang", "monument", "school", "march", "sport"]
		if float(regions[worst]["cut"]) > 45.0 and float(regions[worst]["cul"].get(minor, 0.0)) >= 0.3 and not cu_is_mig(minor):
			kinds += ["autonomy", "autonomy"]
	if not kinl.is_empty():
		kinds += ["kin"]
	var kind: String = String(kinds[cu_rng.randi() % kinds.size()])
	cu_fire(kind, worst, minor, kinl)


func cu_region_minority(i: int) -> String:
	var v: Dictionary = regions[i].get("cul", {})
	var best := ""
	var bv := 0.0
	for k in v:
		if cu_is_tit(String(k)) or String(k) == "oth":
			continue
		if float(v[k]) > bv:
			bv = float(v[k])
			best = String(k)
	return best if bv >= 0.01 else ""


func cu_fire(kind: String, ri: int, minor: String, kinl: Array) -> void:
	var nm: String = cu_name(minor) if minor != "" else ""
	var ev := {}
	match kind:
		"lang":
			ev = {"t": "%s в регионе «{r}» вышли на акции: требуют права пользоваться родным языком в учреждениях и судах." % nm, "o": [
				{"l": "Разрешить региональный язык в местных делах (капитал −6)", "fx": {"capital": -6.0, "support": {"Силовики": -1.5, "Пенсионеры": -1.0, "Молодёжь": 1.0}, "cult": {"pol": {"lang": 1}, "cuh": -20.0}}},
				{"l": "Разогнать акции полицией", "fx": {"support": {"Силовики": 2.0, "Молодёжь": -1.5}, "cult": {"hate": {minor: 15.0}, "cuh": 15.0, "rvhate": 10.0}}},
				{"l": "Начать диалог с общиной (капитал −3)", "fx": {"capital": -3.0, "cult": {"cuh": -10.0}}}]}
		"monument":
			ev = {"t": "В регионе «{r}» спор о двуязычных табличках и памятниках: %s просят названия улиц на своём языке, часть большинства против." % nm.to_lower(), "o": [
				{"l": "Ввести двуязычные таблички", "fx": {"support": {"Силовики": -1.0, "Село": -1.0}, "cult": {"cuh": -18.0, "hate": {minor: -8.0}}}},
				{"l": "Отказать: язык один", "fx": {"support": {"Силовики": 1.5, "Пенсионеры": 0.5}, "cult": {"cuh": 14.0, "hate": {minor: 8.0}}}},
				{"l": "Передать вопрос местным советам (капитал −2)", "fx": {"capital": -2.0, "cult": {"cuh": -6.0}}}]}
		"school":
			ev = {"t": "Родители в регионе «{r}» требуют классы с обучением на родном языке: %s собрали десятки тысяч подписей." % nm.to_lower(), "o": [
				{"l": "Открыть классы на родном языке (долг +0.02% ВВП)", "fx": {"debt": 0.02, "support": {"Бюджетники": 0.5, "Силовики": -0.5}, "cult": {"cuh": -16.0}}},
				{"l": "Отказать: школа должна учить на государственном языке", "fx": {"support": {"Силовики": 1.0, "Пенсионеры": 0.5}, "cult": {"cuh": 12.0, "hate": {minor: 6.0}}}},
				{"l": "Ввести родной язык как предмет по всей стране (капитал −5)", "fx": {"capital": -5.0, "cult": {"pol": {"school": 1}, "cuh": -10.0}}}]}
		"march":
			ev = {"t": "Националисты объявили марш против «засилья меньшинств» через кварталы, где живут %s (регион «{r}»)." % nm.to_lower(), "o": [
				{"l": "Запретить марш", "fx": {"support": {"Силовики": -1.5, "Молодёжь": 1.0}, "cult": {"cuh": -10.0}}},
				{"l": "Разрешить: свобода собраний", "fx": {"support": {"Силовики": 1.5}, "cult": {"cuh": 14.0, "hate": {minor: 10.0}, "rvhate": 6.0}}},
				{"l": "Разрешить, но под охраной полиции (капитал −3)", "fx": {"capital": -3.0, "cult": {"cuh": 3.0}}}]}
		"sport":
			ev = {"t": "Футбольный матч в регионе «{r}» закончился дракой болельщиков из-за национальных лозунгов; %s жалуются на оскорбления." % nm.to_lower(), "o": [
				{"l": "Наказать клубы и ввести штрафы за ненависть", "fx": {"support": {"Молодёжь": -0.5}, "cult": {"cuh": -8.0}}},
				{"l": "Считать хулиганством, без политики", "fx": {"cult": {"cuh": 6.0}}}]}
		"festival":
			var fc: String = minor if minor != "" else String(cu_sorted(cu_national())[mini(1, cu_sorted(cu_national()).size() - 1)][0])
			ev = {"t": "Фестиваль культуры народа «%s» собрал тысячи гостей; организаторы просят государственную поддержку." % cu_name(fc), "o": [
				{"l": "Поддержать фестиваль (долг +0.01% ВВП)", "fx": {"debt": 0.01, "support": {"Молодёжь": 1.0}, "cult": {"cuh": -8.0, "hate": {fc: -5.0}}}},
				{"l": "Не вмешиваться", "fx": {}}]}
		"mixed":
			ev = {"t": "Социологи: смешанных браков и двуязычных семей становится больше, молодёжь меньше делит себя по народам.", "o": [
				{"l": "Отметить в обращении к стране", "fx": {"support": {"Молодёжь": 1.0}, "cult": {"cuh_all": -5.0}}}]}
		"census":
			ev = {"t": "Готовится перепись населения. Общины меньшинств просят право указать два народа и родной язык.", "o": [
				{"l": "Разрешить двойную идентичность", "fx": {"support": {"Молодёжь": 0.5, "Силовики": -0.5}, "cult": {"cuh_all": -4.0}}},
				{"l": "Оставить один народ в анкете", "fx": {"support": {"Силовики": 0.5}, "cult": {"cuh_all": 2.0}}}]}
		"autonomy":
			ev = {"t": "Партии меньшинства в регионе «{r}» требуют культурной автономии: %s хотят своих советов, образования и бюджета на культуру." % nm.to_lower(), "o": [
				{"l": "Дать региону культурную автономию (капитал −8)", "fx": {"capital": -8.0, "reg": {"autonomy": 10.0, "loyalty": 4.0}, "support": {"Силовики": -2.0, "Пенсионеры": -1.0}, "cult": {"cuh": -30.0, "hate": {minor: -10.0}}}},
				{"l": "Отказать", "fx": {"reg": {"unrest": 5.0}, "support": {"Силовики": 1.5}, "cult": {"cuh": 18.0, "hate": {minor: 12.0}, "rvhate": 12.0}}},
				{"l": "Создать комиссию по правам меньшинств (капитал −4)", "fx": {"capital": -4.0, "cult": {"cuh": -10.0}}}]}
		"kin":
			var it: Array = kinl[cu_rng.randi() % kinl.size()]
			var kc: String = it[0]
			var hc: String = it[1]
			var hn: String = String(WORLD[hc]["name"]) if WORLD.has(hc) else hc
			ev = {"t": "%s требует расширить права своих соотечественников — живущих у нас %s: язык, школы, представительство." % [hn, cu_name(kc).to_lower()], "o": [
				{"l": "Пойти навстречу: школы и язык (капитал −5)", "fx": {"capital": -5.0, "support": {"Силовики": -1.5, "Пенсионеры": -0.5}, "cult": {"pol": {"school": 1}, "rel": {hc: 6.0}, "hate": {kc: -8.0}}}},
				{"l": "Отклонить: это наше внутреннее дело", "fx": {"support": {"Силовики": 1.5}, "cult": {"rel": {hc: -6.0}, "hate": {kc: 6.0}}}},
				{"l": "Создать двустороннюю комиссию (капитал −3)", "fx": {"capital": -3.0, "cult": {"rel": {hc: 2.0}}}}]}
	if ev.is_empty():
		return
	ev["kind"] = "cult"
	(cu["evlog"] as Array).append("%s: %s" % [date_text(), String(ev["t"]).replace("{r}", String(REGIONS[ri]["name"]))])
	if (cu["evlog"] as Array).size() > 12:
		(cu["evlog"] as Array).pop_front()
	soc_push_event(ev, ri)


func cult_fx(d: Dictionary) -> void:
	if not cu_on():
		return
	if d.has("pol"):
		for k in d["pol"]:
			var mx: int = int(CU_POL_MAX.get(k, 3))
			cu["pol"][k] = clampi(int(cu["pol"][k]) + int(d["pol"][k]), 0, mx)
	if d.has("hate"):
		for k in d["hate"]:
			(cu["hate"] as Dictionary)[k] = clampf(float((cu["hate"] as Dictionary).get(k, 0.0)) + float(d["hate"][k]), 0.0, 100.0)
	if d.has("cuh") and event_region >= 0 and event_region < regions.size():
		regions[event_region]["cuh"] = clampf(float(regions[event_region].get("cuh", 0.0)) + float(d["cuh"]), -40.0, 100.0)
	if d.has("cuh_all"):
		for r in regions:
			r["cuh"] = clampf(float(r.get("cuh", 0.0)) + float(d["cuh_all"]), -40.0, 100.0)
	if d.has("rel"):
		for cc in d["rel"]:
			ex_rel_change(String(cc), float(d["rel"][cc]))
	if d.has("rvhate") and event_region >= 0:
		rv_add_hate(event_region, float(d["rvhate"]))


# ---------------- действия игрока ----------------


func cu_cd_get(k: String) -> int:
	return int((cu["cd"] as Dictionary).get(k, 0))


func cu_spend(cost: float) -> bool:
	if game_over:
		return false
	if capital < cost:
		log_line("[color=%s]Не хватает политического капитала (нужно %.0f).[/color]" % [COL_BAD, cost])
		return false
	capital -= cost
	return true


func cu_pol_names(k: String) -> Array:
	match k:
		"lang": return CU_LANG
		"school": return CU_SCHOOL
		"auto": return CU_AUTO
		"course": return CU_COURSE
	return CU_FUND


# изменить культурную политику k на dir (+1 — мягче к меньшинствам, −1 — жёстче)
func cu_set_pol(k: String, dir: int) -> bool:
	if pl_deny():
		return false
	if not cu_on() or not CU_POL_MAX.has(k):
		return false
	var v: int = int(cu["pol"][k]) + dir
	if v < 0 or v > int(CU_POL_MAX[k]) or cu_cd_get(k) > 0:
		return false
	var cost: float = float(CU_POL_COST[k])
	if not cu_spend(cost):
		return false
	cu["pol"][k] = v
	(cu["cd"] as Dictionary)[k] = 9
	# реакция большинства: чем больше меньшинств, тем острее вопрос
	var mk: float = 0.5 + 3.0 * clampf(1.0 - cu_tit_share(), 0.0, 0.5)
	var s := float(dir) * mk
	if k == "fund":
		add_support("Бюджетники", 0.5 * s)
		add_support("Пенсионеры", -0.5 * s)
	else:
		add_support("Молодёжь", 1.0 * s)
		add_support("Бизнес", 0.5 * s)
		add_support("Силовики", -1.5 * s)
		add_support("Село", -1.0 * s)
		add_support("Пенсионеры", -0.8 * s)
	log_line("[b]%s: культурная политика — «%s».[/b]" % [date_text(), String(cu_pol_names(k)[v])])
	refresh()
	return true


func cu_dialog() -> bool:
	if pl_deny():
		return false
	if not cu_on() or cu_cd_get("dialog") > 0:
		return false
	if not cu_spend(5.0):
		return false
	(cu["cd"] as Dictionary)["dialog"] = 12
	for r in regions:
		r["cuh"] = clampf(float(r.get("cuh", 0.0)) - 12.0, -40.0, 100.0)
	for k in (cu["hate"] as Dictionary).keys():
		cu["hate"][k] = maxf(0.0, float(cu["hate"][k]) - 6.0)
	log_line("%s: круглый стол с общинами меньшинств — напряжённость снижена." % date_text())
	refresh()
	return true


# культурная автономия выбранному региону
func cu_region_autonomy(i: int) -> bool:
	if pl_deny():
		return false
	if not cu_on() or i < 0 or i >= regions.size() or cu_cd_get("rauto_%d" % i) > 0:
		return false
	if cu_minority_share(i) < 0.08:
		log_line("[color=%s]В регионе «%s» нет крупного меньшинства — культурная автономия не нужна.[/color]" % [COL_WARN, REGIONS[i]["name"]])
		return false
	if not cu_spend(7.0):
		return false
	(cu["cd"] as Dictionary)["rauto_%d" % i] = 24
	regions[i]["cuh"] = clampf(float(regions[i].get("cuh", 0.0)) - 25.0, -40.0, 100.0)
	apply_reg_delta(i, {"autonomy": 8.0, "loyalty": 3.0})
	add_support("Силовики", -1.0)
	log_line("[b]%s: регион «%s» получил культурную автономию.[/b]" % [date_text(), REGIONS[i]["name"]])
	refresh()
	return true


# поддержка соотечественников за рубежом: 0 — нет, 1 — культура и образование, 2 — активная (паспорта, фонды)
func cu_set_dia(dir: int) -> bool:
	if pl_deny():
		return false
	if not cu_on() or cu_cd_get("dia") > 0:
		return false
	var dia: Dictionary = cu["dia"]
	var v: int = int(dia.get("lvl", 0)) + dir
	if v < 0 or v > 2 or cu_diaspora().is_empty():
		return false
	if not cu_spend(6.0):
		return false
	dia["lvl"] = v
	(cu["cd"] as Dictionary)["dia"] = 9
	add_support("Пенсионеры", 0.8 * float(dir))
	add_support("Силовики", 0.8 * float(dir))
	add_support("Молодёжь", -0.4 * float(dir))
	if dir > 0:
		for it in cu_diaspora():
			ex_rel_change(String(it[0]), -2.0 * float(v) * minf(1.0, float(it[1]) * 10.0))
	log_line("[b]%s: поддержка соотечественников за рубежом — %s.[/b]" % [date_text(), ["прекращена", "культура и образование", "активная: фонды и паспорта"][v]])
	refresh()
	return true


# культурная дипломатия: близкие по культуре страны отзываются сильнее
func cu_diplomacy(cc: String) -> bool:
	if pl_deny():
		return false
	if not cu_on() or cc == "" or cc == ccode or cu_cd_get("cdip_" + cc) > 0:
		return false
	if not cu_spend(4.0):
		return false
	(cu["cd"] as Dictionary)["cdip_" + cc] = 12
	var pr := cu_country_prox(cc)
	var d: float = 2.0 + 5.0 * pr
	ex_rel_change(cc, d)
	debt += gdp * 0.0002
	log_line("%s: дни культуры в стране «%s» — отношения %s (культурная близость %.0f%%)." % [date_text(), String(WORLD[cc]["name"]) if WORLD.has(cc) else cc, sg(d, 1), pr * 100.0])
	refresh()
	return true


func cu_effect_text() -> String:
	if not cu_on():
		return ""
	var s := 0.0
	for i in regions.size():
		s += cu_pw(i) * cu_dt(i)
	return "Напряжённость %.0f (на старте %.0f): лояльность регионов %s, недовольство %s в среднем; рост %s п.п." % [
		float(cu["tension"]), float(cu["tension0"]), sg(-CU_LOY_K * s, 1), sg(CU_UNR_K * s, 1), sg(cult_g(), 2)]
