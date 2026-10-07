# Бюджетная политика: ползунки, блокировки, уровни, эффекты, моды законов.
extends "res://scripts/logic/util.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func add_commitment(p: int) -> void:
	pass


func apply_econ(e: Dictionary) -> void:
	pass


func apply_psat(p: int, v: float) -> void:
	pass


func dip_all(delta: float, eu_only: bool) -> void:
	pass


func dip_apply_mods() -> void:
	pass


func dip_fx_apply(dd: Dictionary) -> void:
	pass


func dip_fx_text(dd: Dictionary) -> String:
	return ""


func ec_budget_lines() -> Dictionary:
	return {}


func fed_tax_leak() -> float:
	return 0.0


func fulfill_coalition_demands() -> void:
	pass


func good_name(id: String) -> String:
	return ""


func goods_support_term(group: String) -> float:
	return 0.0


func junior_power() -> float:
	return 0.0


func ministry_fx(m: int, p: int, skill: float = 65.0) -> Dictionary:
	return {}


func mk_def(id: String) -> Dictionary:
	return {}


func new_minister(m: int, p: int) -> Dictionary:
	return {}


func radical_dyn() -> void:
	pass


func radical_roll(base: float) -> void:
	pass


func reg_avg(key: String, wkey: String = "pop") -> float:
	return 0.0


func reg_zones_end(i: int) -> void:
	pass


func rel(a: int, b: int) -> float:
	return 0.0


func sec_idx(i: int) -> float:
	return 0.0


func slider_value_for(key: String) -> float:
	return 0.0


func soc_fx(d: Dictionary) -> void:
	pass


func soc_tax() -> float:
	return 0.0


func sync_ministers() -> void:
	pass


func transfer_avg() -> float:
	return 0.0


func update_slider_label(key: String) -> void:
	pass


func variant_of(tid: String, idx: int) -> Dictionary:
	return {}


func world_help(c: String) -> void:
	pass


# --- конец заглушек ---


func approval() -> float:
	var total := 0.0
	for g in GROUPS:
		total += float(support[g]) * float(GROUP_WEIGHT[g])
	return total


func add_support(group: String, v: float) -> void:
	support[group] = clampf(float(support[group]) + v, 0.0, 100.0)


func add_all_support(v: float) -> void:
	for g in GROUPS:
		add_support(g, v)


func set_policy(key: String, v: float) -> void:
	var d: Dictionary = policy_by_key[key]
	if is_abs(key):
		var r := abs_range(key)
		var a := clampf(v * gdp / 100.0, r.x, r.y)
		pol_abs[key] = a
		pol[key] = a / gdp * 100.0
	else:
		pol[key] = clampf(v, float(d["min"]), float(d["max"]))
	if sliders.has(key):
		(sliders[key]["slider"] as HSlider).set_value_no_signal(slider_value_for(key))
		update_slider_label(key)


func apply_reg_delta(i: int, d: Dictionary, invest: bool = false) -> void:
	var r: Dictionary = regions[i]
	for k in d:
		var key: String = REG_KEYS[k]
		var dv: float = float(d[k])
		if invest and key == "dev" and dv > 0.0:
			dv *= dev_gain_mult(i)
		r[key] = clampf(float(r[key]) + dv, 0.0, 100.0)
		if dv > 0.0 and (r["bonus"] as Dictionary).has(key):
			r["bonus"][key] = minf(40.0, float(r["bonus"][key]) + dv)


func describe_reg(d: Dictionary) -> String:
	var parts: PackedStringArray = []
	for k in d:
		if k == "dev":
			parts.append("ВВП региона %s%%" % sg(float(d[k]) * 0.8, 1))
		else:
			parts.append("%s %s" % [REG_TITLES[k], sg(d[k], 0)])
	return ", ".join(parts)


# ============================================================
#  ЭКОНОМИКА И БЮДЖЕТ (годовые величины; в месяц тратится 1/12)
# ============================================================


func region_support(i: int) -> float:
	var s := 0.0
	var mix: Dictionary = reg_mix[i]
	for g in GROUPS:
		s += float(mix[g]) * float(support[g])
	return s


# «Субсидии бизнесу и аграриям» делятся на два ползунка с той же суммарной базой
func split_subsidies() -> void:
	for i in POLICY.size():
		var d: Dictionary = POLICY[i]
		if String(d["key"]) != "subs":
			continue
		var tot: float = float(d["def"])
		var sd: float = snappedf(tot * 0.6, 0.1)
		var ad: float = snappedf(tot - sd, 0.1)
		var mx: float = float(d["max"])
		d["title"] = "Субсидии бизнесу"
		d["def"] = sd
		d["max"] = maxf(1.0, snappedf(mx * 0.7, 0.5))
		var a: Dictionary = d.duplicate(true)
		a["key"] = "agri"
		a["title"] = "Субсидии аграриям"
		a["def"] = ad
		a["max"] = maxf(1.0, snappedf(mx * 0.5, 0.5))
		POLICY.insert(i + 1, a)
		return


