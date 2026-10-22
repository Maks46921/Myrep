# 0.59: государство и флаг. Окно «Государство» (флаг «на ветру», название по истории, форма правления, столица), выбор флага
# из исторических (data/flags.dat), редактор своего флага и вопрос о смене флага, когда меняется строй.
extends "res://scripts/ui/ui_rules.gd"

const FLAG_TPL := ["Две полосы (горизонтально)", "Три полосы (горизонтально)", "Три полосы (вертикально)", "Скандинавский крест", "Прямой крест",
	"Косой крест", "Деление по диагонали", "Кантон (угол) и поле", "Треугольник у древка", "Круг по центру"]
const FLAG_SYM := ["Звезда", "Три звезды", "Круг", "Кольцо", "Полумесяц", "Солнце", "Крест", "Серп и молот", "Орёл", "Корона", "Щит", "Лев", "Дуб/лавр", "Колос", "Шестерня", "Книга", "Меч", "Роза", "Якорь", "Кедр", "Трезубец", "Двуглавый орёл", "Рука/кулак"]
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
	var out: Array = []
	if uq_on():
		for t in uq_def().get("fl", []):
			if not t in out:
				out.append(t)
	var rv := reg60_var()
	if not rv.is_empty():
		for t in rv.get("fl", []):
			if not t in out:
				out.append(t)
	for t in flag_tags_base():
		if not t in out:
			out.append(t)
	return out


func flag_tags_base() -> Array:
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
	for ge in flag_gen_offers(tags, 8):
		out.append(ge)
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
	var offers := flag_offer_ids(tags)
	if offers.is_empty():
		return
	var pick := flag_pick_auto(tags)
	if pick == "" or pick == flag_cur_id():
		pick = String(offers[0])
	flag_pending = {"tags": tags, "old": old_tags, "pick": pick, "turn": turn, "offers": offers}
	var txt := "Строй страны изменился (%s). Игра предлагает %d флагов на выбор: откройте окно «Государство» (щелчок по флагу слева вверху)." % [flag_regime_label(tags), offers.size()]
	log_tag("ФЛАГ", COL_TEAL, txt)
	if not flag_ask:
		flag_pending = {}
		return
	nt_toast(txt, "inbox", 0)
	flag_top_refresh()


# в реальной жизни строй сразу получает новый флаг; здесь выбор остаётся за игроком
func flag_month_force() -> void:
	flag_month()


func flag_regime_label(tags: Array) -> String:
	if uq_on():
		return uq_title().to_lower()
	var rv := reg60_var()
	if not rv.is_empty():
		return String(rv["n"]).to_lower()
	return String(tags[0]).to_lower()


# ---------- «Авторы флагов»: лицензии и авторы свободных изображений ----------
func flag_credits_fill() -> void:
	var rt := make_rt(fl_body)
	var by_lic := {}
	var rows: Array = []
	for cc in Flags._db:
		for e in Flags._db[cc]:
			if (e as Dictionary).has("lic") or (e as Dictionary).has("author"):
				var lic := String(e.get("lic", "лицензия не указана"))
				by_lic[lic] = int(by_lic.get(lic, 0)) + 1
				rows.append([String(WORLD[cc]["name"]) if WORLD.has(cc) else String(cc), e])
	rows.sort_custom(func(a: Array, b: Array) -> bool:
		if String(a[0]) != String(b[0]):
			return String(a[0]) < String(b[0])
		return String((a[1] as Dictionary)["name"]) < String((b[1] as Dictionary)["name"]))
	var t := "[font_size=20][b]Авторы флагов[/b][/font_size]\n"
	t += "Многие исторические и фанатские флаги в игре — свободные изображения с Викисклада (Wikimedia Commons). Здесь перечислены их авторы и лицензии.\n\n"
	t += "[color=%s]• Общественное достояние (PD) и CC0: можно использовать без условий.\n• CC BY: нужно указать автора (это и делает этот список).\n• CC BY-SA: нужно указать автора, а изображения на её основе остаются под той же лицензией.[/color]\n\n" % COL_DIM
	if rows.is_empty():
		t += "Пока в игре нет флагов, для которых нужно указание авторов: все флаги нарисованы авторами игры или упрощены до геометрических фигур.\n"
	else:
		var lt := PackedStringArray()
		for k in by_lic:
			lt.append("%s: %d" % [String(k), int(by_lic[k])])
		t += "[b]Всего изображений:[/b] %d (%s).\n\n" % [rows.size(), "; ".join(lt)]
		var last := ""
		for r in rows:
			var e2: Dictionary = r[1]
			if String(r[0]) != last:
				last = String(r[0])
				t += "[b]%s[/b]\n" % last
			t += "• %s — автор: %s; лицензия: %s%s\n" % [String(e2["name"]), String(e2.get("author", "не указан")), String(e2.get("lic", "?")), ("; источник: %s" % String(e2["url"])) if e2.has("url") else ""]
	t += "\n[color=%s]Флаги, нарисованные в игре (редактор, предложения при смене строя, 49 символов), принадлежат авторам игры и свободны для использования.[/color]" % COL_DIM
	rt.text = t


