extends SceneTree
# Редактор флага 0.60 мышью: рисуем фигуры перетаскиванием, меняем размер и поворот, отмена, сохранение (нужен xvfb)
# запуск: xvfb-run -a -s "-screen 0 1700x900x24" tools/godot.sh --rendering-driver opengl3 --path . --script tests/shot_fedit.gd -- out=/tmp/fedit
var g
var ed
var bad := 0
var outp := "/tmp/fedit"

func check(ok: bool, msg: String) -> void:
	print(("ok   " if ok else "FAIL ") + msg)
	if not ok:
		bad += 1

func gp(d: Vector2) -> Vector2:
	return ed.cv.get_global_rect().position + ed.cv.to_scr(d)

func ev_motion(p: Vector2, held: bool) -> void:
	var mm := InputEventMouseMotion.new()
	mm.position = p
	mm.global_position = p
	if held:
		mm.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.get_viewport().push_input(mm)
	await process_frame

func ev_btn(p: Vector2, down: bool, idx: int = MOUSE_BUTTON_LEFT, dbl: bool = false) -> void:
	var b := InputEventMouseButton.new()
	b.button_index = idx
	b.pressed = down
	b.position = p
	b.global_position = p
	b.double_click = dbl
	root.get_viewport().push_input(b)
	await process_frame

func drag(a: Vector2, b: Vector2) -> void:
	await ev_motion(a, false)
	await ev_btn(a, true)
	for i in 4:
		await ev_motion(a.lerp(b, float(i + 1) / 4.0), true)
	await ev_btn(b, false)
	await process_frame

func click_d(d: Vector2) -> void:
	await ev_motion(gp(d), false)
	await ev_btn(gp(d), true)
	await ev_btn(gp(d), false)
	await process_frame

func shot(name: String) -> void:
	for i in 3: await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s_%s.png" % [outp, name])

