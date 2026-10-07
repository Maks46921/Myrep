import sys, json, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'de'))
from common import *
import fr, nl, be, lu, laws_c, world14 as W
import de_calib as DC
CS = {"FR": fr.C, "NL": nl.C, "BE": be.C, "LU": lu.C}
import importlib
LAWPARAMS = {}
for _cc, _C in W.NEWC.items():
    CS[_cc] = _C
    _L = importlib.import_module("l_%s" % _cc.lower())
    laws_c.LAW_INFO[_cc] = _L.INFO; laws_c.TOPICS[_cc] = _L.topics; LAWPARAMS[_cc] = _L.params()
    laws_c.EVENTS_X = getattr(laws_c, "EVENTS_X", {}); laws_c.EVENTS_X[_cc] = getattr(_L, "EVENTS", [])
    laws_c.NEWS_X = getattr(laws_c, "NEWS_X", {}); laws_c.NEWS_X[_cc] = getattr(_L, "NEWS", [])
# --- v15: дополнительные законы/события/новости из x_<cc>.py ---
laws_c.EVENTS_X = getattr(laws_c, "EVENTS_X", {}); laws_c.NEWS_X = getattr(laws_c, "NEWS_X", {})
for _cc in list(CS.keys()):
    try:
        _X = importlib.import_module("x_%s" % _cc.lower())
    except ModuleNotFoundError:
        continue
    laws_c.TOPICS[_cc] = (lambda b, x: (lambda info: b(info) + x(info)))(laws_c.TOPICS[_cc], _X.topics_x)
    laws_c.EVENTS_X[_cc] = list(laws_c.EVENTS_X.get(_cc, [])) + list(getattr(_X, "EVENTS_X", []))
    laws_c.NEWS_X[_cc] = list(laws_c.NEWS_X.get(_cc, [])) + list(getattr(_X, "NEWS_X", []))
OTHER0 = json.load(open('other0.json')) if os.path.exists('other0.json') else {}

POLICY_BASE = [
 ("income","Подоходный налог",5.0,18.0,"tax"),("social","Взносы в соцстрахование",12.0,26.0,"tax"),("corp","Налог на прибыль и торговый налог",1.5,8.0,"tax"),
 ("vat","НДС и акцизы",5.0,13.0,"tax"),("emit","Эмиссия денег (ЕЦБ)",0.0,0.0,"tax"),("pensions","Пенсии",0.0,20.0,"spend"),("benefits","Пособия и соцпомощь",0.0,14.0,"spend"),
 ("edu","Образование и наука",0.0,10.0,"spend"),("health","Здравоохранение",0.0,14.0,"spend"),("army","Бундесвер",0.0,8.0,"spend"),("police","Полиция и суды",0.0,5.0,"spend"),
 ("infra","Инфраструктура и транспорт",0.0,9.0,"spend"),("eco","Климат и экология",0.0,5.0,"spend"),("subs","Субсидии бизнесу и аграриям",0.0,7.0,"spend"),("admin","Госаппарат",2.0,9.0,"spend")]

MIN_BASE = [
 ("Сбор налогов и контроль расходов.", '{"a": {"eff_bonus": 0.006}}'),
 ("Армия и военная безопасность.", '{"a": {"sec_bonus": 1.5}}'),
 ("Полиция, миграция и порядок в регионах.", '{"a": {"sec_bonus": 1.0, "reg_unrest_shift": -1.0}}'),
 ("Больницы, страховые кассы и лекарства.", '{"x": {"health_eff": 1.04}}'),
 ("Школы, университеты и исследования.", '{"x": {"edu_eff": 1.04}}'),
 ("Промышленность, торговля и энергетика.", '{"a": {"growth_bonus": 0.08}}'),
 ("Фермеры и продовольствие.", '{"a": {"gb_Село": 2.0}}'),
 ("Климат и охрана природы.", '{"x": {"env_eff": 1.06}}'),
 ("Дороги, железные дороги и жильё.", '{"a": {"reg_dev_bonus": 1.0, "reg_unrest_shift": -1.0}}'),
 ("Пенсии, пособия и защита работников.", '{"a": {"equal_shift": 1.5}}'),
 ("Суды, прокуратура и борьба с коррупцией.", '{"a": {"corr_shift": -2.0}}'),
 ("Отношения с ЕС и соседями, дипломатия.", '{"a": {"growth_bonus": 0.04, "mood_shift": 0.2, "dip_bonus": 1.0}}'),
]
MIN_PARTY_BASE = {  # какие министерства хочет партия по умолчанию (используется в данных стран)
}

