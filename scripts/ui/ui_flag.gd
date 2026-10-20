# 0.59: государство и флаг. Окно «Государство» (флаг «на ветру», название по истории, форма правления, столица), выбор флага
# из исторических (data/flags.dat), редактор своего флага и вопрос о смене флага, когда меняется строй.
extends "res://scripts/ui/ui_rules.gd"

const FLAG_TPL := ["Две полосы (горизонтально)", "Три полосы (горизонтально)", "Три полосы (вертикально)", "Скандинавский крест", "Прямой крест",
	"Косой крест", "Деление по диагонали", "Кантон (угол) и поле", "Треугольник у древка", "Круг по центру"]
const FLAG_SYM := ["Звезда", "Три звезды", "Круг", "Кольцо", "Полумесяц", "Солнце", "Крест", "Серп и молот", "Орёл", "Корона", "Щит"]
const FLAG_SYMPOS := ["По центру", "В углу у древка", "У древка по центру"]
const FLAG_WAVE := "shader_type canvas_item;
uniform float amp = 0.030;
uniform float freq = 7.0;
uniform float spd = 1.5;
void fragment() {
	vec2 uv = UV;
	float ph = uv.x * freq - TIME * spd;
	uv.y += sin(ph) * amp * uv.x;
	uv.x += cos(ph * 0.7 + 1.0) * amp * 0.35 * uv.x;
	vec4 c = texture(TEXTURE, clamp(uv, vec2(0.0), vec2(1.0)));
	float shade = 1.0 + cos(ph) * 0.11 * uv.x;
	COLOR = vec4(c.rgb * shade, c.a);
}"



# ---------- идеологии строя и подбор флага ----------
func flag_tags_now() -> Array:
	var rid := regime_id()
	var econ := econ_id()
	if rid_of("state_church") == "theocracy":
		return ["Теократия"]
	match rid:
		"monarchy_const", "monarchy_abs":
			return ["Монархия"]
		"junta":
			return ["Хунта"]
		"dictatorship":
			return ["Коммунизм", "Однопартийное"] if econ == "planned" else ["Нацизм/фашизм", "Однопартийное", "Хунта"]
		"oneparty":
			return ["Коммунизм", "Социализм", "Однопартийное"] if econ == "planned" else ["Однопартийное", "Нацизм/фашизм"]
		"direct_dem":
			return ["Прямая демократия", "Демократия"]
	if rid_of("state_structure") == "confed":
		return ["Конфедерация", "Демократия"]
	match econ:
		"planned":
			return ["Социализм", "Коммунизм"]
		"coop":
			return ["Социализм", "Демократия"]
		"libertarian":
			return ["Либерализм", "Демократия"]
	return ["Демократия"]


func flag_cur_id() -> String:
	if flag_id != "" and not Flags.entry(flag_id).is_empty():
		return flag_id
	return Flags.default_id(ccode)


# подходящие строю флаги страны: сначала по первой идеологии, потом по остальным; внутри — настоящие, потом новее
func flag_candidates(tags: Array) -> Array:
	var out: Array = []
	var seen := {}
	for t in tags:
		var part: Array = []
		for e in Flags.entries(ccode):
			if String(t) in (e["ideo"] as Array) and not seen.has(String(e["id"])):
				part.append(e)
		part.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var ra: int = 0 if String(a["src"]) == "реальный" else 1
			var rb: int = 0 if String(b["src"]) == "реальный" else 1
			if ra != rb:
				return ra < rb
			return int(a["y0"]) > int(b["y0"]))
		for e in part:
			seen[String(e["id"])] = true
			out.append(e)
	for id in flag_custom:
		var ce: Dictionary = flag_custom[id]
		if not seen.has(String(id)):
			out.append(ce)
	return out


func flag_pick_auto(tags: Array) -> String:
	for t in tags:
		var best := ""
		var by := -1
		for e in Flags.entries(ccode):
			if String(t) in (e["ideo"] as Array) and String(e["src"]) == "реальный":
				if int(e["y1"]) == 0:
					return String(e["id"])
				if int(e["y0"]) > by:
					by = int(e["y0"])
					best = String(e["id"])
		if best != "":
			return best
	return ""


func flag_title() -> String:
	var base: String = String(WORLD[ccode]["name"]) if WORLD.has(ccode) else ccode
	var id := flag_cur_id()
	var e: Dictionary = Flags.entry(id)
	if e.is_empty() or id == Flags.default_id(ccode) or int(e.get("y1", 0)) == 0:
		return base
	return String(e["regime"])


func flag_sync() -> void:
	Flags.custom = flag_custom
	Flags.cur = {}
	Flags.cur[ccode] = flag_cur_id()
	for cc in flag_ai:
		Flags.cur[cc] = flag_ai[cc]


