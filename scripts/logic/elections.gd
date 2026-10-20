# Выборы: голоса, места, президентские и парламентские выборы, конкуренция партий.
extends "res://scripts/logic/regions.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func ag_exit_report(pres: bool, only_party: int) -> void:
	pass


func ag_region_table(ri: int, pres: bool, only: Array) -> Dictionary:
	return {}


func ai_form_gov(allow0: bool) -> Dictionary:
	return {}


func au_after_election() -> void:
	pass


func au_control() -> float:
	return 0.0


func au_fraud_shares(sh: Array[float]) -> Array[float]:
	var r: Array[float] = []
	return r


func au_on() -> bool:
	return false


func au_opp_mult(p: int, role: float) -> float:
	return 0.0


func church_vote_mult(ri: int, p: int) -> float:
	return 0.0


func coal_feasible() -> bool:
	return false


func coal_manual() -> bool:
	return false


func coal_talks_start() -> void:
	pass


func coalition_names() -> String:
	return ""


func cu_nat_tension() -> float:
	return 0.0


func cult_vote_mult(ri: int, p: int) -> float:
	return 0.0


func form_government(verbose: bool) -> bool:
	return false


func gov_ok() -> bool:
	return false


func gov_seats() -> int:
	return 0


func is_cordon(p: int) -> bool:
	return false


func log_header(text: String, col: String) -> void:
	pass


func martial_blocks(reason: String) -> bool:
	return false


func mil_at_war() -> bool:
	return false


func opp_after_election() -> String:
	return ""


func opp_campaign() -> void:
	pass


func opp_enter(reason: String, keep: Dictionary = {}) -> void:
	pass


func opp_gov_seats() -> int:
	return 0


func opp_gov_text() -> String:
	return ""


func opp_to_gov(members: Array, pm: int, why: String) -> void:
	pass


func pact_mult(p: int) -> float:
	return 0.0


func present_event() -> void:
	pass


func radical_text() -> String:
	return ""


func show_election(rep: Dictionary) -> void:
	pass


func show_head_election(rep: Dictionary) -> void:
	pass


func swap_idx(v: int, k: int) -> int:
	return 0


func upper_renew(shares: Array) -> String:
	return ""


# --- конец заглушек ---


# v50: насколько партия отвечает за работу власти: глава правительства — 1, партнёры по коалиции — 0.4, остальные — 0.
# Раньше оценка власти группами (бюджет, события) всегда доставалась партии игрока — даже когда она в оппозиции.
func gov_roles() -> Array[float]:
	var out: Array[float] = []
	var P := PARTY_NAMES.size()
	for p in P:
		out.append(0.0)
	if opp_mode:
		if opp_gov.is_empty():
			return out
		for q in (opp_gov.get("members", []) as Array):
			if int(q) >= 0 and int(q) < P:
				out[int(q)] = 0.4
		var pmo: int = int(opp_gov.get("pm", -1))
		if pmo >= 0 and pmo < P:
			out[pmo] = 1.0
		return out
	for q in mini(P, in_coalition.size()):
		if in_coalition[q]:
			out[q] = 0.4
	var pm: int = int(junior_info()["pm"])
	out[clampi(pm, 0, P - 1)] = 1.0
	return out


func gov_pm_party() -> int:
	var r := gov_roles()
	for p in r.size():
		if r[p] >= 1.0:
			return p
	return r.size()


func vote_weights(ri: int, g: String, pres: bool) -> Array[float]:
	var w: Array[float] = []
	var r: Dictionary = regions[ri]
	# 0.56: при игре не за стартовую партию вклад лояльности региона считается от стартового значения (а не от 50):
	# иначе на старте партия власти и ваша получали не те веса, что в опросах (за СвДП АдГ на старте имела 39% вместо 26%)
	var ref: bool = player_orig != 0
	var loy0: float = reg_loy_start(ri) if ref else 50.0
	var eff: float = clampf(float(support[g]) + (float(r["loy"]) - loy0) * 0.5, 5.0, 100.0)
	var lean: Array = LEAN[g]
	var roles := gov_roles()
	var ex: float = 4.0 if pres else 3.0
	# v53: в оппозиции (или если вы играете не за стартовую партию власти) support — поддержка ВАШЕЙ партии,
	# а оценка власти правящими партиями считается отдельно (effg) и относительно старта: их LEAN уже содержит базу.
	# Раньше партия власти получала множитель от вашей же поддержки, а ваша партия — постоянный вес: игра за
	# оппозицию в России давала КПРФ ~49 %, а «Единой России» — 22 %.
	var own_full: bool = opp_mode or player_orig != 0
	var gb: float = maxf(5.0, float(GROUP_BASE[g]))
	var effg: float = eff
	if ref:
		var g0: float = float(group_base0.get(g, gb)) + (loy0 - 50.0) * 0.5
		effg = clampf(g0 - (eff - gb) / 0.6, 5.0, 100.0) if opp_mode else clampf(g0 + (eff - gb), 5.0, 100.0)
	elif opp_mode:
		effg = clampf(gb - (eff - gb) / 0.6, 5.0, 100.0)
	for p in PARTY_NAMES.size():
		var v: float = float(lean[p])
		# 0.56: протестная партия растёт на недовольстве властью — и тогда, когда за неё играете вы (пока она в оппозиции)
		if p == PROTEST_P and roles[p] <= 0.0 and (p != 0 or opp_mode):
			v *= pow(clampf((100.0 - effg) / 50.0, 0.2, 2.0), 2.0)
			if p == 0:
				v *= pow(eff / 50.0, ex * 0.5)
		elif p == 0 and own_full:
			v *= pow(eff / 50.0, ex)
		elif roles[p] > 0.0:
			if ref:
				# оценка власти — на шкале правящей партии (её стартовая поддержка групп); LEAN прежней партии власти подогнан под (поддержка / 50)^k
				var gk: float = pow(effg / 50.0, ex * roles[p])
				if p == player_orig:
					gk /= pow(float(group_base0.get(g, gb)) / 50.0, ex)
				v *= gk
			else:
				v *= pow((effg / gb) if own_full else (eff / 50.0), ex * roles[p])
		elif p == REGIONAL_P:
			v *= (1.0 + float(r["unrest"]) / 40.0) * lerpf(0.6, 1.5, float(REGIONS[ri]["reg"]))
		v *= float(REG_BIAS[ri][p]) * funding_mult(p) * pact_mult(p)
		# 0.58: «медовый месяц» нового правительства: около +2 п.п. у партии премьера, спад за 9 месяцев (Мюллер и Штрём; Stimson)
		if roles[p] > 0.0 and not pres:
			v *= 1.0 + 0.08 * roles[p] * clampf(1.0 - float(turn - gov_born) / 9.0, 0.0, 1.0)
		v *= cult_vote_mult(ri, p) * church_vote_mult(ri, p) * au_opp_mult(p, roles[p]) * er_mig_mult(ri, p)
		if p > 0:
			v *= issue_multiplier(p)
		if pres and p > 0:
			v *= charisma[p]
		w.append(v)
	return w


func reg_loy_start(ri: int) -> float:
	var key := String(REGIONS[ri].get("uid", ccode + "-" + String(REGIONS[ri]["code"])))
	if not reg_loy0.has(key):
		reg_loy0[key] = float(regions[ri]["loy"])
	return float(reg_loy0[key])


func region_shares(ri: int, pres: bool, only: Array = []) -> Array[float]:
	if AG == null or not ag_on:
		return region_shares_legacy(ri, pres, only)
	var t := ag_region_table(ri, pres, only)
	var P := PARTY_NAMES.size()
	var out: Array[float] = []
	for p in P:
		out.append(0.0)
	var tn := 0
	for g in GROUPS.size():
		tn += int(t["cnt"][g])
		for p in P:
			out[p] += float(t["tab"][g * P + p])
	for p in P:
		out[p] /= float(maxi(1, tn))
	return out


