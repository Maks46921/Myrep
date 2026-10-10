# Сохранения, автосохранения и откат на год назад (v44_1).
# Снимок — все переменные скрипта игры, которые не содержат объектов (окна, генераторы случайных чисел и т.п. пропускаются),
# записанные через var_to_bytes. Агенты населения и интерфейс после загрузки собираются заново.
extends "res://scripts/logic/log.gd"

const SV_DIR := "user://saves"
const SV_SKIP := ["sv_hist", "ag_cache", "current_event", "event_region"]
const SV_KEEP := 4

var sv_hist: Array = []   # автоснимки: [{"turn": int, "date": String, "bytes": PackedByteArray}]


func sv_clean(v: Variant, depth: int = 0) -> bool:
	if depth > 12:
		return false
	match typeof(v):
		TYPE_OBJECT, TYPE_CALLABLE, TYPE_SIGNAL, TYPE_RID:
			return false
		TYPE_ARRAY:
			for x in v:
				if not sv_clean(x, depth + 1):
					return false
		TYPE_DICTIONARY:
			for k in v:
				if not sv_clean(k, depth + 1) or not sv_clean(v[k], depth + 1):
					return false
	return true


func sv_collect() -> Dictionary:
	var out := {}
	for p in get_property_list():
		if (int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
			continue
		var nm: String = String(p["name"])
		if nm in SV_SKIP or nm.begins_with("sv_"):
			continue
		var v: Variant = get(nm)
		if v == null:
			continue
		if sv_clean(v):
			out[nm] = v
	return out


func sv_pack() -> PackedByteArray:
	var d := {"v": 44, "ccode": ccode, "vars": sv_collect(), "opts": game_opts.duplicate(true)}
	return var_to_bytes(d)


func sv_apply(bytes: PackedByteArray) -> bool:
	var d: Variant = bytes_to_var(bytes)
	if typeof(d) != TYPE_DICTIONARY or not (d as Dictionary).has("vars"):
		return false
	if String(d.get("ccode", "")) != ccode:
		return false
	var vars: Dictionary = d["vars"]
	for nm in vars:
		var cur: Variant = get(String(nm))
		var nv: Variant = vars[nm]
		match typeof(cur):
			TYPE_ARRAY:
				if typeof(nv) == TYPE_ARRAY:
					if (cur as Array).is_read_only():
						set(String(nm), nv)
					else:
						(cur as Array).assign(nv)
			TYPE_DICTIONARY:
				if typeof(nv) == TYPE_DICTIONARY:
					if (cur as Dictionary).is_read_only():
						set(String(nm), nv)
					else:
						(cur as Dictionary).clear()
						(cur as Dictionary).merge(nv, true)
			_:
				if typeof(cur) == typeof(nv) or typeof(cur) == TYPE_NIL:
					set(String(nm), nv)
				elif typeof(cur) == TYPE_FLOAT and typeof(nv) == TYPE_INT:
					set(String(nm), float(nv))
	current_event = {}
	event_region = -1
	election_open = false
	game_over = false if not bool(vars.get("game_over", false)) else true
	ag_cache = {}
	ag_ver += 1
	if ag_on:
		ag_build()
	recompute_mods()
	return true


func sv_path(slot: int) -> String:
	return "%s/%s_%d.sav" % [SV_DIR, ccode, slot]


func sv_save(slot: int) -> bool:
	DirAccess.make_dir_recursive_absolute(SV_DIR)
	var f := FileAccess.open(sv_path(slot), FileAccess.WRITE)
	if f == null:
		return false
	f.store_var({"date": date_text(), "turn": turn, "gdp": gdp, "bytes": sv_pack()})
	f.close()
	return true


func sv_info(slot: int) -> String:
	if not FileAccess.file_exists(sv_path(slot)):
		return ""
	var f := FileAccess.open(sv_path(slot), FileAccess.READ)
	if f == null:
		return ""
	var d: Variant = f.get_var()
	f.close()
	if typeof(d) != TYPE_DICTIONARY:
		return ""
	return "%s · месяц %d · ВВП %.0f" % [String(d.get("date", "")), int(d.get("turn", 0)), float(d.get("gdp", 0.0))]


func sv_load(slot: int) -> bool:
	if not FileAccess.file_exists(sv_path(slot)):
		return false
	var f := FileAccess.open(sv_path(slot), FileAccess.READ)
	if f == null:
		return false
	var d: Variant = f.get_var()
	f.close()
	if typeof(d) != TYPE_DICTIONARY:
		return false
	var ok: bool = sv_apply(d["bytes"])
	if ok:
		refresh()
	return ok


func sv_auto() -> void:
	# автоснимок раз в год (в январе); хранится несколько последних
	if game_over or month != 1:
		return
	if sv_hist.size() > 0 and int(sv_hist[sv_hist.size() - 1]["turn"]) == turn:
		return
	sv_hist.append({"turn": turn, "date": date_text(), "bytes": sv_pack()})
	while sv_hist.size() > SV_KEEP:
		sv_hist.pop_front()


func sv_rollback() -> bool:
	# откат на последний автоснимок, сделанный раньше текущего месяца
	for i in range(sv_hist.size() - 1, -1, -1):
		if int(sv_hist[i]["turn"]) < turn:
			var ok: bool = sv_apply(sv_hist[i]["bytes"])
			if ok:
				while sv_hist.size() > i + 1:
					sv_hist.pop_back()
				log_tag("СОХРАНЕНИЕ", COL_WARN, "Откат на %s." % String(sv_hist[i]["date"]))
				refresh()
			return ok
	return false
