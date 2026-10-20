# Реализм (v44_1): блоки и союзы (ЕС, евро, НАТО, Шенген), демография и пенсии, энергия и климат,
# правовое государство и коррупция, СМИ, региональное выравнивание.
# Состояние — словарь rl. Все числа настраиваются константами ниже. Опция game_opts["rlev"]=0 отключает модуль целиком (эталоны golden).
# Действия игрока — общий список rl_acts(page) / rl_do(id): окно «Государство и мир» только показывает их.
extends "res://scripts/logic/intorg.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func diplo_resolve(opt: Dictionary) -> void:
	pass


func sv_auto() -> void:
	pass


# --- конец заглушек ---


# ---------- реальные стартовые данные по 34 странам (≈2023) ----------
const RL_EU := ["DE", "FR", "NL", "BE", "LU", "AT", "CZ", "DK", "ES", "IT", "PL", "PT", "SE", "SI", "SK", "HU", "FI", "HR", "BG", "RO", "GR", "EE", "LV", "LT", "IE"]
const RL_EURO := ["DE", "FR", "NL", "BE", "LU", "AT", "ES", "IT", "PT", "SI", "SK", "FI", "HR", "GR", "EE", "LV", "LT", "IE"]
const RL_SCHENGEN := ["DE", "FR", "NL", "BE", "LU", "AT", "CZ", "DK", "ES", "IT", "PL", "PT", "SE", "SI", "SK", "HU", "FI", "HR", "BG", "RO", "GR", "EE", "LV", "LT", "CH", "NO"]
const RL_CPI := {"DE": 78, "FR": 71, "NL": 79, "BE": 73, "LU": 78, "AT": 71, "CH": 82, "CZ": 54, "DK": 90, "ES": 60, "IT": 56, "NO": 84, "PL": 54, "PT": 61,
	"SE": 82, "GB": 71, "IE": 77, "SI": 56, "SK": 54, "HU": 42, "FI": 87, "HR": 47, "RS": 36, "BA": 35, "ME": 46, "MK": 40, "AL": 37, "XK": 41, "BG": 45,
	"RO": 46, "GR": 49, "EE": 76, "LV": 60, "LT": 62}
const RL_JUD := {"HU": -10.0, "PL": -6.0, "RS": -8.0, "BA": -6.0, "AL": -4.0, "BG": -3.0, "RO": -3.0, "XK": -4.0, "MK": -4.0, "IT": -2.0}
const RL_AGE := {"DE": 22.0, "FR": 21.5, "NL": 20.0, "BE": 19.5, "LU": 15.0, "AT": 19.5, "CH": 19.0, "CZ": 21.0, "DK": 20.0, "ES": 20.5, "IT": 24.0, "NO": 18.0,
	"PL": 19.5, "PT": 24.0, "SE": 20.0, "GB": 19.0, "IE": 15.0, "SI": 21.5, "SK": 18.5, "HU": 20.5, "FI": 23.0, "HR": 22.0, "RS": 21.5, "BA": 18.0,
	"ME": 16.0, "MK": 15.0, "AL": 16.0, "XK": 9.0, "BG": 22.5, "RO": 19.5, "GR": 23.5, "EE": 20.0, "LV": 21.0, "LT": 21.0}
const RL_TFR := {"DE": 1.46, "FR": 1.68, "NL": 1.43, "BE": 1.43, "LU": 1.38, "AT": 1.32, "CH": 1.33, "CZ": 1.45, "DK": 1.5, "ES": 1.19, "IT": 1.2, "NO": 1.4,
	"PL": 1.2, "PT": 1.38, "SE": 1.45, "GB": 1.55, "IE": 1.55, "SI": 1.55, "SK": 1.57, "HU": 1.5, "FI": 1.32, "HR": 1.5, "RS": 1.5, "BA": 1.4, "ME": 1.7,
	"MK": 1.5, "AL": 1.4, "XK": 1.8, "BG": 1.8, "RO": 1.7, "GR": 1.3, "EE": 1.4, "LV": 1.5, "LT": 1.2}
const RL_PRESS := {"DE": 81, "FR": 76, "NL": 82, "BE": 81, "LU": 81, "AT": 75, "CH": 82, "CZ": 78, "DK": 89, "ES": 71, "IT": 70, "NO": 95, "PL": 68, "PT": 83,
	"SE": 88, "GB": 71, "IE": 85, "SI": 73, "SK": 71, "HU": 55, "FI": 88, "HR": 63, "RS": 55, "BA": 63, "ME": 58, "MK": 57, "AL": 60, "XK": 55, "BG": 60,
	"RO": 65, "GR": 54, "EE": 89, "LV": 78, "LT": 77}
const RL_ENDEP := {"DE": 68, "FR": 45, "NL": 70, "BE": 78, "LU": 92, "AT": 60, "CH": 70, "CZ": 38, "DK": 35, "ES": 68, "IT": 74, "NO": 5, "PL": 40, "PT": 70,
	"SE": 30, "GB": 35, "IE": 80, "SI": 45, "SK": 60, "HU": 60, "FI": 40, "HR": 55, "RS": 35, "BA": 30, "ME": 30, "MK": 50, "AL": 30, "XK": 20, "BG": 40,
	"RO": 30, "GR": 70, "EE": 25, "LV": 55, "LT": 70}
const RL_GREEN := {"DE": 58, "FR": 92, "NL": 45, "BE": 70, "LU": 80, "AT": 85, "CH": 95, "CZ": 55, "DK": 80, "ES": 70, "IT": 50, "NO": 98, "PL": 30, "PT": 75,
	"SE": 98, "GB": 65, "IE": 45, "SI": 70, "SK": 85, "HU": 70, "FI": 90, "HR": 65, "RS": 30, "BA": 40, "ME": 55, "MK": 30, "AL": 100, "XK": 10, "BG": 55,
	"RO": 65, "GR": 50, "EE": 40, "LV": 70, "LT": 65}

const RL_CONSTR := ["DE", "ES", "HU", "PL", "SI", "BE", "AL"]   # конструктивный вотум недоверия
const RL_HIST_MAX := 480
# уровни программ (0–3): семья, миграция, пенсионный возраст, зелёный переход, запасы газа, выравнивание регионов
const RL_LEVELS := ["fam", "imm", "ret", "grn", "gas", "eq"]



# 0.58: независимость судов (для конституционного контроля в laws.gd)
func rl_jud() -> float:
	return float((rl["l"] as Dictionary)["jud"]) if rl_on() else 50.0


func rl_on() -> bool:
	return not rl.is_empty() and int(game_opts.get("rlev", 1)) > 0


