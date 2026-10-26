#!/usr/bin/env python3
"""0.64 (п. 4): очередь прогонов проверки реалистичности (tests/audit_real64.gd).
  python3 tools/real64_run.py --seeds 1-3 --years 25 -j 4 [--only RU:calm,UA:war] [--out .testlogs/real64]
Готовые результаты (XX_scn_seed.json) пропускаются. Разбор — tools/real64_report.py.
"""
import argparse, os, subprocess, sys, time, itertools
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
# какие сценарии применимы к какой стране (в порядке важности)
COMBOS = {
    'RU': ['calm', 'war', 'leader', 'weird', 'oil', 'sanctions', 'mobilize', 'unrest', 'union'],
    'UA': ['calm', 'war', 'leader', 'weird', 'oil', 'mobilize', 'unrest', 'eunato'],
    'BY': ['calm', 'leader', 'weird', 'oil', 'sanctions', 'mobilize', 'unrest'],
}


def parse_seeds(s):
    out = []
    for p in s.split(','):
        if '-' in p:
            a, b = p.split('-')
            out += list(range(int(a), int(b) + 1))
        else:
            out.append(int(p))
    return out


def run(job):
    cc, scn, sd, years, out = job
    res = os.path.join(ROOT, out, '%s_%s_%d.json' % (cc, scn, sd))
    if os.path.exists(res):
        return job, 'skip', 0
    godot = os.path.join(ROOT, 'tools', 'godot.sh')
    cmd = [godot, '--headless', '--path', ROOT, '--script', 'tests/audit_real64.gd', '--', 'country=' + cc, 'scn=' + scn, 'seed=%d' % sd, 'years=%d' % years, 'out=' + out]
    t0 = time.time()
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=3600)
        ok = os.path.exists(res)
        if not ok:
            open(os.path.join(ROOT, out, '%s_%s_%d.err' % (cc, scn, sd)), 'w').write((p.stdout or '')[-3000:] + (p.stderr or '')[-3000:])
        return job, 'ok' if ok else 'fail', time.time() - t0
    except subprocess.TimeoutExpired:
        return job, 'timeout', time.time() - t0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--seeds', default='1-3')
    ap.add_argument('--years', type=int, default=25)
    ap.add_argument('-j', type=int, default=4)
    ap.add_argument('--only', default='')
    ap.add_argument('--out', default='.testlogs/real64')
    a = ap.parse_args()
    os.makedirs(os.path.join(ROOT, a.out), exist_ok=True)
    only = set(a.only.split(',')) if a.only else None
    jobs = []
    for sd in parse_seeds(a.seeds):
        for scn_i in range(9):
            for cc in ('RU', 'UA', 'BY'):
                if scn_i < len(COMBOS[cc]):
                    scn = COMBOS[cc][scn_i]
                    if only and ('%s:%s' % (cc, scn)) not in only and cc not in only:
                        continue
                    jobs.append((cc, scn, sd, a.years, a.out))
    print('прогонов: %d' % len(jobs), flush=True)
    n = 0
    with ThreadPoolExecutor(max_workers=a.j) as ex:
        for job, st, dt in ex.map(run, jobs):
            n += 1
            print('[%d/%d] %s %s %s seed=%d %.0fс' % (n, len(jobs), st, job[0], job[1], job[2], dt), flush=True)


if __name__ == '__main__':
    main()
