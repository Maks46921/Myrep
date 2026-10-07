# Финляндия (FI), январь 2026. Сборка из fi_core.py / fi_laws.py / fi_events.py (см. docs/NEWC_SPEC.md).
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, ".."))
import datio
from fi_lib import *
from fi_core import C
import fi_laws as L
import fi_events as EV

bias, T_ = calibrate(C)          # подгоняет C["regions"][i]["loy"]
P = C["policy"]; M = C["macro"]; gdp = M["gdp"]


def col(c): return {"__c": [c[0], c[1], c[2], 1]}


POLICY_BASE = [("income", "Подоходный налог", "tax"), ("social", "Взносы в соцстрахование", "tax"), ("corp", "Налог на прибыль", "tax"),
               ("vat", "НДС и акцизы", "tax"), ("emit", "Эмиссия денег (ЕЦБ)", "tax"), ("pensions", "Пенсии", "spend"), ("benefits", "Пособия и соцпомощь", "spend"),
               ("edu", "Образование и наука", "spend"), ("health", "Здравоохранение", "spend"), ("army", "Вооружённые силы и НАТО", "spend"), ("police", "Полиция, пограничники и суды", "spend"),
               ("infra", "Инфраструктура и транспорт", "spend"), ("eco", "Климат и экология", "spend"), ("subs", "Субсидии бизнесу и аграриям", "spend"), ("admin", "Госаппарат", "spend")]
policy = []
for k, t, kind in POLICY_BASE:
    lo, hi = C["policy_range"].get(k, (0.0, 0.0)) if k != "emit" else (0.0, 0.0)
    policy.append({"key": k, "title": C["policy_titles"].get(k, t), "min": lo, "max": hi, "def": 0.0 if k == "emit" else P[k], "kind": kind})

regions = []
for r in C["regions"]:
    pc = r["pcrel"] / (0.6 + 0.8 * r["dev"] / 100.0)
    regions.append({"code": r["code"], "name": r["name"], "short": r["short"], "popm": r["pop"], "pc": round(pc, 3), "dev": float(r["dev"]), "loy": round(r["loy"], 1),
                    "unrest": float(r["unrest"]), "auto": float(r["auto"]), "reg": r["reg"], "tr": r["tr"], "sec": r["sec"], "infra": float(r["infra"]), "edu": float(r["edu"]),
                    "health": float(r["health"]), "env": float(r["env"]), "mix": r["mix"], "desc": r["desc"]})

dem = []
for s, pr in enumerate(C["parties"]):
    a = SLOT_ARCH[s]
    dem.append([] if s == 0 or a == "none" else demands_fi(a, P, gdp))
ministries = [{"name": C["ministries"][i], "desc": MIN_BASE[i][0], "base": MIN_BASE[i][1]} for i in range(12)]

OTHER0 = 3.7

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
    "MIN_SPECIAL": min_special_fi(SLOT_ARCH),
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

WORLD = {
    "name": "Финляндия", "cap": "Хельсинки", "latlon": (60.17, 24.94), "pop": 5.6, "gdp": 282.0, "debt": 237.0, "growth": 1.0, "infl": 2.1, "unemp": 10.0, "def": 4.3,
    "stab": 80, "appr": 30,
    "gov": "правительство Орпо: Национальная коалиция, «Финны», Шведская народная партия и христианские демократы",
    "gov_party": "Национальная коалиция", "pot": 1.3, "ecb_w": 0.02,
    "stance": {"eu": 0.3, "aus": 0.7, "trd": 0.7, "brd": -0.2, "nuk": 0.9},
    "desc": "Северная страна еврозоны и новичок НАТО с самой длинной сухопутной границей альянса с Россией: всеобщий призыв, 280-тысячная армия военного времени и закрытые с 2023 года пункты пропуска. Для соседей Финляндия — надёжный, бережливый и немногословный партнёр: «счастливейшая страна мира», но с долгом, безработицей и экономикой, которая третий год стоит на месте.",
    "leader": "Премьер-министр Финляндии",
    "pn": ["Kok", "PS", "SDP", "Vas", "Vihr", "KD", "Прочие", "RKP", "Kesk", "Liik"],
    "eu": True, "euro": True,
    "likes": "твёрдость в отношении России и помощь Украине, бюджетная дисциплина, северное оборонное сотрудничество, атомная энергетика и открытая торговля",
    "dislikes": "общие долги ЕС и «трансферный союз», климатические ограничения для лесов, мягкость к Москве, торговые барьеры и пошлины, задержки с обороной восточного фланга",
    "open": 0.55, "stance0": 0.2, "ccol": (0.55, 0.70, 0.85, 1.0),
    "rel": {"DE": 80, "FR": 78, "NL": 76, "BE": 76, "LU": 75, "AT": 74, "CH": 72, "CZ": 76, "DK": 85, "ES": 74, "IT": 72, "NO": 86, "PL": 84, "PT": 74,
            "SE": 92, "GB": 82, "IE": 76, "SI": 72, "SK": 66, "HU": 52},
    # торговля товарами и услугами, млрд € в год (порядки величин 2024 года по данным Статистического управления и Таможни Финляндии)
    "trade_x": {"DE": 11.0, "FR": 3.5, "NL": 6.5, "BE": 3.0, "LU": 0.4, "AT": 1.2, "CH": 1.5, "CZ": 1.0, "DK": 2.5, "ES": 2.5, "IT": 2.8, "NO": 3.5, "PL": 3.6, "PT": 0.6,
                "SE": 13.0, "GB": 5.0, "IE": 1.2, "SI": 0.2, "SK": 0.4, "HU": 0.6},
    "trade_m": {"DE": 13.5, "FR": 3.0, "NL": 6.0, "BE": 3.5, "LU": 0.6, "AT": 1.5, "CH": 1.5, "CZ": 1.6, "DK": 2.8, "ES": 1.5, "IT": 2.5, "NO": 3.0, "PL": 3.5, "PT": 0.4,
                "SE": 15.0, "GB": 3.5, "IE": 2.0, "SI": 0.15, "SK": 0.6, "HU": 0.8},
}
ELEC = {"sys": "Пропорциональная система по 13 округам, метод Д'Ондта, голос за кандидата (открытые списки)", "turn": 0.72,
        "note": "Эдускунта однопалатная (200 депутатов, один — от Аландских островов по мажоритарной системе). Выборы раз в четыре года, ближайшие — в апреле 2027. Президента избирают прямым голосованием на 6 лет в два тура; он ведёт внешнюю политику вместе с правительством.",
        "head": "direct", "title": "президента Республики", "title_n": "Президент Финляндии", "term": 72, "first": 48, "cand0": "Кандидат Национальной коалиции"}
RAD_CUR = "Парламентская республика"
MONARCHY = False
