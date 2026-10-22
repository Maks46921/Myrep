# 0.60: редактор своего флага из слоёв (на весь экран). Фигуры рисуются мышью, цвета любые, привязка к сетке и направляющим.
# Данные документа — flag_doc.gd, холст — flag_canvas.gd. Окно только собирает панели и передаёт сохранение игре.
extends Control

const FD := preload("res://scripts/classes/flag_doc.gd")
const FlagCanvas := preload("res://scripts/classes/flag_canvas.gd")

signal save_requested(doc: Dictionary, apply: bool, edit_id: String)
signal draft_delete(id: String)
signal closed

var syms: Array = []
var wave_code := ""
var panel_style: StyleBox = null
var entry_fn: Callable = Callable()
var polish: Callable = Callable()

var doc: Dictionary = {}
var sel := -1
var tool := ""
var cur_sym := 0
var cur_fill := "#cc1a1f"
var pip_target := "fill"
var snap_on := true
var grid_on := true
var grid := 5.0
var hist: Array = []
var redo_st: Array = []
var saved_json := ""
var edit_id := ""
var drafts: Array = []
var pal: Array = []
var countries: Array = []
var cur_flag_id := ""

var cv = null
var layer_box: VBoxContainer = null
var prop_box: VBoxContainer = null
var pal_grid: HFlowContainer = null
var status_lbl: Label = null
var wind: TextureRect = null
var wind_box: Control = null
var name_edit: LineEdit = null
var tool_btns: Dictionary = {}
var draft_opt: OptionButton = null
var tpl_opt: OptionButton = null
var cty_opt: OptionButton = null
var flg_opt: OptionButton = null
var sym_opt: OptionButton = null
var grid_opt: OptionButton = null
var confirm_bar: Control = null
var rows: Array = []
var undo_btn: Button = null
var redo_btn: Button = null
var save_note: Label = null


# ---------- панель редактора ----------
class Row extends PanelContainer:
	var ed = null
	var idx := 0
	var swatch: ColorRect = null

	func _get_drag_data(_at: Vector2) -> Variant:
		var l := Label.new()
		l.text = "  " + String(ed.layer_name(idx))
		set_drag_preview(l)
		return {"fe_idx": idx}

	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return data is Dictionary and (data as Dictionary).has("fe_idx")

	func _drop_data(at: Vector2, data: Variant) -> void:
		ed.reorder(int((data as Dictionary)["fe_idx"]), idx, at.y > size.y * 0.5)

	func _gui_input(ev: InputEvent) -> void:
		var mb := ev as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			ed.select(idx)


func _btn(parent: Control, text: String, cb: Callable, tip: String = "") -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = tip
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _chk(parent: Control, text: String, on: bool, cb: Callable, tip: String = "") -> CheckBox:
	var c := CheckBox.new()
	c.text = text
	c.button_pressed = on
	c.focus_mode = Control.FOCUS_NONE
	c.tooltip_text = tip
	c.toggled.connect(cb)
	parent.add_child(c)
	return c


func _lbl(parent: Control, text: String, size_px: int = 0) -> Label:
	var l := Label.new()
	l.text = text
	if size_px > 0:
		l.add_theme_font_size_override("font_size", size_px)
	parent.add_child(l)
	return l


func _opt(parent: Control) -> OptionButton:
	var o := OptionButton.new()
	o.focus_mode = Control.FOCUS_NONE
	o.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	o.clip_text = true
	parent.add_child(o)
	return o


func _head(parent: Control, text: String) -> void:
	var l := _lbl(parent, text, 15)
	l.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))


func _pol(n: Node) -> void:
	if polish.is_valid():
		polish.call(n)


func build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.05, 0.07, 0.97)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var pan := PanelContainer.new()
	if panel_style != null:
		pan.add_theme_stylebox_override("panel", panel_style)
	pan.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pan.offset_left = 8.0
	pan.offset_top = 8.0
	pan.offset_right = -8.0
	pan.offset_bottom = -8.0
	add_child(pan)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	pan.add_child(vb)
	_build_top(vb)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(hb)
	_build_left(hb)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 4)
	hb.add_child(mid)
	cv = FlagCanvas.new()
	cv.ed = self
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cv.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cv.custom_minimum_size = Vector2(420.0, 300.0)
	mid.add_child(cv)
	var pr := HBoxContainer.new()
	pr.add_theme_constant_override("separation", 8)
	mid.add_child(pr)
	var pl := _lbl(pr, "Цвета", 14)
	pl.tooltip_text = "Щелчок — заливка выбранной фигуры (или фон). Shift + щелчок — обводка."
	pl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	pal_grid = HFlowContainer.new()
	pal_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pal_grid.add_theme_constant_override("h_separation", 3)
	pal_grid.add_theme_constant_override("v_separation", 3)
	pr.add_child(pal_grid)
	var gb := HBoxContainer.new()
	gb.add_theme_constant_override("separation", 6)
	mid.add_child(gb)
	_btn(gb, "│ Направляющая", func() -> void: add_guide(0), "Вертикальная линия-привязка. Перетащите её мышью; за край холста — удалить.")
	_btn(gb, "─ Направляющая", func() -> void: add_guide(1), "Горизонтальная линия-привязка.")
	_btn(gb, "Убрать направляющие", func() -> void:
		snap_undo()
		doc["gv"] = []
		doc["gh"] = []
		cv.queue_redraw())
	status_lbl = Label.new()
	status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_lbl.custom_minimum_size = Vector2(300.0, 38.0)
	status_lbl.add_theme_font_size_override("font_size", 13)
	status_lbl.add_theme_color_override("font_color", Color(0.78, 0.82, 0.9))
	mid.add_child(status_lbl)
	_build_right(hb)
	status("")


