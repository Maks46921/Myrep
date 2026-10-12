# Регионы: лояльность, недовольство, проекты, региональная экономика.
extends "res://scripts/logic/economy.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func adm_dev_term(i: int) -> float:
	return 0.0


func ag_unrest_term(i: int) -> float:
	return 0.0


func ate_name(a: int) -> String:
	return ""


func fed_auto_term(i: int) -> float:
	return 0.0


func fed_dev_term(i: int) -> float:
	return 0.0


func fed_loy_term(i: int) -> float:
	return 0.0


func fed_unr_term(i: int) -> float:
	return 0.0


func soc_loy_term(i: int) -> float:
	return 0.0


func soc_unr_term(i: int) -> float:
	return 0.0


func update_forecast() -> void:
	pass


func update_transfer_ui() -> void:
	pass


# --- конец заглушек ---


func select_region(i: int) -> void:
	selected_region = i
	refresh()


# ============================================================
#  СОБЫТИЯ
# ============================================================


func reg_avg(key: String, wkey: String = "pop") -> float:
	var s := 0.0
	for i in regions.size():
		var w: float = pop_w[i] if wkey == "pop" else gdp_w[i]
		s += float(regions[i][key]) * w
	return s


func recalc_weights() -> void:
	var pw: Array[float] = []
	var gw: Array[float] = []
	var tp := 0.0
	var tg := 0.0
	for i in regions.size():
		var r: Dictionary = regions[i]
		var p: float = float(r["popm"])
		var g: float = p * float(REGIONS[i]["pc"]) * (0.6 + 0.8 * float(r["dev"]) / 100.0) * sec_idx(i)
		pw.append(p)
		gw.append(g)
		tp += p
		tg += g
	for i in pw.size():
		pw[i] /= tp
		gw[i] /= tg
	pop_w = pw
	gdp_w = gw


func new_governor(kind: int) -> Dictionary:
	return {"name": GOV_NAMES[randi() % GOV_NAMES.size()], "kind": kind, "skill": float(randi_range(35, 85))}


func transfer_avg() -> float:
	var s := 0.0
	for i in regions.size():
		s += gdp_w[i] * float(regions[i]["transfer"])
	return s


