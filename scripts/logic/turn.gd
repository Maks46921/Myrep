# Ход игры: один месяц, конец игры, начальная установка состояния.
extends "res://scripts/logic/events.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func adm_month() -> void:
	pass


func ag_build() -> void:
	pass


func ag_step() -> void:
	pass


func ai_init() -> void:
	pass


func ai_parties_step() -> void:
	pass


func ate_reset() -> void:
	pass


func au_init() -> void:
	pass


func autopilot_run() -> void:
	pass


func bills_step() -> void:
	pass


func cap_mults() -> Array:
	return []


func cap_sources() -> Array:
	return []


func church_init() -> void:
	pass


func church_month() -> void:
	pass


func con_init() -> void:
	pass


func con_month() -> void:
	pass


func council_budget() -> void:
	pass


func cult_g() -> float:
	return 0.0


func cult_init() -> void:
	pass


func cult_month() -> void:
	pass


func dip_init() -> void:
	pass


func dip_step() -> void:
	pass


func diplo_month() -> void:
	pass


func dx_init() -> void:
	pass


func es_init() -> void:
	pass


func ex_g() -> float:
	return 0.0


func ex_infl() -> float:
	return 0.0


func ex_init() -> void:
	pass


func ex_month() -> void:
	pass


func fa_init() -> void:
	pass


func fa_month() -> void:
	pass


func fed_init() -> void:
	pass


func fed_month() -> void:
	pass


func fleet_day() -> void:
	pass


func fleet_g() -> float:
	return 0.0


func fleet_infl() -> float:
	return 0.0


func fleet_init() -> void:
	pass


func fleet_month() -> void:
	pass


func h12_snap() -> void:
	pass


func idl_step() -> void:
	pass


func inbox_month() -> void:
	pass


func ind_g() -> float:
	return 0.0


func ind_init() -> void:
	pass


func ind_month() -> void:
	pass


func io_init() -> void:
	pass


func junior_quit() -> void:
	pass


func log_add(e: Dictionary) -> void:
	pass


func map_cam_step(delta: float) -> void:
	pass


func martial_step() -> void:
	pass


func mil_day() -> void:
	pass


func mil_g() -> float:
	return 0.0


func mil_infl() -> float:
	return 0.0


func mil_init() -> void:
	pass


func mil_month() -> void:
	pass


func mil_start_ongoing() -> void:
	pass


func mil_unemp() -> float:
	return 0.0


func observer_step() -> void:
	pass


func opp_init() -> void:
	pass


func opp_step() -> void:
	pass


func pa_month() -> void:
	pass


func radical_step() -> void:
	pass


func realism_month() -> void:
	pass


func revolt_g() -> float:
	return 0.0


func revolt_init() -> void:
	pass


func revolt_month() -> void:
	pass


func revolt_nationwide_uprising() -> bool:
	return false


func revolt_unemp() -> float:
	return 0.0


func rl_g() -> float:
	return 0.0


func rl_infl() -> float:
	return 0.0


func rl_init() -> void:
	pass


func rules_month() -> void:
	pass


func soc_g() -> float:
	return 0.0


func soc_init() -> void:
	pass


func soc_month() -> void:
	pass


func soc_unemp() -> float:
	return 0.0


func tech_init() -> void:
	pass


func tech_month() -> void:
	pass


func ui_anim_step(delta: float) -> void:
	pass


func world_init() -> void:
	pass


func world_spill_g() -> float:
	return 0.0


func world_spill_infl() -> float:
	return 0.0


func wsim_step() -> void:
	pass


# --- конец заглушек ---


# ---------- реальное время: календарь по дням ----------
# Месячный шаг экономики и политики (next_turn) выполняется на границе месяцев, как и раньше;
# каждый день идёт календарь и ежедневные подсистемы (day_tick).


func set_speed(i: int) -> void:
	play_idx = clampi(i, 0, PLAY_SPEEDS.size() - 1)
	day_acc = 0.0
	if play_idx > 0:
		speed_last = play_idx
	if play_btn != null:
		play_btn.set_pressed_no_signal(play_idx > 0)
		play_btn.text = "⏸" if play_idx > 0 else "▶"
	if speed_opt != null:
		speed_opt.select(speed_last - 1)


func on_play_toggled(on: bool) -> void:
	set_speed(speed_last if on else 0)


func on_speed_selected(k: int) -> void:
	speed_last = k + 1
	if play_idx > 0:
		set_speed(speed_last)