func flag_set(id: String, why: String, tags: Array = []) -> void:
	if id == "" or Flags.entry(id).is_empty():
		return
	var old := flag_cur_id()
	flag_id = id
	var tg: Array = tags if not tags.is_empty() else flag_tags_now()
	flag_by_tag[String(tg[0])] = id
	flag_hist.append({"turn": turn, "id": id, "why": why})
	flag_sync()
	if old != id:
		var e: Dictionary = Flags.entry(id)
		log_tag("ФЛАГ", COL_TEAL, "Флаг страны изменён: %s (%s). %s" % [String(e["name"]), why, String(e["regime"]) if int(e.get("y1", 0)) != 0 else ""])
	flag_top_refresh()


# раз в месяц: изменился строй — вопрос о смене флага (без окна на экране ничего не блокируется)
func flag_month() -> void:
	if not Flags.db_has(ccode):
		return
	var tags := flag_tags_now()
	if flag_tags_last.is_empty():
		flag_tags_last = tags
		return
	if tags == flag_tags_last:
		return
	var old_tags := flag_tags_last
	flag_tags_last = tags
	# для этого строя у вас уже есть выбранный флаг — ставим его сами
	if flag_by_tag.has(String(tags[0])) and not Flags.entry(String(flag_by_tag[String(tags[0])])).is_empty():
		flag_set(String(flag_by_tag[String(tags[0])]), "ваш флаг для этого строя", tags)
		return
	var pick := flag_pick_auto(tags)
	if pick == "" or pick == flag_cur_id():
		return
	flag_pending = {"tags": tags, "old": old_tags, "pick": pick, "turn": turn}
	var txt := "Строй страны изменился (%s). Сменить флаг? Откройте окно «Государство» (щелчок по флагу слева вверху)." % String(tags[0]).to_lower()
	log_tag("ФЛАГ", COL_TEAL, txt)
	if not flag_ask:
		flag_pending = {}
		return
	nt_toast(txt, "inbox", 0)
	flag_top_refresh()


func flag_top_refresh() -> void:
	if top_flag != null and Flags.has(ccode):
		top_flag.texture = Flags.tex(ccode)
		var cbtn: Control = top_flag.get_parent() as Control
		if cbtn != null:
			if fl_dot == null or not is_instance_valid(fl_dot):
				fl_dot = ColorRect.new()
				fl_dot.color = Color(1.0, 0.78, 0.25)
				fl_dot.custom_minimum_size = Vector2(9.0, 9.0)
				fl_dot.size = Vector2(9.0, 9.0)
				fl_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
				fl_dot.set_anchors_preset(Control.PRESET_TOP_RIGHT)
				fl_dot.offset_left = -12.0
				fl_dot.offset_top = 3.0
				fl_dot.offset_right = -3.0
				fl_dot.offset_bottom = 12.0
				cbtn.add_child(fl_dot)
			fl_dot.visible = not flag_pending.is_empty()
			cbtn.tooltip_text = "%s: государство и флаг%s" % [flag_title(), " (строй изменился: можно сменить флаг)" if not flag_pending.is_empty() else ""]


# ---------- окно «Государство» ----------
func flag_win_open(on: bool) -> void:
	if on and fl_ov == null:
		flag_win_build()
	if fl_ov == null:
		return
	fl_ov.visible = on
	if on:
		fl_ov.move_to_front()
		fl_view = 1 if not flag_pending.is_empty() else 0
		fl_pick = flag_cur_id()
		fl_all = false
		flag_win_fill()


func flag_win_build() -> void:
	fl_ov = Control.new()
	fl_ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fl_ov.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fl_ov)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		var mb := ev as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			flag_win_open(false))
	fl_ov.add_child(dim)
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", sbox(C_PANEL, C_ACCENT.darkened(0.2), 2, 12, 16.0, 12.0))
	pan.anchor_left = 0.5
	pan.anchor_right = 0.5
	pan.anchor_top = 0.5
	pan.anchor_bottom = 0.5
	pan.offset_left = -400.0
	pan.offset_right = 400.0
	pan.offset_top = -320.0
	pan.offset_bottom = 320.0
	fl_ov.add_child(pan)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	pan.add_child(vb)
	var hd := HBoxContainer.new()
	vb.add_child(hd)
	var tl := Label.new()
	tl.text = "Государство"
	tl.add_theme_font_size_override("font_size", 22)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hd.add_child(tl)
	var cl := Button.new()
	cl.text = "✕ Закрыть"
	cl.focus_mode = Control.FOCUS_NONE
	cl.pressed.connect(func() -> void: flag_win_open(false))
	hd.add_child(cl)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(sc)
	fl_body = VBoxContainer.new()
	fl_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fl_body.add_theme_constant_override("separation", 10)
	sc.add_child(fl_body)
	polish_tree(fl_ov)


func flag_form_name() -> String:
	if not law_index.has("gov_form"):
		return "республика"
	var v: Dictionary = variant_of("gov_form", cur_idx("gov_form"))
	return String(v.get("n", "республика"))


