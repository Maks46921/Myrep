# Партийный ИИ: идеологии, политический капитал партий, правление без вас, законопроекты и поправки.
extends "res://scripts/logic/opposition.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func autobalance_step(target: float = -1.0, big: bool = false) -> bool:
	return false


func autopilot_step() -> void:
	pass


func corp_state_share() -> float:
	return 0.0


func gov_style_step() -> void:
	pass


func nt_toast(text: String, cls: String, desk: int) -> void:
	pass


func tip_make(title: String, secs: Array = []) -> String:
	return ""


func vote_plan_live() -> bool:
	return false


func vote_plan_open(bid: int) -> void:
	pass


func vt_plan_busy() -> bool:
	return false


# --- конец заглушек ---


# ============================================================
#  ИДЕОЛОГИИ И СТРАТЕГИИ
#  Идеология партии не выдумана для каждой страны отдельно, а выводится из её электората (LEAN):
#  чего хочет электорат от бюджета (GROUP_FX), то партия и считает «своей политикой».
#  К этому добавляется архетип со стратегией:
#   aus   — склонность к экономии (+1 режет расходы, −1 раздаёт);
#   bold  — насколько далеко от стартового курса партия готова уходить;
#   aggr  — как охотно атакует соперников;
#   coop  — как охотно договаривается и входит в коалиции.
# ============================================================
const ARCH := {
	"social": {"n": "левая, социальная", "aus": -0.6, "bold": 1.0, "aggr": 0.5, "coop": 0.6,
		"d": "Опора — рабочие, бюджетники и пенсионеры. Повышает социальные расходы и пенсии, не боится дефицита, мирится с высокими налогами на богатых."},
	"liberal": {"n": "либеральная, рыночная", "aus": 0.7, "bold": 0.9, "aggr": 0.4, "coop": 0.7,
		"d": "Опора — бизнес и молодёжь. Снижает налоги и госаппарат, держит бюджет сбалансированным, поддерживает рост и предпринимателей."},
	"conserv": {"n": "консервативная, порядок и село", "aus": 0.3, "bold": 0.8, "aggr": 0.5, "coop": 0.5,
		"d": "Опора — силовики, село и старшее поколение. Усиливает армию и полицию, помогает аграриям и инфраструктуре, осторожна с новыми тратами."},
	"green": {"n": "зелёная, экологическая", "aus": -0.2, "bold": 1.0, "aggr": 0.3, "coop": 0.8,
		"d": "Опора — экологи и молодёжь. Вкладывается в климат и образование, сокращает субсидии вредным отраслям, охотно идёт в коалиции."},
	"populist": {"n": "популистская, протестная", "aus": -0.5, "bold": 1.2, "aggr": 1.0, "coop": 0.2,
		"d": "Обещает быстрые решения, резко атакует власть и «элиты», с трудом находит союзников."},
}


func ideo_keys() -> Array:
	var out: Array = []
	for d in POLICY:
		if float(d["max"]) > float(d["min"]):
			out.append(String(d["key"]))
	return out


func ideo_valid(q: int) -> bool:
	return q == 0 or (q > 0 and q < PARTY_NAMES.size() and not (q in NO_PLAY_SLOTS))


func lean_share(p: int) -> Dictionary:
	var ck := "s%d" % p
	if ideo_c.has(ck):
		return ideo_c[ck]
	var tot := 0.0
	var sh := {}
	for g in GROUPS:
		var v: float = party_lean(g, p) * float(GROUP_WEIGHT[g])
		sh[g] = v
		tot += v
	for g in GROUPS:
		sh[g] = float(sh[g]) / maxf(0.0001, tot)
	ideo_c[ck] = sh
	return sh


func ideo_d(p: int) -> Dictionary:
	var ck := "d%d" % p
	if ideo_c.has(ck):
		return ideo_c[ck]
	var sh := lean_share(p)
	var out := {}
	for k in ideo_keys():
		var v := 0.0
		for g in GROUPS:
			var c: float = float((GROUP_FX[g] as Dictionary).get(k, 0.0))
			if k == "agri":
				c += float(AGRI_FX.get(g, 0.0))
			v += float(sh[g]) * c
		out[k] = v
	ideo_c[ck] = out
	return out


func ideo_stat(k: String) -> Array:
	var ck := "t" + k
	if ideo_c.has(ck):
		return ideo_c[ck]
	var vals: Array = []
	for q in PARTY_NAMES.size():
		if ideo_valid(q):
			vals.append(float((ideo_d(q) as Dictionary)[k]))
	var m := 0.0
	for v in vals:
		m += float(v)
	m /= float(maxi(1, vals.size()))
	var s2 := 0.0
	for v in vals:
		s2 += (float(v) - m) * (float(v) - m)
	var sd := maxf(0.05, sqrt(s2 / float(maxi(1, vals.size()))))
	ideo_c[ck] = [m, sd]
	return ideo_c[ck]


func party_arch(p: int) -> String:
	var ck := "a%d" % p
	if ideo_c.has(ck):
		return ideo_c[ck]
	var res := "conserv"
	if p == PROTEST_P:
		res = "populist"
	else:
		var avg := {}
		var cnt := 0.0
		for q in PARTY_NAMES.size():
			if ideo_valid(q):
				cnt += 1.0
				for g in GROUPS:
					avg[g] = float(avg.get(g, 0.0)) + float(lean_share(q)[g])
		var r := {}
		var sh := lean_share(p)
		for g in GROUPS:
			r[g] = float(sh[g]) / maxf(0.0001, float(avg[g]) / maxf(1.0, cnt))
		var sc := {
			"social": (float(r["Рабочие"]) + float(r["Бюджетники"]) + 0.5 * float(r["Пенсионеры"])) / 2.5,
			"liberal": (float(r["Бизнес"]) + float(r["Молодёжь"])) / 2.0,
			"conserv": (float(r["Силовики"]) + float(r["Село"]) + 0.5 * float(r["Пенсионеры"])) / 2.5,
			"green": 2.0 * float(r["Экологи"]) / 2.0,
		}
		var bs := -1.0
		for k in sc:
			if float(sc[k]) > bs:
				bs = float(sc[k])
				res = k
	ideo_c[ck] = res
	return res


func ideo_stance(p: int, k: String) -> float:
	var d: float = float((ideo_d(p) as Dictionary)[k])
	var st: Array = ideo_stat(k)
	var s: float = clampf((d - float(st[0])) / float(st[1]), -1.5, 1.5) / 1.5
	if String(policy_by_key[k]["kind"]) == "spend":
		s -= 0.3 * float((ARCH[party_arch(p)] as Dictionary)["aus"])
	return clampf(s, -1.0, 1.0)


func ideo_target(p: int, k: String) -> float:
	var d: Dictionary = policy_by_key[k]
	var rng: float = float(d["max"]) - float(d["min"])
	var bold: float = float((ARCH[party_arch(p)] as Dictionary)["bold"])
	return clampf(float(pol_def[k]) + ideo_stance(p, k) * 0.22 * rng * bold, float(d["min"]), float(d["max"]))


# программа правительства: средневзвешенная по местам идеология партий коалиции, глава весит в полтора раза
func gov_stance(members: Array, pm: int, k: String) -> float:
	var num := 0.0
	var den := 0.0
	for q in members:
		var w := float(maxi(1, seats[int(q)])) * (1.5 if int(q) == pm else 1.0)
		num += w * ideo_stance(int(q), k)
		den += w
	return num / maxf(0.0001, den)


func gov_target(members: Array, pm: int, k: String) -> float:
	var d: Dictionary = policy_by_key[k]
	var rng: float = float(d["max"]) - float(d["min"])
	var bold: float = float((ARCH[party_arch(pm)] as Dictionary)["bold"])
	return clampf(float(pol_def[k]) + gov_stance(members, pm, k) * 0.22 * rng * bold, float(d["min"]), float(d["max"]))


# шаг политики к программе: расходы всегда, налоги — только если есть запас по дефициту
# v35: какой дефицит ИИ-правительство считает допустимым: стартовый (но не меньше 3% ВВП),
# а при долге выше 90% ВВП — 3%, при долге выше 120% — 2%
func ai_def_lim() -> float:
	var dr: float = debt / maxf(1.0, gdp) * 100.0
	if dr > 120.0:
		return 2.0
	if dr > 90.0:
		return 3.0
	return maxf(3.0, def0)


func ai_policy_step(members: Array, pm: int, strength: float) -> int:
	var moved := 0
	var room: bool = last_deficit_pct < ai_def_lim() + 0.4
	for k in ideo_keys():
		if k == "emit" or lock_active(k):
			continue
		var d: Dictionary = policy_by_key[k]
		var rng: float = float(d["max"]) - float(d["min"])
		var cur: float = float(pol[k])
		var step: float = clampf(gov_target(members, pm, k) - cur, -0.04 * rng * strength, 0.04 * rng * strength)
		if absf(step) < 0.01:
			continue
		# v35: при большом дефиците не делаем шагов, которые его увеличивают (раньше блокировались любые налоговые шаги,
		# в том числе повышение, а рост расходов — никогда, и дефицит ИИ-правительства уходил за 10% ВВП)
		var worse: bool = (step < 0.0) if String(d["kind"]) == "tax" else (step > 0.0)
		if worse and not room:
			continue
		set_policy(k, cur + step)
		moved += 1
	# v35: дефицит намного выше обычного — правительство подтягивает доходы
	var lim: float = ai_def_lim()
	if last_deficit_pct > lim + 1.0:
		autobalance_step(lim, true)
		ap_log.clear()
	return moved


func ideo_label(p: int) -> String:
	return String((ARCH[party_arch(p)] as Dictionary)["n"])


# ============================================================
#  ВЕРНОСТЬ ПАРТИЙНОЙ ЛИНИИ ИГРОКА
# ============================================================
func idl_planks() -> Array:
	var ck := "planks"
	if ideo_c.has(ck):
		return ideo_c[ck]
	var arr: Array = []
	for k in ideo_keys():
		var s := ideo_stance(0, k)
		if absf(s) >= 0.4:
			arr.append({"key": k, "dir": 1.0 if s > 0.0 else -1.0, "st": absf(s)})
	arr.sort_custom(func(a, b) -> bool: return float(a["st"]) > float(b["st"]))
	ideo_c[ck] = arr.slice(0, 5)
	return ideo_c[ck]


