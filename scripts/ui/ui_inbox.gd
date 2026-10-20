# 0.57: «Входящие» — малые события не прерывают игру. Они ждут в списке на рамке «Сегодня» несколько месяцев,
# а если игрок не ответил, решаются по его принципам («как вы обычно отвечали», иначе по стилю автопилота).
extends "res://scripts/ui/ui_today.gd"

const INBOX_MONTHS := 3      # сколько месяцев письмо ждёт ответа
const INBOX_MAX := 12        # больше писем не копим: самое старое решается по принципам
const INBOX_ASK_YEAR := 10   # сколько событий с ценой в капитале в год всё-таки задают лично
const INBOX_ALWAYS_CATS := ["security", "disaster", "scandal"]

var inbox: Array = []        # [{ev, rid, t0, due}]
var inbox_year := -1
var inbox_asked := 0         # лично заданных вопросов в этом году
var inbox_bypass := false    # true — открываем письмо из списка, перенаправлять в «Входящие» не нужно
var inbox_done_month := 0    # решено по принципам за последний месяц (для сводки)


func inbox_on() -> bool:
	return bool(game_opts.get("inbox", DisplayServer.get_name() != "headless"))


# событие, которое нельзя отдавать на автомат: кризисы, цепочки, вопросы про партии и министров, дорогие решения
func inbox_important(ev: Dictionary) -> bool:
	if String(ev.get("special", "")) != "" or String(ev.get("kind", "")) != "" or bool(ev.get("chain", false)):
		return true
	if event_party >= 0 or event_min >= 0:
		return true
	if INBOX_ALWAYS_CATS.has(String(ev.get("cat", ""))):
		return true
	var big := 0.0
	for o in (ev.get("o", []) as Array):
		var fx: Dictionary = (o as Dictionary).get("fx", {})
		big = maxf(big, absf(float(fx.get("capital", 0.0))))
		if (o as Dictionary).has("next"):
			return true
	if big >= 8.0:
		return true
	if big >= 3.0:
		if year != inbox_year:
			inbox_year = year
			inbox_asked = 0
		if inbox_asked < INBOX_ASK_YEAR:
			inbox_asked += 1
			return true
	return false


# вызывается в начале present_event(): true — событие ушло во «Входящие»
func inbox_route() -> bool:
	if inbox_bypass or current_event.is_empty() or not inbox_on():
		return false
	if inbox_important(current_event):
		return false
	while inbox.size() >= INBOX_MAX:
		inbox_auto(0)
		if current_event.is_empty() == false:
			break
	var ev: Dictionary = current_event.duplicate(true)
	inbox.append({"ev": ev, "rid": event_region, "t0": turn, "due": turn + INBOX_MONTHS})
	current_event = {}
	event_region = -1
	log_tag("ВХОДЯЩИЕ", COL_TEAL, "%s — письмо: %s" % [date_text(), inbox_title(inbox[inbox.size() - 1])])
	notify_inbox()
	return true


func notify_inbox() -> void:
	pass


func inbox_title(it: Dictionary) -> String:
	var ev: Dictionary = it["ev"]
	var t: String = ev_text(String(ev.get("t", "")))
	var rid: int = int(it.get("rid", -1))
	if rid >= 0 and rid < regions.size():
		t = t.replace("{r}", String(REGIONS[rid]["name"]))
	t = coal_text(t)
	var title := String(ev.get("title", ""))
	if title != "":
		return title
	return t.left(70) + ("…" if t.length() > 70 else "")


# вариант по принципам игрока: тот, что он выбирал в прошлый раз, иначе выбор автопилота
func inbox_pick(ev: Dictionary) -> int:
	var opts: Array = ev["o"]
	var h: Dictionary = ev_hist.get(ev_id(ev), {})
	if not h.is_empty():
		var po: int = int(h.get("o", 0))
		if po < opts.size() and ev_opt_block(opts[po]) == "":
			return po
	var i: int = auto_event_pick(ev)
	if i >= opts.size() or ev_opt_block(opts[i]) != "":
		i = ev_first_ok(opts)
	return i


# решить письмо по принципам игрока; idx — номер в списке
func inbox_auto(idx: int) -> void:
	if idx < 0 or idx >= inbox.size() or not current_event.is_empty():
		return
	var it: Dictionary = inbox[idx]
	inbox.remove_at(idx)
	current_event = it["ev"]
	event_region = int(it.get("rid", -1))
	var i := inbox_pick(current_event)
	var opt: Dictionary = current_event["o"][i]
	log_tag("ВХОДЯЩИЕ", COL_TEAL, "%s — по вашим принципам: «%s».\n      %s" % [date_text(), ev_text(String(opt["l"])), inbox_title(it)])
	inbox_done_month += 1
	inbox_bypass = true
	choose(i)
	inbox_bypass = false


# открыть письмо как обычное событие и решить самому
func inbox_open(idx: int) -> void:
	if idx < 0 or idx >= inbox.size() or not current_event.is_empty():
		return
	var it: Dictionary = inbox[idx]
	inbox.remove_at(idx)
	current_event = it["ev"]
	event_region = int(it.get("rid", -1))
	inbox_bypass = true
	present_event()
	inbox_bypass = false
	refresh()


func inbox_all_auto() -> void:
	while not inbox.is_empty() and current_event.is_empty():
		inbox_auto(0)


# раз в месяц из next_turn_core: просроченные письма решаются сами
func inbox_month() -> void:
	inbox_done_month = 0
	if inbox.is_empty() or not current_event.is_empty():
		return
	var k := 0
	while k < inbox.size():
		if int((inbox[k] as Dictionary)["due"]) <= turn and current_event.is_empty():
			inbox_auto(k)
		else:
			k += 1
	if inbox_done_month > 0:
		log_tag("ВХОДЯЩИЕ", COL_TEAL, "%s — почта месяца: по принципам решено писем: %d, ждут ответа: %d." % [date_text(), inbox_done_month, inbox.size()])


func inbox_todo() -> Array:
	var out: Array = []
	if inbox.is_empty():
		return out
	out.append({"t": "[b]Входящие: %d[/b]\n[color=%s]Малые события не останавливают время. Не ответите — решатся по вашим принципам.[/color]" % [inbox.size(), COL_DIM], "btn": "Ответить на всё по принципам", "f": func() -> void:
		inbox_all_auto()
		refresh()})
	for k in mini(inbox.size(), 6):
		var it: Dictionary = inbox[k]
		var left: int = int(it["due"]) - turn
		var kk: int = k
		out.append({"t": "[b]%s[/b]\n[color=%s]%s[/color]" % [inbox_title(it), COL_DIM, ("осталось %s" % months_short(left)) if left > 0 else "сегодня решится само"],
			"btn": "Решить", "f": func() -> void: inbox_open(kk),
			"btn2": "Как обычно", "f2": func() -> void:
				inbox_auto(kk)
				refresh()})
	if inbox.size() > 6:
		out.append({"t": "[color=%s]…и ещё писем: %d[/color]" % [COL_DIM, inbox.size() - 6], "btn": "", "f": func() -> void: pass})
	return out

