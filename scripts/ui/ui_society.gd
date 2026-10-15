# v55_1: рамка «Общество»: вкладки «Религия и миграция» (11), «Церковь и государство» (20), «Культура» (19);
# окна «Все товары» и «Промышленность и цепочки» на вкладке «Экономика → Товары и цены» (7).
extends "res://scripts/ui/ui_soc.gd"

const CultChart := preload("res://scripts/classes/cult_chart.gd")

var cw_nat_rt: RichTextLabel
var cw_nat_chart: Control
var cw_pol_rt: RichTextLabel
var cw_reg_chart: Control
var cw_reg_rt: RichTextLabel
var cw_kin_rt: RichTextLabel
var cw_spk: Control
var cw_btn := {}
var chw_main_rt: RichTextLabel
var chw_law_rt: RichTextLabel
var chw_reg_rt: RichTextLabel
var chw_spk: Control
var chw_btn := {}
var gdw_all_rt: RichTextLabel
var gdw_ind_rt: RichTextLabel


func build_society_windows() -> void:
	# ---- «Культура» (19) ----
	var w: FloatWindow = new_window("cu_nat", "Народы страны", 19, Rect2(0.0, 0.0, 0.36, 0.54))
	cw_nat_chart = CultChart.new()
	w.body.add_child(cw_nat_chart)
	cw_nat_rt = make_rt(w.body)
	add_note(w.body, "Народы объединены в группы (германские, славянские, тюркские…). Государствообразующие народы не ассимилируются; исторические нации (защищённые) — тоже, если курс не «ассимиляция». Остальные меньшинства со временем переходят к большинству региона — тем быстрее, чем жёстче политика. Данные ориентировочные, по переписям 2020-х годов.", true)

	w = new_window("cu_pol", "Культурная политика", 19, Rect2(0.36, 0.0, 0.345, 0.54))
	cw_pol_rt = make_rt(w.body)
	for k in ["lang", "school", "auto", "course", "fund"]:
		var hb := HBoxContainer.new()
		w.body.add_child(hb)
		cw_btn[k + "-"] = fed_btn(["Строже: язык", "Строже: школы", "Меньше автономии", "Курс — к ассимиляции", "Меньше поддержки"][["lang", "school", "auto", "course", "fund"].find(k)], hb,
			"Жёстче к меньшинствам: радует силовиков, село и пенсионеров, но растёт обида меньшинств и портятся отношения с их родными странами.")
		cw_btn[k + "-"].pressed.connect(func() -> void: cu_set_pol(k, -1))
		cw_btn[k + "+"] = fed_btn(["Мягче: язык", "Мягче: школы", "Больше автономии", "Курс — к мультикультурализму", "Больше поддержки"][["lang", "school", "auto", "course", "fund"].find(k)], hb,
			"Мягче к меньшинствам: снижает напряжённость и улучшает отношения с соседями, но злит силовиков и консервативных избирателей.")
		cw_btn[k + "+"].pressed.connect(func() -> void: cu_set_pol(k, 1))
	cw_btn["dialog"] = fed_btn("Круглый стол с общинами (5)", w.body, "Снижает напряжённость во всех регионах и обиду меньшинств.")
	cw_btn["dialog"].pressed.connect(func() -> void: cu_dialog())
	cw_spk = Spark.new()
	w.body.add_child(cw_spk)

	w = new_window("cu_reg", "Регионы: народы и напряжённость", 19, Rect2(0.0, 0.54, 0.36, 0.46))
	cw_btn["rauto"] = fed_btn("Культурная автономия выбранному региону (7)", w.body, "Регион с крупным меньшинством получает свои советы, школы и бюджет на культуру: напряжённость падает, автономия растёт.")
	cw_btn["rauto"].pressed.connect(func() -> void: cu_region_autonomy(selected_region))
	cw_reg_rt = make_rt(w.body)
	cw_reg_chart = CultChart.new()
	w.body.add_child(cw_reg_chart)

	w = new_window("cu_kin", "Соседи, родные страны и диаспоры", 19, Rect2(0.36, 0.54, 0.345, 0.46))
	var hb2 := HBoxContainer.new()
	w.body.add_child(hb2)
	cw_btn["dia-"] = fed_btn("Меньше поддержки соотечественников", hb2)
	cw_btn["dia-"].pressed.connect(func() -> void: cu_set_dia(-1))
	cw_btn["dia+"] = fed_btn("Больше поддержки (6)", hb2, "Фонды, школы, паспорта для своего народа за рубежом: радует пенсионеров и силовиков, но раздражает соседей.")
	cw_btn["dia+"].pressed.connect(func() -> void: cu_set_dia(1))
	cw_kin_rt = make_rt(w.body)
	cw_kin_rt.meta_clicked.connect(on_cult_meta)

	# ---- «Церковь и государство» (20) ----
	w = new_window("ch_main", "Главная церковь", 20, Rect2(0.0, 0.0, 0.36, 0.56))
	chw_main_rt = make_rt(w.body)
	var r1 := HBoxContainer.new()
	w.body.add_child(r1)
	chw_btn["st_main"] = fed_btn("Сделать веру церкви государственной (12)", r1, "Церковь и верующие довольны, иноверцы и неверующие — нет; молодёжь против.")
	chw_btn["st_main"].pressed.connect(func() -> void: ch_set_state(int(ch.get("faith", 0))))
	chw_btn["st_sec"] = fed_btn("Светское государство (12)", r1, "Отделение церкви от государства: радует молодёжь, злит верующих.")
	chw_btn["st_sec"].pressed.connect(func() -> void: ch_set_state(-1))
	var r2 := HBoxContainer.new()
	w.body.add_child(r2)
	for v in 3:
		chw_btn["fin%d" % v] = fed_btn(["Сама (6)", "Церковный налог (6)", "Из бюджета (6)"][v], r2,
			["Церковь живёт на пожертвования: дешевле для бюджета, церковь недовольна.", "Верующие платят налог через государство: бюджет не тратит, бизнес ворчит.", "Зарплаты и храмы — из бюджета: дорого (около 0,06% ВВП в год), но церковь благодарна."][v])
		chw_btn["fin%d" % v].pressed.connect(func() -> void: ch_set_fin(v))
	var r3 := HBoxContainer.new()
	w.body.add_child(r3)
	chw_btn["meet"] = fed_btn("Встреча с главой церкви (4)", r3)
	chw_btn["meet"].pressed.connect(func() -> void: ch_meet())
	chw_btn["crit"] = fed_btn("Публично раскритиковать", r3, "Отношения с церковью и её влияние падают; молодёжь довольна, верующие — нет.")
	chw_btn["crit"].pressed.connect(func() -> void: ch_criticize())
	var r4 := HBoxContainer.new()
	w.body.add_child(r4)
	chw_btn["riv+"] = fed_btn("Поддержать вторую церковь (8)", r4)
	chw_btn["riv+"].pressed.connect(func() -> void: ch_rival(1))
	chw_btn["riv-"] = fed_btn("Ограничить вторую церковь (8)", r4)
	chw_btn["riv-"].pressed.connect(func() -> void: ch_rival(-1))
	chw_spk = Spark.new()
	w.body.add_child(chw_spk)

	w = new_window("ch_laws", "Церковь и законы", 20, Rect2(0.36, 0.0, 0.345, 0.56))
	chw_law_rt = make_rt(w.body)
	add_note(w.body, "Церковь следит за «моральными» законами: о семье и браке, абортах, религии в школах, воскресной торговле. Позиция церкви — тот вариант, который больше нравится верующим (пенсионерам и селу) и меньше — молодёжи. Чем дальше законы от её позиции, тем хуже отношения; влиятельная церковь в ссоре с властью уводит голоса верующих у правящей партии и может вывести людей на улицы.", true)

	w = new_window("ch_reg", "Религиозность регионов", 20, Rect2(0.0, 0.56, 0.36, 0.44))
	chw_reg_rt = make_rt(w.body)
	var sp: FloatWindow = wins["sw_pol"]
	sp.desk = 20
	sp.frac = Rect2(0.36, 0.56, 0.345, 0.44)
	sp.default_frac = sp.frac
	if wins.has("sw_reg"):
		var sr: FloatWindow = wins["sw_reg"]
		sr.frac = Rect2(0.36, 0.0, 0.34, 0.78)
		sr.default_frac = sr.frac

	# ---- товары: все 64 и промышленность (7) ----
	w = new_window("gd_all", "Все товары: подробно", 7, Rect2(0.0, 0.58, 0.37, 0.42))
	gdw_all_rt = make_rt(w.body)
	w = new_window("gd_ind", "Промышленность, цепочки и санкции", 7, Rect2(0.37, 0.58, 0.335, 0.42))
	gdw_ind_rt = make_rt(w.body)
	# v55_3: «Все товары» и «Промышленность» лежали под «Энергией» и «Историей показателей».
	# «Товары и цены» (7): цены, корзины, что двигает, все товары, история; «Промышленная политика» (16):
	# пульт, энергия (создаётся в ui_realm), панель показателей, промышленность и цепочки, как устроена модель
	var lay := {"gd_list": [7, Rect2(0.0, 0.0, 0.30, 0.5)], "gd_groups": [7, Rect2(0.30, 0.0, 0.405, 0.2)], "gd_drv": [7, Rect2(0.30, 0.2, 0.405, 0.3)],
		"gd_all": [7, Rect2(0.0, 0.5, 0.35, 0.5)], "es_main": [16, Rect2(0.0, 0.0, 0.30, 0.42)], "es_dash": [16, Rect2(0.30, 0.0, 0.405, 0.36)],
		"gd_ind": [16, Rect2(0.30, 0.36, 0.405, 0.40)], "es_info": [16, Rect2(0.30, 0.76, 0.405, 0.24)]}
	for wid in lay:
		if wins.has(wid):
			var gw: FloatWindow = wins[wid]
			gw.desk = int(lay[wid][0])
			gw.frac = lay[wid][1]
			gw.default_frac = gw.frac


