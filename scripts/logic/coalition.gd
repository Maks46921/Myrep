# Коалиция и правительство: партии, министры, требования, вотум недоверия.
extends "res://scripts/logic/elections.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func council_expel_vote(p: int) -> Dictionary:
	return {}


func council_invite_vote(p: int) -> Dictionary:
	return {}


func council_min_vote(m: int, p: int, old: int) -> Dictionary:
	return {}


func crisis_tol_pick() -> int:
	return 0


func end_game(msg: String) -> void:
	pass


func invite_offer_w(p: int, promise: bool, mins: int) -> float:
	return 0.0


func party_lean(g: String, p: int) -> float:
	return 0.0


func show_crisis_exit() -> bool:
	return false


func war_sat_term(p: int) -> float:
	return 0.0


# --- конец заглушек ---


const GOV_EXCLUDE := [6]      # «прочие» — не партия, в коалицию не входит
const CORDON_JOIN := -30.0     # v35: «санитарный кордон» вместо прежнего «никогда» (−99)


# может ли партия вообще входить в правительство/договариваться
func can_govern(p: int) -> bool:
	return p > 0 and p < PARTY_NAMES.size() and not (p in GOV_EXCLUDE)


# партия, с которой мейнстрим обычно не вступает в коалицию
func is_cordon(p: int) -> bool:
	return p > 0 and p < PARTY_TRAITS.size() and float(PARTY_TRAITS[p]["join"]) <= -50.0


func tolerates(p: int) -> bool:
	return can_govern(p) and not in_coalition[p] and seats[p] > 0 and ((minority_ok and willingness(p, false) >= TOLERATE_W) or pact_has(p, "tol"))


func against_seats() -> int:
	var n := 0
	for p in range(1, PARTY_NAMES.size()):
		if in_coalition[p] or tolerates(p):
			continue
		n += seats[p]
	return n


func gov_ok() -> bool:
	if techno_until > turn:
		return true
	if minority_ok or minority_gov:
		return against_seats() < MAJORITY
	return gov_seats() >= MAJORITY


func gov_margin() -> int:
	if minority_ok or minority_gov:
		return MAJORITY - 1 - against_seats()
	return gov_seats() - MAJORITY


func seat_pad() -> int:
	return maxi(1, int(round(float(SEATS) * 0.04)))


func gov_seats() -> int:
	var n := 0
	for p in PARTY_NAMES.size():
		if in_coalition[p]:
			n += seats[p]
	return n


func coalition_names() -> String:
	var parts: PackedStringArray = []
	for p in range(1, PARTY_NAMES.size()):
		if in_coalition[p]:
			parts.append(PARTY_NAMES[p])
	return ", ".join(parts) if parts.size() > 0 else "только ваша партия"


func opp_bloc() -> int:
	var opp := 0
	var upto: int = 9 if int(mods["constr"]) == 1 else PARTY_NAMES.size()
	for p in range(1, upto):
		if not in_coalition[p]:
			opp += seats[p]
	return opp


func check_impeachment() -> void:
	var opp := opp_bloc()
	if minority_ok:
		opp = against_seats()
	if opp >= impeach_seats() and approval() < 42.0 and crisis_months >= 2:
		if not impeach_warned:
			impeach_warned = true
			if ccode == "DE":
				log_line("[color=%s][b]Угроза вотума недоверия![/b] Оппозиция (без АдГ) может собрать %d мест (нужно %d) и избрать нового канцлера, а ваш рейтинг ниже 42%%.[/color]" % [COL_BAD, opp, impeach_seats()])
			else:
				log_line("[color=%s][b]Угроза вотума недоверия![/b] Оппозиция может собрать %d мест (нужно %d) и отправить правительство в отставку, а ваш рейтинг ниже 42%%.[/color]" % [COL_BAD, opp, impeach_seats()])
		if randf() < 0.05:
			end_game(("Бундестаг выразил недоверие и избрал нового канцлера (конструктивный вотум). Оппозиция собрала %d мест из %d." if ccode == "DE" else "Парламент выразил недоверие правительству: оппозиция собрала %d мест из %d, и вы вынуждены уйти в отставку.") % [opp, SEATS])
	elif opp < impeach_seats() - 5 or approval() >= 48.0:
		impeach_warned = false


# ============================================================
#  ЗАКОНЫ, МЕРЫ, ДЕЙСТВИЯ
# ============================================================


func party_stance(p: int, sup: Dictionary) -> float:
	var num := 0.0
	var den := 0.0
	for g in GROUPS:
		var w: float = party_lean(g, p) * float(GROUP_WEIGHT[g])
		var d: float = float(sup.get(g, 0.0))
		if d < 0.0:
			d *= 2.0
		num += w * d
		den += w
	return num / den


# v35: расходы сами поднимаются до ожиданий социальных групп («группы ждут ≈» под статьёй бюджета)
func floor_share(key: String) -> float:
	var want: float = expected_pp(key) * (GDP0 / 100.0) * pop_ratio() * std_index()
	return want / gdp * 100.0


