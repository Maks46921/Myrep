extends SceneTree
# Скриншот меню выбора страны: pick=XX out=путь.png (под xvfb); проверяет, что карточка строится для выбранной страны.
func _init():
	var pick := "DE"
	var outp := OS.get_temp_dir().path_join("shot_menu_%s.png")
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("pick="): pick = String(a).substr(5)
		if String(a).begins_with("country="): pick = String(a).substr(8)
		if String(a).begins_with("out="): outp = String(a).substr(4)
	outp = outp % pick if outp.contains("%s") else outp
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	var menu = g.get_node_or_null("CountryMenu")
	if menu == null:
		g.show_country_menu(true)
		for i in 3: await process_frame
		menu = g.get_node_or_null("CountryMenu")
	if menu == null:
		print("FAIL: меню не открылось")
		quit(1)
		return
	var cm = _find(menu, "CountryMap")
	if cm == null:
		print("FAIL: нет карты в меню")
		quit(1)
		return
	cm.select(pick)
	for i in 8: await process_frame
	await create_timer(0.5).timeout
	root.get_viewport().get_texture().get_image().save_png(outp)
	print("saved ", outp)
	var bad := 0
	# v35: описание положения меняется с выбранной партией (и есть режим наблюдателя)
	var t0: String = g.menu_sit_rt.text if g.menu_sit_rt != null else ""
	if t0 == "":
		bad += 1; print("FAIL: нет описания положения партии")
	g.update_menu_party(1)
	if g.menu_sit_rt.text == t0:
		bad += 1; print("FAIL: описание не меняется при выборе другой партии")
	g.update_menu_party(g.OBSERVER_ID)
	if not g.menu_sit_rt.text.contains("ИИ"):
		bad += 1; print("FAIL: нет описания режима наблюдателя")
	# 0.56: карточки партий и полукруг; можно выбрать протестную партию
	var tabs0 = _find_cls(menu, "TabContainer")
	tabs0.current_tab = 1
	g.menu_fill_parties(pick, 9 if g.party_name_playable(String(g.cdat(pick, "PARTY_NAMES")[9])) else 1)
	for i in 6: await process_frame
	await create_timer(0.3).timeout
	root.get_viewport().get_texture().get_image().save_png(outp.replace(".png", "_party.png"))
	if g.menu_party_grid.get_child_count() < 4:
		bad += 1; print("FAIL: мало карточек партий (%d)" % g.menu_party_grid.get_child_count())
	if g.menu_party_sel == 0:
		bad += 1; print("FAIL: карточка партии не выбирается")
	var ccount := 0
	for c in g.MENU_POL_COLS: ccount += 1
	if ccount < 38:
		bad += 1; print("FAIL: не у всех стран цвет политической карты")
	g.menu_flt["eu"] = 2
	g.menu_apply_filters(cm, g.CDATA.keys())
	if not cm.dim.has("DE") or cm.dim.has("CH"):
		bad += 1; print("FAIL: фильтр «вне ЕС» не работает")
	g.menu_flt.clear()
	g.menu_apply_filters(cm, g.CDATA.keys())
	g.menu_fill_parties(pick, 0)
	tabs0.current_tab = 0
	# --- масштаб и перемещение карты выбора страны ---
	var gp: Vector2 = cm.get_global_rect().get_center()
	var z0: float = cm.zoom
	_btn(root, MOUSE_BUTTON_WHEEL_UP, true, gp)
	await process_frame
	# v49: камера плавная — масштаб догоняет цель за доли секунды
	if not (cm.zoom_t > z0 + 0.01):
		bad += 1; print("FAIL: колёсико не масштабирует карту (%.2f -> %.2f)" % [z0, cm.zoom_t])
	await create_timer(0.7).timeout
	if absf(cm.zoom - cm.zoom_t) > 0.01 * cm.zoom_t:
		bad += 1; print("FAIL: плавный масштаб не дошёл до цели (%.2f -> %.2f)" % [cm.zoom, cm.zoom_t])
	cm.zoom_cmd(1)
	cm.zoom_cmd(1)
	await create_timer(0.7).timeout
	var c0: Vector2 = cm.center
	_btn(root, MOUSE_BUTTON_LEFT, true, gp)
	for k in 6:
		var mm := InputEventMouseMotion.new()
		mm.position = gp + Vector2(15.0 * (k + 1), 5.0 * (k + 1)); mm.global_position = mm.position; mm.relative = Vector2(15, 5); mm.button_mask = 1
		root.get_viewport().push_input(mm)
		await process_frame
	var sel_before: String = cm.selected
	_btn(root, MOUSE_BUTTON_LEFT, false, gp + Vector2(90, 30))
	await process_frame
	if cm.center.distance_to(c0) < 0.01:
		bad += 1; print("FAIL: перетаскивание не сдвигает карту")
	if cm.selected != sel_before:
		bad += 1; print("FAIL: перетаскивание сменило выбор страны")
	# после масштаба щелчок по стране по-прежнему выбирает её
	cm.zoom_cmd(3)
	await create_timer(0.8).timeout
	var v: Array = cm._view()
	var want := "FR" if pick != "FR" else "DE"
	var sp: Vector2 = cm.get_global_rect().position + (cm.labels[want] as Vector2) * float(v[0]) + (v[1] as Vector2)
	_btn(root, MOUSE_BUTTON_LEFT, true, sp)
	_btn(root, MOUSE_BUTTON_LEFT, false, sp)
	await process_frame
	if cm.selected != want:
		bad += 1; print("FAIL: щелчок по стране %s не выбрал её (выбрана %s)" % [want, cm.selected])
	if absf(cm.zoom - cm._fit_zoom(cm.home)) > 0.02 * cm.zoom:
		bad += 1; print("FAIL: ⌂ не вернул обзор Европы (%.2f, нужно %.2f)" % [cm.zoom, cm._fit_zoom(cm.home)])
	# --- настройки новой игры ---
	var tabs = _find_cls(menu, "TabContainer")
	if tabs == null or tabs.get_tab_count() < 3:
		bad += 1; print("FAIL: нет вкладки настроек игры")
	else:
		tabs.current_tab = 2
		var chk = _find_text(menu, "Модель агентов")
		if chk == null:
			bad += 1; print("FAIL: нет переключателя модели агентов в настройках")
		else:
			var was: bool = g.game_opts["agents"]
			chk.button_pressed = not was
			await process_frame
			if g.game_opts["agents"] == was:
				bad += 1; print("FAIL: переключатель агентов не меняет настройку")
			chk.button_pressed = was
		cm.select(pick)
		for i in 6: await process_frame
		root.get_viewport().get_texture().get_image().save_png(outp.replace(".png", "_settings.png"))
	print("меню: проблем %d" % bad)
	quit()
func _btn(r: Window, idx: int, down: bool, pos: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = idx; e.pressed = down; e.position = pos; e.global_position = pos
	r.get_viewport().push_input(e)
func _find_cls(n: Node, cls: String):
	for ch in n.get_children():
		if ch.get_class() == cls:
			return ch
		var r = _find_cls(ch, cls)
		if r != null:
			return r
	return null
func _find_text(n: Node, t: String):
	for ch in n.get_children():
		if ch is CheckBox and String(ch.text).begins_with(t):
			return ch
		var r = _find_text(ch, t)
		if r != null:
			return r
	return null
func _find(n: Node, _cls: String):
	for ch in n.get_children():
		if ch.has_method("select") and ch.has_method("setup"):
			return ch
		var r = _find(ch, _cls)
		if r != null:
			return r
	return null