func on_cult_meta(meta: Variant) -> void:
	var s := String(meta)
	if s.begins_with("cdip:"):
		cu_diplomacy(s.substr(5))


func update_society_windows() -> void:
	if current_desk == 19:
		update_cult_desk()
	elif current_desk == 20:
		update_church_desk()
		if not soc.is_empty():
			update_soc_desk()


func cu_status(cid: String) -> String:
	if cu_is_tit(cid):
		return "государствообразующий"
	if cu_is_prot(cid):
		return "историческая нация"
	if cu_is_mig(cid):
		return "мигранты"
	if cid == "oth":
		return "—"
	return "меньшинство"


func cu_segs(v: Dictionary, legend_ids: Array) -> Array:
	var segs: Array = []
	var other := 0.0
	for it in cu_sorted(v):
		if String(it[0]) in legend_ids:
			segs.append([float(it[1]), cu_col(String(it[0]))])
		else:
			other += float(it[1])
	if other > 0.0:
		segs.append([other, Color(0.45, 0.47, 0.53)])
	return segs


func update_cult_desk() -> void:
	if cw_nat_rt == null or not cu_on():
		return
	var nat := cu_national()
	var nat0 := cu_national0()
	var top: Array = []
	var lg: Array = []
	for it in cu_sorted(nat):
		if top.size() >= 8:
			break
		if String(it[0]) == "oth":
			continue
		top.append(String(it[0]))
		lg.append([cu_name(String(it[0])), cu_col(String(it[0]))])
	(cw_nat_chart as CultChart).set_rows([["Сейчас", cu_segs(nat, top), -1.0], ["На старте", cu_segs(nat0, top), -1.0]], lg)
	var t := "[table=5][cell][color=%s]Народ[/color][/cell][cell][color=%s] Группа[/color][/cell][cell][color=%s] Доля[/color][/cell][cell][color=%s] С начала[/color][/cell][cell][color=%s] Положение[/color][/cell]" % [COL_DIM, COL_DIM, COL_DIM, COL_DIM, COL_DIM]
	var n := 0
	for it in cu_sorted(nat):
		var cid := String(it[0])
		var s: float = float(it[1])
		if s < 0.002 or n >= 16:
			continue
		n += 1
		var d: float = (s - float(nat0.get(cid, 0.0))) * 100.0
		var st := cu_status(cid)
		var g: float = cu_griev(cid) if not cu_is_tit(cid) and cid != "oth" else 0.0
		if g > 0.0:
			st += " · обида [color=%s]%.0f[/color]" % [COL_BAD if g > 0.4 else (COL_WARN if g > 0.2 else COL_DIM), g * 100.0]
		t += "[cell][color=%s]■[/color] %s[/cell][cell] %s[/cell][cell] %.1f%%[/cell][cell][color=%s] %s[/color][/cell][cell] %s[/cell]" % [
			cu_col(cid).to_html(false), cu_name(cid), cu_grp_name(cu_grp(cid)), s * 100.0, COL_GOOD if d > 0.05 else (COL_BAD if d < -0.05 else COL_DIM), sg(d, 2), st]
	t += "[/table]\nАссимилировалось с начала игры: [b]%.0f тыс.[/b] человек." % (float(cu["assim"]) / 1000.0)
	cw_nat_rt.text = t
	# политика
	var p: Dictionary = cu["pol"]
	var pt := "[b]Нынешняя политика[/b]\n"
	pt += "• Язык: [b]%s[/b]\n• Школы: [b]%s[/b]\n• Органы меньшинств: [b]%s[/b]\n• Курс: [b]%s[/b]\n• Поддержка культур: [b]%s[/b]\n" % [
		CU_LANG[int(p["lang"])], CU_SCHOOL[int(p["school"])], CU_AUTO[int(p["auto"])], CU_COURSE[int(p["course"])], CU_FUND[int(p["fund"])]]
	pt += "Напряжённость по стране: [b][color=%s]%.0f[/color][/b]/100 (на старте %.0f). %s\n" % [COL_BAD if float(cu["tension"]) > float(cu["tension0"]) + 5.0 else COL_DIM, float(cu["tension"]), float(cu["tension0"]), cu_effect_text()]
	pt += "[color=%s]Каждое изменение стоит политкапитала (язык 8, школы 7, автономия 8, курс 9, поддержка 5) и ждёт 9 месяцев. Меньшинства в стране: %.1f%%.[/color]" % [COL_DIM, (1.0 - cu_tit_share()) * 100.0]
	cw_pol_rt.text = pt
	for k in ["lang", "school", "auto", "course", "fund"]:
		var cdk: bool = cu_cd_get(k) > 0
		(cw_btn[k + "-"] as Button).disabled = cdk or int(p[k]) <= 0 or opp_mode
		(cw_btn[k + "+"] as Button).disabled = cdk or int(p[k]) >= int(CU_POL_MAX[k]) or opp_mode
	(cw_btn["dialog"] as Button).disabled = cu_cd_get("dialog") > 0 or opp_mode
	var hh: Dictionary = cu["h"]
	cw_spk.title = "Культурная напряжённость и доля меньшинств (%) по месяцам"
	var ms: Array = []
	for x in hh["m"]:
		ms.append(float(x) * 100.0)
	cw_spk.series = [{"v": hh["t"], "c": Color("#f0707a"), "n": "напр."}, {"v": ms, "c": Color("#6fa8dc"), "n": "меньш."}]
	cw_spk.ymin = 0.0
	cw_spk.ymax = 100.0
	cw_spk.queue_redraw()
	# регионы
	var rows: Array = []
	var ord: Array = []
	for i in regions.size():
		ord.append(i)
	ord.sort_custom(func(a, b): return float(regions[a].get("cut", 0.0)) > float(regions[b].get("cut", 0.0)))
	for i in ord:
		if not regions[i].has("cul"):
			continue
		rows.append([String(REGIONS[i]["name"]), cu_segs(regions[i]["cul"], top), float(regions[i]["cut"])])
	(cw_reg_chart as CultChart).set_rows(rows, [])
	var si := selected_region
	var rt := ""
	if si >= 0 and si < regions.size() and regions[si].has("cul"):
		var parts: PackedStringArray = []
		for it in cu_sorted(regions[si]["cul"]):
			if parts.size() >= 4 or float(it[1]) < 0.01:
				break
			parts.append("%s %.0f%%" % [cu_name(String(it[0])), float(it[1]) * 100.0])
		rt = "Выбран регион «%s»: %s. Напряжённость %.0f (на старте %.0f)." % [REGIONS[si]["name"], ", ".join(parts), float(regions[si]["cut"]), float(regions[si]["cut0"])]
	else:
		rt = "Выберите регион на карте, чтобы дать ему культурную автономию."
	cw_reg_rt.text = "[font_size=13]%s[/font_size]\n[color=%s]Столбцы — народы региона, кружок — культурная напряжённость (её рост выше стартовой снижает лояльность, растит недовольство и сепаратизм).[/color]" % [rt, COL_DIM]
	(cw_btn["rauto"] as Button).disabled = opp_mode or si < 0 or si >= regions.size() or cu_minority_share(si) < 0.08 or cu_cd_get("rauto_%d" % si) > 0
	# соседи и диаспоры
	var kt := "[b]Меньшинства, у которых есть родная страна[/b]\n"
	var kl := cu_kin_list()
	if kl.is_empty():
		kt += "[color=%s]Крупных меньшинств из соседних стран нет.[/color]\n" % COL_DIM
	for it in kl:
		if kl.find(it) >= 8:
			break
		var e: Dictionary = (cu["kin"] as Dictionary).get(it[1], {})
		var ag: float = float(e.get("agit", 0.0))
		kt += "• %s — %.1f%%, родина: %s, отношения %.0f%s\n" % [cu_name(String(it[0])), float(it[2]) * 100.0, String(WORLD[it[1]]["name"]) if WORLD.has(it[1]) else String(it[1]), fed_rel(String(it[1])),
			(" · [color=%s]агитация %.0f[/color]" % [COL_BAD, ag]) if ag > 5.0 else ""]
	var dl := cu_diaspora()
	kt += "\n[b]Наши соотечественники за рубежом[/b] (поддержка: %s)\n" % ["нет", "культура и образование", "активная"][int((cu["dia"] as Dictionary).get("lvl", 0))]
	if dl.is_empty():
		kt += "[color=%s]Заметных общин нашего народа в соседних странах нет.[/color]\n" % COL_DIM
	for it in dl:
		if dl.find(it) >= 6:
			break
		kt += "• %s — %.1f%% населения\n" % [String(WORLD[it[0]]["name"]) if WORLD.has(it[0]) else String(it[0]), float(it[1]) * 100.0]
	kt += "\n[b]Культурная дипломатия[/b] (капитал 4): близкие по культуре страны отзываются сильнее\n"
	var cl: Array = []
	for c in wsim:
		if c != ccode:
			cl.append([String(c), cu_country_prox(String(c)), fed_rel(String(c))])
	cl.sort_custom(func(a, b): return float(a[1]) * 100.0 + float(a[2]) * 0.1 > float(b[1]) * 100.0 + float(b[2]) * 0.1)
	var links: PackedStringArray = []
	for it in cl:
		if links.size() >= 8:
			break
		var cd2: bool = cu_cd_get("cdip_" + String(it[0])) > 0
		var nm: String = String(WORLD[it[0]]["name"]) if WORLD.has(it[0]) else String(it[0])
		links.append(("[color=%s]%s[/color]" % [COL_DIM, nm]) if cd2 else ("[url=cdip:%s]%s[/url] (%.0f%%)" % [it[0], nm, float(it[1]) * 100.0]))
	kt += " · ".join(links)
	cw_kin_rt.text = kt
	var lv: int = int((cu["dia"] as Dictionary).get("lvl", 0))
	(cw_btn["dia-"] as Button).disabled = opp_mode or lv <= 0 or cu_cd_get("dia") > 0
	(cw_btn["dia+"] as Button).disabled = opp_mode or lv >= 2 or cu_cd_get("dia") > 0 or dl.is_empty()


