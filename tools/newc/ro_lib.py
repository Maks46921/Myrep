# Помощники для данных Румынии: общие функции берём у Ирландии (ie_lib) и переопределяем раскладку слотов партий.
from ie_lib import GROUPS, g, V, T, calibrate, TRAITS, MIN_BASE, numtxt
import ie_lib as _ie

# Слоты Румынии: 0 НЛП (own) 1 СДП (soc) 2 СРС (lib) 3 SOS Romania (popr) 4 ПОТ (popl) 5 SENS (green)
# 6 прочие и неприсоединившиеся (oth) 7 группа нацменьшинств (euro) 8 ДСВР (region) 9 АУР (prot)
SLOT_KEY = ["own", "soc", "lib", "popr", "popl", "green", "oth", "euro", "region", "prot"]


def p(**kw):
    """реакции партий по архетипам Румынии -> {слот: значение}"""
    out = {}
    for s, k in enumerate(SLOT_KEY):
        if k in kw:
            out[s] = float(kw[k])
    for k, v in kw.items():
        if k.isdigit():
            out[int(k)] = float(v)
    return out


ARCH_SPECIAL = dict(_ie.ARCH_SPECIAL)
ARCH_SPECIAL["lib"] = [(10, {"a": {"corr_shift": -3.5, "gb_Молодёжь": 1.0, "dem_shift": 0.02}}, "Правовое государство и DNA"),
                       (11, {"a": {"growth_bonus": 0.03, "dip_bonus": 1.5, "mood_shift": 0.1}}, "Проевропейская дипломатия"),
                       (1, {"a": {"sec_bonus": 2.0, "gb_Силовики": 1.0}}, "Восточный фланг НАТО"),
                       (7, {"x": {"env_eff": 1.06}, "a": {"gb_Экологи": 1.0}}, "Борьба с незаконными вырубками")]
ARCH_SPECIAL["region"] = [(8, {"a": {"reg_dev_bonus": 2.5, "reg_unrest_shift": -2.0, "auto_shift": 3.0, "eff_bonus": -0.003}}, "Деньги для Трансильвании"),
                          (4, {"x": {"edu_eff": 1.03}, "a": {"reg_unrest_shift": -1.0}}, "Школы на венгерском языке"),
                          (6, {"a": {"gb_Село": 2.5, "reg_unrest_shift": -0.5}}, "Аграрный лоббист")]
ARCH_SPECIAL["euro"] = [(4, {"x": {"edu_eff": 1.02}, "a": {"reg_unrest_shift": -0.5}}, "Школы меньшинств"),
                        (11, {"a": {"dip_bonus": 0.8, "mood_shift": 0.05}}, "Мосты к соседям")]
ARCH_SPECIAL["popl"] = [(9, {"a": {"equal_shift": 2.0, "gb_Пенсионеры": 2.0, "growth_bonus": -0.03}}, "Пенсии превыше всего")]
ARCH_DEMANDS = dict(_ie.ARCH_DEMANDS)
ARCH_DEMANDS["lib"] = [("admin", "<=", 0.95, True, "госаппарат"), ("edu", ">=", 1.03, True, "образование и наука")]
ARCH_DEMANDS["region"] = [("infra", ">=", 0.98, True, "инфраструктура и развитие"), ("subs", ">=", 0.96, True, "субсидии аграриям")]
ARCH_DEMANDS["euro"] = [("edu", ">=", 0.98, True, "образование (школы меньшинств)")]
ARCH_DEMANDS["soc"] = [("pensions", ">=", 0.98, True, "пенсии"), ("benefits", ">=", 0.95, True, "пособия")]
ARCH_DEMANDS["popl"] = [("pensions", ">=", 1.05, True, "пенсии")]


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
