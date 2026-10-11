# v37: армии, войны и захват территорий.
# Армия страны — соединения (дивизии, бригады) по ~10 тыс. человек, каждое стоит в одной АТЕ. В мирное время армия
# содержится из статьи бюджета «армия» (pol["army"]): от неё зависят численность, которую страна может содержать, и выучка.
# Война: объявление (нужно большинство в парламенте), бои за АТЕ, оккупация (контроль АТЕ отличается от владельца),
# снабжение и окружение, усталость от войны, военный счёт, мир: белый мир, присоединение оккупированных АТЕ, репарации,
# капитуляция, полное присоединение страны. ИИ противника обороняется, контратакует и сам предлагает мир.
# Все случайности войны — свой генератор mil_rng: основной ход игры (и эталонные прогоны) они не сдвигают.
# Без войны и мобилизации система не меняет экономику: расходы на армию уже в бюджете.
extends "res://scripts/logic/fleet.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func ar_air_mult(side: int) -> float:
	return 0.0


func ar_ammo_use(f: Dictionary) -> void:
	pass


func ar_att(f: Dictionary) -> float:
	return 0.0


func ar_auto_type(cc: String, kind: String) -> String:
	return ""


func ar_cap_mult() -> float:
	return 0.0


func ar_combined(units: Array) -> float:
	return 0.0


func ar_def(f: Dictionary, a: int) -> float:
	return 0.0


func ar_deterred(cc: String) -> bool:
	return false


func ar_eq(cc: String) -> float:
	return 0.0


func ar_init() -> void:
	pass


func ar_mis_k() -> float:
	return 0.0


func ar_mob_speed() -> float:
	return 0.0


func ar_month() -> void:
	pass


func ar_org_mult(cc: String) -> float:
	return 0.0


func ar_pow_mult(cc: String) -> float:
	return 0.0


func ar_q_mult() -> float:
	return 0.0


func ar_rsv() -> float:
	return 0.0


func ar_unit_name(k: int, sz: float, kind: String, tp: String) -> String:
	return ""


func ar_war_g() -> float:
	return 0.0


func ar_war_infl() -> float:
	return 0.0


func ar_war_start() -> void:
	pass


func ar_wm(cc: String) -> float:
	return 0.0


func talk_apply(t: Dictionary, enemies: Array, lead: String, parts: PackedStringArray) -> void:
	pass


func talk_avail(id: String) -> String:
	return ""


func talk_border_ates(cc: String) -> Array:
	return []


func talk_budget() -> float:
	return 0.0


func talk_ceasefire() -> Dictionary:
	return {}


func talk_cost(id: String, lvl: int = 0) -> float:
	return 0.0


func talk_mediator() -> Dictionary:
	return {}


func talk_pkg_text(pkg: Array) -> String:
	return ""


func talk_terms(pkg: Array) -> Dictionary:
	return {}


func war_demo(cc: String) -> float:
	return 0.0


func war_dip_extra(c: String) -> float:
	return 0.0


func war_intl(w: Dictionary) -> Dictionary:
	return {}


func war_intl_g() -> float:
	return 0.0


func war_intl_infl() -> float:
	return 0.0


func war_intl_init(w: Dictionary) -> void:
	pass


func war_intl_month() -> void:
	pass


func war_on_declare(cc: String) -> String:
	return ""


func war_sanctions_update(w: Dictionary) -> void:
	pass


func war_timers_month() -> void:
	pass


func war_trade_g() -> float:
	return 0.0


func war_vote(cc: String) -> Dictionary:
	return {}


func war_vote_text(cc: String) -> String:
	return ""


# --- конец заглушек ---


# кадровая армия (тыс.), резерв (тыс.), выучка. Источник — открытые оценки 2024 г., округлено.
const MIL_BASE := {
	"DE": [180.0, 30.0, 1.05], "FR": [205.0, 40.0, 1.15], "NL": [34.0, 5.0, 1.05], "BE": [24.0, 5.0, 0.95], "LU": [1.0, 0.0, 0.9],
	"CH": [20.0, 120.0, 1.0], "AT": [22.0, 120.0, 0.95], "PL": [160.0, 50.0, 1.0], "CZ": [26.0, 4.0, 0.95], "DK": [15.0, 40.0, 1.05],
	"NO": [24.0, 40.0, 1.05], "SE": [25.0, 40.0, 1.05], "IT": [165.0, 18.0, 1.0], "ES": [120.0, 15.0, 1.0], "PT": [27.0, 20.0, 0.9],
	"GB": [145.0, 30.0, 1.15], "IE": [8.0, 2.0, 0.9], "SI": [7.0, 1.0, 0.9], "SK": [16.0, 0.0, 0.9], "HU": [25.0, 20.0, 0.9],
	"FI": [24.0, 280.0, 1.05],
	# v38: Балканы и Прибалтика
	"HR": [15.0, 20.0, 0.95], "RS": [28.0, 50.0, 0.85], "BA": [10.0, 5.0, 0.75], "ME": [2.0, 2.5, 0.8], "MK": [8.0, 5.0, 0.8],
	"AL": [8.0, 5.0, 0.75], "XK": [5.0, 3.0, 0.75], "BG": [37.0, 3.0, 0.85], "RO": [70.0, 55.0, 0.9], "GR": [130.0, 220.0, 1.0],
	"EE": [7.0, 30.0, 1.0], "LV": [8.0, 18.0, 0.95], "LT": [23.0, 7.0, 1.0],
	# v49: Молдова, Беларусь, Украина (армия военного времени), Россия
	"MD": [6.0, 50.0, 0.7], "BY": [48.0, 290.0, 0.85], "UA": [800.0, 1000.0, 1.05], "RU": [1150.0, 1500.0, 0.95]}
const MIL_NATO := ["DE", "FR", "NL", "BE", "LU", "PL", "CZ", "DK", "NO", "SE", "IT", "ES", "PT", "GB", "SI", "SK", "HU", "FI",
	"HR", "ME", "MK", "AL", "BG", "RO", "GR", "EE", "LV", "LT"]
func mil_is_nato(cc: String) -> bool:
	if cc == ccode and nato_ovr >= 0:
		return nato_ovr == 1
	return cc in MIL_NATO


const MIL_COMBAT := 0.55         # доля боевых частей в кадровой армии (остальное — тыл, штабы, флот и авиация)
const MIL_DIV := 10.0            # обычная численность соединения, тыс.
const MIL_TRUCE := 60            # месяцев перемирия после войны
const MIL_PEACE_KINDS := ["white", "repar", "annex", "capit", "full"]

var mil: Dictionary = {}
var mil_rng := RandomNumberGenerator.new()
var mil_coast: Dictionary = {}       # прибрежная АТЕ -> ближайший морской узел
var mil_coast_ok := false
var mil_supply: Array = [{}, {}]     # АТЕ со снабжением по сторонам
var mil_plan_t := 0
# быстрые индексы по АТЕ: сторона владельца, сторона контролирующего, стороны войск в АТЕ (битовая маска)
var mil_os := PackedInt32Array()
var mil_cs := PackedInt32Array()
var mil_un := PackedInt32Array()
var mil_seen := PackedInt32Array()
var mil_par := PackedInt32Array()
var mil_stamp := 0
var mil_iver := -1
var mil_dirty := true


# ============================================================
#  ИНИЦИАЛИЗАЦИЯ И ОБЩИЕ СВЕДЕНИЯ
# ============================================================


func mil_init() -> void:
	mil = {"units": [], "ctl": {}, "war": {}, "mob": 0, "mob_t": 0, "mob_k": 0.0, "rec": [], "nid": 1, "loss": {}, "log": [], "dm": 0, "truce": {},
		"sel": -1, "nav": {"station": "", "mode": "defend"}, "kia": 0.0, "wars": 0, "last": {}, "pend": {}, "ctl_ver": 0, "cd": 0}
	mil_rng.seed = hash(ccode) + 777
	mil_supply = [{}, {}]
	mil_dirty = true
	if not MIL_BASE.has(ccode) or ate_n == 0:
		return
	var n: int = mil_n_units(mil_cap())
	var spots := mil_home_spots(ccode, n)
	var per: float = mil_cap() / float(n)
	for k in n:
		mil_new_unit(ccode, per, mil_q(ccode), int(spots[k % spots.size()]), "reg")
	if flt_has_sea():
		mil["nav"]["station"] = mil_home_node(ccode)
	ar_init()


# v50: война, которая уже идёт на начало игры (январь 2026): Россия против Украины с 24 февраля 2022 года
# [противник, мы нападающая сторона, дней войны на старте]
const MIL_ONGOING := {"UA": ["RU", false, 1407], "RU": ["UA", true, 1407]}


func mil_start_ongoing() -> void:
	if not mil_on() or int(game_opts.get("milev", 1)) == 0 or not bool(game_opts.get("ongoing", true)) or not MIL_ONGOING.has(ccode) or mil_at_war():
		return
	var o: Array = MIL_ONGOING[ccode]
	var lead: String = String(o[0])
	if not WORLD.has(lead) or not MIL_BASE.has(lead):
		return
	# отношения на старте уже учитывают войну — не сдвигаем их второй раз
	var dip0: Dictionary = dip.duplicate(true)
	var rx0: Dictionary = (fst.get("rel_x", {}) as Dictionary).duplicate(true)
	mil_start_war(lead, [], [], bool(o[1]))
	dip = dip0
	if fst.has("rel_x"):
		fst["rel_x"] = rx0
	var w: Dictionary = mil["war"]
	w["days"] = int(o[2])
	w["start"] = turn - int(round(float(o[2]) / 30.4))
	w["ongoing"] = true
	w["weary"] = 26.0 if bool(o[1]) else 34.0      # усталость четвёртого года
	w["mor"] = clampf(float(w.get("mor", 55.0)) - 8.0, 15.0, 90.0)
	w["offer_cd"] = 60
	# свои войска на старте стоят на фронте, а не в глубине страны
	var own: Array = mil_units_of(ccode)
	var spots: Array = mil_border_spots(ccode, [lead], int(ceil(float(own.size()) * 0.75)))
	for k in mini(spots.size(), own.size()):
		var f: Dictionary = own[k]
		f["a"] = int(spots[k])
		f["path"] = []
		f["mode"] = "def"
	mil_dirty = true
	# международная реакция четвёртого года: осуждение ООН, санкции ЕС и союзников, добровольцы и требования перемирия уже были
	var it: Dictionary = war_intl(w)
	if not it.is_empty():
		it["cond"] = 70.0
		it["un"] = 4
		it["press"] = 1
		it["vol"] = 3
		if bool(o[1]):
			it["eu"] = true
			w["sanct"] = true
		war_sanctions_update(w)
	w["g0"] = mil_g()
	w["i0"] = mil_infl()
	var msg := "Идёт четвёртый год полномасштабной войны: Россия напала на Украину 24 февраля 2022 года. Фронт проходит по Донбассу, Запорожской и Херсонской областям; Крым, большая часть Донбасса, юг Запорожской и левобережье Херсонской областей заняты Россией."
	mil_log(msg, COL_WARN)
	log_tag("ВОЙНА", COL_BAD, msg)


func mil_on() -> bool:
	return not mil.is_empty() and MIL_BASE.has(ccode)


func mil_n_units(total: float) -> int:
	return clampi(int(round(total / MIL_DIV)), 1, 30)


# боевая численность, которую страна содержит при нынешних расходах на армию (тыс.)
func mil_cap() -> float:
	var b: Array = MIL_BASE.get(ccode, [10.0, 0.0, 1.0])
	return maxf(0.5, float(b[0]) * MIL_COMBAT * mil_spend_ratio() * ar_cap_mult() - ar_mis_k())


func mil_spend_ratio() -> float:
	return clampf(float(pol.get("army", 1.0)) / maxf(0.1, float(pol_def.get("army", 1.0))), 0.2, 3.0)


func mil_q(cc: String) -> float:
	var b: Array = MIL_BASE.get(cc, [10.0, 0.0, 1.0])
	if cc == ccode:
		return float(b[2]) * (0.8 + 0.2 * clampf(mil_spend_ratio(), 0.5, 2.0)) * float(mods["army_q"]) * ar_q_mult()
	return float(b[2])