func plank_dev(pl: Dictionary) -> float:
	var d: Dictionary = policy_by_key[String(pl["key"])]
	var rng: float = float(d["max"]) - float(d["min"])
	return float(pl["dir"]) * (float(pol[String(pl["key"])]) - float(pol_def[String(pl["key"])])) / rng


func idl_mult() -> float:
	return clampf(0.55 + 0.45 * idl / 70.0, 0.55, 1.1)


func idl_step() -> void:
	if game_over:
		return
	# v35: в оппозиции курс определяет чужое правительство — однопартийцы не ставят его вам в вину,
	# недовольство остывает. Раньше верность линии падала в оппозиции, и съезд снимал лидера в первый же месяц у власти.
	if opp_mode:
		idl = clampf(idl + (70.0 - idl) * 0.05, 0.0, 100.0)
		idl_low = 0
		return
	var ok := 0.0
	var viol := 0.0
	for pl in idl_planks():
		var dev := plank_dev(pl)
		if dev < -0.06:
			viol += minf(2.0, (-dev - 0.06) / 0.06)
		elif dev > 0.06:
			ok += 1.0
	var jn: Dictionary = junior_info()
	if bool(jn["junior"]):
		viol *= 0.6
	idl = clampf(idl + 0.35 * ok - 0.9 * viol + (70.0 - idl) * 0.03, 0.0, 100.0)
	if idl < 40.0 and not idl_warned:
		idl_warned = true
		log_tag("ПАРТИЯ", COL_WARN, "однопартийцы недовольны: ваш курс расходится с программой партии (верность линии %.0f/100). Политкапитал копится медленнее." % idl)
	elif idl >= 50.0:
		idl_warned = false
	idl_low = idl_low + 1 if idl < 20.0 else 0
	if idl_low >= 3 and not opp_mode:
		end_game("Партия потеряла доверие к вашему курсу: съезд отстранил вас от руководства (верность линии %.0f/100)." % idl)


func idl_react(p: int, kind: String) -> void:
	var cls := ""
	for x in PACT_KINDS:
		if String(x["id"]) == kind:
			cls = String(x["cls"])
	if (cls == "friend" or cls == "support") and kind != "talk" and party_sim(0, p) < 0.45:
		idl = clampf(idl - 3.0, 0.0, 100.0)
		log_tag("ПАРТИЯ", COL_WARN, "однопартийцы недовольны союзом с идеологически далёкой «%s» (верность линии -3)." % PARTY_NAMES[p])
	elif cls == "hostile" and party_sim(0, p) > 0.8:
		idl = clampf(idl - 2.0, 0.0, 100.0)


func ideology_text() -> String:
	var a: Dictionary = ARCH[party_arch(0)]
	var t := "[b]Идеология вашей партии:[/b] %s. %s\n" % [ideo_label(0), String(a["d"])]
	var jn: Dictionary = junior_info()
	if bool(jn["junior"]):
		t += "[color=%s]Вы — младший партнёр: глава правительства «%s». Власть ограничена на %.0f%%: меньше политкапитала, бюджет меняется медленнее, а закон без согласия партии главы не пройдёт.[/color]\n" % [COL_WARN, PARTY_NAMES[int(jn["pm"])], (1.0 - float(jn["power"])) * 100.0]
	t += "[b]Верность партийной линии:[/b] %.0f/100 (политкапитал ×%.2f).\n" % [idl, idl_mult()]
	var lines: PackedStringArray = []
	for pl in idl_planks():
		var dev := plank_dev(pl)
		var mark := "✓" if dev > 0.06 else ("✗" if dev < -0.06 else "·")
		lines.append("%s %s: %s" % [mark, policy_title(String(pl["key"])), "больше" if float(pl["dir"]) > 0.0 else "меньше"])
	if lines.size() > 0:
		t += "[b]Принципы партии:[/b] " + "; ".join(lines) + "."
	return t


# ============================================================
#  МЛАДШИЙ ПАРТНЁР
# ============================================================
func junior_info() -> Dictionary:
	var res := {"junior": false, "power": 1.0, "pm": 0}
	if opp_mode or not in_coalition[0]:
		return res
	var pm := 0
	for p in PARTY_NAMES.size():
		if in_coalition[p] and seats[p] > seats[pm]:
			pm = p
	# 0.56: глава правительства по коалиционному соглашению
	if not coal_deal.is_empty():
		var dp: int = int(coal_deal.get("pm", -1))
		if dp == 0:
			return res
		if dp > 0 and dp < in_coalition.size() and in_coalition[dp]:
			pm = dp
	if pm == 0 or pm_lead:
		return res
	var share: float = float(seats[0]) / float(maxi(1, gov_seats()))
	res["junior"] = true
	res["pm"] = pm
	res["power"] = clampf(0.35 + 0.9 * share, 0.4, 0.85)
	return res


func junior_power() -> float:
	return float(junior_info()["power"])


# ============================================================
#  0.56 (п.18): ИСТОЧНИКИ ПОЛИТИЧЕСКОГО КАПИТАЛА
#  Правящая партия получает капитал от мест, поста главы правительства, министерств и «экономической власти»
#  (доля госсектора и поддержка бизнеса); неправящая — по доле голосов. Таблица весов — CAP_W.
# ============================================================
# 0.56 (доп. 8): капитал растёт в 1,5 раза быстрее (было: основа 0,2, места 1,2, глава правительства 0,2, младший партнёр 0,05,
# министерство 0,025, экономика 0,15, голоса 1,5, глава государства 0,15, рейтинг 0,2)
const CAP_K := 1.5
const CAP_W := {"base": 0.30, "seats": 1.80, "pm": 0.30, "junior": 0.075, "min": 0.0375, "econ": 0.225, "votes": 2.25, "pres": 0.225, "appr": 0.30}
var cap_vs_turn := -1
var cap_vs := 0.0


func cap_vote_share() -> float:
	if cap_vs_turn != turn:
		cap_vs_turn = turn
		var sh := national_shares(false)
		cap_vs = float(sh[0]) if sh.size() > 0 else 0.0
	return cap_vs


func cap_sources() -> Array:
	var out: Array = [["Основа", CAP_W["base"]]]
	var gov: bool = not opp_mode and in_coalition.size() > 0 and in_coalition[0]
	if gov:
		var sh: float = float(seats[0]) / float(maxi(1, SEATS))
		out.append(["Места в парламенте (%.0f%%)" % (sh * 100.0), float(CAP_W["seats"]) * sh])
		if bool(junior_info()["junior"]):
			out.append(["Младший партнёр в коалиции", CAP_W["junior"]])
		else:
			out.append(["Пост главы правительства", CAP_W["pm"]])
		var nm := 0
		for m in ministries.size():
			if ministries[m] == 0:
				nm += 1
		if nm > 0:
			out.append(["Министерства (%d)" % nm, float(CAP_W["min"]) * float(nm)])
		var ep: float = 0.5 * corp_state_share() + 0.5 * float(support.get("Бизнес", 50.0)) / 100.0
		out.append(["Экономическая власть", float(CAP_W["econ"]) * ep])
		if approval() >= 55.0:
			out.append(["Рейтинг выше 55%", CAP_W["appr"]])
	else:
		var vs: float = cap_vote_share()
		out.append(["Доля голосов (%.0f%%)" % (vs * 100.0), float(CAP_W["votes"]) * vs])
	if pres_party == 0:
		out.append(["Глава государства из вашей партии", CAP_W["pres"]])
	var mb: float = float(mods["capital_bonus"]) * CAP_K
	if absf(mb) > 0.001:
		out.append(["Законы и устройство власти", mb])
	return out


func cap_mults() -> Array:
	var out: Array = [["Верность линии партии", idl_mult()]]
	if techno_until > turn:
		out.append(["Техническое правительство", 0.5])
	return out


# подсказка к капиталу: источники с цифрами
func cap_tip() -> String:
	var rows: Array = []
	for r in cap_sources():
		rows.append([String(r[0]), "%+.2f" % float(r[1])])
	var mrows: Array = []
	for r in cap_mults():
		mrows.append([String(r[0]), "×%.2f" % float(r[1])])
	var secs: Array = [["Источники в месяц", rows], ["Множители", mrows], ["Итого", [["Прирост в месяц", "%+.2f" % cap_rate()]]],
		["", "Капитал тратится на законы, действия и переговоры; за выполненные обещания партнёрам он возвращается. Тратить можно и в минус."]]
	if capital < 0.0:
		secs.append(["", "Внимание: капитал в минусе, риск отставки правительства %.0f%% в месяц." % (cap_neg_risk() * 100.0)])
	return tip_make("Политический капитал: %.1f" % capital, secs)


# ============================================================
#  КАПИТАЛ И ОТНОШЕНИЯ ПАРТИЙ
# ============================================================
func rel(a: int, b: int) -> float:
	if a == b:
		return 100.0
	if a == 0:
		return float(prel[b])
	if b == 0:
		return float(prel[a])
	return float((prm[a] as Array)[b])


func rel_add(a: int, b: int, d: float) -> void:
	if a == b:
		return
	if a == 0:
		prel[b] = clampf(float(prel[b]) + d, 0.0, 100.0)
	elif b == 0:
		prel[a] = clampf(float(prel[a]) + d, 0.0, 100.0)
	else:
		var v := clampf(float((prm[a] as Array)[b]) + d, 0.0, 100.0)
		(prm[a] as Array)[b] = v
		(prm[b] as Array)[a] = v


func prm_base(p: int, q: int) -> float:
	var b := 22.0 + 75.0 * clampf((party_sim(p, q) - 0.35) / 0.65, 0.0, 1.0)
	if p == PROTEST_P or q == PROTEST_P:
		b -= 18.0
	if in_coalition[p] and in_coalition[q]:
		b += 6.0
	return clampf(b, 4.0, 92.0)