func region_shares_legacy(ri: int, pres: bool, only: Array = []) -> Array[float]:
	var out: Array[float] = []
	for p in PARTY_NAMES.size():
		out.append(0.0)
	var mix: Dictionary = reg_mix[ri]
	for g in GROUPS:
		var w := vote_weights(ri, g, pres)
		var tot := 0.0
		for p in w.size():
			if only.size() > 0 and not (p in only):
				w[p] = 0.0
			tot += w[p]
		for p in w.size():
			out[p] += float(mix[g]) * w[p] / tot
	return out


func parl_shares() -> Array[float]:
	var raw := national_shares(false)
	nat_raw_cache = raw.duplicate()
	var thr: float = mods["threshold"]
	var exempt: Array = MACRO.get("thr_exempt", [])   # 0.55.5: списки меньшинств без барьера (Косово: гарантированные места общин)
	var reserved: Dictionary = MACRO.get("reserved", {})
	# 0.58: слот «Прочие» — это несколько мелких партий сразу: он не проходит барьер как одна партия (кроме стран,
	# где независимые и местные списки реально берут места: MACRO.others_pass, и стран без барьера)
	var lump_out: bool = thr >= 0.005 and not bool(MACRO.get("others_pass", false)) and not (6 in exempt)
	var keep := 0.0
	for p in raw.size():
		var ex: bool = (p in exempt) or reserved.has(p) or reserved.has(str(p))
		if (raw[p] < thr and not ex) or (p == 6 and lump_out and not ex):
			raw[p] = 0.0
		keep += raw[p]
	if keep <= 0.0001:
		return national_shares(false)   # барьер выше всех — защита от деления на ноль (никто не прошёл)
	for p in raw.size():
		raw[p] /= keep
	return raw


# наибольшие остатки: n мест пропорционально весам
func hare_seats(w_in: Array[float], n: int) -> Array[int]:
	var shares: Array[float] = []
	var ssum := 0.0
	for x in w_in:
		ssum += x
	for x in w_in:
		shares.append(x / maxf(ssum, 0.0001))
	var res: Array[int] = []
	var rem: Array = []
	var used := 0
	for p in shares.size():
		var q: float = shares[p] * n
		var fl := int(floor(q))
		res.append(fl)
		used += fl
		rem.append([q - fl, p])
	rem.sort_custom(func(a, c): return a[0] > c[0])
	var i := 0
	while used < n and i < rem.size():
		res[rem[i][1]] += 1
		used += 1
		i += 1
	return res


# v53: смешанная несвязанная система (Россия: 225 по спискам + 225 округов). Округа достаются почти целиком лидеру:
# доля округов ~ доля голосов в степени k («закон куба»); при управляемых выборах (au_control) степень выше —
# административный ресурс сильнее всего работает в одномандатных округах.
func smd_frac() -> float:
	return float(ELEC.get("smd", 0.0))


func smd_power() -> float:
	return 2.5 + au_control() * 1.5


# 0.58: метод распределения мест по ELEC.alloc: hare (по умолчанию), dhondt, sl (Сент-Лагё), fptp (округа: победитель
# получает больше своей доли, «закон куба» Кендалла и Стюарта), two_round (два тура: то же, но слабее и с барьером для «кордона»).
# Регионы игры служат округами; места между ними делятся по населению (pop_w).
var nat_raw_cache: Array[float] = []   # национальные доли до барьера (последний parl_shares): нужны региональному подсчёту мест


func divisor_seats(w: Array[float], n: int, sl: bool) -> Array[int]:
	var res: Array[int] = []
	for _p in w.size():
		res.append(0)
	for _s in n:
		var best := -1
		var bq := 0.0
		for p in w.size():
			if w[p] <= 0.0:
				continue
			var div: float = (1.4 if res[p] == 0 else float(res[p] * 2 + 1)) if sl else float(res[p] + 1)
			var q: float = w[p] / div
			if q > bq:
				bq = q
				best = p
		if best < 0:
			break
		res[best] += 1
	return res


func elec_method(smd_part: bool) -> String:
	if smd_part:
		return String(ELEC.get("smd_method", "fptp"))
	return String(ELEC.get("alloc", "hare"))


func elec_power(method: String) -> float:
	if method == "two_round":
		return float(ELEC.get("k", 1.7))
	return float(ELEC.get("k", 3.0))


func region_alloc(w: Array[float], n: int, method: String) -> Array[int]:
	var tot := 0.0
	for x in w:
		tot += x
	if tot <= 0.0 or n <= 0:
		var z: Array[int] = []
		for _p in w.size():
			z.append(0)
		return z
	match method:
		"dhondt":
			return divisor_seats(w, n, false)
		"sl":
			return divisor_seats(w, n, true)
		"fptp", "two_round":
			var k := elec_power(method)
			var wk: Array[float] = []
			for p in w.size():
				var x: float = w[p]
				# 0.58: во втором туре голоса проигравших плохо передаются партиям «кордона» (Франция: Нацобъединение)
				if method == "two_round" and is_cordon(p):
					x *= float(ELEC.get("cordon_k", 0.85))
				wk.append(pow(maxf(x, 0.0), k))
			return hare_seats(wk, n)
		"stv":
			# приближение единого передаваемого голоса: крупные получают небольшую премию, нижним кандидатам голоса передаются
			var ws: Array[float] = []
			for x in w:
				ws.append(pow(maxf(x, 0.0), 1.1))
			return hare_seats(ws, n)
	return hare_seats(w, n)


# места по регионам: shares_in — итоговые национальные доли (после барьера, сдвигов), nat_raw — доли до барьера
func regional_seats(shares_in: Array[float], nseats: int, method: String, smd_part: bool) -> Array[int]:
	var P := shares_in.size()
	var res: Array[int] = []
	for _p in P:
		res.append(0)
	if nseats <= 0 or regions.is_empty() or pop_w.size() != regions.size():
		return hare_seats(shares_in, nseats)
	var quota: Array[int] = hare_seats(pop_w, nseats)
	var rsh: Array = []
	var plain: Array[float] = []
	for _p in P:
		plain.append(0.0)
	for ri in regions.size():
		var rs := region_shares(ri, false)
		rsh.append(rs)
		for p in P:
			plain[p] += pop_w[ri] * rs[p]
	var thr_reg: float = float(ELEC.get("thr_reg", 0.0)) if not smd_part else 0.0
	var reserved: Dictionary = MACRO.get("reserved", {})
	for ri in regions.size():
		if quota[ri] <= 0:
			continue
		var rs2: Array[float] = rsh[ri]
		var w: Array[float] = []
		for p in P:
			var ref: float = shares_in[p]
			if smd_part and ref <= 0.0 and p < nat_raw_cache.size():
				ref = float(nat_raw_cache[p])   # в округах барьер не действует
			var m: float = ref / maxf(plain[p], 0.0001) if plain[p] > 0.0001 else 0.0
			if reserved.has(p) or reserved.has(str(p)):
				m = 0.0
			w.append(rs2[p] * m)
		if thr_reg > 0.0:
			var tt := 0.0
			for x in w:
				tt += x
			for p in P:
				if tt > 0.0 and w[p] / tt < thr_reg:
					w[p] = 0.0
		# 0.58: средняя магнитуда округа (Испания 6,7, Польша 11, Финляндия 15...): регион делится на несколько равных округов
		# с теми же долями: чем меньше округ, тем выше естественный барьер
		var mag: float = float(ELEC.get("mag", 0.0)) if not smd_part else 0.0
		var nd := 1
		if mag > 0.0 and float(quota[ri]) > mag * 1.5:
			nd = maxi(1, int(round(float(quota[ri]) / mag)))
		var base: int = quota[ri] / nd
		var rem: int = quota[ri] - base * nd
		for d in nd:
			var got := region_alloc(w, base + (1 if d < rem else 0), method)
			for p in P:
				res[p] += got[p]
	return res