func set_time_btns(dis: bool) -> void:
	for b in [next_btn, day_btn, week_btn]:
		if b != null:
			(b as Button).disabled = dis


func blocked() -> bool:
	return game_over or not current_event.is_empty() or election_open


func day_tick() -> void:
	day_total += 1
	fleet_day()
	mil_day()


func advance_day() -> bool:
	if blocked():
		return false
	if day >= days_in_month(year, month):
		next_turn()          # переход через границу месяца: месячный шаг; он ставит день = 1
	else:
		day += 1
		if day == 8 or day == 15 or day == 22 or day == 29:
			week_tick()
	day_tick()
	return true


func advance_days(n: int) -> int:
	var done := 0
	for i in n:
		if not advance_day():
			break
		done += 1
	if done > 0:
		refresh()
	return done


# до первого числа следующего месяца
func advance_month() -> void:
	var m0 := turn
	for i in 40:
		if not advance_day() or turn != m0:
			break
	refresh()


func _process(delta: float) -> void:
	map_cam_step(delta)
	ui_anim_step(delta)
	if play_idx <= 0 or blocked():
		return
	day_acc += delta * float(PLAY_SPEEDS[play_idx])
	var guard := 0
	while day_acc >= 1.0 and guard < 120:
		day_acc -= 1.0
		guard += 1
		if not advance_day():
			day_acc = 0.0
			break
	if guard > 0:
		refresh()


func log_policy_changes() -> void:
	var parts: PackedStringArray = []
	for d in POLICY:
		var k: String = d["key"]
		var dv: float = float(pol[k]) - float(prev_pol.get(k, pol[k]))
		if absf(dv) >= 0.05:
			parts.append("«%s» %.1f → %.1f%% ВВП (%s млрд/год)" % [d["title"], float(prev_pol[k]), float(pol[k]), sg(gdp * dv / 100.0, 0)])
	if parts.size() > 0:
		log_tag("БЮДЖЕТ", COL_WARN, "ваши решения: %s" % "; ".join(parts))


