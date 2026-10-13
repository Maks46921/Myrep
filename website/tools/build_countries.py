#!/usr/bin/env python3
"""Собирает website/countries.js (данные, контуры стран) и website/img/flags/*.webp.

1) godot --headless --path . --script website/tools/export_countries.gd -- out=/tmp/sym
2) python3 website/tools/build_countries.py /tmp/sym
"""
import json, re, math, sys
from collections import defaultdict
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(sys.argv[1] if len(sys.argv) > 1 else "/tmp/sym")
ORDER = ["DE","FR","NL","BE","LU","AT","CH","CZ","DK","ES","IT","NO","PL","PT","SE","GB","IE","SI","SK","HU","FI","HR","RS","BA","ME","MK","AL","XK","BG","RO","GR","EE","LV","LT","MD","BY","UA","RU"]
HYBRID = ("RU", "BY")  # гибридные режимы на старте
HEAD = {"direct": "избирается народом", "indirect": "избирается не напрямую", "monarch": "наследственный монарх", "council": "коллегиальный орган"}


def simp(pts, tol):
    out = [pts[0]]
    for p in pts[1:-1]:
        if math.dist(p, out[-1]) >= tol:
            out.append(p)
    return out


def path(parts, tol, ox=0, oy=0, k=1.0, minarea=0, clip=0):
    s = []
    for part in parts:
        pts = list(zip(part[0::2], part[1::2]))
        if len(pts) < 3:
            continue
        xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
        if (max(xs) - min(xs)) * (max(ys) - min(ys)) < minarea:
            continue
        pts = simp(pts, tol)
        if clip:
            pts = [(min(x, clip), y) for x, y in pts]
            if min(p[0] for p in pts) >= clip:
                continue
            c2 = []
            for i, p in enumerate(pts):
                if p[0] == clip and c2 and c2[-1][0] == clip and i + 1 < len(pts) and pts[i + 1][0] == clip:
                    continue
                c2.append(p)
            pts = c2
        pp = []
        for x, y in pts:
            q = (round((x - ox) * k), round((y - oy) * k))
            if not pp or pp[-1] != q:
                pp.append(q)
        if len(pp) >= 3:
            s.append("M" + " ".join("%d %d" % p for p in pp) + "Z")
    return "".join(s)


def geo():
    units = json.loads((ROOT / "data/world_units.dat").read_text(encoding="utf-8"))
    by = defaultdict(list)
    for u in units:
        by[u["cc"]].append(u)
    eu, shape = {}, {}
    for cc in ORDER:
        us = by[cc]
        parts = [p for u in us for p in u["parts"]]
        eu[cc] = path(parts, {"RU": 5.0, "NO": 2.6}.get(cc, 1.6), minarea=0 if cc == "LU" else 6, clip=1320 if cc == "RU" else 0)
        xs = [x for p in parts for x in p[0::2]]; ys = [y for p in parts for y in p[1::2]]
        x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
        span = max(x1 - x0, y1 - y0); k = 400.0 / span
        tol = span / (160 if cc in ("RU", "NO") else 230)
        regs = [path(u["parts"], tol, x0, y0, k, minarea=(span / 120) ** 2) for u in us]
        shape[cc] = {"w": round((x1 - x0) * k), "h": round((y1 - y0) * k), "r": [r for r in regs if r]}
    return {"eu": eu, "shape": shape}


def base_colors():
    # базовые цвета стран на карте игры (WORLD_CCOL в data_core.gd)
    src = (ROOT / "scripts/data/data_core.gd").read_text(encoding="utf-8")
    line = next(l for l in src.splitlines() if l.startswith("const WORLD_CCOL"))
    out = {}
    for cc, r, g, b in re.findall(r'"(\w+)": Color\(([\d.]+), ([\d.]+), ([\d.]+)', line):
        out[cc] = "#%02x%02x%02x" % tuple(round(float(x) * 255) for x in (r, g, b))
    return out


def main():
    d = json.loads((OUT / "countries.json").read_text(encoding="utf-8"))
    (ROOT / "website/img/flags").mkdir(parents=True, exist_ok=True)
    out = []
    col = base_colors()
    for cc in ORDER:
        v = d[cc]; inf = v["info"]
        total = sum(v["seats"])
        out.append({
            "cc": cc, "col": col.get(cc, "#8c8094"), "n": v["name"], "cap": v["cap"], "pop": inf.get("pop", v["pop"]), "gdp": inf.get("gdp", v["gdp"]),
            "debt": inf.get("debt_pct"), "dif": inf.get("difficulty", 3), "blurb": inf.get("blurb", ""), "desc": v["desc"],
            "you": v["leader"], "gov": v["gov"], "gp": v["gov_party"],
            "head": "Монарх" if v["head"] == "monarch" else (v["head_title"] or "Федеральный совет"), "headk": HEAD.get(v["head"], ""),
            "parl": v["parl"], "seats": total, "maj": total // 2 + 1, "up": v["upper"], "upn": v["upper_total"],
            "sys": v["sys"], "term": v["term"], "reg": v["regions"], "gr": v["growth"], "inf": v["infl"], "un": v["unemp"],
            "eu": v["eu"], "euro": v["euro"], "orgs": v["orgs"], "tr": v["traits"], "rel": [r[:3] for r in v["rel"]],
            "p": [{"n": n, "s": s, "c": c} for n, s, c in zip(v["pn"], v["seats"], v["pcol"]) if s > 0],
            "regime": "Гибридный режим" if cc in HYBRID else "",
        })
        Image.open(OUT / "flags" / (cc + ".png")).convert("RGB").save(ROOT / "website/img/flags" / (cc + ".webp"), "WEBP", quality=88)
    js = ("/* Данные стран из игры Symphony. Пересобрать: website/tools/build_countries.py */\n"
          "window.SYM_COUNTRIES=" + json.dumps(out, ensure_ascii=False, separators=(",", ":")) + ";\n"
          "window.SYM_GEO=" + json.dumps(geo(), ensure_ascii=False, separators=(",", ":")) + ";\n")
    (ROOT / "website/countries.js").write_text(js, encoding="utf-8")
    print("Стран:", len(out))


if __name__ == "__main__":
    main()
