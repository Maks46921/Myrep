extends SceneTree
# v47_1: скриншоты карточки агента и окна страны с объяснением отношения (out=префикс, country=XX)
func clear_ev(g) -> void:
	while not g.current_event.is_empty(): g.choose(0)
	if g.election_open: g.election_continue()


func snap(name: String, outp: String) -> void:
	for i in 6: await process_frame
	await create_timer(0.4).timeout
	root.get_viewport().get_texture().get_image().save_png("%s_%s.png" % [outp, name])
	print("saved ", name)


func _init():
	var outp := "/tmp/v47"
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="): outp = String(a).substr(4)
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	for m in 8:
		clear_ev(g)
		g.next_turn()
	clear_ev(g)
	# окно страны: Франция после пойманной разведки и пошлин
	var fr := "FR" if g.ccode != "FR" else "DE"
	g.fa_notify("spy", fr, 1.0)
	g.ex_tariff_set(fr, 1)
	for m in 2:
		clear_ev(g)
		g.next_turn()
	clear_ev(g)
	g.show_desk(10)
	for i in 5: await process_frame
	g.on_ex_meta(fr)
	var wi = g.wins["xw_info"]
	wi.size = Vector2(wi.size.x + 40.0, 900.0)
	wi.move_to_front()
	for i in 4: await process_frame
	var sc = wi.body
	while sc != null and not (sc is ScrollContainer): sc = sc.get_parent()
	if sc != null: sc.scroll_vertical = 100000
	await snap("strana", outp)
	# карточка агента: безработный, если есть
	g.show_desk(6)
	for i in 5: await process_frame
	var pick := 0
	for i in g.AG.n:
		if g.AG.emp[i] == 0 and g.AG.grp[i] != 2 and g.AG.unm[i] > 2:
			pick = i
			break
	g.ag_sel = pick
	var w = g.wins["pop_agent"]
	w.position = Vector2(w.position.x - 60.0, 110.0)
	w.size = Vector2(560.0, 670.0)
	w.move_to_front()
	g.update_pop_windows()
	await snap("agent", outp)
	quit()
