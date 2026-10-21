extends SceneTree
# 0.60: проверка, что импортированные флаги (с полем lic) рисуются, и лист-превью /tmp/flagcheck.png
func _init():
	var txt := FileAccess.get_file_as_string("res://data/flags.dat")
	var d: Dictionary = str_to_var(txt)
	var list: Array = []
	var bad := 0
	for cc in d:
		for e in d[cc]:
			if e.has("lic"):
				list.append(e)
	var cols := 6
	var cw := 180
	var ch := 130
	var rows := int(ceil(float(list.size()) / cols))
	var sheet := Image.create(cols * cw, maxi(rows, 1) * ch, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.15, 0.17, 0.2))
	var t0 := Time.get_ticks_msec()
	for i in list.size():
		var e: Dictionary = list[i]
		var img := Image.new()
		var ok: bool = img.load_svg_from_string(String(e["svg"]), 2.0) == OK and img.get_width() > 2
		if not ok:
			bad += 1
			print("НЕ РИСУЕТСЯ: ", e["id"])
			continue
		var s: float = minf(float(cw - 10) / img.get_width(), float(ch - 10) / img.get_height())
		img.resize(int(img.get_width() * s), int(img.get_height() * s))
		sheet.blit_rect(img, Rect2i(0, 0, img.get_width(), img.get_height()), Vector2i((i % cols) * cw + 5, (i / cols) * ch + 5))
	sheet.save_png("/tmp/flagcheck.png")
	print("flagcheck: ", list.size(), " импортированных, не рисуются ", bad, ", мс ", Time.get_ticks_msec() - t0)
	quit(1 if bad > 0 else 0)
