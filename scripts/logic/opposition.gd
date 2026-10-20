# Выбор партии, оппозиция и соглашения между партиями.
extends "res://scripts/logic/warpol.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func idl_react(p: int, kind: String) -> void:
	pass


func prm_init() -> void:
	pass


# --- конец заглушек ---


# роли партий по слотам: 0 — ваша, 6 — «прочие», REGIONAL_P (обычно 8) — региональная, PROTEST_P (обычно 9) — протестная.
# 0.56: играть можно за любую настоящую партию, в том числе региональную и протестную; не за сборные списки
const NO_PLAY_SLOTS := [6]
const NO_PLAY_NAMES := ["Прочие", "Прочая", "Местные списки", "Малые ", "Самовыдвиженцы", "Беспартийные", "Избирательные союзы", "Внепарламентские", "Независимые депутаты", "Внефракционные"]


func party_name_playable(nm: String) -> bool:
	for pre in NO_PLAY_NAMES:
		if nm.begins_with(pre):
			return false
	return nm.strip_edges() != ""
const NO_GOV_SLOTS := [6]     # v35: партии «кордона» (бывший слот 9) тоже договариваются, но неохотно

const OPP_ACTS := [
	{"id": "critic", "name": "Резко критиковать правительство", "cap": 3.0, "cd": 2, "seats": false,
		"desc": "Выступления и заявления: симпатии групп растут, правительство теряет устойчивость."},
	{"id": "rally", "name": "Митинги и работа в регионах", "cap": 4.0, "cd": 3, "seats": false,
		"desc": "Живая агитация: заметнее всего растёт поддержка групп, к которым ближе ваша партия."},
	{"id": "probe", "name": "Парламентское расследование", "cap": 6.0, "cd": 4, "seats": true,
		"desc": "Комиссия по скандалу: сильно бьёт по устойчивости правительства. Нужны места в парламенте."},
	{"id": "early", "name": "Требовать досрочных выборов", "cap": 12.0, "cd": 12, "seats": false,
		"desc": "Шанс вынудить власть назначить выборы растёт, когда правительство непопулярно или неустойчиво."},
	{"id": "nocon", "name": "Внести вотум недоверия", "cap": 8.0, "cd": 6, "seats": true,
		"desc": "Нужны голоса большинства: ваши, партий вне правительства и партий, которые вас поддерживают."},
	{"id": "join", "name": "Предложить войти в правящую коалицию", "cap": 8.0, "cd": 6, "seats": true,
		"desc": "Переговоры с главой правительства. Согласие зависит от отношений, вашего веса и устойчивости власти."},
]

const PACT_KINDS := [
	{"id": "talk", "cls": "friend", "name": "Провести переговоры", "cap": 3.0, "cd": 3, "left": 0,
		"desc": "Отношения с партией +8. Основа для любых соглашений."},
	{"id": "bloc", "cls": "support", "name": "Предвыборный блок", "cap": 6.0, "cd": 12, "left": -1,
		"desc": "Совместная кампания до следующих выборов: обе партии получают бонус к голосам. Нужны отношения от 55."},
	{"id": "tol", "cls": "support", "name": "Соглашение о поддержке", "cap": 7.0, "cd": 12, "left": 12,
		"desc": "Партия 12 мес. не голосует против вас в вотуме недоверия и терпит правительство. Нужны отношения от 45."},
	{"id": "votes", "cls": "support", "name": "Союз по голосованию", "cap": 5.0, "cd": 12, "left": 12,
		"desc": "12 мес. партия поддерживает ваши законы, если они ей не слишком вредят. Нужны отношения от 50."},
	{"id": "attack", "cls": "hostile", "name": "Публично атаковать", "cap": 2.0, "cd": 3, "left": 12,
		"desc": "Отношения −12, партия теряет часть голосов на год. Остальные партии замечают жёсткость."},
	{"id": "praise", "cls": "friend", "name": "Публично хвалить партию", "cap": 2.0, "cd": 3, "left": 6,
		"desc": "Отношения +6; партия получает небольшую прибавку голосов на полгода."},
	{"id": "aid", "cls": "support", "name": "Помочь партии ресурсами", "cap": 5.0, "cd": 6, "left": 0,
		"desc": "Партия получает +6 собственного политкапитала, отношения +6."},
	{"id": "scandal", "cls": "hostile", "name": "Раскрыть компромат", "cap": 8.0, "cd": 9, "left": 12,
		"desc": "55% успеха: партия теряет 8% голосов на год, отношения −20. Провал: все партии охладевают к вам, а вы теряете поддержку."},
	{"id": "isolate", "cls": "hostile", "name": "Объявить партию нерукопожатной", "cap": 6.0, "cd": 12, "left": 0,
		"desc": "Остальные партии охладевают к ней (−8): ей труднее найти союзников."},
]