func prm_init() -> void:
	var n := PARTY_NAMES.size()
	prm.clear()
	for p in n:
		if p == 0:
			prm.append(prel)
		else:
			var row: Array = []
			for q in n:
				row.append(prm_base(p, q) if q != 0 else 0.0)
			prm.append(row)
	for p in range(1, n):
		for q in range(p + 1, n):
			var v := prm_base(p, q)
			(prm[p] as Array)[q] = v
			(prm[q] as Array)[p] = v


func ai_init() -> void:
	var n := PARTY_NAMES.size()
	pcap.clear()
	for p in n:
		var sh: float = float(seats[p]) / float(maxi(1, SEATS))
		pcap.append(minf(70.0, 25.0 + sh * 80.0 + (8.0 if in_coalition[p] else 0.0)))
	ai_pen.clear()
	ai_blocs.clear()
	ai_stats.clear()
	ideo_c.clear()
	idl = 70.0
	idl_low = 0
	idl_warned = false
	bills.clear()
	bill_queue.clear()
	bill_seq = 0
	vote_sponsor = 0
	cost_mult = 1.0
	if prm.size() != n:
		prm_init()


func ai_note(kind: String) -> void:
	ai_stats[kind] = int(ai_stats.get(kind, 0)) + 1


func cap_swap(p: int) -> float:
	var old := capital
	if pcap.size() > p:
		capital = float(pcap[p])
		cap_ai = true
	return old


func cap_unswap(p: int, old: float) -> void:
	if pcap.size() > p:
		pcap[p] = clampf(capital, 0.0, 100.0)
	cap_ai = false
	capital = old


func autopilot_run() -> void:
	if opp_mode and not opp_gov.is_empty():
		var pm: int = int(opp_gov["pm"])
		var old := cap_swap(pm)
		gov_style_step()
		autopilot_step()
		cap_unswap(pm, old)
	else:
		autopilot_step()


# ============================================================
#  ЕЖЕМЕСЯЧНАЯ ЖИЗНЬ ПАРТИЙ
# ============================================================
func ai_parties_step() -> void:
	if game_over or PARTY_NAMES.size() < 3:
		return
	if pcap.size() != PARTY_NAMES.size() or prm.size() != PARTY_NAMES.size():
		ai_init()
	var n := PARTY_NAMES.size()
	# капитал: базовый прирост + вес в парламенте + правительство
	for p in range(1, n):
		if p == 6:
			continue
		var sh: float = float(seats[p]) / float(maxi(1, SEATS))
		var gain := 0.45 + 5.5 * sh + (0.7 if in_coalition[p] else 0.0)
		if p == PROTEST_P:
			gain = 0.8
		pcap[p] = minf(100.0, float(pcap[p]) + gain)
	# срок штрафов от атак
	for p in ai_pen.keys():
		ai_pen[p] = int(ai_pen[p]) - 1
		if int(ai_pen[p]) <= 0:
			ai_pen.erase(p)
	# отношения тянутся к базе, коалиционные — теплеют
	for p in range(1, n):
		for q in range(p + 1, n):
			var b := prm_base(p, q)
			var cur := float((prm[p] as Array)[q])
			rel_add(p, q, (b - cur) * 0.04)
	if not opp_mode:
		for id in opp_cd.keys():
			opp_cd[id] = maxi(0, int(opp_cd[id]) - 1)
		pacts_tick()
		for p in range(1, n):
			prel[p] = clampf(float(prel[p]) + (prel_base(p) - float(prel[p])) * 0.04, 0.0, 100.0)
	else:
		ai_gov_rule()
	for p in range(1, n):
		if p == 6 or pcap.size() <= p:
			continue
		if seats[p] <= 0 and p != PROTEST_P:
			continue
		ai_party_act(p)
	ai_bloc_plan()


func ai_party_act(p: int) -> void:
	var cp: float = float(pcap[p])
	if cp < 3.0:
		return
	var arch: Dictionary = ARCH[party_arch(p)]
	var aggr: float = float(arch["aggr"])
	var coop: float = float(arch["coop"])
	var in_gov: bool = in_coalition[p] or (opp_mode and not opp_gov.is_empty() and p in opp_gov["members"])
	var roll := randf()
	if opp_mode and not opp_gov.is_empty():
		var pm: int = int(opp_gov["pm"])
		if in_gov:
			if p != pm and roll < 0.35 * coop and cp >= 2.0:
				pcap[p] = cp - 2.0
				rel_add(p, pm, 3.0)
				ai_note("support")
			return
		# оппозиционная партия
		if roll < 0.18 + 0.25 * aggr and cp >= 3.0:
			pcap[p] = cp - 3.0
			var w := 0.6 + float(seats[p]) / float(SEATS) * 4.0
			opp_gov["stab"] = clampf(float(opp_gov["stab"]) - 0.9 * w, 0.0, 100.0)
			rel_add(p, pm, -5.0)
			ai_note("attack_gov")
			return
	elif not in_gov and p != 0:
		# вы у власти: оппозиция давит на ваше правительство
		if roll < 0.10 + 0.20 * aggr and cp >= 4.0:
			pcap[p] = cp - 4.0
			add_all_support(-0.18 * (0.5 + aggr))
			rel_add(0, p, -2.0)
			ai_note("attack_player")
			if randf() < 0.25:
				log_tag("ОППОЗИЦИЯ", COL_WARN, "«%s» развернула кампанию против вашего правительства." % PARTY_NAMES[p])
			return
	elif in_gov and p != 0 and not opp_mode:
		# партнёр по вашей коалиции: подпитывает отношения
		if roll < 0.2 * coop and cp >= 2.0:
			pcap[p] = cp - 2.0
			rel_add(0, p, 1.5)
			ai_note("support")
		return
	# между партиями: дружба с близкими, удар по заметным соперникам
	var best := -1
	var bs := -1.0
	var rival := -1
	var rv := -1.0
	for q in range(1, PARTY_NAMES.size()):
		if q == p or not ideo_valid(q) or seats[q] <= 0:
			continue
		var sm := party_sim(p, q)
		if sm > bs:
			bs = sm
			best = q
		var sc := float(seats[q]) * (1.0 - sm)
		if sc > rv:
			rv = sc
			rival = q
	if roll < 0.55 * coop and best >= 0 and bs > 0.5 and cp >= 3.0:
		pcap[p] = cp - 3.0
		rel_add(p, best, 6.0)
		ai_note("talk")
	elif roll > 1.0 - 0.18 * aggr and rival >= 0 and cp >= 3.0:
		pcap[p] = cp - 3.0
		rel_add(p, rival, -6.0)
		ai_pen[rival] = 4
		ai_note("attack_party")


func ai_bloc_plan() -> void:
	var left: int = parl_term() - (turn - last_parl)
	if left > 9 or left < 3:
		return
	var n := PARTY_NAMES.size()
	for p in range(1, n):
		if ai_blocs.has(p) or not ideo_valid(p) or seats[p] <= 0 or float(pcap[p]) < 6.0:
			continue
		for q in range(p + 1, n):
			if ai_blocs.has(q) or not ideo_valid(q) or seats[q] <= 0 or float(pcap[q]) < 6.0:
				continue
			if party_sim(p, q) > 0.62 and rel(p, q) > 52.0 and randf() < 0.3:
				pcap[p] = float(pcap[p]) - 6.0
				pcap[q] = float(pcap[q]) - 6.0
				ai_blocs[p] = q
				ai_blocs[q] = p
				ai_note("bloc")
				log_tag("ПАРТИИ", COL_PURPLE, "«%s» и «%s» объявили о совместной кампании." % [PARTY_NAMES[p], PARTY_NAMES[q]])
				break


# ============================================================
#  ПРАВИТЕЛЬСТВО БЕЗ ВАС
# ============================================================
func ai_gov_rule() -> void:
	if opp_gov.is_empty():
		return
	var members: Array = opp_gov["members"]
	var pm: int = int(opp_gov["pm"])
	# партнёры по коалиции: довольство зависит от близости и отношений
	if not opp_gov.has("sat"):
		opp_gov["sat"] = {}
	var sat: Dictionary = opp_gov["sat"]
	for q in members.duplicate():
		if int(q) == pm:
			continue
		var cur: float = float(sat.get(int(q), 60.0))
		cur += (party_sim(pm, int(q)) - 0.55) * 3.0 + (rel(pm, int(q)) - 50.0) * 0.03
		sat[int(q)] = clampf(cur, 0.0, 100.0)
		if float(sat[int(q)]) < 18.0 and members.size() > 1:
			members.erase(int(q))
			in_coalition[int(q)] = false
			ai_note("partner_left")
			log_tag("ПРАВИТЕЛЬСТВО", COL_WARN, "«%s» вышла из правящей коалиции: разногласия с «%s»." % [PARTY_NAMES[int(q)], PARTY_NAMES[pm]])
	opp_gov["seats"] = opp_gov_seats()
	# политика по программе коалиции
	var moved := ai_policy_step(members, pm, 1.0)
	if moved > 0:
		ai_note("policy_moves")
	# законопроект
	var has_bill := false
	for b in bills:
		if int(b["sponsor"]) == pm:
			has_bill = true
	if not has_bill and float(pcap[pm]) >= 14.0 and randf() < 0.33:
		ai_pick_law(pm)
	# потеря большинства — поиск партнёра или перестройка
	if int(opp_gov["seats"]) < MAJORITY and not minority_ok:
		if not ai_recruit(pm):
			# нет большинства: если есть другая рабочая коалиция — смена правительства, иначе живём меньшинством
			if ai_reshuffle("правительство потеряло большинство"):
				return
			opp_gov["stab"] = clampf(float(opp_gov["stab"]) - 0.5, 0.0, 100.0)
	# вотум недоверия слабому правительству: альтернативная коалиция
	if float(opp_gov["stab"]) < 30.0 and randf() < 0.25:
		ai_reshuffle("вотум недоверия")


