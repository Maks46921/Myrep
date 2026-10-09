# Помощники для данных Латвии: общие функции из ie_lib (V, T, g, calibrate, TRAITS, MIN_BASE, numtxt) и раскладка слотов партий Латвии.
import ie_lib
from ie_lib import GROUPS, g, V, T, calibrate, TRAITS, MIN_BASE, numtxt  # noqa: F401

# Слоты Латвии (январь 2026):
# 0 «Новое Единство» JV (own)  1 Союз зелёных и крестьян ZZS (cons)  2 «Прогрессивные» (soc)  3 Объединённый список AS (lib)
# 4 Национальное объединение NA (popr)  5 «За стабильность!» (popl)  6 прочие и внефракционные (oth)
# 7 «Согласие» (left)  8 «Суверенная власть» (region — суверенисты, Латгале и русскоязычная Рига)  9 «Латвия на первом месте» LPV (prot)
SLOT_KEY = ["own", "zzs", "pro", "as_", "na", "stab", "oth", "sask", "sv", "lpv"]
SLOT_ARCH = ["own", "cons", "soc", "lib", "popr", "popl", "none", "left", "region", "none"]
ARCHS = ["own", "cons", "soc", "lib", "popr", "popl", "oth", "left", "region", "prot"]


def p(**kw):
    """реакции партий Латвии: p(own=, zzs=, pro=, as_=, na=, stab=, oth=, sask=, sv=, lpv=) -> {слот: значение}"""
    out = {}
    for s, k in enumerate(SLOT_KEY):
        if k in kw:
            out[s] = float(kw[k])
    for k, v in kw.items():
        if k.isdigit():
            out[int(k)] = float(v)
    return out


# особые министры по слотам: (министерство, эффект, название)
SLOT_SPECIAL = {
    1: [(6, {"a": {"gb_Село": 3.0, "reg_unrest_shift": -0.8, "eff_bonus": -0.002}}, "Крестьянский министр"),
        (5, {"a": {"growth_bonus": 0.05, "gb_Бизнес": 1.0, "reg_dev_bonus": 1.0}}, "Порты и региональная экономика"),
        (7, {"x": {"env_eff": 1.05}, "a": {"growth_bonus": 0.02, "gb_Экологи": -0.5}}, "Энергетика без лишних мечтаний"),
        (9, {"a": {"equal_shift": 1.5, "gb_Пенсионеры": 2.0}}, "Пенсии и сельская соцподдержка")],
    2: [(9, {"a": {"equal_shift": 3.0, "gb_Рабочие": 1.5, "growth_bonus": -0.03}}, "Социальное государство"),
        (1, {"a": {"sec_bonus": 2.5, "gb_Силовики": 1.0}}, "Оборонный рывок"),
        (8, {"a": {"reg_dev_bonus": 1.5, "gb_Молодёжь": 1.0}, "x": {"env_eff": 1.03}}, "Общественный транспорт и Rail Baltica"),
        (3, {"x": {"health_eff": 1.07}, "a": {"extra_spend": 0.08}}, "Медицина для всех")],
    3: [(0, {"a": {"eff_bonus": 0.007, "growth_bonus": 0.03, "gb_Бизнес": 1.0}}, "Предпринимательские финансы"),
        (5, {"a": {"growth_bonus": 0.07, "gb_Бизнес": 1.5}}, "Экономика без бюрократии"),
        (8, {"a": {"reg_dev_bonus": 2.0, "reg_unrest_shift": -1.0}}, "Курземе и малые города")],
    4: [(4, {"x": {"edu_eff": 1.03}, "a": {"gb_Молодёжь": -0.5, "reg_unrest_shift": 0.5, "mood_shift": -0.1}}, "Школа только на латышском"),
        (2, {"a": {"sec_bonus": 2.5, "gb_Силовики": 1.5, "mood_shift": -0.2}}, "Граница на замке"),
        (10, {"a": {"corr_shift": -1.5, "gb_Силовики": 0.5}}, "Национальное правосудие")],
    5: [(9, {"a": {"equal_shift": 2.0, "gb_Пенсионеры": 2.0, "growth_bonus": -0.03}}, "Социальный популизм")],
    7: [(9, {"a": {"equal_shift": 3.0, "gb_Рабочие": 1.5}}, "Социал-демократия «Согласия»")],
    8: [(8, {"a": {"reg_dev_bonus": 2.5, "reg_unrest_shift": -2.0, "auto_shift": 3.0, "eff_bonus": -0.004}}, "Интересы Латгале и русскоязычных"),
        (4, {"x": {"edu_eff": 0.98}, "a": {"reg_unrest_shift": -1.5, "mood_shift": 0.1}}, "Школы меньшинств под защитой")],
    9: [(5, {"a": {"growth_bonus": 0.06, "gb_Бизнес": 2.0, "eff_bonus": -0.003}}, "«Латвийский бизнес прежде всего»"),
        (0, {"a": {"eff_bonus": -0.002, "equal_shift": -1.0, "gb_Бизнес": 1.5, "growth_bonus": 0.03}}, "Низкие налоги Шлесерса"),
        (9, {"a": {"equal_shift": 1.5, "gb_Пенсионеры": 2.0, "growth_bonus": -0.02}}, "Пенсии и «традиционная семья»")],
}

SLOT_DEMANDS = {
    1: [("subs", ">=", 1.0, "субсидии аграриям и регионам"), ("pensions", ">=", 0.98, "пенсии")],
    2: [("benefits", ">=", 1.04, "пособия и соцпомощь"), ("health", ">=", 1.04, "здравоохранение")],
    3: [("admin", "<=", 0.97, "госаппарат"), ("infra", ">=", 1.0, "дороги и инфраструктура")],
    4: [("army", ">=", 1.0, "оборона"), ("police", ">=", 1.03, "полиция и пограничники")],
    5: [("pensions", ">=", 1.05, "пенсии"), ("benefits", ">=", 1.05, "пособия")],
    7: [("benefits", ">=", 1.08, "пособия"), ("health", ">=", 1.06, "здравоохранение")],
    8: [("subs", ">=", 1.05, "субсидии Латгале")],
    9: [("income", "<=", 0.95, "подоходный налог"), ("pensions", ">=", 1.03, "пенсии")],
}


def demands_lv(slot, P, gdp):
    out = []
    for key, op, k, nm in SLOT_DEMANDS.get(slot, []):
        val = round(P[key] * k * gdp / 100.0, 2)
        out.append({"key": key, "op": op, "val": float(val), "abs": True,
                    "text": "%s %s %s млрд € в год" % (nm, "не ниже" if op == ">=" else "не выше", ("%.2f" % val).rstrip("0").rstrip(".").replace(".", ","))})
    return out


def min_special_lv():
    out = {}
    for s, lst in SLOT_SPECIAL.items():
        for (m, spec, title) in lst:
            d = dict(spec); d["t"] = title
            out["%d:%d" % (m, s)] = d
    return out
