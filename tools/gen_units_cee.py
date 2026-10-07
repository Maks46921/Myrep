#!/usr/bin/env python3
"""v33: добавляет в data/world_units.dat полигоны Словении (SI, 7 регионов), Словакии (SK, 8 краёв), Венгрии (HU, 8 регионов)
и Финляндии (FI, 8 регионов + Аландские острова) из Natural Earth admin-1 (/tmp/ne_admin1.geojson).
Проекция та же, что у остальной карты: x = 25.7085*lon + 154.29; y = -38.6135*lat + 2192.0.
Соседство считается и с уже существующими единицами (AT, CZ, PL, IT, SE, NO): их списки nb дополняются."""
import sys, json, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import datio
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "newc"))
import gdconst
DC = "scripts/data/data_core.gd"
CTX0 = "tools/ctx_before_v33.dat"
UNITS0 = "tools/units_before_v33.dat"
# соседи новых стран: их земля из Natural Earth заполняет щели между грубыми старыми контурами и новыми странами
NB_UNITS = {"AUT": "AT", "ITA": "IT", "CZE": "CZ", "POL": "PL", "SWE": "SE", "NOR": "NO"}
NB_CTX = {"HRV": "Хорватия", "SRB": "Сербия", "ROU": "Румыния", "UKR": "Украина", "RUS": "Россия"}
from shapely.geometry import shape, Polygon, MultiPolygon, box
from shapely.ops import unary_union
from shapely import affinity
from shapely.validation import make_valid
import shapely
SRC = "/tmp/ne_admin1.geojson"
# код региона -> (поле NE, значения)
SI = {"OSR": ("region", ["Osrednjeslovenska", "Zasavska"]), "POD": ("region", ["Podravska"]), "POM": ("region", ["Pomurska"]),
      "SAV": ("region", ["Savinjska", "Koroška"]), "GOR": ("region", ["Gorenjska"]),
      "PRI": ("region", ["Obalno-kraška", "Goriška", "Notranjsko-kraška"]), "JVS": ("region", ["Jugovzhodna Slovenija", "Spodnjeposavska"])}
SK = {"BA": ("name", ["Bratislavský"]), "TT": ("name", ["Trnavský"]), "TN": ("name", ["Trenciansky"]), "NR": ("name", ["Nitriansky"]),
      "ZA": ("name", ["Žilinský"]), "BB": ("name", ["Banskobystrický"]), "PO": ("name", ["Prešov"]), "KE": ("name", ["Košický"])}
HU = {"PES": ("name", ["Pest", "Érd"]), "BUD": ("name", ["Budapest"]),   # Будапешт после Пешта: анклав рисуется поверх
      "KDT": ("region", ["Central Transdanubia"]), "NYD": ("region", ["Western Transdanubia"]), "DDT": ("region", ["Southern Transdanubia"]),
      "EMO": ("region", ["Northern Hungary"]), "EAL": ("region", ["Northern Great Plain"]), "DAL": ("region", ["Great Southern Plain"])}
FI = {"UUS": ("name", ["Uusimaa"]), "VSS": ("name", ["Finland Proper", "Satakunta"]), "HAM": ("name", ["Pirkanmaa", "Tavastia Proper", "Päijät-Häme"]),
      "KAA": ("name", ["Kymenlaakso", "South Karelia"]), "POH": ("name", ["Ostrobothnia", "Southern Ostrobothnia", "Central Ostrobothnia"]),
      "ISU": ("name", ["Central Finland", "Northern Savonia", "Southern Savonia", "North Karelia"]),
      "PPO": ("name", ["Northern Ostrobothnia", "Kainuu"]), "LAP": ("name", ["Lapland"]), "AHV": ("adm0", ["ALD"])}
SETS = [("SI", "SVN", SI), ("SK", "SVK", SK), ("HU", "HUN", HU), ("FI", "FIN", FI)]
SEA = [("FI-AHV", "FI-VSS"), ("FI-AHV", "SE-STO"), ("FI-POH", "SE-ONO"), ("FI-LAP", "NO-NNO")]   # морские переходы (Аланды, Кваркен) и упрощённая граница Лапландии с Норвегией
NEWCC = [s[0] for s in SETS]

def proj(g):
    return affinity.affine_transform(g, [25.7085, 0, 0, -38.6135, 154.29, 2192.0])

def poly_of(u):
    ps = []
    for p in u["parts"]:
        pts = list(zip(p[0::2], p[1::2]))
        if len(pts) >= 3:
            q = Polygon(pts)
            if not q.is_valid: q = q.buffer(0)
            ps.append(q)
    return unary_union(ps)

def polys_only(g):
    g = make_valid(g)
    ps = []
    for q in getattr(g, "geoms", [g]):
        if isinstance(q, Polygon): ps.append(q)
        elif isinstance(q, MultiPolygon): ps += list(q.geoms)
    return MultiPolygon(ps) if len(ps) != 1 else ps[0]

