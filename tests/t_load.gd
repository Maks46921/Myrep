extends SceneTree
# Самый быстрый тест: проект собирается (вся цепочка скриптов разбирается) и игра стартует.
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	print("%s: загрузка ок, регионов %d, партий %d, агентов %d" % [g.ccode, g.regions.size(), g.PARTY_NAMES.size(), g.AG.n if g.AG != null else 0])
	quit()