func _build_top(vb: VBoxContainer) -> void:
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	vb.add_child(top)
	_lbl(top, "Редактор флага", 20)
	name_edit = LineEdit.new()
	name_edit.placeholder_text = "Название флага"
	name_edit.custom_minimum_size = Vector2(170.0, 0.0)
	name_edit.text_changed.connect(func(tx: String) -> void: doc["name"] = tx)
	top.add_child(name_edit)
	undo_btn = _btn(top, "Отменить", undo, "Ctrl+Z")
	redo_btn = _btn(top, "Вернуть", redo, "Ctrl+Y")
	_btn(top, "−", func() -> void: cv.zoom_by(1.0 / 1.25, cv.size * 0.5), "Уменьшить холст (колесо мыши)")
	_btn(top, "+", func() -> void: cv.zoom_by(1.25, cv.size * 0.5), "Увеличить холст (колесо мыши)")
	_btn(top, "Весь флаг", func() -> void: cv.view_reset(), "Вернуть масштаб")
	_chk(top, "Привязка", true, func(on: bool) -> void: snap_on = on, "Фигуры прилипают к сетке, направляющим, краям и центру флага. Alt — временно отключить.")
	_chk(top, "Сетка", true, func(on: bool) -> void:
		grid_on = on
		cv.queue_redraw())
	grid_opt = OptionButton.new()
	grid_opt.focus_mode = Control.FOCUS_NONE
	for g in [["Шаг 2,5", 2.5], ["Шаг 5", 5.0], ["Шаг 7,5", 7.5], ["Шаг 10", 10.0], ["Шаг 15", 15.0]]:
		grid_opt.add_item(String(g[0]))
		grid_opt.set_item_metadata(grid_opt.item_count - 1, float(g[1]))
	grid_opt.select(1)
	grid_opt.item_selected.connect(func(i: int) -> void:
		grid = float(grid_opt.get_item_metadata(i))
		cv.queue_redraw())
	top.add_child(grid_opt)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	_btn(top, "✕ Закрыть", request_close)
	confirm_bar = HBoxContainer.new()
	confirm_bar.visible = false
	vb.add_child(confirm_bar)
	var cl := _lbl(confirm_bar, "В флаге есть несохранённые изменения. Закрыть без сохранения?")
	cl.add_theme_color_override("font_color", Color(1.0, 0.78, 0.25))
	_btn(confirm_bar, "Закрыть без сохранения", func() -> void:
		confirm_bar.visible = false
		closed.emit())
	_btn(confirm_bar, "Остаться", func() -> void: confirm_bar.visible = false)