func update_regions() -> void:
	var n := regions.size()
	var ud: Array[float] = []
	for r in regions:
		ud.append(float(r["unrest"]))
	var reg_dev_bonus: float = float(mods["reg_dev_bonus"])
	var attr: Array[float] = []
	var attr_avg := 0.0
	var lvl_dev: float = lvl_sum("reg_dev")
	var lvl_unrest: float = lvl_sum("reg_unrest")
	for i in n:
		var r: Dictionary = regions[i]
		var d: Dictionary = REGIONS[i]
		var bn: Dictionary = r["bonus"]
		var gv: Dictionary = r["gov"]
		var gk: int = int(gv["kind"])
		var gs: float = float(gv["skill"]) / 60.0
		var nb: Array = neighbors[i]
		var nb_u := 0.0
		for j in nb:
			nb_u += ud[j]
		nb_u /= float(maxi(1, nb.size()))
		var tr: float = float(r["transfer"]) - float(d.get("tr", 0.8))
		var gl := 0.0
		if gk == 1:
			gl = 4.0 * gs
		elif gk == 3:
			gl = -2.0
		var lt: float = region_support(i) + gl - (ud[i] - 20.0) * 0.15 + tr * 3.0 + (float(r["infra"]) - float(d["infra"])) * 0.03 + float(loy_off[i]) + fed_loy_term(i) + soc_loy_term(i)
		r["loy"] = clampf(float(r["loy"]) + (lt - float(r["loy"])) * mrate(0.35), 0.0, 100.0)
		var ur: float = clampf(unemployment * (1.7 - 0.9 * float(r["dev"]) / 100.0) + (50.0 - float(r["infra"])) * 0.02 - (sec_idx(i) - 1.0) * 20.0, 1.0, 40.0)
		r["unemp"] = ur
		var ut: float = (20.0 + (50.0 - float(r["loy"])) * 0.45 + (ur - 6.5) * 1.8 + (inflation - 4.0) * 0.8
			+ lvl_unrest + float(mods["reg_unrest_shift"]) - (float(r["dev"]) - float(d["dev"])) * 0.12
			- float(r["auto"]) * 0.15 + float(d["reg"]) * 8.0 - tr * 2.0 + maxf(0.0, nb_u - 40.0) * 0.12 + float(unr_off[i]) + ag_unrest_term(i))
		ut += fed_unr_term(i) + soc_unr_term(i)
		if gk == 2:
			ut -= 3.0 * gs
		elif gk == 3:
			ut -= 4.0
		if float(r["env"]) < 30.0:
			ut += 3.0
		r["unrest"] = clampf(float(r["unrest"]) + (clampf(ut, 0.0, 100.0) - float(r["unrest"])) * mrate(0.5) + randf_range(-0.5, 0.5), 0.0, 100.0)
		var dt: float = (float(d["dev"]) + lvl_dev + float(bn["dev"])
			+ (float(r["infra"]) - float(d["infra"])) * 0.15 + (float(r["edu"]) - float(d["edu"])) * 0.10
			+ (float(r["health"]) - float(d["health"])) * 0.05
			+ tr * 0.8 + reg_dev_bonus * 2.0 - maxf(0.0, float(r["unrest"]) - 40.0) * 0.10)
		dt += fed_dev_term(i) + adm_dev_term(i)
		if gk == 2:
			dt += 4.0 * gs
		r["dev"] = clampf(float(r["dev"]) + (dt - float(r["dev"])) * mrate(0.12), 0.0, 100.0)
		r["infra"] = clampf(float(r["infra"]) + (float(d["infra"]) + (float(lvl["infra_lvl"]) - 50.0) * 0.8 + tr + float(bn["infra"]) - float(r["infra"])) * mrate(0.10), 0.0, 100.0)
		r["edu"] = clampf(float(r["edu"]) + (float(d["edu"]) + (float(lvl["edu_lvl"]) - 50.0) * 0.8 + tr * 0.5 + float(bn["edu"]) - float(r["edu"])) * mrate(0.10), 0.0, 100.0)
		r["health"] = clampf(float(r["health"]) + (float(d["health"]) + (float(lvl["health_lvl"]) - 50.0) * 0.8 + tr * 0.5 + float(bn["health"]) - float(r["health"])) * mrate(0.10), 0.0, 100.0)
		r["env"] = clampf(float(r["env"]) + (float(d["env"]) + (float(lvl["env_lvl"]) - 50.0) * 0.8 + float(bn["env"]) - float(r["env"])) * mrate(0.10), 0.0, 100.0)
		var at: float = float(d["auto"]) + float(mods["auto_shift"]) + (5.0 if gk == 3 else 0.0) + fed_auto_term(i)
		r["auto"] = clampf(float(r["auto"]) + (at - float(r["auto"])) * mrate(0.05), 0.0, 100.0)
		for k in bn:
			bn[k] = float(bn[k]) * (1.0 - mrate(0.02))
		var a: float = float(r["dev"]) - 0.5 * float(r["unrest"]) + (float(r["infra"]) - 50.0) * 0.2 + tr
		a += -(ur - unemployment) * 0.8 + float(r["mbonus"]) * 4.17 - (float(r["rdebt"]) - 40.0) * 0.05
		attr.append(a)
		attr_avg += a / float(n)
	for i in n:
		var r2: Dictionary = regions[i]
		var mg: float = (attr[i] - attr_avg) * 0.00002
		r2["popm"] = float(r2["popm"]) * (1.0 + 0.00015 + mg)
		r2["migr"] = float(r2["migr"]) + (mg * 12000.0 - float(r2["migr"])) * 0.2
		r2["mbonus"] = float(r2["mbonus"]) * 0.97
	reg_econ_step()
	recalc_weights()
	for i in n:
		var rh: Array = regions[i]["grp_h"]
		rh.append(gdp * gdp_w[i])
		if rh.size() > 13:
			rh.pop_front()
	for i in n:
		var pr: Dictionary = regions[i]["proj"]
		if pr.is_empty():
			continue
		pr["left"] = int(pr["left"]) - 1
		if int(pr["left"]) <= 0:
			complete_project(i)