func auto_floor(only_selected: bool = false) -> int:
	var n := 0
	var parts: PackedStringArray = []
	for d in POLICY:
		var key: String = d["key"]
		if String(d["kind"]) != "spend":
			continue
		if only_selected and not floor_keys.has(key):
			continue
		var share: float = floor_share(key) + 0.005
		share = lock_allowed_share(key, share)
		var old: float = pol[key]
		if share <= old + 0.001:
			continue
		set_policy(key, share)
		prev_pol[key] = float(prev_pol[key]) + (float(pol[key]) - old)
		n += 1
		parts.append("«%s» %.1f → %.1f%% ВВП" % [policy_title(key), old, float(pol[key])])
	if n > 0:
		log_tag("БЮДЖЕТ", COL_TEAL, "автоподъём расходов до ожиданий социальных групп: %s." % "; ".join(parts))
	return n


func demand_value(key: String) -> float:
	match key:
		"reg_transfer": return transfer_avg()
		"reg_auto": return reg_avg("auto")
	return float(pol[key])


func demand_met(d: Dictionary) -> bool:
	var cur := demand_cur(d)
	if d["op"] == ">=":
		return cur >= float(d["val"]) - 0.001
	return cur <= float(d["val"]) + 0.001


func demand_score(p: int) -> float:
	var ds: Array = PARTY_DEMANDS[p]
	if ds.is_empty():
		return 1.0
	var tot := 0.0
	for d in ds:
		if demand_met(d):
			tot += 1.0
		else:
			var gap: float = absf(demand_cur(d) - float(d["val"]))
			var tol: float = maxf(0.4, 0.25 * absf(float(d["val"])))
			tot += maxf(0.0, 1.0 - gap / tol)
	return tot / float(ds.size())


func demand_lines(p: int) -> String:
	var ds: Array = PARTY_DEMANDS[p]
	if ds.is_empty():
		return "Особых требований нет."
	var t := ""
	for d in ds:
		var ok := demand_met(d)
		t += "[color=%s]%s[/color] %s (сейчас %.1f)\n" % [COL_GOOD if ok else COL_BAD, "✔" if ok else "✘", d["text"], demand_cur(d)]
	return t


func port_score(p: int) -> float:
	var held := 0
	var pref := 0
	var prefs: Array = PARTY_MINISTRIES[p]
	for m in MINISTRIES.size():
		if ministries[m] == p:
			held += 1
			if m in prefs:
				pref += 1
	if held == 0:
		return 15.0
	var fair: float = float(seats[p]) / float(maxi(1, gov_seats())) * float(MINISTRIES.size())
	# v35: любой портфель радует, профильный — сильнее
	return clampf(50.0 + 25.0 * (float(held) - fair) / maxf(1.0, fair) + 20.0 * float(pref) + 6.0 * float(held - pref), 0.0, 100.0)


func sat_target(p: int) -> float:
	var s := SAT_OFFSET
	for it in sat_breakdown(p):
		s += float(it[1])
	return s


func sat_reason(p: int) -> String:
	var parts: PackedStringArray = []
	var tr: Dictionary = PARTY_TRAITS[p]
	if party_attitude(p) < 45.0:
		parts.append("их избиратели недовольны властью")
	if demand_score(p) < 0.6:
		parts.append("не выполнены их бюджетные требования")
	if port_score(p) < 45.0:
		parts.append("им мало министерств")
	if not law_demand_met(p):
		parts.append("не принят закон-условие")
	if float(conc.get(p, 0.0)) < -4.0:
		parts.append("их раздражают ваши решения")
	if turn - int(joined.get(p, turn)) > 24:
		parts.append("давно в коалиции и ждут знаков внимания")
	if float(tr["rating_w"]) > 0.0 and approval() < 45.0:
		parts.append("ваш рейтинг падает")
	return ", ".join(parts) if parts.size() > 0 else "общий фон"


func grant_ministries(p: int) -> void:
	var quota: int = quota_for(p)
	var have := 0
	for m in MINISTRIES.size():
		if ministries[m] == p:
			have += 1
	for m in (PARTY_MINISTRIES[p] as Array):
		if have >= quota:
			break
		if ministries[m] == 0:
			ministries[m] = p
			have += 1
	var wanted: Array = []
	for q in range(1, PARTY_NAMES.size()):
		if q != p and in_coalition[q]:
			for m in (PARTY_MINISTRIES[q] as Array):
				wanted.append(m)
	for pass_no in 2:
		for m in MINISTRIES.size():
			if have >= quota:
				break
			if ministries[m] != 0 or m == 0:
				continue
			if pass_no == 0 and (m in wanted):
				continue
			ministries[m] = p
			have += 1


func release_ministries(p: int) -> void:
	for m in MINISTRIES.size():
		if ministries[m] == p:
			ministries[m] = 0


func assign_ministries() -> void:
	for m in MINISTRIES.size():
		ministries[m] = 0
	var members: Array = []
	for p in range(1, PARTY_NAMES.size()):
		if in_coalition[p]:
			members.append([seats[p], p])
	members.sort_custom(func(a, b): return a[0] > b[0])
	for mb in members:
		for m in (PARTY_MINISTRIES[mb[1]] as Array):
			if ministries[m] == 0:
				ministries[m] = mb[1]
				break
	for mb in members:
		grant_ministries(mb[1])


