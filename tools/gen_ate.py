#!/usr/bin/env python3
"""v36: административно-территориальные единицы (АТЕ) — data/ate.dat.

АТЕ — минимальная единица территории: ~600 км² (между регионом Люксембурга ~860 и Веной ~415), почти равные по площади.
Сетка строится в градусах: шаг по широте постоянный, по долготе растёт как 1/cos(широты) — на карте (равнопромежуточная
проекция, x = 25.7085*lon + 154.29; y = -38.6135*lat + 2192.0) ячейки растягиваются к северу, а реальная площадь одинакова.
Ряды смещены «кирпичом», линии сетки слегка изогнуты (гладкий шум) — чтобы границы выглядели как настоящие.
Ячейки режутся точными контурами регионов из data/world_units.dat (границы стран и регионов сохраняются), обрывки
меньше 35% нормы приклеиваются к соседней АТЕ того же региона. Щели между полигонами регионов (разные источники)
заполняются ближайшим регионом, так что у соседних АТЕ всегда общая граница.

Формат (str_to_var, массивы-«столбцы» по всем АТЕ):
  uid  — исходная единица карты (регион) АТЕ, cx/cy — точка подписи, km — площадь, pw/gw — доля в населении/ВВП исходного региона
  to/tv — треугольники заливки (смещения в треугольниках, по 6 чисел на треугольник)
  no/nb — соседи; ea/eb/eo/ep — общие участки границ (eb = -1: побережье или край карты), полилинии в ep
"""
import sys, os, json, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import datio
import numpy as np
import shapely
from shapely.geometry import Polygon, MultiPolygon, LineString, Point, box
from shapely.ops import unary_union, polygonize, linemerge
from shapely.strtree import STRtree
from shapely.prepared import prep

KM2 = 600.0
SIDE = math.sqrt(KM2)
DLAT = SIDE / 111.32
SMALL = 0.5          # обрывок меньше этой доли нормы — приклеивается к соседу
AMP = 1.0             # изгиб линий сетки, единиц карты (ячейка ~8.5)
OUT = "data/ate.dat"

