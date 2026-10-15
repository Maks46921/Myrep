# v48_1: вооружённые силы.
# Рода войск (мотопехота, танки, артиллерия, аэромобильные части, территориальная оборона) со своими сильными сторонами;
# структура оборонного бюджета (личный состав, техника, подготовка, запасы); комплектование (контракт, выборочный призыв,
# всеобщий призыв) и обученный резерв; боеприпасы и оборонная промышленность; авиация и ПВО; боевой дух на войне;
# программы закупок с поставками; учения, миротворческие миссии, экспорт оружия; гонка вооружений у соседей.
# В мирное время без действий игрока модуль не меняет экономику и поддержку групп (эталонные прогоны не сдвигаются):
# постоянные эффекты считаются как разница с исходным положением страны. Случайности — только mil_rng.
extends "res://scripts/logic/military.gd"

# --- заглушки: эти функции реализованы в модулях ниже по цепочке и там переопределяются (tools/stubs.py) ---


func con_mil(k: String) -> float:
	return 0.0


func dx_has_treaty(c: String, id: String) -> bool:
	return false


func dx_on() -> bool:
	return false


func fa_bots() -> Array:
	return []


func fa_eu_sanc() -> bool:
	return false


func fa_on() -> bool:
	return false


func fa_pers(c: String) -> Dictionary:
	return {}


# --- конец заглушек ---


const AR_TYPES := ["inf", "arm", "art", "lgt", "td"]
# att/def — сила в атаке и обороне, spd — скорость, ammo — расход боеприпасов, n — прилагательное в названии
const AR_INFO := {
	"inf": {"n": "мотопехотная", "name": "Мотопехота", "short": "МП", "att": 1.0, "def": 1.0, "spd": 1.0, "ammo": 1.0,
		"d": "Основа армии: держит фронт и занимает территорию."},
	"arm": {"n": "танковая", "name": "Танковые войска", "short": "ТВ", "att": 1.4, "def": 1.1, "spd": 1.25, "ammo": 1.3,
		"d": "Прорыв и быстрое наступление; дорогая техника, больше расход боеприпасов."},
	"art": {"n": "артиллерийская", "name": "Артиллерия", "short": "АР", "att": 1.2, "def": 1.3, "spd": 0.85, "ammo": 2.2,
		"d": "Огонь с закрытых позиций: сильна в обороне и при поддержке атаки, но «съедает» снаряды."},
	"lgt": {"n": "аэромобильная", "name": "Аэромобильные войска", "short": "ДШ", "att": 1.05, "def": 0.85, "spd": 1.45, "ammo": 0.8,
		"d": "Быстрая переброска и манёвр, слабее в долгой обороне."},
	"td": {"n": "территориальной обороны", "name": "Территориальная оборона", "short": "ТО", "att": 0.55, "def": 1.15, "spd": 0.8, "ammo": 0.6,
		"d": "Дешёвые части из добровольцев и резервистов: хорошо обороняют свою землю, за её пределами слабы."}}

# страна: [комплектование, доли танковых/артиллерийских/аэромобильных соединений, запас боеприпасов (месяцев интенсивных боёв),
#          оборонная промышленность (сколько месяцев запаса выпускает за год), авиация (истребители в современном эквиваленте), ПВО]
# Оценки по открытым данным 2024–2025 гг., округлено.
const AR_DATA := {
	"DE": ["pro", 0.25, 0.15, 0.10, 0.8, 0.9, 160.0, 30.0], "FR": ["pro", 0.20, 0.15, 0.15, 0.8, 0.8, 200.0, 24.0],
	"NL": ["pro", 0.10, 0.15, 0.20, 0.6, 0.2, 40.0, 10.0], "BE": ["pro", 0.05, 0.10, 0.25, 0.5, 0.3, 40.0, 2.0],
	"LU": ["pro", 0.0, 0.0, 0.0, 0.5, 0.0, 0.0, 0.0], "CH": ["con", 0.15, 0.20, 0.05, 2.0, 0.4, 30.0, 8.0],
	"AT": ["con", 0.10, 0.15, 0.10, 1.0, 0.2, 15.0, 4.0], "PL": ["pro", 0.30, 0.20, 0.10, 1.2, 0.6, 90.0, 20.0],
	"CZ": ["pro", 0.15, 0.15, 0.10, 1.0, 0.5, 14.0, 6.0], "DK": ["mix", 0.10, 0.15, 0.05, 0.6, 0.2, 30.0, 2.0],
	"NO": ["mix", 0.15, 0.15, 0.10, 1.0, 0.5, 52.0, 8.0], "SE": ["mix", 0.15, 0.15, 0.10, 1.0, 0.6, 90.0, 10.0],
	"IT": ["pro", 0.15, 0.15, 0.15, 0.8, 0.6, 150.0, 15.0], "ES": ["pro", 0.15, 0.15, 0.15, 0.8, 0.4, 150.0, 12.0],
	"PT": ["pro", 0.10, 0.10, 0.15, 0.6, 0.1, 28.0, 2.0], "GB": ["pro", 0.15, 0.15, 0.20, 0.7, 0.7, 160.0, 10.0],
	"IE": ["pro", 0.0, 0.10, 0.10, 0.5, 0.0, 0.0, 1.0], "SI": ["pro", 0.05, 0.10, 0.10, 0.6, 0.1, 0.0, 2.0],
	"SK": ["pro", 0.10, 0.15, 0.05, 1.0, 0.5, 14.0, 3.0], "HU": ["pro", 0.15, 0.15, 0.05, 0.8, 0.2, 14.0, 4.0],
	"FI": ["con", 0.15, 0.30, 0.05, 2.5, 0.5, 62.0, 10.0], "HR": ["pro", 0.10, 0.15, 0.10, 0.8, 0.1, 12.0, 2.0],
	"RS": ["pro", 0.15, 0.20, 0.05, 1.2, 0.5, 14.0, 6.0], "BA": ["pro", 0.0, 0.10, 0.05, 0.6, 0.1, 0.0, 0.0],
	"ME": ["pro", 0.0, 0.05, 0.05, 0.5, 0.0, 0.0, 0.0], "MK": ["pro", 0.05, 0.10, 0.05, 0.5, 0.0, 0.0, 0.0],
	"AL": ["pro", 0.0, 0.10, 0.05, 0.5, 0.0, 0.0, 0.0], "XK": ["pro", 0.0, 0.05, 0.05, 0.5, 0.0, 0.0, 0.0],
	"BG": ["pro", 0.10, 0.15, 0.05, 1.0, 0.5, 15.0, 4.0], "RO": ["pro", 0.15, 0.20, 0.10, 1.0, 0.3, 30.0, 6.0],
	"GR": ["con", 0.30, 0.20, 0.10, 2.0, 0.2, 200.0, 20.0], "EE": ["con", 0.05, 0.20, 0.05, 1.5, 0.1, 0.0, 2.0],
	"LV": ["con", 0.05, 0.15, 0.05, 1.0, 0.0, 0.0, 2.0], "LT": ["con", 0.10, 0.15, 0.05, 1.2, 0.1, 0.0, 3.0],
	# v49: Молдова (призыв), Беларусь (призыв), Украина (мобилизация военного времени, своё производство дронов и снарядов), Россия (призыв + контракт, военная экономика)
	"MD": ["con", 0.0, 0.10, 0.05, 0.4, 0.0, 0.0, 1.0], "BY": ["con", 0.25, 0.20, 0.10, 1.5, 0.6, 40.0, 15.0],
	"UA": ["con", 0.15, 0.30, 0.10, 0.6, 1.5, 60.0, 30.0], "RU": ["mix", 0.25, 0.30, 0.10, 3.0, 3.5, 700.0, 150.0]}