func apply_seat_bonus(res: Array[int], extra_in: int) -> void:
	var top := 0
	for p in res.size():
		if res[p] > res[top]:
			top = p
	var others: int = SEATS - res[top]
	var extra: int = mini(extra_in, others)
	if others <= 0 or extra <= 0:
		return
	var taken := 0
	for p in res.size():
		if p != top:
			var cut: int = int(floor(float(res[p]) * float(extra) / float(others)))
			res[p] -= cut
			taken += cut
	while taken < extra:
		var big := -1
		for p in res.size():
			if p != top and res[p] > 0 and (big < 0 or res[p] > res[big]):
				big = p
		if big < 0:
			break
		res[big] -= 1
		taken += 1
	res[top] += taken


func allocate_seats(shares_in_all: Array[float]) -> Array[int]:
	var P := shares_in_all.size()
	var shares_in: Array[float] = shares_in_all.duplicate()
	# 0.58: закреплённые места меньшинств (Косово, Хорватия, Словения): раздаются первыми, остальные делятся без них
	var reserved: Dictionary = MACRO.get("reserved", {})
	var fixed: Array[int] = []
	var nres := 0
	for _p in P:
		fixed.append(0)
	for k in reserved:
		var slot := int(k)
		if slot >= 0 and slot < P:
			fixed[slot] = int(reserved[k])
			nres += fixed[slot]
			shares_in[slot] = 0.0
	var n_main: int = SEATS - nres
	var tot0 := 0.0
	for x in shares_in:
		tot0 += x
	if nres > 0 and tot0 > 0.0:
		for p in P:
			shares_in[p] /= tot0
	var res: Array[int] = []
	var smd: float = smd_frac()
	var nsmd: int = int(round(float(n_main) * smd))
	var method := elec_method(false)
	var reg_method: bool = method in ["dhondt", "sl", "fptp", "two_round", "stv"]
	if nsmd > 0 and nsmd < n_main:
		var lst: Array[int] = hare_seats(shares_in, n_main - nsmd)
		var sm: Array[int]
		if bool(ELEC.get("smd_reg", false)):
			sm = regional_seats(shares_in, nsmd, elec_method(true), true)
		else:
			var kw: float = smd_power()
			var w: Array[float] = []
			for x in shares_in:
				w.append(pow(maxf(float(x), 0.0), kw))
			sm = hare_seats(w, nsmd)
		for p in lst.size():
			res.append(lst[p] + sm[p])
	elif nsmd >= n_main and n_main > 0 and bool(ELEC.get("smd_reg", false)):
		res = regional_seats(shares_in, n_main, elec_method(true), true)
	elif reg_method and float(ELEC.get("mag", 0.0)) >= float(SEATS) * 0.8:
		res = region_alloc(shares_in, n_main, method)   # один общенациональный округ
	elif reg_method:
		res = regional_seats(shares_in, n_main, method, false)
	else:
		res = hare_seats(shares_in, n_main)
	for p in P:
		res[p] += fixed[p]
	var bonus: float = float(mods["seat_bonus"])
	var br: Array = ELEC.get("bonus_rule", [])
	if bonus > 0.0 and br.size() == 4:
		# 0.58: бонус победителю по формуле закона (Греция: от 25% голосов 20 мест, +1 за каждые 0,5 п.п., не больше 50);
		# вариант закона с большим бонусом (a.seat_bonus) растягивает формулу
		var lead := 0.0
		for x in shares_in_all:
			lead = maxf(lead, float(x))
		if lead >= float(br[0]):
			var kb: float = bonus / 0.11
			var ex: int = int(round(float(int(br[1]) + int(floor((lead - float(br[0])) / float(br[2])))) * kb))
			apply_seat_bonus(res, mini(ex, int(round(float(br[3]) * minf(1.2, kb)))))
	elif bonus > 0.0:
		apply_seat_bonus(res, int(round(float(SEATS) * bonus)))
	return res


func sorted_parties(shares: Array[float]) -> Array:
	var order: Array = []
	for p in shares.size():
		order.append(p)
	order.sort_custom(func(a, c): return shares[a] > shares[c])
	return order


func head_cand_ok(p: int) -> bool:
	if p == 0:
		return true
	var s: String = String(PARTY_LEADERS[p])
	return s != "—" and s != ""


func head_cand_name(p: int) -> String:
	if p == 0:
		return String(ELEC.get("cand0", "Кандидат вашей партии"))
	return String(PARTY_LEADERS[p]).replace(" (вы)", "")


func head_row(p: int, val: float, win: bool, out: bool, note: String) -> Dictionary:
	return {"name": head_cand_name(p), "sub": PARTY_NAMES[p], "col": PARTY_COLORS[p], "val": val, "win": win, "out": out, "note": note, "you": p == 0}


func head_term_months() -> int:
	var t: int = int(ELEC["term"])
	var m: int = int(mods.get("pres_term", 60))
	if m != 60:
		t = m
	return t


func hold_head(reason: String) -> void:
	ag_exact = true
	hold_head_core(reason)
	if String(ELEC.get("head", "none")) == "direct":
		ag_exit_report(true, pres_party)
	ag_exact = false


func hold_head_core(reason: String) -> void:
	var kind: String = String(ELEC.get("head", "none"))
	if kind == "direct":
		hold_head_direct(reason)
	elif kind == "indirect":
		hold_head_indirect(reason)
	elif kind == "council":
		hold_head_council(reason)
	else:
		pres_due = -1
		return
	if kind == "council":
		pres_due = -1
	else:
		pres_due = turn + head_term_months()
	pres_camp = 0.0
	for p in charisma.size():
		charisma[p] = 1.0


# итог выборов главы государства: возвращает [заголовок, цвет, текст]
func head_outcome(w: int) -> Array:
	pres_party = w
	if String(UPPER.get("kind", "")) == "veto":
		UPPER["veto_p"] = w
	var tt: String = String(ELEC["title_n"])
	var nm: String = head_cand_name(w)
	var vt := ""
	var vc: Color = C_GOOD
	var t := ""
	if w == 0:
		vt = "Ваш кандидат избран"
		capital = minf(100.0, capital + 8.0)
		add_all_support(1.5)
		t = "%s: [b]%s[/b] — человек вашего лагеря. У вас союзник на посту главы государства. Политкапитал +8." % [tt, nm]
	elif in_coalition[w]:
		vt = "Избран кандидат партнёра по коалиции"
		capital = minf(100.0, capital + 4.0)
		add_all_support(0.5)
		t = "%s: [b]%s[/b] («%s»), партнёр по вашей коалиции. Отношения с главой государства дружественные. Политкапитал +4." % [tt, nm, PARTY_NAMES[w]]
	else:
		vt = "Избран оппонент: придётся сотрудничать"
		vc = C_WARN
		capital = minf(100.0, capital - 8.0)
		add_all_support(-1.0)
		t = "%s: [b]%s[/b] («%s»), политический оппонент. Правительству придётся работать с неприязненным главой государства. Политкапитал -8." % [tt, nm, PARTY_NAMES[w]]
	if String(UPPER.get("kind", "")) == "veto":
		t += "\nНовый президент блокирует законы линией партии «%s»: вето теперь работает в её интересах." % PARTY_NAMES[w]
	return [vt, vc, t]


func head_present(rep: Dictionary) -> void:
	log_header(String(rep["title"]) + " — " + date_text(), COL_ELECT)
	log_line(String(rep["log"]))
	show_head_election(rep)
	if not game_over:
		refresh()