func flag_wave_rect(id: String, wide: float) -> Control:
	var e: Dictionary = Flags.entry(id)
	var w: float = float(e.get("w", 90.0))
	var h: float = wide * 60.0 / w
	var tr := TextureRect.new()
	tr.texture = Flags.real_id(id)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.custom_minimum_size = Vector2(wide, h)
	tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if fl_mat == null:
		var sh := Shader.new()
		sh.code = FLAG_WAVE
		fl_mat = ShaderMaterial.new()
		fl_mat.shader = sh
	if DisplayServer.get_name() != "headless":
		tr.material = fl_mat
	return tr


func flag_win_fill() -> void:
	if fl_body == null:
		return
	for c in fl_body.get_children():
		c.queue_free()
	var id := flag_cur_id()
	var e: Dictionary = Flags.entry(id)
	# --- шапка: флаг и сведения ---
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	fl_body.add_child(top)
	var fbox := CenterContainer.new()
	fbox.custom_minimum_size = Vector2(300.0, 200.0)
	top.add_child(fbox)
	if not e.is_empty():
		fbox.add_child(flag_wave_rect(id, 280.0))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(info)
	var rt := make_rt(info)
	var tg := flag_tags_now()
	var t := "[font_size=24][b]%s[/b][/font_size]\n" % flag_title()
	t += "[color=%s]Форма правления:[/color] %s\n" % [COL_DIM, flag_form_name()]
	t += "[color=%s]Идеология строя:[/color] %s\n" % [COL_DIM, ", ".join(PackedStringArray(tg))]
	t += "[color=%s]Столица:[/color] %s\n" % [COL_DIM, String(WORLD[ccode].get("cap", "?")) if WORLD.has(ccode) else "?"]
	if not e.is_empty():
		var y1: int = int(e.get("y1", 0))
		t += "[color=%s]Флаг:[/color] %s" % [COL_DIM, String(e["name"])]
		if int(e.get("y0", 0)) > 0:
			t += " (%d–%s)" % [int(e["y0"]), str(y1) if y1 > 0 else "н. в."]
		t += "\n[color=%s]%s[/color]" % [COL_FAINT_HEX, String(e.get("note", ""))]
	rt.text = t
	# --- вопрос о смене флага после смены строя ---
	if not flag_pending.is_empty():
		var pe: Dictionary = Flags.entry(String(flag_pending["pick"]))
		var q := PanelContainer.new()
		q.add_theme_stylebox_override("panel", sbox(C_PANEL2, Color(1.0, 0.78, 0.25), 2, 8, 12.0, 10.0))
		fl_body.add_child(q)
		var qv := VBoxContainer.new()
		qv.add_theme_constant_override("separation", 6)
		q.add_child(qv)
		var qt := make_rt(qv)
		qt.text = "[b]Строй изменился: %s.[/b] Сменить флаг? Для этого строя подходит «%s»." % [String(flag_pending["tags"][0]).to_lower(), String(pe.get("name", "?"))]
		var qb := HBoxContainer.new()
		qb.add_theme_constant_override("separation", 6)
		qv.add_child(qb)
		var b1 := Button.new()
		b1.text = "Оставить прежний"
		b1.focus_mode = Control.FOCUS_NONE
		b1.pressed.connect(func() -> void:
			flag_pending = {}
			flag_top_refresh()
			flag_win_fill())
		qb.add_child(b1)
		var b2 := Button.new()
		b2.text = "Флаг нового строя"
		b2.focus_mode = Control.FOCUS_NONE
		b2.pressed.connect(func() -> void:
			var pk: String = String(flag_pending["pick"])
			var tgs: Array = flag_pending["tags"]
			flag_pending = {}
			flag_set(pk, "смена строя", tgs)
			fl_pick = pk
			flag_win_fill())
		qb.add_child(b2)
		var b3 := Button.new()
		b3.text = "Все варианты"
		b3.focus_mode = Control.FOCUS_NONE
		b3.pressed.connect(func() -> void:
			fl_view = 1
			fl_all = false
			flag_win_fill())
		qb.add_child(b3)
		var b4 := Button.new()
		b4.text = "Редактор флага"
		b4.focus_mode = Control.FOCUS_NONE
		b4.pressed.connect(func() -> void:
			flag_pending = {}
			flag_editor_open(true))
		qb.add_child(b4)
		var ck := CheckBox.new()
		ck.text = "Спрашивать при смене строя"
		ck.button_pressed = flag_ask
		ck.focus_mode = Control.FOCUS_NONE
		ck.toggled.connect(func(on: bool) -> void: flag_ask = on)
		qv.add_child(ck)
	# --- кнопки ---
	var br := HBoxContainer.new()
	br.add_theme_constant_override("separation", 8)
	fl_body.add_child(br)
	var bs := Button.new()
	bs.text = "Сменить флаг" if fl_view == 0 else "Скрыть список флагов"
	bs.focus_mode = Control.FOCUS_NONE
	bs.pressed.connect(func() -> void:
		fl_view = 1 - fl_view
		flag_win_fill())
	br.add_child(bs)
	var be := Button.new()
	be.text = "Редактор флага"
	be.focus_mode = Control.FOCUS_NONE
	be.pressed.connect(func() -> void: flag_editor_open(true))
	br.add_child(be)
	# --- выбор флага ---
	if fl_view == 1:
		var cand: Array = flag_candidates(flag_tags_now()) if not fl_all else Flags.entries(ccode).duplicate()
		if fl_all:
			for cid in flag_custom:
				cand.append(flag_custom[cid])
		var hr := HBoxContainer.new()
		fl_body.add_child(hr)
		var ht := Label.new()
		ht.text = "Подходящие строю" if not fl_all else "Все флаги страны"
		ht.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ht.add_theme_color_override("font_color", C_ACCENT.lightened(0.18))
		hr.add_child(ht)
		var ca := CheckBox.new()
		ca.text = "Показать все флаги страны"
		ca.button_pressed = fl_all
		ca.focus_mode = Control.FOCUS_NONE
		ca.toggled.connect(func(on: bool) -> void:
			fl_all = on
			flag_win_fill())
		hr.add_child(ca)
		if cand.is_empty():
			var ne := make_rt(fl_body)
			ne.text = "[color=%s]Для этого строя в истории страны флага нет. Можно нарисовать свой в редакторе или показать все флаги страны.[/color]" % COL_DIM
		var gr := GridContainer.new()
		gr.columns = 4
		gr.add_theme_constant_override("h_separation", 8)
		gr.add_theme_constant_override("v_separation", 8)
		fl_body.add_child(gr)
		for ce in cand:
			gr.add_child(flag_card(ce as Dictionary))
		var ap := Button.new()
		ap.text = "Применить выбранный флаг"
		ap.focus_mode = Control.FOCUS_NONE
		ap.disabled = fl_pick == "" or fl_pick == flag_cur_id()
		ap.pressed.connect(func() -> void:
			flag_set(fl_pick, "выбор игрока")
			flag_win_fill())
		fl_body.add_child(ap)
	# --- история флага ---
	if not flag_hist.is_empty():
		var hh := make_rt(fl_body)
		var tx := "[color=%s]История флага:[/color] " % COL_DIM
		var parts: PackedStringArray = []
		for h in flag_hist:
			var he: Dictionary = Flags.entry(String(h["id"]))
			parts.append("%s — %s" % [turn_date_str(int(h["turn"])), String(he.get("name", "?"))])
		hh.text = tx + "; ".join(parts)
	polish_tree(fl_body)


