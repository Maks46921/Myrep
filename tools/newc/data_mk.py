# Северная Македония (MK), январь 2026. Сборка из mk_core.py / mk_laws.py / mk_events.py (см. docs/NEWC_SPEC.md); общие помощники — mk_lib.py (поверх ie_lib.py).
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, ".."))
from mk_lib import *
from mk_core import C
import mk_laws as L
import mk_events as EV


# 0 ВМРО-ДПМНЕ, 1 ЗНАМ, 2 СДСМ, 3 ВЛЕН, 4 ДУИ–НАИ, 5 СПМ и общины, 6 прочие, 7 суверенисты, 8 ДОМ и ЛДП, 9 Левица
# SLOT_ARCH и ARCHS — из mk_lib
bias, T_ = calibrate(C)          # подгоняет C["regions"][i]["loy"]
P = C["policy"]; M = C["macro"]; gdp = M["gdp"]


def col(c): return {"__c": [c[0], c[1], c[2], 1]}


POLICY_BASE = [("income", "Подоходный налог", "tax"), ("social", "Взносы в соцстрахование", "tax"), ("corp", "Налог на прибыль", "tax"),
               ("vat", "НДС и акцизы", "tax"), ("emit", "Эмиссия денег (Народный банк)", "tax"), ("pensions", "Пенсии", "spend"), ("benefits", "Пособия и соцпомощь", "spend"),
               ("edu", "Образование и наука", "spend"), ("health", "Здравоохранение", "spend"), ("army", "Армия и НАТО", "spend"), ("police", "Полиция и суды", "spend"),
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

# прочие доходы (неналоговые доходы, гранты ЕС и План роста, дивиденды госкомпаний, доходы общин), % ВВП
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

# торговля: товары + услуги, млрд € в год (оценки по Госстату и Народному банку 2024, округлено; Германия — главный покупатель продукции технологических зон;
# вне игры — Китай, Турция, США, Великобритания и др.)
WORLD = {
    "name": "Северная Македония", "cap": "Скопье", "latlon": (41.99, 21.43), "pop": 1.84, "gdp": 16.5, "debt": 62.7, "growth": 2.8, "infl": 3.6, "unemp": 11.3, "def": -4.5,
    "stab": 52, "appr": 40,
    "gov": "правительство Христиана Мицкоского (ВМРО-ДПМНЕ, ВЛЕН, ЗНАМ; 78 из 120 мест)",
    "gov_party": "ВМРО-ДПМНЕ", "pot": 3.0, "ecb_w": 0.0,
    "stance": {"eu": 0.2, "aus": 0.3, "trd": 0.6, "brd": 0.3, "nuk": 0.0},
    "desc": "Небольшая страна-кандидат в ЕС и член НАТО с 2020 года, сменившая название по Преспанскому соглашению с Грецией. Около четверти населения — албанцы, "
            "права которых закреплены Охридским соглашением 2001 года. Экономика держится на технологических зонах с немецкими поставщиками автопрома, "
            "денаре, привязанном к евро, и денежных переводах эмигрантов. Переговоры с ЕС заблокированы спором с Болгарией о языке и истории.",
    "leader": "Премьер-министр Северной Македонии",
    "pn": ["ВМРО", "ЗНАМ", "СДСМ", "ВЛЕН", "ДУИ", "СПМ", "Прочие", "Сувер.", "ДОМ", "Левица"],
    "eu": False, "euro": False,
    "likes": "открытие переговоров с ЕС без «новых условий», инвестиции в коридоры VIII и X, рабочие визы для граждан, уважение к македонскому языку и идентичности",
    "dislikes": "болгарское вето и споры об истории, разговоры о «Великой Албании», возврат к спору об имени, нотации о коррупции",
    "open": 0.75, "stance0": 0.0, "ccol": (0.85, 0.20, 0.15, 1.0),
    "rel": {"DE": 70, "FR": 60, "NL": 58, "BE": 58, "LU": 58, "CH": 64, "AT": 64, "PL": 58, "CZ": 60, "DK": 56, "NO": 58, "SE": 60, "IT": 64, "ES": 58, "PT": 56,
            "GB": 66, "IE": 56, "SI": 72, "SK": 58, "HU": 72, "FI": 56, "HR": 66, "RS": 70, "BA": 66, "ME": 70, "AL": 60, "XK": 56, "GR": 50, "BG": 35, "RO": 60,
            "EE": 54, "LV": 54, "LT": 54},
    "trade_x": {"DE": 4.6, "FR": 0.1, "NL": 0.2, "BE": 0.3, "LU": 0.01, "CH": 0.1, "AT": 0.2, "PL": 0.3, "CZ": 0.3, "DK": 0.03, "NO": 0.02, "SE": 0.05, "IT": 0.4, "ES": 0.2,
                "PT": 0.02, "GB": 0.4, "IE": 0.02, "SI": 0.15, "SK": 0.1, "HU": 0.5, "FI": 0.02, "HR": 0.3, "RS": 0.9, "BA": 0.2, "ME": 0.1, "AL": 0.2, "XK": 0.5, "GR": 0.6,
                "BG": 0.6, "RO": 0.3, "EE": 0.01, "LV": 0.01, "LT": 0.01},
    "trade_m": {"DE": 1.9, "FR": 0.2, "NL": 0.3, "BE": 0.2, "LU": 0.01, "CH": 0.1, "AT": 0.3, "PL": 0.4, "CZ": 0.2, "DK": 0.03, "NO": 0.02, "SE": 0.05, "IT": 0.6, "ES": 0.15,
                "PT": 0.02, "GB": 1.5, "IE": 0.02, "SI": 0.2, "SK": 0.1, "HU": 0.3, "FI": 0.02, "HR": 0.2, "RS": 1.2, "BA": 0.2, "ME": 0.03, "AL": 0.1, "XK": 0.1, "GR": 1.4,
                "BG": 0.7, "RO": 0.3, "EE": 0.01, "LV": 0.01, "LT": 0.01},
}
# Президента избирают прямым голосованием на 5 лет (два тура; для избрания во втором туре нужна явка не ниже 40 %).
# Гордана Силяновская-Давкова избрана 8 мая 2024 года -> следующие выборы около апреля 2029 года (40-й месяц).
ELEC = {"sys": "Пропорциональная система в едином общенациональном округе (с 2024 года): 120 мест по методу д'Ондта без барьера, плюс до 3 мест для диаспоры (сейчас не замещаются)", "turn": 0.55,
        "note": "Однопалатное Собрание (120 депутатов) избирается на 4 года. По закону о двойном большинстве («бадинтеровское» большинство) законы о языках, культуре и местном "
                "самоуправлении требуют также большинства депутатов от общин-меньшинств. Президент избирается прямым голосованием на 5 лет; во втором туре нужна явка 40 %.",
        "head": "direct", "title": "президента Республики", "title_n": "Президент Республики Северная Македония", "term": 60, "first": 40, "cand0": "Кандидат ВМРО-ДПМНЕ"}
RAD_CUR = "Парламентская республика"
MONARCHY = False
