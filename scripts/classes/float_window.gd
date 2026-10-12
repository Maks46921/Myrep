extends Control

var frac := Rect2(0.0, 0.0, 0.3, 0.3)     # положение и размер как доли рабочей области
var default_frac := Rect2(0.0, 0.0, 0.3, 0.3)
var desk := 0                             # 0..2 — экран, -1 — всегда видно, -2 — окно события
var body: VBoxContainer
var collapsed := false
var closed := false                       # закрыто игроком (кнопка ×); возвращается через меню «Окна»
var closable := true
var _xbtn: Button
signal close_requested(w)
var accent := Color(0.357, 0.553, 0.937)
var _vb: VBoxContainer
var _title_bar: PanelContainer
var _title: Label
var _btn: Button
var _grips: Array = []
var _content: Control
var _drag := false
var lock_why := ""                        # v50: почему окно недоступно ("" — доступно)
var _lock_bar: PanelContainer = null
var _lock_lbl: Label = null
var _lock_cover: Control = null
var _drag_off := Vector2.ZERO
var _rmode := 0
var _rs_size := Vector2.ZERO
var _rs_mouse := Vector2.ZERO
var _sb: StyleBoxFlat = null
var _tsb: StyleBoxFlat = null
var _bg: Panel = null

func setup(title: String, scrolling: bool, acc: Color = Color(0.357, 0.553, 0.937)) -> void:
	accent = acc
	custom_minimum_size = Vector2(190.0, 90.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.090, 0.106, 0.149, 0.95)
	sb.border_color = Color(0.169, 0.196, 0.282)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(9)
	sb.shadow_color = Color(0, 0, 0, 0.42)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0.0, 3.0)
	bg.add_theme_stylebox_override("panel", sb)
	_sb = sb
	_bg = bg
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# v45_1: мягкий отблеск сверху окна
	bg.draw.connect(func() -> void:
		var hh: float = minf(90.0, bg.size.y * 0.5)
		bg.draw_polygon(PackedVector2Array([Vector2(1.0, 1.0), Vector2(bg.size.x - 1.0, 1.0), Vector2(bg.size.x - 1.0, hh), Vector2(1.0, hh)]),
			PackedColorArray([Color(1, 1, 1, 0.035), Color(1, 1, 1, 0.035), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0)])))
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vb = VBoxContainer.new()
	_vb.add_theme_constant_override("separation", 2)
	add_child(_vb)
	_vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 4)
	_title_bar = PanelContainer.new()
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = Color(0.122, 0.141, 0.200).lerp(accent, 0.20)
	tsb.set_corner_radius_all(6)
	tsb.border_width_left = 3
	tsb.border_color = accent
	tsb.content_margin_left = 9.0
	tsb.content_margin_right = 3.0
	tsb.content_margin_top = 3.0
	tsb.content_margin_bottom = 3.0
	_title_bar.add_theme_stylebox_override("panel", tsb)
	_tsb = tsb
	_title_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_title_bar.mouse_default_cursor_shape = Control.CURSOR_MOVE
	_title_bar.gui_input.connect(_title_input)
	# v45_1: градиент цвета раздела в заголовке
	_title_bar.draw.connect(func() -> void:
		var r := Rect2(Vector2(3.0, 0.0), _title_bar.size - Vector2(3.0, 0.0))
		var a0 := Color(accent.r, accent.g, accent.b, 0.30)
		var a1 := Color(accent.r, accent.g, accent.b, 0.0)
		_title_bar.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
			PackedColorArray([a0, a1, a1, a0]))
		_title_bar.draw_line(Vector2(3.0, 0.5), Vector2(_title_bar.size.x * 0.6, 0.5), Color(1, 1, 1, 0.10), 1.0))
	_vb.add_child(_title_bar)
	var hb := HBoxContainer.new()
	_title_bar.add_child(hb)
	_title = Label.new()
	_title.text = title
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.clip_text = true
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.add_theme_font_size_override("font_size", 14)
	_title.add_theme_color_override("font_color", Color(0.93, 0.95, 1.0))
	hb.add_child(_title)
	_btn = Button.new()
	_btn.text = "–"
	_btn.flat = true
	_btn.focus_mode = Control.FOCUS_NONE
	_btn.tooltip_text = "Свернуть / развернуть"
	_btn.add_theme_color_override("font_color", Color(0.75, 0.8, 0.92))
	_btn.pressed.connect(toggle_collapse)
	hb.add_child(_btn)
	_xbtn = Button.new()
	_xbtn.text = "×"
	_xbtn.flat = true
	_xbtn.focus_mode = Control.FOCUS_NONE
	_xbtn.tooltip_text = "Закрыть окно (вернуть — кнопка «Окна» вверху)"
	_xbtn.add_theme_color_override("font_color", Color(0.95, 0.65, 0.65))
	_xbtn.pressed.connect(func() -> void: close_requested.emit(self))
	hb.add_child(_xbtn)
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 8)
	mc.add_theme_constant_override("margin_right", 8)
	mc.add_theme_constant_override("margin_top", 6)
	mc.add_theme_constant_override("margin_bottom", 8)
	mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 6)
	mc.add_child(body)
	if scrolling:
		var sc := ScrollContainer.new()
		sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		# v35: содержимое растягивается на высоту окна — графики с флагом EXPAND растут вместе с окном
		mc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		body.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_vb.add_child(sc)
		sc.add_child(mc)
		_content = sc
	else:
		mc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		body.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_vb.add_child(mc)
		_content = mc
	for mode in [1, 2, 3]:
		var gr := Control.new()
		gr.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(gr)
		if mode == 1:
			gr.anchor_left = 1.0
			gr.anchor_right = 1.0
			gr.anchor_bottom = 1.0
			gr.offset_left = -6.0
			gr.offset_top = 34.0
			gr.offset_bottom = -16.0
			gr.mouse_default_cursor_shape = Control.CURSOR_HSIZE
		elif mode == 2:
			gr.anchor_top = 1.0
			gr.anchor_bottom = 1.0
			gr.anchor_right = 1.0
			gr.offset_top = -6.0
			gr.offset_right = -16.0
			gr.mouse_default_cursor_shape = Control.CURSOR_VSIZE
		else:
			gr.anchor_left = 1.0
			gr.anchor_right = 1.0
			gr.anchor_top = 1.0
			gr.anchor_bottom = 1.0
			gr.offset_left = -18.0
			gr.offset_top = -18.0
			gr.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
			var mark := Label.new()
			mark.text = "◢"
			mark.modulate = Color(0.55, 0.65, 0.85, 0.7)
			mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mark.add_theme_font_size_override("font_size", 12)
			mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			gr.add_child(mark)
		gr.gui_input.connect(_grip_input.bind(mode))
		_grips.append(gr)

