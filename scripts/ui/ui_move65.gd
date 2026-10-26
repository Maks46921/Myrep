# 0.65: окна политических движений и верхней палаты (раздел «Политика»).
extends "res://scripts/ui/ui_flag.gd"

var mv_pick := ""
var mv_sum_rt: RichTextLabel = null
var mv_list_box: VBoxContainer = null
var mv_det_rt: RichTextLabel = null
var mv_act_box: VBoxContainer = null
var mv_act_btns := {}
var mv_gov_btns := {}
var mv_party_btn: Button = null
var mv_list_sig := ""


func build_move_windows() -> void:
	var w: FloatWindow = new_window("mv_list", "Политические движения", 12, Rect2(0.705, 0.0, 0.295, 0.46))
	mv_sum_rt = make_rt(w.body)
	mv_list_box = VBoxContainer.new()
	mv_list_box.add_theme_constant_override("separation", 4)
	w.body.add_child(mv_list_box)
	add_note(w.body, "Движение — не партия: мест в парламенте у него нет. Оно давит на власть улицей, подписями, забастовками и блогерами, подпитывает близкие партии, а когда вырастет — может зарегистрироваться как партия (часть радикалов тогда уйдёт). Режим отвечает по-разному: в демократии ничего, в гибридных странах аресты лидеров, в авторитарных запреты и репрессии.", true)
	w = new_window("mv_act", "Выбранное движение", 12, Rect2(0.705, 0.46, 0.295, 0.54))
	mv_det_rt = make_rt(w.body)
	mv_act_box = VBoxContainer.new()
	mv_act_box.add_theme_constant_override("separation", 4)
	w.body.add_child(mv_act_box)
	add_title(mv_act_box, "Действия движения")
	for a in MV_ACTS:
		var b := fed_btn("%s (капитал %.1f)" % [a["name"], a["cap"]], mv_act_box, String(a["desc"]))
		b.pressed.connect(on_mv_act.bind(String(a["id"])))
		mv_act_btns[String(a["id"])] = b
	mv_party_btn = fed_btn("Зарегистрировать партию (капитал %.0f)" % MV_PARTY_COST, mv_act_box, "Нужны: поддержка от %.0f%%, возраст движения от %d мес., организованность от %.0f, выбранный лидер, разрешение режима. Часть радикалов уйдёт в отдельное крыло." % [MV_PARTY_SUP, MV_PARTY_AGE, MV_PARTY_ORG])
	mv_party_btn.pressed.connect(on_mv_party)
	add_title(w.body, "Ответ власти")
	for a in MV_GOV_ACTS:
		var b2 := fed_btn("%s (капитал %.0f)" % [a["name"], a["cap"]], w.body, String(a["desc"]))
		b2.pressed.connect(on_mv_gov.bind(String(a["id"])))
		mv_gov_btns[String(a["id"])] = b2


func on_mv_act(id: String) -> void:
	if mv_pick != "":
		mv_act(mv_pick, id)
		refresh()


func on_mv_party() -> void:
	if mv_pick != "":
		mv_to_party(mv_pick)
		refresh()


func on_mv_gov(id: String) -> void:
	if mv_pick != "":
		mv_gov_do(mv_pick, id)
		refresh()


func mv_card_text(m: Dictionary) -> String:
	var st: String = mv_status_name(m)
	var mark := ""
	if mv_is_mine(m):
		mark = "★ "
	elif bool(m["pro"]):
		mark = "· "
	return "%s%s — %.1f%% · орг. %.0f · %s" % [mark, m["name"], float(m["sup"]), float(m["org"]), st]


func update_move_windows() -> void:
	if mv_sum_rt == null:
		return
	if not mv_on() or game_over:
		mv_sum_rt.text = loc("Движения отключены.")
		return
	mv_ensure()
	var list: Array = mv_list()
	var txt := mv_summary_text()
	if mv_player_mv():
		var me: Dictionary = mv_find(String(mv65["play"]))
		txt += "\n[b]Вы играете за движение[/b] «%s». %s" % [me.get("name", ""), ("Партия зарегистрирована." if bool(mv65.get("reg", false)) else "Вас нет в бюллетене, пока не зарегистрируете партию.")]
	mv_sum_rt.text = loc(txt)
	# список карточек пересобирается, только если изменились набор или подписи
	var sig := ""
	for m in list:
		sig += mv_card_text(m) + "|"
	sig += mv_pick
	if sig != mv_list_sig:
		mv_list_sig = sig
		for ch in mv_list_box.get_children():
			mv_list_box.remove_child(ch)
			ch.queue_free()
		if mv_pick == "" and not list.is_empty():
			mv_pick = String(list[0]["id"])
		var order: Array = list.duplicate()
		order.sort_custom(func(a, b) -> bool: return float(a["sup"]) > float(b["sup"]))
		for m in order:
			var b := Button.new()
			b.focus_mode = Control.FOCUS_NONE
			b.toggle_mode = true
			b.button_pressed = String(m["id"]) == mv_pick
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.clip_text = true
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.text = loc(mv_card_text(m))
			b.tooltip_text = loc(String(m["desc"]))
			var mid := String(m["id"])
			b.pressed.connect(func() -> void:
				mv_pick = mid
				mv_list_sig = ""
				refresh())
			mv_list_box.add_child(b)
	var cur: Dictionary = mv_find(mv_pick)
	mv_det_rt.text = loc(mv_detail_text(cur))
	var mine: bool = not cur.is_empty() and mv_is_mine(cur)
	mv_act_box.visible = mine
	for a in MV_ACTS:
		var id := String(a["id"])
		var bt: Button = mv_act_btns[id]
		var why: String = mv_can(cur, id) if mine else "нельзя"
		bt.disabled = why != ""
		bt.text = loc("%s (%s)%s" % [a["name"], ("капитал %.1f" % float(a["cap"])) if float(a["cap"]) > 0.0 else "даёт капитал", (" — " + why) if why != "" else ""])
	var why2: String = mv_party_can(cur) if mine else "нельзя"
	mv_party_btn.visible = mine and String(cur["st"]) != "party"
	mv_party_btn.disabled = why2 != ""
	mv_party_btn.text = loc("Зарегистрировать партию (капитал %.0f)%s" % [MV_PARTY_COST, (" — " + why2) if why2 != "" else ""])
	for a in MV_GOV_ACTS:
		var id2 := String(a["id"])
		var bg: Button = mv_gov_btns[id2]
		var wh: String = mv_gov_can(cur, id2) if not cur.is_empty() else "нельзя"
		bg.visible = not mv_player_mv()
		bg.disabled = wh != ""
		bg.text = loc("%s (капитал %.0f)%s" % [a["name"], a["cap"], (" — " + wh) if wh != "" else ""])