EXTRA = {
 "FR": {"parl_d": "Национальному собранию", "parl_p": "Национальном собрании", "c": "Франция", "c_g": "Франции", "adj": "французск", "regs": "регионов", "regs_n": "регионы", "regs_d": "регионам", "regs_p": "регионах", "ctl": "Матиньон"},
 "NL": {"parl_d": "Второй палате", "parl_p": "Второй палате", "c": "Нидерланды", "c_g": "Нидерландов", "adj": "нидерландск", "regs": "провинций", "regs_n": "провинции", "regs_d": "провинциям", "regs_p": "провинциях", "ctl": "Бинненхоф"},
 "BE": {"parl_d": "Палате представителей", "parl_p": "Палате представителей", "c": "Бельгия", "c_g": "Бельгии", "adj": "бельгийск", "regs": "провинций", "regs_n": "провинции", "regs_d": "провинциям", "regs_p": "провинциях", "ctl": "Брюссель"},
 "LU": {"parl_d": "Палате депутатов", "parl_p": "Палате депутатов", "c": "Люксембург", "c_g": "Люксембурга", "adj": "люксембургск", "regs": "округов", "regs_n": "округа", "regs_d": "округам", "regs_p": "округах", "ctl": "Люксембург"},
}
def slot_arch(C):
    out = []
    for p, P in enumerate(C["parties"]):
        a = P["arch"]
        if p == 0: a = "own"
        out.append(a)
    return out

def ps_convert(v, C):
    psa = v.pop("psa", None)
    if psa is None: return v
    archs = slot_arch(C)
    ps = {}
    for p, a in enumerate(archs):
        key = a
        if p == 9: key = "prot"
        elif a == "none": key = "oth"
        if key in psa and not (key == "oth" and p == 6 and False):
            ps[p] = float(psa[key])
    # партии без архетипа 'oth' и пр.
    v["ps"] = ps
    return v

def topics_text(code, C):
    info = dict(laws_c.LAW_INFO[code]); info["name"] = C["name"]; info["gen"] = C["gen"]
    ts = laws_c.TOPICS[code](info)
    out = []; tags = {}
    for t in ts:
        vs = []
        for i, v in enumerate(t["v"]):
            v = dict(v)
            tg = v.pop("tag", None)
            if tg: tags.setdefault(t["id"], {})[i] = tg
            v = ps_convert(v, C)
            vs.append(v)
        out.append({"id": t["id"], "cat": t["cat"], "name": t["name"], "desc": t["desc"], "v": vs})
    return out, tags, [t["id"] for t in ts if t.get("fund")]

def dip_for(code, tags):
    others = [c for c in W.CODES if c != code]
    tot = sum(W.TRADE[code][c] + W.TRADE[c][code] for c in others)
    dc = {}
    for c in others:
        pair = frozenset((code, c))
        w = (W.TRADE[code][c] + W.TRADE[c][code]) / tot
        lv = W.LV0.get(pair, (2, 1, 1))
        lk, dl = W.LIKES[c]
        dc[c] = {"name": W.NAME[c], "cap": W.CAP[c], "pop": W.POP[c], "gdp": W.GDP[c], "trade": float(W.TRADE[code][c]), "rel0": float(W.REL[pair]), "w": round(w, 3),
                 "lv0": {"trade": lv[0], "sec": lv[1], "energy": lv[2]}, "leader": W.LEADER[c], "desc": W.DESC[c], "likes": lk, "dislikes": dl}
    likes = {}
    for c in others:
        L = {}
        for tid, vv in tags.items():
            for idx, (dim, sign) in vv.items():
                d = round(5.0 * sign * W.STANCE[c][dim], 1)
                if abs(d) >= 0.5: L.setdefault(tid, {})[idx] = d
        likes[c] = L
    return others, dc, likes

