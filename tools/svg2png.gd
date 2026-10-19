# v39: icon.svg -> PNG 256×256 (для иконки exe): godot --headless --script tools/svg2png.gd -- out.png
extends SceneTree


func _init():
	var out := "/tmp/symphony_icon256.png"
	for a in OS.get_cmdline_user_args():
		out = String(a)
	var img := Image.new()
	img.load_svg_from_string(FileAccess.get_file_as_string("res://icon.svg"), 1.0)
	img.save_png(out)
	quit()