func ai_recruit(pm: int) -> bool:
	var members: Array = opp_gov["members"]
	var best := -1
	var bs := 0.0
	for q in range(1, PARTY_NAMES.size()):
		if q in members or seats[q] <= 0 or (q in NO_GOV_SLOTS) or q == 0:
			continue
		var sc := party_sim(pm, q) + (rel(pm, q) - 50.0) / 250.0
		if sc > 0.34 and sc > bs:
			bs = sc
			best = q
	if best < 0:
		return false
	members.append(best)
	in_coalition[best] = true
	(opp_gov["sat"] as Dictionary)[best] = 60.0
	opp_gov["seats"] = opp_gov_seats()
	ai_note("recruit")
	log_tag("ПРАВИТЕЛЬСТВО", COL_NEUTRAL, "«%s» привлекла в коалицию «%s»." % [PARTY_NAMES[pm], PARTY_NAMES[best]])
	return int(opp_gov["seats"]) >= MAJORITY or minority_ok


func ai_reshuffle(why: String) -> bool:
	var g := ai_form_gov(false)
	var old_members: Array = opp_gov["members"]
	var same: bool = g.is_empty() or (int(g["pm"]) == int(opp_gov["pm"]) and (g["members"] as Array).size() == old_members.size())
	if not same and bool(g["ok"]) and int(g["seats"]) > int(opp_gov["seats"]):
		opp_set_gov(g)
		ai_note("reshuffle")
		log_tag("ПРАВИТЕЛЬСТВО", COL_WARN, "%s: сформирована новая коалиция — %s." % [why, opp_gov_text()])
		return true
	return false


func ai_pick_law(pm: int, members_in: Array = []) -> void:
	var members: Array = members_in if members_in.size() > 0 else opp_gov["members"]
	var cand: Array = []
	for t in LAW_TOPICS:
		var tid: String = String(t["id"])
		if not law_index.has(tid) or law_index[tid].has("param") or int(law_cd.get(tid, 0)) > 0 or law_locked(tid) != "" or bill_of(tid) >= 0:
			continue
		var cur := cur_idx(tid)
		var vs: Array = law_index[tid]["v"]
		for idx in vs.size():
			if idx == cur:
				continue
			if radical_req(tid, idx) != "" or String((vs[idx] as Dictionary).get("rid", "")) != "":
				continue
			var s := variant_stance(pm, tid, idx)
			var worst := 0.0
			for q in members:
				worst = minf(worst, variant_stance(int(q), tid, idx))
			var sc := s + 0.5 * worst
			if sc <= 0.6 or law_cost(tid, idx) > (capital if pm == 0 else float(pcap[pm])) - 4.0:
				continue
			cand.append([sc, tid, idx])
	cand.sort_custom(func(a, b) -> bool: return float(a[0]) > float(b[0]))
	var best_t := ""
	var best_i := -1
	var old_sp := vote_sponsor
	vote_sponsor = pm
	for c in cand.slice(0, 8):
		var vv := variant_votes(String(c[1]), int(c[2]), [])
		if int(vv["yes"]) >= law_need(String(c[1]), vv) and not bool(upper_check(String(c[1]), int(c[2]), [])["block"]):
			best_t = String(c[1])
			best_i = int(c[2])
			break
	vote_sponsor = old_sp
	if best_i < 0:
		return
	if pm != 0 and not pa_bill_slot_free(best_t):
		return
	if pm == 0:
		# v35: режим наблюдателя — законопроект вашей партии вносит ИИ обычным порядком
		propose_variant(best_t, best_i)
		return
	bill_seq += 1
	bills.append({"id": bill_seq, "tid": best_t, "idx": best_i, "sponsor": pm, "start": turn, "due": turn + 2 + randi() % 2, "forced": [], "pow": 1.0, "req": [], "paid": 0.0, "pv": "line"})
	ai_note("bill_proposed")
	log_tag("ЗАКОНОПРОЕКТ", COL_PURPLE, "правительство («%s») внесло законопроект «%s»: %s." % [PARTY_NAMES[pm], law_index[best_t]["name"], variant_of(best_t, best_i)["n"]])


# ============================================================
#  ЗАКОНОПРОЕКТЫ: прохождение во времени, просьбы о поправках, ваши поправки
# ============================================================
func bill_of(tid: String) -> int:
	for i in bills.size():
		if String(bills[i]["tid"]) == tid:
			return i
	return -1


func bill_index(bid: int) -> int:
	for i in bills.size():
		if int(bills[i]["id"]) == bid:
			return i
	return -1


func bill_forced(b: Dictionary) -> Array:
	var f: Array = (b["forced"] as Array).duplicate()
	for r in b["req"]:
		if int(r["state"]) == 1 and not (int(r["p"]) in f):
			f.append(int(r["p"]))
	return f


func bill_preview(b: Dictionary) -> Dictionary:
	var tid: String = String(b["tid"])
	var saved: float = float(law_pow_sel.get(tid, 1.0))
	if is_hybrid(tid):
		law_pow_sel[tid] = float(b["pow"])
	var old_sp := vote_sponsor
	vote_sponsor = int(b["sponsor"])
	var v := variant_votes(tid, int(b["idx"]), bill_forced(b))
	vote_sponsor = old_sp
	if is_hybrid(tid):
		law_pow_sel[tid] = saved
	return v


func propose_variant(tid: String, idx: int, forced: Array = []) -> void:
	if game_over:
		return
	# v50: законопроекты вносят только партии, представленные в парламенте; указом — только правительство
	if not observer and pl_deny("parl"):
		return
	if radical_bypass(tid, idx) or (decree_power() and pl_gov()):
		adopt_variant(tid, idx, forced)
		return
	if idx == cur_idx(tid) and not law_tweak(tid):
		return
	var topic: Dictionary = law_index[tid]
	if bill_of(tid) >= 0:
		log_line("[color=%s]Законопроект «%s» уже рассматривается.[/color]" % [COL_WARN, topic["name"]])
		return
	if int(law_cd.get(tid, 0)) > 0:
		return
	var lk := law_locked(tid)
	if lk != "":
		log_line("[color=%s]Закон «%s» изменить нельзя: %s.[/color]" % [COL_BAD, topic["name"], lk])
		return
	var rq := radical_req(tid, idx)
	if rq != "":
		log_line("[color=%s]Закон «%s» не принят: %s[/color]" % [COL_BAD, topic["name"], rq])
		return
	var mine := 0
	for b in bills:
		if int(b["sponsor"]) == 0:
			mine += 1
	if mine >= 3:
		log_line("[color=%s]В работе уже три ваших законопроекта: дождитесь решения.[/color]" % COL_WARN)
		return
	var cost := law_cost(tid, idx)
	if cap_spendable() < cost:
		log_line("[color=%s]Для законопроекта «%s» не хватает политкапитала: нужно %.0f.[/color]" % [COL_BAD, topic["name"], cost])
		return
	var up := cost * 0.35
	capital -= up
	bill_seq += 1
	var months := 5 if is_fund(tid) else 3
	bills.append({"id": bill_seq, "tid": tid, "idx": idx, "sponsor": 0, "start": turn, "due": turn + months, "forced": forced.duplicate(), "pow": float(law_pow_sel.get(tid, 1.0)), "req": [], "paid": up, "did": {}})
	bill_sel = bill_seq
	log_tag("ЗАКОНОПРОЕКТ", COL_PURPLE, "внесён законопроект «%s»: %s. Голосование через %d мес.; взнос политкапитала %.0f. Ждите просьб о поправках или вносите свои." % [topic["name"], variant_of(tid, idx)["n"], months, up])
	refresh()


func bill_request_new(b: Dictionary) -> void:
	var tid: String = String(b["tid"])
	var idx: int = int(b["idx"])
	var forced := bill_forced(b)
	var cands: Array = []
	for r in b["req"]:
		if int(r["state"]) == 0:
			cands.append(int(r["p"]))
	var pick := -1
	var ps_best := 0.0
	var sponsor: int = int(b["sponsor"])
	for p in range(1, PARTY_NAMES.size()):
		if p == sponsor or seats[p] <= 0 or (p in NO_GOV_SLOTS) or p in forced or p in cands:
			continue
		var s := variant_stance(p, tid, idx)
		var need: bool = s < 0.0 or (in_coalition[p] and randf() < 0.2)
		var w: float = float(seats[p]) * (1.0 + maxf(0.0, -s))
		if need and w > ps_best:
			ps_best = w
			pick = p
	if pick < 0:
		return
	var s2 := variant_stance(pick, tid, idx)
	var kind := "money"
	var cost := 2.0 + maxf(0.0, -s2) * 0.6
	var txt := ""
	if is_hybrid(tid) and float(b["pow"]) > 0.55 and s2 > -5.0 and randf() < 0.6:
		kind = "soft"
		cost = 0.0
		txt = "«%s» просит смягчить закон: сила действия −0.2." % PARTY_NAMES[pick]
	elif randf() < 0.25:
		kind = "delay"
		cost = 0.0
		txt = "«%s» просит отложить голосование на месяц ради доработки." % PARTY_NAMES[pick]
	else:
		txt = "«%s» просит политической уступки за голоса (политкапитал −%.0f)." % [PARTY_NAMES[pick], cost]
	(b["req"] as Array).append({"p": pick, "kind": kind, "cost": cost, "state": 0, "txt": txt})
	if int(b["sponsor"]) == 0:
		log_tag("ПОПРАВКА", COL_TEAL, "законопроект «%s»: %s" % [law_index[tid]["name"], txt])


func bill_request(bid: int, ri: int, accept: bool) -> bool:
	var bi := bill_index(bid)
	if bi < 0:
		return false
	var b: Dictionary = bills[bi]
	var reqs: Array = b["req"]
	if ri < 0 or ri >= reqs.size() or int(reqs[ri]["state"]) != 0:
		return false
	var r: Dictionary = reqs[ri]
	var p: int = int(r["p"])
	if accept:
		if cap_spendable() < float(r["cost"]):
			return false
		capital -= float(r["cost"])
		r["state"] = 1
		match String(r["kind"]):
			"soft":
				b["pow"] = maxf(0.5, float(b["pow"]) - 0.2)
			"delay":
				b["due"] = int(b["due"]) + 1
		rel_add(0, p, 4.0)
	else:
		r["state"] = 2
		rel_add(0, p, -3.0)
	refresh()
	return true


