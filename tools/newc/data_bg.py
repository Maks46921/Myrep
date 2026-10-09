# Болгария (BG), январь 2026. Сборка из bg_core.py / bg_laws.py / bg_events.py (см. docs/NEWC_SPEC.md); общие помощники — bg_lib.py (поверх ie_lib.py).
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, ".."))
from bg_lib import *
from bg_core import C
import bg_laws as L
import bg_events as EV


# 0 ГЕРБ–СДС, 1 БСП–ОЛ, 2 ПП–ДБ, 3 «Возрождение», 4 ИТН, 5 МЕЧ, 6 прочие («Величие» и независимые), 7 АПС, 8 ДПС–Новое начало, 9 «Прогрессивная Болгария» Радева
SLOT_ARCH = ["own", "soc", "lib", "popr", "cons", "popr", "none", "euro", "region", "none"]
ARCHS = ["own", "soc", "lib", "popr", "cons", "popr", "oth", "euro", "region", "prot"]
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

# прочие доходы (фонды ЕС, неналоговые доходы, дивиденды БЕХ), % ВВП — подогнано так, чтобы стартовый дефицит ≈ def_target (3,0 %)
OTHER0 = 6.75

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

# торговля: товары + услуги, млрд € в год (оценки по НСИ/БНБ/Eurostat 2024, округлено; вне игры остаются Турция, Китай, Россия, США и др.).
# trade_x — экспорт Болгарии в страну (вкл. туризм и IT-услуги), trade_m — импорт из неё.
WORLD = {
    "name": "Болгария", "cap": "София", "latlon": (42.70, 23.32), "pop": 6.44, "gdp": 108.0, "debt": 28.0, "growth": 3.0, "infl": 3.6, "unemp": 3.6, "def": 3.0,
    "stab": 42, "appr": 22,
    "gov": "служебное положение: правительство Желязкова (ГЕРБ–СДС, БСП–ОЛ, ИТН при поддержке ДПС–НН) в отставке с декабря 2025 года, досрочные выборы в апреле 2026 года",
    "gov_party": "ГЕРБ–СДС", "pot": 2.8, "ecb_w": 0.007,
    "stance": {"eu": 0.4, "aus": 0.3, "trd": 0.6, "brd": -0.1, "nuk": 0.7},
    "desc": "Самая бедная, но быстро растущая страна ЕС на Чёрном море: с 2025 года полностью в Шенгене, с 2026 года — в еврозоне, член НАТО с боевой группой в Ново-Селе. "
            "Низкие налоги (10 %) и долг, IT-аутсорсинг Софии, автокомпоненты Пловдива, АЭС «Козлодуй» и НПЗ в Бургасе. Для соседей Болгария — охранник внешней границы ЕС с Турцией, "
            "энергетический и транспортный коридор на Балканы и вечный источник политических кризисов: восемь выборов за пять лет, «модель Пеевски» и спор с Северной Македонией.",
    "leader": "Премьер-министр (министр-председатель) Болгарии",
    "pn": ["ГЕРБ", "БСП", "ПП–ДБ", "Возрождение", "ИТН", "МЕЧ", "Прочие", "АПС", "ДПС–НН", "Радев"],
    "eu": True, "euro": True,
    "likes": "защита внешней границы ЕС с Турцией, энергетические коридоры через Грецию и Румынию, поддержка болгар за рубежом, инвестиции в Северо-Запад, уважение к болгарской истории в спорах со Скопье",
    "dislikes": "давление по верховенству права и прокуратуре, задержки фондов ЕС, «двойные стандарты» при вступлении в Шенген, пограничные очереди, обвинения в коррупции и пророссийских симпатиях",
    "open": 0.8, "stance0": 0.0, "ccol": (0.30, 0.62, 0.40, 1.0),
    "rel": {"DE": 78, "FR": 76, "NL": 62, "BE": 72, "LU": 72, "CH": 70, "AT": 64, "PL": 74, "CZ": 74, "DK": 70, "NO": 68, "SE": 70, "IT": 74, "ES": 74, "PT": 72,
            "GB": 70, "IE": 70, "SI": 74, "SK": 72, "HU": 70, "FI": 68, "HR": 74, "RS": 66, "BA": 62, "ME": 66, "MK": 38, "AL": 66, "XK": 58, "RO": 82, "GR": 80,
            "EE": 68, "LV": 68, "LT": 68},
    "trade_x": {"DE": 9.5, "FR": 2.8, "NL": 2.2, "BE": 1.8, "LU": 0.2, "CH": 1.4, "AT": 1.6, "PL": 2.2, "CZ": 1.3, "DK": 0.4, "NO": 0.3, "SE": 0.6, "IT": 4.2, "ES": 1.6,
                "PT": 0.3, "GB": 2.6, "IE": 0.6, "SI": 0.4, "SK": 0.6, "HU": 1.4, "FI": 0.2, "HR": 0.4, "RS": 1.2, "BA": 0.2, "ME": 0.1, "MK": 1.0, "AL": 0.2, "XK": 0.15,
                "RO": 6.0, "GR": 4.5, "EE": 0.1, "LV": 0.1, "LT": 0.2},
    "trade_m": {"DE": 7.5, "FR": 2.2, "NL": 2.6, "BE": 1.8, "LU": 0.3, "CH": 0.8, "AT": 2.0, "PL": 2.6, "CZ": 1.8, "DK": 0.3, "NO": 0.2, "SE": 0.5, "IT": 4.0, "ES": 1.8,
                "PT": 0.2, "GB": 1.0, "IE": 0.8, "SI": 0.4, "SK": 0.8, "HU": 2.0, "FI": 0.2, "HR": 0.3, "RS": 0.8, "BA": 0.1, "ME": 0.05, "MK": 0.6, "AL": 0.05, "XK": 0.03,
                "RO": 5.5, "GR": 3.5, "EE": 0.05, "LV": 0.05, "LT": 0.3},
}
# президент избирается прямым голосованием в два тура на 5 лет (не более двух сроков); Румен Радев ушёл в отставку в январе 2026 года, обязанности исполняет
# Илиана Йотова до очередных выборов осенью 2026 года (ноябрь -> 10-й месяц игры).
ELEC = {"sys": "Пропорциональная система по 31 многомандатному округу (240 мест, барьер 4 %, преференциальный голос)", "turn": 0.40,
        "note": "Однопалатное Народное собрание (240 депутатов) избирается на 4 года; явка на выборах 2024 года — около 39 %. Президент и вице-президент избираются прямым голосованием в два тура на 5 лет; "
                "президент назначает служебное правительство и распускает собрание, если три мандата не дали кабинета.",
        "head": "direct", "title": "президента Республики", "title_n": "Президент Республики Болгария", "term": 60, "first": 10, "cand0": "Кандидат ГЕРБ–СДС"}
RAD_CUR = "Парламентская республика"
MONARCHY = False
