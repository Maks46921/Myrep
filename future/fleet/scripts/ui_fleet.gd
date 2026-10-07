extends "res://scripts/ui/ui_soc.gd"

# Экран «Флот и порты» (desk 12): морские пути, порты, флот, миссии.
const FleetMap := preload("res://scripts/classes/fleet_map.gd")
var fw_map = null
var fw_info_rt: RichTextLabel = null
var fw_navy_rt: RichTextLabel = null
var fw_inc_rt: RichTextLabel = null
var fw_pbox: VBoxContainer = null
var fw_pkey := ""
var fw_btn: Dictionary = {}
var fw_spk = null


func build_fleet_windows() -> void:
	var w: FloatWindow = new_window("fw_map", "Морские пути и порты", 12, Rect2(0.0, 0.0, 0.50, 0.62))
	fw_map = FleetMap.new()
	w.body.add_child(fw_map)
	add_note(w.body, "Линии — морские пути (толще — больше торговли, красные — перекрыты). Квадраты — порты вашей страны: зелёный — запас мощности, жёлтый — почти полная загрузка, красный — перегруз. Схема приблизительная.", true)

	w = new_window("fw_info", "Морская торговля", 12, Rect2(0.50, 0.0, 0.50, 0.30))
	fw_info_rt = make_rt(w.body)
	var r0 := HBoxContainer.new()
	w.body.add_child(r0)
	fw_btn["m-"] = fed_btn("Торговый флот −", r0)
	fw_btn["m-"].pressed.connect(on_fleet_merch.bind(-1))
	fw_btn["m+"] = fed_btn("Торговый флот + (2)", r0, "Господдержка судоходных компаний под национальным флагом: меньше зависимость от чужих перевозчиков.")
	fw_btn["m+"].pressed.connect(on_fleet_merch.bind(1))

	w = new_window("fw_navy", "Военный флот", 12, Rect2(0.50, 0.30, 0.50, 0.42))
	fw_navy_rt = make_rt(w.body)
	for cl in FLEET.get("classes", []):
		var cid: String = String(cl["id"])
		fw_btn["o_" + cid] = fed_btn("Заказать: %s (2)" % String(cl["one"]), w.body, "%s\nСтоимость %.2f млрд €, срок %d сут., содержание %.2f млрд €/год." % [String(cl["desc"]), float(cl["cost"]), int(cl["days"]), float(cl["up"])])
		fw_btn["o_" + cid].pressed.connect(on_fleet_order.bind(cid))
	var mh := Label.new()
	mh.text = "Задача флота:"
	w.body.add_child(mh)
	for ms in FLT_MISSIONS:
		var mid: String = String(ms["id"])
		fw_btn["s_" + mid] = fed_btn(String(ms["name"]), w.body, String(ms["desc"]))
		fw_btn["s_" + mid].toggle_mode = true
		fw_btn["s_" + mid].pressed.connect(on_fleet_mission.bind(mid))

	w = new_window("fw_ports", "Порты", 12, Rect2(0.0, 0.62, 0.50, 0.38))
	fw_pbox = VBoxContainer.new()
	fw_pbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	w.body.add_child(fw_pbox)

	w = new_window("fw_inc", "Происшествия на море", 12, Rect2(0.50, 0.72, 0.50, 0.28))
	fw_inc_rt = make_rt(w.body)
	fw_spk = Spark.new()
	w.body.add_child(fw_spk)


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


func update_fleet_windows() -> void:
	if fw_info_rt == null or current_desk != 12:
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
	(fw_btn["m+"] as Button).disabled = int(flt["merch"]) >= 4 or capital < 2.0
	# флот
	var n := "Мощь флота: [b]%.0f[/b] (нужно для полной защиты ≈ %.0f) · защита торговли [b]%.0f%%[/b]\n" % [fleet_power(), float(flt["need"]), fleet_cover() * 100.0]
	for cl in FLEET["classes"]:
		var cid: String = String(cl["id"])
		var q := 0
		for it in flt["queue"]:
			if String(it["cls"]) == cid:
				q += 1
		n += "%s: [b]%d[/b]%s\n" % [String(cl["name"]), int(flt["navy"][cid]), (" (строится %d)" % q) if q > 0 else ""]
		(fw_btn["o_" + cid] as Button).disabled = (not fleet_can_build(cid)) or capital < 2.0 or (flt["queue"] as Array).size() >= 8
	fw_navy_rt.text = n
	for ms in FLT_MISSIONS:
		(fw_btn["s_" + String(ms["id"])] as Button).set_pressed_no_signal(String(flt["mission"]) == String(ms["id"]))
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
			row.add_child(lb)
			var b := make_button("Расширить", row)
			b.tooltip_text = "Расширение на 12 месяцев: пропускная способность порта +12%, стоит долга и 2 капитала."
			b.pressed.connect(on_fleet_port.bind(String(p["id"])))
			fw_btn_ports[String(p["id"])] = [lb, b]
	for p in ps:
		var pr: Array = fw_btn_ports.get(String(p["id"]), [])
		if pr.size() < 2:
			continue
		var st := "строится, осталось %d сут." % int(p["build"]) if int(p["build"]) > 0 else ""
		(pr[0] as Label).text = "загрузка %.0f%% · %s %s" % [float(p["util"]) * 100.0, String(p["name"]), st]
		(pr[1] as Button).text = "Расширить (%.1f)" % fleet_port_cost(String(p["id"]))
		(pr[1] as Button).disabled = int(p["build"]) > 0 or capital < 2.0
	# происшествия
	var it := ""
	if (flt["inc"] as Dictionary).is_empty():
		it = "Сейчас море спокойно.\n"
	for nid in flt["inc"]:
		var d: Dictionary = flt["inc"][nid]
		it += "[color=%s]●[/color] %s: %s, осталось %d сут., потери ≈ %.0f%% трафика\n" % [COL_BAD, String(flt_nodes[nid]["name"]), String(d["kind"]), int(d["days"]), float(d["sev"]) * 100.0]
	var lg: Array = flt["log"]
	var from_i: int = maxi(0, lg.size() - 6)
	it += "\n[color=%s]Журнал:[/color]\n" % COL_DIM
	for k in range(lg.size() - 1, from_i - 1, -1):
		it += str(lg[k]) + "\n"
	fw_inc_rt.text = it
	fw_spk.title = "Пропускная способность путей (по неделям)"
	fw_spk.series = [{"v": flt["hist_f"], "c": Color("#58c8c0"), "n": "пути"}, {"v": flt["hist_u"], "c": Color("#e8b84a"), "n": "порты"}]
	# схема
	var nd: Array = []
	for nid2 in flt_nodes:
		nd.append([Vector2(float(flt_nodes[nid2]["x"]), float(flt_nodes[nid2]["y"])), String(flt_nodes[nid2]["name"]), flt["inc"].has(nid2)])
	var pl: Array = []
	for p in ps:
		var pp: Dictionary = flt_port(String(p["id"]))
		pl.append([Vector2(float(pp["x"]), float(pp["y"])), String(p["name"]), float(p["util"]), int(p["build"]) > 0])
	(fw_map as Control).call("set_data", fleet_lane_edges(), nd, pl)


var fw_btn_ports: Dictionary = {}
