extends SceneTree
# Однократная выгрузка больших констант в data/*.dat (формат var_to_str). Запуск: tools/godot.sh --headless --path . --script tools/extdump.gd
# var_to_str сортирует ключи словарей — пишем сами, сохраняя порядок вставки.
func ser(v, ind: String = "") -> String:
	if v is Dictionary:
		if v.is_empty(): return "{}"
		var parts := PackedStringArray()
		for k in v.keys():
			parts.append(ind + "\t" + var_to_str(k) + ": " + ser(v[k], ind + "\t"))
		return "{\n" + ",\n".join(parts) + "\n" + ind + "}"
	if v is Array:
		if v.is_empty(): return "[]"
		var parts := PackedStringArray()
		for e in v:
			parts.append(ind + "\t" + ser(e, ind + "\t"))
		return "[\n" + ",\n".join(parts) + "\n" + ind + "]"
	return var_to_str(v)

func _init():
	var g = load("res://main.gd").new()
	var w := func(path: String, v) -> void:
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(ser(v))
		f.close()
		print(path, " ", FileAccess.get_file_as_string(path).length())
	for c in g.CDATA.keys():
		w.call("res://data/countries/%s.dat" % c, g.CDATA[c])
	w.call("res://data/world.dat", g.WORLD)
	w.call("res://data/world_units.dat", g.WORLD_UNITS)
	print("keys ", g.CDATA.keys())
	quit()