# комплектование: r — размер обученного резерва (относительно), q — выучка кадровых частей, c — сколько солдат на те же деньги,
# yb — сдвиг поддержки молодёжи, sb — силовиков
const AR_SVC := {
	"pro": {"n": "Контрактная армия", "r": 1.0, "q": 1.06, "c": 1.0, "yb": 0.0, "sb": 0.0,
		"d": "Только добровольцы по контракту: выше выучка, дороже солдат, маленький резерв."},
	"mix": {"n": "Выборочный призыв", "r": 2.5, "q": 1.0, "c": 1.1, "yb": -1.0, "sb": 0.5,
		"d": "Служат отобранные призывники (как в Швеции, Норвегии, Дании): резерв растёт, недовольство умеренное."},
	"con": {"n": "Всеобщий призыв", "r": 6.0, "q": 0.95, "c": 1.25, "yb": -2.5, "sb": 1.0,
		"d": "Служат почти все мужчины призывного возраста (как в Финляндии, Греции, Эстонии): огромный резерв, недовольна молодёжь."}}

const AR_BS0 := {"pers": 0.50, "eq": 0.25, "trn": 0.15, "stk": 0.10}
const AR_BS_KEYS := ["pers", "eq", "trn", "stk"]
const AR_BS_NAMES := {"pers": "Личный состав", "eq": "Техника и модернизация", "trn": "Подготовка и учения", "stk": "Запасы боеприпасов"}
const AR_BS_TIPS := {"pers": "Зарплаты и содержание: от этой доли зависит, сколько солдат может содержать бюджет.",
	"eq": "Закупки и ремонт техники: растёт уровень оснащения — сила каждого соединения и авиации.",
	"trn": "Учения и полигоны: растёт готовность — выучка войск и скорость мобилизации.",
	"stk": "Склады боеприпасов: растёт запас на случай войны."}

# программы закупок: стоимость (млрд €, оплачивается помесячно сверх бюджета — из специального оборонного фонда), срок (мес.), эффект
const AR_PROG := [
	{"id": "fighter5", "n": "Истребители 5-го поколения (12 шт.)", "cost": 2.4, "m": 48, "fx": {"air": 14.0},
		"d": "Малозаметные многоцелевые самолёты: господство в воздухе на десятилетия."},
	{"id": "fighter4", "n": "Многоцелевые истребители (12 шт.)", "cost": 1.2, "m": 30, "fx": {"air": 10.0},
		"d": "Проверенные самолёты поколения 4+: дешевле и быстрее в поставке."},
	{"id": "sam_l", "n": "ПВО большой дальности (дивизион)", "cost": 1.2, "m": 30, "fx": {"ad": 7.0},
		"d": "Защита городов и заводов от самолётов и баллистических ракет."},
	{"id": "sam_s", "n": "ПВО малой и средней дальности (4 батареи)", "cost": 0.5, "m": 18, "fx": {"ad": 4.0},
		"d": "Прикрытие войск и объектов от дронов, вертолётов и крылатых ракет."},
	{"id": "tanks", "n": "Танки (батальон, 44 шт.)", "cost": 0.9, "m": 24, "fx": {"conv": "arm", "eq": 0.02},
		"d": "Одно мотопехотное соединение становится танковым."},
	{"id": "ifv", "n": "Боевые машины пехоты (60 шт.)", "cost": 0.6, "m": 18, "fx": {"eq": 0.04},
		"d": "Защищённая техника для пехоты: оснащение всей армии выше."},
	{"id": "arty", "n": "Самоходные гаубицы (дивизион, 24 шт.)", "cost": 0.4, "m": 18, "fx": {"conv": "art", "eq": 0.01},
		"d": "Одно мотопехотное соединение становится артиллерийским."},
	{"id": "mlrs", "n": "РСЗО дальнего действия (12 пусковых)", "cost": 0.5, "m": 18, "fx": {"art_k": 0.06},
		"d": "Точные удары на 70–300 км: артиллерия сильнее."},
	{"id": "heli", "n": "Ударные вертолёты (12 шт.)", "cost": 0.8, "m": 24, "fx": {"lgt_k": 0.08, "air": 2.0},
		"d": "Огневая поддержка аэромобильных и танковых частей."},
	{"id": "drones", "n": "Ударные и разведывательные беспилотники", "cost": 0.25, "m": 12, "fx": {"drone": 1}, "tech": "m1",
		"d": "Разведка и удары дронами: все соединения сильнее. Нужна технология «Беспилотные системы»."},
	{"id": "ammo_plant", "n": "Завод боеприпасов", "cost": 0.7, "m": 30, "fx": {"ind": 0.3},
		"d": "Свой выпуск снарядов: запасы пополняются быстрее, на войне — тем более."},
	{"id": "stock", "n": "Пополнение складов (полмесяца боёв)", "cost": -1.0, "m": 6, "fx": {"ammo": 0.5},
		"d": "Закупка боеприпасов впрок; цена зависит от численности армии."}]

# миротворческие миссии: k — тыс. военных, req — кому доступно, rel — кто доволен
const AR_MIS := [
	{"id": "un", "n": "Миссия ООН (Ливан)", "k": 0.6, "req": "", "d": "Наблюдение за перемирием под флагом ООН: уважение всех стран."},
	{"id": "eu", "n": "Миссия ЕС (Средиземное море и Африка)", "k": 0.4, "req": "eu", "d": "Охрана судоходства и обучение армий партнёров: ЕС доволен."},
	{"id": "nato", "n": "Миссия НАТО (передовое присутствие на востоке)", "k": 1.0, "req": "nato", "d": "Батальон в составе сил сдерживания: союзники по НАТО довольны."}]

var ar: Dictionary = {}


# ============================================================
#  ИНИЦИАЛИЗАЦИЯ И ДОСТУП
# ============================================================


func ar_init() -> void:
	ar = {}
	if not MIL_BASE.has(ccode):
		return
	var d: Array = AR_DATA.get(ccode, ["pro", 0.1, 0.15, 0.05, 0.8, 0.1, 0.0, 0.0])
	var b: Array = MIL_BASE[ccode]
	ar = {"svc": String(d[0]), "svc0": String(d[0]), "svc_cd": 0, "rsv": float(b[1]), "rsv0": float(b[1]),
		"bs": AR_BS0.duplicate(), "eq": 1.0, "eq_add": 0.0, "rd": 60.0, "rdx": 0.0,
		"ammo": float(d[4]), "ammo0": float(d[4]), "ind": float(d[5]), "ind0": float(d[5]),
		"air": float(d[6]), "air0": float(d[6]), "ad": float(d[7]), "ad0": float(d[7]),
		"drone": 0, "art_k": 0.0, "lgt_k": 0.0, "prog": [], "done": {}, "pq": [], "mis": "", "mis_t": 0, "xp": 0.0,
		"exp": 1, "wecon": false, "cd": {}, "wm": {}, "wmt": {}, "wlog": {}, "deter": {}, "td": 0.0,
		"pw0": 0.0, "hist": {"pw": [], "ammo": [], "rd": [], "eq": []}}
	ar["pw0"] = mil_country_power(ccode)