# Макро-динамика за долю месяца dt (месячный шаг: dt = 1; недельный тик: dt ≈ 7/30). full — месячные «хозяйственные» действия.
func macro_step(dt: float, ecf: Dictionary, deficit_pct: float, debt_ratio: float, full: bool = true) -> void:
	# v35: на рост и инфляцию действует ИЗМЕНЕНИЕ дефицита (бюджетный импульс), а не его уровень относительно старта:
	# опорный дефицит def_ref медленно (≈3 года) подтягивается к текущему. Раньше консолидация бюджета навсегда
	# снижала рост и толкала инфляцию к нулю, а большой дефицит навсегда разгонял их.
	if def_ref < -50.0:
		def_ref = def0
	var fimp: float = deficit_pct - def_ref
	# v35: налоги и субсидии меняют в основном УРОВЕНЬ выпуска: полный эффект на темп роста — пока экономика
	# подстраивается (опора tax_ref догоняет за ≈5 лет), дальше остаётся 30%. Раньше +8 п.п. подоходного налога
	# навсегда отнимали 0,8 п.п. роста в год, и любая консолидация бюджета вела к затяжному спаду.
	var tdrag: float = (
		(float(pol["income"]) - float(pol_def["income"])) * 0.10
		+ (float(pol["social"]) - float(pol_def["social"])) * 0.07
		+ (float(pol["corp"]) - float(pol_def["corp"])) * 0.20
		+ (float(pol["vat"]) - float(pol_def["vat"])) * 0.08
		- (pp0("subs") - float(pol_def["subs"])) * 0.12 - (pp0("agri") - float(pol_def["agri"])) * 0.05
	)
	if tax_ref < -50.0:
		tax_ref = tdrag
	var g_target: float = (
		G_POT
		- 0.3 * tdrag - 0.7 * (tdrag - tax_ref)
		+ lvl_sum("growth")
		- maxf(0.0, inflation - 5.0) * 0.2
		- debt_drag(debt_ratio)
		+ fimp * 0.2
		+ float(mods["growth_bonus"])
		+ shock
		+ float(ecf["g"])
		- maxf(0.0, reg_avg("unrest") - 30.0) * 0.015
		+ world_spill_g()
		+ soc_g()
		+ cult_g()
		+ ind_g()
		+ ex_g()
		+ fleet_g()
		+ mil_g()
		+ revolt_g()
		+ rl_g()
	)
	g_target_last = g_target
	shock *= (0.9 if dt == 1.0 else pow(0.9, dt))
	growth += (g_target - growth) * rt(0.3, dt) + randf_range(-0.3, 0.3) * sqrt(dt)
	growth_ema += (growth - growth_ema) * rt(0.08, dt)
	if growth_trend < -50.0:
		growth_trend = G_NEU
	growth_trend += (growth - growth_trend) * rt(1.0 / 60.0, dt)
	def_ref += (deficit_pct - def_ref) * rt(1.0 / 36.0, dt)
	tax_ref += (tdrag - tax_ref) * rt(1.0 / 60.0, dt)
	# закон Оукена и инфляционное давление — от тренда роста: долгий застой сам по себе не наращивает безработицу и дефляцию без конца
	var g_ref: float = clampf(growth_trend, G_NEU - 1.0, G_NEU + 1.0)
	gdp_base *= 1.0 + growth / 1200.0 * dt
	gdp = gdp_base * regional_potential() / pot0
	if full:
		sync_abs_policies()
		expire_locks()
	inflation = clampf(inflation + (fimp * 0.3 + (growth - g_ref) * 0.15 - (inflation - I_TGT) * 0.2 + emit_excess() * 1.2 + 0.2 * float(ecf["infl"]) + world_spill_infl() + ex_infl() + fleet_infl() + mil_infl() + rl_infl()) / 12.0 * dt, 0.0, 40.0)
	var u_target: float = U_NEU + float(mods["unemp_base"]) + (pp0("benefits") - float(pol_def["benefits"])) * 0.3 - (pp0("subs") - float(pol_def["subs"])) * 0.25 - (pp0("agri") - float(pol_def["agri"])) * 0.1 + lvl_sum("unemp") + float(ecf["unemp"]) + soc_unemp() + mil_unemp() + revolt_unemp()
	unemployment = clampf(unemployment + (-(growth - g_ref) * 0.5 + (u_target - unemployment) * 0.15) / 12.0 * dt, 2.0, 30.0)
	var rloss := 0.0
	for i in regions.size():
		rloss += gdp_w[i] * float(REGIONS[i]["sec"]["res"]) * maxf(0.0, float(regions[i]["unrest"]) - 50.0) * 0.14
	other_rev += (OTHER0 - float(ec["revbase"]) - rloss - other_rev) * rt(mrate(0.1), dt)

	# --- поддержка групп и политический капитал ---
	for g in GROUPS:
		support[g] = clampf(lerpf(float(support[g]), target_support(g), rt(mrate(0.5), dt)), 0.0, 100.0)
	capital = minf(100.0, capital + cap_rate() * dt)


# прирост политического капитала в месяц (v35: показывается рядом с капиталом в верхней панели)
# 0.56 (п.18): сумма источников (места, пост главы правительства, министерства, экономическая власть…) × множители
func cap_rate() -> float:
	var s := 0.0
	for r in cap_sources():
		s += float(r[1])
	for r in cap_mults():
		s *= float(r[1])
	return s



# v35: экономика считается в постоянных ценах, а долг — в деньгах: инфляция обесценивает его реальную величину
# (проценты по долгу — номинальные). Без этого долг рос без предела при любом обычном дефиците.
func debt_erode(dt: float) -> void:
	if debt > 0.0 and inflation > 0.0:
		debt *= 1.0 - inflation / 1200.0 * dt


# v35: торможение роста от долга выше 90% ВВП. Стартовая часть (заложена в калибровку страны) — 0,02 за п.п.,
# прирост сверх стартового — 0,01 за п.п.: при 0,02 высокий долг и спад раскручивали друг друга до дефолта.
func debt_drag(ratio: float) -> float:
	if debt_start < -50.0:
		debt_start = ratio
	var base: float = maxf(0.0, debt_start - 90.0)
	var cur: float = maxf(0.0, ratio - 90.0)
	return 0.02 * base + 0.01 * (cur - base)


func rt(r: float, dt: float) -> float:
	# месячная доля сближения r -> доля за dt месяца
	return r if dt == 1.0 else 1.0 - pow(1.0 - r, dt)