func expected(key: String) -> float:
	return float(pol_def[key]) + float(EXPECT_DRIFT.get(key, 0.0)) * years_passed()


func factor(fname: String) -> float:
	if pol.has(fname):
		if String(policy_by_key[fname]["kind"]) == "spend":
			return pp0(fname) - expected_pp(fname)
		return float(pol[fname]) - float(pol_def[fname])
	if lvl.has(fname):
		return float(lvl[fname]) - 50.0
	match fname:
		"unemp":
			return unemployment - U_NEU
		"infl":
			return inflation - I_NEU
		"growth":
			return growth - G_NEU
	return 0.0


func fatigue() -> float:
	return minf(4.0, 0.1 * years_passed()) + 0.3 * float(turn - last_parl) / 12.0


func target_support(g: String) -> float:
	var tg := target_gov_support(g)
	if opp_mode:
		# в оппозиции народ оценивает власть, а ваша партия получает обратную часть недовольства
		return clampf(float(GROUP_BASE[g]) - 0.6 * (tg - float(GROUP_BASE[g])), 0.0, 100.0)
	return tg


func target_gov_support(g: String) -> float:
	var t: float = float(GROUP_BASE[g]) + float(bias[g]) - fatigue() + lvl_sum("mood") + float(mods["mood_shift"]) + float(mods.get("gb_" + g, 0.0))
	var fx: Dictionary = GROUP_FX[g]
	for k in fx:
		t += float(fx[k]) * factor(k)
	t += goods_support_term(g)
	t += AGRI_FX.get(g, 0.0) * factor("agri")
	return clampf(t, 0.0, 100.0)


# ============================================================
#  ХОД ИГРЫ: ОДИН МЕСЯЦ
# ============================================================


func budget_changes(b: Dictionary) -> String:
	var cur := {}
	for k in b["rev"]:
		cur[k] = float(b["rev"][k]) / gdp * 100.0
	for k in b["exp"]:
		cur[k] = float(b["exp"][k]) / gdp * 100.0
	var out := ""
	if not prev_items.is_empty():
		var diffs: Array = []
		for k in cur:
			var d: float = float(cur[k]) - float(prev_items.get(k, 0.0))
			if absf(d) >= 0.12:
				diffs.append([k, d])
		diffs.sort_custom(func(a, c): return absf(a[1]) > absf(c[1]))
		var parts: PackedStringArray = []
		for i in mini(6, diffs.size()):
			parts.append("%s %s п.п." % [diffs[i][0], sg(diffs[i][1], 2)])
		out = ", ".join(parts)
	prev_items = cur
	return out


func describe_fx(fx: Dictionary, rid: int = -1) -> String:
	var parts: PackedStringArray = []
	if fx.has("debt"):
		parts.append("долг %s%% ВВП" % sg(fx["debt"]))
	if fx.has("shock"):
		parts.append("рост ВВП %s п.п. на ближайшие месяцы" % sg(fx["shock"]))
	if fx.has("infl"):
		parts.append("инфляция %s п.п." % sg(fx["infl"]))
	if fx.has("unemp"):
		parts.append("безработица %s п.п." % sg(fx["unemp"]))
	if fx.has("other_rev"):
		parts.append("прочие доходы %s%% ВВП" % sg(fx["other_rev"]))
	if fx.has("econ"):
		parts.append(describe_econ(fx["econ"]))
	if fx.has("slider"):
		for k in fx["slider"]:
			parts.append("«%s» %s п.п. ВВП" % [policy_title(k), sg(fx["slider"][k])])
		parts.append("обязательство на %d мес.: откатить ползунок нельзя" % int(fx.get("lock_months", 12)))
	if fx.has("state"):
		for k in fx["state"]:
			parts.append("%s %s" % [STATE_NAMES[k], sg(fx["state"][k], 0)])
	if fx.has("all"):
		parts.append("поддержка всех групп %s" % sg(fx["all"], 0))
	if fx.has("support"):
		for g in fx["support"]:
			parts.append("%s %s" % [g, sg(fx["support"][g], 0)])
	if fx.has("capital"):
		parts.append("политкапитал %s" % sg(fx["capital"], 0))
	if fx.has("reg") and rid >= 0:
		parts.append("регион «%s»: %s" % [REGIONS[rid]["name"], describe_reg(fx["reg"])])
	if fx.has("reg_transfer") and rid >= 0:
		parts.append("трансферты региона «%s» %s п.п." % [REGIONS[rid]["name"], sg(fx["reg_transfer"])])
	if fx.has("regall"):
		parts.append("все регионы: %s" % describe_reg(fx["regall"]))
	if fx.has("sector"):
		for sk in fx["sector"]:
			parts.append("регионы с отраслью «%s»: %s" % [SECTOR_NAMES[sk], describe_reg(fx["sector"][sk])])
	if rid >= 0:
		if fx.has("rsec"):
			var sp2: PackedStringArray = []
			for sk in fx["rsec"]:
				sp2.append("%s %s%%" % [SECTOR_NAMES[sk], sg(float(fx["rsec"][sk]) * 100.0, 0)])
			parts.append("регион «%s»: выпуск отраслей — %s" % [REGIONS[rid]["name"], ", ".join(sp2)])
		if fx.has("rdebt"):
			parts.append("долг региона «%s» %s п.п. ВРП" % [REGIONS[rid]["name"], sg(fx["rdebt"], 0)])
		if fx.has("rmig"):
			parts.append("миграция в регион «%s» %s на 1000 жителей в год" % [REGIONS[rid]["name"], sg(fx["rmig"], 1)])
		if fx.get("rzone_end", false):
			parts.append("зоны и кластеры региона сворачиваются")
	if fx.has("coal_sat"):
		parts.append("довольство партнёров по коалиции %s" % sg(fx["coal_sat"], 0))
	if fx.has("dip"):
		parts.append(dip_fx_text(fx["dip"]))
	if fx.get("coal_demands", false):
		parts.append("бюджет подстроится под требования партнёров")
	if fx.has("psat") and event_party > 0:
		parts.append("довольство «%s» %s" % [PARTY_NAMES[event_party], sg(fx["psat"], 0)])
	if fx.has("psat_others"):
		parts.append("довольство остальных партнёров %s" % sg(fx["psat_others"], 0))
	if fx.has("psat_all"):
		parts.append("довольство всех партнёров %s" % sg(fx["psat_all"], 0))
	if fx.get("give_min", false) and event_min >= 0 and event_party > 0:
		parts.append("министерство «%s» переходит партии «%s»" % [MINISTRIES[event_min]["name"], PARTY_NAMES[event_party]])
	if fx.get("dismiss_min", false) and event_min >= 0:
		parts.append("министр «%s» сменён" % MINISTRIES[event_min]["name"])
	if fx.get("promise", false) and event_party > 0:
		parts.append("обещание закона-условия в течение 18 мес.")
	return ", ".join(parts)


