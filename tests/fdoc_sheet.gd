extends SceneTree
# Лист всех фигур редактора флагов: godot --headless не рисует, запускать через xvfb. Результат /tmp/fdoc_sheet.png
const FD := preload("res://scripts/classes/flag_doc.gd")
func _init():
	var G = load("res://scripts/data/data_flags60.gd")
	var syms: Array = G.FLAG_SYM60
	var sheet := Image.create(6 * 190, 5 * 130, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.2, 0.2, 0.25))
	var i := 0
	var cols := ["#cc1a1f", "#f7f7f7", "#0d3a94", "#ffc400"]
	for ty in FD.TYPES:
		var d := FD.new_doc("#2a6b3a")
		var L := FD.new_layer(String(ty[0]), 45, 30, 60, 40, cols[i % 4])
		if String(ty[0]) == "poly":
			L = FD.new_poly([Vector2(20, 10), Vector2(70, 15), Vector2(55, 50), Vector2(25, 40)], cols[i % 4])
		if String(ty[0]) == "sym":
			L["n"] = 7
		L["stroke"] = "#111111"
		L["sw"] = 1.2
		L["r"] = 3.0
		L["rot"] = 15.0 if i % 3 == 0 else 0.0
		d["layers"].append(L)
		var svg := FD.build_svg(d, syms)
		var img := Image.new()
		if img.load_svg_from_string(svg, 2.0) != OK:
			print("FAIL ", ty[0])
			i += 1
			continue
		sheet.blit_rect(img, Rect2i(0, 0, img.get_width(), img.get_height()), Vector2i((i % 6) * 190 + 5, (i / 6) * 130 + 5))
		i += 1
	sheet.save_png("/tmp/fdoc_sheet.png")
	print("saved")
	quit()