func complete_project(i: int) -> void:
	var pr: Dictionary = regions[i]["proj"]
	var pd := find_by_id(PROJECTS, pr["id"])
	regions[i]["proj"] = {}
	if pd.is_empty():
		return
	var eff := effective_reg(i, pd["reg"])
	complete_struct(i, String(pd["id"]), int(pr.get("ate", -1)))
	apply_reg_delta(i, pd["reg"], true)
	var nat := apply_fx(pd["nat"])
	log_tag("ПРОЕКТ", COL_GOOD, "завершён «%s» в регионе «%s». Регион: %s%s." % [
		pd["name"], REGIONS[i]["name"], describe_reg(eff), (", страна: " + nat) if nat != "" else ""])


# v50: стройка не стоит политкапитала, зато на неё реагируют группы интересов (экологи против угля и газа и т. п.)
const PROJ_GROUP_FX := {
	"power_coal": {"Экологи": -2.0, "Рабочие": 0.6, "Бизнес": 0.3}, "power_gas": {"Экологи": -1.0, "Бизнес": 0.4},
	"power_nuke": {"Экологи": -1.4, "Бизнес": 0.6, "Силовики": 0.3}, "solar_wind": {"Экологи": 1.4, "Молодёжь": 0.4, "Село": -0.4},
	"grid": {"Бизнес": 0.5}, "road": {"Бизнес": 0.4, "Село": 0.3, "Экологи": -0.4}, "rail": {"Бизнес": 0.4, "Экологи": 0.3},
	"port": {"Бизнес": 0.6, "Экологи": -0.4}, "factory": {"Рабочие": 0.8, "Бизнес": 0.4, "Экологи": -0.8},
	"indpark": {"Бизнес": 0.7}, "refinery": {"Рабочие": 0.5, "Бизнес": 0.4, "Экологи": -0.9}, "mine": {"Рабочие": 0.6, "Экологи": -1.5, "Село": -0.3},
	"agro": {"Село": 0.8}, "irrig": {"Село": 0.6, "Экологи": -0.2}, "granary": {"Село": 0.5, "Пенсионеры": 0.2},
	"hospital": {"Пенсионеры": 0.8, "Бюджетники": 0.4}, "university": {"Молодёжь": 0.8, "Бюджетники": 0.3},
	"techpark": {"Молодёжь": 0.6, "Бизнес": 0.4}, "telecom": {"Бизнес": 0.4, "Молодёжь": 0.4},
	"housing": {"Молодёжь": 0.6, "Рабочие": 0.3}, "eco": {"Экологи": 1.2, "Бизнес": -0.2},
}


func proj_group_text(pid: String) -> String:
	var fx: Dictionary = PROJ_GROUP_FX.get(pid, {})
	var parts: PackedStringArray = []
	for g in fx:
		var v: float = float(fx[g])
		parts.append("[color=%s]%s %s[/color]" % [COL_GOOD if v > 0.0 else COL_BAD, g, sg(v, 1)])
	return ", ".join(parts) if parts.size() > 0 else "группы равнодушны"


# начать стройку pid в регионе i (ate — АТЕ, где будет сооружение; -1 — выбрать самую населённую АТЕ региона). "" — успех
func project_start_at(i: int, pid: String, ate: int = -1) -> String:
	if game_over:
		return "игра окончена"
	if opp_mode:
		return "стройкой распоряжается правительство"
	if i < 0 or i >= regions.size():
		return "выберите свой регион"
	if not (regions[i]["proj"] as Dictionary).is_empty():
		return "в регионе уже идёт стройка"
	var pd := find_by_id(PROJECTS, pid)
	if pd.is_empty():
		return "нет такого сооружения"
	if ate < 0:
		ate = region_main_ate(i)
	var cost_pct := project_cost_pct(i, pd)
	regions[i]["proj"] = {"id": pd["id"], "left": int(pd["months"]), "months": int(pd["months"]), "cost": cost_pct, "ate": ate}
	var fx: Dictionary = PROJ_GROUP_FX.get(pid, {})
	for g in fx:
		add_support(String(g), float(fx[g]))
	var where: String = ("«%s», %s" % [REGIONS[i]["name"], ate_name(ate)]) if ate >= 0 else "«%s»" % REGIONS[i]["name"]
	log_tag("ПРОЕКТ", COL_TEAL, "%s — %s: начат «%s» (%d мес., всего %.1f млрд). Реакция: %s. %s" % [
		date_text(), where, pd["name"], pd["months"], gdp * cost_pct / 100.0, proj_group_text(pid), roi_text(i, pd["reg"], cost_pct)])
	refresh()
	return ""


