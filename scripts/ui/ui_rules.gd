# 0.57: правила автоматики «если — то». Игрок задаёт условие, действие и предел; игра либо делает сама, либо предлагает
# принять. Предохранители: ничего не делается во время войны, не трогаются договоры, законы и конституция, за раз бюджет
# меняется не больше чем на 1% ВВП, любое действие правила можно отменить в течение месяца.
extends "res://scripts/ui/ui_nav.gd"

# показатель: [название, единица]
const RULE_INDS := {
	"infl": ["Инфляция", "%"], "unemp": ["Безработица", "%"], "debt": ["Госдолг", "% ВВП"], "def": ["Дефицит бюджета", "% ВВП"],
	"appr": ["Рейтинг власти", "%"], "cap": ["Политический капитал", ""], "res": ["Резервы", "% ВВП"], "growth": ["Рост ВВП за год", "%"],
	"unrest": ["Недовольство региона", ""],
}
const RULE_IND_ORDER := ["infl", "unemp", "debt", "def", "appr", "cap", "res", "growth", "unrest"]
const RULE_COOL := 3          # месяцев между срабатываниями одного правила
const RULE_MAX := 12
const RULE_STEP_CAP := 1.0    # предохранитель: за раз не больше 1% ВВП

var rules: Array = []         # [{ind, op, val, act, amt, mode, last, lim, used}] ; op: 0 «больше», 1 «меньше»; mode: 0 делать, 1 предложить
var rule_props: Array = []    # предложенные правилами действия, ждут «Принять»
var rule_undo: Array = []     # [{turn, kind, key, d, rid}] — что правила изменили в этом месяце
var ru_ov: Control = null
var ru_list: VBoxContainer = null
var ru_ind: OptionButton = null
var ru_op: OptionButton = null
var ru_val: SpinBox = null
var ru_act: OptionButton = null
var ru_amt: SpinBox = null
var ru_mode: OptionButton = null
var ru_acts: Array = []       # действия в выпадающем списке: [id, текст]


func rule_ind_val(ind: String) -> float:
	match ind:
		"infl": return inflation
		"unemp": return unemployment
		"debt": return debt / maxf(1.0, gdp) * 100.0
		"def": return last_deficit_pct
		"appr": return approval()
		"cap": return capital
		"res": return float(ec.get("res", 10.0)) if not ec.is_empty() else 10.0
		"growth": return growth
	return 0.0


# список действий: изменить статью бюджета на amt п.п. ВВП, дать грант регионам с недовольством
func rule_actions() -> Array:
	var out: Array = []
	for d in POLICY:
		var k := String(d["key"])
		if k == "emit":
			continue
		out.append(["up:" + k, "Поднять: " + policy_title(k)])
		out.append(["dn:" + k, "Снизить: " + policy_title(k)])
	out.append(["grant", "Трансферт региону с недовольством (+)"])
	return out


func rule_act_title(id: String) -> String:
	for a in rule_actions():
		if String(a[0]) == id:
			return String(a[1])
	return id


func rule_text(r: Dictionary) -> String:
	var ind: Array = RULE_INDS.get(String(r["ind"]), ["?", ""])
	var cond := "%s %s %s%s" % [String(ind[0]), "больше" if int(r["op"]) == 0 else "меньше", ("%.1f" % float(r["val"])).replace(".0", ""), (" " + String(ind[1])) if String(ind[1]) != "" else ""]
	return "Если %s → %s на %.2f п.п. ВВП (%s)" % [cond.to_lower(), rule_act_title(String(r["act"])).to_lower(), float(r["amt"]), "сама" if int(r["mode"]) == 0 else "предложить"]


func rule_cond_ok(r: Dictionary) -> bool:
	var ind := String(r["ind"])
	if ind == "unrest":
		return not rule_hot_regions(float(r["val"]), int(r["op"])).is_empty()
	var v := rule_ind_val(ind)
	return v > float(r["val"]) if int(r["op"]) == 0 else v < float(r["val"])