# ---------- сходство партий ----------
func party_lean(g: String, p: int) -> float:
	if p == 0:
		return 6.0 * pow(float(GROUP_BASE[g]) / 50.0, 3.0)
	return float(LEAN[g][p])


func party_sim(p: int, q: int) -> float:
	var dot := 0.0
	var np := 0.0
	var nq := 0.0
	for g in GROUPS:
		var a := party_lean(g, p)
		var b := party_lean(g, q)
		dot += a * b
		np += a * a
		nq += b * b
	return dot / maxf(0.0001, sqrt(np * nq))


func prel_base(p: int) -> float:
	if p == 0:
		return 100.0
	var b := 22.0 + 75.0 * clampf((party_sim(0, p) - 0.35) / 0.65, 0.0, 1.0)
	if p == PROTEST_P:
		b -= 22.0
	if not opp_mode and in_coalition[p]:
		b += 6.0
	b += war_prel_term(p)
	return clampf(b, 4.0, 92.0)


func prel_init() -> void:
	prel.clear()
	for p in PARTY_NAMES.size():
		prel.append(prel_base(p))
	pacts.clear()
	opp_cd.clear()
	prm_init()


func pact_left(p: int, kind: String) -> int:
	if not pacts.has(p):
		return 0
	return int((pacts[p] as Dictionary).get(kind, 0))


func pact_has(p: int, kind: String) -> bool:
	return pact_left(p, kind) != 0


func pact_mult(p: int) -> float:
	var m := 1.0
	if p == 0:
		for q in pacts:
			if pact_has(int(q), "bloc"):
				m += 0.035
		return m
	if pact_has(p, "bloc"):
		m += 0.04
	if pact_has(p, "attack"):
		m -= 0.04
	if ai_pen.has(p):
		m -= 0.03
	if ai_blocs.has(p):
		m += 0.04
	if pact_has(p, "praise"):
		m += 0.02
	if pact_has(p, "scandal"):
		m -= 0.08
	return m


func cd_left(id: String) -> int:
	return int(opp_cd.get(id, 0))


# ---------- обмен идентичностями с прежней партией власти ----------
func player_swap_ok(k: int) -> bool:
	return k > 0 and k < PARTY_NAMES.size() and not (k in NO_PLAY_SLOTS) and party_name_playable(String(PARTY_NAMES[k]))


func swap_idx(v: int, k: int) -> int:
	return k if v == 0 else (0 if v == k else v)


