# v36: административно-территориальные единицы (АТЕ) и административные реформы.
# АТЕ — минимальная единица территории (~600 км², data/ate.dat, tools/gen_ate.py). Регион — объединение АТЕ.
# Реформы: передача АТЕ между своими регионами, создание и упразднение регионов, покупка отдельных АТЕ у соседей.
# Население и экономика АТЕ не хранятся отдельно: АТЕ несёт постоянную долю населения (pw) и ВВП (gw) исходного региона,
# а текущие значения считаются как доля от нынешнего региона-владельца.
extends "res://scripts/logic/federation.gd"

const ADM_CD := 6                 # месяцев между реформами
const ADM_SHOCK := 24             # месяцев «притирки» после перекройки границ
const ADM_MAX_REG := 60
const ADM_BLEND := ["loy", "unrest", "dev", "auto", "infra", "edu", "health", "env", "rdebt", "unemp", "relt", "mnet", "migr"]
const ADM_BLEND_D := ["dev", "loy", "unrest", "auto", "reg", "tr", "infra", "edu", "health", "env"]

var ate_k := PackedInt32Array()       # номер АТЕ внутри исходного региона (для имени)


# ============================================================
#  ДАННЫЕ
# ============================================================


func ate_load() -> void:
	if ate_n > 0:
		return
	var d: Dictionary = ATE
	var uid: PackedStringArray = d["uid"]
	ate_n = uid.size()
	var cx: PackedFloat32Array = d["cx"]
	var cy: PackedFloat32Array = d["cy"]
	ate_km = d["km"]
	ate_pw = d["pw"]
	ate_gw = d["gw"]
	var to: PackedInt32Array = d["to"]
	var tv: PackedFloat32Array = d["tv"]
	ate_c.resize(ate_n)
	ate_rect.clear()
	for a in ate_n:
		ate_c[a] = Vector2(cx[a], cy[a])
		var lo := Vector2(1e9, 1e9)
		var hi := Vector2(-1e9, -1e9)
		for k in range(to[a] * 6, to[a + 1] * 6, 2):
			lo = Vector2(minf(lo.x, tv[k]), minf(lo.y, tv[k + 1]))
			hi = Vector2(maxf(hi.x, tv[k]), maxf(hi.y, tv[k + 1]))
		ate_rect.append(Rect2(lo, hi - lo))
	wu_n0 = WORLD_UNITS.size()
	wu_cc0.clear()
	wu_nb0.clear()
	wu_c0.clear()
	var idx := {}
	for ui in wu_n0:
		var u: Dictionary = WORLD_UNITS[ui]
		wu_cc0.append(String(u["cc"]))
		wu_nb0.append((u["nb"] as Array).duplicate())
		wu_c0.append((u["c"] as Array).duplicate())
		idx[String(u["id"])] = ui
	ate_unit0.resize(ate_n)
	for a in ate_n:
		ate_unit0[a] = int(idx.get(uid[a], 0))
	# столицы стран
	ate_cap.clear()
	for cc in WORLD_CAPS:
		var a := ate_at_point(WORLD_CAPS[cc])
		if a >= 0 and String(wu_cc0[ate_unit0[a]]) != String(cc):
			a = -1      # точка столицы у самой границы (Братислава) попала в АТЕ соседа — берём ближайшую свою
		if a < 0:
			var bd := 1e18
			for b in ate_n:
				if String(wu_cc0[ate_unit0[b]]) != String(cc):
					continue
				var dd: float = ate_c[b].distance_squared_to(WORLD_CAPS[cc])
				if dd < bd:
					bd = dd
					a = b
		ate_cap[cc] = a
	# морские связи исходных единиц (Аланды, проливы): соседство единиц без общей сухопутной границы АТЕ
	var land := {}
	var nb: PackedInt32Array = d["nb"]
	var no: PackedInt32Array = d["no"]
	for a in ate_n:
		for k in range(no[a], no[a + 1]):
			var b: int = nb[k]
			land[Vector2i(ate_unit0[a], ate_unit0[b])] = true
	ate_sea.clear()
	for ui in wu_n0:
		for uj in (wu_nb0[ui] as Array):
			if int(uj) > ui and not land.has(Vector2i(ui, int(uj))):
				ate_sea.append([ui, int(uj)])


func ate_nbs(a: int) -> PackedInt32Array:
	var no: PackedInt32Array = ATE["no"]
	return (ATE["nb"] as PackedInt32Array).slice(no[a], no[a + 1])


func ate_at_point(p: Vector2) -> int:
	var to: PackedInt32Array = ATE["to"]
	var tv: PackedFloat32Array = ATE["tv"]
	for a in ate_n:
		if not (ate_rect[a] as Rect2).has_point(p):
			continue
		for k in range(to[a] * 6, to[a + 1] * 6, 6):
			if Geometry2D.point_is_inside_triangle(p, Vector2(tv[k], tv[k + 1]), Vector2(tv[k + 2], tv[k + 3]), Vector2(tv[k + 4], tv[k + 5])):
				return a
	return -1


func ate_reset() -> void:
	# новая игра: исходные единицы карты и исходная принадлежность АТЕ
	ate_load()
	WORLD_UNITS.resize(wu_n0)
	for ui in wu_n0:
		var u: Dictionary = WORLD_UNITS[ui]
		u["cc"] = String(wu_cc0[ui])
		u["nb"] = (wu_nb0[ui] as Array).duplicate()
		u["c"] = (wu_c0[ui] as Array).duplicate()
		u.erase("dead")
	ate_unit = ate_unit0.duplicate()
	ate_sel.clear()
	ate_mode = false
	adm_count = 0
	adm_new_n = 0
	ate_rebuild([])


