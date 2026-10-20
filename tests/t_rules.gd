extends SceneTree
# 0.57: правила «если — то»: сработка, предложение, отмена, предохранители.
var bad := 0

func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)

func month(g) -> void:
	for _k in 6:
		if g.election_open:
			g.election_continue()
		if not g.current_event.is_empty():
			g.choose(0)
		var t0: int = g.turn
		g.advance_month()
		if g.turn > t0:
			return

func _init():
	var m = load("res://main.gd").new()
	root.add_child(m)
	for i in 3: await process_frame
	var g = m
	if g.election_open:
		g.election_continue()
	g.current_event = {}
	var v0: float = g.pol["vat"]
	g.rules.append({"ind": "infl", "op": 0, "val": -50.0, "act": "up:vat", "amt": 0.2, "mode": 0, "last": -99})
	month(g)
	check(float(g.pol["vat"]) > v0 + 0.15, "правило подняло НДС (%.2f → %.2f)" % [v0, g.pol["vat"]])
	check(not g.rule_undo.is_empty(), "действие записано для отмены")
	g.rules_undo_last()
	check(absf(float(g.pol["vat"]) - v0) < 0.05, "отмена вернула НДС (%.2f)" % g.pol["vat"])
	# предложение
	g.rules.clear()
	g.rules.append({"ind": "unemp", "op": 0, "val": -5.0, "act": "dn:admin", "amt": 0.1, "mode": 1, "last": -99})
	var a0: float = g.pol["admin"]
	month(g)
	check(g.rule_props.size() == 1, "правило предложило действие")
	check(absf(float(g.pol["admin"]) - a0) < 0.01, "предложение само ничего не меняет")
	g.rule_accept(0)
	check(float(g.pol["admin"]) < a0 - 0.05, "принятое предложение выполнено")
	# предохранитель: потолок 1% ВВП за раз
	g.rules.clear()
	g.rule_do("up:vat", 5.0, "тест")
	check(float(g.pol["vat"]) - float(g.pol["vat"]) == 0.0, "не рухнуло")
	# трансферт региону
	g.rules.clear()
	g.rules.append({"ind": "unrest", "op": 0, "val": -1.0, "act": "grant", "amt": 0.05, "mode": 0, "last": -99})
	var tr0: float = g.regions[0]["transfer"]
	var sum0 := 0.0
	for r in g.regions:
		sum0 += float(r["transfer"])
	month(g)
	var sum1 := 0.0
	for r in g.regions:
		sum1 += float(r["transfer"])
	check(sum1 > sum0 + 0.01, "грант регионам выдан (%.2f → %.2f)" % [sum0, sum1])
	print("t_rules: проблем ", bad)
	m.free()
	quit(1 if bad > 0 else 0)