func apply_fx(fx: Dictionary, rid: int = -1) -> String:
	if fx.has("wc_help"):
		world_help(String(fx["wc_help"]))
	if fx.has("soc"):
		soc_fx(fx["soc"])
	if fx.has("dip"):
		dip_fx_apply(fx["dip"])
	if fx.has("debt"):
		debt += gdp * float(fx["debt"]) / 100.0
	if fx.has("shock"):
		shock += float(fx["shock"]) * 1.3
	if fx.has("infl"):
		inflation = clampf(inflation + float(fx["infl"]), 0.0, 40.0)
	if fx.has("unemp"):
		unemployment = clampf(unemployment + float(fx["unemp"]), 2.0, 30.0)
	if fx.has("other_rev"):
		other_rev += float(fx["other_rev"])
	if fx.has("econ"):
		apply_econ(fx["econ"])
	if fx.has("slider"):
		var lock_m: int = int(fx.get("lock_months", 12))
		for k in fx["slider"]:
			var old: float = pol[k]
			set_policy(k, old + float(fx["slider"][k]))
			prev_pol[k] = float(prev_pol[k]) + (float(pol[k]) - old)
			add_lock(k, old, float(pol[k]), lock_m)
	if fx.has("state"):
		for k in fx["state"]:
			lvl[k] = clampf(float(lvl[k]) + float(fx["state"][k]), 0.0, 100.0)
	if fx.has("all"):
		add_all_support(float(fx["all"]))
	if fx.has("support"):
		for g in fx["support"]:
			add_support(g, float(fx["support"][g]))
	if fx.has("capital"):
		capital = clampf(capital + float(fx["capital"]), 0.0, 100.0)
	if fx.has("pcamp"):
		pres_camp += float(fx["pcamp"])
	if fx.has("reg") and rid >= 0:
		apply_reg_delta(rid, fx["reg"])
	if fx.has("reg_transfer") and rid >= 0:
		regions[rid]["transfer"] = clampf(float(regions[rid]["transfer"]) + float(fx["reg_transfer"]), 0.0, 5.0)
	if fx.has("regall"):
		for i in regions.size():
			apply_reg_delta(i, fx["regall"])
	if fx.has("sector"):
		for sk in fx["sector"]:
			for i in regions.size():
				var share: float = float(REGIONS[i]["sec"][sk])
				var dd := {}
				for k in fx["sector"][sk]:
					dd[k] = float(fx["sector"][sk][k]) * share * 2.0
				apply_reg_delta(i, dd)
	if rid >= 0:
		if fx.has("rsec"):
			for sk in fx["rsec"]:
				var sm: Dictionary = regions[rid]["smul"]
				sm[sk] = clampf(float(sm[sk]) + float(fx["rsec"][sk]), 0.5, 1.9)
		if fx.has("rdebt"):
			regions[rid]["rdebt"] = clampf(float(regions[rid]["rdebt"]) + float(fx["rdebt"]), 0.0, 160.0)
		if fx.has("rmig"):
			regions[rid]["mbonus"] = float(regions[rid]["mbonus"]) + float(fx["rmig"])
		if fx.get("rzone_end", false):
			reg_zones_end(rid)
	if fx.has("coal_sat"):
		for p in range(1, PARTY_NAMES.size()):
			if in_coalition[p]:
				conc[p] = float(conc.get(p, 0.0)) + float(fx["coal_sat"])
				satis[p] = clampf(float(satis.get(p, 50.0)) + float(fx["coal_sat"]) * 0.7, 0.0, 100.0)
	if fx.get("coal_demands", false):
		fulfill_coalition_demands()
	if fx.has("dip_all"):
		dip_all(float(fx["dip_all"]), bool(fx.get("dip_eu_only", false)))
	if fx.has("risk_mul"):
		regime_risk = maxf(0.0, regime_risk * float(fx["risk_mul"]))
	if fx.has("rev_roll"):
		radical_roll(float(fx["rev_roll"]))
	var desc_text := describe_fx(fx, rid)
	if fx.has("psat") and event_party > 0:
		apply_psat(event_party, float(fx["psat"]))
	if fx.has("psat_others") or fx.has("psat_all"):
		for p in range(1, 9):
			if in_coalition[p]:
				if fx.has("psat_all"):
					apply_psat(p, float(fx["psat_all"]))
				elif p != event_party:
					apply_psat(p, float(fx["psat_others"]))
	if fx.get("give_min", false) and event_min >= 0 and event_party > 0 and in_coalition[event_party]:
		ministries[event_min] = event_party
	if fx.get("dismiss_min", false) and event_min >= 0:
		ministers[event_min] = new_minister(event_min, ministries[event_min])
	if fx.get("promise", false) and event_party > 0:
		add_commitment(event_party)
	recompute_mods()
	return desc_text


