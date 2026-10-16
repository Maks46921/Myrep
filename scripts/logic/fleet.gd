# Флот и морская торговля (v30): порты, морские пути, инциденты, военно-морской флот.
# Данные — data/fleet.dat (tools/gen_fleet.py). Состояние — словарь flt. Ежедневный расчёт — fleet_day(), месячный — fleet_month().
# Все эффекты на экономику — отклонения от базового состояния (флот начальный, порты загружены на ~77%, инцидентов нет), поэтому без вмешательства
# игрока и без инцидентов базовые показатели не меняются. Случайные события флота используют отдельный генератор.
extends "res://scripts/logic/influence.gd"

# v37: возвращён в игру (в v31 был убран); данные для FI, SI, SK, HU; морская война — в military.gd.
# Происшествия на море выключаются настройкой «Военные угрозы и происшествия на море» (game_opts["milev"]).

var FLEET: Dictionary = {}
var flt: Dictionary = {}
var flt_rng := RandomNumberGenerator.new()
var flt_nodes: Dictionary = {}     # id -> узел
var flt_path_cache: Dictionary = {}

const FLT_KINDS := [
	["шторм", "Сильный шторм: суда стоят на якоре"], ["нападения на суда", "Нападения на торговые суда"], ["дрейфующие мины", "Обнаружены дрейфующие мины"],
	["блокада", "Заторы из-за блокады и военных учений"], ["авария танкера", "Авария танкера: пролив частично закрыт"], ["кибератака", "Кибератака на портовую систему"],
	["забастовка", "Забастовка портовиков и лоцманов"]]
const FLT_MISSIONS := [
	{"id": "convoy", "name": "Конвои и охрана торговых путей", "desc": "Флот сопровождает суда: инциденты слабее, но корабли изнашиваются."},
	{"id": "patrol", "name": "Береговой патруль", "desc": "Борьба с контрабандой и нелегальной миграцией, спокойнее на побережье, довольнее силовики."},
	{"id": "exercise", "name": "Совместные учения с союзниками", "desc": "Отношения с партнёрами растут, доверие силовиков тоже."},
	{"id": "visits", "name": "Дипломатические визиты в порты", "desc": "Престиж и отношения со всеми партнёрами, но защиты торговли меньше."}]


func fleet_load() -> void:
	if FLEET.is_empty():
		var d = ext_load("res://data/fleet.dat")
		FLEET = d if d != null else {}
		flt_nodes.clear()
		for n in FLEET.get("nodes", []):
			flt_nodes[String(n["id"])] = n


func flt_ports_of(cc: String) -> Array:
	var out: Array = []
	for p in FLEET.get("ports", []):
		if String(p["cc"]) == cc:
			out.append(p)
	return out


func flt_port(pid: String) -> Dictionary:
	for p in FLEET.get("ports", []):
		if String(p["id"]) == pid:
			return p
	return {}


func flt_has_sea() -> bool:
	return not flt.is_empty() and bool(flt.get("sea", false))


# список (порт, доля) страны; у стран без моря — порты договорного доступа
func flt_port_split(cc: String) -> Array:
	var out: Array = []
	var ps := flt_ports_of(cc)
	if not ps.is_empty():
		var tot := 0.0
		for p in ps:
			tot += float(p["w"])
		for p in ps:
			out.append([p, float(p["w"]) / tot])
	else:
		var acc: Dictionary = FLEET.get("access", {})
		if acc.has(cc):
			for a in acc[cc]:
				var pp := flt_port(String(a[0]))
				if not pp.is_empty():
					out.append([pp, float(a[1])])
	return out