# крупные города (широта, долгота, млн жителей) — население АТЕ распределяется не только по площади
CITIES = [
    (52.52, 13.40, 3.7), (53.55, 10.0, 1.9), (48.14, 11.58, 1.5), (50.94, 6.96, 1.1), (50.11, 8.68, 0.75), (48.78, 9.18, 0.63),
    (51.23, 6.78, 0.62), (51.51, 7.47, 0.59), (51.46, 7.01, 0.58), (51.34, 12.37, 0.6), (53.08, 8.80, 0.57), (51.05, 13.74, 0.56),
    (52.37, 9.73, 0.54), (49.45, 11.08, 0.52), (51.43, 6.76, 0.5),
    (48.86, 2.35, 6.5), (45.76, 4.84, 1.4), (43.30, 5.37, 1.6), (43.60, 1.44, 0.8), (43.70, 7.27, 0.6), (47.22, -1.55, 0.6),
    (48.58, 7.75, 0.5), (50.63, 3.06, 1.0), (44.84, -0.58, 0.8), (48.11, -1.68, 0.4),
    (51.51, -0.13, 8.9), (52.49, -1.89, 2.5), (53.48, -2.24, 2.7), (53.80, -1.55, 1.8), (55.86, -4.25, 1.0), (55.95, -3.19, 0.5),
    (53.41, -2.98, 0.9), (54.98, -1.61, 0.8), (51.45, -2.59, 0.6), (51.48, -3.18, 0.5), (54.60, -5.93, 0.6), (53.38, -1.47, 0.7),
    (40.42, -3.70, 6.0), (41.39, 2.17, 4.5), (39.47, -0.38, 1.5), (37.39, -5.98, 1.2), (43.26, -2.93, 0.9), (36.72, -4.42, 0.6),
    (41.65, -0.88, 0.7), (28.1, -15.4, 0.4),
    (41.90, 12.50, 3.5), (45.46, 9.19, 3.2), (40.85, 14.27, 2.2), (45.07, 7.69, 1.5), (38.12, 13.36, 0.9), (44.49, 11.34, 0.6),
    (43.77, 11.26, 0.6), (45.44, 12.32, 0.5), (45.41, 11.88, 0.3), (41.12, 16.87, 0.6),
    (52.37, 4.90, 1.4), (51.92, 4.48, 1.0), (52.08, 4.30, 0.8), (52.09, 5.12, 0.5), (51.44, 5.47, 0.3),
    (50.85, 4.35, 1.9), (51.22, 4.40, 1.0), (51.05, 3.72, 0.5), (50.63, 5.57, 0.6), (50.41, 4.44, 0.4),
    (48.21, 16.37, 1.9), (47.07, 15.44, 0.3), (48.31, 14.29, 0.2), (47.80, 13.04, 0.15), (47.27, 11.39, 0.13),
    (47.38, 8.54, 1.0), (46.20, 6.14, 0.6), (47.56, 7.59, 0.5), (46.95, 7.45, 0.4), (46.52, 6.63, 0.4),
    (52.23, 21.01, 2.5), (50.06, 19.94, 1.2), (51.11, 17.04, 0.8), (51.76, 19.46, 0.7), (52.41, 16.93, 0.7), (54.35, 18.65, 0.9),
    (50.26, 19.02, 2.0), (53.13, 23.16, 0.3), (51.25, 22.57, 0.3), (53.43, 14.55, 0.4),
    (50.08, 14.44, 1.3), (49.20, 16.61, 0.4), (49.84, 18.29, 0.3),
    (48.15, 17.11, 0.5), (48.72, 21.26, 0.25), (47.50, 19.04, 1.8), (47.53, 21.63, 0.2), (46.25, 20.15, 0.16),
    (46.06, 14.51, 0.3), (46.56, 15.65, 0.1),
    (38.72, -9.14, 2.0), (41.15, -8.61, 1.3),
    (53.35, -6.26, 1.4), (51.90, -8.47, 0.3), (53.27, -9.05, 0.1),
    (55.68, 12.57, 1.4), (56.16, 10.20, 0.3), (55.40, 10.39, 0.2), (57.05, 9.92, 0.2),
    (59.33, 18.07, 1.6), (57.71, 11.97, 0.6), (55.60, 13.0, 0.4), (59.86, 17.64, 0.2),
    (59.91, 10.75, 1.0), (60.39, 5.32, 0.3), (63.43, 10.39, 0.2), (58.97, 5.73, 0.2),
    (60.17, 24.94, 1.3), (61.50, 23.76, 0.25), (60.45, 22.27, 0.2), (65.01, 25.47, 0.2),
    (49.61, 6.13, 0.13),
    # v49: Молдова, Беларусь, Украина, Россия и непризнанные образования
    (47.01, 28.86, 0.65), (47.76, 27.93, 0.1), (46.84, 29.63, 0.13), (46.31, 28.66, 0.03),
    (53.90, 27.56, 2.0), (52.43, 31.00, 0.5), (53.90, 30.33, 0.36), (55.19, 30.20, 0.36), (53.68, 23.83, 0.36), (52.10, 23.69, 0.34),
    (50.45, 30.52, 2.9), (49.99, 36.23, 1.3), (46.48, 30.72, 1.0), (48.46, 35.05, 0.95), (49.84, 24.03, 0.72), (47.84, 35.14, 0.7),
    (47.91, 33.39, 0.6), (46.98, 31.99, 0.45), (49.23, 28.47, 0.37), (49.59, 34.55, 0.28), (50.91, 34.80, 0.25), (51.50, 31.29, 0.28),
    (48.74, 37.58, 0.15), (48.02, 37.80, 0.9), (48.04, 37.96, 0.33), (48.30, 38.03, 0.24), (47.10, 37.55, 0.3), (48.57, 39.33, 0.4),
    (55.75, 37.62, 13.0), (59.94, 30.31, 5.6), (55.03, 82.92, 1.6), (56.84, 60.60, 1.5), (55.79, 49.12, 1.3), (56.33, 44.00, 1.2),
    (55.16, 61.40, 1.2), (53.20, 50.15, 1.15), (54.73, 55.95, 1.15), (47.24, 39.71, 1.14), (45.04, 38.98, 1.1), (54.99, 73.37, 1.1),
    (51.67, 39.18, 1.05), (58.01, 56.25, 1.03), (48.71, 44.51, 1.0), (56.01, 92.85, 1.2), (51.53, 46.03, 0.9), (57.15, 65.53, 0.85),
    (53.51, 49.42, 0.68), (56.85, 53.20, 0.64), (53.35, 83.78, 0.63), (52.29, 104.28, 0.62), (48.48, 135.08, 0.62), (43.12, 131.89, 0.6),
    (57.63, 39.87, 0.57), (42.98, 47.50, 0.6), (56.48, 84.95, 0.57), (51.77, 55.10, 0.55), (55.35, 86.09, 0.55), (53.76, 87.14, 0.54),
    (54.63, 39.74, 0.53), (46.35, 48.04, 0.47), (55.74, 52.40, 0.55), (53.20, 45.00, 0.5), (58.60, 49.66, 0.47), (52.61, 39.60, 0.5),
    (54.71, 20.51, 0.49), (44.62, 33.52, 0.55), (44.95, 34.10, 0.34), (43.32, 45.69, 0.33), (68.97, 33.08, 0.27), (64.54, 40.54, 0.3),
    (62.03, 129.73, 0.36), (61.25, 73.40, 0.38), (51.83, 107.58, 0.43), (52.03, 113.50, 0.35), (50.29, 127.53, 0.24), (53.02, 158.65, 0.16),
]
# v49: размер АТЕ по регионам России (км²): огромные малонаселённые регионы делятся крупнее, иначе карта утяжелилась бы вчетверо
KM2_UNIT = {}
# v50: у 89 субъектов России размер ячейки — по площади субъекта (≈ 18 АТЕ на субъект), из набора классов
RU_KM2_CLASSES = [300.0, 600.0, 1000.0, 1500.0, 2500.0, 4000.0, 6000.0, 10000.0, 15000.0, 25000.0]


