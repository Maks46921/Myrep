extends SceneTree
# dev: режим наблюдателя N месяцев: country=XX months=N observer=1
func _init():
	var months := 60
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("months="): months = int(String(a).substr(7))
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	g.observer_start()
	var laws0: Dictionary = g.law_state.duplicate()
	for m in months:
		if g.game_over: break
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty(): print("stuck event: ", g.current_event["t"]); g.choose(0)
		g.next_turn()
	if g.election_open: g.election_continue()
	var changed := 0
	for t in laws0:
		if int(laws0[t]) != int(g.law_state[t]): changed += 1
	print("observer %s: t=%d over=%s opp=%s laws_changed=%d cap=%.1f appr=%.1f debt=%.0f%% gov=%s" % [g.ccode, g.turn, g.game_over, g.opp_mode, changed, g.capital, g.approval(), g.debt / g.gdp * 100.0, g.coalition_names()])
	quit()