# v51: перекраска окна (смена режима): акцент заголовка, фон и рамка
func set_skin(acc: Color, bg: Color, border: Color) -> void:
	accent = acc
	if _tsb != null:
		_tsb.bg_color = bg.lightened(0.06).lerp(acc, 0.20)
		_tsb.border_color = acc
	if _sb != null:
		_sb.bg_color = Color(bg.r, bg.g, bg.b, 0.95)
		_sb.border_color = border
	if _title_bar != null:
		_title_bar.queue_redraw()
	if _bg != null:
		_bg.queue_redraw()


# v50: недоступное окно затемняется, сверху — причина; содержимое можно читать и прокручивать, но не нажимать
func set_locked(why: String) -> void:
	if why == lock_why:
		return
	lock_why = why
	if _lock_bar == null:
		_lock_bar = PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.20, 0.13, 0.10, 0.96)
		sb.border_color = Color(0.93, 0.62, 0.33, 0.85)
		sb.border_width_left = 3
		sb.set_corner_radius_all(5)
		sb.content_margin_left = 8.0
		sb.content_margin_right = 6.0
		sb.content_margin_top = 3.0
		sb.content_margin_bottom = 3.0
		_lock_bar.add_theme_stylebox_override("panel", sb)
		_lock_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_lock_lbl = Label.new()
		_lock_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lock_lbl.add_theme_font_size_override("font_size", 12)
		_lock_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.62))
		_lock_bar.add_child(_lock_lbl)
		_vb.add_child(_lock_bar)
		_vb.move_child(_lock_bar, 1)
		_lock_cover = Control.new()
		_lock_cover.mouse_filter = Control.MOUSE_FILTER_STOP
		_lock_cover.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
		_lock_cover.gui_input.connect(_cover_input)
		add_child(_lock_cover)
		_content.resized.connect(_place_cover)
		_content.item_rect_changed.connect(_place_cover)
	_lock_lbl.text = "✖  " + why
	_lock_bar.visible = why != ""
	_lock_cover.visible = why != ""
	_lock_cover.tooltip_text = why
	_content.modulate = Color(0.62, 0.62, 0.66, 0.78) if why != "" else Color(1, 1, 1, 1)
	_place_cover()


