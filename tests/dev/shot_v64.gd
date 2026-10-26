extends SceneTree
# 0.64: скриншоты новых окон. Аргументы: country=XX desk=N win=id out=путь
func _init():
	var cc := "UA"
	var desk := 2
	var outp := "/tmp/shot_v64.png"
	for a in OS.get_cmdline_user_args():
		var s := String(a)
		if s.begins_with("country="): cc = s.substr(8)
		if s.begins_with("desk="): desk = int(s.substr(5))
		if s.begins_with("out="): outp = s.substr(4)
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 6: await process_frame
	if cc != g.ccode:
		g.choose_country(cc)
		for i in 6: await process_frame
	g.show_desk(desk)
	for a in OS.get_cmdline_user_args():
		var s := String(a)
		if s == "list=1":
			print("WINS ", g.wins.keys())
		if s.begins_with("win="):
			var w = g.wins[s.substr(4)]
			w.closed = false
			w.visible = true
			if w.has_method("raise") or true:
				w.move_to_front()
	g.refresh()
	if OS.get_cmdline_user_args().has("picker=1"):
		var host := PanelContainer.new()
		g.add_child(host)
		host.position = Vector2(180, 150)
		host.custom_minimum_size = Vector2(1000, 420)
		host.size = Vector2(1000, 420)
		var vb := VBoxContainer.new()
		host.add_child(vb)
		var t := Label.new()
		t.text = "Выберите партию для переговоров"
		vb.add_child(t)
		var ph: Dictionary = g.party_pick_make(vb, func(_q: int) -> void: pass)
		var pitems: Array = []
		for p in range(1, mini(7, g.PARTY_NAMES.size())):
			pitems.append({"p": p, "why": "уже в коалиции" if p == 3 else ""})
		g.party_pick_set(ph, pitems, 1)
	for i in 20: await process_frame
	await create_timer(0.8).timeout
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png(outp)
	print("OK shot ", outp, " ", img.get_size())
	quit()