# почему нельзя смягчить/усилить законопроект ("" — можно)
func bill_pow_block(b: Dictionary, kind: String) -> String:
	var tid: String = String(b["tid"])
	if int(b["idx"]) == 0:
		return "возврат к прежнему порядку не имеет силы действия"
	if not is_hybrid(tid):
		return "у этого закона нет шкалы силы (он задаёт точное значение)"
	if kind == "soft" and float(b["pow"]) <= 0.55:
		return "закон уже смягчён до минимума (0.5×)"
	if kind == "hard" and float(b["pow"]) >= 1.45:
		return "закон уже ужесточён до максимума (1.5×)"
	return ""


func bill_amend(bid: int, kind: String) -> bool:
	var bi := bill_index(bid)
	if bi < 0:
		return false
	var b: Dictionary = bills[bi]
	if int(b["sponsor"]) != 0:
		return false
	var tid: String = String(b["tid"])
	var did: Dictionary = b["did"]
	match kind:
		"soft", "hard":
			var why := bill_pow_block(b, kind)
			if why != "":
				log_line("[color=%s]Поправка невозможна: %s.[/color]" % [COL_WARN, why])
				return false
			var y0: int = int(bill_preview(b)["yes"])
			b["pow"] = snappedf(float(b["pow"]) + (-0.2 if kind == "soft" else 0.2), 0.1)
			var y1: int = int(bill_preview(b)["yes"])
			log_tag("ПОПРАВКА", COL_TEAL, "законопроект «%s» %s: сила действия %.1f×; голосов «за» %d → %d (нужно %d)." % [law_index[tid]["name"], "смягчён" if kind == "soft" else "ужесточён", float(b["pow"]), y0, y1, law_need(tid, bill_preview(b))])
		"sweet":
			if bool(did.get("sweet", false)) or cap_spendable() < 4.0:
				return false
			var added: PackedStringArray = []
			for p in range(1, PARTY_NAMES.size()):
				if seats[p] <= 0 or (p in NO_GOV_SLOTS) or p in b["forced"]:
					continue
				var s := variant_stance(p, tid, int(b["idx"]))
				if s < 0.0 and s >= -4.0:
					(b["forced"] as Array).append(p)
					added.append(PARTY_NAMES[p])
					rel_add(0, p, 2.0)
			capital -= 4.0
			did["sweet"] = true
			log_tag("ПОПРАВКА", COL_TEAL, "законопроект «%s»: компенсации и смягчающие поправки — %s согласны голосовать за." % [law_index[tid]["name"], ", ".join(added) if added.size() > 0 else "новых сторонников нет"])
		"fast":
			# v50: ускорение принятия закона отменено — парламент рассматривает законопроект в свой срок
			log_line("[color=%s]Ускорить рассмотрение нельзя: парламент работает в своём темпе.[/color]" % COL_WARN)
			return false
		"slow":
			if int(did.get("slow", 0)) >= 2:
				return false
			b["due"] = int(b["due"]) + 1
			did["slow"] = int(did.get("slow", 0)) + 1
		"withdraw":
			capital = minf(100.0, capital + float(b["paid"]) * 0.5)
			bills.remove_at(bi)
			log_tag("ЗАКОНОПРОЕКТ", COL_WARN, "законопроект «%s» отозван (возвращена половина взноса)." % law_index[tid]["name"])
		_:
			return false
	refresh()
	return true


# ---------- v50: поправки-оговорки: в пользу группы интересов, показателя страны или партии ----------
const RIDER_CHARS := {
	"env_lvl": ["Экологическая оговорка", "env", "Экологи"], "equality": ["Социальная оговорка", "benefits", "Рабочие"],
	"security_lvl": ["Оговорка о безопасности", "police", "Силовики"], "corruption": ["Антикоррупционная оговорка", "", ""],
	"edu_lvl": ["Оговорка об образовании", "edu", "Молодёжь"], "health_lvl": ["Оговорка о здравоохранении", "health", "Пенсионеры"],
	"infra_lvl": ["Оговорка о региональной инфраструктуре", "infra", "Село"],
}
const RIDER_MAX := 4


func bill_rider_list(b: Dictionary) -> Array:
	if not b.has("riders"):
		b["riders"] = []
	return b["riders"]


# kind: "group" (arg — группа), "char" (arg — показатель), "party" (arg — номер партии)
func bill_rider_check(b: Dictionary, kind: String, arg: String) -> String:
	if int(b["sponsor"]) != 0:
		return "это чужой законопроект"
	if bill_rider_list(b).size() >= RIDER_MAX:
		return "не больше %d оговорок в одном законе" % RIDER_MAX
	for r in bill_rider_list(b):
		if String(r["k"]) == kind and String(r["a"]) == arg:
			return "такая оговорка уже есть"
	var cost: float = 4.0 if kind == "party" else 3.0
	if cap_spendable() < cost:
		return "нужно %.0f политкапитала" % cost
	if kind == "party":
		var p := int(arg)
		if p <= 0 or p >= PARTY_NAMES.size() or seats[p] <= 0:
			return "партии нет в парламенте"
	return ""


func bill_rider_add(bid: int, kind: String, arg: String) -> bool:
	var bi := bill_index(bid)
	if bi < 0:
		return false
	var b: Dictionary = bills[bi]
	var why := bill_rider_check(b, kind, arg)
	if why != "":
		log_line("[color=%s]Поправка невозможна: %s.[/color]" % [COL_WARN, why])
		return false
	var tid: String = String(b["tid"])
	var y0: int = int(bill_preview(b)["yes"])
	var won: PackedStringArray = []
	var lost: PackedStringArray = []
	var title := ""
	match kind:
		"group":
			capital -= 3.0
			title = "в пользу группы «%s»" % arg
			# партии, чей электорат — эта группа, охотнее голосуют «за»
			for p in range(1, PARTY_NAMES.size()):
				if seats[p] <= 0 or (p in NO_GOV_SLOTS) or p in b["forced"]:
					continue
				var lean_sh: float = float(LEAN[arg][p]) / maxf(0.001, _lean_sum(arg))
				if lean_sh > 1.4 / float(PARTY_NAMES.size()) and variant_stance(p, tid, int(b["idx"])) >= -3.0:
					(b["forced"] as Array).append(p)
					won.append(PARTY_NAMES[p])
		"char":
			capital -= 3.0
			var ch: Array = RIDER_CHARS.get(arg, ["Оговорка", "", ""])
			title = String(ch[0]).to_lower()
			var pk: String = String(ch[1])
			for p in range(1, PARTY_NAMES.size()):
				if seats[p] <= 0 or (p in NO_GOV_SLOTS) or p in b["forced"]:
					continue
				var st: float = ideo_stance(p, pk) if policy_by_key.has(pk) else (0.4 if arg == "corruption" else 0.0)
				if st > 0.25 and variant_stance(p, tid, int(b["idx"])) >= -3.5:
					(b["forced"] as Array).append(p)
					won.append(PARTY_NAMES[p])
		"party":
			capital -= 4.0
			var q := int(arg)
			title = "с учётом требований «%s»" % PARTY_NAMES[q]
			if not (q in b["forced"]) and variant_stance(q, tid, int(b["idx"])) >= -5.0:
				(b["forced"] as Array).append(q)
				won.append(PARTY_NAMES[q])
			rel_add(0, q, 3.0)
			# противники этой партии отходят
			for p in (b["forced"] as Array).duplicate():
				if int(p) != q and int(p) != 0 and rel(int(p), q) < 32.0:
					(b["forced"] as Array).erase(p)
					lost.append(PARTY_NAMES[int(p)])
	bill_rider_list(b).append({"k": kind, "a": arg, "t": title})
	var y1: int = int(bill_preview(b)["yes"])
	var t := "законопроект «%s»: оговорка %s; голосов «за» %d → %d (нужно %d)." % [law_index[tid]["name"], title, y0, y1, law_need(tid, bill_preview(b))]
	if won.size() > 0:
		t += " Поддержат: %s." % ", ".join(won)
	if lost.size() > 0:
		t += " Отвернулись: %s." % ", ".join(lost)
	log_tag("ПОПРАВКА", COL_TEAL, t)
	refresh()
	return true


func _lean_sum(g: String) -> float:
	var t := 0.0
	for v in (LEAN[g] as Array):
		t += float(v)
	return t


# после принятия закона оговорки действуют: группы, показатели, партии
func bill_riders_apply(b: Dictionary) -> void:
	for r in (b.get("riders", []) as Array):
		match String(r["k"]):
			"group":
				add_support(String(r["a"]), 2.0)
				conc_all_groups_cost(0.04)
			"char":
				var key: String = String(r["a"])
				if lvl.has(key):
					lvl[key] = clampf(float(lvl[key]) + (-2.0 if key == "corruption" else 2.0), 0.0, 100.0)
				var g: String = String((RIDER_CHARS.get(key, ["", "", ""]) as Array)[2])
				if g != "":
					add_support(g, 1.0)
				conc_all_groups_cost(0.03)
			"party":
				var q := int(r["a"])
				if q > 0 and q < PARTY_NAMES.size():
					rel_add(0, q, 4.0)
					if in_coalition[q]:
						conc[q] = float(conc.get(q, 0.0)) + 6.0


# оговорки стоят денег: небольшой разовый расход (доля ВВП)
func conc_all_groups_cost(pp: float) -> void:
	debt += gdp * pp / 100.0


func bills_step() -> void:
	if game_over:
		return
	rg_drip_step()
	bill_queue_step()
	for b in bills.duplicate():
		if turn > int(b["start"]) and randf() < 0.6 and (b["req"] as Array).size() < 4:
			bill_request_new(b)
		# автопилот решений: берёт дешёвые уступки, остальные отклоняет
		if int(b["sponsor"]) == 0 and bool(ap["events"]):
			var reqs: Array = b["req"]
			for i in reqs.size():
				if int(reqs[i]["state"]) == 0:
					bill_request(int(b["id"]), i, float(reqs[i]["cost"]) <= 4.0 and capital >= float(reqs[i]["cost"]) + 15.0)
		bill_warn_short(b)
		if turn >= int(b["due"]) and not live_days:      # 0.62: в живой игре голосуют по средам (bills_due_step)
			# 0.57.1: в живой игре в день голосования время останавливается и открывается окно выбора стратегии
			if bill_plan_wanted(b):
				if not vt_plan_busy():
					vote_plan_open(int(b["id"]))
				continue
			bill_run_vote(b)