func hold_head_direct(reason: String) -> void:
	var n: int = PARTY_NAMES.size()
	var sham: bool = decree_power()
	for p in n:
		charisma[p] = randf_range(0.85, 1.2) if p != 0 else 1.0 + pres_camp
	var cands: Array = []
	for p in n:
		if head_cand_ok(p):
			cands.append(p)
	var s1: Array[float] = []
	if sham:
		var base := sham_shares(national_shares(true))
		var tot := 0.0
		for p in n:
			if p in cands:
				tot += base[p]
		for p in n:
			s1.append(base[p] / tot if p in cands else 0.0)
	else:
		s1 = au_fraud_shares(national_shares(true, cands))
	var order: Array = cands.duplicate()
	order.sort_custom(func(a, b): return s1[a] > s1[b])
	# 0.58: в Северной Македонии победа в 1-м туре требует большинства зарегистрированных избирателей, а не голосов
	var need1 := 0.5
	if bool(ELEC.get("round1_reg", false)):
		need1 = 0.5 / clampf(float(ELEC.get("turn", 0.55)), 0.3, 1.0)
	var runoff: bool = float(s1[order[0]]) <= need1
	var winner: int = order[0]
	var rounds: Array = []
	var rows1: Array = []
	for i in mini(5, order.size()):
		var p: int = order[i]
		if runoff:
			rows1.append(head_row(p, s1[p], false, i >= 2, "во 2-й тур" if i < 2 else "выбыл"))
		else:
			rows1.append(head_row(p, s1[p], i == 0, false, ""))
	rounds.append({"title": "1-й тур · кандидатов: %d" % cands.size(), "need": need1, "need_text": "для победы нужно больше 50%" if need1 <= 0.5 else "для победы нужно больше половины зарегистрированных избирателей", "rows": rows1})
	var logt := "Первый тур: " + "; ".join(PackedStringArray([
		"%s %.1f%%" % [PARTY_NAMES[order[0]], s1[order[0]] * 100.0], "%s %.1f%%" % [PARTY_NAMES[order[1]], s1[order[1]] * 100.0]]))
	if runoff:
		var a: int = order[0]
		var b: int = order[1]
		var s2 := national_shares(true, [a, b])
		# 0.58: голоса выбывших переходят по близости позиций, а не сжимаются на 40 %; «кордон» (партии, с которыми не идут в коалиции)
		# теряет во 2-м туре около 8 п.п.: остальные избиратели объединяются против него (Франция 2002 и 2017, Румыния 2024, Польша)
		var ma: float = 0.5 + (s2[a] - 0.5) * 0.85
		if not sham:
			if is_cordon(a) and not is_cordon(b):
				ma -= 0.08
			elif is_cordon(b) and not is_cordon(a):
				ma += 0.08
		ma = clampf(ma, 0.02, 0.98)
		s2[a] = ma
		s2[b] = 1.0 - ma
		winner = a if s2[a] > s2[b] else b
		rounds.append({"title": "2-й тур", "need": 0.5, "need_text": "побеждает набравший больше половины", "rows": [
			head_row(a, s2[a], winner == a, false, ""), head_row(b, s2[b], winner == b, false, "")]})
		logt += ". Второй тур: %.1f%% против %.1f%%" % [s2[a] * 100.0, s2[b] * 100.0]
	var out: Array = head_outcome(winner)
	# v35: сравнение с прошлыми выборами главы государства (1-й тур)
	if prev_head.size() == n:
		var cmp: PackedStringArray = []
		for i in mini(5, order.size()):
			var p: int = order[i]
			cmp.append("%s %s п.п." % [head_cand_name(p), sg((float(s1[p]) - float(prev_head[p])) * 100.0, 1)])
		out[2] = String(out[2]) + "\n[color=%s]К прошлым выборам (1-й тур): %s.[/color]" % [COL_DIM, "; ".join(cmp)]
		logt += ". К прошлым выборам: " + "; ".join(cmp)
	prev_head = []
	for p in n:
		prev_head.append(float(s1[p]))
	var rep := {"title": "ВЫБОРЫ " + String(ELEC["title"]).to_upper() if not sham else "ВЫБОРЫ БЕЗ ВЫБОРА", "reason": reason, "rounds": rounds, "sham": sham,
		"meta": "Прямое голосование, два тура: во второй выходят двое лучших. Срок полномочий — %d лет. Следующие выборы — %s." % [head_term_months() / 12, turn_date(turn + head_term_months())],
		"vtitle": out[0], "vcol": out[1], "vtext": out[2], "end": "", "log": logt + ". Победил: %s." % head_cand_name(winner)}
	head_present(rep)


func hold_head_indirect(reason: String) -> void:
	var n: int = PARTY_NAMES.size()
	var sham: bool = decree_power()
	var tot_s := 0
	for p in n:
		tot_s += seats[p]
	tot_s = maxi(tot_s, 1)
	var camp: Array = []
	var best := [-1, -1, -1]
	var bs := [-1, -1, -1]
	for p in n:
		var c := 1
		if p == 0 or in_coalition[p]:
			c = 0
		elif String(PARCH[p]) in ["popr", "none"]:
			c = 2
		camp.append(c)
		if head_cand_ok(p) and seats[p] > bs[c]:
			bs[c] = seats[p]
			best[c] = p
	var vf := [0.0, 0.0, 0.0]
	for p in n:
		vf[camp[p]] += float(seats[p]) / float(tot_s)
	if best[1] < 0:
		best[1] = best[2]
		vf[1] += vf[2]
		vf[2] = 0.0
	if best[2] < 0:
		vf[1] += vf[2]
		vf[2] = 0.0
	if best[1] < 0:
		for p in range(1, n):
			if head_cand_ok(p) and (best[1] < 0 or seats[p] > seats[best[1]]):
				best[1] = p
	var electors: int = int(round(float(SEATS) * float(ELEC["ele_x"]) + float(ELEC["ele_add"])))
	var need: Array = ELEC["need"]
	var secret: float = float(ELEC.get("secret", 0.04))
	var all_rounds: Array = []
	var winner := -1
	for r in need.size():
		var nr: float = float(need[r])
		var d: float = 0.0 if sham else secret * randf_range(0.3, 1.5)
		var shift: float = minf(vf[1], pres_camp * 0.6)
		var va: float = vf[0] * (1.0 - d) + shift
		var vb: float = vf[1] + vf[0] * d * 0.8 - shift
		var vc: float = vf[2]
		var vals := [va, vb, vc]
		var rows: Array = []
		var top := 0
		for k in 3:
			if k < 2 or best[k] >= 0:
				if float(vals[k]) > float(vals[top]):
					top = k
		var hit := -1
		if nr > 0.0:
			for k in 3:
				if best[k] >= 0 and float(vals[k]) >= nr:
					hit = k
		else:
			hit = top
		for k in 3:
			if best[k] >= 0 and (k < 2 or float(vals[k]) > 0.005):
				var cnt: int = int(round(float(vals[k]) * float(electors)))
				rows.append(head_row(best[k], vals[k], k == hit, false, ""))
				(rows[rows.size() - 1] as Dictionary)["lab"] = "%.1f%%" % (float(vals[k]) * 100.0)
				(rows[rows.size() - 1] as Dictionary)["note"] = "%d голосов" % cnt
		rows.sort_custom(func(a, b): return float(a["val"]) > float(b["val"]))
		var nt := "нужно %.0f%% голосов" % (nr * 100.0) if nr > 0.0 else "достаточно большинства из поданных"
		all_rounds.append({"title": "%d-й тур голосования" % (r + 1), "need": nr, "need_text": nt, "rows": rows})
		if hit >= 0:
			winner = best[hit]
			break
	if winner < 0:
		winner = best[0] if best[0] >= 0 else 0
	var skipped := 0
	var rounds: Array = all_rounds
	if all_rounds.size() > 3:
		skipped = all_rounds.size() - 3
		rounds = all_rounds.slice(all_rounds.size() - 3)
	var out: Array = head_outcome(winner)
	var meta := "Голосуют %d выборщиков: %s. " % [electors, String(ELEC["body"])]
	if skipped > 0:
		meta += "Первые %d тура(ов) никто не набрал нужного большинства. " % skipped
	meta += "Срок — %d лет. Следующие выборы — %s." % [head_term_months() / 12, turn_date(turn + head_term_months())]
	var rep := {"title": "ВЫБОРЫ " + String(ELEC["title"]).to_upper() if not sham else "ВЫБОРЫ БЕЗ ВЫБОРА", "reason": reason, "rounds": rounds, "sham": sham,
		"meta": meta, "vtitle": out[0], "vcol": out[1], "vtext": out[2], "end": "",
		"log": "%s избран в %d-м туре голосования выборщиков." % [head_cand_name(winner), all_rounds.size()]}
	head_present(rep)


