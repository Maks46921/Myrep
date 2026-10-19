extends SceneTree
# 0.55.4: выгрузка законов, числовых параметров и партий страны в JSON — для сверки с реальностью.
#   tools/godot.sh --headless --path . --script tests/dev/dump_country.gd -- country=FR out=/путь/FR.json
func _init():
	var out := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("out="):
			out = a.substr(4)
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	var laws: Array = []
	var params: Array = []
	for t in g.LAW_TOPICS:
		if t.has("param"):
			var pr: Dictionary = t["param"]
			params.append({"id": t["id"], "name": t["name"], "ref": pr["ref"], "fmt": String(pr["fmt"]), "lo": pr["lo"], "hi": pr["hi"], "desc": String(t.get("desc", ""))})
			continue
		var vs: Array = []
		for v in t["v"]:
			vs.append({"n": String(v.get("n", "")), "d": String(v.get("d", ""))})
		laws.append({"id": t["id"], "name": t["name"], "desc": String(t.get("desc", "")), "cur": int(g.law_state.get(t["id"], 0)), "v": vs})
	var parties: Array = []
	for i in g.PARTY_NAMES.size():
		parties.append({"i": i, "name": g.PARTY_NAMES[i], "leader": String(g.PARTY_LEADERS[i]) if i < g.PARTY_LEADERS.size() else ""})
	var d := {"cc": g.ccode, "laws": laws, "params": params, "parties": parties}
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify(d, "\t"))
	f.close()
	print("ok ", g.ccode, " laws ", laws.size(), " params ", params.size())
	quit()
