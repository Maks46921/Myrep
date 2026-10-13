# Помощники для данных Молдовы: общие функции берутся из ie_lib, переопределены слоты партий, спецминистерства и требования партий.
import ie_lib
from ie_lib import GROUPS, g, V, T, TRAITS, MIN_BASE, ARCH_SPECIAL, ARCH_DEMANDS, numtxt, _norm, calibrate

# слоты Молдовы: 0 PAS(own) 1 блок «Альтернатива»(soc) 2 «Наша партия»(popl) 3 «Демократия дома»(cons) 4 ПКРМ(left)
#                5 сеть Шора / блок «Победа»(popr) 6 прочие и независимые(oth) 7 внепарламентские проевропейские партии(euro)
#                8 местные списки и мэры (Лига городов и сёл и др.)(region) 9 ПСРМ — Патриотический блок Додона(prot)
SLOT_KEY = ["own", "soc", "popl", "cons", "left", "popr", "oth", "euro", "region", "prot"]

ARCH_SPECIAL = dict(ARCH_SPECIAL)
ARCH_SPECIAL["soc"] = [(8, {"a": {"reg_dev_bonus": 1.5, "reg_unrest_shift": -1.0, "gb_Бюджетники": 0.5}}, "Хозяйственник из столичной мэрии"),
                       (9, {"a": {"equal_shift": 2.5, "gb_Пенсионеры": 1.5, "growth_bonus": -0.03}}, "Социальный центризм"),
                       (11, {"a": {"growth_bonus": 0.02, "dip_bonus": 0.6, "mood_shift": 0.1}}, "Прагматичная дипломатия: ЕС без разрыва с Востоком")]
ARCH_SPECIAL["popl"] = [(9, {"a": {"equal_shift": 2.0, "gb_Пенсионеры": 2.0, "growth_bonus": -0.03}}, "Пенсии и тарифы прежде всего"),
                        (2, {"a": {"sec_bonus": 1.5, "reg_unrest_shift": -1.5, "gb_Силовики": 1.0}}, "Порядок по-бельцки"),
                        (8, {"a": {"reg_dev_bonus": 2.0, "reg_unrest_shift": -1.0}}, "Север и Бельцы — «вторая столица»")]
ARCH_SPECIAL["cons"] = [(4, {"x": {"edu_eff": 1.04}, "a": {"gb_Молодёжь": 0.5}}, "Румынский язык и история румын в школах"),
                        (11, {"a": {"dip_bonus": 1.0, "growth_bonus": 0.02, "mood_shift": -0.1}}, "Курс на объединение с Румынией"),
                        (2, {"a": {"sec_bonus": 1.5, "corr_shift": -1.0, "gb_Силовики": 1.0}}, "Чистка «системы» и порядок")]
ARCH_SPECIAL["euro"] = [(11, {"a": {"growth_bonus": 0.03, "dip_bonus": 1.5, "mood_shift": 0.1}}, "Евроинтеграция без оговорок"),
                        (10, {"a": {"corr_shift": -3.0, "gb_Молодёжь": 0.5, "dem_shift": 0.02}}, "Антикоррупционная прокуратура")]
ARCH_SPECIAL["region"] = [(8, {"a": {"reg_dev_bonus": 2.5, "reg_unrest_shift": -1.5, "auto_shift": 2.0, "eff_bonus": -0.003}}, "Деньги для сёл и примэрий"),
                          (6, {"a": {"gb_Село": 3.0, "reg_unrest_shift": -0.5}}, "Аграрный лоббист")]
ARCH_DEMANDS = dict(ARCH_DEMANDS)
ARCH_DEMANDS["soc"] = [("pensions", ">=", 1.00, True, "пенсии"), ("infra", ">=", 1.02, True, "дороги и коммунальная инфраструктура")]
ARCH_DEMANDS["popl"] = [("pensions", ">=", 1.04, True, "пенсии"), ("subs", ">=", 1.0, True, "компенсации за газ и тепло")]
ARCH_DEMANDS["cons"] = [("edu", ">=", 1.03, True, "образование"), ("army", ">=", 1.10, True, "армия")]
ARCH_DEMANDS["left"] = [("benefits", ">=", 1.06, True, "пособия"), ("health", ">=", 1.04, True, "здравоохранение")]
ARCH_DEMANDS["euro"] = [("police", ">=", 1.04, True, "полиция, прокуратура и суды"), ("edu", ">=", 1.0, True, "образование")]
ARCH_DEMANDS["region"] = [("subs", ">=", 0.98, True, "субсидии аграриям"), ("infra", ">=", 1.0, True, "дороги и водопровод в сёлах")]


def p(**kw):
    """реакции партий по архетипам Молдовы -> {слот: значение}"""
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
        val = round(d * k * gdp / 100.0, 2)
        out.append({"key": key, "op": op, "val": float(val), "abs": True,
                    "text": "%s %s %s млрд € в год" % (nm, "не ниже" if op == ">=" else "не выше", ("%.2f" % val).replace(".", ","))})
    return out


def min_special(slot_archs):
    out = {}
    for s, a in enumerate(slot_archs):
        for (m, spec, title) in ARCH_SPECIAL.get(a, []):
            d = dict(spec); d["t"] = title
            out["%d:%d" % (m, s)] = d
    return out
