#!/usr/bin/env python3
"""0.66: добавляет в data/world_units.dat Лихтенштейн (LI), Мальту (MT), Андорру (AD), Сан-Марино (SM), Монако (MC), Приднестровье (PM, 5 районов) и Кипр (CY, 5 округов,
подконтрольных Республике) из Natural Earth (/tmp/claude-0/geo/ne_admin1.geojson). Северный Кипр (ТРСК) — фоновая контекстная страна.
Масштаб реальный: Монако — доля квадратной единицы карты. Старые грубые контуры соседей (FR, ES, IT и др.) режутся по новым странам.
Повторный запуск строит от сохранённых исходников tools/units_before_v66.dat и tools/ctx_before_v66.dat."""
import sys, json, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import datio
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "newc"))
import gdconst
from shapely.geometry import shape, Polygon, MultiPolygon, box, Point
from shapely.ops import unary_union
from shapely.validation import make_valid
import shapely
import shapely.affinity
from gen_units_cee import poly_of, polys_only, ring_pts, set_parts

DC = "scripts/data/data_core.gd"
UNITS0 = "tools/units_before_v66.dat"
CTX0 = "tools/ctx_before_v66.dat"
SRC = "/tmp/claude-0/geo/ne_admin1.geojson"
SRC0 = "/tmp/claude-0/geo/ne_admin0_10m.geojson"


def proj(g):
    return shapely.affinity.affine_transform(make_valid(g), [25.7085, 0, 0, -38.6135, 154.29, 2192.0])


ORDER = {"LI": ["LIE"], "MT": ["GOZ", "NOR", "POR", "SUD"], "AD": ["ORD", "ENC", "CEN"], "SM": ["SMR"], "MC": ["MCO"],
         "PM": ["KAM", "RYB", "DUB", "GRI", "TSB"], "CY": ["NIC", "LIM", "LAR", "PAF", "FAM"]}
if os.environ.get("V66_ONLY"):       # отладка: строить на карте только перечисленные страны
    ORDER = {k: v for k, v in ORDER.items() if k in os.environ["V66_ONLY"].split(",")}
NEWCC = list(ORDER)
AD = {"Ordino": "ORD", "La Massana": "ORD", "Canillo": "ENC", "Encamp": "ENC", "Andorra la Vella": "CEN",
      "Escaldes-Engordany": "CEN", "Sant Julià de Lòria": "CEN"}
CY = {"Nicosia": "NIC", "Limassol": "LIM", "Larnaca": "LAR", "Paphos": "PAF", "Famagusta": "FAM"}
PMR_NE = {"Camenca": "KAM", "Stîngă Nistrului": "DUB", "Grigoriopol": "GRI", "Bender": "TSB", "Transnistria": "TSB"}
MIN_AREA = {"MC": 0.05, "SM": 0.3, "LI": 0.3}
SEA = [("MT-GOZ", "MT-NOR")]


def malta_code(f):
    c = shape(f["geometry"]).centroid
    if c.y > 36.0:
        return "GOZ"
    if c.y >= 35.905:
        return "NOR"
    if c.x >= 14.47:
        return "POR"
    return "SUD"


def classify(f):
    p = f["properties"]
    a3 = p.get("adm0_a3")
    nm = p.get("name")
    if a3 == "LIE":
        return ("LI", "LIE")
    if a3 == "MCO":
        return ("MC", "MCO")
    if a3 == "SMR":
        return ("SM", "SMR")
    if a3 == "AND":
        return ("AD", AD[nm])
    if a3 == "MLT":
        return ("MT", malta_code(f))
    if a3 == "CYP":
        return ("CY", CY[nm])
    return None


