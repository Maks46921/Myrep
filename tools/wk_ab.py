#!/usr/bin/env python3
"""0.62: сравнение месячного и недельного шага.  tools/wk_ab.py [-c DE,FR] [-s 7,8,9] [-y 5] [--ev] [--agents]
Для каждой страны и seed запускает tests/dev/wk_ab.gd в двух режимах и печатает отклонение недельного от месячного
(среднее по seed): ВВП, инфляция, безработица, долг, рейтинг, недовольство. Допуск Damir: ВВП за 10 лет в пределах 7 %."""
import argparse, os, subprocess, sys, concurrent.futures as cf, tempfile
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def run(cc, seed, years, mode, ev, ag, tmp, rl=False):
    out = os.path.join(tmp, f'{cc}_{seed}_{mode}.tsv')
    cmd = [os.path.join(ROOT, 'tools', 'godot.sh'), '--headless', '--path', ROOT, '--script', 'tests/dev/wk_ab.gd', '--',
           f'country={cc}', f'seed={seed}', f'years={years}', f'mode={mode}', f'ev={1 if ev else 0}', f'agents={1 if ag else 0}', f'rl={1 if rl else 0}', f'out={out}']
    subprocess.run(cmd, capture_output=True, text=True, timeout=3000)
    rows = [l.split('\t') for l in open(out).read().strip().split('\n')]
    return rows[0], [[float(x) for x in r] for r in rows[1:]]
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-c', default='DE'); ap.add_argument('-s', default='7,8'); ap.add_argument('-y', type=int, default=5)
    ap.add_argument('-j', type=int, default=4); ap.add_argument('--ev', action='store_true'); ap.add_argument('--agents', action='store_true'); ap.add_argument('--rl', action='store_true')
    a = ap.parse_args()
    ccs = a.c.split(','); seeds = [int(x) for x in a.s.split(',')]
    tmp = tempfile.mkdtemp()
    jobs = {}
    with cf.ThreadPoolExecutor(a.j) as ex:
        for cc in ccs:
            for sd in seeds:
                for mode in 'mw':
                    jobs[(cc, sd, mode)] = ex.submit(run, cc, sd, a.y, mode, a.ev, a.agents, tmp, a.rl)
    names = ['gdp', 'growth', 'infl', 'unemp', 'debt%', 'appr', 'unrest', 'capital']
    # world: показатели мира, дипломатии и агентов (колонки ищем по имени в заголовке)
    wnames = ['w_gdp', 'w_gr', 'w_inf', 'w_rel', 'w_exlv', 'w_prot', 'w_mem']
    for cc in ccs:
        print(f'== {cc}: недельный против месячного, среднее по seed {seeds}, {a.y} лет')
        acc = {}
        hdr = None
        for sd in seeds:
            h, m = jobs[(cc, sd, 'm')].result(); h2, w = jobs[(cc, sd, 'w')].result()
            hdr = h
            n = min(len(m), len(w))
            for i in range(n):
                acc.setdefault(i, []).append((m[i], w[i]))
        for i in sorted(acc):
            ms = [p[0] for p in acc[i]]; ws = [p[1] for p in acc[i]]
            mo = int(ms[0][0])
            cols = []
            for j, nm in enumerate(names, start=1):
                am = sum(r[j] for r in ms) / len(ms); aw = sum(r[j] for r in ws) / len(ws)
                if nm == 'gdp': cols.append(f'gdp {aw/am*100-100:+.1f}%')
                else: cols.append(f'{nm} {aw-am:+.2f}')
            print(f'  мес. {mo:>3}: ' + ' | '.join(cols))
            if hdr is not None and 'w_gdp' in hdr:
                wc = []
                for nm in wnames:
                    j = hdr.index(nm)
                    am = sum(r[j] for r in ms) / len(ms); aw = sum(r[j] for r in ws) / len(ws)
                    wc.append(f'{nm} {aw/am*100-100:+.1f}%' if nm == 'w_gdp' else f'{nm} {aw-am:+.2f} ({am:.2f})')
                print('           мир: ' + ' | '.join(wc))
if __name__ == '__main__': main()