func flt_path(a: String, b: String) -> Array:
	if a == b:
		return [a]
	var key := a + ">" + b
	if flt_path_cache.has(key):
		return flt_path_cache[key]
	var dist := {}
	var prev := {}
	var todo: Array = []
	for id in flt_nodes:
		dist[id] = 1.0e9
		todo.append(id)
	dist[a] = 0.0
	while not todo.is_empty():
		var best := ""
		var bd := 1.0e10
		for id in todo:
			if float(dist[id]) < bd:
				bd = float(dist[id])
				best = String(id)
		if best == "" or best == b:
			break
		todo.erase(best)
		var nb: Dictionary = flt_nodes[best]
		for n2 in nb["adj"]:
			var m: Dictionary = flt_nodes[String(n2)]
			var d: float = bd + Vector2(float(nb["x"]) - float(m["x"]), float(nb["y"]) - float(m["y"])).length()
			if d < float(dist[String(n2)]):
				dist[String(n2)] = d
				prev[String(n2)] = best
	var path: Array = [b]
	var cur := b
	var guard := 0
	while prev.has(cur) and guard < 60:
		cur = String(prev[cur])
		path.push_front(cur)
		guard += 1
	flt_path_cache[key] = path
	return path


func flt_path_len(path: Array) -> float:
	var l := 0.0
	for i in range(1, path.size()):
		var n1: Dictionary = flt_nodes[String(path[i - 1])]
		var n2: Dictionary = flt_nodes[String(path[i])]
		l += Vector2(float(n1["x"]) - float(n2["x"]), float(n1["y"]) - float(n2["y"])).length()
	return l * 2.87     # км (одна единица карты ≈ 2,9 км)


func fleet_init() -> void:
	fleet_load()
	flt = {"sea": false}
	if OS.get_environment("NOFLEET") != "" or FLEET.is_empty() or not WORLD.has(ccode):
		return
	flt_rng.seed = hash(ccode) + 4242
	var own: Array = flt_port_split(ccode)
	var landlocked: bool = flt_ports_of(ccode).is_empty()
	var ss: float = float(FLEET["sea_share"].get(ccode, 0.4))
	var ss_eff: float = ss if not landlocked else 0.42
	var gdp0: float = gdp
	var flows: Array = []
	var edge: Dictionary = {}
	var ntraf: Dictionary = {}
	var ldm: Dictionary = {}
	for ps in own:
		ldm[String((ps[0] as Dictionary)["id"])] = 0.0
	var total := 0.0
	var add_flow := func(label: String, cc2: String, vol: float, pb_list: Array) -> void:
		if vol <= 0.01:
			return
		var fl_item := {"to": label, "cc": cc2, "vol": vol, "paths": []}
		for ps in own:
			var pa: Dictionary = ps[0]
			for pb in pb_list:
				var share: float = float(ps[1]) * float(pb[1])
				var path: Array = flt_path(String(pa["node"]), String((pb[0] as Dictionary)["node"]))
				var v2: float = vol * share
				for i in range(1, path.size()):
					var k1 := String(path[i - 1])
					var k2 := String(path[i])
					var ek := (k1 + "|" + k2) if k1 < k2 else (k2 + "|" + k1)
					edge[ek] = float(edge.get(ek, 0.0)) + v2
				for nid in path:
					ntraf[String(nid)] = float(ntraf.get(String(nid), 0.0)) + v2
				ldm[String(pa["id"])] = float(ldm[String(pa["id"])]) + v2
				(fl_item["paths"] as Array).append([String(pa["id"]), String((pb[0] as Dictionary)["id"]), v2, flt_path_len(path)])
		flows.append(fl_item)
	var wt: Dictionary = WORLD_TRADE
	for c in WORLD:
		if c == ccode:
			continue
		var ex: float = float(wt.get(ccode, {}).get(c, 0.0))
		var im: float = float(wt.get(c, {}).get(ccode, 0.0))
		var s_other: float = float(FLEET["sea_share"].get(c, 0.4))
		var s_pair: float = (ss_eff + (s_other if s_other > 0.0 else 0.42)) * 0.5
		var pbl: Array = flt_port_split(c)
		if pbl.is_empty():
			continue
		var vol: float = (ex + im) * s_pair
		add_flow.call(String(WORLD[c]["name"]), c, vol, pbl)
	# торговля с остальным миром: через Атлантику и Суэц
	var row: float = gdp0 * float(WORLD_OPEN.get(ccode, 0.5)) * 0.45 * ss_eff
	for gate in ["ATL", "SUZ"]:
		var gp := {"id": gate, "node": gate, "w": 1.0}
		var vol_g := 0.0
		for ps in own:
			var atl: float = float((ps[0] as Dictionary)["atl"])
			vol_g += row * float(ps[1]) * (atl if gate == "ATL" else 1.0 - atl)
		add_flow.call("Остальной мир (%s)" % ("Атлантика" if gate == "ATL" else "Суэц и Азия"), "ROW", vol_g, [[gp, 1.0]])
	for f in flows:
		total += float(f["vol"])
	var ports: Dictionary = {}
	for ps in own:
		var pid := String((ps[0] as Dictionary)["id"])
		var l0: float = float(ldm[pid])
		ports[pid] = {"cap": maxf(1.0, l0 / 0.77), "load0": l0, "lvl": 0, "build": 0, "cost": 0.0}
	var navy0: Dictionary = (FLEET["navy0"].get(ccode, {}) as Dictionary).duplicate()
	var nv: Dictionary = {}
	for cl in FLEET["classes"]:
		nv[String(cl["id"])] = int(navy0.get(String(cl["id"]), 0))
	flt = {"sea": true, "land": landlocked, "ss": ss_eff, "gdp0": gdp0, "flows": flows, "edge": edge, "ntraf": ntraf, "total": total, "ports": ports,
		"navy": nv, "navy0": nv.duplicate(), "queue": [], "mission": "convoy", "merch": 0, "inc": {}, "f": 1.0, "util": 0.77, "pend": {}, "hist_f": [1.0], "hist_u": [0.77],
		"log": [], "days": 0, "stress": 0.0, "inc_n": 0, "lost_bn": 0.0, "up": 0.0}
	flt["power0"] = fleet_power()
	flt["need"] = maxf(8.0, float(flt["power0"]) * 1.15)


