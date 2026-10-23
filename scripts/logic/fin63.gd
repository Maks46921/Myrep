# Финансы (0.63): ядро. Центробанк и курс (cbank63.gd), банки и биржа (bank63.gd), госдолг, дефолт, МВФ и фонды (debt63.gd).
# Состояние — словарь fin. Опция game_opts["finlev"]=0 отключает модуль целиком (игра считается как в 0.62).
# Всё считается понедельно (wdt), месячное (журнал, история, перерывы) — только под wmonth. Действия игрока — fin_acts(page) / fin_do(id).
extends "res://scripts/logic/uniq60.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func fin_acts_bank() -> Array:
	return []


func fin_acts_cb() -> Array:
	return []


func fin_acts_debt() -> Array:
	return []


func fin_acts_ex() -> Array:
	return []


func fin_acts_fund() -> Array:
	return []


func fin_acts_fx() -> Array:
	return []


func fin_apply_act(id: String, opt: Dictionary) -> void:
	pass


func fin_bank_step() -> void:
	pass


func fin_cb_pull() -> float:
	return 0.0


func fin_cb_step() -> void:
	pass


func fin_cred_anchor() -> float:
	return 0.0


func fin_debt_step() -> void:
	pass


func fin_ecb_rate() -> float:
	return 0.0


func fin_ex_step() -> void:
	pass


func fin_fund_step() -> void:
	pass


func fin_fx_step() -> void:
	pass


func fin_imf_step() -> void:
	pass


func fin_month_bank() -> void:
	pass


func fin_month_cb() -> void:
	pass


func fin_month_debt() -> void:
	pass


# --- конец заглушек ---


const FIN_VER := 1
const FIN_CR_MULT := [0.5, 1.0, 2.0]        # частота кризисов: редко / как в истории / часто
const FIN_CR_NAMES := ["редко", "как в истории", "часто"]
const FIN_HIST_MAX := 240
const FIN_PAGES := ["cb", "fx", "bank", "ex", "debt", "fund"]
const FIN_PAGE_NAMES := {"cb": "Центробанк", "fx": "Курс и резервы", "bank": "Банки", "ex": "Биржа", "debt": "Долг и МВФ", "fund": "Фонды"}

var fin: Dictionary = {}


# ============================================================
#  ИНИЦИАЛИЗАЦИЯ И ДОСТУП
# ============================================================
func fin_on() -> bool:
	return not fin.is_empty() and int(game_opts.get("finlev", 1)) > 0


func fin_data() -> Dictionary:
	var d: Dictionary = FIN_DEF.duplicate(true)
	if FIN_DATA.has(ccode):
		for k in FIN_DATA[ccode]:
			d[k] = FIN_DATA[ccode][k]
	return d


func fin_rn() -> float:
	# грубо нормальный шум со средним 0 и разбросом ≈1
	return (randf() + randf() + randf() + randf() - 2.0) * 1.73


func fin_cr_mult() -> float:
	return float(FIN_CR_MULT[clampi(int(game_opts.get("fincr", 1)), 0, 2)])


func fin_cd(k: String) -> int:
	return int((fin["cd"] as Dictionary).get(k, 0))


func fin_cd_set(k: String, m: int) -> void:
	(fin["cd"] as Dictionary)[k] = m


func fin_euro_member() -> bool:
	return bool(MACRO.get("euro", true))


# долг за вычетом половины суверенных фондов: на него смотрят рынки
func fin_ratio_net() -> float:
	var f: Dictionary = fin["fd"]
	return debt / maxf(gdp, 1.0) * 100.0 - 0.5 * (float(f["res"]) + float(f["pen"]) + float(f["own"]))