func ar_on() -> bool:
	return mil_on() and not ar.is_empty()


func ar_tp(f: Dictionary) -> String:
	return String(f.get("tp", "inf"))


func ar_info(tp: String) -> Dictionary:
	return AR_INFO.get(tp, AR_INFO["inf"])


func ar_data(cc: String) -> Array:
	return AR_DATA.get(cc, ["pro", 0.1, 0.15, 0.05, 0.8, 0.1, 0.0, 0.0])


# род войск нового соединения: резервисты — мотопехота и территориальная оборона; кадровые — по структуре армии страны
func ar_auto_type(cc: String, kind: String) -> String:
	var cnt := {}
	var n := 0
	for f in mil.get("units", []):
		if String(f["cc"]) == cc and String(f["kind"]) == kind:
			cnt[ar_tp(f)] = int(cnt.get(ar_tp(f), 0)) + 1
			n += 1
	if kind == "res":
		# резервисты: мотопехота, территориальная оборона и — где артиллерия важна (Финляндия, Греция) — артиллерия
		if n % 3 == 2:
			return "td"
		return "art" if n % 3 == 1 and float(ar_data(cc)[2]) >= 0.2 else "inf"
	if n == 0:
		return "inf"
	var d: Array = ar_data(cc)
	var want := {"arm": float(d[1]), "art": float(d[2]), "lgt": float(d[3])}
	var best := "inf"
	var bv := 0.35
	for tp in want:
		var gap: float = float(want[tp]) * float(n + 1) - float(int(cnt.get(tp, 0)))
		if gap > bv:
			bv = gap
			best = String(tp)
	return best


func ar_unit_name(k: int, sz: float, kind: String, tp: String) -> String:
	if tp == "":
		return ""
	if tp == "td":
		return "%d-я бригада территориальной обороны" % k
	var what := "бригада" if sz < 6.0 else "дивизия"
	return "%d-я %s%s %s" % [k, "резервная " if kind == "res" else "", String(ar_info(tp)["n"]), what]


func ar_bs(k: String) -> float:
	if ar.is_empty():
		return float(AR_BS0[k])
	return float((ar["bs"] as Dictionary).get(k, AR_BS0[k]))


# ============================================================
#  МНОЖИТЕЛИ ДЛЯ ВОЕННОГО МОДУЛЯ
# ============================================================


# сколько солдат содержит бюджет: доля на личный состав и модель комплектования
func ar_cap_mult() -> float:
	if ar.is_empty():
		return 1.0
	var sv: Dictionary = AR_SVC[String(ar["svc"])]
	var sv0: Dictionary = AR_SVC[String(ar["svc0"])]
	return pow(ar_bs("pers") / 0.5, 0.7) * float(sv["c"]) / float(sv0["c"]) * (1.0 + con_mil("cap"))


# военные в миротворческой миссии (тыс.): их нет дома
func ar_mis_k() -> float:
	if ar.is_empty() or String(ar["mis"]) == "":
		return 0.0
	for m in AR_MIS:
		if String(m["id"]) == String(ar["mis"]):
			return float(m["k"])
	return 0.0


func ar_rd() -> float:
	if ar.is_empty():
		return 60.0
	return clampf(float(ar["rd"]) + float(ar["rdx"]), 0.0, 100.0)


# выучка: готовность, модель комплектования, опыт миссий
func ar_q_mult() -> float:
	if ar.is_empty():
		return 1.0
	var sv: Dictionary = AR_SVC[String(ar["svc"])]
	var sv0: Dictionary = AR_SVC[String(ar["svc0"])]
	return (0.85 + 0.25 * ar_rd() / 100.0) / 1.0 * float(sv["q"]) / float(sv0["q"]) * (1.0 + float(ar["xp"]))


# скорость мобилизации: готовность сокращает сроки
func ar_mob_speed() -> float:
	return clampf(1.0 + (60.0 - ar_rd()) / 100.0, 0.6, 1.5)


# обученный резерв (тыс.)
func ar_rsv() -> float:
	if ar.is_empty():
		var b: Array = MIL_BASE.get(ccode, [10.0, 0.0, 1.0])
		return float(b[1])
	return float(ar["rsv"])


func ar_ammo(cc: String) -> float:
	if cc == ccode:
		return 9.0 if ar.is_empty() else float(ar["ammo"])
	if mil_at_war() and cc == String(mil["war"]["lead"]):
		return float(mil["war"].get("ammo_e", 9.0))
	return 9.0


# «снарядный голод»: при запасе меньше 0,3 месяца боёв сила падает до 55%
func ar_ammo_mult(cc: String) -> float:
	return clampf(0.55 + 0.45 * ar_ammo(cc) / 0.3, 0.55, 1.0)


func ar_eq(cc: String) -> float:
	if cc == ccode and not ar.is_empty():
		return float(ar["eq"])
	return 1.0


# общий множитель силы соединения страны: техника и боеприпасы
func ar_pow_mult(cc: String) -> float:
	return ar_eq(cc) * ar_ammo_mult(cc)


func ar_mor(side: int) -> float:
	if not mil_at_war():
		return 50.0
	return float(mil["war"].get("mor" if side == 0 else "mor_e", 50.0))


func ar_mor_mult(cc: String) -> float:
	var sd := mil_side(cc)
	if sd < 0:
		return 1.0
	return 0.88 + 0.24 * ar_mor(sd) / 100.0


func ar_drone_mult(cc: String) -> float:
	if cc != ccode or ar.is_empty():
		return 1.0
	return 1.0 + 0.04 * float(mini(3, int(ar["drone"]) + (1 if tech_done("m1") else 0)))


# сила соединения в атаке и в обороне (АТЕ a)
func ar_att(f: Dictionary) -> float:
	var cc := String(f["cc"])
	var tp := ar_tp(f)
	var m: float = float(ar_info(tp)["att"])
	if cc == ccode and not ar.is_empty():
		if tp == "art":
			m *= 1.0 + float(ar["art_k"])
		elif tp == "lgt":
			m *= 1.0 + float(ar["lgt_k"])
		elif tp == "arm" and tech_done("m4b"):
			m *= 1.05
	return m * ar_drone_mult(cc) * ar_mor_mult(cc)


func ar_def(f: Dictionary, a: int) -> float:
	var cc := String(f["cc"])
	var tp := ar_tp(f)
	var m: float = float(ar_info(tp)["def"])
	if tp == "td":
		m *= 1.0 if ate_cc(a) == cc else 0.7
	if cc == ccode and not ar.is_empty() and tp == "art":
		m *= 1.0 + float(ar["art_k"]) * 0.5
	return m * ar_drone_mult(cc) * ar_mor_mult(cc)


