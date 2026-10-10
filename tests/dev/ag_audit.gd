extends SceneTree
# Аудит агентов: разнообразие, самостоятельность, реакция на потрясения. Печатает строки AGA|метрика|значение.
func pr(k: String, v: float) -> void:
	print("AGA|%s|%.4f" % [k, v])

func var_share(A, vals: PackedFloat32Array, key: String) -> float:
	# доля дисперсии внутри групп (1 — всё индивидуально, 0 — всё определяется группой)
	var n: int = A.n
	var mean := 0.0
	for i in n: mean += vals[i]
	mean /= float(n)
	var tot := 0.0
	var gs := {}
	var gc := {}
	for i in n:
		tot += (vals[i] - mean) * (vals[i] - mean)
		var g: int = A.reg[i] if key == "reg" else A.grp[i]
		gs[g] = float(gs.get(g, 0.0)) + vals[i]
		gc[g] = int(gc.get(g, 0)) + 1
	var within := 0.0
	for i in n:
		var g2: int = A.reg[i] if key == "reg" else A.grp[i]
		var m: float = float(gs[g2]) / float(gc[g2])
		within += (vals[i] - m) * (vals[i] - m)
	return within / maxf(tot, 1e-9)

func snapshot(g) -> Dictionary:
	var A = g.AG
	var n: int = A.n
	var appr := PackedFloat32Array()
	appr.resize(n)
	var ob = A.group_offbar()
	var sup = g.ag_support_arr()
	for i in n:
		appr[i] = A.approval_of(i, sup, ob)
	var emp := PackedByteArray(A.emp)
	var ide := PackedFloat32Array(A.ide)
	var prot := 0
	for i in n: prot += A.prot[i]
	return {"appr": appr, "emp": emp, "ide": ide, "prot": float(prot) / float(n)}

func _init():
	var mode := "base"
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("mode="): mode = String(a).substr(5)
	var g = load("res://main.gd").new()
	g.game_opts.merge({"agents": true, "seed": 3, "ev": 0.0, "news": 0.0}, true)
	root.add_child(g)
	for i in 4: await process_frame
	var A = g.AG
	pr("agents", float(A.n))
	var s0 := snapshot(g)
	for ax in 4:
		var v := PackedFloat32Array()
		v.resize(A.n)
		var m := 0.0
		for i in A.n:
			v[i] = A.ide[i * 4 + ax]
			m += v[i]
		m /= float(A.n)
		var sd := 0.0
		for i in A.n: sd += (v[i] - m) * (v[i] - m)
		pr("ide_sd_ax%d" % ax, sqrt(sd / float(A.n)))
		pr("ide_within_grp_ax%d" % ax, var_share(A, v, "grp"))
	pr("appr_within_grp", var_share(A, s0["appr"], "grp"))
	pr("appr_within_reg", var_share(A, s0["appr"], "reg"))
	# 12 месяцев обычной жизни
	var switches := 0
	var prev: PackedByteArray = s0["emp"]
	for m2 in 12:
		if g.election_open: g.election_continue()
		while not g.current_event.is_empty(): g.choose(0)
		g.next_turn()
		var cur: PackedByteArray = A.emp
		for i in A.n:
			if cur[i] != prev[i]: switches += 1
		prev = PackedByteArray(cur)
	pr("emp_switches_per_agent_year", float(switches) / float(A.n))
	var s1 := snapshot(g)
	var moved := 0
	var dsum := 0.0
	for i in A.n:
		var d := 0.0
		for ax2 in 4:
			d += absf(A.ide[i * 4 + ax2] - (s0["ide"] as PackedFloat32Array)[i * 4 + ax2])
		dsum += d
		if d > 0.3: moved += 1
	pr("ide_move_mean_12m", dsum / float(A.n))
	pr("ide_moved_share_12m", float(moved) / float(A.n))
	pr("prot_share_0", float(s0["prot"]))
	pr("prot_share_12", float(s1["prot"]))
	# потрясение: безработица 14% и инфляция 9% на 12 месяцев
	var econ_before: Array = []
	for ax3 in 4:
		var mm := 0.0
		for i in A.n: mm += A.ide[i * 4 + ax3]
		econ_before.append(mm / float(A.n))
	for m3 in 12:
		g.unemployment = 14.0
		g.inflation = 9.0
		if g.election_open: g.election_continue()
		while not g.current_event.is_empty(): g.choose(0)
		g.next_turn()
	var s2 := snapshot(g)
	pr("prot_share_shock", float(s2["prot"]))
	for ax4 in 4:
		var mm2 := 0.0
		for i in A.n: mm2 += A.ide[i * 4 + ax4]
		pr("shock_ide_shift_ax%d" % ax4, mm2 / float(A.n) - float(econ_before[ax4]))
	var un := 0
	for i in A.n: un += 1 - A.emp[i]
	pr("unemp_share_agents_shock", float(un) / float(A.n))
	pr("appr_within_grp_shock", var_share(A, s2["appr"], "grp"))
	quit()