func fin_init() -> void:
	if ec.is_empty():
		return
	var d: Dictionary = fin_data()
	var reg: String = String(d["fx"])
	if fin_euro_member() and reg != "euro":
		reg = "euro"
	var cbi: float = float(d["cbi"])
	var fxs: float = float(ec["fxs"])
	fin = {
		"v": FIN_VER, "mood": 60.0, "mood_off": 0.0, "mood_t": 60.0, "since": turn, "cd": {}, "log": [], "est": d.get("est", []),
		"w": {"gold": 1.0, "usd": 1.0, "shock": 0.0},
		"cb": {"ind0": cbi, "ind": cbi, "law": 0.0, "dem0": democracy_index(), "head": "tech", "head_t": turn - 48, "cred": 60.0,
			"press": 0.0, "lobby": 0.0, "qe": 0.0, "infl0": inflation, "pull0": 0.0, "rate_old": float(ec["rate"]), "rate_up": 0.0, "emit_msg": -99},
		"fx": {"reg": reg, "anc": String(d["anc"]), "lvl": fxs, "band": float(d["band"]), "capctl": bool(d["capctl"]), "capctl_t": -99,
			"gold": float(d["gold"]), "mix_eur": float(d["mix_eur"]), "mix_usd": float(d["mix_usd"]), "mix_cny": float(d["mix_cny"]),
			"swap": 0.0, "swap_t": 0, "swap_by": "", "peg_t": turn if (reg == "peg" and String(d["anc"]) == "EUR") else -999, "imp": 0.0,
			"press": 0.0, "defended": 0.0, "crash_t": -999, "ft": fxs, "val": 0.0, "uni": reg == "euro" and not fin_euro_member(), "peg0": 0.0},
		"bk": {"car": float(d["car"]), "car0": float(d["car"]), "npl": float(d["npl"]), "npl0": float(d["npl"]), "cr": float(d["cr"]), "cr0": float(d["cr"]),
			"trust": 85.0, "ins": int(d["ins"]), "reg": int(d["reg"]), "bub_c": 0.0, "bub_h": 0.0, "shock": 0.0, "state": 0.0, "mh": 0.0,
			"cris": {"on": false, "kind": "", "left": 0.0, "sev": 0.0, "wait": 0.0, "start": -999}, "crunch": 0.0, "stress_t": -999, "stress_msg": "",
			"count": 0, "sov": 8.0, "rates": [], "pend": false},
		"ex": {"idx": 100.0, "fund": 100.0, "ma": 100.0, "bub": 0.0, "mcap": float(d["mcap"]), "tax": 0.0, "restr": false, "closed": 0.0,
			"ipo": 0.0, "ipo_t": -999, "crash_t": -999, "vol": 1.0, "ret_w": 0.0},
		"db": {"mat": float(d["mat"]), "avg": 0.0, "mkt": 0.0, "for": float(d["for"]), "for0": float(d["for"]), "fcur": float(d["fcur"]),
			"cover": 2.4, "auc_rate": 0.0, "auc_fail": 0, "auc_pen": 0.0, "auc_t": -99, "closed_t": -1, "ds": 0, "ds_t": -999, "haircut": 0.0,
			"rest": 0, "hot": 0.0, "spr": 0.0, "wait": 0.0, "ext": 0.0, "off": 0.0, "pend": false},
		"imf": {"st": 0, "tr": 0, "tr_n": 0, "tr_t": 0, "cond": [], "amt": 0.0, "since": 0, "fail": 0, "base_def": 0.0, "base_ret": 0, "base_tax": 0.0,
			"base_ipo": 0.0, "alt": "", "alt_rate": 0.0, "alt_amt": 0.0, "pend": false, "log": []},
		"fd": {"res": float(d["fd_res"]), "pen": float(d["fd_pen"]), "own": 0.0, "own_on": false,
			"rules": {"res": {"in_s": 100.0 if float(d["fd_res"]) > 0.0 else 0.0, "in_fix": 0.0, "out": "crisis"},
				"pen": {"in_s": 0.0, "in_fix": 0.3 if float(d["fd_pen"]) > 0.0 else 0.0, "out": "never"},
				"own": {"in_s": 50.0, "in_fix": 0.0, "out": "crisis"}}},
		"h": {"mood": [], "car": [], "npl": [], "idx": [], "spr": [], "fxs": [], "rate": [], "cr": [], "res": [], "for": []},
	}
	var db: Dictionary = fin["db"]
	db["mkt"] = debt_mkt_rate()
	db["avg"] = float(db["mkt"])
	fin["bk"]["sov"] = clampf(6.0 + maxf(0.0, debt / maxf(gdp, 1.0) * 100.0 - 50.0) * 0.08, 4.0, 22.0)
	fin["cb"]["pull0"] = fin_cb_pull()
	fin["cb"]["cred"] = fin_cred_anchor()
	var rule0: float = cb_rule()
	if reg == "peg" or (reg == "corr" and float(d["band"]) <= 0.06):
		fin["fx"]["peg0"] = (fin_ecb_rate() + 0.3 - rule0) * 0.6
	fin["mood_off"] = 0.0
	fin["mood_off"] = 60.0 - fin_mood_raw()
	fin["fx"]["last"] = fxs


