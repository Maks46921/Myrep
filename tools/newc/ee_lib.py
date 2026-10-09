# Помощники для данных Эстонии: берём общие функции из ie_lib (V, T, g, calibrate, TRAITS, MIN_BASE ...)
# и переопределяем то, что зависит от раскладки слотов и архетипов партий Эстонии.
import ie_lib
from ie_lib import *   # noqa: F401,F403

# Слоты Эстонии:
# 0 Партия реформ (own)  1 «Эстония 200» (euro)  2 Социал-демократы SDE (soc)  3 Isamaa (cons)  4 Центристская партия (popl)
# 5 Эстонские националисты и консерваторы ERK (popr)  6 прочие и внефракционные (oth)  7 «Правые» Parempoolsed (lib)
# 8 избирательные союзы и независимые кандидаты (region)  9 EKRE (prot)
SLOT_KEY = ["own", "euro", "soc", "cons", "popl", "popr", "oth", "lib", "region", "prot"]
SLOT_ARCH = ["own", "euro", "soc", "cons", "popl", "popr", "none", "lib", "region", "none"]
ARCHS = ["own", "euro", "soc", "cons", "popl", "popr", "oth", "lib", "region", "prot"]


def p(**kw):
    """реакции партий по архетипам Эстонии; числовые ключи — слоты"""
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
    "euro": [(4, {"x": {"edu_eff": 1.08}, "a": {"gb_Молодёжь": 2.0, "gb_Бюджетники": 0.5}}, "Единая эстонская школа"),
             (11, {"a": {"growth_bonus": 0.04, "mood_shift": 0.1, "dip_bonus": 2.0}}, "Ценностная дипломатия"),
             (10, {"a": {"corr_shift": -2.5, "eff_bonus": 0.004}}, "Цифровое государство и право"),
             (2, {"a": {"sec_bonus": 1.5, "reg_unrest_shift": -0.5}}, "Защита восточной границы")],
    "lib": [(0, {"a": {"eff_bonus": 0.010, "equal_shift": -0.8}, "x": {"admin_mult": 0.97}}, "Бережливый финансист"),
            (5, {"a": {"growth_bonus": 0.10, "gb_Бизнес": 2.0, "equal_shift": -0.5}}, "Предпринимательская экономика")],
    "popl": [(9, {"a": {"equal_shift": 2.5, "gb_Пенсионеры": 2.0, "gb_Рабочие": 1.0, "growth_bonus": -0.03}}, "Социальное государство"),
             (8, {"a": {"reg_dev_bonus": 1.5, "reg_unrest_shift": -1.5, "gb_Рабочие": 1.0}}, "Развитие Ида-Вирумаа")],
    "popr": [(2, {"a": {"sec_bonus": 2.5, "reg_unrest_shift": -1.0, "mood_shift": -0.2, "gb_Силовики": 1.5}}, "Национальная безопасность"),
             (4, {"x": {"edu_eff": 1.02}, "a": {"gb_Село": 1.0, "mood_shift": -0.1}}, "Национальная школа")],
    "region": [(6, {"a": {"gb_Село": 3.0, "reg_unrest_shift": -1.0, "eff_bonus": -0.003}}, "Голос волостей"),
               (8, {"a": {"reg_dev_bonus": 2.0, "reg_unrest_shift": -1.5, "auto_shift": 3.0, "eff_bonus": -0.003}}, "Сильные самоуправления")],
})
ARCH_DEMANDS = dict(ie_lib.ARCH_DEMANDS)
ARCH_DEMANDS.update({
    "euro": [("edu", ">=", 1.00, True, "образование"), ("admin", "<=", 1.03, True, "госаппарат")],
    "lib": [("income", "<=", 1.00, False, "подоходный налог"), ("admin", "<=", 0.97, True, "госаппарат")],
    "soc": [("benefits", ">=", 0.97, True, "пособия"), ("health", ">=", 1.00, True, "здравоохранение")],
    "cons": [("army", ">=", 1.00, True, "оборона"), ("vat", "<=", 0.97, False, "НДС")],
    "popl": [("pensions", ">=", 1.03, True, "пенсии"), ("benefits", ">=", 1.03, True, "пособия")],
    "popr": [("police", ">=", 1.05, True, "полиция и погранохрана"), ("army", ">=", 1.00, True, "оборона")],
    "region": [("subs", ">=", 0.96, True, "субсидии сёлам и аграриям"), ("infra", ">=", 0.97, True, "дороги")],
})


def demands_list(arch, P, gdp):
    out = []
    for key, op, k, ab, nm in ARCH_DEMANDS.get(arch, []):
        d = P[key]
        if ab:
            val = round(d * k * gdp / 100.0, 1)
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
