# Помощники для данных Хорватии: общие функции берём у Ирландии (ie_lib), раскладку слотов партий, спецминистерства и требования — свои.
import ie_lib
from ie_lib import GROUPS, g, V, T, calibrate, TRAITS, MIN_BASE, numtxt

# Слоты Хорватии:
# 0 ХДС и партнёры (own) 1 СДП (soc) 2 Можемо! (green) 3 Движение Родины (popr) 4 Мост (cons) 5 Центр–GLAS–NPS (lib)
# 6 прочие и независимые (oth) 7 национальные меньшинства (min) 8 ИДС–ПГС, Истрия и Кварнер (region) 9 DOMiNO (prot)
SLOT_KEY = ["own", "soc", "green", "popr", "cons", "lib", "oth", "min", "region", "prot"]
# архетипы для движка (PARCH) и для мировой симуляции (ARCHS)
SLOT_ARCH = ["own", "soc", "green", "popr", "cons", "lib", "none", "region", "region", "none"]
ARCHS = ["own", "soc", "green", "popr", "cons", "lib", "oth", "region", "region", "prot"]


def p(**kw):
    """реакции партий по ключам слотов Хорватии -> {слот: значение}"""
    out = {}
    for s, k in enumerate(SLOT_KEY):
        if k in kw:
            out[s] = float(kw[k])
    for k, v in kw.items():
        if k.isdigit():
            out[int(k)] = float(v)
    return out


A = ie_lib.ARCH_SPECIAL
# спецминистерства по слотам: (министерство, эффект, название)
SLOT_SPECIAL = {
    1: A["soc"],
    2: A["green"] + [(8, {"a": {"reg_dev_bonus": 1.0, "equal_shift": 1.5, "gb_Молодёжь": 1.0}}, "Городское жильё и транспорт")],
    3: [(5, {"a": {"growth_bonus": 0.04, "gb_Рабочие": 1.0, "gb_Бизнес": -0.5}}, "Экономический патриотизм"),
        (6, {"a": {"gb_Село": 3.0, "reg_unrest_shift": -0.5}}, "Славонское село"),
        (9, {"a": {"gb_Пенсионеры": 1.5, "equal_shift": 1.0}}, "Демография и семья"),
        (2, {"a": {"sec_bonus": 2.5, "gb_Силовики": 2.0, "mood_shift": -0.2}}, "Жёсткая граница")],
    4: [(10, {"a": {"corr_shift": -3.5, "gb_Молодёжь": 0.5}}, "Борьба с «системой» и кумовством"),
        (0, {"a": {"eff_bonus": 0.008, "equal_shift": -0.5}}, "Ревизия расходов"),
        (9, {"a": {"gb_Пенсионеры": 1.5, "equal_shift": 1.0}}, "Семья и демография")],
    5: [(0, {"a": {"eff_bonus": 0.007, "growth_bonus": 0.03}}, "Либеральные финансы"),
        (4, {"x": {"edu_eff": 1.08}, "a": {"gb_Молодёжь": 1.5}}, "Наука и университеты"),
        (10, {"a": {"corr_shift": -3.0, "dem_shift": 0.02}}, "Правовое государство")],
    7: [(4, {"x": {"edu_eff": 1.03}, "a": {"reg_unrest_shift": -1.0}}, "Школы меньшинств"),
        (8, {"a": {"reg_dev_bonus": 1.5, "reg_unrest_shift": -1.5, "eff_bonus": -0.002}}, "Возвращение и обновление районов войны")],
    8: [(8, {"a": {"reg_dev_bonus": 2.5, "reg_unrest_shift": -1.5, "auto_shift": 4.0, "eff_bonus": -0.004}}, "Регионализм Истрии"),
        (5, {"a": {"growth_bonus": 0.04, "gb_Бизнес": 1.0}}, "Туризм и малый бизнес побережья")],
}
# требования по ползункам бюджета: (ключ, оператор, множитель к стартовому значению, абсолютное, название)
SLOT_DEMANDS = {
    1: [("pensions", ">=", 0.98, True, "пенсии"), ("health", ">=", 1.03, True, "здравоохранение")],
    2: [("eco", ">=", 1.12, True, "экология и климат"), ("benefits", ">=", 1.05, True, "социальная помощь и жильё")],
    3: [("police", ">=", 1.0, True, "полиция и охрана границы"), ("army", ">=", 1.0, True, "армия"), ("benefits", ">=", 0.97, True, "демографические пособия")],
    4: [("admin", "<=", 0.95, True, "госаппарат"), ("benefits", ">=", 0.98, True, "семейные пособия")],
    5: [("edu", ">=", 1.05, True, "образование и наука"), ("subs", "<=", 0.95, True, "субсидии госкомпаниям")],
    7: [("edu", ">=", 0.98, True, "образование (школы меньшинств)")],
    8: [("infra", ">=", 1.02, True, "инфраструктура (Истрия и Кварнер)"), ("subs", ">=", 0.96, True, "поддержка туризма и малого бизнеса")],
}


def demands_slot(s, P, gdp):
    out = []
    for key, op, k, ab, nm in SLOT_DEMANDS.get(s, []):
        val = round(P[key] * k * gdp / 100.0, 1)
        out.append({"key": key, "op": op, "val": float(val), "abs": True,
                    "text": "%s %s %s млрд € в год" % (nm, "не ниже" if op == ">=" else "не выше", numtxt(val))})
    return out


def min_special_hr():
    out = {}
    for s, lst in SLOT_SPECIAL.items():
        for (m, spec, title) in lst:
            d = dict(spec); d["t"] = title
            out["%d:%d" % (m, s)] = d
    return out
