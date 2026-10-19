extends SceneTree
# 0.57: замер «перебиваний»: сколько раз за 36 месяцев игра останавливается на событии с выбором — без «Входящих» и с ними.
# Запуск: godot --headless --path . --script tests/m_interrupts.gd -- country=DE
func _init():
	var cc := "DE"
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("country="): cc = String(a).substr(8)
	for mode in [false, true]:
		var g = load("res://main.gd").new()
		root.add_child(g)
		for i in 5: await process_frame
		g.game_opts["inbox"] = mode
		var stops := 0
		var auto_n := 0
		for m in 36:
			if g.election_open: g.election_continue()
			if not g.current_event.is_empty():
				stops += 1
				g.choose(0)
			g.next_turn()
			if g.election_open: g.election_continue()
			if not g.current_event.is_empty():
				stops += 1
				g.choose(0)
			auto_n += g.inbox_done_month
		print("inbox=%s: остановок на событии за 36 мес.: %d; решено по принципам: %d; письма в ожидании: %d" % [mode, stops, auto_n, g.inbox.size()])
		g.queue_free()
		await process_frame
	quit()