func fleet_power() -> float:
	var p := 0.0
	if flt.is_empty() or not flt.has("navy"):
		return 0.0
	for cl in FLEET["classes"]:
		p += float(int(flt["navy"].get(String(cl["id"]), 0))) * float(cl["pow"])
	return p


func fleet_class(id: String) -> Dictionary:
	for cl in FLEET.get("classes", []):
		if String(cl["id"]) == id:
			return cl
	return {}


# защита торговли: доля угрозы, которую закрывает флот (0…1,3)
func fleet_cover() -> float:
	if not flt_has_sea():
		return 1.0
	if bool(flt["land"]):
		return 0.85
	var mult := 1.25 if String(flt["mission"]) == "convoy" else (0.7 if String(flt["mission"]) == "visits" else 1.0)
	return clampf(fleet_power() * mult / float(flt["need"]), 0.0, 1.3)


func fleet_scale() -> float:
	if not flt_has_sea():
		return 1.0
	return gdp / float(flt["gdp0"])


func fleet_port_util(pid: String) -> float:
	var p: Dictionary = flt["ports"][pid]
	var cap: float = float(p["cap"])
	return float(p["load0"]) * fleet_scale() / cap


func fleet_util() -> float:
	if not flt_has_sea() or bool(flt["land"]) or (flt["ports"] as Dictionary).is_empty():
		return 0.0
	var l := 0.0
	var c := 0.0
	for pid in flt["ports"]:
		l += float(flt["ports"][pid]["load0"]) * fleet_scale()
		c += float(flt["ports"][pid]["cap"])
	return l / maxf(c, 1.0)


func fleet_sea_gdp() -> float:
	if not flt_has_sea():
		return 0.0
	return float(flt["total"]) / float(flt["gdp0"])


# вклад флота и портов в рост (п.п. в год) и инфляцию
func fleet_g() -> float:
	if not flt_has_sea():
		return 0.0
	var sg := fleet_sea_gdp()
	var u := fleet_util()
	return -(1.0 - float(flt["f"])) * sg * 5.0 - maxf(0.0, u - 0.98) * sg * 4.0 + float(flt["merch"]) * 0.01 * sg


func fleet_infl() -> float:
	if not flt_has_sea():
		return 0.0
	var sg := fleet_sea_gdp()
	return (1.0 - float(flt["f"])) * sg * 3.0 + maxf(0.0, fleet_util() - 0.98) * sg * 2.0


