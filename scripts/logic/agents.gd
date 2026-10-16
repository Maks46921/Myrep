# Население: подключение агентов к голосованию, шагу и протестам.
extends "res://scripts/logic/fpai.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func show_desk(i: int) -> void:
	pass


func update_pop_windows() -> void:
	pass


# --- конец заглушек ---


func ag_k() -> int:
	if ag_k_pref > 0:
		return ag_k_pref
	var people := 0.0
	for r in regions:
		people += float(r["popm"]) * 1000000.0
	return clampi(int(round(people / 40000.0 / 50.0)) * 50, 100, 1000)


func ag_make_pos() -> void:
	var P := PARTY_NAMES.size()
	var raw: Array = []
	for p in P:
		var num: Array[float] = [0.0, 0.0, 0.0, 0.0]
		var den := 0.0
		for gi in GROUPS.size():
			var g: String = GROUPS[gi]
			var w: float = float(GROUP_WEIGHT[g]) * float(LEAN[g][p])
			den += w
			for a in 4:
				num[a] += w * float(AgentPop.MU[gi][a])
		var v: Array = []
		for a in 4:
			v.append(num[a] / maxf(den, 0.0001))
		raw.append(v)
	ag_pos_raw = []
	for p in P:
		ag_pos_raw.append((raw[p] as Array).duplicate())
	ag_pos = []
	for p in P:
		ag_pos.append((raw[p] as Array).duplicate())
	for a in 4:
		var m := 0.0
		for p in P:
			m += float(raw[p][a])
		m /= float(P)
		var s := 0.0
		for p in P:
			s += pow(float(raw[p][a]) - m, 2.0)
		s = sqrt(s / float(P))
		for p in P:
			ag_pos[p][a] = (float(raw[p][a]) - m) / maxf(s, 0.05)


func ag_support_arr() -> Array:
	var sup: Array = []
	for g in GROUPS:
		sup.append(float(support[g]))
	return sup


func ag_build() -> void:
	ag_cache.clear()
	ag_ui_ver = -1
	ag_sel = -1
	ag_phase = 0
	ag_exact = false
	if not ag_on:
		AG = null
		return
	var k := ag_k()
	ag_make_pos()
	if ag_shift.size() == 4 and ag_pos.size() > 0:
		for a in 4:
			ag_pos[0][a] = clampf(float(ag_pos[0][a]) + float(ag_shift[a]), -2.6, 2.6)
	var counts: Array = []
	var secw: Array = []
	for ri in regions.size():
		var tr_n: float = float(regions[ri]["popm"]) * 1000000.0 / float(k)
		var row: Array = []
		for g in GROUPS:
			row.append(int(round(tr_n * float(reg_mix[ri][g]))))
		counts.append(row)
		var sc: Dictionary = REGIONS[ri]["sec"]
		secw.append([float(sc["ind"]), float(sc["agr"]), float(sc["srv"]), float(sc["res"])])
	AG = AgentPop.new()
	AG.setup({"R": regions.size(), "P": PARTY_NAMES.size(), "k": k, "seed": ccode.hash(), "counts": counts, "secw": secw,
		"pos": ag_pos, "gpos": ag_pos_raw[0], "rel": regions.map(func(rg): return rg["rel"]), "ur": unemployment / 100.0, "sup": ag_support_arr(), "ng": GOODS.size(),
		"gkg": GOODS.map(func(g): return float(g["kg"])), "gae": GOODS.map(func(g): return float(g["ae"])), "gic": GOODS.map(func(g): return float(g["ic"])),
		"gprof": GROUPS.map(func(gr): return GOODS.map(func(g): return prof_mult(gr, g["id"])))})
	ag_calibrate()
	ag_prot0 = []
	for r in regions.size():
		ag_prot0.append(AG.region_prot(r))
	ag_ver += 1


# стартовая подгонка: доли агентов в каждой ячейке (регион × группа) равны прежней модели
func ag_calibrate() -> void:
	var P := PARTY_NAMES.size()
	var Gn := GROUPS.size()
	var sup := ag_support_arr()
	for it in 2:
		for ri in regions.size():
			var bw := PackedFloat32Array()
			bw.resize(Gn * P)
			for gi in Gn:
				var w := vote_weights(ri, GROUPS[gi], false)
				for p in P:
					bw[gi * P + p] = w[p]
			var loy: float = (float(regions[ri]["loy"]) - 50.0) * 0.5
			var tab := PackedFloat64Array()
			tab.resize(Gn * P)
			var cnt := PackedInt32Array()
			cnt.resize(Gn)
			AG.tally(ri, bw, sup, loy, 3.0, gov_pm_party(), 9, 1, tab, cnt)
			for gi in Gn:
				if cnt[gi] < 1:
					continue
				var tb := 0.0
				for p in P:
					tb += bw[gi * P + p]
				if tb <= 0.0:
					continue
				var ratio := PackedFloat32Array()
				ratio.resize(P)
				for p in P:
					var have: float = float(tab[gi * P + p]) / float(cnt[gi])
					var want: float = bw[gi * P + p] / tb
					ratio[p] = clampf(want / have, 0.5, 2.0) if have > 0.000001 and want > 0.0 else 1.0
				AG.calib_cell(ri, gi, ratio)


