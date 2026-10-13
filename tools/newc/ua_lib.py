# Помощники для данных Украины: общие функции берутся из ie_lib, переопределены слоты партий, спецминистерства и требования
# (популисты «Батькивщины», либералы «Голоса», мажоритарщики «Довиры»).
import ie_lib
from ie_lib import GROUPS, g, V, T, TRAITS, MIN_BASE, ARCH_SPECIAL, ARCH_DEMANDS, numtxt, _norm

# слоты Украины: 0 «Слуга народа»(own) 1 «Европейская солидарность»(cons) 2 «Батькивщина»(popl) 3 «Голос»(lib)
#                4 «Платформа за жизнь и мир»(soc) 5 «Восстановление Украины»(soc) 6 внефракционные и прочие(none)
#                7 «За будущее»(cons) 8 «Довира» и мажоритарщики(region) 9 ветеранские и волонтёрские списки(none, протест)
SLOT_ARCH = ["own", "cons", "popl", "lib", "soc", "soc", "none", "cons", "region", "none"]
ARCHS = ["own", "cons", "popl", "lib", "soc", "soc", "oth", "cons", "region", "prot"]
# ключи реакций партий в p(): по одному на слот
SLOT_KEY = ["own", "es", "bat", "gol", "pzm", "vu", "oth", "zm", "dov", "vet"]

ARCH_SPECIAL = dict(ARCH_SPECIAL)
ARCH_SPECIAL["lib"] = [(10, {"a": {"corr_shift": -3.5, "gb_Молодёжь": 1.0, "dem_shift": 0.02}}, "Антикоррупционная вертикаль"),
                       (0, {"a": {"eff_bonus": 0.006, "growth_bonus": 0.03}}, "Прозрачный бюджет и Prozorro"),
                       (11, {"a": {"growth_bonus": 0.04, "dip_bonus": 1.5, "mood_shift": 0.1}}, "Европейские реформы без оговорок")]
ARCH_SPECIAL["popl"] = [(9, {"a": {"equal_shift": 3.0, "gb_Пенсионеры": 2.0, "growth_bonus": -0.03}}, "Пенсии и тарифы для людей"),
                        (5, {"a": {"gb_Рабочие": 1.5, "growth_bonus": 0.02, "eff_bonus": -0.003}}, "Дешёвый газ для населения"),
                        (6, {"a": {"gb_Село": 3.0, "reg_unrest_shift": -0.5}}, "Защита фермеров и земли")]
ARCH_SPECIAL["cons"] = [(1, {"a": {"sec_bonus": 2.5, "gb_Силовики": 2.0}}, "Армия и ВПК"),
                        (11, {"a": {"dip_bonus": 1.2, "growth_bonus": 0.03}}, "Евроатлантический курс"),
                        (0, {"a": {"eff_bonus": 0.007, "equal_shift": -0.5}}, "Консервативные финансы"),
                        (6, {"a": {"gb_Село": 2.5, "reg_unrest_shift": -0.5}}, "Аграрное лобби")]
ARCH_SPECIAL["region"] = [(8, {"a": {"reg_dev_bonus": 2.5, "reg_unrest_shift": -2.0, "eff_bonus": -0.004}}, "Деньги на округа и громады"),
                          (6, {"a": {"gb_Село": 3.0, "reg_unrest_shift": -1.0, "eff_bonus": -0.003}}, "Аграрные холдинги и село")]
ARCH_DEMANDS = dict(ARCH_DEMANDS)
ARCH_DEMANDS["lib"] = [("edu", ">=", 1.05, True, "образование и наука"), ("subs", "<=", 0.92, True, "субсидии и госзакупки без тендеров")]
ARCH_DEMANDS["popl"] = [("pensions", ">=", 1.03, True, "пенсии"), ("benefits", ">=", 1.03, True, "субсидии на коммунальные услуги и пособия")]
ARCH_DEMANDS["cons"] = [("army", ">=", 1.02, True, "армия и оборонзаказ"), ("police", ">=", 1.0, True, "СБУ, полиция и суды")]
ARCH_DEMANDS["soc"] = [("pensions", ">=", 1.0, True, "пенсии"), ("benefits", ">=", 0.95, True, "пособия переселенцам и малоимущим")]
ARCH_DEMANDS["region"] = [("infra", ">=", 1.0, True, "восстановление дорог и мостов в округах"), ("subs", ">=", 0.95, True, "поддержка аграриев")]


def p(**kw):
    """реакции партий Украины по ключам слотов (own, es, bat, gol, pzm, vu, oth, zm, dov, vet) -> {слот: значение}"""
    out = {}
    for s, k in enumerate(SLOT_KEY):
        if k in kw:
            out[s] = float(kw[k])
    for k, v in kw.items():
        if k.isdigit():
            out[int(k)] = float(v)
    return out


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


def calibrate(C):
    """как ie_lib.calibrate, но с профилем ветеранских списков (r['Ecal'] вместо r['E'], если задан): в 2019 году их не было."""
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
