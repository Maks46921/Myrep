# Косово (XK), январь 2026. Сборка из xk_core.py / xk_laws.py / xk_events.py (см. docs/NEWC_SPEC.md); общие помощники — xk_lib.py (поверх ie_lib.py).
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, ".."))
from xk_lib import *
from xk_core import C
import xk_laws as L
import xk_events as EV


SLOT_ARCH = ["own", "cons", "lib", "popr", "soc", "euro", "none", "soc", "region", "none"]
ARCHS = ["own", "cons", "lib", "popr", "soc", "euro", "oth", "soc", "region", "prot"]
bias, T_ = calibrate(C)          # подгоняет C["regions"][i]["loy"]
P = C["policy"]; M = C["macro"]; gdp = M["gdp"]


def col(c): return {"__c": [c[0], c[1], c[2], 1]}


POLICY_BASE = [("income", "Подоходный налог", "tax"), ("social", "Взносы в соцстрахование", "tax"), ("corp", "Налог на прибыль", "tax"),
               ("vat", "НДС и акцизы", "tax"), ("emit", "Эмиссия денег (евро в одностороннем порядке)", "tax"), ("pensions", "Пенсии", "spend"), ("benefits", "Пособия и соцпомощь", "spend"),
               ("edu", "Образование и наука", "spend"), ("health", "Здравоохранение", "spend"), ("army", "Силы безопасности", "spend"), ("police", "Полиция и суды", "spend"),
               ("infra", "Инфраструктура и транспорт", "spend"), ("eco", "Климат и экология", "spend"), ("subs", "Субсидии бизнесу и аграриям", "spend"), ("admin", "Госаппарат", "spend")]
policy = []
for k, t, kind in POLICY_BASE:
    lo, hi = C["policy_range"].get(k, (0.0, 0.0)) if k != "emit" else (0.0, 0.0)
    policy.append({"key": k, "title": C["policy_titles"].get(k, t), "min": float(lo), "max": float(hi), "def": 0.0 if k == "emit" else P[k], "kind": kind})

regions = []
for r in C["regions"]:
    pc = r["pcrel"] / (0.6 + 0.8 * r["dev"] / 100.0)
    regions.append({"code": r["code"], "name": r["name"], "short": r["short"], "popm": r["pop"], "pc": round(pc, 3), "dev": float(r["dev"]), "loy": round(r["loy"], 1),
                    "unrest": float(r["unrest"]), "auto": float(r["auto"]), "reg": r["reg"], "tr": r["tr"], "sec": r["sec"], "infra": float(r["infra"]), "edu": float(r["edu"]),
                    "health": float(r["health"]), "env": float(r["env"]), "mix": r["mix"], "desc": r["desc"]})

dem = []
for s, pr in enumerate(C["parties"]):
    a = SLOT_ARCH[s]
    dem.append([] if s == 0 or a == "none" else demands_list(a, P, gdp))
ministries = [{"name": C["ministries"][i], "desc": MIN_BASE[i][0], "base": MIN_BASE[i][1]} for i in range(12)]

OTHER0 = 8.0