def main():
    g = json.load(open(SRC))
    groups = {}
    pm_ne = {}
    cyn = []
    for f in g["features"]:
        p = f["properties"]
        a3 = p.get("adm0_a3")
        if a3 == "MDA":
            nm = p.get("name")
            sh = make_valid(shape(f["geometry"]))
            if nm == "Rezina" and sh.centroid.x > 29.0:
                pm_ne.setdefault("RYB", []).append(sh)
            elif nm in PMR_NE:
                pm_ne.setdefault(PMR_NE[nm], []).append(sh)
            continue
        if a3 == "CYN":
            cyn.append(make_valid(shape(f["geometry"])))
            continue
        k = classify(f)
        if k is None:
            continue
        groups.setdefault(k, []).append(make_valid(shape(f["geometry"])))
    g0 = json.load(open(SRC0))
    for f in g0["features"]:
        if f["properties"].get("ADM0_A3") == "CNM":      # буферная зона ООН — к Никосии
            groups.setdefault(("CY", "NIC"), []).append(make_valid(shape(f["geometry"])))
    if not os.path.exists(UNITS0):
        datio.dump(UNITS0, datio.load("data/world_units.dat"))
    units = datio.load(UNITS0)
    if any(u["cc"] in NEWCC for u in units):
        raise SystemExit("в %s уже есть новые страны" % UNITS0)
    if os.path.exists(CTX0):
        ctx = datio.load(CTX0)
    else:
        ctx = gdconst.get(DC, "WORLD_CTX")
        datio.dump(CTX0, ctx)
    # старое Приднестровье (одна единица) заменяется пятью районами
    pmr_old = [u for u in units if u["cc"] == "PMR"]
    drop = {i for i, u in enumerate(units) if u["cc"] == "PMR"} if "PM" in ORDER else set()
    remap, n = {}, 0
    for i in range(len(units)):
        if i not in drop:
            remap[i] = n
            n += 1
    units = [u for i, u in enumerate(units) if i not in drop]
    for u in units:
        u["nb"] = [remap[j] for j in u["nb"] if j in remap]
    old_idx = {}
    base = len(units)
    new = []
    for cc, codes in ORDER.items():
        raw = {}
        if cc == "PM":
            outline = poly_of(pmr_old[0])
            for code in codes:
                gl = pm_ne.get(code)
                if not gl:
                    raise SystemExit("нет данных PM-%s" % code)
                raw[code] = proj(unary_union(gl)).intersection(outline)
            taken = unary_union(list(raw.values()))
            rest = outline.difference(taken)
            for d in (0.5, 1.0, 2.0, 3.0, 5.0, 8.0, 12.0):
                if rest.area < 1e-6:
                    break
                for code in codes:
                    add = raw[code].buffer(d).intersection(rest)
                    if add.area > 0:
                        raw[code] = raw[code].union(add)
                        rest = rest.difference(add)
            country = outline
        else:
            for code in codes:
                gl = groups.get((cc, code))
                if not gl:
                    raise SystemExit("нет данных: %s-%s" % (cc, code))
                raw[code] = proj(unary_union([x.buffer(0.0005) for x in gl]).buffer(-0.0005))
            country = unary_union(list(raw.values()))
        cut, taken = [], None
        for code in reversed(codes):
            r = raw[code].intersection(country)
            if taken is not None:
                r = r.difference(taken)
            taken = r if taken is None else taken.union(r)
            cut.append(r)
        cut.reverse()
        for code, pg in zip(codes, cut):
            polys = []
            for q in getattr(polys_only(pg), "geoms", [polys_only(pg)]):
                polys += [x for x in getattr(q, "geoms", [q]) if isinstance(x, Polygon)]
            polys = [q for q in polys if q.area > MIN_AREA.get(cc, 0.6)]
            if not polys:
                raise SystemExit("пусто: %s-%s" % (cc, code))
            polys.sort(key=lambda q: -q.area)
            mp = polys[0]
            c = mp.centroid if mp.contains(mp.centroid) else mp.representative_point()
            new.append({"id": "%s-%s" % (cc, code), "cc": cc, "c": [round(c.x, 1), round(c.y, 1)], "nb": [],
                        "parts": [ring_pts(q) for q in polys], "_geo": unary_union(polys)})
        print(cc, "площадь", round(country.area, 2), "регионов", len(codes))
    # соседи: старые грубые контуры (кроме Приднестровья — оно заменено) режутся по новым странам
    newall = unary_union([u["_geo"] for u in new if u["cc"] != "PM"])
    cutter = newall.buffer(0.05)
    for u in units:
        g0_ = poly_of(u)
        if g0_.intersection(cutter).area < 0.02:
            continue
        set_parts(u, g0_, cutter)
        print("старый контур обрезан:", u["id"], round(g0_.area - poly_of(u).area, 2))
    allu = units + new
    geos = [poly_of(u) for u in units] + [u["_geo"] for u in new]
    idx = {u["id"]: i for i, u in enumerate(allu)}

    def link(i, j):
        if j not in allu[i]["nb"]:
            allu[i]["nb"].append(j)
        if i not in allu[j]["nb"]:
            allu[j]["nb"].append(i)
    for k in range(base, len(allu)):
        gk = geos[k].buffer(1.2)
        thr = 0.02 if allu[k]["cc"] in ("MC", "SM", "LI") else 0.5
        for j in range(len(allu)):
            if j != k and gk.intersects(geos[j]) and gk.intersection(geos[j]).area > thr:
                link(k, j)
    for a, b in SEA:
        if a in idx and b in idx:
            link(idx[a], idx[b])
    for u in new:
        del u["_geo"]
    datio.dump("data/world_units.dat", allu)
    # контекст: Северный Кипр (ТРСК) — фоновая страна; старые контуры режутся по новым
    newg = unary_union(geos[base:]).buffer(0.1)
    for c in ctx:
        g0_ = poly_of(c)
        if g0_.intersects(newg) and g0_.intersection(newg).area > 0.05:
            set_parts(c, g0_, newg)
            print("ctx обрезан:", c["name"])
    ctx = [c for c in ctx if c.get("id") != "CYN"]
    sh = proj(unary_union(cyn))
    o = {"id": "CYN", "name": "Северный Кипр", "parts": []}
    gu = polys_only(sh).simplify(0.3, preserve_topology=True)
    gu = polys_only(gu.difference(newg))
    ps = sorted([q for q in getattr(gu, "geoms", [gu]) if isinstance(q, Polygon) and q.area > 0.3], key=lambda q: -q.area)
    o["parts"] = [ring_pts(q) for q in ps]
    ctx.append(o)
    gdconst.put(DC, "WORLD_CTX", ctx, True)
    for u in new:
        print(u["id"], "соседей", len(u["nb"]), "вершин", sum(len(p) // 2 for p in u["parts"]))


if __name__ == "__main__":
    main()
