#!/usr/bin/env python3
"""v49: добавляет в data/world_units.dat Молдову (MD), Беларусь (BY), Украину (UA), Россию (RU) и непризнанные образования —
Приднестровье (PMR), ДНР (DNR), ЛНР (LNR) — из Natural Earth admin-1 (/tmp/claude-0/geo/ne_admin1.geojson, вид «де-факто»: Крым — у России).
Карта расширяется на восток до Чукотки: части к западу от −100° долготы переносятся на +360° (Чукотка 180…191°).
Граница ДНР и подконтрольной Украине части Донецкой области — приблизительная линия соприкосновения конца 2025 г. (DON_UA).
Контекстные страны Украина, Молдавия, Белоруссия, Россия удаляются из WORLD_CTX; добавляются фоновые страны Кавказа, Средней Азии
и Дальнего Востока из Natural Earth admin-0 (/tmp/claude-0/geo/ne_admin0_50m.geojson).
Повторный запуск строит от сохранённых исходников tools/units_before_v49.dat и tools/ctx_before_v49.dat."""
import sys, json, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import datio
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "newc"))
import gdconst
from shapely.geometry import shape, Polygon, MultiPolygon, box, Point
from shapely.ops import unary_union, transform
from shapely.validation import make_valid
import shapely
from gen_units_cee import poly_of, polys_only, ring_pts

DC = "scripts/data/data_core.gd"
UNITS0 = "tools/units_before_v49.dat"
CTX0 = "tools/ctx_before_v49.dat"
SRC = "/tmp/claude-0/geo/ne_admin1.geojson"
SRC0 = "/tmp/claude-0/geo/ne_admin0_50m.geojson"


def lonfix(x, y, z=None):
    xs = [(xx + 360.0 if xx < -100.0 else xx) for xx in (x if hasattr(x, "__len__") else [x])]
    if not hasattr(x, "__len__"):
        xs = xs[0]
    return (xs, y) if z is None else (xs, y, z)


def proj(g):
    g = make_valid(transform(lonfix, g))
    return shapely.affinity.affine_transform(g, [25.7085, 0, 0, -38.6135, 154.29, 2192.0])


import shapely.affinity

# подконтрольная Украине часть Донецкой области (северо-запад: Краматорск, Славянск, Дружковка, Доброполье) — приблизительно, конец 2025 г.
DON_UA = Polygon([(36.3, 49.5), (37.75, 49.5), (38.12, 49.05), (38.05, 48.85), (37.85, 48.62), (37.68, 48.48), (37.35, 48.38),
                  (37.10, 48.30), (36.85, 48.18), (36.3, 48.18)])

MD = {"Chişinău": "CHI", "Bălţi": "BAL", "Sîngerei": "BAL", "Făleşti": "BAL", "Glodeni": "BAL", "Rîşcani": "BAL",
      "Briceni": "NOR", "Edineţ": "NOR", "Ocniţa": "NOR", "Donduseni": "NOR", "Soroca": "NOR", "Drochia": "NOR", "Floreşti": "NOR",
      "Orhei": "CEN", "Rezina": "CEN", "Şoldăneşti": "CEN", "Teleneşti": "CEN", "Ungheni": "CEN", "Călărași": "CEN", "Nisporeni": "CEN",
      "Străşeni": "CEN", "Criuleni": "CEN", "Ialoveni": "CEN", "Hîncesti": "CEN", "Anenii Noi": "CEN",
      "Cahul": "SUD", "Cantemir": "SUD", "Leova": "SUD", "Cimişlia": "SUD", "Basarabeasca": "SUD", "Causeni": "SUD", "Ștefan Vodă": "SUD",
      "Taraclia": "SUD", "Comrat": "GAG"}