func ate_rebuild(changed: Array) -> void:
	# списки АТЕ по единицам, соседи единиц и точки подписей изменённых единиц
	var nu := WORLD_UNITS.size()
	var tmp: Array = []
	for ui in nu:
		tmp.append([])
	for a in ate_n:
		(tmp[ate_unit[a]] as Array).append(a)
	ate_lists.clear()
	for ui in nu:
		ate_lists.append(PackedInt32Array(tmp[ui]))
	var nbs: Array = []
	for ui in nu:
		nbs.append({})
	var nb: PackedInt32Array = ATE["nb"]
	var no: PackedInt32Array = ATE["no"]
	for a in ate_n:
		var ua: int = ate_unit[a]
		for k in range(no[a], no[a + 1]):
			var ub: int = ate_unit[nb[k]]
			if ub != ua:
				(nbs[ua] as Dictionary)[ub] = true
	for pr in ate_sea:
		var ui: int = pr[0]
		var uj: int = pr[1]
		if (ate_lists[ui] as PackedInt32Array).size() > 0 and (ate_lists[uj] as PackedInt32Array).size() > 0:
			(nbs[ui] as Dictionary)[uj] = true
			(nbs[uj] as Dictionary)[ui] = true
	for ui in nu:
		var u: Dictionary = WORLD_UNITS[ui]
		var lst: Array = (nbs[ui] as Dictionary).keys()
		lst.sort()
		u["nb"] = lst
		if (ate_lists[ui] as PackedInt32Array).is_empty():
			u["dead"] = true
		else:
			u.erase("dead")
	for ui in changed:
		if int(ui) >= 0 and int(ui) < nu:
			ate_unit_center(int(ui))
	ate_ver += 1


func ate_unit_center(ui: int) -> void:
	# точка подписи: центр той АТЕ, что ближе всего к «центру тяжести» единицы
	var lst: PackedInt32Array = ate_lists[ui]
	if lst.is_empty():
		return
	var s := Vector2.ZERO
	var w := 0.0
	for a in lst:
		s += ate_c[a] * ate_km[a]
		w += ate_km[a]
	s /= maxf(w, 0.001)
	var best: int = lst[0]
	var bd := 1e18
	for a in lst:
		var dd: float = ate_c[a].distance_squared_to(s)
		if dd < bd:
			bd = dd
			best = a
	WORLD_UNITS[ui]["c"] = [ate_c[best].x, ate_c[best].y]


func ate_alive(ui: int) -> bool:
	return ui >= 0 and ui < WORLD_UNITS.size() and not WORLD_UNITS[ui].has("dead")


func ate_unit_has_capital(cc: String, ui: int) -> bool:
	return ate_cap.has(cc) and int(ate_cap[cc]) >= 0 and ate_unit[int(ate_cap[cc])] == ui


func ate_cc(a: int) -> String:
	return String(WORLD_UNITS[ate_unit[a]]["cc"])


func ate_region(a: int) -> int:
	# индекс своего региона или -1
	var u: Dictionary = WORLD_UNITS[ate_unit[a]]
	if String(u["cc"]) != ccode:
		return -1
	return fed_idx_of_uid(String(u["id"]))


func ate_share(lst: Array, ui: int, gdp_share: bool) -> float:
	# доля списка АТЕ в населении (или ВВП) единицы ui
	var w: PackedFloat32Array = ate_gw if gdp_share else ate_pw
	var tot := 0.0
	for a in (ate_lists[ui] as PackedInt32Array):
		tot += w[a]
	var s := 0.0
	for a in lst:
		if ate_unit[int(a)] == ui:
			s += w[int(a)]
	return s / maxf(tot, 1e-9)


func ate_pop(a: int) -> float:
	# население АТЕ сейчас, млн
	var ui: int = ate_unit[a]
	var u: Dictionary = WORLD_UNITS[ui]
	var cc := String(u["cc"])
	var pm := 0.0
	if cc == ccode:
		var i := fed_idx_of_uid(String(u["id"]))
		if i >= 0:
			pm = float(regions[i]["popm"])
	else:
		pm = float(fed_wreg(cc, String(u["id"])).get("popm", 0.0))
	return pm * ate_share([a], ui, false)


func ate_name(a: int) -> String:
	# имя АТЕ: исходный регион и номер внутри него
	var u0: int = ate_unit0[a]
	if ate_k.size() != ate_n:
		ate_k.resize(ate_n)
		var cnt := {}
		for b in ate_n:
			cnt[ate_unit0[b]] = int(cnt.get(ate_unit0[b], 0)) + 1
			ate_k[b] = int(cnt[ate_unit0[b]])
	var k: int = ate_k[a]
	var cc0 := String(wu_cc0[u0])
	var nm := String(WORLD_UNITS[u0]["id"])
	for r in (fed_w0.get(cc0, WORLD[cc0]["regions"]) as Array):
		if String(r["id"]) == nm:
			nm = String(r["short"])
	if cc0 == ccode:
		for r in REGIONS:
			if String(r.get("uid", "")) == String(WORLD_UNITS[u0]["id"]) and not String(r["short"]).is_empty():
				nm = String(r["short"])
	return "%s-%d" % [nm, k]