def ring_pts(p):
    """внешний контур, округлённый до 0.1, без повторных и самокасающихся вершин — иначе Godot не может его триангулировать"""
    for t in range(6):
        q = shapely.set_precision(p, 0.1)
        q = max([g for g in getattr(q, "geoms", [q]) if isinstance(g, Polygon)] or [Polygon()], key=lambda g: g.area)
        pts = [(round(x, 1), round(y, 1)) for x, y in list(q.exterior.coords)[:-1]]
        if len(pts) >= 3 and len(set(pts)) == len(pts) and Polygon(pts).is_valid:
            return [v for xy in pts for v in xy]
        p = Polygon(p.exterior).buffer(0.08 * (t + 1)).buffer(-0.04 * (t + 1))
    raise SystemExit("не удалось очистить контур")

def set_parts(o, geo, clip=None):
    """записывает внешние контуры геометрии в parts (единица карты или контекстная страна); центр поправляется, если выпал наружу"""
    gu = polys_only(geo).simplify(0.3, preserve_topology=True)
    if clip is not None: gu = polys_only(gu.difference(clip))
    ps = sorted([p for p in getattr(gu, "geoms", [gu]) if isinstance(p, Polygon) and p.area > 0.5], key=lambda p: -p.area)
    o["parts"] = [ring_pts(p) for p in ps]
    if "c" in o and ps:
        from shapely.geometry import Point
        if not any(p.contains(Point(o["c"])) for p in ps):
            rp = ps[0].representative_point()
            o["c"] = [round(rp.x, 1), round(rp.y, 1)]

