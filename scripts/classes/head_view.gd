extends Control

var rounds: Array = []        # {title, need, need_text, rows: [{name, sub, col, val, win, out, note, lab}]}
var progress := 0.0
const ROW_H := 40.0
const HEAD_H := 28.0

func _init() -> void:
	custom_minimum_size = Vector2(320.0, 160.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_data(r: Array) -> void:
	rounds = r
	var h := 6.0
	for rd in rounds:
		h += HEAD_H + float((rd["rows"] as Array).size()) * ROW_H + 8.0
	custom_minimum_size.y = h
	queue_redraw()

func set_progress(v: float) -> void:
	progress = v
	queue_redraw()

func _draw() -> void:
	var f: Font = get_theme_default_font()
	var W: float = size.x
	var n: int = rounds.size()
	var y := 4.0
	var gold := Color(1.0, 0.82, 0.40)
	for ri in n:
		var rd: Dictionary = rounds[ri]
		var er: float = clampf(progress * float(n) - float(ri), 0.0, 1.0)
		var e: float = 1.0 - pow(1.0 - er, 3.0)
		var ha: float = 1.0 if er > 0.0 else 0.3
		draw_string(f, Vector2(6.0, y + 20.0), String(rd["title"]), HORIZONTAL_ALIGNMENT_LEFT, W * 0.55, 15, Color(0.78, 0.84, 1.0, ha))
		var ntxt: String = String(rd.get("need_text", ""))
		if ntxt != "":
			draw_string(f, Vector2(W * 0.45, y + 20.0), ntxt, HORIZONTAL_ALIGNMENT_RIGHT, W * 0.55 - 6.0, 12, Color(0.6, 0.63, 0.72, ha))
		draw_line(Vector2(0.0, y + HEAD_H - 3.0), Vector2(W, y + HEAD_H - 3.0), Color(1, 1, 1, 0.12), 1.0)
		y += HEAD_H
		var rows: Array = rd["rows"]
		var need: float = float(rd.get("need", 0.0))
		var mx := 0.3
		for r in rows:
			mx = maxf(mx, float(r["val"]))
		mx = maxf(mx, need * 1.04)
		var name_w: float = clampf(W * 0.40, 150.0, 300.0)
		var bx: float = name_w + 10.0
		var lab_w := 118.0
		var bw: float = maxf(40.0, W - bx - lab_w - 6.0)
		var sc: float = bw / (mx * 1.1)
		for i in rows.size():
			var r: Dictionary = rows[i]
			var col: Color = r["col"]
			var win: bool = bool(r.get("win", false))
			var out: bool = bool(r.get("out", false))
			var dim := 0.45 if out else 1.0
			dim *= ha
			var ry: float = y + float(i) * ROW_H
			if i % 2 == 0:
				draw_rect(Rect2(0.0, ry, W, ROW_H), Color(1, 1, 1, 0.03))
			if win and er >= 1.0:
				draw_rect(Rect2(0.0, ry, W, ROW_H), Color(gold.r, gold.g, gold.b, 0.11))
				draw_rect(Rect2(0.0, ry, 3.0, ROW_H), gold)
			var cen := Vector2(26.0, ry + ROW_H * 0.5)
			draw_circle(cen, 15.0, Color(col.r, col.g, col.b, dim))
			if win and er >= 1.0:
				draw_arc(cen, 17.0, 0.0, TAU, 28, gold, 2.2)
			var ch: String = String(r["name"]).substr(0, 1)
			var icol := Color(0.07, 0.08, 0.12, dim) if col.get_luminance() > 0.5 else Color(1, 1, 1, dim)
			draw_string(f, Vector2(cen.x - 8.0, cen.y + 6.0), ch, HORIZONTAL_ALIGNMENT_CENTER, 16.0, 17, icol)
			var tcol := Color(0.93, 0.95, 1.0, dim) if not bool(r.get("you", false)) else Color(1.0, 0.85, 0.45, dim)
			draw_string(f, Vector2(48.0, ry + 18.0), String(r["name"]), HORIZONTAL_ALIGNMENT_LEFT, name_w - 50.0, 15, tcol)
			draw_string(f, Vector2(48.0, ry + 33.0), String(r["sub"]), HORIZONTAL_ALIGNMENT_LEFT, name_w - 50.0, 12, Color(0.6, 0.63, 0.72, dim))
			draw_rect(Rect2(bx, ry + 12.0, bw, 16.0), Color(0.055, 0.067, 0.098, ha))
			var fw: float = float(r["val"]) * sc * e
			if fw > 0.5:
				draw_rect(Rect2(bx, ry + 12.0, fw, 16.0), Color(col.r, col.g, col.b, dim))
			if need > 0.0:
				var nx: float = bx + need * sc
				draw_line(Vector2(nx, ry + 8.0), Vector2(nx, ry + ROW_H - 8.0), Color(1, 1, 1, 0.5 * ha), 1.5)
			var lab: String = ("%.1f%%" % (float(r["val"]) * 100.0 * e)) if not r.has("lab") else (String(r["lab"]) if e >= 0.99 else "")
			draw_string(f, Vector2(bx + bw + 8.0, ry + 23.0), lab, HORIZONTAL_ALIGNMENT_LEFT, lab_w - 8.0, 15, Color(0.93, 0.95, 1.0, dim))
			var nt: String = String(r.get("note", ""))
			if win and er >= 1.0:
				nt = "ИЗБРАН"
			if nt != "" and er >= 1.0:
				draw_string(f, Vector2(bx + bw + 8.0, ry + 36.0), nt, HORIZONTAL_ALIGNMENT_LEFT, lab_w - 8.0, 11, gold if win else Color(0.6, 0.63, 0.72, dim))
		y += float(rows.size()) * ROW_H + 8.0
