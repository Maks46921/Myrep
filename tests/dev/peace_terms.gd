extends SceneTree
# Отладка (v53_1): пункты мирного договора — цена, доступность, применение, влияние на мировые санкции.
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	for i in 3:
		if not g.current_event.is_empty(): g.choose(0)
		g.next_turn()
	if not g.mil_at_war():
		print("войны нет"); quit(); return
	for id in g.TALK_IDS + g.TALK_GIVE:
		var why: String = g.talk_avail(id)
		print("%-8s %6.1f %s" % [id, g.talk_cost(id), why])
	var sel: Dictionary = g.talk_sel()
	sel.clear()
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("terms="):
			for t in String(a).substr(6).split(","):
				if t.begins_with("repar"): sel["repar"] = int(t.substr(5))
				else: sel[t] = true
	var q: Dictionary = g.talk_quote()
	print("пакет: ", g.talk_pkg_text(q["pkg"]), " цена %.0f готовность %.0f p %.2f" % [q["cost"], q["budget"], q["p"]])
	var t: Dictionary = g.talk_terms(q["pkg"])
	var r: Dictionary = g.mil_peace("annex" if t.has("land") or t.has("border") else "white", t)
	print(r["msg"])
	g.next_turn()
	print(g.fa_ws_text())
	quit()
