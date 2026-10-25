extends SceneTree
func _init() -> void:
	for l in FileAccess.get_file_as_string("res://scripts/CHAIN.txt").split("\n"):
		l = l.strip_edges()
		if l == "" or l.begins_with("#"): continue
		var p = l if l.begins_with("res://") else "res://" + l
		var s = load(p)
		print("LOAD ", p, " ", s != null and s.can_instantiate())
	quit()