func ate_groups(sel: Array) -> Array:
	# связные компоненты выделения (по сухопутному соседству АТЕ)
	var inset := {}
	for a in sel:
		inset[int(a)] = true
	var seen := {}
	var out: Array = []
	for a in sel:
		if seen.has(int(a)):
			continue
		var comp: Array = [int(a)]
		seen[int(a)] = true
		var k := 0
		while k < comp.size():
			for b in ate_nbs(int(comp[k])):
				if inset.has(b) and not seen.has(b):
					seen[b] = true
					comp.append(b)
			k += 1
		out.append(comp)
	return out


func ate_touches(lst: Array, pred: Callable) -> bool:
	for a in lst:
		for b in ate_nbs(int(a)):
			if pred.call(b):
				return true
	return false


func adm_region_ui(i: int) -> int:
	return int(fed_ui.get(String(REGIONS[i].get("uid", "")), -1))


func adm_region_ates(i: int) -> PackedInt32Array:
	var ui := adm_region_ui(i)
	return ate_lists[ui] if ui >= 0 else PackedInt32Array()


func adm_region_km(i: int) -> float:
	var s := 0.0
	for a in adm_region_ates(i):
		s += ate_km[a]
	return s


func adm_region_nbs(i: int) -> Array:
	# соседние свои регионы (по суше)
	var ui := adm_region_ui(i)
	var out: Array = []
	if ui < 0:
		return out
	for uj in WORLD_UNITS[ui]["nb"]:
		if String(WORLD_UNITS[int(uj)]["cc"]) == ccode:
			var j := fed_idx_of_uid(String(WORLD_UNITS[int(uj)]["id"]))
			if j >= 0 and not (j in out):
				out.append(j)
	return out


# ============================================================
#  ПЕРЕРАСЧЁТ РЕГИОНОВ ПРИ ПЕРЕДАЧЕ АТЕ
# ============================================================


func adm_devf(i: int) -> float:
	return (0.6 + 0.8 * float(regions[i]["dev"]) / 100.0) * sec_idx(i)


func adm_pot(i: int) -> float:
	return float(REGIONS[i]["popm"]) * float(REGIONS[i]["pc"]) * adm_devf(i)


func adm_mix_blend(a: Dictionary, b: Dictionary, w: float) -> Dictionary:
	var out := a.duplicate()
	for k in b:
		out[k] = lerpf(float(a.get(k, b[k])), float(b[k]), w)
	return out


func adm_blend(src: int, dst: int, fp: float, fg: float) -> void:
	# часть населения fp (и ВВП fg) региона src переходит в регион dst: смешиваем показатели по весу населения,
	# потенциал ВВП переносится так, что общий ВВП страны не меняется
	var rs: Dictionary = regions[src]
	var rd: Dictionary = regions[dst]
	var ds: Dictionary = REGIONS[src]
	var dd: Dictionary = REGIONS[dst]
	var pot_s := adm_pot(src)
	var pot_d := adm_pot(dst) if float(dd["popm"]) > 1e-6 else 0.0
	var mv_pot: float = pot_s * fg
	var mp: float = float(rs["popm"]) * fp
	var mp0: float = float(ds["popm"]) * fp
	var w: float = mp / maxf(1e-9, float(rd["popm"]) + mp)
	var wp: float = mv_pot / maxf(1e-9, pot_d + mv_pot)
	for k in ADM_BLEND:
		if rs.has(k) and rd.has(k):
			rd[k] = lerpf(float(rd[k]), float(rs[k]), w)
	for k in ["rel", "rel0"]:
		if rs.has(k) and rd.has(k):
			var v: Array = (rd[k] as Array).duplicate()
			for f in v.size():
				v[f] = lerpf(float(v[f]), float(rs[k][f]), w)
			rd[k] = v
	for k in ADM_BLEND_D:
		if ds.has(k) and dd.has(k):
			dd[k] = lerpf(float(dd[k]), float(ds[k]), w)
	dd["sec"] = adm_mix_blend(dd["sec"], ds["sec"], wp)
	dd["mix"] = adm_mix_blend(dd["mix"], ds["mix"], w)
	reg_mix[dst] = adm_mix_blend(reg_mix[dst], reg_mix[src], w)
	if REG_BIAS.size() > maxi(src, dst):
		var bb: Array = (REG_BIAS[dst] as Array).duplicate()
		for p in bb.size():
			bb[p] = lerpf(float(bb[p]), float(REG_BIAS[src][p]), w)
		REG_BIAS[dst] = bb
	if loy_off.size() > maxi(src, dst):
		loy_off[dst] = lerpf(float(loy_off[dst]), float(loy_off[src]), w)
		unr_off[dst] = lerpf(float(unr_off[dst]), float(unr_off[src]), w)
	rs["popm"] = float(rs["popm"]) - mp
	ds["popm"] = float(ds["popm"]) - mp0
	rd["popm"] = float(rd["popm"]) + mp
	dd["popm"] = float(dd["popm"]) + mp0
	if float(ds["popm"]) > 1e-4:
		ds["pc"] = pot_s * (1.0 - fg) / maxf(1e-9, float(ds["popm"]) * adm_devf(src))
	dd["pc"] = (pot_d + mv_pot) / maxf(1e-9, float(dd["popm"]) * adm_devf(dst))