func hold_head_council(reason: String) -> void:
	var n: int = PARTY_NAMES.size()
	var cn: int = int(ELEC.get("council_n", 7))
	var got: Array = []
	for p in n:
		got.append(0)
	var tot_s := 0
	for p in n:
		tot_s += seats[p]
	for k in cn:
		var bp := -1
		var bq := 0.0
		for p in n:
			if float(seats[p]) < float(tot_s) * 0.05:
				continue
			var q: float = float(seats[p]) / (float(got[p]) + 1.0)
			if q > bq:
				bq = q
				bp = p
		if bp >= 0:
			got[bp] += 1
	var rows: Array = []
	for p in n:
		if got[p] > 0:
			var rw := head_row(p, float(got[p]) / float(cn), false, false, "")
			rw["name"] = "Ваша партия" if p == 0 else String(PARTY_NAMES[p]).split(" (")[0]
			rw["sub"] = "кандидатов: %d" % got[p]
			rw["lab"] = "%d из %d" % [got[p], cn]
			rw["win"] = p == 0
			rw["note"] = ""
			rows.append(rw)
	rows.sort_custom(func(a, b): return float(a["val"]) > float(b["val"]))
	var rounds: Array = [{"title": "Места в Федеральном совете (%d)" % cn, "need": 0.0, "need_text": "делятся между сильнейшими партиями «волшебной формулой»", "rows": rows}]
	var end_msg := ""
	var vt := ""
	var vc: Color = C_GOOD
	var vtx := ""
	var members: Array = []
	var pm := -1
	for p in n:
		if got[p] > 0 and p != 0:
			members.append(p)
			if pm < 0 or got[p] > got[pm] or (got[p] == got[pm] and seats[p] > seats[pm]):
				pm = p
	if got[0] >= 1:
		vt = "Вы сохранили место в правительстве" if not opp_mode else "Вы снова в правительстве"
		capital = minf(100.0, capital + 5.0)
		vtx = "Федеральное собрание подтвердило состав Федерального совета: у вашей партии %d из %d мест. Политкапитал +5." % [got[0], cn]
		if opp_mode:
			opp_to_gov(members, 0, "Федеральное собрание избрало представителей вашей партии в Федеральный совет.")
	else:
		# v36: без места в Федеральном совете партия остаётся в парламенте — игра продолжается в оппозиции
		vt = "Вас не переизбрали"
		vc = C_BAD
		vtx = "Федеральное собрание не переизбрало вас в Федеральный совет: ваша партия осталась без мест в правительстве, но сохраняет %d мест в парламенте. Игра продолжается в оппозиции: критикуйте власть, вносите законопроекты и добивайтесь места в совете на следующих выборах." % seats[0]
		if not opp_mode and pm > 0:
			in_coalition[0] = false
			opp_enter("Федеральное собрание не переизбрало вас в Федеральный совет.", {"members": members, "pm": pm, "seats": 0, "ok": true, "stab": 70.0})
			opp_gov["seats"] = opp_gov_seats()
		elif pm <= 0:
			end_msg = "Федеральное собрание не переизбрало вас в Федеральный совет, а другого состава совета собрать не удалось."
			vtx = end_msg
	var out_t := "Новый состав Федерального совета: " + ", ".join(PackedStringArray(rows.map(func(r): return "%s — %s" % [r["name"], r["lab"]])))
	var rep := {"title": "ВЫБОРЫ ФЕДЕРАЛЬНОГО СОВЕТА", "reason": reason, "rounds": rounds, "sham": false,
		"meta": "Новый парламент избирает всех семерых членов правительства. Президент Конфедерации — выборная должность на один год, глава правительства лишь первый среди равных.",
		"vtitle": vt, "vcol": vc, "vtext": vtx, "end": end_msg, "log": out_t}
	head_present(rep)


func head_campaign_check() -> void:
	var kind: String = String(ELEC.get("head", "none"))
	if kind != "direct" and kind != "indirect":
		return
	if game_over or election_open or not current_event.is_empty() or decree_power():
		return
	if pres_due < 0 or turn < pres_due - 2 or turn >= pres_due or pres_camp_done == pres_due:
		return
	pres_camp_done = pres_due
	var tt: String = String(ELEC["title"])
	var txt := ""
	var opts: Array = []
	if kind == "direct":
		var sh := national_shares(true)
		var rival := 1
		for p in range(1, PARTY_NAMES.size()):
			if head_cand_ok(p) and sh[p] > sh[rival]:
				rival = p
		txt = "Через два месяца — выборы %s (%s). Ваш лагерь может получить союзника на этом посту или оппонента. По опросам главный соперник вашего кандидата — %s («%s», %.1f%%). Как поддержать кандидата?" % [
			tt, turn_date(pres_due), head_cand_name(rival), PARTY_NAMES[rival], sh[rival] * 100.0]
		opts = [
			{"l": "Выдвинуть яркого лидера вашей партии (капитал -4)", "fx": {"capital": -4.0, "pcamp": 0.06}},
			{"l": "Единый кандидат широкой коалиции (капитал -3)", "fx": {"capital": -3.0, "pcamp": 0.04, "coal_sat": 4.0}},
			{"l": "Бросить на кампанию бюджетные ресурсы (долг +0.4% ВВП)", "fx": {"debt": 0.4, "pcamp": 0.07, "support": {"Пенсионеры": 2.0, "Бюджетники": 2.0}}},
			{"l": "Не вмешиваться (капитал +2)", "fx": {"capital": 2.0}},
		]
	else:
		txt = "Через два месяца %s выберут %s. Голосование тайное: часть выборщиков вашей коалиции может проголосовать против. Что предпринять?" % [String(ELEC["body"]), tt]
		opts = [
			{"l": "Выдвинуть собственного кандидата и дисциплинировать выборщиков (капитал -4)", "fx": {"capital": -4.0, "pcamp": 0.05}},
			{"l": "Искать общего кандидата с оппозицией (довольство партнёров -4)", "fx": {"coal_sat": -4.0, "pcamp": 0.03, "all": 0.5}},
			{"l": "Закулисные договорённости: посты и обещания (долг +0.3% ВВП)", "fx": {"debt": 0.3, "pcamp": 0.08, "capital": -3.0}},
			{"l": "Не вмешиваться (капитал +2)", "fx": {"capital": 2.0}},
		]
	current_event = {"t": txt, "kind": "pcampaign", "o": opts}
	event_region = -1
	event_party = -1
	event_min = -1
	present_event()


# 0.58: в Норвегии, Боснии и Герцеговине и Швейцарии парламент нельзя распустить досрочно: при потере доверия или отставке
# правительство меняется без выборов (Норвегия, Босния), а Федеральный совет Швейцарии вообще не уходит в отставку.
func dissolve_blocked(reason: String) -> bool:
	var r: Array = SNAP_RULES.get(ccode, [])
	if r.is_empty() or float(r[2]) >= 0.0:
		return false
	return not (reason in ["плановые выборы", "роспуск парламента режимом", "выборы после мирного соглашения", "досрочные выборы после массовых протестов"])


func no_dissolution_outcome(reason: String) -> void:
	crisis_months = 0
	crisis_offered = false
	deadlock = 0
	if ccode == "CH" or opp_mode:
		log_line("[color=%s]Парламент не распускается: %s. Правительство продолжает работать.[/color]" % [COL_WARN, String(SNAP_RULES[ccode][1]).to_lower() if ccode == "CH" else "досрочных выборов здесь нет"])
		return
	var alt := ai_form_gov(false)
	if not alt.is_empty() and bool(alt["ok"]):
		in_coalition[0] = false
		log_line("[color=%s][b]Досрочных выборов не будет:[/b] парламент нельзя распустить, и другие партии сформировали правительство без выборов.[/color]" % COL_BAD)
		opp_enter("Парламент нельзя распустить досрочно: большинство собрало новое правительство без выборов.")
	else:
		minority_gov = true
		log_line("[color=%s][b]Досрочных выборов не будет:[/b] парламент нельзя распустить, правительство продолжает работу как правительство меньшинства.[/color]" % COL_WARN)
	refresh()


func hold_parliament(reason: String) -> void:
	if martial_blocks(reason):
		return
	if dissolve_blocked(reason):
		no_dissolution_outcome(reason)
		return
	ag_exact = true
	hold_parliament_core(reason)
	ag_exit_report(false, -1)
	ag_exact = false


