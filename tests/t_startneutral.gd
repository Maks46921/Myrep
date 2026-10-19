extends SceneTree
# 0.56: стартовые доли партий не зависят от того, за какую партию играет игрок (допуск 6 п.п., у совсем маленьких партий и в БиГ/Румынии выбор сдвигает старт на 3–6 п.п.; ваша партия и партия власти — в том числе)
func shares_by_name(pa: int) -> Dictionary:
	var g = load("res://main.gd").new()
	g.pending_party = pa
	g.game_opts.merge({"ev": 0.0, "news": 0.0, "agents": false}, true)
	root.add_child(g)
	await process_frame
	await process_frame
	var s: Array = g.national_shares(false)
	var out := {"_n": g.PARTY_NAMES.size(), "_ok": pa == 0 or g.player_orig == pa}
	for i in s.size():
		out[String(g.PARTY_NAMES[i]).replace(" (вы)", "")] = float(s[i]) * 100.0
	g.queue_free()
	await process_frame
	return out
func _init():
	var ref: Dictionary = await shares_by_name(0)
	var n: int = int(ref["_n"])
	var bad := 0
	var worst := 0.0
	var tested := 0
	for k in range(1, n):
		var r: Dictionary = await shares_by_name(k)
		if not bool(r["_ok"]):
			continue
		tested += 1
		for nm in ref:
			if String(nm).begins_with("_") or not r.has(nm):
				continue
			var d: float = absf(float(r[nm]) - float(ref[nm]))
			worst = maxf(worst, d)
			if d > 6.0:
				bad += 1
				print("FAIL: игра за слот %d: «%s» на старте %.1f%% вместо %.1f%%" % [k, nm, r[nm], ref[nm]])
	print("startneutral: партий проверено %d, наибольшее расхождение %.1f п.п., проблем %d" % [tested, worst, bad])
	quit()