# взаимодействие родов войск: в атаке участвуют разные рода — сильнее
func ar_combined(units: Array) -> float:
	var seen := {}
	for f in units:
		var tp := ar_tp(f)
		if tp != "td":
			seen[tp] = true
	return 1.0 + 0.06 * float(clampi(seen.size() - 1, 0, 2))


# ============================================================
#  АВИАЦИЯ И ПВО
# ============================================================


func ar_air(cc: String) -> float:
	if cc == ccode:
		return 0.0 if ar.is_empty() else float(ar["air"]) * (0.85 + 0.15 * float(ar["eq"]))
	var lf: float = float((mil.get("loss", {}) as Dictionary).get(cc, 1.0))
	return float(ar_data(cc)[6]) * ar_wm(cc) * lf


func ar_ad(cc: String) -> float:
	if cc == ccode:
		return 0.0 if ar.is_empty() else float(ar["ad"]) * (1.15 if tech_done("m3") else 1.0) * (1.0 + con_mil("ad"))
	return float(ar_data(cc)[7]) * ar_wm(cc)


func ar_side_air(side: int) -> Vector2:
	var a := 0.0
	var d := 0.0
	for c in mil_side_ccs(side):
		a += ar_air(String(c))
		d += ar_ad(String(c))
	return Vector2(a, d)


# господство в воздухе: ±12% к силе войск стороны
func ar_air_mult(side: int) -> float:
	if not mil_at_war():
		return 1.0
	var s0 := ar_side_air(side)
	var s1 := ar_side_air(1 - side)
	var e0: float = s0.x * (1.0 - 0.5 * s1.y / (s1.y + 30.0)) + 1.0
	var e1: float = s1.x * (1.0 - 0.5 * s0.y / (s0.y + 30.0)) + 1.0
	return clampf(1.0 + 0.12 * log(e0 / e1) / log(4.0), 0.88, 1.12)


# удары авиации и ракет противника по экономике: чем слабее своя ПВО, тем больнее (п.п. роста)
func ar_strike_g() -> float:
	if not ar_on() or not mil_at_war() or int(mil["war"].get("cf", 0)) > 0:
		return 0.0
	var s0 := ar_side_air(0)
	var s1 := ar_side_air(1)
	return -1.2 * s1.x / (s1.x + 2.0 * s0.y + 15.0)


# ============================================================
#  ГОНКА ВООРУЖЕНИЙ СОСЕДЕЙ
# ============================================================


func ar_wm(cc: String) -> float:
	if ar.is_empty():
		return 1.0
	return float((ar["wm"] as Dictionary).get(cc, 1.0))


func ar_deterred(cc: String) -> bool:
	return not ar.is_empty() and int((ar["deter"] as Dictionary).get(cc, 0)) > 0


func ar_world_month() -> void:
	var my_pw: float = mil_country_power(ccode)
	var ratio: float = my_pw / maxf(1.0, float(ar["pw0"]))
	var nbs: Array = tech_nb()
	var wm: Dictionary = ar["wm"]
	var wmt: Dictionary = ar["wmt"]
	var aggr: bool = mil_at_war() and bool(mil["war"]["aggr"])
	for c in fa_bots():
		if not MIL_BASE.has(c):
			continue
		# общее перевооружение Европы: НАТО идёт к новым целям по расходам
		var t: float = 1.0 + (minf(0.2, float(turn) * 0.0025) if mil_is_nato(c) else minf(0.08, float(turn) * 0.001))
		var threat := 0.0
		if c in nbs:
			var hawk: float = float(fa_pers(c)["hawk"]) if fa_on() else 0.5
			if ratio > 1.15 and (fed_rel(c) < 45.0 or hawk >= 0.5):
				threat = clampf((ratio - 1.15) * 0.8, 0.0, 0.35) * (0.6 + 0.8 * hawk)
			if aggr:
				threat += 0.15
		t += threat
		wmt[c] = t
		var cur: float = float(wm.get(c, 1.0))
		wm[c] = cur + (t - cur) * 0.03
		# заметный ответ на ваше усиление — в журнал и в память страны
		var lv: float = float((ar["wlog"] as Dictionary).get(c, 0.0))
		if threat > lv + 0.1:
			(ar["wlog"] as Dictionary)[c] = threat
			ar_log("«%s» наращивает армию в ответ на усиление ваших вооружённых сил." % String(WORLD[c]["name"]), COL_WARN)
			if fa_on():
				fa_hit(c, -2.0, "гонка вооружений")
		elif threat < lv - 0.15:
			(ar["wlog"] as Dictionary)[c] = threat
	# союзники по НАТО раз в год оценивают ваши расходы на оборону (цели: 2% ВВП и 3,5% к 2035 г.)
	if fa_on() and mil_is_nato(ccode) and turn > 0 and turn % 12 == 0:
		var pct: float = ar_nato_pct()
		var n_up := 0
		for c3 in fa_bots():
			if not mil_is_nato(String(c3)):
				continue
			var hk: float = float(fa_pers(String(c3))["hawk"])
			if pct >= 3.5:
				fa_hit(String(c3), 1.0 + hk, "расходы на оборону по целям НАТО")
				n_up += 1
			elif pct < 2.0 and hk >= 0.5:
				fa_hit(String(c3), -1.0, "недостаточные расходы на оборону")
				n_up -= 1
		if n_up > 0:
			ar_log("союзники по НАТО отмечают: вы тратите на оборону %.1f%% ВВП — больше новой цели 3,5%%." % pct, COL_GOOD)
		elif n_up < 0:
			ar_log("союзники по НАТО недовольны: расходы на оборону %.1f%% ВВП — ниже обязательных 2%%." % pct, COL_WARN)
	var dt: Dictionary = ar["deter"]
	for c2 in dt.keys():
		dt[c2] = int(dt[c2]) - 1
		if int(dt[c2]) <= 0:
			dt.erase(c2)


# ============================================================
#  МЕСЯЦ
# ============================================================


func ar_log(txt: String, col: String = "") -> void:
	mil_log(txt, col)


func ar_cd(k: String) -> int:
	return int((ar["cd"] as Dictionary).get(k, 0))