func hold_parliament_core(reason: String) -> void:
	var old_seats: Array = seats.duplicate()
	# 0.58: Швеция — внеочередные выборы не сдвигают четырёхлетний цикл: очередные остаются в сентябре по календарю
	if not (bool(MACRO.get("fixed_cycle", false)) and reason != "плановые выборы" and turn - last_parl < parl_term() - 1):
		last_parl = turn
	if String(ELEC.get("head", "")) == "council":
		pres_due = turn + 2
	crisis_months = 0
	crisis_offered = false
	coal_talks = false
	minority_gov = false
	techno_until = -1
	pm_lead = false
	coal_deal.clear()   # 0.56: после выборов прежнее коалиционное соглашение теряет силу
	cn_draft.clear()
	cn_pat.clear()
	cn_out.clear()
	extra_mins.clear()
	impeach_warned = false
	warned.clear()
	commitments.clear()
	var thr: float = mods["threshold"]
	var raw := national_shares(false)
	var shares := parl_shares()
	var sham := decree_power()
	if sham:
		shares = sham_shares(shares)
		reason = "выборы без выбора"
	elif au_on():
		shares = au_fraud_shares(shares)
	var prev: Array = prev_vote
	if prev.size() != PARTY_NAMES.size():
		prev = []
		var ot := 0
		for x in old_seats:
			ot += int(x)
		for p in PARTY_NAMES.size():
			prev.append(float(old_seats[p]) / float(maxi(1, ot)) if p < old_seats.size() else 0.0)
	seats = allocate_seats(shares)
	log_header("ПАРЛАМЕНТСКИЕ ВЫБОРЫ — %s (%s)" % [date_text(), reason], COL_ELECT)
	log_line("Система: %s%s, %d мест." % [low1(String(ELEC.get("sys", "пропорциональная"))), (", барьер %.0f%%" % (thr * 100.0)) if thr >= 0.005 else "", SEATS])
	if not sham:
		au_after_election()
	var parts: PackedStringArray = []
	for p in sorted_parties(shares):
		if seats[p] > 0:
			parts.append("%s %.1f%% (%d мест)" % [PARTY_NAMES[p], shares[p] * 100.0, seats[p]])
	log_line("  " + "; ".join(parts))
	# v35: сравнение с прошлыми выборами
	var cmp: PackedStringArray = []
	for p in sorted_parties(shares):
		var dpp: float = (float(shares[p]) - (float(prev[p]) if p < prev.size() else 0.0)) * 100.0
		var dse: int = int(seats[p]) - (int(old_seats[p]) if p < old_seats.size() else 0)
		if absf(dpp) >= 0.05 or dse != 0:
			cmp.append("%s %s п.п., %s мест" % [PARTY_NAMES[p], sg(dpp, 1), ("%+d" % dse) if dse != 0 else "±0"])
	if cmp.size() > 0:
		log_line("[color=%s]  К прошлым выборам:[/color] %s." % [COL_DIM, "; ".join(cmp)])
	var upr := upper_renew(shares)
	if upr != "":
		log_line("  " + upr)
	if comp_loss > 0.015:
		log_line("[color=%s]Конкуренция:[/color] оппозиция консолидировалась и голосовала тактически — партия власти недобрала около %.0f п.п. (индекс демократии %.0f%%)." % [COL_DIM, comp_loss * 100.0, democracy_index() * 100.0])
	# победы в регионах
	var won := 0
	var best_r := -1
	var worst_r := -1
	var best_v := -1.0
	var worst_v := 2.0
	for ri in regions.size():
		var rs := region_shares(ri, false)
		var lead := 0
		for p in rs.size():
			if rs[p] > rs[lead]:
				lead = p
		if lead == 0:
			won += 1
		if rs[0] > best_v:
			best_v = rs[0]
			best_r = ri
		if rs[0] < worst_v:
			worst_v = rs[0]
			worst_r = ri
	for p in range(1, PARTY_NAMES.size()):
		in_coalition[p] = false
	satis.clear()
	conc.clear()
	joined.clear()
	var state := "gov"
	var end_msg := ""
	var opp_msg := ""
	if opp_mode:
		state = opp_after_election()
		if state == "gov":
			capital = minf(100.0, capital + 8.0)
			log_line("[color=%s][b]Вы пришли к власти.[/b] Коалиция: %s.[/color]" % [COL_GOOD, coalition_names()])
		else:
			opp_msg = "Правительство: %s. Вы остаётесь в оппозиции: %d мест из %d." % [opp_gov_text(), seats[0], SEATS]
			log_line("[color=%s]%s[/color]" % [COL_WARN, opp_msg])
	elif coal_manual() and not gov_ok() and coal_feasible():
		# v53: коалицию собирает игрок — переговоры вместо автоматического «приглашения» партнёров
		state = "talks"
		coal_talks_start()
	elif form_government(true):
		deadlock = 0
		# v35: новый мандат — после выборов у правительства есть капитал на первые шаги
		capital = minf(100.0, maxf(capital, 30.0) + 8.0)
		log_line("[color=%s][b]Правительство сформировано:[/b] %d мест из %d. Коалиция: %s.[/color]" % [COL_GOOD, gov_seats(), SEATS, coalition_names()])
	else:
		var alt := ai_form_gov(false)
		if not alt.is_empty() and bool(alt["ok"]) and seats[0] < int(seats[int(alt["pm"])]):
			in_coalition[0] = false
			opp_enter("После выборов другие партии собрали большинство и сформировали правительство без вас.")
			opp_msg = "Правительство: %s. Вы в оппозиции: %d мест из %d." % [opp_gov_text(), seats[0], SEATS]
			state = "opp"
		else:
			crisis_months = 1
			state = "crisis"
			capital = maxf(capital, 30.0)   # v35: капитал на переговоры о коалиции
			log_line("[color=%s][b]Правительственный кризис![/b] В вашей коалиции %d мест из %d. У вас %d месяцев, чтобы найти партнёров, иначе будут назначены новые выборы.[/color]" % [COL_BAD, gov_seats(), SEATS, crisis_limit()])
	gov_born = turn   # 0.58: начинается «медовый месяц» нового правительства
	prev_raw = raw.duplicate()   # 0.56: от этих выборов считается предел сдвига до следующих
	var rep := {"reason": reason, "shares": shares, "raw": raw, "prev": prev, "old_seats": old_seats, "thr": thr, "sham": sham, "state": state,
		"end": end_msg, "opp": opp_msg, "won": won, "best": best_r, "worst": worst_r}
	prev_vote = shares.duplicate()
	show_election(rep)
	if state != "lost":
		refresh()


func election_title() -> String:
	return ("Выборы " + tm("parl_in")).to_upper()


# ---------- предвыборная кампания ----------
func campaign_check() -> void:
	if game_over or election_open or not current_event.is_empty() or decree_power():
		return
	if turn - last_parl != parl_term() - 2 or camp_turn == turn:
		return
	camp_turn = turn
	if opp_mode:
		opp_campaign()
		return
	var sh := national_shares(false)
	var rival := 1
	for p in range(1, PARTY_NAMES.size()):
		if sh[p] > sh[rival]:
			rival = p
	var txt := "До выборов %s осталось два месяца. По опросам ваша партия получает %.1f%%, главный соперник — «%s» (%.1f%%). Как вести кампанию?" % [
		tm("parl_g"), sh[0] * 100.0, PARTY_NAMES[rival], sh[rival] * 100.0]
	current_event = {"t": txt, "kind": "campaign", "o": [
		{"l": "Щедрые обещания: пенсии, зарплаты, льготы (долг +0.6% ВВП)", "fx": {"debt": 0.6, "support": {"Пенсионеры": 3.0, "Бюджетники": 3.0, "Рабочие": 2.0, "Бизнес": -2.0}}},
		{"l": "Ставка на экономику и стабильность (капитал -3)", "fx": {"capital": -3.0, "support": {"Бизнес": 3.0, "Силовики": 2.0, "Пенсионеры": 1.0}}},
		{"l": "Агитация за молодёжь и перемены (капитал -3)", "fx": {"capital": -3.0, "support": {"Молодёжь": 4.0, "Экологи": 2.0, "Силовики": -1.0}}},
		{"l": "Массовые встречи и тур по регионам (капитал -4)", "fx": {"capital": -4.0, "all": 1.5, "regall": {"loyalty": 2.0}}},
		]}
	event_region = -1
	event_party = -1
	event_min = -1
	present_event()