# ============================================================
#  БЮДЖЕТ (с трансфертами регионам и проектами)
# ============================================================


func compute_budget() -> Dictionary:
	var rate: float = debt_rate()
	var eff: float = 1.0 + lvl_sum("tax_eff") + float(mods["eff_bonus"]) - (reg_avg("auto") - auto0) * 0.0005 - fed_tax_leak() + soc_tax()
	var rev := {
		"Подоходный налог": gdp * pol["income"] / 100.0 * mods["income_mult"] * eff,
		"Взносы в соцстрахование": gdp * pol["social"] / 100.0 * eff,
		"Налог на прибыль": gdp * pol["corp"] / 100.0 * mods["corp_mult"] * eff,
		"НДС и акцизы": gdp * pol["vat"] / 100.0 * mods["vat_mult"] * eff,
		"Прочие доходы": gdp * other_rev / 100.0,
	}
	if float(pol["emit"]) > 0.0:
		rev["Эмиссия (печать денег)"] = gdp * float(pol["emit"]) / 100.0
	var sp := {
		"Пенсии": gdp * pol["pensions"] * mods["pension_mult"] / 100.0,
		"Пособия и соцпомощь": gdp * pol["benefits"] / 100.0,
		"Образование": gdp * pol["edu"] / 100.0,
		"Здравоохранение": gdp * pol["health"] / 100.0,
		tm("army"): gdp * pol["army"] / 100.0,
		"Полиция и суды": gdp * pol["police"] / 100.0,
		"Инфраструктура": gdp * pol["infra"] / 100.0,
		"Экология": gdp * pol["eco"] / 100.0,
		"Субсидии бизнесу": gdp * pol["subs"] / 100.0,
		"Субсидии аграриям": gdp * pol["agri"] / 100.0,
		"Госаппарат": gdp * pol["admin"] * mods["admin_mult"] / 100.0,
	}
	var tr := 0.0
	var pj := 0.0
	for i in regions.size():
		tr += gdp * gdp_w[i] * float(regions[i]["transfer"]) / 100.0
		var pr: Dictionary = regions[i]["proj"]
		if not pr.is_empty():
			pj += gdp * float(pr["cost"]) / 100.0 / float(pr["months"]) * 12.0
	sp["Трансферты регионам"] = tr
	var zu := 0.0
	for i in regions.size():
		zu += gdp * gdp_w[i] * float(regions[i]["upk"]) / 100.0
	if zu > 0.0:
		sp["Зоны и кластеры"] = zu
	if pj > 0.0:
		sp["Проекты в регионах"] = pj
	if float(mods["extra_spend"]) > 0.0:
		sp["Программы по законам"] = gdp * mods["extra_spend"] / 100.0
	var interest: float = maxf(debt, 0.0) * rate
	sp["Проценты по долгу"] = interest
	var xl := ec_budget_lines()
	for k in xl["rev"]:
		rev[k] = xl["rev"][k]
	for k in xl["exp"]:
		sp[k] = xl["exp"][k]
	var revenue := 0.0
	for k in rev:
		revenue += rev[k]
	var spending := 0.0
	for k in sp:
		spending += sp[k]
	return {"rev": rev, "exp": sp, "revenue": revenue, "spending": spending,
		"interest": interest, "balance": revenue - spending}