PMR_NAMES = ["Camenca", "Grigoriopol", "Stîngă Nistrului", "Transnistria", "Bender"]
BY = {"City of Minsk": "MSK", "Minsk": "MIO", "Brest": "BRE", "Grodno": "GRO", "Gomel": "GOM", "Mogilev": "MOG", "Vitebsk": "VIT"}
UA = {"Kiev City": "KYI", "Kiev": "NOR", "Zhytomyr": "NOR", "Chernihiv": "NOR", "L'viv": "LVI",
      "Ivano-Frankivs'k": "ZAH", "Ternopil'": "ZAH", "Transcarpathia": "ZAH", "Chernivtsi": "ZAH", "Volyn": "VOL", "Rivne": "VOL",
      "Vinnytsya": "POD", "Khmel'nyts'kyy": "POD", "Cherkasy": "CEN", "Kirovohrad": "CEN", "Poltava": "CEN", "Kharkiv": "KHA", "Sumy": "KHA",
      "Dnipropetrovs'k": "DNI", "Zaporizhzhya": "ZAP", "Odessa": "ODE", "Mykolayiv": "MYK", "Kherson": "MYK"}
RU = {}
for code, isos in {
        "SZA": "LEN KR KO ARK NEN VLG MUR NGR PSK", "SPB": "SPE", "KGD": "KGD",
        "CEN": "BEL BRY VLA VOR IVA KLU KOS KRS LIP ORL RYA SMO TAM TVE TUL YAR",
        "YUG": "KDA AD ROS VGG AST KL", "KAV": "DA IN KB KC SE CE STA",
        "VOL": "NIZ KIR ME MO CU UD PER PNZ ULY SAM SAR ORE", "TAB": "TA BA",
        "URA": "SVE CHE KGN TYU KHM YAN X01~", "SIB": "ALT AL TY KK KYA IRK KEM NVS OMS TOM",
        "DVO": "BU ZAB SA KAM PRI KHA AMU MAG SAK YEV CHU"}.items():
    for s in isos.split():
        RU["RU-" + s] = code
ORDER = {"MD": ["CHI", "BAL", "NOR", "CEN", "SUD", "GAG"], "PMR": ["PMR"],
         "UA": ["KYI", "NOR", "LVI", "ZAH", "VOL", "POD", "CEN", "KHA", "DNI", "ZAP", "ODE", "MYK", "DON"],
         "DNR": ["DNR"], "LNR": ["LNR"], "BY": ["MSK", "MIO", "BRE", "GRO", "GOM", "MOG", "VIT"],
         "RU": ["MOW", "MOS", "SPB", "CEN", "SZA", "KGD", "YUG", "KAV", "KRY", "VOL", "TAB", "URA", "SIB", "DVO"]}
NEWCC = list(ORDER)
MIN_AREA = {"RU": 40.0}
CTX_DROP = ["Украина", "Молдавия", "Белоруссия", "Россия"]
NEW_CTX = [("KAZ", "Казахстан"), ("GEO", "Грузия"), ("AZE", "Азербайджан"), ("ARM", "Армения"), ("MNG", "Монголия"), ("CHN", "Китай"),
           ("PRK", "КНДР"), ("KOR", "Республика Корея"), ("JPN", "Япония"), ("UZB", "Узбекистан"), ("TKM", "Туркменистан"),
           ("KGZ", "Киргизия"), ("TJK", "Таджикистан"), ("IRN", "Иран"), ("AFG", "Афганистан"), ("SYR", "Сирия"), ("IRQ", "Ирак"),
           ("USA", "США (Аляска)")]
CTX_BOX = box(-30.0, 30.0, 200.0, 84.0)
NE_FIXED = ["FI", "EE", "LV", "LT", "RO", "HU", "SK"]        # соседи из Natural Earth: новые страны режутся по ним
NB_FILL = {"POL": "PL", "NOR": "NO"}                           # грубые старые контуры: щели добираются их сушей
SEA = [("RU-KGD", "RU-SPB"), ("RU-KRY", "RU-YUG")]             # Балтика до Калининграда, Крымский мост