# ============================================================
#  ИНИЦИАЛИЗАЦИЯ
# ============================================================
func rl_init() -> void:
	rl = {}
	var cc: String = ccode
	var cpi: float = float(RL_CPI.get(cc, 55))
	var age0: float = float(RL_AGE.get(cc, 20.0))
	rl = {
		"b": {"eu": cc in RL_EU, "euro": cc in RL_EURO, "nato": cc in MIL_NATO, "schg": cc in RL_SCHENGEN, "ctrl": false},
		"acc": {}, "edp": 0, "natop": 0, "defe": 0.0, "debt_prev": debt,
		"d": {"age": age0, "age0": age0, "tfr": float(RL_TFR.get(cc, 1.5)), "tfr0": float(RL_TFR.get(cc, 1.5)), "pen": 0.0},
		"e": {"dep": float(RL_ENDEP.get(cc, 50)), "green": float(RL_GREEN.get(cc, 50)), "price": 100.0, "clim": 20.0, "shock": 0},
		"l": {"jud": clampf(cpi + float(RL_JUD.get(cc, 0.0)), 5.0, 98.0), "cor": clampf(100.0 - cpi, 2.0, 95.0), "scand": 0, "anti": 0, "j0": 0.0, "cx": 0.0, "dem0": democracy_index()},
		"m": {"free": float(RL_PRESS.get(cc, 65)), "tgt": float(RL_PRESS.get(cc, 65)), "trust": 55.0, "state": 0, "fake": 0.0},
		"lv": {"fam": 0, "imm": 1, "ret": 0, "grn": 0, "gas": 0, "eq": 0},
		"cd": {}, "g": 0.0, "inf": 0.0, "log": [], "pend": [],
		"h": {"age": [], "tfr": [], "cor": [], "jud": [], "free": [], "price": [], "green": [], "clim": [], "gdp": [], "debt": [], "appr": [], "unemp": [], "infl": [], "growth": []},
	}
	nato_ovr = 1 if bool(rl["b"]["nato"]) else 0
	noc_constr = cc in RL_CONSTR and int(game_opts.get("rlev", 1)) > 0
	var l0: Dictionary = rl["l"]
	l0["j0"] = float(l0["jud"])
	l0["cx"] = float(l0["cor"]) - (100.0 - (0.6 * float(l0["jud"]) + 0.4 * float(rl["m"]["free"])))
	free_adj = 0.0
	rl_rec_hist()


func rl_log(text: String, col: String = "") -> void:
	var lg: Array = rl["log"]
	lg.append("%s: %s" % [date_text(), text])
	while lg.size() > 40:
		lg.pop_front()
	log_tag("ГОСУДАРСТВО", col if col != "" else COL_DIM, text)


func rl_cd_get(k: String) -> int:
	return int((rl["cd"] as Dictionary).get(k, 0))


func rl_cd_set(k: String, m: int) -> void:
	(rl["cd"] as Dictionary)[k] = m


func rl_rec_hist() -> void:
	var h: Dictionary = rl["h"]
	var d: Dictionary = rl["d"]
	var e: Dictionary = rl["e"]
	var l: Dictionary = rl["l"]
	var m: Dictionary = rl["m"]
	var vals := {"age": d["age"], "tfr": d["tfr"], "cor": l["cor"], "jud": l["jud"], "free": m["free"], "price": e["price"], "green": e["green"], "clim": e["clim"],
		"gdp": gdp, "debt": debt / maxf(1.0, gdp) * 100.0, "appr": approval(), "unemp": unemployment, "infl": inflation, "growth": growth}
	for k in vals:
		var a: Array = h[k]
		a.append(float(vals[k]))
		if a.size() > RL_HIST_MAX:
			a.pop_front()


# ---------- хуки в экономику ----------
func rl_g() -> float:
	return float(rl.get("g", 0.0)) if rl_on() else 0.0


func rl_infl() -> float:
	return float(rl.get("inf", 0.0)) if rl_on() else 0.0


# ============================================================
#  ЕЖЕМЕСЯЧНЫЙ ШАГ
# ============================================================
func realism_month() -> void:
	if not rl_on():
		return
	var cd: Dictionary = rl["cd"]
	for k in cd.keys():
		cd[k] = int(cd[k]) - 1
		if int(cd[k]) <= 0:
			cd.erase(k)
	rl["g"] = 0.0
	rl["inf"] = 0.0
	rl_blocs_step()
	rl_demo_step()
	rl_energy_step()
	rl_law_step()
	rl_media_step()
	rl_region_step()
	rl_parl_step()
	rl_pending_step()
	rl_events()
	rl_rec_hist()
	sv_auto()


# ---------- А1. Блоки и союзы ----------
func rl_pc() -> float:
	# ВВП на душу, тыс. € (по данным мира)
	var w: Dictionary = WORLD.get(ccode, {})
	return gdp / maxf(0.1, float(w.get("pop", pop0)))


func rl_deficit_ema() -> float:
	return float(rl["defe"])


func rl_blocs_step() -> void:
	var b: Dictionary = rl["b"]
	var dpct: float = (debt - float(rl["debt_prev"])) / maxf(1.0, gdp) * 1200.0
	rl["debt_prev"] = debt
	rl["defe"] = float(rl["defe"]) * 0.9 + clampf(dpct, -15.0, 15.0) * 0.1
	var ratio: float = debt / maxf(1.0, gdp) * 100.0
	if bool(b["eu"]):
		rl["g"] = float(rl["g"]) + 0.12
		if bool(rl.get("eu_rebate", false)):
			debt -= gdp * 0.05 / 100.0 / 12.0
		var pc: float = rl_pc()
		if pc < 35.0:
			# структурные фонды: бедные члены получают долю ВВП
			debt -= gdp * (35.0 - pc) / 35.0 * 0.5 / 100.0 / 12.0
		# процедура чрезмерного дефицита: дефицит выше 3% при долге выше 60% дольше года
		if float(rl["defe"]) > 3.0 and ratio > 60.0:
			rl["edp"] = int(rl["edp"]) + 1
			if int(rl["edp"]) % 12 == 0:
				debt += gdp * 0.05 / 100.0
				add_support("Бизнес", -1.0)
				dip_all(-1.0, true)
				rl_log("Брюссель открыл процедуру чрезмерного дефицита: штраф 0,05% ВВП, партнёры недовольны.", COL_WARN)
		else:
			rl["edp"] = maxi(0, int(rl["edp"]) - 1)
	if bool(b["schg"]):
		if bool(b["ctrl"]):
			rl["g"] = float(rl["g"]) - 0.06
			rl["inf"] = float(rl["inf"]) + 0.02
		else:
			rl["g"] = float(rl["g"]) + 0.08
	if bool(b["nato"]) and mil_on():
		if mil_spend_ratio() < 0.85:
			rl["natop"] = int(rl["natop"]) + 1
			if int(rl["natop"]) % 12 == 0:
				dip_all(-1.5, false)
				rl_log("Союзники по НАТО требуют выполнять обязательства по расходам на оборону: отношения ухудшаются.", COL_WARN)
		else:
			rl["natop"] = maxi(0, int(rl["natop"]) - 1)
	# заявки на вступление
	var acc: Dictionary = rl["acc"]
	for k in acc.keys():
		var a: Dictionary = acc[k]
		var met := 0
		var need := 4
		if k == "eu":
			met += (1 if float((rl["l"] as Dictionary)["cor"]) <= 55.0 else 0) + (1 if democracy_index() >= 0.5 else 0) + (1 if float(rl["defe"]) <= 3.0 else 0) + (1 if ratio <= 90.0 else 0)
		elif k == "euro":
			met += (1 if inflation <= 3.5 else 0) + (1 if float(rl["defe"]) <= 3.0 else 0) + (1 if ratio <= 70.0 else 0) + (1 if risk_prem <= 1.5 else 0)
		else:
			met += (1 if mil_spend_ratio() >= 0.95 else 0) + (1 if democracy_index() >= 0.5 else 0) + (1 if rl_avg_rel() >= 45.0 else 0) + (1 if float((rl["l"] as Dictionary)["cor"]) <= 60.0 else 0)
		a["met"] = met
		a["p"] = maxf(0.0, float(a["p"]) + (float(met) / float(need)) * 1.2 - 0.25)
		a["m"] = int(a["m"]) + 1
		var goal: float = {"eu": 40.0, "euro": 24.0, "nato": 18.0}.get(k, 30.0)
		if float(a["p"]) >= goal:
			if fa_ws_lvl() > 0:
				if int(a["m"]) % 6 == 0:
					rl_log("Заявка (%s) заморожена: против страны действуют санкции Запада." % rl_bloc_name(String(k)), COL_WARN)
			elif rl_avg_rel() < 40.0:
				if int(a["m"]) % 6 == 0:
					rl_log("Заявка (%s) заблокирована одним из партнёров: улучшайте отношения." % rl_bloc_name(String(k)), COL_WARN)
			else:
				rl_accept(String(k))
				acc.erase(k)