func _build_left(hb: HBoxContainer) -> void:
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(268.0, 0.0)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hb.add_child(sc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 5)
	sc.add_child(v)
	_head(v, "Фигуры")
	var gr := GridContainer.new()
	gr.columns = 2
	gr.add_theme_constant_override("h_separation", 4)
	gr.add_theme_constant_override("v_separation", 4)
	v.add_child(gr)
	var b0 := _btn(gr, "Выбор", func() -> void: set_tool(""), "Выбирать и двигать фигуры")
	b0.toggle_mode = true
	b0.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tool_btns[""] = b0
	for ty in FD.TYPES:
		var t: String = String(ty[0])
		var b := _btn(gr, String(ty[1]), func() -> void: set_tool(t), "Нарисуйте фигуру мышью на флаге")
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 12)
		tool_btns[t] = b
	var b2 := _btn(gr, "Пипетка", func() -> void: start_pipette("fill"), "Взять цвет с флага")
	b2.toggle_mode = true
	b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tool_btns["pipette"] = b2
	_lbl(v, "Символ для рисования")
	sym_opt = _opt(v)
	for i in syms.size():
		sym_opt.add_item(String((syms[i] as Array)[0]))
	sym_opt.item_selected.connect(func(i: int) -> void:
		cur_sym = i
		if tool != "sym":
			set_tool("sym"))
	v.add_child(HSeparator.new())
	_head(v, "Начать заново")
	_btn(v, "Пустой холст", func() -> void: new_blank(), "Чистое поле выбранного цвета фона")
	_lbl(v, "Шаблон из фигур")
	tpl_opt = _opt(v)
	for t in FD.TEMPLATES:
		tpl_opt.add_item(String(t))
	_btn(v, "Взять шаблон", func() -> void: apply_template(tpl_opt.selected), "Шаблон превращается в обычные фигуры, их можно менять")
	v.add_child(HSeparator.new())
	_head(v, "Флаг игры как основа")
	_btn(v, "Нынешний флаг страны", func() -> void: base_from(cur_flag_id))
	cty_opt = _opt(v)
	cty_opt.item_selected.connect(func(i: int) -> void: fill_flags(i))
	flg_opt = _opt(v)
	_btn(v, "Взять этот флаг", func() -> void:
		if flg_opt.item_count > 0:
			base_from(String(flg_opt.get_item_metadata(flg_opt.selected))))
	_btn(v, "Разобрать основу на фигуры", func() -> void: split_base(), "Только для флагов, нарисованных в игре")
	v.add_child(HSeparator.new())
	_head(v, "Мои флаги")
	draft_opt = _opt(v)
	var dr := HBoxContainer.new()
	v.add_child(dr)
	_btn(dr, "Открыть", func() -> void: open_draft())
	_btn(dr, "Удалить", func() -> void: delete_draft())
	var hint := Label.new()
	hint.text = "Колесо — масштаб. Средняя или правая кнопка — сдвиг. Shift при размере — сохранить пропорции. Alt — без привязки. Delete — удалить, Ctrl+D — копия."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.62, 0.66, 0.75))
	v.add_child(hint)


func _build_right(hb: HBoxContainer) -> void:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(340.0, 0.0)
	col.add_theme_constant_override("separation", 5)
	hb.add_child(col)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(sc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 5)
	sc.add_child(v)
	_head(v, "Слои (верхний сверху)")
	var lsc := ScrollContainer.new()
	lsc.custom_minimum_size = Vector2(0.0, 150.0)
	lsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(lsc)
	layer_box = VBoxContainer.new()
	layer_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layer_box.add_theme_constant_override("separation", 2)
	lsc.add_child(layer_box)
	var lb := HBoxContainer.new()
	v.add_child(lb)
	_btn(lb, "Выше", func() -> void: move_sel(1), "Перетащить в списке или нажать")
	_btn(lb, "Ниже", func() -> void: move_sel(-1))
	_btn(lb, "Копия", func() -> void: duplicate_sel(), "Ctrl+D")
	_btn(lb, "Удалить", func() -> void: delete_sel(), "Delete")
	v.add_child(HSeparator.new())
	prop_box = VBoxContainer.new()
	prop_box.add_theme_constant_override("separation", 5)
	v.add_child(prop_box)
	v.add_child(HSeparator.new())
	var wc := _chk(col, "Показать на ветру", true, func(on: bool) -> void: wind_box.visible = on)
	wc.focus_mode = Control.FOCUS_NONE
	wind_box = Control.new()
	wind_box.custom_minimum_size = Vector2(0.0, 120.0)
	col.add_child(wind_box)
	wind = TextureRect.new()
	wind.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wind.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wind.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if wave_code != "":
		var sh := Shader.new()
		sh.code = wave_code
		var mat := ShaderMaterial.new()
		mat.shader = sh
		wind.material = mat
	wind_box.add_child(wind)
	save_note = Label.new()
	save_note.add_theme_font_size_override("font_size", 12)
	save_note.add_theme_color_override("font_color", Color(0.5, 0.9, 0.6))
	col.add_child(save_note)
	_btn(col, "Сохранить в «Мои флаги»", func() -> void: do_save(false), "Флаг сохранится в списке, но не будет применён")
	var ba := _btn(col, "Сохранить и применить", func() -> void: do_save(true), "Флаг станет флагом вашего государства")
	ba.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))


# ---------- открытие ----------
func open_with(start: Dictionary, p: Dictionary) -> void:
	drafts = p.get("drafts", [])
	edit_id = String(p.get("edit_id", ""))
	pal = p.get("pal", [])
	countries = p.get("countries", [])
	cur_flag_id = String(p.get("cur", ""))
	tool = ""
	cv.poly = []
	set_doc(start)
	fill_countries()
	fill_drafts()
	confirm_bar.visible = false
	save_note.text = ""
	cv.view_reset()


func set_doc(d: Dictionary) -> void:
	doc = d
	if not doc.has("gv"):
		doc["gv"] = []
	if not doc.has("gh"):
		doc["gh"] = []
	sel = -1
	hist = []
	redo_st = []
	saved_json = JSON.stringify(doc)
	name_edit.text = String(doc.get("name", ""))
	full_refresh()


