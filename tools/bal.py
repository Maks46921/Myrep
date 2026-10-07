#!/usr/bin/env python3
"""Балансные прогоны: python3 tools/bal.py [-c DE,FR] [-p idle,open,...] [-m 120] [-j 3]; итог в .testlogs/bal.json и таблица."""
import argparse, json, os, re, subprocess, concurrent.futures as cf
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ALL = 'DE FR NL BE LU AT CH CZ DK ES IT NO PL PT SE'.split()
POL = 'idle open closed secular trade_war deals aid mix'.split()
ap = argparse.ArgumentParser()
ap.add_argument('-c', default=','.join(ALL)); ap.add_argument('-p', default=','.join(POL))
ap.add_argument('-m', default='120'); ap.add_argument('-j', type=int, default=3); ap.add_argument('-o', default='socev=1 exev=1 fedev=1')
a = ap.parse_args()
def run(cc, pol):
    cmd = [os.path.join(ROOT, 'tools/godot.sh'), '--headless', '--path', ROOT, '--script', 'tests/bal.gd', '--', 'country=' + cc, 'policy=' + pol, 'months=' + a.m, 'seed=11'] + a.o.split()
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=420).stdout
    except Exception as e:
        return {'cc': cc, 'pol': pol, 'err': str(e)}
    mm = re.search(r'BAL (\{.*\})', out)
    return json.loads(mm.group(1)) if mm else {'cc': cc, 'pol': pol, 'err': out[-300:]}
jobs = [(c, p) for p in a.p.split(',') for c in a.c.split(',')]
res = []
with cf.ThreadPoolExecutor(a.j) as ex:
    for r in ex.map(lambda x: run(*x), jobs):
        res.append(r); print(json.dumps(r, ensure_ascii=False), flush=True)
os.makedirs(os.path.join(ROOT, '.testlogs'), exist_ok=True)
json.dump(res, open(os.path.join(ROOT, '.testlogs', 'bal.json'), 'w'), ensure_ascii=False)