func mil_unit_name(cc: String, k: int, sz: float, kind: String, tp: String = "") -> String:
	var nm := ar_unit_name(k, sz, kind, tp)
	if nm != "":
		return nm
	var what := "бригада" if sz < 6.0 else "дивизия"
	if kind == "res":
		what = "резервная " + what
	return "%d-я %s" % [k, what]


func mil_new_unit(cc: String, sz: float, q: float, a: int, kind: String, tp: String = "") -> Dictionary:
	var k := 1
	for f in mil["units"]:
		if String(f["cc"]) == cc:
			k += 1
	if tp == "":
		tp = ar_auto_type(cc, kind)
	if tp == "":
		tp = "inf"
	var f := {"id": int(mil["nid"]), "cc": cc, "nm": mil_unit_name(cc, k, sz, kind, tp), "str": sz, "max": sz, "org": 1.0, "q": q, "a": a,
		"path": [], "prog": 0.0, "mode": "hold", "kind": kind, "fight": -1, "sea": {}, "tp": tp}
	mil["nid"] = int(mil["nid"]) + 1
	(mil["units"] as Array).append(f)
	return f


func mil_unit(id: int) -> Dictionary:
	for f in mil.get("units", []):
		if int(f["id"]) == id:
			return f
	return {}


func mil_units_of(cc: String) -> Array:
	var out: Array = []
	for f in mil.get("units", []):
		if String(f["cc"]) == cc:
			out.append(f)
	return out


func mil_cc_ates(cc: String) -> Array:
	var out: Array = []
	for ui in WORLD_UNITS.size():
		if String(WORLD_UNITS[ui]["cc"]) == cc and ui < ate_lists.size():
			for a in (ate_lists[ui] as PackedInt32Array):
				out.append(a)
	return out


# места размещения: центры крупнейших регионов страны
func mil_home_spots(cc: String, n: int) -> Array:
	var us: Array = []
	for ui in WORLD_UNITS.size():
		if String(WORLD_UNITS[ui]["cc"]) == cc and ui < ate_lists.size() and (ate_lists[ui] as PackedInt32Array).size() > 0:
			us.append(ui)
	us.sort_custom(func(x, y) -> bool: return (ate_lists[x] as PackedInt32Array).size() > (ate_lists[y] as PackedInt32Array).size())
	var out: Array = []
	if ate_cap.has(cc) and int(ate_cap[cc]) >= 0 and ate_cc(int(ate_cap[cc])) == cc:
		out.append(int(ate_cap[cc]))
	for ui in us:
		var c := Vector2(float(WORLD_UNITS[ui]["c"][0]), float(WORLD_UNITS[ui]["c"][1]))
		var best := -1
		var bd := 1e18
		for a in (ate_lists[ui] as PackedInt32Array):
			var d: float = ate_c[a].distance_squared_to(c)
			if d < bd:
				bd = d
				best = a
		if best >= 0 and not (best in out):
			out.append(best)
		if out.size() >= n:
			break
	if out.is_empty():
		var all := mil_cc_ates(cc)
		if not all.is_empty():
			out.append(int(all[0]))
	return out


# места у границы с противником: АТЕ страны cc, соседние с АТЕ стран из foes, равномерно вдоль границы
func mil_border_spots(cc: String, foes: Array, n: int) -> Array:
	var cand: Array = []
	for a in mil_cc_ates(cc):
		for b in ate_nbs(int(a)):
			if ate_cc(b) in foes:
				cand.append(int(a))
				break
	if cand.is_empty() or n <= 0:
		return []
	cand.sort_custom(func(x, y) -> bool: return ate_c[x].x + ate_c[x].y * 0.7 < ate_c[y].x + ate_c[y].y * 0.7)
	var out: Array = []
	for k in n:
		out.append(int(cand[mini(cand.size() - 1, int((float(k) + 0.5) * float(cand.size()) / float(n)))]))
	return out


func mil_owner(a: int) -> String:
	return ate_cc(a)


func mil_ctl(a: int) -> String:
	return String((mil.get("ctl", {}) as Dictionary).get(a, ate_cc(a)))


func mil_at_war() -> bool:
	return not mil.is_empty() and not (mil["war"] as Dictionary).is_empty()


func mil_side(cc: String) -> int:
	if not mil_at_war():
		return 0 if cc == ccode else -1
	return int((mil["war"]["side"] as Dictionary).get(cc, -1))


func mil_at_war_with(cc: String) -> bool:
	return mil_at_war() and mil_side(cc) == 1


func mil_hostile(c1: String, c2: String) -> bool:
	var s1 := mil_side(c1)
	var s2 := mil_side(c2)
	return s1 >= 0 and s2 >= 0 and s1 != s2


func mil_side_ccs(side: int) -> Array:
	var out: Array = []
	if not mil_at_war():
		return [ccode] if side == 0 else []
	for c in mil["war"]["side"]:
		if int(mil["war"]["side"][c]) == side:
			out.append(String(c))
	return out


func mil_pw(f: Dictionary) -> float:
	var sup := 1.0
	var sd := mil_side(String(f["cc"]))
	if mil_at_war() and sd >= 0 and int(f["a"]) >= 0 and not (mil_supply[sd] as Dictionary).is_empty() and not (mil_supply[sd] as Dictionary).has(int(f["a"])):
		sup = 0.6
	return float(f["str"]) * float(f["q"]) * (0.25 + 0.75 * float(f["org"])) * sup * ar_pow_mult(String(f["cc"]))


func mil_side_power(side: int) -> float:
	var p := 0.0
	for f in mil.get("units", []):
		if mil_side(String(f["cc"])) == side:
			p += mil_pw(f)
	return p


func mil_total(cc: String) -> float:
	var s := 0.0
	for f in mil_units_of(cc):
		s += float(f["str"])
	return s


func mil_regular_total() -> float:
	var s := 0.0
	for f in mil_units_of(ccode):
		if String(f["kind"]) == "reg":
			s += float(f["max"])
	for r in mil.get("rec", []):
		s += float(r["str"])
	return s


func mil_reserve_k(level: int) -> float:
	var rs: float = ar_rsv()
	var popk: float = total_pop() * 1000.0
	if level <= 0:
		return 0.0
	if level == 1:
		return maxf(rs * 0.5, popk * 0.001)
	return rs + popk * 0.003


func mil_mob_k() -> float:
	var s := 0.0
	for f in mil_units_of(ccode):
		if String(f["kind"]) == "res":
			s += float(f["str"])
	return s + float(mil.get("mob_k", 0.0)) * (1.0 if int(mil.get("mob_t", 0)) > 0 else 0.0)


# сила страны вне войны (для решений ИИ и сравнения на экране): кадровая армия × выучка
func mil_country_power(cc: String) -> float:
	if cc == ccode:
		var s := 0.0
		for f in mil_units_of(ccode):
			s += float(f["str"]) * float(f["q"])
		return s * ar_eq(ccode)
	var b: Array = MIL_BASE.get(cc, [5.0, 0.0, 1.0])
	var lim: Dictionary = (mil.get("lim", {}) as Dictionary).get(cc, {})
	return float(b[0]) * MIL_COMBAT * float(b[2]) * float((mil.get("loss", {}) as Dictionary).get(cc, 1.0)) * float(lim.get("arm", 1.0)) * ar_wm(cc)


func mil_log(txt: String, col: String = "") -> void:
	if mil.is_empty():
		return
	(mil["log"] as Array).append("%s — %s" % [date_text(), txt])
	if (mil["log"] as Array).size() > 60:
		(mil["log"] as Array).pop_front()
	log_tag("АРМИЯ", col if col != "" else COL_WARN, "%s — %s" % [date_text(), txt])


# ============================================================
#  ГРАФ АТЕ: ПРОХОДИМОСТЬ, ПУТИ, ПОБЕРЕЖЬЕ
# ============================================================


func mil_idx() -> void:
	if not mil_dirty and mil_iver == ate_ver and mil_os.size() == ate_n:
		return
	mil_dirty = false
	mil_iver = ate_ver
	mil_os.resize(ate_n)
	mil_cs.resize(ate_n)
	mil_un.resize(ate_n)
	var sides := {}
	for ui in WORLD_UNITS.size():
		var c := String(WORLD_UNITS[ui]["cc"])
		if not sides.has(c):
			sides[c] = mil_side(c)
	for a in ate_n:
		mil_os[a] = int(sides[String(WORLD_UNITS[ate_unit[a]]["cc"])])
	for a in ate_n:
		mil_cs[a] = mil_os[a]
	for a in mil.get("ctl", {}):
		mil_cs[int(a)] = mil_side(String(mil["ctl"][a]))


func mil_un_build() -> void:
	mil_idx()
	mil_un.fill(0)
	for f in mil["units"]:
		var a: int = int(f["a"])
		var sd := mil_side(String(f["cc"]))
		if a >= 0 and sd >= 0:
			mil_un[a] = mil_un[a] | (1 << sd)


func mil_passable(a: int, cc: String) -> bool:
	mil_idx()
	if not mil_at_war():
		return mil_os[a] == 0 and cc == ccode
	return mil_os[a] >= 0


# поиск в ширину от АТЕ a0 по проходимым АТЕ; родители — в mil_par (до следующего поиска). Возвращает порядок обхода.
func mil_bfs(a0: int, cc: String) -> PackedInt32Array:
	mil_idx()
	var no: PackedInt32Array = ATE["no"]
	var nb: PackedInt32Array = ATE["nb"]
	if mil_seen.size() != ate_n:
		mil_seen.resize(ate_n)
		mil_seen.fill(0)
		mil_par.resize(ate_n)
	mil_stamp += 1
	var st := mil_stamp
	var war := mil_at_war()
	var q := PackedInt32Array()
	q.append(a0)
	mil_seen[a0] = st
	mil_par[a0] = -1
	var k := 0
	while k < q.size():
		var a: int = q[k]
		k += 1
		for j in range(no[a], no[a + 1]):
			var b: int = nb[j]
			if mil_seen[b] == st:
				continue
			var os: int = mil_os[b]
			if (war and os < 0) or (not war and os != 0):
				continue
			mil_seen[b] = st
			mil_par[b] = a
			q.append(b)
	return q


func mil_reached(a: int) -> bool:
	return a >= 0 and a < mil_seen.size() and mil_seen[a] == mil_stamp


func mil_path_to(to: int) -> Array:
	if not mil_reached(to):
		return []
	var out: Array = []
	var cur := to
	var guard := 0
	while mil_par[cur] != -1 and guard < 8000:
		out.push_front(cur)
		cur = mil_par[cur]
		guard += 1
	return out


func mil_coast_build() -> void:
	if mil_coast_ok:
		return
	mil_coast_ok = true
	mil_coast.clear()
	fleet_load()
	if flt_nodes.is_empty() or ate_n == 0:
		return
	var ea: PackedInt32Array = ATE["ea"]
	var eb: PackedInt32Array = ATE["eb"]
	var coast := {}
	for k in ea.size():
		if eb[k] < 0:
			coast[ea[k]] = true
	for a in coast:
		var best := ""
		var bd := 140.0 * 140.0
		for nid in flt_nodes:
			var n: Dictionary = flt_nodes[nid]
			var d: float = ate_c[int(a)].distance_squared_to(Vector2(float(n["x"]), float(n["y"])))
			if d < bd:
				bd = d
				best = String(nid)
		if best != "":
			mil_coast[int(a)] = best


func mil_home_node(cc: String) -> String:
	var best := ""
	var bw := -1.0
	for p in flt_ports_of(cc):
		if float(p["w"]) > bw:
			bw = float(p["w"])
			best = String(p["node"])
	return best


func mil_port_nodes(cc: String) -> Array:
	var out: Array = []
	for p in flt_ports_of(cc):
		if not (String(p["node"]) in out):
			out.append(String(p["node"]))
	return out


# ============================================================
#  МИРНОЕ ВРЕМЯ: НАБОР, МОБИЛИЗАЦИЯ, ПЕРЕДВИЖЕНИЕ
# ============================================================


