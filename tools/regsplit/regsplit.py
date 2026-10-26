"""0.64: деление объединённых регионов на реальные (карта + данные).
Запуск: python3 regsplit.py spec_xx [spec_yy ...]  -> out/ (ate, world_units, countries/XX.dat, soc, cult, fed, events)
Читает текущее состояние репозитория (P), пишет всё в out/, ничего в репозитории не меняет."""
import sys, os, json, re, copy, importlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from splitlib import World
from ateio import P

REPO = P[:-len('data/')]
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'out')

def dump(obj):
    return json.dumps(obj, ensure_ascii=False, indent='\t').replace('\n', '\n\t')

def clampv(v):
    return round(min(100.0, max(0.0, float(v))), 1)

class CountryFile:
    def __init__(self, cc, path=None):
        self.cc = cc
        self.path = path or (P + 'countries/%s.dat' % cc)
        self.t = open(self.path, encoding='utf8').read()
        t = self.t
        self.i0 = t.index('"REGIONS": [') + len('"REGIONS": ')
        self.i1 = t.index('"REG_BIAS"')
        blk = t[self.i0:self.i1]; end = blk.rindex(']')
        self.regs = json.loads(blk[:end + 1]); self.tail = blk[end + 1:]
        self.j0 = self.i1 + len('"REG_BIAS": ')
        self.j1 = t.index('"GROUP_WEIGHT"')
        bblk = t[self.j0:self.j1]; bend = bblk.rindex(']')
        self.bias = json.loads(bblk[:bend + 1]); self.btail = bblk[bend + 1:]
        assert len(self.bias) == len(self.regs), (cc, len(self.bias), len(self.regs))
    def save(self, path):
        t = self.t
        t2 = t[:self.i0] + dump(self.regs) + self.tail + '"REG_BIAS": ' + dump(self.bias) + self.btail + t[self.j1:]
        open(path, 'w', encoding='utf8').write(t2)

def make_kids(parent, kids):
    """parent — запись региона; kids — спецификации; возвращает новые записи регионов"""
    tp = sum(k['pop'] for k in kids)
    wsum = sum(k['pop'] * k['gpc'] for k in kids)
    out = []
    avg = wsum / tp
    for k in kids:
        n = copy.deepcopy(parent)
        k = dict(k); k['tw'] = dict(k.get('tw', {}))
        if 'dev' not in k['tw']: k['tw']['dev'] = round(max(-12.0, min(12.0, (k['gpc'] / avg - 1.0) * 30.0)), 1)
        if 'tr' not in k['tw']: k['tw']['tr'] = round(max(0.05, min(0.95, float(parent['tr']) + (1.0 - k['gpc'] / avg) * 0.6)), 2)
        n['code'] = k['code']; n['name'] = k['name']; n['short'] = k['short']
        n['popm'] = round(float(parent['popm']) * k['pop'] / tp, 3)
        n['pc'] = round(float(parent['pc']) * k['gpc'] * tp / wsum, 3)
        for kk, v in k.get('tw', {}).items():
            if kk in ('reg', 'tr'): n[kk] = round(float(v), 2)
            elif kk in ('dev', 'loy', 'unrest', 'auto', 'infra', 'edu', 'health', 'env'): n[kk] = clampv(float(n[kk]) + v)
            elif kk == 'sec': n['sec'] = v
            elif kk == 'mix': n['mix'] = v
        n['desc'] = k['desc']
        out.append(n)
    return out

def walk_codes(o, fn):
    if isinstance(o, dict):
        for k in list(o.keys()):
            fn(o, k)
            if k in o: walk_codes(o[k], fn)
    elif isinstance(o, list):
        for v in o: walk_codes(v, fn)

def apply_json_reg(d, cc, kidmap):
    """soc.dat / cult.dat: country.CC.reg"""
    reg = d['country'][cc]['reg']
    new = {}
    for k, v in reg.items():
        if k in kidmap:
            for nk in kidmap[k]: new[nk] = copy.deepcopy(v)
        else: new[k] = v
    reg.clear(); reg.update(new)

UA_PARENTS = {'KYO': 'NOR', 'ZHY': 'NOR', 'CHE': 'NOR', 'IVF': 'ZAH', 'TER': 'ZAH', 'ZAK': 'ZAH', 'CHV': 'ZAH', 'RIV': 'VOL', 'VIN': 'POD',
              'KHM': 'POD', 'CHR': 'CEN', 'KIR': 'CEN', 'POL': 'CEN', 'SUM': 'KHA', 'KHE': 'MYK'}

def compact_nums(s):
    return re.sub(r'\[\s*((?:-?[0-9.eE+-]+,?\s*)+)\]', lambda m: '[' + re.sub(r'\s*\n\s*', ' ', m.group(1)).strip() + ']', s)

