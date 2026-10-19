extends SceneTree
# v49: все флаги на одном листе: out=путь.png
const Flags := preload("res://scripts/classes/flags.gd")
func _init():
	var outp := "/tmp/flags.png"
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("out="): outp = String(a).substr(4)
	var codes := ["DE", "FR", "NL", "BE", "LU", "AT", "CH", "CZ", "DK", "ES", "IT", "NO", "PL", "PT", "SE", "GB", "IE", "SI", "SK",
		"HU", "FI", "HR", "RS", "BA", "ME", "MK", "AL", "XK", "BG", "RO", "GR", "EE", "LV", "LT", "MD", "BY", "UA", "RU", "PMR", "DNR", "LNR"]
	var c := Control.new()
	c.size = Vector2(1000, 660)
	root.add_child(c)
	c.draw.connect(func() -> void:
		c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.08, 0.09, 0.12))
		var f := c.get_theme_default_font()
		for i in codes.size():
			var x: float = 20.0 + float(i % 8) * 120.0
			var y: float = 20.0 + float(i / 8) * 105.0
			Flags.draw(c, codes[i], Rect2(x, y, 99.0, 66.0))
			c.draw_string(f, Vector2(x, y + 86.0), codes[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE))
	for i in 8: await process_frame
	root.get_viewport().get_texture().get_image().save_png(outp)
	quit()
