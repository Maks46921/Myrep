#!/usr/bin/env python3
"""Встраивание новых стран в проект (v30: GB, IE; v33: SI, SK, HU, FI).  Использование:  python3 tools/newc/build.py [--root КОРЕНЬ] si sk hu fi
Для каждой страны нужен модуль tools/newc/data_<cc>.py (см. docs/NEWC_SPEC.md). Сборка идемпотентна."""
import sys, os, json, importlib, math, argparse
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, ".."))
import datio, gdconst
ap = argparse.ArgumentParser()
ap.add_argument("--root", default=os.path.join(HERE, "..", ".."))
ap.add_argument("codes", nargs="*")
A = ap.parse_args()
ROOT = os.path.abspath(A.root)
DC = os.path.join(ROOT, "scripts", "data", "data_core.gd")
codes = [c.upper() for c in A.codes]
if not codes: raise SystemExit("укажите коды стран, например: si sk hu fi")
mods = {}
for cc in codes:
    sys.path.insert(0, HERE)
    mods[cc] = importlib.import_module("data_%s" % cc.lower())
NEWALL = list(codes)
ALL15 = [c for c in gdconst.get(DC, "COUNTRY_CODES") if c not in NEWALL]   # уже встроенные страны
ALLC = ALL15 + NEWALL

def rnd5(x):
    return round(x * 2.0) / 2.0

# ---------- 1. мировая запись ----------
def world_entry(cc):
    m = mods[cc]; W = m.WORLD; D = m.D
    e = {k: W[k] for k in ["name", "cap", "pop", "gdp", "debt", "growth", "infl", "unemp", "def", "stab", "appr", "gov", "gov_party", "pot", "ecb_w", "stance", "desc", "leader"]}
    e["pn"] = list(W["pn"]); e["seats"] = list(D["DE_START_SEATS"])
    regs = []
    for i, r in enumerate(D["REGIONS"]):
        E = list(m.E[i]); s = sum(E) or 1.0
        regs.append({"id": "%s-%s" % (cc, r["code"]), "code": r["code"], "name": r["name"], "short": r["short"], "popm": r["popm"], "pc": r["pc"], "dev": r["dev"],
                     "unrest": r["unrest"], "auto": r["auto"], "infra": r["infra"], "edu": r["edu"], "health": r["health"], "env": r["env"], "loy": r["loy"], "desc": r["desc"],
                     "sh": [round(x / s, 3) for x in E]})
    e["regions"] = regs; e["eu"] = bool(W["eu"]); e["euro"] = bool(W["euro"])
    return e

def project(lat, lon):
    return [round(25.7085 * lon + 154.29, 1), round(-38.6135 * lat + 2192.0, 1)]