func add_member(p: int) -> void:
	in_coalition[p] = true
	joined[p] = turn
	conc[p] = 0.0
	satis[p] = clampf(sat_target(p) * 0.6 + 55.0 * 0.4, 40.0, 70.0)
	grant_ministries(p)


func remove_member(p: int) -> void:
	in_coalition[p] = false
	release_ministries(p)
	satis.erase(p)
	conc.erase(p)
	joined.erase(p)


func cycle_ministry(m: int) -> void:
	if opp_mode:
		return
	if game_over:
		return
	var holders: Array = [0]
	for p in range(1, PARTY_NAMES.size()):
		if in_coalition[p]:
			holders.append(p)
	if holders.size() < 2:
		return
	var idx: int = holders.find(ministries[m])
	var nxt: int = holders[(idx + 1) % holders.size()]
	assign_ministry(m, nxt)


func select_party(p: int) -> void:
	selected_party = p
	refresh()


func do_concession(p: int) -> void:
	if pl_deny(): return
	if game_over or not in_coalition[p] or cap_spendable() < 12.0:
		return
	capital -= 12.0
	conc[p] = float(conc.get(p, 0.0)) + 18.0
	satis[p] = clampf(float(satis.get(p, 50.0)) + 8.0, 0.0, 100.0)
	log_line("[color=%s]Вы пошли на уступки партии «%s» (политкапитал -12): довольство выросло.[/color]" % [COL_GOOD, PARTY_NAMES[p]])
	refresh()


func fulfill_demands(p: int) -> String:
	var parts: PackedStringArray = []
	for d in PARTY_DEMANDS[p]:
		if demand_met(d):
			continue
		var key: String = d["key"]
		if key == "reg_transfer":
			var diff: float = float(d["val"]) - transfer_avg()
			for i in regions.size():
				regions[i]["transfer"] = maxf(0.0, float(regions[i]["transfer"]) + diff)
			parts.append("трансферты регионам +%.1f п.п." % diff)
		elif key == "reg_auto":
			parts.append("рост автономии регионов (нужно действовать в регионах)")
		else:
			var old: float = pol[key]
			var is_amt: bool = d.get("abs", false)
			var share: float = float(d["val"]) / gdp * 100.0 if is_amt else float(d["val"])
			if key == "subs" and is_amt:
				share = maxf(0.0, share - float(pol["agri"]))
			share = lock_allowed_share(key, share)
			set_policy(key, share)
			prev_pol[key] = float(prev_pol[key]) + (float(pol[key]) - old)
			if absf(float(pol[key]) - old) > 0.001:
				if is_amt:
					parts.append("«%s» %.0f → %.0f млрд/год" % [policy_title(key), old * gdp / 100.0, float(pol[key]) * gdp / 100.0])
				else:
					parts.append("«%s» %.1f → %.1f%% ВВП" % [policy_title(key), old, float(pol[key])])
	return ", ".join(parts)


func fulfill_party_demands(p: int) -> void:
	if pl_deny(): return
	if game_over:
		return
	var txt := fulfill_demands(p)
	if txt == "":
		return
	log_line("[b]%s: вы выполнили требования партии «%s»:[/b] %s." % [date_text(), PARTY_NAMES[p], txt])
	refresh()


func fulfill_coalition_demands() -> void:
	var parts: PackedStringArray = []
	for p in range(1, PARTY_NAMES.size()):
		if in_coalition[p]:
			var t := fulfill_demands(p)
			if t != "":
				parts.append("%s: %s" % [PARTY_NAMES[p], t])
	if parts.size() > 0:
		log_line("  Требования партнёров выполнены. " + "; ".join(parts) + ".")


func form_government(verbose: bool) -> bool:
	if not gov_ok():
		var cands: Array = []
		for p in range(1, PARTY_NAMES.size()):
			if not in_coalition[p] and seats[p] > 0 and can_govern(p) and willingness(p, false) >= COALITION_JOIN:
				cands.append([willingness(p, false), p])
		cands.sort_custom(func(a, c): return a[0] > c[0])
		for c in cands:
			in_coalition[c[1]] = true
			if verbose:
				log_line("  %s вступает в правящую коалицию." % PARTY_NAMES[c[1]])
			if gov_ok():
				break
	assign_ministries()
	for p in range(1, PARTY_NAMES.size()):
		if in_coalition[p] and not satis.has(p):
			joined[p] = turn
			conc[p] = 0.0
			satis[p] = clampf(sat_target(p) * 0.6 + 55.0 * 0.4, 40.0, 70.0)
	return gov_ok()