func fin_note(sec: String, text: String, col: String = "") -> void:
	var lg: Array = fin["log"]
	lg.append({"d": date_text(), "s": sec, "t": text, "c": col if col != "" else COL_DIM})
	while lg.size() > 60:
		lg.pop_front()
	log_tag("ФИНАНСЫ", col if col != "" else COL_DIM, text)


# решение игрока в виде окна события (общее для кризисов банков, дефолта, МВФ, смены главы ЦБ)
func fin_event(kind: String, text: String, opts: Array) -> void:
	if not current_event.is_empty() or election_open or game_over:
		return
	current_event = {"t": text, "special": "fin", "fk": kind, "o": opts}
	event_region = -1
	if observer or opp_mode:
		log_tag("НАБЛЮДАТЕЛЬ" if observer else "ФИНАНСЫ", COL_TEAL, "%s — решение: «%s»." % [text.left(120), opts[0]["l"]])
		choose(0)
		return
	present_event()


func fin_resolve(opt: Dictionary) -> void:
	if not fin_on():
		return
	fin_apply_act(String(opt.get("act", "")), opt)


# ============================================================
#  ЕЖЕНЕДЕЛЬНЫЙ РАСЧЁТ
# ============================================================
func fin_week() -> void:
	if game_over or ec.is_empty():
		return
	if fin.is_empty():
		if int(game_opts.get("finlev", 1)) <= 0:
			return
		fin_init()      # старое сохранение без финансового модуля
	if not fin_on():
		return
	fin_world_step()
	fin_cb_step()
	fin_fx_step()
	fin_bank_step()
	fin_ex_step()
	fin_debt_step()
	fin_fund_step()
	fin_imf_step()
	fin_mood_step()
	if wmonth:
		fin_month()


func fin_month() -> void:
	var cdm: Dictionary = fin["cd"]
	for k in cdm.keys():
		cdm[k] = maxi(0, int(cdm[k]) - 1)
	fin_hist_push()
	fin_month_cb()
	fin_month_bank()
	fin_month_debt()


func fin_hist_push() -> void:
	var h: Dictionary = fin["h"]
	var b: Dictionary = fin["bk"]
	var vals := {"mood": float(fin["mood"]), "car": float(b["car"]), "npl": float(b["npl"]), "idx": float(fin["ex"]["idx"]),
		"spr": float(fin["db"]["spr"]), "fxs": float(ec["fxs"]) * 100.0, "rate": float(ec["rate"]), "cr": float(b["cr"]),
		"res": float(ec["res"]), "for": float(fin["db"]["for"])}
	for k in vals:
		var a: Array = h[k]
		a.append(float(vals[k]))
		while a.size() > FIN_HIST_MAX:
			a.pop_front()


# ---------- мировые финансовые факторы: золото, доллар, шоки ----------
func fin_world_step() -> void:
	var w: Dictionary = fin["w"]
	var sq: float = sqrt(wdt)
	var g0: float = float(w["gold"])
	var u0: float = float(w["usd"])
	w["gold"] = clampf(g0 + (1.0 - g0) * rt(0.02, wdt) + fin_rn() * 0.012 * sq + float(w["shock"]) * 0.01 * wdt, 0.5, 2.5)
	w["usd"] = clampf(u0 + (1.0 - u0) * rt(0.02, wdt) + fin_rn() * 0.008 * sq + float(w["shock"]) * 0.004 * wdt, 0.7, 1.4)
	w["dg"] = float(w["gold"]) / g0 - 1.0
	w["du"] = float(w["usd"]) / u0 - 1.0
	w["shock"] = float(w["shock"]) * wdec(0.93)
	if randf() < wp(0.0083 * fin_cr_mult()):
		w["shock"] = minf(1.0, float(w["shock"]) + randf_range(0.4, 0.9))
		fin_note("мир", "Мировой финансовый шок: инвесторы уходят от риска, дорожают золото и займы, падают биржи.", COL_BAD)