func apply_player_party(k: int) -> void:
	player_orig = 0
	if not player_swap_ok(k):
		return
	var n := PARTY_NAMES.size()
	player_orig = k
	var old0_ministries: Array = []
	for m in DE_START_MIN.size():
		if int(DE_START_MIN[m]) == 0:
			old0_ministries.append(m)
	# --- имена, цвета, лидеры, описания ---
	var nm0: String = PARTY_NAMES[0]
	PARTY_NAMES[0] = PARTY_NAMES[k]
	PARTY_NAMES[k] = nm0
	var c0: Color = PARTY_COLORS[0]
	PARTY_COLORS[0] = PARTY_COLORS[k]
	PARTY_COLORS[k] = c0
	var ld0: String = String(PARTY_LEADERS[0]).replace(" (вы)", "")
	var ldk: String = String(PARTY_LEADERS[k])
	PARTY_LEADERS[0] = ldk + " (вы)"
	PARTY_LEADERS[k] = ld0 if ld0 != "" else "Лидер партии"
	var d0: String = String(PARTY_DESC[0])
	var dk: String = String(PARTY_DESC[k])
	d0 = d0.replace("Ваша партия", "Бывшая партия власти").replace("вы возглавляете", "она возглавляла").replace("Вы возглавляете", "Она возглавляла")
	PARTY_DESC[0] = "Ваша партия. " + dk
	PARTY_DESC[k] = d0
	# --- профили электората ---
	group_base0 = GROUP_BASE.duplicate()
	var newbase := {}
	for g in GROUPS:
		var arr: Array = LEAN[g]
		var lk: float = float(arr[k])
		# 0.56: у протестной партии вес растёт как (поддержка / 50)^1,5, а не ^3 (см. vote_weights) — иначе за АдГ на старте 34% вместо 26%
		newbase[g] = clampf(50.0 * pow(maxf(0.0001, lk) / 6.0, (2.0 / 3.0) if k == PROTEST_P else (1.0 / 3.0)), 14.0, 66.0)
		# 0.56: у прежней партии власти свой исходный LEAN (в Польше 3 и 5, а не 6): его и нужно сохранить
		arr[k] = float(arr[0]) * pow(float(GROUP_BASE[g]) / 50.0, 3.0)
		arr[0] = 6.0
	for g in GROUPS:
		GROUP_BASE[g] = newbase[g]
	for ri in REG_BIAS.size():
		var row: Array = REG_BIAS[ri]
		var t0: float = row[0]
		row[0] = row[k]
		row[k] = t0
	# --- стартовые места, коалиция, министерства ---
	var s0: int = DE_START_SEATS[0]
	DE_START_SEATS[0] = DE_START_SEATS[k]
	DE_START_SEATS[k] = s0
	var nc: Array = []
	for p in COALITION0:
		nc.append(swap_idx(int(p), k))
	COALITION0 = nc
	for m in DE_START_MIN.size():
		DE_START_MIN[m] = swap_idx(int(DE_START_MIN[m]), k)
	for i in HEMI_ORDER.size():
		HEMI_ORDER[i] = swap_idx(int(HEMI_ORDER[i]), k)
	# 0.56: региональная и протестная партии остаются собой, даже если теперь это ваша партия (слот 0)
	REGIONAL_P = swap_idx(REGIONAL_P, k)
	PROTEST_P = swap_idx(PROTEST_P, k)
	var ms := {}
	for key in MIN_SPECIAL:
		var parts: PackedStringArray = String(key).split(":")
		if parts.size() == 2:
			ms["%s:%d" % [parts[0], swap_idx(int(parts[1]), k)]] = MIN_SPECIAL[key]
		else:
			ms[key] = MIN_SPECIAL[key]
	MIN_SPECIAL = ms
	if UPPER.has("blocs"):
		for bl in UPPER["blocs"]:
			var lst: Array = bl[1]
			for i in lst.size():
				lst[i] = swap_idx(int(lst[i]), k)
	# 0.58: партия президента с правом вето (Польша) тоже меняет номер: иначе вето «переходило» к вашей партии
	if UPPER.has("veto_p"):
		UPPER["veto_p"] = swap_idx(int(UPPER["veto_p"]), k)
	# --- договорные характеристики: у вас их нет, у прежней партии власти — обычные ---
	var loyal: Dictionary = PARTY_TRAITS[0].duplicate(true)
	for p in range(1, n):
		if String(PARTY_TRAITS[p].get("trait", "")) == "лояльный":
			loyal = PARTY_TRAITS[p].duplicate(true)
			break
	PARTY_TRAITS[k] = loyal
	PARTY_TRAITS[0] = {"trait": "", "desc": "", "att_w": 0.45, "dem_w": 1.0, "port_w": 1.0, "law_met": 0.0, "law_unmet": 0.0, "base": 0.0, "fat_w": 1.0, "join": -99.0, "rating_w": 0.0}
	PARTY_DEMANDS[k] = []
	PARTY_DEMANDS[0] = []
	PARTY_LAW_DEMAND[k] = {}
	PARTY_LAW_DEMAND[0] = {}
	DE_JOIN_ADJ[k] = 0.0
	DE_JOIN_ADJ[0] = 0.0
	PARTY_MINISTRIES[k] = old0_ministries.slice(0, 4) if old0_ministries.size() > 0 else [0, 1, 10]
	PARTY_MINISTRIES[0] = []
	# --- голоса партий за варианты законов следуют за партией, а не за номером ---
	for t in LAW_TOPICS:
		for v in t["v"]:
			var ps: Variant = v.get("ps", null)
			if ps is Dictionary and (ps as Dictionary).size() > 0:
				var nps := {}
				for key in ps:
					nps[swap_idx(int(key), k)] = ps[key]
				v["ps"] = nps
	# 0.56: доли прошлых выборов (предел сдвига и потолок) считались до смены номеров партий — начать заново
	prev_raw = []


# ---------- создание правительства без вас ----------
func ai_coalition(f: int, allow0: bool) -> Dictionary:
	var members: Array = [f]
	var s: int = int(seats[f])
	var cands: Array = []
	for q in PARTY_NAMES.size():
		if q == f or seats[q] <= 0 or (q in NO_GOV_SLOTS) or (q == 0 and not allow0):
			continue
		var sc: float = party_sim(f, q) + (0.0 if q != 0 else float(prel[f]) / 400.0)
		if is_cordon(q) or is_cordon(f):
			# v35: «кордон» преодолевается только при сильном сходстве программ или после затяжного кризиса
			sc -= maxf(0.0, 0.30 - 0.06 * float(deadlock))
		cands.append([sc, q])
	cands.sort_custom(func(a, b) -> bool: return a[0] > b[0])
	for c in cands:
		if s >= MAJORITY:
			break
		if float(c[0]) < 0.34:
			break
		members.append(int(c[1]))
		s += int(seats[int(c[1])])
	return {"members": members, "pm": f, "seats": s, "ok": s >= MAJORITY}