func fleet_recalc_f() -> void:
	var tot: float = maxf(1.0, float(flt["total"]))
	var lost := 0.0
	for nid in flt["inc"]:
		var it: Dictionary = flt["inc"][nid]
		lost += float(it["sev"]) * float(flt["ntraf"].get(nid, 0.0)) / tot
	flt["f"] = clampf(1.0 - lost, 0.4, 1.0)


func fleet_log(txt: String, col: String = "") -> void:
	if flt.has("log"):
		(flt["log"] as Array).append("%s — %s" % [date_text(), txt])
		if (flt["log"] as Array).size() > 40:
			(flt["log"] as Array).pop_front()
	log_tag("ФЛОТ", col if col != "" else COL_TEAL, "%s — %s" % [date_text(), txt])


func fleet_day() -> void:
	if not flt_has_sea() or game_over:
		return
	flt["days"] = int(flt["days"]) + 1
	flt["dm"] = int(flt.get("dm", 0)) + 1
	# стройки: корабли и расширение портов
	var q: Array = flt["queue"]
	for it in q:
		it["left"] = int(it["left"]) - 1
	var i := 0
	while i < q.size():
		if int(q[i]["left"]) <= 0:
			var cl: Dictionary = fleet_class(String(q[i]["cls"]))
			flt["navy"][String(q[i]["cls"])] = int(flt["navy"][String(q[i]["cls"])]) + 1
			fleet_log("в строй вступил %s — флот усилен." % String(cl["one"]), COL_GOOD)
			add_support("Силовики", 0.5)
			q.remove_at(i)
		else:
			i += 1
	for pid in flt["ports"]:
		var p: Dictionary = flt["ports"][pid]
		if int(p["build"]) > 0:
			p["build"] = int(p["build"]) - 1
			if int(p["build"]) == 0:
				p["cap"] = float(p["cap"]) * 1.12
				p["lvl"] = int(p["lvl"]) + 1
				fleet_log("расширение порта «%s» завершено: пропускная способность +12%%." % String(flt_port(pid)["name"]), COL_GOOD)
	# активные инциденты
	var ended: Array = []
	for nid in flt["inc"]:
		var it2: Dictionary = flt["inc"][nid]
		it2["days"] = int(it2["days"]) - 1
		flt["lost_bn"] = float(flt["lost_bn"]) + float(it2["sev"]) * float(flt["ntraf"].get(nid, 0.0)) / 365.0
		if int(it2["days"]) <= 0:
			ended.append(nid)
	for nid in ended:
		fleet_log("судоходство в районе «%s» восстановлено." % String(flt_nodes[nid]["name"]))
		flt["inc"].erase(nid)
	# новые инциденты (отдельный генератор: на рулетку игры не влияют)
	var cover := fleet_cover()
	if int(game_opts.get("milev", 1)) == 1 and flt_rng.randf() < 0.0035 * (1.0 + float(flt["stress"])):
		fleet_incident(cover)
	fleet_recalc_f()
	if int(flt["days"]) % 7 == 0:
		(flt["hist_f"] as Array).append(float(flt["f"]))
		(flt["hist_u"] as Array).append(fleet_util())
		for k in ["hist_f", "hist_u"]:
			if (flt[k] as Array).size() > 260:
				(flt[k] as Array).pop_front()