# ---------- доверие рынков ----------
func fin_mood_raw() -> float:
	var cb: Dictionary = fin["cb"]
	var db: Dictionary = fin["db"]
	var imf: Dictionary = fin["imf"]
	var r := 60.0
	r += 3.0 * clampf(growth - G_NEU, -4.0, 4.0)
	r -= 0.18 * maxf(0.0, fin_ratio_net() - 60.0)
	r -= 6.0 * risk_prem
	r -= 1.5 * maxf(0.0, (last_deficit_pct if absf(last_deficit_pct) > 0.0001 else def0) - 3.0)
	r -= 1.2 * maxf(0.0, inflation - 4.0)
	r += 0.25 * (float(cb["cred"]) - 60.0)
	r -= 9.0 * float(fin["bk"]["crunch"])
	r -= 10.0 * float(fin["w"]["shock"])
	r -= 22.0 * float(db["hot"])
	if int(imf["st"]) == 2:
		r += 6.0
	if bool(fin["fx"]["capctl"]):
		r -= 5.0
	if fin_euro_member():
		r += 4.0
	return r


func fin_mood_step() -> void:
	var t: float = clampf(fin_mood_raw() + float(fin["mood_off"]), 3.0, 97.0)
	fin["mood_t"] = t
	fin["mood"] = clampf(float(fin["mood"]) + (t - float(fin["mood"])) * rt(0.12, wdt), 2.0, 98.0)


func fin_mood_hit(v: float) -> void:
	fin["mood"] = clampf(float(fin["mood"]) + v, 2.0, 98.0)


# ============================================================
#  ХУКИ В ЭКОНОМИКУ (вызываются из macro_step, cb_target, ec_budget_lines, debt_rate)
# ============================================================
func fin_g() -> float:
	if not fin_on():
		return 0.0
	var b: Dictionary = fin["bk"]
	var ex: Dictionary = fin["ex"]
	var db: Dictionary = fin["db"]
	var imf: Dictionary = fin["imf"]
	var g := 0.0
	g += clampf((float(b["cr"]) / maxf(1.0, float(b["cr0"])) - 1.0) * 2.0, -0.5, 0.5)
	g -= 1.1 * float(b["crunch"])
	g -= 0.03 * float(b["state"]) * 0.1
	if bool(fin["fx"]["capctl"]):
		g -= 0.2
	if int(db["closed_t"]) > turn:
		g -= 0.8
	g -= 0.8 * float(db["hot"])
	g += clampf((float(ex["idx"]) / maxf(1.0, float(ex["ma"])) - 1.0) * 1.5, -0.4, 0.4)
	if float(ex["closed"]) > 0.0:
		g -= 0.15
	if int(imf["st"]) == 2:
		g -= 0.25
	g += clampf((float(fin["mood"]) - 60.0) * 0.006, -0.3, 0.3)
	g += 0.003 * float(fin["cb"]["qe"])
	return g


func fin_infl() -> float:
	if not fin_on():
		return 0.0
	var cb: Dictionary = fin["cb"]
	var b: Dictionary = fin["bk"]
	var t := 0.0
	t += float(fin["fx"]["imp"])
	t += 0.02 * float(cb["qe"])
	t += clampf((float(b["cr"]) / maxf(1.0, float(b["cr0"])) - 1.0) * 1.0, -0.3, 0.4)
	t += maxf(0.0, 50.0 - float(cb["cred"])) * 0.004
	t += float(fin["db"]["emit"]) if fin["db"].has("emit") else 0.0
	return t