func adm_absorb(dst: int, pop: float, g_r: float, wr: Dictionary) -> void:
	# в регион dst входит население pop (млн) чужой страны с ВВП g_r
	var rd: Dictionary = regions[dst]
	var dd: Dictionary = REGIONS[dst]
	var k0: float = gdp / maxf(0.001, regional_potential())
	var pot_d := adm_pot(dst)
	var w: float = pop / maxf(1e-9, float(rd["popm"]) + pop)
	var inc := {"loy": 40.0, "unrest": maxf(float(wr.get("unrest", 20.0)), 28.0), "dev": float(wr.get("dev", rd["dev"])), "auto": float(wr.get("auto", rd["auto"])),
		"infra": float(wr.get("infra", rd["infra"])), "edu": float(wr.get("edu", rd["edu"])), "health": float(wr.get("health", rd["health"])), "env": float(wr.get("env", rd["env"]))}
	for k in inc:
		rd[k] = lerpf(float(rd[k]), float(inc[k]), w)
		if k != "loy" and k != "unrest":
			dd[k] = lerpf(float(dd[k]), float(inc[k]), w)
	var pop0: float = float(dd["popm"])
	rd["popm"] = float(rd["popm"]) + pop
	dd["popm"] = pop0 + pop
	dd["pc"] = (pot_d + g_r / maxf(0.001, k0)) / maxf(1e-9, float(dd["popm"]) * adm_devf(dst))
	gdp += g_r


func adm_new_region(src: int, name: String) -> int:
	# пустой регион-копия src (население 0); заполняется переносом АТЕ через adm_blend
	adm_new_n += 1
	var code := "N%d" % adm_new_n
	var uid := "%s-%s" % [ccode, code]
	while fed_ui.has(uid):
		adm_new_n += 1
		code = "N%d" % adm_new_n
		uid = "%s-%s" % [ccode, code]
	var nd: Dictionary = (REGIONS[src] as Dictionary).duplicate(true)
	nd["code"] = code
	nd["uid"] = uid
	nd["name"] = name
	nd["short"] = name.substr(0, 14)
	nd["popm"] = 0.0
	nd["desc"] = "Новый регион, созданный административной реформой %d года." % (START_YEAR + month / 12)
	var r: Dictionary = (regions[src] as Dictionary).duplicate(true)
	r["popm"] = 0.0
	r["gov"] = new_governor(0)
	r["proj"] = {}
	r["built"] = {}
	r["bonus"] = {"dev": 0.0, "infra": 0.0, "edu": 0.0, "health": 0.0, "env": 0.0}
	r["zones"] = []
	r["upk"] = 0.0
	r["rcrisis"] = false
	r["grp_h"] = []
	REGIONS.append(nd)
	regions.append(r)
	reg_cd.append({})
	reg_mix.append((reg_mix[src] as Dictionary).duplicate())
	if REG_BIAS.size() > src:
		REG_BIAS.append((REG_BIAS[src] as Array).duplicate())
	loy_off.append(float(loy_off[src]) if loy_off.size() > src else 0.0)
	unr_off.append(float(unr_off[src]) if unr_off.size() > src else 0.0)
	var i: int = regions.size() - 1
	fed_region_init(i, false, 0)
	regions[i]["since"] = 0
	WORLD_UNITS.append({"id": uid, "cc": ccode, "c": [ate_c[0].x, ate_c[0].y], "nb": [], "parts": []})
	fed_ui[uid] = WORLD_UNITS.size() - 1
	ate_lists.append(PackedInt32Array())
	adm_upper_seat(1)
	return i


func adm_upper_seat(dir: int) -> void:
	# федерация с местами субъектов в верхней палате: новый субъект получает места, упразднённый — теряет
	var c := fed_cfg()
	var n: int = int(c["seats"])
	if n <= 0 or UPPER.is_empty() or String(UPPER.get("kind", "none")) == "none" or not UPPER.has("blocs"):
		return
	var bl: Array = UPPER["blocs"]
	if dir > 0:
		bl.append([n, [0]])
		UPPER["total"] = int(UPPER["total"]) + n
	else:
		for k in range(bl.size() - 1, -1, -1):
			if int(bl[k][0]) == n:
				bl.remove_at(k)
				UPPER["total"] = int(UPPER["total"]) - n
				break


# ============================================================
#  АДМИНИСТРАТИВНАЯ РЕФОРМА: проверки, цена, последствия
# ============================================================


func adm_cost(pop: float, n: int) -> float:
	# политический капитал реформы
	return snappedf(clampf(3.0 + pop * 2.5 + float(n) * 0.15, 3.0, 20.0), 0.5)


func adm_common_check(cost: float) -> String:
	if game_over:
		return "Игра окончена."
	if fed_cd_get("adm") > 0:
		return "Предыдущая реформа ещё проводится (ещё %d мес.)." % fed_cd_get("adm")
	var dm := fed_dom(int(fst["lvl"]) >= 2)
	if not bool(dm["ok"]):
		return ("Перекройка границ субъектов федерации требует конституционного большинства. " if int(fst["lvl"]) >= 2 else "Нужно большинство в парламенте. ") + String(dm["text"])
	if int(fst["lvl"]) >= 2:
		var up := fed_upper()
		if bool(up["on"]) and not bool(up["ok"]):
			return "%s не даёт согласия: у коалиции %d из %d голосов (нужно %d)." % [up["name"], up["yes"], up["total"], up["need"]]
	if cap_spendable() < cost:
		return "Нужно %.1f политического капитала (есть %.1f)." % [cost, capital]
	return ""