D = {
    "PARTY_NAMES": [p_["name"] for p_ in C["parties"]],
    "PARCH": SLOT_ARCH,
    "PARTY_DESC": [p_["desc"] for p_ in C["parties"]],
    "PARTY_COLORS": [col(p_["color"]) for p_ in C["parties"]],
    "LEAN": C["lean"],
    "HEMI_ORDER": C["hemi"],
    "PARTY_LEADERS": [p_["leader"] for p_ in C["parties"]],
    "PARTY_DEMANDS": dem,
    "MINISTRIES": ministries,
    "PARTY_MINISTRIES": [p_["min"] for p_ in C["parties"]],
    "MIN_SPECIAL": min_special(SLOT_ARCH),
    "PARTY_TRAITS": [TRAITS[p_["trait"]] for p_ in C["parties"]],
    "PARTY_LAW_DEMAND": [p_["law"] if p_["law"] else {} for p_ in C["parties"]],
    "MINISTER_NAMES": C["minister_names"],
    "GOV_NAMES": C["gov_names"],
    "REGIONS": regions,
    "REG_BIAS": [[round(x, 3) for x in row] for row in bias],
    "GROUP_WEIGHT": C["gw"],
    "GROUP_BASE": C["gb"],
    "POLICY": policy,
    "MARKETS_OVR": C["markets"],
    "GOODS_OVR": C["goods"],
    "DE_START_SEATS": C["seats"],
    "DE_START_MIN": C["min_start"],
    "DE_JOIN_ADJ": C["join_adj"],
    "SEATS": sum(C["seats"]),
    "REGIONAL_P": C["regional_p"],
    "GDP0": gdp, "G_POT": M["G_POT"], "G_NEU": M["G_NEU"], "I_NEU": M["I_NEU"], "I_TGT": 2.0, "U_NEU": M["U_NEU"], "RATE0": M["RATE0"], "OTHER0": OTHER0,
    "UPPER": C["upper"],
    "MACRO": {"gdp": gdp, "debt": M["debt"], "growth": M["growth"], "infl": M["infl"], "unemp": M["unemp"], "ecb_w": M["ecb_w"], "debt_base": M["debt_base"],
              "debt_thr": M["debt_thr"], "debt_slope": M["debt_slope"], "elapsed": M["elapsed"], "parl_term": M["parl_term"], "threshold": M["threshold"],
              "impeach_seats": M["impeach_seats"], "constr": M["constr"], "minority_ok": M["minority_ok"], "def_target": M["def_target"], "euro": M["euro"], "eu": M["eu"],
              "fiscal_base": M["fiscal_base"], "fiscal_name": M["fiscal_name"], "cb_own": M["cb_own"], "cb_off": M["cb_off"], "crisis_limit": M["crisis_limit"]},
    "TERMS": {**C["terms"], **C["terms_extra"]},
    "INFO": C["info"],
    "COALITION0": C["coalition"],
    "ARCHS": ARCHS,
    "DE_TOPICS": L.DE_TOPICS,
    "DE_PARAM": L.PARAMS,
    "DE_NEW_PARAMS": [],
    "DE_REMOVE": ["central_bank", "pres_term_law", "pres_vote_rule", "export_duty", "tariff_cap", "gov_form", "state_structure", "impeach_rule", "referendum_law", "debt_brake", "auto_policy", "regional_gov_x"],
    "DE_FUND_ADD": L.FUND,
    "LAW_TAGS": L.LAW_TAGS,
    "EVENTS_C": EV.EVENTS_C,
    "NEWS_C": EV.NEWS_C,
    "EVENTS_SPECIAL": [],
}
E = [r["E"] for r in C["regions"]]
REG_EVENTS = EV.REG_EVENTS

