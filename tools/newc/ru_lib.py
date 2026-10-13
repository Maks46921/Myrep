# Помощники для данных России: общие функции берутся из ie_lib, переопределены слоты партий, калибровка (профиль несистемной оппозиции,
# которая в 2021 году не участвовала в выборах), спецминистерства и требования «Новых людей», «Яблока» и Партии пенсионеров.
import ie_lib
from ie_lib import GROUPS, g, V, T, TRAITS, MIN_BASE, ARCH_SPECIAL, ARCH_DEMANDS, numtxt, _norm

# слоты России: 0 «Единая Россия»(own) 1 КПРФ(left) 2 ЛДПР(popr) 3 «Справедливая Россия — За правду»(soc) 4 «Новые люди»(lib)
#               5 «Яблоко»(euro) 6 прочие партии: «Родина», Партия Роста, «Гражданская платформа», «Коммунисты России», «Зелёные»(oth)
#               7 Партия пенсионеров(popl) 8 самовыдвиженцы и местные элиты(region) 9 несистемная оппозиция(prot)
SLOT_KEY = ["own", "left", "popr", "soc", "lib", "euro", "oth", "popl", "region", "prot"]
SLOT_ARCH = ["own", "left", "popr", "soc", "lib", "euro", "none", "popl", "region", "none"]

ARCH_SPECIAL = dict(ARCH_SPECIAL)
ARCH_SPECIAL["left"] = [(9, {"a": {"equal_shift": 4.0, "gb_Рабочие": 2.5, "gb_Пенсионеры": 1.5, "growth_bonus": -0.05}}, "Советская социальная политика"),
                        (5, {"a": {"growth_bonus": -0.03, "equal_shift": 1.5, "gb_Рабочие": 1.5}}, "Национализация ключевых отраслей"),
                        (6, {"a": {"gb_Село": 3.0, "reg_unrest_shift": -0.5}}, "Колхозный лоббист")]
ARCH_SPECIAL["popr"] = [(2, {"a": {"sec_bonus": 3.0, "reg_unrest_shift": -2.0, "mood_shift": -0.2, "gb_Силовики": 1.5}}, "Жёсткий порядок"),
                        (9, {"a": {"equal_shift": 1.5, "gb_Пенсионеры": 1.5, "gb_Рабочие": 1.5}}, "«Народный социализм» ЛДПР"),
                        (11, {"a": {"dip_bonus": -1.0, "gb_Силовики": 1.0, "mood_shift": -0.1}}, "Громкая дипломатия")]
ARCH_SPECIAL["soc"] = [(9, {"a": {"equal_shift": 3.0, "gb_Рабочие": 2.0, "growth_bonus": -0.04}}, "Социальная справедливость"),
                       (3, {"x": {"health_eff": 1.06}, "a": {"extra_spend": 0.08, "gb_Пенсионеры": 1.0}}, "Бесплатная медицина"),
                       (8, {"a": {"reg_dev_bonus": 1.5, "equal_shift": 1.0, "gb_Рабочие": 1.0}}, "Справедливые тарифы ЖКХ")]
ARCH_SPECIAL["lib"] = [(5, {"a": {"growth_bonus": 0.05, "eff_bonus": 0.003, "gb_Бизнес": 2.0}}, "Защита малого бизнеса"),
                       (4, {"x": {"edu_eff": 1.06}, "a": {"gb_Молодёжь": 1.5}}, "Цифровая школа"),
                       (0, {"a": {"eff_bonus": 0.006, "growth_bonus": 0.02}}, "Налоговая донастройка без давления")]
ARCH_SPECIAL["euro"] = [(10, {"a": {"corr_shift": -3.5, "dem_shift": 0.03, "gb_Молодёжь": 1.0}}, "Правовое государство"),
                        (11, {"a": {"dip_bonus": 2.0, "growth_bonus": 0.04, "mood_shift": 0.15, "gb_Силовики": -1.5}}, "Дипломатия мира")]
ARCH_SPECIAL["popl"] = [(9, {"a": {"equal_shift": 2.0, "gb_Пенсионеры": 3.0, "growth_bonus": -0.03}}, "Защита пенсионеров")]
ARCH_SPECIAL["region"] = [(8, {"a": {"reg_dev_bonus": 2.5, "reg_unrest_shift": -2.0, "auto_shift": 3.0, "eff_bonus": -0.004}}, "Интересы регионов"),
                          (6, {"a": {"gb_Село": 3.0, "reg_unrest_shift": -1.0, "eff_bonus": -0.003}}, "Аграрный лоббист")]

ARCH_DEMANDS = dict(ARCH_DEMANDS)
ARCH_DEMANDS["left"] = [("pensions", ">=", 1.06, True, "пенсии"), ("health", ">=", 1.05, True, "здравоохранение")]
ARCH_DEMANDS["popr"] = [("police", ">=", 1.05, True, "полиция и суды"), ("benefits", ">=", 1.0, True, "пособия семьям и участникам СВО")]
ARCH_DEMANDS["soc"] = [("benefits", ">=", 1.04, True, "пособия"), ("pensions", ">=", 1.02, True, "пенсии")]
ARCH_DEMANDS["lib"] = [("subs", ">=", 1.0, True, "поддержка малого бизнеса и IT"), ("edu", ">=", 1.03, True, "образование и наука")]
ARCH_DEMANDS["euro"] = [("army", "<=", 0.75, True, "военные расходы"), ("health", ">=", 1.08, True, "здравоохранение")]
ARCH_DEMANDS["popl"] = [("pensions", ">=", 1.05, True, "пенсии")]
ARCH_DEMANDS["region"] = [("infra", ">=", 1.0, True, "дороги и ЖКХ в регионах"), ("subs", ">=", 0.96, True, "субсидии")]


def p(**kw):
    """реакции партий по архетипам России -> {слот: значение}"""
    out = {}
    for s, k in enumerate(SLOT_KEY):
        if k in kw:
            out[s] = float(kw[k])
    for k, v in kw.items():
        if k.isdigit():
            out[int(k)] = float(v)
    return out


def calibrate(C):
    """как ie_lib.calibrate, но для слота 9 (несистемная оппозиция, в 2021 году не участвовала) берётся профиль r['Ecal'], если задан."""
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
    """требования партий по ползункам бюджета в млрд € в год (по таблице ARCH_DEMANDS России)"""
    out = []
    for key, op, k, ab, nm in ARCH_DEMANDS.get(arch, []):
        d = P[key]
        val = round(d * k * gdp / 100.0, 0 if gdp > 300 else 1)
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
