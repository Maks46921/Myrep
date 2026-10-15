# Товары: потребительская корзина (18 видов), их цены и спрос, корзины групп населения.
extends "res://scripts/logic/laws.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func ind_cat_term(cat: String) -> float:
	return 0.0


# --- конец заглушек ---


func good_def(id: String) -> Dictionary:
	for g in GOODS:
		if g["id"] == id:
			return g
	return {}


func good_name(id: String) -> String:
	var g := good_def(id)
	return String(g["name"]) if not g.is_empty() else id


# Страна меняет доли товаров (GOODS_OVR); сумма по каждому рынку остаётся равной доле рынка в корзине.
func apply_goods() -> void:
	var kgm := {}
	for m in MARKETS:
		kgm[m["id"]] = float(m["kg"])
	var sums := {}
	for g in GOODS:
		var o: Dictionary = GOODS_OVR.get(g["id"], {})
		g["kg"] = float(g["kg"]) * float(o.get("kg", 1.0))
		if o.has("xf"):
			g["xf"] = float(o["xf"])
		sums[g["mk"]] = float(sums.get(g["mk"], 0.0)) + float(g["kg"])
	for g in GOODS:
		var s: float = float(sums.get(g["mk"], 0.0))
		if s > 0.0:
			g["kg"] = float(g["kg"]) / s * float(kgm.get(g["mk"], 0.0))


func goods_init() -> void:
	var gp := {}
	var gd := {}
	var gsh := {}
	var gh := {}
	for g in GOODS:
		gp[g["id"]] = 1.0
		gd[g["id"]] = 1.0
		gsh[g["id"]] = 0.0
		gh[g["id"]] = [1.0]
	ec["gp"] = gp
	ec["gd"] = gd
	ec["gsh"] = gsh
	ec["gh"] = gh


func prof_mult(group: String, gid: String) -> float:
	return float((GOOD_PROF.get(group, {}) as Dictionary).get(gid, 1.0))


# спрос на товары по рынкам (индекс 1.0 = старт); пересчитывает ec["gd"]
func goods_demand() -> Dictionary:
	var cidx: float = float(ec["Cidx"])
	var sums := {}
	var kgs := {}
	for g in GOODS:
		var id: String = g["id"]
		var c: float = maxf(0.2, 1.0 + float(g["ie"]) * (cidx - 1.0)) * pow(float(ec["gp"][id]), -float(g["pe"]))
		ec["gd"][id] = c
		var mid: String = g["mk"]
		sums[mid] = float(sums.get(mid, 0.0)) + float(g["kg"]) * c
		kgs[mid] = float(kgs.get(mid, 0.0)) + float(g["kg"])
	var out := {}
	for m in MARKETS:
		var mid2: String = m["id"]
		out[mid2] = float(sums[mid2]) / float(kgs[mid2]) if kgs.has(mid2) and float(kgs[mid2]) > 0.0 else cidx
	if ec["gd"].has("housing") and out.has("con"):
		out["con"] = 0.5 * cidx + 0.5 * float(ec["gd"]["housing"])
	return out


# цены товаров: следуют за ценой своего рынка плюс курс, пошлины, мировое сырьё, НДС, разовые шоки
func goods_prices() -> void:
	var mk: Dictionary = ec["mk"]
	var fxs: float = float(ec["fxs"])
	var tariff: float = float(ec["tariff"])
	var comm: float = float(ec["comm"])
	var gap: float = float(ec["real_gap"])
	var vat_r: float = float(pol["vat"]) / maxf(0.01, float(pol_def["vat"])) - 1.0
	var gp: Dictionary = ec["gp"]
	for g in GOODS:
		var id: String = g["id"]
		var pm: float = float((mk[g["mk"]] as Dictionary)["p"])
		var t: float = 1.0 + float(g["ps"]) * (pm - 1.0)
		t += float(g["xf"]) * (1.0 / fxs - 1.0) + float(g["tf"]) * 0.004 * (tariff - 5.0) + float(g["dc"]) * (comm - 1.0)
		t += 0.25 * float(g["vat"]) * vat_r
		if id == "housing":
			t += 0.5 * (float((mk["con"] as Dictionary)["p"]) - float((mk["srv"] as Dictionary)["p"])) - 0.02 * gap
		t += float(ec["gsh"][id]) + float(g["dr"]) * years_passed() + ind_cat_term(id)
		ec["gsh"][id] = float(ec["gsh"][id]) + randf_range(-0.005, 0.005) * float(game_opts["volat"])
		t -= float(ec["cpi_s"]) * 0.4
		gp[id] = clampf(float(gp[id]) + (t - float(gp[id])) * 0.2, 0.5, 2.5)
		ec["gsh"][id] = float(ec["gsh"][id]) * 0.9
		var h: Array = ec["gh"][id]
		h.append(float(gp[id]))
		if h.size() > 14:
			h.pop_front()


func goods_shock(id: String, v: float) -> void:
	if ec.is_empty() or not ec.has("gp") or not (ec["gp"] as Dictionary).has(id):
		return
	ec["gsh"][id] = float(ec["gsh"][id]) + v
	ec["gp"][id] = clampf(float(ec["gp"][id]) + v * 0.6, 0.5, 2.5)


func good_yoy(id: String) -> float:
	var h: Array = ec["gh"][id]
	return float(ec["gp"][id]) / float(h[0]) - 1.0 if h.size() > 1 else 0.0


func cpi_goods() -> float:
	var s := 0.0
	for g in GOODS:
		s += float(g["kg"]) * float(ec["gp"][g["id"]])
	return s


# индекс цен корзины группы (1.0 = старт)
func group_cpi(group: String) -> float:
	var num := 0.0
	var den := 0.0
	for g in GOODS:
		var w: float = float(g["kg"]) * prof_mult(group, g["id"])
		num += w * float(ec["gp"][g["id"]])
		den += w
	return num / maxf(den, 0.0001)


# на сколько процентов корзина группы подорожала сильнее (+) или слабее (−), чем средняя
func group_gap(group: String) -> float:
	return (group_cpi(group) / maxf(0.01, cpi_goods()) - 1.0) * 100.0


func goods_support_term(group: String) -> float:
	if ec.is_empty() or not ec.has("gp"):
		return 0.0
	return clampf(-0.9 * group_gap(group), -5.0, 5.0)


# главные статьи расходов группы: массив [id, доля]
func group_top_goods(group: String, n: int) -> Array:
	var items: Array = []
	var den := 0.0
	for g in GOODS:
		var w: float = float(g["kg"]) * prof_mult(group, g["id"])
		items.append([g["id"], w])
		den += w
	items.sort_custom(func(a, b): return float(a[1]) > float(b[1]))
	var out: Array = []
	for i in mini(n, items.size()):
		out.append([items[i][0], float(items[i][1]) / maxf(den, 0.0001)])
	return out
