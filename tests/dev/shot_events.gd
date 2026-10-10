extends SceneTree
# Скриншоты окна события: out=префикс. Показывает несколько событий из нового набора.
func snap(g, name: String, outp: String) -> void:
	for i in 6: await process_frame
	await create_timer(0.4).timeout
	root.get_viewport().get_texture().get_image().save_png("%s_%s.png" % [outp, name])
	print("saved ", name)
	while not g.current_event.is_empty(): g.choose(0)

func _init():
	var outp := "/tmp/ev"
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="): outp = String(a).substr(4)
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	for m in 3:
		while not g.current_event.is_empty(): g.choose(0)
		if g.election_open: g.election_continue()
		g.next_turn()
	while not g.current_event.is_empty(): g.choose(0)
	if g.election_open: g.election_continue()
	g.capital = 30.0
	for id in ["x_chip_plant", "x_bank_trouble", "x_flood", "x_terror_threat"]:
		g.current_event = g.ev_by_id(id)
		g.event_region = 2 if g.current_event.get("rreg", false) else -1
		g.present_event()
		await snap(g, id, outp)
	g.current_event = g.EVENTS[0]
	g.event_region = -1
	g.present_event()
	await snap(g, "old", outp)
	quit()
