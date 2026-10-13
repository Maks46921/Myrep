# Мелкие помощники: перевод, форматирование, цвета, даты.
extends "res://scripts/state/state.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func log_line(s: String) -> void:
	pass


func rt(r: float, dt: float) -> float:
	return 0.0


# --- конец заглушек ---


func tm(k: String) -> String:
	return String(TERMS.get(k, k))


func cap1(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1) if s.length() > 0 else s


func low1(s: String) -> String:
	return s.substr(0, 1).to_lower() + s.substr(1) if s.length() > 0 else s


func build_loc() -> void:
	LOC_RULES.clear()
	if ccode == "DE" or TERMS.is_empty():
		return
	var T: Dictionary = TERMS
	var pairs: Array = [
		["Бундестаге", T["parl_p"]], ["Бундестагу", T["parl_d"]], ["Бундестага", T["parl_g"]], ["в Бундестаг", T["parl_in"]], ["Бундестаг", T["parl"]],
		["канцлером", T["head_i"]], ["канцлера", T["head_g"]], ["канцлеру", T["head_d"]], ["канцлер", T["head"]],
		["АдГ", T["prot_short"]], ["Бундесвер", T["army"]], ["немецк", T["adj"]],
		["земель", T["regs"]], ["землям", T["regs_d"]], ["землях", T["regs_p"]], ["земли", T["regs_n"]],
	]
	if String(UPPER.get("name", "")) != "":
		pairs.insert(0, ["Бундесрат", UPPER["name"]])
	for pr in pairs:
		LOC_RULES.append([String(pr[0]), String(pr[1])])
		var a := String(pr[0])
		if a.begins_with("в "):
			continue
		LOC_RULES.append([cap1(a), cap1(String(pr[1]))])


func loc(s: String) -> String:
	if LOC_RULES.is_empty():
		return s
	for r in LOC_RULES:
		if s.contains(r[0]):
			s = s.replace(r[0], r[1])
	return s


func loc_tree(n: Node) -> void:
	if LOC_RULES.is_empty():
		return
	if n is Label:
		(n as Label).text = loc((n as Label).text)
	elif n is Button:
		(n as Button).text = loc((n as Button).text)
	elif n is RichTextLabel:
		var rt := n as RichTextLabel
		if rt.bbcode_enabled and rt.text != "":
			rt.text = loc(rt.text)
	if n is Control:
		var c := n as Control
		if c.tooltip_text != "":
			c.tooltip_text = loc(c.tooltip_text)
	for ch in n.get_children():
		loc_tree(ch)


func jag_edge(a: Vector2, b: Vector2, depth: int) -> Array:
	# ломаная линия между a и b; одинакова для соседних регионов (общая граница)
	if depth == 0 or a.distance_to(b) < 6.0:
		return [a]
	var lo := a
	var hi := b
	if a.x > b.x or (is_equal_approx(a.x, b.x) and a.y > b.y):
		lo = b
		hi = a
	var d := hi - lo
	var n := Vector2(-d.y, d.x).normalized()
	var k: float = sin((lo.x + hi.x) * 12.9898 + (lo.y + hi.y) * 78.233 + float(depth) * 3.1) * 43758.5453
	k = k - floor(k)
	var m := (lo + hi) * 0.5 + n * (k - 0.5) * d.length() * 0.30
	return jag_edge(a, m, depth - 1) + jag_edge(m, b, depth - 1)


# ============================================================
#  ПОСТРОЕНИЕ ИНТЕРФЕЙСА
# ============================================================


# v50: права партии игрока. Государством (бюджет, разовые меры, министры, дипломатия, влияние, договоры, автопилот)
# распоряжается только правящая коалиция; вносить законопроекты могут только партии, представленные в парламенте.
func pl_gov() -> bool:
	return not opp_mode


func pl_parl() -> bool:
	return not seats.is_empty() and int(seats[0]) > 0


