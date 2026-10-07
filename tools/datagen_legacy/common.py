# Общие построители данных стран для PolitGame v13
import math, json
GROUPS = ["Рабочие","Бизнес","Пенсионеры","Молодёжь","Бюджетники","Село","Силовики","Экологи"]
POLICY_KEYS = ["income","social","corp","vat","emit","pensions","benefits","edu","health","army","police","infra","eco","subs","admin"]

def f(x, d=2): return ("%." + str(d) + "f") % x
def q(s): return '"' + s.replace('\\','\\\\').replace('"','\\"') + '"'

# ---------- калибровка региональных смещений (повторяет vote_weights движка) ----------
def norm(v):
    s = sum(v); return [x / s for x in v]

def calibrate(C):
    R = C["regions"]; n = len(R)
    LEAN = C["lean"]; GW = C["gw"]; GB = C["gb"]; RP = C.get("regional_p", 8)
    POLL = C["poll"]
    E = [norm([max(x, 0.05) for x in r["E"]]) for r in R]
    pw = [r["pop"] for r in R]; s = sum(pw); pw = [x / s for x in pw]
    # подгонка региональных результатов к национальному опросу
    fct = [1.0] * 10
    for it in range(300):
        nat = [0.0] * 10
        for i in range(n):
            v = norm([E[i][p] * fct[p] for p in range(10)])
            for p in range(10): nat[p] += pw[i] * v[p]
        for p in range(10): fct[p] *= (POLL[p] / 100.0) / max(nat[p], 1e-9)
    T = [norm([E[i][p] * fct[p] for p in range(10)]) for i in range(n)]
    def mixn(r):
        m = {g: GW[g] * r["mix"].get(g, 1.0) for g in GROUPS}
        t = sum(m.values()); return {g: m[g] / t for g in GROUPS}
    for i, r in enumerate(R):
        r["loy"] = max(15.0, min(85.0, C.get("loy_mean", 50.0) + (T[i][0] * 100.0 - POLL[0]) * 1.2))
    mixes = [mixn(r) for r in R]
    def shares(i, bias):
        r = R[i]; sh = [0.0] * 10
        for g in GROUPS:
            eff = min(100.0, max(5.0, GB[g] + (r["loy"] - 50.0) * 0.5))
            w = []
            for p in range(10):
                v = LEAN[g][p]
                if p == 0: v *= (eff / 50.0) ** 3
                elif p == 9: v *= max(0.2, min(2.0, (100.0 - eff) / 50.0)) ** 2
                elif p == RP: v *= (1.0 + r["unrest"] / 40.0) * (0.6 + 0.9 * r["reg"])
                v *= bias[i][p]
                w.append(v)
            t = sum(w)
            for p in range(10): sh[p] += mixes[i][g] * w[p] / t
        return sh
    bias = [[1.0] * 10 for _ in range(n)]
    for it in range(500):
        err = 0
        for i in range(n):
            sh = shares(i, bias)
            for p in range(10):
                ratio = T[i][p] / max(sh[p], 1e-9)
                err = max(err, abs(ratio - 1)); bias[i][p] *= ratio ** 0.7
            m = bias[i][0]; bias[i] = [b / m for b in bias[i]]
        if err < 1e-6: break
    return bias, T