func mil_recruit_check() -> String:
	if not mil_on():
		return "Армии нет."
	if opp_mode:
		return "В оппозиции армией командует правительство."
	if capital < 2.0:
		return "Нужно 2 политического капитала."
	if (mil["rec"] as Array).size() >= 4:
		return "Уже формируются 4 соединения."
	var head: float = mil_cap() - mil_regular_total()
	if head < mil_min_unit() and not mil_at_war():
		return "Нет средств на ещё одно соединение: поднимите расходы на армию (сейчас можно содержать %.0f тыс., есть %.0f тыс.)." % [mil_cap(), mil_regular_total()]
	return ""


func mil_min_unit() -> float:
	return clampf(mil_cap() * 0.2, 0.5, 3.0)


func mil_recruit() -> bool:
	if mil_recruit_check() != "":
		return false
	var head: float = mil_cap() - mil_regular_total()
	var sz: float = clampf(head, mil_min_unit(), MIL_DIV) if not mil_at_war() else clampf(mil_cap() * 0.3, mil_min_unit(), MIL_DIV)
	capital -= 2.0
	debt += sz * 0.02          # снаряжение: ≈20 тыс. € на бойца
	(mil["rec"] as Array).append({"str": sz, "days": 90})
	mil_log("начато формирование нового соединения (%.0f тыс. человек, 90 суток)." % sz, COL_TEAL)
	return true


func mil_mob_check(level: int) -> String:
	if not mil_on():
		return "Армии нет."
	if opp_mode:
		return "В оппозиции мобилизацию объявляет правительство."
	if level == int(mil["mob"]):
		return "Уже действует."
	if level > int(mil["mob"]):
		var cost := 3.0 if level == 1 else 6.0
		if capital < cost:
			return "Нужно %.0f политического капитала." % cost
		if level == 2 and not mil_at_war():
			var dm := fed_dom(false)
			if not bool(dm["ok"]):
				return "Всеобщая мобилизация в мирное время требует большинства в парламенте. " + String(dm["text"])
	return ""


func mil_mobilize(level: int) -> bool:
	if mil_mob_check(level) != "":
		return false
	var old: int = int(mil["mob"])
	if level > old:
		capital -= 3.0 if level == 1 else 6.0
		var add: float = mil_reserve_k(level) - mil_reserve_k(old)
		mil["mob"] = level
		mil["mob_k"] = float(mil["mob_k"]) + add
		mil["mob_t"] = maxi(7, int(round((21.0 if level == 1 else 35.0) * ar_mob_speed())))
		add_support("Молодёжь", -3.0 * float(level - old))
		add_support("Рабочие", -1.5 * float(level - old))
		add_support("Силовики", 2.0)
		mil_log("объявлена %s мобилизация: %.0f тыс. резервистов прибудут в части через %d суток." % ["частичная" if level == 1 else "всеобщая", add, int(mil["mob_t"])], COL_WARN)
	else:
		mil["mob"] = level
		var keep: float = mil_reserve_k(level)
		var have := 0.0
		var units: Array = mil["units"]
		for i in range(units.size() - 1, -1, -1):
			var f: Dictionary = units[i]
			if String(f["cc"]) != ccode or String(f["kind"]) != "res":
				continue
			if have + float(f["str"]) > keep + 0.5:
				units.remove_at(i)
			else:
				have += float(f["str"])
		mil["mob_k"] = 0.0
		mil["mob_t"] = 0
		add_support("Молодёжь", 2.0)
		mil_log("мобилизация %s: резервисты возвращаются домой." % ("сокращена" if level > 0 else "отменена"), COL_GOOD)
	return true


func mil_mob_arrive() -> void:
	var tot: float = float(mil["mob_k"])
	mil["mob_k"] = 0.0
	if tot <= 0.5:
		return
	# не больше 40 соединений: у огромных армий (Россия, Украина) резервные соединения просто крупнее
	var n: int = clampi(int(round(tot / MIL_DIV)), 1, 40)
	var spots := mil_home_spots(ccode, n + 1)
	var q: float = mil_q(ccode) * 0.8
	for k in n:
		var a: int = int(spots[(k + 1) % spots.size()])
		mil_new_unit(ccode, tot / float(n), q, a, "res")
	mil_log("резервисты прибыли: %d соединений, %.0f тыс. человек." % [n, tot], COL_TEAL)


# приказ соединению: идти в АТЕ to (путь по суше)
func mil_order_move(id: int, to: int) -> String:
	var f := mil_unit(id)
	if f.is_empty() or String(f["cc"]) != ccode:
		return "Это не ваше соединение."
	if not (f["sea"] as Dictionary).is_empty():
		return "Соединение в море."
	if to < 0 or to >= ate_n:
		return "Нет такой АТЕ."
	if not mil_passable(to, ccode):
		return "Туда нельзя: это территория страны, с которой вы не воюете."
	mil_bfs(int(f["a"]), ccode)
	var p := mil_path_to(to)
	if p.is_empty() and to != int(f["a"]):
		# своё побережье за морем (острова): переброска паромами и транспортами
		mil_coast_build()
		if mil_side(mil_ctl(to)) == mil_side(ccode) and mil_coast.has(to):
			if not mil_coast.has(int(f["a"])):
				return "Пути по суше нет: отведите соединение к побережью, оттуда его перевезут морем."
			var sp := flt_path(String(mil_coast[int(f["a"])]), String(mil_coast[to]))
			f["sea"] = {"to": to, "days": 2 + int(ceil(flt_path_len(sp) / 350.0)), "from": int(f["a"]), "ferry": true}
			f["a"] = -1
			f["path"] = []
			f["mode"] = "hold"
			return ""
		return "Пути по суше нет (нужен десант)."
	f["path"] = p
	f["prog"] = 0.0
	f["fight"] = -1
	f["mode"] = "move"
	return ""


func mil_order_mode(id: int, mode: String) -> void:
	var f := mil_unit(id)
	if f.is_empty() or String(f["cc"]) != ccode:
		return
	f["mode"] = mode
	if mode == "hold":
		f["path"] = []
		f["fight"] = -1


# ============================================================
#  ОБЪЯВЛЕНИЕ ВОЙНЫ
# ============================================================


# страны, с которыми можно воевать: соседи по суше и (при своём флоте) по морю
func mil_targets() -> Array:
	var out: Array = []
	if not mil_on():
		return out
	for ui in fed_adjacent_units():
		var cc := String(WORLD_UNITS[ui]["cc"])
		if not (cc in out) and wsim.has(cc) and MIL_BASE.has(cc):
			out.append(cc)
	if flt_has_sea() and not bool(flt.get("land", true)):
		for cc in wsim:
			if cc != ccode and not (cc in out) and MIL_BASE.has(cc) and not flt_ports_of(String(cc)).is_empty():
				out.append(String(cc))
	return out


# общая сухопутная граница по АТЕ (морские переходы между регионами — не граница: туда только морем)
func mil_land_neighbor(cc: String) -> bool:
	for a in mil_cc_ates(cc):
		if ate_cc(int(a)) != cc:
			continue
		for b in ate_nbs(int(a)):
			if ate_cc(b) == ccode:
				return true
	return false


func mil_allies_for(victim: String, aggressor: String) -> Array:
	# НАТО защищает своих: если на члена НАТО нападает страна вне НАТО — вступают члены НАТО, граничащие с агрессором
	var out: Array = []
	if not mil_is_nato(victim) or mil_is_nato(aggressor) or victim in mil.get("neutral", []):
		return out
	for c in wsim:
		if c == victim or c == aggressor or c == ccode or not mil_is_nato(c) or not MIL_BASE.has(c):
			continue
		var touch := false
		for a in mil_cc_ates(String(c)):
			for b in ate_nbs(int(a)):
				if ate_cc(b) == aggressor:
					touch = true
					break
			if touch:
				break
		if touch:
			out.append(String(c))
	return out


func mil_declare_check(cc: String) -> String:
	if not mil_on():
		return "Армии нет."
	if opp_mode:
		return "Войну объявляет правительство, а вы в оппозиции."
	if mil_at_war():
		return "Вы уже воюете."
	if not wsim.has(cc) or not MIL_BASE.has(cc) or cc == ccode:
		return "С этой страной воевать нельзя."
	if not (cc in mil_targets()):
		return "Нет общей границы и морского пути."
	if int((mil["truce"] as Dictionary).get(cc, 0)) > 0:
		return "Действует мирный договор: ещё %d мес." % int(mil["truce"][cc])
	if capital < 15.0:
		return "Нужно 15 политического капитала."
	var vt := war_vote(cc)
	if not bool(vt["ok"]):
		return "Парламент не поддержит войну: «за» %d из %d мест." % [int(vt["yes"]), int(vt["total"])]
	return ""


func mil_declare(cc: String, force: bool = false) -> Dictionary:
	if not force:
		var why := mil_declare_check(cc)
		if why != "":
			return {"done": false, "msg": why}
		capital -= 15.0
	var allies := mil_allies_for(cc, ccode)
	var vtxt := war_vote_text(cc)
	mil_start_war(cc, allies, [], true)
	fa_notify("war", cc, 1.0)
	var both_eu: bool = bool(WORLD.get(ccode, {}).get("eu", false)) and bool(WORLD[cc].get("eu", false))
	var msg := "Вы объявили войну стране «%s»." % String(WORLD[cc]["name"])
	if not allies.is_empty():
		var nms: PackedStringArray = []
		for c in allies:
			nms.append(String(WORLD[c]["name"]))
		msg += " На её сторону по договору НАТО встают: %s." % ", ".join(nms)
	if bool(mil["war"].get("sanct", false)):
		msg += " Евросоюз вводит санкции против вас."
	var dom := war_on_declare(cc)
	if dom != "":
		msg += " " + dom
	log_line("[b][color=%s]%s: %s[/color][/b]" % [COL_BAD, date_text(), msg])
	log_line(vtxt)
	mil_log(msg, COL_BAD)
	refresh()
	return {"done": true, "msg": msg}


# начало войны: стороны, санкции, армии противника на карте
func mil_start_war(lead: String, foes_extra: Array, friends: Array, we_attack: bool) -> void:
	var side := {ccode: 0, lead: 1}
	for c in foes_extra:
		side[c] = 1
	for c in friends:
		side[c] = 0
	var both_eu: bool = bool(WORLD.get(ccode, {}).get("eu", false)) and bool(WORLD[lead].get("eu", false))
	mil["war"] = {"lead": lead, "side": side, "start": turn, "days": 0, "score": 0.0, "aggr": we_attack, "sanct": both_eu and we_attack,
		"won": 0, "lost": 0, "nwon": 0, "nlost": 0, "kia": [0.0, 0.0], "pow": [0.0, 0.0], "cap_lost": 0, "offer_cd": 30, "prop_cd": 0, "weary": 0.0,
		"blk_e": false, "blk_p": false, "nv": {}, "pop": {}, "tot": [0.0, 0.0], "str0": {}, "occ": [0.0, 0.0], "mob_ai": 0}
	mil["wars"] = int(mil["wars"]) + 1
	mil["ctl"] = {}
	mil_dirty = true
	mil["ctl_ver"] = int(mil["ctl_ver"]) + 1
	# население АТЕ сторон — для военного счёта
	var popd: Dictionary = mil["war"]["pop"]
	var tot := [0.0, 0.0]
	for c in side:
		for a in mil_cc_ates(String(c)):
			var p := ate_pop(int(a))
			popd[int(a)] = p
			tot[int(side[c])] += p
	mil["war"]["tot"] = tot
	# армии остальных участников
	for c in side:
		if String(c) == ccode:
			continue
		var foes: Array = []
		for c2 in side:
			if int(side[c2]) != int(side[c]):
				foes.append(String(c2))
		mil_spawn_army(String(c), foes)
	(mil["war"]["str0"] as Dictionary)[ccode] = mil_total(ccode)
	# свои соединения без приказа встают на оборону границы
	for f in mil_units_of(ccode):
		if String(f["mode"]) == "hold" and (f["path"] as Array).is_empty():
			f["mode"] = "def"
	# флоты противника
	for c in side:
		if int(side[c]) != 1:
			continue
		var p0 := 0.0
		var nv0: Dictionary = FLEET.get("navy0", {}).get(c, {})
		for cl in FLEET.get("classes", []):
			p0 += float(int(nv0.get(String(cl["id"]), 0))) * float(cl["pow"])
		if p0 > 0.0:
			var hn := mil_home_node(String(c))
			p0 *= float((mil.get("nvl", {}) as Dictionary).get(c, 1.0))
			mil["war"]["nv"][c] = {"pow": p0 * float((mil["loss"] as Dictionary).get(c, 1.0)), "pow0": p0, "node": hn, "home": hn, "ports": mil_port_nodes(String(c))}
	# отношения
	for c in side:
		var c_s := String(c)
		if c_s == ccode:
			continue
		var dd: float = -45.0 if int(side[c]) == 1 else 5.0
		if dip.has(c_s):
			dip_change(c_s, dd)
		else:
			(fst["rel_x"] as Dictionary)[c_s] = float((fst["rel_x"] as Dictionary).get(c_s, 0.0)) + dd
	if we_attack:
		dip_all((-12.0 if not both_eu else -22.0) * (0.5 + 0.5 * war_demo(lead)), false)
	war_intl_init(mil["war"])
	ar_war_start()
	mil_plan_t = 0
	mil_supply_update()


