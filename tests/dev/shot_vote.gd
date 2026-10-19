extends SceneTree
# v51: окно голосования с анимацией + статистика единогласия
func _init():
	var outd := "/tmp"
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="): outd = String(a).substr(4)
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 6: await process_frame
	var n := 0
	var tot := 0
	var reb := 0
	for t in g.LAW_TOPICS:
		var v = g.variant_votes(String(t["id"]), 1, [])
		tot += 1
		if int(v["yes"]) >= g.SEATS: n += 1
	print("unanimous ", n, " of ", tot)
	# найти закон, который пройдёт
	g.capital = 100.0
	for t in g.LAW_TOPICS:
		var tid := String(t["id"])
		var v2 = g.variant_votes(tid, 1, [])
		if int(v2["yes"]) >= g.law_need(tid) + 5 and g.cur_idx(tid) != 1 and g.law_locked(tid) == "":
			g.vote_sponsor = 0
			g.adopt_variant(tid, 1, [])
			print("voted ", tid, " ", g.last_vote.get("yes"), "/", g.last_vote.get("no"), "/", g.last_vote.get("abst"), " passed ", g.last_vote.get("passed"))
			break
	for i in 8: await process_frame
	await create_timer(1.6).timeout
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png(outd + "/v51_vote_mid.png")
	await create_timer(2.6).timeout
	img = root.get_viewport().get_texture().get_image()
	img.save_png(outd + "/v51_vote_end.png")
	quit()
