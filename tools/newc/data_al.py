# Албания (AL), январь 2026. Сборка из al_core.py / al_laws.py / al_events.py (см. docs/NEWC_SPEC.md); общие помощники — al_lib.py (поверх ie_lib.py).
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, ".."))
from al_lib import *
from al_core import C
import al_laws as L
import al_events as EV


# 0 СП, 1 ПД, 2 PSD, 3 «Движение Вместе», 4 аграрии-экологи, 5 «Возможность», 6 прочие, 7 Партия Свободы, 8 меньшинства, 9 «Албания становится»
SLOT_ARCH = ["own", "cons", "soc", "left", "green", "lib", "none", "popr", "region", "none"]
ARCHS = list(SLOT_KEY)
bias, T_ = calibrate(C)          # подгоняет C["regions"][i]["loy"]
P = C["policy"]; M = C["macro"]; gdp = M["gdp"]


def col(c): return {"__c": [c[0], c[1], c[2], 1]}


POLICY_BASE = [("income", "Подоходный налог", "tax"), ("social", "Взносы в соцстрахование", "tax"), ("corp", "Налог на прибыль", "tax"),
               ("vat", "НДС и акцизы", "tax"), ("emit", "Эмиссия денег (Банк Албании)", "tax"), ("pensions", "Пенсии", "spend"), ("benefits", "Пособия и соцпомощь", "spend"),
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

# прочие доходы (гранты ЕС, неналоговые доходы, дивиденды, роялти), % ВВП — подогнано под стартовый дефицит ≈ def_target
OTHER0 = 6.5

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

# торговля: млрд € в год, товары + услуги (оценка по INSTAT/Банку Албании 2024–2025; туризм — крупнейший экспорт услуг: Италия, Косово, Польша, Великобритания)
WORLD = {
    "name": "Албания", "cap": "Тирана", "latlon": (41.33, 19.82), "pop": 2.40, "gdp": 27.0, "debt": 14.2, "growth": 3.5, "infl": 2.3, "unemp": 9.3, "def": 1.7,
    "stab": 58, "appr": 45,
    "gov": "правительство Рамы IV: Социалистическая партия (83 из 140 мест)",
    "gov_party": "Социалистическая партия", "pot": 3.4, "ecb_w": 0.0,
    "stance": {"eu": 0.8, "aus": 0.1, "trd": 0.6, "brd": 0.3, "nuk": 0.0},
    "desc": "Небольшая адриатическая страна НАТО и кандидат в ЕС, которая за десять лет превратилась из самой закрытой страны Европы в туристическую звезду Средиземноморья. Для соседей Албания — быстро растущий, проевропейский и удобный партнёр Рамы, но с репутацией транзита наркотиков, коррупции и массовой эмиграции.",
    "leader": "Премьер-министр Албании",
    "pn": ["СП", "ПД", "PSD", "Вместе", "Аграрии", "Возможность", "Прочие", "Свобода", "Меньшинства", "АС"],
    "eu": False, "euro": False,
    "likes": "быстрые реформы ради вступления в ЕС, вклад в НАТО и поддержка Украины, сотрудничество в миграции (протокол с Италией), открытость для туристов и инвесторов",
    "dislikes": "коррупция и непрозрачные концессии, наркотрафик через порты, массовая эмиграция и нелегальная миграция албанцев в Великобританию, конфликты с греческим меньшинством",
    "open": 0.75, "stance0": 0.2, "ccol": (0.70, 0.32, 0.30, 1.0),
    "rel": {"DE": 78, "FR": 74, "NL": 64, "BE": 68, "LU": 68, "CH": 72, "AT": 76, "PL": 72, "CZ": 70, "DK": 68, "NO": 70, "SE": 68, "IT": 84, "ES": 64, "PT": 68,
            "GB": 72, "IE": 68, "SI": 72, "SK": 64, "HU": 68, "FI": 68, "HR": 74, "RS": 45, "BA": 62, "ME": 70, "MK": 72, "XK": 86, "BG": 66, "RO": 68, "GR": 52,
            "EE": 70, "LV": 70, "LT": 70},
    "trade_x": {"DE": 0.9, "FR": 0.3, "NL": 0.15, "BE": 0.08, "LU": 0.01, "CH": 0.15, "AT": 0.15, "PL": 0.3, "CZ": 0.06, "DK": 0.04, "NO": 0.05, "SE": 0.08, "IT": 3.0, "ES": 0.25,
                "PT": 0.02, "GB": 0.5, "IE": 0.03, "SI": 0.05, "SK": 0.03, "HU": 0.06, "FI": 0.02, "HR": 0.08, "RS": 0.25, "BA": 0.05, "ME": 0.2, "MK": 0.35, "XK": 1.0,
                "BG": 0.06, "RO": 0.08, "GR": 0.8, "EE": 0.01, "LV": 0.01, "LT": 0.02},
    "trade_m": {"DE": 1.0, "FR": 0.35, "NL": 0.25, "BE": 0.12, "LU": 0.02, "CH": 0.2, "AT": 0.25, "PL": 0.25, "CZ": 0.12, "DK": 0.06, "NO": 0.04, "SE": 0.08, "IT": 3.0, "ES": 0.4,
                "PT": 0.04, "GB": 0.3, "IE": 0.06, "SI": 0.15, "SK": 0.06, "HU": 0.15, "FI": 0.03, "HR": 0.25, "RS": 0.6, "BA": 0.08, "ME": 0.1, "MK": 0.3, "XK": 0.4,
                "BG": 0.3, "RO": 0.2, "GR": 1.1, "EE": 0.01, "LV": 0.01, "LT": 0.03},
}
# президента избирает Народное собрание: в первых трёх турах нужно 3/5 всех депутатов (84 голоса), в 4-м и 5-м — абсолютное большинство (71);
# Байрам Бегай избран 4 июня 2022 года, вступил в должность 24 июля 2022 года на 5 лет -> следующие выборы около июня 2027 года (17-й месяц игры).
ELEC = {"sys": "Региональная пропорциональная система: 140 мест по 12 областным округам, барьер 1 %, частично открытые списки, голосование диаспоры по почте",
        "turn": 0.47,
        "note": "Однопалатное Народное собрание (Kuvendi, 140 депутатов) избирается на 4 года; явка формально низкая, потому что в списках много эмигрантов. Президент избирается Собранием на 5 лет (не более двух сроков); если за 5 туров президент не избран, Собрание распускается.",
        "head": "indirect", "title": "президента Республики", "title_n": "Президент Республики Албания", "term": 60, "first": 17,
        "body": "депутаты Народного собрания", "ele_x": 1.0, "ele_add": 0, "need": [0.6, 0.6, 0.6, 0.507, 0.0], "secret": 0.02, "cand0": "Кандидат Социалистической партии"}
RAD_CUR = "Парламентская республика"
MONARCHY = False
