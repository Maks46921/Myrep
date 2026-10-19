# 0.57: уведомления. Плашки с звуком только для важного, точки на вкладках (красная — решить сейчас, жёлтая — можно улучшить,
# серая — новое), автозамедление в кризис и условия, при которых время останавливается само. Всё настраивается в «Настройках».
extends "res://scripts/ui/ui_inbox.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func nav_extras() -> void:
	pass


# --- конец заглушек ---


# вид уведомления по метке записи журнала
const NOTIFY_TAG := {"ЗАКОН": "law", "ЗАКОНОПРОЕКТ": "bill", "КРИЗИС": "crisis", "ВЛАСТЬ": "crisis", "ГОСУДАРСТВО": "crisis", "СКАНДАЛ": "crisis",
	"ВОЙНА": "war", "ВОЕННОЕ ПОЛОЖЕНИЕ": "war", "АРМИЯ": "war", "ПАРТНЁР": "partner", "ДИПЛОМАТИЯ": "partner", "ВХОДЯЩИЕ": "inbox",
	"КОАЛИЦИЯ": "coal", "ПЕРЕГОВОРЫ": "coal", "ОППОЗИЦИЯ": "opp", "СТРОЙКА": "build", "МЕГАПРОЕКТ": "build", "НАУКА": "tech", "ТОРГОВЛЯ": "treaty", "МИР": "world"}
# [ключ, название в настройках, режим по умолчанию, куда ведёт плашка]
const NOTIFY_CLASSES := [
	["law", "Закон принят или отклонён", 3, 3], ["crisis", "Кризис, бунт, скандал", 3, 21], ["war", "Война и мир", 3, 15],
	["inbox", "Новое письмо во «Входящих»", 2, 21], ["coal", "Коалиция и переговоры", 1, 4], ["bill", "Законопроекты", 1, 1],
	["partner", "Ответы партнёров и дипломатия", 1, 18], ["opp", "Оппозиция", 0, 12], ["build", "Стройки", 0, 5],
	["tech", "Технологии", 0, 6], ["treaty", "Договоры и торговля", 0, 18], ["world", "Мир вокруг", 0, 2]]
const NOTIFY_MODES := ["Только журнал", "Значок на вкладке", "Плашка", "Плашка и звук"]
const NT_MAX_TOASTS := 4

var nt_layer: Control = null
var nt_box: VBoxContainer = null
var nt_last_text := ""
var nt_new := {}               # вкладка -> сколько новых записей с тех пор, как её открывали
var nt_dots := {}              # вкладка -> цветная точка на кнопке
var nt_crisis := false
var nt_rx: RegEx = null
var nt_hist: Array = []        # последние плашки (для тестов и поиска)


func nt_class(cls: String) -> Array:
	for c in NOTIFY_CLASSES:
		if String(c[0]) == cls:
			return c
	return []


func nt_mode(cls: String) -> int:
	var c := nt_class(cls)
	return int(game_opts.get("nt_" + cls, int(c[2]) if not c.is_empty() else 0))


func nt_plain(t: String) -> String:
	if nt_rx == null:
		nt_rx = RegEx.new()
		nt_rx.compile("\\[[^\\]]*\\]")
	return nt_rx.sub(t, "", true).replace("\n", " ").strip_edges()


# вызывается в конце log_add для каждой записи журнала
func notify_log(e: Dictionary) -> void:
	if String(e.get("k", "")) == "year":
		nt_toast("Итоги %d года готовы: смотрите журнал и рамку «Сегодня»." % int(e.get("year", 0)), "law", 21)
		return
	if String(e.get("k", "")) != "line" or not e.has("tag"):
		return
	var cls: String = String(NOTIFY_TAG.get(String(e["tag"]), ""))
	if cls == "":
		return
	var txt := nt_plain(String(e.get("t", "")))
	var low := txt.to_lower()
	# законопроекты в работе — только журнал; итог голосования — как закон
	if cls == "bill":
		if not ("провален" in low or "принят" in low or "отклон" in low):
			return
	var info := nt_class(cls)
	var desk: int = int(info[3]) if not info.is_empty() else 21
	var mode := nt_mode(cls)
	if cls == "law" and "(правительство «" in txt:
		mode = mini(mode, 1)    # законы, принятые другим правительством, — только значок
	if mode >= 1:
		var tb: int = desk_tab(desk)
		nt_new[tb] = int(nt_new.get(tb, 0)) + 1
	if mode >= 2:
		nt_toast(txt, cls, desk)
	if mode >= 3:
		sfx("bad" if cls in ["crisis", "war"] else ("good" if cls == "law" else "event"))
	nt_stop_check(cls, String(e["tag"]), low)


# условия, когда время останавливается само: итог голосования по закону, вотум и отставка, бунт и переворот, война, ультиматум
func nt_stop_check(cls: String, tag: String, low: String) -> void:
	if play_idx <= 0 or not bool(game_opts.get("stop_on", true)) or log_box == null:
		return
	var stop := false
	if tag == "ЗАКОН" or tag == "ВЛАСТЬ":
		stop = true
	elif "вотум" in low or "ультиматум" in low or "отставк" in low:
		stop = true
	elif cls == "crisis" and ("бунт" in low or "переворот" in low or "мятеж" in low or "восстани" in low):
		stop = true
	elif cls == "war" and ("объявил" in low or "началась" in low or "вторжени" in low):
		stop = true
	if stop:
		set_speed.call_deferred(0)


