# Общая библиотека для малых стран версии 0.66 (LI, MT, AD, SM, MC, PM, CY): сборка словаря D по компактному описанию страны,
# автоматические таблицы торговли и отношений, помощники для тем законов. Формат итоговых данных — как у data_md.py (docs/NEWC_SPEC.md).
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, ".."))
import math
import datio, gdconst
import ie_lib
from ie_lib import GROUPS, g, V, T, TRAITS, MIN_BASE, numtxt, _norm, calibrate

# позиции слотов (в тексте тем законов ps= можно писать p(VU=3, FBP=-2) — по коротким именам партий конкретной страны)
POS = ["own", "soc", "popl", "cons", "left", "popr", "oth", "euro", "region", "prot"]

ARCH_SPECIAL = {k: list(v) for k, v in ie_lib.ARCH_SPECIAL.items()}
ARCH_SPECIAL["popl"] = [(9, {"a": {"equal_shift": 2.0, "gb_Пенсионеры": 2.0, "growth_bonus": -0.03}}, "Пенсии и цены прежде всего"),
                        (2, {"a": {"sec_bonus": 1.5, "reg_unrest_shift": -1.5, "gb_Силовики": 1.0}}, "Порядок и безопасность"),
                        (8, {"a": {"reg_dev_bonus": 2.0, "reg_unrest_shift": -1.0}}, "Интересы местных общин")]
ARCH_SPECIAL["euro"] = [(11, {"a": {"growth_bonus": 0.03, "dip_bonus": 1.5, "mood_shift": 0.1}}, "Сближение с Европой без оговорок"),
                        (10, {"a": {"corr_shift": -3.0, "gb_Молодёжь": 0.5, "dem_shift": 0.02}}, "Прозрачность и независимые суды")]
ARCH_SPECIAL["libr"] = [(0, {"a": {"eff_bonus": 0.008, "equal_shift": -0.5}}, "Низкие налоги и бережливость"),
                        (5, {"a": {"growth_bonus": 0.08}}, "Открытая экономика"),
                        (11, {"a": {"growth_bonus": 0.04, "mood_shift": 0.1, "dip_bonus": 0.8}}, "Деловая дипломатия")]
ARCH_SPECIAL["soc"] = [x for x in ARCH_SPECIAL["soc"]]
ARCH_DEMANDS = dict(ie_lib.ARCH_DEMANDS)
ARCH_DEMANDS["popl"] = [("pensions", ">=", 1.04, True, "пенсии"), ("subs", ">=", 1.0, True, "субсидии и компенсации")]
ARCH_DEMANDS["euro"] = [("police", ">=", 1.04, True, "полиция, прокуратура и суды"), ("edu", ">=", 1.0, True, "образование")]
ARCH_DEMANDS["libr"] = [("admin", "<=", 0.97, True, "госаппарат"), ("corp", "<=", 0.97, True, "налог на прибыль")]
ARCH_DEMANDS["soc"] = [("pensions", ">=", 1.00, True, "пенсии"), ("benefits", ">=", 1.00, True, "пособия")]


def mk_p(names):
    """names: 10 коротких идентификаторов партий по слотам. Возвращает p(**kw) -> {слот: значение}; допустимы и числовые ключи (p(**{'3': 2}))."""
    idx = {n: i for i, n in enumerate(names) if n}

    def p(**kw):
        out = {}
        for k, v in kw.items():
            if k.isdigit():
                out[int(k)] = float(v)
            elif k in idx:
                out[idx[k]] = float(v)
            else:
                raise KeyError("нет партии %s среди %s" % (k, names))
        return out
    return p


def demands_list(arch, P, gdp):
    out = []
    for key, op, k, ab, nm in ARCH_DEMANDS.get(arch, []):
        d = P[key]
        val = round(d * k * gdp / 100.0, 3 if gdp < 30 else 2)
        if val < 0.001:
            continue
        txt = ("%.3f" % val if val < 0.1 else "%.2f" % val).replace(".", ",")
        out.append({"key": key, "op": op, "val": float(val), "abs": True,
                    "text": "%s %s %s млрд € в год" % (nm, "не ниже" if op == ">=" else "не выше", txt)})
    return out


def min_special(slot_archs):
    out = {}
    for s, a in enumerate(slot_archs):
        for (m, spec, title) in ARCH_SPECIAL.get(a, []):
            d = dict(spec); d["t"] = title
            out["%d:%d" % (m, s)] = d
    return out


