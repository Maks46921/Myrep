# Общие помощники для данных Ирландии (перенесены из старого конвейера datagen_legacy и упрощены).
import json
GROUPS = ["Рабочие", "Бизнес", "Пенсионеры", "Молодёжь", "Бюджетники", "Село", "Силовики", "Экологи"]
# короткие имена групп для компактной записи
_G = {"Р": "Рабочие", "Б": "Бизнес", "П": "Пенсионеры", "М": "Молодёжь", "Бю": "Бюджетники", "С": "Село", "Си": "Силовики", "Э": "Экологи"}


def g(**kw):
    """реакции групп: g(Р=2, Б=-1) -> {'Рабочие': 2.0, 'Бизнес': -1.0}"""
    return {_G[k]: float(v) for k, v in kw.items()}


# архетип слота -> ключ ps. Слоты Ирландии: 0 FF(own) 1 FG(cons) 2 Lab(soc) 3 SD(left) 4 Gr(green) 5 II(popr) 6 прочие(oth) 7 Aontú(popr) 8 независимые(region) 9 SF(prot)
SLOT_KEY = ["own", "cons", "soc", "left", "green", "popr", "oth", "popr", "region", "prot"]


def p(**kw):
    """реакции партий по архетипам; числовые ключи (слоты) задаются через p(**{'6': 2})"""
    out = {}
    for s, k in enumerate(SLOT_KEY):
        if k in kw:
            out[s] = float(kw[k])
    for k, v in kw.items():
        if k.isdigit():
            out[int(k)] = float(v)
    return out


def V(n, d, c=None, s=None, a=None, ps=None, st=None, rg=None, set=None, tag=None):
    v = {"n": n, "d": d}
    if c is not None: v["c"] = float(c)
    if s: v["s"] = s
    if a: v["a"] = a
    if st: v["st"] = st
    if rg: v["rg"] = rg
    if set: v["set"] = set
    if ps is not None: v["ps"] = ps
    if tag: v["tag"] = tag
    return v


def T(id, cat, name, desc, variants, fund=False):
    return {"id": id, "cat": cat, "name": name, "desc": desc, "v": variants, "fund": fund}


# ---------- калибровка региональных смещений (повторяет vote_weights движка) ----------
def _norm(v):
    s = sum(v); return [x / s for x in v]


def calibrate(C):
    R = C["regions"]; n = len(R)
    LEAN = C["lean"]; GW = C["gw"]; GB = C["gb"]; RP = C.get("regional_p", 8)
    POLL = C["poll"]
    E = [_norm([max(x, 0.05) for x in r["E"]]) for r in R]
    pw = [r["pop"] for r in R]; s = sum(pw); pw = [x / s for x in pw]
    fct = [1.0] * 10
    for it in range(300):
        nat = [0.0] * 10
        for i in range(n):
            v = _norm([E[i][q] * fct[q] for q in range(10)])
            for q in range(10): nat[q] += pw[i] * v[q]
        for q in range(10): fct[q] *= (POLL[q] / 100.0) / max(nat[q], 1e-9)
    T_ = [_norm([E[i][q] * fct[q] for q in range(10)]) for i in range(n)]

    def mixn(r):
        m = {gg: GW[gg] * r["mix"].get(gg, 1.0) for gg in GROUPS}
        t = sum(m.values()); return {gg: m[gg] / t for gg in GROUPS}
    for i, r in enumerate(R):
        r["loy"] = max(15.0, min(85.0, C.get("loy_mean", 50.0) + (T_[i][0] * 100.0 - POLL[0]) * 1.2))
    mixes = [mixn(r) for r in R]

    def shares(i, bias):
        r = R[i]; sh = [0.0] * 10
        for gg in GROUPS:
            eff = min(100.0, max(5.0, GB[gg] + (r["loy"] - 50.0) * 0.5))
            w = []
            for q in range(10):
                v = LEAN[gg][q]
                if q == 0: v *= (eff / 50.0) ** 3
                elif q == 9: v *= max(0.2, min(2.0, (100.0 - eff) / 50.0)) ** 2
                elif q == RP: v *= (1.0 + r["unrest"] / 40.0) * (0.6 + 0.9 * r["reg"])
                v *= bias[i][q]
                w.append(v)
            t = sum(w)
            for q in range(10): sh[q] += mixes[i][gg] * w[q] / t
        return sh
    bias = [[1.0] * 10 for _ in range(n)]
    for it in range(500):
        err = 0
        for i in range(n):
            sh = shares(i, bias)
            for q in range(10):
                ratio = T_[i][q] / max(sh[q], 1e-9)
                err = max(err, abs(ratio - 1)); bias[i][q] *= ratio ** 0.7
            m = bias[i][0]; bias[i] = [b / m for b in bias[i]]
        if err < 1e-6: break
    return bias, T_


