# Проверка разбора всех скриптов цепочки: godot --headless --path . --script tools/chk_parse.gd [-- en]
# (v54_1: «-- en» — английское дерево en/, его собирает tools/i18n.py build)
extends SceneTree
func _init():
	var pre := "res://en/" if OS.get_cmdline_user_args().has("en") else "res://"
	for f in FileAccess.get_file_as_string(pre + "scripts/CHAIN.txt").split("\n"):
		if f.strip_edges() == "": continue
		var s = load(pre + f.strip_edges())
		print(f, " -> ", s != null and s.can_instantiate())
	quit()