func adm_sel_own(sel: Array) -> bool:
	for a in sel:
		if ate_cc(int(a)) != ccode:
			return false
	return not sel.is_empty()


func adm_sel_pop(sel: Array) -> float:
	var s := 0.0
	for a in sel:
		s += ate_pop(int(a))
	return s


func adm_left_check(sel: Array) -> String:
	# каждому региону-источнику должна остаться хотя бы одна АТЕ
	var cnt := {}
	for a in sel:
		var ui: int = ate_unit[int(a)]
		cnt[ui] = int(cnt.get(ui, 0)) + 1
	for ui in cnt:
		if int(cnt[ui]) >= (ate_lists[int(ui)] as PackedInt32Array).size():
			return "В регионе «%s» не останется ни одной АТЕ — чтобы убрать регион целиком, упраздните его." % String(REGIONS[fed_idx_of_uid(String(WORLD_UNITS[int(ui)]["id"]))]["name"])
	return ""


func adm_move_check(sel: Array, dst: int) -> String:
	if not adm_sel_own(sel):
		return "Выделите АТЕ своей страны."
	if dst < 0 or dst >= regions.size():
		return "Выберите регион."
	var dui := adm_region_ui(dst)
	var lst: Array = []
	for a in sel:
		if ate_unit[int(a)] != dui:
			lst.append(int(a))
	if lst.is_empty():
		return "Все выделенные АТЕ уже в этом регионе."
	var l := adm_left_check(lst)
	if l != "":
		return l
	for comp in ate_groups(lst):
		if not ate_touches(comp, func(b: int) -> bool: return ate_unit[b] == dui):
			return "Выделенные АТЕ должны граничить с регионом «%s»." % String(REGIONS[dst]["name"])
	return adm_common_check(adm_cost(adm_sel_pop(lst), lst.size()))


func adm_create_check(sel: Array) -> String:
	if not adm_sel_own(sel):
		return "Выделите АТЕ своей страны."
	if regions.size() >= ADM_MAX_REG:
		return "Регионов уже %d — больше не получится." % ADM_MAX_REG
	if ate_groups(sel).size() > 1:
		return "Новый регион должен быть цельным: выделенные АТЕ должны граничить друг с другом."
	var l := adm_left_check(sel)
	if l != "":
		return l
	return adm_common_check(adm_cost(adm_sel_pop(sel), sel.size()) + 4.0)


func adm_delete_check(i: int, dst: int) -> String:
	if regions.size() <= 2:
		return "В стране должно остаться хотя бы два региона."
	if i < 0 or i >= regions.size() or dst < 0 or dst >= regions.size() or i == dst:
		return "Выберите регион, к которому присоединить."
	if not (dst in adm_region_nbs(i)):
		return "Регионы «%s» и «%s» не граничат." % [REGIONS[i]["name"], REGIONS[dst]["name"]]
	return adm_common_check(adm_cost(float(regions[i]["popm"]), adm_region_ates(i).size()) + 2.0)


func adm_aftermath(touched: Array, pop: float, n_ate: int, kind: String) -> void:
	# последствия перекройки: недовольство и падение лояльности в затронутых регионах, разовые расходы, «притирка»
	for i in touched:
		var r: Dictionary = regions[int(i)]
		var share: float = clampf(pop / maxf(0.05, float(r["popm"])), 0.0, 1.0)
		var idn: float = 1.0 + 2.0 * float(REGIONS[int(i)].get("reg", 0.0))      # регионы с сильной идентичностью переживают сильнее
		r["unrest"] = clampf(float(r["unrest"]) + (3.0 + 8.0 * share) * idn, 0.0, 100.0)
		r["loy"] = clampf(float(r["loy"]) - (2.0 + 5.0 * share) * idn, 0.0, 100.0)
		r["adm"] = ADM_SHOCK
	debt += gdp * (0.0002 + 0.00002 * float(n_ate)) + (gdp * 0.0005 if kind == "create" else 0.0)
	(fst["cd"] as Dictionary)["adm"] = ADM_CD
	adm_count += 1


func adm_dev_term(i: int) -> float:
	# «притирка» после реформы: управление перестраивается, развитие временно ниже
	var m: int = int(regions[i].get("adm", 0))
	return -3.0 * float(m) / float(ADM_SHOCK)


func adm_month() -> void:
	for r in regions:
		if int(r.get("adm", 0)) > 0:
			r["adm"] = int(r["adm"]) - 1


func adm_admin_mult() -> float:
	# госаппарат: каждый регион сверх стартового числа дороже на 1.2%, каждый упразднённый — дешевле
	if wu_cc0.is_empty() or ate_unit.size() != ate_n:
		return 1.0      # до загрузки АТЕ (калибровка бюджета в начале игры)
	return maxf(0.6, 1.0 + 0.012 * float(regions.size() - wu_cc0.count(ccode)))