func rule_hot_regions(lim: float, op: int) -> Array:
	var out: Array = []
	for i in regions.size():
		var u: float = float(regions[i].get("unrest", 0.0))
		if (u > lim) if op == 0 else (u < lim):
			out.append(i)
	out.sort_custom(func(a: int, b: int) -> bool: return float(regions[a].get("unrest", 0.0)) > float(regions[b].get("unrest", 0.0)))
	return out.slice(0, 3)


# вызывается раз в месяц из next_turn_core (после автопилота)
func rules_month() -> void:
	if rules.is_empty() and rule_props.is_empty():
		return
	while not rule_undo.is_empty() and turn - int((rule_undo[0] as Dictionary)["turn"]) > 1:
		rule_undo.pop_front()
	if opp_mode or observer or game_over or mil_at_war():
		return
	for r in rules:
		var rr: Dictionary = r
		if turn - int(rr.get("last", -99)) < RULE_COOL or not rule_cond_ok(rr):
			continue
		rr["last"] = turn
		if int(rr["mode"]) == 1:
			if rule_props.size() < 6 and not rule_prop_has(String(rr["act"])):
				rule_props.append({"act": String(rr["act"]), "amt": float(rr["amt"]), "why": rule_text(rr)})
				log_tag("АВТОПИЛОТ", COL_TEAL, "%s — правило предлагает: %s." % [date_text(), rule_text(rr)])
		else:
			rule_do(String(rr["act"]), float(rr["amt"]), rule_text(rr), rr)


func rule_prop_has(act: String) -> bool:
	for p in rule_props:
		if String((p as Dictionary)["act"]) == act:
			return true
	return false


func rule_do(act: String, amt: float, why: String, rr: Dictionary = {}) -> void:
	amt = clampf(amt, 0.0, RULE_STEP_CAP)
	if act == "grant":
		var cond_lim := float(rr.get("val", 70.0))
		var hot: Array = rule_hot_regions(cond_lim, int(rr.get("op", 0)))
		for i in hot:
			tr_shift(i, amt)
			rule_undo.append({"turn": turn, "kind": "grant", "key": "", "d": amt, "rid": i})
		if not hot.is_empty():
			log_tag("АВТОПИЛОТ", COL_TEAL, "%s — %s: трансферт +%.2f%% ВВП получили регионов: %d." % [date_text(), why, amt, hot.size()])
		return
	var up: bool = act.begins_with("up:")
	var key: String = act.substr(3)
	if not policy_by_key.has(key):
		return
	var d: float = amt if up else -amt
	var old: float = float(pol[key])
	var nv: float = clampf(old + d, 0.0, pol_hi(key))
	if absf(nv - old) < 0.001 or lock_active(key):
		return
	if bud_base.has(key):
		bud_base[key][0] = clampf(float(bud_base[key][0]) + (nv - old), 0.0, pol_hi(key))
	set_policy(key, nv)
	rule_undo.append({"turn": turn, "kind": "pol", "key": key, "d": nv - old, "rid": -1})
	log_tag("АВТОПИЛОТ", COL_TEAL, "%s — %s: «%s» %.1f → %.1f%% ВВП." % [date_text(), why, policy_title(key), old, nv])


func rule_accept(idx: int) -> void:
	if idx < 0 or idx >= rule_props.size():
		return
	var p: Dictionary = rule_props[idx]
	rule_props.remove_at(idx)
	rule_do(String(p["act"]), float(p["amt"]), String(p["why"]))
	refresh()


func rule_reject(idx: int) -> void:
	if idx >= 0 and idx < rule_props.size():
		rule_props.remove_at(idx)
	refresh()