def sync_world(world, cc, regs, parents):
    """WORLD[cc]['regions'] (data/world.dat) — копия регионов для симуляции других стран"""
    old = {r['code']: r for r in world[cc]['regions']}
    out = []
    for r in regs:
        c = r['code']
        e = old.get(c)
        if e is None:
            e = copy.deepcopy(old[parents[c]])
        else:
            e = copy.deepcopy(e)
        e['id'] = cc + '-' + c
        for k in list(e.keys()):
            if k in r and k not in ('sh', 'id'): e[k] = r[k]
        out.append(e)
    world[cc]['regions'] = out

def run(spec_names):
    os.makedirs(OUT + '/countries', exist_ok=True)
    W = World()
    soc = json.loads(open(P + 'soc.dat', encoding='utf8').read())
    cult = json.loads(open(P + 'cult.dat', encoding='utf8').read())
    fed = json.loads(open(P + 'fed.dat', encoding='utf8').read())
    fed_text = open(P + 'fed.dat', encoding='utf8').read()
    dc_path = os.environ.get('SYM_DC', REPO + 'scripts/data/data_core.gd')
    dc = open(dc_path, encoding='utf8').read().split('\n')
    world = json.loads(open(P + 'world.dat', encoding='utf8').read())
    report = []
    extra = [x[1:] for x in spec_names if x.startswith('+')]
    spec_names = [x for x in spec_names if not x.startswith('+')]
    for name in spec_names:
        m = importlib.import_module(name)
        for cc, spec in m.SPEC.items():
            cf = CountryFile(cc)
            have = [r['code'] for r in cf.regs]
            kidmap = {}
            newregs = []; newbias = []
            for r, b in zip(cf.regs, cf.bias):
                c = r['code']
                if c not in spec['parents']:
                    newregs.append(r); newbias.append(b); continue
                ps = spec['parents'][c]
                kids = ps['kids']
                kc = [k['code'] for k in kids]
                for x in kc:
                    if x != c and x in have: raise SystemExit('код %s уже есть в %s' % (x, cc))
                children = [{'code': k['code'], 'anchors': k['anchors'], 'area': k['area']} for k in kids]
                res, cnt = W.split(cc, cc + '-' + c, children, ps['keep'])
                report.append((cc, c, dict(zip(kc, cnt))))
                for nr in make_kids(r, kids):
                    newregs.append(nr); newbias.append(copy.deepcopy(b))
                kidmap[c] = kc
            cf.regs = newregs; cf.bias = newbias
            cf.save(OUT + '/countries/%s.dat' % cc)
            parents_of = {}
            for pc_, kc_ in kidmap.items():
                for k_ in kc_: parents_of[k_] = pc_
            sync_world(world, cc, cf.regs, parents_of)
            apply_json_reg(soc, cc, kidmap)
            apply_json_reg(cult, cc, kidmap)
            # fed.dat: ключи удалённых кодов
            f = fed.get(cc)
            if f:
                for sub in ('status', 'reg_comp', 'spec'):
                    if sub in f:
                        nd = {}
                        for k, v in f[sub].items():
                            if k in kidmap and k not in kidmap[k]:
                                tgt = spec.get('fed', {}).get(k, kidmap[k][0])
                                nd[tgt] = v
                            else: nd[k] = v
                        f[sub] = nd
            # события региона
            a = None; b = None
            for i, line in enumerate(dc):
                if line == '\t"%s": [' % cc and a is None: a = i
                elif a is not None and re.match(r'^\t"[A-Z]{2,3}": \[', line): b = i; break
            if a is not None:
                evmap = spec.get('events', {})
                for i in range(a, b):
                    mm = re.search(r'"reg": "code:([A-Za-z|]+)"', dc[i])
                    if not mm: continue
                    codes = mm.group(1).split('|')
                    new = []
                    for c2 in codes:
                        if c2 in kidmap:
                            tgt = evmap.get(c2)
                            if tgt is None: tgt = [c2] if c2 in kidmap[c2] else kidmap[c2]
                            elif isinstance(tgt, str): tgt = tgt.split('|')
                            new.extend(tgt)
                        else: new.append(c2)
                    nn = '|'.join(dict.fromkeys(new))
                    if nn != mm.group(1):
                        dc[i] = dc[i].replace('code:' + mm.group(1), 'code:' + nn)
    for cc in extra:
        cf = CountryFile(cc)
        sync_world(world, cc, cf.regs, UA_PARENTS)
    W.finish(OUT)
    open(OUT + '/world.dat', 'w', encoding='utf8').write(compact_nums(json.dumps(world, ensure_ascii=False, indent='\t')) + '\n')
    open(OUT + '/soc.dat', 'w', encoding='utf8').write(json.dumps(soc, ensure_ascii=False, separators=(', ', ': ')))
    open(OUT + '/cult.dat', 'w', encoding='utf8').write(json.dumps(cult, ensure_ascii=False, separators=(', ', ': ')))
    open(OUT + '/fed.dat', 'w', encoding='utf8').write(json.dumps(fed, ensure_ascii=False, indent=1))
    open(OUT + '/data_core.gd', 'w', encoding='utf8').write('\n'.join(dc))
    for r in report: print(r)

if __name__ == '__main__':
    run(sys.argv[1:])
