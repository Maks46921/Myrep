# Россия (RU), январь 2026. Сборка из ru_core.py / ru_laws.py / ru_events.py (см. docs/NEWC_SPEC.md); помощники — ru_lib.py (поверх ie_lib.py).
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, ".."))
import datio
from ru_lib import *
from ru_core import C
import ru_laws as L
import ru_events as EV

# 0 «Единая Россия», 1 КПРФ, 2 ЛДПР, 3 СРЗП, 4 «Новые люди», 5 «Яблоко», 6 прочие партии, 7 Партия пенсионеров, 8 самовыдвиженцы, 9 несистемная оппозиция
ARCHS = list(SLOT_KEY)
bias, T_ = calibrate(C)          # подгоняет C["regions"][i]["loy"]
P = C["policy"]; M = C["macro"]; gdp = M["gdp"]


def col(c): return {"__c": [c[0], c[1], c[2], 1]}


POLICY_BASE = [("income", "Подоходный налог", "tax"), ("social", "Взносы в соцстрахование", "tax"), ("corp", "Налог на прибыль", "tax"),
               ("vat", "НДС и акцизы", "tax"), ("emit", "Эмиссия денег (Банк России)", "tax"), ("pensions", "Пенсии", "spend"), ("benefits", "Пособия и соцпомощь", "spend"),
               ("edu", "Образование и наука", "spend"), ("health", "Здравоохранение", "spend"), ("army", "Вооружённые силы", "spend"), ("police", "Полиция и суды", "spend"),
               ("infra", "Инфраструктура и транспорт", "spend"), ("eco", "Экология", "spend"), ("subs", "Субсидии бизнесу и аграриям", "spend"), ("admin", "Госаппарат", "spend")]
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

# прочие доходы, % ВВП: НДПИ и прочие нефтегазовые налоги (≈ 4 % ВВП в 2025 году), дивиденды госкомпаний (Сбербанк, «Газпром нефть», «Роснефть»),
# имущественные и земельные налоги, госпошлины, неналоговые доходы и средства ФНБ — подобрано так, чтобы стартовый дефицит ≈ def_target (2,6 % ВВП)
OTHER0 = 10.4

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