def ru_unit_km2(poly):
    import math as _m
    lat = (2192.0 - poly.centroid.y) / 38.6135
    km2 = poly.area * (111.32 * _m.cos(_m.radians(lat)) / 25.7085) * (111.32 / 38.6135)
    want = km2 / 18.0
    best = RU_KM2_CLASSES[0]
    for c in RU_KM2_CLASSES:
        if c <= want:
            best = c
    return best


def proj_xy(lon, lat):
    return 25.7085 * lon + 154.29, -38.6135 * lat + 2192.0


def unproj(x, y):
    return (x - 154.29) / 25.7085, (2192.0 - y) / 38.6135


def km2_of(g):
    # площадь в км²: масштаб по x зависит от широты — считаем по центру каждой части
    s = 0.0
    for p in getattr(g, "geoms", [g]):
        if p.is_empty:
            continue
        lat = unproj(0, p.centroid.y)[1]
        s += p.area * (111.32 * math.cos(math.radians(lat)) / 25.7085) * (111.32 / 38.6135)
    return s


class Noise:
    """гладкое смещение плоскости: сумма синусоид со случайными фазами (детерминировано); sc — масштаб (крупные ячейки)"""
    def __init__(self, seed, sc=1.0):
        r = random.Random(seed)
        self.w = []
        self.sc = sc
        for k in range(6):
            lam = r.uniform(11.0, 22.0) * sc
            a = r.uniform(0, math.pi)
            self.w.append((math.cos(a) * 2 * math.pi / lam, math.sin(a) * 2 * math.pi / lam, r.uniform(0, 6.283), r.uniform(0, 6.283)))

    def d(self, x, y):
        dx = dy = 0.0
        for fx, fy, p1, p2 in self.w:
            t = fx * x + fy * y
            dx += math.sin(t + p1)
            dy += math.sin(t + p2)
        k = AMP * self.sc / math.sqrt(len(self.w) / 2)
        return dx * k, dy * k