def classify(p, g):
    a3 = p.get("adm0_a3")
    nm = p.get("name")
    if a3 == "MDA":
        if nm in PMR_NAMES or (nm == "Rezina" and g.centroid.x > 29.0):
            return ("PMR", "PMR")
        if nm in MD:
            return ("MD", MD[nm])
        raise SystemExit("Молдова: не распределено " + str(nm))
    if a3 == "BLR":
        return ("BY", BY[nm])
    if a3 == "UKR":
        if nm == "Donets'k":
            return ("UA", "*DON")
        if nm == "Luhans'k":
            return ("LNR", "LNR")
        if nm in UA:
            return ("UA", UA[nm])
        raise SystemExit("Украина: не распределено " + str(nm))
    if a3 == "RUS":
        if nm in ("Crimea", "Sevastopol"):
            return ("RU", "KRY")
        if nm == "Moskva":
            return ("RU", "MOW")
        if nm == "Moskovskaya":
            return ("RU", "MOS")
        iso = p.get("iso_3166_2")
        if iso in RU:
            return ("RU", RU[iso])
        raise SystemExit("Россия: не распределено %s %s" % (nm, iso))
    return None


def simp_parts(o, geo, tol, min_area):
    gu = polys_only(geo).simplify(tol, preserve_topology=True)
    ps = sorted([q for q in getattr(gu, "geoms", [gu]) if isinstance(q, Polygon) and q.area > min_area], key=lambda q: -q.area)
    o["parts"] = [ring_pts(q) for q in ps]


