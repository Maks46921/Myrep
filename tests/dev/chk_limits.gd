extends SceneTree
# 0.55.5: налоги и расходы без пределов — ставка 0 и далеко за обычным диапазоном
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	g.set_policy("income", 45.0)
	g.set_policy("admin", 0.0)
	g.set_policy("army", 30.0)
	g.set_policy("pensions", -5.0)
	print("income=", g.pol["income"], " admin=", g.pol["admin"], " army=", g.pol["army"], " pensions=", g.pol["pensions"])
	print("slider army max=", g.sliders["army"]["slider"].max_value, " value=", g.sliders["army"]["slider"].value)
	g.toggle_slider_mode("army")
	g.configure_slider("army")
	print("abs army=", g.pol_abs["army"] if g.pol_abs.has("army") else -1, " slider max=", g.sliders["army"]["slider"].max_value)
	for m in 3:
		if not g.current_event.is_empty(): g.choose(0)
		g.next_turn()
	print("after 3 months income=", g.pol["income"], " army=", g.pol["army"])
	quit()