func ag_zs() -> PackedFloat32Array:
	var z := PackedFloat32Array()
	z.resize(6)
	z[0] = clampf(-(factor("income") + factor("social") + factor("vat")) / 3.0, -3.0, 3.0)
	z[1] = clampf((factor("benefits") + factor("pensions") + factor("health") + factor("edu")) / 4.0, -3.0, 3.0)
	z[2] = clampf((factor("growth") - factor("unemp")) / 2.0, -3.0, 3.0)
	z[3] = clampf((factor("army") + factor("police")) / 2.0, -3.0, 3.0)
	z[4] = clampf(factor("eco") + factor("env_lvl") / 10.0, -3.0, 3.0)
	z[5] = clampf(-factor("infl") / 2.0, -3.0, 3.0)
	for j in 6:
		z[j] *= AG_ZK
	return z


# отклонения цен товаров от стартовых (в %), умноженные на силу влияния: агенты с «дорожающей» корзиной недовольнее
func ag_zg() -> PackedFloat32Array:
	var z := PackedFloat32Array()
	z.resize(GOODS.size())
	if ec.is_empty() or not ec.has("gp"):
		return z
	for j in GOODS.size():
		z[j] = clampf((float(ec["gp"][GOODS[j]["id"]]) - 1.0) * 100.0, -40.0, 40.0) * AG_GK
	return z


func ag_step() -> void:
	if AG == null or not ag_on:
		return
	# v47_1: обстановка, которую агенты «переживают» сами: цены, рост, безопасность, природа, миграция, коррупция, регион
	var rloy := PackedFloat32Array()
	rloy.resize(regions.size())
	for ri in regions.size():
		rloy[ri] = clampf((float(regions[ri]["loy"]) - 50.0) * 0.25 - (float(regions[ri]["unrest"]) - 30.0) * 0.1, -8.0, 8.0)
	var mig := 0.0
	if not soc.is_empty() and soc.has("in_now"):
		mig = clampf(soc_din() / 3.0, -1.0, 2.0)
	var ctx := {"z": ag_zs(), "zg": ag_zg(), "sup": ag_support_arr(), "ur": unemployment / 100.0, "gpos": ag_pos_raw[0],
		"infl": inflation, "growth": growth, "sec": float(lvl["security_lvl"]), "env": float(lvl["env_lvl"]), "mig": mig,
		"cor": float(lvl["corruption"]), "rloy": rloy}
	AG.step(ctx, ag_phase % AG_STRIDE, AG_STRIDE)
	ag_phase += 1
	ag_ver += 1


func ag_unrest_term(i: int) -> float:
	if AG == null or not ag_on or i >= ag_prot0.size():
		return 0.0
	return (AG.region_prot(i) - float(ag_prot0[i])) * 40.0


func ag_region_table(ri: int, pres: bool, only: Array) -> Dictionary:
	var P := PARTY_NAMES.size()
	var Gn := GROUPS.size()
	var bw := PackedFloat32Array()
	bw.resize(Gn * P)
	for gi in Gn:
		var w := vote_weights(ri, GROUPS[gi], pres)
		for p in P:
			bw[gi * P + p] = 0.0 if (only.size() > 0 and not (p in only)) else w[p]
	var stride: int = 1 if ag_exact else maxi(1, AG.n / AG_POLL_N)
	var loy: float = (float(regions[ri]["loy"]) - 50.0) * 0.5
	var key := "%d_%d_%d" % [ri, 1 if pres else 0, stride]
	var sig := [hash(bw), ag_ver, int(loy * 1000.0), AG.n]
	if ag_cache.has(key) and ag_cache[key]["sig"] == sig:
		return ag_cache[key]
	var tab := PackedFloat64Array()
	tab.resize(Gn * P)
	var cnt := PackedInt32Array()
	cnt.resize(Gn)
	AG.tally(ri, bw, ag_support_arr(), loy, 4.0 if pres else 3.0, gov_pm_party(), 9, stride, tab, cnt)
	var d := {"sig": sig, "tab": tab, "cnt": cnt}
	ag_cache[key] = d
	return d


# v50: симпатии групп к партиям — доля каждой партии среди сторонников группы по всей стране (опрос агентов)
var gp_cache := {}


func group_party_shares() -> Array:
	var key := "%d|%d|%s" % [turn, ag_ver, str(opp_mode)]
	if String(gp_cache.get("k", "")) == key:
		return gp_cache["v"]
	var P := PARTY_NAMES.size()
	var Gn := GROUPS.size()
	var acc: Array = []
	for gi in Gn:
		var row: Array = []
		row.resize(P)
		row.fill(0.0)
		acc.append(row)
	for ri in regions.size():
		if AG != null and ag_on:
			var t := ag_region_table(ri, false, [])
			for gi in Gn:
				for p in P:
					acc[gi][p] += float(t["tab"][gi * P + p])
		else:
			for gi in Gn:
				var w := vote_weights(ri, GROUPS[gi], false)
				var tot := 0.0
				for p in P:
					tot += w[p]
				var m: float = float(reg_mix[ri][GROUPS[gi]]) * float(regions[ri]["popm"])
				for p in P:
					acc[gi][p] += m * w[p] / maxf(tot, 1e-9)
	for gi in Gn:
		var tt := 0.0
		for p in P:
			tt += float(acc[gi][p])
		for p in P:
			acc[gi][p] = float(acc[gi][p]) / maxf(tt, 1e-9)
	gp_cache = {"k": key, "v": acc}
	return acc


