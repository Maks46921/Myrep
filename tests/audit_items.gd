extends SceneTree
# 0.57.1: что игрок видит в последствиях закона (variant_effect_items) для выбранных законов
func _init():
	var tids := ["elect_threshold"]
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("laws="): tids = String(a).substr(5).split(",")
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 5: await process_frame
	for tid in tids:
		var tp: Dictionary = g.law_index[tid]
		for i in (tp["v"] as Array).size():
			var its: Array = g.variant_effect_items(tid, i)
			var s := []
			for it in its: s.append("%s[%d]" % [it[0], it[1]])
			print("ITEMS %s %d %s: %s" % [tid, i, tp["v"][i]["n"], " | ".join(s)])
	quit()