func fill_countries() -> void:
	cty_opt.clear()
	for c in countries:
		cty_opt.add_item(String((c as Array)[0]))
	if countries.size() > 0:
		cty_opt.select(0)
		fill_flags(0)


func fill_flags(ci: int) -> void:
	flg_opt.clear()
	if ci < 0 or ci >= countries.size():
		return
	for f in (countries[ci] as Array)[1]:
		flg_opt.add_item(String((f as Array)[1]))
		flg_opt.set_item_metadata(flg_opt.item_count - 1, String((f as Array)[0]))


func set_drafts(arr: Array) -> void:
	drafts = arr
	fill_drafts()


func fill_drafts() -> void:
	draft_opt.clear()
	if drafts.is_empty():
		draft_opt.add_item("(пока нет сохранённых)")
		draft_opt.disabled = true
		return
	draft_opt.disabled = false
	var sel_i := 0
	for i in drafts.size():
		var d: Dictionary = drafts[i]
		draft_opt.add_item(String(d["name"]))
		draft_opt.set_item_metadata(i, String(d["id"]))
		if String(d["id"]) == edit_id:
			sel_i = i
	draft_opt.select(sel_i)


func open_draft() -> void:
	if drafts.is_empty() or draft_opt.selected < 0:
		return
	var d: Dictionary = drafts[draft_opt.selected]
	if not d.has("doc"):
		status("Этот флаг сделан старым редактором, его нельзя открыть по слоям.")
		return
	snap_undo()
	edit_id = String(d["id"])
	var nd: Dictionary = (d["doc"] as Dictionary).duplicate(true)
	doc = nd
	if not doc.has("gv"):
		doc["gv"] = []
	if not doc.has("gh"):
		doc["gh"] = []
	sel = -1
	name_edit.text = String(doc.get("name", ""))
	full_refresh()


func delete_draft() -> void:
	if drafts.is_empty() or draft_opt.selected < 0:
		return
	var id := String(draft_opt.get_item_metadata(draft_opt.selected))
	draft_delete.emit(id)
	if id == edit_id:
		edit_id = ""


# ---------- сохранение, закрытие ----------
func is_dirty() -> bool:
	return JSON.stringify(doc) != saved_json


func do_save(apply: bool) -> void:
	doc["name"] = name_edit.text.strip_edges() if name_edit.text.strip_edges() != "" else "Мой флаг"
	name_edit.text = String(doc["name"])
	save_requested.emit(doc.duplicate(true), apply, edit_id)


func saved(id: String, apply: bool) -> void:
	edit_id = id
	saved_json = JSON.stringify(doc)
	save_note.text = "Сохранено: %s" % String(doc["name"])
	if not apply:
		fill_drafts()


func request_close() -> void:
	if is_dirty() and not confirm_bar.visible:
		confirm_bar.visible = true
		return
	confirm_bar.visible = false
	closed.emit()


# Esc: сначала отменяем начатое, потом выделение, потом закрываем
func on_escape() -> void:
	if confirm_bar.visible:
		confirm_bar.visible = false
	elif tool != "" or cv.poly.size() > 0:
		cv.cancel_tool()
	elif sel >= 0:
		select(-1)
	else:
		request_close()


# ---------- документ ----------
func build_svg() -> String:
	return FD.build_svg(doc, syms)


func layer() -> Dictionary:
	var ls: Array = doc.get("layers", [])
	if sel >= 0 and sel < ls.size():
		return ls[sel]
	return {}


func layer_name(i: int) -> String:
	var L: Dictionary = doc["layers"][i]
	var t := String(L["t"])
	if t == "sym":
		var k := int(L.get("n", 0))
		if k >= 0 and k < syms.size():
			return String((syms[k] as Array)[0])
	return FD.type_name(t)


func snap_undo() -> void:
	hist.append(JSON.stringify(doc))
	if hist.size() > 120:
		hist.pop_front()
	redo_st = []
	_undo_state()


func _undo_state() -> void:
	if undo_btn != null:
		undo_btn.disabled = hist.is_empty()
		redo_btn.disabled = redo_st.is_empty()


func _restore(js: String) -> void:
	var d: Variant = JSON.parse_string(js)
	if typeof(d) == TYPE_DICTIONARY:
		doc = d
		sel = mini(sel, (doc["layers"] as Array).size() - 1)
		name_edit.text = String(doc.get("name", ""))
		full_refresh()


func undo() -> void:
	if hist.is_empty():
		return
	redo_st.append(JSON.stringify(doc))
	_restore(String(hist.pop_back()))


func redo() -> void:
	if redo_st.is_empty():
		return
	hist.append(JSON.stringify(doc))
	_restore(String(redo_st.pop_back()))


func full_refresh() -> void:
	layers_rebuild()
	props_rebuild()
	palette_rebuild()
	_undo_state()
	set_tool("")
	cv.refresh()


