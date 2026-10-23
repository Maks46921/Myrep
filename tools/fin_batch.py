#!/usr/bin/env python3
"""0.63: массовый прогон финансового модуля. tools/fin_batch.py [-c DE,FR|all] [-s 7,8] [-y 12] [--off] [-j 3] [--mode m|w]
Для каждой страны/seed запускает tests/dev/fin_run.gd (fin=1, а с --off ещё и fin=0) и печатает итоги: макро в конце, число банковских
кризисов и дефолтов, пробои привязки, программы МВФ, конец игры. Таблица строк по странам и общая статистика частоты кризисов."""
import argparse, os, subprocess, sys, tempfile, concurrent.futures as cf, re
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ALL = 'AL AT BA BE BG BY CH CZ DE DK EE ES FI FR GB GR HR HU IE IT LT LU LV MD ME MK NL NO PL PT RO RS RU SE SI SK UA XK'.split()
def run(cc, seed, years, fin, mode, cr, tmp):
    out = os.path.join(tmp, f'{cc}_{seed}_{fin}.tsv')
    cmd = [os.path.join(ROOT, 'tools', 'godot.sh'), '--headless', '--path', ROOT, '--script', 'tests/dev/fin_run.gd', '--',
           f'country={cc}', f'seed={seed}', f'years={years}', f'fin={fin}', f'mode={mode}', f'cr={cr}', f'out={out}']
    p = subprocess.run(cmd, capture_output=True, text=True, timeout=5400)
    err = [l for l in (p.stdout + p.stderr).split('\n') if 'SCRIPT ERROR' in l or 'Parse Error' in l]
    try:
        txt = open(out).read()
    except Exception:
        return None, err
    return txt, err
def parse(txt):
    lines = txt.strip().split('\n')
    hdr = lines[0].split('\t')
    rows = [dict(zip(hdr, l.split('\t'))) for l in lines[1:] if not l.startswith('#') and not l.startswith('GAME') and '\t' in l]
    over = [l for l in lines if l.startswith('GAME OVER')]
    logs = [l for l in lines if l.startswith('#')]
    return rows, over, logs
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-c', default='DE'); ap.add_argument('-s', default='7'); ap.add_argument('-y', type=int, default=12)
    ap.add_argument('-j', type=int, default=3); ap.add_argument('--off', action='store_true'); ap.add_argument('--mode', default='m'); ap.add_argument('--cr', type=int, default=1)
    a = ap.parse_args()
    ccs = ALL if a.c == 'all' else a.c.split(',')
    seeds = [int(x) for x in a.s.split(',')]
    tmp = tempfile.mkdtemp()
    jobs = {}
    with cf.ThreadPoolExecutor(a.j) as ex:
        for cc in ccs:
            for sd in seeds:
                jobs[(cc, sd, 1)] = ex.submit(run, cc, sd, a.y, 1, a.mode, a.cr, tmp)
                if a.off:
                    jobs[(cc, sd, 0)] = ex.submit(run, cc, sd, a.y, 0, a.mode, a.cr, tmp)
    tot_c = tot_d = tot_runs = 0
    print('страна seed | конец: ВВП рост инфл безр долг% | доверие ставка курс | кризисы дефолты | МВФ | заметки')
    for cc in ccs:
        for sd in seeds:
            txt, err = jobs[(cc, sd, 1)].result()
            if txt is None:
                print(f'{cc} {sd} | НЕТ ВЫВОДА {err[:2]}'); continue
            rows, over, logs = parse(txt)
            if not rows:
                print(f'{cc} {sd} | пусто {over}'); continue
            r = rows[-1]
            tot_runs += 1
            nc = int(r.get('n_cris', 0)); nd = int(r.get('n_dflt', 0)); tot_c += nc; tot_d += nd
            line = f"{cc} {sd} | мес.{r['month']} {r['gdp']} {r['growth']} {r['infl']} {r['unemp']} {r['debt_pct']} | {r.get('mood','-')} {r.get('rate','-')} {r.get('fxs','-')} {r.get('reg','')} | {nc} {nd} | {r.get('imf','-')} |"
            if over: line += ' КОНЕЦ: ' + over[0][:70]
            if err: line += f' ОШИБОК: {len(err)} {err[0][:100]}'
            print(line)
            if a.off:
                t0, e0 = jobs[(cc, sd, 0)].result()
                if t0:
                    r0 = parse(t0)[0][-1]
                    print(f"      без финансов: {r0['gdp']} {r0['growth']} {r0['infl']} {r0['unemp']} {r0['debt_pct']}")
    yrs = tot_runs * a.y
    print(f'\nИтого: прогонов {tot_runs}, лет {yrs}, банковских кризисов {tot_c} (раз в {yrs/max(1,tot_c):.1f} лет на страну), дефолтов {tot_d}')
main()