func rules_undo_last() -> void:
	for u in rule_undo:
		var us: Dictionary = u
		if String(us["kind"]) == "pol":
			var key := String(us["key"])
			var nv: float = clampf(float(pol[key]) - float(us["d"]), 0.0, pol_hi(key))
			if bud_base.has(key):
				bud_base[key][0] = clampf(float(bud_base[key][0]) - float(us["d"]), 0.0, pol_hi(key))
			set_policy(key, nv)
		else:
			tr_shift(int(us["rid"]), -float(us["d"]))
	if not rule_undo.is_empty():
		log_tag("АВТОПИЛОТ", COL_TEAL, "%s — действия правил за этот месяц отменены." % date_text())
	rule_undo.clear()
	refresh()


# карточки для рамки «Сегодня»
func rules_todo() -> Array:
	var out: Array = []
	for k in rule_props.size():
		var kk: int = k
		var p: Dictionary = rule_props[k]
		out.append({"t": "[b]Правило предлагает[/b]\n[color=%s]%s[/color]" % [COL_DIM, String(p["why"])], "btn": "Принять", "f": func() -> void: rule_accept(kk),
			"btn2": "Отклонить", "f2": func() -> void: rule_reject(kk)})
	if not rule_undo.is_empty():
		out.append({"t": "[b]Правила что-то изменили в этом месяце[/b]\n[color=%s]Отменить можно до конца месяца.[/color]" % COL_DIM, "btn": "Отменить", "f": func() -> void: rules_undo_last()})
	return out


# ---------- окно ----------
func rules_open(on: bool) -> void:
	if on and ru_ov == null:
		rules_build()
	if ru_ov == null:
		return
	ru_ov.visible = on
	if on:
		ru_ov.move_to_front()
		rules_fill()


