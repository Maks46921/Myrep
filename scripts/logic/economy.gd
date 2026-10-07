# Экономика: рынки, сооружения, центробанк, торговля, шаг экономики.
extends "res://scripts/logic/goods.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func world_ea_update() -> void:
	pass


# --- конец заглушек ---


func mk_def(id: String) -> Dictionary:
	for m in MARKETS:
		if m["id"] == id:
			return m
	return {}


func init_economy() -> void:
	var mk := {}
	for m in MARKETS:
		mk[m["id"]] = {"K": 1.0 / float(m["u0"]), "sk": 0.0, "D": 1.0, "Dd": 1.0, "Q": 1.0, "u": float(m["u0"]), "p": 1.0, "margin": 0.12,
			"short": 0.0, "imp": float(m["imp"]), "gk": 0.025, "alloc": float(m["w"]), "pt": 1.0}
	ec = {"mk": mk, "rate": RATE0, "rate_auto": true, "rate_goal": RATE0, "fxs": 1.0, "res": 12.0, "nx": 0.0,
		"exp_v": 0.0, "imp_v": 0.0, "tariff": 5.0, "roy_pct": 0.0, "focus": "",
		"wd": 1.0, "comm": 1.0, "comm_shock": 0.0, "fx_shock": 0.0, "rw": 1.0, "ppi": 1.0, "sav": 0.10,
		"cconf": 50.0, "bconf": 50.0, "cc_shock": 0.0, "bc_shock": 0.0, "inv": 0.22, "util": 0.0, "util0": 0.0, "short_tot": 0.0,
		"cpi_idx": 1.0, "reasons": [], "inc": {}, "hist": {}, "x0": 0.0, "k0": 1.0, "hh0": 1.0, "g0": 1.0,
		"revbase": 0.0, "u0": U_NEU, "ec_g": 0.0, "d_infl": 0.0, "d_unemp": 0.0, "struct_up": 0.0, "pr": 0.0,
		"bc_struct": 0.0, "xg": 0.0, "cpi_s": 0.0, "real_gap": 0.0, "Cidx": 1.0, "Iidx": 1.0, "Gidx": 1.0, "Xidx": 1.0,
		"agr_shock": 0.0}
	goods_init()
	# калибровка: экспорт = импорт на старте
	var x0 := 0.0
	var m0 := 0.0
	for m in MARKETS:
		x0 += float(m["w"]) * float(m["x"])
		m0 += float(m["w"]) * float(m["imp"])
	ec["k0"] = x0 / m0
	var ut0 := 0.0
	for m in MARKETS:
		ut0 += float(m["w"]) * float(m["u0"])
	ec["util0"] = ut0
	ec["util"] = ut0
	ec["x0"] = x0
	for m in MARKETS:
		(mk[m["id"]] as Dictionary)["imp"] = minf(0.7, float(m["imp"]) * float(ec["k0"]))
	var b := compute_budget()
	ec["g0"] = (float(b["spending"]) - float(b["interest"])) / gdp
	var inc := income_parts()
	ec["hh0"] = float(inc["total"]) / gdp
	ec["inc"] = inc
	ec["revbase"] = tariff_rev_share() + roy_rev_share()
	other_rev -= float(ec["revbase"])
	var bz := compute_budget()
	def0 = -float(bz["balance"]) / gdp * 100.0
	hist_push()


func tariff_rev_share() -> float:
	# таможенные пошлины, % ВВП
	return float(ec["tariff"]) / 100.0 * 0.7 * import_share() * 100.0


func import_share() -> float:
	var s := 0.0
	for m in MARKETS:
		var st: Dictionary = ec["mk"][m["id"]]
		s += float(m["w"]) * float(st["imp"]) * float(st["D"])
	return s


func roy_rev_share() -> float:
	var m: Dictionary = mk_def("res")
	return float(ec["roy_pct"]) / 100.0 * float(m["w"]) * float(m["x"]) * float(ec["wd"]) * float(ec["comm"]) * 100.0


