# Помощники для данных Словакии: берём всё из ie_lib (V, T, g, calibrate, TRAITS, MIN_BASE ...)
# и переопределяем то, что зависит от раскладки слотов и архетипов партий Словакии.
import ie_lib
from ie_lib import *   # noqa: F401,F403

# Слоты Словакии: 0 Смер-СД(own) 1 Глас-СД(soc) 2 Прогрессивная Словакия(euro) 3 SaS(lib) 4 KDH(cons)
# 5 Движение Словакия(popl) 6 прочие(oth) 7 СНС(popr) 8 Венгерский альянс(region) 9 Республика(prot)
SLOT_KEY = ["own", "soc", "euro", "lib", "cons", "popl", "oth", "popr", "region", "prot"]


def p(**kw):
    """реакции партий по архетипам (own, soc, euro, lib, cons, popl, oth, popr, region, prot); числовые ключи — слоты"""
    out = {}
    for s, k in enumerate(SLOT_KEY):
        if k in kw:
            out[s] = float(kw[k])
    for k, v in kw.items():
        if k.isdigit():
            out[int(k)] = float(v)
    return out


ARCH_SPECIAL = dict(ie_lib.ARCH_SPECIAL)
ARCH_SPECIAL.update({
    "lib": [(0, {"a": {"eff_bonus": 0.012, "equal_shift": -1.0}, "x": {"admin_mult": 0.97}}, "Бережливый финансист"),
            (5, {"a": {"growth_bonus": 0.18, "equal_shift": -1.0, "gb_Рабочие": -1.0, "gb_Бизнес": 2.0}}, "Либеральная экономика"),
            (11, {"a": {"growth_bonus": 0.10, "gb_Бизнес": 2.0, "dip_bonus": 1.0}}, "Открытая торговля")],
    "euro": [(4, {"x": {"edu_eff": 1.10}, "a": {"gb_Молодёжь": 2.5, "corr_shift": -1.0, "gb_Пенсионеры": -1.0}}, "Цифровое образование"),
             (11, {"a": {"growth_bonus": 0.06, "mood_shift": 0.2, "dip_bonus": 2.0}}, "Проевропейский курс"),
             (10, {"a": {"corr_shift": -3.0, "gb_Молодёжь": 1.0}}, "Правовое государство")],
    "popl": [(10, {"a": {"corr_shift": -2.5, "gb_Пенсионеры": 0.5, "eff_bonus": -0.002}}, "Борьба с «мафией»"),
             (2, {"a": {"sec_bonus": 1.5, "reg_unrest_shift": -1.0, "gb_Силовики": 1.0}}, "Полиция против коррупции")],
})
ARCH_DEMANDS = dict(ie_lib.ARCH_DEMANDS)
ARCH_DEMANDS.update({
    # (ключ, оператор, множитель к стартовому значению, абсолютное (млрд €)?, подпись)
    "lib": [("income", "<=", 0.95, False, "подоходный налог"), ("corp", "<=", 0.95, False, "налог на прибыль")],
    "euro": [("edu", ">=", 1.06, True, "образование"), ("admin", "<=", 0.96, True, "госаппарат")],
    # СНС в коалиции: «социальный национализм» — полиция и пенсии, без требования урезать пособия (иначе не выполнено со старта)
    "popr": [("police", ">=", 1.05, True, "полиция и суды"), ("pensions", ">=", 0.98, True, "пенсии")],
    "popl": [("pensions", ">=", 1.03, True, "пенсии"), ("admin", "<=", 0.95, True, "госаппарат")],
})


def demands_list(arch, P, gdp):
    out = []
    for key, op, k, ab, nm in ARCH_DEMANDS.get(arch, []):
        d = P[key]
        if ab:
            val = round(d * k * gdp / 100.0, 0 if gdp > 300 else 1)
            out.append({"key": key, "op": op, "val": float(val), "abs": True, "text": "%s %s %s млрд € в год" % (nm, "не ниже" if op == ">=" else "не выше", numtxt(val))})
        else:
            val = round(d * k, 1)
            out.append({"key": key, "op": op, "val": float(val), "text": "%s %s %.1f%% ВВП" % (nm, "не выше" if op == "<=" else "не ниже", val)})
    return out


def min_special(slot_archs):
    out = {}
    for s, a in enumerate(slot_archs):
        for (m, spec, title) in ARCH_SPECIAL.get(a, []):
            d = dict(spec); d["t"] = title
            out["%d:%d" % (m, s)] = d
    return out