func turn_date_str(t: int) -> String:
	var m: int = (month - 1 + (t - turn)) % 12
	var yy: int = year + int(floor(float(month - 1 + (t - turn)) / 12.0))
	return "%s %d" % [MONTHS[posmod(m, 12)], yy]


func flag_card(e: Dictionary) -> Control:
	var id: String = String(e["id"])
	var pc := PanelContainer.new()
	var sel: bool = id == fl_pick
	pc.add_theme_stylebox_override("panel", sbox(C_PANEL2, C_ACCENT if sel else C_BORDER, 2 if sel else 1, 8, 6.0, 6.0))
	pc.custom_minimum_size = Vector2(170.0, 0.0)
	pc.mouse_filter = Control.MOUSE_FILTER_STOP
	pc.tooltip_text = "%s\n%s" % [String(e["regime"]), String(e.get("note", ""))]
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(v)
	var tr := TextureRect.new()
	tr.texture = Flags.box_id(id)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(150.0, 100.0)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(tr)
	var l := Label.new()
	l.text = String(e["name"])
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 12)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(l)
	var y := Label.new()
	var y1: int = int(e.get("y1", 0))
	y.text = ("%d–%s" % [int(e["y0"]), str(y1) if y1 > 0 else "н. в."]) if int(e.get("y0", 0)) > 0 else "свой флаг"
	y.add_theme_font_size_override("font_size", 11)
	y.add_theme_color_override("font_color", C_TEXT.darkened(0.35))
	y.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(y)
	pc.gui_input.connect(func(ev: InputEvent) -> void:
		var mb := ev as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			fl_pick = id
			flag_win_fill())
	return pc


# ---------- редактор флага ----------
func fe_reset() -> void:
	fe = {"base": "", "tpl": 1, "c1": Color(0.80, 0.10, 0.12), "c2": Color(0.97, 0.97, 0.97), "c3": Color(0.05, 0.22, 0.58),
		"sym": -1, "symc": Color(1.0, 0.82, 0.1), "syms": 0.5, "symp": 0, "name": "Мой флаг"}


