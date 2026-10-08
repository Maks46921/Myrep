#!/usr/bin/env python3
"""v38: заготовки 13 новых стран (Балканы и Прибалтика) (структура взята у готовых стран с тем же числом регионов,
торговля — грубая гравитационная оценка). Автор страны заменяет всё настоящими данными (docs/NEWC_SPEC.md)."""
import sys, os, json, math
HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.join(HERE, "..", "..")
sys.path.insert(0, os.path.join(HERE, ".."))
import datio
NEW = {
 "HR": ("NO", ["ZAG", "ZGZ", "SJZ", "SLA", "SMK", "PGI", "SDA", "SPL"], dict(name="Хорватия", cap="Загреб", latlon=(45.81, 15.98), pop=3.86, gdp=90.0, eu=True, euro=True, ccol=(0.62, 0.40, 0.42, 1.0))),
 "RS": ("NO", ["BEO", "SVO", "JVO", "SUM", "ZAP", "KOL", "IST", "JUG"], dict(name="Сербия", cap="Белград", latlon=(44.82, 20.46), pop=6.6, gdp=80.0, eu=False, euro=False, ccol=(0.58, 0.36, 0.36, 1.0))),
 "BA": ("AT", ["SAR", "ZDC", "TUZ", "HER", "USK", "RBL", "RIS", "RJU", "BRC"], dict(name="Босния и Герцеговина", cap="Сараево", latlon=(43.86, 18.41), pop=3.2, gdp=29.0, eu=False, euro=False, ccol=(0.45, 0.52, 0.70, 1.0))),
 "ME": ("DK", ["POD", "NIK", "PRI", "SEV", "IST"], dict(name="Черногория", cap="Подгорица", latlon=(42.44, 19.26), pop=0.62, gdp=7.5, eu=False, euro=True, ccol=(0.66, 0.52, 0.32, 1.0))),
 "MK": ("NO", ["SKO", "POL", "SIS", "IST", "JIS", "VAR", "PEL", "JZA"], dict(name="Северная Македония", cap="Скопье", latlon=(41.99, 21.43), pop=1.8, gdp=16.0, eu=False, euro=False, ccol=(0.72, 0.55, 0.30, 1.0))),
 "AL": ("NO", ["TIR", "DUR", "SHK", "KUK", "ELB", "FIB", "KOR", "VLG"], dict(name="Албания", cap="Тирана", latlon=(41.33, 19.82), pop=2.4, gdp=25.0, eu=False, euro=False, ccol=(0.60, 0.30, 0.32, 1.0))),
 "XK": ("PT", ["PRI", "MIT", "PEJ", "GJA", "PRZ", "FER", "GJI"], dict(name="Косово", cap="Приштина", latlon=(42.66, 21.17), pop=1.6, gdp=11.0, eu=False, euro=True, ccol=(0.40, 0.50, 0.72, 1.0))),
 "BG": ("PT", ["SOF", "YZA", "SZA", "SCE", "SIZ", "YIZ", "YCE"], dict(name="Болгария", cap="София", latlon=(42.70, 23.32), pop=6.4, gdp=105.0, eu=True, euro=True, ccol=(0.42, 0.60, 0.45, 1.0))),
 "RO": ("NO", ["BUC", "NES", "SES", "SMU", "SVO", "VES", "NVS", "CEN"], dict(name="Румыния", cap="Бухарест", latlon=(44.43, 26.10), pop=19.0, gdp=360.0, eu=True, euro=False, ccol=(0.66, 0.60, 0.35, 1.0))),
 "GR": ("FR", ["ATT", "KMA", "AMT", "DMA", "IPE", "THE", "STE", "DEL", "PEL", "ION", "VAI", "NAI", "KRI"], dict(name="Греция", cap="Афины", latlon=(37.98, 23.73), pop=10.4, gdp=240.0, eu=True, euro=True, ccol=(0.40, 0.62, 0.80, 1.0))),
 "EE": ("DK", ["HAR", "KIR", "KES", "LAA", "LOU"], dict(name="Эстония", cap="Таллин", latlon=(59.44, 24.75), pop=1.37, gdp=40.0, eu=True, euro=True, ccol=(0.40, 0.55, 0.75, 1.0))),
 "LV": ("DK", ["RIG", "KUR", "ZEM", "VID", "LAT"], dict(name="Латвия", cap="Рига", latlon=(56.95, 24.11), pop=1.86, gdp=42.0, eu=True, euro=True, ccol=(0.62, 0.38, 0.40, 1.0))),
 "LT": ("NO", ["VIL", "KAU", "KLA", "SIA", "PAN", "ALY", "TEL", "UTE"], dict(name="Литва", cap="Вильнюс", latlon=(54.69, 25.28), pop=2.89, gdp=80.0, eu=True, euro=True, ccol=(0.58, 0.62, 0.38, 1.0))),
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