# торговля: товары + услуги, млрд € в год (оценки по Евростату, ФТС и национальной статистике за 2024–2025 годы, округлено).
# trade_x — экспорт России в страну, trade_m — импорт из неё. Торговля с ЕС упала примерно на 60–90 % против 2021 года; остались СПГ (Бельгия, Франция,
# Испания, Нидерланды — запрет ЕС с 2027 года), трубопроводный газ «Турецкого потока» и нефть «Дружбы» (Венгрия, Словакия, Сербия), удобрения, никель, палладий,
# ядерное топливо, а в обратную сторону — лекарства, химия, оборудование и продукты, не попавшие под санкции. Крупнейшие партнёры вне игры: Китай (≈ 220 млрд $),
# Индия (нефть), Турция, Казахстан. С Украиной торговли нет; с Белоруссией — Союзное государство и ЕАЭС (оборот ≈ 52–55 млрд $).
WORLD = {
    "name": "Россия", "cap": "Москва", "latlon": (55.75, 37.62), "pop": 146.1, "gdp": 2270.0, "debt": 405.0, "growth": 1.0, "infl": 5.6, "unemp": 2.2, "def": 2.6,
    "stab": 58, "appr": 50,
    "gov": "правительство Михаила Мишустина (с 2020 года, переназначено в мае 2024 года) при президенте Владимире Путине; конституционное большинство «Единой России» в Государственной думе (около 324 из 450 мест)",
    "gov_party": "ЕР", "pot": 1.2, "ecb_w": 0.0,
    "stance": {"eu": -1.0, "aus": 0.2, "trd": -0.3, "brd": -0.3, "nuk": 0.9},
    "desc": "Крупнейшая по территории страна мира и ядерная держава, с февраля 2022 года ведущая полномасштабную войну против Украины. Для большинства европейских соседей — главная угроза безопасности: ЕС, Великобритания, Швейцария и Норвегия ввели санкции, российские газ и нефть почти ушли с европейского рынка, сообщение с Финляндией, странами Балтии и Польшей закрыто или ограничено. Москва делает ставку на Китай, Индию, БРИКС и «дружественные» страны, сохраняя влияние в Белоруссии, Сербии, Венгрии, Словакии и Республике Сербской.",
    "leader": "Председатель Правительства Российской Федерации",
    "pn": ["ЕР", "КПРФ", "ЛДПР", "СРЗП", "НЛ", "Яблоко", "Прочие", "Пенсионеры", "Самовыдв.", "Несистемные"],
    "eu": False, "euro": False,
    "likes": "признание «интересов безопасности» России и отказ от расширения НАТО, снятие санкций и разморозка резервов, покупка российского газа, нефти и ядерного топлива, «традиционные ценности», нейтралитет в войне и прямой диалог с Кремлём в обход Брюсселя",
    "dislikes": "военная помощь Украине и поставки дальнобойного оружия, новые пакеты санкций и использование замороженных активов, расширение НАТО и войска у российских границ, закрытие портов и воздушного пространства, ограничения транзита в Калининград, поддержка российской оппозиции и эмигрантов, снос советских памятников",
    "open": 0.35, "stance0": -0.3, "ccol": (0.50, 0.36, 0.30, 1.0),
    "rel": {"DE": 12, "FR": 10, "NL": 8, "BE": 12, "LU": 15, "CH": 22, "AT": 18, "PL": 4, "CZ": 8, "DK": 6, "NO": 10, "SE": 6, "IT": 22, "ES": 18, "PT": 15,
            "GB": 6, "IE": 12, "SI": 18, "SK": 42, "HU": 50, "FI": 6, "HR": 14, "RS": 70, "BA": 40, "ME": 14, "MK": 15, "AL": 8, "XK": 2, "BG": 22, "RO": 10, "GR": 22,
            "EE": 3, "LV": 4, "LT": 3, "MD": 10, "BY": 92, "UA": 0},
    "trade_x": {"DE": 1.6, "FR": 2.5, "NL": 2.0, "BE": 3.0, "LU": 0.05, "CH": 0.4, "AT": 0.5, "PL": 0.7, "CZ": 0.6, "DK": 0.2, "NO": 0.1, "SE": 0.15, "IT": 1.8, "ES": 2.6,
                "PT": 0.3, "GB": 0.6, "IE": 0.05, "SI": 0.25, "SK": 3.0, "HU": 5.0, "FI": 0.5, "HR": 0.15, "RS": 1.6, "BA": 0.4, "ME": 0.03, "MK": 0.15, "AL": 0.05, "XK": 0.0,
                "BG": 0.4, "RO": 0.4, "GR": 0.8, "EE": 0.1, "LV": 0.4, "LT": 0.3, "MD": 0.15, "BY": 24.0, "UA": 0.0},
    "trade_m": {"DE": 7.0, "FR": 2.0, "NL": 1.4, "BE": 1.4, "LU": 0.05, "CH": 2.6, "AT": 1.2, "PL": 1.2, "CZ": 0.8, "DK": 0.4, "NO": 0.05, "SE": 0.3, "IT": 4.2, "ES": 1.2,
                "PT": 0.1, "GB": 0.4, "IE": 0.5, "SI": 0.8, "SK": 0.5, "HU": 1.0, "FI": 0.5, "HR": 0.15, "RS": 0.9, "BA": 0.1, "ME": 0.02, "MK": 0.05, "AL": 0.01, "XK": 0.0,
                "BG": 0.4, "RO": 0.4, "GR": 0.3, "EE": 0.15, "LV": 0.6, "LT": 1.0, "MD": 0.1, "BY": 22.0, "UA": 0.0},
}
# Президент избирается прямым голосованием в два тура на 6 лет; Владимир Путин переизбран в марте 2024 года (87 % по данным ЦИК), поправки 2020 года «обнулили»
# его прежние сроки и позволяют участвовать и в выборах 2030 года. Следующие выборы — март 2030 года (50-й месяц игры).
ELEC = {"sys": "Смешанная система: 225 депутатов по федеральным партийным спискам (порог 5 %, распределение мест пропорционально) и 225 — в одномандатных округах относительным большинством; голосование длится до трёх дней, во многих регионах — и дистанционно (ДЭГ)",
        "turn": 0.52,
        "note": "Государственная дума избирается на 5 лет; следующие выборы — сентябрь 2026 года. Совет Федерации не избирается: сенаторов направляют губернаторы и региональные парламенты. Президент Российской Федерации избирается прямым голосованием в два тура (второй тур не понадобился ни разу с 1996 года) на 6 лет; голосование необязательно. ОБСЕ не направляет наблюдателей с 2021 года, независимые наблюдатели («Голос») фиксируют давление на бюджетников и вбросы; признанные «иностранными агентами» не могут баллотироваться.",
        "head": "direct", "title": "Президента Российской Федерации", "title_n": "Президент Российской Федерации", "term": 72, "first": 50, "cand0": "Кандидат «Единой России»"}
RAD_CUR = "Президентская республика (смешанная форма правления)"
MONARCHY = False
