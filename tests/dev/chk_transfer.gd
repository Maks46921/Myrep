extends SceneTree
# 0.55.5: «Трансферты регионам» в бюджете — общий ползунок меняет все регионы пропорционально
func _init():
	var g = load("res://main.gd").new()
	root.add_child(g)
	for i in 3: await process_frame
	var b0: float = g.budget_calc()["spend"]["Трансферты регионам"] if g.has_method("budget_calc") else -1.0
	print("avg=", g.transfer_avg(), " slider=", g.bud_tr_slider.value, " label=", g.bud_tr_label.text, " r0=", g.regions[0]["transfer"], " r2=", g.regions[2]["transfer"])
	g.bud_tr_slider.value = g.transfer_avg() * 2.0
	print("avg=", g.transfer_avg(), " label=", g.bud_tr_label.text, " r0=", g.regions[0]["transfer"], " r2=", g.regions[2]["transfer"])
	g.bud_tr_slider.value = 0.0
	print("zero avg=", g.transfer_avg())
	g.bud_tr_slider.value = 1.0
	print("from zero avg=", g.transfer_avg(), " r0=", g.regions[0]["transfer"])
	quit()
