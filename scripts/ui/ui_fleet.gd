# Экран «Флот» (desk 14): морская торговля, порты, военный флот, война на море.
# v37: возвращён из future/fleet; схема морских путей теперь рисуется прямо на большой карте (ui_war.gd).
extends "res://scripts/ui/ui_opp.gd"

var fw_info_rt: RichTextLabel = null
var fw_navy_rt: RichTextLabel = null
var fw_inc_rt: RichTextLabel = null
var fw_sea_rt: RichTextLabel = null
var fw_pbox: VBoxContainer = null
var fw_pkey := ""
var fw_btn: Dictionary = {}
var fw_btn_ports: Dictionary = {}
var fw_spk = null
var fw_station: OptionButton = null
var fw_station_ids: Array = []


func build_fleet_windows() -> void:
	var w: FloatWindow = new_window("fw_info", "Морская торговля и порты", 14, Rect2(0.0, 0.0, 0.22, 0.5))
	fw_info_rt = make_rt(w.body)
	var r0 := HBoxContainer.new()
	w.body.add_child(r0)
	fw_btn["m-"] = fed_btn("Торговый флот −", r0)
	fw_btn["m-"].pressed.connect(on_fleet_merch.bind(-1))
	fw_btn["m+"] = fed_btn("Торговый флот + (2)", r0, "Господдержка судоходных компаний под национальным флагом: меньше зависимость от чужих перевозчиков.")
	fw_btn["m+"].pressed.connect(on_fleet_merch.bind(1))
	fw_spk = Spark.new()
	w.body.add_child(fw_spk)

	w = new_window("fw_navy", "Военный флот", 14, Rect2(0.0, 0.5, 0.22, 0.5))
	fw_navy_rt = make_rt(w.body)
	for cl in FLEET.get("classes", []):
		var cid: String = String(cl["id"])
		fw_btn["o_" + cid] = fed_btn("Заказать: %s (2)" % String(cl["one"]), w.body, "%s\nСтоимость %.2f млрд €, срок %d сут., содержание %.2f млрд €/год." % [String(cl["desc"]), float(cl["cost"]), int(cl["days"]), float(cl["up"])])
		fw_btn["o_" + cid].pressed.connect(on_fleet_order.bind(cid))
	add_title(w.body, "Задача флота в мирное время")
	for ms in FLT_MISSIONS:
		var mid: String = String(ms["id"])
		fw_btn["s_" + mid] = fed_btn(String(ms["name"]), w.body, String(ms["desc"]))
		fw_btn["s_" + mid].toggle_mode = true
		fw_btn["s_" + mid].pressed.connect(on_fleet_mission.bind(mid))
	add_title(w.body, "Война на море")
	fw_sea_rt = make_rt(w.body)
	fw_station = fed_opt(w.body, [], "Где стоит основная эскадра. Во время войны она сражается с флотом противника в этом районе и блокирует его порты, если они здесь. Можно выбрать и щелчком по кружку района на карте.")
	fw_station.item_selected.connect(on_fleet_station)

	add_title(w.body, "Порты (загрузка, расширение)")
	fw_pbox = VBoxContainer.new()
	fw_pbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	w.body.add_child(fw_pbox)

	w = new_window("fw_inc", "Происшествия на море", 14, Rect2(0.505, 0.72, 0.2, 0.28))
	fw_inc_rt = make_rt(w.body)


func on_fleet_merch(d: int) -> void:
	fleet_merch(d)
	refresh()


func on_fleet_order(cid: String) -> void:
	fleet_order(cid)
	refresh()


func on_fleet_mission(mid: String) -> void:
	fleet_set_mission(mid)
	refresh()


func on_fleet_port(pid: String) -> void:
	fleet_port_invest(pid)
	refresh()


func on_fleet_station(i: int) -> void:
	if i >= 0 and i < fw_station_ids.size():
		mil_nav_station_set(String(fw_station_ids[i]))
	refresh()