def main():
    g = json.load(open(SRC))
    groups = {}
    for f in g["features"]:
        p = f["properties"]
        if p.get("adm0_a3") not in ("MDA", "BLR", "UKR", "RUS"):
            continue
        sh = make_valid(shape(f["geometry"]))
        k = classify(p, sh)
        if k is None:
            continue
        if k[1] == "*DON":
            ua = sh.intersection(DON_UA)
            dn = sh.difference(DON_UA)
            groups.setdefault(("UA", "DON"), []).append(ua)
            groups.setdefault(("DNR", "DNR"), []).append(dn)
            continue
        groups.setdefault(k, []).append(sh)
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
    ctx = [c for c in ctx if c["name"] not in CTX_DROP]
    base = len(units)
    fixed = unary_union([poly_of(u) for u in units if u["cc"] in NE_FIXED]).buffer(0.05)
    allcut, allkeys, prev = [], [], fixed
    for cc, codes in ORDER.items():
        raw = {}
        for code in codes:
            gl = groups.get((cc, code))
            if not gl:
                raise SystemExit("нет данных: %s-%s" % (cc, code))
            raw[code] = proj(unary_union([x.buffer(0.0005) for x in gl]).buffer(-0.0005))
        country = unary_union(list(raw.values())).buffer(0.4).buffer(-0.4).difference(prev)
        prev = prev.union(country)
        cut, taken = [], None
        for code in reversed(codes):
            r = raw[code].intersection(country)
            if taken is not None:
                r = r.difference(taken)
            taken = r if taken is None else taken.union(r)
            cut.append(r)
        cut.reverse()
        rest = country.difference(taken)
        for d in (0.5, 1.0, 2.0, 3.0, 5.0, 8.0):
            if rest.area < 1e-6:
                break
            for k in range(len(cut)):
                add = cut[k].buffer(d).intersection(rest)
                if add.area > 0:
                    cut[k] = cut[k].union(add)
                    rest = rest.difference(add)
        allcut += [polys_only(r) for r in cut]
        allkeys += [(cc, code) for code in codes]
        print(cc, "площадь", round(country.area))
    allcut = list(shapely.coverage_simplify(allcut, 1.0, simplify_boundary=True))
    allcut = [polys_only(make_valid(pg).difference(fixed)) for pg in allcut]
    new = []
    for (cc, code), pg in zip(allkeys, allcut):
        polys = []
        for q in getattr(pg, "geoms", [pg]):
            polys += [x for x in getattr(q, "geoms", [q]) if isinstance(x, Polygon)]
        polys = [q for q in polys if q.area > MIN_AREA.get(cc, 0.6)]
        if not polys:
            raise SystemExit("пусто: %s-%s" % (cc, code))
        polys.sort(key=lambda q: -q.area)
        mp = polys[0]
        c = mp.centroid if mp.contains(mp.centroid) else mp.representative_point()
        new.append({"id": "%s-%s" % (cc, code), "cc": cc, "c": [round(c.x, 1), round(c.y, 1)], "nb": [],
                    "parts": [ring_pts(q) for q in polys], "_geo": unary_union(polys)})
    newall = unary_union([u["_geo"] for u in new])
    cutter = newall.buffer(0.05)
    # грубые старые контуры (PL, NO и др.) режутся по новым странам
    from gen_units_cee import set_parts
    for u in units:
        if u["cc"] in NE_FIXED:
            continue
        g0 = poly_of(u)
        if g0.intersection(cutter).area < 0.05:
            continue
        set_parts(u, g0, cutter)
        print("старый контур обрезан:", u["id"], round(g0.area - poly_of(u).area, 1))
    # щели между новыми странами и грубыми старыми контурами — сушей соседей из Natural Earth
    old_all = unary_union([poly_of(u) for u in units])
    covered = unary_union([old_all, newall])
    zone = newall.buffer(20).difference(covered).intersection(box(-200, -1500, 1600, 2500))
    zb = box(*zone.bounds)
    touch = newall.buffer(1.5)
    nbg = {}
    for f in g["features"]:
        a3 = f["properties"].get("adm0_a3")
        if a3 in NB_FILL:
            sp = make_valid(proj(shape(f["geometry"])))
            if sp.intersects(zb):
                nbg.setdefault(a3, []).append(sp.intersection(zb))
    for a3, gl in nbg.items():
        add = unary_union(gl).intersection(zone)
        comps = [q for q in getattr(add, "geoms", [add]) if isinstance(q, Polygon) and q.area > 0.5 and q.intersects(touch)]
        for q in comps:
            cands = [u for u in units if u["cc"] == NB_FILL[a3]]
            tgt = min(cands, key=lambda u: poly_of(u).distance(q))
            set_parts(tgt, poly_of(tgt).union(q.buffer(0.3)).buffer(0.2).buffer(-0.2), cutter)
            print("щель заполнена:", tgt["id"], round(q.area, 1))
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
        for j in range(len(allu)):
            if j != k and gk.intersects(geos[j]) and gk.intersection(geos[j]).area > 0.5:
                link(k, j)
    for a, b in SEA:
        link(idx[a], idx[b])
    for u in new:
        del u["_geo"]
    datio.dump("data/world_units.dat", allu)
    # контекст: старые страны режутся по новым, добавляются Кавказ, Средняя Азия, Дальний Восток
    newg = unary_union(geos[base:]).buffer(0.1)
    from gen_units_cee import set_parts as sp0
    for c in ctx:
        g0 = poly_of(c)
        if g0.intersects(newg):
            sp0(c, g0, newg)
            print("ctx обрезан:", c["name"])
    g0 = json.load(open(SRC0))
    clip_xy = proj(CTX_BOX)
    land_now = unary_union([newg, unary_union([poly_of(c) for c in ctx]).buffer(0.05), unary_union(geos[:base]).buffer(0.05)])
    for a3, nm in NEW_CTX:
        fs = [f for f in g0["features"] if f["properties"].get("ADM0_A3") == a3]
        if not fs:
            raise SystemExit("нет страны " + a3)
        sh = make_valid(proj(make_valid(shape(fs[0]["geometry"])))).intersection(clip_xy)
        sh = polys_only(make_valid(sh)).difference(land_now)
        o = {"id": a3, "name": nm, "parts": []}
        simp_parts(o, sh, 1.2, 8.0)
        if o["parts"]:
            ctx.append(o)
            land_now = land_now.union(poly_of(o).buffer(0.05))
            print("ctx добавлен:", nm, len(o["parts"]))
    gdconst.put(DC, "WORLD_CTX", ctx, True)
    tot = 0
    for u in new:
        n = sum(len(p) // 2 for p in u["parts"])
        tot += n
        print(u["id"], "соседей", len(u["nb"]), "вершин", n)
    print("вершин всего у новых:", tot)


if __name__ == "__main__":
    main()
