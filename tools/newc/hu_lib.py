# Помощники для данных Венгрии: всё общее берётся из ie_lib, переопределены только слоты партий (p) и калибровка
# (у «Тисы» в 2022 году не было списка, поэтому её региональный профиль для калибровки берётся из выборов в ЕП 2024).
import ie_lib
from ie_lib import GROUPS, g, V, T, TRAITS, MIN_BASE, ARCH_SPECIAL, ARCH_DEMANDS, numtxt, _norm

# слоты Венгрии: 0 Фидес–ХДНП(own) 1 Наша Родина(popr) 2 ДК(soc) 3 MSZP(left) 4 LMP и Диалог(green) 5 Моментум(lib)
#                6 прочие: Партия двухвостой собаки и независимые(oth) 7 Йоббик(cons) 8 национальности и местные(region) 9 Тиса(prot)
SLOT_KEY = ["own", "popr", "soc", "left", "green", "lib", "oth", "cons", "region", "prot"]

# у либералов (Моментум) в ie_lib нет спецминистерств и требований — добавим
ARCH_SPECIAL = dict(ARCH_SPECIAL)
ARCH_SPECIAL["lib"] = [(10, {"a": {"corr_shift": -3.5, "gb_Молодёжь": 1.0, "dem_shift": 0.02}}, "Правовое государство"),
                       (4, {"x": {"edu_eff": 1.08}, "a": {"gb_Молодёжь": 1.5}}, "Свободные университеты"),
                       (11, {"a": {"growth_bonus": 0.04, "dip_bonus": 1.5, "mood_shift": 0.1}}, "Возвращение в Европу")]
ARCH_DEMANDS = dict(ARCH_DEMANDS)
ARCH_DEMANDS["lib"] = [("edu", ">=", 1.06, True, "образование и наука"), ("subs", "<=", 0.90, True, "субсидии бизнесу")]
ARCH_DEMANDS["popr"] = [("police", ">=", 1.08, True, "полиция и охрана границы"), ("army", ">=", 1.05, True, "армия")]


def p(**kw):
    out = {}
    for s, k in enumerate(SLOT_KEY):
        if k in kw:
            out[s] = float(kw[k])
    for k, v in kw.items():
        if k.isdigit():
            out[int(k)] = float(v)
    return out


def calibrate(C):
    """как ie_lib.calibrate, но с поправленным профилем «Тисы» (r['Ecal'] вместо r['E'], если задан)."""
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
