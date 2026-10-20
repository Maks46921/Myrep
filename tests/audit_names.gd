extends SceneTree
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	var f := FileAccess.open("/tmp/work056/law_names.txt", FileAccess.WRITE)
	for tp in g.LAW_TOPICS:
		var vn := []
		for v in tp.get("v", []): vn.append(String(v.get("n", "")))
		f.store_line("%s|%s|%s|%s" % [tp["id"], tp.get("cat", -1), tp.get("name", ""), " / ".join(vn)])
	f.close()
	quit()
