# Эстония (EE), январь 2026. Сборка из ee_core.py / ee_laws.py / ee_events.py (см. docs/NEWC_SPEC.md); помощники — ee_lib.py (поверх ie_lib.py).
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, ".."))
import datio
from ee_lib import *
from ee_core import C
import ee_laws as L
import ee_events as EV

bias, T_ = calibrate(C)          # подгоняет C["regions"][i]["loy"]
P = C["policy"]; M = C["macro"]; gdp = M["gdp"]


def col(c): return {"__c": [c[0], c[1], c[2], 1]}


POLICY_BASE = [("income", "Подоходный налог", "tax"), ("social", "Взносы в соцстрахование", "tax"), ("corp", "Налог на прибыль", "tax"),
               ("vat", "НДС и акцизы", "tax"), ("emit", "Эмиссия денег (ЕЦБ)", "tax"), ("pensions", "Пенсии", "spend"), ("benefits", "Пособия и соцпомощь", "spend"),
               ("edu", "Образование и наука", "spend"), ("health", "Здравоохранение", "spend"), ("army", "Вооружённые силы и НАТО", "spend"), ("police", "Полиция, погранохрана и суды", "spend"),
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

OTHER0 = 2.8

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

# торговля: млрд € в год, товары + услуги (порядки величин 2024 года по данным Статистического департамента и Банка Эстонии)
WORLD = {
    "name": "Эстония", "cap": "Таллин", "latlon": (59.44, 24.75), "pop": 1.37, "gdp": 41.5, "debt": 10.0, "growth": 1.6, "infl": 3.8, "unemp": 7.3, "def": 3.5,
    "stab": 62, "appr": 20,
    "gov": "правительство Михала: Партия реформ и «Эстония 200»",
    "gov_party": "Партия реформ", "pot": 2.2, "ecb_w": 0.003,
    "stance": {"eu": 0.5, "aus": 0.5, "trd": 0.7, "brd": -0.1, "nuk": 0.3},
    "desc": "Самая северная из стран Балтии, член ЕС, еврозоны и НАТО на границе с Россией: цифровое государство с e-Residency и интернет-голосованием, родина Skype и Bolt, оборона свыше 5 % ВВП и британский батальон НАТО в Тапа. Для партнёров Эстония — самый громкий голос против Кремля и за Украину, бережливая к долгам, но с высокой инфляцией, болезненным вопросом русскоязычного меньшинства и правительством с рекордно низким рейтингом.",
    "leader": "Премьер-министр Эстонии",
    "pn": ["Реформа", "E200", "SDE", "Isamaa", "Центр", "ERK", "Прочие", "Parem", "Союзы", "EKRE"],
    "eu": True, "euro": True,
    "likes": "твёрдость в отношении России и помощь Украине, оборонные расходы и присутствие союзников на восточном фланге, цифровые решения и единый рынок, Rail Baltica",
    "dislikes": "«бизнес как обычно» с Москвой и вето на санкции, медлительность ЕС в обороне, общие налоги ЕС, климатические правила, бьющие по сланцевому Ида-Вирумаа",
    "open": 0.75, "stance0": 0.2, "ccol": (0.30, 0.50, 0.80, 1.0),
    "rel": {"DE": 82, "FR": 78, "NL": 78, "BE": 76, "LU": 75, "AT": 70, "CH": 70, "CZ": 78, "DK": 84, "ES": 72, "IT": 72, "NO": 84, "PL": 86, "PT": 72,
            "SE": 88, "GB": 86, "IE": 74, "SI": 72, "SK": 55, "HU": 45, "FI": 94, "HR": 72, "RS": 45, "BA": 58, "ME": 64, "MK": 62, "AL": 64, "XK": 66,
            "BG": 68, "RO": 74, "GR": 68, "LV": 92, "LT": 90},
    "trade_x": {"DE": 1.6, "FR": 0.4, "NL": 0.8, "BE": 0.3, "LU": 0.1, "AT": 0.2, "CH": 0.3, "CZ": 0.25, "DK": 0.8, "ES": 0.3, "IT": 0.3, "NO": 0.9, "PL": 0.8,
                "PT": 0.08, "SE": 2.6, "GB": 0.8, "IE": 0.4, "SI": 0.03, "SK": 0.06, "HU": 0.08, "FI": 4.6, "HR": 0.03, "RS": 0.02, "BA": 0.01, "ME": 0.01,
                "MK": 0.01, "AL": 0.01, "XK": 0.01, "BG": 0.04, "RO": 0.08, "GR": 0.05, "LV": 2.6, "LT": 1.6},
    "trade_m": {"DE": 2.6, "FR": 0.5, "NL": 1.1, "BE": 0.5, "LU": 0.1, "AT": 0.3, "CH": 0.2, "CZ": 0.4, "DK": 0.6, "ES": 0.3, "IT": 0.6, "NO": 0.4, "PL": 1.8,
                "PT": 0.05, "SE": 1.6, "GB": 0.6, "IE": 0.5, "SI": 0.05, "SK": 0.15, "HU": 0.2, "FI": 3.8, "HR": 0.03, "RS": 0.02, "BA": 0.01, "ME": 0.01,
                "MK": 0.01, "AL": 0.01, "XK": 0.01, "BG": 0.06, "RO": 0.1, "GR": 0.06, "LV": 1.6, "LT": 2.4},
}
ELEC = {"sys": "Пропорциональная система: 101 место по 12 многомандатным округам с компенсационными мандатами по общенациональным спискам, барьер 5 %; можно голосовать через интернет", "turn": 0.63,
        "note": "Рийгикогу однопалатный (101 депутат) избирается на 4 года, следующие выборы — в марте 2027 года; больше половины избирателей голосуют электронно. Президента избирает Рийгикогу большинством 2/3 (68 голосов) в трёх турах, при неудаче — коллегия выборщиков из депутатов и представителей самоуправлений; срок — 5 лет, не более двух сроков подряд.",
        "head": "indirect", "title": "президента Республики", "title_n": "Президент Эстонии", "term": 60, "first": 8,
        "body": "депутаты Рийгикогу, а при неудаче — коллегия выборщиков с представителями самоуправлений", "ele_x": 1.0, "ele_add": 0,
        "need": [0.667, 0.667, 0.667, 0.5, 0.0], "secret": 0.05, "cand0": "Кандидат Партии реформ"}
RAD_CUR = "Парламентская республика"
MONARCHY = False
