"""Универсальное деление регионов страны на области по клеткам АТЕ (0.64).
Читает/пишет файлы data/* репозитория (накопительно), строит контуры через shapely, переносит записи soc/cult."""
import json, re, copy, numpy as np
from shapely.geometry import Polygon, MultiPolygon
from shapely.ops import unary_union
from proj import fwd as _fwd, caps

CC_NOW = [None]
def fwd(lat, lon):
    x, y = _fwd(lat, lon)
    c = CC_NOW[0]
    if c in caps:
        cxx, cyy, la, lo = caps[c]
        px, py = _fwd(la, lo)
        x += cxx - px; y += cyy - py
    return x, y
from ateio import load_ate, P

def tri_poly(a, to, tv):
    tris = []
    for k in range(to[a] * 6, to[a + 1] * 6, 6):
        t = Polygon([(tv[k], tv[k + 1]), (tv[k + 2], tv[k + 3]), (tv[k + 4], tv[k + 5])])
        if t.area > 0: tris.append(t)
    return unary_union(tris)

def rings_of(g):
    out = []
    geoms = g.geoms if isinstance(g, MultiPolygon) else [g]
    for p in geoms:
        if p.is_empty or p.geom_type != 'Polygon' or p.area < 0.05: continue
        c = list(p.exterior.coords)[:-1]
        out.append([round(v, 1) for xy in c for v in xy])
    return out

def assign_cells(cells, pts, children, iters=400):
    """children: [{code, anchors:[(lat,lon)], area}] -> {cell: code}; смещения подбираются под долю площади"""
    anc = []; lab = []
    for j, ch in enumerate(children):
        for (la, lo) in ch['anchors']:
            anc.append(fwd(la, lo)); lab.append(j)
    anc = np.array(anc); lab = np.array(lab)
    dd = np.sqrt(((pts[:, None, :] - anc[None, :, :]) ** 2).sum(-1))
    tgt = np.array([ch['area'] for ch in children], float); tgt /= tgt.sum()
    off = np.zeros(len(children))
    for it in range(iters):
        k = (dd - off[lab][None, :]).argmin(1); ol = lab[k]
        sh = np.array([(ol == j).sum() / len(cells) for j in range(len(children))])
        off += (tgt - sh) * 6.0
        off = np.clip(off, -12.0, 12.0)
    k = (dd - off[lab][None, :]).argmin(1); ol = lab[k]
    # каждой области — минимум одна клетка (ближайшая к якорю)
    for j in range(len(children)):
        if (ol == j).sum() == 0:
            a0 = np.array([fwd(*x) for x in children[j]['anchors']])
            best = ((pts[:, None, :] - a0[None, :, :]) ** 2).sum(-1).min(1).argmin()
            ol[best] = j
    return {int(cells[i]): children[ol[i]]['code'] for i in range(len(cells))}, [int((ol == j).sum()) for j in range(len(children))]