# за месяц до голосования предупреждаем, если по вашему законопроекту голосов не хватает
func bill_warn_short(b: Dictionary) -> void:
	if int(b["sponsor"]) != 0 or int(b["due"]) - turn != 1 or bool(b.get("warned", false)):
		return
	var pv0: Dictionary = bill_preview(b)
	var need: int = law_need(String(b["tid"]), pv0)
	var yes: int = int(pv0["yes"])
	if yes >= need:
		return
	b["warned"] = true
	var txt := "Через месяц голосование по закону «%s», а голосов не хватает: за %d из нужных %d. Договоритесь с партиями, внесите поправку или отложите голосование." % [law_index[String(b["tid"])]["name"], yes, need]
	log_tag("ЗАКОНОПРОЕКТ", COL_WARN, txt)
	nt_toast(txt, "bill", 3)


# законопроекты, которые ждут вашего решения: просьба о поправке, нехватка голосов, чужой законопроект без вашего решения.
# sev: 3 — просьба, 2 — не хватает голосов, 1 — решите, как голосует фракция
func bills_attention() -> Array:
	var out: Array = []
	for b in bills:
		var left := maxi(0, int(b["due"]) - turn)
		var tid: String = String(b["tid"])
		var why := ""
		var sev := 0
		if int(b["sponsor"]) == 0:
			for r in b["req"]:
				if int(r["state"]) == 0:
					why = "просьба о поправке"
					sev = 3
					break
			if why == "":
				var pv1: Dictionary = bill_preview(b)
				var yes: int = int(pv1["yes"])
				if yes < law_need(tid, pv1):
					why = "не хватает голосов: %d из %d" % [yes, law_need(tid, pv1)]
					sev = 2
		elif seats[0] > 0 and String(b.get("pv", "line")) == "line" and left <= 2:
			why = "решите, как голосует ваша фракция"
			sev = 1
		if sev > 0:
			out.append({"id": int(b["id"]), "why": why, "sev": sev, "left": left})
	out.sort_custom(func(x, y): return int(x["sev"]) > int(y["sev"]) or (int(x["sev"]) == int(y["sev"]) and int(x["left"]) < int(y["left"])))
	return out


# голосование по законопроектам, срок которых пришёл (после закрытия окна — подхватываем остальные)
func bills_due_step() -> void:
	if game_over or vt_plan_busy():
		return
	for b in bills.duplicate():
		if turn < int(b["due"]) or bill_index(int(b["id"])) < 0:
			continue
		if bill_plan_wanted(b):
			vote_plan_open(int(b["id"]))
			return
		bill_run_vote(b)


func bill_run_vote(b: Dictionary) -> void:
	if int(b["sponsor"]) == 0:
		bill_vote(b)
	elif bool(b.get("pa", false)):
		pa_bill_vote(b)
	else:
		ai_bill_vote(b)


# нужно ли сначала спросить игрока: только в живой игре; по чужому закону — если во фракции есть места
func bill_plan_wanted(b: Dictionary) -> bool:
	if bool(b.get("go", false)) or not vote_plan_live():
		return false
	return int(b["sponsor"]) == 0 or seats[0] > 0


# цена голосов отдельной партии (политкапитал): чем дальше закон от её взглядов и чем она больше, тем дороже
func bill_deal_cost(b: Dictionary, p: int) -> float:
	var s := variant_stance(p, String(b["tid"]), int(b["idx"]))
	return roundf((2.0 + maxf(0.0, -s) * 0.6) * (0.6 + 2.5 * pa_power(p)))


# давить можно на партнёров по коалиции; платят они недовольством, а не вы капиталом
func bill_press_ok(p: int) -> bool:
	return p > 0 and not opp_mode and in_coalition[p]


func bill_press_cost(b: Dictionary, p: int) -> float:
	var s := variant_stance(p, String(b["tid"]), int(b["idx"]))
	return 6.0 + maxf(0.0, -s) * 1.5


# партии, которых ещё можно уговорить: против закона и не в списке «за»
func bill_swing_parties(b: Dictionary) -> Array:
	var out: Array = []
	var forced := bill_forced(b)
	for p in range(1, PARTY_NAMES.size()):
		if seats[p] <= 0 or p == int(b["sponsor"]) or (p in NO_GOV_SLOTS) or p in forced:
			continue
		if variant_stance(p, String(b["tid"]), int(b["idx"])) < 0.0:
			out.append(p)
	return out


# прогноз голосования при выбранных сделках/давлении/линии фракции (ничего не списывает)
func bill_plan_preview(b: Dictionary, extra: Array, pv: String = "") -> Dictionary:
	var b2: Dictionary = b.duplicate()
	b2["forced"] = bill_forced(b) + extra
	b2["req"] = []
	var old_pl := vote_pl
	vote_pl = pv
	var v := bill_preview(b2)
	vote_pl = old_pl
	return v


# применить выбранную стратегию к своему законопроекту: deals — купить голоса за капитал, press — надавить на партнёров
func bill_plan_apply(bid: int, deals: Array, press: Array) -> bool:
	var bi := bill_index(bid)
	if bi < 0:
		return false
	var b: Dictionary = bills[bi]
	var total := 0.0
	for p in deals:
		total += bill_deal_cost(b, int(p))
	if total > 0.0 and cap_spendable() < total:
		return false
	capital -= total
	vote_notes.clear()
	for p in deals:
		(b["forced"] as Array).append(int(p))
		rel_add(0, int(p), 2.0)
		vote_notes[int(p)] = "голоса куплены: политкапитал −%.0f" % bill_deal_cost(b, int(p))
	for p in press:
		var q := int(p)
		if not bill_press_ok(q) or q in (b["forced"] as Array):
			continue
		(b["forced"] as Array).append(q)
		satis[q] = clampf(float(satis.get(q, 50.0)) - bill_press_cost(b, q), 0.0, 100.0)
		rel_add(0, q, -5.0)
		vote_notes[q] = "на партию надавили: довольство −%.0f" % bill_press_cost(b, q)
	return true


# обмен голосами по чужому законопроекту: ваша фракция голосует «за», вам задолжали
func pa_trade_value(b: Dictionary) -> float:
	return clampf(roundf(1.0 + 10.0 * pa_power(int(b["sponsor"]))), 1.0, 6.0)


func pa_trade(bid: int) -> bool:
	var bi := bill_index(bid)
	if bi < 0 or pl_deny("parl"):
		return false
	var b: Dictionary = bills[bi]
	if bool(b.get("traded", false)) or int(b["sponsor"]) == 0:
		return false
	b["pv"] = "yes"
	b["traded"] = true
	capital += pa_trade_value(b)
	rel_add(0, int(b["sponsor"]), 6.0)
	vote_notes[0] = "обмен голосами: политкапитал +%.0f" % pa_trade_value(b)
	return true


# поправка к чужому законопроекту: смягчить или усилить, отношения со внесшей партией портятся
func pa_amend(bid: int, kind: String) -> bool:
	var bi := bill_index(bid)
	if bi < 0 or pl_deny("parl"):
		return false
	var b: Dictionary = bills[bi]
	if int(b["sponsor"]) == 0 or bill_pow_block(b, kind) != "" or cap_spendable() < 3.0:
		return false
	capital -= 3.0
	b["pow"] = snappedf(float(b["pow"]) + (-0.2 if kind == "soft" else 0.2), 0.1)
	b["amended"] = true
	rel_add(0, int(b["sponsor"]), -2.0)
	return true


func bill_vote(b: Dictionary) -> void:
	var tid: String = String(b["tid"])
	var idx: int = int(b["idx"])
	var forced := bill_forced(b)
	var topic: Dictionary = law_index[tid]
	var was_cd: int = int(law_cd.get(tid, 0))
	if is_hybrid(tid):
		law_pow_sel[tid] = float(b["pow"])
	var full := law_cost(tid, idx)
	cost_mult = clampf(1.0 - float(b["paid"]) / maxf(0.1, full), 0.0, 1.0)
	var saved_cd := was_cd
	law_cd[tid] = 0
	adopt_variant(tid, idx, forced)
	cost_mult = 1.0
	var ok: bool = int(law_cd.get(tid, 0)) > 0
	if not ok:
		law_cd[tid] = saved_cd
	else:
		bill_riders_apply(b)
	for r in b["req"]:
		if int(r["state"]) == 0:
			rel_add(0, int(r["p"]), -2.0)
	bills.erase(b)
	if not ok:
		log_tag("ЗАКОНОПРОЕКТ", COL_BAD, "законопроект «%s» провален в парламенте. Взнос потерян." % topic["name"])
		sfx("bad")
	refresh()


func ai_bill_vote(b: Dictionary) -> void:
	var tid: String = String(b["tid"])
	var idx: int = int(b["idx"])
	var pm: int = int(b["sponsor"])
	bills.erase(b)
	if opp_gov.is_empty() or int(opp_gov["pm"]) != pm:
		return
	var old := cap_swap(pm)
	vote_sponsor = pm
	vote_pl = String(b.get("pv", "line"))
	if bool(b.get("amended", false)) and is_hybrid(tid):
		law_pow_sel[tid] = float(b["pow"])
	var was: int = int(law_cd.get(tid, 0))
	law_cd[tid] = 0
	var before := cur_idx(tid)
	adopt_variant(tid, idx, bill_forced(b))
	vote_sponsor = 0
	vote_pl = ""
	var ok: bool = cur_idx(tid) == idx and before != idx
	if not ok:
		law_cd[tid] = was
	cap_unswap(pm, old)
	ai_note("bill_passed" if ok else "bill_failed")
	if not ok:
		log_tag("ЗАКОНОПРОЕКТ", COL_NEUTRAL, "законопроект правительства «%s» не набрал голосов." % law_index[tid]["name"])
	pa_vote_after(b, pm)