func flag_editor_open(on: bool) -> void:
	if on and fe_ov == null:
		flag_editor_build()
	if fe_ov == null:
		return
	fe_ov.visible = on
	if on:
		fe_ov.move_to_front()
		fe_reset()
		fe["base"] = flag_cur_id()
		flag_editor_sync()
		flag_editor_preview()


func flag_editor_build() -> void:
	fe_ov = Control.new()
	fe_ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fe_ov.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fe_ov)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fe_ov.add_child(dim)
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", sbox(C_PANEL, C_ACCENT.darkened(0.2), 2, 12, 16.0, 12.0))
	pan.anchor_left = 0.5
	pan.anchor_right = 0.5
	pan.anchor_top = 0.5
	pan.anchor_bottom = 0.5
	pan.offset_left = -430.0
	pan.offset_right = 430.0
	pan.offset_top = -300.0
	pan.offset_bottom = 300.0
	fe_ov.add_child(pan)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	pan.add_child(vb)
	var hd := HBoxContainer.new()
	vb.add_child(hd)
	var tl := Label.new()
	tl.text = "Редактор флага"
	tl.add_theme_font_size_override("font_size", 22)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hd.add_child(tl)
	var cl := Button.new()
	cl.text = "✕ Закрыть"
	cl.focus_mode = Control.FOCUS_NONE
	cl.pressed.connect(func() -> void: flag_editor_open(false))
	hd.add_child(cl)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(hb)
	# левая часть: предпросмотр
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.custom_minimum_size = Vector2(330.0, 0.0)
	hb.add_child(left)
	fe_prev = TextureRect.new()
	fe_prev.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fe_prev.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fe_prev.custom_minimum_size = Vector2(330.0, 220.0)
	left.add_child(fe_prev)
	fe_warn = Label.new()
	fe_warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fe_warn.add_theme_color_override("font_color", Color(1.0, 0.78, 0.25))
	fe_warn.add_theme_font_size_override("font_size", 13)
	left.add_child(fe_warn)
	var nm := LineEdit.new()
	nm.placeholder_text = "Название флага"
	nm.text_changed.connect(func(tx: String) -> void: fe["name"] = tx)
	fe_ctl["name"] = nm
	left.add_child(nm)
	var brow := HBoxContainer.new()
	brow.add_theme_constant_override("separation", 6)
	left.add_child(brow)
	var bsave := Button.new()
	bsave.text = "Сохранить и применить"
	bsave.focus_mode = Control.FOCUS_NONE
	bsave.pressed.connect(flag_editor_save)
	brow.add_child(bsave)
	var brst := Button.new()
	brst.text = "Сбросить"
	brst.focus_mode = Control.FOCUS_NONE
	brst.pressed.connect(func() -> void:
		fe_reset()
		fe["base"] = ""
		flag_editor_sync()
		flag_editor_preview())
	brow.add_child(brst)
	# правая часть: настройки
	var sc := ScrollContainer.new()
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hb.add_child(sc)
	var rv := VBoxContainer.new()
	rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rv.add_theme_constant_override("separation", 7)
	sc.add_child(rv)
	var o_base := fe_option(rv, "Начать с", "base", [])
	fe_ctl["base"] = o_base
	var o_tpl := fe_option(rv, "Шаблон", "tpl", FLAG_TPL)
	fe_ctl["tpl"] = o_tpl
	for k in [["c1", "Цвет 1"], ["c2", "Цвет 2"], ["c3", "Цвет 3"]]:
		var row := HBoxContainer.new()
		rv.add_child(row)
		var lb := Label.new()
		lb.text = String(k[1])
		lb.custom_minimum_size = Vector2(120.0, 0.0)
		row.add_child(lb)
		var cp := ColorPickerButton.new()
		cp.custom_minimum_size = Vector2(80.0, 28.0)
		cp.edit_alpha = false
		var kk: String = String(k[0])
		cp.color_changed.connect(func(c: Color) -> void:
			fe[kk] = c
			flag_editor_preview())
		fe_ctl[kk] = cp
		row.add_child(cp)
	var o_sym := fe_option(rv, "Символ", "sym", ["Без символа"] + FLAG_SYM)
	fe_ctl["sym"] = o_sym
	var row2 := HBoxContainer.new()
	rv.add_child(row2)
	var lb2 := Label.new()
	lb2.text = "Цвет символа"
	lb2.custom_minimum_size = Vector2(120.0, 0.0)
	row2.add_child(lb2)
	var cps := ColorPickerButton.new()
	cps.custom_minimum_size = Vector2(80.0, 28.0)
	cps.edit_alpha = false
	cps.color_changed.connect(func(c: Color) -> void:
		fe["symc"] = c
		flag_editor_preview())
	fe_ctl["symc"] = cps
	row2.add_child(cps)
	var o_pos := fe_option(rv, "Положение", "symp", FLAG_SYMPOS)
	fe_ctl["symp"] = o_pos
	var row3 := HBoxContainer.new()
	rv.add_child(row3)
	var lb3 := Label.new()
	lb3.text = "Размер символа"
	lb3.custom_minimum_size = Vector2(120.0, 0.0)
	row3.add_child(lb3)
	var hs := HSlider.new()
	hs.min_value = 0.2
	hs.max_value = 1.0
	hs.step = 0.05
	hs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hs.custom_minimum_size = Vector2(160.0, 20.0)
	hs.value_changed.connect(func(v: float) -> void:
		fe["syms"] = v
		flag_editor_preview())
	fe_ctl["syms"] = hs
	row3.add_child(hs)
	var hint := make_rt(rv)
	hint.text = "[color=%s]Можно начать с нынешнего или любого настоящего флага страны и добавить к нему символ. Картинки загружать нельзя: только шаблоны, цвета и символы. Редактор предупредит, если флаг слишком похож на настоящий.[/color]" % COL_DIM
	polish_tree(fe_ov)


