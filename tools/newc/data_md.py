# Молдова (MD), январь 2026. Сборка из md_core.py / md_laws.py / md_events.py (см. docs/NEWC_SPEC.md); помощники — md_lib.py (поверх ie_lib.py);
# религия, миграция, федерализм и досрочные выборы — md_extras.py.
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, ".."))
import datio
from md_lib import *
from md_core import C
import md_laws as L
import md_events as EV

# 0 PAS, 1 «Альтернатива», 2 «Наша партия», 3 «Демократия дома», 4 ПКРМ, 5 сеть Шора, 6 прочие, 7 внепарламентские проевропейские, 8 местные и гагаузские, 9 ПСРМ
SLOT_ARCH = ["own", "soc", "popl", "cons", "left", "popr", "none", "euro", "region", "none"]
ARCHS = list(SLOT_KEY)
bias, T_ = calibrate(C)          # подгоняет C["regions"][i]["loy"]
P = C["policy"]; M = C["macro"]; gdp = M["gdp"]


def col(c): return {"__c": [c[0], c[1], c[2], 1]}


POLICY_BASE = [("income", "Подоходный налог", "tax"), ("social", "Взносы в соцстрахование", "tax"), ("corp", "Налог на прибыль", "tax"),
               ("vat", "НДС и акцизы", "tax"), ("emit", "Эмиссия денег (НБМ)", "tax"), ("pensions", "Пенсии", "spend"), ("benefits", "Пособия и соцпомощь", "spend"),
               ("edu", "Образование и наука", "spend"), ("health", "Здравоохранение", "spend"), ("army", "Национальная армия", "spend"), ("police", "Полиция и суды", "spend"),
               ("infra", "Инфраструктура и транспорт", "spend"), ("eco", "Экология", "spend"), ("subs", "Субсидии аграриям и бизнесу", "spend"), ("admin", "Госаппарат", "spend")]
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

# прочие доходы (гранты ЕС и Плана роста, неналоговые доходы, дивиденды «Энергокома» и «Молдтелекома», местные сборы), % ВВП —
# подогнано так, чтобы стартовый дефицит ≈ def_target (налоги 29,2 % ВВП, расходы 37,6 % ВВП, проценты по долгу ≈ 1,4 % ВВП)
OTHER0 = 5.3

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