# ---------- предложения флагов: настоящие, потом нарисованные игрой в цветах страны ----------
var fl_gen_cache: Dictionary = {}


func flag_offer_ids(tags: Array) -> Array:
	var out: Array = []
	var reals: Array = []
	for e in flag_candidates(tags):
		var eid := String((e as Dictionary)["id"])
		if eid.begins_with("gen_") or flag_custom.has(eid) or eid == flag_cur_id():
			continue
		reals.append(eid)
	for k in mini(4, reals.size()):
		out.append(reals[k])
	for ge in flag_gen_offers(tags, 8):
		if out.size() >= 6:
			break
		out.append(String((ge as Dictionary)["id"]))
	return out


func flag_palette(id: String) -> Array:
	var e: Dictionary = Flags.entry(id)
	var cnt := {}
	var rx := RegEx.new()
	rx.compile("#[0-9a-fA-F]{6}")
	for m in rx.search_all(String(e.get("svg", ""))):
		var h := m.get_string().to_lower()
		cnt[h] = int(cnt.get(h, 0)) + 1
	var keys: Array = cnt.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return int(cnt[a]) > int(cnt[b]))
	var out: Array = []
	for k in keys:
		out.append(Color.html(String(k)))
	return out


func flag_color_name(c: Color) -> String:
	var h: float = c.h * 360.0
	if c.v < 0.24:
		return "чёрный"
	if c.s < 0.16:
		return "белый" if c.v > 0.82 else "серый"
	if h < 14.0 or h >= 340.0:
		return "красный" if c.v > 0.5 else "бордовый"
	if h < 40.0:
		return "оранжевый" if c.v > 0.62 else "коричневый"
	if h < 68.0:
		return "жёлтый"
	if h < 165.0:
		return "зелёный"
	if h < 200.0:
		return "бирюзовый"
	if h < 255.0:
		return "синий" if c.v < 0.8 else "голубой"
	if h < 300.0:
		return "фиолетовый"
	return "малиновый"


# одно предложение о флаге: у предложенных игрой — по рисунку, у настоящих — по цветам
func flag_describe(id: String) -> String:
	var e: Dictionary = Flags.entry(id)
	if e.is_empty():
		return ""
	if e.has("desc") and String(e["desc"]) != "":
		return String(e["desc"])
	var names: PackedStringArray = []
	for c in flag_palette(id):
		var n := flag_color_name(c)
		if not n in names:
			names.append(n)
		if names.size() >= 4:
			break
	if names.is_empty():
		return ""
	return "Флаг в цветах: %s." % ", ".join(names)


