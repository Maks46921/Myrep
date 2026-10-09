# Помощники для данных Косова: общие функции берём у Ирландии (ie_lib), переопределяем раскладку слотов партий,
# спецминистерства и требования для архетипов, которых нет в ie_lib.
from ie_lib import GROUPS, g, V, T, calibrate, TRAITS, MIN_BASE, numtxt
import ie_lib as _ie

# Слоты Косова:
# 0 «Самоопределение» (own)  1 ДПК (cons)  2 ДСК (lib)  3 АБК (popr)  4 «Инициатива» Лимая (soc)
# 5 партии неалбанских общин — турки, боснийцы, горанцы, рома, ашкали, египтяне (euro)  6 прочие (oth)
# 7 сербская партия Рашича «За свободу, справедливость и выживание» (soc)  8 «Сербский список» (region)  9 национал-радикалы (prot)
SLOT_KEY = ["own", "pdk", "ldk", "aak", "nis", "min", "oth", "spo", "sl", "prot"]
SLOT_ARCH = ["own", "cons", "lib", "popr", "soc", "euro", "none", "soc", "region", "none"]
ARCHS = ["own", "cons", "lib", "popr", "soc", "euro", "oth", "soc", "region", "prot"]


def p(**kw):
    """реакции партий Косова: p(own=.., pdk=.., ldk=.., aak=.., nis=.., min=.., oth=.., spo=.., sl=.., prot=..) -> {слот: значение}"""
    out = {}
    for s, k in enumerate(SLOT_KEY):
        if k in kw:
            out[s] = float(kw[k])
    for k, v in kw.items():
        if k.isdigit():
            out[int(k)] = float(v)
    return out


ARCH_SPECIAL = dict(_ie.ARCH_SPECIAL)
ARCH_SPECIAL["lib"] = [(0, {"a": {"eff_bonus": 0.007, "growth_bonus": 0.03}}, "Либеральные финансы"),
                       (11, {"a": {"growth_bonus": 0.04, "dip_bonus": 1.5, "mood_shift": 0.1}}, "Примирение с Западом"),
                       (10, {"a": {"corr_shift": -2.5}}, "Правовое государство")]
ARCH_SPECIAL["euro"] = [(8, {"a": {"reg_dev_bonus": 1.5, "reg_unrest_shift": -1.5, "eff_bonus": -0.002}}, "Развитие общин"),
                        (4, {"x": {"edu_eff": 1.03}, "a": {"reg_unrest_shift": -1.0}}, "Школы на языках общин")]
ARCH_SPECIAL["region"] = [(8, {"a": {"reg_dev_bonus": 2.0, "reg_unrest_shift": -2.5, "auto_shift": 5.0, "eff_bonus": -0.004}}, "Сербские общины"),
                          (6, {"a": {"gb_Село": 2.0, "reg_unrest_shift": -1.0}}, "Сербские сёла и монастырские земли")]
ARCH_SPECIAL["popr"] = [(1, {"a": {"sec_bonus": 3.0, "gb_Силовики": 2.0}}, "Ветеран АОК в обороне"),
                        (2, {"a": {"sec_bonus": 2.5, "reg_unrest_shift": -1.5, "mood_shift": -0.2, "gb_Силовики": 1.5}}, "Жёсткий порядок")]
ARCH_DEMANDS = dict(_ie.ARCH_DEMANDS)
ARCH_DEMANDS["lib"] = [("edu", ">=", 1.03, True, "образование и наука"), ("admin", "<=", 0.97, True, "госаппарат")]
ARCH_DEMANDS["euro"] = [("benefits", ">=", 0.98, True, "соцпомощь (общины рома, ашкали и египтян)")]
ARCH_DEMANDS["region"] = [("subs", ">=", 0.98, True, "субсидии (сербские общины на севере)")]
ARCH_DEMANDS["popr"] = [("army", ">=", 1.05, True, "Силы безопасности Косова"), ("pensions", ">=", 0.98, True, "пенсии ветеранов")]


def demands_list(arch, P, gdp):
    out = []
    for key, op, k, ab, nm in ARCH_DEMANDS.get(arch, []):
        d = P[key]
        val = round(d * k * gdp / 100.0, 2)
        out.append({"key": key, "op": op, "val": float(val), "abs": True,
                    "text": "%s %s %s млрд € в год" % (nm, "не ниже" if op == ">=" else "не выше", numtxt(val))})
    return out


def min_special(slot_archs):
    out = {}
    for s, a in enumerate(slot_archs):
        for (m, spec, title) in ARCH_SPECIAL.get(a, []):
            d = dict(spec); d["t"] = title
            out["%d:%d" % (m, s)] = d
    return out