func after_edit(list: bool = true) -> void:
	if list:
		layers_rebuild()
	props_rebuild()
	palette_rebuild()
	cv.refresh()


func changed() -> void:
	cv.refresh()


func wind_update(t: Texture2D) -> void:
	if wind != null:
		wind.texture = t


func new_shape(t: String, x: float, y: float, w: float, h: float) -> Dictionary:
	var fill := cur_fill
	if fill.to_lower() == String(doc.get("bg", "#ffffff")).to_lower():
		fill = "#cc1a1f" if FD.col_of(fill).get_luminance() > 0.5 else "#ffffff"
	var L := FD.new_layer(t, x, y, w, h, fill)
	if t == "sym":
		L["n"] = cur_sym
	return L


func add_layer(L: Dictionary) -> void:
	(doc["layers"] as Array).append(L)
	sel = (doc["layers"] as Array).size() - 1
	layers_rebuild()
	props_rebuild()
	cv.refresh()


func select(i: int) -> void:
	sel = i
	layers_rebuild()
	props_rebuild()
	cv.queue_redraw()


func delete_sel() -> void:
	if sel < 0:
		return
	snap_undo()
	(doc["layers"] as Array).remove_at(sel)
	sel = mini(sel, (doc["layers"] as Array).size() - 1)
	after_edit()


func duplicate_sel() -> void:
	if sel < 0:
		return
	snap_undo()
	var c: Dictionary = (layer() as Dictionary).duplicate(true)
	c["x"] = float(c["x"]) + 3.0
	c["y"] = float(c["y"]) + 3.0
	c["lock"] = false
	(doc["layers"] as Array).insert(sel + 1, c)
	sel += 1
	after_edit()


func move_sel(dir: int) -> void:
	var ls: Array = doc["layers"]
	var j := sel + dir
	if sel < 0 or j < 0 or j >= ls.size():
		return
	snap_undo()
	var t: Variant = ls[sel]
	ls[sel] = ls[j]
	ls[j] = t
	sel = j
	after_edit()


func reorder(from: int, to: int, below: bool) -> void:
	var ls: Array = doc["layers"]
	if from < 0 or from >= ls.size() or to < 0 or to >= ls.size():
		return
	var ins := to + (0 if below else 1)
	if from < ins:
		ins -= 1
	if ins == from:
		return
	snap_undo()
	var L: Variant = ls[from]
	ls.remove_at(from)
	ls.insert(ins, L)
	sel = ins
	after_edit()


func add_guide(axis: int) -> void:
	snap_undo()
	(doc["gv"] if axis == 0 else doc["gh"]).append(45.0 if axis == 0 else 30.0)
	cv.queue_redraw()
	status("Направляющая добавлена на середину: потяните её мышью в нужное место.")


# ---------- старт ----------
func new_blank() -> void:
	snap_undo()
	var d := FD.new_doc("#ffffff")
	d["name"] = String(doc.get("name", "Мой флаг"))
	d["gv"] = doc.get("gv", [])
	d["gh"] = doc.get("gh", [])
	doc = d
	sel = -1
	edit_id = ""
	full_refresh()


func _pal_hex(i: int, def: String) -> String:
	if i < pal.size():
		return FD.col_hex(pal[i])
	return def


func apply_template(i: int) -> void:
	snap_undo()
	var nm := String(doc.get("name", "Мой флаг"))
	var gv: Array = doc.get("gv", [])
	var gh: Array = doc.get("gh", [])
	doc = FD.template_doc(i, _pal_hex(0, "#cc1a1f"), _pal_hex(1, "#f7f7f7"), _pal_hex(2, "#0d3a94"))
	doc["name"] = nm
	doc["gv"] = gv
	doc["gh"] = gh
	sel = -1
	edit_id = ""
	full_refresh()


func base_from(id: String) -> void:
	if id == "" or not entry_fn.is_valid():
		return
	var e: Dictionary = entry_fn.call(id)
	if e.is_empty():
		return
	snap_undo()
	var d := FD.new_doc("#ffffff")
	d["name"] = String(doc.get("name", "Мой флаг"))
	d["gv"] = doc.get("gv", [])
	d["gh"] = doc.get("gh", [])
	var L := FD.base_layer(String(e["svg"]))
	L["src"] = id
	L["lock"] = true
	(d["layers"] as Array).append(L)
	doc = d
	sel = -1
	edit_id = ""
	full_refresh()
	status("Флаг взят основой (слой закреплён). Рисуйте поверх или нажмите «Разобрать основу на фигуры».")