func update_levels() -> void:
	var t := {}
	t["edu_lvl"] = sat(pp0("edu") * mods["edu_eff"], float(pol_def["edu"]))
	t["health_lvl"] = sat(pp0("health") * mods["health_eff"], float(pol_def["health"])) + (float(lvl["env_lvl"]) - 50.0) * 0.1
	t["security_lvl"] = 0.5 * sat(pp0("army"), float(pol_def["army"])) + 0.5 * sat(pp0("police"), float(pol_def["police"])) + float(mods["sec_bonus"])
	t["infra_lvl"] = sat(pp0("infra") * float(mods["infra_eff"]), float(pol_def["infra"]))
	t["env_lvl"] = sat(pp0("eco") * mods["env_eff"], float(pol_def["eco"])) - (growth - G_NEU) * 3.0 - (pp0("subs") - float(pol_def["subs"])) * 3.0 - (pp0("agri") - float(pol_def["agri"])) * 1.5
	t["equality"] = (50.0 + (float(pol["income"]) - float(pol_def["income"])) * 1.5 + (pp0("benefits") - float(pol_def["benefits"])) * 3.0
		+ (pp0("pensions") - float(pol_def["pensions"])) * 0.8 + (float(pol["corp"]) - float(pol_def["corp"])) * 0.5
		+ (float(pol["social"]) - float(pol_def["social"])) * 0.3
		- (pp0("subs") - float(pol_def["subs"])) * 1.5 - (pp0("agri") - float(pol_def["agri"])) * 0.5 + float(mods["equal_shift"]))
	var gov_corr := 0.0
	for r in regions:
		var k: int = int((r["gov"] as Dictionary)["kind"])
		if k == 1:
			gov_corr += 0.4
		elif k == 2:
			gov_corr -= 0.4
	t["corruption"] = (50.0 - (pp0("admin") - float(pol_def["admin"])) * 3.0 - (float(lvl["edu_lvl"]) - 50.0) * 0.15
		- (float(lvl["security_lvl"]) - 50.0) * 0.1 + float(mods["corr_shift"]) + gov_corr)
	for k in t:
		var tv: float = float(t[k])
		lvl[k] = clampf(float(lvl[k]) + (tv - float(lvl[k])) * mrate(float(LEVEL_RATE[k])), 0.0, 100.0)


# ============================================================
#  РЕГИОНЫ
# ============================================================


func pp0(key: String) -> float:
	# сумма на душу населения в «п.п. ВВП начала игры», с поправкой на рост стандартов: от неё зависят состояние страны и довольство групп
	return amt(key) / (GDP0 / 100.0) / pop_ratio() / std_index()


func expected_pp(key: String) -> float:
	return float(pol_def[key]) + float(EXPECT_DRIFT.get(key, 0.0)) * years_passed()


func is_abs(key: String) -> bool:
	return bool(pol_abs_mode.get(key, false))


func abs_range(key: String) -> Vector2:
	var d: Dictionary = policy_by_key[key]
	return Vector2(float(d["min"]) * GDP0 / 100.0 * 0.6, float(d["max"]) * GDP0 / 100.0 * 1.6)


func sync_abs_policies() -> void:
	# для ползунков в режиме «млрд» сумма фиксирована, а доля ВВП пересчитывается
	for key in pol_abs_mode:
		if is_abs(key):
			pol[key] = float(pol_abs[key]) / gdp * 100.0


func lock_active(key: String) -> bool:
	return locks.has(key) and turn < int((locks[key] as Dictionary)["until"])


func add_lock(key: String, old_share: float, new_share: float, months: int) -> void:
	if absf(new_share - old_share) < 0.001:
		return
	var dir: int = 1 if new_share > old_share else -1
	var until: int = turn + months
	if lock_active(key):
		var cur: Dictionary = locks[key]
		if int(cur["dir"]) == dir:
			new_share = maxf(new_share, float(cur["share"])) if dir == 1 else minf(new_share, float(cur["share"]))
			until = maxi(until, int(cur["until"]))
	locks[key] = {"dir": dir, "share": new_share, "amount": new_share * gdp / 100.0, "until": until}


func lock_allowed(key: String, v: float) -> float:
	# v — значение в единицах ползунка (% ВВП или млрд)
	if opp_mode:
		# в оппозиции бюджет ведёт правительство
		return float(pol_abs.get(key, float(pol[key]) * gdp / 100.0)) if is_abs(key) else float(pol[key])
	var jp := junior_power()
	if jp < 0.999:
		# младший партнёр: глава правительства не даёт менять бюджет резко
		var dd: Dictionary = policy_by_key[key]
		var lim: float = (float(dd["max"]) - float(dd["min"])) * 0.10 * jp
		var base: float = float(prev_pol.get(key, pol[key]))
		if is_abs(key):
			lim = lim * gdp / 100.0
			base = base * gdp / 100.0
		v = clampf(v, base - lim, base + lim)
	if not lock_active(key):
		return v
	var lk: Dictionary = locks[key]
	var lim: float = float(lk["amount"]) if is_abs(key) else float(lk["share"])
	return maxf(v, lim) if int(lk["dir"]) == 1 else minf(v, lim)