func rl_avg_rel() -> float:
	var s := 0.0
	var n := 0
	for c in dip:
		s += float(dip[c]["rel"])
		n += 1
	return s / float(n) if n > 0 else 50.0


func rl_bloc_name(k: String) -> String:
	return {"eu": "Евросоюз", "euro": "еврозона", "nato": "НАТО", "schg": "Шенген"}.get(k, k)


func rl_accept(k: String) -> void:
	var b: Dictionary = rl["b"]
	if k == "eu":
		b["eu"] = true
		MACRO["eu"] = true
		if WORLD.has(ccode):
			WORLD[ccode]["eu"] = true
		if ccode in RL_SCHENGEN:
			b["schg"] = true
		add_all_support(2.0)
		dip_all(4.0, true)
		rl_log("Страна принята в Евросоюз! Рынок, фонды и правила ЕС теперь для вас.", COL_GOOD)
		fa_notify("join", "eu", 1.0)
	elif k == "euro":
		b["euro"] = true
		MACRO["euro"] = true
		add_all_support(1.0)
		rl_log("Страна перешла на евро: собственная эмиссия закрыта, зато растёт доверие инвесторов.", COL_GOOD)
		risk_prem = maxf(0.0, risk_prem - 0.4)
	elif k == "nato":
		b["nato"] = true
		nato_ovr = 1
		var nl: Array = mil.get("neutral", []) if not mil.is_empty() else []
		nl.erase(ccode)
		if not mil.is_empty():
			mil["neutral"] = nl
		add_support("Силовики", 3.0)
		dip_all(2.0, false)
		rl_log("Страна принята в НАТО: гарантии безопасности по статье 5 теперь и для вас.", COL_GOOD)
		fa_notify("join", "nato", 1.0)


# ---------- А3. Демография ----------
func rl_demo_step() -> void:
	var d: Dictionary = rl["d"]
	var lv: Dictionary = rl["lv"]
	var tfr_t: float = float(d["tfr0"]) + float(lv["fam"]) * 0.12
	d["tfr"] = float(d["tfr"]) + (tfr_t - float(d["tfr"])) * 0.012
	# старение: базовый темп 0,017 п.п./мес., ускоряется низкой рождаемостью, замедляется миграцией
	var da: float = 0.017 + (1.7 - float(d["tfr"])) * 0.006 - float(int(lv["imm"]) - 1) * 0.004
	d["age"] = clampf(float(d["age"]) + da, 5.0, 45.0)
	var over: float = float(d["age"]) - float(d["age0"])
	var relief: float = 1.0 - float(lv["ret"]) * 0.15
	var pen: float = maxf(0.0, over) * 0.30 * relief
	d["pen"] = pen
	debt += gdp * pen / 100.0 / 12.0
	debt += gdp * float(lv["fam"]) * 0.22 / 100.0 / 12.0
	if int(lv["imm"]) > 1:
		debt += gdp * float(int(lv["imm"]) - 1) * 0.04 / 100.0 / 12.0
	rl["g"] = float(rl["g"]) - maxf(0.0, over) * 0.05 + float(int(lv["imm"]) - 1) * 0.06 + float(lv["ret"]) * 0.03
	# напряжение вокруг миграции питает волну протестов
	if int(lv["imm"]) >= 3 and rv_on():
		var nat: Dictionary = rv["nat"]
		nat["wave"] = rv_clamp(float(nat["wave"]) + 0.25)


# ---------- А4. Энергия и климат ----------
func rl_energy_step() -> void:
	var e: Dictionary = rl["e"]
	var lv: Dictionary = rl["lv"]
	var p: float = float(e["price"])
	# цена энергоносителей возвращается к 100, случайно колеблется; запасы газа гасят скачки
	p += (100.0 - p) * 0.05 + randf_range(-3.0, 3.0) * (1.0 - float(lv["gas"]) * 0.2)
	if int(e["shock"]) > 0:
		e["shock"] = int(e["shock"]) - 1
	e["price"] = clampf(p, 60.0, 400.0)
	# зелёный переход: каждая ступень вкладывает 0,3% ВВП в год и добавляет ≈0,5 п.п. зелёной доли в месяц
	var gr: float = float(e["green"])
	if int(lv["grn"]) > 0:
		debt += gdp * 0.3 * float(lv["grn"]) / 100.0 / 12.0
		gr += 0.45 * float(lv["grn"])
		e["dep"] = maxf(2.0, float(e["dep"]) - 0.06 * float(lv["grn"]))
		rl["g"] = float(rl["g"]) + 0.02 * float(lv["grn"])
	if int(lv["gas"]) > 0:
		debt += gdp * 0.1 * float(lv["gas"]) / 100.0 / 12.0
	e["green"] = clampf(gr, 0.0, 100.0)
	var pr: float = float(e["price"]) - 100.0
	var dep: float = float(e["dep"]) * (1.0 - float(e["green"]) / 250.0)
	rl["inf"] = float(rl["inf"]) + pr * dep * 0.0004
	rl["g"] = float(rl["g"]) - pr * dep * 0.00012
	# климат: риск медленно растёт, зелёная доля его сдерживает
	e["clim"] = clampf(float(e["clim"]) + 0.03 * (1.0 - float(e["green"]) / 150.0), 0.0, 100.0)