func ar_month() -> void:
	if not ar_on():
		return
	var sr: float = mil_spend_ratio()
	var cd: Dictionary = ar["cd"]
	for k in cd.keys():
		cd[k] = int(cd[k]) - 1
		if int(cd[k]) <= 0:
			cd.erase(k)
	if int(ar["svc_cd"]) > 0:
		ar["svc_cd"] = int(ar["svc_cd"]) - 1
	# готовность и оснащение подтягиваются к тому, что оплачивает бюджет
	var rd_t: float = clampf(25.0 + 35.0 * sr * ar_bs("trn") / 0.15, 15.0, 95.0)
	ar["rd"] = float(ar["rd"]) + (rd_t - float(ar["rd"])) * 0.08
	ar["rdx"] = float(ar["rdx"]) * 0.8
	var eq_t: float = clampf(0.55 + 0.45 * sr * ar_bs("eq") / 0.25, 0.5, 1.6) + float(ar["eq_add"])
	ar["eq"] = float(ar["eq"]) + (eq_t - float(ar["eq"])) * 0.02
	# обученный резерв: каждый год приходят и уходят призывные когорты
	var b: Array = MIL_BASE[ccode]
	var popk: float = total_pop() * 1000.0
	var base_r: float = maxf(float(b[1]), popk * 0.0005)
	var rsv_t: float = base_r * float(AR_SVC[String(ar["svc"])]["r"]) / float(AR_SVC[String(ar["svc0"])]["r"])
	if String(ar["svc"]) == String(ar["svc0"]):
		rsv_t = float(ar["rsv0"])
	ar["rsv"] = float(ar["rsv"]) + (rsv_t - float(ar["rsv"])) / 48.0
	# боеприпасы: в мире склады держатся на уровне, который оплачивает бюджет; на войне — выпуск промышленности
	var ind: float = ar_ind()
	var prod: float = (0.1 + ind * 0.6) / 12.0 * (3.0 if bool(ar["wecon"]) else 1.0)
	if mil_at_war():
		ar["ammo"] = float(ar["ammo"]) + prod
		ar_war_month()
	else:
		if bool(ar["wecon"]):
			ar["wecon"] = false
			ar_log("война окончена: промышленность возвращается к мирной продукции.", COL_GOOD)
		var am_t: float = float(ar["ammo0"]) * pow(ar_bs("stk") / 0.1, 0.8) * sqrt(sr) + float(ar.get("ammo_add", 0.0))
		var am: float = float(ar["ammo"])
		if am < am_t:
			ar["ammo"] = minf(am_t, am + prod * 0.6)
		elif am > am_t:
			ar["ammo"] = maxf(am_t, am - am * 0.01)
	# заказанные боеприпасы
	var pq: Array = ar["pq"]
	for i in range(pq.size() - 1, -1, -1):
		pq[i]["m"] = int(pq[i]["m"]) - 1
		if int(pq[i]["m"]) <= 0:
			ar["ammo"] = float(ar["ammo"]) + float(pq[i]["amt"])
			ar_log("прибыла партия боеприпасов: +%.1f мес. боёв." % float(pq[i]["amt"]), COL_GOOD)
			pq.remove_at(i)
	ar_prog_month()
	ar_mis_month()
	ar_exp_month()
	ar_world_month()
	var h: Dictionary = ar["hist"]
	for k2 in ["pw", "ammo", "rd", "eq"]:
		var v: float = mil_country_power(ccode) if k2 == "pw" else (float(ar["ammo"]) if k2 == "ammo" else (ar_rd() if k2 == "rd" else float(ar["eq"])))
		(h[k2] as Array).append(v)
		if (h[k2] as Array).size() > 72:
			(h[k2] as Array).pop_front()


func ar_ind() -> float:
	return 0.0 if ar.is_empty() else float(ar["ind"])


# постоянные сдвиги поддержки групп — только как разница с исходным положением страны
func ar_apply_mods() -> void:
	if not ar_on():
		return
	var sv: Dictionary = AR_SVC[String(ar["svc"])]
	var sv0: Dictionary = AR_SVC[String(ar["svc0"])]
	var dy: float = float(sv["yb"]) - float(sv0["yb"])
	var ds: float = float(sv["sb"]) - float(sv0["sb"])
	var e: int = int(ar["exp"])
	var add := {"Молодёжь": dy, "Силовики": ds, "Бизнес": (1.0 if e == 2 else (-0.8 if e == 0 else 0.0)),
		"Рабочие": (0.5 if e == 2 else 0.0), "Экологи": (-1.5 if e == 2 else (1.0 if e == 0 else 0.0))}
	for g in add:
		if float(add[g]) != 0.0 and GROUPS.has(g):
			mods["gb_" + String(g)] = float(mods.get("gb_" + String(g), 0.0)) + float(add[g])


# ============================================================
#  ВОЙНА: БОЕВОЙ ДУХ, БОЕПРИПАСЫ, АВИАЦИЯ
# ============================================================


func ar_war_start() -> void:
	if not mil_at_war():
		return
	var w: Dictionary = mil["war"]
	var lead := String(w["lead"])
	var dem: float = war_demo(ccode)
	w["mor"] = clampf(55.0 + (0.0 if bool(w["aggr"]) else 18.0) - (14.0 * dem if bool(w["aggr"]) else 0.0), 15.0, 90.0)
	w["mor_e"] = 55.0 + (18.0 if bool(w["aggr"]) else 0.0)
	w["ammo_e"] = float(ar_data(lead)[4]) * ar_wm(lead)
	w["ind_e"] = float(ar_data(lead)[5])
	w["mor_log"] = 0


func ar_war_month() -> void:
	var w: Dictionary = mil["war"]
	var sc: float = float(w["score"])
	var occ: Array = w["occ"]
	var cf: bool = int(w.get("cf", 0)) > 0
	# боевой дух: успехи и потери, оккупация, усталость; оборонительная война держит дух дольше
	var m0: float = float(w.get("mor", 55.0))
	var dm: float = clampf(sc / 12.0, -3.0, 3.0) - float(occ[0]) * 20.0 - (0.8 if bool(w["aggr"]) else 0.2) * minf(3.0, float(w["weary"]) / 3.0)
	if cf:
		dm += 1.0
	w["mor"] = clampf(m0 + dm, 10.0, 95.0)
	w["mor_e"] = clampf(float(w.get("mor_e", 55.0)) - clampf(sc / 12.0, -3.0, 3.0) - float(occ[1]) * 20.0 - 0.3 + (1.0 if cf else 0.0), 10.0, 95.0)
	if float(w["mor"]) < 30.0 and int(w.get("mor_log", 0)) == 0:
		w["mor_log"] = 1
		ar_log("боевой дух армии падает: растёт число отказов и дезертиров, части медленнее восстанавливаются.", COL_BAD)
	elif float(w["mor"]) >= 40.0:
		w["mor_log"] = 0
	# боеприпасы противника: выпуск его промышленности и помощь союзников
	var lead := String(w["lead"])
	var help: float = 0.12 if (mil_is_nato(lead) or bool(WORLD.get(lead, {}).get("eu", false))) and float(w["ammo_e"]) < 0.5 else 0.0
	w["ammo_e"] = float(w["ammo_e"]) + (0.1 + float(w["ind_e"]) * 0.6) / 12.0 * 2.0 + help
	# потери авиации и ПВО
	if not cf:
		var s1 := ar_side_air(1)
		var s0 := ar_side_air(0)
		ar["air"] = maxf(0.0, float(ar["air"]) * (1.0 - 0.015 * s1.y / (s1.y + 25.0)))
		ar["ad"] = maxf(0.0, float(ar["ad"]) * (1.0 - 0.01 * s1.x / (s1.x + 60.0)))
		if s0.x > 0.0 and lead != "":
			var lf: Dictionary = mil["loss"]
			lf[lead] = maxf(0.3, float(lf.get(lead, 1.0)) - 0.004 * s0.x / (s0.x + s1.y * 2.0 + 20.0))
	# предупреждение о снарядном голоде
	if float(ar["ammo"]) < 0.3 and ar_cd("ammo_warn") == 0:
		(ar["cd"] as Dictionary)["ammo_warn"] = 3
		ar_log("[b]кончаются боеприпасы[/b]: запас %.2f мес. боёв — сила войск падает. Закупите снаряды у союзников или переведите промышленность на военные рельсы." % float(ar["ammo"]), COL_BAD)