func update_fleet_windows() -> void:
	if fw_info_rt == null or current_desk != 14:
		return
	if not flt_has_sea():
		fw_info_rt.text = "У этой страны нет морской торговли."
		return
	var land: bool = bool(flt["land"])
	var t := fleet_status_text() + "\n"
	if land:
		t += "[color=%s]Выхода к морю нет: товары идут через порты соседей, свой флот не нужен. Зависимость от чужих портов — ваш риск.[/color]\n" % COL_DIM
	t += "Потери от перекрытий за игру: [b]%.1f[/b] млрд € · инцидентов: [b]%d[/b]\n" % [float(flt["lost_bn"]), int(flt["inc_n"])]
	t += "Вклад в рост: [b]%+.2f[/b] п.п. · в инфляцию: [b]%+.2f[/b] п.п.\n" % [fleet_g(), fleet_infl()]
	t += "Торговый флот под своим флагом: [b]%d[/b]/4" % int(flt["merch"])
	fw_info_rt.text = t
	(fw_btn["m-"] as Button).disabled = int(flt["merch"]) <= 0
	(fw_btn["m+"] as Button).disabled = int(flt["merch"]) >= 4 or cap_spendable() < 2.0
	fw_spk.title = "Пропускная способность путей (по неделям)"
	fw_spk.series = [{"v": flt["hist_f"], "c": Color("#58c8c0"), "n": "пути"}, {"v": flt["hist_u"], "c": Color("#e8b84a"), "n": "порты"}]
	# флот
	var n := "Мощь флота: [b]%.0f[/b] (нужно для полной защиты ≈ %.0f) · защита торговли [b]%.0f%%[/b]\n" % [fleet_power(), float(flt["need"]), fleet_cover() * 100.0]
	for cl in FLEET["classes"]:
		var cid: String = String(cl["id"])
		var q := 0
		for it in flt["queue"]:
			if String(it["cls"]) == cid:
				q += 1
		n += "%s: [b]%d[/b]%s\n" % [String(cl["name"]), int(flt["navy"][cid]), (" (строится %d)" % q) if q > 0 else ""]
		(fw_btn["o_" + cid] as Button).disabled = (not fleet_can_build(cid)) or cap_spendable() < 2.0 or (flt["queue"] as Array).size() >= 8
		(fw_btn["o_" + cid] as Button).visible = not land
	fw_navy_rt.text = n
	for ms in FLT_MISSIONS:
		(fw_btn["s_" + String(ms["id"])] as Button).set_pressed_no_signal(String(flt["mission"]) == String(ms["id"]))
		(fw_btn["s_" + String(ms["id"])] as Button).visible = not land
	# война на море
	var st := String(mil.get("nav", {}).get("station", "")) if not mil.is_empty() else ""
	var s2 := ""
	if land:
		s2 = "Своего военного флота нет."
	else:
		s2 = "Эскадра: [b]%s[/b] · десантные корабли поднимут [b]%.0f[/b] тыс. человек.\n" % [String(flt_nodes[st]["name"]) if flt_nodes.has(st) else "в порту", mil_amp_cap()]
		if mil_at_war():
			var w: Dictionary = mil["war"]
			if (w["nv"] as Dictionary).is_empty():
				s2 += "У противника нет флота.\n"
			for c in w["nv"]:
				var e: Dictionary = w["nv"][c]
				s2 += "Флот «%s»: мощь [b]%.0f[/b] из %.0f, район «%s»\n" % [String(WORLD[c]["name"]), float(e["pow"]), float(e["pow0"]), String(flt_nodes[String(e["node"])]["name"]) if flt_nodes.has(String(e["node"])) else "—"]
			if bool(w["blk_e"]):
				s2 += "[color=%s]Порты противника блокированы.[/color]\n" % COL_GOOD
			if bool(w["blk_p"]):
				s2 += "[color=%s]Противник блокирует ваши порты: торговля несёт потери.[/color]\n" % COL_BAD
			s2 += "Морские бои: побед %d, поражений %d." % [int(w["nwon"]), int(w["nlost"])]
		else:
			s2 += "Войны нет. Во время войны эскадра сражается с флотом противника в выбранном районе и блокирует его порты, если они там."
	fw_sea_rt.text = s2
	fw_station.visible = not land
	if fw_station_ids.size() != flt_nodes.size():
		fw_station.clear()
		fw_station_ids.clear()
		for nid in flt_nodes:
			fw_station.add_item(String(flt_nodes[nid]["name"]))
			fw_station_ids.append(String(nid))
	var si: int = fw_station_ids.find(st)
	if si >= 0 and fw_station.selected != si:
		fw_station.select(si)
	# порты
	var ps: Array = fleet_ports_summary()
	var key := ""
	for p in ps:
		key += String(p["id"]) + ","
	if key != fw_pkey:
		fw_pkey = key
		for ch in fw_pbox.get_children():
			ch.queue_free()
		fw_btn_ports.clear()
		if ps.is_empty():
			add_note(fw_pbox, "Собственных портов нет.", true)
		for p in ps:
			var row := HBoxContainer.new()
			fw_pbox.add_child(row)
			var lb := Label.new()
			lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lb.clip_text = true
			lb.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			lb.custom_minimum_size = Vector2(40.0, 0.0)
			row.add_child(lb)
			fw_btn_ports[String(p["id"])] = [lb]
		# 0.56: порты расширяются в окне «Строительство»
		if not ps.is_empty():
			var ob := make_button("Расширить порты — окно «Строительство»", fw_pbox)
			ob.pressed.connect(bld_open)
	for p in ps:
		var pr: Array = fw_btn_ports.get(String(p["id"]), [])
		if pr.size() < 1:
			continue
		var stt := "строится, осталось %d сут." % int(p["build"]) if int(p["build"]) > 0 else ""
		(pr[0] as Label).text = "%.0f%% · %s %s" % [float(p["util"]) * 100.0, String(p["name"]), stt]
		(pr[0] as Label).tooltip_text = "Загрузка порта «%s»: %.0f%%" % [String(p["name"]), float(p["util"]) * 100.0]

	# происшествия
	var it := ""
	if (flt["inc"] as Dictionary).is_empty():
		it = "Сейчас море спокойно.\n"
	for nid in flt["inc"]:
		var d: Dictionary = flt["inc"][nid]
		it += "[color=%s]●[/color] %s: %s, осталось %d сут., потери ≈ %.0f%% трафика\n" % [COL_BAD, String(flt_nodes[nid]["name"]), String(d["kind"]), int(d["days"]), float(d["sev"]) * 100.0]
	var lg: Array = flt["log"]
	var from_i: int = maxi(0, lg.size() - 8)
	it += "\n[color=%s]Журнал:[/color]\n" % COL_DIM
	for k in range(lg.size() - 1, from_i - 1, -1):
		it += str(lg[k]) + "\n"
	fw_inc_rt.text = it