func check_government() -> void:
	check_commitments()
	if auto_floor_on or not floor_keys.is_empty():
		auto_floor(not auto_floor_on)
	var members := 0
	var sum_sat := 0.0
	for p in range(1, PARTY_NAMES.size()):
		if not in_coalition[p]:
			continue
		var cur: float = float(satis.get(p, 55.0))
		cur += (sat_target(p) - cur) * mrate(0.7)
		satis[p] = cur
		conc[p] = float(conc.get(p, 0.0)) * 0.93
		if cur < SAT_LEAVE:
			remove_member(p)
			sfx("bad")
			warned[p] = false
			log_line("[color=%s]%s вышла из правящей коалиции: довольство упало до %.0f (%s). Её министерства вернулись вашей партии.[/color]" % [COL_BAD, PARTY_NAMES[p], cur, sat_reason(p)])
			continue
		members += 1
		sum_sat += cur
		if cur < SAT_LEAVE + 14.0:
			if not warned.get(p, false):
				warned[p] = true
				log_line("[color=%s]Предупреждение: %s недовольна и может покинуть коалицию (довольство %.0f): %s.[/color]" % [COL_WARN, PARTY_NAMES[p], cur, sat_reason(p)])
		else:
			warned[p] = false
	if gov_ok():
		if crisis_months > 0:
			crisis_months = 0
			log_line("[color=%s]Парламентская поддержка восстановлена.[/color]" % COL_GOOD)
	else:
		crisis_months += 1
		if crisis_months == 1:
			log_line("[color=%s][b]Правительственный кризис![/b] В коалиции только %d мест из %d. Восстановите большинство за %d месяцев, иначе парламент будет распущен.[/color]" % [COL_BAD, gov_seats(), SEATS, crisis_limit()])
		elif crisis_months >= crisis_limit():
			# v35: вместо автоматического роспуска — выбор пути выхода из кризиса (без штрафа капиталом)
			if not crisis_offered and show_crisis_exit():
				return
			if crisis_months >= crisis_limit() + 3 and current_event.is_empty():
				deadlock += 1
				crisis_offered = false
				hold_parliament("правительство не получило поддержки парламента")
				return
	# 0.55.5: капитал в минусе — оппозиция и недовольные партнёры могут потребовать отставки
	if cap_neg_risk() > 0.0 and turn - last_nocon >= 6 and current_event.is_empty() and randf() < cap_neg_risk():
		log_line("[color=%s]Политический капитал правительства в минусе (%.0f): в парламенте заговорили об отставке.[/color]" % [COL_BAD, capital])
		show_no_confidence()
		return
	var avg_sat: float = sum_sat / float(members) if members > 0 else 60.0
	var risky: bool = gov_margin() < seat_pad() or (members > 0 and avg_sat < 45.0) or crisis_months > 0
	if risky and turn - last_nocon >= 18 and current_event.is_empty() and randf() < 0.05:
		show_no_confidence()
		return
	check_impeachment()


func show_no_confidence() -> void:
	last_nocon = turn
	current_event = {"t": "Оппозиция внесла вотум недоверия правительству! Голосование уже скоро.", "special": "nocon", "o": [
		{"l": "Раздать портфели и договориться (капитал -10): довольство партнёров +12", "fx": {"capital": -10.0, "coal_sat": 12.0}},
		{"l": "Выполнить требования партнёров (бюджет изменится)", "fx": {"coal_demands": true, "coal_sat": 6.0}},
		{"l": "Заявить о полной уверенности", "fx": {"all": 2.0, "coal_sat": -6.0}}]}
	event_region = -1
	present_event()


func resolve_no_confidence() -> void:
	var against := 0
	var rebels: PackedStringArray = []
	for p in range(1, PARTY_NAMES.size()):
		if not in_coalition[p]:
			if not tolerates(p):
				against += seats[p]
		elif float(satis.get(p, 50.0)) < 34.0 + maxf(0.0, -capital) * 0.4:   # 0.55.5: при капитале в минусе партнёры бунтуют охотнее
			against += seats[p]
			rebels.append(PARTY_NAMES[p])
	var txt := "Голосование о недоверии: против правительства %d, нужно %d." % [against, MAJORITY]
	if rebels.size() > 0:
		txt += " К оппозиции присоединились: %s." % ", ".join(rebels)
	log_line("[b]%s[/b]" % txt)
	if against >= MAJORITY and noc_constr and randf() >= clampf(0.35 + float(against - MAJORITY) / float(MAJORITY) * 3.0, 0.1, 0.9):
		log_line("[color=%s]Конструктивный вотум: оппозиция набрала голоса против правительства, но не смогла договориться о преемнике. Правительство остаётся.[/color]" % COL_GOOD)
		add_all_support(1.0)
	elif against >= MAJORITY:
		capital -= 10.0
		log_line("[color=%s][b]Парламент выразил недоверие правительству.[/b] Назначены досрочные выборы.[/color]" % COL_BAD)
		hold_parliament("вотум недоверия")
	else:
		log_line("[color=%s]Правительство выдержало вотум недоверия.[/color]" % COL_GOOD)
		add_all_support(2.0)


func toggle_coalition(p: int) -> void:
	if pl_deny(): return
	if game_over or opp_mode or p == 0 or seats[p] == 0:
		return
	if in_coalition[p]:
		var ev := council_expel_vote(p)
		if not bool(ev["ok"]):
			log_line("[color=%s]Совет коалиции против исключения «%s» (за — %.0f%% влияния; против: %s).[/color]" % [COL_BAD, PARTY_NAMES[p], float(ev["yes"]) * 100.0, ", ".join(ev["no"])])
			refresh()
			return
		remove_member(p)
		log_tag("КОАЛИЦИЯ", COL_WARN, "вы исключили «%s» из коалиции. Теперь у правительства %d мест. Её министерства вернулись вашей партии." % [PARTY_NAMES[p], gov_seats()])
		recompute_mods()
		refresh()
	else:
		invite_party(p, false)


