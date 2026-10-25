# 0.60: варианты режимов. У каждого класса недемократического режима (однопартийное, хунта, монархия, гибридный,
# теократия, технократия, олигархия, коллективное руководство, переходное правительство) есть варианты: свои
# добавки к показателям, цены рычагов, события, название правящей силы и метки флага.
# Вариант подбирается при смене режима по идеологии правящей партии и по тому, как режим возник.
# Данные: scripts/data/data_regimes60.gd (создаётся tools/reg60/emit.py).
extends "res://scripts/logic/regime2.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func flag_month_force() -> void:
	pass


# --- конец заглушек ---


func reg60_vars(cls: String) -> Array:
	var out: Array = []
	for v in REG_VARS60:
		if String(v["cls"]) == cls:
			out.append(v)
	return out


func reg60_def(id: String) -> Dictionary:
	for v in REG_VARS60:
		if String(v["id"]) == id:
			return v
	return {}


# вариант, действующий сейчас ({} — демократия или вариант не выбран)
func reg60_var() -> Dictionary:
	if au.is_empty():
		return {}
	var id := String(au.get("var", ""))
	if id == "":
		return {}
	return reg60_def(id)


func reg60_title() -> String:
	var v := reg60_var()
	if v.is_empty():
		return au_class_name()
	return String(v["n"])


# выбор варианта: идеология правящей партии, причина смены режима, страна и немного случайности
func reg60_pick(cls: String) -> String:
	var list := reg60_vars(cls)
	if list.is_empty():
		return ""
	var arch := party_arch(0)
	var best := ""
	var bs := -1.0
	for v in list:
		var s := 0.0
		var ideo: Array = v["ideo"]
		var ix := ideo.find(arch)
		if ix >= 0:
			s += 2.0 + float(ideo.size() - ix) * 0.15
		if reg_cause in (v["cause"] as Array):
			s += 1.5
		if v.has("cc") and ccode in (v["cc"] as Array):
			s += 4.0
		s += randf() * 0.6
		if s > bs:
			bs = s
			best = String(v["id"])
	return best


# вход в класс режима: подбор варианта, стартовые страх/пропаганда/фальсификации, обещание хунты и срок переходного правительства
func reg60_enter(cls: String, quiet: bool) -> void:
	au["var"] = ""
	if cls == "dem":
		return
	var id := reg60_pick(cls)
	au["var"] = id
	var v := reg60_def(id)
	if v.is_empty():
		return
	if not quiet:
		var st: Dictionary = v.get("start", {})
		if st.has("fear"):
			au["fear"] = maxf(float(au["fear"]), float(st["fear"]))
		if st.has("prop"):
			au["prop"] = maxf(float(au["prop"]), float(st["prop"]))
		if st.has("fraud"):
			au["fraud"] = maxf(float(au["fraud"]), float(st["fraud"]))
		if st.has("cult"):
			au["cult"] = maxi(int(au["cult"]), int(st["cult"]))
		au["pris"] = maxi(int(au["pris"]), int(float(au["fear"]) * 12.0))
		log_line("[color=%s][b]Вариант режима: %s.[/b] %s[/color]" % [COL_WARN, String(v["n"]), String(v["d"])])
		reg60_flag_offer()
	if cls == "junta" and id == "jn_temp":
		au["promise"] = turn + 24
	if cls == "transitional":
		au["tr_end"] = turn + 36
		au["tr_ext"] = 0


# после смены режима игре есть что предложить по флагу
func reg60_flag_offer() -> void:
	flag_month_force()


# добавки варианта к показателям (steady-state: mods пересчитываются каждый месяц)
func reg60_dyn() -> void:
	var v := reg60_var()
	if v.is_empty() or mods.is_empty():
		return
	var m: Dictionary = v["m"]
	for k in m:
		mods[k] = float(mods.get(k, 0.0)) + float(m[k])
	mods["eff_bonus"] = clampf(float(mods.get("eff_bonus", 0.0)), -0.03, 0.03)
	# переходное правительство: чем дольше затянут срок, тем хуже настроение
	if String(au.get("cls", "")) == "transitional":
		var over: int = int(au.get("tr_ext", 0))
		if over > 0:
			mods["mood_shift"] = float(mods["mood_shift"]) - 0.04 * float(over)


