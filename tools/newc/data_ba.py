# Босния и Герцеговина (BA), январь 2026. Сборка из ba_core.py / ba_laws.py / ba_events.py (см. docs/NEWC_SPEC.md); общие помощники — ba_lib.py (поверх ie_lib.py).
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, ".."))
from ba_lib import *
from ba_core import C
import ba_laws as L
import ba_events as EV


# 0 ХДЗ БиГ, 1 СДП, 2 СДА, 3 СНСД, 4 НиП, 5 Наша страна, 6 прочие, 7 ДФ и НЕС, 8 СДС и ПДП, 9 протестные списки
# SLOT_ARCH и ARCHS — из ba_lib
bias, T_ = calibrate(C)          # подгоняет C["regions"][i]["loy"]
P = C["policy"]; M = C["macro"]; gdp = M["gdp"]


def col(c): return {"__c": [c[0], c[1], c[2], 1]}


POLICY_BASE = [("income", "Подоходный налог", "tax"), ("social", "Взносы в соцстрахование", "tax"), ("corp", "Налог на прибыль", "tax"),
               ("vat", "НДС и акцизы", "tax"), ("emit", "Эмиссия денег (валютный совет: запрещена)", "tax"), ("pensions", "Пенсии", "spend"), ("benefits", "Пособия и соцпомощь", "spend"),
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

# прочие доходы (неналоговые доходы энтити и кантонов, гранты ЕС и План роста для Западных Балкан, дивиденды «Электропривреды» и «Телекома»), % ВВП
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

# торговля: товары + услуги, млрд € в год (оценки по Агентству статистики БиГ и ЦБ БиГ 2024, округлено; вне игры — Турция, Китай, Россия, США и др.)
WORLD = {
    "name": "Босния и Герцеговина", "cap": "Сараево", "latlon": (43.86, 18.41), "pop": 3.3, "gdp": 29.0, "debt": 26.5, "growth": 2.6, "infl": 3.3, "unemp": 12.4, "def": -2.0,
    "stab": 34, "appr": 28,
    "gov": "Совет министров Борьяны Кришто (ХДЗ БиГ, СНСД, СДП, НиП, Наша страна) без устойчивого большинства после разрыва «Тройки» с СНСД в январе 2025 года",
    "gov_party": "ХДЗ БиГ", "pot": 2.8, "ecb_w": 0.0,
    "stance": {"eu": 0.3, "aus": -0.1, "trd": 0.5, "brd": 0.2, "nuk": 0.0},
    "desc": "Государство двух энтити — Федерации БиГ и Республики Сербской — с округом Брчко и Высоким представителем над всей конструкцией Дейтонского мира. Кандидат в ЕС с 2022 года, "
            "переговоры открыты условно в 2024-м; конвертируемая марка жёстко привязана к евро. Для соседей БиГ — рынок для хорватских и сербских товаров, источник рабочей силы для ЕС "
            "и постоянный риск: споры о сецессии Республики Сербской, хорватском представительстве и роли международного сообщества.",
    "leader": "Председатель Совета министров БиГ",
    "pn": ["ХДЗ", "СДП", "СДА", "СНСД", "НиП", "НС", "Прочие", "ДФ", "СДС", "Платф."],
    "eu": False, "euro": False,
    "likes": "европейские фонды и План роста, безвизовый режим и рабочие визы для граждан, инвестиции в дороги и энергетику, поддержка территориальной целостности, туристы из Залива",
    "dislikes": "вмешательство Белграда и Загреба во внутренние споры, поддержка сецессии РС, нотации о коррупции, ужесточение пограничного контроля ЕС, возвраты мигрантов",
    "open": 0.55, "stance0": 0.0, "ccol": (0.10, 0.25, 0.65, 1.0),
    "rel": {"DE": 70, "FR": 60, "NL": 56, "BE": 58, "LU": 58, "CH": 66, "AT": 72, "PL": 56, "CZ": 58, "DK": 56, "NO": 60, "SE": 62, "IT": 64, "ES": 60, "PT": 56,
            "GB": 64, "IE": 56, "SI": 74, "SK": 56, "HU": 60, "FI": 56, "HR": 62, "RS": 60, "GR": 60, "ME": 70, "MK": 66, "AL": 62, "XK": 50, "BG": 60, "RO": 58,
            "EE": 52, "LV": 52, "LT": 52},
    "trade_x": {"DE": 1.9, "FR": 0.3, "NL": 0.3, "BE": 0.1, "LU": 0.03, "CH": 0.5, "AT": 1.1, "PL": 0.2, "CZ": 0.2, "DK": 0.05, "NO": 0.05, "SE": 0.1, "IT": 1.0, "ES": 0.1,
                "PT": 0.02, "GB": 0.1, "IE": 0.02, "SI": 1.0, "SK": 0.1, "HU": 0.2, "FI": 0.02, "HR": 1.9, "RS": 1.4, "GR": 0.1, "ME": 0.5, "MK": 0.2, "AL": 0.1, "XK": 0.1,
                "BG": 0.05, "RO": 0.1, "EE": 0.01, "LV": 0.01, "LT": 0.02},
    "trade_m": {"DE": 2.0, "FR": 0.4, "NL": 0.4, "BE": 0.2, "LU": 0.03, "CH": 0.2, "AT": 0.8, "PL": 0.6, "CZ": 0.4, "DK": 0.05, "NO": 0.03, "SE": 0.1, "IT": 1.6, "ES": 0.3,
                "PT": 0.03, "GB": 0.2, "IE": 0.05, "SI": 1.0, "SK": 0.2, "HU": 0.6, "FI": 0.03, "HR": 2.5, "RS": 2.2, "GR": 0.2, "ME": 0.2, "MK": 0.2, "AL": 0.05, "XK": 0.05,
                "BG": 0.2, "RO": 0.3, "EE": 0.01, "LV": 0.01, "LT": 0.02},
}
# Глава государства — Президиум из трёх членов (бошняк и хорват от Федерации, серб от РС), прямые выборы на 4 года вместе со всеобщими выборами октября 2026 года.
ELEC = {"sys": "Пропорциональная система: 42 места (28 от Федерации, 14 от Республики Сербской), 21 место по многомандатным округам с открытыми списками и 21 компенсационное, барьер 3 %", "turn": 0.50,
        "note": "Палата представителей (42 депутата) избирается на 4 года в один день с Президиумом, парламентами энтити и кантонов; без согласия Палаты народов (15 делегатов) закон не проходит. "
                "Президиум БиГ (три члена) избирается прямым голосованием относительным большинством; в игре выборы Президиума показаны как выборы его председателя.",
        "head": "direct", "title": "члена Президиума", "title_n": "Председатель Президиума Боснии и Герцеговины", "term": 48, "first": 9, "cand0": "Кандидат ХДЗ БиГ"}
RAD_CUR = "Парламентская республика"
MONARCHY = False