func ai_form_gov(allow0: bool) -> Dictionary:
	var order: Array = []
	for p in PARTY_NAMES.size():
		if seats[p] > 0 and not (p in NO_GOV_SLOTS) and (p != 0 or allow0):
			order.append([int(seats[p]), p])
	order.sort_custom(func(a, b) -> bool: return a[0] > b[0])
	if order.is_empty():
		return {}
	for i in mini(3, order.size()):
		var c := ai_coalition(int(order[i][1]), allow0)
		if bool(c["ok"]):
			return c
	var f: int = int(order[0][1])
	var m := ai_coalition(f, allow0)
	m["ok"] = false
	return m


func opp_set_gov(g: Dictionary) -> void:
	opp_gov = g.duplicate(true)
	if not opp_gov.has("stab"):
		opp_gov["stab"] = 62.0
	opp_gov["since"] = turn
	for p in PARTY_NAMES.size():
		in_coalition[p] = false
	for q in opp_gov["members"]:
		if int(q) != 0:
			in_coalition[int(q)] = true
	satis.clear()
	conc.clear()
	joined.clear()
	for q in opp_gov["members"]:
		if int(q) != 0:
			satis[int(q)] = 60.0
			conc[int(q)] = 0.0
			joined[int(q)] = turn
	assign_ministries()
	for m in MINISTRIES.size():
		if ministries[m] == 0:
			ministries[m] = int(opp_gov["pm"])
	recompute_mods()


func opp_gov_text() -> String:
	if opp_gov.is_empty():
		return "правительство не сформировано"
	var parts: PackedStringArray = []
	for q in opp_gov["members"]:
		parts.append(PARTY_NAMES[int(q)])
	return "%s (глава — «%s», %d мест из %d)" % [", ".join(parts), PARTY_NAMES[int(opp_gov["pm"])], int(opp_gov.get("seats", 0)), SEATS]


func opp_gov_seats() -> int:
	var n := 0
	for q in opp_gov.get("members", []):
		n += int(seats[int(q)])
	return n


# v38: страны, где на старте правительство возглавляет не крупнейшая партия коалиции
# (Румыния: премьер Боложан от НЛП при большей СДП; Босния: председатель Совета министров Кришто от ХДЗ по этнической ротации)
const PM_LEAD_START := ["RO", "BA"]


func opp_init() -> void:
	opp_mode = false
	opp_gov = {}
	offer_pending = false
	prel_init()
	pm_lead = false
	coal_deal = {}
	if 0 in COALITION0:
		pm_lead = player_orig == 0 and ccode in PM_LEAD_START
		prev_raw = []   # 0.56: стартовые доли для предела сдвига берутся уже при готовой власти
		return
	opp_mode = true
	var members: Array = []
	for p in COALITION0:
		members.append(int(p))
	var best: int = int(members[0])
	for p in members:
		if seats[p] > seats[best]:
			best = int(p)
	opp_ap_saved = ap.duplicate()
	opp_ap_force()
	opp_set_gov({"members": members, "pm": best, "seats": 0, "ok": true, "stab": 64.0})
	opp_gov["seats"] = opp_gov_seats()
	prel_init()
	prev_raw = []   # 0.56: стартовые доли для предела сдвига берутся уже при готовой власти


func opp_ap_force() -> void:
	ap["bal"] = true
	ap["events"] = true
	ap["repair"] = true
	ap["build"] = true
	ap["target"] = 0.5


# ---------- смена режима: оппозиция ↔ власть ----------
func opp_enter(reason: String, keep: Dictionary = {}) -> void:
	if opp_mode:
		return
	opp_mode = true
	opp_ap_saved = ap.duplicate()
	opp_ap_force()
	var g := keep if not keep.is_empty() else ai_form_gov(false)
	if g.is_empty():
		g = {"members": [1], "pm": 1, "seats": 0, "ok": false}
	opp_set_gov(g)
	prel_init()
	last_nocon = turn
	crisis_months = 0
	commitments.clear()
	log_tag("ОППОЗИЦИЯ", COL_WARN, "%s Правительство: %s. Теперь вы в оппозиции: бюджет и министерства у других, но вы можете критиковать власть, вносить законопроекты, договариваться с партиями и искать пути к власти." % [reason, opp_gov_text()])