func region_main_ate(i: int) -> int:
	if ate_n <= 0 or i < 0:
		return -1
	var best := -1
	var bp := -1.0
	for ui in map_unit_local:
		if int(map_unit_local[ui]) != i or int(ui) >= ate_lists.size():
			continue
		for a in (ate_lists[int(ui)] as PackedInt32Array):
			var pp: float = ate_pw[a] if a < ate_pw.size() else 0.0
			if pp > bp:
				bp = pp
				best = a
	return best


func start_project() -> void:
	if pl_deny(): return
	if game_over or proj_option == null:
		return
	var why := project_start_at(selected_region, String(PROJECTS[proj_option.selected]["id"]), -1)
	if why != "":
		log_line("[color=%s]Стройка не начата: %s.[/color]" % [COL_WARN, why])


func cancel_project() -> void:
	if game_over:
		return
	var i := selected_region
	var pr: Dictionary = regions[i]["proj"]
	if pr.is_empty():
		return
	var pd := find_by_id(PROJECTS, pr["id"])
	regions[i]["proj"] = {}
	apply_reg_delta(i, {"loyalty": -3.0, "unrest": 3.0})
	log_line("[color=%s]%s: проект «%s» в регионе «%s» остановлен. Жители недовольны (лояльность -3, недовольство +3).[/color]" % [COL_BAD, date_text(), pd["name"], REGIONS[i]["name"]])
	refresh()


func appoint_governor(kind: int) -> void:
	if game_over:
		return
	var ri := selected_region
	var cd: Dictionary = reg_cd[ri]
	if int(cd.get("gov", 0)) > 0 or capital < 8.0:
		return
	capital -= 8.0
	cd["gov"] = 18
	var g := new_governor(kind)
	regions[ri]["gov"] = g
	var d := {}
	if kind == 1:
		d = {"loyalty": 6.0}
	elif kind == 2:
		d = {"dev": 3.0, "unrest": -2.0}
	else:
		d = {"unrest": -6.0, "autonomy": 5.0}
	apply_reg_delta(ri, d)
	log_line("[b]%s: в регионе «%s» новый министр-президент — %s (%s, умение %.0f).[/b] %s. Сразу: %s." % [
		date_text(), REGIONS[ri]["name"], g["name"], GOV_KINDS[kind], g["skill"], GOV_DESC[kind].capitalize(), describe_reg(d)])
	refresh()


func set_transfer(i: int, v: float) -> void:
	regions[i]["transfer"] = clampf(v, 0.0, 5.0)
	update_transfer_ui()
	update_forecast()


func equalize_transfers(mode: int) -> void:
	if game_over:
		return
	if mode == 0:
		for i in regions.size():
			regions[i]["transfer"] = 0.8
		log_line("%s: трансферты всем регионам выровнены: 0.8%% ВВП региона." % date_text())
	elif mode == 1:
		var raw: Array[float] = []
		var tot := 0.0
		for i in regions.size():
			var rv: float = (100.0 - float(regions[i]["dev"])) / 50.0
			raw.append(rv)
			tot += gdp_w[i] * rv
		for i in regions.size():
			regions[i]["transfer"] = clampf(raw[i] * 0.8 / tot, 0.0, 5.0)
		log_line("%s: трансферты перераспределены в пользу бедных регионов (общая сумма прежняя)." % date_text())
	else:
		for i in regions.size():
			regions[i]["transfer"] = 0.3
		log_line("%s: трансферты регионам урезаны до 0.3%% ВВП региона." % date_text())
	update_transfer_ui()
	update_forecast()
	refresh()


func do_region_action(id: String) -> void:
	if game_over:
		return
	var a := find_by_id(REGION_ACTIONS, id)
	var ri := selected_region
	var cd: Dictionary = reg_cd[ri]
	if int(cd.get(id, 0)) > 0:
		return
	if capital < float(a["cap"]):
		log_line("[color=%s]Не хватает политического капитала для действия «%s».[/color]" % [COL_BAD, a["name"]])
		return
	capital -= float(a["cap"])
	debt += gdp * float(a["money"]) / 100.0
	cd[id] = int(a["cd"])
	var eff := effective_reg(ri, a["reg"])
	apply_reg_delta(ri, a["reg"], true)
	var nat := apply_fx(a["nat"])
	var cost_txt := ""
	if float(a["money"]) > 0.0:
		cost_txt = ", расходы %.1f млрд (в долг)" % (gdp * float(a["money"]) / 100.0)
	log_line("[b]%s: «%s» — %s.[/b] Регион: %s%s%s." % [date_text(), REGIONS[ri]["name"], a["name"], describe_reg(eff), cost_txt, (", страна: " + nat) if nat != "" else ""])
	refresh()


