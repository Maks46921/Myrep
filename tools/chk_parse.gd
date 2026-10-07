# Проверка разбора всех скриптов цепочки: godot --headless --path . --script tools/chk_parse.gd
extends SceneTree
func _init():
	for f in FileAccess.get_file_as_string("res://scripts/CHAIN.txt").split("\n"):
		if f.strip_edges() == "": continue
		var s = load("res://" + f.strip_edges())
		print(f, " -> ", s != null and s.can_instantiate())
	quit()