def region_text(C, T, bias):
    R = C["regions"]; out = []
    for i, r in enumerate(R):
        pc = r["pcrel"] / (0.6 + 0.8 * r["dev"] / 100.0)
        sec = r["sec"]
        out.append({"code": r["code"], "name": r["name"], "short": r["short"], "popm": r["pop"], "pc": round(pc, 3), "dev": float(r["dev"]), "loy": round(r["loy"], 1),
                    "unrest": float(r["unrest"]), "auto": float(r["auto"]), "reg": r["reg"], "tr": r["tr"],
                    "sec": {"ind": sec[0], "agr": sec[1], "srv": sec[2], "res": sec[3]}, "infra": float(r["infra"]), "edu": float(r["edu"]), "health": float(r["health"]),
                    "env": float(r["env"]), "mix": r["mix"], "desc": r["desc"]})
    return out

def gdarr(rows): return "[" + ", ".join(gd(x) for x in rows) + "]"

def emit_country(code):
    C = CS[code]
    bias, T = calibrate(C)
    archs = slot_arch(C)
    P = C["policy"]; M = C["macro"]; gdp = M["gdp"]
    d = {}
    d["PARTY_NAMES"] = "[" + ", ".join(q(p["name"]) for p in C["parties"]) + "]"
    d["PARCH"] = "[" + ", ".join(q(x) for x in archs) + "]"
    d["PARTY_DESC"] = "[\n" + ",\n".join("\t" + q(p["desc"]) for p in C["parties"]) + "]"
    d["PARTY_COLORS"] = "[" + ", ".join(color(p["color"]) for p in C["parties"]) + "]"
    d["LEAN"] = "{" + ", ".join('%s: [%s]' % (q(g), ", ".join(f(x, 2) for x in C["lean"][g])) for g in GROUPS) + "}"
    d["HEMI_ORDER"] = gd(C["hemi"])
    d["PARTY_LEADERS"] = "[" + ", ".join(q(p["leader"]) for p in C["parties"]) + "]"
    dem = []
    for p, pr in enumerate(C["parties"]):
        a = archs[p]
        if p == 0 or a in ("own",): dem.append("[]"); continue
        key = a
        if a == "none": dem.append("[]"); continue
        dem.append(demands_text(key, P, gdp))
    d["PARTY_DEMANDS"] = "[" + ", ".join(dem) + "]"
    mins = []
    for i in range(12):
        mins.append('{"name": %s, "desc": %s, "base": %s}' % (q(C["ministries"][i]), q(MIN_BASE[i][0]), MIN_BASE[i][1]))
    d["MINISTRIES"] = "[\n\t" + ",\n\t".join(mins) + "]"
    d["PARTY_MINISTRIES"] = gd([p["min"] for p in C["parties"]])
    d["MIN_SPECIAL"] = min_special(["none" if p == 0 else a for p, a in enumerate(archs)])
    d["PARTY_TRAITS"] = "[" + ",\n\t".join(TRAITS[p["trait"]] for p in C["parties"]) + "]"
    ld = []
    for p in C["parties"]:
        ld.append(gd(p["law"]) if p["law"] else "{}")
    d["PARTY_LAW_DEMAND"] = "[" + ", ".join(ld) + "]"
    d["MINISTER_NAMES"] = gd(C["minister_names"])
    d["GOV_NAMES"] = gd(C["gov_names"])
    regs = region_text(C, T, bias)
    d["REGIONS"] = "[\n" + ",\n".join("\t" + gd(r) for r in regs) + "]"
    d["REG_BIAS"] = "[" + ", ".join("[" + ", ".join(f(x, 3) for x in row) + "]" for row in bias) + "]"
    d["GROUP_WEIGHT"] = gd(C["gw"]); d["GROUP_BASE"] = gd(C["gb"])
    pol = []
    for k, t, lo, hi, kind in POLICY_BASE:
        if k in C.get("policy_range", {}): lo, hi = C["policy_range"][k]
        title = C.get("policy_titles", {}).get(k, t)
        v = 0.0 if k == "emit" else P[k]
        pol.append({"key": k, "title": title, "min": lo, "max": hi, "def": v, "kind": kind})
    d["POLICY"] = "[\n\t" + ",\n\t".join(gd(x) for x in pol) + "]"
    d["MARKETS_OVR"] = gd(C["markets"])
    d["DE_START_SEATS"] = gd(C["seats"])
    d["DE_START_MIN"] = gd(C["min_start"])
    d["DE_JOIN_ADJ"] = gd(C["join_adj"])
    d["SEATS"] = str(sum(C["seats"]))
    d["REGIONAL_P"] = str(C["regional_p"])
    d["GDP0"] = f(gdp, 1); d["G_POT"] = f(M["G_POT"], 2); d["G_NEU"] = f(M["G_NEU"], 2); d["I_NEU"] = f(M["I_NEU"], 2); d["I_TGT"] = "2.0"
    d["U_NEU"] = f(M["U_NEU"], 2); d["RATE0"] = f(M.get("RATE0", 2.0), 2); d["OTHER0"] = f(OTHER0.get(code, 8.0), 3)
    d["UPPER"] = gd(C["upper"])
    d["MACRO"] = gd({"gdp": gdp, "debt": M["debt"], "growth": M["growth"], "infl": M["infl"], "unemp": M["unemp"], "ecb_w": M["ecb_w"], "debt_base": M["debt_base"],
                     "debt_thr": M["debt_thr"], "debt_slope": M["debt_slope"], "elapsed": M["elapsed"], "parl_term": M["parl_term"], "threshold": M["threshold"],
                     "impeach_seats": M["impeach_seats"], "constr": M["constr"], "minority_ok": M["minority_ok"], "def_target": M["def_target"],
                     "euro": M.get("euro", True), "eu": M.get("eu", True), "fiscal_base": M.get("fiscal_base", 3.0), "fiscal_name": M.get("fiscal_name", "Правила ЕС"),
                     "cb_own": M.get("cb_own", -1.0), "cb_off": M.get("cb_off", 0.0), "crisis_limit": M.get("crisis_limit", 6)})
    d["TERMS"] = gd({**C["terms"], **(EXTRA[code] if code in EXTRA else C.get("terms_extra", {}))}); d["INFO"] = gd(C["info"])
    d["COALITION0"] = gd(C["coalition"])
    d["ARCHS"] = gd([("own" if p == 0 else ("prot" if p == 9 else ("oth" if a == "none" else a))) for p, a in enumerate(archs)])
    # законы
    topics, tags, fund = topics_text(code, C)
    d["DE_TOPICS"] = "[\n" + ",\n".join("\t" + gd(t) for t in topics) + "]"
    d["DE_PARAM"] = gd(LAWPARAMS[code] if code in LAWPARAMS else laws_c.params(code))
    d["DE_NEW_PARAMS"] = "[]"
    d["DE_REMOVE"] = gd(["central_bank", "pres_term_law", "pres_vote_rule", "export_duty", "tariff_cap", "gov_form", "state_structure", "impeach_rule", "referendum_law", "debt_brake", "auto_policy", "regional_gov_x"])
    d["DE_FUND_ADD"] = gd(fund)
    others, dc, likes = dip_for(code, tags)
    d["DIP_ORDER"] = gd(others); d["DIP_C"] = gd(dc); d["DIP_LIKES"] = gd(likes)
    d["LAW_TAGS"] = gd(tags)
    d["EVENTS_C"] = gd(getattr(laws_c, "EVENTS_X", {}).get(code, []))
    d["NEWS_C"] = gd(getattr(laws_c, "NEWS_X", {}).get(code, []))
    d["EVENTS_SPECIAL"] = gd(C.get("scripted", []))
    return d

