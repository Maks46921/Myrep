# Хорватия (HR), январь 2026. Сборка из hr_core.py / hr_laws.py / hr_events.py (см. docs/NEWC_SPEC.md); помощники — hr_lib.py (поверх ie_lib.py).
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, ".."))
from hr_lib import *
from hr_core import C
import hr_laws as L
import hr_events as EV

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

dem = [demands_slot(s, P, gdp) for s in range(10)]
ministries = [{"name": C["ministries"][i], "desc": MIN_BASE[i][0], "base": MIN_BASE[i][1]} for i in range(12)]

OTHER0 = 7.8

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
    "MIN_SPECIAL": min_special_hr(),
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

# торговля: млрд € в год, товары + услуги (оценка по DZS/Eurostat 2024). Экспорт услуг — в основном туризм (немцы, австрийцы, словенцы, поляки, чехи);
# крупнейшие товарные партнёры — Италия, Германия, Словения, Венгрия, Босния и Герцеговина, Австрия.
WORLD = {
    "name": "Хорватия", "cap": "Загреб", "latlon": (45.81, 15.98), "pop": 3.86, "gdp": 93.0, "debt": 52.0, "growth": 2.9, "infl": 3.6, "unemp": 4.6, "def": 2.9,
    "stab": 62, "appr": 34,
    "gov": "правительство Пленковича: ХДС и Движение Родины при поддержке представителей меньшинств",
    "gov_party": "ХДС", "pot": 2.6, "ecb_w": 0.006,
    "stance": {"eu": 0.4, "aus": 0.2, "trd": 0.5, "brd": -0.3, "nuk": 0.3},
    "desc": "Адриатическая страна еврозоны, Шенгена и НАТО с самым длинным в ЕС побережьем: туризм даёт пятую часть ВВП, LNG-терминал на Крке и нефтепровод JANAF снабжают Центральную Европу. Для соседей Хорватия — страж внешней границы ЕС и покровитель хорватов Боснии и Герцеговины; память о войне 1991–1995 годов до сих пор определяет отношения с Сербией.",
    "leader": "Председатель правительства (премьер-министр) Хорватии",
    "pn": ["ХДС", "СДП", "Можемо", "ДП", "Мост", "Центр", "Прочие", "Меньшинства", "ИДС", "DOMiNO"],
    "eu": True, "euro": True,
    "likes": "энергетический хаб на Крке и JANAF, охрана внешней границы ЕС, поддержка расширения ЕС на Западные Балканы, гостеприимство для туристов и инвесторов",
    "dislikes": "насильственные выдворения мигрантов, споры о Пиранском заливе и INA, давление на Боснию и Герцеговину в вопросе избирательного закона, высокая инфляция и коррупционные скандалы",
    "open": 0.75, "stance0": 0.1, "ccol": (0.70, 0.35, 0.38, 1.0),
    "rel": {"DE": 82, "FR": 80, "NL": 74, "BE": 76, "LU": 76, "CH": 74, "AT": 82, "PL": 80, "CZ": 80, "DK": 74, "NO": 72, "SE": 72, "IT": 78, "ES": 76, "PT": 74,
            "GB": 74, "IE": 74, "SI": 62, "SK": 80, "HU": 68, "FI": 74,
            "RS": 32, "BA": 55, "ME": 52, "MK": 72, "AL": 76, "XK": 76, "BG": 74, "RO": 74, "GR": 74, "EE": 74, "LV": 74, "LT": 76},
    "trade_x": {"DE": 8.0, "FR": 1.3, "NL": 1.1, "BE": 0.6, "LU": 0.1, "CH": 0.9, "AT": 4.0, "PL": 2.2, "CZ": 1.6, "DK": 0.4, "NO": 0.4, "SE": 0.6, "IT": 4.5, "ES": 0.5,
                "PT": 0.1, "GB": 1.6, "IE": 0.3, "SI": 4.5, "SK": 0.9, "HU": 2.8, "FI": 0.2,
                "RS": 1.5, "BA": 3.2, "ME": 0.7, "MK": 0.3, "AL": 0.15, "XK": 0.25, "BG": 0.4, "RO": 0.6, "GR": 0.3, "EE": 0.05, "LV": 0.06, "LT": 0.1},
    "trade_m": {"DE": 6.0, "FR": 1.2, "NL": 1.8, "BE": 1.0, "LU": 0.2, "CH": 0.5, "AT": 3.0, "PL": 1.6, "CZ": 1.2, "DK": 0.3, "NO": 0.3, "SE": 0.4, "IT": 5.0, "ES": 0.8,
                "PT": 0.15, "GB": 0.6, "IE": 0.6, "SI": 4.5, "SK": 0.9, "HU": 3.5, "FI": 0.15,
                "RS": 1.2, "BA": 1.4, "ME": 0.1, "MK": 0.3, "AL": 0.08, "XK": 0.03, "BG": 0.5, "RO": 0.7, "GR": 0.6, "EE": 0.03, "LV": 0.04, "LT": 0.15},
}
ELEC = {"sys": "Пропорциональная система: 140 мест в 10 округах по 14 (метод д'Ондта, барьер 5 % в округе, преференциальный голос), 3 места для диаспоры (XI округ) и 8 мест национальных меньшинств (XII округ)", "turn": 0.62,
        "note": "Сабор однопалатный (151 место), избирается на 4 года; голосование необязательно. Президент Республики избирается прямым голосованием в два тура на 5 лет (не более двух сроков); Зоран Миланович переизбран в январе 2025 года, следующие выборы — на рубеже 2029/2030 годов.",
        "head": "direct", "title": "президента Республики", "title_n": "Президент Республики Хорватия", "term": 60, "first": 47, "cand0": "Кандидат вашей партии"}
RAD_CUR = "Парламентская республика"
MONARCHY = False