func fe_option(parent: Control, text: String, key: String, items: Array) -> OptionButton:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var lb := Label.new()
	lb.text = text
	lb.custom_minimum_size = Vector2(120.0, 0.0)
	row.add_child(lb)
	var ob := OptionButton.new()
	ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ob.focus_mode = Control.FOCUS_NONE
	for it in items:
		ob.add_item(String(it))
	ob.item_selected.connect(func(i: int) -> void:
		if key == "base":
			fe["base"] = String(ob.get_item_metadata(i)) if ob.get_item_metadata(i) != null else ""
		elif key == "sym":
			fe["sym"] = i - 1
		else:
			fe[key] = i
		flag_editor_preview())
	row.add_child(ob)
	return ob


# значения окна редактора из параметров
func flag_editor_sync() -> void:
	var ob: OptionButton = fe_ctl["base"]
	ob.clear()
	ob.add_item("Чистый шаблон")
	ob.set_item_metadata(0, "")
	var sel := 0
	var cur := flag_cur_id()
	var n := 1
	for e in Flags.entries(ccode):
		ob.add_item("%s (%s)" % [String(e["name"]), str(int(e["y0"]))])
		ob.set_item_metadata(n, String(e["id"]))
		if String(e["id"]) == String(fe["base"]):
			sel = n
		n += 1
	for cid in flag_custom:
		ob.add_item("Свой: %s" % String(flag_custom[cid]["name"]))
		ob.set_item_metadata(n, String(cid))
		if String(cid) == String(fe["base"]):
			sel = n
		n += 1
	ob.select(sel)
	(fe_ctl["tpl"] as OptionButton).select(int(fe["tpl"]))
	for k in ["c1", "c2", "c3", "symc"]:
		(fe_ctl[k] as ColorPickerButton).color = fe[k]
	(fe_ctl["sym"] as OptionButton).select(int(fe["sym"]) + 1)
	(fe_ctl["symp"] as OptionButton).select(int(fe["symp"]))
	(fe_ctl["syms"] as HSlider).value = float(fe["syms"])
	(fe_ctl["name"] as LineEdit).text = String(fe["name"])


func flag_editor_preview() -> void:
	var svg := flag_build_svg(fe)
	var img: Image = Flags.render_image(svg, 90.0)
	if img != null and fe_prev != null:
		fe_prev.texture = ImageTexture.create_from_image(img)
	fe_warn.text = flag_similar_text(svg)


func flag_editor_save() -> void:
	var svg := flag_build_svg(fe)
	var n := 1
	while flag_custom.has("my%d" % n):
		n += 1
	var id := "my%d" % n
	var nm: String = String(fe["name"]).strip_edges()
	if nm == "":
		nm = "Мой флаг"
	var tg := flag_tags_now()
	flag_custom[id] = {"id": id, "w": 90.0, "svg": svg, "regime": nm, "ideo": tg.duplicate(), "y0": 0, "y1": 0, "name": nm, "src": "свой", "note": "Флаг, нарисованный в редакторе."}
	Flags.custom = flag_custom
	flag_set(id, "редактор")
	flag_pending = {}
	flag_editor_open(false)
	fl_pick = id
	if fl_ov != null and fl_ov.visible:
		flag_win_fill()


# ---------- сборка SVG своего флага (90 x 60) ----------
func _fs(c: Color) -> String:
	return "#" + c.to_html(false)


func _fstar(cx: float, cy: float, r: float, fill: String, n: int = 5) -> String:
	var pts: PackedStringArray = []
	for i in 2 * n:
		var a: float = deg_to_rad(-90.0 + float(i) * 180.0 / float(n))
		var rr: float = r if i % 2 == 0 else r * 0.382
		pts.append("%.2f,%.2f" % [cx + rr * cos(a), cy + rr * sin(a)])
	return '<polygon points="%s" fill="%s"/>' % [" ".join(pts), fill]


