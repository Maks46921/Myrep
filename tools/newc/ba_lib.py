# Помощники для данных Боснии и Герцеговины: общее берётся из ie_lib, переопределены слоты партий и спецминистерства.
import ie_lib
from ie_lib import GROUPS, g, T, TRAITS, MIN_BASE, ARCH_SPECIAL, ARCH_DEMANDS, numtxt, calibrate, _norm
import ie_lib as _ie


def V(n, d, c=None, s=None, a=None, ps=None, st=None, rg=None, set=None, tag=None, x=None):
    """как ie_lib.V, но с множителями эффективности x (health_eff, edu_eff, env_eff)"""
    v = _ie.V(n, d, c=c, s=s, a=a, ps=ps, st=st, rg=rg, set=set, tag=tag)
    if x:
        v["x"] = x
    return v

# слоты БиГ: 0 ХДЗ БиГ (own) 1 СДП БиГ (soc) 2 СДА (cons) 3 СНСД (popr) 4 НиП (lib) 5 Наша страна (green)
#            6 прочие малые партии РС и ФБиГ (oth) 7 ДФ и НЕС (left) 8 СДС и ПДП — сербская оппозиция (region) 9 протестные списки (prot)
SLOT_KEY = ["own", "soc", "cons", "popr", "lib", "green", "oth", "left", "region", "prot"]
SLOT_ARCH = ["own", "soc", "cons", "popr", "lib", "green", "none", "left", "region", "none"]
ARCHS = ["own", "soc", "cons", "popr", "lib", "green", "oth", "left", "region", "prot"]


def p(**kw):
    """реакции партий по архетипам -> {слот: значение}; числовой ключ задаёт слот напрямую: p(**{'6': 2})"""
    out = {}
    for s, k in enumerate(SLOT_KEY):
        if k in kw:
            out[s] = float(kw[k])
    for k, v in kw.items():
        if k.isdigit():
            out[int(k)] = float(v)
    return out


# у либералов (НиП) и «региональной» сербской оппозиции в ie_lib нет спецминистерств и требований — добавляем свои
ARCH_SPECIAL = dict(ARCH_SPECIAL)
ARCH_SPECIAL["lib"] = [(11, {"a": {"dip_bonus": 1.5, "growth_bonus": 0.04, "mood_shift": 0.1}}, "Европейский курс"),
                       (10, {"a": {"corr_shift": -3.0, "dem_shift": 0.02}}, "Правовое государство"),
                       (0, {"a": {"eff_bonus": 0.006, "growth_bonus": 0.03}}, "Либеральные финансы")]
ARCH_SPECIAL["region"] = [(0, {"a": {"eff_bonus": 0.005, "auto_shift": 2.0}}, "Фискальная самостоятельность энтити"),
                          (8, {"a": {"reg_dev_bonus": 2.0, "reg_unrest_shift": -1.5, "auto_shift": 3.5, "eff_bonus": -0.003}}, "Деньги на дороги энтити"),
                          (10, {"a": {"corr_shift": -2.5, "auto_shift": 1.0}}, "Суды без Додика")]
ARCH_DEMANDS = dict(ARCH_DEMANDS)
ARCH_DEMANDS["lib"] = [("edu", ">=", 1.05, True, "образование и наука"), ("admin", "<=", 0.96, True, "госаппарат")]
ARCH_DEMANDS["region"] = [("infra", ">=", 1.04, True, "инфраструктура"), ("subs", ">=", 0.98, True, "субсидии")]
ARCH_DEMANDS["cons"] = [("benefits", ">=", 1.03, True, "пособия ветеранам и соцпомощь"), ("police", ">=", 1.02, True, "полиция и суды")]
ARCH_DEMANDS["popr"] = [("pensions", ">=", 1.03, True, "пенсии"), ("admin", ">=", 1.02, True, "госаппарат энтити")]


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