func flag_gen_offers(tags: Array, count: int) -> Array:
	var key := "%s|%s|%d" % [ccode, ",".join(PackedStringArray(tags)), count]
	if fl_gen_cache.has(key):
		return fl_gen_cache[key]
	var out: Array = []
	var pal: Array = flag_palette(Flags.default_id(ccode))
	var pal2: Array = []
	for c in pal:
		var dup := false
		for q in pal2:
			if absf((q as Color).r - (c as Color).r) + absf((q as Color).g - (c as Color).g) + absf((q as Color).b - (c as Color).b) < 0.25:
				dup = true
		if not dup:
			pal2.append(c)
	var defaults := [Color(0.78, 0.07, 0.18), Color(0.97, 0.96, 0.92), Color(0.12, 0.30, 0.62), Color(0.95, 0.76, 0.10)]
	for d in defaults:
		if pal2.size() < 3:
			pal2.append(d)
	var pref := Color(0, 0, 0, 0)
	for t in tags:
		if FLAG_TAG_COL.has(String(t)):
			pref = Color.html(String(FLAG_TAG_COL[String(t)]))
			break
	var syms: Array = []
	for t in tags:
		for si in FLAG_TAG_SYM.get(String(t), []):
			if not int(si) in syms:
				syms.append(int(si))
	for si in FLAG_CC_SYM.get(ccode, []):
		if not int(si) in syms:
			syms.insert(mini(1, syms.size()), int(si))
	if syms.is_empty():
		syms = [0, 10]
	# рецепты: шаблон, символ (место), положение, порядок цветов
	var rec := [[1, 0, 0, [0, 1, 2]], [2, 1, 0, [1, 2, 0]], [0, 0, 1, [2, 0, 1]], [3, -1, 0, [0, 1, 2]], [7, 1, 1, [1, 0, 2]], [8, 0, 2, [2, 1, 0]], [9, 1, 0, [0, 2, 1]], [6, 2, 0, [1, 0, 2]]]
	var tpl_names := ["две горизонтальные полосы", "три горизонтальные полосы", "три вертикальные полосы", "скандинавский крест", "прямой крест", "косой крест", "диагональное деление", "угол (кантон) и поле", "треугольник у древка", "круг в центре"]
	var tag0 := String(tags[0])
	for k in mini(count, rec.size()):
		var r: Array = rec[k]
		var order: Array = r[3]
		var c1: Color = pal2[int(order[0]) % pal2.size()]
		var c2: Color = pal2[int(order[1]) % pal2.size()]
		var c3: Color = pal2[int(order[2]) % pal2.size()]
		if pref.a > 0.0 and k % 2 == 0:
			c1 = pref
		var si: int = -1
		if int(r[1]) >= 0:
			si = int(syms[int(r[1]) % syms.size()])
		var under: Color = c2 if int(r[0]) in [1, 2, 9] else c1
		var symc := Color(0.97, 0.95, 0.88)
		if under.get_luminance() > 0.55:
			symc = Color(0.10, 0.10, 0.12)
		elif pref.a > 0.0 and (String(tags[0]) in ["Монархия", "Империя", "Новая Византия"]):
			symc = Color(0.96, 0.78, 0.22)
		var p := {"base": "", "tpl": int(r[0]), "c1": c1, "c2": c2, "c3": c3, "sym": si, "symc": symc, "syms": 0.55, "symp": int(r[2]), "name": ""}
		var svg := flag_build_svg(p)
		var nm := "%s: знамя %d" % [tag0, k + 1]
		var id := "gen_%s_%s_%d" % [ccode, tag0, k]
		var cn: PackedStringArray = [flag_color_name(c1), flag_color_name(c2)]
		if int(r[0]) in [1, 2]:
			cn.append(flag_color_name(c3))
		var ds := "Флаг: %s (%s)" % [String(tpl_names[int(r[0])]), ", ".join(cn)]
		if si >= 0:
			ds += " и символ «%s»" % String(FLAG_SYM[si])
		ds += "."
		var e := {"id": id, "w": 90.0, "svg": svg, "regime": flag_regime_label(tags).capitalize(), "ideo": tags.duplicate(), "y0": 0, "y1": 0, "name": nm,
			"src": "придуманный", "note": "Предложен игрой: простой флаг в цветах страны.", "desc": ds}
		Flags.temp[id] = e
		out.append(e)
	fl_gen_cache[key] = out
	return out


