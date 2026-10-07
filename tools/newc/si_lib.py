# Помощники для данных Словении: берём общие функции у Ирландии (ie_lib) и переопределяем раскладку слотов партий.
from ie_lib import GROUPS, g, V, T, calibrate, TRAITS, MIN_BASE, numtxt
import ie_lib as _ie

# Слоты Словении: 0 GS (own) 1 SD (soc) 2 Левица (left) 3 Весна (green) 4 NSi–SLS–Фокус (cons) 5 SDS (popr)
# 6 прочие (oth) 7 Демократы Логара (lib) 8 национальные общины (region) 9 Resni.ca (prot)
SLOT_KEY = ["own", "soc", "left", "green", "cons", "popr", "oth", "lib", "region", "prot"]


def p(**kw):
    """реакции партий по архетипам Словении -> {слот: значение}"""
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
                       (5, {"a": {"growth_bonus": 0.06, "gb_Бизнес": 1.5}}, "Предпринимательская экономика"),
                       (10, {"a": {"corr_shift": -2.5}}, "Правовое государство")]
ARCH_SPECIAL["region"] = [(4, {"x": {"edu_eff": 1.03}, "a": {"reg_unrest_shift": -1.0}}, "Школы национальных общин"),
                          (8, {"a": {"reg_dev_bonus": 2.0, "reg_unrest_shift": -1.5, "auto_shift": 3.0, "eff_bonus": -0.003}}, "Интересы приграничья")]
ARCH_DEMANDS = dict(_ie.ARCH_DEMANDS)
ARCH_DEMANDS["lib"] = [("admin", "<=", 0.95, True, "госаппарат"), ("edu", ">=", 1.03, True, "образование и наука")]
ARCH_DEMANDS["region"] = [("edu", ">=", 0.98, True, "образование (школы общин)")]


def demands_list(arch, P, gdp):
    out = []
    for key, op, k, ab, nm in ARCH_DEMANDS.get(arch, []):
        d = P[key]
        val = round(d * k * gdp / 100.0, 1)
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