def R(code, name, short, pop, pcrel, dev, unrest, auto, reg, tr, sec, infra, edu, health, env, mix, desc, E):
    return dict(code=code, name=name, short=short, pop=pop, pcrel=pcrel, dev=dev, unrest=unrest, auto=auto, reg=reg, tr=tr,
                sec={"ind": sec[0], "agr": sec[1], "srv": sec[2], "res": sec[3]}, infra=infra, edu=edu, health=health, env=env, mix=mix, desc=desc, E=E)


def col(c):
    return {"__c": [c[0], c[1], c[2], 1]}


POLICY_BASE = [("income", "Подоходный налог", "tax"), ("social", "Взносы в соцстрахование", "tax"), ("corp", "Налог на прибыль", "tax"),
               ("vat", "НДС и акцизы", "tax"), ("emit", "Эмиссия денег", "tax"), ("pensions", "Пенсии", "spend"), ("benefits", "Пособия и соцпомощь", "spend"),
               ("edu", "Образование и наука", "spend"), ("health", "Здравоохранение", "spend"), ("army", "Армия и оборона", "spend"), ("police", "Полиция и суды", "spend"),
               ("infra", "Инфраструктура и транспорт", "spend"), ("eco", "Экология", "spend"), ("subs", "Субсидии бизнесу и аграриям", "spend"), ("admin", "Госаппарат", "spend")]


def assemble(C, slot_arch, L, EV, remove=None, fund_add=None):
    """C — описание страны (как md_core.C), L — модуль законов (TOPICS/DE_TOPICS/LAW_TAGS/FUND/PARAMS), EV — модуль событий (EVENTS_C, NEWS_C, REG_EVENTS).
    Возвращает (D, E, REG_EVENTS). Прочие доходы OTHER0 подгоняются автоматически под стартовый дефицит def_target."""
    bias, T_ = calibrate(C)
    P = C["policy"]; M = C["macro"]; gdp = M["gdp"]
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
        a = slot_arch[s]
        dem.append([] if s == 0 or a == "none" else demands_list(a, P, gdp))
    ministries = [{"name": C["ministries"][i], "desc": MIN_BASE[i][0], "base": MIN_BASE[i][1]} for i in range(12)]
    taxes = P["income"] + P["social"] + P["corp"] + P["vat"]
    spend = sum(P[k] for k in ["pensions", "benefits", "edu", "health", "army", "police", "infra", "eco", "subs", "admin"])
    interest = C["info"]["debt_pct"] * M["debt_base"]
    other0 = round(spend + interest - taxes - M["def_target"], 2)
    D = {
        "PARTY_NAMES": [p_["name"] for p_ in C["parties"]],
        "PARCH": slot_arch,
        "PARTY_DESC": [p_["desc"] for p_ in C["parties"]],
        "PARTY_COLORS": [col(p_["color"]) for p_ in C["parties"]],
        "LEAN": C["lean"],
        "HEMI_ORDER": C["hemi"],
        "PARTY_LEADERS": [p_["leader"] for p_ in C["parties"]],
        "PARTY_DEMANDS": dem,
        "MINISTRIES": ministries,
        "PARTY_MINISTRIES": [p_["min"] for p_ in C["parties"]],
        "MIN_SPECIAL": min_special(slot_arch),
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
        "GDP0": gdp, "G_POT": M["G_POT"], "G_NEU": M["G_NEU"], "I_NEU": M["I_NEU"], "I_TGT": M["I_TGT"], "U_NEU": M["U_NEU"], "RATE0": M["RATE0"], "OTHER0": other0,
        "UPPER": C["upper"],
        "MACRO": {"gdp": gdp, "debt": M["debt"], "growth": M["growth"], "infl": M["infl"], "unemp": M["unemp"], "ecb_w": M["ecb_w"], "debt_base": M["debt_base"],
                  "debt_thr": M["debt_thr"], "debt_slope": M["debt_slope"], "elapsed": M["elapsed"], "parl_term": M["parl_term"], "threshold": M["threshold"],
                  "impeach_seats": M["impeach_seats"], "constr": M["constr"], "minority_ok": M["minority_ok"], "def_target": M["def_target"], "euro": M["euro"], "eu": M["eu"],
                  "fiscal_base": M["fiscal_base"], "fiscal_name": M["fiscal_name"], "cb_own": M["cb_own"], "cb_off": M["cb_off"], "crisis_limit": M["crisis_limit"]},
        "TERMS": {**C["terms"], **C["terms_extra"]},
        "INFO": C["info"],
        "COALITION0": C["coalition"],
        "ARCHS": list(POS),
        "DE_TOPICS": L.DE_TOPICS,
        "DE_PARAM": L.PARAMS,
        "DE_NEW_PARAMS": [],
        "DE_REMOVE": remove if remove is not None else ["central_bank", "pres_term_law", "pres_vote_rule", "export_duty", "tariff_cap", "gov_form", "state_structure", "impeach_rule",
                                                       "referendum_law", "debt_brake", "auto_policy", "regional_gov_x"],
        "DE_FUND_ADD": L.FUND,
        "LAW_TAGS": L.LAW_TAGS,
        "EVENTS_C": EV.EVENTS_C,
        "NEWS_C": EV.NEWS_C,
        "EVENTS_SPECIAL": [],
        "LAW_START": {},
    }
    E = [[round(x, 2) for x in r["E"]] for r in C["regions"]]
    return D, E, EV.REG_EVENTS