# ---------- 2. сборка ----------
def main():
    # --- WORLD ---
    wp = os.path.join(ROOT, "data", "world.dat")
    W = datio.loadn(wp)
    for cc in NEWALL:
        W[cc] = world_entry(cc)
    datio.dump(wp, W)
    # --- таблицы в data_core.gd ---
    g = lambda n: gdconst.get(DC, n)
    cc_list = g("COUNTRY_CODES")
    for cc in NEWALL:
        if cc not in cc_list: cc_list.append(cc)
    gdconst.put(DC, "COUNTRY_CODES", cc_list)
    mon = g("RAD_MONARCHIES")
    for cc in NEWALL:
        if getattr(mods[cc], "MONARCHY", False) and cc not in mon: mon.append(cc)
    gdconst.put(DC, "RAD_MONARCHIES", mon)
    cur = g("RAD_CUR")
    for cc in NEWALL: cur[cc] = mods[cc].RAD_CUR
    gdconst.put(DC, "RAD_CUR", cur, True)
    el = g("ELEC_DATA")
    for cc in NEWALL: el[cc] = mods[cc].ELEC
    gdconst.put(DC, "ELEC_DATA", el, True)
    rev = g("REG_EVENTS_CC")
    for cc in NEWALL: rev[cc] = mods[cc].REG_EVENTS
    gdconst.put(DC, "REG_EVENTS_CC", rev, True)
    pcol = g("WORLD_PCOL"); ccol = g("WORLD_CCOL"); opn = g("WORLD_OPEN"); st0 = g("WORLD_STANCE0"); caps = g("WORLD_CAPS")
    for cc in NEWALL:
        m = mods[cc]
        pcol[cc] = m.D["PARTY_COLORS"]
        ccol[cc] = {"__c": list(m.WORLD["ccol"]) if len(m.WORLD["ccol"]) == 4 else list(m.WORLD["ccol"])}
        opn[cc] = m.WORLD["open"]; st0[cc] = m.WORLD["stance0"]
        x, y = project(*m.WORLD["latlon"]); caps[cc] = {"__v": [x, y]}
    gdconst.put(DC, "WORLD_PCOL", pcol); gdconst.put(DC, "WORLD_CCOL", ccol); gdconst.put(DC, "WORLD_OPEN", opn); gdconst.put(DC, "WORLD_STANCE0", st0); gdconst.put(DC, "WORLD_CAPS", caps)
    # --- торговля, отношения, уровни ---
    tr = g("WORLD_TRADE"); rel = g("WORLD_REL"); lv0 = g("WORLD_LV0")
    for cc in NEWALL:
        w = mods[cc].WORLD
        tr.setdefault(cc, {})
        for o in ALLC:
            if o == cc: continue
            x = w["trade_x"].get(o)         # экспорт cc -> o
            m_ = w["trade_m"].get(o)        # импорт cc из o (= экспорт o -> cc)
            if x is None and o in mods: x = mods[o].WORLD["trade_m"].get(cc)
            if m_ is None and o in mods: m_ = mods[o].WORLD["trade_x"].get(cc)
            if x is None or m_ is None:
                raise SystemExit("нет торговли %s<->%s (trade_x/trade_m)" % (cc, o))
            tr[cc][o] = round(float(x), 1)
            tr.setdefault(o, {})[cc] = round(float(m_), 1)
        for o in ALLC:
            if o == cc: continue
            k = "".join(sorted([cc, o]))
            r = w["rel"].get(o)
            if r is None and o in mods: r = mods[o].WORLD["rel"].get(cc)
            if r is None: raise SystemExit("нет отношений %s-%s (rel)" % (cc, o))
            rel[k] = float(r)
            if k not in lv0:
                eu_o = (W[o]["eu"] if o in W else True)
                lv0[k] = [2, 1, 1] if (W[cc]["eu"] and eu_o) else [2, 0, 1]
    gdconst.put(DC, "WORLD_TRADE", tr); gdconst.put(DC, "WORLD_REL", rel); gdconst.put(DC, "WORLD_LV0", lv0)
    # убрать фоновые контуры GBR, IRL (теперь играбельные)
    ctx = g("WORLD_CTX")
    drop = {"GBR": "GB", "IRL": "IE", "SVN": "SI", "SVK": "SK", "HUN": "HU", "FIN": "FI"}
    ctx = [c for c in ctx if not (c["id"] in drop and drop[c["id"]] in NEWALL)]
    gdconst.put(DC, "WORLD_CTX", ctx, True)
    # --- дипломатия: данные соседей ---
    W = datio.loadn(wp)
    def ecb_total_w(x):
        return sum(tr[x].get(o, 0.0) for o in ALLC if o != x)
    def dip_c(x, c):
        wc = W[c]; t = tr[x][c]
        k = "".join(sorted([x, c]))
        tot = ecb_total_w(x) + 15.0
        return {"name": wc["name"], "cap": wc["cap"], "pop": wc["pop"], "gdp": wc["gdp"], "trade": t, "rel0": rel[k],
                "w": round(t / tot, 3), "lv0": {"trade": lv0[k][0], "sec": lv0[k][1], "energy": lv0[k][2]},
                "leader": wc["leader"], "desc": wc["desc"],
                "likes": _likes_txt(c)[0], "dislikes": _likes_txt(c)[1]}
    _cache = {}
    def _likes_txt(c):
        if c in mods: return mods[c].WORLD["likes"], mods[c].WORLD["dislikes"]
        for x in ["NO", "FR", "LU", "PT", "SE"]:
            dd = _cache.get(x)
            if dd is None:
                dd = _cache[x] = datio.loadn(os.path.join(ROOT, "data", "countries", "%s.dat" % x))["DIP_C"]
            if c in dd:
                return dd[c]["likes"], dd[c]["dislikes"]
        raise SystemExit("нет likes для " + c)
    def likes_for(x, c, tags):
        out = {}
        st = W[c]["stance"]
        for tid, vs in tags.items():
            o = {}
            for k, (dim, sg) in vs.items():
                v = rnd5(st[dim] * sg * 5.0)
                if v != 0.0: o[k] = v
            if o: out[tid] = o
        return out
    # новые страны: полный DIP
    for cc in NEWALL:
        D = dict(mods[cc].D)
        order = [o for o in ALLC if o != cc]
        D["DIP_ORDER"] = order
        D["DIP_C"] = {o: dip_c(cc, o) for o in order}
        D["DIP_LIKES"] = {o: likes_for(cc, o, D["LAW_TAGS"]) for o in order}
        datio.dump(os.path.join(ROOT, "data", "countries", "%s.dat" % cc), D)
    # существующие страны (кроме DE, у которой свой базовый список соседей): добавить новых
    for x in ALL15:
        if x == "DE": continue
        p = os.path.join(ROOT, "data", "countries", "%s.dat" % x)
        d = datio.loadn(p)
        for cc in NEWALL:
            if cc not in d["DIP_ORDER"]: d["DIP_ORDER"].append(cc)
            d["DIP_C"][cc] = dip_c(x, cc)
            d["DIP_LIKES"][cc] = likes_for(x, cc, d["LAW_TAGS"])
        datio.dump(p, d)
    print("готово:", ", ".join(NEWALL))
main()