# предложенный игрой флаг становится вашим собственным (сохраняется вместе с игрой)
func flag_adopt(id: String) -> String:
	if not id.begins_with("gen_"):
		return id
	for cid in flag_custom:
		if String((flag_custom[cid] as Dictionary).get("gen", "")) == id:
			return String(cid)
	var e: Dictionary = (Flags.entry(id) as Dictionary).duplicate(true)
	if e.is_empty():
		return id
	var n := 1
	while flag_custom.has("my%d" % n):
		n += 1
	var nid := "my%d" % n
	e["id"] = nid
	e["gen"] = id
	flag_custom[nid] = e
	Flags.custom = flag_custom
	return nid


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
	var nm := String(v.get("n", "республика"))
	var rv := reg60_var()
	if not rv.is_empty():
		nm = "%s: %s" % [nm, String(rv["n"])]
	if uq_on():
		return "%s (особый строй «%s»)" % [nm, uq_title()]
	return nm


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
		var fdesc := flag_describe(id)
		if fdesc != "":
			t += "\n[color=%s]Описание:[/color] %s" % [COL_DIM, fdesc]
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
		qt.text = "[b]Строй изменился: %s.[/b] Сменить флаг? Игра предлагает несколько вариантов: щёлкните по флагу, чтобы принять его." % flag_regime_label(flag_pending["tags"])
		var offers: Array = flag_pending.get("offers", [])
		if offers.is_empty():
			offers = flag_offer_ids(flag_pending["tags"])
			flag_pending["offers"] = offers
		var og := GridContainer.new()
		og.columns = 3
		og.add_theme_constant_override("h_separation", 8)
		og.add_theme_constant_override("v_separation", 8)
		qv.add_child(og)
		for oid in offers:
			og.add_child(flag_offer_card(String(oid)))
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
		b2.text = "Первый из предложенных"
		b2.focus_mode = Control.FOCUS_NONE
		b2.pressed.connect(func() -> void:
			var pk: String = flag_adopt(String(flag_pending["pick"]))
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
	bs.text = "Сменить флаг" if fl_view != 1 else "Скрыть список флагов"
	bs.focus_mode = Control.FOCUS_NONE
	bs.pressed.connect(func() -> void:
		fl_view = 0 if fl_view == 1 else 1
		flag_win_fill())
	br.add_child(bs)
	var be := Button.new()
	be.text = "Редактор флага"
	be.focus_mode = Control.FOCUS_NONE
	be.pressed.connect(func() -> void: flag_editor_open(true))
	br.add_child(be)
	var bc := Button.new()
	bc.text = "Авторы флагов" if fl_view != 2 else "Назад к флагу"
	bc.focus_mode = Control.FOCUS_NONE
	bc.pressed.connect(func() -> void:
		fl_view = 2 if fl_view != 2 else 0
		flag_win_fill())
	br.add_child(bc)
	if fl_view == 2:
		flag_credits_fill()
		polish_tree(fl_body)
		return
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
			flag_set(flag_adopt(fl_pick), "выбор игрока")
			fl_pick = flag_cur_id()
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


func flag_offer_card(id: String) -> Control:
	var e: Dictionary = Flags.entry(id)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", sbox(C_PANEL2, C_BORDER, 1, 8, 6.0, 6.0))
	pc.custom_minimum_size = Vector2(150.0, 0.0)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.mouse_filter = Control.MOUSE_FILTER_STOP
	pc.tooltip_text = "%s\n%s\nЩёлкните, чтобы принять этот флаг." % [String(e.get("name", "?")), flag_describe(id)]
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(v)
	var tr := TextureRect.new()
	tr.texture = Flags.box_id(id)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(130.0, 84.0)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(tr)
	var l := Label.new()
	l.text = String(e.get("name", "?"))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 12)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(l)
	var y := Label.new()
	var y0: int = int(e.get("y0", 0))
	y.text = ("%d–%s, %s" % [y0, str(int(e.get("y1", 0))) if int(e.get("y1", 0)) > 0 else "н. в.", String(e.get("src", ""))]) if y0 > 0 else String(e.get("src", "придуманный"))
	y.add_theme_font_size_override("font_size", 11)
	y.add_theme_color_override("font_color", C_TEXT.darkened(0.35))
	y.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(y)
	pc.gui_input.connect(func(ev: InputEvent) -> void:
		var mb := ev as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var tgs: Array = flag_pending.get("tags", flag_tags_now())
			var nid := flag_adopt(id)
			flag_pending = {}
			flag_set(nid, "смена строя", tgs)
			fl_pick = nid
			flag_win_fill())
	return pc


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


# ---------- редактор флага (0.60: слои, окно — scripts/classes/flag_edit.gd, данные — flag_doc.gd) ----------
const FlagEdit := preload("res://scripts/classes/flag_edit.gd")
const FlagDoc := preload("res://scripts/classes/flag_doc.gd")


func flag_editor_open(on: bool) -> void:
	if on and fe_ov == null:
		flag_editor_build()
	if fe_ov == null:
		return
	fe_ov.visible = on
	if on:
		fe_ov.move_to_front()
		fe_ov.call("open_with", flag_editor_start(), flag_editor_params(""))


func flag_editor_build() -> void:
	var ed := FlagEdit.new()
	ed.syms = FLAG_SYM60
	ed.wave_code = FLAG_WAVE
	ed.panel_style = sbox(C_PANEL, C_ACCENT.darkened(0.2), 2, 12, 12.0, 10.0)
	ed.entry_fn = func(id: String) -> Dictionary: return Flags.entry(id)
	ed.polish = func(n: Node) -> void: polish_tree(n)
	ed.visible = false
	add_child(ed)
	ed.build()
	ed.save_requested.connect(flag_editor_save)
	ed.draft_delete.connect(flag_editor_delete)
	ed.closed.connect(func() -> void: flag_editor_open(false))
	fe_ov = ed
	polish_tree(ed)