# армия страны cc на карте: кадровая армия с учётом потерь прошлой войны и ограничений мирного договора;
# в демилитаризованной зоне войска стоят в глубине страны, а не у границы
func mil_spawn_army(cc: String, foes: Array) -> void:
	var b: Array = MIL_BASE[cc]
	var lf: float = float((mil["loss"] as Dictionary).get(cc, 1.0))
	var lim: Dictionary = (mil.get("lim", {}) as Dictionary).get(cc, {})
	var total: float = float(b[0]) * MIL_COMBAT * lf * float(lim.get("arm", 1.0)) * ar_wm(cc)
	var n: int = mil_n_units(total)
	var dmz: bool = int((mil.get("dmz", {}) as Dictionary).get(cc, 0)) > 0
	var nb_n: int = 0 if dmz else int(ceil(float(n) * 0.6))
	var spots := mil_border_spots(cc, foes, nb_n) if nb_n > 0 else []
	var home := mil_home_spots(cc, n)
	if home.is_empty():
		return
	for k in n:
		var a: int = int(spots[k]) if k < spots.size() else int(home[k % home.size()])
		var f := mil_new_unit(cc, total / float(n), mil_q(cc), a, "reg")
		f["mode"] = "auto"
	(mil["war"]["str0"] as Dictionary)[cc] = total


# ============================================================
#  ДЕНЬ ВОЙНЫ
# ============================================================


func mil_day() -> void:
	if not mil_on() or game_over:
		return
	mil["dm"] = int(mil["dm"]) + 1
	# формирование и мобилизация
	var rec: Array = mil["rec"]
	for i in range(rec.size() - 1, -1, -1):
		rec[i]["days"] = int(rec[i]["days"]) - 1
		if int(rec[i]["days"]) <= 0:
			var sp := mil_home_spots(ccode, 3)
			var f := mil_new_unit(ccode, float(rec[i]["str"]), mil_q(ccode), int(sp[mil_rng.randi() % sp.size()]), "reg")
			mil_log("в строй вступила %s (%.0f тыс.)." % [String(f["nm"]), float(f["str"])], COL_GOOD)
			add_support("Силовики", 0.5)
			rec.remove_at(i)
	if int(mil["mob_t"]) > 0:
		mil["mob_t"] = int(mil["mob_t"]) - 1
		if int(mil["mob_t"]) == 0:
			mil_mob_arrive()
	if not mil_at_war():
		mil_move_all()
		mil_sea_day()
		return
	var w: Dictionary = mil["war"]
	w["days"] = int(w["days"]) + 1
	if int(w.get("cf_cd", 0)) > 0:
		w["cf_cd"] = int(w["cf_cd"]) - 1
	if int(w.get("cf", 0)) > 0:
		# перемирие: бои стоят, войска на местах, переговоры идут
		w["cf"] = int(w["cf"]) - 1
		if int(w["cf"]) == 0:
			mil_log("перемирие истекло: бои возобновились.", COL_WARN)
		if int(w["prop_cd"]) > 0:
			w["prop_cd"] = int(w["prop_cd"]) - 1
		mil_recover()
		w["offer_cd"] = int(w["offer_cd"]) - 1
		if int(w["days"]) % 7 == 0:
			mil_ai_peace()
		return
	if int(w["days"]) % 3 == 1:
		mil_supply_update()
	mil_plan_t -= 1
	if mil_plan_t <= 0:
		mil_plan_t = 3
		mil_plan(0)
		mil_plan(1)
	mil_join_battles()
	mil_battles()
	mil_move_all()
	mil_sea_day()
	mil_recover()
	mil_navy_day()
	mil_score_update()
	if int(w["prop_cd"]) > 0:
		w["prop_cd"] = int(w["prop_cd"]) - 1
	w["offer_cd"] = int(w["offer_cd"]) - 1
	if int(w["days"]) % 7 == 0:
		mil_ai_peace()


func mil_hostile_units_at(a: int, cc: String) -> Array:
	var out: Array = []
	for f in mil["units"]:
		if int(f["a"]) == a and mil_hostile(String(f["cc"]), cc):
			out.append(f)
	return out


func mil_units_at(a: int) -> Array:
	var out: Array = []
	for f in mil.get("units", []):
		if int(f["a"]) == a:
			out.append(f)
	return out


func mil_set_ctl(a: int, cc: String) -> void:
	var ctl: Dictionary = mil["ctl"]
	var ow := ate_cc(a)
	var nc := cc
	if mil_side(ow) == mil_side(cc):
		nc = ow
	mil_idx()
	if nc == ow:
		if ctl.has(a):
			ctl.erase(a)
			mil["ctl_ver"] = int(mil["ctl_ver"]) + 1
	elif String(ctl.get(a, ow)) != nc:
		ctl[a] = nc
		mil["ctl_ver"] = int(mil["ctl_ver"]) + 1
	mil_cs[a] = mil_side(nc)


# соединение вошло в АТЕ: контроль и «зона контроля» — соседние АТЕ без войск противника
func mil_take(a: int, cc: String) -> void:
	var sd := mil_side(cc)
	if mil_side(mil_ctl(a)) == sd:
		return          # передвижение по своей территории фронт не сдвигает
	mil_set_ctl(a, cc)
	# зона контроля: соседняя АТЕ противника без его войск переходит под контроль, если уже почти окружена
	# (не меньше трёх её соседей держит наша сторона); свою занятую землю без войск противника — уже при двух
	for b in ate_nbs(a):
		var ob := mil_side(ate_cc(b))
		if ob < 0 or not mil_hostile_units_at(b, cc).is_empty():
			continue
		var home: bool = ob == sd and mil_side(mil_ctl(b)) != sd
		if not home and (ob == sd or mil_side(mil_ctl(b)) != ob):
			continue
		var ours := 0
		for b2 in ate_nbs(b):
			if mil_side(mil_ctl(b2)) == sd:
				ours += 1
		if ours >= (2 if home else 3):
			mil_set_ctl(b, cc)


func mil_move_all() -> void:
	for f in mil["units"]:
		if int(f["fight"]) >= 0 or not (f["sea"] as Dictionary).is_empty():
			continue
		var p: Array = f["path"]
		if p.is_empty():
			continue
		var nx: int = int(p[0])
		var cc := String(f["cc"])
		if not mil_passable(nx, cc):
			f["path"] = []
			continue
		if mil_at_war() and not mil_hostile_units_at(nx, cc).is_empty():
			# по прямому приказу игрока атакуют сразу; сами (ИИ и «наступать сами») — когда рядом собран перевес
			if String(f["mode"]) == "move" or mil_local_odds(nx, cc) >= 1.15 or mil_battle_at(nx, mil_side(cc)):
				f["fight"] = nx
			continue
		var own: bool = mil_side(mil_ctl(nx)) == mil_side(cc)
		f["prog"] = float(f["prog"]) + 0.9 * (1.3 if own else 0.75) * (0.5 + 0.5 * float(f["org"]))
		if float(f["prog"]) >= 1.0:
			f["prog"] = 0.0
			f["a"] = nx
			p.pop_front()
			if mil_at_war():
				mil_take(nx, cc)
			if p.is_empty() and String(f["mode"]) == "move":
				f["mode"] = "hold"


# перевес сил стороны cc у АТЕ x: свои соединения в соседних АТЕ против защитников x (с бонусом обороны)
func mil_local_odds(x: int, cc: String) -> float:
	var sd := mil_side(cc)
	var pa := 0.0
	var nbs := ate_nbs(x)
	for f in mil["units"]:
		if mil_side(String(f["cc"])) != sd or int(f["a"]) < 0:
			continue
		if int(f["fight"]) == x or (int(f["a"]) in nbs and int(f["fight"]) < 0 and String(f["mode"]) != "hold"):
			pa += mil_pw(f) * ar_att(f)
	var pd := 0.0
	for f in mil_hostile_units_at(x, cc):
		pd += mil_pw(f) * ar_def(f, x)
	return pa / maxf(0.01, pd * mil_def_mult(x, 1 - sd))


func mil_battle_at(x: int, side: int) -> bool:
	for f in mil["units"]:
		if int(f["fight"]) == x and mil_side(String(f["cc"])) == side:
			return true
	return false


func mil_join_battles() -> void:
	# свободные соседние соединения (ИИ и «наступать сами») поддерживают идущую атаку
	var fronts := {}
	for f in mil["units"]:
		if int(f["fight"]) >= 0:
			fronts[int(f["fight"])] = mil_side(String(f["cc"]))
	if fronts.is_empty():
		return
	for f in mil["units"]:
		if int(f["fight"]) >= 0 or int(f["a"]) < 0 or float(f["org"]) < 0.5 or not (f["sea"] as Dictionary).is_empty():
			continue
		var md := String(f["mode"])
		var sd := mil_side(String(f["cc"]))
		var a: int = int(f["a"])
		if fronts.has(a) and int(fronts[a]) != sd:
			continue      # сами под ударом — держат свою АТЕ
		for b in ate_nbs(a):
			if not fronts.has(b):
				continue
			if int(fronts[b]) == sd and md == "auto":
				f["fight"] = b
				f["path"] = [b]
				break
			# оборона: свободные соседние части («оборонять», «наступать сами», ИИ) подкрепляют атакованную АТЕ
			if int(fronts[b]) != sd and md in ["auto", "def"] and mil_side(mil_ctl(b)) == sd and (f["path"] as Array).size() != 1:
				f["path"] = [b]
				f["prog"] = maxf(float(f["prog"]), 0.5)
				break


func mil_def_mult(a: int, side: int) -> float:
	var m := 1.25
	if mil_side(ate_cc(a)) == side:
		m += 0.25
	# v50: затяжная война — линии укреплений, минные поля и дроны: обороняться заметно легче, чем наступать
	if mil_at_war() and bool((mil["war"] as Dictionary).get("ongoing", false)):
		m += 0.6
	for c in ate_cap:
		if int(ate_cap[c]) == a:
			m += 0.35
			break
	return m


