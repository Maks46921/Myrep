extends SceneTree
# лист символов флагов: tools/flags60/sym.json -> /tmp/symsheet.png
func _init():
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://tools/flags60/sym.json"))
	var cols := 6
	var cell := 150
	var rows := int(ceil(float(data.size()) / cols))
	var sheet := Image.create(cols * cell, rows * cell, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.8, 0.12, 0.15))
	for i in data.size():
		var svg := '<svg xmlns="http://www.w3.org/2000/svg" viewBox="-12 -12 24 24" width="140" height="140">%s</svg>' % String(data[i][1]).replace('"C"', '"#f4f0e0"')
		var img := Image.new()
		var err := img.load_svg_from_string(svg, 1.0)
		if err != OK:
			print("saved-err ", data[i][0], " ", err)
			continue
		sheet.blend_rect(img, Rect2i(0, 0, img.get_width(), img.get_height()), Vector2i((i % cols) * cell + 5, (i / cols) * cell + 5))
	sheet.save_png("/tmp/symsheet.png")
	print("saved sheet")
	quit()