func ministries_of(p: int) -> String:
	var parts: PackedStringArray = []
	for m in MINISTRIES.size():
		if ministries[m] == p:
			parts.append(MINISTRIES[m]["name"])
	return ", ".join(parts) if parts.size() > 0 else "нет"


# ============================================================
#  ЗАКОНЫ (с переговорами)
# ============================================================


func ministry_fx(m: int, p: int, skill: float = 65.0) -> Dictionary:
	var sf: float = clampf(skill / 65.0, 0.6, 1.5)
	var key := "%d:%d" % [m, p]
	var fx: Dictionary
	if MIN_SPECIAL.has(key):
		fx = MIN_SPECIAL[key]
	else:
		fx = scale_fx(MINISTRIES[m]["base"], 0.8 if p == 0 else 0.5)
	return scale_fx(boost_good(fx, sf), MIN_FX_SCALE)


func ministry_is_special(m: int, p: int) -> bool:
	return MIN_SPECIAL.has("%d:%d" % [m, p])


func ministry_role_text(m: int, p: int) -> String:
	var key := "%d:%d" % [m, p]
	if MIN_SPECIAL.has(key):
		return "специалист: %s" % MIN_SPECIAL[key]["t"]
	if p == 0:
		return "министр вашей партии"
	return "не профильное министерство партии"


func ministry_items(fx: Dictionary) -> Array:
	var items: Array = []
	var xs: Dictionary = fx.get("x", {})
	for k in xs:
		if absf(float(xs[k]) - 1.0) > 0.0001:
			items.append(mod_item(k, 1.0, float(xs[k])))
	var ad: Dictionary = fx.get("a", {})
	for k in ad:
		if absf(float(ad[k])) > 0.0001:
			items.append(mod_item(k, 0.0, float(ad[k])))
	return items


func new_minister(m: int, p: int) -> Dictionary:
	var pool: Array = []
	for n in MINISTER_NAMES:
		if not used_names.has(n):
			pool.append(n)
	var nm: String = pool[randi() % pool.size()] if pool.size() > 0 else MINISTER_NAMES[randi() % MINISTER_NAMES.size()]
	used_names[nm] = true
	var skill: float = clampf(randfn(65.0, 14.0), 35.0, 95.0)
	return {"name": nm, "skill": snappedf(skill, 1.0), "party": p, "since": turn}


func sync_ministers() -> void:
	if ministries.size() != MINISTRIES.size():
		return
	while ministers.size() < MINISTRIES.size():
		ministers.append({})
	for m in MINISTRIES.size():
		var mn: Dictionary = ministers[m]
		if mn.is_empty() or int(mn["party"]) != ministries[m]:
			ministers[m] = new_minister(m, ministries[m])


func cabinet_items() -> Array:
	var with_c := compute_mods(law_state, true)
	var without := compute_mods(law_state, false)
	var items: Array = []
	for key in with_c:
		if absf(float(with_c[key]) - float(without[key])) > 0.00001 and MOD_INFO.has(key):
			items.append(mod_item(key, without[key], with_c[key]))
	return items


func assign_ministry(m: int, p: int) -> void:
	if pl_deny(): return
	if game_over or ministries[m] == p:
		return
	if p != 0 and not in_coalition[p]:
		return
	var old: int = ministries[m]
	if council_on():
		var cv := council_min_vote(m, p, old)
		if not bool(cv["ok"]):
			log_tag("КАБИНЕТ", COL_BAD, "совет коалиции не согласился передать министерство «%s» партии «%s»: «за» %.0f%% влияния, против — %s." % [MINISTRIES[m]["name"], PARTY_NAMES[p], float(cv["yes"]) * 100.0, ", ".join(cv["no"])])
			refresh()
			return
		log_tag("КАБИНЕТ", COL_DIM, "совет коалиции одобрил назначение («за» %.0f%% влияния)." % (float(cv["yes"]) * 100.0))
	ministries[m] = p
	if old > 0 and in_coalition[old]:
		conc[old] = float(conc.get(old, 0.0)) - 5.0
	if p > 0:
		conc[p] = float(conc.get(p, 0.0)) + (5.0 if (m in (PARTY_MINISTRIES[p] as Array)) else 3.0)
	log_tag("КАБИНЕТ", COL_PURPLE, "министерство «%s» передано: %s → %s." % [MINISTRIES[m]["name"], PARTY_NAMES[old], PARTY_NAMES[p]])
	recompute_mods()
	refresh()