# ---------- А5. Правовое государство и коррупция ----------
func rl_cor_add(v: float) -> void:
	# постоянный сдвиг коррупции (решения игрока, скандалы): меняет и текущее значение, и равновесие
	var l: Dictionary = rl["l"]
	l["cx"] = float(l["cx"]) + v
	l["cor"] = clampf(float(l["cor"]) + v, 1.0, 98.0)


func rl_law_step() -> void:
	var l: Dictionary = rl["l"]
	var cor: float = float(l["cor"])
	var jud: float = float(l["jud"])
	var fr: float = float(rl["m"]["free"])
	var dem: float = democracy_index()
	# независимость судов следует за демократией (от базового уровня), коррупция — за судами и свободой прессы
	var jt: float = float(l["j0"]) + (dem - float(l["dem0"])) * 60.0
	l["jud"] = clampf(jud + (jt - jud) * 0.01, 3.0, 99.0)
	var ct: float = 100.0 - (0.6 * jud + 0.4 * fr) + float(l["cx"])
	l["cor"] = clampf(cor + (ct - cor) * 0.015, 1.0, 98.0)
	cor = float(l["cor"])
	rl["g"] = float(rl["g"]) - cor * 0.0035 + jud * 0.0012
	debt += gdp * cor * 0.00002 / 12.0
	if rv_on():
		var nat: Dictionary = rv["nat"]
		nat["hate"] = rv_clamp(float(nat["hate"]) + maxf(0.0, cor - 45.0) * 0.004 - maxf(0.0, 35.0 - cor) * 0.002)


# ---------- А8. СМИ ----------
func rl_media_step() -> void:
	var m: Dictionary = rl["m"]
	var free: float = float(m["free"])
	var trust: float = float(m["trust"])
	var st: int = int(m["state"])
	if st > 0:
		# контроль над СМИ: рейтинг выше, но свобода и доверие падают
		trust = maxf(5.0, trust - 0.15 * float(st))
		add_all_support(0.05 * float(st))
	free = clampf(free + (float(m["tgt"]) - 20.0 * float(st) - free) * 0.02, 3.0, 99.0)
	# фейки растут при слабых СМИ и гаснут при независимых
	var fk: float = float(m["fake"])
	fk = clampf(fk + (55.0 - free) * 0.004 - 0.05 + (0.1 if inflation > 6.0 else 0.0), 0.0, 100.0)
	m["fake"] = fk
	trust = clampf(trust + (free - 50.0) * 0.003 - fk * 0.004, 5.0, 95.0)
	m["trust"] = trust
	m["free"] = free
	free_adj = (free - float(RL_PRESS.get(ccode, 65))) / 100.0 * 0.25
	rl["g"] = float(rl["g"]) - fk * 0.0015
	if rv_on() and fk > 30.0:
		var nat: Dictionary = rv["nat"]
		nat["wave"] = rv_clamp(float(nat["wave"]) + (fk - 30.0) * 0.004)


# ---------- А9. Региональное выравнивание ----------
func rl_region_step() -> void:
	if not rv_on() or regions.size() < 2:
		return
	var eq: int = int((rl["lv"] as Dictionary)["eq"])
	if eq > 0:
		debt += gdp * 0.25 * float(eq) / 100.0 / 12.0
	var avg_dev := 0.0
	for r in regions:
		avg_dev += float(r["dev"])
	avg_dev /= float(regions.size())
	for i in regions.size():
		var rg: Dictionary = rv_reg(i)
		var dev: float = float(regions[i]["dev"])
		var gap: float = (avg_dev - dev) / 50.0
		if eq > 0:
			if dev < avg_dev:
				# бедные регионы довольны трансфертами
				rg["hate"] = maxf(0.0, float(rg["hate"]) - 0.35 * float(eq) * clampf(gap, 0.0, 1.5))
				rg["sep"] = rv_clamp(float(rg["sep"]) - 0.12 * float(eq))
			else:
				# богатые платят за остальных и ропщут (Каталония, Фландрия, Ломбардия)
				rg["sep"] = rv_clamp(float(rg["sep"]) + 0.07 * float(eq) * clampf(-gap, 0.0, 1.5))
		elif dev > avg_dev + 6.0:
			rg["sep"] = rv_clamp(float(rg["sep"]) + 0.02)
		elif dev < avg_dev - 6.0:
			rg["hate"] = minf(100.0, float(rg["hate"]) + 0.03)


# ---------- А6. Парламент и президент ----------
func rl_cohab() -> bool:
	# сожительство: президент избран от партии вне правящей коалиции
	if String(ELEC.get("head", "")) != "direct" or opp_mode:
		return false
	if pres_party <= 0 or pres_party >= in_coalition.size():
		return false
	return not in_coalition[pres_party]


func rl_parl_step() -> void:
	if not rl_cohab():
		rl["cohab"] = 0
		return
	rl["cohab"] = int(rl.get("cohab", 0)) + 1
	capital -= 0.15
	if rl_cd_get("cohab") == 0 and current_event.is_empty() and not observer and randf() < 0.05:
		rl_cd_set("cohab", 18)
		rl_event("cohab", "Сожительство: президент из оппозиции отказался подписать назначения и вернул закон на доработку. Страна смотрит, кто уступит.", [
			{"l": "Пойти на компромисс: уступить в назначениях (капитал −3)", "fx": {"capital": -3.0}, "act": "coh_comp"},
			{"l": "Идти до конца: парламент преодолевает вето (капитал −6)", "fx": {"capital": -6.0}, "act": "coh_fight"},
			{"l": "Ждать, пока всё уляжется", "fx": {}, "act": "coh_wait"}])


# ============================================================
#  СОБЫТИЯ
# ============================================================
func rl_event(kind: String, text: String, opts: Array) -> void:
	if not current_event.is_empty() or election_open or game_over:
		return
	current_event = {"t": text, "special": "rl", "rlk": kind, "o": opts}
	event_region = -1
	if observer or opp_mode:
		log_tag("НАБЛЮДАТЕЛЬ" if observer else "ГОСУДАРСТВО", COL_TEAL, "%s — решение: «%s»." % [text, opts[0]["l"]])
		choose(0)
		return
	present_event()