# расход боеприпасов соединением за сутки боя
func ar_ammo_use(f: Dictionary) -> void:
	var cc := String(f["cc"])
	var k: float = float(f["str"]) * float(ar_info(ar_tp(f))["ammo"]) / 30.0
	if cc == ccode and not ar.is_empty():
		ar["ammo"] = maxf(0.0, float(ar["ammo"]) - k / maxf(5.0, mil_cap()))
	elif mil_at_war() and cc == String(mil["war"]["lead"]):
		var w: Dictionary = mil["war"]
		var ref: float = maxf(5.0, float((w["str0"] as Dictionary).get(cc, 10.0)))
		w["ammo_e"] = maxf(0.0, float(w.get("ammo_e", 1.0)) - k / ref)


# рост и инфляция от военной экономики и ударов по стране
func ar_war_g() -> float:
	if not ar_on():
		return 0.0
	return ar_strike_g() - (1.5 if bool(ar["wecon"]) else 0.0)


func ar_war_infl() -> float:
	if not ar_on():
		return 0.0
	return 0.6 if bool(ar["wecon"]) else 0.0


func ar_org_mult(cc: String) -> float:
	var sd := mil_side(cc)
	if sd < 0 or not mil_at_war():
		return 1.0
	return 0.6 + 0.8 * ar_mor(sd) / 100.0


# ============================================================
#  ДЕЙСТВИЯ ИГРОКА
# ============================================================


# доли оборонного бюджета: сдвиг одной статьи на d, остальные — пропорционально
func ar_shift_bs(k: String, d: float) -> String:
	if not ar_on():
		return "Армии нет."
	if opp_mode:
		return "В оппозиции оборонным бюджетом распоряжается правительство."
	var bs: Dictionary = ar["bs"]
	var lo := {"pers": 0.3, "eq": 0.05, "trn": 0.05, "stk": 0.05}
	var nv: float = clampf(float(bs[k]) + d, float(lo[k]), 0.75)
	var real_d: float = nv - float(bs[k])
	if absf(real_d) < 0.001:
		return "Дальше менять эту статью нельзя."
	var others := 0.0
	for k2 in AR_BS_KEYS:
		if k2 != k:
			others += float(bs[k2]) - float(lo[k2])
	if real_d > 0.0 and others < real_d - 0.0001:
		return "Остальные статьи уже на минимуме."
	for k2 in AR_BS_KEYS:
		if k2 == k:
			continue
		var room: float = float(bs[k2]) - float(lo[k2])
		if real_d > 0.0:
			bs[k2] = float(bs[k2]) - real_d * room / maxf(others, 0.0001)
		else:
			bs[k2] = float(bs[k2]) - real_d * float(bs[k2]) / maxf(1.0 - float(bs[k]), 0.0001)
	bs[k] = nv
	var s := 0.0
	for k3 in AR_BS_KEYS:
		s += float(bs[k3])
	for k4 in AR_BS_KEYS:
		bs[k4] = float(bs[k4]) / s
	return ""


func ar_svc_check(m: String) -> String:
	if not ar_on():
		return "Армии нет."
	if opp_mode:
		return "В оппозиции законы о военной службе принимает правительство."
	if String(ar["svc"]) == m:
		return "Уже действует."
	if int(ar["svc_cd"]) > 0:
		return "Модель комплектования меняли недавно: ещё %d мес." % int(ar["svc_cd"])
	if capital < 8.0:
		return "Нужно 8 политического капитала."
	var dm := fed_dom(false)
	if not bool(dm["ok"]):
		return "Закон о военной службе требует большинства в парламенте. " + String(dm["text"])
	return ""


func ar_set_svc(m: String) -> bool:
	if ar_svc_check(m) != "":
		return false
	var old := String(ar["svc"])
	capital -= 8.0
	ar["svc"] = m
	ar["svc_cd"] = 36
	var up: int = ["pro", "mix", "con"].find(m) - ["pro", "mix", "con"].find(old)
	add_support("Молодёжь", -2.0 * float(up))
	add_support("Силовики", 1.0 * float(up))
	recompute_mods()
	ar_log("принят закон о военной службе: «%s». Резерв будет меняться несколько лет, по мере смены призывных когорт." % String(AR_SVC[m]["n"]), COL_TEAL)
	return true


# территориальная оборона: бригада добровольцев (1% мужчин призывного возраста — ≈0,1% населения)
func ar_td_check() -> String:
	if not ar_on():
		return "Армии нет."
	if opp_mode:
		return "В оппозиции армией командует правительство."
	if capital < 2.0:
		return "Нужно 2 политического капитала."
	if float(ar["td"]) >= total_pop() * 1000.0 * 0.004:
		return "Добровольцев больше нет: все желающие уже в территориальной обороне."
	return ""


func ar_td_form() -> bool:
	if ar_td_check() != "":
		return false
	capital -= 2.0
	var sz: float = clampf(total_pop() * 1000.0 * 0.0008, 0.5, 6.0)
	ar["td"] = float(ar["td"]) + sz
	debt += sz * 0.004
	var sp := mil_home_spots(ccode, 4)
	var f := mil_new_unit(ccode, sz, mil_q(ccode) * 0.75, int(sp[mil_rng.randi() % sp.size()]), "res", "td")
	f["mode"] = "def" if mil_at_war() else "hold"
	add_support("Силовики", 0.5)
	ar_log("сформирована %s (%.1f тыс. добровольцев)." % [String(f["nm"]), sz], COL_TEAL)
	return true


func ar_ammo_price(amt: float) -> float:
	# ≈10 млн € за месяц боёв на тысячу бойцов
	return amt * maxf(2.0, mil_cap()) * 0.01 * ind_arms_price()


func ar_buy_check() -> String:
	if not ar_on():
		return "Армии нет."
	if opp_mode:
		return "В оппозиции закупками занимается правительство."
	if ar_cd("buy") > 0:
		return "Поставщики заняты прошлым заказом: ещё %d мес." % ar_cd("buy")
	if capital < 2.0:
		return "Нужно 2 политического капитала."
	if fa_eu_sanc():
		return "Под санкциями ЕС никто не продаёт вам боеприпасы."
	return ""


func ar_buy_ammo() -> bool:
	if ar_buy_check() != "":
		return false
	var amt := 0.3
	capital -= 2.0
	debt += ar_ammo_price(amt)
	(ar["cd"] as Dictionary)["buy"] = 2
	var m: int = 1 if mil_is_nato(ccode) else 2
	(ar["pq"] as Array).append({"amt": amt, "m": m})
	ar_log("заказаны боеприпасы у союзников: +%.1f мес. боёв за %.2f млрд €, поставка через %d мес." % [amt, ar_ammo_price(amt), m], COL_TEAL)
	return true