func fleet_incident(cover: float) -> void:
	var tot := 0.0
	var ws: Array = []
	for nid in flt_nodes:
		var w2: float = float(flt_nodes[nid]["risk"]) * (float(flt["ntraf"].get(nid, 0.0)) / maxf(1.0, float(flt["total"])) + 0.03)
		if flt["inc"].has(nid):
			w2 = 0.0
		ws.append([nid, w2])
		tot += w2
	if tot <= 0.0:
		return
	var r := flt_rng.randf() * tot
	var nid2 := ""
	for w3 in ws:
		r -= float(w3[1])
		if r <= 0.0:
			nid2 = String(w3[0])
			break
	if nid2 == "":
		nid2 = String(ws[0][0])
	var kind: Array = FLT_KINDS[flt_rng.randi() % FLT_KINDS.size()]
	var sev: float = flt_rng.randf_range(0.2, 0.7) * (1.0 - 0.7 * minf(1.0, cover)) * (1.0 - 0.06 * float(flt["merch"]))
	var days: int = flt_rng.randi_range(5, 24)
	flt["inc_n"] = int(flt["inc_n"]) + 1
	var share: float = float(flt["ntraf"].get(nid2, 0.0)) / maxf(1.0, float(flt["total"]))
	var nm := String(flt_nodes[nid2]["name"])
	if sev >= 0.18 and share >= 0.10 and flt_rng.randf() < 0.25 and current_event.is_empty() and not election_open and not blocked():
		flt["pend"] = {"node": nid2, "sev": sev, "days": days, "kind": String(kind[0])}
		fleet_present_event(nid2, kind, sev, days)
		return
	flt["inc"][nid2] = {"sev": sev, "days": days, "kind": String(kind[0])}
	fleet_log("%s — район «%s», %d сут. (потери торговли до %.0f%%)." % [String(kind[1]), nm, days, sev * share * 100.0], COL_WARN)


func fleet_present_event(nid: String, kind: Array, sev: float, days: int) -> void:
	var nm := String(flt_nodes[nid]["name"])
	var ev := {"t": "%s в районе «%s»: через него идёт часть вашей торговли, ожидаемый простой — %d суток. Что делаем?" % [String(kind[1]), nm, days], "special": "fleet",
		"o": [{"l": "Отправить эскорт и спасательные суда (долг +0.1% ВВП, капитал −2)", "fx": {"debt": 0.1, "capital": -2.0, "support": {"Силовики": 2.0}}},
			{"l": "Ничего не делать, подождать", "fx": {"support": {"Бизнес": -1.0}}},
			{"l": "Выплатить компенсации судоходным компаниям (долг +0.15% ВВП)", "fx": {"debt": 0.15, "support": {"Бизнес": 2.0, "Рабочие": 1.0}}}]}
	current_event = ev
	event_region = -1
	if auto_event_ok(ev):
		auto_resolve_event()
	else:
		present_event()


# вызывается из choose() после применения вариантов события
func fleet_resolve(i: int) -> void:
	var pnd: Dictionary = flt.get("pend", {})
	if pnd.is_empty():
		return
	var sev: float = float(pnd["sev"])
	var days: int = int(pnd["days"])
	if i == 0:
		sev *= 0.5
		days = int(float(days) * 0.6)
	elif i == 2:
		sev *= 0.75
	if flt_has_sea():
		flt["inc"][String(pnd["node"])] = {"sev": sev, "days": maxi(2, days), "kind": String(pnd["kind"])}
		fleet_recalc_f()
	flt["pend"] = {}


func fleet_month() -> void:
	if not flt_has_sea() or game_over:
		return
	# без дневных шагов (месячный режим тестов и прогонов) — проживаем месяц по дням здесь
	if int(flt.get("dm", 0)) == 0:
		for k in 30:
			fleet_day()
	flt["dm"] = 0
	# содержание сверх базового состава и политика торгового флота
	var extra := 0.0
	for cl in FLEET["classes"]:
		var id := String(cl["id"])
		extra += maxf(0.0, float(int(flt["navy"][id]) - int(flt["navy0"][id]))) * float(cl["up"])
	flt["up"] = extra
	debt += (extra + float(flt["merch"]) * 0.0002 * gdp) / 12.0
	# миссии
	var m := String(flt["mission"])
	if m == "patrol":
		add_support("Силовики", 0.25)
	elif m == "exercise":
		add_support("Силовики", 0.2)
		dip_all(0.25, false)
	elif m == "visits":
		dip_all(0.4, false)
	var pw0: float = maxf(1.0, float(flt["power0"]))
	add_support("Силовики", clampf((fleet_power() - float(flt["power0"])) / pw0 * 0.3, -0.6, 0.6))
	# автопилот: расширяет перегруженные порты
	if bool(ap.get("repair", false)) and fleet_util() > 1.0 and not bool(flt["land"]):
		var worst := ""
		var wu := 0.0
		for pid in flt["ports"]:
			var u: float = fleet_port_util(String(pid))
			if u > wu and int(flt["ports"][pid]["build"]) == 0:
				wu = u
				worst = String(pid)
		if worst != "":
			fleet_port_invest(worst, true)