func adm_apply_moves(lst: Array, dst: int) -> Array:
	# переносит АТЕ (своих регионов) в регион dst; возвращает затронутые регионы (индексы ДО возможного удаления)
	var dui := adm_region_ui(dst)
	var by: Dictionary = {}
	for a in lst:
		var ui: int = ate_unit[int(a)]
		if ui == dui:
			continue
		if not by.has(ui):
			by[ui] = []
		(by[ui] as Array).append(int(a))
	var touched: Array = [dst]
	for ui in by:
		var src := fed_idx_of_uid(String(WORLD_UNITS[int(ui)]["id"]))
		var fp := ate_share(by[ui], int(ui), false)
		var fg := ate_share(by[ui], int(ui), true)
		adm_blend(src, dst, fp, fg)
		touched.append(src)
		for a in by[ui]:
			ate_unit[int(a)] = dui
	var ch: Array = by.keys()
	ch.append(dui)
	ate_rebuild(ch)
	return touched


func adm_move(sel: Array, dst: int) -> Dictionary:
	var why := adm_move_check(sel, dst)
	if why != "":
		return {"done": false, "msg": why}
	var dui := adm_region_ui(dst)
	var lst: Array = []
	for a in sel:
		if ate_unit[int(a)] != dui:
			lst.append(int(a))
	var pop := adm_sel_pop(lst)
	capital -= adm_cost(pop, lst.size())
	var old_auto := reg_avg("auto")
	var touched := adm_apply_moves(lst, dst)
	recalc_weights()
	auto0 += reg_avg("auto") - old_auto
	adm_aftermath(touched, pop, lst.size(), "move")
	fed_rebuild()
	ate_sel.clear()
	var msg := "Административная реформа: %d АТЕ (%.2f млн жителей) переданы региону «%s»." % [lst.size(), pop, REGIONS[dst]["name"]]
	log_line("[b]%s: %s[/b]" % [date_text(), msg])
	refresh()
	return {"done": true, "msg": msg}


func adm_create(sel: Array, name: String) -> Dictionary:
	var why := adm_create_check(sel)
	if why != "":
		return {"done": false, "msg": why}
	name = name.strip_edges()
	if name == "":
		name = "Новый регион %d" % (adm_new_n + 1)
	var pop := adm_sel_pop(sel)
	capital -= adm_cost(pop, sel.size()) + 4.0
	# шаблон — регион, отдающий больше всего жителей
	var best := -1
	var bp := -1.0
	for a in sel:
		var p := ate_pop(int(a))
		if p > bp:
			bp = p
			best = ate_region(int(a))
	var old_auto := reg_avg("auto")
	var i := adm_new_region(best, name)
	var touched := adm_apply_moves(sel, i)
	recalc_weights()
	auto0 += reg_avg("auto") - old_auto
	adm_aftermath(touched, pop, sel.size(), "create")
	regions[i]["loy"] = clampf(float(regions[i]["loy"]) + 3.0, 0.0, 100.0)     # «свой» регион: местные элиты довольны
	fed_rebuild()
	selected_region = i
	ate_sel.clear()
	var msg := "Создан новый регион «%s»: %d АТЕ, %.2f млн жителей." % [name, sel.size(), pop]
	log_line("[b]%s: %s[/b]" % [date_text(), msg])
	refresh()
	return {"done": true, "msg": msg, "idx": i}


func adm_delete(i: int, dst: int) -> Dictionary:
	var why := adm_delete_check(i, dst)
	if why != "":
		return {"done": false, "msg": why}
	var nm := String(REGIONS[i]["name"])
	var dn := String(REGIONS[dst]["name"])
	var lst: Array = Array(adm_region_ates(i))
	var pop: float = float(regions[i]["popm"])
	capital -= adm_cost(pop, lst.size()) + 2.0
	var old_auto := reg_avg("auto")
	var ui := adm_region_ui(i)
	# перенос всех АТЕ, затем удаление пустого региона
	adm_blend(i, dst, 1.0, 1.0)
	for a in lst:
		ate_unit[int(a)] = adm_region_ui(dst)
	ate_rebuild([adm_region_ui(dst)])
	var uid := String(REGIONS[i]["uid"])
	fed_drop_region(i)
	fed_ui.erase(uid)
	WORLD_UNITS[ui]["dead"] = true
	adm_upper_seat(-1)
	var nd: int = dst - (1 if dst > i else 0)
	recalc_weights()
	auto0 += reg_avg("auto") - old_auto
	adm_aftermath([nd], pop, lst.size(), "delete")
	# жители упразднённого региона теряют «свою» власть
	regions[nd]["loy"] = clampf(float(regions[nd]["loy"]) - 3.0 * pop / maxf(0.05, float(regions[nd]["popm"])), 0.0, 100.0)
	fed_rebuild()
	selected_region = nd
	ate_sel.clear()
	var msg := "Регион «%s» упразднён и присоединён к «%s»." % [nm, dn]
	log_line("[b]%s: %s[/b]" % [date_text(), msg])
	refresh()
	return {"done": true, "msg": msg}


func adm_rename(i: int, name: String) -> void:
	name = name.strip_edges()
	if name == "" or i < 0 or i >= regions.size():
		return
	REGIONS[i]["name"] = name
	REGIONS[i]["short"] = name.substr(0, 14)
	map_rebuild()
	refresh()


# ============================================================
#  ПОКУПКА ОТДЕЛЬНЫХ АТЕ
# ============================================================