# причина запрета ("" — можно): kind "gov" — действие правительства, "parl" — действие депутатов
func pl_why(kind: String = "gov") -> String:
	if kind == "parl":
		return "" if pl_parl() else "Ваша партия не представлена в парламенте: вносить законопроекты и поправки она не может."
	if opp_mode:
		return "Это решает правительство, а ваша партия в него не входит." if pl_parl() else "Ваша партия не прошла в парламент и не входит в правительство: государством она не распоряжается."
	return ""


# отказ с записью в журнал; true — действие запрещено
func pl_deny(kind: String = "gov") -> bool:
	var why := pl_why(kind)
	if why == "":
		return false
	log_line("[color=%s]%s[/color]" % [COL_WARN, why])
	return true


# v49: название в кавычках «…», если в нём своих кавычек ещё нет (иначе получилось бы ««Слуга народа»»)
func qn(s: String) -> String:
	return s if s.contains("«") else "«%s»" % s


func sg(v: float, digits: int = 1) -> String:
	if absf(v) < 0.5 * pow(10.0, -digits):
		v = 0.0
	var s := String.num(v, digits)
	return ("+" + s) if v > 0.0 else s


func col_delta(v: float, digits: int = 1, invert: bool = false) -> String:
	var good := (v <= 0.0) if invert else (v >= 0.0)
	var c := COL_GOOD if good else COL_BAD
	if absf(v) < 0.5 * pow(10.0, -digits):
		return "[color=%s]–[/color]" % COL_NEUTRAL
	return "[color=%s]%s %s[/color]" % [c, "▲" if v > 0.0 else "▼", String.num(absf(v), digits)]


func find_by_id(arr: Array, id: String) -> Dictionary:
	for d in arr:
		if d["id"] == id:
			return d
	return {}


func policy_title(key: String) -> String:
	if policy_by_key.has(key):
		return policy_by_key[key]["title"]
	return key


func sat(x: float, half: float) -> float:
	return 100.0 * x / (x + half)


func mrate(r: float) -> float:
	# годовая скорость сближения -> месячная
	return 1.0 - pow(1.0 - r, 1.0 / 12.0)


func years_passed() -> float:
	return float(turn) / 12.0


func days_in_month(y: int, m: int) -> int:
	if m == 2:
		return 29 if (y % 4 == 0 and (y % 100 != 0 or y % 400 == 0)) else 28
	return 30 if m in [4, 6, 9, 11] else 31


func date_full() -> String:
	return "%d %s %d" % [day, MONTHS_GEN[month - 1], year]


func date_chip() -> String:
	return "%d %s %d" % [day, String(MONTHS[month - 1]).substr(0, 3).to_lower(), year]


# дней от сегодняшней даты до первого числа месяца, наступающего через n месяцев (месячный шаг происходит именно тогда)
func days_until_months(n: int) -> int:
	if n <= 0:
		return 0
	var d: int = days_in_month(year, month) - day + 1
	var y := year
	var m := month
	for i in n - 1:
		m += 1
		if m > 12:
			m = 1
			y += 1
		d += days_in_month(y, m)
	return d


func days_text(d: int) -> String:
	if d >= 60:
		return months_text(int(round(float(d) / 30.4)))
	return "%d дн." % d


func date_text() -> String:
	return "%s %d" % [MONTHS[month - 1], year]


func turn_date(t: int) -> String:
	var idx: int = year * 12 + (month - 1) + (t - turn)
	return "%s %d" % [MONTHS[idx % 12], idx / 12]


func months_text(n: int) -> String:
	var y := n / 12
	var m := n % 12
	if y > 0 and m > 0:
		return "%d г. %d мес." % [y, m]
	if y > 0:
		return "%d г." % y
	return "%d мес." % m


func date_after(n: int) -> String:
	var t := (month - 1) + n
	return "%s %d" % [MONTHS[t % 12], year + t / 12]


func stat_color(v: float, invert: bool) -> String:
	var good := v / 100.0
	if invert:
		good = 1.0 - good
	return scale_color(good).to_html(false)


func total_pop() -> float:
	var s := 0.0
	for r in regions:
		s += float(r["popm"])
	return s


func pop_ratio() -> float:
	return total_pop() / pop0


func amt(key: String) -> float:
	# сумма статьи в млрд в год
	return gdp * float(pol[key]) / 100.0