func mil_battles() -> void:
	var fronts := {}
	for f in mil["units"]:
		if int(f["fight"]) >= 0:
			var x: int = int(f["fight"])
			if not fronts.has(x):
				fronts[x] = []
			(fronts[x] as Array).append(f)
	var w: Dictionary = mil["war"]
	for x in fronts:
		var att: Array = fronts[x]
		var acc := String(att[0]["cc"])
		var aside := mil_side(acc)
		var dfn: Array = mil_hostile_units_at(int(x), acc)
		if dfn.is_empty():
			for f in att:
				f["fight"] = -1
				if not (f["sea"] as Dictionary).is_empty():
					mil_land(f)
			continue
		var pa := 0.0
		for f in att:
			pa += mil_pw(f) * ar_att(f) * (0.55 if not (f["sea"] as Dictionary).is_empty() else 1.0)
		pa *= ar_combined(att) * ar_air_mult(aside)
		var pd := 0.0
		for f in dfn:
			pd += mil_pw(f) * ar_def(f, int(x))
		pd *= mil_def_mult(int(x), 1 - aside) * ar_air_mult(1 - aside)
		for f in att:
			ar_ammo_use(f)
		for f in dfn:
			ar_ammo_use(f)
		pa = maxf(pa, 0.01)
		pd = maxf(pd, 0.01)
		var r: float = pa / pd
		var ld: float = 0.02 * pa * mil_rng.randf_range(0.7, 1.3)
		var la: float = 0.02 * pd * mil_rng.randf_range(0.7, 1.3)
		var sa := 0.0
		for f in att:
			sa += float(f["str"])
		var sdn := 0.0
		for f in dfn:
			sdn += float(f["str"])
		ld = minf(ld, sdn * 0.08)
		la = minf(la, sa * 0.08)
		for f in att:
			f["str"] = maxf(0.0, float(f["str"]) - la * float(f["str"]) / maxf(sa, 0.01))
			f["org"] = maxf(0.0, float(f["org"]) - 0.06 * clampf(1.0 / r, 0.2, 5.0))
		for f in dfn:
			f["str"] = maxf(0.0, float(f["str"]) - ld * float(f["str"]) / maxf(sdn, 0.01))
			f["org"] = maxf(0.0, float(f["org"]) - 0.06 * clampf(r, 0.2, 5.0))
		(w["kia"] as Array)[aside] = float(w["kia"][aside]) + la
		(w["kia"] as Array)[1 - aside] = float(w["kia"][1 - aside]) + ld
		# исход: сломленные защитники отходят или сдаются, сломленные атакующие прекращают атаку
		var def_left := 0
		for f in dfn:
			if float(f["org"]) < 0.2 or float(f["str"]) < 0.25 * float(f["max"]):
				mil_retreat(f)
			else:
				def_left += 1
		var att_left := 0
		for f in att:
			# сломленные прекращают атаку; самостоятельные (не по прямому приказу) — и при явно проигранном бою
			if float(f["org"]) < 0.2 or (r < 0.6 and String(f["mode"]) != "move" and float(f["org"]) < 0.8):
				f["fight"] = -1
				f["path"] = []
				if not (f["sea"] as Dictionary).is_empty():
					mil_evacuate(f)
			else:
				att_left += 1
		if def_left == 0:
			mil_battle_end(aside, int(x), true)
		elif att_left == 0:
			mil_battle_end(aside, int(x), false)
	mil_cleanup()


func mil_battle_end(aside: int, x: int, att_won: bool) -> void:
	var w: Dictionary = mil["war"]
	var we_won: bool = (aside == 0) == att_won
	if we_won:
		w["won"] = int(w["won"]) + 1
	else:
		w["lost"] = int(w["lost"]) + 1
	var nm := ate_name(x)
	if aside == 0:
		mil_log(("наступление у «%s» успешно: противник отходит." if att_won else "атака у «%s» отбита, наши части отходят на исходные.") % nm, COL_GOOD if att_won else COL_BAD)
	else:
		mil_log(("противник прорвал оборону у «%s»." if att_won else "атака противника у «%s» отбита.") % nm, COL_BAD if att_won else COL_GOOD)


func mil_retreat(f: Dictionary) -> void:
	var a: int = int(f["a"])
	var cc := String(f["cc"])
	var sd := mil_side(cc)
	var best := -1
	var bd := 1e18
	var home: Vector2 = ate_c[int(ate_cap.get(cc, a))] if ate_cap.has(cc) and int(ate_cap[cc]) >= 0 else ate_c[a]
	for b in ate_nbs(a):
		if mil_side(mil_ctl(b)) != sd or not mil_hostile_units_at(b, cc).is_empty() or not mil_passable(b, cc):
			continue
		var d: float = ate_c[b].distance_squared_to(home)
		if d < bd:
			bd = d
			best = b
	f["fight"] = -1
	f["path"] = []
	if best < 0:
		# окружены: сдаются в плен
		var w: Dictionary = mil["war"]
		(w["kia"] as Array)[sd] = float(w["kia"][sd]) + float(f["str"]) * 0.3
		mil_log("%s (%s) окружена и сдалась (%.1f тыс.)." % [String(f["nm"]), String(WORLD[cc]["name"]) if WORLD.has(cc) else cc, float(f["str"])], COL_GOOD if sd == 1 else COL_BAD)
		f["str"] = 0.0
		return
	f["a"] = best
	f["prog"] = 0.0
	f["org"] = maxf(float(f["org"]), 0.12)


func mil_cleanup() -> void:
	var units: Array = mil["units"]
	for i in range(units.size() - 1, -1, -1):
		if float(units[i]["str"]) < 0.6:
			var f: Dictionary = units[i]
			if String(f["cc"]) == ccode and float(f["str"]) > 0.0:
				mil_log("%s разгромлена и расформирована." % String(f["nm"]), COL_BAD)
			if int(mil["sel"]) == int(f["id"]):
				mil["sel"] = -1
			units.remove_at(i)


func mil_recover() -> void:
	for f in mil["units"]:
		var sd := mil_side(String(f["cc"]))
		if int(f["fight"]) >= 0:
			continue
		var a: int = int(f["a"])
		var sup: bool = a < 0 or sd < 0 or (mil_supply[sd] as Dictionary).is_empty() or (mil_supply[sd] as Dictionary).has(a)
		if sup:
			var home: bool = a >= 0 and ate_cc(a) == String(f["cc"])
			f["org"] = minf(1.0, float(f["org"]) + (0.05 if home else 0.03) * ar_org_mult(String(f["cc"])))
			if float(f["str"]) < float(f["max"]):
				var add: float = float(f["max"]) * (0.004 if String(f["cc"]) == ccode else 0.003)
				f["str"] = minf(float(f["max"]), float(f["str"]) + add)
				if String(f["cc"]) == ccode:
					debt += add * 0.02
		else:
			f["org"] = maxf(0.05, float(f["org"]) - 0.02)
			f["str"] = maxf(0.0, float(f["str"]) - float(f["str"]) * 0.004)


# снабжение: АТЕ, связанные через свою (или занятую) территорию с собственной землёй стороны
func mil_supply_update() -> void:
	mil_idx()
	var no: PackedInt32Array = ATE["no"]
	var nb: PackedInt32Array = ATE["nb"]
	for sd in 2:
		var seen := {}
		var q := PackedInt32Array()
		for a in ate_n:
			if mil_os[a] == sd and mil_cs[a] == sd:
				seen[a] = true
				q.append(a)
		var k := 0
		while k < q.size():
			var a: int = q[k]
			k += 1
			for j in range(no[a], no[a + 1]):
				var b: int = nb[j]
				if not seen.has(b) and mil_cs[b] == sd and mil_os[b] >= 0:
					seen[b] = true
					q.append(b)
		mil_supply[sd] = seen


# ============================================================
#  ИИ: ОБОРОНА, КОНТРНАСТУПЛЕНИЕ, НАСТУПЛЕНИЕ
# ============================================================


func mil_plan(side: int) -> void:
	var mine: Array = []
	for f in mil["units"]:
		if mil_side(String(f["cc"])) != side or int(f["fight"]) >= 0 or not (f["sea"] as Dictionary).is_empty() or int(f["a"]) < 0:
			continue
		if String(f["cc"]) == ccode and not (String(f["mode"]) in ["auto", "def"]):
			continue
		mine.append(f)
	if mine.is_empty():
		return
	mil_un_build()
	var no: PackedInt32Array = ATE["no"]
	var nb: PackedInt32Array = ATE["nb"]
	var pw_me := mil_side_power(side)
	var pw_en := maxf(0.01, mil_side_power(1 - side))
	var ratio: float = pw_me / pw_en
	var w: Dictionary = mil["war"]
	var en_cap := -1
	var tgt_cc: String = ccode if side == 1 else String(w["lead"])
	if ate_cap.has(tgt_cc) and int(ate_cap[tgt_cc]) >= 0:
		en_cap = int(ate_cap[tgt_cc])
	var ebit: int = 1 << (1 - side)
	var claimed := {}
	var k := 0
	for f in mine:
		k += 1
		var order := mil_bfs(int(f["a"]), String(f["cc"]))
		if float(f["org"]) < 0.35:
			# потрёпанное соединение отводят в тыл — на свою АТЕ, рядом с которой нет войск противника
			f["path"] = []
			for ai in order:
				if mil_cs[ai] != side or (mil_un[ai] & ebit) != 0:
					continue
				var calm := true
				for j2 in range(no[ai], no[ai + 1]):
					if (mil_un[nb[j2]] & ebit) != 0:
						calm = false
						break
				if calm:
					if ai != int(f["a"]):
						f["path"] = mil_path_to(ai)
					break
			continue
		var occ_home := -1
		var near_en := -1
		var frontier := -1
		var en_unit := -1
		var intruder := -1
		var home_line := -1
		for ai in order:
			if home_line < 0 and mil_os[ai] == side and mil_cs[ai] == side:
				home_line = ai
			var cs: int = mil_cs[ai]
			if occ_home < 0 and mil_os[ai] == side and cs != side:
				occ_home = ai
			if intruder < 0 and mil_os[ai] == side and (mil_un[ai] & ebit) != 0:
				intruder = ai
			if near_en < 0 and cs >= 0 and cs != side and not claimed.has(ai):
				near_en = ai
			if en_unit < 0 and (mil_un[ai] & ebit) != 0:
				en_unit = ai
			if frontier < 0 and cs == side and not claimed.has(ai):
				for j2 in range(no[ai], no[ai + 1]):
					var b: int = nb[j2]
					if mil_cs[b] >= 0 and mil_cs[b] != side:
						frontier = ai
						break
			if occ_home >= 0 and near_en >= 0 and frontier >= 0 and en_unit >= 0 and intruder >= 0 and home_line >= 0:
				break
		var tgt := -1
		# v50: в затяжной позиционной войне (идёт с начала игры) ИИ наступает только при заметном перевесе
		var off_thr: float = 1.9 if bool(w.get("ongoing", false)) else 1.15
		var offense: bool = (ratio >= off_thr and String(f["cc"]) != ccode) or (String(f["mode"]) == "auto" and String(f["cc"]) == ccode and ratio >= 0.9)
		# при перевесе часть сил гонится за прорвавшимися соединениями противника, остальные освобождают землю
		if intruder >= 0 and ratio > 1.0 and k % 2 == 0:
			tgt = intruder
		elif occ_home >= 0 and ratio > 0.7:
			tgt = occ_home
		elif offense:
			if k % 3 == 0 and en_cap >= 0 and mil_reached(en_cap):
				tgt = en_cap
			elif k % 3 == 1 and en_unit >= 0 and ratio > 1.4:
				tgt = en_unit
			else:
				tgt = near_en if near_en >= 0 else en_unit
		elif mil_os[int(f["a"])] != side and home_line >= 0 and (ratio < 0.75 or (not (mil_supply[side] as Dictionary).is_empty() and not (mil_supply[side] as Dictionary).has(int(f["a"])))):
			tgt = home_line      # перевес у противника или нет снабжения — отходим на свою землю, пока не окружили
		else:
			tgt = frontier
		if tgt < 0 or tgt == int(f["a"]):
			f["path"] = []
			continue
		claimed[tgt] = true
		f["path"] = mil_path_to(tgt)
		f["prog"] = minf(float(f["prog"]), 0.5)


# ============================================================
#  ДЕСАНТ
# ============================================================


func mil_amp_cap() -> float:
	if not flt_has_sea() or bool(flt.get("land", true)):
		return 0.0
	return float(int(flt["navy"].get("amp", 0))) * 6.0 + float(int(flt["navy"].get("car", 0))) * 3.0