func replace_minister(m: int) -> void:
	if pl_deny(): return
	if game_over or cap_spendable() < 5.0:
		return
	var p: int = ministries[m]
	if council_on() and p > 0:
		# v35: смену чужого министра решает совет коалиции; партия-держатель против
		var yes := 0.0
		for q in coal_members():
			if q == 0 or (q != p and rel(q, p) < 60.0):
				yes += coal_share(q)
		if yes <= 0.5:
			log_tag("КАБИНЕТ", COL_BAD, "совет коалиции не поддержал смену министра «%s» от «%s» («за» %.0f%% влияния)." % [MINISTRIES[m]["name"], PARTY_NAMES[p], yes * 100.0])
			refresh()
			return
	capital -= 5.0
	var old: Dictionary = ministers[m]
	ministers[m] = new_minister(m, p)
	if p > 0:
		conc[p] = float(conc.get(p, 0.0)) - 6.0
	var nw: Dictionary = ministers[m]
	log_tag("КАБИНЕТ", COL_PURPLE, "министр «%s» %s заменён: %s (навык %.0f) → %s (навык %.0f). Политкапитал -5." % [
		MINISTRIES[m]["name"], PARTY_NAMES[p], old["name"], old["skill"], nw["name"], nw["skill"]])
	recompute_mods()
	refresh()


func reshuffle_cabinet() -> void:
	if pl_deny(): return
	if game_over:
		return
	assign_ministries()
	log_tag("КАБИНЕТ", COL_PURPLE, "министерства перераспределены по квотам: каждая партия получила долю, пропорциональную числу мест, и свои профильные портфели.")
	recompute_mods()
	refresh()


func quota_for(p: int) -> int:
	return maxi(1, int(round(float(seats[p]) / float(maxi(1, gov_seats())) * float(MINISTRIES.size())))) + int(extra_mins.get(p, 0))


func sat_breakdown(p: int) -> Array:
	var tr: Dictionary = PARTY_TRAITS[p]
	var out: Array = []
	out.append(["Настроение избирателей партии", float(tr["att_w"]) * party_attitude(p)])
	out.append(["Бюджетные требования", float(tr["dem_w"]) * 30.0 * demand_score(p)])
	out.append(["Министерства", float(tr["port_w"]) * 0.33 * port_score(p)])
	if not law_demand_of(p).is_empty():
		out.append(["Закон-условие", float(tr["law_met"]) if law_demand_met(p) else float(tr["law_unmet"])])
	out.append(["Обещания, уступки и ваши законы", float(conc.get(p, 0.0))])
	var tired: float = minf(SAT_FATIGUE_CAP, SAT_FATIGUE * float(turn - int(joined.get(p, turn)))) * float(tr["fat_w"])
	out.append(["Усталость от коалиции", -tired])
	var cor := lvl_sum("coal")
	if absf(cor) > 0.05:
		out.append(["Коррупция в стране", cor])
	if float(tr["rating_w"]) != 0.0:
		out.append(["Рейтинг власти", float(tr["rating_w"]) * (approval() - 50.0)])
	if float(tr["base"]) != 0.0:
		out.append(["Характер лидера", float(tr["base"])])
	var wt := war_sat_term(p)
	if absf(wt) > 0.05:
		out.append(["Война", wt])
	return out


func willingness(p: int, promise: bool) -> float:
	var j: float = float(PARTY_TRAITS[p]["join"])
	if j <= -50.0:
		j = CORDON_JOIN + 5.0 * float(deadlock)
	var w := party_attitude(p) + j + float(DE_JOIN_ADJ[p])
	if prel.size() > p:
		w += (float(prel[p]) - 50.0) * (0.45 if is_cordon(p) else 0.25)
	# v35: после повторных выборов без правительства партии охотнее идут на компромисс
	w += 4.0 * float(mini(deadlock, 4))
	# v53: при управляемой политике «системная оппозиция» послушно идёт в правительство (кроме несистемной — слот 9)
	if p != 9:
		w += au_control() * 30.0
	if promise and not law_demand_of(p).is_empty() and not law_demand_met(p):
		w += 8.0
	return w


func add_commitment(p: int) -> void:
	var ld := law_demand_of(p)
	if ld.is_empty() or law_demand_met(p):
		return
	for c in commitments:
		if int(c["p"]) == p:
			return
	var cm := {"p": p, "tid": ld["tid"], "idx": demand_idx(ld), "deadline": turn + 18}
	if ld.has("val"):
		cm["val"] = ld["val"]
		cm["op"] = ld.get("op", "ge")
	commitments.append(cm)
	log_tag("ОБЕЩАНИЕ", COL_PURPLE, "вы пообещали партии «%s» принять закон %s в течение 18 месяцев (до %s)." % [PARTY_NAMES[p], law_demand_text(p), date_after(18)])


func check_commitments() -> void:
	var keep: Array = []
	for c in commitments:
		var p: int = c["p"]
		if not in_coalition[p]:
			continue
		if demand_dict_met(c):
			conc[p] = float(conc.get(p, 0.0)) + 10.0
			log_tag("ОБЕЩАНИЕ", COL_GOOD, "выполнено перед партией «%s»: принят закон %s. Довольство растёт." % [PARTY_NAMES[p], law_demand_text(p)])
			continue
		if turn >= int(c["deadline"]):
			conc[p] = float(conc.get(p, 0.0)) - 18.0
			satis[p] = clampf(float(satis.get(p, 50.0)) - 8.0, 0.0, 100.0)
			log_tag("ОБЕЩАНИЕ", COL_BAD, "нарушено перед партией «%s»: закон %s не принят в срок. Довольство резко упало." % [PARTY_NAMES[p], law_demand_text(p)])
			continue
		keep.append(c)
	commitments = keep