func ate_buy_quote(sel: Array, mult: float, dst: int) -> Dictionary:
	# dst: свой регион, к которому присоединить, или -1 — отдельным новым регионом
	var q := {"ok": true, "why": [], "sel": sel.duplicate(), "mult": mult, "dst": dst}
	if sel.is_empty():
		q["ok"] = false
		(q["why"] as Array).append("Ничего не выделено.")
		return q
	var cc := ate_cc(int(sel[0]))
	q["cc"] = cc
	for a in sel:
		if ate_cc(int(a)) != cc or cc == ccode:
			q["ok"] = false
			(q["why"] as Array).append("Выделяйте АТЕ одной чужой страны.")
			return q
	if not WORLD.has(cc) or not wsim.has(cc):
		q["ok"] = false
		(q["why"] as Array).append("Эта страна не участвует в сделках.")
		return q
	var cf: Dictionary = FED.get(cc, {})
	var cede: int = int(cf.get("cede", 2))
	# по единицам продавца
	var by := {}
	for a in sel:
		var ui: int = ate_unit[int(a)]
		if not by.has(ui):
			by[ui] = []
		(by[ui] as Array).append(int(a))
	var g_sel := 0.0
	var pop := 0.0
	var loy := 0.0
	var whole: Array = []
	var parts: Array = []
	for ui in by:
		var uid := String(WORLD_UNITS[int(ui)]["id"])
		var wr := fed_wreg(cc, uid)
		var fp := ate_share(by[ui], int(ui), false)
		var fg := ate_share(by[ui], int(ui), true)
		var g: float = fed_wreg_gdp(cc, uid) * fg
		var p: float = float(wr.get("popm", 0.0)) * fp
		g_sel += g
		pop += p
		loy += float(wr.get("loy", 50.0)) * p
		parts.append({"ui": int(ui), "uid": uid, "fp": fp, "fg": fg, "g": g, "pop": p})
		if (by[ui] as Array).size() >= (ate_lists[int(ui)] as PackedInt32Array).size():
			whole.append(int(ui))
	loy /= maxf(pop, 1e-6)
	var n_left: int = (WORLD[cc]["regions"] as Array).size() - whole.size()
	if cede == 0:
		q["ok"] = false
		(q["why"] as Array).append("Конституция страны «%s» не допускает отчуждения территории." % WORLD[cc]["name"])
	if ate_cap.has(cc) and int(ate_cap[cc]) in sel:
		q["ok"] = false
		(q["why"] as Array).append("Среди выделенных — АТЕ со столицей страны.")
	if n_left < 2:
		q["ok"] = false
		(q["why"] as Array).append("У страны останется меньше двух регионов.")
	for comp in ate_groups(sel):
		if not ate_touches(comp, func(b: int) -> bool: return ate_cc(b) == ccode):
			q["ok"] = false
			(q["why"] as Array).append("Каждая выделенная часть должна граничить с вашей территорией.")
			break
	if dst >= 0:
		var dui := adm_region_ui(dst)
		if dst >= regions.size() or not ate_touches(sel, func(b: int) -> bool: return ate_unit[b] == dui):
			q["ok"] = false
			(q["why"] as Array).append("Выделенные АТЕ не граничат с регионом, к которому их нужно присоединить.")
	elif regions.size() >= ADM_MAX_REG:
		q["ok"] = false
		(q["why"] as Array).append("Регионов уже %d — присоедините к существующему." % ADM_MAX_REG)
	if int((fst["terr_cd"] as Dictionary).get(cc, 0)) > 0:
		q["ok"] = false
		(q["why"] as Array).append("Недавние переговоры с «%s» провалились (ещё %d мес.)." % [WORLD[cc]["name"], int((fst["terr_cd"] as Dictionary)[cc])])
	var big: bool = pop > 1.0 or not whole.is_empty()
	var dm := fed_dom(big)
	if not bool(dm["ok"]):
		q["ok"] = false
		(q["why"] as Array).append(("Присоединение требует конституционного большинства. " if big else "Ратификация требует большинства в парламенте. ") + String(dm["text"]))
	var w: Dictionary = wsim[cc]
	var rel := fed_rel(cc)
	var price: float = g_sel * 0.75 * mult
	var gshare: float = g_sel / maxf(1.0, float(WORLD[cc]["gdp"]))
	# небольшие уступки продать проще, чем целый регион
	var p_gov: float = clampf(0.30 + (mult - 1.0) * 0.5 + (60.0 - float(w["stab"])) / 150.0 + (float(w["debt"]) - 60.0) / 400.0 + (rel - 50.0) / 200.0 - gshare * 0.8 - (0.05 if cede == 1 else 0.0) + 0.1 * (1.0 - clampf(pop / 0.5, 0.0, 1.0)), 0.02, 0.92)
	var p_loc: float = clampf(0.25 + (mult - 1.0) * 0.15 + (50.0 - loy) / 150.0 + (fed_pc_ratio(cc) - 1.0) * 0.25, 0.05, 0.95)
	var c := fed_cfg()
	var gdp_pct: float = price / maxf(1.0, gdp) * 100.0
	var p_dom := 1.0
	if bool(c["refd"]) and big:
		p_dom = fed_ref_p(-gdp_pct * 0.004)
	var cap: float = snappedf(clampf(5.0 + mult * 3.0 + pop * 4.0, 6.0, 24.0), 0.5)
	q.merge({"price": price, "gdp_r": g_sel, "pop": pop, "p_gov": p_gov, "p_loc": p_loc, "p_dom": p_dom, "p": p_gov * p_loc * p_dom, "cap": cap,
		"country": String(WORLD[cc]["name"]), "rel": rel, "parts": parts, "whole": whole, "gdp_pct": gdp_pct, "km": adm_sel_km(sel)}, true)
	q["afford"] = cap_spendable() >= cap
	return q


