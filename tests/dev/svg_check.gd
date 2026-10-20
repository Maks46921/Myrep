extends SceneTree
func _init():
	var d = str_to_var(FileAccess.get_file_as_string("res://data/flags.dat"))
	var bad := 0
	var n := 0
	var cols := 20
	var sheet := Image.create(cols * 100, 800, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.5, 0.5, 0.5))
	for cc in d:
		for e in d[cc]:
			var img := Image.new()
			var t0 := Time.get_ticks_usec()
			var err := img.load_svg_from_string(String(e["svg"]), 2.0)
			n += 1
			if err != OK or img.get_width() < 4:
				bad += 1
				print("BAD ", e["id"], " err ", err)
				continue
			if n < 5:
				print(e["id"], " size ", img.get_size(), " ", (Time.get_ticks_usec() - t0) / 1000.0, " мс")
			if n <= 160:
				img.resize(90, 60)
				sheet.blit_rect(img, Rect2i(0, 0, 90, 60), Vector2i(((n - 1) % cols) * 100, ((n - 1) / cols) * 70))
	print("svg: всего ", n, " ошибок ", bad)
	sheet.save_png("/tmp/work056/flags/svgsheet.png")
	quit()