func rl_events() -> void:
	if not current_event.is_empty() or election_open or game_over or opp_mode:
		return
	var e: Dictionary = rl["e"]
	var l: Dictionary = rl["l"]
	var m: Dictionary = rl["m"]
	var k: float = float(game_opts.get("rlev", 1)) * float(game_opts.get("ev", 1.0))
	if k <= 0.0:
		return
	# энергетический шок
	if rl_cd_get("shock") == 0 and randf() < 0.006 * k * (0.5 + float(e["dep"]) / 100.0):
		rl_cd_set("shock", 30)
		rl_event("shock", "Скачок цен на газ и нефть: поставщики сократили объёмы, биржи лихорадит. Промышленность и домохозяйства требуют помощи.", [
			{"l": "Субсидии на энергию (долг +0,8% ВВП)", "fx": {"debt": 0.8, "all": 1.0}, "act": "shock_sub"},
			{"l": "Открыть стратегические запасы и закупить газ у новых поставщиков (капитал −4)", "fx": {"capital": -4.0}, "act": "shock_div"},
			{"l": "Пусть рынок сам: цены вырастут", "fx": {"all": -1.5}, "act": "shock_none"}])
		return
	# климатическое бедствие
	if rl_cd_get("clim") == 0 and randf() < 0.0012 * k * (0.5 + float(e["clim"]) / 40.0):
		rl_cd_set("clim", 36)
		var kinds := ["засуха", "наводнение", "лесные пожары", "аномальная жара"]
		var kd: String = kinds[randi() % kinds.size()]
		rl_event("clim", "Климатическое бедствие: %s. Пострадали сельские районы, дороги и энергосети." % kd, [
			{"l": "Фонд помощи пострадавшим (долг +0,5% ВВП)", "fx": {"debt": 0.5, "support": {"Село": 3.0}}, "act": "clim_aid"},
			{"l": "Программа адаптации: плотины, лес, сети (долг +1% ВВП)", "fx": {"debt": 1.0, "support": {"Экологи": 3.0}}, "act": "clim_adapt"},
			{"l": "Ограничиться компенсациями (капитал −2)", "fx": {"capital": -2.0}, "act": "clim_min"}])
		return
	# коррупционный скандал
	if rl_cd_get("scand") == 0 and randf() < 0.004 * k * float(l["cor"]) / 40.0 * (0.6 + float(m["free"]) / 100.0):
		rl_cd_set("scand", 24)
		rl_event("scand", "Журналисты опубликовали расследование: министр и приближённые бизнесмены делили госзаказы. В парламенте требуют отставки.", [
			{"l": "Уволить министра и передать дело прокуратуре (капитал −3)", "fx": {"capital": -3.0, "all": -0.5}, "act": "scand_fire"},
			{"l": "Независимое расследование (капитал −6)", "fx": {"capital": -6.0}, "act": "scand_probe"},
			{"l": "Замять: «ложные обвинения»", "fx": {}, "act": "scand_hide"}])
		return
	# дезинформация
	if rl_cd_get("fake") == 0 and randf() < 0.004 * k * float(m["fake"]) / 40.0:
		rl_cd_set("fake", 24)
		rl_event("fake", "По соцсетям разошёлся фейк о правительстве: видео и «утечки», которых не было. Люди растеряны.", [
			{"l": "Опровержение через независимые СМИ и проверка фактов (капитал −3)", "fx": {"capital": -3.0}, "act": "fake_fact"},
			{"l": "Закон о блокировке «ложной информации» (капитал +3, свобода слова ниже)", "fx": {"capital": 3.0, "support": {"Молодёжь": -3.0}}, "act": "fake_ban"},
			{"l": "Не обращать внимания", "fx": {}, "act": "fake_ignore"}])
		return
	# демографический или миграционный вызов
	if rl_cd_get("demo") == 0 and float(rl["d"]["pen"]) > 0.8 and randf() < 0.01 * k:
		rl_cd_set("demo", 48)
		rl_event("demo", "Пенсионная система трещит: работающих всё меньше, пенсионеров всё больше. Эксперты просят решения.", [
			{"l": "Поднять пенсионный возраст на год (капитал −5)", "fx": {"capital": -5.0, "support": {"Пенсионеры": -5.0, "Бизнес": 2.0}}, "act": "demo_ret"},
			{"l": "Повысить пенсионные взносы (инфляция и безработица ↑)", "fx": {"support": {"Бизнес": -3.0, "Рабочие": -1.0}, "unemp": 0.2}, "act": "demo_tax"},
			{"l": "Занять и подождать (долг +1% ВВП)", "fx": {"debt": 1.0}, "act": "demo_debt"}])


func realism_resolve(opt: Dictionary) -> void:
	var act := String(opt.get("act", ""))
	var l: Dictionary = rl["l"]
	var e: Dictionary = rl["e"]
	var m: Dictionary = rl["m"]
	match act:
		"shock_sub":
			e["price"] = minf(float(e["price"]), 150.0)
			rl_log("энергетический шок смягчён субсидиями.", COL_WARN)
		"shock_div":
			e["dep"] = maxf(2.0, float(e["dep"]) - 4.0)
			e["price"] = 140.0
			rl_log("закуплены альтернативные поставки, зависимость от одного поставщика снижена.", COL_GOOD)
		"shock_none":
			e["price"] = 190.0 * (0.6 + float(e["dep"]) / 150.0)
			e["shock"] = 9
			rl_log("энергетический шок бьёт по ценам и промышленности.", COL_BAD)
		"clim_aid":
			rl_log("помощь пострадавшим от бедствия выплачена.", COL_WARN)
		"clim_adapt":
			e["clim"] = maxf(0.0, float(e["clim"]) - 8.0)
			rl_log("программа адаптации снизила климатические риски.", COL_GOOD)
		"clim_min":
			add_support("Село", -2.0)
		"scand_fire":
			rl_cor_add(-1.5)
			rl_log("скандал: министр уволен.", COL_WARN)
		"scand_probe":
			rl_cor_add(-4.0)
			l["jud"] = minf(99.0, float(l["jud"]) + 2.0)
			l["j0"] = float(l["j0"]) + 2.0
			add_all_support(0.8)
			rl_log("независимое расследование укрепило доверие к институтам.", COL_GOOD)
		"scand_hide":
			if randf() < 0.45 + (float(m["free"]) - 50.0) * 0.004:
				add_all_support(-3.0)
				rl_cor_add(2.0)
				rl_log("попытка замять скандал провалилась: утечка в СМИ ударила по рейтингу.", COL_BAD)
			else:
				rl_log("скандал удалось замять, но осадок остался.", COL_DIM)
		"fake_fact":
			m["fake"] = maxf(0.0, float(m["fake"]) - 12.0)
			m["trust"] = minf(95.0, float(m["trust"]) + 3.0)
		"fake_ban":
			m["fake"] = maxf(0.0, float(m["fake"]) - 8.0)
			m["free"] = maxf(5.0, float(m["free"]) - 5.0)
			m["tgt"] = float(m["tgt"]) - 5.0
			rl_log("закон о блокировке «ложной информации» принят; независимые СМИ жалуются на цензуру.", COL_WARN)
		"fake_ignore":
			m["fake"] = minf(100.0, float(m["fake"]) + 5.0)
		"demo_ret":
			(rl["lv"] as Dictionary)["ret"] = mini(3, int(rl["lv"]["ret"]) + 1)
		"demo_tax":
			rl["d"]["age0"] = float(rl["d"]["age0"]) + 0.5
		"demo_debt":
			pass
		"coh_comp":
			add_all_support(0.5)
			rl_log("компромисс с президентом: напряжение спало.", COL_DIM)
		"coh_fight":
			if randf() < 0.55:
				add_all_support(1.0)
				rl_log("парламент преодолел вето президента.", COL_GOOD)
			else:
				add_all_support(-1.5)
				rl_log("конфликт с президентом обернулся провалом: законы застряли.", COL_BAD)
		"coh_wait":
			add_all_support(-0.5)
		_:
			diplo_resolve(opt)