func region_ok(kind: String, i: int) -> bool:
	var r: Dictionary = regions[i]
	if kind.begins_with("code:"):
		return String(REGIONS[i]["code"]) in kind.substr(5).split("|")
	var sec: Dictionary = sec_cur(i)
	match kind:
		"unrest30": return float(r["unrest"]) > 30.0
		"sep": return float(r["auto"]) < 40.0 and float(r["unrest"]) > 35.0
		"res": return float(sec["res"]) >= 0.25
		"agr": return float(sec["agr"]) >= 0.25
		"ind": return float(sec["ind"]) >= 0.30
		"srv": return float(sec["srv"]) >= 0.6
		"poor": return float(r["dev"]) < 50.0
		"regional": return float(REGIONS[i]["reg"]) >= 0.5
		"tech": return float(r["edu"]) >= 55.0 and float(sec["srv"]) >= 0.5
		"shrink": return float(r["migr"]) < -0.3
		"boom": return float(r["migr"]) > 0.8
		"debt": return float(r["rdebt"]) >= 55.0
		"zone": return not (r["zones"] as Array).is_empty()
		"tight": return float(r["unemp"]) < unemployment * 0.85
		"rich": return per_capita(i) >= 1.15 * avg_per_capita()
	return true


func de_start_parliament() -> void:
	seats.clear()
	for s in DE_START_SEATS:
		seats.append(int(s))
	for p in PARTY_NAMES.size():
		in_coalition[p] = p in COALITION0
	for cp in COALITION0:
		if cp != 0:
			joined[cp] = -8
			satis[cp] = 58.0
			conc[cp] = 0.0
	for m in MINISTRIES.size():
		ministries[m] = int(DE_START_MIN[m])


func calibrate_regions() -> void:
	# смещения подбираются так, чтобы стартовые лояльность и недовольство земель были стационарными при нынешней политике
	loy_off.clear()
	unr_off.clear()
	for i in regions.size():
		loy_off.append(0.0)
		unr_off.append(0.0)
		calibrate_region(i)


func calibrate_region(i: int) -> void:
	var lvl_unrest: float = lvl_sum("reg_unrest")
	var r: Dictionary = regions[i]
	var d: Dictionary = REGIONS[i]
	var lt: float = region_support(i) - (float(r["unrest"]) - 20.0) * 0.15
	loy_off[i] = float(r["loy"]) - lt
	var nb: Array = neighbors[i]
	var nb_u := 0.0
	for j in nb:
		nb_u += float(regions[j]["unrest"])
	nb_u /= float(maxi(1, nb.size()))
	var ur: float = clampf(unemployment * (1.7 - 0.9 * float(r["dev"]) / 100.0) + (50.0 - float(r["infra"])) * 0.02, 1.0, 40.0)
	var ut: float = (20.0 + (50.0 - float(r["loy"])) * 0.45 + (ur - 6.5) * 1.8 + (inflation - 4.0) * 0.8
		+ lvl_unrest + float(mods["reg_unrest_shift"]) - float(r["auto"]) * 0.15 + float(d["reg"]) * 8.0 + maxf(0.0, nb_u - 40.0) * 0.12)
	unr_off[i] = float(r["unrest"]) - ut