func rules_build() -> void:
	ru_ov = Control.new()
	ru_ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ru_ov.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(ru_ov)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		var mb := ev as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			rules_open(false))
	ru_ov.add_child(dim)
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", sbox(C_PANEL, C_ACCENT.darkened(0.2), 2, 12, 16.0, 12.0))
	pan.anchor_left = 0.5
	pan.anchor_right = 0.5
	pan.anchor_top = 0.5
	pan.anchor_bottom = 0.5
	pan.offset_left = -420.0
	pan.offset_right = 420.0
	pan.offset_top = -330.0
	pan.offset_bottom = 330.0
	ru_ov.add_child(pan)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	pan.add_child(vb)
	var hd := HBoxContainer.new()
	vb.add_child(hd)
	var tl := Label.new()
	tl.text = "Автоматика: правила «если — то»"
	tl.add_theme_font_size_override("font_size", 20)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hd.add_child(tl)
	var cl := Button.new()
	cl.text = "✕ Закрыть"
	cl.focus_mode = Control.FOCUS_NONE
	cl.pressed.connect(func() -> void: rules_open(false))
	hd.add_child(cl)
	var rt := make_rt(vb)
	rt.text = "[color=%s]Игра следит за показателями и действует по вашим правилам. Во время войны правила молчат, договоры, законы и конституция им недоступны, за раз бюджет меняется не больше чем на 1%% ВВП. Действия правил можно отменить на рамке «Сегодня» до конца месяца.[/color]" % COL_DIM
	# области автопилота
	add_title(vb, "Автопилот по областям")
	var defs := [
		["bal", "Автобаланс бюджета: подстраивать налоги к цели по дефициту", "Раз в месяц правит налоги, если дефицит далёк от цели."],
		["repair", "Авторемонт сооружений", "Ремонтирует сооружения при износе выше нормы, если долг не слишком высок."],
		["build", "Автостроительство мощностей", "Стартует стройку, когда рынку не хватает мощностей."],
		["events", "Все события по моим принципам (без вопросов)", "Ни одно событие не спрашивает: выбор как у автопилота. Крупные решения тоже отдаются игре!"],
	]
	for d in defs:
		var cb := CheckButton.new()
		cb.text = String(d[1])
		cb.tooltip_text = String(d[2])
		cb.focus_mode = Control.FOCUS_NONE
		cb.button_pressed = bool(ap.get(String(d[0]), false))
		var key: String = String(d[0])
		cb.toggled.connect(func(on: bool) -> void:
			if pl_deny():
				cb.set_pressed_no_signal(not on)
				return
			ap[key] = on
			refresh())
		vb.add_child(cb)
	add_title(vb, "Мои правила")
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(sc)
	ru_list = VBoxContainer.new()
	ru_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ru_list.add_theme_constant_override("separation", 4)
	sc.add_child(ru_list)
	add_title(vb, "Новое правило")
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 6)
	vb.add_child(row)
	var l1 := Label.new()
	l1.text = "Если"
	row.add_child(l1)
	ru_ind = OptionButton.new()
	ru_ind.focus_mode = Control.FOCUS_NONE
	for k in RULE_IND_ORDER:
		ru_ind.add_item(String((RULE_INDS[k] as Array)[0]))
	row.add_child(ru_ind)
	ru_op = OptionButton.new()
	ru_op.focus_mode = Control.FOCUS_NONE
	ru_op.add_item("больше")
	ru_op.add_item("меньше")
	row.add_child(ru_op)
	ru_val = SpinBox.new()
	ru_val.min_value = -100.0
	ru_val.max_value = 1000.0
	ru_val.step = 0.5
	ru_val.value = 5.0
	row.add_child(ru_val)
	var l2 := Label.new()
	l2.text = "то"
	row.add_child(l2)
	ru_act = OptionButton.new()
	ru_act.focus_mode = Control.FOCUS_NONE
	ru_acts = rule_actions()
	for a in ru_acts:
		ru_act.add_item(String(a[1]))
	row.add_child(ru_act)
	var l3 := Label.new()
	l3.text = "на"
	row.add_child(l3)
	ru_amt = SpinBox.new()
	ru_amt.min_value = 0.05
	ru_amt.max_value = RULE_STEP_CAP
	ru_amt.step = 0.05
	ru_amt.value = 0.2
	ru_amt.suffix = "п.п. ВВП"
	ru_amt.custom_minimum_size = Vector2(170.0, 0.0)
	row.add_child(ru_amt)
	ru_mode = OptionButton.new()
	ru_mode.focus_mode = Control.FOCUS_NONE
	ru_mode.add_item("делать сама")
	ru_mode.add_item("предложить мне")
	row.add_child(ru_mode)
	var add := Button.new()
	add.text = "+ Добавить правило"
	add.focus_mode = Control.FOCUS_NONE
	add.pressed.connect(rule_add_from_form)
	vb.add_child(add)
	polish_tree(ru_ov)


func rule_add_from_form() -> void:
	var ind: String = String(RULE_IND_ORDER[ru_ind.selected])
	var act: String = String((ru_acts[ru_act.selected] as Array)[0])
	if (ind == "unrest") != (act == "grant"):
		nt_toast("Недовольство региона сочетается только с трансфертом региону, и наоборот.", "inbox", -1)
		return
	if rules.size() >= RULE_MAX:
		return
	rules.append({"ind": ind, "op": ru_op.selected, "val": ru_val.value, "act": act, "amt": ru_amt.value, "mode": ru_mode.selected, "last": -99})
	rules_fill()


func rules_fill() -> void:
	if ru_list == null:
		return
	for ch in ru_list.get_children():
		ru_list.remove_child(ch)
		ch.queue_free()
	if rules.is_empty():
		var l := Label.new()
		l.text = "Правил пока нет. Например: «Если инфляция больше 6% → снизить: Госаппарат на 0.2 п.п. ВВП»."
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ru_list.add_child(l)
	for k in rules.size():
		var kk: int = k
		var hb := HBoxContainer.new()
		ru_list.add_child(hb)
		var l2 := Label.new()
		l2.text = rule_text(rules[k])
		l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(l2)
		var del := Button.new()
		del.text = "✕"
		del.focus_mode = Control.FOCUS_NONE
		del.pressed.connect(func() -> void:
			rules.remove_at(kk)
			rules_fill())
		hb.add_child(del)