func lock_allowed_share(key: String, share: float) -> float:
	if not lock_active(key):
		return share
	var lk: Dictionary = locks[key]
	var lim: float = float(lk["amount"]) / gdp * 100.0 if is_abs(key) else float(lk["share"])
	return maxf(share, lim) if int(lk["dir"]) == 1 else minf(share, lim)


func lock_until_text(key: String) -> String:
	var left: int = int((locks[key] as Dictionary)["until"]) - turn
	return "ещё %s" % months_text(left)


func lock_note(key: String) -> String:
	if not lock_active(key):
		return ""
	var lk: Dictionary = locks[key]
	var lim_txt: String
	if is_abs(key):
		lim_txt = "%.1f млрд" % float(lk["amount"])
	else:
		lim_txt = "%.1f%% ВВП" % float(lk["share"])
	return "Обязательство (%s): нельзя %s %s." % [lock_until_text(key), "опускать ниже" if int(lk["dir"]) == 1 else "поднимать выше", lim_txt]


func expire_locks() -> void:
	for key in locks.keys():
		if turn >= int((locks[key] as Dictionary)["until"]):
			locks.erase(key)


# Эмиссия возможна, только если у страны своя валюта: вне еврозоны или после выхода из неё (в т.ч. выход из ЕС)
func emit_cap() -> float:
	return 0.0 if bool(MACRO.get("euro", true)) else EMIT_MAX


func sync_emit() -> void:
	if not policy_by_key.has("emit"):
		return
	var cap := emit_cap()
	var d: Dictionary = policy_by_key["emit"]
	d["max"] = cap
	d["title"] = "Эмиссия денег (центробанк)" if cap > 0.0 else "Эмиссия денег (ЕЦБ)"
	if float(pol["emit"]) > cap:
		set_policy("emit", cap)
	if sliders.has("emit"):
		var sd: Dictionary = sliders["emit"]
		(sd["slider"] as HSlider).max_value = maxf(cap, 0.1)
		(sd["box"] as Control).visible = cap > 0.0
		(sd["title_lbl"] as Label).text = String(d["title"])
	if emit_note != null:
		emit_note.visible = true
		emit_note.text = ("Налоги — доля ВВП в год; взносы в соцстрахование идут на пенсии и медицину. Печать денег пополняет бюджет, но выше безопасного предела разгоняет инфляцию."
			if cap > 0.0 else "Деньги в еврозоне печатает ЕЦБ, а не правительство: эмиссия появится, если страна выйдет из еврозоны. Налоги — доля ВВП в год.")


func emit_safe_pct() -> float:
	# сколько денег можно напечатать (% ВВП в год), не разгоняя инфляцию
	return clampf(0.35 * growth_ema + 0.25 - maxf(0.0, inflation - 5.0) * 0.15, 0.0, 2.5)


func emit_excess() -> float:
	return maxf(0.0, float(pol["emit"]) - emit_safe_pct())


func lvl_sum(effect: String) -> float:
	var s := 0.0
	for k in LEVEL_EFFECTS:
		var fx: Dictionary = LEVEL_EFFECTS[k]
		if fx.has(effect):
			s += float(fx[effect]) * (float(lvl[k]) - 50.0)
	return s


func issue_multiplier(p: int) -> float:
	# слабое место в стране — козырь соответствующей партии
	var m := 1.0
	for k in LEVEL_EFFECTS:
		var fx: Dictionary = LEVEL_EFFECTS[k]
		if int(fx.get("party", -1)) == p:
			var dv: float = float(lvl[k]) - 50.0
			if k == "corruption":
				m *= 1.0 + clampf(dv / 100.0, -0.3, 0.5)
			else:
				m *= 1.0 + clampf(-dv / 100.0, -0.3, 0.5)
	return m


func regional_potential() -> float:
	var s := 0.0
	for i in regions.size():
		s += float(REGIONS[i]["popm"]) * float(REGIONS[i]["pc"]) * (0.6 + 0.8 * float(regions[i]["dev"]) / 100.0) * sec_idx(i)
	return s


func per_capita(i: int) -> float:
	# ВВП региона на душу населения, тыс. в год
	return gdp * gdp_w[i] / float(regions[i]["popm"])


func avg_per_capita() -> float:
	return gdp / total_pop()


func tier_name(i: int) -> String:
	var ratio: float = per_capita(i) / avg_per_capita()
	if ratio < 0.6:
		return "отсталый"
	if ratio < 0.8:
		return "слаборазвитый"
	if ratio < 1.0:
		return "ниже среднего"
	if ratio < 1.3:
		return "средний"
	if ratio < 1.8:
		return "развитый"
	return "передовой"


func dev_gain_mult(i: int) -> float:
	# в уже развитых регионах вложения дают меньше
	return clampf((100.0 - float(regions[i]["dev"])) / 60.0, 0.2, 1.3)


func tax_ratio() -> float:
	return (float(pol["income"]) + float(pol["social"]) + float(pol["corp"]) + float(pol["vat"])) / 100.0


func project_cost_pct(i: int, pd: Dictionary) -> float:
	# крупные регионы стоят дороже
	return float(pd["cost"]) * (0.6 + 4.5 * gdp_w[i])