func update_church_desk() -> void:
	if chw_main_rt == null:
		return
	if not ch_on():
		chw_main_rt.text = "[color=%s]Данных о церкви нет.[/color]" % COL_DIM
		return
	var f: int = int(ch["faith"])
	var nat := soc_national()
	var t := "[b]%s[/b]\nВера: %s — %.0f%% населения\n" % [String(ch["name"]), ch_faith_name(f).to_lower(), float(nat[f]) * 100.0]
	t += "Статус: [b]%s[/b] · финансирование: [b]%s[/b]\n" % [ch_state_name(), CH_FIN[int(ch["fin"])]]
	t += "Влияние церкви: [b]%.0f[/b]/100 (на старте %.0f) · религиозность: [b]%.0f[/b]/100 (на старте %.0f)\n" % [float(ch["pow"]), float(ch["pow0"]), ch_nat_piety(), float(ch["pie0"])]
	var rc: String = COL_GOOD if ch_drel() > 3.0 else (COL_BAD if ch_drel() < -3.0 else COL_DIM)
	t += "Отношения с властью: [b][color=%s]%.0f[/color][/b]/100 (на старте %.0f)\n" % [rc, float(ch["rel"]), float(ch["rel0"])]
	var rv_d: Dictionary = ch["riv"]
	if not rv_d.is_empty():
		t += "Вторая церковь той же веры: [b]%s[/b] — %.0f%% верующих, напряжённость между церквями %.0f\n" % [String(rv_d["name"]), float(rv_d["share"]) * 100.0, float(rv_d["ten"])]
	if float(ch["conv"]) > 1000.0:
		t += "Обратились в государственную веру: %.0f тыс.\n" % (float(ch["conv"]) / 1000.0)
	t += ch_effect_text()
	var fc := ch_fin_cost_now()
	if absf(fc) > 0.01:
		t += "\nРасходы на церковь сверх стартовых: %s млрд в год." % sg(fc, 2)
	chw_main_rt.text = t
	var st: int = int(ch["state"])
	(chw_btn["st_main"] as Button).disabled = opp_mode or st == f or ch_cd_get("state") > 0
	(chw_btn["st_sec"] as Button).disabled = opp_mode or st < 0 or ch_cd_get("state") > 0
	for v in 3:
		(chw_btn["fin%d" % v] as Button).disabled = opp_mode or int(ch["fin"]) == v or ch_cd_get("fin") > 0
	(chw_btn["meet"] as Button).disabled = opp_mode or ch_cd_get("meet") > 0
	(chw_btn["crit"] as Button).disabled = opp_mode or ch_cd_get("crit") > 0
	(chw_btn["riv+"] as Button).visible = not rv_d.is_empty()
	(chw_btn["riv-"] as Button).visible = not rv_d.is_empty()
	(chw_btn["riv+"] as Button).disabled = opp_mode or ch_cd_get("riv") > 0
	(chw_btn["riv-"] as Button).disabled = opp_mode or ch_cd_get("riv") > 0
	var hh: Dictionary = ch["h"]
	chw_spk.title = "Влияние церкви, отношения с властью и религиозность по месяцам"
	chw_spk.series = [{"v": hh["p"], "c": Color("#e0b050"), "n": "влияние"}, {"v": hh["r"], "c": Color("#58c887"), "n": "отношения"}, {"v": hh["pi"], "c": Color("#c27ba0"), "n": "религ."}]
	chw_spk.ymin = 0.0
	chw_spk.ymax = 100.0
	chw_spk.queue_redraw()
	# законы
	var lt := ""
	var laws := ch_laws()
	if laws.is_empty():
		lt = "[color=%s]В вашей стране нет законов, которые церковь считает своими.[/color]" % COL_DIM
	else:
		lt = "[table=3][cell][color=%s]Закон[/color][/cell][cell][color=%s] Сейчас[/color][/cell][cell][color=%s] Чего хочет церковь[/color][/cell]" % [COL_DIM, COL_DIM, COL_DIM]
		for it in laws:
			var tid: String = it[0]
			var cur := cur_idx(tid)
			var ok: bool = int(it[1]) == cur
			lt += "[cell]%s[/cell][cell] %s[/cell][cell] [color=%s]%s[/color][/cell]" % [String(law_index[tid]["name"]), String(variant_of(tid, cur)["n"]),
				COL_GOOD if ok else COL_WARN, "довольна" if ok else String(variant_of(tid, int(it[1]))["n"])]
		lt += "[/table]"
	var pr: Dictionary = ch["prom"]
	if not pr.is_empty() and law_index.has(pr["tid"]):
		lt += "\n[color=%s]Обещание церкви: закон «%s» — вариант «%s», осталось %d мес.[/color]" % [COL_WARN, String(law_index[pr["tid"]]["name"]), String(variant_of(String(pr["tid"]), int(pr["idx"]))["n"]), int(pr["left"])]
	var ev: Array = ch["evlog"]
	if not ev.is_empty():
		lt += "\n\n[b]Недавние события[/b]\n"
		for k in range(ev.size() - 1, maxi(-1, ev.size() - 5), -1):
			lt += "• [color=%s]%s[/color]\n" % [COL_DIM, String(ev[k])]
	chw_law_rt.text = lt
	# регионы
	var rt := "[table=4][cell][color=%s]Регион[/color][/cell][cell][color=%s] Верующих церкви[/color][/cell][cell][color=%s] Религиозность[/color][/cell][cell][color=%s] С начала[/color][/cell]" % [COL_DIM, COL_DIM, COL_DIM, COL_DIM]
	var ord: Array = []
	for i in regions.size():
		ord.append(i)
	ord.sort_custom(func(a, b): return float(regions[a].get("pie", 0.0)) > float(regions[b].get("pie", 0.0)))
	for i in ord:
		if not regions[i].has("pie"):
			continue
		var d: float = float(regions[i]["pie"]) - float(regions[i]["pie0"])
		rt += "[cell]%s[/cell][cell] %.0f%%[/cell][cell] %.0f[/cell][cell][color=%s] %s[/color][/cell]" % [REGIONS[i]["name"], ch_believers(i) * 100.0, float(regions[i]["pie"]), COL_GOOD if d > 0.3 else (COL_BAD if d < -0.3 else COL_DIM), sg(d, 1)]
	rt += "[/table]\n[color=%s]Религиозность — доля регулярно практикующих среди верующих. Падает с развитием и светским курсом, растёт в кризисы и войны, держится при государственной религии и храмах.[/color]" % COL_DIM
	chw_reg_rt.text = rt