func mil_land_check(id: int, to: int) -> String:
	mil_coast_build()
	var f := mil_unit(id)
	if f.is_empty() or String(f["cc"]) != ccode:
		return "Выберите своё соединение."
	if not mil_at_war():
		return "Десант возможен только во время войны."
	if not (f["sea"] as Dictionary).is_empty() or int(f["fight"]) >= 0:
		return "Соединение занято."
	if not mil_coast.has(int(f["a"])):
		return "Соединение должно стоять на побережье."
	if to < 0 or not mil_coast.has(to):
		return "Цель должна быть на побережье."
	if mil_side(mil_ctl(to)) != 1:
		return "Цель — побережье, занятое противником."
	var cap := mil_amp_cap()
	if cap <= 0.0:
		return "Нет десантных кораблей (их можно заказать на экране флота)."
	if float(f["str"]) > cap + 0.01:
		return "Корабли поднимут только %.0f тыс. человек, в соединении %.1f тыс." % [cap, float(f["str"])]
	var nd := String(mil_coast[to])
	var my_pow := fleet_power()
	for c in (mil["war"]["nv"] as Dictionary):
		var e: Dictionary = mil["war"]["nv"][c]
		if String(e["node"]) == nd and float(e["pow"]) > my_pow * 0.8:
			return "У цели господствует флот противника: сначала разбейте его или уведите."
	return ""


func mil_land_order(id: int, to: int) -> String:
	var why := mil_land_check(id, to)
	if why != "":
		return why
	var f := mil_unit(id)
	var p := flt_path(String(mil_coast[int(f["a"])]), String(mil_coast[to]))
	var days: int = 2 + int(ceil(flt_path_len(p) / 350.0))
	f["sea"] = {"to": to, "days": days, "from": int(f["a"])}
	f["a"] = -1
	f["path"] = []
	f["mode"] = "hold"
	mil_log("%s погрузилась на корабли: десант на «%s» через %d сут." % [String(f["nm"]), ate_name(to), days], COL_TEAL)
	return ""


func mil_sea_day() -> void:
	for f in mil["units"]:
		var s: Dictionary = f["sea"]
		if s.is_empty() or int(f["fight"]) >= 0:
			continue
		s["days"] = int(s["days"]) - 1
		if int(s["days"]) > 0:
			continue
		var to: int = int(s["to"])
		if mil_hostile_units_at(to, String(f["cc"])).is_empty():
			mil_land(f)
		else:
			f["fight"] = to


func mil_land(f: Dictionary) -> void:
	var to: int = int(f["sea"]["to"])
	var ferry: bool = bool(f["sea"].get("ferry", false))
	f["sea"] = {}
	f["a"] = to
	f["fight"] = -1
	mil_take(to, String(f["cc"]))
	mil_log(("%s переброшена морем в «%s»." if ferry else "%s высадилась на «%s».") % [String(f["nm"]), ate_name(to)], COL_TEAL if ferry else COL_GOOD)


func mil_evacuate(f: Dictionary) -> void:
	var fr: int = int(f["sea"].get("from", -1))
	f["sea"] = {}
	f["fight"] = -1
	f["str"] = float(f["str"]) * 0.9
	if fr < 0 or mil_side(mil_ctl(fr)) != mil_side(String(f["cc"])):
		var sp := mil_home_spots(String(f["cc"]), 1)
		fr = int(sp[0]) if not sp.is_empty() else 0
	f["a"] = fr
	mil_log("десант %s отбит, остатки эвакуированы." % String(f["nm"]), COL_BAD)


# ============================================================
#  ВОЙНА НА МОРЕ: ЭСКАДРЫ, СРАЖЕНИЯ, БЛОКАДА
# ============================================================


func mil_nav_station_set(nid: String) -> void:
	if mil_on() and flt_nodes.has(nid):
		mil["nav"]["station"] = nid


func mil_navy_day() -> void:
	var w: Dictionary = mil["war"]
	var nv: Dictionary = w["nv"]
	var st := String(mil["nav"].get("station", ""))
	var my_pow: float = fleet_power() if (flt_has_sea() and not bool(flt.get("land", true))) else 0.0
	var my_ports := mil_port_nodes(ccode)
	w["blk_e"] = false
	w["blk_p"] = false
	for c in nv:
		var e: Dictionary = nv[c]
		if float(e["pow"]) <= 0.5:
			e["node"] = String(e["home"])
			continue
		# противник ищет боя, если сильнее; иначе прикрывает свои порты
		if st != "" and float(e["pow"]) > my_pow * 1.1:
			e["node"] = st
		elif not my_ports.is_empty() and float(e["pow"]) > my_pow * 1.1:
			e["node"] = String(my_ports[0])
		else:
			e["node"] = String(e["home"])
		if st != "" and String(e["node"]) == st and my_pow > 0.0 and mil_rng.randf() < 0.12:
			mil_naval_battle(String(c), e)
			my_pow = fleet_power()
		if st != "" and st in (e["ports"] as Array) and (String(e["node"]) != st or float(e["pow"]) < my_pow * 0.5) and my_pow > 0.0:
			w["blk_e"] = true
		if String(e["node"]) in my_ports and float(e["pow"]) > 0.5 and (st != String(e["node"]) or my_pow < float(e["pow"]) * 0.5):
			w["blk_p"] = true
			if flt_has_sea():
				(flt["inc"] as Dictionary)[String(e["node"])] = {"sev": 0.55, "days": 2, "kind": "вражеская блокада"}
				fleet_recalc_f()


func mil_naval_battle(c: String, e: Dictionary) -> void:
	var my_pow := fleet_power()
	var dmg_me: float = float(e["pow"]) * 0.06 * mil_rng.randf_range(0.6, 1.4)
	var dmg_e: float = my_pow * 0.06 * mil_rng.randf_range(0.6, 1.4)
	e["pow"] = maxf(0.0, float(e["pow"]) - dmg_e)
	var lost: PackedStringArray = []
	var guard := 0
	while dmg_me > 0.3 and fleet_power() > 0.0 and guard < 40:
		guard += 1
		var ids: Array = []
		for cl in FLEET["classes"]:
			for t in int(flt["navy"].get(String(cl["id"]), 0)):
				ids.append(cl)
		if ids.is_empty():
			break
		var cl2: Dictionary = ids[mil_rng.randi() % ids.size()]
		if float(cl2["pow"]) > dmg_me * 1.6 and mil_rng.randf() < 0.6:
			break
		flt["navy"][String(cl2["id"])] = int(flt["navy"][String(cl2["id"])]) - 1
		dmg_me -= float(cl2["pow"])
		lost.append(String(cl2["one"]))
	var w: Dictionary = mil["war"]
	var won: bool = dmg_e >= float(e["pow"]) * 0.5 or lost.size() <= 1
	if won:
		w["nwon"] = int(w["nwon"]) + 1
	else:
		w["nlost"] = int(w["nlost"]) + 1
	mil_log("морской бой с флотом «%s» в районе «%s»: противник потерял ≈%.0f ед. мощи, мы — %s." % [String(WORLD[c]["name"]), String(flt_nodes[String(e["node"])]["name"]) if flt_nodes.has(String(e["node"])) else "", dmg_e, (", ".join(lost) if not lost.is_empty() else "ни одного корабля")], COL_GOOD if won else COL_BAD)


# ============================================================
#  ВОЕННЫЙ СЧЁТ, УСТАЛОСТЬ, ЭКОНОМИКА
# ============================================================


func mil_occ(side: int) -> float:
	# доля населения стороны side, оказавшаяся под контролем противника
	if not mil_at_war():
		return 0.0
	var w: Dictionary = mil["war"]
	var popd: Dictionary = w["pop"]
	var s := 0.0
	for a in mil["ctl"]:
		if mil_side(ate_cc(int(a))) == side and mil_side(String(mil["ctl"][a])) != side:
			s += float(popd.get(int(a), 0.0))
	return s / maxf(0.001, float(w["tot"][side]))


func mil_cap_held(cc: String) -> bool:
	return ate_cap.has(cc) and int(ate_cap[cc]) >= 0 and mil_side(mil_ctl(int(ate_cap[cc]))) != mil_side(cc)


func mil_score_update() -> void:
	var w: Dictionary = mil["war"]
	var oe := mil_occ(1)
	var op := mil_occ(0)
	w["occ"] = [op, oe]
	var cap_e: bool = mil_cap_held(String(w["lead"]))
	var cap_p: bool = mil_cap_held(ccode)
	w["cap_lost"] = int(w["cap_lost"]) + 1 if cap_p else 0
	var bb: float = clampf(float(int(w["won"]) - int(w["lost"])) * 1.5 + float(int(w["nwon"]) - int(w["nlost"])) * 2.0, -20.0, 20.0)
	var ka: float = float(w["kia"][0])
	var kb: float = float(w["kia"][1])
	var kr: float = clampf((kb - ka) / maxf(5.0, ka + kb) * 10.0, -10.0, 10.0)
	var sc: float = 160.0 * oe - 160.0 * op + (12.0 if cap_e else 0.0) - (12.0 if cap_p else 0.0) + bb + kr + (6.0 if bool(w["blk_e"]) else 0.0) - (6.0 if bool(w["blk_p"]) else 0.0)
	# армия противника разбита полностью
	if mil_side_power(1) < 0.5:
		sc += 25.0
	if mil_side_power(0) < 0.5:
		sc -= 25.0
	w["score"] = clampf(sc, -100.0, 100.0)
	w["weary"] = float(w["weary"]) + 1.0 / 30.0 + (op * 0.05)


func mil_month() -> void:
	if not mil_on() or game_over:
		return
	if int(mil["dm"]) == 0:
		for k in 30:
			mil_day()
			if game_over:
				return
	mil["dm"] = 0
	war_timers_month()
	var tr: Dictionary = mil["truce"]
	for c in tr.keys():
		tr[c] = int(tr[c]) - 1
		if int(tr[c]) <= 0:
			tr.erase(c)
	var lf: Dictionary = mil["loss"]
	for c in lf.keys():
		lf[c] = minf(1.0, float(lf[c]) + 0.03)
		if float(lf[c]) >= 1.0:
			lf.erase(c)
	# мирное время: армия подтягивается к численности, которую оплачивает бюджет
	var cap := mil_cap()
	var have := mil_regular_total()
	var regs: Array = []
	for f in mil_units_of(ccode):
		if String(f["kind"]) == "reg":
			regs.append(f)
	if not regs.is_empty() and have > cap * 1.03:
		var k2: float = maxf(cap / have, 0.95)
		for f in regs:
			f["max"] = float(f["max"]) * k2
			f["str"] = minf(float(f["str"]), float(f["max"]))
	elif not regs.is_empty() and have < cap * 0.97 and (mil["rec"] as Array).is_empty():
		var k3: float = minf(cap / maxf(have, 0.1), 1.03)
		for f in regs:
			f["max"] = minf(float(f["max"]) * k3, MIL_DIV * 1.6)
	var q := mil_q(ccode)
	for f in regs:
		f["q"] = lerpf(float(f["q"]), q, 0.15)
		if not mil_at_war():
			f["str"] = minf(float(f["max"]), float(f["str"]) + float(f["max"]) * 0.05)
			f["org"] = 1.0
	# содержание резервистов
	var mk := mil_mob_k()
	if mk > 0.0:
		debt += mk * 0.006
		add_support("Молодёжь", -0.4 * float(mil["mob"]))
	if mil_at_war():
		mil_war_month()
	else:
		mil_fix_positions()
		mil_ai_declare()
	ar_month()