func roi_estimate(i: int, reg: Dictionary, cost_pct: float) -> Dictionary:
	var dd: float = float(reg.get("dev", 0.0)) * dev_gain_mult(i)
	dd += float(reg.get("infra", 0.0)) * 0.15 + float(reg.get("edu", 0.0)) * 0.10 + float(reg.get("health", 0.0)) * 0.05
	var rel: float = 0.8 * dd / (60.0 + 0.8 * float(regions[i]["dev"]))
	var gain: float = gdp * gdp_w[i] * rel
	var tax: float = gain * tax_ratio()
	var cost: float = gdp * cost_pct / 100.0
	var years := 999.0
	if tax > 0.02:
		years = cost / tax
	return {"cost": cost, "gain": gain, "tax": tax, "years": years}


func roi_text(i: int, reg: Dictionary, cost_pct: float) -> String:
	var r := roi_estimate(i, reg, cost_pct)
	if float(r["years"]) > 40.0:
		return "Экономически почти не окупается (ВВП региона +%.1f млрд/год): вложение ради лояльности и услуг." % float(r["gain"])
	return "Прирост ВВП региона ≈ +%.1f млрд/год, налогов ≈ +%.1f млрд/год. Окупится примерно за %.1f лет." % [r["gain"], r["tax"], r["years"]]


func effective_reg(i: int, reg: Dictionary) -> Dictionary:
	var out := reg.duplicate()
	if out.has("dev") and float(out["dev"]) > 0.0:
		out["dev"] = float(out["dev"]) * dev_gain_mult(i)
	return out


const AGRI_FX := {"Село": 3.5, "Экологи": -0.6, "Бизнес": -0.2}


func demand_cur(d: Dictionary) -> float:
	var key: String = d["key"]
	if key == "subs" and d.get("abs", false):
		return amt("subs") + amt("agri")
	match key:
		"reg_transfer": return transfer_avg()
		"reg_auto": return reg_avg("auto")
	if d.get("abs", false):
		return amt(key)
	return float(pol[key])


# Законы, у которых к каждому варианту добавлен ползунок «сила действия» (множитель эффектов 0.5…1.5)
const HYBRID_IDS := ["party_funding", "media_law", "healthcare", "education_law", "family_policy", "housing", "migration", "ecology_law", "security_law", "agri_law", "energy_policy", "digital_law"]


# v35: силу действия можно менять у любого обычного закона (не числового, не фундаментального и без радикальных вариантов)
func is_hybrid(tid: String) -> bool:
	if not law_index.has(tid):
		return false
	var t: Dictionary = law_index[tid]
	if t.has("_hyb"):
		return bool(t["_hyb"])
	var ok: bool = not t.has("param")
	if ok and not (tid in HYBRID_IDS):
		if bool(t.get("fund", false)):
			ok = false
		for v in t["v"]:
			if (v as Dictionary).has("rid") or (v as Dictionary).has("set"):
				ok = false
	t["_hyb"] = ok
	return ok


func pw_of(tid: String, cand: bool = false) -> float:
	if not is_hybrid(tid):
		return 1.0
	return float((law_pow_sel if cand else law_pow).get(tid, 1.0))


func scale_dict(d: Dictionary, k: float) -> Dictionary:
	if absf(k - 1.0) < 0.0001:
		return d
	var out := {}
	for key in d:
		out[key] = float(d[key]) * k
	return out


# Режим финансирования партий: 0 — частные пожертвования, 1 — государственное, 2 — доноры без лимитов
func funding_mode() -> int:
	if not law_index.has("party_funding"):
		return 0
	var cur: int = int(law_state["party_funding"])
	var v: Dictionary = variant_of("party_funding", cur)
	if v.has("fm"):
		return int(v["fm"])
	return cur if cur <= 2 else 0


# получает ли партия государственное финансирование (прошла в парламент или набрала ≥1% на прошлых выборах)
func party_funded(p: int) -> bool:
	if p < seats.size() and int(seats[p]) > 0:
		return true
	return p < prev_vote.size() and float(prev_vote[p]) >= 0.01


# множитель голосов партии от системы финансирования
func funding_mult(p: int) -> float:
	var mode := funding_mode()
	if mode == 0:
		return 1.0
	var s: float = float(law_pow.get("party_funding", 1.0))
	if mode == 1:
		return 1.0 + (0.07 if party_funded(p) else -0.12) * s
	var n := PARTY_NAMES.size()
	var avg := 0.0
	for q in range(1, n):
		avg += float(LEAN["Бизнес"][q])
	avg /= float(maxi(1, n - 1))
	var rel: float = 0.35 if p == 0 else clampf((float(LEAN["Бизнес"][p]) - avg) / maxf(0.2, avg), -1.0, 1.0)
	return 1.0 + 0.14 * s * rel


func init_laws() -> void:
	law_index.clear()
	law_state.clear()
	law_cd.clear()
	law_pow.clear()
	law_pow_sel.clear()
	for t in LAW_TOPICS:
		law_index[t["id"]] = t
		law_state[t["id"]] = 0
		law_cd[t["id"]] = 0
	recompute_mods()