def emit_de():
    d = {}
    d["INFO"] = gd({"capital": "Берлин", "difficulty": 2, "pop": 83.5, "gdp": 4600.0, "debt_pct": 64.0, "blurb":
        "Вы — федеральный канцлер Германии: у вас большая коалиция ХДС/ХСС и СДПГ, мощная промышленность, долговой тормоз и растущая АдГ. Подходящий старт, чтобы освоить игру."})
    d["TERMS"] = gd({"head": "канцлер", "head_g": "канцлера", "head_d": "канцлеру", "head_i": "канцлером", "parl": "Бундестаг", "parl_g": "Бундестага", "parl_in": "в Бундестаг",
                     "parl_pl": "депутатов", "reg": "земля", "reg_g": "земли", "reg_title": "Министр-президент земли", "reg_word_pl": "земли", "army": "Бундесвер",
                     "prot": "АдГ", "prot_short": "АдГ", "cap": "Берлин", "gov": "федеральное правительство", "state_unit": "16 земель", "head_role": "Федеральный канцлер"})
    d["MACRO"] = gd({"gdp": 4600.0, "debt": 2950.0, "growth": 0.8, "infl": 2.2, "unemp": 6.3, "ecb_w": 0.27, "debt_base": 0.014, "debt_thr": 80.0, "debt_slope": 0.0007,
                     "elapsed": 11, "parl_term": 48, "threshold": 0.05, "impeach_seats": 316, "constr": 1, "minority_ok": False, "def_target": 3.0})
    # Бундесрат: голоса земель и партии, входящие в правительства земель (на январь 2026)
    L = [(6, [0, 4]), (6, [0, 8]), (4, [0, 1]), (4, [1, 5]), (3, [1, 4, 3]), (3, [1, 4]), (5, [0, 1]), (3, [1, 3]), (6, [1, 4]), (6, [0, 4]), (4, [1, 2, 4]),
         (3, [1]), (4, [0, 1]), (4, [0, 1, 2]), (4, [0, 4]), (4, [0, 5, 1])]
    d["EVENTS_C"] = "[]"; d["NEWS_C"] = "[]"; d["EVENTS_SPECIAL"] = "[]"
    d["PARCH"] = '["cons", "soc", "lib", "left", "green", "popl", "none", "euro", "region", "popr"]'
    d["UPPER"] = gd({"name": "Бундесрат", "kind": "consent", "total": 69, "mode": "all", "blocs": [[v, p] for v, p in L],
        "consent": ["state_structure", "regional_gov", "income_tax_law", "corp_tax_law", "vat_law", "education_law", "security_law", "healthcare", "civil_service", "debt_brake", "eu_policy", "regional_policy", "migration", "citizenship_law", "rent_control", "energy_policy", "schengen"],
        "note": "Бундесрат состоит из представителей правительств земель. Законы, затрагивающие земли, требуют его согласия; остальные он может лишь отклонить, и Бундестаг преодолевает вето.", "fund_need": 0.667})
    return d