func junior_quit() -> void:
	# v36: младший партнёр с провальным рейтингом не уходит в отставку, а выходит из коалиции —
	# прежние партнёры правят дальше (если хватает мест) или собирают новое правительство
	var jn := junior_info()
	var members: Array = []
	for p in PARTY_NAMES.size():
		if p != 0 and in_coalition[p]:
			members.append(p)
	var g := {}
	if not members.is_empty():
		var s := 0
		for q in members:
			s += int(seats[int(q)])
		g = {"members": members, "pm": int(jn["pm"]), "seats": s, "ok": s * 2 > SEATS, "stab": 52.0}
		if not bool(g["ok"]):
			g = {}
	low_months = 0
	opp_enter("Рейтинг упал до %.0f%%: чтобы не тонуть вместе с правительством, ваша партия вышла из коалиции." % approval(), g)
	add_support("Молодёжь", 1.0)


func opp_to_gov(members: Array, pm: int, why: String) -> void:
	opp_mode = false
	# v50: автобаланс и автоответ на события включались на время оппозиции (ими правило чужое правительство);
	# вернувшись к власти, бюджет и решения — снова ваши (в автопилоте игрока остались только стройка и ремонт)
	if not observer:
		ap["bal"] = false
		ap["events"] = false
	for p in PARTY_NAMES.size():
		in_coalition[p] = false
	in_coalition[0] = true
	for q in members:
		if int(q) != 0:
			in_coalition[int(q)] = true
	if not opp_ap_saved.is_empty():
		for k2 in opp_ap_saved:
			ap[k2] = opp_ap_saved[k2]
	satis.clear()
	conc.clear()
	joined.clear()
	assign_ministries()
	for q in members:
		if int(q) != 0:
			satis[int(q)] = 58.0
			conc[int(q)] = 0.0
			joined[int(q)] = turn
	opp_gov = {}
	offer_pending = false
	crisis_months = 0
	capital = minf(100.0, capital + 8.0)
	prel_init()
	recompute_mods()
	log_tag("ВЛАСТЬ", COL_GOOD, "%s Вы входите в правительство: %s. Политкапитал +8." % [why, coalition_names()])


# ---------- ежемесячная жизнь оппозиции ----------
func gov_pop() -> float:
	var t := 0.0
	for g in GROUPS:
		t += target_gov_support(g) * float(GROUP_WEIGHT[g])
	return t


func opp_step() -> void:
	if game_over:
		return
	opp_ap_force()
	for id in opp_cd.keys():
		opp_cd[id] = maxi(0, int(opp_cd[id]) - 1)
	pacts_tick()
	for p in range(1, PARTY_NAMES.size()):
		prel[p] = clampf(float(prel[p]) + (prel_base(p) - float(prel[p])) * 0.04, 0.0, 100.0)
	if opp_gov.is_empty():
		return
	opp_gov["seats"] = opp_gov_seats()
	var st: float = float(opp_gov["stab"])
	st += (gov_pop() - 34.0) * 0.06 + randf_range(-1.2, 1.2)
	st += (60.0 - st) * 0.03
	if int(opp_gov["seats"]) < MAJORITY and not minority_ok:
		st -= 0.7
	st = clampf(st, 0.0, 100.0)
	opp_gov["stab"] = st
	if offer_pending and current_event.is_empty() and not election_open:
		opp_show_offer()
		return
	if st < 14.0 and turn - last_parl >= 18 and current_event.is_empty() and not election_open:
		log_tag("ОППОЗИЦИЯ", COL_GOOD, "Правительство потеряло устойчивость и ушло в отставку. Назначены досрочные выборы.")
		hold_parliament("правительство ушло в отставку")


