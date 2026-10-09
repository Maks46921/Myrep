# Помощники для данных Северной Македонии: общее берём из ie_lib, переопределяем раскладку слотов партий
# и добавляем архетипы «lib» (ДУИ–НАИ) и «popl» (социалисты и партии меньшинств в блоке власти).
from ie_lib import GROUPS, g, V, T, calibrate, TRAITS, MIN_BASE, numtxt
import ie_lib as _ie

# Слоты Северной Македонии:
# 0 ВМРО-ДПМНЕ (own) 1 ЗНАМ (cons) 2 СДСМ (soc) 3 ВЛЕН (region) 4 ДУИ–НАИ (lib)
# 5 СПМ и партии меньшинств (popl) 6 прочие (oth) 7 правые суверенисты (popr) 8 ДОМ и ЛДП (green) 9 Левица (prot)
SLOT_KEY = ["own", "cons", "soc", "region", "lib", "popl", "oth", "popr", "green", "prot"]
SLOT_ARCH = ["own", "cons", "soc", "region", "lib", "popl", "none", "popr", "green", "none"]
ARCHS = ["own", "cons", "soc", "region", "lib", "popl", "oth", "popr", "green", "prot"]


def p(**kw):
    """реакции партий по архетипам Северной Македонии -> {слот: значение}"""
    out = {}
    for s, k in enumerate(SLOT_KEY):
        if k in kw:
            out[s] = float(kw[k])
    for k, v in kw.items():
        if k.isdigit():
            out[int(k)] = float(v)
    return out


ARCH_SPECIAL = dict(_ie.ARCH_SPECIAL)
# ДУИ–НАИ: партия албанского истеблишмента — кадры, инфраструктура общин, евроинтеграция
ARCH_SPECIAL["lib"] = [(8, {"a": {"reg_dev_bonus": 2.0, "reg_unrest_shift": -1.5, "auto_shift": 2.5, "eff_bonus": -0.004}}, "Инфраструктура для общин"),
                       (11, {"a": {"dip_bonus": 1.5, "growth_bonus": 0.04, "mood_shift": 0.1}}, "Евроатлантический курс"),
                       (5, {"a": {"growth_bonus": 0.05, "corr_shift": 1.0, "gb_Бизнес": 1.0}}, "Экономика через своих людей")]
# СПМ и партии меньшинств: социальный патронаж, пенсии, пособия, культура общин
ARCH_SPECIAL["popl"] = [(9, {"a": {"equal_shift": 2.5, "gb_Пенсионеры": 2.0, "growth_bonus": -0.03}}, "Социальный патронаж"),
                        (6, {"a": {"gb_Село": 2.5, "reg_unrest_shift": -0.5}}, "Аграрный лоббист"),
                        (4, {"x": {"edu_eff": 1.03}, "a": {"reg_unrest_shift": -1.0}}, "Школы на языках общин")]
# у правых суверенистов — жёсткий порядок и оборона (как у popr в ie_lib, но добавим МИД)
ARCH_SPECIAL["popr"] = list(_ie.ARCH_SPECIAL["popr"]) + [(11, {"a": {"dip_bonus": -1.0, "mood_shift": -0.1, "gb_Силовики": 1.0}}, "Суверенная внешняя политика")]

ARCH_DEMANDS = dict(_ie.ARCH_DEMANDS)
ARCH_DEMANDS["lib"] = [("infra", ">=", 1.05, True, "инфраструктура и дороги общин"), ("edu", ">=", 1.03, True, "образование")]
ARCH_DEMANDS["popl"] = [("pensions", ">=", 1.02, True, "пенсии"), ("subs", ">=", 1.03, True, "субсидии аграриям")]


def demands_list(arch, P, gdp):
    out = []
    for key, op, k, ab, nm in ARCH_DEMANDS.get(arch, []):
        d = P[key]
        val = round(d * k * gdp / 100.0, 2)
        out.append({"key": key, "op": op, "val": float(val), "abs": True,
                    "text": "%s %s %s млрд € в год" % (nm, "не ниже" if op == ">=" else "не выше", ("%.2f" % val))})
    return out


def min_special(slot_archs):
    out = {}
    for s, a in enumerate(slot_archs):
        for (m, spec, title) in ARCH_SPECIAL.get(a, []):
            d = dict(spec); d["t"] = title
            out["%d:%d" % (m, s)] = d
    return out