# ---------- шаблоны архетипов (из данных Германии) ----------
ARCH_SPECIAL = {
 "soc": [(9, {"a": {"equal_shift": 3.0, "gb_Рабочие": 2.0, "growth_bonus": -0.04}}, "Социал-демократ на труде"),
         (1, {"a": {"sec_bonus": 2.5, "gb_Силовики": 1.5}}, "Оборонная реформа"),
         (10, {"a": {"corr_shift": -3.0, "gb_Молодёжь": 0.5}}, "Правовое государство"),
         (7, {"x": {"env_eff": 1.08}, "a": {"gb_Экологи": 1.5}}, "Социальная экополитика"),
         (3, {"x": {"health_eff": 1.08}, "a": {"extra_spend": 0.10}}, "Медицина для всех")],
 "lib": [(0, {"a": {"eff_bonus": 0.012, "equal_shift": -1.0}, "x": {"admin_mult": 0.97}}, "Бережливый финансист"),
         (5, {"a": {"growth_bonus": 0.18, "equal_shift": -1.0, "gb_Рабочие": -1.0, "gb_Бизнес": 2.0}}, "Либеральная экономика"),
         (11, {"a": {"growth_bonus": 0.10, "gb_Бизнес": 2.0, "dip_bonus": 1.0}}, "Открытая торговля")],
 "left": [(9, {"a": {"equal_shift": 4.5, "gb_Рабочие": 3.0, "growth_bonus": -0.06}}, "Левая социальная политика"),
          (3, {"x": {"health_eff": 1.10}, "a": {"extra_spend": 0.12}}, "Медицина для всех"),
          (8, {"a": {"reg_dev_bonus": 1.5, "equal_shift": 2.0, "gb_Бизнес": -1.0}}, "Жильё для всех")],
 "green": [(7, {"x": {"env_eff": 1.18}, "a": {"gb_Экологи": 3.0, "growth_bonus": -0.05}}, "Зелёная политика"),
           (11, {"a": {"gb_Экологи": 1.0, "mood_shift": 0.1, "dip_bonus": 1.0}}, "Ценностная дипломатия"),
           (4, {"x": {"edu_eff": 1.08}, "a": {"gb_Молодёжь": 1.5, "gb_Бизнес": -0.5}}, "Образование будущего")],
 "popl": [(9, {"a": {"equal_shift": 2.5, "gb_Пенсионеры": 2.5, "gb_Рабочие": 2.0}}, "Защита работников и пенсионеров"),
          (2, {"a": {"sec_bonus": 3.0, "reg_unrest_shift": -2.0, "mood_shift": -0.2, "gb_Силовики": 1.5}}, "Жёсткий порядок")],
 "popr": [(2, {"a": {"sec_bonus": 3.0, "reg_unrest_shift": -2.0, "mood_shift": -0.2, "gb_Силовики": 1.5}}, "Жёсткий порядок"),
          (9, {"a": {"equal_shift": 1.5, "gb_Пенсионеры": 2.0, "gb_Рабочие": 1.0}}, "Социальный национализм")],
 "cons": [(0, {"a": {"eff_bonus": 0.008, "equal_shift": -0.5}}, "Консервативные финансы"),
          (2, {"a": {"sec_bonus": 2.0, "gb_Силовики": 1.5, "reg_unrest_shift": -1.0}}, "Порядок и безопасность"),
          (1, {"a": {"sec_bonus": 2.0, "gb_Силовики": 1.0}}, "Сильная оборона"),
          (6, {"a": {"gb_Село": 2.5, "reg_unrest_shift": -0.5}}, "Аграрный лоббист")],
 "euro": [(4, {"x": {"edu_eff": 1.10}, "a": {"gb_Молодёжь": 2.5, "corr_shift": -1.0, "gb_Пенсионеры": -1.0}}, "Цифровое образование"),
          (11, {"a": {"growth_bonus": 0.06, "mood_shift": 0.2, "dip_bonus": 2.0}}, "Проевропейский курс")],
 "region": [(6, {"a": {"gb_Село": 4.0, "reg_unrest_shift": -1.0, "eff_bonus": -0.003}}, "Аграрный лоббист"),
            (8, {"a": {"reg_dev_bonus": 2.5, "reg_unrest_shift": -2.0, "auto_shift": 4.0, "eff_bonus": -0.004}}, "Интересы регионов")],
}
# ключи для ps (реакция партий на варианты законов) по архетипам
ARCH_ORDER = ["own","soc","lib","left","green","popl","popr","cons","euro","region","none"]

