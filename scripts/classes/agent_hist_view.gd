extends Control

var h := PackedInt32Array()
var mark := 38.0

func _init() -> void:
	custom_minimum_size = Vector2(200.0, 130.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.07, 0.08, 0.12))
	if h.is_empty():
		return
	var mx := 1
	for v in h:
		mx = maxi(mx, v)
	var bw: float = size.x / float(h.size())
	for i in h.size():
		var bh: float = (size.y - 18.0) * float(h[i]) / float(mx)
		var col := Color(0.85, 0.35, 0.30) if (float(i) + 0.5) * 100.0 / float(h.size()) < mark else Color(0.36, 0.55, 0.94)
		draw_rect(Rect2(i * bw + 1.0, size.y - 16.0 - bh, bw - 2.0, bh), col)
	var f := ThemeDB.fallback_font
	for t in [0, 25, 50, 75, 100]:
		draw_string(f, Vector2(float(t) / 100.0 * (size.x - 22.0) + 2.0, size.y - 3.0), str(t), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color(1, 1, 1, 0.6))