func ec_budget_lines() -> Dictionary:
	# дополнительные статьи бюджета от экономики
	var out := {"rev": {}, "exp": {}}
	if ec.is_empty():
		return out
	var cust: float = gdp * tariff_rev_share() / 100.0
	var roy: float = gdp * roy_rev_share() / 100.0
	if cust > 0.05:
		out["rev"]["Таможенные пошлины"] = cust
	if roy > 0.05:
		out["rev"]["Доходы от сырья"] = roy
	if float(ec["struct_up"]) > 0.0:
		out["exp"]["Содержание сооружений"] = float(ec["struct_up"]) * gdp / 100.0
	return out


# ---------- сооружения ----------


func struct_count(i: int, id: String) -> int:
	var d: Dictionary = regions[i]["built"]
	if not d.has(id):
		return 0
	return int((d[id] as Dictionary)["n"])


func struct_total(id: String) -> int:
	var n := 0
	for i in regions.size():
		n += struct_count(i, id)
	return n


func struct_cond_factor(cond: float) -> float:
	return 0.4 + 0.6 * cond / 100.0


func struct_step(wear_now: bool = true) -> void:
	var sk := {}
	for m in MARKETS:
		sk[m["id"]] = 0.0
	var bc := 0.0
	var xg := 0.0
	var cpi := 0.0
	var pr := 0.0
	var up := 0.0
	var wear: float = 0.30 + 0.30 * clampf((50.0 - float(lvl["infra_lvl"])) / 50.0, 0.0, 1.0)
	for i in regions.size():
		var bt: Dictionary = regions[i]["built"]
		for id in bt:
			var e: Dictionary = bt[id]
			var pd := find_by_id(PROJECTS, id)
			if pd.is_empty():
				continue
			var n: int = int(e["n"])
			if n <= 0:
				continue
			if wear_now:
				e["cond"] = clampf(float(e["cond"]) - wear, 0.0, 100.0)
			var f: float = struct_cond_factor(float(e["cond"])) * float(n)
			var kd: Dictionary = pd.get("k", {})
			for mid in kd:
				sk[mid] = float(sk[mid]) + float(kd[mid]) * f
			bc += float(pd.get("bc", 0.0)) * f
			xg += float(pd.get("xg", 0.0)) * f
			cpi += float(pd.get("cpi", 0.0)) * f
			pr += float(pd.get("pr", 0.0)) * f
			up += project_cost_pct(i, pd) * float(pd.get("up", 0.05)) * float(n)
	for m in MARKETS:
		(ec["mk"][m["id"]] as Dictionary)["sk"] = float(sk[m["id"]])
	ec["bc_struct"] = minf(bc, 12.0)
	ec["xg"] = minf(xg, 0.12)
	ec["cpi_s"] = minf(cpi, 0.06)
	ec["pr"] = minf(pr, 1.2)
	ec["struct_up"] = up


func complete_struct(i: int, id: String) -> void:
	var bt: Dictionary = regions[i]["built"]
	if bt.has(id):
		var e: Dictionary = bt[id]
		e["n"] = int(e["n"]) + 1
		e["cond"] = (float(e["cond"]) * float(int(e["n"]) - 1) + 100.0) / float(e["n"])
	else:
		bt[id] = {"n": 1, "cond": 100.0}
	if not ec.is_empty():
		struct_step(false)


func repair_cost_pct() -> float:
	var c := 0.0
	for i in regions.size():
		var bt: Dictionary = regions[i]["built"]
		for id in bt:
			var pd := find_by_id(PROJECTS, id)
			var e: Dictionary = bt[id]
			c += project_cost_pct(i, pd) * float(e["n"]) * (100.0 - float(e["cond"])) / 100.0 * 0.45
	return c


func repair_all() -> void:
	if game_over or ec.is_empty():
		return
	var c := repair_cost_pct()
	if c < 0.005:
		return
	debt += gdp * c / 100.0
	for i in regions.size():
		var bt: Dictionary = regions[i]["built"]
		for id in bt:
			(bt[id] as Dictionary)["cond"] = 100.0
	log_tag("РЕМОНТ", COL_TEAL, "%s — отремонтированы все сооружения, %.1f млрд добавлено к долгу." % [date_text(), gdp * c / 100.0])
	struct_step(false)
	refresh()