# ============================================================
#  ПАРТИИ, КОАЛИЦИИ
# ============================================================


func party_attitude(p: int) -> float:
	var num := 0.0
	var den := 0.0
	for g in GROUPS:
		var w: float = float(LEAN[g][p]) * float(GROUP_WEIGHT[g])
		num += w * float(support[g])
		den += w
	var att: float = num / den
	if p == REGIONAL_P:
		att = 0.5 * att + 0.5 * reg_avg("loy")
	elif p == PROTEST_P:
		att *= 0.7
	return att


func electorate_text(p: int) -> String:
	if p == 0:
		return "Партия власти."
	var arr: Array = []
	for g in GROUPS:
		arr.append([float(LEAN[g][p]) * float(GROUP_WEIGHT[g]), g])
	arr.sort_custom(func(a, c): return a[0] > c[0])
	return "Электорат: %s, %s, %s" % [arr[0][1], arr[1][1], arr[2][1]]


func national_shares(pres: bool, only: Array = []) -> Array[float]:
	var out: Array[float] = []
	for p in PARTY_NAMES.size():
		out.append(0.0)
	for ri in regions.size():
		var rs := region_shares(ri, pres, only)
		for p in out.size():
			out[p] += pop_w[ri] * rs[p]
	if only.is_empty():
		out = apply_competition(out, pres)
		if not pres:
			out = er_apply(out)
		return out
	return out


# ============================================================
#  КОАЛИЦИЯ: требования, министерства, довольство, вотум недоверия
# ============================================================


func democracy_index() -> float:
	return clampf(minf(DEM_BASE, float(MIL_DEMO.get(ccode, DEM_BASE))) + float(mods.get("dem_shift", 0.0)), 0.0, 1.0)


func democracy_name(d: float) -> String:
	if d < 0.20:
		return "авторитарный режим"
	if d < 0.40:
		return "гибридный режим"
	if d < 0.60:
		return "ограниченная демократия"
	if d < 0.80:
		return "устойчивая демократия"
	return "либеральная демократия"


func apply_competition(sh: Array[float], pres: bool) -> Array[float]:
	var d := democracy_index()
	var s0: float = sh[0]
	var years: float = float(turn) / 12.0
	var fat: float = clampf((years - 3.0) * 0.012, 0.0, 0.12) * d
	var cap: float = lerpf(0.55, 0.36, d) + (0.05 if pres else 0.0)
	var keep: float = pow(1.0 - d, 1.5)
	var t: float = s0 * (1.0 - fat)
	if t > cap and d < ER_DEM:
		t = cap + (t - cap) * keep
	var excess: float = s0 - t
	comp_loss = maxf(0.0, excess)
	if excess <= 0.0005:
		return sh
	var wsum := 0.0
	for p in range(1, sh.size()):
		wsum += pow(maxf(sh[p], 0.0001), 1.4)
	var out: Array[float] = []
	out.append(t)
	for p in range(1, sh.size()):
		out.append(sh[p] + excess * pow(maxf(sh[p], 0.0001), 1.4) / wsum)
	return out


func democracy_text() -> String:
	var d := democracy_index()
	var col := COL_GOOD if d >= 0.6 else (COL_WARN if d >= 0.4 else COL_BAD)
	var t := "\n[b]Политическая система[/b]\nИндекс демократии: [b][color=%s]%.0f%%[/color][/b] — %s.\n" % [col, d * 100.0, democracy_name(d)]
	var cap: float = lerpf(0.55, 0.36, d)
	var keep: float = pow(1.0 - d, 1.5)
	if keep < 0.95:
		t += "[color=%s]Конкуренция: выше ≈%.0f%% голосов партии власти трудно набрать — оппозиция консолидируется. Чем свободнее СМИ, суды и митинги, тем жёстче потолок.[/color]" % [COL_DIM, cap * 100.0]
	else:
		t += "[color=%s]Конкуренция слабая: ограничений на рост партии власти почти нет.[/color]" % COL_DIM
	return t + radical_text()


func sham_shares(raw: Array[float]) -> Array[float]:
	var s0: float = maxf(0.82, raw[0])
	var rest := 0.0
	for p in range(1, raw.size()):
		rest += raw[p]
	var out: Array[float] = []
	out.append(s0)
	for p in range(1, raw.size()):
		var w: float = raw[p] / rest if rest > 0.0 else 0.0
		if p == PROTEST_P:
			w *= 0.1
		out.append((1.0 - s0) * w)
	var tot := 0.0
	for x in out:
		tot += x
	for i in out.size():
		out[i] = out[i] / tot
	return out


# ============================================================
#  0.56 (доп. 6/9): РЕАЛИЗМ ВЫБОРОВ — МЯГКИЙ ПОТОЛОК ПАРТИИ И ПРЕДЕЛ СДВИГА ЗА ВЫБОРЫ
#  Потолок: обычно 35%, в демократии не выше 60%; свой у каждой страны и партии (система, число партий, кризис,
#  война, харизма, культурное напряжение, новая протестная волна; вниз — низкий барьер, раздробленность,
#  усталость от власти, регионализм, «санитарный кордон»). Мягкий: чем ближе, тем труднее расти.
#  Сдвиг от прошлых выборов: обычно до 10 п.п., при потрясениях до 30 п.п. (тоже мягко, через tanh).
#  В автократиях (индекс демократии ниже ER_DEM) не действует: там работают конкуренция и подтасовки.
# ============================================================
const ER_DEM := 0.5
const ER_CAP0 := 0.35
const ER_CAP_MAX := 0.60
const ER_SWING0 := 0.10
const ER_SWING_MAX := 0.30
# страны с низкой верностью избирателей (молодые партийные системы, частые новые партии)
const ER_VOLATILE := ["GB", "FR", "NL", "ES", "PL", "CZ", "SK", "SI", "HU", "HR", "RS", "BA", "ME", "MK", "AL", "XK", "BG", "RO", "EE", "LV", "LT", "MD", "UA", "GR", "IT"]


func er_on() -> bool:
	return democracy_index() >= ER_DEM


func er_crisis() -> float:
	return clampf(-growth / 3.0 + (unemployment - 8.0) / 8.0 + maxf(0.0, inflation - 6.0) / 10.0, 0.0, 1.0)


func er_gov(p: int) -> bool:
	if opp_mode:
		return (opp_gov.get("members", []) as Array).has(p)
	return p == 0 or (p < in_coalition.size() and in_coalition[p])


func er_gov_years(p: int) -> float:
	if not er_gov(p):
		return 0.0
	if opp_mode:
		return float(turn - int(opp_gov.get("since", 0))) / 12.0
	if p == 0:
		return float(turn) / 12.0 + 2.0
	return float(turn - int(joined.get(p, 0))) / 12.0


# 0.56: архетип партии по исходному номеру (при игре за другую партию слоты 0 и player_orig поменяны местами, PARCH — нет)
func er_arch(p: int) -> String:
	var o: int = swap_idx(p, player_orig)
	return String(PARCH[o]) if o >= 0 and o < PARCH.size() else ""


func er_populist(p: int) -> bool:
	return p == PROTEST_P or er_arch(p) in ["popr", "popl"]


# 0.56: правые популисты растут вместе с миграционным и культурным напряжением региона (cut − cut0), протестная партия — вдвое слабее
func er_mig_mult(ri: int, p: int) -> float:
	var k := 0.0
	if er_arch(p) == "popr":
		k = 0.014
	elif p == PROTEST_P:
		k = 0.007
	if k == 0.0:
		return 1.0
	var r: Dictionary = regions[ri]
	return clampf(1.0 + k * (float(r.get("cut", 0.0)) - float(r.get("cut0", 0.0))), 0.8, 1.7)