# человеческий текст добавок варианта
func reg60_effect_text(v: Dictionary) -> String:
	var pros: PackedStringArray = []
	var cons: PackedStringArray = []
	var m: Dictionary = v["m"]
	for k in m:
		if not MOD_INFO.has(k):
			continue
		var it: Array = mod_item(String(k), 0.0, float(m[k]))
		if not mod_visible(String(k), 0.0, float(m[k])):
			continue
		var txt := String(it[0])
		if int(it[1]) > 0:
			pros.append(txt)
		elif int(it[1]) < 0:
			cons.append(txt)
		else:
			pros.append(txt)
	var t := ""
	if pros.size() > 0:
		t += "[color=%s]▲ %s[/color]\n" % [COL_GOOD, "; ".join(pros)]
	if cons.size() > 0:
		t += "[color=%s]▼ %s[/color]\n" % [COL_BAD, "; ".join(cons)]
	return t


# цены рычагов зависят от варианта: «0.6» — на 40% дешевле, «0» — рычаг недоступен
func reg60_tool_mult(id: String) -> float:
	var v := reg60_var()
	if v.is_empty():
		return 1.0
	var tl: Dictionary = v.get("tl", {})
	return float(tl.get(id, 1.0))


func reg60_act_def(id: String) -> Array:
	for a in AU_ACTS60:
		if String(a[0]) == id:
			return a
	return []


func reg60_has(id: String) -> bool:
	return not reg60_act_def(id).is_empty()


func reg60_check(id: String) -> String:
	var why := pl_why("gov")
	if why != "":
		return why
	if game_over:
		return "игра окончена"
	if not au_on():
		return "при демократии эти рычаги недоступны"
	var a := reg60_act_def(id)
	var cls_req: String = String(a[4])
	if cls_req != "" and not (String(au["cls"]) in cls_req.split(",")):
		return "только для режима: %s" % ", ".join(Array(cls_req.split(",")).map(func(x: String) -> String: return au_class_name(x)))
	if reg60_tool_mult(id) <= 0.0:
		return "при этом варианте режима недоступно"
	var cost := float(a[2]) * reg60_tool_mult(id)
	if cap_spendable() < cost:
		return "нужно %.0f капитала" % cost
	if int(au["cd"].get(id, -99)) > turn:
		return "ещё %d мес." % (int(au["cd"][id]) - turn)
	match id:
		"tr_elect":
			if String(au["cls"]) != "transitional":
				return "только для переходного правительства"
		"tr_extend":
			if int(au.get("tr_ext", 0)) >= 3:
				return "срок уже продлевался трижды"
		"rel_ban":
			if not ch_on():
				return "в этой стране нет церковной системы"
	return ""


