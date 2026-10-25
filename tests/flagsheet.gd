extends SceneTree
# лист-превью флагов по id: godot ... --script tests/flagsheet.gd -- ID,ID,...  -> /tmp/flagsheet.png
func _init():
	var ids: PackedStringArray = []
	for a in OS.get_cmdline_user_args():
		ids = String(a).split(",")
	var d: Dictionary = str_to_var(FileAccess.get_file_as_string("res://data/flags.dat"))
	var list: Array = []
	for cc in d:
		for e in d[cc]:
			if ids.has(String(e["id"])):
				list.append(e)
	var cols := 6
	var cw := 180
	var ch := 130
	var rows := int(ceil(float(list.size()) / cols))
	var sheet := Image.create(cols * cw, maxi(rows, 1) * ch, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.15, 0.17, 0.2))
	for i in list.size():
		var img := Image.new()
		if img.load_svg_from_string(String((list[i] as Dictionary)["svg"]), 2.0) != OK or img.get_width() < 2:
			print("НЕ РИСУЕТСЯ: ", (list[i] as Dictionary)["id"])
			continue
		var s: float = minf(float(cw - 10) / img.get_width(), float(ch - 10) / img.get_height())
		img.resize(int(img.get_width() * s), int(img.get_height() * s))
		sheet.blit_rect(img, Rect2i(0, 0, img.get_width(), img.get_height()), Vector2i((i % cols) * cw + 5, (i / cols) * ch + 5))
	sheet.save_png("/tmp/flagsheet.png")
	print("flagsheet: ", list.size())
	quit()
