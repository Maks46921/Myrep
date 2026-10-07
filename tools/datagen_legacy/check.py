#!/usr/bin/env python3
# Проверка пакета страны: python3 check.py CC   (файлы c_cc.py и l_cc.py в этой же папке)
import sys, importlib, json
from common import *
cc = sys.argv[1].upper(); lo = cc.lower()
C = importlib.import_module("c_" + lo).C
L = importlib.import_module("l_" + lo)
errs = []; warn = []
def E(m): errs.append(m)
def Wn(m): warn.append(m)
ARCHS = {"own", "soc", "lib", "left", "green", "popl", "popr", "cons", "euro", "region", "none"}
PS_KEYS = {"own", "soc", "lib", "left", "green", "popl", "popr", "cons", "euro", "region", "prot", "oth"}
need = ["code", "name", "gen", "adj", "info", "terms", "macro", "policy", "gw", "gb", "markets", "parties", "hemi", "seats", "coalition", "min_start", "join_adj", "regional_p", "lean", "poll", "loy_mean",
        "upper", "ministries", "minister_names", "gov_names", "regions", "world", "terms_extra", "policy_titles"]
for k in need:
    if k not in C: E("нет ключа C[%r]" % k)
if errs: print("\n".join(errs)); sys.exit(1)
if C["code"] != cc: E("code != %s" % cc)
P = C["parties"]
if len(P) != 10: E("партий должно быть 10, их %d" % len(P))
for i, p in enumerate(P):
    for k in ["name", "short", "arch", "color", "leader", "trait", "desc", "min", "law"]:
        if k not in p: E("партия %d: нет %s" % (i, k))
    if p.get("arch") not in ARCHS: E("партия %d: арх %r" % (i, p.get("arch")))
    if p.get("trait") not in TRAITS: E("партия %d: trait %r" % (i, p.get("trait")))
    if any((m < 0 or m > 11) for m in p.get("min", [])): E("партия %d: министерства 0..11" % i)
