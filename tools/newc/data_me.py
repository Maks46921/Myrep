# Черногория (ME), январь 2026. Сборка из me_core.py / me_laws.py / me_events.py (см. docs/NEWC_SPEC.md); общие помощники — me_lib.py (поверх ie_lib.py).
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, ".."))
from me_lib import *
from me_core import C
import me_laws as L
import me_events as EV


SLOT_ARCH = ["own", "soc", "popr", "lib", "cons", "green", "none", "euro", "region", "none"]
ARCHS = ["own", "soc", "popr", "lib", "cons", "green", "oth", "euro", "region", "prot"]
bias, T_ = calibrate(C)          # подгоняет C["regions"][i]["loy"]
P = C["policy"]; M = C["macro"]; gdp = M["gdp"]


def col(c): return {"__c": [c[0], c[1], c[2], 1]}


POLICY_BASE = [("income", "Подоходный налог", "tax"), ("social", "Взносы в соцстрахование", "tax"), ("corp", "Налог на прибыль", "tax"),
               ("vat", "НДС и акцизы", "tax"), ("emit", "Эмиссия денег (нет: евро без ЕЦБ)", "tax"), ("pensions", "Пенсии", "spend"), ("benefits", "Пособия и соцпомощь", "spend"),
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

OTHER0 = 10.7

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

# торговля: млрд € в год, товары + услуги (оценка по MONSTAT/ЦБЧ 2024: экспорт услуг — в основном туризм; импорт — товары из Сербии, ЕС, Китая)
_X = {"DE": 0.30, "FR": 0.12, "NL": 0.04, "BE": 0.03, "LU": 0.02, "AT": 0.06, "CH": 0.06, "CZ": 0.04, "DK": 0.02, "ES": 0.04, "IT": 0.16, "NO": 0.02, "PL": 0.10,
      "PT": 0.01, "SE": 0.03, "GB": 0.12, "IE": 0.02, "SI": 0.07, "SK": 0.02, "HU": 0.05, "FI": 0.01, "HR": 0.15, "RS": 0.55, "BA": 0.25, "MK": 0.03, "AL": 0.07,
      "XK": 0.10, "BG": 0.03, "RO": 0.03, "GR": 0.05, "EE": 0.01, "LV": 0.01, "LT": 0.01}
_M = {"DE": 0.38, "FR": 0.08, "NL": 0.10, "BE": 0.04, "LU": 0.01, "AT": 0.08, "CH": 0.04, "CZ": 0.05, "DK": 0.02, "ES": 0.10, "IT": 0.30, "NO": 0.01, "PL": 0.08,
      "PT": 0.01, "SE": 0.02, "GB": 0.04, "IE": 0.02, "SI": 0.15, "SK": 0.03, "HU": 0.10, "FI": 0.01, "HR": 0.30, "RS": 0.85, "BA": 0.30, "MK": 0.06, "AL": 0.08,
      "XK": 0.04, "BG": 0.05, "RO": 0.05, "GR": 0.22, "EE": 0.01, "LV": 0.01, "LT": 0.01}
WORLD = {
    "name": "Черногория", "cap": "Подгорица", "latlon": (42.44, 19.26), "pop": 0.62, "gdp": 8.3, "debt": 5.05, "growth": 3.0, "infl": 3.8, "unemp": 11.0, "def": 3.6,
    "stab": 55, "appr": 34,
    "gov": "правительство Спаича: «Европа сейчас!», «За будущее Черногории», Демократы, Боснийская партия и албанские партии",
    "gov_party": "Европа сейчас!", "pot": 2.8, "ecb_w": 0.0,
    "stance": {"eu": 0.7, "aus": -0.1, "trd": 0.5, "brd": 0.0, "nuk": -0.3},
    "desc": "Маленькая адриатическая страна НАТО и лидер очереди на вступление в ЕС, в одностороннем порядке пользующаяся евро: туризм на Которском заливе и в Будве, порт Бар, ГЭС и угольная ТЭС в Плевле. Для соседей Черногория — пёстрая страна черногорцев, сербов, бошняков и албанцев, где споры о языке, флаге и церкви не стихают, а кланы из Которского залива известны всей Европе.",
    "leader": "Председатель правительства (премьер-министр) Черногории",
    "pn": ["PES", "DPS", "ЗБЦГ", "Демократы", "BS", "URA", "Прочие", "ЕС-союз", "Албанцы", "ДНП"],
    "eu": False, "euro": True,
    "likes": "быстрые реформы на пути в ЕС, полное совпадение с внешней политикой ЕС и НАТО, борьба с кокаиновыми кланами, открытость для туристов и инвесторов",
    "dislikes": "медленные суды и коррупция, игра на сербо-черногорских противоречиях, незаконная застройка побережья, сделки без тендеров, утечки из порта Бар",
    "open": 0.65, "stance0": 0.1, "ccol": (0.62, 0.32, 0.26, 1.0),
    "rel": {"DE": 74, "FR": 72, "NL": 66, "BE": 70, "LU": 74, "CH": 70, "AT": 74, "PL": 70, "CZ": 70, "DK": 66, "NO": 66, "SE": 66, "IT": 78, "ES": 68, "PT": 66,
            "GB": 74, "IE": 66, "SI": 74, "SK": 68, "HU": 72, "FI": 66, "HR": 52, "RS": 60, "BA": 62, "MK": 72, "AL": 72, "XK": 58, "BG": 66, "RO": 66, "GR": 72,
            "EE": 64, "LV": 64, "LT": 64},
    "trade_x": _X, "trade_m": _M,
}
ELEC = {"sys": "Пропорциональная система: 81 депутат по закрытым спискам в едином общенациональном округе, барьер 3 % (для списков меньшинств — 0,7 %)", "turn": 0.56,
        "note": "Скупщина Черногории однопалатная, избирается на 4 года (последние выборы — 11 июня 2023 года, следующие — не позднее 2027 года). Президент избирается прямым голосованием в два тура на 5 лет (Яков Милатович — с мая 2023 года); голосование необязательно. Конституционные изменения символов и языка требуют 2/3 Скупщины и референдума.",
        "head": "direct", "title": "президента Черногории", "title_n": "Президент Черногории", "term": 60, "first": 27, "cand0": "Кандидат вашей партии"}
RAD_CUR = "Парламентская республика"
MONARCHY = False
