extends SceneTree
# 0.62: в посуточной игре плановые выборы проходят в воскресенье, голосования по законам — в среду; месячный путь (next_turn) прежний.
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
	g.game_opts["ev"] = 0.0
	g.game_opts["news"] = 0.0
	g.current_event = {}
	# --- выборы по воскресеньям ---
	for run in 6:
		g.current_event = {}
		if g.election_open: g.election_continue()
		g.last_parl = g.turn - g.parl_term() + 1 + run       # срок наступит на закрытии месяца
		var lp0: int = g.last_parl
		var wd_seen := -1
		var held := false
		for i in 70:
			if g.blocked():
				if g.election_open:
					wd_seen = g.weekday()
					held = true
					g.election_continue()
				g.current_event = {}
				if held:
					break
			g.advance_day()
		check(held, "прогон %d: плановые выборы состоялись" % run)
		check(wd_seen == 6, "прогон %d: выборы в воскресенье (день недели %d)" % [run, wd_seen])
		check(g.last_parl > lp0, "прогон %d: срок парламента обновился" % run)
		check(g.day <= 7, "прогон %d: первое воскресенье месяца (день %d)" % [run, g.day])
	# --- старый путь: next_turn без дней проводит выборы на закрытии месяца ---
	g.current_event = {}
	if g.election_open: g.election_continue()
	g.last_parl = g.turn - g.parl_term() + 1
	g.next_turn()
	check(g.election_open or g.last_parl == g.turn, "next_turn: выборы на закрытии месяца, как раньше")
	if g.election_open: g.election_continue()
	# --- голосования по средам ---
	g.current_event = {}
	g.day = 20
	for b in g.bills.duplicate():
		pass
	print("t_sunday: проблем ", bad)
	m.free()
	quit(1 if bad > 0 else 0)