func flag_sym_svg(i: int, cx: float, cy: float, s: float, col: Color) -> String:
	var f := _fs(col)
	match i:
		0:
			return _fstar(cx, cy, 11.0 * s, f)
		1:
			return _fstar(cx, cy - 8.0 * s, 6.0 * s, f) + _fstar(cx - 10.0 * s, cy + 7.0 * s, 6.0 * s, f) + _fstar(cx + 10.0 * s, cy + 7.0 * s, 6.0 * s, f)
		2:
			return '<circle cx="%.2f" cy="%.2f" r="%.2f" fill="%s"/>' % [cx, cy, 10.0 * s, f]
		3:
			return '<circle cx="%.2f" cy="%.2f" r="%.2f" fill="none" stroke="%s" stroke-width="%.2f"/>' % [cx, cy, 9.0 * s, f, 3.0 * s]
		4:
			var R := 10.0 * s
			var r := 8.0 * s
			var d := 4.5 * s
			var x: float = (d * d + R * R - r * r) / (2.0 * d)
			var y: float = sqrt(maxf(0.0, R * R - x * x))
			return '<path d="M%.2f,%.2f A%.2f,%.2f 0 1 0 %.2f,%.2f A%.2f,%.2f 0 0 1 %.2f,%.2f Z" fill="%s"/>' % [cx + x, cy - y, R, R, cx + x, cy + y, r, r, cx + x, cy - y, f]
		5:
			var out := '<circle cx="%.2f" cy="%.2f" r="%.2f" fill="%s"/>' % [cx, cy, 6.0 * s, f]
			for k in 12:
				var a: float = deg_to_rad(float(k) * 30.0)
				var hw: float = deg_to_rad(7.0)
				out += '<polygon points="%.2f,%.2f %.2f,%.2f %.2f,%.2f" fill="%s"/>' % [cx + 7.5 * s * cos(a - hw), cy + 7.5 * s * sin(a - hw), cx + 12.5 * s * cos(a), cy + 12.5 * s * sin(a), cx + 7.5 * s * cos(a + hw), cy + 7.5 * s * sin(a + hw), f]
			return out
		6:
			return '<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" fill="%s"/><rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" fill="%s"/>' % [cx - 2.5 * s, cy - 11.0 * s, 5.0 * s, 22.0 * s, f, cx - 8.0 * s, cy - 6.0 * s, 16.0 * s, 5.0 * s, f]
		7:
			return '<g transform="translate(%.2f %.2f) scale(%.3f)" fill="%s"><polygon points="-4.6,6.6 -3.4,7.4 4.6,-3.8 3.4,-4.6"/><polygon points="1.2,-7.2 7.2,-3.4 5.8,-1.4 -0.2,-5.2"/><path d="M-6.8,-4.6 C-9.8,1.4 -5.6,8.2 1.2,7.8 C4.4,7.6 6.6,5.6 7.4,3.4 C5.4,5 3.2,5.8 0.8,5.6 C-4.6,5.0 -7.4,0 -6.8,-4.6 Z"/><polygon points="5.8,2.2 8.2,3.6 7.0,5.4 4.6,4.0"/></g>' % [cx, cy, 1.5 * s, f]
		8:
			return '<g transform="translate(%.2f %.2f) scale(%.3f)" fill="%s"><path d="M0,-8 L1.6,-6 L1.2,-4 L7,-9 L10,-6 L8,-2 L11,0 L7,2 L9,6 L4,4 L3,9 L0,6 L-3,9 L-4,4 L-9,6 L-7,2 L-11,0 L-8,-2 L-10,-6 L-7,-9 L-1.2,-4 L-1.6,-6 Z"/></g>' % [cx, cy, 1.2 * s, f]
		9:
			return '<g transform="translate(%.2f %.2f) scale(%.3f)" fill="%s"><polygon points="-6,4 -6,-3 -3,0 0,-5 3,0 6,-3 6,4"/><rect x="-6" y="4.5" width="12" height="1.8"/></g>' % [cx, cy, 1.9 * s, f]
		10:
			var w := 18.0 * s
			var h := 22.0 * s
			return '<path d="M%.2f,%.2f L%.2f,%.2f L%.2f,%.2f Q%.2f,%.2f %.2f,%.2f Q%.2f,%.2f %.2f,%.2f Z" fill="%s"/>' % [cx - w / 2.0, cy - h / 2.0, cx + w / 2.0, cy - h / 2.0, cx + w / 2.0, cy - h / 2.0 + h * 0.45, cx + w / 2.0, cy - h / 2.0 + h * 0.85, cx, cy + h / 2.0, cx - w / 2.0, cy - h / 2.0 + h * 0.85, cx - w / 2.0, cy - h / 2.0 + h * 0.45, f]
	return ""