TRAITS = {
 "none": '{"trait": "", "desc": "", "att_w": 0.45, "dem_w": 1.0, "port_w": 1.0, "law_met": 0.0, "law_unmet": 0.0, "base": 0.0, "fat_w": 1.0, "join": -99.0, "rating_w": 0.0}',
 "ideo": '{"trait": "идеолог", "desc": "Принципиален: сильно переживает из-за невыполненных требований и закона-условия, министерства для него вторичны.", "att_w": 0.45, "dem_w": 1.3, "port_w": 0.7, "law_met": 12.0, "law_unmet": -6.0, "base": -2.0, "fat_w": 1.0, "join": -3.0, "rating_w": 0.0}',
 "prag": '{"trait": "прагматик", "desc": "Торгуется за портфели: больше всего ценит министерства, к программе относится гибко.", "att_w": 0.40, "dem_w": 0.9, "port_w": 1.5, "law_met": 5.0, "law_unmet": 0.0, "base": 0.0, "fat_w": 1.0, "join": 3.0, "rating_w": 0.0}',
 "loyal": '{"trait": "лояльный", "desc": "Стабильный союзник: медленно устаёт и не любит громких конфликтов.", "att_w": 0.35, "dem_w": 1.0, "port_w": 1.0, "law_met": 5.0, "law_unmet": 0.0, "base": 5.0, "fat_w": 0.5, "join": 4.0, "rating_w": 0.0}',
 "opp": '{"trait": "оппортунист", "desc": "Держится за победителя: его довольство растёт и падает вместе с вашим рейтингом, быстро устаёт от коалиции.", "att_w": 0.45, "dem_w": 1.0, "port_w": 1.0, "law_met": 6.0, "law_unmet": -2.0, "base": 0.0, "fat_w": 1.3, "join": 0.0, "rating_w": 0.5}',
}
# Требования к бюджету по архетипам: (ключ, оператор, коэффициент от стартового значения, абсолют?)
ARCH_DEMANDS = {
 "soc": [("benefits", ">=", 0.93, True, "пособия"), ("pensions", ">=", 0.89, True, "пенсии")],
 "lib": [("income", "<=", 0.952, False, "подоходный налог"), ("corp", "<=", 0.9375, False, "налог на прибыль")],
 "left": [("benefits", ">=", 1.09, True, "пособия"), ("health", ">=", 1.06, True, "здравоохранение")],
 "green": [("eco", ">=", 1.09, True, "экология и климат"), ("infra", ">=", 1.03, True, "инфраструктура")],
 "popl": [("pensions", ">=", 1.03, True, "пенсии"), ("army", "<=", 0.91, True, "армия")],
 "popr": [("police", ">=", 1.10, True, "полиция и суды"), ("benefits", "<=", 0.92, True, "пособия")],
 "cons": [("army", ">=", 1.05, True, "армия"), ("police", ">=", 1.05, True, "полиция и суды")],
 "euro": [("edu", ">=", 1.09, True, "образование"), ("admin", "<=", 0.97, True, "госаппарат")],
 "region": [("subs", ">=", 0.96, True, "субсидии")],
 "none": [],
}

def demands_text(arch, P, gdp):
    out = []
    for key, op, k, ab, nm in ARCH_DEMANDS[arch]:
        d = P[key]
        if ab:
            val = round(d * k * gdp / 100.0, 0 if gdp > 300 else 1)
            txt = "%s %s %s млрд € в год" % (nm, "не ниже" if op == ">=" else "не выше", numtxt(val))
            out.append('{"key": "%s", "op": "%s", "val": %s, "abs": true, "text": %s}' % (key, op, f(val, 1), q(txt)))
        else:
            val = round(d * k, 1)
            out.append('{"key": "%s", "op": "%s", "val": %s, "text": %s}' % (key, op, f(val, 1), q("%s %s %s%% ВВП" % (nm, "не выше" if op == "<=" else "не ниже", f(val, 1)))))
    return "[" + ", ".join(out) + "]"

def numtxt(v):
    return str(int(round(v))) if v >= 40 else f(v, 1)

def min_special(archs):
    out = []
    for p, a in enumerate(archs):
        for (m, spec, title) in ARCH_SPECIAL.get(a, []):
            body = json.dumps(spec, ensure_ascii=False).replace("true", "true")
            out.append('\t"%d:%d": %s,' % (m, p, gd(dict(spec, t=title))))
    return "{\n" + "\n".join(out) + "\n}"

def gd(v):
    if isinstance(v, dict):
        return "{" + ", ".join("%s: %s" % (gd(k), gd(x)) for k, x in v.items()) + "}"
    if isinstance(v, (list, tuple)):
        return "[" + ", ".join(gd(x) for x in v) + "]"
    if isinstance(v, bool): return "true" if v else "false"
    if isinstance(v, int): return str(v)
    if isinstance(v, float): return repr(round(v, 4))
    if isinstance(v, str): return q(v)
    return str(v)

def color(c): return "Color(%s, %s, %s)" % tuple(f(x, 2) for x in c)