# недельный тик: пересчёт макропоказателей, поддержки и рейтинга на 7 дней (цели берутся из последнего месячного расчёта экономики)
func week_tick() -> void:
	if game_over or ec.is_empty():
		return
	var dt: float = minf(7.0 / float(days_in_month(year, month)), maxf(0.0, 1.0 - month_done))
	if dt <= 0.0:
		return
	if month_snap.is_empty():
		take_month_snap()
	var b := compute_budget()
	debt -= float(b["balance"]) / 12.0 * dt
	debt_erode(dt)
	var deficit_pct: float = -float(b["balance"]) / gdp * 100.0
	macro_step(dt, last_ecf, deficit_pct, debt / gdp * 100.0, false)
	month_done += dt
	if debt / gdp > 1.5:
		end_game("Государственный дефолт. Страна не смогла обслуживать долг.")
		return
	if inflation >= 30.0:
		end_game("Гиперинфляция. Правительство отправлено в отставку.")
		return
	if not blocked() and not game_over:
		if randf() < 0.22 * float(game_opts["news"]) * dt:
			show_news()
		if not fire_scripted() and not ev_tick() and randf() < 0.22 * float(game_opts["ev"]) * dt:
			show_event()


func take_month_snap() -> void:
	h12_snap()
	month_snap = {"infl": inflation, "unemp": unemployment, "support": support.duplicate(), "appr": approval()}


func next_turn() -> void:
	if game_over or not current_event.is_empty() or election_open:
		return
	# v50: неутверждённый черновик бюджета в месячный расчёт не входит
	var bud_h := bud_hold_begin()
	next_turn_core()
	bud_hold_end(bud_h)


func next_turn_core() -> void:
	recompute_mods()
	top_prev = {"appr": approval(), "infl": inflation, "unemp": unemployment, "debt": debt / gdp * 100.0}
	council_budget()
	bud_glide_step()
	log_policy_changes()
	autopilot_run()
	rules_month()
	turn += 1
	month += 1
	day = 1
	if month > 12:
		month = 1
		year += 1
	for k in cooldown:
		cooldown[k] = maxi(0, int(cooldown[k]) - 1)
	for k in law_cd:
		law_cd[k] = maxi(0, int(law_cd[k]) - 1)
	for i in regions.size():
		var cd: Dictionary = reg_cd[i]
		for k in cd:
			cd[k] = maxi(0, int(cd[k]) - 1)
	inbox_month()
	# v49: наступившее продолжение истории (цепочка событий) показывается первым — иначе его месяцами
	# вытесняют дипломатические события, инициативы стран и вотумы
	if _ev_chain_due():
		ev_tick()

	var old_infl := inflation
	var old_unemp := unemployment
	var old_support := support.duplicate()
	var old_appr := approval()
	var old_regs: Array = []
	for r in regions:
		old_regs.append((r as Dictionary).duplicate())
	if not month_snap.is_empty():          # в игре недельные тики уже сдвинули показатели: сравниваем с началом месяца
		old_infl = float(month_snap["infl"])
		old_unemp = float(month_snap["unemp"])
		old_support = (month_snap["support"] as Dictionary).duplicate()
		old_appr = float(month_snap["appr"])

	# --- бюджет ---
	var b := compute_budget()
	var balance_y: float = b["balance"]
	var deficit_pct: float = -balance_y / gdp * 100.0
	var debt_ratio: float = debt / gdp * 100.0
	var rest: float = maxf(0.0, 1.0 - month_done)     # доля месяца, ещё не пройденная недельными тиками (в тестах всегда 1)
	debt -= balance_y / 12.0 * rest
	debt_erode(rest)
	brake_step(deficit_pct)
	dip_step()
	wsim_step()
	update_levels()
	update_regions()
	fed_month()
	adm_month()
	revolt_month()
	fleet_month()
	mil_month()
	soc_month()
	cult_month()
	church_month()
	ind_month()
	tech_month()
	realism_month()
	diplo_month()
	fa_month()
	ex_month()
	con_month()

	# --- экономика ---
	var ecf := economy_step()
	last_ecf = ecf
	last_deficit_pct = deficit_pct
	macro_step(rest, ecf, deficit_pct, debt_ratio)
	ag_step()
	month_done = 0.0

	log_month(b, old_infl, old_unemp, old_support, old_appr, old_regs)
	take_month_snap()
	prev_pol = pol.duplicate()
	if month == 12:
		log_year_summary()
		oneoff_year_reset()

	# --- крах государства ---
	if debt / gdp > 1.5:
		end_game("Государственный дефолт. Страна не смогла обслуживать долг.")
		return
	if inflation >= 30.0:
		end_game("Гиперинфляция. Правительство отправлено в отставку.")
		return
	low_months = low_months + 1 if (approval() < 25.0 and not opp_mode) else 0
	if low_months >= 3:
		if bool(junior_info()["junior"]):
			junior_quit()
		else:
			end_game("Рейтинг упал до %.0f%%, партия отказала вам в доверии: вы вынуждены уйти в отставку." % approval())
			return
	var riots := 0
	for r in regions:
		if float(r["unrest"]) >= 90.0:
			riots += 1
	if riots >= 4:
		if revolt_nationwide_uprising():
			pass
		else:
			end_game("Волна региональных восстаний охватила страну. Центральная власть потеряла контроль.")
			return

	# --- выборы и правительство ---
	if game_over:
		return
	radical_step()
	if game_over:
		return
	martial_step()
	if turn - last_parl >= parl_term() and not martial_on():
		hold_parliament("плановые выборы")
	elif opp_mode:
		opp_step()
	elif not decree_power():
		check_government()
	if game_over:
		return
	ai_parties_step()
	pa_month()
	observer_step()
	bills_step()
	idl_step()
	if game_over:
		return

	if pres_due >= 0 and turn >= pres_due and not martial_on() and not election_open and current_event.is_empty():
		hold_head("плановые выборы")
	if game_over:
		return

	# --- события ---
	campaign_check()
	head_campaign_check()
	dip_events()
	if randf() < 0.22 * float(game_opts["news"]) * rest:
		show_news()
	if not fire_scripted() and not ev_tick() and randf() < 0.22 * float(game_opts["ev"]) * rest:
		show_event()
	refresh()


