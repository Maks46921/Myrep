# Помощники для данных Черногории: общие функции берём у Ирландии (ie_lib) и переопределяем раскладку слотов партий.
import ie_lib as _ie
from ie_lib import GROUPS, g, V, T, calibrate, TRAITS, MIN_BASE, numtxt  # noqa: F401

# Слоты Черногории: 0 PES «Европа сейчас!» (own) 1 DPS (soc) 2 «За будущее Черногории» — НСД, СНП и др. (popr)
# 3 Демократы (lib) 4 Боснийская партия (cons) 5 URA (green) 6 прочие (oth) 7 «Европейский союз» — СД, СДП, ЛП (euro)
# 8 албанские партии (region) 9 Демократическая народная партия Кнежевича (prot)
SLOT_KEY = ["own", "soc", "popr", "lib", "cons", "green", "oth", "euro", "region", "prot"]


def p(**kw):
    """реакции партий по архетипам Черногории -> {слот: значение}"""
    out = {}
    for s, k in enumerate(SLOT_KEY):
        if k in kw:
            out[s] = float(kw[k])
    for k, v in kw.items():
        if k.isdigit():
            out[int(k)] = float(v)
    return out


ARCH_SPECIAL = dict(_ie.ARCH_SPECIAL)
ARCH_SPECIAL.update({
    # Демократы Бечича — партия силового блока
    "lib": [(2, {"a": {"sec_bonus": 2.5, "corr_shift": -1.5, "gb_Силовики": 1.5, "reg_unrest_shift": -1.0}}, "Война с кланами"),
            (1, {"a": {"sec_bonus": 2.0, "gb_Силовики": 1.0}}, "Армия в НАТО"),
            (10, {"a": {"corr_shift": -2.5}}, "Правовое государство")],
    # Боснийская партия
    "cons": [(11, {"a": {"dip_bonus": 1.0, "growth_bonus": 0.03, "mood_shift": 0.1}}, "Дипломатия мостов"),
             (9, {"a": {"equal_shift": 1.5, "gb_Пенсионеры": 1.0}}, "Социальная политика Санджака"),
             (8, {"a": {"reg_dev_bonus": 2.0, "reg_unrest_shift": -1.0}}, "Дороги на Север"),
             (5, {"a": {"growth_bonus": 0.05, "gb_Бизнес": 1.0}}, "Энергетика и горное дело")],
    # «За будущее Черногории»
    "popr": [(2, {"a": {"sec_bonus": 2.5, "reg_unrest_shift": -1.0, "mood_shift": -0.2, "gb_Силовики": 1.0}}, "Жёсткий порядок"),
             (9, {"a": {"equal_shift": 1.5, "gb_Пенсионеры": 2.0, "gb_Рабочие": 1.0}}, "Социальный консерватизм"),
             (8, {"a": {"reg_dev_bonus": 1.5, "growth_bonus": 0.03, "eff_bonus": -0.002}}, "Стройки и пространственное планирование"),
             (6, {"a": {"gb_Село": 2.5, "reg_unrest_shift": -0.5}}, "Аграрный лоббист")],
    "euro": [(11, {"a": {"growth_bonus": 0.05, "mood_shift": 0.2, "dip_bonus": 1.5}}, "Проевропейский курс"),
             (4, {"x": {"edu_eff": 1.06}, "a": {"gb_Молодёжь": 1.5}}, "Европейская школа"),
             (10, {"a": {"corr_shift": -2.5}}, "Правовое государство")],
    "region": [(5, {"a": {"growth_bonus": 0.05, "gb_Бизнес": 1.0, "reg_unrest_shift": -0.5}}, "Инвестиции диаспоры"),
               (6, {"a": {"gb_Село": 3.0, "reg_unrest_shift": -1.0, "eff_bonus": -0.003}}, "Аграрный лоббист"),
               (8, {"a": {"reg_dev_bonus": 2.0, "reg_unrest_shift": -1.5, "auto_shift": 3.0, "eff_bonus": -0.003}}, "Интересы Улциня и Тузи")],
})

# (ключ, оператор, множитель к стартовому значению, подпись) — требования в % ВВП (экономика маленькая, миллиарды неудобны)
ARCH_DEMANDS = {
    "soc": [("pensions", ">=", 1.02, "пенсии"), ("edu", ">=", 1.03, "образование")],
    "popr": [("pensions", ">=", 0.98, "пенсии"), ("police", ">=", 0.98, "полиция и суды")],
    "lib": [("police", ">=", 0.98, "полиция и суды"), ("army", ">=", 0.97, "армия")],
    "cons": [("infra", ">=", 0.96, "инфраструктура"), ("benefits", ">=", 0.96, "пособия")],
    "green": [("eco", ">=", 1.2, "экология"), ("admin", "<=", 0.95, "госаппарат")],
    "euro": [("edu", ">=", 1.04, "образование"), ("admin", "<=", 0.97, "госаппарат")],
    "region": [("subs", ">=", 0.96, "субсидии")],
}


def demands_list(arch, P, gdp):
    out = []
    for key, op, k, nm in ARCH_DEMANDS.get(arch, []):
        val = round(P[key] * k, 1)
        out.append({"key": key, "op": op, "val": float(val), "text": "%s %s %.1f%% ВВП" % (nm, "не выше" if op == "<=" else "не ниже", val)})
    return out


def min_special(slot_archs):
    out = {}
    for s, a in enumerate(slot_archs):
        for (m, spec, title) in ARCH_SPECIAL.get(a, []):
            d = dict(spec); d["t"] = title
            out["%d:%d" % (m, s)] = d
    return out
