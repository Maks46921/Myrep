extends SceneTree
# Выгружает данные и флаги стран для сайта. Запуск из корня репозитория:
#   godot --headless --path . --script website/tools/export_countries.gd -- out=/tmp/sym
# затем: python3 website/tools/build_countries.py /tmp/sym
const Flags := preload("res://scripts/classes/flags.gd")
func col(c: Color) -> String: return "#" + c.to_html(false)
func _init():
	var od := "/tmp/sym"
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="): od = String(a).substr(4)
	DirAccess.make_dir_recursive_absolute(od + "/flags")
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	var out := {}
	for cc in g.COUNTRY_CODES:
		var d = str_to_var(FileAccess.get_file_as_string("res://data/countries/%s.dat" % cc))
		var w: Dictionary = g.WORLD[cc]
		var e: Dictionary = g.ELEC_DATA.get(cc, {})
		var pcs := []
		for c in g.WORLD_PCOL.get(cc, []): pcs.append(col(c))
		var orgs := []
		for k in g.ORG_ORDER:
			if cc in (g.ORGS[k]["mem"] as Array): orgs.append(String(g.ORGS[k]["sh"]))
		var traits := []
		for t in g.COUNTRY_TRAITS.get(cc, []): traits.append({"n": g.HIST_TRAITS[t]["n"], "d": g.HIST_TRAITS[t]["d"]})
		var rel := []
		for r in g.HIST_REL.get(cc, []): rel.append(r)
		var up: Dictionary = d.get("UPPER", {})
		out[cc] = {
			"name": w["name"], "cap": w["cap"], "pop": w["pop"], "gdp": w["gdp"], "growth": w["growth"], "infl": w["infl"], "unemp": w["unemp"],
			"appr": w["appr"], "gov": w["gov"], "gov_party": w["gov_party"], "desc": w["desc"], "leader": w["leader"],
			"pn": w["pn"], "seats": w["seats"], "regions": (w["regions"] as Array).size(), "pcol": pcs,
			"info": d.get("INFO", {}), "parl": d.get("TERMS", {}).get("parl", ""), "head_word": d.get("TERMS", {}).get("head", ""),
			"upper": up.get("name", ""), "upper_total": up.get("total", 0),
			"sys": e.get("sys", ""), "head": e.get("head", ""), "head_title": e.get("title_n", ""), "turn": e.get("turn", 0),
			"term": d.get("MACRO", {}).get("parl_term", 0), "eu": w.get("eu", false), "euro": w.get("euro", false),
			"orgs": orgs, "traits": traits, "rel": rel
		}
		var img := Image.create(330, 220, false, Image.FORMAT_RGBA8)
		for y in 220:
			for x in 330:
				img.set_pixel(x, y, Flags.px(cc, (x + 0.5) / 330.0, (y + 0.5) / 220.0))
		img.save_png(od + "/flags/%s.png" % cc)
	var f := FileAccess.open(od + "/countries.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "\t"))
	f.close()
	print("DUMP OK ", out.size())
	quit()