func fin_unemp() -> float:
	if not fin_on():
		return 0.0
	var b: Dictionary = fin["bk"]
	var u := 0.0
	u += 1.0 * float(b["crunch"]) * (1.0 + float((b["cris"] as Dictionary)["sev"]) * 0.3)
	u += 0.6 * float(fin["db"]["hot"])
	if int(fin["db"]["closed_t"]) > turn:
		u += 0.3
	return u


# дополнительные статьи бюджета (налог на биржевые сделки)
func fin_budget_lines() -> Dictionary:
	var out := {"rev": {}, "exp": {}}
	if not fin_on():
		return out
	var ex: Dictionary = fin["ex"]
	var tx: float = float(ex["tax"])
	if tx > 0.0 and float(ex["closed"]) <= 0.0:
		out["rev"]["Налог на биржевые сделки"] = gdp * fin_tx_rev()
	return out


# доход от налога на сделки, доля ВВП в год
func fin_tx_rev() -> float:
	var ex: Dictionary = fin["ex"]
	var tx: float = float(ex["tax"])
	var turnover: float = float(ex["mcap"]) / 100.0 * float(ex["idx"]) / 100.0 * 1.4 * maxf(0.2, 1.0 - tx * 1.2)
	return tx / 100.0 * turnover


# ============================================================
#  ДЕЙСТВИЯ ИГРОКА
# ============================================================
# страницы: "cb", "fx", "bank", "ex", "debt", "fund"; каждое действие: id, name, desc, cap (цена в капитале), ok, why, grp
func fin_acts(page: String) -> Array:
	var out: Array = []
	if not fin_on():
		return out
	match page:
		"cb":
			out = fin_acts_cb()
		"fx":
			out = fin_acts_fx()
		"bank":
			out = fin_acts_bank()
		"ex":
			out = fin_acts_ex()
		"debt":
			out = fin_acts_debt()
		"fund":
			out = fin_acts_fund()
	for a in out:
		if not a.has("ok"):
			a["ok"] = true
			a["why"] = ""
		if bool(a["ok"]):
			var cdk: String = String(a["id"])
			if fin_cd(cdk) > 0:
				a["ok"] = false
				a["why"] = "перерыв %d мес." % fin_cd(cdk)
			elif cap_spendable() < float(a.get("cap", 0.0)):
				a["ok"] = false
				a["why"] = "не хватает капитала (нужно %.0f)" % float(a["cap"])
	return out


func fin_do(id: String) -> bool:
	if pl_deny() or not fin_on() or observer or not current_event.is_empty():
		return false
	var found: Dictionary = {}
	for pg in FIN_PAGES:
		for a in fin_acts(pg):
			if String(a["id"]) == id:
				found = a
	if found.is_empty() or not bool(found["ok"]):
		return false
	capital -= float(found.get("cap", 0.0))
	if found.has("cd"):
		fin_cd_set(id, int(found["cd"]))
	fin_apply_act(id, found)
	return true


# ============================================================
#  ТЕКСТЫ ДЛЯ ИНТЕРФЕЙСА
# ============================================================
func fin_col(v: float, lo: float, hi: float, high_good: bool = true) -> String:
	# цвет показателя: хорошо / нормально / плохо
	var good: bool = v >= hi if high_good else v <= lo
	var bad: bool = v <= lo if high_good else v >= hi
	return COL_GOOD if good else (COL_BAD if bad else COL_WARN)


func fin_mood_text() -> String:
	var m: float = float(fin["mood"])
	return "высокое" if m >= 70.0 else ("нормальное" if m >= 50.0 else ("тревожное" if m >= 35.0 else "паника"))


func fin_est_note(k: String) -> String:
	return " (оценка)" if k in (fin["est"] as Array) else ""


func fin_chip_text() -> String:
	# строка для верхней панели: курс, ставка, доверие рынков
	if not fin_on():
		return ""
	return "курс %.0f · ставка %.1f%% · доверие %s" % [float(ec["fxs"]) * 100.0, float(ec["rate"]), fin_mood_text()]