# торговля: млрд € в год, товары + услуги (оценка по данным Агентства статистики Косова и Евростата за 2024–2025 годы;
# экспорт в Германию и Швейцарию во многом — поездки диаспоры, импорт из Сербии, Албании, Македонии и Турции — продовольствие, стройматериалы и топливо)
WORLD = {
    "name": "Косово", "cap": "Приштина", "latlon": (42.66, 21.17), "pop": 1.59, "gdp": 11.3, "debt": 17.7, "growth": 3.6, "infl": 4.0, "unemp": 10.8, "def": 0.8,
    "stab": 46, "appr": 48,
    "gov": "правительство Курти: «Самоопределение» с депутатами неалбанских общин и партией Рашича",
    "gov_party": "Самоопределение", "pot": 3.4, "ecb_w": 0.0,
    "stance": {"eu": 0.7, "aus": -0.2, "trd": 0.5, "brd": 0.2, "nuk": 0.0},
    "desc": "Самая молодая и самая бедная страна Европы: независимость с 2008 года, около ста признаний, но ни членства в ООН, ни статуса кандидата в ЕС, ни признания от Сербии и пяти стран союза. "
            "Евро без еврозоны, миротворцы KFOR, разделённая Митровица на севере, рекордные переводы диаспоры и массовый отъезд молодёжи в Германию и Швейцарию. "
            "Для соседей-албанцев — вторая родина, для Белграда — «автономный край», для Брюсселя — трудный, но неизбежный партнёр.",
    "leader": "Премьер-министр Республики Косово",
    "pn": ["Самоопределение", "ДПК", "ДСК", "АБК", "Нисма", "Общины", "Прочие", "Рашич", "Сербский список", "Радикалы"],
    "eu": False, "euro": True,
    "likes": "признание независимости и поддержка заявки в ЕС, НАТО и Совет Европы, визовая либерализация и «План роста», инвестиции в энергетику и дороги, давление на Белград по Баньске и архивам",
    "dislikes": "отзывы признания и «сноски» в документах ЕС, требование Ассоциации сербских общин, «меры» и санкции против Приштины, блокировка в международных организациях, пошлины и проверки на границах соседей",
    "open": 0.70, "stance0": 0.15, "ccol": (0.35, 0.45, 0.70, 1.0),
    "rel": {"DE": 88, "FR": 80, "NL": 78, "BE": 76, "LU": 76, "AT": 82, "CH": 86, "CZ": 76, "DK": 78, "ES": 25, "IT": 78, "NO": 80, "PL": 78, "PT": 72, "SE": 80,
            "GB": 88, "IE": 72, "SI": 85, "SK": 28, "HU": 74, "FI": 76, "HR": 86, "RS": 6, "BA": 30, "ME": 72, "MK": 80, "AL": 96, "BG": 72, "RO": 28, "GR": 34,
            "EE": 78, "LV": 74, "LT": 76},
    "trade_x": {"DE": 0.55, "FR": 0.06, "NL": 0.05, "BE": 0.03, "LU": 0.02, "AT": 0.12, "CH": 0.45, "CZ": 0.03, "DK": 0.02, "ES": 0.03, "IT": 0.15, "NO": 0.02,
                "PL": 0.03, "PT": 0.01, "SE": 0.07, "GB": 0.06, "IE": 0.01, "SI": 0.04, "SK": 0.02, "HU": 0.03, "FI": 0.01, "HR": 0.03, "RS": 0.10, "BA": 0.03,
                "ME": 0.03, "MK": 0.17, "AL": 0.35, "BG": 0.03, "RO": 0.03, "GR": 0.04, "EE": 0.005, "LV": 0.005, "LT": 0.005},
    "trade_m": {"DE": 0.70, "FR": 0.12, "NL": 0.12, "BE": 0.08, "LU": 0.01, "AT": 0.15, "CH": 0.20, "CZ": 0.08, "DK": 0.04, "ES": 0.14, "IT": 0.45, "NO": 0.02,
                "PL": 0.18, "PT": 0.03, "SE": 0.05, "GB": 0.08, "IE": 0.03, "SI": 0.18, "SK": 0.07, "HU": 0.15, "FI": 0.02, "HR": 0.12, "RS": 0.55, "BA": 0.08,
                "ME": 0.05, "MK": 0.45, "AL": 0.55, "BG": 0.12, "RO": 0.10, "GR": 0.35, "EE": 0.01, "LV": 0.01, "LT": 0.02},
}
ELEC = {"sys": "Пропорциональная система в едином округе с открытыми списками (пять преференций, барьер 5 %): 100 мест плюс 20 гарантированных мест общинам — 10 сербам, 4 рома, ашкали и египтянам, 3 боснийцам, 2 туркам, 1 горанцам",
        "turn": 0.48,
        "note": "Собрание Республики Косово (120 депутатов) избирается на 4 года; диаспора голосует по почте, и подсчёт её голосов задерживает результат на недели. Президента избирает само Собрание на 5 лет: в первых двух турах нужно 2/3 всех депутатов (80 голосов, что требует согласия оппозиции), в третьем — большинство всех депутатов. Законы «жизненного интереса» общин требуют двойного большинства. Миротворцы KFOR и миссия EULEX остаются на территории страны.",
        "head": "indirect", "title": "президента Республики", "title_n": "Президент Республики Косово", "term": 60, "first": 4,
        "body": "депутаты Собрания", "ele_x": 1.0, "ele_add": 0, "need": [0.667, 0.667, 0.5], "secret": 0.08, "cand0": "Кандидат «Самоопределения»"}
RAD_CUR = "Парламентская республика"
MONARCHY = False