func adm_sel_km(sel: Array) -> float:
	var s := 0.0
	for a in sel:
		s += ate_km[int(a)]
	return s


func ate_buy(sel: Array, mult: float, dst: int, force: int = 0) -> Dictionary:
	var q := ate_buy_quote(sel, mult, dst)
	if not bool(q["ok"]):
		return {"done": false, "msg": "; ".join(PackedStringArray(q["why"]))}
	if not fed_cap_ok(float(q["cap"])):
		return {"done": false, "msg": "Не хватает политического капитала."}
	capital -= float(q["cap"])
	var cc := String(q["cc"])
	var res := {"done": false, "msg": ""}
	var what := "%d АТЕ (%.0f км², %.2f млн жителей)" % [sel.size(), float(q["km"]), float(q["pop"])]
	if not fed_roll(float(q["p_gov"]), force):
		(fst["terr_cd"] as Dictionary)[cc] = 9
		if dip.has(cc):
			dip_change(cc, -2.0)
		res["msg"] = "Правительство страны «%s» отказалось продавать %s (шанс был %.0f%%)." % [q["country"], what, float(q["p_gov"]) * 100.0]
	elif not fed_roll(float(q["p_loc"]), force):
		(fst["terr_cd"] as Dictionary)[cc] = 9
		res["msg"] = "Власти согласились, но жители на местном референдуме отказались менять страну (шанс был %.0f%%)." % (float(q["p_loc"]) * 100.0)
	elif not fed_roll(float(q["p_dom"]), force):
		(fst["terr_cd"] as Dictionary)[cc] = 6
		add_support("Рабочие", -1.0)
		res["msg"] = "Сделка заключена, но на вашем референдуме избиратели отвергли присоединение (шанс был %.0f%%)." % (float(q["p_dom"]) * 100.0)
	else:
		debt += float(q["price"])
		var at := ate_attach(q, sel, dst)
		res = {"done": true, "idx": int(at["tgt"]), "msg": "Куплено у страны «%s»: %s за %.1f млрд (в долг); %s." % [q["country"], what, float(q["price"]),
			("территория вошла в регион «%s»" % String(at["name"])) if dst >= 0 else ("образована федеральная территория «%s»" % String(at["name"]))]}
	log_line("[b]%s: %s[/b]" % [date_text(), res["msg"]])
	refresh()
	return res


# v37: присоединение АТЕ чужой страны (покупка или мирный договор). q — из ate_buy_quote (проверки не требуются).
# dst — свой регион или -1 (новая территория). Возвращает {tgt, name}.
func ate_attach(q: Dictionary, sel: Array, dst: int) -> Dictionary:
	var cc := String(q["cc"])
	var old_auto := reg_avg("auto")
	var tgt := dst
	var tgt_name := ""
	var parts: Array = q["parts"]
	if tgt < 0:
		# новый регион: шаблон — ближайший свой регион, показатели — от продавца
		var nb_i := -1
		for a in sel:
			for b in ate_nbs(int(a)):
				if ate_cc(b) == ccode:
					nb_i = ate_region(b)
					break
			if nb_i >= 0:
				break
		var wr0 := fed_wreg(cc, String(parts[0]["uid"]))
		tgt_name = "%s (присоединённая часть)" % String(wr0.get("short", "Новая территория"))
		tgt = adm_new_region(nb_i, tgt_name)
		regions[tgt]["terr"] = true
		regions[tgt]["comp"] = [0, 0, 0, 0, 0]
		regions[tgt]["cbase"] = [0, 0, 0, 0, 0]
		adm_upper_seat(-1)
		# пустой регион получает показатели первой части сделки целиком (вес 1), остальные смешиваются
	else:
		tgt_name = String(REGIONS[tgt]["name"])
	var tui := adm_region_ui(tgt)
	for pt in parts:
		var wr := fed_wreg(cc, String(pt["uid"]))
		adm_absorb(tgt, float(pt["pop"]), float(pt["g"]), wr)
		if int(pt["ui"]) in q["whole"]:
			fed_rebuild_world_side(cc, String(pt["uid"]))
		else:
			fed_backup_world(cc)
			var wr2 := fed_wreg(cc, String(pt["uid"]))
			wr2["popm"] = maxf(0.001, float(wr2["popm"]) - float(pt["pop"]))
			wsim[cc]["gdp"] = maxf(1.0, float(wsim[cc]["gdp"]) - float(pt["g"]))
	var ch: Array = [tui]
	for a in sel:
		if not (ate_unit[int(a)] in ch):
			ch.append(ate_unit[int(a)])
		ate_unit[int(a)] = tui
	ate_rebuild(ch)
	fst["acq"] = int(fst["acq"]) + 1
	recalc_weights()
	auto0 += reg_avg("auto") - old_auto
	regions[tgt]["adm"] = ADM_SHOCK / 2
	fed_rebuild()
	if dst < 0:
		fed_calibrate_new(tgt)
	if dip.has(cc):
		dip_change(cc, -1.0)
	ate_sel.clear()
	return {"tgt": tgt, "name": tgt_name}