func ar_wecon_check() -> String:
	if not ar_on():
		return "Армии нет."
	if opp_mode:
		return "В оппозиции экономикой управляет правительство."
	if bool(ar["wecon"]):
		return ""
	if not mil_at_war() and int(mil["mob"]) < 2:
		return "Военная экономика — только во время войны или всеобщей мобилизации."
	if capital < 4.0:
		return "Нужно 4 политического капитала."
	return ""


func ar_wecon_toggle() -> bool:
	if ar_wecon_check() != "":
		return false
	if bool(ar["wecon"]):
		ar["wecon"] = false
		ar_log("промышленность возвращается к мирной продукции.", COL_GOOD)
		return true
	capital -= 4.0
	ar["wecon"] = true
	add_support("Бизнес", -2.0)
	add_support("Рабочие", 1.0)
	ar_log("[b]промышленность переведена на военные рельсы[/b]: выпуск боеприпасов втрое больше, но экономика растёт медленнее и цены выше.", COL_WARN)
	return true


# ---------------- программы закупок ----------------


func ar_prog_info(id: String) -> Dictionary:
	for p in AR_PROG:
		if String(p["id"]) == id:
			return p
	return {}


func ar_prog_cost(id: String) -> float:
	var p := ar_prog_info(id)
	if p.is_empty():
		return 0.0
	var c: float = float(p["cost"])
	if c < 0.0:
		c = ar_ammo_price(float(p["fx"].get("ammo", 0.5)))
	# чем больше обычный бюджет тратит на технику, тем меньше нужно сверху
	return c * clampf(1.0 - 0.8 * (ar_bs("eq") - 0.25), 0.8, 1.15)


func ar_prog_running(id: String) -> int:
	var n := 0
	for q in ar.get("prog", []):
		if String(q["id"]) == id:
			n += 1
	return n


func ar_prog_check(id: String) -> String:
	if not ar_on():
		return "Армии нет."
	if opp_mode:
		return "В оппозиции закупками занимается правительство."
	var p := ar_prog_info(id)
	if p.is_empty():
		return "Нет такой программы."
	if (ar["prog"] as Array).size() >= 4:
		return "Уже идут 4 программы: оборонное ведомство не потянет больше."
	if ar_prog_running(id) > 0:
		return "Эта программа уже идёт."
	if p.has("tech") and not tech_done(String(p["tech"])):
		return "Нужна технология «%s»." % String(tech_def(String(p["tech"])).get("name", p["tech"]))
	if String(p["fx"].get("conv", "")) != "" and ar_inf_units().is_empty():
		return "Нет мотопехотных соединений для перевооружения."
	if capital < 2.0:
		return "Нужно 2 политического капитала."
	if fa_eu_sanc() and id in ["fighter5", "sam_l"]:
		return "Под санкциями ЕС такие системы вам не продадут."
	if ar_prog_cost(id) > gdp * 0.02:
		return "Слишком дорого для экономики страны: %.1f млрд € — больше 2%% ВВП." % ar_prog_cost(id)
	return ""


func ar_prog_start(id: String) -> bool:
	if ar_prog_check(id) != "":
		return false
	var p := ar_prog_info(id)
	var c := ar_prog_cost(id)
	capital -= 2.0
	(ar["prog"] as Array).append({"id": id, "left": int(p["m"]), "m": int(p["m"]), "pay": c / float(p["m"]), "cost": c})
	add_support("Силовики", 1.0)
	ar_log("запущена программа «%s»: %.2f млрд €, поставка через %d мес." % [String(p["n"]), c, int(p["m"])], COL_TEAL)
	return true


func ar_inf_units() -> Array:
	var out: Array = []
	for f in mil_units_of(ccode):
		if String(f["kind"]) == "reg" and ar_tp(f) == "inf":
			out.append(f)
	return out


func ar_prog_month() -> void:
	var pr: Array = ar["prog"]
	for i in range(pr.size() - 1, -1, -1):
		var q: Dictionary = pr[i]
		debt += float(q["pay"])
		q["left"] = int(q["left"]) - 1
		if int(q["left"]) > 0:
			continue
		var p := ar_prog_info(String(q["id"]))
		var fx: Dictionary = p.get("fx", {})
		for k in fx:
			match String(k):
				"air", "ad", "art_k", "lgt_k", "ind":
					ar[k] = float(ar[k]) + float(fx[k])
				"eq":
					ar["eq_add"] = float(ar["eq_add"]) + float(fx[k])
				"drone":
					ar["drone"] = int(ar["drone"]) + int(fx[k])
				"ammo":
					ar["ammo"] = float(ar["ammo"]) + float(fx[k])
				"conv":
					var inf := ar_inf_units()
					if not inf.is_empty():
						var f: Dictionary = inf[0]
						f["tp"] = String(fx[k])
						f["nm"] = String(f["nm"]).replace(String(AR_INFO["inf"]["n"]), String(ar_info(String(fx[k]))["n"]))
					else:
						ar["eq_add"] = float(ar["eq_add"]) + 0.02
		(ar["done"] as Dictionary)[String(q["id"])] = int((ar["done"] as Dictionary).get(String(q["id"]), 0)) + 1
		ar_log("[b]поставка завершена[/b]: «%s»." % String(p["n"]), COL_GOOD)
		pr.remove_at(i)


# ---------------- учения ----------------


func ar_ex_check(kind: String, target: String = "") -> String:
	if not ar_on():
		return "Армии нет."
	if opp_mode:
		return "В оппозиции армией командует правительство."
	if mil_at_war():
		return "Во время войны не до учений."
	if ar_cd("ex") > 0:
		return "Войска ещё не отдохнули после прошлых учений: %d мес." % ar_cd("ex")
	var need := {"plan": 2.0, "border": 3.0, "allied": 3.0}
	if capital < float(need.get(kind, 2.0)):
		return "Нужно %.0f политического капитала." % float(need.get(kind, 2.0))
	if kind == "border" and (target == "" or not (target in mil_targets())):
		return "Выберите соседа."
	if kind == "allied" and not mil_is_nato(ccode) and ar_defense_partners().is_empty():
		return "Нет союзников: нужно НАТО или оборонный договор."
	return ""


func ar_defense_partners() -> Array:
	var out: Array = []
	if not dx_on():
		return out
	for c in fa_bots():
		if dx_has_treaty(String(c), "defense"):
			out.append(String(c))
	return out