if P[0]["arch"] != "own": E("партия 0 должна быть arch=own")
if len(C["seats"]) != 10: E("seats длина")
tot = sum(C["seats"]); print("мест всего", tot, "большинство", tot // 2 + 1)
if len(C["hemi"]) != 10 or sorted(C["hemi"]) != list(range(10)): E("hemi должна быть перестановкой 0..9")
if len(C["poll"]) != 10 or abs(sum(C["poll"]) - 100) > 1.5: E("poll сумма %.1f" % sum(C["poll"]))
if len(C["join_adj"]) != 10: E("join_adj длина")
if len(C["min_start"]) != 12: E("min_start длина 12")
if len(C["ministries"]) != 12: E("ministries ровно 12")
for g in GROUPS:
    if g not in C["lean"] or len(C["lean"][g]) != 10: E("lean[%s]" % g)
    if g not in C["gw"] or g not in C["gb"]: E("gw/gb %s" % g)
if abs(sum(C["gw"].values()) - 1) > 0.02: Wn("gw сумма %.2f" % sum(C["gw"].values()))
for k in ["income", "social", "corp", "vat", "pensions", "benefits", "edu", "health", "army", "police", "infra", "eco", "subs", "admin"]:
    if k not in C["policy"]: E("policy %s" % k)
if sum(C["markets"][k]["w"] for k in C["markets"]) < 0.97 or sum(C["markets"][k]["w"] for k in C["markets"]) > 1.03: Wn("markets w сумма %.3f" % sum(C["markets"][k]["w"] for k in C["markets"]))
M = C["macro"]
for k in ["gdp", "debt", "growth", "infl", "unemp", "G_POT", "G_NEU", "I_NEU", "I_TGT", "U_NEU", "RATE0", "ecb_w", "debt_base", "debt_thr", "debt_slope", "def_target", "elapsed", "parl_term", "threshold",
          "impeach_seats", "constr", "minority_ok", "euro", "eu", "fiscal_base", "fiscal_name", "cb_own", "cb_off"]:
    if k not in M: E("macro.%s" % k)
if M.get("impeach_seats", 0) > tot: E("impeach_seats больше числа мест")
R = C["regions"]
if len(R) < 3: E("мало регионов")
rk = ["code", "name", "short", "pop", "pcrel", "dev", "unrest", "auto", "reg", "tr", "sec", "infra", "edu", "health", "env", "mix", "desc", "E"]
for r in R:
    for k in rk:
        if k not in r: E("регион %s: нет %s" % (r.get("code"), k))
    if len(r.get("E", [])) != 10: E("регион %s: E длина 10" % r.get("code"))
    if abs(sum(r.get("sec", [0])) - 1) > 0.03: Wn("регион %s: сумма секторов %.3f" % (r.get("code"), sum(r["sec"])))
    if r.get("dev", 0) > 100 or r.get("unrest", 0) > 100: Wn("регион %s: dev/unrest >100" % r["code"])
GEO = open("../geo/world_geo.gd", encoding="utf-8").read()
for r in R:
    if '"id": "%s-%s"' % (cc, r["code"]) not in GEO: E("нет полигона для региона %s-%s" % (cc, r["code"]))
ids_geo = set(__import__("re").findall(r'"id": "%s-([A-Za-z0-9]+)", "cc"' % cc, GEO))
miss = ids_geo - {r["code"] for r in R}
if miss: E("регионы карты без данных: %s" % sorted(miss))
sp = sum(r["pop"] for r in R); print("население регионов (млн) %.2f; регионов %d" % (sp, len(R)))
W = C["world"]
for k in ["cap", "leader", "pop", "gdp", "debt", "growth", "infl", "unemp", "def", "stab", "appr", "ecb_w", "pot", "gov", "gov_party", "stance", "desc", "likes", "dislikes", "ccol", "open", "stance0", "rel", "trade_x", "trade_m"]:
    if k not in W: E("world.%s" % k)
for k in ["eu", "aus", "trd", "brd", "nuk"]:
    if k not in W.get("stance", {}): E("world.stance.%s" % k)
for k in ["head", "head_g", "head_d", "head_i", "parl", "parl_g", "parl_in", "parl_pl", "reg", "reg_g", "reg_title", "reg_word_pl", "army", "prot", "prot_short", "cap", "gov", "state_unit", "head_role"]:
    if k not in C["terms"]: E("terms.%s" % k)
for k in ["parl_d", "parl_p", "c", "c_g", "adj", "regs", "regs_n", "regs_d", "regs_p", "ctl"]:
    if k not in C["terms_extra"]: E("terms_extra.%s" % k)
U = C["upper"]
for k in ["name", "kind", "total", "blocs", "note", "fund_need"]:
    if k not in U: E("upper.%s" % k)
if U.get("kind") not in ("none", "full", "consent", "override", "veto"): E("upper.kind")
if U.get("blocs") and U["kind"] != "none" or U.get("blocs"):
    for b in U["blocs"]:
        if not (isinstance(b, list) and len(b) == 2 and isinstance(b[1], list)): E("upper bloc формат [голоса, [слоты партий]]: %r" % (b,))
# калибровка
try:
    bias, T = calibrate(C)
    print("калибровка ok; региональные доли ХВ:", [round(t[0] * 100, 1) for t in T][:8])
except Exception as ex:
    E("calibrate: %r" % ex)
# законы
info = dict(L.INFO); info["name"] = C["name"]; info["gen"] = C["gen"]
ts = L.topics(info)
ids = [t["id"] for t in ts]
if len(ids) != len(set(ids)): E("повтор id законов: %s" % [i for i in ids if ids.count(i) > 1])
for need_id in ["fiscal_rule", "eu_policy", "citizenship_law", "rent_control", "schengen", "state_structure", "impeach_rule", "referendum_law", "energy_policy"]:
    if need_id not in ids: Wn("нет закона %s (допустимо, если не применимо)" % need_id)
nv = 0
for t in ts:
    for k in ["id", "cat", "name", "desc", "v"]:
        if k not in t: E("закон %s: нет %s" % (t.get("id"), k))
    if t["cat"] not in (0, 1, 2): E("закон %s: cat 0..2" % t["id"])
    if len(t["v"]) < 2: E("закон %s: меньше 2 вариантов" % t["id"])
    for i, v in enumerate(t["v"]):
        nv += 1
        if "n" not in v or "d" not in v: E("%s/%d нет n,d" % (t["id"], i))
        if i > 0 and "c" not in v and t["id"] != "schengen" and not v.get("set", {}).get("constr") is not None and False: pass
        for kk in v.get("psa", {}):
            if kk not in PS_KEYS: E("%s/%d: ключ ps %r" % (t["id"], i, kk))
        for kk in v.get("s", {}):
            if kk not in GROUPS: E("%s/%d: группа %r" % (t["id"], i, kk))
        if i > 0 and not (v.get("s") or v.get("a") or v.get("set") or v.get("st") or v.get("rg")): Wn("%s/%d: нет эффектов" % (t["id"], i))
print("законов-тем: %d, вариантов: %d" % (len(ts), nv))
P_ = L.params()
for k, v in P_.items():
    if not isinstance(v, dict): E("params[%s]" % k)
for p in P:
    ld = p.get("law")
    if ld:
        tt = [t for t in ts if t["id"] == ld["tid"]]
        if not tt and ld["tid"] not in P_: Wn("закон-условие партии %s: тема %s не найдена среди своих (ок, если базовая)" % (p["short"], ld["tid"]))
# события
ALLOWED_FX = {"slider", "support", "capital", "shock", "debt", "unemp", "infl", "all", "state", "regall", "reg", "reg_transfer", "econ", "dip", "other_rev", "sector", "wc_help", "lock_months"}
STATE = {"edu_lvl", "health_lvl", "security_lvl", "env_lvl", "infra_lvl", "corruption", "equality"}
SLID = {"income", "social", "corp", "vat", "pensions", "benefits", "edu", "health", "army", "police", "infra", "eco", "subs", "admin"}
EV = getattr(L, "EVENTS", []); NW = getattr(L, "NEWS", [])
print("событий: %d, новостей: %d" % (len(EV), len(NW)))
if len(EV) < 14: Wn("мало событий (нужно ≥14)")
if len(NW) < 8: Wn("мало новостей (нужно ≥8)")
def chk_fx(fx, where):
    for k in fx:
        if k not in ALLOWED_FX: E("%s: недопустимый ключ fx %r" % (where, k))
    for g in fx.get("support", {}):
        if g not in GROUPS: E("%s: группа %r" % (where, g))
    for g in fx.get("state", {}):
        if g not in STATE: E("%s: state %r" % (where, g))
    for g in fx.get("slider", {}):
        if g not in SLID: E("%s: slider %r" % (where, g))
    for g in fx.get("dip", {}):
        if g not in ["DE", "FR", "NL", "BE", "LU", "CH", "AT", "PL", "CZ", "DK", "NO", "SE", "IT", "ES", "PT"] or g == cc: E("%s: dip %r" % (where, g))
for i, e in enumerate(EV):
    if "t" not in e or "o" not in e or len(e["o"]) < 2: E("событие %d: t/o (≥2 вариантов)" % i); continue
    if e.get("cond", "") not in ("", "env_low", "infl_high", "debt_high", "unemp_high", "sec_low", "appr_low", "rich", "pre_elec"): E("событие %d: cond" % i)
    if "reg" in e and e["reg"] not in ("any", "unrest30", "sep", "res", "agr", "ind", "srv", "poor", "regional"): E("событие %d: reg" % i)
    for o in e["o"]:
        if "l" not in o or "fx" not in o: E("событие %d: вариант без l/fx" % i)
        else: chk_fx(o["fx"], "событие %d" % i)
for i, n in enumerate(NW):
    if "text" not in n or "fx" not in n: E("новость %d" % i)
    else: chk_fx(n["fx"], "новость %d" % i)
print("\nПРЕДУПРЕЖДЕНИЯ:" if warn else "предупреждений нет"); print("\n".join(" - " + w for w in warn))
if errs:
    print("\nОШИБКИ:"); print("\n".join(" ! " + e for e in errs)); sys.exit(1)
print("\nOK")
