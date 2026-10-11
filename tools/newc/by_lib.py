# Помощники для данных Беларуси (BY): общие функции берутся из ie_lib, переопределены слоты партий, калибровка
# (профиль демократических сил в эмиграции, которых нет в официальных результатах 2024 года), спецминистерства и требования партий.
import ie_lib
from ie_lib import GROUPS, g, V, T, TRAITS, MIN_BASE, ARCH_SPECIAL, ARCH_DEMANDS, numtxt, _norm

# слоты Беларуси: 0 «Белая Русь»(own) 1 КПБ(left) 2 РПТС(soc) 3 ЛДП(popr) 4 либералы и «третий путь»(lib)
#                 5 «Зелёные» и экологи(green) 6 прочие и «против всех»(oth) 7 национальные демократы в эмиграции(cons)
#                 8 беспартийные депутаты президентской вертикали(region) 9 демократические силы Тихановской(prot)
SLOT_KEY = ["own", "left", "soc", "popr", "lib", "green", "oth", "cons", "region", "prot"]

ARCH_SPECIAL = dict(ARCH_SPECIAL)
ARCH_SPECIAL["lib"] = [(0, {"a": {"eff_bonus": 0.006, "growth_bonus": 0.03, "equal_shift": -0.5}}, "Рыночные реформы"),
                       (5, {"a": {"growth_bonus": 0.06, "gb_Бизнес": 2.0, "gb_Рабочие": -0.5}}, "Дерегулирование и частный бизнес"),
                       (11, {"a": {"dip_bonus": 1.2, "growth_bonus": 0.02, "mood_shift": 0.1}}, "Разморозка отношений с Западом")]
ARCH_SPECIAL["cons"] = [(4, {"x": {"edu_eff": 1.06}, "a": {"gb_Молодёжь": 1.5, "gb_Силовики": -1.0}}, "Белорусизация школ и вузов"),
                        (11, {"a": {"dip_bonus": 1.5, "mood_shift": 0.15, "gb_Силовики": -1.0}}, "Европейский выбор"),
                        (10, {"a": {"corr_shift": -3.0, "dem_shift": 0.03, "gb_Силовики": -1.5}}, "Люстрация и независимые суды")]
ARCH_SPECIAL["left"] = [(9, {"a": {"equal_shift": 3.0, "gb_Пенсионеры": 2.0, "gb_Рабочие": 1.5, "growth_bonus": -0.04}}, "Советская социальная политика"),
                        (6, {"a": {"gb_Село": 3.0, "eff_bonus": -0.003}}, "Колхозное лобби"),
                        (8, {"a": {"reg_dev_bonus": 1.5, "equal_shift": 1.5, "gb_Бизнес": -1.0}}, "Государственное жильё")]
ARCH_SPECIAL["popr"] = [(2, {"a": {"sec_bonus": 2.5, "reg_unrest_shift": -1.5, "mood_shift": -0.2, "gb_Силовики": 1.5}}, "Жёсткий порядок"),
                        (1, {"a": {"sec_bonus": 2.0, "gb_Силовики": 1.5, "gb_Молодёжь": -0.5}}, "Территориальная оборона"),
                        (9, {"a": {"equal_shift": 1.0, "gb_Пенсионеры": 1.5, "gb_Рабочие": 1.0}}, "Социальный патриотизм")]
ARCH_SPECIAL["region"] = [(1, {"a": {"sec_bonus": 2.0, "gb_Силовики": 1.5}}, "Генералитет президента"),
                          (2, {"a": {"sec_bonus": 2.5, "reg_unrest_shift": -2.0, "mood_shift": -0.2, "gb_Силовики": 1.5}}, "Силовая вертикаль"),
                          (6, {"a": {"gb_Село": 3.0, "reg_unrest_shift": -1.0, "eff_bonus": -0.003}}, "Директора агрокомбинатов"),
                          (8, {"a": {"reg_dev_bonus": 2.0, "reg_unrest_shift": -1.5, "eff_bonus": -0.003}}, "Облисполкомы и госпрограммы"),
                          (10, {"a": {"sec_bonus": 1.0, "corr_shift": 0.5, "dem_shift": -0.01}}, "Президентская юстиция"),
                          (11, {"a": {"dip_bonus": -0.4, "gb_Силовики": 1.0, "growth_bonus": 0.02}}, "Союзное государство прежде всего")]

ARCH_DEMANDS = dict(ARCH_DEMANDS)
ARCH_DEMANDS["left"] = [("pensions", ">=", 0.98, True, "пенсии"), ("subs", ">=", 0.97, True, "поддержка госпредприятий и колхозов")]
ARCH_DEMANDS["soc"] = [("benefits", ">=", 0.95, True, "пособия семьям"), ("pensions", ">=", 0.95, True, "пенсии")]
ARCH_DEMANDS["popr"] = [("army", ">=", 0.95, True, "армия и территориальная оборона"), ("police", ">=", 0.98, True, "милиция и порядок")]
ARCH_DEMANDS["lib"] = [("subs", "<=", 0.85, True, "субсидии госпредприятиям"), ("admin", "<=", 0.92, True, "госаппарат")]
ARCH_DEMANDS["cons"] = [("edu", ">=", 1.06, True, "образование и белорусская культура"), ("police", "<=", 0.80, True, "силовые структуры")]
ARCH_DEMANDS["region"] = [("subs", ">=", 0.97, True, "поддержка АПК и госпредприятий"), ("police", ">=", 0.97, True, "силовые структуры")]


def p(**kw):
    """реакции партий по архетипам Беларуси -> {слот: значение}"""
    out = {}
    for s, k in enumerate(SLOT_KEY):
        if k in kw:
            out[s] = float(kw[k])
    for k, v in kw.items():
        if k.isdigit():
            out[int(k)] = float(v)
    return out


def calibrate(C):
    """как ie_lib.calibrate, но с региональным профилем оппозиции (r['Ecal'] вместо r['E'], если задан): в 2024 году её к выборам не допустили."""
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
        out.append({"key": key, "op": op, "val": float(val), "abs": True, "text": "%s %s %s млрд € в год" % (nm, "не ниже" if op == ">=" else "не выше", numtxt(val))})
    return out


def min_special(slot_archs):
    out = {}
    for s, a in enumerate(slot_archs):
        for (m, spec, title) in ARCH_SPECIAL.get(a, []):
            d = dict(spec); d["t"] = title
            out["%d:%d" % (m, s)] = d
    return out
