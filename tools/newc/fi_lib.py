# Помощники для данных Финляндии: берём общие функции из ie_lib (V, T, g, calibrate, TRAITS, MIN_BASE, demands_list ...)
# и переопределяем то, что зависит от раскладки слотов партий Финляндии.
import ie_lib
from ie_lib import *          # noqa: F401,F403

# Слоты Финляндии:
# 0 Kok (own)  1 PS (popr)  2 SDP (soc)  3 Vas (left)  4 Vihr (green)  5 KD (cons)  6 прочие (oth)
# 7 RKP + депутат Аландов (lib)  8 Keskusta (region)  9 «Движение сейчас» и протестные списки (prot)
SLOT_KEY = ["own", "popr", "soc", "left", "green", "cons", "oth", "lib", "region", "prot"]
SLOT_ARCH = ["own", "popr", "soc", "left", "green", "cons", "none", "lib", "region", "none"]
ARCHS = ["own", "popr", "soc", "left", "green", "cons", "oth", "lib", "region", "prot"]


def p(**kw):
    """реакции партий по архетипам Финляндии (own, popr, soc, left, green, cons, oth, lib, region, prot); числа-ключи — слоты"""
    out = {}
    for s, k in enumerate(SLOT_KEY):
        if k in kw:
            out[s] = float(kw[k])
    for k, v in kw.items():
        if k.isdigit():
            out[int(k)] = float(v)
    return out


# особые министры: к общим архетипам добавлен либерал (RKP) и финские оттенки
ARCH_SPECIAL_FI = dict(ie_lib.ARCH_SPECIAL)
ARCH_SPECIAL_FI["lib"] = [
    (4, {"x": {"edu_eff": 1.06}, "a": {"gb_Молодёжь": 1.0}}, "Двуязычная школа"),
    (10, {"a": {"corr_shift": -2.5, "dem_shift": 0.02}}, "Права меньшинств и правовое государство"),
    (11, {"a": {"growth_bonus": 0.03, "dip_bonus": 1.5, "mood_shift": 0.1}}, "Северное сотрудничество"),
]
ARCH_SPECIAL_FI["popr"] = [
    (0, {"a": {"eff_bonus": 0.006, "equal_shift": -0.8, "gb_Бюджетники": -1.0}}, "Сокращение расходов"),
    (2, {"a": {"sec_bonus": 3.0, "reg_unrest_shift": -1.5, "mood_shift": -0.2, "gb_Силовики": 1.5}}, "Жёсткая миграционная политика"),
    (10, {"a": {"sec_bonus": 1.0, "gb_Силовики": 1.0, "mood_shift": -0.1}}, "Строгие наказания"),
]

ARCH_DEMANDS_FI = dict(ie_lib.ARCH_DEMANDS)
ARCH_DEMANDS_FI["lib"] = [("edu", ">=", 0.97, True, "образование")]
ARCH_DEMANDS_FI["popr"] = [("police", ">=", 0.97, True, "полиция и пограничники"), ("benefits", "<=", 1.02, True, "пособия")]
ARCH_DEMANDS_FI["cons"] = [("army", ">=", 0.97, True, "оборона"), ("health", ">=", 0.97, True, "здравоохранение")]
ARCH_DEMANDS_FI["region"] = [("subs", ">=", 0.96, True, "субсидии регионам и аграриям"), ("infra", ">=", 0.97, True, "дороги и инфраструктура")]


def demands_fi(arch, P, gdp):
    out = []
    for key, op, k, ab, nm in ARCH_DEMANDS_FI.get(arch, []):
        d = P[key]
        val = round(d * k * gdp / 100.0, 1)
        out.append({"key": key, "op": op, "val": float(val), "abs": True, "text": "%s %s %s млрд € в год" % (nm, "не ниже" if op == ">=" else "не выше", numtxt(val))})
    return out


def min_special_fi(slot_archs):
    out = {}
    for s, a in enumerate(slot_archs):
        for (m, spec, title) in ARCH_SPECIAL_FI.get(a, []):
            d = dict(spec); d["t"] = title
            out["%d:%d" % (m, s)] = d
    return out