def world_text():
    out = []
    # данные регионов всех стран (для карты)
    reg_all = {}
    # ГЕРМАНИЯ из de_calib
    bias, T, pw = DC.calibrate()
    de_regs = []
    PN = ["ХДС/ХСС", "СДПГ", "СвДП", "Левые", "Зелёные", "BSW", "Прочие партии", "Volt", "Свободные избиратели", "АдГ"]
    for i, rid in enumerate(DC.IDS):
        pc = DC.PCREL[rid] / (0.6 + 0.8 * DC.DEV[rid] / 100.0)
        sh = [round(x, 3) for x in T[rid]]
        de_regs.append({"id": "DE-" + rid, "code": rid, "name": DC.NAMES[rid], "short": DC.SHORT[rid], "popm": DC.POP[rid], "pc": round(pc, 3), "dev": float(DC.DEV[rid]), "unrest": float(DC.UNREST[rid]),
                        "auto": float(DC.AUTO[rid]), "infra": float(DC.INFRA[rid]), "edu": float(DC.EDU[rid]), "health": float(DC.HEALTH[rid]), "env": float(DC.ENV[rid]),
                        "loy": round(50.0 + (DC.E[rid][0] - 28.0) * 1.2, 1), "desc": DC.DESC[rid], "sh": sh})
    reg_all["DE"] = de_regs
    pn_all = {"DE": PN}
    pc_all = {"DE": [(0.42, 0.44, 0.52), (0.88, 0.22, 0.25), (0.98, 0.82, 0.15), (0.78, 0.25, 0.62), (0.30, 0.72, 0.35), (0.70, 0.28, 0.38), (0.62, 0.62, 0.68), (0.50, 0.35, 0.85), (0.95, 0.60, 0.18), (0.30, 0.55, 0.95)]}
    seats_all = {"DE": [208, 120, 0, 64, 85, 0, 1, 0, 0, 152]}
    for code, C in CS.items():
        bias, T = calibrate(C)
        regs = []
        for i, r in enumerate(C["regions"]):
            pc = r["pcrel"] / (0.6 + 0.8 * r["dev"] / 100.0)
            regs.append({"id": code + "-" + r["code"], "code": r["code"], "name": r["name"], "short": r["short"], "popm": r["pop"], "pc": round(pc, 3), "dev": float(r["dev"]),
                         "unrest": float(r["unrest"]), "auto": float(r["auto"]), "infra": float(r["infra"]), "edu": float(r["edu"]), "health": float(r["health"]), "env": float(r["env"]),
                         "loy": round(r["loy"], 1), "desc": r["desc"], "sh": [round(x, 3) for x in T[i]]})
        reg_all[code] = regs
        pn_all[code] = [p["short"] for p in C["parties"]]
        pc_all[code] = [p["color"] for p in C["parties"]]
        seats_all[code] = C["seats"]
    de_seats = [208, 120, 0, 64, 85, 0, 1, 0, 0, 152]
    lines = ["const WORLD := {"]
    for c in W.CODES:
        w = {"name": W.NAME[c], "cap": W.CAP[c], "pop": W.POP[c], "gdp": W.GDP[c], "debt": W.DEBT[c], "growth": W.GROWTH[c], "infl": W.INFL[c], "unemp": W.UNEMP[c],
             "def": W.DEFICIT[c], "stab": W.STAB[c], "appr": W.APPR[c], "gov": W.GOV[c], "gov_party": W.GOV_PARTY[c], "pot": W.POTENTIAL[c], "ecb_w": W.ECB_W[c],
             "stance": W.STANCE[c], "desc": W.DESC[c], "leader": W.LEADER[c], "pn": pn_all[c], "seats": seats_all[c] if c != "DE" else de_seats,
             "regions": reg_all[c], "eu": c in W.EU, "euro": c in W.EURO}
        s = gd(w)
        s = s.replace('"pn": [', '"pn": [')
        # цвета
        lines.append("\t%s: %s," % (q(c), s))
    lines.append("}")
    lines.append("const WORLD_PCOL := {" + ", ".join("%s: [%s]" % (q(c), ", ".join(color(x) for x in pc_all[c])) for c in W.CODES) + "}")
    lines.append("const WORLD_CCOL := {" + ", ".join("%s: %s" % (q(c), color(W.CCOL[c])) for c in W.CODES) + "}")
    lines.append("const WORLD_OPEN := " + gd(W.OPEN))
    lines.append("const WORLD_STANCE0 := " + gd(W.STANCE0))
    lines.append("const WORLD_TRADE := " + gd(W.TRADE))
    lines.append("const WORLD_REL := " + gd({a + b: v for pair, v in W.REL.items() for a, b in [tuple(sorted(pair))]}))
    lines.append("const WORLD_LV0 := " + gd({a + b: list(v) for pair, v in W.LV0.items() for a, b in [tuple(sorted(pair))]}))
    return "\n".join(lines)

def main():
    parts = ["# Пакеты данных стран (v13)", "const CDATA := {"]
    for code in ["FR", "NL", "BE", "LU"] + list(W.NEWC.keys()):
        d = emit_country(code)
        parts.append("\t%s: {" % q(code))
        for k, v in d.items():
            parts.append("\t\t%s: %s," % (q(k), v))
        parts.append("\t},")
    d = emit_de()
    parts.append('\t"DE": {')
    for k, v in d.items():
        parts.append("\t\t%s: %s," % (q(k), v))
    parts.append("\t},")
    parts.append("}")
    parts.append(world_text())
    open("countries.gd", "w", encoding="utf-8").write("\n".join(parts) + "\n")
    print("ok", os.path.getsize("countries.gd"))
main()