def unit_polys(units):
    P = []
    for u in units:
        ps = []
        for p in u["parts"]:
            pts = list(zip(p[0::2], p[1::2]))
            if len(pts) >= 3:
                q = Polygon(pts)
                if not q.is_valid:
                    q = q.buffer(0)
                ps.append(q)
        P.append(unary_union(ps))
    return P


def grid_lines(land, nz, side=SIDE, bounds=None):
    """отрезки сетки (уже изогнутые) рядом с сушей; каждый отрезок чуть длиннее нужного — висячие концы polygonize отбросит"""
    dlat = side / 111.32
    sc = side / SIDE
    lp = prep(land.buffer(16.0 * sc))
    lon0, lat0, lon1, lat1 = -32.0, 26.0, 36.0, 72.0
    x0, y0, x1, y1 = land.bounds if bounds is None else bounds
    lon0, lat1 = unproj(x0, y0)
    lon1, lat0 = unproj(x1, y1)
    lon0 -= 1; lon1 += 1; lat0 -= 0.5; lat1 += 0.5
    nb = int((lat1 - lat0) / dlat) + 1
    segs = []

    def bend(pts):
        out = []
        for x, y in pts:
            dx, dy = nz.d(x, y)
            out.append((x + dx, y + dy))
        return out

    def dense(a, b, step=2.2 * sc):
        n = max(1, int(math.hypot(b[0] - a[0], b[1] - a[1]) / step))
        return [(a[0] + (b[0] - a[0]) * t / n, a[1] + (b[1] - a[1]) * t / n) for t in range(n + 1)]

    for j in range(nb + 1):
        la = lat0 + j * dlat
        # горизонтальная линия на широте la: точки на общей сетке по x, берутся только участки у суши
        ya = proj_xy(0, la)[1]
        xs = proj_xy(lon0, 0)[0]
        xe = proj_xy(lon1, 0)[0]
        st = 2.2 * sc
        nx = int((xe - xs) / st) + 1
        run = []
        for k in range(nx):
            a, b = (xs + k * st, ya), (xs + (k + 1) * st, ya)
            if lp.intersects(LineString([a, b])):
                if not run:
                    run = [a]
                run.append(b)
            elif run:
                segs.append(LineString(bend(run)))
                run = []
        if run:
            segs.append(LineString(bend(run)))
        if j == nb:
            break
        lc = la + dlat / 2
        dlon = side / (111.32 * math.cos(math.radians(lc)))
        off = (0.5 * dlon) if j % 2 else 0.0
        yb = proj_xy(0, la + dlat)[1]
        k = math.floor((lon0 - off) / dlon)
        while True:
            lo = off + k * dlon
            if lo > lon1:
                break
            xv = proj_xy(lo, 0)[0]
            a, b = (xv, ya + 3.0 * sc), (xv, yb - 3.0 * sc)
            ln = LineString([a, b])
            if lp.intersects(ln):
                segs.append(LineString(bend(dense(a, b))))
            k += 1
    return segs