func flag_build_svg(p: Dictionary) -> String:
	var c1 := _fs(p["c1"])
	var c2 := _fs(p["c2"])
	var c3 := _fs(p["c3"])
	var body := ""
	var base: String = String(p.get("base", ""))
	var be: Dictionary = Flags.entry(base) if base != "" else {}
	if not be.is_empty():
		var sv: String = String(be["svg"])
		var a: int = sv.find(">")
		var z: int = sv.rfind("</svg>")
		var inner: String = sv.substr(a + 1, z - a - 1)
		var sx: float = 90.0 / float(be["w"])
		body = '<g transform="scale(%.4f 1)">%s</g>' % [sx, inner]
	else:
		match int(p["tpl"]):
			0:
				body = '<rect width="90" height="30" fill="%s"/><rect y="30" width="90" height="30" fill="%s"/>' % [c1, c2]
			1:
				body = '<rect width="90" height="20.1" fill="%s"/><rect y="20" width="90" height="20.1" fill="%s"/><rect y="40" width="90" height="20" fill="%s"/>' % [c1, c2, c3]
			2:
				body = '<rect width="30.1" height="60" fill="%s"/><rect x="30" width="30.1" height="60" fill="%s"/><rect x="60" width="30" height="60" fill="%s"/>' % [c1, c2, c3]
			3:
				body = '<rect width="90" height="60" fill="%s"/><rect x="22" width="12" height="60" fill="%s"/><rect y="24" width="90" height="12" fill="%s"/>' % [c1, c2, c2] + '<rect x="25" width="6" height="60" fill="%s"/><rect y="27" width="90" height="6" fill="%s"/>' % [c3, c3]
			4:
				body = '<rect width="90" height="60" fill="%s"/><rect x="38" width="14" height="60" fill="%s"/><rect y="23" width="90" height="14" fill="%s"/>' % [c1, c2, c2]
			5:
				body = '<rect width="90" height="60" fill="%s"/><path d="M0,0 L90,60 M90,0 L0,60" stroke="%s" stroke-width="12"/>' % [c1, c2]
			6:
				body = '<rect width="90" height="60" fill="%s"/><polygon points="0,60 90,0 90,60" fill="%s"/>' % [c1, c2]
			7:
				body = '<rect width="90" height="60" fill="%s"/><rect width="40" height="32" fill="%s"/>' % [c1, c2]
			8:
				body = '<rect width="90" height="60" fill="%s"/><polygon points="0,0 45,30 0,60" fill="%s"/>' % [c1, c2]
			9:
				body = '<rect width="90" height="60" fill="%s"/><circle cx="45" cy="30" r="17" fill="%s"/>' % [c1, c2]
	var sym := ""
	var si: int = int(p["sym"])
	if si >= 0:
		var pos := Vector2(45.0, 30.0)
		match int(p["symp"]):
			1:
				pos = Vector2(18.0, 15.0)
			2:
				pos = Vector2(24.0, 30.0)
		var sc: float = float(p["syms"]) * (0.7 if int(p["symp"]) == 1 else 1.0)
		sym = flag_sym_svg(si, pos.x, pos.y, sc * 1.3, p["symc"])
	return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 90 60">%s%s</svg>' % [body, sym]


# крошечные копии всех настоящих флагов (для предупреждения «слишком похож»)
func flag_small(id: String) -> PackedByteArray:
	if fl_small_cache.has(id):
		return fl_small_cache[id]
	var e: Dictionary = Flags.entry(id)
	var out := PackedByteArray()
	if not e.is_empty():
		var img := Image.new()
		if img.load_svg_from_string(String(e["svg"]), 0.5) == OK:
			img.convert(Image.FORMAT_RGB8)
			img.resize(18, 12, Image.INTERPOLATE_BILINEAR)
			out = img.get_data()
	fl_small_cache[id] = out
	return out


func flag_similar_text(svg: String) -> String:
	var img := Image.new()
	if img.load_svg_from_string(svg, 0.5) != OK:
		return ""
	img.convert(Image.FORMAT_RGB8)
	img.resize(18, 12, Image.INTERPOLATE_BILINEAR)
	var mine: PackedByteArray = img.get_data()
	var best := 1e9
	var bn := ""
	for cc in Flags._db:
		for e in Flags._db[cc]:
			var o: PackedByteArray = flag_small(String(e["id"]))
			if o.size() != mine.size():
				continue
			var d := 0.0
			for i in mine.size():
				d += absf(float(mine[i]) - float(o[i]))
			d /= float(mine.size()) * 255.0
			if d < best:
				best = d
				bn = "%s (%s)" % [String(e["name"]), String(Flags._db.get(cc, [{"regime": ""}])[0].get("regime", cc)) if false else String(cc)]
	if best < 0.045:
		return "Очень похоже на настоящий флаг: %s. Если это не задумано, измените цвета или символ." % bn
	return ""