func struct_total_count() -> int:
	var n := 0
	for pd in PROJECTS:
		n += struct_total(pd["id"])
	return n


# ---------- мир и центробанк ----------


func world_step() -> void:
	var wd: float = float(ec["wd"])
	wd += (1.0 - wd) * 0.035 + randf_range(-0.012, 0.012)
	ec["wd"] = clampf(wd, 0.65, 1.35)
	ec["comm_shock"] = float(ec["comm_shock"]) * 0.96
	var ct: float = 1.0 + 1.3 * (float(ec["wd"]) - 1.0) + float(ec["comm_shock"]) + randf_range(-0.012, 0.012)
	ec["comm"] = clampf(float(ec["comm"]) + (ct - float(ec["comm"])) * 0.15, 0.55, 1.9)
	ec["fx_shock"] = float(ec["fx_shock"]) * 0.9
	ec["bc_shock"] = float(ec["bc_shock"]) * 0.93
	ec["cc_shock"] = float(ec["cc_shock"]) * 0.93


func cb_target() -> float:
	var ew: float = clampf(float(MACRO.get("ecb_w", 0.27)) * 0.67, 0.0, 0.6)
	var own: float = float(MACRO.get("cb_own", -1.0))
	if own >= 0.0:
		ew = own
	var infl_cb: float = (1.0 - ew) * ea_infl + ew * inflation
	return clampf(infl_cb + RATE_NEUTRAL_REAL + 0.55 * (infl_cb - I_TGT) + 0.20 * (growth - G_NEU) + float(mods.get("cb_bias", 0.0)) + float(MACRO.get("cb_off", 0.0)), 0.0, 15.0)


func cb_name() -> String:
	if bool(MACRO.get("euro", true)):
		return "ЕЦБ"
	return "центральный банк"


func cb_step() -> void:
	ec["rate_goal"] = cb_target()
	world_ea_update()
	ec["rate"] = clampf(float(ec["rate"]) + (float(ec["rate_goal"]) - float(ec["rate"])) * 0.30, 0.0, 15.0)
	ec["real_gap"] = float(ec["rate"]) - inflation - RATE_NEUTRAL_REAL


func set_rate(v: float) -> void:
	ec["rate"] = clampf(v, 0.5, 30.0)
	ec["real_gap"] = float(ec["rate"]) - inflation - RATE_NEUTRAL_REAL


# ---------- домохозяйства: доходы и покупательная способность ----------


func income_parts() -> Dictionary:
	var u: float = unemployment
	var u0: float = U_NEU
	if not ec.is_empty():
		u0 = float(ec["u0"])
	var wages: float = gdp * 0.50 * (1.0 - u / 100.0) / (1.0 - u0 / 100.0)
	var itax: float = gdp * (float(pol["income"]) * float(mods["income_mult"]) + float(pol["social"])) / 100.0
	var pens: float = gdp * float(pol["pensions"]) * float(mods["pension_mult"]) / 100.0
	var ben: float = gdp * float(pol["benefits"]) / 100.0
	return {"wages": wages, "tax": itax, "pens": pens, "ben": ben, "total": wages - itax + pens + ben}


func households_step() -> void:
	var rw: float = float(ec["rw"])
	var rwt: float = (1.0 - 0.03 * (inflation - I_NEU)) * (1.0 + 0.012 * (U_NEU - unemployment))
	rw += (clampf(rwt, 0.6, 1.3) - rw) * 0.08
	ec["rw"] = rw
	var inc := income_parts()
	ec["inc"] = inc
	var share: float = float(inc["total"]) / gdp
	ec["ppi"] = share / float(ec["hh0"]) * rw / pow(maxf(0.5, float(ec["cpi_idx"])), 0.5)
	var gap: float = float(ec["real_gap"])
	ec["sav"] = clampf(0.10 + 0.012 * gap - 0.0007 * (float(ec["cconf"]) - 50.0), 0.03, 0.22)
	var ct: float = 50.0 + 40.0 * (float(ec["ppi"]) - 1.0) - 1.2 * (unemployment - U_NEU) - 1.6 * (inflation - I_NEU) + 0.15 * (approval() - 50.0) + float(ec["cc_shock"])
	ec["cconf"] = clampf(float(ec["cconf"]) + (clampf(ct, 5.0, 95.0) - float(ec["cconf"])) * 0.2, 5.0, 95.0)
	ec["Cidx"] = float(ec["ppi"]) * (1.0 - float(ec["sav"])) / 0.90 * (1.0 + 0.002 * (float(ec["cconf"]) - 50.0))