func split_base() -> void:
	var ls: Array = doc["layers"]
	var idx := -1
	if sel >= 0 and String(ls[sel]["t"]) == "raw":
		idx = sel
	else:
		for i in ls.size():
			if String(ls[i]["t"]) == "raw" and String(ls[i].get("src", "")) != "":
				idx = i
				break
	if idx < 0:
		status("Нет основы из флага игры. Сначала возьмите флаг как основу.")
		return
	var src := String(ls[idx].get("src", ""))
	var e: Dictionary = entry_fn.call(src) if (src != "" and entry_fn.is_valid()) else {}
	if e.is_empty() or e.has("lic"):
		status("Этот флаг взят из настоящего файла, и разобрать его на фигуры нельзя. Разбираются только флаги, нарисованные в игре.")
		return
	var parts: Array = FD.split_svg(String(e["svg"]))
	if parts.is_empty():
		status("Этот флаг слишком сложный: его нельзя разобрать на фигуры.")
		return
	snap_undo()
	ls.remove_at(idx)
	for k in parts.size():
		ls.insert(idx + k, parts[k])
	sel = idx + parts.size() - 1
	after_edit()
	status("Флаг разобран на %d слоёв. Можно менять цвет, размер и порядок каждого." % parts.size())


# ---------- инструменты ----------
func set_tool(t: String) -> void:
	if t != "poly" and cv != null:
		cv.poly = []
	tool = t
	for k in tool_btns:
		(tool_btns[k] as Button).set_pressed_no_signal(String(k) == t)
	if cv != null:
		cv.mouse_default_cursor_shape = Control.CURSOR_CROSS if t != "" else Control.CURSOR_ARROW
		cv.queue_redraw()
	match t:
		"":
			status("")
		"poly":
			status("Щёлкайте по точкам. Двойной щелчок, Enter или щелчок по первой точке — закончить. Правая кнопка — отмена.")
		"pipette":
			status("Щёлкните по флагу, чтобы взять цвет.")
		"band":
			status("Проведите мышью линию вдоль будущей полосы. Щелчок — горизонтальная полоса.")
		_:
			status("Тяните мышью по флагу, чтобы нарисовать фигуру. Щелчок — фигура обычного размера. Правая кнопка — отмена.")


func status(tx: String) -> void:
	if status_lbl == null:
		return
	if tx == "":
		tx = "Щёлкните по фигуре, чтобы выбрать. Белые квадраты — размер, кружок сверху — поворот. Колесо мыши — масштаб холста. Цвета: щелчок — заливка, Shift + щелчок — обводка."
	status_lbl.text = tx


func start_pipette(target: String) -> void:
	pip_target = target
	set_tool("pipette")


func pipette_at(c: Control, pos: Vector2) -> void:
	var d: Vector2 = c.to_doc(pos)
	if c.img != null and d.x >= 0.0 and d.y >= 0.0 and d.x < 90.0 and d.y < 60.0:
		var px := Vector2i(int(d.x * c.rs), int(d.y * c.rs))
		if px.x < c.img.get_width() and px.y < c.img.get_height():
			apply_color(c.img.get_pixelv(px), pip_target)
	set_tool("")


func apply_color(c: Color, target: String) -> void:
	var hx := FD.col_hex(c)
	snap_undo()
	var L := layer()
	if target == "bg" or L.is_empty() or String(L["t"]) == "raw":
		doc["bg"] = hx
	elif target == "stroke":
		L["stroke"] = hx
		if float(L.get("sw", 0.0)) <= 0.0:
			L["sw"] = 1.0
	else:
		L["fill"] = hx
	cur_fill = hx
	after_edit()


# ---------- слои ----------
func layers_rebuild() -> void:
	for ch in layer_box.get_children():
		ch.queue_free()
	rows = []
	var ls: Array = doc.get("layers", [])
	if ls.is_empty():
		var l := Label.new()
		l.text = "Слоёв пока нет. Выберите фигуру слева и нарисуйте её на флаге."
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 12)
		layer_box.add_child(l)
		return
	for i in range(ls.size() - 1, -1, -1):
		var L: Dictionary = ls[i]
		var r := Row.new()
		r.ed = self
		r.idx = i
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.28, 0.24, 0.12) if i == sel else Color(0.16, 0.18, 0.23)
		sb.set_corner_radius_all(4)
		sb.content_margin_left = 4
		sb.content_margin_right = 4
		sb.content_margin_top = 2
		sb.content_margin_bottom = 2
		if i == sel:
			sb.border_color = Color(1.0, 0.78, 0.2)
			sb.set_border_width_all(1)
		r.add_theme_stylebox_override("panel", sb)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 4)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.add_child(h)
		var sw := ColorRect.new()
		sw.custom_minimum_size = Vector2(16, 16)
		sw.color = FD.col_of(String(L.get("fill", "#888888")), Color(0.5, 0.5, 0.5))
		if String(L["t"]) == "raw":
			sw.color = Color(0.5, 0.5, 0.55)
		sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(sw)
		r.swatch = sw
		var nm := Label.new()
		nm.text = layer_name(i)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.clip_text = true
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		nm.add_theme_font_size_override("font_size", 13)
		h.add_child(nm)
		var ib := i
		var eye := Button.new()
		eye.text = "Вид" if not bool(L.get("hide", false)) else "Скр"
		eye.toggle_mode = true
		eye.button_pressed = bool(L.get("hide", false))
		eye.focus_mode = Control.FOCUS_NONE
		eye.add_theme_font_size_override("font_size", 11)
		eye.tooltip_text = "Вид — слой виден, Скр — скрыт. Нажмите, чтобы переключить"
		eye.toggled.connect(func(on: bool) -> void:
			snap_undo()
			doc["layers"][ib]["hide"] = on
			after_edit())
		h.add_child(eye)
		var lk := Button.new()
		lk.text = "Закр" if bool(L.get("lock", false)) else "Своб"
		lk.toggle_mode = true
		lk.button_pressed = bool(L.get("lock", false))
		lk.focus_mode = Control.FOCUS_NONE
		lk.add_theme_font_size_override("font_size", 11)
		lk.tooltip_text = "Своб — слой можно двигать мышью, Закр — закреплён, на холсте его не задеть"
		lk.toggled.connect(func(on: bool) -> void:
			snap_undo()
			doc["layers"][ib]["lock"] = on
			after_edit())
		h.add_child(lk)
		layer_box.add_child(r)
		rows.append(r)
	_pol(layer_box)