func er_neff(sh: Array) -> float:
	var s2 := 0.0
	for x in sh:
		s2 += float(x) * float(x)
	return 1.0 / maxf(0.0001, s2)


# потолок партии p: [доля, причины]
func er_ceiling(p: int, sh: Array) -> Array:
	var c := ER_CAP0
	var why: PackedStringArray = []
	var smd: float = smd_frac()
	if smd > 0.3:
		c += 0.10 * smd
		why.append("мажоритарная система +%.0f" % (10.0 * smd))
	elif float(mods["threshold"]) < 0.03:
		c -= 0.04
		why.append("пропорциональная система с низким барьером −4")
	var n := er_neff(sh)
	if n < 3.5:
		c += minf(0.08, (3.5 - n) * 0.04)
		why.append("мало крупных партий +%.0f" % (minf(0.08, (3.5 - n) * 0.04) * 100.0))
	elif n > 6.0:
		c -= minf(0.04, (n - 6.0) * 0.01)
		why.append("раздробленный парламент −%.0f" % (minf(0.04, (n - 6.0) * 0.01) * 100.0))
	var cr := er_crisis()
	if cr > 0.15 and not er_gov(p):
		c += 0.07 * cr
		why.append("экономический кризис +%.0f" % (7.0 * cr))
	if mil_at_war():
		if er_gov(p):
			c += 0.06
			why.append("война: сплочение вокруг власти +6")
		else:
			c += 0.02
			why.append("война и угроза +2")
	if p < charisma.size() and float(charisma[p]) > 1.05:
		c += minf(0.05, (float(charisma[p]) - 1.0) * 0.25)
		why.append("харизма лидера +%.0f" % (minf(0.05, (float(charisma[p]) - 1.0) * 0.25) * 100.0))
	var ten: float = clampf(cu_nat_tension() / 60.0, 0.0, 1.0)
	if ten > 0.15:
		if er_populist(p):
			c += 0.06 * ten
			why.append("миграционное и культурное напряжение +%.0f" % (6.0 * ten))
		else:
			c -= 0.02 * ten
			why.append("поляризация общества −%.0f" % (2.0 * ten))
	if p < prev_raw.size() and float(prev_raw[p]) < 0.05 and er_populist(p) and cr > 0.3:
		c += 0.04
		why.append("новая партия на волне протеста +4")
	# развал соперника: крупнейшая другая партия потеряла с прошлых выборов 5+ п.п.
	if prev_raw.size() == sh.size():
		for q in sh.size():
			if q != p and float(prev_raw[q]) >= 0.15 and float(prev_raw[q]) - float(sh[q]) >= 0.05:
				c += 0.03
				why.append("развал крупного соперника +3")
				break
	var gy := er_gov_years(p)
	if gy > 4.0:
		c -= minf(0.05, (gy - 4.0) * 0.01)
		why.append("усталость от власти −%.0f" % (minf(0.05, (gy - 4.0) * 0.01) * 100.0))
	if p != REGIONAL_P and REGIONAL_P < sh.size() and float(sh[REGIONAL_P]) >= 0.05:
		c -= 0.03
		why.append("сильные региональные партии −3")
	if is_cordon(p):
		c -= 0.03
		why.append("«санитарный кордон» −3")
	# партия, уже набирающая много голосов, имеет запас роста над текущим результатом (избиратели привыкли за неё голосовать)
	if p < prev_raw.size() and float(prev_raw[p]) > c:
		c = float(prev_raw[p])
		why.append("большая устойчивая база: потолок не ниже результата прошлых выборов")
	return [clampf(c, 0.20, ER_CAP_MAX), why]


# предел сдвига партии p от прошлых выборов: [доля, причины]
func er_swing(p: int) -> Array:
	var m := ER_SWING0
	var why: PackedStringArray = []
	if ER_VOLATILE.has(ccode):
		m += 0.04
		why.append("избиратели в стране мало верны партиям +4")
	var vo: float = float(game_opts.get("volat", 1.0))
	if absf(vo - 1.0) > 0.01:
		m *= clampf(vo, 0.5, 2.0)
		why.append("настройка «изменчивость» ×%.1f" % vo)
	var cr := er_crisis()
	if cr > 0.15:
		m += 0.08 * cr
		why.append("кризис +%.0f" % (8.0 * cr))
	if mil_at_war():
		m += 0.05
		why.append("война +5")
	if pact_has(p, "scandal") or ai_pen.has(p):
		m += 0.04
		why.append("скандал или атаки +4")
	if p < prev_raw.size() and float(prev_raw[p]) < 0.03:
		m += 0.06
		why.append("новая партия +6")
	elif p < prev_raw.size() and float(prev_raw[p]) < 0.08:
		m += 0.02
		why.append("слабая связь с избирателями +2")
	if pact_has(p, "attack") or pact_has(p, "praise") or pact_has(p, "bloc"):
		m += 0.03
		why.append("кампания, похвала или атака +3")
	return [clampf(m, 0.06, ER_SWING_MAX), why]


func er_apply(sh: Array[float]) -> Array[float]:
	if not er_on() or sh.size() < 2:
		return sh
	if prev_raw.size() != sh.size():
		# старт игры: стартовые расклады — реальные опросы, их не трогаем; от них считаются предел сдвига и потолок
		prev_raw = sh.duplicate()
		return sh
	var out: Array[float] = []
	var fixed: Array[bool] = []
	for p in sh.size():
		var v: float = sh[p]
		var moved := false
		if p != 6:
			var m: float = float(er_swing(p)[0])
			var d: float = v - float(prev_raw[p])
			if absf(d) > m * 0.5:
				v = maxf(0.0, float(prev_raw[p]) + m * tanh(d / m))
				moved = true
			var c: float = float(er_ceiling(p, sh)[0])
			# мягкий потолок: выше 0,8 c рост затухает; уже набранное на прошлых выборах не режется, а выше потолка расти нельзя
			var pv: float = float(prev_raw[p])
			var hi: float = maxf(c, pv)
			var a: float = minf(hi, maxf(0.8 * c, pv))
			if v > a:
				v = a + (hi - a) * (1.0 - exp(-(v - a) / maxf(0.0001, hi - a))) if hi - a > 0.002 else a
				moved = true
		out.append(v)
		fixed.append(moved)
	# остаток раздаём «свободным» партиям пропорционально их доле (сжатые не трогаем, чтобы не вылезли за предел)
	var tot := 0.0
	var free_w := 0.0
	for p in out.size():
		tot += out[p]
		if not fixed[p]:
			free_w += out[p]
	var res: float = 1.0 - tot
	for p in out.size():
		if free_w > 0.02:
			if not fixed[p]:
				out[p] = maxf(0.0, out[p] + res * out[p] / free_w)
		else:
			out[p] = out[p] / maxf(0.0001, tot)
	return out


# подсказка к рейтингу партии: почему у неё такой потолок и сдвиг
func er_tip(p: int) -> String:
	if not er_on():
		return "Режим не вполне демократический: потолка и предела сдвига нет, работают конкуренция и административный ресурс."
	var sh := national_shares(false)
	var ce := er_ceiling(p, sh)
	var sw := er_swing(p)
	var t := "Потолок партии: ≈%.0f%% (обычно 35%%, в демократии не выше 60%%; чем ближе к нему, тем труднее расти)" % (float(ce[0]) * 100.0)
	if not (ce[1] as PackedStringArray).is_empty():
		t += "\n  " + "\n  ".join(ce[1] as PackedStringArray)
	var pv: float = float(prev_raw[p]) * 100.0 if p < prev_raw.size() else 0.0
	t += "\nСдвиг с прошлых выборов (%.1f%%): до ±%.0f п.п. (обычно 10, при потрясениях до 30)" % [pv, float(sw[0]) * 100.0]
	if not (sw[1] as PackedStringArray).is_empty():
		t += "\n  " + "\n  ".join(sw[1] as PackedStringArray)
	return t