func build_geometry() -> void:
	region_polys.clear()
	region_centers.clear()
	region_parts.clear()
	neighbors.clear()
	var widx := {}
	for wi in WORLD_UNITS.size():
		widx[String(WORLD_UNITS[wi]["id"])] = wi
	var local := {}
	for i in REGIONS.size():
		local[String(REGIONS[i].get("uid", ccode + "-" + String(REGIONS[i]["code"])))] = i
	for i in REGIONS.size():
		var g: Dictionary = WORLD_UNITS[int(widx[String(REGIONS[i].get("uid", ccode + "-" + String(REGIONS[i]["code"])))])]
		var parts: Array = []
		var best := PackedVector2Array()
		var best_area := -1.0
		for part in g["parts"]:
			var pts := PackedVector2Array()
			for k in range(0, (part as Array).size(), 2):
				pts.append(Vector2(float(part[k]), float(part[k + 1])))
			parts.append(pts)
			var ar := absf(polygon_area(pts))
			if ar > best_area:
				best_area = ar
				best = pts
		region_parts.append(parts)
		region_polys.append(best)
		region_centers.append(Vector2(float(g["c"][0]), float(g["c"][1])))
		var nb: Array = []
		for j in g["nb"]:
			var jid := String(WORLD_UNITS[int(j)]["id"])
			if local.has(jid):
				nb.append(int(local[jid]))
		neighbors.append(nb)


# Геометрия: земли Германии (карта 0..100 x 0..96) и страны Западной Европы (мировая карта). Получено из Natural Earth / открытых данных, упрощено.


func sec_idx(i: int) -> float:
	var r: Dictionary = regions[i]
	var base: Dictionary = REGIONS[i]["sec"]
	var s := 0.0
	var tb := 0.0
	for k in RSEC:
		s += float(base[k]) * float(r["smul"][k])
		tb += float(base[k])
	return s / maxf(0.01, tb)


func sec_cur(i: int) -> Dictionary:
	var r: Dictionary = regions[i]
	var base: Dictionary = REGIONS[i]["sec"]
	var out := {}
	var tot := 0.0
	for k in RSEC:
		var v: float = float(base[k]) * float(r["smul"][k])
		out[k] = v
		tot += v
	for k in RSEC:
		out[k] = float(out[k]) / maxf(0.001, tot)
	return out


func dominant_sector(i: int) -> String:
	var sc := sec_cur(i)
	var best := "srv"
	for k in RSEC:
		if float(sc[k]) > float(sc[best]):
			best = k
	return best


func reg_growth(i: int) -> float:
	var h: Array = regions[i]["grp_h"]
	var n := h.size()
	if n < 4:
		return growth
	var m := mini(n - 1, 12)
	return (pow(float(h[n - 1]) / float(h[n - 1 - m]), 12.0 / float(m)) - 1.0) * 100.0


func rdebt_target(i: int) -> float:
	var r: Dictionary = regions[i]
	var fed: float = float(mods.get("fed_share", 0.0))
	var t: float = (25.0 + (60.0 - float(r["dev"])) * 0.5 + (float(r["unemp"]) - 6.0) * 1.5 - float(r["transfer"]) * 5.0
		+ float(r.get("upk", 0.0)) * 6.0 + float(mods.get("rdebt_shift", 0.0)) * 10.0 + fed * (60.0 - float(r["dev"])) * 0.15
		+ maxf(0.0, 1.0 - growth) * 2.0)
	return clampf(t, 5.0, 150.0)


func reg_zones_end(i: int) -> void:
	var r: Dictionary = regions[i]
	for z in (r["zones"] as Array):
		for k in z["s"]:
			r["legacy"][k] = float(r["legacy"][k]) + 0.4 * float(z["s"][k])
	r["zones"] = []
	r["upk"] = 0.0