# ---------- бизнес: деловой климат и инвестиции ----------


func bconf_reasons() -> Array:
	var r: Array = []
	var mk: Dictionary = ec["mk"]
	var mw := 0.0
	var uw := 0.0
	for m in MARKETS:
		mw += float(m["w"]) * float((mk[m["id"]] as Dictionary)["margin"])
		uw += float(m["w"]) * float((mk[m["id"]] as Dictionary)["u"])
	var gap: float = float(ec["real_gap"])
	var unr: float = reg_avg("unrest")
	var corr: float = float(lvl["corruption"])
	r.append(["Прибыльность отраслей", 60.0 * (mw - 0.12)])
	r.append(["Налог на прибыль", -1.2 * (float(pol["corp"]) * float(mods["corp_mult"]) - float(pol_def["corp"]))])
	r.append(["Взносы и налоги на труд", -0.6 * (float(pol["social"]) - float(pol_def["social"])) - 0.4 * (float(pol["income"]) - float(pol_def["income"]))])
	r.append(["Стоимость кредита (ставка)", -2.5 * gap])
	r.append(["Спрос и загрузка мощностей", 40.0 * (uw - float(ec["util0"]))])
	r.append(["Стабильность в стране", -0.25 * (unr - 25.0) + 0.10 * (approval() - 50.0)])
	r.append(["Инфляция", -1.5 * (inflation - I_NEU)])
	r.append(["Инфраструктура и энергия", 0.15 * (float(lvl["infra_lvl"]) - 50.0) - 25.0 * float((mk["ene"] as Dictionary)["short"])])
	r.append(["Пошлины и курс валюты", -0.4 * (float(ec["tariff"]) - 5.0) - 30.0 * absf(float(ec["fxs"]) - 1.0)])
	r.append(["Коррупция", -0.15 * (corr - 50.0)])
	r.append(["Субсидии бизнесу и аграриям", 3.0 * (pp0("subs") - float(pol_def["subs"])) + 1.2 * (pp0("agri") - float(pol_def["agri"]))])
	r.append(["Долговая нагрузка", -0.12 * maxf(0.0, debt / gdp * 100.0 - 80.0)])
	r.append(["Сооружения и события", float(ec["bc_struct"]) + float(ec["bc_shock"])])
	return r


func business_step() -> void:
	var rs: Array = bconf_reasons()
	ec["reasons"] = rs
	var t := 50.0
	for e in rs:
		t += float(e[1])
	ec["bconf"] = clampf(float(ec["bconf"]) + (clampf(t, 5.0, 95.0) - float(ec["bconf"])) * 0.2, 5.0, 95.0)
	var gap: float = float(ec["real_gap"])
	var it: float = (0.12 + 0.20 * float(ec["bconf"]) / 100.0) * (1.0 - 0.03 * gap)
	ec["inv"] = clampf(float(ec["inv"]) + (clampf(it, 0.10, 0.34) - float(ec["inv"])) * 0.12, 0.10, 0.34)
	ec["Iidx"] = float(ec["inv"]) / 0.22


# ---------- рынки ----------


func gov_idx() -> float:
	var b := compute_budget()
	return (float(b["spending"]) - float(b["interest"])) / gdp / float(ec["g0"])


