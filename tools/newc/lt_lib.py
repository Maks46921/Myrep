# Помощники для данных Литвы: всё общее берём из ie_lib (V, T, g, calibrate, TRAITS, MIN_BASE ...) и sk_lib (архетипы lib/euro/popl),
# переопределяем раскладку слотов, особые министерства и требования партий.
import ie_lib
import sk_lib
from ie_lib import *   # noqa: F401,F403

# Слоты Литвы: 0 ЛСДП(own) 1 Союз Отечества TS-LKD(cons) 2 «Заря Немана»(popr) 3 Демократы «Во имя Литвы»(soc) 4 ЛВЖС(popl)
# 5 Либеральное движение(lib) 6 прочие(oth) 7 Партия свободы(euro) 8 ИАПЛ–СХС(region) 9 Национальное объединение(prot)
SLOT_KEY = ["own", "cons", "popr", "soc", "popl", "lib", "oth", "euro", "region", "prot"]


def p(**kw):
    """реакции партий по архетипам Литвы -> {слот: значение}; числовые ключи — слоты"""
    out = {}
    for s, k in enumerate(SLOT_KEY):
        if k in kw:
            out[s] = float(kw[k])
    for k, v in kw.items():
        if k.isdigit():
            out[int(k)] = float(v)
    return out


ARCH_SPECIAL = dict(sk_lib.ARCH_SPECIAL)
ARCH_SPECIAL.update({
    # «Заря Немана» держит сельское хозяйство и окружающую среду
    "popr": [(2, {"a": {"sec_bonus": 3.0, "reg_unrest_shift": -2.0, "mood_shift": -0.2, "gb_Силовики": 1.5}}, "Жёсткий порядок"),
             (9, {"a": {"equal_shift": 1.5, "gb_Пенсионеры": 2.0, "gb_Рабочие": 1.0}}, "Социальный национализм"),
             (6, {"a": {"gb_Село": 2.5, "reg_unrest_shift": -0.5}}, "Хозяин хуторов"),
             (7, {"a": {"gb_Село": 1.0, "growth_bonus": 0.02}, "x": {"env_eff": 0.96}}, "Природа без запретов")],
    # ЛВЖС: экономика и инновации, село, «трезвая Литва»
    "popl": [(5, {"a": {"growth_bonus": 0.04, "gb_Село": 1.5, "reg_dev_bonus": 1.0}}, "Экономика регионов"),
             (6, {"a": {"gb_Село": 3.0, "reg_unrest_shift": -0.5}}, "Аграрный лоббист"),
             (3, {"x": {"health_eff": 1.05}, "a": {"gb_Пенсионеры": 1.0}}, "Трезвость и профилактика")],
    # Избирательная акция поляков Литвы: юстиция, школы меньшинств, Виленский край
    "region": [(10, {"a": {"corr_shift": -1.0, "reg_unrest_shift": -1.5, "auto_shift": 2.0}}, "Права меньшинств"),
               (4, {"x": {"edu_eff": 1.03}, "a": {"reg_unrest_shift": -1.0}}, "Школы меньшинств"),
               (8, {"a": {"reg_dev_bonus": 2.0, "reg_unrest_shift": -1.5, "auto_shift": 3.0, "eff_bonus": -0.003}}, "Интересы Виленского края")],
})
ARCH_DEMANDS = dict(sk_lib.ARCH_DEMANDS)
ARCH_DEMANDS.update({
    # партнёры по стартовой коалиции — требования выполнены со старта (множитель ≤ 1 для «не ниже»)
    "popr": [("benefits", ">=", 0.98, True, "пособия и соцподдержка"), ("police", ">=", 0.98, True, "полиция и пограничники")],
    "popl": [("subs", ">=", 0.97, True, "поддержка села и фермеров"), ("health", ">=", 0.98, True, "здравоохранение")],
    "region": [("edu", ">=", 0.97, True, "образование (школы меньшинств)")],
    "cons": [("army", ">=", 1.02, True, "оборона"), ("admin", "<=", 0.98, True, "госаппарат")],
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