# экзит-пол: как голосовали группы (по всем агентам)
func ag_exit_report(pres: bool, only_party: int) -> void:
	if AG == null or not ag_on:
		return
	var P := PARTY_NAMES.size()
	var Gn := GROUPS.size()
	var tab := PackedFloat64Array()
	tab.resize(Gn * P)
	var cnt := PackedInt32Array()
	cnt.resize(Gn)
	for ri in regions.size():
		var t := ag_region_table(ri, pres, [])
		for j in tab.size():
			tab[j] += float(t["tab"][j])
		for g in Gn:
			cnt[g] += int(t["cnt"][g])
	var ps: Array = []
	if only_party >= 0:
		ps = [only_party]
	else:
		var idx: Array = []
		for p in P:
			idx.append(p)
		idx.sort_custom(func(a, b): return int(seats[a]) > int(seats[b]))
		ps = idx.slice(0, 3)
	var parts: PackedStringArray = []
	for p in ps:
		var bg := 0
		var wg := 0
		var bv := -1.0
		var wv := 2.0
		for g in Gn:
			var v: float = float(tab[g * P + p]) / float(maxi(1, cnt[g]))
			if v > bv:
				bv = v
				bg = g
			if v < wv:
				wv = v
				wg = g
		parts.append("«%s»: сильнее всего у группы «%s» (%.0f%%), слабее всего — «%s» (%.0f%%)" % [PARTY_NAMES[p], GROUPS[bg], bv * 100.0, GROUPS[wg], wv * 100.0])
	log_line("[b]Экзит-пол по агентам[/b] (%d агентов, 1 агент = %d чел.): %s." % [AG.n, AG.k, "; ".join(parts)])


# v50: перемещение своей партии по идеологической карте: ось a (0–3), направление d (−1/+1).
# Партия делает шаг к новым избирателям; часть старых, оставшихся «позади», охладеет. Капитал 4, раз в 3 месяца.
func ag_party_shift_check() -> String:
	if AG == null or not ag_on:
		return "модель агентов выключена"
	if game_over:
		return "игра окончена"
	if cap_spendable() < 4.0:
		return "нужно 4 политкапитала"
	if int(ag_shift_cd) > turn:
		return "следующий шаг через %d мес." % (int(ag_shift_cd) - turn)
	return ""


var ag_shift_cd := 0
var ag_shift: Array = []    # накопленный сдвиг партии игрока по осям (сохраняется: позиции пересчитываются при загрузке)


func ag_party_shift(a: int, d: int) -> bool:
	var why := ag_party_shift_check()
	if why != "":
		log_line("[color=%s]Сдвинуть партию нельзя: %s.[/color]" % [COL_WARN, why])
		return false
	capital -= 4.0
	ag_shift_cd = turn + 3
	var nv: float = clampf(float(ag_pos[0][a]) + 0.30 * float(d), -2.6, 2.6)
	if ag_shift.size() < 4:
		ag_shift = [0.0, 0.0, 0.0, 0.0]
	ag_shift[a] = float(ag_shift[a]) + (nv - float(ag_pos[0][a]))
	ag_pos[0][a] = nv
	AG.pos[a] = nv
	for i in AG.n:
		AG.calc_aff(i)
	ag_cache.clear()
	ag_ver += 1
	gp_cache = {}
	var end_name: String = String(AgentPop.AXIS_ENDS[a][1 if d > 0 else 0])
	log_tag("ПАРТИЯ", COL_PURPLE, "%s сдвигается по оси «%s» — к «%s». Новые избиратели присматриваются, часть прежних охладела." % [qn(PARTY_NAMES[0]), AgentPop.AXIS_SHORT[a], end_name])
	refresh()
	return true


func ag_pick(i: int) -> void:
	ag_sel = i
	ag_ui_ver = -1
	# v50: карточка агента по умолчанию закрыта — открываем её при выборе
	if wins.has("pop_agent") and (wins["pop_agent"] as Control).get("closed") == true:
		wins["pop_agent"].set("closed", false)
		show_desk(current_desk)
	update_pop_windows()


func ag_random_agent() -> void:
	if AG == null:
		return
	var f: int = (ag_ui["fg"] as OptionButton).selected - 1
	var i := AG.rng.randi() % AG.n
	if f >= 0:
		for t in 400:
			if int(AG.grp[i]) == f:
				break
			i = AG.rng.randi() % AG.n
	ag_pick(i)


func ag_reset_ui() -> void:
	ag_ui_ver = -1
	update_pop_windows()
