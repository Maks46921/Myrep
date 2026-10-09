# Румыния (RO), январь 2026. Сборка из ro_core.py / ro_laws.py / ro_events.py (см. docs/NEWC_SPEC.md); общие помощники — ro_lib.py (поверх ie_lib.py).
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, ".."))
from ro_lib import *
from ro_core import C
import ro_laws as L
import ro_events as EV


# 0 НЛП, 1 СДП, 2 СРС, 3 SOS Румыния, 4 ПОТ, 5 SENS, 6 прочие, 7 нацменьшинства, 8 ДСВР, 9 АУР
SLOT_ARCH = ["own", "soc", "lib", "popr", "popl", "green", "none", "euro", "region", "none"]
ARCHS = list(SLOT_KEY)
bias, T_ = calibrate(C)          # подгоняет C["regions"][i]["loy"]
P = C["policy"]; M = C["macro"]; gdp = M["gdp"]


def col(c): return {"__c": [c[0], c[1], c[2], 1]}


POLICY_BASE = [("income", "Подоходный налог", "tax"), ("social", "Взносы в соцстрахование", "tax"), ("corp", "Налог на прибыль", "tax"),
               ("vat", "НДС и акцизы", "tax"), ("emit", "Эмиссия денег (НБР)", "tax"), ("pensions", "Пенсии", "spend"), ("benefits", "Пособия и соцпомощь", "spend"),
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

# прочие доходы (фонды ЕС, неналоговые доходы, дивиденды госкомпаний), % ВВП — подогнано так, чтобы стартовый дефицит ≈ def_target
OTHER0 = 9.1

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

# торговля: товары + услуги, млрд € в год (оценки по INS/Eurostat 2024, округлено). trade_x — экспорт Румынии в страну, trade_m — импорт из неё.
WORLD = {
    "name": "Румыния", "cap": "Бухарест", "latlon": (44.43, 26.10), "pop": 19.0, "gdp": 375.0, "debt": 225.0, "growth": 0.7, "infl": 9.7, "unemp": 6.0, "def": 6.0,
    "stab": 55, "appr": 30,
    "gov": "правительство Боложана: НЛП, СДП, СРС, ДСВР и депутаты нацменьшинств",
    "gov_party": "Национал-либеральная партия", "pot": 2.6, "ecb_w": 0.0,
    "stance": {"eu": 0.6, "aus": 0.4, "trd": 0.4, "brd": -0.2, "nuk": 0.7},
    "desc": "Крупнейшая страна Юго-Восточной Европы в ЕС и НАТО с собственной валютой — леем: быстрорастущая экономика с автопромом Dacia и Ford, IT-сектором и газом Чёрного моря, но с самым большим бюджетным дефицитом в Евросоюзе. Румыния — опора восточного фланга НАТО и тыл Украины, покровитель Молдовы; после аннулированных выборов 2024 года и подъёма ультраправого АУР партнёры следят за её политической устойчивостью.",
    "leader": "Премьер-министр Румынии",
    "pn": ["НЛП", "СДП", "СРС", "SOS", "ПОТ", "SENS", "Прочие", "Меньш.", "ДСВР", "АУР"],
    "eu": True, "euro": False,
    "likes": "солидарность с восточным флангом НАТО и Украиной, поддержка Молдовы на пути в ЕС, инвестиции в энергетику и инфраструктуру, уважение к роли Румынии в Шенгене и регионе Чёрного моря",
    "dislikes": "двойные стандарты к «новым» членам ЕС, споры о Шенгене и дефиците, давление Будапешта по венгерской общине, российские дроны и дезинформация, дешёвое украинское зерно на своём рынке",
    "open": 0.70, "stance0": 0.1, "ccol": (0.66, 0.60, 0.35, 1.0),
    "rel": {"DE": 78, "FR": 82, "NL": 58, "BE": 72, "LU": 70, "CH": 68, "AT": 60, "PL": 82, "CZ": 74, "DK": 70, "NO": 68, "SE": 70, "IT": 76, "ES": 76, "PT": 72,
            "GB": 74, "IE": 70, "SI": 72, "SK": 70, "HU": 56, "FI": 72, "HR": 72, "RS": 72, "BA": 62, "ME": 64, "MK": 64, "AL": 64, "XK": 40, "BG": 78, "GR": 76,
            "EE": 72, "LV": 72, "LT": 74},
    "trade_x": {"DE": 24.0, "FR": 7.5, "NL": 4.0, "BE": 2.5, "LU": 0.5, "CH": 2.0, "AT": 4.0, "PL": 4.5, "CZ": 3.5, "DK": 0.8, "NO": 0.4, "SE": 1.2, "IT": 11.0, "ES": 3.5,
                "PT": 0.6, "GB": 5.0, "IE": 1.2, "SI": 0.8, "SK": 2.0, "HU": 8.0, "FI": 0.4, "HR": 0.8, "RS": 2.0, "BA": 0.4, "ME": 0.1, "MK": 0.4, "AL": 0.3, "XK": 0.2,
                "BG": 5.0, "GR": 1.8, "EE": 0.2, "LV": 0.2, "LT": 0.4},
    "trade_m": {"DE": 25.0, "FR": 6.5, "NL": 6.0, "BE": 2.8, "LU": 0.8, "CH": 2.2, "AT": 5.5, "PL": 8.0, "CZ": 4.5, "DK": 0.8, "NO": 0.4, "SE": 1.2, "IT": 11.0, "ES": 3.5,
                "PT": 0.5, "GB": 2.5, "IE": 1.5, "SI": 1.0, "SK": 3.0, "HU": 9.5, "FI": 0.6, "HR": 0.6, "RS": 1.5, "BA": 0.2, "ME": 0.05, "MK": 0.2, "AL": 0.1, "XK": 0.05,
                "BG": 5.5, "GR": 2.5, "EE": 0.2, "LV": 0.2, "LT": 0.5},
}
# президент избирается прямым голосованием в два тура на 5 лет: Никушор Дан вступил в должность 26 мая 2025 года -> следующие выборы около мая 2030 года (52-й месяц игры)
ELEC = {"sys": "Пропорциональная система по 43 округам (41 жудец, Бухарест и диаспора): барьер 5 % для партий и 8–10 % для альянсов, отдельные места для 18 национальных меньшинств",
        "turn": 0.52,
        "note": "Парламент двухпалатный: Палата депутатов (331) и Сенат (134) избираются одновременно на 4 года; диаспора избирает 4 депутатов и 2 сенаторов. Президент избирается прямым голосованием в два тура на 5 лет (не более двух сроков), назначает премьер-министра и представляет страну в Европейском совете и НАТО.",
        "head": "direct", "title": "президента Румынии", "title_n": "Президент Румынии", "term": 60, "first": 52, "cand0": "Кандидат вашей партии"}
RAD_CUR = "Полупрезидентская республика"
MONARCHY = False