# ============================================================
#  0.56 (п.15): ПАРТНЁРЫ И ОППОЗИЦИЯ ДЕЙСТВУЮТ САМИ
#  Раз в квартал каждая партия делает 1–3 действия ради своих целей: министры-партнёры предлагают сдвинуть
#  статьи бюджета своих министерств (нужно согласие коалиции, игрок может наложить вето за капитал), партии вносят
#  законопроекты, оппозиция выводит людей на митинги. По чужим законопроектам игрок сам решает, как голосует его фракция.
# ============================================================
const MIN_BUD := {1: ["army"], 2: ["police"], 3: ["health"], 4: ["edu"], 5: ["subs"], 6: ["subs"], 7: ["eco"], 8: ["infra"], 9: ["pensions", "benefits"], 10: ["police"]}
const PA_VOTE_NAMES := {"line": "по линии партии", "yes": "за", "no": "против", "abst": "воздержаться", "free": "свободное голосование"}


func pa_power(p: int) -> float:
	return float(seats[p]) / float(maxi(1, SEATS))


# цена вето на действие партии: чем сильнее партия, тем дороже
func pa_veto_cost(p: int) -> float:
	return roundf(3.0 + 40.0 * pa_power(p))


func pa_month() -> void:
	pl_disc = maxf(0.0, pl_disc - 0.02)
	var keep: Array = []
	for pr in pa_props:
		var p: int = int(pr["p"])
		var m: int = int(pr["m"])
		if opp_mode or not in_coalition[p] or int(ministries[m]) != p:
			continue
		if turn < int(pr["due"]):
			keep.append(pr)
			continue
		var key: String = String(pr["key"])
		var d: Dictionary = policy_by_key[key]
		var old: float = float(pol[key])
		var nv: float = clampf(old + float(pr["d"]), float(d["min"]), float(d["max"]))
		nv = lock_allowed_share(key, nv)
		if absf(nv - old) < 0.01:
			continue
		set_policy(key, nv)
		prev_pol[key] = float(prev_pol[key]) + (float(pol[key]) - old)
		pa_drift[key] = float(pa_drift.get(key, 0.0)) + (float(pol[key]) - old)
		conc[p] = float(conc.get(p, 0.0)) + 3.0
		log_tag("МИНИСТР", COL_TEAL, "вступило в силу предложение министра «%s» (%s): «%s» %.1f → %.1f%% ВВП." % [MINISTRIES[m]["name"], party_abbr(p), policy_title(key), old, float(pol[key])])
	pa_props = keep
	if month == 1:
		pa_drift.clear()
	if month % 3 == 0:
		pa_quarter()


func pa_quarter() -> void:
	if game_over or PARTY_NAMES.size() < 3 or pcap.size() != PARTY_NAMES.size():
		return
	for p in range(1, PARTY_NAMES.size()):
		if p == 6 or seats[p] <= 0:
			continue
		var opts := pa_options(p)
		var n: int = 1 + int(pa_power(p) >= 0.12) + int(float(pcap[p]) >= 45.0)
		for i in n:
			if opts.is_empty():
				break
			var tot := 0.0
			for o in opts:
				tot += float(o[0])
			var r := randf() * tot
			var pick: Array = opts[0]
			for o in opts:
				r -= float(o[0])
				if r <= 0.0:
					pick = o
					break
			# одно предложение по бюджету на партию за квартал
			for o in opts.duplicate():
				if String(o[1]) == String(pick[1]) and String(pick[1]) == "bud":
					opts.erase(o)
			opts.erase(pick)
			if String(pick[1]) == "bill" and randf() > BILL_AI_ACTIVITY:
				continue
			pa_do(p, String(pick[1]), pick[2])


func pa_options(p: int) -> Array:
	var out: Array = []
	if opp_mode and not opp_gov.is_empty() and p in (opp_gov["members"] as Array):
		return out   # правительство без игрока действует по своим правилам (ai_gov_rule)
	var aggr: float = float((ARCH[party_arch(p)] as Dictionary)["aggr"])
	if in_coalition[p] and not opp_mode:
		for m in MINISTRIES.size():
			if int(ministries[m]) != p or not MIN_BUD.has(m):
				continue
			for key in (MIN_BUD[m] as Array):
				var busy := false
				for pr in pa_props:
					if String(pr["key"]) == key:
						busy = true
				if busy:
					continue
				var dd: float = ideo_target(p, key) - float(pol[key])
				# за год министр сдвигает статью не больше чем на 0,5 п.п.; при большом дефиците не просит денег
				if absf(dd) < 0.2 or absf(float(pa_drift.get(key, 0.0))) >= 0.5:
					continue
				var step: float = 0.2 if absf(dd) >= 0.6 else 0.1
				step *= signf(dd)
				var wgt: float = 0.5 + 0.5 * minf(absf(dd), 1.5)
				if step > 0.0 and last_deficit_pct > 3.5:
					continue   # 0.56: при дефиците выше 3,5% ВВП партнёры денег не просят
				if step > 0.0 and last_deficit_pct > 2.5:
					wgt *= 0.3
				out.append([wgt, "bud", {"m": m, "key": key, "d": step}])
		var lb := pa_pick_bill(p)
		if not lb.is_empty():
			out.append([1.2, "bill", lb])
		out.append([0.6, "say", {}])
	else:
		var lb2 := pa_pick_bill(p) if pa_power(p) >= 0.05 else {}
		if not lb2.is_empty():
			out.append([0.5, "bill", lb2])
		out.append([(0.3 + aggr) * (0.5 + 4.0 * pa_power(p)), "rally", {}])
	return out


# законопроект партии: сначала её закон-условие, иначе вариант, который ей ближе всего
func pa_pick_bill(p: int) -> Dictionary:
	var ld := law_demand_of(p)
	if not ld.is_empty() and not ld.has("val") and not law_demand_met(p):
		var tid0: String = String(ld["tid"])
		if law_index.has(tid0) and int(law_cd.get(tid0, 0)) <= 0 and bill_of(tid0) < 0 and turn - int(pa_fail.get(tid0, -99)) >= 12 and law_locked(tid0) == "" and radical_req(tid0, int(ld["idx"])) == "":
			return {"tid": tid0, "idx": int(ld["idx"])}
	var best := {}
	var bs := 1.0
	var topics: Array = LAW_TOPICS.duplicate()
	topics.shuffle()
	for t in topics.slice(0, 30):
		var tid: String = String(t["id"])
		if not law_index.has(tid) or law_index[tid].has("param") or int(law_cd.get(tid, 0)) > 0 or law_locked(tid) != "" or bill_of(tid) >= 0 or turn - int(pa_fail.get(tid, -99)) < 12:
			continue
		var cur := cur_idx(tid)
		var vs: Array = law_index[tid]["v"]
		for idx in [cur - 1, cur + 1]:
			if idx < 0 or idx >= vs.size():
				continue
			if radical_req(tid, idx) != "" or String((vs[idx] as Dictionary).get("rid", "")) != "":
				continue
			# 0.56: при большом дефиците партнёры не вносят законы, которые добавляют бюджетные программы
			if last_deficit_pct > 3.0 and float(((vs[idx] as Dictionary).get("a", {}) as Dictionary).get("extra_spend", 0.0)) > float((((vs[cur] as Dictionary).get("a", {})) as Dictionary).get("extra_spend", 0.0)):
				continue
			var s := variant_stance(p, tid, idx)
			if s > bs:
				bs = s
				best = {"tid": tid, "idx": idx}
	return best


# ---------- 0.59: лимит чужих законопроектов на повестке ----------
const BILL_AI_MAX := 2
const BILL_AI_ACTIVITY := 0.75


func pa_bill_is_demand(p: int, tid: String, idx: int) -> bool:
	var ld := law_demand_of(p)
	return not ld.is_empty() and not ld.has("val") and String(ld.get("tid", "")) == tid and int(ld.get("idx", -1)) == idx


func bill_ai_count() -> int:
	var n := 0
	for b in bills:
		if int(b["sponsor"]) != 0:
			n += 1
	return n


func pa_bill_slot_free(tid: String) -> bool:
	if bill_ai_count() >= BILL_AI_MAX:
		return false
	var cat: int = int(law_index[tid]["cat"])
	for b in bills:
		if int(b["sponsor"]) != 0 and law_index.has(String(b["tid"])) and int(law_index[String(b["tid"])]["cat"]) == cat:
			return false
	return true


func pa_bill_queue(p: int, tid: String, idx: int) -> void:
	for q in bill_queue:
		if String(q["tid"]) == tid:
			return
	if bill_queue.size() >= 4:
		return
	bill_queue.append({"p": p, "tid": tid, "idx": idx, "since": turn})


# раз в месяц: освободилось место на повестке — берём первый подходящий законопроект из очереди
func bill_queue_step() -> void:
	for q in bill_queue.duplicate():
		var tid: String = String(q["tid"])
		if turn - int(q["since"]) > 12 or bill_of(tid) >= 0 or not law_index.has(tid) or cur_idx(tid) == int(q["idx"]) or seats[int(q["p"])] <= 0:
			bill_queue.erase(q)
			continue
		if pa_bill_slot_free(tid):
			bill_queue.erase(q)
			pa_add_bill(int(q["p"]), tid, int(q["idx"]))
			return


func pa_add_bill(p: int, tid: String, idx: int) -> void:
	bill_seq += 1
	bills.append({"id": bill_seq, "tid": tid, "idx": idx, "sponsor": p, "start": turn, "due": turn + 3, "forced": [], "pow": 1.0, "req": [], "paid": 0.0, "did": {}, "pa": true, "pv": "line"})
	pcap[p] = maxf(0.0, float(pcap[p]) - 3.0)
	var who := "партнёр по коалиции" if in_coalition[p] and not opp_mode else "оппозиция"
	log_tag("ЗАКОНОПРОЕКТ", COL_TEAL, "«%s» (%s) внесла законопроект «%s»: %s. Голосование через 3 мес. Как голосует ваша фракция, решите в окне «Законопроекты» (сейчас — %s)." % [
		PARTY_NAMES[p], who, law_index[tid]["name"], variant_of(tid, idx)["n"], pa_line_text(bills[bills.size() - 1])])


