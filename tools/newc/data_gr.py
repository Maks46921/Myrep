# Греция (GR), январь 2026. Сборка из gr_core.py / gr_laws.py / gr_events.py (см. docs/NEWC_SPEC.md); общие помощники — gr_lib.py (поверх ie_lib.py).
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, ".."))
from gr_lib import *
from gr_core import C
import gr_laws as L
import gr_events as EV


# 0 Новая демократия, 1 ПАСОК, 2 СИРИЗА, 3 KKE, 4 «Курс свободы», 5 Ники, 6 прочие и независимые, 7 Голос разума, 8 DEB (меньшинство Фракии), 9 Греческое решение
# SLOT_ARCH и ARCHS — из gr_lib
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

# прочие доходы (фонды ЕС и Фонд восстановления, неналоговые доходы, доходы от ANFA/SMP), % ВВП — подобрано под стартовый баланс ≈ профицит 1 %
OTHER0 = 8.5

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

# торговля: товары + услуги, млрд € в год (оценки по ELSTAT/Банку Греции/Eurostat 2024, округлено; туризм входит в экспорт услуг; вне игры — Турция, Кипр, Китай, США и др.).
WORLD = {
    "name": "Греция", "cap": "Афины", "latlon": (37.98, 23.73), "pop": 10.4, "gdp": 250.0, "debt": 146.0, "growth": 2.1, "infl": 2.9, "unemp": 8.7, "def": -1.0,
    "stab": 58, "appr": 30,
    "gov": "однопартийное правительство Кириакоса Мицотакиса («Новая демократия», 156 из 300 мест)",
    "gov_party": "Новая демократия", "pot": 1.8, "ecb_w": 0.016,
    "stance": {"eu": 0.5, "aus": 0.2, "trd": 0.6, "brd": 0.4, "nuk": 0.3},
    "desc": "Страна еврозоны и НАТО на юго-востоке Европы, пережившая долговой кризис 2010-х и вернувшая инвестиционный рейтинг: туризм, крупнейший в мире торговый флот, "
            "порт Пирей, сельское хозяйство и энергетический коридор для Балкан и Украины. Для соседей Греция — опора ЕС в регионе, хозяин внешней морской границы с Турцией "
            "и Ливией, строгий судья балканских кандидатов в ЕС (Преспанское соглашение с Северной Македонией, греческое меньшинство в Албании) и вечный соперник Турции в Эгейском море.",
    "leader": "Премьер-министр Греции",
    "pn": ["ND", "ПАСОК", "СИРИЗА", "KKE", "Плефси", "Ники", "Прочие", "Голос", "DEB", "Эл. лиси"],
    "eu": True, "euro": True,
    "likes": "солидарность ЕС против притязаний Турции, распределение мигрантов, инвестиции в энергетику и порты, уважение к Преспанскому соглашению и правам греческого меньшинства, туристы",
    "dislikes": "продажа оружия Турции, нарушение Преспанского соглашения, «вторичная миграция» как упрёк Греции, критика выдворений лодок и свободы прессы, бюджетные нотации Берлина",
    "open": 0.6, "stance0": 0.0, "ccol": (0.25, 0.50, 0.85, 1.0),
    "rel": {"DE": 70, "FR": 86, "NL": 66, "BE": 72, "LU": 72, "CH": 70, "AT": 68, "PL": 72, "CZ": 70, "DK": 68, "NO": 68, "SE": 66, "IT": 84, "ES": 80, "PT": 80,
            "GB": 70, "IE": 76, "SI": 74, "SK": 70, "HU": 70, "FI": 68, "HR": 74, "RS": 80, "BA": 62, "ME": 70, "MK": 50, "AL": 52, "XK": 45, "BG": 80, "RO": 80,
            "EE": 66, "LV": 66, "LT": 66},
    "trade_x": {"DE": 9.0, "FR": 4.5, "NL": 3.0, "BE": 1.6, "LU": 0.3, "CH": 1.6, "AT": 1.8, "PL": 2.6, "CZ": 1.2, "DK": 0.8, "NO": 0.7, "SE": 1.2, "IT": 7.0, "ES": 2.6,
                "PT": 0.5, "GB": 6.5, "IE": 0.8, "SI": 0.4, "SK": 0.5, "HU": 0.6, "FI": 0.4, "HR": 0.5, "RS": 1.0, "BA": 0.3, "ME": 0.2, "MK": 1.0, "AL": 0.9, "XK": 0.3,
                "BG": 3.8, "RO": 2.2, "EE": 0.1, "LV": 0.1, "LT": 0.2},
    "trade_m": {"DE": 11.0, "FR": 4.0, "NL": 6.0, "BE": 2.8, "LU": 0.3, "CH": 1.0, "AT": 1.6, "PL": 2.4, "CZ": 1.3, "DK": 1.0, "NO": 0.8, "SE": 0.8, "IT": 9.5, "ES": 3.2,
                "PT": 0.3, "GB": 2.0, "IE": 1.5, "SI": 0.5, "SK": 0.6, "HU": 0.7, "FI": 0.4, "HR": 0.3, "RS": 0.7, "BA": 0.2, "ME": 0.05, "MK": 0.6, "AL": 0.4, "XK": 0.05,
                "BG": 4.5, "RO": 1.5, "EE": 0.05, "LV": 0.05, "LT": 0.2},
}
# президента избирает Парламент: в первых двух турах 2/3 (200 голосов), в третьем 3/5 (180), в четвёртом — абсолютное большинство (151), в пятом — относительное
# (после реформы 2019 года парламент больше не распускается). Константинос Тасулас избран 12 февраля 2025 года на 5 лет -> следующие выборы около февраля 2030 года (50-й месяц).
ELEC = {"sys": "Усиленная пропорциональная система: 300 мест, барьер 3 %, премия победителю от 20 до 50 мест при 25–40 % голосов (с 2023 года)", "turn": 0.53,
        "note": "Однопалатный Парламент (Вули, 300 депутатов) избирается на 4 года; партия-победитель получает премию в 20 мест при 25 % голосов и до 50 мест при 40 %, поэтому 38–40 % часто дают однопартийное большинство. "
                "Президент Греческой Республики избирается Парламентом на 5 лет.",
        "head": "indirect", "title": "президента Республики", "title_n": "Президент Греческой Республики", "term": 60, "first": 50,
        "body": "депутаты Парламента", "ele_x": 1.0, "ele_add": 0, "need": [0.667, 0.667, 0.6, 0.504, 0.0], "secret": 0.02, "cand0": "Кандидат «Новой демократии»"}
RAD_CUR = "Парламентская республика"
MONARCHY = False