def main():
    units = datio.load("data/world_units.dat")
    world = datio.load("data/world.dat")
    P = unit_polys(units)
    n_u = len(units)
    area_u = [p.area for p in P]
    # перекрытия: достаются меньшему региону (анклавы вроде Берлина внутри Бранденбурга)
    order = sorted(range(n_u), key=lambda i: area_u[i])
    taken = None
    clean = [None] * n_u
    for i in order:
        g = P[i] if taken is None else P[i].difference(taken)
        clean[i] = g
        taken = g if taken is None else unary_union([taken, g])
    land = unary_union(clean)
    closed = land.buffer(0.6, join_style=2).buffer(-0.6, join_style=2)
    print("суша", round(land.area), "регионов", n_u, file=sys.stderr)
    # v49: классы размера ячеек — обычные 600 км² и крупные для регионов России; сетка класса режется по его суше
    ukm = [KM2_UNIT.get(u["id"], ru_unit_km2(clean[i]) if u["cc"] == "RU" else KM2) for i, u in enumerate(units)]
    classes = sorted(set(ukm))
    big = unary_union([clean[i] for i in range(n_u) if ukm[i] != KM2]) if len(classes) > 1 else None
    land0 = unary_union([clean[i] for i in range(n_u) if ukm[i] == KM2])
    segs = []
    cell_trees = {}
    cells_k = {}
    for k in classes:
        lk = land0 if k == KM2 else unary_union([clean[i] for i in range(n_u) if ukm[i] == k])
        sk = grid_lines(lk, Noise(36, math.sqrt(k / KM2)), math.sqrt(k), land.bounds if k == KM2 else None)
        cl = list(polygonize(unary_union(sk)))
        cells_k[k] = cl
        cell_trees[k] = STRtree(cl)
        if k == KM2:
            if big is not None:
                bp = prep(big.buffer(0.02))
                sk2 = []
                for sg in sk:
                    if bp.intersects(sg):
                        d = sg.difference(big)
                        sk2 += [q for q in getattr(d, "geoms", [d]) if isinstance(q, LineString) and q.length > 1e-6]
                    else:
                        sk2.append(sg)
                sk = sk2
        else:
            d = unary_union(sk).intersection(lk)
            sk = [q for q in getattr(d, "geoms", [d]) if isinstance(q, LineString) and q.length > 1e-6]
        segs += sk
        print("класс %.0f км²: отрезков %d, ячеек %d" % (k, len(sk), len(cl)), file=sys.stderr)
    lines = [g.boundary for g in clean] + segs
    noded = unary_union(lines)
    # упрощение цепочек между узлами (концы цепочек неподвижны — общие границы остаются общими)
    chains = linemerge(noded)
    chains = [c.simplify(0.3) for c in getattr(chains, "geoms", [chains])]
    faces = list(polygonize(unary_union(chains)))
    print("граней", len(faces), file=sys.stderr)
    utree = STRtree(clean)
    f_reg = [-1] * len(faces)
    f_cell = [-1] * len(faces)
    rp = [f.representative_point() for f in faces]
    for fi, f in enumerate(faces):
        cand = utree.query(rp[fi], predicate="within")
        if len(cand):
            f_reg[fi] = int(min(cand, key=lambda i: area_u[i]))
        if f_reg[fi] >= 0:
            kk = ukm[f_reg[fi]]
            cc = cell_trees[kk].query(rp[fi], predicate="within")
            if len(cc):
                f_cell[fi] = int(cc[0]) + 1000000 * classes.index(kk)
    # щели между полигонами регионов: мелкие грани внутри «закрытой» суши достаются соседу с самой длинной общей границей
    ftree = STRtree(faces)
    cp = prep(closed)
    gaps = [fi for fi in range(len(faces)) if f_reg[fi] < 0 and faces[fi].area < 40.0 and cp.contains(rp[fi])]
    for it in range(8):
        left = []
        for fi in gaps:
            best, bl = -1, 0.0
            for fj in ftree.query(faces[fi]):
                if fj == fi or f_reg[fj] < 0:
                    continue
                l = faces[fi].boundary.intersection(faces[fj].boundary).length
                if l > bl:
                    best, bl = f_reg[fj], l
            if best >= 0:
                f_reg[fi] = best
            else:
                left.append(fi)
        gaps = left
        if not gaps:
            break
    for fi in range(len(faces)):
        if f_reg[fi] >= 0 and f_cell[fi] < 0:
            kk = ukm[f_reg[fi]]
            cc = cell_trees[kk].query(rp[fi], predicate="within")
            if len(cc):
                f_cell[fi] = int(cc[0]) + 1000000 * classes.index(kk)
    # куски: (регион, ячейка) -> связные компоненты
    groups = {}
    for fi in range(len(faces)):
        if f_reg[fi] < 0:
            continue
        groups.setdefault((f_reg[fi], f_cell[fi]), []).append(faces[fi])
    pieces = []      # [регион, геометрия]
    for (r, c), fs in groups.items():
        g = unary_union(fs)
        for p in getattr(g, "geoms", [g]):
            if isinstance(p, Polygon) and p.area > 1e-6:
                pieces.append([r, p])
    print("кусков", len(pieces), file=sys.stderr)
    # приклеиваем мелкие куски к соседу того же региона (по самой длинной общей границе)
    alive = [True] * len(pieces)
    changed = True
    while changed:
        changed = False
        geoms = [p[1] for p in pieces]
        tree = STRtree(geoms)
        idx = sorted([i for i in range(len(pieces)) if alive[i]], key=lambda i: geoms[i].area)
        dirty = set()
        for i in idx:
            if not alive[i] or i in dirty:
                continue
            a = km2_of(pieces[i][1])
            K = ukm[pieces[i][0]]
            if a >= SMALL * K:
                continue
            best, bl, bd = -1, 0.0, 1e18
            for j in tree.query(pieces[i][1].buffer(0.01)):
                j = int(j)
                if j == i or not alive[j] or j in dirty or pieces[j][0] != pieces[i][0]:
                    continue
                l = pieces[i][1].boundary.intersection(pieces[j][1].boundary).length
                aj = km2_of(pieces[j][1])
                score = l / (1.0 + max(0.0, a + aj - 1.5 * K) / K)
                if score > bl:
                    best, bl = j, score
            if best < 0:
                # остров: к ближайшему куску того же региона, если сам очень мал
                if a >= 0.12 * K:
                    continue
                for j in range(len(pieces)):
                    if j == i or not alive[j] or j in dirty or pieces[j][0] != pieces[i][0]:
                        continue
                    d = pieces[i][1].distance(pieces[j][1])
                    if d < bd:
                        best, bd = j, d
                if best < 0 or bd > 12.0 * math.sqrt(K / KM2):
                    continue
            pieces[best][1] = unary_union([pieces[best][1], pieces[i][1]])
            alive[i] = False
            dirty.add(best)
            changed = True
    ate = [p for i, p in enumerate(pieces) if alive[i]]
    # порядок: по странам и регионам, внутри — с севера на юг, с запада на восток
    ate.sort(key=lambda p: (units[p[0]]["id"], round(p[1].centroid.y / 8.0), p[1].centroid.x))
    n = len(ate)
    G = [p[1] for p in ate]
    R = [p[0] for p in ate]
    km = [km2_of(g) for g in G]
    print("АТЕ", n, "площадь: мин %.0f, медиана %.0f, макс %.0f км²" % (min(km), sorted(km)[n // 2], max(km)), file=sys.stderr)
    # население и экономика: площадь × шум + крупные города
    wpop = {}
    for cc, w in world.items():
        for r in w["regions"]:
            wpop[r["id"]] = float(r["popm"])
    rng = random.Random(7)
    base = [km[a] * math.exp(rng.gauss(0.0, 0.45)) for a in range(n)]
    city = [0.0] * n
    tree = STRtree(G)
    for la, lo, pm in CITIES:
        pt = Point(*proj_xy(lo, la))
        c = [int(a) for a in tree.query(pt, predicate="within")]
        if not c:
            c = [int(tree.nearest(pt))]
        city[c[0]] += pm
    pw = [0.0] * n
    gw = [0.0] * n
    by_r = {}
    for a in range(n):
        by_r.setdefault(R[a], []).append(a)
    for r, lst in by_r.items():
        tot = wpop.get(units[r]["id"], 1.0)
        cs = sum(city[a] for a in lst)
        rural = max(0.3 * tot, tot - cs)
        bs = sum(base[a] for a in lst)
        cs_eff = min(cs, 0.7 * tot)
        for a in lst:
            p = rural * base[a] / bs + (cs_eff * city[a] / cs if cs > 0 else 0.0)
            pw[a] = p
            gw[a] = p * (1.0 + 0.6 * min(1.0, city[a] / max(0.05, p)))
        sp = sum(pw[a] for a in lst)
        sg = sum(gw[a] for a in lst)
        for a in lst:
            pw[a] /= sp
            gw[a] /= sg
    # соседи и общие границы
    nbs = [set() for _ in range(n)]
    edges = []
    bnd = [g.boundary for g in G]
    for a in range(n):
        shared = []
        for b in tree.query(G[a].buffer(0.01)):
            b = int(b)
            if b == a:
                continue
            s = bnd[a].intersection(bnd[b])
            ls = [q for q in getattr(s, "geoms", [s]) if isinstance(q, LineString) and q.length > 1e-6]
            if not ls:
                continue
            nbs[a].add(b)
            shared += ls
            if a < b:
                m = linemerge(ls) if len(ls) > 1 else ls[0]
                for q in getattr(m, "geoms", [m]):
                    edges.append((a, b, list(q.coords)))
        rest = bnd[a].difference(unary_union(shared)) if shared else bnd[a]
        for q in getattr(rest, "geoms", [rest]):
            if isinstance(q, LineString) and q.length > 1e-3:
                edges.append((a, -1, list(q.coords)))
    # заливка: треугольники
    tv = []
    to = [0]
    for g in G:
        tris = shapely.constrained_delaunay_triangles(g)
        cnt = 0
        for t in getattr(tris, "geoms", [tris]):
            cs = list(t.exterior.coords)[:3]
            for x, y in cs:
                tv += [x, y]
            cnt += 1
        to.append(to[-1] + cnt)
    # точка подписи — внутри АТЕ
    cxy = [g.representative_point() if not g.contains(g.centroid) else g.centroid for g in G]
    no = [0]
    nbf = []
    for a in range(n):
        nbf += sorted(nbs[a])
        no.append(len(nbf))
    eo = [0]
    ep = []
    for a, b, cs in edges:
        for x, y in cs:
            ep += [x, y]
        eo.append(len(ep) // 2)

    def fa(v, nd=1):
        return "PackedFloat32Array(" + ", ".join(("%." + str(nd) + "f") % x for x in v) + ")"

    def ia(v):
        return "PackedInt32Array(" + ", ".join(str(int(x)) for x in v) + ")"

    out = ["{"]
    out.append('"v": 1,')
    out.append('"km2": %.1f,' % KM2)
    out.append('"uid": PackedStringArray(' + ", ".join(json.dumps(units[r]["id"]) for r in R) + "),")
    out.append('"cx": ' + fa([p.x for p in cxy]) + ",")
    out.append('"cy": ' + fa([p.y for p in cxy]) + ",")
    out.append('"km": ' + fa(km, 0) + ",")
    out.append('"pw": ' + fa(pw, 5) + ",")
    out.append('"gw": ' + fa(gw, 5) + ",")
    out.append('"to": ' + ia(to) + ",")
    out.append('"tv": ' + fa(tv) + ",")
    out.append('"no": ' + ia(no) + ",")
    out.append('"nb": ' + ia(nbf) + ",")
    out.append('"ea": ' + ia([e[0] for e in edges]) + ",")
    out.append('"eb": ' + ia([e[1] for e in edges]) + ",")
    out.append('"eo": ' + ia(eo) + ",")
    out.append('"ep": ' + fa(ep))
    out.append("}")
    open(OUT, "w", encoding="utf-8").write("\n".join(out) + "\n")
    per = {}
    for a in range(n):
        per[units[R[a]]["cc"]] = per.get(units[R[a]]["cc"], 0) + 1
    print("по странам:", per, file=sys.stderr)
    miss = [units[i]["id"] for i in range(n_u) if i not in by_r]
    print("регионы без АТЕ:", miss, file=sys.stderr)
    print("треугольников", to[-1], "рёбер", len(edges), "точек рёбер", len(ep) // 2, "размер %.1f МБ" % (os.path.getsize(OUT) / 1e6), file=sys.stderr)


if __name__ == "__main__":
    main()