func rl_pending_step() -> void:
	# отложенные эффекты действий игрока (суды, антикоррупционное бюро): плавно за несколько месяцев
	var pend: Array = rl["pend"]
	for i in range(pend.size() - 1, -1, -1):
		var p: Dictionary = pend[i]
		var sec: String = String(p["sec"])
		var key: String = String(p["key"])
		var d: Dictionary = rl[sec]
		d[key] = clampf(float(d[key]) + float(p["step"]), -100.0 if key == "cx" else 0.0, 100.0)
		if p.has("key2"):
			d[String(p["key2"])] = float(d[String(p["key2"])]) + float(p["step"])
		p["left"] = int(p["left"]) - 1
		if int(p["left"]) <= 0:
			pend.remove_at(i)


# ============================================================
#  ДЕЙСТВИЯ ИГРОКА
# ============================================================
# страницы: "blocs", "demo", "energy", "law", "media", "region"
func rl_acts(page: String) -> Array:
	var out: Array = []
	if not rl_on():
		return out
	var b: Dictionary = rl["b"]
	var lv: Dictionary = rl["lv"]
	match page:
		"blocs":
			if not bool(b["eu"]):
				out.append({"id": "acc_eu", "name": "Подать заявку на вступление в ЕС", "cap": 8.0, "desc": "Критерии: коррупция не выше 55, демократия, дефицит ≤3%, долг ≤90% ВВП. Путь займёт около трёх лет при выполнении условий и тёплых отношениях с партнёрами."})
			elif not bool(b["euro"]):
				out.append({"id": "acc_euro", "name": "Начать переход на евро", "cap": 6.0, "desc": "Критерии: инфляция ≤3,5%, дефицит ≤3%, долг ≤70% ВВП, низкая премия за риск. После перехода эмиссия закрыта, зато доверие инвесторов выше."})
			if not bool(b["nato"]):
				out.append({"id": "acc_nato", "name": "Подать заявку в НАТО", "cap": 8.0, "desc": "Нужны расходы на армию не ниже стандартных, демократия и хорошие отношения с членами альянса. Дают гарантии статьи 5."})
			else:
				out.append({"id": "leave_nato", "name": "Выйти из НАТО", "cap": 12.0, "desc": "Нейтралитет: армия дешевле по влиянию союзников, но гарантий безопасности больше нет и отношения ухудшаются."})
			if bool(b["schg"]):
				out.append({"id": "ctrl", "name": ("Снять пограничный контроль" if bool(b["ctrl"]) else "Ввести пограничный контроль"), "cap": 2.0, "desc": "Контроль на границах снижает миграционное напряжение и нравится силовикам, но замедляет торговлю и туризм."})
		# v50: отдельные страницы Евросоюза и НАТО
		"eu":
			if bool(b["eu"]):
				out.append({"id": "eu_funds", "name": "Запросить деньги фонда восстановления (−0,3% ВВП долга)", "cap": 6.0, "cd": 24, "desc": "Брюссель выделяет средства на проекты, если в стране верховенство права: коррупция не выше 60."})
				out.append({"id": "eu_veto", "name": "Наложить вето на решение ЕС", "cap": 4.0, "cd": 12, "desc": "Защитить свои интересы: сторонники суверенитета довольны, партнёры по ЕС раздражены."})
				out.append({"id": "eu_rebate", "name": "Добиться скидки на взнос в бюджет ЕС", "cap": 8.0, "cd": 48, "desc": "Взнос меньше на 0,05% ВВП в год, но партнёры недовольны торгом."})
				out.append({"id": "eu_leave", "name": "Выйти из Евросоюза", "cap": 15.0, "desc": "Без единого рынка и фондов рост ниже, бизнес и молодёжь против; суверенитет радует часть избирателей. Уходит и евро, и Шенген."})
		"nato":
			if bool(b["nato"]):
				out.append({"id": "nato_ex", "name": "Принять учения НАТО", "cap": 4.0, "cd": 12, "desc": "Союзники ближе, силовики довольны; соперники альянса злятся."})
				out.append({"id": "nato_base", "name": "Разместить базу союзников", "cap": 8.0, "cd": 999, "desc": "Безопасность +3, сдерживание выше. Часть молодёжи против; Россия и Беларусь в ярости."})
		"demo":
			out.append({"id": "fam_up", "name": "Семейная политика +1 (расход +0,22% ВВП/год)", "cap": 3.0, "desc": "Пособия, детсады, жильё для семей: рождаемость растёт медленно, но верно.", "lv": "fam", "d": 1})
			out.append({"id": "fam_dn", "name": "Семейная политика −1", "cap": 0.0, "desc": "Сократить расходы.", "lv": "fam", "d": -1})
			out.append({"id": "imm_up", "name": "Привлекать мигрантов +1", "cap": 3.0, "desc": "Больше работников: рост и возраст населения улучшаются, но растёт напряжение и расходы на интеграцию.", "lv": "imm", "d": 1})
			out.append({"id": "imm_dn", "name": "Сдерживать миграцию −1", "cap": 2.0, "desc": "Меньше напряжения, но старение ускоряется.", "lv": "imm", "d": -1})
			out.append({"id": "ret_up", "name": "Пенсионная реформа +1 (возраст выхода выше)", "cap": 6.0, "desc": "Снижает давление на бюджет на 15%, но Пенсионеры недовольны.", "lv": "ret", "d": 1})
			out.append({"id": "ret_dn", "name": "Отменить часть пенсионной реформы", "cap": 3.0, "desc": "Пенсионеры довольны, бюджет страдает.", "lv": "ret", "d": -1})
		"energy":
			out.append({"id": "grn_up", "name": "Зелёный переход +1 (0,3% ВВП/год)", "cap": 4.0, "desc": "Солнце, ветер, сети и АЭС: зелёная доля растёт, зависимость от импорта и риск климата падают.", "lv": "grn", "d": 1})
			out.append({"id": "grn_dn", "name": "Замедлить зелёный переход −1", "cap": 1.0, "desc": "Дешевле сейчас, дороже потом.", "lv": "grn", "d": -1})
			out.append({"id": "gas_up", "name": "Стратегические запасы +1 (0,1% ВВП/год)", "cap": 2.0, "desc": "Сглаживают скачки цен на энергию.", "lv": "gas", "d": 1})
			out.append({"id": "gas_dn", "name": "Сократить запасы −1", "cap": 0.0, "desc": "Экономия за счёт безопасности.", "lv": "gas", "d": -1})
			out.append({"id": "diversify", "name": "Диверсифицировать поставщиков (−6 п.п. зависимости, долг +0,1% ВВП)", "cap": 4.0, "cd": 12, "desc": "Новые контракты и терминалы: меньше зависимость от одного поставщика."})
		"law":
			out.append({"id": "courts", "name": "Реформа судов (независимость +8 за 6 мес.)", "cap": 8.0, "cd": 24, "desc": "Прозрачный отбор судей, защита от давления. Часть элиты недовольна."})
			out.append({"id": "anti", "name": "Антикоррупционное бюро", "cap": 10.0, "cd": 36, "desc": "Независимое бюро: коррупция постоянно снижается. Расследования зацепят и ваших людей."})
			out.append({"id": "loyal", "name": "Назначить лояльных судей (капитал +6)", "cap": 0.0, "cd": 36, "desc": "Быстрая власть ценой независимости судов. Коррупция потом растёт."})
		"media":
			out.append({"id": "pub", "name": "Независимое общественное вещание (свобода +6)", "cap": 6.0, "cd": 24, "desc": "Финансирование без вмешательства власти: доверие и свобода прессы растут."})
			out.append({"id": "ctl_up", "name": "Усилить контроль над СМИ +1", "cap": 0.0, "desc": "Рейтинг власти чуть выше, но свобода и доверие падают, коррупция растёт.", "lv": "state", "d": 1})
			out.append({"id": "ctl_dn", "name": "Ослабить контроль над СМИ −1", "cap": 1.0, "desc": "Больше свободы, больше критики.", "lv": "state", "d": -1})
			out.append({"id": "fact", "name": "Центр проверки фактов (фейков −10)", "cap": 4.0, "cd": 12, "desc": "Общественный сервис против дезинформации."})
		"parl":
			out.append({"id": "coal_summit", "name": "Саммит коалиции: пересмотр коалиционного договора", "cap": 4.0, "cd": 12, "desc": "Встреча лидеров партнёров: довольство каждого партнёра по коалиции +8."})
		"region":
			out.append({"id": "eq_up", "name": "Выравнивание регионов +1 (0,25% ВВП/год)", "cap": 4.0, "desc": "Трансферты бедным регионам: растёт лояльность, но богатые регионы недовольны платежами.", "lv": "eq", "d": 1})
			out.append({"id": "eq_dn", "name": "Выравнивание регионов −1", "cap": 0.0, "desc": "Меньше трансфертов.", "lv": "eq", "d": -1})
	for a in out:
		a["ok"] = true
		a["why"] = ""
		var cdk: String = String(a["id"])
		if rl_cd_get(cdk) > 0:
			a["ok"] = false
			a["why"] = "перерыв %d мес." % rl_cd_get(cdk)
		elif cap_spendable() < float(a["cap"]):
			a["ok"] = false
			a["why"] = "не хватает капитала (нужно %.0f)" % float(a["cap"])
		elif a.has("lv"):
			var key: String = String(a["lv"])
			var cur: int = int(rl["m"]["state"]) if key == "state" else int(lv[key])
			var nv: int = cur + int(a["d"])
			if nv < 0 or nv > 3:
				a["ok"] = false
				a["why"] = "предел"
		elif String(a["id"]) in ["acc_eu", "acc_euro", "acc_nato"] and (rl["acc"] as Dictionary).has(String(a["id"]).substr(4)):
			a["ok"] = false
			a["why"] = "заявка уже подана"
	return out