func opp_act(id: String) -> bool:
	if not opp_mode or game_over:
		return false
	var a: Dictionary = {}
	for x in OPP_ACTS:
		if String(x["id"]) == id:
			a = x
	if a.is_empty() or cd_left(id) > 0 or cap_spendable() < float(a["cap"]):
		return false
	if bool(a["seats"]) and seats[0] <= 0:
		return false
	capital -= float(a["cap"])
	opp_cd[id] = int(a["cd"])
	match id:
		"critic":
			add_all_support(1.2)
			opp_gov["stab"] = clampf(float(opp_gov.get("stab", 60.0)) - 3.0, 0.0, 100.0)
			log_tag("ОППОЗИЦИЯ", COL_TEAL, "ваша партия резко раскритиковала власть: симпатии растут, устойчивость правительства падает.")
		"rally":
			var ranked: Array = []
			for g in GROUPS:
				ranked.append([party_lean(g, 0), g])
			ranked.sort_custom(func(x, y) -> bool: return x[0] > y[0])
			for i in 3:
				add_support(String(ranked[i][1]), 2.5)
			add_all_support(0.4)
			log_tag("ОППОЗИЦИЯ", COL_TEAL, "митинги и работа в регионах: поддержка %s, %s и %s выросла." % [ranked[0][1], ranked[1][1], ranked[2][1]])
		"probe":
			var hit := randf_range(5.0, 11.0)
			opp_gov["stab"] = clampf(float(opp_gov.get("stab", 60.0)) - hit, 0.0, 100.0)
			add_all_support(0.8)
			log_tag("ОППОЗИЦИЯ", COL_TEAL, "парламентская комиссия расследует работу правительства: устойчивость власти -%.0f." % hit)
		"early":
			var chance := clampf(0.10 + (50.0 - gov_pop()) * 0.012 + (60.0 - float(opp_gov.get("stab", 60.0))) * 0.008, 0.05, 0.85)
			if turn - last_parl < 6:
				chance *= 0.3
			if randf() < chance:
				log_tag("ОППОЗИЦИЯ", COL_GOOD, "давление оппозиции вынудило власть назначить досрочные выборы.")
				hold_parliament("досрочные выборы по требованию оппозиции")
				return true
			log_tag("ОППОЗИЦИЯ", COL_WARN, "требование досрочных выборов отклонено (шанс был %.0f%%)." % (chance * 100.0))
		"nocon":
			var yes: int = int(seats[0])
			var names: PackedStringArray = []
			for p in range(1, PARTY_NAMES.size()):
				if in_coalition[p] or seats[p] <= 0:
					continue
				if pact_has(p, "tol") or float(prel[p]) >= 55.0:
					yes += int(seats[p])
					names.append(PARTY_NAMES[p])
			var txt := "Вотум недоверия: за %d, нужно %d. Поддержали: %s." % [yes, MAJORITY, ", ".join(names) if names.size() > 0 else "только вы"]
			if yes >= MAJORITY:
				log_tag("ОППОЗИЦИЯ", COL_GOOD, txt + " Правительство пало, назначены досрочные выборы.")
				hold_parliament("вотум недоверия")
				return true
			opp_gov["stab"] = clampf(float(opp_gov.get("stab", 60.0)) + 4.0, 0.0, 100.0)
			add_all_support(-0.8)
			log_tag("ОППОЗИЦИЯ", COL_BAD, txt + " Вотум провален, власть окрепла.")
		"join":
			var pm: int = int(opp_gov["pm"])
			var chance2 := clampf(0.15 + (float(prel[pm]) - 40.0) * 0.012 + float(seats[0]) / float(SEATS) * 1.2 + (55.0 - float(opp_gov.get("stab", 60.0))) * 0.008, 0.03, 0.9)
			if seats[0] <= 0:
				chance2 = 0.0
			if randf() < chance2:
				var mem: Array = (opp_gov["members"] as Array).duplicate()
				mem.append(0)
				opp_to_gov(mem, pm, "«%s» приняла ваше предложение." % PARTY_NAMES[pm])
				return true
			prel[pm] = clampf(float(prel[pm]) - 4.0, 0.0, 100.0)
			log_tag("ОППОЗИЦИЯ", COL_WARN, "«%s» отказалась брать вас в коалицию (шанс был %.0f%%)." % [PARTY_NAMES[pm], chance2 * 100.0])
	refresh()
	return true


# ---------- переговоры и соглашения между партиями ----------
func pact_need(kind: String) -> float:
	match kind:
		"bloc": return 55.0
		"tol": return 45.0
		"votes": return 50.0
	return 0.0


func pact_can(p: int, kind: String) -> String:
	if game_over or p <= 0 or p >= PARTY_NAMES.size():
		return "нельзя"
	if p in NO_GOV_SLOTS and kind != "attack":
		return "партия не заключает соглашений"
	# v50: предвыборный блок, помощь, похвала и прочее доступны и партиям без мест; в парламенте нужны места только для голосов
	if seats[p] <= 0 and (kind == "tol" or kind == "votes"):
		return "у партии нет мест в парламенте"
	if int(seats[0]) <= 0 and (kind == "tol" or kind == "votes"):
		return "у вашей партии нет мест в парламенте"
	var pk: Dictionary = {}
	for x in PACT_KINDS:
		if String(x["id"]) == kind:
			pk = x
	if pk.is_empty():
		return "нельзя"
	if cap_spendable() < float(pk["cap"]):
		return "не хватает политкапитала"
	if cd_left("p%d_%s" % [p, kind]) > 0:
		return "ещё %d мес." % cd_left("p%d_%s" % [p, kind])
	if float(prel[p]) < pact_need(kind) - 0.001:
		return "отношения ниже %.0f" % pact_need(kind)
	if kind == "bloc" and (pact_has(p, "bloc")):
		return "блок уже заключён"
	if (kind == "tol" or kind == "votes") and pact_has(p, kind):
		return "уже действует"
	if kind == "tol" and in_coalition[p] and not opp_mode:
		return "партия уже в коалиции"
	return ""