# ---------- свойства выбранной фигуры ----------
func _color_row(parent: Control, text: String, hx: String, target: String) -> ColorPickerButton:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var lb := Label.new()
	lb.text = text
	lb.custom_minimum_size = Vector2(70.0, 0.0)
	row.add_child(lb)
	var cp := ColorPickerButton.new()
	cp.custom_minimum_size = Vector2(70.0, 26.0)
	cp.edit_alpha = false
	cp.focus_mode = Control.FOCUS_NONE
	cp.color = FD.col_of(hx, Color.WHITE)
	cp.pressed.connect(func() -> void: snap_undo())
	cp.color_changed.connect(func(c: Color) -> void:
		var L := layer()
		var hs := FD.col_hex(c)
		if target == "bg":
			doc["bg"] = hs
		elif L.is_empty():
			return
		elif target == "stroke":
			L["stroke"] = hs
		else:
			L["fill"] = hs
		cur_fill = hs if target != "stroke" else cur_fill
		cv.refresh()
		_swatches())
	row.add_child(cp)
	_btn(row, "Пипетка", func() -> void: start_pipette(target), "Взять цвет с флага")
	return cp


func _swatches() -> void:
	var ls: Array = doc.get("layers", [])
	for r in rows:
		var i: int = (r as Row).idx
		if i < ls.size() and String(ls[i]["t"]) != "raw":
			(r as Row).swatch.color = FD.col_of(String(ls[i].get("fill", "#888888")), Color(0.5, 0.5, 0.5))


func _slider(parent: Control, text: String, key: String, mn: float, mx: float, step: float) -> void:
	var L := layer()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var lb := Label.new()
	lb.text = text
	lb.custom_minimum_size = Vector2(112.0, 0.0)
	lb.add_theme_font_size_override("font_size", 13)
	row.add_child(lb)
	var hs := HSlider.new()
	hs.min_value = mn
	hs.max_value = mx
	hs.step = step
	hs.scrollable = false
	hs.focus_mode = Control.FOCUS_NONE
	hs.set_value_no_signal(float(L.get(key, 0.0)))
	hs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hs.custom_minimum_size = Vector2(80.0, 20.0)
	hs.drag_started.connect(func() -> void: snap_undo())
	hs.value_changed.connect(func(v: float) -> void:
		var LL := layer()
		if LL.is_empty():
			return
		LL[key] = int(v) if step >= 1.0 else v
		cv.refresh())
	row.add_child(hs)


