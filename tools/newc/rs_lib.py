# Помощники для данных Сербии: общие функции берутся из ie_lib, переопределены слоты партий, калибровка (профиль «Студенческого списка»)
# и спецминистерства/требования либералов (ССП).
import ie_lib
from ie_lib import GROUPS, g, V, T, TRAITS, MIN_BASE, ARCH_SPECIAL, ARCH_DEMANDS, numtxt, _norm

# слоты Сербии: 0 СНС и союзники(own) 1 СПС–ЕС(soc) 2 ССП(lib) 3 ЗЛФ и Экологическое восстание(green) 4 НАДА(cons)
#               5 Мы — Голос народа(popr) 6 прочая оппозиция: НДС, СРЦЕ и др.(oth) 7 Демократическая партия(left)
#               8 партии национальных меньшинств(region) 9 Студенческий список(prot)
SLOT_KEY = ["own", "soc", "lib", "green", "cons", "popr", "oth", "left", "region", "prot"]

ARCH_SPECIAL = dict(ARCH_SPECIAL)
ARCH_SPECIAL["lib"] = [(10, {"a": {"corr_shift": -3.5, "gb_Молодёжь": 1.0, "dem_shift": 0.02}}, "Правовое государство"),
                       (0, {"a": {"eff_bonus": 0.006, "growth_bonus": 0.03}}, "Прозрачные финансы"),
                       (11, {"a": {"growth_bonus": 0.04, "dip_bonus": 1.5, "mood_shift": 0.1}}, "Европейский курс без оговорок")]
ARCH_SPECIAL["region"] = [(6, {"a": {"gb_Село": 3.0, "reg_unrest_shift": -1.0, "eff_bonus": -0.003}}, "Аграрный лоббист Воеводины"),
                          (8, {"a": {"reg_dev_bonus": 2.0, "reg_unrest_shift": -2.0, "auto_shift": 3.0, "eff_bonus": -0.003}}, "Деньги для общин меньшинств")]
ARCH_DEMANDS = dict(ARCH_DEMANDS)
ARCH_DEMANDS["lib"] = [("edu", ">=", 1.06, True, "образование и наука"), ("subs", "<=", 0.92, True, "субсидии и госинвестиции без тендеров")]
ARCH_DEMANDS["popr"] = [("health", ">=", 1.06, True, "здравоохранение"), ("subs", ">=", 1.0, True, "поддержка отечественных производителей")]
ARCH_DEMANDS["region"] = [("subs", ">=", 0.96, True, "субсидии аграриям"), ("edu", ">=", 0.98, True, "школы на языках меньшинств")]


def p(**kw):
    """реакции партий по архетипам Сербии -> {слот: значение}"""
    out = {}
    for s, k in enumerate(SLOT_KEY):
        if k in kw:
            out[s] = float(kw[k])
    for k, v in kw.items():
        if k.isdigit():
            out[int(k)] = float(v)
    return out


def calibrate(C):
    """как ie_lib.calibrate, но с профилем «Студенческого списка» (r['Ecal'] вместо r['E'], если задан): в 2023 году его не было."""
    saved = []
    for r in C["regions"]:
        saved.append(r["E"])
        if r.get("Ecal"):
            r["E"] = r["Ecal"]
    try:
        return ie_lib.calibrate(C)
    finally:
        for r, e in zip(C["regions"], saved):
            r["E"] = e


def demands_list(arch, P, gdp):
    out = []
    for key, op, k, ab, nm in ARCH_DEMANDS.get(arch, []):
        d = P[key]
        val = round(d * k * gdp / 100.0, 1)
        out.append({"key": key, "op": op, "val": float(val), "abs": True, "text": "%s %s %s млрд € в год" % (nm, "не ниже" if op == ">=" else "не выше", numtxt(val))})
    return out


def min_special(slot_archs):
    out = {}
    for s, a in enumerate(slot_archs):
        for (m, spec, title) in ARCH_SPECIAL.get(a, []):
            d = dict(spec); d["t"] = title
            out["%d:%d" % (m, s)] = d
    return out