func std_index() -> float:
	# стандарты общества растут медленно (2% в год) независимо от ВВП
	return pow(1.02, years_passed())


func fx_col(val: float, good_if_positive: bool) -> String:
	var good: bool = (val >= 0.0) if good_if_positive else (val <= 0.0)
	var c := COL_GOOD if good else COL_BAD
	if absf(val) < 0.005:
		c = COL_NEUTRAL
	return c


func sbox(bg: Color, border: Color = Color(0, 0, 0, 0), bw: int = 0, radius: int = 6, mx: float = 10.0, my: float = 5.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = mx
	s.content_margin_right = mx
	s.content_margin_top = my
	s.content_margin_bottom = my
	return s


func make_dot_tex(px: int, fill: Color, ring: Color, ring_w: float) -> ImageTexture:
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	var c: float = float(px) / 2.0
	var r_out: float = c - 0.5
	for y in px:
		for x in px:
			var d: float = Vector2(float(x) + 0.5 - c, float(y) + 0.5 - c).length()
			var col := Color(0, 0, 0, 0)
			if d <= r_out + 0.5:
				col = ring if d > r_out - ring_w else fill
				col.a *= clampf(r_out - d + 0.5, 0.0, 1.0)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


func scale_color(g: float) -> Color:
	g = clampf(g, 0.0, 1.0)
	if g < 0.38:
		return C_BAD.lerp(C_WARN, g / 0.38)
	return C_WARN.lerp(C_GOOD, clampf((g - 0.38) / 0.37, 0.0, 1.0))


func fmt_n(v: float, digits: int = 0) -> String:
	var s: String = ("%." + str(digits) + "f") % absf(v)
	var parts := s.split(".")
	var ip: String = parts[0]
	var out := ""
	var cnt := 0
	for i in range(ip.length() - 1, -1, -1):
		out = ip[i] + out
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			out = "\u00a0" + out
	if parts.size() > 1:
		out += "." + parts[1]
	return ("-" if v < 0.0 else "") + out


func months_short(n: int) -> String:
	var y := n / 12
	var m := n % 12
	if y > 0 and m > 0:
		return "%dг %dм" % [y, m]
	if y > 0:
		return "%dг" % y
	return "%dм" % m


func arrow_text(v: float, digits: int = 1) -> String:
	if absf(v) < 0.5 * pow(10.0, -digits):
		return ""
	return ("▲ " if v > 0.0 else "▼ ") + String.num(absf(v), digits)


func delta_col(v: float, up_good: bool) -> Color:
	if absf(v) < 0.001:
		return C_DIM
	return C_GOOD if ((v > 0.0) == up_good) else C_BAD


func col_signed(v: float, digits: int = 1) -> String:
	var c := COL_GOOD if v >= 0.0 else COL_BAD
	if absf(v) < 0.5 * pow(10.0, -digits):
		c = COL_NEUTRAL
	return "[color=%s]%s[/color]" % [c, sg(v, digits)]


func bit_text(items: Array, limit: int = 3) -> String:
	var bits: PackedStringArray = []
	for i in mini(limit, items.size()):
		var it: Array = items[i]
		bits.append(("▲ " if int(it[1]) > 0 else ("▼ " if int(it[1]) < 0 else "◆ ")) + String(it[0]))
	return " · ".join(bits)


func good_col(good: bool) -> String:
	return COL_GOOD if good else COL_BAD


func hint_line(good: bool, text: String) -> String:
	return "[color=%s]%s[/color] %s" % [COL_GOOD if good else COL_WARN, "●", text]


func fmt_sg(v: float, digits: int = 1) -> String:
	return sg(v, digits)


func date_short() -> String:
	return "%s %d" % [String(MONTHS[month - 1]).substr(0, 3), year]


func polygon_area(pts: PackedVector2Array) -> float:
	var a := 0.0
	for i in pts.size():
		var p: Vector2 = pts[i]
		var q: Vector2 = pts[(i + 1) % pts.size()]
		a += p.x * q.y - q.x * p.y
	return a * 0.5