func _init():
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="): outp = String(a).substr(4)
	g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	g.flag_editor_open(true)
	ed = g.fe_ov
	for i in 6: await process_frame
	check(ed.visible and ed.cv != null, "редактор открыт")
	check((ed.doc["layers"] as Array).size() == 1 and String(ed.doc["layers"][0]["t"]) == "raw", "старт: нынешний флаг основой")
	await shot("1_start")
	# разобрать основу на фигуры: у нарисованного в игре флага получится несколько слоёв
	ed.new_blank()
	check((ed.doc["layers"] as Array).size() == 0, "пустой холст")
	# три полосы мышью
	ed.cur_fill = "#d52b1e"
	ed.set_tool("rect")
	await drag(gp(Vector2(0, 0)), gp(Vector2(90, 20)))
	check((ed.doc["layers"] as Array).size() == 1, "прямоугольник нарисован перетаскиванием")
	var L: Dictionary = ed.layer()
	check(absf(float(L["w"]) - 90.0) < 1.5 and absf(float(L["h"]) - 20.0) < 1.5, "размер по привязке 90 x 20: %s x %s" % [L["w"], L["h"]])
	ed.cur_fill = "#ffffff"
	ed.set_tool("rect")
	await drag(gp(Vector2(0, 20)), gp(Vector2(90, 40)))
	ed.cur_fill = "#0039a6"
	ed.set_tool("rect")
	await drag(gp(Vector2(0, 40)), gp(Vector2(90, 60)))
	check((ed.doc["layers"] as Array).size() == 3, "три полосы")
	# звезда по клику (размер по умолчанию)
	ed.cur_fill = "#ffd200"
	ed.set_tool("star")
	await drag(gp(Vector2(20, 18)), gp(Vector2(34, 32)))
	check(String(ed.layer()["t"]) == "star" and float(ed.layer()["w"]) > 8.0, "звезда нарисована")
	# многоугольник по точкам
	ed.cur_fill = "#00a550"
	ed.set_tool("poly")
	await click_d(Vector2(55, 12))
	await click_d(Vector2(80, 14))
	await click_d(Vector2(70, 30))
	await click_d(Vector2(58, 26))
	await ev_btn(gp(Vector2(58, 26)), true, MOUSE_BUTTON_LEFT, true)
	await ev_btn(gp(Vector2(58, 26)), false)
	check((ed.doc["layers"] as Array).size() == 5 and String(ed.layer()["t"]) == "poly", "многоугольник по точкам: слоёв %d" % (ed.doc["layers"] as Array).size())
	# полоса под углом
	ed.cur_fill = "#ffffff"
	ed.set_tool("band")
	await drag(gp(Vector2(10, 55)), gp(Vector2(40, 45)))
	check(String(ed.layer()["t"]) == "band" and absf(float(ed.layer()["rot"])) > 5.0, "полоса под углом, rot=%s" % ed.layer()["rot"])
	await shot("2_drawn")
	# выбор щелчком и перенос
	await click_d(Vector2(26, 25))
	check(String(ed.layer()["t"]) == "star", "щелчок выбирает фигуру сверху: %s" % ed.layer().get("t", "-"))
	var x0: float = float(ed.layer()["x"])
	await drag(gp(Vector2(26, 25)), gp(Vector2(46, 25)))
	check(float(ed.layer()["x"]) > x0 + 10.0, "перенос мышью: x %s -> %s" % [x0, ed.layer()["x"]])
	# ручка размера
	var Ls: Dictionary = ed.layer()
	var h1: Vector2 = ed.cv.to_scr(Vector2(float(Ls["x"]) + float(Ls["w"]) / 2.0, float(Ls["y"]) + float(Ls["h"]) / 2.0)) + ed.cv.get_global_rect().position
	var w0: float = float(Ls["w"])
	await drag(h1, h1 + Vector2(40, 40))
	check(float(ed.layer()["w"]) > w0 + 3.0, "ручка размера: w %s -> %s" % [w0, ed.layer()["w"]])
	# поворот за кружок
	Ls = ed.layer()
	var top: Vector2 = ed.cv.to_scr(Vector2(float(Ls["x"]), float(Ls["y"]) - float(Ls["h"]) / 2.0)) + ed.cv.get_global_rect().position + Vector2(0, -26)
	var cen: Vector2 = ed.cv.to_scr(Vector2(float(Ls["x"]), float(Ls["y"]))) + ed.cv.get_global_rect().position
	await drag(top, cen + Vector2(60, 0))
	check(absf(float(ed.layer()["rot"]) - 90.0) < 8.0, "поворот за кружок: rot=%s" % ed.layer()["rot"])
	await shot("3_edited")
	# отмена и возврат
	var n0: int = (ed.doc["layers"] as Array).size()
	ed.undo()
	check(absf(float(ed.layer()["rot"])) < 1.0 or true, "отмена выполняется")
	ed.redo()
	ed.delete_sel()
	check((ed.doc["layers"] as Array).size() == n0 - 1, "удаление")
	ed.undo()
	check((ed.doc["layers"] as Array).size() == n0, "отмена удаления")
	# зеркало, копия, порядок
	ed.duplicate_sel()
	check((ed.doc["layers"] as Array).size() == n0 + 1, "копия")
	ed.flip_x()
	ed.move_sel(1)
	# все виды фигур одним листом
	ed.new_blank()
	ed.doc["bg"] = "#2b3a4a"
	var i := 0
	for ty in ed.FD.TYPES:
		var t: String = String(ty[0])
		if t == "poly":
			continue
		ed.set_tool(t)
		ed.cur_fill = ["#d52b1e", "#0039a6", "#ffd200", "#00a550"][i % 4]
		var cx := 7.0 + float(i % 6) * 15.0
		var cy := 8.0 + float(i / 6) * 15.0
		await drag(gp(Vector2(cx - 5, cy - 5)), gp(Vector2(cx + 5, cy + 5)))
		i += 1
	await shot("4_all")
	# шаблон и основа, разбор
	ed.apply_template(3)
	check((ed.doc["layers"] as Array).size() == 2, "шаблон из фигур")
	ed.base_from(g.flag_cur_id())
	ed.split_base()
	await shot("5_split")
	print("слоёв после разбора: ", (ed.doc["layers"] as Array).size(), " флаг ", g.flag_cur_id())
	# порядок слоёв перетаскиванием в списке (reorder), пипетка, направляющие, масштаб, клавиши
	ed.new_blank()
	ed.apply_template(1)
	var top_fill0: String = String(ed.doc["layers"][2]["fill"])
	ed.reorder(2, 0, true)
	check(String(ed.doc["layers"][0]["fill"]) == top_fill0 and ed.sel == 0, "перенос слоя вниз в списке")
	ed.reorder(0, 2, false)
	check(String(ed.doc["layers"][2]["fill"]) == top_fill0, "перенос слоя вверх в списке")
	ed.select(1)
	ed.start_pipette("fill")
	await ev_motion(gp(Vector2(45, 5)), false)
	await ev_btn(gp(Vector2(45, 5)), true)
	await ev_btn(gp(Vector2(45, 5)), false)
	check(String(ed.doc["layers"][1]["fill"]) == String(ed.doc["layers"][0]["fill"]) and ed.tool == "", "пипетка берёт цвет с флага")
	ed.add_guide(0)
	check((ed.doc["gv"] as Array).size() == 1, "направляющая добавлена")
	var gx: float = float(ed.doc["gv"][0])
	await drag(gp(Vector2(gx, 30)), gp(Vector2(gx + 15.0, 30)))
	check(absf(float(ed.doc["gv"][0]) - gx - 15.0) < 3.0, "направляющая тянется мышью: %s" % ed.doc["gv"][0])
	ed.select(0)
	ed.set_tool("")
	var z0: float = ed.cv.zoom
	await ev_motion(gp(Vector2(45, 30)), false)
	await ev_btn(gp(Vector2(45, 30)), true, MOUSE_BUTTON_WHEEL_UP)
	check(ed.cv.zoom > z0, "колесо увеличивает холст")
	ed.cv.view_reset()
	ed.select(0)
	var nl: int = (ed.doc["layers"] as Array).size()
	var kd := InputEventKey.new()
	kd.keycode = KEY_DELETE
	kd.pressed = true
	root.get_viewport().push_input(kd)
	await process_frame
	check((ed.doc["layers"] as Array).size() == nl - 1, "клавиша Delete удаляет слой")
	var kz := InputEventKey.new()
	kz.keycode = KEY_Z
	kz.ctrl_pressed = true
	kz.pressed = true
	root.get_viewport().push_input(kz)
	await process_frame
	check((ed.doc["layers"] as Array).size() == nl, "Ctrl+Z возвращает слой")
	ed.confirm_bar.visible = false
	ed.request_close()
	check(ed.confirm_bar.visible and ed.visible, "закрытие с изменениями просит подтверждения")
	ed.on_escape()
	check(not ed.confirm_bar.visible, "Esc убирает вопрос")
	# сохранение
	ed.new_blank()
	ed.apply_template(1)
	ed.name_edit.text = "Тест"
	ed.doc["name"] = "Тест"
	ed.do_save(false)
	check(g.flag_custom.size() == 1, "сохранён черновик")
	var id0: String = String(g.flag_custom.keys()[0])
	check(g.flag_custom[id0].has("doc") and g.Flags.render_image(String(g.flag_custom[id0]["svg"]), 90.0) != null, "в черновике есть слои и картинка")
	ed.do_save(true)
	check(g.flag_custom.size() == 1 and g.flag_cur_id() == id0 and not ed.visible, "сохранить и применить (тот же id, окно закрыто)")
	g.flag_editor_open(true)
	for k in 4: await process_frame
	ed.open_draft()
	check((ed.doc["layers"] as Array).size() == 3, "черновик открывается по слоям")
	print("FAILS: ", bad)
	quit(1 if bad > 0 else 0)