func parl_term() -> int:
	return int(mods["parl_term"])


func pres_term() -> int:
	return int(mods["pres_term"])


func impeach_seats() -> int:
	return int(mods["impeach_seats"])


func crisis_limit() -> int:
	return int(mods["crisis_limit"])


func compute_mods(state: Dictionary, include_cabinet: bool = true, cand_tid: String = "") -> Dictionary:
	var m: Dictionary = BASE_MODS.duplicate()
	for tid in state:
		var v := variant_of(tid, int(state[tid]))
		var pw := 1.0
		if int(state[tid]) > 0:
			pw = pw_of(tid, tid == cand_tid)
		var xs: Dictionary = v.get("x", {})
		for k in xs:
			m[k] = float(m.get(k, 1.0)) * (1.0 + (float(xs[k]) - 1.0) * pw)
		var ad: Dictionary = v.get("a", {})
		for k in ad:
			m[k] = float(m.get(k, 0.0)) + float(ad[k]) * pw
		var st: Dictionary = v.get("set", {})
		for k in st:
			m[k] = st[k]
	if include_cabinet and ministers.size() == MINISTRIES.size():
		for mi in MINISTRIES.size():
			var mn: Dictionary = ministers[mi]
			if mn.is_empty():
				continue
			var fx := ministry_fx(mi, ministries[mi], float(mn["skill"]))
			var cx: Dictionary = fx.get("x", {})
			for k in cx:
				m[k] = float(m[k]) * float(cx[k])
			var ca: Dictionary = fx.get("a", {})
			for k in ca:
				m[k] = float(m[k]) + float(ca[k])
	return m


func recompute_mods() -> void:
	sync_ministers()
	mods = compute_mods(law_state, true)
	radical_dyn()
	dip_apply_mods()
	sync_emit()


func scale_fx(fx: Dictionary, k: float) -> Dictionary:
	var out := {"x": {}, "a": {}}
	var xs: Dictionary = fx.get("x", {})
	for key in xs:
		out["x"][key] = 1.0 + (float(xs[key]) - 1.0) * k
	var ad: Dictionary = fx.get("a", {})
	for key in ad:
		out["a"][key] = float(ad[key]) * k
	return out


func mod_good_dir(key: String) -> int:
	if MOD_INFO.has(key):
		return int(MOD_INFO[key]["g"])
	return 1


func boost_good(fx: Dictionary, sf: float) -> Dictionary:
	# навык министра усиливает только полезные эффекты, издержки не растут
	var out := {"x": {}, "a": {}}
	var xs: Dictionary = fx.get("x", {})
	for key in xs:
		var dv: float = float(xs[key]) - 1.0
		var g: int = mod_good_dir(key)
		out["x"][key] = 1.0 + dv * (sf if (g != 0 and (dv > 0.0) == (g > 0)) else 1.0)
	var ad: Dictionary = fx.get("a", {})
	for key in ad:
		var dv2: float = float(ad[key])
		var g2: int = mod_good_dir(key)
		out["a"][key] = dv2 * (sf if (g2 != 0 and (dv2 > 0.0) == (g2 > 0)) else 1.0)
	return out


func describe_econ(e: Dictionary) -> String:
	var parts: PackedStringArray = []
	for k in ["bc", "cc"]:
		if e.has(k):
			parts.append(String(ECON_FX_INFO[k]) % sg(e[k], 0))
	for k in ["wd", "comm", "fxs"]:
		if e.has(k):
			parts.append(String(ECON_FX_INFO[k]) % sg(e[k], 0))
	if e.has("inv"):
		parts.append(String(ECON_FX_INFO["inv"]) % sg(float(e["inv"]) * 100.0))
	if e.has("res"):
		parts.append(String(ECON_FX_INFO["res"]) % sg(e["res"]))
	if e.has("k"):
		for id in e["k"]:
			parts.append("мощности «%s» %s%%" % [String(mk_def(id)["name"]).to_lower(), sg(float(e["k"][id]) * 100.0, 0)])
	if e.has("p"):
		for id in e["p"]:
			parts.append("цены «%s» %s%%" % [String(mk_def(id)["name"]).to_lower(), sg(float(e["p"][id]) * 100.0, 0)])
	if e.has("g"):
		for id in e["g"]:
			parts.append("цены «%s» %s%%" % [String(good_name(id)).to_lower(), sg(float(e["g"][id]) * 100.0, 0)])
	return ", ".join(parts)


func debt_rate() -> float:
	var ratio: float = debt / gdp * 100.0
	var rate: float = float(MACRO.get("debt_base", 0.014)) + maxf(0.0, ratio - float(MACRO.get("debt_thr", 80.0))) * float(MACRO.get("debt_slope", 0.0007)) + risk_prem / 100.0
	if not ec.is_empty():
		rate += (float(ec["rate"]) - RATE0) / 100.0 * 0.35
	return maxf(rate, 0.005)
