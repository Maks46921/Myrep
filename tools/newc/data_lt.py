# Литва (LT), январь 2026. Сборка из lt_core.py / lt_laws.py / lt_events.py (см. docs/NEWC_SPEC.md); общие помощники — lt_lib.py (поверх ie_lib.py и sk_lib.py).
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, ".."))
from lt_lib import *
from lt_core import C
import lt_laws as L
import lt_events as EV


# 0 ЛСДП 1 TS-LKD 2 «Заря Немана» 3 Демократы 4 крестьяне 5 либералы 6 прочие 7 Партия свободы 8 Акция поляков 9 Нацобъединение
SLOT_ARCH = ["own", "cons", "popr", "soc", "popl", "lib", "none", "euro", "region", "none"]
ARCHS = list(SLOT_KEY)
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
    dem.append([] if s == 0 or a == "none" else demands_list(a, P, gdp))
ministries = [{"name": C["ministries"][i], "desc": MIN_BASE[i][0], "base": MIN_BASE[i][1]} for i in range(12)]

OTHER0 = 5.15

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

# Торговля: млрд € в год, товары + услуги (оценка по данным Госстата Литвы и Eurostat за 2024 год; крупные статьи экспорта —
# нефтепродукты ORLEN, мебель, удобрения, продовольствие, транспортные и ИТ-услуги; большая часть торговли приходится на Польшу, Германию, Латвию и Нидерланды).
WORLD = {
    "name": "Литва", "cap": "Вильнюс", "latlon": (54.69, 25.28), "pop": 2.89, "gdp": 85.0, "debt": 41.5, "growth": 2.6, "infl": 3.4, "unemp": 6.8, "def": 2.7,
    "stab": 62, "appr": 26,
    "gov": "правительство Ругинене: социал-демократы, «Заря Немана», крестьяне и зелёные и Акция поляков Литвы",
    "gov_party": "Социал-демократическая партия Литвы", "pot": 2.6, "ecb_w": 0.006,
    "stance": {"eu": 0.7, "aus": 0.3, "trd": 0.5, "brd": -0.6, "nuk": 0.3},
    "desc": "Самая большая из стран Балтии: государство на внешней границе ЕС и НАТО с Беларусью и Калининградской областью, с самыми высокими в альянсе расходами на оборону (более 5 % ВВП), низким долгом и быстро растущей, но стареющей экономикой — транзит и логистика, мебель, лазеры, нефтепереработка в Мажейкяй, финтех и ИТ в Вильнюсе. Для партнёров Литва — жёсткий голос против Москвы и Минска, адвокат Украины и энергетической независимости Балтии, но и страна с шумной внутренней политикой, частой сменой правительств и болезненным вопросом польского меньшинства.",
    "leader": "Премьер-министр Литовской Республики",
    "pn": ["ЛСДП", "TS-LKD", "Заря Немана", "Демократы", "Крестьяне", "Либералы", "Прочие", "Свобода", "Поляки", "Нацобъед."],
    "eu": True, "euro": True,
    "likes": "твёрдая линия против России и Беларуси, помощь Украине, расходы на оборону выше 5 % ВВП, энергетическая независимость Балтии, единый рынок и транзит",
    "dislikes": "сделки с Москвой и Минском за спиной Балтии, мягкие санкции, спор о правах польского меньшинства, зависимость от российского газа у партнёров, попытки ограничить восточное расширение ЕС",
    "open": 0.88, "stance0": 0.15, "ccol": (0.95, 0.72, 0.20, 1.0),
    "rel": {"DE": 82, "FR": 74, "NL": 76, "BE": 74, "LU": 72, "CH": 70, "AT": 68, "PL": 86, "CZ": 78, "DK": 82, "NO": 78, "SE": 84, "IT": 70, "ES": 70, "PT": 68,
            "GB": 82, "IE": 76, "SI": 72, "SK": 60, "HU": 54, "FI": 82, "HR": 72, "RS": 52, "BA": 64, "ME": 68, "MK": 68, "AL": 68, "XK": 72, "BG": 70, "RO": 76,
            "GR": 64, "EE": 92, "LV": 93},
    "trade_x": {"DE": 3.6, "FR": 1.0, "NL": 1.9, "BE": 0.7, "LU": 0.07, "CH": 0.3, "AT": 0.3, "PL": 4.2, "CZ": 0.5, "DK": 0.7, "NO": 0.6, "SE": 1.4, "IT": 0.8,
                "ES": 0.6, "PT": 0.15, "GB": 1.2, "IE": 0.2, "SI": 0.1, "SK": 0.3, "HU": 0.4, "FI": 0.6, "HR": 0.1, "RS": 0.1, "BA": 0.05, "ME": 0.02, "MK": 0.04,
                "AL": 0.03, "XK": 0.02, "BG": 0.2, "RO": 0.5, "GR": 0.2, "EE": 2.0, "LV": 3.8},
    "trade_m": {"DE": 4.3, "FR": 0.8, "NL": 1.3, "BE": 0.7, "LU": 0.05, "CH": 0.3, "AT": 0.4, "PL": 6.0, "CZ": 0.6, "DK": 0.5, "NO": 0.3, "SE": 0.9, "IT": 1.1,
                "ES": 0.5, "PT": 0.1, "GB": 0.6, "IE": 0.3, "SI": 0.1, "SK": 0.3, "HU": 0.4, "FI": 0.5, "HR": 0.1, "RS": 0.1, "BA": 0.04, "ME": 0.01, "MK": 0.05,
                "AL": 0.02, "XK": 0.01, "BG": 0.2, "RO": 0.3, "GR": 0.2, "EE": 1.3, "LV": 2.6},
}
ELEC = {"sys": "Смешанная система: 71 член Сейма избирается в одномандатных округах в два тура, 70 — по общенациональным спискам (барьер 5 %, для коалиций 7 %)", "turn": 0.52,
        "note": "Сейм (141 место) избирается на 4 года: половина мандатов — в одномандатных округах (при явке ниже 40 % победитель определяется во втором туре), половина — по партийным спискам с преференциями. Верхней палаты нет. "
                "Президент избирается прямым голосованием на 5 лет (не более двух сроков подряд): он ведёт внешнюю политику, командует армией, назначает министров по представлению премьера и может вернуть закон в Сейм — вето преодолевается 71 голосом. "
                "Досрочные выборы возможны решением 3/5 членов Сейма или указом президента, если Сейм дважды не одобрил программу правительства.",
        "head": "direct", "title": "президента Республики", "title_n": "Президент Литовской Республики", "term": 60, "first": 29, "cand0": "Кандидат вашей партии"}
RAD_CUR = "Полупрезидентская республика"
MONARCHY = False
