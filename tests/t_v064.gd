extends SceneTree
# 0.64: «по линии партии» даёт голос по линии; карточки партий; статусы; плитки; поле ввода; мир РФ-УА; Беларусь; регионы Украины
var bad := 0

func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)

func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	var cc := "DE"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("country="):
			cc = a.substr(8)
	if cc != g.ccode:
		g.choose_country(cc)
		for i in 3: await process_frame
	seed(64)
	# --- п.13: «по линии партии» не расходится с линией ---
	var n := 0
	var kinds := {"yes": 0, "no": 0, "abst": 0}
	for p in range(1, g.PARTY_NAMES.size()):
		if g.seats[p] <= 0:
			continue
		for t in g.LAW_TOPICS:
			var tid: String = t["id"]
			var vs: Array = t["v"]
			for idx in vs.size():
				if idx == g.cur_idx(tid):
					continue
				var k: String = g.line_kind_for(tid, idx, p)
				g.vote_sponsor = p
				g.vote_pl = "line"
				var r: Dictionary = g.variant_votes(tid, idx, [])
				g.vote_sponsor = 0
				g.vote_pl = ""
				for e in r["per"]:
					if int(e[0]) != 0:
						continue
					n += 1
					kinds[k] += 1
					if e.size() < 6:
						continue
					if k == "yes":
						check(int(e[3]) >= int(e[4]), "%s %s→%d спонсор %d: линия «за», а фракция в основном против (%d/%d)" % [cc, tid, idx, p, int(e[3]), int(e[4])])
					elif k == "no":
						check(int(e[4]) >= int(e[3]), "%s %s→%d спонсор %d: линия «против», а фракция в основном за (%d/%d)" % [cc, tid, idx, p, int(e[3]), int(e[4])])
					else:
						check(int(e[3]) == 0 and int(e[4]) == 0 and int(e[5]) == g.seats[0], "%s %s→%d: нет линии, а фракция не воздержалась" % [cc, tid, idx])
	print("линия проверена в %d случаях: %s" % [n, str(kinds)])
	check(n > 20, "слишком мало случаев для проверки линии")
	# --- п.6: регионы — данные согласованы во всех странах ---
	var expect_n := {"IT": 20, "ES": 17, "CZ": 14, "HR": 21, "HU": 20, "BG": 28, "SE": 21, "FI": 19, "NO": 15, "EE": 15, "LT": 10, "SI": 11, "AL": 12, "CH": 16, "UA": 24}
	var soc_d = JSON.parse_string(FileAccess.get_file_as_string("res://data/soc.dat"))
	var cult_d = JSON.parse_string(FileAccess.get_file_as_string("res://data/cult.dat"))
	var world_d = JSON.parse_string(FileAccess.get_file_as_string("res://data/world.dat"))
	var nreg_all := 0
	for c in g.COUNTRY_CODES:
		var cd: Dictionary = g.CDATA.get(c, {})
		if not cd.has("REGIONS"):
			continue
		var codes: Array = []
		var seen := {}
		for r in cd["REGIONS"]:
			var code := String(r["code"])
			check(not seen.has(code), "%s: код региона %s повторяется" % [c, code])
			seen[code] = true
			codes.append(code)
		nreg_all += codes.size()
		if expect_n.has(c):
			check(codes.size() == int(expect_n[c]), "%s: регионов %d, ожидалось %d" % [c, codes.size(), int(expect_n[c])])
		check((cd["REG_BIAS"] as Array).size() == codes.size(), "%s: строки REG_BIAS не совпадают с регионами" % c)
		for pair in [["soc", soc_d], ["cult", cult_d]]:
			var cc_d: Dictionary = (pair[1] as Dictionary)["country"]
			if not cc_d.has(c) or not (cc_d[c] as Dictionary).has("reg"):
				continue
			var rg: Dictionary = cc_d[c]["reg"]
			for code in codes:
				check(rg.has(code), "%s: в %s.dat нет региона %s" % [c, pair[0], code])
			for k in rg.keys():
				check(k in codes, "%s: в %s.dat лишний регион %s" % [c, pair[0], k])
		if world_d.has(c):
			var wc: Array = []
			for r in world_d[c]["regions"]:
				wc.append(String(r["code"]))
			wc.sort()
			var sc: Array = codes.duplicate()
			sc.sort()
			check(wc == sc, "%s: регионы world.dat не совпадают с регионами страны" % c)
		for ev in g.REG_EVENTS_CC.get(c, []):
			var rk := String(ev.get("reg", ""))
			if rk.begins_with("code:"):
				for k in rk.substr(5).split("|"):
					check(k in codes, "%s: событие указывает на несуществующий регион %s" % [c, k])
	print("регионов во всех странах: %d" % nreg_all)
	if cc == "UA":
		check(g.REGIONS.size() == 24, "в Украине должно быть 24 региона")
		var occ := g.CDATA["UA"].get("REG_LOST", []) as Array
		check(occ.size() >= 3, "нет списка неподконтрольных территорий Украины")
	# --- п.7: в названиях вариантов законов нет пометок состояния ---
	for t in g.LAW_TOPICS:
		for v in t["v"]:
			var vn := String(v["n"])
			check(not (" (действует)" in vn or " (принято)" in vn or " (текущий)" in vn), "%s: в названии «%s» есть пометка состояния" % [cc, vn])
	check(g.has_method("bill_open_law"), "нет bill_open_law (п.9)")
	# --- п.12: поле ввода отпускается щелчком в другом месте, Esc и Enter ---
	var le := LineEdit.new()
	le.size = Vector2(120, 24)
	g.add_child(le)
	le.position = Vector2(300, 300)
	await process_frame
	le.grab_focus()
	await process_frame
	check(le.has_focus(), "поле ввода не получило фокус")
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.pressed = true
	mb.position = Vector2(-500, -500)
	g.text_focus_release(mb)
	check(not le.has_focus(), "щелчок вне поля не отпустил ввод")
	for kc in [KEY_ESCAPE, KEY_ENTER]:
		le.grab_focus()
		await process_frame
		var ke := InputEventKey.new()
		ke.keycode = kc
		ke.pressed = true
		check(g.text_focus_release(ke), "клавиша %d не обработана" % kc)
		check(not le.has_focus(), "клавиша %d не отпустила ввод" % kc)
	le.queue_free()
	# --- п.1: карточки партий ---
	var host := Control.new()
	g.add_child(host)
	var ph: Dictionary = g.party_pick_make(host, func(_q: int) -> void: pass)
	var pitems: Array = []
	for p in range(1, mini(6, g.PARTY_NAMES.size())):
		pitems.append({"p": p, "why": "тестовая причина" if p == 2 else ""})
	g.party_pick_set(ph, pitems, 1)
	var grid: GridContainer = ph["grid"]
	check(grid.get_child_count() == pitems.size(), "карточек партий %d, ожидалось %d" % [grid.get_child_count(), pitems.size()])
	var off_ok := false
	for ch in grid.get_children():
		if String((ch as Control).tooltip_text).begins_with("Нельзя, потому что"):
			off_ok = true
	check(off_ok, "недоступная партия не помечена «нельзя, потому что…»")
	host.queue_free()
	# --- п.5: мир ИИ-России ---
	if cc == "RU":
		g.mil_declare("UA", true)
		if g.mil_at_war():
			g.mil["pend"] = {"kinds": ["", "talk_cnt", "white", "lose_cede"]}
			g.mil["war"]["score"] = -10.0
			g.mil["ldr_gone"] = false
			if g.au_auth():
				check(g.mil_ai_stance() == "hard", "при жёстком режиме без смены лидера линия должна быть жёсткой")
				check(g.mil_ai_war_pick({}) == 0, "ИИ-Россия согласилась на мир, не взяв Донецкую область")
			g.mil["pend"] = {"kinds": ["", "capit"]}
			check(g.mil_ai_war_pick({}) == 1, "ИИ-Россия не приняла капитуляцию")
			check(not g.mil_don_full(), "Донецкая область не должна быть полностью под контролем в начале войны")
	# --- п.3: Беларусь не тревожится из-за российского усиления ---
	if cc == "RU" and not g.ar.is_empty():
		g.ar["pw0"] = 1.0
		(g.ar["wlog"] as Dictionary).clear()
		g.ar_world_month()
		check(not (g.ar["wlog"] as Dictionary).has("BY"), "Беларусь отреагировала на усиление России как на угрозу")
		check(float((g.ar["wmt"] as Dictionary).get("BY", 1.0)) < 1.2, "Беларусь наращивает армию слишком сильно")
	if bad == 0:
		print("OK v064 %s" % cc)
	quit(1 if bad > 0 else 0)
