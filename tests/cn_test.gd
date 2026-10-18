extends SceneTree
# 0.56: проверка коалиционных переговоров (country=DE): проект, раунды, подписание, нарушение соглашения
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	g.capital = 60.0
	g.cn_new_draft()
	print("parties ", g.cn_parties(), " seats ", g.cn_seats(), " block='", g.cn_block(), "'")
	for p in range(1, g.PARTY_NAMES.size()):
		if g.seats[p] > 0 and g.can_govern(p):
			print(g.PARTY_NAMES[p], " w=", snapped(g.willingness(p, false), 0.1))
	# заменить партнёра: СДПГ (2?) убрать, добавить зелёных
	var spd := -1
	var grn := -1
	for p in range(1, g.PARTY_NAMES.size()):
		if String(g.PARTY_NAMES[p]).contains("СДПГ"): spd = p
		if String(g.PARTY_NAMES[p]).contains("Зел"): grn = p
	g.cn_toggle_party(spd)
	g.cn_toggle_party(grn)
	g.cn_auto_mins()
	print("after swap seats ", g.cn_seats(), " block='", g.cn_block(), "' grn score ", g.cn_score(grn)[0])
	for r in g.cn_score(grn)[1]: print("   ", r)
	g.cn_propose()
	print("ans ", g.cn_ans, " pat ", g.cn_pat)
	# вернуть СДПГ, отдать ей финансы и главу правительства
	g.cn_new_draft()
	g.cn_set_min(1, 0)
	g.cn_toggle_list("budget", spd)
	g.cn_propose()
	print("deal ", not g.coal_deal.is_empty(), " pm ", g.coal_deal.get("pm"), " coalition ", g.coalition_names())
	# сильное нарушение: забрать министерство у партнёра
	var m := -1
	for k in g.MINISTRIES.size():
		if int(g.ministries[k]) == spd: m = k
	g.ministries[m] = 0
	g.cn_month()
	print("after breach spd in coalition: ", g.in_coalition[spd])
	for e in g.log_entries.slice(-6): print("LOG ", String(e.get("t", "")).left(200))
	quit()
