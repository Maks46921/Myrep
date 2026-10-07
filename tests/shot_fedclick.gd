extends SceneTree
# Реальные щелчки мышью по вкладкам «Регионы и автономия» / «Территории» и кнопкам полномочий (нужен xvfb)
var g
var bad := 0

func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)

func click(c: Control) -> void:
	var gp: Vector2 = c.get_global_rect().get_center()
	var mm := InputEventMouseMotion.new(); mm.position = gp; mm.global_position = gp
	root.get_viewport().push_input(mm)
	await process_frame
	var pr := InputEventMouseButton.new(); pr.button_index = MOUSE_BUTTON_LEFT; pr.pressed = true; pr.position = gp; pr.global_position = gp
	root.get_viewport().push_input(pr)
	await process_frame
	var rl := InputEventMouseButton.new(); rl.button_index = MOUSE_BUTTON_LEFT; rl.pressed = false; rl.position = gp; rl.global_position = gp
	root.get_viewport().push_input(rl)
	await process_frame
	await process_frame

func _init():
	g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	g.capital = 200.0
	g.in_coalition.fill(true)
	g.show_desk(2)
	for i in 6: await process_frame
	check(g.subbar3.visible, "подпанель карты не видна")
	await click(g.sub3_buttons[1])
	for i in 4: await process_frame
	check(g.current_desk == 8, "щелчок по вкладке «Регионы и автономия» не открыл экран (desk %d)" % g.current_desk)
	var sp := -1
	for k in 5:
		if not (g.fw_comp_rows[k]["up"] as Button).disabled:
			sp = k
			break
	check(sp >= 0, "нет ни одной доступной передачи полномочия")
	if sp < 0:
		sp = 0
	var row: Dictionary = g.fw_comp_rows[sp]
	var up: Button = row["up"]
	var cap0: float = g.capital
	var lv0: int = int(g.regions[g.selected_region]["comp"][sp])
	await click(up)
	check(g.capital < cap0 and int(g.regions[g.selected_region]["comp"][sp]) == lv0 + 1, "щелчок по ▶ не передал полномочие")
	check((row["lbl"] as Label).text.contains("(+1)"), "подпись полномочия не обновилась: " + (row["lbl"] as Label).text)
	await click(g.sub3_buttons[2])
	for i in 4: await process_frame
	check(g.current_desk == 9, "вкладка «Территории» не открылась")
	check(g.tw_buy_rt.get_parsed_text().length() > 20, "окно покупки региона пустое")
	if g.tw_buy_units.size() > 1:
		g.tw_buy_pick.select(1)
		g.on_tw_changed()
		check(g.tw_buy_rt.get_parsed_text().length() > 20, "после смены региона текст пуст")
	await click(g.sub3_buttons[0])
	for i in 4: await process_frame
	check(g.current_desk == 2, "возврат на карту не удался")
	print("проблем %d" % bad)
	quit()
