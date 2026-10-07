extends SceneTree
# Недельные тики: итоги за 24 месяца при шаге по дням (недельные тики) близки к чисто месячному расчёту.
var bad := 0
func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)

func mk(sd: int) -> Node:
	var m = load("res://main.gd").new()
	m.game_opts.merge({"ev": 0.0, "news": 0.0, "fedev": 0, "socev": 0, "exev": 0}, true)
	m.game_opts["seed"] = sd
	root.add_child(m)
	return m

func _init():
	var a = mk(7)
	for i in 3: await process_frame
	var b = mk(7)
	for i in 3: await process_frame
	for i in 24:
		if a.election_open: a.election_continue()
		if not a.current_event.is_empty(): a.choose(0)
		a.next_turn()
	var guard := 0
	while b.turn < a.turn and guard < 2000:
		guard += 1
		if b.election_open: b.election_continue()
		if not b.current_event.is_empty(): b.choose(0)
		b.advance_day()
	print("месячный: gdp %.0f infl %.2f unemp %.2f appr %.1f debt %.0f cap %.1f" % [a.gdp, a.inflation, a.unemployment, a.approval(), a.debt, a.capital])
	print("недельный: gdp %.0f infl %.2f unemp %.2f appr %.1f debt %.0f cap %.1f" % [b.gdp, b.inflation, b.unemployment, b.approval(), b.debt, b.capital])
	check(b.turn == a.turn, "дошли до того же месяца")
	check(absf(b.gdp / a.gdp - 1.0) < 0.05, "ВВП близок")
	check(absf(b.inflation - a.inflation) < 2.0, "инфляция близка")
	check(absf(b.unemployment - a.unemployment) < 2.0, "безработица близка")
	check(absf(b.approval() - a.approval()) < 12.0, "рейтинг близок")
	check(b.month_done == 0.0 or b.day > 1, "доля месяца учтена")
	print("t_week: проблем ", bad)
	quit(1 if bad > 0 else 0)
