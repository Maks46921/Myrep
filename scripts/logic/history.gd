# v52_1: исторические предпосылки. Черты национального характера (HIST_TRAITS, COUNTRY_TRAITS) дают постоянные
# модификаторы; историческая память (HIST_REL) усиливает добрые дела с давними друзьями и обиды с давними
# соперниками, сдвигает долгосрочный уровень отношений и шанс договоров.
extends "res://scripts/logic/econsys.gd"

func hist_traits(cc: String = "") -> Array:
	return COUNTRY_TRAITS.get(ccode if cc == "" else cc, [])


func hist_dyn() -> void:
	if mods.is_empty():
		return
	for t in hist_traits():
		var d: Dictionary = HIST_TRAITS.get(String(t), {})
		var ad: Dictionary = d.get("a", {})
		for k in ad:
			mods[k] = float(mods.get(k, 0.0)) + float(ad[k])
		var xs: Dictionary = d.get("x", {})
		for k in xs:
			mods[k] = float(mods.get(k, 1.0)) * float(xs[k])


# историческая память нашей страны о стране c: −3..+3 (0 — нет особой истории)
func hist_rel(c: String) -> int:
	for r in HIST_REL.get(ccode, []):
		if String(r[0]) == c:
			return int(r[1])
	# память взаимна: если у партнёра записана история с нами
	for r2 in HIST_REL.get(c, []):
		if String(r2[0]) == ccode:
			return int(r2[1])
	return 0


func hist_why(c: String) -> String:
	for r in HIST_REL.get(ccode, []):
		if String(r[0]) == c:
			return String(r[2])
	for r2 in HIST_REL.get(c, []):
		if String(r2[0]) == ccode:
			return String(r2[2])
	return ""


func hist_name(v: int) -> String:
	return ["вековая вражда", "давняя неприязнь", "настороженность", "без особой истории", "добрые связи", "историческая дружба", "братские народы"][clampi(v + 3, 0, 6)]


# множитель изменения отношений: добро от друга весит больше, обида от соперника — тоже
func hist_mult(c: String, delta: float) -> float:
	var h := hist_rel(c)
	if h > 0 and delta > 0.0:
		return 1.0 + 0.12 * float(h)
	if h < 0 and delta < 0.0:
		return 1.0 + 0.12 * float(-h)
	if h > 0 and delta < 0.0:
		return maxf(0.6, 1.0 - 0.08 * float(h))
	if h < 0 and delta > 0.0:
		return maxf(0.6, 1.0 - 0.08 * float(-h))
	return 1.0


func hist_text_rel(c: String) -> String:
	var h := hist_rel(c)
	if h == 0:
		return ""
	var col := COL_GOOD if h > 0 else COL_BAD
	return "Историческая память: [color=%s]%s[/color] (%s)." % [col, hist_name(h), hist_why(c)]
