# 0.65: окно «Верхняя палата» (раздел «Политика»): правила палаты, конфликт, требования, переговоры, назначения и реформа.
extends "res://scripts/ui/ui_move65.gd"

const UP_OP_IDS := ["create", "abolish", "powers", "form"]
const UP_PW_IDS := ["override", "consent", "full", "none"]
const UP_FORM_IDS := ["direct", "regional", "indirect", "mixed", "appointed", "corporate"]
const UP_SIZE_NAMES := ["малая (около 15% нижней палаты)", "средняя (около 30%)", "большая (около 50%)"]

var up_rt: RichTextLabel = null
var up_deal_btn: Button = null
var up_pack_btn: Button = null
var up_dem_yes: Button = null
var up_dem_no: Button = null
var up_op_opt: OptionButton = null
var up_pw_opt: OptionButton = null
var up_form_opt: OptionButton = null
var up_size_opt: OptionButton = null
var up_prev_rt: RichTextLabel = null
var up_do_btn: Button = null


func build_up_windows() -> void:
	var w: FloatWindow = new_window("up_house", "Верхняя палата", 1, Rect2(0.28, 0.0, 0.30, 1.0))
	up_rt = make_rt(w.body)
	add_title(w.body, "Отношения с палатой")
	up_deal_btn = fed_btn("Договориться с фракциями", w.body, "Переговоры снижают конфликт палат и на полгода делают фракции послушнее.")
	up_deal_btn.pressed.connect(func() -> void: up65_deal())
	up_pack_btn = fed_btn("Назначить сторонников", w.body, "Там, где власть назначает членов палаты (Лорды, Совет Республики, Совет Федерации): новые места для вашей партии, но рейтинг падает, а конфликт растёт.")
	up_pack_btn.pressed.connect(func() -> void: up65_pack())
	up_dem_yes = fed_btn("Выполнить требование палаты", w.body, "Платите политкапиталом: конфликт падает, регионы довольнее.")
	up_dem_yes.pressed.connect(func() -> void: up65_dem_answer(true))
	up_dem_no = fed_btn("Отказать палате", w.body, "Конфликт растёт, но капитал целее.")
	up_dem_no.pressed.connect(func() -> void: up65_dem_answer(false))
	add_title(w.body, "Конституционная реформа палаты")
	up_op_opt = fed_opt(w.body, UP65_OPS.values(), "Что изменить.")
	up_pw_opt = fed_opt(w.body, ["Отлагательное вето", "Согласие на законы о регионах", "Равноправная с нижней", "Почти без полномочий"], "Полномочия: для создания и для смены полномочий.")
	up_form_opt = fed_opt(w.body, ["Прямые выборы", "Делегаты регионов", "Косвенные выборы", "Смешанный порядок", "Назначение", "Представители профессий"], "Как формируется палата.")
	up_size_opt = fed_opt(w.body, UP_SIZE_NAMES, "Размер новой палаты.")
	for o in [up_op_opt, up_pw_opt, up_form_opt, up_size_opt]:
		(o as OptionButton).item_selected.connect(func(_i: int) -> void: refresh())
	up_prev_rt = make_rt(w.body)
	up_do_btn = fed_btn("Провести реформу", w.body, "Нужно конституционное большинство в нижней палате; согласие самой палаты и референдум (если он обязателен) решаются по шансу.")
	up_do_btn.pressed.connect(on_up_reform)
	add_note(w.body, "Кнопки действий: цена в политическом капитале указана на кнопке. Реформа возможна не чаще раза в год. Если палата не согласна — конфликт вырастет, а часть капитала пропадёт.", true)


func up_args() -> Array:
	return [UP_OP_IDS[up_op_opt.selected], UP_PW_IDS[up_pw_opt.selected], UP_FORM_IDS[up_form_opt.selected], up_size_opt.selected]


func on_up_reform() -> void:
	var a := up_args()
	up65_reform_do(String(a[0]), String(a[1]), String(a[2]), int(a[3]))


func update_up_window() -> void:
	if up_rt == null:
		return
	if not up65_on():
		up_rt.text = loc("Верхние палаты отключены.")
		return
	up65_ensure()
	up_rt.text = loc(up65_status_text())
	var exists := upper_on()
	var dw := up65_deal_why()
	up_deal_btn.visible = exists
	up_deal_btn.disabled = dw != ""
	up_deal_btn.text = loc("Договориться с фракциями (капитал %.0f)%s" % [up65_deal_cost(), (" — " + dw) if dw != "" else ""])
	var pw := up65_pack_why()
	up_pack_btn.visible = exists and bool(up65_meta().get("app", false))
	up_pack_btn.disabled = pw != ""
	up_pack_btn.text = loc("Назначить %d сторонников (капитал %.0f)%s" % [up65_pack_n() if exists else 0, 6.0 + float(up65_pack_n() if exists else 0) * 0.3, (" — " + pw) if pw != "" else ""])
	var dem: Dictionary = up65["dem"]
	up_dem_yes.visible = not dem.is_empty()
	up_dem_no.visible = not dem.is_empty()
	if not dem.is_empty():
		up_dem_yes.text = loc("Выполнить требование (капитал %.0f)" % float(dem["cost"]))
	var a := up_args()
	var op := String(a[0])
	up_pw_opt.visible = op == "create" or op == "powers"
	up_form_opt.visible = op == "create" or op == "form"
	up_size_opt.visible = op == "create"
	var info: Dictionary = up65_reform_info(op, String(a[1]), String(a[2]), int(a[3]))
	var t := ""
	if bool(info["ok"]):
		t = "Цена: [b]%.0f[/b] капитала. Конституционное большинство нижней палаты: нужно %.0f%%, у коалиции %.0f%%." % [info["cost"], float(info["need"]) * 100.0, float(info["have"]) * 100.0]
		if exists:
			t += " Шанс, что палата согласится: [b]%.0f%%[/b]." % (float(info["p_up"]) * 100.0)
		if bool(info["ref"]):
			t += " Нужен референдум, шанс успеха около [b]%.0f%%[/b]." % (float(info["p_ref"]) * 100.0)
	else:
		t = "[color=%s]%s.[/color]" % [COL_DIM, info["why"]]
	up_prev_rt.text = loc(t)
	up_do_btn.disabled = not bool(info["ok"]) or game_over
	up_do_btn.text = loc("Провести: %s" % String(UP65_OPS[op]).to_lower())
