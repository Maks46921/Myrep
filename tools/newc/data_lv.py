# Латвия (LV), январь 2026. Сборка из lv_core.py / lv_laws.py / lv_events.py (см. docs/NEWC_SPEC.md); общие помощники — lv_lib.py (поверх ie_lib.py).
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, ".."))
from lv_lib import *
from lv_core import C
import lv_laws as L
import lv_events as EV


# 0 «Новое Единство», 1 ZZS, 2 «Прогрессивные», 3 Объединённый список, 4 Национальное объединение, 5 «За стабильность!», 6 прочие, 7 «Согласие», 8 «Суверенная власть», 9 LPV
# SLOT_ARCH и ARCHS — из lv_lib
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
    dem.append([] if s == 0 else demands_lv(s, P, gdp))
ministries = [{"name": C["ministries"][i], "desc": MIN_BASE[i][0], "base": MIN_BASE[i][1]} for i in range(12)]

# прочие доходы (фонды ЕС, неналоговые доходы, дивиденды Latvenergo и LVM), % ВВП — подобрано под стартовый дефицит ≈ 3,3 %
OTHER0 = 7.0

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
    "MIN_SPECIAL": min_special_lv(),
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
    "GDP0": gdp, "G_POT": M["G_POT"], "G_NEU": M["G_NEU"], "I_NEU": M["I_NEU"], "I_TGT": M["I_TGT"], "U_NEU": M["U_NEU"], "RATE0": M["RATE0"], "OTHER0": OTHER0,
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
E = [[round(x, 2) for x in r["E"]] for r in C["regions"]]
REG_EVENTS = EV.REG_EVENTS

# торговля: товары + услуги, млрд € в год (оценки по CSP/Банку Латвии/Eurostat 2024, округлено; вне игры — Россия, Беларусь, Украина, США, Китай и др.).
WORLD = {
    "name": "Латвия", "cap": "Рига", "latlon": (56.95, 24.11), "pop": 1.86, "gdp": 43.0, "debt": 48.0, "growth": 1.1, "infl": 3.6, "unemp": 6.9, "def": 3.3,
    "stab": 55, "appr": 25,
    "gov": "коалиция Эвики Силини: «Новое Единство», Союз зелёных и крестьян, «Прогрессивные»",
    "gov_party": "Новое Единство", "pot": 2.2, "ecb_w": 0.003,
    "stance": {"eu": 0.6, "aus": 0.3, "trd": 0.6, "brd": 0.3, "nuk": 0.4},
    "desc": "Средняя из трёх прибалтийских стран — член ЕС, НАТО и еврозоны на границе с Россией и Беларусью: транзитные порты Риги, Вентспилса и Лиепаи, лес и деревообработка, "
            "IT-услуги и банки Риги. После 2022 года Латвия тратит на оборону почти 5 % ВВП, строит Балтийскую линию обороны и ждёт Rail Baltica. Для соседей — надёжный союзник по ЕС "
            "и НАТО, сторонник жёстких санкций против России, но с большой русскоязычной общиной, медленным ростом и тающим населением.",
    "leader": "Президент министров (премьер-министр) Латвии",
    "pn": ["JV", "ZZS", "PRO", "AS", "NA", "S!", "Прочие", "Согласие", "СВ", "LPV"],
    "eu": True, "euro": True,
    "likes": "жёсткие санкции против России, войска союзников в Прибалтике, деньги ЕС на оборону и Rail Baltica, энергетическая независимость, поддержка Украины",
    "dislikes": "торговля с Россией и «особые отношения» с Москвой, вето Венгрии, медленные поставки оружия, разговоры о «зонах влияния», миграционное давление с Беларуси",
    "open": 0.85, "stance0": 0.0, "ccol": (0.62, 0.14, 0.20, 1.0),
    "rel": {"DE": 80, "FR": 76, "NL": 76, "BE": 74, "LU": 74, "CH": 70, "AT": 68, "PL": 84, "CZ": 78, "DK": 82, "NO": 82, "SE": 86, "IT": 72, "ES": 72, "PT": 72,
            "GB": 82, "IE": 76, "SI": 72, "SK": 58, "HU": 42, "FI": 88, "HR": 72, "RS": 45, "BA": 60, "ME": 66, "MK": 66, "AL": 68, "XK": 66, "BG": 68, "RO": 76, "GR": 66,
            "EE": 92, "LT": 92},
    "trade_x": {"DE": 2.2, "FR": 0.5, "NL": 0.9, "BE": 0.3, "LU": 0.1, "CH": 0.3, "AT": 0.2, "PL": 1.3, "CZ": 0.3, "DK": 0.9, "NO": 0.7, "SE": 2.0, "IT": 0.4, "ES": 0.3,
                "PT": 0.05, "GB": 1.2, "IE": 0.2, "SI": 0.05, "SK": 0.1, "HU": 0.1, "FI": 0.9, "HR": 0.03, "RS": 0.02, "BA": 0.01, "ME": 0.01, "MK": 0.01, "AL": 0.01, "XK": 0.01,
                "BG": 0.05, "RO": 0.1, "GR": 0.05, "EE": 3.0, "LT": 4.2},
    "trade_m": {"DE": 2.6, "FR": 0.5, "NL": 1.0, "BE": 0.4, "LU": 0.05, "CH": 0.1, "AT": 0.3, "PL": 2.6, "CZ": 0.4, "DK": 0.5, "NO": 0.4, "SE": 1.1, "IT": 0.6, "ES": 0.4,
                "PT": 0.05, "GB": 0.4, "IE": 0.1, "SI": 0.05, "SK": 0.1, "HU": 0.2, "FI": 1.0, "HR": 0.02, "RS": 0.02, "BA": 0.01, "ME": 0.01, "MK": 0.01, "AL": 0.01, "XK": 0.01,
                "BG": 0.1, "RO": 0.1, "GR": 0.05, "EE": 2.8, "LT": 5.5},
}
# президента избирает Сейм тайным голосованием: в каждом туре нужно не меньше 51 голоса из 100. Эдгар Ринкевич избран 31 мая 2023 года на 4 года ->
# следующие выборы около мая 2027 года (17-й месяц игры).
ELEC = {"sys": "Пропорциональная система: 100 мест по 5 избирательным округам, барьер 5 %, открытые списки (плюсы и вычёркивания)", "turn": 0.59,
        "note": "Однопалатный Сейм (100 депутатов) избирается на 4 года; следующие выборы — 3 октября 2026 года. Президент избирается Сеймом на 4 года (не более двух сроков подряд), "
                "может распустить Сейм только через референдум.",
        "head": "indirect", "title": "президента Государства", "title_n": "Президент Латвийской Республики", "term": 48, "first": 17,
        "body": "депутаты Сейма", "ele_x": 1.0, "ele_add": 0, "need": [0.51, 0.51, 0.51, 0.51, 0.51], "secret": 0.04, "cand0": "Кандидат «Нового Единства»"}
RAD_CUR = "Парламентская республика"
MONARCHY = False