func reg_econ_step() -> void:
	res_price = clampf(res_price + (1.0 - res_price) * 0.03 + randf_range(-0.035, 0.035), 0.55, 1.7)
	agr_wx = clampf(agr_wx + (1.0 - agr_wx) * 0.15 + randf_range(-0.03, 0.03), 0.8, 1.15)
	var fed: float = float(mods.get("fed_share", 0.0))
	for i in regions.size():
		var r: Dictionary = regions[i]
		var d: Dictionary = REGIONS[i]
		var strc := {"ind": 0.0, "agr": 0.0, "srv": 0.0, "res": 0.0}
		var keep: Array = []
		var upk := 0.0
		for z in (r["zones"] as Array):
			z["left"] = int(z["left"]) - 1
			if int(z["left"]) <= 0:
				for k in z["s"]:
					r["legacy"][k] = float(r["legacy"][k]) + 0.4 * float(z["s"][k])
				log_tag("РЕГИОН", COL_TEAL, "%s — в регионе «%s» завершён срок программы «%s»: часть эффекта остаётся." % [date_text(), d["name"], z["name"]])
				continue
			for k in z["s"]:
				strc[k] = float(strc[k]) + float(z["s"][k])
			upk += float(z["up"])
			keep.append(z)
		r["zones"] = keep
		r["upk"] = upk
		for k in RSEC:
			r["legacy"][k] = float(r["legacy"][k]) * (1.0 - mrate(0.03))
			strc[k] = float(strc[k]) + float(r["legacy"][k])
		var dinf: float = float(r["infra"]) - float(d["infra"])
		var dedu: float = float(r["edu"]) - float(d["edu"])
		var unr: float = maxf(0.0, float(r["unrest"]) - maxf(45.0, float(d["unrest"])))
		var tg := {
			"ind": 1.0 + float(strc["ind"]) + dinf * 0.003 + dedu * 0.002 - unr * 0.004,
			"agr": 1.0 + float(strc["agr"]) + (agr_wx - 1.0) - maxf(0.0, 30.0 - float(r["env"])) * 0.004,
			"srv": 1.0 + float(strc["srv"]) + dedu * 0.004 + dinf * 0.002 - unr * 0.003 + clampf(float(r["migr"]) * 0.002, -0.03, 0.03),
			"res": 1.0 + float(strc["res"]) + (res_price - 1.0) - unr * 0.004}
		var sm: Dictionary = r["smul"]
		for k in RSEC:
			sm[k] = clampf(float(sm[k]) + (float(tg[k]) - float(sm[k])) * mrate(0.35), 0.5, 1.9)
		# фискальный федерализм: богатые регионы выигрывают, бедные проигрывают
		if absf(fed) > 0.001:
			r["dev"] = clampf(float(r["dev"]) + fed * (float(r["dev"]) - 60.0) / 40.0 * 0.08, 0.0, 100.0)
		# долг региона
		var rt := rdebt_target(i)
		r["rdebt"] = clampf(float(r["rdebt"]) + (rt - float(r["rdebt"])) * mrate(0.06), 0.0, 160.0)
		var rdv: float = float(r["rdebt"])
		if rdv > 60.0:
			r["dev"] = clampf(float(r["dev"]) - (rdv - 60.0) * 0.004, 0.0, 100.0)
		if rdv > 75.0:
			if not bool(r["rcrisis"]):
				r["rcrisis"] = true
				log_tag("РЕГИОН", COL_BAD, "%s — долговой кризис в регионе «%s»: долг %.0f%% ВРП, расходы режут, растёт недовольство." % [date_text(), d["name"], rdv])
			r["infra"] = clampf(float(r["infra"]) - 0.15, 0.0, 100.0)
			r["edu"] = clampf(float(r["edu"]) - 0.10, 0.0, 100.0)
			r["unrest"] = clampf(float(r["unrest"]) + 0.3, 0.0, 100.0)
		elif rdv < 65.0:
			r["rcrisis"] = false
		# последствия миграции
		var mg2: float = float(r["migr"])
		if mg2 < -6.0:
			r["edu"] = clampf(float(r["edu"]) - 0.08, 0.0, 100.0)
		elif mg2 > 8.0:
			r["infra"] = clampf(float(r["infra"]) - 0.08, 0.0, 100.0)
	if turn % 12 == 11:
		reg_year_report()


func reg_year_report() -> void:
	if regions.size() < 4:
		return
	var bi := 0
	var wi := 0
	var di := 0
	for i in regions.size():
		if reg_growth(i) > reg_growth(bi):
			bi = i
		if reg_growth(i) < reg_growth(wi):
			wi = i
		if float(regions[i]["rdebt"]) > float(regions[di]["rdebt"]):
			di = i
	log_tag("РЕГИОНЫ", COL_TEAL, "%s — итоги года: быстрее всех росла экономика региона «%s» (%s%%), медленнее всех — «%s» (%s%%); самый высокий региональный долг — в «%s» (%.0f%% ВРП)." % [
		date_text(), REGIONS[bi]["name"], sg(reg_growth(bi), 1), REGIONS[wi]["name"], sg(reg_growth(wi), 1), REGIONS[di]["name"], float(regions[di]["rdebt"])])


func reg_events_all() -> Array:
	var out: Array = REG_EVENTS_GEN.duplicate()
	for e in (REG_EVENTS_CC.get(ccode, []) as Array):
		out.append(e)
	return out