func rl_do(id: String) -> bool:
	if pl_deny(): return false
	if not rl_on() or observer or not current_event.is_empty():
		return false
	var found: Dictionary = {}
	for pg in ["blocs", "eu", "nato", "demo", "energy", "law", "media", "region", "parl"]:
		for a in rl_acts(pg):
			if String(a["id"]) == id:
				found = a
	if found.is_empty() or not bool(found["ok"]):
		return false
	capital -= float(found["cap"])
	if found.has("cd"):
		rl_cd_set(id, int(found["cd"]))
	var b: Dictionary = rl["b"]
	var l: Dictionary = rl["l"]
	var m: Dictionary = rl["m"]
	var e: Dictionary = rl["e"]
	if found.has("lv"):
		var key: String = String(found["lv"])
		if key == "state":
			m["state"] = int(m["state"]) + int(found["d"])
			if int(found["d"]) > 0:
				rl_cor_add(2.0)
		else:
			(rl["lv"] as Dictionary)[key] = int(rl["lv"][key]) + int(found["d"])
			if key == "ret" and int(found["d"]) > 0:
				add_support("Пенсионеры", -5.0)
				add_support("Бизнес", 1.5)
			elif key == "ret":
				add_support("Пенсионеры", 3.0)
			elif key == "imm" and int(found["d"]) > 0:
				add_support("Бизнес", 1.0)
				add_support("Рабочие", -1.0)
			elif key == "imm":
				add_support("Бизнес", -1.0)
			elif key == "eq" and int(found["d"]) > 0:
				add_support("Бизнес", -0.5)
		rl_log("%s." % String(found["name"]).split(" (")[0], COL_DIM)
		return true
	match id:
		"acc_eu":
			(rl["acc"] as Dictionary)["eu"] = {"p": 0.0, "m": 0, "met": 0}
			rl_log("Подана заявка на вступление в ЕС.", COL_TEAL)
		"acc_euro":
			(rl["acc"] as Dictionary)["euro"] = {"p": 0.0, "m": 0, "met": 0}
			rl_log("Начата подготовка к евро.", COL_TEAL)
		"acc_nato":
			(rl["acc"] as Dictionary)["nato"] = {"p": 0.0, "m": 0, "met": 0}
			rl_log("Подана заявка на вступление в НАТО.", COL_TEAL)
		"leave_nato":
			b["nato"] = false
			nato_ovr = 0
			if not mil.is_empty():
				var nl: Array = mil.get("neutral", [])
				if not (ccode in nl):
					nl.append(ccode)
				mil["neutral"] = nl
			dip_all(-4.0, false)
			add_support("Силовики", -4.0)
			rl_log("Страна вышла из НАТО и объявила нейтралитет.", COL_WARN)
			fa_notify("leave_nato", "", 1.0)
		"eu_funds":
			if float(l["cor"]) > 60.0:
				dip_all(-1.0, true)
				rl_log("Брюссель отказал в деньгах: коррупция слишком высока (%.0f). Партнёры недовольны." % float(l["cor"]), COL_WARN)
			else:
				debt = maxf(0.0, debt - gdp * 0.3 / 100.0)
				add_support("Бизнес", 1.0)
				add_support("Село", 0.5)
				rl_log("Евросоюз выделил средства фонда восстановления (0,3% ВВП).", COL_GOOD)
		"eu_veto":
			dip_all(-2.0, true)
			add_support("Силовики", 1.0)
			add_support("Село", 0.5)
			add_support("Молодёжь", -0.5)
			rl_log("Вы заблокировали решение ЕС: дома это сочли защитой интересов, в Брюсселе — шантажом.", COL_WARN)
		"eu_rebate":
			rl["eu_rebate"] = true
			dip_all(-1.5, true)
			add_support("Бизнес", 0.5)
			rl_log("Взнос в бюджет ЕС снижен.", COL_GOOD)
		"eu_leave":
			b["eu"] = false
			b["euro"] = false
			b["schg"] = false
			dip_all(-6.0, true)
			add_support("Бизнес", -4.0)
			add_support("Молодёжь", -3.0)
			add_support("Силовики", 2.0)
			add_support("Село", 1.0)
			rl["g"] = float(rl["g"]) - 1.0
			rl_log("Страна вышла из Евросоюза: единый рынок, фонды и общие правила остались позади.", COL_BAD)
			fa_notify("leave_nato", "", 1.0)
		"nato_ex":
			dip_all(1.0, false)
			add_support("Силовики", 1.0)
			for foe in ["RU", "BY"]:
				if foe != ccode:
					ex_rel_change(foe, -3.0)
			rl_log("На вашей территории прошли учения НАТО.", COL_GOOD)
		"nato_base":
			rl["nato_base"] = true
			lvl["security_lvl"] = clampf(float(lvl["security_lvl"]) + 3.0, 0.0, 100.0)
			add_support("Силовики", 2.0)
			add_support("Молодёжь", -1.0)
			for foe in ["RU", "BY"]:
				if foe != ccode:
					ex_rel_change(foe, -10.0)
			rl_log("Размещена база союзников по НАТО.", COL_GOOD)
		"ctrl":
			b["ctrl"] = not bool(b["ctrl"])
			add_support("Силовики", 2.0 if bool(b["ctrl"]) else -1.0)
			rl_log("Пограничный контроль %s." % ("введён" if bool(b["ctrl"]) else "снят"), COL_DIM)
		"diversify":
			e["dep"] = maxf(2.0, float(e["dep"]) - 6.0)
			debt += gdp * 0.1 / 100.0
			rl_log("Диверсифицированы поставки энергии.", COL_GOOD)
		"courts":
			(rl["pend"] as Array).append({"sec": "l", "key": "jud", "step": 8.0 / 6.0, "left": 6, "key2": "j0"})
			add_support("Силовики", -1.0)
			rl_log("Запущена реформа судов.", COL_GOOD)
		"anti":
			l["anti"] = 1
			(rl["pend"] as Array).append({"sec": "l", "key": "cor", "step": -8.0 / 12.0, "left": 12, "key2": "cx"})
			add_all_support(0.5)
			add_support("Бизнес", -1.0)
			rl_log("Создано независимое антикоррупционное бюро.", COL_GOOD)
		"loyal":
			capital = minf(100.0, capital + 6.0)
			l["jud"] = maxf(3.0, float(l["jud"]) - 8.0)
			l["j0"] = float(l["j0"]) - 8.0
			rl_cor_add(3.0)
			rl_log("Судьи заменены лояльными: власть крепче, суды слабее.", COL_WARN)
		"coal_summit":
			for p in range(1, PARTY_NAMES.size()):
				if in_coalition[p]:
					satis[p] = minf(100.0, float(satis.get(p, 55.0)) + 8.0)
			rl_log("саммит коалиции: партнёры довольнее.", COL_GOOD)
		"pub":
			m["free"] = minf(98.0, float(m["free"]) + 6.0)
			m["tgt"] = float(m["tgt"]) + 6.0
			m["trust"] = minf(95.0, float(m["trust"]) + 4.0)
			rl_log("Общественное вещание получило независимость.", COL_GOOD)
		"fact":
			m["fake"] = maxf(0.0, float(m["fake"]) - 10.0)
			debt += gdp * 0.02 / 100.0
			rl_log("Работает центр проверки фактов.", COL_GOOD)
	return true


