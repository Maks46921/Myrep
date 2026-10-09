# Сербия (RS), январь 2026. Сборка из rs_core.py / rs_laws.py / rs_events.py (см. docs/NEWC_SPEC.md); помощники — rs_lib.py (поверх ie_lib.py).
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, ".."))
import datio
from rs_lib import *
from rs_core import C
import rs_laws as L
import rs_events as EV

# 0 СНС и союзники, 1 СПС–ЕС, 2 ССП, 3 ЗЛФ и ЭВ, 4 НАДА, 5 Мы — Голос народа, 6 прочая оппозиция, 7 ДС, 8 меньшинства, 9 Студенческий список
SLOT_ARCH = ["own", "soc", "lib", "green", "cons", "popr", "none", "left", "region", "none"]
ARCHS = list(SLOT_KEY)
bias, T_ = calibrate(C)          # подгоняет C["regions"][i]["loy"]
P = C["policy"]; M = C["macro"]; gdp = M["gdp"]


def col(c): return {"__c": [c[0], c[1], c[2], 1]}


POLICY_BASE = [("income", "Подоходный налог", "tax"), ("social", "Взносы в соцстрахование", "tax"), ("corp", "Налог на прибыль", "tax"),
               ("vat", "НДС и акцизы", "tax"), ("emit", "Эмиссия денег (НБС)", "tax"), ("pensions", "Пенсии", "spend"), ("benefits", "Пособия и соцпомощь", "spend"),
               ("edu", "Образование и наука", "spend"), ("health", "Здравоохранение", "spend"), ("army", "Вооружённые силы", "spend"), ("police", "Полиция и суды", "spend"),
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

# прочие доходы (неналоговые доходы, дивиденды EPS/Телекома, гранты ЕС, местные сборы), % ВВП — подогнано так, чтобы стартовый дефицит ≈ def_target
OTHER0 = 8.2

D = {
    "PARTY_NAMES": [p["name"] for p in C["parties"]],
    "PARCH": SLOT_ARCH,
    "PARTY_DESC": [p["desc"] for p in C["parties"]],
    "PARTY_COLORS": [col(p["color"]) for p in C["parties"]],
    "LEAN": C["lean"],
    "HEMI_ORDER": C["hemi"],
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

# торговля: товары + услуги, млрд € в год (оценки по РЗС/НБС 2024, округлено). trade_x — экспорт Сербии в страну, trade_m — импорт из неё.
# Крупные партнёры вне игры: Китай (импорт ≈ 6 млрд €), Россия (газ, нефть), Турция, США. Экспорт в Косово почти остановлен запретом Приштины с 2023 года.
WORLD = {
    "name": "Сербия", "cap": "Белград", "latlon": (44.82, 20.46), "pop": 6.6, "gdp": 86.0, "debt": 38.0, "growth": 2.0, "infl": 2.8, "unemp": 8.6, "def": 2.8,
    "stab": 48, "appr": 40,
    "gov": "правительство Мацута: Сербская прогрессивная партия и союзники, социалисты Дачича и партии венгров и бошняков (около 155 из 250 мест)",
    "gov_party": "СНС", "pot": 3.0, "ecb_w": 0.0,
    "stance": {"eu": -0.1, "aus": 0.3, "trd": 0.5, "brd": -0.3, "nuk": 0.4},
    "desc": "Крупнейшая страна Западных Балкан, кандидат в ЕС с собственной валютой (динар) и военным нейтралитетом. Белград балансирует между Брюсселем, Москвой, Пекином и Вашингтоном, не признаёт Косово и не вводит санкций против России; экономика растёт на иностранных инвестициях (автопром, медь, IT), но страну второй год сотрясают студенческие протесты против коррупции.",
    "leader": "Председатель правительства Сербии",
    "pn": ["СНС", "СПС", "ССП", "ЗЛФ", "НАДА", "Мы–ГН", "Прочие", "ДС", "Меньш.", "Студенты"],
    "eu": False, "euro": False,
    "likes": "уважение к территориальной целостности и отказ признавать Косово, инвестиции без политических условий, поддержка сербов в Боснии и Черногории, дешёвый газ и энергетические проекты, ускорение евроинтеграции Западных Балкан",
    "dislikes": "признание Косова и давление по Охридскому соглашению, требования ввести санкции против России, санкции США против НИС, критика выборов и свободы СМИ, напоминания о войнах 1990-х и резолюция о Сребренице",
    "open": 0.62, "stance0": -0.05, "ccol": (0.62, 0.38, 0.38, 1.0),
    "rel": {"DE": 60, "FR": 66, "NL": 52, "BE": 55, "LU": 56, "CH": 68, "AT": 66, "PL": 52, "CZ": 60, "DK": 50, "NO": 54, "SE": 50, "IT": 68, "ES": 72, "PT": 62,
            "GB": 52, "IE": 55, "SI": 64, "SK": 76, "HU": 84, "FI": 48, "HR": 30, "BA": 52, "ME": 50, "MK": 72, "AL": 38, "XK": 6, "BG": 60, "RO": 78, "GR": 80,
            "EE": 40, "LV": 42, "LT": 38},
    "trade_x": {"DE": 5.6, "FR": 0.9, "NL": 0.6, "BE": 0.3, "LU": 0.05, "CH": 0.9, "AT": 1.1, "PL": 1.0, "CZ": 0.9, "DK": 0.2, "NO": 0.15, "SE": 0.5, "IT": 2.3, "ES": 0.6,
                "PT": 0.1, "GB": 0.7, "IE": 0.2, "SI": 0.8, "SK": 0.6, "HU": 1.8, "FI": 0.1, "HR": 1.0, "BA": 2.6, "ME": 1.2, "MK": 1.0, "AL": 0.25, "XK": 0.1, "BG": 0.9,
                "RO": 1.7, "GR": 0.5, "EE": 0.03, "LV": 0.04, "LT": 0.06},
    "trade_m": {"DE": 6.5, "FR": 1.1, "NL": 0.9, "BE": 0.6, "LU": 0.1, "CH": 0.7, "AT": 1.5, "PL": 1.4, "CZ": 1.0, "DK": 0.3, "NO": 0.15, "SE": 0.5, "IT": 2.6, "ES": 0.8,
                "PT": 0.2, "GB": 0.6, "IE": 0.5, "SI": 1.3, "SK": 0.6, "HU": 2.6, "FI": 0.2, "HR": 1.2, "BA": 1.2, "ME": 0.3, "MK": 0.5, "AL": 0.1, "XK": 0.02, "BG": 1.1,
                "RO": 1.4, "GR": 0.7, "EE": 0.03, "LV": 0.03, "LT": 0.05},
}
# Президент избирается прямым голосованием в два тура на 5 лет (не более двух сроков). Второй срок Александра Вучича истекает 31 мая 2027 года:
# выборы — около апреля 2027 года (15-й месяц игры). Вучич переизбираться не может.
ELEC = {"sys": "Пропорциональная система: 250 мест в едином общенациональном округе по закрытым спискам, порог 3 % (для списков национальных меньшинств — естественный порог), метод Д'Ондта",
        "turn": 0.58,
        "note": "Однопалатная Народная скупщина избирается на 4 года, но досрочные выборы — норма (2014, 2016, 2020, 2022, 2023): президент распускает Скупщину по предложению правительства. Президент Республики избирается прямым голосованием в два тура на 5 лет; голосование необязательно. Автономный край Воеводина избирает собственную Скупщину.",
        "head": "direct", "title": "президента Республики", "title_n": "Президент Республики Сербия", "term": 60, "first": 15, "cand0": "Кандидат СНС"}
RAD_CUR = "Парламентская республика"
MONARCHY = False
