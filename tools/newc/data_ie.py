# Ирландия (IE), январь 2026. Сборка из ie_core.py / ie_laws.py / ie_events.py (см. docs/NEWC_SPEC.md).
import os, sys, copy
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, ".."))
import datio
from ie_lib import *
from ie_core import C
import ie_laws as L
import ie_events as EV


SLOT_ARCH = ["own", "cons", "soc", "left", "green", "popr", "none", "popr", "region", "none"]
ARCHS = ["own", "cons", "soc", "left", "green", "popr", "oth", "popr", "region", "prot"]
bias, T_ = calibrate(C)          # подгоняет C["regions"][i]["loy"]
P = C["policy"]; M = C["macro"]; gdp = M["gdp"]


def col(c): return {"__c": [c[0], c[1], c[2], 1]}


POLICY_BASE = [("income", "Подоходный налог", "tax"), ("social", "Взносы в соцстрахование", "tax"), ("corp", "Налог на прибыль и торговый налог", "tax"),
               ("vat", "НДС и акцизы", "tax"), ("emit", "Эмиссия денег (ЕЦБ)", "tax"), ("pensions", "Пенсии", "spend"), ("benefits", "Пособия и соцпомощь", "spend"),
               ("edu", "Образование и наука", "spend"), ("health", "Здравоохранение", "spend"), ("army", "Вооружённые силы и НАТО", "spend"), ("police", "Полиция и суды", "spend"),
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
    dem.append([] if s == 0 or a == "none" else demands_list(a, P, gdp))
ministries = [{"name": C["ministries"][i], "desc": MIN_BASE[i][0], "base": MIN_BASE[i][1]} for i in range(12)]

OTHER0 = 2.6

D = {
    "PARTY_NAMES": [p["name"] for p in C["parties"]],
    "PARCH": SLOT_ARCH,
    "PARTY_DESC": [p["desc"] for p in C["parties"]],
    "PARTY_COLORS": [col(p["color"]) for p in C["parties"]],
    "LEAN": C["lean"],
    "HEMI_ORDER": [6, 3, 9, 4, 2, 8, 0, 1, 5, 7],
    "PARTY_LEADERS": [p["leader"] for p in C["parties"]],
    "PARTY_DEMANDS": dem,
    "MINISTRIES": ministries,
    "PARTY_MINISTRIES": [p["min"] for p in C["parties"]],
    "MIN_SPECIAL": min_special(SLOT_ARCH),
    "PARTY_TRAITS": [TRAITS[p["trait"]] for p in C["parties"]],
    "PARTY_LAW_DEMAND": [p["law"] if p["law"] else {} for p in C["parties"]],
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
    "name": "Ирландия", "cap": "Дублин", "latlon": (53.35, -6.26), "pop": 5.4, "gdp": 540.0, "debt": 220.0, "growth": 2.5, "infl": 2.0, "unemp": 4.6, "def": -2.0,
    "stab": 80, "appr": 38,
    "gov": "правительство Мартина: Фианна Фойл и Фине Гэл при поддержке группы независимых",
    "gov_party": "Фианна Фойл", "pot": 2.5, "ecb_w": 0.03,
    "stance": {"eu": 0.8, "aus": 0.3, "trd": 0.8, "brd": 0.3, "nuk": -0.4},
    "desc": "Англоязычная страна еврозоны с самой «открытой» экономикой ЕС: штаб-квартиры американских технологических и фармацевтических гигантов, корпоративный налог 12,5–15 % и ВВП, завышенный транснациональными компаниями. Для соседей Ирландия — союзник по Brexit, нейтральная страна, и пример налоговой конкуренции.",
    "leader": "Таосич — премьер-министр Ирландии",
    "pn": ["FF", "FG", "Lab", "SD", "Зелёные", "II", "PBP и др.", "Aontú", "Нез.", "Шинн Фейн"],
    "eu": True, "euro": True,
    "likes": "налоговая стабильность и предсказуемость, поддержка единого рынка и Brexit-солидарность, помощь Украине без военных поставок, открытость для инвестиций и талантов",
    "dislikes": "ссоры о налогах и «налоговых гаванях», отказ от «тройного замка» и нейтралитета без референдума, дефицит жилья и очереди, давление на американские инвестиции",
    "open": 0.88, "stance0": 0.05, "ccol": (0.30, 0.62, 0.42, 1.0),
    "rel": {"DE": 74, "FR": 80, "NL": 80, "BE": 80, "LU": 76, "CH": 68, "AT": 72, "PL": 72, "CZ": 68, "DK": 82, "NO": 76, "SE": 80, "IT": 72, "ES": 76, "PT": 80, "GB": 68},
    "trade_x": {"DE": 33.0, "FR": 18.0, "NL": 22.0, "BE": 40.0, "LU": 3.0, "CH": 9.0, "AT": 3.0, "PL": 5.0, "CZ": 1.5, "DK": 5.0, "NO": 2.5, "SE": 6.0, "IT": 13.0, "ES": 10.0, "PT": 2.0, "GB": 38.0},
    "trade_m": {"DE": 22.0, "FR": 12.0, "NL": 25.0, "BE": 13.0, "LU": 1.5, "CH": 8.0, "AT": 2.0, "PL": 4.0, "CZ": 1.5, "DK": 3.0, "NO": 3.0, "SE": 4.0, "IT": 7.0, "ES": 6.0, "PT": 1.5, "GB": 38.0},
}
ELEC = {"sys": "Пропорциональная система единственного передаваемого голоса (STV), 43 многомандатных округа", "turn": 0.60,
        "note": "Дойл избирается по STV (3–5 мест в округе), Сенат (60 мест) формируется профессиональными панелями; голосование необязательно. Таосич формально назначается президентом после выбора Дойла.",
        "head": "direct", "title": "президента Ирландии", "title_n": "Президент Ирландии", "term": 84, "first": 82, "cand0": "Кандидат Фианна Фойл"}
RAD_CUR = "Парламентская республика"
MONARCHY = False