func markets_step() -> void:
	var mk: Dictionary = ec["mk"]
	var fxs: float = float(ec["fxs"])
	var tariff: float = float(ec["tariff"])
	ec["Gidx"] = clampf(gov_idx(), 0.5, 1.8)
	var xi: float = float(ec["wd"]) * pow(fxs, -0.9) * (1.0 - 0.004 * maxf(0.0, tariff - 5.0)) * (1.0 + float(ec["xg"]))
	ec["Xidx"] = xi
	var cmk := goods_demand()
	var ene_p: float = float((mk["ene"] as Dictionary)["p"])
	for m in MARKETS:
		var id: String = m["id"]
		var s: Dictionary = mk[id]
		var d: float = float(m["c"]) * float(cmk[id]) + float(m["i"]) * float(ec["Iidx"]) + float(m["g"]) * float(ec["Gidx"]) + float(m["x"]) * xi
		s["D"] = d
		# v35: стартовая доля импорта ограничена так же, как текущая (0,7) — иначе у стран с большим экспортом (BE, NL, PT, SK, HU)
		# загрузка мощностей на старте выходила больше 1 (у Бельгии в промышленности — 7,5) и экономика сразу шла вразнос
		var imp0: float = minf(0.7, float(m["imp"]) * float(ec["k0"]))
		var imp: float = imp0 * pow(fxs, 1.2) * (1.0 - 0.025 * (tariff - 5.0)) + maxf(0.0, float(s["u"]) - 0.95) * (0.1 if id == "ene" else 0.5)
		imp = clampf(imp, 0.0, 0.7)
		s["imp"] = imp
		var dd: float = d * (1.0 - imp) / (1.0 - imp0)
		s["Dd"] = dd
		var keff: float = float(s["K"]) + float(s["sk"])
		var u: float = dd / keff
		s["u"] = u
		s["Q"] = minf(dd, keff)
		s["short"] = maxf(0.0, dd - keff) / maxf(dd, 0.01)
		var pt: float = 1.0 + 1.4 * (u - float(m["u0"]))
		if id != "ene":
			pt += 0.25 * (ene_p - 1.0)
		if id == "res":
			pt = float(ec["comm"])
		elif id == "ind":
			pt += 0.225 * (1.0 / fxs - 1.0) + 0.006 * (tariff - 5.0)
		elif id == "agr":
			pt += float(ec["agr_shock"])
		if id != "res":
			pt -= float(ec["cpi_s"]) * 0.6
		s["pt"] = pt
		s["p"] = clampf(float(s["p"]) + (pt - float(s["p"])) * 0.15, 0.6, 2.2)
		var mg: float = 0.12 + 0.5 * (u - float(m["u0"])) + 0.4 * (float(s["p"]) - 1.0) - 0.007 * (float(pol["corp"]) * float(mods["corp_mult"]) - float(pol_def["corp"])) - 0.15 * (float(ec["rw"]) - 1.0)
		if id == "res":
			mg = 0.12 + 0.35 * (float(ec["comm"]) - 1.0) - 0.004 * (float(ec["roy_pct"]) - 10.0) + 0.3 * (u - float(m["u0"]))
		mg = clampf(mg, -0.1, 0.45)
		s["margin"] = float(s["margin"]) + (mg - float(s["margin"])) * 0.3
	ec["agr_shock"] = float(ec["agr_shock"]) * 0.9
	goods_prices()
	# распределение инвестиций и рост мощностей
	var wsum := 0.0
	var wts := {}
	for m in MARKETS:
		var id2: String = m["id"]
		var wt: float = float(m["w"]) * (1.0 + 4.0 * (float((mk[id2] as Dictionary)["margin"]) - 0.12))
		if id2 == str(ec["focus"]):
			wt *= 1.35
		wt = maxf(wt, 0.01)
		wts[id2] = wt
		wsum += wt
	var util := 0.0
	var shorts := 0.0
	var supply_g := 0.0
	for m in MARKETS:
		var id3: String = m["id"]
		var s3: Dictionary = mk[id3]
		var alloc: float = float(wts[id3]) / wsum
		s3["alloc"] = alloc
		var rel: float = float(ec["inv"]) / 0.22 * alloc / float(m["w"])
		var gk: float = 0.065 * rel - 0.04
		s3["gk"] = gk
		s3["K"] = maxf(0.5, float(s3["K"]) * (1.0 + (gk - 0.025) / 12.0))
		util += float(m["w"]) * float(s3["u"])
		shorts += float(m["w"]) * float(s3["short"])
		supply_g += float(m["w"]) * (gk - 0.025)
	ec["util"] = util
	ec["short_tot"] = shorts
	ec["cpi_idx"] = cpi_goods()
	var g: float = 0.4 * supply_g * 100.0 + 5.0 * (util - float(ec["util0"])) - 8.0 * shorts + float(ec["pr"]) + 0.04 * float(ec["nx"])
	ec["ec_g"] = clampf(g, -2.0, 2.0)
	var pull := 0.0
	for m in MARKETS:
		pull += float(m["kg"]) * (float((mk[m["id"]] as Dictionary)["u"]) - float(m["u0"]))
	var gap: float = float(ec["real_gap"])
	var di: float = -0.35 * clampf(gap, -6.0, 6.0) + 6.0 * pull + 0.2 * (float(ec["comm"]) - 1.0) + 1.0 * (1.0 / fxs - 1.0) + 0.045 * (tariff - 5.0) + 6.0 * shorts
	ec["d_infl"] = clampf(di, -2.0, 2.5)
	ec["d_unemp"] = clampf(-3.0 * (util - float(ec["util0"])) - 0.012 * (float(ec["bconf"]) - 50.0), -1.5, 1.5)