func build_notify_ui() -> void:
	nt_layer = Control.new()
	nt_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nt_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(nt_layer)
	nt_box = VBoxContainer.new()
	nt_box.add_theme_constant_override("separation", 6)
	nt_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nt_box.anchor_left = 1.0
	nt_box.anchor_right = 1.0
	nt_box.offset_left = -400.0
	nt_box.offset_right = -14.0
	nt_box.offset_top = ui_top_h + 52.0
	nt_layer.add_child(nt_box)
	for i in desk_buttons.size():
		var b: Button = desk_buttons[i]
		var dot := ColorRect.new()
		dot.color = C_DIM
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.custom_minimum_size = Vector2(9.0, 9.0)
		dot.size = Vector2(9.0, 9.0)
		dot.anchor_left = 1.0
		dot.anchor_right = 1.0
		dot.offset_left = -14.0
		dot.offset_right = -5.0
		dot.offset_top = 5.0
		dot.offset_bottom = 14.0
		dot.visible = false
		b.add_child(dot)
		nt_dots[i] = dot


func nt_toast(text: String, cls: String, desk: int) -> void:
	if nt_box == null or text == nt_last_text:
		return
	nt_last_text = text
	var info := nt_class(cls)
	var col: Color = C_BAD if cls in ["crisis", "war"] else (C_GOOD if cls == "law" else C_ACCENT)
	nt_hist.append(text)
	if nt_hist.size() > 30:
		nt_hist.pop_front()
	while nt_box.get_child_count() >= NT_MAX_TOASTS:
		var old := nt_box.get_child(0)
		nt_box.remove_child(old)
		old.queue_free()
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", sbox(C_PANEL2, col, 2, 8, 10.0, 6.0))
	pc.mouse_filter = Control.MOUSE_FILTER_STOP
	pc.tooltip_text = "Нажмите, чтобы открыть. Все записи — в журнале."
	var lb := Label.new()
	lb.text = text.left(150) + ("…" if text.length() > 150 else "")
	lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lb.custom_minimum_size = Vector2(340.0, 0.0)
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lb.add_theme_font_size_override("font_size", 13)
	pc.add_child(lb)
	pc.gui_input.connect(func(ev: InputEvent) -> void:
		var mb := ev as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			pc.queue_free()
			if desk >= 0:
				show_desk(desk))
	nt_box.add_child(pc)
	var tw := pc.create_tween()
	tw.tween_interval(maxf(2.0, float(game_opts.get("toast_sec", 7.0))))
	tw.tween_property(pc, "modulate:a", 0.0, 0.5)
	tw.tween_callback(pc.queue_free)
	if info.is_empty():
		return


func nt_dot_state(tab: int) -> int:
	# 0 нет, 1 серая, 2 жёлтая, 3 красная
	var st := 0
	if int(nt_new.get(tab, 0)) > 0 and desk_tab(current_desk) != tab:
		st = 1
	if tab == 6:
		if not inbox.is_empty() or not bud_changes().is_empty() or pa_props.size() > 0:
			st = 2
		if not current_event.is_empty() or coal_talks or offer_pending:
			st = 3
	elif tab == 0 and not bud_changes().is_empty():
		st = maxi(st, 2)
	elif tab == 2 and (bills.size() > 0 or pa_props.size() > 0):
		st = maxi(st, 1)
		if pa_props.size() > 0:
			st = maxi(st, 2)
		# 0.57.1: законопроект ждёт решения — жёлтая точка, голосование уже в этом или следующем месяце — красная
		for a in bills_attention():
			st = maxi(st, 3 if int(a["left"]) <= 1 and int(a["sev"]) >= 2 else 2)
	return st


func update_ui_extras() -> void:
	if nt_dots.is_empty():
		return
	nt_new[desk_tab(current_desk)] = 0
	for tab in nt_dots:
		if int(tab) >= desk_buttons.size():
			continue
		var dot: ColorRect = nt_dots[tab]
		var st := nt_dot_state(int(tab))
		dot.visible = st > 0 and (desk_buttons[int(tab)] as Control).visible
		dot.color = [C_DIM, C_DIM, C_WARN, C_BAD][st]
	nt_autoslow()
	nav_extras()


func nt_autoslow() -> void:
	var probs: Array = today_problems()
	var sev := 0.0 if probs.is_empty() else float((probs[0] as Dictionary)["sev"])
	if sev >= 70.0 and not nt_crisis:
		nt_crisis = true
		if bool(game_opts.get("autoslow", true)) and play_idx > 3:
			set_speed(3)
			nt_toast("Автозамедление: %s" % String((probs[0] as Dictionary)["t"]), "crisis", 21)
	elif sev < 50.0:
		nt_crisis = false


# страница настроек «Уведомления» (вызывается из build_settings_window)
func settings_extra_pages() -> void:
	var n := st_page("Уведомления")
	var rt := make_rt(n)
	rt.text = "[color=%s]Что показывать плашкой и звуком, а что только значком или в журнале. Всё есть в журнале в любом случае.[/color]" % COL_DIM
	for c in NOTIFY_CLASSES:
		st_option(n, String(c[1]), NOTIFY_MODES, "nt_" + String(c[0]), "", func(_i: int) -> void: pass)
		# значение по умолчанию (st_option берёт 0)
		var ob := (n.get_child(n.get_child_count() - 1).get_child(1)) as OptionButton
		ob.select(nt_mode(String(c[0])))
	st_check(n, "Останавливать время: итог голосования, вотум, бунт, война, ультиматум", "stop_on", "Время встанет само, когда случится важное.")
	st_check(n, "Замедлять время в кризис", "autoslow", "Если проблема становится острой, скорость падает до обычной.")
	var v := st_page("Вид и входящие")
	st_check(v, "Малые события приходят во «Входящие» (иначе всплывают окном)", "inbox", "Крупные события всегда спрашивают сразу.")
	st_check(v, "Всегда показывать инфляцию и безработицу вверху", "chips_all", "Обычно эти показатели появляются, только когда плохо.")