func pact_do(p: int, kind: String) -> bool:
	if pact_can(p, kind) != "":
		return false
	var pk: Dictionary = {}
	for x in PACT_KINDS:
		if String(x["id"]) == kind:
			pk = x
	capital -= float(pk["cap"])
	opp_cd["p%d_%s" % [p, kind]] = int(pk["cd"])
	if not pacts.has(p):
		pacts[p] = {}
	match kind:
		"talk":
			prel[p] = clampf(float(prel[p]) + 8.0, 0.0, 100.0)
			log_tag("ПЕРЕГОВОРЫ", COL_PURPLE, "встреча с лидером «%s»: отношения %.0f." % [PARTY_NAMES[p], float(prel[p])])
		"bloc":
			var left: int = maxi(2, parl_term() - (turn - last_parl))
			pacts[p]["bloc"] = left
			prel[p] = clampf(float(prel[p]) + 5.0, 0.0, 100.0)
			log_tag("ПЕРЕГОВОРЫ", COL_PURPLE, "предвыборный блок с «%s» до следующих выборов: общая кампания добавит голосов обеим партиям." % PARTY_NAMES[p])
		"tol", "votes":
			pacts[p][kind] = int(pk["left"])
			prel[p] = clampf(float(prel[p]) + 3.0, 0.0, 100.0)
			var what: String = "терпит правительство и не голосует против вас" if kind == "tol" else "поддерживает ваши законы"
			log_tag("ПЕРЕГОВОРЫ", COL_PURPLE, "соглашение с «%s» на 12 мес.: партия %s." % [PARTY_NAMES[p], what])
		"praise":
			pacts[p]["praise"] = int(pk["left"])
			prel[p] = clampf(float(prel[p]) + 6.0, 0.0, 100.0)
			log_tag("ПЕРЕГОВОРЫ", COL_PURPLE, "вы публично хвалите «%s»: отношения %.0f." % [PARTY_NAMES[p], float(prel[p])])
		"aid":
			pcap[p] = minf(100.0, float(pcap[p]) + 6.0)
			prel[p] = clampf(float(prel[p]) + 6.0, 0.0, 100.0)
			log_tag("ПЕРЕГОВОРЫ", COL_PURPLE, "вы помогли «%s» ресурсами: её политкапитал %.0f." % [PARTY_NAMES[p], float(pcap[p])])
		"scandal":
			if randf() < 0.55:
				pacts[p]["scandal"] = int(pk["left"])
				prel[p] = clampf(float(prel[p]) - 20.0, 0.0, 100.0)
				pcap[p] = maxf(0.0, float(pcap[p]) - 6.0)
				log_tag("ПЕРЕГОВОРЫ", COL_WARN, "компромат на «%s» опубликован: партия теряет голоса и капитал." % PARTY_NAMES[p])
			else:
				for q in range(1, PARTY_NAMES.size()):
					prel[q] = clampf(float(prel[q]) - 5.0, 0.0, 100.0)
				add_all_support(-0.6)
				log_tag("ПЕРЕГОВОРЫ", COL_BAD, "компромат на «%s» оказался слабым: партии осуждают вашу грязную игру." % PARTY_NAMES[p])
		"isolate":
			for q in range(1, PARTY_NAMES.size()):
				if q != p:
					rel_add(p, q, -8.0)
			log_tag("ПЕРЕГОВОРЫ", COL_WARN, "вы объявили «%s» нерукопожатной: другие партии охладели к ней." % PARTY_NAMES[p])
		"attack":
			pacts[p]["attack"] = int(pk["left"])
			prel[p] = clampf(float(prel[p]) - 12.0, 0.0, 100.0)
			for q in range(1, PARTY_NAMES.size()):
				if q != p:
					prel[q] = clampf(float(prel[q]) - 1.0, 0.0, 100.0)
			add_all_support(0.4)
			log_tag("ПЕРЕГОВОРЫ", COL_WARN, "вы публично атаковали «%s»: отношения упали, партия теряет голоса." % PARTY_NAMES[p])
	idl_react(p, kind)
	recompute_mods()
	refresh()
	return true


func pacts_tick() -> void:
	for p in pacts.keys():
		var d: Dictionary = pacts[p]
		for k in d.keys():
			var v: int = int(d[k]) - 1
			if v <= 0:
				d.erase(k)
			else:
				d[k] = v
		if d.is_empty():
			pacts.erase(p)