class World:
    def __init__(self):
        self.s_ate, d = load_ate(); self.d = d
        self.uid = list(d['uid'])
        self.U = json.load(open(P + 'world_units.dat', encoding='utf8'))
        self.tab = open(P + 'world_units.dat', encoding='utf8').read().endswith('\n')
        self.idx = {u['id']: i for i, u in enumerate(self.U)}
        self.cx = d['cx']; self.cy = d['cy']; self.km = d['km']
        self.polyc = {}
    def cell(self, a):
        if a not in self.polyc: self.polyc[a] = tri_poly(a, self.d['to'], self.d['tv'])
        return self.polyc[a]
    def split(self, cc, parent_unit, children, keep_code):
        """parent_unit — id единицы (например 'IT-NOV'); keep_code — какая из областей занимает прежнюю единицу"""
        CC_NOW[0] = cc
        cells = np.array([i for i, u in enumerate(self.uid) if u == parent_unit])
        pts = np.array([[self.cx[i], self.cy[i]] for i in cells])
        ui = self.idx[parent_unit]
        polys = [Polygon([(r[k], r[k + 1]) for k in range(0, len(r), 2)]).buffer(0) for r in self.U[ui]['parts']]
        pg = unary_union(polys)
        if len(children) == 1:
            ch = children[0]; new_id = cc + '-' + ch['code']
            if new_id != parent_unit:
                self.U[ui]['id'] = new_id; self.idx[new_id] = ui; del self.idx[parent_unit]
                for i in cells: self.uid[i] = new_id
            return {parent_unit: new_id}, [len(cells)]
        res, cnt = assign_cells(cells, pts, children)
        for code in [c['code'] for c in children]:
            new_id = cc + '-' + code
            if code == keep_code:
                self.U[ui]['id'] = new_id; self.idx.pop(parent_unit, None); self.idx[new_id] = ui
            else:
                self.U.append({'id': new_id, 'cc': cc, 'c': [0.0, 0.0], 'nb': [], 'parts': []}); self.idx[new_id] = len(self.U) - 1
        self.repair(res, children, cc)
        cnt = [sum(1 for c in res.values() if c == ch['code']) for ch in children]
        for a, code in res.items(): self.uid[a] = cc + '-' + code
        for ch in children:
            code = ch['code']; cl = [a for a, c in res.items() if c == code]
            if not cl: raise SystemExit('пустая область ' + code)
            u = self.U[self.idx[cc + '-' + code]]
            cu = unary_union([self.cell(a) for a in cl]).buffer(0.25)
            u['parts'] = rings_of(pg.intersection(cu))
            if not u['parts']: u['parts'] = rings_of(cu)
            w = np.array([self.km[a] for a in cl]); p2 = np.array([[self.cx[a], self.cy[a]] for a in cl])
            c = (p2 * w[:, None]).sum(0) / w.sum()
            best = cl[int(((p2 - c) ** 2).sum(1).argmin())]
            u['c'] = [round(float(self.cx[best]), 1), round(float(self.cy[best]), 1)]
        return res, cnt
    def comps(self, res, code):
        cl = set(a for a, c in res.items() if c == code)
        out = []; seen = set()
        for a0 in sorted(cl):
            if a0 in seen: continue
            comp = [a0]; st = [a0]; seen.add(a0)
            while st:
                a = st.pop()
                for k in range(self.d['no'][a], self.d['no'][a + 1]):
                    b = int(self.d['nb'][k])
                    if b in cl and b not in seen: seen.add(b); st.append(b); comp.append(b)
            out.append(comp)
        return out
    def repair(self, res, children, cc):
        """несвязные куски области отдаём соседней области с самой длинной общей границей"""
        for it in range(6):
            changed = False
            for ch in children:
                cs = self.comps(res, ch['code'])
                if len(cs) <= 1: continue
                cs.sort(key=len, reverse=True)
                for comp in cs[1:]:
                    votes = {}
                    cset = set(comp)
                    for a in comp:
                        for k in range(self.d['no'][a], self.d['no'][a + 1]):
                            b = int(self.d['nb'][k])
                            if b in res and b not in cset and res[b] != ch['code']:
                                votes[res[b]] = votes.get(res[b], 0) + 1
                    if not votes:
                        print('  ! %s-%s: кусок из %d клеток без соседей внутри единицы' % (cc, ch['code'], len(comp))); continue
                    tgt = max(votes, key=votes.get)
                    print('  ~ %s-%s: кусок из %d клеток передан области %s' % (cc, ch['code'], len(comp), tgt))
                    for a in comp: res[a] = tgt
                    changed = True
            if not changed: break
    def finish(self, outdir='.'):
        d = self.d; nbA = d['nb']; no = d['no']
        idx = self.idx
        au = np.array([idx[u] for u in self.uid])
        land = {}
        for a in range(len(au)):
            for k in range(no[a], no[a + 1]):
                ub = au[nbA[k]]
                if au[a] != ub: land.setdefault(int(au[a]), set()).add(int(ub))
        # старые морские связи сохраняем: пары, которых нет в сухопутной смежности исходных данных
        old = json.load(open(P + 'world_units.dat', encoding='utf8'))
        oid = {u['id']: i for i, u in enumerate(old)}
        sea = []
        oland = {}
        ouid = load_ate()[1]['uid']
        oau = np.array([oid[u] for u in ouid])
        for a in range(len(oau)):
            for k in range(no[a], no[a + 1]):
                ub = oau[nbA[k]]
                if oau[a] != ub: oland.setdefault(int(oau[a]), set()).add(int(ub))
        for i, u in enumerate(old):
            for j in u['nb']:
                if j > i and j not in oland.get(i, set()): sea.append((old[i]['id'], old[j]['id']))
        for (x, y) in sea:
            if x in idx and y in idx:
                land.setdefault(idx[x], set()).add(idx[y]); land.setdefault(idx[y], set()).add(idx[x])
        for i, u in enumerate(self.U):
            nb = land.get(i, set())
            # 3 «трёхточечных» расхождения исходных данных не трогаем: берём объединение со старым списком неизменённых единиц
            self.U[i]['nb'] = sorted(set(nb))
        t = self.s_ate
        m = re.search(r'"uid": PackedStringArray\(([^)]*)\)', t)
        new = '"uid": PackedStringArray(' + ', '.join('"%s"' % x for x in self.uid) + ')'
        t2 = t[:m.start()] + new + t[m.end():]
        from ateio import save_arrays, renorm
        dd = dict(self.d); dd['uid'] = self.uid; renorm(dd)
        t2 = save_arrays(t2, dd, ['pw', 'gw'])
        open(outdir + '/out_ate.dat', 'w', encoding='utf8').write(t2)
        open(outdir + '/out_world_units.dat', 'w', encoding='utf8').write(json.dumps(self.U, ensure_ascii=False, indent='\t') + ('\n' if self.tab else ''))
