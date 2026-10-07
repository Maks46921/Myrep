# Партийный ИИ: идеологии, политический капитал партий, правление без вас, законопроекты и поправки.
extends "res://scripts/logic/opposition.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func autopilot_step() -> void:
	pass


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
	if p == 9:
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
func ai_policy_step(members: Array, pm: int, strength: float) -> int:
	var moved := 0
	var room: bool = last_deficit_pct < float(ap["target"]) + 0.4
	for k in ideo_keys():
		if k == "emit" or lock_active(k):
			continue
		if String(policy_by_key[k]["kind"]) == "tax" and not room:
			continue
		var d: Dictionary = policy_by_key[k]
		var rng: float = float(d["max"]) - float(d["min"])
		var cur: float = float(pol[k])
		var step: float = clampf(gov_target(members, pm, k) - cur, -0.04 * rng * strength, 0.04 * rng * strength)
		if absf(step) < 0.01:
			continue
		set_policy(k, cur + step)
		moved += 1
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
	if pm == 0:
		return res
	var share: float = float(seats[0]) / float(maxi(1, gov_seats()))
	res["junior"] = true
	res["pm"] = pm
	res["power"] = clampf(0.35 + 0.9 * share, 0.4, 0.85)
	return res


func junior_power() -> float:
	return float(junior_info()["power"])


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
	if p == 9 or q == 9:
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
	return old


func cap_unswap(p: int, old: float) -> void:
	if pcap.size() > p:
		pcap[p] = clampf(capital, 0.0, 100.0)
	capital = old


func autopilot_run() -> void:
	if opp_mode and not opp_gov.is_empty():
		var pm: int = int(opp_gov["pm"])
		var old := cap_swap(pm)
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
		if p == 9:
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
		if seats[p] <= 0 and p != 9:
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
		if int(vv["yes"]) >= law_need(String(c[1])) and not bool(upper_check(String(c[1]), int(c[2]), [])["block"]):
			best_t = String(c[1])
			best_i = int(c[2])
			break
	vote_sponsor = old_sp
	if best_i < 0:
		return
	if pm == 0:
		# v35: режим наблюдателя — законопроект вашей партии вносит ИИ обычным порядком
		propose_variant(best_t, best_i)
		return
	bill_seq += 1
	bills.append({"id": bill_seq, "tid": best_t, "idx": best_i, "sponsor": pm, "start": turn, "due": turn + 2 + randi() % 2, "forced": [], "pow": 1.0, "req": [], "paid": 0.0})
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
	if radical_bypass(tid, idx) or decree_power():
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
	if capital < cost:
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
		if capital < float(r["cost"]):
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
			log_tag("ПОПРАВКА", COL_TEAL, "законопроект «%s» %s: сила действия %.1f×; голосов «за» %d → %d (нужно %d)." % [law_index[tid]["name"], "смягчён" if kind == "soft" else "ужесточён", float(b["pow"]), y0, y1, law_need(tid)])
		"sweet":
			if bool(did.get("sweet", false)) or capital < 4.0:
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
			if bool(did.get("fast", false)) or capital < 4.0 or int(b["due"]) <= turn + 1:
				return false
			capital -= 4.0
			b["due"] = int(b["due"]) - 1
			did["fast"] = true
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


func bills_step() -> void:
	if game_over:
		return
	for b in bills.duplicate():
		if turn > int(b["start"]) and randf() < 0.6 and (b["req"] as Array).size() < 4:
			bill_request_new(b)
		# автопилот решений: берёт дешёвые уступки, остальные отклоняет
		if int(b["sponsor"]) == 0 and bool(ap["events"]):
			var reqs: Array = b["req"]
			for i in reqs.size():
				if int(reqs[i]["state"]) == 0:
					bill_request(int(b["id"]), i, float(reqs[i]["cost"]) <= 4.0 and capital >= float(reqs[i]["cost"]) + 15.0)
		if turn >= int(b["due"]):
			if int(b["sponsor"]) == 0:
				bill_vote(b)
			else:
				ai_bill_vote(b)


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
	for r in b["req"]:
		if int(r["state"]) == 0:
			rel_add(0, int(r["p"]), -2.0)
	bills.erase(b)
	if not ok:
		log_tag("ЗАКОНОПРОЕКТ", COL_BAD, "законопроект «%s» провален в парламенте. Взнос потерян." % topic["name"])
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
	var was: int = int(law_cd.get(tid, 0))
	law_cd[tid] = 0
	var before := cur_idx(tid)
	adopt_variant(tid, idx, bill_forced(b))
	vote_sponsor = 0
	var ok: bool = cur_idx(tid) == idx and before != idx
	if not ok:
		law_cd[tid] = was
	cap_unswap(pm, old)
	ai_note("bill_passed" if ok else "bill_failed")
	if not ok:
		log_tag("ЗАКОНОПРОЕКТ", COL_NEUTRAL, "законопроект правительства «%s» не набрал голосов." % law_index[tid]["name"])
