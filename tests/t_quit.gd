extends SceneTree
# v36: младший партнёр при провальном рейтинге выходит из коалиции (а не проигрывает); в Швейцарии
# непереизбрание в Федеральный совет оставляет партию в парламенте (оппозиция).
var bad := 0

func check(ok: bool, msg: String) -> void:
	if not ok:
		bad += 1
		print("FAIL: ", msg)

func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	var cc: String = g.ccode
	if g.opp_mode:
		print("[%s] старт в оппозиции — проверка младшего партнёра пропущена" % cc)
	else:
		# 1. делаем партию игрока младшим партнёром: в коалиции есть партия с большим числом мест
		var big := 1
		for p in range(1, g.PARTY_NAMES.size()):
			if g.seats[p] > g.seats[big]: big = p
		if g.seats[big] <= g.seats[0]:
			var d: int = g.seats[0] - g.seats[big] + 5
			g.seats[big] += d
			g.seats[0] -= d
		g.in_coalition[big] = true
		check(bool(g.junior_info()["junior"]), "партия игрока не стала младшим партнёром")
		for gr in g.support: g.support[gr] = 3.0
		g.low_months = 2
		if g.election_open: g.election_continue()
		if not g.current_event.is_empty(): g.choose(0)
		var ap: float = g.approval()
		g.next_turn()
		print("[%s] рейтинг %.0f → %.0f, оппозиция %s, конец игры %s" % [cc, ap, g.approval(), g.opp_mode, g.game_over])
		check(not g.game_over, "младший партнёр проиграл из-за рейтинга: %s" % g.game_over_msg if "game_over_msg" in g else "")
		check(g.opp_mode and not g.in_coalition[0], "младший партнёр не вышел из коалиции")
		check(g.low_months == 0, "счётчик низкого рейтинга не сброшен")
	# 2. Швейцария: Федеральное собрание не избирает вашу партию
	if cc == "CH":
		var g2 = load("res://main.gd").new()
		root.add_child(g2)
		for i in 5: await process_frame
		check(not g2.opp_mode, "CH стартует в правительстве")
		var lost: int = g2.seats[0]
		g2.seats[0] = 0
		g2.seats[1] += lost
		g2.hold_head_council("плановые выборы")
		g2.seats[0] = lost
		g2.seats[1] -= lost
		g2.election_continue()
		check(not g2.game_over, "непереизбрание в Федеральный совет закончило игру")
		check(g2.opp_mode and not g2.in_coalition[0], "после непереизбрания партия не в оппозиции")
		for i in 3:
			if g2.election_open: g2.election_continue()
			if not g2.current_event.is_empty(): g2.choose(0)
			g2.next_turn()
		check(not g2.game_over, "игра в оппозиции не продолжается")
		# возвращение: собрание снова избирает партию
		g2.hold_head_council("плановые выборы")
		g2.election_continue()
		check(not g2.opp_mode and g2.in_coalition[0], "после избрания в совет партия не вернулась в правительство")
		print("[CH] непереизбрание: оппозиция, затем возвращение — %s" % ("ок" if bad == 0 else "ошибки"))
	print("bad %d" % bad)
	quit()