# после выборов блоки распадаются, а бывшие союзники теплее
func pacts_after_election() -> void:
	ai_blocs.clear()
	ai_pen.clear()
	for p in pacts.keys():
		if pact_has(int(p), "bloc"):
			prel[int(p)] = clampf(float(prel[int(p)]) + 6.0, 0.0, 100.0)
			(pacts[p] as Dictionary).erase("bloc")
	for p in pacts.keys():
		if (pacts[p] as Dictionary).is_empty():
			pacts.erase(p)


# ---------- результат выборов для оппозиции ----------
func opp_after_election() -> String:
	pacts_after_election()
	# вы сильнейшая из допустимых партий — пробуем собрать власть вокруг себя
	var best := -1
	for p in PARTY_NAMES.size():
		if seats[p] > 0 and not (p in NO_GOV_SLOTS):
			if best < 0 or seats[p] > seats[best]:
				best = p
	if best == 0:
		var c := ai_coalition(0, true)
		if bool(c["ok"]):
			var mem: Array = c["members"]
			opp_to_gov(mem, 0, "Вы победили на выборах.")
			return "gov"
	var g := ai_form_gov(true)
	if g.is_empty():
		g = ai_form_gov(false)
	if not g.is_empty() and (0 in g["members"]) and int(g["pm"]) != 0:
		var g2 := g.duplicate(true)
		opp_set_gov(ai_form_gov(false) if not ai_form_gov(false).is_empty() else g2)
		offer_pending = true
		offer_gov = g2
		return "opp"
	if not g.is_empty() and int(g["pm"]) == 0:
		opp_to_gov(g["members"], 0, "Вы получили право формировать правительство.")
		return "gov"
	if g.is_empty():
		g = {"members": [1], "pm": 1, "seats": 0, "ok": false}
	opp_set_gov(g)
	return "opp"


func opp_show_offer() -> void:
	offer_pending = false
	if offer_gov.is_empty():
		return
	var pm: int = int(offer_gov["pm"])
	current_event = {"t": "«%s» после выборов предлагает вам войти в правительство: коалиция %s. Принять предложение?" % [PARTY_NAMES[pm], _gov_names(offer_gov)], "special": "offer", "o": [
		{"l": "Принять: войти в правительство", "fx": {}},
		{"l": "Отказаться и остаться в оппозиции (капитал +3)", "fx": {"capital": 3.0}}]}
	event_region = -1
	event_party = -1
	event_min = -1
	present_event()


func _gov_names(g: Dictionary) -> String:
	var parts: PackedStringArray = []
	for q in g["members"]:
		parts.append(PARTY_NAMES[int(q)])
	return ", ".join(parts)


func opp_resolve_offer(i: int) -> void:
	if i == 0 and not offer_gov.is_empty():
		opp_to_gov(offer_gov["members"], int(offer_gov["pm"]), "Вы приняли предложение.")
	offer_gov = {}


func opp_status_text() -> String:
	if not opp_mode:
		return "Вы в правительстве."
	return "[b]Вы в оппозиции.[/b] Правительство: %s. Устойчивость: [b]%.0f[/b]/100. Народная оценка власти: %.0f." % [opp_gov_text(), float(opp_gov.get("stab", 0.0)), gov_pop()]


# кампания в оппозиции: без долговых обещаний
func opp_campaign() -> void:
	var sh := national_shares(false)
	var rival := 1
	for p in range(1, PARTY_NAMES.size()):
		if sh[p] > sh[rival]:
			rival = p
	var txt := "До выборов %s осталось два месяца. По опросам ваша партия получает %.1f%%, главный соперник — «%s» (%.1f%%). Вы в оппозиции — чем вести кампанию?" % [
		tm("parl_g"), sh[0] * 100.0, PARTY_NAMES[rival], sh[rival] * 100.0]
	current_event = {"t": txt, "kind": "campaign", "o": [
		{"l": "Обвинить власть в провалах (капитал -3)", "fx": {"capital": -3.0, "all": 1.2, "support": {"Пенсионеры": 1.5, "Рабочие": 2.0}}},
		{"l": "Предложить «разумную альтернативу» (капитал -3)", "fx": {"capital": -3.0, "support": {"Бизнес": 2.5, "Силовики": 1.5, "Бюджетники": 1.5}}},
		{"l": "Молодёжь и перемены (капитал -3)", "fx": {"capital": -3.0, "support": {"Молодёжь": 4.0, "Экологи": 2.0}}},
		{"l": "Тур по регионам (капитал -4)", "fx": {"capital": -4.0, "all": 1.5, "regall": {"loyalty": 2.0}}},
		]}
	event_region = -1
	event_party = -1
	event_min = -1
	present_event()