func log_month(b: Dictionary, old_infl: float, old_unemp: float, old_support: Dictionary, old_appr: float, old_regs: Array) -> void:
	var notes: Array = []
	if log_detail:
		var rp: PackedStringArray = []
		for k in b["rev"]:
			rp.append("%s %.1f" % [k, float(b["rev"][k]) / 12.0])
		notes.append("доходы по статьям: " + " · ".join(rp))
		var ep: PackedStringArray = []
		for k in b["exp"]:
			ep.append("%s %.1f" % [k, float(b["exp"][k]) / 12.0])
		notes.append("расходы по статьям: " + " · ".join(ep))
	var ch := budget_changes(b)
	if ch != "":
		notes.append("[color=%s]◆[/color] Бюджет (доли ВВП): %s" % [COL_WARN, ch])
	if emit_excess() > 0.01 and (turn % 3 == 0 or log_detail):
		notes.append("[color=%s]⚠[/color] Эмиссия выше безопасного предела на %.1f%% ВВП (%.1f млрд в год): инфляция будет расти." % [COL_WARN, emit_excess(), gdp * emit_excess() / 100.0])
	var diffs: Array = []
	for g in GROUPS:
		diffs.append([g, float(support[g]) - float(old_support[g])])
	diffs.sort_custom(func(a, c): return absf(a[1]) > absf(c[1]))
	var sp: PackedStringArray = []
	for i in 3:
		if absf(diffs[i][1]) >= (0.4 if log_detail else 1.0):
			sp.append("%s %s" % [diffs[i][0], col_delta(diffs[i][1], 1)])
	if sp.size() > 0:
		notes.append("Сильнее всего изменилось отношение: " + ", ".join(sp))
	var rg: Array = []
	for i in regions.size():
		rg.append([REGIONS[i]["name"], float(regions[i]["unrest"]) - float(old_regs[i]["unrest"]), float(regions[i]["unrest"])])
	rg.sort_custom(func(a, c): return a[2] > c[2])
	if float(rg[0][2]) >= 45.0:
		notes.append("[color=%s]⚠[/color] Самый неспокойный регион: «%s», недовольство %.0f." % [COL_WARN, rg[0][0], rg[0][2]])
	log_add({"k": "month", "cat": "sum", "date": date_text(), "rev": float(b["revenue"]) / 12.0, "exp": float(b["spending"]) / 12.0,
		"bal": float(b["balance"]) / 12.0, "debt": debt, "debt_pct": debt / gdp * 100.0, "gdp": gdp, "growth": growth,
		"infl": inflation, "dinfl": inflation - old_infl, "unemp": unemployment, "dunemp": unemployment - old_unemp,
		"appr": approval(), "dappr": approval() - old_appr, "notes": notes})


func log_year_summary() -> void:
	log_add({"k": "year", "cat": "sum", "year": year, "ys": year_start.duplicate(), "gdp": gdp, "debt": debt, "infl": inflation, "unemp": unemployment, "appr": approval()})
	year_start = {"gdp": gdp, "debt": debt, "appr": approval(), "infl": inflation, "unemp": unemployment}


