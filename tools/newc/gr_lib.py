# Помощники для данных Греции: общие функции — из ie_lib, переопределены слоты партий, особые министерства и требования.
import ie_lib as _ie
from ie_lib import GROUPS, g, T, calibrate, TRAITS, MIN_BASE, numtxt
from ie_lib import V as _V

# Слоты Греции: 0 Новая демократия (own) 1 ПАСОК–КИНАЛ (soc) 2 СИРИЗА (left) 3 KKE (kke -> архетип left)
# 4 Плевси Элефтериас (popl) 5 Ники (cons) 6 прочие и независимые (oth) 7 Голос разума (popr)
# 8 Партия дружбы, равенства и мира — мусульманское меньшинство Фракии (region) 9 Греческое решение (prot)
SLOT_KEY = ["own", "soc", "left", "kke", "popl", "cons", "oth", "popr", "region", "prot"]
SLOT_ARCH = ["own", "soc", "left", "left", "popl", "cons", "none", "popr", "region", "none"]
ARCHS = ["own", "soc", "left", "left", "popl", "cons", "oth", "popr", "region", "prot"]


def V(n, d, c=None, s=None, a=None, ps=None, st=None, rg=None, set=None, tag=None, x=None):
    """как ie_lib.V, но с множителями отдачи расходов (x)"""
    v = _V(n, d, c=c, s=s, a=a, ps=ps, st=st, rg=rg, set=set, tag=tag)
    if x:
        v["x"] = x
    return v


def p(**kw):
    """реакции партий по ключам слотов Греции -> {слот: значение}; числовые ключи — прямо слоты"""
    out = {}
    for s, k in enumerate(SLOT_KEY):
        if k in kw:
            out[s] = float(kw[k])
    for k, v in kw.items():
        if k.isdigit():
            out[int(k)] = float(v)
    return out


ARCH_SPECIAL = dict(_ie.ARCH_SPECIAL)
ARCH_SPECIAL["popl"] = [(10, {"a": {"corr_shift": -3.5, "gb_Молодёжь": 1.0, "capital_bonus": -0.03}}, "Чистые руки: прокурорский надзор"),
                        (3, {"x": {"health_eff": 1.06}, "a": {"extra_spend": 0.08, "gb_Пенсионеры": 1.0}}, "Народное здравоохранение")]
ARCH_SPECIAL["cons"] = [(4, {"x": {"edu_eff": 0.98}, "a": {"gb_Пенсионеры": 1.0, "gb_Молодёжь": -1.0}}, "Православная школа"),
                        (6, {"a": {"gb_Село": 2.5, "reg_unrest_shift": -0.5}}, "Аграрный лоббист"),
                        (1, {"a": {"sec_bonus": 2.0, "gb_Силовики": 1.0}}, "Сильная оборона")]
ARCH_SPECIAL["region"] = [(4, {"x": {"edu_eff": 1.02}, "a": {"reg_unrest_shift": -1.0}}, "Школы меньшинства Фракии"),
                          (8, {"a": {"reg_dev_bonus": 2.0, "reg_unrest_shift": -1.5, "auto_shift": 2.0, "eff_bonus": -0.003}}, "Развитие Фракии")]
ARCH_DEMANDS = dict(_ie.ARCH_DEMANDS)
ARCH_DEMANDS["popl"] = [("health", ">=", 1.05, True, "здравоохранение"), ("benefits", ">=", 1.04, True, "пособия")]
ARCH_DEMANDS["cons"] = [("army", ">=", 1.05, True, "оборона"), ("subs", ">=", 1.0, True, "субсидии селу")]
ARCH_DEMANDS["popr"] = [("police", ">=", 1.10, True, "полиция и охрана границ"), ("army", ">=", 1.05, True, "оборона")]
ARCH_DEMANDS["region"] = [("edu", ">=", 0.98, True, "образование (школы меньшинства)")]


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