func fleet_port_cost(pid: String) -> float:
	return maxf(0.2, float(flt["ports"][pid]["cap"]) * 0.025)


func fleet_port_invest(pid: String, auto: bool = false) -> bool:
	if not flt_has_sea() or not flt["ports"].has(pid):
		return false
	var p: Dictionary = flt["ports"][pid]
	if int(p["build"]) > 0:
		return false
	if not auto and cap_spendable() < 2.0:
		return false
	var cost := fleet_port_cost(pid)
	debt += cost
	if not auto:
		capital -= 2.0
	p["build"] = 365
	fleet_log("начато расширение порта «%s»: %.1f млрд €, 12 месяцев." % [String(flt_port(pid)["name"]), cost])
	return true


func fleet_can_build(id: String) -> bool:
	if not flt_has_sea() or bool(flt["land"]):
		return false
	if id == "car" and not (ccode in FLEET.get("carrier", [])):
		return false
	return true


func fleet_order(id: String) -> bool:
	if not fleet_can_build(id) or cap_spendable() < 2.0:
		return false
	var cl: Dictionary = fleet_class(id)
	if cl.is_empty() or (flt["queue"] as Array).size() >= 8:
		return false
	capital -= 2.0
	debt += float(cl["cost"])
	(flt["queue"] as Array).append({"cls": id, "left": int(cl["days"]), "total": int(cl["days"])})
	fleet_log("заказан %s: %.2f млрд €, срок %d сут." % [String(cl["one"]), float(cl["cost"]), int(cl["days"])])
	return true


func fleet_set_mission(id: String) -> void:
	if flt_has_sea():
		flt["mission"] = id


func fleet_merch(d: int) -> bool:
	if not flt_has_sea():
		return false
	var nv: int = clampi(int(flt["merch"]) + d, 0, 4)
	if nv == int(flt["merch"]):
		return false
	if d > 0 and cap_spendable() < 2.0:
		return false
	if d > 0:
		capital -= 2.0
	flt["merch"] = nv
	return true


func fleet_ports_summary() -> Array:
	var out: Array = []
	if not flt_has_sea():
		return out
	for pid in flt["ports"]:
		var pp: Dictionary = flt_port(String(pid))
		out.append({"id": String(pid), "name": String(pp["name"]), "kind": String(pp["kind"]), "cap": float(flt["ports"][pid]["cap"]), "util": fleet_port_util(String(pid)),
			"build": int(flt["ports"][pid]["build"]), "lvl": int(flt["ports"][pid]["lvl"])})
	out.sort_custom(func(a, b) -> bool: return float(a["cap"]) > float(b["cap"]))
	return out


# отрезки морских путей для карты: [точка a, точка b, доля трафика, заблокированность]
func fleet_lane_edges() -> Array:
	var out: Array = []
	if not flt_has_sea():
		return out
	var mx := 1.0
	for ek in flt["edge"]:
		mx = maxf(mx, float(flt["edge"][ek]))
	for ek in flt["edge"]:
		var ab: PackedStringArray = String(ek).split("|")
		var n1: Dictionary = flt_nodes[ab[0]]
		var n2: Dictionary = flt_nodes[ab[1]]
		var blk := 0.0
		for nid in ab:
			if flt["inc"].has(nid):
				blk = maxf(blk, float(flt["inc"][nid]["sev"]))
		out.append([Vector2(float(n1["x"]), float(n1["y"])), Vector2(float(n2["x"]), float(n2["y"])), float(flt["edge"][ek]) / mx, blk])
	return out


func fleet_status_text() -> String:
	if not flt_has_sea():
		return "Данных нет."
	return "Морская торговля: %.0f млрд € в год (%.0f%% ВВП); загрузка портов %.0f%%; пропускная способность морских путей %.0f%%; защита торговли %.0f%%." % [float(flt["total"]) * fleet_scale(), fleet_sea_gdp() * 100.0 * fleet_scale(), fleet_util() * 100.0, float(flt["f"]) * 100.0, fleet_cover() * 100.0]
