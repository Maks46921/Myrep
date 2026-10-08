extends SceneTree
# v37: реальные щелчки мышью: вкладка «Армия и война», объявление войны, выбор соединения на карте и приказ,
# вкладка «Флот» и выбор района эскадры щелчком, белый мир (нужен xvfb)
var g
var bad := 0

func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)

func click_at(gp: Vector2, shift: bool = false) -> void:
	var mm := InputEventMouseMotion.new(); mm.position = gp; mm.global_position = gp
	root.get_viewport().push_input(mm)
	await process_frame
	var pr := InputEventMouseButton.new(); pr.button_index = MOUSE_BUTTON_LEFT; pr.pressed = true; pr.position = gp; pr.global_position = gp; pr.shift_pressed = shift
	root.get_viewport().push_input(pr)
	await process_frame
	var rl := InputEventMouseButton.new(); rl.button_index = MOUSE_BUTTON_LEFT; rl.pressed = false; rl.position = gp; rl.global_position = gp; rl.shift_pressed = shift
	root.get_viewport().push_input(rl)
	await process_frame
	await process_frame

func click(c: Control) -> void:
	var sc = c.get_parent()
	while sc != null and not (sc is ScrollContainer):
		sc = sc.get_parent()
	if sc != null:
		(sc as ScrollContainer).ensure_control_visible(c)
		for i in 3: await process_frame
	await click_at(c.get_global_rect().get_center())

func _init():
	g = load("res://main.gd").new()
	g.game_opts.merge({"ev": 0.0, "news": 0.0, "milev": 0}, true)
	root.add_child(g)
	for i in 5: await process_frame
	g.capital = 200.0
	g.in_coalition.fill(true)
	g.show_desk(2)
	for i in 6: await process_frame
	await click(g.sub3_buttons[3])
	for i in 4: await process_frame
	check(g.current_desk == 13, "вкладка «Армия и война» не открылась (desk %d)" % g.current_desk)
	check(g.war_tgt.item_count > 0 or g.ccode == "LU", "нет целей в списке")
	if g.war_tgt.item_count == 0:
		print("проблем %d" % bad)
		quit()
		return
	g.war_tgt.select(0)
	g.refresh()
	await click(g.war_btn["declare"])
	for i in 3: await process_frame
	check(g.mil_at_war(), "щелчок «Объявить войну» не начал войну: " + g.war_msg)
	# соединение на карте: щелчок по значку, затем по своей АТЕ
	g.map_fit_rect(g.map_country_rect(g.ccode))
	for i in 4: await process_frame
	var f: Dictionary = g.mil_units_of(g.ccode)[0]
	var v: Array = g.map_view()
	var org: Vector2 = g.map_ctl.get_global_rect().position
	var tp: Vector2 = g.war_token_pos(int(f["a"]), float(v[0]), v[1]) + org
	await click_at(tp)
	var sel: int = int(g.mil["sel"])
	check(sel >= 0 and g.mil_unit(sel)["cc"] == g.ccode, "щелчок по значку не выбрал соединение")
	var fs: Dictionary = g.mil_unit(sel)
	var free: Rect2 = g.map_free_rect()
	var tgt := -1
	var bestd := 0.0
	g.mil_bfs(int(fs["a"]), g.ccode)
	for a in g.mil_cc_ates(g.ccode):
		if not g.mil_reached(int(a)):
			continue
		var p: Vector2 = g.ate_c[int(a)] * float(v[0]) + (v[1] as Vector2)
		if not free.grow(-30.0).has_point(p) or g.ate_at(p) != int(a) or g.war_token_at(p) >= 0:
			continue
		var d: float = (g.ate_c[int(a)] as Vector2).distance_to(g.ate_c[int(fs["a"])])
		if d > bestd:
			bestd = d
			tgt = int(a)
	check(tgt >= 0, "не нашлось видимой своей АТЕ для приказа")
	if tgt >= 0:
		await click_at(g.ate_c[tgt] * float(v[0]) + (v[1] as Vector2) + org)
		check(not (fs["path"] as Array).is_empty() and int(fs["path"][-1]) == tgt, "щелчок по АТЕ не дал приказ: " + g.war_msg)
	# флот: щелчок по району
	await click(g.sub3_buttons[4])
	for i in 4: await process_frame
	check(g.current_desk == 14, "вкладка «Флот» не открылась")
	if g.flt_has_sea() and not bool(g.flt["land"]):
		var st0: String = String(g.mil["nav"]["station"])
		v = g.map_view()
		var pick := ""
		for nid in g.flt_nodes:
			var p2: Vector2 = Vector2(float(g.flt_nodes[nid]["x"]), float(g.flt_nodes[nid]["y"])) * float(v[0]) + (v[1] as Vector2)
			if nid != st0 and g.map_free_rect().grow(-20.0).has_point(p2) and g.war_token_at(p2) < 0:
				pick = String(nid)
				break
		if pick != "":
			var p3: Vector2 = Vector2(float(g.flt_nodes[pick]["x"]), float(g.flt_nodes[pick]["y"])) * float(v[0]) + (v[1] as Vector2) + org
			await click_at(p3)
			check(String(g.mil["nav"]["station"]) == pick, "щелчок по району не перевёл эскадру (%s -> %s)" % [st0, String(g.mil["nav"]["station"])])
		else:
			print("нет видимого района для щелчка")
	# белый мир кнопкой
	await click(g.sub3_buttons[3])
	for i in 4: await process_frame
	var bw: Button = g.war_btn["p_white"]
	check(bw.visible and not bw.disabled, "кнопка белого мира недоступна")
	await click(bw)
	check(not g.mil_at_war(), "белый мир не заключён: " + g.war_msg)
	print("проблем %d" % bad)
	quit()