func mil_war_month() -> void:
	var w: Dictionary = mil["war"]
	var months: float = float(w["days"]) / 30.0
	if bool(w.get("ongoing", false)):
		# v50: расходы на идущую войну уже в бюджете (ползунок обороны) — в долг идёт только сверх стартовой армии
		debt += maxf(0.0, mil_total(ccode) - float((w["str0"] as Dictionary).get(ccode, 0.0))) * 0.004
	else:
		debt += gdp * 0.0025 + mil_total(ccode) * 0.004
	var op: float = float(w["occ"][0])
	# в демократии затяжная наступательная война бьёт по рейтингу сильнее
	var dk: float = 1.0 + (0.6 * war_demo(ccode) * war_demo(String(w["lead"])) if bool(w["aggr"]) else 0.0)
	add_support("Молодёжь", (-0.8 - op * 6.0) * dk)
	add_support("Пенсионеры", -0.4 - op * 4.0)
	add_support("Рабочие", -0.4 - op * 4.0)
	add_support("Экологи", -0.5)
	if bool(w["aggr"]):
		add_support("Бизнес", -0.5 * dk)
		add_support("Пенсионеры", -0.3 * (dk - 1.0))
	if float(w["score"]) > 10.0:
		add_support("Силовики", 0.8)
	elif float(w["score"]) < -10.0:
		add_support("Силовики", -0.8)
	# экономика противника
	for c in w["side"]:
		if int(w["side"][c]) == 1 and wsim.has(c):
			var ws: Dictionary = wsim[c]
			ws["growth"] = float(ws["growth"]) - 0.5 - float(w["occ"][1]) * 6.0 - (0.4 if bool(w["blk_e"]) else 0.0)
	# противник объявляет мобилизацию, если проигрывает
	# (в войне, идущей с начала игры, противник уже мобилизовался — новая волна только при тяжёлых неудачах)
	var mob_need: bool = float(w["score"]) > 25.0 if bool(w.get("ongoing", false)) else (float(w["score"]) > 15.0 or months > 2.0)
	if int(w["mob_ai"]) == 0 and mob_need:
		w["mob_ai"] = 1
		var lead := String(w["lead"])
		var b: Array = MIL_BASE[lead]
		var popk: float = float(WORLD[lead].get("pop", 5.0)) * 1000.0
		var add: float = maxf(float(b[1]) * 0.6, popk * 0.003)
		var n: int = clampi(int(round(add / MIL_DIV)), 1, 20)
		var home := mil_home_spots(lead, n)
		for k in n:
			var f := mil_new_unit(lead, add / float(n), float(b[2]) * 0.8, int(home[k % home.size()]), "res")
			f["mode"] = "auto"
		mil_log("«%s» объявила мобилизацию: +%.0f тыс. резервистов." % [String(WORLD[lead]["name"]), add], COL_WARN)
	war_intl_month()
	# чистка контроля над АТЕ, сменившими владельца
	for a in (mil["ctl"] as Dictionary).keys():
		if mil_side(ate_cc(int(a))) < 0:
			(mil["ctl"] as Dictionary).erase(a)
			mil_dirty = true


func mil_fix_positions() -> void:
	# после передачи земли: свои части на чужой территории возвращаются домой
	for f in mil_units_of(ccode):
		if int(f["a"]) >= 0 and ate_cc(int(f["a"])) != ccode:
			var sp := mil_home_spots(ccode, 1)
			if not sp.is_empty():
				f["a"] = int(sp[0])
			f["path"] = []
			f["sea"] = {}
			f["fight"] = -1


func mil_mob_g() -> float:
	if not mil_on():
		return 0.0
	var labor: float = maxf(100.0, total_pop() * 1000.0 * 0.5)
	return -mil_mob_k() / labor * 100.0 * 1.5


func mil_g() -> float:
	if not mil_on():
		return 0.0
	var g: float = mil_mob_g() + ar_war_g()
	if mil_at_war():
		var w: Dictionary = mil["war"]
		g -= 0.8 + minf(8.0, float(w["occ"][0]) * 40.0)
		if bool(w["sanct"]):
			g -= 1.2
	g += war_intl_g()
	var out: float = clampf(g, -14.0, 0.0) + war_trade_g()
	# v50: у войны, идущей на старте, стартовые потери уже учтены в экономике страны — считаются только изменения
	if mil_at_war() and (mil["war"] as Dictionary).has("g0"):
		out -= float(mil["war"]["g0"])
	return out


func mil_infl() -> float:
	if not mil_on():
		return 0.0
	if not mil_at_war():
		return ar_war_infl()
	var base0: float = float((mil["war"] as Dictionary).get("i0", 0.0))
	if int(mil["war"].get("cf", 0)) > 0:
		return 0.6 - base0
	return 1.2 + (0.6 if bool(mil["war"]["sanct"]) else 0.0) + war_intl_infl() + ar_war_infl() - base0


func mil_unemp() -> float:
	if not mil_on():
		return 0.0
	var labor: float = maxf(100.0, total_pop() * 1000.0 * 0.5)
	return -mil_mob_k() / labor * 100.0 * 0.7


func mil_dip_term(c: String) -> float:
	if mil.is_empty():
		return 0.0
	if not mil_at_war():
		return war_dip_extra(c)
	var sd := mil_side(c)
	if sd == 1:
		return -60.0
	if sd == 0:
		return 5.0
	return (-18.0 if bool(mil["war"]["sanct"]) else -6.0) + war_dip_extra(c)


# ============================================================
#  МИР
# ============================================================


func mil_occupied_by_us(cc: String) -> Array:
	var out: Array = []
	for a in mil.get("ctl", {}):
		if ate_cc(int(a)) == cc and String(mil["ctl"][a]) == ccode and int(a) != int(ate_cap.get(cc, -1)):
			out.append(int(a))
	return out


func mil_peace_quote(kind: String) -> Dictionary:
	var q := {"ok": false, "why": "", "need": 0.0, "kind": kind}
	if not mil_at_war():
		q["why"] = "Войны нет."
		return q
	var w: Dictionary = mil["war"]
	var sc: float = float(w["score"])
	var months: float = float(w["days"]) / 30.0
	var lead := String(w["lead"])
	var occ_n := 0
	for c in w["side"]:
		if int(w["side"][c]) == 1:
			occ_n += mil_occupied_by_us(String(c)).size()
	var cap_e: bool = mil_cap_held(lead)
	var need := 0.0
	match kind:
		"white":
			need = -10.0 - months * 1.5
		"repar":
			need = 35.0
		"annex":
			need = 15.0 + float(w["occ"][1]) * 100.0 - (20.0 if cap_e else 0.0)
			if occ_n == 0:
				q["why"] = "Вы не занимаете земель противника."
				return q
		"capit":
			need = 50.0 if cap_e else 75.0
		"full":
			need = 90.0
			if not cap_e:
				q["why"] = "Нужно занять столицу противника."
				return q
	q["need"] = need
	if int(w["prop_cd"]) > 0 and kind != "white":
		q["why"] = "Противник недавно отверг предложение (ещё %d сут.)." % int(w["prop_cd"])
		return q
	q["ok"] = sc >= need
	if not bool(q["ok"]):
		q["why"] = "Военный счёт %+.0f, нужно не меньше %+.0f." % [sc, need]
	return q


func mil_peace_propose(kind: String) -> Dictionary:
	var q := mil_peace_quote(kind)
	if not bool(q["ok"]):
		if mil_at_war() and String(q["why"]).begins_with("Военный счёт"):
			mil["war"]["prop_cd"] = 20
			capital = maxf(0.0, capital - 2.0)
			mil_log("противник отверг мирное предложение. " + String(q["why"]), COL_BAD)
		return {"done": false, "msg": String(q["why"])}
	return mil_peace(kind)


# заключение мира. kind: white, repar, annex, capit, full — условия игрока; lose_cede, lose_capit — условия противника.
# terms (v38) — пакет требований с переговоров: {land|border|repar(%)|disarm|dmz|fleet|trade|guilt|neutral: …}
func mil_peace(kind: String, terms: Dictionary = {}) -> Dictionary:
	if not mil_at_war():
		return {"done": false, "msg": "Войны нет."}
	var w: Dictionary = mil["war"]
	var lead := String(w["lead"])
	var enemies: Array = mil_side_ccs(1)
	var parts: PackedStringArray = []
	var won: bool = kind in ["repar", "annex", "capit", "full"] or not terms.is_empty()
	var lost: bool = kind.begins_with("lose")
	var annexed := false
	# земли
	if kind == "annex" or kind == "capit":
		for c in enemies:
			var sel := mil_occupied_by_us(String(c))
			if terms.has("border") and not terms.has("land"):
				sel = talk_border_ates(String(c))
			if sel.is_empty() or not wsim.has(c):
				continue
			var r := mil_annex(String(c), sel)
			if r != "":
				parts.append(r)
				annexed = true
	if lost and kind != "lose_pay":
		for c in enemies:
			var sel2: Array = []
			for a in mil["ctl"]:
				if ate_cc(int(a)) == ccode and String(mil["ctl"][a]) == String(c) and int(a) != int(ate_cap.get(ccode, -1)):
					sel2.append(int(a))
			if not sel2.is_empty() and wsim.has(c):
				parts.append(mil_cede(sel2, String(c)))
	# деньги
	if (kind == "repar" or kind == "capit" or terms.has("repar")) and wsim.has(lead):
		var amt: float = float(wsim[lead]["gdp"]) * (float(terms["repar"]) / 100.0 if terms.has("repar") else (0.02 if kind == "repar" else 0.03))
		debt = maxf(0.0, debt - amt)
		wsim[lead]["debt"] = float(wsim[lead]["debt"]) + amt / maxf(1.0, float(wsim[lead]["gdp"])) * 100.0
		parts.append("репарации %.1f млрд € (долг уменьшен)" % amt)
	if lost:
		var amt2: float = gdp * (0.01 if kind == "lose_cede" else 0.03)
		if kind == "lose_pay":
			amt2 = gdp * 0.03 + 0.01 * gdp * clampf(-float(w["score"]) / 40.0 - 1.0, 0.0, 2.0)
		debt += amt2
		parts.append("вы выплачиваете %.1f млрд € репараций" % amt2)
	var full_msg := ""
	if kind == "full" and wsim.has(lead):
		var res := union_absorb(lead, 0, float(WORLD[lead].get("debt", 0.0)) * 0.8)
		full_msg = String(res.get("msg", ""))
		parts.append("страна «%s» полностью присоединена" % String(WORLD[lead]["name"]))
		annexed = true
	if not terms.is_empty():
		talk_apply(terms, enemies, lead, parts)
	# аннексия земель демократии нападавшим не признаётся
	if annexed and bool(w["aggr"]) and war_demo(lead) >= 0.5:
		var nr: Dictionary = mil.get("nonrec", {})
		nr[lead] = 36
		mil["nonrec"] = nr
		parts.append("мир не признаёт аннексию (3 года)")
	# конец войны
	var nm := String(WORLD[lead]["name"]) if WORLD.has(lead) else lead
	var title := {"white": "белый мир — довоенные границы", "repar": "мир с репарациями", "annex": "мир с присоединением занятых земель",
		"capit": "капитуляция противника", "full": "капитуляция и полное присоединение", "lose_cede": "мир на условиях противника", "lose_capit": "капитуляция",
		"lose_pay": "мир с выкупом: земли остаются за вами, но вы платите противнику"}
	var msg := "Мир со страной «%s»: %s" % [nm, "мир на ваших условиях" if not terms.is_empty() and kind != "capit" else String(title.get(kind, kind))]
	if not parts.is_empty():
		msg += "; " + "; ".join(parts)
	msg += "."
	mil["last"] = {"lead": lead, "name": nm, "kind": kind, "score": float(w["score"]), "days": int(w["days"]), "kia": (w["kia"] as Array).duplicate(), "msg": msg}
	for c in enemies:
		var c_s := String(c)
		var s0: float = float((w["str0"] as Dictionary).get(c_s, 1.0))
		var left := mil_total(c_s)
		(mil["loss"] as Dictionary)[c_s] = clampf(left / maxf(1.0, s0), 0.3, 1.0) * (0.5 if kind == "capit" or kind == "full" else 1.0)
		(mil["truce"] as Dictionary)[c_s] = MIL_TRUCE
	var units: Array = mil["units"]
	for i in range(units.size() - 1, -1, -1):
		if String(units[i]["cc"]) != ccode:
			units.remove_at(i)
	for f in mil_units_of(ccode):
		f["fight"] = -1
		f["path"] = []
		f["mode"] = "hold"
		if not (f["sea"] as Dictionary).is_empty():
			f["a"] = int(f["sea"].get("from", 0))
			f["sea"] = {}
	mil["war"] = {}
	mil["ctl"] = {}
	mil_dirty = true
	mil["ctl_ver"] = int(mil["ctl_ver"]) + 1
	mil_supply = [{}, {}]
	if flt_has_sea():
		for nid in (flt["inc"] as Dictionary).keys():
			if String(flt["inc"][nid].get("kind", "")) == "вражеская блокада":
				(flt["inc"] as Dictionary).erase(nid)
		fleet_recalc_f()
	mil_fix_positions()
	if won:
		add_support("Силовики", 4.0)
		for g in ["Рабочие", "Пенсионеры", "Бизнес", "Село"]:
			add_support(g, 2.0)
		capital = minf(100.0, capital + 5.0)
	elif lost:
		for g in GROUPS:
			add_support(g, -3.0)
		add_support("Силовики", -4.0)
	else:
		add_support("Молодёжь", 2.0)
		add_support("Бизнес", 2.0)
	log_line("[b][color=%s]%s: %s[/color][/b]" % [COL_GOOD if not lost else COL_BAD, date_text(), msg])
	if full_msg != "":
		log_line(full_msg)
	mil_log(msg, COL_GOOD if not lost else COL_BAD)
	if kind == "lose_capit" and not opp_mode:
		opp_enter("Правительство подписало капитуляцию и ушло в отставку.")
	refresh()
	return {"done": true, "msg": msg}