func invite_party(p: int, promise: bool = false, mins: int = 0) -> void:
	if game_over or opp_mode or not can_govern(p) or seats[p] == 0 or in_coalition[p]:
		return
	# v35: приём новой партии одобряют нынешние партнёры
	var cv := council_invite_vote(p)
	if not bool(cv["ok"]):
		log_line("[color=%s]Партнёры по коалиции против приёма «%s» (за — %.0f%% влияния; против: %s).[/color]" % [COL_BAD, PARTY_NAMES[p], float(cv["yes"]) * 100.0, ", ".join(cv["no"])])
		refresh()
		return
	var w := invite_offer_w(p, promise, mins)
	var paid := false
	if w < COALITION_JOIN:
		if w >= COALITION_JOIN_PAID and cap_spendable() >= CONCESSION_COST:
			paid = true
			capital -= CONCESSION_COST
		else:
			log_line("[color=%s]«%s» отказалась войти в коалицию (готовность %.0f, нужно %.0f).[/color]" % [COL_BAD, PARTY_NAMES[p], w, COALITION_JOIN])
			refresh()
			return
	if mins > 0:
		extra_mins[p] = mins
	add_member(p)
	if paid:
		conc[p] = 10.0
	if promise:
		add_commitment(p)
		conc[p] = float(conc.get(p, 0.0)) + 4.0
	log_tag("КОАЛИЦИЯ", COL_GOOD, "«%s» вошла в коалицию%s. У правительства %d мест. Министерства: %s." % [
		PARTY_NAMES[p], " после уступок (политкапитал -%.0f)" % CONCESSION_COST if paid else "", gov_seats(), ministries_of(p)])
	if gov_ok() and crisis_months > 0:
		crisis_months = 0
		log_line("[color=%s]Парламентская поддержка восстановлена.[/color]" % COL_GOOD)
	if gov_ok() and coal_talks:
		coal_talks_done()
	recompute_mods()
	refresh()


func coal_text(text: String) -> String:
	text = loc(text)
	if event_party > 0:
		text = text.replace("{p}", PARTY_NAMES[event_party])
		text = text.replace("{l}", law_demand_text(event_party))
	if event_min >= 0:
		text = text.replace("{m}", MINISTRIES[event_min]["name"])
	return text


func pick_weighted_partner(cands: Array) -> int:
	var tot := 0.0
	var ws: Array = []
	for p in cands:
		var w: float = maxf(5.0, 85.0 - float(satis.get(p, 55.0)))
		ws.append(w)
		tot += w
	var r := randf() * tot
	for i in cands.size():
		r -= float(ws[i])
		if r <= 0.0:
			return cands[i]
	return cands[0]


func coal_pick(kind: String, members: Array) -> Dictionary:
	if kind == "council":
		var sum := 0.0
		for p in members:
			sum += float(satis.get(p, 55.0))
		if members.size() >= 2 and sum / float(members.size()) < 62.0:
			return {"p": members[0]}
		return {}
	if kind == "want_min":
		var pairs: Array = []
		for p in members:
			for m in (PARTY_MINISTRIES[p] as Array):
				if ministries[m] != p:
					pairs.append([p, m])
		if pairs.is_empty():
			return {}
		var pr: Array = pairs[randi() % pairs.size()]
		return {"p": pr[0], "m": pr[1]}
	if kind == "scandal" or kind == "program":
		var held: Array = []
		for p in members:
			for m in MINISTRIES.size():
				if ministries[m] == p:
					held.append([p, m])
		if held.is_empty():
			return {}
		var h: Array = held[randi() % held.size()]
		return {"p": h[0], "m": h[1]}
	var cands: Array = []
	for p in members:
		if kind == "ultimatum":
			var has := false
			for c in commitments:
				if int(c["p"]) == p:
					has = true
			if law_demand_of(p).is_empty() or law_demand_met(p) or has:
				continue
		if kind == "poach" and float(satis.get(p, 55.0)) >= 66.0:
			continue
		cands.append(p)
	if cands.is_empty():
		return {}
	return {"p": pick_weighted_partner(cands)}


func show_coal_event() -> bool:
	# v50: требования партнёров по коалиции адресованы главе правительства, а не партии вне власти
	if not current_event.is_empty() or opp_mode:
		return false
	var members: Array = []
	for p in range(1, PARTY_NAMES.size()):
		if in_coalition[p]:
			members.append(p)
	if members.is_empty():
		return false
	var cands: Array = COAL_EVENTS.duplicate()
	cands.shuffle()
	for ev in cands:
		var pick := coal_pick(ev["kind"], members)
		if pick.is_empty():
			continue
		current_event = ev
		event_party = int(pick["p"])
		event_min = int(pick.get("m", -1))
		event_region = -1
		present_event()
		return true
	return false


func apply_psat(p: int, v: float) -> void:
	if p <= 0 or not in_coalition[p]:
		return
	conc[p] = float(conc.get(p, 0.0)) + v
	satis[p] = clampf(float(satis.get(p, 50.0)) + v * 0.7, 0.0, 100.0)