TRAITS = {
    "none": {"trait": "", "desc": "", "att_w": 0.45, "dem_w": 1.0, "port_w": 1.0, "law_met": 0.0, "law_unmet": 0.0, "base": 0.0, "fat_w": 1.0, "join": -99.0, "rating_w": 0.0},
    "ideo": {"trait": "идеолог", "desc": "Принципиален: сильно переживает из-за невыполненных требований и закона-условия, министерства для него вторичны.", "att_w": 0.45, "dem_w": 1.3, "port_w": 0.7, "law_met": 12.0, "law_unmet": -6.0, "base": -2.0, "fat_w": 1.0, "join": -3.0, "rating_w": 0.0},
    "prag": {"trait": "прагматик", "desc": "Торгуется за портфели: больше всего ценит министерства, к программе относится гибко.", "att_w": 0.40, "dem_w": 0.9, "port_w": 1.5, "law_met": 5.0, "law_unmet": 0.0, "base": 0.0, "fat_w": 1.0, "join": 3.0, "rating_w": 0.0},
    "loyal": {"trait": "лояльный", "desc": "Стабильный союзник: медленно устаёт и не любит громких конфликтов.", "att_w": 0.35, "dem_w": 1.0, "port_w": 1.0, "law_met": 5.0, "law_unmet": 0.0, "base": 5.0, "fat_w": 0.5, "join": 4.0, "rating_w": 0.0},
    "opp": {"trait": "оппортунист", "desc": "Держится за победителя: его довольство растёт и падает вместе с вашим рейтингом, быстро устаёт от коалиции.", "att_w": 0.45, "dem_w": 1.0, "port_w": 1.0, "law_met": 6.0, "law_unmet": -2.0, "base": 0.0, "fat_w": 1.3, "join": 0.0, "rating_w": 0.5},
}
MIN_BASE = [
    ("Сбор налогов и контроль расходов.", {"a": {"eff_bonus": 0.006}}),
    ("Армия и военная безопасность.", {"a": {"sec_bonus": 1.5}}),
    ("Полиция, миграция и порядок в регионах.", {"a": {"sec_bonus": 1.0, "reg_unrest_shift": -1.0}}),
    ("Больницы, страховые кассы и лекарства.", {"x": {"health_eff": 1.04}}),
    ("Школы, университеты и исследования.", {"x": {"edu_eff": 1.04}}),
    ("Промышленность, торговля и энергетика.", {"a": {"growth_bonus": 0.08}}),
    ("Фермеры и продовольствие.", {"a": {"gb_Село": 2.0}}),
    ("Климат и охрана природы.", {"x": {"env_eff": 1.06}}),
    ("Дороги, железные дороги и жильё.", {"a": {"reg_dev_bonus": 1.0, "reg_unrest_shift": -1.0}}),
    ("Пенсии, пособия и защита работников.", {"a": {"equal_shift": 1.5}}),
    ("Суды, прокуратура и борьба с коррупцией.", {"a": {"corr_shift": -2.0}}),
    ("Отношения с ЕС и соседями, дипломатия.", {"a": {"growth_bonus": 0.04, "mood_shift": 0.2, "dip_bonus": 1.0}}),
]
ARCH_SPECIAL = {
    "soc": [(9, {"a": {"equal_shift": 3.0, "gb_Рабочие": 2.0, "growth_bonus": -0.04}}, "Социал-демократ на труде"),
            (1, {"a": {"sec_bonus": 2.5, "gb_Силовики": 1.5}}, "Оборонная реформа"),
            (10, {"a": {"corr_shift": -3.0, "gb_Молодёжь": 0.5}}, "Правовое государство"),
            (7, {"x": {"env_eff": 1.08}, "a": {"gb_Экологи": 1.5}}, "Социальная экополитика"),
            (3, {"x": {"health_eff": 1.08}, "a": {"extra_spend": 0.10}}, "Медицина для всех")],
    "left": [(9, {"a": {"equal_shift": 4.5, "gb_Рабочие": 3.0, "growth_bonus": -0.06}}, "Левая социальная политика"),
             (3, {"x": {"health_eff": 1.10}, "a": {"extra_spend": 0.12}}, "Медицина для всех"),
             (8, {"a": {"reg_dev_bonus": 1.5, "equal_shift": 2.0, "gb_Бизнес": -1.0}}, "Жильё для всех")],
    "green": [(7, {"x": {"env_eff": 1.18}, "a": {"gb_Экологи": 3.0, "growth_bonus": -0.05}}, "Зелёная политика"),
              (11, {"a": {"gb_Экологи": 1.0, "mood_shift": 0.1, "dip_bonus": 1.0}}, "Ценностная дипломатия"),
              (4, {"x": {"edu_eff": 1.08}, "a": {"gb_Молодёжь": 1.5, "gb_Бизнес": -0.5}}, "Образование будущего")],
    "popr": [(2, {"a": {"sec_bonus": 3.0, "reg_unrest_shift": -2.0, "mood_shift": -0.2, "gb_Силовики": 1.5}}, "Жёсткий порядок"),
             (9, {"a": {"equal_shift": 1.5, "gb_Пенсионеры": 2.0, "gb_Рабочие": 1.0}}, "Социальный национализм")],
    "cons": [(0, {"a": {"eff_bonus": 0.008, "equal_shift": -0.5}}, "Консервативные финансы"),
             (2, {"a": {"sec_bonus": 2.0, "gb_Силовики": 1.5, "reg_unrest_shift": -1.0}}, "Порядок и безопасность"),
             (1, {"a": {"sec_bonus": 2.0, "gb_Силовики": 1.0}}, "Сильная оборона"),
             (6, {"a": {"gb_Село": 2.5, "reg_unrest_shift": -0.5}}, "Аграрный лоббист")],
    "region": [(6, {"a": {"gb_Село": 4.0, "reg_unrest_shift": -1.0, "eff_bonus": -0.003}}, "Аграрный лоббист"),
               (8, {"a": {"reg_dev_bonus": 2.5, "reg_unrest_shift": -2.0, "auto_shift": 4.0, "eff_bonus": -0.004}}, "Интересы регионов")],
}
ARCH_DEMANDS = {
    "soc": [("benefits", ">=", 0.93, True, "пособия"), ("pensions", ">=", 0.89, True, "пенсии")],
    "left": [("benefits", ">=", 1.09, True, "пособия"), ("health", ">=", 1.06, True, "здравоохранение")],
    "green": [("eco", ">=", 1.09, True, "экология и климат"), ("infra", ">=", 1.03, True, "инфраструктура")],
    "popr": [("police", ">=", 1.10, True, "полиция и суды"), ("benefits", "<=", 0.92, True, "пособия")],
    "cons": [("army", ">=", 1.05, True, "армия"), ("police", ">=", 1.05, True, "полиция и суды")],
    "region": [("subs", ">=", 0.96, True, "субсидии")],
}


def numtxt(v):
    return str(int(round(v))) if v >= 40 else ("%.1f" % v)


def demands_list(arch, P, gdp):
    out = []
    for key, op, k, ab, nm in ARCH_DEMANDS.get(arch, []):
        d = P[key]
        if ab:
            val = round(d * k * gdp / 100.0, 0 if gdp > 300 else 1)
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