# присоединение занятых АТЕ страны cc (части, граничащие со своими регионами, входят в них; остальное — новая территория)
func mil_annex(cc: String, sel: Array) -> String:
	var n_ate := 0
	var pop := 0.0
	for comp in ate_groups(sel):
		var votes := {}
		for a in comp:
			for b in ate_nbs(int(a)):
				var ri := ate_region(b)
				if ri >= 0:
					votes[ri] = int(votes.get(ri, 0)) + 1
		var dst := -1
		var bv := 0
		for ri in votes:
			if int(votes[ri]) > bv:
				bv = int(votes[ri])
				dst = int(ri)
		if dst < 0 and regions.size() >= ADM_MAX_REG:
			dst = 0
		var q := ate_buy_quote(comp, 1.0, dst)
		if not q.has("parts"):
			continue
		pop += float(q["pop"])
		n_ate += comp.size()
		ate_attach(q, comp, dst)
	if n_ate == 0:
		return ""
	return "присоединено %d АТЕ страны «%s» (%.2f млн жителей)" % [n_ate, String(WORLD[cc]["name"]), pop]


# передача своих АТЕ стране cc (поражение): целые регионы — целиком, части — через временный регион
func mil_cede(sel: Array, cc: String) -> String:
	var by := {}
	var pop := 0.0
	for a in sel:
		var ri := ate_region(int(a))
		if ri < 0:
			continue
		if not by.has(ri):
			by[ri] = []
		(by[ri] as Array).append(int(a))
		pop += ate_pop(int(a))
	var whole: Array = []
	var partial: Array = []
	for ri in by:
		if (by[ri] as Array).size() >= adm_region_ates(int(ri)).size():
			whole.append(int(ri))
		else:
			partial.append_array(by[ri])
	if not partial.is_empty():
		var src := ate_region(int(partial[0]))
		var ni := adm_new_region(src, "Уступаемая территория")
		adm_apply_moves(partial, ni)
		recalc_weights()
		whole.append(ni)
	whole.sort()
	for k in range(whole.size() - 1, -1, -1):
		var i: int = int(whole[k])
		if i >= regions.size() or regions.size() < 2:
			continue
		recalc_weights()
		var g_r: float = gdp * float(gdp_w[i])
		terr_transfer(i, cc, g_r, 0.0)
	if not partial.is_empty():
		adm_upper_seat(-1)
	return "уступлено %d АТЕ (%.2f млн жителей) стране «%s»" % [sel.size(), pop, String(WORLD[cc]["name"])]


# ============================================================
#  ИИ: МИРНЫЕ ПРЕДЛОЖЕНИЯ И ОБЪЯВЛЕНИЕ ВОЙНЫ
# ============================================================


func mil_ai_peace() -> void:
	var w: Dictionary = mil["war"]
	var sc: float = float(w["score"])
	# вынужденная капитуляция — не раньше двух месяцев войны: за это время можно мобилизоваться и ответить
	if int(w["days"]) >= 60 and (sc <= -90.0 or (int(w["cap_lost"]) >= 20 and sc <= -60.0)):
		mil_log("армия разбита, столица под угрозой: правительство вынуждено подписать капитуляцию.", COL_BAD)
		mil_peace("lose_capit")
		return
	if int(w["offer_cd"]) > 0 or not current_event.is_empty() or election_open:
		return
	var nm := String(WORLD[String(w["lead"])]["name"])
	if sc >= 80.0:
		w["offer_cd"] = 60
		var ks: Array = ["", "capit"]
		var op: Array = [{"l": "Продолжать войну", "fx": {}}, {"l": "Принять капитуляцию: занятые АТЕ и репарации", "fx": {"support": {"Силовики": 2.0}}}]
		if mil_cap_held(String(w["lead"])) and sc >= 90.0:
			ks.append("full")
			op.append({"l": "Присоединить всю страну", "fx": {"support": {"Силовики": 3.0, "Молодёжь": -3.0}}})
		mil_event(ks, "«%s» проиграла войну и готова капитулировать. Военный счёт %+.0f." % [nm, sc], op)
	elif sc <= -40.0:
		w["offer_cd"] = 45
		var pay: float = (0.03 + 0.01 * clampf(-sc / 40.0 - 1.0, 0.0, 2.0)) * 100.0
		mil_event(["", "lose_cede", "lose_pay"], "«%s» предлагает мир: вы уступаете занятые ею земли и платите репарации (1%% ВВП). Через посредников можно выторговать другой вариант: оставить земли, но заплатить больше. Военный счёт %+.0f." % [nm, sc],
			[{"l": "Отклонить: воюем дальше", "fx": {"support": {"Силовики": 1.0}}}, {"l": "Принять мир на условиях противника", "fx": {}},
			{"l": "Выкупить земли: репарации %.0f%% ВВП" % pay, "fx": {"support": {"Бизнес": -1.0}}}])
	elif sc >= 25.0 and int(w["days"]) >= 45 and mil_rng.randf() < 0.35:
		# противник сам предлагает уступки — столько, сколько готов отдать при нынешнем счёте
		w["offer_cd"] = 50
		var want: Array = []
		for id in ["land", "repar", "trade", "guilt", "disarm", "dmz"]:
			if talk_avail(id) == "":
				want.append([id, 1 if id == "repar" else 0])
		var b := talk_budget()
		var cnt: Array = []
		var c := 0.0
		for it in want:
			var ci := talk_cost(String(it[0]), int(it[1]))
			if c + ci <= b:
				cnt.append(it)
				c += ci
		if not cnt.is_empty():
			mil["cnt"] = cnt
			mil_event(["", "talk_cnt"], "«%s» проигрывает и сама предлагает мир: %s. Военный счёт %+.0f." % [nm, talk_pkg_text(cnt), sc],
				[{"l": "Отклонить: добиваться большего", "fx": {}}, {"l": "Принять предложение", "fx": {"support": {"Бизнес": 1.0}}}])
	elif float(w["days"]) > 120.0 and absf(sc) < 12.0 and mil_rng.randf() < 0.3:
		w["offer_cd"] = 60
		mil_event(["", "white"], "Фронт встал. «%s» предлагает белый мир — вернуться к довоенным границам. Военный счёт %+.0f." % [nm, sc],
			[{"l": "Отклонить: воюем дальше", "fx": {}}, {"l": "Принять белый мир", "fx": {"support": {"Молодёжь": 2.0}}}])


func mil_event(kinds: Array, text: String, opts: Array) -> void:
	mil["pend"] = {"kinds": kinds}
	current_event = {"t": text, "special": "war", "o": opts}
	event_region = -1
	present_event()


# после выбора варианта события войны (вызывается из choose())
func mil_resolve(i: int) -> void:
	var p: Dictionary = mil.get("pend", {})
	mil["pend"] = {}
	if p.is_empty():
		return
	var ks: Array = p.get("kinds", [])
	var k: String = String(ks[i]) if i < ks.size() else ""
	if k == "mob1":
		mil_mobilize(1)
	elif not mil_at_war():
		return
	elif k == "talk_cnt":
		var cnt: Array = mil.get("cnt", [])
		var t := talk_terms(cnt)
		mil_peace("annex" if t.has("land") or t.has("border") else "white", t)
	elif k == "press_cf":
		talk_ceasefire()
	elif k == "press_med":
		var r := talk_mediator()
		if not bool(r["done"]):
			talk_ceasefire()
	elif k == "press_no":
		var it := war_intl(mil["war"])
		it["cond"] = minf(100.0, float(it["cond"]) + 10.0)
		war_sanctions_update(mil["war"])
		mil_log("вы отвергли требование прекратить огонь: осуждение растёт, санкций больше.", COL_BAD)
	elif k != "":
		mil_peace(k)


# v49: союзники-покровители: нападение на страну — нападение и на покровителя (учитывается его сила)
const MIL_PATRON := {"BY": "RU"}


func mil_ai_declare() -> void:
	if int(game_opts.get("milev", 1)) == 0 or opp_mode or turn < 12 or not current_event.is_empty() or election_open:
		return
	var my_pow: float = maxf(1.0, mil_country_power(ccode))
	# v49: статья 5 — нападение на члена НАТО означает войну со всем союзом: агрессор учитывает его силу
	var nato_pow := -1.0
	for cc in mil_targets():
		if not mil_land_neighbor(cc) or int((mil["truce"] as Dictionary).get(cc, 0)) > 0 or ar_deterred(cc):
			continue
		var rel := fed_rel(cc)
		if rel >= 15.0:
			continue
		# v49: у страны-покровителя (Беларусь — Россия) нападение на союзника означает войну с ним самим
		var guard: float = 0.0
		var pat: String = String(MIL_PATRON.get(ccode, ""))
		if pat != "" and pat != cc and WORLD.has(pat):
			guard = 0.6 * mil_country_power(pat)
		if mil_is_nato(ccode) and not mil_is_nato(cc) and not (ccode in mil.get("neutral", [])):
			if nato_pow < 0.0:
				nato_pow = 0.0
				for n in wsim:
					if n != ccode and mil_is_nato(String(n)) and MIL_BASE.has(n):
						nato_pow += mil_country_power(String(n))
			guard += 0.35 * nato_pow
		var ratio: float = mil_country_power(cc) / (my_pow + guard)
		if ratio < 1.4:
			continue
		var p: float = 0.01 * (15.0 - rel) / 15.0 * minf(2.0, ratio - 1.3)
		# v49: демократии почти не начинают захватнических войн (Польша 6%, Сербия 43%, Россия — 100% прежней вероятности)
		p *= clampf(1.6 * pow(1.0 - clampf(float(MIL_DEMO.get(cc, 0.5)), 0.0, 1.0), 2.0), 0.03, 1.0)
		if mil_rng.randf() >= p:
			continue
		var friends := mil_allies_for(ccode, cc)
		mil_start_war(cc, [], friends, false)
		var msg := "«%s» объявила вам войну! Её войска перешли границу." % String(WORLD[cc]["name"])
		if not friends.is_empty():
			msg += " Союзники по НАТО вступают в войну на вашей стороне."
		log_line("[b][color=%s]%s: %s[/color][/b]" % [COL_BAD, date_text(), msg])
		mil_log(msg, COL_BAD)
		for g in GROUPS:
			add_support(g, 2.0)      # сплочение вокруг флага
		mil_event(["", "mob1"], msg + " Что делаем?", [{"l": "Обороняться кадровой армией", "fx": {}}, {"l": "Объявить частичную мобилизацию (капитал −3)", "fx": {}}])
		return


func mil_status_text() -> String:
	if not mil_on():
		return "Армии нет."
	var t := "Армия: [b]%.0f[/b] тыс. в %d соединениях · бюджет содержит [b]%.0f[/b] тыс. · выучка [b]%.2f[/b]" % [mil_total(ccode), mil_units_of(ccode).size(), mil_cap(), mil_q(ccode)]
	if int(mil["mob"]) > 0:
		t += " · мобилизация: [b]%s[/b]" % ("частичная" if int(mil["mob"]) == 1 else "всеобщая")
	return t