# ============================================================
#  v53: КОАЛИЦИОННЫЕ ПЕРЕГОВОРЫ ПОСЛЕ ВЫБОРОВ (коалицию собирает игрок)
# ============================================================
func coal_manual() -> bool:
	return int(game_opts.get("coal", 1)) == 1 and not observer


# кандидаты в партнёры: [готовность, партия], лучшие первыми
func coal_cands() -> Array:
	var out: Array = []
	for p in range(1, PARTY_NAMES.size()):
		if in_coalition[p] or seats[p] <= 0 or not can_govern(p):
			continue
		out.append([invite_offer_w(p, false, 0), p])
	out.sort_custom(func(a, b) -> bool: return float(a[0]) > float(b[0]))
	return out


# можно ли вообще собрать большинство с готовыми (хотя бы за уступки) партиями
func coal_feasible() -> bool:
	var s: int = gov_seats()
	for c in coal_cands():
		if float(c[0]) + 6.0 + 8.0 >= COALITION_JOIN_PAID:
			s += int(seats[int(c[1])])
	return s >= MAJORITY


func coal_talks_start() -> void:
	coal_talks = true
	coal_tried.clear()
	crisis_months = 1
	capital = minf(100.0, maxf(capital, 30.0) + 4.0)
	log_line("[color=%s][b]Коалиционные переговоры.[/b] У вашей партии %d мест из %d, для большинства нужно %d. Пригласите партнёров (окно переговоров и раздел «Правительство»): у вас %d мес., иначе — правительственный кризис.[/color]" % [COL_WARN, seats[0], SEATS, MAJORITY, crisis_limit()])


func coal_talks_done() -> void:
	coal_talks = false
	coal_tried.clear()
	crisis_months = 0
	crisis_offered = false
	deadlock = 0
	capital = minf(100.0, capital + 4.0)
	log_line("[color=%s][b]Правительство сформировано[/b] по итогам переговоров: %s — %d мест из %d.[/color]" % [COL_GOOD, coalition_names(), gov_seats(), SEATS])


func coal_w_text(w: float) -> String:
	if w >= COALITION_JOIN:
		return "согласится"
	if w >= COALITION_JOIN_PAID:
		return "согласится за уступки (капитал −%.0f)" % CONCESSION_COST
	return "скорее откажет"


# окно переговоров: с кем говорить и что предложить
func coal_talks_event() -> void:
	if not coal_talks or game_over or election_open or not current_event.is_empty():
		return
	if gov_ok():
		coal_talks_done()
		return
	var opts: Array = []
	var lines: PackedStringArray = []
	for c in coal_cands():
		var p: int = int(c[1])
		var w: float = float(c[0])
		lines.append("«%s» — %d мест, готовность %.0f: %s" % [PARTY_NAMES[p], seats[p], w, coal_w_text(w)])
		if p in coal_tried or opts.size() >= 6:
			continue
		opts.append({"l": "Пригласить «%s» (%d мест): %s" % [PARTY_NAMES[p], seats[p], coal_w_text(w)], "fx": {}, "coal": "inv", "p": p, "promise": false, "mins": 0})
		var w2: float = invite_offer_w(p, true, 1)
		if w < COALITION_JOIN and w2 >= COALITION_JOIN_PAID:
			opts.append({"l": "«%s»: предложить министерство и обещать их закон (%s)" % [PARTY_NAMES[p], coal_w_text(w2)], "fx": {}, "coal": "inv", "p": p, "promise": true, "mins": 1})
	var tp := crisis_tol_pick()
	if tp > 0:
		opts.append({"l": "Правительство меньшинства: «%s» обещает не голосовать против (капитал −5)" % PARTY_NAMES[tp], "fx": {"capital": -5.0}, "coal": "tol", "p": tp})
	opts.append({"l": "Продолжить переговоры самостоятельно (раздел «Правительство», осталось %d мес.)" % maxi(1, crisis_limit() - crisis_months + 1), "fx": {}, "coal": "self", "p": -1})
	var t := "Коалиционные переговоры. У вашей партии «%s» %d мест из %d, у коалиции %d; для большинства нужно %d. С кем договариваться?" % [PARTY_NAMES[0], seats[0], SEATS, gov_seats(), MAJORITY]
	if lines.size() > 0:
		t += "\n" + "\n".join(lines)
	current_event = {"t": t, "special": "coal", "o": opts}
	event_region = -1
	event_party = -1
	event_min = -1
	present_event()


func coal_resolve(opt: Dictionary) -> void:
	var p: int = int(opt.get("p", -1))
	match String(opt.get("coal", "self")):
		"inv":
			coal_tried.append(p)
			invite_party(p, bool(opt.get("promise", false)), int(opt.get("mins", 0)))
		"tol":
			minority_gov = true
			if not pacts.has(p):
				pacts[p] = {}
			pacts[p]["tol"] = parl_term() - (turn - last_parl)
			prel[p] = clampf(float(prel[p]) + 5.0, 0.0, 100.0)
			log_tag("КОАЛИЦИЯ", COL_GOOD, "правительство меньшинства: «%s» обязуется не поддерживать вотум недоверия до следующих выборов." % PARTY_NAMES[p])
		_:
			return
	if gov_ok():
		if coal_talks:
			coal_talks_done()
		recompute_mods()
		return
	coal_talks_event()