# стартовый документ: нынешний флаг как закреплённая основа
func flag_editor_start() -> Dictionary:
	var d := FlagDoc.new_doc("#ffffff")
	var e: Dictionary = Flags.entry(flag_cur_id())
	if not e.is_empty():
		var L := FlagDoc.base_layer(String(e["svg"]))
		L["src"] = String(e["id"])
		L["lock"] = true
		(d["layers"] as Array).append(L)
	return d


func flag_editor_params(edit_id: String) -> Dictionary:
	var pal: Array = []
	var seen := {}
	for e in Flags.entries(ccode):
		for c in flag_palette(String(e["id"])):
			var h: String = (c as Color).to_html(false)
			if not seen.has(h):
				seen[h] = true
				pal.append(c)
		if pal.size() > 24:
			break
	var cur := flag_palette(flag_cur_id())
	var pal2: Array = []
	for c in cur:
		pal2.append(c)
	for c in pal:
		if not (c as Color) in pal2:
			pal2.append(c)
	var cl: Array = []
	for cc in Flags._db:
		var items: Array = []
		for e in Flags._db[cc]:
			var y0: int = int(e.get("y0", 0))
			items.append([String(e["id"]), "%s%s" % [String(e["name"]), (" (%d)" % y0) if y0 > 0 else ""]])
		var nm: String = String(WORLD[cc]["name"]) if WORLD.has(cc) else String(cc)
		cl.append([nm, items, String(cc)])
	cl.sort_custom(func(a: Array, b: Array) -> bool:
		if (String(a[2]) == ccode) != (String(b[2]) == ccode):
			return String(a[2]) == ccode
		return String(a[0]) < String(b[0]))
	return {"drafts": flag_drafts(), "edit_id": edit_id, "pal": pal2, "countries": cl, "cur": flag_cur_id()}


func flag_drafts() -> Array:
	var out: Array = []
	for cid in flag_custom:
		var e: Dictionary = flag_custom[cid]
		out.append({"id": String(cid), "name": String(e.get("name", "Мой флаг")), "doc": e.get("doc", null)})
	return out


func flag_editor_save(doc: Dictionary, apply: bool, edit_id: String) -> void:
	var svg := FlagDoc.build_svg(doc, FLAG_SYM60)
	var id := edit_id
	if id == "" or not flag_custom.has(id):
		var n := 1
		while flag_custom.has("my%d" % n):
			n += 1
		id = "my%d" % n
	var nm: String = String(doc.get("name", "")).strip_edges()
	if nm == "":
		nm = "Мой флаг"
	var tg := flag_tags_now()
	flag_custom[id] = {"id": id, "w": 90.0, "svg": svg, "regime": nm, "ideo": tg.duplicate(), "y0": 0, "y1": 0, "name": nm, "src": "свой",
		"note": "Флаг, нарисованный в редакторе.", "doc": doc}
	Flags.custom = flag_custom
	Flags.forget(id)
	if fe_ov != null:
		fe_ov.call("saved", id, apply)
		fe_ov.call("set_drafts", flag_drafts())
	if apply:
		flag_set(id, "редактор")
		flag_pending = {}
		fl_pick = id
		flag_editor_open(false)
		if fl_ov != null and fl_ov.visible:
			flag_win_fill()
	elif flag_cur_id() == id:
		flag_sync()


func flag_editor_delete(id: String) -> void:
	if not flag_custom.has(id):
		return
	var was_cur := flag_cur_id() == id
	flag_custom.erase(id)
	Flags.custom = flag_custom
	Flags.forget(id)
	if was_cur:
		flag_id = ""
		flag_sync()
	if fe_ov != null:
		fe_ov.call("set_drafts", flag_drafts())


# предложения игры (flag_gen_offers) строятся по простым шаблонам: параметры p — шаблон, три цвета и один символ
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
	if i < 0 or i >= FLAG_SYM60.size():
		return ""
	var svg: String = String((FLAG_SYM60[i] as Array)[1]).replace('"C"', '"%s"' % _fs(col))
	return '<g transform="translate(%.2f %.2f) scale(%.3f)">%s</g>' % [cx, cy, s * 0.95, svg]


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

