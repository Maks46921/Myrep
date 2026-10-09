# Помощники для данных Албании: общие функции берём из ie_lib, переопределяем раскладку слотов партий и спецминистерства.
from ie_lib import GROUPS, g, V, T, calibrate, TRAITS, MIN_BASE, numtxt
import ie_lib as _ie

# Слоты Албании: 0 Социалистическая партия (own) 1 Демократическая партия — «Альянс за великолепную Албанию» (cons)
# 2 Социал-демократическая партия Томa Доши (soc) 3 «Движение Вместе» (left) 4 Аграрно-экологическая партия (green)
# 5 Партия «Возможность» (lib) 6 прочие (oth) 7 Партия Свободы Илира Меты (popr) 8 партии меньшинств: PDIU и PBDNJ (region)
# 9 «Албания становится» Адриатика Лапая (prot)
SLOT_KEY = ["own", "cons", "soc", "left", "green", "lib", "oth", "popr", "region", "prot"]


def p(**kw):
    """реакции партий по архетипам Албании -> {слот: значение}"""
    out = {}
    for s, k in enumerate(SLOT_KEY):
        if k in kw:
            out[s] = float(kw[k])
    for k, v in kw.items():
        if k.isdigit():
            out[int(k)] = float(v)
    return out


ARCH_SPECIAL = dict(_ie.ARCH_SPECIAL)
ARCH_SPECIAL["lib"] = [(0, {"a": {"eff_bonus": 0.007, "growth_bonus": 0.03}}, "Налоги для предпринимателей"),
                       (5, {"a": {"growth_bonus": 0.06, "gb_Бизнес": 1.5}}, "Экономика без бюрократии"),
                       (10, {"a": {"corr_shift": -2.5}}, "Правовое государство")]
ARCH_SPECIAL["green"] = [(6, {"a": {"gb_Село": 3.0, "reg_unrest_shift": -0.5}}, "Аграрный лоббист"),
                         (7, {"x": {"env_eff": 1.12}, "a": {"gb_Экологи": 2.0, "growth_bonus": -0.03}}, "Охрана рек и побережья")]
ARCH_SPECIAL["region"] = [(4, {"x": {"edu_eff": 1.03}, "a": {"reg_unrest_shift": -1.0}}, "Школы меньшинств"),
                          (8, {"a": {"reg_dev_bonus": 2.0, "reg_unrest_shift": -1.5, "auto_shift": 2.0, "eff_bonus": -0.003}}, "Интересы юга и меньшинств")]
ARCH_DEMANDS = dict(_ie.ARCH_DEMANDS)
ARCH_DEMANDS["lib"] = [("admin", "<=", 0.95, True, "госаппарат"), ("corp", "<=", 0.95, True, "налог на прибыль")]
ARCH_DEMANDS["green"] = [("subs", ">=", 1.05, True, "субсидии аграриям"), ("eco", ">=", 1.05, True, "экология")]
ARCH_DEMANDS["region"] = [("edu", ">=", 0.98, True, "образование (школы меньшинств)")]
ARCH_DEMANDS["popr"] = [("police", ">=", 1.05, True, "полиция и суды"), ("pensions", ">=", 1.0, True, "пенсии")]


def demands_list(arch, P, gdp):
    out = []
    for key, op, k, ab, nm in ARCH_DEMANDS.get(arch, []):
        d = P[key]
        val = round(d * k * gdp / 100.0, 2)
        out.append({"key": key, "op": op, "val": float(val), "abs": True,
                    "text": "%s %s %s млрд € в год" % (nm, "не ниже" if op == ">=" else "не выше", "%.2f" % val)})
    return out


def min_special(slot_archs):
    out = {}
    for s, a in enumerate(slot_archs):
        for (m, spec, title) in ARCH_SPECIAL.get(a, []):
            d = dict(spec); d["t"] = title
            out["%d:%d" % (m, s)] = d
    return out
