# Словакия (SK), январь 2026. Сборка из sk_core.py / sk_laws.py / sk_events.py (см. docs/NEWC_SPEC.md). Схема — как data_ie.py.
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, ".."))
import datio  # noqa: F401
from sk_lib import *
from sk_core import C
import sk_laws as L
import sk_events as EV


# 0 Смер(own) 1 Глас(soc) 2 PS(euro) 3 SaS(lib) 4 KDH(cons) 5 Словакия(popl) 6 прочие 7 СНС(popr) 8 Венгерский альянс(region) 9 Республика(протест)
SLOT_ARCH = ["own", "soc", "euro", "lib", "cons", "popl", "none", "popr", "region", "none"]
ARCHS = ["own", "soc", "euro", "lib", "cons", "popl", "oth", "popr", "region", "prot"]
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

OTHER0 = 6.0

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

# Торговля: товары + услуги, млрд € в год (оценка по Eurostat/ŠÚ SR 2024; экспорт SK ≈ 110 млрд € товаров + 15 млрд € услуг).
WORLD = {
    "name": "Словакия", "cap": "Братислава", "latlon": (48.15, 17.11), "pop": 5.42, "gdp": 140.0, "debt": 86.0, "growth": 1.0, "infl": 3.8, "unemp": 5.4, "def": 4.2,
    "stab": 55, "appr": 33,
    "gov": "правительство Фицо: Смер-СД, Глас-СД и Словацкая национальная партия",
    "gov_party": "Смер-СД", "pot": 2.0, "ecb_w": 0.01,
    "stance": {"eu": -0.2, "aus": 0.0, "trd": 0.4, "brd": -0.5, "nuk": 0.8},
    "desc": "Малая страна еврозоны с самой высокой в мире долей автопрома: Volkswagen, Stellantis, Kia, Jaguar Land Rover и Volvo. Правительство Роберта Фицо держится «суверенной» линии — "
            "спорит с Брюсселем о верховенстве права, прекратило военную помощь Украине и держится за российский газ, сближаясь с Венгрией, — но остаётся в ЕС и НАТО. "
            "Для соседей Словакия — надёжный промышленный партнёр и трудный союзник в Совете ЕС.",
    "leader": "Премьер-министр Словакии",
    "pn": ["Смер", "Глас", "PS", "SaS", "KDH", "Словакия", "Прочие", "СНС", "МА", "Республика"],
    "eu": True, "euro": True,
    "likes": "развитие автопрома и инвестиции, атомная энергетика, дешёвая энергия и газ, «прагматичные» отношения со всеми, совместные проекты Центральной Европы и шоссе",
    "dislikes": "лекции о верховенстве права и угрозы фондам ЕС, санкции против российского газа и нефти, миграционные квоты, военная эскалация и «прогрессивная» повестка",
    "open": 0.85, "stance0": -0.05, "ccol": (0.40, 0.48, 0.70, 1.0),
    "rel": {"DE": 70, "FR": 66, "NL": 58, "BE": 64, "LU": 66, "CH": 70, "AT": 76, "PL": 62, "CZ": 88, "DK": 60, "NO": 64, "SE": 60, "IT": 72, "ES": 70, "PT": 70,
            "GB": 64, "IE": 64, "SI": 74, "HU": 82, "FI": 56},
    "trade_x": {"DE": 24.0, "FR": 7.0, "NL": 3.5, "BE": 2.0, "LU": 0.3, "CH": 1.4, "AT": 7.5, "PL": 9.5, "CZ": 14.5, "DK": 0.9, "NO": 0.5, "SE": 1.4, "IT": 5.5, "ES": 3.0, "PT": 0.6,
                "GB": 4.5, "IE": 0.5, "SI": 1.1, "HU": 9.0, "FI": 0.5},
    "trade_m": {"DE": 21.0, "FR": 3.8, "NL": 3.5, "BE": 2.2, "LU": 0.4, "CH": 1.3, "AT": 6.0, "PL": 7.5, "CZ": 15.5, "DK": 0.6, "NO": 0.5, "SE": 1.1, "IT": 4.5, "ES": 1.8, "PT": 0.4,
                "GB": 1.8, "IE": 0.9, "SI": 1.1, "HU": 7.0, "FI": 0.5},
}
ELEC = {"sys": "Пропорциональная система по спискам в едином общенациональном округе, порог 5 % (7 % для коалиций)", "turn": 0.68,
        "note": "Национальный совет однопалатный (150 депутатов, срок 4 года), голосование необязательно, избиратели могут дать до четырёх преференциальных голосов. "
                "Президент избирается прямым голосованием в два тура на 5 лет; Петер Пеллегрини вступил в должность в июне 2024 года.",
        "head": "direct", "title": "президента Словацкой Республики", "title_n": "Президент Словацкой Республики", "term": 60, "first": 39, "cand0": "Кандидат Смера"}
RAD_CUR = "Парламентская республика"
MONARCHY = False
