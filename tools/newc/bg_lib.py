# Помощники для данных Болгарии: общие функции берём у Ирландии (ie_lib), переопределяем раскладку слотов партий,
# спецминистерства и требования для архетипов, которых нет в ie_lib (lib, euro), и калибровку (как у Венгрии — профиль новой партии Радева).
import ie_lib
from ie_lib import GROUPS, g, V, T, TRAITS, MIN_BASE, numtxt, _norm
import ie_lib as _ie

# Слоты Болгарии: 0 ГЕРБ–СДС (own) 1 БСП–Объединённые левые (soc) 2 ПП–ДБ (lib) 3 «Возрождение» (popr) 4 ИТН (cons)
# 5 МЕЧ (popr) 6 прочие: «Величие» и независимые (oth) 7 АПС (euro) 8 ДПС–Новое начало (region) 9 «Прогрессивная Болгария» Радева (prot)
SLOT_KEY = ["own", "soc", "lib", "popr", "cons", "mech", "oth", "euro", "region", "prot"]


def p(**kw):
    """реакции партий по архетипам Болгарии -> {слот: значение}; mech — МЕЧ (по умолчанию как popr, но слабее)"""
    out = {}
    for s, k in enumerate(SLOT_KEY):
        if k in kw:
            out[s] = float(kw[k])
    if 5 not in out and "popr" in kw:
        out[5] = round(float(kw["popr"]) * 0.7, 1)
    for k, v in kw.items():
        if k.isdigit():
            out[int(k)] = float(v)
    return out


ARCH_SPECIAL = dict(_ie.ARCH_SPECIAL)
ARCH_SPECIAL["lib"] = [(10, {"a": {"corr_shift": -4.0, "gb_Молодёжь": 1.0, "dem_shift": 0.02}}, "Судебная реформа и борьба с коррупцией"),
                       (0, {"a": {"eff_bonus": 0.007, "growth_bonus": 0.03}}, "Прозрачные финансы"),
                       (5, {"a": {"growth_bonus": 0.06, "gb_Бизнес": 1.5}}, "Цифровая экономика и стартапы")]
ARCH_SPECIAL["euro"] = [(4, {"x": {"edu_eff": 1.04}, "a": {"reg_unrest_shift": -1.0}}, "Школы в смешанных районах"),
                        (6, {"a": {"gb_Село": 2.5, "reg_unrest_shift": -0.5}}, "Табачные и горные хозяйства")]
ARCH_SPECIAL["region"] = [(6, {"a": {"gb_Село": 4.0, "reg_unrest_shift": -1.0, "eff_bonus": -0.004}}, "Аграрный лоббист"),
                          (8, {"a": {"reg_dev_bonus": 2.5, "reg_unrest_shift": -2.0, "eff_bonus": -0.005, "corr_shift": 1.5}}, "Распределитель региональных денег")]
ARCH_DEMANDS = dict(_ie.ARCH_DEMANDS)
ARCH_DEMANDS["lib"] = [("police", ">=", 1.0, True, "суды и прокуратура"), ("edu", ">=", 1.05, True, "образование и наука")]
ARCH_DEMANDS["euro"] = [("subs", ">=", 0.98, True, "субсидии аграриям"), ("edu", ">=", 0.99, True, "образование")]
ARCH_DEMANDS["region"] = [("subs", ">=", 1.0, True, "субсидии и региональные программы"), ("infra", ">=", 0.98, True, "дороги и инфраструктура")]
ARCH_DEMANDS["cons"] = [("health", ">=", 1.0, True, "здравоохранение"), ("police", ">=", 1.0, True, "полиция и суды")]


def calibrate(C):
    """как ie_lib.calibrate, но с профилем «Прогрессивной Болгарии» (r['Ecal'] вместо r['E'], если задан): в 2024 году партии не было."""
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
