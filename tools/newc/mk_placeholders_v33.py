#!/usr/bin/env python3
"""v33: заготовки data_si.py / data_sk.py / data_hu.py / data_fi.py (структура взята у готовых стран с тем же числом регионов,
торговля — грубая гравитационная оценка). Автор страны заменяет всё настоящими данными (docs/NEWC_SPEC.md)."""
import sys, os, json, math
HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.join(HERE, "..", "..")
sys.path.insert(0, os.path.join(HERE, ".."))
import datio
NEW = {
 "SI": ("PT", ["OSR", "POD", "POM", "SAV", "GOR", "PRI", "JVS"], dict(name="Словения", cap="Любляна", latlon=(46.05, 14.51), pop=2.1, gdp=70.0, eu=True, euro=True, ccol=(0.35, 0.55, 0.75, 1.0))),
 "SK": ("NO", ["BA", "TT", "TN", "NR", "ZA", "BB", "PO", "KE"], dict(name="Словакия", cap="Братислава", latlon=(48.15, 17.11), pop=5.4, gdp=135.0, eu=True, euro=True, ccol=(0.55, 0.42, 0.68, 1.0))),
 "HU": ("NO", ["BUD", "PES", "KDT", "NYD", "DDT", "EMO", "EAL", "DAL"], dict(name="Венгрия", cap="Будапешт", latlon=(47.50, 19.04), pop=9.6, gdp=215.0, eu=True, euro=False, ccol=(0.62, 0.5, 0.36, 1.0))),
 "FI": ("AT", ["UUS", "VSS", "HAM", "KAA", "POH", "ISU", "PPO", "LAP", "AHV"], dict(name="Финляндия", cap="Хельсинки", latlon=(60.17, 24.94), pop=5.6, gdp=285.0, eu=True, euro=True, ccol=(0.42, 0.6, 0.78, 1.0))),
}
def main():
    W = datio.loadn(os.path.join(ROOT, "data", "world.dat"))
    caps = {}
    for cc, w in W.items():
        caps[cc] = (w["gdp"], None)
    allc = list(W.keys()) + [c for c in NEW if c not in W]
    for cc, (tmpl, codes, base) in NEW.items():
        d = datio.loadn(os.path.join(ROOT, "data", "countries", "%s.dat" % tmpl))
        TW = W[tmpl]
        for k in ("DIP_ORDER", "DIP_C", "DIP_LIKES"): d.pop(k)
        E = []
        assert len(d["REGIONS"]) == len(codes), (cc, tmpl)
        for i, r in enumerate(d["REGIONS"]):
            r["code"] = codes[i]
            E.append(list(TW["regions"][i]["sh"]))
        os.makedirs(os.path.join(HERE, "ph"), exist_ok=True)
        datio.dump(os.path.join(HERE, "ph", "%s_D.dat" % cc.lower()), d)
        json.dump(E, open(os.path.join(HERE, "ph", "%s_E.json" % cc.lower()), "w"))
        g = base["gdp"]
        tx = {}; tm = {}; rel = {}
        for o in allc:
            if o == cc: continue
            go = W[o]["gdp"] if o in W else NEW[o][2]["gdp"]
            v = round(0.08 * math.sqrt(g * go) * 0.3, 1)
            tx[o] = v; tm[o] = v; rel[o] = 70
        world = {"name": base["name"], "cap": base["cap"], "latlon": base["latlon"], "pop": base["pop"], "gdp": g, "debt": g * 0.6, "growth": 1.5, "infl": 2.5,
                 "unemp": 5.5, "def": 3.0, "stab": 60, "appr": 35, "gov": "заготовка", "gov_party": "заготовка", "pot": 1.5, "ecb_w": 0.01 if base["euro"] else 0.0,
                 "stance": {"eu": 0.5, "aus": 0.2, "trd": 0.6, "brd": 0.0, "nuk": 0.0}, "desc": "Заготовка", "leader": "Премьер-министр",
                 "pn": ["П1", "П2", "П3", "П4", "П5", "П6", "Др.", "П8", "П9", "П10"], "eu": base["eu"], "euro": base["euro"], "likes": "заготовка", "dislikes": "заготовка",
                 "open": 0.7, "stance0": 0.1, "ccol": base["ccol"], "rel": rel, "trade_x": tx, "trade_m": tm}
        src = '''# ЗАГОТОВКА %s — заменить настоящими данными (docs/NEWC_SPEC.md)
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, ".."))
import datio
D = datio.loadn(os.path.join(HERE, "ph", "%s_D.dat"))
E = json.load(open(os.path.join(HERE, "ph", "%s_E.json")))
WORLD = %s
REG_EVENTS = []
ELEC = {"sys": "Заготовка", "turn": 0.65, "note": "", "head": "monarch"}
RAD_CUR = "Заготовка"
MONARCHY = False
''' % (cc, cc.lower(), cc.lower(), repr(world))
        open(os.path.join(HERE, "data_%s.py" % cc.lower()), "w", encoding="utf-8").write(src)
    print("заготовки созданы")
main()