# ---------- торговля ----------


func trade_step() -> void:
	var mk: Dictionary = ec["mk"]
	var fxs: float = float(ec["fxs"])
	var xi: float = float(ec["Xidx"])
	var xv := 0.0
	var mv := 0.0
	for m in MARKETS:
		var id: String = m["id"]
		var s: Dictionary = mk[id]
		var xq: float = float(m["w"]) * float(m["x"]) * xi
		if id == "res":
			xq *= float(ec["comm"])
		xv += xq
		mv += float(m["w"]) * float(s["D"]) * float(s["imp"]) / fxs + float(m["w"]) * float(s["short"]) * float(s["Dd"]) * 0.8
	ec["exp_v"] = xv * gdp
	ec["imp_v"] = mv * gdp
	var nx: float = (xv - mv) * 100.0
	ec["nx"] = nx
	ec["res"] = clampf(float(ec["res"]) + nx / 12.0 * 0.6, -5.0, 60.0)
	var gap: float = float(ec["real_gap"])
	var ft: float = 1.0 + 0.02 * nx + 0.012 * gap - 0.015 * (inflation - I_NEU) + (float(ec["res"]) - 12.0) * 0.003 + float(ec["fx_shock"])
	ec["fxs"] = clampf(fxs + (ft - fxs) * 0.10, 0.6, 1.5)


func economy_step() -> Dictionary:
	if ec.is_empty():
		return {"g": 0.0, "infl": 0.0, "unemp": 0.0}
	world_step()
	cb_step()
	households_step()
	struct_step()
	business_step()
	markets_step()
	trade_step()
	hist_push()
	for m in MARKETS:
		var sm: Dictionary = ec["mk"][m["id"]]
		var wk: String = "short_" + String(m["id"])
		if float(sm["short"]) > 0.03 and not warned.has(wk):
			warned[wk] = true
			log_tag("ДЕФИЦИТ", COL_BAD, "%s — на рынке «%s» не хватает товара (%.0f%% спроса): растут цены и импорт. Стройте мощности или поднимайте инвестиции." % [date_text(), String(m["name"]).to_lower(), float(sm["short"]) * 100.0])
		elif float(sm["short"]) < 0.005 and warned.has(wk):
			warned.erase(wk)
	return {"g": float(ec["ec_g"]), "infl": float(ec["d_infl"]), "unemp": float(ec["d_unemp"])}


# ---------- история для графиков ----------


func hist_push() -> void:
	var h: Dictionary = ec["hist"]
	var vals := {"growth": growth, "infl": inflation, "unemp": unemployment, "rate": float(ec["rate"]), "fxs": float(ec["fxs"]) * 100.0,
		"bconf": float(ec["bconf"]), "cconf": float(ec["cconf"]), "inv": float(ec["inv"]) * 100.0, "util": float(ec["util"]) * 100.0,
		"ppi": float(ec["ppi"]) * 100.0, "nx": float(ec["nx"]), "cpi": float(ec["cpi_idx"]) * 100.0}
	for k in HIST_KEYS:
		if not h.has(k):
			h[k] = []
		var a: Array = h[k]
		a.append(float(vals[k]))
		if a.size() > 360:
			a.pop_front()