# ---------- сводные тексты ----------
func rl_summary_text() -> String:
	if not rl_on():
		return "Модуль выключен в настройках игры."
	var b: Dictionary = rl["b"]
	var d: Dictionary = rl["d"]
	var e: Dictionary = rl["e"]
	var l: Dictionary = rl["l"]
	var m: Dictionary = rl["m"]
	var t := ""
	t += "[b]Блоки[/b]: ЕС %s · евро %s · НАТО %s · Шенген %s%s\n" % [rl_yn(bool(b["eu"])), rl_yn(bool(b["euro"])), rl_yn(bool(b["nato"])), rl_yn(bool(b["schg"])), " (контроль на границах)" if bool(b["ctrl"]) else ""]
	for k in rl["acc"]:
		var a: Dictionary = rl["acc"][k]
		t += "  заявка «%s»: прогресс %.0f%%, критериев выполнено %d из 4\n" % [rl_bloc_name(String(k)), float(a["p"]) / {"eu": 40.0, "euro": 24.0, "nato": 18.0}.get(k, 30.0) * 100.0, int(a["met"])]
	t += "[b]Демография[/b]: старше 65 лет %.1f%% (при старте %.1f%%) · рождаемость %.2f · нагрузка пенсий +%.2f%% ВВП\n" % [float(d["age"]), float(d["age0"]), float(d["tfr"]), float(d["pen"])]
	t += "[b]Энергия[/b]: цена %.0f (норма 100) · зависимость от импорта %.0f%% · зелёная доля %.0f%% · климатический риск %.0f\n" % [float(e["price"]), float(e["dep"]), float(e["green"]), float(e["clim"])]
	t += "[b]Право[/b]: независимость судов %.0f · коррупция %.0f\n" % [float(l["jud"]), float(l["cor"])]
	t += "[b]СМИ[/b]: свобода прессы %.0f · доверие %.0f · дезинформация %.0f%s\n" % [float(m["free"]), float(m["trust"]), float(m["fake"]), (" · контроль власти ×%d" % int(m["state"])) if int(m["state"]) > 0 else ""]
	if rl_cohab():
		t += "[b]Сожительство[/b]: президент из оппозиции, месяцев: %d\n" % int(rl.get("cohab", 0))
	if noc_constr:
		t += "[b]Вотум недоверия[/b]: конструктивный (нужен преемник)\n"
	var lv: Dictionary = rl["lv"]
	t += "[b]Программы[/b]: семья %d · миграция %d · пенсионная реформа %d · зелёный переход %d · запасы %d · выравнивание регионов %d" % [lv["fam"], lv["imm"], lv["ret"], lv["grn"], lv["gas"], lv["eq"]]
	return t


func rl_yn(v: bool) -> String:
	return "да" if v else "нет"
