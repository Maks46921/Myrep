# Венгрия (HU), январь 2026. Сборка из hu_core.py / hu_laws.py / hu_events.py (см. docs/NEWC_SPEC.md).
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, ".."))
import datio
from hu_lib import *
from hu_core import C
import hu_laws as L
import hu_events as EV

# 0 Фидес–ХДНП, 1 Наша Родина, 2 ДК, 3 MSZP, 4 LMP–Диалог, 5 Моментум, 6 MKKP и независимые, 7 Йоббик, 8 национальности, 9 Тиса
SLOT_ARCH = ["own", "popr", "soc", "left", "green", "lib", "none", "cons", "region", "none"]
ARCHS = list(SLOT_KEY)
bias, T_ = calibrate(C)          # подгоняет C["regions"][i]["loy"]
P = C["policy"]; M = C["macro"]; gdp = M["gdp"]


def col(c): return {"__c": [c[0], c[1], c[2], 1]}


POLICY_BASE = [("income", "Подоходный налог", "tax"), ("social", "Взносы в соцстрахование", "tax"), ("corp", "Налог на прибыль", "tax"),
               ("vat", "НДС и акцизы", "tax"), ("emit", "Эмиссия денег (MNB)", "tax"), ("pensions", "Пенсии", "spend"), ("benefits", "Пособия и соцпомощь", "spend"),
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

# прочие доходы (фонды ЕС, неналоговые доходы, дивиденды госкомпаний), % ВВП — подогнано так, чтобы стартовый дефицит ≈ def_target (3,0 %)
OTHER0 = 7.3

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

# торговля: товары + услуги, млрд € в год (оценки по Eurostat/KSH 2024, округлено). trade_x — экспорт Венгрии в страну, trade_m — импорт из неё.
WORLD = {
    "name": "Венгрия", "cap": "Будапешт", "latlon": (47.50, 19.04), "pop": 9.55, "gdp": 220.0, "debt": 163.0, "growth": 1.0, "infl": 3.8, "unemp": 4.4, "def": 4.8,
    "stab": 60, "appr": 40,
    "gov": "правительство Орбана: Фидес–ХДНП с конституционным большинством (135 из 199 мест)",
    "gov_party": "Фидес–ХДНП", "pot": 2.2, "ecb_w": 0.0,
    "stance": {"eu": -0.6, "aus": -0.1, "trd": 0.3, "brd": -0.9, "nuk": 0.8},
    "desc": "Центральноевропейская страна с собственной валютой и экономикой, встроенной в немецкий автопром и китайские аккумуляторные цепочки. Правительство Орбана — самый громкий «суверенист» ЕС: вето по Украине и санкциям, дружба с Москвой и Пекином, замороженные фонды ЕС; для соседей Венгрия — неудобный, но незаменимый партнёр в Центральной Европе.",
    "leader": "Премьер-министр Венгрии",
    "pn": ["Фидес", "Наша Родина", "ДК", "MSZP", "LMP–Диалог", "Моментум", "MKKP и др.", "Йоббик", "Меньш.", "Тиса"],
    "eu": True, "euro": False,
    "likes": "уважение к «национальному суверенитету» и христианской идентичности, отказ от миграционных квот, дешёвая энергия и атом, инвестиции без политических условий, защита венгерских меньшинств",
    "dislikes": "условия верховенства права для фондов ЕС, давление по Украине и российскому газу, миграционный пакт, критика законов о СМИ и ЛГБТ, «уроки демократии» из Брюсселя",
    "open": 0.80, "stance0": -0.15, "ccol": (0.58, 0.40, 0.30, 1.0),
    "rel": {"DE": 62, "FR": 58, "NL": 45, "BE": 50, "LU": 52, "CH": 60, "AT": 62, "PL": 50, "CZ": 62, "DK": 48, "NO": 45, "SE": 45, "IT": 68, "ES": 55, "PT": 56,
            "GB": 60, "IE": 50, "SI": 66, "SK": 80, "FI": 45},
    "trade_x": {"DE": 36.0, "FR": 7.0, "NL": 6.0, "BE": 3.0, "LU": 0.6, "CH": 2.5, "AT": 9.0, "PL": 9.0, "CZ": 8.0, "DK": 1.5, "NO": 0.6, "SE": 2.2, "IT": 9.0, "ES": 4.5, "PT": 0.8,
                "GB": 5.5, "IE": 1.0, "SI": 2.5, "SK": 10.0, "FI": 0.7},
    "trade_m": {"DE": 30.0, "FR": 5.0, "NL": 8.0, "BE": 3.5, "LU": 1.0, "CH": 2.5, "AT": 10.0, "PL": 9.0, "CZ": 7.0, "DK": 1.2, "NO": 0.6, "SE": 1.8, "IT": 7.5, "ES": 2.5, "PT": 0.5,
                "GB": 3.0, "IE": 2.0, "SI": 1.8, "SK": 9.0, "FI": 0.8},
}
# президента избирает Государственное собрание тайным голосованием: в первом туре нужны 2/3 всех депутатов, во втором — простое большинство поданных голосов.
# Тамаш Шуйок избран 26 февраля 2024 года, вступил в должность 5 марта 2024 года на 5 лет -> следующие выборы около марта 2029 года (38-й месяц игры).
ELEC = {"sys": "Смешанная система: 106 одномандатных округов (один тур, относительное большинство) и 93 места по общенациональным спискам (порог 5 %, «компенсация победителю»)",
        "turn": 0.70,
        "note": "Однопалатное Государственное собрание (199 депутатов) избирается на 4 года; венгры за рубежом без адреса в стране голосуют по почте только за списки, национальности — за свои списки. Президент избирается парламентом на 5 лет.",
        "head": "indirect", "title": "президента Венгрии", "title_n": "Президент Венгрии", "term": 60, "first": 38,
        "body": "депутаты Государственного собрания", "ele_x": 1.0, "ele_add": 0, "need": [0.667, 0.0], "secret": 0.02, "cand0": "Кандидат Фидес–ХДНП"}
RAD_CUR = "Парламентская республика"
MONARCHY = False