func props_rebuild() -> void:
	for ch in prop_box.get_children():
		ch.queue_free()
	var L := layer()
	if L.is_empty():
		_head(prop_box, "Фон флага")
		_color_row(prop_box, "Цвет фона", String(doc.get("bg", "#ffffff")), "bg")
		var h := Label.new()
		h.text = "Выберите фигуру на флаге или в списке слоёв, чтобы менять её."
		h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		h.add_theme_font_size_override("font_size", 12)
		h.add_theme_color_override("font_color", Color(0.62, 0.66, 0.75))
		prop_box.add_child(h)
		return
	var t := String(L["t"])
	_head(prop_box, layer_name(sel))
	if t == "raw":
		var rl := Label.new()
		rl.text = "Готовый рисунок. Его можно двигать, менять размер и порядок. Кнопка «Разобрать основу на фигуры» делит его на слои, если он нарисован в игре."
		rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rl.add_theme_font_size_override("font_size", 12)
		prop_box.add_child(rl)
	else:
		_color_row(prop_box, "Заливка", String(L.get("fill", "#ffffff")), "fill")
		if t != "sym":
			var on := String(L.get("stroke", "")) != ""
			var sr := HBoxContainer.new()
			prop_box.add_child(sr)
			_chk(sr, "Обводка", on, func(v: bool) -> void:
				snap_undo()
				var LL := layer()
				LL["stroke"] = "#111111" if v else ""
				if v and float(LL.get("sw", 0.0)) <= 0.0:
					LL["sw"] = 1.0
				after_edit())
			if on:
				_color_row(prop_box, "Цвет обводки", String(L.get("stroke", "#111111")), "stroke")
				_slider(prop_box, "Толщина обводки", "sw", 0.2, 5.0, 0.1)
		if t == "sym":
			var so := OptionButton.new()
			so.focus_mode = Control.FOCUS_NONE
			for i in syms.size():
				so.add_item(String((syms[i] as Array)[0]))
			so.select(int(L.get("n", 0)))
			so.item_selected.connect(func(i: int) -> void:
				snap_undo()
				layer()["n"] = i
				cur_sym = i
				after_edit())
			prop_box.add_child(so)
		for pr in FD.PARAMS.get(t, []):
			var a: Array = pr
			_slider(prop_box, String(a[1]), String(a[0]), float(a[2]), float(a[3]), float(a[4]))
		if FD.has_corner(t):
			_slider(prop_box, "Скругление углов", "r", 0.0, 15.0, 0.25)
	var fr := HBoxContainer.new()
	prop_box.add_child(fr)
	_btn(fr, "⇄ Отразить", flip_x, "Зеркально по горизонтали")
	_btn(fr, "⇅ Отразить", flip_y, "Зеркально по вертикали")
	_btn(fr, "Поворот 0°", rot_zero)
	_pol(prop_box)


func flip_x() -> void:
	snap_undo()
	var L := layer()
	L["fx"] = not bool(L.get("fx", false))
	cv.refresh()


func flip_y() -> void:
	snap_undo()
	var L := layer()
	L["fy"] = not bool(L.get("fy", false))
	cv.refresh()


func rot_zero() -> void:
	snap_undo()
	layer()["rot"] = 0.0
	cv.refresh()


# ---------- цвета ----------
func palette_rebuild() -> void:
	for ch in pal_grid.get_children():
		ch.queue_free()
	var seen := {}
	var list: Array = []
	var add := func(hx: String) -> void:
		hx = hx.to_lower()
		if hx != "" and not seen.has(hx) and list.size() < 40:
			seen[hx] = true
			list.append(hx)
	add.call(String(doc.get("bg", "#ffffff")))
	for L in doc.get("layers", []):
		add.call(String(L.get("fill", "")) if String(L["t"]) != "raw" else "")
		add.call(String(L.get("stroke", "")))
	for c in pal:
		add.call(FD.col_hex(c))
	for b in ["#ffffff", "#000000", "#cc1a1f", "#0d3a94", "#0f8a3c", "#ffc400", "#f28c28", "#1e90d6", "#6b2d8c", "#7a4a21", "#8c8c8c", "#e8c8a0"]:
		add.call(String(b))
	for hx in list:
		var b := Button.new()
		b.custom_minimum_size = Vector2(22.0, 22.0)
		b.focus_mode = Control.FOCUS_NONE
		var col := FD.col_of(String(hx), Color.WHITE)
		for st in ["normal", "hover", "pressed"]:
			var sb := StyleBoxFlat.new()
			sb.bg_color = col if st != "hover" else col.lightened(0.15)
			sb.set_border_width_all(1)
			sb.border_color = Color(0.9, 0.9, 0.95, 0.7) if st == "hover" else Color(0, 0, 0, 0.6)
			sb.set_corner_radius_all(3)
			b.add_theme_stylebox_override(st, sb)
		b.tooltip_text = String(hx)
		b.pressed.connect(func() -> void:
			apply_color(col, "stroke" if Input.is_key_pressed(KEY_SHIFT) else "fill"))
		pal_grid.add_child(b)
	_pol(pal_grid)


# ---------- клавиши ----------
func _input(ev: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var k := ev as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	var fo := get_viewport().gui_get_focus_owner()
	if fo is LineEdit or fo is TextEdit:
		return
	var used := true
	match k.keycode:
		KEY_DELETE, KEY_BACKSPACE:
			delete_sel()
		KEY_ENTER, KEY_KP_ENTER:
			if tool == "poly":
				cv.finish_poly()
			else:
				used = false
		KEY_D:
			if k.ctrl_pressed or k.meta_pressed:
				duplicate_sel()
			else:
				used = false
		KEY_Z:
			if k.ctrl_pressed or k.meta_pressed:
				if k.shift_pressed:
					redo()
				else:
					undo()
			else:
				used = false
		KEY_Y:
			if k.ctrl_pressed or k.meta_pressed:
				redo()
			else:
				used = false
		_:
			used = false
	if used:
		get_viewport().set_input_as_handled()