func _place_cover() -> void:
	if _lock_cover == null or not _lock_cover.visible:
		return
	_lock_cover.position = _content.position + _vb.position
	_lock_cover.size = _content.size if not collapsed else Vector2.ZERO


func _cover_input(ev: InputEvent) -> void:
	var mb := ev as InputEventMouseButton
	if mb == null or not mb.pressed:
		return
	move_to_front()
	var sc := _content as ScrollContainer
	if sc != null and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		sc.scroll_vertical += 48 * (1 if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1)


func set_closable(on: bool) -> void:
	closable = on
	if _xbtn != null:
		_xbtn.visible = on

func get_title() -> String:
	return _title.text

func set_title(t: String) -> void:
	_title.text = t

func refresh_wraps(n: Node = null) -> void:
	if n == null:
		n = self
	for ch in n.get_children():
		if ch is Button and (ch as Button).autowrap_mode != TextServer.AUTOWRAP_OFF:
			(ch as Button).update_minimum_size()
		refresh_wraps(ch)

func apply_frac() -> void:
	var p := get_parent() as Control
	if p == null:
		return
	var ps: Vector2 = p.size
	position = (frac.position * ps).round()
	var h: float = 36.0 if collapsed else frac.size.y * ps.y
	size = Vector2(frac.size.x * ps.x, h)

func _store() -> void:
	var p := get_parent() as Control
	if p == null or p.size.x < 1.0 or p.size.y < 1.0:
		return
	frac.position = position / p.size
	frac.size.x = size.x / p.size.x
	if not collapsed:
		frac.size.y = size.y / p.size.y

func toggle_collapse() -> void:
	if not collapsed:
		_store()
	collapsed = not collapsed
	_content.visible = not collapsed
	_btn.text = "+" if collapsed else "–"
	custom_minimum_size.y = 36.0 if collapsed else 90.0
	for i in [0, 2]:
		(_grips[i] as Control).visible = not collapsed
	apply_frac()

func _gui_input(ev: InputEvent) -> void:
	var mb := ev as InputEventMouseButton
	if mb != null and mb.pressed:
		move_to_front()

func _title_input(ev: InputEvent) -> void:
	var p := get_parent() as Control
	if p == null:
		return
	var mb := ev as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.double_click and mb.pressed:
			toggle_collapse()
			return
		_drag = mb.pressed
		if mb.pressed:
			move_to_front()
			_drag_off = p.get_local_mouse_position() - position
		else:
			_store()
		return
	var mm := ev as InputEventMouseMotion
	if mm != null and _drag:
		var m: Vector2 = p.get_local_mouse_position() - _drag_off
		m.x = clampf(m.x, 60.0 - size.x, p.size.x - 60.0)
		m.y = clampf(m.y, 0.0, p.size.y - 30.0)
		position = m

func _grip_input(ev: InputEvent, mode: int) -> void:
	var p := get_parent() as Control
	if p == null:
		return
	var mb := ev as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			_rmode = mode
			move_to_front()
			_rs_size = size
			_rs_mouse = p.get_local_mouse_position()
		else:
			_rmode = 0
			_store()
			refresh_wraps()
		return
	var mm := ev as InputEventMouseMotion
	if mm != null and _rmode != 0:
		var d: Vector2 = p.get_local_mouse_position() - _rs_mouse
		var ns := _rs_size
		if _rmode == 1 or _rmode == 3:
			ns.x += d.x
		if _rmode == 2 or _rmode == 3:
			ns.y += d.y
		ns.x = clampf(ns.x, custom_minimum_size.x, maxf(custom_minimum_size.x, p.size.x - position.x + 200.0))
		ns.y = clampf(ns.y, custom_minimum_size.y, maxf(custom_minimum_size.y, p.size.y - position.y + 200.0))
		size = ns