func ar_exercise(kind: String, target: String = "") -> bool:
	if ar_ex_check(kind, target) != "":
		return false
	var cost: float = gdp * 0.0002
	debt += cost
	(ar["cd"] as Dictionary)["ex"] = 4
	match kind:
		"plan":
			capital -= 2.0
			ar["rdx"] = float(ar["rdx"]) + 6.0
			ar_log("прошли плановые учения: готовность войск выше.", COL_TEAL)
		"border":
			capital -= 3.0
			ar["rdx"] = float(ar["rdx"]) + 6.0
			(ar["deter"] as Dictionary)[target] = 12
			ex_rel_change(target, -4.0)
			if fa_on():
				fa_hit(target, -4.0, "военные учения у границы")
			add_support("Силовики", 1.5)
			ar_log("учения у границы с «%s»: сосед раздражён, но нападать на вас теперь опаснее." % String(WORLD[target]["name"]), COL_WARN)
			if fa_on() and float(fa_pers(target)["hawk"]) >= 0.5:
				var wm: Dictionary = ar["wm"]
				wm[target] = float(wm.get(target, 1.0)) + 0.05
				ar_log("«%s» отвечает своими учениями и стягивает войска к границе." % String(WORLD[target]["name"]), COL_WARN)
		"allied":
			capital -= 3.0
			ar["rdx"] = float(ar["rdx"]) + 8.0
			ar["xp"] = minf(0.04, float(ar["xp"]) + 0.004)
			var ps: Array = []
			if mil_is_nato(ccode):
				for c in fa_bots():
					if mil_is_nato(String(c)):
						ps.append(String(c))
			else:
				ps = ar_defense_partners()
			for c2 in ps:
				ex_rel_change(String(c2), 1.5)
			ar_log("совместные учения с союзниками: готовность и слаженность выше, союзники довольны.", COL_GOOD)
	return true


# ---------------- миротворческие миссии ----------------


func ar_mis_info(id: String) -> Dictionary:
	for m in AR_MIS:
		if String(m["id"]) == id:
			return m
	return {}


func ar_mis_check(id: String) -> String:
	if not ar_on():
		return "Армии нет."
	if opp_mode:
		return "В оппозиции армией командует правительство."
	if String(ar["mis"]) == id:
		return ""
	if String(ar["mis"]) != "":
		return "Сначала верните войска из нынешней миссии."
	if mil_at_war():
		return "Во время войны войска нужны дома."
	var m := ar_mis_info(id)
	if String(m["req"]) == "eu" and not bool(WORLD.get(ccode, {}).get("eu", false)):
		return "Только для стран ЕС."
	if String(m["req"]) == "nato" and not mil_is_nato(ccode):
		return "Только для членов НАТО."
	if mil_cap() < float(m["k"]) * 4.0:
		return "Армия слишком мала для такой миссии."
	if capital < 2.0:
		return "Нужно 2 политического капитала."
	return ""


func ar_mis_toggle(id: String) -> bool:
	if ar_mis_check(id) != "":
		return false
	var m := ar_mis_info(id)
	if String(ar["mis"]) == id:
		ar["mis"] = ""
		ar_log("контингент «%s» вернулся домой." % String(m["n"]), COL_GOOD)
		return true
	capital -= 2.0
	ar["mis"] = id
	ar["mis_t"] = 0
	ar_log("отправлен контингент: «%s» (%.1f тыс. военных)." % [String(m["n"]), float(m["k"])], COL_TEAL)
	return true


func ar_mis_month() -> void:
	var id := String(ar["mis"])
	if id == "":
		return
	if mil_at_war():
		ar["mis"] = ""
		ar_log("из-за войны контингент отозван из миссии.", COL_WARN)
		return
	var m := ar_mis_info(id)
	ar["mis_t"] = int(ar["mis_t"]) + 1
	debt += float(m["k"]) * 0.008
	ar["xp"] = minf(0.04, float(ar["xp"]) + 0.001)
	if int(ar["mis_t"]) % 6 == 0:
		for c in fa_bots():
			var ok: bool = id == "un" or (id == "eu" and bool(WORLD.get(c, {}).get("eu", false))) or (id == "nato" and mil_is_nato(String(c)))
			if ok:
				ex_rel_change(String(c), 0.6 if id == "un" else 1.0)
		capital += 0.5
	if mil_rng.randf() < 0.012:
		add_support("Пенсионеры", -1.0)
		add_support("Молодёжь", -1.0)
		ar_log("в миссии «%s» погибли наши военные. Общество скорбит; оппозиция требует вернуть контингент." % String(m["n"]), COL_BAD)


# ---------------- экспорт оружия ----------------


func ar_exp_check(lv: int) -> String:
	if not ar_on():
		return "Армии нет."
	if opp_mode:
		return "В оппозиции экспортом оружия управляет правительство."
	if int(ar["exp"]) == lv:
		return "Уже действует."
	if ar_cd("exp") > 0:
		return "Правила экспорта меняли недавно: ещё %d мес." % ar_cd("exp")
	if capital < 3.0:
		return "Нужно 3 политического капитала."
	return ""


func ar_set_exp(lv: int) -> bool:
	if ar_exp_check(lv) != "":
		return false
	capital -= 3.0
	ar["exp"] = lv
	(ar["cd"] as Dictionary)["exp"] = 12
	recompute_mods()
	if lv == 2 and fa_on():
		for c in fa_bots():
			if float(fa_pers(String(c))["values"]) >= 0.7:
				fa_hit(String(c), -1.0, "торговля оружием без разбора")
	ar_log(["экспорт оружия запрещён: промышленность теряет заказы.", "экспорт оружия — только союзникам и партнёрам.", "разрешён активный экспорт оружия: заводы загружены, но правозащитники недовольны."][lv], COL_TEAL)
	return true


# доход от экспорта (млрд € в год) — разница с обычным режимом
func ar_exp_rev() -> float:
	if ar.is_empty():
		return 0.0
	var e: int = int(ar["exp"])
	if e == 1:
		return 0.0
	return gdp * (0.0005 if e == 2 else -0.0003) * (0.5 + float(ar["ind"]))


func ar_exp_month() -> void:
	var e: int = int(ar["exp"])
	if e == 1:
		return
	debt -= ar_exp_rev() / 12.0
	# активный экспорт загружает заводы и растит выпуск, запрет — сокращает
	var ind_t: float = float(ar["ind0"]) + (0.15 if e == 2 else -0.1) + float((ar["done"] as Dictionary).get("ammo_plant", 0)) * 0.3
	ar["ind"] = maxf(0.0, float(ar["ind"]) + (ind_t - float(ar["ind"])) * 0.03)


# ============================================================
#  СВОДКИ
# ============================================================


func ar_nato_pct() -> float:
	return float(pol.get("army", 1.0))


func ar_comp() -> Dictionary:
	var out := {}
	for tp in AR_TYPES:
		out[tp] = 0.0
	for f in mil_units_of(ccode):
		var tp := ar_tp(f)
		out[tp] = float(out.get(tp, 0.0)) + float(f["str"])
	return out


func ar_rival_rows() -> Array:
	# соседи и крупные армии: [страна, сила, отношение, тренд]
	var rows: Array = []
	var seen := {}
	for c in tech_nb():
		if MIL_BASE.has(c) and c != ccode:
			seen[c] = true
	for c2 in ["DE", "FR", "GB", "PL", "IT"]:
		if c2 != ccode and MIL_BASE.has(c2):
			seen[c2] = true
	for c3 in seen:
		rows.append([String(c3), mil_country_power(String(c3)), fed_rel(String(c3)), float((ar["wmt"] as Dictionary).get(c3, 1.0)) - ar_wm(String(c3))])
	rows.sort_custom(func(x, y) -> bool: return float(x[1]) > float(y[1]))
	return rows
