extends SceneTree
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	if g.AG == null:
		print("[%s] AG=null" % g.ccode); quit(); return
	var P: int = g.PARTY_NAMES.size()
	# агентная и прежняя модель на старте
	g.ag_exact = true
	var a: Array = g.national_shares(false)
	g.ag_on = false
	var l: Array = g.national_shares(false)
	g.ag_on = true
	var md := 0.0
	var ms := ""
	for p in P:
		md = maxf(md, absf(a[p] - l[p]))
	var dl := ""
	for p in P: dl += "%+.1f " % ((a[p]-l[p])*100.0)
	print("  разница по партиям: ", dl)
	# группы: среднее агентов == поддержка
	var st: Array = g.AG.group_stats(g.ag_support_arr())
	var gd := 0.0
	for i in g.GROUPS.size():
		gd = maxf(gd, absf(float(st[i]["appr"]) - float(g.support[g.GROUPS[i]])))
	print("[%s] агентов %d (k=%d) расхождение с прежней моделью: макс %.2f п.п.; группы: макс откл. %.3f" % [g.ccode, g.AG.n, g.AG.k, md * 100.0, gd])
	# скорость
	g.ag_exact = false
	var t0 := Time.get_ticks_msec()
	g.ag_ver += 1
	g.national_shares(false)
	var t1 := Time.get_ticks_msec()
	g.ag_exact = true
	g.ag_ver += 1
	g.national_shares(false)
	var t2 := Time.get_ticks_msec()
	g.ag_ver += 1
	g.ag_step()
	var t3 := Time.get_ticks_msec()
	print("  время: опрос %d мс, точный подсчёт %d мс, шаг агентов %d мс" % [t1 - t0, t2 - t1, t3 - t2])
	g.ag_exact = false
	# прогон 36 месяцев, смотрим дрейф
	for m in 36:
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty(): g.choose(0)
		g.next_turn()
		if g.game_over: break
	st = g.AG.group_stats(g.ag_support_arr())
	var s := ""
	for i in g.GROUPS.size():
		s += "%s %.0f/%.0f%% " % [g.GROUPS[i], float(st[i]["appr"]), float(st[i]["prot"]) * 100.0]
	print("  через 36 мес.: ", s)
	g.ag_exact = true
	var b: Array = g.national_shares(false)
	var line := ""
	for p in P:
		line += "%.1f " % (b[p] * 100.0)
	print("  доли: ", line)
	quit()
