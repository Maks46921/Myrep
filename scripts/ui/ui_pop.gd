# Интерфейс: вкладка «Население».
extends "res://scripts/ui/ui_world.gd"

func build_pop_windows() -> void:
	ag_ui.clear()
	var w1: FloatWindow = new_window("pop_groups", "Группы интересов — агрегаты агентов", 6, Rect2(0.0, 0.0, 0.34, 0.46))
	var cb := Label.new()
	cb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cb.add_theme_font_size_override("font_size", 12)
	cb.add_theme_color_override("font_color", C_DIM)
	cb.text = "Модель агентов включена: 1 агент = %d чел. (задаётся только в меню перед началом игры)." % ag_k() if ag_on else "Модель агентов выключена в настройках новой игры: население считается группами. Включить её можно только в меню перед стартом."
	cb.mouse_filter = Control.MOUSE_FILTER_STOP
	cb.tooltip_text = "Модель агентов и число человек на агента выбираются в меню «Настройки игры» при запуске новой игры и во время игры не меняются."
	w1.body.add_child(cb)
	ag_ui["head"] = make_rt(w1.body)
	ag_ui["table"] = make_rt(w1.body)
	ag_ui["bask"] = make_fold(w1.body, "На что тратят группы и что для них дорожает")

	var w2: FloatWindow = new_window("pop_hist", "Оценка власти: распределение агентов", 6, Rect2(0.0, 0.46, 0.34, 0.54))
	var hb := HBoxContainer.new()
	w2.body.add_child(hb)
	var hl := Label.new()
	hl.text = "Группа:"
	hb.add_child(hl)
	var hg := OptionButton.new()
	hg.add_item("Все группы")
	for g in GROUPS:
		hg.add_item(g)
	hg.item_selected.connect(func(_i): ag_reset_ui())
	hb.add_child(hg)
	ag_ui["hg"] = hg
	var hv := AgentHistView.new()
	w2.body.add_child(hv)
	ag_ui["hist"] = hv
	ag_ui["hnote"] = make_rt(w2.body)

	var w3: FloatWindow = new_window("pop_map", "Идеологическая карта", 6, Rect2(0.34, 0.0, 0.36, 0.64))
	var mb := HBoxContainer.new()
	w3.body.add_child(mb)
	var axl := Label.new()
	axl.text = "Ось →"
	mb.add_child(axl)
	var ax := OptionButton.new()
	var ayl := Label.new()
	ayl.text = "Ось ↑"
	var ay := OptionButton.new()
	for t in AgentPop.AXIS_SHORT:
		ax.add_item(String(t))
		ay.add_item(String(t))
	ax.selected = 0
	ay.selected = 1
	ax.item_selected.connect(func(_i): ag_reset_ui())
	ay.item_selected.connect(func(_i): ag_reset_ui())
	ax.clip_text = true
	ay.clip_text = true
	ax.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mb.add_child(ax)
	mb.add_child(ayl)
	mb.add_child(ay)
	ag_ui["ax"] = ax
	ag_ui["ay"] = ay
	var mb2 := HBoxContainer.new()
	w3.body.add_child(mb2)
	var cm := OptionButton.new()
	for t in ["Цвет: первый выбор партии", "Цвет: группа интересов", "Цвет: оценка власти", "Цвет: готовность протестовать"]:
		cm.add_item(t)
	cm.clip_text = true
	cm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cm.tooltip_text = "Чем раскрасить точки-агентов."
	cm.item_selected.connect(func(_i): ag_reset_ui())
	mb2.add_child(cm)
	ag_ui["cm"] = cm
	var pf := OptionButton.new()
	pf.add_item("Все партии")
	for pn in PARTY_NAMES:
		pf.add_item(String(pn))
	pf.clip_text = true
	pf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pf.tooltip_text = "Оставить на карте только сторонников одной партии."
	pf.item_selected.connect(func(_i): ag_reset_ui())
	mb2.add_child(pf)
	ag_ui["pf"] = pf
	ag_ui["mleg"] = make_rt(w3.body)
	var mv := AgentMapView.new()
	mv.picked = ag_pick
	mv.tipper = ag_tip
	w3.body.add_child(mv)
	ag_ui["map"] = mv
	ag_ui["mnote"] = make_fold(w3.body, "Как читать карту")

	var w4: FloatWindow = new_window("pop_agent", "Карточка агента", 6, Rect2(0.34, 0.64, 0.18, 0.36))
	var ab := HFlowContainer.new()
	w4.body.add_child(ab)
	var rb := Button.new()
	rb.text = "Случайный агент"
	rb.focus_mode = Control.FOCUS_NONE
	rb.pressed.connect(ag_random_agent)
	ab.add_child(rb)
	var fg := OptionButton.new()
	fg.add_item("из любой группы")
	for g in GROUPS:
		fg.add_item(g)
	ab.add_child(fg)
	ag_ui["fg"] = fg
	ag_ui["card"] = make_rt(w4.body)

	var w5: FloatWindow = new_window("pop_regions", "Протестные настроения по регионам", 6, Rect2(0.52, 0.64, 0.18, 0.36))
	ag_ui["reg"] = make_rt(w5.body)


