# Мир v14: 5 старых стран из world13 + новые страны из пакетов c_<cc>.py (C["world"]); торговля — гравитационная модель с уточнениями
import os, math, importlib, sys
from world13 import *
import world13 as _W
NEW_ORDER = ["CH", "AT", "PL", "CZ", "DK", "NO", "SE", "IT", "ES", "PT"]
NEWC = {}
for _cc in NEW_ORDER:
    if os.path.exists(os.path.join(os.path.dirname(os.path.abspath(__file__)), "c_%s.py" % _cc.lower())):
        NEWC[_cc] = importlib.import_module("c_%s" % _cc.lower()).C
CODES = list(_W.CODES) + [c for c in NEW_ORDER if c in NEWC]
EU = {"DE", "FR", "NL", "BE", "LU", "AT", "PL", "CZ", "DK", "SE", "IT", "ES", "PT"}
EURO = {"DE", "FR", "NL", "BE", "LU", "AT", "IT", "ES", "PT"}
LL = {"DE": (52.52, 13.40), "FR": (48.86, 2.35), "NL": (52.37, 4.90), "BE": (50.85, 4.35), "LU": (49.61, 6.13), "CH": (46.95, 7.45), "AT": (48.21, 16.37), "PL": (52.23, 21.01),
      "CZ": (50.09, 14.42), "DK": (55.68, 12.57), "NO": (59.91, 10.75), "SE": (59.33, 18.07), "IT": (41.90, 12.50), "ES": (40.42, -3.70), "PT": (38.72, -9.14)}
BORDER = {frozenset(p) for p in [("DE", "FR"), ("DE", "NL"), ("DE", "BE"), ("DE", "LU"), ("FR", "BE"), ("FR", "LU"), ("NL", "BE"), ("BE", "LU"), ("DE", "CH"), ("DE", "AT"), ("DE", "PL"),
          ("DE", "CZ"), ("DE", "DK"), ("FR", "CH"), ("FR", "IT"), ("FR", "ES"), ("CH", "AT"), ("CH", "IT"), ("AT", "CZ"), ("AT", "IT"), ("PL", "CZ"), ("NO", "SE"), ("DK", "SE"), ("ES", "PT")]}
# недостающие поля стран берутся из C["world"] пакета
NAME = dict(_W.NAME); CAP = dict(_W.CAP); LEADER = dict(_W.LEADER); POP = dict(_W.POP); GDP = dict(_W.GDP); DEBT = dict(_W.DEBT); GROWTH = dict(_W.GROWTH)
INFL = dict(_W.INFL); UNEMP = dict(_W.UNEMP); DEFICIT = dict(_W.DEFICIT); STAB = dict(_W.STAB); APPR = dict(_W.APPR); ECB_W = dict(_W.ECB_W); POTENTIAL = dict(_W.POTENTIAL)
GOV = dict(_W.GOV); GOV_PARTY = dict(_W.GOV_PARTY); STANCE = dict(_W.STANCE); DESC = dict(_W.DESC); LIKES = dict(_W.LIKES); CCOL = dict(_W.CCOL)
OPEN = {"DE": 0.35, "FR": 0.27, "NL": 0.70, "BE": 0.75, "LU": 0.85}
STANCE0 = {"DE": 0.2, "FR": 0.1, "NL": 0.15, "BE": 0.3, "LU": 0.1}
for cc, C in NEWC.items():
    w = C["world"]
    NAME[cc] = C["name"]; CAP[cc] = w["cap"]; LEADER[cc] = w["leader"]; POP[cc] = w["pop"]; GDP[cc] = w["gdp"]; DEBT[cc] = w["debt"]; GROWTH[cc] = w["growth"]
    INFL[cc] = w["infl"]; UNEMP[cc] = w["unemp"]; DEFICIT[cc] = w["def"]; STAB[cc] = w["stab"]; APPR[cc] = w["appr"]; ECB_W[cc] = w["ecb_w"]; POTENTIAL[cc] = w["pot"]
    GOV[cc] = w["gov"]; GOV_PARTY[cc] = w["gov_party"]; STANCE[cc] = w["stance"]; DESC[cc] = w["desc"]; LIKES[cc] = (w["likes"], w["dislikes"]); CCOL[cc] = tuple(w["ccol"])
    OPEN[cc] = w.get("open", 0.4); STANCE0[cc] = w.get("stance0", 0.1)
def _dist(a, b):
    la1, lo1 = map(math.radians, LL[a]); la2, lo2 = map(math.radians, LL[b])
    h = math.sin((la2 - la1) / 2) ** 2 + math.cos(la1) * math.cos(la2) * math.sin((lo2 - lo1) / 2) ** 2
    return 6371.0 * 2 * math.asin(math.sqrt(h))
def _grav(a, b):
    k = 0.0105
    t = k * (GDP[a] * GDP[b]) ** 0.75 / max(_dist(a, b), 250.0) ** 0.8 * 40.0
    if frozenset((a, b)) in BORDER: t *= 1.35
    if a in EU and b in EU: t *= 1.15
    if (a in EU) != (b in EU): t *= 0.85
    return t
TRADE = {a: {} for a in CODES}
for a in CODES:
    for b in CODES:
        if a == b: continue
        if a in _W.TRADE and b in _W.TRADE[a]:
            TRADE[a][b] = float(_W.TRADE[a][b]); continue
        wa = NEWC.get(a, {}).get("world", {}); wb = NEWC.get(b, {}).get("world", {})
        v = wa.get("trade_x", {}).get(b)
        if v is None: v = wb.get("trade_m", {}).get(a)
        if v is None: v = _grav(a, b)
        TRADE[a][b] = round(float(v), 1)
REL = dict(_W.REL); LV0 = dict(_W.LV0)
for i, a in enumerate(CODES):
    for b in CODES[i + 1:]:
        pr = frozenset((a, b))
        if pr in REL: continue
        vals = []
        for x, y in ((a, b), (b, a)):
            r = NEWC.get(x, {}).get("world", {}).get("rel", {}).get(y)
            if r is not None: vals.append(float(r))
        if vals: REL[pr] = round(sum(vals) / len(vals), 0)
        else:
            r = 60.0 + (6 if (a in EU and b in EU) else 0) + (4 if pr in BORDER else 0) + (4 if (a in EURO and b in EURO) else 0)
            REL[pr] = r
        if pr not in LV0:
            both_eu = a in EU and b in EU
            LV0[pr] = (2, 1, 1) if both_eu else (2, 0, 1)
