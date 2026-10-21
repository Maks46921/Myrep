# 0.60: особые законы стран — реальные законы, которых ещё нет в данных страны.
# Партийные реакции (ps) считаются по архетипам партий страны (ARCHS) и осям закона.
import sys, os, json
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import datio
from core import derive_s, V, gd, topic_gd
from t_elec import *

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DE_ARCHS = ["own", "soc", "lib", "left", "green", "popl", "oth", "euro", "region", "prot"]
VEC = {
    "soc": {"e": -0.9, "l": 0.4, "g": 0.3, "n": -0.3}, "lib": {"e": 1.0, "l": 0.8, "g": -0.1, "n": -0.4},
    "left": {"e": -1.2, "l": 0.3, "g": 0.4, "n": -0.4}, "green": {"e": -0.3, "l": 0.5, "g": 1.2, "n": -0.3},
    "popl": {"e": -0.5, "l": -0.3, "g": -0.2, "n": 0.8}, "euro": {"e": 0.2, "l": 0.6, "g": 0.4, "n": -0.8},
    "region": {"n": 0.3}, "prot": {"e": -0.1, "l": -0.1, "n": 0.4},
    "popr": {"e": -0.1, "l": -0.5, "g": -0.2, "n": 0.9}, "cons": {"e": 0.6, "l": -0.4, "g": -0.2, "n": 0.7},
}
_ARCHS = {}


def archs(cc):
    if cc not in _ARCHS:
        if cc == "DE":
            _ARCHS[cc] = DE_ARCHS
        else:
            _ARCHS[cc] = datio.load(os.path.join(ROOT, "data/countries/%s.dat" % cc))["ARCHS"]
    return _ARCHS[cc]


def ps_for(cc, ax, mult=1.0, over=None):
    out = {}
    for i, a in enumerate(archs(cc)):
        if a not in VEC:
            continue
        v = sum(VEC[a].get(k, 0.0) * ax.get(k, 0.0) for k in ("e", "l", "g", "n")) * mult
        v = round(max(-9.0, min(9.0, v)) * 2) / 2
        if over and a in over:
            v = float(over[a])
        if abs(v) >= 0.5:
            out[i] = v
    return out


CTOPICS = {}   # cc -> [topic]
NOTES = []     # сомнительные места (для отчёта)


def CT(cc, id, cat, name, desc, variants, fund=False, start=None, doubt=None):
    """variants: список V-описаний (кортежей) — (n, d, c, ax, extra-словарь с ключами s,a,x,st,rg,pa)"""
    vs = []
    for tup in variants:
        n, d = tup[0], tup[1]
        if len(tup) == 2:
            vs.append({"n": n, "d": d})
            continue
        c, ax = tup[2], tup[3]
        ex = tup[4] if len(tup) > 4 else {}
        v = V(n, d, c, ax, s=ex.get("s"), a=ex.get("a"), x=ex.get("x"), st=ex.get("st"), rg=ex.get("rg"), k=ex.get("k", 1.0))
        v["ps"] = ps_for(cc, ax, ex.get("k", 1.0), ex.get("pa"))
        if not v["ps"]:
            v.pop("ps")
        vs.append(v)
    t = {"id": id, "cat": cat, "name": name, "desc": desc, "v": vs}
    if fund:
        t["fund"] = True
    CTOPICS.setdefault(cc, []).append(t)
    if doubt:
        NOTES.append((cc, id, doubt))
