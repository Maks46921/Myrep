extends SceneTree
# v50: снимки бюджета — план (черновик) и переговоры совета коалиции
func _init():
	var outd := "/tmp"
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="): outd = String(a).substr(4)
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 6: await process_frame
	g.show_desk(0)
	for i in 6: await process_frame
	var s1: HSlider = g.sliders["pensions"]["slider"]
	g.on_slider(s1.value + 1.5, "pensions")
	var s2: HSlider = g.sliders["corp"]["slider"]
	g.on_slider(s2.value - 1.0, "corp")
	var s3: HSlider = g.sliders["vat"]["slider"]
	g.on_slider(s3.value + 1.0, "vat")
	g.refresh()
	for i in 8: await process_frame
	await create_timer(0.5).timeout
	await snap(outd + "/v50_budget_plan.png")
	print("pending ", g.bud_pending(), " council ", g.bud_needs_council())
	g.on_bud_accept()
	for i in 8: await process_frame
	await create_timer(0.4).timeout
	await snap(outd + "/v50_budget_neg.png")
	var p0: float = float(g.pol["pensions"])
	g.next_turn()
	print("after month pending ", g.bud_pending(), " pens ", p0, " -> ", g.pol["pensions"])
	quit()

func snap(p: String) -> void:
	await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png(p)
	print("saved ", p)