# ---------- события и меры ----------


func apply_econ(e: Dictionary) -> void:
	if ec.is_empty():
		return
	if e.has("bc"):
		ec["bc_shock"] = float(ec["bc_shock"]) + float(e["bc"])
		ec["bconf"] = clampf(float(ec["bconf"]) + float(e["bc"]) * 0.6, 5.0, 95.0)
	if e.has("cc"):
		ec["cc_shock"] = float(ec["cc_shock"]) + float(e["cc"])
		ec["cconf"] = clampf(float(ec["cconf"]) + float(e["cc"]) * 0.6, 5.0, 95.0)
	if e.has("wd"):
		ec["wd"] = clampf(float(ec["wd"]) + float(e["wd"]) / 100.0, 0.65, 1.35)
	if e.has("comm"):
		ec["comm_shock"] = float(ec["comm_shock"]) + float(e["comm"]) / 100.0
		ec["comm"] = clampf(float(ec["comm"]) + float(e["comm"]) / 100.0 * 0.5, 0.55, 1.9)
	if e.has("fxs"):
		ec["fxs"] = clampf(float(ec["fxs"]) + float(e["fxs"]) / 100.0, 0.6, 1.5)
		ec["fx_shock"] = float(ec["fx_shock"]) + float(e["fxs"]) / 100.0 * 0.3
	if e.has("inv"):
		ec["inv"] = clampf(float(ec["inv"]) + float(e["inv"]), 0.10, 0.34)
	if e.has("res"):
		ec["res"] = float(ec["res"]) + float(e["res"])
	if e.has("k"):
		for id in e["k"]:
			var s: Dictionary = ec["mk"][id]
			s["K"] = maxf(0.5, float(s["K"]) * (1.0 + float(e["k"][id])))
	if e.has("g"):
		for gid in e["g"]:
			goods_shock(String(gid), float(e["g"][gid]))
	if e.has("p"):
		for id in e["p"]:
			var s2: Dictionary = ec["mk"][id]
			s2["p"] = clampf(float(s2["p"]) + float(e["p"][id]), 0.6, 2.2)
			if id == "agr":
				ec["agr_shock"] = float(ec["agr_shock"]) + float(e["p"][id]) * 0.8


func region_struct_text(i: int) -> String:
	var bt: Dictionary = regions[i]["built"]
	if bt.is_empty():
		return "Сооружений нет."
	var parts: PackedStringArray = []
	for id in bt:
		var pd := find_by_id(PROJECTS, id)
		var e: Dictionary = bt[id]
		parts.append("%s ×%d (%.0f%%)" % [pd["name"], e["n"], e["cond"]])
	return "Построено: " + "; ".join(parts) + "."


func struct_effect_text(pd: Dictionary) -> String:
	var parts: PackedStringArray = []
	var kd: Dictionary = pd.get("k", {})
	for id in kd:
		parts.append("мощность «%s» +%.1f%%" % [String(mk_def(id)["name"]).to_lower(), float(kd[id]) * 100.0])
	if pd.has("bc"):
		parts.append("деловой климат +%.1f" % float(pd["bc"]))
	if pd.has("xg"):
		parts.append("экспорт дешевле на %.1f%%" % (float(pd["xg"]) * 100.0))
	if pd.has("cpi"):
		parts.append("цены ниже на %.1f%%" % (float(pd["cpi"]) * 100.0))
	if pd.has("pr"):
		parts.append("производительность +%.2f п.п. роста в год" % float(pd["pr"]))
	return "%s: %s. %s Содержание %.0f%% стоимости в год; без ремонта сооружение изнашивается." % [
		STRUCT_CATS[int(pd["cat"])], ", ".join(parts) if parts.size() > 0 else "эффекты в самом регионе", pd.get("desc", ""), float(pd["up"]) * 100.0]