func pa_do(p: int, kind: String, o: Dictionary) -> void:
	match kind:
		"bud":
			var key: String = String(o["key"])
			var d: float = float(o["d"])
			# согласие коалиции: остальные партнёры по своему влиянию
			var against := 0.0
			var tot := 0.0
			var no_names: PackedStringArray = []
			for q in coal_members():
				if q == p or q == 0:
					continue
				var w := coal_share(q)
				tot += w
				var dq: float = ideo_target(q, key) - float(pol[key])
				if absf(dq) >= 0.15 and signf(dq) != signf(d):
					against += w
					no_names.append(party_abbr(q))
			if tot > 0.0 and against / tot > 0.5:
				log_tag("МИНИСТР", COL_DIM, "министр «%s» (%s) хотел изменить «%s» на %s п.п. ВВП, но совет коалиции против (%s)." % [MINISTRIES[int(o["m"])]["name"], party_abbr(p), policy_title(key), sg(d, 1), ", ".join(no_names)])
				return
			pa_seq += 1
			pa_props.append({"id": pa_seq, "p": p, "m": int(o["m"]), "key": key, "d": d, "due": turn + 1})
			pcap[p] = maxf(0.0, float(pcap[p]) - 2.0)
			log_tag("МИНИСТР", COL_TEAL, "министр «%s» (%s) предлагает изменить «%s» на %s п.п. ВВП. Если вы не наложите вето (политкапитал −%.0f, окно «Правительство» → «Обязательства и предложения»), изменение вступит в силу в конце следующего месяца." % [
				MINISTRIES[int(o["m"])]["name"], party_abbr(p), policy_title(key), sg(d, 1), pa_veto_cost(p)])
		"bill":
			var tid: String = String(o["tid"])
			var idx: int = int(o["idx"])
			if bill_of(tid) >= 0:
				return
			# 0.59: на повестке не больше двух чужих законопроектов и не больше одного на сферу; остальные ждут в очереди.
			# Исключение: закон-условие самой партии.
			if not pa_bill_is_demand(p, tid, idx) and not pa_bill_slot_free(tid):
				pa_bill_queue(p, tid, idx)
				return
			pa_add_bill(p, tid, idx)
		"say":
			var st: float = float(satis.get(p, 55.0))
			if st >= 62.0:
				add_all_support(0.1)
				log_tag("ПАРТНЁР", COL_GOOD, "«%s» публично хвалит работу правительства." % PARTY_NAMES[p])
			elif st < 47.0:
				add_all_support(-0.12)
				log_tag("ПАРТНЁР", COL_WARN, "«%s» публично критикует правительство: %s." % [PARTY_NAMES[p], sat_reason(p)])
		"rally":
			var w: float = 0.5 + 4.0 * pa_power(p)
			pcap[p] = maxf(0.0, float(pcap[p]) - 2.0)
			if opp_mode and not opp_gov.is_empty():
				opp_gov["stab"] = clampf(float(opp_gov["stab"]) - 0.6 * w, 0.0, 100.0)
				if pa_power(p) >= 0.08:
					log_tag("ОППОЗИЦИЯ", COL_DIM, "«%s» вывела сторонников на митинги против правительства." % PARTY_NAMES[p])
			else:
				add_all_support(-0.06 * w)
				if pa_power(p) >= 0.06:
					log_tag("ОППОЗИЦИЯ", COL_WARN, "«%s» провела митинги против вашего правительства: рейтинг власти −%.1f." % [PARTY_NAMES[p], 0.06 * w])


# линия партии игрока по чужому законопроекту: true — «за» (0.64: единый расчёт в laws.gd, line_kind_for)
func pa_line(b: Dictionary) -> bool:
	return pa_line_kind(b) == "yes"


func pa_line_kind(b: Dictionary) -> String:
	return line_kind_for(String(b["tid"]), int(b["idx"]), int(b["sponsor"]))


func pa_line_text(b: Dictionary) -> String:
	return {"yes": "за", "no": "против", "abst": "воздержаться"}[pa_line_kind(b)]


func pa_set_vote(bid: int, v: String) -> void:
	var bi := bill_index(bid)
	if bi < 0 or not PA_VOTE_NAMES.has(v):
		return
	if pl_deny("parl"):
		return
	bills[bi]["pv"] = v
	refresh()


func pa_bill_vote(b: Dictionary) -> void:
	var tid: String = String(b["tid"])
	var idx: int = int(b["idx"])
	var p: int = int(b["sponsor"])
	bills.erase(b)
	if p <= 0 or p >= PARTY_NAMES.size() or seats[p] <= 0:
		return
	var old := cap_swap(p)
	capital = maxf(capital, 40.0)
	vote_sponsor = p
	vote_pl = String(b.get("pv", "line"))
	if bool(b.get("amended", false)) and is_hybrid(tid):
		law_pow_sel[tid] = float(b["pow"])
	cost_mult = 0.25
	var was: int = int(law_cd.get(tid, 0))
	law_cd[tid] = 0
	var before := cur_idx(tid)
	adopt_variant(tid, idx, [])
	vote_sponsor = 0
	vote_pl = ""
	cost_mult = 1.0
	var ok: bool = cur_idx(tid) == idx and before != idx
	if not ok:
		law_cd[tid] = was
	cap_unswap(p, old)
	if not ok:
		pa_fail[tid] = turn
		log_tag("ЗАКОНОПРОЕКТ", COL_NEUTRAL, "законопроект «%s» партии «%s» не принят." % [law_index[tid]["name"], party_abbr(p)])
	pa_vote_after(b, p)


# последствия выбора фракции: против линии — слабеет дисциплина и недовольны избиратели; против партнёра — он обижен
func pa_vote_after(b: Dictionary, p: int) -> void:
	if seats[0] <= 0:
		return
	var pv: String = String(b.get("pv", "line"))
	var lk := pa_line_kind(b)
	var eff: String = pv if pv != "line" else lk
	var nm: String = String(law_index[String(b["tid"])]["name"])
	if (eff == "yes" and lk == "no") or (eff == "no" and lk == "yes"):
		pl_disc = minf(1.0, pl_disc + 0.15)
		add_all_support(-0.2)
		log_tag("ФРАКЦИЯ", COL_WARN, "по закону «%s» ваша фракция проголосовала против линии партии: дисциплина слабеет, часть избирателей недовольна." % nm)
	elif eff == "free":
		pl_disc = minf(1.0, pl_disc + 0.05)
	if opp_mode:
		if p < prel.size():
			rel_add(0, p, 3.0 if eff == "yes" else (-2.0 if eff == "no" else 0.0))
		return
	if in_coalition[p]:
		if eff == "no":
			satis[p] = clampf(float(satis.get(p, 50.0)) - 6.0, 0.0, 100.0)
			rel_add(0, p, -4.0)
			log_tag("КОАЛИЦИЯ", COL_WARN, "«%s» обижена: ваша фракция голосовала против её законопроекта «%s»." % [PARTY_NAMES[p], nm])
		elif eff == "abst":
			satis[p] = clampf(float(satis.get(p, 50.0)) - 3.0, 0.0, 100.0)
		elif eff == "yes":
			conc[p] = float(conc.get(p, 0.0)) + 2.0
	elif eff == "yes":
		var angry: PackedStringArray = []
		for q in coal_members():
			if q != 0 and variant_stance(q, String(b["tid"]), int(b["idx"])) < -1.0:
				satis[q] = clampf(float(satis.get(q, 50.0)) - 3.0, 0.0, 100.0)
				angry.append(party_abbr(q))
		if angry.size() > 0:
			log_tag("КОАЛИЦИЯ", COL_WARN, "партнёры (%s) недовольны: вы поддержали законопроект оппозиции «%s»." % [", ".join(angry), nm])


# вето: снять чужой законопроект с повестки (правительство управляет повесткой)
func pa_veto_bill(bid: int) -> void:
	var bi := bill_index(bid)
	if bi < 0 or pl_deny():
		return
	var b: Dictionary = bills[bi]
	var p: int = int(b["sponsor"])
	if p == 0 or not bool(b.get("pa", false)):
		return
	var cost := pa_veto_cost(p)
	if cap_spendable() < cost:
		log_line("[color=%s]Для вето нужно %.0f политкапитала.[/color]" % [COL_WARN, cost])
		return
	capital -= cost
	bills.remove_at(bi)
	if in_coalition[p]:
		satis[p] = clampf(float(satis.get(p, 50.0)) - 5.0, 0.0, 100.0)
	rel_add(0, p, -3.0)
	log_tag("ВЕТО", COL_PURPLE, "вы сняли с повестки законопроект «%s» партии «%s» (политкапитал −%.0f)." % [law_index[String(b["tid"])]["name"], PARTY_NAMES[p], cost])
	refresh()


func pa_veto_prop(id: int) -> void:
	if pl_deny():
		return
	for i in pa_props.size():
		var pr: Dictionary = pa_props[i]
		if int(pr["id"]) != id:
			continue
		var p: int = int(pr["p"])
		var cost := pa_veto_cost(p)
		if cap_spendable() < cost:
			log_line("[color=%s]Для вето нужно %.0f политкапитала.[/color]" % [COL_WARN, cost])
			return
		capital -= cost
		conc[p] = float(conc.get(p, 0.0)) - 4.0
		pa_props.remove_at(i)
		log_tag("ВЕТО", COL_PURPLE, "вы запретили министру «%s» (%s) менять «%s» (политкапитал −%.0f)." % [MINISTRIES[int(pr["m"])]["name"], party_abbr(p), policy_title(String(pr["key"])), cost])
		refresh()
		return


func pa_prop_text(pr: Dictionary) -> String:
	return "Министр «%s» (%s): «%s» %s п.п. ВВП — вступит в силу в конце %s" % [MINISTRIES[int(pr["m"])]["name"], party_abbr(int(pr["p"])), policy_title(String(pr["key"])), sg(float(pr["d"]), 1), "этого месяца" if int(pr["due"]) <= turn else "следующего месяца"]