func tool_req(t: Dictionary, i: int) -> String:
	var r: Dictionary = regions[i]
	var sc := sec_cur(i)
	match String(t["req"]):
		"ind15":
			if float(sc["ind"]) < 0.15:
				return "нужна промышленность не меньше 15% экономики региона"
		"tech":
			if float(r["edu"]) < 50.0:
				return "нужно образование региона не ниже 50"
		"agr04":
			if float(sc["agr"]) < 0.04:
				return "нужно сельское хозяйство не меньше 4% экономики региона"
		"srv50":
			if float(sc["srv"]) < 0.5:
				return "нужны услуги не меньше 50% экономики региона"
		"res03":
			if float(sc["res"]) < 0.03:
				return "нужно сырьё не меньше 3% экономики региона"
		"debt40":
			if float(r["rdebt"]) < 40.0:
				return "долг региона ниже 40% ВРП"
	return ""


func tool_effect_text(t: Dictionary, i: int) -> String:
	var parts: PackedStringArray = []
	var f: float = reg_tool_factor(i)
	for k in t["s"]:
		parts.append("%s %s%%" % [SECTOR_NAMES[k], sg(float(t["s"][k]) * f * 100.0, 0)])
	var txt := ""
	if parts.size() > 0:
		txt = "выпуск отраслей: " + ", ".join(parts)
	if t.has("mig"):
		txt += ("; " if txt != "" else "") + "приток населения %s на 1000 в год" % sg(float(t["mig"]), 0)
	if t.has("rdebt"):
		txt += ("; " if txt != "" else "") + "долг региона %s п.п. ВРП" % sg(float(t["rdebt"]), 0)
	var rg := describe_reg(t["reg"]) if not (t["reg"] as Dictionary).is_empty() else ""
	if rg != "":
		txt += ("; " if txt != "" else "") + rg
	return txt


func reg_tool_factor(i: int) -> float:
	# в уже развитых регионах отдача ниже; законы могут её усиливать
	return clampf((100.0 - float(regions[i]["dev"])) / 60.0, 0.35, 1.3) * float(mods.get("zone_eff", 1.0))


func tool_cost_pct(i: int, t: Dictionary) -> float:
	return float(t["cost"]) * (0.6 + 4.5 * gdp_w[i])


func reg_tool_buy() -> void:
	if game_over or re_tool_opt == null:
		return
	var i := selected_region
	var t: Dictionary = REG_TOOLS[re_tool_opt.selected]
	var r: Dictionary = regions[i]
	var cd: Dictionary = reg_cd[i]
	var key := "tool_" + String(t["id"])
	if int(cd.get(key, 0)) > 0 or capital < float(t["cap"]) or tool_req(t, i) != "":
		return
	if int(t["months"]) > 0:
		if (r["zones"] as Array).size() >= 3:
			return
		for z in (r["zones"] as Array):
			if String(z["id"]) == String(t["id"]):
				return
	var cost_pct := tool_cost_pct(i, t)
	capital -= float(t["cap"])
	debt += gdp * cost_pct / 100.0
	cd[key] = 18
	var f := reg_tool_factor(i) * maxf(0.4, 1.0 - 0.25 * float((r["zones"] as Array).size()))
	if int(t["months"]) > 0:
		var s := {}
		for k in t["s"]:
			s[k] = float(t["s"][k]) * f
		(r["zones"] as Array).append({"id": t["id"], "name": t["name"], "left": int(t["months"]), "s": s, "up": float(t["up"])})
	if t.has("mig"):
		r["mbonus"] = float(r["mbonus"]) + float(t["mig"]) * f
	if t.has("rdebt"):
		r["rdebt"] = clampf(float(r["rdebt"]) + float(t["rdebt"]), 0.0, 160.0)
	apply_reg_delta(i, t["reg"], false)
	var nat := apply_fx(t["nat"])
	log_tag("РЕГИОН", COL_TEAL, "%s — «%s»: запущено «%s» (%.1f млрд в долг, политкапитал -%.0f). %s%s." % [
		date_text(), REGIONS[i]["name"], t["name"], gdp * cost_pct / 100.0, float(t["cap"]), tool_effect_text(t, i), (", страна: " + nat) if nat != "" else ""])
	refresh()
