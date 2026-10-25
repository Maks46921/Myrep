extends SceneTree
# 0.60: варианты режимов — данные, выбор, эффекты, события, рычаги, смена строя законом
var bad := 0
func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)
func _init():
	var g = load("res://main.gd").new()
	g.game_opts.merge({"ev": 0.0, "news": 0.0}, true)
	root.add_child(g)
	for i in 3: await process_frame
	var start_cls: String = String(g.au.get("cls", "dem"))
	print("старт ", g.ccode, ": класс ", start_cls, ", вариант ", g.au.get("var", ""))
	if start_cls != "dem":
		check(String(g.au.get("var", "")) != "", "на старте у страны с недемократическим режимом выбран вариант")
	var acts := {}
	for a in g.AU_ACTS60:
		acts[a[0]] = true
	for a in g.AU_ACTS:
		acts[a[0]] = true
	for a in g.AU2_ACTS:
		acts[a[0]] = true
	acts["reward"] = true
	acts["purge"] = true
	var ids := {}
	var classes := {}
	for v in g.REG_VARS60:
		check(not ids.has(v["id"]), "вариант: id не повторяется %s" % v["id"])
		ids[v["id"]] = true
		classes[v["cls"]] = classes.get(v["cls"], 0) + 1
		check(g.AU_CLANS.has(v["cls"]) and g.AU_CLASS_NAMES.has(v["cls"]), "вариант %s: класс %s описан" % [v["id"], v["cls"]])
		for k in v["m"]:
			check(g.MOD_INFO.has(k), "вариант %s: показатель %s есть в MOD_INFO" % [v["id"], k])
		for k in v.get("tl", {}):
			check(acts.has(k), "вариант %s: рычаг %s существует" % [v["id"], k])
		for a in v["ideo"]:
			check(a in ["social", "liberal", "conserv", "green", "populist"], "вариант %s: архетип %s" % [v["id"], a])
		check(String(v["d"]).length() > 40, "вариант %s: есть описание" % v["id"])
	for c in ["oneparty", "junta", "monarchy_abs", "hybrid", "theocracy", "technocracy", "oligarchy", "collective", "transitional"]:
		check(classes.has(c), "для класса %s есть варианты" % c)
	var ev_by := {}
	for e in g.REG_EVENTS60:
		check(ids.has(e["var"]), "событие: вариант %s существует" % e["var"])
		ev_by[e["var"]] = int(ev_by.get(e["var"], 0)) + 1
		check((e["o"] as Array).size() >= 2, "событие %s: не меньше двух вариантов" % e["var"])
	for id in ids:
		check(int(ev_by.get(id, 0)) >= 5, "у варианта %s не меньше пяти событий (%d)" % [id, int(ev_by.get(id, 0))])
	# выбор варианта и эффекты для каждого класса; все события выполняются без ошибок
	g.au_init()
	for cls in classes:
		g.reg_cause = "coup"
		g.au_set_class(cls, false)
		var cur: String = String(g.au.get("var", ""))
		check(cur != "" and String(g.reg60_def(cur)["cls"]) == cls, "класс %s: выбран вариант (%s)" % [cls, cur])
		for v in g.reg60_vars(cls):
			g.au["var"] = v["id"]
			g.recompute_mods()
			check(g.reg60_title() == v["n"], "название варианта %s" % v["id"])
			check(g.reg60_effect_text(v) != "", "текст эффектов %s" % v["id"])
			for e in g.reg60_events():
				pass
			for e in g.REG_EVENTS60:
				if e["var"] != v["id"]:
					continue
				for o in e["o"]:
					g.apply_fx(o["fx"])
	# рычаги
	g.au_set_class("oneparty", false)
	g.capital = 80.0
	for id in ["show_trial", "rally", "enemy", "rel_ban"]:
		g.au["cd"] = {}
		var why: String = g.au_check(id)
		if why == "":
			check(g.au_act(id), "рычаг %s срабатывает" % id)
		else:
			print("рычаг %s: %s" % [id, why])
	# переходное правительство: срок и возврат к демократии
	g.au_set_class("transitional", false)
	check(int(g.au.get("tr_end", 0)) > g.turn + 30, "переходное правительство: срок записан")
	g.capital = 80.0
	g.au["cd"] = {}
	check(g.au_check("tr_extend") == "", "переходное: продление доступно")
	# смена строя законом: технократия и обратно
	var vs: Array = g.law_index["gov_form"]["v"]
	var itech := -1
	for k in vs.size():
		if String((vs[k] as Dictionary).get("rid", "")) == "technocracy":
			itech = k
	check(itech > 0, "форма правления: технократия есть среди вариантов")
	if itech > 0:
		g.au_init()
		g.reg_cause = "reform"
		g.law_state["gov_form"] = itech
		g.radical_enact("gov_form", itech, "")
		g.recompute_mods()
		g.au_step()
		check(g.regime_class() == "technocracy", "после закона класс режима — технократия (%s)" % g.regime_class())
		check(String(g.au.get("var", "")) in ["tc_cab", "tc_epist", "tc_cb"], "вариант технократии выбран (%s)" % g.au.get("var", ""))
		g.au_step()
		g.au_step()
	print("t_reg60: проблем ", bad, ", вариантов ", ids.size(), ", событий ", g.REG_EVENTS60.size())
	quit(1 if bad > 0 else 0)
