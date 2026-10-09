extends SceneTree
# v35: совет коалиции (события, кабинет, бюджет младшего партнёра), выход из кризиса, «кордон».
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
	# коалиция минимум из двух партий
	if g.coal_members().size() < 2:
		for p in range(1, g.PARTY_NAMES.size()):
			if g.can_govern(p) and g.seats[p] > 0:
				g.add_member(p)
				break
	check(g.council_on(), "совет коалиции работает при 2+ партиях")
	var sh := 0.0
	for p in g.coal_members():
		sh += g.coal_share(p)
	check(absf(sh - 1.0) < 0.001, "доли влияния в сумме 100%% (%.3f)" % sh)
	# событие: затраты капитала делятся по влиянию
	var partner := -1
	for p in g.coal_members():
		if p != 0:
			partner = p
	g.capital = 50.0
	var pc0: float = float(g.pcap[partner])
	g.current_event = {"t": "тест", "o": [{"l": "дорого", "fx": {"capital": -10.0}}, {"l": "дорого тоже", "fx": {"capital": -10.0}}]}
	g.event_party = -1
	g.present_event()
	check(g.council_event_note(0) != "", "у варианта есть подсказка совета")
	g.choose(0)
	var paid: float = 50.0 - g.capital
	check(absf(paid - 10.0 * g.coal_share(0)) < 0.3, "вы платите свою долю (%.2f из 10, доля %.2f)" % [paid, g.coal_share(0)])
	check(float(g.pcap[partner]) < pc0 or pc0 <= 0.0, "партнёр тоже платит")
	# дальше — коалиция ровно из двух партий: вы и крупнейший партнёр
	partner = -1
	for p in g.coal_members():
		if p != 0 and (partner < 0 or g.seats[p] > g.seats[partner]):
			partner = p
	for p in g.coal_members():
		if p != 0 and p != partner:
			g.remove_member(p)
	g.assign_ministries()
	# большинство партнёров может переиграть младшего партнёра
	var s0: int = g.seats[0]
	g.seats[0] = 5
	g.pm_lead = false          # v38: в Румынии и Боснии игрок на старте глава правительства при меньшей партии
	check(g.coal_share(0) < 0.5, "игрок — младший партнёр")
	check(bool(g.junior_info()["junior"]), "junior_info видит младшего партнёра")
	# бюджет младшего партнёра: лимита на ползунок больше нет
	var k := "edu"
	var v0: float = g.pol[k]
	g.prev_pol = g.pol.duplicate()
	var hi: float = g.lock_allowed(k, v0 + 2.0)
	check(hi >= v0 + 1.99, "у младшего партнёра нет ограничения ползунка (%.2f → %.2f)" % [v0, hi])
	g.set_policy(k, v0 + 2.0)
	g.council_budget()
	var st: float = g.ideo_stance(partner, k)
	if st > -0.2:
		check(absf(float(g.pol[k]) - (v0 + 2.0)) < 0.01, "совет одобрил изменение, которое партнёру не противно")
	else:
		check(absf(float(g.pol[k]) - v0) < 0.01, "совет отклонил изменение и вернул ползунок")
	# министерство: при доле < 50% без согласия партнёра не передать
	var m := -1
	for i in g.MINISTRIES.size():
		if g.ministries[i] == partner:
			m = i
	if m >= 0:
		g.assign_ministry(m, 0)
		check(g.ministries[m] == partner, "партнёр-большинство не отдал своё министерство")
	g.seats[0] = s0
	# «кордон»: с бывшими «несговорчивыми» можно договариваться
	var cp := -1
	for p in range(1, g.PARTY_NAMES.size()):
		if g.is_cordon(p) and g.can_govern(p):
			cp = p
	if cp > 0:
		check(g.willingness(cp, false) > -60.0, "у партии за кордоном готовность не «никогда» (%.0f)" % g.willingness(cp, false))
		check(g.pact_can(cp, "talk") != "партия не заключает соглашений", "с партией за кордоном можно вести переговоры")
		g.deadlock = 3
		var w3: float = g.willingness(cp, false)
		g.deadlock = 0
		check(w3 > g.willingness(cp, false) + 10.0, "затяжной кризис смягчает кордон")
	# кризис: вместо роспуска — событие с путями выхода
	for p in range(1, g.PARTY_NAMES.size()):
		if g.in_coalition[p]:
			g.remove_member(p)
	if not g.gov_ok():
		g.crisis_months = g.crisis_limit() - 1
		g.check_government()
		check(String(g.current_event.get("special", "")) == "crisis", "показан выбор выхода из кризиса")
		var n: int = (g.current_event["o"] as Array).size()
		check(n >= 2, "есть хотя бы техническое правительство и выборы")
		g.choose(0)
		check(g.gov_ok(), "после выбора правительство работает")
	print("t_council: проблем ", bad)
	quit(1 if bad > 0 else 0)