# ---------- торговля и отношения со всеми странами игры ----------
ALL38 = ["DE", "FR", "NL", "BE", "LU", "AT", "CH", "CZ", "DK", "ES", "IT", "NO", "PL", "PT", "SE", "GB", "IE", "SI", "SK", "HU", "FI", "HR", "RS", "BA", "ME", "MK",
         "AL", "XK", "BG", "RO", "GR", "EE", "LV", "LT", "MD", "BY", "UA", "RU"]
NEW66 = ["LI", "MT", "AD", "SM", "MC", "PM", "CY"]
_GDP = {"DE": 4600, "FR": 3050, "NL": 1100, "BE": 580, "LU": 86, "AT": 480, "CH": 800, "CZ": 300, "DK": 400, "ES": 1650, "IT": 2200, "NO": 480, "PL": 800, "PT": 290,
        "SE": 560, "GB": 3400, "IE": 520, "SI": 68, "SK": 120, "HU": 200, "FI": 280, "HR": 85, "RS": 80, "BA": 27, "ME": 7, "MK": 14, "AL": 25, "XK": 10, "BG": 108,
        "RO": 340, "GR": 250, "EE": 40, "LV": 42, "LT": 80, "MD": 18, "BY": 70, "UA": 190, "RU": 1800,
        "LI": 7, "MT": 22, "AD": 3.8, "SM": 1.9, "MC": 8.5, "PM": 1.1, "CY": 34}
_LL = {"DE": (52.5, 13.4), "FR": (48.9, 2.35), "NL": (52.4, 4.9), "BE": (50.85, 4.35), "LU": (49.6, 6.1), "AT": (48.2, 16.4), "CH": (46.95, 7.45), "CZ": (50.1, 14.4),
       "DK": (55.7, 12.6), "ES": (40.4, -3.7), "IT": (41.9, 12.5), "NO": (59.9, 10.75), "PL": (52.2, 21.0), "PT": (38.7, -9.1), "SE": (59.3, 18.1), "GB": (51.5, -0.1),
       "IE": (53.3, -6.3), "SI": (46.05, 14.5), "SK": (48.15, 17.1), "HU": (47.5, 19.05), "FI": (60.2, 24.9), "HR": (45.8, 16.0), "RS": (44.8, 20.5), "BA": (43.85, 18.4),
       "ME": (42.4, 19.3), "MK": (42.0, 21.4), "AL": (41.3, 19.8), "XK": (42.65, 21.15), "BG": (42.7, 23.3), "RO": (44.4, 26.1), "GR": (38.0, 23.7), "EE": (59.4, 24.75),
       "LV": (56.95, 24.1), "LT": (54.7, 25.3), "MD": (47.0, 28.85), "BY": (53.9, 27.55), "UA": (50.45, 30.5), "RU": (55.75, 37.6),
       "LI": (47.14, 9.52), "MT": (35.9, 14.5), "AD": (42.5, 1.52), "SM": (43.94, 12.45), "MC": (43.74, 7.42), "PM": (46.84, 29.63), "CY": (35.17, 33.36)}


def _dist(a, b):
    (la, oa), (lb, ob) = _LL[a], _LL[b]
    return math.hypot((la - lb) * 111.0, (oa - ob) * 111.0 * math.cos(math.radians((la + lb) / 2)))