const AG_GROUP_COLS := [Color("e8825a"), Color("5aa9e8"), Color("b5a1e8"), Color("f2d94d"), Color("5ae8c0"), Color("8cc152"), Color("9aa4b8"), Color("4fd16b")]


func ag_tip(i: int) -> String:
	if AG == null or i < 0 or i >= AG.n:
		return ""
	var g: int = AG.grp[i]
	var ob := AG.group_offbar()
	var a: float = clampf(float(support[GROUPS[g]]) + AG.off[i] - ob[g], 0.0, 100.0)
	return "Агент №%d — %s, %s\nОценка власти: %.0f%s\nВозраст %d, %s\nЩёлкните — подробная карточка." % [i, GROUPS[g], String(REGIONS[AG.reg[i]]["name"]), a, " (недоволен)" if a < AgentPop.PROT_AT else "", int(AG.age[i]), AgentPop.SEC_NAMES[AG.sec[i]]]


func ag_agent_text(i: int) -> String:
	var P := PARTY_NAMES.size()
	var g: int = AG.grp[i]
	var r: int = AG.reg[i]
	var sup_g: float = float(support[GROUPS[g]])
	var ob := AG.group_offbar()
	var a: float = clampf(sup_g + AG.off[i] - ob[g], 0.0, 100.0)
	var loy: float = (float(regions[r]["loy"]) - 50.0) * 0.5
	var eff_c: float = clampf(sup_g + loy, 5.0, 100.0)
	var ei: float = clampf(a + loy, 5.0, 100.0)
	var w := vote_weights(r, GROUPS[g], false)
	var v: Array = []
	var tot := 0.0
	for p in P:
		var x: float = w[p] * AG.aff[i * P + p]
		if p == 0:
			x *= pow(ei / eff_c, 3.0)
		elif p == 9:
			x *= pow(clampf((100.0 - ei) / maxf(100.0 - eff_c, 1.0), 0.2, 3.0), 2.0)
		v.append(x)
		tot += x
	var idx: Array = []
	for p in P:
		idx.append(p)
	idx.sort_custom(func(p, q): return float(v[p]) > float(v[q]))
	var t := "[b]Агент №%d[/b] — «%s», %s\n" % [i, GROUPS[g], String(REGIONS[r]["name"])]
	t += "Представляет [b]%d чел.[/b]\n" % AG.k
	var jt: String = "пенсионер" if g == 2 else "работает"
	if AG.emp[i] == 0 and g != 2:
		jt = "[color=#ff8a80]безработный[/color]" + (" уже %d мес." % int(AG.unm[i]) if AG.unm.size() > i and AG.unm[i] > 0 else "")
	t += "Возраст: %d, образование: %s\nОтрасль: %s, %s\n" % [int(AG.age[i]), AgentPop.EDU_NAMES[AG.edu[i]] if AG.edu.size() > i else "—", AgentPop.SEC_NAMES[AG.sec[i]], jt]
	t += "Доход: ×%.2f от среднего по группе-эталону\n" % AG.inc[i]
	if AG.pb.size() > i:
		var pbv: float = AG.pb[i]
		t += "Кошелёк: [color=%s]%s[/color] (%s)\n" % ["#8be08b" if pbv >= 0.5 else ("#ff8a80" if pbv <= -1.5 else "#e8d27a"), "живёт лучше" if pbv >= 0.5 else ("живёт хуже" if pbv <= -1.5 else "без перемен"), sg(pbv, 1)]
		t += "Доверие к институтам: %.0f%%, придёт на выборы: %.0f%%%s\n" % [AG.trust[i] * 100.0, AG.tp[i] * 100.0, "  [color=#ffb74d]активист[/color]" if AG.act[i] == 1 else ""]
		var pp := 0
		for q in AgentPop.NPEER:
			var j: int = AG.peers[i * AgentPop.NPEER + q]
			if j >= 0 and j != i and AG.prot[j] == 1:
				pp += 1
		if pp > 0:
			t += "Знакомых, готовых протестовать: %d из %d\n" % [pp, AgentPop.NPEER]
	t += "Вера: [color=%s][b]%s[/b][/color]%s\n" % [SOC_FCOL[AG.faith[i]], SOC_FAITH[AG.faith[i]], " (практикующий)" if AG.devout[i] == 1 else ""]
	t += "Оценка власти: [b]%.0f[/b] (группа: %.0f)%s\n\n" % [a, sup_g, "  [color=#ff8a80]готов протестовать[/color]" if AG.prot[i] == 1 else ""]
	t += "[b]Взгляды[/b]\n"
	for ax in 4:
		t += "%s: %+.1f\n" % [AgentPop.AXIS_NAMES[ax], AG.ide[i * 4 + ax]]
	var ws: Array = []
	for kk in 6:
		ws.append(kk)
	ws.sort_custom(func(p, q): return AG.cw[i * 6 + p] > AG.cw[i * 6 + q])
	t += "\n[b]Главные интересы:[/b] %s, %s\n" % [AgentPop.KEY_NAMES[ws[0]], AgentPop.KEY_NAMES[ws[1]]]
	if AG.NG > 0 and not ec.is_empty() and ec.has("gp"):
		var gi: Array = []
		for j in AG.NG:
			gi.append(j)
		gi.sort_custom(func(p, q): return AG.gw[i * AG.NG + p] > AG.gw[i * AG.NG + q])
		var sp: PackedStringArray = []
		var pc := 0.0
		for j in AG.NG:
			pc += AG.gw[i * AG.NG + j] * float(ec["gp"][GOODS[j]["id"]])
		for q in 3:
			sp.append("%s %.0f%%" % [String(GOODS[gi[q]]["short"]).to_lower(), AG.gw[i * AG.NG + gi[q]] * 100.0])
		t += "[b]Больше всего тратит на:[/b] %s. Его корзина подорожала на %s%%.\n" % [", ".join(sp), sg((pc - 1.0) * 100.0, 1)]
	t += "\n[b]Если бы выборы были сегодня[/b]\n"
	for j in 3:
		var p: int = idx[j]
		t += "[color=#%s]■[/color] %s — %.0f%%\n" % [(PARTY_COLORS[p] as Color).to_html(false), PARTY_NAMES[p], 100.0 * float(v[p]) / maxf(tot, 0.0001)]
	return t