func end_game(msg: String) -> void:
	msg = loc(msg)
	game_over = true
	end_reason = msg
	log_header("КОНЕЦ ИГРЫ", COL_BAD)
	log_line("[color=%s]%s[/color]" % [COL_BAD, msg])
	log_line("Вы правили %d лет и %d мес. (до %s)." % [turn / 12, turn % 12, date_text()])
	current_event = {}
	if wins.has("event"):
		(wins["event"] as FloatWindow).visible = false
	if next_btn != null:
		set_time_btns(true)
	set_speed(0)
	refresh()


# ============================================================
#  ВЫБОРЫ: ПАРЛАМЕНТСКИЕ (пропорциональные) И ПРЕЗИДЕНТСКИЕ (два тура)
# ============================================================


func init_state() -> void:
	init_laws()
	ministers.clear()
	commitments.clear()
	used_names.clear()
	for d in POLICY:
		pol[d["key"]] = float(d["def"])
		pol_def[d["key"]] = float(d["def"])
		pol_abs[d["key"]] = float(d["def"]) * gdp / 100.0
		pol_abs_mode[d["key"]] = false
		policy_by_key[d["key"]] = d
	prev_pol = pol.duplicate()
	for g in GROUPS:
		support[g] = float(GROUP_BASE[g])
		bias[g] = 0.0
	for m in MEASURES:
		cooldown[m["id"]] = 0
	for a in ACTIONS:
		cooldown[a["id"]] = 0
	regions.clear()
	reg_mix.clear()
	reg_cd.clear()
	for i in REGIONS.size():
		var d: Dictionary = REGIONS[i]
		var kind: int = 0
		regions.append({"loy": float(d["loy"]), "unrest": float(d["unrest"]), "dev": float(d["dev"]), "auto": float(d["auto"]),
			"infra": float(d["infra"]), "edu": float(d["edu"]), "health": float(d["health"]), "env": float(d["env"]),
			"transfer": float(d.get("tr", 0.5)), "popm": float(d["popm"]), "unemp": U_NEU, "gov": new_governor(kind), "proj": {}, "built": {},
			"bonus": {"dev": 0.0, "infra": 0.0, "edu": 0.0, "health": 0.0, "env": 0.0},
			"smul": {"ind": 1.0, "agr": 1.0, "srv": 1.0, "res": 1.0}, "legacy": {"ind": 0.0, "agr": 0.0, "srv": 0.0, "res": 0.0},
			"zones": [], "upk": 0.0, "rdebt": 30.0, "rcrisis": false, "migr": 0.0, "mbonus": 0.0, "grp_h": []})
		reg_cd.append({})
		var mix := {}
		var tot := 0.0
		var dm: Dictionary = d["mix"]
		for g in GROUPS:
			var m: float = float(GROUP_WEIGHT[g]) * float(dm.get(g, 1.0))
			mix[g] = m
			tot += m
		for g in GROUPS:
			mix[g] = float(mix[g]) / tot
		reg_mix.append(mix)
	recalc_weights()
	res_price = 1.0
	agr_wx = 1.0
	for i in regions.size():
		regions[i]["rdebt"] = rdebt_target(i)
	auto0 = reg_avg("auto")
	pop0 = total_pop()
	pot0 = regional_potential()
	gdp_base = gdp
	table_order.clear()
	for i in REGIONS.size():
		table_order.append(i)
	charisma.clear()
	for p in PARTY_NAMES.size():
		charisma.append(1.0)
	in_coalition.clear()
	for p in PARTY_NAMES.size():
		in_coalition.append(p == 0)
	ministries.clear()
	for m in MINISTRIES.size():
		ministries.append(0)
	satis.clear()
	conc.clear()
	de_start_parliament()
	opp_init()
	ai_init()
	recompute_mods()
	init_economy()
	ate_reset()
	build_geometry()
	calibrate_regions()
	dip_init()
	world_init()
	fed_init()
	soc_init()
	cult_init()
	church_init()
	tech_init()
	revolt_init()
	au_init()
	es_init()
	con_init()
	rl_init()
	io_init()
	dx_init()
	fa_init()
	ex_init()
	fleet_init()
	mil_init()
	mil_start_ongoing()
	ind_init()
	recompute_mods()
	dip_bonus0 = float(mods["dip_bonus"])
	year_start = {"gdp": gdp, "debt": debt, "appr": approval(), "infl": inflation, "unemp": unemployment}
	ag_build()


func skip_months(n: int) -> void:
	for i in n:
		if game_over or not current_event.is_empty():
			break
		next_turn()
