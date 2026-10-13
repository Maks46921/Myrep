extends SceneTree
# v53_1: мировые санкции и путь их снятия, новые пункты мирного договора, события только для членов организаций.
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	var bad := 0
	for i in 2:
		if not g.current_event.is_empty(): g.choose(0)
		g.next_turn()
	if not g.fa_on():
		print("модуль «Государство и мир» выключен — пропуск")
		print("мир: проблем 0")
		quit()
		return
	var lvl0: int = g.fa_ws_lvl()
	var exp0: int = {"RU": 3, "BY": 2}.get(g.ccode, 0)
	if lvl0 != exp0:
		bad += 1; print("FAIL: стартовый уровень санкций %d, ожидали %d" % [lvl0, exp0])
	# события об организациях — только членам
	for pair in [["НАТО", "nato"], ["ОДКБ", "csto"], ["Саммит ЕС", "eu"]]:
		var blocked: bool = g.ev_org_blocked("Тест: %s обсуждает бюджет." % pair[0])
		if blocked == g.io_member(pair[1]):
			bad += 1; print("FAIL: событие «%s» при членстве %s: заблокировано %s" % [pair[0], g.io_member(pair[1]), blocked])
	for o in g.dip_summit_orgs():
		if not g.io_member(String(o)):
			bad += 1; print("FAIL: саммит организации %s, а страна не член" % o)
	# все пункты мирного договора знают текст и цену
	for id in g.TALK_IDS + g.TALK_GIVE:
		if not g.TALK_INFO.has(id):
			bad += 1; print("FAIL: нет описания пункта %s" % id)
	# путь снятия санкций у агрессора: мир с признанием границ и компенсацией → переговоры снижают уровень
	if g.mil_at_war() and g.war_aggressor() == g.ccode:
		var sel: Dictionary = g.talk_sel()
		sel.clear()
		sel["pow"] = true
		sel["comp"] = true
		if g.talk_avail("recog") == "":
			sel["recog"] = true
		var q: Dictionary = g.talk_quote()
		var t: Dictionary = g.talk_terms(q["pkg"])
		g.mil_peace("annex" if t.has("land") or t.has("border") else "white", t)
		g.next_turn()
		if g.mil_at_war():
			bad += 1; print("FAIL: война не закончилась")
		if g.fa_ws_lvl() < lvl0:
			bad += 1; print("FAIL: санкции исчезли сами с концом войны")
		var ok: Dictionary = {}
		for c in g.fa_ws_conds():
			ok[c[0]] = c[2]
		if not ok["war"] or not ok["comp"] or (sel.has("recog") and not ok["border"]):
			bad += 1; print("FAIL: условия после мира ", ok)
		g.capital = 50.0
		g.current_event = {}
		var was: int = g.fa_ws_lvl()
		g.fa_ws_do("ws_talks")
		if bool(g.fa_ws_step_ok()[0]) and g.fa_ws_lvl() >= was and was > 0:
			bad += 1; print("FAIL: условия выполнены, но переговоры не сняли ступень")
		print("  %s: после мира и переговоров уровень %d → %d" % [g.ccode, was, g.fa_ws_lvl()])
	# окно и действия не падают
	var txt: String = g.fa_ws_text()
	if txt == "":
		bad += 1; print("FAIL: пустой текст окна «Мир и санкции»")
	g.capital = 50.0
	var gd := 0
	while not g.current_event.is_empty() and gd < 8:
		g.choose(0)
		gd += 1
	g.current_event = {}
	if not g.fa_ws_do("ws_diplo"):
		bad += 1; print("FAIL: дипломатическое наступление не сработало")
	for m in 12:
		if not g.current_event.is_empty(): g.choose(0)
		g.next_turn()
	print("%s: санкции %d, отношение мира %.0f" % [g.ccode, g.fa_ws_lvl(), g.fa_world()])
	print("мир: проблем %d" % bad)
	quit()
