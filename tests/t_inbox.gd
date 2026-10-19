extends SceneTree
# 0.57: «Входящие» — малые события уходят в список, не останавливают время и решаются по принципам.
var bad := 0

func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)

func _init():
	var m = load("res://main.gd").new()
	root.add_child(m)
	for i in 3: await process_frame
	var g = m
	var cc := "DE"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("country="):
			cc = a.substr(8)
	if cc != g.ccode:
		g.choose_country(cc)
		for i in 3: await process_frame
	g.game_opts["inbox"] = true
	g.game_opts["ev"] = 3.0
	seed(7)
	g.current_event = {}
	var seen := 0
	var maxq := 0
	var asked := 0
	for k in 60:
		if g.game_over:
			break
		if g.election_open:
			g.election_continue()
		if not g.current_event.is_empty():
			asked += 1
			g.choose(0)
		g.advance_month()
		seen = maxi(seen, g.inbox.size())
		maxq = maxi(maxq, g.inbox.size())
		for it in g.inbox:
			check(int(it["due"]) > g.turn - 1, "просроченное письмо осталось в списке")
	check(maxq > 0, "за 5 лет хотя бы одно событие ушло во «Входящие»")
	check(g.inbox.size() <= g.INBOX_MAX, "список не раздут (%d)" % g.inbox.size())
	# ручные действия
	if g.election_open:
		g.election_continue()
	g.current_event = {}
	g.inbox.clear()
	var ev: Dictionary = g.EVENTS[0]
	g.inbox.append({"ev": ev.duplicate(true), "rid": -1, "t0": g.turn, "due": g.turn + 3})
	g.inbox.append({"ev": ev.duplicate(true), "rid": -1, "t0": g.turn, "due": g.turn + 3})
	g.inbox_auto(0)
	check(g.inbox.size() == 1 and g.current_event.is_empty(), "«Как обычно» решает письмо")
	g.inbox_open(0)
	check(g.inbox.is_empty() and not g.current_event.is_empty(), "«Решить» открывает окно события")
	g.choose(0)
	check(g.current_event.is_empty(), "событие решено")
	# таймер
	var evm: Dictionary = ev.duplicate(true)
	evm["title"] = "__таймер"
	g.inbox.append({"ev": evm, "rid": -1, "t0": g.turn, "due": g.turn + 1})
	var t1: int = g.turn
	for _k in 6:
		if g.election_open:
			g.election_continue()
		if not g.current_event.is_empty():
			g.choose(0)
		g.advance_month()
		if g.turn > t1:
			break
	if not g.current_event.is_empty():
		g.choose(0)
	var still := false
	for it in g.inbox:
		still = still or String(it["ev"].get("title", "")) == "__таймер"
	check(not still, "по таймеру письмо решилось (turn %d→%d, ждут %d, ce %d)" % [t1, g.turn, g.inbox.size(), g.current_event.size()])
	# в тестах без включения опции маршрутизации нет
	g.game_opts["inbox"] = false
	g.current_event = ev.duplicate(true)
	g.event_region = -1
	check(not g.inbox_route(), "при выключенной опции письма не создаются")
	print("t_inbox: проблем ", bad, " (в очереди макс. ", maxq, ", лично ", asked, ")")
	m.free()
	quit(1 if bad > 0 else 0)
