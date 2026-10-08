extends SceneTree
func _init() -> void:
	var t := Time.get_ticks_msec()
	var d = str_to_var(FileAccess.get_file_as_string("res://data/ate.dat"))
	print("load ms ", Time.get_ticks_msec() - t, " n ", (d["uid"] as PackedStringArray).size(), " tv ", (d["tv"] as PackedFloat32Array).size())
	quit()