func reg60_act(id: String) -> bool:
	var why := reg60_check(id)
	if why != "":
		log_line("[color=%s]Нельзя: %s.[/color]" % [COL_WARN, why])
		return false
	var a := reg60_act_def(id)
	capital -= float(a[2]) * reg60_tool_mult(id)
	au_cd(id, int(a[3]))
	var txt := ""
	match id:
		"show_trial":
			au["fear"] = minf(100.0, float(au["fear"]) + 10.0)
			au["pris"] = int(au["pris"]) + 40
			au_und_add(-10.0)
			add_support("Молодёжь", -3.0)
			add_support("Силовики", 1.0)
			dip_all(-2.0, true)
			lvl["corruption"] = clampf(float(lvl["corruption"]) - 1.0, 0.0, 100.0)
			au["prop"] = minf(100.0, float(au["prop"]) + 3.0)
			txt = "Показательный процесс: обвиняемые «сознались», приговоры громкие. Страх вырос, подполье притихло."
			if au_und_max() > 60.0 and randf() < 0.3:
				regime_risk = minf(100.0, regime_risk + 5.0)
				txt += " [color=%s]Но процесс породил мучеников — подполье получило новые лозунги.[/color]" % COL_BAD
		"rally":
			au["prop"] = minf(100.0, float(au["prop"]) + 5.0)
			add_all_support(1.5)
			debt += gdp * 0.0005
			for k in au_clan_of_kind("apparat"):
				au_clan_add(k, 4.0)
			txt = "Массовые митинги в поддержку власти: автобусы, флаги, праздничные концерты (0,05% ВВП). Официальный рейтинг вырос."
		"enemy":
			add_support("Силовики", 3.0)
			add_all_support(1.5)
			au["prop"] = minf(100.0, float(au["prop"]) + 4.0)
			au["fear"] = minf(100.0, float(au["fear"]) + 2.0)
			dip_all(-3.0, false)
			shock += -0.15
			for k in au_clan_of_kind("force"):
				au_clan_add(k, 6.0)
			txt = "Назван внешний враг: газеты и телевидение объясняют трудности «происками извне». Силовики воодушевлены, отношения с миром хуже."
		"rel_ban":
			if String(au["cls"]) == "theocracy":
				church_fx({"pow": 4.0})
				add_support("Пенсионеры", 1.0)
				add_support("Молодёжь", -3.0)
				dip_all(-2.0, true)
				regall_unrest(2.0)
				txt = "Запрещены иные веры и обряды, не одобренные духовенством: единая вера укрепилась, меньшинства и молодёжь недовольны."
			else:
				church_fx({"pow": -6.0, "rel": -2.0})
				add_support("Пенсионеры", -3.0)
				add_support("Село", -2.0)
				add_support("Молодёжь", 1.0)
				au["fear"] = minf(100.0, float(au["fear"]) + 4.0)
				txt = "Запрещены религиозные организации и обряды вне государственного надзора: влияние церкви упало, верующие обижены."
		"tr_elect":
			txt = "Назначены свободные выборы: переходное правительство передаёт власть избранному парламенту."
			au_log(txt)
			au_set_gov("")
			return true
		"tr_extend":
			au["tr_end"] = int(au.get("tr_end", turn)) + 12
			au["tr_ext"] = int(au.get("tr_ext", 0)) + 1
			au_und_add(8.0)
			regime_risk = minf(100.0, regime_risk + 6.0)
			dip_all(-1.5, true)
			txt = "Срок переходного правительства продлён на год: обещания выборов отодвинуты."
	au_log(txt)
	return true


func regall_unrest(d: float) -> void:
	for r in regions:
		r["unrest"] = clampf(float(r["unrest"]) + d, 0.0, 100.0)


# события вариантов: идут в общий пул вместе с событиями класса режима (каждое с двойным весом)
func reg60_events() -> Array:
	var out: Array = []
	if au.is_empty() or not au_on():
		return out
	var id := String(au.get("var", ""))
	if id == "":
		return out
	for e in REG_EVENTS60:
		if String(e["var"]) == id:
			out.append(e)
			out.append(e)
	return out


# ежемесячный шаг: срок переходного правительства, прочее
func reg60_step() -> void:
	if au.is_empty() or not au_on():
		return
	if String(au["cls"]) == "transitional" and turn >= int(au.get("tr_end", 999999)) and current_event.is_empty() and not bool(au.get("tr_asked", false)):
		au["tr_asked"] = true
		current_event = {"special": "reg60", "t": "[b]Срок переходного правительства истёк.[/b] По обещанию пора назначать свободные выборы. Но у власти привыкли, а новые политики просят «ещё немного времени».", "o": [
			{"l": "Назначить выборы и передать власть (капитал −2)", "fx": {"capital": -2.0, "all": 3.0, "dip_all": 2.0}, "act": "tr_elect"},
			{"l": "Продлить срок на год (риск растёт)", "fx": {"au": {"und": 8.0, "risk": 6.0}, "dip_all": -1.5}, "act": "tr_extend"},
			{"l": "Закрепить власть: объявить себя правительством на постоянной основе", "fx": {"au": {"und": 12.0, "fear": 8.0, "risk": 10.0}, "dip_all": -3.0, "all": -3.0}, "act": "tr_stay"}]}
		event_region = -1
		present_event()
	elif String(au["cls"]) != "transitional":
		au["tr_asked"] = false


func reg60_event_act(act: String) -> void:
	match act:
		"tr_elect":
			au["tr_asked"] = false
			au_log("Назначены свободные выборы: переходное правительство передаёт власть избранному парламенту.")
			au_set_gov("")
		"tr_extend":
			au["tr_end"] = turn + 12
			au["tr_ext"] = int(au.get("tr_ext", 0)) + 1
			au["tr_asked"] = false
			au_log("Срок переходного правительства продлён на год.")
		"tr_stay":
			au["tr_end"] = turn + 600
			au_log("Переходное правительство объявило себя постоянным.")


func reg60_resolve(opt: Dictionary) -> void:
	var act: String = String(opt.get("act", ""))
	if act != "":
		reg60_event_act(act)