func update_pop_windows() -> void:
	if ag_ui.is_empty():
		return
	var head: RichTextLabel = ag_ui["head"]
	var table: RichTextLabel = ag_ui["table"]
	if AG == null or not ag_on:
		head.text = "Модель агентов выключена: голосуют укрупнённые группы."
		table.text = ""
		(ag_ui["card"] as RichTextLabel).text = ""
		(ag_ui["reg"] as RichTextLabel).text = ""
		return
	var sup := ag_support_arr()
	if ag_ui_ver != ag_ver:
		ag_ui_ver = ag_ver
		var st: Array = AG.group_stats(sup)
		head.text = "Агентов: [b]%d[/b] (1 агент = %d чел.)" % [AG.n, AG.k]
		head.tooltip_text = "Оценка группы — среднее по её агентам; голосуют, протестуют и мигрируют в настроениях сами агенты, у каждого свой возраст, доход, отрасль, занятость, взгляды и интересы. Выборы считаются по всем агентам, опросы — по выборке."
		var tt := "[table=7]"
		for h in ["Группа", "Млн", "Оценка", "±", "Протест", "Безраб.", "Лет"]:
			tt += "[cell][b]%s[/b] [/cell]" % h
		for g in GROUPS.size():
			var s: Dictionary = st[g]
			tt += "[cell]%s [/cell][cell]%.2f [/cell][cell][b]%.0f[/b] [/cell][cell]±%.0f [/cell][cell]%.0f%% [/cell][cell]%.1f%% [/cell][cell]%.0f [/cell]" % [
				GROUPS[g], float(int(s["n"]) * AG.k) / 1000000.0, float(s["appr"]), float(s["sd"]), float(s["prot"]) * 100.0, float(s["unemp"]) * 100.0, float(s["age"])]
		tt += "[/table]"
		table.text = tt
		var bk := "[table=3][cell][b]Группа[/b] [/cell][cell][b]Главные траты[/b] [/cell][cell][b]Корзина vs средняя[/b][/cell]"
		for gr in GROUPS:
			var tops: PackedStringArray = []
			for it in group_top_goods(gr, 3):
				tops.append("%s %.0f%%" % [String(good_def(it[0])["short"]).to_lower(), float(it[1]) * 100.0])
			var gp_: float = group_gap(gr)
			bk += "[cell]%s [/cell][cell]%s [/cell][cell][color=%s]%s п.п.[/color][/cell]" % [gr, ", ".join(tops), COL_BAD if gp_ > 0.3 else (COL_GOOD if gp_ < -0.3 else COL_DIM), sg(gp_, 1)]
		bk += "[/table]"
		(ag_ui["bask"] as RichTextLabel).text = bk
		var hg: int = (ag_ui["hg"] as OptionButton).selected - 1
		var hs := AG.hist(sup, hg, 20)
		(ag_ui["hist"] as AgentHistView).h = hs
		(ag_ui["hist"] as AgentHistView).queue_redraw()
		var lo := 0
		var all := 0
		for b in hs.size():
			all += hs[b]
			if (float(b) + 0.5) * 5.0 < AgentPop.PROT_AT:
				lo += hs[b]
		(ag_ui["hnote"] as RichTextLabel).text = "Красные столбцы — оценка ниже %d: таких агентов [b]%.0f%%[/b] — они готовы выходить на улицы." % [int(AgentPop.PROT_AT), 100.0 * float(lo) / float(maxi(1, all))]
		# карта
		var ax: int = (ag_ui["ax"] as OptionButton).selected
		var ay: int = (ag_ui["ay"] as OptionButton).selected
		var cmode: int = (ag_ui["cm"] as OptionButton).selected
		var mv: AgentMapView = ag_ui["map"]
		mv.pts.clear()
		mv.cols.clear()
		mv.ids.clear()
		mv.favs.clear()
		mv.filter = (ag_ui["pf"] as OptionButton).selected - 1
		mv.ends = [AgentPop.AXIS_ENDS[ax][0], AgentPop.AXIS_ENDS[ax][1], AgentPop.AXIS_ENDS[ay][0], AgentPop.AXIS_ENDS[ay][1]]
		mv.axis_names = [AgentPop.AXIS_SHORT[ax], AgentPop.AXIS_SHORT[ay]]
		var step := maxi(1, AG.n / 1600)
		var P := PARTY_NAMES.size()
		var pm: Array = []
		for p in P:
			pm.append(1.0)
		var ob := AG.group_offbar()
		var pcnt: Array = []
		for p in P:
			pcnt.append(0)
		var gcnt: Array = []
		for g in GROUPS.size():
			gcnt.append(0)
		var low := 0
		var sumv := Vector2.ZERO
		var i := 0
		while i < AG.n:
			var g: int = AG.grp[i]
			var a: float = clampf(float(sup[g]) + AG.off[i] - ob[g], 5.0, 100.0)
			pm[0] = pow(a / 50.0, 3.0)
			var fv := AG.favourite(i, LEAN[GROUPS[g]], pm)
			var c: Color = PARTY_COLORS[fv]
			if cmode == 1:
				c = AG_GROUP_COLS[g]
			elif cmode == 2:
				c = Color(0.95, 0.25, 0.25).lerp(Color(0.95, 0.85, 0.3), clampf((a - 20.0) / 30.0, 0.0, 1.0)).lerp(Color(0.3, 0.85, 0.5), clampf((a - 50.0) / 30.0, 0.0, 1.0))
			elif cmode == 3:
				c = Color(1.0, 0.3, 0.3) if a < AgentPop.PROT_AT else Color(0.55, 0.6, 0.7)
			c.a = 0.8
			if a < AgentPop.PROT_AT:
				low += 1
			pcnt[fv] += 1
			gcnt[g] += 1
			var pt := Vector2(AG.ide[i * 4 + ax], AG.ide[i * 4 + ay])
			sumv += pt
			mv.pts.append(pt)
			mv.cols.append(c)
			mv.ids.append(i)
			mv.favs.append(fv)
			i += step
		var ns: int = maxi(1, mv.pts.size())
		mv.centroid = sumv / float(ns)
		mv.marks = []
		for p in P:
			var share: float = float(pcnt[p]) / float(ns)
			var tip := "%s\nу %.0f%% агентов это первый выбор (на выборах часть голосует иначе или не идёт)\nПозиция по осям: %s %+.1f, %s %+.1f" % [PARTY_NAMES[p], share * 100.0, AgentPop.AXIS_SHORT[ax], float(ag_pos[p][ax]) * 0.5, AgentPop.AXIS_SHORT[ay], float(ag_pos[p][ay]) * 0.5]
			if p == 0:
				tip += "\nЭто ваша партия."
			mv.marks.append([Vector2(float(ag_pos[p][ax]), float(ag_pos[p][ay])) * 0.5, PARTY_COLORS[p], String(PARTY_NAMES[p]).substr(0, 14), share, p == 0, tip])
		var lg := ""
		if cmode == 0:
			var order: Array = []
			for p in P:
				order.append(p)
			order.sort_custom(func(p, q): return pcnt[p] > pcnt[q])
			for p in order:
				if float(pcnt[p]) / float(ns) < 0.01:
					continue
				lg += "[color=#%s]●[/color] %s [b]%.0f%%[/b]   " % [(PARTY_COLORS[p] as Color).to_html(false), String(PARTY_NAMES[p]).substr(0, 22), 100.0 * float(pcnt[p]) / float(ns)]
		elif cmode == 1:
			for g in GROUPS.size():
				lg += "[color=#%s]●[/color] %s %.0f%%   " % [(AG_GROUP_COLS[g] as Color).to_html(false), GROUPS[g], 100.0 * float(gcnt[g]) / float(ns)]
		elif cmode == 2:
			lg = "[color=#f24040]●[/color] недовольны (ниже %d)   [color=#f2d94d]●[/color] колеблются   [color=#4dd980]●[/color] довольны.  Недовольных: [b]%.0f%%[/b]" % [int(AgentPop.PROT_AT), 100.0 * float(low) / float(ns)]
		else:
			lg = "[color=#ff4d4d]●[/color] готовы выходить на улицы — [b]%.0f%%[/b] агентов   [color=#8c99b3]●[/color] остальные" % [100.0 * float(low) / float(ns)]
		lg += "\n[color=#ffffff]★[/color] ваша партия · размер кружка партии — доля тех, у кого она первый выбор · ✚ центр общества · жёлтое кольцо — выбранный агент"
		(ag_ui["mleg"] as RichTextLabel).text = "[font_size=12]%s[/font_size]" % lg
		(ag_ui["mnote"] as RichTextLabel).text = "Каждая точка — один агент (показана выборка до 1600 из %d), её положение — взгляды агента по двум выбранным осям. Концы осей подписаны по краям: чем ближе точка к краю, тем крайнее взгляды. Кружки с названием — позиции партий (по составу их электората, разброс растянут для читаемости); чем больше кружок, тем больше агентов ставят её на первое место. Наведите курсор на точку или партию — появится подсказка; щёлкните по точке — откроется карточка агента. Недовольные постепенно смещаются к суверенитету и порядку." % AG.n
		# регионы
		var rows: Array = []
		for r in regions.size():
			rows.append(r)
		rows.sort_custom(func(p, q): return AG.region_prot(p) > AG.region_prot(q))
		var rt := "Доля агентов с оценкой власти ниже %d и её изменение %s. Она повышает недовольство региона.\n" % [int(AgentPop.PROT_AT), h12_label("prot")]
		var pr0: Array = h12_ago("prot", [])
		for r in rows:
			var cur: float = AG.region_prot(r) * 100.0
			var dv: float = cur - (float(pr0[r]) * 100.0 if r < pr0.size() else cur)
			rt += "%s — [b]%.0f%%[/b] [color=%s](%+.1f)[/color]\n" % [String(REGIONS[r]["name"]), cur, "#ff8a80" if dv > 0.5 else ("#7bd88f" if dv < -0.5 else "#9aa4b8"), dv]
		(ag_ui["reg"] as RichTextLabel).text = rt
	var mv2: AgentMapView = ag_ui["map"]
	if ag_sel >= 0 and ag_sel < AG.n:
		var ax2: int = (ag_ui["ax"] as OptionButton).selected
		var ay2: int = (ag_ui["ay"] as OptionButton).selected
		mv2.sel = Vector2(AG.ide[ag_sel * 4 + ax2], AG.ide[ag_sel * 4 + ay2])
		(ag_ui["card"] as RichTextLabel).text = ag_agent_text(ag_sel)
	else:
		mv2.sel = Vector2(INF, INF)
		(ag_ui["card"] as RichTextLabel).text = "Выберите агента на карте или нажмите «Случайный агент»."
	mv2.queue_redraw()