func update_goods_detail() -> void:
	if gdw_all_rt == null or not ind_on() or ec.is_empty() or not ec.has("gp"):
		return
	var t := "[table=4][cell][color=%s]Товар[/color][/cell][cell][color=%s] Доля в категории[/color][/cell][cell][color=%s] Цена к категории[/color][/cell][cell][color=%s] За 12 мес.[/color][/cell]" % [COL_DIM, COL_DIM, COL_DIM, COL_DIM]
	var n := 0
	for g in GOODS:
		var cat: String = String(g["id"])
		var xs := gx_of_cat(cat)
		if xs.is_empty():
			continue
		t += "[cell][b]%s[/b][/cell][cell][/cell][cell][/cell][cell] %s%%[/cell]" % [g["name"], sg(good_yoy(cat) * 100.0, 1)]
		for x in xs:
			n += 1
			var d: float = float(ind["x"][x]["d"]) * 100.0
			var y: float = ind_yoy(String(x)) * 100.0
			t += "[cell]   %s[/cell][cell] %.0f%%[/cell][cell][color=%s] %s%%[/color][/cell][cell][color=%s] %s%%[/color][/cell]" % [gx_name(String(x)), float(ind["w"][x]) * 100.0,
				COL_BAD if d > 1.0 else (COL_GOOD if d < -1.0 else COL_DIM), sg(d, 1), COL_BAD if y > inflation + 2.0 else COL_DIM, sg(y, 1)]
	t += "[/table]"
	var ex := ind_exports()
	if not ex.is_empty():
		var parts: PackedStringArray = []
		for it in ex:
			if parts.size() >= 10:
				break
			parts.append("%s (×%.1f)" % [String(it[1]).to_lower(), float(it[2])])
		t += "\n[b]Экспортные товары страны[/b]: %s." % ", ".join(parts)
	gdw_all_rt.text = "[font_size=13]%d подробных товаров внутри 18 видов расходов, 18 промышленных товаров и видов оружия — всего %d.[/font_size]\n%s" % [n, n + gi_ids().size(), t]
	var it2 := "[table=5][cell][color=%s]Товар[/color][/cell][cell][color=%s] Самообесп.[/color][/cell][cell][color=%s] Надбавка[/color][/cell][cell][color=%s] Цена[/color][/cell][cell][color=%s] Из чего[/color][/cell]" % [COL_DIM, COL_DIM, COL_DIM, COL_DIM, COL_DIM]
	var inputs: Dictionary = CU.get("inputs", {})
	for id in gi_ids():
		var ss := ind_ss(String(id))
		var ss0 := ind_ss0(String(id))
		var pr: float = float(ind["g"][id]["prem"]) * 100.0
		var ins: PackedStringArray = []
		for h in (inputs.get(id, {}) as Dictionary):
			ins.append(String(gi_def(String(h)).get("short", h)).to_lower())
		var sc: String = COL_GOOD if ss >= 1.1 else (COL_BAD if ss < 0.5 else COL_DIM)
		it2 += "[cell]%s[/cell][cell][color=%s] ×%.2f[/color]%s[/cell][cell][color=%s] %.0f%%[/color][/cell][cell] %.2f[/cell][cell][color=%s] %s[/color][/cell]" % [
			gi_name(String(id)), sc, ss, (" (было ×%.2f)" % ss0) if absf(ss - ss0) > 0.02 else "", COL_BAD if pr > 5.0 else COL_DIM, pr, gi_price(String(id)), COL_DIM, ", ".join(ins) if ins.size() > 0 else "сырьё"]
	it2 += "[/table]"
	var lv: int = clampi(fa_ws_lvl(), 0, 3)
	it2 += "\nСамообеспеченность — производство к потреблению: ×1 — хватает своего, больше — экспорт, меньше — нужен импорт. "
	it2 += "Санкции против страны: [b]%s[/b] — перекрыто %.0f%% импорта (технологий — больше). Если своего мало, а импорт перекрыт, растёт надбавка к цене; по цепочкам она доходит до машин, техники и продуктов. Заводы и мегапроект повышают самообеспеченность." % [["нет", "персональные", "секторальные", "полная блокада"][lv], float(IND_BLOCK[lv]) * 100.0]
	gdw_ind_rt.text = it2
