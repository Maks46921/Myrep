# Беларусь (BY), январь 2026. Сборка из by_core.py / by_laws.py / by_events.py (см. docs/NEWC_SPEC.md); помощники — by_lib.py (поверх ie_lib.py).
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, ".."))
import datio
from by_lib import *
from by_core import C
import by_laws as L
import by_events as EV

# 0 «Белая Русь», 1 КПБ, 2 РПТС, 3 ЛДП, 4 либералы и «третий путь», 5 «Зелёные» и экологи, 6 прочие и «против всех»,
# 7 национальные демократы в эмиграции, 8 беспартийные депутаты президентской вертикали, 9 демократические силы (Тихановская)
SLOT_ARCH = ["own", "left", "soc", "popr", "lib", "green", "none", "cons", "region", "none"]
ARCHS = list(SLOT_KEY)
bias, T_ = calibrate(C)          # подгоняет C["regions"][i]["loy"]
P = C["policy"]; M = C["macro"]; gdp = M["gdp"]


def col(c): return {"__c": [c[0], c[1], c[2], 1]}


POLICY_BASE = [("income", "Подоходный налог", "tax"), ("social", "Взносы в соцстрахование", "tax"), ("corp", "Налог на прибыль", "tax"),
               ("vat", "НДС и акцизы", "tax"), ("emit", "Эмиссия денег (Нацбанк)", "tax"), ("pensions", "Пенсии", "spend"), ("benefits", "Пособия и соцпомощь", "spend"),
               ("edu", "Образование и наука", "spend"), ("health", "Здравоохранение", "spend"), ("army", "Вооружённые силы", "spend"), ("police", "Милиция и суды", "spend"),
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

# прочие доходы (неналоговые доходы, дивиденды госпредприятий, земельный налог и налог на недвижимость, экологический налог,
# компенсации России за «налоговый манёвр»), % ВВП — подогнано так, чтобы стартовый дефицит ≈ def_target
OTHER0 = 6.7

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

# торговля: товары + услуги, млрд € в год (оценки 2025 года, округлено). trade_x — экспорт Беларуси в страну, trade_m — импорт из неё.
# Внешнеторговый оборот товаров и услуг 2025 года — 105,2 млрд $ (≈ 93 млрд €, Нацбанк). Россия — около 60 % оборота (энергоносители, металл,
# машины в обмен на продовольствие, технику, мебель, нефтепродукты); второй партнёр вне игры — Китай (≈ 8 млрд $), затем Казахстан, Турция, ОАЭ.
# ЕС (Евростат, 2024): экспорт ЕС в Беларусь 6,8 млрд €, импорт из Беларуси 1,3 млрд € — в 2025 году ещё меньше из-за санкций и закрытых переходов.
# Официальная торговля с Украиной почти остановлена войной; Косово Беларусь не признаёт.
WORLD = {
    "name": "Беларусь", "cap": "Минск", "latlon": (53.90, 27.56), "pop": 9.06, "gdp": 84.0, "debt": 27.0, "growth": 1.3, "infl": 7.0, "unemp": 3.0, "def": 1.5,
    "stab": 60, "appr": 45,
    "gov": "правительство Александра Турчина, назначенное президентом Александром Лукашенко; все 110 мест Палаты представителей у «Белой Руси», беспартийных и трёх лояльных партий",
    "gov_party": "Белая Русь", "pot": 1.6, "ecb_w": 0.0,
    "stance": {"eu": -0.9, "aus": 0.0, "trd": -0.3, "brd": -0.4, "nuk": 0.7},
    "desc": "Авторитарная президентская республика, которой с 1994 года правит Александр Лукашенко: ближайший союзник России в Союзном государстве, ОДКБ и ЕАЭС, плацдарм российского ядерного оружия и войск, нападавших на Украину в 2022 году. Экономика — наполовину государственная, живёт на российском газе, нефти и рынке; калий и нефтепродукты под санкциями ЕС. Для соседей по ЕС — источник миграционного давления, шаров-контрабандистов и политзаключённых; для Москвы и Пекина — надёжный партнёр.",
    "leader": "Премьер-министр Республики Беларусь",
    "pn": ["Белая Русь", "КПБ", "РПТС", "ЛДП", "Либералы", "Зелёные", "Прочие", "НацДем", "Беспарт.", "Демсилы"],
    "eu": False, "euro": False,
    "likes": "отказ от санкций и критики выборов, торговля без политических условий, поддержка Союзного государства и «многополярного мира», признание белорусской АЭС, открытые переходы для фур и поездов Китай — Европа, переговоры напрямую с президентом",
    "dislikes": "санкции против калия, нефтепродуктов и «Белавиа», поддержка Светланы Тихановской и эмиграции, бело-красно-белый флаг, размещение войск НАТО у границы, закрытие пограничных переходов, требования освободить всех политзаключённых и признать выборы нелегитимными",
    "open": 0.70, "stance0": -0.3, "ccol": (0.52, 0.60, 0.44, 1.0),
    "rel": {"DE": 22, "FR": 22, "NL": 20, "BE": 20, "LU": 22, "CH": 30, "AT": 28, "PL": 10, "CZ": 18, "DK": 18, "NO": 18, "SE": 16, "IT": 30, "ES": 28, "PT": 25,
            "GB": 15, "IE": 22, "SI": 28, "SK": 40, "HU": 50, "FI": 18, "HR": 25, "RS": 62, "BA": 35, "ME": 25, "MK": 30, "AL": 20, "XK": 2, "BG": 30, "RO": 20, "GR": 35,
            "EE": 12, "LV": 10, "LT": 6, "MD": 30, "UA": 10, "RU": 92},
    "trade_x": {"DE": 0.25, "FR": 0.04, "NL": 0.06, "BE": 0.03, "LU": 0.005, "CH": 0.05, "AT": 0.03, "PL": 0.50, "CZ": 0.04, "DK": 0.01, "NO": 0.02, "SE": 0.02, "IT": 0.06,
                "ES": 0.02, "PT": 0.005, "GB": 0.05, "IE": 0.01, "SI": 0.01, "SK": 0.02, "HU": 0.04, "FI": 0.02, "HR": 0.01, "RS": 0.15, "BA": 0.02, "ME": 0.01, "MK": 0.01,
                "AL": 0.005, "XK": 0.001, "BG": 0.02, "RO": 0.02, "GR": 0.01, "EE": 0.04, "LV": 0.12, "LT": 0.35, "MD": 0.25, "UA": 0.02, "RU": 26.0},
    "trade_m": {"DE": 1.60, "FR": 0.25, "NL": 0.30, "BE": 0.15, "LU": 0.005, "CH": 0.15, "AT": 0.15, "PL": 1.30, "CZ": 0.20, "DK": 0.06, "NO": 0.03, "SE": 0.06, "IT": 0.55,
                "ES": 0.12, "PT": 0.01, "GB": 0.12, "IE": 0.02, "SI": 0.03, "SK": 0.06, "HU": 0.12, "FI": 0.03, "HR": 0.01, "RS": 0.08, "BA": 0.01, "ME": 0.005, "MK": 0.005,
                "AL": 0.005, "XK": 0.001, "BG": 0.03, "RO": 0.06, "GR": 0.03, "EE": 0.03, "LV": 0.20, "LT": 0.60, "MD": 0.08, "UA": 0.02, "RU": 29.0},
}
# Президент избирается прямым голосованием на 5 лет; по Конституции 2022 года — не более двух сроков (отсчёт с новой редакции).
# Александр Лукашенко объявлен избранным 26 января 2025 года (86,8 %), инаугурация — 25 марта 2025 года; следующие выборы — около января 2030 года (48-й месяц игры).
# Палата представителей избрана 25 февраля 2024 года на 5 лет: следующие выборы — февраль 2029 года.
ELEC = {"sys": "Мажоритарная система: 110 одномандатных округов; избирательные комиссии формируются из провластных организаций, пятидневное досрочное голосование, независимые наблюдатели и ОБСЕ не допускаются",
        "turn": 0.73,
        "note": "Палата представителей избирается на 5 лет, Совет Республики (64 члена) — местными Советами и президентом. Президент Республики избирается прямым голосованием (во втором туре — два лидера первого) на 5 лет; голосование необязательно. Выборы 2020 и 2025 годов ЕС, США и Великобритания не признали ни свободными, ни честными; ОБСЕ на выборы не приглашается. По Конституции 2022 года над парламентом стоит Всебелорусское народное собрание (1200 делегатов).",
        "head": "direct", "title": "президента Республики Беларусь", "title_n": "Президент Республики Беларусь", "term": 60, "first": 48, "cand0": "Кандидат власти (Александр Лукашенко или преемник)"}
RAD_CUR = "Президентская республика"
MONARCHY = False
