# Словения (SI), январь 2026. Сборка из si_core.py / si_laws.py / si_events.py (см. docs/NEWC_SPEC.md); общие помощники — si_lib.py (поверх ie_lib.py).
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, ".."))
from si_lib import *
from si_core import C
import si_laws as L
import si_events as EV


SLOT_ARCH = ["own", "soc", "left", "green", "cons", "popr", "none", "lib", "region", "none"]
ARCHS = ["own", "soc", "left", "green", "cons", "popr", "oth", "lib", "region", "prot"]
bias, T_ = calibrate(C)          # подгоняет C["regions"][i]["loy"]
P = C["policy"]; M = C["macro"]; gdp = M["gdp"]


def col(c): return {"__c": [c[0], c[1], c[2], 1]}


POLICY_BASE = [("income", "Подоходный налог", "tax"), ("social", "Взносы в соцстрахование", "tax"), ("corp", "Налог на прибыль", "tax"),
               ("vat", "НДС и акцизы", "tax"), ("emit", "Эмиссия денег (ЕЦБ)", "tax"), ("pensions", "Пенсии", "spend"), ("benefits", "Пособия и соцпомощь", "spend"),
               ("edu", "Образование и наука", "spend"), ("health", "Здравоохранение", "spend"), ("army", "Вооружённые силы и НАТО", "spend"), ("police", "Полиция и суды", "spend"),
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

OTHER0 = 4.0

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

# торговля: млрд € в год, товары + услуги (оценка по SURS/Eurostat 2024; экспорт в Швейцарию — фармацевтика Lek/Novartis и Krka)
WORLD = {
    "name": "Словения", "cap": "Любляна", "latlon": (46.05, 14.51), "pop": 2.12, "gdp": 71.0, "debt": 47.2, "growth": 1.3, "infl": 2.6, "unemp": 3.8, "def": 2.6,
    "stab": 66, "appr": 28,
    "gov": "правительство Голоба: Движение Свобода, Социал-демократы и Левица",
    "gov_party": "Движение Свобода", "pot": 2.2, "ecb_w": 0.005,
    "stance": {"eu": 0.6, "aus": 0.1, "trd": 0.6, "brd": 0.0, "nuk": 0.6},
    "desc": "Небольшая альпийско-адриатическая страна еврозоны и НАТО, самая богатая из бывших республик Югославии: экспортная промышленность (фармацевтика, автокомпоненты, бытовая техника), порт Копер и атомная станция Кршко. Для соседей Словения — надёжный транзитный узел и сторонник расширения ЕС на Балканы, но с шумной внутренней политикой и затяжным пограничным спором с Хорватией.",
    "leader": "Председатель правительства (премьер-министр) Словении",
    "pn": ["Свобода", "SD", "Левица", "Весна", "NSi", "SDS", "Прочие", "Демократы", "Общины", "Resni.ca"],
    "eu": True, "euro": True,
    "likes": "поддержка расширения ЕС на Западные Балканы, транзит через порт Копер, атомная энергетика без выбросов, взвешенная позиция в спорах ЕС",
    "dislikes": "пограничный контроль Италии и Австрии, медленные реформы и бюджетный дефицит, «идеологические» шаги во внешней политике, спор о Пиранском заливе",
    "open": 0.85, "stance0": 0.1, "ccol": (0.35, 0.55, 0.75, 1.0),
    "rel": {"DE": 80, "FR": 76, "NL": 74, "BE": 76, "LU": 75, "CH": 74, "AT": 80, "PL": 72, "CZ": 76, "DK": 74, "NO": 72, "SE": 74, "IT": 78, "ES": 78, "PT": 74,
            "GB": 70, "IE": 76, "SK": 78, "HU": 72, "FI": 74},
    "trade_x": {"DE": 10.0, "FR": 2.8, "NL": 1.1, "BE": 0.8, "LU": 0.1, "CH": 10.5, "AT": 5.0, "PL": 2.0, "CZ": 1.4, "DK": 0.3, "NO": 0.2, "SE": 0.6, "IT": 6.5, "ES": 0.9,
                "PT": 0.15, "GB": 0.8, "IE": 0.15, "SK": 1.1, "HU": 2.2, "FI": 0.2},
    "trade_m": {"DE": 9.0, "FR": 2.2, "NL": 1.8, "BE": 1.0, "LU": 0.2, "CH": 9.0, "AT": 5.5, "PL": 1.8, "CZ": 1.4, "DK": 0.4, "NO": 0.2, "SE": 0.5, "IT": 8.5, "ES": 1.0,
                "PT": 0.2, "GB": 0.5, "IE": 0.5, "SK": 1.2, "HU": 2.2, "FI": 0.2},
}
ELEC = {"sys": "Пропорциональная система по 8 избирательным единицам (88 мест, барьер 4 %) и 2 места для итальянской и венгерской общин", "turn": 0.65,
        "note": "Государственное собрание (90 мест) избирается на 4 года; Государственный совет (40 мест) — непрямыми выборами представителей интересов и имеет лишь отлагательное вето. Президент избирается прямым голосованием в два тура на 5 лет (не более двух сроков подряд); голосование необязательно.",
        "head": "direct", "title": "президента Республики", "title_n": "Президент Республики Словения", "term": 60, "first": 22, "cand0": "Кандидат вашей партии"}
RAD_CUR = "Парламентская республика"
MONARCHY = False
