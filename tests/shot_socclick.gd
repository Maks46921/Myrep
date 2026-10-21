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

# кнопка может быть ниже видимой части окна: прокрутить к ней
func reveal(c: Control) -> void:
	var sc = c.get_parent()
	while sc != null and not (sc is ScrollContainer):
		sc = sc.get_parent()
	if sc != null:
		(sc as ScrollContainer).ensure_control_visible(c)
	for i in 3: await process_frame

func _init():
	g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	g.capital = 300.0
	g.show_desk(1)
	for i in 6: await process_frame
	check(g.subbar.visible and g.sub_buttons.size() == 5, "подпанель политики: ждали 5 вкладок")
	# v55_1: «Религия и миграция» — в рамке «Общество»
	await click(g.desk_buttons[5])
	for i in 4: await process_frame
	check(g.subbar4.visible and g.sub4_buttons.size() == 3, "нет подпанели рамки «Общество»")
	await click(g.sub4_buttons[0])
	for i in 4: await process_frame
	check(g.current_desk == 11, "вкладка «Религия и миграция» не открылась (desk %d)" % g.current_desk)
	check(g.sw_rel_rt.get_parsed_text().length() > 60, "таблица религий пуста")
	var lv0: int = int(g.soc["lvl"])
	var b: Button = g.sw_btn["mig+"]
	check(not b.disabled, "кнопка «Мягче границы» недоступна")
	await click(b)
	check(int(g.soc["lvl"]) == lv0 + 1, "щелчок «Мягче границы» не сработал")
	await click(g.sub4_buttons[1])
	for i in 4: await process_frame
	check(g.current_desk == 20, "вкладка «Церковь и государство» не открылась (desk %d)" % g.current_desk)
	await click(g.sw_btn["sec+"])
	check(int(g.soc["sec"]) == 2, "щелчок «Больше секуляризма» не сработал")
	check(g.chw_main_rt.get_parsed_text().length() > 60, "окно церкви пусто")
	var r0: float = float(g.ch["rel"])
	check(not g.chw_btn["meet"].disabled, "кнопка встречи с церковью недоступна")
	await reveal(g.chw_btn["meet"])
	await click(g.chw_btn["meet"])
	check(float(g.ch["rel"]) > r0, "щелчок «Встреча с главой церкви» не сработал")
	await click(g.sub4_buttons[2])
	for i in 4: await process_frame
	check(g.current_desk == 19, "вкладка «Культура» не открылась (desk %d)" % g.current_desk)
	check(g.cw_nat_rt.get_parsed_text().length() > 60, "таблица народов пуста")
	var f0: int = int(g.cu["pol"]["fund"])
	check(not g.cw_btn["fund+"].disabled, "кнопка поддержки культур недоступна")
	await reveal(g.cw_btn["fund+"])
	await click(g.cw_btn["fund+"])
	check(int(g.cu["pol"]["fund"]) == f0 + 1, "щелчок «Больше поддержки» культур не сработал")
	g.show_desk(1)
	for i in 4: await process_frame
	g.show_desk(5)
	for i in 6: await process_frame
	check(g.subbar2.visible and g.sub2_buttons.size() >= 3, "подпанель экономики без «Влияния и зависимости»")
	await click(g.sub2_buttons[2])
	for i in 4: await process_frame
	check(g.current_desk == 10, "вкладка «Влияние и зависимость» не открылась (desk %d)" % g.current_desk)
	check(g.xw_list_rt.get_parsed_text().length() > 60 and g.ex_sel != "", "список партнёров пуст")
	var c: String = g.ex_sel
	var d0: int = int(g.ex["p"][c]["deal"])
	g.fed_rel(c)
	g.dip_change(c, 10.0) if g.dip.has(c) else null
	await reveal(g.xw_btn["aid"])
	await click(g.xw_btn["aid"])
	check(float(g.ex["p"][c]["aid"]) > 0.0, "щелчок «Помощь» не сработал")
	g.on_ex_meta(g.ex_partners()[1])
	for i in 3: await process_frame
	check(g.ex_sel == g.ex_partners()[1], "выбор страны не сработал")
	g.show_desk(0)
	for i in 4: await process_frame
	check(g.current_desk == 0, "возврат на бюджет не удался")
	print("проблем %d" % bad)
	quit()