def auto_trade(cc, total, over=None, lam=1100.0, expo=0.75, only_eu=None):
    """total — суммарный экспорт/импорт страны (млрд €) всем 38 странам игры; доля i ~ ВВП^0.75 * exp(-расстояние/лямбда); over — точные значения (подменяют)."""
    over = dict(over or {})
    w = {o: (_GDP[o] ** expo) * math.exp(-_dist(cc, o) / lam) for o in ALL38 + NEW66 if o != cc and o not in over}
    rest = max(total - sum(over.values()), 0.0)
    s = sum(w.values()) or 1.0
    out = {o: round(rest * v / s, 3) for o, v in w.items()}
    out.update({o: float(v) for o, v in over.items()})
    return out


def auto_rel(cc, base=60, over=None, eu_bonus=0, east=0):
    """отношения 0–100: базовый уровень + бонус близости по расстоянию; over — точные значения."""
    out = {}
    for o in ALL38 + NEW66:
        if o == cc:
            continue
        d = _dist(cc, o)
        v = base + 8 * math.exp(-d / 800.0) - 6 * (d > 2500)
        if o in ("RU", "BY"):
            v += east
        out[o] = int(round(max(5, min(97, v))))
    out.update(over or {})
    return out


# ---------- параметры законов и имена ----------
def par_num(name, unit, fmt, lo, hi, fs, ref, step, desc):
    return {"unit": unit, "fmt": fmt, "name": name, "lo": lo, "hi": hi, "fs": fs, "ref": ref, "step": step, "desc": desc}


def std_params(min_wage, pension_age, family_policy, migration, labor_code, state_property, unemp_benefit, copay, agri_law, mil_service,
               paid_leave=28, carbon_ref=0, uni_ref=45):
    """min_wage, pension_age, family_policy, migration, labor_code — par_num(...); остальные — (ref, название) либо (ref, hi, название)."""
    return {
        "paid_leave": {"ref": paid_leave, "unit": "календарных дней в году", "fmt": "%d календарных дней в году"},
        "min_wage": min_wage, "pension_age": pension_age, "family_policy": family_policy, "migration": migration,
        "state_property": {"ref": state_property[0], "name": state_property[1]},
        "labor_code": labor_code,
        "unemp_benefit": {"ref": unemp_benefit[0], "hi": unemp_benefit[1], "name": unemp_benefit[2]},
        "copay": {"ref": copay[0], "name": copay[1]},
        "carbon_tax": {"ref": carbon_ref, "unit": "€ за тонну CO₂", "fmt": "%d € за тонну CO₂", "name": "Плата за выбросы CO₂", "lo": 0, "hi": 60, "step": 10.0},
        "agri_law": {"ref": agri_law[0], "unit": "% надбавка", "fmt": "надбавки и защита фермеров, %d%%", "name": agri_law[1]},
        "uni_places": {"ref": uni_ref},
        "mil_service": {"ref": mil_service[0], "name": mil_service[1]},
    }


def gen_names(firsts, lasts, n):
    """n детерминированных пар «имя фамилия» из списков (пул игровых министров; к реальным лицам не привязан)."""
    out = []
    i = 0
    while len(out) < n:
        f = firsts[i % len(firsts)]
        l = lasts[(i * 7 + i // len(firsts) * 3) % len(lasts)]
        nm = "%s %s" % (f, l)
        if nm not in out:
            out.append(nm)
        i += 1
    return out


def finish_laws(TOPICS):
    """теги, список fund и DE_TOPICS из списка тем (как в конце md_laws.py)"""
    tags = {}
    for t in TOPICS:
        for j, v in enumerate(t["v"]):
            tg = v.pop("tag", None)
            if tg is not None and tg[1] != 0:
                tags.setdefault(t["id"], {})[j] = [tg[0], tg[1]]
    fund = [t["id"] for t in TOPICS if t.get("fund")]
    topics = [{"id": t["id"], "cat": t["cat"], "name": t["name"], "desc": t["desc"], "v": t["v"]} for t in TOPICS]
    return topics, tags, fund


class Mod:
    """простой контейнер вместо модулей законов/событий"""
    def __init__(self, **kw):
        self.__dict__.update(kw)


def O(l, **fx):
    return {"l": l, "fx": fx}


def Ev(t, *opts, **kw):
    d = {"t": t, "o": list(opts)}
    d.update(kw)
    return d


def News(text, **fx):
    return {"text": text, "fx": fx}


def RegEv(t, reg, *opts):
    """региональное событие: opts — кортежи (текст, {fx})"""
    return {"t": t, "reg": reg, "o": [{"l": l, "fx": fx} for l, fx in opts]}
