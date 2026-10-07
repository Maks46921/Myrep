#!/usr/bin/env python3
"""v35: длинные прогоны стилей игры. Каждый стиль × каждая играбельная партия × каждая страна.
  tools/styles.py [-j 4] [-m 360] [-c DE,PL] [-s careful,chaos] [-p 0,2]
Результаты дописываются в .testlogs/styles.jsonl (уже сделанные прогоны пропускаются),
сводка — tools/styles.py --report."""
import argparse, json, os, subprocess, sys
from concurrent.futures import ThreadPoolExecutor
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
from test import ALL  # noqa
STYLES = ["passive", "careful", "populist", "austerity", "growth", "reformer", "coalition", "chaos"]
PARTIES = [0, 1, 2, 3, 4, 5, 7]  # 6 — «прочие», 8/9 недоступны в меню
OUT = os.path.join(ROOT, '.testlogs', 'styles.jsonl')


def run(job):
    cc, p, st, months = job
    cmd = [os.path.join(ROOT, 'tools', 'godot.sh'), '--headless', '--audio-driver', 'Dummy', '--path', ROOT,
           '--script', 'tests/styles.gd', '--', 'country=' + cc, 'party=%d' % p, 'style=' + st, 'months=%d' % months, 'seed=1']
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=900).stdout
    except subprocess.TimeoutExpired:
        return {'cc': cc, 'slot': p, 'style': st, 'error': 'timeout'}
    for line in out.splitlines():
        if line.startswith('STY '):
            d = json.loads(line[4:])
            d['slot'] = p
            errs = [l for l in out.splitlines() if 'SCRIPT ERROR' in l]
            d['script_errors'] = len(errs)
            if errs:
                d['err1'] = errs[0][:160]
            return d
    errs = [l for l in out.splitlines() if 'ERROR' in l]
    return {'cc': cc, 'slot': p, 'style': st, 'error': (errs[0] if errs else out[-300:])[:300]}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-j', type=int, default=4)
    ap.add_argument('-m', type=int, default=360)
    ap.add_argument('-c', default=','.join(ALL))
    ap.add_argument('-s', default=','.join(STYLES))
    ap.add_argument('-p', default=','.join(map(str, PARTIES)))
    a = ap.parse_args()
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    done = set()
    if os.path.exists(OUT):
        for l in open(OUT):
            d = json.loads(l)
            if 'error' not in d:
                done.add((d['cc'], d['slot'], d['style']))
    jobs = [(cc, int(p), st, a.m) for cc in a.c.split(',') for p in a.p.split(',') for st in a.s.split(',')
            if (cc, int(p), st) not in done]
    print('прогонов: %d (уже есть %d)' % (len(jobs), len(done)), flush=True)
    with ThreadPoolExecutor(a.j) as ex, open(OUT, 'a') as f:
        for i, d in enumerate(ex.map(run, jobs)):
            f.write(json.dumps(d, ensure_ascii=False) + '\n')
            f.flush()
            print('%d/%d %s %s %s %s' % (i + 1, len(jobs), d['cc'], d['slot'], d['style'], d.get('error', '')[:80]), flush=True)


if __name__ == '__main__':
    main()
