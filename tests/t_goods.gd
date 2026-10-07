extends SceneTree
# Товары: доли корзины сходятся, цены/спрос реагируют на шоки, у групп разные корзины, агенты видят цены.
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	var bad := 0
	var sk := 0.0
	var per := {}
	for x in g.GOODS:
		sk += float(x["kg"])
		per[x["mk"]] = float(per.get(x["mk"], 0.0)) + float(x["kg"])
	if absf(sk - 1.0) > 0.001:
		print("FAIL: сумма корзины %.4f" % sk); bad += 1
	for m in g.MARKETS:
		if float(m["kg"]) > 0.0 and absf(float(per.get(m["id"], 0.0)) - float(m["kg"])) > 0.001:
			print("FAIL: рынок %s: товары %.4f, корзина %.4f" % [m["id"], per.get(m["id"], 0.0), m["kg"]]); bad += 1
	if g.GOODS.size() < 18:
		print("FAIL: товаров %d" % g.GOODS.size()); bad += 1
	seed(11)
	for m in 6:
		g.next_turn()
	var base_cpi: float = g.cpi_goods()
	var b_old: float = g.group_gap("Пенсионеры")
	var b_rural: float = g.group_gap("Село")
	var b_biz: float = g.group_gap("Бизнес")
	var s_old: float = g.goods_support_term("Пенсионеры")
	g.goods_shock("fuel", 0.30)
	g.goods_shock("meds", 0.30)
	g.next_turn()
	var gap_old: float = g.group_gap("Пенсионеры") - b_old
	var gap_rural: float = g.group_gap("Село") - b_rural
	var gap_biz: float = g.group_gap("Бизнес") - b_biz
	print("cpi %.4f -> %.4f; разрыв корзин: пенсионеры %+.2f%%, село %+.2f%%, бизнес %+.2f%%" % [base_cpi, g.cpi_goods(), gap_old, gap_rural, gap_biz])
	if g.cpi_goods() <= base_cpi:
		print("FAIL: шок цен не поднял корзину"); bad += 1
	if gap_old <= gap_biz or gap_rural <= gap_biz:
		print("FAIL: у пенсионеров/села корзина должна дорожать сильнее, чем у бизнеса"); bad += 1
	if g.goods_support_term("Пенсионеры") >= s_old:
		print("FAIL: рост цен лекарств не снизил поддержку пенсионеров"); bad += 1
	if g.AG != null and g.ag_on:
		if g.AG.NG != g.GOODS.size():
			print("FAIL: у агентов нет корзины"); bad += 1
		var s := 0.0
		for j in g.AG.NG:
			s += g.AG.gw[j]
		if absf(s - 1.0) > 0.01:
			print("FAIL: доли расходов агента %.3f" % s); bad += 1
	for gd in g.GOODS:
		var p: float = g.ec["gp"][gd["id"]]
		if is_nan(p) or p < 0.4 or p > 3.0:
			print("FAIL: цена %s = %s" % [gd["id"], p]); bad += 1
	print("goods проблем %d" % bad if bad > 0 else "goods ok")
	quit(1 if bad > 0 else 0)