def main():
    g = json.load(open(SRC))
    groups = {}
    for f in g["features"]:
        p = f["properties"]
        for cc, a3, M in SETS:
            for code, (fld, names) in M.items():
                if fld == "adm0":
                    if p.get("adm0_a3") in names: groups.setdefault((cc, code), []).append(shape(f["geometry"]))
                elif p.get("adm0_a3") == a3 and p.get(fld) in names:
                    groups.setdefault((cc, code), []).append(shape(f["geometry"]))
    # всегда строим от карты v32 (без SI/SK/HU/FI): повторный запуск даёт тот же результат
    units = datio.load(UNITS0)
    if any(u["cc"] in NEWCC for u in units): raise SystemExit("в %s уже есть SI/SK/HU/FI" % UNITS0)
    base = len(units)
    # прежние единицы карты (AT, CZ, PL, IT, SE, NO…) и контекстные страны нарисованы по другому, грубому источнику и местами
    # заходят на новые страны. Точнее Natural Earth: новые страны берутся как есть, старые контуры режутся по ним, щели добираются сушей соседей (v33.1)
    old_all = unary_union([poly_of(u) for u in units])
    # контекстные страны (Россия, Украина, Румыния, Хорватия…) грубые: на них новые страны не обрезаются, наоборот — их режем ниже
    # исходные контуры контекстных стран сохраняются при первом запуске: повторный запуск режет их заново, а не уже обрезанные
    if os.path.exists(CTX0): ctx = datio.load(CTX0)
    else:
        ctx = gdconst.get(DC, "WORLD_CTX")
        datio.dump(CTX0, ctx)
    ctx_all = unary_union([poly_of(c) for c in ctx])
    new = []
    allcut, allkeys, prev = [], [], None
    for cc, a3, M in SETS:
        raw = {}
        for code in M:
            gl = groups.get((cc, code))
            if not gl: raise SystemExit("нет данных: %s-%s" % (cc, code))
            raw[code] = proj(unary_union([x.buffer(0.0005) for x in gl]).buffer(-0.0005))
        # страна целиком: обрезка по соседям и сглаживание; регионы режутся по ней и между собой без перекрытий
        country = unary_union(list(raw.values())).buffer(0.4).buffer(-0.4)
        if prev is not None: country = country.difference(prev)     # без наложений между самими новыми странами
        prev = country if prev is None else prev.union(country)
        codes = list(M)
        cut, taken = [], None
        for code in reversed(codes):          # анклавы (идут позже) забирают свою площадь первыми
            r = raw[code].intersection(country)
            if taken is not None: r = r.difference(taken)
            taken = r if taken is None else taken.union(r)
            cut.append(r)
        cut.reverse()
        # остаток страны (заполненные щели, обрезки сглаживания) раздаём ближайшим регионам: наращиваем их по шагам
        rest = country.difference(taken)
        for d in (0.5, 1.0, 2.0, 3.0, 5.0, 8.0):
            if rest.area < 1e-6: break
            for k in range(len(cut)):
                add = cut[k].buffer(d).intersection(rest)
                if add.area > 0:
                    cut[k] = cut[k].union(add)
                    rest = rest.difference(add)
        allcut += [polys_only(r) for r in cut]
        allkeys += [(cc, code) for code in codes]
    # общее упрощение всего покрытия: соседние регионы (и соседние страны) получают одинаковую линию границы
    allcut = list(shapely.coverage_simplify(allcut, 0.8, simplify_boundary=True))
    for (cc, code), pg in zip(allkeys, allcut):
        pg = make_valid(pg)
        polys = [g for g in getattr(pg, "geoms", [pg]) if isinstance(g, Polygon)]
        sub = []
        for q in polys:
            sub += [g for g in getattr(q, "geoms", [q]) if isinstance(g, Polygon)]
        min_a = 0.8 if code != "AHV" else 0.3
        polys = [q for q in sub if q.area > min_a]
        if not polys: raise SystemExit("пусто: %s" % code)
        polys.sort(key=lambda q: -q.area)
        parts = []
        for q in polys:
            parts.append(ring_pts(q))
        mp = polys[0]
        c = mp.centroid if mp.contains(mp.centroid) else mp.representative_point()
        new.append({"id": "%s-%s" % (cc, code), "cc": cc, "c": [round(c.x, 1), round(c.y, 1)], "nb": [], "parts": parts, "_geo": unary_union(polys)})
    # щели вокруг новых стран — это настоящая суша соседей, которой нет в грубых старых контурах: добираем её из Natural Earth
    newall = unary_union([u["_geo"] for u in new])
    cutter = newall.buffer(0.05)
    for u in units:
        g0 = poly_of(u)
        if g0.intersection(cutter).area < 0.05: continue
        set_parts(u, g0, cutter)
        print("старый контур обрезан:", u["id"], round(g0.area - poly_of(u).area, 1))
    old_all = unary_union([poly_of(u) for u in units])
    covered = unary_union([old_all, ctx_all, newall])
    zone = newall.buffer(25).difference(covered)
    zb = box(*zone.bounds)
    nbg = {}
    for f in g["features"]:
        a3 = f["properties"].get("adm0_a3")
        if a3 in NB_UNITS or a3 in NB_CTX:
            sh = shape(f["geometry"])
            x0, y0, x1, y1 = zb.bounds
            if not sh.intersects(box((x0 - 154.29) / 25.7085, (2192.0 - y1) / 38.6135, (x1 - 154.29) / 25.7085, (2192.0 - y0) / 38.6135)):
                continue
            sp = make_valid(proj(sh))
            if sp.intersects(zb): nbg.setdefault(a3, []).append(sp.intersection(zb))
    touch = newall.buffer(1.5)
    for a3, gl in nbg.items():
        add = unary_union(gl).intersection(zone)
        comps = [q for q in getattr(add, "geoms", [add]) if isinstance(q, Polygon) and q.area > 0.5 and q.intersects(touch)]
        for q in comps:
            if a3 in NB_UNITS:
                cands = [u for u in units if u["cc"] == NB_UNITS[a3]]
                tgt = min(cands, key=lambda u: poly_of(u).distance(q))
            else:
                tgt = next(c for c in ctx if c["name"] == NB_CTX[a3])
            set_parts(tgt, poly_of(tgt).union(q.buffer(0.3)).buffer(0.2).buffer(-0.2), cutter)
            print("щель заполнена:", tgt.get("id", tgt.get("name")), round(q.area, 1))
    allu = units + new
    geos = [poly_of(u) for u in units] + [u["_geo"] for u in new]
    idx = {u["id"]: i for i, u in enumerate(allu)}
    def link(i, j):
        if j not in allu[i]["nb"]: allu[i]["nb"].append(j)
        if i not in allu[j]["nb"]: allu[j]["nb"].append(i)
    for k in range(base, len(allu)):
        gk = geos[k].buffer(1.2)
        for j in range(len(allu)):
            if j == k: continue
            if gk.intersects(geos[j]) and gk.intersection(geos[j]).area > 0.5:
                link(k, j)
    for a, b in SEA:
        link(idx[a], idx[b])
    for u in new: del u["_geo"]
    datio.dump("data/world_units.dat", allu)
    # контекстные страны режем по новым, чтобы не лежали под ними (Россия под Финляндией и т.п.)
    newg = unary_union(geos[base:]).buffer(0.1)
    for c in ctx:
        g0 = poly_of(c)
        if not g0.intersects(newg): continue
        set_parts(c, g0, newg)
        print("ctx обрезан:", c["name"], round(g0.area - poly_of(c).area, 1))
    gdconst.put(DC, "WORLD_CTX", ctx, True)
    for u in new:
        print(u["id"], [allu[j]["id"] for j in u["nb"]], sum(len(p) // 2 for p in u["parts"]))
main()
