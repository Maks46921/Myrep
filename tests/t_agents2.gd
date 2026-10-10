extends SceneTree
# Агенты v47_1: личная история (работа с памятью, кошелёк, доверие, явка), окружение, дрейф взглядов, активисты.
var bad := 0

func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)

func months(g, n: int) -> void:
	for i in n:
		if g.game_over: return
		if g.election_open: g.election_continue()
		var k := 0
		while not g.current_event.is_empty() and k < 8:
			g.choose(0)
			k += 1
		g.next_turn()

func _init():
	var g = load("res://main.gd").new()
	g.game_opts.merge({"agents": true, "k": 0, "seed": 3, "ev": 0.0, "news": 0.0}, true)
	root.add_child(g)
	for i in 4: await process_frame
	var A = g.AG
	check(A != null and A.n > 1000, "агенты не созданы")
	var n: int = A.n
	check(A.edu.size() == n and A.tp.size() == n and A.trust.size() == n and A.peers.size() == n * A.NPEER, "новые свойства агентов не созданы")
	var bad_peer := 0
	for i in mini(n, 5000):
		for kq in A.NPEER:
			var j: int = A.peers[i * A.NPEER + kq]
			if j < 0 or j >= n or A.reg[j] != A.reg[i]: bad_peer += 1
	check(bad_peer == 0, "знакомые должны быть из того же региона: %d ошибок" % bad_peer)
	# образование и явка
	var tp_hi := 0.0
	var n_hi := 0
	var tp_lo := 0.0
	var n_lo := 0
	for i in n:
		if A.edu[i] == 2:
			tp_hi += A.tp[i]
			n_hi += 1
		elif A.edu[i] == 0:
			tp_lo += A.tp[i]
			n_lo += 1
	check(n_hi > 0 and n_lo > 0 and tp_hi / n_hi > tp_lo / n_lo, "образованные должны голосовать чаще")
	var ide0 := PackedFloat32Array(A.ide)
	var emp0 := PackedByteArray(A.emp)
	months(g, 12)
	var sw := 0
	for i in n:
		if A.emp[i] != emp0[i]: sw += 1
	check(float(sw) / float(n) < 0.25, "занятость не должна «мигать»: %.2f смен на агента в год" % (float(sw) / float(n)))
	var mv := 0.0
	for i in n:
		for ax in 4: mv += absf(A.ide[i * 4 + ax] - ide0[i * 4 + ax])
	check(mv / float(n) > 0.03, "взгляды агентов должны меняться со временем: %.3f" % (mv / float(n)))
	# кризис: безработица и инфляция
	var econ0 := 0.0
	for i in n: econ0 += A.ide[i * 4]
	for m in 18:
		g.unemployment = 14.0
		g.inflation = 9.0
		months(g, 1)
	var econ1 := 0.0
	var long_u := 0
	var act := 0
	var un := 0
	for i in n:
		econ1 += A.ide[i * 4]
		if A.emp[i] == 0 and A.unm[i] >= 12: long_u += 1
		act += A.act[i]
		un += 1 - A.emp[i]
	check(econ1 / n < econ0 / n - 0.01, "кризис должен сдвинуть экономические взгляды влево: %.3f → %.3f" % [econ0 / n, econ1 / n])
	check(long_u > 0, "должны быть долгосрочно безработные")
	check(act > 0, "в кризис должны появиться активисты")
	check(float(un) / float(n) > 0.06, "доля безработных агентов должна вырасти: %.3f" % (float(un) / float(n)))
	check(not is_nan(g.gdp), "NaN")
	print("agents2 ", g.ccode, " агентов ", n, " проблем ", bad)
	quit(1 if bad > 0 else 0)