# торговля: товары + услуги, млрд € в год (оценки по БНС/НБМ 2024–2025, округлено). trade_x — экспорт Молдовы в страну, trade_m — импорт из неё.
# Экспорт ≈ 5,3 млрд € (товары ≈ 3,2, услуги ≈ 2,1: IT, транспорт), импорт ≈ 10 млрд €; около 2/3 экспорта идёт в ЕС, Румыния — первый партнёр (≈ 30 % экспорта товаров).
# Крупные партнёры вне игры: Турция, Китай (импорт ≈ 1,5 млрд €), США, Казахстан. Газ и электричество закупаются на биржах ЕС (в основном через Румынию).
WORLD = {
    "name": "Молдова", "cap": "Кишинёв", "latlon": (47.01, 28.86), "pop": 2.41, "gdp": 18.0, "debt": 7.1, "growth": 2.4, "infl": 6.8, "unemp": 3.8, "def": 4.5,
    "stab": 44, "appr": 40,
    "gov": "правительство Мунтяну: однопартийное большинство Партии действия и солидарности (55 из 101 места), президент — Майя Санду",
    "gov_party": "PAS", "pot": 3.0, "ecb_w": 0.0,
    "stance": {"eu": 0.9, "aus": 0.2, "trd": 0.6, "brd": 0.3, "nuk": 0.0},
    "desc": "Небольшая бедная страна между Румынией и Украиной, кандидат в ЕС с 2022 года, ведущий переговоры о вступлении с 2024 года, с собственной валютой (лей) и конституционным нейтралитетом. "
            "Кишинёв под руководством Майи Санду и PAS решительно развернулся на Запад, избавился от российского газа и стал примером реформ для соседей, но часть его территории — Приднестровье с российскими войсками — неподконтрольна, а Москва ведёт против страны гибридную войну.",
    "leader": "Премьер-министр Республики Молдова",
    "pn": ["PAS", "Альт.", "НП", "ДД", "ПКРМ", "Шор", "Прочие", "ПроЕС", "Местные", "ПСРМ"],
    "eu": False, "euro": False,
    "likes": "поддержка евроинтеграции и отделения переговоров Молдовы от украинских, энергетические проекты и линии электропередачи, бюджетная помощь и План роста, защита от российских гибридных атак, уважение к нейтралитету и мирная реинтеграция Приднестровья",
    "dislikes": "вето на открытие кластеров, сделки с Москвой за спиной Кишинёва, давление ради «особого статуса» Приднестровья, поддержка сети Шора и пророссийских сепаратистов Гагаузии, высылки дипломатов и угрозы газовыми контрактами",
    "open": 0.75, "stance0": 0.15, "ccol": (0.52, 0.56, 0.40, 1.0),
    "rel": {"DE": 82, "FR": 84, "NL": 72, "BE": 70, "LU": 68, "CH": 66, "AT": 70, "PL": 80, "CZ": 74, "DK": 72, "NO": 70, "SE": 74, "IT": 74, "ES": 68, "PT": 66,
            "GB": 76, "IE": 66, "SI": 68, "SK": 62, "HU": 52, "FI": 72, "HR": 66, "RS": 52, "BA": 54, "ME": 60, "MK": 58, "AL": 60, "XK": 40, "BG": 70, "RO": 92, "GR": 68,
            "EE": 78, "LV": 78, "LT": 80, "BY": 28, "UA": 84, "RU": 12},
    "trade_x": {"DE": 0.30, "FR": 0.10, "NL": 0.10, "BE": 0.05, "LU": 0.01, "CH": 0.12, "AT": 0.08, "PL": 0.15, "CZ": 0.12, "DK": 0.02, "NO": 0.01, "SE": 0.03, "IT": 0.28, "ES": 0.05,
                "PT": 0.01, "GB": 0.20, "IE": 0.03, "SI": 0.01, "SK": 0.03, "HU": 0.08, "FI": 0.01, "HR": 0.01, "RS": 0.02, "BA": 0.005, "ME": 0.003, "MK": 0.003, "AL": 0.002, "XK": 0.001,
                "BG": 0.12, "RO": 1.20, "GR": 0.05, "EE": 0.01, "LV": 0.02, "LT": 0.03, "BY": 0.05, "UA": 0.40, "RU": 0.15},
    "trade_m": {"DE": 0.70, "FR": 0.15, "NL": 0.15, "BE": 0.08, "LU": 0.01, "CH": 0.06, "AT": 0.12, "PL": 0.30, "CZ": 0.15, "DK": 0.03, "NO": 0.01, "SE": 0.04, "IT": 0.45, "ES": 0.12,
                "PT": 0.02, "GB": 0.10, "IE": 0.04, "SI": 0.03, "SK": 0.06, "HU": 0.20, "FI": 0.02, "HR": 0.01, "RS": 0.05, "BA": 0.01, "ME": 0.002, "MK": 0.01, "AL": 0.002, "XK": 0.001,
                "BG": 0.20, "RO": 1.70, "GR": 0.20, "EE": 0.01, "LV": 0.03, "LT": 0.07, "BY": 0.15, "UA": 0.65, "RU": 0.25},
}
# Президент избирается прямым голосованием в два тура на 4 года (не более двух сроков подряд). Майя Санду переизбрана 3 ноября 2024 года (вступила в должность 24 декабря),
# следующие выборы — около октября 2028 года (33-й месяц игры); Санду баллотироваться уже не может. Следующие парламентские выборы — осенью 2029 года.
ELEC = {"sys": "Пропорциональная система: 101 место в едином общенациональном округе по закрытым спискам, порог 5 % для партий, 7 % для блоков и 2 % для независимых кандидатов, метод Д'Ондта",
        "turn": 0.52,
        "note": "Однопалатный Парламент избирается на 4 года; для диаспоры открываются участки за рубежом (в 2025 году — более 300), для жителей Приднестровья — на правом берегу Днестра. "
                "Президент Республики избирается прямым голосованием в два тура на 4 года (не более двух сроков подряд): назначает премьер-министра, представляет страну, может один раз вернуть закон и при условиях ст. 85 Конституции распустить Парламент. Голосование необязательно; итоги утверждает Конституционный суд.",
        "head": "direct", "title": "президента Республики Молдова", "title_n": "Президент Республики Молдова", "term": 48, "first": 33, "cand0": "Кандидат PAS"}
RAD_CUR = "Парламентская республика"
MONARCHY = False
