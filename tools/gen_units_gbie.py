#!/usr/bin/env python3
"""v30: добавляет в data/world_units.dat полигоны Великобритании (12 регионов) и Ирландии (8 регионов) из Natural Earth admin-1
(/tmp/ne_admin1.geojson). Проекция та же, что у остальной карты: x = 25.7085*lon + 154.29; y = -38.6135*lat + 2192.0."""
import sys, json, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import datio
from shapely.geometry import shape, Polygon, MultiPolygon
from shapely.ops import unary_union
from shapely import affinity
SRC = "/tmp/ne_admin1.geojson"
GB = {"SCO": ["Highlands and Islands", "South Western", "North Eastern", "Eastern"], "WAL": ["East Wales", "West Wales and the Valleys"], "NIR": ["Northern Ireland"],
      "NEE": ["North East"], "NWE": ["North West"], "YOR": ["Yorkshire and the Humber"], "EMI": ["East Midlands"], "WMI": ["West Midlands"],
      "EOE": ["East"], "LON": ["Greater London"], "SEE": ["South East"], "SWE": ["South West"]}
IE = {"BOR": ["Border"], "WES": ["West"], "MLD": ["Midlands"], "MWE": ["Mid-West"], "MEA": ["Mid-East"], "DUB": ["Dublin"], "SEA": ["South-East"], "SWT": ["South-West"]}
def proj(g):
    # (lon, lat) -> x, y
    return affinity.affine_transform(g, [25.7085, 0, 0, -38.6135, 154.29, 2192.0])
def main():
    g = json.load(open(SRC))
    groups = {}
    for f in g["features"]:
        p = f["properties"]
        for cc, a3, M in (("GB", "GBR", GB), ("IE", "IRL", IE)):
            if p.get("adm0_a3") != a3: continue
            for code, names in M.items():
                if p.get("region") in names:
                    groups.setdefault((cc, code), []).append(shape(f["geometry"]))
    units = datio.load("data/world_units.dat")
    units = [u for u in units if u["cc"] not in ("GB", "IE")]
    base = len(units)
    new = []
    for (cc, code), gl in groups.items():
        geo = unary_union([x.buffer(0.0005) for x in gl]).buffer(-0.0005)
        pg = proj(geo).simplify(0.35, preserve_topology=True)
        polys = list(pg.geoms) if isinstance(pg, MultiPolygon) else [pg]
        polys = [q for q in polys if q.area > 0.8]
        if not polys: raise SystemExit("пусто: %s" % code)
        polys.sort(key=lambda q: -q.area)
        parts = []
        for q in polys:
            pts = []
            for x, y in list(q.exterior.coords)[:-1]:
                pts += [round(x, 1), round(y, 1)]
            parts.append(pts)
        main_poly = polys[0]
        c = main_poly.representative_point() if not main_poly.contains(main_poly.centroid) else main_poly.centroid
        new.append({"id": "%s-%s" % (cc, code), "cc": cc, "c": [round(c.x, 1), round(c.y, 1)], "nb": [], "parts": parts, "_geo": unary_union(polys)})
    order = [("GB", k) for k in GB] + [("IE", k) for k in IE]
    new.sort(key=lambda u: order.index((u["cc"], u["id"].split("-")[1])))
    for i, u in enumerate(new):
        for j, v in enumerate(new):
            if i != j and u["_geo"].buffer(0.9).intersects(v["_geo"]) and u["_geo"].buffer(0.9).intersection(v["_geo"]).length > 0.5:
                u["nb"].append(base + j)
    idx = {u["id"]: base + i for i, u in enumerate(new)}
    for a, b in (("GB-NIR", "GB-SCO"), ("IE-DUB", "GB-WAL")):   # короткие морские проливы считаются соседством
        ua = new[idx[a] - base]; ub = new[idx[b] - base]
        if idx[b] not in ua["nb"]: ua["nb"].append(idx[b])
        if idx[a] not in ub["nb"]: ub["nb"].append(idx[a])
    for u in new: del u["_geo"]
    out = units + new
    datio.dump("data/world_units.dat", out)
    print("ok", len(out), [(u["id"], len(u["nb"]), sum(len(p) // 2 for p in u["parts"])) for u in new])
main()
